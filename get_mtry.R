rm(list=ls())
Sys.setenv(TZ='UTC')

library(tidyverse)

setwd(dir = paste("~/GFZ/_Dagow/5_data_analysis/Felix/RandomForest/"))

# import 
df_mtry_H_2015 <- read_csv("./RF_models/mtry_H_2015.csv") %>%
  mutate(Year = 2015,
         Flux = "H")
df_mtry_H_2016 <- read_csv("./RF_models/mtry_H_2016.csv") %>%
  mutate(Year = 2016,
         Flux = "H")

df_mtry_LE_2015 <- read_csv("./RF_models/mtry_LE_2015.csv") %>%
  mutate(Year = 2015,
         Flux = "LE")
df_mtry_LE_2016 <- read_csv("./RF_models/mtry_LE_2016.csv") %>%
  mutate(Year = 2016,
         Flux = "LE")

df_mtry_NEE_2015 <- read_csv("./RF_models/mtry_NEE_2015.csv") %>%
  mutate(Year = 2015,
         Flux = "NEE")
df_mtry_NEE_2016 <- read_csv("./RF_models/mtry_NEE_2016.csv") %>%
  mutate(Year = 2016,
         Flux = "NEE")

df_mtry_FCH4_2015 <- read_csv("./RF_models/mtry_FCH4_2015.csv") %>%
  mutate(Year = 2015,
         Flux = "FCH4")
df_mtry_FCH4_2016 <- read_csv("./RF_models/mtry_FCH4_2016.csv") %>%
  mutate(Year = 2016,
         Flux = "FCH4")

# join data frames
df_mtry <- rbind.data.frame(df_mtry_H_2015, df_mtry_H_2016, 
                 df_mtry_LE_2015, df_mtry_LE_2016, 
                 df_mtry_NEE_2015, df_mtry_NEE_2016,
                 df_mtry_FCH4_2015, df_mtry_FCH4_2016)

# calculate best tune parameters
df_mtry_results <- df_mtry %>%
  group_by(Flux, Year) %>%
  summarise(mtry_RMSE_min = mtry[which.min(RMSE)],
            RMSE_min = min(RMSE), 
            mtry_Rsquare_max = mtry[which.max(Rsquared)],
            Rsquare_max = max(Rsquared),
            mtry_MAE = mtry[which.min(MAE)],
            MAE_min = min(MAE)) %>%
  ungroup()

# plot results per Year and Flux
df_mtry %>%
  mutate(Year = as.factor(Year)) %>%
  ggplot(aes(mtry, RMSE, color = Year)) +
  geom_point() +
  geom_line() +
  geom_ribbon(aes(ymin = RMSE - RMSESD, ymax = RMSE + RMSESD, fill = Year), alpha = .5) +
  geom_point(data = df_mtry_results, aes(x = mtry_RMSE_min, y = RMSE_min), color = "black") +
  geom_hline(data = df_mtry_results, aes(yintercept = RMSE_min), color = "black") +
  geom_vline(data = df_mtry_results, aes(xintercept = mtry_RMSE_min), color = "black") +
  facet_wrap(~Flux, ncol = 2, scales = "free_y") +
  theme_bw()

# get average mtry (choose "floor" due to principle of parsimony)
df_mtry_results %>%
  group_by(Flux) %>%
  summarise(across(starts_with("mtry"), ~floor(mean(., na.rm = T))))


