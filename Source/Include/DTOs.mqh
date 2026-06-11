//+------------------------------------------------------------------+
//|  DTOs.mqh — Data Transfer Objects (Shared Structs)               |
//|  Lula Price Action Execution Engine V1.0                         |
//+------------------------------------------------------------------+
#ifndef DTOS_MQH
#define DTOS_MQH

#include "Defines.mqh"

//+------------------------------------------------------------------+
//|  SSensorData — Complete sensor snapshot for one bar              |
//+------------------------------------------------------------------+
struct SSensorData
{
   //--- ATR values per timeframe
   double         atr_W1;
   double         atr_D1;
   double         atr_H4;
   double         atr_H1;
   double         atr_Current;

   //--- KAMA (adaptive trend baseline & momentum)
   double         kama;
   double         kamaSlope;

   //--- Price zone proximity
   bool           isAtSupplyZone;
   bool           isAtDemandZone;
   ENUM_ZONE_RANK zoneRank;
   double         zoneHigh;
   double         zoneLow;

   //--- Multi-Timeframe Bias
   ENUM_WEEKLY_BIAS weeklyBias;
   ENUM_WEEKLY_BIAS dailyBias;
   ENUM_WEEKLY_BIAS h4Bias;

   //--- Volatility & Context
   double           weeklyATR;
   bool             isHighVolMode;
   bool             isRolloverWindow;

   //--- Constructor: zero-safe defaults
   SSensorData() {
      atr_W1 = atr_D1 = atr_H4 = atr_H1 = atr_Current = 0.0;
      kama             = 0.0;
      kamaSlope        = 0.0;
      isAtSupplyZone   = false;
      isAtDemandZone   = false;
      zoneRank         = RANK_WEAK;
      zoneHigh         = 0.0;
      zoneLow          = 0.0;
      weeklyBias       = BIAS_UNDEFINED;
      dailyBias        = BIAS_UNDEFINED;
      h4Bias           = BIAS_UNDEFINED;
      weeklyATR        = 0.0;
      isHighVolMode    = false;
      isRolloverWindow = false;
   }
};

//+------------------------------------------------------------------+
//|  SPatternResult — Output of CPatternEngine for one bar           |
//+------------------------------------------------------------------+
struct SPatternResult
{
   ENUM_PATTERN_TYPE    patternType;
   ENUM_TRADE_DIRECTION direction;
   int                  confidenceScore;  // 0-100
   bool                 isGradeA;         // true if Engulfing body >= ENGULFING_GRADE_A_RATIO x prev body
                                          // Grade A = triggers 1H Override Clause (Gate 5 bypass)
   double               entryPrice;
   double               stopLoss;
   double               takeProfit;
   double               rrRatio;          // Calculated R:R
   datetime             barTime;

   //--- Constructor: zero-safe defaults
   SPatternResult() {
      patternType     = PATTERN_NONE;
      direction       = DIRECTION_NONE;
      confidenceScore = 0;
      isGradeA        = false;
      entryPrice      = 0.0;
      stopLoss        = 0.0;
      takeProfit      = 0.0;
      rrRatio         = 0.0;
      barTime         = 0;
   }

   //--- Validity check
   bool IsValid() const {
      return (patternType != PATTERN_NONE &&
              confidenceScore > 0 &&
              entryPrice > 0.0 &&
              stopLoss   > 0.0 &&
              takeProfit > 0.0);
   }
};

//+------------------------------------------------------------------+
//|  SMarketState — Output of CStateMachine                          |
//+------------------------------------------------------------------+
struct SMarketState
{
   ENUM_MARKET_STATE    state;
   int                  alignmentScore;    // 0-100 multi-TF alignment
   int                  impliedDirection;  // 0 = None, 1 = Long, -1 = Short
   bool                 isTrendingUp;
   bool                 isTrendingDown;
   bool                 isChoppy;
   bool                 isRetracementZone;

   //--- Constructor
   SMarketState() {
      state             = STATE_UNDEFINED;
      alignmentScore    = 0;
      impliedDirection  = 0;
      isTrendingUp      = false;
      isTrendingDown    = false;
      isChoppy          = false;
      isRetracementZone = false;
   }
};

#endif // DTOS_MQH
