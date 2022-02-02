%%
% Dec. 15, 2019, Xiaole Zhang
% draw the annual mean concentration
%%
% Dec. 29, 2019, Xiaole Zhang
% update the the code to integrate the aerosol dynamics from MAFOR model
%%
clear
% if mafor is not calculated yet, this flag can be set as 0, then the
% concentrations without the modifications from aerosol dynamics will be
% calculated. Otherwise, the flag should be set as 1 to include the Mafor
% results.
withMAFORFlag = 0;

resultsFolder = '../../Computation/';
concFolder = './concData/';
load totalPNFactors_revise_aromatics.mat
load airportGridInfo.mat
load temperatures.mat
load dispersion.mat
dirMAFOR = '../../MAFOR/';

refTemp = [0 10 20 30];
%%
classTable = importdata([resultsFolder 'meteopgt.all']);%608class' s table
meteoCategories = classTable.data;
meteoCategoryNum = size(meteoCategories, 1);

uncompressFlag = 0;
%% read grad configurations
[Gral,sourceNum] = setGralConfig();
% emission in kg, concentration in mug/m3, then convert it into kg/cm3
Gral.convertFactor = 10^-9*10^-6;
airportX = Gral.xll(airportCenterIdY, airportCenterIdX);
airportY = Gral.yll(airportCenterIdY, airportCenterIdX);
Gral.dist = sqrt((Gral.xll-airportX).^2 + (Gral.yll-airportY).^2);
%% read read meteo data
meteoData = importdata([resultsFolder 'mettimeseries.dat']);

%%
reverseStr = [];
concAll = zeros(Gral.nrows, Gral.ncols, sourceNum);
parfor meteoID = 1:length(meteoData)
    %% show information
%     percentDone = 100 * meteoID / length(meteoData);
%     msg = sprintf('Loop %d: %3.1f',meteoID, percentDone);
%     fprintf([reverseStr, msg]);
%     reverseStr = repmat(sprintf('\b'), 1, length(msg));
    
    disp(meteoID)
    factors = totalPNFactors(meteoID, :);
    if(sum(factors) == 0)
        continue
    else
        %% get specific meteo
        windDirect = meteoData(meteoID, 4);
        stableClass = meteoData(meteoID, 5);
        windSpeed = meteoData(meteoID, 3);
        dilcoef = abs(pr(meteoID));
        temperature = temp(meteoID);
        
        vtemp = temperature-refTemp;
        [vtemp, idtemp] = min(abs(vtemp));
        source = [num2str(refTemp(idtemp)) 'degree'];
        
        %% get scenario id
        scenariodId = meteoCategories(:,1)==windDirect& meteoCategories(:,2)==windSpeed&meteoCategories(:,3)==stableClass;
        if(sum(scenariodId)~=1)
            error('Scenario error')
        end
        scenariodId = find(scenariodId==1);
        
        %% get conc
        if(withMAFORFlag)
            concAll = concAll + modifiedByMAFOR(dirMAFOR, Gral, sourceNum, meteoID, windSpeed, dilcoef, scenariodId, minDistance, factors,source);
        else
            concAllTmp = getGralConc(scenariodId,sourceNum, Gral);
            for phaseId = 1:sourceNum
                concAllTmp(:,:,phaseId) = concAllTmp(:,:,phaseId)*factors(phaseId);
            end
            concAll = concAll + concAllTmp;
        end
    end
end
%%
concAll = concAll/length(meteoData);

if(withMAFORFlag)
    save annualTotalPN_mafor_revise_aromatics.mat concAll
else
    save annualTotalPN_mafor_revise_aromatics_withoutMAFOR.mat concAll
end
