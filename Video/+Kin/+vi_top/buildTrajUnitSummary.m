function unit_summary = buildTrajUnitSummary(dataset, spk_times, unit_id, unit_quality_str, plot_cfg)
% Build one unit-level summary from a reusable session dataset.

tab = dataset.tab;
cond_defs = dataset.cond_defs;
axis_cfg = dataset.axis_cfg;

template = struct( ...
    'trials', {{}}, ...
    'n_trials', 0, ...
    'raster_spikes', {{}}, ...
    'time_range', [0 0], ...
    'traj_clim', [0 0], ...
    'x_bins', [], ...
    'psth_fr', [], ...
    'psth_t', [], ...
    'x_centers', [], ...
    'fr_by_x', [], ...
    'mean_start_rel', nan);
unit_summary = repmat(template, numel(cond_defs), 1);

for iCond = 1:numel(cond_defs)
    row_idx = find(cond_defs(iCond).row_mask);
    phase_summary = struct();
    phase_summary.trials = cell(numel(row_idx), 1);
    phase_summary.n_trials = 0;

    all_x = [];
    all_fr = [];
    all_tspk = [];
    start_rel = [];
    raster_spikes = cell(0,1);

    for i = 1:numel(row_idx)
        iRow = row_idx(i);
        traj = tab.(cond_defs(iCond).traj_var){iRow};
        if isempty(traj)
            continue
        end
        valid = get_valid_traj_mask(traj);
        if nnz(valid) < plot_cfg.min_frames
            continue
        end

        align_t = tab.(cond_defs(iCond).align_event)(iRow);
        trial_summary = summarize_single_trial(traj, spk_times, align_t, cond_defs(iCond), plot_cfg);
        if isempty(trial_summary)
            continue
        end

        phase_summary.n_trials = phase_summary.n_trials + 1;
        phase_summary.trials{phase_summary.n_trials} = trial_summary;
        all_x = [all_x; trial_summary.x(:)]; %#ok<AGROW>
        all_fr = [all_fr; trial_summary.sdf_frame(:)]; %#ok<AGROW>
        all_tspk = [all_tspk; trial_summary.spike_rel(:)]; %#ok<AGROW>

        if ~isempty(cond_defs(iCond).start_event)
            start_rel_this = tab.(cond_defs(iCond).start_event)(iRow) - tab.(cond_defs(iCond).align_event)(iRow);
        else
            start_rel_this = trial_summary.start_rel;
        end
        if isnan(start_rel_this)
            start_rel_this = trial_summary.start_rel;
        end
        start_rel = [start_rel; start_rel_this]; %#ok<AGROW>
        raster_spikes{end+1,1} = trial_summary.spike_rel(:); %#ok<AGROW>
    end

    phase_summary.trials = phase_summary.trials(1:phase_summary.n_trials);
    phase_summary.raster_spikes = raster_spikes;
    phase_summary.time_range = axis_cfg.psth_xlim_ms(iCond, :);
    phase_summary.traj_clim = axis_cfg.traj_clim_ms(iCond, :);
    phase_summary.x_bins = axis_cfg.xlim(1):plot_cfg.bin_pos_px:axis_cfg.xlim(2);
    if numel(phase_summary.x_bins) < 2
        phase_summary.x_bins = [axis_cfg.xlim(1), axis_cfg.xlim(2)];
    end

    if phase_summary.n_trials > 0
        [phase_summary.psth_fr, phase_summary.psth_t] = sdf25( ...
            all_tspk, phase_summary.time_range, plot_cfg.kernel_width_ms, ...
            plot_cfg.psth_bin_ms, phase_summary.n_trials);
        phase_summary.psth_fr = smoothdata(phase_summary.psth_fr, 'gaussian', plot_cfg.psth_smooth_bins);
        phase_summary.x_centers = mean([phase_summary.x_bins(1:end-1); phase_summary.x_bins(2:end)], 1);
        x_idx = discretize(all_x, phase_summary.x_bins);
        phase_summary.fr_by_x = accumarray(x_idx(~isnan(x_idx)), all_fr(~isnan(x_idx)), [numel(phase_summary.x_centers), 1], @mean, nan);
        phase_summary.mean_start_rel = mean(start_rel, 'omitnan');
    else
        phase_summary.psth_t = phase_summary.time_range(1):plot_cfg.psth_bin_ms:phase_summary.time_range(2);
        phase_summary.psth_fr = zeros(size(phase_summary.psth_t));
        phase_summary.x_centers = mean([phase_summary.x_bins(1:end-1); phase_summary.x_bins(2:end)], 1);
        phase_summary.fr_by_x = nan(numel(phase_summary.x_centers), 1);
        phase_summary.mean_start_rel = nan;
    end

    unit_summary(iCond) = phase_summary;
end

unit_summary = struct( ...
    'conditions', unit_summary, ...
    'unit_id', unit_id, ...
    'unit_quality_str', unit_quality_str);
end

function trial_summary = summarize_single_trial(traj, spk_times, align_t, cond_def, plot_cfg)
valid = get_valid_traj_mask(traj);
if nnz(valid) < 2
    trial_summary = [];
    return
end

traj_window = get_window_for_phase(cond_def.phase, plot_cfg, 'traj');
psth_window = get_window_for_phase(cond_def.phase, plot_cfg, 'psth');

t_frame_abs = traj.time(valid);
t_frame_rel = t_frame_abs - align_t;
t_frame_rel_clipped = min(max(t_frame_rel, traj_window(1)), traj_window(2));
t_keep = t_frame_rel >= traj_window(1) & t_frame_rel <= traj_window(2);
if nnz(t_keep) < 2
    trial_summary = [];
    return
end

t_frame_abs = t_frame_abs(t_keep);
t_frame_rel = t_frame_rel(t_keep);
x_keep = traj.head_x(valid);
y_keep = traj.head_y(valid);
x_keep = x_keep(t_keep);
y_keep = y_keep(t_keep);

t_start = round(align_t + psth_window(1));
t_end = round(align_t + psth_window(2));
t_grid_abs = t_start:t_end;
if isempty(t_grid_abs)
    trial_summary = [];
    return
end

spk_this = spk_times(spk_times >= t_start & spk_times <= t_end);
spk_train = histcounts(spk_this, [t_grid_abs-0.5, t_grid_abs(end)+0.5]);
sdf_abs = sdf(t_grid_abs/1000, spk_train, plot_cfg.kernel_width_ms, 0);
sdf_frame = interp1(t_grid_abs, sdf_abs, t_frame_abs, 'linear', 'extrap');

trial_summary = struct();
trial_summary.t_abs = t_frame_abs(:);
trial_summary.t_rel = t_frame_rel(:);
trial_summary.traj_x = traj.head_x(valid);
trial_summary.traj_y = traj.head_y(valid);
trial_summary.traj_t_rel = t_frame_rel(:);
trial_summary.traj_t_rel_clipped = t_frame_rel_clipped(:);
trial_summary.x = x_keep(:);
trial_summary.y = y_keep(:);
trial_summary.sdf_frame = sdf_frame(:);
trial_summary.spike_rel = spk_this(:) - align_t;
trial_summary.start_rel = min(t_frame_rel);
end

function valid = get_valid_traj_mask(traj)
valid = ~isnan(traj.head_x) & ~isnan(traj.head_y);
if ismember('kept_mask', traj.Properties.VariableNames)
    valid = valid & logical(traj.kept_mask);
end
if ismember('keep_run_mask', traj.Properties.VariableNames)
    valid = valid & logical(traj.keep_run_mask);
end
end

function window_ms = get_window_for_phase(phase_name, plot_cfg, mode_name)
switch char(phase_name)
    case 'Approach'
        switch mode_name
            case 'traj'
                window_ms = plot_cfg.traj_window_approach_ms;
            case 'psth'
                window_ms = plot_cfg.psth_window_approach_ms;
        end
    case 'Retrieval'
        switch mode_name
            case 'traj'
                window_ms = plot_cfg.traj_window_retrieval_ms;
            case 'psth'
                window_ms = plot_cfg.psth_window_retrieval_ms;
        end
    otherwise
        error('Unknown phase name: %s', phase_name);
end
end
