julia_prep <- function(data) {

  data = data %>%
    filter(COMMON.NAME == "Indian Peafowl") %>% 
    distinct(gridg3, month) %>% 
    left_join(data)
  
  tm = data %>% distinct(timegroups)

  datay = data %>%
    group_by(gridg3, gridg1, group.id) %>% 
    slice(1) %>% 
    group_by(gridg3, gridg1) %>% 
    reframe(medianlla = median(no.sp)) %>%
    group_by(gridg3) %>% 
    reframe(medianlla = mean(medianlla)) %>%
    reframe(medianlla = round(mean(medianlla)))
  
  medianlla = datay$medianlla
  
  
  # expand dataframe to include absences as well
  ed = expandbyspecies(data, "Indian Peafowl") %>% 
    # converting months to seasons
    mutate(month = as.numeric(month)) %>% 
    mutate(month = case_when(month %in% c(12,1,2) ~ "Win",
                             month %in% c(3,4,5) ~ "Sum",
                             month %in% c(6,7,8) ~ "Mon",
                             month %in% c(9,10,11) ~ "Aut")) %>% 
    mutate(month = as.factor(month))
  
  
  return(ed)
  
}