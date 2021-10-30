function [x,y,hImage] = drawBackground(imageFile, alpha, fontsize)
%[x,y,hImage] = drawBackground(imageFile)
%   draw the background image with geoinformation
im = imread(imageFile);
dataConfig = importdata([imageFile(1:end-4) '.jgw']);

[yn, xn, dust] = size(im);

dx = dataConfig(1);
dy = dx;
x = dataConfig(5);
y = dataConfig(6);

x = x:dx:(xn-1)*dx+x;
y = y:-dy:-(yn-1)*dy+y;

figsize = [100 100 xn yn];
figure('position', figsize)
hImage = imagesc(x, y, im, 'alphadata', alpha);
axis equal
axis tight
axis xy
% set(gca, 'xlim', [min(obsx)-100, max(obsx)+100], 'ylim', [min(obsy)-100, max(obsy)+100])
xlabel('Longitude')
ylabel('Latitude')
set(gca,'fontname', 'arial', 'FontSize',fontsize)

end

