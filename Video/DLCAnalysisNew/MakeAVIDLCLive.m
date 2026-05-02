function MakeAVIDLCLive(TblName, varargin)

% This program makes avi files depicting each reaching events from [-.25 2]
% surrounding DLC detection time
% btable is a product from DLCOnlineTrackingBehavior.mlx, found in every
% session folder. 
% parameters:
% 'Redo': 1. re-make all videos; 0. make only new videos
% 'FileType': by default avi, can also do mp4
% Jianing Yu 3-30-2022

if isempty(TblName)
    TblName = dir('BpodMED*csv').name;
end;

FrameRate = 50;
PreFrameNum = -FrameRate*0.5;
PostFrameNum = FrameRate*1.5;

redo =1;
filetype = 'avi';

for i =1:2:nargin-1
    switch varargin{i}
        case 'Redo'
            redo = varargin{i+1};
    end;
end;

btable = readtable(TblName);
ANMName                =             btable.("RatName"); 
IndBpod                     =             btable.('TrialsBpod');
FPs                              =             btable.('FPs');
tPress                         =             btable.('tPress'); 
tApproach                 =             btable.('tApproach');
tDLC                            =             btable.('tDLC');
Opto                            =            btable.('OptoStimTypes');
FrameTime                =             btable.('FrameTimeAtDLCTime');
FrameTimeIdx                =        btable.('FrameIdxAtDLCTime');

vidFile                        =              dir([ANMName{1} '*.avi']);
vidFile                        =              vidFile.name;

vidtsFile                        =              dir([ANMName{1} '_position*.txt']);
vidtsFile                        =              vidtsFile.name;
Pos                                 =              importdata(vidtsFile);

% extrace all frame times with pos data
AllFrameTimes          =            zeros(length(Pos), 1);
Xpos                          =           zeros(length(Pos), 1);
Ypos                          =           zeros(length(Pos), 1);
for k =1:length(AllFrameTimes)
    iPos = strsplit(Pos{k}, ' ');
    AllFrameTimes(k) = sum(sscanf(iPos{4}(1:end-1), '%f:%f:%f').*[3600; 60;1]) + str2num(iPos{5}(1:end-2))/1000;
    Xpos(k) = str2double(iPos{1}(2:end-1));
    Ypos(k) = str2double(iPos{2}(1:end-1));
end;

thisFolder = fullfile(pwd, 'DLCVideoClips');
if ~exist(thisFolder, 'dir')
    mkdir(thisFolder)
end;

 % load posdata
load(dir(['PosData_' ANMName{1} '*Updated.mat']).name)

% load video
vidObj=VideoReader(vidFile);

%
OrgTableName = strsplit(TblName, '_');
Date = strsplit(OrgTableName{3}, '.');
aGoodName       =     ['OptoDLCVideo_' OrgTableName{2} '_' Date{1}  '.csv'];

TrialNums = [];
OptoStimTypes= {};
DLCtoPressLatencyms = [];

for i =1:length(tDLC) % go through each entry

    if tDLC(i)>0 && tPress(i)>0 && (strcmp(Opto{i}, 'NoStim') || strcmp(Opto{i}, 'Stim_DLC')) && ~isnan(FrameTime(i))

        if PosData.StimTime(FrameTimeIdx(i), 1) == FrameTime(i);
            aviFrameIdx = PosData.StimTime(FrameTimeIdx(i), 2);
            FramesToExtract = aviFrameIdx + [PreFrameNum PostFrameNum];
            if FramesToExtract(1)>0 && FramesToExtract(2)< vidObj.NumFrames
                % extract time stamps
                FramesToExtractAll = aviFrameIdx + [PreFrameNum:PostFrameNum];
                FrameTimeStamps = zeros(1, length(FramesToExtractAll));
                FrameTimeDLC = [];
                IndCritical = [];
                DLCPos = [];
                Xpos_frames  =  Xpos(FramesToExtractAll);
                Ypos_frames  =  Ypos(FramesToExtractAll);
                for j =1:length(FramesToExtractAll)
                    iPos = strsplit(Pos{FramesToExtractAll(j)}, ' ');
                    if FramesToExtractAll(j) == aviFrameIdx
                        FrameTimeDLC = sum(sscanf(iPos{4}(1:end-1), '%f:%f:%f').*[3600; 60;1]) + str2num(iPos{5}(1:end-2))/1000;
                        IndCritical = j;
                        DLCPos= [str2num(iPos{1}(2:end-1))  str2num(iPos{2})];
                    end;
                    FrameTimeStamps(j) = sum(sscanf(iPos{4}(1:end-1), '%f:%f:%f').*[3600; 60;1]) + str2num(iPos{5}(1:end-2))/1000;
                end;
                % Get relative number
                FrameTimeStampshat = FrameTimeStamps - FrameTimeDLC;
                theseFrames = read(vidObj, [FramesToExtract(1) FramesToExtract(2)]);
                img_extracted=zeros(size(theseFrames, 1), size(theseFrames, 2), size(theseFrames, 4));
                for ii =1:size(theseFrames, 4)
                    img_extracted(:, :, ii) = rgb2gray(theseFrames(:, :, :, ii));
                end;

                % make video clips
                % build video clips, frame by frame
                F= struct('cdata', [], 'colormap', []);

                VidMeta.TrialNum_Bpod           =            i;
                VidMeta.btable                           =         fullfile(pwd, TblName);
                VidMeta.VidFileOrg                    =          vidFile;
                VidMeta.FrameIndex                 =          FramesToExtractAll;       % Event time in ms in behavior time
                VidMeta.FrameSize                    =         [size(img_extracted, 2) size(img_extracted, 1)];
                VidMeta.FrameTimes                 =          FrameTimeStamps;                        % frame time in ms in behavior time
                VidMeta.Xpos                             =         Xpos_frames; % online tracking data
                VidMeta.Ypos                             =          Ypos_frames;
                VidMeta.Event                             =           'DLC';
                VidMeta.Opto                              =            Opto{i};                   % frame index in original video
                VidMeta.Code                              =            mfilename('fullpath');
                VidMeta.CreatedOn                    =            date;                                % today's date

                TrialNums = [TrialNums; i];
                OptoStimTypes= [OptoStimTypes;  Opto(i)];
                DLCtoPressLatencyms = [DLCtoPressLatencyms; 1000*(-btable.tDLC(i) + btable.tPress(i))];

                video_name = sprintf('Trial_%s', num2str(i, '%03.f'));
                alreadymade = 0;

                if ~redo
                    switch filetype
                        case 'avi'
                            file_to_check = dir(fullfile(thisFolder, [video_name, '.avi']));
                            if ~isempty(file_to_check)
                                alreadymade =1;
                            end;
                        case 'mp4'
                            file_to_check = dir(fullfile(thisFolder, [video_name, '.mp4']));
                            if ~isempty(file_to_check)
                                alreadymade =1;
                            end;
                    end;
                end;

                sprintf('Check trial #%2.0d', i)

                if ~alreadymade
                    for k =1:size(img_extracted, 3)

                        hf25 = figure(25); clf
                        set(hf25, 'name', 'side view', 'units', 'centimeters', 'position', [ 3 5 10 10*size(theseFrames, 1)/size(theseFrames, 2)], 'PaperPositionMode', 'auto', 'color', 'w', 'Visible', 'on')
                        VidHeight = size(theseFrames, 1)*(1+10*size(theseFrames, 1)/size(theseFrames, 2))/(10*size(theseFrames, 1)/size(theseFrames, 2));

                        ha= axes;
                        set(ha, 'units', 'centimeters', 'position', [0 0 10 10*size(theseFrames, 1)/size(theseFrames, 2)], 'nextplot', 'add', ...
                            'xlim',[0 size(theseFrames, 2)], 'ylim', [0 size(theseFrames, 1)], 'ydir','reverse')
%                         axis off
                        % plot this frame:
                        imagesc(img_extracted(:, :, k), [0 250]);
                        colormap('gray')

                        if k==IndCritical
                            plot(DLCPos(1), DLCPos(2), 'o', 'markersize', 4, 'linewidth', 2, 'color', [0.5 1 0.5])
                        end;

                        if strcmp(Opto{i}, 'Stim_DLC') && k>=IndCritical
                            line([0 size(theseFrames, 2)], [0 0], 'linewidth', 4, 'color', [0 184 255]/255)
                            line([0 size(theseFrames, 2)], [size(theseFrames, 1) size(theseFrames, 1)], 'linewidth', 4, 'color', [0 184 255]/255)
                            line([0 0], [0 size(theseFrames, 1)], 'linewidth', 4, 'color', [0 184 255]/255)
                            line([size(theseFrames, 2) size(theseFrames, 2)], [0 size(theseFrames, 1)], 'linewidth', 4, 'color', [0 184 255]/255)
                        end;

                        text(10,  size(theseFrames, 1)-8,  [strrep([Opto{i}], '_', '-')], 'color', [1 1 0.4], 'fontsize', 6,'fontweight', 'bold')
                        text(100,  size(theseFrames, 1)-8,  sprintf('DLC-to-touch: %2.0f ms', -1000*(btable.tDLC(i) - btable.tPress(i))), ...
                            'color', [1 1 0.4], 'fontsize', 6,'fontweight', 'bold')
                        text(300,  size(theseFrames, 1)-8,  sprintf('tFrame: %2.0f ms', FrameTimeStampshat(k)*1000), 'color',[1 1 0.4], 'fontsize', 6,'fontweight', 'bold')
                        text(420,  size(theseFrames, 1)-8,  sprintf('Trial# %2.0d', i), 'color', [1 1 0.4], 'fontsize', 6,'fontweight', 'bold')


                        % plot or update data in this plot
                        F(k) = getframe(hf25) ;
                        drawnow

                    end
                    % make a video clip and save it to the correct location


                    writerObj = VideoWriter([video_name '.avi']);
                    writerObj.FrameRate = 10; % this is 10 x slower

                    % set the seconds per image
                    % open the video writer
                    open(writerObj);
                    % write the frames to the video
                    for ifrm=1:length(F)
                        % convert the image to a frame
                        frame = F(ifrm) ;
                        writeVideo(writerObj, frame);
                    end
                    % close the writer object
                    close(writerObj);
                    movefile( [video_name '.avi'], thisFolder)
                    MetaFileName = fullfile(thisFolder, [video_name, '.mat']);
                    save(MetaFileName, 'VidMeta');
                end;
            end;
        end;
    end;
end;

% Make a table to doc this job

btable      =     table(TrialNums, OptoStimTypes, DLCtoPressLatencyms);
writetable(btable, aGoodName)
