clear;clc;
rng('default'); % Set the random seed for reproducibility of the results
%% Initiate
mfile = mfilename('fullpath');
[mpath,~,~] = fileparts(mfile);

path_functions = fullfile(mpath,'0_Functions'); % 'C:\Users\CY\Desktop\20220403\Mice\0_Functions';
path_archive = fullfile(mpath,'1_Archive'); % 'C:\Users\CY\Desktop\20220403\Mice\1_Archive';
sbjPath = mpath; % 'C:\Users\CY\Desktop\20220403\Mice';
examplePath = fullfile(mpath,'38\Analysis');% 'C:\Users\CY\Desktop\20220403\Mice\38\Analysis';

AnalysisSbj = {'38','42','Mold','Novel','Roy','Tyrell','Vigor'};
grpVar = ["Lesion";"Sham";"Lesion";"Sham";"Lesion";"Sham";"Lesion"];
global lesionBoundary;
lesionBoundary = 20211229; % the day before the first session after lesion
sessNearBound = 7;
%% Extract Data
addpath(path_functions);
[tarPath,orderName] = genTarPath(sbjPath,examplePath,AnalysisSbj);
% sort
idx = zeros(1,length(orderName));
for i=1:length(AnalysisSbj)
    idx(i) = find(ismember(orderName,AnalysisSbj{i}));
end
tarPath = tarPath(idx);
orderName = orderName(idx);
% extract
btAll2d = {};
for ipath=1:length(tarPath)
    dataPath = tarPath{ipath};
    cd(dataPath);
    
    FileNames = arrayfun(@(x)x.name, dir('*Subject*.txt'), 'UniformOutput', false);
    btAll = cell(1,length(FileNames));
    for i=1:length(FileNames)
        btAll{i} = med_DataExtract(FileNames{i},false);
    end

    savename = 'bmixedAll_' + upper(btAll{1}.Subject(1));
    save(savename, 'btAll')
    
    btAll2d(end+1,1:length(btAll)) = btAll;
end
task2d = cellfun(@(in) getTask(in),btAll2d,'UniformOutput',false);
sessAfter2les = find(ismember(task2d(1,:),'ThreeFPsMixedBpod_les'),1,'first');
plotRange = sessAfter2les-sessNearBound:sessAfter2les+sessNearBound-1;

save(fullfile(path_archive,'bmixedAllsbj.mat'),'btAll2d','grpVar','plotRange','task2d');
%% Plot
cd(path_archive);
load('bmixedAllsbj.mat');

med_plotLee2Vigor(btAll2d,grpVar,plotRange);
%% Functions
function out = getTask(in)
    global lesionBoundary;
    if ~isempty(in)
        out = char(in.Task(1));
        date = in.Date(1);
        if strcmp(out,"ThreeFPsMixedBpod") && date>lesionBoundary
            out = 'ThreeFPsMixedBpod_les';
        end
    else
        out = '';
    end
end

function [tarPath,orderName] = genTarPath(sbjPath,examplePath,nameFilter)
switch nargin
    case 2
        nameFilter = {};
    case 3
        % pass
end

sbj_suffix = erase(examplePath,sbjPath);
ind_sep = find(sbj_suffix==filesep);
if length(ind_sep)>1
    task_suffix = sbj_suffix(ind_sep(2):end); % erase subject name
else
    task_suffix = '';
end

sbjDir = dir(sbjPath);
tarPath = {};
addd = 1;
orderName = {};
for i=1:length(sbjDir)
    if isequal(sbjDir(i).name,'.') || isequal(sbjDir(i).name, '..') || ~sbjDir(i).isdir
        continue;
    end
    if ~isempty(nameFilter) && ~ismember(sbjDir(i).name,nameFilter)
        continue;
    end
    tmp_folder = [sbjPath, filesep, sbjDir(i).name, task_suffix];
    if isfolder(tmp_folder)
        
        tarPath{addd} = tmp_folder;
        orderName{addd} = sbjDir(i).name;
        addd = addd + 1;
    end
end

end
