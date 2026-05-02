%% Make relevant videos
%% Load r
r_file = dir('RTarray*.mat');
load(r_file.name)
%% Load side view
side_view_files    = dir('Aligned_FrameInfoSideView*.mat');
FrameInfoSide = cell(1, length(side_view_files));
for i =1:length(side_view_files)
    FrameInfoSide{i} = load(side_view_files(i).name);
end
top_view_files  = dir('Aligned_FrameInfoTopView*.mat');
FrameInfoTop = cell(1, length(top_view_files));
for i =1:length(top_view_files)
    FrameInfoTop{i} = load(top_view_files(i).name);
end
rate = 100; % frame rate
%% Extract Event Times
EventTime = Spikes.Videos.ExtractEvents_LeverPressVI(r);
%% Make videos (Press-Poke-Press cycle)
% % extract 10 frames (0.1 sec) before port exit and 10 (0.1 sec) post press time
% nPre = 10;
% nPost = 10;
% minMT = 500; % ms
% minReT = 500;
% maxMT = 4000; % ms, the intervals <maxInterval are used
% maxReT = 8000;
% % extract release time
% EventName = 'RetrievalCycle';
% 
% Event = EventTime.PressPokeCycle;
% idxUse = find(Event.MovementTime>=minMT & Event.MovementTime<=maxMT & Event.RestartTime>=minReT & Event.RestartTime<=maxReT);
% 
% tEvents =  [Event.PressesThis(idxUse) Event.PressesNext(idxUse)]; % in ms
% video_path = fullfile(pwd, 'VideoClips', EventName);
% if ~exist(video_path, 'dir')
%     mkdir(video_path);
% end
% % Make video from both angles
% Angles = {'Top'};
% for a = 1:length(Angles)
%     ViewAngle = Angles{a}; % it could also be 'Side'
%     switch ViewAngle
%         case 'Top'
%             FrameInfoSelected = FrameInfoTop;
%         case 'Side'
%             FrameInfoSelected = FrameInfoSide;
%     end
% Spikes.Videos.MakeClipFromSeq_2Events(ViewAngle, FrameInfoSelected, tEvents, EventName, [nPre nPost], video_path, {r.Meta, Event}, [], rate);
% end
%% Make videos (Retrieval: Release-Poke)
% extract 50 frames (0.5 sec) before port exit and 10 (0.1 sec) post press time
nPre = 50; % 0.5 sec before
nPost = 10;
minMT = 500; % ms
maxMT = 5000; % ms, the intervals <maxInterval are used
% extract release time
EventName = 'Retrieval';

Event = EventTime.PressPokeCycle;
idxUse = find(Event.MovementTime>=minMT & Event.MovementTime<=maxMT);

tEvents =  [Event.Releases(idxUse) Event.PokeFirst(idxUse)]; % in ms
video_path = fullfile(pwd, 'VideoClips', EventName);
if ~exist(video_path, 'dir')
    mkdir(video_path);
end
% Make video from both angles
Angles = {'Top'};
for a = 1:length(Angles)
    ViewAngle = Angles{a}; % it could also be 'Side'
    switch ViewAngle
        case 'Top'
            FrameInfoSelected = FrameInfoTop;
        case 'Side'
            FrameInfoSelected = FrameInfoSide;
    end
Spikes.Videos.MakeClipFromSeq_2Events(ViewAngle, FrameInfoSelected, tEvents, EventName, [nPre nPost], video_path, {r.Meta, Event}, [], rate);
end
%% Make videos (Approach: PortExit-Press)
% extract 10 frames (0.1 sec) before port exit and 10 (0.1 sec) post press time
nPre = 10;
nPost = 10;
minReT = 500;
maxReT = 8000;
% extract release time
EventName = 'Approach';

Event = EventTime.PressPokeCycle;
idxUse = find(Event.RestartTime>=minReT & Event.RestartTime<=maxReT);

tEvents =  [Event.PortExit(idxUse) Event.PressesNext(idxUse)]; % in ms
video_path = fullfile(pwd, 'VideoClips', EventName);
if ~exist(video_path, 'dir')
    mkdir(video_path);
end
% Make video from both angles
Angles = {'Top'};
for a = 1:length(Angles)
    ViewAngle = Angles{a}; % it could also be 'Side'
    switch ViewAngle
        case 'Top'
            FrameInfoSelected = FrameInfoTop;
        case 'Side'
            FrameInfoSelected = FrameInfoSide;
    end
Spikes.Videos.MakeClipFromSeq_2Events(ViewAngle, FrameInfoSelected, tEvents, EventName, [nPre nPost], video_path, {r.Meta, Event}, [], rate);
end