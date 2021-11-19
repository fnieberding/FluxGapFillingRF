This Repo contains a function and use case for gap-filling Eddy Covariance data using Random Forest algorithm (Breiman, 2001). 

The function in RF_impute_missing_fluxes.R is basically a convenient wrapper using caret::train to perform gap-filling of your input variables using randomForest::randomForest.

The script _RFatMefe.R imports the data and sets the processing options (e.g. mtry, n_trees, pre processing steps etc.) Then RF_impute_missing_fluxes.R estimates the train parameters for every (flux) variable to be filled on an annual basis. The script is performed in parallel to increase computation time and can easily be adapted to run on linux server.  

The other two scripts (_check_output.R and get_mtry.R) can be used to inspect model accuracies and results for mtry determination.

References:

Breiman, L. (2001), Random Forests, Machine Learning 45(1), 5-32.

Breiman, L (2002), “Manual On Setting Up, Using, And Understanding Random Forests V3.1”, https://www.stat.berkeley.edu/~breiman/Using_random_forests_V3.1.pdf.
