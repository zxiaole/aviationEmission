# Environmental impact of aviation emission                       [<img src="/img/logo.jpg" width="144" height="120">](https://ie.ifu.ethz.ch/)
[Developed by the Chair of Air Quality and Particle Technology, headed by Prof. Dr. Jing Wang, at ETH Zurich](https://ie.ifu.ethz.ch/)

First, we develop the emission inventory of particle number for the Zurich Airport. The emission inventory is based on the detailed flight trajectories provided by [OpenSky Network](https://opensky-network.org/).

Then, [GRAL/GRAMM](https://gral.tugraz.at/) model is utilized to calculate the dispersion of the emitted particles to the surrounding area. The dispersion results are modified using the [MAFOR (Multicomponent Aerosol FORmation) model](https://sourceforge.net/projects/mafor/) to consider the influence of aerosol dynamics (e.g. the coagulation with the background ambient particles). The background ambient particle number concentrations are estimated by a SVM regression model based on the long term observations from the station at Basel of the [NABEL (National Air Pollution Monitoring Network)](https://www.bafu.admin.ch/bafu/en/home/topics/air/state/data/national-air-pollution-monitoring-network--nabel-.html).  

## Emission inventory
* [getDataCompress_zurich_2019.py](/emissionInventory/preprocessing/getDataCompress_zurich_2019.py): downloads the Automatic Dependent Surveillance–Broadcast data from [OpenSky Network](https://opensky-network.org/). The data will be downloaded weekly and saved as *parquet* to reduce the size of single file.

* [emissionWeekly.py](/emissionInventory/preprocessing/emissionWeekly.py): extract the weekly data from *parquet* to *csv*, and link the *icao24* number with the aircraft type. The aircraft database [aircraftDatabase.csv](https://opensky-network.org/datasets/metadata/) should be downloaded from OpenSky Network.

* [main.m](/emissionInventory/processing/main.m): separate the whole flight trajectory into six phases (saved in [segmentation](/emissionInventory/processing/segmentation)), calculate the frequency at each grid box (saved in [spatialFrequency](/emissionInventory/processing/spatialFrequency)). The particle number emissions of non-volatile particles are estimated based on the frequency. The spatial distributions are saved as *tif*. (*One week was processed in the code as an example*)

* [analyzeHourlyEmission_revise_aromatics.m](/emissionInventory/processing/analyzeHourlyEmission_revise_aromatics.m): calculate the total particle number emission (both volatile and non-volatile particles). [airportTemp.txt](/emissionInventory/processing/airportTemp.txt) is the hourly ambient temperature and precipitation, which is used to estimate the total particle number emission. The formation of volatile particles depends on the ambient temperature. Now the airportTemp.txt contains the data for 2017, which was obtained from [NOAA](https://www.ncei.noaa.gov/maps/hourly/). The meteo data can be also obtained from other sources, e.g. [MeteoSwiss](https://gate.meteoswiss.ch/idaweb/login.do). The daily flights are also needed [dailyFlights](/emissionInventory/processing/dailyFlights). The data is used to calculate the temporal profile, which can be also estimated using the trajectory data, but it is time consuming. The data for different years can be obtained from the the annual report of Zurich Airport (e.g. [statistikbericht2020.pdf](https://www.flughafen-zuerich.ch/newsroom/download/1083723/statistikbericht2020.pdf)).

* [results_nvPM_num_emission_2018](/emissionInventory/results_nvPM_num_emission_2018/): the developed emission inventories of non-volatile particles from jet engines at the Zurich Airport for the year of 2018. Data are the number of particles emitted within each grid box during the whole year and the averaged altitude of the emissions. The shapefiles can be used by GRAMM/GRAL model.

* [regressionModelForPN.m](/regressionModelforPNEmission/regressionModelForPN.m):  Regression model for the total particle number emission index based on the data set from APEX, AAFEX I&II, [(Moore et al., 2015)](https://pubs.acs.org/doi/10.1021/ef502618w) and the LAX study [(Moore et al., 2017)](https://www.nature.com/articles/sdata2017198). The data used in the fitting were from these studies.

* Results of segmentation of flights
[<img src="/img/segmentation.png">](https://pubs.acs.org/doi/full/10.1021/acs.est.0c02249)

* Results of emission
[<img src="/img/emissions.jpeg">](https://pubs.acs.org/doi/full/10.1021/acs.est.0c02249)

## Dispersion model
The detailed introduction and tutorial for GRAL/GRAMM can be available from [GRAL/GRAMM](https://gral.tugraz.at/).
* [getData](/meteoData/getData.m): the meteorological data used for this study was from reanalysis database [NCEP GFS 0.25 Degree Global Forecast Grids Historical Archive](https://rda.ucar.edu/datasets/ds084.1/#!access). The code was used to generate the input data [metData](meteoData/metData.txt) and [Precipitation](meteoData/Precipitation.txt) needed by Gral.

## Post-processing
After the GRAL/GRAMM calculations, the results should be read and analyzed. In this study, the results of GRAL/GRAMM will be further updated by the aerosol dynamics model MAFOR. The tools and codes are in the postprocessing folder.
* [readConc](/postprocessing/readConc.m): the results of GRAL are in the compressed format. This code extracts the compressed conc data, and it only needs to be run once at the beginning for a certain case to extract the compressed data.
* [setGralConfig](/postprocessing/setGralConfig.m): (function) get the key configurations of the domain used in the Gral calculations. If the domain has been changed, the corresponding setting should be also changed in the code.
* [coupleMafor_hourly](/postprocessing/coupleMafor_hourly.m): generate the dilution and initial conc by each hour which will be utilized in the offline coupling with the aerosol dynamics model MAFOR.
* [getGralConc](/postprocessing/getGralConc.m): (function) read the conc data from the extracted files.
* [annualMeanConc_revise_aromatics](/postprocessing/annualMeanConc_revise_aromatics.m): calculate the annual mean concentrations of the total particle number concentrations induced by the aviation emissions with or without the coupling with MAFOR.
* [drawMap](/postprocessing/plotDist/drawMap.m): plot the distribution of the total particle number concentrations, which are generated by [annualMeanConc_revise_aromatics](/postprocessing/annualMeanConc_revise_aromatics.m). An example file is contained, but it only has the concentrations induced by the emissions from taxi phase. 

## Offline coupling with MAFOR
* [run.m](/MAFOR_Calc/run.m): the main file to automatically run MAFOR for all the meteorological conditions in the analysis. The generated results will be later utilized to offline couple the GRAL and MAFOR.
* [MAFOR_templates.zip](/MAFOR_Calc/MAFOR_templates.zip): The compositions of the particles are influenced by temperature. In this study, the temperature from −5 to 35°C was divided into four intervals with a step of 10°C, as shown in the Sectioin S3 in the supporting information of [(Zhang et al., 2020)](https://pubs.acs.org/doi/10.1021/acs.est.0c02249). The templates of the input files for MAFOR at these 4 temperature categories are stored in this compressed files. It should be extracted, and directly put the folders 0degree, 10degree, 20degree and 30degree in MAFOR_Calc. The MAFOR exe is also included in each folder. Maybe one has to replace it with the compiled one on their own computer. [refEimissions.mat](/MAFOR_Calc/refEimissions.mat) is used to generate the input files.
* [concBackgroundModel.mat](/MAFOR_Calc/refEimissions.mat): the trained SVM model to estimate the background particle number concentrations.
* [dispersion_example.mat](/MAFOR_Calc/dispersion_example.mat): an example for the calculation (please change the name to 'dispersion.mat 'for use). The data is generated by [coupleMafor_hourly](/postprocessing/coupleMafor_hourly.m).
* [svmTest.m](/MAFOR_Calc/svmTest.m): to train the SVM model for background particle number concentration.
* [my_sizetest_plume.m](/MAFOR_Calc/my_sizetest_plume.m): to read the size distribution from MAFOR results. 
* Spatial distribution of the surface (2 m above ground) particle number concentration attributable to the aircraft emissions with a resolution of 20 m. The background concentration has been excluded.
[<img src="/img/concentrations.jpeg">](https://pubs.acs.org/doi/full/10.1021/acs.est.0c02249)

## Reference
1. Xiaole Zhang, Matthias Karl, Luchi Zhang, Jing Wang. Influence of Aviation Emission on the Particle Number Concentration near Zurich Airport. Environmental Science & Technology 2020, 54 (22) , 14161-14171. https://doi.org/10.1021/acs.est.0c02249
2. Moore, R. H.; Shook, M. A.; Ziemba, L. D.; DiGangi, J. P.; Winstead, E. L.; Rauch, B.; Jurkat, T.; Thornhill, K. L.; Crosbie, E. C.; Robinson, C.; Shingler, T. J.; Anderson, B. E. Take-off engine particle emission indices for in-service aircraft at Los Angeles International Airport. Sci. Data 2017, 4, 170198  DOI: 10.1038/sdata.2017.198  https://www.nature.com/articles/sdata2017198
3. Moore, R. H.; Shook, M.; Beyersdorf, A.; Corr, C.; Herndon, S.; Knighton, W. B.; Miake-Lye, R.; Thornhill, K. L.; Winstead, E. L.; Yu, Z.; Ziemba, L. D.; Anderson, B. E. Influence of Jet Fuel Composition on Aircraft Engine Emissions: A Synthesis of Aerosol Emissions Data from the NASA APEX, AAFEX, and ACCESS Missions. Energy Fuels 2015, 29, 2591– 2600,  DOI: 10.1021/ef502618w https://pubs.acs.org/doi/10.1021/ef502618w
