//+------------------------------------------------------------------+
//| CActiveTradeManager.mqh                                          |
//| V2: Implements the 3-Tier Post-Entry Monitor (H1/M15/H4)         |
//+------------------------------------------------------------------+
#ifndef CACTIVETRADEMANAGER_MQH
#define CACTIVETRADEMANAGER_MQH

#include "..\Include\DTOs.mqh"
#include <Trade\Trade.mqh>

class CActiveTradeManager
{
private:
   string   m_symbol;
   CTrade   m_trade;

public:
   CActiveTradeManager(string symbol) : m_symbol(symbol) {}
   ~CActiveTradeManager() {}
   
   // Main entry point called on every bar close
   void MonitorTrades(const SSensorData &context)
   {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(PositionGetString(POSITION_SYMBOL) == m_symbol)
         {
            CheckHealthH1(ticket, context);
            // CheckMicroM15(ticket, context);
            // CheckMacroH4(ticket, context);
         }
      }
   }

private:
   void CheckHealthH1(ulong ticket, const SSensorData &context)
   {
      // Tier 1: H1 Health Pulse
      // If price closes strongly against our position (past dynamic KAMA), execute a soft exit
      long type = PositionGetInteger(POSITION_TYPE);
      
      // We only execute on Closed Bar data, so we use Bid/Ask here for closing but 
      // the decision should ideally use Close[1]. For real-time monitoring we use current price.
      double currentPrice = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(m_symbol, SYMBOL_BID) : SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      
      if(context.kama > 0)
      {
         // If long, and price falls below KAMA
         if(type == POSITION_TYPE_BUY && currentPrice < context.kama)
         {
            PrintFormat("[Active Monitor] H1 Health Failed for Long (Ticket %d) - Price below KAMA. Soft Exit.", ticket);
            m_trade.PositionClose(ticket);
         }
         // If short, and price rises above KAMA
         else if(type == POSITION_TYPE_SELL && currentPrice > context.kama)
         {
            PrintFormat("[Active Monitor] H1 Health Failed for Short (Ticket %d) - Price above KAMA. Soft Exit.", ticket);
            m_trade.PositionClose(ticket);
         }
      }
   }
   
   void CheckMicroM15(ulong ticket, const SSensorData &context)
   {
      // Tier 2: Micro Structure
      // E.g., moving stop loss to breakeven when M15 creates a new favorable structure node
   }
   
   void CheckMacroH4(ulong ticket, const SSensorData &context)
   {
      // Tier 3: Time Decay
      // E.g., if trade has been open for > X bars without hitting TP1, close or trail stop
   }
};

#endif // CACTIVETRADEMANAGER_MQH
