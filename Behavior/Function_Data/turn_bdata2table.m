function thisTable = turn_bdata2table(bdata, varargin);
% Turn bdata (from track_training_progress_advanced.m) to a table
%  turn_bdata2table(bdata, 'save', 1, 'filename', [], 'path', [])
% Jianing Yu
% 8/27/2022
tosave = 0;
savepath = pwd;

% make a file name
a = strrep(strrep(bdata.SessionName, '-', '_'), ' ', '_');
filename = [extractAfter(a, 'Subject_') '_' extractBefore(a, '_Subject')];

for i=1:2:size(varargin,2)
    switch varargin{i}
        case {'save', 'Save'}
            tosave = varargin{i+1};
        case {'path'}
            if ~isempty(varargin{i+1})
            savepath = varargin{i+1};
            end;
        case {'filename'}
             if ~isempty(varargin{i+1})
            filename = varargin{i+1};
             end;
    end;
end;

% number of trials
N_trials = length(bdata.PressTime);

% Session information
Subject = repmat({extractAfter(bdata.SessionName, 'Subject ')}, N_trials, 1);
Session = repmat(extractBefore(bdata.SessionName, '-Subject '), N_trials, 1);
Date = repmat(bdata.Metadata.Date, N_trials, 1);
Protocol = repmat({extractAfter(bdata.Metadata.ProtocolName, 'FR1_')}, N_trials, 1);

LesionIndex = zeros(N_trials, 1);

% Press
PressIndex = [1:N_trials]';
PressTime = bdata.PressTime';
ReleaseTime = bdata.ReleaseTime';
ReactionTime = [];
ToneTime = [];
FP_ms = bdata.FPs';
Outcome = [];

for i =1:length(bdata.PressTime)
    if ~isempty(find(bdata.Correct == i, 1))
        Outcome{i} = 'Correct';
        % find tone time
        ToneTime(i) = bdata.TimeTone(find(bdata.TimeTone-bdata.PressTime(i)>0, 1, 'first'));
        ReactionTime(i) = ReleaseTime(i) - ToneTime(i); 
    elseif  ~isempty(find(bdata.Premature == i, 1))
        Outcome{i} = 'Premature';
        ToneTime(i)= -1;
        ReactionTime(i) = -1; 
    elseif ~isempty(find(bdata.Late == i, 1))
        Outcome{i} = 'Late';
        ToneTime(i) = bdata.TimeTone(find(bdata.TimeTone-bdata.PressTime(i)>0, 1, 'first'));
        ReactionTime(i) = ReleaseTime(i) - ToneTime(i);
    elseif ~isempty(find(bdata.Dark == i, 1))
        Outcome{i} = 'Dark';
        ToneTime(i)= 0;
        ReactionTime(i) = 0;
    else
        Outcome{i} = 'NAN';
        ToneTime(i)= 0;
        ReactionTime(i) = 0;
    end;
end;

PressTime_s =PressTime;
ReleaseTime_s = ReleaseTime;
Outcome = Outcome';
ToneTime_s = ToneTime';
ReactionTime_s = ReactionTime';
thisTable = table(Subject, Date, Session, Protocol, LesionIndex, PressIndex, PressTime_s, ReleaseTime_s, FP_ms, ToneTime_s, ReactionTime_s, Outcome);

if tosave
    filename = fullfile(savepath, [filename '.csv']);
    writetable(thisTable,filename);
end;
end