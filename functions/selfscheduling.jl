# function for selfscheduling

function selfscheduling(;nr_of_supermarkets::Int, ramping::Bool)
    # must be greater than 0
    ## FIRST SELF-SCHEDULE
    selfschedule = Model(Mosek.Optimizer)
    add_excess_heat_constraints(selfschedule, nr_of_supermarkets, ramping)

    @objective(selfschedule, Min, sum(selfschedule[:load_el][t]*price_el_hourly[t] -
            selfschedule[:output_heat][t]*price_waste_heat[t] for t in 1:n_hours))
    optimize!(selfschedule)

    # store the output heat from waste heat
    output_heat_s = value.(selfschedule[:output_heat])

    # then clear market with output heat fixed input
    market_fix = Model(Mosek.Optimizer)
    @variable(market_fix, output_heat[1:n_hours])
    fix.(output_heat, output_heat_s)
    @variable(market_fix, shedded_load[1:n_hours] >= 0)
    @variable(market_fix, wasted_heat[t=1:n_hours] >= 0)
    @constraint(market_fix, limit_wasted[t=1:n_hours],
        output_heat[t] - wasted_heat[t] >= 0)
    @variable(market_fix,
        0 <= gen_heat[i in 1:n_CHPs, t in 1:n_hours] <= CHP_heat_lim[i])
    @constraint(market_fix, balance[t=1:n_hours],
        sum(gen_heat[:,t]) + sum(output_heat[t] - wasted_heat[t]) == # convert output_heat to MW
        load_heat_hourly[t] - shedded_load[t])

    # objective function
    @expression(market_fix, costfun[t=1:n_hours], shedded_load[t]*10^4 +
        sum(cost_heat[i,t]*gen_heat[i,t] for i in 1:n_CHPs))
    @objective(market_fix, Min, sum(costfun[t] for t in 1:n_hours))

    optimize!(market_fix)
    return market_fix
end
