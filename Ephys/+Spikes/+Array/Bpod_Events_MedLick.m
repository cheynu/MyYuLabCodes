function events = Bpod_Events_MedLick(sd);
% 2/20/2021
% extract events from bpod's SessionData structure
% MedLick Recording
% 10/4/2022 add AllPokeIns and AllPokesOuts. 

% 7/7/2023
% for MedLick, simply get the poke time and reward time

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
 
    
events.SessionStartTime = sd.Info.SessionStartTime_UTC;
events.RewardAmount = median(arrayfun(@(x)x.GUI.RewardAmount, sd.TrialSettings));

events.GoodRelease = [];    % time of a successful lever release
events.GoodPokeIn = [];      % time of port poke after a succesful lever release (reward delivered immediately)
events.Reward = [];             % two-row matrix, first row valve open, second row valve close

events.AllPokeIns = [];
events.AllPokeOuts = [];

t0 = sd.TrialStartTimestamp(1);

for k =1:Ntrials
    t_trial = sd.TrialStartTimestamp(k); % in seconds
    if isfield(sd.RawEvents.Trial{k}.Events, 'Port1In')
        events.AllPokeIns = [events.AllPokeIns t_trial+sd.RawEvents.Trial{k}.Events.Port1In];
    end
    if isfield(sd.RawEvents.Trial{k}.Events, 'Port1Out')
        events.AllPokeOuts = [events.AllPokeOuts t_trial+sd.RawEvents.Trial{k}.Events.Port1Out];
    end
    % good release (MEDTTL) is signaled by BNC1High
    if isfield(sd.RawEvents.Trial{k}.Events, 'BNC1High')
        events.GoodRelease = [events.GoodRelease t_trial+sd.RawEvents.Trial{k}.States.WaitForMedTTL(end)];
        events.GoodPokeIn = [events.GoodPokeIn t_trial+sd.RawEvents.Trial{k}.States.WaitForRewardEntry(2)];
        events.Reward = [events.Reward t_trial+sd.RawEvents.Trial{k}.States.RewardDelivery'];
    end
    % MedLick doesn't have press signals so the followings cannot be
    % derived. 

    %     if   isnan(sd.RawEvents.Trial{k}.States.WaitForPokedIn(1))
    %         press_time = t_trial+sd.RawEvents.Trial{k}.States.WaitForMedTTL(1);
    %         events.BadPress = [events.BadPress press_time];
    %     end;
    %
    %     % poke following a bad press
    %     if k>1 && isnan(sd.RawEvents.Trial{k-1}.States.WaitForPokedIn(1))
    %         badpokes = sd.RawEvents.Trial{k}.States.BadPortEntry; % bad poke entries of current trial
    %         ind_prepress = find(badpokes(:, 1)< sd.RawEvents.Trial{k}.States.WaitForMedTTL(1));
    %          if ~isempty(ind_prepress)
    %             badpokes = badpokes(ind_prepress, :);
    %             events.BadPokeIn =      [events.BadPokeIn; t_trial+badpokes(:, 1)];
    %             events.BadPokeOut =    [events.BadPokeOut; t_trial+badpokes(:, 2)];
    %         end;
    %     end;
end

events.Reward                       =                 events.Reward-t0;
events.AllPokeIns                  =                 events.AllPokeIns - t0;
events.AllPokeOuts               =                 events.AllPokeOuts - t0;
events.GoodRelease             =                events.GoodRelease - t0;
events.AllPress                      =                 [];
events.BadPokeInFirst           =                 [];
events.BadPokeOutFirst        =                 [];