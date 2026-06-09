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
| `CPatternEngine.mqh` | Runs all 7 detectors + `C_ContextAnalyzer`. Returns highest-priority valid `CPatternResult`. Owns instances, safely deletes in destructor. |
| `C_ContextAnalyzer.mqh` | Unified algorithmic sieve. Enforces Daily Warning (60% wick rejection limit) and Pivot Reversal (must occur at a zone or 8-bar fractal extreme). |

#### Detectors
| File | Responsibility |
|------|---------------|
| `C_EngulfingDetector.mqh` | Current body engulfs previous body. `isGradeA = true` if body ratio ≥ `1.5×`. |
| `C_FalseBreakoutDetector.mqh` | Dynamic VIX75 (10% ATR) vs Forex (5% ATR) penetration logic. Triggers Grade A. |
| `C_ForceBarDetector.mqh` | Body ≥ 80% range, size ≥ 1× ATR. Displacement ≥ `2.0× ATR` triggers Grade A. |
| `C_StarPatternDetector.mqh` | 3-bar morning/evening stars (Directional Base → Exhaustion → Reversal). |
| `C_PinBarDetector.mqh` | Wick-ratio test; wick ≥ `0.65`. |
| `C_InsideBarDetector.mqh` | Strict High/Low inside bounds; directional bias derived from Mother Bar. |
| `C_DblhcDbhlcDetector.mqh` | ATR variance tolerance matching (5% VIX75 / 2% Forex) for floor/ceiling blocks. |

### Acceptance Criteria
- All files compile: **0 errors, 0 warnings** in MetaEditor 5.
- `CPatternEngine::Detect()` correctly identifies all 7 pattern types on historical test data.
- `CPatternResult.IsValid()` returns `false` for `PATTERN_NONE`, zero prices, or score < 70.
- `isGradeA` triggers correctly for Engulfing, False Breakouts, and Extreme Force Bars.
- `Cmp()` is used for **all** floating-point equality checks.
- Memory contract: `CPatternEngine` owns and deletes all detectors + context analyzer.
- **SPRINT 2 STATUS: 100% COMPLETE** ✅

---

## Sprint 3 — The Judgment (State Machine)
**Goal:** Determine market state and multi-timeframe alignment score.

### Files
| File | Responsibility |
|------|---------------|
| `C_TrendAnalyzer.mqh` | Evaluates KAMA slope & current price vs KAMA from `SSensorData`. |
| `C_RangeAnalyzer.mqh` | Reads structural extremes using `CSensorArray` context. |
| `C_ChoppyFilter.mqh` | Uses ADX to filter chop; intercepts non-Grade-A patterns if low momentum. |
| `C_RetracementDetector.mqh` | Identifies Fib 38.2/50/61.8 overlaps with `CPatternResult` entry points. |
| `C_AlignmentScorer.mqh` | Generates 0-100 score validating `CPatternResult` confidence. |
| `CStateMachine.mqh` | Derives `ENUM_MARKET_STATE`; exposes `SMarketState` to Gate 5. |

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
