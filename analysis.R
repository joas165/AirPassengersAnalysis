# Air passengers: seasonal ARIMA forecasting with baselines and honest evaluation
# Data: monthly international airline passengers (thousands), 1949-1960
# Requires: forecast, ggplot2 (see README)

suppressPackageStartupMessages({
  library(forecast)
  library(ggplot2)
})

dir.create("output", showWarnings = FALSE)

x <- AirPassengers
stopifnot(is.ts(x), frequency(x) == 12, length(x) == 144)

# ---- 1. Exploration ---------------------------------------------------------
print(head(x, 12))
autoplot(x) + labs(x = "Year", y = "Passengers (thousands)")

plot(decompose(x, type = "multiplicative"))

# Stationarity check: log, first difference, seasonal difference.
# diff() keeps the ts attributes, so no ts() wrapper is needed.
x_stat <- diff(diff(log(x)), lag = 12)
tsdisplay(x_stat, main = "log, d = 1, D = 1")

# ---- 2. Train / test split (by date, not by index) --------------------------
train <- window(x, end   = c(1959, 10))   # 130 obs
test  <- window(x, start = c(1959, 11))   # 14 obs
stopifnot(length(train) == 130, length(test) == 14)

# Box-Cox lambda estimated on the training data only (no test leakage)
lamb <- BoxCox.lambda(train)

# ---- 3. Models --------------------------------------------------------------
fit_arima <- auto.arima(train, D = 1, lambda = lamb)
print(fit_arima)
checkresiduals(fit_arima)

fc_arima  <- forecast(fit_arima, h = length(test))
fc_snaive <- snaive(train, h = length(test))
fc_ets    <- forecast(ets(train), h = length(test))

# ---- 4. Holdout accuracy vs baselines ---------------------------------------
cols <- c("RMSE", "MAE", "MAPE")
acc <- rbind(
  ARIMA  = accuracy(fc_arima,  test)["Test set", cols],
  ETS    = accuracy(fc_ets,    test)["Test set", cols],
  SNAIVE = accuracy(fc_snaive, test)["Test set", cols]
)
print(round(acc, 2))

p <- autoplot(fc_arima, include = 24) +
  autolayer(test, series = "Actual") +
  labs(x = "Year", y = "Passengers (thousands)")
print(p)
ggsave("output/holdout_forecast.png", p, width = 8, height = 4.5, dpi = 150)

# ---- 5. Time series cross-validation (on the training data only) ------------
# Same model specification as the fitted auto.arima, same lambda.
# Expanding window, 12-month horizon. The test set stays untouched.
ord <- arimaorder(fit_arima)   # p d q P D Q period

cv_arima <- function(y, h) {
  forecast(Arima(y, order = ord[1:3],
                 seasonal = list(order = ord[4:6], period = 12),
                 lambda = lamb), h = h)
}

e_arima  <- tsCV(train, cv_arima, h = 12, initial = 72)
e_snaive <- tsCV(train, snaive,   h = 12, initial = 72)

by_h <- function(e) {
  rbind(RMSE = sqrt(colMeans(e^2, na.rm = TRUE)),
        MAE  = colMeans(abs(e),   na.rm = TRUE))
}
cat("\nCV error by horizon (ARIMA)\n");  print(round(by_h(e_arima),  1))
cat("\nCV error by horizon (SNAIVE)\n"); print(round(by_h(e_snaive), 1))

# ---- 6. Final forecast: refit on all data, same specification ---------------
fit_final <- Arima(x, order = ord[1:3],
                   seasonal = list(order = ord[4:6], period = 12),
                   lambda = lamb)
fc_final <- forecast(fit_final, h = 24)
p_final <- autoplot(fc_final) +
  labs(x = "Year", y = "Passengers (thousands)")
print(p_final)
ggsave("output/final_forecast.png", p_final, width = 8, height = 4.5, dpi = 150)

writeLines(capture.output(sessionInfo()), "output/sessionInfo.txt")
