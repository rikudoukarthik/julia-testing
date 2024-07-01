source("model-convergence/model_function.R")

# loading singlespeciesrun() from SoIB
source("https://raw.githubusercontent.com/stateofindiasbirds/soib_2023/master/00_scripts/00_functions.R")
rm(list = setdiff(ls(), c("singlespeciesrun", "expandbyspecies")))


# load data
load("data/dataforanalyses.RData")

data_mod <- data %>% 
  julia_prep() |> 
  # Julia doesn't like periods in column names, converts them to    underscores by default
  # so results in errors in function call
    rename(OBSERVATION_COUNT = OBSERVATION.COUNT,
            no_sp = no.sp)
  
save(data_mod, file = "data/data_for_test.RData")
