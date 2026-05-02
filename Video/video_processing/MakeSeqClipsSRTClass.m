function MakeSeqClipsSRTClass(SRTobj, FrameInfo, WSOut, tEvents, varargin)
% new, more generic clip-making program in 2022!

% Kb:  Kb class
% frameinfo: frame related
% sout: from wavesurfer, can be empty if no ws data are available. 
% tevents: this is the time of events that are to be constructed. 

% this program export video clips from behavior-relevant time points.
% File name is : ANM_YearMonDay_Event###.avi
% Video files should be stored in a directly named after the event name,
% etc., \DLC_NoStim

% varargin:
% 'Event', 'Press', 'DLCNoStim', etc.

% 'TimeRange': [2000 3000] in seconds
% 'RatName': 'Charlie'
% 'SessionName': '20200810'

% Jianing Yu
% 5/1/2021
% 5/5/2022 revised from ExportSeqVideoFiles.m to make it more generic
% 12/4/2022 revised from MakeSeqClip.m to use KbClass as an input (instead
% of BpodMEDTable)

% make video clips 
% need these data:
% 1. Kb: Kornblum class 
% 2. frameinfo.mat
% 3. event times (in bpod time) 
% 4(optional). wavesurfer data sout

remake =0;
trange = [1000 1000]; % in ms

if nargin>2
    for i=1:2:size(varargin,2)
        switch varargin{i}
            case {'Event'}
                event = varargin{i+1};
            case {'EventType'}
                event_type = varargin{i+1};
            case {'Pre'}
                trange(1) = varargin{i+1}; % pre-event periods.
            case {'Post'}
                trange(2) = varargin{i+1}; % pre-event periods.
            case {'ANM'}
                anm = varargin{i+1}; % animal name
            case {'BehaviorType'}
                beh_type = varargin{i+1}; % type of behavior, e.g., ApproachDLCMixOptoStim
            case {'Session'}
                session = varargin{i+1}; % Session name
            case {'Remake'}
                remake =  varargin{i+1};
            otherwise
                errordlg('unknown argument')
        end
    end
end

% This is frame time in MED time, we use it extract video grames
tframesMED            =    FrameInfo.tFrameMED; % in ms

tPre                    =    trange(1); % pre event time included, in ms
tPost                   =     trange(2); % post event time included, in ms
trigger_dur         =     250; % trigger sitmulus is usually 250 ms

% low-pass filter
[bfilt, afilt] = butter(4, 200*2/10000, 'low');

% identify video onset and offset
% beginning of new video segments (sometimes we record more than one video
% and there could be significan gap between these videos. obviously, events
% occuring within these gaps were not filmed.

thisFolder = fullfile(pwd, 'VideoClips', event_type);
if ~exist(thisFolder, 'dir')
    mkdir(thisFolder)
end;

% % Video meta data
% VidsMeta = struct( ...
%     'ANM', anm, ...
%     'Session', session, ...
%     'Event', event, ...
%     'EventTime', [], ...
%     'BpodTrialNum',[],...
%     'Performance', [], ... % 1 correct 0 incorrect NaN no press
%     'FrameTimesBpod', [], ...
%     'VideoFile', [], ... % Video file used to make this clip
%     'FrameIndx', [], ... % Video frame index to make this clip
%     'Code', [], ...
%     'CreatedOn', []);

% Video meta data
VidsMeta = struct( ...
    'ANM', anm, ...
    'Session', session, ...
    'Event', event, ...
    'EventTime', [], ...
    'PressTrialNum', [],...
    'Performance', [], ... % 1 correct 0 incorrect NaN no press
    'FrameTimesMED', [], ...
    'VideoFile', [], ... % Video file used to make this clip
    'FrameIndx', [], ... % Video frame index to make this clip
    'Code', [], ...
    'CreatedOn', []);


%% Start making videos
clc
video_acc = 0;

for i =1:length(tEvents) % i is also the trial number

    if contains(event, 'Press')
        ind_event                       =          find(Kb.PressTime == tEvents(i));
    elseif contains(event, 'Release')
        ind_event                       =          find(Kb.ReleaseTime == tEvents(i));
    else
        disp(['Check this event: ' event])
    end;

    itEvent                               =        tEvents(i)*1000; % in ms
    IndThisClip                        =         find(tframesMED>=itEvent - tPre & tframesMED<= itEvent + tPost);

    iFrameTimesMED             =          tframesMED(IndThisClip); % frames for this event
    indFrame_at_Event          =        find(iFrameTimesMED>itEvent, 1, 'first');

    % make sure the videoclip can be constructed from a single video file
    if itEvent -iFrameTimesMED(1) < tPre-50
        continue
    elseif  iFrameTimesMED(end)-itEvent < tPost-50
        continue
    elseif FrameInfo.SeqFileIndx(IndThisClip(1)) ~= FrameInfo.SeqFileIndx(IndThisClip(end))
        % same video file
        continue
    end;

    % find  out index in this video file
    IndThisClip_prime = FrameInfo.SeqFrameIndx(IndThisClip);

    this_video                      =           FrameInfo.SeqVidFile{FrameInfo.SeqFileIndx(IndThisClip(1))};
%     [~, IndThisFrame]         =            min(abs(tframesMED - itEvent)); % frame closest to the event
    % Trial num and time of all kinds of events
    iTrial                               =          ind_event;
    iFP                                  =         Kb.FP(ind_event);
    % check if a video has been created and check if we want to
    % re-create the same video
    ClipName = sprintf('%s_%s_%s%03d', anm, session, event,  iTrial);

    % with directory
    VidClipFileName = fullfile(thisFolder, [ClipName '.avi']);
    check_this_file = dir(VidClipFileName);

    if ~isempty(check_this_file)  && ~remake % found a video clip with the same name, and we don't want to remake the video clip
        continue % move on
    end;

    % a few important events
    PressTime               =       Kb.PressTime(ind_event)*1000-iFrameTimesMED(1);

    if Kb.ToneTime(ind_event) ~=0 && ~isnan(Kb.ToneTime(ind_event))
        TriggerTime            =        Kb.ToneTime(ind_event)*1000-iFrameTimesMED(1);
    else
        TriggerTime            =       0;
    end;
    ReleaseTime           =       Kb.ReleaseTime(ind_event)*1000-iFrameTimesMED(1);
    Perf                          =       Kb.Outcome{ind_event};

    if ~isempty(WSOut)
        t_WS                     =           WSOut.TimeInMED; % in ms
        ind_WS                 =           find(WSOut.TimeInMED>=itEvent - tPre & WSOut.TimeInMED<=itEvent + tPost);
        tf_WS                    =           t_WS(ind_WS);

        if isempty(tf_WS)
            continue
        end;

        tf_WS                    =           tf_WS - tf_WS(1);
        f_Press                  =           filtfilt(bfilt, afilt, detrend(WSOut.Signals(ind_WS, find(contains(WSOut.Labels, 'Press'))), 'constant'));
        f_Press                  =            f_Press - mean(f_Press(1:10));
        f_Press                 =            f_Press/max(0.5, max(abs(f_Press)));
        f_Trigger               =           filtfilt(bfilt, afilt, WSOut.Signals(ind_WS, find(contains(WSOut.Labels, 'Trigger'))));
%         f_Approach          =           filtfilt(bfilt, afilt, WSOut.Signals(ind_WS, find(contains(WSOut.Labels, 'Approach'))));
%         f_Opto                  =           WSOut.Signals(ind_WS, find(contains(WSOut.Labels, 'Opto')));

%         % make new f_Opto
%         f_OptoNew         =             zeros(size(f_Opto));
%         above_th            =              find(f_Opto>2);
%         if ~isempty(above_th)
%             LaserBeg          =             above_th(1);
%             LaserEnd          =             above_th(end);
%             tLaserBeg          =            tf_WS(above_th(1));
%             tLaserEnd          =            tf_WS(above_th(end));
%             f_OptoNew(LaserBeg:LaserEnd) = 1;
%         else
%             tLaserBeg=[];
%             tLaserEnd=[];
%         end;

        % make new f_Trigger
        f_TriggerNew    =             zeros(size(f_Trigger));
        above_th           =              find(f_TriggerNew>1);
        if ~isempty(above_th)
            tTriggerBeg          =            tf_WS(above_th(1));
            tTriggerEnd          =            tf_WS(above_th(end));
            f_TriggerNew(above_th(1):above_th(end)) = 1;
        else
            tTriggerBeg          =            [];
            tTriggerEnd          =            [];
        end;

    else
        t_WS                    =           [];
        tf_WS                   =           [];
        f_Press                 =           [];
        f_Trigger              =           [];
        f_Approach         =           [];
        f_Opto                 =           [];
        tLaserBeg          =             [];
        tLasesEnd          =             [];
        f_OptoNew         =            [];
        tTriggerBeg          =           [];
        tTriggerEnd          =           [];
        f_TriggerNew    =            [];
    end;

    % build video clips, frame by frame
    F= struct('cdata', [], 'colormap', []);
 

    VidMeta.ANM                         =           anm;
    VidMeta.Session                     =          session;
    VidMeta.Event                        =          event;
    VidMeta.EventTime               =          itEvent/1000; % in sec (Bpod)
    VidMeta.PressTrialNum        =          ind_event;
    VidMeta.FP                              =          iFP;
    VidMeta.FrameTimesMED   =          iFrameTimesMED;                        % frame time in ms in behavior time
    VidMeta.FrameIndx               =          IndThisClip_prime;                   % frame index in original video
    VidMeta.VideoFile                  =         this_video;
    VidMeta.Code                         =         mfilename('fullpath');
    VidMeta.CreatedOn               =           date;                                % today's date

    video_acc = video_acc+1;
    if video_acc ==1
        VidsMeta = VidMeta;
    else
        VidsMeta(video_acc) = VidMeta;
    end;

    % Extract frames: use IndThisClip_prime

    tic
    FrameFiles        =   ReadJpegSEQ(this_video, [IndThisClip_prime(1) IndThisClip_prime(end)]);
    FrameFiles        =    FrameFiles(:, 1);
    toc
    [height, width] =  size(FrameFiles{1});
    VidsMeta(video_acc) = VidMeta;

    iFrameTimesMED = iFrameTimesMED - iFrameTimesMED(1);

    hf25 = figure(25); clf
    set(hf25, 'name', 'side view', 'units', 'centimeters', 'position', [ 3 3 15 3+15*height/width], 'PaperPositionMode', 'auto', 'color', 'w')
    ha= axes;
    set(ha, 'units', 'centimeters', 'position', [0 3 15 15*height/width], 'nextplot', 'add', 'xlim',[0 width], 'ylim', [0 height], 'ydir','reverse')
    axis off
    % plot some important behavioral events
    ha2= axes;
    set(ha2, 'units', 'centimeters', 'position', [1.5 1 13 1.75], 'nextplot', 'add', 'xlim',[0 tPre+tPost],...
        'xtick', [0:500:5000], 'ytick', [1 2], ...
        'yticklabel', {'Press', 'Trigger'},'ylim', [-1 3], 'tickdir', 'out')
    xlabel('Time (ms)')

    writerObj = VideoWriter(VidClipFileName);
    writerObj.FrameRate = 10; % this is 10 x slower
    % set the seconds per image
    % open the video writer
    open(writerObj);

    % Make videos
    for k =1:length(FrameFiles)

        % plot this frame:
        if k ==1
            himg = imagesc(ha, FrameFiles{1}, [0 250]);
            colormap('gray')
        else
            himg.CData = FrameFiles{k};
        end;

        itframes_norm = iFrameTimesMED(k) - iFrameTimesMED(1);
        time_of_frame = sprintf('%3.0f ms', round(itframes_norm));
        if k == 1
            hframetimetext = text(ha, 5, 20, [time_of_frame], 'color', [246 233 35]/255, 'fontsize', 15,'fontweight', 'bold');
        else
            hframetimetext.String = time_of_frame;
        end;
        if k ==1
            % Bpod trial num iTrial
            text(ha, 10, height-180,  sprintf('Trial# %2.0d',iTrial), 'color', [255 255 255]/255, 'fontsize',  12, 'fontweight', 'bold')
            text(ha, 10, height-140,  sprintf('%s',session), 'color', [255 255 255]/255, 'fontsize',  12, 'fontweight', 'bold')
            text(ha, 10,  height-100,  sprintf('%s', strrep(event_type, '_', ' ')), 'color', [255 255 255]/255, 'fontsize',  12, 'fontweight', 'bold')
            if ~isnan(iFP)
                text(ha, 10, height-60,  sprintf('FP %2.0f ms', iFP), 'color', [255 255 255]/255, 'fontsize',  12, 'fontweight', 'bold')
                text(ha, 10, height-20,  Perf, 'color', [255 255 255]/255, 'fontsize',  12, 'fontweight', 'bold')

            end;
        end;

        % only plot once
        if k ==1
%             % Plot event time
%             line(iFrameTimesMED(indFrame_at_Event)*[1 1], get(ha2, 'ylim'), 'color', 'c', 'linewidth', 2)
%             
            % plot Press data
            if ~isempty(f_Press)
                % itframes
                hp_press = plot(ha2, tf_WS, f_Press+1, 'k', 'linewidth', 2);
            end;

            if PressTime>0 && ReleaseTime>0
                axes(ha2)
                plotshaded([PressTime ReleaseTime], [-0.5 -0.5; 1.5 1.5 ], [0.5 0.5 0.5])
            end;

            % Plot Trigger data
            if TriggerTime>0
                axes(ha2)
                plotshaded([TriggerTime TriggerTime+250], [1.5 1.5; 2.5 2.5],  [0.7 0.4 0.3])
            end;
%  
%             % plot Opto data
%             if ~isempty(f_OptoNew) && ~isempty(tLaserBeg)
%                 axes(ha2)
%                 plotshaded([tLaserBeg tLaserEnd], [3 3; 3.75 3.75], [0 0.6 1])
%             end;

        end;

        if k ==1
            hcurrentframe = line(ha2, [iFrameTimesMED(k) iFrameTimesMED(k)], get(ha2, 'ylim'), 'color', [0.75 0.75 0.75], 'linewidth', 2, 'linestyle', '-');
        else
            hcurrentframe.XData = [iFrameTimesMED(k) iFrameTimesMED(k)];
        end;

        % plot or update data in this plot
        F = getframe(hf25) ;
        drawnow
        writeVideo(writerObj, F);
    end;
    %     VidClipFileName = fullfile(thisFolder, [ClipName '.avi']);
    % close the writer object
    close(writerObj);
    MetaFileName = fullfile(thisFolder, [ClipName, '.mat']);
    save(MetaFileName, 'VidMeta');
end;