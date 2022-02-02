%% extract the compressed conc data
% Dec. 12, 2019, Xiaole Zhang
% extract the compressed conc data
% this code only needs to be run once for a case to extract the compressed
% data

%% key configurations
% the directory of the GRAL results
resultsFolder = '../../Computation/';

% the directory to save the extracted files
concFolder = './concData/';

classTable = importdata([resultsFolder 'meteopgt.all']);%608class' s table
meteoCategories = classTable.data;
meteoCategoryNum = size(meteoCategories, 1);

uncompressFlag = 1;

% emission in kg, concentration in mug/m3, then convert it into kg/cm3
convertFactor = 10^-9*10^-6;

%% 
[Gral,sourceNum] = setGralConfig();

%%
reverseStr = [];
% concAll is the raw concenrations of nvPM without corrections of aerosol
% dynamics
concAll = zeros(Gral.nrows, Gral.ncols, sourceNum);
for categoryId = 1:meteoCategoryNum
    %% show information
    percentDone = 100 * categoryId / meteoCategoryNum;
    msg = sprintf('Loop %d: %3.1f',meteoCategoryNum, percentDone);
    fprintf([reverseStr, msg]);
    reverseStr = repmat(sprintf('\b'), 1, length(msg));
    %%
    
    filename = [resultsFolder num2str(categoryId,'%05d') '.grz'];
    meteoFrequency = meteoCategories(categoryId, 4);
    if(uncompressFlag)
        unzip(filename, concFolder);
    end
    concCategory = zeros(Gral.nrows, Gral.ncols);
    for sourceId = 1:sourceNum
        concFileName = [concFolder num2str(categoryId,'%05d') '-10' num2str(sourceId) '.con'];
        %%
        conc = zeros(Gral.nrows, Gral.ncols);
        %%
        fid = fopen(concFileName);
        dd = fread(fid, 'int');
        data = reshape(dd(2:end), 3, []);
        xcoord = data(1,:);
        ycoord = data(2,:);
        fclose(fid);
        
        idy = floor((xcoord - Gral.xllcorner - Gral.cellsize/2)/Gral.cellsize) + 1;
        idx = floor((ycoord - Gral.yllcorner - Gral.cellsize/2)/Gral.cellsize) + 1;
        linearInd = sub2ind([Gral.nrows, Gral.ncols], idx, idy);
        %%
        fid = fopen(concFileName);
        dd = fread(fid, 'float');
        data = reshape(dd(2:end), 3, []);
        
        conc(linearInd) = data(3,:)'; 
        conc = flipud(conc);
        fclose(fid);
        concCategory = conc*meteoFrequency;%*concFactors(sourceId, hourId);
        concAll(:, :,sourceId) = concAll(:, :,sourceId) + conc*meteoFrequency;
    end

end
%

concAll = concAll/sum(meteoCategories(:,4))*convertFactor;
save annualConcAverage.mat concAll

