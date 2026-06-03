//+------------------------------------------------------------------+
//|  CEngine4_RoleReversal.mqh — Engine 4: Role Reversal Levels     |
//|  Sprint 1: The Sensor Array                                      |
//|                                                                  |
//|  Responsibility: Detect broken Support/Resistance levels that    |
//|  have flipped roles. A broken resistance becomes new support,   |
//|  and a broken support becomes new resistance. These "role        |
//|  reversal" levels are the highest-probability retest zones.      |
//+------------------------------------------------------------------+
#ifndef CENGINE4_ROLEREVERSAL_MQH
#define CENGINE4_ROLEREVERSAL_MQH

#include "../../Include/Defines.mqh"
#include "../../Include/DTOs.mqh"

class CEngine4_RoleReversal
{
private:
   string         m_symbol;
   int            m_lookback;
   bool           m_isAtReversalZone;
   ENUM_ZONE_TYPE m_reversalZoneType;   // ZONE_SUPPLY or ZONE_DEMAND (flipped role)
   double         m_reversalLevel;      // The price level of the role reversal

   void           ScanReversals();
   bool           WasBrokenResistance(const double level) const;
   bool           WasBrokenSupport(const double level)    const;

public:
                  CEngine4_RoleReversal();
                 ~CEngine4_RoleReversal();

   bool           Init(const string symbol, const int lookback);
   void           Deinit();

   // Called by CSensorArray::Update() — runs the RoleReversal() scan
   void           RoleReversal();

   bool           IsAtReversalZone() const { return m_isAtReversalZone; }
   ENUM_ZONE_TYPE GetReversalType()  const { return m_reversalZoneType; }
   double         GetReversalLevel() const { return m_reversalLevel;    }
};

CEngine4_RoleReversal::CEngine4_RoleReversal()
   : m_lookback(100),
     m_isAtReversalZone(false),
     m_reversalZoneType(ZONE_NONE),
     m_reversalLevel(0.0) {}

CEngine4_RoleReversal::~CEngine4_RoleReversal() { Deinit(); }

bool CEngine4_RoleReversal::Init(const string symbol, const int lookback)
{
   m_symbol   = symbol;
   m_lookback = lookback;
   return true;
}

void CEngine4_RoleReversal::Deinit() {}

void CEngine4_RoleReversal::RoleReversal()
{
   ScanReversals();
}

void CEngine4_RoleReversal::ScanReversals()
{
   // TODO Sprint 1: Implement Role Reversal detection
   // Algorithm:
   //
   // 1. Use Engine 2 swing highs as candidate resistance levels
   // 2. Scan forward to find if price closed ABOVE that resistance (breakout)
   //    → That level is now "flipped to support" (role reversal demand zone)
   // 3. Use Engine 2 swing lows as candidate support levels
   // 4. Scan forward to find if price closed BELOW that support
   //    → That level is now "flipped to resistance" (role reversal supply zone)
   //
   // 5. For the highest-ranked reversal level, check if current price
   //    is retesting it from the new direction:
   //    Flipped support: price pulls back down to the level from above
   //    Flipped resistance: price rallies back up to the level from below
   //
   // 6. A retest within ATR(H4) distance = m_isAtReversalZone = true
   // 7. Set m_reversalZoneType = ZONE_ROLE_REVERSAL

   m_isAtReversalZone = false;
   m_reversalZoneType = ZONE_NONE;
   m_reversalLevel    = 0.0;
}

bool CEngine4_RoleReversal::WasBrokenResistance(const double level) const
{
   // TODO Sprint 1: Return true if a candle closed above 'level'
   // after that level was established as resistance
   return false;
}

bool CEngine4_RoleReversal::WasBrokenSupport(const double level) const
{
   // TODO Sprint 1: Return true if a candle closed below 'level'
   // after that level was established as support
   return false;
}

#endif // CENGINE4_ROLEREVERSAL_MQH
