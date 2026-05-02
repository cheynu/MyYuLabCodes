function fig = plotChemoEffect(obj)

%%
opts.color = GPSColor(); % Color class for GPS
opts.mk = ["o", "x"]; % Scatter marker for correct and others
opts.ls = [":", "-.", "-"]; % Line style for [ShortFP, MedFP, LongFP]
opts.lw = [0.5, 1, 1.5]; % Line width for [ShortFP, MedFP, LongFP]

opts.session_date = char(obj.Sessions);
opts.session_date = opts.session_date(:, 5:8);

opts.plotsize = [8    4;
                 8.5  3.5;
                 8    2;
                 8.5  5;
                 5    5;
                 4    4];

opts.sep_col = 1.2;
opts.sep_row = 1.5;

opts.bandwidth = 0.05;

%%
cp.session_control = obj.Sessions(obj.Label=="Control");
cp.session_chemo   = obj.Sessions(obj.Label=="Chemo");

cp.date_control    = char(cp.session_control);
cp.date_control    = string(cp.date_control(:, 5:8));
cp.date_chemo      = char(cp.session_chemo);
cp.date_chemo      = string(cp.date_chemo(:, 5:8));

if length(cp.session_chemo) ~= length(cp.session_control)
    fprintf("The numbers of control and chemo sessions dont match.\n");
    return
end

cp.indx_control    = ismember(obj.BehavTable.SessionDate, cp.session_control);
cp.indx_chemo      = ismember(obj.BehavTable.SessionDate, cp.session_chemo);

cp.behav_control   = obj.BehavTable(cp.indx_control, :);
cp.behav_chemo     = obj.BehavTable(cp.indx_chemo, :);
cp.ind_control     = obj.Ind(cp.indx_control, :);
cp.ind_chemo       = obj.Ind(cp.indx_chemo, :);

cp.trial_control   = cp.behav_control.TrialStartTime + cp.behav_control.CentInTime;
cp.trial_chemo     = cp.behav_chemo.TrialStartTime   + cp.behav_chemo.CentInTime;

cp.num_session_pairs = length(cp.session_control);
cp.session_sep       = zeros(1, cp.num_session_pairs-1);
for s = 1:cp.num_session_pairs-1
    i_control   = find(cp.behav_control.SessionDate==cp.session_control(s), 1, 'last');
    i_chemo     = find(cp.behav_chemo.SessionDate==cp.session_chemo(s), 1, 'last');
    end_control = cp.trial_control(i_control);
    end_chemo   = cp.trial_chemo(i_chemo);

    cp.session_sep(s) = max([end_control, end_chemo]) + 5;

    if s==1
        cp.trial_control(i_control+1:end) = cp.trial_control(i_control+1:end) + cp.session_sep(s);
        cp.trial_chemo(i_chemo+1:end)     = cp.trial_chemo(i_chemo+1:end) + cp.session_sep(s);
    else
        cp.trial_control(i_control+1:end) = cp.trial_control(i_control+1:end) + cp.session_sep(s) - cp.session_sep(s-1);
        cp.trial_chemo(i_chemo+1:end)     = cp.trial_chemo(i_chemo+1:end) + cp.session_sep(s) - cp.session_sep(s-1);
    end
end

%%
fig = figure(24); clf(24);
set(gcf, 'unit', 'centimeters', 'position', [2 1 35.5 23.4], 'paperpositionmode', 'auto', 'color', 'w');

set_fig_title(fig, obj.Subject+" / "+obj.Task+" / "+obj.Sessions(1)+"\_"+obj.Sessions(end)+" / ChemoEffect");

%% Set axes and plot
%% Maze diagram
ha1 = axes;
set(ha1, 'units', 'centimeters', 'position', [2.8+2*(opts.sep_row+opts.plotsize(1, 1))+5.5 1.5+3*(opts.sep_col+opts.plotsize(1, 2)), opts.plotsize(1, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_diagram(ha1, opts);

%% Performance
% Hold duration scatter
% Control
ha21 = axes;
set(ha21, 'units', 'centimeters', 'position', [1.5+0*(opts.sep_row+opts.plotsize(1, 1)) 1.5+3*(opts.sep_col+opts.plotsize(1, 2))+2.7, opts.plotsize(3, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_scatter(ha21, obj, cp, "Control", opts);
set(ha21, 'xtick', [], 'xlabel', []);

% Chemo
ha22 = axes;
set(ha22, 'units', 'centimeters', 'position', [1.5+0*(opts.sep_row+opts.plotsize(1, 1)) 1.5+3*(opts.sep_col+opts.plotsize(1, 2)), opts.plotsize(3, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_scatter(ha22, obj, cp, "Chemo", opts);

% Performance track
ha3 = axes;
set(ha3, 'units', 'centimeters', 'position', [1.5+1*(opts.sep_row+opts.plotsize(1, 1)) 1.5+3*(opts.sep_col+opts.plotsize(1, 2)), opts.plotsize(4, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_performance_track(ha3, obj, cp, opts);

% Performance compare
ha4 = axes;
set(ha4, 'units', 'centimeters', 'position', [2+2*(opts.sep_row+opts.plotsize(1, 1)) 1.5+3*(opts.sep_col+opts.plotsize(1, 2)), opts.plotsize(5, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_performance_compare(ha4, obj, opts);

% ha41 = axes;
% set(ha41, 'units', 'centimeters', 'position', [2+2*(opts.sep_row+opts.plotsize(1, 1))+3 1.5+3*(opts.sep_col+opts.plotsize(1, 2))+.5, 0.4*opts.plotsize(5, :) ], 'nextplot', 'add', 'fontsize', 7);
% plot_performance_compare(ha41, obj, opts);
% set(ha41, 'xlim', [0 8], 'ylim', [0 8], 'xlabel', [], 'ylabel', [], 'xtick', 0:2:8, 'ytick', 0:2:8, 'title', []);

% legend
ha42 = axes;
set(ha42, 'units', 'centimeters', 'position', [2+2*(opts.sep_row+opts.plotsize(1, 1))+5.1 1.5+3*(opts.sep_col+opts.plotsize(1, 2))+2, [1.5 3] ], 'nextplot', 'add', 'fontsize', 7);
line(ha42, [0 .6], [0 0], 'Color', opts.color.Correct, 'LineWidth', 1);
text(ha42, .7, 0, 'Correct', 'FontSize', 8, 'Color', opts.color.Correct);
line(ha42, [0 .6], [1 1], 'Color', opts.color.Premature, 'LineWidth', 1);
text(ha42, .7, 1, 'Premature', 'FontSize', 8, 'Color', opts.color.Premature);
line(ha42, [0 .6], [2 2], 'Color', opts.color.Wrong, 'LineWidth', 1);
text(ha42, .7, 2, 'Wrong', 'FontSize', 8, 'Color', opts.color.Wrong);
line(ha42, [0 .6], [3 3], 'Color', opts.color.Late, 'LineWidth', 1);
text(ha42, .7, 3, 'Late', 'FontSize', 8, 'Color', opts.color.Late);

line(ha42, [0 .6], [5 5], 'Color', 'k', 'LineWidth', 1, 'LineStyle', '-')
scatter(ha42, 0.3, 5, 12, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k', 'LineWidth', 1);
text(ha42, .7, 5, 'Control', 'FontSize', 8, 'Color', 'k');
line(ha42, [0 .6], [6 6], 'Color', 'k', 'LineWidth', 1, 'LineStyle', ':')
scatter(ha42, 0.3, 6, 12, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'LineWidth', 1);
text(ha42, .7, 6, 'Chemo', 'FontSize', 8, 'Color', 'k');

set(ha42, 'xlim', [0 2], 'ylim', [0 7], 'xcolor', 'none', 'ycolor', 'none', 'ydir', 'reverse', 'color', 'none');

%% Hold duration
% Hold duration violin plot
ha5 = axes;
set(ha5, 'units', 'centimeters', 'position', [1.5+0*(opts.sep_row+opts.plotsize(1, 1)) 1.5+2*(opts.sep_col+opts.plotsize(1, 2)), opts.plotsize(1, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_violin(ha5, obj, opts);

% Hold duration statistic
% Median
ha61 = axes;
set(ha61, 'units', 'centimeters', 'position', [1.5+1*(opts.sep_row+opts.plotsize(1, 1)) 1.5+2*(opts.sep_col+opts.plotsize(1, 2)), opts.plotsize(6, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_median_compare(ha61, obj, opts);

% IQR
ha62 = axes;
set(ha62, 'units', 'centimeters', 'position', [1.8+1*(opts.sep_row+opts.plotsize(1, 1))+4.5 1.5+2*(opts.sep_col+opts.plotsize(1, 2)), opts.plotsize(6, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_iqr_compare(ha62, obj, opts);
set(ha62, 'ylabel', []);

% Hold duration PDF
% Right
ha71 = axes;
set(ha71, 'units', 'centimeters', 'position', [1.5+0*(opts.sep_row+opts.plotsize(1, 1)) 1.5+1*(opts.sep_col+opts.plotsize(1, 2)), opts.plotsize(2, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_pdf(ha71, obj, "R", opts);

% Left
ha72 = axes;
set(ha72, 'units', 'centimeters', 'position', [1.5+0*(opts.sep_row+opts.plotsize(1, 1)) 1.5+0*(opts.sep_col+opts.plotsize(1, 2))+0.5, opts.plotsize(2, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_pdf(ha72, obj, "L", opts);

ha71.YLim(2) = max([ha71.YLim(2) ha72.YLim(2)]);
ha72.YLim(2) = ha71.YLim(2);

% Hold duration CDF
% Right
ha81 = axes;
set(ha81, 'units', 'centimeters', 'position', [1.5+1*(opts.sep_row+opts.plotsize(1, 1)) 1.5+1*(opts.sep_col+opts.plotsize(1, 2)), opts.plotsize(2, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_cdf(ha81, obj, "R", opts);

% Left
ha82 = axes;
set(ha82, 'units', 'centimeters', 'position', [1.5+1*(opts.sep_row+opts.plotsize(1, 1)) 1.5+0*(opts.sep_col+opts.plotsize(1, 2))+0.5, opts.plotsize(2, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_cdf(ha82, obj, "L", opts);

%% Reaction time
% Reaction time violin
ha9 = axes;
set(ha9, 'units', 'centimeters', 'position', [2+2*(opts.sep_row+opts.plotsize(1, 1)) 1.5+2*(opts.sep_col+opts.plotsize(1, 2)), opts.plotsize(1, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_reaction_time_violin(ha9, obj, opts);

% reaction time compare
ha10 = axes;
set(ha10, 'units', 'centimeters', 'position', [2+3*(opts.sep_row+opts.plotsize(1, 1)) 1.5+2*(opts.sep_col+opts.plotsize(1, 2)), opts.plotsize(6, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_reaction_time_median_compare(ha10, obj, opts);

%% Movement time
% movement time violin
ha11 = axes;
set(ha11, 'units', 'centimeters', 'position', [2+2*(opts.sep_row+opts.plotsize(1, 1)) 1.5+1*(opts.sep_col+opts.plotsize(1, 2)), opts.plotsize(1, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_movement_time_violin(ha11, obj, opts);

% movement time median
ha12 = axes;
set(ha12, 'units', 'centimeters', 'position', [2+3*(opts.sep_row+opts.plotsize(1, 1)) 1.5+1*(opts.sep_col+opts.plotsize(1, 2)), opts.plotsize(6, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_movement_time_median_compare(ha12, obj, opts);

%% Shuttle time
% log shuttle time violin
ha13 = axes;
set(ha13, 'units', 'centimeters', 'position', [2+2*(opts.sep_row+opts.plotsize(1, 1)) 1.5+0*(opts.sep_col+opts.plotsize(1, 2)), opts.plotsize(1, :) .* [1/3, 1] ], 'nextplot', 'add', 'fontsize', 8);
plot_shuttle_time_violin(ha13, obj, cp, opts);

% %% Interruption
% % Interruption histogram
% ha14 = axes;
% set(ha14, 'units', 'centimeters', 'position', [2+2*(opts.sep_row+opts.plotsize(1, 1))+4.5 2+0*(opts.sep_col+opts.plotsize(1, 2)), opts.plotsize(2, :) .* [3/5 1] ], 'nextplot', 'add', 'fontsize', 8);
% plot_interruption(ha14, obj, cp, opts);

%% ha1. Make a diagram of the setup
    function plot_diagram(ax, opts)

        x = [1 3 5 8 9   11  11  9   8 5 3 1 1];
        y = [0 0 2 2 1.2 1.2 4.8 4.8 4 4 6 6 0];

        patch(ax, 'XData', x, 'YData', y, 'FaceColor', 'none', 'EdgeColor', 'k', 'linewidth', 2);

        viscircles(ax, [9.6, 3], 0.3, 'color', 'k', 'LineWidth', 1);
        text(ax, 8.6, 3, 'Init', 'FontWeight','bold', 'HorizontalAlignment', 'center');
        viscircles(ax, [3.5, 3], 0.3,  'color', 'k', 'LineWidth', 1);
        text(ax, 3.9, 3, 'Cent', 'FontWeight', 'bold');

        viscircles(ax, [3, 1.5], 0.3, 'color', opts.color.PortL);
        text(ax, 1.2, 1.5, 'Left', 'FontWeight','bold', 'HorizontalAlignment', 'left', 'Color', opts.color.PortL);
        viscircles(ax, [3, 4.5], 0.3,  'color', opts.color.PortR);
        text(ax, 1.2, 4.5, 'Right', 'FontWeight', 'bold', 'HorizontalAlignment', 'left', 'Color', opts.color.PortR);

        set(ax, 'Color', 'none', 'XColor', 'none', 'YColor', 'none', 'ylim', [0 6], 'xlim', [0 12]);
    end

%% ha2. Plot every trial's hold duration during training
    function plot_hold_duration_scatter(ax, obj, cp, lb, opts)

        for fp_this = 1:length(obj.MixedFP)
            yline(ax, obj.MixedFP(fp_this), 'Color', [.8 .8 .8], 'LineWidth', opts.lw(fp_this), 'LineStyle', ':', 'Alpha', 0.4);
        end
        if ~isempty(cp.session_sep)
            xline(ax, cp.session_sep, 'Color', [.7 .7 .7], 'LineWidth', 1, 'LineStyle', '-');
        end

        switch lower(lb)
            case {'control', 'ctrl'}
                hd  = cp.behav_control.HoldDuration;
                fp  = cp.behav_control.FP;
                ind = cp.ind_control;
                tk  = cp.trial_control;
            case {'chemo'}
                hd  = cp.behav_chemo.HoldDuration;
                fp  = cp.behav_chemo.FP;
                ind = cp.ind_chemo;
                tk  = cp.trial_chemo;
        end

        % port 1 wrong (defined by their action, which is different from target)
        scatter(ax, tk(ind.wrongL), hd(ind.wrongL), ...
            22*fp(ind.wrongL), opts.color.PortL, opts.mk(2), 'MarkerEdgeAlpha', 0.6, 'linewidth', 1);

        % port 2 wrong
        scatter(ax, tk(ind.wrongR), hd(ind.wrongR), ...
            22*fp(ind.wrongR), opts.color.PortR, opts.mk(2), 'MarkerEdgeAlpha', 0.6, 'linewidth', 1);

        % premature
        scatter(ax, tk(ind.premature), hd(ind.premature), ...
            22*fp(ind.premature), opts.color.Premature, opts.mk(2), 'MarkerEdgeAlpha', 0.6, 'linewidth', 1);

        % late
        scatter(ax, tk(ind.late), hd(ind.late), ...
            22*fp(ind.late), opts.color.Late, opts.mk(2), 'MarkerEdgeAlpha', 0.6, 'linewidth', 1);

        % port 1 correct (defined by their action, which is also the target for correct response)
        scatter(ax, tk(ind.correctL), hd(ind.correctL), ...
            18*fp(ind.correctL), opts.color.PortL, opts.mk(1), 'MarkerEdgeAlpha', 0.6, 'linewidth', 1);

        % port 2 correct
        scatter(ax, tk(ind.correctR), hd(ind.correctR), ...
            18*fp(ind.correctR), opts.color.PortR, opts.mk(1), 'MarkerEdgeAlpha', 0.6, 'linewidth', 1);

        switch lower(lb)
            case {'control', 'ctrl'}
                t = "\it{Control ";
                for s_this = 1:cp.num_session_pairs
                    if s_this < cp.num_session_pairs
                        t = t + cp.date_control(s_this) + "/";
                    else
                        t = t + cp.date_control(s_this) + "}";
                    end
                end
                ax.Title.String = t;
                ax.Title.Color  = opts.color.Control;
            case {'chemo'}
                t = "\it{Chemo ";
                for s_this = 1:cp.num_session_pairs
                    if s_this < cp.num_session_pairs
                        t = t + cp.date_chemo(s_this) + "/";
                    else
                        t = t + cp.date_chemo(s_this) + "}";
                    end
                end
                ax.Title.String = t;
                ax.Title.Color  = opts.color.Treat;
        end
        ax.Title.FontWeight  = 'bold';
        ax.Title.FontSize    = 9;
        ax.Title.Interpreter = 'tex';

        ax.XLabel.String = 'Time in training (s)';
        ax.YLabel.String = 'Hold duration (s)';
        set(ax, 'xlim', [0 max([cp.trial_control(end) cp.trial_chemo(end)])+5], 'ylim', [0 2.5], 'ticklength', [0.01 0.1]);
    end

%% ha3. Plot performance track of each session
    function plot_performance_track(ax, obj, cp, opts)

        if ~isempty(cp.session_sep)
            xline(ax, cp.session_sep, 'Color', [.7 .7 .7], 'LineWidth', 1, 'LineStyle', '-');
        end
        s_sep = [0 cp.session_sep];

        for s_this = 1:cp.num_session_pairs
            ind_control = find(obj.PerformanceTrack.Sessions==cp.session_control(s_this));
            plot(ax, obj.PerformanceTrack.WinPos(ind_control)+s_sep(s_this), obj.PerformanceTrack.CorrectRatio(ind_control),   'linestyle', '-', 'color', opts.color.Correct, ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', opts.color.Correct,   'markeredgecolor', 'w');
            plot(ax, obj.PerformanceTrack.WinPos(ind_control)+s_sep(s_this), obj.PerformanceTrack.WrongRatio(ind_control),     'linestyle', '-', 'color', opts.color.Wrong, ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', opts.color.Wrong,     'markeredgecolor', 'w');
            plot(ax, obj.PerformanceTrack.WinPos(ind_control)+s_sep(s_this), obj.PerformanceTrack.PrematureRatio(ind_control), 'linestyle', '-', 'color', opts.color.Premature, ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', opts.color.Premature, 'markeredgecolor', 'w');
            plot(ax, obj.PerformanceTrack.WinPos(ind_control)+s_sep(s_this), obj.PerformanceTrack.LateRatio(ind_control),      'linestyle', '-', 'color', opts.color.Late, ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', opts.color.Late,      'markeredgecolor', 'w');

            ind_chemo = find(obj.PerformanceTrack.Sessions==cp.session_chemo(s_this));
            plot(ax, obj.PerformanceTrack.WinPos(ind_chemo)+s_sep(s_this), obj.PerformanceTrack.CorrectRatio(ind_chemo),   'linestyle', ':', 'color', opts.color.Correct, ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', opts.color.Correct,   'markeredgecolor', 'w');
            plot(ax, obj.PerformanceTrack.WinPos(ind_chemo)+s_sep(s_this), obj.PerformanceTrack.WrongRatio(ind_chemo),     'linestyle', ':', 'color', opts.color.Wrong, ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', opts.color.Wrong,     'markeredgecolor', 'w');
            plot(ax, obj.PerformanceTrack.WinPos(ind_chemo)+s_sep(s_this), obj.PerformanceTrack.PrematureRatio(ind_chemo), 'linestyle', ':', 'color', opts.color.Premature, ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', opts.color.Premature, 'markeredgecolor', 'w');
            plot(ax, obj.PerformanceTrack.WinPos(ind_chemo)+s_sep(s_this), obj.PerformanceTrack.LateRatio(ind_chemo),      'linestyle', ':', 'color', opts.color.Late, ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', opts.color.Late,      'markeredgecolor', 'w');
        end

        ax.XLabel.String = 'Time in training (s)';
        ax.YLabel.String = 'Performance (%)';
        set(ax, 'XLim', [0 max([cp.trial_control(end) cp.trial_chemo(end)])+5], 'YLim', [0 100]);
    end

%% ha4. Plot performance comparation
    function plot_performance_compare(ax, obj, opts)

        line(ax, [0 100], [0 100], 'LineStyle', ':', 'LineWidth', 1, 'Color', 'k');

        perf_control = obj.PerformanceControl;
        perf_chemo   = obj.PerformanceChemo;

        r_short = obj.PerformanceControl.Foreperiod==0.5 & obj.PerformanceControl.TargetPort=="R";
        l_short = obj.PerformanceControl.Foreperiod==0.5 & obj.PerformanceControl.TargetPort=="L";
        r_med   = obj.PerformanceControl.Foreperiod==1   & obj.PerformanceControl.TargetPort=="R";
        l_med   = obj.PerformanceControl.Foreperiod==1   & obj.PerformanceControl.TargetPort=="L";
        r_long  = obj.PerformanceControl.Foreperiod==1.5 & obj.PerformanceControl.TargetPort=="R";
        l_long  = obj.PerformanceControl.Foreperiod==1.5 & obj.PerformanceControl.TargetPort=="L";

        r_all   = obj.PerformanceControl.Foreperiod==0   & obj.PerformanceControl.TargetPort=="R";
        l_all   = obj.PerformanceControl.Foreperiod==0   & obj.PerformanceControl.TargetPort=="L";

        scatter(ax, perf_control.PrematureRatio(r_short | r_med | r_long), perf_chemo.PrematureRatio(r_short | r_med | r_long), ...
            [.5 1 1.5]*16, 'Marker', '^', 'MarkerFaceColor', opts.color.Premature, 'MarkerEdgeColor', opts.color.PortR, ...
            'MarkerFaceAlpha', 0.4, 'MarkerEdgeAlpha', 0.5, ...
            'LineWidth', 1);
        scatter(ax, perf_control.PrematureRatio(l_short | l_med | l_long), perf_chemo.PrematureRatio(l_short | l_med | l_long), ...
            [.5 1 1.5]*16, 'Marker', '^', 'MarkerFaceColor', opts.color.Premature, 'MarkerEdgeColor', opts.color.PortL, ...
            'MarkerFaceAlpha', 0.4, 'MarkerEdgeAlpha', 0.5, ...
            'LineWidth', 1);
%         plot(ax, [perf_control.PrematureRatio(r_all) perf_chemo.PrematureRatio(r_all)], [perf_control.PrematureRatio(l_all) perf_chemo.PrematureRatio(l_all)], ...
%             'Color', [opts.color.Premature 0.6], 'LineWidth', 1.5);
        scatter(ax, perf_control.PrematureRatio(r_all), perf_chemo.PrematureRatio(r_all), 36, ...
            'Marker', 'o', 'MarkerFaceColor', opts.color.Premature, 'MarkerEdgeColor', opts.color.PortR, ...
            'MarkerFaceAlpha', 0.8, 'MarkerEdgeAlpha', 0.9, ...
            'LineWidth', 1);
        scatter(ax, perf_control.PrematureRatio(l_all), perf_chemo.PrematureRatio(l_all), 36, ...
            'Marker', 'o', 'MarkerFaceColor', opts.color.Premature, 'MarkerEdgeColor', opts.color.PortL, ...
            'MarkerFaceAlpha', 0.8, 'MarkerEdgeAlpha', 0.9, ...
            'LineWidth', 1);

        scatter(ax, perf_control.WrongRatio(r_short | r_med | r_long), perf_chemo.WrongRatio(r_short | r_med | r_long), ...
            [.5 1 1.5]*16, 'Marker', '^', 'MarkerFaceColor', opts.color.Wrong, 'MarkerEdgeColor', opts.color.PortR, ...
            'MarkerFaceAlpha', 0.5, 'MarkerEdgeAlpha', 0.5, ...
            'LineWidth', 1);
        scatter(ax, perf_control.WrongRatio(l_short | l_med | l_long), perf_chemo.WrongRatio(l_short | l_med | l_long), ...
            [.5 1 1.5]*16, 'Marker', '^', 'MarkerFaceColor', opts.color.Wrong, 'MarkerEdgeColor', opts.color.PortL, ...
            'MarkerFaceAlpha', 0.5, 'MarkerEdgeAlpha', 0.5, ...
            'LineWidth', 1);
%         plot(ax, [perf_control.WrongRatio(r_all) perf_chemo.WrongRatio(r_all)], [perf_control.WrongRatio(l_all) perf_chemo.WrongRatio(l_all)], ...
%             'Color', [opts.color.Wrong 0.6], 'LineWidth', 1.5);
        scatter(ax, perf_control.WrongRatio(r_all), perf_chemo.WrongRatio(r_all), 36, ...
            'Marker', 'o', 'MarkerFaceColor', opts.color.Wrong, 'MarkerEdgeColor', opts.color.PortR, ...
            'MarkerFaceAlpha', 0.7, 'MarkerEdgeAlpha', 0.9, ...
            'LineWidth', 1);
        scatter(ax, perf_control.WrongRatio(l_all), perf_chemo.WrongRatio(l_all), 36, ...
            'Marker', 'o', 'MarkerFaceColor', opts.color.Wrong, 'MarkerEdgeColor', opts.color.PortL, ...
            'MarkerFaceAlpha', 0.7, 'MarkerEdgeAlpha', 0.9, ...
            'LineWidth', 1);

        scatter(ax, perf_control.LateRatio(r_short | r_med | r_long), perf_chemo.LateRatio(r_short | r_med | r_long), ...
            [.5 1 1.5]*16, 'Marker', '^', 'MarkerFaceColor', opts.color.Late, 'MarkerEdgeColor', opts.color.PortR, ...
            'MarkerFaceAlpha', 0.4, 'MarkerEdgeAlpha', 0.5, ...
            'LineWidth', 1);
        scatter(ax, perf_control.LateRatio(l_short | l_med | l_long), perf_chemo.LateRatio(l_short | l_med | l_long), ...
            [.5 1 1.5]*16, 'Marker', '^', 'MarkerFaceColor', opts.color.Late, 'MarkerEdgeColor', opts.color.PortL, ...
            'MarkerFaceAlpha', 0.4, 'MarkerEdgeAlpha', 0.5, ...
            'LineWidth', 1);
%         plot(ax, [perf_control.LateRatio(r_all) perf_chemo.LateRatio(r_all)], [perf_control.LateRatio(l_all) perf_chemo.LateRatio(l_all)], ...
%             'Color', [opts.color.Late 0.6], 'LineWidth', 1.5);
        scatter(ax, perf_control.LateRatio(r_all), perf_chemo.LateRatio(r_all), 36, ...
            'Marker', 'o', 'MarkerFaceColor', opts.color.Late, 'MarkerEdgeColor', opts.color.PortR, ...
            'MarkerFaceAlpha', 0.9, 'MarkerEdgeAlpha', 0.9, ...
            'LineWidth', 1);
        scatter(ax, perf_control.LateRatio(l_all), perf_chemo.LateRatio(l_all), 36, ...
            'Marker', 'o', 'MarkerFaceColor', opts.color.Late, 'MarkerEdgeColor', opts.color.PortL, ...
            'MarkerFaceAlpha', 0.9, 'MarkerEdgeAlpha', 0.9, ...
            'LineWidth', 1);

        scatter(ax, perf_control.CorrectRatio(r_short | r_med | r_long), perf_chemo.CorrectRatio(r_short | r_med | r_long), ...
            [.5 1 1.5]*16, 'Marker', '^', 'MarkerFaceColor', opts.color.Correct, 'MarkerEdgeColor', opts.color.PortR, ...
            'MarkerFaceAlpha', 0.4, 'MarkerEdgeAlpha', 0.5, ...
            'LineWidth', 1);
        scatter(ax, perf_control.CorrectRatio(l_short | l_med | l_long), perf_chemo.CorrectRatio(l_short | l_med | l_long), ...
            [.5 1 1.5]*16, 'Marker', '^', 'MarkerFaceColor', opts.color.Correct, 'MarkerEdgeColor', opts.color.PortL, ...
            'MarkerFaceAlpha', 0.4, 'MarkerEdgeAlpha', 0.5, ...
            'LineWidth', 1);
%         plot(ax, [perf_control.CorrectRatio(r_all) perf_chemo.CorrectRatio(r_all)], [perf_control.CorrectRatio(l_all) perf_chemo.CorrectRatio(l_all)], ...
%             'Color', [opts.color.Correct 0.6], 'LineWidth', 1.5);
        scatter(ax, perf_control.CorrectRatio(r_all), perf_chemo.CorrectRatio(r_all), 36, ...
            'Marker', 'o', 'MarkerFaceColor', opts.color.Correct, 'MarkerEdgeColor', opts.color.PortR, ...
            'MarkerFaceAlpha', 0.8, 'MarkerEdgeAlpha', 0.9, ...
            'LineWidth', 1);
        scatter(ax, perf_control.CorrectRatio(l_all), perf_chemo.CorrectRatio(l_all), 36, ...
            'Marker', 'o', 'MarkerFaceColor', opts.color.Correct, 'MarkerEdgeColor', opts.color.PortL, ...
            'MarkerFaceAlpha', 0.8, 'MarkerEdgeAlpha', 0.9, ...
            'LineWidth', 1);

        text(ax, 50, 100, "Performance (%)", 'FontSize', 9, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

        ax.XLabel.String     = "Control";
        ax.XLabel.Color      = opts.color.Control;
        ax.XLabel.FontWeight = "Bold";

        ax.YLabel.String     = "Chemo";
        ax.YLabel.Color      = opts.color.Treat;
        ax.YLabel.FontWeight = "Bold";

        set(ax, 'xlim', [0 100], 'ylim', [0 100]);
    end

%% Hold duration violin
    function plot_hold_duration_violin(ax, obj, opts)

        dcz_ind = 2 * (1:length(obj.MixedFP))';
        num_dcz = length(obj.MixedFP);
        patch(ax, 'XData', [dcz_ind-.5 dcz_ind-.5 dcz_ind+.5 dcz_ind+.5]', 'YData', repmat([0; 100; 100; 0], 1, num_dcz), ...
            'FaceColor', opts.color.Treat, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

        for fp_this = 1:length(obj.MixedFP)
            line(ax, -.5 + 2*[fp_this-0.45 fp_this+0.45], [obj.MixedFP(fp_this) obj.MixedFP(fp_this)], 'Color', 'k', 'LineWidth', .5, 'LineStyle', '-');
        end

        num_violin = length(obj.Ports)*2*length(obj.MixedFP);
        thisHD = nan(height(obj.BehavTable), num_violin);

        for fp_this = 1:length(obj.MixedFP)
            for p_this = 1:length(obj.Ports)
                thisHD(1:length(obj.HDSorted.Control{fp_this, p_this}), 4*(fp_this-1)+p_this)   = obj.HDSorted.Control{fp_this, p_this};
                thisHD(1:length(obj.HDSorted.Chemo{fp_this, p_this})  , 4*(fp_this-1)+p_this+2) = obj.HDSorted.Chemo{fp_this, p_this};
            end
        end

        thisHD(all(isnan(thisHD), 2), :) = [];

        violinplot({thisHD(:, 2:2:end), thisHD(:, 1:2:end)}, obj.Sessions, ...
            'ViolinColor', {repmat(opts.color.PortR, num_violin/2, 1), repmat(opts.color.PortL, num_violin/2, 1)}, ...
            'MarkerSize', 8, 'ShowMedian', false, 'ShowWhisker', false, 'ShowBox', false, 'Bandwidth', obj.BandWidth);

        scatter(ax, ceil((1:num_violin)/2) + repmat([-.02 .02], 1, num_violin/2), median(thisHD, 'omitnan'), 32, ...
            repmat([opts.color.PortL; opts.color.PortR], num_violin/2, 1), ...
            'filled', 'LineWidth', 1, 'MarkerEdgeColor', [.3 .3 .3], 'MarkerFaceAlpha', 0.6);

        ax.XLabel.String = 'Foreperiod (s)';
        ax.YLabel.String = 'Hold duration (s)';
        set(ax, 'xlim', [.5 2*length(obj.MixedFP)+.5], 'ylim', [0 obj.Bins.HoldDuration(end)], 'xtick', 1.5:2:2*length(obj.MixedFP), ...
            'xticklabel', obj.MixedFP, 'ticklength', [0.01 0.1], 'box', 'off');
    end

%% Hold duration comparation
% median
    function plot_hold_duration_median_compare(ax, obj, opts)
       
        ind_l = find(ismember(obj.HDStat.Control.thisFP, obj.MixedFP) & obj.HDStat.Control.Port=="L");
        ind_r = find(ismember(obj.HDStat.Control.thisFP, obj.MixedFP) & obj.HDStat.Control.Port=="R");

%         for i = 1:length(ind_l)
%             plot(ax, [obj.HDStat.Control.Median(ind_l(i)) obj.HDStat.Chemo.Median(ind_l(i))], [obj.HDStat.Control.Median(ind_r(i)) obj.HDStat.Chemo.Median(ind_r(i))], ...
%                 'Color', [0 0 0 0.6], 'LineWidth', 1.5);
%         end
        
        scatter(ax, obj.HDStat.Control.Median(ind_l), obj.HDStat.Chemo.Median(ind_l), ...
            [.5 1 1.5]*24, 'Marker', 'o', 'MarkerFaceColor', opts.color.PortL, 'MarkerEdgeColor', opts.color.PortL, ...
            'MarkerFaceAlpha', 0.6, 'MarkerEdgeAlpha', 1, ...
            'LineWidth', 1.5);
        scatter(ax, obj.HDStat.Control.Median(ind_r), obj.HDStat.Chemo.Median(ind_r), ...
            [.5 1 1.5]*24, 'Marker', 'o', 'MarkerFaceColor', opts.color.PortR, 'MarkerEdgeColor', opts.color.PortR, ...
            'MarkerFaceAlpha', 0.6, 'MarkerEdgeAlpha', 1, ...
            'LineWidth', 1.5);

        ax.YLabel.String     = "Chemo";
        ax.YLabel.Color      = opts.color.Treat;
        ax.YLabel.FontWeight = "Bold";

        ax.XLabel.String     = "Control";
        ax.XLabel.Color      = opts.color.Control;
        ax.XLabel.FontWeight = "Bold";

        set(ax, 'xlimmode', 'auto', 'ylimmode', 'auto');
        ax.XLim = [0 2];
%         ax.XLim = [min([ax.XLim(1) ax.YLim(1)]) max([ax.XLim(2) ax.YLim(2)])] .* [.95 1.05];
        ax.YLim = ax.XLim;
        ax.XTick = ax.YTick;

        text(ax, mean(ax.XLim), ax.YLim(2), "HD median (s)", 'FontSize', 9, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

        line(ax, [0 100], [0 100], 'Color', 'k', 'LineStyle', ':', 'LineWidth', .5);
    end

% IQR
    function plot_hold_duration_iqr_compare(ax, obj, opts)

        ind_l = find(ismember(obj.HDStat.Control.thisFP, obj.MixedFP) & obj.HDStat.Control.Port=="L");
        ind_r = find(ismember(obj.HDStat.Control.thisFP, obj.MixedFP) & obj.HDStat.Control.Port=="R");

%         for i = 1:length(ind_l)
%             plot(ax, [obj.HDStat.Control.IQR(ind_l(i)) obj.HDStat.Chemo.IQR(ind_l(i))], [obj.HDStat.Control.IQR(ind_r(i)) obj.HDStat.Chemo.IQR(ind_r(i))], ...
%                 'Color', [0 0 0 0.6], 'LineWidth', 1.5);
%         end

        ax.YLabel.String     = "Chemo";
        ax.YLabel.Color      = opts.color.Treat;
        ax.YLabel.FontWeight = "Bold";

        ax.XLabel.String     = "Control";
        ax.XLabel.Color      = opts.color.Control;
        ax.XLabel.FontWeight = "Bold";
        
        scatter(ax, obj.HDStat.Control.IQR(ind_l), obj.HDStat.Chemo.IQR(ind_l), ...
            [.5 1 1.5]*24, 'Marker', 'o', 'MarkerFaceColor', opts.color.PortL, 'MarkerEdgeColor', opts.color.PortL, ...
            'MarkerFaceAlpha', 0.6, 'MarkerEdgeAlpha', 1, ...
            'LineWidth', 1.5);
        scatter(ax, obj.HDStat.Control.IQR(ind_r), obj.HDStat.Chemo.IQR(ind_r), ...
            [.5 1 1.5]*24, 'Marker', 'o', 'MarkerFaceColor', opts.color.PortR, 'MarkerEdgeColor', opts.color.PortR, ...
            'MarkerFaceAlpha', 0.6, 'MarkerEdgeAlpha', 1, ...
            'LineWidth', 1.5);

        set(ax, 'xlimmode', 'auto', 'ylimmode', 'auto');
        ax.XLim = [0 1];
%         ax.XLim = [min([ax.XLim(1) ax.YLim(1)]) max([ax.XLim(2) ax.YLim(2)])] .* [.95 1.05];
        ax.YLim = ax.XLim;
        ax.XTick = ax.YTick;

        text(ax, mean(ax.XLim), ax.YLim(2), "HD IQR (s)", 'FontSize', 9, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

        line(ax, [0 100], [0 100], 'Color', 'k', 'LineStyle', ':', 'LineWidth', .5);
    end

%% Hold duration density
% Prob. density
    function plot_hold_duration_pdf(ax, obj, port, opts)

        p = obj.Ports==upper(string(port));

        for fp = 1:length(obj.MixedFP)

            xline(ax, obj.MixedFP(fp), 'color', [.7 .7 .7], 'linewidth', 1, 'LineStyle', opts.ls(fp));

            pdf_control = obj.HDPDF.Control{fp, p};
            pdf_chemo   = obj.HDPDF.Chemo{fp, p};

            fill(ax, [pdf_control.x flip(pdf_control.x)], [pdf_control.ci(1,:) flip(pdf_control.ci(2,:))], 'r', ...
                'FaceColor', opts.color.Control, 'FaceAlpha', .2, 'EdgeColor', 'none');
            plot(ax, pdf_control.x, pdf_control.f, ...
                'color', opts.color.Control, 'linewidth', 1.2, 'LineStyle', opts.ls(fp));
            fill(ax, [pdf_chemo.x flip(pdf_chemo.x)], [pdf_chemo.ci(1,:) flip(pdf_chemo.ci(2,:))], 'r', ...
                'FaceColor', opts.color.Treat, 'FaceAlpha', .2, 'EdgeColor', 'none');
            plot(ax, pdf_chemo.x, pdf_chemo.f, ...
                'color', opts.color.Treat  , 'linewidth', 1.2, 'LineStyle', opts.ls(fp));

        end

        switch upper(string(port))
            case {"L"}
                ax.XLabel.String = "Hold duration Left (s)";
                ax.XLabel.Color  = opts.color.PortL;
            case {"R"}
                ax.XLabel.String = "Hold duration Right (s)";
                ax.XLabel.Color  = opts.color.PortR;
        end
        ax.XLabel.FontWeight = "Bold";

        ax.YLabel.String = "Prob. density (1/s)";
        set(ax, 'xlim', [0 obj.Bins.HoldDuration(end)], 'ylimmode', 'auto');
    end

% Cum. distribution
    function plot_hold_duration_cdf(ax, obj, port, opts)

        p = obj.Ports==upper(string(port));

        for fp = 1:length(obj.MixedFP)

            xline(ax, obj.MixedFP(fp), 'color', [.7 .7 .7], 'linewidth', 1, 'LineStyle', opts.ls(fp));

            cdf_control = obj.HDCDF.Control{fp, p};
            cdf_chemo   = obj.HDCDF.Chemo{fp, p};

            fill(ax, [cdf_control.x flip(cdf_control.x)], [cdf_control.ci(1,:) flip(cdf_control.ci(2,:))], 'r', ...
                'FaceColor', opts.color.Control, 'FaceAlpha', .2, 'EdgeColor', 'none');
            plot(ax, cdf_control.x, cdf_control.f, ...
                'color', opts.color.Control, 'linewidth', 1.2, 'LineStyle', opts.ls(fp));
            fill(ax, [cdf_chemo.x cdf_chemo.x(end:-1:1)], [cdf_chemo.ci(1,:) cdf_chemo.ci(2, end:-1:1)], 'r', ...
                'FaceColor', opts.color.Treat, 'FaceAlpha', .2, 'EdgeColor', 'none');
            plot(ax, cdf_chemo.x, cdf_chemo.f, ...
                'color', opts.color.Treat  , 'linewidth', 1.2, 'LineStyle', opts.ls(fp));

        end

        switch upper(string(port))
            case {"L"}
                ax.XLabel.String = "Hold duration Left (s)";
                ax.XLabel.Color  = opts.color.PortL;
            case {"R"}
                ax.XLabel.String = "Hold duration Right (s)";
                ax.XLabel.Color  = opts.color.PortR;
        end
        ax.XLabel.FontWeight = "Bold";

        ax.YLabel.String = "Cum. distribution";
        set(ax, 'xlim', [0 obj.Bins.HoldDuration(end)], 'ylim', [0 1]);
    end

%% Reaction time violin
    function plot_reaction_time_violin(ax, obj, opts)

        dcz_ind = 2 * (1:length(obj.MixedFP))';
        num_dcz = length(obj.MixedFP);
        patch(ax, 'XData', [dcz_ind-.5 dcz_ind-.5 dcz_ind+.5 dcz_ind+.5]', 'YData', repmat([0; 100; 100; 0], 1, num_dcz), ...
            'FaceColor', opts.color.Treat, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

        yline(ax, .5, 'Color', [.7 .7 .7], 'LineWidth', 1.5, 'LineStyle', '--')

        num_violin = length(obj.Ports)*2*length(obj.MixedFP);
        thisRT = nan(height(obj.BehavTable), num_violin);

        for fp_this = 1:length(obj.MixedFP)
            for p_this = 1:length(obj.Ports)
                thisRT(1:length(obj.RTSorted.Control{fp_this, p_this}), 4*(fp_this-1)+p_this)   = obj.RTSorted.Control{fp_this, p_this};
                thisRT(1:length(obj.RTSorted.Chemo{fp_this, p_this})  , 4*(fp_this-1)+p_this+2) = obj.RTSorted.Chemo{fp_this, p_this};
            end
        end

        thisRT(all(isnan(thisRT), 2), :) = [];

        violinplot({thisRT(:, 2:2:end), thisRT(:, 1:2:end)}, obj.Sessions, ...
            'ViolinColor', {repmat(opts.color.PortR, num_violin/2, 1), repmat(opts.color.PortL, num_violin/2, 1)}, ...
            'MarkerSize', 8, 'ShowMedian', false, 'ShowWhisker', false, 'ShowBox', false, 'Bandwidth', obj.BandWidth);

        scatter(ax, ceil((1:num_violin)/2) + repmat([-.02 .02], 1, num_violin/2), median(thisRT, 'omitnan'), 32, ...
            repmat([opts.color.PortL; opts.color.PortR], num_violin/2, 1), ...
            'filled', 'LineWidth', 1, 'MarkerEdgeColor', [.3 .3 .3], 'MarkerFaceAlpha', 0.6);

        ax.XLabel.String = 'Foreperiod (s)';
        ax.YLabel.String = 'Reaction time (s)';
        set(ax, 'xlim', [.5 2*length(obj.MixedFP)+.5], 'ylim', [0 .6], 'xtick', 1.5:2:2*length(obj.MixedFP), ...
            'xticklabel', obj.MixedFP, 'ticklength', [0.01 0.1], 'box', 'off');
    end

%% Reaction time comparation
% median
    function plot_reaction_time_median_compare(ax, obj, opts)
       
        ind_l = find(ismember(obj.RTStat.Control.thisFP, obj.MixedFP) & obj.RTStat.Control.Port=="L");
        ind_r = find(ismember(obj.RTStat.Control.thisFP, obj.MixedFP) & obj.RTStat.Control.Port=="R");

%         for i = 1:length(ind_l)
%             plot(ax, [obj.RTStat.Control.Median(ind_l(i)) obj.RTStat.Chemo.Median(ind_l(i))], [obj.RTStat.Control.Median(ind_r(i)) obj.RTStat.Chemo.Median(ind_r(i))], ...
%                 'Color', [0 0 0 0.6], 'LineWidth', 1.5);
%         end
        
        scatter(ax, obj.RTStat.Control.Median(ind_l), obj.RTStat.Chemo.Median(ind_l), ...
            [.5 1 1.5]*24, 'Marker', 'o', 'MarkerFaceColor', opts.color.PortL, 'MarkerEdgeColor', opts.color.PortL, ...
            'MarkerFaceAlpha', 0.6, 'MarkerEdgeAlpha', 1, ...
            'LineWidth', 1.5);
        scatter(ax, obj.RTStat.Control.Median(ind_r), obj.RTStat.Chemo.Median(ind_r), ...
            [.5 1 1.5]*24, 'Marker', 'o', 'MarkerFaceColor', opts.color.PortR, 'MarkerEdgeColor', opts.color.PortR, ...
            'MarkerFaceAlpha', 0.6, 'MarkerEdgeAlpha', 1, ...
            'LineWidth', 1.5);

        ax.YLabel.String     = "Chemo";
        ax.YLabel.Color      = opts.color.Treat;
        ax.YLabel.FontWeight = "Bold";

        ax.XLabel.String     = "Control";
        ax.XLabel.Color      = opts.color.Control;
        ax.XLabel.FontWeight = "Bold";

        set(ax, 'xlimmode', 'auto', 'ylimmode', 'auto');
        ax.XLim = [0 0.3];
%         ax.XLim = [min([ax.XLim(1) ax.YLim(1)]) max([ax.XLim(2) ax.YLim(2)])] .* [.95 1.05];
        ax.YLim = ax.XLim;
        ax.YTick = ax.XTick;

        text(ax, mean(ax.XLim), ax.YLim(2), "RT median (s)", 'FontSize', 9, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

        line(ax, [0 100], [0 100], 'Color', 'k', 'LineStyle', ':', 'LineWidth', 1);
    end

%% Movement time violin
    function plot_movement_time_violin(ax, obj, opts)

        dcz_ind = 2 * (1:length(obj.MixedFP))';
        num_dcz = length(obj.MixedFP);
        patch(ax, 'XData', [dcz_ind-.5 dcz_ind-.5 dcz_ind+.5 dcz_ind+.5]', 'YData', repmat([0; 100; 100; 0], 1, num_dcz), ...
            'FaceColor', opts.color.Treat, 'FaceAlpha', 0.2, 'EdgeColor', 'none');


        num_violin = length(obj.Ports)*2*length(obj.MixedFP);
        thisMT = nan(height(obj.BehavTable), num_violin);

        for fp_this = 1:length(obj.MixedFP)
            for p_this = 1:length(obj.Ports)
                thisMT(1:length(obj.MTSorted.Control{fp_this, p_this}), 4*(fp_this-1)+p_this)   = obj.MTSorted.Control{fp_this, p_this};
                thisMT(1:length(obj.MTSorted.Chemo{fp_this, p_this})  , 4*(fp_this-1)+p_this+2) = obj.MTSorted.Chemo{fp_this, p_this};
            end
        end

        thisMT(all(isnan(thisMT), 2), :) = [];

        violinplot({thisMT(:, 2:2:end), thisMT(:, 1:2:end)}, obj.Sessions, ...
            'ViolinColor', {repmat(opts.color.PortR, num_violin/2, 1), repmat(opts.color.PortL, num_violin/2, 1)}, ...
            'MarkerSize', 8, 'ShowMedian', false, 'ShowWhisker', false, 'ShowBox', false, 'Bandwidth', obj.BandWidth);

        scatter(ax, ceil((1:num_violin)/2) + repmat([-.02 .02], 1, num_violin/2), median(thisMT, 'omitnan'), 32, ...
            repmat([opts.color.PortL; opts.color.PortR], num_violin/2, 1), ...
            'filled', 'LineWidth', 1, 'MarkerEdgeColor', [.3 .3 .3], 'MarkerFaceAlpha', 0.6);

        ax.XLabel.String = 'Foreperiod (s)';
        ax.YLabel.String = 'Movement time (s)';
        set(ax, 'xlim', [.5 2*length(obj.MixedFP)+.5], 'ylim', [0 obj.Bins.MovementTime(end)], 'xtick', 1.5:2:2*length(obj.MixedFP), ...
            'xticklabel', obj.MixedFP, 'ticklength', [0.01 0.1], 'box', 'off');
    end

%% Movement time comparation
    function plot_movement_time_median_compare(ax, obj, opts)
       
        ind_l = find(ismember(obj.MTStat.Control.thisFP, obj.MixedFP) & obj.MTStat.Control.Port=="L");
        ind_r = find(ismember(obj.MTStat.Control.thisFP, obj.MixedFP) & obj.MTStat.Control.Port=="R");

%         for i = 1:length(ind_l)
%             plot(ax, [obj.MTStat.Control.Median(ind_l(i)) obj.MTStat.Chemo.Median(ind_l(i))], [obj.MTStat.Control.Median(ind_r(i)) obj.MTStat.Chemo.Median(ind_r(i))], ...
%                 'Color', [0 0 0 0.6], 'LineWidth', 1.5);
%         end
        
        scatter(ax, obj.MTStat.Control.Median(ind_l), obj.MTStat.Chemo.Median(ind_l), ...
            [.5 1 1.5]*24, 'Marker', 'o', 'MarkerFaceColor', opts.color.PortL, 'MarkerEdgeColor', opts.color.PortL, ...
            'MarkerFaceAlpha', 0.6, 'MarkerEdgeAlpha', 1, ...
            'LineWidth', 1.5);
        scatter(ax, obj.MTStat.Control.Median(ind_r), obj.MTStat.Chemo.Median(ind_r), ...
            [.5 1 1.5]*24, 'Marker', 'o', 'MarkerFaceColor', opts.color.PortR, 'MarkerEdgeColor', opts.color.PortR, ...
            'MarkerFaceAlpha', 0.6, 'MarkerEdgeAlpha', 1, ...
            'LineWidth', 1.5);

        ax.YLabel.String     = "Chemo";
        ax.YLabel.Color      = opts.color.Treat;
        ax.YLabel.FontWeight = "Bold";

        ax.XLabel.String     = "Control";
        ax.XLabel.Color      = opts.color.Control;
        ax.XLabel.FontWeight = "Bold";

        set(ax, 'xlimmode', 'auto', 'ylimmode', 'auto');
        ax.XLim = [0 .8];
%         ax.XLim = [min([ax.XLim(1) ax.YLim(1)]) max([ax.XLim(2) ax.YLim(2)])] .* [.95 1.05];
        ax.YLim = ax.XLim;
        ax.YTick = ax.XTick;

        text(ax, mean(ax.XLim), ax.YLim(2), "MT median (s)", 'FontSize', 9, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

        line(ax, [0 100], [0 100], 'Color', 'k', 'LineStyle', ':', 'LineWidth', 1);
    end

%% log Shuttle time violin
    function plot_shuttle_time_violin(ax, obj, cp, opts)

        patch(ax, 'XData', [1.5 1.5 2.5 2.5]', 'YData', [-1; 100; 100; -1], ...
            'FaceColor', opts.color.Treat, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

        thisSTLog = nan(height(obj.BehavTable), 2);

        STLog_control = log(cp.behav_control.ShuttleTime);
        [~, ~, indrmv] = rmoutliers_custome(STLog_control);
        STLog_control(indrmv) = nan;

        STLog_chemo = log(cp.behav_chemo.ShuttleTime);
        [~, ~, indrmv] = rmoutliers_custome(STLog_chemo);
        STLog_chemo(indrmv) = nan;

        thisSTLog(1:length(STLog_control), 1) = STLog_control;
        thisSTLog(1:length(STLog_chemo), 2)  = STLog_chemo;

        violinplot(thisSTLog, ["Control", "Chemo"], ...
            'ViolinColor', [opts.color.Control; opts.color.Treat], ...
            'MarkerSize', 2, 'ShowMedian', false, 'ShowWhisker', false, 'ShowBox', false, 'BandWidth', obj.BandWidth);

        scatter(ax, 1:2, median(thisSTLog, 'omitnan'), 40, ...
            ones(2, 3), ...
            'filled', 'LineWidth', 1, 'MarkerEdgeColor', [.3 .3 .3]);

        ax.XLabel.String = 'Treatment';
        ax.YLabel.String = 'Shuttle time (s)';
        set(ax, 'xlim', [.5 2.5], 'ylim', [-1 obj.Bins.ShuttleTimeLog(end)], 'xtick', 1:2, ...
            'xticklabel', ["Control", "Chemo"], ...
            'ytick', -1:3, 'yticklabel', ["10^-1", "10^0", "10^1", "10^2", "10^3"], ...
            'ticklength', [0.01 0.1], 'box', 'off');
    end

%% Interruption
    function plot_interruption(ax, obj, cp, opts)

        for fp_this = 1:length(obj.MixedFP)
            xline(ax, obj.MixedFP(fp_this), 'color', [.7 .7 .7], 'linewidth', opts.lw(fp_this), 'LineStyle', '-');
        end

        nums_control = zeros(1, length(obj.Bins.Interruption)-1);
        nums_chemo   = zeros(1, length(obj.Bins.Interruption)-1);
        for i = 1:length(nums_control)
            nums_control(i) = sum(cp.behav_control.HoldDuration(cp.behav_control.Stage==1) >= obj.Bins.Interruption(i));
            nums_chemo(i)   = sum(cp.behav_chemo.HoldDuration(cp.behav_control.Stage==1) >= obj.Bins.Interruption(i));
        end

        h_control = histcounts(obj.InterruptionControl.On, "BinEdges", obj.Bins.Interruption) ./ nums_control;
        bar(ax, obj.Bins.Interruption(1:end-1)+.5*obj.Bins.widthInter, h_control, 1, 'FaceColor', opts.color.Control , 'FaceAlpha', 0.25, 'EdgeColor', 'k', 'EdgeAlpha', 0.6);
        h_chemo   = histcounts(obj.InterruptionChemo.On  , "BinEdges", obj.Bins.Interruption) ./ nums_chemo;
        bar(ax, obj.Bins.Interruption(1:end-1)+.5*obj.Bins.widthInter, h_chemo  , 1, 'FaceColor', opts.color.Treat   , 'FaceAlpha', 0.25, 'EdgeColor', 'k', 'EdgeAlpha', 0.6);

        y_control = smoothdata(h_control, 'gaussian', 0.18*(length(h_control)));
        y_chemo   = smoothdata(h_chemo  , 'gaussian', 0.18*(length(h_chemo)));

        plot(ax, obj.Bins.Interruption(1:end-1)+.5*obj.Bins.widthInter, y_control, 'Color', opts.color.Control, 'LineStyle', '-', 'LineWidth', 1.5);
        plot(ax, obj.Bins.Interruption(1:end-1)+.5*obj.Bins.widthInter, y_chemo  , 'Color', opts.color.Treat  , 'LineStyle', '-', 'LineWidth', 1.5);

        ax.YLabel.String = "Interruptions / trial";
        ax.XLabel.String = "Hold duration (s)";
        set(ax, 'xlim', [0 1.5]);
    end

end
