//+------------------------------------------------------------------+
//|  Lula_V1.mq5                                                     |
//|  Lula Price Action Execution Engine V1.0                         |
//|  Multi-Timeframe Candlestick EA — VIX75 & Forex                 |
//|                                                                  |
//|  Architecture: Weekly->Daily->4H->1H->15M                       |
//|  Entry Logic:  7-Gate Boolean Decision Tree                      |
//+------------------------------------------------------------------+
#property copyright   "Lula Trading Systems"
#property version     "1.00"
#property description "Multi-Timeframe Price Action EA — Weekly->Daily->4H->1H->15M"
#property strict

//--- Core definitions and shared DTOs
#include "Include/Defines.mqh"
#include "Include/DTOs.mqh"

//--- Sprint modules
#include "Sprint1_Sensors/CSensorArray.mqh"
#include "Sprint2_Patterns/CPatternEngine.mqh"
#include "Sprint3_State/CStateMachine.mqh"
#include "Sprint4_Execution/CDecisionTree.mqh"
#include "Sprint4_Execution/CRiskManager.mqh"
#include "Sprint4_Execution/CTradeExecutor.mqh"
#include "Sprint4_Execution/CCorrelationFilter.mqh"

//+------------------------------------------------------------------+
//| EA Input Parameters                                               |
//+------------------------------------------------------------------+
input group "=== Risk Management ==="
input double inp_RiskPercent        = 1.0;   // Risk per trade (% of balance)
input double inp_MaxDailyDrawdown   = 4.0;   // Max daily drawdown (%)
input double inp_MaxTotalDrawdown   = 6.0;   // Max total session drawdown (%)
input double inp_ATR_StopMultiplier = 1.5;   // ATR stop loss multiplier
input double inp_MinRR              = 2.0;   // Minimum Risk:Reward ratio

input group "=== Sensor Settings ==="
input int    inp_ATR_Period         = 14;    // ATR period (all timeframes)
input int    inp_KAMA_Period        = 14;    // KAMA / iAMA period
input int    inp_ZoneLookback       = 100;   // Bars to scan for S/D zones

input group "=== Pattern Settings ==="
input double inp_PinBar_WickRatio   = 0.65;  // Min wick-to-range ratio for Pin Bar
input int    inp_Pattern_MinScore   = 70;    // Min confidence score (0-100)

input group "=== Magic Number ==="
input ulong  inp_MagicNumber        = 20250101; // Unique EA magic number

//+------------------------------------------------------------------+
//| Module Instances (global — initialised in OnInit)                |
//+------------------------------------------------------------------+
CSensorArray        g_Sensors;
CPatternEngine      g_Patterns;
CStateMachine       g_StateMachine;
CDecisionTree       g_DecisionTree;
CRiskManager        g_RiskManager;
CTradeExecutor      g_Executor;
CCorrelationFilter  g_CorrFilter;

//+------------------------------------------------------------------+
//| OnInit — Initialise all modules in dependency order              |
//+------------------------------------------------------------------+
int OnInit()
{
   PrintFormat("[Lula V1] Initialising | Symbol: %s | TF: %s | Build: %d",
               _Symbol, EnumToString(_Period), TerminalInfoInteger(TERMINAL_BUILD));

   if(!g_Sensors.Init(_Symbol, inp_ATR_Period, inp_KAMA_Period, inp_ZoneLookback)) {
      Print("[ERROR] CSensorArray::Init() failed — EA shutting down.");
      return INIT_FAILED;
   }
   if(!g_Patterns.Init(inp_PinBar_WickRatio, inp_Pattern_MinScore)) {
      Print("[ERROR] CPatternEngine::Init() failed — EA shutting down.");
      return INIT_FAILED;
   }
   if(!g_StateMachine.Init()) {
      Print("[ERROR] CStateMachine::Init() failed — EA shutting down.");
      return INIT_FAILED;
   }
   if(!g_RiskManager.Init(inp_RiskPercent, inp_MaxDailyDrawdown,
                           inp_MaxTotalDrawdown, inp_ATR_StopMultiplier, inp_MinRR)) {
      Print("[ERROR] CRiskManager::Init() failed — EA shutting down.");
      return INIT_FAILED;
   }
   if(!g_Executor.Init(inp_MagicNumber)) {
      Print("[ERROR] CTradeExecutor::Init() failed — EA shutting down.");
      return INIT_FAILED;
   }
   if(!g_CorrFilter.Init()) {
      Print("[ERROR] CCorrelationFilter::Init() failed — EA shutting down.");
      return INIT_FAILED;
   }
   if(!g_DecisionTree.Init(&g_Sensors, &g_Patterns, &g_StateMachine,
                            &g_RiskManager, &g_Executor, &g_CorrFilter)) {
      Print("[ERROR] CDecisionTree::Init() failed — EA shutting down.");
      return INIT_FAILED;
   }

   Print("[Lula V1] All modules initialised successfully. Waiting for first bar...");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit — Clean up all modules in reverse init order            |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   g_DecisionTree.Deinit();
   g_CorrFilter.Deinit();
   g_Executor.Deinit();
   g_RiskManager.Deinit();
   g_StateMachine.Deinit();
   g_Patterns.Deinit();
   g_Sensors.Deinit();
   PrintFormat("[Lula V1] Deinitialised. Reason code: %d", reason);
}

//+------------------------------------------------------------------+
//| OnTick — Main logic loop (bar-close only)                        |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- New bar detection — all logic is bar-close based
   static datetime s_lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == s_lastBarTime) return;
   s_lastBarTime = currentBarTime;

   //--- Update all sensor data first (reads indicators, zones)
   g_Sensors.Update();

   //--- Derive market state from sensor data
   g_StateMachine.Update(g_Sensors.GetData());

   //--- Run the 7-gate decision tree
   //    If all gates pass, CTradeExecutor::PlaceTrade() is called internally
   g_DecisionTree.Evaluate();

   //--- Manage any open trades (trailing stop, partial close logic)
   g_Executor.ManageOpenTrades();
}

//+------------------------------------------------------------------+
//| OnTradeTransaction — Trade event handler                         |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest&     request,
                        const MqlTradeResult&      result)
{
   g_Executor.OnTradeTransaction(trans, request, result);
}
