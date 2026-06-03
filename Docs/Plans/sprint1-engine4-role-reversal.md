# Implementation Plan: Sprint 1 - Engine 4 (Role Reversal)

## Objective
Create the `C_RoleReversalMonitor` class. This engine tracks broken standard S/R zones (Rank 2). It monitors them for a "Change of Polarity" retest. If a broken resistance is retested and successfully holds as support (or vice versa), the engine elevates the zone to a `RANK_1_5_HIGH` high-probability entry level.

## Business Rules (The Math)
- **Break Detection:** A zone is considered broken if a 4H candle *body* (Open and Close) fully crosses and closes beyond the zone's upper or lower boundaries.
- **The Watchlist:** When broken, the zone's `BreakZone(Time[0])` method is called, and the zone is passed to a monitoring array.
- **Retest Validation:** Price must return *into* the variance boundaries of the broken zone, and then the next candle must close *away* from the zone in the direction of the original breakout.
- **Elevation:** If validated, the zone's `ValidateRetest()` method is called (which sets it to `RANK_1_5_HIGH` and `ZONE_ROLE_REVERSAL`).
- **Expiration:** If `ROLE_REVERSAL_MAX_BARS` (50 bars) pass since the break without a valid retest, the zone is purged from the watchlist and abandoned.

## Scope
**In Scope:**
- Maintaining an internal dynamic array of `CPriceZone` pointers (`m_broken_zones`).
- Logic to detect a clean body breakout.
- Logic to detect a pullback into the zone and a subsequent rejection.
- Time-based expiration of broken zones.

**Out of Scope:**
- Creating new zones from scratch (it only modifies existing zones).
- Execution logic.

## Architecture Impact
- **Class:** `C_RoleReversalMonitor`
- **Location:** `Source/Sprint1_Sensors/Detectors/C_RoleReversalMonitor.mqh`
- **Method Signatures:** - `void MonitorActiveZones(CPriceZone* &active_zones[], double close, double open, datetime time)`
  - `void MonitorBrokenZones(double high, double low, double close, double open)`
  - `void PurgeExpiredZones(datetime current_time, int timeframe_seconds)`

## Deliverables
1. `C_RoleReversalMonitor.mqh` compiling with 0 warnings.
2. Git Branch: `feature/sprint1-engine4-role-reversal`
