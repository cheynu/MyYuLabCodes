function EventOut = AlignBehaviorClassToBR_MS(EventOut, myclass)

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

% 4/12/2023 version 
% adapted to multiple myclass from seperated sessions. 

% these are times for lever press and release recorded in blackrock
PressEphys        =     EventOut.Onset{strcmp(EventOut.EventsLabels, 'LeverPress')};
ReleaseEphys     =     EventOut.Offset{strcmp(EventOut.EventsLabels, 'LeverPress')};
TriggerEphys     =     EventOut.Onset{strcmp(EventOut.EventsLabels, 'Trigger')};

% Need to figure out these
FP_Ephys                    =          zeros(1, length(PressEphys)); % the FP of each press
OutcomeEphys            =         zeros(1, length(PressEphys));  % the outcome of each press
CueEphys                    =         zeros(1, length(PressEphys)); % Cue/Uncue of each press
% Lever presses, FP, releases, and correct index recorded in MED

% myclass now is a cell array
PressBehavior             =     cell(1, length(myclass));          % press time recorded in MED
ReleaseBehavior         =     cell(1, length(myclass));      % lever releases recorded in MED
TriggerBehavior           =     cell(1, length(myclass));           % trigger time recorded in MED. For uncued trials, tone occured after good release but was not recorded. 
PerformanceBehavior  =     cell(1, length(myclass)); 
PressIndex                   =     cell(1, length(myclass)); 
FP                                 =     cell(1, length(myclass)); 
CueBehavior                 =     cell(1, length(myclass)); 

for i = 1:length(myclass)
    PressBehavior{i}             =     myclass{i}.PressTime*1000;          % press time recorded in MED
    ReleaseBehavior{i}         =     myclass{i}.ReleaseTime*1000;      % lever releases recorded in MED
    TriggerBehavior{i}           =     myclass{i}.ToneTime*1000;            % trigger time recorded in MED. For uncued trials, tone occured after good release but was not recorded.
    PerformanceBehavior{i}  =     myclass{i}.Outcome;
    PressIndex{i}                   =     myclass{i}.PressIndex;
    FP{i}                                 =     myclass{i}.FP;
    if isprop(myclass{i}, 'Cue')
        CueBehavior{i}                 =    myclass{i}.Cue;
    else
        CueBehavior{i} = ones(1, myclass{i}.TrialNum);
    end;
end;

PressIndexEphys    =               ones(1, length(PressEphys));

if length(myclass)>1 % multiple sessions
    t_critical = 30*60*1000; % this is the critical checking point, in ms
    if find(diff(PressEphys)>t_critical)  % multiple segments
        % Track bpod
        ind_breakpoint = find(diff(PressEphys)>t_critical);
        disp(PressEphys(ind_breakpoint))
        disp(PressEphys(ind_breakpoint+1))
        disp( (PressEphys(ind_breakpoint+1)- PressEphys(ind_breakpoint)))
        % press before [1 ind_breakpoint(i)], [ind_breakpoint(i)+1
        % ind_breakpoint(i+1)], ..., [ind_breakpoint(end)+1 end]
        ind_segments_beg =[1 ind_breakpoint'+1];
        ind_segments_end = [ind_breakpoint' length(PressEphys)];
    else
        ind_segments_beg = 1;
        ind_segments_end = length(PressEphys);
    end;
else
    ind_segments_beg = 1;
    ind_segments_end = length(PressEphys);
end;

PressEphysIndex2Behavior = cell(1, length(myclass));
EventOut.OutcomeEphys                                  =          [];
EventOut.CueEphys                                          =          [];
EventOut.FP_Ephys                                          =          [];
% if for some reasons, there is no trigger events in EventOut, we can fill
% it in
TriggerTimeMapped = [];
for i =1:length(myclass)

    iPressEphysIndex                                             =            PressIndexEphys([ind_segments_beg(i):ind_segments_end(i)]);
    iPressEphys                                                      =            PressEphys([ind_segments_beg(i):ind_segments_end(i)]);
    IndMatched                                                       =            findseqmatchrev(PressBehavior{i}, iPressEphys, 0, 1);
    iPressEphysIndex(isnan(IndMatched))              =           NaN;   % only for these presses we can find matching ones in behavior
    PressEphysIndex2Behavior{i}                            =          PressIndex{i}(IndMatched); %
    EventOut.OutcomeEphys                                  =           [EventOut.OutcomeEphys PerformanceBehavior{i}(IndMatched)];
    EventOut.CueEphys                                          =           [EventOut.CueEphys; [1:length(iPressEphysIndex);  CueBehavior{i}(IndMatched)]'];
    EventOut.FP_Ephys                                          =           [EventOut.FP_Ephys; FP{i}(IndMatched)'];
    iTriggerBehavior                                                 =          TriggerBehavior{i};

    for k =1: length(iPressEphys)
        kPressTimeEphys             =           iPressEphys(k);
        kPressTimeBehavior         =           PressBehavior{i}(PressEphysIndex2Behavior{i}(k));
        if k<length(PressEphys)
            if iTriggerBehavior(PressEphysIndex2Behavior{i}(k))>0
                disp( iTriggerBehavior(PressEphysIndex2Behavior{i}(k))-kPressTimeBehavior+kPressTimeEphys - kPressTimeEphys)
                TriggerTimeMapped = [TriggerTimeMapped iTriggerBehavior(PressEphysIndex2Behavior{i}(k))-kPressTimeBehavior+kPressTimeEphys];
            end;
        end;
    end;
end;

% find out the min distance between triggertimemapped and the ones recorded
% in blackrock
figure;
 
subplot(2, 1, 1)
plot(TriggerEphys, 5, 'ko');
hold on
line([TriggerTimeMapped' TriggerTimeMapped'], [4 6]', 'color', 'm')
set(gca, 'ylim', [4 6])
ylabel('Trigger')

IndTrigger2Keep = []; % this is to get rid of trigger events that are not really trigger events (e.g., correct release)
minD= ones(1, length(TriggerTimeMapped));
for k =1:length(TriggerTimeMapped)
    [~, ind_min]= min(abs(TriggerTimeMapped(k) - TriggerEphys));
    IndTrigger2Keep = [IndTrigger2Keep ind_min];
    minD(k) = TriggerTimeMapped(k) - TriggerEphys(ind_min);
    sprintf('Distance is %2.2f ms', minD(k))
end;
TriggerEphys = TriggerEphys(IndTrigger2Keep);
 
subplot(2, 1, 2)
histogram(minD)
xlabel('Time difference between Blackrock trigger and MED trigger');
ylabel('Count')

if isempty(find(strcmp(EventOut.EventsLabels, 'Trigger')));
    EventOut.EventsLabels{end+1}='Trigger';
    EventOut.Onset{end+1}=TriggerTimeMapped;
else
    TriggerDur = 250; % 250 ms trigger events
    EventOut.Onset{strcmp(EventOut.EventsLabels, 'Trigger')}=TriggerEphys;
    EventOut.Offset{strcmp(EventOut.EventsLabels, 'Trigger')}=TriggerEphys+TriggerDur;
end;