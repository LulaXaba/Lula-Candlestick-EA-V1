//+------------------------------------------------------------------+
//|  C_SwingDetector.mqh — Swing High / Low Fractal Engine           |
//|  Sprint 1: The Sensor Array                                      |
//|                                                                  |
//|  Responsibility: Identifies strict fractal swing highs and lows  |
//|  using a parameterized left and right bar lookback logic.        |
//+------------------------------------------------------------------+
#ifndef C_SWINGDETECTOR_MQH
#define C_SWINGDETECTOR_MQH

#include "../Include/Defines.mqh"

class C_SwingDetector
{
private:
   int              m_leftBars;
   int              m_rightBars;
   ENUM_TIMEFRAMES  m_timeframe;
   string           m_symbol;

public:
                    C_SwingDetector(int left_bars = 3, int right_bars = 3, ENUM_TIMEFRAMES tf = PERIOD_CURRENT);
                   ~C_SwingDetector();

   bool             Init(const string symbol);
   void             Deinit();

   bool             IsSwingHigh(int index) const;
   bool             IsSwingLow(int index) const;
};

C_SwingDetector::C_SwingDetector(int left_bars = 3, int right_bars = 3, ENUM_TIMEFRAMES tf = PERIOD_CURRENT)
   : m_leftBars(left_bars),
     m_rightBars(right_bars),
     m_timeframe(tf),
     m_symbol(_Symbol)
{
}

C_SwingDetector::~C_SwingDetector()
{
   Deinit();
}

bool C_SwingDetector::Init(const string symbol)
{
   m_symbol = symbol;
   return true;
}

void C_SwingDetector::Deinit()
{
}

bool C_SwingDetector::IsSwingHigh(int index) const
{
   if(index < m_rightBars) return false; // Not enough right-side bars closed yet

   double centerHigh = iHigh(m_symbol, m_timeframe, index);
   if(centerHigh == 0.0) return false;

   // Check left bars (older candles -> index + i)
   for(int i = 1; i <= m_leftBars; i++)
   {
      double leftHigh = iHigh(m_symbol, m_timeframe, index + i);
      if(leftHigh >= centerHigh || leftHigh == 0.0) return false;
   }

   // Check right bars (newer candles -> index - i)
   for(int i = 1; i <= m_rightBars; i++)
   {
      double rightHigh = iHigh(m_symbol, m_timeframe, index - i);
      if(rightHigh >= centerHigh || rightHigh == 0.0) return false;
   }

   return true;
}

bool C_SwingDetector::IsSwingLow(int index) const
{
   if(index < m_rightBars) return false; // Not enough right-side bars closed yet

   double centerLow = iLow(m_symbol, m_timeframe, index);
   if(centerLow == 0.0) return false;

   // Check left bars (older candles -> index + i)
   for(int i = 1; i <= m_leftBars; i++)
   {
      double leftLow = iLow(m_symbol, m_timeframe, index + i);
      if(leftLow <= centerLow || leftLow == 0.0) return false;
   }

   // Check right bars (newer candles -> index - i)
   for(int i = 1; i <= m_rightBars; i++)
   {
      double rightLow = iLow(m_symbol, m_timeframe, index - i);
      if(rightLow <= centerLow || rightLow == 0.0) return false;
   }

   return true;
}

#endif // C_SWINGDETECTOR_MQH
