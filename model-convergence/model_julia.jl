using Pkg

# Pkg.add("RCall")
# Pkg.add("DataFrames")
# Pkg.add("MixedModels")
# Pkg.add("GLM")
# Pkg.add("CSV")

using MixedModels, RCall, GLM, DataFrames, CSV

# evaluate below in R environment using RCall
R"""
require(lme4)

load("data/data_for_test.RData")
attach("data/data_for_test.RData")

mod_formula <- OBSERVATION_COUNT ~ month + month:log(no_sp) + timegroups + (1|gridg3/gridg1)
"""

# data: copy from R
data_mod = rcopy(R"data_mod")
# model: define
form_mod = rcopy(R"mod_formula")
str_mod = GeneralizedLinearMixedModel(form_mod, data_mod, Binomial(), CloglogLink())
str_mod.optsum.optimizer = :LN_BOBYQA

# fit model
@elapsed mod_julia = fit!(str_mod, fast = true) 
# 10-13 min with no optimizer specified (isn't BOBYQA default?)
# 9 min with NELDERMEAD
# 6 min with BOBYQA
# but the elapsed time varies considerably in each iteration

# getting model coefficients and saving as dataframe in R
coefs = coeftable(mod_julia)
coef_df = DataFrame(variable = coefs.rownms,
                                    Estimate = coefs.cols[1],
                                    StdError = coefs.cols[2],
                                    z_val = coefs.cols[3])

CSV.write("model-convergence/coef_julia.csv", coef_df)

# model without clogloglink
str_mod2 = GeneralizedLinearMixedModel(form_mod, data_mod, Binomial())
str_mod2.optsum.optimizer = :LN_BOBYQA

@elapsed mod_julia2 = fit!(str_mod2, fast = true) 
# 7 min without clogloglink


# model without Generalized
@elapsed mod_julia3 = fit(LinearMixedModel, form_mod, data_mod) 
# 2 sec