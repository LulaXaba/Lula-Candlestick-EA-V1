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
    int                 m_atrHandle;  // [Fix #4] persistent ATR handle

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
    : m_symbol(""), m_ltf(PERIOD_M5), m_atrHandle(INVALID_HANDLE) {}

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
    PrintFormat("[V3 Decision Tree] Initialized for %s (LTF: %s)", m_symbol, EnumToString(m_ltf));
    return true;
}

// [Fix #4] Use the cached handle; reads shift-1 (last fully closed LTF bar)
double C_DecisionTree::GetDynamicBuffer()
{
    if(m_atrHandle == INVALID_HANDLE) return 0.0;
    double atr[];
    if(CopyBuffer(m_atrHandle, 0, 1, 1, atr) > 0)
        return atr[0] * 0.5;  // 0.5x ATR for SL breathing room
    return 0.0;
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
        double ltf_strong_high = ltf_structure.GetLastStrongHigh();

        // 1. CHoCH latch — confirmed when CLOSED bar closes above the swing high
        if(!s_longChochConfirmed && ltf_strong_high > 0 && c1 > ltf_strong_high)
        {
            s_longChochConfirmed = true;
            PrintFormat("[V3 Trigger] LATCH SET: Bullish CHoCH on %s (close %.5f > swing %.5f). Waiting for POI.",
                        EnumToString(m_ltf), c1, ltf_strong_high);
        }

        if(!s_longChochConfirmed) return setup;

        // 2. POI re-entry — use closed bar price for containment check
        double   dummy_sl   = 0.0, sweep_level = 0.0;
        datetime poi_time   = 0;
        bool     inside_poi = mtf_poi_sensor.IsInsideBullishPOI(c1, dummy_sl, poi_time);
        bool     eq_swept   = mtf_liquidity.IsEQLSwept(sweep_level);

        if(!inside_poi && !eq_swept)
        {
            static datetime lastWaitPrint = 0;
            if(TimeCurrent() - lastWaitPrint >= 300)
            {
                PrintFormat("[V3 Trigger] CHoCH Latched. Waiting for close (%.5f) inside Green MTF Box.", c1);
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
        double ltf_strong_low = ltf_structure.GetLastStrongLow();

        // Trap override: if HTF is now Discount, invalidate
        if(htf_structure.PriceInDiscountZone(c1))
        {
            s_shortChochConfirmed = false;
            return setup;
        }

        // 1. CHoCH latch — confirmed when CLOSED bar closes below the swing low
        if(!s_shortChochConfirmed && ltf_strong_low > 0 && c1 < ltf_strong_low)
        {
            s_shortChochConfirmed = true;
            PrintFormat("[V3 Trigger] LATCH SET: Bearish CHoCH on %s (close %.5f < swing %.5f). Waiting for POI.",
                        EnumToString(m_ltf), c1, ltf_strong_low);
        }

        if(!s_shortChochConfirmed) return setup;

        // 2. POI re-entry — use closed bar price
        double   dummy_sl   = 0.0, sweep_level = 0.0;
        datetime poi_time   = 0;
        bool     inside_poi = mtf_poi_sensor.IsInsideBearishPOI(c1, dummy_sl, poi_time);
        bool     eq_swept   = mtf_liquidity.IsEQHSwept(sweep_level);

        if(!inside_poi && !eq_swept)
        {
            static datetime lastWaitPrintS = 0;
            if(TimeCurrent() - lastWaitPrintS >= 300)
            {
                PrintFormat("[V3 Trigger] CHoCH Latched. Waiting for close (%.5f) inside Red MTF Box.", c1);
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
