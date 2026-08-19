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
      int confluenceCount = 0;
      
      // 1. Structure Check (Is it with the Trend?)
      if(pattern.direction == DIRECTION_LONG && context.trendState == TREND_UPTREND) confluenceCount++;
      if(pattern.direction == DIRECTION_SHORT && context.trendState == TREND_DOWNTREND) confluenceCount++;
      
      // 2. Zone Check (Is it at a major support/demand?)
      if(pattern.direction == DIRECTION_LONG && context.isAtDemandZone) confluenceCount++;
      if(pattern.direction == DIRECTION_SHORT && context.isAtSupplyZone) confluenceCount++;
      
      // 3. KAMA Check (Is entry near dynamic S/R?)
      if(context.kama > 0)
      {
         double dist = MathAbs(pattern.entryPrice - context.kama);
         // Dynamic variance threshold can be pulled from context.kamaVariance, simplified here:
         if(dist < 50.0 * _Point) confluenceCount++;
      }
      
      // Assign grade based on overlap
      if(confluenceCount == 3) return GRADE_A_PLUS;
      if(confluenceCount == 2) return GRADE_A;
      if(confluenceCount == 1) return GRADE_B;
      
      return GRADE_REJECT;
   }
};

#endif // CONFLUENCEGRADER_MQH
