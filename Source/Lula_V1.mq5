//+------------------------------------------------------------------+
//|                                                      Lula_V1.mq5 |
//|                             Lula Price Action Execution Engine V1|
//|                                   Copyright 2026, Lula Engineers |
//+------------------------------------------------------------------+
#property copyright   "Lula Engineering Team"
#property link        "https://github.com/your-repo"
#property version     "1.00"
#property description "Multi-Timeframe Price Action EA — Weekly->Daily->4H->1H->15M"
#property strict

//--- Core Definitions
#include "Include\Defines.mqh"
#include "Include\DTOs.mqh"

//--- Sprint Architectures
#include "Sprint1_Sensors\CSensorArray.mqh"
#include "Sprint2_Patterns\CPatternEngine.mqh"
#include "Sprint3_State\CStateMachine.mqh"
#include "Sprint4_Execution\CDecisionTree.mqh"
#include "Sprint4_Execution\CRiskManager.mqh"
#include "Sprint4_Execution\CTradeExecutor.mqh"

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
input group "=== 1. SENSORS & MACRO ==="
input int    inp_ATR_Period       = 14;    // ATR period (all timeframes)
input int    inp_KAMA_Fast        = 2;     // KAMA fast period
input int    inp_KAMA_Slow        = 30;    // KAMA slow period
input int    inp_Lookback         = 100;   // Bars to scan for S/D zones
input bool   inp_IsVIX75          = true;  // true = VIX75 mode; false = Forex mode

input group "=== 2. PATTERN ENGINE ==="
input double inp_PinBar_Ratio     = 0.65; // Min wick-to-range ratio for Pin Bar
input int    inp_MinPatternScore  = 70;   // Min confidence score (0-100)

input group "=== 3. RISK MANAGEMENT ==="
input double inp_RiskPerTradePct  = 1.0;  // Risk per trade (% of account balance)
input double inp_MaxDailyDDPct    = 4.0;  // Max daily drawdown (%)
input double inp_MaxTotalDDPct    = 6.0;  // Max total session drawdown (%)
input double inp_MinRRRatio       = 2.0;  // Minimum acceptable Risk:Reward ratio

input group "=== 4. EXECUTION LAYER ==="
input ulong  inp_MagicNumber      = 777777; // Unique EA identifier
input ulong  inp_Slippage         = 10;     // Max slippage in points

//+------------------------------------------------------------------+
//| GLOBAL SYSTEM POINTERS                                           |
//+------------------------------------------------------------------+
CSensorArray*   g_sensors;
CPatternEngine* g_patterns;
CStateMachine*  g_state;
CDecisionTree*  g_decision;
CRiskManager*   g_risk;
CTradeExecutor* g_executor;

datetime        g_last_bar_time;

//+------------------------------------------------------------------+
//| EXPERT INITIALIZATION (BOOT SEQUENCE)                            |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("[Lula V1] Initiating Boot Sequence...");

   //--- 1. Memory Allocation
   g_sensors  = new CSensorArray();
   g_patterns = new CPatternEngine();
   g_state    = new CStateMachine();
   g_decision = new CDecisionTree();
   g_risk     = new CRiskManager();
   g_executor = new CTradeExecutor();

   //--- 2. Module Initialization Cascade (dependency order)
   if(!g_sensors.Init(_Symbol, inp_ATR_Period, inp_KAMA_Fast, inp_KAMA_Slow, inp_Lookback, inp_IsVIX75))
     {
      Print("[Lula V1] BOOT FAILED: CSensorArray::Init()");
      return INIT_FAILED;
     }
   if(!g_patterns.Init(inp_PinBar_Ratio, inp_MinPatternScore))
     {
      Print("[Lula V1] BOOT FAILED: CPatternEngine::Init()");
      return INIT_FAILED;
     }
   if(!g_state.Init(_Symbol))
     {
      Print("[Lula V1] BOOT FAILED: CStateMachine::Init()");
      return INIT_FAILED;
     }
   if(!g_decision.Init(_Symbol, inp_MinPatternScore))
     {
      Print("[Lula V1] BOOT FAILED: CDecisionTree::Init()");
      return INIT_FAILED;
     }
   if(!g_risk.Init(_Symbol, inp_RiskPerTradePct, inp_MaxDailyDDPct, inp_MaxTotalDDPct, inp_MinRRRatio))
     {
      Print("[Lula V1] BOOT FAILED: CRiskManager::Init()");
      return INIT_FAILED;
     }
   if(!g_executor.Init(_Symbol, inp_MagicNumber, inp_Slippage))
     {
      Print("[Lula V1] BOOT FAILED: CTradeExecutor::Init()");
      return INIT_FAILED;
     }

   g_last_bar_time = 0;

   PrintFormat("[Lula V1] All 6 Engines Online | Symbol: %s | TF: %s | Build: %d",
               _Symbol, EnumToString(_Period), TerminalInfoInteger(TERMINAL_BUILD));
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| EXPERT DEINITIALIZATION (SHUTDOWN SEQUENCE)                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   PrintFormat("[Lula V1] Shutting down. Reason: %d. Purging memory...", reason);

   // Call Deinit() on engines that own sub-objects before deleting pointers
   if(g_patterns) { g_patterns.Deinit(); delete g_patterns; g_patterns = NULL; }
   if(g_state)    { g_state.Deinit();    delete g_state;    g_state    = NULL; }

   // Remaining objects clean up in their destructors
   if(g_sensors)  { delete g_sensors;  g_sensors  = NULL; }
   if(g_decision) { delete g_decision; g_decision = NULL; }
   if(g_risk)     { delete g_risk;     g_risk     = NULL; }
   if(g_executor) { delete g_executor; g_executor = NULL; }

   Print("[Lula V1] Shutdown complete. Goodbye.");
  }

//+------------------------------------------------------------------+
//| EXPERT TICK FUNCTION (THE HEARTBEAT)                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   //================================================================
   // PHASE 0: INSTITUTIONAL TIME-GATING — run only on Bar Open
   //================================================================
   datetime current_bar_time = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(current_bar_time == g_last_bar_time) return;
   g_last_bar_time = current_bar_time;

   //================================================================
   // PHASE 1: SENSORY ACQUISITION
   // Update all zone engines, ATR, and KAMA for the new bar.
   //================================================================
   g_sensors.Update();

   // All pattern and sensor evaluation is on the COMPLETED bar (index 1)
   double completed_bar_close = iClose(_Symbol, PERIOD_CURRENT, 1);
   SSensorData sensor_data    = g_sensors.GetData(completed_bar_close);

   //================================================================
   // PHASE 2: MACRO STATE EVALUATION (Sprint 3)
   // Classify market as Trending / Ranging / Choppy / Retracement.
   //================================================================
   g_state.Update(sensor_data);
   SMarketState market_state = g_state.GetState();

   //================================================================
   // PHASE 3: MICRO PATTERN DETECTION (Sprint 2)
   // Scan for institutional candlestick footprints.
   //================================================================
   CPatternResult* p_result = g_patterns.ScanForPattern(g_sensors);

   // If no pattern detected on this bar, halt — nothing to evaluate.
   if(p_result == NULL || !p_result.IsValid()) return;

   //================================================================
   // PHASE 3b: MAP CPatternResult CLASS -> SPatternResult DTO
   // Bridge Sprint 2 class output to the Sprint 4 Decision Tree DTO.
   // NOTE: GetType() is the correct accessor (not GetPattern()).
   //================================================================
   SPatternResult pattern_dto;
   pattern_dto.patternType     = p_result.GetType();
   pattern_dto.direction       = p_result.GetDirection();
   pattern_dto.confidenceScore = inp_MinPatternScore; // Baseline; detectors set quality via grade
   pattern_dto.isGradeA        = (p_result.GetGrade() == GRADE_A);
   pattern_dto.entryPrice      = p_result.GetEntryPrice();
   pattern_dto.stopLoss        = p_result.GetStopLoss();
   pattern_dto.barTime         = g_last_bar_time;

   // Auto-calculate Take Profit based on minimum R:R — direction-aware
   double risk_distance = MathAbs(pattern_dto.entryPrice - pattern_dto.stopLoss);
   if(risk_distance <= 0)
     {
      Print("[Lula V1] Pattern rejected: zero risk distance on SL calculation.");
      return;
     }

   if(pattern_dto.direction == DIRECTION_LONG)
      pattern_dto.takeProfit = pattern_dto.entryPrice + (risk_distance * inp_MinRRRatio);
   else if(pattern_dto.direction == DIRECTION_SHORT)
      pattern_dto.takeProfit = pattern_dto.entryPrice - (risk_distance * inp_MinRRRatio);
   else
      return; // DIRECTION_NONE — no trade

   pattern_dto.rrRatio = inp_MinRRRatio;

   //================================================================
   // PHASE 4: THE DECISION TREE (7 GATES) & EXECUTION (Sprint 4)
   // Only if all 7 gates pass do we calculate lot size and fire.
   //================================================================
   if(g_decision.Evaluate(sensor_data, pattern_dto, market_state, g_risk))
     {
      double lot_size = g_risk.CalculateLotSize(pattern_dto.entryPrice, pattern_dto.stopLoss);

      if(lot_size > 0)
        {
         g_executor.ExecuteTrade(pattern_dto, lot_size);
        }
      else
        {
         Print("[Lula V1] Execution aborted: lot size calculated as zero (check account balance / SL distance).");
        }
     }
  }

//+------------------------------------------------------------------+
//| OnTradeTransaction — Trade event handler (reserved for v1.1)     |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest     &request,
                        const MqlTradeResult      &result)
  {
   // Future: g_executor.OnTradeTransaction(trans, request, result);
  }
//+------------------------------------------------------------------+
