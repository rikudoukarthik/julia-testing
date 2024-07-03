require(tidyverse)
require(bench)

# loading expandbyspecies() from SoIB
source("https://raw.githubusercontent.com/stateofindiasbirds/soib_2023/master/00_scripts/00_functions.R")
rm(list = setdiff(ls(), "expandbyspecies"))
# loading expand_dt()
source("expandbyspecies/expand_dt.R")
# loading expand_julia()
source("expandbyspecies/expand_julia.R")


# load data
load("data/dataforanalyses.RData")

# benchmark (total ~40 min)
benchmarked <- bench::mark(
  ORIGINAL = expandbyspecies(data, "Indian Peafowl"),
  DT = expand_dt(data, "Indian Peafowl"),
  JULIAFIED = expand_julia(data, "Indian Peafowl"),
  iterations = 3
)

# write benchmark summary
benchmarked |> 
  dplyr::select(-result, -gc, -memory, -time)  |> 
  write_csv(file = "expandbyspecies/benchmark.csv")

data_orig <- expandbyspecies(data, "Indian Peafowl")
data_julia <- expand_julia(data, "Indian Peafowl")
str(data_julia)
