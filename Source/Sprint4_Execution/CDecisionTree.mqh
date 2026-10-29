//+------------------------------------------------------------------+
//|                                             CDecisionTree.mqh    |
//|                             Lula Price Action Execution Engine V3|
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

// DTO for passing the exact coordinates to the Executor
struct STradeSetup
{
    ENUM_TRADE_SIGNAL direction;
    double            entryPrice;
    double            stopLoss;
    double            tpLocal;   // Ticket 1: MTF Target (Day Trade)
    double            tpMacro;   // Ticket 2: HTF Target (The Runner)
    string            modelName; // "POI_Continuation" or "Liquidity_Sweep"
};

class C_DecisionTree
{
private:
    string              m_symbol;
    
    // Dynamic Buffer for synthetic spreads (e.g. 1.5 * ATR for SL breathing room)
    double              GetDynamicBuffer(ENUM_TIMEFRAMES tf);

public:
                        C_DecisionTree();
                       ~C_DecisionTree();

    bool                Init(string symbol);
    
    // The core evaluation method
    STradeSetup         Evaluate(
                            ENUM_V3_STATE            current_state,
                            C_MarketStructureSensor  *htf_structure,
                            C_MarketStructureSensor  *ltf_structure, // To detect the LTF CHoCH
                            C_POI_Sensor             *mtf_poi_sensor,
                            C_LiquiditySensor        *mtf_liquidity
                        );
};

C_DecisionTree::C_DecisionTree() : m_symbol("") {}
C_DecisionTree::~C_DecisionTree() {}

bool C_DecisionTree::Init(string symbol)
{
    m_symbol = symbol;
    PrintFormat("[V3 Decision Tree] Initialized for %s", m_symbol);
    return true;
}

double C_DecisionTree::GetDynamicBuffer(ENUM_TIMEFRAMES tf)
{
    double atr[];
    int handle = iATR(m_symbol, tf, 14);
    if(handle == INVALID_HANDLE) return 0.0;
    double buffer = 0.0;
    if(CopyBuffer(handle, 0, 0, 1, atr) > 0)
    {
        buffer = atr[0] * 0.5; // 0.5x ATR buffer to avoid wick-outs
    }
    IndicatorRelease(handle);
    return buffer;
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
    
    if(current_state != STATE_LTF_ARMED_LONG && current_state != STATE_LTF_ARMED_SHORT &&
       current_state != STATE_LTF_WAIT_RETRACE_LONG && current_state != STATE_LTF_WAIT_RETRACE_SHORT)
        return setup; // EA is sleeping/searching. Do nothing.

    if(htf_structure == NULL || ltf_structure == NULL || mtf_poi_sensor == NULL || mtf_liquidity == NULL)
        return setup;

    double current_bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
    double current_ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
    double buffer = GetDynamicBuffer(PERIOD_M5); // Use LTF buffer for entries
    
    // ---------------------------------------------------------
    // GATE 4: LOWER TIME FRAME (LTF) TRIGGER EVALUATION
    // ---------------------------------------------------------
    
    // --- STATE TRACKING LATCHES ---
    // These static variables remember if the CHoCH happened, surviving tick-by-tick resets
    static bool s_longChochConfirmed = false;
    static bool s_shortChochConfirmed = false;

    // Reset latches if we are no longer in an active armed state
    if(current_state != STATE_LTF_ARMED_LONG && current_state != STATE_LTF_WAIT_RETRACE_LONG) 
        s_longChochConfirmed = false;
    if(current_state != STATE_LTF_ARMED_SHORT && current_state != STATE_LTF_WAIT_RETRACE_SHORT) 
        s_shortChochConfirmed = false;

    // --- LONG TRIGGER EVALUATION ---
    if(current_state == STATE_LTF_ARMED_LONG || current_state == STATE_LTF_WAIT_RETRACE_LONG)
    {
        double ltf_strong_high = ltf_structure.GetLastStrongHigh();
        
        // 1. Detect and Latch the CHoCH
        if(!s_longChochConfirmed && ltf_strong_high > 0 && current_bid > ltf_strong_high)
        {
            s_longChochConfirmed = true;
            PrintFormat("[V3 Trigger] LATCH SET: Bullish CHoCH confirmed on M5. Waiting for POI re-entry.");
        }
        
        if(!s_longChochConfirmed) return setup; // Still waiting for the rally
        
        // 2. The Retracement Latch (Wait for price to drop back into the MTF Order Block)
        double dummy_sl = 0.0, sweep_level = 0.0;
        bool inside_poi = mtf_poi_sensor.IsInsideBullishPOI(current_ask, dummy_sl); // Use ASK for buying
        bool eq_swept   = mtf_liquidity.IsEQLSwept(sweep_level);
        
        if(!inside_poi && !eq_swept) {
            static datetime lastWaitPrint = 0;
            if(TimeCurrent() - lastWaitPrint >= 300) {
                PrintFormat("[V3 Trigger] CHoCH Latched. Waiting for price (%.5f) to drop back into Green MTF Box.", current_ask);
                lastWaitPrint = TimeCurrent();
            }
            return setup;
        }
        
        // 3. Execute
        if(inside_poi)
        {
            setup.direction = SIGNAL_LONG;
            setup.entryPrice = current_ask;
            setup.stopLoss   = dummy_sl - buffer; 
            setup.modelName  = "POI_Continuation_Long";
        }
        else if(eq_swept)
        {
            setup.direction = SIGNAL_LONG;
            setup.entryPrice = current_ask;
            setup.stopLoss   = sweep_level - buffer; 
            setup.modelName  = "Liquidity_Sweep_Long";
        }
        
        if(setup.direction == SIGNAL_LONG)
        {
            setup.tpLocal = htf_structure.GetLastWeakHigh(); 
            if(setup.tpLocal <= setup.entryPrice) {
                double risk_points = setup.entryPrice - setup.stopLoss;
                setup.tpLocal = setup.entryPrice + (risk_points * 2.0);
            }
            setup.tpMacro = setup.tpLocal + (setup.tpLocal - setup.entryPrice); 
            
            PrintFormat("[V3 Execution] %s Fired on POI Re-entry! Entry: %.5f | SL: %.5f", setup.modelName, setup.entryPrice, setup.stopLoss);
            s_longChochConfirmed = false; // Reset latch after firing
        }
    }
    
    // --- SHORT TRIGGER EVALUATION ---
    else if(current_state == STATE_LTF_ARMED_SHORT || current_state == STATE_LTF_WAIT_RETRACE_SHORT)
    {
        double ltf_strong_low = ltf_structure.GetLastStrongLow();
        
        // Trap override: If H4 shifts to Discount, invalidate the setup
        if(htf_structure.PriceInDiscountZone(current_bid)) {
            s_shortChochConfirmed = false;
            return setup; 
        }
        
        // 1. Detect and Latch the CHoCH
        if(!s_shortChochConfirmed && ltf_strong_low > 0 && current_bid < ltf_strong_low)
        {
            s_shortChochConfirmed = true;
            PrintFormat("[V3 Trigger] LATCH SET: Bearish CHoCH confirmed on M5. Waiting for POI re-entry.");
        }
        
        if(!s_shortChochConfirmed) return setup; 
        
        // 2. The Retracement Latch (Wait for price to rally back into the MTF Order Block)
        double dummy_sl = 0.0, sweep_level = 0.0;
        bool inside_poi = mtf_poi_sensor.IsInsideBearishPOI(current_bid, dummy_sl); // Use BID for selling
        bool eq_swept   = mtf_liquidity.IsEQHSwept(sweep_level);
        
        if(!inside_poi && !eq_swept) {
            static datetime lastWaitPrintS = 0;
            if(TimeCurrent() - lastWaitPrintS >= 300) {
                PrintFormat("[V3 Trigger] CHoCH Latched. Waiting for price (%.5f) to rally back into Red MTF Box.", current_bid);
                lastWaitPrintS = TimeCurrent();
            }
            return setup;
        }
        
        // 3. Execute
        if(inside_poi)
        {
            setup.direction = SIGNAL_SHORT;
            setup.entryPrice = current_bid;
            setup.stopLoss   = dummy_sl + buffer; 
            setup.modelName  = "POI_Continuation_Short";
        }
        else if(eq_swept)
        {
            setup.direction = SIGNAL_SHORT;
            setup.entryPrice = current_bid;
            setup.stopLoss   = sweep_level + buffer; 
            setup.modelName  = "Liquidity_Sweep_Short";
        }
        
        if(setup.direction == SIGNAL_SHORT)
        {
            setup.tpLocal = htf_structure.GetLastWeakLow(); 
            if(setup.tpLocal >= setup.entryPrice || setup.tpLocal == 0) {
                double risk_points = setup.stopLoss - setup.entryPrice;
                setup.tpLocal = setup.entryPrice - (risk_points * 2.0);
            }
            setup.tpMacro = setup.tpLocal - (setup.entryPrice - setup.tpLocal); 
            
            PrintFormat("[V3 Execution] %s Fired on POI Re-entry! Entry: %.5f | SL: %.5f", setup.modelName, setup.entryPrice, setup.stopLoss);
            s_shortChochConfirmed = false; // Reset latch after firing
        }
    }

    return setup;
}
#endif
