//+------------------------------------------------------------------+
//|  C_KAMAModule.mqh — Kaufman Adaptive Moving Average Module       |
//|  Sprint 1: The Eyes                                              |
//+------------------------------------------------------------------+
#ifndef C_KAMAMODULE_MQH
#define C_KAMAMODULE_MQH

#include "../Include/Defines.mqh"

class C_KAMAModule
{
private:
   string   m_symbol;
   int      m_period;
   int      m_handle;
   double   m_kama;

public:
            C_KAMAModule();
           ~C_KAMAModule();

   bool     Init(const string symbol, const int period);
   void     Deinit();
   void     Update();
   double   GetKAMA()      const { return m_kama; }
};

C_KAMAModule::C_KAMAModule() : m_handle(INVALID_HANDLE), m_kama(0.0), m_period(14) {}
C_KAMAModule::~C_KAMAModule() { Deinit(); }

bool C_KAMAModule::Init(const string symbol, const int period)
{
   m_symbol = symbol;
   m_period = period;
   // iAMA = Adaptive Moving Average (Kaufman) built into MQL5
   // KAMA_FAST_PERIOD and KAMA_SLOW_PERIOD come from Defines.mqh
   m_handle = iAMA(symbol, PERIOD_CURRENT, period,
                   KAMA_FAST_PERIOD, KAMA_SLOW_PERIOD, 0, PRICE_CLOSE);
   if(m_handle == INVALID_HANDLE)
   {
      PrintFormat("[ERROR] %s: KAMA handle invalid. Symbol: %s", __FUNCTION__, symbol);
      return false;
   }
   return true;
}

void C_KAMAModule::Deinit()
{
   if(m_handle != INVALID_HANDLE)
   {
      IndicatorRelease(m_handle);
      m_handle = INVALID_HANDLE;
   }
}

void C_KAMAModule::Update()
{
   if(m_handle == INVALID_HANDLE) return;
   
   // FIXED: Changed static double buf[1] to dynamic for CopyBuffer compatibility
   double buf[];
   ArrayResize(buf, 1);
   ArraySetAsSeries(buf, true);
   if(CopyBuffer(m_handle, 0, 1, 1, buf) >= 1)
      m_kama = buf[0];
   // If data unavailable, keep previous value — do not reset to 0
}

#endif // C_KAMAMODULE_MQH
