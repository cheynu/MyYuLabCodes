function EventOut = AlignBehaviorClassToBR_CY(EventOut, myclass, BpodEvents)

% 3/3/2021 Jianing Yu
% EventOut comes from BlackRock's digital input
% bMED is the b array coming from MED data
% Time of some critical behavioral events (e.g., Trigger stimulus) needs to be mapped to EventOut
% Alignment is performed using press onset data
% Alignment of each trigger stimulus needs to be adjusted to the preceding press
% onset

% 4/2/2023 revised from AlignMED2BR but use behavior class instead 
% the goal of this function is to find the behavioral meaning of each blackrock's press 
% Lever presses and releases recorded in blackrock

% these are times for lever press and release recorded in blackrock

arguments
    EventOut
    myclass
    BpodEvents = []
end

PressEphys        =     EventOut.Onset{strcmp(EventOut.EventsLabels, 'LeverPress')};
ReleaseEphys     =     EventOut.Offset{strcmp(EventOut.EventsLabels, 'LeverPress')};

if length(ReleaseEphys)<length(PressEphys)
    [PressEphysMatched, ReleaseEphysMatched] = matchSeqOnsetOffset(PressEphys, ReleaseEphys);
    ind_valid = ~isnan(PressEphysMatched) & ~isnan(ReleaseEphysMatched);
    PressEphys = PressEphysMatched(ind_valid);
    ReleaseEphys = ReleaseEphysMatched(ind_valid);
    EventOut.Onset{strcmp(EventOut.EventsLabels, 'LeverPress')} = PressEphys;
    EventOut.Offset{strcmp(EventOut.EventsLabels, 'LeverPress')} = ReleaseEphys;
elseif length(ReleaseEphys)>length(PressEphys)
    error('Need debug!');
end

if ~isempty(find(strcmp(EventOut.EventsLabels, 'Trigger')))
    TriggerEphys     =     EventOut.Onset{strcmp(EventOut.EventsLabels, 'Trigger')};
else
    TriggerEphys     =     [];
end

% Lever presses, FP, releases, and correct index recorded in MED
PressBehavior             =     myclass.PressTime*1000;          % press time recorded in MED
ReleaseBehavior         =     myclass.ReleaseTime*1000;      % lever releases recorded in MED
TriggerBehavior           =     myclass.ToneTime*1000;            % trigger time recorded in MED. For uncued trials, tone occured after good release but was not recorded. 
PerformanceBehavior  =     myclass.Outcome;
PressIndex                   =     myclass.PressIndex;  % this is from 1 to whatever the last press index is
FP                                =     myclass.FP;
if isprop(myclass, 'Cue')
    CueBehavior                 =    myclass.Cue;
else
    CueBehavior = ones(1, myclass.TrialNum);
end;

PressIndexEphys    =               ones(1, length(PressEphys));
% Start to map
% PressBehavior is the time recorded in MED
% PressEphys is the time recorded in Ephys system
% IndMatched gives the matching index. 

IndMatched                                                       =             findseqmatchrev(PressBehavior, PressEphys, 0, 1); % note that IndMatched has the same length as PressEphys
% IndMatched = findseqmatchWXN(PressBehavior, PressEphys, 1, 'AlignmentMED', 2); % debug, in some supercat ephys conditions
IndNaN                                                              =             find(isnan(IndMatched));
IndValid                                                             =              find(~isnan(IndMatched));

PressEphysIndex                                              =              [1:length(PressEphys)]; % this is 1 to the total number of press recorded in ephys
PressEphysIndex(IndNaN)                                 =            NaN;   % only for these presses we can find matching ones in behavior. some ephys-press cannot be mapped. 
PressEphysIndex(IndValid)                                 =            PressIndex(IndMatched(IndValid));   % only for these presses we can find matching ones in behavior. some ephys-press cannot be mapped. 
PressEphysIndex2Behavior                              =            PressEphysIndex; %
% Need to figure out these

if ~isempty(BpodEvents) && isfield(BpodEvents,'AllPressTypeVI')
    PerformanceEphys = cell(1, length(PressEphys));
    PressBpod = BpodEvents.AllPress.*1000;
    PressBpodType = BpodEvents.AllPressTypeVI;

    if length(PressEphys)==length(PressBpod)
        idxGoodPress = PressBpodType==1;
        idxBadPress = PressBpodType==-1;
        idxOtherPress = PressBpodType==0;
        PerformanceEphys(idxGoodPress) = repmat({'Correct'},1,sum(idxGoodPress));
        PerformanceEphys(idxBadPress) = repmat({'Premature'},1,sum(idxBadPress)); % borrow the concept in SRT task, they are both press before the correct press time
        PerformanceEphys(idxOtherPress) = repmat({'Late'},1,sum(idxOtherPress)); % borrow the concept in SRT task, they are both press after the correct press time
    elseif length(PressEphys)<length(PressBpod)
        % there may be extra final press in bpod in the session not
        % completing expected trials
        Indout = findseqmatchrev(PressBpod, PressEphys, 0, 0);
%         Indout = findseqmatchWXN(PressBpod, PressEphys, 1, 'AlignmentBpod2', 2); % for debug
        close(58); % fig number in findseqmatchrev
        PressBpodType = PressBpodType(Indout(~isnan(Indout)));
        idxGoodPress = PressBpodType==1;
        idxBadPress = PressBpodType==-1;
        idxOtherPress = PressBpodType==0;
        PerformanceEphys(idxGoodPress) = repmat({'Correct'},1,sum(idxGoodPress));
        PerformanceEphys(idxBadPress) = repmat({'Premature'},1,sum(idxBadPress)); % borrow the concept in SRT task, they are both press before the correct press time
        PerformanceEphys(idxOtherPress) = repmat({'Late'},1,sum(idxOtherPress)); % borrow the concept in SRT task, they are both press after the correct press time
    else
        error('EphysPress was not trimmed to the same length of BpodPress. It should be!');
    end
else
    PerformanceEphys                                            =           cell(1, length(PressEphys)); % each press corresponds to a behavioral outcome
    PerformanceEphys(IndNaN)                              =           repmat({'NaN'}, 1, length(IndNaN));
    PerformanceEphys(IndValid)                              =           PerformanceBehavior(IndMatched(IndValid));
end

CueEphys                                                           =           zeros(1, length(PressEphys)); % each press corresponds to a behavioral outcome
CueEphys(IndNaN)                                            =           NaN;
CueEphys(IndValid)                                            =           CueBehavior(IndMatched(IndValid));

FPEphys                                                           =           zeros(1, length(PressEphys)); % each press corresponds to a behavioral outcome
FPEphys(IndNaN)                                            =           NaN;
if ~isempty(FP)
    FPEphys(IndValid)                                            =           FP(IndMatched(IndValid));
end
EventOut.OutcomeEphys                                  =          PerformanceEphys;
EventOut.CueEphys                                          =           [PressIndexEphys;  CueEphys]';
EventOut.FP_Ephys                                          =           FPEphys;

% if for some reasons, there is no trigger events in EventOut, we can fill
% it in
TriggerTimeMapped = [];
for i =1: length(PressEphys)
    iPressTimeEphys             =           PressEphys(i);
    if ~isnan(PressEphysIndex2Behavior(i))
        iPressTimeBehavior         =           PressBehavior(PressEphysIndex2Behavior(i));
        if i<length(PressEphys)
            if TriggerBehavior(PressEphysIndex2Behavior(i))>0
                TriggerTimeMapped = [TriggerTimeMapped TriggerBehavior(PressEphysIndex2Behavior(i))-iPressTimeBehavior+iPressTimeEphys];
            end;
        end;
    end
end;

ReleaseTimeMapped = [];
for i =1: length(PressEphys)
    iPressTimeEphys             =           PressEphys(i);
    if ~isnan(PressEphysIndex2Behavior(i))
        iPressTimeBehavior         =           PressBehavior(PressEphysIndex2Behavior(i));
        iReleaseTimeBehavior         =       ReleaseBehavior(PressEphysIndex2Behavior(i));
        if ~isnan(iPressTimeBehavior)
            ReleaseTimeMapped(i) =  iReleaseTimeBehavior-iPressTimeBehavior+iPressTimeEphys
        end;
    end
end;

if contains(myclass.Protocol,'ThreeFPsMixedBpodProbe')
    EventOut.Offset{strcmp(EventOut.EventsLabels, 'LeverPress')} = ReleaseTimeMapped(:);
end

% find out the min distance between triggertimemapped and the ones recorded
% in blackrock
figure;
subplot(2, 1, 1)
plot(ReleaseEphys, 5, 'ko');
hold on
line([ReleaseTimeMapped' ReleaseTimeMapped'], [4 6]', 'color', 'm')
set(gca, 'ylim', [4 6])
ylabel('Release')

subplot(2, 1, 2)
if ~isempty(TriggerEphys)
    plot(TriggerEphys, 5, 'ko');
end;
hold on
line([TriggerTimeMapped' TriggerTimeMapped'], [4 6]', 'color', 'm')
set(gca, 'ylim', [4 6])
ylabel('Trigger')

if ~isempty(TriggerEphys)
    IndTrigger2Keep = []; % this is to get rid of trigger events that are not really trigger events (e.g., correct release)
    minD= ones(1, length(TriggerTimeMapped));
    for k =1:length(TriggerTimeMapped)
        [~, ind_min]= min(abs(TriggerTimeMapped(k) - TriggerEphys));
        IndTrigger2Keep = [IndTrigger2Keep ind_min];
        minD(k) = TriggerTimeMapped(k) - TriggerEphys(ind_min);
        sprintf('Distance is %2.2f ms', minD(k))
    end;
    TriggerEphys = TriggerEphys(IndTrigger2Keep);
end

minDRelease= ones(1, length(ReleaseTimeMapped))
for k =1:length(ReleaseTimeMapped)
    minDRelease(k) = min(abs(ReleaseTimeMapped(k) - ReleaseEphys));
    sprintf('Distance is %2.2f ms', minDRelease(k))
end;

figure;
subplot(2, 1, 1)
if ~isempty(TriggerEphys)
    histogram(minD)
end;
xlabel('Time difference between Blackrock trigger and MED trigger');
ylabel('Count')
subplot(2, 1, 2)
histogram(minDRelease)
xlabel('Time difference between Blackrock release and MED release');
ylabel('Count')

if isempty(TriggerEphys);
    EventOut.EventsLabels{end+1}='Trigger';
    EventOut.Onset{end+1}=TriggerTimeMapped;
    TriggerDur = 250; % 250 ms trigger events
    EventOut.Onset{end+1}=TriggerTimeMapped+TriggerDur;
else
    TriggerDur = 250; % 250 ms trigger events
    EventOut.Onset{strcmp(EventOut.EventsLabels, 'Trigger')}=TriggerEphys;
    EventOut.Offset{strcmp(EventOut.EventsLabels, 'Trigger')}=TriggerEphys+TriggerDur;
end;