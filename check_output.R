rm(list=ls())
Sys.setenv(TZ='UTC')

library(tidyverse)
library(randomForest)
library(caret)

setwd(dir = paste("~/GFZ/_Dagow/5_data_analysis/Felix/3_gap_filling/"))

# import RF Models
# mod_RF_H_2015_bagImpute <- readRDS("./RF_models/mod_RF_H_2015_bagImpute.rds")
# mod_RF_H_2015_knnImpute <- readRDS("./RF_models/mod_RF_H_2015_knnImpute.rds")
# mod_RF_H_2015_medianImpute <- readRDS("./RF_models/mod_RF_H_2015_medianImpute.rds")


# import 
list_of_files_T <- list.files(path = "./RF_models/",
                              recursive = TRUE,
                              pattern = "*1000_TRUE_wNEE.rds",
                              full.names = TRUE)

list_of_files_F <- list.files(path = "./RF_models/",
                            recursive = TRUE,
                            pattern = "*1000_TRUE_noNEE.rds",
                            full.names = TRUE)

mod_H_2015_T <- read_rds(list_of_files_T[1])
mod_H_2015_F <- read_rds(list_of_files_F[1])

plot(sqrt(mod_H_2015_T$finalModel$mse), ylab = "RMSE of H (W / m?)", xlab = "N trees", main = "median Impute", type = "b")
points(sqrt(mod_H_2015_F$finalModel$mse), col = "red")
lines(sqrt(mod_H_2015_F$finalModel$mse), col = "red")

plot(varImp(mod_H_2015_T, scale = F), main = "variable importance for H \n by median Impute", xlim = c(0,100))
plot(varImp(mod_H_2015_F, scale = F), main = "variable importance for H \n by median Impute", xlim = c(0,100))


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

  
  
  