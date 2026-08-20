//+------------------------------------------------------------------+
//|                                               CPatternResult.mqh |
//|                             Lula Price Action Execution Engine V1|
//+------------------------------------------------------------------+
#ifndef CPATTERNRESULT_MQH
#define CPATTERNRESULT_MQH

#include "..\Include\Defines.mqh"

//--- Pattern Grade Classification removed (now uses ENUM_CONFLUENCE_GRADE from Defines.mqh)

class CPatternResult
  {
private:
   ENUM_PATTERN_TYPE    m_type;
   ENUM_TRADE_DIRECTION m_direction;
   ENUM_CONFLUENCE_GRADE   m_grade;
   bool                 m_bypass_1h;
   double               m_entry_price;
   double               m_stop_loss;

public:
                        CPatternResult();
                       ~CPatternResult();

   //--- Mutators
   void                 SetPattern(ENUM_PATTERN_TYPE type, ENUM_TRADE_DIRECTION dir,
                                   ENUM_CONFLUENCE_GRADE grade, bool bypass,
                                   double entry, double sl);
   void                 Clear();

   //--- Accessors
   ENUM_PATTERN_TYPE    GetType() const       { return m_type; }
   ENUM_TRADE_DIRECTION GetDirection() const  { return m_direction; }
   ENUM_CONFLUENCE_GRADE   GetGrade() const      { return m_grade; }
   bool                 IsBypass1H() const    { return m_bypass_1h; }
   double               GetEntryPrice() const { return m_entry_price; }
   double               GetStopLoss() const   { return m_stop_loss; }

   //--- Validation
   bool                 IsValid() const       { return m_type != PATTERN_NONE; }
  };

CPatternResult::CPatternResult()
  {
   Clear();
  }

CPatternResult::~CPatternResult() {}

void CPatternResult::SetPattern(ENUM_PATTERN_TYPE type, ENUM_TRADE_DIRECTION dir,
                                ENUM_CONFLUENCE_GRADE grade, bool bypass, double entry, double sl)
  {
   m_type        = type;
   m_direction   = dir;
   m_grade       = grade;
   m_bypass_1h   = bypass;
   m_entry_price = entry;
   m_stop_loss   = sl;
  }

void CPatternResult::Clear()
  {
   m_type        = PATTERN_NONE;
   m_direction   = DIRECTION_NONE;
   m_grade       = GRADE_REJECT;
   m_bypass_1h   = false;
   m_entry_price = 0.0;
   m_stop_loss   = 0.0;
  }

#endif
