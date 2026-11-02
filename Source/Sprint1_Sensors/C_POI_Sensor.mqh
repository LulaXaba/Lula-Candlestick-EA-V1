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
    int             m_atrHandle;

    // [PATCH P2] New tunables — defaults chosen for VIX75 (ATR 120–160 on M5/M15)
    double          m_dispMult;      // displacement threshold as ATR multiple (was hard-coded 1.0)
    double          m_mitigBufATR;   // mitigation buffer as ATR fraction (was 0.0)
    double          m_proxATR;       // proximity entry tolerance as ATR fraction

    bool            ZoneExists(bool isBull, datetime t) const
    {
        for(int i = 0; i < ArraySize(m_zones); i++)
            if(m_zones[i].time == t && m_zones[i].isBullish == isBull) return true;
        return false;
    }

    double          GetATR()
    {
        if(m_atrHandle == INVALID_HANDLE) return 0.0;
        double atr[];
        ArrayResize(atr, 0);
        if(CopyBuffer(m_atrHandle, 0, 1, 1, atr) > 0) return atr[0];
        return 0.0;
    }

public:
                    C_POI_Sensor() : m_symbol(""), m_tf(PERIOD_CURRENT), m_atrHandle(INVALID_HANDLE),
                                     m_dispMult(0.6), m_mitigBufATR(0.25), m_proxATR(0.30)
                    { ArrayResize(m_zones, 0); }
                   ~C_POI_Sensor()
                    { if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle); }

    // [PATCH P3] Init gains optional params. Existing call sites (symbol, tf) still compile.
    void            Init(string symbol, ENUM_TIMEFRAMES tf,
                         double dispMult      = 0.6,
                         double mitigBufATR   = 0.25,
                         double proxATR       = 0.30)
    {
        m_symbol       = symbol;
        m_tf           = tf;
        m_dispMult     = dispMult;
        m_mitigBufATR  = mitigBufATR;
        m_proxATR      = proxATR;
        ArrayResize(m_zones, 0);
        if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
        m_atrHandle = iATR(m_symbol, m_tf, 14);
        PrintFormat("[V3 POI] Config: dispMult=%.2f  mitigBuf=%.2f ATR  prox=%.2f ATR",
                    m_dispMult, m_mitigBufATR, m_proxATR);
    }

    void            Update()
    {
        double atr = GetATR();
        if(atr <= 0.0) return;

        double open[], close[], high[], low[];
        datetime time[];
        ArraySetAsSeries(open,  true);
        ArraySetAsSeries(close, true);
        ArraySetAsSeries(high,  true);
        ArraySetAsSeries(low,   true);
        ArraySetAsSeries(time,  true);

        if(CopyOpen (m_symbol, m_tf, 1, 3, open)  < 3 ||
           CopyClose(m_symbol, m_tf, 1, 3, close) < 3 ||
           CopyHigh (m_symbol, m_tf, 1, 3, high)  < 3 ||
           CopyLow  (m_symbol, m_tf, 1, 3, low)   < 3 ||
           CopyTime (m_symbol, m_tf, 1, 3, time)  < 3) return;

        // [PATCH P4] Displacement uses m_dispMult (was hard-coded 1.0)
        double dispThresh = atr * m_dispMult;

        // Bullish POI
        if(close[0] > open[0] && (close[0] - open[0]) > dispThresh && close[1] <= open[1])
        {
            if(!ZoneExists(true, time[1]))
            {
                int s = ArraySize(m_zones); ArrayResize(m_zones, s + 1);
                m_zones[s].isActive  = true;
                m_zones[s].isBullish = true;
                m_zones[s].top       = MathMax(open[1], high[1]);
                m_zones[s].bottom    = low[1];
                m_zones[s].time      = time[1];
            }
        }

        // Bearish POI
        if(close[0] < open[0] && (open[0] - close[0]) > dispThresh && close[1] >= open[1])
        {
            if(!ZoneExists(false, time[1]))
            {
                int s = ArraySize(m_zones); ArrayResize(m_zones, s + 1);
                m_zones[s].isActive  = true;
                m_zones[s].isBullish = false;
                m_zones[s].top       = high[1];
                m_zones[s].bottom    = MathMin(open[1], low[1]);
                m_zones[s].time      = time[1];
            }
        }

        // [PATCH P5] Mitigation with ATR buffer — a brief wick/close above the top
        // no longer kills a supply zone. Only a decisive breach (> top + buffer) does.
        double closed_bar_close = close[0];
        double mitigBuf         = atr * m_mitigBufATR;
        for(int i = 0; i < ArraySize(m_zones); i++)
        {
            if(!m_zones[i].isActive) continue;
            if( m_zones[i].isBullish && closed_bar_close < (m_zones[i].bottom - mitigBuf))
                m_zones[i].isActive = false;
            if(!m_zones[i].isBullish && closed_bar_close > (m_zones[i].top + mitigBuf))
                m_zones[i].isActive = false;
        }
    }

    // --- Accessors ---

    bool            IsInsideBullishPOI(double price, double &out_sl, datetime &out_poi_time)
    {
        for(int i = 0; i < ArraySize(m_zones); i++)
        {
            if(m_zones[i].isActive && m_zones[i].isBullish &&
               price >= m_zones[i].bottom && price <= m_zones[i].top)
            {
                out_sl       = m_zones[i].bottom;
                out_poi_time = m_zones[i].time;
                return true;
            }
        }
        return false;
    }
    bool            IsInsideBullishPOI(double price, double &out_sl)
                    { datetime t = 0; return IsInsideBullishPOI(price, out_sl, t); }

    bool            IsInsideBearishPOI(double price, double &out_sl, datetime &out_poi_time)
    {
        for(int i = 0; i < ArraySize(m_zones); i++)
        {
            if(m_zones[i].isActive && !m_zones[i].isBullish &&
               price >= m_zones[i].bottom && price <= m_zones[i].top)
            {
                out_sl       = m_zones[i].top;
                out_poi_time = m_zones[i].time;
                return true;
            }
        }
        return false;
    }
    bool            IsInsideBearishPOI(double price, double &out_sl)
                    { datetime t = 0; return IsInsideBearishPOI(price, out_sl, t); }

    // [PATCH P6] Proximity accessors — price need not be *inside* the zone; within
    // m_proxATR × ATR below the bottom is enough. Picks the zone with smallest
    // distance-to-edge so the nearest candidate wins.
    bool            IsNearBearishPOI(double price, double atr, double &out_sl,
                                     datetime &out_poi_time)
    {
        if(atr <= 0.0) return false;
        double tol = atr * m_proxATR;
        double bestDist = DBL_MAX;
        bool   found    = false;
        for(int i = 0; i < ArraySize(m_zones); i++)
        {
            if(!m_zones[i].isActive || m_zones[i].isBullish) continue;
            // Reject if price has already broken above the top + mitigation buffer
            if(price > m_zones[i].top + tol) continue;
            // Accept if price is anywhere from (bottom - tol) up to top
            if(price >= m_zones[i].bottom - tol && price <= m_zones[i].top)
            {
                double d = MathAbs(price - (m_zones[i].top + m_zones[i].bottom) * 0.5);
                if(d < bestDist)
                {
                    bestDist     = d;
                    out_sl       = m_zones[i].top;
                    out_poi_time = m_zones[i].time;
                    found        = true;
                }
            }
        }
        return found;
    }

    bool            IsNearBullishPOI(double price, double atr, double &out_sl,
                                     datetime &out_poi_time)
    {
        if(atr <= 0.0) return false;
        double tol = atr * m_proxATR;
        double bestDist = DBL_MAX;
        bool   found    = false;
        for(int i = 0; i < ArraySize(m_zones); i++)
        {
            if(!m_zones[i].isActive || !m_zones[i].isBullish) continue;
            if(price < m_zones[i].bottom - tol) continue;
            if(price >= m_zones[i].bottom && price <= m_zones[i].top + tol)
            {
                double d = MathAbs(price - (m_zones[i].top + m_zones[i].bottom) * 0.5);
                if(d < bestDist)
                {
                    bestDist     = d;
                    out_sl       = m_zones[i].bottom;
                    out_poi_time = m_zones[i].time;
                    found        = true;
                }
            }
        }
        return found;
    }

    // --- Mitigation helpers ---
    void            DeactivatePOIByTime(datetime poi_time)
    {
        if(poi_time <= 0) return;
        for(int i = 0; i < ArraySize(m_zones); i++)
        {
            if(m_zones[i].time == poi_time)
            {
                m_zones[i].isActive = false;
                PrintFormat("[V3 POI] POI (%s) consumed and deactivated.", TimeToString(poi_time));
                return;
            }
        }
    }
    void            DeactivateBullishPOI(double price)
    {
        for(int i = 0; i < ArraySize(m_zones); i++)
        {
            if(m_zones[i].isActive && m_zones[i].isBullish &&
               price >= m_zones[i].bottom && price <= m_zones[i].top)
            { m_zones[i].isActive = false; return; }
        }
    }
    void            DeactivateBearishPOI(double price)
    {
        for(int i = 0; i < ArraySize(m_zones); i++)
        {
            if(m_zones[i].isActive && !m_zones[i].isBullish &&
               price >= m_zones[i].bottom && price <= m_zones[i].top)
            { m_zones[i].isActive = false; return; }
        }
    }

    int             GetPOICount() { return ArraySize(m_zones); }
    SPOI            GetPOI(int i)
                    { static SPOI empty; if(i < 0 || i >= ArraySize(m_zones)) return empty; return m_zones[i]; }

    // [PATCH P7] Diagnostics — distinguish "no zones" from "all inactive"
    int             GetActiveBearCount()
    {
        int n = 0;
        for(int i = 0; i < ArraySize(m_zones); i++)
            if(m_zones[i].isActive && !m_zones[i].isBullish) n++;
        return n;
    }
    int             GetActiveBullCount()
    {
        int n = 0;
        for(int i = 0; i < ArraySize(m_zones); i++)
            if(m_zones[i].isActive && m_zones[i].isBullish) n++;
        return n;
    }
    int             GetTotalBearCount()
    {
        int n = 0;
        for(int i = 0; i < ArraySize(m_zones); i++)
            if(!m_zones[i].isBullish) n++;
        return n;
    }
    int             GetTotalBullCount()
    {
        int n = 0;
        for(int i = 0; i < ArraySize(m_zones); i++)
            if(m_zones[i].isBullish) n++;
        return n;
    }

    void            Backfill(const int bars = 300)
    {
        if(m_atrHandle == INVALID_HANDLE) return;
        double atr = GetATR();
        if(atr <= 0.0) return;
        double dispThresh = atr * m_dispMult;      // [PATCH P8]

        double o[], c[], h[], l[]; datetime t[];
        ArraySetAsSeries(o, true); ArraySetAsSeries(c, true);
        ArraySetAsSeries(h, true); ArraySetAsSeries(l, true);
        ArraySetAsSeries(t, true);

        int n = bars + 2;
        if(CopyOpen (m_symbol, m_tf, 1, n, o) < n ||
           CopyClose(m_symbol, m_tf, 1, n, c) < n ||
           CopyHigh (m_symbol, m_tf, 1, n, h) < n ||
           CopyLow  (m_symbol, m_tf, 1, n, l) < n ||
           CopyTime (m_symbol, m_tf, 1, n, t) < n) return;

        for(int k = bars - 1; k >= 0; k--)
        {
            if(c[k] > o[k] && (c[k] - o[k]) > dispThresh && c[k+1] <= o[k+1] && !ZoneExists(true, t[k+1]))
            {
                int s = ArraySize(m_zones); ArrayResize(m_zones, s + 1);
                m_zones[s].isActive  = true; m_zones[s].isBullish = true;
                m_zones[s].top       = MathMax(o[k+1], h[k+1]);
                m_zones[s].bottom    = l[k+1];
                m_zones[s].time      = t[k+1];
            }
            if(c[k] < o[k] && (o[k] - c[k]) > dispThresh && c[k+1] >= o[k+1] && !ZoneExists(false, t[k+1]))
            {
                int s = ArraySize(m_zones); ArrayResize(m_zones, s + 1);
                m_zones[s].isActive  = true; m_zones[s].isBullish = false;
                m_zones[s].top       = h[k+1];
                m_zones[s].bottom    = MathMin(o[k+1], l[k+1]);
                m_zones[s].time      = t[k+1];
            }
            // Mitigation with buffer (same logic as live Update)
            double mitigBuf = atr * m_mitigBufATR;
            for(int i = 0; i < ArraySize(m_zones); i++)
            {
                if(!m_zones[i].isActive) continue;
                if( m_zones[i].isBullish && c[k] < (m_zones[i].bottom - mitigBuf)) m_zones[i].isActive = false;
                if(!m_zones[i].isBullish && c[k] > (m_zones[i].top + mitigBuf))    m_zones[i].isActive = false;
            }
        }

        PrintFormat("[V3 POI] Backfill: %d zones total, %d active after %d bars.",
                    ArraySize(m_zones), GetActiveBearCount() + GetActiveBullCount(), bars);
    }
};

#endif
