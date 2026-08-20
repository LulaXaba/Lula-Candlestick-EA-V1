//+------------------------------------------------------------------+
//| CZigZagEngine.mqh                                                |
//| FastZZ logic ported into EA-native class                         |
//| Reads H4 structure in real-time for trend definition             |
//+------------------------------------------------------------------+
#ifndef CZIGZAGENGINE_MQH
#define CZIGZAGENGINE_MQH

#include "..\Include\Defines.mqh"

//+------------------------------------------------------------------+
//| Pivot node struct                                                |
//+------------------------------------------------------------------+
struct SZZNode
{
   double price;      // Pivot price
   datetime time;     // Pivot time
   int    index;      // Bar index (0 = current)
   bool   isHigh;     // true = swing high, false = swing low
};

//+------------------------------------------------------------------+
//| ZigZag Engine — FastZZ algorithm ported                          |
//+------------------------------------------------------------------+
class CZigZagEngine
{
private:
   string   m_symbol;
   ENUM_TIMEFRAMES m_tf;
   int      m_depth;        // Minimum points in a ray (input)
   double   m_depthPrice;   // Converted to price
   int      m_last;         // Index of last confirmed pivot
   int      m_direction;    // 1 = seeking high, -1 = seeking low
   
   // Internal buffers (we maintain our own history)
   double   m_zzH[];        // Swing highs
   double   m_zzL[];        // Swing lows
   double   m_high[];       // Price history highs
   double   m_low[];        // Price history lows
   double   m_open[];       // Price history opens
   double   m_close[];      // Price history closes
   datetime m_time[];       // Bar times
   
   int      m_bars;         // Bars processed
   
   void     ResizeBuffers(int size);
   
public:
   CZigZagEngine();
   ~CZigZagEngine();
   
   bool     Init(string symbol, ENUM_TIMEFRAMES tf, int depthPoints);
   void     Update();       // Call every tick or on new bar
   
   //--- Accessors for V2 trend logic
   bool     GetLast4Nodes(SZZNode &nodes[]) const;     // Returns last 4 pivots
   double   GetLastHigh() const;
   double   GetLastLow() const;
   double   GetPrevHigh() const;    // 2nd last high
   double   GetPrevLow() const;     // 2nd last low
   datetime GetLastHighTime() const;
   datetime GetLastLowTime() const;
   
   //--- Trend state (the 4-node math)
   ENUM_TREND_STATE GetTrendState() const;
   bool     IsHigherHigh() const;
   bool     IsHigherLow() const;
   bool     IsLowerHigh() const;
   bool     IsLowerLow() const;
   
   //--- Pullback detection
   bool     IsPullbackToHL(double currentPrice, double variance) const;  // Long setup
   bool     IsPullbackToLH(double currentPrice, double variance) const;  // Short setup
   
   void     PrintNodes() const;     // Debug
};

//+------------------------------------------------------------------+
CZigZagEngine::CZigZagEngine() : m_symbol(""), m_tf(PERIOD_CURRENT),
   m_depth(1000), m_depthPrice(0), m_last(0), m_direction(1), m_bars(0) {}

CZigZagEngine::~CZigZagEngine() {}

//+------------------------------------------------------------------+
bool CZigZagEngine::Init(string symbol, ENUM_TIMEFRAMES tf, int depthPoints)
{
   m_symbol = symbol;
   m_tf = tf;
   m_depth = depthPoints;
   m_depthPrice = depthPoints * SymbolInfoDouble(symbol, SYMBOL_POINT);
   m_direction = 1;
   m_last = 0;
   m_bars = 0;
   
   ArraySetAsSeries(m_zzH, true);
   ArraySetAsSeries(m_zzL, true);
   ArraySetAsSeries(m_high, true);
   ArraySetAsSeries(m_low, true);
   ArraySetAsSeries(m_open, true);
   ArraySetAsSeries(m_close, true);
   ArraySetAsSeries(m_time, true);
   
   // Initial historical load
   Update();
   return true;
}

//+------------------------------------------------------------------+
void CZigZagEngine::ResizeBuffers(int size)
{
   ArrayResize(m_zzH, size);
   ArrayResize(m_zzL, size);
   ArrayResize(m_high, size);
   ArrayResize(m_low, size);
   ArrayResize(m_open, size);
   ArrayResize(m_close, size);
   ArrayResize(m_time, size);
}

//+------------------------------------------------------------------+
void CZigZagEngine::Update()
{
   int total = iBars(m_symbol, m_tf);
   if(total == 0) return;
   
   // Resize if needed
   if(total != m_bars)
   {
      ResizeBuffers(total);
      m_bars = total;
   }
   
   // Copy price data
   CopyHigh(m_symbol, m_tf, 0, total, m_high);
   CopyLow(m_symbol, m_tf, 0, total, m_low);
   CopyOpen(m_symbol, m_tf, 0, total, m_open);
   CopyClose(m_symbol, m_tf, 0, total, m_close);
   CopyTime(m_symbol, m_tf, 0, total, m_time);
   
   // Reset and recalculate all pivots
   ArrayInitialize(m_zzH, 0.0);
   ArrayInitialize(m_zzL, 0.0);
   m_last = 0;
   m_direction = 1;
   
   for(int i = 0; i < total - 1; i++)
   {
      bool set = false;
      m_zzL[i] = 0.0;
      m_zzH[i] = 0.0;
      
      if(m_direction > 0)  // Seeking new high
      {
         // Update running high
         if(m_high[i] > m_zzH[m_last])
         {
            m_zzH[m_last] = 0.0;  // Clear old pivot
            m_zzH[i] = m_high[i]; // New running high
            m_last = i;
            set = true;
            
            // Check for reversal: low dropped below high - depth
            if(m_low[i] < m_high[m_last] - m_depthPrice)
            {
               // Confirm the high pivot
               if(m_open[i] < m_close[i]) 
                  m_zzH[m_last] = m_high[m_last]; 
               else 
                  m_direction = -1;
               
               // Start new low pivot
               m_zzL[i] = m_low[i];
            }
         }
         
         // Alternative reversal check
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
      else  // m_direction < 0, seeking new low
      {
         // Update running low
         if(m_low[i] < m_zzL[m_last])
         {
            m_zzL[m_last] = 0.0;
            m_zzL[i] = m_low[i];
            m_last = i;
            set = true;
            
            // Check for reversal: high rose above low + depth
            if(m_high[i] > m_low[m_last] + m_depthPrice)
            {
               if(m_open[i] > m_close[i])
                  m_zzL[m_last] = m_low[m_last];
               else
                  m_direction = 1;
               
               m_zzH[i] = m_high[i];
            }
         }
         
         // Alternative reversal check
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
}

//+------------------------------------------------------------------+
//| Get the last 4 ZigZag nodes                                      |
//+------------------------------------------------------------------+
bool CZigZagEngine::GetLast4Nodes(SZZNode &nodes[]) const
{
   ArrayResize(nodes, 4);
   int found = 0;
   
   for(int i = 1; i < m_bars && found < 4; i++)
   {
      if(m_zzH[i] > 0)
      {
         nodes[found].price = m_zzH[i];
         nodes[found].time = m_time[i];
         nodes[found].index = i;
         nodes[found].isHigh = true;
         found++;
      }
      else if(m_zzL[i] > 0)
      {
         nodes[found].price = m_zzL[i];
         nodes[found].time = m_time[i];
         nodes[found].index = i;
         nodes[found].isHigh = false;
         found++;
      }
   }
   
   return (found == 4);
}

//+------------------------------------------------------------------+
//| Determine the current structural trend state                       |
//+------------------------------------------------------------------+
ENUM_TREND_STATE CZigZagEngine::GetTrendState() const
{
   SZZNode nodes[];
   if(!GetLast4Nodes(nodes)) return TREND_RANGE;
   
   // Needs to evaluate sequence: HL/HH or LH/LL
   // nodes[0] is most recent. If nodes[0] is High, nodes[1] is Low, nodes[2] is High, nodes[3] is Low
   if(nodes[0].isHigh)
   {
      // nodes[0]=HH, nodes[1]=HL, nodes[2]=LH, nodes[3]=LL
      if(nodes[0].price > nodes[2].price && nodes[1].price > nodes[3].price)
         return TREND_UPTREND;
   }
   else
   {
      // nodes[0]=LL, nodes[1]=LH, nodes[2]=HL, nodes[3]=HH
      if(nodes[0].price < nodes[2].price && nodes[1].price < nodes[3].price)
         return TREND_DOWNTREND;
   }
   
   return TREND_RANGE;
}

//+------------------------------------------------------------------+
//| Stub accessors for individual pivots                             |
//+------------------------------------------------------------------+
double CZigZagEngine::GetLastHigh() const { 
   for(int i=1; i<m_bars; i++) if(m_zzH[i]>0) return m_zzH[i]; 
   return 0; 
}
double CZigZagEngine::GetLastLow() const { 
   for(int i=1; i<m_bars; i++) if(m_zzL[i]>0) return m_zzL[i]; 
   return 0; 
}
double CZigZagEngine::GetPrevHigh() const { 
   int c=0; 
   for(int i=1; i<m_bars; i++) { 
      if(m_zzH[i]>0) { c++; if(c==2) return m_zzH[i]; } 
   } 
   return 0; 
}
double CZigZagEngine::GetPrevLow() const { 
   int c=0; 
   for(int i=1; i<m_bars; i++) { 
      if(m_zzL[i]>0) { c++; if(c==2) return m_zzL[i]; } 
   } 
   return 0; 
}
datetime CZigZagEngine::GetLastHighTime() const { 
   for(int i=1; i<m_bars; i++) if(m_zzH[i]>0) return m_time[i]; 
   return 0; 
}
datetime CZigZagEngine::GetLastLowTime() const { 
   for(int i=1; i<m_bars; i++) if(m_zzL[i]>0) return m_time[i]; 
   return 0; 
}

bool CZigZagEngine::IsHigherHigh() const { return GetLastHigh() > GetPrevHigh(); }
bool CZigZagEngine::IsHigherLow() const  { return GetLastLow() > GetPrevLow(); }
bool CZigZagEngine::IsLowerHigh() const  { return GetLastHigh() < GetPrevHigh(); }
bool CZigZagEngine::IsLowerLow() const   { return GetLastLow() < GetPrevLow(); }

bool CZigZagEngine::IsPullbackToHL(double currentPrice, double variance) const {
   if(GetTrendState() != TREND_UPTREND) return false;
   return (MathAbs(currentPrice - GetLastLow()) <= variance);
}
bool CZigZagEngine::IsPullbackToLH(double currentPrice, double variance) const {
   if(GetTrendState() != TREND_DOWNTREND) return false;
   return (MathAbs(currentPrice - GetLastHigh()) <= variance);
}

void CZigZagEngine::PrintNodes() const {
   PrintFormat("CZigZagEngine: LastHigh=%.5f, LastLow=%.5f", GetLastHigh(), GetLastLow());
}
#endif // CZIGZAGENGINE_MQH
