//+------------------------------------------------------------------+
//|  CEngine1_SupplyDemand.mqh — Engine 1: Supply & Demand Zones    |
//|  Sprint 1: The Sensor Array                                      |
//|                                                                  |
//|  Responsibility: Identify and score institutional Supply and     |
//|  Demand zones based on price origin (base candle) analysis.     |
//+------------------------------------------------------------------+
#ifndef CENGINE1_SUPPLYDEMAND_MQH
#define CENGINE1_SUPPLYDEMAND_MQH

#include "../../Include/Defines.mqh"
#include "../../Include/DTOs.mqh"

class CEngine1_SupplyDemand
{
private:
   string         m_symbol;
   int            m_lookback;
   ENUM_ZONE_TYPE m_detectedZoneType;
   ENUM_ZONE_RANK m_detectedZoneRank;
   double         m_zoneHigh;
   double         m_zoneLow;

   void           ScanZones();
   bool           IsBaseCandle(const int barIndex) const;
   int            CountTouches(const double zHigh, const double zLow) const;

public:
                  CEngine1_SupplyDemand();
                 ~CEngine1_SupplyDemand();

   bool           Init(const string symbol, const int lookback);
   void           Deinit();

   // Called by CSensorArray::Update() — runs the SupplyDemand() scan
   void           SupplyDemand();

   ENUM_ZONE_TYPE GetZoneType() const { return m_detectedZoneType; }
   ENUM_ZONE_RANK GetZoneRank() const { return m_detectedZoneRank; }
   double         GetZoneHigh() const { return m_zoneHigh; }
   double         GetZoneLow()  const { return m_zoneLow;  }
   bool           IsAtSupply()  const { return m_detectedZoneType == ZONE_SUPPLY; }
   bool           IsAtDemand()  const { return m_detectedZoneType == ZONE_DEMAND; }
};

CEngine1_SupplyDemand::CEngine1_SupplyDemand()
   : m_lookback(100),
     m_detectedZoneType(ZONE_NONE),
     m_detectedZoneRank(RANK_WEAK),
     m_zoneHigh(0.0),
     m_zoneLow(0.0) {}

CEngine1_SupplyDemand::~CEngine1_SupplyDemand() { Deinit(); }

bool CEngine1_SupplyDemand::Init(const string symbol, const int lookback)
{
   m_symbol   = symbol;
   m_lookback = lookback;
   return true;
}

void CEngine1_SupplyDemand::Deinit() {}

// Public entry point — called by CSensorArray
void CEngine1_SupplyDemand::SupplyDemand()
{
   ScanZones();
}

void CEngine1_SupplyDemand::ScanZones()
{
   // TODO Sprint 1: Implement Supply/Demand zone detection
   // Algorithm:
   // 1. Iterate bars from 1 to m_lookback
   // 2. Identify "base candles": body < 30% of candle range (consolidation)
   // 3. Check if base candle was followed by a strong impulse move
   //    (next candle body > 2x base candle body = valid origin)
   // 4. Supply zone: strong DOWN impulse after base = overhead supply
   // 5. Demand zone: strong UP impulse after base = underlying demand
   // 6. Zone boundaries = base candle High (zoneHigh) and Low (zoneLow)
   // 7. Call CountTouches() to determine ENUM_ZONE_RANK
   // 8. Check if current Ask/Bid is within zone boundaries
   //    Supply: Ask >= zoneLow && Ask <= zoneHigh
   //    Demand: Bid >= zoneLow && Bid <= zoneHigh

   m_detectedZoneType = ZONE_NONE;
   m_detectedZoneRank = RANK_WEAK;
   m_zoneHigh = 0.0;
   m_zoneLow  = 0.0;
}

bool CEngine1_SupplyDemand::IsBaseCandle(const int barIndex) const
{
   // TODO Sprint 1: Return true if body < 30% of total range
   double open  = iOpen(m_symbol,  PERIOD_H4, barIndex);
   double close = iClose(m_symbol, PERIOD_H4, barIndex);
   double high  = iHigh(m_symbol,  PERIOD_H4, barIndex);
   double low   = iLow(m_symbol,   PERIOD_H4, barIndex);
   double body  = MathAbs(open - close);
   double range = MathAbs(high - low);
   if(range <= 0) return false;
   return (body / range) < 0.30;
}

int CEngine1_SupplyDemand::CountTouches(const double zHigh, const double zLow) const
{
   // TODO Sprint 1: Count how many candles have entered the zone boundary
   // Touch = candle Low <= zHigh AND candle High >= zLow
   int touches = 0;
   for(int i = 1; i <= m_lookback; i++) {
      double hi = iHigh(m_symbol, PERIOD_H4, i);
      double lo = iLow(m_symbol,  PERIOD_H4, i);
      if(lo <= zHigh && hi >= zLow) touches++;
   }
   return touches;
}

#endif // CENGINE1_SUPPLYDEMAND_MQH
