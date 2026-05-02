function EventOut = AlignBehToEphys(EventOut, BehClass)

% 3/3/2021 Jianing Yu - AlignMED2BR
% EventOut comes from BlackRock's digital input
% bMED is the b array coming from MED data
% Time of some critical behavioral events (e.g., Trigger stimulus) needs to be mapped to EventOut
% Alignment is performed using press onset data
% Alignment of each trigger stimulus needs to be adjusted to the preceding press
% onset

% 4/2/2023 - AlignBehaviorClassToBR - revised from AlignMED2BR but use behavior class instead
% the goal of this function is to find the behavioral meaning of each blackrock's press 
% Lever presses and releases recorded in blackrock

% 10/9/2024 Zhuohao Zhang - AlignBehToEphys - revised from AlignBehaviorClassToBR for GPS tasks
% the goal of this function is to find the behavioral meaning of each neuropixels' PokeCentIn 
% PokeChoiceIn and PokeInitIn. And complete behavior events in ephys
% recording (Trigger, PokeCentOut)

% these are times for poke-in center, choice and init recorded in ephys.
PokeCentInEphys   = EventOut.Onset{strcmp(EventOut.EventsLabels, 'PokeCentIn')};
PokeChoiceInEphys = EventOut.Onset{strcmp(EventOut.EventsLabels, 'PokeChoiceIn')};
PokeInitInEphys   = EventOut.Onset{strcmp(EventOut.EventsLabels, 'PokeInitIn')};

% Sometimes the recording miss the first init_in signal before cent_in, we drop that
if PokeInitInEphys(1) > PokeCentInEphys(1) % missing occurred
    PokeCentInEphys(1) = [];
    if PokeChoiceInEphys(1) < PokeCentInEphys(1)
        PokeChoiceInEphys(1) = [];
    end
end
% Sometimes the recording over-take the last+1 init_in signal without cent_in, we drop that
if PokeInitInEphys(end) > PokeCentInEphys(end) % over-taking occurred
    PokeInitInEphys(end) = [];
end

% these are times for poke-in center, choice and init recorded in bpod
Beh = BehClass.BehavTable;

PokeCentInBeh   = Beh.TrialCentInTime*1000;
PokeCentOutBeh  = (Beh.TrialStartTime+Beh.CentOutTime)*1000;
PokeChoiceInBeh = (Beh.TrialStartTime+Beh.ChoicePokeTime)*1000;
PokeInitInBeh   = (Beh.TrialStartTime+Beh.InitInTime)*1000;
PokeInitOutBeh  = (Beh.TrialStartTime+Beh.InitOutTime)*1000;
TriggerBeh      = (Beh.TrialStartTime+Beh.TriggerCueTime)*1000;

PerformanceBeh = Beh.Outcome;
TrialIndexBeh  = Beh.Trials;
PortCorrectBeh = Beh.PortCorrect;
PortChosenBeh  = Beh.PortChosen;
FPBeh          = Beh.FP;
CueBeh         = Beh.Cued;
StageBeh       = Beh.Stage;

%
% Start to map
% PokeCentInBeh is the time recorded in Bpod
% PokeCentInEphys is the time recorded in Ephys system
% IndMatched gives the matching index. 

IndMatched = findseqmatchrev(PokeCentInBeh, PokeCentInEphys, 0, 1); % note that IndMatched has the same length as PokeCentInEphys
IndValid   = find(~isnan(IndMatched));

PokeCentInEphys   = PokeCentInEphys(IndValid);
PokeInitInEphys   = PokeInitInEphys(IndValid);

IndMatchedChoice  = findseqmatchrev(PokeChoiceInBeh, PokeChoiceInEphys, 0, 1); % note that IndMatched has the same length as PokeCentInEphys
IndValidChoice    = ~isnan(IndMatchedChoice);
PokeChoiceInEphys = PokeChoiceInEphys(IndValidChoice);

% Update EventOut
EventOut.Onset{strcmp(EventOut.EventsLabels, 'PokeCentIn')}   = PokeCentInEphys;
EventOut.Onset{strcmp(EventOut.EventsLabels, 'PokeChoiceIn')} = PokeChoiceInEphys;
EventOut.Onset{strcmp(EventOut.EventsLabels, 'PokeInitIn')}   = PokeInitInEphys;

NumTrialsEphys = length(PokeCentInEphys);

%
TrialIndexEphys  = TrialIndexBeh(IndMatched(IndValid)); % only for these presses we can find matching ones in behavior
PerformanceEphys = PerformanceBeh(IndMatched(IndValid));
CueEphys         = CueBeh(IndMatched(IndValid));
FPEphys          = FPBeh(IndMatched(IndValid));
PortCorrectEphys = PortCorrectBeh(IndMatched(IndValid));
PortChosenEphys  = PortChosenBeh(IndMatched(IndValid));
StageEphys       = StageBeh(IndMatched(IndValid));

% add information to EventOut
EventOut.TrialIndexEphys       = TrialIndexEphys;
EventOut.OutcomeEphys          = PerformanceEphys;
EventOut.CueEphys              = CueEphys;
EventOut.FPEphys               = FPEphys;
EventOut.PortCorrectEphys      = PortCorrectEphys;
EventOut.PortChosenEphys       = PortChosenEphys;
EventOut.StageEphys            = StageEphys;

% there are no marks for trigger and poke-cent-out during GPS neuropixels
% recording, we can fill them in through poke-cent-in time

% Trigger
TriggerMapped = nan(1, NumTrialsEphys);
for i = 1:NumTrialsEphys
    iPokeCentInEphys = PokeCentInEphys(i);
    if ~isnan(TrialIndexEphys(i))
        ind_beh = find(TrialIndexBeh==TrialIndexEphys(i));
        iPokeCentInBeh = PokeCentInBeh(ind_beh);
        iTriggerBeh = TriggerBeh(ind_beh);
        if iTriggerBeh > 0
            TriggerMapped(i) = iTriggerBeh-iPokeCentInBeh+iPokeCentInEphys;
        end
    end
end
TriggerMapped = TriggerMapped(~isnan(TriggerMapped));

% Cent out
PokeCentOutMapped = nan(1, NumTrialsEphys);
for i = 1:NumTrialsEphys
    iPokeCentInEphys = PokeCentInEphys(i);
    if ~isnan(TrialIndexEphys(i))
        ind_beh = find(TrialIndexBeh==TrialIndexEphys(i));
        iPokeCentInBeh  = PokeCentInBeh(ind_beh);
        iPokeCentOutBeh = PokeCentOutBeh(ind_beh);
        if ~isnan(iPokeCentOutBeh)
            PokeCentOutMapped(i) = iPokeCentOutBeh-iPokeCentInBeh+iPokeCentInEphys;
        end
    end
end

% in some cases, there are no marks for choice poke in (premature trials or some probe trials)
% Choice
ChoiceInMapped = nan(1, NumTrialsEphys);
for i = 1:NumTrialsEphys
    iPokeCentInEphys = PokeCentInEphys(i);
    if ~isnan(TrialIndexEphys(i))
        ind_beh = find(TrialIndexBeh==TrialIndexEphys(i));
        iPokeCentInBeh = PokeCentInBeh(ind_beh);
        iPokeChoiceInBeh = PokeChoiceInBeh(ind_beh);
        if iPokeChoiceInBeh > 0
            ChoiceInMapped(i) = iPokeChoiceInBeh-iPokeCentInBeh+iPokeCentInEphys;
        end
    end
end
ChoiceInMapped = ChoiceInMapped(~isnan(ChoiceInMapped));
% complete the original choice marker from recording
ChoiceInToFill = false(1, length(ChoiceInMapped));
for i = 1:length(ChoiceInMapped)
    dt = min(abs(ChoiceInMapped(i) - PokeChoiceInEphys)); % get the distance between ephys marker and mapped marker
    if dt > 500 % if the distance is larger than 500ms
        ChoiceInToFill(i) = true;
    end
end
ChoiceInFilled = [PokeChoiceInEphys', ChoiceInMapped(ChoiceInToFill)];
ChoiceInFilled = sort(ChoiceInFilled);

% there are no marks for poke-init-out during GPS neuropixels
% recording, we can fill them in through poke-init-in time
% Init out
InitOutMapped = nan(1, NumTrialsEphys);
for i = 1:NumTrialsEphys
    iPokeInitInEphys = PokeInitInEphys(i);
    if ~isnan(TrialIndexEphys(i))
        ind_beh = find(TrialIndexBeh==TrialIndexEphys(i));
        iPokeInitInBeh = PokeInitInBeh(ind_beh);
        iPokeInitOutBeh = PokeInitOutBeh(ind_beh);
        if iPokeInitOutBeh > 0
            InitOutMapped(i) = iPokeInitOutBeh-iPokeInitInBeh+iPokeInitInEphys;
        end
    end
end
InitOutMapped = InitOutMapped(~isnan(InitOutMapped));

% find out the min distance between triggertimemapped and the ones recorded
% in blackrock
figure;
subplot(2, 1, 1)
plot(PokeCentInEphys, 5, 'ko');
hold on
line([PokeCentOutMapped' PokeCentOutMapped'], [4 6]', 'color', 'm')
set(gca, 'ylim', [4 6])
ylabel('Poke-out center')

if ~isempty(TriggerMapped) % In Autoshaping task, there is no trigger
    subplot(2, 1, 2)
    plot(PokeCentInEphys, 5, 'ko');
    hold on
    line([TriggerMapped' TriggerMapped'], [4 6]', 'color', 'm')
    set(gca, 'ylim', [4 6])
    ylabel('Trigger')
end

% add event time info to EventOut
if isempty(find(strcmp(EventOut.EventsLabels, 'Trigger'), 1))
    EventOut.EventsLabels{end+1}='Trigger';
end
TriggerDur = 250; % 250 ms trigger events
EventOut.Onset{strcmp(EventOut.EventsLabels, 'Trigger')}  = TriggerMapped;
EventOut.Offset{strcmp(EventOut.EventsLabels, 'Trigger')} = TriggerMapped + TriggerDur;

if isempty(find(strcmp(EventOut.EventsLabels, 'PokeCentOut'), 1))
    EventOut.EventsLabels{end+1}='PokeCentOut';
end
EventOut.Onset{strcmp(EventOut.EventsLabels, 'PokeCentOut')}  = PokeCentOutMapped;
EventOut.Offset{strcmp(EventOut.EventsLabels, 'PokeCentOut')} = PokeCentOutMapped + 200;

if isempty(find(strcmp(EventOut.EventsLabels, 'PokeChoiceIn'), 1))
    EventOut.EventsLabels{end+1}='PokeChoiceIn';
end
EventOut.Onset{strcmp(EventOut.EventsLabels, 'PokeChoiceIn')}  = ChoiceInFilled;
EventOut.Offset{strcmp(EventOut.EventsLabels, 'PokeChoiceIn')} = ChoiceInFilled + 200;

if isempty(find(strcmp(EventOut.EventsLabels, 'PokeInitOut'), 1))
    EventOut.EventsLabels{end+1}='PokeInitOut';
end
EventOut.Onset{strcmp(EventOut.EventsLabels, 'PokeInitOut')}  = InitOutMapped;
EventOut.Offset{strcmp(EventOut.EventsLabels, 'PokeInitOut')} = InitOutMapped + 200;

end % AlignBehToEphys