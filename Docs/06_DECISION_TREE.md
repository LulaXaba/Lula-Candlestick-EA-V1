# 06 — Decision Tree: 7-Gate Boolean Logic Flow

## Overview
Every potential trade signal passes through **7 sequential gates**.
**ALL 7 gates must return TRUE** for an order to be placed.
A FALSE at any gate = **NO TRADE** — log the rejection reason and wait.

---

## The 7 Gates

### Gate 1: Weekly Bias Defined
```
IsWeeklyBiasDefined() == TRUE
  → SSensorData.weeklyBias == BIAS_BULLISH or BIAS_BEARISH
  → NOT BIAS_UNDEFINED or BIAS_NEUTRAL
```

### Gate 2: Daily Alignment
```
IsDailyAligned(weeklyBias) == TRUE
  → Most recent CLOSED daily candle closes in direction of weeklyBias
  → Daily candle body not a rejection (wick < 60% of range)
```

### Gate 3: At Key Zone
```
IsAtKeyZone() == TRUE
  → SSensorData.isAtSupplyZone OR isAtDemandZone == true
  → SSensorData.zoneRank >= RANK_MAJOR
```

### Gate 4: Pattern Detected
```
IsPatternDetected() == TRUE
  → CPatternEngine::Detect() returns a valid SPatternResult
  → SPatternResult.patternType != PATTERN_NONE
  → SPatternResult.confidenceScore >= inp_Pattern_MinScore (default 70)
```

### Gate 5: 1H Structure Valid
```
Is1HStructureValid() == TRUE
  → OR (SPatternResult.patternType == GRADE_A_ENGULFING) // Override Clause bypass
  → CStateMachine.isChoppy == false
  → CStateMachine.alignmentScore >= 70
  → (Sprint 4 TODO: BoS/CHoCH confirmed on 1H)
```

### Gate 6: Risk:Reward Met
```
IsRiskRewardMet() == TRUE
  → SPatternResult.rrRatio >= CRiskManager.GetMinRR() (default 2.0)
  → SL and TP distances are both > 0
```

### Gate 7: Drawdown Safe
```
IsDrawdownSafe() == TRUE
  → Daily drawdown < inp_MaxDailyDrawdown (4%)
  → Total drawdown < inp_MaxTotalDrawdown (6%)
  → ACCOUNT_MARGIN_LEVEL > 200% (if margin exists)
```

---

## Rejection Logging
Every failed gate is logged:
```mql5
PrintFormat("[Lula V1] GATE %d REJECTED — %s", gateId, reason);
```

## Trade Execution (all gates pass)
```mql5
Print("[Lula V1] All 7 gates PASSED — executing trade.");
CTradeExecutor::PlaceTrade(signal);
```
