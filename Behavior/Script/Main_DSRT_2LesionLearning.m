%% Initiate
clear;clc;
rng('default'); % Set the random seed for reproducibility of the results

path_functions = 'C:\Users\CY\OneDrive\lab\BehaviorTraining\TrainingAnalysis\Code;C:\Users\CY\OneDrive\lab\BehaviorTraining\TrainingAnalysis\Code\Function_Data;C:\Users\CY\OneDrive\lab\BehaviorTraining\TrainingAnalysis\Code\Function_Plot;C:\Users\CY\OneDrive\lab\BehaviorTraining\TrainingAnalysis\Code\Function_Plot\Group;C:\Users\CY\OneDrive\lab\BehaviorTraining\TrainingAnalysis\Code\Function_Plot\Individual;C:\Users\CY\OneDrive\lab\BehaviorTraining\TrainingAnalysis\Code\Function_Tool;C:\Users\CY\OneDrive\lab\BehaviorTraining\TrainingAnalysis\Code\Function_Tool\matplotlib3.3_colormap_for_matlab;';

sbjPath = 'C:\Users\CY\Desktop\20220403\Rats';
examplePath = 'C:\Users\CY\Desktop\20220403\Rats\Hsiao-hsien\Analysis';

AnalysisSbj = {'Hsiao-hsien','Ingmar','Kieslowski','Leonard','Matias','ONeal','Nicola'};
grpVar_le1 = ["Sham";"Lesion";"Sham";"Lesion";"Sham";"Lesion";"Sham"];
grpVar_le2 = ["Lesion";"Sham";"Sham";"Sham";"Sham";"Sham";"Lesion"];
grpVar = [grpVar_le1,grpVar_le2];
%% Extract Data
addpath(path_functions);
[tarPath,orderName] = genTarPath(sbjPath,examplePath,AnalysisSbj);

idx = zeros(1,length(orderName));
for i=1:length(AnalysisSbj)
    idx(i) = find(ismember(orderName,AnalysisSbj{i}));
end
tarPath = tarPath(idx);
orderName = orderName(idx);

btAll2d = {};
for i=1:length(tarPath)
    dataPath = tarPath{i};
    cd(dataPath);
    
    FileNames = arrayfun(@(x)x.name, dir('*DSRT*.mat'), 'UniformOutput', false);
    btAll_raw = cell(1,length(FileNames)); % 'b'pod 't'able
    for i=1:length(FileNames)
        btAll_raw{i} = DSRT_DataExtract_Block(FileNames{i},false);
    end
    btAll = DSRT_DataMerge_Block(btAll_raw,2); % merge multiple files of one day
    
    savename = 'bmixedAll_' + upper(btAll{end}.Subject(1));
    save(savename, 'btAll')
    
    btAll2d(end+1,1:length(btAll)) = btAll;
end
%% Plot
plotFunction(btAll2d,grpVar);

%% Functions
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