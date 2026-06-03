//+------------------------------------------------------------------+
//|  CSensorArray.mqh — Sensor Aggregator                            |
//|  Sprint 1: The Sensor Array                                      |
//|                                                                  |
//|  Orchestrates all 4 engines and individual sensor modules.       |
//|  Exposes a single SSensorData struct to the rest of the EA.     |
//+------------------------------------------------------------------+
#ifndef CSENSORARRAY_MQH
#define CSENSORARRAY_MQH

#include "../Include/DTOs.mqh"
#include "C_ATRModule.mqh"
#include "C_KAMAModule.mqh"
#include "CPriceZone.mqh"
#include "Detectors/CEngine1_SupplyDemand.mqh"
#include "Detectors/CEngine2_StandardSR.mqh"
#include "Detectors/CEngine3_WeeklyMacro.mqh"
#include "Detectors/CEngine4_RoleReversal.mqh"

class CSensorArray
{
private:
   string                m_symbol;

   // Individual sensor modules
   C_ATRModule           m_atr;
   C_KAMAModule          m_kama;
   CPriceZone            m_zones;

   // The 4 context engines
   CEngine1_SupplyDemand m_engine1;    // SupplyDemand()
   CEngine2_StandardSR   m_engine2;    // StandardSR()
   CEngine3_WeeklyMacro  m_engine3;    // WeeklyMacro()
   CEngine4_RoleReversal m_engine4;    // RoleReversal()

   SSensorData           m_data;       // Cached snapshot — returned by GetData()

   bool                  IsInsideRolloverWindow() const;

public:
                         CSensorArray();
                        ~CSensorArray();

   bool                  Init(const string symbol,
                               const int    atrPeriod,
                               const int    kamaPeriod,
                               const int    zoneLookback);
   void                  Deinit();
   void                  Update();               // Call once per new bar

   const SSensorData&    GetData() const { return m_data; }
};

CSensorArray::CSensorArray() {}
CSensorArray::~CSensorArray() { Deinit(); }

bool CSensorArray::Init(const string symbol,
                        const int    atrPeriod,
                        const int    kamaPeriod,
                        const int    zoneLookback)
{
   m_symbol = symbol;

   if(!m_atr.Init(symbol, atrPeriod))
      { PrintFormat("[ERROR] %s: ATR init failed",          __FUNCTION__); return false; }
   if(!m_kama.Init(symbol, kamaPeriod))
      { PrintFormat("[ERROR] %s: KAMA init failed",         __FUNCTION__); return false; }
   if(!m_zones.Init(symbol, zoneLookback))
      { PrintFormat("[ERROR] %s: PriceZone init failed",    __FUNCTION__); return false; }
   if(!m_engine1.Init(symbol, zoneLookback))
      { PrintFormat("[ERROR] %s: Engine1 S/D init failed",  __FUNCTION__); return false; }
   if(!m_engine2.Init(symbol, zoneLookback))
      { PrintFormat("[ERROR] %s: Engine2 SR init failed",   __FUNCTION__); return false; }
   if(!m_engine3.Init(symbol))
      { PrintFormat("[ERROR] %s: Engine3 Macro init failed",__FUNCTION__); return false; }
   if(!m_engine4.Init(symbol, zoneLookback))
      { PrintFormat("[ERROR] %s: Engine4 RR init failed",   __FUNCTION__); return false; }

   return true;
}

void CSensorArray::Deinit()
{
   m_atr.Deinit();
   m_kama.Deinit();
   m_zones.Deinit();
}

void CSensorArray::Update()
{
   //--- Update base sensor data
   m_atr.Update();
   m_kama.Update();
   m_zones.Update();

   //--- Run all 4 engines
   m_engine1.SupplyDemand();
   m_engine2.StandardSR();
   m_engine3.WeeklyMacro();
   m_engine4.RoleReversal();

   //--- Populate the shared SSensorData snapshot
   m_data.atr_Current = m_atr.GetATR(PERIOD_CURRENT);
   m_data.atr_H1      = m_atr.GetATR(PERIOD_H1);
   m_data.atr_H4      = m_atr.GetATR(PERIOD_H4);
   m_data.atr_D1      = m_atr.GetATR(PERIOD_D1);
   m_data.atr_W1      = m_atr.GetATR(PERIOD_W1);
   m_data.kama        = m_kama.GetKAMA();

   // Zone data: prefer Supply/Demand engine, fall back to StandardSR
   if(m_engine1.IsAtSupply() || m_engine1.IsAtDemand()) {
      m_data.isAtSupplyZone = m_engine1.IsAtSupply();
      m_data.isAtDemandZone = m_engine1.IsAtDemand();
      m_data.zoneRank       = m_engine1.GetZoneRank();
      m_data.zoneHigh       = m_engine1.GetZoneHigh();
      m_data.zoneLow        = m_engine1.GetZoneLow();
   } else if(m_engine4.IsAtReversalZone()) {
      m_data.isAtSupplyZone = (m_engine4.GetReversalType() == ZONE_SUPPLY);
      m_data.isAtDemandZone = (m_engine4.GetReversalType() == ZONE_DEMAND);
      m_data.zoneRank       = RANK_MAJOR;   // Role reversals are always high-rank
      m_data.zoneHigh       = m_engine4.GetReversalLevel();
      m_data.zoneLow        = m_engine4.GetReversalLevel();
   } else {
      m_data.isAtSupplyZone = m_engine2.IsAtResistance();
      m_data.isAtDemandZone = m_engine2.IsAtSupport();
      m_data.zoneRank       = m_zones.GetZoneRank();
      m_data.zoneHigh       = m_engine2.GetNearestResistance();
      m_data.zoneLow        = m_engine2.GetNearestSupport();
   }

   // Weekly bias from Engine 3
   m_data.weeklyBias    = m_engine3.GetWeeklyBias();
   m_data.weeklyATR     = m_engine3.GetWeeklyATR();
   m_data.isHighVolMode = m_engine3.IsHighVolMode();

   // Rollover window flag
   m_data.isRolloverWindow = IsInsideRolloverWindow();
}

bool CSensorArray::IsInsideRolloverWindow() const
{
   // Block new trades during broker rollover (23:55 – 00:05 broker time)
   MqlDateTime t;
   TimeTradeServer(t);
   int hhmm = t.hour * 100 + t.min;
   return (hhmm >= ROLLOVER_PAUSE_START || hhmm <= ROLLOVER_PAUSE_END);
}

#endif // CSENSORARRAY_MQH
