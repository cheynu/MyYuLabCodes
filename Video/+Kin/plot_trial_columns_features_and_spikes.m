function hf = plot_trial_columns_features_and_spikes(trial_info, spike_times_ms, unit_id, trial_press_times, basis, basis_idx, varargin)

%PLOT_TRIAL_COLUMNS_SPACE_VEL_SPIKES
% One column per trial, with 3 stacked panels:
%   1) space: paw/ear x and y
%   2) velocity: paw/ear vx and vy
%   3) spikes: raster
%
% x and y are sign-flipped so decreases look increasing.
% vx and vy are plotted as-is.
%
% Inputs
%   trial_info         struct array
%   spike_times_ms     spike times in ms, absolute/original timebase
%   unit_id            unit_id
%   trial_press_times  vector/string/cell of press_time identifiers to plot
%
% Name-value
%   'ColWidthPerSec'   default 1   cm
%   'SpaceHeight'      default 4.5   cm
%   'VelocityHeight'   default 4.5   cm
%   'SpikeHeight'      default 1.4   cm
%   'FigureNumber'     default []
%   'FontName'         default 'Helvetica'
%   'FontSize'         default 7
%   'LineWidth'        default 0.8
%   'UseValidOnly'     default true
%   'HorizontalGap'    default 0.8   cm
%   'VerticalGap'      default 0.15  cm
%   'TopMargin'        default 0.9   cm
%   'BottomMargin'     default 0.6   cm
%   'LeftMargin'       default 0.7   cm
%   'RightMargin'      default 0.4   cm
%   'FigureName'       default 'Trial space, velocity, and spikes'
%   'ShowLegend'       default true
%    'SpaceLims'       default empty
%
% Example
%   hf = plot_trial_columns_space_vel_spikes( ...
%       trial_info, spike_times_ms, [786178 1856098], ...
%       'ColWidth', 4.2, 'SpaceHeight', 4.3, ...
%       'VelocityHeight', 4.3, 'SpikeHeight', 1.2);

p = inputParser;
p.addRequired('trial_info', @(x) isstruct(x) && ~isempty(x));
p.addRequired('spike_times_ms', @(x) isnumeric(x) && isvector(x));
p.addRequired('unit_id', @(x) (isstring(x) && isscalar(x)));
p.addRequired('trial_press_times', @(x) isnumeric(x) || isstring(x) || iscell(x));
p.addRequired('basis', @(x) isstruct(x) && isfield(x, 'centers'));
p.addRequired('basis_idx', @(x) isnumeric(x) && isscalar(x) && x >= 1);

p.addParameter('ColWidth', 4, @(x) isnumeric(x) && isscalar(x) && x > 2);
p.addParameter('ColWidthPerSec', 1, @(x) isnumeric(x) && isscalar(x) && x > 0.1);
p.addParameter('SpaceHeight', 4.5, @(x) isnumeric(x) && isscalar(x) && x > 0.5);
p.addParameter('VelocityHeight', 4.5, @(x) isnumeric(x) && isscalar(x) && x > 0.5);
p.addParameter('SpikeHeight', 1.4, @(x) isnumeric(x) && isscalar(x) && x > 0.2);
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
p.addParameter('FigureName', 'Trial space, velocity, and spikes', @(x) ischar(x) || isstring(x));
p.addParameter('ShowLegend', true, @(x) islogical(x) && isscalar(x));
p.addParameter('SpaceOffsets', [1.5 0.5 -0.5 -1.5], @(x) isnumeric(x) && numel(x)==4);
p.addParameter('ActivationOffsets', [1 0], @(x) isnumeric(x) && numel(x)==2);
p.addParameter('VelocityOffsets', [30 10 -10 -30], @(x) isnumeric(x) && numel(x)==4);
p.addParameter('SpaceLims', [], @(x) isnumeric(x) && numel(x)==2);
p.addParameter('VelocityLims', [], @(x) isnumeric(x) && numel(x)==2);
p.addParameter('ActivationLims', [], @(x) isnumeric(x) && numel(x)==2);
p.addParameter('ActivationHeight', 1.2, @(x) isnumeric(x) && isscalar(x) && x > 0.2);
p.addParameter('SaveFigure', false, @(x) islogical(x) && isscalar(x));
p.addParameter('FigureTag', '', @(x) ischar(x) || isstring(x));
p.parse(trial_info, spike_times_ms, unit_id, trial_press_times, basis, basis_idx, varargin{:});

col_width   = p.Results.ColWidth;
col_width_s = p.Results.ColWidthPerSec;
space_h     = p.Results.SpaceHeight;
vel_h       = p.Results.VelocityHeight;
act_h = p.Results.ActivationHeight;
spike_h     = p.Results.SpikeHeight;
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
show_legend = p.Results.ShowLegend;
space_offsets = p.Results.SpaceOffsets;
vel_offsets = p.Results.VelocityOffsets;
act_offsets = p.Results.ActivationOffsets;
space_ylim  = p.Results.SpaceLims;
vel_ylim    = p.Results.VelocityLims;
act_ylim    = p.Results.ActivationLims;
save_figure = p.Results.SaveFigure;
fig_tag = char(string(p.Results.FigureTag));

spike_times_ms = spike_times_ms(:);
trial_press_times = string(trial_press_times(:));

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
fig_height = top_m + bot_m + space_h + vgap + act_h + vgap + vel_h + vgap + spike_h + 0.5;

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
    'String', sprintf('%s',unit_id), ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'bottom', ...
    'FontWeight', 'bold', ...
    'FontName', font_name, ...
    'FontSize', font_size+1, ...
    'Interpreter', 'none');

% consistent styles
c_paw_x = [0 0 0];
c_paw_y = [0.35 0.35 0.35];

c_ear_x = [0.2 0.45 0.8];
c_ear_y = [0.6 0.75 0.95];

for ic = 1:ncol
    tr = trial_info(idx(ic));

    x0 = left_m + (ic-1)*(col_width + hgap);

    y_spk = bot_m;
    y_vel = y_spk + spike_h + vgap;
    y_act = y_vel + vel_h + vgap;
    y_spa = y_act + act_h + vgap;

    % choose common x-limits from trial bounds
    xlim_this = [(tr.t_start - tr.press_time)/1000, (tr.t_end - tr.press_time)/1000];

    % -------- space panel --------
    ax1 = axes('Parent', hf, 'Units','centimeters', ...
        'Position', [x0 y_spa col_width space_h], ...
        'FontName', font_name, 'FontSize', font_size, ...
        'LineWidth', 0.5, 'Box', 'off');
    hold(ax1, 'on');

    local_plot_feature(ax1, tr, 'LeftPaw', 'x_rel_cm', 1, c_paw_x, lw, use_valid, space_offsets(1));
    local_plot_feature(ax1, tr, 'LeftPaw', 'y_rel_cm', 1, c_paw_y, lw*1.5, use_valid, space_offsets(2));
    local_plot_feature(ax1, tr, 'LeftEar', 'x_rel_cm', 1, c_ear_x, lw, use_valid, space_offsets(3));
    local_plot_feature(ax1, tr, 'LeftEar', 'y_rel_cm', 1, c_ear_y, lw*1.5, use_valid, space_offsets(4));

    % xline(ax1, 0, '--', 'LineWidth', 0.5);
    xlim(ax1, xlim_this);
    if ic == 1
        ylabel(ax1, 'space', 'FontName', font_name, 'FontSize', font_size);
    end
    num = regexp(string(tr.trial), '\d+$', 'match', 'once');
    title(ax1, num, 'Interpreter', 'none', 'FontName', font_name, 'FontSize', font_size);
    grid(ax1, 'off');
    set(ax1, 'XTickLabel', []);

    % adjust the width of this plot based on data length
    plot_width = diff(xlim_this)*col_width_s;
    ax1.Position(3) = plot_width;

    if show_legend && ic == 1  && false
        legend(ax1, {'paw x','paw y','ear x','ear y'}, ...
            'Location', 'best', 'Box', 'off', 'FontSize', font_size-1);
    end

    % --- make scale ---
    if ic == 1
        line(ax1, (xlim_this(2)-0.1)*[1 1], [-5 0], 'Color','k', 'LineWidth',1);
        text(xlim_this(2), -2.5, '5 cm', 'FontSize',font_size, 'FontName',font_name)
    end

    if ic>1
        ax1.YTick = [];
    end

    % --- decide y range ---
    if ~isempty(space_ylim)
        ax1.YLim = space_ylim;
    end

    % -------- basis activation panel --------
    ax_act = axes('Parent', hf, 'Units','centimeters', ...
        'Position', [x0 y_act col_width act_h], ...
        'FontName', font_name, 'FontSize', font_size, ...
        'LineWidth', 0.5, 'Box', 'off');
    hold(ax_act, 'on');

    A_paw = compute_bodypart_basis_activation(tr, basis, basis_idx, 'LeftPaw');
    A_ear = compute_bodypart_basis_activation(tr, basis, basis_idx, 'LeftEar');

    m_paw = A_paw.valid & isfinite(A_paw.activation);
    m_ear = A_ear.valid & isfinite(A_ear.activation);

    plot(ax_act, A_paw.t_rel_ms(m_paw)/1000, A_paw.activation(m_paw)+act_offsets(1), ...
        '-', 'Color', c_paw_x, 'LineWidth', lw*1.2);
    plot(ax_act, A_ear.t_rel_ms(m_ear)/1000, A_ear.activation(m_ear)+act_offsets(2), ...
        '-', 'Color', c_ear_x, 'LineWidth', lw*1.2);

    xlim(ax_act, xlim_this);
    ylim(ax_act, [-0.02 1.02]);

    if ic == 1
        ylabel(ax_act, 'activation', 'FontName', font_name, 'FontSize', font_size);
    end
    set(ax_act, 'XTickLabel', []);
    grid(ax_act, 'off');

    % width matches the real trial duration
    ax_act.Position(3) = plot_width;

    if ic > 1
        ax_act.YTick = [];
    end

    if ~isempty(act_ylim)
        ax_act.YLim = act_ylim;
    end

    % --- make scale ---
    if ic == 1
        line(ax_act, (xlim_this(2)-0.1)*[1 1], [0 0.1], 'Color','k', 'LineWidth',1);
        text(xlim_this(2), 0.05, sprintf('0.1(basis %d)', basis_idx), ...
            'FontSize',font_size, 'FontName',font_name, 'Interpreter','none')
    end

    if ic == 1
        text(ax_act, xlim_this(1), 0.9, sprintf('basis %d', basis_idx), ...
            'FontName', font_name, 'FontSize', font_size, ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
    end


    % -------- velocity panel --------
    ax2 = axes('Parent', hf, 'Units','centimeters', ...
        'Position', [x0 y_vel col_width vel_h], ...
        'FontName', font_name, 'FontSize', font_size, ...
        'LineWidth', 0.5, 'Box', 'off');
    hold(ax2, 'on');

    vel_true = true;
    local_plot_feature(ax2, tr, 'LeftPaw', 'vx_cm_s', 1, c_paw_x, lw, use_valid, vel_offsets(1), vel_true);
    local_plot_feature(ax2, tr, 'LeftPaw', 'vy_cm_s', 1, c_paw_y, lw*1.5, use_valid, vel_offsets(2), vel_true);
    local_plot_feature(ax2, tr, 'LeftEar', 'vx_cm_s', 1, c_ear_x, lw, use_valid, vel_offsets(3), vel_true);
    local_plot_feature(ax2, tr, 'LeftEar', 'vy_cm_s', 1, c_ear_y, lw*1.5, use_valid, vel_offsets(4), vel_true);

    % xline(ax2, 0, '--', 'LineWidth', 0.5);
    xlim(ax2, xlim_this);
    % adjust the width of this plot based on data length
    ax2.Position(3) = plot_width;
    if ic == 1
        ylabel(ax2, 'velocity', 'FontName', font_name, 'FontSize', font_size);
    end
    grid(ax2, 'off');
    set(ax2, 'XTickLabel', []);

    if show_legend && ic == 1 && false
        legend(ax2, {'paw vx','paw vy','ear vx','ear vy'}, ...
            'Location', 'best', 'Box', 'off', 'FontSize', font_size-1);
    end

    % --- make scale ---
    if ic == 1
        line(ax2, (xlim_this(2)-0.1)*[1 1], [-20 0], 'Color','k', 'LineWidth',1);
        text(xlim_this(2), -10, '10 cm/s', 'FontSize',font_size, 'FontName',font_name)
    end

    if ic > 1
        ax2.YTick = [];
    end

    % --- decide y range ---
    if ~isempty(vel_ylim)
        ax2.YLim = vel_ylim;
    end

    % -------- spike raster --------
    ax3 = axes('Parent', hf, 'Units','centimeters', ...
        'Position', [x0 y_spk col_width spike_h], ...
        'FontName', font_name, 'FontSize', font_size, ...
        'LineWidth', 0.5, 'Box', 'off');
    hold(ax3, 'on');

    spk = spike_times_ms(spike_times_ms >= tr.t_start & spike_times_ms <= tr.t_end);
    spk_rel_s = (spk - tr.press_time) / 1000;

    for s = 1:numel(spk_rel_s)
        line(ax3, [spk_rel_s(s) spk_rel_s(s)], [0 1], 'Color', 'k', 'LineWidth', 0.5);
    end
    % xline(ax3, 0, '--', 'LineWidth', 0.5);
    xlim(ax3, xlim_this);
    ax3.Position(3) = plot_width;
    ylim(ax3, [0 1]);
    yticks(ax3, []);
    if ic == 1
        ylabel(ax3, 'spk', 'FontName', font_name, 'FontSize', font_size);
    end
    xlabel(ax3, 'time from press (s)', 'FontName', font_name, 'FontSize', font_size);
    grid(ax3, 'off');
end

x0 = left_m + ncol*(col_width + hgap);
% add the legend column
ax_label = axes('Parent', hf, 'Units','centimeters', ...
    'Position', [x0 y_spa col_width space_h], ...
    'FontName', font_name, 'FontSize', font_size, ...
    'LineWidth', 0.5, 'Box', 'off');
hold(ax_label, 'on');

ax_label.XLim = [0 2];
ax_label.YLim = [0 10];
ax_label.YDir = 'reverse';

line([0 .1], [1 1], 'Color', c_paw_x)
line([0 .1], [2 2], 'Color', c_paw_y)
line([0 .1], [3 3], 'Color', c_ear_x)
line([0 .1], [4 4], 'Color', c_ear_x)

legend(ax_label, {'paw vx','paw vy','ear vx','ear vy'}, ...
    'Location', 'best', 'Box', 'off', 'FontSize', font_size-1);
 
axis off

% --- reshape the size of this figure ---
adjust_figure_size(hf, 1.5);

% -------------------- save --------------------
if save_figure
    adjust_figure_size(hf, 1);

    press_tag = strjoin(string(trial_press_times), "_");
    press_tag = regexprep(press_tag, '[^\w-]+', '_');

    if ~isempty(fig_tag)
        figName = sprintf('trial_features_activation_spikes_%s_%s_%s', ...
            local_safe_str(unit_id), press_tag, local_safe_str(fig_tag));
    else
        figName = sprintf('trial_features_activation_spikes_%s_%s', ...
            local_safe_str(unit_id), press_tag);
    end

    outFolder = fullfile(pwd, 'figure', 'glm');
    if ~exist(outFolder, 'dir')
        mkdir(outFolder);
    end

    save_fig(hf, figName, outFolder, 'Formats', {"png","pdf"});

    write_meta( ...
        figName, ...
        'MetaFolder', outFolder, ...
        'Description', 'Example trials showing paw/ear position, velocity, basis activation, and spike raster', ...
        'Purpose', 'To illustrate the construction of basis-function activation and its temporal relationship to behavior and spiking', ...
        'GeneratorFunction', 'Kin.plot_trial_columns_features_and_spikes.m', ...
        'GeneratorScript', '', ...
        'Inputs', { ...
            sprintf('unit_id: %s', string(unit_id)), ...
            sprintf('trial_press_times: %s', strjoin(string(trial_press_times), ', ')), ...
            sprintf('basis_idx: %d', basis_idx), ...
            sprintf('figure_name: %s', fig_name) ...
        });
end

end

function local_plot_feature(ax, tr, body_part, feat_name, sign_flip, color_this, lw, use_valid, y_offset, is_vel)

if nargin<10 || isempty(is_vel)
    is_vel = false;
end
if ~isfield(tr, body_part)
    return
end
S = tr.(body_part);
if ~isfield(S, feat_name) || ~isfield(S, 'time')
    return
end

t_abs = S.time(:);
t_rel_s = (t_abs - tr.press_time) / 1000;

if use_valid && isfield(S, 'valid')
    m = logical(S.valid(:));
else
    m = true(size(t_abs));
end

yy = S.(feat_name)(:);
yy = sign_flip * yy + y_offset;

plot(ax, t_rel_s(m), yy(m), '-', 'Color', color_this, 'LineWidth', lw);
if is_vel
    yline(ax, y_offset, 'linestyle', ':', 'Color', color_this, 'LineWidth', lw);
end
end

function act = compute_bodypart_basis_activation(trial_info_entry, basis, basis_idx, body_part)
%COMPUTE_BODYPART_BASIS_ACTIVATION
% Compute basis activation over time for one body part in one trial.
%
% Inputs
%   trial_info_entry   one element of trial_info
%   basis              basis struct
%   basis_idx          scalar basis index, 1..basis.K
%   body_part          e.g. 'LeftPaw' or 'LeftEar'
%
% Output
%   act struct with fields:
%       .trial
%       .press_time
%       .body_part
%       .basis_idx
%       .center_x
%       .center_y
%       .time_ms
%       .t_rel_ms
%       .x_rel_cm
%       .y_rel_cm
%       .valid
%       .activation

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