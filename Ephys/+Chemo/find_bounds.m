function [seg_onset, seg_offset, durs]=find_bounds(r)
% function [seg_onset, seg_offset, durs]=find_bounds(r)
% in seconds
% look at r and find the beginning and ending of each recording segments. 
% Jianing Yu 3/29/2023

% number of segments
nseg                    =       length(r.Meta);
seg_onset           =       zeros(1, nseg);
seg_offset           =       zeros(1, nseg);
durs                     =      zeros(1, nseg);
durs(1)                 =       r.Meta(1).DataDurationSec;
seg_offset(1)       =       durs(1)+seg_onset(1);

if nseg>1
    for i =2:nseg
        dt_i                    =         r.Meta(i).DateTimeRaw - r.Meta(i-1).DateTimeRaw; % start time of this session relative to the first session
        seg_onset(i)      =         seg_onset(i-1) + dt_i(end)/1000+dt_i(end-1)+dt_i(end-2)*60+dt_i(end-3)*60*60;  % convert time to ms
        durs(i)               =          r.Meta(i).DataDurationSec; 
        seg_offset(i)      =         seg_onset(i) + durs(i);  % convert time to ms
    end;
end;
