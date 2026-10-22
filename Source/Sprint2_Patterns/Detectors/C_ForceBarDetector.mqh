//+------------------------------------------------------------------+
//|                                         C_ForceBarDetector.mqh   |
//|                             Lula Price Action Execution Engine V2|
//+------------------------------------------------------------------+
#ifndef C_FORCEBARDETECTOR_MQH
#define C_FORCEBARDETECTOR_MQH

#include "..\..\Include\Defines.mqh"
#include "..\..\Include\DTOs.mqh"
#include "..\..\Sprint1_Sensors\CSensorArray.mqh"
#include "..\CPatternResult.mqh"

class C_ForceBarDetector
  {
private:
   string            m_symbol;
   int               m_min_score;
   bool              m_verbose;

public:
                     C_ForceBarDetector();
                    ~C_ForceBarDetector();

   bool              Init(const string symbol, int min_score, bool verbose = false);
   bool              Detect(const int barIndex, CSensorArray* sensor, CPatternResult* result);
  };

C_ForceBarDetector::C_ForceBarDetector() : m_symbol(""), m_min_score(70), m_verbose(false) {}
C_ForceBarDetector::~C_ForceBarDetector() {}

bool C_ForceBarDetector::Init(const string symbol, int min_score, bool verbose)
  {
   m_symbol = symbol;
   m_min_score = min_score;
   m_verbose = verbose;
   return true;
  }

bool C_ForceBarDetector::Detect(const int barIndex, CSensorArray* sensor, CPatternResult* result)
  {
   if(barIndex < 1 || sensor == NULL || result == NULL) return false;

   double open  = iOpen(m_symbol, PERIOD_CURRENT, barIndex);
   double high  = iHigh(m_symbol, PERIOD_CURRENT, barIndex);
   double low   = iLow(m_symbol, PERIOD_CURRENT, barIndex);
   double close = iClose(m_symbol, PERIOD_CURRENT, barIndex);

   double range = MathAbs(high - low);
   double body  = MathAbs(open - close);

   if(range <= 0) return false; // Guard against divide by zero

   SSensorData sData = sensor.GetData(close);
   double atr = sData.atr_Current > 0 ? sData.atr_Current : 100 * _Point;

   SSymbolProfile prof = CSymbolProfile::Get(m_symbol);

   // 1. Evaluate Force Bar Math Parameters
   double bodyRatio = body / range;
   bool isSignificantSize = (range >= atr);                                // Must be at least 1x ATR
   bool isBodyDominant    = (bodyRatio) >= prof.forcebar_min_body_pct; // Profile-calibrated body ratio

   if(m_verbose)
     {
      if(isSignificantSize && isBodyDominant)
         PrintFormat("[DET FORCE] body/range=%.2f threshold=%.2f range=%.5f atr=%.5f -> HIT score=70",
                     bodyRatio, prof.forcebar_min_body_pct, range, atr);
      else
         PrintFormat("[DET FORCE] body/range=%.2f threshold=%.2f range=%.5f atr=%.5f sigSize=%s bodyDom=%s -> MISS",
                     bodyRatio, prof.forcebar_min_body_pct, range, atr,
                     isSignificantSize ? "Y" : "N", isBodyDominant ? "Y" : "N");
     }

   if(!isSignificantSize || !isBodyDominant) return false;

   // 2. Identify Direction
   bool isBullishForce = (close > open);
   bool isBearishForce = (close < open);

   // 3. Fetch Market Context & Score
   int score = 70; // Base confidence score

   // Scoring Gate 1: Zone Confluence (Force bars originating AT a zone are highly valid)
   if(isBullishForce && sData.isAtDemandZone) score += ZONE_CONFLUENCE_BONUS;
   if(isBearishForce && sData.isAtSupplyZone) score += ZONE_CONFLUENCE_BONUS;

   // Scoring Gate 2: Direction Alignment (Macro Bias)
   if(isBullishForce && sData.weeklyBias == BIAS_BULLISH) score += 10;
   if(isBearishForce && sData.weeklyBias == BIAS_BEARISH) score += 10;

   // Extra Institutional Boost: If the Force bar is >= 2.0x ATR, it's an extreme displacement
   bool isExtremeDisplacement = (range >= (2.0 * atr));
   if(isExtremeDisplacement) score += 10;

   // Validation Gate
   if(score < m_min_score)
     {
      if(m_verbose) PrintFormat("[DET FORCE] score=%d < min=%d -> REJECT", score, m_min_score);
      return false;
     }

   // 4. Determine Grade
   // An extreme displacement force bar bypasses 1H checks because the momentum is overwhelming
   ENUM_CONFLUENCE_GRADE grade = isExtremeDisplacement ? GRADE_A : GRADE_B;
   bool bypass_1h = isExtremeDisplacement;

   // 5. Populate DTO Output
   ENUM_TRADE_DIRECTION dir = isBullishForce ? DIRECTION_LONG : DIRECTION_SHORT;
   double entry = close; 
   double sl = 0.0;

   // Stop Loss goes below/above the origin of the Force Bar, plus standard buffer
   if(isBullishForce)
     {
      sl = low - (atr * ATR_MULTIPLIER_NORMAL);
     }
   else
     {
      sl = high + (atr * ATR_MULTIPLIER_NORMAL);
     }

   // Note: Since we don't have a specific PATTERN_FORCE_BAR enum yet, we use PATTERN_ENGULFING 
   // conceptually, or we can add PATTERN_FORCE_BAR. Assuming we stick to the closest momentum pattern:
   result.SetPattern(PATTERN_ENGULFING, dir, grade, bypass_1h, entry, sl);

   return true;
  }

#endif
