//+------------------------------------------------------------------+
//|                                              C_TrendAnalyzer.mqh |
//|                             Lula Price Action Execution Engine V1|
//+------------------------------------------------------------------+
#ifndef C_TRENDANALYZER_MQH
#define C_TRENDANALYZER_MQH

#include "..\Include\Defines.mqh"
#include "..\Include\DTOs.mqh"
#include "..\Sprint1_Sensors\C_SwingDetector.mqh"

class C_TrendAnalyzer
  {
private:
   string            m_symbol;
   C_SwingDetector* m_swings;

   int               GetStructureDirection();

public:
                     C_TrendAnalyzer();
                    ~C_TrendAnalyzer();

   bool              Init(const string symbol);
   void              Deinit();
   
   void              Evaluate(const SSensorData &sensor_data, SMarketState &out_state);
  };

C_TrendAnalyzer::C_TrendAnalyzer() : m_symbol(""), m_swings(NULL) {}

C_TrendAnalyzer::~C_TrendAnalyzer()
  {
   Deinit();
  }

bool C_TrendAnalyzer::Init(const string symbol)
  {
   m_symbol = symbol;
   
   // Instantiate a localized swing detector (L=3, R=3) to read market structure
   m_swings = new C_SwingDetector(3, 3, PERIOD_CURRENT);
   m_swings.Init(m_symbol);
   
   return true;
  }

void C_TrendAnalyzer::Deinit()
  {
   if(m_swings != NULL)
     {
      delete m_swings;
      m_swings = NULL;
     }
  }

// Returns 1 for Bullish Structure (HH, HL), -1 for Bearish Structure (LH, LL), 0 for Mixed
int C_TrendAnalyzer::GetStructureDirection()
  {
   double sh1 = 0.0, sh2 = 0.0; // Swing Highs (1 is newest, 2 is older)
   double sl1 = 0.0, sl2 = 0.0; // Swing Lows (1 is newest, 2 is older)
   
   int hCount = 0, lCount = 0;
   
   // Scan backward to find the last 2 confirmed swing points of each type
   for(int i = 1; i < 200 && (hCount < 2 || lCount < 2); i++)
     {
      if(hCount < 2 && m_swings.IsSwingHigh(i))
        {
         if(hCount == 0) sh1 = iHigh(m_symbol, PERIOD_CURRENT, i);
         else            sh2 = iHigh(m_symbol, PERIOD_CURRENT, i);
         hCount++;
        }
        
      if(lCount < 2 && m_swings.IsSwingLow(i))
        {
         if(lCount == 0) sl1 = iLow(m_symbol, PERIOD_CURRENT, i);
         else            sl2 = iLow(m_symbol, PERIOD_CURRENT, i);
         lCount++;
        }
     }
     
   if(hCount < 2 || lCount < 2) return 0; // Insufficient data to define structure
   
   bool isHigherHigh = (sh1 > sh2);
   bool isHigherLow  = (sl1 > sl2);
   bool isLowerHigh  = (sh1 < sh2);
   bool isLowerLow   = (sl1 < sl2);
   
   if(isHigherHigh && isHigherLow) return 1;  // Bullish Order Flow
   if(isLowerHigh && isLowerLow)   return -1; // Bearish Order Flow
   
   return 0; // Mixed / Consolidation
  }

void C_TrendAnalyzer::Evaluate(const SSensorData &sensor_data, SMarketState &out_state)
  {
   // If the market is already flagged as choppy, we do not define a trend.
   if(out_state.state == STATE_CHOPPY) return;

   int structure_dir = GetStructureDirection();
   double close = iClose(m_symbol, PERIOD_CURRENT, 1);
   
   // Check Dynamic Momentum (Price relative to KAMA baseline)
   bool kama_bullish = (sensor_data.kama > 0 && close > sensor_data.kama);
   bool kama_bearish = (sensor_data.kama > 0 && close < sensor_data.kama);
   
   // Institutional Trend Confluence: Structure MUST align with Dynamic Momentum
   if(structure_dir == 1 && kama_bullish)
     {
      out_state.state = STATE_TRENDING_UP;
     }
   else if(structure_dir == -1 && kama_bearish)
     {
      out_state.state = STATE_TRENDING_DOWN;
     }
  }

#endif
