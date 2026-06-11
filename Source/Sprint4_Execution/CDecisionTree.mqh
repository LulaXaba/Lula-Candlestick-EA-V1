//+------------------------------------------------------------------+
//|                                              CDecisionTree.mqh   |
//|                             Lula Price Action Execution Engine V1|
//+------------------------------------------------------------------+
#ifndef CDECISIONTREE_MQH
#define CDECISIONTREE_MQH

#include "..\Include\Defines.mqh"
#include "..\Include\DTOs.mqh"

// Forward declaration of the Risk Manager (to be built next)
class CRiskManager;

class CDecisionTree
  {
private:
   string            m_symbol;
   int               m_min_pattern_score;

   //--- Rejection Logger
   void              LogRejection(int gateId, string reason);

   //--- The 7 Sequential Gates
   bool              Gate1_WeeklyBiasDefined(const SSensorData &sensor);
   bool              Gate2_DailyAlignment(const SSensorData &sensor);
   bool              Gate3_AtKeyZone(const SSensorData &sensor);
   bool              Gate4_PatternDetected(const SPatternResult &pattern);
   bool              Gate5_1HStructureValid(const SPatternResult &pattern, const SMarketState &state);
   bool              Gate6_RiskRewardMet(const SPatternResult &pattern, CRiskManager* risk_manager);
   bool              Gate7_DrawdownSafe(CRiskManager* risk_manager);

public:
                     CDecisionTree();
                    ~CDecisionTree();

   bool              Init(const string symbol, int min_pattern_score);
   
   //--- Main Execution Evaluation
   bool              Evaluate(const SSensorData &sensor, const SPatternResult &pattern, const SMarketState &state, CRiskManager* risk_manager);
  };

CDecisionTree::CDecisionTree() : m_symbol(""), m_min_pattern_score(70) {}
CDecisionTree::~CDecisionTree() {}

bool CDecisionTree::Init(const string symbol, int min_pattern_score)
  {
   m_symbol = symbol;
   m_min_pattern_score = min_pattern_score;
   return true;
  }

void CDecisionTree::LogRejection(int gateId, string reason)
  {
   PrintFormat("[Lula V1] GATE %d REJECTED — %s", gateId, reason);
  }

//===================================================================
// GATE 1: Weekly Bias Defined
//===================================================================
bool CDecisionTree::Gate1_WeeklyBiasDefined(const SSensorData &sensor)
  {
   return (sensor.weeklyBias == BIAS_BULLISH || sensor.weeklyBias == BIAS_BEARISH);
  }

//===================================================================
// GATE 2: Daily Alignment & Wick Rejection
//===================================================================
bool CDecisionTree::Gate2_DailyAlignment(const SSensorData &sensor)
  {
   // Index 1 = Last CLOSED daily candle
   double dOpen  = iOpen(m_symbol, PERIOD_D1, 1);
   double dClose = iClose(m_symbol, PERIOD_D1, 1);
   double dHigh  = iHigh(m_symbol, PERIOD_D1, 1);
   double dLow   = iLow(m_symbol, PERIOD_D1, 1);
   
   double range = MathAbs(dHigh - dLow);
   if(range <= 0) return false;

   bool isBullishDay = (dClose > dOpen);
   bool isBearishDay = (dClose < dOpen);

   // Alignment check
   if(sensor.weeklyBias == BIAS_BULLISH && !isBullishDay) return false;
   if(sensor.weeklyBias == BIAS_BEARISH && !isBearishDay) return false;

   // Wick Rejection Rule (Wick against the bias must be < 60% of total range)
   if(sensor.weeklyBias == BIAS_BULLISH)
     {
      double upperWick = dHigh - MathMax(dOpen, dClose);
      if((upperWick / range) >= DAILY_REJECTION_WICK_PCT) return false;
     }
   else if(sensor.weeklyBias == BIAS_BEARISH)
     {
      double lowerWick = MathMin(dOpen, dClose) - dLow;
      if((lowerWick / range) >= DAILY_REJECTION_WICK_PCT) return false;
     }

   return true;
  }

//===================================================================
// GATE 3: At Key Zone (Major or Higher)
//===================================================================
bool CDecisionTree::Gate3_AtKeyZone(const SSensorData &sensor)
  {
   return (sensor.isAtSupplyZone || sensor.isAtDemandZone) && (sensor.zoneRank >= RANK_MAJOR);
  }

//===================================================================
// GATE 4: Pattern Detected & Scored
//===================================================================
bool CDecisionTree::Gate4_PatternDetected(const SPatternResult &pattern)
  {
   return (pattern.patternType != PATTERN_NONE && pattern.confidenceScore >= m_min_pattern_score);
  }

//===================================================================
// GATE 5: 1H Structure Valid (With Grade A Bypass)
//===================================================================
bool CDecisionTree::Gate5_1HStructureValid(const SPatternResult &pattern, const SMarketState &state)
  {
   // THE GRADE A OVERRIDE: Institutional displacement bypasses localized chop
   if(pattern.isGradeA) return true;
   
   // Standard Gate 5 Rules
   if(state.isChoppy) return false;
   if(state.alignmentScore < 70) return false;
   
   // (Sprint 4 TODO: BoS/CHoCH mapping would inject here if needed later)
   
   return true;
  }

//===================================================================
// GATE 6: Risk:Reward Met
//===================================================================
bool CDecisionTree::Gate6_RiskRewardMet(const SPatternResult &pattern, CRiskManager* risk_manager)
  {
   if(risk_manager == NULL) return false;
   if(pattern.stopLoss <= 0 || pattern.takeProfit <= 0) return false;
   
   // We will build GetMinRR() into CRiskManager next
   // return (pattern.rrRatio >= risk_manager.GetMinRR()); 
   
   // Fallback stub until Risk Manager is implemented
   return (pattern.rrRatio >= 2.0); 
  }

//===================================================================
// GATE 7: Drawdown Safe
//===================================================================
bool CDecisionTree::Gate7_DrawdownSafe(CRiskManager* risk_manager)
  {
   if(risk_manager == NULL) return false;
   
   // We will build IsDrawdownSafe() into CRiskManager next
   // return risk_manager.IsDrawdownSafe();
   
   return true; // Stub until Risk Manager is built
  }

//===================================================================
// MAIN ORCHESTRATOR EVALUATION
//===================================================================
bool CDecisionTree::Evaluate(const SSensorData &sensor, const SPatternResult &pattern, const SMarketState &state, CRiskManager* risk_manager)
  {
   if(!Gate1_WeeklyBiasDefined(sensor))
     {
      // We don't log Gate 1 constantly to avoid spamming the journal on every tick
      return false; 
     }

   if(!Gate2_DailyAlignment(sensor))
     {
      // LogRejection(2, "Daily candle conflicts with Weekly Bias or shows massive rejection wick.");
      return false;
     }

   if(!Gate3_AtKeyZone(sensor))
     {
      // LogRejection(3, "Price is not at a Major Supply/Demand Zone.");
      return false;
     }

   if(!Gate4_PatternDetected(pattern))
     {
      // LogRejection(4, "No valid institutional pattern detected >= Min Score.");
      return false;
     }

   if(!Gate5_1HStructureValid(pattern, state))
     {
      LogRejection(5, "1H Structure is Choppy or Alignment Score < 70 (No Grade A Bypass).");
      return false;
     }

   if(!Gate6_RiskRewardMet(pattern, risk_manager))
     {
      LogRejection(6, "Calculated Risk:Reward does not meet minimum threshold.");
      return false;
     }

   if(!Gate7_DrawdownSafe(risk_manager))
     {
      LogRejection(7, "Drawdown limit reached. Capital protection active.");
      return false;
     }

   Print("[Lula V1] All 7 gates PASSED — valid trade setup locked.");
   return true;
  }

#endif
