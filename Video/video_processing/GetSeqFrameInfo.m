function FrameInfo = GetSeqFrameInfo(SeqVidFile, frame_range, name, compute_ROI, mask)

% Jianing Yu
% 2021/5/21
% Get frame timestamps and ROI

%% Get frame times
if isempty(SeqVidFile)
    seqfiles = dir('*.seq');
    if length(seqfiles)>0;
        for i=1:length(seqfiles)
            SeqVidFile{i} = seqfiles(i).name;
        end;
    end;
end;

MedFile=dir('*.txt');

if nargin<5
    mask = [];
    if nargin<4
        compute_ROI = 1;
        if nargin<3
            name = [];
            if nargin<2
                frame_range = [3200 3200]+5*60*100;
            end
        end
    end
end
%% extract mask, use frames from 5*60*50 to 5*60*50+60*50
if compute_ROI
    if ~isempty(mask)
        save('mask.mat', 'mask')
    elseif isempty(dir('mask.mat'))
        mask = ExtractMaskSeq(SeqVidFile{1}, frame_range);
        save('mask.mat', 'mask')
    else
        load('mask.mat','mask')
    end
else
    mask = [];
end
%% based on "mask", extract pixel intensity in ROI from all frames
tsROI = [];
tsOrg = [];
SummedROI = [];
SeqFrameIndx = [];
SeqFileIndx = [];
tic

clc
sprintf('Extracting ......')

% set up a start time for all video clips

tstart = 0;

for i=1:length(SeqVidFile)    
    %  Read all frames:
    kframe =1;
    keepreading = 1;
 
    while keepreading ==1
        try
            [thisFrame]         =   ReadJpegSEQ(SeqVidFile{i}, [kframe kframe]);
            tf           = thisFrame{2};
            if ~isempty(mask)
                imgOut = double(thisFrame{1});
                roi_k = sum(imgOut(mask));
            else
                roi_k = [];
            end
            
            tf_hr    =      str2num(tf([13 14]))*3600*1000;
            tf_mn    =      str2num(tf([16 17]))*60*1000;
            tf_ss    =      str2num(tf([19 20]))*1000;
            tf_ms    =      str2num(tf([22:end]))/1000;
            tf_current = round(sum([tf_hr, tf_mn, tf_ss, tf_ms]));
            
            if kframe == 1 && i == 1 % only define tstart once
                tstart = tf_current;
            else
                if tf_current > tstart
                    keepreading = 1;
                else
                    keepreading = 0;
                end
            end
            
            if keepreading
                tsOrg                =   [tsOrg tf_current];
                tf_current          =   tf_current - tstart;
                tsROI                 =   [tsROI tf_current];
                SummedROI     =   [SummedROI roi_k];
                SeqFrameIndx   =   [SeqFrameIndx kframe];
                SeqFileIndx        =   [SeqFileIndx i];
                kframe = kframe + 1;
            end
            
            if rem(kframe, 600*100)==0
                sprintf('60000 frames (~ 10min) extracted %2.0d ', kframe/6000)
            end            
        catch
            keepreading = 0;
        end;        
    end;
end;
toc

tsROI = tsROI - tsROI(1); % onset normalized to 0
FrameInfo                          =   [];
FrameInfo.tframeOrg        = tsOrg;
FrameInfo.tframe               = tsROI;
FrameInfo.mask                 = mask;
FrameInfo.ROI                   = SummedROI;
FrameInfo.SeqVidFile        = SeqVidFile;
FrameInfo.SeqFileIndx        = SeqFileIndx;
FrameInfo.SeqFrameIndx   = SeqFrameIndx;

if ~isempty(MedFile)
    FrameInfo.MEDfile              = MedFile.name;
end;
aGoodName = ['FrameInfo' name '.mat'];
% Save for now because it takes a long time to get tsROI
save(aGoodName, 'FrameInfo') 