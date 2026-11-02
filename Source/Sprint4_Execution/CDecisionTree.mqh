//+------------------------------------------------------------------+
//|                                              CDecisionTree.mqh   |
//|                              Lula Price Action Execution Engine V3|
//+------------------------------------------------------------------+
#ifndef C_DECISIONTREE_MQH
#define C_DECISIONTREE_MQH

#include "../Sprint3_State/CStateMachine.mqh"
#include "../Sprint1_Sensors/C_MarketStructureSensor.mqh"
#include "../Sprint1_Sensors/C_POI_Sensor.mqh"
#include "../Sprint1_Sensors/C_LiquiditySensor.mqh"

enum ENUM_TRADE_SIGNAL
{
    SIGNAL_NONE,
    SIGNAL_LONG,
    SIGNAL_SHORT
};

// DTO passing exact coordinates to the Executor
struct STradeSetup
{
    ENUM_TRADE_SIGNAL direction;
    double            entryPrice;
    double            stopLoss;
    double            tpLocal;     // Ticket 1: MTF Target (Day Trade)
    double            tpMacro;     // Ticket 2: HTF Target (The Runner)
    string            modelName;   // "POI_Continuation" or "Liquidity_Sweep"
    datetime          poiTime;     // POI formation time (for one-shot mitigation)
    double            sweepLevel;  // Swept liquidity level
};

class C_DecisionTree
{
private:
    string              m_symbol;
    ENUM_TIMEFRAMES     m_ltf;
    int                 m_atrHandle;    // [Fix #4] persistent ATR handle
    double              m_minStopATR;   // [Item 8] min allowed stop as ATR multiple
    double              m_maxStopATR;   // [Item 8] max allowed stop as ATR multiple

    double              GetATR();
    double              GetDynamicBuffer();

public:
                        C_DecisionTree();
                       ~C_DecisionTree();

    bool                Init(string symbol, ENUM_TIMEFRAMES ltf = PERIOD_M5);

    STradeSetup         Evaluate(
                            ENUM_V3_STATE            current_state,
                            C_MarketStructureSensor  *htf_structure,
                            C_MarketStructureSensor  *ltf_structure,
                            C_POI_Sensor             *mtf_poi_sensor,
                            C_LiquiditySensor        *mtf_liquidity
                        );
};

C_DecisionTree::C_DecisionTree()
    : m_symbol(""), m_ltf(PERIOD_M5), m_atrHandle(INVALID_HANDLE),
      m_minStopATR(1.0), m_maxStopATR(4.0) {}

C_DecisionTree::~C_DecisionTree()
{
    if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
}

bool C_DecisionTree::Init(string symbol, ENUM_TIMEFRAMES ltf)
{
    m_symbol = symbol;
    m_ltf    = ltf;
    if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
    m_atrHandle = iATR(m_symbol, m_ltf, 14);

    SSymbolProfile prof = CSymbolProfile::Get(m_symbol);
    m_minStopATR = (prof.stop_min_atr > 0.0) ? prof.stop_min_atr : 1.0;
    m_maxStopATR = (prof.stop_max_atr > 0.0) ? prof.stop_max_atr : 4.0;

    PrintFormat("[V3 Decision Tree] Initialized for %s (LTF: %s | StopATR: %.1f-%.1f)",
                m_symbol, EnumToString(m_ltf), m_minStopATR, m_maxStopATR);
    return true;
}

// [Fix #4 / Item 8] Use cached handle; reads shift-1 (last fully closed LTF bar)
double C_DecisionTree::GetATR()
{
    if(m_atrHandle == INVALID_HANDLE) return 0.0;
    double atr[];
    if(CopyBuffer(m_atrHandle, 0, 1, 1, atr) > 0)
        return atr[0];
    return 0.0;
}

double C_DecisionTree::GetDynamicBuffer()
{
    return GetATR() * 0.5;  // 0.5x ATR for SL breathing room
}

STradeSetup C_DecisionTree::Evaluate(
    ENUM_V3_STATE            current_state,
    C_MarketStructureSensor  *htf_structure,
    C_MarketStructureSensor  *ltf_structure,
    C_POI_Sensor             *mtf_poi_sensor,
    C_LiquiditySensor        *mtf_liquidity)
{
    STradeSetup setup;
    ZeroMemory(setup);
    setup.direction = SIGNAL_NONE;

    if(current_state != STATE_LTF_ARMED_LONG  && current_state != STATE_LTF_ARMED_SHORT &&
       current_state != STATE_LTF_WAIT_RETRACE_LONG && current_state != STATE_LTF_WAIT_RETRACE_SHORT)
        return setup;

    if(htf_structure == NULL || ltf_structure == NULL || mtf_poi_sensor == NULL || mtf_liquidity == NULL)
        return setup;

    // [Fix #4] Use the CLOSED bar price for every structural check, not live tick
    double c1 = iClose(m_symbol, m_ltf, 1);   // last fully closed LTF bar
    if(c1 <= 0.0) return setup;

    // Live ask/bid only for order fill price — filled at live market
    double current_ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
    double current_bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
    double buffer      = GetDynamicBuffer();

    // --- STATE TRACKING LATCHES & ONE-SHOT GUARD ---
    static bool     s_longChochConfirmed  = false;
    static bool     s_shortChochConfirmed = false;
    static datetime s_lastAttemptBarTime  = 0;
    static datetime s_longLatchBar        = 0;   // [Patch 3] latch age tracking
    static datetime s_shortLatchBar       = 0;

    const int LATCH_BARS = 24;   // 24 × LTF bars ≈ 2 hours on M5; tune per asset

    // Reset latches when no longer in an active armed state
    if(current_state != STATE_LTF_ARMED_LONG  && current_state != STATE_LTF_WAIT_RETRACE_LONG)
        s_longChochConfirmed  = false;
    if(current_state != STATE_LTF_ARMED_SHORT && current_state != STATE_LTF_WAIT_RETRACE_SHORT)
        s_shortChochConfirmed = false;

    datetime current_bar_time = iTime(m_symbol, m_ltf, 0);

    // ONE-SHOT GUARD: once an attempt fires on a bar, nothing else fires that bar
    if(current_bar_time > 0 && current_bar_time == s_lastAttemptBarTime)
        return setup;

    // ---------------------------------------------------------
    // GATE 4: LOWER TIME FRAME (LTF) TRIGGER EVALUATION
    // ---------------------------------------------------------

    if(current_state == STATE_LTF_ARMED_LONG || current_state == STATE_LTF_WAIT_RETRACE_LONG)
    {
        double ltf_strong_high = ltf_structure.GetLastWeakHigh();   // [Patch B] CHoCH breaks the WEAK swing, not the strong BOS level

        // [Patch 3] Trap: if price is in HTF premium while armed long, invalidate
        if(htf_structure.PriceInPremiumZone(c1))
        {
            s_longChochConfirmed = false;
            return setup;
        }

        // 1. CHoCH latch — [IsFreshBreak] c1 must be the FIRST closed bar above the level
        //    (c1 > level AND the bar before it was not already above it)
        double c2 = iClose(m_symbol, m_ltf, 2);
        bool isFreshBreak = (ltf_strong_high > 0 && c1 > ltf_strong_high && c2 <= ltf_strong_high);

        if(!s_longChochConfirmed && isFreshBreak)
        {
            s_longChochConfirmed = true;
            s_longLatchBar       = current_bar_time;   // [Patch 3] record when latch was set
            PrintFormat("[V3 Trigger] LATCH SET: Bullish CHoCH on %s (close %.5f > swing %.5f). Waiting for POI.",
                        EnumToString(m_ltf), c1, ltf_strong_high);
        }

        if(!s_longChochConfirmed) return setup;

        // [Patch 3] Latch expiry — stale latches must not fire on unrelated zones hours later
        if(current_bar_time - s_longLatchBar > (datetime)(LATCH_BARS * PeriodSeconds(m_ltf)))
        {
            s_longChochConfirmed = false;
            PrintFormat("[V3 Trigger] Long CHoCH latch EXPIRED after %d bars.", LATCH_BARS);
            return setup;
        }

        // 2. POI re-entry — use closed bar price for containment check
        double   dummy_sl   = 0.0, sweep_level = 0.0;
        datetime poi_time   = 0;
        bool     inside_poi = mtf_poi_sensor.IsInsideBullishPOI(c1, dummy_sl, poi_time);
        bool     eq_swept   = mtf_liquidity.IsEQLSwept(sweep_level);

        if(!inside_poi && !eq_swept)
        {
            // [Diagnostic] Explain the silence
            static datetime lastWaitPrint = 0;
            if(TimeCurrent() - lastWaitPrint >= 300)
            {
                int nz = mtf_poi_sensor.GetPOICount(), act = 0;
                double nearest = 0; double nd = DBL_MAX;
                for(int z = 0; z < nz; z++)
                {
                    SPOI poi = mtf_poi_sensor.GetPOI(z);
                    if(!poi.isActive || !poi.isBullish) continue;
                    act++;
                    double mid = (poi.top + poi.bottom) * 0.5;
                    if(MathAbs(c1 - mid) < nd) { nd = MathAbs(c1 - mid); nearest = mid; }
                }
                double atrVal = 0; double ab[1];
                if(m_atrHandle != INVALID_HANDLE && CopyBuffer(m_atrHandle, 0, 1, 1, ab) > 0) atrVal = ab[0];
                PrintFormat("[V3 Wait] LONG | zones total=%d activeBull=%d | nearest mid=%.5f | dist=%.5f | atrLTF=%.5f",
                            nz, act, nearest, (act > 0 ? nd : 0.0), atrVal);
                lastWaitPrint = TimeCurrent();
            }
            return setup;
        }

        // 3. Build the setup
        if(inside_poi)
        {
            setup.direction  = SIGNAL_LONG;
            setup.entryPrice = current_ask;
            setup.stopLoss   = dummy_sl - buffer;
            setup.modelName  = "POI_Continuation_Long";
            setup.poiTime    = poi_time;
        }
        else // eq_swept
        {
            setup.direction  = SIGNAL_LONG;
            setup.entryPrice = current_ask;
            setup.stopLoss   = sweep_level - buffer;
            setup.modelName  = "Liquidity_Sweep_Long";
            setup.sweepLevel = sweep_level;
        }

        if(setup.direction == SIGNAL_LONG)
        {
            // [Item 8] Stop-size bounds check (reject out-of-range stops, do not widen)
            double atr  = GetATR();
            double risk = MathAbs(setup.entryPrice - setup.stopLoss);
            if(atr <= 0.0 || risk < m_minStopATR * atr || risk > m_maxStopATR * atr)
            {
                PrintFormat("[V3 Trigger] REJECT: stop %.5f = %.2f ATR (allowed %.2f-%.2f).",
                            risk, atr > 0 ? risk / atr : 0.0, m_minStopATR, m_maxStopATR);
                setup.direction = SIGNAL_NONE;
                s_lastAttemptBarTime = current_bar_time;
                return setup;
            }

            setup.tpLocal = htf_structure.GetLastWeakHigh();
            if(setup.tpLocal <= setup.entryPrice)
            {
                double risk = setup.entryPrice - setup.stopLoss;
                setup.tpLocal = setup.entryPrice + risk * 2.0;
            }
            setup.tpMacro = setup.tpLocal + (setup.tpLocal - setup.entryPrice);

            PrintFormat("[V3 Execution] %s | Entry %.5f | SL %.5f | TP1 %.5f",
                        setup.modelName, setup.entryPrice, setup.stopLoss, setup.tpLocal);
            s_longChochConfirmed = false;
            s_lastAttemptBarTime = current_bar_time;
        }
    }
    else if(current_state == STATE_LTF_ARMED_SHORT || current_state == STATE_LTF_WAIT_RETRACE_SHORT)
    {
        double ltf_strong_low = ltf_structure.GetLastWeakLow();    // [Patch B] CHoCH breaks the WEAK swing, not the strong BOS level

        // Trap override: if HTF is now Discount, invalidate
        if(htf_structure.PriceInDiscountZone(c1))
        {
            s_shortChochConfirmed = false;
            return setup;
        }

        // 1. CHoCH latch — [IsFreshBreak] c1 must be the FIRST closed bar below the level
        double c2 = iClose(m_symbol, m_ltf, 2);
        bool isFreshBreak = (ltf_strong_low > 0 && c1 < ltf_strong_low && c2 >= ltf_strong_low);

        if(!s_shortChochConfirmed && isFreshBreak)
        {
            s_shortChochConfirmed = true;
            s_shortLatchBar       = current_bar_time;   // [Patch 3] record when latch was set
            PrintFormat("[V3 Trigger] LATCH SET: Bearish CHoCH on %s (close %.5f < swing %.5f). Waiting for POI.",
                        EnumToString(m_ltf), c1, ltf_strong_low);
        }

        if(!s_shortChochConfirmed) return setup;

        // [Patch 3] Latch expiry
        if(current_bar_time - s_shortLatchBar > (datetime)(LATCH_BARS * PeriodSeconds(m_ltf)))
        {
            s_shortChochConfirmed = false;
            PrintFormat("[V3 Trigger] Short CHoCH latch EXPIRED after %d bars.", LATCH_BARS);
            return setup;
        }

        // 2. POI re-entry — use closed bar price
        double   dummy_sl   = 0.0, sweep_level = 0.0;
        datetime poi_time   = 0;
        bool     inside_poi = mtf_poi_sensor.IsInsideBearishPOI(c1, dummy_sl, poi_time);
        bool     eq_swept   = mtf_liquidity.IsEQHSwept(sweep_level);

        if(!inside_poi && !eq_swept)
        {
            // [Diagnostic] Explain the silence
            static datetime lastWaitPrintS = 0;
            if(TimeCurrent() - lastWaitPrintS >= 300)
            {
                int nz = mtf_poi_sensor.GetPOICount(), act = 0;
                double nearest = 0; double nd = DBL_MAX;
                for(int z = 0; z < nz; z++)
                {
                    SPOI poi = mtf_poi_sensor.GetPOI(z);
                    if(!poi.isActive || poi.isBullish) continue;
                    act++;
                    double mid = (poi.top + poi.bottom) * 0.5;
                    if(MathAbs(c1 - mid) < nd) { nd = MathAbs(c1 - mid); nearest = mid; }
                }
                double atrVal = 0; double ab[1];
                if(m_atrHandle != INVALID_HANDLE && CopyBuffer(m_atrHandle, 0, 1, 1, ab) > 0) atrVal = ab[0];
                PrintFormat("[V3 Wait] SHORT | zones total=%d activeBear=%d | nearest mid=%.5f | dist=%.5f | atrLTF=%.5f",
                            nz, act, nearest, (act > 0 ? nd : 0.0), atrVal);
                lastWaitPrintS = TimeCurrent();
            }
            return setup;
        }

        // 3. Build the setup
        if(inside_poi)
        {
            setup.direction  = SIGNAL_SHORT;
            setup.entryPrice = current_bid;
            setup.stopLoss   = dummy_sl + buffer;
            setup.modelName  = "POI_Continuation_Short";
            setup.poiTime    = poi_time;
        }
        else // eq_swept
        {
            setup.direction  = SIGNAL_SHORT;
            setup.entryPrice = current_bid;
            setup.stopLoss   = sweep_level + buffer;
            setup.modelName  = "Liquidity_Sweep_Short";
            setup.sweepLevel = sweep_level;
        }

        if(setup.direction == SIGNAL_SHORT)
        {
            // [Item 8] Stop-size bounds check (reject out-of-range stops, do not widen)
            double atr  = GetATR();
            double risk = MathAbs(setup.entryPrice - setup.stopLoss);
            if(atr <= 0.0 || risk < m_minStopATR * atr || risk > m_maxStopATR * atr)
            {
                PrintFormat("[V3 Trigger] REJECT: stop %.5f = %.2f ATR (allowed %.2f-%.2f).",
                            risk, atr > 0 ? risk / atr : 0.0, m_minStopATR, m_maxStopATR);
                setup.direction = SIGNAL_NONE;
                s_lastAttemptBarTime = current_bar_time;
                return setup;
            }

            setup.tpLocal = htf_structure.GetLastWeakLow();
            if(setup.tpLocal >= setup.entryPrice || setup.tpLocal == 0)
            {
                double risk = setup.stopLoss - setup.entryPrice;
                setup.tpLocal = setup.entryPrice - risk * 2.0;
            }
            setup.tpMacro = setup.tpLocal - (setup.entryPrice - setup.tpLocal);

            PrintFormat("[V3 Execution] %s | Entry %.5f | SL %.5f | TP1 %.5f",
                        setup.modelName, setup.entryPrice, setup.stopLoss, setup.tpLocal);
            s_shortChochConfirmed = false;
            s_lastAttemptBarTime  = current_bar_time;
        }
    }

    return setup;
}
#endif
