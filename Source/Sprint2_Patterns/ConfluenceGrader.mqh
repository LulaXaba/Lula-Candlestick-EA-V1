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
      PrintFormat("[GRADER DEBUG] Direction=%s Trend=%s", 
                  EnumToString(pattern.direction), EnumToString(context.trendState));
                  
      // MANDATORY GATE 0: Trend must match trade direction
      if(pattern.direction == DIRECTION_LONG && context.trendState != TREND_UPTREND)
      {
         Print("[GRADER DEBUG] REJECT: Long but trend not UP");
         return GRADE_REJECT;
      }
      if(pattern.direction == DIRECTION_SHORT && context.trendState != TREND_DOWNTREND)
      {
         Print("[GRADER DEBUG] REJECT: Short but trend not DOWN");
         return GRADE_REJECT;
      }
          
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
      
      ENUM_CONFLUENCE_GRADE grade = GRADE_REJECT;
      // Grade based on exact overlap
      if(hasZone && atKAMA) grade = GRADE_A_PLUS;
      else if(hasZone && !atKAMA) grade = GRADE_A;
      else if(!hasZone && atKAMA) grade = GRADE_B;
      else if(!hasZone && !atKAMA) grade = GRADE_C;
      
      PrintFormat("[GRADER DEBUG] Grade=%s", EnumToString(grade));
      return grade;
   }
};

#endif // CONFLUENCEGRADER_MQH
