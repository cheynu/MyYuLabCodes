function MakeClipFromSeq(ViewAngle, FrameInfoSelected, tEvents, EventName, nSelected, video_path, meta, burst_info, frame_rate);
% 2025.1 JY. This still only applies to ephys data (cause it uses
% FrameInfoSelected{k}.FrameInfo.tFramesMapped2Ephys_ms)
if nargin<9
    frame_rate = 50;
    if nargin<8
        burst_info = [];
    end
end
nPre = nSelected(1);
nPost = nSelected(2);

for i =1:length(tEvents)
    tic
    tEvent = round(tEvents(i));
    % try to look for video in one seq file, if we cannot find it, try
    % another
    found_it          = 0;
    seq_file          = [];
    seq_index      = [];
    seq_time       = [];
    seq_timeEphys = [];
    for k =1:length(FrameInfoSelected)
        if ~found_it
            tEphys = FrameInfoSelected{k}.FrameInfo.tFramesMapped2Ephys_ms;
            if length(find(tEphys<tEvent))>=nPre && length(find(tEphys>=tEvent))>=nPost
                found_it = 1;
                ind=find(tEphys>=tEvent, 1, 'first');
                seq_file = FrameInfoSelected{k}.FrameInfo.SeqVidFile{1};
                seq_index = (ind-nPre:ind+nPost-1);
                seq_time   = FrameInfoSelected{k}.FrameInfo.tframeOrg(seq_index);
                seq_timeEphys = FrameInfoSelected{k}.FrameInfo.tFramesMapped2Ephys_ms(seq_index);
            end
        end
    end

    if found_it

        VideoInfo.Meta  = meta;
        VideoInfo.Event = EventName;
        if ~isempty(burst_info)
            VideoInfo.SpikeInformation = burst_info;
        end
        VideoInfo.Index = NaN;
        VideoInfo.Time = tEvent;
        VideoInfo.nPre = nPre;
        VideoInfo.nPost = nPost;
        VideoInfo.VideoName = seq_file;
        VideoInfo.VideoTimeStamps = seq_time;
        VideoInfo.EphysTimeStamps = seq_timeEphys;
        VideoFolder = video_path;
        VideoName = fullfile(VideoFolder, [ViewAngle '_' EventName '_' num2str(tEvent) '.mp4']);
        InfoName = fullfile(VideoFolder, [ViewAngle '_' EventName '_' num2str(tEvent) '.mat']);

        Video = VideoWriter(VideoName, 'MPEG-4');
        Video.FrameRate = frame_rate; % 1x
        open(Video)

        FrameFiles        =   ReadJpegSEQ(seq_file, [seq_index(1) seq_index(end)]);
        for m =1:size(FrameFiles, 1)
            frame = FrameFiles{m, 1}; % Extract the image data (550x752 uint8)
            % Convert the frame if necessary (for example, to RGB if needed)
            if ndims(frame) == 2 % Grayscale
                frame = repmat(frame, [1 1 3]); % Convert to RGB by replicating channels
            end
            Video.writeVideo(frame);
        end
        % Write the frame to the video
        close(Video)
        save(InfoName, 'VideoInfo')
    end

end
end

% #########################################################################
%%Intact script using this function:
%Make relevant videos
% %% Load r
% load('RTarray_Amazon_20210823.mat')
% %% Load side view
% side_view_files    = dir('Aligned_FrameInfoSideView*.mat');  % from
% Step1_AlignFrameToEphys.mlx, look for a copy in +Spikes/+Videos/
% FrameInfoSide = cell(1, length(side_view_files));
% for i =1:length(side_view_files)
%     FrameInfoSide{i} = load(side_view_files(i).name);
% end
% top_view_files  = dir('Aligned_FrameInfoTopView*.mat');
% FrameInfoTop = cell(1, length(top_view_files));
% for i =1:length(top_view_files)
%     FrameInfoTop{i} = load(top_view_files(i).name);
% end
% % extract 100 frames (1 sec) before trigger time and 250 (2.5 sec) post trigger time
% EventTime = Spikes.Videos.ExtractEvents(r);
% nPre = 100;
% nPost = 250;
% % extract release time
% EventName = 'Press';
% Event = EventTime.Presses;
% tEvents = [Event.Time{1}; Event.Time{2}; Event.Time{3}; Event.Time{4}]; % in ms
% video_path = fullfile(pwd, 'VideoClips', EventName);
% if ~exist(video_path, 'dir')
%     mkdir(video_path);
% end
% % Make video from both angles
% Angles = {'Top', 'Side'};
% for a = 1:length(Angles)
%     ViewAngle = Angles{a}; % it could also be 'Side'
%     switch ViewAngle
%         case 'Top'
%             FrameInfoSelected = FrameInfoTop;
%         case 'Side'
%             FrameInfoSelected = FrameInfoSide;
%     end
% Spikes.Videos.MakeClipFromSeq(ViewAngle, FrameInfoSelected, tEvents, Event,EventName, video_path);
% end
% #########################################################################