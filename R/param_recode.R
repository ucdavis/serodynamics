#' @title Parameter recode
#' @author Sam Schildhauer
#' @description
#'  `param_recode()` recodes JAGS curve-parameter indices (1-5) as their
#'  log-scale parameter labels (e.g., `"log(y0)"`, `"log(alpha)"`).
#' @param x A [vector] of character numbers ("1"-"5") that represent
#'  parameters.
#' @returns A [vector] of log-scale parameter labels.
#' @keywords internal
param_recode <- function(x) {
  map <- c("1" = "log(y0)", 
           "2" = "log(y1 - y0)",
           "3" = "log(t1)", 
           "4" = "log(alpha)", 
           "5" = "log(shape - 1)")
  unname(map[as.character(x)])
}
