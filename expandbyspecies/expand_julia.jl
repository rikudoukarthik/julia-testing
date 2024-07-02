using Pkg

# Pkg.add("DataFramesMeta")

using DataFrames, DataFramesMeta, RCall
using DataFramesMeta: @chain

R"""
load("data/dataforanalyses.RData")
attach("data/dataforanalyses.RData")
"""

# data: copy from R
@elapsed data_exp = rcopy(R"data")

# modifying
data_exp = @chain data_exp begin
    @subset(_.COMMON_NAME .== "Indian Peafowl")  # Filter rows
    @select(_, :gridg3, :month)  # Select relevant columns
    unique(_)  # Get distinct rows
    leftjoin(_, data_exp, on = [:gridg3, :month])  # Left join with original data
end