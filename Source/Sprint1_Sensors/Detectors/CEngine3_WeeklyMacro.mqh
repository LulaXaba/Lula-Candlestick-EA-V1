//+------------------------------------------------------------------+
/// @file    CEngine3_WeeklyMacro.mqh
/// @brief   Engine 3: Weekly Macro bias determination.
/// @author  Lula Engineering Team
//+------------------------------------------------------------------+
#ifndef CENGINE3_WEEKLYMACRO_MQH
#define CENGINE3_WEEKLYMACRO_MQH

#include "..\..\Include\Defines.mqh"
#include "..\CPriceZone.mqh"

class CEngine3_WeeklyMacro
  {
private:
   string            m_symbol;
   ENUM_WEEKLY_BIAS  m_weeklyBias;
   double            m_weeklyHigh;
   double            m_weeklyLow;
   double            m_weeklyATR;
   bool              m_highVolMode;
   
   CPriceZone* m_macroHighZone;
   CPriceZone* m_macroLowZone;

   bool              IsWeeklyDoji(const int barIndex) const;

public:
                     CEngine3_WeeklyMacro();
                    ~CEngine3_WeeklyMacro();

   bool              Init(const string symbol);
   void              Deinit();
   void              AnalyseWeeklyBias(double &w1_atr_array[]); // Takes populated array instead of handle
   
   CPriceZone* GetMacroHighZone() const { return m_macroHighZone; }
   CPriceZone* GetMacroLowZone() const { return m_macroLowZone; }
   ENUM_WEEKLY_BIAS  GetWeeklyBias() const { return m_weeklyBias; }
   double            GetWeeklyATR()  const { return m_weeklyATR; }
   bool              IsHighVolMode() const { return m_highVolMode; }
  };

CEngine3_WeeklyMacro::CEngine3_WeeklyMacro() : m_weeklyBias(BIAS_UNDEFINED), m_weeklyHigh(0.0), 
                                               m_weeklyLow(0.0), m_weeklyATR(0.0), m_highVolMode(false),
                                               m_macroHighZone(NULL), m_macroLowZone(NULL) {}

CEngine3_WeeklyMacro::~CEngine3_WeeklyMacro() { Deinit(); }

bool CEngine3_WeeklyMacro::Init(const string symbol)
  {
   m_symbol = symbol;
   return true;
  }

void CEngine3_WeeklyMacro::Deinit()
  {
   if(m_macroHighZone != NULL) { delete m_macroHighZone; m_macroHighZone = NULL; }
   if(m_macroLowZone != NULL)  { delete m_macroLowZone;  m_macroLowZone = NULL; }
  }

bool CEngine3_WeeklyMacro::IsWeeklyDoji(const int barIndex) const
  {
   double open  = iOpen(m_symbol, PERIOD_W1, barIndex);
   double close = iClose(m_symbol, PERIOD_W1, barIndex);
   double high  = iHigh(m_symbol, PERIOD_W1, barIndex);
   double low   = iLow(m_symbol, PERIOD_W1, barIndex);
   
   double range = MathAbs(high - low);
   double body  = MathAbs(open - close);
   
   if(range <= 0) return true;
   return (body / range) <= WEEKLY_DOJI_THRESHOLD;
  }

void CEngine3_WeeklyMacro::AnalyseWeeklyBias(double &w1_atr_array[])
  {
   if(m_macroHighZone == NULL) m_macroHighZone = new CPriceZone();
   if(m_macroLowZone == NULL)  m_macroLowZone  = new CPriceZone();

   double open  = iOpen(m_symbol, PERIOD_W1, 1);
   double close = iClose(m_symbol, PERIOD_W1, 1);
   double high  = iHigh(m_symbol, PERIOD_W1, 1);
   double low   = iLow(m_symbol, PERIOD_W1, 1);
   
   double range = MathAbs(high - low);
   double body  = MathAbs(open - close);

   if(IsWeeklyDoji(1) || body <= (range * WEEKLY_NEUTRAL_THRESHOLD))
      m_weeklyBias = BIAS_NEUTRAL;
   else if(close > open)
      m_weeklyBias = BIAS_BULLISH;
   else if(close < open)
      m_weeklyBias = BIAS_BEARISH;

   int highestIdx = iHighest(m_symbol, PERIOD_W1, MODE_HIGH, 26, 1);
   int lowestIdx  = iLowest(m_symbol, PERIOD_W1, MODE_LOW, 26, 1);
   m_weeklyHigh   = iHigh(m_symbol, PERIOD_W1, highestIdx);
   m_weeklyLow    = iLow(m_symbol, PERIOD_W1, lowestIdx);

   // Volatility check via passed-in W1 array (fixes temporary handle issue)
   if(ArraySize(w1_atr_array) >= 15)
     {
      m_weeklyATR = w1_atr_array[0];
      double avgATR = 0;
      for(int i = 1; i <= 14; i++) avgATR += w1_atr_array[i];
      avgATR /= 14.0;
      
      m_highVolMode = (m_weeklyATR > (2.0 * avgATR));
     }

   // Zone width is 10% of Weekly ATR
   double zoneWidth = m_weeklyATR > 0 ? m_weeklyATR * 0.1 : 10.0 * _Point;
   
   m_macroHighZone.SetZoneLimits(m_weeklyHigh + zoneWidth, m_weeklyHigh - zoneWidth);
   m_macroHighZone.SetRankAndType(RANK_1_MAXIMUM, ZONE_WEEKLY_MACRO);
   
   m_macroLowZone.SetZoneLimits(m_weeklyLow + zoneWidth, m_weeklyLow - zoneWidth);
   m_macroLowZone.SetRankAndType(RANK_1_MAXIMUM, ZONE_WEEKLY_MACRO);
  }
#endif
