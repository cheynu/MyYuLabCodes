%% Make relevant videos
%% Load r
 load('RTarray_Musk_20210824.mat')
 % Load side view
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
%% Make videos based on poke time
% extract 10 frames (0.1 sec) before trigger time and 10 (0.1 sec) post poke time
EventTime = Spikes.Videos.ExtractEvents(r);
nPre = 10;
nPost = 10;
% extract release time
EventName = 'Poke';
Event = EventTime.Pokes;
tEvents =  [Event.RewardPoke.Time{1} Event.RewardPoke.Time{2}]; % in ms
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
Spikes.Videos.MakeClipFromSeq(ViewAngle, FrameInfoSelected, tEvents, EventName, [nPre nPost], video_path, {r.Meta, Event});
end

%% Make videos based on Press time (top)
% extract 100 frames (1 sec) before press time and 400 (4 sec) post trigger time
EventTime = Spikes.Videos.ExtractEvents(r);
nPre = 500;
nPost = 500;
% extract release time
EventName = 'Press';
Event = EventTime.Presses;
tEvents = [Event.Time{1}; Event.Time{2}; Event.Time{3}; Event.Time{4}]; % in ms
video_path = fullfile(pwd, 'VideoClips', EventName);
if ~exist(video_path, 'dir')
    mkdir(video_path);
end
% Make video from both angles
Angles = {'Top'};
rate = 100; % frame rate
for a = 1:length(Angles)

    ViewAngle = Angles{a}; % it could also be 'Side'
    switch ViewAngle
        case 'Top'
            video_path_ = fullfile(video_path, 'Top');
            FrameInfoSelected = FrameInfoTop;
        case 'Side'
            video_path_ = fullfile(video_path, 'Side');
            FrameInfoSelected = FrameInfoSide;
    end

Spikes.Videos.MakeClipFromSeq(ViewAngle, FrameInfoSelected, tEvents, EventName, [nPre nPost], video_path_, {r.Meta, Event}, rate);
end

%% Make videos based on Press time (side)
% extract 100 frames (1 sec) before press time and 400 (4 sec) post trigger time
EventTime = Spikes.Videos.ExtractEvents(r);
nPre = 200;
nPost = 250;
% extract release time
EventName = 'Press';
Event = EventTime.Presses;
tEvents = [Event.Time{1}; Event.Time{2}; Event.Time{3}; Event.Time{4}]; % in ms
video_path = fullfile(pwd, 'VideoClips', EventName);
if ~exist(video_path, 'dir')
    mkdir(video_path);
end
% Make video from both angles
Angles = {'Side'};
rate = 100; % frame rate
for a = 1:length(Angles)

    ViewAngle = Angles{a}; % it could also be 'Side'
    switch ViewAngle
        case 'Top'
            video_path_ = fullfile(video_path, 'Top');
            FrameInfoSelected = FrameInfoTop;
        case 'Side'
            video_path_ = fullfile(video_path, 'Side');
            FrameInfoSelected = FrameInfoSide;
    end

Spikes.Videos.MakeClipFromSeq(ViewAngle, FrameInfoSelected, tEvents, EventName, [nPre nPost], video_path_, {r.Meta, Event}, rate);
end
%% Make videos based on  Trigger time
% extract 50 frames (0.5 sec) before trigger time and 100 (1 sec) post trigger time
EventTime = Spikes.Videos.ExtractEvents(r);
nPre = 50;
nPost = 100;
% extract release time
EventName = 'Trigger';
Event = EventTime.Triggers;
tEvents = [Event.Time{1}; Event.Time{2}; Event.Time{3}]; % in ms
video_path = fullfile(pwd, 'VideoClips', EventName);
if ~exist(video_path, 'dir')
    mkdir(video_path);
end
% Make video from both angles
Angles = {'Top', 'Side'};
for a = 1:length(Angles)
    ViewAngle = Angles{a}; % it could also be 'Side'
    switch ViewAngle
        case 'Top'
            FrameInfoSelected = FrameInfoTop;
        case 'Side'
            FrameInfoSelected = FrameInfoSide;
    end
Spikes.Videos.MakeClipFromSeq(ViewAngle, FrameInfoSelected, tEvents, EventName, [nPre nPost], video_path, {r.Meta, Event});
end

%% Make video clips based on bursting time
% Unit [15 2] is what we really care about.
Ch = 15;
Un = 2;
burst=Spikes.Videos.burst_timings(r, [Ch Un]);
EventTime = Spikes.Videos.ExtractEvents(r);
tburst_onset = burst.onset_poisson*1000;
tburst_offset = burst.offset_poisson*1000;
spikes_in_bursts = burst.spikes_in_bursts;
nPre = 10;
VideoInterval = 10; % 10 ms between frames
% extract release time
Event = [];
EventName = ['Bursting_Ch' num2str(Ch) 'Unit' num2str(Un)];
BurstInfo.ChannelUnit = [Ch, Un];
BurstInfo.Labels = {'Onset-Offset','SpikesInBursts', 'SDF_of_Bursts'};
Event.BehaviorLabels = {'Press', 'Release', 'Trigger', 'Poke1', 'Poke2'};
Event.BehaviorTimings_ms = {EventTime.PressTimes_ms, EventTime.Releases_ms, EventTime.Triggers_ms, EventTime.RewardPokes_ms, EventTime.NonRewardPokes_ms};
video_path = fullfile(pwd, 'VideoClips', EventName);
if ~exist(video_path, 'dir')
    mkdir(video_path);
end
% Make video from both angles
Angles = {'Top', 'Side'};
for k =1:length(tburst_onset)
    for a = 1:length(Angles)
        ViewAngle = Angles{a}; % it could also be 'Side'
        switch ViewAngle
            case 'Top'
                FrameInfoSelected = FrameInfoTop;
            case 'Side'
                FrameInfoSelected = FrameInfoSide;
        end
        nPost = ceil((tburst_offset(k)-tburst_onset(k)+0.1)/VideoInterval);
        disp(nPost)
        BurstInfo.Values =  {[tburst_onset(k) tburst_offset(k)], spikes_in_bursts{1, k}, spikes_in_bursts{2, k}};
        tEvent = tburst_onset(k); % in ms
        Spikes.Videos.MakeClipFromSeq(ViewAngle, FrameInfoSelected, tEvent, EventName, [nPre nPost], video_path, {r.Meta, Event}, BurstInfo);
    end
end