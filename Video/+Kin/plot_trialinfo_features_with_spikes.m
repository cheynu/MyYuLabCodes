function hf = plot_trialinfo_features_with_spikes(trial_info, spike_times_ms, trial_press_times, varargin)
%PLOT_TRIAL_COLUMNS_FEATURES_AND_SPIKES
% One column per trial. Within each column, stacked traces:
%   Paw x, Paw y, Paw vx, Paw vy,
%   Ear x, Ear y, Ear vx, Ear vy,
%   Spike raster
%
% x and y are sign-flipped so decreases appear upward/increasing visually.
% vx and vy are left unchanged.
%
% Inputs
%   trial_info         struct array
%   spike_times_ms     spike times in ms, absolute/original timebase
%   trial_press_times  vector/string/cell of press_time identifiers to plot
%
% Name-value
%   'ColWidth'         default 4.5   (cm)
%   'ColHeight'        default 16    (cm)
%   'FigureNumber'     default []
%   'FontName'         default 'Helvetica'
%   'FontSize'         default 7
%   'LineWidth'        default 0.7
%   'UseValidOnly'     default true
%   'HorizontalGap'    default 0.8   (cm)
%   'TopMargin'        default 0.8   (cm)
%   'BottomMargin'     default 0.6   (cm)
%   'LeftMargin'       default 0.7   (cm)
%   'RightMargin'      default 0.4   (cm)
%   'InnerGap'         default 0.08  (cm)
%   'FigureName'       default 'Trial features and spikes'
%
% Example
%   hf = plot_trial_columns_features_and_spikes(trial_info, spike_times_ms, ...
%       [786178 1856098], 'ColWidth', 4.2, 'ColHeight', 15);

p = inputParser;
p.addRequired('trial_info', @(x) isstruct(x) && ~isempty(x));
p.addRequired('spike_times_ms', @(x) isnumeric(x) && isvector(x));
p.addRequired('trial_press_times', @(x) isnumeric(x) || isstring(x) || iscell(x));

p.addParameter('ColWidth', 4.5, @(x) isnumeric(x) && isscalar(x) && x > 1);
p.addParameter('ColHeight', 16, @(x) isnumeric(x) && isscalar(x) && x > 4);
p.addParameter('FigureNumber', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x)));
p.addParameter('FontName', 'Helvetica', @(x) ischar(x) || isstring(x));
p.addParameter('FontSize', 7, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('LineWidth', 0.7, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('UseValidOnly', true, @(x) islogical(x) && isscalar(x));
p.addParameter('HorizontalGap', 0.8, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.addParameter('TopMargin', 0.8, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.addParameter('BottomMargin', 0.6, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.addParameter('LeftMargin', 0.7, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.addParameter('RightMargin', 0.4, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.addParameter('InnerGap', 0.08, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.addParameter('FigureName', 'Trial features and spikes', @(x) ischar(x) || isstring(x));
p.parse(trial_info, spike_times_ms, trial_press_times, varargin{:});

col_width   = p.Results.ColWidth;
col_height  = p.Results.ColHeight;
fig_num     = p.Results.FigureNumber;
font_name   = char(string(p.Results.FontName));
font_size   = p.Results.FontSize;
lw          = p.Results.LineWidth;
use_valid   = p.Results.UseValidOnly;
hgap        = p.Results.HorizontalGap;
top_m       = p.Results.TopMargin;
bot_m       = p.Results.BottomMargin;
left_m      = p.Results.LeftMargin;
right_m     = p.Results.RightMargin;
inner_gap   = p.Results.InnerGap;
fig_name    = char(string(p.Results.FigureName));

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

% 9 stacked rows: 8 traces + 1 raster
n_rows = 9;
usable_h = col_height - top_m - bot_m - (n_rows-1)*inner_gap;
row_h = usable_h / n_rows;

fig_width = left_m + right_m + ncol*col_width + (ncol-1)*hgap;
fig_height = col_height;

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
    'Position', [left_m, fig_height-top_m+0.05, fig_width-left_m-right_m, 0.35], ...
    'String', fig_name, ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'bottom', ...
    'FontWeight', 'bold', ...
    'FontName', font_name, ...
    'FontSize', font_size+1, ...
    'Interpreter', 'none');

row_defs = { ...
    'LeftPaw', 'x_rel_cm',  'paw x';
    'LeftPaw', 'y_rel_cm',  'paw y';
    'LeftPaw', 'vx_cm_s',   'paw vx';
    'LeftPaw', 'vy_cm_s',   'paw vy';
    'LeftEar', 'x_rel_cm',  'ear x';
    'LeftEar', 'y_rel_cm',  'ear y';
    'LeftEar', 'vx_cm_s',   'ear vx';
    'LeftEar', 'vy_cm_s',   'ear vy'};

for ic = 1:ncol
    tr = trial_info(idx(ic));
    x0 = left_m + (ic-1)*(col_width + hgap);

    % column title = press_time
    annotation(hf, 'textbox', ...
        'Units', 'centimeters', ...
        'Position', [x0, fig_height-top_m-0.18, col_width, 0.25], ...
        'String', char(string(tr.press_time)), ...
        'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontName', font_name, ...
        'FontSize', font_size, ...
        'Interpreter', 'none');

    % store x-limits from first available trace
    xlim_this = [];

    % 8 feature rows
    for ir = 1:8
        body_part = row_defs{ir,1};
        feat_name = row_defs{ir,2};
        ylab = row_defs{ir,3};

        y0 = bot_m + (n_rows-ir)*(row_h + inner_gap);

        ax = axes('Parent', hf, 'Units','centimeters', ...
            'Position', [x0 y0 col_width row_h], ...
            'FontName', font_name, ...
            'FontSize', font_size, ...
            'LineWidth', 0.5, ...
            'Box', 'off');
        hold(ax, 'on');

        if isfield(tr, body_part)
            S = tr.(body_part);
            t_abs = S.time(:);
            t_rel_s = (t_abs - tr.press_time) / 1000;

            if isempty(xlim_this)
                xlim_this = [min(t_rel_s) max(t_rel_s)];
            end

            if use_valid && isfield(S, 'valid')
                m = logical(S.valid(:));
            else
                m = true(size(t_abs));
            end

            yy = S.(feat_name)(:);

            % flip x and y only
            if feat_name == "x_rel_cm" || strcmp(feat_name, 'x_rel_cm') || ...
               feat_name == "y_rel_cm" || strcmp(feat_name, 'y_rel_cm')
                yy = -yy;
            end

            plot(ax, t_rel_s(m), yy(m), 'k-', 'LineWidth', lw);
            xline(ax, 0, '--', 'LineWidth', 0.5);

            ylabel(ax, ylab, 'FontName', font_name, 'FontSize', font_size);

            if ir < 8
                set(ax, 'XTickLabel', []);
            else
                xlabel(ax, 't from press (s)', 'FontName', font_name, 'FontSize', font_size);
            end

            xlim(ax, xlim_this);
            grid(ax, 'on');
        else
            axis(ax, 'off');
        end
    end

    % spike raster row
    y0 = bot_m;
    ax = axes('Parent', hf, 'Units','centimeters', ...
        'Position', [x0 y0 col_width row_h], ...
        'FontName', font_name, ...
        'FontSize', font_size, ...
        'LineWidth', 0.5, ...
        'Box', 'off');
    hold(ax, 'on');

    % use trial bounds if available
    t_min = tr.t_start;
    t_max = tr.t_end;
    spk = spike_times_ms(spike_times_ms >= t_min & spike_times_ms <= t_max);
    spk_rel_s = (spk - tr.press_time) / 1000;

    for s = 1:numel(spk_rel_s)
        line(ax, [spk_rel_s(s) spk_rel_s(s)], [0 1], 'Color', 'k', 'LineWidth', 0.5);
    end
    xline(ax, 0, '--', 'LineWidth', 0.5);

    ylabel(ax, 'spk', 'FontName', font_name, 'FontSize', font_size);
    xlabel(ax, 't from press (s)', 'FontName', font_name, 'FontSize', font_size);
    xlim(ax, xlim_this);
    ylim(ax, [0 1]);
    yticks(ax, []);
    grid(ax, 'on');
end
end