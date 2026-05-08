#' @title Parameter recode
#' @author Sam Schildhauer
#' @description
#'  `param_recode` recodes character numbers as their corresponding parameter.
#' @param x A [vector] of character numbers that represent parameters.
#' @returns A [vector] with recoded values.
#' @keywords internal
param_recode <- function(x) {
  dplyr::recode(
    x,
    "1" = "y0",
    "2" = "y1",
    "3" = "t1",
    "4" = "alpha",
    "5" = "shape"
  )
}
