function pixelFrequencyFiltered= isolatedMedFilter(pixelFrequency)
%function pixelFrequencyFiltered= noneZeroMedFilter(pixelFrequency,windowSize)
%
% tmpMatrix = pixelFrequency(pixelFrequency>0);
% tmpMatrix = sort(tmpMatrix, 'descend');
% tmpMatrixSum = cumsum(tmpMatrix);
% tmpMatrixSum = tmpMatrixSum/tmpMatrixSum(end);
% id = find(tmpMatrixSum>0.999);
limitV = 0;%tmpMatrix(id(1));
pixelFrequencyFiltered = zeros(size(pixelFrequency));

for i=2:size(pixelFrequency,1)-1
    for j=2:size(pixelFrequency,2)-1
        if(pixelFrequency(i,j)>limitV)
            tmpMM = pixelFrequency(i-1:i+1, j-1:j+1);
            if(sum(tmpMM(:)>limitV)>2)
                pixelFrequencyFiltered(i,j)=pixelFrequency(i,j);
            end
        end
    end
end

end

