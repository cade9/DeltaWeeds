## calculate_angle
# author: christiana ade
# date: 11/29/2018
# purpose: to calculate angles between bands
# inputs: three bands from original stack (b1,b2,b3) and 
# wavelengths in micrometers from AVIRIS-NG (w1,w2,w3)
# This index is used in Step2_Indices of this workflow
calculate_angle <- function(b1,b2,b3,w1,w2,w3){
  # calculate distances between vertices
  a2 = (abs(b1 - b2))^2 + (w2 - w1)^2
  d2 = (abs(b3 - b2))^2 + (w3 - w2)^2
  c2 = (abs(b1 - b3))^2 + (w3 - w1)^2
  
  # calculate angle
  angle = (acos(a2 + d2 - c2))/(2*(sqrt(a2))*(sqrt(d2)))
  
  ## test if angle is positive or negative
  # set up test
  pi = 3.14159265
  eix = w1 - w2
  eiy = b1 - b2
  ejx = w3 - w2
  ejy = b3 - b2
  test = eix*ejy - ejx*eiy
  
  # test conditions and return angle
    if (test < 0) {
      angle = pi*2 - angle
      return(angle)
    } else {
      angle
      return(angle)
    }
}


