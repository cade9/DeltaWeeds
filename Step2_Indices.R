# Title: Step 2- Index Calculation
# Author: Christiana Ade 
# Contact: cade@ucmerced.edu, c.ade92@gmail.com
# Date Updated: 11/29/2018
# Code based on Shruti Khanna"s (shrkhanna@ucdavis.edu) IDL script
# l6_batch_avrising2017_index.pro located at https://github.com/shrkhanna/IDL_Delta2017
# Purpose:
# Opens images created by the continuum removal script (Step1_contRemoval) extracts 
# minima bands (outlined below), calculates a suite of indices, and extracts
# key bands in the blue,green,red,nir,and swir part of the electromagnetic spectrum.
# It outputs in stack of all relevent AVIRIS bands, indices, and CR minimas in a single file.
#####################################################################################
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  #### USER DEFINED VARIABLES #### 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The following variables should be defined by the user each time. 

#### INPUT FILES ####
# 1) Aviris surface reflectance image directory
avrDir <- "Z:\\AVIRIS\\coreg_orig"
# 2) Search pattern 
imgPattern <- "2017.*bsq$"
# 3) location of continuum removal images 
crDir <-""
# 3)
outsuf = '_indx.img'            # output images suffix
crsuf1 = '_crw1.img'            # suffix for continuum removal at 980 nm  (water)
crsuf2 = '_crw2.img'            # suffix for continuum removal at 1200 nm (water)
crsuf3 = '_crc.img'             # suffix for continuum removal at 2300 nm (cellulose)
# 3) source for diff_index function
source("./Functions/diff_index.R")
# 4) source for calculate_angle.R
source("./Functions/calculate_angle.R")

## Option change the temp output directory 
# tempDir = ""
#rasterOptions(tmpdir = tempDir )

#### OUTPUT FILES ####


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
### Inputs:
# list of aviris files 
avrFiles <- list.files(avrDir, pattern = imgPattern , recursive =  T, full.names = T)
# list crw1
crw1L <- list.files(crDir, pattern = crsuf1, recursive = T, full.names = T)
# list crw2
crw2L <- list.files(crDir, pattern = crsuf2, recurisve = T, full.names = T)
# list crw3
crcL <- list.files(crDir, pattern = crsuf3, recursive = T, full.names = T)


#### Bands Selection #### 
# Band positions used in angle calculations 
posB = 14 # blue position
posG = 35 # green position
posR = 60 # red position
posNIR1 = 85 # NIR1 position 
posNIR2 = 140 # NIR2 position
poSWIR1 = 259 # SWIR1 position
poSWIR2 = 367 # SWIR2 position

## all relevant band positions for indexes calculated below
# length(pos) = 24
pos = c(14,  27,  31,  35,  36,  38,  43,  56,  60,  63,  64,  
        66,  74,  85, 108, 120, 135, 140, 163, 184, 259, 334, 340, 367)
# ~! possibly in the future will be changed to a function
posext <- c(20,102)

for (i in 1:length(avrFiles)){
  ## Specify file name ##
  avrFN <- "Z:\\Cade\\DeltaWeeds\\Data\\testImg_46_2017_incNA"
  
  ## read in raster at traditional index ##
  avrImg <- stack(avrFN)[[pos]]
  
  ## read in raster at positions for NDAVI and WAVI ##
  avrExt <- stack(avrFN)[[posext]]
  
  ## Extract Wavelengths from header information ##
  avrWl <- waveHdr(avrImg)
  # subset based on band positions
  
  ## Define angle postions ##
  # read in and convert to micrometers
  anglew1 = #empty data frame
  anglew1[1] = avrWl[posG]/1000       # Green Wavelength
  anglewl[2] = avrWl[posR]/1000       # Red   wavelength
  anglewl[3] = avrWl[posNIR1]/1000    # NIR   wavelength
  anglewl[4] = avrWl[poSWIR1]/1000    # SWIR1 wavelength
  anglewl[5] = avrWl[poSWIR2]/1000    # SWIR2 wavelength
  
  
  #create blank raster stack
  r <- stack()

  # NDVI from bands (677) and (1077) (R & NIR) 
  r = addLayer(r,diff_index(avrImg[[18]], avrImg[[9]]))
  
  # gNDVI (green ndvi) from bands (557) and (677) (G & R) band 
  r = addLayer(r,diff_index(avrImg[[5]], avrImg[[9]]))
  
  # R-G Ratio from bands (557) and (677) (G & R)
  r = addLayer(r,avrImg[[9]]/avrImg[[5]])
  
  # NDWI from bands, (1077) and (1674) (NIR & SWIR1)
  r = addLayer(r,diff_index(avrImg[[18]], avrImg[[21]]))
  
  # NDWI2 from bands, (1077) and (2214) (NIR & SWIR2)
  r = addLayer(r,diff_index(avrImg[[18]], avrImg[[24]]))
  
  # LPI (Leaf Pigment Index) from bands, (557) and (1077) (G & NIR)
  r = addLayer(r,(1/(10*avrImg[[5]])) - (1/10*avrImg[[18]]))
  
  # angle at NIR for bands, (677), (1077) and (1674) (R, NIR, SWIR1)
  r = addLayer(r,calculate_angle(avrImg[[9]], avrImg[[18]], avrImg[[21]], 
                                 anglewl[[2]], anglewl[[3]], anglewl[[4]]))
  
  # angle at Red for bands, (557), (677) and (1077) (G, R, NIR)
  r = addLayer(r,calculate_angle(avrImg[[5]], avrImg[[9]], avrImg[[18]], 
                                 anglewl[[1]], anglewl[[2]], anglewl[[3]]))
  
  # angle at SWIR1 for bands, (1077) and (1674) and (2214) (NIR, SWIR1, SWIR2)
  r = addLayer(r,calculate_angle(avrImg[[18]], avrImg[[21]], avrImg[[24]], 
                                 anglewl[[3]], anglewl[[4]], anglewl[[5]]))
  
  # mNDVI (red edge ndvi) from bands, (692) and (747)
  r = addLayer(r, diff_index(avrImg[[13]], avrImg[[10]]))
  
  # GI (green index) from bands, (557)and (677) (G & R)
  r = addLayer(r, diff_index(avrImg[[5]], avrImg[[9]]))
  
  # PRI from bands, (531) and (567)
  r = addLayer(r, diff_index(avrImg[[3]], avrImg[[6]]))
  
  # CAI between bands (2049), (2079) and (2214)
  r = addLayer(r, (0.5*(avrImg[[22]] + avrImg[[24]])) - avrImg[[23]])
  
  # WADI (Water Absorption Difference Index) between bands (1077) and (1298)
  r = addLayer(r, diff_index(avrImg[[18]], avrImg[[20]]))
  
  # Absorption depth for water at 980 nm (ADW1) between bands (917), (977) and (1052)
  r = addLayer(r, 0.5*(avrImg[[15]] + avrImg[[17]]) - avrImg[[16]])
  
  # Absorption depth for water at 1160 nm (ADW2) between bands (1077), (1193) and (1298)
  r = addLayer(r, (0.5*(avrImg[[18]] + avrImg[[20]])) - avrImg[[19]])
  
  # Structure Insensitive Pigment index (SIPI) for bands (446), (677), (802) (B, R, NIR)
  r = addLayer(r, (avrImg[[14]] - avrImg[[1]])/(avrImg[[14]] - avrImg[[9]]))
  
  # Carotenoid Reflectance Index (CRI_550) for bands (512) and (552)
  r = addLayer(r, (1/(10*avrImg[[2]])) - (1/(10*avrImg[[4]])))
  
  # Carotenoid Reflectance Index (CRI_700) for bands (512) and (707)
  r = addLayer(r, (1/(10*avrImg[[2]]) - (1/(10*avrImg[[12]]))))
  
  # Anthocyanin Reflectance Index (ARI) for bands (552) and (707)
  r = addLayer(r, (1/(10*avrImg[[4]]) - (1/(10*avrImg[[12]]))))
  
  # Blue band
  r = addLayer(r, avrImg[[1]])
  
  # Green band
  r = addLayer(r, avrImg[[4]])
  
  # Red band
  r = addLayer(r, avrImg[[9]])
  
  # NIR band
  r = addLayer(r, avrImg[[18]])
  
  # SWIR1 band
  r = addLayer(r, avrImg[[21]])
  
  # SWIR2 band
  r = addLayer(r, avrImg[[24]])
  #########################################
  # Continuum Removal minima for Water 1
  r = addLayer(r, crmin1[[i]])
  
  # Continuum Removal minima for Water 2
  r = addLayer(r, crmin2[[i]])
  
  # Continuum Removal minima for Cellulose
  r = addLayer(r, crmin3[[i]])
  #################################
  
  # two SAV indices, NDAVI and WAVI
  r = addLayer(r,diff_index(avrExt[[2]], avrExt[[1]]))
  r = addLayer(r,((avrExt[[2]] - avrExt[[1]])/(avrExt[[2]] + avrExt[[1]] + 0.5))*(1.5))
  
  
  
  ## perhaps put an if statement here that if the nlayers of r does not equal something 

  names(r) <- c( "NDVI", "gNDVI", "RGRatio", "NDWI", "NDWI2", "LPI", "ANIR", "ARed", "ASWIR1", "mNDVI",
                 "GI", "PRI", "CAI", "WADI", "ADW1", "ADW2", "SIPI", "CRI550", "CRI700", "ARI", "Blue", 
                 "Green", "Red", "NIR", "SWIR1", "SWIR2", "CRWat1", "CRWat2", "CRCell", "NDAVI", "WAVI")
  
  writeRaster()
}


