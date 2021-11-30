rm(list=ls())
Sys.setenv(TZ='UTC')

library(tidyverse)
library(randomForest)
library(caret)
library(cowplot)
library(randomForestExplainer)

setwd(dir = paste("~/GFZ/_Dagow/5_data_analysis/Felix/3_gap_filling/"))

# function

plot_RF_results <- function(Flux, Year) {
  
  # import
  mod <- read_rds(paste0("./RF_models/mod_RF_", Flux, "_", Year, "_medianImpute_750_.rds"))
  
  # format
  df_mod <- data.frame(N_trees = 1:750, RMSE = sqrt(mod$finalModel$mse))
  
  # plot
  p1 <- ggplot(df_mod, aes(x = N_trees, y = RMSE )) +
    geom_point() +
    labs(y = "RMSE", x = "N trees", title = paste0(Flux, " - ", Year)) +
    theme_bw()
  
  p2 <- plot(varImp(mod, scale = T), main = paste0(Flux, " - ", Year), xlim = c(0,105))
  
  p3 <- plot_grid(p1,p2, ncol = 2, align = "hv", axis = "t")
  
  # print
  ggsave(paste0("./plots/", Flux, "_", Year, "_750.png"), width = 16, height = 9, dpi = 300)
}

Flux = c("H", "LE", "NEE")
Year = rep(c(2015:2021), each = length(Flux))

mapply(plot_RF_results, Flux = Flux, Year = Year)


  