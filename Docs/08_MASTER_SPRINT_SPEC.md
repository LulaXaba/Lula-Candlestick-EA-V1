# 08 — Master Sprint Specification (Sprints 1–4)

---

## Sprint 1 — The Eyes (Sensors)
**Goal:** Build the data acquisition layer. The EA can "see" the market.

### Files
| File | Responsibility |
|------|---------------|
| `C_ATRModule.mqh` | iATR handles for 5 TFs; exposes `GetATR(TF)` |
| `C_KAMAModule.mqh` | iAMA (KAMA) on current TF; exposes `GetKAMA()` |
| `CPriceZone.mqh` | Swing H/L scan; zone rank; `IsAtSupplyZone()` / `IsAtDemandZone()` |
| `CSensorArray.mqh` | Orchestrator; aggregates all into `SSensorData` via `GetData()` |
| `Detectors/CEngine1_SupplyDemand.mqh` | Supply/Demand detection (1 touch + 2xATR) |
| `Detectors/CEngine2_StandardSR.mqh` | Standard S/R detection (2+ touches) |
| `Detectors/CEngine3_WeeklyMacro.mqh` | Weekly macro levels (6-month H/L) |
| `Detectors/C_RoleReversalMonitor.mqh` | Role reversal detection (broken level retests) |

### Acceptance Criteria
- All files compile: **0 errors, 0 warnings**.
- `CSensorArray::GetData()` returns populated `SSensorData` on every bar.
- ATR values match the MT5 built-in ATR indicator (visual comparison in charts).
- Unit test: Print ATR(H1), ATR(H4), ATR(D1), KAMA on every new bar.

---

## Sprint 2 — The Language (Patterns)
**Goal:** Detect all 4-Tier Institutional Footprint patterns at key zones.
Expose a single `CPatternEngine::Detect()` call that returns the highest-tier
`CPatternResult` for the current bar.

### DTO: `CPatternResult` (class — replaces old `SPatternResult` struct)
Defined in `Include/DTOs.mqh`.

| Field | Type | Purpose |
|-------|------|---------|
| `patternType` | `ENUM_PATTERN_TYPE` | Pattern identifier |
| `direction` | `ENUM_TRADE_DIRECTION` | `DIRECTION_LONG` or `DIRECTION_SHORT` |
| `tier` | `int` | 1 = highest institutional weight, 3 = lowest |
| `isGradeA` | `bool` | `true` **only** for Grade A Engulfing — triggers Gate 5 bypass |
| `confidenceScore` | `int` | 0–100; must be ≥ `inp_Pattern_MinScore (70)` to pass Gate 4 |
| `entryPrice` | `double` | Calculated entry price |
| `slPrice` | `double` | Stop Loss price |
| `tpPrice` | `double` | Take Profit price |
| `rrRatio` | `double` | Risk:Reward ratio |
| `barTime` | `datetime` | Time of the signal candle |
| `IsValid()` | `bool` | Returns `true` if type ≠ NONE, score ≥ threshold, prices > 0 |

### Utility: `Cmp()` Tolerance Function
```cpp
// Defined in Sprint2_Patterns/Utility/Cmp.mqh
bool Cmp(double a, double b, double epsilon = 1e-8);
```
> **MQL5 Rule:** Never use `==` to compare doubles. All pattern geometry checks
> (body size, wick ratios, range comparisons) must use `Cmp()` to avoid
> floating-point equality failures in backtesting.

### Files

#### Orchestrator
| File | Responsibility |
|------|---------------|
| `CPatternEngine.mqh` | Runs all 7 detectors + 2 context readers. Returns single highest-tier valid `CPatternResult`. Owns all detector instances — deletes in destructor. |

#### Tier 1 Detectors (highest institutional weight; Engulfing triggers Gate 5 bypass)
| File | Responsibility |
|------|---------------|
| `C_EngulfingDetector.mqh` | Current body fully engulfs previous body. `isGradeA = true` if body ratio ≥ `ENGULFING_GRADE_A_RATIO (1.5×)`. |
| `C_FalseBreakoutDetector.mqh` | Price wicks through zone boundary then closes BACK inside zone. 15M close must be inside the 4H **body** (Open/Close), NOT the wick (High/Low). |
| `C_ForceBarDetector.mqh` | Single full-body directional candle. Body ≥ `2.0 × ATR(14)`. Wick < 20% of body. |
| `C_DoubleCandleDetector.mqh` | DBLHC (Double Bar Higher Close — bullish) / DBHLC (Double Bar Lower Close — bearish). |

#### Tier 2 Detectors
| File | Responsibility |
|------|---------------|
| `C_PinBarDetector.mqh` | Wick ≥ `PINBAR_MIN_WICK_RATIO (0.65)` of total range. Tail points away from zone. |
| `C_StarPatternDetector.mqh` | Morning Star (bullish) / Evening Star (bearish) — 3-candle. Middle body ≤ 10% of range. |

#### Tier 3 Detectors
| File | Responsibility |
|------|---------------|
| `C_InsideBarDetector.mqh` | Current High ≤ previous High AND Low ≥ previous Low. Requires zone rank ≥ `RANK_MAJOR`. |

#### Context Readers (informational — not trade signals)
| File | Responsibility |
|------|---------------|
| `C_PivotContextReader.mqh` | Classical pivot reversal structure. Sets `zoneContext` flag on `CPatternResult`. |
| `C_DailyContextWarner.mqh` | Flags dangerous daily contexts (doji, spike bar, gap). Reduces `confidenceScore` by 15 if active. |

### Acceptance Criteria
- All files compile: **0 errors, 0 warnings** in MetaEditor 5.
- `CPatternEngine::Detect()` correctly identifies all 7 pattern types on historical test data.
- `CPatternResult.IsValid()` returns `false` for `PATTERN_NONE`, zero prices, or score < 70.
- `isGradeA` is **only ever `true`** for Engulfing with body ratio ≥ 1.5×. All others: `false`.
- `C_FalseBreakoutDetector` uses the 4H **body** boundary (not wick) for the close-back test.
- `Cmp()` is used for **all** floating-point equality checks — zero raw `==` on doubles.
- Tier priority enforced: Tier 1 present → no Tier 2 or 3 result returned.
- Memory contract: `CPatternEngine` owns and deletes all 7 detectors + 2 context readers in destructor.
- Priority order: `Engulfing/FalseBO/ForceBar/DoubleCandle (T1) > PinBar/Star (T2) > InsideBar (T3)`.

---

## Sprint 3 — The Judgment (State Machine)
**Goal:** Determine market state and multi-timeframe alignment score.

### Files
| File | Responsibility |
|------|---------------|
| `C_TrendAnalyzer.mqh` | KAMA slope → bullish / bearish / flat |
| `C_RangeAnalyzer.mqh` | Swing H/L → range high / range low |
| `C_ChoppyFilter.mqh` | ADX(14) on H4 < threshold → choppy (no trades) |
| `C_RetracementDetector.mqh` | Fibonacci 38.2 / 50 / 61.8 on most recent swing |
| `C_AlignmentScorer.mqh` | 0-100 score based on 5 alignment criteria |
| `CStateMachine.mqh` | Derives `ENUM_MARKET_STATE`; exposes `SMarketState` |

### Acceptance Criteria
- Market state correctly identified in MT5 backtest visual mode.
- ADX chop filter blocks trades when ADX < 20.
- Alignment score >= 70 required before Gate 5 passes.

---

## Sprint 4 — The Trigger (Execution)
**Goal:** Execute trades safely. Manage open positions. Enforce all 7 gates.

### Files
| File | Responsibility |
|------|---------------|
| `CDecisionTree.mqh` | All 7 gates; rejection logging; calls `PlaceTrade()` |
| `CRiskManager.mqh` | Lot sizing; daily DD; total DD; consecutive loss factor |
| `CTradeExecutor.mqh` | CTrade buy/sell; trailing stop; `OnTradeTransaction` handler |
| `CCorrelationFilter.mqh` | Check open positions for correlated instruments |

### Acceptance Criteria
- Full 12-month backtest on VIX75 completes: **0 runtime errors**.
- Maximum drawdown <= 6% across all tested periods.
- All 7 gate decisions logged in MT5 Journal tab.
- Lot size correctly scales with account balance and stop distance.
