//+------------------------------------------------------------------+
//|                                    ZigZag_Statistics_EA.mq5     |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "../Include/ZigZag_Common.mqh"
#include "../Include/TradeManager.mqh"
#include "../Include/RiskManager.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input group "=== ZigZag Settings ==="
input double ZigZag1_Percentage = 3.0;        // ZigZag 1 Percentage
input double ZigZag2_Percentage = 5.0;        // ZigZag 2 Percentage
input int    Calculation_Depth = 500;         // Calculation Depth
input bool   Use_Both_ZigZags = true;         // Use Both ZigZag Signals

input group "=== Trading Settings ==="
input bool   Enable_Auto_Trading = true;      // Enable Automated Trading
input ENUM_TRADE_DIRECTION Trade_Direction = TRADE_BOTH; // Trade Direction
input int    Min_Time_Between_Trades = 60;    // Min Time Between Trades (minutes)
input double Max_Spread = 3.0;                // Maximum Spread (points)
input bool   Use_Session_Filter = false;      // Use Trading Session Filter

input group "=== Signal Filters ==="
input double Min_Percentage_Move = 2.5;       // Minimum Percentage Move for Entry
input double Min_Statistical_Significance = 1.5; // Minimum Statistical Significance
input bool   Use_Market_Structure_Filter = true; // Use Market Structure Filter
input bool   Use_Trend_Filter = true;         // Use Trend Filter
input int    Trend_Lookback_Points = 5;       // Trend Lookback Points

input group "=== Risk Management ==="
input ENUM_LOT_SIZE_METHOD Lot_Size_Method = LOT_PERCENTAGE; // Lot Size Method
input double Fixed_Lot_Size = 0.1;            // Fixed Lot Size
input double Risk_Percentage = 2.0;           // Risk Percentage per Trade
input double Max_Daily_Loss_Percent = 5.0;    // Maximum Daily Loss (%)
input int    Max_Trades_Per_Day = 10;         // Maximum Trades per Day
input ENUM_SL_METHOD Stop_Loss_Method = SL_SWING_LEVELS; // Stop Loss Method
input ENUM_TP_METHOD Take_Profit_Method = TP_RISK_REWARD; // Take Profit Method
input double Risk_Reward_Ratio = 2.0;         // Risk-Reward Ratio

input group "=== Trade Management ==="
input bool   Use_Trailing_Stop = true;        // Use Trailing Stop
input bool   Use_Break_Even = true;           // Move to Break Even
input double Break_Even_Trigger = 1.5;        // Break Even Trigger (R:R)
input bool   Use_Partial_Close = false;       // Use Partial Profit Taking
input double Partial_Close_Percent = 50.0;    // Partial Close Percentage

input group "=== Display Settings ==="
input bool   Show_Info_Panel = true;          // Show Information Panel
input bool   Show_Trade_Arrows = true;        // Show Trade Arrows
input bool   Show_Statistics = true;          // Show Statistics
input color  Panel_Color = clrWhite;          // Panel Background Color
input int    Magic_Number = 123456;           // Magic Number

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CTradeManager *trade_manager;
CRiskManager *risk_manager;

ZigZagPoint zigzag1_points[];
ZigZagPoint zigzag2_points[];
ZigZagStatistics stats1, stats2;

int zigzag1_count, zigzag2_count;
datetime last_trade_time;
datetime last_calculation_time;
datetime ea_start_time;

double high_buffer[], low_buffer[];
datetime time_buffer[];

bool initialization_complete = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize managers
   trade_manager = new CTradeManager();
   risk_manager = new CRiskManager();
   
   if(!trade_manager.Initialize(Magic_Number))
   {
      Print("Failed to initialize Trade Manager");
      return INIT_FAILED;
   }
   
   if(!risk_manager.Initialize(AccountInfoDouble(ACCOUNT_BALANCE)))
   {
      Print("Failed to initialize Risk Manager");
      return INIT_FAILED;
   }
   
   // Configure trade manager
   trade_manager.SetTradeDirection(Trade_Direction);
   trade_manager.SetMaxSpread(Max_Spread);
   trade_manager.SetMaxDailyLoss(AccountInfoDouble(ACCOUNT_BALANCE) * Max_Daily_Loss_Percent / 100.0);
   trade_manager.SetMaxTradesPerDay(Max_Trades_Per_Day);
   trade_manager.SetLotSizeMethod(Lot_Size_Method, 
      (Lot_Size_Method == LOT_FIXED) ? Fixed_Lot_Size : Risk_Percentage);
   
   // Configure risk manager
   risk_manager.SetMaxRiskPerTrade(Risk_Percentage);
   risk_manager.SetMaxDailyRisk(Max_Daily_Loss_Percent);
   risk_manager.SetMaxDrawdownLimit(20.0);
   
   // Initialize arrays
   ArrayResize(zigzag1_points, Calculation_Depth);
   ArrayResize(zigzag2_points, Calculation_Depth);
   ArrayResize(high_buffer, Calculation_Depth);
   ArrayResize(low_buffer, Calculation_Depth);
   ArrayResize(time_buffer, Calculation_Depth);
   
   zigzag1_count = 0;
   zigzag2_count = 0;
   last_trade_time = 0;
   last_calculation_time = 0;
   ea_start_time = TimeCurrent();
   
   // Set up initial display
   if(Show_Info_Panel)
      UpdateInfoPanel();
   
   Print("ZigZag Statistics EA initialized successfully");
   initialization_complete = true;
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(trade_manager != NULL)
   {
      delete trade_manager;
      trade_manager = NULL;
   }
   
   if(risk_manager != NULL)
   {
      risk_manager.Deinitialize();
      delete risk_manager;
      risk_manager = NULL;
   }
   
   // Clean up display objects
   CleanupDisplay();
   
   Print("ZigZag Statistics EA deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!initialization_complete || !Enable_Auto_Trading)
      return;
   
   // Update price data
   if(!UpdatePriceData())
      return;
   
   // Calculate ZigZag points on new bar
   static datetime last_bar_time = 0;
   if(iTime(_Symbol, PERIOD_CURRENT, 0) != last_bar_time)
   {
      last_bar_time = iTime(_Symbol, PERIOD_CURRENT, 0);
      
      if(!CalculateZigZagPoints())
         return;
      
      // Update statistics
      if(zigzag1_count > 2)
         stats1 = CalculateStatistics(zigzag1_points, zigzag1_count);
      
      if(zigzag2_count > 2)
         stats2 = CalculateStatistics(zigzag2_points, zigzag2_count);
   }
   
   // Check for trading signals
   if(ShouldCheckForSignals())
   {
      CheckTradingSignals();
   }
   
   // Manage open trades
   ManageOpenTrades();
   
   // Update display
   if(Show_Info_Panel)
      UpdateInfoPanel();
}

//+------------------------------------------------------------------+
//| Update Price Data                                                |
//+------------------------------------------------------------------+
bool UpdatePriceData()
{
   int copied_high = CopyHigh(_Symbol, PERIOD_CURRENT, 0, Calculation_Depth, high_buffer);
   int copied_low = CopyLow(_Symbol, PERIOD_CURRENT, 0, Calculation_Depth, low_buffer);
   int copied_time = CopyTime(_Symbol, PERIOD_CURRENT, 0, Calculation_Depth, time_buffer);
   
   if(copied_high <= 0 || copied_low <= 0 || copied_time <= 0)
   {
      Print("Failed to copy price data");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Calculate ZigZag Points                                          |
//+------------------------------------------------------------------+
bool CalculateZigZagPoints()
{
   // Calculate ZigZag 1
   zigzag1_count = CalculateZigZag(high_buffer, low_buffer, time_buffer, 
                                   ZigZag1_Percentage, 0, Calculation_Depth, zigzag1_points);
   
   // Calculate ZigZag 2
   if(Use_Both_ZigZags)
   {
      zigzag2_count = CalculateZigZag(high_buffer, low_buffer, time_buffer, 
                                      ZigZag2_Percentage, 0, Calculation_Depth, zigzag2_points);
   }
   
   return (zigzag1_count > 0);
}

//+------------------------------------------------------------------+
//| Should Check for Signals                                        |
//+------------------------------------------------------------------+
bool ShouldCheckForSignals()
{
   // Check time between trades
   if(last_trade_time > 0 && 
      (TimeCurrent() - last_trade_time) < (Min_Time_Between_Trades * 60))
      return false;
   
   // Check if we have enough ZigZag points
   if(zigzag1_count < 3)
      return false;
   
   // Check risk limits
   if(!risk_manager.CheckDailyRiskLimits(Risk_Percentage) ||
      !risk_manager.CheckDrawdownLimits())
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Check Trading Signals                                           |
//+------------------------------------------------------------------+
void CheckTradingSignals()
{
   // Check buy signals
   if(CheckBuySignal())
   {
      ExecuteBuyOrder();
   }
   // Check sell signals
   else if(CheckSellSignal())
   {
      ExecuteSellOrder();
   }
}

//+------------------------------------------------------------------+
//| Check Buy Signal                                                 |
//+------------------------------------------------------------------+
bool CheckBuySignal()
{
   if(Trade_Direction == TRADE_SHORT_ONLY)
      return false;
   
   if(zigzag1_count < 3)
      return false;
   
   ZigZagPoint latest = zigzag1_points[zigzag1_count - 1];
   ZigZagPoint previous = zigzag1_points[zigzag1_count - 2];
   
   // Check if latest point is a low (potential buy signal)
   if(latest.type != ZIGZAG_LOW)
      return false;
   
   // Check minimum percentage move
   if(MathAbs(latest.percentage_move) < Min_Percentage_Move)
      return false;
   
   // Market structure filter
   if(Use_Market_Structure_Filter)
   {
      if(latest.structure != STRUCTURE_HL && latest.structure != STRUCTURE_NONE)
      {
         // Only trade Higher Lows for bullish structure
         if(GetMarketBias(zigzag1_points, zigzag1_count, Trend_Lookback_Points) <= 0)
            return false;
      }
   }
   
   // Trend filter
   if(Use_Trend_Filter)
   {
      int bias = GetMarketBias(zigzag1_points, zigzag1_count, Trend_Lookback_Points);
      if(bias < 0) // Don't buy in bearish trend
         return false;
   }
   
   // Statistical significance filter
   if(stats1.avg_move_up > 0 && 
      MathAbs(latest.percentage_move) < (stats1.avg_move_up * Min_Statistical_Significance))
      return false;
   
   // ZigZag 2 confirmation
   if(Use_Both_ZigZags && zigzag2_count >= 2)
   {
      ZigZagPoint zz2_latest = zigzag2_points[zigzag2_count - 1];
      // Additional confirmation logic can be added here
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check Sell Signal                                                |
//+------------------------------------------------------------------+
bool CheckSellSignal()
{
   if(Trade_Direction == TRADE_LONG_ONLY)
      return false;
   
   if(zigzag1_count < 3)
      return false;
   
   ZigZagPoint latest = zigzag1_points[zigzag1_count - 1];
   ZigZagPoint previous = zigzag1_points[zigzag1_count - 2];
   
   // Check if latest point is a high (potential sell signal)
   if(latest.type != ZIGZAG_HIGH)
      return false;
   
   // Check minimum percentage move
   if(MathAbs(latest.percentage_move) < Min_Percentage_Move)
      return false;
   
   // Market structure filter
   if(Use_Market_Structure_Filter)
   {
      if(latest.structure != STRUCTURE_LH && latest.structure != STRUCTURE_NONE)
      {
         // Only trade Lower Highs for bearish structure
         if(GetMarketBias(zigzag1_points, zigzag1_count, Trend_Lookback_Points) >= 0)
            return false;
      }
   }
   
   // Trend filter
   if(Use_Trend_Filter)
   {
      int bias = GetMarketBias(zigzag1_points, zigzag1_count, Trend_Lookback_Points);
      if(bias > 0) // Don't sell in bullish trend
         return false;
   }
   
   // Statistical significance filter
   if(stats1.avg_move_down > 0 && 
      MathAbs(latest.percentage_move) < (stats1.avg_move_down * Min_Statistical_Significance))
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Execute Buy Order                                                |
//+------------------------------------------------------------------+
void ExecuteBuyOrder()
{
   double entry_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double stop_loss = risk_manager.CalculateStopLoss(entry_price, zigzag1_points, 
                                                     zigzag1_count, Stop_Loss_Method);
   double take_profit = risk_manager.CalculateTakeProfit(entry_price, stop_loss, 
                                                         Take_Profit_Method, Risk_Reward_Ratio);
   
   // Validate the trade
   double lot_size = risk_manager.CalculatePositionSize(entry_price, stop_loss, Risk_Percentage);
   
   if(!risk_manager.ValidateTradeRisk(lot_size, entry_price, stop_loss))
   {
      Print("Trade risk validation failed for buy order");
      return;
   }
   
   string comment = StringFormat("ZZ_EA_BUY_%s", TimeToString(TimeCurrent(), TIME_SECONDS));
   
   if(trade_manager.OpenBuyOrder(entry_price, lot_size, stop_loss, take_profit, comment))
   {
      last_trade_time = TimeCurrent();
      
      if(Show_Trade_Arrows)
         CreateTradeArrow("BUY_" + IntegerToString(TimeCurrent()), entry_price, clrBlue, "BUY");
      
      Print(StringFormat("Buy order executed: Price=%.5f, Lot=%.2f, SL=%.5f, TP=%.5f", 
                         entry_price, lot_size, stop_loss, take_profit));
   }
}

//+------------------------------------------------------------------+
//| Execute Sell Order                                               |
//+------------------------------------------------------------------+
void ExecuteSellOrder()
{
   double entry_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double stop_loss = risk_manager.CalculateStopLoss(entry_price, zigzag1_points, 
                                                     zigzag1_count, Stop_Loss_Method);
   double take_profit = risk_manager.CalculateTakeProfit(entry_price, stop_loss, 
                                                         Take_Profit_Method, Risk_Reward_Ratio);
   
   // Validate the trade
   double lot_size = risk_manager.CalculatePositionSize(entry_price, stop_loss, Risk_Percentage);
   
   if(!risk_manager.ValidateTradeRisk(lot_size, entry_price, stop_loss))
   {
      Print("Trade risk validation failed for sell order");
      return;
   }
   
   string comment = StringFormat("ZZ_EA_SELL_%s", TimeToString(TimeCurrent(), TIME_SECONDS));
   
   if(trade_manager.OpenSellOrder(entry_price, lot_size, stop_loss, take_profit, comment))
   {
      last_trade_time = TimeCurrent();
      
      if(Show_Trade_Arrows)
         CreateTradeArrow("SELL_" + IntegerToString(TimeCurrent()), entry_price, clrRed, "SELL");
      
      Print(StringFormat("Sell order executed: Price=%.5f, Lot=%.2f, SL=%.5f, TP=%.5f", 
                         entry_price, lot_size, stop_loss, take_profit));
   }
}

//+------------------------------------------------------------------+
//| Manage Open Trades                                              |
//+------------------------------------------------------------------+
void ManageOpenTrades()
{
   // Update trade information
   trade_manager.UpdateTradeInfo();
   
   int positions_count = trade_manager.GetOpenPositionsCount();
   if(positions_count == 0)
      return;
   
   // Implement trailing stop logic
   if(Use_Trailing_Stop)
   {
      UpdateTrailingStops();
   }
   
   // Implement break-even logic
   if(Use_Break_Even)
   {
      UpdateBreakEven();
   }
   
   // Implement partial close logic
   if(Use_Partial_Close)
   {
      UpdatePartialClose();
   }
}

//+------------------------------------------------------------------+
//| Update Trailing Stops                                           |
//+------------------------------------------------------------------+
void UpdateTrailingStops()
{
   // Implementation for trailing stops based on new ZigZag pivots
   // This would monitor for new ZigZag points and adjust stops accordingly
}

//+------------------------------------------------------------------+
//| Update Break Even                                                |
//+------------------------------------------------------------------+
void UpdateBreakEven()
{
   // Implementation for moving stops to break-even
   // when profit reaches specified trigger level
}

//+------------------------------------------------------------------+
//| Update Partial Close                                             |
//+------------------------------------------------------------------+
void UpdatePartialClose()
{
   // Implementation for partial profit taking
   // at statistical levels or predetermined targets
}

//+------------------------------------------------------------------+
//| Create Trade Arrow                                               |
//+------------------------------------------------------------------+
void CreateTradeArrow(string name, double price, color arrow_color, string text)
{
   ObjectDelete(0, name);
   
   if(ObjectCreate(0, name, OBJ_ARROW_BUY, 0, TimeCurrent(), price))
   {
      ObjectSetInteger(0, name, OBJPROP_COLOR, arrow_color);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 3);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   }
}

//+------------------------------------------------------------------+
//| Update Information Panel                                         |
//+------------------------------------------------------------------+
void UpdateInfoPanel()
{
   string panel_name = "ZigZagEAPanel";
   
   // Remove existing panel
   ObjectDelete(0, panel_name);
   
   // Create panel background
   if(ObjectCreate(0, panel_name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
   {
      ObjectSetInteger(0, panel_name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, panel_name, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, panel_name, OBJPROP_YDISTANCE, 30);
      ObjectSetInteger(0, panel_name, OBJPROP_XSIZE, 280);
      ObjectSetInteger(0, panel_name, OBJPROP_YSIZE, 400);
      ObjectSetInteger(0, panel_name, OBJPROP_BGCOLOR, Panel_Color);
      ObjectSetInteger(0, panel_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, panel_name, OBJPROP_BORDER_COLOR, clrGray);
      ObjectSetInteger(0, panel_name, OBJPROP_BACK, false);
      ObjectSetInteger(0, panel_name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, panel_name, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, panel_name, OBJPROP_HIDDEN, true);
   }
   
   // Create information labels
   CreateInfoLabel("EATitle", "ZigZag Statistics EA", 20, 40, 12, clrNavy);
   
   string status = Enable_Auto_Trading ? "ACTIVE" : "DISABLED";
   color status_color = Enable_Auto_Trading ? clrGreen : clrRed;
   CreateInfoLabel("EAStatus", "Status: " + status, 20, 60, 10, status_color);
   
   // Trading information
   string trades_info = StringFormat("Open Positions: %d", trade_manager.GetOpenPositionsCount());
   CreateInfoLabel("TradesInfo", trades_info, 20, 80, 9, clrBlack);
   
   string profit_info = StringFormat("Total Profit: %.2f", trade_manager.GetTotalProfit());
   color profit_color = trade_manager.GetTotalProfit() >= 0 ? clrGreen : clrRed;
   CreateInfoLabel("ProfitInfo", profit_info, 20, 100, 9, profit_color);
   
   // ZigZag information
   string zz1_info = StringFormat("ZigZag 1 (%.1f%%): %d points", ZigZag1_Percentage, zigzag1_count);
   CreateInfoLabel("ZZ1Info", zz1_info, 20, 130, 9, clrBlue);
   
   if(Use_Both_ZigZags)
   {
      string zz2_info = StringFormat("ZigZag 2 (%.1f%%): %d points", ZigZag2_Percentage, zigzag2_count);
      CreateInfoLabel("ZZ2Info", zz2_info, 20, 150, 9, clrRed);
   }
   
   // Market bias
   if(zigzag1_count > 0)
   {
      int bias = GetMarketBias(zigzag1_points, zigzag1_count, Trend_Lookback_Points);
      string bias_text = "";
      color bias_color = clrBlack;
      
      if(bias > 0)
      {
         bias_text = "Market Bias: BULLISH";
         bias_color = clrGreen;
      }
      else if(bias < 0)
      {
         bias_text = "Market Bias: BEARISH";
         bias_color = clrRed;
      }
      else
      {
         bias_text = "Market Bias: NEUTRAL";
         bias_color = clrGray;
      }
      
      CreateInfoLabel("BiasInfo", bias_text, 20, 180, 9, bias_color);
   }
   
   // Risk information
   RiskMetrics risk_metrics = risk_manager.GetRiskMetrics();
   string drawdown_info = StringFormat("Drawdown: %.2f%%", risk_metrics.current_drawdown);
   color dd_color = risk_metrics.current_drawdown > 10 ? clrRed : clrBlack;
   CreateInfoLabel("DrawdownInfo", drawdown_info, 20, 210, 9, dd_color);
   
   string winrate_info = StringFormat("Win Rate: %.1f%%", risk_metrics.win_rate);
   CreateInfoLabel("WinRateInfo", winrate_info, 20, 230, 9, clrBlack);
   
   // Statistics
   if(Show_Statistics && zigzag1_count > 2)
   {
      CreateInfoLabel("StatsTitle", "Statistics (ZigZag 1)", 20, 260, 10, clrDarkBlue);
      
      string avg_moves = StringFormat("Avg: ↑%.2f%% ↓%.2f%%", stats1.avg_move_up, stats1.avg_move_down);
      CreateInfoLabel("AvgMoves", avg_moves, 20, 280, 8, clrBlack);
      
      string max_moves = StringFormat("Max: ↑%.2f%% ↓%.2f%%", stats1.max_move_up, stats1.max_move_down);
      CreateInfoLabel("MaxMoves", max_moves, 20, 300, 8, clrBlack);
   }
   
   // Last update
   string update_time = StringFormat("Updated: %s", TimeToString(TimeCurrent(), TIME_SECONDS));
   CreateInfoLabel("UpdateTime", update_time, 20, 350, 8, clrGray);
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Create Information Label                                         |
//+------------------------------------------------------------------+
void CreateInfoLabel(string name, string text, int x, int y, int font_size, color text_color)
{
   ObjectDelete(0, name);
   
   if(ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
   {
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
      ObjectSetInteger(0, name, OBJPROP_COLOR, text_color);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   }
}

//+------------------------------------------------------------------+
//| Cleanup Display Objects                                         |
//+------------------------------------------------------------------+
void CleanupDisplay()
{
   ObjectDelete(0, "ZigZagEAPanel");
   
   string objects_to_delete[] = {
      "EATitle", "EAStatus", "TradesInfo", "ProfitInfo", "ZZ1Info", "ZZ2Info",
      "BiasInfo", "DrawdownInfo", "WinRateInfo", "StatsTitle", "AvgMoves", 
      "MaxMoves", "UpdateTime"
   };
   
   for(int i = 0; i < ArraySize(objects_to_delete); i++)
   {
      ObjectDelete(0, objects_to_delete[i]);
   }
   
   // Clean up trade arrows
   for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
   {
      string obj_name = ObjectName(0, i);
      if(StringFind(obj_name, "BUY_") >= 0 || StringFind(obj_name, "SELL_") >= 0)
      {
         ObjectDelete(0, obj_name);
      }
   }
   
   ChartRedraw();
}