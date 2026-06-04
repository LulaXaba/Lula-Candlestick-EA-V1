//+------------------------------------------------------------------+
//|  C_RoleReversalMonitor.mqh — Engine 4: Role Reversal             |
//|  Sprint 1: The Sensor Array                                      |
//|                                                                  |
//|  Responsibility: Monitors broken Standard S/R zones for a        |
//|  "Change of Polarity" retest and elevates their status.          |
//+------------------------------------------------------------------+
#ifndef C_ROLEREVERSALMONITOR_MQH
#define C_ROLEREVERSALMONITOR_MQH

#include "../../Include/Defines.mqh"
#include "../CPriceZone.mqh"

#ifndef ROLE_REVERSAL_MAX_BARS
#define ROLE_REVERSAL_MAX_BARS 50
#endif

class C_RoleReversalMonitor
{
private:
   CPriceZone*       m_broken_zones[]; // Watchlist array for broken zones

public:
                     C_RoleReversalMonitor();
                    ~C_RoleReversalMonitor();

   bool              Init();
   void              Deinit();

   // Checks if an active standard S/R zone has been cleanly broken by the candle body
   // ★ MODIFIED: [Task P9] — Added atr_h4 parameter
   void              MonitorActiveZones(CPriceZone* &active_zones[], double close, double open, datetime time, double atr_h4);
   
   // ★ ADDED: [Task P4] — Clears watchlist without deleting objects
   void              FlushWatchlist();
   
   // Checks if broken zones have been successfully retested
   void              MonitorBrokenZones(double high, double low, double close, double open);
   
   // Purges zones that have been broken longer than ROLE_REVERSAL_MAX_BARS
   void              PurgeExpiredZones(datetime current_time, int timeframe_seconds);
   
private:
   void              RemoveZoneFromWatchlist(int index);
};

C_RoleReversalMonitor::C_RoleReversalMonitor()
{
   ArrayResize(m_broken_zones, 0);
}

C_RoleReversalMonitor::~C_RoleReversalMonitor()
{
   Deinit();
}

bool C_RoleReversalMonitor::Init()
{
   return true;
}

void C_RoleReversalMonitor::Deinit()
{
   // Do not delete pointers as they are managed by CSensorArray, just clear array
   ArrayResize(m_broken_zones, 0);
}

void C_RoleReversalMonitor::FlushWatchlist()
{
   ArrayResize(m_broken_zones, 0);
}

void C_RoleReversalMonitor::MonitorActiveZones(CPriceZone* &active_zones[], double close, double open, datetime time, double atr_h4)
{
   for(int i = 0; i < ArraySize(active_zones); i++)
   {
      CPriceZone* zone = active_zones[i];
      if(zone == NULL) continue;
      
      // We monitor Standard S/R (RANK_MAJOR or RANK_MINOR) for Role Reversal
      ENUM_ZONE_RANK rank = zone.GetZoneRank();
      if(rank == RANK_WEAK || rank == RANK_EXTREME) continue;
      
      double zHigh = zone.GetZoneHigh();
      double zLow  = zone.GetZoneLow();
      
      // Clean body breakout check (Primary)
      bool brokenUp   = (open < zLow && close > zHigh);
      bool brokenDown = (open > zHigh && close < zLow);
      
      // ★ ADDED: [Task P9] — Secondary breakout condition
      bool brokenUpSecondary = (open <= zHigh) && (close > zHigh + (atr_h4 * 0.5)) && (close > open);
      bool brokenDownSecondary = (open >= zLow) && (close < zLow - (atr_h4 * 0.5)) && (close < open);
      
      if(brokenUp || brokenDown || brokenUpSecondary || brokenDownSecondary)
      {
         // Mark the zone as broken
         zone.BreakZone(time); 
         
         int size = ArraySize(m_broken_zones);
         ArrayResize(m_broken_zones, size + 1);
         m_broken_zones[size] = zone;
      }
   }
}

void C_RoleReversalMonitor::MonitorBrokenZones(double high, double low, double close, double open)
{
   for(int i = ArraySize(m_broken_zones) - 1; i >= 0; i--)
   {
      CPriceZone* zone = m_broken_zones[i];
      if(zone == NULL) continue;
      
      double zHigh = zone.GetZoneHigh();
      double zLow  = zone.GetZoneLow();
      
      // Check if price pulled back into the zone boundaries (retest)
      bool retested = (low <= zHigh && high >= zLow);
      if(!retested) continue;
      
      // Check if the candle closed away from the zone in the breakout direction
      // For now, assuming a pseudo GetType() exists. 
      // If none exists, this will need CPriceZone structure updates.
      // ENUM_ZONE_TYPE origType = zone->GetType(); 
      bool validRejection = false;
      
      // Example Placeholder Logic (Requires actual ENUM_ZONE_TYPE getter):
      // if(origType == ZONE_SUPPLY && close > open && close > zHigh) validRejection = true;
      // else if(origType == ZONE_DEMAND && close < open && close < zLow) validRejection = true;
      
      // Fallback pseudo-logic: evaluate rejection strictly by close vs open and zone limits
      // ★ MODIFIED: [Framework Alignment] — Clarified comments. Broken resistance becomes support (bullish rejection). Broken support becomes resistance (bearish rejection).
      if(close > open && close > zHigh) validRejection = true; // Broken resistance retested as support -> Bullish rejection
      if(close < open && close < zLow) validRejection = true;  // Broken support retested as resistance -> Bearish rejection

      if(validRejection)
      {
         // Validates the retest and elevates rank
         zone.ValidateRetest();
         RemoveZoneFromWatchlist(i);
      }
   }
}

void C_RoleReversalMonitor::PurgeExpiredZones(datetime current_time, int timeframe_seconds)
{
   int max_seconds = ROLE_REVERSAL_MAX_BARS * timeframe_seconds;
   
   for(int i = ArraySize(m_broken_zones) - 1; i >= 0; i--)
   {
      CPriceZone* zone = m_broken_zones[i];
      if(zone == NULL) continue;
      
      // Check expiration
      datetime breakTime = zone.GetBreakTime();
      
      if(breakTime > 0 && (current_time - breakTime > max_seconds))
      {
         RemoveZoneFromWatchlist(i);
      }
   }
}

void C_RoleReversalMonitor::RemoveZoneFromWatchlist(int index)
{
   int size = ArraySize(m_broken_zones);
   if(index < 0 || index >= size) return;
   
   for(int i = index; i < size - 1; i++)
   {
      m_broken_zones[i] = m_broken_zones[i+1];
   }
   ArrayResize(m_broken_zones, size - 1);
}

#endif // C_ROLEREVERSALMONITOR_MQH
