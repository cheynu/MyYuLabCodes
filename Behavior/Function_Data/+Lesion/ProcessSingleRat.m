function ProcessSingleRat(LesionSession)

% Jianing Yu
% 
% find out name of the rat
thisFolder = pwd;
thisFolderSplitted = strsplit(thisFolder, '\');

ratName = thisFolderSplitted{end};
disp(['this rat is: ', ratName])
savename1 = ['BClassArrayLesion_' upper(ratName)];
savename2 = ['LesionEffect_' upper(ratName)];

disp(savename1)
disp(savename2)

% Read folders
rootFolder = pwd;
files = dir(rootFolder);
dirFlags = [files.isdir];
subFolders                 =        files(dirFlags);
subFolderNames      =        {subFolders(3:end).name};
dataFolderNames    = {};
for k =1:length(subFolderNames)
    if ~isempty(str2num(subFolderNames{k}))
        dataFolderNames = [dataFolderNames  subFolderNames{k}];
        fprintf('Subfolder #%d = %s \n', k,  subFolderNames{k})
    end;
end
dataFolderNames';
AllSessions = dataFolderNames';

% Show files
Behavior.MED.DisplayMEDs

Post        =   {LesionSession}; % in this rat, two lesions were performed. 
PostMED     =   Behavior.MED.findMEDName(Post); % used in an old code

disp(PostMED)

if length(Post) ==1
    IndLesion = find(strcmp(AllSessions, Post));
else
    IndLesion = cellfun(@(x)find(strcmp(AllSessions, x)), Post);
end;
disp(IndLesion)
BClassArray = {};
iLesion = [];

bAllFPsBpod=struct('Metadata',[],'SessionName',[],'PressTime',[],'ReleaseTime', [],...
    'Correct',[],'Premature',[],'Late',[],'Dark', [],...
    'ReactionTime',[],'TimeTone',[],'IndToneLate',[], 'FPs', []);

for i=1:length(AllSessions)
    cd(fullfile(thisFolder, AllSessions{i}))
    iMED = dir(['*' ratName '.txt']);
    [bAllFPsBpod(i), bc]=Behavior.MED.track_training(iMED.name);
    close all;

    if length(IndLesion)>1
        bc.LesionIndexAll= zeros(1, length(IndLesion));
        % use the first lesion
        % track lesion index
        for k =1:length(IndLesion)
            InLesionFirst = IndLesion(k);

            if i-InLesionFirst<0
                iLesion = i-InLesionFirst;
            else
                iLesion = i-InLesionFirst + 1;
            end;

            if k ==1
                bc.LesionIndex = iLesion;
            end;
            bc.LesionIndexAll(k) = iLesion;
        end;

    else
        % track lesion index
        if i-IndLesion<0
            iLesion = i-IndLesion;
        else
            iLesion = i-IndLesion + 1;
        end;

        bc.LesionIndex = iLesion;
        bc.LesionIndexAll = iLesion;

    end;


    bc.Plot()
    bc.PlotDistribution()
    bc.Print()
    BClassArray{i}= bc;
end;

cd(thisFolder)

save (savename1, 'BClassArray')
save (savename2, 'bAllFPsBpod')

% compute group class
% Decide what sessions are treated as pre- or post- sessions
thisFolder = pwd;
thisFolderSplitted = strsplit(thisFolder, '\');
ratName = thisFolderSplitted{end};
disp(['this rat is: ', ratName])
savename1 = ['BClassArrayLesion_' upper(ratName) '.mat'];

load(savename1)
obj=Behavior.SRT.BehaviorGroupClass(BClassArray); % this is the group obj. Note that I am using package mode to organize these data
obj.PreLesionSessions  = (-5:-1);
obj.PostLesionSessions = (1:5);
obj.PreLesionTrialNum  = 500;
obj.PostLesionTrialNum = 500;
obj = obj.FitGauss_Lesion();
obj = obj.CalRTLesion();


obj.PlotPrePostLesion;
obj.PlotPerformanceLesion;
obj.Print();
obj.Save();