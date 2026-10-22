//+------------------------------------------------------------------+
//|                                                      Lula_V2.mq5 |
//|                             Lula Price Action Execution Engine V2|
//|                                   Copyright 2026, Lula Engineers |
//+------------------------------------------------------------------+
#property copyright   "Lula Engineering Team"
#property link        "https://github.com/your-repo"
#property version     "2.00"
#property description "Trend Structure Price Action EA — V2"
#property strict

//--- Core Definitions
#include "Include\Defines.mqh"
#include "Include\DTOs.mqh"

//--- V2 Architectures
#include "Sprint3_State\CMarketContext.mqh"
#include "Sprint2_Patterns\CPatternEngine.mqh"
#include "Sprint2_Patterns\CTradeSetupManager.mqh"
#include "Sprint4_Execution\CActiveTradeManager.mqh"
#include "Sprint4_Execution\CRiskManager.mqh"
#include "Sprint4_Execution\CTradeExecutor.mqh"

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
input group "=== 1. RISK MANAGEMENT ==="
input double inp_RiskPerTradePct  = 0.2;  // Risk per trade (%)
input double inp_MaxDailyDDPct    = 4.0;  // Max daily drawdown (%)
input double inp_MaxTotalDDPct    = 6.0;  // Max total drawdown (%)
input double inp_MinRRRatio       = 2.0;  // Min RR

input group "=== 2. EXECUTION ==="
input ulong  inp_MagicNumber      = 777777; 
input ulong  inp_Slippage         = 10;     

input group "=== 3. ZIGZAG & STRUCTURE ==="
input int    inp_ZZ_Depth_H4      = 5000;   // ZigZag Depth H4 (points)
input int    inp_ZZ_Depth_D1      = 10000;  // ZigZag Depth D1 (points)
input int    inp_ZZ_Depth_W1      = 20000;  // ZigZag Depth W1 (points)
input double inp_HL_Variance      = 500.0;  // Pullback Variance (points)

//+------------------------------------------------------------------+
//| GLOBAL SYSTEM POINTERS                                           |
//+------------------------------------------------------------------+
CMarketContext*      g_context;
CPatternEngine*      g_patterns;
CRiskManager*        g_risk;
CTradeExecutor*      g_executor;
CTradeSetupManager*  g_setupManager;
CActiveTradeManager* g_activeMonitor;

datetime        g_last_bar_time;

//+------------------------------------------------------------------+
//| EXPERT INITIALIZATION (BOOT SEQUENCE)                            |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("[Lula V2] Initiating V2 Boot Sequence...");

   //--- 1. Memory Allocation
   g_context       = new CMarketContext();
   g_patterns      = new CPatternEngine();
   g_risk          = new CRiskManager();
   g_executor      = new CTradeExecutor();
   
   //--- 2. Manager Allocation
   g_setupManager  = new CTradeSetupManager(g_executor, g_risk);
   g_activeMonitor = new CActiveTradeManager(_Symbol);

   //--- 3. Initialization
   if(!g_context.Init(_Symbol, PERIOD_CURRENT, inp_ZZ_Depth_H4, inp_ZZ_Depth_D1, inp_ZZ_Depth_W1)) return INIT_FAILED;
   if(!g_patterns.Init(0.65, 70)) return INIT_FAILED; 
   if(!g_risk.Init(_Symbol, inp_RiskPerTradePct, inp_MaxDailyDDPct, inp_MaxTotalDDPct, inp_MinRRRatio)) return INIT_FAILED;
   if(!g_executor.Init(_Symbol, inp_MagicNumber, inp_Slippage)) return INIT_FAILED;

   g_last_bar_time = 0;
   Print("[Lula V2] All V2 Engines Online.");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| EXPERT DEINITIALIZATION (SHUTDOWN SEQUENCE)                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   PrintFormat("[Lula V2] Shutting down. Reason: %d. Purging memory...", reason);

   if(g_context)       { delete g_context;       g_context = NULL; }
   if(g_patterns)      { g_patterns.Deinit(); delete g_patterns; g_patterns = NULL; }
   if(g_setupManager)  { delete g_setupManager;  g_setupManager = NULL; }
   if(g_activeMonitor) { delete g_activeMonitor; g_activeMonitor = NULL; }
   if(g_risk)          { delete g_risk;          g_risk = NULL; }
   if(g_executor)      { delete g_executor;      g_executor = NULL; }
   
   Print("[Lula V2] Shutdown complete.");
}

//+------------------------------------------------------------------+
//| EXPERT TICK FUNCTION (THE HEARTBEAT)                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //================================================================
   // TEMPORARY NUCLEAR TEST (Step 3)
   // Remove this block after confirming execution works
   //================================================================
   static bool testFired = false;
   if(!testFired && PositionsTotal() == 0)
   {
      testFired = true;
      
      CTrade test_trade;
      test_trade.SetExpertMagicNumber(inp_MagicNumber);
      test_trade.SetDeviationInPoints(inp_Slippage);
      test_trade.SetTypeFilling(ORDER_FILLING_FOK);
      
      double lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double sl  = bid - 1000 * _Point;
      double tp  = bid + 1000 * _Point;
      
      PrintFormat("[NUCLEAR TEST] Attempting BUY %.2f lots @ SL=%.2f TP=%.2f",
                  lot, sl, tp);
      
      bool ok = test_trade.Buy(lot, _Symbol, ask, sl, tp, "NUCLEAR_TEST");
      if(!ok && test_trade.ResultRetcode() == TRADE_RETCODE_INVALID_FILL)
      {
         test_trade.SetTypeFilling(ORDER_FILLING_IOC);
         ok = test_trade.Buy(lot, _Symbol, ask, sl, tp, "NUCLEAR_TEST");
      }
      
      if(!ok)
      {
         PrintFormat("[NUCLEAR TEST] FAILED: %d - %s",
                     test_trade.ResultRetcode(),
                     test_trade.ResultRetcodeDescription());
      }
      else
      {
         PrintFormat("[NUCLEAR TEST] SUCCESS: Ticket %I64u",
                     test_trade.ResultOrder());
      }
   }
   // === END NUCLEAR TEST ===

   //================================================================
   // PHASE 0: ROLLOVER FREEZE (P2)
   // No new trades between broker time 23:55–00:05. Spread protection.
   //================================================================
   MqlDateTime dt;
   TimeCurrent(dt);
   if((dt.hour == 23 && dt.min >= 55) || (dt.hour == 0 && dt.min <= 5))
   {
      // Rollover window
   }
   
   //================================================================
   // PHASE 1: ACTIVE TRADE MONITORING (V2)
   // Continuously evaluates open trades against H1/M15 health checks
   //================================================================
   if(g_context && g_activeMonitor)
   {
      g_activeMonitor.MonitorTrades(g_context.GetData());
   }

   //================================================================
   // PHASE 2: TIME-GATING & ROLLOVER FREEZE
   // Only scan for new setups on bar open
   //================================================================
   if((dt.hour == 23 && dt.min >= 55) || (dt.hour == 0 && dt.min <= 5)) return; // Rollover Freeze
   
   datetime current_bar_time = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(current_bar_time == g_last_bar_time) return;
   g_last_bar_time = current_bar_time;

   //================================================================
   // PHASE 3: CONTEXT ACQUISITION
   // Updates ZigZag, KAMA, and Static Zones
   //================================================================
   g_context.Update();
   SSensorData contextData = g_context.GetData();

   //================================================================
   // PHASE 4: PATTERN DETECTION & SETUP SCANNING
   //================================================================
   Print("[SETUP DEBUG] Scanning for setup...");
   
   // Gate 1: Alignment check debug
   if(contextData.trendH4 != contextData.trendD1 || contextData.trendH4 != contextData.trendW1)
   {
      PrintFormat("[SETUP DEBUG] BLOCKED: IsFullAlignment() = false (H4=%s D1=%s W1=%s)",
                  EnumToString(contextData.trendH4), EnumToString(contextData.trendD1), EnumToString(contextData.trendW1));
   }
   else
   {
      Print("[SETUP DEBUG] PASSED: Full alignment");
   }

   // Gate 2: Pullback check debug
   double checkPrice = iClose(_Symbol, PERIOD_CURRENT, 1);
   if(g_context && g_context.ZigZagH4())
   {
      bool atHL = g_context.ZigZagH4().IsPullbackToHL(checkPrice, inp_HL_Variance);
      bool atLH = g_context.ZigZagH4().IsPullbackToLH(checkPrice, inp_HL_Variance);
      if(!atHL && !atLH)
      {
         Print("[SETUP DEBUG] BLOCKED: Not at HL/LH");
      }
      else
      {
         PrintFormat("[SETUP DEBUG] PASSED: At %s", atHL ? "HL" : "LH");
      }
   }

   SPatternResult pattern_dto; 
   // pattern_dto = g_patterns.Scan(contextData); 

   //================================================================
   // PHASE 5: EVALUATE & EXECUTE
   // CTradeSetupManager grades the confluence and routes to executor
   //================================================================
   if(!pattern_dto.IsValid())
   {
      Print("[SETUP DEBUG] BLOCKED: No pattern");
   }
   else
   {
      PrintFormat("[SETUP DEBUG] PASSED: Pattern=%s", EnumToString(pattern_dto.patternType));
      g_setupManager.EvaluateAndExecute(pattern_dto, contextData);
   }
}
