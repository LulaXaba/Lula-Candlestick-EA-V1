//+------------------------------------------------------------------+
//| CMarketContext.mqh                                               |
//| V2 Context Hub — replaces CStateMachine                          |
//| Merges ZigZag structure, KAMA dynamic S/R, and Zone Data         |
//+------------------------------------------------------------------+
#ifndef CMARKETCONTEXT_MQH
#define CMARKETCONTEXT_MQH

#include "..\Include\Defines.mqh"
#include "..\Include\DTOs.mqh"
#include "..\Sprint1_Sensors\CZigZagEngine.mqh"
#include "..\Sprint1_Sensors\C_KAMAModule.mqh"
// TODO: Include V1 Zone/ATR modules as needed

class CMarketContext
{
private:
   string            m_symbol;
   ENUM_TIMEFRAMES   m_tf;
   
   CZigZagEngine*    m_zigzagH4;
   CZigZagEngine*    m_zigzagD1;
   CZigZagEngine*    m_zigzagW1;
   C_KAMAModule*     m_kama;
   // TODO: CPriceZone* or C_ATRModule* references here
   
   SSensorData       m_data;
   ENUM_TREND_STATE  m_trendState;

public:
   CMarketContext();
  ~CMarketContext();

   bool              Init(string symbol, ENUM_TIMEFRAMES tf);
   void              Deinit();
   void              Update();
   
   SSensorData       GetData() const { return m_data; }
   ENUM_TREND_STATE  GetTrendState() const { return m_trendState; }
   
   // Direct accessors to the underlying engines
   CZigZagEngine*    ZigZagH4() const { return m_zigzagH4; }
   C_KAMAModule*     KAMA()   const { return m_kama; }
};

//+------------------------------------------------------------------+
CMarketContext::CMarketContext() : m_symbol(""), m_tf(PERIOD_CURRENT), 
   m_zigzagH4(NULL), m_zigzagD1(NULL), m_zigzagW1(NULL), m_kama(NULL)
{
   ZeroMemory(m_data);
   m_trendState = TREND_RANGE;
}

CMarketContext::~CMarketContext()
{
   Deinit();
}

//+------------------------------------------------------------------+
bool CMarketContext::Init(string symbol, ENUM_TIMEFRAMES tf)
{
   m_symbol = symbol;
   m_tf = tf;
   
   m_zigzagH4 = new CZigZagEngine();
   if(!m_zigzagH4.Init(m_symbol, PERIOD_H4, ZIGZAG_DEPTH))
   {
      Print("[ERROR] CMarketContext failed to init ZigZag H4");
      return false;
   }
   
   m_zigzagD1 = new CZigZagEngine();
   if(!m_zigzagD1.Init(m_symbol, PERIOD_D1, ZIGZAG_DEPTH))
   {
      Print("[ERROR] CMarketContext failed to init ZigZag D1");
      return false;
   }
   
   m_zigzagW1 = new CZigZagEngine();
   if(!m_zigzagW1.Init(m_symbol, PERIOD_W1, ZIGZAG_DEPTH))
   {
      Print("[ERROR] CMarketContext failed to init ZigZag W1");
      return false;
   }
   
   m_kama = new C_KAMAModule();
   // Note: KAMA period usually driven by D1 or H4, using 14 as default for now
   if(!m_kama.Init(m_symbol, 14)) 
   {
      Print("[ERROR] CMarketContext failed to init KAMA");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
void CMarketContext::Deinit()
{
   if(m_zigzagH4 != NULL) { delete m_zigzagH4; m_zigzagH4 = NULL; }
   if(m_zigzagD1 != NULL) { delete m_zigzagD1; m_zigzagD1 = NULL; }
   if(m_zigzagW1 != NULL) { delete m_zigzagW1; m_zigzagW1 = NULL; }
   if(m_kama != NULL)     { delete m_kama;     m_kama = NULL; }
}

//+------------------------------------------------------------------+
void CMarketContext::Update()
{
   // 1. Update engines
   if(m_zigzagH4) m_zigzagH4.Update();
   if(m_zigzagD1) m_zigzagD1.Update();
   if(m_zigzagW1) m_zigzagW1.Update();
   if(m_kama)     m_kama.Update();
   
   // 2. Fetch structural state
   if(m_zigzagH4) m_trendState = m_zigzagH4.GetTrendState();
   
   // 3. Populate SSensorData (to pass to Trade Evaluator)
   ZeroMemory(m_data);
   
   m_data.trendState = m_trendState;
   if(m_zigzagH4) m_data.trendH4 = m_zigzagH4.GetTrendState();
   if(m_zigzagD1) m_data.trendD1 = m_zigzagD1.GetTrendState();
   if(m_zigzagW1) m_data.trendW1 = m_zigzagW1.GetTrendState();
   
   if(m_kama)
   {
      m_data.kama = m_kama.GetKAMA();
      // Calculate slope or other KAMA metrics if needed
   }
   
   // TODO: Fill zone data and ATR data from remaining sensors
}

#endif // CMARKETCONTEXT_MQH
