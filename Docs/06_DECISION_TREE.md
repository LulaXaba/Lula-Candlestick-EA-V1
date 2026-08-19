# 06 — Decision Tree: V2 Active Trade Monitoring

## Overview
V2 introduces a massive shift from V1's "fire and forget" 7-Gate boolean logic. Instead of solely relying on pre-entry gates and waiting for SL/TP, V2 employs a **3-Tier Post-Entry Monitor** that actively manages the trade based on evolving structure and momentum.

---

## Part 1: Pre-Entry Validation (The New Setup Gates)

1. **Trend State Active**: `CTrendStructure` must report `UPTREND` or `DOWNTREND`. `RANGE` or `TRANSITION` = No Trade.
2. **Confluence Valid**: The pullback node must score Grade C or higher (A+, A, B, or C) from `ConfluenceGrader`. `Reject` = No Trade.
3. **Pattern Confirmed**: A valid candlestick pattern on H1/M15 at the structural node.
4. **Risk Safe**: Drawdown limits intact and margin > 200%.

---

## Part 2: The 3-Tier Post-Entry Monitor
Once a trade is open, `CActiveTradeManager` evaluates its health exclusively on bar closes.

| Tier | Check Frequency | What It Checks | Purpose |
| --- | --- | --- | --- |
| Tier 1: Standard Pulse | Every H1 bar close | Structure + Momentum + Character | Main health check |
| Tier 2: Micro-Confirmation | Every M15 bar close | Candle shape, wick rejection | Zoom in when threatened |
| Tier 3: Strategic Review | Every H4 bar close | Higher timeframe alignment | Context, not exits |

### The 4 Lenses (What We Check)

#### Lens 1: Structure Integrity (Emergency Exit)
- **Question**: Is the level that got me in still holding?
- **Trigger**: Did H1 close below the Higher Low I bought from? (Or above the Lower High I sold from?)
- **Action**: EXIT 100% IMMEDIATELY. The structural floor/ceiling is broken.

#### Lens 2: Momentum Progress (Soft Exit)
- **Question**: Is the trade actually moving toward target, or just sitting there?
- **Trigger**: Look at the last 3 closed H1 candles.
- **Action**:
  - 3 of 3 closes against trade direction → Momentum dead. Tighten SL to BE + 1 tick (or Exit 50%).
  - 2 of 3 closes against trade direction → Stalling. Flag warning → activate Tier 2 (M15) monitoring.

#### Lens 3: Character Change (CHoCH / BoS)
- **Question**: Has the H1 market structure shifted against my position?
- **Trigger**: H1 prints a Lower Low (for longs) or Higher High (for shorts).
- **Action**: EXIT 50% immediately. Move SL to breakeven on the rest.

#### Lens 4: Higher Timeframe Alignment (Institutional Veto)
- **Question**: Does the H4 still want this trade to work?
- **Trigger**: Every H4 bar close. Does H4 print an engulfing, pin bar, or FBO *against* the position?
- **Action**: EXIT 100% immediately. (Institutional veto).

---

## Part 3: The Time Decay Rule
V2 kills dead trades by time, not just price.
- **Formula**: `Expected Move Time = (Distance to Target in points) / (H1 ATR × 0.5)`
- **Rule**: If `Trade Open Time > 2 × Expected Move Time` AND `Progress < 50%` → EXIT 100%. The market is telling you your timing was wrong.

---

## The Decision Matrix Summary

| Tier 1 (H1) | Tier 2 (M15) | Tier 3 (H4) | Decision |
| --- | --- | --- | --- |
| Structure broken | — | — | EXIT 100% |
| Momentum stalled (2/3) | M15 confirms rejection | — | Tighten SL to BE |
| Momentum dead (3/3) | — | — | EXIT 50%, BE rest |
| Character changed | — | — | EXIT 50%, BE rest |
| Everything green | — | H4 reversal pattern | EXIT 100% |
| Everything green | — | H4 aligned | HOLD |
