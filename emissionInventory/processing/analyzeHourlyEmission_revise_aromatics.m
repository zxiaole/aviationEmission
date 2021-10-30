%% Dec. 12, 2019, Xiaole Zhang
% analyze the distribution of emission at each hour
% based on weekday, Monday to Sunday, each day will have a temporal profile

%-1:not valid;
% 0: taxi;
% 1: approach;
% 2: taking off;
% 3: takeoff roll on ground;
% 4: at boarding gate (APU);
% 5: landing on ground;
% 6: Surface vehicle
% 7: climbe out
%%
clear
weeksNum = 1;
folder = 'segmentation/';
clcFlag = 1;
drawFlag = 1;
calcTemp = 1;
calcHourEmissionFactor = 1;
refEmissionNum = 10^16; % num per kg-fuel
KFactor = 273.15; % Kelvin
%%
load('pushMask.mat');
load('airportMask.mat');

% the same as the sequence in GRAL source
phases = {'Taxiing', 'Take-off roll', 'Take-off', 'Climb-out', 'Approach', 'Landing roll'};
pairsId = [0 3 2 7 1 5];
%%
% timeAtPhase 7*24 hours, 6 phases
if clcFlag==0
    load('hourlyDuration.mat');
else
    sliceNum = weeksNum;
    timeAtPhase = zeros(7, 24, 6,sliceNum);
    for i=0:sliceNum-1
        disp(i)
 
        filename = [folder 'weekFromFeb', num2str(i,'%02d')];

        load(filename);
        
        % time zone zurich: when daylight saving, +2;  when not +1
        dateFlight = datetime(times,'ConvertFrom','posixtime','TimeZone','Europe/Rome') + 1/24; % convert unix time to date local
        dayLightSaving = isdst(dateFlight); % if daylight saving =1, otherwise 0;
        dateFlight = dateFlight + dayLightSaving/24;
        
        hourFlight = hour(dateFlight);
        weekDayFlight = weekday(dateFlight);
        
        
        for phaseId = 1:6
            if(phaseId == 1)
                validFlag = interp2(xBW, yBW, double(pushBackBW), lon, lat) == 0&interp2(xAirportBW, yAirportBW, double(airportBW), lon, lat)==1;
            elseif(phaseId == 2)
                validFlag = interp2(xBW, yBW, double(pushBackBW), lon, lat) == 0;
            end
            for hourId = 1:24
                for weekdayId = 1:7
                    id = validFlag&hourFlight==hourId & weekDayFlight==weekdayId & statusAll==pairsId(phaseId);
                    timeAtPhase(weekdayId, hourId, phaseId, i+1) = sum(durationAll(id));
                end
            end
        end
        
    end
    
    save hourlyDuration.mat timeAtPhase
end
%% draw temporal changes
if(drawFlag)
    symbols = {'^', 'd', 'h','p', 's', '>', 'o'};
    colors = {'k', 'g', 'm','c', 'y', 'b', 'r'};
    weekdays = {'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'};
    data = sum(timeAtPhase,4);
    linewidth = 1.5;
    markersize = 12;
    fontsize = 20;
    for phaseId=1:6
        figsize = [100 100 1000 400];
        figure('position', figsize)
        hold on
        tmpData = data(:,:,phaseId);
        for i=1:7
            tmp = tmpData(i,:);
            tmp(1:6) = 0; % after 0 befor 6:00 set as 0 according to airport report
            plot((tmp./sum(tmp,2))'*100, [symbols{i} colors{i} '-'], 'markersize', markersize, 'markerfacecolor', colors{i}, 'markeredgecolor', 'k', 'linewidth', linewidth);
        end
        box on
        xlabel('Hour of the day');
        ylabel({'Hourly emission share (%)'})
        text(19.5,12, phases{phaseId}, 'fontsize',fontsize);
        set(gca, 'ylim', [0 14], 'fontname', 'Arial', 'fontweight', 'normal', 'fontsize', fontsize);
        hl = legend( weekdays, 'location', 'northwest');
        
        set(hl, 'box', 'off')
        saveas(gcf, [phases{phaseId} '_tempralFactor.jpg'], 'jpg')
        
    end
    year = 2017;
    E = eomday(year,1:12);
    emissionTemp = zeros(12, 7);
end

%% load the temperature of 2017
if(calcTemp)
    tempData = readtable('airportTemp.txt', 'HeaderLines',1);
    tempTime = tempData.Var3;
    temp = str2double(tempData.Var22);
    dewTemp = str2double(tempData.Var23); % EW POINT temperature
    rain = str2double(tempData.Var29); % inch per hour
    rain = rain*2.54*10; % mm/h
    rain(isnan(rain)) = 0;
    
    temp = (5/9)*(temp-32); % To convert temperature from degrees Fahrenheit by
    dewTemp = (5/9)*(dewTemp-32);
    
    t = datetime(num2str(tempTime),'InputFormat','yyyyMMddHHmm','TimeZone','Europe/Rome') + 1/24;
    
    dayLightSaving = isdst(t); % if daylight saving =1, otherwise 0;
    t = t + dayLightSaving/24;
    hours = 24*(datenum(t) - datenum(datetime('201701010000','InputFormat','yyyyMMddHHmm','TimeZone','Europe/Rome')));
    
    id = isnan(temp)|isnan(hours)|isnan(dewTemp)|dewTemp>temp;
    temp(id) = [];
    hours(id) = [];
    dewTemp(id) = [];
    rain(id) = [];
    [v, id] = unique(hours);
    temp = temp(id);
    hours = hours(id);
    dewTemp = dewTemp(id);
    rain = rain(id);
    % https://iridl.ldeo.columbia.edu/dochelp/QA/Basic/dewpoint.html
    % Calculate the relative humidity
    [humidity] = calcHumidity(temp+KFactor,dewTemp+KFactor);
    
    hoursNew = 1:365*24;
    
    
    temp = interp1(hours, temp, hoursNew);
    humidity = interp1(hours, humidity, hoursNew);
    rain = interp1(hours, rain, hoursNew);
    save temperatures.mat hoursNew temp humidity rain
else
    load('temperatures.mat')
end
%% estimate hourly fuel consumption
if(calcHourEmissionFactor)
    load('ZRH_2018.mat');
    load('emissionCoef_aromatics.mat');
    sulfurContent = 650;
    aromaticContent = 18;
    modelFunEIn =  @(q,x)q(1)./(1+exp(q(2)*x(:,1)+q(3)))...
        .*exp(x(:,2)*q(4)+x(:,3)*q(5)+x(:,4).^1*q(6));
    
    dayFlights = importdata('dailyFlights');
    dayFactors = dayFlights/sum(dayFlights);
    
    idSeq = [1 4 2 4 2 3]; % this sequence is the same as that in 'main.m', but it's different from that in GRAL shown above
    % GRAL: phases = {'Taxiing', 'Take-off roll', 'Take-off', 'Climb-out', 'Approach', 'Landing roll'};
    standardEmission = nvolNum(idSeq);%[dataEmission(1), dataEmission(4), dataEmission(2), dataEmission(4), dataEmission(2), dataEmission(3)];
    standardFuelComp = departFuelComsuption(idSeq);%[departFuelComsuption(1), departFuelComsuption(4), departFuelComsuption(2), departFuelComsuption(4), ]
    defaultEmissionIndiceGral = standardEmission./standardFuelComp;
    % approachFuelConsumptionModification = [1, 7/30, 1, 7/30, 1, 1 ]; % approah below 100m should using 7% taxiing
    
    thrustCorrention = [7, 100, 100, 80, 7, 7]./[7, 30, 100, 30, 100, 80];
    thurstLevels = [7, 100, 100, 80, 7, 7];
    takingOffCorrection = [1, 0.8059, 0.8059, 1, 1, 1]; % the ads-b estimated takingoff time is 52.1156, 0.8059 of the standard 42s
    totalPNFactors = zeros(8760, 6);
    totalPNFactorsStd = zeros(8760, 6);
    firstDay = weekday(datetime('20170101','InputFormat','yyyyMMdd'));
    
    
    data = sum(timeAtPhase,4);
    hourFactors = zeros(7, 24, 6);
    for phaseId=1:6
        tmpData = data(:,:,phaseId);
        for i=1:7
            tmp = tmpData(i,:);
            tmp(1:6) = 0; % after 0 befor 6:00 set as 0 according to airport report
            hourFactors(i, :, phaseId) = tmp./sum(tmp);
        end
    end
    
    for hour = hoursNew
        currentHour = mod(hour, 24);
        if(currentHour==0)
            currentHour = 24;
        end
        currentWeekDay = mod(firstDay+floor(hour/24),7);
        if(currentWeekDay == 0)
            currentWeekDay = 7;
        end
        currentDay = ceil(hour/24);
        
        % Get the fraction of the corresponding day
        dayFactor = dayFactors(currentDay);
        
        currentTmp = temp(hour);
        
        for phaseId = 1:6
            thrust = thurstLevels(phaseId);
            [pnFactor, delta] = nlpredci(modelFunEIn,[sulfurContent currentTmp thrust aromaticContent], emissionFactorsCoef, resid, 'jacobian',J,'PredOpt','observation');
            hourFactor = hourFactors(currentWeekDay, currentHour, phaseId)*dayFactors(currentDay)/(1/365/24);
            totalPNFactors(hour, phaseId) = (refEmissionNum*pnFactor)...
                /defaultEmissionIndiceGral(phaseId)...
                *thrustCorrention(phaseId)...
                *takingOffCorrection(phaseId)...
                *hourFactor;
            
            refStd = 0.0;
            refMean = 1;
            deltaAll = sqrt(delta^2*refStd^2 + delta^2*refMean^2 + pnFactor^2*refStd^2);
            totalPNFactorsStd(hour, phaseId)= (refEmissionNum*deltaAll)...
                /defaultEmissionIndiceGral(phaseId)...
                *thrustCorrention(phaseId)...
                *takingOffCorrection(phaseId)...
                *hourFactor;
        end
    end
    
    save totalPNFactors_revise_aromatics.mat totalPNFactors totalPNFactorsStd
end

