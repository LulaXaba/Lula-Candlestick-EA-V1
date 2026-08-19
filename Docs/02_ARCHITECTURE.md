# 02 — Architecture: SOLID & OOP Class Structure (V2)

## Design Principles (SOLID)
- **S** — Single Responsibility: One class, one job. `CTrendStructure` only reads ZigZag. `CActiveTradeManager` only monitors open trades.
- **O** — Open/Closed: Add new entry models to `CTradeSetupManager` without modifying core execution.
- **L** — Liskov Substitution: All setup engines follow the same entry interface.
- **I** — Interface Segregation: Small, focused public APIs per class.
- **D** — Dependency Inversion: Trade execution depends on abstract setup data.

## Data Flow (V2)
```
OnTick()
  └─ [new bar check]
       ├─ CMarketContext::Update()
       │    ├─ CTrendStructure::Update() (reads ZigZag, updates HH/HL arrays)
       │    ├─ CSensorEngines::Update() (V1 Zones)
       │    └─ C_KAMAModule::Update() (Dynamic S/R)
       │
       ├─ CActiveTradeManager::MonitorTrades()
       │    ├─ Tier 1: CheckHealthH1() (Structure/Momentum check)
       │    ├─ Tier 2: CheckMicroM15() (If warning flagged)
       │    └─ Tier 3: CheckMacroH4() (HTF veto check)
       │
       └─ CTradeSetupManager::EvaluateNewSetups()
            ├─ EntryModels: Pullback, Breakout, Reversal
            ├─ ConfluenceGrader (Scores A+, A, B, C based on 3-layer overlap)
            └─ CExecutionCore::PlaceTrade() (With structure SL & Fib TPs)
```

## Class Hierarchy (V2)
```
Lula_V2.mq5
│
├── CMarketContext           ← Owns V1 Zones + V2 Structure + KAMA
│   ├── CTrendStructure      ← ZigZag node reader; manages HH/HL arrays
│   ├── CSensorEngines       ← Maintains active Supply/Demand zones (from V1)
│   ├── C_KAMAModule         ← Dynamic S/R — "elastic band" confluence
│   └── C_AlignmentScorer    ← Checks if Structure overlaps with Zones + KAMA
│
├── CTradeSetupManager       ← Evaluates Entry Types
│   ├── Detectors/           ← 7 Candlestick pattern detectors (from V1)
│   └── EntryModels/         ← Pullback, Breakout, HTF Reversal logic
│       └── ConfluenceGrader ← A+ / A / B / C grading based on overlap
│
├── CActiveTradeManager      ← The 3-Tier Post-Entry Monitor
│   ├── CheckHealthH1()      ← Structure + Momentum + Character checks
│   ├── CheckMicroM15()      ← Zoom-in on warning flags
│   └── CheckMacroH4()       ← HTF alignment veto
│
├── CExecutionCore
│   ├── CRiskManager         ← Dynamic structure SL, Fib TP, lot sizing adjustments
│   └── CTradeExecutor       ← Order placement & Partial Exits
│       └── ClosePartial()   ← Broker volume safety check (SYMBOL_VOLUME_MIN/STEP)
```

## Shared Data Structures (Include/DTOs.mqh)
- `ENUM_TREND_STATE` — `UPTREND`, `DOWNTREND`, `RANGE`, `TRANSITION`
- `ENUM_CONFLUENCE_GRADE` — `GRADE_A_PLUS`, `GRADE_A`, `GRADE_B`, `GRADE_C`, `GRADE_REJECT`
- `SSensorData` — Context snapshot.
- `CPatternResult` — Now includes TP1, TP2, and ConfluenceGrade.

## Memory Ownership Contract
| Owner Class | Owns | Deletion Responsibility |
|-------------|------|-------------------------|
| `CMarketContext` | `CTrendStructure`, `CSensorEngines`, `C_KAMAModule`, `C_AlignmentScorer` | Destructor `~CMarketContext()` |
| `CSensorEngines` | All `CPriceZone*` | `ClearActiveZones()` |
| `CTradeSetupManager` | All entry models, detectors | Destructor `~CTradeSetupManager()` |
| `CExecutionCore` | `CRiskManager`, `CTradeExecutor` | Destructor `~CExecutionCore()` |
