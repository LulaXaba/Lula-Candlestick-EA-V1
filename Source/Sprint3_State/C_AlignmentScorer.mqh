//+------------------------------------------------------------------+
//|                                           C_AlignmentScorer.mqh  |
//|                             Lula Price Action Execution Engine V1|
//+------------------------------------------------------------------+
#ifndef C_ALIGNMENTSCORER_MQH
#define C_ALIGNMENTSCORER_MQH

#include "..\Include\Defines.mqh"
#include "..\Include\DTOs.mqh"

class C_AlignmentScorer
  {
private:
   string            m_symbol;

public:
                     C_AlignmentScorer();
                    ~C_AlignmentScorer();

   bool              Init(const string symbol);
   void              Deinit();
   
   int               CalculateScore(const SSensorData &sensor_data);
  };

C_AlignmentScorer::C_AlignmentScorer() : m_symbol("") {}

C_AlignmentScorer::~C_AlignmentScorer()
  {
   Deinit();
  }

bool C_AlignmentScorer::Init(const string symbol)
  {
   m_symbol = symbol;
   return true;
  }

void C_AlignmentScorer::Deinit() {}

int C_AlignmentScorer::CalculateScore(const SSensorData &sensor_data)
  {
   int score = 0;

   // 1. Timeframe Alignment (Max 60 pts)
   // +20 if 4H aligns with Daily, +20 if Daily aligns with Weekly, +20 if all three align
   if(sensor_data.h4Bias == sensor_data.dailyBias) score += 20;
   if(sensor_data.dailyBias == sensor_data.weeklyBias) score += 20;
   if(sensor_data.h4Bias == sensor_data.weeklyBias) score += 20;

   // 2. Momentum Velocity (Max 40 pts)
   // We look at the KAMA relative to price and the macro bias.
   bool isBullishConfluence = (sensor_data.kamaSlope > 0) && (sensor_data.weeklyBias == BIAS_BULLISH);
   bool isBearishConfluence = (sensor_data.kamaSlope < 0) && (sensor_data.weeklyBias == BIAS_BEARISH);
   
   if(isBullishConfluence || isBearishConfluence)
     {
      score += 40;
     }

   return MathMin(score, 100);
  }

#endif
