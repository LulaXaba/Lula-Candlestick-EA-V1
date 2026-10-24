//+------------------------------------------------------------------+
//|                                             CTradeExecutor.mqh   |
//|                             Lula Price Action Execution Engine V1|
//+------------------------------------------------------------------+
#ifndef CTRADEEXECUTOR_MQH
#define CTRADEEXECUTOR_MQH

#include <Trade\Trade.mqh>
#include <Generic\HashMap.mqh>
#include "..\Include\Defines.mqh"
#include "..\Include\DTOs.mqh"

class CTradeExecutor
  {
private:
   CTrade            m_trade;
   string            m_symbol;
   ulong             m_magic_number;
   
   CHashMap<ulong, double>               m_structuralLevels;
   CHashMap<ulong, ENUM_TRADE_DIRECTION> m_structuralDirections;
   
   CHashMap<ulong, double>               m_entryH1Highs;
   CHashMap<ulong, double>               m_entryH1Lows;

public:
                     CTradeExecutor();
                    ~CTradeExecutor();

   bool              Init(const string symbol, ulong magic_number, ulong deviation = 10);
   
   //--- Order Routing
   bool              ExecuteTrade(const SPatternResult &pattern, double lot_size);
   bool              ClosePartial(ulong ticket, double percentToClose);
   bool              ClosePosition(ulong ticket, string comment = "");
   bool              MoveSLToBreakeven(ulong ticket);
   
   //--- Trade State Tracking
   void              StoreStructuralLevel(ulong ticket, double level, ENUM_TRADE_DIRECTION dir);
   bool              GetStructuralLevel(ulong ticket, double &level, ENUM_TRADE_DIRECTION &dir);
   void              StoreH1EntryExtremes(ulong ticket, double h1High, double h1Low);
   bool              GetH1EntryExtremes(ulong ticket, double &h1High, double &h1Low);
  };

CTradeExecutor::CTradeExecutor() : m_symbol(""), m_magic_number(0) {}
CTradeExecutor::~CTradeExecutor() {}

bool CTradeExecutor::Init(const string symbol, ulong magic_number, ulong deviation)
  {
   m_symbol = symbol;
   m_magic_number = magic_number;
   
   m_trade.SetExpertMagicNumber(m_magic_number);
   m_trade.SetDeviationInPoints(deviation);
   uint filling = (uint)SymbolInfoInteger(m_symbol, SYMBOL_FILLING_MODE);
   if((filling & SYMBOL_FILLING_FOK) != 0)
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if((filling & SYMBOL_FILLING_IOC) != 0)
      m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
   
   return true;
  }

bool CTradeExecutor::ExecuteTrade(const SPatternResult &pattern, double lot_size)
  {
   if(lot_size <= 0.0)
     {
      Print("[Trade Executor] Aborting execution: Invalid Lot Size.");
      return false;
     }

   if(!pattern.IsValid() || pattern.direction == DIRECTION_NONE)
     {
      Print("[Trade Executor] Aborting execution: Invalid Pattern Result.");
      return false;
     }

   double current_ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
   double current_bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   
   bool success = false;

   //--- EXECUTE LONG POSITION
   if(pattern.direction == DIRECTION_LONG)
     {
      PrintFormat("[Trade Executor] Routing BUY Order: Lots=%.2f, Entry=%.5f, SL=%.5f, TP=%.5f", 
                  lot_size, current_ask, pattern.stopLoss, pattern.takeProfit1);
                  
      success = m_trade.Buy(lot_size, m_symbol, current_ask, pattern.stopLoss, pattern.takeProfit1, "Lula V1 Long");
     }
   //--- EXECUTE SHORT POSITION
   else if(pattern.direction == DIRECTION_SHORT)
     {
      PrintFormat("[Trade Executor] Routing SELL Order: Lots=%.2f, Entry=%.5f, SL=%.5f, TP=%.5f", 
                  lot_size, current_bid, pattern.stopLoss, pattern.takeProfit1);
                  
      success = m_trade.Sell(lot_size, m_symbol, current_bid, pattern.stopLoss, pattern.takeProfit1, "Lula V1 Short");
     }

   //--- ERROR HANDLING
   if(success)
     {
      ulong ticket = m_trade.ResultOrder();
      if (ticket == 0) ticket = m_trade.ResultDeal();
      PrintFormat("[Trade Executor] TRADE SUCCESSFUL. Ticket: %d", ticket);
      StoreStructuralLevel(ticket, pattern.structuralLevel, pattern.direction);
      
      double h1High = iHigh(m_symbol, PERIOD_H1, 1);
      double h1Low  = iLow(m_symbol, PERIOD_H1, 1);
      StoreH1EntryExtremes(ticket, h1High, h1Low);
     }
   else
     {
      PrintFormat("[Trade Executor] TRADE FAILED. Error Code: %d, Description: %s", 
                  m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
     }

   return success;
  }

//+------------------------------------------------------------------+
//| V2: Partial Close with Safety Bounds                             |
//+------------------------------------------------------------------+
bool CTradeExecutor::ClosePartial(ulong ticket, double percentToClose)
{
   if(percentToClose <= 0 || percentToClose >= 100.0) return false;
   
   if(!PositionSelectByTicket(ticket)) return false;
   
   double currentVolume = PositionGetDouble(POSITION_VOLUME);
   double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
   double stepLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
   
   double targetVolume = currentVolume * (percentToClose / 100.0);
   double normalizedVolume = MathFloor(targetVolume / stepLot) * stepLot;
   
   // If the amount we want to close is less than min lot, skip it (User Rule)
   if(normalizedVolume < minLot)
   {
      PrintFormat("[Trade Executor] Partial close volume %.2f is less than MinLot %.2f. Skipping.", normalizedVolume, minLot);
      return false;
   }
   
   // If remaining volume would be < minLot, we can't do it either
   double remainingVolume = currentVolume - normalizedVolume;
   if(remainingVolume > 0 && remainingVolume < minLot)
   {
      PrintFormat("[Trade Executor] Partial close leaves %.2f < MinLot. Skipping.", remainingVolume);
      return false; 
   }
   
   bool success = m_trade.PositionClosePartial(ticket, normalizedVolume);
   if(success)
      PrintFormat("[Trade Executor] Partially closed %.2f lots on ticket %d", normalizedVolume, ticket);
   else
      PrintFormat("[Trade Executor] Partial close failed for ticket %d. Error: %d", ticket, m_trade.ResultRetcode());
      
   return success;
}

//+------------------------------------------------------------------+
//| V2: Close Full Position helper                                   |
//+------------------------------------------------------------------+
bool CTradeExecutor::ClosePosition(ulong ticket, string comment)
{
   if(!PositionSelectByTicket(ticket)) return false;
   bool success = m_trade.PositionClose(ticket, -1);
   if(success)
      PrintFormat("[Trade Executor] Position closed: %s (Ticket: %d)", comment, ticket);
   else
      PrintFormat("[Trade Executor] Close failed for ticket %d. Error: %d", ticket, m_trade.ResultRetcode());
   return success;
}

//+------------------------------------------------------------------+
//| V2: Move SL to Breakeven                                         |
//+------------------------------------------------------------------+
bool CTradeExecutor::MoveSLToBreakeven(ulong ticket)
{
   if(!PositionSelectByTicket(ticket)) return false;
   
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentSL = PositionGetDouble(POSITION_SL);
   double currentTP = PositionGetDouble(POSITION_TP);
   
   // Check if already at or past breakeven
   long type = PositionGetInteger(POSITION_TYPE);
   if(type == POSITION_TYPE_BUY && currentSL >= openPrice) return true;
   if(type == POSITION_TYPE_SELL && currentSL > 0 && currentSL <= openPrice) return true;
   
   bool success = m_trade.PositionModify(ticket, openPrice, currentTP);
   if(success)
      PrintFormat("[Trade Executor] SL moved to Breakeven for ticket %d", ticket);
   else
      PrintFormat("[Trade Executor] Failed to move SL to BE for ticket %d. Error: %d", ticket, m_trade.ResultRetcode());
      
   return success;
}

//+------------------------------------------------------------------+
//| V2: Trade State Tracking                                         |
//+------------------------------------------------------------------+
void CTradeExecutor::StoreStructuralLevel(ulong ticket, double level, ENUM_TRADE_DIRECTION dir)
{
   m_structuralLevels.Add(ticket, level);
   m_structuralDirections.Add(ticket, dir);
}

bool CTradeExecutor::GetStructuralLevel(ulong ticket, double &level, ENUM_TRADE_DIRECTION &dir)
{
   return m_structuralLevels.TryGetValue(ticket, level) && m_structuralDirections.TryGetValue(ticket, dir);
}

void CTradeExecutor::StoreH1EntryExtremes(ulong ticket, double h1High, double h1Low)
{
   m_entryH1Highs.Add(ticket, h1High);
   m_entryH1Lows.Add(ticket, h1Low);
}

bool CTradeExecutor::GetH1EntryExtremes(ulong ticket, double &h1High, double &h1Low)
{
   return m_entryH1Highs.TryGetValue(ticket, h1High) && m_entryH1Lows.TryGetValue(ticket, h1Low);
}

#endif
