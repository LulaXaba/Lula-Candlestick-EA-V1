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
    int             m_atrHandle;   // [Fix #4] persistent handle, not recreated per call

    // [Fix #2] Existence check scans ALL zones (including inactive) to prevent
    // mitigated POIs from being recreated on the next update call.
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
        // [Closed-bar rule] shift 1 — consistent with every other structural read
        if(CopyBuffer(m_atrHandle, 0, 1, 1, atr) > 0) return atr[0];
        return 0.0;
    }

public:
                    C_POI_Sensor() : m_symbol(""), m_tf(PERIOD_CURRENT), m_atrHandle(INVALID_HANDLE)
                    { ArrayResize(m_zones, 0); }
                   ~C_POI_Sensor()
                    { if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle); }

    void            Init(string symbol, ENUM_TIMEFRAMES tf)
    {
        m_symbol = symbol;
        m_tf     = tf;
        ArrayResize(m_zones, 0);
        if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
        m_atrHandle = iATR(m_symbol, m_tf, 14);
    }

    void            Update()
    {
        double atr = GetATR();
        if(atr <= 0.0) return;

        // [Fix #2] Copy with series flag set BEFORE copy so index meaning is deliberate:
        //   index 0 = most recent closed bar (shift 1 from live)
        //   index 1 = one bar older          (shift 2)
        //   index 2 = two bars older         (shift 3)
        // We look at the displacement bar [0] and its predecessor [1].
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

        // index 0 = displacement bar, index 1 = order-block base bar
        // Bullish POI: strong bullish displacement off a bearish base
        if(close[0] > open[0] && (close[0] - open[0]) > (atr * 1.0) && close[1] <= open[1])
        {
            if(!ZoneExists(true, time[1])) // [Fix #2] guard against duplicates
            {
                int s = ArraySize(m_zones); ArrayResize(m_zones, s + 1);
                m_zones[s].isActive  = true;
                m_zones[s].isBullish = true;
                m_zones[s].top       = MathMax(open[1], high[1]);
                m_zones[s].bottom    = low[1];
                m_zones[s].time      = time[1];
            }
        }

        // Bearish POI: strong bearish displacement off a bullish base
        if(close[0] < open[0] && (open[0] - close[0]) > (atr * 1.0) && close[1] >= open[1])
        {
            if(!ZoneExists(false, time[1])) // [Fix #2] guard against duplicates
            {
                int s = ArraySize(m_zones); ArrayResize(m_zones, s + 1);
                m_zones[s].isActive  = true;
                m_zones[s].isBullish = false;
                m_zones[s].top       = high[1];
                m_zones[s].bottom    = MathMin(open[1], low[1]);
                m_zones[s].time      = time[1];
            }
        }

        // Mitigation check on closed bar price (bar index 0 = last closed)
        double closed_bar_close = close[0];
        for(int i = 0; i < ArraySize(m_zones); i++)
        {
            if(!m_zones[i].isActive) continue;
            if( m_zones[i].isBullish && closed_bar_close < m_zones[i].bottom) m_zones[i].isActive = false;
            if(!m_zones[i].isBullish && closed_bar_close > m_zones[i].top)    m_zones[i].isActive = false;
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

    // --- Mitigation helpers (called from OnTick after a trade fires) ---

    void            DeactivatePOIByTime(datetime poi_time)
    {
        if(poi_time <= 0) return;
        for(int i = 0; i < ArraySize(m_zones); i++)
        {
            if(m_zones[i].time == poi_time)   // deactivate even if already marked inactive
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
            {
                m_zones[i].isActive = false;
                PrintFormat("[V3 POI] Bullish POI (%s) consumed.", TimeToString(m_zones[i].time));
                return;
            }
        }
    }

    void            DeactivateBearishPOI(double price)
    {
        for(int i = 0; i < ArraySize(m_zones); i++)
        {
            if(m_zones[i].isActive && !m_zones[i].isBullish &&
               price >= m_zones[i].bottom && price <= m_zones[i].top)
            {
                m_zones[i].isActive = false;
                PrintFormat("[V3 POI] Bearish POI (%s) consumed.", TimeToString(m_zones[i].time));
                return;
            }
        }
    }

    int             GetPOICount() { return ArraySize(m_zones); }
    SPOI            GetPOI(int i) { static SPOI empty; if(i < 0 || i >= ArraySize(m_zones)) return empty; return m_zones[i]; }

    // --- Historical seed: build zones from the last `bars` closed MTF bars ---
    // Called once from OnInit after Init(). Uses current-bar ATR as an approximation
    // (acceptable for seeding; live Update() refines from there).
    void            Backfill(const int bars = 300)
    {
        if(m_atrHandle == INVALID_HANDLE) return;
        double atr = GetATR();
        if(atr <= 0.0) return;

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

        for(int k = bars - 1; k >= 0; k--)          // oldest -> newest
        {
            // Bullish POI: strong bullish displacement off a bearish base
            if(c[k] > o[k] && (c[k] - o[k]) > atr && c[k+1] <= o[k+1] && !ZoneExists(true, t[k+1]))
            {
                int s = ArraySize(m_zones); ArrayResize(m_zones, s + 1);
                m_zones[s].isActive  = true;
                m_zones[s].isBullish = true;
                m_zones[s].top       = MathMax(o[k+1], h[k+1]);
                m_zones[s].bottom    = l[k+1];
                m_zones[s].time      = t[k+1];
            }
            // Bearish POI: strong bearish displacement off a bullish base
            if(c[k] < o[k] && (o[k] - c[k]) > atr && c[k+1] >= o[k+1] && !ZoneExists(false, t[k+1]))
            {
                int s = ArraySize(m_zones); ArrayResize(m_zones, s + 1);
                m_zones[s].isActive  = true;
                m_zones[s].isBullish = false;
                m_zones[s].top       = h[k+1];
                m_zones[s].bottom    = MathMin(o[k+1], l[k+1]);
                m_zones[s].time      = t[k+1];
            }
            // Chronological mitigation pass
            for(int i = 0; i < ArraySize(m_zones); i++)
            {
                if(!m_zones[i].isActive) continue;
                if( m_zones[i].isBullish && c[k] < m_zones[i].bottom) m_zones[i].isActive = false;
                if(!m_zones[i].isBullish && c[k] > m_zones[i].top)    m_zones[i].isActive = false;
            }
        }

        int act = 0;
        for(int i = 0; i < ArraySize(m_zones); i++) if(m_zones[i].isActive) act++;
        PrintFormat("[V3 POI] Backfill: %d zones total, %d active after %d bars.", ArraySize(m_zones), act, bars);
    }
};

#endif // C_POI_SENSOR_MQH
