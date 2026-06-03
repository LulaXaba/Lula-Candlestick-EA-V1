//+------------------------------------------------------------------+
//|  CEngine3_WeeklyMacro.mqh — Engine 3: Weekly Macro Levels       |
//|  Sprint 1: The Sensor Array                                      |
//|                                                                  |
//|  Responsibility: Determine the weekly macro bias (bullish /      |
//|  bearish / neutral) and identify key weekly price levels.        |
//|  Scan depth: WEEKLY_MACRO_LOOKBACK = 26 bars (~6 months).       |
//+------------------------------------------------------------------+
#ifndef CENGINE3_WEEKLYMACRO_MQH
#define CENGINE3_WEEKLYMACRO_MQH

#include "../../Include/Defines.mqh"
#include "../../Include/DTOs.mqh"

class CEngine3_WeeklyMacro
{
private:
   string           m_symbol;
   ENUM_WEEKLY_BIAS m_weeklyBias;
   double           m_weeklyHigh;    // Highest high of last WEEKLY_MACRO_LOOKBACK bars
   double           m_weeklyLow;     // Lowest low of last WEEKLY_MACRO_LOOKBACK bars
   double           m_weeklyATR;     // Weekly ATR — compared to VIX75_MIN_ATR
   bool             m_highVolMode;   // true if weekly ATR > 2x average (HIGH_VOL mode)

   void             AnalyseWeeklyBias();
   bool             IsWeeklyDoji(const int barIndex) const;

public:
                    CEngine3_WeeklyMacro();
                   ~CEngine3_WeeklyMacro();

   bool             Init(const string symbol);
   void             Deinit();

   // Called by CSensorArray::Update() — runs the WeeklyMacro() analysis
   void             WeeklyMacro();

   ENUM_WEEKLY_BIAS GetWeeklyBias()  const { return m_weeklyBias;  }
   double           GetWeeklyHigh()  const { return m_weeklyHigh;  }
   double           GetWeeklyLow()   const { return m_weeklyLow;   }
   double           GetWeeklyATR()   const { return m_weeklyATR;   }
   bool             IsHighVolMode()  const { return m_highVolMode;  }
};

CEngine3_WeeklyMacro::CEngine3_WeeklyMacro()
   : m_weeklyBias(BIAS_UNDEFINED),
     m_weeklyHigh(0.0),
     m_weeklyLow(0.0),
     m_weeklyATR(0.0),
     m_highVolMode(false) {}

CEngine3_WeeklyMacro::~CEngine3_WeeklyMacro() { Deinit(); }

bool CEngine3_WeeklyMacro::Init(const string symbol)
{
   m_symbol = symbol;

   // Validate that we have enough weekly bars (26 = ~6 months)
   if(Bars(symbol, PERIOD_W1) < WEEKLY_MACRO_LOOKBACK)
   {
      PrintFormat("[WARN] %s: Insufficient weekly bar history (%d bars). Need %d.",
                  __FUNCTION__, Bars(symbol, PERIOD_W1), WEEKLY_MACRO_LOOKBACK);
      // Not a hard failure — continue with available data
   }
   return true;
}

void CEngine3_WeeklyMacro::Deinit() {}

void CEngine3_WeeklyMacro::WeeklyMacro()
{
   AnalyseWeeklyBias();
}

void CEngine3_WeeklyMacro::AnalyseWeeklyBias()
{
   // TODO Sprint 1: Implement weekly macro analysis
   // Algorithm (scan only WEEKLY_MACRO_LOOKBACK = 26 bars):
   //
   // 1. Read bar[1] = last CLOSED weekly candle
   //    open  = iOpen(m_symbol,  PERIOD_W1, 1)
   //    close = iClose(m_symbol, PERIOD_W1, 1)
   //    high  = iHigh(m_symbol,  PERIOD_W1, 1)
   //    low   = iLow(m_symbol,   PERIOD_W1, 1)
   //    body  = MathAbs(open - close)        // See Docs/09_RESEARCH_NOTES.md
   //    range = MathAbs(high - low)
   //
   // 2. Bias determination:
   //    BULLISH: close > open AND body > (range * 0.20)  // meaningful close
   //    BEARISH: close < open AND body > (range * 0.20)
   //    NEUTRAL: IsWeeklyDoji() OR body <= (range * 0.20)
   //
   // 3. Weekly macro levels:
   //    m_weeklyHigh = iHighest over WEEKLY_MACRO_LOOKBACK weekly bars
   //    m_weeklyLow  = iLowest  over WEEKLY_MACRO_LOOKBACK weekly bars
   //
   // 4. High volatility mode:
   //    m_weeklyATR = ATR(14) on PERIOD_W1
   //    If m_weeklyATR > (average of last 14 weekly ATRs * 2) → m_highVolMode = true
   //    Also: if m_weeklyATR < VIX75_MIN_ATR → ATR gate will block all trades

   m_weeklyBias  = BIAS_UNDEFINED;
   m_weeklyHigh  = 0.0;
   m_weeklyLow   = 0.0;
   m_weeklyATR   = 0.0;
   m_highVolMode = false;
}

bool CEngine3_WeeklyMacro::IsWeeklyDoji(const int barIndex) const
{
   // TODO Sprint 1: Doji = body < 5% of range
   double open  = iOpen(m_symbol,  PERIOD_W1, barIndex);
   double close = iClose(m_symbol, PERIOD_W1, barIndex);
   double high  = iHigh(m_symbol,  PERIOD_W1, barIndex);
   double low   = iLow(m_symbol,   PERIOD_W1, barIndex);
   double body  = MathAbs(open - close);
   double range = MathAbs(high - low);
   if(range <= 0) return true;  // Zero-range bar = treat as doji
   return (body / range) < 0.05;
}

#endif // CENGINE3_WEEKLYMACRO_MQH
