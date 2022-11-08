clear;clc;
path_func = 'C:\Users\CY\OneDrive\lab\Codes\CY\Video\DLCplot';addpath(path_func);
rpath = pwd;
path_figsave = fullfile(rpath,'Figures');

sbjName = 'Matias';
PrefPaw = 1; % 1:left, 2:right, 3:both
pathAll = {'20220323','20220324','20220404','20220405','20220406','20220408'};
grpName = {'PreLesion','PostLesion'};
grpVar = {1:2,3:6};

defaultSize = [708 851]; % [1134,1361], unify the video frame size
x_range = [100 750];
y_range = [150 700];
t_range = [-300 200];
t_endpoints = [-50,-100,-150];
%% Manual track results
for i=1:length(pathAll)
    TrackingResults = arrayfun(@(x)fullfile(x.folder,x.name),...
        dir(fullfile(rpath,pathAll{i},'*.xlsx')),'UniformOutput', false);
    TrackingResult = TrackingResults{1};
    if i==1
        PressOut = ExtractMovementParams(TrackingResult,path_figsave);
    else
        PressOut(i) = ExtractMovementParams(TrackingResult,path_figsave);
    end
end
save(fullfile(rpath,'PressOut.mat'),'PressOut');

IndPost = grpVar{2}(1); % the first post-lesion session is the xth session
IndPreLesion = grpVar{1};
IndPostLesion = grpVar{2};
PlotManualTrackingPressOut(PressOut, PrefPaw, IndPost, IndPreLesion, IndPostLesion, path_figsave);
%% DLC results
try
    load(fullfile(rpath,'PressOut.mat'),'PressOut');
    msfilter = true;
catch
    msfilter = false;
end
fPre = 1;fPost = 1;
for i=1:length(pathAll)
    % load DLC data
    datapath = fullfile(rpath,pathAll{i});
    dlc = load(fullfile(datapath,'DLCTrackingOut.mat'),'DLCTrackingOut');
    dlc = unifyDLCformat(dlc);
    % modify data if needed
    if ~isempty(defaultSize)
        dlc = rescaleDLCdata(dlc,defaultSize);
    end
    if msfilter
        dlc = DLCfilter(dlc,PressOut(i),'pressPaw','L');% ,'outcome',{'cor','late'});
    end
    % create PawTraj obj & plot
    Dobj = PawTraj(dlc);
    Dobj.Subject = sbjName;
    Dobj.x_range = x_range;
    Dobj.y_range = y_range;
    Dobj.t_range = t_range;
    Dobj.t_endpoints = t_endpoints;
    for j=1:length(grpVar)
        if ismember(i,grpVar{j})
            Dobj.Treatment = grpName{j};
            break;
        end
    end
    Dobj.plot;
    Dobj.print;
    Dobj.save;
    % assemble data across sessions
    switch Dobj.Treatment
        case grpName{1}
            TrackingOutPreLesion(fPre) = dlc;
            fPre = fPre + 1;
        case grpName{2}
            TrackingOutPostLesion(fPost) = dlc;
            fPost = fPost + 1;
    end
end
save(fullfile(rpath,'TrackingOutPeriLesion.mat'),'TrackingOutPreLesion','TrackingOutPostLesion','-v7.3');
%%
load(fullfile(rpath,'TrackingOutPeriLesion.mat'),'TrackingOutPreLesion','TrackingOutPostLesion');
TrajOut = DLCTrajPrePost(TrackingOutPreLesion,TrackingOutPostLesion,...
    'ANM_Name',sbjName,'HorizontalRange',x_range,'VerticalRange',y_range,...
    'tRange',t_range,'savepath',path_figsave,'tEndPoints',[-50,-100,-200]);
