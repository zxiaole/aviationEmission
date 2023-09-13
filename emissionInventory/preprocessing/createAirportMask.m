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

x=ll(1):dx:ur(1);
y=ur(2):-dx:ll(2);
%%
[yn, xn, dust] = size(im);

dximg = dataConfig(1);
dyimg = dximg;
ximg = dataConfig(5);
yimg = dataConfig(6);

ximg = ximg:dximg:(xn-1)*dximg+ximg;
yimg = yimg:-dyimg:-(yn-1)*dyimg+yimg;

%% boundary of airport
BW = roipoly(im);
imagesc(ximg, yimg, BW)
axis xy;

[x, y] = meshgrid(x, y);
[ximg, yimg] = meshgrid(ximg, yimg);

airportBW = interp2(ximg, yimg,double(BW), x, y);
airportBW = airportBW > 0;
xAirportBW = x;
yAirportBW = y;

save airportMask.mat airportBW xAirportBW yAirportBW

