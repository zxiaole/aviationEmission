function absdSegmentation(fileName, dir)
% 11.08.2019 by Xiaole Zhang.
% To read the Openskynet data, and estimate the spatial
% distribution of the emission. Distinguish the locations for taxi, taking
% off and approach

%% read Opensky network data
% fileName = 'month01';
% fileName = 'weekFromFeb01';
data = readtable([dir fileName '.csv']);

groundService = '4b5';
%% define the area and the resolution unit degree
rEarth = 6400000; % meters of earth radius
dx = 0.0001;
ll = [8.48 47.41];%[min(lon(:))-dx/2 min(lat(:))-dx/2];
ur = [8.64 47.50];%[max(lon(:))+dx/2 max(lat(:))+dx/2];
separationTime = 30*60; % 60 minutes
zrhAltitude = 408; % altitude of zurich airport
htmpLanding = zrhAltitude;
heightThreshold = 20; % meter
lengthThreshold = 10; % seconds
delayThreshold = 10; % seconds
takoffAngleThreshold = 0.98; % cos(theta)
takeoffThreshold = 20; % m/s
runWayDistanceThreshold = 50; % m, the distance threshold from runway to decide the takeoff or landing roll
verticalSpeedThreshold = 30; % normal vertical speed would be 1000 feet per min
speedLow = 0.5; % m/s for the upper boundary to define stop of aircrafts
spatialMoveThreshold = 100; % m
continuousStopTime = 60*30; % seconds, time duration to define the stop of engines
takeOffTime = 42; % seconds
windowSize = 5;
windowSizeForLongStop = 20;
debug = 0;

multipleN = 0;
theta = 0.5*pi;
rotations = [cos(theta) sin(theta); -sin(theta) cos(theta)];
%%
xDegreeToDistance = rEarth*cos((ll(2)+ur(2))/2/180*pi)*1/180*pi;
yDegreeToDistance = rEarth*1/180*pi;

%% reorganise the data
% find all the aircrafts below 1000 meters and within the domain
% dataBackup = data;
hights = data.baroaltitude;
lon = data.lon;
lat = data.lat;
% speeds = data.velocity;
timeMsg = data.time;
timeContact = data.lastcontact;
timeAge = timeMsg-timeContact;
id = hights < 1500&lon>ll(1)&lon<ur(1)&lat>ll(2)&lat<ur(2)&timeAge<delayThreshold;
data(~id,:) = [];

% make the time as increasing sequence
times = data.time;
[seqT,idIncreast] = sort(times, 'ascend');
data = data(idIncreast,:);

%%
icaoId = data.icao24;
onground = data.onground;
onground = strcmpi(onground, 'True');
speeds = data.velocity;
hights = data.baroaltitude;
lon = data.lon;
lat = data.lat;
times = data.time;

statusAll = zeros(size(lon));
durationAll = zeros(size(lon));
speedAll = zeros(size(lon));
heightAll = zeros(size(lon));
aircrafts= unique(icaoId);
count = 0;

reverseStr = '';
for i = 1:length(aircrafts)
    percentDone = 100 * i / length(aircrafts);
    countCurrent = 0;
    msg = sprintf('Loop %d: %3.1f; Total flights: %d',i, percentDone, count);
    fprintf([reverseStr, msg]);
    reverseStr = repmat(sprintf('\b'), 1, length(msg));
    
    if(debug)
        currentAircraft = '4b17de';%aircrafts{i};
    else
        currentAircraft= aircrafts{i};
    end
    
    idt = strcmp(icaoId,currentAircraft);
    idtIndex = find(idt==1);
    seq=onground(idt);
    seqH=hights(idt);
    seqT=times(idt);
    seqLon = lon(idt);
    seqLat = lat(idt);
    
    %% estiamte the flight phases
    statusIndex = zeros(sum(idt),1); % -1:not valid; 0: taxi; 1: approach; 2: taking off;3: takeoff roll on ground; 4: at boarding gate (APU); 5: landing on ground; 6: Surface Vehicle; 7: climb out
    heightAboveGround = zeros(sum(idt),1); % convert the baroatitude into the heights above ground
    duration = [0; diff(seqT)];
    changeHeights = [0; diff(seqH)];
    seqSpeed = zeros(sum(idt),1);
    
    idsep = find(duration>separationTime);
    % Set the changes in duration and height between different periods as
    % zeros
    changeHeights(idsep) = 0;
    duration(idsep) = 0;
    idRoundBegin = 1;
    flagGround = 0;
    
    % this is ground service viecle continue
    if(strcmp(currentAircraft(1:3), groundService))
        statusIndex(:) = 6;
    else 
        for roundN = 1:length(idsep)+1
            htmpLanding = zrhAltitude; % set default ground altitude, but this will be modified if on ground measurements are avialable
            
            if(roundN<=length(idsep))
                idRoundN = idRoundBegin:idsep(roundN)-1;
                idRoundBegin=idsep(roundN);
            else
                idRoundN = idRoundBegin:length(seq);
            end
            
            if(debug)
                td = idtIndex(idRoundN) ==  29979;
                if(sum(td)>0)
                    disp(1)
                end
            end
            
            %% correct the false status
            seqTmp = seq(idRoundN);
            seqHTmp = seqH(idRoundN);
            seqTTmp = seqT(idRoundN);
            seqLonTmp = seqLon(idRoundN);
            seqLatTmp = seqLat(idRoundN);
            seqDurationTmp = duration(idRoundN);
            
            %
            lonDiff = ([0; diff(seqLonTmp)])*xDegreeToDistance;
            latDiff = ([0; diff(seqLatTmp)])*yDegreeToDistance;
            seqUTmp = lonDiff./seqDurationTmp;
            seqVTmp = latDiff./seqDurationTmp;
            seqUTmp = movmean(seqUTmp,windowSize);
            seqVTmp = movmean(seqVTmp,windowSize);
            seqSpeedTmp = sqrt(seqUTmp.^2 + seqVTmp.^2);
            seqMoveTmp = seqSpeedTmp.*seqDurationTmp;
            
            statusIndexTmp = zeros(length(seqTmp),1);
            changeHeightsTmp = changeHeights(idRoundN);
            
            if(seqTTmp(end)-seqTTmp(1)<lengthThreshold)
                statusIndex(idRoundN) = -1;
                seqSpeed(idRoundN) = -1;
                heightAboveGround(idRoundN) = -1;
                seq(idRoundN) = -1;
                continue
            end
            
            idsky = find(seqTmp==0);
            idground = seqTmp == 1 & seqHTmp>0;
            meanGroundAltitude = mean(seqHTmp(idground));
            % there may be some negative values, which should be corrected.
            seqHTmp(seqTmp == 1 & seqHTmp<0)=meanGroundAltitude;
            % remove some spikes
            seqHTmp(seqTmp == 1 & abs(seqHTmp-meanGroundAltitude)>heightThreshold)=meanGroundAltitude;
            
            %         verticalSpeedTmp = changeHeightsTmp./seqDurationTmp;
            %         idVertical = find(verticalSpeedTmp>verticalSpeedThreshold);
            %         while(~isempty(idVertical))
            %             seqHTmp(idVertical) = seqHTmp(idVertical-1);
            %             changeHeightsTmp = [0; diff(seqHTmp)];
            %             verticalSpeedTmp = changeHeightsTmp./seqDurationTmp;
            %             idVertical = find(verticalSpeedTmp>verticalSpeedThreshold);
            %         end
            
            if(~isempty(idsky))
                seqCheck = seqHTmp(idsky);
                diffs = [0; diff(seqCheck)];
                
                diffs = movmean(diffs,windowSize);
                id = abs(diffs)==0;
                seqTmp(idsky(id)) = true;
                seqHTmp(idsky(id)) = meanGroundAltitude;
                
                y = medfilt1(double(seqTmp),min(20, floor(length(seqTmp)/4)));
                idCorrect = y>0;
                seqHTmp(idCorrect&~seqTmp) = meanGroundAltitude;
                seqTmp = idCorrect;
            end
            
            if(debug)
                latTmp = seqLat(idRoundN);
                lonTmp=seqLon(idRoundN);
                speedTmp = speeds(idtIndex(idRoundN));
                save([currentAircraft '.mat'], 'seqHTmp', 'seqTmp','lonTmp', 'latTmp', 'speedTmp', 'seqTTmp')
            end
            
            currentStatus = seqTmp(1);
            idBegin = 1;
            countTmp = 0;
            startTakingOffTime = nan;
            
            ddd = diff(seqTmp);
            if(sum(abs(ddd))>1)
                multipleN=multipleN+1;
            end
            for j=2:length(seqTmp)
                if(currentStatus~=seqTmp(j))
                    
                    
                    if(seqTmp(j)) % landing
                        
                        groundEndingIndex = find(seqTmp(j:end)==1) +j-1; % find all the taxi period, where seqTmp is one
                        htmpLanding = mean(seqHTmp(groundEndingIndex)); % find the baroaltitude during this landing
                        
                        if(j>2)
                            % try to find the taking off phase on ground
                            uvector = [mean(diff(seqLonTmp(1:(j-1))))*xDegreeToDistance mean(diff(seqLatTmp(1:(j-1))))*yDegreeToDistance];
                            %                             uvector = [(seqLonTmp(j-1)-seqLonTmp(j-2))*xDegreeToDistance (seqLatTmp(j-1)-seqLatTmp(j-2))*yDegreeToDistance];
                            runWayVector = uvector/sqrt(uvector*uvector'); % runway vector
                            runWayVectorPerpen = runWayVector*rotations;
                            % a point on the runway
                            runWayPoint = [mean(seqLonTmp(1:(j-1))) mean(seqLatTmp(1:(j-1)))];
                            % calculate the movement direction of aircraft
                            uVector = [seqUTmp(groundEndingIndex) seqVTmp(groundEndingIndex)];
                            uSpeed = sqrt(sum((uVector.*uVector),2));
                            uIndicators = uVector*runWayVector'./uSpeed;
                            
                            pVector = ([seqLonTmp(groundEndingIndex) seqLatTmp(groundEndingIndex)] - runWayPoint).*[xDegreeToDistance yDegreeToDistance];
                            pDistance = abs(pVector*runWayVectorPerpen'); % unit: m
                        
                            idspeedMean = uSpeed>0;
                            takeoffThreshold = mean(uSpeed(idspeedMean)) + std(uSpeed(idspeedMean));
                            idUIndicators = uIndicators>takoffAngleThreshold&uSpeed>takeoffThreshold&pDistance<runWayDistanceThreshold;
                            statusIndexTmp(groundEndingIndex(idUIndicators)) = 5; % Landing on ground
                        end
                        
                        if(abs(sum(changeHeightsTmp(idBegin:j-1)))>heightThreshold)
                            countTmp = countTmp + 1;
                            if(mean(changeHeightsTmp(idBegin:j-1))>0)
                                statusIndexTmp(idBegin:j-1) = 2;
                            else
                                statusIndexTmp(idBegin:j-1) = 1;
                            end
                        end
                    else % taking off
                        groundEndingIndex = find(seqTmp(1:j)==1); % find all the taxi period, where seqTmp is one
                        htmpLanding = mean(seqHTmp(groundEndingIndex)); % find the baroaltitude during this landing
                        idTakingOffOnGround = find(seqHTmp(j:end)-htmpLanding<heightThreshold)+j-1;
                        
                        % try to find the taking off phase on ground
                        uvector = [mean(diff(seqLonTmp(j:end)))*xDegreeToDistance mean(diff(seqLatTmp(j:end)))*yDegreeToDistance];
%                         uvector = [(seqLonTmp(j)-seqLonTmp(j-1))*xDegreeToDistance (seqLatTmp(j)-seqLatTmp(j-1))*yDegreeToDistance];
                        runWayVector = uvector/sqrt(uvector*uvector'); % runway vector
                        runWayVectorPerpen = runWayVector*rotations;
                        % a point on the runway
                        runWayPoint = [mean(seqLonTmp(j:end)) mean(seqLatTmp(j:end))];
                                                
                        uVector = [seqUTmp(groundEndingIndex) seqVTmp(groundEndingIndex)];
                        uSpeed = sqrt(sum((uVector.*uVector),2));
                        uIndicators = uVector*runWayVector'./uSpeed;
                        
                        pVector = ([seqLonTmp(groundEndingIndex) seqLatTmp(groundEndingIndex)] - runWayPoint).*[xDegreeToDistance yDegreeToDistance];
                        pDistance = abs(pVector*runWayVectorPerpen'); % unit: m
                               
                        idspeedMean = uSpeed>0;
                        takeoffThreshold = mean(uSpeed(idspeedMean)) + std(uSpeed(idspeedMean));
                        idUIndicators = uIndicators>takoffAngleThreshold&uSpeed>takeoffThreshold&pDistance<runWayDistanceThreshold;
                        statusIndexTmp(groundEndingIndex(idUIndicators)) = 3; % taking-off on ground
                        
                        if(sum(idUIndicators)>0)
                            idStart = groundEndingIndex(idUIndicators);
                            startTakingOffTime = seqTTmp(idStart(1));
                        end
                        
                        if(abs(seqHTmp(end)-htmpLanding)>heightThreshold)
                            countTmp = countTmp + 1;
                        end
                    end
                    idBegin = j;
                    currentStatus = seqTmp(j);
                end
            end
            
            if(~seqTmp(end))
                if(abs(sum(changeHeightsTmp(idBegin:end)))>heightThreshold)
                    if(mean(changeHeightsTmp(idBegin:end))>0)
                        statusIndexTmp(idBegin:end) = 2;
                        if(~isnan(startTakingOffTime))
                            climbId = find((seqTTmp(idBegin:end) -startTakingOffTime)>takeOffTime);
                            if(~isempty(climbId))
                                climbId = climbId(1) + idBegin-1;
                                statusIndexTmp(climbId:end) = 7;
                            end
                        end
                    else
                        statusIndexTmp(idBegin:end) = 1;
                    end
                    flagGround=0;
                else
                    flagGround=1;
                end
            else
                flagGround=1;
            end
            
            if(countTmp==0)
                if(seqTmp(end))
                    htmpLanding = mean(seqHTmp);
                    if(~flagGround)
                        countTmp = 1;
                        flagGround=1;
                    end
                else
                    countTmp = 1;
                end
                
            end
            
            ongroundId = find(statusIndexTmp==0);
            speedGround = seqSpeedTmp(ongroundId);
            speedGround(isnan(speedGround)) = 0;
            speedGround = medfilt1(speedGround, windowSizeForLongStop);
            groundFlags = 0;
            for groundId = 1:length(speedGround)
                if(speedGround(groundId)<speedLow && seqMoveTmp(groundId)< spatialMoveThreshold)
                    groundFlags=groundFlags+1;
                else
                    if(groundFlags>0)
                        id2 = ongroundId(groundId-1);
                        id1 = ongroundId(groundId-groundFlags);
                        if(sum(seqDurationTmp(id1:id2))>continuousStopTime)
                            statusIndexTmp(id1:id2)=4;
                        end
                    end
                    groundFlags = 0;
                end
            end
            
            statusIndex(idRoundN) = statusIndexTmp;
            seqSpeed(idRoundN) = seqSpeedTmp;
            heightAboveGround(idRoundN) = max((seqHTmp - htmpLanding)*zrhAltitude/htmpLanding,0);
            seq(idRoundN) = seqTmp;
            countCurrent = countCurrent+countTmp;
            count = count+countTmp;
        end
    end
    speedAll(idt) = seqSpeed;
    durationAll(idt) = duration;
    statusAll(idt) = statusIndex;
    heightAll(idt) =  heightAboveGround;
end
save(['segmentation/' fileName '.mat'], 'statusAll', 'heightAll', 'durationAll', 'speedAll','lon', 'lat', 'count', 'll', 'ur', 'times')
end 