expand_dtplyr = function(data, species) {

  require(tidyverse)
  require(dtplyr)
  require(data.table)
  
  data_exp <- data

  setDT(data_exp)
  data_exp <- data_exp %>% 
    lazy_dt(immutable = FALSE) |> 
    mutate(across(contains("gridg"), ~ as.factor(.))) %>% 
    mutate(timegroups = as.factor(timegroups))

  # considers only complete lists
  
  checklistinfo = data_exp %>%
    distinct(gridg1, gridg2, gridg3, gridg4, 
             ALL.SPECIES.REPORTED, OBSERVER.ID, 
             #city,
             #DURATION.MINUTES,EFFORT.DISTANCE.KM,
             group.id, month, year, no.sp, timegroups, timegroups1) %>%
    filter(ALL.SPECIES.REPORTED == 1) |> 
    as.data.table()
  
  checklistinfo <- checklistinfo[
    , 
    .SD[1], # subset of data
    by = group.id
]
  
    
  # expand data frame to include the bird species in every list
  data_exp2 = checklistinfo %>% 
    lazy_dt(immutable = FALSE) |> 
    mutate(COMMON.NAME = species) %>% 
    left_join(data_exp) %>%
    dplyr::select(-c("COMMON.NAME","gridg2","gridg4","OBSERVER.ID",
                     "ALL.SPECIES.REPORTED","group.id","year","timegroups1",
                     "gridg0","DATETIME")) %>% 
    # deal with NAs (column is character)
    mutate(OBSERVATION.COUNT = case_when(is.na(OBSERVATION.COUNT) ~ 0,
                                       OBSERVATION.COUNT != "0" ~ 1, 
                                       TRUE ~ as.numeric(OBSERVATION.COUNT))) |> 
    as_tibble()

  return(data_exp2)

}

# why is error "object gridg0 not found"?