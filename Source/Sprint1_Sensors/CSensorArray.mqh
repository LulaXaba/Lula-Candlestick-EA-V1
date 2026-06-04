//+------------------------------------------------------------------+
/// @file    CSensorArray.mqh
/// @brief   Master Sensor Array — orchestrates all 4 detection engines.
/// @author  Lula Engineering Team
//+------------------------------------------------------------------+
#ifndef CSENSORARRAY_MQH
#define CSENSORARRAY_MQH

#include "CPriceZone.mqh"
#include "C_SwingDetector.mqh"
#include "C_ATRModule.mqh"
#include "C_KAMAModule.mqh"
#include "..\Include\DTOs.mqh"

#include "Detectors\CEngine1_SupplyDemand.mqh"
#include "Detectors\CEngine2_StandardSR.mqh"
#include "Detectors\CEngine3_WeeklyMacro.mqh"
#include "Detectors\C_RoleReversalMonitor.mqh"

class CSensorArray
  {
private:
   CPriceZone* m_active_zones[];
   C_SwingDetector* m_swings;
   C_KAMAModule* m_kama;
   C_ATRModule* m_atr;
   
   CEngine1_SupplyDemand* m_e1_sd;
   CEngine2_StandardSR* m_e2_sr;
   CEngine3_WeeklyMacro* m_e3_wm;
   C_RoleReversalMonitor* m_e4_rr;

   bool                    m_is_vix75;
   double                  m_variance_pts;
   int                     m_lookback;

   void                    ClearActiveZones();
   void                    AppendZonesToArray(CPriceZone* &source_array[]);

public:
                           CSensorArray();
                          ~CSensorArray();

   bool                    Init(const string symbol, int atr_period, int kama_fast, int kama_slow, int lookback, bool is_vix75);
   void                    Update(); // The main interface for the EA
   SSensorData             GetData(double current_price);
   
   void                    ScanMarketEnvironment(); // Called by Update()
   int                     GetConfluenceScore(double current_price);
   ENUM_ZONE_RANK          GetHighestRankAtPrice(double current_price);
  };

CSensorArray::CSensorArray() : m_swings(NULL), m_kama(NULL), m_atr(NULL), 
                               m_e1_sd(NULL), m_e2_sr(NULL), m_e3_wm(NULL), m_e4_rr(NULL) {}

CSensorArray::~CSensorArray()
  {
   if(m_e4_rr) m_e4_rr.FlushWatchlist();
   ClearActiveZones();
   
   if(m_e1_sd) { delete m_e1_sd; m_e1_sd = NULL; }
   if(m_e2_sr) { delete m_e2_sr; m_e2_sr = NULL; }
   if(m_e3_wm) { delete m_e3_wm; m_e3_wm = NULL; } // This safely deletes the macro zones
   if(m_e4_rr) { delete m_e4_rr; m_e4_rr = NULL; }
   
   if(m_swings) { delete m_swings; m_swings = NULL; }
   if(m_kama)   { delete m_kama;   m_kama = NULL; }
   if(m_atr)    { delete m_atr;    m_atr = NULL; }
  }

bool CSensorArray::Init(const string symbol, int atr_period, int kama_fast, int kama_slow, int lookback, bool is_vix75)
  {
   m_is_vix75 = is_vix75;
   m_lookback = lookback;
   m_variance_pts = m_is_vix75 ? 50.0 : 15.0 * _Point;

   m_swings = new C_SwingDetector(3, 3, PERIOD_CURRENT);
   m_swings.Init(symbol);
   
   m_kama = new C_KAMAModule();
   m_kama.Init(symbol, kama_fast); // assuming simplified init
   
   m_atr = new C_ATRModule();
   m_atr.Init(symbol, atr_period);
   
   m_e1_sd = new CEngine1_SupplyDemand();
   m_e1_sd.Init(symbol, PERIOD_CURRENT);
   
   m_e2_sr = new CEngine2_StandardSR();
   m_e2_sr.Init(symbol, PERIOD_CURRENT);
   
   m_e3_wm = new CEngine3_WeeklyMacro();
   m_e3_wm.Init(symbol);
   
   m_e4_rr = new C_RoleReversalMonitor();
   
   return true;
  }

void CSensorArray::Update()
  {
   ScanMarketEnvironment();
  }

void CSensorArray::ClearActiveZones()
  {
   int total = ArraySize(m_active_zones);
   for(int i = 0; i < total; i++)
     {
      if(m_active_zones[i] != NULL)
        {
         // Do NOT delete Engine 3 macro zones here as they are owned by CEngine3_WeeklyMacro
         if(m_active_zones[i].GetType() != ZONE_WEEKLY_MACRO)
           {
            delete m_active_zones[i];
           }
         m_active_zones[i] = NULL;
        }
     }
   ArrayResize(m_active_zones, 0);
  }

void CSensorArray::AppendZonesToArray(CPriceZone* &source_array[])
  {
   int src_total = ArraySize(source_array);
   if(src_total == 0) return;
   
   int orig_total = ArraySize(m_active_zones);
   ArrayResize(m_active_zones, orig_total + src_total);
   
   for(int i = 0; i < src_total; i++)
     {
      m_active_zones[orig_total + i] = source_array[i];
     }
  }

void CSensorArray::ScanMarketEnvironment()
  {
   // Flush to prevent dangling pointers!
   m_e4_rr.FlushWatchlist(); 
   ClearActiveZones();

   m_atr.Update(); 
   m_kama.Update();

   // Get W1 array for Engine 3
   double w1_atr_array[15];
   CopyBuffer(iATR(_Symbol, PERIOD_W1, 14), 0, 1, 15, w1_atr_array);
   ArraySetAsSeries(w1_atr_array, true);
   
   m_e3_wm.AnalyseWeeklyBias(w1_atr_array);
   
   // Add Macro Zones explicitly
   int size = ArraySize(m_active_zones);
   ArrayResize(m_active_zones, size + 2);
   m_active_zones[size] = m_e3_wm.GetMacroHighZone();
   m_active_zones[size+1] = m_e3_wm.GetMacroLowZone();

   double current_atr_array[];
   CopyBuffer(iATR(_Symbol, PERIOD_CURRENT, 14), 0, 0, m_lookback + 5, current_atr_array);
   ArraySetAsSeries(current_atr_array, true);

   CPriceZone* e1_output[];
   CPriceZone* e2_output[];

   m_e1_sd.DetectZones(m_swings, current_atr_array, m_lookback, e1_output);
   AppendZonesToArray(e1_output);

   m_e2_sr.DetectZones(m_swings, m_variance_pts, m_lookback, e2_output);
   AppendZonesToArray(e2_output);

   m_e4_rr.MonitorActiveZones(m_active_zones, iClose(_Symbol, PERIOD_CURRENT, 0), iOpen(_Symbol, PERIOD_CURRENT, 0), iTime(_Symbol, PERIOD_CURRENT, 0), current_atr_array[0]);
   m_e4_rr.MonitorBrokenZones(iHigh(_Symbol, PERIOD_CURRENT, 0), iLow(_Symbol, PERIOD_CURRENT, 0), iClose(_Symbol, PERIOD_CURRENT, 0), iOpen(_Symbol, PERIOD_CURRENT, 0));
   m_e4_rr.PurgeExpiredZones(TimeCurrent(), PeriodSeconds());
  }

int CSensorArray::GetConfluenceScore(double current_price)
  {
   int score = 0;
   int total = ArraySize(m_active_zones);
   
   for(int i = 0; i < total; i++)
     {
      if(m_active_zones[i] != NULL && m_active_zones[i].IsPriceInsideZone(current_price))
        {
         ENUM_ZONE_RANK rank = m_active_zones[i].GetRank();
         if(rank == RANK_1_MAXIMUM)  score += 3;
         if(rank == RANK_1_5_HIGH)   score += 2;
         if(rank == RANK_MAJOR)      score += 1;
         if(rank == RANK_MINOR)      score += 1;
        }
     }
     
   double kama_val = m_kama.GetKAMA();
   if(kama_val > 0 && MathAbs(current_price - kama_val) <= m_variance_pts)
     {
      score += 1;
     }
     
   return score;
  }

ENUM_ZONE_RANK CSensorArray::GetHighestRankAtPrice(double current_price)
  {
   ENUM_ZONE_RANK max_rank = RANK_WEAK;
   int total = ArraySize(m_active_zones);
   
   for(int i = 0; i < total; i++)
     {
      if(m_active_zones[i] != NULL && m_active_zones[i].IsPriceInsideZone(current_price))
        {
         if(m_active_zones[i].GetRank() > max_rank)
           max_rank = m_active_zones[i].GetRank();
        }
     }
   return max_rank;
  }

SSensorData CSensorArray::GetData(double current_price)
  {
   SSensorData data;
   // Ensure zero initialization
   ZeroMemory(data);
   
   data.atr_Current  = m_atr.GetATR(PERIOD_CURRENT);
   data.atr_H1       = m_atr.GetATR(PERIOD_H1);
   data.atr_H4       = m_atr.GetATR(PERIOD_H4);
   data.atr_D1       = m_atr.GetATR(PERIOD_D1);
   data.atr_W1       = m_atr.GetATR(PERIOD_W1);
   data.kama         = m_kama.GetKAMA();
   data.weeklyBias   = m_e3_wm.GetWeeklyBias();
   data.weeklyATR    = m_e3_wm.GetWeeklyATR();
   data.isHighVolMode= m_e3_wm.IsHighVolMode();
   data.zoneRank     = GetHighestRankAtPrice(current_price);
   
   int total = ArraySize(m_active_zones);
   for(int i = 0; i < total; i++)
     {
      if(m_active_zones[i] != NULL && m_active_zones[i].IsPriceInsideZone(current_price))
        {
         if(m_active_zones[i].GetType() == ZONE_SUPPLY) data.isAtSupplyZone = true;
         if(m_active_zones[i].GetType() == ZONE_DEMAND) data.isAtDemandZone = true;
         
         if(m_active_zones[i].GetRank() == data.zoneRank)
           {
            data.zoneHigh = m_active_zones[i].GetUpperBound();
            data.zoneLow  = m_active_zones[i].GetLowerBound();
           }
        }
     }
     
   return data;
  }

#endif
