//+------------------------------------------------------------------+
//|  CSensorArray.mqh — Master Sensor Array Manager                  |
//|  Sprint 1: The Sensor Array                                      |
//|                                                                  |
//|  Responsibility: Instantiates all 4 Engines, orchestrates the    |
//|  scan sequence, aggregates zones, strictly manages memory,       |
//|  and calculates the overall Confluence Score.                    |
//+------------------------------------------------------------------+
#ifndef CSENSORARRAY_MQH
#define CSENSORARRAY_MQH

#include "../Include/Defines.mqh"
#include "CPriceZone.mqh"
#include "C_SwingDetector.mqh"
#include "C_ATRModule.mqh"
#include "C_KAMAModule.mqh"
#include "Detectors/CEngine1_SupplyDemand.mqh"
#include "Detectors/CEngine2_StandardSR.mqh"
#include "Detectors/CEngine3_WeeklyMacro.mqh"
#include "Detectors/C_RoleReversalMonitor.mqh"

class CSensorArray
{
private:
   C_SwingDetector*       m_swings;
   C_KAMAModule*          m_kama;
   C_ATRModule*           m_atr;
   bool                   m_isVix75;
   
   CEngine1_SupplyDemand* m_engine1;
   CEngine2_StandardSR*   m_engine2;
   CEngine3_WeeklyMacro*  m_engine3;
   C_RoleReversalMonitor* m_engine4;

   CPriceZone*            m_active_zones[];

   void                   ClearActiveZones();

public:
                          CSensorArray(C_SwingDetector* swings, C_KAMAModule* kama, C_ATRModule* atr, bool is_vix75);
                         ~CSensorArray();

   void                   ScanMarketEnvironment();
   int                    GetConfluenceScore(double price);
   ENUM_ZONE_RANK         GetHighestRankAtPrice(double price);
};

CSensorArray::CSensorArray(C_SwingDetector* swings, C_KAMAModule* kama, C_ATRModule* atr, bool is_vix75)
   : m_swings(swings),
     m_kama(kama),
     m_atr(atr),
     m_isVix75(is_vix75)
{
   m_engine1 = new CEngine1_SupplyDemand();
   m_engine2 = new CEngine2_StandardSR();
   m_engine3 = new CEngine3_WeeklyMacro();
   m_engine4 = new C_RoleReversalMonitor();
   
   m_engine1->Init(_Symbol);
   m_engine2->Init(_Symbol);
   m_engine3->Init(_Symbol);
   m_engine4->Init();
   
   ArrayResize(m_active_zones, 0);
}

CSensorArray::~CSensorArray()
{
   // Strict memory cleanup of dynamically allocated objects
   ClearActiveZones();
   
   if(m_engine1 != NULL) { delete m_engine1; m_engine1 = NULL; }
   if(m_engine2 != NULL) { delete m_engine2; m_engine2 = NULL; }
   if(m_engine3 != NULL) { delete m_engine3; m_engine3 = NULL; }
   if(m_engine4 != NULL) { delete m_engine4; m_engine4 = NULL; }
}

void CSensorArray::ClearActiveZones()
{
   int size = ArraySize(m_active_zones);
   for(int i = 0; i < size; i++)
   {
      if(m_active_zones[i] != NULL)
      {
         delete m_active_zones[i];
         m_active_zones[i] = NULL;
      }
   }
   ArrayResize(m_active_zones, 0);
}

void CSensorArray::ScanMarketEnvironment()
{
   // Flush memory before rebuilding zones
   ClearActiveZones();

   // 1. Update ATR and KAMA (Assuming Update() methods exist on these modules)
   // if(m_atr != NULL) m_atr->Update();
   // if(m_kama != NULL) m_kama->Update();

   // 2. Run Engine 3 (Weekly Macro)
   m_engine3->WeeklyMacro();
   // Note: The resulting macro zones from engine 3 would be fetched and appended here.
   // e.g., AddZone(m_engine3->GetSupplyZone()); AddZone(m_engine3->GetDemandZone());

   // 3. Run Engine 1 (Supply/Demand) and Engine 2 (Standard S/R)
   CPriceZone* temp_zones[];
   ArrayResize(temp_zones, 0);
   
   double atr_array[];
   ArraySetAsSeries(atr_array, true);
   int atrHandle = iATR(_Symbol, PERIOD_CURRENT, 14);
   if(atrHandle != INVALID_HANDLE)
   {
      CopyBuffer(atrHandle, 0, 0, 1000, atr_array);
      IndicatorRelease(atrHandle);
   }

   int lookback = m_isVix75 ? 500 : 1000;
   double variance = m_isVix75 ? 50.0 : 15.0 * _Point;

   m_engine1->DetectZones(m_swings, atr_array, lookback, temp_zones);
   m_engine2->DetectZones(m_swings, variance, lookback, temp_zones);

   // Merge temp_zones into m_active_zones
   int tSize = ArraySize(temp_zones);
   ArrayResize(m_active_zones, tSize);
   for(int i = 0; i < tSize; i++)
   {
      m_active_zones[i] = temp_zones[i];
   }

   // 4. Run Engine 4 (Role Reversal)
   double close = iClose(_Symbol, PERIOD_CURRENT, 1);
   double open  = iOpen(_Symbol, PERIOD_CURRENT, 1);
   double high  = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double low   = iLow(_Symbol, PERIOD_CURRENT, 1);
   datetime time= iTime(_Symbol, PERIOD_CURRENT, 1);

   m_engine4->MonitorActiveZones(m_active_zones, close, open, time);
   m_engine4->MonitorBrokenZones(high, low, close, open);
   m_engine4->PurgeExpiredZones(TimeCurrent(), PeriodSeconds());
}

int CSensorArray::GetConfluenceScore(double price)
{
   int score = 0;
   
   // Check price against all active zones
   for(int i = 0; i < ArraySize(m_active_zones); i++)
   {
      CPriceZone* zone = m_active_zones[i];
      if(zone == NULL) continue;
      
      double zHigh = zone->GetZoneHigh();
      double zLow  = zone->GetZoneLow();
      
      // If price intersects the zone boundary
      if(price <= zHigh && price >= zLow)
      {
         ENUM_ZONE_RANK rank = zone->GetZoneRank();
         
         if(rank == RANK_EXTREME) score += 3; // Weekly Macro (Rank 1)
         else if(zone->GetType() == ZONE_ROLE_REVERSAL) score += 2; // Role Reversal (Rank 1.5)
         else score += 1; // Supply/Demand or Standard SR (Rank 2)
      }
   }
   
   // KAMA dynamic level (+1 point)
   // Approximation check:
   /*
   if(m_kama != NULL)
   {
      double kPrice = m_kama->GetKAMA();
      double kVariance = m_isVix75 ? 20.0 : 5.0 * _Point;
      if(MathAbs(price - kPrice) <= kVariance) score += 1;
   }
   */
   return score;
}

ENUM_ZONE_RANK CSensorArray::GetHighestRankAtPrice(double price)
{
   ENUM_ZONE_RANK highest = RANK_WEAK;
   for(int i = 0; i < ArraySize(m_active_zones); i++)
   {
      CPriceZone* zone = m_active_zones[i];
      if(zone == NULL) continue;
      
      if(price <= zone->GetZoneHigh() && price >= zone->GetZoneLow())
      {
         ENUM_ZONE_RANK r = zone->GetZoneRank();
         if(r > highest) highest = r;
      }
   }
   return highest;
}

#endif // CSENSORARRAY_MQH
