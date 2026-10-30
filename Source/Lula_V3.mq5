//+------------------------------------------------------------------+
//|                                                      Lula_V3.mq5 |
//|                             Lula Price Action Execution Engine V3|
//|                    Institutional SMC & Liquidity Sweep Architect |
//+------------------------------------------------------------------+
#property copyright "Lula Xaba"
#property link      "https://github.com/LulaXaba"
#property version   "3.01"
#property strict

//--- Core Engine Includes
#include "Sprint1_Sensors/CZigZagEngine.mqh"
#include "Sprint1_Sensors/C_MarketStructureSensor.mqh"
#include "Sprint1_Sensors/C_POI_Sensor.mqh"
#include "Sprint1_Sensors/C_LiquiditySensor.mqh"

#include "Sprint3_State/CStateMachine.mqh"
#include "Sprint4_Execution/CDecisionTree.mqh"
#include "Sprint4_Execution/CTradeExecutor.mqh"
#include "Sprint4_Execution/C_VisualRenderer.mqh"

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "--- V3 Risk Management ---"
input double            inp_RiskPercent    = 1.0;     // Risk per Trade (%)
input ulong             inp_MagicNumber    = 777777;  // EA Magic Number

input group "--- SMC Execution Parameters ---"
input double            inp_MinPullbackPct = 30.0;    // Minimum Pullback % (e.g. 30 for aggressive trends)

input group "--- Top-Down Timeframes ---"
input ENUM_TIMEFRAMES   inp_HTF = PERIOD_H4;          // Macro Narrative (Trend)
input ENUM_TIMEFRAMES   inp_MTF = PERIOD_H1;          // Point of Interest (OB/Liquidity)
input ENUM_TIMEFRAMES   inp_LTF = PERIOD_M5;          // Sniper Trigger (CHoCH)

input group "--- Visual Mode & Charting ---"
input bool              inp_ShowVisuals = true;        // Draw SMC Concepts on Chart

//+------------------------------------------------------------------+
//| Global Object Pointers                                           |
//+------------------------------------------------------------------+
CZigZagEngine           *g_zzHTF;
CZigZagEngine           *g_zzMTF;
CZigZagEngine           *g_zzLTF;

C_MarketStructureSensor *g_structureHTF;
C_MarketStructureSensor *g_structureLTF;
C_POI_Sensor            *g_poiSensorMTF;
C_LiquiditySensor       *g_liquidityMTF;

C_StateMachine          *g_stateMachine;
C_DecisionTree          *g_decisionTree;
C_TradeExecutor         *g_executor;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("==================================================");
    Print(" Starting Lula V3 SMC Execution Engine...");
    Print("==================================================");

    // 1. Base ZigZag Engines
    g_zzHTF = new CZigZagEngine();
    g_zzMTF = new CZigZagEngine();
    g_zzLTF = new CZigZagEngine();
    g_zzHTF.Init(_Symbol, inp_HTF);
    g_zzMTF.Init(_Symbol, inp_MTF);
    g_zzLTF.Init(_Symbol, inp_LTF);

    // 2. SMC Sensors
    g_structureHTF = new C_MarketStructureSensor();
    g_structureLTF = new C_MarketStructureSensor();
    g_poiSensorMTF = new C_POI_Sensor();
    g_liquidityMTF = new C_LiquiditySensor();

    g_structureHTF.Init(_Symbol, inp_HTF, inp_MinPullbackPct);
    g_structureLTF.Init(_Symbol, inp_LTF, inp_MinPullbackPct);
    g_poiSensorMTF.Init(_Symbol, inp_MTF);
    g_liquidityMTF.Init(_Symbol, inp_MTF, inp_LTF); // [Fix #3] pass LTF for sweep expiry

    // 3. State & Execution Layers
    g_stateMachine = new C_StateMachine();
    g_decisionTree = new C_DecisionTree();
    g_executor     = new C_TradeExecutor();

    g_stateMachine.Init(_Symbol, inp_HTF, inp_MTF, inp_LTF);
    g_decisionTree.Init(_Symbol, inp_LTF);

    if(!g_executor.Init(_Symbol, inp_RiskPercent, inp_MagicNumber))
    {
        Print("FATAL: Trade Executor failed to initialize. Check broker filling modes.");
        return INIT_FAILED;
    }

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if(inp_ShowVisuals)
    {
        C_VisualRenderer::Clear("HTF_ZZ_");
        C_VisualRenderer::Clear("MTF_ZZ_");
        C_VisualRenderer::Clear("POI_");
        C_VisualRenderer::Clear("OB_");
        C_VisualRenderer::Clear("HTF_Equilibrium_50");
    }

    if(CheckPointer(g_zzHTF))        delete g_zzHTF;
    if(CheckPointer(g_zzMTF))        delete g_zzMTF;
    if(CheckPointer(g_zzLTF))        delete g_zzLTF;
    if(CheckPointer(g_structureHTF)) delete g_structureHTF;
    if(CheckPointer(g_structureLTF)) delete g_structureLTF;
    if(CheckPointer(g_poiSensorMTF)) delete g_poiSensorMTF;
    if(CheckPointer(g_liquidityMTF)) delete g_liquidityMTF;
    if(CheckPointer(g_stateMachine)) delete g_stateMachine;
    if(CheckPointer(g_decisionTree)) delete g_decisionTree;
    if(CheckPointer(g_executor))     delete g_executor;

    Print("Lula V3 safely shut down. Resources cleared.");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // 1. State Machine — sensor updates happen inside on new HTF/MTF bar
    ENUM_V3_STATE currentState = g_stateMachine.UpdateAndRoute(
        g_structureHTF, g_poiSensorMTF, g_liquidityMTF, g_zzHTF, g_zzMTF
    );

    // 2. Visuals — only on new LTF bar in tester (suppress per-tick render for speed)
    //    In live mode visual mode flag is checked.
    static datetime s_lastVisualBar = 0;
    if(inp_ShowVisuals)
    {
        bool renderNow = MQLInfoInteger(MQL_VISUAL_MODE)   // visual tester: update every tick for smooth display
                         ? true
                         : (iTime(_Symbol, inp_LTF, 0) != s_lastVisualBar);  // live/normal: once per LTF bar
        if(renderNow)
        {
            C_VisualRenderer::RenderAll(g_zzHTF, g_zzMTF, g_structureHTF, g_poiSensorMTF);
            s_lastVisualBar = iTime(_Symbol, inp_LTF, 0);
        }
    }

    // 3. CPU gate — EA is not in an execution zone, sleep
    if(currentState == STATE_HTF_NARRATIVE ||
       currentState == STATE_MTF_POI_SEARCH ||
       currentState == STATE_STANDBY)
        return;

    // 4. Closed Bar Execution Gate — every action below runs exactly once per LTF bar close
    static datetime s_lastLtfBarTime = 0;
    datetime currentLtfBarTime = iTime(_Symbol, inp_LTF, 0);
    if(currentLtfBarTime <= 0) currentLtfBarTime = TimeCurrent();
    if(currentLtfBarTime == s_lastLtfBarTime) return;
    s_lastLtfBarTime = currentLtfBarTime;

    // 5. LTF Awakening — update structure on the freshly closed LTF bar
    g_zzLTF.Update();
    g_structureLTF.Update(g_zzLTF);

    // 6. Decision Matrix — evaluate if all LTF trigger conditions are met
    STradeSetup setup = g_decisionTree.Evaluate(
        currentState,
        g_structureHTF,
        g_structureLTF,
        g_poiSensorMTF,
        g_liquidityMTF
    );

    // 7. Execution — ALWAYS consume the setup (POI mitigated on any attempt, success or not)
    //    [Fix #1] The consume-on-attempt pattern: deactivate before checking result.
    if(setup.direction != SIGNAL_NONE)
    {
        // Consume the POI / swept pool immediately — no emotional re-entries
        if(setup.poiTime > 0)
            g_poiSensorMTF.DeactivatePOIByTime(setup.poiTime);
        else if(setup.direction == SIGNAL_LONG)
            g_poiSensorMTF.DeactivateBullishPOI(setup.entryPrice);
        else
            g_poiSensorMTF.DeactivateBearishPOI(setup.entryPrice);

        if(setup.sweepLevel > 0)
            g_liquidityMTF.DeactivateSweptPool(setup.sweepLevel);

        // Then attempt execution
        bool ok = g_executor.ExecuteSplitTrade(setup);
        if(ok)
            PrintFormat("+++ TRADE SUCCESS: Lula V3 Executed %s at %.5f (tickets: %d)",
                        setup.modelName, setup.entryPrice, g_executor.TicketsOpened());
        else
            PrintFormat("--- TRADE FAILED: %s rejected (tickets opened: %d).",
                        setup.modelName, g_executor.TicketsOpened());
    }
}
//+------------------------------------------------------------------+
