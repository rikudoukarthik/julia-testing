expand_julia = function(data, species) {
    
    require(tidyverse)
    require(JuliaCall)
    
    
    data <- data %>% 
        mutate(across(contains("gridg"), ~ as.factor(.))) %>% 
        mutate(timegroups = as.factor(timegroups))
    
    
    checklistinfo = data %>%
        distinct(gridg1, gridg2, gridg3, gridg4, 
                 ALL.SPECIES.REPORTED, OBSERVER.ID, 
                 group.id, month, year, no.sp, timegroups, timegroups1) %>%
        filter(ALL.SPECIES.REPORTED == 1) 
        
    
    env_julia <- julia_setup()
    julia_library("RCall")
    julia_library("DataFrames")
    julia_library("DataFramesMeta")
    julia_library("DataFramesMeta: @chain")
    
    # data: transfer to Julia (30 sec)
    julia_assign("checklistinfo", checklistinfo)
    julia_command('
        checklistinfo = @chain checklistinfo begin
            @subset(:ALL_SPECIES_REPORTED .== 1) # filter rows
            @groupby(:group_id) # group
            combine(first) # dplyr::summarise
        end
    ')
    # Save to R
    julia_command("@rput checklistinfo")
    
    # converting column names that have changed to _ in Julia back to .
    names(checklistinfo) <- gsub("_", ".", names(checklistinfo))
    
    # below step (especially left join) cannot be Julia-fied because
    # that needs data to be transferred, which is essentially
    # creating a copy, and therefore, not feasible
    data = checklistinfo %>% 
        mutate(COMMON.NAME = species) %>% 
        left_join(data,
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

    rm(checklistinfo)
            
    return(data)

}

# see this for interesting comparison with R
# https://yjunechoe.github.io/posts/2022-11-13-dataframes-jl-and-accessories/