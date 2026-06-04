# Changelog

All notable changes to Lula V1 will be documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### In Progress
- Sprint 2: Pattern Recognition Engine (Pin Bar, Engulfing, Inside Bar, False Breakout)

---

## [0.2.0] - 2026-06-04 — Sprint 1: MQL5 Strict Compilation Fixes

### Fixed
- **Enum Synchronization (`Defines.mqh`):** Unified `ENUM_ZONE_RANK` and `ENUM_ZONE_TYPE` to include all
  identifiers required by the engine files. Added `RANK_STANDARD(10)`, `RANK_1_5_HIGH(20)`,
  `RANK_1_MAXIMUM(30)` to `ENUM_ZONE_RANK`. Added `ZONE_STANDARD_SR(4)`, `ZONE_WEEKLY_MACRO(5)`,
  `ZONE_DYNAMIC_KAMA(6)` to `ENUM_ZONE_TYPE`. Previous enum values (`RANK_WEAK=0`, `RANK_MINOR=1`,
  `RANK_MAJOR=2`, `RANK_EXTREME=3`) were integer-incompatible with engine expectations and replaced
  with properly weighted integer values matching the confluence scoring matrix.
- **Missing Constants (`Defines.mqh`):** Added `ROLE_REVERSAL_MAX_BARS(50)`,
  `RISK_REDUCTION_THRESHOLD(-4.0)`, and `VIX75_MAX_SPREAD(5.0)` which were referenced by
  `C_RoleReversalMonitor.mqh` and other engine files but not yet declared.
- **MQL5 Dynamic Array Fix (`C_ATRModule.mqh`):** Replaced stack-allocated `double buf[1]` in
  `FetchATR()` with a heap-dynamic array (`double buf[]; ArrayResize(buf, 1)`) to satisfy MQL5's
  `CopyBuffer()` strict reference requirement. Added `INVALID_HANDLE` guard.
- **MQL5 Dynamic Array Fix (`C_KAMAModule.mqh`):** Replaced stack-allocated `double buf[1]` in
  `Update()` with a heap-dynamic array (`double buf[]; ArrayResize(buf, 1)`). Added `INVALID_HANDLE`
  guard.
- **MQL5 Dynamic Array Fix (`CSensorArray.mqh`):** Replaced static `double w1_atr_array[15]` in
  `ScanMarketEnvironment()` with a dynamic array (`double w1_atr_array[]; ArrayResize(w1_atr_array, 15)`)
  and wrapped `CopyBuffer()` call in a success-check guard.
- **Syntax Fix (`CEngine2_StandardSR.mqh`):** Removed erroneous `out_zones[outSize].Init(m_symbol,
  lookback_bars)` call. `CPriceZone` has no `Init()` method — this call caused a cascade of 4 compiler
  syntax errors (unexpected token, undeclared identifier, operator expected).
- **Missing Accessor (`CEngine3_WeeklyMacro.mqh`):** Added `double GetWeeklyATR() const` accessor
  to resolve `undeclared identifier 'GetWeeklyATR'` error in `CSensorArray::GetData()`.

### Result
- **Sprint 1 compiles with 0 errors and 0 warnings** in MetaEditor 5. Sprint 1 is fully locked.

---

## [0.1.0] - Sprint 0 — Scaffold
### Added
- README, CHANGELOG, HANDOVER, PROGRESS_TRACKER root files
- Docs/ folder with 10 specification documents (00–09)
- Source/ folder with sprint sub-directories
- Lula_V1.mq5 main EA execution shell
- Lula_V1.mqproj MetaEditor project file
- Include/Defines.mqh — all global enums and constants
- Include/DTOs.mqh — SSensorData, SPatternResult, SMarketState structs
- Sprint1_Sensors/ — CSensorArray, C_ATRModule, C_KAMAModule, CPriceZone + 4 detector engines
- Sprint2_Patterns/ — CPatternEngine + 4 detectors (skeleton)
- Sprint3_State/ — CStateMachine + 5 analyzers (skeleton)
- Sprint4_Execution/ — CDecisionTree, CRiskManager, CTradeExecutor, CCorrelationFilter (skeleton)
