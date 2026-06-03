# ADR-001: SensorArray OOP Design

**Status:** Accepted
**Date:** 2026-06-03
**Deciders:** Lula Trading Systems

---

## Context
We needed a way to aggregate multiple heterogeneous data sources (ATR, KAMA, Supply/Demand zones, S/R levels, weekly macro, role reversals) into a single, consistent snapshot that can be passed to the rest of the EA without tight coupling.

## Decision
Use a **Facade + Aggregator** OOP pattern via `CSensorArray`:
- `CSensorArray` owns all four engine instances and all sensor module instances.
- It exposes a single `const SSensorData& GetData()` method.
- Callers (e.g., `CDecisionTree`) depend only on the `SSensorData` struct — not on any specific engine class.
- Each engine has exactly one responsibility and one public entry-point method (`SupplyDemand()`, `StandardSR()`, `WeeklyMacro()`, `RoleReversal()`).

## Alternatives Considered

| Alternative | Why Rejected |
|-------------|-------------|
| Global variables for sensor data | Violates SOLID — creates hidden coupling |
| Passing individual sensor pointers to `CDecisionTree` | Too many dependencies; changes to sensors break the tree |
| Single monolithic sensor class | Violates Single Responsibility; untestable |

## Consequences
- **Positive:** Any engine can be replaced or extended without touching `CDecisionTree`.
- **Positive:** `SSensorData` struct is the only contract between layers — easy to unit test.
- **Negative:** Slightly more files than a monolithic approach.
- **Accepted trade-off:** Maintainability > brevity.

## Implementation Reference
- [`CSensorArray.mqh`](../Source/Sprint1_Sensors/CSensorArray.mqh)
- [`DTOs.mqh`](../Source/Include/DTOs.mqh) — `SSensorData` struct
