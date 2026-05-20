#'
#'
#' SEES Typhoid run_mod jags output
#'
#' A [serodynamics::run_mod()] output 
#' using the [nepal_sees] example data set as input
#' and stratifying by column `"bldculres"`, 
#' which is the diagnosis type (typhoid or
#' paratyphoid). Keeping only IDs `"newperson"`, `"sees_npl_1"`, `"sees_npl_2"`.
#'
#' @format An S3 object of class `sr_model`: A [tibble::tbl_df] that contains 
#'   the
#'   posterior predictive distribution of the person-specific parameters for a
#'   "new person" with no observed data (`Subject = "newperson"`) and posterior
#'   distributions of the person-specific parameters for two arbitrarily-chosen
#'   subjects (`"sees_npl_1"` and `"sees_npl_2"`).
#'   Contains 40,000 `rows`, 7 `columns`, and model `attributes`.
#' \describe{
#'  \item{Iteration}{Number of sampling iterations: 500 iterations}
#'  \item{Chain}{Number of MCMC chains run: 2 chains run}
#'  \item{Parameter}{Parameter being estimated}
#'  \item{Iso_type}{Antibody/antigen type combination being evaluated:
#'  `HlyE_IgA` and `HlyE_IgG`}
#'  \item{Stratification}{The variable used to stratify jags model: `typhi` and
#'  `paratyphi`}
#'  \item{Subject}{ID of subject being evaluated: `newperson`, `sees_npl_1`, 
#'  `sees_npl_2`}
#'  \item{value}{Estimated value of the parameter}
#'  \item{attributes}{A [list] of `attributes` that summarize the jags inputs, 
#'  priors, and optional jags_post mcmc object}
#' }
#' @source reference study: <https://doi.org/10.1016/S2666-5247(22)00114-8>
"nepal_sees_jags_output"
