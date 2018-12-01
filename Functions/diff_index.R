# author: christiana ade
# date: 11/29/2018
# purpose: simple normalized spectral index
# Inputs:
# takes two inputs band 1 and band 2
# band 1 will be subtracted from band 2 
# This index is used in Step2_Indices of this workflow
diff_index <- function(b1,b2){
  index <- (b2 - b1)/(b2+b1)
  
}
