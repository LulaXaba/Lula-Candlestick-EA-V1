# Implementation Plan: Engine 1 — Supply & Demand Zone Detector

**Plan ID:** PLAN-S1-E1
**Sprint:** 1 — The Sensor Array
**Branch:** `feature/sprint1-engine1-supply-demand`
**File:** `Source/Sprint1_Sensors/Detectors/CEngine1_SupplyDemand.mqh`
**Method:** `CEngine1_SupplyDemand::SupplyDemand()`

---

## Objective
Scan the H4 timeframe over `m_lookback` bars to identify institutional Supply and Demand zones based on "base candle" (consolidation before impulse) origin analysis. Rank each zone and check if current price is within any zone boundary.

---

## Business Rules
| Rule | Value |
|------|-------|
| Scan Timeframe | H4 (primary signal timeframe) |
| Lookback | `inp_ZoneLookback` (default 100 bars) |
| Base Candle | `body / range < 0.30` (consolidation before impulse) |
| Impulse Qualifier | Next candle body > 2x base candle body |
| Supply Zone | Strong DOWN impulse after base candle |
| Demand Zone | Strong UP impulse after base candle |
| Zone Boundaries | Base candle High = `zoneHigh`, Low = `zoneLow` |
| Zone Rank | `RANK_WEAK` (1 touch), `RANK_MINOR` (2), `RANK_MAJOR` (3+), `RANK_EXTREME` (weekly-origin) |
| At Zone | Current Ask within supply zone OR current Bid within demand zone |

---

## Scope
**In Scope:**
- Base candle detection on H4 timeframe.
- Impulse strength validation (2x body rule).
- Zone boundary extraction (High/Low of base candle).
- Touch counting via `CountTouches()`.
- Zone rank assignment per touch count.
- Current price proximity check.

**Out of Scope:**
- Weekly macro levels (Engine 3).
- Standard swing highs/lows (Engine 2).
- Role reversal levels (Engine 4).
- Pattern detection (Sprint 2).

---

## Architecture Impact
| Item | Detail |
|------|--------|
| Modified File | `CEngine1_SupplyDemand.mqh` |
| Method Signature | `public void SupplyDemand()` |
| Caller | `CSensorArray::Update()` — bar close only |
| Data Written To | `SSensorData.isAtSupplyZone`, `.isAtDemandZone`, `.zoneRank`, `.zoneHigh`, `.zoneLow` |

---

## Error Handling
| Scenario | Required Behaviour |
|----------|-------------------|
| `iHigh` / `iLow` returns 0 | Skip that bar iteration, continue loop |
| Zero-range candle | Skip (range = 0 causes division errors) |
| No zone found in lookback | Set `m_detectedZoneType = ZONE_NONE`, return safely |

---

## Testing Requirements
**Test 1:** Print detected zone High/Low on each bar. Visually verify against H4 chart supply/demand origins.
**Test 2:** Set lookback to 5 bars (insufficient). Verify no crash and `ZONE_NONE` returned.

---

## Git Deliverables
| Item | Value |
|------|-------|
| Branch | `feature/sprint1-engine1-supply-demand` |
| Commit Message | `feat: implement Engine1 SupplyDemand base-candle zone detection` |
| DoD Reference | `Docs/11_DEFINITION_OF_DONE.md` |
| PR Template | `Docs/12_PR_TEMPLATE.md` |
