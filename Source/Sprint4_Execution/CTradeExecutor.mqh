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
    double            m_minRR;            // [Patch 6] minimum reward:risk ratio; default 1.5
    double            m_maxSpreadFrac;    // [Item 8] max allowed spread as fraction of stop risk (default 0.15)

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

public:
                      C_TradeExecutor();
                     ~C_TradeExecutor() {}

    bool              Init(string symbol, double risk_percent, ulong magic_number);
    bool              ExecuteSplitTrade(const STradeSetup &setup);
    int               TicketsOpened() const { return m_ticketsOpened; } // [Fix #1]
    bool              HasOpenPosition();   // [Patch 6] public — guard before Evaluate in OnTick
    void              ManageRunner();      // [Patch 6] breakeven management for the Runner ticket
};

C_TradeExecutor::C_TradeExecutor()
    : m_symbol(""), m_riskPercent(0.5), m_maxMarginPct(0.20),
      m_maxLots(0.0), m_magicNumber(777777), m_assetClass(ASSET_FOREX),
      m_ticketsOpened(0), m_minRR(1.5), m_maxSpreadFrac(0.15) {}

ENUM_ASSET_CLASS C_TradeExecutor::DetectAssetClass()
{
    // [Patch 7] Single source of truth: delegate to CSymbolProfile so there is
    // no divergence between the executor's classifier and the profile system.
    // (Old string-scan missed EURUSD.m, Step Index, Jump Index, etc.)
    switch(CSymbolProfile::Get(m_symbol).cls)
    {
        case SYM_SPIKY_SYNTH:    return ASSET_BOOMCRASH;
        case SYM_VOLATILE_SYNTH: return ASSET_VOLATILITY;
        case SYM_FOREX:
        case SYM_METAL:          return ASSET_FOREX;
        default:                 return ASSET_OTHER_SYNTH;
    }
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

    SSymbolProfile prof = CSymbolProfile::Get(m_symbol);
    m_maxSpreadFrac = (prof.stop_max_spread_frac > 0.0) ? prof.stop_max_spread_frac : 0.15;

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

    // [Patch 5] MQL_TESTER branch removed: OrderCalcProfit is 10,000× tick math
    // on Deriv Synthetics in the tester, producing sub-minimum lots that abort
    // every synthetic trade. Cross-check still runs in live; validate on EURUSD
    // first, then test Synthetics with a corrected custom-symbol spec.
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

    PrintFormat("[V3 AUDIT] %s | entry=%.5f sl=%.5f dist=%.5f | tv=%.8f tvProfit=%.8f ts=%.8f contract=%.2f calcMode=%d volMin=%.4f",
                m_symbol, entry, sl, MathAbs(entry - sl),
                SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE),
                SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE_PROFIT),
                SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE),
                SymbolInfoDouble(m_symbol, SYMBOL_TRADE_CONTRACT_SIZE),
                (int)SymbolInfoInteger(m_symbol, SYMBOL_TRADE_CALC_MODE),
                SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN));
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

    // [Patch 6] R:R gate — reject trades where the target is on the wrong side or below minimum R:R
    {
        if( is_long && s.tpLocal <= price) { Print("[V3 Executor] ABORT: TP on wrong side of entry."); return false; }
        if(!is_long && s.tpLocal >= price) { Print("[V3 Executor] ABORT: TP on wrong side of entry."); return false; }
        double risk = MathAbs(price - s.stopLoss);
        double rew  = MathAbs(s.tpLocal - price);
        if(risk <= 0.0 || rew / risk < m_minRR)
        {
            PrintFormat("[V3 Executor] ABORT: RR %.2f < min %.2f. Trade skipped.", risk > 0 ? rew / risk : 0.0, m_minRR);
            return false;
        }
    }

    // [Item 8] Spread gate — abort if spread exceeds allowed fraction of stop risk
    double spread = SymbolInfoDouble(m_symbol, SYMBOL_ASK) - SymbolInfoDouble(m_symbol, SYMBOL_BID);
    double risk_spread = MathAbs(price - s.stopLoss);
    if(spread > m_maxSpreadFrac * risk_spread)
    {
        PrintFormat("[V3 Executor] ABORT: spread %.5f > %.0f%% of stop %.5f.",
                    spread, m_maxSpreadFrac * 100.0, risk_spread);
        return false;
    }

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

// [Patch 6] Move the Runner ticket to breakeven once the Day Trade ticket has closed.
// Called from OnTick BEFORE Evaluate so the guard fires on the very first tick after fill.
// Note: MT5 truncates comments to 31 chars. "POI_Continuation_Long (Runner)" = 30 chars — OK.
// If model names are renamed, keep the "(Runner)" suffix to at most 9 trailing chars.
void C_TradeExecutor::ManageRunner()
{
    int   n  = 0;
    ulong rt = 0;

    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong t = PositionGetTicket(i);
        if(t == 0) continue;
        if(PositionGetString(POSITION_SYMBOL)        != m_symbol ||
           (ulong)PositionGetInteger(POSITION_MAGIC) != m_magicNumber) continue;
        n++;
        if(StringFind(PositionGetString(POSITION_COMMENT), "(Runner)") >= 0) rt = t;
    }

    // Only act when the Runner is the sole surviving ticket (Day Trade already closed)
    if(n != 1 || rt == 0 || !PositionSelectByTicket(rt)) return;

    double open = PositionGetDouble(POSITION_PRICE_OPEN);
    double sl   = PositionGetDouble(POSITION_SL);
    double tp   = PositionGetDouble(POSITION_TP);
    bool   buy  = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);

    // Already at breakeven or beyond — nothing to do
    if((buy && sl >= open) || (!buy && sl > 0.0 && sl <= open)) return;

    // Not yet in profit — wait
    double px = SymbolInfoDouble(m_symbol, buy ? SYMBOL_BID : SYMBOL_ASK);
    if((buy && px <= open) || (!buy && px >= open)) return;

    int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
    if(m_trade.PositionModify(rt, NormalizeDouble(open, digits), tp))
        PrintFormat("[V3 Runner] Ticket %I64u moved to breakeven (%.5f).", rt, open);
    else
        PrintFormat("[V3 Runner] BE move failed. Retcode=%u", m_trade.ResultRetcode());
}

#endif
