# install JuliaCall
# install.packages("JuliaCall")
library(JuliaCall)
require(tidyverse)
require(lme4)

# load data
load("data/data_for_test.RData")


# set up Julia
# (107 sec first time)
env_julia <- julia_setup()

julia_library("MixedModels")
julia_library("RCall")
# julia_install_package("GLM")
# julia_install_package("DataFrames")
julia_library("GLM")
julia_library("DataFrames")

# data: transfer to Julia
julia_assign("data_mod", data_mod)
# model: define in R and transfer to Julia
mod_formula <- formula(
  OBSERVATION_COUNT ~ month + month:log(no_sp) + timegroups + (1|gridg3/gridg1)
)
julia_assign("mod_formula", mod_formula)

# fit the model in Julia
julia_command(" 
@elapsed mod_julia = fit!(GeneralizedLinearMixedModel(mod_formula, data_mod, Binomial(), CloglogLink()),
                  fast = true)
") # 13 min

# Save the model to R's environment using RCall within Julia
julia_command("@rput mod_julia")

# getting model coefficients and saving as dataframe in R
julia_command("coefs = coeftable(mod_julia)")
julia_command("coef_df = DataFrame(variable = coefs.rownms,
                                    Estimate = coefs.cols[1],
                                    StdError = coefs.cols[2],
                                    z_val = coefs.cols[3])")
julia_command("@rput coef_df")
