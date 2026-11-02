//+------------------------------------------------------------------+
//|                                             CTradeExecutor.mqh   |
//|                             Lula Price Action Execution Engine V3|
//+------------------------------------------------------------------+
#ifndef CTRADEEXECUTOR_MQH
#define CTRADEEXECUTOR_MQH

#include <Trade\Trade.mqh>
#include "..\Include\Defines.mqh"
#include "CDecisionTree.mqh"
#include "C_TradeManager.mqh"          // [PATCH X1] 3-tier manager

enum ENUM_ASSET_CLASS { ASSET_FOREX, ASSET_VOLATILITY, ASSET_BOOMCRASH, ASSET_OTHER_SYNTH };

class C_TradeExecutor
{
private:
    CTrade            m_trade;
    string            m_symbol;
    double            m_riskPercent;
    double            m_maxMarginPct;
    double            m_maxLots;
    ulong             m_magicNumber;
    ENUM_ASSET_CLASS  m_assetClass;
    int               m_ticketsOpened;
    double            m_minRR;
    double            m_maxSpreadFrac;
    int               m_atrHandle;              // [PATCH X2] local ATR for tier reg

    C_TradeManager   *m_manager;                // [PATCH X1] optional; NULL → legacy 2-ticket
    ENUM_TIMEFRAMES   m_ltf;                    // [PATCH X3] for entryTime grouping

    ENUM_ASSET_CLASS  DetectAssetClass();
    void              ApplyRiskProfile(double requested_risk);
    bool              SetSafeFillingMode();
    double            GetLossPerLot(ENUM_ORDER_TYPE type, double entry, double sl);
    double            GetMarginPerLot(ENUM_ORDER_TYPE type, double entry);
    double            NormalizeVolume(double vol);
    double            CalculateLotSize(ENUM_ORDER_TYPE type, double entry, double sl);
    bool              HasMargin(ENUM_ORDER_TYPE type, double vol, double price);
    bool              EnforceStopLevel(ENUM_ORDER_TYPE type, double price, double &sl, double &tp, int digits, double point);
    double            GetATR();                 // [PATCH X2]

    // [PATCH X4] SendOrder now returns position id (0 = failure) so manager can register.
    ulong             SendOrder(ENUM_ORDER_TYPE type, double vol, double price,
                                double sl, double tp, const string comment);

public:
                      C_TradeExecutor();
                     ~C_TradeExecutor();

    bool              Init(string symbol, double risk_percent, ulong magic_number,
                           ENUM_TIMEFRAMES ltf = PERIOD_M5);   // [PATCH X3]
    bool              ExecuteSplitTrade(const STradeSetup &setup);
    int               TicketsOpened() const { return m_ticketsOpened; }
    bool              HasOpenPosition();
    void              ManageRunner();   // legacy path only; no-op when manager is set

    // [PATCH X1]
    void              SetTradeManager(C_TradeManager *mgr) { m_manager = mgr; }
};

C_TradeExecutor::C_TradeExecutor()
    : m_symbol(""), m_riskPercent(0.5), m_maxMarginPct(0.20),
      m_maxLots(0.0), m_magicNumber(777777), m_assetClass(ASSET_FOREX),
      m_ticketsOpened(0), m_minRR(1.5), m_maxSpreadFrac(0.15),
      m_atrHandle(INVALID_HANDLE), m_manager(NULL), m_ltf(PERIOD_M5) {}

C_TradeExecutor::~C_TradeExecutor()
{
    if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
}

double C_TradeExecutor::GetATR()
{
    if(m_atrHandle == INVALID_HANDLE) return 0.0;
    double a[];
    if(CopyBuffer(m_atrHandle, 0, 1, 1, a) > 0) return a[0];
    return 0.0;
}

ENUM_ASSET_CLASS C_TradeExecutor::DetectAssetClass()
{
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

// [PATCH X3] Init now takes an LTF so the executor can stamp entryTime consistently
bool C_TradeExecutor::Init(string symbol, double risk_percent, ulong magic_number,
                           ENUM_TIMEFRAMES ltf)
{
    if(symbol == "" || risk_percent <= 0.0) return false;

    m_symbol      = symbol;
    m_magicNumber = magic_number;
    m_ltf         = ltf;
    m_assetClass  = DetectAssetClass();
    ApplyRiskProfile(risk_percent);

    SSymbolProfile prof = CSymbolProfile::Get(m_symbol);
    m_maxSpreadFrac = (prof.stop_max_spread_frac > 0.0) ? prof.stop_max_spread_frac : 0.15;

    if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
    m_atrHandle = iATR(m_symbol, m_ltf, 14);

    m_trade.SetExpertMagicNumber(m_magicNumber);
    m_trade.SetDeviationInPoints(10);

    if(!SetSafeFillingMode())
    {
        PrintFormat("[V3 Executor] FATAL: no valid filling mode for %s", m_symbol);
        return false;
    }

    PrintFormat("[V3 Executor] Init %s | Class=%d | Risk req=%.2f%% eff=%.2f%% | MaxMargin=%.0f%% | MaxLots=%.2f | Magic=%I64u | LTF=%s | Manager=%s",
                m_symbol, (int)m_assetClass, risk_percent, m_riskPercent,
                m_maxMarginPct * 100.0, m_maxLots, m_magicNumber,
                EnumToString(m_ltf), m_manager ? "ATTACHED" : "none (legacy 2-ticket)");
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

bool C_TradeExecutor::EnforceStopLevel(ENUM_ORDER_TYPE type, double price,
                                       double &sl, double &tp, int digits, double point)
{
    bool is_long = (type == ORDER_TYPE_BUY);
    double stop_level = (double)SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
    if(stop_level <= 0.0) return true;

    if(MathAbs(price - sl) < stop_level)
        sl = NormalizeDouble(is_long ? price - stop_level : price + stop_level, digits);

    if(tp > 0.0 && MathAbs(price - tp) < stop_level)
        tp = NormalizeDouble(is_long ? price + stop_level : price - stop_level, digits);

    return true;
}

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

// [PATCH X4] Returns the position id (0 = failure)
ulong C_TradeExecutor::SendOrder(ENUM_ORDER_TYPE type, double vol, double price,
                                 double sl, double tp, const string comment)
{
    if(!HasMargin(type, vol, price)) return 0;

    bool ok = (type == ORDER_TYPE_BUY)
              ? m_trade.Buy(vol,  m_symbol, price, sl, tp, comment)
              : m_trade.Sell(vol, m_symbol, price, sl, tp, comment);

    if(!ok)
    {
        PrintFormat("[V3 Executor] %s FAILED. Retcode=%u (%s)", comment,
                    m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
        return 0;
    }

    m_ticketsOpened++;

    ulong dealTicket = m_trade.ResultDeal();
    ulong posId      = 0;
    if(dealTicket > 0 && HistoryDealSelect(dealTicket))
        posId = (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);

    PrintFormat("[V3 Executor] %s OPEN. Deal=%I64u Pos=%I64u Vol=%.2f SL=%.5f TP=%.5f",
                comment, dealTicket, posId, vol, sl, tp);
    return posId;
}

//====================================================================
// ExecuteSplitTrade — 3-tier when manager attached, else legacy 2-ticket
//====================================================================
bool C_TradeExecutor::ExecuteSplitTrade(const STradeSetup &setup)
{
    m_ticketsOpened = 0;
    if(setup.direction == SIGNAL_NONE) return false;

    if(HasOpenPosition())
    {
        Print("[V3 Executor] ABORT: EA already holds an open position on this symbol. No stacking.");
        return false;
    }

    const bool is_long = (setup.direction == SIGNAL_LONG);
    const ENUM_ORDER_TYPE type = is_long ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

    double price = SymbolInfoDouble(m_symbol, is_long ? SYMBOL_ASK : SYMBOL_BID);
    if(price <= 0.0) return false;

    int    digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
    double point  = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
    if(point <= 0.0) return false;

    STradeSetup s = setup;
    s.stopLoss = NormalizeDouble(setup.stopLoss, digits);
    s.tpLocal  = NormalizeDouble(setup.tpLocal,  digits);
    s.tpMacro  = NormalizeDouble(setup.tpMacro,  digits);

    // [PATCH X5] Populate tp1/2/3 with fallback to legacy aliases
    s.tp1 = (setup.tp1 > 0.0) ? NormalizeDouble(setup.tp1, digits) : s.tpLocal;
    s.tp2 = (setup.tp2 > 0.0) ? NormalizeDouble(setup.tp2, digits) : 0.0;
    s.tp3 = (setup.tp3 > 0.0) ? NormalizeDouble(setup.tp3, digits) : s.tpMacro;

    // Directional sanity
    if( is_long && s.stopLoss >= price) { Print("[V3 Executor] ABORT: Long SL >= price.");  return false; }
    if(!is_long && s.stopLoss <= price) { Print("[V3 Executor] ABORT: Short SL <= price."); return false; }

    // Stop-level: validate SL against tp1 AND tp3 separately, then sync aliases
    double checkTP1 = s.tp1;
    double checkTP3 = s.tp3;
    EnforceStopLevel(type, price, s.stopLoss, checkTP1, digits, point);
    EnforceStopLevel(type, price, s.stopLoss, checkTP3, digits, point);
    s.tp1     = checkTP1;
    s.tp3     = checkTP3;
    s.tpLocal = s.tp1;
    s.tpMacro = s.tp3;

    // R:R gate — bound by tp1 (tightest target)
    if( is_long && s.tp1 <= price) { Print("[V3 Executor] ABORT: TP1 on wrong side of entry."); return false; }
    if(!is_long && s.tp1 >= price) { Print("[V3 Executor] ABORT: TP1 on wrong side of entry."); return false; }
    double risk = MathAbs(price - s.stopLoss);
    double rew  = MathAbs(s.tp1 - price);
    if(risk <= 0.0 || rew / risk < m_minRR)
    {
        PrintFormat("[V3 Executor] ABORT: RR %.2f < min %.2f. Trade skipped.", risk > 0 ? rew / risk : 0.0, m_minRR);
        return false;
    }

    // Spread gate
    double spread = SymbolInfoDouble(m_symbol, SYMBOL_ASK) - SymbolInfoDouble(m_symbol, SYMBOL_BID);
    if(spread > m_maxSpreadFrac * risk)
    {
        PrintFormat("[V3 Executor] ABORT: spread %.5f > %.0f%% of stop %.5f.",
                    spread, m_maxSpreadFrac * 100.0, risk);
        return false;
    }

    // Size on final stop
    double total_lot = CalculateLotSize(type, price, s.stopLoss);
    if(total_lot <= 0.0) return false;
    double min_lot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);

    // Decide mode — 3-tier requires manager attachment + populated v3 fields
    bool hasV3Fields = (setup.tp1 > 0.0 && setup.tp2 > 0.0 && setup.tp3 > 0.0);
    bool use3Tier    = hasV3Fields && (m_manager != NULL);

    if(hasV3Fields && !m_manager)
        Print("[V3 Executor] WARNING: v3 fields present but manager not attached. Falling back to legacy 2-ticket.");

    datetime entryTime = TimeCurrent();
    double   atrEntry  = GetATR();

    //------------------------------------------------------------------
    // 3-TIER PATH
    //------------------------------------------------------------------
    if(use3Tier)
    {
        double fr[3] = { setup.volT1, setup.volT2, setup.volT3 };
        if(fr[0] <= 0.0 || fr[1] <= 0.0 || fr[2] <= 0.0)
        {
            fr[0] = 0.40; fr[1] = 0.30; fr[2] = 0.30;
            Print("[V3 Executor] Volume fractions not set. Using defaults 40/30/30.");
        }
        double nsum = fr[0] + fr[1] + fr[2];
        if(nsum > 0.0) { fr[0] /= nsum; fr[1] /= nsum; fr[2] /= nsum; }

        double tps[3]  = { s.tp1, s.tp2, s.tp3 };
        double vols[3] = { 0.0, 0.0, 0.0 };

        // Can we split into 3 viable tickets?
        bool canSplit3 = (total_lot >= min_lot * 3.0);

        if(canSplit3)
        {
            vols[0] = NormalizeVolume(total_lot * fr[0]);
            vols[1] = NormalizeVolume(total_lot * fr[1]);
            vols[2] = NormalizeVolume(total_lot * fr[2]);

            double drift = total_lot - (vols[0] + vols[1] + vols[2]);
            if(vols[2] + drift >= min_lot)
                vols[2] = NormalizeVolume(vols[2] + drift);

            // Fold below-minimum tiers into T3
            for(int i = 0; i < 2; i++)
                if(vols[i] < min_lot) { vols[2] = NormalizeVolume(vols[2] + vols[i]); vols[i] = 0.0; }
        }
        else
        {
            vols[2] = total_lot;
            Print("[V3 Executor] Total lot below 3× minimum. Single T3 (runner) ticket.");
        }

        for(int tier = 0; tier < 3; tier++)
        {
            if(vols[tier] < min_lot) continue;

            double livePx   = SymbolInfoDouble(m_symbol, is_long ? SYMBOL_ASK : SYMBOL_BID);
            // T1 & T2 use broker TP; T3 has no broker TP — EA manages exit via manager
            double brokerTP = (tier < 2) ? tps[tier] : 0.0;

            // Re-validate stop level per live price
            double ticketSL = s.stopLoss;
            double checkTP  = (brokerTP > 0.0) ? brokerTP : tps[tier];
            EnforceStopLevel(type, livePx, ticketSL, checkTP, digits, point);
            if(brokerTP > 0.0) brokerTP = checkTP;

            string tag = s.modelName + " T" + IntegerToString(tier + 1);

            ulong posId = SendOrder(type, vols[tier], livePx, ticketSL, brokerTP, tag);
            if(posId > 0)
            {
                // trendAtEntry = 0 here; manager resolves trend from htf_structure on next bar
                m_manager.Register(posId, tier + 1, is_long ? +1 : -1,
                                   livePx, ticketSL, tps[tier],
                                   0, atrEntry,
                                   s.modelName, entryTime);
            }
            else
            {
                // T1 failure is fatal — without the entry ticket we've lost the POI
                if(tier == 0 && m_ticketsOpened == 0) return false;
                // T2/T3 failure is non-fatal — allow remaining tiers to continue
                PrintFormat("[V3 Executor] T%d send failed. Continuing with remaining tiers.", tier + 1);
            }
        }

        PrintFormat("[V3 Executor] 3-tier execution complete: %d ticket(s) opened [%s].",
                    m_ticketsOpened, s.modelName);
        return (m_ticketsOpened > 0);
    }

    //------------------------------------------------------------------
    // LEGACY 2-TICKET PATH (unchanged behavior)
    //------------------------------------------------------------------
    double half_lot  = NormalizeVolume(total_lot / 2.0);
    bool   isSplit   = (half_lot >= min_lot && half_lot > 0.0);

    if(!isSplit)
    {
        half_lot = total_lot;
        Print("[V3 Executor] Half-lot below minimum. Single ticket, full size.");
    }

    if(SendOrder(type, half_lot, price, s.stopLoss, s.tpLocal, s.modelName + " (Day Trade)") == 0)
        return false;

    if(isSplit)
    {
        price = SymbolInfoDouble(m_symbol, is_long ? SYMBOL_ASK : SYMBOL_BID);
        SendOrder(type, half_lot, price, s.stopLoss, s.tpMacro, s.modelName + " (Runner)");
    }

    return true;
}

//====================================================================
// ManageRunner — legacy path only; superseded by C_TradeManager
//====================================================================
void C_TradeExecutor::ManageRunner()
{
    // [PATCH X6] When the manager is attached it owns all SL/trailing/exit logic.
    if(m_manager != NULL) return;

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

    if(n != 1 || rt == 0 || !PositionSelectByTicket(rt)) return;

    double open = PositionGetDouble(POSITION_PRICE_OPEN);
    double sl   = PositionGetDouble(POSITION_SL);
    double tp   = PositionGetDouble(POSITION_TP);
    bool   buy  = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);

    if((buy && sl >= open) || (!buy && sl > 0.0 && sl <= open)) return;

    double px = SymbolInfoDouble(m_symbol, buy ? SYMBOL_BID : SYMBOL_ASK);
    if((buy && px <= open) || (!buy && px >= open)) return;

    int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
    if(m_trade.PositionModify(rt, NormalizeDouble(open, digits), tp))
        PrintFormat("[V3 Runner] Ticket %I64u moved to breakeven (%.5f).", rt, open);
    else
        PrintFormat("[V3 Runner] BE move failed. Retcode=%u", m_trade.ResultRetcode());
}

#endif
