# excess-heat-in-market
Code accompanying PSCC article `Market Integration of Excess Heat' by Linde Frölke, Ida-Marie Palm, and Jalal Kazempour. 
Link to the article will be posted here as soon as it is available. Contact the authors at linfr@dtu.dk for questions.

## Dependencies / needed software
All code is in Julia. For optimization, JuMP is used. Mosek is used as a solver. You need to install Mosek and get a (academic) license to use the code as is. Otherwise, change the optimization function to change solver. We run the code in VSCode with Julia extension. 

## How to run it to reproduce all results
The way we run it:
1. Clone the repository
2. Open the folder "excess-heat-in-market" in VSCode
3. Run the file /scripts/plot_suboptimality_dependence.jl as a script in the Julia REPL. 

## Contents of this repository
### Data
Spot market data from Nord Pool, heat consumption data from Copenhagen area, weather data. See the article for more details

### figs
Figures produced for the article. 

### functions
The files in this folder contain functions used to build the optimization problems. 

### scripts
1. setup.jl creates a Pkg environment with the necessary packages, and loads the packages.
2. load_params.jl loads the data from files, and contains other input values.
3. plot_suboptimality_dependence.jl is the main script that reproduces all results in the article. 

