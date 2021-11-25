
rm(list=ls())

Sys.setenv(TZ='UTC')

library(caret)
library(doParallel)
library(parallelly)
library(RANN)        # only needed if impute == "knnImpute"
source("_RF_impute_missing_fluxes.R")

# import ------------------------------------------------------------------
## import locally
setwd(dir = paste("~/GFZ/_Dagow/5_data_analysis/Felix/3_gap_filling/"))
df <- read.csv("./RF_data/df_dagow_RF_211125.csv")

# df <- df %>% select(-NEE)

## import on linux server
# setwd(dir = paste("~/RF"))
# df <- read.csv("./RF_data/df_dagow_RF.csv")

## format
# The dataset needs the column Timestamp (as.POSIXct("YYYY-MM-DD HH:MM")). 
# All other variables should be quality controlled Fluxes (i.e. variables to gap-fill) and meteorological variables (predictors)
df$Timestamp <- as.POSIXct(df$Timestamp)

## generate output directories 
# beware: when run on linux server this might not work. So: 
# make sure the following 3 directories are present in you current working directory: c("RF_models", "RF_plots", "RF_results")
if (!dir.exists(paste0(getwd(),"/RF_models"))) {dir.create(paste0(getwd(),"/RF_models"))}
if (!dir.exists(paste0(getwd(),"/RF_plots"))) {dir.create(paste0(getwd(),"/RF_plots"))}
if (!dir.exists(paste0(getwd(),"/RF_results"))) {dir.create(paste0(getwd(),"/RF_results"))}

# set processing parameters for test run on local machine -----------------------------------------------
# set suffix, can be used for testing different settings
suffix = "_wNEE"

# Flux to be gap filled. If other fluxes are present in data set they will also be used as predictor variables. 
fluxes <- c("H") 

# For which years should the processing be performed? 
years <- rep(c(2015), each = length(fluxes))

# Determine if the other fluxes should also be used as predictors
use_other_fluxes_as_predictors = T

if (use_other_fluxes_as_predictors) {
  predictors = NULL
} else {
  predictors <- c("Tair", "RH", "Pa", "SWin", "SWout", "LWin", "LWout",
                  "Rn", "ws", "wd", "TW", "DO", "WTD", "Tskin", "DOY")
}

# Which pre-processing steps should be performed? i.e. how should missing values in predictor variables be treated?
# impute = rep(c("medianImpute", "knnImpute", "bagImpute"), each = length(fluxes) + length(years))
impute = rep(c("medianImpute"), each = length(fluxes) + length(years))

# How many cores should be used for parallel processing. Depends on your machine.
N_cores = makeCluster(parallelly::availableCores(omit = 1))

# How many trees should be grown. Take care, the number of trees scales linearly with the processing time. Higher N_trees will take longer.
N_trees = 1000

# Should gridded search for mtry be performed? The more mtry?s are computed the higher the processing time. 
train_mtry = F

if (train_mtry) {
  ## if train_mtry = T
  # set vector of all possible mtrys to train.
  # mtry = c(1:length(predictors))  
  
  # alternatively specify vector of desired length, e.g. 
  mtry = c(6,9)
  
  K_cv = 3 # K-fold cross validation used for training mtry. Only used when train_mtry == T
  N_cv = 3  # N times repeated cross validation. Only used when train_mtry == T
  
  } else {
    ## if train_mtry = F
    # set single number when mtry is already trained
    mtry = 9  
    
    # alternatively use default for RF regression
    # mtry = floor(length(predictors)/3)
    
    K_cv = NULL
    N_cv = NULL
  }


# set processing parameters "final" run on linux server!  ------------------------------------
## Take care, this code will take a long time and the resulting models will be huge (~500 MB each). 
## Progress can be estimated with the plots and files which are written out during processing.

# fluxes <- c("H", "LE", "NEE", "FCH4")
# years <- rep(c(2015:2016), each = length(fluxes))
# impute = rep(c("medianImpute", "knnImpute", "bagImpute"), each = length(fluxes) + length(years))
# mtry = c(1:length(predictors)) 
# train_mtry = T
# N_cores = 10
# N_trees = 1000
# K_cv = 10
# N_cv = 5


# perform parallel Flux Imputation using RF -------------------------------
cluster <- makePSOCKcluster(N_cores)
registerDoParallel(cluster)

mapply(RF_impute_missing_fluxes, 
       fluxes, years, impute, 
       MoreArgs = list(data = df, predictors = predictors, use_other_fluxes_as_predictors = use_other_fluxes_as_predictors,
                       N_cores = N_cores, N_trees = N_trees, train_mtry = train_mtry, 
                       mtry = mtry, K_cv = K_cv, N_cv = N_cv, suffix = suffix))

stopCluster(cluster)

