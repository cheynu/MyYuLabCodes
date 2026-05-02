function ProcessLesionData(sessions, lesion_sessions)

% Process lesion data from single rat
% Jianing Yu 5/18/2023

%%  function ComputeKornblumAllSessions

% find out name of the rat
thisFolder = pwd;
if ispc
    thisFolderSplitted = strsplit(thisFolder, '\');
else
    thisFolderSplitted = strsplit(thisFolder, '/');
end;

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
subFolderNames             =        {subFolders(3:end).name};
dataFolderNames            =        {};
for k =1:length(subFolderNames)
    if ~isempty(str2num(subFolderNames{k}))
        dataFolderNames = [dataFolderNames  subFolderNames{k}];
        fprintf('Subfolder #%d = %s \n', k,  subFolderNames{k})
    end;
end
dataFolderNames'

AllSessions = [
%     {'20200512'}
%     {'20200513'}
%     {'20200514'}
%     {'20200515'}
%     {'20200516'}
%     {'20200518'}
%     {'20200519'}
%     {'20200521'}
%     {'20200522'}
%     {'20200523'}
%     {'20200525'}
%     {'20200526'}
%     {'20200527'}
%     {'20200528'}
%     {'20200529'}
%     {'20200530'}
%     {'20200601'}
%     {'20200602'}
%     {'20200603'}
%     {'20200604'}
%     {'20200605'}
%     {'20200606'}
%     {'20200608'}
%     {'20200609'}
%     {'20200611'}
%     {'20200612'}
%     {'20200613'}
%     {'20200615'}
%     {'20200616'}
%     {'20200617'}
%     {'20200618'}
%     {'20200622'}
%     {'20200623'}
%     {'20200624'}
%     {'20200625'}
%     {'20200626'}
    {'20200627'}
    {'20200629'}
    {'20200630'}
    {'20200701'}
    {'20200706'}
    {'20200707'}
    {'20200708'}
    {'20200709'}
    {'20200710'}
    {'20200723'}
    {'20200724'}
    {'20200725'}
    {'20200727'}
    {'20200728'}
    {'20200729'}
    {'20200813'}  % Post lesion day 1
    {'20200814'}
    {'20200815'}
    {'20200816'}
    {'20200817'}
    {'20200818'}
    {'20200819'}
    {'20200820'}
    {'20200821'}
    {'20200822'}
%     {'20200911'}
%     {'20200912'}
%     {'20200914'}
%     {'20200915'}
%     {'20200916'}
%     {'20200917'}
%     {'20200918'}
%     {'20200919'}
%     {'20200921'}
%     {'20200922'}
%     {'20200923'}
%     {'20200924'}
%     {'20200925'}
%     {'20200926'} 
%     {'20201008'}
%     {'20201010'}
%     {'20201020'}
%     {'20201021'}
%     {'20201022'}
%     {'20201023'}
%     {'20201024'}
%     {'20201026'}
%     {'20201027'}
    ];

Post        =   {'20200813'}; % in this rat, two lesions were performed. 
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


% compute group class
% Decide what sessions are treated as pre- or post- sessions

if ispc
    thisFolderSplitted = strsplit(thisFolder, '\');
else
    thisFolderSplitted = strsplit(thisFolder, '/');
end;

ratName = thisFolderSplitted{end};
disp(['this rat is: ', ratName])
savename1 = ['BClassArrayLesion_' upper(ratName)];
savename2 = ['LesionEffect_' upper(ratName)];

disp(savename1)
disp(savename2)
cd(thisFolder)

save (savename1, 'BClassArray')
save (savename2, 'bAllFPsBpod')


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


Second lesion
clear all;
close all;

thisFolder = pwd;
% find out name of the rat
thisFolderSplitted = strsplit(thisFolder, '\');
ratName = thisFolderSplitted{end};
disp(['this rat is: ', ratName])

thisFolder = fullfile(thisFolder, 'SecondLesion')
cd(thisFolder)
 
AllSessions = [
    {'20200815'}
    {'20200816'}
    {'20200817'}
    {'20200818'}
    {'20200819'}
    {'20200820'}
    {'20200821'}
    {'20200822'}
    {'20200911'} % Post second lesion day 1
    {'20200912'}
    {'20200914'}
    {'20200915'}
    {'20200916'}
    {'20200917'}
    {'20200918'}
    {'20200919'}
    {'20200921'}
    {'20200922'}
    {'20200923'}
    {'20200924'}
    {'20200925'}
    {'20200926'} 
 
    ];

Post        =   { '20200911'}; % in this rat, two lesions were performed. 
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
savename1_New = ['BClassArrayLesion_' upper(ratName)];
save (savename1_New, 'BClassArray')

load(savename1_New)
obj=Behavior.SRT.BehaviorGroupClass(BClassArray); % this is the group obj. Note that I am using package mode to organize these data
obj.PreLesionSessions  = (-5:-1);
obj.PostLesionSessions = (1:5);
obj.PreLesionTrialNum  = 500;
obj.PostLesionTrialNum = 500;
obj = obj.FitGauss_Lesion();
obj = obj.CalRTLesion();


obj.PlotPrePostLesion;
obj.PlotPerformanceLesion; 
obj.Save();
obj.Print();

