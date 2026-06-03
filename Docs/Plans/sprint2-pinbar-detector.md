# Implementation Plan: Sprint 2 — Pin Bar Detector

**Plan ID:** PLAN-S2-PINBAR
**Sprint:** 2 — Pattern Recognition
**Branch:** `feature/sprint2-pinbar-detector`
**File:** `Source/Sprint2_Patterns/C_PinBarDetector.mqh`
**Method:** `C_PinBarDetector::Detect(barIndex, result)`

---

## Objective
Detect valid Pin Bar candlestick patterns on bar index 1 (last closed bar). A Pin Bar is defined by a long rejection wick with a small body, indicating a failed directional move and institutional rejection at a price level.

---

## Business Rules
| Rule | Value |
|------|-------|
| Measurement | `body = MathAbs(open - close)`, `range = MathAbs(high - low)` |
| Upper wick | `high - MathMax(open, close)` |
| Lower wick | `MathMin(open, close) - low` |
| Min Wick Ratio | `PINBAR_MIN_WICK_RATIO = 0.65` — wick must be >= 65% of total range |
| Bullish Pin Bar | Lower wick >= `PINBAR_MIN_WICK_RATIO * range` AND close > midpoint of range |
| Bearish Pin Bar | Upper wick >= `PINBAR_MIN_WICK_RATIO * range` AND close < midpoint of range |
| Confidence Base | 60 points (base) |
| Zone Confluence | +`ZONE_CONFLUENCE_BONUS` (10 pts) if at Supply/Demand zone |
| Direction Alignment | +10 pts if wick direction aligns with weekly bias |
| Min Score to Pass | `inp_Pattern_MinScore` = 70 |

---

## Scope
**In Scope:**
- Wick ratio calculation per the exact formulas in `Docs/09_RESEARCH_NOTES.md`.
- Bullish / bearish classification.
- Confidence scoring with zone and bias bonuses.
- Populating `SPatternResult` struct (entry, SL, TP, direction).
- SL placement: beyond wick tip + `ATR_Current * inp_ATR_StopMultiplier`.
- TP placement: entry + (SL distance * `inp_MinRR`).

**Out of Scope:**
- Pattern priority (handled by `CPatternEngine`).
- Trade execution (Sprint 4).
- 1H structure check (Sprint 3 / Gate 5).

---

## Architecture Impact
| Item | Detail |
|------|--------|
| Modified File | `C_PinBarDetector.mqh` |
| Method Signature | `public bool Detect(const int barIndex, SPatternResult &result)` |
| Caller | `CPatternEngine::Detect()` |
| Returns | `true` if valid Pin Bar found; populates `result` |

---

## Error Handling
| Scenario | Required Behaviour |
|----------|-------------------|
| `range == 0` | Return `false` — do not divide by zero |
| `barIndex < 1` | Return `false` |
| `CopyBuffer` for ATR fails | Use last known ATR value — do not crash |

---

## Testing Requirements
**Test 1:** On VIX75 H4 chart in visual backtest, verify Pin Bars are correctly identified with an arrow object or Print log.
**Test 2:** Manually verify SL is placed beyond the wick tip on both bullish and bearish examples.

---

## Git Deliverables
| Item | Value |
|------|-------|
| Branch | `feature/sprint2-pinbar-detector` |
| Commit Message | `feat: implement C_PinBarDetector wick-ratio and confidence scoring` |
| DoD Reference | `Docs/11_DEFINITION_OF_DONE.md` |
| PR Template | `Docs/12_PR_TEMPLATE.md` |
