using JuMP

function add_excess_heat_constraints(mod::JuMP.Model)
    # variables for RDCs
    @variable(mod, output_heat[1:n_hours] >= 0)
    @variable(mod, load_el[1:n_hours] >= 0)
    @variable(mod, temp_RDC[1:n_hours])

    # constraints RDCs --
    # initial conditions: set all RDCs to start at lower temperature limit,
    # and set the HP to be turned off during the first interval
    fix(temp_RDC[1], temp_limit[1,1]; force=true)
    # fix(output_heat[1], 0; force=true)

    # link heat output and el input
    @constraint(mod, con_COP[t = 1:n_hours],
                output_heat[t] == COP[t]*load_el[t])
    # HP output limit
    @constraint(mod, con_heat_limit[t=1:n_hours],
                output_heat[t] <= heat_limit)
    # # temp limits
    @constraint(mod, con_temp_limit[t=2:n_hours],
             temp_limit[1,1] <= temp_RDC[t] <= temp_limit[1,2])
    # # T dynamics
    @constraint(mod, con_temp[t=2:n_hours],
                (temp_RDC[t] - temp_RDC[t-1]) ==
                    - A*(output_heat[t] - load_el[t])*10^3 + # convert to kW
                    B*(temp_supermarket - temp_RDC[t-1])
                )
    # average temperature constraint
    @constraint(mod, avg_temp_max[p=1:n_periods],
        sum(temp_RDC[periods[p][1]:periods[p][2]])/p_length <= T_avg_max)
    @constraint(mod, avg_temp_min[p=1:n_periods],
        sum(temp_RDC[periods[p][1]:periods[p][2]])/p_length >= T_avg_min)
    return mod
end


# with n_supermarkets as input
function add_excess_heat_constraints(mod::JuMP.Model, n_of_sup::Int,
            ramping::Bool)
    # make inputs
    heat_limit_ = n_of_sup * 30 / 10^3 # in MW
    A_ = 1 / 10  / n_of_sup

    # variables for RDCs
    @variable(mod, output_heat[1:n_hours] >= 0)
    @variable(mod, load_el[1:n_hours] >= 0)
    @variable(mod, temp_RDC[1:n_hours])

    # constraints RDCs --
    # initial conditions: set all RDCs to start at lower temperature limit,
    # and set the HP to be turned off during the first interval
    fix(temp_RDC[1], temp_limit[1,1]; force=true)
    # fix(output_heat[1], 0; force=true)

    # link heat output and el input
    @constraint(mod, con_COP[t = 1:n_hours],
                output_heat[t] == COP[t]*load_el[t])
    # HP output limit
    @constraint(mod, con_heat_limit[t=1:n_hours],
                output_heat[t] <= heat_limit_)
    # # temp limits
    @constraint(mod, con_temp_limit[t=2:n_hours],
             temp_limit[1,1] <= temp_RDC[t] <= temp_limit[1,2])
    # # T dynamics
    @constraint(mod, con_temp[t=2:n_hours],
                (temp_RDC[t] - temp_RDC[t-1]) ==
                    - A_*(output_heat[t] - load_el[t])*10^3 + # convert to kW
                    B*(temp_supermarket - temp_RDC[t-1])
                )
    # average temperature constraint
    @constraint(mod, avg_temp_max[p=1:n_periods],
        sum(temp_RDC[periods[p][1]:periods[p][2]])/p_length <= T_avg_max)
    @constraint(mod, avg_temp_min[p=1:n_periods],
        sum(temp_RDC[periods[p][1]:periods[p][2]])/p_length >= T_avg_min)

    if ramping
        # ramping constraint for HP
        @constraint(mod, ramping_ub[t=2:n_hours],
            mod[:output_heat][t] - mod[:output_heat][t-1] <= heat_limit_/4)
        @constraint(mod, ramping_lb[t=2:n_hours],
            -heat_limit_/4 <= mod[:output_heat][t] - mod[:output_heat][t-1])
    end

    return mod
end
