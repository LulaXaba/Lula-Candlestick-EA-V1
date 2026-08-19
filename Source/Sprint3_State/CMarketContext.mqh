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
   
   CZigZagEngine*    m_zigzag;
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
   CZigZagEngine*    ZigZag() const { return m_zigzag; }
   C_KAMAModule*     KAMA()   const { return m_kama; }
};

//+------------------------------------------------------------------+
CMarketContext::CMarketContext() : m_symbol(""), m_tf(PERIOD_CURRENT), 
   m_zigzag(NULL), m_kama(NULL)
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
   
   m_zigzag = new CZigZagEngine();
   if(!m_zigzag.Init(m_symbol, m_tf, ZIGZAG_DEPTH))
   {
      Print("[ERROR] CMarketContext failed to init ZigZag");
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
   if(m_zigzag != NULL) { delete m_zigzag; m_zigzag = NULL; }
   if(m_kama != NULL)   { delete m_kama;   m_kama = NULL; }
}

//+------------------------------------------------------------------+
void CMarketContext::Update()
{
   // 1. Update engines
   if(m_zigzag) m_zigzag.Update();
   if(m_kama)   m_kama.Update();
   
   // 2. Fetch structural state
   if(m_zigzag) m_trendState = m_zigzag.GetTrendState();
   
   // 3. Populate SSensorData (to pass to Trade Evaluator)
   ZeroMemory(m_data);
   if(m_kama)
   {
      m_data.kama = m_kama.GetKAMA();
      // Calculate slope or other KAMA metrics if needed
   }
   
   // TODO: Fill zone data and ATR data from remaining sensors
}

#endif // CMARKETCONTEXT_MQH
