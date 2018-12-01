## emLibSMA
# author: christiana ade
# date: 11/29/2018
# purpose: to create a speclib class type from the hsdar package 
# this converts data from a spectral library csv file into a format 
# that can be used for spectral unmixing. 
# inputs: 1) a csv file with endmember spectra, the first column must be wavelength in nm
# the remaining columns must have the endmember material name 
# 2) a character vector  of bad band positions 
# This function is called in Step4_SAM of this workflow
#########################################################

emLibSAM <- function(specDat, badBands = "NONE"){
  if(badBands == "NONE"){
    colnames(specDat) <- specDat[1,]
    specDat <- specDat[-1,]
    return(specDat)
  } else {
    colnames(specDat) <- specDat[1,]
    specDat <- specDat[-1,]
    specDat <- specDat[,-c(badBands)]
    return(specDat)
  }
}

# ## Testing section ###
# bbFile <- "Z:/Cade/DeltaWeeds/Data/SAM/SAM_badbands_2017.csv"
# emFile <- "Z:/Cade/DeltaWeeds/Data/SAM/SAM_spec_lib.csv"
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
# dSpec <- read_csv(emFile) %>% t()
# emLibSAM(specDat = dSpec, badBands = badBands)
