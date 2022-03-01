%%
% Dec. 17, 2019, Xiaole Zhang
% automatically run MAFOR code
%%
clear 
clc
poolobj = gcp('nocreate');
if isempty(poolobj)
    parpool(6)
end

load dispersion.mat
load refEimissions.mat
load concBackgroundModel.mat

minimumConc = 1000;
maxDuration = 5;
maxDistanceMafor = 15000;
resultsFolder = '../GralResults/Computation/';

firstday = '201701010000';
inputFormat = 'yyyyMMddHHmm';
timeZone = 'Europe/Rome';
%% read read meteo data
meteoData = importdata([resultsFolder 'mettimeseries.dat']);
classTable = importdata([resultsFolder 'meteopgt.all']);
meteoCategories = classTable.data;
meteoCategoryNum = size(meteoCategories, 1);
%% find the scenario IDs
scenarioId = zeros(length(meteoData),1);
windDirectAll = zeros(length(meteoData),1);
stableClassAll= zeros(length(meteoData),1);
windSpeedAll = zeros(length(meteoData),1);
hourIndexAll = zeros(length(meteoData),1);
dayIndexAll = zeros(length(meteoData),1);
weekdayIndexAll = zeros(length(meteoData),1);
monthIndexAll = zeros(length(meteoData),1);

timeZero = datetime(firstday,'InputFormat',inputFormat,'TimeZone',timeZone) ;

for meteoID = 1:length(meteoData)
    currentTime = timeZero+meteoID/24;
    hourIndexAll(meteoID) = hour(currentTime);
    dayIndexAll(meteoID) = day(currentTime);
    weekdayIndexAll(meteoID) = weekday(currentTime);
    monthIndexAll(meteoID) = month(currentTime);
    if(concr(meteoID) == 0)
        continue
    else   
        windDirect = meteoData(meteoID, 4);
        stableClass = meteoData(meteoID, 5);
        windSpeed = meteoData(meteoID, 3);
        windDirectAll(meteoID) = windDirect;
        stableClassAll(meteoID) = stableClass;
        windSpeedAll(meteoID) = windSpeed;
        
        scenarioIdTmp = meteoCategories(:,1)==windDirect& meteoCategories(:,2)==windSpeed&meteoCategories(:,3)==stableClass;
        if(sum(scenarioIdTmp)~=1)
            error('Scenario error')
        end
        scenarioId(meteoID) = find(scenarioIdTmp==1);
    end
end

parfor meteoID = 1:length(meteoData)
    if(scenarioId(meteoID) == 0)
        continue
    else
        durationMafor = min(maxDuration, maxDistanceMafor/windSpeedAll(meteoID)/3600);
        durationMafor = ceil(durationMafor);
        hourMafor = hourIndexAll(meteoID);
        dayMafor = monthIndexAll(meteoID);
        monthMafor = monthIndexAll(meteoID);
        u10Mafor = windSpeedAll(meteoID);
        dilcoefMafor = -1*pr(meteoID);
        concInitMafor = concr(meteoID);
        distanceInitMafor = minDistance;
        rainMafor = rain(meteoID);
        temperatureMafor = temp(meteoID);
        humidityMafor = humidity(meteoID);
        
        X = [hourMafor,weekdayIndexAll(meteoID),temperatureMafor,humidityMafor, u10Mafor, rainMafor];
        concBackground =  predict(MdlStd, X);
        
        
        maforCaseRun(meteoID, refEmissions, refBackground, durationMafor, hourMafor, dayMafor, monthMafor, ...
            u10Mafor, dilcoefMafor, concInitMafor, concBackground, distanceInitMafor, rainMafor, temperatureMafor, humidityMafor)
    end
end
%%






