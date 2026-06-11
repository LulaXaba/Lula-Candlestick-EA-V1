//+------------------------------------------------------------------+
//|                                               CRiskManager.mqh   |
//|                             Lula Price Action Execution Engine V1|
//+------------------------------------------------------------------+
#ifndef CRISKMANAGER_MQH
#define CRISKMANAGER_MQH

#include "..\Include\Defines.mqh"
#include "..\Include\DTOs.mqh"

class CRiskManager
  {
private:
   string            m_symbol;
   double            m_risk_per_trade_pct;
   double            m_max_daily_dd_pct;
   double            m_max_total_dd_pct;
   double            m_min_rr_ratio;

   double            GetDailyProfit();

public:
                     CRiskManager();
                    ~CRiskManager();

   bool              Init(const string symbol, double risk_pct = 1.0, double max_daily_dd = 4.0, double max_total_dd = 6.0, double min_rr = 2.0);
   
   //--- Gate 6 & 7 Accessors
   double            GetMinRR() const { return m_min_rr_ratio; }
   bool              IsDrawdownSafe();
   
   //--- Execution Math
   double            CalculateLotSize(double entry_price, double stop_loss);
  };

CRiskManager::CRiskManager() : m_symbol(""), m_risk_per_trade_pct(1.0), m_max_daily_dd_pct(4.0), m_max_total_dd_pct(6.0), m_min_rr_ratio(2.0) {}
CRiskManager::~CRiskManager() {}

bool CRiskManager::Init(const string symbol, double risk_pct, double max_daily_dd, double max_total_dd, double min_rr)
  {
   m_symbol = symbol;
   m_risk_per_trade_pct = risk_pct;
   m_max_daily_dd_pct = max_daily_dd;
   m_max_total_dd_pct = max_total_dd;
   m_min_rr_ratio = min_rr;
   return true;
  }

double CRiskManager::GetDailyProfit()
  {
   // Define "today" starting at 00:00 broker time
   datetime current_time = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(current_time, dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime start_of_day = StructToTime(dt);

   double daily_profit = 0.0;
   
   if(HistorySelect(start_of_day, current_time))
     {
      int deals_total = HistoryDealsTotal();
      for(int i = 0; i < deals_total; i++)
        {
         ulong deal_ticket = HistoryDealGetTicket(i);
         if(deal_ticket > 0)
           {
            // Only count deals for this EA's symbol that actually closed positions
            if(HistoryDealGetString(deal_ticket, DEAL_SYMBOL) == m_symbol)
              {
               long entry_type = HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
               if(entry_type == DEAL_ENTRY_OUT || entry_type == DEAL_ENTRY_INOUT)
                 {
                  daily_profit += HistoryDealGetDouble(deal_ticket, DEAL_PROFIT);
                  daily_profit += HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION);
                  daily_profit += HistoryDealGetDouble(deal_ticket, DEAL_SWAP);
                 }
              }
           }
        }
     }
     
   // Also factor in the floating profit of currently open positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong pos_ticket = PositionGetTicket(i);
      if(PositionGetString(POSITION_SYMBOL) == m_symbol)
        {
         daily_profit += PositionGetDouble(POSITION_PROFIT);
         daily_profit += PositionGetDouble(POSITION_SWAP);
        }
     }
     
   return daily_profit;
  }

bool CRiskManager::IsDrawdownSafe()
  {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   
   // 1. Total Drawdown Check (Equity vs Balance)
   if(equity < balance)
     {
      double total_dd_pct = ((balance - equity) / balance) * 100.0;
      if(total_dd_pct >= m_max_total_dd_pct)
        {
         PrintFormat("[Risk Manager] TOTAL DRAWDOWN LIMIT REACHED: %.2f%%", total_dd_pct);
         return false;
        }
     }
     
   // 2. Margin Level Check (Must be safe if we have open positions)
   double margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   if(margin_level > 0 && margin_level < 200.0)
     {
      PrintFormat("[Risk Manager] MARGIN LEVEL TOO LOW: %.2f%%", margin_level);
      return false;
     }

   // 3. Daily Drawdown Check
   double daily_profit = GetDailyProfit();
   if(daily_profit < 0)
     {
      double daily_dd_pct = (MathAbs(daily_profit) / balance) * 100.0;
      if(daily_dd_pct >= m_max_daily_dd_pct)
        {
         PrintFormat("[Risk Manager] DAILY DRAWDOWN LIMIT REACHED: %.2f%%", daily_dd_pct);
         return false;
        }
     }

   return true;
  }

double CRiskManager::CalculateLotSize(double entry_price, double stop_loss)
  {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double risk_amount_currency = balance * (m_risk_per_trade_pct / 100.0);
   
   double tick_size  = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
   double tick_value = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
   
   if(tick_size <= 0 || tick_value <= 0 || entry_price <= 0 || stop_loss <= 0) return 0.0;
   
   // Calculate Stop Loss distance in ticks
   double sl_distance_points = MathAbs(entry_price - stop_loss);
   double loss_ticks = sl_distance_points / tick_size;
   
   if(loss_ticks <= 0) return 0.0;
   
   // Formula: Lot Size = Risk Amount / (Ticks * Tick Value)
   double raw_lot_size = risk_amount_currency / (loss_ticks * tick_value);
   
   // Normalize Lot Size to broker limits
   double min_lot  = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
   double max_lot  = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
   double lot_step = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
   
   // Round to nearest lot step
   double normalized_lot = MathRound(raw_lot_size / lot_step) * lot_step;
   
   // Clamp between min and max allowed
   normalized_lot = MathMax(min_lot, MathMin(normalized_lot, max_lot));
   
   return normalized_lot;
  }

#endif
