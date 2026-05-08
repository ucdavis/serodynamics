#' @title Excluding population parameters
#' @author Sam Schildhauer
#' @description
#'  `ex_popparams` excludes estimated population parameters from final output
#'  [data.frame].
#' @param x A [data.frame] with a `Subject` variable.
#' @returns A filtered [data.frame] excluding population parameters.
#' @keywords internal
ex_popparams <- function(x) { 
  x <- x |>
    dplyr::filter(!(.data$Subject %in% c("mu.par", "prec.par", "prec.logy")))
  return(x)
} 
