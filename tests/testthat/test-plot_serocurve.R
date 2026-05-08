test_that(
  desc = "plot_serocurve() works with population param_source (default)",
  code = {
    skip_if(getRversion() < "4.4.1")

    sr_model <- serodynamics::nepal_sees_jags_output

    # Single antigen-iso, single stratum
    p1 <- plot_serocurve(
      model       = sr_model,
      antigen_iso = "HlyE_IgA",
      strat       = "typhi"
    )
    vdiffr::expect_doppelganger("serocurve-population-single-strat", p1)

    # Multiple strata coloured (default)
    p2 <- plot_serocurve(
      model       = sr_model,
      antigen_iso = "HlyE_IgA"
    )
    vdiffr::expect_doppelganger("serocurve-population-multi-strat", p2)

    # Faceted by stratification
    p3 <- plot_serocurve(
      model          = sr_model,
      antigen_iso    = "HlyE_IgA",
      facet_by_strat = TRUE
    )
    vdiffr::expect_doppelganger("serocurve-population-facet-strat", p3)

    # Multiple antigen-isotypes, faceted
    p4 <- plot_serocurve(
      model                = sr_model,
      antigen_iso          = c("HlyE_IgA", "HlyE_IgG"),
      facet_by_antigen_iso = TRUE
    )
    vdiffr::expect_doppelganger("serocurve-population-facet-antigen-iso", p4)

    # Without CI
    p5 <- plot_serocurve(
      model       = sr_model,
      antigen_iso = "HlyE_IgA",
      strat       = "typhi",
      show_ci     = FALSE
    )
    vdiffr::expect_doppelganger("serocurve-population-no-ci", p5)
  }
)

test_that(
  desc = "plot_serocurve() works with newperson param_source",
  code = {
    skip_if(getRversion() < "4.4.1")

    sr_model <- serodynamics::nepal_sees_jags_output

    p6 <- plot_serocurve(
      model        = sr_model,
      antigen_iso  = "HlyE_IgA",
      strat        = "typhi",
      param_source = "newperson"
    )
    vdiffr::expect_doppelganger("serocurve-newperson-single-strat", p6)
  }
)

test_that(
  desc = "plot_serocurve() errors when population_params attribute is missing",
  code = {
    # Strip the population_params attribute to simulate an old sr_model object
    sr_model_old <- serodynamics::nepal_sees_jags_output
    attr(sr_model_old, "population_params") <- NULL

    expect_error(
      plot_serocurve(sr_model_old, antigen_iso = "HlyE_IgA",
                     param_source = "population"),
      regexp = "population_params"
    )
  }
)
