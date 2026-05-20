
#' @title Summary Table of Jags Posterior Estimates
#' @author Sam Schildhauer
#' @description
#'  `post_summ()` takes an `sr_model` tibble returned by [run_mod]
#'  to summary table for parameter, antigen/antibody, and stratification
#'  combination.
#'  Defaults will produce every combination of antigen/antibody, parameters,
#'  and stratifications, unless otherwise specified.
#'  Antigen/antibody combinations and stratifications will vary by analysis.
#'  The antibody dynamic curve includes the following parameters:
#'  - y0 = baseline antibody concentration
#'  - y1 = peak antibody concentration
#'  - t1 = time to peak
#'  - shape = shape parameter
#'  - alpha = decay rate
#' @param data An `sr_model` tibble returned by [run_mod].
#' @param iso Specify [character] string to produce tables of only a
#' specific antigen/antibody combination, entered with quotes. Default outputs
#' all antigen/antibody combinations.
#' @param param Specify [character] string to produce tables of only a
#' specific parameter, entered with quotes. Options include:
#' - `alpha` = posterior estimate of decay rate
#' - `shape` = posterior estimate of shape parameter
#' - `t1` = posterior estimate of time to peak
#' - `y0` = posterior estimate of baseline antibody concentration
#' - `y1` = posterior estimate of peak antibody concentration
#' @param strat Specify [character] string to produce tables of specific
#' stratification entered in quotes.
#' @return A [data.frame] summarizing estimate mean, standard deviation (SD), 
#' median, and quantiles (2.5%, 25.0%, 50.0%, 75.0%, 97.5%).
#' @export
#' @examples
#' post_summ(data = serodynamics::nepal_sees_jags_output)

post_summ <- function(data,
                      iso = unique(data$Iso_type),
                      param = unique(data$Parameter),
                      strat = unique(data$Stratification)) {

  summarize_jags <- data |>
    dplyr::filter(.data$Iso_type %in% iso) |>
    dplyr::filter(.data$Parameter %in% param) |>
    dplyr::filter(.data$Stratification %in% strat)  |>
    dplyr::filter(.data$Subject == "newperson")

  summarize_jags <- summarize_jags |>
    dplyr::group_by(.data$Iso_type, .data$Parameter, 
                    .data$Stratification) |>
    dplyr::summarize(Mean = mean(.data$value), 
                     SD = stats::sd(.data$value), 
                     Median = stats::median(.data$value), 
                     `2.5%` = quantile(.data$value, 0.025), 
                     `25.0%` = quantile(.data$value, 0.25), 
                     `50.0%` = quantile(.data$value, 0.50), 
                     `75.0%` = quantile(.data$value, 0.75), 
                     `97.5%` = quantile(.data$value, 0.975))
  tibble::as_tibble(summarize_jags)
}
