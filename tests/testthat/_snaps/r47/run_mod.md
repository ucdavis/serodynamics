# results are consistent with SEES data

    list(names = c("Iteration", "Chain", "Parameter", "Iso_type", 
    "Stratification", "Subject", "value"), class = c("sr_model", 
    "tbl_df", "tbl", "data.frame"), nChains = 2L, nParameters = 440L, 
        nIterations = 100L, nBurnin = 20, nThin = 1, priors = list(
            mu_hyp_param = c(1, 7, 1, -4, -1), prec_hyp_param = c(1, 
            1e-05, 1, 0.001, 1), omega_param = c(1, 50, 1, 10, 1), 
            wishdf_param = 20, prec_logy_hyp_param = c(4, 1)))

# results are consistent with unstratified SEES data with population  parameters

    list(names = c("Iteration", "Chain", "Parameter", "Iso_type", 
    "Stratification", "Subject", "value"), class = c("sr_model", 
    "tbl_df", "tbl", "data.frame"), nChains = 2L, nParameters = 1952L, 
        nIterations = 100L, nBurnin = 20, nThin = 1, priors = list(
            mu_hyp_param = c(1, 7, 1, -4, -1), prec_hyp_param = c(1, 
            1e-05, 1, 0.001, 1), omega_param = c(1, 50, 1, 10, 1), 
            wishdf_param = 20, prec_logy_hyp_param = c(4, 1)))

