//+------------------------------------------------------------------+
//|                                           RiskManager.mqh       |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "ZigZag_Common.mqh"

//+------------------------------------------------------------------+
//| Risk Level Enum                                                  |
//+------------------------------------------------------------------+
enum ENUM_RISK_LEVEL
{
   RISK_LOW = 0,            // Low risk
   RISK_MEDIUM = 1,         // Medium risk
   RISK_HIGH = 2            // High risk
};

//+------------------------------------------------------------------+
//| Risk Metrics Structure                                           |
//+------------------------------------------------------------------+
struct RiskMetrics
{
   double current_drawdown;     // Current drawdown percentage
   double max_drawdown;         // Maximum drawdown
   double daily_var;            // Daily Value at Risk
   double win_rate;             // Win rate percentage
   double profit_factor;        // Profit factor
   double sharp_ratio;          // Sharpe ratio
   int consecutive_losses;      // Consecutive losses
   double largest_loss;         // Largest single loss
   ENUM_RISK_LEVEL risk_level;  // Current risk level
};

//+------------------------------------------------------------------+
//| Trade Statistics Structure                                       |
//+------------------------------------------------------------------+
struct TradeStatistics
{
   int total_trades;            // Total number of trades
   int winning_trades;          // Number of winning trades
   int losing_trades;           // Number of losing trades
   double gross_profit;         // Total gross profit
   double gross_loss;           // Total gross loss
   double net_profit;           // Net profit
   double average_win;          // Average winning trade
   double average_loss;         // Average losing trade
   double largest_win;          // Largest winning trade
   double largest_loss;         // Largest losing trade
   int max_consecutive_wins;    // Maximum consecutive wins
   int max_consecutive_losses;  // Maximum consecutive losses
};

//+------------------------------------------------------------------+
//| Risk Manager Class                                              |
//+------------------------------------------------------------------+
class CRiskManager
{
private:
   // Risk settings
   double            m_max_risk_per_trade;      // Maximum risk per trade (%)
   double            m_max_daily_risk;          // Maximum daily risk (%)
   double            m_max_drawdown_limit;      // Maximum drawdown limit (%)
   double            m_max_correlation;         // Maximum correlation with other pairs
   
   // Account metrics
   double            m_initial_balance;         // Initial account balance
   double            m_peak_balance;            // Peak account balance
   double            m_current_balance;         // Current account balance
   double            m_account_equity;          // Current account equity
   
   // Trade tracking
   TradeStatistics   m_statistics;              // Trade statistics
   RiskMetrics       m_risk_metrics;            // Risk metrics
   double            m_daily_pnl[];             // Daily P&L array
   datetime          m_last_update;             // Last update time
   
   // ATR for volatility calculations
   int               m_atr_handle;              // ATR indicator handle
   double            m_atr_buffer[];            // ATR values
   
public:
   // Constructor
   CRiskManager(void);
   
   // Initialization
   bool Initialize(double initial_balance);
   void Deinitialize(void);
   
   // Settings
   void SetMaxRiskPerTrade(double risk) { m_max_risk_per_trade = risk; }
   void SetMaxDailyRisk(double risk) { m_max_daily_risk = risk; }
   void SetMaxDrawdownLimit(double limit) { m_max_drawdown_limit = limit; }
   void SetMaxCorrelation(double correlation) { m_max_correlation = correlation; }
   
   // Risk calculations
   double CalculatePositionSize(double entry_price, double stop_loss, double account_risk);
   double CalculateStopLoss(double entry_price, const ZigZagPoint &points[], int count, ENUM_SL_METHOD method);
   double CalculateTakeProfit(double entry_price, double stop_loss, ENUM_TP_METHOD method, double ratio = 2.0);
   double CalculateATRBasedLevel(double current_price, double multiplier, bool is_stop_loss);
   
   // Risk assessment
   bool ValidateTradeRisk(double position_size, double entry_price, double stop_loss);
   bool CheckDailyRiskLimits(double proposed_risk);
   bool CheckDrawdownLimits(void);
   ENUM_RISK_LEVEL AssessCurrentRiskLevel(void);
   
   // Statistical analysis
   void UpdateTradeStatistics(double profit_loss, bool is_winning_trade);
   void UpdateRiskMetrics(void);
   double CalculateVaR(double confidence_level = 0.95);
   double CalculateSharpeRatio(void);
   
   // Position sizing based on volatility
   double GetVolatilityAdjustedSize(double base_size);
   double GetATRValue(int shift = 0);
   
   // Market condition assessment
   bool IsHighVolatilityPeriod(void);
   bool IsCorrelationRiskHigh(string symbol1, string symbol2);
   
   // Utility functions
   void ResetStatistics(void);
   void LogRiskMetrics(void);
   string GetRiskReport(void);
   
   // Getters
   RiskMetrics GetRiskMetrics(void) { return m_risk_metrics; }
   TradeStatistics GetTradeStatistics(void) { return m_statistics; }
   double GetCurrentDrawdown(void) { return m_risk_metrics.current_drawdown; }
   double GetWinRate(void) { return m_risk_metrics.win_rate; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRiskManager::CRiskManager(void)
{
   m_max_risk_per_trade = 2.0;      // 2% per trade
   m_max_daily_risk = 5.0;          // 5% per day
   m_max_drawdown_limit = 20.0;     // 20% maximum drawdown
   m_max_correlation = 0.7;         // 70% maximum correlation
   
   m_initial_balance = 0;
   m_peak_balance = 0;
   m_current_balance = 0;
   m_account_equity = 0;
   
   ZeroMemory(m_statistics);
   ZeroMemory(m_risk_metrics);
   
   m_atr_handle = INVALID_HANDLE;
   m_last_update = 0;
   
   ArrayResize(m_daily_pnl, 252); // One year of trading days
   ArrayInitialize(m_daily_pnl, 0);
}

//+------------------------------------------------------------------+
//| Initialize Risk Manager                                          |
//+------------------------------------------------------------------+
bool CRiskManager::Initialize(double initial_balance)
{
   m_initial_balance = initial_balance;
   m_peak_balance = initial_balance;
   m_current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   m_account_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   // Initialize ATR indicator
   m_atr_handle = iATR(_Symbol, PERIOD_CURRENT, 14);
   if(m_atr_handle == INVALID_HANDLE)
   {
      Print("Failed to create ATR indicator handle");
      return false;
   }
   
   ArraySetAsSeries(m_atr_buffer, true);
   
   ResetStatistics();
   UpdateRiskMetrics();
   
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize Risk Manager                                        |
//+------------------------------------------------------------------+
void CRiskManager::Deinitialize(void)
{
   if(m_atr_handle != INVALID_HANDLE)
      IndicatorRelease(m_atr_handle);
}

//+------------------------------------------------------------------+
//| Calculate Position Size                                          |
//+------------------------------------------------------------------+
double CRiskManager::CalculatePositionSize(double entry_price, double stop_loss, double account_risk)
{
   if(entry_price <= 0 || stop_loss <= 0 || account_risk <= 0)
      return 0;
   
   double risk_amount = m_current_balance * account_risk / 100.0;
   double pip_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double pip_size = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   double stop_loss_pips = MathAbs(entry_price - stop_loss) / pip_size;
   
   if(stop_loss_pips <= 0 || pip_value <= 0)
      return 0;
   
   double position_size = risk_amount / (stop_loss_pips * pip_value);
   
   // Apply volatility adjustment
   position_size = GetVolatilityAdjustedSize(position_size);
   
   // Normalize lot size
   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   position_size = MathMax(position_size, min_lot);
   position_size = MathMin(position_size, max_lot);
   position_size = MathFloor(position_size / lot_step) * lot_step;
   
   return position_size;
}

//+------------------------------------------------------------------+
//| Calculate Stop Loss                                              |
//+------------------------------------------------------------------+
double CRiskManager::CalculateStopLoss(double entry_price, const ZigZagPoint &points[], int count, ENUM_SL_METHOD method)
{
   double stop_loss = 0;
   
   switch(method)
   {
      case SL_FIXED_POINTS:
         {
            double point_value = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
            stop_loss = entry_price - (100 * point_value); // 100 points default
         }
         break;
         
      case SL_ATR:
         {
            double atr = GetATRValue();
            stop_loss = CalculateATRBasedLevel(entry_price, 2.0, true);
         }
         break;
         
      case SL_SWING_LEVELS:
         {
            if(count >= 2)
            {
               // Find the nearest swing level
               ZigZagPoint last_point = points[count - 1];
               if(last_point.type == ZIGZAG_HIGH)
               {
                  // For sell orders, use the swing high
                  stop_loss = last_point.price + (10 * SymbolInfoDouble(_Symbol, SYMBOL_POINT));
               }
               else
               {
                  // For buy orders, use the swing low
                  stop_loss = last_point.price - (10 * SymbolInfoDouble(_Symbol, SYMBOL_POINT));
               }
            }
            else
            {
               // Fallback to ATR method
               stop_loss = CalculateATRBasedLevel(entry_price, 2.0, true);
            }
         }
         break;
         
      case SL_PERCENTAGE:
         {
            stop_loss = entry_price * (1 - 0.02); // 2% default
         }
         break;
   }
   
   return stop_loss;
}

//+------------------------------------------------------------------+
//| Calculate Take Profit                                            |
//+------------------------------------------------------------------+
double CRiskManager::CalculateTakeProfit(double entry_price, double stop_loss, ENUM_TP_METHOD method, double ratio = 2.0)
{
   double take_profit = 0;
   double risk_distance = MathAbs(entry_price - stop_loss);
   
   switch(method)
   {
      case TP_FIXED_POINTS:
         {
            double point_value = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
            take_profit = entry_price + (200 * point_value); // 200 points default
         }
         break;
         
      case TP_RISK_REWARD:
         {
            if(entry_price > stop_loss) // Buy order
               take_profit = entry_price + (risk_distance * ratio);
            else // Sell order
               take_profit = entry_price - (risk_distance * ratio);
         }
         break;
         
      case TP_STATISTICAL:
         {
            // Use statistical analysis from ZigZag data
            take_profit = entry_price + (risk_distance * ratio); // Simplified for now
         }
         break;
         
      case TP_ATR:
         {
            take_profit = CalculateATRBasedLevel(entry_price, 3.0, false);
         }
         break;
   }
   
   return take_profit;
}

//+------------------------------------------------------------------+
//| Calculate ATR Based Level                                        |
//+------------------------------------------------------------------+
double CRiskManager::CalculateATRBasedLevel(double current_price, double multiplier, bool is_stop_loss)
{
   double atr = GetATRValue();
   if(atr <= 0) return current_price;
   
   if(is_stop_loss)
      return current_price - (atr * multiplier);
   else
      return current_price + (atr * multiplier);
}

//+------------------------------------------------------------------+
//| Validate Trade Risk                                              |
//+------------------------------------------------------------------+
bool CRiskManager::ValidateTradeRisk(double position_size, double entry_price, double stop_loss)
{
   double risk_amount = position_size * MathAbs(entry_price - stop_loss) * 
                       SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) / 
                       SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   double risk_percentage = (risk_amount / m_current_balance) * 100.0;
   
   return risk_percentage <= m_max_risk_per_trade;
}

//+------------------------------------------------------------------+
//| Check Daily Risk Limits                                         |
//+------------------------------------------------------------------+
bool CRiskManager::CheckDailyRiskLimits(double proposed_risk)
{
   // Calculate current daily risk
   double daily_risk = 0;
   
   // Add logic to calculate total daily risk from open positions
   // This is simplified for now
   
   return (daily_risk + proposed_risk) <= m_max_daily_risk;
}

//+------------------------------------------------------------------+
//| Check Drawdown Limits                                           |
//+------------------------------------------------------------------+
bool CRiskManager::CheckDrawdownLimits(void)
{
   UpdateRiskMetrics();
   return m_risk_metrics.current_drawdown <= m_max_drawdown_limit;
}

//+------------------------------------------------------------------+
//| Assess Current Risk Level                                        |
//+------------------------------------------------------------------+
ENUM_RISK_LEVEL CRiskManager::AssessCurrentRiskLevel(void)
{
   UpdateRiskMetrics();
   
   if(m_risk_metrics.current_drawdown > 15.0 || 
      m_risk_metrics.consecutive_losses > 5)
      return RISK_HIGH;
   else if(m_risk_metrics.current_drawdown > 8.0 || 
           m_risk_metrics.consecutive_losses > 3)
      return RISK_MEDIUM;
   else
      return RISK_LOW;
}

//+------------------------------------------------------------------+
//| Update Trade Statistics                                          |
//+------------------------------------------------------------------+
void CRiskManager::UpdateTradeStatistics(double profit_loss, bool is_winning_trade)
{
   m_statistics.total_trades++;
   
   if(is_winning_trade)
   {
      m_statistics.winning_trades++;
      m_statistics.gross_profit += profit_loss;
      
      if(profit_loss > m_statistics.largest_win)
         m_statistics.largest_win = profit_loss;
   }
   else
   {
      m_statistics.losing_trades++;
      m_statistics.gross_loss += MathAbs(profit_loss);
      
      if(MathAbs(profit_loss) > m_statistics.largest_loss)
         m_statistics.largest_loss = MathAbs(profit_loss);
   }
   
   m_statistics.net_profit = m_statistics.gross_profit - m_statistics.gross_loss;
   
   if(m_statistics.winning_trades > 0)
      m_statistics.average_win = m_statistics.gross_profit / m_statistics.winning_trades;
   
   if(m_statistics.losing_trades > 0)
      m_statistics.average_loss = m_statistics.gross_loss / m_statistics.losing_trades;
   
   UpdateRiskMetrics();
}

//+------------------------------------------------------------------+
//| Update Risk Metrics                                             |
//+------------------------------------------------------------------+
void CRiskManager::UpdateRiskMetrics(void)
{
   m_current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   m_account_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   // Update peak balance
   if(m_current_balance > m_peak_balance)
      m_peak_balance = m_current_balance;
   
   // Calculate current drawdown
   m_risk_metrics.current_drawdown = ((m_peak_balance - m_current_balance) / m_peak_balance) * 100.0;
   
   // Update maximum drawdown
   if(m_risk_metrics.current_drawdown > m_risk_metrics.max_drawdown)
      m_risk_metrics.max_drawdown = m_risk_metrics.current_drawdown;
   
   // Calculate win rate
   if(m_statistics.total_trades > 0)
      m_risk_metrics.win_rate = ((double)m_statistics.winning_trades / m_statistics.total_trades) * 100.0;
   
   // Calculate profit factor
   if(m_statistics.gross_loss > 0)
      m_risk_metrics.profit_factor = m_statistics.gross_profit / m_statistics.gross_loss;
   
   // Assess risk level
   m_risk_metrics.risk_level = AssessCurrentRiskLevel();
}

//+------------------------------------------------------------------+
//| Get ATR Value                                                    |
//+------------------------------------------------------------------+
double CRiskManager::GetATRValue(int shift = 0)
{
   if(m_atr_handle == INVALID_HANDLE)
      return 0;
   
   if(CopyBuffer(m_atr_handle, 0, shift, 1, m_atr_buffer) <= 0)
      return 0;
   
   return m_atr_buffer[0];
}

//+------------------------------------------------------------------+
//| Get Volatility Adjusted Size                                    |
//+------------------------------------------------------------------+
double CRiskManager::GetVolatilityAdjustedSize(double base_size)
{
   double atr = GetATRValue();
   if(atr <= 0) return base_size;
   
   // Get average ATR for comparison
   double atr_array[];
   ArrayResize(atr_array, 20);
   if(CopyBuffer(m_atr_handle, 0, 0, 20, atr_array) <= 0)
      return base_size;
   
   double avg_atr = 0;
   for(int i = 0; i < 20; i++)
      avg_atr += atr_array[i];
   avg_atr /= 20;
   
   // Adjust size based on current volatility vs average
   double volatility_ratio = atr / avg_atr;
   
   if(volatility_ratio > 1.5)        // High volatility
      return base_size * 0.7;        // Reduce size
   else if(volatility_ratio < 0.7)   // Low volatility
      return base_size * 1.2;        // Increase size
   
   return base_size;
}

//+------------------------------------------------------------------+
//| Check if High Volatility Period                                 |
//+------------------------------------------------------------------+
bool CRiskManager::IsHighVolatilityPeriod(void)
{
   double atr = GetATRValue();
   double atr_array[];
   ArrayResize(atr_array, 50);
   
   if(CopyBuffer(m_atr_handle, 0, 0, 50, atr_array) <= 0)
      return false;
   
   double avg_atr = 0;
   for(int i = 0; i < 50; i++)
      avg_atr += atr_array[i];
   avg_atr /= 50;
   
   return atr > (avg_atr * 1.5);
}

//+------------------------------------------------------------------+
//| Reset Statistics                                                 |
//+------------------------------------------------------------------+
void CRiskManager::ResetStatistics(void)
{
   ZeroMemory(m_statistics);
   ZeroMemory(m_risk_metrics);
   ArrayInitialize(m_daily_pnl, 0);
}

//+------------------------------------------------------------------+
//| Get Risk Report                                                  |
//+------------------------------------------------------------------+
string CRiskManager::GetRiskReport(void)
{
   UpdateRiskMetrics();
   
   string report = "=== RISK MANAGEMENT REPORT ===\n";
   report += StringFormat("Current Drawdown: %.2f%%\n", m_risk_metrics.current_drawdown);
   report += StringFormat("Maximum Drawdown: %.2f%%\n", m_risk_metrics.max_drawdown);
   report += StringFormat("Win Rate: %.2f%%\n", m_risk_metrics.win_rate);
   report += StringFormat("Profit Factor: %.2f\n", m_risk_metrics.profit_factor);
   report += StringFormat("Total Trades: %d\n", m_statistics.total_trades);
   report += StringFormat("Net Profit: %.2f\n", m_statistics.net_profit);
   
   string risk_level_str = "";
   switch(m_risk_metrics.risk_level)
   {
      case RISK_LOW: risk_level_str = "LOW"; break;
      case RISK_MEDIUM: risk_level_str = "MEDIUM"; break;
      case RISK_HIGH: risk_level_str = "HIGH"; break;
   }
   report += StringFormat("Risk Level: %s\n", risk_level_str);
   
   return report;
}