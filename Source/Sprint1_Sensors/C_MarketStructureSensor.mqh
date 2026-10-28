//+------------------------------------------------------------------+
//|                                     C_MarketStructureSensor.mqh  |
//|                             Lula Price Action Execution Engine V3|
//+------------------------------------------------------------------+
#ifndef C_MARKETSTRUCTURESENSOR_MQH
#define C_MARKETSTRUCTURESENSOR_MQH

#include "CZigZagEngine.mqh" // Inheriting your existing V2 engine

enum ENUM_MACRO_PHASE
{
    PHASE_IMPULSE_EXPECTED,
    PHASE_PULLBACK_EXPECTED,
    PHASE_UNKNOWN
};

struct SStructureNode
{
    datetime time;
    double   price;
    bool     isHigh;
    bool     isStrong; 
    bool     isWeak;   
};

class C_MarketStructureSensor
{
private:
    string              m_symbol;
    SStructureNode      m_nodes[];
    
    // Structural Extremes
    double              m_lastStrongLow;
    double              m_lastWeakHigh;
    double              m_lastStrongHigh;
    double              m_lastWeakLow;
    int                 m_trendDirection; // 1 = Bullish, -1 = Bearish, 0 = Ranging
    ENUM_TIMEFRAMES     m_tf;
    double              m_pullbackPct;    // Minimum pullback percentage (e.g. 30.0)
    
    void                EvaluateInstitutionalStrength();

public:
                        C_MarketStructureSensor();
                       ~C_MarketStructureSensor();

    bool                Init(string symbol, ENUM_TIMEFRAMES tf = PERIOD_CURRENT, double min_pullback = 30.0);
    
    // Feed the perfected V2 ZigZag engine into the V3 Sensor
    void                Update(CZigZagEngine *zigzag_engine);

    bool                PriceInDiscountZone(double current_price);
    bool                PriceInPremiumZone(double current_price);
    ENUM_MACRO_PHASE    GetMacroPhase();
    
    int                 GetTrendDirection() { return m_trendDirection; }
    double              GetLastStrongLow()  { return m_lastStrongLow; }
    double              GetLastStrongHigh() { return m_lastStrongHigh; }
    double              GetLastWeakHigh()   { return m_lastWeakHigh; }
    double              GetLastWeakLow()    { return m_lastWeakLow; }

    double GetDiscountThreshold() {
        if(m_lastStrongLow == 0 || m_lastWeakHigh == 0) return 0;
        return m_lastWeakHigh - ((m_lastWeakHigh - m_lastStrongLow) * (m_pullbackPct / 100.0));
    }
    double GetPremiumThreshold() {
        if(m_lastStrongHigh == 0 || m_lastWeakLow == 0) return 0;
        return m_lastWeakLow + ((m_lastStrongHigh - m_lastWeakLow) * (m_pullbackPct / 100.0));
    }
};

C_MarketStructureSensor::C_MarketStructureSensor() : m_symbol(""), 
                                                     m_lastStrongLow(0), m_lastWeakHigh(0), 
                                                     m_lastStrongHigh(0), m_lastWeakLow(0),
                                                     m_trendDirection(0), m_tf(PERIOD_CURRENT),
                                                     m_pullbackPct(30.0) {}

C_MarketStructureSensor::~C_MarketStructureSensor() {}

bool C_MarketStructureSensor::Init(string symbol, ENUM_TIMEFRAMES tf, double min_pullback)
{
    m_symbol = symbol;
    m_tf = tf;
    m_pullbackPct = min_pullback;
    m_trendDirection = 0;
    ArrayResize(m_nodes, 0);
    PrintFormat("[V3 Sensor] Market Structure Initialized: %s (TF: %s, Pullback: %.1f%%)", 
                m_symbol, EnumToString(m_tf), m_pullbackPct);
    return true;
}

void C_MarketStructureSensor::Update(CZigZagEngine *zigzag_engine) {
    if(zigzag_engine == NULL) return;
    int total_zz_nodes = zigzag_engine.GetNodeCount();
    int valid_nodes = total_zz_nodes - 1;
    if(valid_nodes < 2) return;
    
    ArrayResize(m_nodes, valid_nodes);
    
    // START AT INDEX 1: Ignore node 0 because it repaints until locked
    for(int i = 1; i < total_zz_nodes; i++) {
        m_nodes[i-1].price = zigzag_engine.GetNodePrice(i);
        m_nodes[i-1].time  = zigzag_engine.GetNodeTime(i);
        m_nodes[i-1].isHigh = zigzag_engine.IsNodeHigh(i);
        m_nodes[i-1].isStrong = false;
    }
    EvaluateInstitutionalStrength();
}

void C_MarketStructureSensor::EvaluateInstitutionalStrength() {
    int total = ArraySize(m_nodes);
    m_lastStrongLow = 0; m_lastStrongHigh = 0;
    m_lastWeakHigh = 0; m_lastWeakLow = 0;
    
    if(total < 3) return;

    // 1. Find the absolute most recent locked High and Low (These are the active "Weak" targets)
    for(int i = 0; i < total; i++) {
        if(m_nodes[i].isHigh && m_lastWeakHigh == 0) m_lastWeakHigh = m_nodes[i].price;
        if(!m_nodes[i].isHigh && m_lastWeakLow == 0) m_lastWeakLow = m_nodes[i].price;
        if(m_lastWeakHigh != 0 && m_lastWeakLow != 0) break;
    }

    // 2. Scan historical nodes for Break of Structure (BOS) to lock in Strong Pivots
    for(int i = 2; i < total; i++) {
        if(m_nodes[i].isHigh) {
            // Bullish BOS: Newer High (i-2) breaks above Older High (i)
            if(m_nodes[i-2].price > m_nodes[i].price) {
                m_nodes[i-1].isStrong = true; 
                if(m_lastStrongLow == 0) { // Only grab the most recent one
                    m_lastStrongLow = m_nodes[i-1].price;
                    m_trendDirection = 1; // BULLISH
                }
            }
        } else {
            // Bearish BOS: Newer Low (i-2) breaks below Older Low (i)
            if(m_nodes[i-2].price < m_nodes[i].price) {
                m_nodes[i-1].isStrong = true; 
                if(m_lastStrongHigh == 0) {
                    m_lastStrongHigh = m_nodes[i-1].price;
                    m_trendDirection = -1; // BEARISH
                }
            }
        }
    }
    
    // --- Dealing Range Fallback ---
    if(m_lastStrongLow == 0 || m_lastStrongHigh == 0) {
        double max_high = 0, min_low = 99999999;
        for(int k = 0; k < total; k++) {
            if(m_nodes[k].isHigh && m_nodes[k].price > max_high) max_high = m_nodes[k].price;
            if(!m_nodes[k].isHigh && m_nodes[k].price < min_low) min_low = m_nodes[k].price;
        }
        if(m_lastStrongLow == 0) m_lastStrongLow = min_low;
        if(m_lastStrongHigh == 0) m_lastStrongHigh = max_high;
    }
}

bool C_MarketStructureSensor::PriceInDiscountZone(double current_price)
{
    if(m_lastStrongLow == 0 || m_lastWeakHigh == 0) return false;
    double range = m_lastWeakHigh - m_lastStrongLow;
    if(range <= 0) return false; // Safety check
    
    double threshold = m_lastWeakHigh - (range * (m_pullbackPct / 100.0));
    return current_price <= threshold; 
}

bool C_MarketStructureSensor::PriceInPremiumZone(double current_price)
{
    if(m_lastStrongHigh == 0 || m_lastWeakLow == 0) return false;
    double range = m_lastStrongHigh - m_lastWeakLow;
    if(range <= 0) return false; // Safety check
    
    double threshold = m_lastWeakLow + (range * (m_pullbackPct / 100.0));
    return current_price >= threshold; 
}

ENUM_MACRO_PHASE C_MarketStructureSensor::GetMacroPhase()
{
    int total = ArraySize(m_nodes);
    if(total < 1) return PHASE_UNKNOWN;
    
    if(m_nodes[total-1].isHigh && m_nodes[total-1].isWeak) return PHASE_PULLBACK_EXPECTED;
    if(!m_nodes[total-1].isHigh && m_nodes[total-1].isWeak) return PHASE_PULLBACK_EXPECTED;
        
    return PHASE_IMPULSE_EXPECTED;
}
#endif
