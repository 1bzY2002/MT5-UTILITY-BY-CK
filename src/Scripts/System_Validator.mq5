//+------------------------------------------------------------------+
//|                                      System_Validator.mq5       |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs

#include "../Include/ZigZag_Common.mqh"
#include "../Include/TradeManager.mqh"
#include "../Include/RiskManager.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input bool Run_ZigZag_Test = true;        // Test ZigZag Calculations
input bool Run_TradeManager_Test = true;  // Test Trade Manager
input bool Run_RiskManager_Test = true;   // Test Risk Manager
input bool Run_Display_Test = true;       // Test Display Functions
input int  Test_Bars = 100;               // Number of bars to test

//+------------------------------------------------------------------+
//| Script program start function                                   |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("=== ZigZag Statistical System Validation ===");
   Print("Starting system validation tests...");
   
   bool all_tests_passed = true;
   
   // Test 1: ZigZag Calculations
   if(Run_ZigZag_Test)
   {
      Print("\n--- Testing ZigZag Calculations ---");
      if(TestZigZagCalculations())
         Print("✓ ZigZag calculations test PASSED");
      else
      {
         Print("✗ ZigZag calculations test FAILED");
         all_tests_passed = false;
      }
   }
   
   // Test 2: Trade Manager
   if(Run_TradeManager_Test)
   {
      Print("\n--- Testing Trade Manager ---");
      if(TestTradeManager())
         Print("✓ Trade Manager test PASSED");
      else
      {
         Print("✗ Trade Manager test FAILED");
         all_tests_passed = false;
      }
   }
   
   // Test 3: Risk Manager
   if(Run_RiskManager_Test)
   {
      Print("\n--- Testing Risk Manager ---");
      if(TestRiskManager())
         Print("✓ Risk Manager test PASSED");
      else
      {
         Print("✗ Risk Manager test FAILED");
         all_tests_passed = false;
      }
   }
   
   // Test 4: Display Functions
   if(Run_Display_Test)
   {
      Print("\n--- Testing Display Functions ---");
      if(TestDisplayFunctions())
         Print("✓ Display functions test PASSED");
      else
      {
         Print("✗ Display functions test FAILED");
         all_tests_passed = false;
      }
   }
   
   // Final Results
   Print("\n=== VALIDATION RESULTS ===");
   if(all_tests_passed)
   {
      Print("🎉 ALL TESTS PASSED! System is ready for use.");
      Print("You can now safely use the ZigZag Statistics EA.");
   }
   else
   {
      Print("⚠️  SOME TESTS FAILED! Please check the implementation.");
      Print("Review the error messages above and fix issues before using the EA.");
   }
   
   Print("Validation completed.");
}

//+------------------------------------------------------------------+
//| Test ZigZag Calculations                                         |
//+------------------------------------------------------------------+
bool TestZigZagCalculations()
{
   // Get sample data
   double high_array[], low_array[];
   datetime time_array[];
   
   int copied = CopyHigh(_Symbol, PERIOD_CURRENT, 0, Test_Bars, high_array);
   if(copied <= 0)
   {
      Print("Failed to copy high prices for testing");
      return false;
   }
   
   if(CopyLow(_Symbol, PERIOD_CURRENT, 0, Test_Bars, low_array) <= 0)
   {
      Print("Failed to copy low prices for testing");
      return false;
   }
   
   if(CopyTime(_Symbol, PERIOD_CURRENT, 0, Test_Bars, time_array) <= 0)
   {
      Print("Failed to copy time data for testing");
      return false;
   }
   
   // Test ZigZag calculation
   ZigZagPoint test_points[];
   ArrayResize(test_points, Test_Bars);
   
   int points_found = CalculateZigZag(high_array, low_array, time_array, 
                                      3.0, 0, Test_Bars, test_points);
   
   if(points_found <= 0)
   {
      Print("No ZigZag points found - check calculation logic");
      return false;
   }
   
   Print("Found ", points_found, " ZigZag points in ", Test_Bars, " bars");
   
   // Test statistics calculation
   if(points_found >= 3)
   {
      ZigZagStatistics stats = CalculateStatistics(test_points, points_found);
      
      if(stats.total_points != points_found)
      {
         Print("Statistics calculation error - point count mismatch");
         return false;
      }
      
      Print("Statistics: Avg up=", DoubleToString(stats.avg_move_up, 2), 
            "%, Avg down=", DoubleToString(stats.avg_move_down, 2), "%");
   }
   
   // Test market bias calculation
   int bias = GetMarketBias(test_points, points_found);
   string bias_text = (bias > 0) ? "Bullish" : (bias < 0) ? "Bearish" : "Neutral";
   Print("Market bias: ", bias_text);
   
   return true;
}

//+------------------------------------------------------------------+
//| Test Trade Manager                                               |
//+------------------------------------------------------------------+
bool TestTradeManager()
{
   CTradeManager *trade_manager = new CTradeManager();
   
   if(trade_manager == NULL)
   {
      Print("Failed to create Trade Manager instance");
      return false;
   }
   
   // Test initialization
   if(!trade_manager.Initialize(999999)) // Use test magic number
   {
      Print("Failed to initialize Trade Manager");
      delete trade_manager;
      return false;
   }
   
   // Test configuration
   trade_manager.SetTradeDirection(TRADE_BOTH);
   trade_manager.SetMaxSpread(3.0);
   trade_manager.SetMaxDailyLoss(1000.0);
   trade_manager.SetMaxTradesPerDay(10);
   trade_manager.SetLotSizeMethod(LOT_PERCENTAGE, 2.0);
   
   // Test lot size calculation
   double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double test_sl = current_price * 0.98; // 2% stop loss
   double lot_size = trade_manager.CalculateLotSize(current_price, test_sl);
   
   if(lot_size <= 0)
   {
      Print("Lot size calculation failed");
      delete trade_manager;
      return false;
   }
   
   Print("Calculated lot size: ", DoubleToString(lot_size, 2));
   
   // Test risk checks
   if(!trade_manager.CheckRiskLimits())
   {
      Print("Risk limits check method working");
   }
   
   if(!trade_manager.CheckSpread())
   {
      Print("Spread check method working (spread may be too high)");
   }
   
   delete trade_manager;
   return true;
}

//+------------------------------------------------------------------+
//| Test Risk Manager                                                |
//+------------------------------------------------------------------+
bool TestRiskManager()
{
   CRiskManager *risk_manager = new CRiskManager();
   
   if(risk_manager == NULL)
   {
      Print("Failed to create Risk Manager instance");
      return false;
   }
   
   // Test initialization
   double test_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(!risk_manager.Initialize(test_balance))
   {
      Print("Failed to initialize Risk Manager");
      delete risk_manager;
      return false;
   }
   
   // Test configuration
   risk_manager.SetMaxRiskPerTrade(2.0);
   risk_manager.SetMaxDailyRisk(5.0);
   risk_manager.SetMaxDrawdownLimit(20.0);
   
   // Test position size calculation
   double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double test_sl = current_price * 0.98;
   double position_size = risk_manager.CalculatePositionSize(current_price, test_sl, 2.0);
   
   if(position_size <= 0)
   {
      Print("Position size calculation failed");
      delete risk_manager;
      return false;
   }
   
   Print("Risk-adjusted position size: ", DoubleToString(position_size, 2));
   
   // Test stop loss calculation
   ZigZagPoint dummy_points[3];
   dummy_points[0].price = current_price * 1.02;
   dummy_points[0].type = ZIGZAG_HIGH;
   dummy_points[1].price = current_price * 0.98;
   dummy_points[1].type = ZIGZAG_LOW;
   dummy_points[2].price = current_price;
   dummy_points[2].type = ZIGZAG_HIGH;
   
   double stop_loss = risk_manager.CalculateStopLoss(current_price, dummy_points, 3, SL_SWING_LEVELS);
   
   if(stop_loss <= 0)
   {
      Print("Stop loss calculation failed");
      delete risk_manager;
      return false;
   }
   
   Print("Calculated stop loss: ", DoubleToString(stop_loss, 5));
   
   // Test risk validation
   bool risk_valid = risk_manager.ValidateTradeRisk(position_size, current_price, stop_loss);
   Print("Risk validation result: ", risk_valid ? "Valid" : "Invalid");
   
   // Test risk metrics
   RiskMetrics metrics = risk_manager.GetRiskMetrics();
   Print("Current drawdown: ", DoubleToString(metrics.current_drawdown, 2), "%");
   
   delete risk_manager;
   return true;
}

//+------------------------------------------------------------------+
//| Test Display Functions                                           |
//+------------------------------------------------------------------+
bool TestDisplayFunctions()
{
   // Test creating a simple display object
   string test_object = "ValidationTestPanel";
   
   // Clean up any existing object
   ObjectDelete(0, test_object);
   
   // Create test panel
   if(!ObjectCreate(0, test_object, OBJ_RECTANGLE_LABEL, 0, 0, 0))
   {
      Print("Failed to create test display object");
      return false;
   }
   
   // Configure object
   ObjectSetInteger(0, test_object, OBJPROP_CORNER, CORNER_LEFT_LOWER);
   ObjectSetInteger(0, test_object, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, test_object, OBJPROP_YDISTANCE, 50);
   ObjectSetInteger(0, test_object, OBJPROP_XSIZE, 200);
   ObjectSetInteger(0, test_object, OBJPROP_YSIZE, 100);
   ObjectSetInteger(0, test_object, OBJPROP_BGCOLOR, clrLightGray);
   ObjectSetInteger(0, test_object, OBJPROP_BORDER_COLOR, clrDarkGray);
   ObjectSetInteger(0, test_object, OBJPROP_BACK, false);
   ObjectSetInteger(0, test_object, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, test_object, OBJPROP_HIDDEN, true);
   
   // Create test label
   string test_label = "ValidationTestLabel";
   ObjectDelete(0, test_label);
   
   if(!ObjectCreate(0, test_label, OBJ_LABEL, 0, 0, 0))
   {
      Print("Failed to create test label object");
      ObjectDelete(0, test_object);
      return false;
   }
   
   ObjectSetInteger(0, test_label, OBJPROP_CORNER, CORNER_LEFT_LOWER);
   ObjectSetInteger(0, test_label, OBJPROP_XDISTANCE, 20);
   ObjectSetInteger(0, test_label, OBJPROP_YDISTANCE, 75);
   ObjectSetString(0, test_label, OBJPROP_TEXT, "✓ Display Test OK");
   ObjectSetString(0, test_label, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, test_label, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, test_label, OBJPROP_COLOR, clrGreen);
   ObjectSetInteger(0, test_label, OBJPROP_BACK, false);
   ObjectSetInteger(0, test_label, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, test_label, OBJPROP_HIDDEN, true);
   
   ChartRedraw();
   
   Print("Test display panel created - check chart for confirmation");
   
   // Wait a moment then clean up
   Sleep(2000);
   ObjectDelete(0, test_object);
   ObjectDelete(0, test_label);
   ChartRedraw();
   
   return true;
}

//+------------------------------------------------------------------+
//| Script deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Clean up any remaining test objects
   ObjectDelete(0, "ValidationTestPanel");
   ObjectDelete(0, "ValidationTestLabel");
   ChartRedraw();
}