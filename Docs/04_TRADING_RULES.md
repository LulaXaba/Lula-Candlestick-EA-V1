# 04 — Trading Rules: Weekly → Daily → 4H → 1H → 15M Protocol

## Overview
Every trade requires full top-down alignment across 5 timeframes.
A single misalignment = NO TRADE. This is the core edge.

---

## Step 1: Weekly Bias (Gate 1 input)
- Examine the most recently CLOSED weekly candle.
- **Bullish bias:** Candle closes clearly above its open (clear body).
- **Bearish bias:** Candle closes clearly below its open.
- **Neutral (skip):** Doji, small body, or indecision → skip entire week.
- Weekly ATR context: If weekly candle range > 2x ATR(14)W → HIGH VOLATILITY MODE.
  → Increase ATR stop multiplier (see Docs/05_RISK_MANAGEMENT.md).

## Step 2: Daily Confirmation (Gate 2 input)
- Daily candle must close IN THE DIRECTION of the weekly bias.
- Rejection rule: If daily wick > 60% of total candle range → re-evaluate bias.
- Require at least ONE full daily candle of confirmation before 4H entry.
- A daily candle that closes against the bias → invalidates the weekly bias.

## Step 3: 4H Primary Signal (Gates 3 & 4)
- Price must be AT or INSIDE an identified Supply or Demand zone (CPriceZone).
- Zone rank must be RANK_MAJOR or higher.
- A valid candlestick pattern must form at the zone (CPatternEngine).
- 4H ATR must be > 50% of its 14-period average (market must be active).

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
