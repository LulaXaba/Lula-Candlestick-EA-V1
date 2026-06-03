# Implementation Plan: Sprint 1 - Engine 1 (Supply & Demand)

## Objective
Create the `CEngine1_SupplyDemand` class. This engine detects institutional order blocks by identifying single fractal swing points that are immediately followed by extreme price displacement (explosive momentum). 

## Business Rules (The Math)
- **The Trigger:** A valid Swing High or Swing Low detected by `C_SwingDetector`.
- **The Displacement:** The candle(s) immediately following the swing point must exhibit a range or body size `>= 2.0 * ATR(14)`. 
- **The Zone (Base Candle):** If displacement is confirmed, the exact `High` and `Low` of the swing point candle (the "base" candle) become the boundaries of the `CPriceZone`.
- **Classification:** `ZONE_SUPPLY_DEMAND` // (Maps to ZONE_SUPPLY / ZONE_DEMAND)
- **Weight:** `RANK_2_STANDARD` // (Maps to RANK_MAJOR)
- **Touch Count:** 1 (No second touch required).

## Scope
**In Scope:**
- Querying `C_SwingDetector` for recent swing points.
- Fetching `ATR(14)` data to calculate the displacement threshold dynamically.
- Evaluating the 1-3 candles immediately following the swing for the 2x ATR expansion.
- Instantiation of `CPriceZone` objects for validated order blocks.

**Out of Scope:**
- Multi-touch clustering (Handled by Engine 2).
- Lower timeframe analysis.

## Architecture Impact
- **Class:** `CEngine1_SupplyDemand`
- **Location:** `Source/Sprint1_Sensors/Detectors/CEngine1_SupplyDemand.mqh`
- **Method Signature:** `void DetectZones(C_SwingDetector* swings, double &atr_array[], int lookback_bars, CPriceZone* &out_zones[])`

## Detection Logic Steps
1. **Iterate Swings:** Loop through the last `lookback_bars`. Check `IsSwingHigh(i)` and `IsSwingLow(i)`.
2. **Measure Displacement:** If a Swing Low is found at `i`, look at candles `i-1` and `i-2` (the candles that formed *after* the swing). If the bullish close is massive (`Close - Open >= 2.0 * ATR[i]`), it's a Demand Zone.
3. **Invert for Supply:** If a Swing High is found at `i`, and the bearish drop at `i-1` or `i-2` is `>= 2.0 * ATR[i]`, it's a Supply Zone.
4. **Zone Creation:** Set `m_upper_bound = High[i]` and `m_lower_bound = Low[i]`. Create `CPriceZone`, set rank/type, and add to `out_zones`.

## Deliverables
1. `CEngine1_SupplyDemand.mqh` compiling with 0 warnings.
2. Git Branch: `feature/sprint1-engine1-supply-demand`
