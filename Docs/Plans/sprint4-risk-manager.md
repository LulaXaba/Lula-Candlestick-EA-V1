# Implementation Plan: Sprint 4 — Risk Manager

**Plan ID:** PLAN-S4-RISK
**Sprint:** 4 — Execution & Risk
**Branch:** `feature/sprint4-risk-manager`
**File:** `Source/Sprint4_Execution/CRiskManager.mqh`

---

## Objective
Implement the complete `CRiskManager` class providing: (1) ATR-based dynamic position sizing, (2) daily drawdown tracking with halt capability, (3) total session drawdown guard, (4) consecutive loss lot reduction, and (5) high-volatility mode multiplier switching. This class is the financial safety layer — all trades must pass through it before execution.

---

## Business Rules

### Position Sizing
| Parameter | Source |
|-----------|--------|
| Risk Amount | `AccountBalance * (inp_RiskPercent / 100)` |
| Stop Distance | `ATR(14)_Current * inp_ATR_StopMultiplier / Point` |
| Lot Size | `RiskAmount / (StopDistPoints * TickValue)` |
| Lot Rounding | Round to `SYMBOL_VOLUME_STEP` |
| Lot Clamping | Clamp to `[SYMBOL_VOLUME_MIN, SYMBOL_VOLUME_MAX]` |
| High Vol Mode | If `SSensorData.isHighVolMode == true` → use `ATR_MULTIPLIER_HIGH_VOL` instead |
| Min SL | Stop distance must be >= `MIN_SL_POINTS` |

### Daily Drawdown Guard
| Rule | Value |
|------|-------|
| Capture Point | `m_dayOpenEquity` set at `OnInit()` and reset at new calendar day |
| Daily Loss % | `(m_dayOpenEquity - equity) / m_dayOpenEquity * 100` |
| Halt Threshold | `inp_MaxDailyDrawdown` (default 4%) |
| On Trigger | Close all open trades → set `m_haltTrading = true` → log reason |

### Total Session Drawdown Guard
| Rule | Value |
|------|-------|
| Capture Point | `m_sessionStartEquity` set once at `OnInit()` |
| Total Loss % | `(m_sessionStartEquity - equity) / m_sessionStartEquity * 100` |
| Halt Threshold | `inp_MaxTotalDrawdown` (default 6%) = `MAX_WEEKLY_DRAWDOWN` in magnitude |
| On Trigger | Close all open trades → set `m_haltTrading = true` |

### Consecutive Loss Reduction
| Rule | Value |
|------|-------|
| Trigger | `m_consecutiveLosses >= MAX_CONSECUTIVE_LOSSES` (3) |
| Action | Apply `LOT_REDUCTION_FACTOR` (0.5) to calculated lot size |
| Reset | On any winning trade close, reset `m_consecutiveLosses = 0` |

### Margin Guard
| Rule | Value |
|------|-------|
| Check | `AccountInfoDouble(ACCOUNT_MARGIN_LEVEL)` |
| Threshold | `MARGIN_LEVEL_MIN` = 200% |
| Action | If margin level < 200% → `IsDrawdownSafe()` returns false |

---

## Scope
**In Scope:**
- `CalculateLotSize(stopDistancePoints)` method.
- `IsDrawdownSafe()` — returns false if any guard is triggered.
- `UpdateDrawdownTracking()` — call on new calendar day to reset daily equity.
- `OnTradeClosed(profit)` — updates consecutive loss counter.
- All broker API calls: `SYMBOL_TRADE_TICK_VALUE`, `SYMBOL_VOLUME_MIN/MAX/STEP`, `ACCOUNT_EQUITY`, `ACCOUNT_BALANCE`, `ACCOUNT_MARGIN_LEVEL`.
- Tick value retry loop (from `Docs/09_RESEARCH_NOTES.md`).

**Out of Scope:**
- Order placement (handled by `CTradeExecutor`).
- Pattern detection.
- Gate logic (handled by `CDecisionTree`).

---

## Architecture Impact
| Item | Detail |
|------|--------|
| Modified File | `CRiskManager.mqh` |
| Pointer Passed To | `CDecisionTree` — calls `GetMinRR()`, `IsDrawdownSafe()`, `CalculateLotSize()` |
| Also Used By | `CTradeExecutor` — passes lot size from `CalculateLotSize()` to `CTrade::Buy/Sell` |

---

## Error Handling
| Scenario | Required Behaviour |
|----------|-------------------|
| `SYMBOL_TRADE_TICK_VALUE == 0` | Retry loop up to 10 times with 500ms delay. Return `INIT_FAILED` if still 0. |
| `StopDistPoints <= 0` | Return lot size 0 — do not divide by zero |
| `AccountBalance == 0` | Return lot size 0 — log error |

---

## Testing Requirements
**Test 1:** Print calculated lot size for a known ATR and balance. Verify formula manually.
**Test 2:** Reduce equity manually in test to trigger daily DD halt. Verify `m_haltTrading` flag is set and logged.
**Test 3:** Simulate 3 consecutive losses. Verify next lot size is halved.

---

## Git Deliverables
| Item | Value |
|------|-------|
| Branch | `feature/sprint4-risk-manager` |
| Commit Message | `feat: implement CRiskManager ATR sizing, drawdown guards, and consecutive loss reduction` |
| DoD Reference | `Docs/11_DEFINITION_OF_DONE.md` |
| PR Template | `Docs/12_PR_TEMPLATE.md` |
