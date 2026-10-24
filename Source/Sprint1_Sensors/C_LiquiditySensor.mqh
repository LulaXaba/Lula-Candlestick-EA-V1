//+------------------------------------------------------------------+
//|                                         C_LiquiditySensor.mqh    |
//|                             Lula Price Action Execution Engine V3|
//+------------------------------------------------------------------+
#ifndef C_LIQUIDITYSENSOR_MQH
#define C_LIQUIDITYSENSOR_MQH

#include "CZigZagEngine.mqh"
#include "..\Include\SymbolProfile.mqh"

struct SLiquidityPool
{
    bool     isActive;
    bool     isEQH;        // true = Equal Highs, false = Equal Lows
    double   level;        // The price boundary of the liquidity pool
    datetime timeFormed;
    bool     isSwept;      // Becomes true when a wick pierces the level but body closes inside
};

class C_LiquiditySensor
{
private:
    string              m_symbol;
    ENUM_TIMEFRAMES     m_tf;
    SLiquidityPool      m_pools[];
    
    double              m_atrTolerance; 
    
    double              GetATR(int period);
    void                DetectPools(CZigZagEngine *zigzag_engine);
    void                CheckForSweeps();

public:
                        C_LiquiditySensor();
                       ~C_LiquiditySensor();

    bool                Init(string symbol, ENUM_TIMEFRAMES tf);
    void                Update(CZigZagEngine *zigzag_engine);
    
    // Accessors for Decision Tree Execution
    bool                IsEQHSwept(double &sweep_level);
    bool                IsEQLSwept(double &sweep_level);
};

C_LiquiditySensor::C_LiquiditySensor() : m_symbol(""), m_tf(PERIOD_CURRENT), m_atrTolerance(0.0) {}
C_LiquiditySensor::~C_LiquiditySensor() {}

bool C_LiquiditySensor::Init(string symbol, ENUM_TIMEFRAMES tf)
{
    m_symbol = symbol;
    m_tf = tf;
    ArrayResize(m_pools, 0);
    PrintFormat("[V3 Sensor] Liquidity Sensor Initialized: %s", m_symbol);
    return true;
}

void C_LiquiditySensor::Update(CZigZagEngine *zigzag_engine)
{
    if(zigzag_engine == NULL) return;
    
    // Dynamic ATR tolerance (e.g., within 15% of H1 ATR to be considered "Equal")
    m_atrTolerance = GetATR(14) * 0.15; 
    
    DetectPools(zigzag_engine);
    CheckForSweeps();
}

void C_LiquiditySensor::DetectPools(CZigZagEngine *zigzag_engine)
{
    int total_zz_nodes = zigzag_engine.GetNodeCount();
    if(total_zz_nodes < 5) return; // Need at least a few swings to find matches
    
    // Scan the most recent nodes to build pools
    int scan_depth = MathMin(total_zz_nodes, 8); 
    
    for(int i = 0; i < scan_depth; i++)
    {
        double priceA = zigzag_engine.GetNodePrice(i);
        bool isHighA  = zigzag_engine.IsNodeHigh(i);
        
        for(int j = i + 1; j < scan_depth; j++)
        {
            double priceB = zigzag_engine.GetNodePrice(j);
            bool isHighB  = zigzag_engine.IsNodeHigh(j);
            
            // Only compare Highs to Highs, Lows to Lows
            if(isHighA != isHighB) continue;
            
            // If they are within the ATR tolerance, we found an EQH / EQL
            if(MathAbs(priceA - priceB) <= m_atrTolerance)
            {
                bool poolExists = false;
                double targetLevel = isHighA ? MathMax(priceA, priceB) : MathMin(priceA, priceB);
                
                // Prevent duplicate pools
                for(int p = 0; p < ArraySize(m_pools); p++)
                {
                    if(m_pools[p].isActive && m_pools[p].isEQH == isHighA && MathAbs(m_pools[p].level - targetLevel) <= m_atrTolerance)
                    {
                        poolExists = true;
                        break;
                    }
                }
                
                if(!poolExists)
                {
                    int size = ArraySize(m_pools);
                    ArrayResize(m_pools, size + 1);
                    m_pools[size].isActive = true;
                    m_pools[size].isEQH = isHighA;
                    m_pools[size].level = targetLevel;
                    m_pools[size].isSwept = false;
                    m_pools[size].timeFormed = zigzag_engine.GetNodeTime(i);
                }
            }
        }
    }
}

void C_LiquiditySensor::CheckForSweeps()
{
    double high[], low[], close[];
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    if(CopyHigh(m_symbol, m_tf, 0, 2, high) < 2) return;
    if(CopyLow(m_symbol, m_tf, 0, 2, low) < 2) return;
    if(CopyClose(m_symbol, m_tf, 0, 2, close) < 2) return;
    
    for(int p = 0; p < ArraySize(m_pools); p++)
    {
        if(!m_pools[p].isActive || m_pools[p].isSwept) continue;
        
        if(m_pools[p].isEQH)
        {
            // EQH Sweep Trap: Wick pierces above pool, but body closes below it
            if(high[1] > m_pools[p].level && close[1] < m_pools[p].level)
            {
                m_pools[p].isSwept = true;
                m_pools[p].isActive = false; // Deactivate once swept
                PrintFormat("[V3 Liquidity] EQH Swept at %.5f! Sell Stop-Hunt Detected.", m_pools[p].level);
            }
        }
        else
        {
            // EQL Sweep Trap: Wick pierces below pool, but body closes above it
            if(low[1] < m_pools[p].level && close[1] > m_pools[p].level)
            {
                m_pools[p].isSwept = true;
                m_pools[p].isActive = false; 
                PrintFormat("[V3 Liquidity] EQL Swept at %.5f! Buy Stop-Hunt Detected.", m_pools[p].level);
            }
        }
    }
}

bool C_LiquiditySensor::IsEQHSwept(double &sweep_level)
{
    for(int i = 0; i < ArraySize(m_pools); i++)
    {
        if(m_pools[i].isEQH && m_pools[i].isSwept)
        {
            sweep_level = m_pools[i].level;
            return true;
        }
    }
    return false;
}

bool C_LiquiditySensor::IsEQLSwept(double &sweep_level)
{
    for(int i = 0; i < ArraySize(m_pools); i++)
    {
        if(!m_pools[i].isEQH && m_pools[i].isSwept)
        {
            sweep_level = m_pools[i].level;
            return true;
        }
    }
    return false;
}

double C_LiquiditySensor::GetATR(int period)
{
    double atr[];
    int handle = iATR(m_symbol, m_tf, period);
    if(handle == INVALID_HANDLE) return 0.0;
    double val = 0.0;
    if(CopyBuffer(handle, 0, 0, 1, atr) > 0)
    {
        val = atr[0];
    }
    IndicatorRelease(handle);
    return val;
}
#endif
