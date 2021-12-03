
rm(list=ls())

Sys.setenv(TZ='UTC')

library(caret)
library(lubridate)
library(doParallel)
library(parallelly)
library(RANN)        # only needed if impute == "knnImpute"
source("_RF_impute_missing_fluxes.R")

# import ------------------------------------------------------------------
## import locally
setwd(dir = paste("~/GFZ/_Dagow/5_data_analysis/Felix/3_gap_filling/"))
data <- read.csv("./RF_data/df_dagow_RF.csv")

## import on linux server
# setwd(dir = paste("~/RF"))
# data <- read.csv("./RF_data/df_dagow_RF.csv")

## format
# The dataset needs the column Timestamp (as.POSIXct("YYYY-MM-DD HH:MM")). 
# All other variables should be quality controlled Fluxes (i.e. variables to gap-fill) and meteorological variables (predictors)
data$Timestamp <- ymd_hms(data$Timestamp)

## generate output directories 
# beware: when run on linux server this might not work. So: 
# make sure the following 3 directories are present in you current working directory: c("RF_models", "RF_plots", "RF_results")
if (!dir.exists(paste0(getwd(),"/RF_models"))) {dir.create(paste0(getwd(),"/RF_models"))}
if (!dir.exists(paste0(getwd(),"/RF_plots"))) {dir.create(paste0(getwd(),"/RF_plots"))}
if (!dir.exists(paste0(getwd(),"/RF_results"))) {dir.create(paste0(getwd(),"/RF_results"))}

# set processing parameters for test run on local machine -----------------------------------------------
# set suffix, can be used for testing different settings
suffix = "_mtrytrain"

# Flux to be gap filled
fluxes <- c("H", "LE", "NEE") 
# fluxes <- c("FCH4") 

# For which years should the processing be performed? 
years <- rep(c(2015:2016), each = length(fluxes))

# Which variables should be used as predictors
predictors <- c( 
                # "H", "LE", "NEE", # activate only when gap-filling FCH4
                "Tair", "RH", "Pa", "SWin", "SWout", "LWin", "LWout",
                "Rn", "ws", "wd", "TW", "DO", "WTD", "VPD", "Tskin", 
                "DOY", "sin_hod", "cos_hod", "sin_doy", "cos_doy")

  
# Which pre-processing steps should be performed? i.e. how should missing values in predictor variables be treated?
# impute = rep(c("medianImpute", "knnImpute", "bagImpute"), each = length(fluxes) + length(years))
impute = rep(c("medianImpute"), each = length(fluxes) + length(years))

# How many cores should be used for parallel processing. Depends on your machine.
N_cores = makeCluster(parallelly::availableCores(omit = 1))

# How many trees should be grown. Take care, the number of trees scales linearly with the processing time. Higher N_trees will take longer.
N_trees = 20

# Should gridded search for mtry be performed? The more mtrys are computed the higher the processing time. 
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
    
    # when using individual mtry per flux for all years:  CAUTION: if this setting is choosen, mtry has to be supplied as sdditional variable to the function using mapply(). (I.e. not in the MoreArgs list but together with fluxes, years and impute )
    # mtry = rep(c(9, 10, 3), times = length(fluxes))
    
    K_cv = NULL
    N_cv = NULL
  }


# perform parallel Flux Imputation using RF -------------------------------
cluster <- makePSOCKcluster(N_cores)
registerDoParallel(cluster)

mapply(RF_impute_missing_fluxes, 
       fluxes, years, impute,
       # mtry = mtry, # activate if one individual mtry is used per flux but for all years
       MoreArgs = list(data = data, predictors = predictors,
                       N_trees = N_trees, train_mtry = train_mtry, 
                       mtry = mtry, # comment out if one individual mtry is used per flux but for all years
                       K_cv = K_cv, N_cv = N_cv, suffix = suffix))

stopCluster(cluster)

