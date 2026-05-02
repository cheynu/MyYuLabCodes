function hf = plot_example_toptrajectory_frame(S, varargin)
%PLOT_EXAMPLE_TOPTRAJECTORY_FRAME
% Plot a saved example top-view frame with tracked head trajectory overlaid.
%
% Input
%   S   struct with fields:
%         .frame
%         .TT
%         .anm_session
%         .trial
%         .index   (recommended; selected frame row within TT)
%         .time    (recommended; selected frame time)
%
% S.TT is expected to be a top-view table containing columns such as:
%   trial, lever_phase, time, head_x, head_y, head_theta_x, head_theta_y,
%   kept_mask, keep_run_mask, ...
%
% Name-value
%   'FigureWidthCm'      default 4
%   'FigureNumber'       default []
%   'SaveFigure'         default true
%   'UseKeptOnly'        default true
%   'Phases'             default ["toLever","fromLever"]
%   'DotSize'            default 8
%   'FrameDotSize'       default 45
%   'FrameDotColor'      default [0.55 0.2 0.75]
%   'HeadLineLengthPx'   default 30
%   'HeadLineWidth'      default 1.2
%   'ShowHeadLine'       default true
%   'ShowTrajectory'     default true
%   'ReverseX'           default true
%
% Output
%   hf   figure handle

p = inputParser;
p.addRequired('S', @(x) isstruct(x) && isfield(x, 'frame') && isfield(x, 'TT'));

p.addParameter('FigureWidthCm', 4, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('FigureNumber', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x)));
p.addParameter('SaveFigure', true, @(x) islogical(x) && isscalar(x));
p.addParameter('UseKeptOnly', true, @(x) islogical(x) && isscalar(x));
p.addParameter('Phases', ["toLever","fromLever"], @(x) ischar(x) || isstring(x) || iscell(x));

p.addParameter('DotSize', 2, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('FrameDotSize', 5, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('FrameDotColor', [0.55 0.2 0.75], @(x) isnumeric(x) && numel(x)==3);

p.addParameter('HeadLineLengthPx', 60, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('HeadLineWidth', 1.2, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('ShowHeadLine', true, @(x) islogical(x) && isscalar(x));
p.addParameter('ShowTrajectory', true, @(x) islogical(x) && isscalar(x));
p.addParameter('ReverseX', false, @(x) islogical(x) && isscalar(x));

p.parse(S, varargin{:});

fig_w = p.Results.FigureWidthCm;
fig_num = p.Results.FigureNumber;
save_figure = p.Results.SaveFigure;
use_kept_only = p.Results.UseKeptOnly;
phases = string(p.Results.Phases);
dot_size = p.Results.DotSize;
frame_dot_size = p.Results.FrameDotSize;
frame_dot_color = p.Results.FrameDotColor;
head_line_len = p.Results.HeadLineLengthPx;
head_line_w = p.Results.HeadLineWidth;
show_head_line = p.Results.ShowHeadLine;
show_traj = p.Results.ShowTrajectory;
reverse_x = p.Results.ReverseX;

TT = S.TT;
frame = S.frame;

TT.trial = string(TT.trial);
TT.lever_phase = string(TT.lever_phase);

if isfield(S, 'trial') && ~isempty(S.trial)
    TT = TT(TT.trial == string(S.trial), :);
end

if ~isempty(phases)
    if any(strcmpi(phases, "all")) || any(strcmpi(phases, "both"))
        phases = ["toLever","fromLever"];
    end
    TT = TT(ismember(TT.lever_phase, phases), :);
end

if use_kept_only
    if ismember('kept_mask', TT.Properties.VariableNames)
        TT = TT(logical(TT.kept_mask), :);
    elseif ismember('keep_run_mask', TT.Properties.VariableNames)
        TT = TT(logical(TT.keep_run_mask), :);
    end
end

if isempty(TT)
    error('No rows remain in TT after filtering.');
end

% colors by phase
phase_colors = struct();
phase_colors.toLever   = [255 197 112] / 255;
phase_colors.fromLever = [191 198 196] / 255;

[nr, nc, ~] = size(frame);
fig_h = fig_w * nr / nc;

if isempty(fig_num)
    hf = figure('Color', 'w', 'Units', 'centimeters', ...
        'Position', [2 2 fig_w fig_h], 'Visible', 'on');
else
    hf = figure(fig_num); clf(hf);
    set(hf, 'Color', 'w', 'Units', 'centimeters', ...
        'Position', [2 2 fig_w fig_h], 'Visible', 'on');
end

ax = axes('Parent', hf, 'Units', 'normalized', 'Position', [0 0 1 1]);
imshow(frame, 'Parent', ax);
hold(ax, 'on');

% -------------------------------------------------
% trajectories by phase
% -------------------------------------------------
if show_traj
    u_phases = unique(TT.lever_phase, 'stable');

    for i = 1:numel(u_phases)
        ph = u_phases(i);
        m = TT.lever_phase == ph;

        x = TT.head_x(m);
        y = TT.head_y(m);

        if isfield(phase_colors, char(ph))
            c = phase_colors.(char(ph));
        else
            c = [1 1 1];
        end

        scatter(ax, x, y, dot_size, ...
            'MarkerFaceColor', c, ...
            'MarkerEdgeColor', 'none', ...
            'MarkerFaceAlpha', 0.65);
    end
end

% -------------------------------------------------
% selected frame row
% -------------------------------------------------
row_sel = local_find_selected_row(S, TT);

hx = TT.head_x(row_sel);
hy = TT.head_y(row_sel);

% big purple dot at current head position
scatter(ax, hx, hy, frame_dot_size, ...
    'MarkerFaceColor', frame_dot_color, ...
    'MarkerEdgeColor', 'w', ...
    'LineWidth', 0.5);

% head direction line
if show_head_line && ...
        ismember('head_theta_x', TT.Properties.VariableNames) && ...
        ismember('head_theta_y', TT.Properties.VariableNames)

    dx = TT.head_theta_x(row_sel);
    dy = TT.head_theta_y(row_sel);

    if isfinite(dx) && isfinite(dy)
        x1 = hx;
        y1 = hy;
        x2 = hx + head_line_len * dx;
        y2 = hy + head_line_len * dy;

        line(ax, [x1 x2], [y1 y2], ...
            'Color', frame_dot_color, ...
            'LineWidth', head_line_w);
    end
end

% flip left-right if desired
if reverse_x
    set(ax, 'XDir', 'reverse');
end

axis(ax, 'image');
axis(ax, 'off');

% -------------------------------------------------
% scale bar (5 cm x 5 cm)
% -------------------------------------------------
if isfield(S, 'scale_px_per_cm')
    scale_px_per_cm = S.scale_px_per_cm;
else
    scale_px_per_cm = 250/10; % fallback
end

bar_cm = 5;
bar_px = bar_cm * scale_px_per_cm;
margin_px = 20;

% because XDir may be reversed, use the same logic as before
x0 = margin_px + bar_px;
y0 = nr - margin_px;

line(ax, [x0, x0 - bar_px], [y0 - 50, y0 - 50], ...
    'Color', 'w', 'LineWidth', 1.5);

line(ax, [x0, x0], [y0 - 50, y0 - bar_px - 50], ...
    'Color', 'w', 'LineWidth', 1.5);

% -------------------------------------------------
% save
% -------------------------------------------------
if save_figure
    outFolder = fullfile(pwd, 'figure', 'examples');
    if ~exist(outFolder, 'dir')
        mkdir(outFolder);
    end

    figName = sprintf('example_toptrajectory_%s_%s', ...
        local_safe_str(S.anm_session), local_safe_str(S.trial));

    save_fig(hf, figName, outFolder, 'Formats', {"png","pdf"});

    write_meta( ...
        figName, ...
        'MetaFolder', outFolder, ...
        'Description', 'Example top-view frame with overlaid head trajectory and head direction', ...
        'Purpose', 'Visualize raw top-view frame and selected head position/orientation for an example trial', ...
        'GeneratorFunction', 'plot_example_toptrajectory_frame', ...
        'GeneratorScript', '', ...
        'Inputs', { ...
            sprintf('anm_session: %s', string(S.anm_session)), ...
            sprintf('trial: %s', string(S.trial)), ...
            sprintf('index: %d', local_getfield_safe(S, 'index', NaN)), ...
            sprintf('time: %.6g', local_getfield_safe(S, 'time', NaN)), ...
            sprintf('gain: %.6g', local_getfield_safe(S, 'gain', NaN)), ...
            sprintf('use kept only: %d', use_kept_only), ...
            sprintf('phases: %s', strjoin(phases, ', ')), ...
            sprintf('head line length px: %.3g', head_line_len) ...
        });
end

end

function row_sel = local_find_selected_row(S, TT)

row_sel = [];

% first try exact original index if it still matches filtered TT
if isfield(S, 'time') && ~isempty(S.time)
    mt = round(TT.time) == round(S.time);
    if isfield(S, 'trial') && ~isempty(S.trial)
        mt = mt & (TT.trial == string(S.trial));
    end
    hit = find(mt, 1, 'first');
    if ~isempty(hit)
        row_sel = hit;
        return
    end
end


% next try matching by time and trial
if isfield(S, 'time') && ~isempty(S.time)
    mt = TT.time == S.time;
    if isfield(S, 'trial') && ~isempty(S.trial)
        mt = mt & (TT.trial == string(S.trial));
    end
    hit = find(mt, 1, 'first');
    if ~isempty(hit)
        row_sel = hit;
        return
    end
end

% fallback: middle row
row_sel = round(height(TT)/2);
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