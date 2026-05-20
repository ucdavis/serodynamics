# Copilot Instructions for serodynamics

## Repository Overview

**serodynamics** is an R package for modeling longitudinal antibody responses to infection. It implements Bayesian MCMC methods using JAGS (Just Another Gibbs Sampler) to estimate antibody dynamic curve parameters including baseline concentration, peak concentration, time to peak, shape parameter, and decay rate.

- **Type**: R package (statistical modeling)
- **Size**: ~121MB, ~209 files, ~76 R source files, ~1,664 lines of R code
- **Language**: R (>= 4.1.0)
- **Key Dependencies**: runjags, rjags, JAGS 4.3.1, serocalculator, ggmcmc, dplyr, ggplot2
- **Lifecycle**: Experimental (under active development)

## Lab-Wide Guidance

**Follow the guidance in the [UCD-SeRG Lab Manual](https://ucd-serg.github.io/lab-manual/)**, which provides comprehensive best practices for:
- Culture and conduct
- Communication
- Reproducibility
- Code repositories and version control
- Coding practices and style
- Working with big data
- Quarto and documentation
- GitHub workflows
- Reproducible environments
- Code and data publication
- AI tools usage
- And more

If the web version is inaccessible, refer to the [source files on GitHub](https://github.com/UCD-SERG/lab-manual) for easier reading.

## Critical Setup Requirements

### Copilot Setup Workflow (Automatic Environment Configuration)

The repository includes a **`.github/workflows/copilot-setup-steps.yml`** workflow that automatically configures the GitHub Copilot coding agent's environment with all required dependencies. This workflow runs automatically when Copilot starts working on a task, ensuring a consistent and properly configured development environment.

#### What the Workflow Does

The copilot-setup-steps.yml workflow:

1. **Installs system dependencies**: All required Ubuntu packages for R package development (libcurl, libssl, libxml2, graphics libraries, etc.)
2. **Installs JAGS 4.3.1**: The required Bayesian MCMC system library
3. **Sets up R (>= 4.1.0)**: Installs the R release version that meets the package's minimum requirement
4. **Installs R package dependencies**: All Imports, Suggests, and development dependencies from DESCRIPTION
5. **Verifies installation**: Runs comprehensive checks to ensure JAGS and R are properly configured

#### When It Runs

The workflow runs in the following scenarios:

- **Automatically for Copilot**: When the GitHub Copilot coding agent starts working on a task, it uses this workflow to prepare the environment
- **On workflow changes**: When `.github/workflows/copilot-setup-steps.yml` is modified (via push or pull request)
- **Manual testing**: Can be triggered manually from the repository's "Actions" tab using workflow_dispatch

#### Integration with CI Workflows

The copilot-setup-steps.yml workflow complements but does not replace the CI workflows:

- **Purpose**: Configures the Copilot agent's environment for development work, not for CI testing
- **Scope**: Runs on ubuntu-latest only, while CI workflows test on multiple platforms (Ubuntu, macOS, Windows) and R versions (release, devel, oldrel-1)
- **Alignment**: Uses the same JAGS installation and R setup approach as the R-CMD-check.yaml workflow, ensuring consistency
- **Timeout**: Limited to 55 minutes (Copilot maximum is 59 minutes)

#### Verification Steps

The workflow includes detailed verification logging:

- **JAGS verification**: Checks system JAGS command availability, R interface package versions (rjags, runjags), and runs `runjags::testjags()`
- **R version check**: Ensures R >= 4.1.0 requirement is met
- **Package verification**: Lists key installed packages (devtools, rjags, runjags, rcmdcheck, lintr, spelling, testthat)

#### Customization

If you need to modify the Copilot environment setup:

1. Edit `.github/workflows/copilot-setup-steps.yml`
2. Test changes by pushing to a branch or using workflow_dispatch
3. Ensure the job name remains `copilot-setup-steps` (required by Copilot)
4. Keep timeout under 59 minutes
5. Update this documentation to reflect any significant changes

### Quick Start with Docker (RECOMMENDED)

**The easiest way to get started is to use the provided dev container configuration**, which automatically sets up R, JAGS, and all dependencies in a persistent environment.

**Benefits:**
- **Cached setup**: Container persists between Copilot sessions - no need to reinstall everything
- **Zero manual setup**: Everything is pre-configured and ready to use
- **Consistent environment**: Same R version, JAGS, and system libraries every time

**How to use:**
1. **GitHub Copilot Workspace**: Automatically detects and uses the devcontainer
2. **VS Code**: Install "Dev Containers" extension, then "Reopen in Container"
3. **GitHub Codespaces**: Automatically uses the devcontainer configuration

See `.devcontainer/README.md` for detailed documentation.

### Alternative: Quick Start with Docker

**If you prefer manual Docker setup**, you can use the rocker/verse Docker image which includes R, RStudio, tidyverse, TeX, and many common R packages pre-installed.

To use Docker:

```bash
# Pull the rocker/verse image (includes R >= 4.1.0, tidyverse, devtools, and more)
docker pull rocker/verse:latest

# Run container with repository mounted
docker run -d \
  -v /home/runner/work/serodynamics/serodynamics:/workspace \
  -w /workspace \
  --name serodynamics-dev \
  rocker/verse:latest

# Execute commands in the container
docker exec serodynamics-dev R -e "devtools::install_dev_deps()"
docker exec serodynamics-dev R -e "devtools::check()"

# Or start an interactive R session
docker exec -it serodynamics-dev R

# Clean up when done
docker stop serodynamics-dev
docker rm serodynamics-dev
```

**Note**: You will still need to install JAGS inside the Docker container (see JAGS Installation section below).

### Manual Installation (if not using devcontainer or Docker)

If the devcontainer or Docker is not available or you prefer a native installation, follow the manual installation instructions below.

### R Installation and Development Dependencies (REQUIRED)

**ALWAYS install R and all development dependencies when starting work on a pull request.** This ensures you avoid issues caused by missing dependencies or environment misconfiguration during the development process.

#### Installing R (>= 4.1.0)

The package requires R version 4.1.0 or higher. Install R for your platform:

- **Ubuntu/Linux**: 
  ```bash
  # Add CRAN repository for latest R version
  sudo apt-get update
  sudo apt-get install -y software-properties-common dirmngr
  wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/maruti.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
  sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
  sudo apt-get update
  sudo apt-get install -y r-base r-base-dev
  
  # Verify installation
  R --version
  ```

- **macOS**: 
  ```bash
  # Install using Homebrew (recommended)
  brew install r
  
  # Or download from CRAN: https://cran.r-project.org/bin/macosx/
  # Verify installation
  R --version
  ```

- **Windows**: 
  Download and install from https://cran.r-project.org/bin/windows/base/
  
  Verify installation by opening R console and checking version:
  ```r
  R.version.string
  ```

#### Installing Development Dependencies

After installing R, install all required development dependencies:

```r
# Install devtools (required for package development)
install.packages("devtools", repos = "https://cloud.r-project.org")

# Install all package dependencies (Imports, Suggests, and development needs)
# This reads DESCRIPTION file and installs everything needed
devtools::install_dev_deps(dependencies = TRUE)
```

**Alternative approach** using pak (faster parallel installation):
```r
install.packages("pak", repos = "https://cloud.r-project.org")
pak::local_install_dev_deps(dependencies = TRUE)
```

#### Verify Development Environment

After installation, verify your development environment is properly configured:

```r
# Load devtools
library(devtools)

# Check package dependencies
devtools::dev_sitrep()

# Load the package in development mode
devtools::load_all()

# Run a quick check
devtools::check_man()
```

**Note**: If you encounter issues with dependencies, particularly with system libraries, install the following system dependencies first:

- **Ubuntu/Linux**:
  ```bash
  sudo apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev
  ```

- **macOS**: Most system dependencies are handled by Homebrew, but you may need:
  ```bash
  brew install pkg-config cairo
  ```

- **Windows**: Install Rtools from https://cran.r-project.org/bin/windows/Rtools/ (choose version matching your R version)

### JAGS Installation (REQUIRED)

**ALWAYS install JAGS before attempting to build, test, or run this package.** The package will fail without it.

#### Installing JAGS in Docker (if using rocker/verse)

```bash
# Install JAGS inside the Docker container
docker exec serodynamics-dev apt-get update
docker exec serodynamics-dev apt-get install -y jags

# Install the R interface
docker exec serodynamics-dev R -e 'install.packages("rjags", repos = "https://cloud.r-project.org", type = "source")'

# Verify installation
docker exec serodynamics-dev R -e 'runjags::testjags()'
```

#### Installing JAGS on your local system

- **Ubuntu/Linux**: `sudo apt-get update && sudo apt-get install -y jags`
- **macOS**: Download from https://sourceforge.net/projects/mcmc-jags/files/JAGS/4.x/Mac%20OS%20X/JAGS-4.3.1.pkg
- **Windows**: Download from https://sourceforge.net/project/mcmc-jags/JAGS/4.x/Windows/JAGS-4.3.1.exe

After installing JAGS, install the R interface:
```r
install.packages("rjags", repos = "https://cloud.r-project.org", type = "source")
```

Verify installation with:
```r
library(rjags)
library(runjags)
runjags::findJAGS()
runjags::testjags()
```

## Build and Development Workflow

### Initial Setup

```r
# Install development dependencies
devtools::install_dev_deps()

# Or using the package manager approach
install.packages("devtools")
```

### Documentation Generation

**ALWAYS regenerate documentation after modifying roxygen2 comments in `.R` files.**

```r
# Generate documentation from roxygen2 comments
devtools::document()
# or
roxygen2::roxygenise()
```

Documentation files in `man/` and `NAMESPACE` are auto-generated. Do NOT edit them directly.

### README Updates

README.md is generated from README.Rmd. **ALWAYS edit README.Rmd, never README.md directly.**

To regenerate:
```r
rmarkdown::render("README.Rmd")
```

### Package Checking

Run R CMD check to validate the package:

```r
# Full package check (takes several minutes)
devtools::check()
# or
rcmdcheck::rcmdcheck(error_on = "note")
```

**Note**: This runs multiple validation steps including examples, tests, and documentation checks. Allow 5-10 minutes for completion.

### Testing

```r
# Run all tests
devtools::test()
# or
testthat::test_local(stop_on_warning = TRUE, stop_on_error = TRUE)
```

Tests are located in `tests/testthat/`. The package uses testthat 3.0+ with snapshot testing for MCMC output validation. Some tests are OS-specific and skip on Windows/Linux.

### Linting

The package uses a custom lintr configuration (`.lintr.R`) with strict requirements:

```r
# Lint the entire package
lintr::lint_package()

# Lint specific file
lintr::lint("R/filename.R")
```

**Key linting rules**:
- Use `cli::cli_inform()` instead of `message()`
- Use `cli::cli_warn()` instead of `warning()`
- Use `cli::cli_abort()` instead of `stop()`
- Use `::` instead of `library()` in package code
- Use native pipe `|>` (configured in project.Rproj)
- Follow snake_case with uppercase acronyms allowed (e.g., `prep_IDs` is valid)
- Avoid `undesirable_function_linter` warnings

Exclusions: `data-raw/`, `vignettes/`, `inst/examples/`, and `inst/analyses/` are exempt from some linters.

### Spelling Check

```r
# Check spelling
spelling::spell_check_package()
```

Custom words are in `inst/WORDLIST`.

## Continuous Integration (CI) Checks

The following workflows run on every PR. **All must pass** for merge:

1. **R-CMD-check.yaml**: Runs R CMD check on Ubuntu (release, devel, oldrel-1), macOS (release), and Windows (release). Installs JAGS on all platforms. Fails on any NOTE. Build args include `--no-manual` and `--compact-vignettes=gs+qpdf`. (~10-15 min)

2. **lint-changed-files.yaml**: Lints only files changed in the PR using lintr with custom `.lintr.R` config. Fails if `LINTR_ERROR_ON_LINT=true` and lints found. (~2-3 min)

3. **test-coverage.yaml**: Runs on macOS, generates code coverage via covr, uploads to Codecov. Creates JUnit test reports. (~5-10 min)

4. **check-spelling.yaml**: Spell checks using spelling package. (~1-2 min)

5. **check-readme.yaml**: Renders README.Rmd and verifies it matches README.md. (~2-3 min)

6. **R-check-docs.yml**: Runs `roxygen2::roxygenise()` and checks if `man/`, `NAMESPACE`, or `DESCRIPTION` changed. Fails if documentation is out of sync. (~2-3 min)

7. **news.yaml**: Ensures NEWS.md is updated for every PR. Can be bypassed with `no-changelog` label. (~1 min)

8. **version-check.yaml**: Verifies DESCRIPTION version number increased vs. main branch. Run `usethis::use_version()` to increment. (~1 min)

9. **pkgdown.yaml**: Builds pkgdown website on PR (preview), tags, and main branch pushes. Requires Quarto setup. (~5-7 min)

10. **copilot-setup-steps.yml**: Configures the GitHub Copilot coding agent's environment automatically. Runs when Copilot starts work, when the workflow file changes, or via manual dispatch. Not a required check for PR merges. See "Copilot Setup Workflow" section for details. (~5-10 min)

### PR Commands

Team members can trigger actions by commenting on PRs:
- `/document` - Runs `roxygen2::roxygenise()` and commits changes
- `/style` - Runs `styler::style_pkg()` and commits changes

## Repository Structure

### Key Directories

- **R/**: Package source code (30 R files)
  - `Run_Mod.R`: Main function to run JAGS Bayesian models
  - `as_case_data.R`: Convert data to case_data class
  - `prep_data.r`, `prep_priors.R`: Data preparation for JAGS
  - `sim_case_data.R`: Simulate case data for testing
  - `post_summ.R`, `postprocess_jags_output.R`: Post-processing JAGS results
  - `plot_*.R`: Diagnostic plotting functions (trace, density, Rhat, effective sample size)
  - `serodynamics-package.R`: Package documentation
  
- **tests/testthat/**: Unit tests (~19 test files)
  - Uses snapshot testing with `_snaps/` subdirectory
  - `fixtures/`: Test fixtures including example JAGS output
  - Most tests seed RNG for reproducibility
  
- **man/**: Auto-generated documentation (25 .Rd files) - **DO NOT EDIT**

- **data/**: Package datasets
  - `nepal_sees.rda`: Example SEES dataset
  - `nepal_sees_jags_output.rda`: Pre-computed JAGS output

- **data-raw/**: Raw data processing scripts (not included in package build)

- **inst/**: Installed files
  - `inst/extdata/`: JAGS model files (`model.jags`, `model.dobson.jags`), example CSV data
  - `inst/examples/`: Example R scripts for documentation
  - `inst/WORDLIST`: Custom spelling dictionary

- **vignettes/**: Package vignettes
  - `dobson.Rmd`: Minimal example vignette
  - `articles/`: Additional articles (pkgdown-only)

- **pkgdown/**: pkgdown website configuration
  - `_pkgdown.yml`: Site structure, reference organization

### Configuration Files

- **DESCRIPTION**: Package metadata, dependencies, version (0.0.0.9044)
- **NAMESPACE**: Auto-generated exports - **DO NOT EDIT**
- **.lintr.R**: Custom lintr configuration (NOT `.lintr`)
- **.Rprofile**: Interactive session setup (loads devtools, conflicted, etc.)
- **.Rbuildignore**: Files excluded from package build
- **project.Rproj**: RStudio project settings (UseNativePipeOperator: Yes)
- **_quarto.yml**: Quarto rendering configuration for vignettes
- **codecov.yml**: Code coverage thresholds (1% target)
- **.gitignore**: Git exclusions

## Common Issues and Workarounds

### JAGS Not Found
**Symptom**: Errors like "JAGS not found" or `runjags::testjags()` fails.
**Solution**: Install JAGS system library first (see Critical Setup Requirements), then install rjags from source.

### Tests Failing on Specific OS
**Symptom**: Some tests fail on Windows or Linux but pass on macOS.
**Solution**: Try to make output platform independent. 
As a fallback, use the `variant` option in `testthat::expect_snapshot()`,
`testthat::expect_snapshot_value()`, and `testthat::expect_snapshot_file()`
to make snapshots platform-specific.

### Documentation Out of Sync
**Symptom**: R-check-docs.yml workflow fails.
**Solution**: Run `devtools::document()` locally and commit the updated `man/` and `NAMESPACE` files.

### Version Not Incremented
**Symptom**: version-check.yaml workflow fails.
**Solution**: Run `usethis::use_version()` to increment the version in DESCRIPTION.

### NEWS.md Not Updated
**Symptom**: news.yaml workflow fails.
**Solution**: Add a bullet point to NEWS.md under the development version header, or add `no-changelog` label to PR if change doesn't warrant NEWS entry.

### Linting Failures
**Symptom**: lint-changed-files.yaml fails.
**Solution**: Review `.lintr.R` for custom rules. Common issues:
- Using `message()` instead of `cli::cli_inform()`
- Using `library()` instead of `::`
- Wrong pipe operator (use `|>` not `%>%`)

### Long-Running Tests Timeout
**Symptom**: Tests timeout during CI.
**Solution**: MCMC sampling can be slow. Tests use small iteration counts (nchain=2, nadapt=100, nburn=100, nmc=10, niter=10) to speed up. If adding new tests, follow this pattern.

## Testing Requirements Before Code Changes

**ALWAYS establish value-based unit tests BEFORE modifying any functions.** This ensures that changes preserve existing behavior and new behavior is correctly validated.

### Testing Strategy

Choose the appropriate testing approach based on the context:

#### When to Use Snapshot Tests
Use snapshot tests (`expect_snapshot()`, `expect_snapshot_value()`, or `expect_snapshot_data()`) when:
- Testing complex data structures (data.frames, lists, model outputs)
- Validating MCMC outputs or statistical results
- Output format stability is important
- The exact values are less important than structural consistency

**Examples from this repository:**
```r
# For data frames with numeric precision control
dataset |> expect_snapshot_data(name = "sees-data")

# For R objects with serialization
prepped_data |> expect_snapshot_value(style = "serialize")

# For simple output or error messages
results <- post_summ(data) |> expect_no_error()
testthat::expect_snapshot(results)
```

#### When to Use Explicit Value Tests
Use explicit value tests (`expect_equal()`, `expect_identical()`, etc.) when:
- Testing simple scalar outputs
- Validating specific numeric thresholds or boundaries
- Testing Boolean returns or categorical outputs
- Exact values are critical for correctness

**Examples:**
```r
# Testing exact numeric values
expect_equal(calculate_mean(c(1, 2, 3)), 2)

# Testing with tolerance for floating point
expect_equal(calculate_ratio(3, 7), 0.4285714, tolerance = 1e-6)

# Testing logical conditions
expect_true(is_valid_input(data))
expect_false(has_missing_values(complete_data))
```

#### Testing Best Practices
- **Seed randomness**: Use `withr::local_seed()` or `withr::with_seed()` for reproducible tests involving random number generation
- **Use small test cases**: Particularly for MCMC tests, use minimal iteration counts (nchain=2, nadapt=100, nburn=100, nmc=10, niter=10) to keep tests fast
- **Platform-specific snapshots**: Use the `variant` parameter in snapshot functions when output differs by OS
- **Test fixtures**: Store complex test data in `tests/testthat/fixtures/` for reuse
- **Custom snapshot helpers**: Use `expect_snapshot_data()` for data frames with automatic CSV snapshot and numeric precision control

### Test-Driven Workflow
1. **Before modifying a function**: Write or verify existing tests capture the current behavior
2. **Add new tests**: Create tests for the new functionality you're adding
3. **Make changes**: Modify the function implementation
4. **Run tests**: Validate all tests pass, updating snapshots only when changes are intentional
5. **Review snapshots**: When snapshots change, review the diff to ensure changes are expected

## Code Style Guidelines

- **Lab manual overrides tidyverse style**: Follow the [UCD-SeRG Lab Manual coding-style chapter](https://ucd-serg.github.io/lab-manual/coding-style.html) first; fall back to the [tidyverse style guide](https://style.tidyverse.org) only where the lab manual is silent. Where the two conflict, the lab manual wins.
- **Use explicit `return()` statements**: Per the [lab manual](https://ucd-serg.github.io/lab-manual/coding-style/function-structure-and-documentation.html#explicit-return-statements) (which follows the [Google R Style Guide](https://google.github.io/styleguide/Rguide.html#use-explicit-returns)), always end functions with `return(value)` rather than relying on R's implicit final-expression return. This overrides the tidyverse style guide. Note: `return_linter` is currently disabled in `.lintr` for flexibility on older code, but new code should use explicit returns.
- **Use native pipe**: `|>` not `%>%`
- **Avoid redundant logical comparisons**: Use logical values directly (e.g., `if (is_ready)` not `if (is_ready == TRUE)`)
- **Naming**: snake_case, acronyms may be uppercase (e.g., `prep_IDs_data`)
- **Messaging**: Use `cli::cli_*()` functions for all user-facing messages
- **No `library()` in package code**: Use `::` or DESCRIPTION Imports
- **Document all exports**: Use roxygen2 (@title, @description, @param, @returns, @examples)
- **Test snapshot changes**: Use `testthat::announce_snapshot_file()` for CSV snapshots
- **Seed tests**: Use `withr::local_seed()` for reproducible tests
- **Prefer data-first pipelines**: Design and call functions so the primary data object flows through `|>` naturally
- **Avoid code duplication**: Don't copy-paste substantial code chunks. Instead, decompose reusable logic into well-named helper functions. This improves maintainability, testability, and reduces the risk of inconsistent behavior across similar code paths.
- **Quarto vignettes**: Use Quarto-style chunk options with `#|` prefix (e.g., `#| label: my-chunk`, `#| eval: false`) instead of R Markdown comma-separated options (e.g., `{r my-chunk, eval=FALSE}`)
- **Tidyverse replacements**: Use tidyverse/modern replacements for base R functions where available (e.g., `sessioninfo::session_info()` instead of `sessionInfo()`, `tibble::tibble()` instead of `data.frame()`, `readr::read_csv()` instead of `read.csv()`)
- **Write tidy code**: Keep code clean, readable, and well-organized. Follow consistent formatting, use meaningful variable names, and maintain logical structure

## Documentation and Evidence Standards

- **Do not assume behavior**: Run the relevant command(s) and verify outputs before claiming something works.
- **Use markdown syntax in `.qmd` prose**: Wrap code in backticks, use markdown links, and avoid raw HTML links.
- **Use semantic line breaks and list spacing in `.qmd`**: Break long prose across lines and include a blank line before bullet/numbered lists.
- **Use Quarto cross-references**: Reference sections/figures/tables with labels (for example `@sec-...`, `@fig-...`, `@tbl-...`) instead of plain text references.
- **Support factual claims**: Back factual statements with citations or direct verification evidence, and verify external links/resources before describing them.

## Code Formatting Guidelines

When adding or editing text in source code (for example comments, documentation strings, or error messages) or in Quarto document text chunks:

- Add a newline at the end of every phrase or logical unit of text
- Put each phrase on its own line in source files
- Treat a phrase as a complete thought, clause, or sentence
- Prefer this structure to improve readability and make diffs clearer

## Package Development Commands Summary

```r
# Complete development workflow
devtools::load_all()           # Load package for interactive testing
devtools::document()           # Update documentation
devtools::test()               # Run tests
devtools::check()              # Full R CMD check (slow)
usethis::use_version()         # Increment version
lintr::lint_package()          # Check code style
spelling::spell_check_package() # Check spelling
rmarkdown::render("README.Rmd") # Update README
```

## Trust These Instructions

These instructions have been validated against the actual repository structure, workflows, and configuration files. When making changes:

1. **ALWAYS** install R (>= 4.1.0) and all development dependencies when starting work on a PR
2. **ALWAYS** ensure JAGS is installed before any build/test operations
3. **ALWAYS** establish value-based unit tests (snapshot or explicit value tests) BEFORE modifying functions
4. **ALWAYS** write tidy, clean, and well-organized code
5. **ALWAYS** run `devtools::document()` after modifying roxygen2 comments
6. **ALWAYS** edit README.Rmd (not README.md) for README changes
7. **ALWAYS** increment dev version number to be one ahead of main branch before requesting PR review
8. **ALWAYS** update NEWS.md for user-facing changes
9. **ALWAYS** run tests before committing (`devtools::test()`)
10. **ALWAYS** check and fix lintr issues in changed files in PRs before committing
11. **ALWAYS** run `devtools::document()` before requesting PR review
12. **ALWAYS** make sure `devtools::check()` passes before requesting PR review
13. **ALWAYS** make sure `devtools::spell_check()` passes before requesting PR review
14. **ALWAYS** run `pkgdown::build_site()` before requesting PR review to ensure the pkgdown site builds successfully
15. **ALWAYS** verify Quarto documents render successfully locally - don't rely on CI workflows. For vignettes and articles, test rendering with `quarto render path/to/file.qmd` or by building the full site with `pkgdown::build_site()`
16. When `pkgdown::build_site()` has errors related to Quarto, use `quarto::quarto_render(input = "path/to/file.qmd", quiet = FALSE)` to debug and see detailed error messages

Only search for additional information if these instructions are incomplete or incorrect for your specific task.
