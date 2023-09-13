load  02a186.mat
outputName = 'output.gif';
im = imread('airportBackground.jpg');
dataConfig = importdata('airportBackground.jgw');
%%
dx = 0.00005;
ll = [8.53 47.44];%[min(lon(:))-dx/2 min(lat(:))-dx/2];
ur = [8.58 47.49];%[max(lon(:))+dx/2 max(lat(:))+dx/2];
rEarth = 6400000; % meters of earth radius
xDegreeToDistance = rEarth*cos((ll(2)+ur(2))/2/180*pi)*1/180*pi;
yDegreeToDistance = rEarth*1/180*pi;

xl=ll(1):dx:ur(1);
yl=ur(2):-dx:ll(2);
%%
[yn, xn, dust] = size(im);

dximg = dataConfig(1);
dyimg = dximg;
ximg = dataConfig(5);
yimg = dataConfig(6);

ximg = ximg:dximg:(xn-1)*dximg+ximg;
yimg = yimg:-dyimg:-(yn-1)*dyimg+yimg;

%% boundary of airport
h=imagesc(xl,yl,im);
axis xy
BWAll = false(size(im,1),size(im,2));
[x, y] = meshgrid(xl, yl);
[ximg, yimg] = meshgrid(ximg, yimg);
for i=1:6
    set(0, 'CurrentFigure', gcf)
    BW = roipoly();
    BWAll = BWAll | BW;   
end

imagesc( BWAll)
axis xy;
pushBackBW = interp2(ximg, yimg, double(BWAll), x, y);
pushBackBW = pushBackBW > 0;

promptMessage = sprintf('Draw self power region \nor Quit?');
titleBarCaption = 'Continue?';
button = questdlg(promptMessage, titleBarCaption, 'Continue', 'Continue');
%%
close all
h=imagesc(xl,yl,im);
axis xy
BWAll = false(size(im,1),size(im,2));

for i=1:3
    BW = roipoly();
    BWAll = BWAll | BW;
end

imagesc(BWAll)
axis xy;
selfPowerBW = interp2(ximg, yimg,double(BWAll), x, y);
selfPowerBW = selfPowerBW > 0;
xBW =x;
yBW =y;

save pushMask.mat selfPowerBW pushBackBW xBW yBW