## Script to understand simple forecasting principles 
using RCall, TimeSeries, MarketData, Plots 
using CSV, DataFrames, Statistics, StateSpaceModels

# CUSTOM FUNCTION ZONE 

# custom date function 
fixdate(x) = DateTime(x, dateformat"yyyy-mm-dd HH:MM:SS") #helpful for NGR Data 

# Generate a plot of seasonality characteristics by plotting month over month 
function plot_seasonality(ya, freq)
    plot()
    for i in 1:freq
        TimeSeries.values(when(ya, month, i)) |> plot!
    end
    current() # shows the current plot 
end

# Plot of Centered Moving Average 
function plot_cma(series, m)
    # moving average of 12 months (because of daily data)
    ma = moving(mean, series, m, padding=false)
    # center the moving average
    ma_cent = lead(ma, Int(m/2) +1 , padding=true) # use the lead function to center 
    plot(ma_cent, label="")
    plot!(series, linecolor="grey", alpha=.5, label="" ) # makes a nice plot 
end

## Evaluate different State Space models 
# option to zoom to the last set of values 
# takes a State Space model and TimeArray of test values
# usage: plot_forecast(smoothing, test.Close[1:5], 40)    
function plot_forecast(model, testvalues, zoom_to_last=nothing) 
    actual_values = vcat(fill(NaN, length(model.system.y)), values(testvalues)) # helper function to create a vector of NaNs
    plot(model, forecast(model, length(testvalues)), label=["Train" "Forecast"])
    plot!(actual_values, linecolor="gray", alpha=.5, label="Actual") # makes a nice plot
    if !isnothing(zoom_to_last)
        xlims!(length(model.system.y) - zoom_to_last, length(model.system.y) + length(testvalues))
    end
end

#### SIDEBAR - CREATING SOME DATA FOR Time Series PLAY
# Creating a fake time series
#mydates = collect(Date(2019, 1, 1):Day(1):Date(2020, 1, 1))
#mydates = map(x -> DateTime(x), mydates)
#ts = TimeArray(mydates, 1:length(mydates))
# Create a moving average of 3 months
#ma3 = moving(mean, ts, 3)
################################### END SIDEBAR

## Manipulating AAPL time series data 
ya = yahoo(:AAPL, YahooOpt(period1 = DateTime("2015-01-01")))
## Example NGR data
ngr = CSV.read("example_ngr.csv", DataFrame)
ngr = TimeArray(map(fixdate, ngr[!, :date]), ngr[!, :price], [:price])

## Plotting the data
plot(ya, title = "Apple Stock Price", ylabel = "Price", xlabel = "Date")

# Seasonally adjusted data
ya_adj = ya.Close ./ ma12_cent.Close
plot(ya_adj, label="Seasonally Adjusted Close")

## Create train and test 
train = ya[1:floor(Int, 0.8*length(ya))]
test = ya[floor(Int, 0.8*length(ya)):end]

# The simplest model with only local trend - which ends up being just an average 
smoothing = UnobservedComponents(values(train.Close), trend = "local level", seasonal = "no", cycle = "no")
fit!(smoothing)
#fc = forecast(smoothing, length(test))
###########
plot_forecast(smoothing, test.Close)

# More complex model with trend and seasonality
smoothing = UnobservedComponents(values(train.Close), trend = "local linear trend", seasonal = "stochastic 12", cycle = "stochastic damped")
fit!(smoothing)
###########
plot_forecast(smoothing, test.Close[1:5], 20)

### Exponential smoothing
exp_smoothing = ExponentialSmoothing(values(train.Close), trend=true, damped_trend=true, seasonal=12)
fit!(exp_smoothing)
plot_forecast(exp_smoothing, test.Close[1:5], 20)

# Different optimizers 
exp_smoothing = ExponentialSmoothing(values(train.Close), trend=true, damped_trend=true, seasonal=12)
opt = Optimizer(StateSpaceModels.Optim.GradientDescent());
fit!(exp_smoothing; optimizer=opt)
plot_forecast(exp_smoothing, test.Close, 60)


## Cross-validate 
cross_validation(smoothing, 1, 1000;
         n_scenarios = 5)

## Estimate NGR models 
exp_smoothing = ExponentialSmoothing(values(log.(ngr.price)), trend=true, damped_trend=true, seasonal=24)
opt = Optimizer(StateSpaceModels.Optim.GradientDescent());
fit!(exp_smoothing; optimizer=opt)
plot_forecast(exp_smoothing, log.(ngr.price), 60)

# Define a julia function to call a simple seasonal arima in R
function myarima(x, order)
    R"arima($x, $order)"
end
# example usage: myarima(ngr.price, [0,1,0])