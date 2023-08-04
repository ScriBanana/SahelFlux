library(NLMR)
library(raster)
library(landscapetools)
# https://besjournals.onlinelibrary.wiley.com/doi/10.1111/2041-210X.13076


# simulate a distance gradient
high_autocorrelation <- nlm_distancegradient(ncol = 100, nrow = 100,
                                             origin = c(50,50, 50,50))

# landscape with lower autocorrelation 
low_autocorrelation <- nlm_fbm(ncol = 100, nrow = 100, fract_dim = 1.5)

ecotones <- util_merge(low_autocorrelation, high_autocorrelation)

nr_classified <- landscapetools::util_classify(ecotones, weighting = c(0.01, 0.2, 0.1, 0.2,0.2))


# look at the results
show_landscape(list("Low autocorrelation" = low_autocorrelation,
                    "High autocorrelation" = high_autocorrelation,
                    "Ecotones" = nr_classified
))
