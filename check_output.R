rm(list=ls())
Sys.setenv(TZ='UTC')

library(tidyverse)
library(randomForest)
library(caret)
library(cowplot)

setwd(dir = "~/GFZ/_Dagow/5_data_analysis/Felix/3_gap_filling/")

# function
plot_RF_results <- function(Flux, Year) {
  
  # import
  mod <- read_rds(paste0("./RF_models/mod_RF_", Flux, "_", Year, "_medianImpute_750_mtrySet", ".rds"))
  
  # format
  df_mod <- data.frame(N_trees = 1:750, RMSE = sqrt(mod$finalModel$mse))
  
  df_varImp <- varImp(mod, scale = F)$importance
  df_varImp$Var <- rownames(df_varImp)
  df_varImp <- arrange(df_varImp, Overall)
  df_varImp$Var <- factor(df_varImp$Var, levels = as.character(df_varImp$Var))
  
  # plot
  p1 <- ggplot(df_mod, aes(x = N_trees, y = RMSE )) +
    geom_point() +
    labs(y = "RMSE", x = "N trees", title = paste0("Model Accuracy for ", Flux, " - ", Year)) +
    theme_bw()
  
  p2 <- ggplot(df_varImp, aes(x = Overall, y = Var )) +
    geom_segment( aes(x=0, xend=Overall, y=Var, yend=Var)) +
    geom_point(color = "blue") +
    labs(x = "Importance", title = paste0("Variable Importance for ", Flux, " - ", Year)) +
    theme_classic() +
    theme(panel.border = element_rect(fill = NA), axis.title.y = element_blank())
  
  p3 <- plot_grid(p1 + theme(text = element_text(size = 16)),
                  p2 + theme(text = element_text(size = 16)), 
                  ncol = 2, align = "h", axis = "t")
  
  # print
  ggsave(paste0("./plots/", Flux, "_", Year, "_750_mtrySet", ".png"), width = 16, height = 9, dpi = 300)
}

Flux = c("H", "LE", "NEE", "FCH4")
Year = rep(c(2015:2021), each = length(Flux))

mapply(plot_RF_results, Flux = Flux, Year = Year)


# get accuracies ----------------------------------------------------------
df_acc <- data.frame(Year = 2015:2021,
                     name = rep(c("H", "LE", "NEE", "FCH4"), each = length(2015:2021)),
                     RMSE_test = NA_real_,
                     RMSE_oob = NA_real_,
                     RSQUARE_test = NA_real_,
                     RSQUARE_oob = NA_real_)


get_RF_accuracy <- function(Flux, Year) {
  # import results
  res.name <- list.files(path = "./RF_results/",
                         # pattern = paste0("*_", Flux, "_", Year, "_medianImpute_750_mtrySet\\d{0,}.csv"),
                         pattern = paste0("*_", Flux, "_", Year, "_medianImpute_750_mtrySet.csv"),
                         full.names = TRUE)
  
  result <- read_csv(res.name, show_col_types = F)
  
  # import models
  result$Timestamp <- as.POSIXct(result$Timestamp)
  
  mod.name <- list.files(path = "./RF_models/",
                              # pattern = paste0("*_", Flux, "_", Year, "_medianImpute_750_mtrySet\\d{0,}.rds"),
                         pattern = paste0("*_", Flux, "_", Year, "_medianImpute_750_mtrySet.rds"),
                         full.names = TRUE)
  
  mod_RF <- read_rds(mod.name)
  
  # calculate error metrics
  test_value = result[which(result[, "test_set"] == 1), "value"]$value
  test_pred = result[which(result[, "test_set"] == 1), "RF_pred"]$RF_pred
  
  test_pred = test_pred[which(!is.na(test_value))]
  test_value = test_value[which(!is.na(test_value))]
  
  rss = sum((test_value - test_pred)^2, na.rm = T)
  tss = sum((test_value - mean(test_value, na.rm = T))^2)
  
  # test-set error
  RMSE_test = round(caret::RMSE(test_pred, test_value), 3)
  RSQUARE_test = round(1 - rss / tss, 3)
  
  # out-of-bag error
  RMSE_oob = round(sqrt(min(mod_RF$finalModel$mse)), 3)
  RSQUARE_oob = round(max(mod_RF$finalModel$rsq), 3)
  
  # print to df_acc in global environment
  df_acc[df_acc$Year == Year & df_acc$name == Flux, "RMSE_test"] <<- RMSE_test
  df_acc[df_acc$Year == Year & df_acc$name == Flux, "RMSE_oob"] <<- RMSE_oob
  df_acc[df_acc$Year == Year & df_acc$name == Flux, "RSQUARE_test"] <<- RSQUARE_test
  df_acc[df_acc$Year == Year & df_acc$name == Flux, "RSQUARE_oob"] <<- RSQUARE_oob
}


Flux = c("H", "LE", "NEE", "FCH4")
Year <- rep(c(2015:2021), each = length(Flux))

mapply(get_RF_accuracy, Flux = Flux, Year = Year)




