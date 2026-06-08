//+------------------------------------------------------------------+
//|  Lula_V1.mq5                                                     |
//|  Lula Price Action Execution Engine V1.0                         |
//|  Multi-Timeframe Candlestick EA — VIX75 & Forex                  |
//|                                                                  |
//|  Architecture: Weekly->Daily->4H->1H->15M                        |
//|  Entry Logic:  7-Gate Boolean Decision Tree                      |
//+------------------------------------------------------------------+
#property copyright   "Lula Trading Systems"
#property version     "1.00"
#property description "Multi-Timeframe Price Action EA — Weekly->Daily->4H->1H->15M"
#property strict

//--- Core definitions and shared DTOs
#include "Include/Defines.mqh"
#include "Include/DTOs.mqh"

//--- Sprint 1 module (Active)
#include "Sprint1_Sensors/CSensorArray.mqh"

/* --- FUTURE SPRINTS (Commented out until built) ---
#include "Sprint2_Patterns/CPatternEngine.mqh"
#include "Sprint3_State/CStateMachine.mqh"
#include "Sprint4_Execution/CDecisionTree.mqh"
#include "Sprint4_Execution/CRiskManager.mqh"
#include "Sprint4_Execution/CTradeExecutor.mqh"
#include "Sprint4_Execution/CCorrelationFilter.mqh"
---------------------------------------------------*/

//+------------------------------------------------------------------+
//| EA Input Parameters                                              |
//+------------------------------------------------------------------+
input group "=== Risk Management ==="
input double inp_RiskPercent        = 1.0;     // Risk per trade (% of balance)
input double inp_MaxDailyDrawdown   = 4.0;     // Max daily drawdown (%)
input double inp_MaxTotalDrawdown   = 6.0;     // Max total session drawdown (%)
input double inp_ATR_StopMultiplier = 1.5;     // ATR stop loss multiplier
input double inp_MinRR              = 2.0;     // Minimum Risk:Reward ratio

input group "=== Sensor Settings ==="
input int    inp_ATR_Period         = 14;      // ATR period (all timeframes)
input int    inp_KAMA_Period        = 30;      // KAMA Slow period
input int    inp_ZoneLookback       = 500;     // Bars to scan for S/D zones

input group "=== Pattern Settings ==="
input double inp_PinBar_WickRatio   = 0.65;    // Min wick-to-range ratio for Pin Bar
input int    inp_Pattern_MinScore   = 70;      // Min confidence score (0-100)

input group "=== Magic Number ==="
input ulong  inp_MagicNumber        = 20250101; // Unique EA magic number

//+------------------------------------------------------------------+
//| Module Instances (global)                                        |
//+------------------------------------------------------------------+
CSensorArray        g_Sensors;

/* --- FUTURE INSTANCES ---
CPatternEngine      g_Patterns;
CStateMachine       g_StateMachine;
CDecisionTree       g_DecisionTree;
CRiskManager        g_RiskManager;
CTradeExecutor      g_Executor;
CCorrelationFilter  g_CorrFilter;
-------------------------*/

//+------------------------------------------------------------------+
//| OnInit — Initialise all modules in dependency order              |
//+------------------------------------------------------------------+
int OnInit()
{
   PrintFormat("[Lula V1] Initialising | Symbol: %s | TF: %s | Build: %d",
               _Symbol, EnumToString(_Period), TerminalInfoInteger(TERMINAL_BUILD));

   // Detect if running on a synthetic/volatility index for variance scaling
   bool is_vix = (StringFind(_Symbol, "75") >= 0 || StringFind(_Symbol, "10") >= 0 ||
                  StringFind(_Symbol, "25") >= 0 || StringFind(_Symbol, "50") >= 0 ||
                  StringFind(_Symbol, "100") >= 0 || StringFind(_Symbol, "Step") >= 0);

   // FIXED: Passing all 6 required parameters to CSensorArray
   if(!g_Sensors.Init(_Symbol, inp_ATR_Period, 2, inp_KAMA_Period, inp_ZoneLookback, is_vix)) {
      Print("[ERROR] CSensorArray::Init() failed — EA shutting down.");
      return INIT_FAILED;
   }

   /* --- FUTURE INITS ---
   if(!g_Patterns.Init(inp_PinBar_WickRatio, inp_Pattern_MinScore)) { ... }
   // ... other modules
   ---------------------*/

   Print("[Lula V1] Sensor Array initialised successfully. Waiting for first bar...");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit — Clean up all modules in reverse init order            |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   /* --- FUTURE DEINITS ---
   g_DecisionTree.Deinit();
   g_CorrFilter.Deinit();
   g_Executor.Deinit();
   g_RiskManager.Deinit();
   g_StateMachine.Deinit();
   g_Patterns.Deinit();
   -----------------------*/

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

   /* --- FUTURE LOGIC ---
   g_StateMachine.Update(g_Sensors.GetData(Close[0]));
   g_DecisionTree.Evaluate();
   g_Executor.ManageOpenTrades();
   ---------------------*/
}

//+------------------------------------------------------------------+
//| OnTradeTransaction — Trade event handler                         |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest&     request,
                        const MqlTradeResult&      result)
{
   // g_Executor.OnTradeTransaction(trans, request, result);
}
