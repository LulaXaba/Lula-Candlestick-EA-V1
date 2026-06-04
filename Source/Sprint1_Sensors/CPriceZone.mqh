//+------------------------------------------------------------------+
/// @file    CPriceZone.mqh
/// @brief   Atomic price zone container — stores boundaries, rank,
///          type, and proximity state for a single S/D or S/R level.
/// @author  Lula Engineering Team
/// @version 1.1.0
//+------------------------------------------------------------------+
#ifndef CPRICEZONE_MQH
#define CPRICEZONE_MQH

#include "..\Include\Defines.mqh"

class CPriceZone
  {
private:
   double            m_upper_bound;
   double            m_lower_bound;
   ENUM_ZONE_TYPE    m_type;
   ENUM_ZONE_RANK    m_rank;
   int               m_touch_count;
   bool              m_is_active;
   datetime          m_time_formed;
   bool              m_is_broken;
   datetime          m_break_time;

public:
                     CPriceZone();
                    ~CPriceZone();

   //--- Safe Mutators
   void              SetZoneLimits(double upper, double lower);
   void              SetRankAndType(ENUM_ZONE_RANK rank, ENUM_ZONE_TYPE type);
   void              IncrementTouchCount() { m_touch_count++; }
   void              ForceTouchCount(int count) { m_touch_count = count; }
   void              BreakZone(datetime break_time);
   void              ValidateRetest();

   //--- Safe Accessors
   double            GetUpperBound()   const { return m_upper_bound; }
   double            GetLowerBound()   const { return m_lower_bound; }
   ENUM_ZONE_RANK    GetRank()         const { return m_rank; }
   ENUM_ZONE_TYPE    GetType()         const { return m_type; }
   int               GetTouchCount()   const { return m_touch_count; }
   
   // A zone is only active if it hasn't been broken (or if it was validated and reactivated)
   bool              IsActive()        const { return m_is_active && !m_is_broken; }
   bool              IsBroken()        const { return m_is_broken; }
   datetime          GetBreakTime()    const { return m_break_time; }
   datetime          GetTimeFormed()   const { return m_time_formed; }

   //--- Read-Only Execution Evaluator
   bool              IsPriceInsideZone(double price) const;
  };

CPriceZone::CPriceZone() : m_upper_bound(0), m_lower_bound(0), m_type(ZONE_STANDARD_SR),
                           m_rank(RANK_STANDARD), m_touch_count(1), m_is_active(true),
                           m_time_formed(TimeCurrent()), m_is_broken(false), m_break_time(0) {}

CPriceZone::~CPriceZone() {}

void CPriceZone::SetZoneLimits(double upper, double lower)
  {
   m_upper_bound = MathMax(upper, lower);
   m_lower_bound = MathMin(upper, lower);
  }

void CPriceZone::SetRankAndType(ENUM_ZONE_RANK rank, ENUM_ZONE_TYPE type)
  {
   m_rank = rank;
   m_type = type;
  }

void CPriceZone::BreakZone(datetime break_time)
  {
   m_is_active  = false;
   m_is_broken  = true;
   m_break_time = break_time;
  }

void CPriceZone::ValidateRetest()
  {
   m_is_active  = true;
   m_is_broken  = false;
   m_rank       = RANK_1_5_HIGH;
   m_type       = ZONE_ROLE_REVERSAL;
  }

bool CPriceZone::IsPriceInsideZone(double price) const
  {
   if(!IsActive()) return false;
   return (price <= m_upper_bound && price >= m_lower_bound);
  }

#endif
