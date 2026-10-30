//+------------------------------------------------------------------+
//|                                             CTradeExecutor.mqh   |
//|                             Lula Price Action Execution Engine V3|
//+------------------------------------------------------------------+
#ifndef CTRADEEXECUTOR_MQH
#define CTRADEEXECUTOR_MQH

// ---------------------------------------------------------------
// NOTE: The legacy V1/V2 CTradeExecutor class has been removed.
// V3 C_TradeExecutor is the sole executor in this file.
// DTOs.mqh is not required by V3 — include removed to avoid bloat.
// ---------------------------------------------------------------

#include <Trade\Trade.mqh>
#include "..\Include\Defines.mqh"
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
    int               m_ticketsOpened;    // [Fix #1] tracks how many tickets sent this execution

    ENUM_ASSET_CLASS  DetectAssetClass();
    void              ApplyRiskProfile(double requested_risk);
    bool              SetSafeFillingMode();
    double            GetLossPerLot(ENUM_ORDER_TYPE type, double entry, double sl);
    double            GetMarginPerLot(ENUM_ORDER_TYPE type, double entry);
    double            NormalizeVolume(double vol);
    double            CalculateLotSize(ENUM_ORDER_TYPE type, double entry, double sl);
    bool              HasMargin(ENUM_ORDER_TYPE type, double vol, double price);
    bool              EnforceStopLevel(ENUM_ORDER_TYPE type, double price, double &sl, double &tp, int digits, double point);
    bool              SendOrder(ENUM_ORDER_TYPE type, double vol, double price,
                                double sl, double tp, const string comment);
    bool              HasOpenPosition();   // [Fix #5]

public:
                      C_TradeExecutor();
                     ~C_TradeExecutor() {}

    bool              Init(string symbol, double risk_percent, ulong magic_number);
    bool              ExecuteSplitTrade(const STradeSetup &setup);
    int               TicketsOpened() const { return m_ticketsOpened; } // [Fix #1]
};

C_TradeExecutor::C_TradeExecutor()
    : m_symbol(""), m_riskPercent(0.5), m_maxMarginPct(0.20),
      m_maxLots(0.0), m_magicNumber(777777), m_assetClass(ASSET_FOREX),
      m_ticketsOpened(0) {}

ENUM_ASSET_CLASS C_TradeExecutor::DetectAssetClass()
{
    if(StringFind(m_symbol, "Volatility") >= 0 || StringFind(m_symbol, "VIX")   >= 0) return ASSET_VOLATILITY;
    if(StringFind(m_symbol, "Boom")       >= 0 || StringFind(m_symbol, "Crash") >= 0) return ASSET_BOOMCRASH;
    if(StringFind(m_symbol, "Step")       >= 0 || StringFind(m_symbol, "Jump")  >= 0 ||
       StringFind(m_symbol, "Range")      >= 0)                                        return ASSET_OTHER_SYNTH;
    return ASSET_FOREX;
}

void C_TradeExecutor::ApplyRiskProfile(double requested_risk)
{
    double cap;
    switch(m_assetClass)
    {
        case ASSET_BOOMCRASH:   cap = 0.50; m_maxMarginPct = 0.15; m_maxLots = 1.0; break;
        case ASSET_VOLATILITY:  cap = 0.50; m_maxMarginPct = 0.15; m_maxLots = 1.0; break;
        case ASSET_OTHER_SYNTH: cap = 0.75; m_maxMarginPct = 0.20; m_maxLots = 2.0; break;
        default:                cap = 1.00; m_maxMarginPct = 0.20; m_maxLots = 0.0; break;
    }
    m_riskPercent = MathMin(MathMax(requested_risk, 0.0), MathMin(cap, 1.0));
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
    if((filling & SYMBOL_FILLING_FOK) != 0)       m_trade.SetTypeFilling(ORDER_FILLING_FOK);
    else if((filling & SYMBOL_FILLING_IOC) != 0)  m_trade.SetTypeFilling(ORDER_FILLING_IOC);
    else                                           m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
    return true;
}

// Cross-checked loss per lot: tick math vs OrderCalcProfit, fail closed.
double C_TradeExecutor::GetLossPerLot(ENUM_ORDER_TYPE type, double entry, double sl)
{
    double dist = MathAbs(entry - sl);

    double tv = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE_LOSS);
    if(tv <= 0.0) tv = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
    double ts = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
    double tickMath = (tv > 0.0 && ts > 0.0) ? (dist / ts) * tv : 0.0;

    double profit = 0.0, calc = 0.0;
    if(OrderCalcProfit(type, m_symbol, 1.0, entry, sl, profit) && profit != 0.0)
        calc = MathAbs(profit);

    if(tickMath <= 0.0 && calc <= 0.0) return 0.0;
    if(tickMath <= 0.0) return calc;
    if(calc     <= 0.0) return tickMath;

    double ratio = calc / tickMath;
    if(ratio > 1.05 || ratio < 0.95)
    {
        PrintFormat("[V3 Executor] WARNING: OrderCalcProfit (%.4f) vs tick math (%.4f), ratio %.2f. Using tick math.",
                    calc, tickMath, ratio);
        return tickMath;
    }
    return calc;
}

double C_TradeExecutor::GetMarginPerLot(ENUM_ORDER_TYPE type, double entry)
{
    double margin = 0.0;
    if(OrderCalcMargin(type, m_symbol, 1.0, entry, margin) && margin > 0.0) return margin;
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

    if(vol < minL) return 0.0;
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

    PrintFormat("[V3 AUDIT] %s | entry=%.5f sl=%.5f dist=%.5f | tv=%.8f ts=%.8f contract=%.2f",
                m_symbol, entry, sl, MathAbs(entry - sl),
                SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE),
                SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE),
                SymbolInfoDouble(m_symbol, SYMBOL_TRADE_CONTRACT_SIZE));
    PrintFormat("[V3 AUDIT] risk$=%.2f lossPerLot=%.4f marginPerLot=%.4f freeMargin=%.2f lev=%d",
                risk_money, loss_per_lot, margin_lot, free_m, (int)AccountInfoInteger(ACCOUNT_LEVERAGE));

    if(loss_per_lot <= 0.0) { Print("[V3 Executor] ABORT: loss per lot unknown."); return 0.0; }
    if(margin_lot   <= 0.0) { Print("[V3 Executor] ABORT: margin per lot unknown."); return 0.0; }

    double lots = risk_money / loss_per_lot;

    double max_by_margin = (free_m * m_maxMarginPct) / margin_lot;
    if(lots > max_by_margin)
    {
        PrintFormat("[V3 Executor] Margin clamp: %.4f -> %.4f lots", lots, max_by_margin);
        lots = max_by_margin;
    }

    if(m_maxLots > 0.0 && lots > m_maxLots)
    {
        PrintFormat("[V3 Executor] Lot ceiling (%d): %.4f -> %.2f", (int)m_assetClass, lots, m_maxLots);
        lots = m_maxLots;
    }

    lots = NormalizeVolume(lots);
    if(lots <= 0.0)
        Print("[V3 Executor] ABORT: risk-sized lot below broker minimum. Trade skipped.");
    return lots;
}

bool C_TradeExecutor::HasMargin(ENUM_ORDER_TYPE type, double vol, double price)
{
    double per_lot = GetMarginPerLot(type, price);
    if(per_lot <= 0.0) return false;
    double need   = per_lot * vol;
    double free_m = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    if(need > free_m * 0.95)
    {
        PrintFormat("[V3 Executor] Margin pre-check FAIL: need %.2f, free %.2f", need, free_m);
        return false;
    }
    return true;
}

// [Fix — smaller item] Validate BOTH SL and TP against stop level
bool C_TradeExecutor::EnforceStopLevel(ENUM_ORDER_TYPE type, double price,
                                       double &sl, double &tp, int digits, double point)
{
    bool is_long = (type == ORDER_TYPE_BUY);
    double stop_level = (double)SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
    if(stop_level <= 0.0) return true;

    // SL compliance
    if(MathAbs(price - sl) < stop_level)
        sl = NormalizeDouble(is_long ? price - stop_level : price + stop_level, digits);

    // TP compliance — only adjust if TP is set and too close
    if(tp > 0.0 && MathAbs(price - tp) < stop_level)
        tp = NormalizeDouble(is_long ? price + stop_level : price - stop_level, digits);

    return true;
}

// [Fix #5] Reject if this EA already has a live position on the symbol
bool C_TradeExecutor::HasOpenPosition()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;
        if(PositionGetString(POSITION_SYMBOL)             == m_symbol &&
           (ulong)PositionGetInteger(POSITION_MAGIC)      == m_magicNumber)
            return true;
    }
    return false;
}

bool C_TradeExecutor::SendOrder(ENUM_ORDER_TYPE type, double vol, double price,
                                double sl, double tp, const string comment)
{
    if(!HasMargin(type, vol, price)) return false;

    bool ok = (type == ORDER_TYPE_BUY)
              ? m_trade.Buy(vol,  m_symbol, price, sl, tp, comment)
              : m_trade.Sell(vol, m_symbol, price, sl, tp, comment);

    if(!ok)
        PrintFormat("[V3 Executor] %s FAILED. Retcode=%u (%s)", comment,
                    m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
    else
    {
        m_ticketsOpened++;  // [Fix #1]
        ulong ticket = m_trade.ResultOrder();
        if(ticket == 0) ticket = m_trade.ResultDeal();
        PrintFormat("[V3 Executor] %s OPEN. Ticket=%I64u Vol=%.2f SL=%.5f TP=%.5f",
                    comment, ticket, vol, sl, tp);  // [Fix — %I64u for ulong]
    }
    return ok;
}

bool C_TradeExecutor::ExecuteSplitTrade(const STradeSetup &setup)
{
    m_ticketsOpened = 0;  // [Fix #1] reset at top of every attempt

    if(setup.direction == SIGNAL_NONE) return false;

    // [Fix #5] Block stacking on existing live position
    if(HasOpenPosition())
    {
        Print("[V3 Executor] ABORT: EA already holds an open position on this symbol. No stacking.");
        return false;
    }

    const bool is_long   = (setup.direction == SIGNAL_LONG);
    const ENUM_ORDER_TYPE type = is_long ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

    // 1. Live price — this is what we fill at
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
    if( is_long && s.stopLoss >= price) { Print("[V3 Executor] ABORT: Long SL >= price.");  return false; }
    if(!is_long && s.stopLoss <= price) { Print("[V3 Executor] ABORT: Short SL <= price."); return false; }

    // 3. Stop-level compliance for BOTH SL and TP (smaller item fix)
    EnforceStopLevel(type, price, s.stopLoss, s.tpLocal,  digits, point);
    EnforceStopLevel(type, price, s.stopLoss, s.tpMacro,  digits, point);

    // 4. Size on the FINAL stop (after widening)
    double total_lot = CalculateLotSize(type, price, s.stopLoss);
    if(total_lot <= 0.0) return false;

    // 5. Split into two equal half-lots
    double min_lot  = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
    double half_lot = NormalizeVolume(total_lot / 2.0);
    bool   isSplit  = (half_lot >= min_lot && half_lot > 0.0);

    if(!isSplit)
    {
        half_lot = total_lot;
        Print("[V3 Executor] Half-lot below minimum. Single ticket, full size.");
    }

    // 6. Ticket 1 — Day Trade target
    if(!SendOrder(type, half_lot, price, s.stopLoss, s.tpLocal, s.modelName + " (Day Trade)"))
        return false;

    // 7. Ticket 2 — Runner target (only when Ticket 1 filled)
    if(isSplit)
    {
        price = SymbolInfoDouble(m_symbol, is_long ? SYMBOL_ASK : SYMBOL_BID);
        SendOrder(type, half_lot, price, s.stopLoss, s.tpMacro, s.modelName + " (Runner)");
        // Runner failure is non-fatal: Ticket 1 remains open at half-risk.
        // Return value is always true once Ticket 1 succeeds so that OnTick
        // consumes the POI regardless of whether the runner filled.
    }

    return true;  // at least Ticket 1 filled
}
#endif
