//+------------------------------------------------------------------+
//|                                     C_FalseBreakoutDetector.mqh  |
//|                             Lula Price Action Execution Engine V1|
//+------------------------------------------------------------------+
#ifndef C_FALSEBREAKOUTDETECTOR_MQH
#define C_FALSEBREAKOUTDETECTOR_MQH

#include "..\..\Include\Defines.mqh"
#include "..\..\Include\DTOs.mqh"
#include "..\..\Sprint1_Sensors\CSensorArray.mqh"
#include "..\CPatternResult.mqh"

class C_FalseBreakoutDetector
  {
private:
   string            m_symbol;
   int               m_min_score;
   bool              m_is_vix75;

public:
                     C_FalseBreakoutDetector();
                    ~C_FalseBreakoutDetector();

   bool              Init(const string symbol, int min_score);
   bool              Detect(const int barIndex, CSensorArray* sensor, CPatternResult* result);
  };

C_FalseBreakoutDetector::C_FalseBreakoutDetector() : m_symbol(""), m_min_score(70), m_is_vix75(false) {}
C_FalseBreakoutDetector::~C_FalseBreakoutDetector() {}

bool C_FalseBreakoutDetector::Init(const string symbol, int min_score)
  {
   m_symbol = symbol;
   m_min_score = min_score;
   
   m_is_vix75 = (StringFind(m_symbol, "75") >= 0 || StringFind(m_symbol, "10") >= 0 || 
                 StringFind(m_symbol, "25") >= 0 || StringFind(m_symbol, "50") >= 0 || 
                 StringFind(m_symbol, "100") >= 0 || StringFind(m_symbol, "Step") >= 0);
                 
   return true;
  }

bool C_FalseBreakoutDetector::Detect(const int barIndex, CSensorArray* sensor, CPatternResult* result)
  {
   if(barIndex < 1 || sensor == NULL || result == NULL) return false;

   double open  = iOpen(m_symbol, PERIOD_CURRENT, barIndex);
   double high  = iHigh(m_symbol, PERIOD_CURRENT, barIndex);
   double low   = iLow(m_symbol, PERIOD_CURRENT, barIndex);
   double close = iClose(m_symbol, PERIOD_CURRENT, barIndex);

   // To find a false breakout, we must check if the extremes (High/Low) pierced a zone
   SSensorData dataHigh = sensor.GetData(high);
   SSensorData dataLow  = sensor.GetData(low);
   SSensorData dataClose= sensor.GetData(close);

   double atr = dataClose.atr_Current > 0 ? dataClose.atr_Current : 100 * _Point;

   // Institutional Penetration Standards
   double penetration_threshold = m_is_vix75 ? (atr * 0.10) : (atr * 0.05);

   bool isBullishFBO = false;
   bool isBearishFBO = false;
   double sl = 0.0;

   // 1. Check Bullish False Breakout (Swept Support/Demand)
   if(dataLow.zoneRank >= RANK_MINOR && (dataLow.isAtDemandZone || dataLow.zoneRank >= RANK_STANDARD))
     {
      double zoneLow = dataLow.zoneLow;
      double penetration = zoneLow - low;
      
      // Wick went below zone, penetrated enough to sweep stops, but closed back inside or above the zone boundary
      if(low < zoneLow && penetration >= penetration_threshold && close > zoneLow)
        {
         isBullishFBO = true;
         sl = low - (atr * ATR_MULTIPLIER_NORMAL); // Stop loss below the sweep wick
        }
     }

   // 2. Check Bearish False Breakout (Swept Resistance/Supply)
   if(!isBullishFBO && dataHigh.zoneRank >= RANK_MINOR && (dataHigh.isAtSupplyZone || dataHigh.zoneRank >= RANK_STANDARD))
     {
      double zoneHigh = dataHigh.zoneHigh;
      double penetration = high - zoneHigh;
      
      // Wick went above zone, penetrated enough to sweep stops, but closed back inside or below the zone boundary
      if(high > zoneHigh && penetration >= penetration_threshold && close < zoneHigh)
        {
         isBearishFBO = true;
         sl = high + (atr * ATR_MULTIPLIER_NORMAL); // Stop loss above the sweep wick
        }
     }

   if(!isBullishFBO && !isBearishFBO) return false;

   // 3. Score the Setup
   // False Breakouts are inherently high-probability because liquidity was already taken.
   int score = 75; // Base score is higher than standard patterns

   // Alignment with Macro Bias
   if(isBullishFBO && dataClose.weeklyBias == BIAS_BULLISH) score += 15;
   if(isBearishFBO && dataClose.weeklyBias == BIAS_BEARISH) score += 15;

   // Validation Gate
   if(score < m_min_score) return false;

   // 4. Populate DTO Output
   ENUM_TRADE_DIRECTION dir = isBullishFBO ? DIRECTION_LONG : DIRECTION_SHORT;
   double entry = close; 
   
   // False breakouts trigger the Grade A bypass (especially on VIX75) as they are trap patterns
   result.SetPattern(PATTERN_FALSE_BREAKOUT, dir, GRADE_A, true, entry, sl);
   
   return true;
  }

#endif
