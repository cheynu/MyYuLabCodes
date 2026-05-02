function [file_names, names, frame_names] = getVideoInfos(side_view_dim, top_view_dim)

dir_out = dir('./*.seq');
vid_filenames = {dir_out.name};
vid_filenames_top = {};
vid_filenames_side = {};

% sort vide names based on timing
vid_times = zeros(1, length(vid_filenames));
for k = 1:length(vid_filenames)
    vid_times(k) = get_seq_time(vid_filenames{k});
end
[~, ind_sort] = sort(vid_times);
vid_filenames = vid_filenames(ind_sort);

% check video frame size to determine if it is side or top view
type_names = cell(1, length(vid_filenames));

for k = 1:length(vid_filenames)
    img = ReadJpegSEQ2(vid_filenames{k},1);
    if ~isempty(top_view_dim)
       if  size(img, 1) == top_view_dim(1) ||  size(img, 2) == top_view_dim(2);
        type_names{k} = 'TopView';
       end
    end

    if ~isempty(side_view_dim)
        if size(img, 1) ==  side_view_dim(1) || size(img, 2) ==  side_view_dim(2)
            type_names{k} = 'SideView';
        end
    end
end
% filenames=arrayfun(@(x)x.name, dir('*.seq'), 'UniformOutput', false);
[names, frame_names] = ProduceNames(vid_filenames, type_names); % check these videos via PlaySeqFile first
file_names= vid_filenames;

% FrameData = {
%  'FrameInfoSideView_20210823-16-00-02.mat'  'FrameInfoTopView_20210823-16-00-04.mat'  
%  'FrameInfoSideView_20210823-16-20-31.mat'  'FrameInfoTopView_20210823-16-20-34.mat'
% };

end
 
function [names, frame_names] = ProduceNames(filenames, attachments);
    names = cell(1, length(filenames));
    side_names = {};
    top_names = {};
    for i =1:length(filenames)
        vidfile = extractBefore(filenames{i}, '.000.seq');
        names{i} = [attachments{i} '_' vidfile];
        switch attachments{i}
            case 'SideView'
                side_name = ['FrameInfoSideView_' vidfile '.mat'];
                side_names = [side_names; side_name];
            case 'TopView'
                top_name = ['FrameInfoTopView_' vidfile '.mat'];
                top_names = [top_names; top_name];
        end
    end
    frame_names = [side_names top_names];

end


function t = get_seq_time(seqname)
% year = str2double(seqname(1:4));
% month = str2double(seqname(5:6));
% month = str2double(seqname(7:8));
hour = str2double(seqname(10:11));
min = str2double(seqname(13:14));
sec = str2double(seqname(16:17));
t = sec+60*min+60*60*hour;
end