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
    
    void                EvaluateInstitutionalStrength();

public:
                        C_MarketStructureSensor();
                       ~C_MarketStructureSensor();

    bool                Init(string symbol);
    
    // Feed the perfected V2 ZigZag engine into the V3 Sensor
    void                Update(CZigZagEngine *zigzag_engine);

    bool                PriceInDiscountZone(double current_price);
    bool                PriceInPremiumZone(double current_price);
    ENUM_MACRO_PHASE    GetMacroPhase();
    
    double              GetLastStrongLow()  { return m_lastStrongLow; }
    double              GetLastStrongHigh() { return m_lastStrongHigh; }
    double              GetLastWeakHigh()   { return m_lastWeakHigh; }
    double              GetLastWeakLow()    { return m_lastWeakLow; }
};

C_MarketStructureSensor::C_MarketStructureSensor() : m_symbol(""), 
                                                     m_lastStrongLow(0), m_lastWeakHigh(0), 
                                                     m_lastStrongHigh(0), m_lastWeakLow(0) {}

C_MarketStructureSensor::~C_MarketStructureSensor() {}

bool C_MarketStructureSensor::Init(string symbol)
{
    m_symbol = symbol;
    ArrayResize(m_nodes, 0);
    PrintFormat("[V3 Sensor] Market Structure Initialized: %s", m_symbol);
    return true;
}

void C_MarketStructureSensor::Update(CZigZagEngine *zigzag_engine)
{
    if(zigzag_engine == NULL) return;
    
    // 1. Ingest nodes from your existing V2 ZigZag Engine
    int total_zz_nodes = zigzag_engine.GetNodeCount(); 
    if(total_zz_nodes < 3) return;
    
    ArrayResize(m_nodes, total_zz_nodes);
    
    // We reverse the array to evaluate from oldest (0) to newest (total-1)
    for(int i = 0; i < total_zz_nodes; i++)
    {
        int chrono_idx = total_zz_nodes - 1 - i;
        m_nodes[chrono_idx].time   = zigzag_engine.GetNodeTime(i); // Assuming these accessors exist
        m_nodes[chrono_idx].price  = zigzag_engine.GetNodePrice(i);
        m_nodes[chrono_idx].isHigh = zigzag_engine.IsNodeHigh(i);
        m_nodes[chrono_idx].isStrong = false;
        m_nodes[chrono_idx].isWeak   = false;
    }
    
    // 2. Apply V3 SMC logic ON TOP of the V2 ZigZag array
    EvaluateInstitutionalStrength();
}

void C_MarketStructureSensor::EvaluateInstitutionalStrength()
{
    int total = ArraySize(m_nodes);
    
    for(int i = 2; i < total; i++)
    {
        if(m_nodes[i].isHigh)
        {
            if(m_nodes[i].price <= m_nodes[i-2].price) 
            {
                m_nodes[i].isWeak = true;
                m_lastWeakHigh = m_nodes[i].price;
            }
            if(i >= 3 && m_nodes[i].price < m_nodes[i-3].price) 
            {
                m_nodes[i-1].isStrong = true; 
                m_lastStrongHigh = m_nodes[i-1].price;
            }
        }
        else 
        {
            if(m_nodes[i].price >= m_nodes[i-2].price)
            {
                m_nodes[i].isWeak = true;
                m_lastWeakLow = m_nodes[i].price;
            }
            if(i >= 3 && m_nodes[i].price > m_nodes[i-3].price)
            {
                m_nodes[i-1].isStrong = true; 
                m_lastStrongLow = m_nodes[i-1].price;
            }
        }
    }
    
    double current_price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
    
    // Chain Reaction Invalidation
    if(m_lastStrongLow > 0 && current_price < m_lastStrongLow)
    {
        m_lastStrongLow = 0; 
        m_lastWeakHigh = 0; 
    }
    
    if(m_lastStrongHigh > 0 && current_price > m_lastStrongHigh)
    {
         m_lastStrongHigh = 0; 
         m_lastWeakLow = 0; 
    }
}

bool C_MarketStructureSensor::PriceInDiscountZone(double current_price)
{
    if(m_lastStrongLow == 0 || m_lastWeakHigh == 0) return false;
    double equilibrium = m_lastStrongLow + ((m_lastWeakHigh - m_lastStrongLow) / 2.0);
    return current_price <= equilibrium; 
}

bool C_MarketStructureSensor::PriceInPremiumZone(double current_price)
{
    if(m_lastStrongHigh == 0 || m_lastWeakLow == 0) return false;
    double equilibrium = m_lastWeakLow + ((m_lastStrongHigh - m_lastWeakLow) / 2.0);
    return current_price >= equilibrium; 
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
