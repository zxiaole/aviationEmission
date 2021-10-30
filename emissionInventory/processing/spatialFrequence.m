function spatialFrequence(filename, dir, dx)
%%
%-1:not valid; 
% 0: taxi;                    -> 0
% 1: approach;                -> 3
% 2: taking off;              -> 4
% 3: takeoff roll on ground;  -> 2
% 4: at boarding gate (APU);  -> 5
% 5: landing on ground;       -> 1
% 6: Surface vehicle          
% 7: climbe out               -> 6
%%
% filename =  'month01'; %'weekFromFeb00';%
load([dir '/' filename '.mat']);
%%
% dx = 0.00005;
% ll = [8.53 47.44];%[min(lon(:))-dx/2 min(lat(:))-dx/2];
% ur = [8.58 47.49];%[max(lon(:))+dx/2 max(lat(:))+dx/2];
rEarth = 6400000; % meters of earth radius
xDegreeToDistance = rEarth*cos((ll(2)+ur(2))/2/180*pi)*1/180*pi;
yDegreeToDistance = rEarth*1/180*pi;

phases = {'Taxiing', 'Landing_roll', 'Take-off_roll', 'Approach', 'Take-off', 'Climb-out'};
pairsId = [0 5 3 1 2 7];
%%
x=ll(1):dx:ur(1);
y=ur(2):-dx:ll(2);


lonDiff = ([0; diff(lon)])*xDegreeToDistance;
latDiff = ([0; diff(lat)])*yDegreeToDistance;
moveNew = sqrt(lonDiff.^2 + latDiff.^2)./durationAll;

for phaseId = 1:length(phases)
    pixelFrequency = nan(length(y), length(x));
    pixelHeights = nan(length(y), length(x));
    id = statusAll == pairsId(phaseId);
    
    lonInMode = lon(id);
    latInMode = lat(id);
    durationInMode = durationAll(id);
    heightInMode = heightAll(id);
    
    idx = ceil((lonInMode - ll(1))/dx);
    idy = ceil((ur(2)-latInMode)/dx);
    idUnique = unique([idx idy], 'rows');
    reverseStr = '';
    for i=1:length(idUnique)
        percentDone = 100 * i / length(idUnique);
        msg = sprintf('Loop %d: %3.1f',i, percentDone);
        fprintf([reverseStr, msg]);
        reverseStr = repmat(sprintf('\b'), 1, length(msg));
        
        idCurrent = idUnique(i,1)==idx & idUnique(i,2)==idy;
        %         if(length(idCurrent)<10)
        %             continue
        %         end
        pixelFrequency(idUnique(i,2), idUnique(i,1)) = sum(durationInMode(idCurrent));
        pixelHeights(idUnique(i,2), idUnique(i,1)) = sum(heightInMode(idCurrent).*durationInMode(idCurrent))/pixelFrequency(idUnique(i,2), idUnique(i,1));
    end
    save(['spatialFrequency/' filename '_' num2str(dx) '_' phases{phaseId} '.mat'], 'pixelFrequency', 'pixelHeights', 'll', 'ur', 'dx', 'count')
end
end





