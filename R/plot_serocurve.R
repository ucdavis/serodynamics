#' @title Plot Estimated Serodynamic Curves at the Population Level
#' @description
#' Plots the estimated antibody response curve derived from posterior samples
#' of population-level (`mu.par`) or the predictive distribution from a fitted
#' [run_mod()] model.  A median curve with an optional 95% credible interval
#' ribbon is produced for each requested antigen-isotype and stratification
#' combination.
#'
#' @param model An `sr_model` object returned by [run_mod()].
#' @param antigen_iso A [character] vector of antigen-isotype combinations to
#'   plot.  Defaults to all antigen-isotypes present in `model`.
#' @param strat A [character] vector of stratification levels to include.
#'   Defaults to all stratification levels present in `model`.
#' @param param_source [character]; which posterior samples to use for the
#'   curve.  Options:
#'   - `"population"` (default): uses population-level `mu.par` samples stored
#'     in `attr(model, "population_params")`. Requires the model to have been
#'     fitted with `run_mod(..., with_pop_params = TRUE)`.
#'   - `"newperson"`: uses the predictive distribution for a new individual
#'     drawn from the population-level prior.
#' @param show_ci [logical]; if [TRUE] (default), draws a 95% credible
#'   interval ribbon around the median curve.
#' @param log_y [logical]; if [TRUE], applies a [log10] transformation to the
#'   y-axis.  Defaults to [FALSE].
#' @param log_x [logical]; if [TRUE], applies a pseudo-log10 transformation to
#'   the x-axis.  Defaults to [FALSE].
#' @param xlim (Optional) A numeric vector of length 2 giving custom x-axis
#'   limits.
#' @param facet_by_antigen_iso [logical]; if [TRUE], facets the plot by
#'   antigen-isotype.  Defaults to [TRUE] when multiple antigen-isotypes are
#'   requested.
#' @param facet_by_strat [logical]; if [TRUE], facets the plot by
#'   stratification level.  When [FALSE] (default), different stratification
#'   levels are shown as different colours on the same panel.
#' @param ncol [integer]; number of columns when faceting.  If [NULL]
#'   (default), a sensible value is chosen automatically.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#'
#' @example inst/examples/examples-plot_serocurve.R
plot_serocurve <- function(
    model,
    antigen_iso = unique(model$Iso_type),
    strat = unique(model$Stratification),
    param_source = "population",
    show_ci = TRUE,
    log_y = FALSE,
    log_x = FALSE,
    xlim = NULL,
    facet_by_antigen_iso = length(antigen_iso) > 1,
    facet_by_strat = FALSE,
    ncol = NULL) {

  param_source <- match.arg(param_source, c("population", "newperson"))

  # ---- Retrieve posterior samples of curve parameters --------------------
  if (param_source == "population") {
    pop_params <- attr(model, "population_params")
    if (is.null(pop_params)) {
      cli::cli_abort(
        c(
          "The {.arg model} object does not have a {.field population_params}",
          " attribute.",
          "i" = paste0(
            "Re-fit the model with",
            " {.code run_mod(..., with_pop_params = TRUE)}."
          )
        )
      )
    }
    # The population_params tibble has columns:
    # Iteration, Chain, Parameter, Iso_type, Stratification,
    # Population_Parameter, value
    # Filter to mu.par rows only, then pivot wider and transform from log scale.
    param_samples <- pop_params |>
      dplyr::filter(
        .data$Population_Parameter == "mu.par",
        .data$Iso_type %in% .env$antigen_iso,
        .data$Stratification %in% .env$strat
      ) |>
      dplyr::select(
        all_of(
          c("Chain", "Iteration", "Parameter", "Iso_type", "Stratification",
            "value")
        )
      ) |>
      tidyr::pivot_wider(
        names_from = "Parameter",
        values_from = "value",
        names_prefix = "log_"
      ) |>
      dplyr::mutate(
        y0    = exp(.data$log_y0),
        y1    = .data$y0 + exp(.data$log_y1),
        t1    = exp(.data$log_t1),
        alpha = exp(.data$log_alpha),
        shape = exp(.data$log_shape) + 1
      ) |>
      dplyr::select(
        -dplyr::starts_with("log_")
      ) |>
      dplyr::mutate(
        Iso_type = factor(.data$Iso_type),
        Stratification = factor(.data$Stratification)
      )
    antigen_iso_col <- "Iso_type"
  } else {
    # "newperson": predictive distribution for a new individual drawn from
    # the population-level prior
    param_samples <- model |>
      dplyr::filter(
        .data$Subject == "newperson",
        .data$Iso_type %in% .env$antigen_iso,
        .data$Stratification %in% .env$strat
      ) |>
      dplyr::select(
        all_of(
          c("Chain", "Iteration", "Parameter", "Iso_type", "Stratification",
            "value")
        )
      ) |>
      tidyr::pivot_wider(
        names_from = "Parameter",
        values_from = "value"
      ) |>
      dplyr::mutate(
        Iso_type = factor(.data$Iso_type),
        Stratification = factor(.data$Stratification)
      )
    antigen_iso_col <- "Iso_type"
  }

  # ---- Compute predicted curves over a grid of time points ---------------
  tx <- seq(0, 1200, by = 5)

  serocourse_all <- param_samples |>
    dplyr::reframe(
      t = .env$tx,
      res = ab(.data$t, .data$y0, .data$y1, .data$t1, .data$alpha,
               .data$shape),
      .by = all_of(
        c("Chain", "Iteration", antigen_iso_col, "Stratification")
      )
    )

  # ---- Summarise to median + 95 % CI -------------------------------------
  curve_summary <- serocourse_all |>
    dplyr::summarise(
      .by = all_of(c(antigen_iso_col, "Stratification", "t")),
      res_med  = stats::quantile(.data$res, probs = 0.50, na.rm = TRUE),
      res_low  = stats::quantile(.data$res, probs = 0.025, na.rm = TRUE),
      res_high = stats::quantile(.data$res, probs = 0.975, na.rm = TRUE)
    )

  # ---- Determine whether to colour by stratification ---------------------
  n_strat <- length(unique(param_samples$Stratification))
  multi_strat <- n_strat > 1 && !facet_by_strat

  # ---- Build the ggplot --------------------------------------------------
  p <- ggplot2::ggplot() +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Time since onset", y = "Assay result") +
    ggplot2::theme(legend.position = "bottom")

  if (show_ci) {
    if (multi_strat) {
      p <- p +
        ggplot2::geom_ribbon(
          data = curve_summary,
          ggplot2::aes(
            x = .data$t,
            ymin = .data$res_low,
            ymax = .data$res_high,
            fill = .data$Stratification
          ),
          alpha = 0.2,
          inherit.aes = FALSE
        )
    } else {
      p <- p +
        ggplot2::geom_ribbon(
          data = curve_summary,
          ggplot2::aes(
            x = .data$t,
            ymin = .data$res_low,
            ymax = .data$res_high,
            fill = "ci"
          ),
          alpha = 0.2,
          inherit.aes = FALSE
        )
    }
  }

  # Median line
  if (multi_strat) {
    p <- p +
      ggplot2::geom_line(
        data = curve_summary,
        ggplot2::aes(
          x = .data$t,
          y = .data$res_med,
          colour = .data$Stratification
        ),
        linewidth = 1,
        inherit.aes = FALSE
      )
  } else {
    p <- p +
      ggplot2::geom_line(
        data = curve_summary,
        ggplot2::aes(
          x = .data$t,
          y = .data$res_med,
          colour = "median"
        ),
        linewidth = 1,
        inherit.aes = FALSE
      )
  }

  # ---- Legend for single-stratification plots ----------------------------
  if (!multi_strat) {
    color_vals <- c("median" = "red")
    color_labels <- c("median" = "Median")

    fill_vals <- c("ci" = "red")
    fill_labels <- c("ci" = "95% credible interval")

    p <- p +
      ggplot2::scale_color_manual(
        name = "",
        values = color_vals,
        labels = color_labels,
        guide = ggplot2::guide_legend(override.aes = list(shape = NA))
      ) +
      ggplot2::scale_fill_manual(
        name = "",
        values = fill_vals,
        labels = fill_labels,
        guide = ggplot2::guide_legend(override.aes = list(color = NA))
      )
  }

  # ---- Faceting ----------------------------------------------------------
  facet_vars <- character(0)
  if (facet_by_antigen_iso) facet_vars <- c(facet_vars, antigen_iso_col)
  if (facet_by_strat)       facet_vars <- c(facet_vars, "Stratification")

  if (length(facet_vars) > 0) {
    facet_formula <- stats::as.formula(
      paste("~", paste(facet_vars, collapse = " + "))
    )
    if (is.null(ncol)) {
      n_panels <- length(unique(interaction(
        curve_summary[[facet_vars[1]]],
        if (length(facet_vars) > 1) curve_summary[[facet_vars[2]]] else NULL
      )))
      ncol <- if (n_panels == 1) {
        1
      } else if (n_panels <= 4) {
        2
      } else {
        NULL
      }
    }
    p <- p + ggplot2::facet_wrap(facet_formula, ncol = ncol)
  }

  # ---- Log scales --------------------------------------------------------
  if (log_y) {
    p <- p + ggplot2::scale_y_log10()
  }
  if (log_x) {
    p <- p +
      ggplot2::scale_x_continuous(
        trans = scales::pseudo_log_trans(sigma = 1, base = 10)
      )
  }

  # ---- Custom x-axis limits ----------------------------------------------
  if (!is.null(xlim)) {
    p <- p + ggplot2::coord_cartesian(xlim = xlim)
  }

  return(p)
}
