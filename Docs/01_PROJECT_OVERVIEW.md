# 01 — Project Overview: Lula Price Action Execution Engine V2.0

## Core Goals (V2 Upgrade)
1. **Trade with the Trend**: Shift from V1's static zone reversal plays to dynamic trend structure trading (Higher Lows / Lower Highs).
2. **Institutional Confluence**: Enforce the 3-Layer Confluence Model (ZigZag Structure + V1 Zones + KAMA Dynamic S/R) before any entry.
3. **Structure-Based Risk**: Use market structure for Stop Loss placement (below HL / above LH) rather than fixed ATR buffers. Exit immediately when the structure thesis breaks.
4. **Active Trade Management**: Move away from "wait and hope" by utilizing a 3-tier, bar-close-only post-entry monitoring system.

## The V2 Multi-Timeframe Mandate
The EA is **FORBIDDEN** from placing a trade unless it satisfies the 3-layer confluence:
- **Daily/H4 (Structure)**: ZigZag confirms a valid trend structure (HH/HL or LH/LL).
- **H4 (Zones & KAMA)**: Price pulls back to a structural node that intersects with a valid V1 Zone AND the KAMA dynamic support/resistance line.
- **H1/M15 (Execution)**: A valid candlestick reversal pattern (e.g., Engulfing, Pin Bar) confirms the entry at this specific institutional confluence zone.

## Design Philosophy
- **Structure Over Math**: The mathematical ZigZag defines trend, not moving averages. KAMA is purely a dynamic momentum check, not a trend-definer.
- **Bar-close logic only**: No mid-candle entries or exits.
- **Thesis-Driven Exits**: If the structural level that justified the entry breaks, the thesis is dead. The EA must exit immediately.
- **Time Decay**: Trades that stagnate and exceed 2x their expected move time without hitting 50% progress are aggressively closed.

## Memory Ownership Contract (MANDATORY)
This contract must be preserved across all architectural updates:
| Owner | Objects Owned | Deletion Responsibility |
|-------|--------------|------------------------|
| `CMarketContext` | `CTrendStructure`, `CSensorEngines`, `C_KAMAModule` | Destructor |
| `CSensorEngines` | All `CPriceZone*` in active zones | `ClearActiveZones()` |
| `CTradeSetupManager` | All entry models and pattern detectors | Destructor |
| `CActiveTradeManager`| Live trade state objects | Destructor |

### MQL5 Strict Array Rule
> **ALL `CopyBuffer()` calls MUST use dynamic arrays.**
> Static arrays (`double buf[N]`) are rejected by MQL5's strict mode.

## Success Criteria (V2 Upgrade Complete)
- EA correctly identifies HH/HL and LH/LL using ZigZag nodes without repainting issues at bar-close.
- SL dynamically locks to the structural level, and TPs are correctly projected via Fibonacci extensions.
- Partial closures respect broker `SYMBOL_VOLUME_MIN` limits without crashing.
- Live active management (H1/M15 checks) successfully tightens stops or exits early on momentum failure.
- No MQL5 compiler warnings (strict mode).

## Out of Scope
- Machine learning / AI signal generation
- Tick-by-tick micro-management
- Hedging strategies (EA strictly follows netting/single directional plays based on structure)
