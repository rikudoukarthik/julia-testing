using Pkg

# Pkg.add("RCall")
# Pkg.add("DataFrames")
# Pkg.add("MixedModels")
# Pkg.add("GLM"

using MixedModels, RCall, GLM, DataFrames

# evaluate below in R environment using RCall
R"""
require(lme4)

load("data/data_for_test.RData")
attach("data/data_for_test.RData")

mod_formula <- OBSERVATION_COUNT ~ month + month:log(no_sp) + timegroups + (1|gridg3/gridg1)
"""

# data: copy from R
data_mod = rcopy(R"data_mod")
form_mod = rcopy(R"mod_formula")
# model: define
@elapsed mod_julia = fit!(GeneralizedLinearMixedModel(form_mod, data_mod, Binomial(), CloglogLink()),
                            fast = true) # 10-13 min

# getting model coefficients and saving as dataframe in R
coefs = coeftable(mod_julia)
coef_df = DataFrame(variable = coefs.rownms,
                                    Estimate = coefs.cols[1],
                                    StdError = coefs.cols[2],
                                    z_val = coefs.cols[3])

