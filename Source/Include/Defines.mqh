//+------------------------------------------------------------------+
//|  Defines.mqh — Global Enumerations and Constants                 |
//|  Lula Price Action Execution Engine V1.0                         |
//|                                                                  |
//|  RULE: No magic numbers anywhere else in the codebase.           |
//|  Every numeric literal lives here or as an EA input parameter.   |
//+------------------------------------------------------------------+
#ifndef DEFINES_MQH
#define DEFINES_MQH

//+------------------------------------------------------------------+
//| Zone Quality Ranking                                              |
//+------------------------------------------------------------------+
enum ENUM_ZONE_RANK
{
   RANK_WEAK      = 0,   // Single-touch zone, minor level
   RANK_MINOR     = 5,   // 2-touch zone, moderate confluence
   RANK_STANDARD  = 10,  // Baseline S/R cluster level
   RANK_MAJOR     = 15,  // 3+ touch zone, strong confluence
   RANK_1_5_HIGH  = 20,  // Role-reversal validated zone (elevated)
   RANK_1_MAXIMUM = 30,  // Weekly macro high/low — highest priority
   RANK_EXTREME   = 40   // All-time high/low, key weekly level
};

//+------------------------------------------------------------------+
//| Zone Type                                                         |
//+------------------------------------------------------------------+
enum ENUM_ZONE_TYPE
{
   ZONE_NONE          = 0,
   ZONE_SUPPLY        = 1,   // Overhead supply (resistance origin)
   ZONE_DEMAND        = 2,   // Underlying demand (support origin)
   ZONE_ROLE_REVERSAL = 3,   // Broken S/R that flipped (Engine 4)
   ZONE_STANDARD_SR   = 4,   // Generic S/R cluster (Engine 2 default)
   ZONE_WEEKLY_MACRO  = 5,   // Weekly high/low macro zone (Engine 3)
   ZONE_DYNAMIC_KAMA  = 6    // KAMA-anchored dynamic zone
};

//+------------------------------------------------------------------+
//| Market State (output of CStateMachine)                           |
//+------------------------------------------------------------------+
enum ENUM_MARKET_STATE
{
   STATE_UNDEFINED     = 0,
   STATE_TRENDING_UP   = 1,
   STATE_TRENDING_DOWN = 2,
   STATE_RANGING       = 3,
   STATE_CHOPPY        = 4,
   STATE_RETRACEMENT   = 5,   // Valid tradeable state — NOT a rejection
   STATE_BREAKOUT      = 6
};

//+------------------------------------------------------------------+
//| Weekly Bias (output of Engine 3 — WeeklyMacro)                   |
//+------------------------------------------------------------------+
enum ENUM_WEEKLY_BIAS
{
   BIAS_UNDEFINED = 0,
   BIAS_BULLISH   = 1,
   BIAS_BEARISH   = 2,
   BIAS_NEUTRAL   = 3   // Skip — no trades this week
};

//+------------------------------------------------------------------+
//| Pattern Type                                                      |
//+------------------------------------------------------------------+
enum ENUM_PATTERN_TYPE
{
   PATTERN_NONE           = 0,
   PATTERN_PIN_BAR        = 1,
   PATTERN_ENGULFING      = 2,   // Grade A = triggers 1H Override Clause
   PATTERN_INSIDE_BAR     = 3,
   PATTERN_FALSE_BREAKOUT = 4    // Highest priority on VIX75
};

//+------------------------------------------------------------------+
//| Trade Direction                                                   |
//+------------------------------------------------------------------+
enum ENUM_TRADE_DIRECTION
{
   DIRECTION_NONE  = 0,
   DIRECTION_LONG  = 1,
   DIRECTION_SHORT = 2
};

//+------------------------------------------------------------------+
//| Decision Tree Gate IDs (for rejection logging)                   |
//+------------------------------------------------------------------+
enum ENUM_GATE_ID
{
   GATE_1_WEEKLY_BIAS   = 1,
   GATE_2_DAILY_ALIGN   = 2,
   GATE_3_KEY_ZONE      = 3,
   GATE_4_PATTERN       = 4,
   GATE_5_STRUCTURE     = 5,   // Bypassable by Grade A Engulfing Override
   GATE_6_RISK_REWARD   = 6,
   GATE_7_DRAWDOWN_SAFE = 7
};

//+------------------------------------------------------------------+
//| Execution State                                                   |
//+------------------------------------------------------------------+
enum ENUM_EXECUTION_STATE
{
   EXEC_WAITING         = 0,
   EXEC_ENTRY_PENDING   = 1,
   EXEC_ACTIVE          = 2,
   EXEC_CLOSING         = 3,
   EXEC_ERROR           = 4
};

//+------------------------------------------------------------------+
//| VIX75-Specific Constants (from Docs/09_RESEARCH_NOTES.md)        |
//+------------------------------------------------------------------+
#define VIX75_MIN_ATR           800.0   // ATR(14) threshold — below = compression, no trade
#define VIX75_MAX_SPREAD          5.0   // Maximum allowed spread in points for VIX75
#define WEEKLY_MACRO_LOOKBACK   26      // 26 weekly bars = ~6 months of macro data
#define ROLLOVER_PAUSE_START    2355    // Broker time HHMM — pause new trades (23:55)
#define ROLLOVER_PAUSE_END      5       // Broker time HHMM — resume trades (00:05)
#define ORDER_RETRY_MAX         3       // Max order submission retries (VIX75 requotes)
#define ORDER_RETRY_DELAY_MS    200     // Milliseconds between order retries
#define SLIPPAGE_POINTS_MAX     50      // Max slippage allowed in points

//+------------------------------------------------------------------+
//| Engine 4: Role Reversal Constants                                 |
//+------------------------------------------------------------------+
#define ROLE_REVERSAL_MAX_BARS   50     // Max bars a broken zone stays on the watchlist

//+------------------------------------------------------------------+
//| Risk Management Constants                                         |
//+------------------------------------------------------------------+
#define MAX_WEEKLY_DRAWDOWN       -6.0  // Maximum weekly drawdown % (negative = loss)
#define RISK_REDUCTION_THRESHOLD  -4.0  // Drawdown level % that triggers lot reduction
#define ATR_MULTIPLIER_NORMAL      1.5  // Normal market ATR stop multiplier
#define ATR_MULTIPLIER_HIGH_VOL    2.0  // High volatility mode (weekly ATR elevated)
#define MIN_SL_POINTS             10.0  // Absolute minimum SL distance in points
#define MAX_CONSECUTIVE_LOSSES    3     // Trigger lot reduction after N losses
#define LOT_REDUCTION_FACTOR      0.5   // Halve lot size after consecutive losses
#define MARGIN_LEVEL_MIN         200.0  // Minimum margin level % — Gate 7
#define RISK_PER_TRADE_PCT         1.0  // Default 1% risk per trade

//+------------------------------------------------------------------+
//| Pattern Recognition Constants                                     |
//+------------------------------------------------------------------+
#define PINBAR_MIN_WICK_RATIO    0.65   // Minimum wick-to-range ratio for valid Pin Bar
#define ENGULFING_GRADE_A_RATIO  1.5    // Grade A: body must be >= 1.5x previous body
#define ZONE_CONFLUENCE_BONUS    10     // Extra confidence score for zone confluence

//+------------------------------------------------------------------+
//| State Machine Constants                                           |
//+------------------------------------------------------------------+
#define ADX_CHOPPY_THRESHOLD     20.0   // ADX(14) H4 below this = choppy, no trades
#define ALIGNMENT_MIN_SCORE      70     // Minimum multi-TF alignment score — Gate 5
#define DAILY_REJECTION_WICK_PCT 0.60   // Daily wick > 60% of range = rejection candle
#define WEEKLY_DOJI_THRESHOLD    0.05
#define WEEKLY_NEUTRAL_THRESHOLD 0.20

//+------------------------------------------------------------------+
//| KAMA (Kaufman Adaptive Moving Average) Parameters                 |
//+------------------------------------------------------------------+
#define KAMA_FAST_PERIOD         2      // Fast EMA period
#define KAMA_SLOW_PERIOD         30     // Slow EMA period
#define KAMA_CONFLUENCE_VARIANCE_VIX75    20.0
#define KAMA_CONFLUENCE_VARIANCE_FOREX    5.0

//+------------------------------------------------------------------+
//| Fibonacci Retracement Levels                                      |
//+------------------------------------------------------------------+
#define FIBO_382    0.382   // 38.2% retracement
#define FIBO_500    0.500   // 50.0% retracement
#define FIBO_618    0.618   // 61.8% retracement (golden ratio — primary target)

#endif // DEFINES_MQH
