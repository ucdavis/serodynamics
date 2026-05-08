#' @title Generate Predicted Antibody Response Curves (Median + 95% CI)
#' @description
#' Plots a median antibody response curve with a 95% credible interval 
#' ribbon, using MCMC samples from the posterior distribution. 
#' Optionally overlays observed data, 
#' applies logarithmic spacing on the y- and x-axes, 
#' and shows all individual 
#' sampled curves.
#'
#' @param model An `sr_model` object (returned by [run_mod]) containing 
#'   samples from the posterior distribution of the model parameters.
#' @param ids The participant IDs to plot; for example, `"sees_npl_128"`.
#' @param antigen_iso  The antigen isotype to plot; for example, "HlyE_IgA" or 
#' "HlyE_IgG".
#' @param dataset (Optional) A [tibble::tbl_df] with observed antibody response
#' data. 
#' Must contain:
#'   - `timeindays`
#'   - `value`
#'   - `id`
#'   - `antigen_iso`
#' @param legend_obs Label for observed data in the legend.
#' @param legend_median Label for the median prediction line.
#' @param show_quantiles [logical]; if [TRUE] (default), plots the 2.5%, 50%, 
#' and 97.5% quantiles.
#' @param log_y [logical]; if [TRUE], applies a [log10] transformation to 
#' the y-axis.
#' @param log_x [logical]; if [TRUE], applies a [log10] transformation to the 
#' x-axis.
#' @param show_all_curves [logical]; if [TRUE], overlays all 
#' individual sampled curves.
#' @param alpha_samples Numeric; transparency level for individual 
#' curves (default = 0.3).
#' @param xlim (Optional) A numeric vector of length 2 providing custom x-axis 
#' limits.
#' @param ylab (Optional) A string for the y-axis label. If `NULL` (default), 
#' the label is automatically set to "ELISA units" or "ELISA units (log scale)"
#' based on the `log_y` argument.
#' @param facet_by_id [logical]; if [TRUE], facets the plot by 'id'. 
#' Defaults to [TRUE] when multiple IDs are provided.
#' @param ncol [integer]; number of columns for faceting.
#'
#' @return A [ggplot2::ggplot] object displaying predicted antibody response 
#' curves with a median curve and a 95% credible interval band as default.
#' @export
#'
#' @example inst/examples/examples-plot_predicted_curve.R
plot_predicted_curve <- function(model,
                                 ids,
                                 antigen_iso,
                                 dataset = NULL,
                                 legend_obs = "Observed data",
                                 legend_median = "Median prediction",
                                 show_quantiles = TRUE,
                                 log_y = FALSE,
                                 log_x = FALSE,
                                 show_all_curves = FALSE,
                                 alpha_samples = 0.3,
                                 xlim = NULL,
                                 ylab = NULL,
                                 facet_by_id = length(ids) > 1,
                                 ncol = NULL) {
  
  # Filter to the subject(s) & antigen of interest:
  sr_model_sub <- model |>
    dplyr::filter(
      .data$Subject %in% ids,        # allow multiple IDs
      .data$Iso_type == antigen_iso  # e.g. "HlyE_IgA"
    )
  
  # Pivot to wide format: one row per iteration/chain
  param_medians_wide <- sr_model_sub |>
    dplyr::select(
      all_of(c("Chain",
               "Iteration",
               "Iso_type",
               "Parameter",
               "value",
               "Subject"))
    ) |>
    tidyr::pivot_wider(
      names_from  = c("Parameter"),
      values_from = c("value")
    ) |>
    dplyr::arrange(.data$Chain, .data$Iteration) |>
    dplyr::mutate(
      antigen_iso = factor(.data$Iso_type),
      id = as.factor(.data$Subject),
      r = .data$shape
    ) |>
    dplyr::select(-c("Iso_type", "Subject"))
  
  # Add sample_id if not present (to identify individual samples)
  if (!"sample_id" %in% names(param_medians_wide)) {
    param_medians_wide <- param_medians_wide |>
      dplyr::mutate(sample_id = dplyr::row_number())
  }
  # Define time points for prediction
  tx2 <- seq(0, 1200, by = 5)
  
  ## --- Prepare data for Model 1 ---
  dt1 <- data.frame(t = tx2) |>
    dplyr::mutate(idx = dplyr::row_number()) |>
    tidyr::pivot_wider(names_from = "idx", 
                       values_from = "t", 
                       names_prefix = "time") |>
    dplyr::slice(
      rep(seq_len(dplyr::n()), each = nrow(param_medians_wide))
    )
  
  serocourse_all1 <- cbind(param_medians_wide, dt1) |>
    tidyr::pivot_longer(cols = dplyr::starts_with("time"), values_to = "t") |>
    dplyr::select(-c("name")) |>
    dplyr::mutate(res = ab(.data$t, 
                           .data$y0, 
                           .data$y1, 
                           .data$t1, 
                           .data$alpha, 
                           .data$shape))
  
  # Determine Y-axis label
  if (is.null(ylab)) {
    if (log_y) {
      ylab <- "ELISA units (log scale)"
    } else {
      ylab <- "ELISA units"
    }
  }
  
  # Base ggplot object with legend at the bottom.
  p <- ggplot2::ggplot() +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Days since fever onset", y = ylab) +
    ggplot2::theme(legend.position = "bottom")
  
  # If show_all_curves is TRUE, overlay all individual sampled curves.
  if (show_all_curves) {
    p <- p +
      ggplot2::geom_line(data = serocourse_all1,
                         ggplot2::aes(x = .data$t, 
                                      y = .data$res, 
                                      group = .data$sample_id,
                                      color = "samples"),
                         alpha = alpha_samples)
  }
  
  # --- Summarize & Plot Model 1 (Median + 95% Ribbon) ---
  if (show_quantiles) {
    sum1 <- serocourse_all1 |>
      dplyr::summarise(
        .by = all_of(c("id", "t")),
        res.med  = stats::quantile(.data$res, probs = 0.50, na.rm = TRUE),
        res.low  = stats::quantile(.data$res, probs = 0.025, na.rm = TRUE),
        res.high = stats::quantile(.data$res, probs = 0.975, na.rm = TRUE)
      )
    
    p <- p +
      ggplot2::geom_ribbon(data = sum1,
                           ggplot2::aes(x = .data$t, 
                                        ymin = .data$res.low, 
                                        ymax = .data$res.high, 
                                        fill = "ci"),
                           alpha = 0.2, inherit.aes = FALSE) +
      ggplot2::geom_line(data = sum1,
                         ggplot2::aes(x = .data$t, 
                                      y = .data$res.med, 
                                      color = "median"),
                         linewidth = 1, inherit.aes = FALSE)
  }
  
  # --- Overlay Observed Data (if provided) ---
  if (!is.null(dataset)) {
    observed_data <- dataset |>
      dplyr::rename(
        t = dataset |> get_timeindays_var(), 
        res = dataset |> serocalculator::get_values_var()
      ) |>
      dplyr::select(all_of(c("id", 
                             "t",
                             "res",
                             "antigen_iso"))) |>
      dplyr::mutate(id = as.factor(.data$id)) |>
      dplyr::filter(.data$id %in% .env$ids,
                    .data$antigen_iso %in% .env$antigen_iso)
    
    p <- p +
      ggplot2::geom_point(data = observed_data,
                          ggplot2::aes(x = .data$t, 
                                       y = .data$res, 
                                       group = .data$id, 
                                       color = "observed"),
                          size = 2, show.legend = TRUE) +
      ggplot2::geom_line(data = observed_data,
                         ggplot2::aes(x = .data$t, 
                                      y = .data$res, 
                                      group = .data$id, 
                                      color = "observed"),
                         linewidth = 1, show.legend = TRUE)
  }
  
  # --- Construct Unified Legend ---
  color_vals <- c("median" = "red")
  color_labels <- c("median" = legend_median)
  fill_vals <- c("ci" = "red")
  fill_labels <- c("ci" = "95% credible interval")
  
  if (show_all_curves) {
    color_vals["samples"] <- "gray"
    color_labels["samples"] <- "Posterior samples"
  }
  
  if (!is.null(dataset)) {
    color_vals["observed"] <- "blue"
    color_labels["observed"] <- legend_obs
  }
  
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
  
  # --- Optionally facet by ID ---
  if (facet_by_id) {
    if (is.null(ncol)) {
      n_ids <- length(unique(param_medians_wide$id))
      ncol <- if (n_ids == 1) {
        1
      } else if (n_ids > 1 && n_ids <= 4) {
        2
      } else {
        NULL
      }
    }
    p <- p + ggplot2::facet_wrap(~ id, ncol = ncol)
  }
  
  # --- Optionally add log10 scales for y and/or x ---
  if (log_y) {
    p <- p + ggplot2::scale_y_log10()
  }
  if (log_x) {
    p <- p +
      ggplot2::scale_x_continuous(
        trans = scales::pseudo_log_trans(sigma = 1, base = 10)
      )
  }
  
  # --- Set custom x-axis limits if provided ---
  if (!is.null(xlim)) {
    p <- p + ggplot2::coord_cartesian(xlim = xlim)
  }
  
  return(p)
}
