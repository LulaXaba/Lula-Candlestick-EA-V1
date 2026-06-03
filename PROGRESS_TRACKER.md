# Project Progress Tracker: Lula EA V1.0

## SPRINT 1: The Sensor Array
- [x] Project Architecture established.
- [x] Governance Documents written.
- [ ] Implement `Include/Defines.mqh` (Enums and Constants).
- [ ] Implement `Sprint1_Sensors/CPriceZone.mqh` (Data Object).
- [ ] Implement `Sprint1_Sensors/CSensorArray.mqh` (Manager).
- [ ] Code Engine 3: `WeeklyMacro()`.
- [ ] Code Engine 1: `SupplyDemand()`.
- [ ] Code Engine 2: `StandardSR()`.
- [ ] Code Engine 4: `RoleReversal()`.

## SPRINT 2: Pattern Recognition (Pending)
- [ ] `C_PinBarDetector.mqh`
- [ ] `C_EngulfingDetector.mqh` (Grade A flag required)
- [ ] `C_InsideBarDetector.mqh`
- [ ] `C_FalseBreakoutDetector.mqh` (body boundary rule)
- [ ] `CPatternEngine.mqh`

## SPRINT 3: State Machine (Pending)
- [ ] `C_TrendAnalyzer.mqh`
- [ ] `C_RangeAnalyzer.mqh`
- [ ] `C_ChoppyFilter.mqh`
- [ ] `C_RetracementDetector.mqh` (Retracement = valid state, not rejection)
- [ ] `C_AlignmentScorer.mqh`
- [ ] `CStateMachine.mqh`

## SPRINT 4: Execution & Risk (Pending)
- [ ] `CDecisionTree.mqh` (Gate 5 Override Clause, ATR gate, rollover filter)
- [ ] `CRiskManager.mqh`
- [ ] `CTradeExecutor.mqh` (retry loop, rollover window pause)
- [ ] `CCorrelationFilter.mqh`
