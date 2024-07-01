source("model-convergence/model_function.R")

# loading singlespeciesrun() from SoIB
source("https://raw.githubusercontent.com/stateofindiasbirds/soib_2023/master/00_scripts/00_functions.R")
rm(list = setdiff(ls(), c("singlespeciesrun", "expandbyspecies")))


# load data
load("data/dataforanalyses.RData")

data_mod <- data %>% julia_prep()
save(data_mod, file = "data/data_for_test.RData")
