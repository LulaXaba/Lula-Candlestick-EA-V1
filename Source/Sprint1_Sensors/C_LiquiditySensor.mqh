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
    datetime sweepTime;    // [Fix #3] When the sweep was detected
};

// [Fix #3] After this many LTF bars the swept signal expires (prevents stale entries)
#define SWEEP_EXPIRY_BARS 12

class C_LiquiditySensor
{
private:
    string              m_symbol;
    ENUM_TIMEFRAMES     m_tf;
    ENUM_TIMEFRAMES     m_ltf;         // [Fix #3] needed to compute expiry
    SLiquidityPool      m_pools[];

    double              m_atrTolerance;
    int                 m_atrHandle;   // [Fix #4] persistent handle

    double              GetATR();
    void                DetectPools(CZigZagEngine *zigzag_engine);
    void                CheckForSweeps();
    void                ExpireOldSweeps();   // [Fix #3]

public:
                        C_LiquiditySensor();
                       ~C_LiquiditySensor();

    bool                Init(string symbol, ENUM_TIMEFRAMES tf, ENUM_TIMEFRAMES ltf = PERIOD_M5);
    void                Update(CZigZagEngine *zigzag_engine);

    // Accessors for Decision Tree Execution
    bool                IsEQHSwept(double &sweep_level);
    bool                IsEQLSwept(double &sweep_level);
    void                DeactivateSweptPool(double sweep_level);
};

C_LiquiditySensor::C_LiquiditySensor()
    : m_symbol(""), m_tf(PERIOD_CURRENT), m_ltf(PERIOD_M5),
      m_atrTolerance(0.0), m_atrHandle(INVALID_HANDLE) {}

C_LiquiditySensor::~C_LiquiditySensor()
{
    if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
}

bool C_LiquiditySensor::Init(string symbol, ENUM_TIMEFRAMES tf, ENUM_TIMEFRAMES ltf)
{
    m_symbol = symbol;
    m_tf     = tf;
    m_ltf    = ltf;
    ArrayResize(m_pools, 0);
    if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
    m_atrHandle = iATR(m_symbol, m_tf, 14);  // [Fix #4] create once
    PrintFormat("[V3 Sensor] Liquidity Sensor Initialized: %s", m_symbol);
    return true;
}

void C_LiquiditySensor::Update(CZigZagEngine *zigzag_engine)
{
    if(zigzag_engine == NULL) return;

    // Dynamic ATR tolerance (within 15% of MTF ATR to be considered "Equal")
    double rawAtr = GetATR();
    m_atrTolerance = rawAtr * 0.15;

    DetectPools(zigzag_engine);
    CheckForSweeps();
    ExpireOldSweeps();  // [Fix #3]
}

void C_LiquiditySensor::DetectPools(CZigZagEngine *zigzag_engine)
{
    int total_zz_nodes = zigzag_engine.GetNodeCount();
    if(total_zz_nodes < 5) return;

    int scan_depth = MathMin(total_zz_nodes, 8);

    for(int i = 0; i < scan_depth; i++)
    {
        double priceA = zigzag_engine.GetNodePrice(i);
        bool   isHighA = zigzag_engine.IsNodeHigh(i);
        datetime timeA = zigzag_engine.GetNodeTime(i);

        for(int j = i + 1; j < scan_depth; j++)
        {
            double priceB = zigzag_engine.GetNodePrice(j);
            bool   isHighB = zigzag_engine.IsNodeHigh(j);

            if(isHighA != isHighB) continue;

            if(MathAbs(priceA - priceB) <= m_atrTolerance)
            {
                double targetLevel = isHighA ? MathMax(priceA, priceB) : MathMin(priceA, priceB);

                // [Fix #3] Dedupe against ALL pools (active AND inactive / swept) by level+direction
                bool poolExists = false;
                for(int p = 0; p < ArraySize(m_pools); p++)
                {
                    if(m_pools[p].isEQH == isHighA &&
                       MathAbs(m_pools[p].level - targetLevel) <= m_atrTolerance)
                    {
                        poolExists = true;
                        break;
                    }
                }

                if(!poolExists)
                {
                    int size = ArraySize(m_pools);
                    ArrayResize(m_pools, size + 1);
                    m_pools[size].isActive   = true;
                    m_pools[size].isEQH      = isHighA;
                    m_pools[size].level      = targetLevel;
                    m_pools[size].isSwept    = false;
                    m_pools[size].sweepTime  = 0;
                    m_pools[size].timeFormed = timeA;
                }
            }
        }
    }
}

void C_LiquiditySensor::CheckForSweeps()
{
    double high[], low[], close[];
    ArraySetAsSeries(high,  true);
    ArraySetAsSeries(low,   true);
    ArraySetAsSeries(close, true);
    if(CopyHigh (m_symbol, m_tf, 1, 2, high)  < 2) return;
    if(CopyLow  (m_symbol, m_tf, 1, 2, low)   < 2) return;
    if(CopyClose(m_symbol, m_tf, 1, 2, close) < 2) return;

    // Use only the last closed bar (index 0 after series = shift 1)
    for(int p = 0; p < ArraySize(m_pools); p++)
    {
        if(!m_pools[p].isActive || m_pools[p].isSwept) continue;

        if(m_pools[p].isEQH)
        {
            // EQH sweep: wick above, body closes below
            if(high[0] > m_pools[p].level && close[0] < m_pools[p].level)
            {
                m_pools[p].isSwept   = true;
                m_pools[p].isActive  = false;
                m_pools[p].sweepTime = TimeCurrent();
                PrintFormat("[V3 Liquidity] EQH Swept at %.5f! Sell Stop-Hunt Detected.", m_pools[p].level);
            }
        }
        else
        {
            // EQL sweep: wick below, body closes above
            if(low[0] < m_pools[p].level && close[0] > m_pools[p].level)
            {
                m_pools[p].isSwept   = true;
                m_pools[p].isActive  = false;
                m_pools[p].sweepTime = TimeCurrent();
                PrintFormat("[V3 Liquidity] EQL Swept at %.5f! Buy Stop-Hunt Detected.", m_pools[p].level);
            }
        }
    }
}

// [Fix #3] Invalidate swept signals older than SWEEP_EXPIRY_BARS LTF bars
void C_LiquiditySensor::ExpireOldSweeps()
{
    if(m_ltf == PERIOD_CURRENT) return;
    datetime ltfBarDuration = (datetime)PeriodSeconds(m_ltf);
    datetime expiry         = ltfBarDuration * SWEEP_EXPIRY_BARS;

    datetime now = TimeCurrent();
    for(int p = 0; p < ArraySize(m_pools); p++)
    {
        if(m_pools[p].isSwept && m_pools[p].sweepTime > 0)
        {
            if((now - m_pools[p].sweepTime) >= expiry)
            {
                m_pools[p].isSwept  = false; // signal expires — no longer actionable
                PrintFormat("[V3 Liquidity] Swept signal at %.5f expired after %d bars.", m_pools[p].level, SWEEP_EXPIRY_BARS);
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

void C_LiquiditySensor::DeactivateSweptPool(double sweep_level)
{
    for(int i = 0; i < ArraySize(m_pools); i++)
    {
        if(m_pools[i].isSwept &&
           MathAbs(m_pools[i].level - sweep_level) <= (m_atrTolerance > 0 ? m_atrTolerance : 0.0001))
        {
            m_pools[i].isSwept  = false;
            m_pools[i].isActive = false;
            PrintFormat("[V3 Liquidity] Swept pool at %.5f consumed and deactivated.", sweep_level);
            return;
        }
    }
}

double C_LiquiditySensor::GetATR()
{
    if(m_atrHandle == INVALID_HANDLE) return 0.0;
    double atr[];
    if(CopyBuffer(m_atrHandle, 0, 0, 1, atr) > 0) return atr[0];
    return 0.0;
}
#endif
