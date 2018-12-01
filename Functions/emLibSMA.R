## emLibSMA
# author: christiana ade
# date: 11/29/2018
# purpose: to create a speclib class type from the hsdar package 
# this converts data from a spectral library csv file into a format 
# that can be used for spectral unmixing. 
# inputs: 1) a csv file with endmember spectra, the first column must be wavelength in nm
# the remaining columns must have the endmember material name 
# 2) a character vector  of bad band positions 
# This function is called in Step3_SMA of this workflow
#########################################################

emLibSMA <- function(specDat, badBands = "NONE"){
    if(badBands == "NONE"){
      wave <- specDat$Wavelength
      # extract the spectra and put in correct format
      mySpec <- specData %>%
        select(-Wavelength) %>%
        as.data.frame() %>%
        as.matrix()
      # remove column names
      colnames(mySpec) <- NULL
      # transpose matrix
      mySpecTrans <- t(mySpec)
      # final  spectral response function
      specIn <- speclib(mySpecTrans,wave)
      return(specIn)
    } else {
      dSpec2 <- dSpec[-badBands,]
      wave <- dSpec2$Wavelength
      # extract the spectra and put in correct format
      mySpec <- dSpec2 %>%
        select(-Wavelength) %>%
        as.data.frame() %>%
        as.matrix()
      # remove column names
      colnames(mySpec) <- NULL
      # transpose matrix
      mySpecTrans <- t(mySpec)
      # final  spectral response function
      specIn <- speclib(mySpecTrans,wave)
      return(specIn)
    }
}

# ## Testing section ###
# bbFile <- "./Data/SMA/SMA_badbands_2017.csv"
# emFile <- "./Data/SMA/SMA_spectra.csv"
# # read in bad bands csv 
# bb <- read_csv(bbFile, col_names= F) %>%
#   #select first column
#   select(names(.)[1]) 
# # select row position where bands is = 0 
# badBands <- which(bb$X1 == 0)
# 
# #### Prepare endmember spectra ####
# # read in the the different spectra required 
# # read in spectra
# dSpec <- read_csv(emFile)
# emLib(specDat = dSpec, badBands = badBands)
