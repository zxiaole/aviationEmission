function pixelFrequencyFiltered= noneZeroMedFilterEmission(pixelFrequency,windowSize)
%function pixelFrequencyFiltered= noneZeroMedFilter(pixelFrequency,windowSize)
%

limitV = 0;

lowSize =floor(windowSize/2);
highSize = ceil(windowSize/2);
pixelFrequencyFiltered = zeros(size(pixelFrequency));
for i=highSize+1:size(pixelFrequency,1)-highSize-1
    for j=highSize+1:size(pixelFrequency,2)-highSize-1
        if(pixelFrequency(i,j)>limitV)
                tmpM = pixelFrequency(i-lowSize:i+lowSize, j-lowSize:j+lowSize);
                pixelFrequencyFiltered(i,j)=mean(tmpM(tmpM(:)>limitV));
        end
    end
end

end

