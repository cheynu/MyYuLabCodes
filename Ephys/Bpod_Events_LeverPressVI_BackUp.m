function events = Bpod_Events_LeverPressVI_BackUp(sd, vb)
% 12/1/2025
% revised for leverpress variable interval task
% 2/20/2021
% extract events from bpod's SessionData structure
% MedLick Recording
% 10/4/2022 add AllPokeIns and AllPokesOuts. 

arguments
    sd
    vb = []
end
if ~isempty(vb) && isfield(vb,'isExtinction')
    isExtinction = vb.isExtinction;
else
    isExtinction = false;
end

Ntrials = sd.nTrials;
% 
%          WaitForPress: [0 0.1342]
%         WaitForMedTTL: [0.1342 4.1342]
%                  Late: [4.1342 5.1342]
%          BadPortEntry: [NaN NaN]
%     WaitForMedTTLStim: [NaN NaN]
%          InvalidEntry: [NaN NaN]
%             BriefExit: [NaN NaN]
%        WaitForPokedIn: [NaN NaN]
%        RewardDelivery: [NaN NaN]
%              Drinking: [NaN NaN]
%         DrinkingGrace: [NaN NaN]
%       WaitForPortExit: [NaN NaN]
 
    
all_events = fieldnames(sd.RawEvents.Trial{1}.States);

events.GoodWait = [];
events.GoodPress = [];      % used in leverpressVI task
events.GoodRelease = [];    % time of a successful lever release
events.GoodPokeIn = [];      % time of port poke after a succesful lever release (reward delivered immediately)
events.Reward = [];             % two-row matrix, first row valve open, second row valve close

events.AllPokeIns = [];
events.AllPokeOuts = [];
events.AllPress = [];
events.AllPressTypeVI = []; % 1: rewarded press, -1: presses before rewarded press (during VI) each trial, 0: other presses

events.BadWait = [];
events.BadPress = [];
events.BadPokeIn = [];
events.BadPokeOut = [];
events.BadPokeInFirst = [];
events.BadPokeOutFirst = [];

t0 = sd.TrialStartTimestamp(1);

for k =1:Ntrials
    t_trial = sd.TrialStartTimestamp(k); % in seconds

    if isfield(sd.RawEvents.Trial{k}.Events, 'AnalogIn1_1')
        pressInTrial = sd.RawEvents.Trial{k}.Events.AnalogIn1_1;
        if k==1
            pressInTrial = pressInTrial(pressInTrial>0.01);
        end
        allPress = t_trial + pressInTrial;
        events.AllPress = [events.AllPress allPress];
    end

    if isfield(sd.RawEvents.Trial{k}.Events, 'Port1In')
        allPokeIns = t_trial+sd.RawEvents.Trial{k}.Events.Port1In;
        events.AllPokeIns = [events.AllPokeIns allPokeIns];
    end

    if isfield(sd.RawEvents.Trial{k}.Events, 'Port1Out')
        allPokeOuts = t_trial+sd.RawEvents.Trial{k}.Events.Port1Out;
        allPokeOutsAlign = [];
        for i=1:length(allPokeIns)
            thisPokeIn = allPokeIns(i);
            if i~=length(allPokeIns)
                nextPokeIn = allPokeIns(i+1);
                thisPokeOut = allPokeOuts(allPokeOuts>thisPokeIn & allPokeOuts<nextPokeIn);
            else
                thisPokeOut = allPokeOuts(allPokeOuts>thisPokeIn);
            end
            if ~isempty(thisPokeOut)
                thisPokeOut = thisPokeOut(1);
            elseif i==length(allPokeIns)
                thisPokeOut = [];
                allPokeIns(end) = [];
                events.AllPokeIns(end) = [];
            else
                error('No matched PokeOut found');
            end
            allPokeOutsAlign = [allPokeOutsAlign thisPokeOut];
        end
        events.AllPokeOuts = [events.AllPokeOuts allPokeOutsAlign];
    end

    if ~isExtinction && ~isnan(sd.RawEvents.Trial{k}.States.RewardDelivery(1))  % Good Poke & reward time
        % % events.GoodRelease = [events.GoodRelease t_trial+sd.RawEvents.Trial{k}.States.WaitForMedTTL(end)];
        goodPokeIn = t_trial+sd.RawEvents.Trial{k}.States.RewardDelivery(1);
        events.GoodPokeIn = [events.GoodPokeIn goodPokeIn];
        events.Reward = [events.Reward t_trial+sd.RawEvents.Trial{k}.States.RewardDelivery'];
        % events.GoodWait = [events.GoodWait t_trial+sd.RawEvents.Trial{k}.States.WaitForMedTTL'];
        % events.GoodWait = [events.GoodWait nan(2,1)];
    end
    
    % if   isnan(sd.RawEvents.Trial{k}.States.RewardDelivery(1))
    %     press_time = t_trial+sd.RawEvents.Trial{k}.States.WaitForMedTTL(1);
    %     events.BadPress = [events.BadPress press_time];
    % end;

    if ~isExtinction && ~isnan(sd.RawEvents.Trial{k}.States.RewardedPress(1))
        goodPress = t_trial+sd.RawEvents.Trial{k}.States.RewardedPress(1);
        events.GoodPress = [events.GoodPress goodPress];
    end

    if ~isExtinction
        % events.BadPress = setdiff(allPress, goodPress);
        events.BadPress = [events.BadPress allPress(allPress<goodPress)]; % press happened in VI (excluding the press after rewarded press)
    else
        events.BadPress = [events.BadPress allPress];
    end

    if ~isExtinction
        % badpokes = sd.RawEvents.Trial{k}.States.InvalidEntry; % bad poke entries of current trial
        badPokesIn = allPokeIns(allPokeIns<goodPokeIn);
        badPokesOut = allPokeOutsAlign(allPokeIns<goodPokeIn);
    else
        badPokesIn = allPokeIns;
        badPokesOut = allPokeOutsAlign;
    end
    events.BadPokeIn = [events.BadPokeIn badPokesIn];
    events.BadPokeOut = [events.BadPokeOut badPokesOut];
    % events.BadWait = [events.BadWait t_trial+sd.RawEvents.Trial{k}.States.WaitForMedTTL'];
    % events.BadWait = [events.BadWait nan(2,1)];

end

% relative timing with respect to the first trial
% events.GoodWait              = events.GoodWait-t0;
% events.BadWait              = events.BadWait-t0;
if ~isExtinction % if not, they're empty
    events.GoodPress        = events.GoodPress-t0;
    events.GoodRelease      = events.GoodRelease-t0;
    events.GoodPokeIn       = events.GoodPokeIn-t0;
    events.Reward           = events.Reward-t0;
end
events.BadPokeIn        = events.BadPokeIn -t0;
events.BadPokeOut       = events.BadPokeOut - t0;
events.BadPress         = events.BadPress -t0;
events.AllPokeIns       = events.AllPokeIns - t0;
events.AllPokeOuts      = events.AllPokeOuts - t0;
events.AllPress         = events.AllPress - t0;

allPressTypeVI = zeros(size(events.AllPress));
idxGood = ismember(events.AllPress, events.GoodPress);
idxBad = ismember(events.AllPress, events.BadPress);
allPressTypeVI(idxGood) = 1;
allPressTypeVI(idxBad) = -1;
events.AllPressTypeVI = allPressTypeVI;

% figure;
% plot(events.GoodRelease,1, 'go'); hold on
% plot(events.GoodPokeIn, 2, 'b*')
% plot(events.BadPokeIn, 3, 'r*')
% plot(events.BadPress, 3, 'k^')
% line([events.AllPokeIns; events.AllPokeIns], [0 4], 'color', 'b')
% set(gca, 'ylim', [0 4])
% xlabel('sec')


% extract the first poke after each bad release
bad_pokein=[];
bad_pokeout=[];
for i=1:length(events.BadPress)
    t_badpress = events.BadPress(i);
    t_pressnext = events.AllPress(find(events.AllPress>t_badpress, 1, 'first'));

    t_badpoke       = events.BadPokeIn(find(events.BadPokeIn>t_badpress, 1, 'first'));
    t_badpokeout    = events.BadPokeOut(find(events.BadPokeIn>t_badpress, 1, 'first'));
    
    if isempty(t_pressnext)
        bad_pokein=[bad_pokein t_badpoke];
        bad_pokeout=[bad_pokeout t_badpokeout];
    elseif t_badpoke < t_pressnext
        bad_pokein=[bad_pokein t_badpoke];
        bad_pokeout=[bad_pokeout t_badpokeout];
    end 
end
events.BadPokeInFirst = bad_pokein;
events.BadPokeOutFirst = bad_pokeout;

% plot(events.BadPokeInFirst, 3, 'ro')
    
end