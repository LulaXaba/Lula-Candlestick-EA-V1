//+------------------------------------------------------------------+
//|  CEngine3_WeeklyMacro.mqh — Engine 3: Weekly Macro Levels        |
//|  Sprint 1: The Sensor Array                                      |
//|                                                                  |
//|  Responsibility: Determine the weekly macro bias (bullish /      |
//|  bearish / neutral) and identify key weekly price levels.        |
//|  Scan depth: WEEKLY_MACRO_LOOKBACK = 26 bars (~6 months).        |
//+------------------------------------------------------------------+
#ifndef CENGINE3_WEEKLYMACRO_MQH
#define CENGINE3_WEEKLYMACRO_MQH

#include "../../Include/Defines.mqh"
#include "../../Include/DTOs.mqh"
#include "../CPriceZone.mqh"

class CEngine3_WeeklyMacro
{
private:
   string           m_symbol;
   ENUM_WEEKLY_BIAS m_weeklyBias;
   double           m_weeklyHigh;    // Highest high of last WEEKLY_MACRO_LOOKBACK bars
   double           m_weeklyLow;     // Lowest low of last WEEKLY_MACRO_LOOKBACK bars
   double           m_weeklyATR;     // Weekly ATR — compared to VIX75_MIN_ATR
   bool             m_highVolMode;   // true if weekly ATR > 2x average (HIGH_VOL mode)
   
   CPriceZone*      m_macroHighZone;
   CPriceZone*      m_macroLowZone;

   void             AnalyseWeeklyBias(double weekly_atr);
   bool             IsWeeklyDoji(const int barIndex) const;

public:
                    CEngine3_WeeklyMacro();
                   ~CEngine3_WeeklyMacro();

   bool             Init(const string symbol);
   void             Deinit();

   // Main entry point for CSensorArray
   void             WeeklyMacro(double weekly_atr);
   
   // Core logic execution method
   void             RunEngine3_WeeklyMacro(double weekly_atr); 

   ENUM_WEEKLY_BIAS GetWeeklyBias()  const { return m_weeklyBias;  }
   double           GetWeeklyHigh()  const { return m_weeklyHigh;  }
   double           GetWeeklyLow()   const { return m_weeklyLow;   }
   double           GetWeeklyATR()   const { return m_weeklyATR;   }
   bool             IsHighVolMode()  const { return m_highVolMode; }

   // ★ ADDED: [Task P2] — Macro Zone Getters
   CPriceZone*      GetMacroHighZone() const { return m_macroHighZone; }
   CPriceZone*      GetMacroLowZone()  const { return m_macroLowZone;  }
};

CEngine3_WeeklyMacro::CEngine3_WeeklyMacro()
   : m_weeklyBias(BIAS_UNDEFINED),
     m_weeklyHigh(0.0),
     m_weeklyLow(0.0),
     m_weeklyATR(0.0),
     m_highVolMode(false),
     m_macroHighZone(NULL),
     m_macroLowZone(NULL) 
{}

CEngine3_WeeklyMacro::~CEngine3_WeeklyMacro() 
{ 
   Deinit(); 
}

bool CEngine3_WeeklyMacro::Init(const string symbol)
{
   m_symbol = symbol;

   if(Bars(symbol, PERIOD_W1) < WEEKLY_MACRO_LOOKBACK)
   {
      PrintFormat("[WARN] %s: Insufficient weekly bar history (%d bars). Need %d.",
                  __FUNCTION__, Bars(symbol, PERIOD_W1), WEEKLY_MACRO_LOOKBACK);
   }
   return true;
}

void CEngine3_WeeklyMacro::Deinit() 
{
   if(m_macroHighZone != NULL)
   {
      delete m_macroHighZone;
      m_macroHighZone = NULL;
   }
   if(m_macroLowZone != NULL)
   {
      delete m_macroLowZone;
      m_macroLowZone = NULL;
   }
}

void CEngine3_WeeklyMacro::WeeklyMacro(double weekly_atr)
{
   RunEngine3_WeeklyMacro(weekly_atr);
}

void CEngine3_WeeklyMacro::RunEngine3_WeeklyMacro(double weekly_atr)
{
   AnalyseWeeklyBias(weekly_atr);
   
   if(m_macroHighZone == NULL) m_macroHighZone = new CPriceZone();
   if(m_macroLowZone == NULL) m_macroLowZone = new CPriceZone();
   
   m_macroHighZone->Init(m_symbol, WEEKLY_MACRO_LOOKBACK);
   m_macroLowZone->Init(m_symbol, WEEKLY_MACRO_LOOKBACK);
   
   // ★ MODIFIED: [Task P2] — Setters logic for CPriceZone
   m_macroHighZone->SetRankAndType(RANK_EXTREME, ZONE_SUPPLY);
   m_macroHighZone->SetZoneLimits(m_weeklyHigh, m_weeklyHigh);
   m_macroLowZone->SetRankAndType(RANK_EXTREME, ZONE_DEMAND);
   m_macroLowZone->SetZoneLimits(m_weeklyLow, m_weeklyLow);
}

void CEngine3_WeeklyMacro::AnalyseWeeklyBias(double weekly_atr)
{
   double open  = iOpen(m_symbol,  PERIOD_W1, 1);
   double close = iClose(m_symbol, PERIOD_W1, 1);
   double high  = iHigh(m_symbol,  PERIOD_W1, 1);
   double low   = iLow(m_symbol,   PERIOD_W1, 1);
   double body  = MathAbs(open - close);
   double range = MathAbs(high - low);
   
   // ★ MODIFIED: [Task P5] — Replaced 0.20 magic number with WEEKLY_NEUTRAL_THRESHOLD
   if(IsWeeklyDoji(1) || body <= (range * WEEKLY_NEUTRAL_THRESHOLD))
   {
      m_weeklyBias = BIAS_NEUTRAL;
   }
   else if(close > open)
   {
      m_weeklyBias = BIAS_BULLISH;
   }
   else if(close < open)
   {
      m_weeklyBias = BIAS_BEARISH;
   }

   int highestIdx = iHighest(m_symbol, PERIOD_W1, MODE_HIGH, WEEKLY_MACRO_LOOKBACK, 1);
   int lowestIdx  = iLowest(m_symbol, PERIOD_W1, MODE_LOW, WEEKLY_MACRO_LOOKBACK, 1);
   
   if(highestIdx >= 0) m_weeklyHigh = iHigh(m_symbol, PERIOD_W1, highestIdx);
   if(lowestIdx >= 0)  m_weeklyLow  = iLow(m_symbol, PERIOD_W1, lowestIdx);
   
   // ★ REMOVED: [Task P8] — Removed temporary iATR handle creation, using passed weekly_atr parameter
   m_weeklyATR = weekly_atr;
}

bool CEngine3_WeeklyMacro::IsWeeklyDoji(const int barIndex) const
{
   double open  = iOpen(m_symbol,  PERIOD_W1, barIndex);
   double close = iClose(m_symbol, PERIOD_W1, barIndex);
   double high  = iHigh(m_symbol,  PERIOD_W1, barIndex);
   double low   = iLow(m_symbol,   PERIOD_W1, barIndex);
   double body  = MathAbs(open - close);
   double range = MathAbs(high - low);
   if(range <= 0) return true;  
   // ★ MODIFIED: [Task P5] — Replaced 0.05 magic number with WEEKLY_DOJI_THRESHOLD
   return (body / range) < WEEKLY_DOJI_THRESHOLD;
}

#endif // CENGINE3_WEEKLYMACRO_MQH
