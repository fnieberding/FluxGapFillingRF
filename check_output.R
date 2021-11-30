rm(list=ls())
Sys.setenv(TZ='UTC')

library(tidyverse)
library(randomForest)
library(caret)
library(cowplot)

setwd(dir = "~/GFZ/_Dagow/5_data_analysis/Felix/3_gap_filling/")

# function
plot_RF_results <- function(Flux, Year, mtry) {
  
  # import
  mod <- read_rds(paste0("./RF_models/mod_RF_", Flux, "_", Year, "_medianImpute_750_mtrySet", mtry, ".rds"))
  
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
  ggsave(paste0("./plots/", Flux, "_", Year, "_750_mtrySet", mtry, ".png"), width = 16, height = 9, dpi = 300)
}

Flux = c("H", "LE", "NEE")
Year = rep(c(2015:2021), each = length(Flux))
mtry = rep(c(9, 10, 3), times = length(Flux))

mapply(plot_RF_results, Flux = Flux, Year = Year, mtry = mtry)

Flux = "H"
Year = 2015
mtry = 9
