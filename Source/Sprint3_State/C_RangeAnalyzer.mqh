//+------------------------------------------------------------------+
//|                                              C_RangeAnalyzer.mqh |
//|                             Lula Price Action Execution Engine V1|
//+------------------------------------------------------------------+
#ifndef C_RANGEANALYZER_MQH
#define C_RANGEANALYZER_MQH

#include "..\Include\Defines.mqh"
#include "..\Include\DTOs.mqh"

class C_RangeAnalyzer
  {
private:
   string            m_symbol;
   double            m_min_atr_multiplier;
   double            m_max_atr_multiplier;

public:
                     C_RangeAnalyzer();
                    ~C_RangeAnalyzer();

   bool              Init(const string symbol, double min_atr = 1.5, double max_atr = 4.0);
   void              Deinit();
   
   bool              Evaluate(const SSensorData &sensor_data, SMarketState &out_state);
  };

C_RangeAnalyzer::C_RangeAnalyzer() : m_symbol(""), m_min_atr_multiplier(1.5), m_max_atr_multiplier(4.0) {}

C_RangeAnalyzer::~C_RangeAnalyzer()
  {
   Deinit();
  }

bool C_RangeAnalyzer::Init(const string symbol, double min_atr, double max_atr)
  {
   m_symbol = symbol;
   m_min_atr_multiplier = min_atr;
   m_max_atr_multiplier = max_atr;
   return true;
  }

void C_RangeAnalyzer::Deinit()
  {
   // No dynamic pointers to clean up in this specific class
  }

bool C_RangeAnalyzer::Evaluate(const SSensorData &sensor_data, SMarketState &out_state)
  {
   // If the market is already flagged as choppy, we do not evaluate ranging.
   if(out_state.state == STATE_CHOPPY) return false;

   // FIXED: Use the correct variable names from SSensorData (zoneHigh/zoneLow, not nearestSupply/nearestDemand)
   double supply = sensor_data.zoneHigh;
   double demand = sensor_data.zoneLow;
   
   // If we don't have a defined ceiling and floor, we cannot be in a defined range
   if(supply <= 0 || demand <= 0) return false;
   
   double range_distance = supply - demand;
   if(range_distance <= 0) return false; // Sanity check

   double atr = sensor_data.atr_Current > 0 ? sensor_data.atr_Current : 100 * _Point;

   // 1. Evaluate Range Bounds (Too tight = Chop, Too wide = Trend/Macro Structure)
   bool isWideEnough  = range_distance >= (atr * m_min_atr_multiplier);
   bool isTightEnough = range_distance <= (atr * m_max_atr_multiplier);

   if(!isWideEnough || !isTightEnough) return false;

   // 2. Evaluate Price Position
   double current_price = iClose(m_symbol, PERIOD_CURRENT, 0);
   
   // Price must actually be trapped INSIDE this structure to be ranging
   bool isTrapped = (current_price < supply) && (current_price > demand);
   
   if(isTrapped)
     {
      // Valid Accumulation/Distribution Phase
      out_state.state = STATE_RANGING;
      return true;
     }

   return false;
  }

#endif
