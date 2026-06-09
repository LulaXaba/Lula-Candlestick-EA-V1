//+------------------------------------------------------------------+
//|                                        C_RetracementDetector.mqh |
//|                             Lula Price Action Execution Engine V1|
//+------------------------------------------------------------------+
#ifndef C_RETRACEMENTDETECTOR_MQH
#define C_RETRACEMENTDETECTOR_MQH

#include "..\Include\Defines.mqh"
#include "..\Include\DTOs.mqh"

class C_RetracementDetector
  {
private:
   string            m_symbol;

public:
                     C_RetracementDetector();
                    ~C_RetracementDetector();

   bool              Init(const string symbol);
   void              Deinit();
   
   void              Evaluate(const SSensorData &sensor_data, SMarketState &out_state);
  };

C_RetracementDetector::C_RetracementDetector() : m_symbol("") {}

C_RetracementDetector::~C_RetracementDetector()
  {
   Deinit();
  }

bool C_RetracementDetector::Init(const string symbol)
  {
   m_symbol = symbol;
   return true;
  }

void C_RetracementDetector::Deinit()
  {
   // No dynamic memory to release
  }

void C_RetracementDetector::Evaluate(const SSensorData &sensor_data, SMarketState &out_state)
  {
   // Retracement logic only applies if the market is locally trending.
   // We do not evaluate retracements in Choppy or Ranging markets.
   if(out_state.state != STATE_TRENDING_UP && out_state.state != STATE_TRENDING_DOWN)
      return;

   // Institutional Definition of a Retracement:
   // The localized (current timeframe) trend is moving AGAINST the Macro Bias.
   
   bool isBullishRetracement = (out_state.state == STATE_TRENDING_UP) && 
                               (sensor_data.weeklyBias == BIAS_BEARISH);
                               
   bool isBearishRetracement = (out_state.state == STATE_TRENDING_DOWN) && 
                               (sensor_data.weeklyBias == BIAS_BULLISH);

   if(isBullishRetracement || isBearishRetracement)
     {
      // Overwrite the local trend state with the Retracement Phase classification
      out_state.state = STATE_RETRACEMENT;
      
      // Optionally flag the implied direction of the pullback
      out_state.impliedDirection = isBullishRetracement ? DIRECTION_LONG : DIRECTION_SHORT;
     }
   else
     {
      // If the local trend aligns perfectly with the Macro bias, it is an IMPULSIVE move.
      out_state.impliedDirection = (out_state.state == STATE_TRENDING_UP) ? DIRECTION_LONG : DIRECTION_SHORT;
     }
  }

#endif
