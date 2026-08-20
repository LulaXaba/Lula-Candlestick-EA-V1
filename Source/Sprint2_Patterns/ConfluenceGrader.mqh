//+------------------------------------------------------------------+
//| ConfluenceGrader.mqh                                             |
//| V2: Grades trade setups based on the 3-Layer Confluence Model    |
//+------------------------------------------------------------------+
#ifndef CONFLUENCEGRADER_MQH
#define CONFLUENCEGRADER_MQH

#include "..\Include\DTOs.mqh"

class ConfluenceGrader
{
public:
   static ENUM_CONFLUENCE_GRADE Grade(const SPatternResult &pattern, const SSensorData &context)
   {
      // MANDATORY GATE 0: Trend must match trade direction
      if(pattern.direction == DIRECTION_LONG && context.trendState != TREND_UPTREND)
         return GRADE_REJECT;
      if(pattern.direction == DIRECTION_SHORT && context.trendState != TREND_DOWNTREND)
         return GRADE_REJECT;
         
      // Only THEN check confluence layers
      bool hasZone = false;
      if(pattern.direction == DIRECTION_LONG && context.isAtDemandZone) hasZone = true;
      if(pattern.direction == DIRECTION_SHORT && context.isAtSupplyZone) hasZone = true;
      
      bool atKAMA = false;
      if(context.kama > 0)
      {
         double dist = MathAbs(pattern.entryPrice - context.kama);
         if(dist < 50.0 * _Point) atKAMA = true;
      }
      
      // Grade based on exact overlap
      if(hasZone && atKAMA) return GRADE_A_PLUS;
      if(hasZone && !atKAMA) return GRADE_A;
      if(!hasZone && atKAMA) return GRADE_B;
      
      // If we only have ZigZag and no other confluence, we return GRADE_C per the spec
      if(!hasZone && !atKAMA) return GRADE_C;
      
      return GRADE_REJECT;
   }
};

#endif // CONFLUENCEGRADER_MQH
