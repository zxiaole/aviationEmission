function [outputData, outputN] = downScaleM(data, nfactor)
%[outputData] = downScaleM(data, nfactor)
%   decrease the resolution of data by a factor of nfactor
[m, n] = size(data);

mN = floor(m/nfactor);
nN = floor(n/nfactor);

outputData = zeros(mN, nN);
outputN = zeros(mN, nN);

for i=1:mN
    for j=1:nN
        subData = data((i-1)*nfactor+1:i*nfactor, (j-1)*nfactor+1:j*nfactor);
        outputData(i, j) = sum(subData(:));
        outputN(i, j) = sum(subData(:)>0);
    end
end
end

