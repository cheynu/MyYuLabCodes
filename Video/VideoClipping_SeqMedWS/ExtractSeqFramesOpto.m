GetSeqFrameInfo([0 2000]+5*60*100);
load('FrameInfo.mat')
% FrameInfo = 
%   struct with fields:
%           tframe: [1×152719 double]
%             mask: [1080×1440 logical]
%              ROI: [1×152719 double]
%       SeqVidFile: {'20210330-12-23-00.000.seq'}
%      SeqFileIndx: [1×152719 double]
%     SeqFrameIndx: [1×152719 double]
%          MEDfile: '2021-03-30_12h14m_Subject Pineapple.txt'
         
h5file = dir('*.h5');
sout = ReadH5Opto(h5file.name);  % this gives data from wave surfer

MEDFile=dir('*.txt');
BpodFile = dir('Pineapple*.mat');
bu =  GetOptoBehApproach(MEDFile.name, BpodFile.name);
tbeh_trigger = bu.TimeTone*1000;  % in ms

% Map sout signal to MED time

sout = MapWave2B(sout, bu);

Extrct           =       "ExportSeqVideoFiles(bu, FrameInfo, sout, 'Event', 'Approach', 'TimeRange', [2000 5000], 'SessionName',strrep(FrameInfo.MEDfile(1:10), '-', ''), 'RatName', FrameInfo.MEDfile(27:strfind(FrameInfo.MEDfile, '.')-1), 'Remake', 1);";
%%  The goal is to align tLEDon and tbeh_trigger
% alignment and print
%% extract LED-On time
tLEDon = FindLEDon(FrameInfo.tframe, FrameInfo.ROI);

Indout = findseqmatch(tbeh_trigger-tbeh_trigger(1), tLEDon-tLEDon(1), 1);
% these LEDon times are the ones that cannot be matched to trigger. It must be a false positive signal that was picked up by mistake in "tLEDon = FindLEDon(tsROI, SummedROI);"
ind_badROI = find(isnan(Indout));
tLEDon(ind_badROI) = []; % remove them
Indout(ind_badROI) = []; % at this point, each LEDon time can be mapped to a trigger time in b (Indout)
FrameInfo.tLEDon = tLEDon;
FrameInfo.Indout = Indout;
%% Now, let's redefine the frame time. Each frame time should be re-mapped to the timespace in b.
% all frame times are here: FrameInfo.tframe
tframes_in_b = MapVidFrameTime2B(FrameInfo.tLEDon,  tbeh_trigger, Indout, FrameInfo.tframe);
FrameInfo.tFramesInB = tframes_in_b;

imhappy = 0;
while ~imhappy
    %% Empirically, some events are still not well aligned. In particually, in a small subset of trials, LED starts to light up at trigger time we need to revise these trials.
    % some tLEDon need to be revised.
    
    tLEDon = CorrectLEDtime(bu, FrameInfo); % update tLEDon
    Indout = findseqmatch(tbeh_trigger-tbeh_trigger(1), tLEDon, 1);
    % these LEDon times are the ones that cannot be matched to trigger. It must be a false positive signal that was picked up by mistake in "tLEDon = FindLEDon(tsROI, SummedROI);"
    ind_badROI = find(isnan(Indout));
    tLEDon(ind_badROI) = []; % remove them
    Indout(ind_badROI) = []; % at this point, each LEDon time can be mapped to a trigger time in b (Indout)
    FrameInfo.tLEDon = tLEDon;
    FrameInfo.Indout = Indout;
    tframes_in_b = MapVidFrameTime2B(FrameInfo.tLEDon,  tbeh_trigger, Indout, FrameInfo.tframe);
    FrameInfo.tFramesInB = tframes_in_b;
    clc
    reply = input('Are you happy? Y/N [Y]', 's');
    if isempty(reply)
        reply = 'Y';
    end;
    if strcmp(reply, 'Y')  ||  strcmp(reply, 'y')
        imhappy = 1;
    else
        imhappy =0;
    end
end;

%% check if the LED ON/OFF looks right around trigger stimulus
 roi_collect = CheckSeqFrameTrigger(bu, FrameInfo);
%% Check if Press and Release look alright
 CheckSeqFramePressRelease(bu, FrameInfo)
save FrameInfo FrameInfo
 
%  Making videos
eval(Extrct)
 