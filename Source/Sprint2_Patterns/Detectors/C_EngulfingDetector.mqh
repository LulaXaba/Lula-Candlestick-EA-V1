//+------------------------------------------------------------------+
//|                                           C_EngulfingDetector.mqh|
//|                             Lula Price Action Execution Engine V1|
//+------------------------------------------------------------------+
#ifndef C_ENGULFINGDETECTOR_MQH
#define C_ENGULFINGDETECTOR_MQH

#include "..\..\Include\Defines.mqh"
#include "..\..\Include\DTOs.mqh"
#include "..\..\Sprint1_Sensors\CSensorArray.mqh"
#include "..\CPatternResult.mqh"

class C_EngulfingDetector
  {
private:
   string            m_symbol;
   int               m_min_score;

public:
                     C_EngulfingDetector();
                    ~C_EngulfingDetector();

   bool              Init(const string symbol, int min_score);
   bool              Detect(const int barIndex, CSensorArray* sensor, CPatternResult* result);
  };

C_EngulfingDetector::C_EngulfingDetector() : m_symbol(""), m_min_score(70) {}
C_EngulfingDetector::~C_EngulfingDetector() {}

bool C_EngulfingDetector::Init(const string symbol, int min_score)
  {
   m_symbol = symbol;
   m_min_score = min_score;
   return true;
  }

bool C_EngulfingDetector::Detect(const int barIndex, CSensorArray* sensor, CPatternResult* result)
  {
   // Engulfing requires 2 bars: the current (index) and the previous (index + 1)
   if(barIndex < 1 || sensor == NULL || result == NULL) return false;

   double open1  = iOpen(m_symbol, PERIOD_CURRENT, barIndex);
   double close1 = iClose(m_symbol, PERIOD_CURRENT, barIndex);
   double high1  = iHigh(m_symbol, PERIOD_CURRENT, barIndex);
   double low1   = iLow(m_symbol, PERIOD_CURRENT, barIndex);

   double open2  = iOpen(m_symbol, PERIOD_CURRENT, barIndex + 1);
   double close2 = iClose(m_symbol, PERIOD_CURRENT, barIndex + 1);
   double high2  = iHigh(m_symbol, PERIOD_CURRENT, barIndex + 1);
   double low2   = iLow(m_symbol, PERIOD_CURRENT, barIndex + 1);

   double body1 = MathAbs(open1 - close1);
   double body2 = MathAbs(open2 - close2);

   if(body1 <= 0 || body2 <= 0) return false; // Filter out doji structures in the base

   // 1. Identify Base Bullish / Bearish Engulfing Structure
   bool isBullishEngulfing = (close2 < open2) && (close1 > open1) && 
                             (close1 >= open2) && (open1 <= close2);

   bool isBearishEngulfing = (close2 > open2) && (close1 < open1) && 
                             (open1 >= close2) && (close1 <= open2);

   if(!isBullishEngulfing && !isBearishEngulfing) return false;

   // 2. Determine Pattern Grade (Grade A = Body >= 1.5x previous body)
   ENUM_CONFLUENCE_GRADE grade = GRADE_B;
   bool bypass_1h = false;
   
   if(body1 >= (body2 * ENGULFING_GRADE_A_RATIO))
     {
      grade = GRADE_A;
      bypass_1h = true; // GRADE A Triggers 1H Structure Bypass
     }

   // 3. Fetch Market Context & Score
   SSensorData sData = sensor.GetData(close1);
   int score = 60; // Base confidence score

   // Scoring Gate 1: Zone Confluence
   if(isBullishEngulfing && sData.isAtDemandZone) score += ZONE_CONFLUENCE_BONUS;
   if(isBearishEngulfing && sData.isAtSupplyZone) score += ZONE_CONFLUENCE_BONUS;

   // Scoring Gate 2: Direction Alignment (Macro Bias)
   if(isBullishEngulfing && sData.weeklyBias == BIAS_BULLISH) score += 10;
   if(isBearishEngulfing && sData.weeklyBias == BIAS_BEARISH) score += 10;

   // Validation Gate
   if(score < m_min_score) return false;

   // 4. Populate DTO Output
   double atr = sData.atr_Current > 0 ? sData.atr_Current : 100 * _Point; 
   ENUM_TRADE_DIRECTION dir = isBullishEngulfing ? DIRECTION_LONG : DIRECTION_SHORT;
   double entry = close1; 
   double sl = 0.0;

   // Calculate Institutional Stop Loss (Beyond extreme of the 2-candle formation + ATR buffer)
   if(isBullishEngulfing)
     {
      double lowest_low = MathMin(low1, low2);
      sl = lowest_low - (atr * ATR_MULTIPLIER_NORMAL);
     }
   else
     {
      double highest_high = MathMax(high1, high2);
      sl = highest_high + (atr * ATR_MULTIPLIER_NORMAL);
     }

   result.SetPattern(PATTERN_ENGULFING, dir, grade, bypass_1h, entry, sl);
   
   return true;
  }

#endif
