function [ receptorNames, receptorCoords ] = readReceptors(  )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

fidin = fopen('Receptor.txt');
[fidin, tmp, tline]= readLine(fidin);
receptorNum = str2num(tmp{1});
receptorNames = cell(receptorNum,1);
receptorCoords = zeros(receptorNum, 2);
for i=1:receptorNum
    [fidin, tmp, tline]= readLine(fidin);
    receptorNames{i} = tmp{end};
    receptorCoords(i,:) = [str2num(tmp{2}) str2num(tmp{3})];
end
fclose(fidin);
end

