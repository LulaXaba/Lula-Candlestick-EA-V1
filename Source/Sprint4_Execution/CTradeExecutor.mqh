//+------------------------------------------------------------------+
//|                                             CTradeExecutor.mqh   |
//|                             Lula Price Action Execution Engine V1|
//+------------------------------------------------------------------+
#ifndef CTRADEEXECUTOR_MQH
#define CTRADEEXECUTOR_MQH

#include <Trade\Trade.mqh>
#include "..\Include\Defines.mqh"
#include "..\Include\DTOs.mqh"

class CTradeExecutor
  {
private:
   CTrade            m_trade;
   string            m_symbol;
   ulong             m_magic_number;

public:
                     CTradeExecutor();
                    ~CTradeExecutor();

   bool              Init(const string symbol, ulong magic_number, ulong deviation = 10);
   
   //--- Order Routing
   bool              ExecuteTrade(const SPatternResult &pattern, double lot_size);
  };

CTradeExecutor::CTradeExecutor() : m_symbol(""), m_magic_number(0) {}
CTradeExecutor::~CTradeExecutor() {}

bool CTradeExecutor::Init(const string symbol, ulong magic_number, ulong deviation)
  {
   m_symbol = symbol;
   m_magic_number = magic_number;
   
   m_trade.SetExpertMagicNumber(m_magic_number);
   m_trade.SetDeviationInPoints(deviation);
   m_trade.SetTypeFilling(ORDER_FILLING_FOK); // Fill or Kill (Standard for most brokers)
   
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
                  lot_size, current_ask, pattern.stopLoss, pattern.takeProfit);
                  
      success = m_trade.Buy(lot_size, m_symbol, current_ask, pattern.stopLoss, pattern.takeProfit, "Lula V1 Long");
     }
   //--- EXECUTE SHORT POSITION
   else if(pattern.direction == DIRECTION_SHORT)
     {
      PrintFormat("[Trade Executor] Routing SELL Order: Lots=%.2f, Entry=%.5f, SL=%.5f, TP=%.5f", 
                  lot_size, current_bid, pattern.stopLoss, pattern.takeProfit);
                  
      success = m_trade.Sell(lot_size, m_symbol, current_bid, pattern.stopLoss, pattern.takeProfit, "Lula V1 Short");
     }

   //--- ERROR HANDLING
   if(success)
     {
      PrintFormat("[Trade Executor] TRADE SUCCESSFUL. Ticket: %d", m_trade.ResultDeal());
     }
   else
     {
      PrintFormat("[Trade Executor] TRADE FAILED. Error Code: %d, Description: %s", 
                  m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
     }

   return success;
  }

#endif
