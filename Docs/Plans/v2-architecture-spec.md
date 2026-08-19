# V2 Architecture Specification

## Overview
This document is the formal contract defining the V2 architectural classes, their public interfaces, and the data flow. 

---

## 1. CMarketContext (The Global State)
**Responsibility**: Aggregates all structural and zone data into a unified V2 market view.
**Ownership**: Owns `CTrendStructure`, `CSensorEngines` (from V1), and `C_KAMAModule`.

### Public Interface
```cpp
bool Init(string symbol, ENUM_TIMEFRAMES tf);
void Update(); // Called on new bar to refresh sensors
SSensorData GetData() const; // Snapshot of the current state
```

---

## 2. CTrendStructure (The ZigZag Reader)
**Responsibility**: Mathematically defines the market structure using the ZigZag indicator.
**Ownership**: Lives inside `CMarketContext`.

### Public Interface
```cpp
bool Init(string symbol, ENUM_TIMEFRAMES tf, int depth, int dev, int step);
void Update(); // Reads latest nodes from ZigZag buffer on closed bars
ENUM_TREND_STATE GetTrendState() const; // UPTREND, DOWNTREND, RANGE, TRANSITION
bool GetLast4Nodes(SZZNode &nodes[]); // Fills array with the last 4 structural extremes
double GetLastHigh() const;
double GetLastLow() const;
```

---

## 3. CTradeSetupManager (The Evaluator)
**Responsibility**: Grades confluences and validates the 3 V2 Entry Models.
**Ownership**: Main EA instance. Owns all Pattern Detectors.

### Public Interface
```cpp
bool Init();
void EvaluateNewSetups(const SSensorData &context, SPatternResult &outResult);
ENUM_CONFLUENCE_GRADE GradeConfluence(double price, const SSensorData &context);
```

---

## 4. CActiveTradeManager (The Post-Entry Monitor)
**Responsibility**: Executes the 3-Tier monitor on active trades. Triggers soft/emergency exits.
**Ownership**: Main EA instance.

### Public Interface
```cpp
void MonitorTrades(const SSensorData &context); // Called on every bar
void CheckHealthH1(ulong ticket, const SSensorData &context); // Tier 1
void CheckMicroM15(ulong ticket, const SSensorData &context); // Tier 2
void CheckMacroH4(ulong ticket, const SSensorData &context);  // Tier 3
```

---

## 5. CRiskManager & CTradeExecutor (Execution Core V2)
**Responsibility**: Safe position sizing based on structural nodes and strict broker volume logic for partial exits.

### Key Additions
```cpp
// In CRiskManager
double CalculateStructureStopLoss(double entryPrice, ENUM_TRADE_DIRECTION dir, const SSensorData &context);
double CalculateFibTarget(double entryPrice, double swingHigh, double swingLow, double fibLevel);
double ApplyConfluenceLotMultiplier(double baseLot, ENUM_CONFLUENCE_GRADE grade);

// In CTradeExecutor
bool ClosePartial(ulong ticket, double percentToClose); // Enforces SYMBOL_VOLUME_MIN/STEP
```
