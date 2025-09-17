//+------------------------------------------------------------------+
//|                                      ZigZag_Backtester.mq5      |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs

#include "../Include/ZigZag_Common.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input group "=== Backtest Settings ==="
input datetime Start_Date = D'2024.01.01';    // Backtest Start Date
input datetime End_Date = D'2024.12.31';      // Backtest End Date
input double   ZigZag_Percentage = 3.0;       // ZigZag Percentage
input double   Min_Move_Threshold = 2.5;      // Minimum Move Threshold (%)

input group "=== Trading Parameters ==="
input double   Initial_Balance = 10000.0;     // Initial Balance
input double   Risk_Per_Trade = 2.0;          // Risk Per Trade (%)
input double   Risk_Reward_Ratio = 2.0;       // Risk-Reward Ratio
input int      Max_Trades = 1000;             // Maximum Trades

input group "=== Output Settings ==="
input bool     Show_Detailed_Results = true;  // Show Detailed Results
input bool     Export_To_CSV = false;         // Export Results to CSV
input string   CSV_Filename = "ZigZag_Backtest_Results.csv"; // CSV Filename

//+------------------------------------------------------------------+
//| Backtest Results Structure                                       |
//+------------------------------------------------------------------+
struct BacktestResults
{
   int total_trades;
   int winning_trades;
   int losing_trades;
   double gross_profit;
   double gross_loss;
   double net_profit;
   double win_rate;
   double profit_factor;
   double average_win;
   double average_loss;
   double largest_win;
   double largest_loss;
   double max_drawdown;
   double max_consecutive_wins;
   double max_consecutive_losses;
   double sharpe_ratio;
   double return_on_investment;
};

//+------------------------------------------------------------------+
//| Trade Record Structure                                           |
//+------------------------------------------------------------------+
struct TradeRecord
{
   datetime entry_time;
   datetime exit_time;
   double entry_price;
   double exit_price;
   double profit_loss;
   string trade_type;
   string exit_reason;
};

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
BacktestResults results;
TradeRecord trade_records[];
ZigZagPoint zigzag_points[];
double balance_history[];

//+------------------------------------------------------------------+
//| Script program start function                                   |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("Starting ZigZag Strategy Backtest...");
   Print("Start Date: ", TimeToString(Start_Date));
   Print("End Date: ", TimeToString(End_Date));
   Print("ZigZag Percentage: ", ZigZag_Percentage, "%");
   
   // Initialize results
   ZeroMemory(results);
   ArrayResize(trade_records, 0);
   ArrayResize(zigzag_points, 0);
   ArrayResize(balance_history, 0);
   
   // Run backtest
   if(RunBacktest())
   {
      // Calculate final results
      CalculateFinalResults();
      
      // Display results
      DisplayResults();
      
      // Export to CSV if requested
      if(Export_To_CSV)
         ExportResultsToCSV();
   }
   else
   {
      Print("Backtest failed to run properly");
   }
   
   Print("Backtest completed");
}

//+------------------------------------------------------------------+
//| Run Backtest                                                     |
//+------------------------------------------------------------------+
bool RunBacktest()
{
   // Get historical data
   datetime time_array[];
   double high_array[], low_array[], close_array[];
   
   int bars_copied = CopyTime(_Symbol, PERIOD_H1, Start_Date, End_Date, time_array);
   if(bars_copied <= 0)
   {
      Print("Failed to copy time data");
      return false;
   }
   
   if(CopyHigh(_Symbol, PERIOD_H1, Start_Date, End_Date, high_array) <= 0 ||
      CopyLow(_Symbol, PERIOD_H1, Start_Date, End_Date, low_array) <= 0 ||
      CopyClose(_Symbol, PERIOD_H1, Start_Date, End_Date, close_array) <= 0)
   {
      Print("Failed to copy price data");
      return false;
   }
   
   Print("Loaded ", bars_copied, " bars for analysis");
   
   // Calculate ZigZag points for the entire period
   ArrayResize(zigzag_points, bars_copied);
   int zigzag_count = CalculateZigZag(high_array, low_array, time_array, 
                                      ZigZag_Percentage, 0, bars_copied, zigzag_points);
   
   if(zigzag_count < 3)
   {
      Print("Insufficient ZigZag points found: ", zigzag_count);
      return false;
   }
   
   Print("Found ", zigzag_count, " ZigZag points");
   
   // Simulate trading
   double current_balance = Initial_Balance;
   ArrayResize(balance_history, zigzag_count);
   ArrayResize(trade_records, Max_Trades);
   
   int trade_count = 0;
   bool in_trade = false;
   TradeRecord current_trade;
   
   for(int i = 2; i < zigzag_count && trade_count < Max_Trades; i++)
   {
      ZigZagPoint current_point = zigzag_points[i];
      ZigZagPoint previous_point = zigzag_points[i-1];
      
      // Check if move meets minimum threshold
      if(MathAbs(current_point.percentage_move) < Min_Move_Threshold)
         continue;
      
      if(!in_trade)
      {
         // Look for entry signals
         if(IsValidEntry(zigzag_points, i))
         {
            // Enter trade
            current_trade.entry_time = current_point.time;
            current_trade.entry_price = current_point.price;
            
            if(current_point.type == ZIGZAG_LOW)
            {
               current_trade.trade_type = "BUY";
            }
            else
            {
               current_trade.trade_type = "SELL";
            }
            
            in_trade = true;
         }
      }
      else
      {
         // Look for exit signals
         if(IsValidExit(current_trade, current_point))
         {
            // Exit trade
            current_trade.exit_time = current_point.time;
            current_trade.exit_price = current_point.price;
            current_trade.exit_reason = "ZigZag Signal";
            
            // Calculate profit/loss
            double position_size = (current_balance * Risk_Per_Trade / 100.0) / 
                                  MathAbs(current_trade.entry_price - GetStopLossPrice(current_trade, zigzag_points, i));
            
            if(current_trade.trade_type == "BUY")
            {
               current_trade.profit_loss = (current_trade.exit_price - current_trade.entry_price) * position_size;
            }
            else
            {
               current_trade.profit_loss = (current_trade.entry_price - current_trade.exit_price) * position_size;
            }
            
            // Update balance
            current_balance += current_trade.profit_loss;
            balance_history[i] = current_balance;
            
            // Store trade record
            trade_records[trade_count] = current_trade;
            trade_count++;
            
            // Update results
            UpdateResults(current_trade);
            
            in_trade = false;
         }
      }
   }
   
   ArrayResize(trade_records, trade_count);
   results.total_trades = trade_count;
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if Valid Entry                                             |
//+------------------------------------------------------------------+
bool IsValidEntry(const ZigZagPoint &points[], int index)
{
   if(index < 2) return false;
   
   ZigZagPoint current = points[index];
   ZigZagPoint previous = points[index-1];
   
   // Simple entry logic - trade on ZigZag reversals
   if(current.type == ZIGZAG_LOW && previous.type == ZIGZAG_HIGH)
   {
      // Potential buy signal
      return true;
   }
   else if(current.type == ZIGZAG_HIGH && previous.type == ZIGZAG_LOW)
   {
      // Potential sell signal
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check if Valid Exit                                              |
//+------------------------------------------------------------------+
bool IsValidExit(const TradeRecord &trade, const ZigZagPoint &current_point)
{
   // Simple exit logic - exit on opposite ZigZag signal
   if(trade.trade_type == "BUY" && current_point.type == ZIGZAG_HIGH)
   {
      return true;
   }
   else if(trade.trade_type == "SELL" && current_point.type == ZIGZAG_LOW)
   {
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Get Stop Loss Price                                              |
//+------------------------------------------------------------------+
double GetStopLossPrice(const TradeRecord &trade, const ZigZagPoint &points[], int index)
{
   if(index < 1) return trade.entry_price;
   
   // Use previous ZigZag point as stop loss reference
   ZigZagPoint previous = points[index-1];
   
   if(trade.trade_type == "BUY")
   {
      return previous.price * 0.99; // 1% below previous low
   }
   else
   {
      return previous.price * 1.01; // 1% above previous high
   }
}

//+------------------------------------------------------------------+
//| Update Results                                                   |
//+------------------------------------------------------------------+
void UpdateResults(const TradeRecord &trade)
{
   if(trade.profit_loss > 0)
   {
      results.winning_trades++;
      results.gross_profit += trade.profit_loss;
      
      if(trade.profit_loss > results.largest_win)
         results.largest_win = trade.profit_loss;
   }
   else
   {
      results.losing_trades++;
      results.gross_loss += MathAbs(trade.profit_loss);
      
      if(MathAbs(trade.profit_loss) > results.largest_loss)
         results.largest_loss = MathAbs(trade.profit_loss);
   }
}

//+------------------------------------------------------------------+
//| Calculate Final Results                                          |
//+------------------------------------------------------------------+
void CalculateFinalResults()
{
   if(results.total_trades > 0)
   {
      results.win_rate = ((double)results.winning_trades / results.total_trades) * 100.0;
      results.net_profit = results.gross_profit - results.gross_loss;
      
      if(results.gross_loss > 0)
         results.profit_factor = results.gross_profit / results.gross_loss;
      
      if(results.winning_trades > 0)
         results.average_win = results.gross_profit / results.winning_trades;
      
      if(results.losing_trades > 0)
         results.average_loss = results.gross_loss / results.losing_trades;
      
      results.return_on_investment = (results.net_profit / Initial_Balance) * 100.0;
   }
   
   // Calculate maximum drawdown
   CalculateMaxDrawdown();
}

//+------------------------------------------------------------------+
//| Calculate Maximum Drawdown                                       |
//+------------------------------------------------------------------+
void CalculateMaxDrawdown()
{
   if(ArraySize(balance_history) == 0) return;
   
   double peak = Initial_Balance;
   double max_dd = 0;
   
   for(int i = 0; i < ArraySize(balance_history); i++)
   {
      if(balance_history[i] > peak)
         peak = balance_history[i];
      
      double current_dd = ((peak - balance_history[i]) / peak) * 100.0;
      if(current_dd > max_dd)
         max_dd = current_dd;
   }
   
   results.max_drawdown = max_dd;
}

//+------------------------------------------------------------------+
//| Display Results                                                  |
//+------------------------------------------------------------------+
void DisplayResults()
{
   Print("=== ZIGZAG STRATEGY BACKTEST RESULTS ===");
   Print("Period: ", TimeToString(Start_Date), " to ", TimeToString(End_Date));
   Print("Initial Balance: $", DoubleToString(Initial_Balance, 2));
   Print("Final Balance: $", DoubleToString(Initial_Balance + results.net_profit, 2));
   Print("");
   
   Print("=== TRADE STATISTICS ===");
   Print("Total Trades: ", results.total_trades);
   Print("Winning Trades: ", results.winning_trades);
   Print("Losing Trades: ", results.losing_trades);
   Print("Win Rate: ", DoubleToString(results.win_rate, 2), "%");
   Print("");
   
   Print("=== PROFIT & LOSS ===");
   Print("Gross Profit: $", DoubleToString(results.gross_profit, 2));
   Print("Gross Loss: $", DoubleToString(results.gross_loss, 2));
   Print("Net Profit: $", DoubleToString(results.net_profit, 2));
   Print("ROI: ", DoubleToString(results.return_on_investment, 2), "%");
   Print("Profit Factor: ", DoubleToString(results.profit_factor, 2));
   Print("");
   
   Print("=== TRADE ANALYSIS ===");
   Print("Average Win: $", DoubleToString(results.average_win, 2));
   Print("Average Loss: $", DoubleToString(results.average_loss, 2));
   Print("Largest Win: $", DoubleToString(results.largest_win, 2));
   Print("Largest Loss: $", DoubleToString(results.largest_loss, 2));
   Print("Maximum Drawdown: ", DoubleToString(results.max_drawdown, 2), "%");
   Print("");
   
   if(Show_Detailed_Results && ArraySize(trade_records) > 0)
   {
      Print("=== DETAILED TRADE HISTORY ===");
      for(int i = 0; i < MathMin(10, ArraySize(trade_records)); i++)
      {
         TradeRecord trade = trade_records[i];
         Print(StringFormat("Trade %d: %s | Entry: %s @ %.5f | Exit: %s @ %.5f | P&L: $%.2f",
                           i+1, trade.trade_type,
                           TimeToString(trade.entry_time),
                           trade.entry_price,
                           TimeToString(trade.exit_time),
                           trade.exit_price,
                           trade.profit_loss));
      }
      
      if(ArraySize(trade_records) > 10)
         Print("... and ", ArraySize(trade_records) - 10, " more trades");
   }
}

//+------------------------------------------------------------------+
//| Export Results to CSV                                            |
//+------------------------------------------------------------------+
void ExportResultsToCSV()
{
   string filename = CSV_Filename;
   int file_handle = FileOpen(filename, FILE_WRITE | FILE_CSV);
   
   if(file_handle != INVALID_HANDLE)
   {
      // Write header
      FileWrite(file_handle, "Trade", "Type", "Entry Time", "Entry Price", 
                "Exit Time", "Exit Price", "Profit/Loss", "Exit Reason");
      
      // Write trade data
      for(int i = 0; i < ArraySize(trade_records); i++)
      {
         TradeRecord trade = trade_records[i];
         FileWrite(file_handle, i+1, trade.trade_type,
                  TimeToString(trade.entry_time),
                  DoubleToString(trade.entry_price, 5),
                  TimeToString(trade.exit_time),
                  DoubleToString(trade.exit_price, 5),
                  DoubleToString(trade.profit_loss, 2),
                  trade.exit_reason);
      }
      
      FileClose(file_handle);
      Print("Results exported to: ", filename);
   }
   else
   {
      Print("Failed to create CSV file: ", filename);
   }
}