#' @title Preparing population parameters
#' @author Sam Schildhauer
#' @description
#'  `prep_popparams` filters a [data.frame] to only include population 
#'  parameters and renames the `Subject` variable as `Population_Parameter`.
#' @param x A [data.frame] with `Subject` and `.is_population_parameter`
#'  variables.
#' @returns A filtered [data.frame] with the `Subject` variable renamed to
#' `Population_Parameter`.
#' @keywords internal
prep_popparams <- function(x) {
  x |>
    dplyr::filter(.data$.is_population_parameter) |>
    dplyr::rename("Population_Parameter" = "Subject") |>
    dplyr::select(-c(".is_population_parameter"))
}
