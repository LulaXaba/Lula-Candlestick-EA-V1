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
   if(!g_context.Init(_Symbol, PERIOD_CURRENT)) return INIT_FAILED;
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
   // PHASE 0: ROLLOVER FREEZE (P2)
   // No new trades between broker time 23:55–00:05. Spread protection.
   //================================================================
   MqlDateTime dt;
   TimeCurrent(dt);
   if((dt.hour == 23 && dt.min >= 55) || (dt.hour == 0 && dt.min <= 5))
   {
      // If we still want active trade monitoring to happen during rollover, 
      // we should put this block AFTER Phase 1. 
      // Actually, monitoring is fine, but entry is what we want to prevent.
      // We'll let Phase 1 run, but return after it.
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
   // PHASE 4: PATTERN DETECTION
   // Note: Pattern engine to be updated to accept SSensorData instead of V1 CSensorArray
   //================================================================
   SPatternResult pattern_dto; 
   // pattern_dto = g_patterns.Scan(contextData); 

   //================================================================
   // PHASE 5: EVALUATE & EXECUTE
   // CTradeSetupManager grades the confluence and routes to executor
   //================================================================
   if(pattern_dto.IsValid())
   {
      g_setupManager.EvaluateAndExecute(pattern_dto, contextData);
   }
}
