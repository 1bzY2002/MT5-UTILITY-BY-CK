//+------------------------------------------------------------------+
//|                                           TradeManager.mqh       |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//+------------------------------------------------------------------+
//| Trade Direction Enum                                             |
//+------------------------------------------------------------------+
enum ENUM_TRADE_DIRECTION
{
   TRADE_BOTH = 0,          // Both directions
   TRADE_LONG_ONLY = 1,     // Long only
   TRADE_SHORT_ONLY = 2     // Short only
};

//+------------------------------------------------------------------+
//| Lot Size Calculation Method                                      |
//+------------------------------------------------------------------+
enum ENUM_LOT_SIZE_METHOD
{
   LOT_FIXED = 0,           // Fixed lot size
   LOT_PERCENTAGE = 1,      // Percentage of account
   LOT_VOLATILITY = 2       // Volatility adjusted
};

//+------------------------------------------------------------------+
//| Stop Loss Calculation Method                                     |
//+------------------------------------------------------------------+
enum ENUM_SL_METHOD
{
   SL_FIXED_POINTS = 0,     // Fixed points
   SL_ATR = 1,              // ATR based
   SL_SWING_LEVELS = 2,     // Previous swing levels
   SL_PERCENTAGE = 3        // Percentage of price
};

//+------------------------------------------------------------------+
//| Take Profit Calculation Method                                   |
//+------------------------------------------------------------------+
enum ENUM_TP_METHOD
{
   TP_FIXED_POINTS = 0,     // Fixed points
   TP_RISK_REWARD = 1,      // Risk-reward ratio
   TP_STATISTICAL = 2,      // Statistical levels
   TP_ATR = 3               // ATR based
};

//+------------------------------------------------------------------+
//| Trade Information Structure                                       |
//+------------------------------------------------------------------+
struct TradeInfo
{
   ulong ticket;            // Order ticket
   datetime open_time;      // Open time
   double open_price;       // Open price
   double volume;           // Volume
   ENUM_ORDER_TYPE type;    // Order type
   double sl;               // Stop loss
   double tp;               // Take profit
   string comment;          // Comment
   double profit;           // Current profit
   bool modified;           // Has been modified
   datetime last_modify;    // Last modification time
};

//+------------------------------------------------------------------+
//| Trade Manager Class                                              |
//+------------------------------------------------------------------+
class CTradeManager
{
private:
   CTrade            m_trade;
   CPositionInfo     m_position;
   COrderInfo        m_order;
   
   // Trading settings
   ENUM_TRADE_DIRECTION m_trade_direction;
   double            m_max_spread;
   int               m_slippage;
   ulong             m_magic_number;
   
   // Risk management
   double            m_max_daily_loss;
   double            m_daily_loss;
   int               m_max_trades_per_day;
   int               m_trades_today;
   datetime          m_last_trade_date;
   
   // Lot sizing
   ENUM_LOT_SIZE_METHOD m_lot_method;
   double            m_fixed_lot;
   double            m_risk_percentage;
   
   // Arrays for tracking
   TradeInfo         m_open_trades[];
   
public:
   // Constructor
   CTradeManager(void);
   
   // Initialization
   bool Initialize(ulong magic_number);
   
   // Settings
   void SetTradeDirection(ENUM_TRADE_DIRECTION direction) { m_trade_direction = direction; }
   void SetMaxSpread(double spread) { m_max_spread = spread; }
   void SetSlippage(int slippage) { m_slippage = slippage; }
   void SetMaxDailyLoss(double loss) { m_max_daily_loss = loss; }
   void SetMaxTradesPerDay(int trades) { m_max_trades_per_day = trades; }
   void SetLotSizeMethod(ENUM_LOT_SIZE_METHOD method, double value);
   
   // Trade execution
   bool OpenBuyOrder(double price, double volume, double sl, double tp, string comment = "");
   bool OpenSellOrder(double price, double volume, double sl, double tp, string comment = "");
   bool ModifyPosition(ulong ticket, double sl, double tp);
   bool ClosePosition(ulong ticket, double volume = 0);
   bool CloseAllPositions(void);
   
   // Lot size calculation
   double CalculateLotSize(double entry_price, double sl_price, double risk_amount = 0);
   
   // Risk management
   bool CheckRiskLimits(void);
   bool CheckSpread(void);
   bool CheckTradingTime(void);
   
   // Position management
   void UpdateTradeInfo(void);
   int GetOpenPositionsCount(void);
   double GetTotalProfit(void);
   
   // Utility functions
   void ResetDailyCounters(void);
   bool IsNewTradingDay(void);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTradeManager::CTradeManager(void)
{
   m_trade_direction = TRADE_BOTH;
   m_max_spread = 3.0;
   m_slippage = 3;
   m_magic_number = 0;
   m_max_daily_loss = 1000.0;
   m_daily_loss = 0.0;
   m_max_trades_per_day = 10;
   m_trades_today = 0;
   m_last_trade_date = 0;
   m_lot_method = LOT_FIXED;
   m_fixed_lot = 0.1;
   m_risk_percentage = 2.0;
   
   ArrayResize(m_open_trades, 0);
}

//+------------------------------------------------------------------+
//| Initialize Trade Manager                                         |
//+------------------------------------------------------------------+
bool CTradeManager::Initialize(ulong magic_number)
{
   m_magic_number = magic_number;
   m_trade.SetExpertMagicNumber(magic_number);
   m_trade.SetDeviationInPoints(m_slippage);
   
   ResetDailyCounters();
   UpdateTradeInfo();
   
   return true;
}

//+------------------------------------------------------------------+
//| Set Lot Size Method                                              |
//+------------------------------------------------------------------+
void CTradeManager::SetLotSizeMethod(ENUM_LOT_SIZE_METHOD method, double value)
{
   m_lot_method = method;
   
   switch(method)
   {
      case LOT_FIXED:
         m_fixed_lot = value;
         break;
      case LOT_PERCENTAGE:
      case LOT_VOLATILITY:
         m_risk_percentage = value;
         break;
   }
}

//+------------------------------------------------------------------+
//| Open Buy Order                                                   |
//+------------------------------------------------------------------+
bool CTradeManager::OpenBuyOrder(double price, double volume, double sl, double tp, string comment = "")
{
   if(!CheckRiskLimits() || !CheckSpread() || !CheckTradingTime())
      return false;
      
   if(m_trade_direction == TRADE_SHORT_ONLY)
      return false;
   
   if(volume <= 0)
      volume = CalculateLotSize(price, sl);
   
   if(volume <= 0)
      return false;
   
   bool result = m_trade.Buy(volume, _Symbol, price, sl, tp, comment);
   
   if(result)
   {
      m_trades_today++;
      UpdateTradeInfo();
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| Open Sell Order                                                  |
//+------------------------------------------------------------------+
bool CTradeManager::OpenSellOrder(double price, double volume, double sl, double tp, string comment = "")
{
   if(!CheckRiskLimits() || !CheckSpread() || !CheckTradingTime())
      return false;
      
   if(m_trade_direction == TRADE_LONG_ONLY)
      return false;
   
   if(volume <= 0)
      volume = CalculateLotSize(price, sl);
   
   if(volume <= 0)
      return false;
   
   bool result = m_trade.Sell(volume, _Symbol, price, sl, tp, comment);
   
   if(result)
   {
      m_trades_today++;
      UpdateTradeInfo();
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| Modify Position                                                  |
//+------------------------------------------------------------------+
bool CTradeManager::ModifyPosition(ulong ticket, double sl, double tp)
{
   if(!m_position.SelectByTicket(ticket))
      return false;
   
   return m_trade.PositionModify(ticket, sl, tp);
}

//+------------------------------------------------------------------+
//| Close Position                                                   |
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(ulong ticket, double volume = 0)
{
   if(!m_position.SelectByTicket(ticket))
      return false;
   
   if(volume <= 0)
      volume = m_position.Volume();
   
   bool result = m_trade.PositionClose(ticket);
   
   if(result)
      UpdateTradeInfo();
   
   return result;
}

//+------------------------------------------------------------------+
//| Close All Positions                                             |
//+------------------------------------------------------------------+
bool CTradeManager::CloseAllPositions(void)
{
   bool all_closed = true;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == m_magic_number)
         {
            if(!m_trade.PositionClose(m_position.Ticket()))
               all_closed = false;
         }
      }
   }
   
   if(all_closed)
      UpdateTradeInfo();
   
   return all_closed;
}

//+------------------------------------------------------------------+
//| Calculate Lot Size                                               |
//+------------------------------------------------------------------+
double CTradeManager::CalculateLotSize(double entry_price, double sl_price, double risk_amount = 0)
{
   double lot_size = 0;
   
   switch(m_lot_method)
   {
      case LOT_FIXED:
         lot_size = m_fixed_lot;
         break;
         
      case LOT_PERCENTAGE:
      case LOT_VOLATILITY:
         {
            if(risk_amount <= 0)
               risk_amount = AccountInfoDouble(ACCOUNT_BALANCE) * m_risk_percentage / 100.0;
            
            double pip_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
            double pip_size = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
            double stop_loss_pips = MathAbs(entry_price - sl_price) / pip_size;
            
            if(stop_loss_pips > 0 && pip_value > 0)
            {
               lot_size = risk_amount / (stop_loss_pips * pip_value);
            }
            else
            {
               lot_size = m_fixed_lot;
            }
         }
         break;
   }
   
   // Normalize lot size
   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   lot_size = MathMax(lot_size, min_lot);
   lot_size = MathMin(lot_size, max_lot);
   lot_size = MathFloor(lot_size / lot_step) * lot_step;
   
   return lot_size;
}

//+------------------------------------------------------------------+
//| Check Risk Limits                                               |
//+------------------------------------------------------------------+
bool CTradeManager::CheckRiskLimits(void)
{
   if(IsNewTradingDay())
      ResetDailyCounters();
   
   // Check daily loss limit
   if(m_daily_loss >= m_max_daily_loss)
      return false;
   
   // Check trades per day limit
   if(m_trades_today >= m_max_trades_per_day)
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Check Spread                                                     |
//+------------------------------------------------------------------+
bool CTradeManager::CheckSpread(void)
{
   double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   return spread <= m_max_spread;
}

//+------------------------------------------------------------------+
//| Check Trading Time                                               |
//+------------------------------------------------------------------+
bool CTradeManager::CheckTradingTime(void)
{
   // Basic implementation - can be extended with session filters
   return true;
}

//+------------------------------------------------------------------+
//| Update Trade Information                                         |
//+------------------------------------------------------------------+
void CTradeManager::UpdateTradeInfo(void)
{
   int positions_count = 0;
   
   // Count positions with our magic number
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == m_magic_number)
            positions_count++;
      }
   }
   
   ArrayResize(m_open_trades, positions_count);
   
   int index = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == m_magic_number)
         {
            m_open_trades[index].ticket = m_position.Ticket();
            m_open_trades[index].open_time = m_position.Time();
            m_open_trades[index].open_price = m_position.PriceOpen();
            m_open_trades[index].volume = m_position.Volume();
            m_open_trades[index].type = (ENUM_ORDER_TYPE)m_position.PositionType();
            m_open_trades[index].sl = m_position.StopLoss();
            m_open_trades[index].tp = m_position.TakeProfit();
            m_open_trades[index].comment = m_position.Comment();
            m_open_trades[index].profit = m_position.Profit();
            index++;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Get Open Positions Count                                        |
//+------------------------------------------------------------------+
int CTradeManager::GetOpenPositionsCount(void)
{
   return ArraySize(m_open_trades);
}

//+------------------------------------------------------------------+
//| Get Total Profit                                                |
//+------------------------------------------------------------------+
double CTradeManager::GetTotalProfit(void)
{
   double total_profit = 0;
   
   for(int i = 0; i < ArraySize(m_open_trades); i++)
   {
      total_profit += m_open_trades[i].profit;
   }
   
   return total_profit;
}

//+------------------------------------------------------------------+
//| Reset Daily Counters                                            |
//+------------------------------------------------------------------+
void CTradeManager::ResetDailyCounters(void)
{
   m_trades_today = 0;
   m_daily_loss = 0;
   m_last_trade_date = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Check if New Trading Day                                        |
//+------------------------------------------------------------------+
bool CTradeManager::IsNewTradingDay(void)
{
   MqlDateTime current_time, last_time;
   TimeToStruct(TimeCurrent(), current_time);
   TimeToStruct(m_last_trade_date, last_time);
   
   return (current_time.day != last_time.day || 
           current_time.mon != last_time.mon || 
           current_time.year != last_time.year);
}