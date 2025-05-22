# Julia testing

There are two main computation bottlenecks in the SoIB pipeline: our GLMM models run for every species across every habitat mask 1000 times; and a data manipulation step where we expand the eBird presence dataset to get absence rows. These are attempts at optimising these steps using alternative approaches.

## Species trend models (`model-convergence/`)

Figured out the pipelines to successfully run models [from R using JuliaCall](https://github.com/rikudoukarthik/julia-testing/blob/main/model-convergence/model_julia.R) and [from Julia using RCall](https://github.com/rikudoukarthik/julia-testing/blob/main/model-convergence/model_julia.jl), and compared these with models [from R using R (lme4)](https://github.com/rikudoukarthik/julia-testing/blob/main/model-convergence/model_r.R). 

### Summary

- Model estimates are very similar, so this is not a concern at all. (See coefficients of [Julia](https://github.com/rikudoukarthik/julia-testing/blob/main/model-convergence/coef_julia.csv) and [R](https://github.com/rikudoukarthik/julia-testing/blob/main/model-convergence/coef_r.csv).)
- For our fully-specified SoIB GLMM (example here, Indian Peafowl), Julia offers no time advantage.
  - `glmer()` in R fits the model in 7 min
  - Julia model with no optimizer specified (docs say BOBYQA is default but not sure) takes 10-13 min in both methods (from R and from Julia)
  - Julia model with NELDERMEAD optimizer specified takes 9 min
  - Julia model with BOBYQA optimizer specified (explicitly) takes 6 min
  - Julia model elapsed time varies considerably in each iteration
- For SoIB GLMM using default logit link instead of cloglog link, Julia is on par with R (7 min)
- Real difference, in our dataset, seems to be with a nonsense LMM (with violated assumptions). Julia fits this LMM in 2 sec, compared to 2.5 min in R!
  - In all of the documentation I found online regarding `MixedModels.jl` and comparisons with `lmer()`, none really benchmarked GLMMs, it was all LMMs.
- My takeaway is that we should retain our R GLMM modelling workflow, and not switch to Julia. What we should consider switching to Julia is the non-modelling steps like `expandbyspecies()`.

## Expand species data by filling zeroes (`expandbyspecies/`)

Benchmarked our current `expandbyspecies()` against two alternatives: [one](https://github.com/rikudoukarthik/julia-testing/blob/main/expandbyspecies/expand_julia.R) where only the groupby-slice-ungroup step (most time-consuming step, ~80%) is passed to Julia via `JuliaCall` and the sliced data returned to R; and [another](https://github.com/rikudoukarthik/julia-testing/blob/main/expandbyspecies/expand_dt.R) where all data operations in `expandbyspecies()` are converted from `dplyr` to one of `data.table` or `dtplyr` based on convenience.

### Summary

See [this CSV](https://github.com/rikudoukarthik/julia-testing/blob/main/expandbyspecies/benchmark.csv) for benchmark results. 

- I only did 3 iterations for each call in the interest of time, but it's once again clear that the Julia method (at least `JuliaCall` specifically) is highly volatile. The other two are more consistent.
- The DT method (`data.table`/`dtplyr`) is 5x faster than the current `dplyr` method in `expandbyspecies()`, and also requires much less overhead memory (so better parallelised performance?).
- For the record, `expandbyspecies()` for Indian Peafowl takes around 50% of the time that `glmer()` takes---3-4 min versus 7 min.
- The "`total_time`" column for these 3 iterations suggests that making this change would end up saving us considerable number of hours (days a stretch?) over the 1000 iterations over all species and masks.

_All this benchmarking was done on my laptop, so I'm not really sure how the relative performances of the three methods would change with more powerful hardware on our servers. But I assume absolute values would scale proportionately._
