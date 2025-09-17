# ZigZag Statistical EA - Installation & Setup Guide

## Quick Start Installation

### Step 1: File Installation
1. Copy the entire `src` folder to your MetaTrader 5 data directory:
   - Windows: `C:\Users\[Username]\AppData\Roaming\MetaQuotes\Terminal\[Terminal_ID]\MQL5\`
   - The structure should be:
   ```
   MQL5/
   ├── Experts/ZigZag_Statistics_EA.mq5
   ├── Indicators/ZigZag_Statistics_MT5.mq5
   ├── Include/
   │   ├── ZigZag_Common.mqh
   │   ├── TradeManager.mqh
   │   └── RiskManager.mqh
   └── Scripts/ZigZag_Backtester.mq5
   ```

### Step 2: Compilation
1. Open MetaEditor in MetaTrader 5
2. Compile all files in this order:
   - First: All `.mqh` files in Include folder
   - Then: `ZigZag_Statistics_MT5.mq5` (Indicator)
   - Finally: `ZigZag_Statistics_EA.mq5` (Expert Advisor)

### Step 3: Testing the Indicator
1. Attach `ZigZag Statistics MT5` indicator to any chart
2. Verify the statistical panel appears and shows ZigZag points
3. Test different percentage settings to understand sensitivity

### Step 4: Setting Up the Expert Advisor
1. Attach `ZigZag Statistics EA` to your chosen chart
2. Configure basic settings (see configurations below)
3. Enable automated trading in MT5
4. Monitor the information panel

## Recommended Configuration Presets

### Conservative Settings (Low Risk)
```
=== ZigZag Settings ===
ZigZag1_Percentage = 4.0
ZigZag2_Percentage = 6.0
Use_Both_ZigZags = true

=== Trading Settings ===
Trade_Direction = TRADE_BOTH
Min_Time_Between_Trades = 120
Max_Spread = 2.0

=== Signal Filters ===
Min_Percentage_Move = 3.5
Min_Statistical_Significance = 2.0
Use_Market_Structure_Filter = true
Use_Trend_Filter = true

=== Risk Management ===
Risk_Percentage = 1.5
Max_Daily_Loss_Percent = 3.0
Max_Trades_Per_Day = 5
Risk_Reward_Ratio = 2.5
```

### Aggressive Settings (Higher Risk/Reward)
```
=== ZigZag Settings ===
ZigZag1_Percentage = 2.5
ZigZag2_Percentage = 4.0
Use_Both_ZigZags = false

=== Trading Settings ===
Trade_Direction = TRADE_BOTH
Min_Time_Between_Trades = 60
Max_Spread = 3.0

=== Signal Filters ===
Min_Percentage_Move = 2.0
Min_Statistical_Significance = 1.2
Use_Market_Structure_Filter = false
Use_Trend_Filter = true

=== Risk Management ===
Risk_Percentage = 2.5
Max_Daily_Loss_Percent = 6.0
Max_Trades_Per_Day = 15
Risk_Reward_Ratio = 2.0
```

### Scalping Settings (High Frequency)
```
=== ZigZag Settings ===
ZigZag1_Percentage = 1.5
ZigZag2_Percentage = 2.5
Use_Both_ZigZags = true

=== Trading Settings ===
Trade_Direction = TRADE_BOTH
Min_Time_Between_Trades = 30
Max_Spread = 1.5

=== Signal Filters ===
Min_Percentage_Move = 1.0
Min_Statistical_Significance = 1.0
Use_Market_Structure_Filter = true
Use_Trend_Filter = false

=== Risk Management ===
Risk_Percentage = 1.0
Max_Daily_Loss_Percent = 4.0
Max_Trades_Per_Day = 25
Risk_Reward_Ratio = 1.5
```

## Asset-Specific Recommendations

### Forex Major Pairs (EUR/USD, GBP/USD, USD/JPY)
- ZigZag Percentage: 2.5-4.0%
- Risk per trade: 1-2%
- Best timeframes: H1, H4
- Session filter: London/New York overlap

### Forex Minor Pairs (EUR/GBP, AUD/CAD)
- ZigZag Percentage: 3.0-5.0%
- Risk per trade: 1-1.5%
- Best timeframes: H4, D1
- Session filter: Active market hours

### Commodities (Gold, Oil)
- ZigZag Percentage: 1.5-3.0%
- Risk per trade: 1-2%
- Best timeframes: H1, H4
- Special: Use volatility adjustment

### Stock Indices (S&P500, DAX)
- ZigZag Percentage: 2.0-4.0%
- Risk per trade: 1.5-2.5%
- Best timeframes: H4, D1
- Session filter: Market hours only

## Performance Monitoring

### Daily Checks
- [ ] Check overnight positions
- [ ] Review daily P&L
- [ ] Monitor drawdown levels
- [ ] Verify spread conditions

### Weekly Reviews
- [ ] Analyze win rate trends
- [ ] Review parameter effectiveness
- [ ] Check correlation with market conditions
- [ ] Update risk limits if needed

### Monthly Optimization
- [ ] Run backtests on recent data
- [ ] Compare with manual trading results
- [ ] Adjust parameters based on performance
- [ ] Review and update documentation

## Troubleshooting Common Issues

### Issue: No Trading Signals
**Possible Causes:**
- ZigZag percentages too high
- Statistical thresholds too strict
- Market conditions not suitable

**Solutions:**
- Reduce ZigZag percentages by 0.5-1.0%
- Lower Min_Statistical_Significance
- Check if trend filter is too restrictive

### Issue: Too Many Trades
**Possible Causes:**
- ZigZag percentages too low
- Filters not restrictive enough
- High market volatility

**Solutions:**
- Increase ZigZag percentages
- Raise statistical significance thresholds
- Enable more filters (structure, trend)

### Issue: Large Losses
**Possible Causes:**
- Position sizes too large
- Stop losses too wide
- Poor market conditions

**Solutions:**
- Reduce risk percentage
- Use tighter stop loss methods
- Enable drawdown protection

### Issue: Poor Win Rate
**Possible Causes:**
- Counter-trend trading
- Inadequate filtering
- Wrong timeframe

**Solutions:**
- Enable trend filter
- Use market structure confirmation
- Test on different timeframes

## Advanced Configuration

### Multi-Timeframe Setup
1. Run EA on H1 chart for entries
2. Use H4 ZigZag for trend confirmation
3. Monitor D1 for major structure levels

### Portfolio Management
1. Use different Magic Numbers for each pair
2. Coordinate position sizes across pairs
3. Monitor total portfolio exposure

### News Integration
1. Reduce position sizes before major news
2. Widen stop losses during volatile periods
3. Consider pausing trading around events

## Support and Maintenance

### Backup Strategy
- Save working parameter sets
- Keep logs of performance periods
- Document any custom modifications

### Update Procedures
- Test new versions on demo accounts
- Maintain rollback capability
- Document version changes

### Community Resources
- Share performance results
- Contribute to optimization research
- Report bugs and improvements

Remember: Always test thoroughly on demo accounts before using real money!