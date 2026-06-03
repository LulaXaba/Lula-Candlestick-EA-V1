# Technical Research & MQL5 Constraints

## VIX75 (Volatility 75 Index) Specifics

### Tick Value & Point Size
Brokers vary on VIX75 decimals. The EA must dynamically calculate:
```mql5
double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
double point   = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
```
**Never hardcode** `0.01` or any point value — always fetch from broker at runtime.

### Spread Widening Window
VIX75 spreads widen **massively** during server rollovers, typically **23:55 to 00:05 broker time**.
- The EA **must pause all new trade execution** during this window.
- Trail stops aggressively on any open positions prior to this window.
- **Code Impact:** `CDecisionTree::Evaluate()` or `CTradeExecutor` must check broker server time and block `PlaceTrade()` when inside the rollover window.

### ATR Volatility Threshold
- **`VIX75_MIN_ATR = 800` points** is the baseline for active volatility.
- Below 800 = algorithmic compression phase. **No entries allowed.**
- Above 800 = market is in active stop-hunt / liquidity mode. Patterns are valid.
- This is enforced as a hard constant in `Defines.mqh` — NOT a user input.

---

## MQL5 Language & Execution Quirks

### Indicator Handle Placement
Do **NOT** declare `iATR` or `iMA` inside `OnTick()`. This causes memory leaks.
Declare all indicator handles inside class constructors / `Init()` methods (called from `OnInit()`).
Use `CopyBuffer()` to retrieve latest values on each bar.

### Array Indexing (Critical)
By default, MQL5 arrays are indexed `[0] = oldest bar`.
For price action trading you **MUST** call `ArraySetAsSeries(array, true)` so:
- `[0]` = current forming candle
- `[1]` = last closed candle (the one you evaluate)

### OrderSend Retry Loop
VIX75 is highly volatile; requotes and slippage are common.
Always implement a retry loop (max 3 attempts) for order submission:
```mql5
int retries = 0;
bool sent = false;
while(!sent && retries < 3) {
    sent = m_trade.Buy(lots, _Symbol, price, sl, tp, comment);
    if(!sent) {
        PrintFormat("[WARN] OrderSend attempt %d failed: %d", retries+1, GetLastError());
        Sleep(200);
    }
    retries++;
}
```

### Tick Value Initialization Bug
Some VIX75 brokers return `SYMBOL_TRADE_TICK_VALUE = 0` on EA startup.
```mql5
// Fix: Retry loop in OnInit()
int retries = 0;
double tickVal = 0;
while(tickVal <= 0 && retries < 10) {
    Sleep(500);
    tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    retries++;
}
if(tickVal <= 0) return INIT_FAILED;
```

---

## Data Mapping Rules

### Weekly Macro Scan Depth (Engine 3)
To scan **6 months** of weekly data, the bot only needs `26` weekly bars.
Do **not** request 10,000 bars from the server — it is unnecessary and slow.
```mql5
#define WEEKLY_MACRO_LOOKBACK  26   // 26 weeks = ~6 months
```

### Pattern Measurement Formulas
Always use these exact formulas — never deviate:
```mql5
double body  = MathAbs(open - close);         // Candle body size
double range = MathAbs(high - low);           // Full candle range (High - Low)
double upperWick = high - MathMax(open, close);
double lowerWick = MathMin(open, close) - low;
```

### False Breakout Body Rule (Critical)
The 15M reversal candle must close inside the 4H mother bar **body**, not just the wick:
```mql5
double motherBodyHigh = MathMax(motherOpen, motherClose);
double motherBodyLow  = MathMin(motherOpen, motherClose);
bool closedInsideBody = (close15M < motherBodyHigh && close15M > motherBodyLow);
// Use this check — NOT High/Low of the mother bar
```

---

## Broker Compatibility Notes
- History depth on VIX75: typically **6–12 months** on most brokers.
- Validate available bars: `if(Bars(_Symbol, PERIOD_W1) < WEEKLY_MACRO_LOOKBACK) return INIT_FAILED;`
- Lot size limits: always clamp using `SYMBOL_VOLUME_MIN`, `SYMBOL_VOLUME_MAX`, `SYMBOL_VOLUME_STEP`.
