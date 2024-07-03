require(tidyverse)
require(bench)

# loading expandbyspecies() from SoIB
source("https://raw.githubusercontent.com/stateofindiasbirds/soib_2023/master/00_scripts/00_functions.R")
rm(list = setdiff(ls(), "expandbyspecies"))
# loading expand_dt()
source("expandbyspecies/expand_dt.R")
source("expandbyspecies/expand_julia.R")


# load data
load("data/dataforanalyses.RData")

# benchmark
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
