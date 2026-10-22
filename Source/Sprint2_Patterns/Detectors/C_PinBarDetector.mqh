//+------------------------------------------------------------------+
//|                                             C_PinBarDetector.mqh |
//|                             Lula Price Action Execution Engine V1|
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

public:
                     C_PinBarDetector();
                    ~C_PinBarDetector();

   bool              Init(const string symbol, double wick_ratio, int min_score);
   bool              Detect(const int barIndex, CSensorArray* sensor, CPatternResult* result);
  };

C_PinBarDetector::C_PinBarDetector() : m_symbol(""), m_wick_ratio(0.45), m_min_score(70) {}
C_PinBarDetector::~C_PinBarDetector() {}

bool C_PinBarDetector::Init(const string symbol, double wick_ratio, int min_score)
  {
   m_symbol = symbol;
   m_wick_ratio = wick_ratio;
   m_min_score = min_score;
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
   double effective_wick_ratio = (m_wick_ratio > 0.0) ? m_wick_ratio : prof.pinbar_min_wick_ratio;
   double close_threshold_bull = low  + (range * prof.pinbar_close_pct);
   double close_threshold_bear = high - (range * prof.pinbar_close_pct);

   // Identify base mathematical structure
   bool isBullishPin = (lower_wick >= (effective_wick_ratio * range)) && (close > close_threshold_bull);
   bool isBearishPin = (upper_wick >= (effective_wick_ratio * range)) && (close < close_threshold_bear);

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
   if(score < m_min_score) return false;

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
