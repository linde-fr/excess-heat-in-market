## Load parameters

## indices
n_CHPs = 13                                     # representing each of the 13 CHPs
n_hours = 24*365                                  # no. of hours in simulation (also time steps for CHPs)

# periods for average temperature
p_length = 6
n_periods = Int((n_hours/p_length))
periods = [(Int((p-1)*p_length + 1), Int(p*p_length)) for p in 1:n_periods ]
#
start_date = Dates.DateTime("2019-01-01T00:00:00")
end_date = start_date + Hour(n_hours)

# create a list of timestamps for plotting or other interesting things
time_list_hourly = []
date = Dates.DateTime(start_date)
time_list_hourly = [Dates.DateTime(start_date) + Hour(t) for t in 1:n_hours]

## inputs
# Electricity price from NordPool, using UTC time and DKK as price, in DKK/MWh
df_elprice = CSV.read("Data/elspot_2018-2020_DK2.csv", DataFrame;
    select=["HourUTC", "SpotPriceDKK"])
df_elprice.HourUTC = DateTime.(df_elprice.HourUTC, "yyyy-mm-ddTHH:MM:SS+00:00")
price_el_hourly = reverse(
                  df_elprice[start_date .<= df_elprice[!,"HourUTC"] .< end_date,
                  :"SpotPriceDKK"]
                  )

# heat load  [MWh/h]
# data from Varmelast for the CTR & VEKS areas
df_heatcons = CSV.read("Data/heat_consumption_2019-2021.csv", DataFrame)
df_heatcons.HourUTC = DateTime.(df_heatcons.HourUTC, "yyyy-mm-dd HH:MM")
df_heatcons_total = DataFrame(HourUTC = df_heatcons.HourUTC,
    TotalConsumption = (df_heatcons.TotalConsCTR + df_heatcons.TotalConsVEKS))
load_heat_hourly = replace(
    df_heatcons_total[start_date .<= df_heatcons_total[!,"HourUTC"] .< end_date,
    :TotalConsumption], missing => 0)

# median ambient temperatures from the "DMI"-measuring station in Copenhagen
df_temp = DataFrame(HourUTC = [], Temperature = [])
for feature in JSON.parsefile("Data/weather_data/datafixed.json")["features"]
    value = feature["properties"]["value"]
    timestamp = feature["properties"]["observed"]
    push!(df_temp, [timestamp value])
end
df_temp.HourUTC = DateTime.(df_temp.HourUTC, "yyyy-mm-ddTHH:MM:SSZ")
temp_ambient_hourly = reverse(df_temp[start_date .<= df_temp[!,"HourUTC"] .<
                                                     end_date, :"Temperature"])
# getting the ambient temperature in the necessary resolution
temp_supermarket = 25

# calculating COP based on ambient temperature based on regression from mekanik-data
# assuming that COP is the same for all HPs
COP = zeros(n_hours)
for t in 1:n_hours
    T = temp_ambient_hourly[t]
    if T < -10
        COP[t] = 1.691-0.00425*(T)
    elseif T >= 20
        COP[t] = 1.973+0.00185*(T)
    else
        COP[t] = 1.825+0.0100*(T)
    end
end

## PARAMETERS

# fuel price for fuel used for each hour for each plant [DKK/MWh]
# taken from Ommen, Markussen & Elmegaard 2013: Heat pumps in district heating networks [€/GJ]
# the €-price is multiplied by 7.5/0.278 to get the DKK-price and the MWh-quantity
price_fuel = [6.5, 2, 7.3, 7.3, 7.3, 2, 3.5, 6.9, 2, 2, 2, 6.5, 6.5]*7.5/0.278

# power-to-heat ratio for each generator, assumed to be 0.45 for all
# (COMBINED HEAT AND POWER (CHP) GENERATION Directive 2012/27/EU of the European
# Parliament and of the Council Commission Decision 2008/952/EC)
phr = repeat([0.45], outer=n_CHPs)

# fuel efficiency for producing heat and electricity per plant [t fuel/MWh el or heat]
# from Ommen, Markussen & Elmegaard 2013: Heat pumps in district heating networks
# assuming ρ_el = 0.2 and ρ_heat = 0.9 for the ones without information
#eff_el = eff_heat = repeat([1], outer=length(CHPs))
eff_heat = [0.9, 0.9, 0.9, 0.9, 0.9, 0.83, 0.91, 0.93, 0.81, 0.99, 0.99, 0.9, 0.9]
eff_el = [0.21, 0.2, 0.18, 0.29, 0.2, 0.19, 0.36, 0.43, 0.18, 0.12, 0.18, 0.2, 0.2]

# parameters for heat dynamics model
B = 1 / 21

# temp and heat generation limits
temp_limit = [2 8]

# min and max for average RDC temperature in each period
T_avg_min = 4
T_avg_max = 5
# max fuel intake per plant [MWh/h] equal to cap. boiler
max_fuel_intake = [365, 550, 180, 300, 125, 131, 600, 1150, 65, 95, 110, 46.5, 56.2]
max_heat_gen = [251, 400, 240, 250, 94, 190, 331, 585, 96.8, 69, 73, 41.8, 53]

# CHP heat limit
CHP_heat_lim = max_heat_gen  # max_fuel_intake ./ (eff_el .* phr .+ eff_heat)

## CHP bids
cost_heat = [price_el_hourly[t] <= price_fuel[i]*eff_el[i] ?
    price_fuel[i]*(eff_el[i]*phr[i]+eff_heat[i]) - price_el_hourly[t]*phr[i] :
    price_el_hourly[t]*eff_heat[i]/eff_el[i] for i in 1:n_CHPs, t in 1:n_hours]


# price for waste heat calculated from a simple exponential model
# assuming that the forecasted temperature is close to the actual temperature,
# as the prices depend on the forecasted temperature
price_waste_heat = [(temp_ambient_hourly[t]-273.15) < 17.5 ?
                round(380*0.92^(temp_ambient_hourly[t]-273.15), digits=0) :
                0 for t in 1:n_hours] ./ 10^3
