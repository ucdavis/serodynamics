test_that(
  desc = "results are consistent with simulated data",
  code = {
    testthat::announce_snapshot_file("sim-strat-curve-params.csv")
    testthat::announce_snapshot_file("sim-strat-fitted_residuals.csv")
    testthat::announce_snapshot_file("popparam-summary-stats.csv")
    withr::local_seed(1)
    strat1 <- serocalculator::typhoid_curves_nostrat_100 |>
      sim_case_data(n = 100,
                    antigen_isos = "HlyE_IgA") |>
      mutate(strat = "stratum 2")
    withr::local_seed(2)
    strat2 <- serocalculator::typhoid_curves_nostrat_100 |>
      sim_case_data(n = 100, antigen_isos = "HlyE_IgA") |>
      mutate(strat = "stratum 1")
    dataset <- dplyr::bind_rows(strat1, strat2)
    results <- run_mod(
      data = dataset, # The data set input
      file_mod = serodynamics_example("model.jags"),
      nchain = 2, # Number of mcmc chains to run
      nadapt = 100, # Number of adaptations to run
      nburn = 100, # Number of unrecorded samples before sampling begins
      nmc = 10,
      niter = 10, # Number of iterations
      strat = "strat", # Variable to be stratified
      with_pop_params = TRUE
    ) |>
      suppressWarnings()
    
    results |>
      expect_snapshot_data(
        "sim-strat-curve-params",
        variant = darwin_variant()
      )
    
    # Testing attributes
    results |>
      attributes() |>
      names() |>
      expect_setequal(c("names", "row.names", "class", "nChains", 
                        "nParameters", "nIterations", "nBurnin", "nThin",
                        "population_params", "priors", 
                        "fitted_residuals"))
    
    # Verify class appears immediately after names and row.names
    expect_equal(
      names(attributes(results))[1:3],
      c("names", "row.names", "class")
    )
    
    attributes(results)$fitted_residuals |>
      expect_snapshot_data(
        "sim-strat-fitted_residuals",
        variant = darwin_variant()
      )

    # Testing for population parameters
    attributes(results)$population_params |>
      dplyr::group_by(Parameter) |>
      dplyr::summarise(
        mean = mean(value),
        sd = sd(value),
        .groups = "drop"
      ) |>
      dplyr::arrange(Parameter) |>
      expect_snapshot_data("popparam-summary-stats", 
        variant = darwin_variant()    
      )
    
    pop_params <- attributes(results)$population_params
    expect_s3_class(pop_params, "data.frame")
    expect_true(all(c("Population_Parameter", "value") %in% names(pop_params)))
    
    expect_setequal(
      unique(pop_params$Population_Parameter),
      c("mu.par", "prec.par", "prec.logy")
    )
    expect_true(all(is.finite(pop_params$value)))
    
  }
)

test_that(
  desc = "results are consistent with SEES data",
  code = {
    testthat::announce_snapshot_file("strat-curve-params.csv")
    testthat::announce_snapshot_file("strat-fitted_residuals.csv")
    withr::local_seed(1)
    dataset <- serodynamics::nepal_sees 
    
    results <- run_mod(
      data = dataset, # The data set input
      file_mod = serodynamics_example("model.jags"),
      nchain = 2, # Number of mcmc chains to run
      nadapt = 10, # Number of adaptations to run
      nburn = 10, # Number of unrecorded samples before sampling begins
      nmc = 100,
      niter = 100, # Number of iterations
      strat = "bldculres" # Variable to be stratified
    ) |>
      suppressWarnings()
    
    results |>
      attributes() |>
      rlist::list.remove(c("row.names", "fitted_residuals")) |>
      expect_snapshot_value(style = "deparse", variant = r46_variant())
    
    results |>
      expect_snapshot_data(
        "strat-curve-params",
        variant = darwin_variant()
      )
    
    attributes(results)$fitted_residuals |>
      expect_snapshot_data(
        "strat-fitted_residuals",
        variant = darwin_variant()
      )
    
    expect_null(attr(results, "population_params"))
    
  }
)

test_that(
  desc = "results are consistent with unstratified SEES data with population
  parameters",
  code = {
    announce_snapshot_file("nostrat-curve-params.csv")
    announce_snapshot_file("nostrat-fitted_residuals.csv")
    announce_snapshot_file("popparam-nostrat-summary-stats.csv")
    
    withr::local_seed(1)
    dataset <- serodynamics::nepal_sees 
    
    results <- run_mod(
      data = dataset, # The data set input
      file_mod = serodynamics_example("model.jags"),
      nchain = 2, # Number of mcmc chains to run
      nadapt = 10, # Number of adaptations to run
      nburn = 10, # Number of unrecorded samples before sampling begins
      nmc = 100,
      niter = 100, # Number of iterations
      strat = NA, # Variable to be stratified
      with_pop_params = TRUE
    ) |>
      suppressWarnings()
    
    results |>
      attributes() |>
      rlist::list.remove(c("row.names", "fitted_residuals",
                           "population_params")) |>
      expect_snapshot_value(style = "deparse", variant = r46_variant())
    
    results |>
      expect_snapshot_data(
        "nostrat-curve-params",
        variant = darwin_variant()
      )
    
    attributes(results)$fitted_residuals |>
      expect_snapshot_data(
        "nostrat-fitted_residuals",
        variant = darwin_variant()
      )
    
    # Testing for population parameters
    attributes(results)$population_params |>
      dplyr::group_by(Parameter) |>
      dplyr::summarise(
        mean = mean(value),
        sd = sd(value),
        .groups = "drop"
      ) |>
      dplyr::arrange(Parameter) |>
      expect_snapshot_data(
        "popparam-nostrat-summary-stats",
        variant = darwin_variant()
      )
  }
)

test_that(
  desc = "preclogy_per_iso relabels prec.logy Parameter by isotype in run_mod",
  code = {
    withr::local_seed(1)
    dataset <- serodynamics::nepal_sees

    results <- suppressWarnings(
      run_mod(
        data = dataset,
        file_mod = serodynamics_example("model.jags"),
        nchain = 2,
        nadapt = 10,
        nburn = 10,
        nmc = 100,
        niter = 100,
        strat = NA,
        with_pop_params = TRUE,
        preclogy_per_iso = TRUE
      )
    )

    pop_params <- attr(results, "population_params")
    expect_s3_class(pop_params, "data.frame")

    preclogy_rows <- pop_params[pop_params$Population_Parameter == "prec.logy", ]
    expect_gt(nrow(preclogy_rows), 0)

    # With preclogy_per_iso = TRUE, Parameter should be the isotype label,
    # not the constant "prec.logy"
    expect_false(all(preclogy_rows$Parameter == "prec.logy"))
    expect_true(all(preclogy_rows$Parameter %in% unique(pop_params$Iso_type)))
  }
)

test_that(
  desc = "results are consistent with unstratified SEES data with modified
  priors and post",
  code = {
    announce_snapshot_file("nostrat-curve-params-specpriors.csv")
    withr::local_seed(1)
    dataset <- serodynamics::nepal_sees 
    
    results <- run_mod(
      data = dataset, # The data set input
      file_mod = serodynamics_example("model.jags"),
      nchain = 2, # Number of mcmc chains to run
      nadapt = 10, # Number of adaptations to run
      nburn = 10, # Number of unrecorded samples before sampling begins
      nmc = 100,
      niter = 100, # Number of iterations
      strat = NA, # Variable to be stratified
      with_post = TRUE,
      mu_hyp_param = c(1, 4, 1, -3, -1),
      prec_hyp_param = c(0.01, 0.0001, 0.01, 0.001, 0.01),
      omega_param = c(1, 20, 1, 10, 1),
      wishdf_param = 10,
      prec_logy_hyp_param = c(3, 1)
    ) |>
      suppressWarnings()
    
    results |>
      expect_snapshot_data(
        "nostrat-curve-params-specpriors",
        variant = darwin_variant()
      )
    
    jags_post <- attributes(results)$jags.post
    expect_false(is.null(jags_post))
    expect_type(jags_post, "list")
    expect_true("None" %in% names(jags_post))
    expect_s3_class(jags_post$None$mcmc, "mcmc.list")
    
  }
)
