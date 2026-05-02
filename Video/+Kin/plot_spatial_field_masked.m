function [ax_field, cb_field] = plot_spatial_field_masked( ...
    hf, field, basis, trial_info, body_part, varargin)
%PLOT_SPATIAL_FIELD_MASKED
% Plot masked spatial tuning field with trajectory overlay and unsupported
% region shown in gray via an overlaid mask.
%
% Usage
%   [ax_field, cb_field] = plot_spatial_field_masked( ...
%       hf, field, basis, trial_info, body_part, ...)
%
% Required inputs
%   hf         figure handle
%   field      struct from reconstruct_spatial_tuning_field_masked
%              expected fields:
%                  .xq, .yq, .F
%              optional:
%                  .F_masked
%                  .support_mask
%   basis      basis struct
%   trial_info struct array
%   body_part  e.g. 'LeftPaw'
%
% Name-value
%   'FieldPosition'    [x y w h] in cm, default [2 8 5 5]
%   'ColorbarWidth'    scalar in cm, default 0.35
%   'ColorbarGap'      scalar in cm, default 0.25
%   'FontName'         default 'Arial'
%   'FontSize'         default 7
%   'LineWidth'        default 0.5
%   'XLim'             default [min(field.xq) max(field.xq)]
%   'YLim'             default [min(field.yq) max(field.yq)]
%   'FieldCLim'        default []
%   'ShowExpField'     default false
%   'UseMasked'        default true
%   'TrajLineWidth'    default 0.3
%   'TrajColor'        default [0.2 0.2 0.2]
%   'NumTrialsToPlot'  default 20
%   'RandomSeed'       default 41
%   'ShowTraj'         default true
%   'ShowBasisCenters' default true
%   'ShowOrigin'       default true
%   'ShowMaskOverlay'  default true
%   'MaskColor'        default [.9 .9 .9]
%
% Outputs
%   ax_field, cb_field

p = inputParser;
p.addParameter('FieldPosition', [2 8 5 5], @(x) isnumeric(x) && numel(x)==4);
p.addParameter('ColorbarWidth', 0.35, @(x) isnumeric(x) && isscalar(x));
p.addParameter('ColorbarGap', 0.25, @(x) isnumeric(x) && isscalar(x));
p.addParameter('FontName', 'Arial', @(x) ischar(x) || isstring(x));
p.addParameter('FontSize', 7, @(x) isnumeric(x) && isscalar(x));
p.addParameter('LineWidth', 0.5, @(x) isnumeric(x) && isscalar(x));
p.addParameter('XLim', [min(field.xq) max(field.xq)], @(x) isnumeric(x) && numel(x)==2);
p.addParameter('YLim', [min(field.yq) max(field.yq)], @(x) isnumeric(x) && numel(x)==2);
p.addParameter('FieldCLim', [], @(x) isempty(x) || (isnumeric(x) && numel(x)==2));
p.addParameter('ShowExpField', false, @(x) islogical(x) && isscalar(x));
p.addParameter('UseMasked', true, @(x) islogical(x) && isscalar(x));
p.addParameter('TrajLineWidth', 0.3, @(x) isnumeric(x) && isscalar(x));
p.addParameter('TrajColor', [0.2 0.2 0.2], @(x) isnumeric(x) && numel(x)==3);
p.addParameter('NumTrialsToPlot', 20, @(x) isnumeric(x) && isscalar(x) && x >= 1);
p.addParameter('RandomSeed', 41, @(x) isnumeric(x) && isscalar(x));
p.addParameter('ShowTraj', true, @(x) islogical(x) && isscalar(x));
p.addParameter('ShowBasisCenters', true, @(x) islogical(x) && isscalar(x));
p.addParameter('ShowOrigin', true, @(x) islogical(x) && isscalar(x));
p.addParameter('ShowMaskOverlay', true, @(x) islogical(x) && isscalar(x));
p.addParameter('MaskColor', [.9 .9 .9], @(x) isnumeric(x) && numel(x)==3);
p.parse(varargin{:});

field_pos   = p.Results.FieldPosition;
cb_w        = p.Results.ColorbarWidth;
cb_gap      = p.Results.ColorbarGap;
font_name   = char(p.Results.FontName);
font_size   = p.Results.FontSize;
line_width  = p.Results.LineWidth;
x_lim       = p.Results.XLim;
y_lim       = p.Results.YLim;
field_clim  = p.Results.FieldCLim;
show_exp    = p.Results.ShowExpField;
use_masked  = p.Results.UseMasked;
traj_lw     = p.Results.TrajLineWidth;
traj_color  = p.Results.TrajColor;
n_plot      = p.Results.NumTrialsToPlot;
seed        = p.Results.RandomSeed;
show_traj   = p.Results.ShowTraj;
show_basis  = p.Results.ShowBasisCenters;
show_origin = p.Results.ShowOrigin;
show_mask   = p.Results.ShowMaskOverlay;
mask_color  = p.Results.MaskColor;

% -------------------------
% field data
% -------------------------
if use_masked && isfield(field, 'F_masked')
    Fplot = field.F_masked;
else
    Fplot = field.F;
end

if show_exp
    Fplot = exp(Fplot);
    field_title = sprintf('%s', body_part);
    field_label = 'multiplicative gain';
else
    field_title = sprintf('%s', body_part);
    field_label = 'log-rate contribution';
end

% -------------------------
% auto-select trials
% -------------------------
rng(seed);
n_trials_total = numel(trial_info);
n_plot = min(n_plot, n_trials_total);
trial_sel = randperm(n_trials_total, n_plot);

% -------------------------
% colormap for field
% -------------------------
mycolormap = customcolormap(linspace(0,1,11), ...
    {'#68011d','#b5172f','#d75f4e','#f7a580','#fedbc9', ...
     '#f5f9f3','#d5e2f0','#93c5dc','#4295c1','#2265ad','#062e61'});

% -------------------------
% main axes
% -------------------------
ax_field = axes('Parent', hf, 'Units', 'centimeters', ...
    'Position', field_pos, ...
    'FontName', font_name, 'FontSize', font_size, ...
    'LineWidth', line_width, 'Box', 'off');
hold(ax_field, 'on');

% main field image
imagesc(ax_field, field.xq, field.yq, Fplot, 'CDataMapping', 'scaled');
set(ax_field, 'YDir', 'normal');  
axis(ax_field, 'equal');
axis(ax_field, [x_lim y_lim]);

colormap(ax_field, mycolormap);

if isempty(field_clim)
    vals = Fplot(isfinite(Fplot));
    mx = max(abs(vals));
    if isempty(mx) || mx == 0
        mx = 1;
    end
    clim(ax_field, [-mx mx]);
else
    clim(ax_field, field_clim);
end

% -------------------------
% unsupported mask overlay
% -------------------------
if show_mask && isfield(field, 'support_mask')
    unsupported = ~field.support_mask;

    % RGB image, all pixels same gray
    mask_rgb = zeros([size(unsupported), 3]);
    for c = 1:3
        mask_rgb(:,:,c) = mask_color(c);
    end

    hmask = image(ax_field, field.xq, field.yq, mask_rgb);
    set(hmask, 'AlphaData', double(unsupported));
    uistack(hmask, 'top');
end

% -------------------------
% overlays
% -------------------------
if show_basis
    plot(ax_field, basis.centers(:,1), basis.centers(:,2), ...
        'k+', 'MarkerSize', 2, 'LineWidth', 0.5);
end

if show_traj
    local_plot_bodypart_trajectories(ax_field, trial_info, body_part, ...
        trial_sel, traj_lw, traj_color);
end

if show_origin
    scatter(ax_field, 0, 0, 'o', ...
        'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'none', 'SizeData', 15);
end

title(ax_field, field_title, ...
    'FontName', font_name, 'FontSize', font_size, 'Interpreter', 'none');
grid(ax_field, 'off');

% -------------------------
% colorbar
% -------------------------
cb_field = colorbar(ax_field, 'southoutside');
cb_field.Units = 'centimeters';
cb_field.Position = [field_pos(1), field_pos(2)-cb_gap-cb_w, field_pos(3), cb_w];
cb_field.FontName = font_name;
cb_field.FontSize = font_size;
cb_field.TickLabelInterpreter = 'none';
cb_field.Label.String = field_label;

mx = max(abs(clim(ax_field)));
if mx > 0.1
    tick_max = floor(mx*10)/10;
    cb_field.Ticks = [-tick_max 0 tick_max];
    cb_field.TickLabels = compose('%.1f', cb_field.Ticks);
end

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
            plot(ax, x, y, '-', 'LineWidth', lw, 'Color', lc);
        end
    end
end
end