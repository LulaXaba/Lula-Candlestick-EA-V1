# 03 — Coding Standards: MQL5 Rules & Naming Conventions

## File Naming
| Type | Convention | Example |
|------|-----------|---------|
| EA main file | PascalCase + version | `Lula_V1.mq5` |
| Class header | C prefix + PascalCase | `CPatternEngine.mqh` |
| Sub-module | C_ prefix | `C_ATRModule.mqh` |
| Enums & constants | PascalCase | `Defines.mqh` |
| Data structures | PascalCase | `DTOs.mqh` |

## Variable Naming
| Scope | Convention | Example |
|-------|-----------|---------|
| Class member | `m_` prefix | `m_atrPeriod` |
| Pointer member | `mp_` prefix | `mp_sensors` |
| Input parameter | `inp_` prefix | `inp_RiskPercent` |
| Global instance | `g_` prefix | `g_Sensors` |
| Local variable | camelCase | `barClose`, `stopDist` |
| Named constant | ALL_CAPS | `ATR_MULTIPLIER_NORMAL` |
| Enum prefix | `ENUM_` | `ENUM_ZONE_RANK` |

## Non-Negotiable Rules
1. **No magic numbers.** Every numeric literal → named constant in `Defines.mqh` or EA input.
2. **Every class has:** constructor, destructor, `Init()` returning `bool`, and `Deinit()`.
3. **`Init()` returning false triggers EA shutdown.** Log the error first.
4. **`OnTick()` must run in < 5ms.** No heavy loops. All scanning is bar-close only.
5. **All indicator handles validated** against `INVALID_HANDLE` immediately after creation.
6. **`CopyBuffer()` must be error-checked.** Never assume data availability.
7. **All errors logged** with: `PrintFormat("[ERROR] %s: <message>", __FUNCTION__)`.
8. **`#ifndef` include guards** in every `.mqh` file — no exceptions.
9. **`#property strict`** at top of every file (or inherited from main EA).

## Compile Requirements
- Target: MetaTrader 5 Build 3800+
- `#property strict` mandatory
- Zero compiler errors AND zero warnings before marking any sprint task complete
- Use `ArraySetAsSeries(buf, true)` before every `CopyBuffer()` call

## Preferred MQL5 APIs
```mql5
// Tick value — never hardcode
double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
double point   = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

// Lot bounds — always fetch from broker
double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

// Equity for drawdown
double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
```
