function dataset = buildTrajConditionDataset(tab, anchor, plot_cfg)
% Build a session-level top-view dataset that can be reused across units
% and sessions without re-reading raw DLC / ephys files.

n_trial = height(tab);
prev_rewarded = false(n_trial, 1);
if n_trial > 1
    prev_rewarded(2:end) = strcmp(string(tab.reward(1:end-1)), "Rewarded");
end

has_approach = cellfun(@(x) ~isempty(x), tab.Traj_Approach);
has_retrieval = cellfun(@(x) ~isempty(x), tab.Traj_Retrieval);
is_bad_poke = strcmp(string(tab.reward), "Bad");

cond_defs = struct( ...
    'name', {'PostRewardApproach', 'PostUnrewardApproach', 'GoodPokeRetrieval', 'BadPokeRetrieval'}, ...
    'title', {'Approach | post-reward', 'Approach | post-unreward', 'Retrieval | good poke', 'Retrieval | bad poke'}, ...
    'phase', {'Approach', 'Approach', 'Retrieval', 'Retrieval'}, ...
    'traj_var', {'Traj_Approach', 'Traj_Approach', 'Traj_Retrieval', 'Traj_Retrieval'}, ...
    'align_event', {'t_press', 't_press', 't_poke_first', 't_poke_first'}, ...
    'start_event', {'', '', 't_release', 't_release'}, ...
    'row_mask', { ...
        has_approach & prev_rewarded, ...
        has_approach & ~prev_rewarded, ...
        has_retrieval & ~is_bad_poke, ...
        has_retrieval & is_bad_poke});

axis_cfg = compute_shared_axis_config(tab, cond_defs, plot_cfg, anchor);

dataset = struct();
dataset.tab = tab;
dataset.anchor = anchor;
dataset.cond_defs = cond_defs;
dataset.axis_cfg = axis_cfg;
dataset.plot_cfg = plot_cfg;
end

function axis_cfg = compute_shared_axis_config(tab, cond_defs, plot_cfg, anchor)
all_x = [];
all_y = [];
axis_cfg.traj_clim_ms = zeros(numel(cond_defs), 2);
axis_cfg.psth_xlim_ms = zeros(numel(cond_defs), 2);
axis_cfg.anchor_x = anchor.x_px;
axis_cfg.anchor_y = anchor.y_px;

for iCond = 1:numel(cond_defs)
    if strcmp(cond_defs(iCond).phase, 'Approach')
        axis_cfg.traj_clim_ms(iCond, :) = plot_cfg.traj_window_approach_ms;
        axis_cfg.psth_xlim_ms(iCond, :) = plot_cfg.psth_window_approach_ms;
    else
        axis_cfg.traj_clim_ms(iCond, :) = plot_cfg.traj_window_retrieval_ms;
        axis_cfg.psth_xlim_ms(iCond, :) = plot_cfg.psth_window_retrieval_ms;
    end
end

for iCond = 1:numel(cond_defs)
    row_idx = find(cond_defs(iCond).row_mask);
    for iRow = row_idx(:)'
        traj = tab.(cond_defs(iCond).traj_var){iRow};
        if isempty(traj)
            continue
        end
        valid = get_valid_traj_mask(traj);
        if nnz(valid) < plot_cfg.min_frames
            continue
        end
        align_t = tab.(cond_defs(iCond).align_event)(iRow);
        if isnan(align_t)
            continue
        end
        all_x = [all_x; traj.head_x(valid)]; %#ok<AGROW>
        all_y = [all_y; traj.head_y(valid)]; %#ok<AGROW>
    end
end

if isempty(all_x)
    axis_cfg.xlim = [0 800];
    axis_cfg.ylim = [0 450];
else
    axis_cfg.xlim = [floor(min(all_x)), ceil(max(all_x))];
    axis_cfg.ylim = [floor(min(all_y)), ceil(max(all_y))];
end
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
