# increase the nr of excess heat producers and see suboptimality
include("setup.jl")
include("../functions/market_participation.jl")
include("../functions/selfscheduling.jl")
include("load_params.jl")

x_penetration = Vector(0:5000:70000)
x_penetration[1] = 1

## market participation ---------------------------------------------------
# object to store results in
markets = []
market_obj_value = []

# iterate
for i in 1:length(x_penetration)
    m = market_participation(nr_of_supermarkets=x_penetration[i], ramping=true)
    #push!(markets, m)
    push!(market_obj_value, objective_value(m))
end
# save it
filename = "Data/market_participation_objfun_vect.jld2"
@save filename x_penetration market_obj_value

## selfscheduling ---------------------------------------------------------
selfsched_obj_value = []

for i in 1:length(x_penetration)
    s = selfscheduling(nr_of_supermarkets=x_penetration[i], ramping=true)
    push!(selfsched_obj_value, objective_value(s))
end
filename = "Data/selfsched_objfun_vect.jld2"
@save filename x_penetration selfsched_obj_value

## plots with installed excess heat capacity on x-axis ------------------------
yunit = 10^9
plot(x_penetration * 30 / 10^3, selfsched_obj_value ./ yunit, label="self-scheduling",grid="x",
    xlabel="installed excess heat capacity [MW]", ylabel="total generation cost [M DKK]",
    xtickfontsize=16, ytickfontsize=16, legendfontsize=18, color=:black,
    linestyle=[:solid], lw=3,
    foreground_color_legend = nothing,background_color_legend = nothing,
    guidefontsize=16, fontfamily="Computer Modern", legendtitle=nothing)
plot!(x_penetration * 30 / 10^3, market_obj_value / yunit, lw=3,
    label="market participation", color=:black, linestyle=:dash)
savefig("figs/compare_total_generation_costs.pdf")

plot(x_penetration  * 30 / 10^3, (selfsched_obj_value - market_obj_value)/yunit,
    legend=:none,
    xlabel="installed excess heat capacity [MW]", ylabel="suboptimality [M DKK]",
    xtickfontsize=16, ytickfontsize=16, legendfontsize=18,
    grid="x", color=:black, lw=3,
    guidefontsize=18, fontfamily="Computer Modern", legendtitle=nothing)
savefig("figs/suboptimality.pdf")


# compute some quantities for selected levels of installed capacity ---------
# select nr of supermarkets 
n_sup_list = [10000, 40000, 50000, 70000]
nms = reshape(string.(Int.(n_sup_list * 30 / 10^3)), (1,4))
nms = [nm * " MW" for nm in nms]

# total cost
save_c_m_m = Array{Float64}(undef, length(n_sup_list), 12)
save_c_m_s = Array{Float64}(undef, length(n_sup_list), 12)
# scheduled excess heat
save_eh_m_m = Array{Float64}(undef, length(n_sup_list), 12)
save_eh_m_s = Array{Float64}(undef, length(n_sup_list), 12)
# market clearing price
save_mp_m_m = Array{Float64}(undef, length(n_sup_list), 12)
save_mp_m_s = Array{Float64}(undef, length(n_sup_list), 12)
# wasted excess heat
save_weh_m_m = Array{Float64}(undef, length(n_sup_list), 12)
save_weh_m_s = Array{Float64}(undef, length(n_sup_list), 12)


for i in 1:length(n_sup_list)
    m = market_participation(nr_of_supermarkets=n_sup_list[i], ramping=true)
    s = selfscheduling(nr_of_supermarkets=n_sup_list[i], ramping=true)

    # compute & save total cost
    save_c_m_m[i,:] = [sum(value.(m[:costfun][Dates.value.(Month.(time_list_hourly)) .== m_nr]))
        for m_nr in 1:12]
    save_c_m_s[i,:] = [sum(value.(s[:costfun][Dates.value.(Month.(time_list_hourly)) .== m]))
        for m in 1:12]

    # total scheduled excess heat
    save_eh_m_m[i,:] = [sum(value.((m[:output_heat] - m[:wasted_heat])[
            Dates.value.(Month.(time_list_hourly)) .== m_nr])) for m_nr in 1:12]
    save_eh_m_s[i,:] = [sum(value.((s[:output_heat] - s[:wasted_heat])[
            Dates.value.(Month.(time_list_hourly)) .== m_nr])) for m_nr in 1:12]

    # average market clearing price
    save_mp_m_m[i,:] = [mean(dual.(m[:balance])[
            Dates.value.(Month.(time_list_hourly)) .== m_nr]) for m_nr in 1:12]
    save_mp_m_s[i,:] = [mean(dual.(s[:balance])[
            Dates.value.(Month.(time_list_hourly)) .== m_nr]) for m_nr in 1:12]

    # # average market clearing price
    save_mp_m_m[i,:] = [mean(dual.(m[:balance])[
            Dates.value.(Month.(time_list_hourly)) .== m_nr]) for m_nr in 1:12]
    save_mp_m_s[i,:] = [mean(dual.(s[:balance])[
            Dates.value.(Month.(time_list_hourly)) .== m_nr]) for m_nr in 1:12]

    # wasted excess heat
    save_weh_m_m[i,:] = [sum(value.((m[:wasted_heat])[
            Dates.value.(Month.(time_list_hourly)) .== m_nr])) for m_nr in 1:12]
    save_weh_m_s[i,:] = [sum(value.((s[:wasted_heat])[
            Dates.value.(Month.(time_list_hourly)) .== m_nr])) for m_nr in 1:12]
end

### how much excess heat is scheduled in total in a year? 
sum(save_eh_m_m'[:,1])
sum(save_eh_m_m'[:,2])
sum(save_eh_m_m'[:,4])


## plots with Month numbers on x-axis  ------------------------------------------------
## plot total chp generation cost
choose = [1,2,4] # [2, 3]
clrs = reshape(palette(:default)[1:3], (1,length(choose)))
xtick = Vector(1:12)
yscale = 10^6
plot(1:12, (save_c_m_s - save_c_m_m)'[:,choose] / yscale, xlabel="month",
    ylabel="suboptimality [million DKK]", xticks=xtick, label=nms[:,choose],
    xtickfontsize=16, ytickfontsize=16, legendfontsize=18,
    grid="x", legend=(90,:inner), color=clrs,#legendtitle="excess heat",
    foreground_color_legend = nothing,background_color_legend = nothing,
    guidefontsize=18, fontfamily="Computer Modern", lw=4)
savefig("figs/monthly_total_cost_diff.pdf")
percent_decrease = Array{Float64}(undef, length(n_sup_list), 12)
for i in 1:length(n_sup_list)
    percent_decrease[i,:] = (save_c_m_s[i,:] - save_c_m_m[i,:]) ./ save_c_m_s[i,:]
end

plot(1:12, percent_decrease'[:,choose] .* 100 , xlabel="month",
    ylabel="decrease in total cost if integrate in market [%]", xticks=xtick,
    label=nms)

# plot montly decrease for chosen ones
choose = [1,2,4]
clrs = reshape(palette(:default)[1:3], (1,length(choose)))
plot(1:12, save_c_m_s'[:,choose]/yscale, xlabel="month",
    ylabel="total cost [million DKK]", xticks=xtick, lw=2.5,
    label=reshape(["self-scheduling", :none,:none], (1,3)), color=:gray)
plot!(1:12, save_c_m_m'[:,choose]/yscale, color=:gray, linestyle=:dash,
    label=reshape(["market participation", :none,:none], (1,3)), lw=2.5)
plot!(1:12, save_c_m_s'[:,choose]/yscale,lw=2.5,
    label=nms[:,choose], color=clrs, xtickfontsize=16, ytickfontsize=16,
    legendfontsize=18,
    grid="x", legend=:topright, guidefontsize=18, fontfamily="Computer Modern")
plot!(1:12, save_c_m_m'[:,choose]/yscale,color=clrs, linestyle=:dash, lw=2.5,
    foreground_color_legend = nothing, label=:none, (1,3))
savefig("figs/monthly_total_cost.pdf")

## plot total scheduled excess heat
choose = [1,2,4]
yscale = 10^6
clrs = reshape(palette(:default)[1:3], (1,length(choose)))
plot(1:12, save_eh_m_m'[:,choose]/yscale, color=:gray, linestyle=:dash,lw=3,
    label=reshape(["market participation", :none,:none], (1,3)))
plot!(1:12, save_eh_m_s'[:,choose]/yscale, xlabel="month",
    ylabel="sched. excess heat [10^6 MWh]", xticks=xtick, lw=3,
    label=reshape(["self-scheduling", :none,:none], (1,3)), color=:gray)
plot!(1:12, save_eh_m_s'[:,choose]/yscale,lw=3,
    label=nms[:,choose], color=clrs, xtickfontsize=16, ytickfontsize=16,
    legendfontsize=18,
    grid="x",  guidefontsize=16, fontfamily="Computer Modern")
plot!(1:12, save_eh_m_m'[:,choose]/yscale,color=clrs, linestyle=:dash,lw=3,
    background_color_legend = nothing, legend=(100,:inner),
    foreground_color_legend = nothing, label=:none, (1,3),  ylims=(-0.1,1.35))
montly_load = [sum(load_heat_hourly[
        Dates.value.(Month.(time_list_hourly)) .== m_nr]) for m_nr in 1:12]
scatter!(1:12, montly_load / yscale, label="montly load", color=:black,
        markersize=5)
savefig("figs/monthly_scheduled_volume.pdf")

## wasted excess heat
choose = [1,2,4]
yscale = 10^6
clrs = reshape(palette(:default)[1:3], (1,length(choose)))
plot(1:12, save_weh_m_s'[:,choose]/yscale, xlabel="month", lw=3,
    ylabel="wasted excess heat [10^6 MWh]", xticks=xtick,
    label=reshape(["self-scheduling", :none,:none], (1,3)), color=:gray)
plot!(1:12, save_weh_m_m'[:,choose]/yscale, color=:gray, linestyle=:dash,
    label=reshape(["market participation", :none,:none], (1,3)), lw=3)
plot!(1:12, save_weh_m_s'[:,choose]/yscale,
    label=nms[:,choose], color=clrs, xtickfontsize=16, ytickfontsize=16,
     lw=3, legendfontsize=18,
    grid="x", legend=:topright, guidefontsize=16, fontfamily="Computer Modern")
plot!(1:12, save_weh_m_m'[:,choose]/yscale,color=clrs, linestyle=:dash,  lw=3,
    foreground_color_legend = nothing, label=:none, (1,3), ylims=(-0.1,1.35),
    legend=:topleft, background_color_legend = nothing)
savefig("figs/montly_wasted_excessheat.pdf")

## market price
choose = [1,2,4]
yscale = 1
clrs = reshape(palette(:default)[1:3], (1,length(choose)))
plot(1:12, save_mp_m_s'[:,choose]/yscale, xlabel="month", lw=3,
    ylabel="avg market price [DKK/MWh]", xticks=xtick,
    label=reshape(["self-scheduling", :none,:none], (1,3)), color=:gray)
plot!(1:12, save_mp_m_m'[:,choose]/yscale, color=:gray, linestyle=:dash, lw=3,
    label=reshape(["market participation", :none,:none], (1,3)))
plot!(1:12, save_mp_m_s'[:,choose]/yscale, legend=(100,:inner), lw=3,
    label=nms[:,choose], color=clrs, xtickfontsize=16, ytickfontsize=15,
    legendfontsize=16,
    grid="x", guidefontsize=16, fontfamily="Computer Modern")
plot!(1:12, save_mp_m_m'[:,choose]/yscale,color=clrs, linestyle=:dash,
    foreground_color_legend = nothing, background_color_legend = nothing,
    label=:none, lw=3)
savefig("figs/monthly_market_prices.pdf")
