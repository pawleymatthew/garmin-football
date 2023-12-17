read_fit <- function(file) {
  temp <- FITfileR::readFitFile(file)
  laps <- laps(temp)
  records <- records(temp) %>% 
    dplyr::bind_rows() %>%
    dplyr::arrange(timestamp) %>%
    dplyr::rename(lng = position_long, lat = position_lat) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(lap = sum(laps$start_time <= timestamp)) %>%
    dplyr::ungroup()
  return(records)
}

ex_basis <- function(x, y, id) {
  c(x[id == "RF"] - x[id == "RB"], y[id == "RF"] - y[id == "RB"])
}

ey_basis <- function(x, y, id) {
  c(x[id == "LB"] - x[id == "RB"], y[id == "LB"] - y[id == "RB"])
}

ll_to_xy <- function(lng, lat, ex, ey) {
  pracma::linearproj(A = cbind(ex, ey), B = rbind(lng, lat))$P
}