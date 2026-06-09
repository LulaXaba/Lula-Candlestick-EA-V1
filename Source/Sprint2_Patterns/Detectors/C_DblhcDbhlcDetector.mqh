//+------------------------------------------------------------------+
//|                                       C_DblhcDbhlcDetector.mqh   |
//|                             Lula Price Action Execution Engine V1|
//+------------------------------------------------------------------+
#ifndef C_DBLHCDBHLCDETECTOR_MQH
#define C_DBLHCDBHLCDETECTOR_MQH

#include "..\..\Include\Defines.mqh"
#include "..\..\Include\DTOs.mqh"
#include "..\..\Sprint1_Sensors\CSensorArray.mqh"
#include "..\CPatternResult.mqh"

class C_DblhcDbhlcDetector
  {
private:
   string            m_symbol;
   int               m_min_score;
   bool              m_is_vix75;

public:
                     C_DblhcDbhlcDetector();
                    ~C_DblhcDbhlcDetector();

   bool              Init(const string symbol, int min_score);
   bool              Detect(const int barIndex, CSensorArray* sensor, CPatternResult* result);
  };

C_DblhcDbhlcDetector::C_DblhcDbhlcDetector() : m_symbol(""), m_min_score(70), m_is_vix75(false) {}
C_DblhcDbhlcDetector::~C_DblhcDbhlcDetector() {}

bool C_DblhcDbhlcDetector::Init(const string symbol, int min_score)
  {
   m_symbol = symbol;
   m_min_score = min_score;
   
   m_is_vix75 = (StringFind(m_symbol, "75") >= 0 || StringFind(m_symbol, "10") >= 0 || 
                 StringFind(m_symbol, "25") >= 0 || StringFind(m_symbol, "50") >= 0 || 
                 StringFind(m_symbol, "100") >= 0 || StringFind(m_symbol, "Step") >= 0);
                 
   return true;
  }

bool C_DblhcDbhlcDetector::Detect(const int barIndex, CSensorArray* sensor, CPatternResult* result)
  {
   if(barIndex < 1 || sensor == NULL || result == NULL) return false;

   double open1  = iOpen(m_symbol, PERIOD_CURRENT, barIndex);     // Current forming momentum bar
   double close1 = iClose(m_symbol, PERIOD_CURRENT, barIndex);
   double high1  = iHigh(m_symbol, PERIOD_CURRENT, barIndex);
   double low1   = iLow(m_symbol, PERIOD_CURRENT, barIndex);

   double open2  = iOpen(m_symbol, PERIOD_CURRENT, barIndex + 1); // Previous bar
   double close2 = iClose(m_symbol, PERIOD_CURRENT, barIndex + 1);
   double high2  = iHigh(m_symbol, PERIOD_CURRENT, barIndex + 1);
   double low2   = iLow(m_symbol, PERIOD_CURRENT, barIndex + 1);

   SSensorData sData = sensor.GetData(close1);
   double atr = sData.atr_Current > 0 ? sData.atr_Current : 100 * _Point;

   // Calculate acceptable variance for "matching" highs/lows
   double tolerance = m_is_vix75 ? (atr * 0.05) : (atr * 0.02);

   // 1. Evaluate Matching Extremes
   bool matchingLows  = (MathAbs(low1 - low2) <= tolerance);
   bool matchingHighs = (MathAbs(high1 - high2) <= tolerance);

   // 2. Identify Structure: DBLHC (Bullish) or DBHLC (Bearish)
   // For true institutional momentum, the current bar must close decisively beyond the previous close.
   bool isDBLHC = matchingLows  && (close1 > close2) && (close1 > open1);
   bool isDBHLC = matchingHighs && (close1 < close2) && (close1 < open1);

   if(!isDBLHC && !isDBHLC) return false;

   // 3. Fetch Market Context & Score
   int score = 60; // Base confidence score

   // Scoring Gate 1: Zone Confluence
   if(isDBLHC && sData.isAtDemandZone) score += ZONE_CONFLUENCE_BONUS;
   if(isDBHLC && sData.isAtSupplyZone) score += ZONE_CONFLUENCE_BONUS;

   // Scoring Gate 2: Direction Alignment (Macro Bias)
   if(isDBLHC && sData.weeklyBias == BIAS_BULLISH) score += 10;
   if(isDBHLC && sData.weeklyBias == BIAS_BEARISH) score += 10;

   // Validation Gate
   if(score < m_min_score) return false;

   // 4. Populate DTO Output
   ENUM_TRADE_DIRECTION dir = isDBLHC ? DIRECTION_LONG : DIRECTION_SHORT;
   double entry = close1; 
   double sl = 0.0;

   // Calculate Institutional Stop Loss (Beyond the matching limit-order block + ATR buffer)
   if(isDBLHC)
     {
      double block_low = MathMin(low1, low2);
      sl = block_low - (atr * ATR_MULTIPLIER_NORMAL);
     }
   else
     {
      double block_high = MathMax(high1, high2);
      sl = block_high + (atr * ATR_MULTIPLIER_NORMAL);
     }

   // Standard DBLHC/DBHLC does not trigger the 1H bypass (Grade B)
   result.SetPattern(PATTERN_ENGULFING, dir, GRADE_B, false, entry, sl); 
   // Note: We classify this under ENGULFING or INSIDE_BAR family contextually. Let's map it cleanly to GRADE_B standard momentum.
   // If you want a specific enum for DBLHC, we can use PATTERN_INSIDE_BAR as the closest proxy, or add PATTERN_DBLHC to Defines.
   // I'll leave it mapped as a Grade B structure under PATTERN_PIN_BAR's momentum equivalent (as it's a 2-bar pinbar).
   result.SetPattern(PATTERN_PIN_BAR, dir, GRADE_B, false, entry, sl);

   return true;
  }

#endif
