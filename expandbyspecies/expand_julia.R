# loading singlespeciesrun() from SoIB
source("https://raw.githubusercontent.com/stateofindiasbirds/soib_2023/master/00_scripts/00_functions.R")
rm(list = setdiff(ls(), "expandbyspecies"))

# load data
load("data/dataforanalyses.RData")
  
require(tidyverse)
library(dtplyr)

data_exp = data %>%
    filter(COMMON.NAME == "Indian Peafowl") %>% 
    distinct(gridg3, month) %>% 
    left_join(data)

rm(data)
gc()

data_exp <- data_exp %>% 
    mutate(across(contains("gridg"), ~ as.factor(.))) %>% 
    mutate(timegroups = as.factor(timegroups))


tictoc::tic("step 1") # 8 sec
checklistinfo1 = data_exp %>%
    distinct(gridg1, gridg2, gridg3, gridg4, 
             ALL.SPECIES.REPORTED, OBSERVER.ID, 
             #city,
             #DURATION.MINUTES,EFFORT.DISTANCE.KM,
             group.id, month, year, no.sp, timegroups, timegroups1)
tictoc::toc()


# tictoc::tic("step 2") # 239 sec
# tictoc::tic("step 2a") # 0.1% (0.5 sec)
# checklistinfo2a <- checklistinfo1 %>%
#     filter(ALL.SPECIES.REPORTED == 1) 
# tictoc::toc()
# tictoc::tic("step 2b") # 99.9% (238 sec)
# checklistinfo2 <- checklistinfo2a |> 
#     group_by(group.id) %>% 
#     slice(1) %>% 
#     ungroup()
# tictoc::toc()
# tictoc::toc()



library(JuliaCall)
env_julia <- julia_setup()

julia_library("RCall")
julia_library("DataFrames")
julia_library("DataFramesMeta")
julia_library("DataFramesMeta: @chain")

# data: transfer to Julia (30 sec)
julia_assign("checklistinfo1", checklistinfo1)
julia_command('
@elapsed data_exp2 = @chain checklistinfo1 begin
    @subset(:ALL_SPECIES_REPORTED .== 1) # filter rows
    @groupby(:group_id) # group
    combine(d -> first(d)) # dplyr::summarise
end
')


# trying data.table for the same (0.65 sec)
library(data.table)

tictoc::tic("data.table")
setDT(checklistinfo2a)
checklistinfo2 <- checklistinfo2a[
    , 
    .SD[1], # subset of data
    by = group.id
]
setDF(checklistinfo2)
tictoc::toc()





# tictoc::tic("step 3") # 30-60 sec
# expanded = checklistinfo2 %>% 
#     mutate(COMMON.NAME = "Indian Peafowl") %>% 
#     left_join(data_exp) %>%
#     dplyr::select(-c("COMMON.NAME","gridg2","gridg4","OBSERVER.ID",
#                      "ALL.SPECIES.REPORTED","group.id","year","timegroups1",
#                      "gridg0","DATETIME")) %>% 
#   # deal with NAs (column is character)
#   mutate(OBSERVATION.COUNT = case_when(is.na(OBSERVATION.COUNT) ~ 0,
#                                        OBSERVATION.COUNT != "0" ~ 1, 
#                                        TRUE ~ as.numeric(OBSERVATION.COUNT)))
# tictoc::toc()

# dtplyr
tictoc::tic.clearlog()
tictoc::tic("step 3 in dtplyr") #  sec

expanded <- lazy_dt(checklistinfo2) |> 
    mutate(COMMON.NAME == "Indian Peafowl") |> 
    left_join(lazy_dt(data_exp)) %>%
    dplyr::select(-c("COMMON.NAME","gridg2","gridg4","OBSERVER.ID",
                         "ALL.SPECIES.REPORTED","group.id","year","timegroups1",
                         "gridg0","DATETIME")) %>% 
    # deal with NAs (column is character)
    mutate(OBSERVATION.COUNT = case_when(is.na(OBSERVATION.COUNT) ~ 0,
                                           OBSERVATION.COUNT != "0" ~ 1, 
                                           TRUE ~ as.numeric(OBSERVATION.COUNT))) 

setDF(expanded)
tictoc::toc()
tictoc::toc(log = TRUE, quiet = TRUE)


# data.table
tictoc::tic("step 3 in base data.table") #  sec
setDT(checklistinfo2)
setDT(data_exp)

# Left join 
expanded <- merge(checklistinfo2, data_exp, all.x = TRUE, 
    by = c("group.id", "gridg1", "gridg2", "gridg3", "gridg4", 
    "ALL.SPECIES.REPORTED", "OBSERVER.ID", "month", "year",
    "no.sp", "timegroups", "timegroups1", "COMMON.NAME"))  
# Select and remove columns
columns_to_remove <- c("COMMON.NAME","gridg2","gridg4","OBSERVER.ID",
                       "ALL.SPECIES.REPORTED","group.id","year","timegroups1",
                       "gridg0","DATETIME")
expanded[, (columns_to_remove) := NULL]

# Handle NAs with a conditional mutation
expanded[
    , 
    OBSERVATION.COUNT := ifelse(is.na(OBSERVATION.COUNT), 
                                0,
                                ifelse(OBSERVATION.COUNT != "0", 
                                        1, 
                                        as.numeric(OBSERVATION.COUNT)))
]

setDF(expanded)

tictoc::toc(log = TRUE, quiet = TRUE)
tictoc::tic.log()