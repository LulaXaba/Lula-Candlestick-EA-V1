//+------------------------------------------------------------------+
//|                                                      Lula_V3.mq5 |
//|                             Lula Price Action Execution Engine V3|
//|                    Institutional SMC & Liquidity Sweep Architect |
//+------------------------------------------------------------------+
#property copyright "Lula Xaba"
#property link      "https://github.com/LulaXaba"
#property version   "3.02"
#property strict

//--- Core Engine Includes
#include "Sprint1_Sensors/CZigZagEngine.mqh"
#include "Sprint1_Sensors/C_MarketStructureSensor.mqh"
#include "Sprint1_Sensors/C_POI_Sensor.mqh"
#include "Sprint1_Sensors/C_LiquiditySensor.mqh"

#include "Sprint3_State/CStateMachine.mqh"
#include "Sprint4_Execution/CDecisionTree.mqh"
#include "Sprint4_Execution/C_TradeManager.mqh"       // [PATCH V1] new module
#include "Sprint4_Execution/CTradeExecutor.mqh"
#include "Sprint4_Execution/C_VisualRenderer.mqh"

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "--- V3 Risk Management ---"
input double            inp_RiskPercent       = 1.0;     // Risk per Trade (%)
input ulong             inp_MagicNumber       = 777777;  // EA Magic Number

input group "--- SMC Execution Parameters ---"
input double            inp_MinPullbackPct    = 30.0;    // Minimum Pullback % (e.g. 30 for aggressive trends)

input group "--- Top-Down Timeframes ---"
input ENUM_TIMEFRAMES   inp_HTF = PERIOD_H4;             // Macro Narrative (Trend)
input ENUM_TIMEFRAMES   inp_MTF = PERIOD_H1;             // Point of Interest (OB/Liquidity)
input ENUM_TIMEFRAMES   inp_LTF = PERIOD_M5;             // Sniper Trigger (CHoCH)

input group "--- V3 Tuning & Optimization ---"
input double            inp_DispMultATR       = 0.60;    // POI displacement multiplier (was 1.00)
input double            inp_MitigBufATR       = 0.25;    // POI mitigation buffer as ATR fraction
input double            inp_POITolATR         = 0.30;    // POI entry proximity tolerance as ATR fraction
input int               inp_ChochLatchBars    = 72;      // CHoCH latch duration in LTF bars (was 24)
input int               inp_ArmedHoldBars     = 72;      // Armed state duration in LTF bars (was 24)
input int               inp_SweepExpiryBars   = 36;      // Sweep signal expiry in LTF bars (was 12)

input group "--- V3 Trade Management ---"
input double            inp_ManageSL_BufATR   = 0.25;    // SL buffer around swing HL/LH (×ATR)
input double            inp_EarlyProtectATR   = 1.00;    // Pre-T1 BE trigger (×ATR profit)
input bool              inp_EnableEarlyProtect= true;    // Enable T0 early protection

input group "--- V3 Stop Sizing & Execution Gates ---"
input double            inp_MinStopATR        = 1.0;     // Min stop (widened if tighter)
input double            inp_MaxStopATR        = 10.0;    // Max stop — 10 ATR for FX (4.0 was too tight)
input double            inp_MaxSpreadFrac     = 0.30;    // Max spread as fraction of stop risk (was 0.15)

input group "--- Visual Mode & Charting ---"
input bool              inp_ShowVisuals       = true;    // Draw SMC Concepts on Chart

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
C_TradeManager          *g_tradeManager;      // [PATCH V1]
C_TradeExecutor         *g_executor;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("==================================================");
    Print(" Starting Lula V3 SMC Execution Engine (v3.02)...");
    Print("==================================================");

    // 1. Base ZigZag Engines
    g_zzHTF = new CZigZagEngine();
    g_zzMTF = new CZigZagEngine();
    g_zzLTF = new CZigZagEngine();
    if(!g_zzHTF.Init(_Symbol, inp_HTF) ||
       !g_zzMTF.Init(_Symbol, inp_MTF, 1000, 2.5) ||
       !g_zzLTF.Init(_Symbol, inp_LTF, 1000, 2.0))
    {
        Print("FATAL: ZigZag Engine failed to initialize.");
        return INIT_FAILED;
    }

    // 2. SMC Sensors
    g_structureHTF = new C_MarketStructureSensor();
    g_structureLTF = new C_MarketStructureSensor();
    g_poiSensorMTF = new C_POI_Sensor();
    g_liquidityMTF = new C_LiquiditySensor();

    g_structureHTF.Init(_Symbol, inp_HTF, inp_MinPullbackPct);
    g_structureLTF.Init(_Symbol, inp_LTF, inp_MinPullbackPct);
    g_poiSensorMTF.Init(_Symbol, inp_MTF, inp_DispMultATR, inp_MitigBufATR, inp_POITolATR);
    g_liquidityMTF.Init(_Symbol, inp_MTF, inp_LTF, inp_SweepExpiryBars);

    g_poiSensorMTF.Backfill(300);

    // 3. State & Execution Layers
    g_stateMachine = new C_StateMachine();
    g_decisionTree = new C_DecisionTree();
    g_tradeManager = new C_TradeManager();        // [PATCH V1]
    g_executor     = new C_TradeExecutor();

    g_stateMachine.Init(_Symbol, inp_HTF, inp_MTF, inp_LTF, inp_ArmedHoldBars);
    g_decisionTree.Init(_Symbol, inp_LTF, inp_ChochLatchBars, inp_POITolATR,
                        inp_MinStopATR, inp_MaxStopATR);

    // [PATCH V2] Init manager BEFORE executor so the executor's Init log shows ATTACHED
    if(!g_tradeManager.Init(_Symbol, inp_MagicNumber, inp_LTF,
                            inp_ManageSL_BufATR,
                            inp_EarlyProtectATR,
                            inp_EnableEarlyProtect))
    {
        Print("FATAL: TradeManager failed to initialize.");
        return INIT_FAILED;
    }
    g_executor.SetTradeManager(g_tradeManager);

    // [PATCH V3] Pass inp_LTF so executor's internal ATR handle matches the LTF
    if(!g_executor.Init(_Symbol, inp_RiskPercent, inp_MagicNumber, inp_LTF, inp_MaxSpreadFrac))
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
        C_VisualRenderer::Clear("TRADE_");              // [PATCH VIZ-4]
        C_VisualRenderer::Clear("HTF_Discount_Threshold");
        C_VisualRenderer::Clear("HTF_Premium_Threshold");
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
    if(CheckPointer(g_tradeManager)) delete g_tradeManager;   // [PATCH V1]
    if(CheckPointer(g_executor))     delete g_executor;

    Print("Lula V3 safely shut down. Resources cleared.");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // ----------------------------------------------------------------
    // 1. State machine routing (internally throttled to HTF/MTF/LTF)
    // ----------------------------------------------------------------
    ENUM_V3_STATE currentState = g_stateMachine.UpdateAndRoute(
        g_structureHTF, g_poiSensorMTF, g_liquidityMTF, g_zzHTF, g_zzMTF
    );

    // ----------------------------------------------------------------
    // 2. Detect new LTF bar — single source of truth for per-bar work
    // ----------------------------------------------------------------
    static datetime s_lastLtfBarTime = 0;
    datetime currentLtfBarTime = iTime(_Symbol, inp_LTF, 0);
    if(currentLtfBarTime <= 0) currentLtfBarTime = TimeCurrent();
    bool newLtfBar = (currentLtfBarTime != s_lastLtfBarTime);

    if(newLtfBar)
    {
        s_lastLtfBarTime = currentLtfBarTime;

        // 2a. LTF awakening — refresh zigzag + structure on the freshly closed bar
        g_zzLTF.Update();
        g_structureLTF.Update(g_zzLTF);

        // 2b. [PATCH V4] Trade manager — runs every LTF bar regardless of state.
        //     This is what catches the trend-flip exit even when the state machine
        //     has already returned to MTF_POI_SEARCH on this tick.
        if(CheckPointer(g_tradeManager))
            g_tradeManager.OnLtfBar(g_structureHTF, g_structureLTF, g_zzLTF);

        // 2c. Legacy runner BE (no-op when manager is attached)
        g_executor.ManageRunner();
    }

    // ----------------------------------------------------------------
    // 3. Visuals — only on new LTF bar in tester, every tick in visual tester
    // ----------------------------------------------------------------
    if(inp_ShowVisuals)
    {
        bool renderNow = MQLInfoInteger(MQL_VISUAL_MODE) ? true : newLtfBar;
        if(renderNow)
            C_VisualRenderer::RenderAll(
                g_zzHTF, g_zzMTF, g_structureHTF, g_poiSensorMTF,
                _Symbol, inp_MagicNumber,
                VIS_RENDER_ALL_SAME_SYMBOL,     // [FIX 4] or VIS_RENDER_CURRENT for max perf
                inp_MTF,                        // [FIX 3] POIs extend 20×MTF bars
                false                           // [FIX 5] set true to see mitigated zones in grey
            );
    }

    // ----------------------------------------------------------------
    // 4. CPU gate — EA is not in an execution zone, sleep
    // ----------------------------------------------------------------
    if(currentState == STATE_HTF_NARRATIVE ||
       currentState == STATE_MTF_POI_SEARCH ||
       currentState == STATE_STANDBY)
        return;

    // ----------------------------------------------------------------
    // 5. Per-LTF-bar execution gate
    // ----------------------------------------------------------------
    if(!newLtfBar) return;

    // ----------------------------------------------------------------
    // 6. Open-position guard — no evaluation while in a trade
    //    (manager above may have closed the position on this bar; if so
    //     HasOpenPosition() is already false and we proceed normally)
    // ----------------------------------------------------------------
    if(g_executor.HasOpenPosition()) return;

    // ----------------------------------------------------------------
    // 7. Decision Matrix
    // ----------------------------------------------------------------
    STradeSetup setup = g_decisionTree.Evaluate(
        currentState,
        g_structureHTF,
        g_structureLTF,
        g_poiSensorMTF,
        g_liquidityMTF
    );

    // ----------------------------------------------------------------
    // 8. Execution — consume POI/sweep on attempt
    // ----------------------------------------------------------------
    if(setup.direction != SIGNAL_NONE)
    {
        if(setup.poiTime > 0)
            g_poiSensorMTF.DeactivatePOIByTime(setup.poiTime);
        else if(setup.direction == SIGNAL_LONG)
            g_poiSensorMTF.DeactivateBullishPOI(setup.entryPrice);
        else
            g_poiSensorMTF.DeactivateBearishPOI(setup.entryPrice);

        if(setup.sweepLevel > 0)
            g_liquidityMTF.DeactivateSweptPool(setup.sweepLevel);

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
