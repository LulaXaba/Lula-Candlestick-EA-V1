# Implementation Plan: Engine 3 — Weekly Macro Detector

**Plan ID:** PLAN-S1-E3
**Sprint:** 1 — The Sensor Array
**Branch:** `feature/sprint1-engine3-weekly-macro`
**File:** `Source/Sprint1_Sensors/Detectors/CEngine3_WeeklyMacro.mqh`
**Method:** `CEngine3_WeeklyMacro::WeeklyMacro()`

---

## Objective
Create a reusable, isolated detection module that scans the Weekly timeframe to identify the absolute High and Low of the last 6 months (26 weeks). These extremes must be converted into `CPriceZone` objects and assigned the highest structural weight (`RANK_EXTREME`). The weekly bias (bullish / bearish / neutral) must be derived from the last closed weekly candle.

---

## Business Rules
| Rule | Value |
|------|-------|
| Lookback Period | Exactly `WEEKLY_MACRO_LOOKBACK` = 26 weekly bars |
| Weekly High | Highest `iHigh` over 26 bars |
| Weekly Low | Lowest `iLow` over 26 bars |
| Zone Classification | `ZONE_SUPPLY` (above price) / `ZONE_DEMAND` (below price) |
| Zone Rank | `RANK_EXTREME` — macro timeframe weight overrides touch-count rule |
| Touch Requirement | 1 touch only (weekly rank substitutes for standard 2-touch rule) |
| Bias: Bullish | `close > open` AND `body > range * 0.20` on last closed weekly candle |
| Bias: Bearish | `close < open` AND `body > range * 0.20` |
| Bias: Neutral | Doji OR `body <= range * 0.20` → `BIAS_NEUTRAL` → no trades |
| High Vol Mode | If `weeklyATR > (avg of last 14 weekly ATRs * 2)` → `isHighVolMode = true` |
| ATR Gate | If `weeklyATR < VIX75_MIN_ATR` → compression phase, no trades |

---

## Scope

**In Scope:**
- Weekly timeframe data retrieval using `iHigh`, `iLow`, `iOpen`, `iClose`.
- Derivation of `ENUM_WEEKLY_BIAS` from last closed weekly candle (bar index 1).
- Detection of `m_weeklyHigh` and `m_weeklyLow` using `iHighest` / `iLowest` over 26 bars.
- Setting `m_highVolMode` flag based on weekly ATR comparison.
- Exposing all values via public getters for `CSensorArray` to populate `SSensorData`.
- Insufficient history error handling.
- `CopyRates` failure retry (max `ORDER_RETRY_MAX` = 3 attempts).

**Out of Scope:**
- Lower timeframe S/R (Engine 2).
- Trading execution or order management.
- Pattern recognition (Sprint 2).
- Zone touch counting (macro rank overrides this).

---

## Architecture Impact
| Item | Detail |
|------|--------|
| Modified File | `CEngine3_WeeklyMacro.mqh` |
| Method Signature | `public void WeeklyMacro()` (calls private `AnalyseWeeklyBias()`) |
| Caller | `CSensorArray::Update()` — runs on bar close, **never on tick** |
| Data Written To | `SSensorData.weeklyBias`, `.weeklyATR`, `.isHighVolMode` via `CSensorArray` |
| Design Principle | Single Responsibility — Engine 3 only touches Weekly timeframe data |

---

## Error Handling
| Scenario | Required Behaviour |
|----------|-------------------|
| `Bars(_Symbol, PERIOD_W1) < WEEKLY_MACRO_LOOKBACK` | Log `"[WARN] Engine3: Insufficient weekly history. Available: N bars."` Continue with available bars. |
| `CopyRates` / `iHigh` / `iLow` fails | Retry max 3 times with 200ms delay. If still failing, log `"[ERROR] Engine3: Weekly data fetch failed."` Return — do not crash. |
| Zero-range weekly candle (range == 0) | Classify as `BIAS_NEUTRAL` — do not divide by zero. |

---

## Testing Requirements

**Test 1 — Output Validation:**
Add a `Print()` call in `CSensorArray::Update()` after `m_engine3.WeeklyMacro()`:
```mql5
PrintFormat("[Engine3] Bias: %s | WeeklyHigh: %.2f | WeeklyLow: %.2f | ATR: %.2f | HighVol: %s",
   EnumToString(m_engine3.GetWeeklyBias()),
   m_engine3.GetWeeklyHigh(),
   m_engine3.GetWeeklyLow(),
   m_engine3.GetWeeklyATR(),
   m_engine3.IsHighVolMode() ? "YES" : "NO");
```
Verify coordinates match the manual 6-month high/low on the MetaTrader Weekly chart.

**Test 2 — Error Safety:**
Temporarily set `WEEKLY_MACRO_LOOKBACK` to 10000 in testing. Verify EA logs the warning and continues without array out-of-range crashes.

---

## Git Deliverables
| Item | Value |
|------|-------|
| Branch | `feature/sprint1-engine3-weekly-macro` |
| Commit Message | `feat: implement Engine3 WeeklyMacro 26-bar bias and macro level detection` |
| DoD Reference | `Docs/11_DEFINITION_OF_DONE.md` — all 7 gates must pass |
| PR Template | `Docs/12_PR_TEMPLATE.md` — complete before merging |
