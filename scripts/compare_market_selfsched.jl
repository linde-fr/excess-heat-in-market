## compare market and self-scheduling
include("setup.jl")
include("load_params.jl")

only_with_r = true

using StatsPlots

## load data"Data/models_market_participation_N=$(n_supermarkets).jld2"
@load "Data/models_market_participation_N=$(n_supermarkets).jld2" market_dfs market_CHP_gen_heat
@load "Data/models_selfscheduling_N=$(n_supermarkets).jld2" selfschedule_dfs selfschedule_CHP_gen_heat

## combine data

if only_with_r
    modnms = ["market_r", "selfschedule_r"]
    dfs = vcat(market_dfs, selfschedule_dfs)[[2,4]]
    CHP_gen_heat = vcat(market_CHP_gen_heat, selfschedule_CHP_gen_heat)[[2,4]]
else
    modnms = ["market", "market_r", "selfschedule", "selfschedule_r"]
    dfs = vcat(market_dfs, selfschedule_dfs)
    CHP_gen_heat = vcat(market_CHP_gen_heat, selfschedule_CHP_gen_heat)
end

n_mod = length(modnms)
## RDC temperature
n_days = 2
times = (1:(24*n_days)) .+ 5*24

p = plot(ylabel="RDC temp [°C]", xlabel="time", legend=:bottomright)
for i = 1:length(modnms)
    plot!(p, time_list_hourly[times], dfs[i][2].temp_RDC[times], label=modnms[i],
        xticks=time_list_hourly[times][4]:Hour(length(times)/2):time_list_hourly[times][length(times)])
end

display(p)
if only_with_r
    savefig("figs/market_vs_selfsched_temp_N=$(n_supermarkets)_r.pdf")
else
    savefig("figs/market_vs_selfsched_temp_N=$(n_supermarkets).pdf")
end
## heat output
p = plot(ylabel="Excess heat produces [MW]", xlabel="time", legend=:bottomleft)
for i = 1:length(modnms)
    plot!(p, time_list_hourly[times], dfs[i][2].output_heat[times], label=modnms[i],
        xticks=time_list_hourly[times][4]:Hour(length(times)/2):time_list_hourly[times][length(times)])
end

display(p)
if only_with_r
    savefig("figs/market_vs_selfsched_heat_output_N=$(n_supermarkets)_r.pdf")
else
    savefig("figs/market_vs_selfsched_heat_output_N=$(n_supermarkets).pdf")
end



## wasted heat
times = (1:(24*4)) .+ 150*24

p = plot(ylabel="Unused excess heat [MW]", xlabel="time", legend=:topleft)
for i = 1:length(modnms)
    plot!(p, time_list_hourly[times], dfs[i][2].wasted_heat[times], label=modnms[i],
        xticks=time_list_hourly[times][4]:Hour(length(times)/2):time_list_hourly[times][length(times)])
end

display(p)
if only_with_r
    savefig("figs/market_vs_selfsched_wasted_heat_N=$(n_supermarkets)_r.pdf")
else
    savefig("figs/market_vs_selfsched_wasted_heat_N=$(n_supermarkets).pdf")
end

## prices
times = 1:500
p = plot(ylabel="Heat marginal price[DKK/MWh]", xlabel="time", legend=:topleft)
for i = 1:length(modnms)
    plot!(p, time_list_hourly[times], CHP_gen_heat[i][2].market_price[times], label=modnms[i],
        xticks=time_list_hourly[times][4]:Hour(length(times)/2):time_list_hourly[times][length(times)])
end

display(p)
if only_with_r
    savefig("figs/market_vs_selfsched_marginal_price_N=$(n_supermarkets)_r.pdf")
else
    savefig("figs/market_vs_selfsched_marginal_price_N=$(n_supermarkets).pdf")
end


## values
total_wasted_heat = [sum(dfs[i][2].wasted_heat) for i in 1:n_mod]
display(total_wasted_heat)

# total cost for consumers (load * marginal clearing price)
total_cost_consumers = [sum(CHP_gen_heat[i][2].market_price .* load_heat_hourly)
    for i in 1:n_mod]
display(total_cost_consumers)


##
avg_marg_price = [sum(CHP_gen_heat[i][2].market_price)/n_hours for i in 1:n_mod]
display(avg_marg_price)

avg_marg_price_month = [sum(CHP_gen_heat[i][2].market_price[
                Dates.value.(Month.(time_list_hourly)) .== m]) / n_hours
                for i in 1:n_mod, m in 1:12]
plot(1:12, avg_marg_price_month[1,:], label=modnms[1], linetype=:bar,
    ylabel="average clearing price", xlabel="month")
plot!(1:12, avg_marg_price_month[2,:], label=modnms[2], linetype=:bar)

ctg = repeat(modnms, inner = 12)
nam = repeat(append!("0" .*string.(1:9), string.(10:12)), outer = 2)

groupedbar(nam, avg_marg_price_month', group = ctg, xlabel = "month",
        ylabel = "average clearing price [DKK/MWh]",
        title = "avg marginal price by month", bar_width = 0.67,
        lw = 0, framestyle = :box)
if only_with_r
    savefig("figs/market_vs_selfsched_avg_marg_montly_N=$(n_supermarkets)_r.pdf")
else
    savefig("figs/market_vs_selfsched_avg_marg_montly_N=$(n_supermarkets).pdf")
end
## total costs per month
total_cost_consumers_m = [sum((CHP_gen_heat[i][2].market_price.* load_heat_hourly)[
                Dates.value.(Month.(time_list_hourly)) .== m] )
                for i in 1:n_mod, m in 1:12]
groupedbar(nam, total_cost_consumers_m', group = ctg, xlabel = "month",
        ylabel = "total payment consumers [DKK]", bar_width = 0.67,
        lw = 0, framestyle = :box)
if only_with_r
    savefig("figs/market_vs_selfsched_cons_pay_montly_N=$(n_supermarkets)_r.pdf")
else
    savefig("figs/market_vs_selfsched_cons_pay_montly_N=$(n_supermarkets).pdf")
end
