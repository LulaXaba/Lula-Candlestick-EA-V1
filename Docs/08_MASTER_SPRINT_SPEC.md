# 08 — Master Sprint Specification (V2 Upgrade)

---

## Sprint 1: Architecture & Foundation
**Goal**: Establish the data structures, enums, and formal spec for V2.

### Tasks
- Create `Docs/Plans/v2-architecture-spec.md` with full class/method contracts.
- Update `Include/Defines.mqh` - Add V2 constants (ZigZag params, Fib levels, KAMA variances).
- Update `Include/DTOs.mqh` - Add `ENUM_TREND_STATE`, `ConfluenceGrade`, TP1/TP2 fields.

### Acceptance Criteria
- Specifications clearly outline the role of each new class.
- All Enums and constants compile without errors.

---

## Sprint 2: Core Context Engines
**Goal**: Build the indicators and state engines that understand the market.

### Tasks
- Scaffold `CTrendStructure` - Reads ZigZag buffer, validates nodes, and exposes the trend state.
- Scaffold/Upgrade `C_KAMAModule` - Promote to dynamic S/R.
- Integrate `CMarketContext` - Merge V1 `CSensorEngines`, `CTrendStructure`, and `C_KAMAModule`.

### Acceptance Criteria
- `CTrendStructure` correctly identifies HH/HL and LH/LL nodes via ZigZag.
- `CMarketContext` provides a unified view of the market state.
- Print() tests verify ZigZag node reading.

---

## Sprint 3: Trade Execution & Risk Safety
**Goal**: Upgrade the executor to handle structure-based exits and partials safely.

### Tasks
- Update `CRiskManager` - Dynamic SL (structure-based), TP1/TP2 calculations, lot scaling based on confluence grade.
- Update `CTradeExecutor` - Implement `ClosePartial()` with broker volume safety limits (`SYMBOL_VOLUME_MIN/STEP`).

### Acceptance Criteria
- Stop Loss is correctly calculated as the distance to the structural node.
- Partial closures execute successfully in MT5 strategy tester without volume limit errors.

---

## Sprint 4: Entry Models & Trade Management
**Goal**: Build the setups, grading, and post-entry monitoring logic.

### Tasks
- Build `ConfluenceGrader` - Logic to score setups A+, A, B, C based on 3-layer overlap.
- Scaffold `CTradeSetupManager` - Implements the 3 Entry Models (Pullback, Breakout, Trend Reversal).
- Scaffold `CActiveTradeManager` - Implement the 3-Tier monitor (`CheckHealthH1`, `CheckMicroM15`, `CheckMacroH4`) and the time decay logic.

### Acceptance Criteria
- Grades correctly assigned based on the Venn Diagram overlap.
- Post-entry monitor successfully tightens SL or closes trades based on momentum failure.

---

## Sprint 5: Final Integration & Review
**Goal**: Bring it all together in the main EA file.

### Tasks
- Update `Lula_V2.mq5` - Wire up the new classes into the main `OnTick()` loop based on bar-close execution.
- System-wide review and backtest validation.

### Acceptance Criteria
- Full compile with 0 errors/warnings.
- Backtest confirms Trend Structure entries and active exits.
