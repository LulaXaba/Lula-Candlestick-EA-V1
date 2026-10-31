//+------------------------------------------------------------------+
//| CZigZagEngine.mqh                                                |
//| FastZZ logic — patched for correct pivot depth, closed-bar gate, |
//| alternating cache, and O(1) node accessors                       |
//+------------------------------------------------------------------+
#ifndef CZIGZAGENGINE_MQH
#define CZIGZAGENGINE_MQH

#include "..\Include\Defines.mqh"

//+------------------------------------------------------------------+
//| Pivot node struct                                                |
//+------------------------------------------------------------------+
struct SZZNode
{
   double   price;    // Pivot price
   datetime time;     // Pivot time
   int      index;    // Bar index (0 = current)
   bool     isHigh;   // true = swing high, false = swing low
};

//+------------------------------------------------------------------+
//| ZigZag Engine — FastZZ algorithm, patched                        |
//+------------------------------------------------------------------+
class CZigZagEngine
{
private:
   string          m_symbol;
   ENUM_TIMEFRAMES m_tf;
   int             m_depth;       // depthPoints input (kept for reference)
   double          m_depthPrice;  // depth in price units
   int             m_last;
   int             m_direction;

   // Raw price buffers (series order)
   double          m_zzH[];
   double          m_zzL[];
   double          m_high[];
   double          m_low[];
   double          m_open[];
   double          m_close[];
   datetime        m_time[];
   int             m_bars;

   // [Patch #4] Strictly-alternating confirmed-pivot cache, newest first
   SZZNode         m_cache[];
   int             m_cacheCount;

   // [Patch #2] Closed-bar gate
   datetime        m_lastBarTime;

   // [Patch #1] Per-timeframe ATR depth
   double          m_ownAtrMult;
   int             m_ownAtrHandle;

   void            ResizeBuffers(int size);
   void            BuildCache();           // [Patch #4]

public:
   CZigZagEngine();
   ~CZigZagEngine();

   // [Patch #1] added ownAtrMult parameter
   bool     Init(string symbol, ENUM_TIMEFRAMES tf,
                 int depthPoints = 1000, double ownAtrMult = 0.0);
   void     Update();

   //--- V2 accessors (unchanged signatures, still scan raw buffers)
   bool     GetLast4Nodes(SZZNode &nodes[]) const;
   double   GetLastHigh()      const;
   double   GetLastLow()       const;
   double   GetPrevHigh()      const;
   double   GetPrevLow()       const;
   datetime GetLastHighTime()  const;
   datetime GetLastLowTime()   const;

   ENUM_TREND_STATE GetTrendState()                         const;
   bool     IsHigherHigh()                                  const;
   bool     IsHigherLow()                                   const;
   bool     IsLowerHigh()                                   const;
   bool     IsLowerLow()                                    const;

   bool     IsPullbackToHL(double currentPrice, double atr_mult = 0.0) const;
   bool     IsPullbackToLH(double currentPrice, double atr_mult = 0.0) const;
   double   GetH1ATR()                                      const;

   //--- [Patch #4] O(1) node accessors backed by the cache
   int      GetNodeCount()                    const { return m_cacheCount; }
   double   GetNodePrice(int i)               const { return (i >= 0 && i < m_cacheCount) ? m_cache[i].price  : 0.0;   }
   datetime GetNodeTime(int i)                const { return (i >= 0 && i < m_cacheCount) ? m_cache[i].time   : 0;     }
   bool     IsNodeHigh(int i)                 const { return (i >= 0 && i < m_cacheCount) ? m_cache[i].isHigh : false; }
   int      GetNodes(int maxCount, SZZNode &nodes[]) const;

   void     PrintNodes() const;
};

//+------------------------------------------------------------------+
CZigZagEngine::CZigZagEngine()
   : m_symbol(""), m_tf(PERIOD_CURRENT), m_depth(1000), m_depthPrice(0),
     m_last(0), m_direction(1), m_bars(0),
     m_cacheCount(0), m_lastBarTime(0),
     m_ownAtrMult(0.0), m_ownAtrHandle(INVALID_HANDLE) {}

CZigZagEngine::~CZigZagEngine()
{
   if(m_ownAtrHandle != INVALID_HANDLE) IndicatorRelease(m_ownAtrHandle);
}

//+------------------------------------------------------------------+
bool CZigZagEngine::Init(string symbol, ENUM_TIMEFRAMES tf,
                         int depthPoints, double ownAtrMult)
{
   m_symbol      = symbol;
   m_tf          = tf;
   m_depth       = depthPoints;
   m_ownAtrMult  = ownAtrMult;   // [Patch #1]
   m_lastBarTime = 0;             // [Patch #2] force first run

   SSymbolProfile prof = CSymbolProfile::Get(symbol);
   double mult = prof.zz_depth_atr_mult_h4;
   if(m_tf == PERIOD_D1)       mult = prof.zz_depth_atr_mult_d1;
   else if(m_tf == PERIOD_W1)  mult = prof.zz_depth_atr_mult_w1;
   else if(m_tf == PERIOD_H4)  mult = prof.zz_depth_atr_mult_h4;

   double h1_atr = GetH1ATR();
   if(h1_atr > 0.0 && mult > 0.0)
      m_depthPrice = h1_atr * mult;
   else
      m_depthPrice = depthPoints * SymbolInfoDouble(symbol, SYMBOL_POINT);

   m_direction = 1;
   m_last      = 0;
   m_bars      = 0;

   ArraySetAsSeries(m_zzH,   true);
   ArraySetAsSeries(m_zzL,   true);
   ArraySetAsSeries(m_high,  true);
   ArraySetAsSeries(m_low,   true);
   ArraySetAsSeries(m_open,  true);
   ArraySetAsSeries(m_close, true);
   ArraySetAsSeries(m_time,  true);

   Update();   // initial historical load
   return true;
}

//+------------------------------------------------------------------+
void CZigZagEngine::ResizeBuffers(int size)
{
   ArrayResize(m_zzH,   size);
   ArrayResize(m_zzL,   size);
   ArrayResize(m_high,  size);
   ArrayResize(m_low,   size);
   ArrayResize(m_open,  size);
   ArrayResize(m_close, size);
   ArrayResize(m_time,  size);
}

//+------------------------------------------------------------------+
void CZigZagEngine::Update()
{
   // [Patch #2] Closed-bar gate — recompute only once per new bar
   datetime bt = iTime(m_symbol, m_tf, 0);
   if(bt > 0 && bt == m_lastBarTime) return;
   m_lastBarTime = bt;

   // [Patch #4] Cap lookback so the O(n²) scan is bounded
   int total = MathMin(iBars(m_symbol, m_tf), 3000);
   if(total < 10) return;

   // Refresh H4-profile depth
   SSymbolProfile prof = CSymbolProfile::Get(m_symbol);
   double mult = prof.zz_depth_atr_mult_h4;
   if(m_tf == PERIOD_D1)       mult = prof.zz_depth_atr_mult_d1;
   else if(m_tf == PERIOD_W1)  mult = prof.zz_depth_atr_mult_w1;
   else if(m_tf == PERIOD_H4)  mult = prof.zz_depth_atr_mult_h4;

   double h1_atr = GetH1ATR();
   if(h1_atr > 0.0 && mult > 0.0)
      m_depthPrice = h1_atr * mult;
   else if(m_depthPrice <= 0.0)
      m_depthPrice = m_depth * SymbolInfoDouble(m_symbol, SYMBOL_POINT);

   // [Patch #1] Own-timeframe depth override for LTF/MTF engines
   if(m_ownAtrMult > 0.0)
   {
      if(m_ownAtrHandle == INVALID_HANDLE)
         m_ownAtrHandle = iATR(m_symbol, m_tf, 14);
      double b[1];
      if(m_ownAtrHandle != INVALID_HANDLE &&
         CopyBuffer(m_ownAtrHandle, 0, 1, 1, b) > 0 && b[0] > 0.0)
         m_depthPrice = b[0] * m_ownAtrMult;
   }

   if(total != m_bars)
   {
      ResizeBuffers(total);
      m_bars = total;
   }

   CopyHigh (m_symbol, m_tf, 0, total, m_high);
   CopyLow  (m_symbol, m_tf, 0, total, m_low);
   CopyOpen (m_symbol, m_tf, 0, total, m_open);
   CopyClose(m_symbol, m_tf, 0, total, m_close);
   CopyTime (m_symbol, m_tf, 0, total, m_time);

   ArrayInitialize(m_zzH, 0.0);
   ArrayInitialize(m_zzL, 0.0);
   m_last      = total - 1;
   m_direction = 1;

   // [Patch #2] Loop stops at shift 1 — the live bar never touches confirmed pivots
   for(int i = total - 1; i >= 1; i--)
   {
      bool set = false;
      m_zzL[i] = 0.0;
      m_zzH[i] = 0.0;

      if(m_direction > 0)   // Seeking new high
      {
         if(m_high[i] > m_zzH[m_last])
         {
            m_zzH[m_last] = 0.0;
            m_zzH[i]      = m_high[i];
            m_last = i;
            set = true;

            if(m_low[i] < m_high[m_last] - m_depthPrice)
            {
               if(m_open[i] < m_close[i]) m_zzH[m_last] = m_high[m_last];
               else                        m_direction = -1;
               m_zzL[i] = m_low[i];
            }
         }

         if(m_low[i] < m_zzH[m_last] - m_depthPrice &&
            (!set || m_open[i] > m_close[i]))
         {
            m_zzL[i] = m_low[i];
            if(m_high[i] > m_zzL[i] + m_depthPrice && m_open[i] < m_close[i])
               m_zzH[i] = m_high[i];
            else
               m_direction = -1;
            m_last = i;
         }
      }
      else   // m_direction < 0, seeking new low
      {
         if(m_low[i] < m_zzL[m_last])
         {
            m_zzL[m_last] = 0.0;
            m_zzL[i]      = m_low[i];
            m_last = i;
            set = true;

            if(m_high[i] > m_low[m_last] + m_depthPrice)
            {
               if(m_open[i] > m_close[i]) m_zzL[m_last] = m_low[m_last];
               else                        m_direction = 1;
               m_zzH[i] = m_high[i];
            }
         }

         if(m_high[i] > m_zzL[m_last] + m_depthPrice &&
            (!set || m_open[i] < m_close[i]))
         {
            m_zzH[i] = m_high[i];
            if(m_low[i] < m_zzH[i] - m_depthPrice && m_open[i] > m_close[i])
               m_zzL[i] = m_low[i];
            else
               m_direction = 1;
            m_last = i;
         }
      }
   }

   BuildCache();   // [Patch #4]
}

//+------------------------------------------------------------------+
//| [Patch #4] Build strictly-alternating pivot cache, newest first  |
//+------------------------------------------------------------------+
void CZigZagEngine::BuildCache()
{
   SZZNode tmp[];   // built oldest-first, then reversed
   int n = 0;

   for(int i = m_bars - 1; i >= 1; i--)
   {
      bool h = (m_zzH[i] > 0.0), l = (m_zzL[i] > 0.0);
      if(!h && !l) continue;

      // [Patch #3] When both flags are set on one bar, pick the type that maintains alternation
      bool isHigh;
      if(h && l) isHigh = (n == 0) ? true : !tmp[n - 1].isHigh;
      else       isHigh = h;

      double p = isHigh ? m_zzH[i] : m_zzL[i];

      // Merge consecutive same-type pivots: keep the more extreme one
      if(n > 0 && tmp[n - 1].isHigh == isHigh)
      {
         if((isHigh && p > tmp[n - 1].price) ||
            (!isHigh && p < tmp[n - 1].price))
         {
            tmp[n - 1].price = p;
            tmp[n - 1].time  = m_time[i];
            tmp[n - 1].index = i;
         }
         continue;
      }

      ArrayResize(tmp, n + 1);
      tmp[n].price  = p;
      tmp[n].time   = m_time[i];
      tmp[n].index  = i;
      tmp[n].isHigh = isHigh;
      n++;
   }

   // Reverse so index 0 = newest
   ArrayResize(m_cache, n);
   for(int k = 0; k < n; k++) m_cache[k] = tmp[n - 1 - k];
   m_cacheCount = n;
}

//+------------------------------------------------------------------+
//| GetNodes — fills caller array from the cache (newest first)      |
//+------------------------------------------------------------------+
int CZigZagEngine::GetNodes(int maxCount, SZZNode &nodes[]) const
{
   int cnt = MathMin(maxCount, m_cacheCount);
   ArrayResize(nodes, cnt);
   for(int i = 0; i < cnt; i++) nodes[i] = m_cache[i];
   return cnt;
}

//+------------------------------------------------------------------+
//| GetLast4Nodes — fills 4 nodes from the cache                     |
//+------------------------------------------------------------------+
bool CZigZagEngine::GetLast4Nodes(SZZNode &nodes[]) const
{
   if(m_cacheCount < 4) return false;
   ArrayResize(nodes, 4);
   for(int i = 0; i < 4; i++) nodes[i] = m_cache[i];
   return true;
}

//+------------------------------------------------------------------+
//| Simple pivot accessors (now backed by cache)                     |
//+------------------------------------------------------------------+
double   CZigZagEngine::GetLastHigh()     const { for(int i=0;i<m_cacheCount;i++) if( m_cache[i].isHigh) return m_cache[i].price; return 0.0; }
double   CZigZagEngine::GetLastLow()      const { for(int i=0;i<m_cacheCount;i++) if(!m_cache[i].isHigh) return m_cache[i].price; return 0.0; }
double   CZigZagEngine::GetPrevHigh()     const { int c=0; for(int i=0;i<m_cacheCount;i++) if( m_cache[i].isHigh&&++c==2) return m_cache[i].price; return 0.0; }
double   CZigZagEngine::GetPrevLow()      const { int c=0; for(int i=0;i<m_cacheCount;i++) if(!m_cache[i].isHigh&&++c==2) return m_cache[i].price; return 0.0; }
datetime CZigZagEngine::GetLastHighTime() const { for(int i=0;i<m_cacheCount;i++) if( m_cache[i].isHigh) return m_cache[i].time;  return 0; }
datetime CZigZagEngine::GetLastLowTime()  const { for(int i=0;i<m_cacheCount;i++) if(!m_cache[i].isHigh) return m_cache[i].time;  return 0; }

bool CZigZagEngine::IsHigherHigh() const { return GetLastHigh() > GetPrevHigh(); }
bool CZigZagEngine::IsHigherLow()  const { return GetLastLow()  > GetPrevLow();  }
bool CZigZagEngine::IsLowerHigh()  const { return GetLastHigh() < GetPrevHigh(); }
bool CZigZagEngine::IsLowerLow()   const { return GetLastLow()  < GetPrevLow();  }

//+------------------------------------------------------------------+
ENUM_TREND_STATE CZigZagEngine::GetTrendState() const
{
   SZZNode nodes[];
   if(!GetLast4Nodes(nodes)) return TREND_RANGE;

   if(nodes[0].isHigh)
   {
      if(nodes[0].price > nodes[2].price && nodes[1].price > nodes[3].price)
         return TREND_UPTREND;
   }
   else
   {
      if(nodes[0].price < nodes[2].price && nodes[1].price < nodes[3].price)
         return TREND_DOWNTREND;
   }
   return TREND_RANGE;
}

//+------------------------------------------------------------------+
double CZigZagEngine::GetH1ATR() const
{
   static int    h1_handle     = INVALID_HANDLE;
   static string cached_symbol = "";
   if(h1_handle == INVALID_HANDLE || cached_symbol != m_symbol)
   {
      if(h1_handle != INVALID_HANDLE) IndicatorRelease(h1_handle);
      h1_handle     = iATR(m_symbol, PERIOD_H1, 14);
      cached_symbol = m_symbol;
   }
   double buf[1];
   if(h1_handle != INVALID_HANDLE && CopyBuffer(h1_handle, 0, 1, 1, buf) > 0)
      return buf[0];
   return 100 * _Point;
}

//+------------------------------------------------------------------+
bool CZigZagEngine::IsPullbackToHL(double currentPrice, double atr_mult) const
{
   SZZNode nodes[];
   if(!GetLast4Nodes(nodes)) return false;
   if(nodes[0].isHigh) return false;

   SSymbolProfile prof = CSymbolProfile::Get(m_symbol);
   double mult = (atr_mult > 0.0) ? atr_mult : prof.hl_variance_atr_mult;
   double distance = MathAbs(currentPrice - nodes[0].price);
   return (distance <= GetH1ATR() * mult);
}

bool CZigZagEngine::IsPullbackToLH(double currentPrice, double atr_mult) const
{
   SZZNode nodes[];
   if(!GetLast4Nodes(nodes)) return false;
   if(!nodes[0].isHigh) return false;

   SSymbolProfile prof = CSymbolProfile::Get(m_symbol);
   double mult = (atr_mult > 0.0) ? atr_mult : prof.hl_variance_atr_mult;
   double distance = MathAbs(currentPrice - nodes[0].price);
   return (distance <= GetH1ATR() * mult);
}

//+------------------------------------------------------------------+
void CZigZagEngine::PrintNodes() const
{
   PrintFormat("CZigZagEngine [%s %s]: %d cached pivots | LastHigh=%.5f LastLow=%.5f",
               m_symbol, EnumToString(m_tf), m_cacheCount,
               GetLastHigh(), GetLastLow());
}

#endif // CZIGZAGENGINE_MQH
