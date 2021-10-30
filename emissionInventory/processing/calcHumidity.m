function [humidity] = calcHumidity(T,Td)
% [humidity] = calcHumidity(T,Td)
% T: temperature (K); Td: dew point temperature (K)
% HUMIIDTY: % 
%   https://iridl.ldeo.columbia.edu/dochelp/QA/Basic/dewpoint.html
%  Relative humidity gives the ratio of how much moisture the air is holding to how much moisture it could hold at a given temperature.
% 
% This can be expressed in terms of vapor pressure and saturation vapor pressure:
% 
% RH = 100% x (E/Es)
% 
% where, according to an approximation of the Clausius-Clapeyron equation:
% 
% E = E0 x exp[(L/Rv) x {(1/T0) - (1/Td)}] and
% 
% Es = E0 x exp[(L/Rv) x {(1/T0) - (1/T)}]
% 
% where E0 = 0.611 kPa, (L/Rv) = 5423 K (in Kelvin, over a flat surface of water), T0 = 273 K (Kelvin)
% 
% and T is temperature (in Kelvin), and Td is dew point temperature (also in Kelvin). 
E0 = 0.611;
LRV = 5423;
T0 = 273;

E = E0*exp(LRV*(1./T0-1./Td));
Es = E0*exp(LRV*(1./T0-1./T));
humidity = E./Es*100;
end

