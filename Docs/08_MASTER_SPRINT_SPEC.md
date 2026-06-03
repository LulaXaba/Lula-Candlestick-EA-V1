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
| `Detectors/CEngine1_Trend.mqh` | KAMA slope + ATR trend detection |
| `Detectors/CEngine2_Range.mqh` | Range boundary swing detection |
| `Detectors/CEngine3_Reversal.mqh` | Reversal context (wicks, rejections) |
| `Detectors/CEngine4_Breakout.mqh` | Breakout momentum detection |

### Acceptance Criteria
- All files compile: **0 errors, 0 warnings**.
- `CSensorArray::GetData()` returns populated `SSensorData` on every bar.
- ATR values match the MT5 built-in ATR indicator (visual comparison in charts).
- Unit test: Print ATR(H1), ATR(H4), ATR(D1), KAMA on every new bar.

---

## Sprint 2 — The Language (Patterns)
**Goal:** Detect high-probability candlestick patterns at key zones.

### Files
| File | Responsibility |
|------|---------------|
| `C_PinBarDetector.mqh` | Wick-ratio test; bullish/bearish; configurable ratio |
| `C_EngulfingDetector.mqh` | Body engulf test; current body > previous body |
| `C_InsideBarDetector.mqh` | Inside range; direction from bias alignment |
| `C_FalseBreakoutDetector.mqh` | Zone pierce + close-back = liquidity sweep |
| `CPatternEngine.mqh` | Runs all; selects highest confidence; returns `SPatternResult` |

### Acceptance Criteria
- All files compile: **0 errors, 0 warnings**.
- `CPatternEngine::Detect()` correctly identifies patterns on test data.
- `SPatternResult.confidenceScore` reflects zone proximity and bias alignment.
- Priority order: FalseBreakout > PinBar > Engulfing > InsideBar.

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
