//+------------------------------------------------------------------+
//|  C_ATRModule.mqh — Average True Range (ATR) Module              |
//|  Sprint 1: The Eyes                                              |
//+------------------------------------------------------------------+
#ifndef C_ATRMODULE_MQH
#define C_ATRMODULE_MQH

class C_ATRModule
{
private:
   string   m_symbol;
   int      m_period;
   int      m_handle_Current;
   int      m_handle_H1;
   int      m_handle_H4;
   int      m_handle_D1;
   int      m_handle_W1;
   double   m_atr_Current;
   double   m_atr_H1;
   double   m_atr_H4;
   double   m_atr_D1;
   double   m_atr_W1;

   bool     FetchATR(const int handle, double &out_value);

public:
            C_ATRModule();
           ~C_ATRModule();

   bool     Init(const string symbol, const int period);
   void     Deinit();
   void     Update();
   double   GetATR(const ENUM_TIMEFRAMES tf) const;
   bool     GetATRBuffer(const ENUM_TIMEFRAMES tf, const int count, double &out_buffer[]) const;
};

//--- Constructor
C_ATRModule::C_ATRModule()
   : m_handle_Current(INVALID_HANDLE),
     m_handle_H1(INVALID_HANDLE),
     m_handle_H4(INVALID_HANDLE),
     m_handle_D1(INVALID_HANDLE),
     m_handle_W1(INVALID_HANDLE),
     m_atr_Current(0.0), m_atr_H1(0.0), m_atr_H4(0.0),
     m_atr_D1(0.0), m_atr_W1(0.0) {}

//--- Destructor
C_ATRModule::~C_ATRModule() { Deinit(); }

//--- Create indicator handles for all 5 timeframes
bool C_ATRModule::Init(const string symbol, const int period)
{
   m_symbol = symbol;
   m_period = period;

   m_handle_Current = iATR(symbol, PERIOD_CURRENT, period);
   m_handle_H1      = iATR(symbol, PERIOD_H1,      period);
   m_handle_H4      = iATR(symbol, PERIOD_H4,      period);
   m_handle_D1      = iATR(symbol, PERIOD_D1,      period);
   m_handle_W1      = iATR(symbol, PERIOD_W1,      period);

   if(m_handle_Current == INVALID_HANDLE ||
      m_handle_H1      == INVALID_HANDLE ||
      m_handle_H4      == INVALID_HANDLE ||
      m_handle_D1      == INVALID_HANDLE ||
      m_handle_W1      == INVALID_HANDLE)
   {
      PrintFormat("[ERROR] %s: One or more ATR handles invalid. Symbol: %s",
                  __FUNCTION__, symbol);
      return false;
   }
   return true;
}

//--- Release all indicator handles
void C_ATRModule::Deinit()
{
   if(m_handle_Current != INVALID_HANDLE) { IndicatorRelease(m_handle_Current); m_handle_Current = INVALID_HANDLE; }
   if(m_handle_H1      != INVALID_HANDLE) { IndicatorRelease(m_handle_H1);      m_handle_H1      = INVALID_HANDLE; }
   if(m_handle_H4      != INVALID_HANDLE) { IndicatorRelease(m_handle_H4);      m_handle_H4      = INVALID_HANDLE; }
   if(m_handle_D1      != INVALID_HANDLE) { IndicatorRelease(m_handle_D1);      m_handle_D1      = INVALID_HANDLE; }
   if(m_handle_W1      != INVALID_HANDLE) { IndicatorRelease(m_handle_W1);      m_handle_W1      = INVALID_HANDLE; }
}

//--- Safe single-bar buffer read
bool C_ATRModule::FetchATR(const int handle, double &out_value)
{
   if(handle == INVALID_HANDLE) return false;
   
   // FIXED: Changed static double buf[1] to dynamic for CopyBuffer compatibility
   double buf[];
   ArrayResize(buf, 1);
   ArraySetAsSeries(buf, true);
   if(CopyBuffer(handle, 0, 1, 1, buf) < 1) return false;
   out_value = buf[0];
   return true;
}

//--- Refresh all ATR values (call once per new bar)
void C_ATRModule::Update()
{
   FetchATR(m_handle_Current, m_atr_Current);
   FetchATR(m_handle_H1,      m_atr_H1);
   FetchATR(m_handle_H4,      m_atr_H4);
   FetchATR(m_handle_D1,      m_atr_D1);
   FetchATR(m_handle_W1,      m_atr_W1);
}

//--- Get ATR value for a specific timeframe
double C_ATRModule::GetATR(const ENUM_TIMEFRAMES tf) const
{
   switch(tf)
   {
      case PERIOD_H1: return m_atr_H1;
      case PERIOD_H4: return m_atr_H4;
      case PERIOD_D1: return m_atr_D1;
      case PERIOD_W1: return m_atr_W1;
      default:        return m_atr_Current;
   }
}

//--- Fetch historical ATR buffer without creating new handles
bool C_ATRModule::GetATRBuffer(const ENUM_TIMEFRAMES tf, const int count, double &out_buffer[]) const
{
   int handle = INVALID_HANDLE;
   switch(tf)
   {
      case PERIOD_H1: handle = m_handle_H1; break;
      case PERIOD_H4: handle = m_handle_H4; break;
      case PERIOD_D1: handle = m_handle_D1; break;
      case PERIOD_W1: handle = m_handle_W1; break;
      default:        handle = m_handle_Current; break;
   }
   
   if(handle == INVALID_HANDLE) return false;
   
   ArraySetAsSeries(out_buffer, true);
   if(CopyBuffer(handle, 0, 1, count, out_buffer) < count) return false;
   
   return true;
}

#endif // C_ATRMODULE_MQH
