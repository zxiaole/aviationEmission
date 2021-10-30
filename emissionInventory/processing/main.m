clear
weeksNum = 1;

%%

for i=0:(weeksNum-1)
    disp(i)
    filename = ['weekFromFeb', num2str(i,'%02d')];
    absdSegmentation(filename, '/data/database/Openskynet/codeZurich/' )
    spatialFrequence(filename, 'segmentation', 0.00005)
end


%% get the annual total duration for each phase
phases = {'Taxiing', 'Take-off_roll', 'Take-off', 'Climb-out', 'Approach', 'Landing_roll'};
dir = 'spatialFrequency/';

phaseId = 1;
filename = [dir 'weekFromFeb' num2str(i, '%02d') '_5e-05_' phases{phaseId} '.mat'];
    load(filename);
frequencyByPhases = zeros([size(pixelFrequency), length(phases)]);
heightByPhases = zeros([size(pixelFrequency), length(phases)]);
heightCount = zeros([size(pixelFrequency),length(phases)]);
countTotal = 0;

for i=0:(weeksNum-1)
    for phaseId = 1:length(phases)
        filename = [dir 'weekFromFeb' num2str(i, '%02d') '_5e-05_' phases{phaseId} '.mat'];
        load(filename);
        pixelFrequency(isnan(pixelFrequency)) = 0;
        pixelHeights(isnan(pixelHeights)) = 0;
        frequencyByPhases(:,:,phaseId) = frequencyByPhases(:,:,phaseId) + pixelFrequency;
        heightByPhases(:,:,phaseId) = heightByPhases(:,:,phaseId) + pixelHeights;
         heightCount(:,:,phaseId) = heightCount(:,:,phaseId) + (pixelHeights>0);
    end
    countTotal = countTotal + count;
end
heightByPhases = heightByPhases./heightCount; % 44 weeks
heightByPhases(isnan(heightByPhases)) = 0;
save totalFrequency.mat  frequencyByPhases phases heightByPhases countTotal ll dx ur
%% re-sample the emission to make lower resolution 
load airportMask.mat
load pushMask.mat
load ZRH_2018.mat
imageFile = 'airportBackground2.jpg';

% March 27, 2020
totalEmByPhase = zeros(6, 1);
%
nfactor = 80;
rEarth = 6400000; %m
fontsize = 25;
windowSize = 10;
clim = [14 20.5];
phasesName = phases;

standardDuration = [26*60, 4*60, 42, 4*60, 42, 2*60+12];
dataEmission = nvolNum;
standardEmission = [dataEmission(1), dataEmission(4), dataEmission(2), dataEmission(4), dataEmission(2), dataEmission(3)];

dxNew = dx*nfactor;
idNum = 0;
for phaseId = 1:length(phases)
%     dataFileName = [resolutionName phases{phaseId} '.mat'];
%     load(dataFileName);
    pixelFrequency = frequencyByPhases(:,:,phaseId);
    timeFactor = 1/(countTotal/2); % per flight
    xDegreeToDistance = rEarth*cos((ll(2)+ur(2))/2/180*pi)*1/180*pi;
    yDegreeToDistance = rEarth*1/180*pi;
    ds = dx*dx*xDegreeToDistance*yDegreeToDistance;

    [xb,yb,hImage] = drawBackground(imageFile, 1, fontsize);
    
    xv=ll(1):dx:ur(1);
    yv=ur(2):-dx:ll(2);
    [x, y] = meshgrid(xv,yv);
    
    
    airportBWNew = interp2(xAirportBW, yAirportBW, double(airportBW), x, y);
    airportBWNew = airportBWNew  == 1;
    
    pushBackBWNew = interp2(xBW, yBW, double(pushBackBW), x, y);
    pushBackBWNew = pushBackBWNew == 1;
    selfPowerBWNew = interp2(xBW, yBW, double(selfPowerBW), x, y);
    selfPowerBWNew = selfPowerBWNew == 1;
    
    if(phaseId == 1)
        pixelFrequencyWithinAirport = pixelFrequency.*airportBWNew.*~(pushBackBWNew);
    else
        pixelFrequencyWithinAirport = pixelFrequency.*~(pushBackBWNew);
    end
    iddtmp = isnan(pixelFrequencyWithinAirport);
    pixelFrequencyWithinAirport(iddtmp) = 0;
    
    pixelFrequencyFinal= isolatedMedFilter(pixelFrequencyWithinAirport);
    pixelFrequencyFinal = noneZeroMedFilterEmission(pixelFrequencyFinal,windowSize);
    
%     sharesRaw = pixelFrequencyFinal/sum(pixelFrequencyFinal(:));
    nvoEmissions = pixelFrequencyFinal*timeFactor/standardDuration(phaseId)*standardEmission(phaseId); % kg/a
    
    [nvoEmissions] = downScaleM(nvoEmissions, nfactor);
    emissionsAll(:,:,phaseId) = nvoEmissions;
    if(phaseId==1||phaseId==2||phaseId==6)
        heights = zeros(size(nvoEmissions));
        heightAll(:,:,phaseId) = heights;
    else
        [heights, outputN] = downScaleM(heightByPhases(:,:,phaseId), nfactor);
        heights = heights./outputN;
        heights(isnan(heights)) = 0;
        heightAll(:,:,phaseId) = heights;
    end
    alphaData = nvoEmissions>0 & ~isnan(nvoEmissions);
    xvNew=ll(1)+dxNew/2:dxNew:ur(1)-dxNew/2;
    yvNew=ur(2)-dxNew/2:-dxNew:ll(2)+dxNew/2;
    
    hold on
    hl = imagesc(xvNew, yvNew, log10(nvoEmissions), clim );
    set(hl, 'alphadata', alphaData)
    set(gca, 'xlim', [8.53 8.575], 'ylim', [47.44 47.485]);
    colormap jet
    text(8.56,47.4825, phasesName{phaseId}, 'fontsize',fontsize);
    h2=cbarrow2();
    
    h=gcf;
    c=get(h,'children'); % Find allchildren
    cb=findobj(h,'Tag','Colorbar'); % Find thecolorbar children
    barTicks = cb.Ticks;
    for i=1:length(barTicks)
        cb.TickLabels{i} = ['10^{' num2str(barTicks(i)) '}'];
        cb.FontSize = fontsize;
        cb.FontName = 'Arial';
    end
    
    cb.Label.String = {'nvPM Number\cdota^{-1}'};
    cb.Label.Rotation = 0;
    cb.Label.Position = [1 clim(2)+0.32 0];
    saveas(gcf, [phases{phaseId} '.jpg'], 'jpg')
    
    DN = zeros(size(nvoEmissions));
    dnId = find(nvoEmissions(:)>0);
    DN(dnId) = dnId+idNum;
    idNum = idNum + length( dnId );
    
    R = georefcells();
    R.LatitudeLimits = [ur(2)-size(nvoEmissions,1)*dxNew+dxNew/2 ur(2)-dxNew/2];
    R.LongitudeLimits = [ll(1)+dxNew/2 ll(1)+size(nvoEmissions,2)*dxNew-dxNew/2];
    R.ColumnsStartFrom = 'north';
    R.CellExtentInLatitude = dxNew;
    R.CellExtentInLongitude = dxNew;
    R.RasterSize = size(nvoEmissions);
    namesTif = [phases{phaseId} '_emission.tif'];
    geotiffwrite(namesTif,nvoEmissions,R)
    namesTif = [phases{phaseId} '_height.tif'];
    geotiffwrite(namesTif,heights,R)
        namesTif = [phases{phaseId} '_DN.tif'];
    geotiffwrite(namesTif,DN,R)
    totalEmByPhase(phaseId) = sum(nvoEmissions(:));
end
save totalEmByPhase.mat totalEmByPhase