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
    
    if(current_state != STATE_LTF_ARMED_LONG && current_state != STATE_LTF_ARMED_SHORT)
        return setup; // EA is sleeping/searching. Do nothing.

    if(htf_structure == NULL || ltf_structure == NULL || mtf_poi_sensor == NULL || mtf_liquidity == NULL)
        return setup;

    double current_bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
    double current_ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
    double buffer = GetDynamicBuffer(PERIOD_M5); // Use LTF buffer for entries
    
    // ---------------------------------------------------------
    // GATE 4: LOWER TIME FRAME (LTF) TRIGGER EVALUATION
    // ---------------------------------------------------------
    
    if(current_state == STATE_LTF_ARMED_LONG)
    {
        // 1. Did the LTF print a Bullish CHoCH? (Broke above the last LTF Strong High)
        double ltf_strong_high = ltf_structure.GetLastStrongHigh();
        bool ltf_bullish_choch = (ltf_strong_high > 0 && current_bid > ltf_strong_high);
        
        if(!ltf_bullish_choch) return setup; // Still waiting for reversal confirmation
        
        // 2. Determine Which Model Fired
        double dummy_sl = 0.0, sweep_level = 0.0;
        
        if(mtf_poi_sensor.IsInsideBullishPOI(current_bid, dummy_sl))
        {
            // MODEL 1: Structural Continuation
            setup.direction = SIGNAL_LONG;
            setup.entryPrice = current_ask;
            setup.stopLoss   = dummy_sl - buffer; // Distal line of POI minus ATR buffer
            setup.modelName  = "POI_Continuation_Long";
        }
        else if(mtf_liquidity.IsEQLSwept(sweep_level))
        {
            // MODEL 2: Liquidity Sweep Reversal
            setup.direction = SIGNAL_LONG;
            setup.entryPrice = current_ask;
            // SL goes below the lowest point of the sweep to protect against further hunting
            setup.stopLoss   = sweep_level - buffer; 
            setup.modelName  = "Liquidity_Sweep_Long";
        }
        
        if(setup.direction == SIGNAL_LONG)
        {
            // Profit Maximizer Targets
            setup.tpLocal = htf_structure.GetLastWeakHigh(); // Ticket 1 targets the immediate Weak High
            setup.tpMacro = setup.tpLocal + (setup.tpLocal - setup.entryPrice); // Ticket 2 targets an extended 1:1 runner
            
            PrintFormat("[V3 Execution] %s Triggered! Entry: %.5f | SL: %.5f", setup.modelName, setup.entryPrice, setup.stopLoss);
        }
    }
    else if(current_state == STATE_LTF_ARMED_SHORT)
    {
        // 1. Did the LTF print a Bearish CHoCH? (Broke below the last LTF Strong Low)
        double ltf_strong_low = ltf_structure.GetLastStrongLow();
        bool ltf_bearish_choch = (ltf_strong_low > 0 && current_bid < ltf_strong_low);
        
        // TRAP OVERRIDE: If a bearish CHoCH happens while inside HTF Discount, IGNORE IT.
        if(htf_structure.PriceInDiscountZone(current_bid))
        {
            PrintFormat("[V3 Override] Bearish LTF CHoCH detected inside HTF Discount. Flagged as Sweep Trap. Ignored.");
            return setup; 
        }
        
        if(!ltf_bearish_choch) return setup; // Still waiting for reversal confirmation
        
        // 2. Determine Which Model Fired
        double dummy_sl = 0.0, sweep_level = 0.0;
        
        if(mtf_poi_sensor.IsInsideBearishPOI(current_bid, dummy_sl))
        {
            // MODEL 1: Structural Continuation
            setup.direction = SIGNAL_SHORT;
            setup.entryPrice = current_bid;
            setup.stopLoss   = dummy_sl + buffer; // Distal line of POI plus ATR buffer
            setup.modelName  = "POI_Continuation_Short";
        }
        else if(mtf_liquidity.IsEQHSwept(sweep_level))
        {
            // MODEL 2: Liquidity Sweep Reversal
            setup.direction = SIGNAL_SHORT;
            setup.entryPrice = current_bid;
            setup.stopLoss   = sweep_level + buffer; 
            setup.modelName  = "Liquidity_Sweep_Short";
        }
        
        if(setup.direction == SIGNAL_SHORT)
        {
            // Profit Maximizer Targets
            setup.tpLocal = htf_structure.GetLastWeakLow(); // Ticket 1 targets the immediate Weak Low
            setup.tpMacro = setup.tpLocal - (setup.entryPrice - setup.tpLocal); // Ticket 2 targets an extended runner
            
            PrintFormat("[V3 Execution] %s Triggered! Entry: %.5f | SL: %.5f", setup.modelName, setup.entryPrice, setup.stopLoss);
        }
    }

    return setup;
}
#endif
