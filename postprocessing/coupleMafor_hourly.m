%% Dec. 17, Xiaole Zhang
% generate the dilution and initial conc for MAFOR
% by each hour

%% Gral domain configuration
close all
clear

%% initialize parallel computing
poolobj = gcp('nocreate');
if isempty(poolobj)
    parpool(6)
end

%% load data and get the configurations of domain in GRAL
% generated by analyzeHourlyEmission_revise_aromatics.m (directory might be changed)
load totalPNFactors_revise_aromatics.mat 

% generated by analyzeHourlyEmission_revise_aromatics.m (directory might be changed)
load temperatures.mat 

% get the configurations of the domain in GRAL. If nothing was changed in GRAL, 
% the configures should be the same 
[Gral,sourceNum] = setGralConfig(); 
meteoNum = length(totalPNFactors);

% index of the center of the airport, if the domain was not changed in GRAL, the
% value should remain the same. These values will be needed in the coupling
% calculations with MAFOR later
airportCenterIdX = 983; 
airportCenterIdY = 648;

airportX = Gral.xll(airportCenterIdY, airportCenterIdX);
airportY = Gral.yll(airportCenterIdY, airportCenterIdX);
dist = sqrt((Gral.xll-airportX).^2 + (Gral.yll-airportY).^2);

% emission in kg, concentration in mug/m3, then convert it into kg/cm3
convertFactor = 10^-9*10^-6;

%% these will be needed in the coupling calculations with MAFOR later
minDistance = 1500; % meter
maxDistance = 10*1000;
intervalDistance = 100;

save airportGridInfo.mat airportCenterIdX airportCenterIdY minDistance

%% read read meteo data
resultsFolder = '../../Computation/'; % the directory of the GRAL results
meteoData = importdata([resultsFolder 'mettimeseries.dat']);
classTable = importdata([resultsFolder 'meteopgt.all']);%608class' s table
meteoCategories = classTable.data;
meteoCategoryNum = size(meteoCategories, 1);

%% generate the dilution and initial conc for MAFOR by each hour
pr = zeros(meteoNum,1);
concr = zeros(meteoNum,1);
for meteoID = 1:meteoNum
    disp(meteoID)
    factors = totalPNFactors(meteoID, :);
    if(sum(factors) == 0)
        % if no emission, just continue
        continue
    else
        %% get scenario id
        windDirect = meteoData(meteoID, 4);
        stableClass = meteoData(meteoID, 5);
        windSpeed = meteoData(meteoID, 3);
        
        %% get scenario id
        scenariodId = meteoCategories(:,1)==windDirect& meteoCategories(:,2)==windSpeed&meteoCategories(:,3)==stableClass;
        if(sum(scenariodId)~=1)
            error('Scenario error')
        end
        scenariodId = find(scenariodId==1);
        concAll = getGralConc(scenariodId, sourceNum, Gral);
        conc = zeros(size(concAll,1),size(concAll,2));
        for phaseId = 1:sourceNum
            conc = conc+concAll(:,:,phaseId)*totalPNFactors(meteoID, phaseId);
        end
        conc = conc*convertFactor;
        xt = minDistance:intervalDistance:maxDistance;
        
        
        concm = zeros(size(xt));
        
        for i=1:length(xt)
            id = dist>xt(i) & dist<=xt(i)+2*Gral.cellsize;
            concm(i) = quantile(conc(id), 0.95);
        end
        dil{meteoID}=concm;
        id = concm == 0;
        xt(id) = [];
        concm(id) = [];
        
        p = polyfit(log(xt), log(concm), 1);
        pr(meteoID) = p(1);
        concr(meteoID) = exp(polyval(p, log(xt(1))));

    end
end
%%
save('dispersion.mat', 'pr', 'concr', 'minDistance', 'maxDistance', 'temp', 'humidity', 'rain')