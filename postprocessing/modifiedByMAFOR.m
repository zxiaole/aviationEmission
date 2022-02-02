function [concAll] = modifiedByMAFOR(dirMAFOR, Gral, sourceNum, hourId, u10, dilcoef, scenariodId, minDistance, factors,source)
% Dec. 29, 2019, Xiaole Zhang
%   Modify the Gral results by using the MAFOR model results to take the
%   infuence of aerosol dynamics into account


%%
destination = [num2str(hourId) '_' source '_' num2str(dilcoef) '_u10_' num2str(u10)];
filename = [dirMAFOR destination '/size_dis.res'];
resultDir = ['../maforGralCombined_resvise_aromatics/'];
outputName = [resultDir num2str(hourId) '.mat'];
if(exist(outputName, 'file'))
    disp('Exist calculation')
    load(outputName)
else
    data = importdata(filename);
    if(isempty(data))
        error(num2str(hourId))
    end
    refDist = (data(4,2:end).*data(2,2:end))*10^-6; % convert from #/m^3 to #/cm^3;
    refDist = refDist/sum(refDist);
    
    t = data(4:end,1) - data(4,1);
    distanceMAFOR = t*u10;
    dilution = (1 + distanceMAFOR/minDistance).^-dilcoef;
    dataNet = data(4:end, 2:end) - (1-dilution)*data(3,2:end);
    
    realN = dataNet(:, :)./(dataNet(1,:));
    factorsAero =  realN./dilution;
    idNAN = isnan(factorsAero)|isinf(factorsAero);
    factorsAero = min(factorsAero,1);
    factorsAero = max(factorsAero, 0);
    factorsAero(idNAN) = 0;
    
    numFactor = sum(factorsAero.*dataNet(1,:),2)./sum(dataNet(1,:));
    %% get conc
    concAllTmp = getGralConc(scenariodId,sourceNum, Gral)*Gral.convertFactor;
    for phaseId = 1:sourceNum
        concAllTmp(:,:,phaseId) = concAllTmp(:,:,phaseId)*factors(phaseId);
    end
    concAll = sum(concAllTmp, 3);
    nrow = size(concAll,1);
    ncol = size(concAll,2);
    [vd, idV] = unique(distanceMAFOR);
    concFactors = interp1(distanceMAFOR(idV)+minDistance, numFactor(idV), Gral.dist(:),'linear','extrap');
    concFactors = min(concFactors, 1);
    concFactors = max(concFactors, 0);
    concAll = concAll.*reshape(concFactors, nrow, ncol);
    
    
    save(outputName, 'concAll');
end
% concAll = repmat(sum(concAllTmp, 3),1,1,length(refDist));
% nrow = size(concAll,1);
% ncol = size(concAll,2);
%
% distTmp = abs(Gral.dist(:) - (distanceMAFOR+minDistance)');
% [vs, id] = min(distTmp, [], 2);
% id = reshape(id, nrow, ncol);
% factorsAero(id, :);
% for nBin = 1:length(refDist)
%     concFactors = interp1(distanceMAFOR, factorsAero(:, nBin), Gral.dist(:),'linear','extrap');
%     concFactors = min(concFactors, 1);
%     concFactors = max(concFactors, 0);
%     concAll(:,:,nBin) = concAll(:,:,nBin).*refDist(nBin).*reshape(concFactors, nrow, ncol);
% end
%


