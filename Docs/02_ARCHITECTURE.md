# 02 — Architecture: SOLID & OOP Class Structure

## Design Principles (SOLID)
- **S** — Single Responsibility: One class, one job. No god classes.
- **O** — Open/Closed: Add new pattern detectors without modifying CPatternEngine.
- **L** — Liskov Substitution: All detectors follow the same Detect() interface.
- **I** — Interface Segregation: Small, focused public APIs per class.
- **D** — Dependency Inversion: CDecisionTree depends on pointers, not concrete instances.

## Data Flow
```
OnTick()
  └─ [new bar check]
       ├─ CSensorArray::Update()      → SSensorData
       ├─ CStateMachine::Update()     → SMarketState
       └─ CDecisionTree::Evaluate()
            ├─ Gate 1-3: SSensorData checks
            ├─ Gate 4:   CPatternEngine::Detect() → SPatternResult
            ├─ Gate 5:   SMarketState checks
            ├─ Gate 6-7: CRiskManager checks
            └─ CTradeExecutor::PlaceTrade()
```

## Class Hierarchy
```
Lula_V1.mq5  (Main EA Shell — OnInit/OnTick/OnDeinit)
│
├── CSensorArray          — Aggregates all sensors; exposes SSensorData
│   ├── C_ATRModule       — iATR handles for 5 timeframes
│   ├── C_KAMAModule      — iAMA (Kaufman) adaptive moving average
│   ├── CPriceZone        — Swing H/L supply & demand zone scanner
│   └── Detectors/
│       ├── CEngine1_Trend    — Trend context (KAMA slope + ATR)
│       ├── CEngine2_Range    — Range boundaries (swing H/L)
│       ├── CEngine3_Reversal — Reversal context detection
│       └── CEngine4_Breakout — Breakout / momentum detection
│
├── CPatternEngine        — Runs all detectors; returns best SPatternResult
│   ├── C_PinBarDetector
│   ├── C_EngulfingDetector
│   ├── C_InsideBarDetector
│   └── C_FalseBreakoutDetector
│
├── CStateMachine         — Derives ENUM_MARKET_STATE; exposes SMarketState
│   ├── C_TrendAnalyzer
│   ├── C_RangeAnalyzer
│   ├── C_ChoppyFilter        — ADX < threshold = choppy
│   ├── C_RetracementDetector — Fibonacci 38.2 / 50 / 61.8
│   └── C_AlignmentScorer     — 0-100 multi-TF score
│
└── CDecisionTree         — 7-Gate boolean logic
    ├── CRiskManager      — Position sizing + drawdown guard
    ├── CTradeExecutor    — CTrade order placement & trailing
    └── CCorrelationFilter
```

## Shared Data Structures (Include/)
- `SSensorData`    — snapshot of all sensor readings per bar
- `SPatternResult` — detected pattern + entry/SL/TP/R:R
- `SMarketState`   — market state enum + alignment score
- `ENUM_ZONE_RANK`, `ENUM_MARKET_STATE`, `ENUM_WEEKLY_BIAS`, etc.
