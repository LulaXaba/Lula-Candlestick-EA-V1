//+------------------------------------------------------------------+
//|                                         C_StarPatternDetector.mqh|
//|                             Lula Price Action Execution Engine V1|
//+------------------------------------------------------------------+
#ifndef C_STARPATTERNDETECTOR_MQH
#define C_STARPATTERNDETECTOR_MQH

#include "..\..\Include\Defines.mqh"
#include "..\..\Include\DTOs.mqh"
#include "..\..\Sprint1_Sensors\CSensorArray.mqh"
#include "..\CPatternResult.mqh"

class C_StarPatternDetector
  {
private:
   string            m_symbol;
   int               m_min_score;

public:
                     C_StarPatternDetector();
                    ~C_StarPatternDetector();

   bool              Init(const string symbol, int min_score);
   bool              Detect(const int barIndex, CSensorArray* sensor, CPatternResult* result);
  };

C_StarPatternDetector::C_StarPatternDetector() : m_symbol(""), m_min_score(70) {}
C_StarPatternDetector::~C_StarPatternDetector() {}

bool C_StarPatternDetector::Init(const string symbol, int min_score)
  {
   m_symbol = symbol;
   m_min_score = min_score;
   return true;
  }

bool C_StarPatternDetector::Detect(const int barIndex, CSensorArray* sensor, CPatternResult* result)
  {
   // Star patterns require 3 bars: current (index), middle (index+1), and base (index+2)
   if(barIndex < 1 || sensor == NULL || result == NULL) return false;

   // Bar 1: The Reversal Confirmation (Newest)
   double open1  = iOpen(m_symbol, PERIOD_CURRENT, barIndex);
   double close1 = iClose(m_symbol, PERIOD_CURRENT, barIndex);
   double high1  = iHigh(m_symbol, PERIOD_CURRENT, barIndex);
   double low1   = iLow(m_symbol, PERIOD_CURRENT, barIndex);

   // Bar 2: The Star / Exhaustion (Middle)
   double open2  = iOpen(m_symbol, PERIOD_CURRENT, barIndex + 1);
   double close2 = iClose(m_symbol, PERIOD_CURRENT, barIndex + 1);
   double high2  = iHigh(m_symbol, PERIOD_CURRENT, barIndex + 1);
   double low2   = iLow(m_symbol, PERIOD_CURRENT, barIndex + 1);

   // Bar 3: The Base / Origin (Oldest)
   double open3  = iOpen(m_symbol, PERIOD_CURRENT, barIndex + 2);
   double close3 = iClose(m_symbol, PERIOD_CURRENT, barIndex + 2);
   double high3  = iHigh(m_symbol, PERIOD_CURRENT, barIndex + 2);
   double low3   = iLow(m_symbol, PERIOD_CURRENT, barIndex + 2);

   double body2  = MathAbs(open2 - close2);
   double range2 = MathAbs(high2 - low2);
   if(range2 <= 0) return false;

   // Exhaustion check: Bar 2 must be a doji/spinning top (body <= 30% of range)
   bool isExhaustion = (body2 / range2) <= 0.30;
   if(!isExhaustion) return false;

   // 1. Check Morning Star (Bullish Reversal)
   bool isBearishBase  = (close3 < open3);
   bool isBullishConf  = (close1 > open1);
   bool isLowestLow    = (low2 < low3) && (low2 < low1); // Star must form the pivot
   
   double bearishBaseMidpoint = close3 + ((open3 - close3) * 0.5);
   bool piercesMidpointUp = (close1 >= bearishBaseMidpoint);

   bool isMorningStar = isBearishBase && isLowestLow && isBullishConf && piercesMidpointUp;

   // 2. Check Evening Star (Bearish Reversal)
   bool isBullishBase  = (close3 > open3);
   bool isBearishConf  = (close1 < open1);
   bool isHighestHigh  = (high2 > high3) && (high2 > high1); // Star must form the pivot
   
   double bullishBaseMidpoint = open3 + ((close3 - open3) * 0.5);
   bool piercesMidpointDn = (close1 <= bullishBaseMidpoint);

   bool isEveningStar = isBullishBase && isHighestHigh && isBearishConf && piercesMidpointDn;

   if(!isMorningStar && !isEveningStar) return false;

   // 3. Fetch Market Context & Score
   SSensorData sData = sensor.GetData(close1);
   double atr = sData.atr_Current > 0 ? sData.atr_Current : 100 * _Point;

   int score = 65; // Base confidence score (Higher than 2-bar patterns as 3 bars = more data)

   // Scoring Gate 1: Zone Confluence
   if(isMorningStar && sData.isAtDemandZone) score += ZONE_CONFLUENCE_BONUS;
   if(isEveningStar && sData.isAtSupplyZone) score += ZONE_CONFLUENCE_BONUS;

   // Scoring Gate 2: Direction Alignment (Macro Bias)
   if(isMorningStar && sData.weeklyBias == BIAS_BULLISH) score += 10;
   if(isEveningStar && sData.weeklyBias == BIAS_BEARISH) score += 10;

   // Validation Gate
   if(score < m_min_score) return false;

   // 4. Determine Grade (If the confirmation bar is massive, promote to Grade A)
   double range1 = MathAbs(high1 - low1);
   bool bypass_1h = (range1 >= (1.5 * atr));
   ENUM_PATTERN_GRADE grade = bypass_1h ? GRADE_A : GRADE_B;

   // 5. Populate DTO Output
   ENUM_TRADE_DIRECTION dir = isMorningStar ? DIRECTION_LONG : DIRECTION_SHORT;
   double entry = close1; 
   double sl = 0.0;

   // Stop Loss MUST go beyond the extreme of the Star (Bar 2)
   if(isMorningStar)
     {
      sl = low2 - (atr * ATR_MULTIPLIER_NORMAL);
     }
   else
     {
      sl = high2 + (atr * ATR_MULTIPLIER_NORMAL);
     }

   // Note: Star Patterns act as major reversals. We map to PATTERN_PIN_BAR conceptually in the DTO
   // because it functions as a fractal pin bar on higher timeframes. 
   result.SetPattern(PATTERN_PIN_BAR, dir, grade, bypass_1h, entry, sl);

   return true;
  }

#endif
