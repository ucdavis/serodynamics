#' @title Excluding population parameters
#' @author Sam Schildhauer
#' @description
#'  `ex_popparams` excludes estimated population parameters from final output
#'  [data.frame].
#' @param x A [data.frame] with a `.is_population_parameter` variable.
#' @returns A filtered [data.frame] excluding population parameters.
#' @keywords internal
ex_popparams <- function(x) {
  x |>
    dplyr::filter(!.data$.is_population_parameter) |>
    dplyr::select(-c(".is_population_parameter"))
}
