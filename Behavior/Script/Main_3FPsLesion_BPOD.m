clear;clc;
rng(20220819); % Set the random seed for reproducibility of the results
rpath = pwd; % rootpath
%% Initiate
path_functions = fullfile(rpath,'0_Functions');addpath(path_functions);
path_archive = fullfile(rpath,'1_Archive');

GroupName = {'Lesion','Sham'};
PeriodName = {'Pre','Post'};
prdVar = {1:8,9:16};

plotRange = 2:15;
%% Extract Data
tarPath = {};
for i=1:length(GroupName) % Get each subject's data folder & grouping info
    grpName = GroupName{i};
    grpPath = fullfile(rpath,grpName);
    grpDir = dir(grpPath);
    for j=1:length(grpDir)
        if ~grpDir(j).isdir || strcmp(grpDir(j).name,'.') || ...
                strcmp(grpDir(j).name, '..') || strcmp(grpDir(j).name,'0_shelve')
            continue;
        end
        sbjDir = fullfile(grpPath,grpDir(j).name);
        if isfolder(sbjDir)
            tmpInfo = {sbjDir,grpDir(j).name,grpName};
            tarPath(end+1,1:3) = tmpInfo;
        end
    end
end

btAll2d = {}; % 'b'pod 't'able Allsessions 2d(for all subjects)
for ipath=1:size(tarPath,1) % Extract the raw data & packaging
    dataPath = tarPath{ipath,1};
    grpName = tarPath{ipath,3};
    cd(dataPath);
    % extract and processing
    FileNames = arrayfun(@(x)x.name, dir('*DSRT*.mat'), 'UniformOutput', false);
    btAll_raw = cell(1,length(FileNames));
    for i=1:length(FileNames)
        btAll_raw{i} = DSRT_DataExtract_Block(FileNames{i},false);
    end
    % merge multiple files of one day into one file
    btAll_merge = DSRT_DataMerge_Block(btAll_raw,2);
    % add group information to data file
    btAll = cell(1,length(btAll_merge));
    for i=1:length(btAll_merge)
        bt = btAll_merge{i};
        for j=1:length(prdVar)
            if ismember(i,prdVar{j})
                dateGrp = PeriodName{j}; % Pre/Post
                newVars = repelem(strcat(string(grpName),'-',string(dateGrp)),size(bt,1))';
                break;
            end
        end
        btAll{i} = addvars(bt,newVars,'After','Date','NewVariableNames','Group');
    end

    % Save
    savename = 'bmixedAll_' + upper(btAll{1}.Subject(1)); %tarPath{ipath,2}
    save(savename, 'btAll');
    btAll2d(end+1,1:length(btAll)) = btAll;
end
save(fullfile(path_archive,'bmixedAllsbj.mat'),'btAll2d','plotRange');
task2d = cellfun(@(in) getGroup(in),btAll2d,'UniformOutput',false); % for check
%% Plot
cd(path_archive);
load('bmixedAllsbj.mat');

plotLesionAfterLearning(btAll2d,plotRange);
%% Functions
function out = getGroup(in)
    if ~isempty(in)
        out = char(in.Group(1));
    else
        out = '';
    end
end