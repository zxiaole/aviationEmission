function plotForTheMap(conc, Gral, img)
% Dec. 30, 2019, Xiaole Zhang
% Modified to draw the distribution plot

fontsize = 18;
load rodosColorMap.mat
colormap(colormapRodos/255);
conclog = log10(conc+eps);

vmin = 2.0;
dv = 0.25;
id = find(conclog<vmin);
conclog(id) = nan;
conclog(1) = 4.75;
conclog(2) = vmin;
v = vmin:dv:(vmin+11*dv);% linspace(2.75, 6.0, 12);
maxTick = (vmin+11*dv);

[~, hContour]=contourf(Gral.xll, Gral.yll, (conclog), v, 'linecolor', 'none');
drawnow;  % this is important, to ensure that FacePrims is ready in the next line!
%%
% npixels = 2000/img.dx;
% xpixel = 1100;
% ypixel = 700;
% line([xpixel xpixel+npixels], [ypixel ypixel], 'linewidth', 5, 'color', [0 0 0])
% text(xpixel + npixels/4,ypixel-20,'2 km' , 'FontWeight', 'bold', 'FontSize', 15)
%%
axis xy
axis equal
axis tight
axis([4.195 4.23 2.695 2.718]*10^6)
%
% tt = (0:2000:18854);
% xticks = 200+ tt/img.dx;
% set(gca, 'xtick', xticks, 'xticklabel', num2str(tt'/1000), 'fontsize', fontsize);
%
% tt = (0:2000:11827);
% yticks = 110+ tt/img.dx;
% set(gca, 'ytick', yticks, 'yticklabel', num2str(tt'/1000), 'fontsize', fontsize);
set(gca, 'ytick', (2.695:0.005:2.718)*10^6,'fontname', 'arial', 'fontsize', fontsize);
xlabel('West-East (m)', 'fontsize', fontsize);
ylabel('South-North (m)', 'fontsize', fontsize);
% axis off
pause(2)

h2=cbarrow2();
pause(2)

%%
h=gcf;
c=get(h,'children'); % Find allchildren
cb=findobj(h,'Tag','Colorbar'); % Find thecolorbar children
barTicks = cb.Ticks;
for i=1:length(barTicks)
    cb.TickLabels{i} = ['10^{' num2str(barTicks(i)) '}'];
    cb.FontSize = fontsize;
    cb.FontName = 'Arial';
end

cb.Label.String = 'Num conc(# cm^{-3})';
cb.Label.Rotation = 0;
cb.Label.Position = [2.2 maxTick+0.2 0];


alphaV = 150;
hFills = hContour.FacePrims;  % array of TriangleStrip objects
[hFills.ColorType] = deal('truecoloralpha');  % default = 'truecolor'
for idx = 1 : numel(hFills)
    hFills(idx).ColorData(4) = alphaV;   % default=255
end
drawnow;


alphaVal = alphaV/255;
% Get the color data of the object that correponds to the colorbar
cdata = h2.Face.Texture.CData;
% Change the 4th channel (alpha channel) to 10% of it's initial value (255)
cdata(end,:) = uint8(alphaVal * cdata(end,:));
% Ensure that the display respects the alpha channel
h2.Face.Texture.ColorType = 'truecoloralpha';
% Update the color data with the new transparency information
h2.Face.Texture.CData = cdata;
drawnow;
h2.Face.ColorBinding = 'discrete';


end

