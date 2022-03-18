%% Dec. 18, 2019 Xiaole Zhang 
% Try to use svm to predict the CPC
% training the model using data from Basel
clear
load carsmall
rng 'default'  % For reproducibility

%%
tb1 = readtable('Basel.csv', 'headerline', 6);
% tb1 = readtable('BAS_long.csv', 'headerline', 6);

% read meteo data
filename = 'meteo2019.txt';
firstdayMeteo = '201901010000';
[temp,humidity,speed, rain,dirW,hoursNew] = readMeteo(filename, firstdayMeteo);
%%
inputFormat = 'dd.MM.yyyy HH:mm';
timeZone = 'Europe/Rome';
tempTime = tb1.Var1;
concData = tb1.Var2;
firstDay = '01.01.2019 00:00';


%%
[hourIndex,weekDayIndex, hours] = getDateProperties(tempTime, inputFormat, timeZone,firstDay);
temp = interp1(hoursNew, temp, hours);
humidity = interp1(hoursNew, humidity, hours);
speed = interp1(hoursNew, speed, hours);
rain = interp1(hoursNew, rain, hours);
dirW = interp1(hoursNew, dirW, hours);

% X = [hourIndex,weekDayIndex,temp,humidity, speed, rain, dirW];
X = [hourIndex,weekDayIndex,temp,humidity, speed, rain];
idTrain = 1:length(X);
MdlStd = fitrsvm(X(idTrain, :),concData(idTrain),'Standardize',true,'KernelFunction','gaussian');
MdlStd.ConvergenceInfo.Converged

trainData =  predict(MdlStd, X(idTrain,:));
predictions = predict(MdlStd, X(6400:end,:));
save concBackgroundModel.mat MdlStd
%%
interval = 10;
sections = 0:interval:360-interval;
c = [];
numData = [];
for i = sections
    id = dirW>=i & dirW<i+interval& ~isnan(concData);
    c = [c mean(concData(id))];
    numData = [numData sum(id)]; 
end
hold on
plot(sections, c)
%% Zurich data plot
load('predictions2017Zurich.mat')
figsize = [100 100 1200 300];
figure('position', figsize);
tZurich = 1:365*24;
firstDate = datetime('2017010100', 'format', 'yyyyMMddhh');
dates = firstDate + tZurich/24;
plot(tZurich, predictions,'r-', 'linewidth', 1)
xtick = 1:24*14:365*24;
xticklabel = datestr(dates(xtick), 'mmm dd');
set(gca,'fontname', 'arial', 'FontSize',18, 'xlim', [0 362*24],'ylim', [0 20000], 'xtick', xtick, 'xticklabel', xticklabel, 'XTickLabelRotation', 45)

%%
% X = [Horsepower,Weight];
% Y = MPG;
% Mdl = fitrsvm(X,Y);
% Mdl.ConvergenceInfo.Converged
% 
% 
% 
% MdlLin = fitrsvm(X,Y,'Standardize',true,'KFold',5)



