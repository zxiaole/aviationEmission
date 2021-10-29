# Environmental impact of aviation emission
First, we develop the emission inventory of particle number for the Zurich Airport. The emission inventory is based on the detailed flight trajectories provided by [OpenSky Network](https://opensky-network.org/).

Then, [GRAL/GRAMM](https://gral.tugraz.at/) model is utilized to calculate the dispersion of the emitted particles to the surrounding area. The dispersion results are modified using the [MAFOR (Multicomponent Aerosol FORmation) model](https://sourceforge.net/projects/mafor/) to consider the influence of aerosol dynamics (e.g. the coagulation with the background ambient particles). The background ambient particle number concentrations are estimated by a SVM regression model based on the long term observations from the stattion at Basel of the [NABEL (National Air Pollution Monitoring Network)](https://www.bafu.admin.ch/bafu/en/home/topics/air/state/data/national-air-pollution-monitoring-network--nabel-.html).  

## Emission inventory
