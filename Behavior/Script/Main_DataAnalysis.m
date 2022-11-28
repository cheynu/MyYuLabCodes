clear;clc;
rng(42); % set seed for reproduction
mfile = mfilename('fullpath');
pathOri = pwd;
%% Parameters
% folder example: pathExp = fullfile(pathSbj,tarSbj{i},subfoldersSuchAsTaskName);
pathTar = {'C:\Users\CY\OneDrive\lab\BehaviorTraining\Data\Mouse_mPFC_DREADD\Astra\SalineDCZ'}; % folders extracting data (if it's empty, it will be generated by pathSbj & pathExp)
pathSbj = 'C:\Users\CY\OneDrive\lab\BehaviorTraining\Data\Rat_mPFC_hM3Dq'; % subject path
pathExp = 'C:\Users\CY\OneDrive\lab\BehaviorTraining\Data\Rat_mPFC_hM3Dq\Lavazza\3FPs'; % example path
pathArc = 'C:\Users\CY\OneDrive\lab\BehaviorTraining\Archive'; % archive path
pathFunArc = 'C:\Users\CY\OneDrive\lab\Codes\CY\Behavior'; % path containing functions, which will be archived if it exists
tarSbj = {'Astra'}; % subjects (folders) need to be processed

typeAll = {'.txt','.mat'}; typeData = typeAll{1}; % data type
isPlotDaily = true;
% Experiment parameters
expName = {'DCZ','Saline'};
expIdx = {[4,7,11,14,17,21,24,27],setdiff(1:27,[4,7,11,14,17,21,24,27])};
% Group parameters
isPlotGroup = false;
grpName = {'hM3D','ChR2'}; % between-subject group's name
grpIdx = {[2 3 6],[1 4 5]}; % same length as grpName, and it need cover all subjects
%% Extract Data & plot for individual
if isfolder(pathFunArc)
    oldpath = addpath(genpath(pathFunArc)); 
end

pathArcReal = fullfile(pathArc,char(datetime('now','format','yyyyMMdd-HHmmss'))); % real archive folder
[~,~] = mkdir(pathArcReal);
if isempty(pathTar)
    [pathTar,orderName,taskSuff,sign] = genTarPath(pathSbj,pathExp,tarSbj);
else
    sign = false;
end

arcData = {};
btAll2d = {};
for i=1:length(pathTar)
    pathData = pathTar{i};
    cd(pathData);
    switch typeData
        case '.txt'
            FileNames = arrayfun(@(x)x.name, dir(fullfile(pathData,'*Subject*.txt')), 'UniformOutput', false);
        case '.mat'
            FileNames = arrayfun(@(x)x.name, dir(fullfile(pathData,'*DSRT*.mat')), 'UniformOutput', false);
        otherwise
            errordlg('Please choose available data types!','Error');
    end
    btAll = cell(1,length(FileNames));
    switch typeData %%%%%%%%%%%%%%Functions to extract data%%%%%%%%%%%%%%%%
        case '.txt'
            for j=1:length(FileNames)
                btAll{j} = med_DataExtract(FileNames{j},isPlotDaily,pathArcReal);
            end
        case '.mat'
            for j=1:length(FileNames)
                btAll{j} = DSRT_DataExtract_Block(FileNames{j},isPlotDaily,pathArcReal);
            end
            btAll = DSRT_DataMerge_Block(btAll,2); % 2:merge data, 3:select the longest data
    end
    % Save data
    savename = append('bmixedAll_',upper(btAll{1}.Subject(1)));
    save(savename,'btAll','-mat');
    
    curCol = size(btAll,2);
    btAll2d(end+1,1:curCol) = btAll;
    arcCol = length(FileNames);
    if sign
        arcData(end+1,1:arcCol) = fullfile(pathData,FileNames)';
    else
        arcData(end+1:end+arcCol) = fullfile(pathData,FileNames)';
    end
    
    cd(pathArcReal);
    %%%%%%%%%%%%%%%%%%%%%%%%%Plot for each subject%%%%%%%%%%%%%%%%%%%%%%%%%
%     BPOD_LearningPlot_Individual(btAll);
%     BPOD_TrialProgress_Individual(btAll);
%     med_LearningPlot_Individual(btAll);
    med_ExpCompare3FPs_Individual(btAll,genVar(expName,expIdx));
end
%% Group plot
cd(pathArcReal);
if ~isPlotGroup || ~sign
    save('bmixedAllsbj','btAll2d');
else
    grpVar = genVar(grpName,grpIdx);
    save('bmixedAllsbj','btAll2d','grpVar');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%Plot for group%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    BPOD_LearningPlot_PairComp(btAll2d,grpVar);
end
%% Backup
copyfile(append(mfile,'.m'),pathArcReal);
if isfolder(pathFunArc)
    zip(fullfile(pathArcReal,'BAK_Func'),pathFunArc);
end
if ~sign
    zip(fullfile(pathArcReal,'BAK_Data'),arcData(isfile(arcData)));
else
    pathTemp = fullfile(pathArcReal,'BAK_Data');
    [~,~] = mkdir(pathTemp);
    for i=1:length(tarSbj)
        pathThisSbj = fullfile(pathTemp,tarSbj{i});
        [~,~] = mkdir(pathThisSbj);
        arcThisData = arcData(i,:);
        arcThisData = arcThisData(isfile(arcThisData(~cellfun(@isempty,arcThisData))));
        for j=1:length(arcThisData)
            copyfile(arcThisData{j},pathThisSbj);
        end
    end
    zip(fullfile(pathArcReal,'BAK_Data'),pathTemp);
    rmdir(pathTemp,'s');
end
if isfolder(pathFunArc)
    path(oldpath);
end
% cd(pathOri);
%% Functions
function [pathTar,orderName,taskSuff,sign] = genTarPath(pathSbj,pathExp,tarSbj)
    orderName = {};
    pathTar = {};
    if isfolder(pathSbj) && isfolder(pathExp)
        sbj_suffix = erase(pathExp,pathSbj);
        ind_sep = find(sbj_suffix==filesep);
        if length(ind_sep)>1
            taskSuff = sbj_suffix(ind_sep(2):end); % erase subject name
        else
            taskSuff = '';
        end
        sbjDir = dir(pathSbj);
        for i=1:length(sbjDir)
            if isequal(sbjDir(i).name,'.') || isequal(sbjDir(i).name, '..') || ~sbjDir(i).isdir
                continue;
            end
            tmp_folder = [pathSbj, filesep, sbjDir(i).name, taskSuff];
            if isfolder(tmp_folder)
                orderName{end+1} = sbjDir(i).name;
            end
        end
        if isempty(orderName)
            sign = false;
        else
            for i=1:length(tarSbj)
                if ismember(tarSbj{i},orderName)
                    pathTar{end+1} = [pathSbj,filesep,tarSbj{i},taskSuff];
                else
                    fprintf('%s was not found\n',tarSbj{i});
                end
            end
            sign = true;
        end
    else
        taskSuff = '';
        sign = false;
    end
end

function Var = genVar(Name,Idx)
Var = {};
for i=1:length(Idx)
    Var(Idx{i}) = Name(i);
end
Var = string(Var);
end