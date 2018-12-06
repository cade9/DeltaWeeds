# Title: Step 6 - Extract data from stack all for field polygons 
# Author: Christiana Ade 
# Contact: cade@ucmerced.edu, c.ade92@gmail.com
# Date Updated: 11/29/2018
# Code based on Shruti Khanna"s (shrkhanna@ucdavis.edu) R script
# extact_polygon_data_from_index_images.r located at https://github.com/shrkhanna/ImageAnalysis2018-master
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
dir_progr = "X:/delta_sav/code/R/extract_data/"
# set working directory
setwd(dir_progr)
# 2) image directory from where data will be extracted
dir_image = "X:/delta_sav/raster/classification/allinputs/201711/"
# 3) training/test data directory without the last slash front slash
dir_shape = "X:/delta_sav/vector/field_data/2017/data4"
# 4) suffix of images to be processed
imgsuf  = "_all.img"
# 5) name of shapefile without the .shp extension
name_shape  = "201711_GPSPoly_tst_all"
# 6) name of training csv files
name_csv = paste(dir_out, "R_201711_tst_corr.csv", sep="")
# 7) if there is a mask_value to be ignored in the image files
mskval = 0
# 8) begin processing at this file
stfile = 1
# 9) end processing at this file
enfile = 0

#### OUTPUT FILES ####
# output directory for the csv file
dir_out   = "X:/delta_sav/raster/classification/training_test/201711/"


#### END USER DEFINED VARIABLES  ####
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#### packages ####
require(raster)
require(rgdal)
require(tidyverse)
require(tools)
require(stringr)
require(rgeos)
############################

# get list of files
img_list <- list.files(dir_image, pattern = imgsuf, full.names=TRUE)
img_list <- subset(img_list, !grepl(".enp", img_list))
no_files <- length(img_list)

if (enfile < stfile) { enfile = no_files }

#enfile = 32

# read the data shapefile: readOGR(dsn = destination folder, layer = filename)
vector_shape <- readOGR(dsn = dir_shape, layer = name_shape)

# get names of field data columns
fields <- colnames(vector_shape@data)

# read metadata
img_attrib = unique(attr(GDALinfo(img_list[1]), 'mdata'))
# separate band number from band name
img_bnames = sapply(strsplit(img_attrib, '='), function(x)x[2])
# get index of band names (because 51 comes after 5)
index = gsub("Band_", "", sapply(strsplit(img_attrib, '='), function(x)x[1]))
# reorder band names by their index to them back in right order
bnames = img_bnames[order(as.integer(index))]
# get number of bands in image
bnumbr = length(bnames)

first = 0

for (i in stfile:enfile) {

  # read the input image (give entire path)
  input_image = brick(img_list[i])
  # intialize number of polygons to 0
  no_poly_trn = 0
  
  # get subset of points that intersect with the image i
  vint = raster::intersect(vector_shape, as(extent(input_image), 'SpatialPolygons'))
  
  # test if any vector data intersected with the image i
  if (!is.null(vint)) {
    if (first == 0) {
      # first file found where vector data intersected with image
      # turn flag "ON" so that master array can be initialized
      first = i
    }
    # number of polygons intersecting with image i
    no_poly_trn = nrow(vint)
  }
  
  # if more than 1 polygon intersected with image i, then ...
  if (!is.null(vint)) {
    
    # Extract training data as a data frame
    extrn = raster::extract(input_image, vint, cellnumbers=TRUE)
    # Make a vector of no. of pixels extracted per polygon
    freq = t(as.data.frame(lapply(extrn, length)))
    # divide by number of columns to get number of rows
    freq = freq/(bnumbr+1)
    # Total number of pixels extracted from the image
    total = sum(freq)
    
    # convert large list into a single list
    subtrn = NULL
    for (j in 1:no_poly_trn) {
      subtrn = rbind(subtrn, as.data.frame(extrn[[j]]))
    }    

    # add columns to vector data containing number of pixles in each polygon
    vint_freq = as.data.frame(cbind(vint@data, freq))
    # add name of column containing the pixel count
    names(vint_freq) = c(fields, "freq")
    # make this new vector data frame have the same number of rows as the extracted data (duplicate rows for no. of pixels)
    vector = vint_freq[rep(row.names(vint_freq), vint_freq$freq),]
    
    # bind extracted data to the vector data which are now equal length
    subtrnb = cbind(subtrn, vector)
    # give correct column headings to the composite file
    names(subtrnb) = c("FID", bnames, fields, "freq")
    # remove all "0" rows from result data frame
    subtrnb = subset(subtrnb, !((subtrnb[[2]] == mskval) & (subtrnb[[3]] == mskval) & (subtrnb[[4]] == mskval) & (subtrnb[[5]] == mskval)))

    # if this is the first image where vector data intersected, begin master vector
    if (i == first) {
  
      # initialize the master data frames for test and training
      mastrn <- subtrnb
  
      # add vector data to the band names list
      names(mastrn) = c("FID", bnames, fields, "freq")
  
    } else {
      
      # prevent duplication of data where flightlines overlap
      # remove all fids in following file which have been extracted before
      subtrnb = subtrnb[!(subtrnb$ORIG_FID %in% mastrn$ORIG_FID),]
      # append new extracted data to existing data (previously extracted)
      mastrn <- rbind(mastrn, subtrnb)
    }
    # status report
    print(i)

  } # end if no polygons condition
}  # end i for loop


# write table to csv
write.csv(mastrn, file=name_csv)
