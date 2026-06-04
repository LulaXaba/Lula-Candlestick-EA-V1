//+------------------------------------------------------------------+
//|  CEngine2_StandardSR.mqh — Engine 2: Standard S/R Levels         |
//|  Sprint 1: The Sensor Array                                      |
//|                                                                  |
//|  Responsibility: Fractal Clustering Algorithm. Groups raw swings |
//|  into valid S/R zones using a defined variance and 2-touch rule. |
//+------------------------------------------------------------------+
#ifndef CENGINE2_STANDARDSR_MQH
#define CENGINE2_STANDARDSR_MQH

#include "../../Include/Defines.mqh"
#include "../CPriceZone.mqh"
#include "../C_SwingDetector.mqh"

class CEngine2_StandardSR
{
private:
   // Nested struct to handle mathematical grouping before OOP conversion
   struct TemporaryCluster
   {
      double   centerPrice;
      double   upperBound;
      double   lowerBound;
      int      touchCount;
      bool     isSupply; // Helper flag to approximate ZONE_SUPPLY vs ZONE_DEMAND
   };

   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;

public:
                     CEngine2_StandardSR();
                    ~CEngine2_StandardSR();

   bool              Init(const string symbol, ENUM_TIMEFRAMES tf = PERIOD_CURRENT);
   void              Deinit();

   void              DetectZones(C_SwingDetector* swings, double variance_pts, int lookback_bars, CPriceZone* &out_zones[]);
};

CEngine2_StandardSR::CEngine2_StandardSR()
{
}

CEngine2_StandardSR::~CEngine2_StandardSR()
{
   Deinit();
}

bool CEngine2_StandardSR::Init(const string symbol, ENUM_TIMEFRAMES tf)
{
   m_symbol    = symbol;
   m_timeframe = tf;
   return true;
}

void CEngine2_StandardSR::Deinit()
{
}

void CEngine2_StandardSR::DetectZones(C_SwingDetector* swings, double variance_pts, int lookback_bars, CPriceZone* &out_zones[])
{
   if(swings == NULL) return;

   TemporaryCluster clusters[];
   ArrayResize(clusters, 0);

   // 1. Find Swings
   // ★ MODIFIED: [Framework Alignment] — Reversed loop direction to iterate from oldest to newest
   for(int i = lookback_bars; i >= 1; i--)
   {
      bool isHigh = swings.IsSwingHigh(i);
      bool isLow  = swings.IsSwingLow(i);

      if(!isHigh && !isLow) continue;

      double price = isHigh ? iHigh(m_symbol, m_timeframe, i) : iLow(m_symbol, m_timeframe, i);
      bool matched = false;

      // 2. Cluster Match
      for(int c = 0; c < ArraySize(clusters); c++)
      {
         if(MathAbs(price - clusters[c].centerPrice) <= variance_pts)
         {
            // 3. Merge: Expand bounds and increment touch count
            clusters[c].upperBound = MathMax(clusters[c].upperBound, price);
            clusters[c].lowerBound = MathMin(clusters[c].lowerBound, price);
            clusters[c].touchCount++;
            matched = true;
            break;
         }
      }

      // Create new cluster if no match
      if(!matched)
      {
         int size = ArraySize(clusters);
         ArrayResize(clusters, size + 1);
         clusters[size].centerPrice = price;
         clusters[size].upperBound  = price;
         clusters[size].lowerBound  = price;
         clusters[size].touchCount  = 1;
         clusters[size].isSupply    = isHigh;
      }
   }

   // 4. Filter and Create Zones
   for(int c = 0; c < ArraySize(clusters); c++)
   {
      // Enforce strict 2-touch minimum
      if(clusters[c].touchCount >= 2)
      {
         int outSize = ArraySize(out_zones);
         ArrayResize(out_zones, outSize + 1);
         
         out_zones[outSize] = new CPriceZone();
         out_zones[outSize].Init(m_symbol, lookback_bars);
         
         out_zones[outSize].SetZoneLimits(clusters[c].upperBound, clusters[c].lowerBound);
         
         // Rank: RANK_MINOR for 2-touch, RANK_MAJOR (2) for 3+ touches (Standard S/R weight)
         ENUM_ZONE_RANK rank = (clusters[c].touchCount >= 3) ? RANK_MAJOR : RANK_MINOR;
         ENUM_ZONE_TYPE type = clusters[c].isSupply ? ZONE_SUPPLY : ZONE_DEMAND;
         
         out_zones[outSize].SetRankAndType(rank, type);
      }
   }
}

#endif // CENGINE2_STANDARDSR_MQH
