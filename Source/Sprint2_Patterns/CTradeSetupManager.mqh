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

enum ENUM_ENTRY_MODEL
{
    MODEL_NONE = 0,
    MODEL_PULLBACK = 1,
    MODEL_BREAKOUT_RETEST = 2,
    MODEL_HTF_REVERSAL = 3
};

class CTradeSetupManager
{
private:
   CTradeExecutor* m_executor;
   CRiskManager*   m_risk;

public:
   CTradeSetupManager(CTradeExecutor* exec, CRiskManager* risk) : m_executor(exec), m_risk(risk) {}
   ~CTradeSetupManager() {}
   
   ENUM_ENTRY_MODEL ClassifySetup(const SPatternResult &pattern, const SSensorData &context)
   {
      // P1: Classify the setup based on structural context.
      // Currently defaults to Pullback if trend aligns.
      if(pattern.direction == DIRECTION_LONG && context.trendState == TREND_UPTREND)
         return MODEL_PULLBACK;
      if(pattern.direction == DIRECTION_SHORT && context.trendState == TREND_DOWNTREND)
         return MODEL_PULLBACK;
      
      return MODEL_NONE;
   }
   
   bool IsFullAlignment(const SSensorData &context, ENUM_TRADE_DIRECTION dir)
   {
      if(dir == DIRECTION_LONG)
         return (context.trendH4 == TREND_UPTREND && context.trendD1 == TREND_UPTREND && context.trendW1 == TREND_UPTREND);
      else if(dir == DIRECTION_SHORT)
         return (context.trendH4 == TREND_DOWNTREND && context.trendD1 == TREND_DOWNTREND && context.trendW1 == TREND_DOWNTREND);
         
      return false;
   }
   
   void EvaluateAndExecute(SPatternResult &pattern, const SSensorData &context)
   {
      // P2: Full Alignment Gate
      if(!IsFullAlignment(context, pattern.direction))
      {
         Print("[Trade Setup] Rejecting: Multi-Timeframe ZigZag alignment failed (H4, D1, W1 do not agree).");
         return;
      }
      
      // P2: Gap Open Rule
      double currentOpen = iOpen(Symbol(), PERIOD_H1, 0);
      double gapDistance = MathAbs(currentOpen - pattern.entryPrice) / _Point;
      if(context.atr_H1 > 0 && gapDistance > (context.atr_H1 * 0.5 / _Point))
      {
         PrintFormat("[Trade Setup] Rejecting: Gap Open Rule. Open %f is too far from entry zone %f.", currentOpen, pattern.entryPrice);
         return;
      }
      // 0. Classify Entry Model
      ENUM_ENTRY_MODEL entryModel = ClassifySetup(pattern, context);
      if(entryModel == MODEL_NONE)
      {
         Print("[Trade Setup] Rejecting: Could not classify entry model.");
         return;
      }
      
      // 1. Grade the confluence
      pattern.confluenceGrade = ConfluenceGrader::Grade(pattern, context);
      
      if(pattern.confluenceGrade == GRADE_REJECT) 
      {
         PrintFormat("[Trade Setup] Setup rejected due to insufficient confluence.");
         return;
      }
      
      // 1.5 KAMA Momentum Veto (P1)
      if(context.kama > 0)
      {
         if(pattern.direction == DIRECTION_LONG && pattern.entryPrice < context.kama)
         {
            if(pattern.entryPrice < context.kama - (10.0 * _Point))
            {
               Print("[V2 VETO] Price well below KAMA. Rejecting long entry.");
               return;
            }
            else
            {
               Print("[V2 VETO] Price crossed below KAMA. Reducing lot by 50%.");
               pattern.confluenceGrade = GRADE_C;
            }
         }
         else if(pattern.direction == DIRECTION_SHORT && pattern.entryPrice > context.kama)
         {
            if(pattern.entryPrice > context.kama + (10.0 * _Point))
            {
               Print("[V2 VETO] Price well above KAMA. Rejecting short entry.");
               return;
            }
            else
            {
               Print("[V2 VETO] Price crossed above KAMA. Reducing lot by 50%.");
               pattern.confluenceGrade = GRADE_C;
            }
         }
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
