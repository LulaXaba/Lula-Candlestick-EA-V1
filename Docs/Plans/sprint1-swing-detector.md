# Implementation Plan: Sprint 1 - Swing Detector

## Objective
Create the core mathematical engine (`C_SwingDetector`) that scans candlestick arrays and identifies valid fractal Swing Highs and Swing Lows. This module will act as the foundational dependency for Engine 1 (Supply/Demand), Engine 2 (Standard S/R), and Engine 4 (Role Reversal).

## Business Rules (The Math)
- **Swing High:** A candle whose `High` is *strictly greater* than the Highs of the `N` candles to its left, and *strictly greater* than the Highs of the `N` candles to its right.
- **Swing Low:** A candle whose `Low` is *strictly less* than the Lows of the `N` candles to its left, and *strictly less* than the Lows of the `N` candles to its right.
- **Default Parameters:** 3 candles left, 3 candles right.
- **Strict Inequality:** `>` and `<` must be used. `>=` is invalid, as flat tops/bottoms do not constitute a sharp fractal pivot.

## Scope
**In Scope:**
- Isolation of MQL5 `iHigh` and `iLow` arrays inside a loop.
- Boolean evaluation of the 3L/3R rule.

**Out of Scope:**
- Grouping swings into zones (This belongs to the Cluster Engine).
- Trading or pattern logic.

## Architecture Impact
- **Class:** `C_SwingDetector`
- **Methods Required:** `bool IsSwingHigh(int index)` and `bool IsSwingLow(int index)`.
- **Memory Management:** No dynamic objects are created here. Safe for rapid looping.

## Error Handling
- **Out of Bounds:** If the requested `index` is too close to the current forming candle (`index < right_bars`), return `false`. A swing cannot be confirmed if the right-side candles haven't closed yet.

## Deliverables
1. `Source/Sprint1_Sensors/C_SwingDetector.mqh` compiling with 0 warnings.
2. Git Branch: `feature/sprint1-swing-detector`
