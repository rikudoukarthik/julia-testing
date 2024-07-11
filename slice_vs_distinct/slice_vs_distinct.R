require(tidyverse)
require(bench)

data <- read.delim("data/ebd_IN-KA-BN_smp_relMay-2024.txt",
            sep = "\t", header = T, quote = "", 
            stringsAsFactors = F, na.strings = c(""," ",NA))

data <- data |> 
  mutate(group.id = ifelse(is.na(GROUP.IDENTIFIER), 
                                  SAMPLING.EVENT.IDENTIFIER, GROUP.IDENTIFIER)) |> 
  group_by(group.id) %>% 
  mutate(no.sp = n_distinct(COMMON.NAME)) %>%
  ungroup()


method1 <- function(input) {

  output <- input %>%
    group_by(group.id, COMMON.NAME) %>% 
    slice(1) %>% 
    ungroup()

  return(output)

}

method2 <- function(input) {

  output <- input |> 
    distinct(group.id, COMMON.NAME, .keep_all = TRUE) |> 
    arrange(group.id, COMMON.NAME) |> 
    as_tibble()

  return(output)

}

# benchmark 
benchmarked <- bench::mark(
  ORIGINAL = method1(data),
  DISTINCT = method2(data),
  iterations = 3
)

benchmark_method2 <- bench::mark(
  DISTINCT = method2(data),
  iterations = 10
)

# write benchmark summary
benchmarked |> 
  dplyr::select(-result, -gc, -memory, -time)  |> 
  write_csv(file = "slice_vs_distinct/benchmark.csv")


###


data1a <- data |> 
  distinct(group.id, LONGITUDE, LATITUDE) %>% 
  group_by(group.id) %>% 
  slice(1) %>% 
  ungroup()

data1b <- data |> 
  distinct(group.id, LONGITUDE, LATITUDE) %>% 
  distinct(group.id, .keep_all = TRUE) |> 
  arrange(group.id) |> 
  as_tibble()

all.equal(data1a, data1b)


###


completelistcheck = function(data) {
  require(tidyverse)
  require(lubridate)

  data = data %>% 
    # create 2 columns from the "TIME.OBSERVATIONS.STARTED' column
    mutate(DATETIME = as_datetime(paste("2023-06-01", # any date, we just need the time
                                        TIME.OBSERVATIONS.STARTED)),
           hr = hour(DATETIME),
           min = minute(DATETIME)) %>% 
    # calculate speed and species/unit time (sut)
    mutate(speed = EFFORT.DISTANCE.KM*60/DURATION.MINUTES, # kmph
           sut = no.sp*60/DURATION.MINUTES, # species per hour
           # calculate hour checklist ended
           end = floor((hr*60 + min + DURATION.MINUTES)/60))
  
  # set thresholds for speed and sut
  vel = 20
  time = 2
  
  
  # exclude any list that may in fact be incomplete ###
  
  temp = data %>%
    # list of on-paper complete lists
    filter(ALL.SPECIES.REPORTED == 1, PROTOCOL.TYPE != "Incidental") %>%
    group_by(group.id) %>% 
    slice(1)
  
  # choose checklists without info on duration with 3 or fewer species
  grp = temp %>%
    filter(no.sp <= 3, is.na(DURATION.MINUTES)) %>%
    distinct(group.id)
  grp = grp$group.id
  
  # exclude records based on various criteria 
  data = data %>%
    mutate(ALL.SPECIES.REPORTED = case_when(
      # fake complete lists
      ALL.SPECIES.REPORTED == 1 & 
        (EFFORT.DISTANCE.KM > 10 | # remove travelling lists covering >10 km
           group.id %in% grp | # lists without info on duration with 3 or fewer species
           speed > vel | # too fast
           (DURATION.MINUTES < 3) | # too short
           (sut < time & no.sp <= 3) | # species per unit time too slow
           PROTOCOL.TYPE == "Incidental" | # incidental
           (!is.na(hr) & ((hr <= 4 & end <= 4) | # nocturnal filter
                            (hr >= 20 & end <= 28)))) ~ 0, 
      # true incomplete lists
      ALL.SPECIES.REPORTED == 0 ~ 0,
      # true complete lists
      TRUE ~ 1
    )) %>% 
    dplyr::select(-speed,-sut,-hr,-min,-end, -DATETIME) 
}
completelistcheck2 <- function(data) {

  require(tidyverse)
  require(lubridate)

  data = data %>% 
    # create 2 columns from the "TIME.OBSERVATIONS.STARTED' column
    mutate(DATETIME = as_datetime(paste("2023-06-01", # any date, we just need the time
                                        TIME.OBSERVATIONS.STARTED)),
           hr = hour(DATETIME),
           min = minute(DATETIME)) %>% 
    # calculate speed and species/unit time (sut)
    mutate(speed = EFFORT.DISTANCE.KM*60/DURATION.MINUTES, # kmph
           sut = no.sp*60/DURATION.MINUTES, # species per hour
           # calculate hour checklist ended
           end = floor((hr*60 + min + DURATION.MINUTES)/60))
  
  # set thresholds for speed and sut
  vel = 20
  time = 2
  
  
  # exclude any list that may in fact be incomplete ###
  
  grp = data %>%
    # only need checklist metadata
    distinct(group.id, .keep_all = TRUE) |> 
    # list of on-paper complete lists
    filter(ALL.SPECIES.REPORTED == 1, PROTOCOL.TYPE != "Incidental") %>%
    # choose checklists without info on duration with 3 or fewer species
    filter(no.sp <= 3, is.na(DURATION.MINUTES)) %>%
    pull(group.id)
  
  # exclude records based on various criteria 
  data = data %>%
    mutate(ALL.SPECIES.REPORTED = case_when(
      # fake complete lists
      ALL.SPECIES.REPORTED == 1 & 
        (EFFORT.DISTANCE.KM > 10 | # remove travelling lists covering >10 km
           group.id %in% grp | # lists without info on duration with 3 or fewer species
           speed > vel | # too fast
           (DURATION.MINUTES < 3) | # too short
           (sut < time & no.sp <= 3) | # species per unit time too slow
           PROTOCOL.TYPE == "Incidental" | # incidental
           (!is.na(hr) & ((hr <= 4 & end <= 4) | # nocturnal filter
                            (hr >= 20 & end <= 28)))) ~ 0, 
      # true incomplete lists
      ALL.SPECIES.REPORTED == 0 ~ 0,
      # true complete lists
      TRUE ~ 1
    )) %>% 
    dplyr::select(-speed,-sut,-hr,-min,-end,-DATETIME)

  return(data)

}
completelistcheck3 <- function(data) {

  require(tidyverse)
  require(lubridate)

  data_filt = data %>% 
    # only need checklist metadata
    distinct(group.id, .keep_all = TRUE) |> 
    # create 2 columns from the "TIME.OBSERVATIONS.STARTED' column
    mutate(DATETIME = as_datetime(paste("2023-06-01", # any date, we just need the time
                                        TIME.OBSERVATIONS.STARTED)),
           hr = hour(DATETIME),
           min = minute(DATETIME)) %>% 
    # calculate speed and species/unit time (sut)
    mutate(speed = EFFORT.DISTANCE.KM*60/DURATION.MINUTES, # kmph
           sut = no.sp*60/DURATION.MINUTES, # species per hour
           # calculate hour checklist ended
           end = floor((hr*60 + min + DURATION.MINUTES)/60))
  
  # set thresholds for speed and sut
  vel = 20
  time = 2
  
  
  # exclude any list that may in fact be incomplete ###
  
  grp = data_filt %>%
    # list of on-paper complete lists
    filter(ALL.SPECIES.REPORTED == 1, PROTOCOL.TYPE != "Incidental") %>%
    # choose checklists without info on duration with 3 or fewer species
    filter(no.sp <= 3, is.na(DURATION.MINUTES)) %>%
    pull(group.id)
  
  # exclude records based on various criteria 
  data_filt = data_filt %>%
    mutate(ALL.SPECIES.REPORTED = case_when(
      # fake complete lists
      ALL.SPECIES.REPORTED == 1 & 
        (EFFORT.DISTANCE.KM > 10 | # remove travelling lists covering >10 km
           group.id %in% grp | # lists without info on duration with 3 or fewer species
           speed > vel | # too fast
           (DURATION.MINUTES < 3) | # too short
           (sut < time & no.sp <= 3) | # species per unit time too slow
           PROTOCOL.TYPE == "Incidental" | # incidental
           (!is.na(hr) & ((hr <= 4 & end <= 4) | # nocturnal filter
                            (hr >= 20 & end <= 28)))) ~ 0, 
      # true incomplete lists
      ALL.SPECIES.REPORTED == 0 ~ 0,
      # true complete lists
      TRUE ~ 1
    )) %>% 
    dplyr::select(-speed,-sut,-hr,-min,-end) |> 
    distinct(group.id, ALL.SPECIES.REPORTED)

  # joining updated ALL.SPECIES.REPORTED column back to original
  data <- data |> 
    dplyr::select(-ALL.SPECIES.REPORTED) |> 
    left_join(data_filt, by = "group.id")

  return(data)

}

data2a <- completelistcheck(data) |> 
  relocate(ALL.SPECIES.REPORTED, .after = last_col())
data2b <- completelistcheck2(data)
data2c <- completelistcheck3(data)
all.equal(data2a, data2c)

# 3rd method results in slight discrepancies: group lists where a different version 
# gets sliced and therefore gets filtered out in the complete list check.
# Plus, it does not offer much of a time advantage, so going with 2nd.