function FrameIndOut = TrackFrameTime(iDLCTime, TimeOfDLCMapped2Bpod, StimTimesClushat, PosData);

% Jianing Yu
% 3/29/2022

% Here we find out the video index of a DLC-triggered event recorded in
% Bpod

% Note that iDLCTime is not padded with the starting time of a trial

ind_DLC = find(TimeOfDLCMapped2Bpod == iDLCTime);
thisStimTimeClusHat = StimTimesClushat(ind_DLC);

ind_PosD
