# Title: Step 7 - Batch run random forest model 
# Author: Christiana Ade 
# Contact: cade@ucmerced.edu, c.ade92@gmail.com
# Date Updated: 11/29/2018
# Code based on Shruti Khanna"s (shrkhanna@ucdavis.edu) R script
# batch_run_RandomForest.r located at https://github.com/shrkhanna/ImageAnalysis2018-master
# Purpose:
# Extract information from layer stack bands of all products and split into traning 
# and validation data for random forest classifier. 
# Requires band stack created in Step5 and field polygons
#####################################################################################
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#### USER DEFINED VARIABLES #### 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The following variables should be defined by the user each time.

#### INPUT FILES ####
# 1) working directory with the R program file
dir_progr = "X:/delta_sav/code/R/random_forest/"

# set working directory
setwd(dir_progr)

# 2) image directory
dir_image = "X:/delta_sav/raster/classification/allinputs/201711/"

# 3) training/test data directory 
# underscore "_" is fine in column names of test/train files but no dash "-" - converts to "."
dir_data  = "X:/delta_sav/raster/classification/training_test/201711/"

# 4) suffix of images to be processed (with all inputs)
imgsuf  = "all.img"

# 5) suffix of output files
outsuf  = "201711RFDeltav4"

# 6) name of training and test csv files
name_trncsv = paste(dir_data, "R_201711_trn_v4.csv", sep="")
name_tstcsv = paste(dir_data, "R_201711_tst_corr_balanced.csv",  sep="")

# 7)  name of the test data predicted class file which will be output
name_predict = paste(dir_out, "201711_Test_pred_v5.csv", sep="")
# 8) name of the file used to save importance of all variables in RF
name_impfile = paste(dir_out, "201711_Test_imp_v5.csv", sep="")

# 9)  number of information columns in test and training csv files after image bands
# it is a good idea to retain the ORIG_FID column to link back to original point or polygon
infocols = 47

# 10) maximum number of iterations in the random forest
maxiter = 3000
# minimum number of points needed to allow a seperate end node
npoints = 40

# 11) start processing at this file
stfile = 1

# 12) end processing at this file
enfile = 19

# 13) column number with target class information
classcol = 98

#### OUTPUT FILES ####
# 1) output directory for classified files and for test data
dir_out   = "X:/delta_sav/raster/classification/methods/201711/tiffs/"

#### END USER DEFINED VARIABLES  ####
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#### packages ####
require(raster)
require(rgdal)
require(tidyverse)
require(tools)
require(stringr)
require(rgeos)
require(asbio)
require(sp)
require(functional)
require(randomForest)
############################

# read training and test data
csvtrn = as.data.frame(read.csv(name_trncsv))
csvtst = as.data.frame(read.csv(name_tstcsv))

# number of columns in training data
no_col_trn = ncol(csvtrn)

# number of variables number of columns - number of information columns
no_vars = no_col_trn - infocols

# classcol column has class name. Ensure that all variable columns are read as numeric fields & species column as factor
csvtrn[, 1:no_vars] <- sapply(csvtrn[, 1:no_vars], as.numeric)
levels = sort(unique(csvtrn[, classcol]))
csvtrn[, classcol] <- factor(csvtrn[, classcol], levels=levels, ordered=FALSE)
csvtst[, 1:no_vars] <- sapply(csvtst[, 1:no_vars], as.numeric)
csvtst[, classcol] <- factor(csvtst[, classcol], levels=levels, ordered=FALSE)
# save column names in a string array
trn_colnames = colnames(csvtrn)
# save column names in a string array
tst_colnames = colnames(csvtst)

if (sum(trn_colnames != tst_colnames) > 0) { paste("Test and train file variable names do not match") }

# get list of files
img_list <- list.files(dir_image, pattern = imgsuf, full.names=TRUE)
# total number of input files in directory
no_files <- length(img_list)

if (enfile < stfile) { enfile = no_files }

# name the bands of the input image

# read metadata
img_attrib = attr(GDALinfo(img_list[1]), 'mdata')
# separate band number from band name
img_bnames = sapply(strsplit(img_attrib, '='), function(x)x[2])
# get index of band names (because 51 comes after 5)
index = gsub("Band_", "", sapply(strsplit(img_attrib, '='), function(x)x[1]))
# reorder band names by their index to them back in right order
bnames = img_bnames[order(as.integer(index))]
# total number of bands
bnumbr = length(bnames)

if (sum(trn_colnames[1:no_vars] != bnames) > 0) { paste("Train file variable names do not match image band names") }

# create formula string for Random Forest function
var_string = ""
for (i in 1:no_vars) {
  # add "+" between each band name for each variable
  # ENSURE that image band names are the same as training and test csv column names
  var_string <- paste(var_string, trn_colnames[i], "+")
}
# get length of the formula string
var_len = nchar(var_string)
# generate formula string eliminating the last "+" after the last variable name
var_for = paste(trn_colnames[classcol], " ~ ", substr(var_string, 1, var_len-2), sep="")
# assign above string as a formula
formula = as.formula(var_for)

##########################################
##  CLASSIFICATION! using Random Forest ##
##########################################

# clean up test data - purge NAN/NA/INF values
temp <- csvtrn[,1:no_vars]
csvtrn_nona <- temp[apply(temp, 1, Compose(is.finite, all)),]
csvcls_nona <- csvtrn[apply(temp, 1, Compose(is.finite, all)), classcol]

# clean up test data - purge NAN/NA/INF values
temp <- csvtst[,1:no_vars]
csvtst_nona <- temp[apply(temp, 1, Compose(is.finite, all)),]
csvtst_rslt <- csvtst[apply(temp, 1, Compose(is.finite, all)), classcol]

if (exists("RF_model_20180227_v4.RData")) {
  load("RF_model_20180227_v4.RData")
} else {
  
  # Make sure that variable names are same in csv file and the band names of the image
  # Run randomForest using all inputs: model = randomForest(species vs. list of inputs to be used, data = name of training data frame,
  # importance = report information on important variables, ntree = number of trees to allow, na.action = what to do with NAN data
  # nodesize = minimum number of members per end class)
  RF_model = randomForest(csvtrn_nona, y=csvcls_nona, importance = TRUE, ntree = maxiter, nodesize = npoints)
  #RF_model = randomForest(formula, data = csvtrn_nona, importance = TRUE, ntree = maxiter, nodesize = npoints)
  
  # save model into a file
  save(RF_model, file="RF_model_20180227_v4.RData")
}

# predict values for the test data that was extracted using the model just produced above (model)
predtst = as.data.frame(predict(RF_model, csvtst_nona))
# generate serial row names for all test data
row_names = seq(1, nrow(csvtst_nona), by=1)
# manually assign the test csv file and the predicted file the same row names to ensure correct correspondence
row.names(csvtst_nona) = row_names
row.names(predtst)     = row_names

# create the table with predicted value, dominant species name and cover; this is only when using field data
csvtst_table = data.frame(predicted=predtst, class=csvtst_rslt)

# write the above table to a file
write.csv(csvtst_table, file=name_predict)

#csvtst_table = as.data.frame(read.csv(name_predict))

# calculate Kappa using the asbio package: asbio::Kappa(as.character(prediction_name$predict, as.character(test_data$species)))
RF_kappa = asbio::Kappa(as.character(predtst[,1]),as.character(csvtst_rslt))

#RF_kappa = asbio::Kappa(as.character(csvtst_table[,1]),as.character(csvtst_table[,2]))

# print the Kappa value
RF_kappa

# print the importance file
importanceRF <- RF_model$importance
write.csv(importanceRF, file=name_impfile)

##################################################################################################
########## here start running on images ##########

# for each file in a folder, run RF_model
for (i in stfile:enfile) {
  
  # read the input image (give entire path)
  input_image = brick(img_list[i])
  # assign bandnames of image
  names(input_image) = bnames
  # give status report - which file is being processed
  paste("Processing: ", img_list[i])
  
  #input_image[is.na(input_image)] <- 0
  
  #ii.nona <- reclassify(input_image, cbind(NA, 0))
  
  # generate output filename
  # get filename after removing the input suffix
  basename = strsplit(basename(img_list[i]), '_')
  # join it with output suffix to generate correct output filename and combine with path
  # changed this code to make sure, no underscored in filename because output is tiff - doesn't like "_"
  name_out = paste(dir_out, basename[[1]][1], basename[[1]][2], outsuf, sep="")
  
  if (file.exists(name_out)) {
    paste("File already exists", i, name_out)
  } else {
    
    # predict classification image: 
    # predict(index image with all inputs, model to be used, type??, na.rm = TRUE i.e. remove NA values)
    predict_class_image = predict(input_image, RF_model, type="response", na.rm=TRUE, inf.rm=TRUE)
    
    # create classification image: 
    # writeRaster(the above predicted output, name of a file with exactly name samples, lines, etc, format, datatype, overwrite or not)
    writeRaster(predict_class_image, name_out, format='GTiff', dataType='INT1U', overwrite=TRUE, options=c("COMPRESS=NONE", "TFW=YES"))
  }
  
}

