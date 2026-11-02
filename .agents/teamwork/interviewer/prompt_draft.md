Analyze the Lula V3 expert advisor system pipeline, provide visual drawings/diagrams of the execution pipeline, and diagnose why trades are missed or not placed based on the source code and MetaTester 5 backtest logs.

Working directory: c:\Users\Admin\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\Advisors\Lula-Candlestick-EA-V1
Integrity mode: development

## Requirements

### R1. System Pipeline Explanation & Documentation
Read the Lula V3 expert advisor source code in `Source/` and provide a comprehensive explanation of the end-to-end trading pipeline. The explanation must document how multi-timeframe analysis (HTF, MTF, LTF), market structure sensors, liquidity sweeps, trade setup arming, trigger latches (such as CHoCH), POI/zone evaluation, and order placement interact.

### R2. Visual Pipeline Drawings
Provide visual drawings/diagrams (in Markdown text diagrams, Mermaid flowcharts/state charts, or images as chosen by the team) illustrating the execution lifecycle, state machine transitions, armed state and trigger latch expiration timelines, and the conditions required to reach trade entry.

### R3. Root-Cause Diagnosis of Missed Trades
Analyze the provided MetaTester 5 backtest logs against the implementation to pinpoint exactly why trades were not executed. Specifically explain the log events where armed states expired, CHoCH latches expired without POI confirmation, zones showed `activeBear=0`, and what specific conditions failed to be met for an entry.

## Acceptance Criteria

### Pipeline Documentation & Visuals
- [ ] Comprehensive documentation of the Lula V3 execution pipeline covering all stages from multi-timeframe structure evaluation to trade execution.
- [ ] Visual diagrams depicting system state transitions, latch durations/expirations, and entry gate conditions.

### Diagnosis & Findings
- [ ] Clear diagnosis explaining why trades were not placed during the logged backtest period, tracing specific log lines (including armed state expirations, CHoCH latches, and `activeBear=0`) to the underlying source logic.
- [ ] Identification of any missing logic, restrictive thresholds, or architectural gaps preventing trade fulfillment.

## Reference Material

### MetaTester 5 Backtest Log Excerpt
```text
2026.11.02 13:54:44.881	MetaTester 5 started on 127.0.0.1:3000
2026.11.02 13:54:44.888	cloud network mode is off
2026.11.02 13:54:44.888	initialization finished
2026.11.02 13:54:45.110	login (build 6230)
2026.11.02 13:54:45.480	895764 bytes of account info loaded
2026.11.02 13:54:45.480	1478 bytes of tester parameters loaded
2026.11.02 13:54:45.480	5828 bytes of input parameters loaded
2026.11.02 13:54:45.482	5766 bytes of symbols list loaded (725 symbols)
2026.11.02 13:54:45.482	expert file added: Experts\Advisors\Lula-Candlestick-EA-V1\Source\Lula_V3.ex5. 202462 bytes loaded
2026.11.02 13:54:45.579	3892 Mb available, 48 blocks set for ticks generating
2026.11.02 13:54:45.579	calculate profit in pips, initial deposit 3000, leverage 1:100
2026.11.02 13:54:45.580	successfully initialized
2026.11.02 13:54:45.580	226 Kb of total initialization data received
2026.11.02 13:54:45.580	Intel Core i5-7200U  @ 2.50GHz, 12163 MB
2026.11.02 13:54:45.603	debug version of 'Lula_V3.ex5', please recompile it
2026.11.02 13:54:45.613	Volatility 75 Index: symbol to be synchronized
2026.11.02 13:54:45.614	Volatility 75 Index: symbol synchronized, 3880 bytes of symbol info received
2026.11.02 13:54:45.651	Volatility 75 Index: history synchronization started
2026.11.02 13:54:45.721	Volatility 75 Index: load 53 bytes of history data to synchronize in 0:00:00.007
2026.11.02 13:54:45.721	Volatility 75 Index: history synchronized from 2024.01.01 to 2026.08.19
2026.11.02 13:54:45.725	Volatility 75 Index: ticks synchronization started
2026.11.02 13:54:48.753	Volatility 75 Index: load 60 bytes of tick data to synchronize in 0:00:03.031
2026.11.02 13:54:48.753	Volatility 75 Index: history ticks synchronized from 2026.06.25 to 2026.07.30
2026.11.02 13:54:49.042	Volatility 75 Index,H1: history cache allocated for 13577 bars and contains 12960 bars from 2025.01.01 00:00 to 2026.06.24 23:00
2026.11.02 13:54:49.042	Volatility 75 Index,H1: history begins from 2025.01.01 00:00
2026.11.02 13:54:49.060	Volatility 75 Index,H1 (Deriv-Demo): generating based on real ticks
2026.11.02 13:54:49.061	Volatility 75 Index,H1: testing of Experts\Advisors\Lula-Candlestick-EA-V1\Source\Lula_V3.ex5 from 2026.06.25 00:00 to 2026.07.31 00:00 started with inputs:
2026.11.02 13:54:49.061	  --- V3 Risk Management ---=
2026.11.02 13:54:49.061	  inp_RiskPercent=1.0
2026.11.02 13:54:49.061	  inp_MagicNumber=777777
2026.11.02 13:54:49.061	  --- SMC Execution Parameters ---=
2026.11.02 13:54:49.061	  inp_MinPullbackPct=30.0
2026.11.02 13:54:49.061	  --- Top-Down Timeframes ---=
2026.11.02 13:54:49.061	  inp_HTF=16385
2026.11.02 13:54:49.061	  inp_MTF=15
2026.11.02 13:54:49.061	  inp_LTF=5
2026.11.02 13:54:49.061	  --- Visual Mode & Charting ---=
2026.11.02 13:54:49.061	  inp_ShowVisuals=true
2026.11.02 13:54:49.084	2026.06.25 00:00:00   ==================================================
2026.11.02 13:54:49.084	2026.06.25 00:00:00    Starting Lula V3 SMC Execution Engine...
2026.11.02 13:54:49.084	2026.06.25 00:00:00   ==================================================
2026.11.02 13:54:49.173	Volatility 75 Index,M15: history cache allocated for 54308 bars and contains 51839 bars from 2025.01.01 00:00 to 2026.06.24 23:45
2026.11.02 13:54:49.173	Volatility 75 Index,M15: history begins from 2025.01.01 00:00
2026.11.02 13:54:49.268	Volatility 75 Index,M5: history cache allocated for 162919 bars and contains 155513 bars from 2025.01.01 00:00 to 2026.06.24 23:55
2026.11.02 13:54:49.268	Volatility 75 Index,M5: history begins from 2025.01.01 00:00
2026.11.02 13:54:49.270	2026.06.25 00:00:00   [V3 Sensor] Market Structure Initialized: Volatility 75 Index (TF: PERIOD_H1, Pullback: 30.0%)
2026.11.02 13:54:49.270	2026.06.25 00:00:00   [V3 Sensor] Market Structure Initialized: Volatility 75 Index (TF: PERIOD_M5, Pullback: 30.0%)
2026.11.02 13:54:49.270	2026.06.25 00:00:00   [V3 Sensor] Liquidity Sensor Initialized: Volatility 75 Index
2026.11.02 13:54:49.270	2026.06.25 00:00:00   [V3 State Machine] Initialized. HTF: PERIOD_H1 | MTF: PERIOD_M15 | LTF: PERIOD_M5
2026.11.02 13:54:49.270	2026.06.25 00:00:00   [V3 Decision Tree] Initialized for Volatility 75 Index (LTF: PERIOD_M5 | StopATR: 1.0-3.0)
2026.11.02 13:54:49.270	2026.06.25 00:00:00   [V3 Executor] Init Volatility 75 Index | Class=1 | Risk req=1.00% eff=0.50% | MaxMargin=15% | MaxLots=1.00 | Magic=777777
2026.11.02 13:54:50.064	Volatility 75 Index : real ticks begin from 2026.06.25 00:00:00
2026.11.02 13:54:50.070	2026.06.25 00:00:02   [V3 State] Close(1): 40827.28000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:54:50.070	2026.06.25 00:00:02   [V3 State Machine] PERIOD_H1 BEARISH Trend + Opportunity Found. Arming PERIOD_M5 for Short Triggers.
2026.11.02 13:54:53.176	2026.06.25 01:05:00   [V3 State] Close(1): 40601.58000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:54:56.261	2026.06.25 02:05:00   [V3 State Machine] Short armed state EXPIRED after 24 bars.
2026.11.02 13:54:56.261	2026.06.25 02:05:00   [V3 State] Close(1): 40901.86000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:54:56.261	2026.06.25 02:05:00   [V3 State Machine] PERIOD_H1 BEARISH Trend + Opportunity Found. Arming PERIOD_M5 for Short Triggers.
2026.11.02 13:54:57.629	2026.06.25 02:35:00   [V3 Trigger] LATCH SET: Bearish CHoCH on PERIOD_M5 (close 40695.27000 < swing 40718.00000). Waiting for POI.
2026.11.02 13:54:57.629	2026.06.25 02:35:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=132.66429
2026.11.02 13:54:57.837	2026.06.25 02:40:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=135.65714
2026.11.02 13:54:58.101	2026.06.25 02:45:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=127.73500
2026.11.02 13:54:58.349	2026.06.25 02:50:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=132.72429
2026.11.02 13:54:58.585	2026.06.25 02:55:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=127.85500
2026.11.02 13:54:58.823	2026.06.25 03:00:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=120.22929
2026.11.02 13:54:58.981	2026.06.25 03:05:00   [V3 State] Close(1): 40672.54000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:54:58.981	2026.06.25 03:05:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=120.27071
2026.11.02 13:54:59.149	2026.06.25 03:10:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=113.55500
2026.11.02 13:54:59.285	2026.06.25 03:15:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=116.13929
2026.11.02 13:54:59.463	2026.06.25 03:20:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=120.72429
2026.11.02 13:54:59.648	2026.06.25 03:25:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=120.17929
2026.11.02 13:54:59.801	2026.06.25 03:30:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=124.73714
2026.11.02 13:54:59.867	2026.06.25 03:35:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=126.42643
2026.11.02 13:55:00.057	2026.06.25 03:40:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=126.08429
2026.11.02 13:55:00.216	2026.06.25 03:45:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=127.23000
2026.11.02 13:55:00.412	2026.06.25 03:50:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=123.47071
2026.11.02 13:55:00.602	2026.06.25 03:55:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=125.18143
2026.11.02 13:55:00.691	2026.06.25 04:00:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=122.16286
2026.11.02 13:55:00.734	2026.06.25 04:05:00   [V3 State] Close(1): 40236.46000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:55:00.735	2026.06.25 04:05:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=125.43500
2026.11.02 13:55:00.916	2026.06.25 04:10:00   [V3 State Machine] Short armed state EXPIRED after 24 bars.
2026.11.02 13:55:00.916	2026.06.25 04:10:00   [V3 State Machine] PERIOD_H1 BEARISH Trend + Opportunity Found. Arming PERIOD_M5 for Short Triggers.
2026.11.02 13:55:00.917	2026.06.25 04:10:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=129.68214
2026.11.02 13:55:01.144	2026.06.25 04:15:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=139.05429
2026.11.02 13:55:01.306	2026.06.25 04:20:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=142.32786
2026.11.02 13:55:01.514	2026.06.25 04:25:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=137.11071
2026.11.02 13:55:01.649	2026.06.25 04:30:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=137.13643
2026.11.02 13:55:01.769	2026.06.25 04:35:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=136.01786
2026.11.02 13:55:01.890	2026.06.25 04:40:00   [V3 Trigger] Short CHoCH latch EXPIRED after 24 bars.
2026.11.02 13:55:03.056	2026.06.25 05:05:00   [V3 State] Close(1): 40487.19000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:55:05.035	2026.06.25 06:05:00   [V3 State] Close(1): 41205.83000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:55:05.306	2026.06.25 06:15:00   [V3 State Machine] Short armed state EXPIRED after 24 bars.
2026.11.02 13:55:05.306	2026.06.25 06:15:00   [V3 State Machine] PERIOD_H1 BEARISH Trend + Opportunity Found. Arming PERIOD_M5 for Short Triggers.
2026.11.02 13:55:06.863	2026.06.25 07:05:00   [V3 State] Close(1): 41083.52000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:55:08.922	2026.06.25 08:05:00   [V3 State] Close(1): 41125.55000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:55:09.463	2026.06.25 08:20:00   [V3 State Machine] Short armed state EXPIRED after 24 bars.
2026.11.02 13:55:09.463	2026.06.25 08:20:00   [V3 State Machine] PERIOD_H1 BEARISH Trend + Opportunity Found. Arming PERIOD_M5 for Short Triggers.
2026.11.02 13:55:10.105	2026.06.25 08:40:00   [V3 Trigger] LATCH SET: Bearish CHoCH on PERIOD_M5 (close 40945.06000 < swing 40955.86000). Waiting for POI.
2026.11.02 13:55:10.105	2026.06.25 08:40:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=141.09429
2026.11.02 13:55:10.260	2026.06.25 08:45:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=133.29643
2026.11.02 13:55:10.452	2026.06.25 08:50:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=136.16571
2026.11.02 13:55:10.629	2026.06.25 08:55:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=138.12500
2026.11.02 13:55:10.753	2026.06.25 09:00:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=139.25357
2026.11.02 13:55:10.892	2026.06.25 09:05:00   [V3 State] Close(1): 40927.38000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:55:10.892	2026.06.25 09:05:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=134.17143
2026.11.02 13:55:11.078	2026.06.25 09:10:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=136.39786
2026.11.02 13:55:11.207	2026.06.25 09:15:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=138.46000
2026.11.02 13:55:11.336	2026.06.25 09:20:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=140.79929
2026.11.02 13:55:11.465	2026.06.25 09:25:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=133.17714
2026.11.02 13:55:11.648	2026.06.25 09:30:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=134.83786
2026.11.02 13:55:11.883	2026.06.25 09:35:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=126.56286
2026.11.02 13:55:12.089	2026.06.25 09:40:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=120.49214
2026.11.02 13:55:12.301	2026.06.25 09:45:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=120.88286
2026.11.02 13:55:12.467	2026.06.25 09:50:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=119.36214
2026.11.02 13:55:12.613	2026.06.25 09:55:00   [V3 Wait] SHORT | zones total=2 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=129.61857
2026.11.02 13:55:12.741	2026.06.25 10:00:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=132.16071
2026.11.02 13:55:12.870	2026.06.25 10:05:00   [V3 State] Close(1): 41607.30000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:55:12.870	2026.06.25 10:05:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=133.68571
2026.11.02 13:55:12.994	2026.06.25 10:10:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=134.92857
2026.11.02 13:55:13.131	2026.06.25 10:15:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=134.31571
2026.11.02 13:55:13.278	2026.06.25 10:20:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=133.13929
2026.11.02 13:55:13.475	2026.06.25 10:25:00   [V3 State Machine] Short armed state EXPIRED after 24 bars.
2026.11.02 13:55:13.476	2026.06.25 10:25:00   [V3 State Machine] PERIOD_H1 BEARISH Trend + Opportunity Found. Arming PERIOD_M5 for Short Triggers.
2026.11.02 13:55:13.481	2026.06.25 10:25:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=135.78143
2026.11.02 13:55:13.737	2026.06.25 10:30:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=139.74571
2026.11.02 13:55:13.919	2026.06.25 10:35:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=139.81071
2026.11.02 13:55:14.129	2026.06.25 10:40:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=137.16929
2026.11.02 13:55:14.403	2026.06.25 10:45:00   [V3 Trigger] Short CHoCH latch EXPIRED after 24 bars.
2026.11.02 13:55:14.930	2026.06.25 11:05:00   [V3 State] Close(1): 41594.59000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:55:17.411	2026.06.25 12:05:00   [V3 State] Close(1): 41470.53000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:55:18.331	2026.06.25 12:30:00   [V3 State Machine] Short armed state EXPIRED after 24 bars.
2026.11.02 13:55:18.331	2026.06.25 12:30:00   [V3 State Machine] PERIOD_H1 BEARISH Trend + Opportunity Found. Arming PERIOD_M5 for Short Triggers.
2026.11.02 13:55:18.893	2026.06.25 12:55:00   [V3 Trigger] LATCH SET: Bearish CHoCH on PERIOD_M5 (close 41314.65000 < swing 41360.86000). Waiting for POI.
2026.11.02 13:55:18.893	2026.06.25 12:55:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=132.88357
2026.11.02 13:55:19.121	2026.06.25 13:00:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=138.09571
2026.11.02 13:55:19.367	2026.06.25 13:05:00   [V3 State] Close(1): 41395.75000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:55:19.367	2026.06.25 13:05:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=135.83643
2026.11.02 13:55:19.589	2026.06.25 13:10:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=138.75143
2026.11.02 13:55:19.715	2026.06.25 13:15:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=147.90929
2026.11.02 13:55:19.836	2026.06.25 13:20:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | border atrLTF=150.08429
2026.11.02 13:55:19.978	2026.06.25 13:25:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=152.08643
2026.11.02 13:55:20.119	2026.06.25 13:30:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=153.11429
2026.11.02 13:55:20.237	2026.06.25 13:35:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=148.68643
2026.11.02 13:55:20.395	2026.06.25 13:40:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=149.91571
2026.11.02 13:55:20.641	2026.06.25 13:45:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=153.62357
2026.11.02 13:55:20.862	2026.06.25 13:50:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=160.78357
2026.11.02 13:55:20.988	2026.06.25 13:55:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=158.89000
2026.11.02 13:55:21.134	2026.06.25 14:00:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=162.37786
2026.11.02 13:55:21.280	2026.06.25 14:05:00   [V3 State] Close(1): 41280.61000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:55:21.280	2026.06.25 14:05:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=169.40500
2026.11.02 13:55:21.478	2026.06.25 14:10:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=163.42214
2026.11.02 13:55:21.609	2026.06.25 14:15:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=161.39857
2026.11.02 13:55:21.743	2026.06.25 14:20:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=153.80786
2026.11.02 13:55:21.906	2026.06.25 14:25:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=147.10429
2026.11.02 13:55:22.160	2026.06.25 14:30:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=145.32071
2026.11.02 13:55:22.401	2026.06.25 14:35:00   [V3 State Machine] Short armed state EXPIRED after 24 bars.
2026.11.02 13:55:22.401	2026.06.25 14:35:00   [V3 State Machine] PERIOD_H1 BEARISH Trend + Opportunity Found. Arming PERIOD_M5 for Short Triggers.
2026.11.02 13:55:22.402	2026.06.25 14:35:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=149.24500
2026.11.02 13:55:22.652	2026.06.25 14:40:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=154.46000
2026.11.02 13:55:22.856	2026.06.25 14:45:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=156.97714
2026.11.02 13:55:23.090	2026.06.25 14:50:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=152.71500
2026.11.02 13:55:23.343	2026.06.25 14:55:00   [V3 Wait] SHORT | zones total=3 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=148.36643
2026.11.02 13:55:23.572	2026.06.25 15:00:00   [V3 Trigger] Short CHoCH latch EXPIRED after 24 bars.
2026.11.02 13:55:23.832	2026.06.25 15:05:00   [V3 State] Close(1): 41542.75000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:55:27.138	2026.06.25 16:05:00   [V3 State] Close(1): 41276.43000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:55:28.921	2026.06.25 16:40:00   [V3 State Machine] Short armed state EXPIRED after 24 bars.
2026.11.02 13:55:28.921	2026.06.25 16:40:00   [V3 State Machine] PERIOD_H1 BEARISH Trend + Opportunity Found. Arming PERIOD_M5 for Short Triggers.
2026.11.02 13:55:30.134	2026.06.25 17:05:00   [V3 State] Close(1): 42262.58000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:55:33.632	2026.06.25 18:05:00   [V3 State] Close(1): 41864.19000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:55:35.694	2026.06.25 18:45:00   [V3 State Machine] Short armed state EXPIRED after 24 bars.
2026.11.02 13:55:35.694	2026.06.25 18:45:00   [V3 State Machine] PERIOD_H1 BEARISH Trend + Opportunity Found. Arming PERIOD_M5 for Short Triggers.
2026.11.02 13:55:36.751	2026.06.25 19:05:00   [V3 State] Close(1): 42074.46000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:55:38.768	2026.06.25 20:05:00   [V3 State] Close(1): 42152.15000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:55:40.292	2026.06.25 20:50:00   [V3 State Machine] Short armed state EXPIRED after 24 bars.
2026.11.02 13:55:40.292	2026.06.25 20:50:00   [V3 State Machine] PERIOD_H1 BEARISH Trend + Opportunity Found. Arming PERIOD_M5 for Short Triggers.
2026.11.02 13:55:40.839	2026.06.25 21:05:00   [V3 State] Close(1): 42661.71000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:55:43.264	2026.06.25 22:05:00   [V3 State] Close(1): 43214.02000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:55:44.087	2026.06.25 22:35:00   [V3 Trigger] LATCH SET: Bearish CHoCH on PERIOD_M5 (close 42785.56000 < swing 42841.40000). Waiting for POI.
2026.11.02 13:55:44.087	2026.06.25 22:35:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=428.65000 | atrLTF=159.14357
2026.11.02 13:55:44.233	2026.06.25 22:40:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=389.67000 | atrLTF=153.65714
2026.11.02 13:55:44.364	2026.06.25 22:45:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=328.04000 | atrLTF=150.78714
2026.11.02 13:55:44.529	2026.06.25 22:50:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=480.79000 | atrLTF=146.42429
2026.11.02 13:55:44.704	2026.06.25 22:55:00   [V3 State Machine] Short armed state EXPIRED after 24 bars.
2026.11.02 13:55:44.704	2026.06.25 22:55:00   [V3 State Machine] PERIOD_H1 BEARISH Trend + Opportunity Found. Arming PERIOD_M5 for Short Triggers.
2026.11.02 13:55:44.705	2026.06.25 22:55:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=477.97000 | atrLTF=148.51500
2026.11.02 13:55:44.812	2026.06.25 23:00:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=459.84000 | atrLTF=145.81571
2026.11.02 13:55:44.960	2026.06.25 23:05:00   [V3 State] Close(1): 42739.47000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:55:44.961	2026.06.25 23:05:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=474.74000 | atrLTF=144.55500
2026.11.02 13:55:45.208	2026.06.25 23:10:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=542.57000 | atrLTF=147.75500
2026.11.02 13:55:45.332	2026.06.25 23:15:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=465.10000 | atrLTF=146.50071
2026.11.02 13:55:45.591	2026.06.25 23:20:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=444.23000 | atrLTF=144.83286
2026.11.02 13:55:45.863	2026.06.25 23:25:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=394.02000 | atrLTF=147.59786
2026.11.02 13:55:46.103	2026.06.25 23:30:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=457.15000 | atrLTF=147.26714
2026.11.02 13:55:46.373	2026.06.25 23:35:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=441.11000 | atrLTF=140.96071
2026.11.02 13:55:46.623	2026.06.25 23:40:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=514.11000 | atrLTF=136.73929
2026.11.02 13:55:46.878	2026.06.25 23:45:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=646.88000 | atrLTF=142.76357
2026.11.02 13:55:47.129	2026.06.25 23:50:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=637.59000 | atrLTF=142.92571
2026.11.02 13:55:47.361	2026.06.25 23:55:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=571.24000 | atrLTF=144.42000
2026.11.02 13:55:47.625	2026.06.26 00:00:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=602.05000 | atrLTF=138.01143
2026.11.02 13:55:47.882	2026.06.26 00:05:00   [V3 State] Close(1): 42576.91000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:55:47.882	2026.06.26 00:05:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=637.30000 | atrLTF=138.49500
2026.11.02 13:55:48.116	2026.06.26 00:10:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=568.77000 | atrLTF=138.81143
2026.11.02 13:55:48.434	2026.06.26 00:15:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=571.18000 | atrLTF=136.47214
2026.11.02 13:55:48.728	2026.06.26 00:20:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=420.23000 | atrLTF=137.72929
2026.11.02 13:55:48.954	2026.06.26 00:25:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=493.14000 | atrLTF=136.55000
2026.11.02 13:55:49.221	2026.06.26 00:30:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=298.71000 | atrLTF=149.88286
2026.11.02 13:55:49.455	2026.06.26 00:35:00   [V3 Wait] SHORT | zones total=4 activeBear=1 | nearest mid=43214.21000 | dist=224.87000 | atrLTF=151.27571
2026.11.02 13:55:49.721	2026.06.26 00:40:00   [V3 Trigger] Short CHoCH latch EXPIRED after 24 bars.
2026.11.02 13:55:50.459	2026.06.26 01:00:00   [V3 State Machine] Short armed state EXPIRED after 24 bars.
2026.11.02 13:55:50.600	2026.06.26 01:05:00   [V3 State] Close(1): 43424.89000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:55:51.106	2026.06.26 01:15:00   [V3 Liquidity] EQH Swept at 43360.52000! Sell Stop-Hunt Detected.
2026.11.02 13:55:51.106	2026.06.26 01:15:00   [V3 State Machine] PERIOD_H1 BEARISH Trend + Opportunity Found. Arming PERIOD_M5 for Short Triggers.
2026.11.02 13:55:53.414	2026.06.26 02:05:00   [V3 State] Close(1): 43182.05000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:55:53.549	2026.06.26 02:15:00   [V3 Liquidity] Swept signal at 43360.52000 expired after 12 bars.
2026.11.02 13:55:56.663	2026.06.26 03:05:00   [V3 State] Close(1): 43716.56000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:55:57.507	2026.06.26 03:20:00   [V3 State Machine] Short armed state EXPIRED after 24 bars.
2026.11.02 13:56:00.131	2026.06.26 04:05:00   [V3 State] Close(1): 44557.31000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:56:02.056	2026.06.26 05:05:00   [V3 State] Close(1): 44834.74000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:56:05.757	2026.06.26 06:05:00   [V3 State] Close(1): 44591.08000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:56:09.173	2026.06.26 07:05:00   [V3 State] Close(1): 43984.55000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:56:12.371	2026.06.26 08:05:00   [V3 State] Close(1): 43451.84000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:56:15.822	2026.06.26 09:05:00   [V3 State] Close(1): 44097.43000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:56:19.329	2026.06.26 10:05:00   [V3 State] Close(1): 44111.28000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:56:22.982	2026.06.26 11:05:00   [V3 State] Close(1): 43998.81000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:56:25.883	2026.06.26 11:55:00   [V3 State Machine] PERIOD_H1 BEARISH Trend + Opportunity Found. Arming PERIOD_M5 for Short Triggers.
2026.11.02 13:56:26.213	2026.06.26 12:05:00   [V3 State] Close(1): 44098.07000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:56:29.309	2026.06.26 13:05:00   [V3 State] Close(1): 44554.36000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:56:31.950	2026.06.26 14:00:00   [V3 State Machine] Short armed state EXPIRED after 24 bars.
2026.11.02 13:56:32.259	2026.06.26 14:05:00   [V3 State] Close(1): 44865.19000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:56:35.901	2026.06.26 15:05:00   [V3 State] Close(1): 44375.07000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:56:39.289	2026.06.26 16:05:00   [V3 State] Close(1): 44846.91000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:56:42.738	2026.06.26 17:05:00   [V3 State] Close(1): 44341.47000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:56:45.863	2026.06.26 18:05:00   [V3 State] Close(1): 43961.85000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:56:49.722	2026.06.26 19:05:00   [V3 State] Close(1): 43750.48000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:56:52.988	2026.06.26 20:00:00   [V3 Liquidity] EQL Swept at 43380.56000! Buy Stop-Hunt Detected.
2026.11.02 13:56:53.276	2026.06.26 20:05:00   [V3 State] Close(1): 43505.49000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:56:56.219	2026.06.26 20:50:00   [V3 State Machine] PERIOD_H1 BEARISH Trend + Opportunity Found. Arming PERIOD_M5 for Short Triggers.
2026.11.02 13:56:56.906	2026.06.26 21:00:00   [V3 Liquidity] Swept signal at 43380.56000 expired after 12 bars.
2026.11.02 13:56:57.138	2026.06.26 21:05:00   [V3 State] Close(1): 43444.72000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:57:00.540	2026.06.26 21:55:00   [V3 Trigger] LATCH SET: Bearish CHoCH on PERIOD_M5 (close 43187.58000 < swing 43248.01000). Waiting for POI.
2026.11.02 13:57:00.540	2026.06.26 21:55:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=273.27000 | atrLTF=151.94786
2026.11.02 13:57:00.965	2026.06.26 22:00:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=407.64000 | atrLTF=147.74214
2026.11.02 13:57:01.306	2026.06.26 22:05:00   [V3 State] Close(1): 43026.06000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: NO
2026.11.02 13:57:01.306	2026.06.26 22:05:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=434.79000 | atrLTF=147.26357
2026.11.02 13:57:01.741	2026.06.26 22:10:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=502.12000 | atrLTF=149.04429
2026.11.02 13:57:02.100	2026.06.26 22:15:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=519.05000 | atrLTF=155.92571
2026.11.02 13:57:02.506	2026.06.26 22:20:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=578.71000 | atrLTF=155.95000
2026.11.02 13:57:02.907	2026.06.26 22:25:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=521.54000 | atrLTF=159.05286
2026.11.02 13:57:03.030	2026.06.26 22:30:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=566.93000 | atrLTF=157.45786
2026.11.02 13:57:03.360	2026.06.26 22:35:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=569.20000 | atrLTF=151.09357
2026.11.02 13:57:03.728	2026.06.26 22:40:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=480.71000 | atrLTF=145.26143
2026.11.02 13:57:04.063	2026.06.26 22:45:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=461.33000 | atrLTF=144.82714
2026.11.02 13:57:04.273	2026.06.26 22:50:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=504.07000 | atrLTF=138.11714
2026.11.02 13:57:04.634	2026.06.26 22:55:00   [V3 State Machine] Short armed state EXPIRED after 24 bars.
2026.11.02 13:57:05.018	2026.06.26 23:00:00   [V3 State Machine] PERIOD_H1 BEARISH Trend + Opportunity Found. Arming PERIOD_M5 for Short Triggers.
2026.11.02 13:57:05.026	2026.06.26 23:00:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=422.36000 | atrLTF=142.47429
2026.11.02 13:57:05.363	2026.06.26 23:05:00   [V3 State] Close(1): 43029.43000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:57:05.369	2026.06.26 23:05:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=431.42000 | atrLTF=132.25786
2026.11.02 13:57:05.631	2026.06.26 23:10:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=461.98000 | atrLTF=125.88429
2026.11.02 13:57:05.653	2026.06.26 23:15:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=558.15000 | atrLTF=127.43500
2026.11.02 13:57:05.901	2026.06.26 23:20:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=694.30000 | atrLTF=133.40643
2026.11.02 13:57:06.245	2026.06.26 23:25:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=606.67000 | atrLTF=128.39857
2026.11.02 13:57:06.449	2026.06.26 23:30:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=598.99000 | atrLTF=122.35500
2026.11.02 13:57:06.780	2026.06.26 23:35:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=614.44000 | atrLTF=118.86786
2026.11.02 13:57:07.111	2026.06.26 23:40:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=730.97000 | atrLTF=121.66643
2026.11.02 13:57:07.447	2026.06.26 23:45:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=758.07000 | atrLTF=124.15714
2026.11.02 13:57:07.832	2026.06.26 23:50:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=589.20000 | atrLTF=129.59857
2026.11.02 13:57:08.118	2026.06.26 23:55:00   [V3 Wait] SHORT | zones total=8 activeBear=2 | nearest mid=43460.85000 | dist=556.14000 | atrLTF=129.64500
2026.11.02 13:57:08.450	2026.06.27 00:00:01   [V3 Liquidity] EQL Swept at 42741.63000! Buy Stop-Hunt Detected.
2026.11.02 13:57:08.451	2026.06.27 00:00:01   [V3 Trigger] Short CHoCH latch EXPIRED after 24 bars.
2026.11.02 13:57:08.774	2026.06.27 00:05:00   [V3 State] Close(1): 42995.55000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:57:12.770	2026.06.27 01:05:00   [V3 State Machine] Short armed state EXPIRED after 24 bars.
2026.11.02 13:57:12.770	2026.06.27 01:05:00   [V3 State] Close(1): 43373.07000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:57:12.770	2026.06.27 01:05:00   [V3 State Machine] PERIOD_H1 BEARISH Trend + Opportunity Found. Arming PERIOD_M5 for Short Triggers.
2026.11.02 13:57:13.290	2026.06.27 01:15:00   [V3 Liquidity] Swept signal at 42741.63000 expired after 12 bars.
2026.11.02 13:57:16.419	2026.06.27 02:05:00   [V3 State] Close(1): 43479.87000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:57:20.463	2026.06.27 03:05:00   [V3 State] Close(1): 43767.73000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:57:20.738	2026.06.27 03:10:00   [V3 State Machine] Short armed state EXPIRED after 24 bars.
2026.11.02 13:57:20.738	2026.06.27 03:10:00   [V3 State Machine] PERIOD_H1 BEARISH Trend + Opportunity Found. Arming PERIOD_M5 for Short Triggers.
2026.11.02 13:57:24.346	2026.06.27 04:05:00   [V3 State] Close(1): 43996.07000 | Trend: BEARISH | HTF Discount: NO | HTF Premium: YES
2026.11.02 13:57:25.775	2026.06.27 04:40:00   [V3 Trigger] LATCH SET: Bearish CHoCH on PERIOD_M5 (close 43543.36000 < swing 43630.26000). Waiting for POI.
2026.11.02 13:57:25.775	2026.06.27 04:40:00   [V3 Wait] SHORT | zones total=8 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=157.64643
2026.11.02 13:57:26.065	2026.06.27 04:45:00   [V3 Wait] SHORT | zones total=8 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=152.27643
2026.11.02 13:57:26.344	2026.06.27 04:50:00   [V3 Wait] SHORT | zones total=8 activeBear=0 | nearest mid=0.00000 | dist=0.00000 | atrLTF=143.47857
```
