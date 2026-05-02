function fig = plotChemoEffect(obj)

%%
opts.color = GPSColor(); % Color class for GPS
opts.mk = ["o", "x"]; % Scatter marker for correct and others
opts.ls = [":", "-.", "-"]; % Line style for [ShortFP, MedFP, LongFP]
opts.lw = [0.5, 1, 1.5]; % Line width for [ShortFP, MedFP, LongFP]

opts.session_date = char(obj.Sessions);
opts.session_date = opts.session_date(:, 5:8);

opts.plotsize = [8    4;
                 6.5  3.5;
                 9    2;
                 9  5;
                 5    5;
                 4    4];

opts.sep_col = 1.5;
opts.sep_row = 1.5;

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
set(gcf, 'unit', 'centimeters', 'position', [2 1 33 18.5], 'paperpositionmode', 'auto', 'color', 'w');
set_fig_title(fig, obj.Subject+" / "+obj.TaskName+" / "+obj.Sessions(1)+"\_"+obj.Sessions(end)+" / ChemoEffect");

%% Set axes and plot
% %% Maze diagram
% ha_diagram = axes;
% set(ha_diagram, 'units', 'centimeters', 'position', [1.2+2*(opts.sep_row+opts.plotsize(1, 1)) 2+2*(opts.sep_col+opts.plotsize(1, 2)), opts.plotsize(1, :) ], 'nextplot', 'add', 'fontsize', 8);
% plot_diagram(ha_diagram, opts);

%% Performance
% Hold duration scatter
% Control
ha_hd_scatter_control = axes;
set(ha_hd_scatter_control, 'units', 'centimeters', 'position', [1.5 15, opts.plotsize(3, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_scatter(ha_hd_scatter_control, obj, cp, "Control", opts);
set(ha_hd_scatter_control, 'xtick', [], 'xlabel', []);

% Chemo
ha_hd_scatter_chemo = axes;
set(ha_hd_scatter_chemo, 'units', 'centimeters', 'position', [1.5 12.3, opts.plotsize(3, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_scatter(ha_hd_scatter_chemo, obj, cp, "Chemo", opts);

% Performance track
% Left
x_now = ha_hd_scatter_chemo.Position(1) + ha_hd_scatter_chemo.Position(3) + opts.sep_row;
y_now = ha_hd_scatter_chemo.Position(2);
ha_perf_track_l = axes;
set(ha_perf_track_l, 'units', 'centimeters', 'position', [x_now y_now, opts.plotsize(4, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_performance_track(ha_perf_track_l, obj, "L", cp, opts);

% Right
x_now = x_now + ha_perf_track_l.Position(3) + opts.sep_row;
ha_perf_track_r = axes;
set(ha_perf_track_r, 'units', 'centimeters', 'position', [x_now y_now, opts.plotsize(4, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_performance_track(ha_perf_track_r, obj, "R", cp, opts);

%% Hold duration
% Hold duration violin plot
x_now = ha_hd_scatter_chemo.Position(1);
y_now = y_now - opts.sep_col - opts.plotsize(6, 2);
ha_hd_violin = axes;
set(ha_hd_violin, 'units', 'centimeters', 'position', [x_now y_now, opts.plotsize(6, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_violin(ha_hd_violin, obj, opts);

% Hold duration statistic
% Median
x_now = x_now + ha_hd_violin.Position(3) + opts.sep_row;
ha_hd_median = axes;
set(ha_hd_median, 'units', 'centimeters', 'position', [x_now y_now, opts.plotsize(6, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_median_compare(ha_hd_median, obj, opts);

% IQR
x_now = x_now + ha_hd_median.Position(3) + opts.sep_row;
ha_hd_iqr = axes;
set(ha_hd_iqr, 'units', 'centimeters', 'position', [x_now y_now, opts.plotsize(6, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_iqr_compare(ha_hd_iqr, obj, opts);

%% Movement time
% movement time violin
x_now = ha_hd_violin.Position(1);
y_now = y_now - opts.sep_col - opts.plotsize(6, 2);
ha_mt_violin = axes;
set(ha_mt_violin, 'units', 'centimeters', 'position', [x_now y_now, opts.plotsize(6, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_movement_time_violin(ha_mt_violin, obj, opts);

% movement time median
x_now = x_now + ha_mt_violin.Position(3) + opts.sep_row;
ha_mt_median = axes;
set(ha_mt_median, 'units', 'centimeters', 'position', [x_now y_now, opts.plotsize(6, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_movement_time_median_compare(ha_mt_median, obj, opts);

%% Shuttle time
% log shuttle time violin
x_now = x_now + ha_mt_median.Position(3) + opts.sep_row;
ha_st_violin = axes;
set(ha_st_violin, 'units', 'centimeters', 'position', [x_now y_now, opts.plotsize(6, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_shuttle_time_violin(ha_st_violin, obj, cp, opts);

%% Hold duration
% Hold duration PDF
% Left
x_now = ha_hd_iqr.Position(1) + ha_hd_iqr.Position(3) + opts.sep_row + .5;
y_now = ha_hd_iqr.Position(2);
ha_hd_pdf_l = axes;
set(ha_hd_pdf_l, 'units', 'centimeters', 'position', [x_now y_now, opts.plotsize(2, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_pdf(ha_hd_pdf_l, obj, "L", opts);
set(ha_hd_pdf_l, 'xlabel', [], 'xticklabel', []);

% Right
x_now = x_now + ha_hd_pdf_l.Position(3) + opts.sep_row/2;
ha_hd_pdf_r = axes;
set(ha_hd_pdf_r, 'units', 'centimeters', 'position', [x_now y_now, opts.plotsize(2, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_pdf(ha_hd_pdf_r, obj, "R", opts);
set(ha_hd_pdf_r, 'ylabel', [], 'yticklabel', []);
set(ha_hd_pdf_r, 'xlabel', [], 'xticklabel', []);

ha_hd_pdf_l.YLim(2) = max([ha_hd_pdf_l.YLim(2) ha_hd_pdf_r.YLim(2)]);
ha_hd_pdf_r.YLim(2) = ha_hd_pdf_l.YLim(2);

% Hold duration CDF
% Left
x_now = ha_hd_pdf_l.Position(1);
y_now = ha_hd_pdf_l.Position(2) - opts.sep_col - opts.plotsize(2, 2) + 0.5;
ha_hd_cdf_l = axes;
set(ha_hd_cdf_l, 'units', 'centimeters', 'position', [x_now y_now, opts.plotsize(2, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_cdf(ha_hd_cdf_l, obj, "L", opts);

% Right
x_now = x_now + ha_hd_cdf_l.Position(3) + opts.sep_row/2;
ha_hd_cdf_r = axes;
set(ha_hd_cdf_r, 'units', 'centimeters', 'position', [x_now y_now, opts.plotsize(2, :) ], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_cdf(ha_hd_cdf_r, obj, "R", opts);
set(ha_hd_cdf_r, 'ylabel', [], 'yticklabel', []);


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

        yline(ax, obj.TargetFP, 'Color', [.8 .8 .8], 'LineWidth', 1, 'LineStyle', ':', 'Alpha', 0.7);
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
        ax.XLabel.FontWeight = "Bold";
        ax.YLabel.FontWeight = "Bold";
        set(ax, 'xlim', [0 max([cp.trial_control(end) cp.trial_chemo(end)])+5], 'ylim', [0 2.5], 'ticklength', [0.01 0.1]);
    end

%% ha3. Plot performance track of each session
    function plot_performance_track(ax, obj, port, cp, opts)

        perf_track = obj.("PerformanceTrackUncue" + upper(port));
        if ~isempty(cp.session_sep)
            xline(ax, cp.session_sep, 'Color', [.7 .7 .7], 'LineWidth', 1, 'LineStyle', '-');
        end

        s_sep = [0 cp.session_sep];

        for s_this = 1:cp.num_session_pairs
            ind_control = find(perf_track.Sessions==cp.session_control(s_this));
            plot(ax,  perf_track.WinPos(ind_control)+s_sep(s_this),  perf_track.CorrectRatio(ind_control),   'linestyle', '-', 'color', opts.color.Correct, ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', opts.color.Correct,   'markeredgecolor', 'w');
            plot(ax,  perf_track.WinPos(ind_control)+s_sep(s_this),  perf_track.WrongRatio(ind_control),     'linestyle', '-', 'color', opts.color.Wrong, ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', opts.color.Wrong,     'markeredgecolor', 'w');
            plot(ax,  perf_track.WinPos(ind_control)+s_sep(s_this),  perf_track.PrematureRatio(ind_control), 'linestyle', '-', 'color', opts.color.Premature, ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', opts.color.Premature, 'markeredgecolor', 'w');
            plot(ax,  perf_track.WinPos(ind_control)+s_sep(s_this),  perf_track.LateRatio(ind_control),      'linestyle', '-', 'color', opts.color.Late, ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', opts.color.Late,      'markeredgecolor', 'w');

            ind_chemo = find(perf_track.Sessions==cp.session_chemo(s_this));
            plot(ax,  perf_track.WinPos(ind_chemo)+s_sep(s_this),  perf_track.CorrectRatio(ind_chemo),   'linestyle', ':', 'color', .8*opts.color.Correct, ...
                'markersize', 5, 'linewidth', 1.5, 'markerfacecolor', .8*opts.color.Correct,   'markeredgecolor', 'w');
            plot(ax,  perf_track.WinPos(ind_chemo)+s_sep(s_this),  perf_track.WrongRatio(ind_chemo),     'linestyle', ':', 'color', .8*opts.color.Wrong, ...
                'markersize', 5, 'linewidth', 1.5, 'markerfacecolor', .8*opts.color.Wrong,     'markeredgecolor', 'w');
            plot(ax,  perf_track.WinPos(ind_chemo)+s_sep(s_this),  perf_track.PrematureRatio(ind_chemo), 'linestyle', ':', 'color', .8*opts.color.Premature, ...
                'markersize', 5, 'linewidth', 1.5, 'markerfacecolor', .8*opts.color.Premature, 'markeredgecolor', 'w');
            plot(ax,  perf_track.WinPos(ind_chemo)+s_sep(s_this),  perf_track.LateRatio(ind_chemo),      'linestyle', ':', 'color', .8*opts.color.Late, ...
                'markersize', 5, 'linewidth', 1.5, 'markerfacecolor', .8*opts.color.Late,      'markeredgecolor', 'w');
        end

        switch upper(port)
            case {'L'}
                ax.YLabel.String = 'Performance (%) - Left';
                ax.YLabel.Color = opts.color.PortL;
            case {'R'}
                ax.YLabel.String = 'Performance (%) - Right';
                ax.YLabel.Color = opts.color.PortR;
        end
        ax.XLabel.String = 'Time in training (s)';
        
        ax.XLabel.FontWeight = "Bold";
        ax.YLabel.FontWeight = "Bold";
        set(ax, 'XLim', [0 max([cp.trial_control(end) cp.trial_chemo(end)])+5], 'YLim', [0 100]);
    end

%% Hold duration violin
    function plot_hold_duration_violin(ax, obj, opts)

        dcz_ind = 2 * (1:length(obj.TargetFP))';
        num_dcz = length(obj.TargetFP);
        patch(ax, 'XData', [dcz_ind-.5 dcz_ind-.5 dcz_ind+.5 dcz_ind+.5]', 'YData', repmat([0; 100; 100; 0], 1, num_dcz), ...
            'FaceColor', opts.color.Treat, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

        line(ax, [0.6 2.4], [obj.TargetFP obj.TargetFP], 'Color', 'k', 'LineWidth', .5, 'LineStyle', '-');

        num_violin = length(obj.Ports)*2*length(obj.TargetFP);
        thisHD = nan(height(obj.BehavTable), num_violin);
        
        cued_this = find(obj.CueUncue==0);
        for p_this = 1:length(obj.Ports)
            thisHD(1:length(obj.HDSorted.Control{cued_this, p_this}), p_this)   = obj.HDSorted.Control{cued_this, p_this};
            thisHD(1:length(obj.HDSorted.Chemo{cued_this, p_this})  , p_this+2) = obj.HDSorted.Chemo{cued_this, p_this};
        end

        thisHD(all(isnan(thisHD), 2), :) = [];

        violinplot({thisHD(:, 2:2:end), thisHD(:, 1:2:end)}, obj.Sessions, ...
            'ViolinColor', {repmat(opts.color.PortR, num_violin/2, 1), repmat(opts.color.PortL, num_violin/2, 1)}, ...
            'MarkerSize', 8, 'ShowMedian', false, 'ShowWhisker', false, 'ShowBox', false, 'Bandwidth', 0.1);

        scatter(ax, ceil((1:num_violin)/2) + repmat([-.02 .02], 1, num_violin/2), median(thisHD, 'omitnan'), 32, ...
            repmat([opts.color.PortL; opts.color.PortR], num_violin/2, 1), ...
            'filled', 'LineWidth', 1, 'MarkerEdgeColor', [.3 .3 .3], 'MarkerFaceAlpha', 0.6);

        ax.XLabel.String = 'Foreperiod (s)';
        ax.YLabel.String = 'Hold duration (s)';
        ax.XLabel.FontWeight = "Bold";
        ax.YLabel.FontWeight = "Bold";
        set(ax, 'xlim', [.5 2*length(obj.TargetFP)+.5], 'ylim', [0 obj.Bins.HoldDuration(end)], 'xtick', 1.5:2:2*length(obj.TargetFP), ...
            'xticklabel', obj.TargetFP, 'ticklength', [0.01 0.1], 'box', 'off');
    end

%% Hold duration comparation
% median
    function plot_hold_duration_median_compare(ax, obj, opts)
       
        n_boot = 1000;
        alpha_ci = .05;

%         ind_l = find(obj.HDStatControl.thisCued==0 & obj.HDStatControl.Port=="L");
%         ind_r = find(obj.HDStatControl.thisCued==0 & obj.HDStatControl.Port=="R");

        cued_this = find(obj.CueUncue==0);

        p_this = obj.Ports=="L";
        hd_control_l = obj.HDSorted.Control{cued_this, p_this};
        hd_chemo_l   = obj.HDSorted.Chemo{cued_this, p_this};

        p_this = obj.Ports=="R";
        hd_control_r = obj.HDSorted.Control{cued_this, p_this};
        hd_chemo_r   = obj.HDSorted.Chemo{cued_this, p_this};

        med = @(x) median(x, 'omitnan');
        hd_med_control_l = med(hd_control_l);
        hd_med_chemo_l = med(hd_chemo_l);
        hd_med_control_r = med(hd_control_r);
        hd_med_chemo_r = med(hd_chemo_r);

        hd_med_ci_control_l = bootci(n_boot, {med, hd_control_l}, 'Type', 'cper', 'Alpha', alpha_ci);
        hd_med_ci_chemo_l = bootci(n_boot, {med, hd_chemo_l}, 'Type', 'cper', 'Alpha', alpha_ci);
        hd_med_ci_control_r = bootci(n_boot, {med, hd_control_r}, 'Type', 'cper', 'Alpha', alpha_ci);
        hd_med_ci_chemo_r = bootci(n_boot, {med, hd_chemo_r}, 'Type', 'cper', 'Alpha', alpha_ci);

        scatter(ax, hd_med_control_l, hd_med_chemo_l, ...
            24, 'Marker', 'o', 'MarkerFaceColor', opts.color.PortL, 'MarkerEdgeColor', opts.color.PortL, ...
            'MarkerFaceAlpha', 0.4, 'MarkerEdgeAlpha', .6, ...
            'LineWidth', 1.5);
        plot(ax, hd_med_ci_control_l, [hd_med_chemo_l hd_med_chemo_l], ...
            'Color', opts.color.PortL, 'LineWidth', 1.2);
        plot(ax, [hd_med_control_l hd_med_control_l], hd_med_ci_chemo_l, ...
            'Color', opts.color.PortL, 'LineWidth', 1.2);

        scatter(ax, hd_med_control_r, hd_med_chemo_r, ...
            24, 'Marker', 'o', 'MarkerFaceColor', opts.color.PortR, 'MarkerEdgeColor', opts.color.PortR, ...
            'MarkerFaceAlpha', 0.4, 'MarkerEdgeAlpha', .6, ...
            'LineWidth', 1.5);
        plot(ax, hd_med_ci_control_r, [hd_med_chemo_r hd_med_chemo_r], ...
            'Color', opts.color.PortR, 'LineWidth', 1.2);
        plot(ax, [hd_med_control_r hd_med_control_r], hd_med_ci_chemo_r, ...
            'Color', opts.color.PortR, 'LineWidth', 1.2);
        
        ax.YLabel.String     = "Chemo";
        ax.YLabel.Color      = opts.color.Treat;
        ax.YLabel.FontWeight = "Bold";

        ax.XLabel.String     = "Control";
        ax.XLabel.Color      = opts.color.Control;
        ax.XLabel.FontWeight = "Bold";

        set(ax, 'xlimmode', 'auto', 'ylimmode', 'auto');
%         ax.XLim = [min([ax.XLim(1) ax.YLim(1)]) max([ax.XLim(2) ax.YLim(2)])] .* [.95 1.05];
        ax.XLim = [-.2 .2] + obj.TargetFP;
        ax.YLim = ax.XLim;
        ax.XTick = [-.2 0 .2] + obj.TargetFP;
        ax.YTick = ax.XTick;

        text(ax, mean(ax.XLim), ax.YLim(2), "HD median (s)", 'FontSize', 9, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

        line(ax, [0 100], [0 100], 'Color', 'k', 'LineStyle', ':', 'LineWidth', .5);
        line(ax, [obj.TargetFP obj.TargetFP], [0 obj.TargetFP], 'Color', 'k', 'LineStyle', ':', 'LineWidth', .5);
        line(ax, [0 obj.TargetFP], [obj.TargetFP obj.TargetFP], 'Color', 'k', 'LineStyle', ':', 'LineWidth', .5);

    end

% IQR
    function plot_hold_duration_iqr_compare(ax, obj, opts)

        n_boot = 1000;
        alpha_ci = .05;

%         ind_l = find(obj.HDStatControl.thisCued==0 & obj.HDStatControl.Port=="L");
%         ind_r = find(obj.HDStatControl.thisCued==0 & obj.HDStatControl.Port=="R");

        cued_this = find(obj.CueUncue==0);

        p_this = obj.Ports=="L";
        hd_control_l = obj.HDSorted.Control{cued_this, p_this};
        hd_chemo_l   = obj.HDSorted.Chemo{cued_this, p_this};

        p_this = obj.Ports=="R";
        hd_control_r = obj.HDSorted.Control{cued_this, p_this};
        hd_chemo_r   = obj.HDSorted.Chemo{cued_this, p_this};

        iqr_f = @(x) iqr(x);
        hd_iqr_control_l = iqr_f(hd_control_l);
        hd_iqr_chemo_l = iqr_f(hd_chemo_l);
        hd_iqr_control_r = iqr_f(hd_control_r);
        hd_iqr_chemo_r = iqr_f(hd_chemo_r);

        hd_iqr_ci_control_l = bootci(n_boot, {iqr_f, hd_control_l}, 'Type', 'cper', 'Alpha', alpha_ci);
        hd_iqr_ci_chemo_l = bootci(n_boot, {iqr_f, hd_chemo_l}, 'Type', 'cper', 'Alpha', alpha_ci);
        hd_iqr_ci_control_r = bootci(n_boot, {iqr_f, hd_control_r}, 'Type', 'cper', 'Alpha', alpha_ci);
        hd_iqr_ci_chemo_r = bootci(n_boot, {iqr_f, hd_chemo_r}, 'Type', 'cper', 'Alpha', alpha_ci);

        scatter(ax, hd_iqr_control_l, hd_iqr_chemo_l, ...
            24, 'Marker', 'o', 'MarkerFaceColor', opts.color.PortL, 'MarkerEdgeColor', opts.color.PortL, ...
            'MarkerFaceAlpha', 0.4, 'MarkerEdgeAlpha', .6, ...
            'LineWidth', 1.5);
        plot(ax, hd_iqr_ci_control_l, [hd_iqr_chemo_l hd_iqr_chemo_l], ...
            'Color', opts.color.PortL, 'LineWidth', 1.2);
        plot(ax, [hd_iqr_control_l hd_iqr_control_l], hd_iqr_ci_chemo_l, ...
            'Color', opts.color.PortL, 'LineWidth', 1.2);

        scatter(ax, hd_iqr_control_r, hd_iqr_chemo_r, ...
            24, 'Marker', 'o', 'MarkerFaceColor', opts.color.PortR, 'MarkerEdgeColor', opts.color.PortR, ...
            'MarkerFaceAlpha', 0.4, 'MarkerEdgeAlpha', .6, ...
            'LineWidth', 1.5);
        plot(ax, hd_iqr_ci_control_r, [hd_iqr_chemo_r hd_iqr_chemo_r], ...
            'Color', opts.color.PortR, 'LineWidth', 1.2);
        plot(ax, [hd_iqr_control_r hd_iqr_control_r], hd_iqr_ci_chemo_r, ...
            'Color', opts.color.PortR, 'LineWidth', 1.2);
        
        ax.YLabel.String     = "Chemo";
        ax.YLabel.Color      = opts.color.Treat;
        ax.YLabel.FontWeight = "Bold";

        ax.XLabel.String     = "Control";
        ax.XLabel.Color      = opts.color.Control;
        ax.XLabel.FontWeight = "Bold";

        set(ax, 'xlimmode', 'auto', 'ylimmode', 'auto');
        ax.XLim = [0 max([ax.XLim(2) ax.YLim(2)])] .* 1.2;
%         ax.XLim = [-.2 .2] + obj.TargetFP;
        ax.YLim = ax.XLim;
%         ax.XTick = [-.2 0 .2] + obj.TargetFP;
        ax.YTick = ax.XTick;

        text(ax, mean(ax.XLim), ax.YLim(2), "HD IQR (s)", 'FontSize', 9, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

        line(ax, [0 100], [0 100], 'Color', 'k', 'LineStyle', ':', 'LineWidth', .5);
%         line(ax, [obj.TargetFP obj.TargetFP], [0 obj.TargetFP], 'Color', 'k', 'LineStyle', ':', 'LineWidth', .5);
%         line(ax, [0 obj.TargetFP], [obj.TargetFP obj.TargetFP], 'Color', 'k', 'LineStyle', ':', 'LineWidth', .5);

    end

%% Hold duration density
% Prob. density
    function plot_hold_duration_pdf(ax, obj, port, opts)

        p_this = obj.Ports==upper(string(port));
        cued_this = find(obj.CueUncue==0);

        xline(ax, obj.TargetFP, 'color', [.7 .7 .7], 'linewidth', 1, 'LineStyle', '-');

        hd_control_pdf = obj.HDPDF.Control{cued_this, p_this};
        hd_chemo_pdf   = obj.HDPDF.Chemo{cued_this, p_this};

        fill(ax, [hd_control_pdf.x flip(hd_control_pdf.x)], [hd_control_pdf.ci(1,:) flip(hd_control_pdf.ci(2,:))], 'y', ...
            'FaceColor', opts.color.Control, 'FaceAlpha', 0.4, 'EdgeColor', 'none');
        plot(ax, hd_control_pdf.x, hd_control_pdf.f, ...
            'color', opts.color.Control, 'linewidth', 1.5, 'LineStyle', '-');

        fill(ax, [hd_chemo_pdf.x flip(hd_chemo_pdf.x)], [hd_chemo_pdf.ci(1,:) flip(hd_chemo_pdf.ci(2,:))], 'y', ...
            'FaceColor', opts.color.Treat, 'FaceAlpha', 0.4, 'EdgeColor', 'none');
        plot(ax, hd_chemo_pdf.x, hd_chemo_pdf.f, ...
            'color', opts.color.Treat  , 'linewidth', 1.5, 'LineStyle', '-');

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
        ax.YLabel.FontWeight = "Bold";

        set(ax, 'xlim', [0 obj.Bins.HoldDuration(end)], 'ylimmode', 'auto');
    end

% Cum. distribution
    function plot_hold_duration_cdf(ax, obj, port, opts)

        p_this = obj.Ports==upper(string(port));
        cued_this = find(obj.CueUncue==0);

        xline(ax, obj.TargetFP, 'color', [.7 .7 .7], 'linewidth', 1, 'LineStyle', '-');

        hd_control_cdf = obj.HDCDF.Control{cued_this, p_this};
        hd_chemo_cdf   = obj.HDCDF.Chemo{cued_this, p_this};

        fill(ax, [hd_control_cdf.x flip(hd_control_cdf.x)], [hd_control_cdf.ci(1,:) flip(hd_control_cdf.ci(2,:))], 'y', ...
            'FaceColor', opts.color.Control, 'FaceAlpha', 0.4, 'EdgeColor', 'none');
        plot(ax, hd_control_cdf.x, hd_control_cdf.f, ...
            'color', opts.color.Control, 'linewidth', 1.5, 'LineStyle', '-');

        fill(ax, [hd_chemo_cdf.x flip(hd_chemo_cdf.x)], [hd_chemo_cdf.ci(1,:) flip(hd_chemo_cdf.ci(2,:))], 'y', ...
            'FaceColor', opts.color.Treat, 'FaceAlpha', 0.4, 'EdgeColor', 'none');
        plot(ax, hd_chemo_cdf.x, hd_chemo_cdf.f, ...
            'color', opts.color.Treat  , 'linewidth', 1.5, 'LineStyle', '-');

        switch upper(string(port))
            case {"L"}
                ax.XLabel.String = "Hold duration Left (s)";
                ax.XLabel.Color  = opts.color.PortL;
            case {"R"}
                ax.XLabel.String = "Hold duration Right (s)";
                ax.XLabel.Color  = opts.color.PortR;
        end
        ax.XLabel.FontWeight = "Bold";

        ax.YLabel.String = "Cumulative distribution";
        ax.YLabel.FontWeight = "Bold";

        set(ax, 'xlim', [0 obj.Bins.HoldDuration(end)], 'ylim', [0 1]);
    end

    function plot_hold_duration_median(ax, obj, port, opts)

        p_this = obj.Ports==upper(string(port));
        cued_this = find(obj.CueUncue==0);

        hd_control = obj.HDSortedControl{cued_this, p_this};
        hd_chemo   = obj.HDSortedChemo{cued_this, p_this};

        med = @(x) median(x, 'omitnan');

        hd_control_med = med(hd_control);
        hd_chemo_med   = med(hd_chemo);

        hd_control_med_ci = bootci(1000, {med, hd_control}, 'Type', 'cper', 'Alpha', .01);
        hd_chemo_med_ci = bootci(1000, {med, hd_chemo}, 'Type', 'cper', 'Alpha', .01);

%         plot(ax, hd_control_med, 0, ...
%             'Color', opts.color.Control, 'Marker', 'o', 'MarkerSize', 4, 'MarkerFaceColor', opts.color.Control);
        plot(ax, hd_control_med_ci, [0 0], ...
            'color', opts.color.Control, 'linewidth', 1.5, 'LineStyle', '-');

%         plot(ax, hd_chemo_med, 1, ...
%             'Color', opts.color.Treat, 'Marker', 'o', 'MarkerSize', 4, 'MarkerFaceColor', opts.color.Treat);
        plot(ax, hd_chemo_med_ci, [1 1], ...
            'color', opts.color.Treat, 'linewidth', 1.5, 'LineStyle', '-');

        set(ax, 'xlim', [0 obj.Bins.HoldDuration(end)], 'ylim', [-.5 1.5]);
    end


%% Movement time violin
    function plot_movement_time_violin(ax, obj, opts)

        dcz_ind = 2 * (1:length(obj.TargetFP))';
        num_dcz = length(obj.TargetFP);
        patch(ax, 'XData', [dcz_ind-.5 dcz_ind-.5 dcz_ind+.5 dcz_ind+.5]', 'YData', repmat([0; 100; 100; 0], 1, num_dcz), ...
            'FaceColor', opts.color.Treat, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

        num_violin = length(obj.Ports)*2*length(obj.TargetFP);
        thisMT = nan(height(obj.BehavTable), num_violin);

        cued_this = find(obj.CueUncue==0);
        for p_this = 1:length(obj.Ports)
            thisMT(1:length(obj.MTSorted.Control{cued_this, p_this}), p_this)   = obj.MTSorted.Control{cued_this, p_this};
            thisMT(1:length(obj.MTSorted.Chemo{cued_this, p_this})  , p_this+2) = obj.MTSorted.Chemo{cued_this, p_this};
        end

        thisMT(all(isnan(thisMT), 2), :) = [];
        thisMT = rmoutliers(thisMT, 1);

        violinplot({thisMT(:, 2:2:end), thisMT(:, 1:2:end)}, obj.Sessions, ...
            'ViolinColor', {repmat(opts.color.PortR, num_violin/2, 1), repmat(opts.color.PortL, num_violin/2, 1)}, ...
            'MarkerSize', 8, 'ShowMedian', false, 'ShowWhisker', false, 'ShowBox', false, 'Bandwidth', 0.1);

        scatter(ax, ceil((1:num_violin)/2) + repmat([-.02 .02], 1, num_violin/2), median(thisMT, 'omitnan'), 32, ...
            repmat([opts.color.PortL; opts.color.PortR], num_violin/2, 1), ...
            'filled', 'LineWidth', 1, 'MarkerEdgeColor', [.3 .3 .3], 'MarkerFaceAlpha', 0.6);

        ax.XLabel.String = 'Foreperiod (s)';
        ax.YLabel.String = 'Movement time (s)';
        ax.XLabel.FontWeight = "Bold";
        ax.YLabel.FontWeight = "Bold";

        set(ax, 'xlim', [.5 2*length(obj.TargetFP)+.5], 'ylim', [0 1], 'xtick', 1.5:2:2*length(obj.TargetFP), ...
            'xticklabel', obj.TargetFP, 'ticklength', [0.01 0.1], 'box', 'off');
    end

%% Movement time comparation
    function plot_movement_time_median_compare(ax, obj, opts)
       
        n_boot = 1000;
        alpha_ci = .05;
        
        cued_this = find(obj.CueUncue==0);

        p_this = obj.Ports=="L";
        mt_control_l = obj.MTSorted.Control{cued_this, p_this};
        mt_chemo_l   = obj.MTSorted.Chemo{cued_this, p_this};

        p_this = obj.Ports=="R";
        mt_control_r = obj.MTSorted.Control{cued_this, p_this};
        mt_chemo_r   = obj.MTSorted.Chemo{cued_this, p_this};

        med = @(x) median(x, 'omitnan');
        mt_med_control_l = med(mt_control_l);
        mt_med_chemo_l = med(mt_chemo_l);
        mt_med_control_r = med(mt_control_r);
        mt_med_chemo_r = med(mt_chemo_r);

        mt_med_ci_control_l = bootci(n_boot, {med, mt_control_l}, 'Type', 'cper', 'Alpha', alpha_ci);
        mt_med_ci_chemo_l = bootci(n_boot, {med, mt_chemo_l}, 'Type', 'cper', 'Alpha', alpha_ci);
        mt_med_ci_control_r = bootci(n_boot, {med, mt_control_r}, 'Type', 'cper', 'Alpha', alpha_ci);
        mt_med_ci_chemo_r = bootci(n_boot, {med, mt_chemo_r}, 'Type', 'cper', 'Alpha', alpha_ci);

        scatter(ax, mt_med_control_l, mt_med_chemo_l, ...
            24, 'Marker', 'o', 'MarkerFaceColor', opts.color.PortL, 'MarkerEdgeColor', opts.color.PortL, ...
            'MarkerFaceAlpha', 0.4, 'MarkerEdgeAlpha', .6, ...
            'LineWidth', 1.5);
        plot(ax, mt_med_ci_control_l, [mt_med_chemo_l mt_med_chemo_l], ...
            'Color', opts.color.PortL, 'LineWidth', 1.2);
        plot(ax, [mt_med_control_l mt_med_control_l], mt_med_ci_chemo_l, ...
            'Color', opts.color.PortL, 'LineWidth', 1.2);

        scatter(ax, mt_med_control_r, mt_med_chemo_r, ...
            24, 'Marker', 'o', 'MarkerFaceColor', opts.color.PortR, 'MarkerEdgeColor', opts.color.PortR, ...
            'MarkerFaceAlpha', 0.4, 'MarkerEdgeAlpha', .6, ...
            'LineWidth', 1.5);
        plot(ax, mt_med_ci_control_r, [mt_med_chemo_r mt_med_chemo_r], ...
            'Color', opts.color.PortR, 'LineWidth', 1.2);
        plot(ax, [mt_med_control_r mt_med_control_r], mt_med_ci_chemo_r, ...
            'Color', opts.color.PortR, 'LineWidth', 1.2);
        
        ax.YLabel.String     = "Chemo";
        ax.YLabel.Color      = opts.color.Treat;
        ax.YLabel.FontWeight = "Bold";

        ax.XLabel.String     = "Control";
        ax.XLabel.Color      = opts.color.Control;
        ax.XLabel.FontWeight = "Bold";

        set(ax, 'xlimmode', 'auto', 'ylimmode', 'auto');
%         ax.XLim = [min([ax.XLim(1) ax.YLim(1)]) max([ax.XLim(2) ax.YLim(2)])] .* [.95 1.05];
        ax.XLim = [0 1];
        ax.YLim = ax.XLim;
        ax.YTick = ax.XTick;

        text(ax, mean(ax.XLim), ax.YLim(2), "MT median (s)", 'FontSize', 9, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

        line(ax, [0 100], [0 100], 'Color', 'k', 'LineStyle', ':', 'LineWidth', .5);
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
            'MarkerSize', 2, 'ShowMedian', false, 'ShowWhisker', false, 'ShowBox', false);

        scatter(ax, 1:2, median(thisSTLog, 'omitnan'), 40, ...
            ones(2, 3), ...
            'filled', 'LineWidth', 1, 'MarkerEdgeColor', [.3 .3 .3]);

        ax.XLabel.String = 'Treatment';
        ax.YLabel.String = 'Shuttle time (s)';
        ax.XLabel.FontWeight = "Bold";
        ax.YLabel.FontWeight = "Bold";

        set(ax, 'xlim', [.5 2.5], 'ylim', [-1 obj.Bins.ShuttleTimeLog(end)], 'xtick', 1:2, ...
            'xticklabel', ["Control", "Chemo"], ...
            'ytick', -1:3, 'yticklabel', ["10^-1", "10^0", "10^1", "10^2", "10^3"], ...
            'ticklength', [0.01 0.1], 'box', 'off');
    end

%% Statistics
    function get_stats(obj, port)

        nboot = 1000;
        alpha = 0.05;

        p_this = obj.Ports==upper(string(port));
        cued_this = find(obj.CueUncue==0);

        hd_control = obj.HDSortedControl{cued_this, p_this};
        hd_chemo   = obj.HDSortedChemo{cued_this, p_this};

        med = @(x) median(x, 'omitnan');

        hd_control_med = med(hd_control);
        hd_chemo_med   = med(hd_chemo);
        hd_d_med_hat = hd_chemo_med - hd_control_med;

        [hd_control_med_ci, hd_control_med_boot] = bootci(nboot, {med, hd_control}, 'Type', 'cper', 'Alpha', alpha);
        [hd_chemo_med_ci, hd_chemo_med_boot] = bootci(nboot, {med, hd_chemo}, 'Type', 'cper', 'Alpha', alpha);

        hd_d_med_boot = hd_chemo_med_boot - hd_control_med_boot;
        hd_d_med_ci = [2*hd_d_med_hat-quantile(hd_d_med_boot, 1-alpha/2) 2*hd_d_med_hat-quantile(hd_d_med_boot, alpha/2)];

    end


end
