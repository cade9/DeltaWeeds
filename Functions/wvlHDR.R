# will have to include the string detect for this 
# test it out just on an actual fightline 
# one from 2014 and one from 2017 because one is an img file and the other is 
# a bsq file
# calculate the number of layers 

avr2014File <- "Z:\\AVIRIS\\coreg_orig\\Delta_fl21\\ang_21_20171101t213835_corr_v2p13_rot_unstack_fr_2_REGaffine.bsq"
avr2014 <- stack(avr2014File)
numBands <- nlayers(avr2014)

### in the actual code this will help you figure out what the header is 
# removes .img/.tiff/.bsq and replaces with .hdr
headerName <- paste0(file_path_sans_ext(avr2014File),".hdr")
# test
hdrFN <- headerName

wvlHDR <- function(hdrFN, numBands){
  # the number of layers 
  #numBands = nlayers(avr2014) # we can potentially get this info from the band header
  # reads lines of the header
  hLines <- readLines(hdrFN)
  # determines the position of the wavelength string 
  wavPos <- grep('wavelength =', hLines)
  # subsets the lines of the header by the position of the wavelength string
  wav <- hLines[wavPos]
  
  # if the number of characters of the wavelength is less than or equal to 14 then 
  # the wavelengths were read in as individual lines and not as one entry
  if (nchar(wav) <= 14){
    # this means that each line holds at least 5 bands of information, thus the header 
    # will be re-read in 
    avrHDR <-  t(read.csv(hdrFN))
    # the start of the actual wavelength numbers is then one position over from the 
    # 'wavelength =' string
    ## wavelength number start
    waveStart <- grep('wavelength =', avrHDR)+1 
    # the end is one less than the start plus the number of bands 
    # end of wavelength index'
    waveStop <- (waveStart + numBands)-1
    # extract wavelengths from header
    wavelengths1 <- avrHDR[waveStart:waveStop]
    # remove any symbols other than numbers 
    wavelengths1 <- as.numeric(gsub("[^0-9\\.]", "", wavelengths1))
    #return(wavelengths1)
    wavelengths1
  } else{
    sepHDR <- unlist(strsplit(wav, ","))
    wavelengths1 <- as.numeric(gsub("[^0-9\\.]", "", sepHDR))
    #return(wavelengths1)
    wavelengths1
  }
}

wvl <- wvlHDR(hdrFN = headerName, numBands = nlayers(avr2014))
