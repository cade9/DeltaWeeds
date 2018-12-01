# Title: Step 4 - Spectral Angle Mapping
# Author: Christiana Ade 
# Contact: cade@ucmerced.edu, c.ade92@gmail.com
# Date Updated: 11/29/2018
# Code based on Shruti Khanna"s (shrkhanna@ucdavis.edu) IDL script
# l6_batch_avrising2017_samclass.pro located at https://github.com/shrkhanna/IDL_Delta2017
# Purpose:
# Create rule files from a spectral angle mapper classification. Note the classification 
# results are not saved, just the rule classes. 
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
bbFile <- "./Data/SAM/SAM_badbands_2017.csv"
# 4) spectra to be used for spectral angle mapping 
# see information above regarding required format
emFile <- "./Data/SAM/SAM_spec_lib.csv"

#### OUTPUT FILES ####
# 
outDir <- "./Output/SAM"
outSuf <- "_sam_rules" 

#### USER DEFINED FUNCTIONS ####
source("./Functions/wvlHDR.R")
source("./Functions/emLibSAM.R")


                    #### END USER DEFINED VARIABLES  ####
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#### packages ####
require(raster)
require(rgdal)
require(hsdar)
require(RStoolbox)
require(tidyverse)
require(tools)
require(stringr)
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
# read in spectra csv and transpose
dSpec <- read_csv(emFile) %>% t()
# convert format 
samSpec <- emLibSAM(specDat = dSpec, badBands = badBands)

#### List of AVIRIS Level-2 Products ####
avrFiles <- list.files(avrDir, pattern = imgPattern , recursive =  T, full.names = T)

#### Loop to calculate Spectral Mixture Analysis ####
for(i in 1:length(avrFiles)){
  # identify file name
  imgF <- avrFiles[i] #i 
  
  ### Modify Raster Information ###
  # read in raster  
  avrRas <- brick(imgF)
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
  # change raster name to wavelengths
  names(avrRas) <- wvl_f

  ### spectral angle mapping ###
  # angles = T returns the rule layers
  r_sam <- sam(avrRas,samSpec,angles = T)

  ### write raster out ###
  rBase <- basename(imgF) 
  outFile <- paste0(outDir,"/",rBase,outSuf)
  writeRaster(unmixImg, filename = outFile, format = "ENVI")
  
  ## remove tempfiles ##
  rm(avrRas)
  rm(r_sam)
  removeTmpFiles(h=0)
}