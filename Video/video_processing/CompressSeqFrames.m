function FrameInfo = CompressSeqFrames(SeqVidFile, keepRatio)
% Jianing Yu, modified 2025/4/15
% Extracts frames from .seq file, compresses them, and saves as .mp4
% Input:
%   SeqVidFile: path to .seq file or empty to search for .seq files

%% Initialize inputs
if nargin<2 || isempty(keepRatio)
    keepRatio = 1;
end
if nargin < 1 || isempty(SeqVidFile)
    seqfiles = dir('*.seq');
    if ~isempty(seqfiles)
        SeqVidFile = {seqfiles.name};
    else
        error('No .seq files found in directory');
    end
end

if ischar(SeqVidFile)
    SeqVidFile = {SeqVidFile};
end

for i = 1:length(SeqVidFile)
    %% Setup video writer
    % Use the first .seq file name for the output .mp4
    [~, baseName, ~] = fileparts(SeqVidFile{i});
    outputVideoFile = [baseName '.mp4'];
    v = VideoWriter(outputVideoFile, 'MPEG-4');
    v.FrameRate = 30; % Adjust as needed
    open(v);
    %% Extract frames and process
    tsROI = [];
    tsOrg = [];
    SeqFrameIndx = [];
    SeqFileIndx = [];
    tstart = 0;
    fprintf('Extracting and compressing frames...\n');
    tic
    kframe = 1;
    keepreading = 1;

    while keepreading
        img = ReadJpegSEQ3(SeqVidFile{i}, kframe);
        if ~isempty(img)
            tf_current = ReadTimestampSEQ(SeqVidFile{i}, kframe);
            % Set start time
            if kframe == 1 && i == 1
                tstart = tf_current;
            else
                if tf_current <= tstart
                    keepreading = 0;
                    continue;
                end
            end
            % Write frame to video
            writeVideo(v, img);
            % Store frame info
            tsOrg = [tsOrg tf_current];
            tf_current = tf_current - tstart;
            tsROI = [tsROI tf_current];
            SeqFrameIndx = [SeqFrameIndx kframe];
            SeqFileIndx = [SeqFileIndx i];
            kframe = kframe + round(1/keepRatio);
            % Progress update
            if rem(kframe, 600*100) == 0
                fprintf('Processed %d frames (~10min)\n', kframe);
            end
        else
            keepreading=0;
            fprintf('The end is reached at %d \n', kframe);
        end
    end
    %% Finalize video
    close(v);
    fprintf('Video saved as %s\n', outputVideoFile);
    %% Store frame info
    tsROI = tsROI - tsROI(1); % Normalize to 0
    FrameInfo = struct();
    FrameInfo.tframeOrg = tsOrg;
    FrameInfo.tframe = tsROI;
    FrameInfo.SeqVidFile = SeqVidFile;
    FrameInfo.SeqFileIndx = SeqFileIndx;
    FrameInfo.SeqFrameIndx = SeqFrameIndx;

    %% Save FrameInfo
    aGoodName = ['FrameInfo_' baseName '.mat'];
    save(aGoodName, 'FrameInfo');
    fprintf('FrameInfo saved as %s\n', aGoodName);

    toc
end
end
