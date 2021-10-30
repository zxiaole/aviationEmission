# Environmental impact of aviation emission
First, we develop the emission inventory of particle number for the Zurich Airport. The emission inventory is based on the detailed flight trajectories provided by [OpenSky Network](https://opensky-network.org/).

Then, [GRAL/GRAMM](https://gral.tugraz.at/) model is utilized to calculate the dispersion of the emitted particles to the surrounding area. The dispersion results are modified using the [MAFOR (Multicomponent Aerosol FORmation) model](https://sourceforge.net/projects/mafor/) to consider the influence of aerosol dynamics (e.g. the coagulation with the background ambient particles). The background ambient particle number concentrations are estimated by a SVM regression model based on the long term observations from the stattion at Basel of the [NABEL (National Air Pollution Monitoring Network)](https://www.bafu.admin.ch/bafu/en/home/topics/air/state/data/national-air-pollution-monitoring-network--nabel-.html).  

## Emission inventory
* [getDataCompress_zurich_2019.py](/emissionInventory/preprocessing/getDataCompress_zurich_2019.py): downloads the Automatic Dependent Surveillance–Broadcast data from [OpenSky Network](https://opensky-network.org/). The data will be downloaded weekly and saved as *parquet* to reduce the size of single file.

* [emissionWeekly.py](/emissionInventory/preprocessing/emissionWeekly.py): extract the weekly data from *parquet* to *csv*, and link the *icao24* number with the aircraft type. The aircraft database [aircraftDatabase.csv](https://opensky-network.org/datasets/metadata/) should be downloaded from OpenSky Network.

* [main.m](/emissionInventory/processing/main.m): separate the whole flight trajectory into six phases (saved in [segmentation](/emissionInventory/processing/segmentation)), calculate the frequency at each grid box (saved in [spatialFrequency](/emissionInventory/processing/spatialFrequency)). The particle number emissions of non-volatile particles are estimated based on the frequency. The spatial distributions are saved as *tif*. (*One week was processed in the code as an example*)

* [analyzeHourlyEmission_revise_aromatics.m](/emissionInventory/processing/analyzeHourlyEmission_revise_aromatics.m): calculate the total particle number emission (both volatile and non-volatile particles). [airportTemp.txt](/emissionInventory/processing/airportTemp.txt) is the hourly ambient temperature and precipitation, which is used to estimate the total particle number emission. The formation of volatile particles depends on the ambient temperature. Now the airportTemp.txt contains the data for 2017, which was obtained from [NOAA](https://www.ncei.noaa.gov/maps/hourly/). The meteo data can be also obtained from other sources, e.g. [MeteoSwiss](https://gate.meteoswiss.ch/idaweb/login.do). The daily flights are also needed [dailyFlights](/emissionInventory/processing/dailyFlights). The data is used to calculate the temporal profile, which can be also estimated using the trajectory data, but it is time consuming. The data for different years can be obtained from the the annual report of Zurich Airport (e.g. [statistikbericht2020.pdf](https://www.flughafen-zuerich.ch/newsroom/download/1083723/statistikbericht2020.pdf)).


## Dispersion model
(to be continued)
