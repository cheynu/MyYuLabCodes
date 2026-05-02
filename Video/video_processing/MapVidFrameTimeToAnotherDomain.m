function tFramesOut = MapVidFrameTimeToAnotherDomain(tLEDon,  tBehaviorTimes, tFrames);

% Jianing Yu
% 5/1/2021
% given LED time, indout, and trigger time in b, conver the time of each
% frame to a time in behavior domain
% reivised 12/4/2022
% tLEDon and tBehaviorTimes have the same number of elements--they are
% matched. 

tFramesOut = []; % this is the frame time in behavior time domain
for i=1:length(tLEDon)
    if i==1
        frames_sofar = find(tFrames<=tLEDon(i));
    elseif  i ==length(tLEDon)
        frames_sofar = find(tFrames>tLEDon(i-1));
    else
        frames_sofar = find(tFrames>tLEDon(i-1) & tFrames<=tLEDon(i));
    end
    frames_sofar_remap = tFrames(frames_sofar) - tLEDon(i) + tBehaviorTimes(i);  % convert the frame time to time in the behavior domain
    tFramesOut         = [tFramesOut frames_sofar_remap];
end
