# ADR-002: State Machine Design

**Status:** Accepted
**Date:** 2026-06-03
**Deciders:** Lula Trading Systems

---

## Context
The EA must classify the current market into one of several states (trending up, trending down, ranging, choppy, retracement, breakout) before allowing any trade. This classification must be:
1. A single authoritative output (no ambiguity).
2. Derived from multiple independent analyzer components.
3. Extensible — new states can be added without rewriting existing logic.

A critical discovery (`Docs/00_DISCOVERY.md` — Discovery #1) mandates that `STATE_RETRACEMENT` must be treated as a **valid tradeable state**, not a rejection. This requirement drove the state machine design.

## Decision
Use a **Composite State Machine** pattern via `CStateMachine`:
- Each analyzer (`C_TrendAnalyzer`, `C_RangeAnalyzer`, `C_ChoppyFilter`, `C_RetracementDetector`, `C_AlignmentScorer`) runs independently and sets its own boolean flag.
- `CStateMachine::Update()` combines all flags using a priority-ordered derivation rule to produce a single `ENUM_MARKET_STATE`.
- The state is exposed via `const SMarketState& GetState()`.
- `CDecisionTree` reads `SMarketState` — it never talks to individual analyzers directly.

### State Priority Order (highest to lowest)
1. `STATE_CHOPPY` — ADX < 20. **Hard block.** No further evaluation.
2. `STATE_BREAKOUT` — confirmed momentum beyond zone boundary.
3. `STATE_RETRACEMENT` — 4H bearish within Daily bullish (or vice versa). **Valid entry setup.**
4. `STATE_TRENDING_UP` / `STATE_TRENDING_DOWN` — KAMA slope confirmed.
5. `STATE_RANGING` — swing H/L compression detected.
6. `STATE_UNDEFINED` — fallback when no analyzer fires.

## Alternatives Considered

| Alternative | Why Rejected |
|-------------|-------------|
| Single `if/else` chain in `OnTick()` | Non-SOLID, untestable, fragile to additions |
| Hard-coded state flags in `CSensorArray` | Mixes sensing responsibility with state judgment |
| External state machine library | MQL5 cannot import arbitrary C++ libs |

## Consequences
- **Positive:** Adding a new market state = adding one new analyzer class + one line in `CStateMachine::Update()`.
- **Positive:** Retracement is a first-class state — correctly implements Discovery #1.
- **Negative:** More files than a flat if/else block.
- **Accepted trade-off:** Correct architecture prevents the "retracement = rejection" bug that causes retail EA failures.

## Implementation Reference
- [`CStateMachine.mqh`](../Source/Sprint3_State/CStateMachine.mqh)
- [`DTOs.mqh`](../Source/Include/DTOs.mqh) — `SMarketState` struct
- [`Defines.mqh`](../Source/Include/Defines.mqh) — `ENUM_MARKET_STATE`
