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

//+------------------------------------------------------------------+
//| V3: Institutional Split Trade Executor                           |
//+------------------------------------------------------------------+
#include "CDecisionTree.mqh"

class C_TradeExecutor
{
private:
    CTrade              m_trade;
    string              m_symbol;
    double              m_riskPercent;
    ulong               m_magicNumber;

    bool                SetSafeFillingMode();
    double              CalculateLotSize(double entry_price, double stop_loss);

public:
                        C_TradeExecutor();
                       ~C_TradeExecutor();

    bool                Init(string symbol, double risk_percent, ulong magic_number);
    bool                ExecuteSplitTrade(const STradeSetup &setup);
};

C_TradeExecutor::C_TradeExecutor() : m_symbol(""), m_riskPercent(1.0), m_magicNumber(777777) {}
C_TradeExecutor::~C_TradeExecutor() {}

bool C_TradeExecutor::Init(string symbol, double risk_percent, ulong magic_number)
{
    m_symbol = symbol;
    m_riskPercent = risk_percent;
    m_magicNumber = magic_number;
    
    m_trade.SetExpertMagicNumber(m_magicNumber);
    m_trade.SetDeviationInPoints(10); // Standard 10-point slippage tolerance
    
    if(!SetSafeFillingMode())
    {
        PrintFormat("[V3 Executor] FATAL: Could not set a valid filling mode for %s", m_symbol);
        return false;
    }
    
    PrintFormat("[V3 Executor] Initialized. Risk: %.2f%% | Magic: %d", m_riskPercent, m_magicNumber);
    return true;
}

// Solves the Retcode 10030 (Unsupported Filling Mode) bug common on Deriv/Synthetics
bool C_TradeExecutor::SetSafeFillingMode()
{
    int filling = (int)SymbolInfoInteger(m_symbol, SYMBOL_FILLING_MODE);
    
    if((filling & SYMBOL_FILLING_FOK) != 0) 
    {
        m_trade.SetTypeFilling(ORDER_FILLING_FOK);
        Print("[V3 Executor] Filling Mode set to FOK (Fill or Kill)");
        return true;
    }
    else if((filling & SYMBOL_FILLING_IOC) != 0) 
    {
        m_trade.SetTypeFilling(ORDER_FILLING_IOC);
        Print("[V3 Executor] Filling Mode set to IOC (Immediate or Cancel)");
        return true;
    }
    else
    {
        m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
        Print("[V3 Executor] Filling Mode set to RETURN");
        return true;
    }
}

double C_TradeExecutor::CalculateLotSize(double entry_price, double stop_loss)
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_money = balance * (m_riskPercent / 100.0);
    
    double tick_size  = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
    double tick_value = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
    
    if(tick_size == 0 || tick_value == 0) return 0.0;
    
    // Risk in ticks
    double sl_ticks = MathAbs(entry_price - stop_loss) / tick_size;
    if(sl_ticks <= 0) return 0.0;
    
    // Total risk value for 1.0 lot
    double risk_per_lot = sl_ticks * tick_value;
    double lot_size = risk_money / risk_per_lot;
    
    // --- MARGIN SAFETY LIMITER ---
    // Calculate the margin required for 1.0 lot
    double margin_required = 0;
    if(!OrderCalcMargin(ORDER_TYPE_BUY, m_symbol, 1.0, entry_price, margin_required) || margin_required == 0) {
        // Fallback estimate if OrderCalcMargin fails (e.g., in some Synthetics environments)
        margin_required = (entry_price * 1.0) / AccountInfoInteger(ACCOUNT_LEVERAGE);
    }
    
    // Check how much margin this lot size will eat up
    double total_margin = lot_size * margin_required;
    double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    
    // If the required margin exceeds 80% of our available free margin, shrink the lot size
    double max_allowed_margin = free_margin * 0.80;
    if(total_margin > max_allowed_margin && margin_required > 0) {
        lot_size = max_allowed_margin / margin_required;
        PrintFormat("[V3 Executor] Margin Warning: Reducing Lot Size to %.2f to fit account constraints.", lot_size);
    }
    // -----------------------------
    
    // Clamp to broker limits
    double min_lot  = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
    double max_lot  = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
    double step_lot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
    
    lot_size = MathFloor(lot_size / step_lot) * step_lot;
    if(lot_size < min_lot) lot_size = min_lot;
    if(lot_size > max_lot) lot_size = max_lot;
    
    return lot_size;
}

bool C_TradeExecutor::ExecuteSplitTrade(const STradeSetup &setup)
{
    if(setup.direction == SIGNAL_NONE) return false;

    double total_lot = CalculateLotSize(setup.entryPrice, setup.stopLoss);
    if(total_lot <= 0.0) return false;

    double min_lot  = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
    double step_lot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
    
    // Split the lot size in half and normalize to the broker's step volume
    double half_lot = MathFloor((total_lot / 2.0) / step_lot) * step_lot;
    
    // If the split lot is smaller than the minimum, just execute a single normal trade
    bool isSplit = true;
    if(half_lot < min_lot)
    {
        half_lot = min_lot;
        isSplit = false;
        Print("[V3 Executor] Calculated half-lot is below minimum volume. Executing single ticket only.");
    }

    bool success = true;

    // -------------------------------------------------------------
    // Normalize to broker digits to prevent 10016 Invalid Stops
    // -------------------------------------------------------------
    int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
    
    // We must pass a mutable copy to the executor
    STradeSetup safe_setup = setup;
    safe_setup.stopLoss = NormalizeDouble(setup.stopLoss, digits);
    safe_setup.tpLocal  = NormalizeDouble(setup.tpLocal, digits);
    safe_setup.tpMacro  = NormalizeDouble(setup.tpMacro, digits);
    
    // Ensure minimum stop level compliance
    double stop_level = SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL) * SymbolInfoDouble(m_symbol, SYMBOL_POINT);
    if(stop_level > 0) {
        if(safe_setup.direction == SIGNAL_LONG && (safe_setup.entryPrice - safe_setup.stopLoss) < stop_level) 
            safe_setup.stopLoss = NormalizeDouble(safe_setup.entryPrice - stop_level, digits);
        if(safe_setup.direction == SIGNAL_SHORT && (safe_setup.stopLoss - safe_setup.entryPrice) < stop_level) 
            safe_setup.stopLoss = NormalizeDouble(safe_setup.entryPrice + stop_level, digits);
    }
    // -------------------------------------------------------------

    if(safe_setup.direction == SIGNAL_LONG)
    {
        // Ticket 1: The Day Trade 
        if(m_trade.Buy(half_lot, m_symbol, SymbolInfoDouble(m_symbol, SYMBOL_ASK), safe_setup.stopLoss, safe_setup.tpLocal, safe_setup.modelName + " (Day Trade)"))
            PrintFormat("[V3 Executor] Ticket 1 (Long) Opened. Lot: %.2f | TP Local: %.5f", half_lot, safe_setup.tpLocal);
        else { PrintFormat("[V3 Executor] Error opening Ticket 1: %d", m_trade.ResultRetcode()); success = false; }
        
        // Ticket 2: The Profit Maximizer 
        if(isSplit)
        {
            if(m_trade.Buy(half_lot, m_symbol, SymbolInfoDouble(m_symbol, SYMBOL_ASK), safe_setup.stopLoss, safe_setup.tpMacro, safe_setup.modelName + " (Runner)"))
                PrintFormat("[V3 Executor] Ticket 2 (Long) Opened. Lot: %.2f | TP Macro: %.5f", half_lot, safe_setup.tpMacro);
            else { PrintFormat("[V3 Executor] Error opening Ticket 2: %d", m_trade.ResultRetcode()); success = false; }
        }
    }
    else if(safe_setup.direction == SIGNAL_SHORT)
    {
        // Ticket 1: The Day Trade 
        if(m_trade.Sell(half_lot, m_symbol, SymbolInfoDouble(m_symbol, SYMBOL_BID), safe_setup.stopLoss, safe_setup.tpLocal, safe_setup.modelName + " (Day Trade)"))
            PrintFormat("[V3 Executor] Ticket 1 (Short) Opened. Lot: %.2f | TP Local: %.5f", half_lot, safe_setup.tpLocal);
        else { PrintFormat("[V3 Executor] Error opening Ticket 1: %d", m_trade.ResultRetcode()); success = false; }
        
        // Ticket 2: The Profit Maximizer 
        if(isSplit)
        {
            if(m_trade.Sell(half_lot, m_symbol, SymbolInfoDouble(m_symbol, SYMBOL_BID), safe_setup.stopLoss, safe_setup.tpMacro, safe_setup.modelName + " (Runner)"))
                PrintFormat("[V3 Executor] Ticket 2 (Short) Opened. Lot: %.2f | TP Macro: %.5f", half_lot, safe_setup.tpMacro);
            else { PrintFormat("[V3 Executor] Error opening Ticket 2: %d", m_trade.ResultRetcode()); success = false; }
        }
    }

    return success;
}
#endif
