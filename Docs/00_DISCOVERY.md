# Discovery & Intent Documentation

## Project Origin & Core Philosophy
This project translates Munehisa Homma's "The Candlestick Trading Bible" from a discretionary retail strategy into a strict quantitative MQL5 Expert Advisor.

**The Human Intent:** Eliminate the psychological failure points of manual trading (fear, revenge trading, premature execution, and misidentifying choppy markets) by turning the visual patterns into pure algorithmic geometry.

---

## The Discovered Solutions (The "Why")

### 1. The Retracement Logic (Conflict Resolution)
- **Problem:** Retail traders freeze when the Daily chart is Bullish but the 4H chart is Bearish.
- **Discovery:** This is NOT a conflict. It is a "Retracement Phase." The 4H bearish move is simply price seeking liquidity at a Daily structural floor.
- **Action:** The bot must identify this dynamic and hunt for a bullish reversal pattern exactly where the 4H bearish move intersects the Daily support.
- **Code Impact:** `CStateMachine` must classify `STATE_RETRACEMENT` as a **valid tradeable state**, not a rejection. Gate 5 must pass when retracement is confirmed at the Daily floor.

### 2. The 1H Confirmation Loophole (Override Clause)
- **Problem:** Waiting for 1H market structure to shift after a massive 4H Engulfing Bar ruins the Risk:Reward ratio.
- **Discovery:** The sheer size of a 4H Engulfing Bar *is* the 1H structure shift.
- **Action:** Added an "Override Clause." If the 4H signal is a **Grade A Engulfing Bar**, the bot bypasses the 1H check (Gate 5) and drops directly to the 15M for execution.
- **Code Impact:** `CDecisionTree::Gate5_StructureValid()` must check `SPatternResult.isGradeA` flag. If true and pattern is `PATTERN_ENGULFING`, return TRUE without the alignment score check.

### 3. The False Breakout Timing Trap
- **Problem:** Executing an Inside Bar breakout on the 15M chart while the 4H candle is still forming leads to getting trapped.
- **Discovery:** The reversal candle must close back inside the **body** of the mother bar, not just the wick.
- **Action:** Execution is strictly locked until the 15M reversal candle permanently closes inside the 4H Mother Bar's established **body boundary** (Open/Close range), not the High/Low range.
- **Code Impact:** `C_FalseBreakoutDetector::Detect()` must compare the 15M close against `MathMax(motherBarOpen, motherBarClose)` and `MathMin(motherBarOpen, motherBarClose)`, NOT High/Low.

### 4. VIX75 Paradigm Shift
- **Problem:** VIX75 operates 24/7 without fundamental drivers (news).
- **Discovery:** VIX75 is a synthetic algorithmic asset designed to hunt liquidity (stops).
- **Action:** Standard Forex session filters do not apply. Instead, we use a strict volatility filter (`ATR(14) > 800`) and prioritize the "False Breakout" strategy, because stop-hunting is the operating model of the VIX75 algorithm.
- **Code Impact:** `CDecisionTree` must gate all entries against `VIX75_MIN_ATR = 800` (defined in `Defines.mqh`). Below this threshold = algorithmic compression, no trade.

---

## Key Timeframe Chain
| Timeframe | Role |
|-----------|------|
| Weekly    | Engine 3 — Macro bias, key levels (WeeklyMacro) |
| Daily     | Confirmation + Retracement floor detection |
| 4H        | Primary signal + Grade A Engulfing Override |
| 1H        | Structure validation (bypassable via Override Clause) |
| 15M / 5M  | Execution trigger — bar must CLOSE inside 4H body |

---

## Pattern Priority Order
1. **False Breakout** (highest — VIX75 stop-hunt model)
2. **Pin Bar** (strong rejection at zone)
3. **Engulfing** (Grade A = 1H Override eligible)
4. **Inside Bar** (lowest — strictest timing rule applies)
