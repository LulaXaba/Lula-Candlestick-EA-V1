//+------------------------------------------------------------------+
//|                                         C_OrderBlockSensor.mqh   |
//|                             Lula Price Action Execution Engine V3|
//+------------------------------------------------------------------+
#ifndef C_ORDERBLOCKSENSOR_MQH
#define C_ORDERBLOCKSENSOR_MQH

#include "CZigZagEngine.mqh"
#include "../Include/SymbolProfile.mqh"

struct SOrderBlock
{
    bool     isActive;
    bool     isBullish;
    double   top;
    double   bottom;
    datetime time;
};

class C_OrderBlockSensor
{
private:
    string          m_symbol;
    ENUM_TIMEFRAMES m_tf;
    SOrderBlock     m_blocks[];

    double          GetATR(int period)
    {
        double atr[];
        ArrayResize(atr, 0);
        int h = iATR(m_symbol, m_tf, period);
        if(h == INVALID_HANDLE) return 0.0;
        double val = 0.0;
        if(CopyBuffer(h, 0, 0, 1, atr) > 0)
            val = atr[0];
        IndicatorRelease(h);
        return val;
    }

public:
                    C_OrderBlockSensor() : m_symbol(""), m_tf(PERIOD_CURRENT) { ArrayResize(m_blocks, 0); }
                   ~C_OrderBlockSensor() {}

    void            Init(string symbol, ENUM_TIMEFRAMES tf)
    {
        m_symbol = symbol;
        m_tf = tf;
        ArrayResize(m_blocks, 0);
    }
    
    void            Update()
    {
        double atr = GetATR(14);
        if(atr <= 0.0) return;

        double open[], close[], high[], low[];
        datetime time[];
        
        ArraySetAsSeries(open, true);
        ArraySetAsSeries(close, true);
        ArraySetAsSeries(high, true);
        ArraySetAsSeries(low, true);
        ArraySetAsSeries(time, true);

        if(CopyOpen(m_symbol, m_tf, 1, 5, open) < 5) return;
        if(CopyClose(m_symbol, m_tf, 1, 5, close) < 5) return;
        if(CopyHigh(m_symbol, m_tf, 1, 5, high) < 5) return;
        if(CopyLow(m_symbol, m_tf, 1, 5, low) < 5) return;
        if(CopyTime(m_symbol, m_tf, 1, 5, time) < 5) return;
        
        // Find Bullish OB (Down candle followed by massive displacement)
        if(close[1] > open[1] && (close[1] - open[1]) > (atr * 1.5) && close[2] < open[2])
        {
            bool exists = false;
            for(int k = 0; k < ArraySize(m_blocks); k++)
            {
                if(m_blocks[k].time == time[2]) { exists = true; break; }
            }
            if(!exists)
            {
                int s = ArraySize(m_blocks);
                ArrayResize(m_blocks, s + 1);
                m_blocks[s].isActive  = true;
                m_blocks[s].isBullish = true;
                m_blocks[s].top       = MathMax(open[2], close[2]);
                m_blocks[s].bottom    = low[2];
                m_blocks[s].time      = time[2];
            }
        }

        // Find Bearish OB (Up candle followed by massive displacement)
        if(close[1] < open[1] && (open[1] - close[1]) > (atr * 1.5) && close[2] > open[2])
        {
            bool exists = false;
            for(int k = 0; k < ArraySize(m_blocks); k++)
            {
                if(m_blocks[k].time == time[2]) { exists = true; break; }
            }
            if(!exists)
            {
                int s = ArraySize(m_blocks);
                ArrayResize(m_blocks, s + 1);
                m_blocks[s].isActive  = true;
                m_blocks[s].isBullish = false;
                m_blocks[s].top       = high[2];
                m_blocks[s].bottom    = MathMin(open[2], close[2]);
                m_blocks[s].time      = time[2];
            }
        }
        
        // Mitigation Check
        double cur_bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
        for(int i = 0; i < ArraySize(m_blocks); i++)
        {
            if(!m_blocks[i].isActive) continue;
            if(m_blocks[i].isBullish && cur_bid < m_blocks[i].bottom)
                m_blocks[i].isActive = false;
            if(!m_blocks[i].isBullish && cur_bid > m_blocks[i].top)
                m_blocks[i].isActive = false;
        }
    }
    
    bool            IsInsideBullishOB(double price, double &out_sl)
    {
        for(int i = 0; i < ArraySize(m_blocks); i++)
        {
            if(m_blocks[i].isActive && m_blocks[i].isBullish && price >= m_blocks[i].bottom && price <= m_blocks[i].top)
            {
                out_sl = m_blocks[i].bottom;
                return true;
            }
        }
        return false;
    }

    bool            IsInsideBearishOB(double price, double &out_sl)
    {
        for(int i = 0; i < ArraySize(m_blocks); i++)
        {
            if(m_blocks[i].isActive && !m_blocks[i].isBullish && price >= m_blocks[i].bottom && price <= m_blocks[i].top)
            {
                out_sl = m_blocks[i].top;
                return true;
            }
        }
        return false;
    }
    
    // For Visual Renderer
    int             GetBlockCount()           { return ArraySize(m_blocks); }
    SOrderBlock     GetBlock(int i)           { return m_blocks[i]; }
};

#endif // C_ORDERBLOCKSENSOR_MQH
