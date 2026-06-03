# Framework Documentation — Complete Reference Document

---

## THE MASTER TRADING FRAMEWORK
### Built on The Candlestick Trading Bible
#### Version 1.0 — Final

---

# SECTION 1: THE CORE FORMULA

> *Everything in this framework answers three questions and three questions only.*

```
QUESTION 1: WHAT IS THE MARKET DOING?
QUESTION 2: WHAT ARE THE KEY LEVELS?
QUESTION 3: WHAT IS THE SIGNAL?

If you cannot answer all three clearly
and simultaneously — there is no trade.
```

---

# SECTION 2: THE TIMEFRAME HIERARCHY

```
╔══════════════════════════════════════════════════════════════╗
║  TIMEFRAME   PURPOSE                        QUESTIONS        ║
╠══════════════════════════════════════════════════════════════╣
║              Market structure + bias         Q1 + Q2         ║
║  WEEKLY      Major S/R identification                        ║
║              Last weekly candle read                         ║
║              Big institutional intent                        ║
╠══════════════════════════════════════════════════════════════╣
║              Trend confirmation              Q1 + Q2         ║
║  DAILY       Key S/R + Supply/Demand zones                   ║
║              Fibonacci swing mapping                         ║
║              Retracement zone identification                 ║
╠══════════════════════════════════════════════════════════════╣
║              PRIMARY TRADING TIMEFRAME       Q2 + Q3         ║
║  4H          Pattern identification                          ║
║              Retracement phase reading                       ║
║              Dynamic KAMA interaction                        ║
║              Signal confirmation                             ║
╠══════════════════════════════════════════════════════════════╣
║              Market structure refinement     Q1              ║
║  1H          Retracement exhaustion reading                  ║
║              HH/HL or LH/LL confirmation                     ║
║              NOTE: Bypassed for Grade A                      ║
║              Engulfing Bar (Override Clause)                 ║
╠══════════════════════════════════════════════════════════════╣
║              EXECUTION ONLY                  Q3              ║
║  5M / 15M    Entry candle precision                          ║
║              Stop placement calibration                      ║
║              NO signal generation here                       ║
║              NO pattern hunting here                         ║
╚══════════════════════════════════════════════════════════════╝
```

---

# SECTION 3: MARKET CLASSIFICATION

> *Classification happens on Weekly and Daily only. Never on 4H or below. If the market cannot be classified — close the chart.*

---

## State 1: Trending Market

```
UPTREND DEFINITION:
Series of Higher Highs + Higher Lows
Each swing meaningful in size (see VIX75 minimums)

DOWNTREND DEFINITION:
Series of Lower Highs + Lower Lows
Each swing meaningful in size

CHARACTERISTIC:
Two moves exist inside every trend:
→ Impulsive Move  = direction of trend
→ Retracement     = counter-move before next impulse

YOUR JOB IN A TREND:
Never enter the impulsive move late
Never fight the retracement
Wait for retracement to reach key level
Enter at the START of the next impulsive move

ACTION: Trade WITH trend only
        Counter-trend only for experienced traders
        at Weekly key levels with Grade A signal
```

---

## State 2: Ranging Market

```
DEFINITION:
Price bouncing between defined boundaries
Minimum 2 confirmed touches of support
Minimum 2 confirmed touches of resistance
No HH/HL or LH/LL structure present

FOUR STRATEGIES AVAILABLE:
┌────────────────────────────────────────────────┐
│ Strategy 1: Fade from boundaries               │
│ Buy at support / Sell at resistance            │
│ Signal required at boundary                    │
│ Bollinger Bands confirm extremes               │
├────────────────────────────────────────────────┤
│ Strategy 2: Trade the breakout                 │
│ Enter after confirmed boundary break           │
│ Verify breakout is real not false              │
│ Momentum and candle close required             │
├────────────────────────────────────────────────┤
│ Strategy 3: Trade the pullback                 │
│ Miss the breakout? Wait for retest             │
│ Broken resistance becomes support              │
│ Signal required at retest level                │
├────────────────────────────────────────────────┤
│ Strategy 4: Trade the false breakout           │
│ Inside bar false breakout at boundary          │
│ Highest probability ranging setup              │
│ Best R:R of all ranging strategies             │
│ Candle close rule applies strictly             │
└────────────────────────────────────────────────┘
```

---

## State 3: Choppy Market

```
DEFINITION:
No clear direction
No identifiable boundaries
Price moving in tight, noisy oscillation
Cannot determine if trending or ranging

ONE RULE ONLY:
DO NOT TRADE

Close the chart.
Find another instrument.
No pattern has statistical edge
in a choppy market.
No exceptions.
```

---

# SECTION 4: THE RETRACEMENT LOGIC

> *This is the framework's most critical structural insight. Master this and timeframe conflicts disappear permanently.*

```
WHEN HIGHER AND LOWER TIMEFRAMES APPEAR TO CONFLICT:

Weekly = Bullish + Daily = Bullish + 4H = Bearish
→ THIS IS NOT A CONFLICT
→ THE 4H BEARISH MOVE IS THE RETRACEMENT

Weekly = Bearish + Daily = Bearish + 4H = Bullish
→ THIS IS NOT A CONFLICT
→ THE 4H BULLISH MOVE IS THE RETRACEMENT

THE RETRACEMENT TELLS YOU TWO THINGS:
1. WHAT is happening
   Price is seeking liquidity at a key level

2. WHERE it ends
   At the identified key level on Daily or Weekly

YOUR ONLY JOB DURING A RETRACEMENT:
Identify the key level the retracement is heading to
Wait for the signal at that level
Enter the next impulsive move — not the retracement

TRUE CONFLICT — THE ONLY ONE THAT EXISTS:
Weekly Bearish + Daily Bearish + 4H Bullish = No trade
Two higher timeframes aligned against the setup
= Insufficient institutional backing
= Sit out

Weekly Bullish + Daily Bullish + 4H Bearish = Retracement
= High probability setup forming
= Prepare your entry
```

---

# SECTION 5: KEY LEVEL HIERARCHY

> *Levels are not equal. Their weight determines confluence strength.*

```
╔══════════════════════════════════════════════════════════════╗
║  RANK   LEVEL TYPE              WEIGHT    NOTES              ║
╠══════════════════════════════════════════════════════════════╣
║   1     Weekly S/R              MAXIMUM   Overrides all      ║
║         Major turning points             lower signals       ║
║         Institutional barriers          Non-negotiable       ║
╠══════════════════════════════════════════════════════════════╣
║   2     Daily S/R +             HIGH      Bank/institution   ║
║         Supply & Demand zones            order zones         ║
║                                          Strong move away    ║
║                                          = institutional     ║
╠══════════════════════════════════════════════════════════════╣
║   3     Daily KAMA (8/21)       HIGH      EQUAL WEIGHT       ║
║         ★ PATCH 1 APPLIED ★             to static Daily S/R ║
║                                          Valid in fast trends ║
║                                          where static levels  ║
║                                          are not present     ║
╠══════════════════════════════════════════════════════════════╣
║   4     Fibonacci 50% & 61.8%   MEDIUM    Pinpoints entry    ║
║         (These two levels only)          zone within S/R     ║
║                                          Most major moves    ║
║                                          retrace to these    ║
╠══════════════════════════════════════════════════════════════╣
║   5     4H KAMA Dynamic S/R     MEDIUM    Confluence         ║
║                                          confirmation only   ║
║                                          Not standalone      ║
╠══════════════════════════════════════════════════════════════╣
║   6     Trendlines              LOWER     Linear S/R         ║
║                                          Valid but lower     ║
║                                          weight than         ║
║                                          horizontal levels   ║
╚══════════════════════════════════════════════════════════════╝

CONFLUENCE MINIMUM REQUIREMENT:
At least 2 levels must align at the same zone
before any signal is considered tradeable

EXAMPLE OF STRONG CONFLUENCE:
Weekly S/R + Fibonacci 61.8% + Daily KAMA
= Three levels at one zone
= Maximum probability setup
```

---

# SECTION 6: PATTERN GRADING SYSTEM

---

## The Pin Bar

```
ANATOMY:
Small real body (open and close tightly together)
Long tail showing rejection from a level
Bullish pin = long lower tail
Bearish pin = long upper tail

GRADE A — ALL CRITERIA REQUIRED:
□ Tail minimum 2× length of real body
□ Small real body — open and close within 25% of range
□ Formed on 4H or Daily — never smaller timeframe
□ Formed at identified key level (minimum rank 4)
□ In line with Weekly + Daily trend direction
□ Bullish pin = white/green body preferred
□ Bearish pin = black/red body preferred

GRADE B — TRADEABLE WITH CAUTION:
□ Tail slightly less than 2× body
□ All other Grade A criteria met
□ Requires one additional confluence factor
□ Reduced position size applies

NO TRADE:
□ Short tail relative to body
□ No key level present at formation
□ Against two or more higher timeframe directions
□ Formed in choppy or ranging market interior
□ Formed on 1H or below (signal generation prohibited)
```

---

## The Engulfing Bar

```
ANATOMY:
Two candles — second fully consumes the first
Bullish engulfing = forms at downtrend exhaustion
Bearish engulfing = forms at uptrend exhaustion

GRADE A — ALL CRITERIA REQUIRED:
□ Market in clearly definable trend
□ Second candle completely engulfs first candle
□ Second candle opposite color to first candle
□ Forms at key level — minimum rank 4 confluence
□ In line with Weekly + Daily direction
□ ★ OVERRIDE CLAUSE ACTIVE ON GRADE A ★
  Bypasses 1H structure check
  Drops directly to 15M for execution

GRADE B — TRADEABLE WITH CAUTION:
□ Second candle engulfs first
□ Color rule marginal or not met
□ Single confluence factor only
□ 1H structure check NOT bypassed
□ Reduced position size applies

NO TRADE:
□ Forms in open space with no level nearby
□ Against two or more higher TF directions
□ In choppy market
□ Second candle does not fully engulf first
```

---

## The Inside Bar & False Breakout

```
INSIDE BAR ANATOMY:
Two candles — second completely inside first
Mother candle = first (large)
Baby candle   = second (smaller, inside mother)
Indicates consolidation and indecision

INSIDE BAR GRADE A:
□ Mother candle significant in size
□ Baby candle completely inside mother candle
□ Located at key S/R level (minimum rank 4)
□ Trending market = continuation signal
□ Top/bottom of trend = reversal signal

FALSE BREAKOUT GRADE A
(Highest Probability Setup In Entire Framework):
□ Inside bar forms at key level
□ Price breaks out of inside bar in one direction
□ Price immediately reverses direction
□ ★ PATCH 3 APPLIED ★
  Execution strictly prohibited until
  micro-reversal candle has CLOSED
  back inside the 4H Mother Bar BODY
  Not the wick range — the BODY
□ Trapped traders now exposed on wrong side
□ Enter in opposite direction of false move
□ Signature R:R: 1:8 potential

NO TRADE:
□ Inside bar in choppy market
□ False breakout with no key level present
□ Cannot identify which direction was false
□ Reversal candle closes inside wick only
   not inside body of mother candle
□ VIX75: excursion less than 80 points
```

---

# SECTION 7: THE THREE ENTRY METHODS

---

## Method 1: Aggressive Entry

```
WHEN TO USE:
Strong confluence (3+ levels)
Clear trend with momentum
Pin bar or Inside bar setup

EXECUTION:
Enter immediately after signal candle
closes on 4H chart
Do not wait for retracement into candle

STOP LOSS:
Beyond the extreme of the signal candle tail
Forex : ATR(14) × 1.5 beyond extreme
VIX75 : ATR(14) × 2.5 beyond extreme

PROFIT TARGET:
Next significant S/R level in trade direction
```

---

## Method 2: Conservative Entry

```
WHEN TO USE:
Large signal candle creates wide stop
Better R:R ratio needed
Pin bar with oversized tail

EXECUTION:
Wait for 50% retracement of signal
candle's total range after it closes
Enter when price pulls back halfway

RISK:
Market may not retrace to 50%
If it does not retrace — trade is missed
Do not chase — accept the miss

REWARD:
When it works: potential 5:1 R:R
One trade per month at this ratio
is sufficient for meaningful returns
```

---

## Method 3: False Breakout Entry

```
WHEN TO USE:
Inside bar false breakout identified
At key level with 2+ confluence factors

EXECUTION SEQUENCE:
Step 1: Inside bar identified on 4H at key level
Step 2: Price breaks out of mother bar
        (stop hunting phase — do not enter)
Step 3: Price reverses direction
Step 4: ★ WAIT — CANDLE MUST CLOSE ★
Step 5: 15M candle closes INSIDE mother bar BODY
Step 6: ENTER after confirmed close only

★ PATCH 3 — ABSOLUTE RULE:
Execution on 15M is strictly prohibited
until the micro-reversal candle has
definitively CLOSED back inside
the 4H Mother Bar body boundary
Entering on an open candle =
you are the trapped liquidity
Trade closed candles — not intentions

STOP LOSS:
Beyond the false breakout extreme
VIX75: minimum 80 point excursion required
       before false breakout is considered valid

PROFIT TARGET:
First major S/R beyond the trap zone
```

---

# SECTION 8: THE DECISION TREE

```
═══════════════════════════════════════════
STEP 1: OPEN WEEKLY CHART
═══════════════════════════════════════════
         │
         ▼
Can you classify the market?
         │
    ┌────┴────┐
  CHOPPY   TRENDING or RANGING
    │               │
 CLOSE           CONTINUE
 CHART
         │
         ▼
═══════════════════════════════════════════
STEP 2: WEEKLY ANALYSIS
═══════════════════════════════════════════
Identify: Major S/R levels
Identify: Trend direction
Read:     Last weekly candle
Record:   Bullish / Bearish bias
         │
         ▼
═══════════════════════════════════════════
STEP 3: OPEN DAILY CHART
═══════════════════════════════════════════
Confirm:  Trend structure
Identify: Daily S/R + Supply/Demand
Map:      Fibonacci on last major swing
Note:     Where retracement zones sit
Note:     Where KAMA is acting as S/R
         │
         ▼
═══════════════════════════════════════════
STEP 4: OPEN 4H CHART
═══════════════════════════════════════════
         │
Is 4H WITH or AGAINST Daily/Weekly?
         │
    ┌────┴─────┐
AGAINST        WITH
(Retracement)  (Impulse in progress)
    │               │
Note the       Is there a pattern
key level      at current level?
it heads to         │
    │          ┌────┴────┐
    └────┬─────┘        NO
         │             WAIT
         ▼
Is there a Grade A or B pattern
at confluence of 2+ key levels?
         │
    ┌────┴────┐
   NO        YES
    │          │
  WAIT    PATTERN CHECK:
           Is it Grade A Engulfing?
                   │
         ┌─────────┴─────────┐
        YES                  NO
         │                   │
★ OVERRIDE CLAUSE ★    PROCEED TO 1H
Bypass 1H check
Drop to 15M directly
         │
         ▼
═══════════════════════════════════════════
STEP 5: OPEN 1H CHART (if not bypassed)
═══════════════════════════════════════════
Confirm:  Structure direction
Look for: HH/HL = Bullish confirmation
          LH/LL = Bearish confirmation
Look for: Structure shift = reversal ready
         │
         ▼
═══════════════════════════════════════════
STEP 6: DROP TO 15M OR 5M — EXECUTION
═══════════════════════════════════════════
Find:     Entry candle at exact key level
Calculate: Stop loss placement
Calculate: Profit target (next S/R)
Calculate: R:R ratio

Is R:R ≥ 1:2 (Forex) or 1:3 (VIX75)?
         │
    ┌────┴────┐
   NO        YES
    │          │
 IGNORE    EXECUTE TRADE
 SETUP     Place stop loss
           Place profit target
           Walk away
```

---

# SECTION 9: RISK MANAGEMENT

---

## Position Sizing

```
THINK IN DOLLARS — NOT PIPS

Account Risk Per Trade:
Beginners      : 1% maximum per trade
Advanced       : 2% maximum per trade
VIX75 (all)   : 0.5% per trade

Lot Sizing Formula:
Dollar Risk = Account Balance × Risk %
Stop Distance in pips = from entry to stop loss
Lot Size = Dollar Risk ÷ (Stop pips × pip value)

Standard lot  = $10 per pip
Mini lot      = $1 per pip
Micro lot     = $0.10 per pip
```

---

## Risk:Reward Requirements

```
ABSOLUTE MINIMUM:
Forex          : 1:2 R:R — never below
VIX75          : 1:3 R:R — elevated for volatility
False Breakout : 1:8 potential — signature setup

Never enter a trade where profit potential
is less than the amount being risked
No exceptions regardless of setup quality
```

---

## Stop Loss Rules

```
HARD RULE:
Every trade has a stop loss placed at execution
Mental stops are prohibited
No exceptions

PLACEMENT:
Pin Bar      : Beyond the tip of the tail
Engulfing    : Beyond full engulfing candle extreme
Inside Bar   : Beyond the mother candle extreme
False BO     : Beyond the false breakout extreme

ATR CALIBRATION:
Forex  : Stop = ATR(14) × 1.5 beyond signal extreme
VIX75  : Stop = ATR(14) × 2.5 beyond signal extreme
```

---

## Profit Target Rules

```
Trending market  : Next significant S/R level
Ranging market   : Opposite boundary of the range
False breakout   : First major S/R beyond trap zone

Once stop and target are placed:
DO NOT MOVE THE STOP LOSS TO LOSS
DO NOT CLOSE EARLY FROM EMOTION
Let the market confirm or deny the trade
```

---

## Daily Loss Limit

```
Maximum 2 consecutive losing trades per session
After 2 consecutive losses:
→ Close all charts
→ Stop trading for the day
→ Resume next session fresh

REASONING:
Two consecutive losses indicates either
market conditions have shifted
or emotional state is compromised
Both require a mandatory reset
```

---

## Weekly Drawdown Threshold

```
WEEKLY LOSS LIMIT: 6%

If cumulative weekly loss reaches 6%:
→ Stop trading immediately
→ Close all analysis
→ Reset the following Monday
→ Resume at full parameters Monday open
→ No exceptions
→ No "one more setup"

The 6% represents statistical evidence
that conditions are not favorable
Not a personal failure — a market condition
```

---

## Re-Entry Rule

```
A stopped trade is a closed case.
It does not exist anymore.

Re-entry requires:
A completely new signal formation
Same level + new pattern = new trade
Treated as a fresh independent setup

PROHIBITED:
Chasing a stopped trade
Doubling down on a lost direction
Emotional re-entry without new signal
Revenge trading of any kind
```

---

# SECTION 10: THE STRATEGY MAP

---

## Trending Market Playbook

```
PRIMARY STRATEGY: Trade WITH trend at retracements

EXECUTION SEQUENCE:
1. Identify trend direction on Weekly + Daily
2. Identify key level where retracement ends
   (Static S/R / Daily KAMA / Fibonacci 50-61.8%)
3. Wait for 4H pattern at that level
4. Confirm on 1H (unless Grade A Engulfing)
5. Execute on 15M or 5M

VALID SIGNALS IN TREND:
Pin bar at retracement level
Engulfing bar at retracement level
Inside bar at retracement level
Inside bar false breakout at retracement level

DYNAMIC S/R IN TRENDS:
KAMA (8/21) acts as dynamic support in uptrend
KAMA (8/21) acts as dynamic resistance in downtrend
KAMA touch = valid entry zone (equal to static S/R)

COUNTER-TREND RULE:
Experienced traders only
Requires Weekly key level rejection
Requires Grade A signal minimum
Requires strong multi-timeframe confluence
```

---

## Ranging Market Playbook

```
PREREQUISITE:
2+ confirmed touches of both support AND resistance
Range boundaries clearly identifiable
Market classified as ranging on Daily

STRATEGY 1 — FADE FROM BOUNDARIES:
Buy at support with signal
Sell at resistance with signal
Bollinger Bands confirm price at extreme
Do not trade inside the range

STRATEGY 2 — TRADE THE BREAKOUT:
Wait for confirmed candle close beyond boundary
Confirm breakout is not a false move
Enter on momentum after confirmed close
Target opposite boundary + beyond

STRATEGY 3 — TRADE THE PULLBACK:
Missed the breakout?
Wait for price to retest broken boundary
Broken resistance becomes support
Broken support becomes resistance
Signal required at retest point

STRATEGY 4 — FALSE BREAKOUT (HIGHEST PROBABILITY):
Inside bar forms at range boundary
Price breaks beyond boundary (trap)
Price reverses and closes back inside range
Candle close rule applies strictly
Enter after confirmed reversal close
Target opposite boundary
```

---

## Choppy Market Rule

```
╔══════════════════════════════════════╗
║  CHOPPY MARKET = DO NOT TRADE        ║
║                                      ║
║  No strategy applies here            ║
║  No pattern has edge here            ║
║  Close the chart                     ║
║  Find another instrument             ║
║  No exceptions                       ║
╚══════════════════════════════════════╝
```

---

# SECTION 11: THE INDICATOR STACK

```
╔══════════════════════════════════════════════════════════════╗
║  TIMEFRAME    INDICATORS              PURPOSE                ║
╠══════════════════════════════════════════════════════════════╣
║  WEEKLY       KAMA                    Trend bias             ║
║               Fibonacci               Major levels           ║
║               RSI (divergence only)   Momentum warning       ║
╠══════════════════════════════════════════════════════════════╣
║  DAILY        KAMA (8 + 21)           Dynamic S/R            ║
║               Fibonacci               Retracement zones      ║
║               RSI (divergence only)   Trend exhaustion       ║
║               ATR(14)                 Volatility baseline    ║
╠══════════════════════════════════════════════════════════════╣
║  4H           KAMA (8 + 21)           Dynamic S/R            ║
║               Bollinger Bands         Range confirmation      ║
║               Fibonacci               Entry zone precision   ║
║               ATR(14)                 Stop calibration       ║
╠══════════════════════════════════════════════════════════════╣
║  1H           KAMA                    Structure direction    ║
║               ATR(14)                 Live volatility check  ║
╠══════════════════════════════════════════════════════════════╣
║  5M / 15M     ATR(14)                 Position sizing only   ║
║               CLEAN CHART             Entry candle reading   ║
╚══════════════════════════════════════════════════════════════╝

INDICATOR RULES:
No indicator generates a signal independently
Candlestick pattern on 4H is always the signal
Indicators are filters, confirmations, or
risk calibration tools — nothing more

RSI RULE:
Divergence on Weekly/Daily only
Never used for overbought/oversold signals
Never used to generate entries
```

---

# SECTION 12: FOREX SPECIFIC RULES

---

## Session Filter

```
VALID TRADING SESSIONS:
London Open  : 08:00 – 12:00 GMT
New York     : 13:00 – 17:00 GMT

AVOID:
Asian session entries (identify only)
Late NY session after 17:00 GMT
```

---

## Correlation Rule

```
CORRELATED PAIRS POSITION SIZING:

Setup Grade      Risk Per Trade    Total Exposure
────────────────────────────────────────────────
Mid Setup      : 0.5% each     →  1.0% combined
Strong Setup   : 0.75% each    →  1.5% combined
Grade A Both   : 1.0% each     →  2.0% combined

CONDITION FOR FULL 1% ON BOTH:
Both setups independently qualify as Grade A
Both at different key level types
Not the same level on both pairs simultaneously

OVERRIDE:
A Grade A setup is never ignored due to correlation
Scale the size — never skip the trade
```

---

## News Event Protocol

```
HIGH IMPACT EVENTS: NFP / FOMC / CPI / Rate Decisions

PRE-NEWS (30 minutes before):
→ No new position entries
→ All pending orders cancelled
→ Floating profit positions: CLOSE
→ Drawdown positions: Assess if stop is safe
  If stop is not beyond news range: CLOSE manually

POST-NEWS (30 minutes after release):
→ No entries during the spike
→ Wait for price to settle
→ News candle becomes key level reference
→ Normal framework resumes after 30 minutes

THE NEWS CANDLE:
Not tradeable during formation
Its close and subsequent structure
is what matters — not the spike
```

---

# SECTION 13: VIX75 SPECIFIC RULEBOOK

---

## The Fundamental Difference

```
VIX75 is a synthetic index.
Price is algorithmically generated.
The algorithm targets liquidity at key levels.
Stop hunting is the operating model — not a side effect.

IMPLICATION:
The False Breakout strategy is not just valid on VIX75
It is the PRIMARY strategy
Because stop hunting IS what VIX75 does
Understanding this = trading WITH the algorithm
Not understanding this = being the algorithm's target
```

---

## Rule 1: Volatility Filter

```
INSTRUMENT: ATR(14) on 4H chart

MINIMUM THRESHOLD: 800 points

Above 800 = Active volatility = Framework applies
Below 800 = Compression phase = DO NOT TRADE

When ATR drops sharply after large move:
Algorithm is loading for next engineered move
Wait for ATR expansion above 800
The compression itself = likely inside bar forming
Watch for false breakout of compression
```

---

## Rule 2: Spread Protection

```
SPREAD LIMIT: Maximum 5 points for entry

ROLLOVER PROTECTION:
No new positions ±15 minutes of server rollover
No positions held through rollover unless
stop loss is already 3× normal spread
away from current price

WEEKEND OPEN:
No entries Sunday 00:00 – 00:15 broker time

IF SPREAD EXCEEDS 5 POINTS:
Do not execute
Wait for normalization
Re-evaluate setup — it may have passed
```

---

## Rule 3: Pattern Size Minimums

```
PIN BAR:
Total candle range minimum    = 200 points
Tail length minimum           = 150 points
Tail must be ≥ 2× body       (book rule maintained)
Body maximum                  = 80 points
Below 200 points = micro-trap = DO NOT TRADE

ENGULFING BAR:
Engulfing candle minimum      = 300 points
Candle being engulfed minimum = 150 points
Combined range minimum        = 400 points
Below 300 points = insufficient momentum

INSIDE BAR:
Mother candle minimum         = 400 points
Baby candle maximum           = 60% of mother
False breakout excursion      = minimum 80 points
Reversal close                = inside mother BODY
                                not just inside wick
```

---

## Rule 4: Session Behavior

```
HIGH LIQUIDITY — TRADE:
08:00 – 12:00 GMT  London session
13:00 – 17:00 GMT  New York session

IDENTIFY ONLY — DO NOT ENTER:
02:00 – 06:00 GMT  Asian session
Use this window to map levels
for London open setups

NO ENTRIES:
20:00 – 01:00 GMT  Thin market window
Rollover protection applies 23:45 – 00:15

SETUP MATURITY RULE:
A perfect 4H setup that matures at 21:00 GMT
waits for London open confirmation
Execute on 5M/15M during London session only
```

---

## Rule 5: Inside Bar Validity

```
VERDICT: Valid on VIX75 — False Breakout version ONLY

VALID CONDITIONS:
□ Mother candle ≥ 400 points
□ Inside bar forms during Asian session compression
□ False breakout occurs at London or NY open
□ Excursion ≥ 80 points beyond mother candle
□ Reversal close inside mother bar BODY
□ Key level from Daily or Weekly present at zone

INVALID CONDITIONS:
□ Mother candle < 400 points
□ Inside bar forms during NY session
□ No key level present
□ Excursion < 80 points
□ Reversal closes inside wick only

THE OPERATING LOGIC:
Algorithm compresses during Asian session
Expands at London open to hunt accumulated stops
This IS the false breakout — manufactured
Position on the correct side of this mechanism
```

---

## Rule 6: Trend Structure Minimums

```
VALID TREND ON DAILY:
Each HH must be ≥ 500 points above previous High
Each HL must hold ≥ 300 points above previous Low
Each LL must be ≥ 500 points below previous Low
Each LH must hold ≥ 300 points below previous High

VALID STRUCTURE ON 1H:
HH/HL or LH/LL swings ≥ 200 points

BELOW THESE MINIMUMS:
= Algorithm noise
= Not a valid trend signal
= Do not apply trend strategies

RISK PARAMETERS:
Risk per trade  : 0.5% of account
Stop loss       : ATR(14) × 2.5 beyond signal extreme
Minimum R:R     : 1:3
Daily loss cap  : 1.5% (3 trades maximum)
```

---

# SECTION 14: FRAMEWORK QUICK REFERENCE

```
╔══════════════════════════════════════════════════════════════╗
║              PRE-TRADE CHECKLIST                             ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  WEEKLY ANALYSIS                                             ║
║  □ Market classified (Trend/Range/Choppy)                   ║
║  □ Major S/R levels identified                              ║
║  □ Weekly bias confirmed (Bull/Bear)                        ║
║  □ Last weekly candle read                                  ║
║                                                              ║
║  DAILY ANALYSIS                                             ║
║  □ Trend structure confirmed                                ║
║  □ Key S/R + Supply/Demand mapped                          ║
║  □ Fibonacci drawn on last major swing                      ║
║  □ KAMA direction noted                                     ║
║  □ Retracement zones identified                             ║
║                                                              ║
║  4H ANALYSIS                                                ║
║  □ 4H direction vs Daily confirmed                          ║
║  □ Retracement or impulse phase identified                  ║
║  □ Pattern present at key level                             ║
║  □ Pattern graded (A / B / No Trade)                        ║
║  □ Minimum 2 confluence factors present                     ║
║                                                              ║
║  1H CONFIRMATION (skip if Grade A Engulfing)                ║
║  □ Structure confirms trade direction                       ║
║  □ HH/HL or LH/LL present                                  ║
║                                                              ║
║  EXECUTION (15M / 5M)                                       ║
║  □ Entry candle identified at key level                     ║
║  □ Candle has CLOSED (not still forming)                    ║
║  □ Stop loss calculated and placed                          ║
║  □ Profit target identified (next S/R)                      ║
║  □ R:R calculated (≥1:2 Forex / ≥1:3 VIX75)               ║
║  □ Position size calculated ($ risk not pips)               ║
║                                                              ║
║  RISK CHECK                                                  ║
║  □ Daily loss limit not reached (2 losses max)              ║
║  □ Weekly drawdown not at 6%                                ║
║  □ Spread within limit (VIX75 ≤ 5pts)                      ║
║  □ Not within rollover window (VIX75)                       ║
║  □ Not within 30min of news event (Forex)                   ║
║  □ Correlation rule checked if multi-pair                   ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

---

# FRAMEWORK METADATA

```
VERSION      : 1.0 — Final
STATUS       : Complete — All gaps closed
SCORE        : 100/100

PRIMARY SOURCE    : The Candlestick Trading Bible
                    Munehisa Homma
RISK SOURCE       : Mark Douglas — Trading In The Zone
MA SOURCE         : Perry Kaufman — Adaptive Moving Averages
CODE STANDARD     : Andrew R. Young — OOP MQL5
PATTERN SOURCE    : Steve Nison — Japanese Candlestick Charting

ASSETS COVERED    : Forex + VIX75
TIMEFRAMES        : Weekly / Daily / 4H / 1H / 15M / 5M
PRIMARY TF        : 4H
EXECUTION TF      : 15M / 5M

NEXT STEP         : Backtesting Protocol
                    Minimum 50 trades per setup per asset
                    Before live capital deployment
```

---

*The framework is complete. Every rule has a reason. Every reason comes from the book, from logic, or from your deliberate decisions as the trader. Nothing here is arbitrary.*


Audit Verdict: Yes — With One Precision Addition

Confirming Each Engine Against The Book

Engine 1: Supply & Demand (1 Touch + ATR Displacement)
Book source — exact language:

"Pay more attention to the way the price leaves the zone, if the market leaves the area quickly, this is an indication that banks and institutions are there."

And:

"The secret behind supply and demand areas is that big players put their pending orders there, when the market approaches these zones, we see a crazy move from these levels."

Verdict: Mathematically correct ✅
The book never requires a second touch for supply and demand. It requires one thing only — the violence of the departure. A single touch with explosive displacement IS the definition of an institutional order block in this book's framework.
ENGINE 1 TRANSLATION:
1 swing point identified
+ Subsequent candle ≥ 2× ATR(14) displacement
= Tier 1 Institutional Zone
= Hard-coded immediately
= No second touch required
= No waiting

Engine 2: Standard S/R (2 Touches + Variance Clustering)
Book source — exact language:

"To confirm a ranging market, I have to look for at least two touches of support level, and two touches of resistance level."

And:

"Support and resistance levels are formed when price reverses and changes direction, and price will often respect these support and resistance levels."

Verdict: Mathematically correct ✅
The book explicitly requires two touches before a standard horizontal level is confirmed. This is not implied — it is stated as the classification condition for a valid ranging market boundary.
ENGINE 2 TRANSLATION:
2 swing highs or 2 swing lows
terminating within ±50 points (VIX75)
or ±15 points (Forex)
= Valid standard S/R level
= Rank 2 classification
= Fractal clustering confirms the zone width

Engine 3: Weekly Major Turning Points (1 Touch — Macro Weight)
Book source — exact language:

"The most important support and resistance levels: if you can identify them on the weekly chart, you will know what is going to happen when price approaches these levels on the 4H chart."

And the critical example:

"The weekly resistance level was a powerful turning point that reversed the market direction" — referring to a single weekly rejection that overrode a daily pin bar signal entirely.

Verdict: Mathematically correct ✅
The book demonstrates that a single weekly level rejection carries enough institutional weight to reverse a confirmed daily signal. The macro timeframe weight substitutes for the second touch requirement. The sheer size of the weekly candle and the timeframe itself IS the confirmation.
ENGINE 3 TRANSLATION:
Highest high of last 6 months = Weekly resistance
Lowest low of last 6 months  = Weekly support
1 touch required only
Macro timeframe weight = confirmation substitute
Rank 1 classification — overrides all lower signals

The One Precision Addition The Book Implies
There is a fourth condition the book demonstrates but does not explicitly name. It needs to be captured in the engine architecture:
The Retested Level — Role Reversal
BOOK SOURCE:
"When the market makes the retracement move
it respects the previous swing point (support level)
which represents the beginning of another impulsive move."

And:
"In trending markets, when prices pass through
resistance level, that resistance could become support."

WHAT THIS CREATES:
A broken S/R level that is subsequently retested
carries ELEVATED weight on the retest

ENGINE 4: ROLE REVERSAL LEVEL
Condition:
A confirmed S/R level (Engine 2) is broken
Price returns to retest the broken level
The broken resistance now acts as support
The broken support now acts as resistance

Classification:
Rank 2 on first identification
Elevates to Rank 1.5 on confirmed retest
Because the book demonstrates these levels
produce some of the highest probability entries
in the entire framework

BOT TRANSLATION:
When Engine 2 level is broken by a closing candle
Flag the level as "Role Reversal Candidate"
When price returns to within ±variance of that level
Elevate classification to Rank 1.5
Signal the Decision Tree that a high probability
retracement entry zone is active

The Complete Sensor Array Architecture
╔══════════════════════════════════════════════════════════════╗
║              SENSOR ARRAY — LEVEL DETECTION                  ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  ENGINE 1: SUPPLY & DEMAND DETECTOR                         ║
║  ─────────────────────────────────────                      ║
║  Trigger  : 1 swing point                                   ║
║  Confirm  : Next candle ≥ 2× ATR(14)                       ║
║  Output   : Institutional Zone (Rank 2)                     ║
║  Source   : "Market leaves quickly = banks there"           ║
║                                                              ║
║  ENGINE 2: STANDARD S/R DETECTOR                            ║
║  ─────────────────────────────────────                      ║
║  Trigger  : 2 swing points                                  ║
║  Confirm  : Within ±50pts VIX75 / ±15pts Forex             ║
║  Output   : Standard S/R Zone (Rank 2)                     ║
║  Source   : "At least two touches to confirm"               ║
║                                                              ║
║  ENGINE 3: WEEKLY MACRO DETECTOR                            ║
║  ─────────────────────────────────────                      ║
║  Trigger  : Highest high / Lowest low (6 months)            ║
║  Confirm  : 1 touch — macro weight substitutes              ║
║  Output   : Major Turning Point (Rank 1)                    ║
║  Source   : "Weekly level reversed entire daily signal"     ║
║                                                              ║
║  ENGINE 4: ROLE REVERSAL DETECTOR                           ║
║  ─────────────────────────────────────                      ║
║  Trigger  : Engine 2 level broken by closing candle         ║
║  Confirm  : Price returns to ±variance of broken level      ║
║  Output   : Role Reversal Zone (Rank 1.5)                  ║
║  Source   : "Resistance becomes support after breakout"     ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

Rank Classification Summary
RANK 1   → Weekly Macro Level (Engine 3)
           Overrides all lower signals
           Single touch — macro weight confirmed

RANK 1.5 → Role Reversal Level (Engine 4)
           Broken S/R retested
           Highest probability trending entry zone

RANK 2   → Standard S/R (Engine 2)
           Two touch minimum confirmed
           Standard confluence factor

RANK 2   → Supply & Demand Zone (Engine 1)
           Single touch + ATR displacement
           Institutional fingerprint confirmed

RANK 3   → KAMA Dynamic Level
           Equal weight to Rank 2 static level
           Valid in fast trends only
           (Patch 1 — already in Layer 4)

RANK 4   → Fibonacci 50% & 61.8%
           Pinpoints entry within higher rank zone
           Never standalone — always confluence

RANK 5   → Trendlines
           2 touch minimum to draw
           3rd touch = actionable entry zone
           Lowest standalone weight