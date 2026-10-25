//+------------------------------------------------------------------+
//|                                                      Lula_V3.mq5 |
//|                             Lula Price Action Execution Engine V3|
//|                    Institutional SMC & Liquidity Sweep Architect |
//+------------------------------------------------------------------+
#property copyright "Lula Xaba"
#property link      "https://github.com/LulaXaba"
#property version   "3.00"
#property strict

//--- Core Engine Includes
#include "Sprint1_Sensors/CZigZagEngine.mqh"
#include "Sprint1_Sensors/C_MarketStructureSensor.mqh"
#include "Sprint1_Sensors/C_OrderBlockSensor.mqh"
#include "Sprint1_Sensors/C_LiquiditySensor.mqh"

#include "Sprint3_State/CStateMachine.mqh"
#include "Sprint4_Execution/CDecisionTree.mqh"
#include "Sprint4_Execution/CTradeExecutor.mqh"
#include "Sprint4_Execution/C_VisualRenderer.mqh"

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "--- V3 Risk Management ---"
input double            inp_RiskPercent   = 1.0;      // Risk per Trade (%)
input ulong             inp_MagicNumber   = 777777;   // EA Magic Number

input group "--- Top-Down Timeframes ---"
input ENUM_TIMEFRAMES   inp_HTF = PERIOD_H4;          // Macro Narrative (Trend)
input ENUM_TIMEFRAMES   inp_MTF = PERIOD_M15;         // Point of Interest (OB/Liquidity)
input ENUM_TIMEFRAMES   inp_LTF = PERIOD_M5;          // Sniper Trigger (CHoCH)

input group "--- Visual Mode & Charting ---"
input bool              inp_ShowVisuals   = true;     // Draw SMC Concepts on Chart

//+------------------------------------------------------------------+
//| Global Object Pointers                                           |
//+------------------------------------------------------------------+
// ZigZag Base Engines
CZigZagEngine           *g_zzHTF;
CZigZagEngine           *g_zzMTF;
CZigZagEngine           *g_zzLTF;

// Institutional SMC Sensors
C_MarketStructureSensor *g_structureHTF;
C_MarketStructureSensor *g_structureLTF;
C_OrderBlockSensor      *g_obSensorMTF;
C_LiquiditySensor       *g_liquidityMTF;

// State & Execution Managers
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

    // 1. Initialize Base ZigZag Engines (Depth is handled dynamically via ATR inside)
    g_zzHTF = new CZigZagEngine();
    g_zzMTF = new CZigZagEngine();
    g_zzLTF = new CZigZagEngine();
    g_zzHTF.Init(_Symbol, inp_HTF);
    g_zzMTF.Init(_Symbol, inp_MTF);
    g_zzLTF.Init(_Symbol, inp_LTF);

    // 2. Initialize SMC Sensors
    g_structureHTF = new C_MarketStructureSensor();
    g_structureLTF = new C_MarketStructureSensor();
    g_obSensorMTF  = new C_OrderBlockSensor();
    g_liquidityMTF = new C_LiquiditySensor();
    
    g_structureHTF.Init(_Symbol);
    g_structureLTF.Init(_Symbol);
    g_obSensorMTF.Init(_Symbol, inp_MTF);
    g_liquidityMTF.Init(_Symbol, inp_MTF);

    // 3. Initialize State & Execution Layers
    g_stateMachine = new C_StateMachine();
    g_decisionTree = new C_DecisionTree();
    g_executor     = new C_TradeExecutor();

    g_stateMachine.Init(_Symbol, inp_HTF, inp_MTF, inp_LTF);
    g_decisionTree.Init(_Symbol);
    
    if(!g_executor.Init(_Symbol, inp_RiskPercent, inp_MagicNumber))
    {
        Print("FATAL: Trade Executor failed to initialize. Check broker filling modes.");
        return INIT_FAILED;
    }

    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Clean up visual objects on chart
    if(inp_ShowVisuals)
    {
        C_VisualRenderer::Clear("HTF_ZZ_");
        C_VisualRenderer::Clear("MTF_ZZ_");
        C_VisualRenderer::Clear("OB_");
    }

    // Clean up memory to prevent leaks
    if(CheckPointer(g_zzHTF)) delete g_zzHTF;
    if(CheckPointer(g_zzMTF)) delete g_zzMTF;
    if(CheckPointer(g_zzLTF)) delete g_zzLTF;
    
    if(CheckPointer(g_structureHTF)) delete g_structureHTF;
    if(CheckPointer(g_structureLTF)) delete g_structureLTF;
    if(CheckPointer(g_obSensorMTF))  delete g_obSensorMTF;
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
    // 1. Route through the Top-Down State Machine
    // The state machine handles its own IsNewBar throttling for HTF/MTF
    ENUM_V3_STATE currentState = g_stateMachine.UpdateAndRoute(
        g_structureHTF, 
        g_obSensorMTF, 
        g_liquidityMTF, 
        g_zzHTF, 
        g_zzMTF
    );

    // 2. Visual Mode: Render SMC Concepts (ZigZag lines & Order Blocks) on Chart
    if(inp_ShowVisuals)
    {
        C_VisualRenderer::DrawZigZag(g_zzHTF, "HTF", clrDodgerBlue);
        C_VisualRenderer::DrawZigZag(g_zzMTF, "MTF", clrDarkOrange);
        C_VisualRenderer::DrawOrderBlocks(g_obSensorMTF);
    }

    // 3. CPU Optimization: If EA is not in an execution zone, go to sleep.
    if(currentState == STATE_HTF_NARRATIVE || 
       currentState == STATE_MTF_POI_SEARCH || 
       currentState == STATE_STANDBY)
    {
        return; // Drops the tick instantly. Saves massive processing power.
    }

    // 4. LTF Awakening: EA is sitting in an HTF PD Zone AND touching an MTF POI.
    // Update the Lower Timeframe structure to scan for the sniper trigger (CHoCH).
    g_zzLTF.Update();
    g_structureLTF.Update(g_zzLTF);

    // 5. Decision Matrix: Evaluate if the LTF trigger conditions are fully met.
    STradeSetup setup = g_decisionTree.Evaluate(
        currentState, 
        g_structureHTF, 
        g_structureLTF, 
        g_obSensorMTF, 
        g_liquidityMTF
    );

    // 6. Execution: If the setup object returned a valid signal, fire the trades!
    if(setup.direction != SIGNAL_NONE)
    {
        if(g_executor.ExecuteSplitTrade(setup))
        {
            PrintFormat("+++ TRADE SUCCESS: Lula V3 Executed %s at %.5f", setup.modelName, setup.entryPrice);
            // Note: Sensors automatically mitigate/deactivate OBs and Sweeps on the next tick,
            // naturally preventing duplicate trade entries.
        }
        else
        {
            Print("--- TRADE FAILED: Executor rejected the setup.");
        }
    }
}
//+------------------------------------------------------------------+
