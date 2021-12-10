function [ outputData] = covertCell2double( inputData )
%   Dec. 4, 2019, Xiaole Zhang
%   [ outputData] = covertCell2double( inputData )
%   Covert the potential cell data to double
if(iscell( inputData))
    outputData  = cellfun(@str2double, inputData );
elseif(isa(inputData, 'numeric'))
    outputData = inputData;
else
    error('No type found for inputData')
end


end