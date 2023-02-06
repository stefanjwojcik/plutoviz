### A Pluto.jl notebook ###
# v0.19.11

using Markdown
using InteractiveUtils

# ╔═╡ de5b9e89-c7f7-4c50-97cf-55b696e93799
begin
	using Pkg; 
	Pkg.activate(".")
end

# ╔═╡ aedc1f34-6909-44b7-9dd9-fc47b15f51f5
begin 
	using RCall, Plots, CSV, DataFrames, Statistics, StateSpaceModels, PlutoUI, RenewableForecast, YesEnergyApi, Dates
end

# ╔═╡ 7b93882c-9ad8-11ea-0288-0941e163f9d5
md""" $(PlutoUI.LocalResource("..\\..\\images/NG_Renewables_Logo.png", :width => 300))
# NG Renewables Day Ahead vs. Real-Time Modeling
"""

# ╔═╡ 9168cece-be0a-4b67-99a7-205e7b10871d
md"""
This is the result of a backtest for a simple seasonal Naive model, taking the period 24 hours prior as the prediction for the current hour. 
"""

# ╔═╡ 9414a092-f105-11ea-10cd-23f84e47d876
# ╠═╡ show_logs = false
gr()

# ╔═╡ d3ff0e37-bc21-476a-ae56-c6cde10cc461
md"""
### Gettting the Data 
"""

# ╔═╡ e679567f-2bfb-412a-afc2-652f176d3e04
config("Olivia.steinke@nationalgrid.com", "NGRenewables123")

# ╔═╡ 1eccccfe-e888-40b4-aaf6-1d22ff953322
dat = get_training_data("2022-07-01", "2022-07-21").data

# ╔═╡ a64af472-7c94-4403-a761-5d245793cdc1


# ╔═╡ 02580141-52fe-41a2-a0d7-4479ae146cdd
md"""
Basic patterns of the data 

### Spencer Node Prices in July
"""

# ╔═╡ 06a08321-de06-43d9-a484-ae0a6e5591d7
plot(dat.DATETIME, [dat.SPNC_SPNCE_5DALMP, dat.SPNC_SPNCE_5RT_LMP_ERCOT_ADDERS], label = ["Day Ahead Spencer Prices" "Real Time Spencer Prices"])

# ╔═╡ c755a8f9-ad1d-417f-b920-d49891d970b6
ideal_strategy = mean(max.(dat.SPNC_SPNCE_5DALMP, dat.SPNC_SPNCE_5RT_LMP_ERCOT_ADDERS ))

# ╔═╡ d7792ed9-824f-4943-b9f1-8c30910dba35
md"""
Looking backward, we can see a total payoff from allocating all Day-Ahead of $(round(mean(dat.SPNC_SPNCE_5DALMP))) USD per MWH during this period, and a total payoff for Real Time of $(round(mean(dat.SPNC_SPNCE_5RT_LMP_ERCOT_ADDERS))), a percentage difference of $(round(mean(dat.SPNC_SPNCE_5DALMP .- dat.SPNC_SPNCE_5RT_LMP_ERCOT_ADDERS)/mean(dat.SPNC_SPNCE_5RT_LMP_ERCOT_ADDERS)*100))%. The perfect strategy would yield $(round(ideal_strategy)) USD.
"""

# ╔═╡ b65575fd-4f1e-4260-9735-7519811d408a
md"""
The ideal strategy gives a $(round(ideal_strategy/mean(dat.SPNC_SPNCE_5RT_LMP_ERCOT_ADDERS)*100)) % premium over the pure real time strategy. 
"""

# ╔═╡ cbc6fb3f-765b-477b-b55e-430371e9dbfd
md"""
Train two seasonal Naive models 
"""

# ╔═╡ 57f37a01-05c4-47c5-9d2f-089947dbe54b
#begin
#	m = 24
#	DAmod =  SeasonalNaive(dat.SPNC_SPNCE_5DALMP, m)
#	RTmod = SeasonalNaive(dat.SPNC_SPNCE_5RT_LMP_ERCOT_ADDERS, m)
#	fit!(DAmod)
#	fit!(RTmod)
#end

# ╔═╡ 3107192d-5f05-40ef-b50f-1f7202b72d5a
#ar = auto_arima(dat.SPNC_SPNCE_5DALMP, seasonal=24)

# ╔═╡ 3cdadead-bd71-40bd-bfe1-0960486993c2
#ar.results

# ╔═╡ 89a9f321-ba22-4161-943b-0dc2190e633f
#fieldnames(typeof(ar))

# ╔═╡ e9597cd2-7f68-4201-85d0-d60b680e05c0
sum(max.(dat.SPNC_SPNCE_5DALMP, dat.SPNC_SPNCE_5RT_LMP_ERCOT_ADDERS ))

# ╔═╡ b87043ee-1a6a-4de1-b5c2-03ab0886560e


# ╔═╡ c7ccda17-0cfb-4f11-a9d1-a796c54b8ccf


# ╔═╡ 75327c1d-f1eb-49b8-80b8-ee1bed30681d


# ╔═╡ 0067feff-f424-4ada-b190-5f64c12e2be7
# This is supposedly the best SARIMA according to auto arima 
# uses a zero mean 
begin
	m = 24
	DAmod =  SARIMA(dat.SPNC_SPNCE_5DALMP, order=(0,1,4), seasonal_order=(2,0,2,24))
	RTmod = SARIMA(dat.SPNC_SPNCE_5RT_LMP_ERCOT_ADDERS, order=(0,1,4), seasonal_order=(2,0,2,24))
	fit!(DAmod)
	fit!(RTmod)
end

# ╔═╡ 76440df7-e7fb-4b23-8ad4-0b96e66eb930
md"""
Run a backtest of the specified models, return a dataframe of the results 
"""

# ╔═╡ 6466fb40-8e5c-4116-90ee-337489dbd235
begin
    train, test = train_test_split(dat)
    db = DARTCompleteBackTest(train, test, dat, DAmod, RTmod, :SPNC_SPNCE_5DALMP, :SPNC_SPNCE_5RT_LMP_ERCOT_ADDERS)
    dbf = DARTBacktest_to_DataFrame(db)
end

# ╔═╡ 5ae65950-9ad9-11ea-2e14-35119d369acd
md"""
## Plots
Showing the effectiveness of a very simple model 
"""

# ╔═╡ 5dc06b99-1884-46eb-bd25-d6525ac0e6d7
md"""
### Day Ahead prices
"""

# ╔═╡ aaa805d4-9ad8-11ea-21c2-3b20580fea0e
begin 
	plot(dbf.testdates, dbf.da_lb, fillrange=dbf.da_ub, color=:lightgrey, 
	label = "95% CI of prediction")
	plot!(dbf.testdates, [dbf.da_pred, dbf.da_actual], label=["Predicted DA" "Actual DA"])
end

# ╔═╡ 5a6a465d-bbb5-4c65-a6fc-8e56863bff59
md"""
The above model would predict a total payoff from all Day-Ahead of $(round(sum(dbf.da_pred))) USD, and the actual payoff for Day-ahead ended up being $(round(sum(dbf.da_actual))), so this estimate was off by $(round(sum(dbf.da_pred .- dbf.da_actual)/sum(dbf.da_actual)*100))%.
"""

# ╔═╡ 8d68efd0-3741-48f1-b9ae-4a94da106de0
md""" 
#### Real Time prices
"""

# ╔═╡ 2afb0046-1e25-4d49-bfa1-f29382b5ce78
begin 
	plot(dbf.testdates, dbf.rt_lb, fillrange=dbf.rt_ub, color=:lightgrey, 
	label = "95% CI of prediction")
	plot!(dbf.testdates, [dbf.rt_pred, dbf.rt_actual], label=["Predicted RT" "Actual DA"])
end

# ╔═╡ 9cbb9e54-5eed-47a9-8698-46cc032fb13c
md"""
The above Real-Time model would predict a total payoff from all Real Time of $(round(sum(dbf.rt_pred))) USD, and the actual payoff for Real Time ended up being $(round(sum(dbf.rt_actual))), so this estimate was off by $(round(sum(dbf.rt_pred .- dbf.rt_actual)/sum(dbf.rt_actual)*100))%.
"""

# ╔═╡ 1198c3e5-351d-4264-b345-8bec49adad99
md"""
### Estimates of the Premium (DA - RT) with 95% confidence intervals
"""

# ╔═╡ 07e706a7-56c4-4563-86ff-03a50928e912
begin
	plot(dbf.testdates, [dbf.prem_lb], fillrange=dbf.prem_ub, 
	label = "Premium 95% CI")
	plot!(dbf.testdates, [dbf.prem], color=:black, label = "Est. Premium")
	plot!(dbf.testdates, [dbf.prem_actual], color=:red, label = "Actual Premium")
end

# ╔═╡ 88772fdb-5664-46d8-8b74-3279dd4b9f8f
md"""
The above model would predict a total premium of $(round(sum(dbf.prem))) USD of Day-ahead over Real Time, with the actual premium being $(round(sum(dbf.prem_actual))), so this estimate was off by $(round(sum(dbf.prem .- dbf.prem_actual)/sum(dbf.prem_actual)*100))%.
"""

# ╔═╡ 2fea0296-eeb5-45a9-b010-5b6d52881daf
md"""
### Hourly Aggregations
"""

# ╔═╡ 9d57068f-e2c1-4266-81a1-9db15fd870c4
begin 
	dbf.HOURENDING = Dates.hour.(dbf.testdates);
	dbfh =  select(dbf, Not([:testdates])) |>
		(data -> groupby(data, :HOURENDING)) |> 
		(data -> combine(data, All() .=> mean, renamecols=false));
end


# ╔═╡ e49a5259-b0cd-46a8-8a7f-885e1cc95f56
bar([dbfh.prem, dbfh.prem_actual], label = ["Predicted Premium" "Actual Premium"], alpha = .5, title = "Predicted vs. Actual Premium by Hour", legend=:topleft)

# ╔═╡ 3a3b802b-0227-44bb-906a-911ca9d2188f
begin 
	plot(dbfh[!, :HOURENDING], dbfh.prem_lb, 
            fillrange=dbfh.prem_ub, 
            label = "95% CI",
            color=:lightblue)
    plot!(dbfh[!, :HOURENDING], [dbfh.prem, dbfh.prem_actual], 
        color=[:blue :red],
        label = ["Predicted Premium" "Actual Premium"], 
        title = "Day-Ahead Premium", 
        xlabel = "Time", 
        ylabel = "Day Ahead Premium (\$ /MWh)", 
        legend = :topleft)
    annotate!(10, 700, 
        text("Mean Predicted Premium: $(round(mean(dbfh.prem), digits=2))", 10, :topright))
    annotate!(10, 500, 
        text("Mean Actual Premium: $(round(mean(dbfh.prem_actual), digits=2))", 10, :topright))
	bar!([dbfh.prem, dbfh.prem_actual], label = ["Predicted Premium" "Actual Premium"], alpha=.2)
end

# ╔═╡ 4b39f962-4c15-4c73-a66f-a9c97b03ce31


# ╔═╡ Cell order:
# ╟─de5b9e89-c7f7-4c50-97cf-55b696e93799
# ╠═aedc1f34-6909-44b7-9dd9-fc47b15f51f5
# ╟─7b93882c-9ad8-11ea-0288-0941e163f9d5
# ╟─9168cece-be0a-4b67-99a7-205e7b10871d
# ╠═9414a092-f105-11ea-10cd-23f84e47d876
# ╟─d3ff0e37-bc21-476a-ae56-c6cde10cc461
# ╟─e679567f-2bfb-412a-afc2-652f176d3e04
# ╠═1eccccfe-e888-40b4-aaf6-1d22ff953322
# ╠═a64af472-7c94-4403-a761-5d245793cdc1
# ╟─02580141-52fe-41a2-a0d7-4479ae146cdd
# ╠═06a08321-de06-43d9-a484-ae0a6e5591d7
# ╠═c755a8f9-ad1d-417f-b920-d49891d970b6
# ╠═d7792ed9-824f-4943-b9f1-8c30910dba35
# ╠═b65575fd-4f1e-4260-9735-7519811d408a
# ╟─cbc6fb3f-765b-477b-b55e-430371e9dbfd
# ╠═57f37a01-05c4-47c5-9d2f-089947dbe54b
# ╠═3107192d-5f05-40ef-b50f-1f7202b72d5a
# ╠═3cdadead-bd71-40bd-bfe1-0960486993c2
# ╠═89a9f321-ba22-4161-943b-0dc2190e633f
# ╠═e9597cd2-7f68-4201-85d0-d60b680e05c0
# ╠═b87043ee-1a6a-4de1-b5c2-03ab0886560e
# ╠═c7ccda17-0cfb-4f11-a9d1-a796c54b8ccf
# ╠═75327c1d-f1eb-49b8-80b8-ee1bed30681d
# ╠═0067feff-f424-4ada-b190-5f64c12e2be7
# ╟─76440df7-e7fb-4b23-8ad4-0b96e66eb930
# ╠═6466fb40-8e5c-4116-90ee-337489dbd235
# ╟─5ae65950-9ad9-11ea-2e14-35119d369acd
# ╟─5dc06b99-1884-46eb-bd25-d6525ac0e6d7
# ╠═aaa805d4-9ad8-11ea-21c2-3b20580fea0e
# ╠═5a6a465d-bbb5-4c65-a6fc-8e56863bff59
# ╟─8d68efd0-3741-48f1-b9ae-4a94da106de0
# ╠═2afb0046-1e25-4d49-bfa1-f29382b5ce78
# ╟─9cbb9e54-5eed-47a9-8698-46cc032fb13c
# ╟─1198c3e5-351d-4264-b345-8bec49adad99
# ╠═07e706a7-56c4-4563-86ff-03a50928e912
# ╠═88772fdb-5664-46d8-8b74-3279dd4b9f8f
# ╠═2fea0296-eeb5-45a9-b010-5b6d52881daf
# ╠═9d57068f-e2c1-4266-81a1-9db15fd870c4
# ╠═e49a5259-b0cd-46a8-8a7f-885e1cc95f56
# ╠═3a3b802b-0227-44bb-906a-911ca9d2188f
# ╠═4b39f962-4c15-4c73-a66f-a9c97b03ce31
