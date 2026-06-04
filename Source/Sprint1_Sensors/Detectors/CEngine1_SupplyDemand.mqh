//+------------------------------------------------------------------+
/// @file    CEngine1_SupplyDemand.mqh
/// @brief   Engine 1: Institutional Supply & Demand zone detector.
/// @author  Lula Engineering Team
//+------------------------------------------------------------------+
#ifndef CENGINE1_SUPPLYDEMAND_MQH
#define CENGINE1_SUPPLYDEMAND_MQH

#include "..\..\Include\Defines.mqh"
#include "..\CPriceZone.mqh"
#include "..\C_SwingDetector.mqh"

class CEngine1_SupplyDemand
  {
private:
   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;

public:
                     CEngine1_SupplyDemand();
                    ~CEngine1_SupplyDemand();

   bool              Init(const string symbol, ENUM_TIMEFRAMES tf = PERIOD_CURRENT);
   void              DetectZones(C_SwingDetector* swings, double &atr_array[], int lookback_bars, CPriceZone* &out_zones[]);
  };

CEngine1_SupplyDemand::CEngine1_SupplyDemand() {}
CEngine1_SupplyDemand::~CEngine1_SupplyDemand() {}

bool CEngine1_SupplyDemand::Init(const string symbol, ENUM_TIMEFRAMES tf)
  {
   m_symbol = symbol;
   m_timeframe = tf;
   return true;
  }

void CEngine1_SupplyDemand::DetectZones(C_SwingDetector* swings, double &atr_array[], int lookback_bars, CPriceZone* &out_zones[])
  {
   ArrayResize(out_zones, 0);
   int zone_count = 0;

   // FIXED: Reverse iteration (oldest to newest relative to the check)
   for(int i = lookback_bars; i >= 2; i--)
     {
      if(!swings.IsSwingHigh(i) && !swings.IsSwingLow(i)) continue;
      
      double atr = atr_array[i];
      if(atr <= 0) continue;
      
      bool isDisplaced = false;
      ENUM_ZONE_TYPE zType = ZONE_STANDARD_SR;
      
      // Check subsequent candles (i-1, i-2)
      for(int j = 1; j <= 2; j++)
        {
         int checkIdx = i - j;
         if(checkIdx < 0) continue;
         
         double open  = iOpen(m_symbol, m_timeframe, checkIdx);
         double close = iClose(m_symbol, m_timeframe, checkIdx);
         double high  = iHigh(m_symbol, m_timeframe, checkIdx);
         double low   = iLow(m_symbol, m_timeframe, checkIdx);
         
         double range = MathAbs(high - low);
         double body  = MathAbs(close - open);
         
         if(swings.IsSwingLow(i) && close > open && (body >= 2.0 * atr || range >= 2.0 * atr))
           {
            isDisplaced = true;
            zType = ZONE_DEMAND;
            break;
           }
           
         if(swings.IsSwingHigh(i) && close < open && (body >= 2.0 * atr || range >= 2.0 * atr))
           {
            isDisplaced = true;
            zType = ZONE_SUPPLY;
            break;
           }
        }
        
      if(isDisplaced)
        {
         CPriceZone* newZone = new CPriceZone();
         newZone.SetZoneLimits(iHigh(m_symbol, m_timeframe, i), iLow(m_symbol, m_timeframe, i));
         newZone.SetRankAndType(RANK_MAJOR, zType);
         
         ArrayResize(out_zones, zone_count + 1);
         out_zones[zone_count] = newZone;
         zone_count++;
        }
     }
  }
#endif
