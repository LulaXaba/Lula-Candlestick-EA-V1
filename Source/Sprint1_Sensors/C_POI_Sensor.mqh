//+------------------------------------------------------------------+
//|                                                C_POI_Sensor.mqh  |
//|                             Lula Price Action Execution Engine V3|
//|                     Unified Order Block & Supply/Demand Sensor   |
//+------------------------------------------------------------------+
#ifndef C_POI_SENSOR_MQH
#define C_POI_SENSOR_MQH

struct SPOI
{
    bool     isActive;
    bool     isBullish;
    double   top;
    double   bottom;
    datetime time;
};

class C_POI_Sensor
{
private:
    string          m_symbol;
    ENUM_TIMEFRAMES m_tf;
    SPOI            m_zones[];

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
                    C_POI_Sensor() : m_symbol(""), m_tf(PERIOD_CURRENT) { ArrayResize(m_zones, 0); }
                   ~C_POI_Sensor() {}

    void            Init(string symbol, ENUM_TIMEFRAMES tf)
    {
        m_symbol = symbol;
        m_tf = tf;
        ArrayResize(m_zones, 0);
    }
    
    void            Update()
    {
        double atr = GetATR(14);
        if(atr <= 0.0) return;

        // Use dynamic arrays to prevent static allocation warnings
        double open[], close[], high[], low[];
        datetime time[];
        
        if(CopyOpen(m_symbol, m_tf, 1, 5, open) < 5 || 
           CopyClose(m_symbol, m_tf, 1, 5, close) < 5 || 
           CopyHigh(m_symbol, m_tf, 1, 5, high) < 5 || 
           CopyLow(m_symbol, m_tf, 1, 5, low) < 5 || 
           CopyTime(m_symbol, m_tf, 1, 5, time) < 5) return;
           
        ArraySetAsSeries(open, true);
        ArraySetAsSeries(close, true);
        ArraySetAsSeries(high, true);
        ArraySetAsSeries(low, true);
        ArraySetAsSeries(time, true);
        
        // 1. Bullish POI (Order Block or Demand Base + Expansion)
        if(close[1] > open[1] && (close[1]-open[1]) > (atr * 1.0) && close[2] <= open[2]) {
            int s = ArraySize(m_zones); ArrayResize(m_zones, s+1);
            m_zones[s].isActive = true; m_zones[s].isBullish = true;
            m_zones[s].top = MathMax(open[2], high[2]); m_zones[s].bottom = low[2];
            m_zones[s].time = time[2];
        }
        
        // 2. Bearish POI (Order Block or Supply Base + Expansion)
        if(close[1] < open[1] && (open[1]-close[1]) > (atr * 1.0) && close[2] >= open[2]) {
            int s = ArraySize(m_zones); ArrayResize(m_zones, s+1);
            m_zones[s].isActive = true; m_zones[s].isBullish = false;
            m_zones[s].top = high[2]; m_zones[s].bottom = MathMin(open[2], low[2]);
            m_zones[s].time = time[2];
        }
        
        // Mitigation
        double cur_bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
        for(int i = 0; i < ArraySize(m_zones); i++)
        {
            if(!m_zones[i].isActive) continue;
            if(m_zones[i].isBullish && cur_bid < m_zones[i].bottom)
                m_zones[i].isActive = false;
            if(!m_zones[i].isBullish && cur_bid > m_zones[i].top)
                m_zones[i].isActive = false;
        }
    }
    
    bool            IsInsideBullishPOI(double price, double &out_sl)
    {
        for(int i = 0; i < ArraySize(m_zones); i++)
        {
            if(m_zones[i].isActive && m_zones[i].isBullish && price >= m_zones[i].bottom && price <= m_zones[i].top)
            {
                out_sl = m_zones[i].bottom;
                return true;
            }
        }
        return false;
    }
    
    bool            IsInsideBearishPOI(double price, double &out_sl)
    {
        for(int i = 0; i < ArraySize(m_zones); i++)
        {
            if(m_zones[i].isActive && !m_zones[i].isBullish && price >= m_zones[i].bottom && price <= m_zones[i].top)
            {
                out_sl = m_zones[i].top;
                return true;
            }
        }
        return false;
    }
    
    int             GetPOICount()       { return ArraySize(m_zones); }
    SPOI            GetPOI(int i)       { return m_zones[i]; }
};

#endif // C_POI_SENSOR_MQH
