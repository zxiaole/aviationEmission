function [concAll] = getGralConc(scenarioId,sourceNum, Gral)

%% [concAll] = getGralConc(scenarioId,sourceNum, Gral)
% Dec. 12, 2019, Xiaole Zhang
% Get all the conc for scenario ID
%%
concFolder = './concData/';

concAll = zeros(Gral.nrows, Gral.ncols, sourceNum);
for sourceId = 1:sourceNum
    concFileName = [concFolder num2str(scenarioId,'%05d') '-1' num2str(sourceId, '%02d') '.con'];
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
    
    concAll(:, :,sourceId) = conc;
end


end



