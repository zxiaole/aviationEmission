%% Mar. 24, 2020, Xiaole Zhang
% Develop method to estimate the particle number emission of volatile
% particels, investigate the three influence factors: (1) thrust level; (2)
% fuel sulfur composition; (3) temperature.
%% April 2, 2020, Xiaole Zhang
% Anova test

%% April 8, 2020, Xiaole Zhang
% evaluate the maxium thrust dependence

%%
clear
close all

%% basic configurations
capsize = 10;
linewidth = 1.5;
markersize = 14;
fontsize = 16;
thrustLevels = [7, 4, 30, 65, 85, 100];

% raw data directories
dataFolder = 'rawData';
APEXFolder = 'APEX&AAFEX';
LAXFolder = 'LAX';
LAXFileName = 'LAX-Ground-Summary_TP_20140518_R01_thru20140525.xlsx';

%% read data from LAX experiment
sul_LAX = [];
tmp_LAX = [];
ein_LAX = [];
einAct_LAX = [];
Aromatics_LAX = [];
naph_LAX = [];
thrusts_LAX = [];
hydrogen_LAX = [];

fig = figure('position', [100 100 450 500]);

filename = fullfile(dataFolder, LAXFolder, LAXFileName);
dataLAX = readtable(filename,'Sheet','LAX_Data');

manufacturesLAX = dataLAX.Aircraft_Manufacturer;
eiNLAX = dataLAX.EI_Number_Total;

ein_LAX = (eiNLAX);
uniqueManufacturesLAX = unique(manufacturesLAX);
LAXEngine = dataLAX.Engine_Model_Series;

naph_fuel = [0.81 1.31 0.63 0.63 2.8 2.2];
naph_LAX = 1.1*ones(size(ein_LAX)); % scentific data

thrusts_LAX =ones(size(ein_LAX))*100;

arom_fuel = [17.7 18.5 12 17.6 23 22.6];

Aromatics_LAX = ones(size(ein_LAX))*median(arom_fuel); % scentific data
hydrogen_LAX = ones(size(ein_LAX))*13.8;
tmp_LAX = ones(size(ein_LAX))*22.5;

sufl_fuel = [1530 1280 710 620 1600 1780];
% sul_LAX = mean(sufl_fuel) + randn(size(ein_LAX))*std(sufl_fuel); % scentific data
sul_LAX = ones(size(ein_LAX))*mean(sufl_fuel) ; % scentific data


%% read data from APEX, AAFEX experiments. Plot the influence of temperature and sulfur content
figure
symbols = {'o', 'd', 's','o', 'd', 's'};
colors = {'r', 'g', 'b','r', 'g', 'b'};
sul = [];
tmp = [];
ein = [];
einAct = [];
Aromatics = [];
naph = [];
thrusts = [];
hydrogen = [];
for i=2:-1:1
    filenameAll{i} = fullfile(dataFolder, APEXFolder, ['power' num2str(thrustLevels(i)) '.txt']);
    [ dataTable] = readAPEXData( filenameAll{i});
    refId = dataTable.Sulfur<=1500 ...
        &dataTable.Sulfur>=600 ...
        &dataTable.Aromatics>=0 ...
        &dataTable.Aromatics<=25 ...
        &dataTable.Naph>0 ...
        &~isnan(dataTable.ColdEIn) ...
        &~isnan(dataTable.TempC) ...
        &dataTable.TempC>0 ...
        &dataTable.Hydrogen>0;
    refEiN = 1;% mean(dataTable.ColdEIn(refId));
    id = dataTable.Sulfur>=00 ...
        &dataTable.Sulfur<=1500 ...
        &~(dataTable.Sulfur==1148&dataTable.ColdEIn<2*10^16) ...
        &dataTable.Aromatics>=0 ...
        &dataTable.Aromatics<=35 ...
        &dataTable.Naph>0 ...
        &~isnan(dataTable.ColdEIn) ...
        &~isnan(dataTable.TempC)...
        &dataTable.Hydrogen>0 ...
        &dataTable.ColdEIn<9*10^16;
    %     h2 = errorbar(thrustLevels(i), mean(dataTable.ColdEIn(id)), std(dataTable.ColdEIn(id)), ...
    %         'ro', 'markersize', markersize, 'markerfacecolor', 'r', 'markeredgecolor', 'k', 'linewidth', linewidth , 'capsize', capsize);
    
    sul = [sul; dataTable.Sulfur(id)];
    tmp = [tmp; dataTable.TempC(id)];
    ein = [ein; dataTable.ColdEIn(id)/refEiN];
    einAct = [einAct;dataTable.ColdEIn(id) ];
    Aromatics = [Aromatics; dataTable.Aromatics(id) ];
    naph = [naph; dataTable.Naph(id)];
    thrusts = [thrusts; ones(size(dataTable.Aromatics(id)))*thrustLevels(i)];
    hydrogen = [hydrogen; dataTable.Hydrogen(id)];
    
    plot(dataTable.Sulfur(id), dataTable.ColdEIn(id)/refEiN, symbols{i},  'markersize', markersize, 'markerfacecolor', 'none', 'markeredgecolor', colors{i} );
    hold on
    dataTable.ColdEIn(~id) = nan;
    dataTable.Sulfur(~id) = nan;
    allData{i} = dataTable;
end


%% aromatics, thrusts (fitting the relation)
modelFunEIn =  @(q,x)q(1)./(1+exp(q(2)*x(:,1)+q(3)))...
    .*exp(x(:,2)*q(4)+x(:,3)*q(5)+x(:,4).^1*q(6));
startingVals = [0.9136   -0.0109    2.7761   -0.0084  0  0 ];
totalData = [[sul tmp    thrusts Aromatics]; ...
    [sul_LAX tmp_LAX     thrusts_LAX Aromatics_LAX]  ];
[coefEstsGSD,resid,J,Sigma] = nlinfit(totalData, [ein;ein_LAX]/10^16, modelFunEIn, startingVals);
emissionFactorsCoef = coefEstsGSD;
save emissionCoef_aromatics.mat emissionFactorsCoef resid J Sigma

t = 0:5:30;
s = ones(size(t))*650;
naphZurich =ones(size(t))*1.1;
aromaticsZurich = ones(size(t))*18;
thrustsZurich  = ones(size(t))*7;
hydrogenZurich  = ones(size(t))*13.8;
[ypred2, delta] = nlpredci(modelFunEIn,[s(:) t(:)  thrustsZurich(:) aromaticsZurich(:)], coefEstsGSD, resid, 'jacobian',J);
plot(t, ypred2, '-')

[ypred, delta] = nlpredci(modelFunEIn,totalData, coefEstsGSD, resid, 'jacobian',J);

figure('position', [100 100 550 500])
id =1:length(ein);
h1=plot( ypred(id)*10^16 , [ein], ...
            'bo', 'markersize', 8, 'markerfacecolor', 'b', 'markeredgecolor', 'k');
bounds = [15.8 17.0];

set(gca, 'xscale', 'log', 'yscale', 'log', 'xlim', 10.^bounds, 'ylim',10.^bounds)
hold on
plot(10.^bounds,10.^bounds, 'k-', 'linewidth', 2)
plot(10.^bounds,10.^bounds*2, 'k--', 'linewidth', 2)
plot(10.^bounds,10.^bounds/2, 'k--', 'linewidth', 2)

errorbar( mean(ypred(id(end):end))*10^16,mean(ein_LAX),std(ein_LAX), 'r-', 'linewidth',2);
h2=plot( mean(ypred(id(end):end))*10^16,mean(ein_LAX), 'rs', 'markersize', 12 , 'markerfacecolor', 'r', 'markeredgecolor', 'k');

bl = legend([h1, h2], {'APEX, AAFEX I&II' 'LAX experiments'}, 'fontname', 'Arial', 'fontweight', 'normal', 'fontsize', fontsize, 'location', 'northwest');
set(bl, 'box', 'off')
ylabel('Measured emission index (kg^{-1}-fuel)')
xlabel({'Regression model (kg^{-1}-fuel)'})
set(gca, 'fontname', 'Arial', 'fontweight', 'normal', 'fontsize', fontsize);

set(gcf,'PaperPositionMode','auto')
print('regression_model','-dpng','-r300')

%% plot correlation between aromatics and hydrogen content
figure
coefs = polyfit(Aromatics, hydrogen,1);
x = 5:25;
y = polyval(coefs, x);

plot(x,y, 'k-', 'linewidth', 2)
hold on
plot(Aromatics,hydrogen, ...
            'ro', 'markersize', markersize, 'markerfacecolor', 'r', 'markeredgecolor', 'k');
box on

ylabel('Hydrogen mass content (%)')
xlabel({'Aromatics volume content (%)'})
set(gca, 'xlim', [5 25], 'ylim', [13 15], 'fontname', 'Arial', 'fontweight', 'normal', 'fontsize', fontsize);


set(gcf,'PaperPositionMode','auto')
print('Aromatics_hydrogen','-dpng','-r300')


