function [fid,lineContent, tline]= readLine(fid)
%% [fid,lineContent]= readLine(fid)
% fid: the identifier of the target file
% lineContent: the cell which contains the valid content of the line

tline = fgetl(fid);
tline = deblank(tline);
tmp = regexp(tline, '#', 'split');
tline = tmp{1};
lineContent = regexp(tline, ',', 'split');
id = cellfun(@(x)isempty(x), lineContent);
lineContent(id) = [];
