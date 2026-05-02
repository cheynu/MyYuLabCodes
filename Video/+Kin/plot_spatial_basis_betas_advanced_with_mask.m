function hf = plot_spatial_basis_betas_advanced_with_mask(result, basis, trial_info, varargin)
% plot_spatial_basis_betas_advanced_with_mask
% Plot basis-reconstructed spatial tuning fields for selected body parts,
% plus velocity betas, in a multi-column layout, with occupancy-based mask
% overlaid on each spatial field.
%
% Works with:
%   1) single-fit result struct from fit_poisson_elasticnet_glm_by_trial
%   2) repeated-fit summary struct from fit_poisson_elasticnet_glm_repeated
%
% Layout:
%   row 1, col 1: example basis function
%   row 1, col 2..end: reconstructed tuning field for each body part
%   row 2, col 1: info panel
%   row 2, col 2..end: velocity betas for each body part

% -------------------- parse --------------------
p = inputParser;
p.addRequired('result', @(x) isstruct(x));
p.addRequired('basis', @(x) isstruct(x) && isfield(x, 'centers'));
p.addRequired('trial_info', @(x) isstruct(x));

p.addParameter('BodyParts', [], @(x) isempty(x) || iscell(x) || isstring(x));
p.addParameter('BodyPartColormaps', struct(), @(x) isstruct(x) || isa(x,'containers.Map'));
p.addParameter('IndependentColorLimits', true, @(x) islogical(x) && isscalar(x));

p.addParameter('FigureWidth', 16, @(x) isnumeric(x) && isscalar(x) && x > 5);
p.addParameter('FieldWidth', [], @(x) isnumeric(x) && isscalar(x) && x > 1);

p.addParameter('FigureName', 'Spatial tuning and velocity', @(x) ischar(x) || isstring(x));
p.addParameter('FigureTag', '', @(x) ischar(x) || isstring(x));
p.addParameter('SaveFigure', true, @(x) islogical(x) && isscalar(x));
p.addParameter('FigureNumber', 17, @(x) isnumeric(x) && isscalar(x));
p.addParameter('NumTrialsToPlot', 20, @(x) isnumeric(x) && x >= 1);
p.addParameter('BasisIndexToShow', [], @(x) isempty(x) || (isnumeric(x) && ~any(x<1)));
p.addParameter('MarkerSize', 18, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('TrajLineWidth', 0.15, @(x) isnumeric(x) && isscalar(x));
p.addParameter('ReverseY', true, @(x) islogical(x) && isscalar(x));
p.addParameter('FontName', 'Helvetica', @(x) ischar(x) || isstring(x));
p.addParameter('FontSize', 6, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('HorizontalGap', 1, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('VerticalGap', 1, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('SavePanelPNGs', true, @(x) islogical(x) && isscalar(x));
p.addParameter('VelocityPanelWidth', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x > .5));
p.addParameter('AddTrajsToField', true, @(x) islogical(x) && isscalar(x));
p.addParameter('PositionMode', 'basis', @(x) any(strcmpi(string(x), ["basis","bin"])));

% masking
p.addParameter('UseOccupancyMask', true, @(x) islogical(x) && isscalar(x));
p.addParameter('MaskColor', [.9 .9 .9], @(x) isnumeric(x) && numel(x)==3);
p.addParameter('MaskSmoothSigma', 1, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.addParameter('MaskQuantileNonzero', 0.01, @(x) isnumeric(x) && isscalar(x) && x >= 0 && x <= 1);
p.addParameter('MaskUseSmoothedOcc', true, @(x) islogical(x) && isscalar(x));
p.addParameter('UseMaskedRegionForCLim', true, @(x) islogical(x) && isscalar(x));

p.parse(result, basis, trial_info, varargin{:});
body_parts = p.Results.BodyParts;
bodypart_colormaps = p.Results.BodyPartColormaps;
independent_clim   = p.Results.IndependentColorLimits;
fig_width = p.Results.FigureWidth;
fig_name = char(string(p.Results.FigureName));
fig_tag = char(string(p.Results.FigureTag));
save_figure = p.Results.SaveFigure;
fig_num = p.Results.FigureNumber;
n_plot = p.Results.NumTrialsToPlot;
basis_idx_to_show = p.Results.BasisIndexToShow;
traj_lw = p.Results.TrajLineWidth;
reverse_y = p.Results.ReverseY;
font_name = char(string(p.Results.FontName));
font_size = p.Results.FontSize;
hgap = p.Results.HorizontalGap;
vgap = p.Results.VerticalGap;
save_panel_pngs = p.Results.SavePanelPNGs; %#ok<NASGU>
vel_panel_w = p.Results.VelocityPanelWidth;
add_trajs = p.Results.AddTrajsToField;
use_mask = p.Results.UseOccupancyMask;
mask_color = p.Results.MaskColor;
mask_smooth_sigma = p.Results.MaskSmoothSigma;
mask_quantile = p.Results.MaskQuantileNonzero;
mask_use_smoothed = p.Results.MaskUseSmoothedOcc;
use_masked_for_clim = p.Results.UseMaskedRegionForCLim;
field_map_width = p.Results.FieldWidth;
position_mode = lower(string(p.Results.PositionMode));

% colors
body_colors = struct();
body_colors.LeftEar  = [51 115 204] / 255;
body_colors.LeftPaw  = [241 101 34] / 255;
body_colors.RightPaw = [46 160 67] / 255;

% -------------------- detect mode --------------------
is_average_mode = isfield(result, 'field') && isfield(result, 'n_repeats');

% -------------------- body parts --------------------
if isempty(body_parts)
    if is_average_mode
        body_parts = fieldnames(result.field);
    else
        if ~isfield(result, 'beta_table')
            error('result.beta_table is required in single-fit mode.');
        end
        T = result.beta_table;
        if ~istable(T)
            error('result.beta_table must be a table.');
        end
        body_parts = local_infer_body_parts(T);
    end
else
    body_parts = cellstr(string(body_parts(:)));
end

n_body = numel(body_parts);
if n_body == 0
    error('No body parts found to plot.');
end

% if isempty(basis_idx_to_show)
%     [~, basis_idx_to_show] = min(sum(basis.centers.^2, 2));
% end
% basis_idx_to_show = min(max(1, basis_idx_to_show), basis.K);

% -------------------- prepare one field per body part --------------------
fields = cell(1, n_body);
field_clim = nan(n_body, 2);
mx_field_shared = 0.2;

for i = 1:n_body
    bp = body_parts{i};

    fields{i} = Kin.local_prepare_one_bodypart_map( ...
        result, basis, trial_info, bp, is_average_mode, ...
        'UseOccupancyMask', use_mask, ...
        'MaskSmoothSigma', mask_smooth_sigma, ...
        'MaskQuantileNonzero', mask_quantile, ...
        'MaskUseSmoothedOcc', mask_use_smoothed, ...
        'UseMaskedRegionForCLim', use_masked_for_clim,...
        'PositionMode', position_mode);

    field_clim(i,:) = fields{i}.clim;
    mx_field_shared = max(mx_field_shared, max(abs(fields{i}.clim)));
end

if mx_field_shared == 0
    mx_field_shared = 1;
end

mx_field_shared = round(mx_field_shared*10)/10;

% -------------------- extract velocity/speed betas --------------------
vx_beta = zeros(n_body,1);
vy_beta = zeros(n_body,1);
speed_beta = zeros(n_body,1);

if is_average_mode
    if ~isfield(result, 'velocity_beta')
        warning('Average result has no velocity_beta field. Using zeros.');
    end
    for i = 1:n_body
        bp = body_parts{i};
        if isfield(result, 'velocity_beta') && isfield(result.velocity_beta, bp)
            vx_beta(i) = getfield_safe(result.velocity_beta.(bp), 'vx_mean', 0);
            vy_beta(i) = getfield_safe(result.velocity_beta.(bp), 'vy_mean', 0);
            speed_beta(i) = getfield_safe(result.velocity_beta.(bp), 'speed_mean', 0);
        end
    end
else
    T = result.beta_table;
    for i = 1:n_body
        vx_beta(i) = local_extract_scalar_beta(T, sprintf('%s_vx_cm_s', body_parts{i}));
        vy_beta(i) = local_extract_scalar_beta(T, sprintf('%s_vy_cm_s', body_parts{i}));
        speed_beta(i) = local_extract_scalar_beta(T, sprintf('%s_speed_cm_s', body_parts{i}));
    end
end

mx_vel = max(abs([vx_beta(:); vy_beta(:); speed_beta(:)]));
if mx_vel == 0
    mx_vel = 1;
end

% -------------------- layout --------------------
ncol = 1 + n_body;

left = 0.9;
right = 0.9;
top = 1.3;
bottom = 0.8;
cb_w = 0.15;
title_h = 0.55;

usable_w = fig_width - left - right - (ncol-1)*hgap;

col_w = usable_w / ncol;

if ~isempty(field_map_width)
    col_w = field_map_width;
end

if isempty(vel_panel_w)
    vel_panel_w = col_w;
end

x_lim = [basis.x_range(1), basis.x_range(2)];
y_lim = [basis.y_range(1), basis.y_range(2)];
xy_aspect = diff(y_lim) / diff(x_lim);
row1_h = col_w * xy_aspect;
row2_h = row1_h;

fig_height = bottom + row2_h + vgap + row1_h + top + title_h;

% -------------------- figure --------------------
hf = figure(fig_num); clf(hf);
set(hf, 'Color', 'w', ...
    'Units', 'centimeters', ...
    'Position', [2 2 fig_width fig_height], ...
    'Name', fig_name, ...
    'Visible', 'on');

if is_average_mode
    title_str = sprintf('%s\nAverage across %d splits \n%s', fig_name, result.n_repeats, string(result.unit_id));
else
    if isfield(result, 'unit_id')
        title_str = sprintf('%s\n%s', fig_name, string(result.unit_id));
    else
        title_str = fig_name;
    end
end

annotation(hf, 'textbox', ...
    'Units', 'centimeters', ...
    'Position', [left, fig_height-top-title_h+.5, fig_width-left-right, title_h], ...
    'String', title_str, ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontWeight', 'bold', ...
    'FontName', font_name, ...
    'FontSize', font_size+1, ...
    'Interpreter', 'none');

row1_y = bottom + row2_h + vgap;
row2_y = bottom;

rng(41);
n_trials_total = numel(trial_info);
n_plot = min(n_plot, n_trials_total);
trial_sel = randperm(n_trials_total, n_plot);

% ============================================================
% row 1 col 1: example basis function
% ============================================================
x0 = left;
ax = axes('Parent', hf, 'Units', 'centimeters', ...
    'Position', [x0 row1_y col_w row1_h], ...
    'FontName', font_name, 'FontSize', font_size, ...
    'LineWidth', 0.5, 'Box', 'off');
hold(ax, 'on');

if strcmp(position_mode, "basis")
    if any(basis_idx_to_show)
        [basis_field, xq, yq] = local_eval_one_basis(basis, basis_idx_to_show, 120);
        imagesc(ax, xq, yq, basis_field, 'CDataMapping', 'scaled');
    end
else
    Kin.plot_xy_bin_grid(ax, basis, 'ShowCenters', false, 'BinPlot', basis_idx_to_show);
end

set(ax, 'YDir', ternary(reverse_y, 'reverse', 'normal'));
axis(ax, 'equal');
axis(ax, [x_lim y_lim]);
plot(ax, basis.centers(:,1), basis.centers(:,2), 'w+', 'MarkerSize', 2, 'LineWidth', 0.5);

for i = 1:numel(body_parts)
    bp = body_parts{i};
    if isfield(body_colors, bp)
        local_plot_bodypart_trajectories(ax, trial_info, bp, trial_sel(1:1:length(trial_sel)), 0.25, body_colors.(bp));
    else
        local_plot_bodypart_trajectories(ax, trial_info, bp, trial_sel(1:1:length(trial_sel)), 0.25, [.8 .8 .8]);
    end
end
scatter(ax, 0, 0, 'o', 'MarkerFaceColor', 'r','MarkerEdgeColor', 'none', 'SizeData', 15);
colormap(ax, parula);
xlabel(ax, 'x (cm)');
ylabel(ax, 'y (cm)');
title(ax, sprintf('Example basis function (%02d)', basis_idx_to_show), ...
    'FontName', font_name, 'FontSize', font_size);
grid(ax, 'off');

if any(basis_idx_to_show)
    hbar = colorbar(ax);
    hbar.Units = 'centimeters';
    hbar.Position(1) = ax.Position(1)+ax.Position(3)+0.1;
    hbar.Position(2) = ax.Position(2);
    hbar.Position(3) = cb_w;
    hbar.Position(4) = ax.Position(4);
end

% ============================================================
% row 1 col 2..end: masked spatial fields
% ============================================================
field_axes = gobjects(n_body,1);

for i = 1:n_body
    bp = body_parts{i};
    Fi = fields{i};

    x0 = left + i*(col_w + hgap);
    ax = axes('Parent', hf, 'Units', 'centimeters', ...
        'Position', [x0 row1_y col_w row1_h], ...
        'FontName', font_name, 'FontSize', font_size, ...
        'XTick', [], 'YTick', [], ...
        'LineWidth', 0.5, 'Box', 'off');
    hold(ax, 'on');
    imagesc(ax, Fi.xq, Fi.yq, Fi.F, 'CDataMapping', 'scaled');
    set(ax, 'YDir', ternary(reverse_y, 'reverse', 'normal'));
    axis(ax, 'equal');
    axis(ax, [x_lim y_lim]);
    axis(ax, 'off')
    % plot(ax, basis.centers(:,1), basis.centers(:,2), ...
    %     'k+', 'MarkerSize', 2, 'LineWidth', 0.5);

    if add_trajs
        if isfield(body_colors, bp)
            local_plot_bodypart_trajectories(ax, trial_info, bp, trial_sel(1:length(trial_sel)), traj_lw, body_colors.(bp));
        else
            local_plot_bodypart_trajectories(ax, trial_info, bp, trial_sel(1:length(trial_sel)), traj_lw, [.25 .25 .25]);
        end
    end

    colormap(ax, local_get_bodypart_colormap(bp, bodypart_colormaps));

    if independent_clim
        if abs(Fi.clim)>0.2 
            max_c = max(Fi.clim);
            max_c = ceil(max_c*10)/10;
            Fi.clim = [-max_c max_c];
            clim(ax, Fi.clim);
        else
            clim(ax, [-.2 .2]);
        end
    else
        if abs(mx_field_shared)>0.2
        clim(ax, [-mx_field_shared mx_field_shared]);
        else
        clim(ax, [-0.2 0.2]);
        end
    end

    if use_mask
        unsupported = ~Fi.support_mask;
        mask_rgb = zeros([size(unsupported), 3]);
        for c = 1:3
            mask_rgb(:,:,c) = mask_color(c);
        end
        hmask = image(ax, Fi.xq, Fi.yq, mask_rgb);
        set(hmask, 'AlphaData', double(unsupported));
        uistack(hmask, 'top');
    end

    if is_average_mode
        title(ax, sprintf('%s (mean)', bp), ...
            'FontName', font_name, 'FontSize', font_size-1, 'Interpreter', 'none');
    else
        title(ax, sprintf('%s', bp), ...
            'FontName', font_name, 'FontSize', font_size-1, 'Interpreter', 'none');
    end
    scatter(ax, 0, 0, 'o', ...
        'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'none', 'SizeData', 15);

    grid(ax, 'off');
    field_axes(i) = ax;

    cb_x = x0;
    cb_y = row1_y - cb_w - .25;

    cb = colorbar(ax, 'southoutside');
    cb.Units = 'centimeters';
    cb.Position = [cb_x cb_y col_w 0.1];
    cb.FontName = font_name;
    cb.FontSize = font_size;
    cb.TickLabelInterpreter = 'none';

    mx = max(abs(clim(ax)));
    if mx > 0.1
        tick_max = ceil(mx*10)/10;
        cb.Ticks = [-tick_max 0 tick_max];
        cb.TickLabels = compose('%.1f', cb.Ticks);
    end

    if i == 1
        cb.Label.String = 'log-rate contribution';
    end
end

% ============================================================
% row 2 col 1: info panel
% ============================================================
x0 = left-0.75;
ax = axes('Parent', hf, 'Units', 'centimeters', ...
    'Position', [x0 row2_y col_w row2_h], ...
    'Visible', 'off');
hold(ax, 'on');

txt = local_make_info_text(result, basis, body_parts, is_average_mode, position_mode);
text(ax, 0, 1, txt, ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'top', ...
    'FontName', font_name, ...
    'FontSize', font_size, ...
    'Interpreter', 'none');

% ============================================================
% row 2 col 2..end: velocity betas
% ============================================================
for i = 1:n_body
    x_center = left + i*(col_w + hgap) + col_w/2;
    x0 = x_center - vel_panel_w/2;

    ax = axes('Parent', hf, 'Units', 'centimeters', ...
        'Position', [x0 row2_y vel_panel_w row2_h], ...
        'FontName', font_name, 'FontSize', font_size, ...
        'LineWidth', 0.5, 'Box', 'off');
    hold(ax, 'on');

    vals = [vx_beta(i) vy_beta(i) speed_beta(i)];
    bar(ax, 1:3, vals, 0.75, ...
        'FaceColor', 'k', 'EdgeColor', 'none');

    xlim(ax, [0.4 3.6]);
    xticks(ax, 1:3);
    xticklabels(ax, {'vx','vy','speed'});
    if i == 1
        ylabel(ax, '\beta');
    end

    if i>1
        ax.YTickLabel = [];
    end

    if is_average_mode
        title(ax, sprintf('%s (mean)', body_parts{i}), ...
            'FontName', font_name, 'FontSize', font_size, 'Interpreter', 'none');
    else
        title(ax, sprintf('%s', body_parts{i}), ...
            'FontName', font_name, 'FontSize', font_size, 'Interpreter', 'none');
    end

    ylim(ax, local_nice_ylim([-mx_vel mx_vel]));
    yline(ax, 0, ':', 'LineWidth', 0.5, 'Color', [0.6 0.6 0.6]);
    grid(ax, 'off');
end

% -------------------- save --------------------
if save_figure
    adjust_figure_size(hf, 1);
    if is_average_mode
        figName = sprintf('spatial_tuning_and_velocity_avg_%s_%s', ...
            local_safe_str(getfield_safe(result, 'unit_id', 'unit')), fig_tag);
    else
        figName = sprintf('spatial_tuning_and_velocity_%s_%s', ...
            local_safe_str(getfield_safe(result, 'unit_id', 'unit')), fig_tag);
    end

    outFolder = fullfile(pwd, 'figure', 'glm');
    if ~exist(outFolder, 'dir')
        mkdir(outFolder);
    end
    save_fig(hf, figName, outFolder, "Format", {"png","pdf","svg"});
    write_meta( ...
        figName, ...
        'MetaFolder', outFolder, ...
        'Description', 'Basis-reconstructed spatial tuning fields and velocity betas from GLM, with occupancy-based masking', ...
        'Purpose', 'To visualize spatial tuning fields and velocity betas for selected body parts', ...
        'GeneratorFunction', 'Kin.plot_spatial_basis_betas_advanced.m', ...
        'GeneratorScript', '', ...
        'Inputs', { ...
            sprintf('is_average_mode: %d', is_average_mode), ...
            sprintf('body_parts: %s', strjoin(string(body_parts), ', ')), ...
            sprintf('figure_tag: %s', string(fig_tag)), ...
            sprintf('use_mask: %d', use_mask), ...
            sprintf('mask_quantile: %.4f', mask_quantile) ...
        });
end

end

% ============================================================
% helpers
% ============================================================

function body_parts = local_infer_body_parts(T)
fn = string(T.feature_name);
body_parts = strings(0,1);

for i = 1:numel(fn)
    tok = regexp(fn(i), '^(.*)_basis_\d+$', 'tokens', 'once');
    if ~isempty(tok)
        body_parts(end+1,1) = string(tok{1}); %#ok<AGROW>
        continue
    end
    tok = regexp(fn(i), '^(.*)_v[xy]_cm_s$', 'tokens', 'once');
    if ~isempty(tok)
        body_parts(end+1,1) = string(tok{1}); %#ok<AGROW>
    end
end

body_parts = unique(body_parts, 'stable');
body_parts = cellstr(body_parts);
end

function b = local_extract_scalar_beta(T, feature_name)
fn = string(T.feature_name);
idx = find(fn == string(feature_name), 1);
if isempty(idx)
    b = 0;
else
    b = T.beta(idx);
end
end

function yl = local_nice_ylim(raw_lim)
mx = max(abs(raw_lim));
if mx == 0
    mx = 1;
end
yl = [-1.05*mx, 1.05*mx];
end

function [F, xq, yq] = local_eval_one_basis(basis, k, ngrid)
xq = linspace(basis.x_range(1), basis.x_range(2), ngrid);
yq = linspace(basis.y_range(1), basis.y_range(2), ngrid);
[Xq, Yq] = meshgrid(xq, yq);

cx = basis.centers(k,1);
cy = basis.centers(k,2);

F = exp( ...
    -0.5 * ((Xq - cx) ./ basis.sigma_x).^2 ...
    -0.5 * ((Yq - cy) ./ basis.sigma_y).^2 );
end

function local_plot_bodypart_trajectories(ax, trial_info, body_part, trial_sel, lw, lc)
for ii = 1:numel(trial_sel)
    k = trial_sel(ii);
    if isfield(trial_info(k), body_part) && ...
            isfield(trial_info(k).(body_part), 'x_rel_cm') && ...
            isfield(trial_info(k).(body_part), 'y_rel_cm')
        x = trial_info(k).(body_part).x_rel_cm;
        y = trial_info(k).(body_part).y_rel_cm;
        if ~isempty(x) && ~isempty(y)
            plot(ax, x, y, 'k-', 'LineWidth', lw, 'Color', lc);
        end
    end
end
end


function txt = local_make_info_text(result, basis, body_parts, is_average_mode, position_mode)
if is_average_mode
    pr2_median = getfield_safe(result, 'pR2_test_median', NaN);
    lam_mean = getfield_safe(result, 'lambda_best_mean', NaN);
    n_rep    = getfield_safe(result, 'n_repeats', NaN);

    if strcmp(position_mode, "basis")
        txt = sprintf([ ...
            'average result\n' ...
            'test pR^2 median: %.4f\n' ...
            'lambda mean: %.4g\n' ...
            'n repeats: %d\n' ...
            'basis: %d x %d (%d)\n' ...
            '\\sigma_x: %.3g\n' ...
            '\\sigma_y: %.3g\n' ...
            'body parts: %s'], ...
            pr2_median, lam_mean, n_rep, ...
            basis.nx, basis.ny, basis.K, ...
            basis.sigma_x, basis.sigma_y, strjoin(body_parts, ', '));
    else
        txt = sprintf([ ...
            'average result\n' ...
            'test pR^2 median: %.4f\n' ...
            'lambda mean: %.4g\n' ...
            'n repeats: %d\n' ...
            'basis: %d x %d (%d)\n' ...
            'body parts: %s'], ...
            pr2_median, lam_mean, n_rep, ...
            basis.nx, basis.ny, basis.K, ...
            strjoin(body_parts, ', '));
    end
else
    u = getfield_safe(result, 'unit_id', '');
    pr2 = getfield_safe(result, 'pR2_test', NaN);
    lam = getfield_safe(result, 'lambda_best', NaN);

    if strcmp(position_mode, "basis")
        txt = sprintf([ ...
            'unit: %s\n' ...
            'test pR^2: %.4f\n' ...
            'lambda: %.4g\n' ...
            'basis: %d x %d (%d)\n' ...
            '\\sigma_x: %.3g\n' ...
            '\\sigma_y: %.3g\n' ...
            'body parts: %s'], ...
            string(u), pr2, lam, basis.nx, basis.ny, basis.K, ...
            basis.sigma_x, basis.sigma_y, strjoin(body_parts, ', '));
    else
        txt = sprintf([ ...
            'unit: %s\n' ...
            'test pR^2: %.4f\n' ...
            'lambda: %.4g\n' ...
            'basis: %d x %d (%d)\n' ...
            'body parts: %s'], ...
            string(u), pr2, lam, ...
            basis.nx, ...
            basis.ny, ...
            basis.K, ...
            strjoin(body_parts, ', '));
    end
end
end

function out = getfield_safe(S, field_name, default_val)
if isfield(S, field_name)
    out = S.(field_name);
else
    out = default_val;
end
end

function out = local_safe_str(x)
x = string(x);
x = regexprep(x, '[^\w-]+', '_');
out = char(x);
end

function out = ternary(cond, a, b)
if cond
    out = a;
else
    out = b;
end
end

function cmap = local_get_bodypart_colormap(body_part, cmap_spec)
if isstruct(cmap_spec) && isfield(cmap_spec, body_part)
    cmap = cmap_spec.(body_part);
    return
end

if isa(cmap_spec, 'containers.Map') && isKey(cmap_spec, body_part)
    cmap = cmap_spec(body_part);
    return
end

cmap = customcolormap(linspace(0,1,11), ...
    {'#68011d','#b5172f','#d75f4e','#f7a580','#fedbc9', ...
     '#f5f9f3','#d5e2f0','#93c5dc','#4295c1','#2265ad','#062e61'});
end