# 01 — Project Overview: Lula Price Action Execution Engine V1.0

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

## Memory Ownership Contract (MANDATORY — enforced from Sprint 1)
This contract is non-negotiable and must be preserved across all future sprints.
Any AI-generated code that violates these rules introduces memory leaks or dangling pointers.

| Owner | Objects Owned | Deletion Responsibility |
|-------|--------------|------------------------|
| `CSensorArray` | All `CPriceZone*` in `m_active_zones[]` | `ClearActiveZones()` — called at the start of every scan |
| `CSensorArray` | All 4 engine instances (`m_e1_sd`, `m_e2_sr`, `m_e3_wm`, `m_e4_rr`) | Destructor `~CSensorArray()` |
| `CEngine3_WeeklyMacro` | `m_macroHighZone*`, `m_macroLowZone*` | `Deinit()` — **excluded** from `CSensorArray::ClearActiveZones()` |
| `C_RoleReversalMonitor` | **Nothing** — holds non-owning references only | Must call `FlushWatchlist()` **before** `ClearActiveZones()` |
| `CPatternEngine` | All 7 detector instances + 2 context reader instances | Destructor `~CPatternEngine()` |

### MQL5 Strict Array Rule
> **ALL `CopyBuffer()` calls MUST use dynamic arrays.**
> Static arrays (`double buf[N]`) are rejected by MQL5's strict mode with
> "cannot be used for static allocated array". Always use:
> ```cpp
> double buf[];
> ArrayResize(buf, N);
> CopyBuffer(handle, 0, offset, count, buf);
> ```

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
