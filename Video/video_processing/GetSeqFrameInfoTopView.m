function FrameInfo = GetSeqFrameInfoTopView(FrameInfo, SeqVidFile)

% Jianing Yu
% 2021/5/21
% Get frame timestamps and ROI
% 2021/12/19
% Add top-view video to FrameInfo

%% Get frame times
if isempty(SeqVidFile)
    seqfiles = dir('*.seq');
    if length(seqfiles)>0;
        for i=1:length(seqfiles)
            SeqVidFile{i} = seqfiles(i).name;
        end;
    end;
end;
  
%% based on "mask", extract pixel intensity in ROI from all frames
 
SeqFrameIndx = [];
SeqFileIndx = [];
tic

clc
sprintf('Extracting ......')

% set up a start time for all video clips

tstart = 0;
tsROI = [];
for i=1:length(SeqVidFile)
    
    %  Read all frames:
    kframe =1;
    keepreading = 1;
 
    while keepreading ==1
        try
            [thisFrame]         =   ReadJpegSEQ(SeqVidFile{i}, [kframe kframe]);
            imgOut = double(thisFrame{1});
            tf           = thisFrame{2};
 
            tf_hr      =    str2num(tf([13 14]))*3600*1000;
            tf_mn    =      str2num(tf([16 17]))*60*1000;
            tf_ss      =      str2num(tf([19 20]))*1000;
            tf_ms    =      str2num(tf([22:end]))/1000;
            
            tf_current = round(sum([tf_hr, tf_mn, tf_ss, tf_ms]));
            
            if kframe == 1 && i == 1; % only define tstart once
                tstart = tf_current;
            else
                if tf_current > tstart
                    keepreading = 1;
                else
                    keepreading = 0;
                end;
            end;
            
            if keepreading
                tf_current          =   tf_current - tstart;
                
                tsROI                 =   [tsROI tf_current];
 
                SeqFrameIndx   =   [SeqFrameIndx kframe];
                SeqFileIndx        =   [SeqFileIndx i];
                
                kframe = kframe + 1;
            end;
            
            if rem(kframe, 1000)==0
                sprintf('1000s frames extracted %2.0d ', kframe/1000)
            end
            
        catch
            keepreading = 0;
        end;
        
    end;
end;
toc

tsROI = tsROI - tsROI(1); % onset normalized to 0
FrameInfo.tframe_TopView               = tsROI;
FrameInfo.SeqVidFile_TopView        = SeqVidFile;
FrameInfo.SeqFileIndx_TopView        = SeqFileIndx;
FrameInfo.SeqFrameIndx_TopView   = SeqFrameIndx;
