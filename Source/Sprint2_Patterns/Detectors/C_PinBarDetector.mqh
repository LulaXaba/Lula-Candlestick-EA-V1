//+------------------------------------------------------------------+
//|                                             C_PinBarDetector.mqh |
//|                             Lula Price Action Execution Engine V2|
//+------------------------------------------------------------------+
#ifndef C_PINBARDETECTOR_MQH
#define C_PINBARDETECTOR_MQH

#include "..\..\Include\Defines.mqh"
#include "..\..\Include\DTOs.mqh"
#include "..\..\Sprint1_Sensors\CSensorArray.mqh"
#include "..\CPatternResult.mqh"

class C_PinBarDetector
  {
private:
   string            m_symbol;
   double            m_wick_ratio;
   int               m_min_score;
   bool              m_verbose;

public:
                     C_PinBarDetector();
                    ~C_PinBarDetector();

   bool              Init(const string symbol, double wick_ratio, int min_score, bool verbose = false);
   bool              Detect(const int barIndex, CSensorArray* sensor, CPatternResult* result);
  };

C_PinBarDetector::C_PinBarDetector() : m_symbol(""), m_wick_ratio(0.45), m_min_score(70), m_verbose(false) {}
C_PinBarDetector::~C_PinBarDetector() {}

bool C_PinBarDetector::Init(const string symbol, double wick_ratio, int min_score, bool verbose)
  {
   m_symbol = symbol;
   m_wick_ratio = wick_ratio;
   m_min_score = min_score;
   m_verbose = verbose;
   return true;
  }

bool C_PinBarDetector::Detect(const int barIndex, CSensorArray* sensor, CPatternResult* result)
  {
   if(barIndex < 1 || sensor == NULL || result == NULL) return false;

   double open  = iOpen(m_symbol, PERIOD_CURRENT, barIndex);
   double high  = iHigh(m_symbol, PERIOD_CURRENT, barIndex);
   double low   = iLow(m_symbol, PERIOD_CURRENT, barIndex);
   double close = iClose(m_symbol, PERIOD_CURRENT, barIndex);

   double range = MathAbs(high - low);
   if(range <= 0) return false; // Prevent divide by zero

   double body       = MathAbs(open - close);
   double upper_wick = high - MathMax(open, close);
   double lower_wick = MathMin(open, close) - low;
   SSymbolProfile prof = CSymbolProfile::Get(m_symbol);
   double effective_wick_ratio = prof.pinbar_min_wick_ratio;
   double close_threshold_bull = low  + (range * prof.pinbar_close_pct);
   double close_threshold_bear = high - (range * prof.pinbar_close_pct);

   // Identify base mathematical structure
   double lower_wick_pct = (range > 0) ? lower_wick / range : 0;
   double upper_wick_pct = (range > 0) ? upper_wick / range : 0;
   bool isBullishPin = (lower_wick >= (effective_wick_ratio * range)) && (close > close_threshold_bull);
   bool isBearishPin = (upper_wick >= (effective_wick_ratio * range)) && (close < close_threshold_bear);

   if(m_verbose)
     {
      if(isBullishPin)
         PrintFormat("[DET PIN] wick_ratio=%.2f threshold=%.2f close_pct=%.2f body=%.5f -> HIT(bull) score=70",
                     lower_wick_pct, effective_wick_ratio, prof.pinbar_close_pct, body);
      else if(isBearishPin)
         PrintFormat("[DET PIN] wick_ratio=%.2f threshold=%.2f close_pct=%.2f body=%.5f -> HIT(bear) score=70",
                     upper_wick_pct, effective_wick_ratio, prof.pinbar_close_pct, body);
      else
         PrintFormat("[DET PIN] lower_wick=%.2f upper_wick=%.2f threshold=%.2f close_pct=%.2f -> MISS",
                     lower_wick_pct, upper_wick_pct, effective_wick_ratio, prof.pinbar_close_pct);
     }

   if(!isBullishPin && !isBearishPin) return false;

   // Fetch Market Context
   SSensorData sData = sensor.GetData(close);
   
   int score = 70; // Base confidence score

   // Scoring Gate 1: Zone Confluence
   if(isBullishPin && sData.isAtDemandZone) score += ZONE_CONFLUENCE_BONUS;
   if(isBearishPin && sData.isAtSupplyZone) score += ZONE_CONFLUENCE_BONUS;

   // Scoring Gate 2: Direction Alignment (Macro Bias)
   if(isBullishPin && sData.weeklyBias == BIAS_BULLISH) score += 10;
   if(isBearishPin && sData.weeklyBias == BIAS_BEARISH) score += 10;

   // Validation Gate
   if(score < m_min_score)
     {
      if(m_verbose) PrintFormat("[DET PIN] score=%d < min=%d -> REJECT", score, m_min_score);
      return false;
     }

   // Safe ATR Fallback
   double atr = sData.atr_Current;
   if(atr <= 0) atr = 100 * _Point; 

   ENUM_TRADE_DIRECTION dir = isBullishPin ? DIRECTION_LONG : DIRECTION_SHORT;
   double entry = close; // Enter on candle close
   double sl = 0.0;

   // Calculate Institutional Stop Loss (Beyond wick + ATR buffer)
   if(isBullishPin)
     {
      sl = low - (atr * ATR_MULTIPLIER_NORMAL);
     }
   else
     {
      sl = high + (atr * ATR_MULTIPLIER_NORMAL);
     }

   // Standard Pin Bars do not trigger 1H Bypass (Grade B)
   result.SetPattern(PATTERN_PIN_BAR, dir, GRADE_B, false, entry, sl);
   
   return true;
  }

#endif
