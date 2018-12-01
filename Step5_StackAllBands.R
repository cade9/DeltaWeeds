# Title: Step 5- Stack all bands 
# Author: Christiana Ade 
# Contact: cade@ucmerced.edu, c.ade92@gmail.com
# Date Updated: 11/29/2018
# Purpose: Stack all outputs from previous steps and mask them 
# Output: a raster stack for each flightline containing layers related to continuum removal,
# band indices, spectral angle mapping and spectral linear unmixing
# **REQUIRES** 
# All previous scripts to be finished running 
#####################################################################################
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#### USER DEFINED VARIABLES #### 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The following variables should be defined by the user each time.

#### INPUT FILES ####
# index directory
indxDir <- "./Output/Index"
# index suffix -- file names
indxSuf <- "_index$"

# sma directory
smaDir <- "./Output/SMA"
# sma suffix
smaSuf <- "sma$"

# sam directory
samDir <- "./Output/SAM"
# sam suffix
samSuf <- "sam_rules$"

# mask directory
maskDir <- "./Data/Masks"
# mask suffix
mskSuf <- "msk$"

#### OUTPUT FILES ####
outDir <- "./Output/stackAll"
outSuf <- "_stackAll" 

#### END USER DEFINED VARIABLES  ####
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## require packages
require(raster)
require(rgdal)
require(hsdar)
require(RStoolbox)
require(tidyverse)
require(tools)
require(stringr)

#### List of All Products ####
# aviris reflectance
avrFiles <- list.files(avrDir, pattern = imgPattern , recursive =  T, full.names = T)
# list index files 
indxL <- list.files(indxDir, pattern = indxSuf, full.names = T)
# list sma files 
smaL <- list.files(smaDir, pattern = smaSuf, full.names = T)
# list sam files
samL <- list.files(samDir, pattern = samSuf, full.names = T)
# list masks
mskL <- list.files(maskDir, pattern = mskSuf, full.names = T)
for(i in 1:length(indxL)){
  ### read in rasters ###
  # index raster
  indx_ras <- stack(indxL[i]) #i
  # sma raster
  sma_ras <- stack(smaL[i]) #i
  # sam raster
  sam_ras <- stack(samL[i]) #i
  
  ### stack all ### 
  stack_all <- stack(indx_ras, sma_ras , sam_ras)
  
  ### Apply mask ###
  # mask raster
  msk_ras <- raster(mskL[i]) #i 
  stack_all_masked <- stack_all * msk_ras

  ### write raster out ###
  rBase <- basename(avrList[i]) #i
  outFile <- paste0(outDir,"/",rBase,outSuf)
  writeRaster(stack_all_masked, filename = outFile, format = "ENVI")
  
  ## remove tempfiles ##
  rm(avrRas)
  rm(unmix_ras)
  rm(unmixImg)
  removeTmpFiles(h=0)
}