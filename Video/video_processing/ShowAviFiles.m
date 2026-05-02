function [vidFiles, tsFiles, cfolder]=ShowAviFiles(cfolder);


if nargin<1
    [~,path,~] = uigetfile({'*.avi';'*.txt'},...
        'Select any file');

    cfolder = path;
end;

clc
allVidFiles = dir(fullfile(cfolder, 'Cam*.avi'));
if ~isempty(allVidFiles)
    vidFiles = arrayfun(@(x)x.name, allVidFiles, 'UniformOutput',0);
    filetime = cell2mat(arrayfun(@(x)x.datenum, allVidFiles, 'UniformOutput',0));
    [~, indsort] = sort(filetime);
    vidFiles = vidFiles(indsort);
end;

alltsFiles = dir(fullfile(cfolder, 'Cam*.txt'));

if ~isempty(alltsFiles)
    tsFiles = arrayfun(@(x)x.name, alltsFiles, 'UniformOutput',0);
    filetime = cell2mat(arrayfun(@(x)x.datenum, alltsFiles, 'UniformOutput',0));
    [~, indsort] = sort(filetime);
    tsFiles = tsFiles(indsort);
end;

sprintf('%s',cfolder);