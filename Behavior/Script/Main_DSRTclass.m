clear;clc;
rng(42); % set seed for reproduction
mfile = mfilename('fullpath');
pathOri = pwd;
%% Parameters
pathTar = {'C:\Users\CY\OneDrive\lab\BehaviorTraining\Data\Rat_mPFC_Lesion\Kieslowski\DSRT_06_3FPs\Session Data'};
pathFunArc = 'C:\Users\CY\OneDrive\lab\Codes\CY\Behavior'; % path containing functions, which will be archived if it exists


%% Extract Data & plot for individual
if isfolder(pathFunArc)
    oldpath = addpath(genpath(pathFunArc)); 
end

for i=1:length(pathTar)
    pathData = pathTar{i};
    cd(pathData);
    Filenames = arrayfun(@(x)x.name, dir(fullfile(pathData,'*DSRT*.mat')), 'UniformOutput', false);
    bcAll = cell(1,length(Filenames));
    for j=1:length(Filenames)
        bcAll{j} = BehaviorDSRT(Filenames{j});
    end
end
bcIndi = BehaviorDSRT_Indiv(bcAll,'Experiments',repelem(["Saline","DCZ"],16),'Group','Sham');
bcIndi2 = BehaviorDSRT_Indiv(bcAll,'Experiments',repelem(["Saline","DCZ"],16),'Group','Lesion','Subject','Fakerat');
bcGrp = BehaviorDSRT_Group({bcIndi,bcIndi2});