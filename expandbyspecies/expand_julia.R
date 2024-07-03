expand_julia = function(data_exp, species) {
    
    require(tidyverse)
    require(JuliaCall)
    
    
    data_exp <- data_exp %>% 
        mutate(across(contains("gridg"), ~ as.factor(.))) %>% 
        mutate(timegroups = as.factor(timegroups))
    
    
    checklistinfo = data_exp %>%
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
            combine(d -> first(d)) # dplyr::summarise
        end
    ')
    # Save to R
    julia_command("@rput checklistinfo")
    
    
    # below step (especially left join) cannot be Julia-fied because
    # that needs data_exp to be transferred, which is essentially
    # creating a copy, and therefore, not feasible
    data_exp = checklistinfo %>% 
        mutate(COMMON.NAME = "Indian Peafowl") %>% 
        left_join(data_exp,
                    by = c("group.id", "gridg1", "gridg2", "gridg3", "gridg4",
                    "ALL.SPECIES.REPORTED", "OBSERVER.ID", "month", "year", 
                    "no.sp", "timegroups", "timegroups1", "COMMON.NAME")) %>%
        dplyr::select(-c("COMMON.NAME","gridg2","gridg4","OBSERVER.ID",
                            "ALL.SPECIES.REPORTED","group.id","year","timegroups1",
                            "gridg0","DATETIME")) %>% 
        # deal with NAs (column is character)
        mutate(OBSERVATION.COUNT = case_when(is.na(OBSERVATION.COUNT) ~ 0,
                                                OBSERVATION.COUNT != "0" ~ 1, 
                                                TRUE ~ as.numeric(OBSERVATION.COUNT)))
            
    return(data_exp)

}
