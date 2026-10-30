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
//| V3: Institutional Split Trade Executor (hardened)                |
//+------------------------------------------------------------------+
#include "CDecisionTree.mqh"

enum ENUM_ASSET_CLASS { ASSET_FOREX, ASSET_VOLATILITY, ASSET_BOOMCRASH, ASSET_OTHER_SYNTH };

class C_TradeExecutor
{
private:
    CTrade            m_trade;
    string            m_symbol;
    double            m_riskPercent;      // effective risk after profile cap
    double            m_maxMarginPct;     // max % of free margin one setup may consume
    double            m_maxLots;          // hard lot ceiling per setup (total)
    ulong             m_magicNumber;
    ENUM_ASSET_CLASS  m_assetClass;

    ENUM_ASSET_CLASS  DetectAssetClass();
    void              ApplyRiskProfile(double requested_risk);
    bool              SetSafeFillingMode();
    double            GetLossPerLot(ENUM_ORDER_TYPE type, double entry, double sl);
    double            GetMarginPerLot(ENUM_ORDER_TYPE type, double entry);
    double            NormalizeVolume(double vol);
    double            CalculateLotSize(ENUM_ORDER_TYPE type, double entry, double sl);
    bool              HasMargin(ENUM_ORDER_TYPE type, double vol, double price);
    bool              SendOrder(ENUM_ORDER_TYPE type, double vol, double price,
                                double sl, double tp, const string comment);

public:
                      C_TradeExecutor();
                     ~C_TradeExecutor() {}

    bool              Init(string symbol, double risk_percent, ulong magic_number);
    bool              ExecuteSplitTrade(const STradeSetup &setup);
};

C_TradeExecutor::C_TradeExecutor()
   : m_symbol(""), m_riskPercent(0.5), m_maxMarginPct(0.20),
     m_maxLots(0.0), m_magicNumber(777777), m_assetClass(ASSET_FOREX) {}

ENUM_ASSET_CLASS C_TradeExecutor::DetectAssetClass()
{
    if(StringFind(m_symbol, "Volatility") >= 0 || StringFind(m_symbol, "VIX") >= 0) return ASSET_VOLATILITY;
    if(StringFind(m_symbol, "Boom")  >= 0 || StringFind(m_symbol, "Crash") >= 0)    return ASSET_BOOMCRASH;
    if(StringFind(m_symbol, "Step")  >= 0 || StringFind(m_symbol, "Jump")  >= 0 ||
       StringFind(m_symbol, "Range") >= 0)                                          return ASSET_OTHER_SYNTH;
    return ASSET_FOREX;
}

// DEFAULTS - tune per instrument after forward testing.
void C_TradeExecutor::ApplyRiskProfile(double requested_risk)
{
    double cap;
    switch(m_assetClass)
    {
        case ASSET_BOOMCRASH:  cap = 0.50; m_maxMarginPct = 0.15; m_maxLots = 1.0;  break; // spike/gap-through risk
        case ASSET_VOLATILITY: cap = 0.50; m_maxMarginPct = 0.15; m_maxLots = 1.0;  break; // extreme volatility
        case ASSET_OTHER_SYNTH:cap = 0.75; m_maxMarginPct = 0.20; m_maxLots = 2.0;  break;
        default:               cap = 1.00; m_maxMarginPct = 0.20; m_maxLots = 0.0;  break; // 0 = broker max only
    }
    m_riskPercent = MathMin(MathMax(requested_risk, 0.0), MathMin(cap, 1.0)); // 1.0% absolute ceiling
}

bool C_TradeExecutor::Init(string symbol, double risk_percent, ulong magic_number)
{
    if(symbol == "" || risk_percent <= 0.0) return false;

    m_symbol      = symbol;
    m_magicNumber = magic_number;
    m_assetClass  = DetectAssetClass();
    ApplyRiskProfile(risk_percent);

    m_trade.SetExpertMagicNumber(m_magicNumber);
    m_trade.SetDeviationInPoints(10);

    if(!SetSafeFillingMode())
    {
        PrintFormat("[V3 Executor] FATAL: no valid filling mode for %s", m_symbol);
        return false;
    }

    PrintFormat("[V3 Executor] Init %s | Class=%d | Risk req=%.2f%% eff=%.2f%% | MaxMargin=%.0f%% | MaxLots=%.2f | Magic=%I64u",
                m_symbol, (int)m_assetClass, risk_percent, m_riskPercent,
                m_maxMarginPct * 100.0, m_maxLots, m_magicNumber);
    return true;
}

bool C_TradeExecutor::SetSafeFillingMode()
{
    int filling = (int)SymbolInfoInteger(m_symbol, SYMBOL_FILLING_MODE);
    if((filling & SYMBOL_FILLING_FOK) != 0)      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
    else if((filling & SYMBOL_FILLING_IOC) != 0) m_trade.SetTypeFilling(ORDER_FILLING_IOC);
    else                                         m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
    return true;
}

// Broker-computed loss for 1 lot over entry->SL. Fallback: tick math. Unknown = 0 (fail closed).
double C_TradeExecutor::GetLossPerLot(ENUM_ORDER_TYPE type, double entry, double sl)
{
    double profit = 0.0;
    if(OrderCalcProfit(type, m_symbol, 1.0, entry, sl, profit) && profit != 0.0)
        return MathAbs(profit);

    double tv = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE_LOSS);
    if(tv <= 0.0) tv = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
    double ts = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
    if(tv <= 0.0 || ts <= 0.0) return 0.0;

    return (MathAbs(entry - sl) / ts) * tv;
}

// Broker-computed margin for 1 lot. No guessing: unknown = 0 = no trade.
double C_TradeExecutor::GetMarginPerLot(ENUM_ORDER_TYPE type, double entry)
{
    double margin = 0.0;
    if(OrderCalcMargin(type, m_symbol, 1.0, entry, margin) && margin > 0.0)
        return margin;

    double initial = SymbolInfoDouble(m_symbol, SYMBOL_MARGIN_INITIAL);
    if(initial > 0.0) return initial;

    return 0.0;
}

double C_TradeExecutor::NormalizeVolume(double vol)
{
    double step = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
    double minL = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
    double maxL = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
    if(step <= 0.0 || minL <= 0.0 || vol <= 0.0) return 0.0;

    vol = MathFloor(vol / step + 1e-9) * step;
    int d = (int)MathMax(0.0, MathRound(-MathLog10(step)));
    vol = NormalizeDouble(vol, d);

    if(vol < minL) return 0.0;      // never round UP into more risk
    if(vol > maxL) vol = maxL;
    return vol;
}

double C_TradeExecutor::CalculateLotSize(ENUM_ORDER_TYPE type, double entry, double sl)
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double free_m  = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    if(balance <= 0.0 || free_m <= 0.0 || entry <= 0.0 || sl <= 0.0) return 0.0;

    double risk_money   = balance * (m_riskPercent / 100.0);
    double loss_per_lot = GetLossPerLot(type, entry, sl);
    double margin_lot   = GetMarginPerLot(type, entry);

    // --- FORENSIC LOG: read this first in the tester journal ---
    PrintFormat("[V3 AUDIT] %s | entry=%.5f sl=%.5f dist=%.5f | tickVal=%.8f tickSize=%.8f contract=%.2f",
                m_symbol, entry, sl, MathAbs(entry - sl),
                SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE),
                SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE),
                SymbolInfoDouble(m_symbol, SYMBOL_TRADE_CONTRACT_SIZE));
    PrintFormat("[V3 AUDIT] risk$=%.2f lossPerLot=%.4f marginPerLot=%.4f freeMargin=%.2f lev=%d",
                risk_money, loss_per_lot, margin_lot, free_m, (int)AccountInfoInteger(ACCOUNT_LEVERAGE));

    if(loss_per_lot <= 0.0) { Print("[V3 Executor] ABORT: loss per lot unknown."); return 0.0; }
    if(margin_lot   <= 0.0) { Print("[V3 Executor] ABORT: margin per lot unknown."); return 0.0; }

    double lots = risk_money / loss_per_lot;

    // Margin clamp (applies to TOTAL volume, both tickets)
    double max_by_margin = (free_m * m_maxMarginPct) / margin_lot;
    if(lots > max_by_margin)
    {
        PrintFormat("[V3 Executor] Margin clamp: %.2f -> %.2f lots", lots, max_by_margin);
        lots = max_by_margin;
    }

    // Asset-class lot ceiling
    if(m_maxLots > 0.0 && lots > m_maxLots)
    {
        PrintFormat("[V3 Executor] Lot ceiling (%d): %.2f -> %.2f", (int)m_assetClass, lots, m_maxLots);
        lots = m_maxLots;
    }

    lots = NormalizeVolume(lots);
    if(lots <= 0.0)
        Print("[V3 Executor] ABORT: risk-sized lot below broker minimum. Trade skipped, not inflated.");
    return lots;
}

bool C_TradeExecutor::HasMargin(ENUM_ORDER_TYPE type, double vol, double price)
{
    double per_lot = GetMarginPerLot(type, price);
    if(per_lot <= 0.0) return false;
    double need = per_lot * vol;
    double free_m = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    if(need > free_m * 0.95)
    {
        PrintFormat("[V3 Executor] Pre-check FAIL: need %.2f, free %.2f", need, free_m);
        return false;
    }
    return true;
}

bool C_TradeExecutor::SendOrder(ENUM_ORDER_TYPE type, double vol, double price,
                                double sl, double tp, const string comment)
{
    if(!HasMargin(type, vol, price)) return false;

    bool ok = (type == ORDER_TYPE_BUY)
              ? m_trade.Buy(vol, m_symbol, price, sl, tp, comment)
              : m_trade.Sell(vol, m_symbol, price, sl, tp, comment);

    if(!ok)
        PrintFormat("[V3 Executor] %s FAILED. Retcode=%u (%s)", comment,
                    m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
    else
        PrintFormat("[V3 Executor] %s OPEN. Vol=%.2f SL=%.5f TP=%.5f", comment, vol, sl, tp);
    return ok;
}

bool C_TradeExecutor::ExecuteSplitTrade(const STradeSetup &setup)
{
    if(setup.direction == SIGNAL_NONE) return false;

    const bool is_long = (setup.direction == SIGNAL_LONG);
    const ENUM_ORDER_TYPE type = is_long ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

    // 1. LIVE price - size and stops are computed on what we will actually fill at
    double price = SymbolInfoDouble(m_symbol, is_long ? SYMBOL_ASK : SYMBOL_BID);
    if(price <= 0.0) return false;

    int    digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
    double point  = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
    if(point <= 0.0) return false;

    STradeSetup s = setup;
    s.stopLoss = NormalizeDouble(setup.stopLoss, digits);
    s.tpLocal  = NormalizeDouble(setup.tpLocal,  digits);
    s.tpMacro  = NormalizeDouble(setup.tpMacro,  digits);

    // 2. Directional sanity
    if(is_long  && (s.stopLoss >= price)) { Print("[V3 Executor] ABORT: Long SL >= price."); return false; }
    if(!is_long && (s.stopLoss <= price)) { Print("[V3 Executor] ABORT: Short SL <= price."); return false; }

    // 3. Stop-level compliance BEFORE sizing (widening SL after sizing breaks the 1% cap)
    double stop_level = (double)SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
    if(stop_level > 0.0 && MathAbs(price - s.stopLoss) < stop_level)
        s.stopLoss = NormalizeDouble(is_long ? price - stop_level : price + stop_level, digits);

    // 4. Size on the FINAL stop
    double total_lot = CalculateLotSize(type, price, s.stopLoss);
    if(total_lot <= 0.0) return false;

    // 5. Split
    double min_lot  = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
    double half_lot = NormalizeVolume(total_lot / 2.0);
    bool   isSplit  = (half_lot >= min_lot && half_lot > 0.0);

    if(!isSplit)
    {
        half_lot = total_lot;   // single ticket carries the full computed size
        Print("[V3 Executor] Half-lot below minimum. Single ticket, full size.");
    }

    // 6. Ticket 1 gates Ticket 2
    if(!SendOrder(type, half_lot, price, s.stopLoss, s.tpLocal, s.modelName + " (Day Trade)"))
        return false;

    if(isSplit)
    {
        price = SymbolInfoDouble(m_symbol, is_long ? SYMBOL_ASK : SYMBOL_BID); // refresh
        if(!SendOrder(type, half_lot, price, s.stopLoss, s.tpMacro, s.modelName + " (Runner)"))
            return false;   // Ticket 1 stays open at half risk
    }
    return true;
}
#endif
