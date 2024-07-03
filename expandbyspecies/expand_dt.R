expand_dt = function(data_exp, species) {

  require(tidyverse)
  require(dtplyr)
  require(data.table)
  

  setDT(data_exp)
  data_exp <- data_exp %>% 
    lazy_dt(immutable = FALSE) |> 
    mutate(across(contains("gridg"), ~ as.factor(.))) %>% 
    mutate(timegroups = as.factor(timegroups)) |> 
    as.data.table()


  # Get distinct rows and filter based on a condition
  # (using base data.table because lazy_dt with immutable == FALSE would
  # modify data_exp even though we are assigning to checklistinfo.
  # and immutable == TRUE copies the data and this is a huge bottleneck)
  # considers only complete lists
  checklistinfo <- unique(data_exp[, 
      .(gridg1, gridg2, gridg3, gridg4, ALL.SPECIES.REPORTED, OBSERVER.ID, 
        group.id, month, year, no.sp, timegroups, timegroups1)
      ])[
        # filter
      ALL.SPECIES.REPORTED == 1
    ]
  
  checklistinfo <- checklistinfo[
    , 
    .SD[1], # subset of data
    by = group.id
]
  
    
  # expand data frame to include the bird species in every list
  data_exp2 = checklistinfo %>% 
    lazy_dt(immutable = FALSE) |> 
    mutate(COMMON.NAME = species) %>% 
    left_join(data_exp |> lazy_dt(immutable = FALSE),
              by = c("group.id", "gridg1", "gridg2", "gridg3", "gridg4",
                      "ALL.SPECIES.REPORTED", "OBSERVER.ID", "month", "year", 
                      "no.sp", "timegroups", "timegroups1", "COMMON.NAME")) %>%
    dplyr::select(-c("COMMON.NAME","gridg2","gridg4","OBSERVER.ID",
                     "ALL.SPECIES.REPORTED","group.id","year","timegroups1",
                     "gridg0","DATETIME")) %>% 
    # deal with NAs (column is character)
    mutate(OBSERVATION.COUNT = case_when(is.na(OBSERVATION.COUNT) ~ 0,
                                       OBSERVATION.COUNT != "0" ~ 1, 
                                       TRUE ~ as.numeric(OBSERVATION.COUNT))) |> 
    as_tibble()

  detach("package:dtplyr", unload = TRUE)
  
  return(data_exp2)

}

