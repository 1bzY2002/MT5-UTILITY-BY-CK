//+------------------------------------------------------------------+
//|                                             ZigZag_Common.mqh    |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| ZigZag Structure Definitions                                      |
//+------------------------------------------------------------------+
enum ENUM_MARKET_STRUCTURE
{
   STRUCTURE_NONE = 0,      // No structure
   STRUCTURE_HH = 1,        // Higher High
   STRUCTURE_LH = 2,        // Lower High
   STRUCTURE_HL = 3,        // Higher Low
   STRUCTURE_LL = 4         // Lower Low
};

enum ENUM_ZIGZAG_POINT_TYPE
{
   ZIGZAG_NONE = 0,         // Not a ZigZag point
   ZIGZAG_HIGH = 1,         // ZigZag High
   ZIGZAG_LOW = 2           // ZigZag Low
};

//+------------------------------------------------------------------+
//| ZigZag Point Structure                                           |
//+------------------------------------------------------------------+
struct ZigZagPoint
{
   datetime time;           // Time of the point
   double price;            // Price of the point
   ENUM_ZIGZAG_POINT_TYPE type;  // Type of point (High/Low)
   ENUM_MARKET_STRUCTURE structure;  // Market structure
   int bar_index;           // Bar index
   double percentage_move;  // Percentage move from previous point
};

//+------------------------------------------------------------------+
//| ZigZag Statistics Structure                                      |
//+------------------------------------------------------------------+
struct ZigZagStatistics
{
   double avg_move_up;      // Average upward move
   double avg_move_down;    // Average downward move
   double max_move_up;      // Maximum upward move
   double max_move_down;    // Maximum downward move
   double min_move_up;      // Minimum upward move
   double min_move_down;    // Minimum downward move
   double std_dev_up;       // Standard deviation of upward moves
   double std_dev_down;     // Standard deviation of downward moves
   int total_points;        // Total ZigZag points
   int total_up_moves;      // Total upward moves
   int total_down_moves;    // Total downward moves
   double quartile_1_up;    // First quartile upward moves
   double quartile_3_up;    // Third quartile upward moves
   double quartile_1_down;  // First quartile downward moves
   double quartile_3_down;  // Third quartile downward moves
};

//+------------------------------------------------------------------+
//| Global Arrays for ZigZag Points                                 |
//+------------------------------------------------------------------+
ZigZagPoint zigzag_points[];
ZigZagStatistics current_stats;

//+------------------------------------------------------------------+
//| Calculate ZigZag Points                                          |
//+------------------------------------------------------------------+
int CalculateZigZag(const double &high[], const double &low[], const datetime &time[], 
                    double percentage, int start_pos, int count, ZigZagPoint &points[])
{
   if(percentage <= 0) return 0;
   
   int points_found = 0;
   double current_extreme = 0;
   ENUM_ZIGZAG_POINT_TYPE current_direction = ZIGZAG_NONE;
   int extreme_index = 0;
   
   // Find first extreme point
   for(int i = start_pos; i < start_pos + count - 1; i++)
   {
      if(current_direction == ZIGZAG_NONE)
      {
         if(high[i] > high[i+1] * (1 + percentage/100))
         {
            current_extreme = high[i];
            current_direction = ZIGZAG_HIGH;
            extreme_index = i;
         }
         else if(low[i] < low[i+1] * (1 - percentage/100))
         {
            current_extreme = low[i];
            current_direction = ZIGZAG_LOW;
            extreme_index = i;
         }
         continue;
      }
      
      // Looking for opposite direction
      if(current_direction == ZIGZAG_HIGH)
      {
         // Check for new higher high
         if(high[i] > current_extreme * (1 + percentage/100))
         {
            current_extreme = high[i];
            extreme_index = i;
         }
         // Check for significant low
         else if(low[i] < current_extreme * (1 - percentage/100))
         {
            // Add previous high point
            if(points_found < ArraySize(points))
            {
               points[points_found].time = time[extreme_index];
               points[points_found].price = current_extreme;
               points[points_found].type = ZIGZAG_HIGH;
               points[points_found].bar_index = extreme_index;
               points[points_found].structure = DetermineMarketStructure(points, points_found);
               
               if(points_found > 0)
               {
                  points[points_found].percentage_move = 
                     ((current_extreme - points[points_found-1].price) / points[points_found-1].price) * 100;
               }
               
               points_found++;
            }
            
            current_extreme = low[i];
            current_direction = ZIGZAG_LOW;
            extreme_index = i;
         }
      }
      else if(current_direction == ZIGZAG_LOW)
      {
         // Check for new lower low
         if(low[i] < current_extreme * (1 - percentage/100))
         {
            current_extreme = low[i];
            extreme_index = i;
         }
         // Check for significant high
         else if(high[i] > current_extreme * (1 + percentage/100))
         {
            // Add previous low point
            if(points_found < ArraySize(points))
            {
               points[points_found].time = time[extreme_index];
               points[points_found].price = current_extreme;
               points[points_found].type = ZIGZAG_LOW;
               points[points_found].bar_index = extreme_index;
               points[points_found].structure = DetermineMarketStructure(points, points_found);
               
               if(points_found > 0)
               {
                  points[points_found].percentage_move = 
                     ((current_extreme - points[points_found-1].price) / points[points_found-1].price) * 100;
               }
               
               points_found++;
            }
            
            current_extreme = high[i];
            current_direction = ZIGZAG_HIGH;
            extreme_index = i;
         }
      }
   }
   
   return points_found;
}

//+------------------------------------------------------------------+
//| Determine Market Structure                                        |
//+------------------------------------------------------------------+
ENUM_MARKET_STRUCTURE DetermineMarketStructure(const ZigZagPoint &points[], int current_index)
{
   if(current_index < 2) return STRUCTURE_NONE;
   
   ZigZagPoint current = points[current_index];
   ZigZagPoint previous = points[current_index - 1];
   ZigZagPoint prev_prev = points[current_index - 2];
   
   if(current.type == ZIGZAG_HIGH && prev_prev.type == ZIGZAG_HIGH)
   {
      if(current.price > prev_prev.price)
         return STRUCTURE_HH;  // Higher High
      else
         return STRUCTURE_LH;  // Lower High
   }
   else if(current.type == ZIGZAG_LOW && prev_prev.type == ZIGZAG_LOW)
   {
      if(current.price > prev_prev.price)
         return STRUCTURE_HL;  // Higher Low
      else
         return STRUCTURE_LL;  // Lower Low
   }
   
   return STRUCTURE_NONE;
}

//+------------------------------------------------------------------+
//| Calculate ZigZag Statistics                                      |
//+------------------------------------------------------------------+
ZigZagStatistics CalculateStatistics(const ZigZagPoint &points[], int count)
{
   ZigZagStatistics stats = {0};
   if(count < 2) return stats;
   
   double upward_moves[];
   double downward_moves[];
   ArrayResize(upward_moves, count);
   ArrayResize(downward_moves, count);
   
   int up_count = 0, down_count = 0;
   
   // Collect moves
   for(int i = 1; i < count; i++)
   {
      double move = points[i].percentage_move;
      
      if(move > 0)
      {
         upward_moves[up_count] = move;
         up_count++;
         
         if(move > stats.max_move_up || stats.max_move_up == 0)
            stats.max_move_up = move;
         if(move < stats.min_move_up || stats.min_move_up == 0)
            stats.min_move_up = move;
      }
      else if(move < 0)
      {
         move = MathAbs(move);
         downward_moves[down_count] = move;
         down_count++;
         
         if(move > stats.max_move_down || stats.max_move_down == 0)
            stats.max_move_down = move;
         if(move < stats.min_move_down || stats.min_move_down == 0)
            stats.min_move_down = move;
      }
   }
   
   // Calculate averages
   if(up_count > 0)
   {
      double sum = 0;
      for(int i = 0; i < up_count; i++)
         sum += upward_moves[i];
      stats.avg_move_up = sum / up_count;
      
      // Calculate standard deviation
      double variance = 0;
      for(int i = 0; i < up_count; i++)
         variance += MathPow(upward_moves[i] - stats.avg_move_up, 2);
      stats.std_dev_up = MathSqrt(variance / up_count);
      
      // Calculate quartiles
      ArraySort(upward_moves, up_count);
      int q1_index = (int)(up_count * 0.25);
      int q3_index = (int)(up_count * 0.75);
      stats.quartile_1_up = upward_moves[q1_index];
      stats.quartile_3_up = upward_moves[q3_index];
   }
   
   if(down_count > 0)
   {
      double sum = 0;
      for(int i = 0; i < down_count; i++)
         sum += downward_moves[i];
      stats.avg_move_down = sum / down_count;
      
      // Calculate standard deviation
      double variance = 0;
      for(int i = 0; i < down_count; i++)
         variance += MathPow(downward_moves[i] - stats.avg_move_down, 2);
      stats.std_dev_down = MathSqrt(variance / down_count);
      
      // Calculate quartiles
      ArraySort(downward_moves, down_count);
      int q1_index = (int)(down_count * 0.25);
      int q3_index = (int)(down_count * 0.75);
      stats.quartile_1_down = downward_moves[q1_index];
      stats.quartile_3_down = downward_moves[q3_index];
   }
   
   stats.total_points = count;
   stats.total_up_moves = up_count;
   stats.total_down_moves = down_count;
   
   return stats;
}

//+------------------------------------------------------------------+
//| Get Latest ZigZag Point                                          |
//+------------------------------------------------------------------+
ZigZagPoint GetLatestZigZagPoint(const ZigZagPoint &points[], int count)
{
   ZigZagPoint empty_point = {0};
   if(count <= 0) return empty_point;
   
   return points[count - 1];
}

//+------------------------------------------------------------------+
//| Check if New ZigZag Point is Formed                             |
//+------------------------------------------------------------------+
bool IsNewZigZagPoint(const ZigZagPoint &points[], int count, const ZigZagPoint &new_point)
{
   if(count == 0) return true;
   
   ZigZagPoint last_point = points[count - 1];
   
   // Check if it's a different time and significant move
   if(new_point.time != last_point.time && 
      MathAbs(new_point.percentage_move) > 0)
   {
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Get Market Bias from ZigZag                                     |
//+------------------------------------------------------------------+
int GetMarketBias(const ZigZagPoint &points[], int count, int lookback_points = 3)
{
   if(count < lookback_points) return 0;
   
   int bullish_count = 0;
   int bearish_count = 0;
   
   // Analyze recent market structure
   for(int i = count - lookback_points; i < count; i++)
   {
      if(points[i].structure == STRUCTURE_HH || points[i].structure == STRUCTURE_HL)
         bullish_count++;
      else if(points[i].structure == STRUCTURE_LH || points[i].structure == STRUCTURE_LL)
         bearish_count++;
   }
   
   if(bullish_count > bearish_count) return 1;   // Bullish bias
   if(bearish_count > bullish_count) return -1;  // Bearish bias
   
   return 0; // Neutral bias
}