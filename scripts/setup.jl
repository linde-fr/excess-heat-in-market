using Pkg
Pkg.activate("excess-heat-pricing")
Pkg.instantiate()

#
Pkg.add(["JuMP", "Plots", 
         "Dates", "MosekTools", "Mosek",
         "DataFrames", "JSON", 
         "CSV", "JLD2", 
         "Statistics"]) 

using JuMP
using Plots
using Plots.PlotMeasures
using Dates
using DataFrames
using JSON
using CSV
using JLD2
using Statistics
using MosekTools, Mosek