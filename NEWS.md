# serodynamics (development version)

* Added `plot_serocurve()` for graphical visualization of population-level
  serodynamic curves using posterior samples of the `mu.par` hyperparameter
  (or optionally the "newperson" subject).  Supports 95% credible interval
  ribbons, stratified curves with colour or faceting, and multiple
  antigen-isotypes (#74).
* `run_mod()` now monitors the `mu.par` hyperparameter and stores its
  posterior samples on the latent parameter scale in a
  `population_params` attribute of the returned `sr_model` object; functions
  such as `plot_serocurve()` apply transformations to the original parameter
  scale when needed (#74).
* Expanded `.github/copilot-instructions.md` with additional guidance on evidence-based claims, Quarto markdown/cross-reference conventions, R style practices, and phrase-level line-break formatting for source text.
* Fixed `dplyr::as_tibble()` references to `tibble::as_tibble()` in `post_summ()` and `run_mod()`, since `as_tibble()` is exported from the `tibble` package, not `dplyr`.
* Added R 4.5+ snapshot variants to handle the changed attribute ordering in
  `as_case_data()`, ensuring test suite compatibility with R 4.5 and later (#109).
* Added dev container configuration for persistent, cached development environment
  that includes R, JAGS, and all dependencies preinstalled, making Copilot
  Workspace sessions much faster.
* Reorganized pkgdown documentation with new "Getting Started" guide demonstrating main API workflow, organized articles into "Get started" and "Developer Notes" sections (#73).
* Added `.github/workflows/copilot-setup-steps.yml` GitHub Actions workflow to automate environment setup for GitHub Copilot coding agent, preinstalling R, JAGS, and all dependencies.

* Consolidated OS-specific snapshot variants: removed redundant Linux and Windows
  snapshot directories (which were identical), keeping only base snapshots and 
  darwin-specific variants for macOS platform differences (#73).

* Initial CRAN submission.
* Updated Copilot instructions to encourage code decomposition and avoid copy-pasting substantial code chunks.

## New features

* Made "newperson" optional in `prep_data()` (#73)
* Including fitted and residual values as data frame in run_mod output. (#101)
* Added  `plot_predicted_curve()` with support for faceting by multiple IDs (#68)
* Replacing old data object with new run_mod output (#102)
* Adding class assignment to run_mod output (#76)
* Making prep_priors modifiable (#78)
* Changes to `run_mod()` output:
  - Taking out `include_subs` as an input option, default will include all
  individuals
  - Making a single tbl as output
  - All other pieces will be attributes.
* Changes to `run_mod()` (#79):
   - `jags.post` now optionally included in output, as specified by argument
   `with_post`
   - all subjects now optionally included in `curve_params` output component, 
   as specified by argument `include_subs`
* Diagnostic function to produce R-hat dotplots with stratification (#67)
* Added function for summarizing estimates in a table (#74)
* Diagnostic trace plot function with strat (#64)
* Diagnostic function to produce effective sample size plots with
stratification (#66)
* Diagnostic function to produce density plots with stratification (#27)
* Added SEES data set data folder and documentation (#41)
* Fixing SEES data and added jags_post for SEES (#63)
* `as_case_data()` now creates column `visit_num` (#47, #50)
* Added `postprocess_jags_output()` to API (#33)
* Added `initsfunction()` to API (#37)
* Added participant IDs as names to `nsmpl` element of `prep_data()` output (#34)
* Added `initsfunction()` to API (#37)
* Added `as_case_data()` to API (#31)
* Added `prep_priors()` to API (#30)
* Added `autoplot()` method for `case_data` objects (#28)
* Added examples for `sim_pop_data()`, `autoplot.case_data()` (#18)
* Added attributes as a return to the run_mod function (#24)
* exported `run_mod()` function (#22)
* Function that runs jags with option of stratification included. (#14)
* Changed package name to serodynamics. (#19, #20)

## Bug fixes

None yet

## Developer-facing changes

* Switched ggmcmc dependency from GitHub dev version to CRAN v1.5.1.2 (#135)
* vectorized `ab()` function (#116)
* Added `lintr::undesirable_function_linter()` to `.lintr.R` (#81)
* Reformatted `.lintr` as R file (following 
https://github.com/r-lib/lintr/issues/2844#issuecomment-2776725389) (#81)
* Set shortcut pipe to be base pipe (#80)
* Added snapshot test for `run_mod()`
* Clarified `prep_data()` internals using `{dplyr}` (#34)
* Removed ".R" suffix from jags model files 
to prevent them from getting linted as R files (#34)
* Added `dobson.Rmd` minimal vignette (#36)
* Overall cleaning to get checks working (#28)
* Added units tests for `prep_data()`, `sim_case_data()` (#18)
* Added various GitHub Actions (#10, #15, #18)

# serodynamics 0.0.0

Started development.
