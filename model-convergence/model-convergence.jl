using Pkg

Pkg.add("RCall")
Pkg.add("MixedModels")

using MixedModels, RCall

# evaluate below in R environment using RCall
R"""
require(lme4)

load("data/data_for_test.RData")
attach("data/data_for_test.RData")

mod_formula <- OBSERVATION_COUNT ~ month + month:log(no_sp) + timegroups + (1|gridg3/gridg1)
"""

data_mod = rcopy(R"data_mod")

mod_julia = fit(MixedModel, rcopy(R"mod_formula"), rcopy(R"data_mod"))



        data = data_mod, family = binomial(link = 'cloglog'), 
        nAGQ = 0, control = glmerControl(optimizer = "bobyqa")
