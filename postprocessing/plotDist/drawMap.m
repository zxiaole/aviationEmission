%% draw plots

%%
% This is only an example, and it should be changed to the results generated by annualMeanConc_revise_aromatics.m
load('annualTotalPN_mafor_example.mat') 
% load('../annualTotalPN_mafor_revise_aromatics_withoutMAFOR.mat') 

concTemp = concAll(:,:,1); % the last dimension could be changed to others 1:6, indicating different sources

% load('annualTotalPN.mat')
% concTemp = sum(concAll,3);

concType = 'num'; % 'mass' or 'num'
%% read grad configurations
[Gral,sourceNum] = setGralConfig();

%%
scrsz = get(groot,'ScreenSize');
figure('Position',[1 1 scrsz(3)*0.75 scrsz(4)*0.75])
backgroundFileName = 'gralBackground.jpg';

%% Image domain configuration
im = imread(backgroundFileName);
im = uint8(mean(im,3));


geocoord = load([backgroundFileName(1:end-4) '.jgw']);
img.dx = geocoord(1);
img.xorig = geocoord(5);
img.yorig = geocoord(6);
x = img.xorig:img.dx:(img.xorig + size(im,2)*img.dx - img.dx);
y = img.yorig:-img.dx:(img.yorig - size(im,1)*img.dx + img.dx);
[img.x,img.y] = meshgrid(x, y);

imagesc(x, y, repmat(im,1,1,3))
axis equal
axis tight
hold on
%%
hold on
plotForTheMap(concTemp, Gral, img)
%%
%% Define the locations of the receptors
[ receptorNames, receptorCoords ] = readReceptors( );

receptorN = length(receptorNames);
receptorPixelsX = receptorCoords(:,1);%(receptorCoords(:,1) - img.xorig)/img.dx;
receptorPixelsY = receptorCoords(:,2);% (img.yorig - receptorCoords(:,2))/img.dx;
scatter(receptorPixelsX, receptorPixelsY,80, '+', 'k', 'LineWidth', 2)
for i=1:receptorN
    spaceN =0;
    names = regexp(strtrim(receptorNames{i}), ' ', 'split');
    for j=1:length(names)
        spaceN = max(spaceN, length(names{j}));
    end
    spaceN = min(10, spaceN);
    if(strcmp(names, 'Apron'))
        text(receptorPixelsX(i)+150,receptorPixelsY(i)+200, names , 'FontWeight', 'bold', 'FontSize', 12)
    else
        text(receptorPixelsX(i)+150,receptorPixelsY(i)-200, names , 'FontWeight', 'bold', 'FontSize', 12)
    end
end
interp2(Gral.xll,Gral.yll,concTemp,receptorCoords(:,1), receptorCoords(:,2))
%%
regionId =15;

%%
filename ='ZurichRegions/zurich.shp';

info = shapeinfo(filename);
roi = shaperead(filename);
tp = 250;
for regionId=1:length(roi)
    rx = roi(regionId).X(1:end-1);
    ry = roi(regionId).Y(1:end-1);
    plot(rx, ry, '-', 'color', [0.5 0.5 0.5], 'linewidth', 0.5)
    xx = mean(rx)-length(roi(regionId).NAME)*150;
    yy = mean(ry)+tp;
    tp = -tp;
    
    if(4.195*10^6<xx&& xx<4.225*10^6&& 2.695*10^6<yy&& yy<2.718*10^6)
        
        if(strcmp(roi(regionId).NAME, 'Rorbas'))
            text(xx, yy+tp, roi(regionId).NAME)
        else
            text(xx, yy, roi(regionId).NAME)
        end
    end
    
end