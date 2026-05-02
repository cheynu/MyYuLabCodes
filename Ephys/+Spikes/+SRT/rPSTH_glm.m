function [stat_out, stat_table] = rPSTH_glm(s)
% Jianing Yu 8/14/2025
% s is the output from rPSTHWarped.m
% s =
% struct with fields:
% eventSequenceLabels: {'press'  'trigger'  'release'  'poke'}
% eventSequence: {[33×4 double]  [20×4 double]}
% explained: 'These are press-related spike trains and sdfs, each cell is a FP'
% press: {{1×33 cell}  {1×20 cell}}
% trigger: {{1×33 cell}  {1×20 cell}}

% 10.9.2025: revised to use glme instead of lme
% 10.9.2025: revised to use glm instead of glme
% trigger window: 250 ms, to avoid the mix of retrieval activity 

stat_out = struct();

% approach+lift
bin_size.approach   = [-2000 -1000; -1000 0]; % this covers both approach and lift process
bin_size.lift       = [-1500 -1000; -750 -250]; % 

% approch section
% bin_size.approach = [-1500 -1000; -1000 -500]; % in ms. compare spike count before and after press, 500 ms window
% first region: -2000 -- -1000 ms before press vs -750 -- 250 after press
bin_size.press = [-500 0; 0 500]; % in ms. compare spike count before and after press, 500 ms window
% second region: -500 -- 0 before trigger vs 100 -- 600 after trigger
bin_size.trigger = [-250 0; 0 250]; % in ms, compare spike count before and after trigger, 500 ms window
% third region: 0 -- 1000 before poke vs 0 -- 1000 after poke
bin_size.poke = [-1000 0; 0 1000]; % in ms, compare spike count before and after poke, 500 ms window

% Step 1: Extract spike count in these time windows
% this_sdf.raster
stat_out.cell_id = s.unit.cell_id; 

nFP = length(s.raster.press);
FPs = s.FPs;
spk_count_tab = table;
% behavior_events = {'approach','lift', 'press', 'trigger', 'poke'};
behavior_events = {'approach','press', 'trigger', 'poke'};
trial_index = 0;
for i =1:nFP
    n_sequence = size(s.raster.eventSequence{i}, 1);
    spk_times = s.raster.press{i};
    FP = FPs(i);
    % figure(5); clf(5); set(gcf, 'Visible','on')
    % plot(s.sdf.warped(i).t_sdf, s.sdf.warped(i).sdf_mean)
    % hold on
    for k =1:n_sequence
        event_time = s.raster.eventSequence{i}(k, :);
        event_time = event_time-event_time(1);
        % bin_size.press = [-500 0; 0 FP];
        % rt_this_seq = event_time(3)-event_time(2)-0.1;
        % bin_size.trigger = [-rt_this_seq 0; 0 rt_this_seq];
        % retrieval_dur = event_time(4)-event_time(3);
        % bin_size.poke = [-retrieval_dur 0; 0 1000];

        event_time(3)= [];% this is the release time
        spk_time = spk_times{k};
        trial_index = trial_index +1;

        for j_ =1:length(behavior_events)

            switch behavior_events{j_}

                case 'approach'
                    % pre event spk
                    pre_window = bin_size.approach(1, :);
                    post_window = bin_size.approach(2, :);

                case 'lift'

                    pre_window = bin_size.lift(1, :);
                    post_window = bin_size.lift(2, :);
                case 'press'
                    pre_window = bin_size.press(1, :);
                    post_window = bin_size.press(2, :);

                case 'trigger'
                    pre_window = bin_size.trigger(1, :)+FP;
                    post_window = bin_size.trigger(2, :)+FP;

                case 'poke'
                    pre_window = bin_size.poke(1, :)+event_time(3);
                    post_window = bin_size.poke(2, :)+event_time(3);

            end

            ind_pre = sum(spk_time>=pre_window(1) & spk_time<pre_window(2));
            spk_count_pre = ind_pre;

            this_row = table(trial_index, {behavior_events{j_}},  {'Pre'}, FP, spk_count_pre, diff(pre_window)/1000, ...
                'VariableNames',{'trial', 'event', 'time_point', 'FP', 'spike_count', 'duration'});
            spk_count_tab = [spk_count_tab; this_row];
      
            % post event spk
            ind_post = sum(spk_time>=post_window(1) & spk_time<post_window(2));
            spk_count_post = ind_post;

            this_row = table(trial_index, {behavior_events{j_}}, {'Post'}, FP, spk_count_post, diff(post_window)/1000, ...
                'VariableNames',{'trial', 'event', 'time_point', 'FP', 'spike_count', 'duration'});
            spk_count_tab = [spk_count_tab; this_row];
 
        end
    end
end

tbl = spk_count_tab;

% Convert to categorical for factors
tbl.event = categorical(tbl.event, {'approach', 'press', 'trigger', 'poke'});  % Set order to match reference
tbl.time_point = categorical(tbl.time_point, {'Pre', 'Post'});  % Set reference to 'Post' first

% Fit the linear mixed effects model
% Formula: spike_rate ~ event * time_point + (1 | trial)
% lme = fitlme(tbl, 'spike_rate ~ event * time_point + (1 | trial)');
stat_out = struct();
stat_out.cell_id = s.unit.cell_id;  % Assuming this is defined elsewhere
spk_count_tab.event = categorical(spk_count_tab.event);
spk_count_tab.time_point = categorical(spk_count_tab.time_point, {'Pre', 'Post'});
spk_count_tab.trial = categorical(spk_count_tab.trial);
spk_count_tab = spk_count_tab(spk_count_tab.event~='lift', :); % lift data are not used

stat_out = struct();
stat_out.cell_id = s.unit.cell_id;  % Assuming defined

% ... (your table generation code for spk_count_tab here) ...

% Convert to categorical
% spk_count_tab.event = categorical(spk_count_tab.event, {'approach', 'lift', 'press', 'trigger', 'poke'});
spk_count_tab.event = categorical(spk_count_tab.event, {'approach', 'press', 'trigger', 'poke'});
spk_count_tab.time_point = categorical(spk_count_tab.time_point, {'Pre', 'Post'});
spk_count_tab.trial = categorical(spk_count_tab.trial);

events = categories(spk_count_tab.event);  % Get unique events as categorical array
pvals = struct();
folds = struct();
fold_lowers = struct();
fold_uppers = struct();
status = struct();
threshold = 20;  % Adjust as needed

for i = 1:length(events)
    event = events{i};
    event_data = spk_count_tab(spk_count_tab.event == event, :);
    status.(event) = {};
    
    % Skip if low activity for this event
    event_spikes = sum(event_data.spike_count);
    if event_spikes < threshold
        status.(event) = 'low_activity';
        pvals.(event) = 1;
        folds.(event) = 1;
        fold_lowers.(event) = 1;
        fold_uppers.(event) = 1;
        continue;
    end

    % Check proportion of zeros to decide pseudocount
    pre_idx = strcmp(string(event_data.time_point), 'Pre');
    pre_zero_count = sum(event_data.spike_count(pre_idx) == 0);
    pre_total = sum(pre_idx);
    pre_zero_prop = pre_zero_count / pre_total;

    post_idx = strcmp(string(event_data.time_point), 'Post');
    post_zero_count = sum(event_data.spike_count(post_idx) == 0);
    post_total = sum(post_idx);
    post_zero_prop = post_zero_count / post_total;

    % Add pseudocount if ≥50% zeros in Pre or Post
    temp_data = event_data;
    if pre_zero_prop >= 0.5 || post_zero_prop >= 0.5
        temp_data.spike_count = temp_data.spike_count + 1;  % Integer pseudocount
        status.(event) = 'pseudocount_added';
    else
        status.(event) = 'no_pseudocount';
    end

    % Check for perfect separation (all Pre=0, some Post>0)
    %
    %     In your 'poke' data (390 rows, 195 trials), all Pre spike counts
    %     are 0, while Post has some non-zero counts (e.g., mean Post rate
    %     ~0.64 Hz). This perfect separation (Pre=0, Post>0) causes the
    %     Poisson GLM to struggle because the log fold change
    %     ($\log(\text{Post rate} / \text{Pre rate})$) becomes undefined or
    %     infinite ($\log(\text{Post} / 0)$). This leads to numerical
    %     instability, ill-conditioned weights, or non-convergence
    %     warnings, as you've seen.
    %     Parametric models like Poisson GLM assume a specific distribution
    %     (mean = variance) and rely on iterative maximum likelihood
    %     estimation, which fails when the likelihood surface is flat or
    %     %     unbounded due to zeros. Sparse Data and Zeros:
    % 
    % Your data is sparse (many zeros, especially in Pre), violating Poisson's
    % assumption of sufficient counts for stable estimation. Even with
    % pseudocounts (+1), the model may produce unreliable p-values or fold
    % changes, especially for low-count events like 'poke'. Non-parametric
    % tests don't assume a specific distribution, making them robust to zeros,
    % low counts, or non-normality, which is common in neural spike data.

    if pre_zero_prop == 1 && post_zero_count < post_total
        status.(event) = [status.(event) '_perfect_separation'];
        % Use non-parametric test (Wilcoxon signed-rank)
        pre_rates = temp_data.spike_count(pre_idx) ./ temp_data.duration(pre_idx);
        post_rates = temp_data.spike_count(post_idx) ./ temp_data.duration(post_idx);
        [p, ~] = signrank(pre_rates, post_rates);
        pvals.(event) = p;
        folds.(event) = Inf;  % Indicates activation from zero
        fold_lowers.(event) = NaN;
        fold_uppers.(event) = NaN;
        continue;
    end

   % Fit GLM with Poisson
    try
        lastwarn('');  % Clear warnings
        opts = statset('MaxIter', 1000, 'TolFun', 1e-8);  % Stricter tolerance
        glm = fitglm(temp_data, 'spike_count ~ time_point', ...
            'Distribution', 'poisson', 'Offset', log(temp_data.duration), ...
            'Options', opts);
        
        % Check for warnings indicating convergence issues
        [wmsg, wid] = lastwarn;
        if ~isempty(wid) && (contains(wmsg, 'converge') || contains(wmsg, 'ill-conditioned') || contains(wmsg, 'Iteration limit'))
            status.(event) = [status.(event) '_warning'];
            pvals.(event) = NaN;
            folds.(event) = NaN;
            fold_lowers.(event) = NaN;
            fold_uppers.(event) = NaN;
            continue;
        end
        
        status.(event) = [status.(event) '_glm_fitted'];
        stat_out.glm.(event) = glm;

    catch ME
        disp(['GLM failed for ' event ': ' ME.message '. Skipping.']);
        status.(event) = 'fit_failed';
        pvals.(event) = NaN;
        folds.(event) = NaN;
        fold_lowers.(event) = NaN;
        fold_uppers.(event) = NaN;
        continue;
    end

    % Post-hoc contrast: Post vs Pre
    coef_names = glm.CoefficientNames';
    beta = glm.Coefficients.Estimate;
    cov_mat = glm.CoefficientCovariance;
    
    post_name = 'time_point_Post';
    post_idx = find(strcmp(coef_names, post_name));
    if isempty(post_idx)
        error(['time_point_Post not found for ' event]);
    end
    
    contrast = zeros(1, length(beta));
    contrast(post_idx) = 1;
    [p, ~, ~] = coefTest(glm, contrast);
    est = contrast * beta;  % log(fold)
    se = sqrt(contrast * cov_mat * contrast');
    z_crit = norminv(0.975);
    lower = est - z_crit * se;
    upper = est + z_crit * se;
    
    pvals.(event) = p;
    folds.(event) = exp(est);
    fold_lowers.(event) = exp(lower);
    fold_uppers.(event) = exp(upper);
end

stat_out.pvals = pvals;
stat_out.contrast = struct('fold', folds, 'fold_lower', fold_lowers, 'fold_upper', fold_uppers);
stat_out.status = status;

% Summary table
stat_table = table({stat_out.cell_id}, ...
    pvals.approach, folds.approach, fold_lowers.approach, fold_uppers.approach, ...% pvals.lift, folds.lift, fold_lowers.lift, fold_uppers.lift, ...
    pvals.press, folds.press, fold_lowers.press, fold_uppers.press, ...
    pvals.trigger, folds.trigger, fold_lowers.trigger, fold_uppers.trigger, ...
    pvals.poke, folds.poke, fold_lowers.poke, fold_uppers.poke, ...
    'VariableNames', {'cell_id', ...
    'pval_approach', 'fold_approach', 'fold_lower_approach', 'fold_upper_approach', ...% 'pval_lift', 'fold_lift', 'fold_lower_lift', 'fold_upper_lift', ...
    'pval_press', 'fold_press', 'fold_lower_press', 'fold_upper_press', ...
    'pval_trigger', 'fold_trigger', 'fold_lower_trigger', 'fold_upper_trigger', ...
    'pval_poke', 'fold_poke', 'fold_lower_poke', 'fold_upper_poke'});

end