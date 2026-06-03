# 01 — Project Overview

## Core Goals
1. **Automate** the Lula price action methodology end-to-end.
2. **Enforce** the multi-timeframe mandate — no trade without full chain alignment.
3. **Protect capital** via strict ATR-based risk management and drawdown guards.
4. **Scale** from VIX75 to Forex pairs with minimal code changes.

## Multi-Timeframe Mandate
The EA is **FORBIDDEN** from placing a trade unless:
- Weekly bias is defined (bullish, bearish — skip if neutral).
- Daily candle confirms the weekly bias direction.
- 4H shows a valid price action pattern at a key Supply/Demand zone.
- 1H structure does not contradict the signal (BoS or CHoCH present).
- 15M entry trigger candle is closed and aligned.

## Design Philosophy
- **Bar-close logic only.** No mid-candle entries. Safety over speed.
- **Rule-based, not discretionary.** Every decision is a boolean gate.
- **ATR-relative stops.** No fixed pip stops. Adapts to market volatility.
- **Zero magic numbers.** All parameters are exposed as EA inputs or named constants.

## Success Criteria (Sprint 4 Complete)
- EA compiles and runs without errors in MetaEditor / MT5.
- Backtest on VIX75 shows positive expectancy over 12 months of data.
- Maximum drawdown does not exceed 6% in any tested period.
- All 7 gates of the decision tree are enforced and logged correctly.
- No MQL5 compiler warnings (strict mode).

## Out of Scope (V1)
- Machine learning / AI signal generation
- News filter (VIX75 has no news events)
- Multi-symbol simultaneous trading (correlation filter prevents it)
- Copy trading or remote signal delivery
