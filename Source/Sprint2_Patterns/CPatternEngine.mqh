//+------------------------------------------------------------------+
//|                                               CPatternEngine.mqh |
//|                             Lula Price Action Execution Engine V1|
//+------------------------------------------------------------------+
#ifndef CPATTERNENGINE_MQH
#define CPATTERNENGINE_MQH

#include "CPatternResult.mqh"
#include "..\Sprint1_Sensors\CSensorArray.mqh"

#include "Detectors\C_PinBarDetector.mqh"
#include "Detectors\C_EngulfingDetector.mqh"
#include "Detectors\C_InsideBarDetector.mqh"
#include "Detectors\C_FalseBreakoutDetector.mqh"
#include "Detectors\C_DblhcDbhlcDetector.mqh"
#include "Detectors\C_ForceBarDetector.mqh"

class CPatternEngine
  {
private:
   double               m_pinbar_wick_ratio;
   int                  m_min_score;
   datetime             m_last_bar_time;
   
   CPatternResult* m_latest_result;
   
   //--- Detectors
   C_PinBarDetector* m_pinbar_detector;
   C_EngulfingDetector* m_engulfing_detector;
   C_InsideBarDetector* m_insidebar_detector;
   C_FalseBreakoutDetector* m_fbo_detector;
   C_DblhcDbhlcDetector* m_dblhc_detector;
   C_ForceBarDetector* m_force_detector;

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
   m_latest_result      = new CPatternResult();
   m_pinbar_detector    = new C_PinBarDetector();
   m_engulfing_detector = new C_EngulfingDetector();
   m_insidebar_detector = new C_InsideBarDetector();
   m_fbo_detector       = new C_FalseBreakoutDetector();
   m_dblhc_detector     = new C_DblhcDbhlcDetector();
   m_force_detector     = new C_ForceBarDetector();
  }

CPatternEngine::~CPatternEngine()
  {
   Deinit();
  }

bool CPatternEngine::Init(double pinbar_ratio, int min_score)
  {
   m_pinbar_wick_ratio = pinbar_ratio;
   m_min_score         = min_score;
   
   if(m_pinbar_detector != NULL)    m_pinbar_detector.Init(_Symbol, m_pinbar_wick_ratio, m_min_score);
   if(m_engulfing_detector != NULL) m_engulfing_detector.Init(_Symbol, m_min_score);
   if(m_insidebar_detector != NULL) m_insidebar_detector.Init(_Symbol, m_min_score);
   if(m_fbo_detector != NULL)       m_fbo_detector.Init(_Symbol, m_min_score);
   if(m_dblhc_detector != NULL)     m_dblhc_detector.Init(_Symbol, m_min_score);
   if(m_force_detector != NULL)     m_force_detector.Init(_Symbol, m_min_score);
   
   return true;
  }

void CPatternEngine::Deinit()
  {
   if(m_latest_result != NULL)      { delete m_latest_result; m_latest_result = NULL; }
   if(m_pinbar_detector != NULL)    { delete m_pinbar_detector; m_pinbar_detector = NULL; }
   if(m_engulfing_detector != NULL) { delete m_engulfing_detector; m_engulfing_detector = NULL; }
   if(m_insidebar_detector != NULL) { delete m_insidebar_detector; m_insidebar_detector = NULL; }
   if(m_fbo_detector != NULL)       { delete m_fbo_detector; m_fbo_detector = NULL; }
   if(m_dblhc_detector != NULL)     { delete m_dblhc_detector; m_dblhc_detector = NULL; }
   if(m_force_detector != NULL)     { delete m_force_detector; m_force_detector = NULL; }
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
   
   //--- DETECTOR PRIORITY 1: ENGULFING BAR (Grade A)
   if(m_engulfing_detector.Detect(1, sensor, m_latest_result)) return m_latest_result;

   //--- DETECTOR PRIORITY 2: FALSE BREAKOUT (Grade A)
   if(m_fbo_detector.Detect(1, sensor, m_latest_result)) return m_latest_result;

   //--- DETECTOR PRIORITY 3: PIN BAR
   if(m_pinbar_detector.Detect(1, sensor, m_latest_result)) return m_latest_result;
     
   //--- DETECTOR PRIORITY 4: INSIDE BAR
   if(m_insidebar_detector.Detect(1, sensor, m_latest_result)) return m_latest_result;

   //--- DETECTOR PRIORITY 5: DBLHC / DBHLC
   if(m_dblhc_detector.Detect(1, sensor, m_latest_result)) return m_latest_result;

   //--- DETECTOR PRIORITY 6: FORCE BAR
   if(m_force_detector.Detect(1, sensor, m_latest_result)) return m_latest_result;
     
   // TODO: Inject remaining 1 Detector here (Star Patterns)
   
   return m_latest_result;
  }

#endif
