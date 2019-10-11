SL2P_L8_OLI_v01
----------
----------

SL2P processor [1} was adapted for adapted for estimating leaf area index (LAI), fraction canopy cover (FCOVER), fraction of absorbed photosynthetically active radiation (FAPAR), canopy chlorophyll content (CCC) and canopy water content (CWC)from Landsat-8/OLI surface reflectance data. Quality indicators (flags maps) are computed for each product.

The algorithm generates a water_shadow_cloud_snow (WSCS) mask. 

Content:
--------
- README.md: the actual document.
- SL2P_L8_OLI_v_01.m : the main code.
- tools: containg the trained NNET used for estimating vegetation biophysical variables from L8/OLI surface reflectance data as well as other auxilary code pieces.

Inputs:
-------
- surface reflectance maps: band3, band4, band5, band6, band7.
- solar_zenith map
- sensor_zenith map
- solar_azimuth map
- sensor_azimuth map 

- pixel_qa map

Input data could be obtained from : https://espa.cr.usgs.gov/

Samples of input data are available in: https://drive.google.com/drive/folders/1iO0L4uTkF0vOy0VFM0ZDgd6vpfzbwv7y

Input maps should be provided in separalte .tif files at 30m spatial resolution.

Outputs:
--------
- lai, fcover, fapar, lai_cw (CCC), lai_cab (CCC) maps.
- lai_flags, fcover_flags, fapar_flags, lai_cw_flags,        lai_cab_flags maps.
- water_shadow_cloud_snow mask: WSCS_mask  
    

Use:
--------
SL2P_L8_OLI_v_01(['.\Samples_S2L2A_data\'], 'S2A_MSIL2A_20171026T110131_N0206_R094_T30SWJ_20171026T144303')


References:
-----------
[1] Weiss, M.; Baret, F. S2ToolBox level 2 products, version 1.1. 2016. [https://step.esa.int/docs/extra/ATBD_S2ToolBox_L2B_V1.1.pdf].
 

 

