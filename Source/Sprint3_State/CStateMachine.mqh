//+------------------------------------------------------------------+
//|                                                CStateMachine.mqh |
//|                             Lula Price Action Execution Engine V1|
//+------------------------------------------------------------------+
#ifndef CSTATEMACHINE_MQH
#define CSTATEMACHINE_MQH

#include "..\Include\Defines.mqh"
#include "..\Include\DTOs.mqh"
#include "..\Sprint1_Sensors\CSensorArray.mqh"

// Forward declarations for sub-analyzers (to be built next)
class C_TrendAnalyzer;
class C_RangeAnalyzer;
class C_ChoppyFilter;
class C_RetracementDetector;
class C_AlignmentScorer;

class CStateMachine
  {
private:
   string                  m_symbol;
   SMarketState            m_current_state;
   datetime                m_last_update_time;

   //--- Sub-Analyzers
   C_TrendAnalyzer* m_trend_analyzer;
   C_RangeAnalyzer* m_range_analyzer;
   C_ChoppyFilter* m_choppy_filter;
   C_RetracementDetector* m_retracement_detector;
   C_AlignmentScorer* m_alignment_scorer;

   bool                    IsNewBar();

public:
                           CStateMachine();
                          ~CStateMachine();

   bool                    Init(const string symbol = NULL);
   void                    Deinit();

   //--- Main Execution
   void                    Update(const SSensorData &sensor_data);
   
   //--- Accessors
   SMarketState            GetState() const { return m_current_state; }
  };

CStateMachine::CStateMachine() : m_symbol(""), m_last_update_time(0)
  {
   ZeroMemory(m_current_state);
   m_current_state.state = STATE_UNDEFINED;
   
   // Initialize pointers to NULL until the files are built
   m_trend_analyzer       = NULL;
   m_range_analyzer       = NULL;
   m_choppy_filter        = NULL;
   m_retracement_detector = NULL;
   m_alignment_scorer     = NULL;
  }

CStateMachine::~CStateMachine()
  {
   Deinit();
  }

bool CStateMachine::Init(const string symbol)
  {
   m_symbol = (symbol == NULL) ? _Symbol : symbol;
   
   // TODO: Instantiate sub-analyzers here as we build them:
   // m_choppy_filter = new C_ChoppyFilter();
   // m_choppy_filter.Init(m_symbol);
   
   return true;
  }

void CStateMachine::Deinit()
  {
   if(m_trend_analyzer != NULL)       { delete m_trend_analyzer; m_trend_analyzer = NULL; }
   if(m_range_analyzer != NULL)       { delete m_range_analyzer; m_range_analyzer = NULL; }
   if(m_choppy_filter != NULL)        { delete m_choppy_filter; m_choppy_filter = NULL; }
   if(m_retracement_detector != NULL) { delete m_retracement_detector; m_retracement_detector = NULL; }
   if(m_alignment_scorer != NULL)     { delete m_alignment_scorer; m_alignment_scorer = NULL; }
  }

bool CStateMachine::IsNewBar()
  {
   datetime current_time = iTime(m_symbol, PERIOD_CURRENT, 0);
   if(current_time != m_last_update_time)
     {
      m_last_update_time = current_time;
      return true;
     }
   return false;
  }

void CStateMachine::Update(const SSensorData &sensor_data)
  {
   // The State Machine evaluates the global picture once per bar
   if(!IsNewBar()) return;
   
   // Default reset
   ZeroMemory(m_current_state);
   m_current_state.state = STATE_UNDEFINED;

   //---------------------------------------------------------
   // STATE EVALUATION CASCADE (To be implemented with sub-analyzers)
   //---------------------------------------------------------
   
   // Step 1: Check for Choppy/Un-tradeable conditions first (ADX < 20)
   // if(m_choppy_filter.IsChoppy()) { m_current_state.state = STATE_CHOPPY; return; }
   
   // Step 2: Check for Ranging Market (Price bouncing between tight S/R bounds)
   // if(m_range_analyzer.IsRanging(sensor_data)) { m_current_state.state = STATE_RANGING; }

   // Step 3: Check for Trend Phase (Impulse vs Retracement)
   // m_trend_analyzer.Evaluate(sensor_data, m_current_state);
   // m_retracement_detector.Evaluate(sensor_data, m_current_state);
   
   // Step 4: Calculate Timeframe Alignment Score (0-100)
   // m_current_state.alignmentScore = m_alignment_scorer.CalculateScore(sensor_data);

  }

#endif
