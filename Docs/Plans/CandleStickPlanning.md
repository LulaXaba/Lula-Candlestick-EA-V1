# Audit: Existing Indicator vs Our Framework

---

## The Core Question: Two Parts

```
1. Do the pattern names correspond to our framework?
2. Can these patterns tell us when institutions enter?
```

---

## Part 1: Name Correspondence Audit

---

### Direct Matches — Patterns We Use

```
INDICATOR NAME          OUR FRAMEWORK NAME      STATUS
────────────────────────────────────────────────────────
Inside Bar              Inside Bar              ✅ EXACT MATCH
Double Inside           Double Inside Bar       ✅ USABLE
Hammer Pattern          Bullish Pin Bar         ✅ EXACT MATCH
Shooting Star           Bearish Pin Bar         ✅ EXACT MATCH
Engulfing Bullish Line  Bullish Engulfing Bar   ✅ EXACT MATCH
Engulfing Bearish Line  Bearish Engulfing Bar   ✅ EXACT MATCH
Morning Star            Morning Star            ✅ IN BOOK
Evening Star            Evening Star            ✅ IN BOOK
Bullish Harami          Inside Bar (Bullish)    ✅ SAME PATTERN
Bearish Harami          Inside Bar (Bearish)    ✅ SAME PATTERN
Morning Doji Star       Morning Star variant    ✅ IN BOOK
Evening Doji Star       Evening Star variant    ✅ IN BOOK
```

---

### Patterns In Indicator Not In Our Framework

```
INDICATOR NAME                          OUR ASSESSMENT
──────────────────────────────────────────────────────
Outside Bar                             ⚠️ NOT IN FRAMEWORK
Pin Up (3-bar)                          ⚠️ DIFFERENT from our Pin Bar
Pin Down (3-bar)                        ⚠️ DIFFERENT from our Pin Bar
Pivot Point Reversal Up/Down            ⚠️ NOT IN FRAMEWORK
Double Bar Low Higher Close (DBLHC)     ⚠️ NOT IN FRAMEWORK
Double Bar High Lower Close (DBHLC)     ⚠️ NOT IN FRAMEWORK
Close Price Reversal Up/Down            ⚠️ NOT IN FRAMEWORK
Neutral Bar                             ⚠️ NOT IN FRAMEWORK
Force Bar Up/Down                       ⚠️ NOT IN FRAMEWORK
Mirror Bar                              ⚠️ NOT IN FRAMEWORK
Dark Cloud Cover                        ⚠️ NOT IN FRAMEWORK
Doji Star                               ⚠️ NOT IN FRAMEWORK
Bullish/Bearish Harami Cross            ⚠️ NOT IN FRAMEWORK
Two Neutral Bars                        ⚠️ NOT IN FRAMEWORK
```

---

### Critical Technical Difference — Pin Bar Definition

```
THIS NEEDS IMMEDIATE ATTENTION:

OUR FRAMEWORK PIN BAR:
Single candle
Long tail rejection
Tail ≥ 2× body
Formed at key level

THIS INDICATOR'S PIN BAR:
3-candle pattern
Candle 1 (index+2): reference candle
Candle 2 (index+1): the pin candle
  Must be highest high of all 3 (Pin Up)
  Must be lowest low of all 3 (Pin Down)
Candle 3 (index+0): confirmation candle

CODE CONFIRMS THIS:
if(Cmp(high_1,high_2)>0 &&
   Cmp(high_1,high_0)>0 &&
   Cmp(low_1,low_2)>0  &&
   Cmp(low_1,low_0)>0  &&
   body_size_1*2<shadow_upper_1)
→ PINUP

TRANSLATION:
This indicator requires the candle AFTER
the pin bar to have already formed
before it plots the signal

OUR FRAMEWORK:
We evaluate the pin bar when it CLOSES
We do not wait for the next candle

VERDICT:
Different definitions
Cannot be used as-is for our C_PinBarDetector
Our mathematical definition is superior
because it fires one candle earlier
giving us the entry at the right time
```

---

### The Hammer vs Pin Bar Distinction

```
INDICATOR HAMMER DEFINITION (from code):
shadow_upper_0 <= min_dev
AND shadow_lower_0 > 2 * body_size_0

TRANSLATION:
Upper shadow essentially zero
Lower shadow > 2× body size
Single candle evaluation

OUR FRAMEWORK PIN BAR DEFINITION:
Body <= range × 0.25
Lower shadow >= body × 2.0
Upper shadow <= range × 0.15
Single candle evaluation

VERDICT:
These are compatible ✅
The Hammer in this indicator
IS our Bullish Pin Bar
The Shooting Star IS our Bearish Pin Bar
Same candle — different names
The indicator's Hammer definition
is slightly less strict than ours
(does not enforce the 25% body rule)
Our definition is more rigorous
```

---

## Part 2: Institutional Entry Detection

```
THE REAL QUESTION:
Can ANY of these patterns tell us
when institutions are entering?

DIRECT ANSWER FROM THE BOOK:
"The secret behind supply and demand areas
is that big players put their pending orders there.
When the market approaches these zones
we see a crazy move from these levels."

Institutions do not announce entry.
They leave footprints.
The footprints are in specific patterns.
```

---

### Patterns That Signal Institutional Entry

```
╔══════════════════════════════════════════════════════════════╗
║  TIER 1 — STRONGEST INSTITUTIONAL SIGNALS                    ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  ENGULFING BAR (Bullish or Bearish)                         ║
║  Why institutions:                                           ║
║  The second candle consumes the first                        ║
║  This requires MASSIVE order volume                          ║
║  A retail trader cannot move price enough                    ║
║  to fully engulf the previous candle                         ║
║  Only institutional order flow does this                     ║
║  The book: "Buyers overwhelmed sellers"                      ║
║  = institutional buying overwhelmed retail selling           ║
║                                                              ║
║  FALSE BREAKOUT (Inside Bar variant)                         ║
║  Why institutions:                                           ║
║  The book names this explicitly:                             ║
║  "Banks know where retail stops are placed"                  ║
║  "They drive price to hunt those stops"                      ║
║  "Then reverse the market strongly"                          ║
║  The false breakout IS the institutional                     ║
║  stop hunt mechanism made visible                            ║
║  This is the clearest institutional                          ║
║  fingerprint in the entire framework                         ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║  TIER 2 — STRONG INSTITUTIONAL SIGNALS                       ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  HAMMER / SHOOTING STAR (Pin Bar)                           ║
║  Why institutions:                                           ║
║  Long tail = price was rejected violently                    ║
║  That rejection requires institutional                       ║
║  counter-orders at a specific level                          ║
║  "Buyers drove price back up" = institution                  ║
║  buying absorbed all retail selling pressure                 ║
║                                                              ║
║  MORNING STAR / EVENING STAR                                 ║
║  Why institutions:                                           ║
║  Three-candle momentum reversal                              ║
║  Third candle gapping and closing strongly                   ║
║  requires sustained institutional commitment                  ║
║  Not a single order — a campaign                            ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║  TIER 3 — CONTEXTUAL SIGNALS                                 ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  INSIDE BAR / HARAMI                                         ║
║  Why institutions:                                           ║
║  Consolidation after a large move                            ║
║  Institutions are absorbing positions                        ║
║  before the next directional push                            ║
║  On its own = indecision                                     ║
║  At a key level = institutional accumulation                 ║
║                                                              ║
║  OUTSIDE BAR (not in our framework)                          ║
║  Why institutions:                                           ║
║  Complete engulfment including wicks                         ║
║  High volatility = institutional battle                      ║
║  Direction of close = who won                                ║
║  Could be added as supplementary signal                      ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

---

### Patterns That Do NOT Signal Institutional Entry

```
THESE ARE RETAIL NOISE:

Neutral Bar          = No commitment either side
                       Institutions are absent
                       Not a signal

Force Bar Up/Down    = Close = High or Low
                       Momentum bar only
                       Tells direction not entry

Mirror Bar           = Two equal bodies
                       Coincidence not institution
                       Unreliable signal

Two Neutral Bars     = Double indecision
                       No institutional footprint

Dark Cloud Cover     = Valid reversal but
                       not in our book's framework
                       Could confuse signal quality

Doji Star            = Indecision only
                       The book covers Doji separately
                       as a standalone warning signal
                       Not a trade trigger alone
```

---

## The Practical Decision

```
WHAT THIS MEANS FOR OUR C_PatternEngine:

OPTION A: USE THIS INDICATOR AS REFERENCE
Build our own C_PatternEngine from scratch
using our mathematical definitions
Use this indicator's code as a reference
for MQL5 syntax and structure only

REASON:
Our definitions are more precise
Our Pin Bar fires one candle earlier
Our grading system does not exist here
Our VIX75 size filters do not exist here
Our confluence requirement does not exist here
This indicator draws arrows — it does not grade

OPTION B: ADAPT THIS INDICATOR
Take the Hammer, Shooting Star,
Engulfing Bull/Bear, Inside Bar code blocks
Inject our additional conditions on top
Body ratio check
VIX75 size filter
Confluence score check
Grade assignment

RECOMMENDATION: OPTION B

Reason:
The core math for Hammer, Shooting Star,
Engulfing, and Inside Bar is already
correctly written and tested in MQL5
The Cmp() function for price comparison
with tolerance is excellent defensive coding
The structure is clean and readable
We are not reinventing — we are extending

WHAT WE TAKE:
✅ Cmp() function — superior to == for prices
✅ Hammer detection math
✅ Shooting Star detection math
✅ Engulfing Bull/Bear detection math
✅ Inside Bar detection math
✅ ATR handle creation pattern
✅ ArraySetAsSeries pattern
✅ Object naming convention

WHAT WE ADD:
➕ Body ratio enforcement (25% rule)
➕ VIX75 size minimums
➕ Confluence score requirement
➕ Grade A / Grade B classification
➕ Bypass flag for Grade A Engulfing
➕ Closed bar rule enforcement
➕ False breakout 3-candle detection
➕ Direction alignment with State Machine
```

---

## Summary Verdict

```
╔══════════════════════════════════════════════╗
║           INDICATOR AUDIT RESULT             ║
╠══════════════════════════════════════════════╣
║                                              ║
║  Pattern correspondence    PARTIAL ⚠️        ║
║  4 of our patterns present                   ║
║  Pin Bar definition differs                  ║
║  No grading system present                   ║
║  No confluence requirement                   ║
║                                              ║
║  Institutional detection    YES ✅           ║
║  Engulfing = Tier 1                          ║
║  False Breakout = Tier 1                     ║
║  Pin Bar = Tier 2                            ║
║  Morning/Evening Star = Tier 2               ║
║  Inside Bar = Tier 3 (context dependent)     ║
║                                              ║
║  Recommendation                              ║
║  ADAPT not replace ✅                        ║
║  Take the math structure                     ║
║  Inject our framework rules on top           ║
║  Cmp() function is worth keeping             ║
║                                              ║
╚══════════════════════════════════════════════╝

This indicator is a solid foundation.
It is not a complete solution.
It needs our framework injected into it
before it becomes Sprint 2 ready.

Full Pattern Audit: Psychology, Institutional Footprints & Framework Fit

First — The Pin Bar Fix
THE PROBLEM:
Indicator uses 3-candle confirmation
Our framework uses single closed candle

THE FIX FOR OUR C_PinBarDetector:

INDICATOR CODE (what it does):
Waits for candle AFTER the pin to form
Then plots — already one candle late

OUR CORRECTED DEFINITION:
Evaluate on the CLOSING of the pin candle itself

// Our version replaces the 3-candle check with:
// BULLISH PIN BAR — single candle evaluation
double CandleRange  = High[0] - Low[0];
double Body         = MathAbs(Close[0] - Open[0]);
double UpperShadow  = High[0] - MathMax(Open[0], Close[0]);
double LowerShadow  = MathMin(Open[0], Close[0]) - Low[0];

bool IsBullishPin =
   Body         <= CandleRange * 0.25  &&
   LowerShadow  >= Body * 2.0          &&
   UpperShadow  <= CandleRange * 0.15;

// We keep the Cmp() tolerance function
// but evaluate on bar close not bar+1
// This fires one candle earlier
// giving us the institutional entry point
// not the confirmation of what already happened

The Institutional Footprint Patterns
What We Already Have In Our Framework
These four are confirmed institutional footprints
already in Sprint 2 architecture:

1. PIN BAR / HAMMER / SHOOTING STAR
   Institutional meaning:
   Price reached a level where institutions
   had pending orders waiting
   The long tail = institutions absorbed
   every retail order thrown at them
   and pushed price back violently
   "The rejection is the institution"

2. ENGULFING BAR
   Institutional meaning:
   The volume required to consume an entire
   previous candle including its body
   cannot come from retail traders
   This is a single institutional decision:
   "We are taking control of this market now"
   The candle IS the announcement

3. INSIDE BAR
   Institutional meaning:
   After a large move institutions pause
   They are distributing or accumulating
   within the mother candle's range
   Retail sees indecision
   Institutions are loading positions
   quietly before the next push

4. FALSE BREAKOUT
   Institutional meaning:
   The most deliberate footprint of all
   Institutions know exactly where
   retail stop losses cluster
   They engineer a move to collect
   that liquidity then reverse
   "The false breakout is not accidental
   it is the mechanism"

The Other Patterns — Full Psychology Audit

Outside Bar
INDICATOR NAME: Outside Bar
WHAT IT IS:
Current candle High > previous High
AND current candle Low < previous Low
Complete engulfment including wicks

PSYCHOLOGY:
An extreme battle between buyers and sellers
Both sides pushed hard in both directions
The candle that closes determines the winner

BULLISH OUTSIDE BAR:
Sellers pushed to new lows
Buyers overwhelmed them completely
Close near the top = buyers dominated

BEARISH OUTSIDE BAR:
Buyers pushed to new highs
Sellers overwhelmed them completely
Close near the bottom = sellers dominated

INSTITUTIONAL RELEVANCE:
High relevance at key levels
The range expansion = institutional participation
Retail cannot create this range alone

FRAMEWORK FIT:
Not in our current framework
Could be added as a supplementary
confirmation signal
Similar weight to engulfing bar
but requires context of key level
to be meaningful

VERDICT: ADD AS SUPPLEMENTARY ✅
Treat like Grade B Engulfing
when found at key level

Pivot Point Reversal Up / Down
INDICATOR NAME: Pivot Point Reversal Up/Down
WHAT IT IS:
3-candle pattern
Middle candle is the extreme point
(highest high for PPR Down
 lowest low for PPR Up)
Third candle closes BEYOND the middle candle's
high (PPR Up) or low (PPR Down)

CODE CONFIRMS:
PPR Up:
  high_1 < high_2 AND high_1 < high_0
  low_1  < low_2  AND low_1  < low_0
  close_0 > high_1
// Middle candle is lowest low
// Third candle closes above middle high

PPR Down:
  high_1 > high_2 AND high_1 > high_0
  low_1  > low_2  AND low_1  > low_0
  close_0 < low_1
// Middle candle is highest high
// Third candle closes below middle low

PSYCHOLOGY:
This is actually a confirmed swing point reversal
The middle candle = the turning point
The third candle = confirmation of direction change
It is similar to our retracement exhaustion signal

INSTITUTIONAL RELEVANCE:
Moderate — it confirms a swing has formed
Institutions have already entered by candle 3
This is confirmation not entry

FRAMEWORK FIT:
This is actually what our 1H structure check
is looking for — a confirmed swing low or high
Could be used as 1H structure confirmation signal
NOT as a 4H entry signal

VERDICT: USE FOR 1H STRUCTURE CONFIRMATION ✅
Maps directly to Layer 7 Step 5:
"HH/HL or LH/LL confirmation on 1H"

Double Bar Low Higher Close / Double Bar High Lower Close
INDICATOR NAME: DBLHC / DBHLC
WHAT IT IS:
DBLHC:
Two consecutive candles with equal lows
Second candle closes higher than first
Second candle high >= first candle high

DBHLC:
Two consecutive candles with equal highs
Second candle closes lower than first
Second candle low <= first candle low

PSYCHOLOGY:
DBLHC — Bullish:
Price tested the same low TWICE
Both times buyers stepped in at that exact level
Equal lows = institutional buy orders
sitting at that specific price
Two tests = confirmation they are there
Higher close = buyers won the second test

DBHLC — Bearish:
Price tested the same high TWICE
Both times sellers defended that level
Equal highs = institutional sell orders
Lower close = sellers won the second test

INSTITUTIONAL RELEVANCE:
VERY HIGH ✅
This is one of the clearest institutional
order footprints available
Equal lows or equal highs =
pending institutional orders at that price
The second test = the institution absorbed
the second wave of retail pressure

FRAMEWORK FIT:
This maps directly to our Engine 2
Standard S/R detection
Two equal lows = support zone confirmed
Two equal highs = resistance zone confirmed
But more importantly:
DBLHC AT OUR KEY LEVEL = institutional
confirmation that our level is correct
DBHLC AT OUR KEY LEVEL = same confirmation

VERDICT: ADD TO SPRINT 2 AS TIER 1 SIGNAL ✅
Rename in our framework:
DBLHC = Double Bottom Confirmation
DBHLC = Double Top Confirmation
Weight = equivalent to Pin Bar Grade A
when found at identified key level

Close Price Reversal Up / Down
INDICATOR NAME: CPRU / CPRD
WHAT IT IS:
CPRU (3 candles):
Candles 1+2 making lower highs and lower lows
Candle 3 makes a lower low
BUT closes higher than candle 2 close
AND candle 3 is bearish (close < open)

CPRD (3 candles):
Candles 1+2 making higher highs and higher lows
Candle 3 makes a higher high
BUT closes lower than candle 2 close
AND candle 3 is bullish (close > open)

PSYCHOLOGY:
CPRU:
Downtrend is losing momentum
New low was made but buyers pushed close higher
Sellers could not maintain the new low
First sign of buying pressure entering

CPRD:
Uptrend is losing momentum
New high was made but sellers pushed close lower
Buyers could not hold the new high
First sign of selling pressure entering

INSTITUTIONAL RELEVANCE:
Moderate-High
This is an early warning signal
Institutions are beginning to counter
the prevailing trend
The close reversal = their orders
are starting to absorb the trend momentum

FRAMEWORK FIT:
This is an early warning signal
Maps to our RSI divergence concept
Price makes new extreme
but close momentum is reversing
Best used on Daily/Weekly as
a warning before a 4H signal forms

VERDICT: USE AS DAILY CONTEXT WARNING ⚠️
Not a standalone entry signal
Adds weight to existing confluence
"Daily CPRU present + 4H Pin Bar at level
= elevated probability setup"

Neutral Bar / Two Neutral Bars
INDICATOR NAME: NB / NB2
WHAT IT IS:
Open = Close (Doji)
Upper AND lower shadows both significant
Two Neutral Bars = two consecutive Dojis

PSYCHOLOGY:
Complete indecision
Buyers and sellers perfectly balanced
Neither side in control
The book calls this the Doji —
"Equality and indecision in the market"

INSTITUTIONAL RELEVANCE:
LOW as standalone
Institutions are not present with conviction
They are watching and waiting

EXCEPTION:
Neutral Bar at a key level after a strong move =
institutions pausing before next push
Similar to Inside Bar psychology
But weaker signal

FRAMEWORK FIT:
The book covers Doji separately
We do not trade it alone
Use as supporting context only
"Doji at key level = possible inside bar forming
wait for next candle to confirm"

VERDICT: CONTEXT ONLY — NOT A SIGNAL ❌

Force Bar Up / Down
INDICATOR NAME: FBU / FBD
WHAT IT IS:
FBU: Close == High (closed at the very top)
FBD: Close == Low (closed at the very bottom)

PSYCHOLOGY:
FBU:
Buyers controlled price the entire session
Not a single moment of seller control
Close = High = buyers in complete dominance

FBD:
Sellers controlled the entire session
Close = Low = sellers in complete dominance

INSTITUTIONAL RELEVANCE:
HIGH in the right context ✅
A Force Bar in trend direction
= institutions committed to this direction
No pullback within the candle
= no retail resistance was meaningful

AT KEY LEVEL:
Force Bar closing through a key level
= institutional breakout confirmation
This is the breakout candle
our ranging strategy waits for

FRAMEWORK FIT:
Maps directly to Layer 9 Strategy 2:
"Trade the breakout — confirmed candle
close beyond boundary"
A Force Bar breaking through S/R
= highest quality breakout signal

VERDICT: ADD AS BREAKOUT CONFIRMATION ✅
FBU closing above resistance = confirmed breakout
FBD closing below support = confirmed breakout
Feeds Layer 9 Ranging Strategy 2

Mirror Bar
INDICATOR NAME: Mirror Bar
WHAT IT IS:
Two candles with equal body sizes
Second candle opens where first closed
Opposite direction candles

PSYCHOLOGY:
The market perfectly reversed its previous move
Candle 1 moved in one direction with exact force
Candle 2 reversed with identical force
A mathematical symmetry in price

INSTITUTIONAL RELEVANCE:
LOW to MODERATE
Interesting pattern but coincidental
in most cases
Only meaningful at a key level where
the reversal mirrors an institutional
defense of that level

FRAMEWORK FIT:
Not sufficient for our framework alone
Too rare and too coincidental to rely on

VERDICT: IGNORE ❌

Dark Cloud Cover
INDICATOR NAME: Dark Cloud Cover
WHAT IT IS:
2 candles
Candle 1: Strong bullish
Candle 2: Opens above Candle 1 high
          Closes below Candle 1 midpoint
          Bearish candle

PSYCHOLOGY:
Bulls pushed strongly (Candle 1)
Next session opened even higher
= initial bullish excitement
Then sellers overwhelmed buyers
closing below the midpoint of the bull candle
= sellers have taken control

INSTITUTIONAL RELEVANCE:
HIGH at resistance levels ✅
The gap up open = retail FOMO buying
Institutions sell into that FOMO
Using retail buying as exit liquidity
The close below midpoint = confirmation
institutions won the session

FRAMEWORK FIT:
This is actually a variant of our
Bearish Engulfing Bar
Less powerful because it does not
fully engulf the previous candle
But the psychology is identical:
Institutions selling into retail buying

VERDICT: ADD AS GRADE B BEARISH SIGNAL ✅
At resistance = Grade B Bearish
With other confluence = tradeable
Weaker than full engulfing bar

Doji Star
INDICATOR NAME: Doji Star
WHAT IT IS:
Candle 1: Strong directional candle
Candle 2: Doji that gaps away from Candle 1
          Open = Close on the Doji

PSYCHOLOGY:
Strong move followed by complete indecision
The gap = overnight sentiment shift
The Doji = neither side in control
Classic reversal warning signal

INSTITUTIONAL RELEVANCE:
MODERATE
Institutions have paused the trend
They are neither adding nor removing
Equal buyers and sellers = standoff

FRAMEWORK FIT:
The book covers the Doji separately
as a reversal warning — not a trade signal
"When found at top or bottom of trend
it is a sign that the prior trend
is losing its strength"
This maps to our RSI divergence role:
early warning, not entry trigger

VERDICT: USE AS WARNING SIGNAL ONLY ⚠️
Same role as RSI divergence
Adds weight to existing confluence
Does not generate entries alone

Bullish / Bearish Harami Cross
INDICATOR NAME: Harami Cross
WHAT IT IS:
Standard Harami (Inside Bar) BUT
the second candle is a perfect Doji
Open = Close on the baby candle

PSYCHOLOGY:
The Harami Cross is STRONGER than
a standard Inside Bar because:
Standard Inside Bar = indecision
Harami Cross = PERFECT indecision
The Doji baby candle means neither
buyer nor seller moved price at all
from open to close

INSTITUTIONAL RELEVANCE:
HIGH when at key level ✅
Institutions are in a complete standoff
The next candle will determine who wins
The breakout of the Harami Cross
is more explosive than a regular
Inside Bar breakout because
the compression is more complete

FRAMEWORK FIT:
Treat as GRADE A Inside Bar
The Doji baby = more compressed
= more explosive breakout expected
= better R:R on false breakout setup

VERDICT: UPGRADE TO GRADE A INSIDE BAR ✅
When baby candle is Doji:
Inside Bar automatically Grade A
False breakout of Harami Cross
= highest probability setup

Complete Pattern Classification For Our EA
╔══════════════════════════════════════════════════════════════╗
║         FINAL PATTERN CLASSIFICATION TABLE                   ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  TIER 1 — INSTITUTIONAL ENTRY SIGNALS                        ║
║  Use as primary entry triggers                               ║
║  ─────────────────────────────────                          ║
║  Engulfing Bar (Bull/Bear)    KEEP ✅  Sprint 2 core        ║
║  False Breakout               KEEP ✅  Sprint 2 core        ║
║  DBLHC / DBHLC               ADD  ✅  Double confirmation   ║
║  Force Bar (at S/R break)     ADD  ✅  Breakout confirm     ║
║                                                              ║
║  TIER 2 — INSTITUTIONAL REJECTION SIGNALS                    ║
║  Use as entry triggers at key levels                         ║
║  ─────────────────────────────────                          ║
║  Hammer / Pin Bar (Bullish)   KEEP ✅  Sprint 2 core        ║
║  Shooting Star (Bearish)      KEEP ✅  Sprint 2 core        ║
║  Morning Star                 KEEP ✅  Book pattern         ║
║  Evening Star                 KEEP ✅  Book pattern         ║
║  Morning Doji Star            KEEP ✅  Stronger variant     ║
║  Evening Doji Star            KEEP ✅  Stronger variant     ║
║  Dark Cloud Cover             ADD  ✅  Grade B bearish      ║
║  Outside Bar                  ADD  ✅  Grade B at levels    ║
║                                                              ║
║  TIER 3 — INSTITUTIONAL ACCUMULATION SIGNALS                 ║
║  Use as context and confirmation                             ║
║  ─────────────────────────────────                          ║
║  Inside Bar / Harami          KEEP ✅  Sprint 2 core        ║
║  Harami Cross                 UPGRADE✅ Grade A Inside Bar  ║
║  Double Inside Bar            KEEP ✅  Deeper compression   ║
║                                                              ║
║  TIER 4 — STRUCTURE CONFIRMATION SIGNALS                     ║
║  Use for timeframe structure reading only                    ║
║  ─────────────────────────────────                          ║
║  Pivot Point Reversal Up/Down USE  ✅  1H structure check   ║
║  Close Price Reversal Up/Down USE  ⚠️  Daily warning only   ║
║                                                              ║
║  CONTEXT ONLY — NO TRADE SIGNALS                             ║
║  ─────────────────────────────────                          ║
║  Neutral Bar / Two Neutral    ❌  Indecision only           ║
║  Doji Star                    ❌  Warning only              ║
║  Mirror Bar                   ❌  Coincidental              ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

What This Means For Sprint 2
ORIGINAL SPRINT 2 HAD 4 DETECTORS:
C_PinBarDetector
C_EngulfingDetector
C_InsideBarDetector
C_FalseBreakoutDetector

UPDATED SPRINT 2 NOW HAS 7 DETECTORS:

C_PinBarDetector           (fixed — single candle)
C_EngulfingDetector        (+ Dark Cloud Cover as Grade B)
C_InsideBarDetector        (+ Harami Cross = auto Grade A)
C_FalseBreakoutDetector    (unchanged — Patch 3 applies)
C_DoubleCandleDetector     (NEW — DBLHC/DBHLC patterns)
C_ForceBarDetector         (NEW — breakout confirmation)
C_StarPatternDetector      (NEW — Morning/Evening Star)

PLUS TWO CONTEXT READERS:
C_PivotReversalReader      (1H structure confirmation)
C_ContextWarningReader     (Daily CPR warning signals)

THE INSTITUTIONAL FOOTPRINT IS NOW COMPLETE:
Every way institutions leave a mark
on a price chart is captured
and classified in our framework

Bottom Line
The indicator gave us:
✅ Correct math for 4 core patterns
✅ The Cmp() tolerance function
✅ MQL5 structural template

We discovered:
✅ 3 additional Tier 1-2 entry signals
✅ 2 structure confirmation tools
✅ Harami Cross = auto Grade A upgrade
✅ Force Bar = breakout confirmation

Institutions DO leave footprints.
We now have every footprint classified.
No institutional move goes undetected.




this is the source coding we talking about above.

//+------------------------------------------------------------------+
//|                                                     Patterns.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                                 https://mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 31
#property indicator_plots   30
//--- plot P1
#property indicator_label1  "Double inside"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot P2
#property indicator_label2  "Inside"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot P3
#property indicator_label3  "Outside"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrRed
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- plot P4
#property indicator_label4  "Pin up"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrRed
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
//--- plot P5
#property indicator_label5  "Pin down"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrRed
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1
//--- plot P6
#property indicator_label6  "Pivot Point Reversal Up"
#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrRed
#property indicator_style6  STYLE_SOLID
#property indicator_width6  1
//--- plot P7
#property indicator_label7  "Pivot Point Reversal Down"
#property indicator_type7   DRAW_ARROW
#property indicator_color7  clrRed
#property indicator_style7  STYLE_SOLID
#property indicator_width7  1
//--- plot P8
#property indicator_label8  "Double Bar Low With A Higher Close"
#property indicator_type8   DRAW_ARROW
#property indicator_color8  clrRed
#property indicator_style8  STYLE_SOLID
#property indicator_width8  1
//--- plot P9
#property indicator_label9  "Double Bar High With A Lower Close"
#property indicator_type9   DRAW_ARROW
#property indicator_color9  clrRed
#property indicator_style9  STYLE_SOLID
#property indicator_width9  1
//--- plot P10
#property indicator_label10  "Close Price Reversal Up"
#property indicator_type10   DRAW_ARROW
#property indicator_color10  clrRed
#property indicator_style10  STYLE_SOLID
#property indicator_width10  1
//--- plot P11
#property indicator_label11  "Close Price Reversal Down"
#property indicator_type11   DRAW_ARROW
#property indicator_color11  clrRed
#property indicator_style11  STYLE_SOLID
#property indicator_width11  1
//--- plot P12
#property indicator_label12  "Neutral Bar"
#property indicator_type12   DRAW_ARROW
#property indicator_color12  clrRed
#property indicator_style12  STYLE_SOLID
#property indicator_width12  1
//--- plot P13
#property indicator_label13  "Force Bar Up"
#property indicator_type13   DRAW_ARROW
#property indicator_color13  clrRed
#property indicator_style13  STYLE_SOLID
#property indicator_width13  1
//--- plot P14
#property indicator_label14  "Force Bar Down"
#property indicator_type14   DRAW_ARROW
#property indicator_color14  clrRed
#property indicator_style14  STYLE_SOLID
#property indicator_width14  1
//--- plot P15
#property indicator_label15  "Mirror Bar"
#property indicator_type15   DRAW_ARROW
#property indicator_color15  clrRed
#property indicator_style15  STYLE_SOLID
#property indicator_width15  1
//--- plot P16
#property indicator_label16  "Hammer Pattern"
#property indicator_type16   DRAW_ARROW
#property indicator_color16  clrRed
#property indicator_style16  STYLE_SOLID
#property indicator_width16  1
//--- plot P17
#property indicator_label17  "Shooting Star"
#property indicator_type17   DRAW_ARROW
#property indicator_color17  clrRed
#property indicator_style17  STYLE_SOLID
#property indicator_width17  1
//--- plot P18
#property indicator_label18  "Evening Star"
#property indicator_type18   DRAW_ARROW
#property indicator_color18  clrRed
#property indicator_style18  STYLE_SOLID
#property indicator_width18  1
//--- plot P19
#property indicator_label19  "Morning Star"
#property indicator_type19   DRAW_ARROW
#property indicator_color19  clrRed
#property indicator_style19  STYLE_SOLID
#property indicator_width19  1
//--- plot P20
#property indicator_label20  "Bearish Harami"
#property indicator_type20   DRAW_ARROW
#property indicator_color20  clrRed
#property indicator_style20  STYLE_SOLID
#property indicator_width20  1
//--- plot P21
#property indicator_label21  "Bearish Harami Cross"
#property indicator_type21   DRAW_ARROW
#property indicator_color21  clrRed
#property indicator_style21  STYLE_SOLID
#property indicator_width21  1
//--- plot P22
#property indicator_label22  "Bullish Harami"
#property indicator_type22   DRAW_ARROW
#property indicator_color22  clrRed
#property indicator_style22  STYLE_SOLID
#property indicator_width22  1
//--- plot P23
#property indicator_label23  "Bullish Harami Cross"
#property indicator_type23   DRAW_ARROW
#property indicator_color23  clrRed
#property indicator_style23  STYLE_SOLID
#property indicator_width23  1
//--- plot P24
#property indicator_label24  "Dark Cloud Cover"
#property indicator_type24   DRAW_ARROW
#property indicator_color24  clrRed
#property indicator_style24  STYLE_SOLID
#property indicator_width24  1
//--- plot P25
#property indicator_label25  "Doji Star"
#property indicator_type25   DRAW_ARROW
#property indicator_color25  clrRed
#property indicator_style25  STYLE_SOLID
#property indicator_width25  1
//--- plot P26
#property indicator_label26  "Engulfing Bearish Line"
#property indicator_type26   DRAW_ARROW
#property indicator_color26  clrRed
#property indicator_style26  STYLE_SOLID
#property indicator_width26  1
//--- plot P27
#property indicator_label27  "Engulfing Bullish Line"
#property indicator_type27   DRAW_ARROW
#property indicator_color27  clrRed
#property indicator_style27  STYLE_SOLID
#property indicator_width27  1
//--- plot P28
#property indicator_label28  "Evening Doji Star"
#property indicator_type28   DRAW_ARROW
#property indicator_color28  clrRed
#property indicator_style28  STYLE_SOLID
#property indicator_width28  1
//--- plot P29
#property indicator_label29  "Morning Doji Star"
#property indicator_type29   DRAW_ARROW
#property indicator_color29  clrRed
#property indicator_style29  STYLE_SOLID
#property indicator_width29  1
//--- plot P30
#property indicator_label30  "Two Neutral Bars"
#property indicator_type30   DRAW_ARROW
#property indicator_color30  clrRed
#property indicator_style30  STYLE_SOLID
#property indicator_width30  1
//--- indicator buffers
double         BufferATR[];
//--- enums
enum ENUM_INPUT_ON_OFF
  {
   INPUT_ON    =  1,             // On
   INPUT_OFF   =  0              // Off
  };
enum ENUM_INPUT_YES_NO
  {
   INPUT_YES   =  1,             // Yes
   INPUT_NO    =  0              // No
  };
//+------------------------------------------------------------------+
//| Перечисление типов паттернов                                     |
//+------------------------------------------------------------------+
enum ENUM_PATTERN_TYPE
  {
   PATTERN_TYPE_DOUBLE_INSIDE,   // Double inside
   PATTERN_TYPE_INSIDE,          // Inside
   PATTERN_TYPE_OUTSIDE,         // Outside
   PATTERN_TYPE_PINUP,           // Pin up
   PATTERN_TYPE_PINDOWN,         // Pin down
   PATTERN_TYPE_PPRUP,           // Pivot Point Reversal Up
   PATTERN_TYPE_PPRDN,           // Pivot Point Reversal Down
   PATTERN_TYPE_DBLHC,           // Double Bar Low With A Higher Close
   PATTERN_TYPE_DBHLC,           // Double Bar High With A Lower Close
   PATTERN_TYPE_CPRU,            // Close Price Reversal Up
   PATTERN_TYPE_CPRD,            // Close Price Reversal Down
   PATTERN_TYPE_NB,              // Neutral Bar
   PATTERN_TYPE_FBU,             // Force Bar Up
   PATTERN_TYPE_FBD,             // Force Bar Down
   PATTERN_TYPE_MB,              // Mirror Bar
   PATTERN_TYPE_HAMMER,          // Hammer Pattern
   PATTERN_TYPE_SHOOTSTAR,       // Shooting Star
   PATTERN_TYPE_EVSTAR,          // Evening Star
   PATTERN_TYPE_MORNSTAR,        // Morning Star
   PATTERN_TYPE_BEARHARAMI,      // Bearish Harami
   PATTERN_TYPE_BEARHARAMICROSS, // Bearish Harami Cross
   PATTERN_TYPE_BULLHARAMI,      // Bullish Harami
   PATTERN_TYPE_BULLHARAMICROSS, // Bullish Harami Cross
   PATTERN_TYPE_DARKCLOUD,       // Dark Cloud Cover
   PATTERN_TYPE_DOJISTAR,        // Doji Star
   PATTERN_TYPE_ENGBEARLINE,     // Engulfing Bearish Line
   PATTERN_TYPE_ENGBULLLINE,     // Engulfing Bullish Line
   PATTERN_TYPE_EVDJSTAR,        // Evening Doji Star
   PATTERN_TYPE_MORNDJSTAR,      // Morning Doji Star
   PATTERN_TYPE_NB2              // Two Neutral Bars
  };
//--- input parameters
input ENUM_INPUT_ON_OFF InpEnableOneBarPatterns       =  INPUT_ON;   // Enable One-bar patterns:
input ENUM_INPUT_ON_OFF InpEnableTwoBarPatterns       =  INPUT_ON;   // Enable Two-bar patterns:
input ENUM_INPUT_ON_OFF InpEnableThreeBarPatterns     =  INPUT_ON;   // Enable Three-bar patterns:
input uint              InpEQ                         =  1;          // Maximum of pips distance between equal prices
input ENUM_INPUT_YES_NO InpShowPatternDescript        =  INPUT_YES;  // Show Pattern Descriptions
input uint              InpFontSize                   =  8;          // Font size
input color             InpFontColor                  =  clrGray;    // Texts color
input string            InpFontName                   =  "Calibri";  // Font name
//---
input ENUM_INPUT_ON_OFF InpEnablePAT_DOUBLE_INSIDE    =  INPUT_ON;   // <Double inside> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_INSIDE           =  INPUT_ON;   // <Inside> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_OUTSIDE          =  INPUT_ON;   // <Outside> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_PINUP            =  INPUT_ON;   // <Pin up> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_PINDOWN          =  INPUT_ON;   // <Pin down> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_PPRUP            =  INPUT_ON;   // <Pivot Point Reversal Up> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_PPRDN            =  INPUT_ON;   // <Pivot Point Reversal Down> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_DBLHC            =  INPUT_ON;   // <Double Bar Low With A Higher Close> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_DBHLC            =  INPUT_ON;   // <Double Bar High With A Lower Close> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_CPRU             =  INPUT_ON;   // <Close Price Reversal Up> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_CPRD             =  INPUT_ON;   // <Close Price Reversal Down> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_NB               =  INPUT_ON;   // <Neutral Bar> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_FBU              =  INPUT_ON;   // <Force Bar Up> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_FBD              =  INPUT_ON;   // <Force Bar Down> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_MB               =  INPUT_ON;   // <Mirror Bar> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_HAMMER           =  INPUT_ON;   // <Hammer Pattern> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_SHOOTSTAR        =  INPUT_ON;   // <Shooting Star> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_EVSTAR           =  INPUT_ON;   // <Evening Star> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_MORNSTAR         =  INPUT_ON;   // <Morning Star> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_BEARHARAMI       =  INPUT_ON;   // <Bearish Harami> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_BEARHARAMICROSS  =  INPUT_ON;   // <Bearish Harami Cross> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_BULLHARAMI       =  INPUT_ON;   // <Bullish Harami> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_BULLHARAMICROSS  =  INPUT_ON;   // <Bullish Harami Cross> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_DARKCLOUD        =  INPUT_ON;   // <Dark Cloud Cover> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_DOJISTAR         =  INPUT_ON;   // <Doji Star> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_ENGBEARLINE      =  INPUT_ON;   // <Engulfing Bearish Line> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_ENGBULLLINE      =  INPUT_ON;   // <Engulfing Bullish Line> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_EVDJSTAR         =  INPUT_ON;   // <Evening Doji Star> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_MORNDJSTAR       =  INPUT_ON;   // <Morning Doji Star> pattern
input ENUM_INPUT_ON_OFF InpEnablePAT_NB2              =  INPUT_ON;   // <Two Neutral Bars> pattern
//--- global variables
int      handle_atr;
double   eq_pp;
string   prefix;
string   font_name;
string   ArrayNames[][2]=
  {
     {"Double inside","DBLIN"}, {"Inside Bar","IN"}, {"Outside Bar","OUT"}, {"Pin Bar up","PINUP"}, {"Pin Bar down","PINDOWN"},
     {"Pivot Point Reversal Up","PPRUP"}, {"Pivot Point Reversal Down","PPRDN"}, {"Double Bar Low With A Higher Close","DBLHC"},
     {"Double Bar High With A Lower Close","DBHLC"}, {"Close Price Reversal Up","CPRU"}, {"Close Price Reversal Down","CPRD"},
     {"Neutral Bar","NB"}, {"Force Bar Up","FBU"}, {"Force Bar Down","FBD"}, {"Mirror Bar","MB"}, {"Hammer","HAMMER"},
     {"Shooting Star","SHOOTSTAR"}, {"Evening Star","EVSTAR"}, {"Morning Star","MORNSTAR"}, {"Bearish Harami","BEARHARAMI"},
     {"Bearish Harami Cross","BEARHARAMICROSS"}, {"Bullish Harami","BULLHARAMI"}, {"Bullish Harami Cross","BULLHARAMICROSS"},
     {"Dark Cloud Cover","DARKCLOUD"}, {"Doji Star","DOJISTAR"}, {"Engulfing Bearish Line","ENGBEARLINE"},
     {"Engulfing Bullish Line","ENGBULLLINE"}, {"Evening Doji Star","EVDJSTAR"},
     {"Morning Doji Star","MORNDJSTAR"}, {"Two Neutral Bars","NB2"}
  };
//--- structures
struct SDataBuffers
  {
   double            Buffer[];         // Буфер паттерна
   ENUM_PATTERN_TYPE type_pattern;     // Тип паттерна
   //--- Возвращает Название паттерна
   string            Description(void) { return DescriptionPattern(type_pattern); }
  } Pattern[];  // Структура данных паттернов
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- setting global variables
   if(Point()==0)
     {
      Print("Error. Unable to get the value of points on ",Symbol());
      return INIT_FAILED;
     }
   eq_pp=InpEQ*Point();
   prefix="Patterns_";
   font_name=(InpFontName=="" ? "Calibri" : InpFontName);
//--- indicator buffers mapping
//--- and setting a code from the Wingdings charset as the property of PLOT_ARROW,
//--- and setting as series
   ArraySetAsSeries(BufferATR,true);
   int total=ArrayRange(ArrayNames,0);
   ArrayResize(Pattern,total);
   ZeroMemory(Pattern);
   for(int i=0; i<total; i++)
     {
      SetIndexBuffer(i,Pattern[i].Buffer,INDICATOR_DATA);
      PlotIndexSetInteger(i,PLOT_ARROW,159);
      Pattern[i].type_pattern=(ENUM_PATTERN_TYPE)i;
      ArraySetAsSeries(Pattern[i].Buffer,true);
     }
//--- settings indicators parameters
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
   IndicatorSetString(INDICATOR_SHORTNAME,"Patterns");
//--- create ATR handles
   ResetLastError();
   handle_atr=iATR(Symbol(),PERIOD_CURRENT,14);
   if(handle_atr==INVALID_HANDLE)
     {
      Print("The iATR object was not created: Error ",GetLastError());
      return INIT_FAILED;
     }
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0,prefix);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- Проверка на минимальное количество баров для расчёта
   if(rates_total<4) return 0;
//--- Установка индексации массивов как таймсерий
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(time,true);
//--- Проверка и расчёт количества просчитываемых баров
   int limit=rates_total-prev_calculated;
   if(limit>1)
     {
      limit=rates_total-5;
      int total=ArraySize(Pattern);
      for(int i=0; i<total; i++)
         ArrayInitialize(Pattern[i].Buffer,EMPTY_VALUE);
     }
//--- Подготовка данных
   int copied=0,count=(limit==0 ? 1 : rates_total);
   copied=CopyBuffer(handle_atr,0,0,count,BufferATR);
   if(copied!=count) return 0;
//--- Расчёт индикатора
   for(int i=limit; i>0 && !IsStopped(); i--)
      CheckPatterns(i,open,high,low,close,time);
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Проверяет наличие паттерна по индексу бара                       |
//+------------------------------------------------------------------+
void CheckPatterns(const int index,const double &open[],const double &high[],const double &low[],const double &close[],const datetime &time[])
  {
//--- Очистка буферов на текущем индексе
   int total=ArraySize(Pattern);
   for(int i=0; i<total; i++) 
      Pattern[i].Buffer[index]=EMPTY_VALUE;
//--- Расчёт паттернов
   double min_dev=fmax(eq_pp,Point());
   double min_dev4=fmax(eq_pp*4,Point()*4);
//--- свеча со смещением 0
   double open_0=open[index];
   double close_0=close[index];
   double low_0=low[index];
   double high_0=high[index];
   double body_top_0=fmax(open_0,close_0);
   double body_bottom_0=fmin(open_0,close_0);
   double body_size_0=body_top_0-body_bottom_0;
   double shadow_upper_0=high_0-body_top_0;
   double shadow_lower_0=body_bottom_0-low_0;
//--- свеча со смещением 1
   double open_1=open[index+1];
   double close_1=close[index+1];
   double low_1=low[index+1];
   double high_1=high[index+1];
   double body_top_1=fmax(open_1,close_1);
   double body_bottom_1=fmin(open_1,close_1);
   double body_size_1=body_top_1-body_bottom_1;
   double shadow_upper_1=high_1-body_top_1;
   double shadow_lower_1=body_bottom_1-low_1;
//--- свеча со смещением 2
   double open_2=open[index+2];
   double close_2=close[index+2];
   double low_2=low[index+2];
   double high_2=high[index+2];
   double body_top_2=fmax(open_2,close_2);
   double body_bottom_2=fmin(open_2,close_2);
   double body_size_2=body_top_2-body_bottom_2;
   double shadow_upper_2=high_2-body_top_2;
   double shadow_lower_2=body_bottom_2-low_2;

//--- однобаровые паттерны
   if(InpEnableOneBarPatterns)
     {
      if(Cmp(open_0,close_0)==0 && shadow_upper_0>min_dev4 && shadow_lower_0>min_dev4)
         if(InpEnablePAT_NB) DrawPattern(index,PATTERN_TYPE_NB,high,low,time);
      if(close_0==high_0)
         if(InpEnablePAT_FBU) DrawPattern(index,PATTERN_TYPE_FBU,high,low,time);
      if(close_0==low_0)
         if(InpEnablePAT_FBD) DrawPattern(index,PATTERN_TYPE_FBD,high,low,time);
      if(shadow_upper_0<=min_dev && shadow_lower_0>2*body_size_0)
         if(InpEnablePAT_HAMMER) DrawPattern(index,PATTERN_TYPE_HAMMER,high,low,time);
      if(shadow_lower_0<=min_dev && shadow_upper_0>2*body_size_0)
         if(InpEnablePAT_SHOOTSTAR) DrawPattern(index,PATTERN_TYPE_SHOOTSTAR,high,low,time);
     }

//--- двухбаровые паттерны
   if(InpEnableTwoBarPatterns)
     {
      if(Cmp(high_0,high_1)<0 && Cmp(low_0,low_1)>0)
         if(InpEnablePAT_INSIDE) DrawPattern(index,PATTERN_TYPE_INSIDE,high,low,time);
      if(Cmp(high_0,high_1)>0 && Cmp(low_0,low_1)<0)
         if(InpEnablePAT_OUTSIDE) DrawPattern(index,PATTERN_TYPE_OUTSIDE,high,low,time);
      if(Cmp(high_0,high_1)==0 && Cmp(close_0,close_1)<0 && Cmp(low_0,low_1)<=0)
         if(InpEnablePAT_DBHLC) DrawPattern(index,PATTERN_TYPE_DBHLC,high,low,time);
      if(Cmp(low_0,low_1)==0 && Cmp(close_0,close_1)>0 && Cmp(high_0,high_1)>=0)
         if(InpEnablePAT_DBLHC) DrawPattern(index,PATTERN_TYPE_DBLHC,high,low,time);
      if(Cmp(body_size_1,body_size_0)==0 && Cmp(open_1,close_0)==0)
         if(InpEnablePAT_MB) DrawPattern(index,PATTERN_TYPE_MB,high,low,time);
      if(Cmp(high_0,high_1)<0 && Cmp(low_0,low_1)>0 && Cmp(close_1,open_1)>0 && Cmp(close_0,open_0)<0 && Cmp(body_size_1,body_size_0)>0 && Cmp(close_1,open_0)>0 && Cmp(open_1,close_0)<0)
         if(InpEnablePAT_BEARHARAMI) DrawPattern(index,PATTERN_TYPE_BEARHARAMI,high,low,time);
      if(Cmp(high_0,high_1)<0 && Cmp(low_0,low_1)>0 && Cmp(close_1,open_1)>0 && Cmp(open_0,close_0)==0 && Cmp(body_size_1,body_size_0)>0 && Cmp(close_1,open_0)>0 && Cmp(open_1,close_0)<0)
         if(InpEnablePAT_BEARHARAMICROSS) DrawPattern(index,PATTERN_TYPE_BEARHARAMICROSS,high,low,time);
      if(Cmp(high_0,high_1)<0 && Cmp(low_0,low_1)>0 && Cmp(close_1,open_1)<0 && Cmp(close_0,open_0)>0 && Cmp(body_size_1,body_size_0)>0 && Cmp(close_1,open_0)<0 && Cmp(open_1,close_0)>0)
         if(InpEnablePAT_BULLHARAMI) DrawPattern(index,PATTERN_TYPE_BULLHARAMI,high,low,time);
      if(Cmp(high_0,high_1)<0 && Cmp(low_0,low_1)>0 && Cmp(close_1,open_1)<0 && Cmp(open_0,close_0)==0 && Cmp(body_size_1,body_size_0)>0 && Cmp(close_1,open_0)<0 && Cmp(open_1,close_0)>0)
         if(InpEnablePAT_BULLHARAMICROSS) DrawPattern(index,PATTERN_TYPE_BULLHARAMICROSS,high,low,time);
      if(Cmp(close_1,open_1)>0 && Cmp(close_0,open_0)<0 && Cmp(high_1,open_0)<0 && Cmp(close_0,close_1)<0 && Cmp(close_0,open_1)>0)
         if(InpEnablePAT_DARKCLOUD) DrawPattern(index,PATTERN_TYPE_DARKCLOUD,high,low,time);
      if(Cmp(open_0,close_0)==0 && Cmp(close_1,open_1)>0 && Cmp(open_0,high_1)>0 && Cmp(close_1,open_1)<0 && Cmp(open_0,low_1)<0)
         if(InpEnablePAT_DOJISTAR) DrawPattern(index,PATTERN_TYPE_DOJISTAR,high,low,time);
      if(Cmp(close_1,open_1)>0 && Cmp(close_0,open_0)<0 && Cmp(open_0,close_1)>0 && Cmp(close_0,open_1)<0)
         if(InpEnablePAT_ENGBEARLINE) DrawPattern(index,PATTERN_TYPE_ENGBEARLINE,high,low,time);
      if(Cmp(close_1,open_1)<0 && Cmp(close_0,open_0)>0 && Cmp(open_0,close_1)<0 && Cmp(close_0,open_1)>0)
         if(InpEnablePAT_ENGBULLLINE) DrawPattern(index,PATTERN_TYPE_ENGBULLLINE,high,low,time);
      if(Cmp(open_0,close_0)==0 && shadow_upper_0>min_dev4 && shadow_lower_0>min_dev4 && Cmp(open_1,close_1)==0 && shadow_upper_1>min_dev4 && shadow_lower_1>min_dev4)
         if(InpEnablePAT_NB2) DrawPattern(index,PATTERN_TYPE_NB2,high,low,time);
     }

//--- трёхбаровые паттерны
   if(InpEnableThreeBarPatterns)
     {
      if(Cmp(high_0,high_1)<0 && Cmp(low_0,low_1)>0 && Cmp(high_1,high_2)<0 && Cmp(low_1,low_2)>0)
         if(InpEnablePAT_DOUBLE_INSIDE) DrawPattern(index,PATTERN_TYPE_DOUBLE_INSIDE,high,low,time);
      if(Cmp(high_1,high_2)>0 && Cmp(high_1,high_0)>0 && Cmp(low_1,low_2)>0 && Cmp(low_1,low_0)>0 && body_size_1*2<shadow_upper_1)
         if(InpEnablePAT_PINUP) DrawPattern(index,PATTERN_TYPE_PINUP,high,low,time);
      if(Cmp(high_1,high_2)<0 && Cmp(high_1,high_0)<0 && Cmp(low_1,low_2)<0 && Cmp(low_1,low_0)<0 && body_size_1*2<shadow_lower_1)
         if(InpEnablePAT_PINDOWN) DrawPattern(index,PATTERN_TYPE_PINDOWN,high,low,time);
      if(Cmp(high_1,high_2)>0 && Cmp(high_1,high_0)>0 && Cmp(low_1,low_2)>0 && Cmp(low_1,low_0)>0 && Cmp(close_0,low_1)<0)
         if(InpEnablePAT_PPRDN) DrawPattern(index,PATTERN_TYPE_PPRDN,high,low,time);
      if(Cmp(high_1,high_2)<0 && Cmp(high_1,high_0)<0 && Cmp(low_1,low_2)<0 && Cmp(low_1,low_0)<0 && Cmp(close_0,high_1)>0)
         if(InpEnablePAT_PPRUP) DrawPattern(index,PATTERN_TYPE_PPRUP,high,low,time);
      if(Cmp(high_1,high_2)<0 && Cmp(low_1,low_2)<0 && Cmp(high_0,high_1)<0 && Cmp(low_0,low_1)<0 && Cmp(close_0,close_1)>0 && Cmp(open_0,close_0)<0)
         if(InpEnablePAT_CPRU) DrawPattern(index,PATTERN_TYPE_CPRU,high,low,time);
      if(Cmp(high_1,high_2)>0 && Cmp(low_1,low_2)>0 && Cmp(high_0,high_1)>0 && Cmp(low_0,low_1)>0 && Cmp(close_0,close_1)<0 && Cmp(open_0,close_0)>0)
         if(InpEnablePAT_CPRD) DrawPattern(index,PATTERN_TYPE_CPRD,high,low,time);
      if(Cmp(close_2,open_2)>0 && Cmp(close_1,open_1)>0 && Cmp(close_0,open_0)<0 && Cmp(close_2,open_1)<0 && Cmp(body_size_2,body_size_1)>0 && Cmp(body_size_1,body_size_0)<0 && Cmp(close_0,open_2)>0 && Cmp(close_0,close_2)<0)
         if(InpEnablePAT_EVSTAR) DrawPattern(index,PATTERN_TYPE_EVSTAR,high,low,time);
      if(Cmp(close_2,open_2)<0 && Cmp(close_1,open_1)>0 && Cmp(close_0,open_0)>0 && Cmp(close_2,open_1)>0 && Cmp(body_size_2,body_size_1)>0 && Cmp(body_size_1,body_size_0)<0 && Cmp(close_0,close_2)>0 && Cmp(close_0,open_2)<0)
         if(InpEnablePAT_MORNSTAR) DrawPattern(index,PATTERN_TYPE_MORNSTAR,high,low,time);
      if(Cmp(close_2,open_2)>0 && Cmp(close_1,open_1)==0 && Cmp(close_0,open_0)<0 && Cmp(close_2,open_1)<0 && Cmp(body_size_2,body_size_1)>0 && Cmp(body_size_1,body_size_0)<0 && Cmp(close_0,open_2)>0 && Cmp(close_0,close_2)<0)
         if(InpEnablePAT_EVDJSTAR) DrawPattern(index,PATTERN_TYPE_EVDJSTAR,high,low,time);
      if(Cmp(close_2,open_2)<0 && Cmp(close_1,open_1)==0 && Cmp(close_0,open_0)>0 && Cmp(close_2,open_1)>0 && Cmp(body_size_2,body_size_1)>0 && Cmp(body_size_1,body_size_0)<0 && Cmp(close_0,close_2)>0 && Cmp(close_0,open_2)<0)
         if(InpEnablePAT_MORNDJSTAR) DrawPattern(index,PATTERN_TYPE_MORNDJSTAR,high,low,time);
     }
  }
//+------------------------------------------------------------------+
//| Отображает паттерн                                               |
//+------------------------------------------------------------------+
void DrawPattern(int index,ENUM_PATTERN_TYPE pattern_type,const double &high[],const double &low[],const datetime &time[])
  {
   bool up=true;
   int length=1;
   double price=0;
//---
   if(pattern_type==PATTERN_TYPE_NB) {up=true; length=1;}
   if(pattern_type==PATTERN_TYPE_FBU) {up=false; length=1;}
   if(pattern_type==PATTERN_TYPE_FBD) {up=true; length=1;}
   if(pattern_type==PATTERN_TYPE_HAMMER) {up=true; length=1;}
   if(pattern_type==PATTERN_TYPE_SHOOTSTAR) {up=true; length=1;}

   if(pattern_type==PATTERN_TYPE_INSIDE) {up=true; length=2;}
   if(pattern_type==PATTERN_TYPE_OUTSIDE) {up=true; length=2;}
   if(pattern_type==PATTERN_TYPE_DBHLC) {up=true; length=2;}
   if(pattern_type==PATTERN_TYPE_DBLHC) {up=false; length=2;}
   if(pattern_type==PATTERN_TYPE_MB) {up=true; length=2;}
   if(pattern_type==PATTERN_TYPE_BEARHARAMI) {up=true; length=2;}
   if(pattern_type==PATTERN_TYPE_BEARHARAMICROSS) {up=true; length=2;}
   if(pattern_type==PATTERN_TYPE_BULLHARAMI) {up=true; length=2;}
   if(pattern_type==PATTERN_TYPE_BULLHARAMICROSS) {up=true; length=2;}
   if(pattern_type==PATTERN_TYPE_DARKCLOUD) {up=true; length=2;}
   if(pattern_type==PATTERN_TYPE_DOJISTAR) {up=true; length=2;}
   if(pattern_type==PATTERN_TYPE_ENGBEARLINE) {up=true; length=2;}
   if(pattern_type==PATTERN_TYPE_ENGBULLLINE) {up=true; length=2;}
   if(pattern_type==PATTERN_TYPE_NB2) {up=true; length=2;}

   if(pattern_type==PATTERN_TYPE_DOUBLE_INSIDE) {up=true; length=3;}
   if(pattern_type==PATTERN_TYPE_PINUP) {up=true; length=3;}
   if(pattern_type==PATTERN_TYPE_PINDOWN) {up=false; length=3;}
   if(pattern_type==PATTERN_TYPE_PPRDN) {up=true; length=3;}
   if(pattern_type==PATTERN_TYPE_PPRUP) {up=false; length=3;}
   if(pattern_type==PATTERN_TYPE_CPRU) {up=false; length=3;}
   if(pattern_type==PATTERN_TYPE_CPRD) { up=true; length=3;}
   if(pattern_type==PATTERN_TYPE_EVSTAR) {up=true; length=3;}
   if(pattern_type==PATTERN_TYPE_MORNSTAR) {up=true; length=3;}
   if(pattern_type==PATTERN_TYPE_EVDJSTAR) {up=true; length=3;}
   if(pattern_type==PATTERN_TYPE_MORNDJSTAR) {up=true; length=3;}

   price=(up ? high[Highest(NULL,PERIOD_CURRENT,length,index)]+BufferATR[index] : low[Lowest(NULL,PERIOD_CURRENT,length,index)]-BufferATR[index]);
   Pattern[pattern_type].Buffer[index]=price;
   Pattern[pattern_type].type_pattern=pattern_type;
   if(InpShowPatternDescript)
      DrawLabel(pattern_type,price,index,high,low,time,up);
  }
//+------------------------------------------------------------------+
//| Выводит надпись с названием паттерна                             |
//+------------------------------------------------------------------+
void DrawLabel(const ENUM_PATTERN_TYPE type_pattern,const double price,const int index,const double &high[],const double &low[],const datetime &time[],const bool upper)
  {
   string tm=TimeToString(time[index]);
   string name=prefix+DescrShortPattern(type_pattern)+"_"+(string)index+"_"+tm;
   ObjectCreate(0,name,OBJ_TEXT,0,time[index],price);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetString(0,name,OBJPROP_TEXT,DescriptionPattern(type_pattern));
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,InpFontSize);
   ObjectSetString(0,name,OBJPROP_FONT,font_name);
   ObjectSetInteger(0,name,OBJPROP_COLOR,InpFontColor);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"Pattern on "+NameTimeframe()+":\n"+DescriptionPattern(type_pattern)+"\n"+tm);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,(upper ? ANCHOR_LEFT_LOWER : ANCHOR_LEFT_UPPER));
   //---
   name=prefix+DescrShortPattern(type_pattern)+"_vl_"+(string)index+"_"+tm;
   ObjectCreate(0,name,OBJ_TREND,0,0,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clrRed);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,0);
   ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_DOT);
   ObjectSetInteger(0,name,OBJPROP_RAY,false);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"\n");
   ObjectSetInteger(0,name,OBJPROP_TIME,0,time[index]);
   ObjectSetInteger(0,name,OBJPROP_TIME,1,time[index]);
   ObjectSetDouble(0,name,OBJPROP_PRICE,0,(upper ? high[index] : low[index]));
   ObjectSetDouble(0,name,OBJPROP_PRICE,1,price);
  }
//+------------------------------------------------------------------+
//| Возвращает наименование паттерна по индексу                      |
//+------------------------------------------------------------------+
string DescriptionPattern(const int index)
  {
   return(ArrayNames[index][0]);
  }
//+------------------------------------------------------------------+
//| Возвращает наименование паттерна по перечислению                 |
//+------------------------------------------------------------------+
string DescriptionPattern(const ENUM_PATTERN_TYPE pattern)
  {
   return(ArrayNames[(int)pattern][0]);
  }
//+------------------------------------------------------------------+
//| Возвращает короткое наименование паттерна по индексу             |
//+------------------------------------------------------------------+
string DescrShortPattern(const int index)
  {
   return(ArrayNames[index][1]);
  }
//+------------------------------------------------------------------+
//| Возвращает короткое наименование паттерна по перечислению        |
//+------------------------------------------------------------------+
string DescrShortPattern(const ENUM_PATTERN_TYPE pattern)
  {
   return(ArrayNames[(int)pattern][1]);
  }
//+------------------------------------------------------------------+
//| Возвращает индекс наибольшего значения в массиве                 |
//+------------------------------------------------------------------+
int Highest(const string symbol_name,const ENUM_TIMEFRAMES timeframe,const int count,const int start)
  {
   string symb=(symbol_name==NULL || symbol_name=="" ? Symbol() : symbol_name);
   double array[];
   ArraySetAsSeries(array,true);
   if(CopyHigh(symb,timeframe,start,count,array)==count)
      return ArrayMaximum(array)+start;
   return WRONG_VALUE;
  }
//+------------------------------------------------------------------+
//| Возвращает индекс наименьшего значения в массиве                 |
//+------------------------------------------------------------------+
int Lowest(const string symbol_name,const ENUM_TIMEFRAMES timeframe,const int count,const int start)
  {
   string symb=(symbol_name==NULL || symbol_name=="" ? Symbol() : symbol_name);
   double array[];
   ArraySetAsSeries(array,true);
   if(CopyLow(symb,timeframe,start,count,array)==count)
      return ArrayMinimum(array)+start;
   return WRONG_VALUE;
  }
//+------------------------------------------------------------------+
//| Возвращает результат сравнения двух цен                          |
//+------------------------------------------------------------------+
int Cmp(double price1,double price2)
  {
   return(fabs(price1-price2)<eq_pp ? 0 : price1>price2 ? 1 : -1);
  }
//+------------------------------------------------------------------+
//| Возвращает наименование таймфрейма                               |
//+------------------------------------------------------------------+
string NameTimeframe(int timeframe=PERIOD_CURRENT)
  {
   if(timeframe==PERIOD_CURRENT) timeframe=Period();
   switch(timeframe)
     {
      case 1      : return "M1";
      case 2      : return "M2";
      case 3      : return "M3";
      case 4      : return "M4";
      case 5      : return "M5";
      case 6      : return "M6";
      case 10     : return "M10";
      case 12     : return "M12";
      case 15     : return "M15";
      case 20     : return "M20";
      case 30     : return "M30";
      case 16385  : return "H1";
      case 16386  : return "H2";
      case 16387  : return "H3";
      case 16388  : return "H4";
      case 16390  : return "H6";
      case 16392  : return "H8";
      case 16396  : return "H12";
      case 16408  : return "D1";
      case 32769  : return "W1";
      case 49153  : return "MN1";
      default     : return (string)(int)Period();
     }
  }
//+------------------------------------------------------------------+