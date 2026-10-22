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
   double            m_daily_wick_pct;

public:
                     C_ContextAnalyzer();
                    ~C_ContextAnalyzer();

   bool              Init(const string symbol);
   
   // Returns true if the context is SAFE to trade, false if the pattern should be rejected
   bool              Analyze(const int barIndex, CSensorArray* sensor, CPatternResult* result);
  };

C_ContextAnalyzer::C_ContextAnalyzer() : m_symbol(""), m_daily_wick_pct(DAILY_REJECTION_WICK_PCT) {}
C_ContextAnalyzer::~C_ContextAnalyzer() {}

bool C_ContextAnalyzer::Init(const string symbol)
  {
   m_symbol = symbol;
   m_daily_wick_pct = DAILY_REJECTION_WICK_PCT; // default 0.60
   if(StringFind(symbol, "Boom") >= 0 || StringFind(symbol, "150") >= 0)
      m_daily_wick_pct = 0.85; // Boom spikes have structural upper wicks
   return true;
  }

bool C_ContextAnalyzer::Analyze(const int barIndex, CSensorArray* sensor, CPatternResult* result)
  {
   if(result == NULL || !result.IsValid() || sensor == NULL) return false;

   ENUM_TRADE_DIRECTION dir = result.GetDirection();
   SSymbolProfile prof = CSymbolProfile::Get(m_symbol);

   //==================================================================
   // 1. PIVOT & ZONE CONTEXT (Grade A / Zone checks first)
   //==================================================================
   // If it's a Grade A pattern (Engulfing/False Breakout), it has enough momentum to override local pivot checks
   if(result.GetGrade() == GRADE_A) return true;

   SSensorData sData = sensor.GetData(result.GetEntryPrice());
   
   // If the pattern is at a recognized Sprint 1 Zone, it is automatically valid context (never rejected by daily filter)
   if(sData.zoneRank >= RANK_MINOR) return true;

   //==================================================================
   // 2. DAILY WARNING CONTEXT (Macro Wick Rejection for non-zone setups)
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
         if((upperWick / dRange) >= prof.daily_wick_max_long)
           {
            PrintFormat("[CTX] REJECT daily-wick dir=%d ratio=%.2f threshold=%.2f",
                        dir, upperWick / dRange, prof.daily_wick_max_long);
            return false; // Reject: Daily sellers are in control
           }
        }
      else if(dir == DIRECTION_SHORT)
        {
         // If we want to go short, check if there's a massive lower wick on the daily (buying pressure)
         double lowerWick = MathMin(dOpen, dClose) - dLow;
         if((lowerWick / dRange) >= prof.daily_wick_max_short)
           {
            PrintFormat("[CTX] REJECT daily-wick dir=%d ratio=%.2f threshold=%.2f",
                        dir, lowerWick / dRange, prof.daily_wick_max_short);
            return false; // Reject: Daily buyers are in control
           }
        }
     }

   //==================================================================
   // 3. LOCAL EXTREME CHECK (Lookback derived from symbol profile)
   //==================================================================
   bool isLocalExtreme = false;
   int lookback = prof.local_extreme_lookback;
   int lowestIdx = -1;
   int highestIdx = -1;
   
   if(dir == DIRECTION_LONG)
     {
      // Check if the pattern contains the lowest low of the last 15 bars
      lowestIdx = iLowest(m_symbol, PERIOD_CURRENT, MODE_LOW, lookback, barIndex);
      // Allow barIndex, barIndex+1, or barIndex+2 to account for 2-bar and 3-bar patterns
      isLocalExtreme = (lowestIdx >= barIndex && lowestIdx <= barIndex + 2);
     }
   else if(dir == DIRECTION_SHORT)
     {
      // Check if the pattern contains the highest high of the last 15 bars
      highestIdx = iHighest(m_symbol, PERIOD_CURRENT, MODE_HIGH, lookback, barIndex);
      isLocalExtreme = (highestIdx >= barIndex && highestIdx <= barIndex + 2);
     }

   // If it is neither at a zone nor a local extreme, it's floating in chop. Reject it.
   if(!isLocalExtreme)
     {
      PrintFormat("[CTX] REJECT not-at-zone-not-extreme dir=%d zoneRank=%d idx=%d",
                  dir, sData.zoneRank, (dir == DIRECTION_LONG ? lowestIdx : highestIdx));
      return false;
     }

   return true;
  }

#endif
