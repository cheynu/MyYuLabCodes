function fig = plotTrajUnitSummary(unit_summary, dataset, plot_cfg)
conditions = unit_summary.conditions;
cond_defs = dataset.cond_defs;
axis_cfg = dataset.axis_cfg;

fig = figure(10); clf(fig);
set(fig, 'Color', 'w', 'Units', 'centimeters', 'Position', [2 2 15.4 11.2], ...
    'PaperPositionMode', 'auto');

fr_max = 5;
for iCond = 1:numel(conditions)
    fr_max = max(fr_max, safe_nanmax(conditions(iCond).psth_fr));
    fr_max = max(fr_max, safe_nanmax(conditions(iCond).fr_by_x));
end
fr_ylim = [0 fr_max * 1.2];

left = 1;
col_w = 2.5;
gap_small = 0.4;
cb_w = 0.18;
gap_after_cb = 1.5;
x_col = zeros(1,4);
x_col(1) = left;
x_col(2) = x_col(1) + col_w + gap_small;
x_cb1 = x_col(2) + col_w + 0.10;
x_col(3) = x_cb1 + cb_w + gap_after_cb;
x_col(4) = x_col(3) + col_w + gap_small;
x_cb2 = x_col(4) + col_w + 0.10;

row_h1 = 2.5;
row_h2 = 1.7;
row_h3 = 2.25;
y_row3 = 1.1;
y_row2 = y_row3 + row_h3 + 1;
y_row1 = y_row2 + row_h2 + 0.5;

ax_top = gobjects(1,4);
for iCond = 1:numel(cond_defs)
    s = conditions(iCond);

    ax1 = axes(fig, 'Units', 'centimeters', 'Position', [x_col(iCond) y_row1 col_w row_h1]); hold(ax1, 'on');
    ax_top(iCond) = ax1;
    for iTrial = 1:s.n_trials
        tr = s.trials{iTrial};
        if isfield(tr, 'traj_x')
            x_plot = tr.traj_x;
            y_plot = tr.traj_y;
            c_plot = tr.traj_t_rel_clipped;
        else
            x_plot = tr.x;
            y_plot = tr.y;
            c_plot = tr.t_rel;
        end
        if numel(x_plot) < 2
            continue
        end
        surface(ax1, [x_plot x_plot], [y_plot y_plot], [c_plot c_plot], ...
            'EdgeColor', 'interp', 'FaceColor', 'none', 'LineWidth', 1.2);
    end
    title(ax1, sprintf('%s\nn = %d', cond_defs(iCond).title, s.n_trials));
    if iCond == 1
        ylabel(ax1, 'Head y (px)');
    else
        set(ax1, 'yticklabels', {});
    end
    set(ax1, 'YDir', 'reverse', 'Box', 'off', 'SortMethod', 'childorder');
    xlim(ax1, axis_cfg.xlim);
    ylim(ax1, axis_cfg.ylim);
    axis(ax1, 'equal');
    colormap(ax1, turbo);
    clim(ax1, s.traj_clim);

    ax2 = axes(fig, 'Units', 'centimeters', 'Position', [x_col(iCond) y_row2 col_w row_h2]); hold(ax2, 'on');
    plot(ax2, s.x_centers, s.fr_by_x, 'k', 'LineWidth', 1.6);
    xline(ax2, axis_cfg.anchor_x, '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 1);
    xlim(ax2, axis_cfg.xlim);
    ylim(ax2, fr_ylim);
    xlabel(ax2, 'Head x (px)');
    if iCond == 1
        ylabel(ax2, 'FR (Hz)');
    else
        set(ax2, 'yticklabels', {});
    end
    set(ax2, 'Box', 'off');

    ax3 = axes(fig, 'Units', 'centimeters', 'Position', [x_col(iCond) y_row3 col_w row_h3]); hold(ax3, 'on');
    plot_raster_background(ax3, s, axis_cfg.psth_xlim_ms(iCond, :), fr_ylim, plot_cfg.max_raster_trials);
    plot(ax3, s.psth_t, s.psth_fr, 'r', 'LineWidth', 1.6);
    xline(ax3, 0, ':k', 'LineWidth', 1);
    if ~isnan(s.mean_start_rel)
        xline(ax3, s.mean_start_rel, '--', 'Color', [0 0.45 0.74], 'LineWidth', 1);
    end
    xlim(ax3, axis_cfg.psth_xlim_ms(iCond, :));
    ylim(ax3, fr_ylim);
    xlabel(ax3, sprintf('Time from %s (ms)', pretty_event_name(cond_defs(iCond).align_event)));
    if iCond == 1
        ylabel(ax3, 'FR (Hz)');
    else
        set(ax3, 'yticklabels', {});
    end
    set(ax3, 'Box', 'off');
end

pos_ax2 = ax_top(2).Position;
cb1 = colorbar(ax_top(2), 'Units', 'centimeters');
ax_top(2).Position = pos_ax2;
cb1.Position = [x_cb1 y_row1 0.18 row_h1];
cb1.Label.String = 'Time from press (ms)';

pos_ax4 = ax_top(4).Position;
cb2 = colorbar(ax_top(4), 'Units', 'centimeters');
ax_top(4).Position = pos_ax4;
cb2.Position = [x_cb2 y_row1 0.18 row_h1];
cb2.Label.String = 'Time from poke (ms)';

sgtitle(fig, sprintf('Ch%d Unit%d | %s | Trajectory, FR-Loc, and PSTH', ...
    unit_summary.unit_id(1), unit_summary.unit_id(2), unit_summary.unit_quality_str), ...
    'FontSize', 12, 'fontname', 'deja vu sans');
end

function plot_raster_background(ax, cond_summary, time_range, fr_ylim, max_raster_trials)
hold(ax, 'on');
if cond_summary.n_trials == 0
    return
end

n_plot = min(cond_summary.n_trials, max(15, min(cond_summary.n_trials, max_raster_trials)));
trial_sel = round(linspace(1, cond_summary.n_trials, n_plot));
y_top = fr_ylim(2) * 0.98;
y_bottom = fr_ylim(2) * 0.52;
row_step = max((y_top - y_bottom) / max(15, n_plot), eps);
tick_height = row_step * 0.7;

for i = 1:numel(trial_sel)
    spk = cond_summary.raster_spikes{trial_sel(i)};
    spk = spk(spk >= time_range(1) & spk <= time_range(2));
    y0 = y_top - (i-1) * row_step;
    for j = 1:numel(spk)
        line(ax, [spk(j) spk(j)], [y0-tick_height y0], 'Color', 'k', 'LineWidth', 0.6);
    end
end
end

function label = pretty_event_name(event_name)
switch char(event_name)
    case 't_press'
        label = 'press';
    case 't_poke_first'
        label = 'poke';
    otherwise
        label = erase(char(event_name), 't_');
end
end

function out = safe_nanmax(x)
if isempty(x) || all(isnan(x(:)))
    out = 0;
else
    out = max(x(:), [], 'omitnan');
end
end
