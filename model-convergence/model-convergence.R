
# install JuliaCall
# install.packages("JuliaCall")
library(JuliaCall)

require(tidyverse)
require(lme4)


# load data
load("data/data_for_test.RData")
# Julia doesn't like periods in column names, converts them to underscores by default
# so results in errors in function call
data_mod <- data_mod |> 
  rename(OBSERVATION_COUNT = OBSERVATION.COUNT,
    no_sp = no.sp)

# set up Julia
# (107 sec first time)
env_julia <- julia_setup()

attach(env_julia)


library("MixedModels")

# data
assign("data_mod", data_mod)
# model
assign("mod_formula", formula(
  glmer(OBSERVATION_COUNT ~ month + month:log(no_sp) + timegroups + (1|gridg3/gridg1), 
        data = data_mod, family = binomial(link = 'cloglog'), 
        nAGQ = 0, control = glmerControl(optimizer = "bobyqa"))
))

eval("@elapsed mod_julia = fit(MixedModel, mod_formula, data_mod)")
eval("mod_julia")


detach(env_julia)
