//+------------------------------------------------------------------+
//|                                   ZigZag_Statistics_MT5.mq5     |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   2

#include "../Include/ZigZag_Common.mqh"

//--- indicator plots
#property indicator_label1  "ZigZag 1"
#property indicator_type1   DRAW_SECTION
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "ZigZag 2"
#property indicator_type2   DRAW_SECTION
#property indicator_color2  clrRed
#property indicator_style2  STYLE_DOT
#property indicator_width2  1

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input group "ZigZag Settings"
input double ZigZag1_Percentage = 3.0;        // ZigZag 1 Percentage
input double ZigZag2_Percentage = 5.0;        // ZigZag 2 Percentage
input int    Calculation_Depth = 500;         // Calculation Depth

input group "Display Settings"
input bool   Show_Statistics_Panel = true;    // Show Statistics Panel
input bool   Show_Market_Structure = true;    // Show Market Structure
input bool   Show_Daily_Analysis = true;      // Show Daily Analysis
input color  Panel_Background_Color = clrWhite; // Panel Background Color
input color  Panel_Text_Color = clrBlack;    // Panel Text Color

input group "Statistical Analysis"
input bool   Enable_Quartile_Analysis = true; // Enable Quartile Analysis
input bool   Enable_Trend_Analysis = true;    // Enable Trend Analysis
input int    Statistical_Period = 100;        // Statistical Period

//+------------------------------------------------------------------+
//| Indicator Buffers                                                |
//+------------------------------------------------------------------+
double ZigZag1Buffer[];
double ZigZag2Buffer[];
double HighBuffer[];
double LowBuffer[];

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
ZigZagPoint zigzag1_points[];
ZigZagPoint zigzag2_points[];
ZigZagStatistics stats1, stats2;
datetime last_calculation_time;
int zigzag1_count, zigzag2_count;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize indicator buffers
   SetIndexBuffer(0, ZigZag1Buffer, INDICATOR_DATA);
   SetIndexBuffer(1, ZigZag2Buffer, INDICATOR_DATA);
   SetIndexBuffer(2, HighBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, LowBuffer, INDICATOR_CALCULATIONS);
   
   // Set empty values
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
   
   // Initialize arrays
   ArrayResize(zigzag1_points, Statistical_Period);
   ArrayResize(zigzag2_points, Statistical_Period);
   ArrayInitialize(ZigZag1Buffer, 0.0);
   ArrayInitialize(ZigZag2Buffer, 0.0);
   
   zigzag1_count = 0;
   zigzag2_count = 0;
   last_calculation_time = 0;
   
   // Set indicator properties
   IndicatorSetString(INDICATOR_SHORTNAME, "ZigZag Statistics MT5");
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total < Calculation_Depth)
      return 0;
   
   // Clear buffers
   ArrayInitialize(ZigZag1Buffer, 0.0);
   ArrayInitialize(ZigZag2Buffer, 0.0);
   
   // Copy price data to calculation buffers
   ArrayCopy(HighBuffer, high, 0, 0, rates_total);
   ArrayCopy(LowBuffer, low, 0, 0, rates_total);
   
   // Calculate ZigZag points
   int start_pos = MathMax(0, rates_total - Calculation_Depth);
   int count = MathMin(Calculation_Depth, rates_total - start_pos);
   
   // Calculate ZigZag 1
   zigzag1_count = CalculateZigZag(high, low, time, ZigZag1_Percentage, 
                                   start_pos, count, zigzag1_points);
   
   // Calculate ZigZag 2
   zigzag2_count = CalculateZigZag(high, low, time, ZigZag2_Percentage, 
                                   start_pos, count, zigzag2_points);
   
   // Draw ZigZag lines
   DrawZigZagLines(zigzag1_points, zigzag1_count, ZigZag1Buffer, time, rates_total);
   DrawZigZagLines(zigzag2_points, zigzag2_count, ZigZag2Buffer, time, rates_total);
   
   // Calculate statistics
   if(zigzag1_count > 2)
      stats1 = CalculateStatistics(zigzag1_points, zigzag1_count);
   
   if(zigzag2_count > 2)
      stats2 = CalculateStatistics(zigzag2_points, zigzag2_count);
   
   // Update display on new bar
   if(time[rates_total-1] != last_calculation_time)
   {
      if(Show_Statistics_Panel)
         DisplayStatisticsPanel();
      
      last_calculation_time = time[rates_total-1];
   }
   
   return rates_total;
}

//+------------------------------------------------------------------+
//| Draw ZigZag Lines                                                |
//+------------------------------------------------------------------+
void DrawZigZagLines(const ZigZagPoint &points[], int count, double &buffer[], 
                     const datetime &time[], int rates_total)
{
   if(count < 2) return;
   
   for(int i = 0; i < count - 1; i++)
   {
      datetime start_time = points[i].time;
      datetime end_time = points[i + 1].time;
      double start_price = points[i].price;
      double end_price = points[i + 1].price;
      
      // Find start and end indices
      int start_index = -1, end_index = -1;
      
      for(int j = 0; j < rates_total; j++)
      {
         if(time[j] == start_time) start_index = j;
         if(time[j] == end_time) end_index = j;
      }
      
      if(start_index >= 0 && end_index >= 0)
      {
         // Draw line between points
         int steps = MathAbs(end_index - start_index);
         if(steps > 0)
         {
            double price_step = (end_price - start_price) / steps;
            
            for(int k = 0; k <= steps; k++)
            {
               int index = start_index + (end_index > start_index ? k : -k);
               if(index >= 0 && index < rates_total)
               {
                  buffer[index] = start_price + (price_step * k);
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Display Statistics Panel                                         |
//+------------------------------------------------------------------+
void DisplayStatisticsPanel()
{
   string panel_name = "ZigZagStatsPanel";
   
   // Remove existing panel
   ObjectDelete(0, panel_name);
   
   // Create panel background
   if(!ObjectCreate(0, panel_name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
      return;
   
   ObjectSetInteger(0, panel_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, panel_name, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, panel_name, OBJPROP_YDISTANCE, 30);
   ObjectSetInteger(0, panel_name, OBJPROP_XSIZE, 300);
   ObjectSetInteger(0, panel_name, OBJPROP_YSIZE, 350);
   ObjectSetInteger(0, panel_name, OBJPROP_BGCOLOR, Panel_Background_Color);
   ObjectSetInteger(0, panel_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, panel_name, OBJPROP_BORDER_COLOR, clrGray);
   ObjectSetInteger(0, panel_name, OBJPROP_BACK, false);
   ObjectSetInteger(0, panel_name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, panel_name, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, panel_name, OBJPROP_HIDDEN, true);
   
   // Create text labels
   CreateStatsLabel("ZigZagTitle", "ZigZag Statistical Analysis", 20, 40, 12, clrNavy);
   
   // ZigZag 1 Statistics
   string zz1_info = StringFormat("ZigZag 1 (%.1f%%) - Points: %d", ZigZag1_Percentage, zigzag1_count);
   CreateStatsLabel("ZZ1Info", zz1_info, 20, 65, 9, Panel_Text_Color);
   
   if(zigzag1_count > 2)
   {
      string zz1_stats = StringFormat("Avg Up: %.2f%% | Avg Down: %.2f%%", 
                                      stats1.avg_move_up, stats1.avg_move_down);
      CreateStatsLabel("ZZ1Stats1", zz1_stats, 20, 80, 8, Panel_Text_Color);
      
      string zz1_range = StringFormat("Max Up: %.2f%% | Max Down: %.2f%%", 
                                      stats1.max_move_up, stats1.max_move_down);
      CreateStatsLabel("ZZ1Stats2", zz1_range, 20, 95, 8, Panel_Text_Color);
      
      string zz1_quartiles = StringFormat("Q1-Q3 Up: %.2f%%-%.2f%% | Down: %.2f%%-%.2f%%", 
                                          stats1.quartile_1_up, stats1.quartile_3_up,
                                          stats1.quartile_1_down, stats1.quartile_3_down);
      CreateStatsLabel("ZZ1Stats3", zz1_quartiles, 20, 110, 8, Panel_Text_Color);
   }
   
   // ZigZag 2 Statistics
   string zz2_info = StringFormat("ZigZag 2 (%.1f%%) - Points: %d", ZigZag2_Percentage, zigzag2_count);
   CreateStatsLabel("ZZ2Info", zz2_info, 20, 140, 9, Panel_Text_Color);
   
   if(zigzag2_count > 2)
   {
      string zz2_stats = StringFormat("Avg Up: %.2f%% | Avg Down: %.2f%%", 
                                      stats2.avg_move_up, stats2.avg_move_down);
      CreateStatsLabel("ZZ2Stats1", zz2_stats, 20, 155, 8, Panel_Text_Color);
      
      string zz2_range = StringFormat("Max Up: %.2f%% | Max Down: %.2f%%", 
                                      stats2.max_move_up, stats2.max_move_down);
      CreateStatsLabel("ZZ2Stats2", zz2_range, 20, 170, 8, Panel_Text_Color);
   }
   
   // Market Structure Analysis
   if(Show_Market_Structure && zigzag1_count > 0)
   {
      CreateStatsLabel("StructureTitle", "Market Structure", 20, 200, 10, clrDarkBlue);
      
      ZigZagPoint latest = GetLatestZigZagPoint(zigzag1_points, zigzag1_count);
      string structure_text = "";
      
      switch(latest.structure)
      {
         case STRUCTURE_HH: structure_text = "Higher High (Bullish)"; break;
         case STRUCTURE_LH: structure_text = "Lower High (Bearish)"; break;
         case STRUCTURE_HL: structure_text = "Higher Low (Bullish)"; break;
         case STRUCTURE_LL: structure_text = "Lower Low (Bearish)"; break;
         default: structure_text = "No Clear Structure"; break;
      }
      
      CreateStatsLabel("StructureInfo", structure_text, 20, 215, 9, Panel_Text_Color);
      
      // Market Bias
      int bias = GetMarketBias(zigzag1_points, zigzag1_count);
      string bias_text = "";
      color bias_color = Panel_Text_Color;
      
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
      
      CreateStatsLabel("BiasInfo", bias_text, 20, 230, 9, bias_color);
   }
   
   // Daily Analysis
   if(Show_Daily_Analysis)
   {
      CreateStatsLabel("DailyTitle", "Daily Analysis", 20, 260, 10, clrDarkBlue);
      
      MqlDateTime today;
      TimeToStruct(TimeCurrent(), today);
      
      string daily_info = StringFormat("Analysis Date: %04d.%02d.%02d", 
                                       today.year, today.mon, today.day);
      CreateStatsLabel("DailyDate", daily_info, 20, 275, 8, Panel_Text_Color);
      
      // Add more daily analysis here
      string update_time = StringFormat("Last Update: %02d:%02d", today.hour, today.min);
      CreateStatsLabel("UpdateTime", update_time, 20, 290, 8, clrGray);
   }
   
   // Performance indicators
   CreateStatsLabel("Performance", "Real-time Statistical Tracking Active", 20, 320, 8, clrGreen);
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Create Statistics Label                                          |
//+------------------------------------------------------------------+
void CreateStatsLabel(string name, string text, int x, int y, int font_size, color text_color)
{
   ObjectDelete(0, name);
   
   if(ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
   {
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
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
//| Indicator deinitialization function                             |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Clean up objects
   ObjectDelete(0, "ZigZagStatsPanel");
   
   string objects_to_delete[] = {
      "ZigZagTitle", "ZZ1Info", "ZZ1Stats1", "ZZ1Stats2", "ZZ1Stats3",
      "ZZ2Info", "ZZ2Stats1", "ZZ2Stats2", "StructureTitle", "StructureInfo",
      "BiasInfo", "DailyTitle", "DailyDate", "UpdateTime", "Performance"
   };
   
   for(int i = 0; i < ArraySize(objects_to_delete); i++)
   {
      ObjectDelete(0, objects_to_delete[i]);
   }
   
   ChartRedraw();
}