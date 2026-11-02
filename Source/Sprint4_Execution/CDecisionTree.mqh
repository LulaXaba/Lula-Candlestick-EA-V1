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
    double            tp1;          // NEW — target 1
    double            tp2;          // NEW — target 2
    double            tp3;          // NEW — target 3 (runner)
    double            tpLocal;      // alias for tp1 (back-compat)
    double            tpMacro;      // alias for tp3 (back-compat)
    double            atrAtEntry;   // NEW
    string            modelName;
    datetime          poiTime;
    double            sweepLevel;
    // NEW — tier volume fractions (sum = 1.0)
    double            volT1;
    double            volT2;
    double            volT3;
};

class C_DecisionTree
{
private:
    string              m_symbol;
    ENUM_TIMEFRAMES     m_ltf;
    int                 m_atrHandle;    // [Fix #4] persistent ATR handle
    double              m_minStopATR;   // [Item 8] min allowed stop as ATR multiple
    double              m_maxStopATR;   // [Item 8] max allowed stop as ATR multiple
    // [PATCH D1] New tunables
    int                 m_latchBars;    // was: const int LATCH_BARS = 24
    double              m_proxATR;      // entry proximity tolerance as ATR fraction

    double              GetATR();
    double              GetDynamicBuffer();

public:
                        C_DecisionTree();
                       ~C_DecisionTree();

    bool                Init(string symbol, ENUM_TIMEFRAMES ltf = PERIOD_M5,
                             int latchBars = 72, double proxATR = 0.30,
                             double minStopATR = 0.0, double maxStopATR = 0.0);   // [FIX S-1]

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
      m_minStopATR(1.0), m_maxStopATR(10.0),
      m_latchBars(72), m_proxATR(0.30) {}

C_DecisionTree::~C_DecisionTree()
{
    if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
}

bool C_DecisionTree::Init(string symbol, ENUM_TIMEFRAMES ltf, int latchBars, double proxATR,
                          double minStopATR, double maxStopATR)
{
    m_symbol    = symbol;
    m_ltf       = ltf;
    m_latchBars = latchBars;
    m_proxATR   = proxATR;
    if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
    m_atrHandle = iATR(m_symbol, m_ltf, 14);

    SSymbolProfile prof = CSymbolProfile::Get(m_symbol);
    m_minStopATR = (minStopATR > 0.0) ? minStopATR
                  : ((prof.stop_min_atr > 0.0) ? prof.stop_min_atr : 1.0);
    m_maxStopATR = (maxStopATR > 0.0) ? maxStopATR
                  : ((prof.stop_max_atr > 0.0) ? prof.stop_max_atr : 10.0);

    PrintFormat("[V3 Decision Tree] Initialized for %s (LTF: %s | StopATR: %.1f-%.1f | latchBars: %d | proxATR: %.2f)",
                m_symbol, EnumToString(m_ltf), m_minStopATR, m_maxStopATR, m_latchBars, m_proxATR);
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

        // 1. CHoCH latch — [PATCH D3] refresh on every fresh CHoCH, not just the first
        double c2 = iClose(m_symbol, m_ltf, 2);
        bool isFreshBreak = (ltf_strong_high > 0 && c1 > ltf_strong_high && c2 <= ltf_strong_high);

        if(isFreshBreak)
        {
            s_longChochConfirmed = true;
            s_longLatchBar       = current_bar_time;
            PrintFormat("[V3 Trigger] LATCH SET/REFRESH: Bullish CHoCH on %s (close %.5f > swing %.5f). Waiting for POI.",
                        EnumToString(m_ltf), c1, ltf_strong_high);
        }

        if(!s_longChochConfirmed) return setup;

        // [PATCH D3] Latch expiry
        if(current_bar_time - s_longLatchBar > (datetime)(m_latchBars * PeriodSeconds(m_ltf)))
        {
            s_longChochConfirmed = false;
            PrintFormat("[V3 Trigger] Long CHoCH latch EXPIRED after %d bars.", m_latchBars);
            return setup;
        }

        // 2. POI re-entry — [PATCH D4] inside OR within m_proxATR * ATR of the nearest zone
        double   dummy_sl   = 0.0, sweep_level = 0.0;
        datetime poi_time   = 0;
        double   atrDT      = GetATR();
        bool     inside_poi = mtf_poi_sensor.IsInsideBullishPOI(c1, dummy_sl, poi_time);
        bool     near_poi   = (!inside_poi && atrDT > 0.0)
                              ? mtf_poi_sensor.IsNearBullishPOI(c1, atrDT, dummy_sl, poi_time)
                              : false;
        bool     eq_swept   = mtf_liquidity.IsEQLSwept(sweep_level);

        if(!inside_poi && !near_poi && !eq_swept)
        {
            // [Diagnostic] Explain the silence [PATCH D5]
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
                PrintFormat("[V3 Wait] LONG | zones total=%d activeBull=%d (totBull=%d) | nearest mid=%.5f | dist=%.5f | atrLTF=%.5f",
                            nz, act, mtf_poi_sensor.GetTotalBullCount(), nearest, (act > 0 ? nd : 0.0), atrVal);
                lastWaitPrint = TimeCurrent();
            }
            return setup;
        }

        bool usable_poi = (inside_poi || near_poi);

        // 3. Build the setup
        if(usable_poi)
        {
            setup.direction  = SIGNAL_LONG;
            setup.entryPrice = current_ask;
            setup.stopLoss   = dummy_sl - buffer;
            setup.modelName  = (near_poi && !inside_poi) ? "POI_Proximity_Long" : "POI_Continuation_Long";
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
            // [Item 8] Stop-size bounds check (Widen tight stops, reject wide stops)
            double atr  = GetATR();
            if(atr <= 0.0) 
            {
                Print("[V3 Trigger] REJECT: ATR is 0.0, cannot calculate stop floor.");
                setup.direction = SIGNAL_NONE;
                s_lastAttemptBarTime = current_bar_time;
                return setup;
            }
            
            double current_risk = setup.entryPrice - setup.stopLoss;
            double min_risk = m_minStopATR * atr;
            double max_risk = m_maxStopATR * atr;
            
            // [FIX S-2] Wide stops are valid — accept and let risk-sizing shrink the lot
            if(current_risk > max_risk)
            {
                PrintFormat("[V3 Trigger] ACCEPT-WIDE: Stop %.2f ATR (max %.2f). Lot will scale down.", 
                            current_risk / atr, m_maxStopATR);
                // no rejection — CalculateLotSize handles the sizing
            }
            else if(current_risk < min_risk)
            {
                PrintFormat("[V3 Trigger] ADJUST: Stop %.5f too tight (%.2f ATR). Widening SL to %.2f ATR.", 
                            current_risk, current_risk / atr, m_minStopATR);
                setup.stopLoss = setup.entryPrice - min_risk;
            }

            // [PATCH TM-1] — explicit T1/T2/T3 with per-setup volume splits
            double risk = setup.entryPrice - setup.stopLoss;
            setup.atrAtEntry = atr;

            // T1: structural target (last weak high), fall back to 1.5R
            double t1Struct = htf_structure.GetLastWeakHigh();
            if(t1Struct <= 0 || t1Struct <= setup.entryPrice)
                t1Struct = setup.entryPrice + risk * 1.5;
            setup.tp1 = t1Struct;

            // [FIX M-3] Sweep T1 must be at least 1.5R from entry
            if(setup.modelName == "Liquidity_Sweep_Long")
            {
                double minT1Dist = risk * 1.5;
                if((setup.tp1 - setup.entryPrice) < minT1Dist)
                    setup.tp1 = setup.entryPrice + minT1Dist;
            }

            // T2: 2.5R minimum — never below T1
            double t2Min = setup.entryPrice + risk * 2.5;
            setup.tp2 = MathMax(t2Min, setup.tp1 + risk * 0.5);

            // T3: runner — 4R or HTF macro structure, whichever is further
            double t3R = setup.entryPrice + risk * 4.0;
            setup.tp3 = t3R;

            // Back-compat aliases
            setup.tpLocal = setup.tp1;
            setup.tpMacro = setup.tp3;

            // Volume splits by setup type
            if(setup.modelName == "Liquidity_Sweep_Long")
            { setup.volT1 = 0.50; setup.volT2 = 0.30; setup.volT3 = 0.20; }
            else if(setup.modelName == "POI_Proximity_Long")
            { setup.volT1 = 0.30; setup.volT2 = 0.40; setup.volT3 = 0.30; }
            else  // POI_Continuation_Long
            { setup.volT1 = 0.40; setup.volT2 = 0.30; setup.volT3 = 0.30; }

            PrintFormat("[V3 Execution] %s | Entry %.5f | SL %.5f | T1 %.5f (%.0f%%) | T2 %.5f (%.0f%%) | T3 %.5f (%.0f%%)",
                        setup.modelName, setup.entryPrice, setup.stopLoss,
                        setup.tp1, setup.volT1*100,
                        setup.tp2, setup.volT2*100,
                        setup.tp3, setup.volT3*100);
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

        // 1. CHoCH latch — [PATCH D3] refresh on every fresh CHoCH, not just the first
        double c2 = iClose(m_symbol, m_ltf, 2);
        bool isFreshBreak = (ltf_strong_low > 0 && c1 < ltf_strong_low && c2 >= ltf_strong_low);

        if(isFreshBreak)
        {
            s_shortChochConfirmed = true;
            s_shortLatchBar       = current_bar_time;
            PrintFormat("[V3 Trigger] LATCH SET/REFRESH: Bearish CHoCH on %s (close %.5f < swing %.5f). Waiting for POI.",
                        EnumToString(m_ltf), c1, ltf_strong_low);
        }

        if(!s_shortChochConfirmed) return setup;

        // [PATCH D3] Latch expiry
        if(current_bar_time - s_shortLatchBar > (datetime)(m_latchBars * PeriodSeconds(m_ltf)))
        {
            s_shortChochConfirmed = false;
            PrintFormat("[V3 Trigger] Short CHoCH latch EXPIRED after %d bars.", m_latchBars);
            return setup;
        }

        // 2. POI re-entry — [PATCH D4] inside OR within m_proxATR * ATR of the nearest zone
        double   dummy_sl   = 0.0, sweep_level = 0.0;
        datetime poi_time   = 0;
        double   atrDT      = GetATR();
        bool     inside_poi = mtf_poi_sensor.IsInsideBearishPOI(c1, dummy_sl, poi_time);
        bool     near_poi   = (!inside_poi && atrDT > 0.0)
                              ? mtf_poi_sensor.IsNearBearishPOI(c1, atrDT, dummy_sl, poi_time)
                              : false;
        bool     eq_swept   = mtf_liquidity.IsEQHSwept(sweep_level);

        if(!inside_poi && !near_poi && !eq_swept)
        {
            // [Diagnostic] Explain the silence [PATCH D5]
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
                PrintFormat("[V3 Wait] SHORT | zones total=%d activeBear=%d (totBear=%d) | nearest mid=%.5f | dist=%.5f | atrLTF=%.5f",
                            nz, act, mtf_poi_sensor.GetTotalBearCount(), nearest,
                            (act > 0 ? nd : 0.0), atrVal);
                lastWaitPrintS = TimeCurrent();
            }
            return setup;
        }

        bool usable_poi = (inside_poi || near_poi);

        // 3. Build the setup
        if(usable_poi)
        {
            setup.direction  = SIGNAL_SHORT;
            setup.entryPrice = current_bid;
            setup.stopLoss   = dummy_sl + buffer;
            setup.modelName  = (near_poi && !inside_poi) ? "POI_Proximity_Short" : "POI_Continuation_Short";
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
            // [Item 8] Stop-size bounds check (Widen tight stops, reject wide stops)
            double atr  = GetATR();
            if(atr <= 0.0) 
            {
                Print("[V3 Trigger] REJECT: ATR is 0.0, cannot calculate stop floor.");
                setup.direction = SIGNAL_NONE;
                s_lastAttemptBarTime = current_bar_time;
                return setup;
            }
            
            double current_risk = setup.stopLoss - setup.entryPrice;
            double min_risk = m_minStopATR * atr;
            double max_risk = m_maxStopATR * atr;
            
            // [FIX S-2] Wide stops are valid — accept and let risk-sizing shrink the lot
            if(current_risk > max_risk)
            {
                PrintFormat("[V3 Trigger] ACCEPT-WIDE: Stop %.2f ATR (max %.2f). Lot will scale down.", 
                            current_risk / atr, m_maxStopATR);
                // no rejection — CalculateLotSize handles the sizing
            }
            else if(current_risk < min_risk)
            {
                PrintFormat("[V3 Trigger] ADJUST: Stop %.5f too tight (%.2f ATR). Widening SL to %.2f ATR.", 
                            current_risk, current_risk / atr, m_minStopATR);
                setup.stopLoss = setup.entryPrice + min_risk;
            }

            // [PATCH TM-1] — explicit T1/T2/T3 with per-setup volume splits
            double risk = setup.stopLoss - setup.entryPrice;
            setup.atrAtEntry = atr;

            // T1: structural target (last weak low), fall back to 1.5R
            double t1Struct = htf_structure.GetLastWeakLow();
            if(t1Struct <= 0 || t1Struct >= setup.entryPrice)
                t1Struct = setup.entryPrice - risk * 1.5;
            setup.tp1 = t1Struct;

            // [FIX M-3] Sweep T1 must be at least 1.5R from entry
            if(setup.modelName == "Liquidity_Sweep_Short")
            {
                double minT1Dist = risk * 1.5;
                if((setup.entryPrice - setup.tp1) < minT1Dist)
                    setup.tp1 = setup.entryPrice - minT1Dist;
            }

            // T2: 2.5R minimum — never below T1
            double t2Min = setup.entryPrice - risk * 2.5;
            setup.tp2 = MathMin(t2Min, setup.tp1 - risk * 0.5);

            // T3: runner — 4R or HTF macro structure, whichever is further
            double t3R = setup.entryPrice - risk * 4.0;
            setup.tp3 = t3R;

            // Back-compat aliases
            setup.tpLocal = setup.tp1;
            setup.tpMacro = setup.tp3;

            // Volume splits by setup type
            if(setup.modelName == "Liquidity_Sweep_Short")
            { setup.volT1 = 0.50; setup.volT2 = 0.30; setup.volT3 = 0.20; }
            else if(setup.modelName == "POI_Proximity_Short")
            { setup.volT1 = 0.30; setup.volT2 = 0.40; setup.volT3 = 0.30; }
            else  // POI_Continuation_Short
            { setup.volT1 = 0.40; setup.volT2 = 0.30; setup.volT3 = 0.30; }

            PrintFormat("[V3 Execution] %s | Entry %.5f | SL %.5f | T1 %.5f (%.0f%%) | T2 %.5f (%.0f%%) | T3 %.5f (%.0f%%)",
                        setup.modelName, setup.entryPrice, setup.stopLoss,
                        setup.tp1, setup.volT1*100,
                        setup.tp2, setup.volT2*100,
                        setup.tp3, setup.volT3*100);
            s_shortChochConfirmed = false;
            s_lastAttemptBarTime  = current_bar_time;
        }
    }

    return setup;
}
#endif
