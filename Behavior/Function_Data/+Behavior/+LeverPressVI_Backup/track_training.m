function vb = track_training(bpodfile, medfile, ifPlot, opts)
%TRACK_TRAINING_PROGRESS_FROM_BPOD 此处显示有关此函数的摘要
%   此处显示详细说明

arguments
    bpodfile {char}
    medfile {char} = ''
    ifPlot = true;
    opts.SavePath = '';
end

if isfile(bpodfile)
    fileDir = dir(bpodfile);
    load(bpodfile,'SessionData');
else
    error('File "%s" not found!',bpodfile);
end
if isempty(opts.SavePath)
    pathSave = fileDir.folder;
else
    pathSave = opts.SavePath;
end
if isempty(medfile)
    medDir = dir('*_Subject*.txt');
    if ~isempty(medDir)
        medfile = medDir(1).name;
    end
end

nMinRound = 4; % 0.0001 second
minStep = 1/(10^nMinRound);
%% Basic info
vb = struct; % variable interval behavior

vb.Subject = extractBefore(bpodfile,'_');
vb.Group = ''; % add grouping variable for subject
vb.Experiment = ''; % add grouping variable for session
session = extractAfter(bpodfile,'LeverPressVI_');
session = extractBefore(session,'.mat');
vb.Session = session;

date = session(1:8);
vb.Date = date;
vb.DateTime = datetime(SessionData.Info.SessionStartTime_MATLAB,'ConvertFrom','datenum');

% extract result
Custom = SessionData.Custom;
nTrial = length(Custom.VI_EndTime);
if isfield(Custom,'SessionType')
    switch Custom.SessionType
        case 'Default'
            isExtinction = false;
        case 'Extinction'
            isExtinction = true;
    end
else
    isExtinction = false;
end
isNoReward = SessionData.TrialSettings(1).GUI.RewardAmount<0.01; % e.g., 0 or 0.001
vb.isExtinction = isExtinction; % no port light
vb.isNoReward = isNoReward; % extinction with port light
vb.isDevaluation = false;

% session duration
t0 = SessionData.TrialStartTimestamp(1);
max_trial_set = SessionData.TrialSettings(1).GUI.Max_Trial;
max_duration_set = SessionData.TrialSettings(1).GUI.Max_Duration;
if nTrial>=max_trial_set-3 % (almost) complete preset trial num
    SessionDuration = SessionData.TrialEndTimestamp(nTrial)-t0;
elseif SessionData.TrialEndTimestamp(nTrial)-t0>=max_duration_set % time's up, not completing all trials
    % there may be some events made by human after max_duration_set (to end
    % up the trial for data storage)
    % Just use the events during SessionDuration
    SessionDuration = max_duration_set;
else
    warning('Unexpected trial number & session duration. Please check the raw data.\n\n');
    SessionDuration = SessionData.TrialEndTimestamp(nTrial)-t0;
end

%% re-extract press & poke info
tEvent.SessionStartTime = t0;
tEvent.PokeIn = [];
tEvent.PokeOut = [];
tEvent.Press = [];
tEvent.Release = [];
tPressState = [];
tGoodPokeFirst = [];
tEventTrial.SessionStartTime = t0;
tEventTrial.VI_EndTime = [];
tEventTrial.BadPress = {};
tEventTrial.GoodPress = [];
tEventTrial.RetrievalLatency = [];
tEventTrial.BadPokeIn = {};
tEventTrial.BadPokeOut = {};
tEventTrial.GoodPokeIn = {};
tEventTrial.GoodPokeOut = {};

for i=1:nTrial
    tTrialStart = SessionData.TrialStartTimestamp(i);
    States = SessionData.RawEvents.Trial{i}.States;
    Events = SessionData.RawEvents.Trial{i}.Events;
    % extract the time in session of each event
    if isfield(Events,'Port1In')
        pokein = Events.Port1In;
        tEvent.PokeIn = [tEvent.PokeIn; pokein(:)+tTrialStart];
    else
        pokein = [];
    end
    if isfield(Events,'Port1Out')
        pokeout = Events.Port1Out;
        tEvent.PokeOut = [tEvent.PokeOut; pokeout(:)+tTrialStart];
    else
        pokeout = [];
    end
    if isfield(Events,'AnalogIn1_1')
        press = Events.AnalogIn1_1;
        tEvent.Press = [tEvent.Press; press(:)+tTrialStart];
    else
        pokein = [];
    end

    % get the time aligned to every VI_EndTime
    tVI_End = States.WaitForVI_End(end,2);
    tEventTrial.VI_EndTime = [tEventTrial.VI_EndTime tVI_End+tTrialStart];
    tZero = tVI_End;
    
    % % Bad press (from states)
    % badpress = [];
    % if any(~isnan(States.BadLeverPress_VI))
    %     badpress = [badpress; States.BadLeverPress_VI(:,1)];
    % end
    % if any(~isnan(States.BadLeverPress_PostVI))
    %     badpress = [badpress; States.BadLeverPress_PostVI(:,1)];
    % end
    % % Good press (from states)
    % goodpress = NaN;
    % if any(~isnan(States.RewardedPress))
    %     goodpress = States.RewardedPress(1);
    % end
    % if isExtinction
    %     badpress = sort([badpress; goodpress]);
    %     goodpress = NaN;
    % end
    % tPressState = [tPressState; sort([badpress(:); goodpress(:)])+tTrialStart]; % used to compare with press from Events
    
    % bad/good press from events
    goodpress = NaN;
    if any(~isnan(States.RewardedPress))
        goodpress = States.RewardedPress(1);
    end
    if isExtinction
        goodpress = NaN;
    end
    badpress = press(~ismember(round(press,nMinRound),round(goodpress,nMinRound)));

    tEventTrial.GoodPress(i) = goodpress-tZero;
    tEventTrial.BadPress{i} = badpress-tZero;
    
    % pokeIn&Out
    if ~isExtinction && any(~isnan(States.RewardDelivery))
        tReward = States.RewardDelivery(1);
        retrievalLatency = tReward-goodpress;
        goodpokein = pokein(round(pokein,nMinRound)>=round(tReward,nMinRound));
        goodpokeout = pokeout(round(pokeout,nMinRound)>=round(tReward,nMinRound));
        badpokein = setdiff(pokein,goodpokein);
        badpokeout = setdiff(pokeout,goodpokeout);
        tGoodPokeFirst = [tGoodPokeFirst; goodpokein(1)+tTrialStart];
    else
        tReward = NaN;
        retrievalLatency = NaN;
        badpokein = pokein;
        badpokeout = pokeout;
        goodpokein = [];
        goodpokeout = [];
    end
    
    tEventTrial.RetrievalLatency(i) = retrievalLatency;
    tEventTrial.BadPokeIn{i} = badpokein-tZero;
    tEventTrial.BadPokeOut{i} = badpokeout-tZero;
    tEventTrial.GoodPokeIn{i} = goodpokein-tZero;
    tEventTrial.GoodPokeOut{i} = goodpokeout-tZero;
end
% preserve the events during SessionDuration
fields = fieldnames(tEvent);
fields = setdiff(fields,'SessionStartTime');
for i=1:length(fields)
    field = fields{i};
    % exclude the events happened before session start (the pause period)
    tEvent.(field) = tEvent.(field)(tEvent.(field)>t0+0.1);
    % exclude the events happened after session duration
    tEvent.(field) = tEvent.(field)(tEvent.(field)<=t0+SessionDuration);
end

% debug
% tPressState = tPressState(tPressState<=t0+SessionDuration);
% isPressSame = isequal(round(tEvent.Press,nMinRound),round(tPressState,nMinRound));
% if ~isPressSame
%     tEvent.Press(~ismember(tEvent.Press,tPressState))
%     error('The presses from States & Events are not same. Please debug!');
% end

% align poke-in & poke-out
[PokeInAlign, PokeOutAlign, idxIn, idxOut] = matchEventsKeepAllIn(tEvent.PokeIn, tEvent.PokeOut);
idxMissing = find(isnan(PokeOutAlign));
if ~isempty(idxMissing)
    for i=1:length(idxMissing)
        PokeOutAlign(idxMissing(i)) = PokeInAlign(idxMissing(i))+minStep; % if poke-out is missing, use poke-in to fill
    end
end
tEvent.PokeIn = PokeInAlign;
tEvent.PokeOut = PokeOutAlign;

% add release data from med
if ~isempty(medfile)
    [~, bc] = Behavior.MED.track_training_progress_press(medfile);
    Ind = findseqmatchWXN(bc.PressTime, tEvent.Press, 1, 'PressTime_Align_MED_BPOD');

    tPressMED = bc.PressTime(Ind);
    tReleaseMED = bc.ReleaseTime(Ind);
    PressDur = tReleaseMED-tPressMED;
    
    tRelease = tEvent.Press(:)+PressDur(:);
    tEvent.Release = tRelease;
else
    error('MED file not found. Release data needed.');
end

% classify tEvent.Press
tGoodPress = tEventTrial.VI_EndTime+tEventTrial.GoodPress;
tGoodPress = tGoodPress(~isnan(tGoodPress));
idxGoodPress = find(ismember(round(tEvent.Press,nMinRound),round(tGoodPress,nMinRound)));
idxBadPress = find(~ismember(round(tEvent.Press,nMinRound),round(tGoodPress,nMinRound)));

% %classify tEvent.Poke & the release followed by a poke
idxReleaseGoodPoke = [];
idxReleaseBadPoke = [];
% GoodPoke (First, middle, Last)
idxGoodPokeFirst = find(ismember(round(tEvent.PokeIn,nMinRound),round(tGoodPokeFirst,nMinRound)));
idxGoodPoke = []; % the consecutive pokes from every first poke after rewarded press
idxGoodPokeLast = []; % The last poke of each good pokes sequences
for i=1:length(idxGoodPokeFirst)
    tGoodPokeFirstThis = tEvent.PokeIn(idxGoodPokeFirst(i));
    tNextPress = tEvent.Press(find(tEvent.Press>tGoodPokeFirstThis,1));
    if ~isempty(tNextPress)
        idxGoodPokeThis = find(tEvent.PokeIn>=tGoodPokeFirstThis & tEvent.PokeOut<tNextPress);
    else
        idxGoodPokeThis = find(tEvent.PokeIn>=tGoodPokeFirstThis);
    end
    idxGoodPokeLast = [idxGoodPokeLast; idxGoodPokeThis(end)];
    idxGoodPoke = [idxGoodPoke; idxGoodPokeThis];
    
    if ~isempty(tEvent.Release)
        idxReleaseLast = find(tEvent.Release<tGoodPokeFirstThis,1,'last');
    else
        idxReleaseLast = find(tEvent.Press<tGoodPokeFirstThis,1,'last');
    end
    idxReleaseGoodPoke = [idxReleaseGoodPoke; idxReleaseLast];
end
% BadPoke (First, middle, last)
idxBadPoke = setdiff((1:length(tEvent.PokeIn))',idxGoodPoke);
idxBadPokeFirst = []; % the first poke after a bad leverpress (if exist)
idxBadPokeLast = []; % the last poke after a bad leverpress & before next leverpress (if exist)
for i=1:length(idxBadPress)
    tThisBadPress = tEvent.Press(idxBadPress(i));
    tNextPress = tEvent.Press(find(tEvent.Press>tThisBadPress,1));
    if ~isempty(tNextPress)
        idxBadPokeThis = find(tEvent.PokeIn>tThisBadPress & tEvent.PokeOut<tNextPress);
    else
        idxBadPokeThis = find(tEvent.PokeIn>tThisBadPress);
    end
    % tThisBadPress could be the press between rewarded press & rewarded poke
    % so idxBadPokeThis could be the idxGoodPoke, exclude them
    idxBadPokeThis = setdiff(idxBadPokeThis,idxGoodPoke);

    if ~isempty(idxBadPokeThis)
        % In theory, idxBadPokeThis belongs to idxBadPoke
        isAllBadPoke = all(ismember(idxBadPokeThis,idxBadPoke));
        if isAllBadPoke
            idxBadPokeFirst = [idxBadPokeFirst; idxBadPokeThis(1)];
            idxBadPokeLast = [idxBadPokeLast; idxBadPokeThis(end)];
            % the release before this first bad poke
            idxReleaseBadPoke = [idxReleaseBadPoke; idxBadPress(i)];
        else
            error('Non-BadPoke happened after a BadLeverPress. Please check data!');
        end
    end
end

tEventIndex.Press.Bad = idxBadPress(:);
tEventIndex.Press.Good = idxGoodPress(:);
tEventIndex.Release.GoGoodPoke = idxReleaseGoodPoke;
tEventIndex.Release.GoBadPoke = idxReleaseBadPoke;
tEventIndex.Release.Others = setdiff(1:length(tEvent.Release),[idxReleaseGoodPoke; idxReleaseBadPoke]);
tEventIndex.Poke.Bad = idxBadPoke;
tEventIndex.Poke.BadFirst = idxBadPokeFirst;
tEventIndex.Poke.BadLast = idxBadPokeLast;
tEventIndex.Poke.Good = idxGoodPoke;
tEventIndex.Poke.GoodFirst = idxGoodPokeFirst;
tEventIndex.Poke.GoodLast = idxGoodPokeLast;

% raw trial info
vb.tEvent = tEvent;
vb.idxEvent = tEventIndex;
vb.tEventTrial = tEventTrial;

% construct responses table
idxBadPokeOthers = setdiff(vb.idxEvent.Poke.Bad, vb.idxEvent.Poke.BadFirst);
idxGoodPokeOthers = setdiff(vb.idxEvent.Poke.Good, vb.idxEvent.Poke.GoodFirst);

% Responses - important events 
% Good/Bad x Press/Poke(In)
% The releases followed by Good/Bad PokeIn (to calculate movement time)
% The Good/Bad PokeOut followed by Press (to calculate restart time)

% Recommend using contains(Responses.Type, "Press") to extract events
% "Press" & "Poke" can find all press & poke-in events
% "Release" can find all release followed by poke-in
% "PokeFirst" can find the first poke-in of each poke sequence
% "PortOut" can find all poke-out before a press
EventLabels = [repmat("GoodPress",      size(vb.idxEvent.Press.Good(:)));
               repmat("ReleaseGoGood",  size(vb.idxEvent.Release.GoGoodPoke(:)));
               repmat("GoodPokeFirst",  size(vb.idxEvent.Poke.GoodFirst(:)));
               repmat("GoodPoke",       size(idxGoodPokeOthers(:)));
               repmat("GoodPortExit",   size(vb.idxEvent.Poke.GoodLast(:)));
               repmat("BadPress",       size(vb.idxEvent.Press.Bad(:)));
               repmat("ReleaseGoBad",   size(vb.idxEvent.Release.GoBadPoke(:)));
               repmat("BadPokeFirst",   size(vb.idxEvent.Poke.BadFirst(:)));
               repmat("BadPoke",        size(idxBadPokeOthers(:)));
               repmat("BadPortExit",    size(vb.idxEvent.Poke.BadLast(:)));
               ];
EventTime = [vb.tEvent.Press(vb.idxEvent.Press.Good);
             vb.tEvent.Release(vb.idxEvent.Release.GoGoodPoke);
             vb.tEvent.PokeIn(vb.idxEvent.Poke.GoodFirst);
             vb.tEvent.PokeIn(idxGoodPokeOthers);
             vb.tEvent.PokeOut(vb.idxEvent.Poke.GoodLast);
             vb.tEvent.Press(vb.idxEvent.Press.Bad);
             vb.tEvent.Release(vb.idxEvent.Release.GoBadPoke);
             vb.tEvent.PokeIn(vb.idxEvent.Poke.BadFirst);
             vb.tEvent.PokeIn(idxBadPokeOthers);
             vb.tEvent.PokeOut(vb.idxEvent.Poke.BadLast);
             ];
[EventTime, idxSortEvent] = sort(EventTime,'ascend');
EventLabels = EventLabels(idxSortEvent);
Responses = table(EventLabels,EventTime-t0,'VariableNames',{'Type','Time'});

% ResponsesAll - Good/Bad x (Press/Release | PokeIn/PokeOut)
EventLabels2 = [repmat("GoodPress",         size(vb.idxEvent.Press.Good(:)));
                repmat("GoodRelease",       size(vb.idxEvent.Press.Good(:)));
                repmat("BadPress",          size(vb.idxEvent.Press.Bad(:)));
                repmat("BadRelease",        size(vb.idxEvent.Press.Bad(:)));
                repmat("GoodPokeIn",        size(vb.idxEvent.Poke.Good(:)));
                repmat("GoodPokeOut",       size(vb.idxEvent.Poke.Good(:)));
                repmat("BadPokeIn",         size(vb.idxEvent.Poke.Bad(:)));
                repmat("BadPokePoke",       size(vb.idxEvent.Poke.Bad(:)));
                ];
EventTime2 = [vb.tEvent.Press(vb.idxEvent.Press.Good);
              vb.tEvent.Release(vb.idxEvent.Press.Good);
              vb.tEvent.Press(vb.idxEvent.Press.Bad);
              vb.tEvent.Release(vb.idxEvent.Press.Bad);
              vb.tEvent.PokeIn(vb.idxEvent.Poke.Good);
              vb.tEvent.PokeOut(vb.idxEvent.Poke.Good);
              vb.tEvent.PokeIn(vb.idxEvent.Poke.Bad);
              vb.tEvent.PokeOut(vb.idxEvent.Poke.Bad);
              ];
[EventTime2, idxSortEvent2] = sort(EventTime2,'ascend');
EventLabels2 = EventLabels2(idxSortEvent2);
ResponsesAll = table(EventLabels2,EventTime2-t0,'VariableNames',{'Type','Time'});

vb.Responses = Responses;
vb.ResponsesAll = ResponsesAll;
nResponses = size(Responses,1);
%% session estimates & detail info
vb.nTrial = nTrial;
vb.SessionDuration = SessionDuration;

% VI real (last reward - this VI_EndTime)
if isExtinction
    VIreal = nan(1,nTrial); % in extinction test, no VI/reward
else
    VIreal = Custom.VI(1:nTrial);
    for j=1:nTrial
        if j>1 % pass trial 1, use the preset VI
            tThisVI_End = vb.tEventTrial.VI_EndTime(j);
            tLastVI_End = vb.tEventTrial.VI_EndTime(j-1);
            tLastGoodPoke = vb.tEventTrial.GoodPokeIn{j-1};
            if ~isempty(tLastGoodPoke)
                tLastGoodPokeFirst = tLastGoodPoke(1);
                vi = tThisVI_End - (tLastVI_End + tLastGoodPokeFirst);
            else
                % GoodPoke could be tempty in some exceptional cases (early protocol), the reward was skipped (cause time out)
                % use the rewarded press as VI start
                tLastGoodPress = vb.tEventTrial.GoodPress(j-1);
                vi = tThisVI_End - (tLastVI_End + tLastGoodPress);
            end
            VIreal(j) = vi;
        end
    end
end

% vi info
vb.VI_Preset_Mean = SessionData.TrialSettings(1).GUI.VI_Mean;
vb.VI_Preset = Custom.VI;
vb.VI = VIreal; % vb.VI_Real_Mean = mean(VIreal(1:nTrial));

% basic trial time structure
vb.tVI_End = vb.tEventTrial.VI_EndTime(1:nTrial)-t0;
vb.RewardedPressDelay = vb.tEventTrial.GoodPress(1:nTrial); % VI_End - next press
vb.RetrievalLatency = vb.tEventTrial.RetrievalLatency(1:nTrial); % port-light on (rewarded-press) to poke-in

% %press info
% for each press, there's a parameter that if the next event is still press
% two conditions: 
% 1. "xxxPress" - "xxxPress"; 
% 2. "xxxPress" - "ReleaseGoxxx" - "xxxPokeFirst"
idxPress = find(contains(vb.Responses.Type,'Press'));
tPress = vb.Responses.Time(idxPress);
nPress = length(idxPress);
IRI = [tPress(1); diff(tPress)];

if idxPress(end)==size(vb.Responses,1)
    idxPressNext = idxPress(1:end-1)+1;
    addEnd = false;
else
    idxPressNext = idxPress+1;
    addEnd = [];
end
isNextPress = [contains(vb.Responses.Type(idxPressNext),'Press'); addEnd];

% for each press, there's a parameter that 
% it's the ?th press after last poke or reward (good poke)
% and the last poke (bout) is good/bad
idxPortExit = find(contains(vb.Responses.Type,'PortExit'));
iPressAfterPoke = nan(size(idxPress));
isAfterGood = false(size(idxPress));
IRI_Adjusted = IRI;
for i = 1:nPress
    % 检查当前 Press 是否是自上一个 Poke 后的第一个
    % 如果是第一个 Press，它的前一个 Press (i-1) 肯定导致了 Switch (isPressStay == 0)
    curIdxPress = idxPress(i);
    if i == 1 % first press
        count = 1;
        isGood = false;
    elseif isNextPress(i-1) == false % first press after poke
        count = 1;
        
        idxLastExit = idxPortExit(find(idxPortExit<curIdxPress,1,'last'));
        lastExit = vb.Responses.Type(idxLastExit); % 'GoodPortExit' or 'BadPortExit'

        isGood = contains(lastExit, 'Good');
        % replace the IRI of first press after poke with restart latency
        newIRI = vb.Responses.Time(curIdxPress) - vb.Responses.Time(idxLastExit);
        IRI_Adjusted(i) = newIRI; 
    else % the press after a press
        % 连击序列中，继承当前的 count 和 isGood 状态
        count = count + 1;
    end
    iPressAfterPoke(i) = count;
    isAfterGood(i) = isGood;
end

% login
vb.nPress = nPress;
vb.PressRate = vb.nPress/vb.SessionDuration*60; % press num/min
vb.tPress = tPress;
vb.IRI = IRI; % inter-press interval
vb.isPressStay = isNextPress;
vb.nPressAfterPoke = iPressAfterPoke;
vb.isPressAfterGood = isAfterGood;
vb.IRI_Adjusted = IRI_Adjusted; % restart latency & the IRI in the press bout
vb.PressRate_Active = 60./mean(IRI_Adjusted,'omitnan');
vb.tPressBoutStart = vb.tPress(vb.nPressAfterPoke==1);
vb.PressBoutLength = vb.nPressAfterPoke(vb.isPressStay==false);
vb.PressBoutRate = length(vb.tPressBoutStart)./vb.SessionDuration*60; % pressStart num/min
vb.nPressAfterReward = []; % the xth press after last reward (it's reward if reward&goodpoke are not the same)
vb.IntervalAfterReward = []; % how long past since last reward for each press

% press rate in early/late period
earlyDur = 10;
lateDur = 10;
vb.EarlyLateMin = [earlyDur, lateDur];
pressRateEarly = sum(tPress <= earlyDur*60)/earlyDur;
pressRateLate = sum(tPress >= vb.SessionDuration-lateDur*60)/lateDur;
vb.EarlyLatePressRate = [pressRateEarly pressRateLate];
vb.PersistenceIndex = pressRateLate/pressRateEarly;

% %poke info
tPokeFirst = vb.Responses.Time(contains(vb.Responses.Type,"PokeFirst"));
tGoodPokeFirst = vb.Responses.Time(contains(vb.Responses.Type,"GoodPokeFirst"));
tBadPokeFirst = vb.Responses.Time(contains(vb.Responses.Type,"BadPokeFirst"));
vb.nPokeFirst = length(tPokeFirst);
vb.BadPokeFirstRatio = length(tBadPokeFirst)./length(tPokeFirst);
vb.InterRewardInterval = diff(tGoodPokeFirst);

% %estimate grouped by poke type
vb.PokeType.Label = {'Bad','Good'};
vb.PokeType.Bad.nPokeFirst = length(tBadPokeFirst);
vb.PokeType.Good.nPokeFirst = length(tGoodPokeFirst);
vb.PokeType.Bad.tPokeFirst = tBadPokeFirst;
vb.PokeType.Good.tPokeFirst = tGoodPokeFirst;

% release to poke interval (real movement time)
idxReleaseGoGood = find(contains(vb.Responses.Type, "ReleaseGoGood"));
idxReleaseGoGood = idxReleaseGoGood(idxReleaseGoGood+1<=nResponses);
nextEvents = vb.Responses.Type(idxReleaseGoGood+1);
isNextValid = contains(nextEvents,'GoodPokeFirst'); % In theory they are all true.
idxReleaseGoGood = idxReleaseGoGood(isNextValid);
mt_good = vb.Responses.Time(idxReleaseGoGood+1) - vb.Responses.Time(idxReleaseGoGood);

idxReleaseGoBad = find(contains(vb.Responses.Type, "ReleaseGoBad"));
idxReleaseGoBad = idxReleaseGoBad(idxReleaseGoBad+1<=nResponses);
nextEvents = vb.Responses.Type(idxReleaseGoBad+1);
isNextValid = contains(nextEvents,'BadPokeFirst'); % In theory they are all true.
idxReleaseGoBad = idxReleaseGoBad(isNextValid);
mt_bad = vb.Responses.Time(idxReleaseGoBad+1) - vb.Responses.Time(idxReleaseGoBad);

vb.PokeType.Bad.MovementTime = mt_bad;
vb.PokeType.Good.MovementTime = mt_good;

% poke-out - re-press interval
idxGoodPortExit = find(contains(vb.Responses.Type,"GoodPortExit"));
idxGoodPortExit = idxGoodPortExit(idxGoodPortExit+1<=nResponses);
nextEvents = vb.Responses.Type(idxGoodPortExit+1);
isNextValid = contains(nextEvents,'Press'); % In theory they are all true.
idxGoodPortExit = idxGoodPortExit(isNextValid);
repress_interval_good = vb.Responses.Time(idxGoodPortExit+1) - vb.Responses.Time(idxGoodPortExit);

idxBadPortExit = find(contains(vb.Responses.Type,"BadPortExit"));
idxBadPortExit = idxBadPortExit(idxBadPortExit+1<=nResponses);
nextEvents = vb.Responses.Type(idxBadPortExit+1);
isNextValid = contains(nextEvents,'Press'); % In theory they are all true.
idxBadPortExit = idxBadPortExit(isNextValid);
repress_interval_bad = vb.Responses.Time(idxBadPortExit+1) - vb.Responses.Time(idxBadPortExit);

vb.PokeType.Bad.RestartLatency = repress_interval_bad;
vb.PokeType.Good.RestartLatency = repress_interval_good;

% mean performance estimator
vb.MeanPerf.VI_Preset = mean(vb.VI_Preset,'omitnan');
vb.MeanPerf.VI = mean(vb.VI,'omitnan');
vb.MeanPerf.RewardedPressDelay = mean(rmoutliers_custom(vb.RewardedPressDelay));
vb.MeanPerf.RetrievalLatency = mean(rmoutliers_custom(vb.RetrievalLatency(~isnan(vb.RetrievalLatency))));
vb.MeanPerf.MovementTime = mean(rmoutliers_custom([vb.PokeType.Bad.MovementTime;vb.PokeType.Good.MovementTime]));
vb.MeanPerf.IRI = mean(rmoutliers_custom(vb.IRI));
vb.MeanPerf.IRI_Adjusted = mean(rmoutliers_custom(vb.IRI_Adjusted));
vb.MeanPerf.pStayN1 = mean(vb.isPressStay(vb.nPressAfterPoke==1));
vb.MeanPerf.PressBoutLength = mean(rmoutliers_custom(vb.PressBoutLength));
vb.MeanPerf.InterRewardInterval = mean(rmoutliers_custom(vb.InterRewardInterval));
vb.MeanPerf.InterBadPokeInterval = mean(rmoutliers_custom(diff(vb.PokeType.Bad.tPokeFirst)));
%% Save Data
savename = ['vb_',vb.Subject,'_',vb.Session,'.mat'];
savename = fullfile(pathSave, savename);
save(savename,'vb','-mat');

%% Plot
if ifPlot
    Behavior.LeverPressVI.plotSessionLeverPressVI(vb,"SavePath",pathSave);
end

end

%% Function

function [s1_m, s2_m, idx1, idx2] = matchEventsKeepAllIn(s1, s2, max_duration)
    % s1_m: 结果等同于原始 s1 (去除了重复和乱序)
    % s2_m: 匹配到的 poke-out，找不到则为 NaN
    % idx1: 原始 s1 的索引
    % idx2: 原始 s2 的索引 (如果匹配到的话)，未匹配则为 NaN
    
    if nargin < 3, max_duration = Inf; end
    
    % 预处理：排序并记录原始索引
    [s1_sorted, sortIdx1] = sort(s1(:));
    [s2_sorted, sortIdx2] = sort(s2(:));
    
    L1 = length(s1_sorted);
    L2 = length(s2_sorted);
    
    % 初始化输出：长度与 s1 一致
    s1_m = s1_sorted;
    s2_m = nan(L1, 1);
    idx1 = sortIdx1;
    idx2 = nan(L1, 1);
    
    p2 = 1; % s2 的指针
    
    for i = 1:L1
        current_in = s1_sorted(i);
        
        % 1. 移动 p2 指针，跳过所有早于当前 in 的 out
        while p2 <= L2 && s2_sorted(p2) <= current_in
            p2 = p2 + 1;
        end
        
        % 2. 检查当前的 s2 是否属于当前的 in
        % 逻辑：s2 必须在当前 in 之后，且如果存在下一个 in，s2 必须在下一个 in 之前
        if p2 <= L2
            potential_out = s2_sorted(p2);
            duration = potential_out - current_in;
            
            % 判断该 s2 是否属于当前 in 的条件：
            % A. 时长在范围内
            % B. (重要) 如果有下一个 in，当前的 out 必须比下一个 in 更近或者在下一个 in 之前
            is_valid = (duration <= max_duration);
            
            if i < L1
                % 如果下一个 in 比当前的 out 还早，说明当前的 in 丢失了 out
                if s1_sorted(i+1) < potential_out
                    is_valid = false;
                end
            end
            
            if is_valid
                s2_m(i) = potential_out;
                idx2(i) = sortIdx2(p2);
                p2 = p2 + 1; % 匹配成功，s2 指针才后移
            end
        end
        % 如果不满足 is_valid，s2_m(i) 保持为 NaN
    end
end