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
│       ├── CEngine1_SupplyDemand — Explosive moves (1 touch + 2xATR)
│       ├── CEngine2_StandardSR   — Range boundaries (2+ touches)
│       ├── CEngine3_WeeklyMacro  — Weekly macro levels (6-month H/L)
│       └── C_RoleReversalMonitor — Broken level retest validation
│
├── CPatternEngine        — Orchestrator; runs all detectors; returns highest-tier CPatternResult
│   │
│   ├── Detectors/ (7 total — Prioritized by institutional weight)
│   │   ├── C_EngulfingDetector       — [Tier 1] Body engulf ≥ 1.5×; triggers Grade A bypass
│   │   ├── C_FalseBreakoutDetector   — [Tier 1] Zone pierce + close-back; triggers Grade A bypass
│   │   ├── C_ForceBarDetector        — [Tier 1] ≥ 80% body; ≥ 2.0×ATR displacement triggers Grade A bypass
│   │   ├── C_StarPatternDetector     — [Tier 1] Morning Star / Evening Star (3-candle reversal)
│   │   ├── C_PinBarDetector          — [Tier 2] Wick-ratio test; wick ≥ PINBAR_MIN_WICK_RATIO
│   │   ├── C_InsideBarDetector       — [Tier 3] Inside range; direction from bias alignment
│   │   └── C_DblhcDbhlcDetector      — [Tier 3] DBLHC (bullish) / DBHLC (bearish) ATR-variance matching extremes
│   │
│   ├── C_ContextAnalyzer             — Unified filter: tests Pivot Reversal and Daily Warning rules
│   │
│   └── Utility/
│       └── Cmp(double a, double b, double epsilon) — Tolerance-safe double comparison
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
- `CPatternResult` — detected pattern + tier + isGradeA + entry/SL/TP/R:R + `IsValid()` method
- `SMarketState`   — market state enum + alignment score
- `ENUM_ZONE_RANK` (WEAK=0, MINOR=5, STANDARD=10, MAJOR=15, 1_5_HIGH=20, 1_MAXIMUM=30, EXTREME=40)
- `ENUM_ZONE_TYPE`, `ENUM_MARKET_STATE`, `ENUM_WEEKLY_BIAS`, `ENUM_PATTERN_TYPE`, etc.

## Memory Ownership Contract
> [!IMPORTANT]
> The following rules were enforced during Sprint 1 and are **permanent architectural law**.
> Any future sprint code that violates these rules will introduce memory leaks or dangling pointers.

| Owner Class | Owns | Must NOT be freed by |
|-------------|------|----------------------|
| `CSensorArray` | All `CPriceZone*` in `m_active_zones[]` | Any engine class |
| `CSensorArray` | All 4 engine pointers | Any external caller |
| `CEngine3_WeeklyMacro` | `m_macroHighZone*`, `m_macroLowZone*` | `CSensorArray::ClearActiveZones()` |
| `C_RoleReversalMonitor` | **Nothing** — non-owning refs only | — |
| `CPatternEngine` | All 7 detector instances + 2 context readers | Destructor only |

**Critical sequence in `CSensorArray::ScanMarketEnvironment()`:**
1. `m_e4_rr.FlushWatchlist()` — FIRST (releases non-owning refs before zone deletion)
2. `ClearActiveZones()` — SECOND (deletes zone objects, resizes to 0)
3. Zone scan engines — THIRD (rebuild fresh zones)
