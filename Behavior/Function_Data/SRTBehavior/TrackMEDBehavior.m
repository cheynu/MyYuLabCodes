function [bout, bclass] = TrackMEDBehavior(filename, MEDProtocol)

% Hanbo Wang, Dec 2022
% Use @UpdataB to add FP data for wait protocols

% Revised from @track_training_progress_advanced (Jianing Yu Oct 2019)
arguments
    filename char{mustBeFile} = dir('*Subject*.txt');
    MEDProtocol string {mustBeMember(MEDProtocol, ...
        ["AutoShapine", "LeverPress", "LeverRelease", ...
         "Wait1", "Wait2", "Wait", "2FPs", "3FPs"])} = "2FPs"
end
SessionName   = strrep(filename(1:end-4), '_', '-');
tEvents       = med_to_tec_new(filename, 100);
bout.Metadata = med_to_protocol(filename);

%% find out press-time
% time of lever presses / releases
tPress   = tEvents(tEvents(:, 2) == 1, 1);
tRelease = tEvents(tEvents(:, 2) == 4, 1);

if length(tRelease) < length(tPress) % final release was not registered before the session ended. 
    tPress = tPress(1:end-1);
end
% press duration for each press, in ms
if tRelease(1) < tPress(1)
    tRelease(1) = [];
end
if tRelease(end) < tPress(end)
    tPress(end) = [];
end
if length(tRelease) > length(tPress)
    tRelease(end) = [];
end

%% find out reward time
idxReward = find(tEvents(:, 2) == 13);
if isempty(idxReward)
    idxReward = find(tEvents(:, 2) == 18);
end
tReward = tEvents(idxReward, 1);

% LeverPress & LeverRelease will give free water after the first minute
tTone = tEvents(tEvents(:, 2) == 11, 1);
if ismember(MEDProtocol, ["LeverPress", "LeverRelease"])
    if tTone(1) > 60
        tTone(1)   = [];
        tReward(1) = [];
    end
end

%% find out successful presses
idxGoodPress = [];
nPress = length(tPress);
for i = 1:nPress
    % For LeverPress and LeverRelease protocol, reward signal had 0.1s latency
    % and sometimes they just don't match exactly
    if MEDProtocol == "LeverPress"
        idx = find(abs(tReward - tPress(i) - 0.1) <= 0.001, 1);
    elseif MEDProtocol == "LeverRelease"
        idx = find(abs(tReward - tRelease(i) - 0.1) <= 0.001, 1);
    else
        idx = tReward == tRelease(i);
    end
    if any(idx)
        idxGoodPress = [idxGoodPress i]; %#ok<*AGROW> 
    end
end
idxBadPress = setdiff(1:nPress, idxGoodPress);  % bad presses include both early and premature release

%% find out premature releases
tPremature = tEvents(tEvents(:, 2) == 50, 1);
[~, idxPremature] = intersect(tRelease, tPremature);

%% find out late releases
tLate = tEvents(tEvents(:, 2) == 51, 1);   % this is the time of late_error z pulse
idxLate = [];
for i = 1:length(tLate)
   idxLate = [idxLate find((tPress-tLate(i)).*(tRelease-tLate(i)) <= 0)];
end
tLate = tRelease(idxLate);

%% find out presses that occur when the lever light is off (inter-trial presses)
% find out lever-light-on/off time
tLeverLightOn  = tEvents(tEvents(:, 2) == 15, 1);
tLeverLightOff = tEvents(tEvents(:, 2) == 25, 1);
idxDarkPress = [];
for i = 1:length(idxBadPress)
    % most recent light ON/OFF
    recentLightOn = tLeverLightOn(find(tLeverLightOn < tPress(idxBadPress(i)), 1, 'last'));
    recentLightOff = tLeverLightOff(find(tLeverLightOff < tPress(idxBadPress(i)), 1, 'last'));
    if ~isempty(recentLightOn) && ~isempty(recentLightOff) && recentLightOff > recentLightOn
        idxDarkPress = [idxDarkPress idxBadPress(i)];
    end 
end

%% find out reaction time
nTone = length(tTone);
RT = nan(1, nTone);
idxToneLate = nan(nTone, 1);
for i = 1:nTone
    if ~isempty(tRelease(find(tRelease >= tTone(i), 1, 'first')))
        itRelease = tRelease(find(tRelease>=tTone(i), 1, 'first'));
        RT(i) = 1000*(itRelease-tTone(i));
        if isempty(find(itRelease == tLate, 1))  % not a late release
            idxToneLate(i) = 0;
        else
            idxToneLate(i) = 1;  % lever releases were late in response to these tones
        end
    end
end

% find out FP requirement:
FPs = [];
try
    fp_events = med_to_tec_fp(filename, 100);
    if size(fp_events, 1) >= length(tPress)  % if this checks out, foreperiod requirement is documented.
        FPs = fp_events(1: length(tPress), 2)*10;
    else
        FPs = NaN*ones(length(tPress), 1);
    end
catch
    disp("Add FP by @UpdateWaitB");
end

% outcome of all trials
Outcome = [];
for i = 1:length(tPress)
    if any(find(i==idxGoodPress))
        iOutcome = "Correct";
    elseif any(find(i==idxPremature))
        iOutcome = "Premature";
    elseif any(find(i==idxLate))
        iOutcome = "Late";
    elseif any(find(i==idxDarkPress))
        iOutcome = "Dark";
    else
        iOutcome = "NaN";
    end
    Outcome = [Outcome iOutcome];
end

%% save data
bout.SessionName  = SessionName;
bout.PressTime    = tPress';
bout.ReleaseTime  = tRelease';
bout.Correct      = idxGoodPress;
bout.Premature    = idxPremature';
bout.Late         = idxLate;
bout.Dark         = idxDarkPress;
bout.ReactionTime = RT;
bout.TimeTone     = tTone';           % trigger signal for release 
bout.IndToneLate  = idxToneLate';
bout.FPs          = FPs';
bout.Outcome      = Outcome;

if isempty(bout.FPs)
    bout = UpdateWaitB(bout);
end

savename = ['B_' upper(bout.Metadata.SubjectName) '_' strrep(bout.Metadata.Date, ...
    '-', '_') '_' strrep(bout.Metadata.StartTime, ':', '')];
b = bout;
save(savename, 'b');

bclass = Behavior.SRT.BehaviorClass(b);
bclass.Save();
