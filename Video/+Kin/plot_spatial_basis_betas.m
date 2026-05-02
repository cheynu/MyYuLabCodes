function hf = plot_spatial_basis_betas(result, basis, trial_info, varargin)
%PLOT_SPATIAL_BASIS_BETAS
% Plot basis-reconstructed spatial tuning fields for selected body parts,
% plus velocity betas, in a multi-column layout.
%
% Layout:
%   row 1, col 1: example basis function
%   row 1, col 2..end: reconstructed tuning field for each body part
%   row 2, col 1: info panel
%   row 2, col 2..end: velocity betas for each body part
%
% Required inputs
%   result      fitted GLM result, must contain:
%                 .beta_table
%                 .unit_id   (optional)
%                 .pR2_test  (optional)
%                 .lambda_best (optional)
%   basis       basis struct, must contain:
%                 .centers, .sigma_x, .sigma_y, .x_range, .y_range, .K
%   trial_info   struct array with trial trajectories, expected format:
%                 trial_info(k).(body_part).x_rel_cm
%                 trial_info(k).(body_part).y_rel_cm
%
% Name-value
%   'BodyParts'        cellstr/string of body parts to plot
%                      default: inferred from result.beta_table basis features
%   'FigureWidth'      figure width in cm, default 16
%   'FigureName'       default 'Spatial tuning and velocity'
%   'FigureTag'        default ''
%   'SaveFigure'       default true
%   'FigureNumber'     default 17
%   'NumTrialsToPlot'  default 20
%   'BasisIndexToShow' default: center nearest origin
%   'MarkerSize'       default 18
%   'TrajLineWidth'    default 0.15
%   'ReverseY'         default true
%   'FontName'         default 'Helvetica'
%   'FontSize'         default 7
%   'HorizontalGap'    default 1 cm
%   'VerticalGap'      default 1 cm

% Notes
%   This function assumes basis features are named like:
%       <BodyPart>_basis_01, ..., <BodyPart>_basis_K
%   and velocity features are named like:
%       <BodyPart>_vx_cm_s, <BodyPart>_vy_cm_s

% -------------------- parse --------------------
p = inputParser;
p.addRequired('result', @(x) isstruct(x));
p.addRequired('basis', @(x) isstruct(x) && isfield(x, 'centers'));
p.addRequired('trial_info', @(x) isstruct(x));

p.addParameter('BodyParts', [], @(x) isempty(x) || iscell(x) || isstring(x));
p.addParameter('FigureWidth', 16, @(x) isnumeric(x) && isscalar(x) && x > 5);
p.addParameter('FigureName', 'Spatial tuning and velocity', @(x) ischar(x) || isstring(x));
p.addParameter('FigureTag', '', @(x) ischar(x) || isstring(x));
p.addParameter('SaveFigure', true, @(x) islogical(x) && isscalar(x));
p.addParameter('FigureNumber', 17, @(x) isnumeric(x) && isscalar(x));
p.addParameter('NumTrialsToPlot', 20, @(x) isnumeric(x) && isscalar(x) && x >= 1);
p.addParameter('BasisIndexToShow', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 1));
p.addParameter('MarkerSize', 18, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('TrajLineWidth', 0.15, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('ReverseY', false, @(x) islogical(x) && isscalar(x));
p.addParameter('FontName', 'Helvetica', @(x) ischar(x) || isstring(x));
p.addParameter('FontSize', 7, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('HorizontalGap', 1, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('VerticalGap', 1, @(x) isnumeric(x) && isscalar(x) && x > 0);

p.parse(result, basis, trial_info, varargin{:});

body_parts = p.Results.BodyParts;
fig_width = p.Results.FigureWidth;
fig_name = char(string(p.Results.FigureName));
fig_tag = char(string(p.Results.FigureTag));
save_figure = p.Results.SaveFigure;
fig_num = p.Results.FigureNumber;
n_plot = p.Results.NumTrialsToPlot;
basis_idx_to_show = p.Results.BasisIndexToShow;
ms = p.Results.MarkerSize;
traj_lw = p.Results.TrajLineWidth;
reverse_y = p.Results.ReverseY;
font_name = char(string(p.Results.FontName));
font_size = p.Results.FontSize;
hgap = p.Results.HorizontalGap;
vgap = p.Results.VerticalGap;

if ~isfield(result, 'beta_table')
    error('result.beta_table is required.');
end
T = result.beta_table;
if ~istable(T)
    error('result.beta_table must be a table.');
end

if isempty(body_parts)
    body_parts = local_infer_body_parts(T);
else
    body_parts = cellstr(string(body_parts(:)));
end

n_body = numel(body_parts);
if n_body == 0
    error('No body parts found to plot.');
end

if isempty(basis_idx_to_show)
    [~, basis_idx_to_show] = min(sum(basis.centers.^2, 2)); % nearest origin
end
basis_idx_to_show = min(max(1, basis_idx_to_show), basis.K);

% -------------------- extract reconstructed fields --------------------
fields = cell(n_body,1);
mx_field = 0;
for i = 1:n_body
    fields{i} = Kin.reconstruct_spatial_tuning_field(result, basis, body_parts{i});
    mx_field = max(mx_field, max(abs(fields{i}.F(:))));
end
if mx_field == 0
    mx_field = 1;
end

% -------------------- extract velocity betas --------------------
vx_beta = zeros(n_body,1);
vy_beta = zeros(n_body,1);
for i = 1:n_body
    vx_beta(i) = local_extract_scalar_beta(T, sprintf('%s_vx_cm_s', body_parts{i}));
    vy_beta(i) = local_extract_scalar_beta(T, sprintf('%s_vy_cm_s', body_parts{i}));
end
mx_vel = max(abs([vx_beta(:); vy_beta(:)]));
if mx_vel == 0
    mx_vel = 1;
end

% -------------------- layout --------------------
ncol = 1 + n_body;

% margins/gaps in cm
left = 0.9;
right = 0.9;
top = 1.3;
bottom = 0.8;
cb_w = 0.28;     % shared colorbar width
cb_gap = 0.12;
title_h = 0.55;

% usable width
usable_w = fig_width - left - right - (ncol-1)*hgap;
col_w = usable_w / ncol;

% row 1 height from spatial aspect
x_lim = [basis.x_range(1), basis.x_range(2)];
y_lim = [basis.y_range(1), basis.y_range(2)];
xy_aspect = diff(y_lim) / diff(x_lim);
row1_h = col_w * xy_aspect;

% row 2 height from golden ratio
phi = (1 + sqrt(5)) / 2;
row2_h = col_w / phi;

fig_height = bottom + row2_h + vgap + row1_h + top + title_h;

% -------------------- figure --------------------
hf = figure(fig_num); clf(hf);
set(hf, 'Color', 'w', ...
    'Units', 'centimeters', ...
    'Position', [2 2 fig_width fig_height], ...
    'Name', fig_name, ...
    'Visible', 'on');

% prepare title
if isfield(result, 'unit_id')
    title_str = sprintf('%s\n%s', fig_name, string(result.unit_id));
else
    title_str = fig_name;
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

mycolormap = customcolormap(linspace(0,1,11), ...
    {'#68011d','#b5172f','#d75f4e','#f7a580','#fedbc9', ...
     '#f5f9f3','#d5e2f0','#93c5dc','#4295c1','#2265ad','#062e61'});

% common top row y position
row1_y = bottom + row2_h + vgap;
row2_y = bottom;

% choose trials once
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

[basis_field, xq, yq] = local_eval_one_basis(basis, basis_idx_to_show, 120);
imagesc(ax, xq, yq, basis_field);
set(ax, 'YDir', ternary(reverse_y, 'reverse', 'normal'));
axis(ax, 'equal');
axis(ax, [x_lim y_lim]);
plot(ax, basis.centers(:,1), basis.centers(:,2), 'w+', 'MarkerSize', 2, 'LineWidth', 0.5);
% plot(ax, basis.centers(basis_idx_to_show,1), basis.centers(basis_idx_to_show,2), ...
    % 'wo', 'MarkerFaceColor', 'r', 'MarkerSize', 4);
local_plot_pooled_trajectories(ax, trial_info, body_parts, trial_sel, traj_lw);
plot(ax, 0, 0, 'wo', 'MarkerFaceColor', 'r', 'MarkerSize', 4);
colormap(ax, parula);
xlabel(ax, 'x (cm)');
ylabel(ax, 'y (cm)');
title(ax, sprintf('Example basis function (%02d)', basis_idx_to_show), ...
    'FontName', font_name, 'FontSize', font_size);
grid(ax, 'on');

% ============================================================
% row 1 col 2..end: tuning fields
% ============================================================
top_axes = gobjects(n_body,1);

for i = 1:n_body
    x0 = left + i*(col_w + hgap); % because col 1 is basis panel
    ax = axes('Parent', hf, 'Units', 'centimeters', ...
        'Position', [x0 row1_y col_w row1_h], ...
        'FontName', font_name, 'FontSize', font_size, ...
        'LineWidth', 0.5, 'Box', 'off');
    top_axes(i) = ax;
    hold(ax, 'on');

    imagesc(ax, fields{i}.xq, fields{i}.yq, fields{i}.F);
    set(ax, 'YDir', ternary(reverse_y, 'reverse', 'normal'));
    axis(ax, 'equal');
    axis(ax, [x_lim y_lim]);
    plot(ax, basis.centers(:,1), basis.centers(:,2), 'k+', 'MarkerSize', 4, 'LineWidth', 0.5);
    local_plot_bodypart_trajectories(ax, trial_info, body_parts{i}, trial_sel(1:4:end), traj_lw);
    plot(ax, 0, 0, 'wo', 'MarkerFaceColor', 'r', 'MarkerSize', 4);

    colormap(ax, mycolormap);
    clim(ax, [-mx_field mx_field]);

    xlabel(ax, 'x (cm)');
    ylabel(ax, 'y (cm)');
    title(ax, sprintf('%s spatial tuning field', body_parts{i}), ...
        'FontName', font_name, 'FontSize', font_size, 'Interpreter', 'none');
    grid(ax, 'on');
end

% shared colorbar for tuning fields
cb_x = left + ncol*col_w + (ncol-1)*hgap + cb_gap;
cb = colorbar(top_axes(end), 'Units', 'centimeters', ...
    'Position', [cb_x row1_y  cb_w row1_h]);
cb.Label.String = 'log-rate contribution';
cb.FontName = font_name;
cb.FontSize = font_size;

% ============================================================
% row 2 col 1: info panel
% ============================================================
x0 = left-0.75;
ax = axes('Parent', hf, 'Units', 'centimeters', ...
    'Position', [x0 row2_y col_w row2_h], ...
    'Visible', 'off');
hold(ax, 'on');

txt = local_make_info_text(result, basis, body_parts);
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
    x0 = left + i*(col_w + hgap);
    ax = axes('Parent', hf, 'Units', 'centimeters', ...
        'Position', [x0 row2_y col_w row2_h], ...
        'FontName', font_name, 'FontSize', font_size, ...
        'LineWidth', 0.5, 'Box', 'off');
    hold(ax, 'on');

    bar(ax, [1 2], [vx_beta(i) vy_beta(i)], 0.6);
    xlim(ax, [0.4 2.6]);
    xticks(ax, [1 2]);
    xticklabels(ax, {'vx','vy'});
    ylabel(ax, '\beta');
    title(ax, sprintf('%s velocity betas', body_parts{i}), ...
        'FontName', font_name, 'FontSize', font_size, 'Interpreter', 'none');
    ylim(ax, local_nice_ylim([-mx_vel mx_vel]));
    grid(ax, 'on');
end

% -------------------- save --------------------
if save_figure
    adjust_figure_size(hf, 1);
    figName = sprintf('spatial_tuning_and_velocity_%s_%s', ...
        local_safe_str(getfield_safe(result, 'unit_id', 'unit')), fig_tag);
    outFolder = fullfile(pwd, 'figure', 'glm');
    if ~exist(outFolder, 'dir')
        mkdir(outFolder);
    end
    save_fig(hf, figName, outFolder, 'Formats', {"png","pdf"});

    write_meta( ...
        figName, ...
        'MetaFolder', outFolder, ...
        'Description', 'Basis-reconstructed spatial tuning fields and velocity betas from GLM', ...
        'Purpose', 'To visualize spatial tuning fields and velocity betas for selected body parts', ...
        'GeneratorFunction', 'Kin.plot_spatial_basis_betas.m', ...
        'GeneratorScript', '', ...
        'Inputs', {'result', 'basis', 'trial_info'});
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

function local_plot_bodypart_trajectories(ax, trial_info, body_part, trial_sel, lw)
for ii = 1:numel(trial_sel)
    k = trial_sel(ii);
    if isfield(trial_info(k), body_part) && ...
            isfield(trial_info(k).(body_part), 'x_rel_cm') && ...
            isfield(trial_info(k).(body_part), 'y_rel_cm')

        x = trial_info(k).(body_part).x_rel_cm;
        y = trial_info(k).(body_part).y_rel_cm;
        if ~isempty(x) && ~isempty(y)
            plot(ax, x, y, 'k-', 'LineWidth', lw, 'Color',[.8 .8 .8]);
        end
    end
end
end

function local_plot_pooled_trajectories(ax, trial_info, body_parts, trial_sel, lw)
for i = 1:numel(body_parts)
    local_plot_bodypart_trajectories(ax, trial_info, body_parts{i}, trial_sel, lw);
end
end

function txt = local_make_info_text(result, basis, body_parts)
u = getfield_safe(result, 'unit_id', '');
pr2 = getfield_safe(result, 'pR2_test', NaN);
lam = getfield_safe(result, 'lambda_best', NaN);

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