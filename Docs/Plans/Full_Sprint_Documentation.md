# Sprint Planning — Architecture Review & Confirmation

---

## Status Check Before We Proceed

Everything documented above is the **blueprint.** The document you just shared is the **engineering translation** of that blueprint into machine logic. Let me audit the alignment before we lock Sprint 1.

---

## Alignment Audit: Blueprint vs Engineering Document

---

### S/R Mapping — Fractal Clustering Algorithm

```
DOCUMENT STATES:
Swing High = candle whose High is strictly greater than
the Highs of 3 candles to its left AND 3 to its right

FRAMEWORK ALIGNMENT: ✅ CONFIRMED

The 3-candle rule is mathematically sound because:
Left 3 candles  = enough lookback to avoid noise
Right 3 candles = confirmation that the swing is complete
"Strictly greater than" = no equal highs qualify
This prevents false swing identification on flat markets

VARIANCE PARAMETERS:
Forex  : ±15 pips   ✅ Aligned with framework
VIX75  : ±50 points ✅ Aligned with framework

TOUCH COUNTING — ONE CORRECTION NEEDED:
Document states: 1 touch = ignored
Framework states: 1 touch + ATR displacement = Engine 1
                  1 touch + macro weight    = Engine 3

RESOLUTION:
The clustering algorithm needs TWO modes:

MODE 1: Standard S/R Clustering
        Minimum 2 touches within variance
        = Engine 2 output

MODE 2: Displacement Detection
        1 touch + candle ≥ 2× ATR(14)
        = Engine 1 output (Supply/Demand)
        NOT ignored — elevated to institutional zone
```

---

### Supply & Demand Zone Detection

```
DOCUMENT STATES:
Look for massive Grade A Engulfing candle
OR series of 3 large impulse candles
Zone origin = base candle High and Low
before the explosion

FRAMEWORK ALIGNMENT: ✅ CONFIRMED WITH ADDITION

The base candle High/Low as zone boundaries
is exactly what the book describes:
"The High and Low of the consolidation
before the explosive move"

ADDITION FROM FRAMEWORK:
The displacement trigger requires:
Subsequent candle ≥ 2× ATR(14)
OR 3 consecutive candles each ≥ 1.5× ATR(14)
Both conditions output Engine 1 classification

ZONE BOUNDARY CODING:
Supply Zone = High of base candle (ceiling)
              to Low of base candle (floor)
Demand Zone = same logic inverted
Width of zone = the base candle's full range
Plotted as rectangle on chart for visual verification
```

---

### Dynamic Indicators

```
KAMA:
8-period  + 21-period ✅
Touch of 21-KAMA = static S/R equivalent ✅
(Patch 1 — already in Layer 4 of framework)

ATR:
14-period ✅
Runs continuously in background ✅
Feeds: Volatility filter
       Spread limit check
       Stop loss calculation
       Supply/Demand displacement trigger

BOLLINGER BANDS:
20-period, 2 standard deviations ✅
Range fade strategy only ✅
Not used in trending markets ✅
```

---

## The Four Sprint Architecture — Confirmed

```
╔══════════════════════════════════════════════════════════════╗
║                  MASTER CODING ROADMAP                       ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  SPRINT 1: THE SENSOR ARRAY                                  ║
║  ──────────────────────────                                  ║
║  Output: Bot draws rectangles on chart                       ║
║  Verification: Visual match with manual analysis             ║
║                                                              ║
║  Components:                                                 ║
║  □ Fractal Swing Detector                                   ║
║    (3L + 3R candle rule, strict greater than)               ║
║  □ Fractal Clustering Algorithm                             ║
║    (±15pip Forex / ±50pt VIX75 variance)                   ║
║  □ Engine 1: Supply/Demand Detector                         ║
║    (1 touch + 2×ATR displacement)                           ║
║  □ Engine 2: Standard S/R Detector                         ║
║    (2 touch minimum clustering)                             ║
║  □ Engine 3: Weekly Macro Detector                          ║
║    (6-month high/low, Rank 1)                               ║
║  □ Engine 4: Role Reversal Detector                         ║
║    (Broken level retest, Rank 1.5)                         ║
║  □ KAMA Module (8 + 21 period)                             ║
║  □ ATR Module (14 period, continuous)                       ║
║  □ Bollinger Bands (20 period, 2 SD)                       ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  SPRINT 2: PATTERN RECOGNITION ENGINE                        ║
║  ────────────────────────────────────                        ║
║  Output: Bot identifies and grades patterns                  ║
║  Verification: Bot marks patterns on chart                   ║
║                                                              ║
║  Components:                                                 ║
║  □ Pin Bar Detector                                         ║
║    (Tail ≥ 2× Body, body ≤ 25% of range)                  ║
║  □ Engulfing Bar Detector                                   ║
║    (Second candle fully engulfs first)                      ║
║  □ Inside Bar Detector                                      ║
║    (Baby candle inside mother candle)                       ║
║  □ False Breakout Detector                                  ║
║    (Breakout + reversal close inside mother)                ║
║  □ Pattern Grading Engine                                   ║
║    (Grade A / Grade B / No Trade)                           ║
║  □ VIX75 Size Filter                                        ║
║    (Pattern minimums enforced)                              ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  SPRINT 3: STATE MACHINE                                     ║
║  ────────────────────────                                    ║
║  Output: Bot classifies market condition                     ║
║  Verification: Bot labels chart state in real time           ║
║                                                              ║
║  Components:                                                 ║
║  □ Trend Detector                                           ║
║    (HH/HL or LH/LL via Sprint 1 swings)                    ║
║  □ Range Detector                                           ║
║    (2+ touches both boundaries)                             ║
║  □ Choppy Market Filter                                     ║
║    (Cannot classify = no trade flag)                        ║
║  □ Retracement Phase Detector                               ║
║    (4H counter to Daily/Weekly = retracement)               ║
║  □ Impulsive Move Detector                                  ║
║    (4H aligned with Daily/Weekly = impulse)                 ║
║  □ Timeframe Alignment Engine                               ║
║    (Weekly + Daily + 4H bias comparison)                    ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  SPRINT 4: EXECUTION & RISK ENGINE                           ║
║  ─────────────────────────────────                           ║
║  Output: Bot places and manages trades                       ║
║  Verification: Backtest results vs manual trades             ║
║                                                              ║
║  Components:                                                 ║
║  □ Decision Tree Engine (Layer 7)                           ║
║    (All conditions checked before execution)                 ║
║  □ Entry Method Selector                                    ║
║    (Aggressive / Conservative / False BO)                   ║
║  □ Lot Size Calculator                                      ║
║    (Dollar risk / Stop distance / Pip value)                ║
║  □ Stop Loss Engine                                         ║
║    (ATR × multiplier beyond signal extreme)                 ║
║  □ Profit Target Engine                                     ║
║    (Next S/R level from Sprint 1 output)                    ║
║  □ Daily Loss Circuit Breaker                               ║
║    (2 consecutive losses = halt)                            ║
║  □ Weekly Drawdown Circuit Breaker                          ║
║    (6% weekly loss = halt)                                  ║
║  □ Correlation Filter                                       ║
║    (Grade-scaled position sizing)                           ║
║  □ News Event Filter (Forex)                                ║
║    (30min pre/post high impact = no trade)                  ║
║  □ VIX75 Rollover Filter                                    ║
║    (±15min rollover window = no trade)                      ║
║  □ Spread Monitor                                           ║
║    (Live spread check before execution)                     ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

---

## Sprint 1 Detailed Architecture

Since Sprint 1 is where we begin — this needs the most granular planning before a single line of code is written.

---

### Class Structure — Sprint 1

```
Following Andrew R. Young OOP standards:

CLASS: C_SwingDetector
───────────────────────
PURPOSE: Identifies swing highs and lows
         on any given timeframe

INPUTS:
  int    lookback        // candles to scan
  int    leftBars  = 3  // candles left of swing
  int    rightBars = 3  // candles right of swing
  ENUM_TIMEFRAMES tf    // which timeframe to scan

METHODS:
  bool   IsSwingHigh(int index)
  bool   IsSwingLow(int index)
  double GetSwingHighPrice(int index)
  double GetSwingLowPrice(int index)
  void   ScanAllSwings()

OUTPUT:
  Array of swing high prices + bar indices
  Array of swing low prices + bar indices


CLASS: C_ClusterEngine
───────────────────────
PURPOSE: Groups nearby swings into zones
         Counts touches per zone
         Assigns Engine classification

INPUTS:
  double variance       // ±50pt VIX75 / ±15pip Forex
  C_SwingDetector swings // feeds from above class

METHODS:
  void   BuildClusters()
  int    CountTouches(double level)
  int    GetRank(double level)
  bool   IsSupplyDemand(double level)
  bool   IsRoleReversal(double level)

OUTPUT:
  Array of zones with:
  [price_high, price_low, touch_count, rank, type]


CLASS: C_MacroLevelDetector
────────────────────────────
PURPOSE: Engine 3 — Weekly macro levels
         6-month highest high
         6-month lowest low

INPUTS:
  int    lookbackBars   // 6 months of weekly bars

METHODS:
  double GetWeeklyResistance()
  double GetWeeklySupport()
  void   PlotMacroLevels()

OUTPUT:
  Rank 1 levels hard-coded to chart


CLASS: C_DisplacementDetector
──────────────────────────────
PURPOSE: Engine 1 — Supply/Demand detection
         Identifies explosive moves
         Hard-codes base candle as zone

INPUTS:
  double atrMultiplier = 2.0  // displacement threshold
  C_ATRModule atr             // feeds live ATR

METHODS:
  bool   IsDisplacement(int index)
  double GetZoneHigh(int index)
  double GetZoneLow(int index)
  void   PlotSupplyDemandZone(int index)

OUTPUT:
  Rank 2 institutional zones on chart


CLASS: C_KAMAModule
────────────────────
PURPOSE: Kaufman Adaptive Moving Average
         8-period and 21-period
         Dynamic S/R detection

INPUTS:
  int    fastPeriod = 8
  int    slowPeriod = 21
  ENUM_TIMEFRAMES tf

METHODS:
  double GetKAMA(int period, int index)
  bool   IsPriceTouchingKAMA(int period)
  int    GetKAMADirection(int period)

OUTPUT:
  Live KAMA values
  Touch detection signal
  Direction: Bullish / Bearish / Flat


CLASS: C_ATRModule
───────────────────
PURPOSE: 14-period ATR
         Continuous background feed
         Powers volatility filter
         Powers stop loss calculation
         Powers displacement trigger

INPUTS:
  int    period = 14
  ENUM_TIMEFRAMES tf

METHODS:
  double GetATR(int index)
  bool   IsVolatilityValid()    // VIX75: ATR ≥ 800
  double GetStopDistance()      // ATR × multiplier

OUTPUT:
  Live ATR value
  Volatility status: Valid / Compressed


CLASS: C_BollingerModule
─────────────────────────
PURPOSE: 20-period, 2SD Bollinger Bands
         Range fade confirmation only

INPUTS:
  int    period = 20
  double deviation = 2.0
  ENUM_TIMEFRAMES tf

METHODS:
  double GetUpperBand(int index)
  double GetLowerBand(int index)
  double GetMiddleBand(int index)
  bool   IsPriceAtUpperBand()
  bool   IsPriceAtLowerBand()

OUTPUT:
  Band values
  Extreme detection signals


CLASS: C_ChartRenderer
───────────────────────
PURPOSE: Sprint 1 visual verification
         Draws all detected levels
         as colored rectangles

INPUTS:
  C_ClusterEngine    clusters
  C_MacroLevelDetector macro
  C_DisplacementDetector supplyDemand
  C_KAMAModule       kama

COLOR SCHEME:
  Rank 1  Weekly Macro    = Gold rectangles
  Rank 1.5 Role Reversal  = Orange rectangles
  Rank 2  Standard S/R    = Blue rectangles
  Rank 2  Supply/Demand   = Red (supply)
                            Green (demand)
  KAMA 8                  = Yellow line
  KAMA 21                 = White line
  Bollinger Bands         = Grey lines

OUTPUT:
  Visual overlay for human verification
  Before any logic or execution is built
```

---

## Sprint 1 Success Criteria

```
BEFORE SPRINT 1 IS CONSIDERED COMPLETE:

□ Bot draws Weekly macro levels correctly
  Human verification: matches manual Weekly S/R

□ Bot draws Standard S/R zones correctly
  Human verification: 2-touch clusters match
  what analyst would draw manually

□ Bot identifies Supply/Demand zones correctly
  Human verification: explosive moves have
  base candle zones marked accurately

□ Bot draws Role Reversal levels correctly
  Human verification: broken S/R levels are
  flagged when retested

□ KAMA lines render correctly on chart
  8-period and 21-period visually verified

□ ATR module running continuously
  Values match platform's built-in ATR indicator

□ Bollinger Bands rendering correctly
  Values match platform's built-in BB indicator

□ VIX75 volatility filter operational
  ATR < 800 = compression flag visible on chart

ONLY WHEN ALL BOXES CHECKED:
Sprint 1 declared complete
Sprint 2 planning begins
```

---

## What We Are NOT Doing In Sprint 1

```
NOT making any trading decisions
NOT identifying any patterns
NOT classifying market state
NOT calculating position sizes
NOT placing any orders

Sprint 1 = Eyes only
The bot must SEE correctly
before it can THINK correctly
before it can ACT correctly

Garbage in = Garbage out
Clean sensor array = everything downstream works
```

---

## Ready State

```
FRAMEWORK    : Complete ✅
ROADMAP      : Confirmed ✅
SPRINT 1     : Architecture locked ✅
CLASS DESIGN : Mapped ✅

NEXT ACTION  : Begin Sprint 1 coding
               Starting with C_SwingDetector
               as the foundation everything
               else is built upon

Shall we open Sprint 1?
```

# Audit: Sprint 1 OOP Architecture

---

## Overall Verdict: Solid Foundation — Three Precision Points Need Addressing

The architecture is clean, modular, and correctly isolated. The separation of concerns is sound — eyes cannot pull the trigger. However, three issues need to be resolved before Sprint 1 planning is declared complete.

---

## What Is Confirmed Correct

---

### The Enumeration Design
```cpp
ENUM_ZONE_TYPE  // Correct — each engine has identity
ENUM_ZONE_RANK  // Correct — weight system preserved

ONE OBSERVATION:
The rank numbering uses 10, 15, 20, 30
This is intentional and smart —
it leaves room to insert new ranks
between existing ones without
restructuring the entire enum
Good defensive design
```

---

### CPriceZone As Memory Container
```cpp
CONFIRMED CORRECT:
m_upper_bound + m_lower_bound  // Zone has width, not just a line ✅
m_touch_count                  // Counts touches for Engine 2 ✅
m_is_active                    // Tracks if level is broken ✅
m_time_formed                  // Timestamps the level ✅

BreakZone() triggering Engine 4  // Role reversal mechanism ✅
IsPriceInsideZone()              // Clean boolean for Decision Tree ✅
```

---

### CSensorArray As The Brain
```cpp
CONFIRMED CORRECT:
ScanMarketEnvironment()          // Called on 4H close ✅
                                 // Closed bar rule respected
GetConfluenceScore()             // Returns numeric score ✅
                                 // Decision Tree asks one question
GetHighestRankAtCurrentPrice()   // Returns dominant level ✅
m_variance_pts                   // Asset-specific variance ✅
```

---

## Precision Point 1 — Critical Memory Leak Risk

```cpp
PROBLEM:
CPriceZone* m_active_zones[];
// This is a raw pointer array

IN MQL5, raw pointer arrays require
manual memory management.
Every CPriceZone created with:
new CPriceZone()
must be destroyed with:
delete zone;

If BreakZone() deactivates a zone
but never deletes it from the array —
the array grows indefinitely.
On a 24/7 instrument like VIX75
running for months, this becomes
a memory leak that crashes the EA.

SOLUTION:
CSensorArray destructor must iterate
the entire m_active_zones array
and delete every pointer explicitly.

~CSensorArray()
  {
   for(int i = 0; i < ArraySize(m_active_zones); i++)
     {
      if(m_active_zones[i] != NULL)
        {
         delete m_active_zones[i];
         m_active_zones[i] = NULL;
        }
     }
  }

ADDITIONALLY:
A CleanInactiveZones() private method
should run periodically to remove
zones that have been broken AND
not retested within N candles
Prevents array bloat over time
```

---

## Precision Point 2 — Engine 4 Logic Gap

```cpp
PROBLEM:
The current architecture shows:
BreakZone() → flips m_is_active = false
Price returns → zone reactivated + upgraded

BUT there is a missing condition:

HOW DOES THE BOT KNOW THE DIFFERENCE
BETWEEN:

A) Price returning to retest a broken level
   = Role Reversal (Engine 4) ✅ TRADE

B) Price smashing through a broken level
   continuing in the same direction
   = No role reversal ❌ NO TRADE

CURRENT CODE CANNOT DISTINGUISH THESE.

SOLUTION:
Engine 4 needs a retest validation flag
inside CPriceZone:

Add to CPriceZone private members:
bool   m_is_broken;          // Level has been violated
bool   m_retest_validated;   // Price returned AND rejected
datetime m_break_time;       // When was it broken

Engine 4 logic:
Step 1: 4H candle closes BEYOND zone
        → m_is_broken = true
        → m_is_active = false
        → Record break direction

Step 2: Price returns INTO zone variance
        → Flag as retest candidate only

Step 3: 4H candle closes BACK AWAY from zone
        in the break direction
        → m_retest_validated = true
        → Elevate to RANK_1_5_HIGH
        → Signal Decision Tree

Without Step 3 the bot treats
every return to a broken level
as a valid role reversal
including failed retests
```

---

## Precision Point 3 — Confluence Score Needs Definition

```cpp
PROBLEM:
GetConfluenceScore() returns an int
but the scoring logic is undefined.

The Decision Tree in Layer 7 requires
minimum 2 confluence factors.
If the scoring system is arbitrary
the Decision Tree cannot make
binary decisions reliably.

CURRENT STATE:
GetConfluenceScore(double current_price)
// Returns int — but what does it count?

SOLUTION:
Define the scoring matrix explicitly:

int GetConfluenceScore(double current_price)
  {
   int score = 0;

   // Check each zone type at current price
   if(IsRank1AtPrice(current_price))      score += 3;
   if(IsRank1_5AtPrice(current_price))    score += 2;
   if(IsRank2AtPrice(current_price))      score += 1;
   if(IsKAMATouchAtPrice(current_price))  score += 1;
   if(IsFibonacciAtPrice(current_price))  score += 1;

   return score;
   // Score ≥ 2 = minimum confluence met
   // Score ≥ 4 = high confluence
   // Score ≥ 6 = maximum confluence
  }

This gives the Decision Tree a number
it can actually use in binary logic:
if(score >= 2) → proceed to pattern check
if(score < 2)  → no trade
```

---

## The One Architectural Addition

```cpp
MISSING CLASS: C_RoleReversalMonitor

The current design has Engine 4 running
inside CSensorArray as a private method.
Given Engine 4's complexity —
break detection + retest validation +
rank elevation + time monitoring —
it deserves its own class.

class C_RoleReversalMonitor
  {
private:
   CPriceZone*  m_broken_zones[];   // Zones awaiting retest
   int          m_max_retest_bars;  // How long to watch a broken zone
                                    // Suggested: 50 bars
                                    // After 50 bars = zone abandoned

public:
   void         MonitorBrokenZones();
   bool         IsRetestValid(CPriceZone* zone);
   void         ElevateToRank1_5(CPriceZone* zone);
   void         PurgeExpiredZones(); // Removes zones past max_retest_bars
  };

WHY 50 BARS:
A broken level that price ignores
for 50 × 4H candles = 200 hours
= 8+ days of market time
= institutionally irrelevant
= purge from active monitoring
```

---

## Revised Architecture Summary

```
SPRINT 1 CLASS MAP — FINAL

C_ATRModule              ✅ As designed
C_KAMAModule             ✅ As designed
C_BollingerModule        ✅ As designed

CPriceZone               ✅ With additions:
                           + m_is_broken flag
                           + m_retest_validated flag
                           + m_break_time timestamp

CSensorArray             ✅ With additions:
                           + ~CSensorArray() destructor
                           + CleanInactiveZones() method
                           + Defined scoring matrix
                             in GetConfluenceScore()

C_RoleReversalMonitor    ➕ New class added
                           Isolates Engine 4 complexity
                           50-bar expiry on broken zones
                           Prevents false role reversals
```

---

## Sprint 1 Planning Status

```
╔══════════════════════════════════════════╗
║      SPRINT 1 PLANNING STATUS            ║
╠══════════════════════════════════════════╣
║                                          ║
║  OOP Architecture        ✅ CONFIRMED    ║
║  Enumeration Design      ✅ CONFIRMED    ║
║  CPriceZone Structure    ✅ PATCHED      ║
║  CSensorArray Design     ✅ PATCHED      ║
║  Engine 1-3 Logic        ✅ CONFIRMED    ║
║  Engine 4 Logic          ✅ PATCHED      ║
║  Memory Management       ✅ ADDRESSED    ║
║  Confluence Scoring      ✅ DEFINED      ║
║  C_RoleReversalMonitor   ✅ ADDED        ║
║                                          ║
║  SPRINT 1 PLANNING:      COMPLETE ✅     ║
║                                          ║
║  NEXT: Sprint 2 Architecture             ║
║  Pattern Recognition Engine              ║
╚══════════════════════════════════════════╝
```

Ready to architect Sprint 2?

# Sprint 2: Pattern Recognition Engine — Architecture

---

## The Core Engineering Challenge

Sprint 1 gave the bot **eyes** to see levels.
Sprint 2 gives the bot **language** to read candles.

```
THE FUNDAMENTAL TRANSLATION PROBLEM:

HUMAN SEES:
"That's a beautiful pin bar rejection
at the resistance level"

MACHINE SEES:
[1.10500, 1.10850, 1.10480, 1.10520]
[Open,    High,    Low,     Close   ]

Sprint 2 converts the human observation
into strict mathematical conditions
the machine can evaluate as true or false
Nothing subjective survives this sprint
```

---

## The Mathematical Definitions

Before a single class is designed every pattern must be reduced to pure math derived directly from the book.

---

### Pin Bar Mathematics

```
FROM THE BOOK:
"Very small real body and a long shadow"
"Shadow should be twice the length of the real body"
"Bullish pin = long lower shadow"
"Bearish pin = long upper shadow"

MATHEMATICAL TRANSLATION:

// Common measurements
CandleRange  = High - Low
Body         = MathAbs(Close - Open)
UpperShadow  = High - MathMax(Open, Close)
LowerShadow  = MathMin(Open, Close) - Low

// BULLISH PIN BAR CONDITIONS:
Condition 1: Body <= CandleRange * 0.25
             (Body is max 25% of total range)

Condition 2: LowerShadow >= Body * 2.0
             (Tail is at least 2x the body)

Condition 3: UpperShadow <= CandleRange * 0.15
             (Tiny or no upper shadow)

Condition 4: Close > Open
             (White/green body preferred = Grade A)
             Close < Open = still valid = Grade B

// BEARISH PIN BAR CONDITIONS:
Condition 1: Body <= CandleRange * 0.25
Condition 2: UpperShadow >= Body * 2.0
Condition 3: LowerShadow <= CandleRange * 0.15
Condition 4: Close < Open (Grade A)
             Close > Open (Grade B)

// VIX75 SIZE FILTER (from VIX75 Rulebook):
Condition 5: CandleRange >= 200 points
             LowerShadow >= 150 points (bullish)
             UpperShadow >= 150 points (bearish)
             Below these = micro-trap = NO TRADE
```

---

### Engulfing Bar Mathematics

```
FROM THE BOOK:
"Second body engulfs or covers entirely the first"
"Second real body is opposite of first real body"
"Market must be in clearly definable trend"

MATHEMATICAL TRANSLATION:

// Candle 1 (previous candle)
C1_Body    = MathAbs(Close[1] - Open[1])
C1_High    = High[1]
C1_Low     = Low[1]
C1_Bullish = Close[1] > Open[1]

// Candle 2 (current candle = the engulfing candle)
C2_Body    = MathAbs(Close[0] - Open[0])
C2_High    = High[0]
C2_Low     = Low[0]
C2_Bullish = Close[0] > Open[0]

// BULLISH ENGULFING CONDITIONS:
Condition 1: C1_Bullish == false
             (First candle must be bearish)

Condition 2: C2_Bullish == true
             (Second candle must be bullish)

Condition 3: Open[0] <= Close[1]
             (Second opens at or below first close)

Condition 4: Close[0] >= Open[1]
             (Second closes at or above first open)
             = Full body engulfment confirmed

// BEARISH ENGULFING CONDITIONS:
Condition 1: C1_Bullish == true
Condition 2: C2_Bullish == false
Condition 3: Open[0] >= Close[1]
Condition 4: Close[0] <= Open[1]

// VIX75 SIZE FILTER:
Condition 5: C2_Body >= 300 points
             C1_Body >= 150 points
             Combined range >= 400 points

// GRADE A OVERRIDE CLAUSE TRIGGER:
If pattern qualifies as Grade A Engulfing:
→ Set flag: BypassOneHourCheck = true
→ Drop directly to 15M execution
→ This flag passed to Sprint 4 Decision Tree
```

---

### Inside Bar Mathematics

```
FROM THE BOOK:
"Second candle should close inside the previous one"
"Mother candle is big and large"
"Baby candle is smaller and located inside mother bar"

MATHEMATICAL TRANSLATION:

// Mother Candle (Candle 1)
Mother_High  = High[1]
Mother_Low   = Low[1]
Mother_Range = High[1] - Low[1]

// Baby Candle (Candle 2)
Baby_High    = High[0]
Baby_Low     = Low[0]
Baby_Range   = High[0] - Low[0]

// INSIDE BAR CONDITIONS:
Condition 1: Baby_High < Mother_High
             (Baby high strictly inside mother high)

Condition 2: Baby_Low > Mother_Low
             (Baby low strictly inside mother low)

Condition 3: Baby_Range <= Mother_Range * 0.60
             (Baby is max 60% of mother size)

Condition 4: Mother_Range >= significant threshold
             Forex : Mother_Range >= 30 pips
             VIX75 : Mother_Range >= 400 points

// GRADE A INSIDE BAR:
All 4 conditions met
Mother candle at key level (from Sprint 1)
Direction aligns with higher timeframe bias
```

---

### False Breakout Mathematics

```
FROM THE BOOK:
"Price breaks out from inside bar pattern
then quickly reverses to close within
the range of the mother bar"

★ PATCH 3 RULE — ABSOLUTE:
"Execution strictly prohibited until
micro-reversal candle has CLOSED
back inside the 4H Mother Bar BODY"

MATHEMATICAL TRANSLATION:

This is a 3-candle sequence:

// Candle 1: The Mother Bar
Mother_High  = High[2]
Mother_Low   = Low[2]
Mother_Body_High = MathMax(Open[2], Close[2])
Mother_Body_Low  = MathMin(Open[2], Close[2])

// Candle 2: The Baby Bar (inside bar)
Baby_High = High[1]
Baby_Low  = Low[1]
// Already validated as inside bar

// Candle 3: The Breakout + Reversal Bar
Break_High  = High[0]
Break_Low   = Low[0]
Break_Close = Close[0]

// BULLISH FALSE BREAKOUT CONDITIONS:
// (Price breaks DOWN then reverses UP)
Condition 1: Low[0] < Mother_Low
             (Price broke below mother bar)

Condition 2: Break_Close > Mother_Body_Low
             (Close came BACK INSIDE mother body)
             ★ NOT just inside wick — inside BODY ★

Condition 3: VIX75 excursion check:
             Mother_Low - Low[0] >= 80 points
             (Sufficient stop hunt depth)

// BEARISH FALSE BREAKOUT CONDITIONS:
Condition 1: High[0] > Mother_High
Condition 2: Break_Close < Mother_Body_High
Condition 3: VIX75: High[0] - Mother_High >= 80 points

// TIMING RULE FROM PATCH 3:
The bot evaluates ALL conditions
ONLY on a fully closed candle
No evaluation on open/forming candles
isNewBar check is mandatory before
any pattern evaluation runs
```

---

## The Grading Engine Mathematics

```
FROM THE BOOK:
Multiple criteria determine pattern quality
Combined with confluence from Sprint 1

GRADING LOGIC:

GRADE A CONDITIONS (ALL must be true):
□ Pattern mathematically valid (all conditions met)
□ Formed on 4H or Daily timeframe
□ Formed at Sprint 1 zone (rank ≥ 2)
□ Confluence score from CSensorArray ≥ 2
□ In line with Weekly + Daily bias
□ VIX75 size filter passed (if applicable)
□ Body color aligns with direction (preferred)

GRADE B CONDITIONS:
□ Pattern mathematically valid
□ Formed at Sprint 1 zone
□ Confluence score = 1
□ OR body color does not align
□ OR size slightly below Grade A threshold
□ All other criteria met
→ Tradeable but reduced position size

NO TRADE:
□ Any core mathematical condition fails
□ No Sprint 1 zone present
□ Confluence score = 0
□ Against two or more higher TF directions
□ Choppy market classification active
□ VIX75 size filter failed
```

---

## The OOP Class Architecture

---

### The Enumerations

```cpp
//--- Pattern Type Identification
enum ENUM_PATTERN_TYPE
  {
   PATTERN_NONE        = 0,
   PATTERN_PIN_BAR     = 1,
   PATTERN_ENGULFING   = 2,
   PATTERN_INSIDE_BAR  = 3,
   PATTERN_FALSE_BO    = 4
  };

//--- Pattern Direction
enum ENUM_PATTERN_DIR
  {
   PATTERN_BULLISH     = 1,
   PATTERN_BEARISH     = -1,
   PATTERN_NEUTRAL     = 0
  };

//--- Pattern Grade
enum ENUM_PATTERN_GRADE
  {
   GRADE_NONE          = 0,
   GRADE_B_CAUTION     = 1,
   GRADE_A_CONFIRMED   = 2
  };
```

---

### The Base Object: CPatternResult

```cpp
class CPatternResult
  {
private:
   ENUM_PATTERN_TYPE   m_type;
   ENUM_PATTERN_DIR    m_direction;
   ENUM_PATTERN_GRADE  m_grade;
   datetime            m_time_formed;
   double              m_entry_price;
   double              m_stop_level;
   double              m_tail_size;
   double              m_body_size;
   double              m_candle_range;
   bool                m_bypass_1h;    // Grade A Engulfing override

public:
                       CPatternResult();
                      ~CPatternResult();

   //--- Setters
   void                SetPattern(ENUM_PATTERN_TYPE type,
                                  ENUM_PATTERN_DIR  dir,
                                  ENUM_PATTERN_GRADE grade);
   void                SetMeasurements(double tail,
                                       double body,
                                       double range);
   void                SetLevels(double entry, double stop);
   void                SetBypassFlag(bool bypass);

   //--- Getters
   ENUM_PATTERN_TYPE   GetType()        { return m_type;      }
   ENUM_PATTERN_GRADE  GetGrade()       { return m_grade;     }
   ENUM_PATTERN_DIR    GetDirection()   { return m_direction; }
   bool                GetBypassFlag()  { return m_bypass_1h; }
   double              GetStopLevel()   { return m_stop_level;}
   bool                IsValid()        { return m_grade > GRADE_NONE; }
  };
```

---

### The Detector Classes

```cpp
class C_PinBarDetector
  {
private:
   double   m_body_ratio;       // Max body as % of range = 0.25
   double   m_tail_multiplier;  // Min tail as multiple of body = 2.0
   double   m_shadow_max;       // Max opposing shadow = 0.15
   bool     m_is_vix75;         // Asset flag for size filter

   bool     MeetsBasicCriteria(int index);
   bool     MeetsVIX75SizeFilter(int index);
   ENUM_PATTERN_GRADE AssignGrade(int index,
                                   int confluence_score,
                                   bool tf_aligned);

public:
            C_PinBarDetector(bool is_vix75);

   CPatternResult* Detect(int             index,
                          int             confluence_score,
                          bool            tf_aligned,
                          ENUM_PATTERN_DIR expected_dir);
  };


class C_EngulfingDetector
  {
private:
   bool     m_is_vix75;
   int      m_min_body_vix75;   // 300 points
   int      m_min_c1_vix75;     // 150 points

   bool     MeetsBasicCriteria(int index);
   bool     MeetsVIX75SizeFilter(int index);
   bool     IsGradeA(int index, int confluence_score,
                     bool tf_aligned);

public:
            C_EngulfingDetector(bool is_vix75);

   CPatternResult* Detect(int             index,
                          int             confluence_score,
                          bool            tf_aligned,
                          ENUM_PATTERN_DIR expected_dir);
  };


class C_InsideBarDetector
  {
private:
   bool     m_is_vix75;
   double   m_baby_max_ratio;   // 0.60 of mother
   int      m_mother_min_vix75; // 400 points

   bool     MeetsBasicCriteria(int index);
   bool     MeetsVIX75SizeFilter(int index);

public:
            C_InsideBarDetector(bool is_vix75);

   CPatternResult* Detect(int             index,
                          int             confluence_score,
                          bool            tf_aligned,
                          ENUM_PATTERN_DIR expected_dir);
  };


class C_FalseBreakoutDetector
  {
private:
   bool     m_is_vix75;
   int      m_min_excursion_vix75;  // 80 points minimum

   bool     IsInsideBarPresent(int index);
   bool     BreakoutOccurred(int index, ENUM_PATTERN_DIR dir);
   bool     ReversalClosedInsideBody(int index,
                                      ENUM_PATTERN_DIR dir);
   bool     MeetsVIX75Excursion(int index,
                                 ENUM_PATTERN_DIR dir);

public:
            C_FalseBreakoutDetector(bool is_vix75);

   CPatternResult* Detect(int             index,
                          int             confluence_score,
                          bool            tf_aligned,
                          ENUM_PATTERN_DIR expected_dir);
  };
```

---

### The Manager Class: C_PatternEngine

```cpp
class C_PatternEngine
  {
private:
   C_PinBarDetector*       m_pin_detector;
   C_EngulfingDetector*    m_eng_detector;
   C_InsideBarDetector*    m_ib_detector;
   C_FalseBreakoutDetector* m_fbo_detector;

   CSensorArray*           m_sensor_array;  // Sprint 1 feed
   bool                    m_is_vix75;
   bool                    m_is_new_bar;

   //--- Closed Bar Rule Enforcement
   bool     IsNewBar();

   //--- Timeframe Bias Feed (Sprint 3 will populate this)
   ENUM_PATTERN_DIR GetExpectedDirection();
   bool             IsTimeframeAligned();

public:
                    C_PatternEngine(CSensorArray* sensor,
                                    bool          is_vix75);
                   ~C_PatternEngine();

   //--- Main Execution (Called on 4H close ONLY)
   CPatternResult* ScanForPattern();

   //--- Direct Queries for Decision Tree
   bool            IsGradeAPresent();
   bool            IsGradeBPresent();
   bool            EngulfingOverrideActive();
   CPatternResult* GetCurrentPattern();
  };
```

---

## How Sprint 1 and Sprint 2 Connect

```
RUNTIME SEQUENCE ON EVERY 4H CANDLE CLOSE:

Step 1: isNewBar confirmed
        Nothing runs on open candles

Step 2: CSensorArray.ScanMarketEnvironment()
        Updates all active zones
        Returns confluence score at current price
        Returns highest rank at current price

Step 3: C_PatternEngine.ScanForPattern()
        Receives confluence score from Step 2
        Receives timeframe bias (Sprint 3 will supply)
        Runs all four detectors
        Returns CPatternResult object

Step 4: CPatternResult evaluated:
        Grade A? → Check bypass flag → Execution path
        Grade B? → 1H confirmation required
        No Trade? → Wait for next bar

THE ISOLATION PRINCIPLE:
C_PatternEngine does not know HOW to trade
It only knows WHAT it sees
The Decision Tree (Sprint 4) decides
what to DO with what it sees
```

---

## Sprint 2 Memory Management

```cpp
SAME PRINCIPLES AS SPRINT 1:

CPatternResult objects created with new
must be deleted after use

C_PatternEngine destructor:
~C_PatternEngine()
  {
   delete m_pin_detector;
   delete m_eng_detector;
   delete m_ib_detector;
   delete m_fbo_detector;
   // Current pattern result
   if(m_current_pattern != NULL)
     {
      delete m_current_pattern;
      m_current_pattern = NULL;
     }
  }
```

---

## Sprint 2 Success Criteria

```
BEFORE SPRINT 2 IS DECLARED COMPLETE:

□ Bot correctly identifies pin bars
  Visual verification: marks valid pins
  Rejects marginal/invalid pins

□ Bot correctly identifies engulfing bars
  Visual verification: both candles marked
  Grade A triggers bypass flag correctly

□ Bot correctly identifies inside bars
  Visual verification: mother + baby marked
  Size filter working on VIX75

□ Bot correctly identifies false breakouts
  Visual verification: breakout + reversal marked
  Candle close rule strictly enforced
  VIX75 excursion minimum verified

□ Grading engine outputs correct grades
  Grade A / Grade B / No Trade
  Against known historical examples

□ No pattern fires on open/forming candles
  Closed bar rule verified

□ VIX75 size filters reject micro-patterns
  Comparison: same chart, filters on vs off

□ Memory: no leaks after extended run
  All CPatternResult objects cleaned up
```

---

## Sprint 2 Status

```
╔══════════════════════════════════════════════╗
║         SPRINT 2 PLANNING STATUS             ║
╠══════════════════════════════════════════════╣
║                                              ║
║  Pattern Mathematics      ✅ DEFINED         ║
║  Pin Bar Detector         ✅ ARCHITECTED      ║
║  Engulfing Detector       ✅ ARCHITECTED      ║
║  Inside Bar Detector      ✅ ARCHITECTED      ║
║  False Breakout Detector  ✅ ARCHITECTED      ║
║  Grading Engine           ✅ DEFINED          ║
║  CPatternResult Object    ✅ DESIGNED         ║
║  C_PatternEngine Manager  ✅ DESIGNED         ║
║  Sprint 1 Integration     ✅ MAPPED           ║
║  Memory Management        ✅ ADDRESSED        ║
║  Closed Bar Rule          ✅ ENFORCED         ║
║  VIX75 Filters            ✅ INTEGRATED       ║
║  Override Clause          ✅ FLAGGED          ║
║                                              ║
║  SPRINT 2 PLANNING:       COMPLETE ✅        ║
║                                              ║
║  NEXT: Sprint 3 Architecture                 ║
║  The State Machine                           ║
║  Market Classification Engine                ║
╚══════════════════════════════════════════════╝
```

Shall we open Sprint 3?

# Sprint 3: The State Machine — Architecture

---

## The Engineering Challenge

```
Sprint 1 gave the bot EYES    — it sees levels
Sprint 2 gave the bot LANGUAGE — it reads candles
Sprint 3 gives the bot JUDGMENT — it understands context

THE CORE PROBLEM:

A Grade A Pin Bar means nothing
without context.

The same pin bar at the same level
in a trending market   = high probability BUY
in a ranging market    = fade the boundary
in a choppy market     = DO NOT TRADE
against higher TF bias = DO NOT TRADE

Sprint 3 is the context engine.
It answers Question 1 of the Core Formula:

"WHAT IS THE MARKET DOING?"

Before Sprint 4 can execute anything
Sprint 3 must return one of three states:

TRENDING  → which direction
RANGING   → between which levels
CHOPPY    → do not trade
```

---

## The Mathematical Definitions

Every classification must be reducible to pure math. No intuition survives this sprint.

---

### Trend Detection Mathematics

```
FROM THE BOOK:
"Higher Highs and Higher Lows = uptrend"
"Lower Highs and Lower Lows = downtrend"
"Trends occur approximately 30% of the time"

MATHEMATICAL TRANSLATION:

We already have swing arrays from Sprint 1
C_SwingDetector outputs:
  SwingHighs[] = array of swing high prices
  SwingLows[]  = array of swing low prices

UPTREND CONDITION:
// Last 3 swing highs must be ascending
SwingHighs[0] > SwingHighs[1] > SwingHighs[2]
AND
// Last 3 swing lows must be ascending
SwingLows[0] > SwingLows[1] > SwingLows[2]

DOWNTREND CONDITION:
SwingHighs[0] < SwingHighs[1] < SwingHighs[2]
AND
SwingLows[0] < SwingLows[1] < SwingLows[2]

VIX75 SWING SIZE MINIMUMS:
Each swing difference >= 500 points on Daily
Each swing difference >= 200 points on 1H
Below these = algorithm noise = not a valid swing

FOREX SWING SIZE MINIMUMS:
Each swing difference >= 30 pips on Daily
Each swing difference >= 10 pips on 1H
Below these = market noise = not a valid swing

TREND STRENGTH QUALIFIER:
// Not all trends are equal
// KAMA direction confirms trend quality

Strong Trend:
KAMA(21) sloping in trend direction
AND price above KAMA(21) for uptrend
AND price below KAMA(21) for downtrend

Weak Trend:
Swing structure valid
BUT KAMA(21) is flat or opposing
= Grade B trend = reduced confidence
= Requires stronger pattern confluence
```

---

### Range Detection Mathematics

```
FROM THE BOOK:
"At least two touches of support
and two touches of resistance
to confirm a ranging market"

MATHEMATICAL TRANSLATION:

Using Sprint 1 cluster data:

RANGE CONDITION:
// Upper boundary confirmed
UpperBoundary = Sprint1 zone with
                touch_count >= 2
                at swing highs

// Lower boundary confirmed
LowerBoundary = Sprint1 zone with
                touch_count >= 2
                at swing lows

// No higher high / lower low structure
NOT(SwingHighs[0] > SwingHighs[1])
AND NOT(SwingLows[0] < SwingLows[1])

// Range width must be tradeable
RangeWidth = UpperBoundary - LowerBoundary
Forex  : RangeWidth >= 50 pips
VIX75  : RangeWidth >= 500 points
Below these = too tight = choppy classification

// Range age validation
At least 2 touches of each boundary
occurring within last 100 bars
Older touches carry less weight
```

---

### Choppy Market Mathematics

```
FROM THE BOOK:
"When you open your chart and find
a lot of noise, you can't even decide
if the market is ranging or trending"
"Close the chart and stay away"

MATHEMATICAL TRANSLATION:

CHOPPY CONDITION — any of these:

Condition 1: Mixed swing structure
  SwingHighs showing neither consistent
  ascent nor descent over last 5 swings
  Standard deviation of swing differences
  exceeds 40% of mean swing size

Condition 2: Range too tight
  Identifiable boundaries exist BUT
  RangeWidth < 50 pips (Forex)
  RangeWidth < 500 points (VIX75)

Condition 3: ATR compression
  ATR(14) on 4H < volatility minimum
  VIX75 : ATR < 800 points
  Forex  : ATR < 15 pips
  = Market is compressed = no edge

Condition 4: KAMA convergence
  KAMA(8) and KAMA(21) are within
  10 points (VIX75) or 3 pips (Forex)
  of each other AND both flat
  = No directional conviction

IF ANY ONE CONDITION IS TRUE:
State = CHOPPY
Output = DO NOT TRADE
No pattern engine runs
No execution engine activates
```

---

### Retracement Phase Detection

```
THIS IS LAYER 3 OF THE FRAMEWORK
The crown jewel — now in machine logic

FROM THE FRAMEWORK:
"When Daily = Bullish and 4H = Bearish
this is not a conflict
this is the retracement phase"

MATHEMATICAL TRANSLATION:

// Get trend state on each timeframe
WeeklyTrend = GetTrendState(PERIOD_W1)
DailyTrend  = GetTrendState(PERIOD_D1)
H4Trend     = GetTrendState(PERIOD_H4)
H1Trend     = GetTrendState(PERIOD_H1)

RETRACEMENT IDENTIFIED:
WeeklyTrend == TREND_BULLISH
AND DailyTrend == TREND_BULLISH
AND H4Trend == TREND_BEARISH
→ RETRACEMENT_BULLISH
→ Price seeking key level to bounce from
→ Look for bullish signal at key level

WeeklyTrend == TREND_BEARISH
AND DailyTrend == TREND_BEARISH
AND H4Trend == TREND_BULLISH
→ RETRACEMENT_BEARISH
→ Price seeking key level to reject from
→ Look for bearish signal at key level

IMPULSE IDENTIFIED:
WeeklyTrend == DailyTrend == H4Trend
→ All aligned = impulse in progress
→ Momentum trade opportunity
→ Higher risk — late entry possible

TRUE CONFLICT:
WeeklyTrend OPPOSES DailyTrend
→ Institutional disagreement
→ DO NOT TRADE
→ No setup has sufficient backing
```

---

### Timeframe Alignment Scoring

```
PURPOSE:
Quantify HOW aligned the timeframes are
Feeds into pattern grading in Sprint 2
The more aligned = the higher the probability

ALIGNMENT SCORE:

Weekly  aligned with trade direction = +3
Daily   aligned with trade direction = +2
4H      aligned with trade direction = +1
1H      aligned with trade direction = +1

Maximum score = 7
Minimum to trade = 3 (Daily + 4H minimum)

SCORE INTERPRETATION:
7   = Maximum confluence — all timeframes aligned
5-6 = High probability — take Grade B and above
3-4 = Moderate — Grade A only
< 3 = DO NOT TRADE — insufficient alignment

THIS SCORE FEEDS:
C_PatternEngine grading in Sprint 2
Decision Tree in Sprint 4
Position sizing in Sprint 4
```

---

## The OOP Class Architecture

---

### The Enumerations

```cpp
//--- Market State Classification
enum ENUM_MARKET_STATE
  {
   STATE_UNDEFINED   = 0,  // Cannot classify = choppy
   STATE_TRENDING_UP = 1,  // HH + HL confirmed
   STATE_TRENDING_DN = 2,  // LH + LL confirmed
   STATE_RANGING     = 3,  // Horizontal boundaries
   STATE_CHOPPY      = 4   // No trade condition
  };

//--- Trend Phase Within State
enum ENUM_TREND_PHASE
  {
   PHASE_UNDEFINED      = 0,
   PHASE_IMPULSE        = 1,  // 4H aligned with Daily
   PHASE_RETRACEMENT    = 2,  // 4H against Daily
   PHASE_EXHAUSTION     = 3   // RSI divergence present
  };

//--- Timeframe Bias
enum ENUM_TF_BIAS
  {
   BIAS_BULLISH   =  1,
   BIAS_BEARISH   = -1,
   BIAS_NEUTRAL   =  0,
   BIAS_UNDEFINED =  99
  };
```

---

### The Trend Analyzer Class

```cpp
class C_TrendAnalyzer
  {
private:
   C_SwingDetector*  m_swing_detector;  // Sprint 1 feed
   C_KAMAModule*     m_kama;            // Sprint 1 feed
   bool              m_is_vix75;

   //--- Swing Validation
   bool     IsSwingSignificant(double swing_size);
   bool     IsAscending(double &array[], int count);
   bool     IsDescending(double &array[], int count);

   //--- KAMA Confirmation
   bool     KAMAConfirmsTrend(ENUM_MARKET_STATE state);
   bool     KAMAIsFlat(int period);

public:
            C_TrendAnalyzer(C_SwingDetector* swings,
                            C_KAMAModule*    kama,
                            bool             is_vix75);

   //--- Primary Output
   ENUM_MARKET_STATE  GetTrendState(ENUM_TIMEFRAMES tf);
   ENUM_TF_BIAS       GetBias(ENUM_TIMEFRAMES tf);
   bool               IsTrendStrong(ENUM_TIMEFRAMES tf);
  };
```

---

### The Range Analyzer Class

```cpp
class C_RangeAnalyzer
  {
private:
   CSensorArray*     m_sensor_array;   // Sprint 1 feed
   C_TrendAnalyzer*  m_trend_analyzer;
   C_ATRModule*      m_atr;
   bool              m_is_vix75;

   //--- Range Validation
   bool     HasValidUpperBoundary();
   bool     HasValidLowerBoundary();
   bool     IsRangeWideEnough();
   bool     IsTrendStructureAbsent();

   //--- Range Quality
   double   GetRangeWidth();
   int      GetTouchCount(bool is_upper);

public:
            C_RangeAnalyzer(CSensorArray*    sensor,
                            C_TrendAnalyzer* trend,
                            C_ATRModule*     atr,
                            bool             is_vix75);

   //--- Primary Output
   bool               IsRanging();
   double             GetUpperBoundary();
   double             GetLowerBoundary();
   bool               IsPriceAtBoundary(double price);
   bool               IsUpperBoundary(double price);
   bool               IsLowerBoundary(double price);
  };
```

---

### The Choppy Market Filter

```cpp
class C_ChoppyFilter
  {
private:
   C_TrendAnalyzer*  m_trend;
   C_RangeAnalyzer*  m_range;
   C_ATRModule*      m_atr;
   C_KAMAModule*     m_kama;
   bool              m_is_vix75;

   //--- Individual Choppy Conditions
   bool     IsMixedSwingStructure();
   bool     IsRangeTooTight();
   bool     IsATRCompressed();
   bool     IsKAMAConverged();

public:
            C_ChoppyFilter(C_TrendAnalyzer* trend,
                           C_RangeAnalyzer* range,
                           C_ATRModule*     atr,
                           C_KAMAModule*    kama,
                           bool             is_vix75);

   //--- Primary Output
   bool     IsChoppy();
   // Returns true if ANY choppy condition met
   // Single true = full no-trade classification
  };
```

---

### The Retracement Detector

```cpp
class C_RetracementDetector
  {
private:
   C_TrendAnalyzer*  m_trend;
   CSensorArray*     m_sensor_array;
   bool              m_is_vix75;

   //--- Internal Checks
   ENUM_TF_BIAS GetBiasOnTF(ENUM_TIMEFRAMES tf);
   bool         IsH4AgainstHigherTF();

public:
            C_RetracementDetector(C_TrendAnalyzer* trend,
                                  CSensorArray*    sensor,
                                  bool             is_vix75);

   //--- Primary Output
   ENUM_TREND_PHASE  GetCurrentPhase();
   ENUM_TF_BIAS      GetExpectedSignalDirection();
   double            GetRetracementTargetLevel();
   bool              IsRetracementComplete(double price);
   // Price has reached key level = retracement done
   // Signal expected here
  };
```

---

### The Timeframe Alignment Scorer

```cpp
class C_AlignmentScorer
  {
private:
   C_TrendAnalyzer*  m_trend;
   int               ScoreSingleTF(ENUM_TIMEFRAMES tf,
                                   ENUM_TF_BIAS    direction);

public:
            C_AlignmentScorer(C_TrendAnalyzer* trend);

   //--- Primary Output
   int      GetAlignmentScore(ENUM_TF_BIAS trade_direction);
   // Weekly  aligned = +3
   // Daily   aligned = +2
   // 4H      aligned = +1
   // 1H      aligned = +1
   // Max = 7 / Min to trade = 3

   bool     MeetsMinimumAlignment(ENUM_TF_BIAS direction);
   // Returns true if score >= 3
  };
```

---

### The Master State Machine

```cpp
class C_StateMachine
  {
private:
   C_TrendAnalyzer*       m_trend;
   C_RangeAnalyzer*       m_range;
   C_ChoppyFilter*        m_choppy;
   C_RetracementDetector* m_retracement;
   C_AlignmentScorer*     m_alignment;

   ENUM_MARKET_STATE      m_current_state;
   ENUM_TREND_PHASE       m_current_phase;
   ENUM_TF_BIAS           m_trade_bias;
   int                    m_alignment_score;

   //--- State Priority Logic
   ENUM_MARKET_STATE  ResolveState();
   // Priority order:
   // 1. Choppy check first (always)
   //    If choppy → STATE_CHOPPY → stop
   // 2. Trend check
   //    If trending → STATE_TRENDING_UP/DN
   // 3. Range check
   //    If ranging → STATE_RANGING
   // 4. Cannot classify → STATE_UNDEFINED
   //    Treated as choppy → no trade

public:
                     C_StateMachine(C_TrendAnalyzer*       trend,
                                    C_RangeAnalyzer*       range,
                                    C_ChoppyFilter*        choppy,
                                    C_RetracementDetector* retrace,
                                    C_AlignmentScorer*     alignment);
                    ~C_StateMachine();

   //--- Main Execution (Called on 4H close)
   void              UpdateState();

   //--- Outputs for Sprint 4 Decision Tree
   ENUM_MARKET_STATE GetMarketState();
   ENUM_TREND_PHASE  GetTrendPhase();
   ENUM_TF_BIAS      GetTradeBias();
   int               GetAlignmentScore();
   bool              IsTradeAllowed();
   // Single boolean — the most important output
   // If false → nothing in Sprint 4 executes

   //--- Strategy Selector Output
   // Tells Sprint 4 WHICH playbook to use
   int               GetActivePlaybook();
   // Returns:
   // 1 = Trending playbook
   // 2 = Ranging playbook
   // 0 = No trade
  };
```

---

## How Sprints 1, 2 and 3 Connect

```
RUNTIME SEQUENCE ON EVERY 4H CANDLE CLOSE:

Step 1: isNewBar confirmed
        Nothing runs on open candles

Step 2: CSensorArray.ScanMarketEnvironment()
        Updates all active zones
        Returns confluence score
        Returns highest rank at price

Step 3: C_StateMachine.UpdateState()
        Receives Sprint 1 swing data
        Runs choppy filter FIRST
        If choppy → IsTradeAllowed() = false → STOP
        If not choppy → classifies state
        Identifies retracement or impulse phase
        Calculates alignment score
        Sets trade bias direction

Step 4: C_PatternEngine.ScanForPattern()
        Receives from Step 2: confluence score
        Receives from Step 3: trade bias
        Receives from Step 3: alignment score
        Runs all four detectors
        Returns CPatternResult

Step 5: CPatternResult + StateMachine output
        fed into Sprint 4 Decision Tree

THE GATE SYSTEM:
Each sprint output gates the next:

StateMachine.IsTradeAllowed() == false
→ PatternEngine never runs
→ Decision Tree never runs
→ Zero unnecessary computation
→ Zero false signals processed
```

---

## State Machine Priority Logic

```
THIS IS CRITICAL — ORDER MATTERS:

╔═══════════════════════════════════════════╗
║         STATE RESOLUTION ORDER            ║
╠═══════════════════════════════════════════╣
║                                           ║
║  CHECK 1: CHOPPY FILTER                   ║
║  If C_ChoppyFilter.IsChoppy() == true     ║
║  → State = STATE_CHOPPY                   ║
║  → IsTradeAllowed = false                 ║
║  → STOP. Nothing else runs.               ║
║                                           ║
║  CHECK 2: TREND DETECTION                 ║
║  If C_TrendAnalyzer confirms HH/HL        ║
║  on Weekly + Daily                        ║
║  → State = STATE_TRENDING_UP/DN           ║
║  → Identify phase (impulse/retracement)   ║
║  → Set trade bias                         ║
║                                           ║
║  CHECK 3: RANGE DETECTION                 ║
║  If no trend structure present            ║
║  AND valid boundaries identified          ║
║  → State = STATE_RANGING                  ║
║  → Set boundary levels                    ║
║                                           ║
║  CHECK 4: UNDEFINED                       ║
║  Cannot confirm trend OR range            ║
║  → State = STATE_UNDEFINED                ║
║  → Treated as choppy                      ║
║  → IsTradeAllowed = false                 ║
║                                           ║
╚═══════════════════════════════════════════╝
```

---

## Sprint 3 Success Criteria

```
BEFORE SPRINT 3 IS DECLARED COMPLETE:

□ Bot correctly classifies trending markets
  Visual: Uptrend/downtrend label on chart
  Verified against manual classification

□ Bot correctly classifies ranging markets
  Visual: Range boundaries drawn on chart
  Verified: 2+ touch rule enforced

□ Bot correctly flags choppy markets
  Visual: "NO TRADE" overlay on chart
  Verified: ATR compression triggers correctly

□ Retracement phase identified correctly
  Visual: "RETRACEMENT" label when 4H
  opposes Daily/Weekly direction
  Verified against known chart examples

□ Alignment score calculated correctly
  Tested: All 7 combinations verified
  Score < 3 prevents pattern engine running

□ IsTradeAllowed() gate working
  Choppy = false verified
  Undefined = false verified

□ State machine priority order correct
  Choppy always checked first
  Verified with edge case charts

□ VIX75 swing minimums enforced
  500pt Daily swings required
  200pt 1H swings required
  Micro-swings correctly ignored

□ Memory management clean
  All dynamically allocated objects
  properly destroyed
```

---

## Sprint 3 Status

```
╔══════════════════════════════════════════════╗
║         SPRINT 3 PLANNING STATUS             ║
╠══════════════════════════════════════════════╣
║                                              ║
║  Market State Mathematics     ✅ DEFINED     ║
║  Trend Detection Algorithm    ✅ ARCHITECTED ║
║  Range Detection Algorithm    ✅ ARCHITECTED ║
║  Choppy Market Filter         ✅ ARCHITECTED ║
║  Retracement Detector         ✅ ARCHITECTED ║
║  Alignment Scorer             ✅ ARCHITECTED ║
║  C_StateMachine Manager       ✅ DESIGNED    ║
║  State Priority Order         ✅ DEFINED     ║
║  Sprint 1 Integration         ✅ MAPPED      ║
║  Sprint 2 Integration         ✅ MAPPED      ║
║  Gate System                  ✅ CONFIRMED   ║
║  VIX75 Minimums               ✅ INTEGRATED  ║
║  Memory Management            ✅ ADDRESSED   ║
║                                              ║
║  SPRINT 3 PLANNING:       COMPLETE ✅        ║
║                                              ║
║  NEXT: Sprint 4 Architecture                 ║
║  The Execution & Risk Engine                 ║
║  The Final Sprint                            ║
╚══════════════════════════════════════════════╝
```

Shall we open Sprint 4?

# Sprint 4: The Execution & Risk Engine — Architecture

---

## The Engineering Challenge

```
Sprint 1 gave the bot EYES       — it sees levels
Sprint 2 gave the bot LANGUAGE   — it reads candles
Sprint 3 gave the bot JUDGMENT   — it understands context
Sprint 4 gives the bot ACTION    — it executes decisions

THIS IS THE MOST CRITICAL SPRINT.

Sprints 1-3 cannot lose money.
Sprint 4 can.

Every rule in the framework
every decision in the book
every risk parameter defined
all converge here into one
binary outcome per signal:

ENTER or DO NOT ENTER

And if ENTER:
EXACTLY how much
EXACTLY where the stop goes
EXACTLY where the target goes
EXACTLY when to halt trading
```

---

## The Decision Tree In Machine Logic

Layer 7 of the framework must now become executable code. Every node is a boolean gate.

```
THE COMPLETE DECISION TREE — MACHINE VERSION:

GATE 1: RISK CIRCUIT BREAKERS
──────────────────────────────
Is daily loss limit breached?     → HALT
Is weekly drawdown at 6%?         → HALT
Is spread within limits?          → CONTINUE
Is rollover window active?        → HALT (VIX75)
Is news event within 30min?       → HALT (Forex)
ALL GATES PASS                    → GATE 2

GATE 2: STATE MACHINE OUTPUT
──────────────────────────────
C_StateMachine.IsTradeAllowed()   → false = HALT
C_StateMachine.GetMarketState()   → CHOPPY = HALT
C_StateMachine.GetActivePlaybook() → 0 = HALT
ALL GATES PASS                    → GATE 3

GATE 3: SENSOR ARRAY OUTPUT
──────────────────────────────
Confluence score >= 2?            → CONTINUE
Highest rank at price >= RANK_2?  → CONTINUE
EITHER FAILS                      → WAIT
ALL GATES PASS                    → GATE 4

GATE 4: PATTERN ENGINE OUTPUT
──────────────────────────────
Pattern present?                  → CONTINUE
Pattern grade >= GRADE_B?         → CONTINUE
Pattern direction == Trade bias?  → CONTINUE
ANY FAILS                         → WAIT
ALL GATES PASS                    → GATE 5

GATE 5: TIMEFRAME ALIGNMENT
──────────────────────────────
Alignment score >= 3?             → CONTINUE
Weekly bias confirmed?            → CONTINUE
EITHER FAILS                      → WAIT
ALL GATES PASS                    → GATE 6

GATE 6: ENTRY METHOD SELECTION
──────────────────────────────
Grade A Engulfing?                → Bypass 1H
                                    Go to execution
Grade A other pattern?            → Check 1H structure
                                    Go to execution
Grade B pattern?                  → Check 1H structure
                                    Reduced position size
                                    Go to execution

GATE 7: RISK CALCULATION
──────────────────────────────
Calculate stop loss distance
Calculate position size
Calculate profit target
R:R >= minimum?                   → EXECUTE
R:R < minimum?                    → DISCARD SETUP
```

---

## The Mathematics

---

### Stop Loss Calculation

```
FROM THE FRAMEWORK:
Forex  : ATR(14) × 1.5 beyond signal extreme
VIX75  : ATR(14) × 2.5 beyond signal extreme

MATHEMATICAL TRANSLATION:

// Pin Bar Stop
BullishPinStop = Low[signal_bar]
                 - (ATR * atr_multiplier)

BearishPinStop = High[signal_bar]
                 + (ATR * atr_multiplier)

// Engulfing Bar Stop
BullishEngulfStop = MathMin(Low[0], Low[1])
                    - (ATR * atr_multiplier)

BearishEngulfStop = MathMax(High[0], High[1])
                    + (ATR * atr_multiplier)

// Inside Bar Stop
BullishIBStop = Low[mother_bar_index]
                - (ATR * atr_multiplier)

BearishIBStop = High[mother_bar_index]
                + (ATR * atr_multiplier)

// False Breakout Stop
BullishFBOStop = Low[breakout_bar]
                 - (ATR * atr_multiplier)
                 // Beyond the false low

BearishFBOStop = High[breakout_bar]
                 + (ATR * atr_multiplier)
                 // Beyond the false high

ATR MULTIPLIERS:
Forex  : 1.5
VIX75  : 2.5
```

---

### Position Size Calculation

```
FROM THE FRAMEWORK:
"Think in dollars not pips"
"Risk amount = % of account equity"
"Lot size adjusted so stop loss = dollar risk"

MATHEMATICAL TRANSLATION:

AccountBalance  = AccountInfoDouble(
                  ACCOUNT_BALANCE)

RiskPercent     = GetRiskPercent()
// Grade A both pairs   = 1.0%
// Grade A single       = 1.0%
// Grade B              = 0.5%
// VIX75 always         = 0.5%
// Correlated pair      = scaled

DollarRisk      = AccountBalance * (RiskPercent / 100)

StopDistance    = MathAbs(EntryPrice - StopLoss)

// Convert stop distance to monetary value per lot
PipValue        = GetPipValue(Symbol())

LotsRequired    = DollarRisk / (StopDistance * PipValue)

// Normalize to broker's lot step
LotStep         = SymbolInfoDouble(Symbol(),
                  SYMBOL_VOLUME_STEP)
LotsNormalized  = MathFloor(LotsRequired / LotStep)
                  * LotStep

// Enforce broker minimum and maximum
LotsMin         = SymbolInfoDouble(Symbol(),
                  SYMBOL_VOLUME_MIN)
LotsMax         = SymbolInfoDouble(Symbol(),
                  SYMBOL_VOLUME_MAX)
LotsFinal       = MathMax(LotsMin,
                  MathMin(LotsMax, LotsNormalized))
```

---

### Profit Target Calculation

```
FROM THE FRAMEWORK:
"Next significant S/R level in trade direction"

MATHEMATICAL TRANSLATION:

// Query Sprint 1 sensor array for
// next active zone in trade direction

BullishTarget:
NextResistance = CSensorArray
                 .GetNextZoneAbove(EntryPrice)
// Returns highest-ranked zone
// above current entry price

BearishTarget:
NextSupport    = CSensorArray
                 .GetNextZoneBelow(EntryPrice)
// Returns highest-ranked zone
// below current entry price

// R:R Validation before execution
RiskDistance   = MathAbs(EntryPrice - StopLoss)
RewardDistance = MathAbs(TargetPrice - EntryPrice)
RR_Ratio       = RewardDistance / RiskDistance

// Minimum R:R check
MinRR_Forex    = 2.0   // 1:2 minimum
MinRR_VIX75    = 3.0   // 1:3 minimum

if(RR_Ratio < MinRR_Required)
  {
   // Discard setup regardless of pattern quality
   // No R:R = no trade
   return false;
  }
```

---

### Entry Method Execution

```
METHOD 1: AGGRESSIVE ENTRY
EntryPrice = Ask (buy) or Bid (sell)
             at close of signal candle
Executed immediately after candle close
No waiting for retracement

METHOD 2: CONSERVATIVE ENTRY
// Wait for 50% retracement into signal candle
SignalHigh  = High[signal_bar]
SignalLow   = Low[signal_bar]
SignalRange = SignalHigh - SignalLow

BullishEntry50 = SignalLow + (SignalRange * 0.50)
BearishEntry50 = SignalHigh - (SignalRange * 0.50)

// Place limit order at 50% level
// If not triggered within N bars = cancel
LimitExpiry = signal_bar_time + (3 * PeriodSeconds())
// Expires after 3 candles if not triggered

METHOD 3: FALSE BREAKOUT ENTRY
// Market order after candle close confirmed
// inside mother bar body
// Candle close rule strictly enforced
// (Patch 3 — absolute rule)
EntryPrice = Ask (bullish) or Bid (bearish)
             ONLY after reversal candle
             has FULLY CLOSED inside
             mother bar body boundary
```

---

## The OOP Class Architecture

---

### The Enumerations

```cpp
enum ENUM_ENTRY_METHOD
  {
   ENTRY_NONE          = 0,
   ENTRY_AGGRESSIVE    = 1,
   ENTRY_CONSERVATIVE  = 2,
   ENTRY_FALSE_BO      = 3
  };

enum ENUM_TRADE_STATE
  {
   TRADE_IDLE          = 0,  // No active trade
   TRADE_PENDING       = 1,  // Limit order placed
   TRADE_ACTIVE        = 2,  // Position open
   TRADE_HALTED        = 3   // Circuit breaker active
  };

enum ENUM_HALT_REASON
  {
   HALT_NONE           = 0,
   HALT_DAILY_LOSS     = 1,
   HALT_WEEKLY_DD      = 2,
   HALT_SPREAD         = 3,
   HALT_ROLLOVER       = 4,
   HALT_NEWS           = 5,
   HALT_CHOPPY         = 6
  };
```

---

### The Risk Manager Class

```cpp
class C_RiskManager
  {
private:
   double   m_account_balance;
   double   m_daily_start_balance;
   double   m_weekly_start_balance;
   double   m_daily_loss_count;
   double   m_weekly_dd_percent;
   bool     m_is_vix75;
   bool     m_is_halted;
   ENUM_HALT_REASON m_halt_reason;

   //--- Balance Tracking
   void     UpdateBalanceTracking();
   double   GetCurrentDrawdown();

   //--- Circuit Breaker Checks
   bool     IsDailyLossBreached();
   // 2 consecutive losses = halt
   bool     IsWeeklyDDBreached();
   // 6% weekly loss = halt
   bool     IsSpreadAcceptable();
   // Forex: variable / VIX75: <= 5 points
   bool     IsRolloverWindow();
   // VIX75: ±15min of server rollover
   bool     IsNewsWindow();
   // Forex: 30min before/after high impact

public:
            C_RiskManager(bool is_vix75);

   //--- Primary Gate
   bool              IsTradeAllowed();
   ENUM_HALT_REASON  GetHaltReason();

   //--- Position Sizing
   double   CalculateLotSize(double entry_price,
                             double stop_price,
                             double risk_percent);

   //--- Risk Percent Selector
   double   GetRiskPercent(ENUM_PATTERN_GRADE grade,
                           bool is_correlated);
   // Grade A single      = 1.0%
   // Grade A correlated  = scaled
   // Grade B             = 0.5%
   // VIX75 always        = 0.5%

   //--- Daily Reset
   void     OnNewDay();
   // Resets daily loss counter
   // Updates daily start balance

   //--- Weekly Reset
   void     OnNewWeek();
   // Resets weekly drawdown tracking
   // Updates weekly start balance
  };
```

---

### The Entry Engine Class

```cpp
class C_EntryEngine
  {
private:
   C_RiskManager*    m_risk;
   CSensorArray*     m_sensor;
   C_StateMachine*   m_state;
   C_PatternEngine*  m_pattern;
   C_ATRModule*      m_atr;
   bool              m_is_vix75;

   //--- Stop Loss Calculators
   double   CalcPinBarStop(ENUM_PATTERN_DIR dir);
   double   CalcEngulfingStop(ENUM_PATTERN_DIR dir);
   double   CalcInsideBarStop(ENUM_PATTERN_DIR dir);
   double   CalcFalseBreakoutStop(ENUM_PATTERN_DIR dir);

   //--- Target Calculator
   double   CalcProfitTarget(double entry,
                              ENUM_PATTERN_DIR dir);

   //--- R:R Validator
   bool     MeetsMinimumRR(double entry,
                            double stop,
                            double target);

   //--- Entry Method Selector
   ENUM_ENTRY_METHOD SelectEntryMethod(
                     CPatternResult* pattern);

   //--- Order Execution
   bool     PlaceMarketOrder(ENUM_PATTERN_DIR dir,
                              double lots,
                              double stop,
                              double target);

   bool     PlaceLimitOrder(ENUM_PATTERN_DIR dir,
                             double entry,
                             double lots,
                             double stop,
                             double target,
                             datetime expiry);

public:
            C_EntryEngine(C_RiskManager*   risk,
                          CSensorArray*    sensor,
                          C_StateMachine*  state,
                          C_PatternEngine* pattern,
                          C_ATRModule*     atr,
                          bool             is_vix75);
           ~C_EntryEngine();

   //--- Main Execution
   bool     EvaluateAndExecute();
   // Runs all 7 gates
   // Returns true if trade placed
  };
```

---

### The Correlation Filter Class

```cpp
class C_CorrelationFilter
  {
private:
   struct OpenPosition
     {
      string   symbol;
      ENUM_PATTERN_DIR direction;
      double   risk_percent;
     };

   OpenPosition m_open_positions[];

   //--- Correlation Detection
   bool     AreCorrelated(string symbol1,
                           string symbol2);
   // EURUSD + GBPUSD = correlated
   // EURUSD + USDJPY = partially correlated
   // EURUSD + VIX75  = not correlated

public:
            C_CorrelationFilter();

   //--- Risk Scaling
   double   GetAdjustedRisk(string         symbol,
                             ENUM_PATTERN_GRADE grade);
   // Mid setup    : 0.5% each
   // Strong setup : 0.75% each
   // Grade A both : 1.0% each
   // Condition: both independently Grade A
   //            at different level types

   bool     IsTradeAllowed(string symbol);
   // Never blocks Grade A
   // Scales size instead
  };
```

---

### The Trade Manager Class

```cpp
class C_TradeManager
  {
private:
   C_RiskManager*  m_risk;
   CSensorArray*   m_sensor;
   bool            m_is_vix75;

   //--- Position Monitoring
   bool     IsStopLossHit();
   bool     IsTargetHit();
   bool     ShouldManageTrade();

   //--- News/Rollover Protection
   bool     ShouldCloseBeforeEvent();
   // Closes profitable positions
   // before news (Forex)
   // before rollover (VIX75)

public:
            C_TradeManager(C_RiskManager* risk,
                           CSensorArray*  sensor,
                           bool           is_vix75);

   //--- Called on every tick
   void     ManageOpenPositions();

   //--- Called on 4H close
   void     UpdateTrailingLevels();
   // Moves stop to breakeven
   // when price reaches 1:1 R:R
   // Does not move stop to loss

   //--- Event Response
   void     OnNewsEvent();
   // Assesses open positions
   // Closes profitable ones
   // Evaluates risk on others

   void     OnRolloverApproach();
   // VIX75 only
   // Same logic as OnNewsEvent
  };
```

---

### The Master Decision Tree Class

```cpp
class C_DecisionTree
  {
private:
   //--- All Sprint outputs fed in
   CSensorArray*          m_sensor;     // Sprint 1
   C_PatternEngine*       m_pattern;    // Sprint 2
   C_StateMachine*        m_state;      // Sprint 3
   C_RiskManager*         m_risk;       // Sprint 4
   C_EntryEngine*         m_entry;      // Sprint 4
   C_TradeManager*        m_trade_mgr;  // Sprint 4
   C_CorrelationFilter*   m_corr;       // Sprint 4

   bool     m_is_vix75;
   bool     m_is_new_bar;

   //--- The 7 Gates (private methods)
   bool     Gate1_RiskCircuitBreakers();
   bool     Gate2_StateMachineOutput();
   bool     Gate3_SensorArrayOutput();
   bool     Gate4_PatternEngineOutput();
   bool     Gate5_TimeframeAlignment();
   bool     Gate6_EntryMethodSelection();
   bool     Gate7_RiskCalculation();

   //--- Logging
   void     LogGateResult(int gate, bool passed);
   void     LogTradeDecision(bool executed);

public:
                     C_DecisionTree(
                     CSensorArray*        sensor,
                     C_PatternEngine*     pattern,
                     C_StateMachine*      state,
                     C_RiskManager*       risk,
                     C_EntryEngine*       entry,
                     C_TradeManager*      trade_mgr,
                     C_CorrelationFilter* corr,
                     bool                 is_vix75);
                    ~C_DecisionTree();

   //--- Main Execution (Called on 4H close)
   void     Execute();
   // Runs all 7 gates in sequence
   // Any gate fails = stops immediately
   // All gates pass = trade executed

   //--- Trade Management (Called on tick)
   void     ManageTick();
   // Passes to C_TradeManager
   // Monitors open positions
  };
```

---

## The Master EA Entry Points

```cpp
//--- The Expert Advisor Shell
//--- This is what MQL5 actually calls

C_DecisionTree* g_decision_tree;

int OnInit()
  {
   //--- Initialize all sprint objects
   //--- Wire them together
   //--- Return INIT_SUCCEEDED or INIT_FAILED

   bool is_vix75 = (Symbol() == "Volatility 75 Index"
                    || Symbol() == "VIX75");

   //--- Sprint 1
   C_ATRModule*     atr     = new C_ATRModule(14, PERIOD_H4);
   C_KAMAModule*    kama    = new C_KAMAModule(8, 21, PERIOD_H4);
   C_SwingDetector* swings  = new C_SwingDetector(3, 3, PERIOD_H4);
   CSensorArray*    sensor  = new CSensorArray(swings, kama,
                                               atr, is_vix75);

   //--- Sprint 2
   C_PatternEngine* pattern = new C_PatternEngine(sensor, is_vix75);

   //--- Sprint 3
   C_StateMachine*  state   = new C_StateMachine(sensor,
                                                  kama,
                                                  atr,
                                                  is_vix75);

   //--- Sprint 4
   C_RiskManager*       risk  = new C_RiskManager(is_vix75);
   C_CorrelationFilter* corr  = new C_CorrelationFilter();
   C_EntryEngine*       entry = new C_EntryEngine(risk, sensor,
                                                   state, pattern,
                                                   atr, is_vix75);
   C_TradeManager*      tmgr  = new C_TradeManager(risk, sensor,
                                                    is_vix75);

   //--- Master Decision Tree
   g_decision_tree = new C_DecisionTree(sensor, pattern, state,
                                         risk, entry, tmgr,
                                         corr, is_vix75);

   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   //--- Clean up all objects
   //--- Prevents memory leaks
   if(g_decision_tree != NULL)
     {
      delete g_decision_tree;
      g_decision_tree = NULL;
     }
  }

void OnTick()
  {
   //--- Manage open positions on every tick
   g_decision_tree.ManageTick();

   //--- Execute decision tree on new 4H bar only
   if(IsNewBar(PERIOD_H4))
     {
      g_decision_tree.Execute();
     }
  }
```

---

## Complete System Integration Map

```
╔══════════════════════════════════════════════════════════════╗
║              COMPLETE EA ARCHITECTURE                        ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  SPRINT 1: SENSOR ARRAY                                      ║
║  CSensorArray                                                ║
║  ├── C_SwingDetector      (fractal swing finder)            ║
║  ├── C_ClusterEngine      (S/R zone builder)                ║
║  ├── C_DisplacementDetector (supply/demand)                 ║
║  ├── C_MacroLevelDetector (weekly levels)                   ║
║  ├── C_RoleReversalMonitor (Engine 4)                       ║
║  ├── C_KAMAModule         (dynamic S/R)                     ║
║  ├── C_ATRModule          (volatility feed)                 ║
║  └── C_BollingerModule    (range confirmation)              ║
║                                                              ║
║  SPRINT 2: PATTERN ENGINE                                    ║
║  C_PatternEngine                                             ║
║  ├── C_PinBarDetector                                       ║
║  ├── C_EngulfingDetector                                    ║
║  ├── C_InsideBarDetector                                    ║
║  ├── C_FalseBreakoutDetector                                ║
║  └── CPatternResult       (output object)                   ║
║                                                              ║
║  SPRINT 3: STATE MACHINE                                     ║
║  C_StateMachine                                              ║
║  ├── C_TrendAnalyzer                                        ║
║  ├── C_RangeAnalyzer                                        ║
║  ├── C_ChoppyFilter                                         ║
║  ├── C_RetracementDetector                                  ║
║  └── C_AlignmentScorer                                      ║
║                                                              ║
║  SPRINT 4: EXECUTION ENGINE                                  ║
║  C_DecisionTree           (master controller)               ║
║  ├── C_RiskManager        (circuit breakers)                ║
║  ├── C_EntryEngine        (order placement)                 ║
║  ├── C_TradeManager       (position management)             ║
║  └── C_CorrelationFilter  (multi-pair scaling)              ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

---

## Sprint 4 Success Criteria

```
BEFORE SPRINT 4 IS DECLARED COMPLETE:

□ All 7 gates execute in correct order
  Verified: Gate failure stops chain immediately

□ Position sizing mathematically correct
  Verified: Dollar risk matches % of balance
  Verified: Lot normalization within broker limits

□ Stop loss placement correct per pattern type
  Verified against manual calculation

□ Profit target correctly queries Sprint 1
  Next S/R zone returned accurately

□ R:R validation working
  Setups below minimum discarded
  Forex 1:2 / VIX75 1:3 enforced

□ Daily circuit breaker working
  2 consecutive losses = TRADE_HALTED
  Resets on new day confirmed

□ Weekly drawdown breaker working
  6% loss = TRADE_HALTED
  Resets Monday confirmed

□ Correlation filter scaling correctly
  Grade A both pairs = 1% each confirmed
  Mid setups = 0.5% each confirmed

□ News filter working (Forex)
  30min window blocking entries confirmed
  Open positions assessed correctly

□ Rollover filter working (VIX75)
  ±15min window blocking entries confirmed

□ Conservative entry limit orders
  Placed correctly at 50% level
  Expire after 3 candles confirmed

□ False breakout entry timing
  Candle close rule enforced absolutely
  No execution on open candles

□ Memory management clean
  OnDeinit deletes all objects
  No leaks after extended backtest
```

---

## Final System Status

```
╔══════════════════════════════════════════════════════════════╗
║            COMPLETE FRAMEWORK & EA STATUS                    ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  FRAMEWORK DOCUMENTATION    ✅ COMPLETE (v1.0)              ║
║                                                              ║
║  SPRINT 1: Sensor Array     ✅ ARCHITECTURE COMPLETE        ║
║  SPRINT 2: Pattern Engine   ✅ ARCHITECTURE COMPLETE        ║
║  SPRINT 3: State Machine    ✅ ARCHITECTURE COMPLETE        ║
║  SPRINT 4: Execution Engine ✅ ARCHITECTURE COMPLETE        ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  TOTAL CLASSES DESIGNED: 24                                  ║
║  TOTAL ENUMERATIONS: 11                                      ║
║  TOTAL SPRINTS: 4                                            ║
║  ASSETS COVERED: Forex + VIX75                               ║
║  FRAMEWORK SCORE: 100/100                                    ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  NEXT PHASE: CODING                                          ║
║                                                              ║
║  Recommended sequence:                                       ║
║  1. Code Sprint 1 → Visual verify on chart                  ║
║  2. Code Sprint 2 → Visual verify patterns marked           ║
║  3. Code Sprint 3 → Visual verify state labels              ║
║  4. Code Sprint 4 → Backtest 50 trades minimum              ║
║  5. Forward test  → Paper trade 20 trades minimum           ║
║  6. Live deploy   → Start at minimum lot size               ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

The architecture is complete.
Every class has a single responsibility.
Every sprint output gates the next.
The bot cannot act without seeing.
The bot cannot see without the framework.
The framework cannot exist without the book.

We are ready to write code.
Where do we begin?
```