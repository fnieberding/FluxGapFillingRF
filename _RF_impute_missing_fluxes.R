RF_impute_missing_fluxes <- 
  function(Flux, Year, predictors = NULL, impute, data, N_cores, N_trees, train_mtry, mtry, K_cv = NULL, N_cv = NULL, suffix = "") {
    
    # check if output directories are present
    if (!dir.exists(paste0(getwd(),"/RF_models"))) {stop("Output directory ./RF_models does not exist")}
    if (!dir.exists(paste0(getwd(),"/RF_plots"))) {stop("Output directory ./RF_plots does not exist")}
    if (!dir.exists(paste0(getwd(),"/RF_results"))) {stop("Output directory ./RF_results does not exist")}
    
    # check if all flux and predictor variables are present in data set
    if (!Flux %in% colnames(data)) {stop("Not all fluxes are present in data.")}
    if (any(!predictors %in% colnames(data))) {stop("Not all predictors are present in data.")}
    
    # specify predictors
    predictors = c("VAR", predictors)

    # make "Year" variable in data
    data$Year <- as.integer(format(data$Timestamp, "%Y"))
    
    # select only period when Fluxes is not missing and Year == Year
    wm_only <- data[!is.na(data[ , Flux]) , ]
    wm_only <- wm_only[wm_only[ , "Year"] == Year, ] 
    
    # assign 'VAR' name to Fluxes. Necssary for correct formulation in train()
    names(wm_only)[names(wm_only) == Flux] <- "VAR"
    
    # 75% of data used for model tuning/validation
    index <- createDataPartition(wm_only[ , "VAR"], p = 0.75, list = F) 
    train_set <- wm_only[index, ]
    test_set <- wm_only[-index, ]
    
    ### random forest model with mtry tuning if train_mtry == T
    tgrid <- data.frame(mtry = mtry)
    
    if (train_mtry) {
      trControl=trainControl(
        method = "repeatedcv",   
        number = K_cv,                
        repeats = N_cv,
        allowParallel = TRUE) 
    } else {
      trControl = trainControl(method = "none")
    }
    
    ############### Random forest run
    mod_RF <- train(VAR ~ ., data = train_set[ , predictors],
                    method = "rf",
                    preProcess = impute,             #impute missing met data with "impute" method
                    trControl = trControl,
                    tuneGrid = tgrid,
                    ntree = N_trees, 
                    na.action = na.pass,
                    allowParallel = TRUE,            # not sure if this is needed here because it is already specified in trControl = trainControl()
                    importance = TRUE,
                    keepX = TRUE)
    
    # save results of modeling and mtry
    if (train_mtry) {
      mtry_results = mod_RF$results
      mtry_results$Flux = Flux
      mtry_results$Year = Year
      write.csv(mtry_results, paste0("./RF_models/mtry_", Flux, "_", Year, "_", impute, "_", N_trees, "_", suffix, ".csv"), row.names = FALSE)
    }
    
    saveRDS(mod_RF, paste0("./RF_models/mod_RF_", Flux, "_", Year, "_", impute, "_", N_trees, "_", suffix, ".rds"))
    
    # generate Flux_rf predictions for the whole dataset
    result <- data.frame(Timestamp = data[data[ , "Year"] == Year, "Timestamp"],
                         Flux = Flux,
                         value = data[data[ , "Year"] == Year, Flux], # you can add datetime column here if you want to.
                         test_set = 0)
    
    # indicate if value was retained for testing, i.e. not included in training the model
    result[which(result$Timestamp %in% test_set$Timestamp), "test_set"] <- 1
    
    # predict missing Flux values for whole data set
    result$RF_pred <- predict(mod_RF, data[data[ , "Year"] == Year, ], na.action = na.pass) # Flux RF model
    result$RF_filled <- ifelse(is.na(result$value), result$RF_pred, result$value) # gap-filled column (true value when it is, gap-filled value when missing)
    result$RF_residual <- ifelse(is.na(result$value), NA, result$RF_pred - result$value) # residual (model - obs). can be used for random uncertainty analysis
    
    # write result
    write.csv(result,paste0("./RF_results/pred_RF_", Flux, "_", Year, "_", impute, "_", N_trees, "_", suffix, ".csv"), row.names = F)
    
    ## calculate error metrics
    # from test set
    test_value = result[which(result[, "test_set"] == 1), "value"]
    test_pred = result[which(result[, "test_set"] == 1), "RF_pred"]
    
    test_pred = test_pred[which(!is.na(test_value))]
    test_value = test_value[which(!is.na(test_value))]
    
    rss = sum((test_value - test_pred)^2, na.rm = T)
    tss = sum((test_value - mean(test_value, na.rm = T))^2)
    
    RMSE_test = round(RMSE(test_pred, test_value), 3)
    RSQUARE_test = round(1 - rss / tss, 3)
    
    # out-of-bag error
    RMSE_oob = round(sqrt(min(mod_RF$finalModel$mse)), 3)
    RSQUARE_oob = round(max(mod_RF$finalModel$rsq), 3)
    
    # plot results
    error_pos.x = rep(as.POSIXct(as.numeric(max(result$Timestamp)) * 0.998, origin = "1970-01-01"), times = 4)
    error_pos.y = c(max(result$RF_filled) * 0.95, max(result$RF_filled) * 0.9, max(result$RF_filled) * 0.85, max(result$RF_filled) * 0.8)
    error_labels = c(paste0("RMSE_test: ", RMSE_test), paste0("RMSE_oob: ", RMSE_oob), paste0("RSQUARE_test: ", RSQUARE_test), paste0("RSQUARE_oob: ", RSQUARE_oob))
    
    p <-  ggplot(result, aes(Timestamp, RF_filled)) +
      geom_line(aes(Timestamp, RF_filled), color = "black", na.rm = T) +
      geom_point(color = "red", na.rm = T) +
      geom_point(aes(Timestamp, value), color= "black", na.rm = T)+
      annotate("text", 
               x = error_pos.x, 
               y = error_pos.y, 
               label = error_labels,
               hjust = "left") +
      scale_y_continuous(name = Flux) +
      scale_x_datetime(date_breaks = "1 month", date_labels = "%m", name = Year) +
      theme_bw()
    
    ggsave(paste0("./RF_plots/RF_", Flux, "_", Year, "_", impute, "_", N_trees, "_", suffix, ".png"), plot = p, width = 16, height = 9, dpi = 300)
  }