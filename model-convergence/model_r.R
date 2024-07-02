require(tidyverse)
require(lme4)

# load data
load("data/data_for_test.RData")

system.time(
mod_r <- glmer(OBSERVATION_COUNT ~ month + month:log(no_sp) + timegroups + (1|gridg3/gridg1),
                data = data_mod, family = binomial(link = 'cloglog'), 
                nAGQ = 0, control = glmerControl(optimizer = "bobyqa"))
) # 7 min

coef_df <- summary(mod_r) |> 
  coef() |> 
  as.data.frame() |> 
  rownames_to_column("variables")

write.csv(coef_df, file = "model-convergence/coef_r.csv", row.names = FALSE)

# model without clogloglink
system.time(
  mod_r2 <- glmer(OBSERVATION_COUNT ~ month + month:log(no_sp) + timegroups + (1|gridg3/gridg1),
                  data = data_mod, family = binomial, 
                  nAGQ = 0, control = glmerControl(optimizer = "bobyqa"))
  ) # 11 min


# model without Generalized
system.time(
  mod_r2 <- lmer(OBSERVATION_COUNT ~ month + month:log(no_sp) + timegroups + (1|gridg3/gridg1),
                  data = data_mod, 
                  control = lmerControl(optimizer = "bobyqa"))
  ) # 2.5 min
