rm(list=ls())
Sys.setenv(TZ='UTC')

library(tidyverse)
library(randomForest)
library(caret)

setwd(dir = paste("~/GFZ/_Dagow/5_data_analysis/Felix/3_gap_filling/"))

# import RF Models
mod_RF_H_2015_bagImpute <- readRDS("./RF_models/mod_RF_H_2015_bagImpute.rds")
mod_RF_H_2015_knnImpute <- readRDS("./RF_models/mod_RF_H_2015_knnImpute.rds")
mod_RF_H_2015_medianImpute <- readRDS("./RF_models/mod_RF_H_2015_medianImpute.rds")


# import RF results
df_RF_H_2015_bagImpute <- read_csv("./RF_results/pred_RF_H_2015_bagImpute.csv")
df_RF_H_2015_knnImpute <- read_csv("./RF_results/pred_RF_H_2015_knnImpute.csv")
df_RF_H_2015_medianImpute <- read_csv("./RF_results/pred_RF_H_2015_medianImpute.csv")


# plot RMSE decrease for different imputation methods
png("H_bagImpute.png")
plot(sqrt(mod_RF_H_2015_bagImpute$finalModel$mse), ylab = "RMSE of H (W / m?)", xlab = "N trees", main = "Bag Impute", ylim = c(4.5,10))
abline(5,0, col = "red")
dev.off()

png("H_medianImpute.png")
plot(sqrt(mod_RF_H_2015_medianImpute$finalModel$mse), ylab = "RMSE of H (W / m?)", xlab = "N trees", main = "Median Impute", ylim = c(4.5,10))
abline(5,0, col = "red")
dev.off()

png("H_knnImpute.png")
plot(sqrt(mod_RF_H_2015_knnImpute$finalModel$mse), ylab = "RMSE of H (W / m?)", xlab = "N trees", main = "KNN Impute", ylim = c(4.5,10))
abline(5,0, col = "red")
dev.off()

# plot variable importance for different imputation methods
png("H_var_Imp_bag.png")
plot(varImp(mod_RF_H_2015_bagImpute, scale = F), main = "variable importance for H \n by Bag Impute", xlim = c(0,100))
dev.off()

png("H_var_Imp_med.png")
plot(varImp(mod_RF_H_2015_medianImpute, scale = F), main = "variable importance for H \n by Median Impute", xlim = c(0,100))
dev.off()

png("H_var_Imp_knn.png")
plot(varImp(mod_RF_H_2015_knnImpute, scale = F), main = "variable importance for H \n by KNN Impute", xlim = c(0,100))
dev.off()



df_RF_H_2015_medianImpute %>%
  filter(!is.na(value)) %>%
  # pivot_longer(c(value, RF_pred)) %>%
  ggplot(aes(value, fill = name)) +
  geom_density(alpha = .5)
  geom_boxplot(alpha = .5)

  
  
  