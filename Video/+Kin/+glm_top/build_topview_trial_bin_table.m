function [B, trial_info] = build_topview_trial_bin_table(T, ops)
%BUILD_TOPVIEW_TRIAL_BIN_TABLE Bin top-view tracking by trial and phase.
%
% [B, trial_info] = build_topview_trial_bin_table(T, ops)
%
% T should be the top-view table after add_topview_features(...), so that
% lever-centered and cm-scaled variables already exist.
%
% INPUT
%   T : top-view tracking table
%
%   ops fields:
%       .phases              string/cellstr, e.g. ["toLever","fromLever"]
%       .bin_ms              bin size in ms, e.g. 25
%       .use_keep_run_mask   logical, default false
%       .smooth_win_frames   moving-average window in frames, default 11
% OUTPUT
%   B : one row per trial-bin-phase
%
%   trial_info : one element per parent trial. Each element contains:
%       .trial
%       .anm_session
%       .press_time
%       .toLever      (phase struct, if present)
%       .fromLever    (phase struct, if present)
%
% Each phase struct contains:
%       .phase
%       .time
%       .t_rel_ms
%       .valid
%       .n_samples
%       .n_valid_samples
%       .tracked_duration_ms
%       .tracked_fraction
%       .t_start
%       .t_end
%       .duration_ms
%       plus available kinematic fields copied from T
%
% B includes:
%       trial, anm_session, press_time, lever_phase
%       time_bin_start, time_bin_end, time_bin_center
%       t_rel_ms, t_rel_s, t_rel_s2
%       valid_head
%       and available binned top-view variables
%
% Jianing Yu / revised with per-trial nested phase info

% -----------------------------
% checks
% -----------------------------
required_vars = {'time', 'trial', 'anm_session', 'lever_phase'};
missing_vars = required_vars(~ismember(required_vars, T.Properties.VariableNames));
if ~isempty(missing_vars)
    error('build_topview_trial_bin_table:MissingVariable', ...
        'Missing required variable(s): %s', strjoin(missing_vars, ', '));
end

if ~isfield(ops, 'phases')
    error('build_topview_trial_bin_table:MissingOps', 'ops.phases is required.');
end
if ~isfield(ops, 'bin_ms')
    error('build_topview_trial_bin_table:MissingOps', 'ops.bin_ms is required.');
end
if ~isfield(ops, 'use_keep_run_mask')
    ops.use_keep_run_mask = false;
end

if ~isfield(ops, 'smooth_win_frames')
    ops.smooth_win_frames = 11;
end

phases = string(ops.phases(:)');
T.lever_phase = string(T.lever_phase);
T.trial = string(T.trial);
T.anm_session = string(T.anm_session);

% keep only requested phases
T = T(ismember(T.lever_phase, phases), :);

if isempty(T)
    warning('build_topview_trial_bin_table:NoRows', ...
        'No rows remain after filtering requested phases.');
    B = table();
    trial_info = struct([]);
    return
end

% -----------------------------
% extract press time from trial name
% supports Top_Press_229539 or Side_Press_229539
% -----------------------------
% tok = regexp(T.trial, "^(?:Side|Top)_Press_(\d+)$", "tokens", "once");
% 核心逻辑：在捕获括号 (\d+) 前增加 (?:\d+_)? 用于匹配并忽略掉第一组数字和下划线
tok = regexp(T.trial, "^(?:Side|Top)_(?:Press|Approach|Retrieval)_(?:\d+_)?(\d+)$", "tokens", "once");
press_time = nan(height(T), 1);

for i = 1:height(T)
    if ~isempty(tok{i})
        press_time(i) = str2double(tok{i}{1});
    end
end

T.press_time = press_time;

if any(isnan(T.press_time))
    warning('Some rows have trial names that do not match (Side|Top)_Press_<time>.');
end

% -----------------------------
% phase / feature flags
% -----------------------------
has_kept_mask           = ismember('kept_mask', T.Properties.VariableNames);
has_keep_run_mask       = ismember('keep_run_mask', T.Properties.VariableNames);

% Variables that can be copied into phase-level raw trial_info directly
raw_copy_vars = {
    'head_x'
    'head_y'
    'head_x_cm'
    'head_y_cm'
    'head_x_rel_cm'
    'head_y_rel_cm'
    'vx_cm_s'
    'vy_cm_s'
    'speed_cm_s'
    'forward_speed_cm_s'
    'lateral_speed_cm_s'
    'head_theta'
    'head_theta_cos'
    'head_theta_sin'
    'head_omega'
    'dist_to_lever_cm'
    'approach_speed_cm_s'
};

% Variables to be linearly averaged within bins
mean_bin_vars = {
    'head_x_cm'
    'head_y_cm'
    'head_x_rel_cm'
    'head_y_rel_cm'
    'vx_cm_s'
    'vy_cm_s'
    'speed_cm_s'
    'forward_speed_cm_s'
    'lateral_speed_cm_s'
    'head_omega'
    'dist_to_lever_cm'
    'approach_speed_cm_s'
};

% Circular variable(s) to bin specially
has_head_theta = ismember('head_theta', T.Properties.VariableNames);
has_head_theta_cos = ismember('head_theta_cos', T.Properties.VariableNames);
has_head_theta_sin = ismember('head_theta_sin', T.Properties.VariableNames);

% -----------------------------
% parent trials
% -----------------------------
trials = unique(T.trial, "stable");
nTrials = numel(trials);

fprintf('Found %d parent trials across phases: %s\n', ...
    nTrials, strjoin(cellstr(phases), ', '));

B_cell = {};
trial_info = repmat(struct(), nTrials, 1);

% -----------------------------
% build outputs
% -----------------------------
for k = 1:nTrials
    this_trial = trials(k);
    Ttrial_all = T(T.trial == this_trial, :);

    if isempty(Ttrial_all)
        continue
    end

    trial_info(k).trial = this_trial;
    trial_info(k).anm_session = Ttrial_all.anm_session(1);
    trial_info(k).press_time = Ttrial_all.press_time(1);

    % initialize all requested phase fields as empty
    for iP = 1:numel(phases)
        phase_name = matlab.lang.makeValidName(char(phases(iP)));
        trial_info(k).(phase_name) = [];
    end

    % process each requested phase within this parent trial
    for iP = 1:numel(phases)
        this_phase = phases(iP);
        phase_field = matlab.lang.makeValidName(char(this_phase));

        Tphase = Ttrial_all(Ttrial_all.lever_phase == this_phase, :);
        if isempty(Tphase)
            continue
        end
        Tphase = local_smooth_topview_phase_table(Tphase, ops.smooth_win_frames);

        t_press = Tphase.press_time(1);
        anm_session = Tphase.anm_session(1);
        t_min = min(Tphase.time);
        t_max = max(Tphase.time);

        % -----------------------------
        % raw-frame validity
        % -----------------------------
        valid_raw = true(height(Tphase), 1);
        if has_kept_mask
            valid_raw = valid_raw & (Tphase.kept_mask == 1);
        end
        if ops.use_keep_run_mask && has_keep_run_mask
            valid_raw = valid_raw & (Tphase.keep_run_mask == 1);
        end

        % -----------------------------
        % nested phase struct for trial_info
        % -----------------------------
        P = struct();
        P.phase = this_phase;
        P.time = Tphase.time;
        P.t_rel_ms = Tphase.time - t_press;
        P.valid = valid_raw;
        P.n_samples = height(Tphase);
        P.n_valid_samples = sum(valid_raw);
        P.t_start = t_min;
        P.t_end = t_max;
        P.duration_ms = t_max - t_min;

        if numel(Tphase.time) >= 2
            dt_est = median(diff(Tphase.time), 'omitnan');
        else
            dt_est = 10;
        end

        P.tracked_duration_ms = sum(valid_raw) * dt_est;
        if ~isempty(valid_raw)
            P.tracked_fraction = sum(valid_raw) / numel(valid_raw);
        else
            P.tracked_fraction = NaN;
        end

        for iVar = 1:numel(raw_copy_vars)
            v = string(raw_copy_vars{iVar});
            if ismember(v, string(Tphase.Properties.VariableNames))
                P.(v) = Tphase.(v);
            else
                P.(v) = [];
            end
        end

        trial_info(k).(phase_field) = P;
        % -----------------------------
        % bins for B
        % -----------------------------
        edges = t_min:ops.bin_ms:(t_max + ops.bin_ms);
        if numel(edges) < 2
            continue
        end

        nBins = numel(edges) - 1;

        Bk = table();
        Bk.trial = repmat(this_trial, nBins, 1);
        Bk.anm_session = repmat(anm_session, nBins, 1);
        Bk.press_time = repmat(t_press, nBins, 1);
        Bk.lever_phase = repmat(this_phase, nBins, 1);

        Bk.time_bin_start  = edges(1:end-1)';
        Bk.time_bin_end    = edges(2:end)';
        Bk.time_bin_center = (Bk.time_bin_start + Bk.time_bin_end) / 2;

        Bk.t_rel_ms = Bk.time_bin_center - t_press;
        Bk.t_rel_s  = Bk.t_rel_ms / 1000;
        Bk.t_rel_s2 = Bk.t_rel_s .^ 2;

        Bk.valid_head = false(nBins, 1);

        % initialize linear-mean vars if present in Tphase
        for iVar = 1:numel(mean_bin_vars)
            v = string(mean_bin_vars{iVar});
            if ismember(v, string(Tphase.Properties.VariableNames))
                Bk.(v) = nan(nBins, 1);
            end
        end

        % initialize circular outputs
        if has_head_theta
            Bk.head_theta = nan(nBins, 1);
        end
        if has_head_theta_cos
            Bk.head_theta_cos = nan(nBins, 1);
        end
        if has_head_theta_sin
            Bk.head_theta_sin = nan(nBins, 1);
        end

        bin_idx = discretize(Tphase.time, edges);

        for b = 1:nBins
            m = (bin_idx == b);

            if has_kept_mask
                m = m & (Tphase.kept_mask == 1);
            end
            if ops.use_keep_run_mask && has_keep_run_mask
                m = m & (Tphase.keep_run_mask == 1);
            end

            if ~any(m)
                continue
            end

            % linear means
            for iVar = 1:numel(mean_bin_vars)
                v = string(mean_bin_vars{iVar});
                if ismember(v, string(Tphase.Properties.VariableNames))
                    Bk.(v)(b) = mean(Tphase.(v)(m), 'omitnan');
                end
            end

            % circular head theta
            if has_head_theta
                c = mean(cos(Tphase.head_theta(m)), 'omitnan');
                s = mean(sin(Tphase.head_theta(m)), 'omitnan');

                Bk.head_theta(b) = atan2(s, c);

                if has_head_theta_cos && ismember('head_theta_cos', Bk.Properties.VariableNames)
                    Bk.head_theta_cos(b) = c;
                end
                if has_head_theta_sin && ismember('head_theta_sin', Bk.Properties.VariableNames)
                    Bk.head_theta_sin(b) = s;
                end
            end

            Bk.valid_head(b) = true;
        end

        B_cell{end+1,1} = Bk; %#ok<AGROW>
    end
end

% -----------------------------
% concatenate B
% -----------------------------
if ~isempty(B_cell)
    B = vertcat(B_cell{:});
else
    B = table();
end

end

function Tphase = local_smooth_topview_phase_table(Tphase, smooth_win_frames)

if smooth_win_frames <= 1 || isempty(Tphase)
    return
end

smooth_vars = {
    'head_x'
    'head_y'
    'head_x_cm'
    'head_y_cm'
    'head_x_rel_cm'
    'head_y_rel_cm'
    'vx_cm_s'
    'vy_cm_s'
    'speed_cm_s'
    'forward_speed_cm_s'
    'lateral_speed_cm_s'
    'head_omega'
    'dist_to_lever_cm'
    'approach_speed_cm_s'
};

% smooth ordinary linear variables
for iVar = 1:numel(smooth_vars)
    v = smooth_vars{iVar};
    if ismember(v, Tphase.Properties.VariableNames)
        x = Tphase.(v);
        if isnumeric(x)
            Tphase.(v) = movmean(x, smooth_win_frames, 'omitnan', 'Endpoints', 'shrink');
        end
    end
end

% circular angle smoothing through cos/sin
has_cos = ismember('head_theta_cos', Tphase.Properties.VariableNames);
has_sin = ismember('head_theta_sin', Tphase.Properties.VariableNames);

if has_cos && has_sin
    c = Tphase.head_theta_cos;
    s = Tphase.head_theta_sin;

    c = movmean(c, smooth_win_frames, 'omitnan', 'Endpoints', 'shrink');
    s = movmean(s, smooth_win_frames, 'omitnan', 'Endpoints', 'shrink');

    % renormalize to unit circle when possible
    r = hypot(c, s);
    good = isfinite(r) & (r > 0);

    c_norm = c;
    s_norm = s;
    c_norm(good) = c(good) ./ r(good);
    s_norm(good) = s(good) ./ r(good);

    Tphase.head_theta_cos = c_norm;
    Tphase.head_theta_sin = s_norm;

    if ismember('head_theta', Tphase.Properties.VariableNames)
        Tphase.head_theta = atan2(Tphase.head_theta_sin, Tphase.head_theta_cos);
    end
end

end