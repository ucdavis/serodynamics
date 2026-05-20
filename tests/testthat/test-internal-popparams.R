test_that("param_recode correctly recodes parameter indices", {
  # Test valid parameter indices
  expect_equal(serodynamics:::param_recode("1"), "log(y0)")
  expect_equal(serodynamics:::param_recode("2"), "log(y1 - y0)")
  expect_equal(serodynamics:::param_recode("3"), "log(t1)")
  expect_equal(serodynamics:::param_recode("4"), "log(alpha)")
  expect_equal(serodynamics:::param_recode("5"), "log(shape - 1)")
  
  # Test vector of valid indices
  expect_equal(
    serodynamics:::param_recode(c("1", "2", "3", "4", "5")),
    c("log(y0)", "log(y1 - y0)", "log(t1)", 
      "log(alpha)", "log(shape - 1)")
  )
})

test_that("unpack_jags handles factor Parameter column", {
  withr::local_seed(42)
  # Create a simple ggs-like object with factor Parameter column
  test_data <- tibble::tibble(
    Iteration = rep(1:5, 3),
    Chain = rep(1, 15),
    Parameter = factor(
      rep(c("mu.par[1,1]", "prec.par[1,1,2]", "y0[1,1]"), each = 5)
    ),
    value = rnorm(15)
  )
  
  # Should not error with factor column
  result <- serodynamics:::unpack_jags(test_data)
  
  expect_true(is.data.frame(result))
  expect_true("Subject" %in% names(result))
  expect_true("Param" %in% names(result))
})

test_that("unpack_jags correctly unpacks mu.par parameters", {
  withr::local_seed(42)
  test_data <- tibble::tibble(
    Iteration = rep(1:3, 2),
    Chain = rep(1, 6),
    Parameter = rep(c("mu.par[1,1]", "mu.par[1,2]"), each = 3),
    value = rnorm(6)
  )
  
  result <- serodynamics:::unpack_jags(test_data)
  
  # Check that mu.par rows are present
  mu_rows <- result[result$Subject == "mu.par", ]
  expect_gt(nrow(mu_rows), 0)
  
  # Check Subject is correctly set
  expect_true("mu.par" %in% result$Subject)
  
  # Check Param is correctly decoded
  expect_true(all(mu_rows$Param %in% c("log(y0)", "log(y1 - y0)", "log(t1)", 
                                       "log(alpha)", "log(shape - 1)")))
})

test_that("unpack_jags correctly unpacks prec.par parameters", {
  withr::local_seed(42)
  test_data <- tibble::tibble(
    Iteration = rep(1:3, 2),
    Chain = rep(1, 6),
    Parameter = rep(c("prec.par[1,1,2]", "prec.par[1,2,3]"), each = 3),
    value = rnorm(6)
  )
  
  result <- serodynamics:::unpack_jags(test_data)
  
  # Check that prec.par rows are present
  prec_rows <- result[result$Subject == "prec.par", ]
  expect_gt(nrow(prec_rows), 0)
  
  # Check Subject is correctly set
  expect_true("prec.par" %in% result$Subject)
  
  # Check Param contains pairs (e.g., "y0, y1")
  expect_true(any(grepl(",", prec_rows$Param)))
})

test_that("unpack_jags correctly unpacks prec.logy parameters", {
  withr::local_seed(42)
  test_data <- tibble::tibble(
    Iteration = rep(1:3, 2),
    Chain = rep(1, 6),
    Parameter = rep(c("prec.logy[1]", "prec.logy[2]"), each = 3),
    value = rnorm(6)
  )
  
  result <- serodynamics:::unpack_jags(test_data)
  
  # Check that prec.logy rows are present
  logy_rows <- result[result$Subject == "prec.logy", ]
  expect_gt(nrow(logy_rows), 0)
  
  # Check Subject is correctly set
  expect_true("prec.logy" %in% result$Subject)
})

test_that("unpack_jags correctly unpacks scalar prec.logy parameters", {
  withr::local_seed(42)
  test_data <- tibble::tibble(
    Iteration = 1:3,
    Chain = rep(1, 3),
    Parameter = rep("prec.logy", 3),
    value = rnorm(3)
  )
  
  result <- serodynamics:::unpack_jags(test_data)
  
  expect_true(all(result$Subject == "prec.logy"))
  expect_true(all(result$Subnum == "1"))
  expect_true(all(result$Param == "prec.logy"))
})

test_that("unpack_jags correctly unpacks individual-level parameters", {
  withr::local_seed(42)
  test_data <- tibble::tibble(
    Iteration = rep(1:3, 2),
    Chain = rep(1, 6),
    Parameter = rep(c("y0[1,1]", "alpha[2,1]"), each = 3),
    value = rnorm(6)
  )
  
  result <- serodynamics:::unpack_jags(test_data)
  
  # Check individual-level parameters are unpacked
  expect_true(all(c("1", "2") %in% result$Subject))
  expect_true(all(c("y0", "alpha") %in% result$Param))
})

test_that("prep_popparams filters to population parameters only", {
  withr::local_seed(42)
  test_data <- tibble::tibble(
    Iteration = 1:10,
    Chain = rep(1, 10),
    Parameter = rep(c("y0", "mu.par"), each = 5),
    Subject = rep(c("1", "mu.par"), each = 5),
    value = rnorm(10),
    .is_population_parameter = rep(c(FALSE, TRUE), each = 5)
  )
  
  result <- serodynamics:::prep_popparams(test_data)
  
  # Should only have population parameters
  expect_true(all(result$Population_Parameter %in% 
                    c("mu.par", "prec.par", "prec.logy")))
  
  # Should rename Subject to Population_Parameter
  expect_true("Population_Parameter" %in% names(result))
  expect_false("Subject" %in% names(result))
  
  # .is_population_parameter column should be removed
  expect_false(".is_population_parameter" %in% names(result))
  
  # Should have 5 rows (only mu.par rows)
  expect_equal(nrow(result), 5)
})

test_that("ex_popparams excludes population parameters", {
  withr::local_seed(42)
  test_data <- tibble::tibble(
    Iteration = 1:10,
    Chain = rep(1, 10),
    Parameter = rep(c("y0", "mu.par"), each = 5),
    Subject = rep(c("1", "mu.par"), each = 5),
    value = rnorm(10),
    .is_population_parameter = rep(c(FALSE, TRUE), each = 5)
  )
  
  result <- serodynamics:::ex_popparams(test_data)
  
  # Should not have any population parameters
  expect_false(any(result$Subject %in% c("mu.par", "prec.par", "prec.logy")))
  
  # Should have 5 rows (only y0 rows)
  expect_equal(nrow(result), 5)
  
  # .is_population_parameter column should be removed
  expect_false(".is_population_parameter" %in% names(result))
})

test_that("preclogy_per_iso relabels prec.logy Parameter by Iso_type", {
  withr::local_seed(42)
  # Simulate the data shape that exists in Run_Mod.R after the iso_dat join
  # but before the rename of Param → Parameter.
  mock_unpacked <- tibble::tibble(
    Iteration = rep(1:3, 4),
    Chain = 1L,
    Param = c(
      rep("prec.logy", 3), rep("prec.logy", 3),
      rep("y0", 3),        rep("y0", 3)
    ),
    Subject = c(
      rep("prec.logy", 3), rep("prec.logy", 3),
      rep("1", 3),         rep("2", 3)
    ),
    Iso_type = c(
      rep("HlyE_IgA", 3), rep("HlyE_IgG", 3),
      rep("HlyE_IgA", 3), rep("HlyE_IgA", 3)
    ),
    value = rnorm(12),
    .is_population_parameter = c(rep(TRUE, 6), rep(FALSE, 6))
  )

  # Apply the preclogy_per_iso transformation (mirrors Run_Mod.R logic)
  result <- mock_unpacked |>
    dplyr::mutate(
      Param = dplyr::if_else(
        .data$.is_population_parameter &
          .data$Subject == "prec.logy" &
          !is.na(.data$Iso_type),
        .data$Iso_type,
        .data$Param
      )
    )

  preclogy_rows <- result[result$.is_population_parameter, ]
  # Each prec.logy row should now carry its isotype as the Param label
  expect_setequal(unique(preclogy_rows$Param), c("HlyE_IgA", "HlyE_IgG"))

  # Individual-level rows are unchanged
  ind_rows <- result[!result$.is_population_parameter, ]
  expect_true(all(ind_rows$Param == "y0"))
})

test_that("prep_popparams and ex_popparams are complementary", {
  withr::local_seed(42)
  test_data <- tibble::tibble(
    Iteration = rep(1:5, 4),
    Chain = rep(1, 20),
    Parameter = rep(c("y0", "mu.par", "prec.par", "prec.logy"), each = 5),
    Subject = rep(c("1", "mu.par", "prec.par", "prec.logy"), each = 5),
    value = rnorm(20),
    .is_population_parameter = rep(c(FALSE, TRUE, TRUE, TRUE), each = 5)
  )
  
  pop_params <- serodynamics:::prep_popparams(test_data)
  individual_params <- serodynamics:::ex_popparams(test_data)
  
  # Together they should account for all rows
  expect_equal(nrow(pop_params) + nrow(individual_params), nrow(test_data))
  
  # No overlap in subjects
  # Note: pop_params has Population_Parameter column, not Subject
  expect_false(any(individual_params$Subject %in% 
                     c("mu.par", "prec.par", "prec.logy")))
})
