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
   // ★ ADDED: [Task P1] — Missing properties
   ENUM_ZONE_TYPE m_type;
   bool           m_is_active;
   bool           m_is_broken;
   bool           m_retest_valid;
   datetime       m_break_time;
   int            m_touch_count;

   //--- Internal helpers
   void           DetectZones();
   // ★ REMOVED: [Task P7] — CountZoneTouches stub removed, managed by Engine 2 via IncrementTouchCount

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

   // ★ ADDED: [Task P1] — Missing CPriceZone methods required by Engines
   void           SetZoneLimits(double upper, double lower);
   void           SetRankAndType(ENUM_ZONE_RANK rank, ENUM_ZONE_TYPE type);
   ENUM_ZONE_TYPE GetType()         const { return m_type;       }
   bool           IsActive()        const { return m_is_active;  }
   int            GetTouchCount()   const { return m_touch_count;}
   void           IncrementTouchCount()   { m_touch_count++;     }
   void           BreakZone(datetime break_time);
   void           ValidateRetest();
   bool           IsBroken()        const { return m_is_broken;  }
   bool           IsRetestValid()   const { return m_retest_valid;}
   datetime       GetBreakTime()    const { return m_break_time; }
   bool           IsPriceInsideZone(double price) const;
};

CPriceZone::CPriceZone()
   : m_lookback(100), m_isAtSupply(false), m_isAtDemand(false),
     m_rank(RANK_WEAK), m_zoneHigh(0.0), m_zoneLow(0.0),
     m_type(ZONE_NONE), m_is_active(true), m_is_broken(false),
     m_retest_valid(false), m_break_time(0), m_touch_count(0) {}

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
   // Note: Engine-set values like m_rank, m_zoneHigh, and m_zoneLow 
   // should not be reset here as they are managed externally by engines.
}

// ★ REMOVED: [Task P7] — CountZoneTouches implementation removed

// ★ ADDED: [Task P1] — Missing CPriceZone method implementations
void CPriceZone::SetZoneLimits(double upper, double lower)
{
   if(upper < lower)
   {
      m_zoneHigh = lower;
      m_zoneLow = upper;
   }
   else
   {
      m_zoneHigh = upper;
      m_zoneLow = lower;
   }
}

void CPriceZone::SetRankAndType(ENUM_ZONE_RANK rank, ENUM_ZONE_TYPE type)
{
   m_rank = rank;
   m_type = type;
}

void CPriceZone::BreakZone(datetime break_time)
{
   m_is_broken = true;
   m_is_active = false;
   m_break_time = break_time;
}

void CPriceZone::ValidateRetest()
{
   if(m_is_broken)
   {
      m_retest_valid = true;
      m_type = ZONE_ROLE_REVERSAL;
   }
}

bool CPriceZone::IsPriceInsideZone(double price) const
{
   if(m_is_broken) return false;
   if(m_zoneHigh == 0.0 || m_zoneLow == 0.0) return false;
   return (price >= m_zoneLow && price <= m_zoneHigh);
}

#endif // CPRICEZONE_MQH
