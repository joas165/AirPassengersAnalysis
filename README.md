# AirPassengersAnalysis

Seasonal ARIMA forecasting of the classic monthly air passengers series
(1949-1960, thousands of passengers), compared against seasonal naive and ETS
baselines.

## Method

1. Multiplicative decomposition; log + regular + seasonal differencing to check stationarity.
2. Train/test split by date: train through Oct 1959, test Nov 1959 - Dec 1960 (14 months).
3. `auto.arima` (D = 1) with a Box-Cox lambda estimated on the training data only.
4. Residual diagnostics, then holdout RMSE / MAE / MAPE against `snaive` and `ets`.
5. Expanding-window time series cross-validation on the training data (h = 12),
   reported as RMSE and MAE by horizon.
6. Refit on all data and forecast 24 months ahead.

## Run

```r
install.packages(c("forecast", "ggplot2"))   # once
source("analysis.R")
```

Figures and `sessionInfo()` are written to `output/`.

## Results

Fill in after running: selected ARIMA order, holdout table, CV table.
