# 09 — Technical Research & MQL5 Constraints (V2)

## VIX75 (Volatility 75 Index) Specifics

### Tick Value & Point Size
Brokers vary on VIX75 decimals. The EA must dynamically calculate:
```mql5
double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
double point   = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
```
**Never hardcode** `0.01` or any point value.

### Spread Widening Window
VIX75 spreads widen **massively** during server rollovers, typically **23:55 to 00:05 broker time**.
- The EA **must pause all new trade execution** during this window.
- Trail stops aggressively on any open positions prior to this window.

### ATR Volatility Threshold
- **`VIX75_MIN_H4_ATR = 800` points** is the baseline for active volatility.
- Below 800 = algorithmic compression phase. **No entries allowed.**

---

## MQL5 Language & Execution Quirks

### ZigZag Indicator Quirks
The ZigZag indicator repaints on the current bar.
- Always evaluate ZigZag nodes on **closed bars** to lock in the structural points.
- Empty buffer values for ZigZag in MQL5 are usually `0.0` or `EMPTY_VALUE`. Validate this carefully when searching for nodes.

### Indicator Handle Placement
Do **NOT** declare `iCustom` or `iMA` inside `OnTick()`. This causes memory leaks.
Declare all indicator handles inside class constructors / `Init()` methods.

### Array Indexing (Critical)
By default, MQL5 arrays are indexed `[0] = oldest bar`.
For price action trading you **MUST** call `ArraySetAsSeries(array, true)` so:
- `[0]` = current forming candle
- `[1]` = last closed candle (the one you evaluate)

### Partial Close Volume Constraints
Broker volume limits will cause partial closure attempts to fail if not rounded correctly:
```cpp
double target_close = current_volume / 2.0;
double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
target_close = MathRound(target_close / lot_step) * lot_step;
if(target_close < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)) {
    // Cannot partial close
}
```

---

## Data Mapping Rules

### Trend Structure Nodes
To evaluate the trend, the EA needs the last **4 valid (non-zero) nodes** from the ZigZag buffer.
```mql5
// Node 1: Most recent structural extreme
// Node 2: Previous extreme
// Node 3: Older extreme
// Node 4: Oldest needed extreme
```

### Pattern Measurement Formulas
Always use these exact formulas:
```mql5
double body  = MathAbs(open - close);         // Candle body size
double range = MathAbs(high - low);           // Full candle range (High - Low)
double upperWick = high - MathMax(open, close);
double lowerWick = MathMin(open, close) - low;
```

---

## Broker Compatibility Notes
- History depth on VIX75: typically **6–12 months** on most brokers.
- Lot size limits: always clamp using `SYMBOL_VOLUME_MIN`, `SYMBOL_VOLUME_MAX`, `SYMBOL_VOLUME_STEP`.
