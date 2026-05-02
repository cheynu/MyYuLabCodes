function hf = plot_trial_features_spikes_and_prediction(trial_info, result, trial_press_times, basis, basis_idx, varargin)
%PLOT_TRIAL_FEATURES_SPIKES_AND_PREDICTION
% One column per trial, with stacked panels:
%   1) space: paw/ear x and y
%   2) basis activation
%   3) velocity: paw/ear vx and vy
%   4) spikes: raster
%   5) prediction: observed and predicted firing rate
%
% Inputs
%   trial_info         struct array
%   result             GLM result struct from fit_poisson_elasticnet_glm_by_trial
%   trial_press_times  vector/string/cell of press_time identifiers to plot
%   basis              basis struct
%   basis_idx          scalar basis index
%
% Notes
%   Which trials to plot (e.g. one train and one test) should be decided
%   outside this function. This function only plots the requested trials.

p = inputParser;
p.addRequired('trial_info', @(x) isstruct(x) && ~isempty(x));
p.addRequired('result', @(x) isstruct(x));
p.addRequired('trial_press_times', @(x) isnumeric(x) || isstring(x) || iscell(x));
p.addRequired('basis', @(x) isstruct(x) && isfield(x, 'centers'));
p.addRequired('basis_idx', @(x) isnumeric(x) && x(1) >= 1);
p.addParameter('BodyParts', {'LeftPaw','LeftEar'}, @(x) iscell(x) || isstring(x));
p.addParameter('ColWidth', 4, @(x) isnumeric(x) && isscalar(x) && x > 2);
p.addParameter('ColWidthPerSec', 1, @(x) isnumeric(x) && isscalar(x) && x > 0.1);
p.addParameter('SpaceHeight', 4.5, @(x) isnumeric(x) && isscalar(x) && x > 0.5);
p.addParameter('VelocityHeight', 4.5, @(x) isnumeric(x) && isscalar(x) && x > 0.5);
p.addParameter('ActivationHeight', 1.2, @(x) isnumeric(x) && isscalar(x) && x > 0.2);
p.addParameter('SpikeHeight', 1.0, @(x) isnumeric(x) && isscalar(x) && x > 0.2);
p.addParameter('PredictionHeight', 1.4, @(x) isnumeric(x) && isscalar(x) && x > 0.2);
p.addParameter('FigureNumber', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x)));
p.addParameter('FontName', 'Helvetica', @(x) ischar(x) || isstring(x));
p.addParameter('FontSize', 7, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('LineWidth', 0.8, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('UseValidOnly', true, @(x) islogical(x) && isscalar(x));
p.addParameter('HorizontalGap', 0.8, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.addParameter('VerticalGap', 0.15, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.addParameter('TopMargin', 0.9, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.addParameter('BottomMargin', 0.6, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.addParameter('LeftMargin', 0.7, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.addParameter('RightMargin', 0.4, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.addParameter('FigureName', 'Trial features, spikes, and prediction', @(x) ischar(x) || isstring(x));
p.addParameter('ShowLegend', true, @(x) islogical(x) && isscalar(x));
p.addParameter('SpaceOffsets', [1.5 0.5 -0.5 -1.5], @(x) isnumeric(x) && numel(x)==4);
p.addParameter('ActivationOffsets', [1 0], @(x) isnumeric(x) && numel(x)==2);
p.addParameter('VelocityOffsets', [30 10 -10 -30], @(x) isnumeric(x) && numel(x)==4);
p.addParameter('SpaceLims', [], @(x) isempty(x) || (isnumeric(x) && numel(x)==2));
p.addParameter('VelocityLims', [], @(x) isempty(x) || (isnumeric(x) && numel(x)==2));
p.addParameter('ActivationLims', [], @(x) isempty(x) || (isnumeric(x) && numel(x)==2));
p.addParameter('PredictionLims', [], @(x) isempty(x) || (isnumeric(x) && numel(x)==2));
p.addParameter('SaveFigure', false, @(x) islogical(x) && isscalar(x));
p.addParameter('FigureTag', '', @(x) ischar(x) || isstring(x));
p.addParameter('MarkTime', [], @(x) isempty(x) || (isnumeric(x)));
p.addParameter('PositionMode', 'basis', @(x) any(strcmpi(string(x), ["basis","bin"])));

p.parse(trial_info, result, trial_press_times, basis, basis_idx, varargin{:});

col_width   = p.Results.ColWidth;
col_width_s = p.Results.ColWidthPerSec;
space_h     = p.Results.SpaceHeight;
vel_h       = p.Results.VelocityHeight;
act_h       = p.Results.ActivationHeight;
spike_h     = p.Results.SpikeHeight;
pred_h      = p.Results.PredictionHeight;
fig_num     = p.Results.FigureNumber;
font_name   = char(string(p.Results.FontName));
font_size   = p.Results.FontSize;
lw          = p.Results.LineWidth;
use_valid   = p.Results.UseValidOnly;
hgap        = p.Results.HorizontalGap;
vgap        = p.Results.VerticalGap;
top_m       = p.Results.TopMargin;
bot_m       = p.Results.BottomMargin;
left_m      = p.Results.LeftMargin;
right_m     = p.Results.RightMargin;
fig_name    = char(string(p.Results.FigureName));

space_offsets = p.Results.SpaceOffsets;
vel_offsets   = p.Results.VelocityOffsets;
act_offsets   = p.Results.ActivationOffsets;
position_mode = string(p.Results.PositionMode);

if isempty(space_offsets)
    % one offset for x and one for y per body part
    n_space = 2 * n_bp;
    space_offsets = linspace(n_space/2, -n_space/2, n_space);
end

if isempty(vel_offsets)
    n_vel = 2 * n_bp;
    vel_offsets = linspace(10*n_vel/2, -10*n_vel/2, n_vel);
end

if isempty(act_offsets)
    act_offsets = linspace(n_bp-1, 0, n_bp);
end

space_ylim    = p.Results.SpaceLims;
vel_ylim      = p.Results.VelocityLims;
act_ylim      = p.Results.ActivationLims;
pred_ylim     = p.Results.PredictionLims;
save_figure   = p.Results.SaveFigure;
fig_tag       = char(string(p.Results.FigureTag));
mark_time     = p.Results.MarkTime;
body_parts = cellstr(string(p.Results.BodyParts(:)));
n_bp = numel(body_parts);
trial_press_times = string(trial_press_times(:));
unit_id = string(local_getfield_safe(result, 'unit_id', "unit"));

% find requested trials by press_time
all_press = arrayfun(@(s) string(s.press_time), trial_info);
idx = zeros(numel(trial_press_times),1);
for i = 1:numel(trial_press_times)
    k = find(all_press == trial_press_times(i), 1, 'first');
    if isempty(k)
        error('Could not find trial with press_time = %s', trial_press_times(i));
    end
    idx(i) = k;
end

ncol = numel(idx);
fig_width = left_m + right_m + ncol*col_width + (ncol-1)*hgap;
fig_height = top_m + bot_m + space_h + vgap + act_h + vgap + vel_h + vgap + spike_h + vgap + pred_h + 0.5;

if isempty(fig_num)
    hf = figure('Color','w', 'Units','centimeters', ...
        'Position',[2 2 fig_width fig_height], 'Visible','on');
else
    hf = figure(fig_num); clf(hf);
    set(hf, 'Color','w', 'Units','centimeters', ...
        'Position',[2 2 fig_width fig_height], 'Visible','on');
end

annotation(hf, 'textbox', ...
    'Units', 'centimeters', ...
    'Position', [left_m, fig_height-top_m, fig_width-left_m-right_m, 0.65], ...
    'String', sprintf('%s', unit_id), ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'bottom', ...
    'FontWeight', 'bold', ...
    'FontName', font_name, ...
    'FontSize', font_size+1, ...
    'Interpreter', 'none');

% consistent styles

body_colors = struct();
body_colors.LeftPaw  = [0 0 0];
body_colors.LeftEar  = [0.2 0.45 0.8];
body_colors.RightPaw = [0.1 0.6 0.2];

c_obs   = [0 0 0];
c_pred  = [0.85 0 0];

for ic = 1:ncol
    tr = trial_info(idx(ic));

    idx_map = local_get_common_time_indices(tr, body_parts, use_valid);
    Rp = local_find_trial_prediction(result, tr.trial);

    x0 = left_m + (ic-1)*(col_width + hgap);

    y_pred = bot_m;
    y_spk  = y_pred + pred_h + vgap;
    y_vel  = y_spk + spike_h + vgap;
    y_act  = y_vel + vel_h + vgap;
    y_spa  = y_act + act_h + vgap;

    xlim_this = [(tr.t_start - tr.press_time)/1000, (tr.t_end - tr.press_time)/1000];
    plot_width = diff(xlim_this) * col_width_s;

    % -------- space panel --------
    ax1 = axes('Parent', hf, 'Units','centimeters', ...
        'Position', [x0 y_spa col_width space_h], ...
        'FontName', font_name, 'FontSize', font_size, ...
        'LineWidth', 0.5, 'Box', 'off');
    hold(ax1, 'on');

    kk = 0;
    for ib = 1:n_bp
        bp = body_parts{ib};
        c_this = local_get_bodypart_color(bp, body_colors, ib);

        kk = kk + 1;
        local_plot_feature(ax1, tr, bp, 'x_rel_cm', 1, c_this, lw, ...
            space_offsets(kk), idx_map.(bp), false);

        kk = kk + 1;
        local_plot_feature(ax1, tr, bp, 'y_rel_cm', 1, c_this, lw*1.5, ...
            space_offsets(kk), idx_map.(bp), false);
    end

    xlim(ax1, xlim_this);
    ax1.Position(3) = plot_width;

    if ic == 1
        ylabel(ax1, 'space', 'FontName', font_name, 'FontSize', font_size);
    end

    num = regexp(string(tr.trial), '\d+$', 'match', 'once');
    title(ax1, sprintf('%s | %s', num, Rp.set_name), ...
        'Interpreter', 'none', 'FontName', font_name, 'FontSize', font_size);

    if ic == 1
        line(ax1, (xlim_this(2)-0.1)*[1 1], [-5 0], 'Color','k', 'LineWidth',1);
        text(ax1, xlim_this(2), -2.5, '5 cm', 'FontSize',font_size, 'FontName',font_name);
    end

    if ic > 1
        ax1.YTick = [];
    end
    if ~isempty(space_ylim)
        ax1.YLim = space_ylim;
    end
    set(ax1, 'XTickLabel', []);
    grid(ax1, 'off');
    
    if ~isempty(mark_time)
        for i =1:numel(mark_time)
            xline(ax1, (mark_time(i)-tr.press_time)/1000, 'color', 'b');
        end
    end

    % -------- basis activation panel --------
    ax_act = axes('Parent', hf, 'Units','centimeters', ...
        'Position', [x0 y_act col_width act_h], ...
        'FontName', font_name, 'FontSize', font_size, ...
        'LineWidth', 0.5, 'Box', 'off');
    hold(ax_act, 'on');


    if strcmp(position_mode, 'basis')

        for ib = 1:n_bp
            bp = body_parts{ib};
            c_this = local_get_bodypart_color(bp, body_colors, ib);

            A = compute_bodypart_basis_activation(tr, basis, basis_idx, bp);

            plot(ax_act, A.t_rel_ms(idx_map.(bp))/1000, ...
                A.activation(idx_map.(bp)) + act_offsets(ib), ...
                '-', 'Color', c_this, 'LineWidth', lw*1.2);
        end

        xlim(ax_act, xlim_this);
        ax_act.Position(3) = plot_width;

        if ic == 1
            ylabel(ax_act, 'activation', 'FontName', font_name, 'FontSize', font_size);
            text(ax_act, xlim_this(1), 0.9, sprintf('basis %d', basis_idx), ...
                'FontName', font_name, 'FontSize', font_size, ...
                'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
            line(ax_act, (xlim_this(2)-0.1)*[1 1], [0 0.5], 'Color','k', 'LineWidth',1);
            text(ax_act, xlim_this(2), 0.05, sprintf('0.5 (basis %d)', basis_idx), ...
                'FontSize',font_size, 'FontName',font_name, 'Interpreter','none');
        end

        if ic > 1
            ax_act.YTick = [];
        end
        if ~isempty(act_ylim)
            ax_act.YLim = act_ylim;
        else
            ylim(ax_act, [-0.02 1.02]);
        end
        set(ax_act, 'XTickLabel', []);
        grid(ax_act, 'off');

        if ~isempty(mark_time)
            for ii =1:numel(mark_time)
                xline(ax_act, (mark_time(ii)-tr.press_time)/1000, 'color', 'b');
            end
        end

    else
        
        for ib = 1:n_bp
            bp = body_parts{ib};
            c_this = local_get_bodypart_color(bp, body_colors, ib);
            tr.(bp).occupancy = Kin.compute_pixel_occupancy(tr, basis, bp, 'time');

            for kk =1:length(basis_idx)
            plot(ax_act, (tr.(bp).time-tr.press_time)/1000, ...
                tr.(bp).occupancy(:, basis_idx(kk)) + act_offsets(kk), ...
                '-', 'Color', c_this, 'LineWidth', lw*1.2);
            end
        end

        xlim(ax_act, xlim_this);
        ax_act.Position(3) = plot_width;

        if ic > 1
            ax_act.YTick = [];
        end
        if ~isempty(act_ylim)
            ax_act.YLim = act_ylim;
        else
            ylim(ax_act, [-0.02 1.02]);
        end
        set(ax_act, 'XTickLabel', []);
        grid(ax_act, 'off');

        if ~isempty(mark_time)
            for ii =1:numel(mark_time)
                xline(ax_act, (mark_time(ii)-tr.press_time)/1000, 'color', 'b');
            end
        end


    end

    % -------- velocity panel --------
    ax2 = axes('Parent', hf, 'Units','centimeters', ...
        'Position', [x0 y_vel col_width vel_h], ...
        'FontName', font_name, 'FontSize', font_size, ...
        'LineWidth', 0.5, 'Box', 'off');
    hold(ax2, 'on');

    kk = 0;
    for ib = 1:n_bp
        bp = body_parts{ib};
        c_this = local_get_bodypart_color(bp, body_colors, ib);

        kk = kk + 1;
        local_plot_feature(ax2, tr, bp, 'vx_cm_s', 1, c_this, lw, ...
            vel_offsets(kk), idx_map.(bp), true);

        kk = kk + 1;
        local_plot_feature(ax2, tr, bp, 'vy_cm_s', 1, c_this, lw*1.5, ...
            vel_offsets(kk), idx_map.(bp), true);
    end

    xlim(ax2, xlim_this);
    ax2.Position(3) = plot_width;

    if ic == 1
        ylabel(ax2, 'velocity', 'FontName', font_name, 'FontSize', font_size);
        line(ax2, (xlim_this(2)-0.1)*[1 1], [-20 0], 'Color','k', 'LineWidth',1);
        text(ax2, xlim_this(2), -10, '20 cm/s', 'FontSize',font_size, 'FontName',font_name);
    end

    if ic > 1
        ax2.YTick = [];
    end
    if ~isempty(vel_ylim)
        ax2.YLim = vel_ylim;
    end
    set(ax2, 'XTickLabel', []);
    grid(ax2, 'off');

    if ~isempty(mark_time)
        for ii =1:numel(mark_time)
            xline(ax2, (mark_time(ii)-tr.press_time)/1000, 'color', 'b');
        end
    end

    % -------- spike raster --------
    ax3 = axes('Parent', hf, 'Units','centimeters', ...
        'Position', [x0 y_spk col_width spike_h], ...
        'FontName', font_name, 'FontSize', font_size, ...
        'LineWidth', 0.5, 'Box', 'off');
    hold(ax3, 'on');

    for s = 1:numel(Rp.spike_times_rel_s)
        line(ax3, [Rp.spike_times_rel_s(s) Rp.spike_times_rel_s(s)], [0 1], ...
            'Color', 'k', 'LineWidth', 0.5);
    end

    xlim(ax3, xlim_this);
    ax3.Position(3) = plot_width;
    ylim(ax3, [0 1]);
    yticks(ax3, []);
    if ic == 1
        ylabel(ax3, 'spk', 'FontName', font_name, 'FontSize', font_size);
    end
    set(ax3, 'XTickLabel', []);
    grid(ax3, 'off');

    if ~isempty(mark_time)
        for ii =1:numel(mark_time)
            xline(ax3, (mark_time(ii)-tr.press_time)/1000, 'color', 'b');
        end
    end

    % -------- prediction panel --------
    ax4 = axes('Parent', hf, 'Units','centimeters', ...
        'Position', [x0 y_pred col_width pred_h], ...
        'FontName', font_name, 'FontSize', font_size, ...
        'LineWidth', 0.5, 'Box', 'off');
    hold(ax4, 'on');

    t_pred = (Rp.time_bin_center - Rp.press_time) / 1000;
    bar(ax4, t_pred, Rp.y_rate_hz, .9, 'FaceColor', c_obs, 'EdgeColor', 'none', 'LineWidth', lw);
    plot(ax4, t_pred, Rp.mu_rate_hz, '-', 'Color', c_pred, 'LineWidth', lw);

    xlim(ax4, xlim_this);
    ax4.Position(3) = plot_width;

    if ic == 1
        ylabel(ax4, 'rate', 'FontName', font_name, 'FontSize', font_size);
    end
    xlabel(ax4, 'time from press (s)', 'FontName', font_name, 'FontSize', font_size);
    if ~isempty(pred_ylim)
        ax4.YLim = pred_ylim;
    end
    grid(ax4, 'off');

end

% add legend column
x0 = left_m + ncol*(col_width + hgap);
ax_label = axes('Parent', hf, 'Units','centimeters', ...
    'Position', [x0 y_spa col_width max(space_h, 2.8)], ...
    'FontName', font_name, 'FontSize', font_size, ...
    'LineWidth', 0.5, 'Box', 'off');
hold(ax_label, 'on');

y0 = 1;
dy = 1;

for ib = 1:n_bp
    bp = body_parts{ib};
    c_this = local_get_bodypart_color(bp, body_colors, ib);

    yy1 = y0 + (ib-1)*2;
    yy2 = yy1 + 1;

    line(ax_label, [0 .1], [yy1 yy1], 'Color', c_this, 'LineWidth', lw);
    line(ax_label, [0 .1], [yy2 yy2], 'Color', c_this, 'LineWidth', lw*1.5);

    text(ax_label, 0.15, yy1, sprintf('%s x / vx', bp), ...
        'FontName', font_name, 'FontSize', font_size, 'VerticalAlignment', 'middle', ...
        'Interpreter', 'none');
    text(ax_label, 0.15, yy2, sprintf('%s y / vy', bp), ...
        'FontName', font_name, 'FontSize', font_size, 'VerticalAlignment', 'middle', ...
        'Interpreter', 'none');
end

yy_obs = y0 + 2*n_bp;
yy_pred = yy_obs + 1;

line(ax_label, [0 .1], [yy_obs yy_obs], 'Color', c_obs, 'LineWidth', lw);
line(ax_label, [0 .1], [yy_pred yy_pred], 'Color', c_pred, 'LineWidth', lw);

text(ax_label, 0.15, yy_obs, 'observed rate', ...
    'FontName', font_name, 'FontSize', font_size, 'VerticalAlignment', 'middle');
text(ax_label, 0.15, yy_pred, 'predicted rate', ...
    'FontName', font_name, 'FontSize', font_size, 'VerticalAlignment', 'middle');

ax_label.XLim = [0 2];
ax_label.YLim = [0 yy_pred + 1];
ax_label.YDir = 'reverse';
axis(ax_label, 'off');

adjust_figure_size(hf, 1.5);

% -------------------- save --------------------
if save_figure
    adjust_figure_size(hf, 1);

    press_tag = strjoin(string(trial_press_times), "_");
    press_tag = regexprep(press_tag, '[^\w-]+', '_');

    if ~isempty(fig_tag)
        figName = sprintf('trial_features_spikes_prediction_%s_%s_%s', ...
            local_safe_str(unit_id), press_tag, local_safe_str(fig_tag));
    else
        figName = sprintf('trial_features_spikes_prediction_%s_%s', ...
            local_safe_str(unit_id), press_tag);
    end

    outFolder = fullfile(pwd, 'figure', 'glm_prediction');
    if ~exist(outFolder, 'dir')
        mkdir(outFolder);
    end

    save_fig(hf, figName, outFolder, 'Formats', {"png","pdf"});

    write_meta( ...
        figName, ...
        'MetaFolder', outFolder, ...
        'Description', 'Example trials showing paw/ear position, velocity, basis activation, spike raster, and prediction', ...
        'Purpose', 'To illustrate trial-level kinematics, spikes, and GLM prediction', ...
        'GeneratorFunction', 'Kin.plot_trial_features_spikes_and_prediction.m', ...
        'GeneratorScript', '', ...
        'Inputs', { ...
            sprintf('unit_id: %s', string(unit_id)), ...
            sprintf('trial_press_times: %s', strjoin(string(trial_press_times), ', ')), ...
            sprintf('basis_idx: %d', basis_idx), ...
            sprintf('figure_name: %s', fig_name) ...
        });
end

end

function Rp = local_find_trial_prediction(result, trial_name)
Rp = struct();
Rp.trial = string(trial_name);
Rp.set_name = "unknown";
Rp.press_time = NaN;
Rp.time_bin_start = [];
Rp.time_bin_end = [];
Rp.time_bin_center = [];
Rp.y = [];
Rp.mu = [];
Rp.y_rate_hz = [];
Rp.mu_rate_hz = [];
Rp.spike_times_rel_s = [];

if isfield(result, 'train_trials')
    idx = find(string({result.train_trials.trial}) == string(trial_name), 1);
    if ~isempty(idx)
        Rp = result.train_trials(idx);
        Rp.set_name = "train";
        return
    end
end

if isfield(result, 'test_trials')
    idx = find(string({result.test_trials.trial}) == string(trial_name), 1);
    if ~isempty(idx)
        Rp = result.test_trials(idx);
        Rp.set_name = "test";
        return
    end
end

error('Trial %s not found in result.train_trials or result.test_trials.', string(trial_name));
end

function local_plot_feature(ax, tr, body_part, feat_name, sign_flip, color_this, lw, y_offset, idx_use, is_vel)

if nargin < 10 || isempty(is_vel)
    is_vel = false;
end

if ~isfield(tr, body_part)
    return
end
S = tr.(body_part);

if ~isfield(S, feat_name) || ~isfield(S, 'time')
    return
end

if isempty(idx_use)
    idx_use = (1:numel(S.time))';
end

t_abs = S.time(idx_use);
t_rel_s = (t_abs - tr.press_time) / 1000;

yy = S.(feat_name)(idx_use);
yy = sign_flip * yy + y_offset;

plot(ax, t_rel_s, yy, '-', 'Color', color_this, 'LineWidth', lw);

if is_vel
    yline(ax, y_offset, 'LineStyle', ':', 'Color', 'k', 'LineWidth', .5);
end
end

function act = compute_bodypart_basis_activation(trial_info_entry, basis, basis_idx, body_part)
if basis_idx < 1 || basis_idx > basis.K
    error('basis_idx out of range. Must be between 1 and %d.', basis.K);
end
if ~isfield(trial_info_entry, body_part)
    error('Body part %s not found in trial_info entry.', body_part);
end

S = trial_info_entry.(body_part);
if ~isfield(S, 'x_rel_cm') || ~isfield(S, 'y_rel_cm') || ~isfield(S, 'time')
    error('Body part %s is missing x_rel_cm, y_rel_cm, or time.', body_part);
end

x = S.x_rel_cm(:);
y = S.y_rel_cm(:);
time_ms = S.time(:);

if isfield(S, 'valid')
    valid = logical(S.valid(:));
else
    valid = true(size(x));
end

cx = basis.centers(basis_idx, 1);
cy = basis.centers(basis_idx, 2);

activation = nan(size(x));
good = valid & isfinite(x) & isfinite(y);
activation(good) = exp( ...
    -0.5 * ((x(good) - cx) ./ basis.sigma_x).^2 ...
    -0.5 * ((y(good) - cy) ./ basis.sigma_y).^2 );

act = struct();
act.trial = trial_info_entry.trial;
act.press_time = trial_info_entry.press_time;
act.body_part = string(body_part);
act.basis_idx = basis_idx;
act.center_x = cx;
act.center_y = cy;
act.time_ms = time_ms;
act.t_rel_ms = time_ms - trial_info_entry.press_time;
act.x_rel_cm = x;
act.y_rel_cm = y;
act.valid = valid;
act.activation = activation;
end

function out = local_safe_str(x)
x = string(x);
x = regexprep(x, '[^\w-]+', '_');
out = char(x);
end

function out = local_getfield_safe(S, fname, default_val)
if isfield(S, fname)
    out = S.(fname);
else
    out = default_val;
end
end

function idx_map = local_get_common_time_indices(tr, body_parts, use_valid)
% Return indices into each body part's time vector for common timestamps.
%
% idx_map.(body_part) gives row indices for samples shared by all body parts.
% idx_map.common_time gives the shared timestamps.

if nargin < 3
    use_valid = true;
end

body_parts = cellstr(string(body_parts(:)));
n_bp = numel(body_parts);

% start from first body part
bp0 = body_parts{1};
S0 = tr.(bp0);
t_common = S0.time(:);
idx_ref = (1:numel(t_common))';

if use_valid && isfield(S0, 'valid')
    m0 = logical(S0.valid(:));
    t_common = t_common(m0);
    idx_ref = idx_ref(m0);
end

idx_map = struct();
idx_map.(bp0) = idx_ref;

for i = 2:n_bp
    bp = body_parts{i};
    S = tr.(bp);

    t_this = S.time(:);
    idx_this = (1:numel(t_this))';

    if use_valid && isfield(S, 'valid')
        m = logical(S.valid(:));
        t_this = t_this(m);
        idx_this = idx_this(m);
    end

    [t_new, ia, ib] = intersect(t_common, t_this);

    % shrink previously stored indices to the new common set
    prev_fields = fieldnames(idx_map);
    for j = 1:numel(prev_fields)
        f = prev_fields{j};
        if ~strcmp(f, 'common_time')
            idx_map.(f) = idx_map.(f)(ia);
        end
    end

    idx_map.(bp) = idx_this(ib);
    t_common = t_new;
end

idx_map.common_time = t_common;
end

function c = local_get_bodypart_color(body_part, body_colors, idx)
if isfield(body_colors, body_part)
    c = body_colors.(body_part);
    return
end

fallback = lines(max(idx, 7));
c = fallback(idx, :);
end