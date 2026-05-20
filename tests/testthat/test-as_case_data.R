test_that(
  desc = "results are consistent with simulated data",
  code = {
    withr::with_seed(
      1,
      code = {
        test_obj <-
          serocalculator::typhoid_curves_nostrat_100 |>
          sim_case_data(n = 5)
      }
    )
    
    test_obj <- test_obj |>
      as_case_data(
        id_var = "id",
        biomarker_var = "antigen_iso",
        time_in_days = "timeindays",
        value_var = "value"
      )
    
    test_obj |>
      attributes() |>
      rlist::list.remove("row.names") |>
      expect_snapshot_value(style = "deparse", variant = r45_variant())
    
    test_obj |> expect_snapshot_data(name = "sim-data")
  }
)

test_that(
  desc = "results are consistent with SEES data",
  code = {
    
    
    dataset <- serodynamics_example(
      "SEES_Case_Nepal_ForSeroKinetics_02-13-2025.csv"
    ) |>
      readr::read_csv() |>
      as_case_data(
        id_var = "person_id",
        biomarker_var = "antigen_iso",
        value_var = "result",
        time_in_days = "dayssincefeveronset"
      )
    
    dataset |>
      attributes() |>
      rlist::list.remove("row.names") |>
      expect_snapshot_value(style = "deparse", variant = r45_variant())
    
    dataset |> expect_snapshot_data(name = "sees-data")
  }
)

test_that(
  desc = "validates required columns exist",
  code = {
    # Create test data missing required column
    test_data <- data.frame(
      id = 1:3,
      value = c(100, 200, 300)
      # Missing: antigen_iso and timeindays columns
    )
    
    # Should error with clear message about missing columns
    expect_error(
      as_case_data(
        test_data,
        id_var = "id",
        biomarker_var = "antigen_iso",
        value_var = "value",
        time_in_days = "timeindays"
      ),
      "Required column.*missing"
    )
  }
)
