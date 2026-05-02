function vb = track_training(bpodfile, medfile, ifPlot, opts)
%track_training Behavior.LeverPressVI.track_training(bpodfile, medfile, ifPlot, opts)
% Input:
%   bpodfile
%   medfile
%   ifPlot
%   opts.SavePath = ''
% Most Important Output：vb.EventTable
% EventTable is a press-level long-format table.
% Each row corresponds to one lever press in the session.
%
% Row identifiers:
%   anm_session            - subject/session identifier
%   press_index            - ordinal index of the press within the session
%
% Press history variables:
%   press_rank             - rank of this press within the current press bout;
%                            reset to 1 after a poke/port-exit sequence
%   time_from_last_reward  - time elapsed since the last rewarded good poke
%
% Press timing variables:
%   t_press                - press onset time relative to session start
%   t_release              - lever release time relative to session start
%
% Press outcome variables:
%   outcome                - press type: "Good" or "Bad"
%                            Good = first press after VI offset;
%                            Bad = non-rewarded press
%   is_stay                - whether the next key event after this press is
%                            another press rather than a poke sequence
%
% Poke timing variables:
%   t_poke_first           - first poke-in time following this press, if any
%   t_port_exit            - last poke-out time of the following poke bout, if any
%   t_pokein_all           - all poke-in times in the poke bout following this press
%   t_pokeout_all          - all poke-out times in the poke bout following this press
%
% Poke / reward outcome variables:
%   reward                 - outcome of the poke sequence following this press:
%                            "Rewarded" = good poke with water delivery;
%                            "Omitted"  = good poke without water delivery;
%                            "Bad"      = bad poke;
%                            "NaN"      = no poke sequence before the next press
%                                         or before session end
%   valve_time             - valve-open duration for rewarded/omitted good pokes
%
% In brief, EventTable describes, for each press:
%   1) whether the press was good or bad;
%   2) whether the animal stayed pressing or switched to poking;
%   3) if it poked, whether the poke sequence was rewarded, omitted, or bad;
%   4) the timing of the press, release, poke onset, and port exit.

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
session = char(extract(bpodfile, digitsPattern(8)+"_"+digitsPattern(6)));
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
vb.isExtinction = isExtinction; % no port light
vb.isDevaluation = false;

if isfield(Custom,'isRewardOmission') % the program add the settings about omission
    isOmitted = Custom.isRewardOmission(1:nTrial);
elseif isExtinction % if it's extinction (without port light) program, no reward was given
    isOmitted = false(1,nTrial);
else % there could be some omitted trials in extinction with port light
    isOmitted = [];
    for i=1:nTrial
        amount = SessionData.TrialSettings(i).GUI.RewardAmount;
        isOmitted = [isOmitted; amount<0.01]; % if valve time is less than 0.01 s, it's a omiited trial (session)
    end
end
vb.OmitRatio = mean(isOmitted);

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
tEventTrial.isGoodOmitted = isOmitted';
tEventTrial.ValveTime = [];

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
        press = [];
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
    % badpress = press(~ismember(round(press,nMinRound),round(goodpress,nMinRound)));
    badpress = press(~(abs(press-goodpress)<minStep));

    tEventTrial.GoodPress(i) = goodpress-tZero;
    tEventTrial.BadPress{i} = badpress-tZero;
    
    % pokeIn&Out
    if ~isExtinction && any(~isnan(States.RewardDelivery))
        tReward = States.RewardDelivery(1);
        vtime = diff(States.RewardDelivery);
        retrievalLatency = tReward-goodpress;
        % goodpokein = pokein(round(pokein,nMinRound)>=round(tReward,nMinRound));
        idxGoodIn = find(abs(pokein-tReward)<minStep);
        if ~isempty(idxGoodIn)
            goodpokein = pokein(idxGoodIn:end);
        else
            goodpokein = [];
        end
        % goodpokeout = pokeout(round(pokeout,nMinRound)>=round(tReward,nMinRound));
        idxGoodOut = find(abs(pokeout-tReward)<minStep);
        if ~isempty(idxGoodOut)
            goodpokeout = pokeout(idxGoodOut:end);
        else
            goodpokeout = [];
        end
        badpokein = setdiff(pokein,goodpokein);
        badpokeout = setdiff(pokeout,goodpokeout);
        if ~isempty(goodpokein)
            tGoodPokeFirst = [tGoodPokeFirst; goodpokein(1)+tTrialStart];
        end
    else
        tReward = NaN;
        vtime = NaN;
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
    tEventTrial.ValveTime(i) = vtime;
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
[PokeInAlign, PokeOutAlign, idxIn, idxOut] = matchSeqOnsetOffset(tEvent.PokeIn, tEvent.PokeOut);
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
% idxGoodPress = find(ismember(round(tEvent.Press,nMinRound),round(tGoodPress,nMinRound)));
% idxBadPress = find(~ismember(round(tEvent.Press,nMinRound),round(tGoodPress,nMinRound)));
idxGoodPress = find(any(abs(tEvent.Press-tGoodPress(:)')<minStep, 2));
idxBadPress = find(~any(abs(tEvent.Press-tGoodPress(:)')<minStep, 2));

% %classify tEvent.Poke & the release followed by a poke
idxReleaseGoodPoke = [];
idxReleaseBadPoke = [];

% idxGoodPokeFirst = find(ismember(round(tEvent.PokeIn,nMinRound),round(tGoodPokeFirst,nMinRound)));
idxGoodPokeFirst = find(any(abs(tEvent.PokeIn-tGoodPokeFirst(:)')<minStep, 2));
idxGoodPoke = [];
idxGoodPokeLast = [];
% Rewarded Poke (First, middle, Last)
idxRewardedPokeFirst = [];
idxRewardedPoke = []; % the consecutive pokes from every first poke after rewarded press
idxRewardedPokeLast = []; % The last poke of each good pokes sequences
% OmittedPoke (First, middle, Last)
idxOmittedPokeFirst = [];
idxOmittedPoke = [];
idxOmittedPokeLast = [];
for i=1:length(idxGoodPokeFirst)
    isThisOmitted = isOmitted(i);
    tGoodPokeFirstThis = tEvent.PokeIn(idxGoodPokeFirst(i));
    tNextPress = tEvent.Press(find(tEvent.Press>tGoodPokeFirstThis,1));
    if ~isempty(tNextPress)
        idxGoodPokeThis = find(tEvent.PokeIn>=tGoodPokeFirstThis & tEvent.PokeOut<tNextPress);
    else
        idxGoodPokeThis = find(tEvent.PokeIn>=tGoodPokeFirstThis);
    end
    idxGoodPokeLast = [idxGoodPokeLast; idxGoodPokeThis(end)];
    idxGoodPoke = [idxGoodPoke; idxGoodPokeThis];
    if ~isThisOmitted
        idxRewardedPokeFirst = [idxRewardedPokeFirst; idxGoodPokeThis(1)];
        idxRewardedPokeLast = [idxRewardedPokeLast; idxGoodPokeThis(end)];
        idxRewardedPoke = [idxRewardedPoke; idxGoodPokeThis];
    else
        idxOmittedPokeFirst = [idxOmittedPokeFirst; idxGoodPokeThis(1)];
        idxOmittedPokeLast = [idxOmittedPokeLast; idxGoodPokeThis(end)];
        idxOmittedPoke = [idxOmittedPoke; idxGoodPokeThis];
    end
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
    idxBadPokeThis = setdiff(idxBadPokeThis, idxGoodPoke);
    % idxBadPokeThis = intersect(idxBadPokeThis, idxBadPoke);

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
tEventIndex.Poke.Reward = idxRewardedPoke; % obtain the reward
tEventIndex.Poke.RewardFirst = idxRewardedPokeFirst;
tEventIndex.Poke.RewardLast = idxRewardedPokeLast;
tEventIndex.Poke.Omit = idxOmittedPoke;
tEventIndex.Poke.OmitFirst = idxOmittedPokeFirst;
tEventIndex.Poke.OmitLast = idxOmittedPokeLast;

% raw trial info
vb.tEvent = tEvent;
vb.idxEvent = tEventIndex;
vb.tEventTrial = tEventTrial;

% construct responses table
idxBadPokeOthers = setdiff(vb.idxEvent.Poke.Bad, vb.idxEvent.Poke.BadFirst);
idxRewardPokeOthers = setdiff(vb.idxEvent.Poke.Reward, vb.idxEvent.Poke.RewardFirst);
idxOmitPokeOthers = setdiff(vb.idxEvent.Poke.Omit, vb.idxEvent.Poke.OmitFirst);

% Responses - important events 
% Good/Bad x Press/Poke(In)
% The releases followed by Good/Bad PokeIn (to calculate movement time)
% The Good/Bad PokeOut followed by Press (to calculate restart time)

% Recommend using contains(Responses.Type, "Press") to extract events
% "Press" & "Poke" can find all press & poke-in events
% "Release" can find all release followed by poke-in
% "PokeFirst" can find the first poke-in of each poke sequence
% "PortOut" can find all poke-out before a press
EventLabels = [repmat("GoodPress",          size(vb.idxEvent.Press.Good(:)));
               repmat("ReleaseGoGood",      size(vb.idxEvent.Release.GoGoodPoke(:)));
               repmat("RewardGoodPokeFirst",size(vb.idxEvent.Poke.RewardFirst(:)));
               % repmat("RewardGoodPoke",     size(idxRewardPokeOthers(:)));
               repmat("RewardGoodPortExit", size(vb.idxEvent.Poke.RewardLast(:)));
               repmat("OmitGoodPokeFirst",  size(vb.idxEvent.Poke.OmitFirst(:)));
               % repmat("OmitGoodPoke",       size(idxOmitPokeOthers(:)));
               repmat("OmitGoodPortExit",   size(vb.idxEvent.Poke.OmitLast(:)));
               repmat("BadPress",           size(vb.idxEvent.Press.Bad(:)));
               repmat("ReleaseGoBad",       size(vb.idxEvent.Release.GoBadPoke(:)));
               repmat("BadPokeFirst",       size(vb.idxEvent.Poke.BadFirst(:)));
               % repmat("BadPoke",            size(idxBadPokeOthers(:)));
               repmat("BadPortExit",        size(vb.idxEvent.Poke.BadLast(:)));
               ];
EventTime = [vb.tEvent.Press(vb.idxEvent.Press.Good);
             vb.tEvent.Release(vb.idxEvent.Release.GoGoodPoke);
             vb.tEvent.PokeIn(vb.idxEvent.Poke.RewardFirst);
             % vb.tEvent.PokeIn(idxRewardPokeOthers);
             vb.tEvent.PokeOut(vb.idxEvent.Poke.RewardLast);
             vb.tEvent.PokeIn(vb.idxEvent.Poke.OmitFirst);
             % vb.tEvent.PokeIn(idxOmitPokeOthers);
             vb.tEvent.PokeOut(vb.idxEvent.Poke.OmitLast);
             vb.tEvent.Press(vb.idxEvent.Press.Bad);
             vb.tEvent.Release(vb.idxEvent.Release.GoBadPoke);
             vb.tEvent.PokeIn(vb.idxEvent.Poke.BadFirst);
             % vb.tEvent.PokeIn(idxBadPokeOthers);
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
                repmat("RewardGoodPokeIn",  size(vb.idxEvent.Poke.Reward(:)));
                repmat("RewardGoodPokeOut", size(vb.idxEvent.Poke.Reward(:)));
                repmat("OmitGoodPokeIn",    size(vb.idxEvent.Poke.Omit(:)));
                repmat("OmitGoodPokeOut",   size(vb.idxEvent.Poke.Omit(:)));
                repmat("BadPokeIn",         size(vb.idxEvent.Poke.Bad(:)));
                repmat("BadPokeOut",       size(vb.idxEvent.Poke.Bad(:)));
                ];
EventTime2 = [vb.tEvent.Press(vb.idxEvent.Press.Good);
              vb.tEvent.Release(vb.idxEvent.Press.Good);
              vb.tEvent.Press(vb.idxEvent.Press.Bad);
              vb.tEvent.Release(vb.idxEvent.Press.Bad);
              vb.tEvent.PokeIn(vb.idxEvent.Poke.Reward);
              vb.tEvent.PokeOut(vb.idxEvent.Poke.Reward);
              vb.tEvent.PokeIn(vb.idxEvent.Poke.Omit);
              vb.tEvent.PokeOut(vb.idxEvent.Poke.Omit);
              vb.tEvent.PokeIn(vb.idxEvent.Poke.Bad);
              vb.tEvent.PokeOut(vb.idxEvent.Poke.Bad);
              ];
[EventTime2, idxSortEvent2] = sort(EventTime2,'ascend');
EventLabels2 = EventLabels2(idxSortEvent2);
ResponsesAll = table(EventLabels2,EventTime2-t0,'VariableNames',{'Type','Time'});

vb.Responses = Responses;
vb.ResponsesAll = ResponsesAll;
nResponses = size(Responses,1);

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
isNextPress = logical(isNextPress);

% % construct EventTable

% session & press/row info
anm_session = repmat({append(vb.Subject,'_',vb.Session)},size(tPress));
press_index = (1:nPress)';
% history info
press_rank = iPressAfterPoke;
time_from_last_reward = nan(size(idxPress)); % last_reward to this press
% time points of press/release
t_press = tPress; 
t_release = vb.ResponsesAll.Time(contains(vb.ResponsesAll.Type,'Release'));
% feedback/response of press
isGoodPress = contains(vb.Responses.Type(idxPress),'Good');
outcome = cellstr(categorical(isGoodPress, [true, false], ["Good", "Bad"])); % if there's port light after press
is_stay = isNextPress;
% time points of first poke-in/last poke-out (if existed)
t_poke_first = nan(size(idxPress));
t_port_exit = nan(size(idxPress));
t_pokein_all = cell(size(idxPress));
t_pokeout_all = cell(size(idxPress));
% feedback of poke
reward = cell(size(idxPress)); % No poke/bad poke/rewarded poke/omitted poke
valve_time = nan(size(idxPress));

iTrial = 1;
tLastReward = NaN;
for i=1:length(idxPress)
    idxThis = idxPress(i);
    tThisPress = vb.Responses.Time(idxThis);
    time_from_last_reward(i) = tThisPress-tLastReward;
    if is_stay(i) % next event is also press
        reward{i} = 'NaN';
        continue;
    else % next event is poke or session ends
        idxNext = find(vb.Responses.Time>tThisPress & contains(vb.Responses.Type,'Press'),1,'first');
        if ~isempty(idxNext)
            tNextPress = vb.Responses.Time(idxNext);
            idx_poke_first = find(contains(vb.Responses.Type,'PokeFirst') & vb.Responses.Time>tThisPress & vb.Responses.Time<tNextPress,1,'first');
            idx_port_exit = find(contains(vb.Responses.Type,'PortExit') & vb.Responses.Time>tThisPress & vb.Responses.Time<tNextPress,1,'last');
        else
            idx_poke_first = find(contains(vb.Responses.Type,'PokeFirst') & vb.Responses.Time>tThisPress,1,'first');
            idx_port_exit = find(contains(vb.Responses.Type,'PortExit') & vb.Responses.Time>tThisPress,1,'last');
        end
        if ~isempty(idx_poke_first)
            t_poke_first(i) = vb.Responses.Time(idx_poke_first);
            % clasify the poke
            type_poke = vb.Responses.Type(idx_poke_first);
            if contains(type_poke,'Reward') % rewarded (good) poke
                reward{i} = 'Rewarded';
                tLastReward = t_poke_first(i);
                valve_time(i) = tEventTrial.ValveTime(iTrial);
                iTrial = iTrial+1;
            elseif contains(type_poke,'Omit') % rewarded (good) poke % omitted (good) poke
                reward{i} = 'Omitted';
                valve_time(i) = tEventTrial.ValveTime(iTrial);
                iTrial = iTrial+1;
            elseif contains(type_poke,'Bad') % bad poke
                reward{i} = 'Bad';
            else
                error('Unexpected condition');
            end
        else % no poke after this press (because of the cutoff of the session)
            reward{i} = 'NaN';
        end
        if ~isempty(idx_port_exit)
            t_port_exit(i) = vb.Responses.Time(idx_port_exit);
        end
        if ~isempty(idx_poke_first) && ~isempty(idx_port_exit)
            t_poke_start = vb.Responses.Time(idx_poke_first);
            t_poke_end = vb.Responses.Time(idx_port_exit);
            idxPokeEvent = find(vb.ResponsesAll.Time >= t_poke_start & vb.ResponsesAll.Time <= t_poke_end);
            isPokeIn = contains(vb.ResponsesAll.Type(idxPokeEvent),'PokeIn');
            isPokeOut = contains(vb.ResponsesAll.Type(idxPokeEvent),'PokeOut');
            t_pokein_all{i} = vb.ResponsesAll.Time(idxPokeEvent(isPokeIn));
            t_pokeout_all{i} = vb.ResponsesAll.Time(idxPokeEvent(isPokeOut));
        elseif ~isempty(idx_poke_first)
            error('Unexpected conditions. Debug!');
        elseif ~isempty(idx_port_exit)
            error('Unexpected conditions. Debug!');
        end
    end
end
EventTable = table(anm_session, press_index, ...% row indentifier
    press_rank, time_from_last_reward, ...% history info of this press
    t_press, t_release, ...% press/release time
    outcome, is_stay, ...% feedback/response of press
    t_poke_first, t_port_exit, t_pokein_all, t_pokeout_all, ...% poke time
    reward, valve_time);
vb.EventTable = EventTable;

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
vb.isOmitted = isOmitted;

% press info
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
vb.PersistenceIndex = (pressRateLate-pressRateEarly)/(pressRateLate+pressRateEarly);

% %poke info
tPokeFirst = vb.Responses.Time(contains(vb.Responses.Type,"PokeFirst"));
tAllGoodPokeFirst = vb.Responses.Time(contains(vb.Responses.Type,"GoodPokeFirst"));
tRewardPokeFirst = vb.Responses.Time(contains(vb.Responses.Type,"RewardGoodPokeFirst"));
tOmitPokeFirst = vb.Responses.Time(contains(vb.Responses.Type,"OmitGoodPokeFirst"));
tBadPokeFirst = vb.Responses.Time(contains(vb.Responses.Type,"BadPokeFirst"));
vb.nPokeFirst = length(tPokeFirst);
vb.BadPokeFirstRatio = length(tBadPokeFirst)./length(tPokeFirst);
vb.InterRewardInterval = diff(tRewardPokeFirst);

% %estimate grouped by poke type
vb.PokeType.Label = {'Bad','Good','Reward','Omit'};
vb.PokeType.Bad.nPokeFirst = length(tBadPokeFirst);
vb.PokeType.Good.nPokeFirst = length(tAllGoodPokeFirst);
vb.PokeType.Reward.nPokeFirst = length(tRewardPokeFirst);
vb.PokeType.Omit.nPokeFirst = length(tOmitPokeFirst);
vb.PokeType.Bad.tPokeFirst = tBadPokeFirst;
vb.PokeType.Good.tPokeFirst = tAllGoodPokeFirst;
vb.PokeType.Reward.tPokeFirst = tRewardPokeFirst;
vb.PokeType.Omit.tPokeFirst = tOmitPokeFirst;

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

idxRewardPortExit = find(contains(vb.Responses.Type,"RewardGoodPortExit"));
idxRewardPortExit = idxRewardPortExit(idxRewardPortExit+1<=nResponses);
nextEvents = vb.Responses.Type(idxRewardPortExit+1);
isNextValid = contains(nextEvents,'Press'); % In theory they are all true.
idxRewardPortExit = idxRewardPortExit(isNextValid);
repress_interval_reward = vb.Responses.Time(idxRewardPortExit+1) - vb.Responses.Time(idxRewardPortExit);

idxOmitPortExit = find(contains(vb.Responses.Type,"OmitGoodPortExit"));
idxOmitPortExit = idxOmitPortExit(idxOmitPortExit+1<=nResponses);
nextEvents = vb.Responses.Type(idxOmitPortExit+1);
isNextValid = contains(nextEvents,'Press'); % In theory they are all true.
idxOmitPortExit = idxOmitPortExit(isNextValid);
repress_interval_omit = vb.Responses.Time(idxOmitPortExit+1) - vb.Responses.Time(idxOmitPortExit);

idxBadPortExit = find(contains(vb.Responses.Type,"BadPortExit"));
idxBadPortExit = idxBadPortExit(idxBadPortExit+1<=nResponses);
nextEvents = vb.Responses.Type(idxBadPortExit+1);
isNextValid = contains(nextEvents,'Press'); % In theory they are all true.
idxBadPortExit = idxBadPortExit(isNextValid);
repress_interval_bad = vb.Responses.Time(idxBadPortExit+1) - vb.Responses.Time(idxBadPortExit);

vb.PokeType.Bad.RestartLatency = repress_interval_bad;
vb.PokeType.Good.RestartLatency = repress_interval_good;
vb.PokeType.Reward.RestartLatency = repress_interval_reward;
vb.PokeType.Omit.RestartLatency = repress_interval_omit;

% mean performance estimator
vb.MeanPerf.VI_Preset = mean(vb.VI_Preset,'omitnan');
vb.MeanPerf.VI = mean(vb.VI,'omitnan');
vb.MeanPerf.RewardedPressDelay = mean(rmoutliers_custom(vb.RewardedPressDelay));
vb.MeanPerf.RetrievalLatency = mean(rmoutliers_custom(vb.RetrievalLatency(~isnan(vb.RetrievalLatency))));
vb.MeanPerf.MovementTime = mean(rmoutliers_custom([vb.PokeType.Bad.MovementTime;vb.PokeType.Good.MovementTime]));
vb.MeanPerf.IRI = mean(rmoutliers_custom(vb.IRI));
vb.MeanPerf.IRI_Adjusted = mean(rmoutliers_custom(vb.IRI_Adjusted));
vb.MeanPerf.pBadStayN1 = mean(vb.EventTable.is_stay( ...
    vb.EventTable.press_rank==1 ...
    & strcmp(vb.EventTable.outcome,'Bad') ...
    & contains(vb.EventTable.reward,{'NaN','Bad'})));
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
