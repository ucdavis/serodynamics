#' @title Unpacking MCMC Object
#' @author Sam Schildhauer
#' @description
#'  `unpack_jags()` takes a long-format MCMC sample (typically created by
#'  applying [ggmcmc::ggs()] to the `mcmc` component of [run_mod] output)
#'  and unpacks it into separate rows for individual-level curve parameters
#'  and population-level hyperparameters/precision terms.
#' @param data A [tibble::tbl_df] in [ggmcmc::ggs()] / MCMC-long format,
#'   usually `ggmcmc::ggs(jags_post[["mcmc"]])` where `jags_post` comes from
#'   [run_mod]. Must contain at least `Iteration`, `Chain`, `Parameter`,
#'   and `value` columns.
#' @returns A [tibble::tbl_df] containing MCMC samples from the joint
#' posterior distribution of the model with unpacked individual-level
#' parameters (e.g., `y0`, `y1`, `t1`, `alpha`, `shape`) and
#' population-level parameters (e.g., `mu.par`, `prec.par`, `prec.logy`),
#' along with subject-related fields such as `Subject` and `Subnum`.
#' Isotype names are not added by `unpack_jags()` itself.
#' @keywords internal
unpack_jags <- function(data) {
  
  # Convert Parameter column to character if it's a factor (from ggmcmc::ggs)
  if (is.factor(data$Parameter)) {
    data$Parameter <- as.character(data$Parameter)
  }

  unpack_with_pattern <- function(data, filter_pattern, regex_pattern,
                                  subject_repl, subnum_repl, param_fun) {
    data |>
      dplyr::filter(
        startsWith(.data$Parameter, paste0(filter_pattern, "[")) |
          .data$Parameter == filter_pattern
      ) |>
      dplyr::mutate(
        Subject = dplyr::if_else(
          .data$Parameter == filter_pattern,
          filter_pattern,
          gsub(regex_pattern, subject_repl, .data$Parameter)
        ),
        Subnum = dplyr::if_else(
          .data$Parameter == filter_pattern,
          "1",
          gsub(regex_pattern, subnum_repl, .data$Parameter)
        ),
        Param = param_fun(.data$Parameter, regex_pattern)
      )
  }

  # Regular expressions for unpacking
  regex_twoidx <- "([[:alnum:].]+)\\[([0-9]+),([0-9]+)\\]"       # e.g. x[1,2]
  regex_threeidx <- "([[:alnum:].]+)\\[([0-9]+),([0-9]+),([0-9]+)\\]"
  # e.g. x[1,2,3]
  regex_oneidx <- "([[:alnum:].]+)\\[([0-9]+)\\]"                 # e.g. x[1]

  # Unpacking mu.par
  # Separating population parameters from the rest of the data
  jags_mupar <- unpack_with_pattern(
    data = data,
    filter_pattern = "mu.par",
    regex_pattern = regex_twoidx,
    subject_repl = "\\1",
    subnum_repl = "\\2",
    param_fun = function(param, pattern) {
      param_recode(gsub(pattern, "\\3", param))
    }
  )

  # Unpacking prec.par
  jags_precpar <- unpack_with_pattern(
    data = data,
    filter_pattern = "prec.par",
    regex_pattern = regex_threeidx,
    subject_repl = "\\1",
    subnum_repl = "\\2",
    param_fun = function(param, pattern) {
      paste0(
        param_recode(gsub(pattern, "\\3", param)), ", ",
        param_recode(gsub(pattern, "\\4", param))
      )
    }
  )

  # Unpacking prec.logy
  jags_preclogy <- unpack_with_pattern(
    data = data,
    filter_pattern = "prec.logy",
    regex_pattern = regex_oneidx,
    subject_repl = "\\1",
    subnum_repl = "\\2",
    param_fun = function(param, pattern) {
      "prec.logy"
    }
  )

  # Working with jags unpacked ggs outputs to clarify parameter and subject
  jags_unpack_params <- data |>
    dplyr::mutate(
      Subject = gsub(regex_twoidx, "\\2", .data$Parameter),
      Subnum = gsub(regex_twoidx, "\\3", .data$Parameter),
      Param = gsub(regex_twoidx, "\\1", .data$Parameter)
    ) |> 
    dplyr::filter(.data$Param %in% c("y0", "y1", "t1", "alpha", "shape"))

  # Putting data frame together, marking population-parameter rows explicitly
  jags_unpack_bind <- dplyr::bind_rows(
    dplyr::mutate(jags_unpack_params, .is_population_parameter = FALSE),
    dplyr::mutate(jags_mupar,         .is_population_parameter = TRUE),
    dplyr::mutate(jags_precpar,       .is_population_parameter = TRUE),
    dplyr::mutate(jags_preclogy,      .is_population_parameter = TRUE)
  )

  jags_unpack_bind
}
