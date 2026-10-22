//+------------------------------------------------------------------+
//|                                           C_InsideBarDetector.mqh|
//|                             Lula Price Action Execution Engine V1|
//+------------------------------------------------------------------+
#ifndef C_INSIDEBARDETECTOR_MQH
#define C_INSIDEBARDETECTOR_MQH

#include "..\..\Include\Defines.mqh"
#include "..\..\Include\DTOs.mqh"
#include "..\..\Sprint1_Sensors\CSensorArray.mqh"
#include "..\CPatternResult.mqh"

class C_InsideBarDetector
  {
private:
   string            m_symbol;
   int               m_min_score;

public:
                     C_InsideBarDetector();
                    ~C_InsideBarDetector();

   bool              Init(const string symbol, int min_score);
   bool              Detect(const int barIndex, CSensorArray* sensor, CPatternResult* result);
  };

C_InsideBarDetector::C_InsideBarDetector() : m_symbol(""), m_min_score(70) {}
C_InsideBarDetector::~C_InsideBarDetector() {}

bool C_InsideBarDetector::Init(const string symbol, int min_score)
  {
   m_symbol = symbol;
   m_min_score = min_score;
   return true;
  }

bool C_InsideBarDetector::Detect(const int barIndex, CSensorArray* sensor, CPatternResult* result)
  {
   // Inside Bar requires 2 bars: the Inside Bar (index) and the Mother Bar (index + 1)
   if(barIndex < 1 || sensor == NULL || result == NULL) return false;

   double high1  = iHigh(m_symbol, PERIOD_CURRENT, barIndex);     // Inside Bar
   double low1   = iLow(m_symbol, PERIOD_CURRENT, barIndex);

   double open2  = iOpen(m_symbol, PERIOD_CURRENT, barIndex + 1); // Mother Bar
   double close2 = iClose(m_symbol, PERIOD_CURRENT, barIndex + 1);
   double high2  = iHigh(m_symbol, PERIOD_CURRENT, barIndex + 1);
   double low2   = iLow(m_symbol, PERIOD_CURRENT, barIndex + 1);

   // 1. Identify Base Inside Bar Structure (Strict High/Low boundary check relaxed for synthetics)
   bool isInsideBar = (high1 <= high2) && (low1 >= low2);
   if(!isInsideBar) return false;

   // 2. Determine Implied Direction based on Mother Bar momentum
   bool isBullish = (close2 > open2);
   bool isBearish = (close2 < open2);

   // Filter out doji mother bars where direction is entirely ambiguous
   if(!isBullish && !isBearish) return false;

   // 3. Fetch Market Context & Score
   double close1 = iClose(m_symbol, PERIOD_CURRENT, barIndex); // Inside bar close for context fetch
   SSensorData sData = sensor.GetData(close1);
   int score = 70; // Base confidence score

   // Scoring Gate 1: Zone Confluence
   if(isBullish && sData.isAtDemandZone) score += ZONE_CONFLUENCE_BONUS;
   if(isBearish && sData.isAtSupplyZone) score += ZONE_CONFLUENCE_BONUS;

   // Scoring Gate 2: Direction Alignment (Macro Bias)
   if(isBullish && sData.weeklyBias == BIAS_BULLISH) score += 10;
   if(isBearish && sData.weeklyBias == BIAS_BEARISH) score += 10;

   // Validation Gate
   if(score < m_min_score) return false;

   // 4. Populate DTO Output
   double atr = sData.atr_Current > 0 ? sData.atr_Current : 100 * _Point; 
   ENUM_TRADE_DIRECTION dir = isBullish ? DIRECTION_LONG : DIRECTION_SHORT;
   
   // Enter on the close of the Inside Bar (anticipating the breakout)
   double entry = close1; 
   double sl = 0.0;

   // Institutional Stop Loss goes beyond the extremes of the MOTHER BAR, not the inside bar.
   if(isBullish)
     {
      sl = low2 - (atr * ATR_MULTIPLIER_NORMAL);
     }
   else
     {
      sl = high2 + (atr * ATR_MULTIPLIER_NORMAL);
     }

   // Inside Bars are Grade B (Standard) patterns
   result.SetPattern(PATTERN_INSIDE_BAR, dir, GRADE_B, false, entry, sl);
   
   return true;
  }

#endif
