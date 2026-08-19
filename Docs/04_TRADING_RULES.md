# 04 — Trading Rules: The 3-Layer Confluence Model (V2)

## Overview
V2 abandons static zone reversal trading in favor of **Trend Structure Trading**. 
Every entry requires alignment across three independent geometry types (The Venn Diagram): ZigZag Structure, V1 Static Zones, and Dynamic KAMA.

---

## The Three-Layer Confluence Model

### Layer 1: ZigZag Structure (The Pivot)
- Uses MQL5 standard ZigZag to read the last 4 valid nodes.
- **Uptrend**: Node 1 (HL) > Node 3 (HL) AND Node 2 (HH) > Node 4 (HH).
- **Downtrend**: Node 1 (LH) < Node 3 (LH) AND Node 2 (LL) < Node 4 (LL).
- **Question**: "Is this a confirmed Higher Low or Lower High?"

### Layer 2: V1 Zones (Static Institutional Memory)
- A pullback to a ZigZag node is stronger if it aligns with a previously broken Supply zone (Role Reversal) or Demand zone.
- **Question**: "Did price bounce here in the past?"

### Layer 3: KAMA (Dynamic Elastic Band)
- KAMA acts as dynamic support/resistance, NOT a trend definer.
- It verifies if the structural pullback has reached the average mathematical cost basis.
- **Question**: "Are we currently at the average cost basis?"

---

## The A+ Confluence Signal & Grading

Before execution, `ConfluenceGrader` assigns a grade:

| Grade | ZigZag | V1 Zone | KAMA | Action |
|-------|--------|---------|------|--------|
| **A+** | HL/LH confirmed | Overlaps Zone | At KAMA | Full lot size, normal risk |
| **A** | HL/LH confirmed | Overlaps Zone | Near KAMA | Full lot size |
| **B** | HL/LH confirmed | No Zone | At KAMA | Reduce lot by 25% |
| **C** | HL/LH confirmed | No Zone | Far from KAMA | Reduce lot by 50% |
| **Reject**| No HL/LH | — | — | No trade |

**KAMA Momentum Veto**: If price pulls back to the HL but has crossed strongly *below* the H4 KAMA with a bearish close, the entry is rejected (trend likely reversing).

---

## V2 Entry Models (3 Types Only)

### Type 1: Pullback to Structure (Bread & Butter)
- **Context**: H4/D1 confirms trend sequence. Price pulls back to the structural node.
- **Trigger**: H1/M15 prints a reversal pattern (Engulfing, Pin Bar, FBO) AT or NEAR the structural node.
- **Stop Loss**: Below the HL (Uptrends) / Above the LH (Downtrends).
- **Targets**: TP1 = Previous Swing Extreme. TP2 = Fib 1.272 / 1.618 Extension.

### Type 2: Breakout + Retest
- **Context**: H4 consolidates near a Swing High, breaks above with momentum (Volatility Squeeze / ADX).
- **Trigger**: H1 pulls back to the broken level (Role Reversal). Confluence checked.
- **Targets**: TP1 = Broken level test. TP2 = 1x Consolidation Range or next Supply.

### Type 3: Trend Reversal (Rare, HTF Only)
- **Context**: W1/D1 structure breaks (e.g., long-standing uptrend prints first LL, then a LH pullback).
- **Trigger**: H4 price reaches the LH and shows rejection.
- **Targets**: TP1 = Previous LL. TP2 = Fib 1.618 extension downward.

---

## Execution Constraints
- **Gap Open Rule**: If a candle opens past the desired entry price, skip the trade (R:R is skewed).
- **Strict SL**: If the structural node breaks, the EA MUST exit immediately.
