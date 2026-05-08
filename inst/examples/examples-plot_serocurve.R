# nepal_sees_jags_output already includes population_params
model <- serodynamics::nepal_sees_jags_output

# Population-level curve for a single antigen-isotype and stratum
p1 <- plot_serocurve(
  model       = model,
  antigen_iso = "HlyE_IgA",
  strat       = "typhi"
)
print(p1)

# Population-level curves for both stratifications, coloured by stratum
p2 <- plot_serocurve(
  model       = model,
  antigen_iso = "HlyE_IgA"
)
print(p2)

# Facet by stratification instead of colouring
p3 <- plot_serocurve(
  model          = model,
  antigen_iso    = "HlyE_IgA",
  facet_by_strat = TRUE
)
print(p3)

# Multiple antigen-isotypes, faceted, without CI
p4 <- plot_serocurve(
  model                = model,
  antigen_iso          = c("HlyE_IgA", "HlyE_IgG"),
  facet_by_antigen_iso = TRUE,
  show_ci              = FALSE
)
print(p4)

# Using the predictive distribution for a new individual (newperson posterior)
p5 <- plot_serocurve(
  model        = model,
  antigen_iso  = "HlyE_IgA",
  param_source = "newperson"
)
print(p5)
