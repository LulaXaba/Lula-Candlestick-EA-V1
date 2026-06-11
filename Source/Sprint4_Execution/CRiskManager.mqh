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
   // --- 1. Calculate the exact dollar amount we are willing to lose ---
   double balance    = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * (m_risk_per_trade_pct / 100.0);

   // --- 2. Fetch broker volume constraints ---
   double minLot     = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
   double maxLot     = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
   double volumeStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);

   if(entry_price <= 0 || stop_loss <= 0) return 0.0;

   // --- 3. Determine order type from entry vs stop loss direction ---
   ENUM_ORDER_TYPE orderType = (entry_price > stop_loss) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

   // --- 4. Ask the MT5 native engine: how much does 1.00 Lot lose between entry and SL? ---
   // This bypasses the Strategy Tester's broken SYMBOL_TRADE_TICK_VALUE for synthetic indices.
   // OrderCalcProfit() uses the terminal's internal margin/profit engine — identical on live,
   // demo, and Strategy Tester — guaranteeing correct scaling for VIX75 and all synthetics.
   double simulatedProfit = 0.0;
   bool   success = OrderCalcProfit(orderType, m_symbol, 1.0, entry_price, stop_loss, simulatedProfit);

   if(!success || simulatedProfit >= 0)
     {
      PrintFormat("[Risk Manager] OrderCalcProfit failed or returned non-negative (%.2f). Defaulting to MinLot.", simulatedProfit);
      return minLot;
     }

   // simulatedProfit is a negative number (e.g., -2970.00). Convert to absolute loss per 1 lot.
   double moneyLostPerStandardLot = MathAbs(simulatedProfit);

   if(moneyLostPerStandardLot <= 0) return minLot;

   // --- 5. Back-calculate the exact lots needed to lose exactly riskAmount ---
   double rawLots = riskAmount / moneyLostPerStandardLot;

   // --- 6. Normalize to broker's volume step.
   // MathFloor (not MathRound) guarantees we never exceed our intended risk dollar amount.
   double normalizedLots = MathFloor(rawLots / volumeStep) * volumeStep;

   // --- 7. Clamp final value to broker min/max limits ---
   normalizedLots = MathMax(minLot, MathMin(normalizedLots, maxLot));

   PrintFormat("[Risk Manager] Lot Calc: Balance=%.2f | Risk=%.2f | 1Lot Loss=%.2f | Raw=%.4f | Final=%.3f",
               balance, riskAmount, moneyLostPerStandardLot, rawLots, normalizedLots);

   return NormalizeDouble(normalizedLots, 3);
  }

#endif
