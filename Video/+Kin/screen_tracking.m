function out = screen_tracking(T, body_part)
%SCREEN_TRACKING Screen suspicious tracking points for one body part.
%
% out = screen_tracking(T, body_part)
%
% Inputs
%   T          table containing columns:
%              time, body_part, x_s, y_s, trial
%   body_part  char/string, e.g. 'LeftPaw'
%
% Behavior
%   1) Filters table for the requested body part
%   2) Plots x_s vs y_s as a scatter
%   3) Asks whether to inspect bad points
%   4) If yes, lets user click points on the scatter
%   5) Finds nearest tracked samples to the clicked locations
%   6) Extracts the corresponding trial IDs
%   7) Plots x_s vs time and y_s vs time for those trials
%
% Output
%   out.body             requested body part
%   out.trials_question  cell array of suspicious trial IDs

    %-----------------------------
    % initialize output
    %-----------------------------
    out = struct();
    out.body = char(string(body_part));
    out.trials_question = {};

    %-----------------------------
    % basic checks
    %-----------------------------
    required_vars = {'time','body_part','x_s','y_s','trial'};
    missing_vars = setdiff(required_vars, T.Properties.VariableNames);
    if ~isempty(missing_vars)
        error('screen_tracking:MissingColumns', ...
            'Missing required columns: %s', strjoin(missing_vars, ', '));
    end

    %-----------------------------
    % normalize table columns
    %-----------------------------
    bp_all    = string(T.body_part);
    trial_all = string(T.trial);

    %-----------------------------
    % filter one body part
    %-----------------------------
    this_body = string(body_part);
    mask = bp_all == this_body;

    if ~any(mask)
        warning('screen_tracking:NoRows', ...
            'No rows found for body part: %s', this_body);
        return;
    end

    Tb = T(mask, :);
    x  = Tb.x_s;
    y  = Tb.y_s;

    % remove NaN rows from clickable scatter
    good = isfinite(x) & isfinite(y);
    Tb_click = Tb(good, :);
    xg = Tb_click.x_s;
    yg = Tb_click.y_s;

    if isempty(Tb_click)
        warning('screen_tracking:NoValidXY', ...
            'No valid x_s/y_s rows found for body part: %s', this_body);
        return;
    end

    %-----------------------------
    % scatter plot
    %-----------------------------
    hf1 = figure('Name', sprintf('screen tracking: %s', this_body), ...
                 'Color', 'w', 'Visible','on', 'Units', 'Centimeters', ...
                 'Position',[2 2 25 8]);
    ax = subplot(1, 3, 1);
    scatter(xg, yg, 8, 'filled');
    xlabel('x_s');
    ylabel('y_s');
    title(sprintf('%s: x_s vs y_s', this_body), 'Interpreter', 'none');
    axis equal;
    set(gca, 'ydir', 'reverse')
    grid on;
    box off;

    %-----------------------------
    % ask user whether to inspect
    %-----------------------------
    choice = questdlg( ...
        sprintf('Check bad points for %s?', this_body), ...
        'screen tracking', ...
        'Yes', 'No', 'Yes');

    if ~strcmp(choice, 'Yes')
        return;
    end

    %-----------------------------
    % get clicks
    %-----------------------------
    figure(hf1);
    title({
        sprintf('%s: x_s vs y_s', this_body), ...
        'Click suspicious points, then press Enter'
        }, 'Interpreter', 'none');

    [xc, yc] = ginput();

    if isempty(xc)
        return;
    end

    %-----------------------------
    % map clicks to nearest samples
    %-----------------------------
    sel_idx = nan(numel(xc),1);

    for i = 1:numel(xc)
        d2 = (xg - xc(i)).^2 + (yg - yc(i)).^2;
        [~, sel_idx(i)] = min(d2);
    end

    sel_idx = unique(sel_idx(:));

    % trials containing the clicked-nearest points
    bad_trials = unique(string(Tb_click.trial(sel_idx)), 'stable');
    out.trials_question = cellstr(bad_trials);

    %-----------------------------
    % print suspicious trials
    %-----------------------------
    fprintf('\nSuspicious trials for body part: %s\n', char(this_body));
    for k = 1:numel(bad_trials)
        fprintf('  %s\n', bad_trials(k));
    end
    fprintf('\n');

    %-----------------------------
    % highlight all points from those trials in red
    %-----------------------------
    trial_mask_all = ismember(string(Tb_click.trial), bad_trials);

    hold on;
    scatter(xg(trial_mask_all), yg(trial_mask_all), 12, 'r', 'filled');
    scatter(xg(sel_idx), yg(sel_idx), 50, 'k');   % optional: clicked-nearest points
    hold off;

    legend({'all points', 'selected trials', 'clicked-nearest points'}, ...
        'Interpreter', 'none', 'Location', 'best');

    %-----------------------------
    % plot y_s versus time in one axes
    %-----------------------------
    n_trials = numel(bad_trials);
    if n_trials == 0
        return;
    end
    ax = subplot(1, 3, 2);

    hold(ax, 'on');

    legtxt = cell(n_trials, 1);

    for k = 1:n_trials
        this_trial = bad_trials(k);
        mt = string(Tb.trial) == this_trial;
        Tt = Tb(mt, :);

        % sort by time just in case
        [t_sort, ord] = sort(Tt.time);
        ys = Tt.y_s(ord);
        t_sort = t_sort - t_sort(1);
        plot(ax, t_sort, ys, '-', 'LineWidth', 1.2);

        legtxt{k} = char(this_trial);
    end

    xlabel(ax, 'time');
    ylabel(ax, 'y_s');
    title(ax, sprintf('%s | suspicious trials | y_s vs time', this_body), ...
        'Interpreter', 'none');
    % legend(ax, legtxt, 'Interpreter', 'none', 'Location', 'best');
    grid(ax, 'on');
    box(ax, 'off');
    hold(ax, 'off');

    %-----------------------------
    % third panel: trial-name list
    %-----------------------------
    ax3 = subplot(1, 3, 3);
    cla(ax3);
    hold(ax3, 'on');

    for k = 1:n_trials
        text(ax3, 1, k, sprintf('%d. %s', k, legtxt{k}), ...
            'Interpreter', 'none', ...
            'FontSize', 10, ...
            'VerticalAlignment', 'middle');
    end

    xlim(ax3, [0.8 1.2]);
    ylim(ax3, [0.5, n_trials + 0.5]);
    set(ax3, 'YDir', 'reverse');   % optional: line 1 at top
    set(ax3, 'XTick', []);
    ylabel(ax3, 'line #');
    title(ax3, 'trial labels', 'Interpreter', 'none');
    box(ax3, 'on');
    grid(ax3, 'off');
    hold(ax3, 'off');

    axis(ax3, 'off');
end