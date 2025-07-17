# MT5 ZigZag Statistical Trading System

## Overview
A comprehensive MetaTrader 5 trading system that combines ZigZag pattern analysis with advanced statistical methods to provide automated trading capabilities. The system includes both indicator analysis and Expert Advisor functionality.

## System Components

### 1. Core Include Files
- **ZigZag_Common.mqh**: Core ZigZag calculation algorithms and statistical analysis
- **TradeManager.mqh**: Complete trade execution and management system
- **RiskManager.mqh**: Advanced risk management and position sizing

### 2. ZigZag Statistical Indicator
- **ZigZag_Statistics_MT5.mq5**: Advanced indicator with dual ZigZag calculations
- Real-time statistical analysis and market structure identification
- Interactive panel showing key metrics and market bias

### 3. Expert Advisor
- **ZigZag_Statistics_EA.mq5**: Fully automated trading system
- Signal generation based on ZigZag patterns and statistical thresholds
- Comprehensive risk management and trade management features

### 4. Backtesting Tools
- **ZigZag_Backtester.mq5**: Historical strategy validation script
- Performance analysis and detailed reporting
- CSV export functionality for further analysis

## Key Features

### ZigZag Analysis
- **Dual ZigZag System**: Two configurable ZigZag calculations for different timeframes
- **Market Structure Detection**: Automatic identification of HH, LH, HL, LL patterns
- **Statistical Metrics**: Real-time calculation of average moves, standard deviations, and quartiles
- **Trend Analysis**: Market bias detection using configurable lookback periods

### Trading Signals
- **Pattern-Based Entry**: Trades triggered on ZigZag pivot confirmations
- **Statistical Filtering**: Minimum move thresholds based on historical data
- **Market Structure Confirmation**: Entry validation using structure breaks
- **Trend Alignment**: Optional trend filters to avoid counter-trend trades

### Risk Management
- **Multiple Lot Sizing Methods**: Fixed, percentage-based, or volatility-adjusted
- **Dynamic Stop Losses**: ATR-based, swing levels, or percentage methods
- **Take Profit Strategies**: Risk-reward ratios, statistical levels, or ATR-based
- **Daily Limits**: Maximum loss and trade count restrictions
- **Drawdown Protection**: Real-time monitoring and trade suspension

### Trade Management
- **Trailing Stops**: Based on new ZigZag pivot formation
- **Break-Even Moves**: Automatic stop adjustment after profit targets
- **Partial Profit Taking**: Configurable percentage-based exits
- **Position Monitoring**: Real-time P&L and risk assessment

## Installation

1. Copy all files to your MetaTrader 5 installation:
   ```
   MQL5/
   ├── Experts/
   │   └── ZigZag_Statistics_EA.mq5
   ├── Indicators/
   │   └── ZigZag_Statistics_MT5.mq5
   ├── Include/
   │   ├── ZigZag_Common.mqh
   │   ├── TradeManager.mqh
   │   └── RiskManager.mqh
   └── Scripts/
       └── ZigZag_Backtester.mq5
   ```

2. Compile all files in the MetaEditor

3. Restart MetaTrader 5

## Configuration

### Indicator Settings
- **ZigZag 1 Percentage**: Primary ZigZag sensitivity (default: 3.0%)
- **ZigZag 2 Percentage**: Secondary ZigZag sensitivity (default: 5.0%)
- **Calculation Depth**: Number of bars to analyze (default: 500)
- **Display Options**: Panel colors, statistical analysis toggles

### Expert Advisor Settings

#### ZigZag Configuration
- **ZigZag 1/2 Percentage**: Pattern sensitivity settings
- **Use Both ZigZags**: Enable dual ZigZag confirmation

#### Trading Parameters
- **Trade Direction**: Long only, short only, or both directions
- **Min Time Between Trades**: Minimum interval between signals
- **Session Filters**: Optional trading time restrictions

#### Signal Filters
- **Min Percentage Move**: Threshold for entry signals (default: 2.5%)
- **Statistical Significance**: Multiplier for average move filtering
- **Market Structure Filter**: Use structure confirmation
- **Trend Filter**: Align trades with market bias

#### Risk Management
- **Lot Size Method**: Fixed, percentage, or volatility-based
- **Risk Percentage**: Capital risk per trade (default: 2%)
- **Max Daily Loss**: Daily loss limit (default: 5%)
- **Stop Loss Method**: ATR, swing levels, or fixed points
- **Take Profit Method**: Risk-reward, statistical, or ATR-based

## Usage Guide

### Running the Indicator
1. Attach ZigZag_Statistics_MT5 to any chart
2. Configure ZigZag percentages based on instrument volatility
3. Monitor the statistical panel for market analysis
4. Use structure and bias information for manual trading decisions

### Running the Expert Advisor
1. Attach ZigZag_Statistics_EA to the desired chart
2. Configure all parameters according to your risk tolerance
3. Enable automated trading in MT5 terminal
4. Monitor the information panel for real-time status
5. Review trade performance through the integrated statistics

### Backtesting Strategy
1. Run ZigZag_Backtester script on historical data
2. Configure test parameters and date range
3. Analyze results for strategy optimization
4. Export detailed results to CSV for further analysis

## Performance Optimization

### Parameter Tuning
- **ZigZag Percentages**: Lower values for more signals, higher for fewer but stronger signals
- **Statistical Significance**: Higher values reduce trade frequency but improve quality
- **Risk-Reward Ratios**: Balance between win rate and profit potential

### Market Adaptation
- **Volatility Adjustment**: Use ATR-based sizing for changing market conditions
- **Correlation Monitoring**: Avoid overexposure to correlated instruments
- **Session Filtering**: Focus on high-activity trading periods

### Risk Controls
- **Position Sizing**: Never risk more than 1-3% per trade
- **Daily Limits**: Set maximum daily loss at 3-5% of account
- **Drawdown Limits**: Consider stopping trading at 15-20% drawdown

## Monitoring and Maintenance

### Daily Checks
- Review overnight positions and market gaps
- Monitor daily P&L against limits
- Check for news events affecting traded instruments

### Weekly Analysis
- Review trading statistics and performance metrics
- Analyze win rates and average trade results
- Adjust parameters based on market condition changes

### Monthly Optimization
- Backtest parameter changes on recent data
- Review and update risk management settings
- Analyze correlation with other trading strategies

## Troubleshooting

### Common Issues
- **No Signals Generated**: Check ZigZag percentages and statistical thresholds
- **High Frequency Trading**: Increase minimum move thresholds
- **Poor Win Rate**: Review market structure and trend filters
- **Large Drawdowns**: Reduce position sizes and tighten risk controls

### Performance Issues
- **Slow Calculation**: Reduce calculation depth or optimize parameters
- **Memory Usage**: Clear old ZigZag points periodically
- **Display Problems**: Restart terminal if panels don't update

## Risk Disclaimer
This trading system is for educational and research purposes. Past performance does not guarantee future results. Always trade with proper risk management and never risk more than you can afford to lose.

## Support and Updates
For questions, improvements, or bug reports, please refer to the repository documentation and issue tracking system.
