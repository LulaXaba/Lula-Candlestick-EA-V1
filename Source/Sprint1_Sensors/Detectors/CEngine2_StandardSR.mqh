//+------------------------------------------------------------------+
//|  CEngine2_StandardSR.mqh — Engine 2: Standard S/R Levels        |
//|  Sprint 1: The Sensor Array                                      |
//|                                                                  |
//|  Responsibility: Identify classic horizontal Support and         |
//|  Resistance levels based on swing highs and lows.               |
//+------------------------------------------------------------------+
#ifndef CENGINE2_STANDARDSR_MQH
#define CENGINE2_STANDARDSR_MQH

#include "../../Include/Defines.mqh"
#include "../../Include/DTOs.mqh"

class CEngine2_StandardSR
{
private:
   string   m_symbol;
   int      m_lookback;
   double   m_nearestResistance;
   double   m_nearestSupport;
   bool     m_isAtResistance;
   bool     m_isAtSupport;

   void     ScanSwingLevels();
   bool     IsSwingHigh(const int barIndex) const;
   bool     IsSwingLow(const int barIndex)  const;

public:
            CEngine2_StandardSR();
           ~CEngine2_StandardSR();

   bool     Init(const string symbol, const int lookback);
   void     Deinit();

   // Called by CSensorArray::Update() — runs the StandardSR() scan
   void     StandardSR();

   double   GetNearestResistance() const { return m_nearestResistance; }
   double   GetNearestSupport()    const { return m_nearestSupport;    }
   bool     IsAtResistance()       const { return m_isAtResistance;    }
   bool     IsAtSupport()          const { return m_isAtSupport;       }
};

CEngine2_StandardSR::CEngine2_StandardSR()
   : m_lookback(100),
     m_nearestResistance(0.0),
     m_nearestSupport(0.0),
     m_isAtResistance(false),
     m_isAtSupport(false) {}

CEngine2_StandardSR::~CEngine2_StandardSR() { Deinit(); }

bool CEngine2_StandardSR::Init(const string symbol, const int lookback)
{
   m_symbol   = symbol;
   m_lookback = lookback;
   return true;
}

void CEngine2_StandardSR::Deinit() {}

void CEngine2_StandardSR::StandardSR()
{
   ScanSwingLevels();
}

void CEngine2_StandardSR::ScanSwingLevels()
{
   // TODO Sprint 1: Implement swing high/low detection
   // Algorithm:
   // 1. Scan m_lookback bars for swing highs (local maxima) and swing lows (local minima)
   // 2. A swing high: bar[i].High > bar[i-1].High && bar[i].High > bar[i+1].High
   // 3. A swing low:  bar[i].Low  < bar[i-1].Low  && bar[i].Low  < bar[i+1].Low
   // 4. Find nearest resistance above current price
   // 5. Find nearest support below current price
   // 6. Set m_isAtResistance / m_isAtSupport within ATR proximity tolerance

   m_nearestResistance = 0.0;
   m_nearestSupport    = 0.0;
   m_isAtResistance    = false;
   m_isAtSupport       = false;
}

bool CEngine2_StandardSR::IsSwingHigh(const int barIndex) const
{
   // TODO Sprint 1: 3-bar swing high detection (expand to 5-bar for stronger levels)
   if(barIndex < 1 || barIndex >= m_lookback) return false;
   double hi   = iHigh(m_symbol, PERIOD_H4, barIndex);
   double hiL  = iHigh(m_symbol, PERIOD_H4, barIndex + 1);
   double hiR  = iHigh(m_symbol, PERIOD_H4, barIndex - 1);
   return (hi > hiL && hi > hiR);
}

bool CEngine2_StandardSR::IsSwingLow(const int barIndex) const
{
   // TODO Sprint 1: 3-bar swing low detection
   if(barIndex < 1 || barIndex >= m_lookback) return false;
   double lo   = iLow(m_symbol, PERIOD_H4, barIndex);
   double loL  = iLow(m_symbol, PERIOD_H4, barIndex + 1);
   double loR  = iLow(m_symbol, PERIOD_H4, barIndex - 1);
   return (lo < loL && lo < loR);
}

#endif // CENGINE2_STANDARDSR_MQH
