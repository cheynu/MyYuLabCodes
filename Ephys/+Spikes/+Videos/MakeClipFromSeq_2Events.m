function MakeClipFromSeq_2Events(ViewAngle, FrameInfoSelected, tEvents, EventName, nSelected, video_path, meta, burst_info, frame_rate);
% 2026.4.5 Yu Chen. Updated to support dual-event [StartEvent, EndEvent] clipping.
% tEvents: N x 2 matrix, where col 1 is StartEvent, col 2 is EndEvent.
% nSelected: [nPre, nPost], additional frames before StartEvent and after EndEvent.
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

% 检查 tEvents 是否为两列
if size(tEvents, 2) ~= 2
    error('tEvents 必须是一个 N x 2 的矩阵（第一列为起始时刻，第二列为结束时刻）。');
end

for i =1:size(tEvents,1)
    tic
    % 获取当前这一组的两个时刻
    tStartEvent = tEvents(i, 1);
    tEndEvent   = tEvents(i, 2);

    % tEvent = round(tEvents(i));
    % try to look for video in one seq file, if we cannot find it, try
    % another
    found_it      = 0;
    seq_file      = [];
    seq_index     = [];
    seq_time      = [];
    seq_timeEphys = [];
    for k =1:length(FrameInfoSelected)
        if ~found_it
            tEphys = FrameInfoSelected{k}.FrameInfo.tFramesMapped2Ephys_ms;
            
            % 找到起始时刻和结束时刻在 ephys 时间轴中的位置
            idxStart = find(tEphys >= tStartEvent, 1, 'first');
            idxEnd   = find(tEphys >= tEndEvent, 1, 'first');
            if ~isempty(idxStart) && ~isempty(idxEnd) && ...
               (idxStart - nPre) >= 1 && (idxEnd + nPost) <= length(tEphys)
            % if length(find(tEphys<tEvent))>=nPre && length(find(tEphys>=tEvent))>=nPost
                found_it = 1;

                % 定义裁剪的帧索引范围
                seq_index = (idxStart - nPre : idxEnd + nPost);
                % ind=find(tEphys>=tEvent, 1, 'first');
                % seq_index = (ind-nPre:ind+nPost-1);

                seq_file = FrameInfoSelected{k}.FrameInfo.SeqVidFile{1};
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
        VideoInfo.Time = [tStartEvent tEndEvent];
        VideoInfo.nPre = nPre;
        VideoInfo.nPost = nPost;
        VideoInfo.VideoName = seq_file;
        VideoInfo.VideoTimeStamps = seq_time;
        VideoInfo.EphysTimeStamps = seq_timeEphys;

        VideoFolder = video_path;
        timestamp_str = [num2str(round(tStartEvent)) '_' num2str(round(tEndEvent))];
        VideoName = fullfile(VideoFolder, [ViewAngle '_' EventName '_' timestamp_str '.mp4']);
        InfoName = fullfile(VideoFolder, [ViewAngle '_' EventName '_' timestamp_str '.mat']);

        Video = VideoWriter(VideoName, 'MPEG-4');
        Video.FrameRate = frame_rate; % 1x
        open(Video)

        FrameFiles = ReadJpegSEQ(seq_file, [seq_index(1) seq_index(end)]);
        for m =1:size(FrameFiles, 1)
            frame = FrameFiles{m, 1}; % Extract the image data (550x752 uint8)
            % Convert the frame if necessary (for example, to RGB if needed)
            if ismatrix(frame) % Grayscale
                frame = repmat(frame, [1 1 3]); % Convert to RGB by replicating channels
            end
            Video.writeVideo(frame);
        end
        % Write the frame to the video
        close(Video)
        save(InfoName, 'VideoInfo')
        fprintf('Saved: %s (Duration: %.2f s)\n', VideoName, toc);
    else
        fprintf('Warning: Could not find complete range for Event Row %d\n', i);
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