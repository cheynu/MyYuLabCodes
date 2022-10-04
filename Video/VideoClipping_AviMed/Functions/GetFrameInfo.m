function FrameInfo = GetFrameInfo(fileinfo,frame_range)
%These are the required video and behavioral files.
 
VidFiles = fileinfo.Vids;
TsFiles = fileinfo.Txts;
MEDfile = fileinfo.MED;

mask = ExtractMask(VidFiles{1}, frame_range);
%% based on "mask", extract pixel intensity in ROI from all frames
numFrames = [];
for i=1:length(VidFiles)
    vidObj = VideoReader(VidFiles{i});
    numFrames = [numFrames,vidObj.NumFrames];
    clear vidObj;
end
allFrames = sum(numFrames);

tsROI           = [];
SummedROI       = [];
AviFrameIndx    = [];
AviFileIndx     = [];

if length(VidFiles)==length(TsFiles)
    Only1Ts = false;
else
    Only1Ts = true;
end

% wtic = tic;
% fbar = waitbar(0,'Masking time remaining: calculating...');
% idxFrame = 0;
lenTiming = 500;
parfor_progress(ceil(allFrames./lenTiming));
for i=1:length(VidFiles)
    if ~Only1Ts
        fileID = fopen(TsFiles{i}, 'r');
    else
        fileID = fopen(TsFiles{1}, 'r');
    end
    formatSpec   = '%f' ;
    NumOuts      = fscanf(fileID, formatSpec); % this contains frame time (in ms) and frame index    
    fclose(fileID);
    
    ind_brk = find(NumOuts==0);
    FrameTs = NumOuts(1:ind_brk-1);  % frame times
%     FrameIdx = NumOuts(ind_brk+1:end);  % frame idx    
    filename = VidFiles{i};
    vidObj = VideoReader(filename);
    parfor k=1:vidObj.NumFrames
        idxFrame = sum(numFrames(1:i))-numFrames(i)+k;
%         idxFrame = idxFrame + 1;
        if rem(idxFrame,lenTiming)==0
%             costTime = toc(wtic);
%             remainTimeS = costTime./idxFrame.*(allFrames-idxFrame);
%             remainTimeM = ceil(remainTimeS./60);
%             remainTime = [num2str(remainTimeM),' min'];
%             waitbar(idxFrame/allFrames, fbar, ['Masking time remaining: ',remainTime]);
            parfor_progress;
        end
        
        thisFrame = read(vidObj, k);
        thisFrame = thisFrame(:, :, 1);
        roi_k = sum(thisFrame(mask));
        if ~Only1Ts
            tsROI = [tsROI FrameTs(k)];
        else
            tsROI = [tsROI FrameTs(idxFrame)];
        end
        SummedROI       = [SummedROI roi_k];
        AviFileIndx     = [AviFileIndx i];
        AviFrameIndx    = [AviFrameIndx k];
    end
    clear vidObj;
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
FrameInfo.AviFile       = VidFiles;
FrameInfo.AviFileIndx	= AviFileIndx;
FrameInfo.AviFrameIndx	= AviFrameIndx;
FrameInfo.MEDfile       = MEDfile;

%% Save for now because it takes a long time to get tsROI
save FrameInfo FrameInfo
end

