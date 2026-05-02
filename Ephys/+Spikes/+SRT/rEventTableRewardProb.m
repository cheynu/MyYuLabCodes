function [event_table, t_portin] = rEventTableRewardProb(r)
% JY 2025/08/21
% Easy extraction of behavioral variables for physiology.
% 2025/12/18 adapted for reward probability protocol. 


rb                                       =       r.Behavior;
%% Presses
ind_press                                 =       find(strcmp(rb.Labels, 'LeverPress'));
t_presses                                 =       Spikes.SRT.shape_it(rb.EventTimings(rb.EventMarkers == ind_press));
disp(['Number of presses is ' num2str(length(t_presses))])

%% Release
ind_release                              =        find(strcmp(rb.Labels, 'LeverRelease'));
t_releases                               =        Spikes.SRT.shape_it(rb.EventTimings(rb.EventMarkers == ind_release));

%% Trigger
ind_triggers = find(strcmp(rb.Labels, 'Trigger'));
t_triggers = Spikes.SRT.shape_it(rb.EventTimings(rb.EventMarkers == ind_triggers)); % trigger time in ms.

%% Poke
ind_portin = find(strcmp(rb.Labels, 'PokeOnset'));
t_portin = Spikes.SRT.shape_it(rb.EventTimings(rb.EventMarkers == ind_portin));
t_behavior_MED = r.BehaviorClass.PressTime; % to ms

%% Valve
ind_valve = find(strcmp(rb.Labels, 'ValveOnset'));
t_valve = Spikes.SRT.shape_it(rb.EventTimings(rb.EventMarkers == ind_valve));

if isempty(t_portin)
    t_portin = t_valve;
end
% find out matches
ind_press_match = findseqmatchrev(t_behavior_MED, t_presses/1000, 0, 0, 0);
event_table = table();

for i =1:length(ind_press_match)

    this_session = [r.BehaviorClass.Subject '_' r.BehaviorClass.Date];

    t_press_ephys = t_presses(i);

    % corresponding event in MED
    ind_MED_matched = ind_press_match(i);

    if isnan(ind_MED_matched)
        continue
    end

    if isprop(r.BehaviorClass, 'Cue')
        iCue                = r.BehaviorClass.Cue(ind_MED_matched);
    else
        iCue                = ones(length(r.BehaviorClass.Stage), 1);
    end

    iStage              = r.BehaviorClass.Stage(ind_MED_matched);

    if iStage == 0
        type = 'WarmUp';
    else
        if isnan(iCue)
            type = 'Dark';
        elseif iCue == 1
            type = 'Normal';
        elseif iCue == 0
            type = 'Probe';
        end
    end

    t_press_MED         = r.BehaviorClass.PressTime(ind_MED_matched);
    t_release_MED       = r.BehaviorClass.ReleaseTime(ind_MED_matched);
    hold_duration_MED   = t_release_MED-t_press_MED;
    t_trigger_MED       = r.BehaviorClass.ToneTime(ind_MED_matched);
    outcome_MED         = r.BehaviorClass.Outcome{ind_MED_matched};
    
    if ~isempty(r.BehaviorClass.FP)
        thisFP              = r.BehaviorClass.FP(ind_MED_matched);
    elseif r.BehaviorClass.ToneTime(ind_MED_matched)>0
        thisFP              = 1000*(r.BehaviorClass.ToneTime(ind_MED_matched)-r.BehaviorClass.PressTime(ind_MED_matched));
    else
        thisFP = NaN;
    end
    
    RT_MED              = r.BehaviorClass.ReactionTime(ind_MED_matched);

    t_release_ephys     = t_releases(find(t_releases>t_press_ephys, 1, 'first'));
    if isempty(t_release_ephys)
        continue
    end

    hold_duration_ephys = t_release_ephys-t_press_ephys;

    if abs(hold_duration_ephys-hold_duration_MED*1000)>20
        continue
    end

    if t_trigger_MED>0 && any(strcmp(outcome_MED, {'Correct', 'Late'}))
        t_trigger_ephys     = t_triggers(find(t_triggers>t_press_ephys, 1, 'first'));
        if isempty(t_trigger_ephys)
            t_trigger_ephys = NaN;
        end
        rt_ephys            = t_release_ephys-t_trigger_ephys;
    else
        t_trigger_ephys = NaN;
        rt_ephys = NaN;
    end
   
    t_poke_ephys =[];
    t_valve_ephys = [];

    this_outcome = 'NaN';
    if strcmp(outcome_MED, 'Correct')        
        t_poke_ephys = t_portin(find(t_portin>t_release_ephys, 1, 'first'));
        t_valve_ephys = t_valve(find(t_valve>t_release_ephys, 1, 'first'));
        
        % this is the time of next press
        t_next_press  = t_presses(find(t_presses>t_release_ephys, 1, 'first'));

        if abs(t_poke_ephys-t_valve_ephys)<10
            this_outcome = 'Rewarded';
        elseif isempty(t_valve_ephys) || (~isempty(t_valve_ephys) && t_valve_ephys>t_next_press)
            this_outcome = 'Omitted';
        else
            this_outcome = 'Unclear';
        end

    else % Try looking for port nose-poke locked to incorrect response
        t_poke_ephys = t_portin(find(t_portin>t_release_ephys, 1, 'first'));        
        % this is the time of next press
        t_next_press  = t_presses(find(t_presses>t_release_ephys, 1, 'first'));

        if ~isempty(t_poke_ephys) && t_poke_ephys>t_next_press
            t_poke_ephys = NaN;
        end
    end

    if isempty(t_poke_ephys)
        t_poke_ephys = NaN;
    end

    if isempty(t_valve_ephys)
        t_valve_ephys = NaN;
    end

    this_row = table({this_session}, i, ind_MED_matched, {type}, t_press_ephys, t_trigger_ephys, t_release_ephys,...
        t_poke_ephys, t_valve_ephys, thisFP, rt_ephys, {outcome_MED}, {this_outcome}, 'VariableNames',{ ...
        'anm_session', 'press_index', 'MED_index', 'type', 't_press', 't_trigger', 't_release', ...
        't_poke', 't_valve', 'FP', 'rt', 'outcome', 'reward'});

    event_table = [event_table; this_row];
  
end

n_rows = height(event_table);
reward_prob = NaN(n_rows, 1);
reward_level = repmat({'NaN'}, n_rows, 1);
n_block = 5;
th = 0.5;
for i =1:n_rows
    if i>1
        rew_history = event_table.reward(strcmp(event_table.outcome(1:i-1), 'Correct'));
        if length(rew_history) >= n_block
            rew_history = rew_history(end-n_block+1:end);
            rew_prob_hat = sum(strcmp(rew_history, 'Rewarded'))/n_block;
            reward_prob(i) = rew_prob_hat;
            if rew_prob_hat>th
                reward_level{i} = 'High';
            else
                reward_level{i} = 'Low';
            end
        end
    end
end

if any(isnan(event_table.FP)) % in some old version of MED, FP was not recorded in MED but can be computed. 
    inds = find(isnan(event_table.FP));
    for i =1:length(inds)
        i_inds = inds(i);
        if any(find(~isnan(event_table.FP(1:i_inds)), 1, 'last')) 
            event_table.FP(i_inds) = event_table.FP(find(~isnan(event_table.FP(1:i_inds)), 1, 'last'));
        elseif any(find(~isnan(event_table.FP(i_inds+1:end)), 1, 'first')) 
            event_table.FP(i_inds) = event_table.FP(find(~isnan(event_table.FP(i_inds+1:end)), 1, 'first'));
        end
    end
end

event_table.reward_probability  = reward_prob;
event_table.reward_level        = reward_level;