%%
% Dec. 17, 2019, Xiaole Zhang
% automatically run MAFOR code
%%
clear all
clc
load dispersion.mat
load totalPNFactors.mat
minimumConc = 1000;
resultsFolder = '../../GralResults/Computation/';
%% read read meteo data
meteoData = importdata([resultsFolder 'mettimeseries.dat']);
windDirect = meteoData(:,4);
stableClass = meteoData(:, 5);
windSpeed = meteoData(:, 3);

classTable = importdata([resultsFolder 'meteopgt.all']);
meteoCategories = classTable.data;
meteoCategoryNum = size(meteoCategories, 1);
%%
reverseStr = [];
for scenarioId=1:meteoCategoryNum
    %% show information
    percentDone = 100 * scenarioId / length(meteoData);
    msg = sprintf('Loop %d: %3.1f',scenarioId, percentDone);
    fprintf([reverseStr, msg]);
    reverseStr = repmat(sprintf('\b'), 1, length(msg));
    
    meteoId=meteoCategories(scenarioId,1)==windDirect&meteoCategories(scenarioId,2)==windSpeed&meteoCategories(scenarioId,3)==stableClass;
        if(sum(meteoId)~=1)
            error('Scenario error')
        end
end


%%
[Gral,sourceNum] = setGralConfig();
scenarioNum = 827;

airportCenterIdX = 983;
airportCenterIdY = 648;

airportX = Gral.xll(airportCenterIdY, airportCenterIdX);
airportY = Gral.yll(airportCenterIdY, airportCenterIdX);
dist = sqrt((Gral.xll-airportX).^2 + (Gral.yll-airportY).^2);


datatmp = importdata('meteopgt.txt');

u10All = unique(datatmp(:,2));
u10All = u10All';

%%
emissionFactorAll = [0.05 0.2 0.3 0.4 0.8 0.9 1];
defaultConc =  1.276862765040000e+06;
%% get relations between particle conc, speed and dilcoef

%%

source = 'test';
% fileID = fopen('./traffic/ingeod.dat','r');
% tline = fgetl(fileID);
% vars = regexp(tline, '[ \t]', 'split' );
% fclose(fileID);
for modelType = 1
    count = 0;
    for dilcoef = dilcoefAll
        for u10 = u10All
            %% get the initial baseline conc according to dilcoef and u10
            categoryConcEst = find(u10All == u10);
            concEstCoef = pConcStabAll(categoryConcEst,:);
            concBase = polyval(concEstCoef, -1*dilcoef);
            concBase = max(concBase, minimumConc);
            baseFactor = concBase/defaultConc;
            
            %% revise the baseline initial conc by 7 levels and 2 models
            for emissionFactor = emissionFactorAll
                disp(['current:' num2str(count) '_model'])
                
                %% copy files
                if(modelType == 1)
                    destination = [source '_linear_' 'Dilu' num2str(dilcoef) '_u10_' num2str(u10) '_emi_' num2str(emissionFactor)];
                    mkdir(destination);
                else
                    destination = [source '_sdata_''Dilu' num2str(dilcoef) '_u10_' num2str(u10) '_emi_' num2str(emissionFactor)];
                    mkdir(destination);
                end
                
                %% revise ingeod.dat: speed, dilution
                fid = fopen('./test/ingeod.dat','r');
                fod = fopen(['./' destination '/ingeod.dat'],'w');
                for lineN = 1:2
                    strtmp = fgetl(fid);
                    vars = regexp(strtmp, '\s+|\t', 'split' );
                    vars{25} = num2str(dilcoef);
                    vars{12} = num2str(u10);
                    strtmp = [];
                    for varsN = 1:25
                        strtmp = [strtmp vars{varsN} '\t'];
                    end
                    fprintf(fod, [strtmp '\n']);
                end
                fclose(fod);
                fclose(fid);
                
                %% revise the inaero.dat
                fod = fopen(['./' destination '/inaero.dat'], 'w');
                
                if(modelType == 1)
                    % for linear model
                    fid = fopen('./test/inaero_linearModel.dat');
                elseif(modelType == 2)
                    % for sdata model
                    fid = fopen('./test/inaero_sData.dat');
                else
                    error('So many modeltypes')
                end
                
                
                for lineN = 1:5
                    strtmp = fgetl(fid);
                    if(lineN>1)
                        vars = regexp(strtmp, '\s+|\t', 'split' );
                        strtmp = [];
                        for varsN = 1:13
                            if(varsN>=5)
                                vars{varsN} = num2str(str2double(vars{varsN})*emissionFactor*baseFactor);
                            end
                            strtmp = [strtmp vars{varsN} '\t'];
                        end
                        
                    end
                    fprintf(fod, [strtmp '\n']);
                end
                
                fclose(fid);
                fclose(fod);
                %% copy the sensitive.dat
                copyfile('test/sensitiv.dat', destination);
                %% copy the dispers.dat
                copyfile('test/dispers.dat', destination);
                %% copy the inchem.dat
                copyfile('test/inchem.dat', destination);
                %% copy the organic.dat
                copyfile('test/organic.dat', destination);
                %% copy the inbgair.dat
                copyfile('test/inbgair.dat', destination);
                %% copy the MAFOR_v19_ubuntu64.exe
                copyfile('test/MAFOR_v19_ubuntu64.exe', destination);
                
                %% run the program
                cd(destination)
                tic
                unix('./MAFOR_v19_ubuntu64.exe >& log')
                tc = toc;
                disp(tc)
                
                delete 'MAFOR_v19_ubuntu64.exe'
                cd('..')
                count = count + 1;
            end 
        end
    end
    
end

%%






