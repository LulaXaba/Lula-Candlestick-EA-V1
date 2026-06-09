//+------------------------------------------------------------------+
//|                                               CPatternEngine.mqh |
//|                             Lula Price Action Execution Engine V1|
//+------------------------------------------------------------------+
#ifndef CPATTERNENGINE_MQH
#define CPATTERNENGINE_MQH

#include "CPatternResult.mqh"
#include "..\Sprint1_Sensors\CSensorArray.mqh"
#include "Detectors\C_PinBarDetector.mqh"

class CPatternEngine
  {
private:
   double               m_pinbar_wick_ratio;
   int                  m_min_score;
   datetime             m_last_bar_time;
   
   CPatternResult* m_latest_result;
   C_PinBarDetector* m_pinbar_detector;

   bool                 IsNewBar();

public:
                        CPatternEngine();
                       ~CPatternEngine();

   bool                 Init(double pinbar_ratio, int min_score);
   void                 Deinit();

   //--- Main Execution
   CPatternResult* ScanForPattern(CSensorArray* sensor);

   //--- Core Candlestick Math Utility
   static int           Cmp(double price1, double price2, double point_tolerance);
  };

CPatternEngine::CPatternEngine() : m_pinbar_wick_ratio(0.65), m_min_score(70), m_last_bar_time(0)
  {
   m_latest_result = new CPatternResult();
   m_pinbar_detector = new C_PinBarDetector();
  }

CPatternEngine::~CPatternEngine()
  {
   Deinit();
  }

bool CPatternEngine::Init(double pinbar_ratio, int min_score)
  {
   m_pinbar_wick_ratio = pinbar_ratio;
   m_min_score         = min_score;
   
   if(m_pinbar_detector != NULL) m_pinbar_detector.Init(_Symbol, m_pinbar_wick_ratio, m_min_score);
   
   return true;
  }

void CPatternEngine::Deinit()
  {
   if(m_latest_result != NULL) { delete m_latest_result; m_latest_result = NULL; }
   if(m_pinbar_detector != NULL) { delete m_pinbar_detector; m_pinbar_detector = NULL; }
  }

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

int CPatternEngine::Cmp(double price1, double price2, double point_tolerance)
  {
   if(MathAbs(price1 - price2) <= point_tolerance) return 0;
   if(price1 > price2) return 1;
   return -1;
  }

CPatternResult* CPatternEngine::ScanForPattern(CSensorArray* sensor)
  {
   if(sensor == NULL) return m_latest_result;
   
   // Strictly enforce Closed Bar Rule
   if(!IsNewBar()) return m_latest_result;
   
   m_latest_result.Clear();
   
   //--- DETECTOR 1: PIN BAR
   // Index 1 = Last closed candle
   if(m_pinbar_detector.Detect(1, sensor, m_latest_result))
     {
      // If detected and validated via scoring, return the result
      return m_latest_result;
     }
     
   // TODO: Inject remaining 6 Detectors here
   
   return m_latest_result;
  }

#endif
