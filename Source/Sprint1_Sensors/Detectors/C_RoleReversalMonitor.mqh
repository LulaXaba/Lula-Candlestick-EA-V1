//+------------------------------------------------------------------+
/// @file    C_RoleReversalMonitor.mqh
/// @brief   Engine 4: Polarity Watchdog — Change-of-Polarity retest.
/// @author  Lula Engineering Team
//+------------------------------------------------------------------+
#ifndef C_ROLEREVERSALMONITOR_MQH
#define C_ROLEREVERSALMONITOR_MQH

#include "..\..\Include\Defines.mqh"
#include "..\CPriceZone.mqh"

class C_RoleReversalMonitor
  {
private:
   CPriceZone* m_broken_zones[];

   void              RemoveZoneFromWatchlist(int index);

public:
                     C_RoleReversalMonitor();
                    ~C_RoleReversalMonitor();

   void              FlushWatchlist();
   void              MonitorActiveZones(CPriceZone* &active_zones[], double close, double open, datetime time, double current_atr);
   void              MonitorBrokenZones(double high, double low, double close, double open);
   void              PurgeExpiredZones(datetime current_time, int timeframe_seconds);
  };

C_RoleReversalMonitor::C_RoleReversalMonitor() { FlushWatchlist(); }
C_RoleReversalMonitor::~C_RoleReversalMonitor() { FlushWatchlist(); }

void C_RoleReversalMonitor::FlushWatchlist()
  {
   ArrayResize(m_broken_zones, 0);
  }

void C_RoleReversalMonitor::RemoveZoneFromWatchlist(int index)
  {
   int size = ArraySize(m_broken_zones);
   for(int i = index; i < size - 1; i++)
     {
      m_broken_zones[i] = m_broken_zones[i + 1];
     }
   ArrayResize(m_broken_zones, size - 1);
  }

void C_RoleReversalMonitor::MonitorActiveZones(CPriceZone* &active_zones[], double close, double open, datetime time, double current_atr)
  {
   int size = ArraySize(active_zones);
   for(int i = 0; i < size; i++)
     {
      if(active_zones[i] == NULL || !active_zones[i].IsActive()) continue;
      
      ENUM_ZONE_RANK rank = active_zones[i].GetRank();
      if(rank == RANK_MINOR || rank == RANK_MAJOR || rank == RANK_STANDARD)
        {
         double zHigh = active_zones[i].GetUpperBound();
         double zLow  = active_zones[i].GetLowerBound();
         
         // Secondary Breakout Rule integrated (Open inside zone + ATR overrun)
         bool brokenUp = (open < zLow && close > zHigh) || 
                         (open <= zHigh && open >= zLow && close > (zHigh + (current_atr * 0.5)));
                         
         bool brokenDn = (open > zHigh && close < zLow) || 
                         (open <= zHigh && open >= zLow && close < (zLow - (current_atr * 0.5)));

         if(brokenUp || brokenDn)
           {
            active_zones[i].BreakZone(time);
            
            int bSize = ArraySize(m_broken_zones);
            ArrayResize(m_broken_zones, bSize + 1);
            m_broken_zones[bSize] = active_zones[i];
           }
        }
     }
  }

void C_RoleReversalMonitor::MonitorBrokenZones(double high, double low, double close, double open)
  {
   int size = ArraySize(m_broken_zones);
   for(int i = size - 1; i >= 0; i--)
     {
      double zHigh = m_broken_zones[i].GetUpperBound();
      double zLow  = m_broken_zones[i].GetLowerBound();
      
      bool retested = (low <= zHigh) && (high >= zLow);
      
      if(retested)
        {
         // Bullish rejection: Broken resistance retested as support, rejects upward
         bool bullish_reject = (close > open && close > zHigh);
         // Bearish rejection: Broken support retested as resistance, rejects downward
         bool bearish_reject = (close < open && close < zLow);
         
         if(bullish_reject || bearish_reject)
           {
            m_broken_zones[i].ValidateRetest();
            RemoveZoneFromWatchlist(i);
           }
        }
     }
  }

void C_RoleReversalMonitor::PurgeExpiredZones(datetime current_time, int timeframe_seconds)
  {
   int max_lifetime = ROLE_REVERSAL_MAX_BARS * timeframe_seconds;
   int size = ArraySize(m_broken_zones);
   
   for(int i = size - 1; i >= 0; i--)
     {
      if(m_broken_zones[i].GetBreakTime() > 0 && 
         (current_time - m_broken_zones[i].GetBreakTime() > max_lifetime))
        {
         RemoveZoneFromWatchlist(i);
        }
     }
  }
#endif
