## contRemoval
# author: christiana ade
# date: 11/29/2018
# purpose: returns a continuum removed spectra for certain band positions
# inputs: 1) a raster
# 2) a numeric vector of band positions to be subset
# 3) the positions to subset the wavelengths at
#########################################################

# wavelengths are actually going to get determined outside
contRemove <- function(ras, crpos, wvl){
  # subset raster by band position 
  crpos_r <- ras[[crpos1]]
  # subset wavelengths by band positon
  wvl_cr <- as.numeric(wvl[crpos1])
  # n layer of raster
  nl <- nlayers(crpos_r)
  # subset bands to start and end of cr postion
  y1 <- cr1[[1]]
  y2 <- cr1[[nl]]
  # subset wavelengths by start and end of crpostion
  x1 <- wvl_cr[[1]]
  x2 <- wvl_cr[[nl]]
  # calculate slope
  m = (r2 - r1)/(x1 - x2)
  # calculate y intercept
  b = r1 - m*x1
  # create new stack for continuum curve
  cc <- stack()
  for(i in 1:length(wvl_cr)){
    # calculate reflectance value for each wavelength on the line
    y = m*wvl_cr[i] + b
    # add new layer
    cc <- addLayer(cc, y)
  }
  # divide original spectrum by continuum curve to get
  # continuum removal 
  cr <- crpos_r/cc
  return(cr)
}


# # test raster
# # read in raster 
# crpos1 = c(114:142)
# r <- stack("Z:\\Cade\\DeltaWeeds\\Data\\testImg_46_2017_incNA")
# # wvl_cr <- wvl[crpos1]
# wvl
# 
# m3 <- contRemove(ras = r, crpos = crpos1,wvl = wvl)
