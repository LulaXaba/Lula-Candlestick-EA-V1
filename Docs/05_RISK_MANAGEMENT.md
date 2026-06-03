# 05 — Risk Management: Drawdown Limits & ATR Stop Multipliers

## Core Risk Parameters (EA Inputs)
| Parameter | Default | Description |
|-----------|---------|-------------|
| `inp_RiskPercent` | 1.0 | % of account balance risked per trade (1% Beginners, 2% Advanced, 0.5% VIX75) |
| `inp_MaxDailyDrawdown` | 0.0 | % max daily drawdown (Note: Framework uses 2 consecutive losses rule instead) |
| `inp_MaxTotalDrawdown` | 6.0 | % max total session drawdown before halt |
| `inp_ATR_StopMultiplier` | 1.5 | ATR multiplier for stop loss distance |
| `inp_MinRR` | 2.0 | Minimum acceptable Risk:Reward ratio |

## Position Sizing Formula
```mql5
RiskAmount     = AccountBalance * (inp_RiskPercent / 100)
StopDistPoints = ATR(14)_Current * inp_ATR_StopMultiplier / Point
LotSize        = RiskAmount / (StopDistPoints * TickValue)
LotSize        = Clamp(LotSize, SYMBOL_VOLUME_MIN, SYMBOL_VOLUME_MAX)
LotSize        = Round(LotSize / SYMBOL_VOLUME_STEP) * SYMBOL_VOLUME_STEP
LotSize        = NormalizeDouble(LotSize, 2)
```
Never hardcode tick value or lot step — always fetch from `SymbolInfoDouble()`.

## Drawdown Guards (enforced in CRiskManager)

### Daily Drawdown Check (Consecutive Loss Rule)
- Maximum 2 consecutive losing trades per session.
- Track consecutive losses across the daily session.
- If consecutive losses >= 2 → close all trades, set HALT flag for the day, resume next session.

### Total Session Drawdown Check
- Captured at `OnInit()`: `m_sessionStartEquity`.
- If `totalLoss% >= inp_MaxTotalDrawdown` → close all trades, halt for session.

### Margin Level Guard
- If `ACCOUNT_MARGIN_LEVEL < 200%` → Gate 7 returns false (no new trades).

### Consecutive Loss Protection
- After `MAX_CONSECUTIVE_LOSSES` (default: 3) losses in a row:
  → Reduce lot size by `LOT_REDUCTION_FACTOR` (50%) for next trade cycle.
  → Reset counter when a winning trade closes.

## ATR Stop Multiplier Logic
| Market Condition | Multiplier |
|-----------------|-----------|
| Normal | `ATR_MULTIPLIER_NORMAL` = 1.5x |
| High Volatility Mode (weekly ATR > 2x avg) | `ATR_MULTIPLIER_HIGH_VOL` = 2.0x |

**Absolute minimum stop:** `MIN_SL_POINTS` = 10 points beyond wick extreme.
