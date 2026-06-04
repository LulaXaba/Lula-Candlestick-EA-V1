//+------------------------------------------------------------------+
//|  CEngine1_SupplyDemand.mqh — Engine 1: Supply & Demand Zones     |
//|  Sprint 1: The Sensor Array                                      |
//|                                                                  |
//|  Responsibility: Detects institutional order blocks via 1-touch  |
//|  swing points followed by explosive 2.0x ATR displacement.       |
//+------------------------------------------------------------------+
#ifndef CENGINE1_SUPPLYDEMAND_MQH
#define CENGINE1_SUPPLYDEMAND_MQH

#include "../../Include/Defines.mqh"
#include "../CPriceZone.mqh"
#include "../C_SwingDetector.mqh"

class CEngine1_SupplyDemand
{
private:
   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;

public:
                     CEngine1_SupplyDemand();
                    ~CEngine1_SupplyDemand();

   bool              Init(const string symbol, ENUM_TIMEFRAMES tf = PERIOD_CURRENT);
   void              Deinit();

   // MQL5 arrays passed by reference (atr_array should be set as series)
   void              DetectZones(C_SwingDetector* swings, double &atr_array[], int lookback_bars, CPriceZone* &out_zones[]);
};

CEngine1_SupplyDemand::CEngine1_SupplyDemand()
{
}

CEngine1_SupplyDemand::~CEngine1_SupplyDemand()
{
   Deinit();
}

bool CEngine1_SupplyDemand::Init(const string symbol, ENUM_TIMEFRAMES tf)
{
   m_symbol    = symbol;
   m_timeframe = tf;
   return true;
}

void CEngine1_SupplyDemand::Deinit()
{
}

void CEngine1_SupplyDemand::DetectZones(C_SwingDetector* swings, double &atr_array[], int lookback_bars, CPriceZone* &out_zones[])
{
   if(swings == NULL) return;

   // Start from lookback_bars to allow checking candles i-1 and i-2 for displacement correctly in a series array
   // ★ MODIFIED: [Framework Alignment] — Reversed loop direction to iterate from oldest to newest
   for(int i = lookback_bars; i >= 2; i--) 
   {
      bool isHigh = swings.IsSwingHigh(i);
      bool isLow  = swings.IsSwingLow(i);

      if(!isHigh && !isLow) continue;
      
      // We need ATR at index i to check if subsequent candles expand >= 2 * ATR
      double atr = atr_array[i];
      if(atr <= 0) continue;

      bool isDisplaced = false;
      
      // Check displacement on candle i-1 or i-2 (the candles immediately after the swing)
      for(int j = 1; j <= 2; j++)
      {
         int checkIdx = i - j;
         if(checkIdx < 0) continue;
         
         double open  = iOpen(m_symbol, m_timeframe, checkIdx);
         double close = iClose(m_symbol, m_timeframe, checkIdx);
         double range = MathAbs(iHigh(m_symbol, m_timeframe, checkIdx) - iLow(m_symbol, m_timeframe, checkIdx));
         double body  = MathAbs(close - open);
         
         if(isLow)
         {
            // Demand: bullish displacement
            if(close > open && (body >= 2.0 * atr || range >= 2.0 * atr))
            {
               isDisplaced = true;
               break;
            }
         }
         else if(isHigh)
         {
            // Supply: bearish displacement
            if(close < open && (body >= 2.0 * atr || range >= 2.0 * atr))
            {
               isDisplaced = true;
               break;
            }
         }
      }
      
      if(isDisplaced)
      {
         int outSize = ArraySize(out_zones);
         ArrayResize(out_zones, outSize + 1);
         
         out_zones[outSize] = new CPriceZone();
         out_zones[outSize].Init(m_symbol, lookback_bars);
         
         // Boundaries are the exact High and Low of the base candle (index i)
         double baseHigh = iHigh(m_symbol, m_timeframe, i);
         double baseLow  = iLow(m_symbol, m_timeframe, i);
         
         out_zones[outSize].SetZoneLimits(baseHigh, baseLow);
         
         // Weight: RANK_2_STANDARD maps to RANK_MAJOR (enum value 2) in Defines.mqh
         ENUM_ZONE_TYPE type = isHigh ? ZONE_SUPPLY : ZONE_DEMAND;
         out_zones[outSize].SetRankAndType(RANK_MAJOR, type);
      }
   }
}

#endif // CENGINE1_SUPPLYDEMAND_MQH
