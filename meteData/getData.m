% the directory for 'mainFolder' should be changed
% April. 22, 2020
% generate input data for GRAL Wuhan
% estimate stability 
%% 
clc
clear
f = filesep;

%% Configuration
year = 2019; % start of the period
month = 1;
day = 1;
hour = 0;
timezone = 0; % all the data are for 0 time zone, so time difference should be considered for specific airport

taskName = 'zhang424089'; % last part of the file name
lastHours = 24*365; % length of the period

% airport coordinate
airportLat = 40;
airportLon = 0;

mainFolder = './meteoData/data'; % folder for the meteo data

%% Initialization
hour = floor(hour/6)*6;
datafolder = [mainFolder f 'data'];
DateString = [num2str(year)...
    num2str(month, '%02d')...
    num2str(day, '%02d')...
    num2str(hour, '%02d')];
FormatIn = 'yyyymmddhh';
ct = datenum(DateString,FormatIn);

num = (lastHours)/6+1;
u = zeros(num*2,1); % m/s
v = zeros(num*2,1); % m/s
temperationGradient = zeros(num*2,1);
humidity = zeros(num*2,1);
radiation = zeros(num*2,1); % W/m**2
cloudCoverage = zeros(num*2,1); % %
rain = zeros(num*2,1);
count = 0;

%% load the meteo data
for i = 0:6:lastHours
    
    count = count + 1;
    currentDate = datestr(ct+i/24, FormatIn);
    disp(['Processing data for : ' currentDate]);
    %% Process 0 hour
    filename_0 = ['gfs.0p25.' currentDate '.f000.grib2.' taskName '.nc'];   
    filePath_0 = fullfile(mainFolder, filename_0);
    
    finfo_0 = ncinfo(filePath_0);

    if(i==0)
        lat = ncread(filePath_0, 'lat_0');
        lon = ncread(filePath_0, 'lon_0');
        id = lon>180;
        lon(id) = lon(id)-360;
        [lonGrid, latGrid] = meshgrid(lon(:), lat(:));
    end
    
    % get wind data, 10 m above ground
    utmp =  ncread(filePath_0, 'UGRD_P0_L103_GLL0');
    utmp = squeeze(utmp(:,:,1)); 
    u((count-1)*2+1) = interp2(lonGrid, latGrid, utmp', airportLon, airportLat); % interpolation to the location of the farm
    vtmp =  ncread(filePath_0,'VGRD_P0_L103_GLL0');
    vtmp = squeeze(vtmp(:,:,1)); 
    v((count-1)*2+1) = interp2(lonGrid, latGrid, vtmp', airportLon, airportLat);
    
    % humidity at 2m
    htmp =  ncread(filePath_0, 'RH_P0_L103_GLL0'); 
     htmp = squeeze(htmp(:,:,1)); 
    humidity((count-1)*2+1) = interp2(lonGrid, latGrid, htmp', airportLon, airportLat); % interpolation to the location of the farm

    % get temperation
    ttmp = ncread(filePath_0, 'TMP_P0_L103_GLL0'); 
    ttmpH_80m = squeeze(ttmp(:,:,2,1)); 
    ttmpL_2m = squeeze(ttmp(:,:,1,1)); 
    temperationGradient((count-1)*2+1) = interp2(lonGrid, latGrid, (ttmpH_80m-ttmpL_2m)'/78, airportLon, airportLat); 
    
    %% Process 3 hour
    % radiation and cloud coverage in Boundary layer cloud layer
    filename_3 = ['gfs.0p25.' currentDate '.f003.grib2.' taskName '.nc']; 
    filePath_3 = fullfile(mainFolder, filename_3);
    radtmp = ncread(filePath_3, 'DSWRF_P8_L1_GLL0_avg');
    radiation((count-1)*2+1) = interp2(lonGrid, latGrid, radtmp', airportLon, airportLat);  
    
    % rain
    raintmp =  ncread(filePath_3,'PRATE_P8_L1_GLL0_avg'); 
    raintmp = raintmp/1000*3600*1000;
    rain((count-1)*2+1) = interp2(lonGrid, latGrid, raintmp', airportLon, airportLat); % interpolation to the location of the farm
 
    % get wind data, 10 m above ground
    utmp = ncread(filePath_3, 'UGRD_P0_L103_GLL0');
    utmp = squeeze(utmp(:,:,1)); 
    u((count-1)*2+2) = interp2(lonGrid, latGrid, utmp', airportLon, airportLat); % interpolation to the location of the farm
    vtmp = ncread(filePath_3, 'VGRD_P0_L103_GLL0');
    vtmp = squeeze(vtmp(:,:,1)); 
    v((count-1)*2+2) = interp2(lonGrid, latGrid, vtmp', airportLon, airportLat); 
    
    % humidity at 2m
    htmp =  ncread(filePath_3, 'RH_P0_L103_GLL0');
    htmp = squeeze(htmp(:,:,1)); 
    humidity((count-1)*2+2) = interp2(lonGrid, latGrid, htmp', airportLon, airportLat); % interpolation to the location of the farm

    % get temperation
    ttmp = ncread(filePath_3, 'TMP_P0_L103_GLL0');
    ttmpH_80m = squeeze(ttmp(:,:,2,1)); 
    ttmpL_2m = squeeze(ttmp(:,:,1,1)); 
    temperationGradient((count-1)*2+2) = interp2(lonGrid, latGrid, (ttmpH_80m-ttmpL_2m)'/78, airportLon, airportLat); 

    %% Process 6 hour
    filename_6 = ['gfs.0p25.' currentDate '.f006.grib2.' taskName '.nc'];
    filePath_6 = fullfile(mainFolder, filename_6);

    radtmp2 = ncread(filePath_6, 'DSWRF_P8_L1_GLL0_avg');
    radtmp2 = max((radtmp2*6-radtmp*3)/3, 0);
    radiation((count-1)*2+2) = interp2(lonGrid, latGrid, radtmp2', airportLon, airportLat); 
    
    % rain
    raintmp2 = ncread(filePath_6, 'PRATE_P8_L1_GLL0_avg');
    raintmp2 = raintmp2/1000*3600*1000;
    raintmp2 = max((raintmp2*6-raintmp*3)/3, 0);
    rain((count-1)*2+2) = interp2(lonGrid, latGrid, raintmp2', airportLon, airportLat); % interpolation to the location of the farm
end

%% Interpolate the meteo data as hourly
timeFromFile = 0:3:lastHours+3;
timeByHour = 0:1:lastHours;
u_hourly = interp1(timeFromFile, u, timeByHour)';
v_hourly = interp1(timeFromFile, v, timeByHour)';
rain_hourly = interp1(timeFromFile, rain, timeByHour)';
temperationGradient_hourly = interp1(timeFromFile, temperationGradient, timeByHour)';
humidity_hourly = interp1(timeFromFile, humidity, timeByHour)';

windSpeed_hourly = sqrt(u_hourly.^2 + v_hourly.^2);
windDirection_hourly = -1*atan2(v_hourly, u_hourly)/pi*180-90;
id = windDirection_hourly<0;
windDirection_hourly(id) = windDirection_hourly(id) + 360;

timeFromFile = 1.5-3:3:lastHours+4.5;
radiation = [radiation(1); radiation];
timeByHour = 0:1:lastHours;
radiation_hourly = interp1(timeFromFile,radiation,timeByHour)';

%% Estimate stability
stabilities = zeros(size(windDirection_hourly));
minSpeed = [0 2 3 5 6];
maxSpeed = [2 3 5 6 50];
minRadiation = [925 675 175 20];
maxRadiation = [2000 925 675 175];
stab = [1 1 2 4; 1 2 3 4;2 2 3 4;3 3 4 4; 3 4 4 4];

for i=1:5
    for j=1:4
        id = windSpeed_hourly>minSpeed(i)&windSpeed_hourly<=maxSpeed(i)...
            &radiation_hourly>=minRadiation(j)&radiation_hourly<maxRadiation(j);
        stabilities(id) = stab(i, j);
    end
end

minSpeed = [0 2 3];
maxSpeed = [2 3 50];
minGradient = [-1000 0];
maxGradient = [0 1000];
stab = [6 7; 5 6; 4 4];

for i=1:3
    for j=1:2
        id = windSpeed_hourly>minSpeed(i)&windSpeed_hourly<=maxSpeed(i)&radiation_hourly<20 ...
            &temperationGradient_hourly>=minGradient(j)&temperationGradient_hourly<maxGradient(j);
        stabilities(id) = stab(i, j);
    end
end


%% Save data into file
Formatout = 'dd.mm.yyyy,hh:MM'; datestr(ct+i/24, Formatout);
for i=1:length(timeByHour)
    currentDateShow{i} = datestr(ct+(timeByHour(i)+timezone)/24, Formatout);
end

fid = fopen('metData.txt','w');
for i=1:length(windSpeed_hourly)
    fprintf(fid, '%s, %f, %f, %d \n', currentDateShow{i}, windSpeed_hourly(i), windDirection_hourly(i), stabilities(i));
end
fclose(fid);

%%  Save precipitation data into file
fid = fopen('Precipitation.txt','w');
fprintf(fid, 'Day.Month\tHour\tPrecipitation[mm/h]\n');

for i=1:length(timeByHour)
    dstr = datestr(ct+(timeByHour(i)+timezone)/24, 'dd.mm');
    hstr = datestr(ct+(timeByHour(i)+timezone)/24, 'hh');
	fprintf(fid, '%s\t%d\t%f\n',dstr,str2num(hstr), rain_hourly(i));
end

fclose(fid);



