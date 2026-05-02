function tevents = GetEventTimesKornblum(r)
% Jianing Yu
% 4/17/2021  get time of some critical events. 
% 10/22/2022 revised to meet Kornblum requirements

% we now have the following useful information:
% tevents.press_correct                  =            {t_correctpresses_cue, t_correctpresses_uncue};
% tevents.rt                                       =           {rt_correct_cue_sorted, rt_correct_uncue_sorted};
% tevents.press_premature             =            {t_prematurepresses_cue, t_prematurepresses_uncue};
% tevents.press_late                        =           {t_latepresses_cue, t_latepresses_uncue};
% 
% tevents.release_correct               =            {t_correctreleases_cue, t_correctreleases_uncue};
% tevents.release_premature          =            {t_prematurereleases_cue, t_prematurereleases_uncue};
% tevents.release_late                     =            {t_latereleases_cue, t_latereleases_uncue};
% 
% tevents.trigger                              =            t_triggers;
% tevents.trigger_correct                 =            t_triggers_correct;
% tevents.trigger_late                       =           t_triggers_late;
% 
% tevents.pokein                              =           t_portin;
% tevents.rewards                            =           t_rewards;

rb = r.Behavior;
% index of Cued and Uncued trials
ind_cue = find(rb.CueIndex(:, 2) == 1);
ind_uncue = find(rb.CueIndex(:, 2) == 0);
ind_press = find(strcmp(rb.Labels, 'LeverPress'));
t_presses = rb.EventTimings(rb.EventMarkers == ind_press);

% press for cue and uncue trials
t_presses_cue           =       t_presses(ind_cue);
t_presses_uncue       =       t_presses(ind_uncue);
t_presses_dark         =        t_presses(isnan(rb.CueIndex(:, 2)));

sprintf('There are %2.0f cued trials', length(t_presses_cue))
sprintf('There are %2.0f uncued trials', length(t_presses_uncue))
 
figure(8); clf
ha = axes('nextplot', 'add', 'xlim', [0.5 3.5], 'xtick', [1:3], 'xticklabel', {'Cued', 'Uncued', 'Dark'});
bar(1, length(t_presses_cue), 'FaceColor', 'k')
bar(2, length(t_presses_uncue), 'FaceColor', 'b')
bar(3, length(t_presses_dark), 'FaceColor', [0.7 0.7 0.7])
 ylabel('Number of presses')

% release
ind_release= find(strcmp(rb.Labels, 'LeverRelease'));
t_releases = rb.EventTimings(rb.EventMarkers == ind_release);
 % press for cue and uncue trials
t_release_cue           =       t_releases(ind_cue);
t_release_uncue       =       t_releases(ind_uncue);
t_release_dark         =        t_releases(isnan(rb.CueIndex(:, 2)));

% time of all reward delievery
ind_rewards = find(strcmp(rb.Labels, 'ValveOnset'));
t_rewards= rb.EventTimings(rb.EventMarkers == ind_rewards);
t_rewards_cue = [];
t_rewards_uncue = [];

% check which reward is produced by cue vs uncue trials
for i =1:length(t_rewards)
    most_recent_cue = t_release_cue(find(t_release_cue-t_rewards(i)<0, 1, 'last'));
    most_recent_uncue = t_release_uncue(find(t_release_uncue-t_rewards(i)<0, 1, 'last'));
    if ~isempty(most_recent_cue) && ~isempty(most_recent_uncue)
        if most_recent_cue > most_recent_uncue
            t_rewards_cue = [t_rewards_cue t_rewards(i)];
        else
            t_rewards_uncue = [t_rewards_uncue t_rewards(i)];
        end;
    end;
end;

% index and time of correct presses
t_correctpresses = t_presses(rb.CorrectIndex);
FPs_correctpresses = rb.Foreperiods(rb.CorrectIndex);
FP_Kornblum = median(rb.Foreperiods); % This is the foreperiod of this session

[t_correctpresses_cue, ind_correct_cue]             =       intersect(t_correctpresses, t_presses_cue);
[t_correctpresses_uncue, ind_correct_uncue]     =       intersect(t_correctpresses, t_presses_uncue);

% index and time of correct releases
t_correctreleases                   =       t_releases(rb.CorrectIndex); 
t_correctreleases_cue           =       t_correctreleases(ind_correct_cue);
t_correctreleases_uncue       =       t_correctreleases(ind_correct_uncue);

% reaction time of correct responses
rt_correct                  =        t_correctreleases - t_correctpresses - FPs_correctpresses;
rt_correct_cue          =        rt_correct(ind_correct_cue);
rt_correct_uncue      =        rt_correct(ind_correct_uncue);

% sorting index
[rt_correct_cue_sorted, sortindex_cue] = sort(rt_correct_cue);
[rt_correct_uncue_sorted, sortindex_uncue] = sort(rt_correct_uncue);

t_correctpresses_cue = t_correctpresses_cue(sortindex_cue);
t_correctpresses_uncue = t_correctpresses_uncue(sortindex_uncue);

t_correctreleases_cue = t_correctreleases_cue(sortindex_cue);
t_correctreleases_uncue = t_correctreleases_uncue(sortindex_uncue);

% time of all triggers
ind_triggers = find(strcmp(rb.Labels, 'Trigger'));
t_triggers = rb.EventTimings(rb.EventMarkers == ind_triggers);

t_triggers_correct = [];
ind_goodtriggers = [];
t_triggers_late = [];
ind_badtriggers = [];
 
dt=[];
for i = 1:length(t_triggers)    
    it_trigger = t_triggers(i);
    [it_release, ~] = min(abs(t_correctreleases-it_trigger));
    if it_release<2000
        % trigger followed by successful release
        t_triggers_correct = [t_triggers_correct; it_trigger];
        ind_goodtriggers = [ ind_goodtriggers i];
    else
        % trigger followed by late release
        t_triggers_late = [t_triggers_late; it_trigger];
        ind_badtriggers = [ind_badtriggers i];
    end;
end; 
  
% port access, t_portin and t_portout
ind_portin = find(strcmp(rb.Labels, 'PokeOnset'));
t_portin = rb.EventTimings(rb.EventMarkers == ind_portin);

tpoke_reward = t_portin;
movetime = zeros(1, length(t_rewards));
for i =1:length(t_rewards)
    dt = t_rewards(i)-t_correctreleases;
    dt = dt(dt>0);
    if ~isempty(dt)
        movetime(i) = dt(end);
    end;
end;
 
% only take positive move times
ind_movetimepos = find(movetime>0);
t_rewards = t_rewards(ind_movetimepos);
movetime = movetime(ind_movetimepos);

[t_rewards_cue, ind_reward_cue] = intersect(t_rewards, t_rewards_cue);
[t_rewards_uncue, ind_reward_uncue] = intersect(t_rewards, t_rewards_uncue);

movetime_cue = movetime(ind_reward_cue);
movetime_uncue = movetime(ind_reward_uncue);

[~, indmovesort_cue]            =    sort(movetime_cue);
[~, indmovesort_uncue]        =    sort(movetime_uncue);
                            
% sorted. 
t_rewards_cue                     =        t_rewards_cue(indmovesort_cue);
t_rewards_uncue                 =        t_rewards_uncue(indmovesort_uncue);

% time of premature presses
t_prematurepresses_cue = t_presses(intersect(rb.PrematureIndex, ind_cue));
t_prematurepresses_uncue = t_presses(intersect(rb.PrematureIndex, ind_uncue));
t_prematurereleases_cue = t_releases(intersect(rb.PrematureIndex, ind_cue));
t_prematurereleases_uncue = t_releases(intersect(rb.PrematureIndex, ind_uncue));                                             

pressdur_premature_cue              =    t_prematurereleases_cue - t_prematurepresses_cue;
pressdur_premature_uncue          =    t_prematurereleases_uncue - t_prematurepresses_uncue;

[~, ind_premature_cue] = sort(pressdur_premature_cue);
t_prematurepresses_cue = t_prematurepresses_cue(ind_premature_cue);
t_prematurereleases_cue = t_prematurereleases_cue(ind_premature_cue);

[~, ind_premature_uncue] = sort(pressdur_premature_uncue);
t_prematurepresses_uncue = t_prematurepresses_uncue(ind_premature_uncue);
t_prematurereleases_uncue = t_prematurereleases_uncue(ind_premature_uncue);

% time of late presses
t_latepresses_cue = t_presses(intersect(rb.LateIndex, ind_cue));
t_latepresses_uncue = t_presses(intersect(rb.LateIndex, ind_uncue));

t_latereleases_cue = t_releases(intersect(rb.LateIndex, ind_cue));
t_latereleases_uncue = t_releases(intersect(rb.LateIndex, ind_uncue));

pressdur_late_cue              =    t_latereleases_cue - t_latepresses_cue;
pressdur_late_uncue          =    t_latereleases_uncue - t_latepresses_uncue;

[~, ind_late_cue] = sort(pressdur_late_cue);

t_latepresses_cue = t_latepresses_cue(ind_late_cue);
t_latereleases_cue = t_latereleases_cue(ind_late_cue);

[~, ind_late_uncue] = sort(pressdur_late_uncue);
t_latepresses_uncue = t_latepresses_uncue(ind_late_uncue);
t_latereleases_uncue = t_latereleases_uncue(ind_late_uncue);

tevents.press_correct                  =            {t_correctpresses_cue, t_correctpresses_uncue};
tevents.rt                                       =           {rt_correct_cue_sorted, rt_correct_uncue_sorted};
tevents.press_premature             =            {t_prematurepresses_cue, t_prematurepresses_uncue};
tevents.press_late                        =           {t_latepresses_cue, t_latepresses_uncue};

tevents.release_correct               =            {t_correctreleases_cue, t_correctreleases_uncue};
tevents.release_premature          =            {t_prematurereleases_cue, t_prematurereleases_uncue};
tevents.release_late                     =            {t_latereleases_cue, t_latereleases_uncue};

tevents.trigger                              =            t_triggers;
tevents.trigger_correct                 =            t_triggers_correct;
tevents.trigger_late                       =           t_triggers_late;

tevents.pokein                              =           t_portin;
tevents.rewards                            =           t_rewards;