//+------------------------------------------------------------------+
//|                                              CStateMachine.mqh   |
//|                             Lula Price Action Execution Engine V3|
//+------------------------------------------------------------------+
#ifndef C_STATEMACHINE_MQH
#define C_STATEMACHINE_MQH

#include "../Sprint1_Sensors/C_MarketStructureSensor.mqh"
#include "../Sprint1_Sensors/C_OrderBlockSensor.mqh"
#include "../Sprint1_Sensors/C_LiquiditySensor.mqh"
#include "../Sprint1_Sensors/CZigZagEngine.mqh"

enum ENUM_V3_STATE
{
    STATE_HTF_NARRATIVE,    // 1. Determining macro trend and PD ranges
    STATE_MTF_POI_SEARCH,   // 2. Waiting for price to reach a valid MTF POI
    STATE_LTF_ARMED_LONG,   // 3. Price is in Discount POI; LTF is awake scanning for Longs
    STATE_LTF_ARMED_SHORT,  // 4. Price is in Premium POI; LTF is awake scanning for Shorts
    STATE_STANDBY           // 5. Conflicting conditions, EA goes to sleep
};

class C_StateMachine
{
private:
    string              m_symbol;
    ENUM_TIMEFRAMES     m_htf;
    ENUM_TIMEFRAMES     m_mtf;
    ENUM_TIMEFRAMES     m_ltf;
    
    ENUM_V3_STATE       m_currentState;
    
    // Bar tracking to prevent array CPU overload (MQL5 Strategy Tester bottleneck)
    datetime            m_lastHtfTime;
    datetime            m_lastMtfTime;
    
    bool                IsNewBar(ENUM_TIMEFRAMES tf, datetime &last_time);

public:
                        C_StateMachine();
                       ~C_StateMachine();

    bool                Init(string symbol, ENUM_TIMEFRAMES htf, ENUM_TIMEFRAMES mtf, ENUM_TIMEFRAMES ltf);
    
    // The core traffic controller. Returns the active state to the main EA.
    ENUM_V3_STATE       UpdateAndRoute(
                            C_MarketStructureSensor *htf_structure,
                            C_OrderBlockSensor      *mtf_ob_sensor,
                            C_LiquiditySensor       *mtf_liquidity,
                            CZigZagEngine           *htf_zigzag,
                            CZigZagEngine           *mtf_zigzag
                        );

    ENUM_V3_STATE       GetCurrentState() { return m_currentState; }
};

C_StateMachine::C_StateMachine() : m_symbol(""), m_currentState(STATE_HTF_NARRATIVE), 
                                   m_lastHtfTime(0), m_lastMtfTime(0) {}

C_StateMachine::~C_StateMachine() {}

bool C_StateMachine::Init(string symbol, ENUM_TIMEFRAMES htf, ENUM_TIMEFRAMES mtf, ENUM_TIMEFRAMES ltf)
{
    m_symbol = symbol;
    m_htf = htf;
    m_mtf = mtf;
    m_ltf = ltf;
    
    m_currentState = STATE_HTF_NARRATIVE;
    PrintFormat("[V3 State Machine] Initialized. HTF: %s | MTF: %s | LTF: %s", 
                EnumToString(m_htf), EnumToString(m_mtf), EnumToString(m_ltf));
    return true;
}

bool C_StateMachine::IsNewBar(ENUM_TIMEFRAMES tf, datetime &last_time)
{
    datetime currentTime = iTime(m_symbol, tf, 0);
    if(currentTime != last_time)
    {
        last_time = currentTime;
        return true;
    }
    return false;
}

ENUM_V3_STATE C_StateMachine::UpdateAndRoute(
                            C_MarketStructureSensor *htf_structure,
                            C_OrderBlockSensor      *mtf_ob_sensor,
                            C_LiquiditySensor       *mtf_liquidity,
                            CZigZagEngine           *htf_zigzag,
                            CZigZagEngine           *mtf_zigzag)
{
    // 1. Throttle CPU: Only update Macro Sensors when a new HTF/MTF bar opens
    if(IsNewBar(m_htf, m_lastHtfTime))
    {
        if(htf_zigzag != NULL)
        {
            htf_zigzag.Update(); // Update HTF ZigZag
            if(htf_structure != NULL)
                htf_structure.Update(htf_zigzag);
        }
    }
    
    if(IsNewBar(m_mtf, m_lastMtfTime))
    {
        if(mtf_zigzag != NULL)
            mtf_zigzag.Update();
        if(mtf_ob_sensor != NULL)
            mtf_ob_sensor.Update(); // Evaluates mitigation
        if(mtf_liquidity != NULL && mtf_zigzag != NULL)
            mtf_liquidity.Update(mtf_zigzag); // Scans for equal highs/lows
    }

    double current_price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
    double dummy_sl = 0.0;
    double sweep_level = 0.0;

    // 2. State Evaluation: The Macro Hierarchy
    
    // Evaluate HTF Premium/Discount Status
    bool inDiscount = (htf_structure != NULL) ? htf_structure.PriceInDiscountZone(current_price) : false;
    bool inPremium  = (htf_structure != NULL) ? htf_structure.PriceInPremiumZone(current_price) : false;

    static datetime lastPrint = 0;
    if(current_price != 0 && TimeCurrent() - lastPrint >= 3600) {
        PrintFormat("[V3 State] Price: %.5f | HTF Discount: %s | HTF Premium: %s", current_price, inDiscount?"YES":"NO", inPremium?"YES":"NO");
        lastPrint = TimeCurrent();
    }

    // If price is nowhere near an institutional zone, drop to search mode
    if(!inDiscount && !inPremium) 
    {
        m_currentState = STATE_MTF_POI_SEARCH;
        return m_currentState;
    }

    // 3. POI Proximity & Ghost Zone Prevention
    // Ensure we are inside a valid MTF POI before waking up the LTF
    
    // --- LONG EVALUATION (Model 1 & Model 2) ---
    if(inDiscount)
    {
        bool inBullishOB = (mtf_ob_sensor != NULL) && mtf_ob_sensor.IsInsideBullishOB(current_price, dummy_sl);
        bool eqlSwept    = (mtf_liquidity != NULL) && mtf_liquidity.IsEQLSwept(sweep_level);
        
        if(inBullishOB || eqlSwept)
        {
            // Price is in HTF Discount AND tapping an MTF POI. Wake up the LTF!
            if(m_currentState != STATE_LTF_ARMED_LONG)
                PrintFormat("[V3 State Machine] HTF Discount POI Tapped. Arming LTF for Long Triggers.");
                
            m_currentState = STATE_LTF_ARMED_LONG;
            return m_currentState;
        }
    }
    
    // --- SHORT EVALUATION (Model 1 & Model 2) ---
    if(inPremium)
    {
        bool inBearishOB = (mtf_ob_sensor != NULL) && mtf_ob_sensor.IsInsideBearishOB(current_price, dummy_sl);
        bool eqhSwept    = (mtf_liquidity != NULL) && mtf_liquidity.IsEQHSwept(sweep_level);
        
        if(inBearishOB || eqhSwept)
        {
            // Price is in HTF Premium AND tapping an MTF POI. Wake up the LTF!
            if(m_currentState != STATE_LTF_ARMED_SHORT)
                PrintFormat("[V3 State Machine] HTF Premium POI Tapped. Arming LTF for Short Triggers.");
                
            m_currentState = STATE_LTF_ARMED_SHORT;
            return m_currentState;
        }
    }

    // Default Fallback
    m_currentState = STATE_MTF_POI_SEARCH;
    return m_currentState;
}
#endif
