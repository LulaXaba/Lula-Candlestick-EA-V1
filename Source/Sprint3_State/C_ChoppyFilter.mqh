//+------------------------------------------------------------------+
//|                                              C_ChoppyFilter.mqh  |
//|                             Lula Price Action Execution Engine V1|
//+------------------------------------------------------------------+
#ifndef C_CHOPPYFILTER_MQH
#define C_CHOPPYFILTER_MQH

#include "..\Include\Defines.mqh"

class C_ChoppyFilter
  {
private:
   string            m_symbol;
   int               m_adx_handle;
   double            m_threshold;

public:
                     C_ChoppyFilter();
                    ~C_ChoppyFilter();

   bool              Init(const string symbol, const int period = 14, const double threshold = 20.0);
   void              Deinit();
   
   bool              IsChoppy();
   double            GetCurrentADX();
  };

C_ChoppyFilter::C_ChoppyFilter() : m_symbol(""), m_adx_handle(INVALID_HANDLE), m_threshold(20.0) {}

C_ChoppyFilter::~C_ChoppyFilter()
  {
   Deinit();
  }

bool C_ChoppyFilter::Init(const string symbol, const int period, const double threshold)
  {
   m_symbol = symbol;
   m_threshold = threshold;
   
   m_adx_handle = iADX(m_symbol, PERIOD_CURRENT, period);
   if(m_adx_handle == INVALID_HANDLE)
     {
      Print("[ERROR] C_ChoppyFilter: Failed to create ADX handle");
      return false;
     }
     
   return true;
  }

void C_ChoppyFilter::Deinit()
  {
   if(m_adx_handle != INVALID_HANDLE)
     {
      IndicatorRelease(m_adx_handle);
      m_adx_handle = INVALID_HANDLE;
     }
  }

double C_ChoppyFilter::GetCurrentADX()
  {
   if(m_adx_handle == INVALID_HANDLE) return -1.0;
   
   double buf[];
   ArrayResize(buf, 1);
   ArraySetAsSeries(buf, true);
   
   // Buffer 0 is the MAIN_LINE for iADX
   // We read index 1 (the last completely closed bar) to prevent repainting
   if(CopyBuffer(m_adx_handle, 0, 1, 1, buf) > 0)
     {
      return buf[0];
     }
     
   return -1.0; // Return -1 on copy failure
  }

bool C_ChoppyFilter::IsChoppy()
  {
   double adx = GetCurrentADX();
   
   // Fail-safe: If we lose data connection and can't read ADX, 
   // assume the market is choppy to protect capital and prevent blind entries.
   if(adx < 0) return true; 
   
   return (adx < m_threshold);
  }

#endif
