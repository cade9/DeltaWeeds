# Title: Step 3- Spectral Mixture Analysis
# Author: Christiana Ade 
# Contact: cade@ucmerced.edu, c.ade92@gmail.com
# Date Updated: 11/29/2018
# Code based on Shruti Khanna"s (shrkhanna@ucdavis.edu) IDL script
# l6_batch_avrising2017_lsu.pro located at https://github.com/shrkhanna/IDL_Delta2017
# Purpose:
# Calculate spectral unmixing using spectra of six endmembers - emergent vegetation (emr), 
# non-photosynthetic vegetation (npv), submerged aquatic vegetation (sav), soil, vegetation,
# and water. 
# Output: a raster stack in .envi format nlayers - 1 is the % of each endmember and the final
# layer is RMSE
# **REQUIRES** 
# 1) CSV file with spectral endmembers. Column 1 should be Wavelength (info in nm), remaining
# columns should have the title of each endmember. ncols = nendmembers + 1
# 2) bad bands csv file. Column one should have no header. Column should be only 0s and 1s
# 1s correspond to a "good" band position and 0s correspond to a "bad" band positions
# nrows = number of bands in imagery
#####################################################################################
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  #### USER DEFINED VARIABLES #### 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The following variables should be defined by the user each time.

#### INPUT FILES ####
# 1) Aviris surface reflectance image directory
avrDir <- "Z:\\AVIRIS\\coreg_orig"
# 2) Search pattern - the pattern used to select the correct aviris files
# usually the suffix 
imgPattern <- "2017.*bsq$"
# 3) bad band csv - bands to be excluded from analysis
# see information above regarding required format
bbFile <- "./Data/SMA/SMA_badbands_2017.csv"
# 4) spectra to be used for linear spectral unmixing 
# see information above regarding required format
emFileSMA <- "./Data/SMA/SMA_spectra.csv"

#### OUTPUT FILES ####
outDir <- "./Output/SMA"
outSuf <- "_sma" 

#### USER DEFINED FUNCTIONS ####
source("./Functions/wvlHDR.R")
source("./Functions/emLibSMA.R")


                       #### END USER DEFINED VARIABLES  ####
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#### packages ####
require(tools)
require(hsdar)
require(raster)
############################
######## Inputs: ######
#### Determine bad band positions ####
# read in bad bands csv 
bb <- read_csv(bbFile, col_names= F) %>%
  #select first column
  select(names(.)[1]) 
# select row position where bands is = 0 
badBands <- which(bb$X1 == 0)

#### Prepare endmember spectra ####
# read in spectra csv
dSpec <- read_csv(emFileSMA)
# names of spectra
specNames <- names(dSpec)[-1]
# convert to hsdar::specLib
smaSpec <- emLibSMA(specDat = dSpec, badBands = badBands)

#### List of AVIRIS Level-2 Products ####
avrFiles <- list.files(avrDir, pattern = imgPattern , recursive =  T, full.names = T)

#### Loop to calculate Spectral Mixture Analysis ####
for(i in 1:length(avrFiles)){
  # identify file name
  imgF <- avrFiles[i] #i 
  
  ### Convert Raster Data to Speclib ###
  # read in raster and divide reflectances by 1000 
  avrRas <- brick(imgF)/1000
  # determine number of bands 
  numBands <- nlayers(avrRas)
  # locate header file name and file path
  headerName <- paste0(file_path_sans_ext(imgF),".hdr")
  # determine wavelengths of the raster data
  wvl <- wvlHeader(hdrFN = headerName, numBands = numBands)
  # filter wvl for bad bands
  wvl_f <- wvl[-badBands]
  # drop the layers of the raster brick that correspond to the bad bands
  avrRas <- dropLayer(avrRas,badBands)
  # set NA values 
  NAvalue(avrRas) <- -9999
  # raster convert to speclib
  rasLib <- speclib(avrRas,wvl_f)
  
  ### spectral linear unmixing ###
  unmix_ras <- unmix(rasLib, smaSpec)
  # output raster
  unmixImg <- unmix_ras@spectra@spectra_ra
  # reset NA values 
  unmixImg[is.na(unmixImg)] <- -9999
  # rename bands of out raster
  names(unmixImg) <- c(specNames, "RMSE")

  ### write raster out ###
  rBase <- basename(imgF) 
  outFile <- paste0(outDir,"/",rBase,outSuf)
  writeRaster(unmixImg, filename = outFile, format = "ENVI")
  
  ## remove tempfiles ##
  rm(avrRas)
  rm(unmix_ras)
  rm(unmixImg)
  removeTmpFiles(h=0)
}