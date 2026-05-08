#' @title Run Jags Model
#' @author Sam Schildhauer
#' @description
#'  `run_mod()` takes a data frame and adjustable MCMC inputs to
#'  [runjags::run.jags()] as an MCMC
#'  Bayesian model to estimate antibody dynamic curve parameters.
#'  The [rjags::jags.model()] models seroresponse dynamics to an
#'  infection. The antibody dynamic curve includes the following parameters:
#'  - y0 = baseline antibody concentration
#'  - y1 = peak antibody concentration
#'  - t1 = time to peak
#'  - shape = shape parameter
#'  - alpha = decay rate
#' @param data A [base::data.frame()] with the following columns.
#' @param file_mod The name of the file that contains model structure.
#' @param nchain An [integer] between 1 and 4 that specifies
#' the number of MCMC chains to be run per jags model.
#' @param nadapt An [integer] specifying the number of adaptations per chain.
#' @param nburn An [integer] specifying the number of burn ins before sampling.
#' @param nmc An [integer] specifying the number of samples in posterior chains.
#' @param niter An [integer] specifying the number of iterations.
#' @param strat A [character] string specifying the stratification variable,
#' entered in quotes.
#' @param with_post A [logical] value specifying whether a raw `jags.post`
#' component
#' should be included as an element of the [list] object returned by `run_mod()`
#' (see `Value` section below for details).
#' Note: These objects can be large.
#' @param with_pop_params A [logical] value specifying whether population 
#' level parameters should be included as an attribute entitled 
#' `population_params`. Excluded as default.
#' Note: These objects can be large.
#' @returns An `sr_model` class object: a subclass of [tibble::tbl_df] that
#' contains MCMC samples from the joint posterior distribution of the model
#' parameters, conditional on the provided input `data`, 
#' including the following:
#'   - `iteration` = Number of sampling iterations
#'   - `chain` = Number of MCMC chains run; between 1 and 4
#'   - `Parameter` = Parameter being estimated. Includes the following:
#'     - `y0` = Posterior estimate of baseline antibody concentration
#'     - `y1` = Posterior estimate of peak antibody concentration
#'     - `t1` = Posterior estimate of time to peak
#'     - `shape` = Posterior estimate of shape parameter
#'     - `alpha` = Posterior estimate of decay rate
#'   - `Iso_type` = Antibody/antigen type combination being evaluated
#'   - `Stratification` = The variable used to stratify jags model
#'   - `Subject` = ID of subject being evaluated
#'   - `value` = Estimated value of the parameter
#' - The following [attributes] are included in the output:
#'   - `class`: Class of the output object.
#'   - `nChain`: Number of chains run.
#'   - `nParameters`: The amount of parameters estimated in the model.
#'   - `nIterations`: Number of iteration specified.
#'   - `nBurnin`: Number of burn ins.
#'   - `nThin`: Thinning number (niter/nmc).
#'   - `population_params`: Optionally included modeled population parameters
#'   indexed by
#'   `Iteration`,
#'   `Chain`, `Parameter`, `Iso_type`, and `Stratification`. Excluded as
#'   default. Includes the following modeled population parameters:
#'     - `mu.par` = The population means of the host-specific model parameters
#'     on latent transformed scales. For these rows, `Parameter` values refer
#'     to the underlying `par` components used in the model, not necessarily
#'     to the observed-scale curve parameters used elsewhere in the package.
#'     For example, `y1` corresponds to `log(y1 - y0)` and `shape`
#'     corresponds to `log(shape - 1)`.
#'     - `prec.par` = The population precision matrix of the hyperparameters
#'     (with diagonal elements equal to inverse variances).
#'     - `prec.logy` = A vector of population precisions (inverse variances),
#'     one per antigen/isotype combination.
#'   - `priors`: A [list] that summarizes the input priors, including:
#'     - `mu_hyp_param`
#'     - `prec_hyp_param`
#'     - `omega_param`
#'     - `wishdf`
#'     - `prec_logy_hyp_param`
#'   - `fitted_residuals`: A [data.frame] containing fitted and residual values
#'   for all observations.
#'   - An optional `"jags.post"` attribute, included when argument
#'   `with_post` = TRUE.
#' @inheritDotParams prep_priors
#' @export
#' @example inst/examples/run_mod-examples.R
run_mod <- function(data,
                    file_mod = serodynamics_example("model.jags"),
                    nchain = 4,
                    nadapt = 0,
                    nburn = 0,
                    nmc = 100,
                    niter = 100,
                    strat = NA,
                    with_post = FALSE,
                    with_pop_params = FALSE,
                    ...) {
  ## Conditionally creating a stratification list to loop through
  if (is.na(strat)) {
    strat_list <- "None"
  } else {
    strat_list <- unique(data[[strat]])
  }

  ## Creating a shell to output results
  jags_out <- tibble::tibble(
    "Iteration" = integer(),
    "Chain" = integer(),
    "value" = numeric(),
    "Subject" = character(),
    "Parameter" = character(),
    "Iso_type" = character(),
    "Stratification" = character()
  )

  ## Creating output list for jags.post
  jags_post_final <- list()

  # For loop for running stratifications
  for (i in strat_list) {
    # Creating if else statement for running the loop
    if (is.na(strat)) {
      dl_sub <- data
    } else {
      dl_sub <- data |>
        dplyr::filter(.data[[strat]] == i)
    }

    # prepare data for modeline
    longdata <- prep_data(dl_sub)
    priorspec <- prep_priors(max_antigens = longdata$n_antigen_isos,
                             ...)

    # inputs for jags model
    nchains <- nchain # nr of MC chains to run simultaneously
    nadapt <- nadapt # nr of iterations for adaptation
    nburnin <- nburn # nr of iterations to use for burn-in
    nmc <- nmc # nr of samples in posterior chains
    niter <- niter # nr of iterations for posterior sample
    nthin <- round(niter / nmc) # thinning needed to produce nmc from niter

    tomonitor <- c("y0", "y1", "t1", "alpha", "shape")
    # Conditional statement for including population parameters
    if (with_pop_params) {
      tomonitor <- c(tomonitor, "mu.par", "prec.par",
                     "prec.logy")
    }

    jags_post <- runjags::run.jags(
      model = file_mod,
      data = c(longdata, priorspec),
      inits = initsfunction,
      method = "parallel",
      adapt = nadapt,
      burnin = nburnin,
      thin = nthin,
      sample = nmc,
      n.chains = nchains,
      monitor = tomonitor,
      summarise = FALSE
    )
    # Assigning the raw jags output to a list.
    # This object will include a raw output for the jags.post for each
    # stratification and will only be included if specified. 
    jags_post_final[[i]] <- jags_post

    # Unpacking and cleaning MCMC output.
    jags_packed <- ggmcmc::ggs(jags_post[["mcmc"]])

    # Adding attributes
    mod_atts <- attributes(jags_packed)
    # Select necessary attributes by name for robustness across platforms
    mod_atts <- mod_atts[c("nChains", "nParameters", "nIterations",
                           "nBurnin", "nThin", "description")]
    
    # extracting antigen-iso combinations to correctly number
    # them by the order they are estimated by the program.
    iso_dat <- data.frame(attributes(longdata)$antigens)
    iso_dat <- iso_dat |> dplyr::mutate(Subnum = row.names(iso_dat))
    
    # Unpacking the mcmc object
    jags_unpacked <- unpack_jags(jags_packed)
    
    # Merging isodat in to ensure we are classifying antigen_iso. 
    jags_unpacked <- dplyr::left_join(jags_unpacked, iso_dat, 
                                      by = "Subnum")
    
    # Adding in ID name
    ids <- data.frame(attr(longdata, "ids")) |>
      dplyr::mutate(Subject = as.character(dplyr::row_number()))
    jags_final <- dplyr::left_join(jags_unpacked, ids, 
                                   by = "Subject") |>
      dplyr::rename(
        Iso_type = "attributes.longdata..antigens",
        Subject_mcmc = "attr.longdata...ids.."
      ) |>
      # Subject handling:
      # * For individual-level parameters, the left join above finds a row in
      #   attr(longdata, "ids"), so Subject_mcmc contains the subject ID.
      # * For population-level parameters (e.g., mu.par, prec.par, prec.logy),
      #   there is no matching ID, so Subject_mcmc is NA. In that case we
      #   intentionally keep the original Subject value from unpack_jags,
      #   which holds the parameter name and serves as the identifier.
      dplyr::mutate(Subject_mcmc = ifelse(is.na(.data$Subject_mcmc), 
                                          .data$Subject, 
                                          .data$Subject_mcmc)) |>
      # At this point, jags_unpacked contains:
      # * Parameter: original JAGS parameter names (e.g., "y0[1,2]")
      # * Param: cleaned parameter names used elsewhere in the package.
      # We drop the original JAGS-style Parameter column and keep the
      # cleaned names, then rename Param back to Parameter so that all
      # downstream code consistently uses a single "Parameter" column
      # containing cleaned parameter names.
      # Drop the temporary Subject (now only used as a fallback for population
      # parameters) and rename Subject_mcmc back to Subject for downstream use.
      dplyr::select(-dplyr::all_of(c("Subnum", "Subject", "Parameter"))) |>
      dplyr::rename(
        Subject = "Subject_mcmc",
        Parameter = "Param"
      )
    
    # Creating a label for the stratification, if there is one.
    # If not, will add in "None".
    jags_final$Stratification <- i
    # Creating output as a data frame with the
    # jags output results for each stratification rbinded.
    jags_out <- dplyr::bind_rows(jags_out, jags_final)
  }
  
  if (with_pop_params) {
    # Preparing population parameters
    population_params <- prep_popparams(jags_out)
    population_params <- population_params[, c(
      "Iteration", "Chain", "Parameter", "Iso_type",
      "Stratification", "Population_Parameter", "value"
    )]
  
    # Taking out population parameters
    jags_out <- ex_popparams(jags_out)
  }
  
  # Making output a tibble and restructuring.
  jags_out <- jags_out[, c("Iteration", "Chain", "Parameter", "Iso_type",
                           "Stratification", "Subject", "value")]
  current_atts <- attributes(jags_out)
  # Explicitly build the attribute list in the correct order to ensure that
  # `class` appears immediately after `names` and `row.names`.
  # The dplyr operations above can carry ggmcmc attributes (nChains, etc.)
  # from jags_packed into jags_out, placing `class` at the end. We use
  # mod_atts (named selection from jags_packed) as the authoritative source
  # for the ggmcmc-style metadata attributes.
  new_atts <- list(
    names = current_atts$names,
    row.names = current_atts$row.names,
    class = union("sr_model", current_atts$class),
    nChains = mod_atts$nChains,
    nParameters = mod_atts$nParameters,
    nIterations = mod_atts$nIterations,
    nBurnin = mod_atts$nBurnin,
    nThin = mod_atts$nThin,
    description = mod_atts$description
  )
  attributes(jags_out) <- new_atts
  
  # Adding population parameters optionally and priors in as attributes
  if (with_pop_params) {
    jags_out <- jags_out |>
      structure(population_params = population_params)
  }
  jags_out <- jags_out |>
    structure(priors = attributes(priorspec)$used_priors)
  
  # Calculating fitted and residuals
  # Renaming columns using attributes from as_case_data
  fit_res <- calc_fit_mod(modeled_dat = jags_out,
                          original_data = dl_sub)
  jags_out <- jags_out |>
    structure(fitted_residuals = fit_res)

  # Conditionally adding jags.post
  if (with_post) {
    jags_out <- jags_out |>
      structure(jags.post = jags_post_final)
  }
  jags_out
}
