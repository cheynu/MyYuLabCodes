function [score_tbl, S0] = time_shift_2d_map(B, trial_info, params, shifts_ms, shifts_ms_plot, range)

% related to   B = Kin.glm_side.add_spike_counts_to_bins(B, spike_times_ms, unit);
% if shfits_ms is empty, we plot only one map, otherwise, we also plot a range
% of maps in 2 rows.
score_tbl = [];

fig_x = 2;
fig_y = 2;
fig_width = 7;
fig_height = 6;

% --- start a new fig ---
hf = start_fig('fig', 15, 'name', 'spike-body map', ...
    'position', [fig_x, fig_y, fig_width, fig_height], 'Visible', 'on');

% --- compute 2d rate map ---
M = Kin.compute_2d_rate_map(B, params);
S0 = Kin.score_2d_rate_map(M, []);

xp = 1.25;
yp = 1;
panel_width = 4.5;
x_lim = [min(M.x_edges) max(M.x_edges)];
y_lim = [min(M.y_edges) max(M.y_edges)];
panel_height = diff(y_lim)*panel_width/diff(x_lim);

ax = start_axes(...
    hf, [xp yp panel_width panel_height], ...
    'xlim', x_lim, ...
    'ylim', y_lim, ...
    'ytick', (0:2:10),...
    'xtick', (0:2:10),...
    'ygrid', 'on');

map_name = 'rate_smooth_hz';
opts.ax = ax;
opts.mask_color = [1 1 1];
opts.title = M.unit_id;
opts.tosave = false;
opts.range = range;
opts.plot_bar = false;

Kin.plot2dmap_side(M, map_name, opts);

% --- add a color bar ---
hbar = colorbar(ax);
hbar.Label.String = strrep(map_name, '_', '\_');
hbar.Units = 'centimeters';
hbar.Position(1) = panel_width+xp+0.1;
hbar.Position(2) = ax.Position(2);
hbar.Position(3) = 0.25;
hbar.Position(4) = ax.Position(4);

% --- plot trajectory ---
rng(40)
n_plot = 25;
k = randperm(numel(trial_info),n_plot);
for i =1:n_plot
    plot(trial_info(k(i)).(params.body).x_rel_cm, trial_info(k(i)).(params.body).y_rel_cm, 'r-');
    plot(0, 0, 'wo', 'MarkerFaceColor', 'r'); % anchor
end

hf = gcf;
adjust_figure_size(hf, 1);
figName = sprintf('kinematics_side_%s_%s_fig1_zero_shift', M.unit_id, params.body);
outFolder = fullfile(pwd, 'figure', 'side_2d');
if ~exist(outFolder, 'dir')
    mkdir(outFolder)
end
save_fig(hf, figName, outFolder, 'Formats', {"png"});

%% Plot shiftted data

% --- initialize score table ---
score_rows = [];
score_rows = [score_rows; struct2table(struct( ...
    'shift_ms', 0, ...
    'peak_rate_hz', S0.peak_rate_hz, ...
    'peak_local10_mean_hz', S0.peak_local10_mean_hz,...
    'map_var_hz2', S0.map_var_hz2, ...
    'contrast_hz', S0.contrast_hz, ...
    'corr_with_zero', 1, ...
    'spread_cm', S0.spread_cm, ...
    'compactness_inv_cm', S0.compactness_inv_cm, ...
    'n_valid_bins', S0.n_valid_bins ...
    ))];

if isempty(shifts_ms)
    return
end

params_shift = params;
params_shift.x_col = [params.x_col '_shift'];
params_shift.y_col = [params.y_col '_shift'];
params_shift.x_edges = M.x_edges;
params_shift.y_edges = M.y_edges;

fig_x = 2;
fig_y = 2;
fig_width = 7;
fig_height = 6;

% --- start a new fig ---
hf2 = start_fig('fig', 16, 'name', 'spike-body map', ...
    'position', [fig_x, fig_y, fig_width, fig_height], 'Visible', 'on');

xp = .5;
yp = 1;
panel_width = 2;

h_gap = 0.25;
v_gap = 0.5;

x_lim = [min(M.x_edges) max(M.x_edges)];
y_lim = [min(M.y_edges) max(M.y_edges)];
panel_height = diff(y_lim)*panel_width/diff(x_lim);
yp_neg = yp;
yp_pos = yp+panel_height+v_gap;

% plot the same zero-shift map
ax = start_axes(...
    hf2, [xp yp_neg panel_width panel_height], ...
    'xlim', x_lim, ...
    'ylim', y_lim, ...
    'ytick', (0:2:10),...
    'xtick', (0:2:10),...
    'ygrid', 'on');

opts.ax = ax;
opts.mask_color = [1 1 1];
opts.title = sprintf('0 ms');
opts.tosave = false;
opts.range = range;
opts.plot_bar = false;
Kin.plot2dmap_side(M, map_name, opts);
ax.XTick = [];
ax.YTick = [];
ax.XLabel.String = [];
ax.YLabel.String = [];

ax = start_axes(...
    hf2, [xp yp_pos panel_width panel_height], ...
    'xlim', x_lim, ...
    'ylim', y_lim, ...
    'ytick', (0:2:10),...
    'xtick', (0:2:10),...
    'ygrid', 'on');
opts.ax = ax;
Kin.plot2dmap_side(M, map_name, opts);
ax.XTick = [];
ax.YTick = [];
ax.XLabel.String = [];
ax.YLabel.String = [];
%
xp = xp+panel_width+h_gap;
bin_ms = mode(diff(B.time_bin_start));

x_now = 0;
y_now = 0;
for i =1:numel(shifts_ms)

    signs = [1 -1];
    yps = [yp_pos yp_neg];

    for k = 1:numel(signs)
        % positive shift
        shift_ms = shifts_ms(i)*signs(k);
        ind = find(shifts_ms_plot == shifts_ms(i));
        B2 = Kin.shift_body_coordinates_by_trial( ...
            B, ...
            params.x_col, ...
            params.y_col, ...
            params.valid_col, ...
            shift_ms, ...
            bin_ms);

        M_shift = Kin.compute_2d_rate_map(B2, params_shift);
        S = Kin.score_2d_rate_map(M_shift, M);
        score_rows = [score_rows; struct2table(struct( ...
            'shift_ms', shift_ms, ...
            'peak_rate_hz', S.peak_rate_hz, ...
            'peak_local10_mean_hz', S.peak_local10_mean_hz,...
            'map_var_hz2', S.map_var_hz2, ...
            'contrast_hz', S.contrast_hz, ...
            'corr_with_zero', S.corr_with_zero, ...
            'spread_cm', S.spread_cm, ...
            'compactness_inv_cm', S.compactness_inv_cm, ...
            'n_valid_bins', S.n_valid_bins ...
            ))];

        if any(ind)
            % --- plot positively-shifted map ---
            ax = start_axes(...
                hf2, [xp+(ind-1)*(panel_width+h_gap) yps(k) panel_width panel_height], ...
                'xlim', x_lim, ...
                'ylim', y_lim, ...
                'ytick', (0:2:10),...
                'xtick', (0:2:10),...
                'ygrid', 'on');

            opts.ax = ax;
            opts.title = sprintf('%d ms', shift_ms);
            Kin.plot2dmap_side(M_shift, map_name, opts);

            ax.XTick = [];
            ax.YTick = [];
            ax.XLabel.String = [];
            ax.YLabel.String = [];

            x_now = max(x_now, ax.Position(1)+ax.Position(3));
            y_now = max(y_now, ax.Position(2)+ax.Position(4));
        end
    end
end

score_tbl = sortrows(score_rows, 'shift_ms');

% --- add a color bar ---
hbar = colorbar(ax);
hbar.Label.String = strrep(map_name, '_', '\_');
hbar.Units = 'centimeters';
hbar.Position(1) = x_now+0.25;
hbar.Position(2) = yp_neg;
hbar.Position(3) = 0.25;
hbar.Position(4) = y_now-yp_neg;

str = sprintf('time shift rate map (%s)', M.unit_id);
hf2 = figure(hf2);
annotation(hf2, 'textbox', ...
    'Units', 'centimeters', ...
    'Position', [1, yp_pos + panel_height + 1, 4, 0.5], ...
    'String', str, ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontWeight', 'bold', ...
    'FontName', 'Helvetica', 'Interpreter','none');


adjust_figure_size(hf2, 1);
figName = sprintf('kinematics_side_%s_%s_fig2_shift', M.unit_id, params.body);
outFolder = fullfile(pwd, 'figure', 'side_2d');
if ~exist(outFolder, 'dir')
    mkdir(outFolder)
end
save_fig(hf2, figName, outFolder, 'Formats', {"png"});
%% Plot metric

fig_x = 2;
fig_y = 2;
fig_width = 15;
fig_height = 9;

% --- start a new fig ---
hf3 = start_fig('fig', 17, 'name', 'spike-body map', ...
    'position', [fig_x, fig_y, fig_width, fig_height], 'Visible', 'on');

% 1) peak rate
subplot(2,2,1);
plot(score_tbl.shift_ms, score_tbl.peak_local10_mean_hz, '-o', 'LineWidth', 1.5, 'MarkerSize', 5);
hold on;
xline(0, '--k');
xlabel('Shift (ms)');
ylabel('Peak local-mean-rate (Hz)');
title('Peak local-mean-rate');
box off;

% 2) contrast
subplot(2,2,2);
plot(score_tbl.shift_ms, score_tbl.contrast_hz, '-o', 'LineWidth', 1.5, 'MarkerSize', 5);
hold on;
xline(0, '--k');
xlabel('Shift (ms)');
ylabel('Contrast (Hz)');
title('Map contrast');
box off;

% 3) variance
subplot(2,2,3);
plot(score_tbl.shift_ms, score_tbl.map_var_hz2, '-o', 'LineWidth', 1.5, 'MarkerSize', 5);
hold on;
xline(0, '--k');
xlabel('Shift (ms)');
ylabel('Variance (Hz^2)');
title('Spatial variance');
box off;

% 4) compactness
subplot(2,2,4);
plot(score_tbl.shift_ms, score_tbl.compactness_inv_cm, '-o', 'LineWidth', 1.5, 'MarkerSize', 5);
hold on;
xline(0, '--k');
xlabel('Shift (ms)');
ylabel('Compactness (1/cm)');
title('Compactness');
box off;

figName = sprintf('kinematics_side_%s_%s_fig3_metric', M.unit_id, params.body);
outFolder = fullfile(pwd, 'figure', 'side_2d');
if ~exist(outFolder, 'dir')
    mkdir(outFolder)
end
save_fig(hf3, figName, outFolder, 'Formats', {"png"});

% save score_tbl
tabName = sprintf('kinematics_side_%s_%s_time_shift_metric.csv', M.unit_id, params.body);
outFolder = fullfile(pwd, 'Data', 'Processed');
if ~exist(outFolder, 'dir')
    mkdir(outFolder)
end
writetable(score_tbl, tabName)

metaDir = outFolder;
write_meta( ...
    tabName, ...
    'MetaFolder', metaDir,...
    'Description', 'Compare rate-kinematics map across different time lags', ...
    'Purpose', 'To show the temporal relationship between body and spikes', ...
    'GeneratorFunction', 'Kin.time_shift_2d_map.m', ...
    'GeneratorScript', 'fit_side_glm_for_unit_script.mlx', ...
    'Inputs', {'Check the script'});

end

