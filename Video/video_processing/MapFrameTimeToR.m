function r = MapFrameTimeToR(r, ts)
 
% 4/20/2021
%Jianing Yu
% update/add frame signal

% 10/23/2022 JY
% reivsed. added a match algorithm to align frame signal and video
% timestamps

%% extract frame signal from original line
indframe = find(strcmp(r.Behavior.Labels, 'FrameOn'));
t_frameon = r.Behavior.EventTimings(r.Behavior.EventMarkers == indframe);

ind_break = find(diff(t_frameon)>1000);
t_seg =[];
if isempty(ind_break)
    t_seg{1} = t_frameon;
else
    ind_break = [1; ind_break+1];
    for i =1:length(ind_break)
        if i<length(ind_break)
            t_seg{i}=t_frameon(ind_break(i):ind_break(i+1)-1);
        else
            t_seg{i}=t_frameon(ind_break(i):end);
        end;
    end;
end;

%% add Video session 
if isfield(r, 'Video')
    r= rmfield(r, 'Video');
end;

if ~isempty(ts)
    r.Video.ts = ts;
end;

r.Video.TimeStamps.SideVideoIndex = [];
r.Video.TimeStamps.SideVideoFrameTime2Ephys = [];
 r.Video.TimeStamps.SideVideoFrameTimeOrg    = [];
if isfield(ts, 'side')
    r.Video.TimeStamps.SideVideoFileNames =  ts.sideviews;
    for i =1:length(t_seg)
        tseq_blackrock = t_seg{i};
        tseq_videoframe = ts.side(i).ts;
        % goal is to align these two sequence
        if length(tseq_videoframe) == length(tseq_blackrock)
            tseq_mapped = tseq_blackrock';
        else
            tseq_mapped = mapframe2blackrock(tseq_videoframe,  tseq_blackrock); % time of each frame mapped to blackrock's time
        end;
        r.Video.TimeStamps.SideVideoIndex                                =     [r.Video.TimeStamps.SideVideoIndex i*ones(1,  length(tseq_mapped))];
        r.Video.TimeStamps.SideVideoFrameTime2Ephys          =      [r.Video.TimeStamps.SideVideoFrameTime2Ephys tseq_mapped];
        r.Video.TimeStamps.SideVideoFrameTimeOrg                =      [r.Video.TimeStamps.SideVideoFrameTimeOrg  tseq_videoframe];
    end;
end;


r.Video.TimeStamps.TopVideoIndex = [];
r.Video.TimeStamps.TopVideoFrameTime2Ephys = [];
r.Video.TimeStamps.TopVideoFrameTimeOrg = [];
if isfield(ts, 'top')
    r.Video.TimeStamps.TopVideoFileNames =  ts.topviews;
    for i =1:length(t_seg)
        tseq_blackrock = t_seg{i};
        tseq_videoframe = ts.top(i).ts;
        % goal is to align these two sequence
        if length(tseq_videoframe) == length(tseq_blackrock)
            tseq_mapped = tseq_blackrock';
        else
            tseq_mapped                                                              =     MapTopToSide(tseq_videoframe,  r, i); % time of each frame mapped to blackrock's time
        end;
        r.Video.TimeStamps.TopVideoIndex                                =     [r.Video.TimeStamps.TopVideoIndex i*ones(1,  length(tseq_mapped))];
        r.Video.TimeStamps.TopVideoFrameTime2Ephys          =      [r.Video.TimeStamps.TopVideoFrameTime2Ephys tseq_mapped];
        r.Video.TimeStamps.TopVideoFrameTimeOrg                =      [r.Video.TimeStamps.TopVideoFrameTimeOrg  tseq_videoframe];

    end;
end;


tic
save RTarrayAll r
toc

function tout = mapframe2blackrock(frametime, triggertime)

if length(frametime) == length(triggertime)
    tout = triggertime';
else
    % tseq_mapped = mapframe2blackrock(tseq_videoframe, tseq_blackrock);
    triggerorg = triggertime;
    triggertime= triggertime-triggertime(1);
    frametime = frametime - frametime(1);
    tout = zeros(1, length(frametime));
    index = zeros(1, length(frametime));
    % assume the first frame is captured
    i = 1;
    tout(1) = triggerorg(1);
    index(1)= 1; 
    tic

    triggertimeprime = triggertime;
    mindist_all = 0;

    for i =2:length(frametime)
        if rem(i, 6000) == 0
            disp('Another 1 min of frames processed')
        end;
        % distance from last frame
        i_dt_frame = frametime(i) - frametime(i-1);
        % distance in trigger signal from last alignment
        i_dt_trigger = triggertimeprime - triggertimeprime(index(i-1));
        [mindist, indmin] = min(abs(i_dt_trigger-i_dt_frame));
        index(i) = indmin;
        mindist_all = [mindist_all mindist];

    end;

    figure; hist(mindist_all, 100)
    tout(2:length(frametime)) = triggerorg(index(2:end));
end;


function tout_mapped = MapTopToSide(tseq_videoframe, r, ind)

SideVideoFrameTimes                     =          r.Video.TimeStamps.SideVideoFrameTimeOrg(r.Video.TimeStamps.SideVideoIndex == ind);
SideVideoFrameTimesMapped        =          r.Video.TimeStamps.SideVideoFrameTime2Ephys(r.Video.TimeStamps.SideVideoIndex == ind);

tout_mapped = NaN*ones(1, length(tseq_videoframe));

last_ind = [];
allmindt = [];

for i =1:length(tseq_videoframe)
    if rem(i, 6000) == 0
        disp('Another 1 min of frames processed')
    end;
    it = tseq_videoframe(i);
    [mindt, indexmindt] = min(abs(SideVideoFrameTimes - it));
    allmindt = [allmindt mindt];

    if mindt<2
        if last_ind == indexmindt
           continue
        end;
        last_ind = indexmindt;
        tout_mapped(i) = SideVideoFrameTimesMapped(indexmindt);
    end;
end;
