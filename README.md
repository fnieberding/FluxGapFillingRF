Using Random Forest for Eddy Covariance flux gap-filling
================
Felix Nieberding
2021-11-25

## Description

This Repo contains a function and use case for gap-filling Eddy
Covariance data using Random Forests algorithm (Breiman, 2001).

The function in *\_RF_impute_missing_fluxes.R* is basically a convenient
wrapper using `caret::train()` to perform gap-filling of input variables
using `randomForest::randomForest()`. It is based on the code provided
by [Yeonuk Kim](https://github.com/yeonukkim/EC_FCH4_gapfilling) based
on his recent publication in Global Change Biology:
<https://doi.org/10.1111/gcb.14845>.

The script *gap_filling.R* imports the data and sets the processing
options (e.g. mtry, n_trees, pre processing steps etc.) Then
*\_RF_impute_missing_fluxes.R* estimates the train parameters for every
(flux) variable to be filled on an annual basis. The script is performed
in parallel to increase computation time and can easily be adapted to
the number of cores available.

The other two scripts (*check_output.R* and *get_mtry.R*) can be used to
inspect model accuracies and results for mtry determination.

### References:

Breiman, L. (2001), Random Forests, Machine Learning 45(1), 5-32.
