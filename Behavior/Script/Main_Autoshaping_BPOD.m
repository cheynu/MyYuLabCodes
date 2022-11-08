clear;clc;
rng(20221011); % Set the random seed for reproducibility of the results
rpath = pwd; % rootpath
%% Initiate
% path_functions = fullfile(rpath,'0_Functions');addpath(path_functions);
path_archive = fullfile(rpath,'1_Archive');
if ~isfolder(path_archive)
    mkdir(path_archive);
end

Subjects = {'Lavazza','Moriarty','Nave','Orange','Pericles','Quarantelli','Rebel','Strangelove'};
subfolder = 'Autoshaping';
plotmark = true;
%%
tarPath = {};
for i=1:length(Subjects)
    tarPath{i} = fullfile(rpath,Subjects{i},subfolder);
end
%% Extract Data
btAll2d = {}; % 'b'pod 't'able Allsessions 2d(for all subjects)
for ipath=1:length(tarPath) % Extract the raw data & packaging
    dataPath = tarPath{ipath};
    cd(dataPath);
    % extract and processing
    FileNames = arrayfun(@(x)x.name, dir('*DSRT*.mat'), 'UniformOutput', false);
    btAll_raw = cell(1,length(FileNames));
    for i=1:length(FileNames)
        btAll_raw{i} = DSRT_DataExtract_Autoshaping(FileNames{i},plotmark);
    end
    % merge multiple files of one day into one file
    btAll = DSRT_DataMerge_Autoshaping(btAll_raw,2);
    % Save
    savename = 'bmixedAll_' + upper(btAll{1}.Subject(1)); %tarPath{ipath,2}
    save(savename, 'btAll');
    btAll2d(end+1,1:length(btAll)) = btAll;
    
    % Plot (individual)
    % add function to plot for each subject, such as:
    % BPOD_AutoshapingPlot_Individual(btAll,path_archive);
end
save(fullfile(path_archive,'bmixedAllsbj.mat'),'btAll2d','tarType');
%% Plot (group)
cd(path_archive);
load('bmixedAllsbj.mat');

% add function to plot for group, such as: 
% BPOD_AutoshapingPlot_Group(btAll2d,DCZvar,path_archive);