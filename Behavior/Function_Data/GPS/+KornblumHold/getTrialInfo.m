function obj = getTrialInfo(obj, SessionData)
% Get trial information of events' time points
obj.NumTrials = SessionData.nTrials;

obj.Trials = (1:obj.NumTrials)';
obj.TrialStartTime = SessionData.TrialStartTimestamp(obj.Trials)';

obj.InitPokeInTime = cell(obj.NumTrials, 1);
obj.InitPokeOutTime = cell(obj.NumTrials, 1);

obj.CentPokeInTime = cell(obj.NumTrials, 1);
obj.CentPokeOutTime = cell(obj.NumTrials, 1);

obj.ChoiceCueTime = zeros(obj.NumTrials, 2);
obj.TriggerCueTime = zeros(obj.NumTrials, 1);
obj.ChoicePokeTime = zeros(obj.NumTrials, 1);

obj.PortCorrect = zeros(obj.NumTrials, 1);
obj.PortChosen = zeros(obj.NumTrials, 1);
obj.Outcome = strings(obj.NumTrials, 1);
obj.LateChoice = strings(obj.NumTrials, 1);

if ~isfield(SessionData.Custom, "Version")
    obj.FP = SessionData.Custom.FP';
else
    switch SessionData.Custom.Version
        case {'20230312', '20230618'}
            obj.FP = zeros(obj.NumTrials, 1);
            for i = 1:SessionData.nTrials
                if ~isfield(SessionData.RawEvents.Trial{1, i}.Events, 'BNC1High')
                    obj.Outcome(i) = "Bug";
                else
                    obj.FP(i) = SessionData.RawEvents.Trial{1, i}.Events.BNC1High(1) - SessionData.RawEvents.Trial{1, i}.States.FP(1);
                end
            end
    end
end
obj.Cued = SessionData.Custom.Cued';
obj.RW = SessionData.Custom.RW';

switch SessionData.Custom.Version

    %% Version 20230312, time controlled by Arduino, 3 uncued RWs
    case {'20230312'}
        for i = 1:obj.NumTrials

            if obj.Outcome(i)=="Bug"
                continue;
            end

            iStates = SessionData.RawEvents.Trial{i}.States;
            iEvents = SessionData.RawEvents.Trial{i}.Events;

            obj.InitPokeInTime{i} = iEvents.Port3In(iEvents.Port3In>=iStates.Wait4Sample(1) & iEvents.Port3In<=iStates.Wait4Center(2));
            obj.InitPokeOutTime{i} = iEvents.Port3Out(iEvents.Port3Out>=iStates.Wait4Sample(1) & iEvents.Port3Out<=iStates.Wait4Center(2));

            obj.CentPokeInTime{i} = iStates.FP(:, 1);
            obj.PortCorrect(i) = SessionData.Custom.CorPort(i);

            if ~isnan(iStates.Premature(1)) % Premature
                obj.Outcome(i) = "Premature";
                obj.CentPokeOutTime{i} = iStates.FP(:, 2);
                obj.ChoiceCueTime(i, :) = [iStates.FP(1) iStates.Premature(1)];
                obj.TriggerCueTime(i) = nan;
                obj.ChoicePokeTime(i) = nan;
                obj.PortChosen(i) = nan;

                if iStates.FP(end, 2) - iStates.FP(1, 1) > obj.FP(i)
                    obj.Outcome(i) = "Bug";
                end
            elseif ~isnan(iStates.Late(1)) % Late
                obj.Outcome(i) = "Late";
                obj.CentPokeOutTime{i} = [iStates.FP(1:end-1, 2); iStates.Late(2)];
                obj.ChoiceCueTime(i, :) = [iStates.FP(1) iStates.Late(2)];
                obj.TriggerCueTime(i) = iStates.FP(end, 2);

                if ~any(isfield(iStates, ["LateWrong", "LateCorrect"]))
                    obj.ChoicePokeTime(i) = nan;
                    % figure out the port situation: WrongPort(1)
                    % should match a port entry time
                    obj.PortChosen(i) = nan;
                elseif ~isnan(iStates.LateWrong(1))
                    obj.LateChoice(i) = "Wrong";
                    obj.ChoicePokeTime(i) = iStates.LateWrong(1);
                    % figure out the port situation: WrongPort(1)
                    % should match a port entry time
                    if isfield(iEvents, 'Port2In') && sum(ismember(iEvents.Port2In, iStates.LateWrong(1)))
                        obj.PortChosen(i) = 2;
                    elseif  isfield(iEvents, 'Port1In') && sum(ismember(iEvents.Port1In, iStates.LateWrong(1)))
                        obj.PortChosen(i) = 1;
                    else % sometimes, they poke during the choice light presentation
                        obj.PortChosen(i) = nan;
                    end
                elseif ~isnan(iStates.LateCorrect(1))
                    obj.LateChoice(i) = "Correct";
                    obj.ChoicePokeTime(i) = nan;
                    % figure out the port situation: WrongPort(1)
                    % should match a port entry time
                    if isfield(iEvents, 'Port2In') && sum(ismember(iEvents.Port2In, iStates.LateCorrect(1)))
                        obj.PortChosen(i) = 2;
                    elseif  isfield(iEvents, 'Port1In') && sum(ismember(iEvents.Port1In, iStates.LateCorrect(1)))
                        obj.PortChosen(i) = nan;
                    else % sometimes, they poke during the choice light presentation
                        obj.PortChosen(i) = nan;
                    end
                else
                    obj.LateChoice(i) = "Miss";
                    obj.ChoicePokeTime(i) = nan;
                    % figure out the port situation: WrongPort(1)
                    % should match a port entry time
                    obj.PortChosen(i) = nan;
                end
            elseif ~isnan(iStates.WrongPort(1)) % selected the wrong port
                obj.Outcome(i) = 'Wrong';
                obj.ChoiceCueTime(i, :) = [iStates.FP(1) iStates.WrongPort(1)]; % duration that the choice light lit up.
                obj.TriggerCueTime(i) = iStates.FP(end, 2);
                switch obj.Cued(i)
                    case 1
                        obj.CentPokeOutTime{i} = [iStates.FP(1:end-1, 2); iStates.Wait4ChoiceCue(1)];
                    case 0
                        if ~isnan(iStates.Wait4Out_UncueSlow)
                            obj.CentPokeOutTime{i} = [iStates.FP(1:end-1, 2); iStates.Wait4ChoiceUncueSlow(1)];
                        elseif ~isnan(iStates.Wait4Out_Uncue)
                            obj.CentPokeOutTime{i} = [iStates.FP(1:end-1, 2); iStates.Wait4ChoiceUncue(1)];
                        elseif ~isnan(iStates.Wait4Out_UncueFast)
                            obj.CentPokeOutTime{i} = [iStates.FP(1:end-1, 2); iStates.Wait4ChoiceUncueFast(1)];
                        end
                end
                obj.ChoicePokeTime(i) = iStates.WrongPort(1);
                % figure out the port situation: WrongPort(1)
                % should match a port entry time
                if isfield(iEvents, 'Port2In') && sum(ismember(iEvents.Port2In, iStates.WrongPort(1)))
                    obj.PortChosen(i) = 2;
                elseif  isfield(iEvents, 'Port1In') && sum(ismember(iEvents.Port1In, iStates.WrongPort(1)))
                    obj.PortChosen(i) = 1;
                else % sometimes, they poke during the choice light presentation
                    obj.PortChosen(i) = nan;
                end
            elseif ~isnan(iStates.Wait4RewardCue(1))
                obj.Outcome(i) = 'Correct';
                obj.CentPokeOutTime{i} = [iStates.FP(1:end-1, 2); iStates.Wait4ChoiceCue(1)];
                obj.ChoiceCueTime(i, :) = [iStates.FP(1) iStates.Wait4ChoiceCue(2)]; % duration that the choice light lit up.
                obj.TriggerCueTime(i) = iStates.FP(end, 2);
                obj.ChoicePokeTime(i) = iStates.Wait4ChoiceCue(2);
                % find out the port
                if isfield(iEvents, 'Port2In') && sum(ismember(iEvents.Port2In, iStates.Wait4RewardCue(1)))
                    obj.PortChosen(i) = 2;
                elseif  isfield(iEvents, 'Port1In') && sum(ismember(iEvents.Port1In, iStates.Wait4RewardCue(1)))
                    obj.PortChosen(i) = 1;
                else % sometimes, they poke during the choice light presentation
                    obj.PortChosen(i) = nan;
                end
            elseif ~isnan(iStates.Wait4RewardUncueFast(1))
                obj.Outcome(i) = 'Correct';
                obj.CentPokeOutTime{i} = [iStates.FP(1:end-1, 2); iStates.Wait4ChoiceUncueFast(1)];
                obj.ChoiceCueTime(i, :) = [iStates.FP(1) iStates.Wait4ChoiceUncueFast(2)]; % duration that the choice light lit up.
                obj.TriggerCueTime(i) = iStates.FP(end, 2);
                obj.ChoicePokeTime(i) = iStates.Wait4ChoiceUncueFast(2);
                % find out the port
                if isfield(iEvents, 'Port2In') && sum(ismember(iEvents.Port2In, iStates.Wait4RewardUncueFast(1)))
                    obj.PortChosen(i) = 2;
                elseif  isfield(iEvents, 'Port1In') && sum(ismember(iEvents.Port1In, iStates.Wait4RewardUncueFast(1)))
                    obj.PortChosen(i) = 1;
                else % sometimes, they poke during the choice light presentation
                    obj.PortChosen(i) = nan;
                end
            elseif ~isnan(iStates.Wait4RewardUncue(1))
                obj.Outcome(i) = 'Correct';
                obj.CentPokeOutTime{i} = [iStates.FP(1:end-1, 2); iStates.Wait4ChoiceUncue(1)];
                obj.ChoiceCueTime(i, :) = [iStates.FP(1) iStates.Wait4ChoiceUncue(2)]; % duration that the choice light lit up.
                obj.TriggerCueTime(i) = iStates.FP(end, 2);
                obj.ChoicePokeTime(i) = iStates.Wait4ChoiceUncue(2);
                % find out the port
                if isfield(iEvents, 'Port2In') && sum(ismember(iEvents.Port2In, iStates.Wait4RewardUncue(1)))
                    obj.PortChosen(i) = 2;
                elseif  isfield(iEvents, 'Port1In') && sum(ismember(iEvents.Port1In, iStates.Wait4RewardUncue(1)))
                    obj.PortChosen(i) = 1;
                else % sometimes, they poke during the choice light presentation
                    obj.PortChosen(i) = nan;
                end
            elseif ~isnan(iStates.Wait4RewardUncueSlow(1))
                obj.Outcome(i) = 'Correct';
                obj.CentPokeOutTime{i} = [iStates.FP(1:end-1, 2); iStates.Wait4ChoiceUncueSlow(1)];
                obj.ChoiceCueTime(i, :) = [iStates.FP(1) iStates.Wait4ChoiceUncueSlow(2)]; % duration that the choice light lit up.
                obj.TriggerCueTime(i) = iStates.FP(end, 2);
                obj.ChoicePokeTime(i) = iStates.Wait4ChoiceUncueSlow(2);
                % find out the port
                if isfield(iEvents, 'Port2In') && sum(ismember(iEvents.Port2In, iStates.Wait4RewardUncueSlow(1)))
                    obj.PortChosen(i) = 2;
                elseif  isfield(iEvents, 'Port1In') && sum(ismember(iEvents.Port1In, iStates.Wait4RewardUncueSlow(1)))
                    obj.PortChosen(i) = 1;
                else % sometimes, they poke during the choice light presentation
                    obj.PortChosen(i) = nan;
                end
            else
                obj.Outcome(i) = 'Bug';
            end
        end

        %% Version 20230618, time controlled by GlobalTimer, signalled by Arduino, 1 uncued RWs
    case {'20230618'}
        for i = 1:obj.NumTrials

            if strcmp(obj.Outcome(i), 'Bug')
                continue;
            end

            iStates = SessionData.RawEvents.Trial{i}.States;
            iEvents = SessionData.RawEvents.Trial{i}.Events;

            obj.InitPokeInTime{i} = iEvents.Port3In(iEvents.Port3In>=iStates.Wait4Sample(1) & iEvents.Port3In<=iStates.Wait4Center(2));
            obj.InitPokeOutTime{i} = iEvents.Port3Out(iEvents.Port3Out>=iStates.Wait4Sample(1) & iEvents.Port3Out<=iStates.Wait4Center(2));

            if isfield(iStates, 'Wait4Out')
                obj.CentPokeInTime{i} = [iStates.FP(:, 1); iStates.Wait4Out(2:end, 1); iStates.Late(2:end, 1)];
            else
                obj.CentPokeInTime{i} = iStates.FP(:, 1);
            end

            obj.PortCorrect(i) = SessionData.Custom.CorPort(i);

            if ~isnan(iStates.Premature(1)) % Premature
                obj.Outcome(i) = 'Premature';
                obj.CentPokeOutTime{i} = iStates.FP(:, 2);
                obj.ChoiceCueTime(i, :) = [iStates.FP(1) iStates.Premature(1)];
                obj.TriggerCueTime(i) = nan;
                obj.ChoicePokeTime(i) = nan;
                obj.PortChosen(i) = nan;

                if iStates.FP(end, 2) - iStates.FP(1, 1) > obj.FP(i)
                    obj.Outcome(i) = 'Bug';
                end
            elseif ~isnan(iStates.Late(1)) % Late
                obj.Outcome(i) = "Late";
                if isfield(iStates, 'Wait4Out')
                    obj.CentPokeOutTime{i} = [iStates.FP(1:end-1, 2); iStates.Wait4Out(1:end-1, 2); iStates.Late(:, 2)];
                else
                    obj.CentPokeOutTime{i} = [iStates.FP(1:end-1, 2); iStates.Late(2)];
                end
                obj.ChoiceCueTime(i, :) = [iStates.FP(1) iStates.Late(end, 2)];
                if ~obj.Cued(i)
                    obj.TriggerCueTime(i) = nan;
                else
                    obj.TriggerCueTime(i) = iStates.FP(end, 2);
                end

                if ~any(isfield(iStates, ["LateWrong", "LateCorrect"]))
                    obj.ChoicePokeTime(i) = nan;
                    % figure out the port situation: WrongPort(1)
                    % should match a port entry time
                    obj.PortChosen(i) = nan;
                elseif ~isnan(iStates.LateWrong(1))
                    obj.LateChoice(i) = 'Wrong';
                    obj.ChoicePokeTime(i) = iStates.LateWrong(1);
                    % figure out the port situation: WrongPort(1)
                    % should match a port entry time
                    if isfield(iEvents, 'Port2In') && sum(ismember(iEvents.Port2In, iStates.LateWrong(1)))
                        obj.PortChosen(i) = 2;
                    elseif  isfield(iEvents, 'Port1In') && sum(ismember(iEvents.Port1In, iStates.LateWrong(1)))
                        obj.PortChosen(i) = 1;
                    else % sometimes, they poke during the choice light presentation
                        obj.PortChosen(i) = nan;
                    end
                elseif ~isnan(iStates.LateCorrect(1))
                    obj.LateChoice(i) = 'Correct';
                    obj.ChoicePokeTime(i) = iStates.LateCorrect(1);
                    % figure out the port situation: WrongPort(1)
                    % should match a port entry time
                    if isfield(iEvents, 'Port2In') && sum(ismember(iEvents.Port2In, iStates.LateCorrect(1)))
                        obj.PortChosen(i) = 2;
                    elseif  isfield(iEvents, 'Port1In') && sum(ismember(iEvents.Port1In, iStates.LateCorrect(1)))
                        obj.PortChosen(i) = nan;
                    else % sometimes, they poke during the choice light presentation
                        obj.PortChosen(i) = nan;
                    end
                else
                    obj.LateChoice(i) = 'Miss';
                    obj.ChoicePokeTime(i) = nan;
                    % figure out the port situation: WrongPort(1)
                    % should match a port entry time
                    obj.PortChosen(i) = nan;
                end

            elseif ~isnan(iStates.WrongPort(1)) % selected the wrong port
                obj.Outcome(i) = 'Wrong';
                if isfield(iStates, 'Wait4Out')
                    if ~isnan(iStates.Wait4Out(1, 2))
                        obj.CentPokeOutTime{i} = [iStates.FP(1:end-1, 2); iStates.Wait4Out(:, 2)];
                    else
                        obj.CentPokeOutTime{i} = [iStates.FP(1:end-1, 2); iStates.ChoiceCue(2)];
                    end
                else
                    obj.CentPokeOutTime{i} = [iStates.FP(1:end-1, 2); iStates.Wait4Choice(1)];
                end

                obj.ChoiceCueTime(i, :) = [iStates.FP(1) iStates.Wait4Choice(2)]; % duration that the choice light lit up.
                if ~obj.Cued(i)
                    obj.TriggerCueTime(i) = iStates.Wait4Choice(1);
                else
                    obj.TriggerCueTime(i) = iStates.FP(end, 2);
                end
                obj.ChoicePokeTime(i) = iStates.Wait4Choice(2);
                % figure out the port situation: WrongPort(1)
                % should match a port entry time
                if isfield(iEvents, 'Port2In') && sum(ismember(iEvents.Port2In, iStates.WrongPort(1)))
                    obj.PortChosen(i) = 2;
                elseif  isfield(iEvents, 'Port1In') && sum(ismember(iEvents.Port1In, iStates.WrongPort(1)))
                    obj.PortChosen(i) = 1;
                else % sometimes, they poke during the choice light presentation
                    obj.PortChosen(i) = nan;
                end
            elseif ~isnan(iStates.Wait4Reward(1))
                obj.Outcome(i) = 'Correct';
                if isfield(iStates, 'Wait4Out')
                    if ~isnan(iStates.Wait4Out(1, 2))
                        obj.CentPokeOutTime{i} = [iStates.FP(1:end-1, 2); iStates.Wait4Out(:, 2)];
                    else
                        obj.CentPokeOutTime{i} = [iStates.FP(1:end-1, 2); iStates.ChoiceCue(2)];
                    end
                else
                    obj.CentPokeOutTime{i} = [iStates.FP(1:end-1, 2); iStates.Wait4Choice(1)];
                end
                obj.ChoiceCueTime(i, :) = [iStates.FP(1) iStates.Wait4Choice(2)]; % duration that the choice light lit up.
                if ~obj.Cued(i)
                    obj.TriggerCueTime(i) = iStates.Wait4Choice(1);
                else
                    obj.TriggerCueTime(i) = iStates.FP(end, 2);
                end
                obj.ChoicePokeTime(i) = iStates.Wait4Choice(2);
                % find out the port
                if isfield(iEvents, 'Port2In') && sum(ismember(iEvents.Port2In, iStates.Wait4Reward(1)))
                    obj.PortChosen(i) = 2;
                elseif  isfield(iEvents, 'Port1In') && sum(ismember(iEvents.Port1In, iStates.Wait4Reward(1)))
                    obj.PortChosen(i) = 1;
                else % sometimes, they poke during the choice light presentation
                    obj.PortChosen(i) = nan;
                end
            else
                obj.Outcome(i) = 'Bug';
            end
        end
end

obj.FP = roundn(obj.FP, -1);
obj.TargetFP = unique(obj.FP);
if length(obj.TargetFP) > 1
    fprintf("\nMore than 1 foreperiod (FP) have been found: \n");
    disp(obj.TargetFP);
    obj.TargetFP = mode(obj.FP);
    fprintf("Take the mode number: %f\n", obj.TargetFP);
end

%% remove bug trials
ind_bug = strcmp(obj.Outcome, 'Bug') | obj.FP <= 0;

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

end