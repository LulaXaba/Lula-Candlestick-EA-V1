//+------------------------------------------------------------------+
//|  CPriceZone.mqh — Supply & Demand Zone Detection                 |
//|  Sprint 1: The Eyes                                              |
//+------------------------------------------------------------------+
#ifndef CPRICEZONE_MQH
#define CPRICEZONE_MQH

#include "../Include/Defines.mqh"

class CPriceZone
{
private:
   string         m_symbol;
   int            m_lookback;       // Bars to scan for swing H/L
   bool           m_isAtSupply;
   bool           m_isAtDemand;
   ENUM_ZONE_RANK m_rank;
   double         m_zoneHigh;
   double         m_zoneLow;

   //--- Internal helpers
   void           DetectZones();
   int            CountZoneTouches(const double zHigh, const double zLow,
                                   const int startBar, const int bars) const;

public:
                  CPriceZone();
                 ~CPriceZone();

   bool           Init(const string symbol, const int lookback);
   void           Deinit();
   void           Update();

   bool           IsAtSupplyZone()  const { return m_isAtSupply; }
   bool           IsAtDemandZone()  const { return m_isAtDemand; }
   ENUM_ZONE_RANK GetZoneRank()     const { return m_rank;       }
   double         GetZoneHigh()     const { return m_zoneHigh;   }
   double         GetZoneLow()      const { return m_zoneLow;    }
};

CPriceZone::CPriceZone()
   : m_lookback(100), m_isAtSupply(false), m_isAtDemand(false),
     m_rank(RANK_WEAK), m_zoneHigh(0.0), m_zoneLow(0.0) {}

CPriceZone::~CPriceZone() { Deinit(); }

bool CPriceZone::Init(const string symbol, const int lookback)
{
   m_symbol   = symbol;
   m_lookback = lookback;
   return true;
}

void CPriceZone::Deinit() {}

void CPriceZone::Update()
{
   DetectZones();
}

void CPriceZone::DetectZones()
{
   // TODO Sprint 1: Implement full supply/demand zone detection
   // Algorithm outline:
   // 1. Find swing highs/lows over m_lookback bars using iHighest/iLowest
   // 2. Identify "base candles" — small-body candles preceding a strong impulse
   // 3. Define zone boundaries as the base candle High/Low
   // 4. Count touches via CountZoneTouches() to determine ENUM_ZONE_RANK
   // 5. Check if current bid/ask is within any detected zone
   // 6. Set m_isAtSupply, m_isAtDemand, m_rank, m_zoneHigh, m_zoneLow

   m_isAtSupply = false;
   m_isAtDemand = false;
   m_rank       = RANK_WEAK;
   m_zoneHigh   = 0.0;
   m_zoneLow    = 0.0;
}

int CPriceZone::CountZoneTouches(const double zHigh, const double zLow,
                                   const int startBar, const int bars) const
{
   // TODO Sprint 1: Count how many times price has entered the zone boundary
   // A "touch" = candle low <= zHigh AND candle high >= zLow
   return 0;
}

#endif // CPRICEZONE_MQH
