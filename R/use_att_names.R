#' @title Assigns column names to conform with [calc_fit_mod()] using attributes
#' @description
#'  `use_att_names` takes prepared longitudinal data for antibody kinetic
#'  modeling and names columns using attribute values to allow merging
#'  with a modeled [run_mod] output [tibble::tbl_df]. The column names include
#'  `Subject`, `Iso_type`, `t`, and `result`. 
#' @param data A [data.frame] raw longitudinal data that has been
#' prepared for antibody kinetic modeling using [as_case_data()].
#' @returns The input [data.frame] with columns named after attributes.
#' @keywords internal
use_att_names <- function(data) {
  data <- data |> 
    dplyr::rename(
      Subject = data |> serocalculator::ids_varname(),
      Iso_type = data |> serocalculator::get_biomarker_names_var(),
      t = data |> get_timeindays_var(),
      result = data |> serocalculator::get_values_var()
    ) 
  return(data)
}
