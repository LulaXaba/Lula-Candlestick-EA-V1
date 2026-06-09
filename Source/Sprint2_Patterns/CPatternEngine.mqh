//+------------------------------------------------------------------+
//|                                               CPatternEngine.mqh |
//|                             Lula Price Action Execution Engine V1|
//+------------------------------------------------------------------+
#ifndef CPATTERNENGINE_MQH
#define CPATTERNENGINE_MQH

#include "CPatternResult.mqh"
#include "..\Sprint1_Sensors\CSensorArray.mqh"

class CPatternEngine
  {
private:
   double               m_pinbar_wick_ratio;
   int                  m_min_score;
   datetime             m_last_bar_time;

   CPatternResult*      m_latest_result;

   bool                 IsNewBar();

public:
                        CPatternEngine();
                       ~CPatternEngine();

   bool                 Init(double pinbar_ratio, int min_score);
   void                 Deinit();

   //--- Main Execution
   CPatternResult*      ScanForPattern(CSensorArray* sensor);

   //--- Core Candlestick Math Utility
   //    Returns  0 if |price1 - price2| <= point_tolerance  (mathematically "equal")
   //    Returns  1 if price1 is distinctly higher than price2
   //    Returns -1 if price1 is distinctly lower  than price2
   //    RULE: Never use raw == to compare doubles in MQL5 pattern geometry checks.
   static int           Cmp(double price1, double price2, double point_tolerance);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPatternEngine::CPatternEngine() : m_pinbar_wick_ratio(0.65), m_min_score(70), m_last_bar_time(0)
  {
   m_latest_result = new CPatternResult();
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CPatternEngine::~CPatternEngine()
  {
   Deinit();
  }

//+------------------------------------------------------------------+
//| Init — Store configuration from EA inputs                        |
//+------------------------------------------------------------------+
bool CPatternEngine::Init(double pinbar_ratio, int min_score)
  {
   m_pinbar_wick_ratio = pinbar_ratio;
   m_min_score         = min_score;
   return true;
  }

//+------------------------------------------------------------------+
//| Deinit — Release owned heap objects                              |
//+------------------------------------------------------------------+
void CPatternEngine::Deinit()
  {
   if(m_latest_result != NULL)
     {
      delete m_latest_result;
      m_latest_result = NULL;
     }
  }

//+------------------------------------------------------------------+
//| IsNewBar — Enforce closed-bar execution rule                     |
//+------------------------------------------------------------------+
bool CPatternEngine::IsNewBar()
  {
   datetime current_time = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(current_time != m_last_bar_time)
     {
      m_last_bar_time = current_time;
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Cmp — Floating-point tolerance comparator (static utility)       |
//+------------------------------------------------------------------+
int CPatternEngine::Cmp(double price1, double price2, double point_tolerance)
  {
   if(MathAbs(price1 - price2) <= point_tolerance) return  0; // Mathematically equal
   if(price1 > price2)                             return  1; // price1 distinctly higher
   return -1;                                                  // price1 distinctly lower
  }

//+------------------------------------------------------------------+
//| ScanForPattern — Main entry point called by CDecisionTree        |
//+------------------------------------------------------------------+
CPatternResult* CPatternEngine::ScanForPattern(CSensorArray* sensor)
  {
   if(sensor == NULL) return m_latest_result;

   // Strictly enforce Closed Bar Rule — no mid-candle signals
   if(!IsNewBar()) return m_latest_result;

   m_latest_result.Clear();

   // TODO: Inject the 7 Detectors here in Tier priority order:
   //   Tier 1: C_EngulfingDetector, C_FalseBreakoutDetector, C_ForceBarDetector, C_DoubleCandleDetector
   //   Tier 2: C_PinBarDetector, C_StarPatternDetector
   //   Tier 3: C_InsideBarDetector
   // First detector that fires populates m_latest_result via SetPattern() and returns.

   return m_latest_result;
  }

#endif
