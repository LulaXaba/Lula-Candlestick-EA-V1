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
      {
         bool h4_align = (context.trendH4 == TREND_UPTREND);
         bool d1_align = (context.trendD1 == TREND_UPTREND || context.trendD1 == TREND_RANGE);
         bool w1_align = (context.trendW1 != TREND_DOWNTREND);
         return (h4_align && d1_align && w1_align);
      }
      else if(dir == DIRECTION_SHORT)
      {
         bool h4_align = (context.trendH4 == TREND_DOWNTREND);
         bool d1_align = (context.trendD1 == TREND_DOWNTREND || context.trendD1 == TREND_RANGE);
         bool w1_align = (context.trendW1 != TREND_UPTREND);
         return (h4_align && d1_align && w1_align);
      }
         
      return false;
   }
   
   void EvaluateAndExecute(SPatternResult &pattern, const SSensorData &context)
   {
      Print("[SETUP DEBUG] Scanning for setup...");
      
      // Gate 1: Alignment
      if(!IsFullAlignment(context, pattern.direction))
      {
         PrintFormat("[SETUP DEBUG] BLOCKED: IsFullAlignment() = false (H4=%s D1=%s W1=%s Dir=%s)",
                     EnumToString(context.trendH4), EnumToString(context.trendD1), EnumToString(context.trendW1),
                     EnumToString(pattern.direction));
         return;
      }
      Print("[SETUP DEBUG] PASSED: Full alignment");
      
      // P2: Gap Open Rule
      double currentOpen = iOpen(Symbol(), PERIOD_H1, 0);
      double gapDistance = MathAbs(currentOpen - pattern.entryPrice) / _Point;
      if(context.atr_H1 > 0 && gapDistance > (context.atr_H1 * 0.5 / _Point))
      {
         PrintFormat("[SETUP DEBUG] BLOCKED: Gap Open Rule. Open %f is too far from entry zone %f.", currentOpen, pattern.entryPrice);
         return;
      }
      
      // 0. Classify Entry Model
      ENUM_ENTRY_MODEL entryModel = ClassifySetup(pattern, context);
      if(entryModel == MODEL_NONE)
      {
         Print("[SETUP DEBUG] BLOCKED: Could not classify entry model.");
         return;
      }
      PrintFormat("[SETUP DEBUG] PASSED: Entry Model=%s", EnumToString(entryModel));
      
      // 1. Grade the confluence
      pattern.confluenceGrade = ConfluenceGrader::Grade(pattern, context);
      
      if(pattern.confluenceGrade == GRADE_REJECT) 
      {
         Print("[SETUP DEBUG] BLOCKED: Grade = REJECT");
         return;
      }
      PrintFormat("[SETUP DEBUG] PASSED: Grade=%s", EnumToString(pattern.confluenceGrade));
      
      // 1.5 KAMA Momentum Veto (P1)
      if(context.kama > 0)
      {
         if(pattern.direction == DIRECTION_LONG && pattern.entryPrice < context.kama)
         {
            if(pattern.entryPrice < context.kama - (10.0 * _Point))
            {
               Print("[SETUP DEBUG] BLOCKED: Price well below KAMA.");
               return;
            }
            else
            {
               Print("[SETUP DEBUG] WARNING: Price crossed below KAMA. Reducing lot by 50%.");
               pattern.confluenceGrade = GRADE_C;
            }
         }
         else if(pattern.direction == DIRECTION_SHORT && pattern.entryPrice > context.kama)
         {
            if(pattern.entryPrice > context.kama + (10.0 * _Point))
            {
               Print("[SETUP DEBUG] BLOCKED: Price well above KAMA.");
               return;
            }
            else
            {
               Print("[SETUP DEBUG] WARNING: Price crossed above KAMA. Reducing lot by 50%.");
               pattern.confluenceGrade = GRADE_C;
            }
         }
      }
      
      // 2. Risk Management (Calculate lot size and apply grade scaling)
      double baseLot = m_risk.CalculateLotSize(pattern.entryPrice, pattern.stopLoss);
      double finalLot = m_risk.ApplyConfluenceLotMultiplier(baseLot, pattern.confluenceGrade);
      
      if(finalLot <= 0)
      {
         PrintFormat("[SETUP DEBUG] BLOCKED: Final lot size <= 0 (base=%.2f)", baseLot);
         return;
      }
      
      PrintFormat("[SETUP DEBUG] *** SETUP VALID *** Executing Grade %s setup with %.2f lots.", 
                  EnumToString(pattern.confluenceGrade), finalLot);
      m_executor.ExecuteTrade(pattern, finalLot);
   }
};

#endif // CTRADESETUPMANAGER_MQH
