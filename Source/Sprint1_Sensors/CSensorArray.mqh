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
#include "../Include/DTOs.mqh"
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
   int                    m_lookback;
   string                 m_symbol;
   
   CEngine1_SupplyDemand* m_engine1;
   CEngine2_StandardSR*   m_engine2;
   CEngine3_WeeklyMacro*  m_engine3;
   C_RoleReversalMonitor* m_engine4;

   CPriceZone*            m_active_zones[];

   void                   ClearActiveZones();

public:
                          CSensorArray();
                         ~CSensorArray();

   bool                   Init(const string symbol, int atr_period, int kama_period, int zone_lookback);
   void                   Deinit();
   void                   Update();
   SSensorData            GetData();

   void                   ScanMarketEnvironment();
   int                    GetConfluenceScore(double price);
   ENUM_ZONE_RANK         GetHighestRankAtPrice(double price);
};

CSensorArray::CSensorArray()
   : m_swings(NULL),
     m_kama(NULL),
     m_atr(NULL),
     m_isVix75(false),
     m_lookback(100),
     m_symbol(""),
     m_engine1(NULL),
     m_engine2(NULL),
     m_engine3(NULL),
     m_engine4(NULL)
{
   ArrayResize(m_active_zones, 0);
}

bool CSensorArray::Init(const string symbol, int atr_period, int kama_period, int zone_lookback)
{
   m_symbol = symbol;
   m_isVix75 = (StringFind(symbol, "VIX") >= 0);
   m_lookback = zone_lookback;
   
   m_swings = new C_SwingDetector();
   m_kama = new C_KAMAModule();
   m_atr = new C_ATRModule();
   
   m_engine1 = new CEngine1_SupplyDemand();
   m_engine2 = new CEngine2_StandardSR();
   m_engine3 = new CEngine3_WeeklyMacro();
   m_engine4 = new C_RoleReversalMonitor();
   
   if(!m_swings->Init(symbol) || 
      !m_atr->Init(symbol, atr_period) || 
      !m_kama->Init(symbol, kama_period) ||
      !m_engine1->Init(symbol) || 
      !m_engine2->Init(symbol) || 
      !m_engine3->Init(symbol) || 
      !m_engine4->Init()) 
   {
      return false;
   }
   return true;
}

void CSensorArray::Deinit()
{
   // Strict memory cleanup of dynamically allocated objects
   ClearActiveZones();
   
   if(m_engine1 != NULL) { delete m_engine1; m_engine1 = NULL; }
   if(m_engine2 != NULL) { delete m_engine2; m_engine2 = NULL; }
   if(m_engine3 != NULL) { delete m_engine3; m_engine3 = NULL; }
   if(m_engine4 != NULL) { delete m_engine4; m_engine4 = NULL; }
   
   if(m_swings != NULL)  { delete m_swings;  m_swings = NULL;  }
   if(m_atr != NULL)     { delete m_atr;     m_atr = NULL;     }
   if(m_kama != NULL)    { delete m_kama;    m_kama = NULL;    }
}

CSensorArray::~CSensorArray()
{
   Deinit();
}

void CSensorArray::ClearActiveZones()
{
   int size = ArraySize(m_active_zones);
   for(int i = 0; i < size; i++)
   {
      if(m_active_zones[i] != NULL)
      {
         // ★ MODIFIED: [Framework Alignment] — Do not delete Engine 3 macro zones, role reversal ones ARE deleted
         ENUM_ZONE_RANK zRank = m_active_zones[i]->GetZoneRank();
         if(zRank != RANK_EXTREME)
         {
            delete m_active_zones[i];
         }
         m_active_zones[i] = NULL;
      }
   }
   ArrayResize(m_active_zones, 0);
}

void CSensorArray::ScanMarketEnvironment()
{
   // ORDER IS NON-NEGOTIABLE:
   // Engine 4 must release non-owning zone references
   // BEFORE CSensorArray deletes the zone objects.
   // Reversing this order produces dangling pointers.
   // Step 1a: Flush watchlist
   m_engine4->FlushWatchlist();
   // Step 1b: Clear active zones
   ClearActiveZones();

   // STEP 1b: REFRESH ALL LIVE INDICATORS
   if(m_atr != NULL) 
   {
      m_atr->Update();
      if(m_atr->GetATR(PERIOD_H4) == 0.0)
      {
         PrintFormat("[ERROR] %s: ATR H4 returned zero — scan aborted", __FUNCTION__);
         return;
      }
   }
   
   if(m_kama != NULL)
   {
      m_kama->Update();
      if(m_kama->GetKAMA() == 0.0)
      {
         PrintFormat("[WARN] %s: KAMA returned zero — using previous value", __FUNCTION__);
      }
   }

   // 2. Run Engine 3 (Weekly Macro)
   double w1_atr = m_atr->GetATR(PERIOD_W1);
   double avg_w1_atr = 0.0;
   double w1_buffer[];
   if(m_atr->GetATRBuffer(PERIOD_W1, 14, w1_buffer))
   {
      double sum = 0.0;
      for(int i = 0; i < 14; i++) sum += w1_buffer[i];
      avg_w1_atr = sum / 14.0;
   }
   m_engine3->RunEngine3_WeeklyMacro(w1_atr, avg_w1_atr);

   // STEP 2b: APPEND ENGINE 3 MACRO ZONES TO m_active_zones[]
   CPriceZone* macroHigh = m_engine3->GetMacroHighZone();
   CPriceZone* macroLow  = m_engine3->GetMacroLowZone();
   
   if(macroHigh != NULL && macroHigh->GetZoneHigh() > 0)
   {
      int current_size = ArraySize(m_active_zones);
      ArrayResize(m_active_zones, current_size + 1);
      m_active_zones[current_size] = macroHigh;
   }
   
   if(macroLow != NULL && macroLow->GetZoneLow() > 0)
   {
      int current_size = ArraySize(m_active_zones);
      ArrayResize(m_active_zones, current_size + 1);
      m_active_zones[current_size] = macroLow;
   }

   // 3. Run Engine 1 (Supply/Demand) and Engine 2 (Standard S/R)
   CPriceZone* temp_zones[];
   ArrayResize(temp_zones, 0);
   
   double atr_array[];
   ArraySetAsSeries(atr_array, true);
   int atrHandle = iATR(m_symbol, PERIOD_CURRENT, 14);
   if(atrHandle != INVALID_HANDLE)
   {
      CopyBuffer(atrHandle, 0, 0, 1000, atr_array);
      IndicatorRelease(atrHandle);
   }

   int lookback = m_lookback;
   double variance = m_isVix75 ? 50.0 : 15.0 * _Point;

   m_engine1->DetectZones(m_swings, atr_array, lookback, temp_zones);
   m_engine2->DetectZones(m_swings, variance, lookback, temp_zones);

   // Merge temp_zones into m_active_zones
   int tSize = ArraySize(temp_zones);
   int cSize = ArraySize(m_active_zones);
   ArrayResize(m_active_zones, cSize + tSize);
   for(int i = 0; i < tSize; i++)
   {
      m_active_zones[cSize + i] = temp_zones[i];
   }

   // 4. Run Engine 4 (Role Reversal)
   double close = iClose(m_symbol, PERIOD_CURRENT, 1);
   double open  = iOpen(m_symbol, PERIOD_CURRENT, 1);
   double high  = iHigh(m_symbol, PERIOD_CURRENT, 1);
   double low   = iLow(m_symbol, PERIOD_CURRENT, 1);
   datetime time= iTime(m_symbol, PERIOD_CURRENT, 1);
   double atr_h4 = m_atr->GetATR(PERIOD_H4);

   m_engine4->MonitorActiveZones(m_active_zones, close, open, time, atr_h4);
   m_engine4->MonitorBrokenZones(high, low, close, open);
   m_engine4->PurgeExpiredZones(TimeCurrent(), PeriodSeconds());
}

void CSensorArray::Update()
{
   ScanMarketEnvironment();
}

SSensorData CSensorArray::GetData()
{
   SSensorData data;
   if(m_atr != NULL)
   {
      data.atr_Current = m_atr->GetATR(PERIOD_CURRENT);
      data.atr_H1 = m_atr->GetATR(PERIOD_H1);
      data.atr_H4 = m_atr->GetATR(PERIOD_H4);
      data.atr_D1 = m_atr->GetATR(PERIOD_D1);
      data.atr_W1 = m_atr->GetATR(PERIOD_W1);
   }
   if(m_kama != NULL) data.kama = m_kama->GetKAMA();

   double price = iClose(m_symbol, PERIOD_CURRENT, 0);
   data.zoneRank = GetHighestRankAtPrice(price);
   
   for(int i = 0; i < ArraySize(m_active_zones); i++)
   {
      CPriceZone* z = m_active_zones[i];
      if(z != NULL && z->IsPriceInsideZone(price))
      {
         if(z->GetType() == ZONE_SUPPLY) data.isAtSupplyZone = true;
         if(z->GetType() == ZONE_DEMAND) data.isAtDemandZone = true;
         data.zoneHigh = z->GetZoneHigh();
         data.zoneLow = z->GetZoneLow();
         if(z->GetZoneRank() == data.zoneRank) break;
      }
   }

   if(m_engine3 != NULL)
   {
      data.weeklyBias = m_engine3->GetWeeklyBias();
      data.weeklyATR  = m_engine3->GetWeeklyATR();
      data.isHighVolMode = m_engine3->IsHighVolMode();
   }
   
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int hm = dt.hour * 100 + dt.min;
   if(hm >= ROLLOVER_PAUSE_START || hm < ROLLOVER_PAUSE_END) data.isRolloverWindow = true;
   
   return data;
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
   if(m_kama != NULL)
   {
      double kPrice = m_kama->GetKAMA();
      if(kPrice != 0.0)
      {
         double kVariance = m_isVix75 ? KAMA_CONFLUENCE_VARIANCE_VIX75 : KAMA_CONFLUENCE_VARIANCE_FOREX * _Point;
         if(MathAbs(price - kPrice) <= kVariance) score += 1;
      }
   }
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
