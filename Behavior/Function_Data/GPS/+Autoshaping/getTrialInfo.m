function obj = getTrialInfo(obj, SessionData)

obj.NumTrials = SessionData.nTrials;

obj.Trials = (1:obj.NumTrials)';
obj.TrialStartTime = SessionData.TrialStartTimestamp(obj.Trials)';

obj.InitPokeInTime = cell(obj.NumTrials, 1);
obj.InitPokeOutTime = cell(obj.NumTrials, 1);

obj.CentPokeInTime = cell(obj.NumTrials, 1);
obj.CentPokeOutTime = cell(obj.NumTrials, 1);

obj.ChoiceCueTime = zeros(obj.NumTrials, 2);
obj.TriggerCueTime = nan(obj.NumTrials, 1);
obj.ChoicePokeTime = zeros(obj.NumTrials, 1);

obj.PortCorrect = zeros(obj.NumTrials, 1);
obj.PortChosen = zeros(obj.NumTrials, 1);
obj.Outcome = strings(obj.NumTrials, 1);

obj.TargetFP = 0;
obj.FP = zeros(obj.NumTrials, 1);
obj.RW = zeros(obj.NumTrials, 1);
obj.Cued = zeros(obj.NumTrials, 1);
obj.LateChoice = strings(obj.NumTrials, 1);

for i = 1:obj.NumTrials
    iStates = SessionData.RawEvents.Trial{i}.States;
    iEvents = SessionData.RawEvents.Trial{i}.Events;

    if isnan(iStates.WrongPort(1)) && isnan(iStates.Wait4Reward(1))
        obj.Outcome(i) = "Bug";
        continue;
    end

    obj.InitPokeInTime{i} = iEvents.Port3In(iEvents.Port3In>=iStates.Wait4Sample(1) & iEvents.Port3In<=iStates.Wait4Center(2))';
    obj.InitPokeOutTime{i} = iEvents.Port3Out(iEvents.Port3Out>=iStates.Wait4Sample(1) & iEvents.Port3Out<=iStates.Wait4Center(2))';

    obj.CentPokeInTime{i} = iEvents.Port4In(iEvents.Port4In>=iStates.Wait4Center(2) & iEvents.Port4In<=iStates.Wait4Choice(1))';
    obj.CentPokeOutTime{i} = iEvents.Port4Out(iEvents.Port4Out>=iStates.Wait4Center(2) & iEvents.Port4Out<=iStates.Wait4Choice(1))';
%     obj.CentPokeInTime{i} = iEvents.Port4In(iEvents.Port4In>=iStates.Wait4Center(1) & iEvents.Port4In<=iStates.Wait4Choice(2));
%     obj.CentPokeOutTime{i} = iEvents.Port4Out(iEvents.Port4Out>=iStates.Wait4Center(1) & iEvents.Port4Out<=iStates.Wait4Choice(2));

    obj.ChoiceCueTime(i, :) = [iStates.CentralReward(1) iStates.Wait4Choice(2)];
    obj.ChoicePokeTime(i) = iStates.Wait4Choice(2);
    obj.PortCorrect(i) = SessionData.Custom.CorPort(i);

    obj.ChoicePokeTime(i) = iStates.Wait4Choice(2);
    if ~isnan(iStates.WrongPort(1)) % selected the wrong port
        obj.Outcome(i) = 'Wrong';
        % figure out the port situation: WrongPort(1)
        % should match a port entry time
        if isfield(iEvents, 'Port2In') && sum(ismember(iEvents.Port2In, iStates.WrongPort(1)))
            obj.PortChosen(i) = 2;
        elseif isfield(iEvents, 'Port1In') && sum(ismember(iEvents.Port1In, iStates.WrongPort(1)))
            obj.PortChosen(i) = 1;
        else % sometimes, they poke during the choice light presentation
            obj.PortChosen(i) = NaN;
        end
    elseif ~isnan(iStates.Wait4Reward(1))
        obj.Outcome(i) = 'Correct';
        % find out the port
        if isfield(iEvents, 'Port2In') && sum(ismember(iEvents.Port2In, iStates.Wait4Reward(1)))
            obj.PortChosen(i) = 2;
        elseif isfield(iEvents, 'Port1In') && sum(ismember(iEvents.Port1In, iStates.Wait4Reward(1)))
            obj.PortChosen(i) = 1;
        else % sometimes, they poke during the choice light presentation
            obj.PortChosen(i) = NaN;
        end
    end
end

%%
%% remove bug trials
ind_bug = obj.Outcome=="Bug";

obj.NumTrials = obj.NumTrials - sum(ind_bug);

obj.Trials(ind_bug)             = [];
obj.TrialStartTime(ind_bug)     = [];

obj.FP(ind_bug)                 = [];
obj.RW(ind_bug)                 = [];

obj.InitPokeInTime(ind_bug)     = [];
obj.InitPokeOutTime(ind_bug)    = [];

obj.CentPokeInTime(ind_bug)     = [];
obj.CentPokeOutTime(ind_bug)    = [];

obj.ChoiceCueTime(ind_bug, :)   = [];
obj.TriggerCueTime(ind_bug)     = [];
obj.ChoicePokeTime(ind_bug)     = [];

obj.PortCorrect(ind_bug)        = [];
obj.PortChosen(ind_bug)         = [];
obj.Outcome(ind_bug)            = [];
obj.LateChoice(ind_bug)         = [];

obj.Cued(ind_bug)               = [];

end % getTrialInfo