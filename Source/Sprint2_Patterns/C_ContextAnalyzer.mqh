//+------------------------------------------------------------------+
//|                                           C_ContextAnalyzer.mqh  |
//|                             Lula Price Action Execution Engine V1|
//+------------------------------------------------------------------+
#ifndef C_CONTEXTANALYZER_MQH
#define C_CONTEXTANALYZER_MQH

#include "..\Include\Defines.mqh"
#include "..\Include\DTOs.mqh"
#include "..\Sprint1_Sensors\CSensorArray.mqh"
#include "CPatternResult.mqh"

class C_ContextAnalyzer
  {
private:
   string            m_symbol;

public:
                     C_ContextAnalyzer();
                    ~C_ContextAnalyzer();

   bool              Init(const string symbol);
   
   // Returns true if the context is SAFE to trade, false if the pattern should be rejected
   bool              Analyze(const int barIndex, CSensorArray* sensor, CPatternResult* result);
  };

C_ContextAnalyzer::C_ContextAnalyzer() : m_symbol("") {}
C_ContextAnalyzer::~C_ContextAnalyzer() {}

bool C_ContextAnalyzer::Init(const string symbol)
  {
   m_symbol = symbol;
   return true;
  }

bool C_ContextAnalyzer::Analyze(const int barIndex, CSensorArray* sensor, CPatternResult* result)
  {
   if(result == NULL || !result.IsValid() || sensor == NULL) return false;

   ENUM_TRADE_DIRECTION dir = result.GetDirection();
   
   //==================================================================
   // 1. DAILY WARNING CONTEXT (Macro Wick Rejection)
   //==================================================================
   double dOpen  = iOpen(m_symbol, PERIOD_D1, 0);
   double dHigh  = iHigh(m_symbol, PERIOD_D1, 0);
   double dLow   = iLow(m_symbol, PERIOD_D1, 0);
   double dClose = iClose(m_symbol, PERIOD_D1, 0);
   double dRange = MathAbs(dHigh - dLow);

   if(dRange > 0)
     {
      if(dir == DIRECTION_LONG)
        {
         // If we want to go long, check if there's a massive upper wick on the daily (selling pressure)
         double upperWick = dHigh - MathMax(dOpen, dClose);
         if((upperWick / dRange) >= DAILY_REJECTION_WICK_PCT)
           {
            return false; // Reject: Daily sellers are in control
           }
        }
      else if(dir == DIRECTION_SHORT)
        {
         // If we want to go short, check if there's a massive lower wick on the daily (buying pressure)
         double lowerWick = MathMin(dOpen, dClose) - dLow;
         if((lowerWick / dRange) >= DAILY_REJECTION_WICK_PCT)
           {
            return false; // Reject: Daily buyers are in control
           }
        }
     }

   //==================================================================
   // 2. PIVOT REVERSAL CONTEXT (No-Man's Land Filter)
   //==================================================================
   // If it's a Grade A pattern (Engulfing/False Breakout), it has enough momentum to override local pivot checks
   if(result.GetGrade() == GRADE_A) return true;

   SSensorData sData = sensor.GetData(result.GetEntryPrice());
   
   // If the pattern is at a recognized Sprint 1 Zone, it is automatically valid context
   if(sData.zoneRank >= RANK_MINOR) return true;

   // If NOT at a zone, it MUST be a local 8-bar extreme (fractal pivot) to be traded
   bool isLocalExtreme = false;
   int lookback = 8;
   
   if(dir == DIRECTION_LONG)
     {
      // Check if the pattern contains the lowest low of the last 8 bars
      int lowestIdx = iLowest(m_symbol, PERIOD_CURRENT, MODE_LOW, lookback, barIndex);
      // Allow barIndex, barIndex+1, or barIndex+2 to account for 2-bar and 3-bar patterns
      isLocalExtreme = (lowestIdx >= barIndex && lowestIdx <= barIndex + 2);
     }
   else if(dir == DIRECTION_SHORT)
     {
      // Check if the pattern contains the highest high of the last 8 bars
      int highestIdx = iHighest(m_symbol, PERIOD_CURRENT, MODE_HIGH, lookback, barIndex);
      isLocalExtreme = (highestIdx >= barIndex && highestIdx <= barIndex + 2);
     }

   // If it is neither at a zone nor a local extreme, it's floating in chop. Reject it.
   if(!isLocalExtreme) return false;

   return true;
  }

#endif
