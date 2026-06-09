# 04 — Trading Rules: Weekly → Daily → 4H → 1H → 15M Protocol

## Overview
Every trade requires full top-down alignment across 5 timeframes.
A single misalignment = NO TRADE. This is the core edge.

---

## Step 1: Weekly Bias (Gate 1 input)
- Examine the most recently CLOSED weekly candle.
- **Bullish bias:** Candle closes clearly above its open (body confirmed).
- **Bearish bias:** Candle closes clearly below its open.
- **Neutral (skip):** Skip the entire week — no trades — if either condition holds:
  - **Doji:** `body / range ≤ WEEKLY_DOJI_THRESHOLD (5%)` — indecision candle.
  - **Small body:** `body / range ≤ WEEKLY_NEUTRAL_THRESHOLD (20%)` — weak directional signal.
- **High Volatility Mode:** If `weeklyATR > 2 × avgATR(14, W1)`:
  → `data.isHighVolMode = true` → increase ATR stop multiplier (see `Docs/05_RISK_MANAGEMENT.md`).
  → These thresholds are hard constants: `WEEKLY_DOJI_THRESHOLD = 0.05`, `WEEKLY_NEUTRAL_THRESHOLD = 0.20`.

## Step 2: Daily Confirmation (Gate 2 input)
- Daily candle must close IN THE DIRECTION of the weekly bias.
- Rejection rule: If daily wick > 60% of total candle range → re-evaluate bias.
- Require at least ONE full daily candle of confirmation before 4H entry.
- A daily candle that closes against the bias → invalidates the weekly bias.

## Step 3: 4H Primary Signal (Gates 3 & 4)
- Price must be AT or INSIDE an identified Supply or Demand zone (`CPriceZone`).
- **Confluence score** (`CSensorArray::GetConfluenceScore()`) must be ≥ 1. Score components:
  - `+3` — Weekly Macro level (`RANK_1_MAXIMUM`, `ZONE_WEEKLY_MACRO`)
  - `+2` — Role Reversal zone (`ZONE_ROLE_REVERSAL`, validated retest)
  - `+1` — Institutional S&D or Standard S/R zone
  - `+1` — KAMA Confluence Bonus: price within `KAMA_CONFLUENCE_VARIANCE_VIX75 (20 pts)` of KAMA
- A valid candlestick pattern must form at the zone (`CPatternEngine::Detect()`).
- 4H ATR must be > 50% of its 14-period average (market must be active).
- `VIX75_MIN_ATR = 800.0` — if ATR(14, current) < 800 on VIX75, no trades (compression filter).

## 4-Tier Institutional Footprint Model (Pattern Priority)
Patterns are ranked by institutional significance. `CPatternEngine` returns the **highest Tier**
pattern detected at the zone. Lower-tier patterns are only reported if no higher-tier is present.

| Tier | Patterns | isGradeA | Gate 5 Behaviour |
|------|----------|----------|-----------------|
| **Tier 1** | Engulfing, False Breakout, Force Bar | `true` for Engulfing (≥ 1.5× body), False Breakout, and Extreme Force Bar (≥ 2.0× ATR) | **Gate 5 bypassed** — drop directly to 15M entry |
| **Tier 2** | Star Patterns, Pin Bar | `false` | Normal Gate 5 validation required |
| **Tier 3** | Inside Bar, DBLHC/DBHLC | `false` | Normal Gate 5 validation + requires strong zone rank |
| **Tier 4** | Confluence-only (no pattern, but score ≥ 3) | `false` | **NOT a trade signal** — informational only |

> **Grade A Bypass Override:** If `CPatternResult.isGradeA == true`, Gate 5 (1H structure check)
> is bypassed entirely. The EA drops directly to 15M entry execution. This applies to:
> - **Engulfing:** Body ratio ≥ `ENGULFING_GRADE_A_RATIO (1.5×)`.
> - **False Breakout:** Strict penetration depths (VIX75: ≥ 10% ATR, Forex: ≥ 5% ATR).
> - **Extreme Force Bar:** Displacement ≥ 2.0× ATR with ≥ 80% body ratio.

## Context Final Filters (C_ContextAnalyzer)
Before a pattern is deemed valid, it must pass the unified algorithmic sieve:
1. **Daily Warning Rule:** If the current daily candle wick against the intended trade direction is ≥ 60% of the daily range (`DAILY_REJECTION_WICK_PCT`), the trade is rejected (macro players are rejecting the level).
2. **Pivot Reversal Rule:** Non-Grade-A patterns MUST occur either AT a recognized structural zone (Sprint 1) OR form a local 8-bar fractal extreme. Patterns floating in "no man's land" are immediately discarded.

## Step 4: 1H Structure Validation (Gate 5)
- **Override Clause**: If a Grade A Engulfing Bar is detected, bypass the 1H structure check completely and drop directly to 15M for execution.
- Otherwise, 1H chart must show a Break of Structure (BoS) or Change of Character (CHoCH)
  in the direction of the trade.
- No major 1H support/resistance level directly blocking the trade path.
- Alignment score (C_AlignmentScorer) must be >= 70/100.

## Step 5: 15M Entry Execution
- Wait for the 15M candle to CLOSE confirming the pattern.
- Enter on the OPEN of the next 15M candle (bar-close execution).
- **Stop Loss:** Beyond the pattern wick extreme + ATR buffer.
  `SL = wickExtreme ± (ATR_Current * inp_ATR_StopMultiplier)`
- **Take Profit:** Minimum inp_MinRR × stop distance from entry.

## Invalidation Rules
- If price trades > 50% into the entry candle body before TP → exit at market.
- If weekly candle closes against bias → close all open trades, re-evaluate.
- If daily drawdown limit hit → close all trades, halt for session (CRiskManager).
