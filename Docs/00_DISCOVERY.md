# Discovery & Intent Documentation (V2)

## Project Origin & Core Philosophy
This project translates Munehisa Homma's "The Candlestick Trading Bible" from a discretionary retail strategy into a strict quantitative MQL5 Expert Advisor.

**The Human Intent:** Eliminate the psychological failure points of manual trading (fear, revenge trading, premature execution, and misidentifying choppy markets) by turning the visual patterns into pure algorithmic geometry.

---

## The Discovered Solutions (The "Why")

### 1. The Retracement Logic (Conflict Resolution)
- **Problem:** Retail traders freeze when the Daily chart is Bullish but the 4H chart is Bearish.
- **Discovery:** This is NOT a conflict. It is a "Retracement Phase." The 4H bearish move is simply price seeking liquidity at a Daily structural floor.
- **Action:** The bot must identify this dynamic and hunt for a bullish reversal pattern exactly where the 4H bearish move intersects the Daily support.

### 2. The 1H Confirmation Loophole (V1 Override Clause)
- **Problem:** Waiting for 1H market structure to shift after a massive 4H Engulfing Bar ruins the Risk:Reward ratio.
- **Discovery:** The sheer size of a 4H Engulfing Bar *is* the 1H structure shift.
- **Action:** Added an "Override Clause." If the 4H signal is a **Grade A Engulfing Bar**, the bot bypasses the 1H check and drops directly to the 15M for execution.

### 3. The False Breakout Timing Trap
- **Problem:** Executing an Inside Bar breakout on the 15M chart while the 4H candle is still forming leads to getting trapped.
- **Discovery:** The reversal candle must close back inside the **body** of the mother bar, not just the wick.
- **Action:** Execution is strictly locked until the 15M reversal candle permanently closes inside the 4H Mother Bar's established **body boundary**.

### 4. VIX75 Paradigm Shift
- **Problem:** VIX75 operates 24/7 without fundamental drivers (news).
- **Discovery:** VIX75 is a synthetic algorithmic asset designed to hunt liquidity (stops).
- **Action:** Standard Forex session filters do not apply. Instead, we use a strict volatility filter (`ATR(14) > 800`).

### 5. The Trend Structure Paradigm (V2 Upgrade)
- **Problem:** V1 trades were held too long, missing TP and reversing into SL. Moving averages (KAMA) lagged the true market structure.
- **Discovery:** Market structure (HH/HL) is best defined mathematically by ZigZag nodes, which immediately identify a Change of Character. Moving averages should only be used as dynamic cost-basis filters, not trend definers.
- **Action:** V2 introduces the **3-Layer Confluence Model** (ZigZag + V1 Zones + KAMA), shifts SL placement to structural invalidation points, and adds a **3-Tier Post-Entry Monitor** to actively close dead momentum trades early.

---

## Key Timeframe Chain (V2)
| Timeframe | Role |
|-----------|------|
| W1        | Macro regime bias |
| D1        | Trend definition / structural filtering |
| H4        | Operational structure (ZigZag HH/HL), Confluence Venn Diagram |
| H1        | Active post-entry monitoring (Health Pulse) / Entry timing |
| M15       | Execution precision & Micro-confirmation for warnings |

---

## Pattern Priority Order
1. **False Breakout** (highest — VIX75 stop-hunt model)
2. **Pin Bar** (strong rejection at structural node)
3. **Engulfing** (Grade A = execution ready)
4. **Inside Bar** (lowest — strictest timing rule applies)
