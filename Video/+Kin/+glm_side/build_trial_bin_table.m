function [B, trial_info] = build_trial_bin_table(T, ops)
% build_trial_bin_table
%
% Jianing Yu 3/12/2026
%
% T is the table from app track_side_kinematics.
% From T, extract trials and press time, then build:
%
% OUTPUT
%   B : one row per trial-bin, for GLM / rate-map analysis
%   trial_info : struct array, one element per trial, for easy trajectory plotting
%
% B columns include:
%   trial
%   anm_session
%   press_time
%   time_bin_start
%   time_bin_end
%   time_bin_center
%   t_rel_ms
%   t_rel_s
%   t_rel_s2
%   <body>_x_cm, <body>_y_cm
%   <body>_x_rel_cm, <body>_y_rel_cm
%   <body>_vx_cm_s, <body>_vy_cm_s
%   valid_<body>
%   valid_all_parts
%
% trial_info(k) includes:
%   .trial
%   .anm_session
%   .press_time
%   .t_start
%   .t_end
%   .duration_ms
%   .<body>.time
%   .<body>.t_rel_ms
%   .<body>.x_cm
%   .<body>.y_cm
%   .<body>.x_rel_cm
%   .<body>.y_rel_cm
%   .<body>.vx_cm_s
%   .<body>.vy_cm_s
%   .<body>.valid
%   .<body>.n_samples
%   .<body>.n_valid_samples
%   .<body>.tracked_duration_ms
%   .<body>.tracked_fraction

%-----------------------------
% basic cleanup
%-----------------------------
T = T(strcmp(string(T.lever_phase), string(ops.phase)), :);
T = T(ismember(string(T.body_part), string(ops.body_parts)), :);

T.trial       = string(T.trial);
T.body_part   = string(T.body_part);
T.anm_session = string(T.anm_session);

%-----------------------------
% extract press time from trial name
% example: "Side_Press_229539" -> 229539
%-----------------------------
tok = regexp(T.trial, "Side_Press_(\d+)", "tokens", "once");
press_time = nan(height(T),1);

for i = 1:height(T)
    if ~isempty(tok{i})
        press_time(i) = str2double(tok{i}{1});
    end
end

T.press_time = press_time;

if any(isnan(T.press_time))
    warning('Some rows have trial names that do not match Side_Press_<time>.');
end

%-----------------------------
% unique trials
%-----------------------------
trials = unique(T.trial, "stable");
nTrials = numel(trials);

fprintf('Found %d trials in phase %s.\n', nTrials, string(ops.phase));

%-----------------------------
% prepare outputs
%-----------------------------
B_cell = cell(nTrials, 1);
trial_info = repmat(struct(), nTrials, 1);
parts = string(ops.body_parts);

%-----------------------------
% build one binned table per trial
% and one trajectory/QC struct per trial
%-----------------------------
for k = 1:nTrials
    this_trial = trials(k);
    Ttrial = T(T.trial == this_trial, :);

    if isempty(Ttrial)
        continue
    end

    t_press = Ttrial.press_time(1);
    anm_session = Ttrial.anm_session(1);

    % time range for this trial
    t_min = min(Ttrial.time);
    t_max = max(Ttrial.time);

    %---------------------------------
    % trial_info: trial-level metadata
    %---------------------------------
    trial_info(k).trial = this_trial;
    trial_info(k).anm_session = anm_session;
    trial_info(k).press_time = t_press;
    trial_info(k).t_start = t_min;
    trial_info(k).t_end = t_max;
    trial_info(k).duration_ms = t_max - t_min;

    %---------------------------------
    % define bin edges for B
    %---------------------------------
    edges = t_min:ops.bin_ms:(t_max + ops.bin_ms);
    if numel(edges) < 2
        continue
    end

    nBins = numel(edges) - 1;

    % initialize trial-bin table
    Bk = table();
    Bk.trial = repmat(this_trial, nBins, 1);
    Bk.anm_session = repmat(anm_session, nBins, 1);
    Bk.press_time = repmat(t_press, nBins, 1);

    Bk.time_bin_start  = edges(1:end-1)';
    Bk.time_bin_end    = edges(2:end)';
    Bk.time_bin_center = (Bk.time_bin_start + Bk.time_bin_end) / 2;

    % press-relative time
    Bk.t_rel_ms = Bk.time_bin_center - t_press;
    Bk.t_rel_s  = Bk.t_rel_ms / 1000;
    Bk.t_rel_s2 = Bk.t_rel_s .^ 2;

    % initialize columns for each body part
    for p = 1:numel(parts)
        bp = parts(p);

        Bk.(bp + "_x_cm")      = nan(nBins,1);
        Bk.(bp + "_y_cm")      = nan(nBins,1);
        Bk.(bp + "_x_rel_cm")  = nan(nBins,1);
        Bk.(bp + "_y_rel_cm")  = nan(nBins,1);
        Bk.(bp + "_vx_cm_s")   = nan(nBins,1);
        Bk.(bp + "_vy_cm_s")   = nan(nBins,1);
        Bk.(bp + "_speed_cm_s")   = nan(nBins,1);

        Bk.("valid_" + bp)     = false(nBins,1);
    end

    %---------------------------------
    % fill one body part at a time
    %---------------------------------
    for p = 1:numel(parts)
        bp = parts(p);
        Tb = Ttrial(Ttrial.body_part == bp, :);

        % initialize empty fields in trial_info even if missing
        trial_info(k).(bp).time = [];
        trial_info(k).(bp).t_rel_ms = [];
        trial_info(k).(bp).x_cm = [];
        trial_info(k).(bp).y_cm = [];
        trial_info(k).(bp).x_rel_cm = [];
        trial_info(k).(bp).y_rel_cm = [];
        trial_info(k).(bp).vx_cm_s = [];
        trial_info(k).(bp).vy_cm_s = [];
        trial_info(k).(bp).valid = [];
        trial_info(k).(bp).n_samples = 0;
        trial_info(k).(bp).n_valid_samples = 0;
        trial_info(k).(bp).tracked_duration_ms = 0;
        trial_info(k).(bp).tracked_fraction = NaN;

        if isempty(Tb)
            continue
        end

        %---------------------------------
        % original-resolution trajectory info
        %---------------------------------
        time_raw = Tb.time;
        x_cm = Tb.x_s / ops.scale_px_per_cm;
        y_cm = Tb.y_s / ops.scale_px_per_cm;
        x_rel_cm = -(Tb.x_s - ops.anchor.x_px) / ops.scale_px_per_cm;
        y_rel_cm = -(Tb.y_s - ops.anchor.y_px) / ops.scale_px_per_cm;
        vx_cm_s = -Tb.vx / ops.scale_px_per_cm; 
        % '-' sign to reverse the definition of movement direction. moving
        % closer to the lever (moving left) means a positive velocity,
        % moving up means a positive velocity
        vy_cm_s = -Tb.vy / ops.scale_px_per_cm;

        valid_raw = true(height(Tb),1);
        if ismember('kept_mask', Tb.Properties.VariableNames)
            valid_raw = valid_raw & (Tb.kept_mask == 1);
        end

        trial_info(k).(bp).time = time_raw;
        trial_info(k).(bp).t_rel_ms = time_raw - t_press;
        trial_info(k).(bp).x_cm = x_cm;
        trial_info(k).(bp).y_cm = y_cm;
        trial_info(k).(bp).x_rel_cm = x_rel_cm;
        trial_info(k).(bp).y_rel_cm = y_rel_cm;
        trial_info(k).(bp).vx_cm_s = vx_cm_s;
        trial_info(k).(bp).vy_cm_s = vy_cm_s;
        trial_info(k).(bp).valid = valid_raw;
        trial_info(k).(bp).n_samples = numel(valid_raw);
        trial_info(k).(bp).n_valid_samples = sum(valid_raw);

        if numel(time_raw) >= 2
            dt_est = median(diff(time_raw), 'omitnan');
        else
            dt_est = 10; % fallback
        end

        trial_info(k).(bp).tracked_duration_ms = sum(valid_raw) * dt_est;

        if numel(valid_raw) > 0
            trial_info(k).(bp).tracked_fraction = sum(valid_raw) / numel(valid_raw);
        else
            trial_info(k).(bp).tracked_fraction = NaN;
        end


        % --- detect linear segment ---     
        lin_params = struct();
        lin_params.min_block_len = 4;
        lin_params.max_turn_deg = 5;
        lin_params.min_total_disp = 0.15;
        lin_params.use_valid_mask = valid_raw;

        lin_info = Kin.detect_linear_segments_xy( ...
            trial_info(k).(bp).x_rel_cm, ...
            trial_info(k).(bp).y_rel_cm, ...
            trial_info(k).(bp).time, ...
            lin_params);

        trial_info(k).(bp).linear_mask = lin_info.linear_mask;
        trial_info(k).(bp).linear_dur_ms = lin_info.linear_dur_ms;
        trial_info(k).(bp).n_linear_blocks = lin_info.n_linear_blocks;
        trial_info(k).(bp).linear_blocks = lin_info.linear_blocks;

        %---------------------------------
        % assign rows to bins for B
        %---------------------------------
        bin_idx = discretize(Tb.time, edges);

        for b = 1:nBins
            m = (bin_idx == b);

            if ismember('kept_mask', Tb.Properties.VariableNames)
                m = m & (Tb.kept_mask == 1);
            end

            if ~any(m)
                continue
            end

            % optional stricter rule: require at least 2 valid frames
            % if sum(m) < 2
            %     continue
            % end

            x_px  = mean(Tb.x_s(m), 'omitnan');
            y_px  = mean(Tb.y_s(m), 'omitnan');
            vx_px = mean(Tb.vx(m),  'omitnan');
            vy_px = mean(Tb.vy(m),  'omitnan');

            Bk.(bp + "_x_cm")(b)     = x_px  / ops.scale_px_per_cm;
            Bk.(bp + "_y_cm")(b)     = y_px  / ops.scale_px_per_cm;
            Bk.(bp + "_x_rel_cm")(b) = -(x_px - ops.anchor.x_px) / ops.scale_px_per_cm;
            Bk.(bp + "_y_rel_cm")(b) = -(y_px - ops.anchor.y_px) / ops.scale_px_per_cm;
            Bk.(bp + "_vx_cm_s")(b)  = -vx_px / ops.scale_px_per_cm;
            Bk.(bp + "_vy_cm_s")(b)  = -vy_px / ops.scale_px_per_cm;
            Bk.(bp + "_speed_cm_s")(b)  = hypot(vx_px / ops.scale_px_per_cm, vy_px / ops.scale_px_per_cm);

            Bk.("valid_" + bp)(b) = true;
        end
    end

    %---------------------------------
    % all-parts validity
    %---------------------------------
    valid_cols = "valid_" + parts;
    valid_mat = false(nBins, numel(valid_cols));

    for j = 1:numel(valid_cols)
        valid_mat(:,j) = Bk.(valid_cols(j));
    end

    Bk.valid_all_parts = all(valid_mat, 2);

    B_cell{k} = Bk;
end

%-----------------------------
% concatenate across trials
%-----------------------------
not_empty = ~cellfun(@isempty, B_cell);
if any(not_empty)
    B = vertcat(B_cell{not_empty});
else
    B = table();
end

end