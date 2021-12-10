function [ dataTable] = readAPEXData( filename )
%Dec. 6, 2019, Xiaole Zhang
%   read the data from file, from NASA experiments
%    [ dataTable] = readAPEXData( filename )

dataTable = readtable(filename, 'Delimiter','\t');

dataTable.TempC = covertCell2double( dataTable.TempC );
dataTable.HotV  = covertCell2double(dataTable.HotV);
dataTable.VolV  = covertCell2double(dataTable.VolV);
dataTable.mSO4  = covertCell2double(dataTable.mSO4);
dataTable.mOrg  = covertCell2double(dataTable.mOrg);
dataTable.ColdEIn  = covertCell2double(dataTable.ColdEIn);

dataTable.Sulfur = covertCell2double(dataTable.Sulfur);
dataTable.Aromatics = covertCell2double(dataTable.Aromatics);
dataTable.Naph = covertCell2double(dataTable.Naph);
dataTable.Hydrogen = covertCell2double(dataTable.Hydrogen);
end

