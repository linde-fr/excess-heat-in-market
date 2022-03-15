# market_participation_function
include("../functions/add_excess_heat_constraints.jl")

function market_participation(;nr_of_supermarkets::Int, ramping::Bool)
    ## OPTIMIZATION MODEL
    market = Model(Mosek.Optimizer)
    add_excess_heat_constraints(market, nr_of_supermarkets, ramping)

    #
    @variable(market, shedded_load[1:n_hours] >= 0)
    @variable(market, wasted_heat[1:n_hours] >= 0)
    @constraint(market, limit_wasted[t=1:n_hours],
        market[:output_heat][t] - wasted_heat[t] >= 0)

    # for CHPs
    @variable(market, 0 <= gen_heat[i in 1:n_CHPs, t in 1:n_hours] <= CHP_heat_lim[i])

    # balancing load with both RDCs and CHPs
    @constraint(market, balance[t=1:n_hours],
        sum(gen_heat[:,t]) + market[:output_heat][t] - wasted_heat[t] ==
        load_heat_hourly[t] - shedded_load[t])

    # objective function!
    @expression(market, costfun[t=1:n_hours], shedded_load[t]*10^4 +
        sum(cost_heat[i,t]*gen_heat[i,t] for i in 1:n_CHPs))
    @objective(market, Min, sum(costfun[t] for t in 1:n_hours))

    optimize!(market)

    return market
end
