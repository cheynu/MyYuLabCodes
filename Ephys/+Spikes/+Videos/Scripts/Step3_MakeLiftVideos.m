
%%  Make videos based on Press time
% extract 100 frames (1 sec) before press time and 400 (4 sec) post trigger time
VideoPath_TopView = fullfile(pwd, 'VideoClips', 'Press');
VideoPath_SideView = fullfile(pwd, 'VideoClips', 'Press', 'Side');
EventName = 'Lift';
VideoPath_Lift = fullfile(pwd, 'VideoClips', EventName);
if ~exist(VideoPath_Lift, 'dir')
    mkdir(VideoPath_Lift);
end
% extract 20 frames before 'Lift' and 20 after 'Lift'
nPre = 20;
nPost = 50;
rate = 100;
LiftTable = readtable('LiftTime_RTarray_Lunar_20230309.csv');
%
% LiftTable =
%   99×5 table
%              vidName               tLift         tPress         Paw         Turn
%     _________________________    __________    __________    _________    _________
%
%     {'Top_Press_154849.mp4' }    1.5454e+05    1.5485e+05    {'Right'}    {'Right'}
%     {'Top_Press_177874.mp4' }     1.776e+05    1.7787e+05    {'Right'}    {'Right'}

N_trials = size(LiftTable, 1);

for i =1:N_trials
    top_vid_name        =       LiftTable.vidName{i};
    top_vid_meta         =       strrep(top_vid_name, '.mp4', '.mat');
    side_vid_name       =       strrep(top_vid_name, 'Top', 'Side');
    side_vid_meta        =       strrep(side_vid_name, '.mp4', '.mat');
    lift_time = LiftTable.tLift(i);
    lift_video_name = ['Side_Lift_' num2str(round(lift_time)) '.mp4'];
    top_meta = load(fullfile(VideoPath_TopView, top_vid_meta));
    side_meta = load(fullfile(VideoPath_SideView, side_vid_meta));
    % extract frames
    ind_pre_lift     = find(side_meta.VideoInfo.EphysTimeStamps<lift_time);
    ind_post_lift   = find(side_meta.VideoInfo.EphysTimeStamps>=lift_time);
    if length(ind_pre_lift)<nPre || length(ind_post_lift)<nPost
        continue
    else
        ind_pre_lift = ind_pre_lift(end-nPre+1:end);
        ind_post_lift = ind_post_lift(1:nPost);
    end

    side_video = VideoReader(fullfile(VideoPath_SideView, side_vid_name));
    fields = fieldnames(side_meta.VideoInfo);
    LiftMeta = struct();
    for ii = 1:numel(fields)
        LiftMeta.(fields{ii}) = []; % Initialize each field to empty
    end

    LiftMeta.Meta = side_meta.VideoInfo.Meta;
    LiftMeta.Event = 'Lift';
    LiftMeta.Time = lift_time;
    LiftMeta.nPre = nPre;
    LiftMeta.nPost = nPost;
    LiftMeta.VideoName = side_meta.VideoInfo.VideoName;
    ind_extract = [ind_pre_lift ind_post_lift];
    LiftMeta.VideoTimeStamps = side_meta.VideoInfo.VideoTimeStamps(ind_extract);
    LiftMeta.EphysTimeStamps = side_meta.VideoInfo.EphysTimeStamps(ind_extract);

    VideoInfo = LiftMeta;
    LiftInfoName = fullfile(VideoPath_Lift, ['Side_Lift_' num2str(round(lift_time)) '.mat']);

    % save LiftMeta file
    Video = VideoWriter(fullfile(VideoPath_Lift, lift_video_name), 'MPEG-4');
    Video.FrameRate = rate; % 1x
    open(Video)

    for m =1:length(ind_extract)
        side_video.CurrentTime = (ind_extract(m) - 1) / side_video.FrameRate;
        frame = readFrame(side_video);
        Video.writeVideo(frame);
    end
    % Write the frame to the video
    close(Video)
    save(LiftInfoName, 'VideoInfo')
end
