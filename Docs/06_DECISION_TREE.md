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
  → CSensorArray::GetConfluenceScore(price) >= 1

  // Confluence score breakdown:
  // +3  RANK_1_MAXIMUM / ZONE_WEEKLY_MACRO (Engine 3 macro levels)
  // +2  ZONE_ROLE_REVERSAL (Engine 4 validated retest)
  // +1  ZONE_SUPPLY / ZONE_DEMAND (Engines 1 & 2)
  // +1  KAMA Confluence Bonus (price within KAMA_CONFLUENCE_VARIANCE_VIX75)
```

### Gate 4: Pattern Detected
```
IsPatternDetected() == TRUE
  → CPatternEngine::Detect() returns a valid CPatternResult
  → CPatternResult.IsValid() == true
      → patternType  != PATTERN_NONE
      → confidenceScore >= inp_Pattern_MinScore (default 70)
      → entryPrice, slPrice, tpPrice all > 0

  // Tier priority (CPatternEngine selects highest tier present):
  // Tier 1: Engulfing (Grade A), False Breakout, Force Bar, DBLHC/DBHLC
  // Tier 2: Pin Bar, Star Patterns
  // Tier 3: Inside Bar
  // CPatternResult.tier stores the integer tier (1, 2, or 3)
```

### Gate 5: 1H Structure Valid
```
Is1HStructureValid() == TRUE

  // GRADE A ENGULFING OVERRIDE CLAUSE:
  IF CPatternResult.isGradeA == true:
    → Gate 5 is BYPASSED entirely
    → Proceed directly to Gate 6 (Risk:Reward)
    → Log: "[Lula V1] Gate 5 bypassed — Grade A Engulfing Override active"

  // Standard validation (all non-Tier-1-Engulfing patterns):
  ELSE:
    → CStateMachine.isChoppy == false        (ADX(14,H4) >= ADX_CHOPPY_THRESHOLD)
    → CStateMachine.alignmentScore >= 70      (ALIGNMENT_MIN_SCORE)
    → (Sprint 4 TODO: BoS/CHoCH confirmed on 1H chart)
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
