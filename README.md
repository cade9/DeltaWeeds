# DeltaWeeds

This repository catelogs the workflow needed to process AVIRIS-NG hyperspectral imagery for the purpose of creating high spatial resolution vegetation maps of the Sacramento-San Joaquin Delta. 

It has seven steps: 
1) Continuum Removal - AVIRIS surface reflectance required as input.
2) Index Calculation - AVIRIS surface reflectance and continuum removal required as input.
3) Spectral Mixture Analsys (SMA) - two .csv and reflectance images required as input.
4) Spectral Angle Mapping (SAM) - two .csv and reflectance images required as input.
5) Image Stacking - output of the above scripts required as input.
6) Extract Polygon Data - image stack and field data polygons required as input.
7) Apply and Validate Random Forest Algorithm - surface reflectance images and csv outputs from extract polygons required as input. 
