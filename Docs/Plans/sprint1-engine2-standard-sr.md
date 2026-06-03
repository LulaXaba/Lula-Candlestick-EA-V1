# Implementation Plan: Sprint 1 - Engine 2 (Standard S/R)

## Objective
Create the `CEngine2_StandardSR` class, which acts as the Fractal Clustering Algorithm. This engine will consume raw swing points from `C_SwingDetector`, group them into cohesive horizontal bands based on asset-specific variance, enforce the book's strict 2-touch minimum rule, and output `CPriceZone` objects.

## Business Rules (The Math)
- **Input Source:** Must query `C_SwingDetector` over a defined lookback period (e.g., 500-1000 bars on the 4H chart).
- **Clustering Variance:** - VIX75: ±50 points.
  - Forex: ±15 pips (converted to `_Point` equivalent).
- **Touch Minimum:** A clustered zone MUST have `touch_count >= 2` to be considered valid. Single touches are discarded by this engine (Engine 1 handles single touches).
- **Classification:** `ZONE_STANDARD_SR`
- **Weight:** `RANK_2_STANDARD`

## Scope
**In Scope:**
- Structuring an internal array/list to hold temporary clusters.
- Mathematics to compare a new swing point against existing clusters.
- Instantiation of `CPriceZone` objects for validated clusters.
- Returning an array of pointers to valid `CPriceZone` objects.

**Out of Scope:**
- Identifying the swings (delegated to `C_SwingDetector`).
- Drawing on the chart.
- Single-touch Supply/Demand (Engine 1 logic).

## Architecture Impact
- **Class:** `CEngine2_StandardSR`
- **Location:** `Source/Sprint1_Sensors/Detectors/CEngine2_StandardSR.mqh`
- **Method Signature:** `void DetectZones(C_SwingDetector* swings, double variance_pts, int lookback_bars, CPriceZone* &out_zones[])`

## Clustering Logic Steps
1. **Find Swings:** Loop through `lookback_bars`. If `IsSwingHigh(i)` or `IsSwingLow(i)` is true, get the price.
2. **Cluster Match:** Check if this price is within `variance_pts` of an existing temporary cluster's center/average.
3. **Merge or Create:** If it matches, expand the cluster's upper/lower bounds and increment its touch count. If no match, create a new temporary cluster with 1 touch.
4. **Filter:** After looping, iterate through all temporary clusters. For every cluster where `touches >= 2`, create a `CPriceZone`, `SetZoneLimits()`, `SetRankAndType()`, and add it to `out_zones`.

## Deliverables
1. `CEngine2_StandardSR.mqh` compiling with 0 warnings.
2. Git Branch: `feature/sprint1-engine2-standard-sr`
