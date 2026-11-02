//+------------------------------------------------------------------+
//|                                              CStateMachine.mqh   |
//|                             Lula Price Action Execution Engine V3|
//+------------------------------------------------------------------+
#ifndef C_STATEMACHINE_MQH
#define C_STATEMACHINE_MQH

#include "../Sprint1_Sensors/C_MarketStructureSensor.mqh"
#include "../Sprint1_Sensors/C_POI_Sensor.mqh"
#include "../Sprint1_Sensors/C_LiquiditySensor.mqh"
#include "../Sprint1_Sensors/CZigZagEngine.mqh"

enum ENUM_V3_STATE
{
    STATE_HTF_NARRATIVE,    
    STATE_MTF_POI_SEARCH,   
    STATE_LTF_ARMED_LONG,   
    STATE_LTF_WAIT_RETRACE_LONG, // NEW: CHoCH confirmed, waiting for LTF Discount
    STATE_LTF_ARMED_SHORT,  
    STATE_LTF_WAIT_RETRACE_SHORT,// NEW: CHoCH confirmed, waiting for LTF Premium
    STATE_STANDBY           
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
    datetime            m_armedBar;      // [Item 6] bar time when state was armed; holds for 24 LTF bars
    
    bool                IsNewBar(ENUM_TIMEFRAMES tf, datetime &last_time);

public:
                        C_StateMachine();
                       ~C_StateMachine();

    bool                Init(string symbol, ENUM_TIMEFRAMES htf, ENUM_TIMEFRAMES mtf, ENUM_TIMEFRAMES ltf);
    
    // The core traffic controller. Returns the active state to the main EA.
    ENUM_V3_STATE       UpdateAndRoute(
                            C_MarketStructureSensor *htf_structure,
                            C_POI_Sensor            *mtf_poi_sensor,
                            C_LiquiditySensor       *mtf_liquidity,
                            CZigZagEngine           *htf_zigzag,
                            CZigZagEngine           *mtf_zigzag
                        );

    ENUM_V3_STATE       GetCurrentState() { return m_currentState; }
};

C_StateMachine::C_StateMachine() : m_symbol(""), m_currentState(STATE_HTF_NARRATIVE), 
                                   m_lastHtfTime(0), m_lastMtfTime(0), m_armedBar(0) {}

C_StateMachine::~C_StateMachine() {}

bool C_StateMachine::Init(string symbol, ENUM_TIMEFRAMES htf, ENUM_TIMEFRAMES mtf, ENUM_TIMEFRAMES ltf)
{
    m_symbol = symbol;
    m_htf = htf;
    m_mtf = mtf;
    m_ltf = ltf;
    m_armedBar = 0;
    
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
                            C_POI_Sensor            *mtf_poi_sensor,
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
        if(mtf_poi_sensor != NULL)
            mtf_poi_sensor.Update(); // Evaluates mitigation
        if(mtf_liquidity != NULL && mtf_zigzag != NULL)
            mtf_liquidity.Update(mtf_zigzag); // Scans for equal highs/lows
    }

    // [Item 6] Closed-bar arming: arm on the last closed LTF bar, never live tick
    double c1 = iClose(m_symbol, m_ltf, 1);
    if(c1 <= 0.0) return m_currentState;

    datetime ltf_bar   = iTime(m_symbol, m_ltf, 0);
    const int HOLD_BARS = 24; // Hold armed state for 24 LTF bars unless trend flips

    int trend = (htf_structure != NULL) ? htf_structure.GetTrendDirection() : 0;

    // Check existing armed state: cancel on trend flip or expiry
    if(m_currentState == STATE_LTF_ARMED_LONG)
    {
        if(trend != 1)
        {
            m_currentState = STATE_MTF_POI_SEARCH;
            m_armedBar     = 0;
            PrintFormat("[V3 State Machine] Long armed state CANCELLED: trend flipped (trend=%d).", trend);
        }
        else if(ltf_bar > 0 && m_armedBar > 0 && (ltf_bar - m_armedBar) > (datetime)(HOLD_BARS * PeriodSeconds(m_ltf)))
        {
            m_currentState = STATE_MTF_POI_SEARCH;
            m_armedBar     = 0;
            PrintFormat("[V3 State Machine] Long armed state EXPIRED after %d bars.", HOLD_BARS);
        }
    }
    else if(m_currentState == STATE_LTF_ARMED_SHORT)
    {
        if(trend != -1)
        {
            m_currentState = STATE_MTF_POI_SEARCH;
            m_armedBar     = 0;
            PrintFormat("[V3 State Machine] Short armed state CANCELLED: trend flipped (trend=%d).", trend);
        }
        else if(ltf_bar > 0 && m_armedBar > 0 && (ltf_bar - m_armedBar) > (datetime)(HOLD_BARS * PeriodSeconds(m_ltf)))
        {
            m_currentState = STATE_MTF_POI_SEARCH;
            m_armedBar     = 0;
            PrintFormat("[V3 State Machine] Short armed state EXPIRED after %d bars.", HOLD_BARS);
        }
    }

    double dummy_sl    = 0.0;
    double sweep_level = 0.0;

    // 2. State Evaluation: The Macro Hierarchy (evaluated on closed bar c1)
    bool inDiscount = (htf_structure != NULL) ? htf_structure.PriceInDiscountZone(c1) : false;
    bool inPremium  = (htf_structure != NULL) ? htf_structure.PriceInPremiumZone(c1)  : false;

    static datetime lastPrint = 0;
    if(TimeCurrent() - lastPrint >= 3600) {
        string trendStr = (trend == 1) ? "BULLISH" : (trend == -1 ? "BEARISH" : "RANGING");
        PrintFormat("[V3 State] Close(1): %.5f | Trend: %s | HTF Discount: %s | HTF Premium: %s",
                    c1, trendStr, inDiscount ? "YES" : "NO", inPremium ? "YES" : "NO");
        lastPrint = TimeCurrent();
    }

    // --- LONG EVALUATION ---
    if(trend == 1)
    {
        bool inBullishPOI = (mtf_poi_sensor != NULL) && mtf_poi_sensor.IsInsideBullishPOI(c1, dummy_sl);
        bool eqlSwept     = (mtf_liquidity != NULL)  && mtf_liquidity.IsEQLSwept(sweep_level);
        
        // Arm M5 if closed price hits Discount, OR hits an Order Block, OR sweeps Liquidity
        if(inDiscount || inBullishPOI || eqlSwept)
        {
            if(m_currentState != STATE_LTF_ARMED_LONG)
                PrintFormat("[V3 State Machine] %s BULLISH Trend + Opportunity Found. Arming %s for Long Triggers.",
                            EnumToString(m_htf), EnumToString(m_ltf));
            m_currentState = STATE_LTF_ARMED_LONG;
            m_armedBar     = ltf_bar;
            return m_currentState;
        }
    }
    
    // --- SHORT EVALUATION ---
    if(trend == -1)
    {
        bool inBearishPOI = (mtf_poi_sensor != NULL) && mtf_poi_sensor.IsInsideBearishPOI(c1, dummy_sl);
        bool eqhSwept     = (mtf_liquidity != NULL)  && mtf_liquidity.IsEQHSwept(sweep_level);
        
        // Arm M5 if closed price hits Premium, OR hits an Order Block, OR sweeps Liquidity
        if(inPremium || inBearishPOI || eqhSwept)
        {
            if(m_currentState != STATE_LTF_ARMED_SHORT)
                PrintFormat("[V3 State Machine] %s BEARISH Trend + Opportunity Found. Arming %s for Short Triggers.",
                            EnumToString(m_htf), EnumToString(m_ltf));
            m_currentState = STATE_LTF_ARMED_SHORT;
            m_armedBar     = ltf_bar;
            return m_currentState;
        }
    }

    // If still within active armed hold window, maintain armed state
    if(m_currentState == STATE_LTF_ARMED_LONG || m_currentState == STATE_LTF_ARMED_SHORT)
        return m_currentState;

    // Default Fallback
    m_currentState = STATE_MTF_POI_SEARCH;
    return m_currentState;
}
#endif
