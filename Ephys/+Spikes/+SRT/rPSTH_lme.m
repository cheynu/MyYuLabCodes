function [stat_out, stat_table] = rPSTH_lme(s)
% Jianing Yu 8/14/2025
% s is the output from rPSTHWarped.m
% s =
% struct with fields:
% eventSequenceLabels: {'press'  'trigger'  'release'  'poke'}
% eventSequence: {[33×4 double]  [20×4 double]}
% explained: 'These are press-related spike trains and sdfs, each cell is a FP'
% press: {{1×33 cell}  {1×20 cell}}
% trigger: {{1×33 cell}  {1×20 cell}}

bin_size.press = [-500 500]; % in ms. compare spike count before and after press, 500 ms window
bin_size.trigger = [-500 500]; % in ms, compare spike count before and after trigger, 500 ms window
bin_size.poke = [-500 2000]; % in ms, compare spike count before and after poke, 500 ms window

% Step 1: Extract spike count in these time windows
% this_sdf.raster
stat_out.cell_id = s.unit.index; 

nFP = length(s.raster.press);
FPs = s.FPs;
spk_count_tab = table;
segments = {'press', 'trigger'};
behavior_events = {'press', 'trigger', 'poke'};
trial_index = 0;
for i =1:nFP

    n_sequence = size(s.raster.eventSequence{i}, 1);
    spk_times = s.raster.press{i};
    FP = FPs(i);

    for k =1:n_sequence
        event_time = s.raster.eventSequence{i}(k, :);
        event_time = event_time-event_time(1);
        rt = event_time(3) - event_time(2); % ms, release - trigger
        mt = event_time(4) - event_time(3); % ms, poke - release
        event_time(3)= [];
        spk_time = spk_times{k};

        spk_count = zeros(length(event_time), 2); % 2 means pre and post
        trial_index = trial_index +1;
        for j =1:length(behavior_events)
            
            behavior_event = behavior_events{j};
            if strcmp(behavior_event,'trigger') % trigger range: [trigger-RT, trigger+RT]
                bin_size.(behavior_event) = [-rt, rt];
            elseif strcmp(behavior_event,'poke')
                bin_size.(behavior_event)(1) = -mt;
            end
            % pre event spk
            ind_pre = sum(spk_time>=event_time(j)+bin_size.(behavior_event)(1) & spk_time<event_time(j));
            spk_count_pre = ind_pre*1000/abs(bin_size.(behavior_event)(1));

            this_row = table(trial_index, {behavior_event},  {'Pre'}, FP, spk_count_pre,...
                'VariableNames',{'trial', 'event', 'time_point', 'FP', 'spike_rate'});
            spk_count_tab = [spk_count_tab; this_row];
      
            % post event spk
            ind_post = sum(spk_time>=event_time(j) & spk_time<event_time(j)+bin_size.(behavior_event)(2));
            spk_count_post = ind_post*1000/abs(bin_size.(behavior_event)(2));

            this_row = table(trial_index, {behavior_event}, {'Post'}, FP, spk_count_post, ...
                'VariableNames',{'trial', 'event', 'time_point', 'FP', 'spike_rate'});
            spk_count_tab = [spk_count_tab; this_row];
            

            if strcmp(behavior_event,"poke")
                fprintf("trial %d, poke_time = %.1f, spikes in window: pre=%d, post=%d\n", ...
                    trial_index, event_time(j), ind_pre, ind_post);
            end
        end
    end
end

tbl = spk_count_tab;

% Convert to categorical for factors
tbl.event = categorical(tbl.event, {'press', 'trigger', 'poke'});  % Set order to match reference
tbl.time_point = categorical(tbl.time_point, {'Pre', 'Post'});  % Set reference to 'Post' first

% Fit the linear mixed effects model
% Formula: spike_rate ~ event * time_point + (1 | trial)
lme = fitlme(tbl, 'spike_rate ~ event * time_point + (1 | trial)');

% Display the model summary
disp(lme);

stat_out.lme = lme;

% An example
% Fixed effects coefficients (95% CIs):
%     Name                                     Estimate    SE        tStat      DF 
%     {'(Intercept)'                  }         27.019     1.4005     19.292    312
%     {'event_trigger'                }         16.415     1.9806     8.2878    312
%     {'event_poke'                   }         -5.434     1.9806    -2.7436    312
%     {'time_point_Post'              }         16.528     1.9806      8.345    312
%     {'event_trigger:time_point_Post'}        -28.189      2.801    -10.064    312
%     {'event_poke:time_point_Post'   }        -21.509      2.801    -7.6791    312
% 
% 
%     pValue        Lower      Upper  
%     3.8585e-55     24.263     29.775
%     3.4636e-15     12.518     20.312
%      0.0064292     -9.331    -1.5369
%     2.3345e-15     12.631     20.425
%     8.1281e-21      -33.7    -22.677
%     2.0809e-13    -27.021    -15.998

% event_trigger is the effect of event time (from press to trigger, before
% sitmulus). 
% event_poke is the effect of event time (from press to poke, before
% sitmulus). 
% time_point_Post is the effect of post compared to pre, for press (which
% is the reference). 
% event_trigger:time_point_Post is the pre-post change for trigger compared
% to that for press, it is a bit complicated and shows differential
% modulation (not pre-post difference at trigger)
% event_poke:time_point_Post similar to above.

% Perform post hoc pairwise comparisons and adjust for multiple comparisons
% using Bonferroni

stat_out.pvals = [];

% Assuming tbl and lme are already created and fitted as in previous code
% Confirm coefficient order
disp(lme.CoefficientNames');

% Assuming order: {'(Intercept)'  'event_trigger'  'event_poke'  'time_point_Post'  'event_trigger:time_point_Post'  'event_poke:time_point_Post'}
% Note: Adjust if order differs in your output
% Contrasts for Post - Pre per event
contrast_press = [0 0 0 1 0 0];  % time_point_Post
contrast_trigger = [0 0 0 1 1 0];  % time_point_Post + event_trigger:time_point_Post
contrast_poke = [0 0 0 1 0 1];  % time_point_Post + event_poke:time_point_Post

% Perform tests (use 'satterthwaite' for approximate DF if needed; adjust DFMethod as per your table's DF)
[p_press, F_press, stats_press] = coefTest(lme, contrast_press);
[p_trigger, F_trigger, stats_trigger] = coefTest(lme, contrast_trigger);
[p_poke, F_poke, stats_poke] = coefTest(lme, contrast_poke);

% Bonferroni adjustment for 3 tests
% num_tests = 3;
num_tests = 1; % save raw value for subsequent corrections (e.g., fdr), 2025.9.11
stat_out.pvals.press = min(p_press * num_tests, 1);
stat_out.pvals.trigger = min(p_trigger * num_tests, 1);
stat_out.pvals.poke = min(p_poke * num_tests, 1);

% Extract coefficients, covariance, and DF from the fitted model
beta = lme.Coefficients.Estimate;
cov_mat = lme.CoefficientCovariance;
df = lme.DFE;  % Degrees of freedom from the model (e.g., 312 in your table)

% Critical t-value for 95% CI
t_crit = tinv(0.975, df);

% Contrast vectors based on coefficient order: 
% 1:(Intercept), 2:event_trigger, 3:event_poke, 4:time_point_Post, 
% 5:event_trigger:time_point_Post, 6:event_poke:time_point_Post

% Press: time_point_Post
contrast_press = [0 0 0 1 0 0];
stat_out.contrast.est_press = contrast_press * beta;
stat_out.contrast.se_press = sqrt(contrast_press * cov_mat * contrast_press');
stat_out.contrast.ci_press_lower = stat_out.contrast.est_press - t_crit * stat_out.contrast.se_press;
stat_out.contrast.ci_press_upper = stat_out.contrast.est_press + t_crit * stat_out.contrast.se_press;

% Trigger: time_point_Post + event_trigger:time_point_Post
contrast_trigger = [0 0 0 1 1 0];
stat_out.contrast.est_trigger = contrast_trigger * beta;
stat_out.contrast.se_trigger = sqrt(contrast_trigger * cov_mat * contrast_trigger');
stat_out.contrast.ci_trigger_lower = stat_out.contrast.est_trigger - t_crit * stat_out.contrast.se_trigger;
stat_out.contrast.ci_trigger_upper = stat_out.contrast.est_trigger + t_crit * stat_out.contrast.se_trigger;

% Poke: time_point_Post + event_poke:time_point_Post
contrast_poke = [0 0 0 1 0 1];
stat_out.contrast.est_poke = contrast_poke * beta;
stat_out.contrast.se_poke = sqrt(contrast_poke * cov_mat * contrast_poke');
stat_out.contrast.ci_poke_lower = stat_out.contrast.est_poke - t_crit * stat_out.contrast.se_poke;
stat_out.contrast.ci_poke_upper = stat_out.contrast.est_poke + t_crit * stat_out.contrast.se_poke;

stat_table = table({stat_out.cell_id}, ...
    stat_out.pvals.press, stat_out.contrast.est_press, stat_out.contrast.se_press, ...
    stat_out.pvals.trigger, stat_out.contrast.est_trigger, stat_out.contrast.se_trigger, ...
    stat_out.pvals.poke, stat_out.contrast.est_poke, stat_out.contrast.se_poke, ...
    'VariableNames',{'cell_id',...
    'pval_press', 'contrast_press', 'se_press', ...
    'pval_trigger', 'contrast_trigger', 'se_trigger', ...
    'pval_poke', 'contrast_poke', 'se_poke'});