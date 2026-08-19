//+------------------------------------------------------------------+
//| CTradeSetupManager.mqh                                           |
//| V2: Evaluates entry models and routes to executor                |
//+------------------------------------------------------------------+
#ifndef CTRADESETUPMANAGER_MQH
#define CTRADESETUPMANAGER_MQH

#include "..\Include\DTOs.mqh"
#include "ConfluenceGrader.mqh"
#include "..\Sprint4_Execution\CTradeExecutor.mqh"
#include "..\Sprint4_Execution\CRiskManager.mqh"

class CTradeSetupManager
{
private:
   CTradeExecutor* m_executor;
   CRiskManager*   m_risk;

public:
   CTradeSetupManager(CTradeExecutor* exec, CRiskManager* risk) : m_executor(exec), m_risk(risk) {}
   ~CTradeSetupManager() {}
   
   void EvaluateAndExecute(SPatternResult &pattern, const SSensorData &context)
   {
      // 1. Grade the confluence
      pattern.confluenceGrade = ConfluenceGrader::Grade(pattern, context);
      
      if(pattern.confluenceGrade == GRADE_REJECT) 
      {
         PrintFormat("[Trade Setup] Setup rejected due to insufficient confluence.");
         return;
      }
      
      // 2. Risk Management (Calculate lot size and apply grade scaling)
      double baseLot = m_risk.CalculateLotSize(pattern.entryPrice, pattern.stopLoss);
      double finalLot = m_risk.ApplyConfluenceLotMultiplier(baseLot, pattern.confluenceGrade);
      
      // 3. Execution
      if(finalLot > 0) 
      {
         PrintFormat("[Trade Setup] Executing Grade %d setup with %.2f lots.", pattern.confluenceGrade, finalLot);
         m_executor.ExecuteTrade(pattern, finalLot);
      }
   }
};

#endif // CTRADESETUPMANAGER_MQH
