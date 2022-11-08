function FrameInfo = GetSeqFrameInfo_Bpod(frame_range,BpodFile)
switch nargin
    case 0
        frame_range = [0,1]+5*60*50;
        BpodFile = arrayfun(@(x)x.name, dir('*DSRT*.mat'), 'UniformOutput', false);
    case 1
        BpodFile = arrayfun(@(x)x.name, dir('*DSRT*.mat'), 'UniformOutput', false);
    otherwise
        % pass
end
idx_udl = strfind(BpodFile{1},'_');
sbj = BpodFile{1}(1:idx_udl(1)-1);
date = BpodFile{1}(idx_udl(4)+1:idx_udl(5)-1);
%% Extract mask, use frames from 5min*60s/min*50frame/s to 6min*60*50 (default)
SeqVidFile = arrayfun(@(x)x.name, dir('*.seq'), 'UniformOutput', false);

mask = ExtractMaskSeq(SeqVidFile{1}, frame_range);
%% based on "mask", extract pixel intensity in ROI from all frames
numFrames = [];
for i=1:length(SeqVidFile)
    [~,headerInfo] = ReadJpegSEQ(SeqVidFile{i}, [1 1]);
    numFrames = [numFrames,headerInfo.AllocatedFrames];
end
allFrames = sum(numFrames);

tsROI = [];
SummedROI = [];
SeqFrameIndx = [];
SeqFileIndx = [];

% wtic = tic;
% fbar = waitbar(0,'Masking time remaining: calculating...','Name',[sbj,' ',date]);
% idxFrame = 0;
parfor_progress(ceil(allFrames./500));
for i=1:length(SeqVidFile)
    %  Read all frames:
%     firstFrame = ReadJpegSEQ(SeqVidFile{i}, [1 1]);
%     tstart = calTF(firstFrame{2}); % every video has a time scale
    parfor kframe=1:numFrames(i)
        idxFrame = sum(numFrames(1:i))-numFrames(i)+kframe;
%         idxFrame = idxFrame + 1;
        if rem(idxFrame,500)==0
%             costTime = toc(wtic);
%             remainTimeS = costTime./idxFrame.*(allFrames-idxFrame);
%             remainTimeM = ceil(remainTimeS./60);
%             remainTime = [num2str(remainTimeM),' min'];
%             waitbar(idxFrame/allFrames, fbar, ['Masking time remaining: ',remainTime]);
            parfor_progress;
        end
        
        thisFrame = ReadJpegSEQ(SeqVidFile{i}, [kframe kframe]);
        imgOut    = double(thisFrame{1});
        tf_current = calTF(thisFrame{2});
        
        roi_k = sum(imgOut(mask));
%         tf_current = tf_current - tstart;
        
        tsROI           = [tsROI tf_current];
        SummedROI       = [SummedROI roi_k];
        SeqFrameIndx    = [SeqFrameIndx kframe];
        SeqFileIndx     = [SeqFileIndx i];
    end
end
% close(fbar);
parfor_progress(0);
parObj = gcp('nocreate');
delete(parObj);

tsROI = tsROI - tsROI(1); % onset normalized to 0
FrameInfo               = [];
FrameInfo.tframe        = tsROI;
FrameInfo.mask          = mask;
FrameInfo.ROI           = SummedROI;
FrameInfo.SeqVidFile    = SeqVidFile;
FrameInfo.SeqFileIndx   = SeqFileIndx;
FrameInfo.SeqFrameIndx  = SeqFrameIndx;
FrameInfo.Bpodfile      = BpodFile;

%% Save (because it takes a long time to get tsROI)
save FrameInfo FrameInfo
end

function tfOut = calTF(tfIn)
tf_hr = str2num(tfIn([13 14]))*3600*1000;
tf_mn = str2num(tfIn([16 17]))*60*1000;
tf_ss = str2num(tfIn([19 20]))*1000;
tf_ms = str2num(tfIn([22:end]))/1000;

tfOut = round(sum([tf_hr, tf_mn, tf_ss, tf_ms]));
end
