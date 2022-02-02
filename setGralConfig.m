function [Gral,sourceNum] = setGralConfig()
%[Gral,sourceNum] = setGralConfig()
%   Dec. 14, Xiaole
% set the parameters of GRAL
Gral.ncols = 1983;
Gral.nrows = 1228;
Gral.xllcorner = 4192580;
Gral.yllcorner = 2694140;
Gral.cellsize = 20;
sourceNum = 6;

xll =Gral. xllcorner:Gral.cellsize:(Gral.xllcorner+Gral.ncols*Gral.cellsize-Gral.cellsize);
yll = Gral.yllcorner:Gral.cellsize:(Gral.yllcorner+Gral.nrows*Gral.cellsize-Gral.cellsize);
[xll, yll] = meshgrid(xll, fliplr(yll));
Gral.xll = xll;
Gral.yll = yll;
end

