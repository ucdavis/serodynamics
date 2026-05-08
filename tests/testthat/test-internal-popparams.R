test_that("param_recode correctly recodes parameter indices", {
  # Test valid parameter indices
  expect_equal(serodynamics:::param_recode("1"), "y0")
  expect_equal(serodynamics:::param_recode("2"), "y1")
  expect_equal(serodynamics:::param_recode("3"), "t1")
  expect_equal(serodynamics:::param_recode("4"), "alpha")
  expect_equal(serodynamics:::param_recode("5"), "shape")
  
  # Test vector of valid indices
  expect_equal(
    serodynamics:::param_recode(c("1", "2", "3", "4", "5")),
    c("y0", "y1", "t1", "alpha", "shape")
  )
})

test_that("unpack_jags handles factor Parameter column", {
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
  expect_true(all(mu_rows$Param %in% c("y0", "y1", "t1", "alpha", "shape")))
})

test_that("unpack_jags correctly unpacks prec.par parameters", {
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

test_that("unpack_jags correctly unpacks individual-level parameters", {
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
  test_data <- tibble::tibble(
    Iteration = 1:10,
    Chain = rep(1, 10),
    Parameter = rep(c("y0", "mu.par"), each = 5),
    Subject = rep(c("1", "mu.par"), each = 5),
    value = rnorm(10)
  )
  
  result <- serodynamics:::prep_popparams(test_data)
  
  # Should only have population parameters
  expect_true(all(result$Population_Parameter %in% 
                    c("mu.par", "prec.par", "prec.logy")))
  
  # Should rename Subject to Population_Parameter
  expect_true("Population_Parameter" %in% names(result))
  expect_false("Subject" %in% names(result))
  
  # Should have 5 rows (only mu.par rows)
  expect_equal(nrow(result), 5)
})

test_that("ex_popparams excludes population parameters", {
  test_data <- tibble::tibble(
    Iteration = 1:10,
    Chain = rep(1, 10),
    Parameter = rep(c("y0", "mu.par"), each = 5),
    Subject = rep(c("1", "mu.par"), each = 5),
    value = rnorm(10)
  )
  
  result <- serodynamics:::ex_popparams(test_data)
  
  # Should not have any population parameters
  expect_false(any(result$Subject %in% c("mu.par", "prec.par", "prec.logy")))
  
  # Should have 5 rows (only y0 rows)
  expect_equal(nrow(result), 5)
  
  # Should keep original structure
  expect_equal(names(result), names(test_data))
})

test_that("prep_popparams and ex_popparams are complementary", {
  test_data <- tibble::tibble(
    Iteration = rep(1:5, 4),
    Chain = rep(1, 20),
    Parameter = rep(c("y0", "mu.par", "prec.par", "prec.logy"), each = 5),
    Subject = rep(c("1", "mu.par", "prec.par", "prec.logy"), each = 5),
    value = rnorm(20)
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
