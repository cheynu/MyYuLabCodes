function hf = plot_trialinfo_vy_vs_time(trial_info, varargin)
%PLOT_TRIALINFO_VY_VS_TIME Plot vy vs time (relative to press) for selected trials.
%
% Usage:
%   hf = plot_trialinfo_vy_vs_time(trial_info)
%   hf = plot_trialinfo_vy_vs_time(trial_info, 'TrialIdx', [1 4 9 12])
%
% Name-value
%   'TrialIdx'        indices into trial_info, default random 6 trials
%   'NumTrials'       used only if TrialIdx is empty, default 6
%   'BodyParts'       default {'LeftPaw','LeftEar'}
%   'UseValidOnly'    default true
%   'FigureNumber'    default []
%   'FigureWidth'     default 16 cm
%   'FontName'        default 'Helvetica'
%   'FontSize'        default 7
%   'LineWidth'       default 0.8
%   'ReverseYSign'    default false
%                     if true, plots -vy so "upward" appears positive
%
% Notes
%   Time is computed as:
%       t_rel_ms = bodypart.time - trial.press_time
%   and converted to seconds for plotting.

p = inputParser;
p.addRequired('trial_info', @(x) isstruct(x) && ~isempty(x));
p.addParameter('TrialIdx', [], @(x) isempty(x) || isnumeric(x));
p.addParameter('NumTrials', 6, @(x) isnumeric(x) && isscalar(x) && x >= 1);
p.addParameter('BodyParts', {'LeftPaw','LeftEar'}, @(x) iscell(x) || isstring(x));
p.addParameter('UseValidOnly', true, @(x) islogical(x) && isscalar(x));
p.addParameter('FigureNumber', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x)));
p.addParameter('FigureWidth', 16, @(x) isnumeric(x) && isscalar(x) && x > 5);
p.addParameter('FontName', 'Helvetica', @(x) ischar(x) || isstring(x));
p.addParameter('FontSize', 7, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('LineWidth', 0.8, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('ReverseYSign', false, @(x) islogical(x) && isscalar(x));
p.parse(trial_info, varargin{:});

trial_idx = p.Results.TrialIdx;
n_trials_to_plot = p.Results.NumTrials;
body_parts = cellstr(string(p.Results.BodyParts(:)));
use_valid_only = p.Results.UseValidOnly;
fig_num = p.Results.FigureNumber;
fig_width = p.Results.FigureWidth;
font_name = char(string(p.Results.FontName));
font_size = p.Results.FontSize;
lw = p.Results.LineWidth;
reverse_y_sign = p.Results.ReverseYSign;

n_total = numel(trial_info);

if isempty(trial_idx)
    rng(41);
    n_trials_to_plot = min(n_trials_to_plot, n_total);
    trial_idx = randperm(n_total, n_trials_to_plot);
else
    trial_idx = trial_idx(:)';
    trial_idx = trial_idx(trial_idx >= 1 & trial_idx <= n_total);
end

n_plot = numel(trial_idx);
n_body = numel(body_parts);

if n_plot == 0
    error('No valid trial indices to plot.');
end

% layout
left = 1.0;
right = 0.5;
top = 0.8;
bottom = 0.8;
hgap = 0.7;
vgap = 0.7;

ncol = n_body;
nrow = n_plot;

usable_w = fig_width - left - right - (ncol-1)*hgap;
col_w = usable_w / ncol;
row_h = 2.2;
fig_height = top + bottom + nrow*row_h + (nrow-1)*vgap;

% figure
if isempty(fig_num)
    hf = figure('Color','w', 'Units','centimeters', ...
        'Position',[2 2 fig_width fig_height], ...
        'Visible','on');
else
    hf = figure(fig_num); clf(hf);
    set(hf, 'Color','w', 'Units','centimeters', ...
        'Position',[2 2 fig_width fig_height], ...
        'Visible','on');
end

for ir = 1:n_plot
    k = trial_idx(ir);
    tr = trial_info(k);

    for ic = 1:n_body
        bp = body_parts{ic};

        x0 = left + (ic-1)*(col_w + hgap);
        y0 = bottom + (nrow-ir)*(row_h + vgap);

        ax = axes('Parent', hf, 'Units','centimeters', ...
            'Position',[x0 y0 col_w row_h], ...
            'FontName', font_name, ...
            'FontSize', font_size, ...
            'LineWidth', 0.5, ...
            'Box', 'off');
        hold(ax, 'on');

        if isfield(tr, bp)
            S = tr.(bp);

            t_rel_s = (S.time(:) - tr.press_time) / 1000;
            vy = S.vy_cm_s(:);

            if reverse_y_sign
                vy = -vy;
            end

            if use_valid_only && isfield(S, 'valid')
                m = logical(S.valid(:));
            else
                m = true(size(vy));
            end

            plot(ax, t_rel_s(m), vy(m), 'k-', 'LineWidth', lw);

            % mark press time
            xline(ax, 0, '--', 'LineWidth', 0.6);

            % optional highlight linear blocks if present
            if isfield(S, 'linear_blocks') && ~isempty(S.linear_blocks)
                blocks = S.linear_blocks;
                if size(blocks,2) == 2
                    yl = ylim(ax);
                    for ib = 1:size(blocks,1)
                        i1 = blocks(ib,1);
                        i2 = blocks(ib,2);
                        if i1 >= 1 && i2 <= numel(t_rel_s)
                            patch(ax, ...
                                [t_rel_s(i1) t_rel_s(i2) t_rel_s(i2) t_rel_s(i1)], ...
                                [yl(1) yl(1) yl(2) yl(2)], ...
                                [0.9 0.9 0.95], ...
                                'EdgeColor', 'none', ...
                                'FaceAlpha', 0.3);
                        end
                    end
                    uistack(findobj(ax,'Type','Line'),'top');
                end
            end

            if ir == 1
                title(ax, bp, 'Interpreter','none');
            end

            if ic == 1
                ylabel(ax, sprintf('trial %d\nv_y (cm/s)', k));
            else
                ylabel(ax, 'v_y (cm/s)');
            end

            if ir == n_plot
                xlabel(ax, 'time from press (s)');
            end

            grid(ax, 'on');

            txt = sprintf('%s', tr.trial);
            text(ax, 0.02, 0.92, txt, ...
                'Units','normalized', ...
                'HorizontalAlignment','left', ...
                'VerticalAlignment','top', ...
                'FontSize', font_size, ...
                'Interpreter','none');
        else
            axis(ax, 'off');
            text(0.5, 0.5, sprintf('%s missing', bp), ...
                'Parent', ax, ...
                'Units','normalized', ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','middle', ...
                'Interpreter','none');
        end
    end
end
end