# Title: Step 1- Continuum removal 
# Author: Christiana Ade 
# Contact: cade@ucmerced.edu, c.ade92@gmail.com
# Date Updated: 11/29/2018
# Code based on Shruti Khanna"s (shrkhanna@ucdavis.edu) IDL script
# l6_batch_avrising2017_lcr.pro located at https://github.com/shrkhanna/IDL_Delta2017
# Purpose:
# Create continuum removed rasters for three band positions 
# **REQUIRES** 
# 1) list of AVIRIS imagery and band positions of continuum removal 
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
# 3) Three continuum removal postions 
crpos1 = c(114:142) # 907-1047 nm
crpos2 = c(151:181) # 1073-1293 nm
crpos3 = c(333:368) # 2209-2384 nm

#### OUTPUT FILES ####
outDir <- "./Output/cr"
crsuf1 = '_crw1'            # suffix for continuum removal at 980 nm  (water)
crsuf2 = '_crw2'            # suffix for continuum removal at 1200 nm (water)
crsuf3 = '_crc'             # suffix for continuum removal at 2300 nm (cellulose)

#### USER DEFINED FUNCTIONS ####
source("./Functions/wvlHDR.R")
source("./Functions/contRemoval.R")
#### END USER DEFINED VARIABLES  ####
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## require packages
require(raster)
require(rgdal)
require(hsdar)
require(RStoolbox)
require(tidyverse)
require(tools)

######## Inputs: ######
#### List of AVIRIS Level-2 Products ####
avrFiles <- list.files(avrDir, pattern = imgPattern , recursive =  T, full.names = T)

#### Loop to calculate Spectral Mixture Analysis ####
for(i in 1:length(avrFiles)){
  # identify file name
  imgF <- avrFiles[i] #i 
  
  ### Read in Raster and Extract Wavelength information ###
  # read in raster  
  avrRas <- brick(imgF)
  # determine number of bands 
  numBands <- nlayers(avrRas)
  # locate header file name and file path
  headerName <- paste0(file_path_sans_ext(imgF),".hdr")
  # determine wavelengths of the raster data
  wvl <- as.numeric(wvlHeader(hdrFN = headerName, numBands = numBands))
  # set NA values 
  NAvalue(avrRas) <- -9999
  # change raster name to wavelengths
  names(avrRas) <- wvl
  
  ### Calculate 3 continuum removed Spectra Raster Information ###
  cr1 <- contRemove(ras = avrRas, crpos = crpos1, wvl = wvl)
  cr2 <- contRemove(ras = avrRas, crpos = crpos2, wvl = wvl)
  cr3 <- contRemove(ras = avrRas, crpos = crpos2, wvl = wvl)
  
  ### Determine three out names ###
  rBase <- basename(imgF) 
  out_cr1 <- paste0(outDir,"/",rBase,crsuf1)
  out_cr2 <- paste0(outDir,"/",rBase,crsuf2)
  out_cr3 <- paste0(outDir,"/",rBase,crsuf3)
  
  ### Write three rasters ### 
  writeRaster(cr1, filename = out_cr1, format = "ENVI")
  writeRaster(cr2, filename = out_cr2, format = "ENVI")
  writeRaster(cr3, filename = out_cr3, format = "ENVI")
  ## remove tempfiles ##
  rm(avrRas)
  rm(cr1)
  rm(cr2)
  rm(cr3)
  removeTmpFiles(h=0)
}

      