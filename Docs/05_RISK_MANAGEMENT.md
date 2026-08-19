# 05 — Risk Management: Structure-Based Risk (V2)

## Core Risk Parameters (EA Inputs)
| Parameter | Default | Description |
|-----------|---------|-------------|
| `inp_RiskPercent` | 1.0 | % of account balance risked per trade |
| `inp_MaxDailyDrawdown` | 4.0 | % max daily drawdown |
| `inp_MaxTotalDrawdown` | 6.0 | % max total session drawdown before halt |
| `inp_Min_H4_ATR` | 800.0 | Minimum H4 ATR for VIX75 (0.0020 for Forex) |

## V2 Position Sizing Formula (Structure-Based)
Unlike V1, which used fixed ATR multipliers for the Stop Loss, V2 uses the exact distance to the structural invalidation point (HL/LH).

```mql5
// 1. Define hard stop based on structure
StopPrice = (Direction == LONG) ? ZigZag_HigherLow : ZigZag_LowerHigh;
StopDistPoints = MathAbs(EntryPrice - StopPrice) / Point;

// 2. Adjust lot size based on Confluence Grade
ConfluenceMultiplier = GetConfluenceMultiplier(Grade); // 1.0 for A+, 0.75 for B, 0.50 for C

// 3. Calculate Risk
RiskAmount = AccountBalance * (inp_RiskPercent / 100) * ConfluenceMultiplier;

// 4. Calculate Final Lot Size
LotSize = RiskAmount / (StopDistPoints * TickValue);
LotSize = Clamp(LotSize, SYMBOL_VOLUME_MIN, SYMBOL_VOLUME_MAX);
LotSize = Round(LotSize / SYMBOL_VOLUME_STEP) * SYMBOL_VOLUME_STEP;
```

## Targets & Partial Exits
- **TP1 (Structural Test)**: The previous Swing High/Low. 
- **TP2 (Extension)**: Fibonacci 1.272 or 1.618 extension of the pullback leg.

**Partial Exit Safety (MQL5 Limits)**:
When price reaches TP1, the EA closes 50% of the position and moves SL to breakeven. 
However, it must respect `SYMBOL_VOLUME_MIN`:
```cpp
double target_close = current_volume / 2.0;
target_close = MathRound(target_close / lot_step) * lot_step;

if(target_close >= min_volume) {
    PositionClosePartial(ticket, target_close);
} else {
    // Volume too small to split — bypass partial and move SL to BE instead
    MoveSLToBreakeven(ticket);
}
```

## Drawdown Guards (Maintained from V1)
- **Consecutive Loss Rule**: Max 2 consecutive losses per session → Halt trading for the day.
- **Margin Level Guard**: No trades if Margin Level < 200%.
- **Consecutive Loss Protection**: After 3 consecutive losses, reduce risk by 50% until the next win.
