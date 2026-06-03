# Implementation Plan: Sprint 1 - Sensor Array Manager

## Objective
Create the `CSensorArray` class. This is the master manager for Sprint 1. It instantiates the 4 Engines, orchestrates the market scanning sequence, aggregates all resulting `CPriceZone` objects into a central memory array, handles strict memory cleanup, and computes the mathematical Confluence Score for any given price.

## Business Rules (The Math)
- **The Scoring Matrix (`GetConfluenceScore`):** - Price inside a Rank 1 zone (Weekly Macro) = +3 points
  - Price inside a Rank 1.5 zone (Role Reversal) = +2 points
  - Price inside a Rank 2 zone (Standard S/R or Supply/Demand) = +1 point
  - Price touching KAMA(21) dynamic level = +1 point
  - (Total score >= 2 is required by the framework to trade).
- **Memory Management:** The EA will run 24/7. `CSensorArray` MUST explicitly `delete` every `CPriceZone` pointer it holds in its destructor, as well as the Engine class instances, to prevent memory leaks.
- **Execution Order:** 1. Update ATR and KAMA.
  2. Run Engine 3 (Weekly Macro).
  3. Run Engine 1 (Supply/Demand) and Engine 2 (Standard S/R) using the Swing Detector.
  4. Run Engine 4 (Role Reversal) to monitor break/retest statuses.

## Scope
**In Scope:**
- Master dynamic array: `CPriceZone* m_active_zones[]`.
- Instantiation of the 4 Engines.
- `GetConfluenceScore(double price)` and `GetHighestRankAtPrice(double price)`.
- Explicit destructor memory cleanup.

**Out of Scope:**
- Creating the actual swings or zones (delegated to the individual engines).
- Trading logic or entry execution.

## Architecture Impact
- **Class:** `CSensorArray`
- **Location:** `Source/Sprint1_Sensors/CSensorArray.mqh`
- **Constructor Signature:** `CSensorArray(C_SwingDetector* swings, C_KAMAModule* kama, C_ATRModule* atr, bool is_vix75)`
- **Core Method:** `void ScanMarketEnvironment()` (Called strictly on 4H bar close).

## Deliverables
1. `CSensorArray.mqh` compiling with 0 warnings.
2. Git Branch: `feature/sprint1-sensor-array-manager`
