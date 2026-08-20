//+------------------------------------------------------------------+
//| CActiveTradeManager.mqh                                          |
//| V2: Implements the 3-Tier Post-Entry Monitor (H1/M15/H4)         |
//+------------------------------------------------------------------+
#ifndef CACTIVETRADEMANAGER_MQH
#define CACTIVETRADEMANAGER_MQH

#include "..\Include\DTOs.mqh"
#include <Trade\Trade.mqh>
#include "CTradeExecutor.mqh"
#include "..\Sprint2_Patterns\CPatternEngine.mqh"

extern CTradeExecutor* g_executor;
extern CPatternEngine* g_patternEngine;

class CActiveTradeManager
{
private:
   string   m_symbol;
   CTrade   m_trade;
   datetime m_lastH1Time;

public:
   CActiveTradeManager(string symbol) : m_symbol(symbol), m_lastH1Time(0) {}
   ~CActiveTradeManager() {}
   
   // Main entry point called on every tick, but gated to H1 closed bars
   void MonitorTrades(const SSensorData &context)
   {
      datetime currentH1 = iTime(m_symbol, PERIOD_H1, 0);
      if(currentH1 == m_lastH1Time) return;  // Not a new H1 bar
      m_lastH1Time = currentH1;
      
      // Use closed bar data
      double h1Close = iClose(m_symbol, PERIOD_H1, 1);
      
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(PositionGetString(POSITION_SYMBOL) == m_symbol)
         {
            CheckHealthH1(ticket, h1Close);
            CheckTimeDecay(ticket, context); // Dynamic Time Decay needs context (ATR)
            CheckMacroH4(ticket); // Lens 4
         }
      }
   }

private:
   void CheckHealthH1(ulong ticket, double h1Close)
   {
      if(Lens1_StructureBreak(ticket, h1Close)) return;
      if(Lens3_CharacterChange(ticket)) return;
      
      if(Lens2_MomentumDead(ticket)) 
      {
         PrintFormat("[Active Monitor] Momentum Dead for Ticket %d. Attempting 50%% close.", ticket);
         bool closed = g_executor.ClosePartial(ticket, 50.0);
         if(!closed)
         {
            // Couldn't split — move SL to BE instead
            PrintFormat("[Active Monitor] Partial close failed/skipped for Ticket %d. Moving SL to BE.", ticket);
            g_executor.MoveSLToBreakeven(ticket);
         }
      }
   }
   
   // === LENS 1: Structure Integrity ===
   bool Lens1_StructureBreak(ulong ticket, double h1Close)
   {
      double sl;
      ENUM_TRADE_DIRECTION dir;
      if(!g_executor.GetStructuralLevel(ticket, sl, dir)) return false;
      
      if(dir == DIRECTION_LONG && h1Close < sl)
      {
         PrintFormat("[V2 EXIT] H1 closed below HL %.5f. Structure dead.", sl);
         g_executor.ClosePosition(ticket, "Structure break: HL violated");
         return true;
      }
      if(dir == DIRECTION_SHORT && h1Close > sl)
      {
         PrintFormat("[V2 EXIT] H1 closed above LH %.5f. Structure dead.", sl);
         g_executor.ClosePosition(ticket, "Structure break: LH violated");
         return true;
      }
      return false;
   }
   
   // === LENS 2: Momentum Progress (last 3 H1 candles) ===
   bool Lens2_MomentumDead(ulong ticket)
   {
      double c1 = iClose(m_symbol, PERIOD_H1, 1);
      double c2 = iClose(m_symbol, PERIOD_H1, 2);
      double c3 = iClose(m_symbol, PERIOD_H1, 3);
      
      double sl;
      ENUM_TRADE_DIRECTION dir;
      if(!g_executor.GetStructuralLevel(ticket, sl, dir)) return false;
      
      int against = 0;
      if(dir == DIRECTION_LONG)
      {
         if(c1 < c2) against++;
         if(c2 < c3) against++;
         if(c1 < c3) against++;
      }
      else
      {
         if(c1 > c2) against++;
         if(c2 > c3) against++;
         if(c1 > c3) against++;
      }
      
      return (against >= 3);
   }
   
   // === LENS 3: Character Change (CHoCH) ===
   bool Lens3_CharacterChange(ulong ticket)
   {
      double sl;
      ENUM_TRADE_DIRECTION dir;
      if(!g_executor.GetStructuralLevel(ticket, sl, dir)) return false;
      
      double entryH1High, entryH1Low;
      if(!g_executor.GetH1EntryExtremes(ticket, entryH1High, entryH1Low)) return false;
      
      if(dir == DIRECTION_LONG && iLow(m_symbol, PERIOD_H1, 1) < entryH1Low)
      {
         PrintFormat("[V2 EXIT] Character Change (CHoCH): Lower Low printed for Ticket %d. Reducing risk.", ticket);
         bool closed = g_executor.ClosePartial(ticket, 50.0);
         if(!closed) g_executor.MoveSLToBreakeven(ticket);
         return true;
      }
      if(dir == DIRECTION_SHORT && iHigh(m_symbol, PERIOD_H1, 1) > entryH1High)
      {
         PrintFormat("[V2 EXIT] Character Change (CHoCH): Higher High printed for Ticket %d. Reducing risk.", ticket);
         bool closed = g_executor.ClosePartial(ticket, 50.0);
         if(!closed) g_executor.MoveSLToBreakeven(ticket);
         return true;
      }
      return false;
   }
   
   // === LENS 4: HTF Alignment (H4 Review) ===
   void CheckMacroH4(ulong ticket)
   {
      // Runs every H1 bar (could be gated to H4 bar close if preferred, but checked here)
      datetime currentH4 = iTime(m_symbol, PERIOD_H4, 0);
      static datetime lastH4Time = 0;
      if(currentH4 == lastH4Time) return;
      lastH4Time = currentH4;
      
      if(!g_patternEngine) return;
      
      double sl;
      ENUM_TRADE_DIRECTION dir;
      if(!g_executor.GetStructuralLevel(ticket, sl, dir)) return;
      
      // Assume g_patternEngine has a ScanForPatternH4 method or similar
      // If it doesn't compile we will need to adjust based on CPatternEngine interface
      // Since user provided: SPatternResult h4Pattern = m_patternEngine.ScanForPatternH4();
      SPatternResult h4Pattern = g_patternEngine.ScanForPatternH4();
      
      if(h4Pattern.direction == DIRECTION_SHORT && dir == DIRECTION_LONG)
      {
         PrintFormat("[V2 EXIT] H4 Institutional Veto (Bearish) for Ticket %d", ticket);
         g_executor.ClosePosition(ticket, "H4 institutional veto");
      }
      else if(h4Pattern.direction == DIRECTION_LONG && dir == DIRECTION_SHORT)
      {
         PrintFormat("[V2 EXIT] H4 Institutional Veto (Bullish) for Ticket %d", ticket);
         g_executor.ClosePosition(ticket, "H4 institutional veto");
      }
   }
   
   void CheckTimeDecay(ulong ticket, const SSensorData &context)
   {
      // P1 Feature: Dynamic Time Decay based on expected move time
      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      datetime currentTime = TimeCurrent();
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentTP = PositionGetDouble(POSITION_TP);
      
      if(currentTP <= 0 || context.atr_H1 <= 0) return;
      
      double distanceToTarget = MathAbs(currentTP - openPrice) / _Point;
      double expectedMoveTimeHours = distanceToTarget / (context.atr_H1 * 0.5 / _Point);
      
      int hoursOpen = (int)((currentTime - openTime) / 3600);
      
      // If open > 2 * ExpectedMoveTime and progress < 50%
      double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
      double progress = MathAbs(currentPrice - openPrice) / MathAbs(currentTP - openPrice);
      
      if(hoursOpen > 2 * expectedMoveTimeHours && progress < 0.5)
      {
         PrintFormat("[V2 EXIT] Time Decay: Trade open for %d hours (Expected: %.1f). Progress %.1f%%. Exiting.", 
                     hoursOpen, expectedMoveTimeHours, progress * 100);
         g_executor.ClosePosition(ticket, "Time Decay");
      }
   }
};

#endif // CACTIVETRADEMANAGER_MQH
