# Lula Price Action Execution Engine — V2 Master Plan

From Zone Reversal to Trend Structure Trading
Date: 2026-07-29
Status: Planning / Architecture Audit — APPROVED FOR IMPLEMENTATION
Scope: Full system redesign from V1 (reversal-at-zones) to V2 (trend-following structure)

## 1. The Core Shift: Why V2?

**V1 Problem**
* Trades were held too long, missing TP and reversing into SL.
* No concept of trend progression — entries were static zone plays.
* Exits were purely fixed SL/TP with no structural invalidation.
* No active post-entry monitoring beyond "wait and hope."

**V2 Solution**
* Trade with the trend, not against it.
* Enter at Higher Lows (longs) and Lower Highs (shorts).
* Exit when structure breaks, not when an arbitrary pip count is hit.
* Monitor trades with a 3-tier, bar-close-only system.
* Hybridize V2 structure with V1 institutional zones for confluence.
* Reintegrate KAMA as dynamic support/resistance — NOT as a trend definer.
* Golden Rule: If the structural level that justified your entry breaks, the thesis is dead — exit immediately, regardless of where your hard SL sits.

## 2. Trend Structure Model

**How V2 Defines Trend (ZigZag + Math)**
V2 uses the built-in MQL5 ZigZag indicator (iCustom calling standard ZigZag.ex5) to mathematically define structure. The human eye spots HH/HL easily; the algorithm reads the ZigZag buffer.

Buffer Read: Pull the last 4 valid, non-zero data points from the ZigZag buffer.

**Uptrend Confirmation:**
* Node 1 (New HL) > Node 3 (Old HL)
* Node 2 (New HH) > Node 4 (Old HH)

**Downtrend Confirmation:**
* Node 1 (New LH) < Node 3 (Old LH)
* Node 2 (New LL) < Node 4 (Old LL)

| Market State | ZigZag Evidence | Trade Bias |
| --- | --- | --- |
| Uptrend | Node 1 (HL) > Node 3 (HL) AND Node 2 (HH) > Node 4 (HH) | Long only |
| Downtrend | Node 1 (LH) < Node 3 (LH) AND Node 2 (LL) < Node 4 (LL) | Short only |
| Transition | Sequence breaks (e.g., HL followed by LL) | No trade / wait |
| Range | No clear 4-node sequence; ZigZag flat | No trade |

`CTrendStructure` updates on every H4 bar close, reads these nodes, and exposes `ENUM_TREND_STATE` (`UPTREND`, `DOWNTREND`, `RANGE`, `TRANSITION`).

**Why KAMA Does NOT Define Trend in V2**
In V1, `C_KAMAModule` and `C_TrendAnalyzer` used KAMA slope to define trend state. This is demoted in V2.
* The Problem: Moving Averages are mathematically lagging. If a strong uptrend suddenly breaks its last Higher Low (Change of Character), the structural trend is dead instantly. But a 50-period KAMA may still point upward for 10–20 candles before the math catches up. If the EA relies on KAMA for trend direction, it will buy a "dip" into the MA when the structure has already reversed.
* The Fix: ZigZag defines trend. KAMA is promoted to Dynamic Confluence and Momentum Veto.

**Timeframe Roles**
| Timeframe | Role | Why It Matters |
| --- | --- | --- |
| W1 | Macro regime | Multi-week bias — is the market trending or ranging? |
| D1 | Trend definition | Confirms ZigZag structure; filters noise |
| H4 | Operational structure | Current swing location. Where is the next HH/LL likely? |
| H1 | Entry timing | Is the pullback to HL/LH complete? Pattern confirmation. |
| M15 | Execution precision | Exact entry, SL placement, initial risk definition. |

## 3. The Three-Layer Confluence Model (The Venn Diagram)

Every valid V2 entry requires alignment across three independent geometry types. This is the institutional edge.

```
                    ┌─────────────────┐
                    │  ZIGZAG         │
                    │  (Structure)    │
                    │  "Is this a     │
                    │   Higher Low?"  │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
    ┌─────────▼────────┐    │    ┌─────────▼────────┐
    │  V1 ZONES         │    │    │  KAMA           │
    │  (Static S/R)     │    │    │  (Dynamic S/R)  │
    │  "Did price       │    │    │  "Are we at     │
    │   bounce here     │    │    │   the average   │
    │   before?"        │    │    │   cost basis?"  │
    └───────────────────┘    │    └─────────────────┘
                             │
                    ┌────────▼────────┐
                    │  ENTRY ZONE     │
                    │  (A+ Confluence)│
                    └─────────────────┘
```

**Layer 1: ZigZag Structure (The Pivot)**
Confirms the pullback is at a valid HL (longs) or LH (shorts). Provides the structural floor/ceiling for SL placement.
Question: "Is this a Higher Low?"

**Layer 2: V1 Zones (Static Institutional Memory)**
`CPriceZone` engines (Supply/Demand, Standard SR, Weekly Macro, Role Reversal).
A pullback to a ZigZag HL is infinitely stronger if that HL aligns with a previously broken Supply zone (Role Reversal) or a Demand zone.
Question: "Did price bounce here in the past?"

**Layer 3: KAMA (Dynamic Elastic Band)**
KAMA acts as a dynamic support/resistance line.
When a ZigZag HL aligns with the KAMA line, it means the pullback has reached the average mathematical cost basis.
Question: "Are we currently at the average cost basis?"

**The A+ Confluence Signal**
| Confluence Level | ZigZag | V1 Zone | KAMA | Signal Grade |
| --- | --- | --- | --- | --- |
| A+ | HL confirmed | Overlaps zone | At KAMA | Full size, normal risk |
| A | HL confirmed | Overlaps zone | Near KAMA | Full size |
| B | HL confirmed | No zone | At KAMA | Reduce lot by 25% |
| C | HL confirmed | No zone | Far from KAMA | Reduce lot by 50% |
| Reject | No HL/LH | — | — | No trade |

## 4. KAMA as Momentum Veto (The Filter)

| Scenario | KAMA Reading | Action |
| --- | --- | --- |
| Pullback to HL, price above H4 KAMA | Healthy dynamic support | Normal entry |
| Pullback to HL, price at H4 KAMA | Perfect elastic band snap | A+ confluence, full size |
| Pullback to HL, price crossed below H4 KAMA | Momentum deeply exhausted | Reduce lot by 50% |
| Pullback to HL, price well below H4 KAMA | Trend likely reversing | Reject entry |

## 5. V2 Entry Models (3 Types Only)

**Entry Type 1: Pullback to Structure (Bread & Butter)**
* **For Uptrends:** ZigZag H4/D1 confirms HH + HL sequence. H4 pulls back toward last HL. H1 prints reversal pattern. Entry long on H1/M15. SL below HL. TP1 is previous HH. TP2 is Fib extension.
* **For Downtrends:** Inverted.

**Entry Type 2: Breakout + Retest**
* **For Uptrends:** H4 consolidates, breaks above. H1 pulls back to broken HH level. Confluence check. Entry long. SL below retest level. TP1 is broken HH. TP2 is 1x range.
* **For Downtrends:** Inverted.

**Entry Type 3: Trend Reversal (Rare, HTF Only)**
* Only when W1/D1 structure breaks. This is the ONLY short setup in an uptrend context, and only after D1 confirms the trend is dead.

## 6. The 3-Tier Monitoring System

| Tier | Check Frequency | What It Checks | Purpose |
| --- | --- | --- | --- |
| Tier 1: Standard Pulse | Every H1 bar close | Structure + Momentum + Character | Main health check |
| Tier 2: Micro-Confirmation | Every M15 bar close | Candle shape, wick rejection | Zoom in when threatened |
| Tier 3: Strategic Review | Every H4 bar close | Higher timeframe alignment | Context, not exits |

## 7. The 4 Lenses (What We Actually Check)

* **Lens 1: Structure Integrity:** Did H1 close below HL (longs) / above LH (shorts)? YES -> EXIT 100%.
* **Lens 2: Momentum Progress:** Check last 3 closed H1 candles. 3/3 against -> Momentum dead, tighten SL.
* **Lens 3: Character Change:** H1 prints Lower Low (for longs). EXIT 50%, move SL to BE on rest.
* **Lens 4: Higher Timeframe Alignment:** H4 prints reversal pattern against you -> EXIT 100%.

## 8. The Decision Matrix

| Tier 1 (H1) | Tier 2 (M15) | Tier 3 (H4) | Decision |
| --- | --- | --- | --- |
| Structure broken | — | — | EXIT 100% |
| Momentum stalled (2/3) | M15 confirms rejection | — | Tighten SL to BE |
| Momentum dead (3/3) | — | — | EXIT 50%, BE rest |
| Character changed | — | — | EXIT 50%, BE rest |
| Everything green | — | H4 reversal pattern | EXIT 100% |
| Everything green | — | H4 aligned | HOLD |

## 9. Time Decay Rule
If trade open time > 2× Expected Move Time and progress < 50% → Exit.

## 10. Exit Logic Summary
Rules: Target Reached, Structure Break, Momentum Failure, Time Decay, HTF Veto, Partial Exit Safety.

## 11. Risk Management (V2)
Key Change: SL is no longer an ATR buffer. It is the structural invalidation point. TP is no longer arbitrary R:R. It is the next structural target.

## 12. Session & Environment Rules
Optional filters, Gap open rule.

## 13. V2 Architecture (Final)
```
Lula_V2.mq5
│
├── CMarketContext           
│   ├── CTrendStructure      
│   ├── CSensorEngines       
│   ├── C_KAMAModule         
│   └── C_AlignmentScorer    
│
├── CTradeSetupManager       
│   ├── Detectors/           
│   └── EntryModels/         
│       └── ConfluenceGrader 
│
├── CActiveTradeManager      
│   ├── CheckHealthH1()      
│   ├── CheckMicroM15()      
│   └── CheckMacroH4()       
│
├── CExecutionCore
│   ├── CRiskManager         
│   └── CTradeExecutor       
│       └── ClosePartial()   
│
└── Include/
    ├── Defines.mqh          
    └── DTOs.mqh             
```

## 14. Key Principles (Non-Negotiable)
Trade with trend. Enter at structure. Three-layer confluence required. SL at structure break. TP at structure. Partial exits at TP1. KAMA is Dynamic S/R. Monitor on bar close only. Exit on thesis death. Kill dead trades by time. No tick-watching.

## 15. V1 → V2: Side-by-Side Example
(Included from prompt)

## 16. Open Questions for Next Session
* ZigZag parameters (Depth=12, Deviation=5, Backstep=3?)
* Fibonacci extension choice (1.272 vs 1.618)
* Breakout consolidation rules
* V1 zone overlap tolerance
* Multi-symbol support
* KAMA parameters
* KAMA confluence variance

## 17. Next Steps (Implementation Order)
* Generate Docs/Plans/v2-architecture-spec.md
* Define branch names
* Scaffold CTrendStructure
* Scaffold C_KAMAModule upgrade
* Scaffold CActiveTradeManager
* Integrate CMarketContext
* Update CRiskManager
* Update CTradeExecutor
* Update Defines.mqh and DTOs.mqh
* Build ConfluenceGrader
