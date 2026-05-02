function fig = plotProgress(obj)

%%
opts.color = GPSColor(); % Color class for GPS
opts.mk = ["o", "x"]; % Scatter marker for correct and others
opts.ls = [":", "-.", "-"]; % Line style for [ShortFP, MedFP, LongFP]
opts.lw = [0.5, 1, 1.5]; % Line width for [ShortFP, MedFP, LongFP]
opts.trial_ticks = obj.BehavTable.TrialStartTimeProgress + obj.BehavTable.CentInTime;

opts.session_sep = zeros(1, obj.NumSessions-1);
for s = 1:obj.NumSessions-1
    ind = find(obj.BehavTable.Session==obj.Sessions(s), 1, 'last');
    opts.session_sep(s) = opts.trial_ticks(ind)+5;
end

opts.session_date = char(obj.Sessions);
opts.session_date = opts.session_date(:, 5:8);

opts.plotsize1 = [8 4];
opts.plotsize2 = [9 3.5];
opts.plotsize3 = [3.5 3];
opts.plotsize4 = [2 3];

opts.sep_col = 0.5;
opts.sep_row = 1.5;

%%
fig = figure(23); clf(23);
set(gcf, 'unit', 'centimeters', 'position', [2 .7 39.5 25.4], 'paperpositionmode', 'auto', 'color', 'w');

mycolormap = customcolormap_preset("red-white-blue");

uicontrol('Style', 'text', 'parent', 23, 'units', 'normalized', 'position', [0.25 0.95 0.5 0.04],...
    'string', obj.Subject+" / "+obj.Task+" / "+obj.Sessions(1)+"_"+obj.Sessions(end), 'fontsize', 11, 'fontweight', 'bold', 'backgroundcolor', 'w');

%% Set axes and plot
% Maze diagram
ha1 = axes;
set(ha1, 'units', 'centimeters', 'position', [.3+3*(opts.sep_row+opts.plotsize1(1))+1.5 2+4*(opts.sep_col+opts.plotsize1(2)), opts.plotsize1], 'nextplot', 'add', 'fontsize', 8);
plot_diagram(ha1, opts);

% Hold duration scatter
ha2 = axes;
set(ha2, 'units', 'centimeters', 'position', [1.5+0*(opts.sep_row+opts.plotsize1(1)) 2+3*(opts.sep_col+opts.plotsize1(2)), opts.plotsize1], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_scatter(ha2, obj, opts);
set(ha2, 'xtick', [], 'xlabel', []);

% Reaction time scatter
ha3 = axes;
set(ha3, 'units', 'centimeters', 'position', [1.5+0*(opts.sep_row+opts.plotsize1(1)) 2+2*(opts.sep_col+opts.plotsize1(2)), opts.plotsize1], 'nextplot', 'add', 'fontsize', 8);
plot_reaction_time_scatter(ha3, obj, opts);
set(ha3, 'xtick', [], 'xlabel', []);

% Performance track
ha4 = axes;
set(ha4, 'units', 'centimeters', 'position', [1.5+0*(opts.sep_row+opts.plotsize1(1)) 2+4*(opts.sep_col+opts.plotsize1(2)), opts.plotsize1], 'nextplot', 'add', 'fontsize', 8);
plot_performance_track_progress(ha4, obj, opts);
set(ha4, 'xtick', [], 'xlabel', []);

% Performance progress
ha5 = axes;
set(ha5, 'units', 'centimeters', 'position', [.5+1*(opts.sep_row+opts.plotsize1(1)) 2+4*(opts.sep_col+opts.plotsize1(2)), opts.plotsize1], 'nextplot', 'add', 'fontsize', 8);
plot_performance_progress(ha5, obj, opts);
set(ha5, 'xtick', [], 'xlabel', [], 'yticklabel', [], 'ylabel', []);

% Reaction time violin plot
ha6 = axes;
set(ha6, 'units', 'centimeters', 'position', [.5+1*(opts.sep_row+opts.plotsize1(1)) 2+2*(opts.sep_col+opts.plotsize1(2)), opts.plotsize1], 'nextplot', 'add', 'fontsize', 8);
plot_reaction_time_violin(ha6, obj, opts);
set(ha6, 'xtick', [], 'xlabel', [], 'yticklabel', [], 'ylabel', []);

%
ha7 = axes;
set(ha7, 'units', 'centimeters', 'position', [.5+3*(opts.sep_row+opts.plotsize1(1))+1.5 2+3*(opts.sep_col+opts.plotsize1(2)), opts.plotsize1], 'nextplot', 'add', 'fontsize', 8);
plot_reaction_time_median(ha7, obj, opts);
set(ha7, 'xtick', [], 'xlabel', []);

%
ha8 = axes;
set(ha8, 'units', 'centimeters', 'position', [.5+3*(opts.sep_row+opts.plotsize1(1))+1.5 2+2*(opts.sep_col+opts.plotsize1(2)), opts.plotsize1], 'nextplot', 'add', 'fontsize', 8);
plot_reaction_time_iqr(ha8, obj, opts);

%
ha9 = axes;
set(ha9, 'units', 'centimeters', 'position', [.5+2*(opts.sep_row+opts.plotsize1(1)) 2+4*(opts.sep_col+opts.plotsize1(2)), opts.plotsize1], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_heatmap(ha9, obj, "R", opts)
set(ha9, 'xtick', [], 'xlabel', []);

colormap(mycolormap);
cb9 = colorbar(ha9, 'units', 'centimeters', 'position', [.5+3*(opts.sep_row+opts.plotsize1(1))-opts.sep_row+0.2 2+4*(opts.sep_col+opts.plotsize1(2)), [.3 opts.plotsize1(2)]]);
cb9.Limits = [0 cb9.Limits(2)];
cb9.Label.String = "Prob. density (1/s)";
cb9.FontSize = 8;

%
ha10 = axes;
set(ha10, 'units', 'centimeters', 'position', [.5+2*(opts.sep_row+opts.plotsize1(1)) 2+3*(opts.sep_col+opts.plotsize1(2)), opts.plotsize1], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_heatmap(ha10, obj, "L", opts)
set(ha10, 'xtick', [], 'xlabel', []);

colormap(mycolormap);
cb10 = colorbar(ha10, 'units', 'centimeters', 'position', [.5+3*(opts.sep_row+opts.plotsize1(1))-opts.sep_row+0.2 2+3*(opts.sep_col+opts.plotsize1(2)), [.3 opts.plotsize1(2)]]);
cb10.Limits = [0 cb10.Limits(2)];
cb10.Label.String = "Prob. density (1/s)";
cb10.FontSize = 8;

%
ha11 = axes;
set(ha11, 'units', 'centimeters', 'position', [.5+2*(opts.sep_row+opts.plotsize1(1)) 2+2*(opts.sep_col+opts.plotsize1(2)), opts.plotsize1], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_heatmap(ha11, obj, "L-R", opts);

colormap(mycolormap);
cb11 = colorbar(ha11, 'units', 'centimeters', 'position', [.5+3*(opts.sep_row+opts.plotsize1(1))-opts.sep_row+0.2 2+2*(opts.sep_col+opts.plotsize1(2)), [.3 4]]);
cb11.Label.String = "Δ Prob. density (1/s)";
cb11.FontSize = 8;

%
ha121 = axes;
set(ha121, 'units', 'centimeters', 'position', [.5+2*(opts.sep_row+opts.plotsize1(1)) 1.5+1*(opts.sep_col+opts.plotsize1(2)), opts.plotsize2], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_pdf_early_late(ha121, obj, "R", opts);

ha122 = axes;
set(ha122, 'units', 'centimeters', 'position', [.5+2*(opts.sep_row+opts.plotsize1(1)) 1.9+0*(opts.sep_col+opts.plotsize1(2)), opts.plotsize2], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_pdf_early_late(ha122, obj, "L", opts);

density_max = max([ha121.YLim(2) ha122.YLim(2)]);
set(ha121, 'ylim', [0 density_max], 'xticklabel', [], 'xlabel', []);
set(ha122, 'ylim', [0 density_max]);

%
ha131 = axes;
set(ha131, 'units', 'centimeters', 'position', [1+3*(opts.sep_row+opts.plotsize1(1)) 1.5+1*(opts.sep_col+opts.plotsize1(2)), opts.plotsize2], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_cdf_early_late(ha131, obj, "R", opts);
set(ha131, 'xticklabel', [], 'xlabel', []);

ha132 = axes;
set(ha132, 'units', 'centimeters', 'position', [1+3*(opts.sep_row+opts.plotsize1(1)) 1.9+0*(opts.sep_col+opts.plotsize1(2)), opts.plotsize2], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_cdf_early_late(ha132, obj, "L", opts);

ha1321 = axes;
set(ha1321, 'units', 'centimeters', 'position', [.5+3*(opts.sep_row+opts.plotsize1(1))+5*opts.plotsize2(1)/6 1.5+0*(opts.sep_col+opts.plotsize1(2))+1*opts.plotsize2(2)/6, opts.plotsize2 ./ [5 3]], ...
    'nextplot', 'add', 'fontsize', 8, 'color', 'none', 'xcolor', 'none', 'ycolor', 'none', 'xlim', [0 3], 'ylim', [0 3]);
line(ha1321, [1 2], [2 2], 'Color', opts.color.PhaseEarly, 'LineWidth', 1, 'LineStyle', '-');
line(ha1321, [1 2], [1 1], 'Color', opts.color.PhaseLate, 'LineWidth', 1, 'LineStyle', '-');
text(ha1321, 2.2, 2, "Early", 'FontSize', 8);
text(ha1321, 2.2, 1, "Late", 'FontSize', 8);

%
ha14 = axes;
set(ha14, 'units', 'centimeters', 'position', [1.5+0*(opts.sep_row+opts.plotsize1(1)) 2+1*(opts.sep_col+opts.plotsize1(2)), opts.plotsize1], 'nextplot', 'add', 'fontsize', 8);
plot_movement_time_scatter(ha14, obj, opts);
set(ha14, 'xtick', [], 'xlabel', []);

%
ha15 = axes;
set(ha15, 'units', 'centimeters', 'position', [1.5+0*(opts.sep_row+opts.plotsize1(1)) 2+0*(opts.sep_col+opts.plotsize1(2)), opts.plotsize1], 'nextplot', 'add', 'fontsize', 8);
plot_shuttle_time_scatter(ha15, obj, opts);

%
ha16 = axes;
set(ha16, 'units', 'centimeters', 'position', [.5+1*(opts.sep_row+opts.plotsize1(1)) 2+3*(opts.sep_col+opts.plotsize1(2)), opts.plotsize1], 'nextplot', 'add', 'fontsize', 8);
plot_hold_duration_violin(ha16, obj, opts)
set(ha16, 'xtick', [], 'xlabel', [], 'yticklabel', [], 'ylabel', []);

ha17 = axes;
set(ha17, 'units', 'centimeters', 'position', [.5+1*(opts.sep_row+opts.plotsize1(1)) 2+1*(opts.sep_col+opts.plotsize1(2)), opts.plotsize1], 'nextplot', 'add', 'fontsize', 8);
plot_movement_time_violin(ha17, obj, opts)
set(ha17, 'xtick', [], 'xlabel', [], 'yticklabel', [], 'ylabel', []);

ha18 = axes;
set(ha18, 'units', 'centimeters', 'position', [.5+1*(opts.sep_row+opts.plotsize1(1)) 2+0*(opts.sep_col+opts.plotsize1(2)), opts.plotsize1], 'nextplot', 'add', 'fontsize', 8);
plot_shuttle_time_violin(ha18, obj, opts)
set(ha18, 'yticklabel', [], 'ylabel', [])

%% ha1. Make a diagram of the setup
    function plot_diagram(ax, opts)

        line(ax, [1 1], [0 6], 'color', 'k', 'linewidth', 2);
        line(ax, [1 3], [0 0], 'color', 'k', 'linewidth', 2);
        line(ax, [3 5], [0 2], 'color', 'k', 'linewidth', 2);
        line(ax, [5 8], [2 2], 'color', 'k', 'linewidth', 2);
        line(ax, [1 3], [6 6], 'color', 'k', 'linewidth', 2);
        line(ax, [3 5], [6 4], 'color', 'k', 'linewidth', 2);
        line(ax, [5 8], [4 4], 'color', 'k', 'linewidth', 2);

        line(ax, [8 9], [4 4.8], 'color', 'k', 'linewidth', 2);
        line(ax, [8 9], [2 1.2], 'color', 'k', 'linewidth', 2);
        line(ax, [9 11], [4.8 4.8], 'color', 'k', 'linewidth', 2);
        line(ax, [9 11], [1.2 1.2], 'color', 'k', 'linewidth', 2);
        line(ax, [11 11], [1.2 4.8], 'color', 'k', 'linewidth', 2);

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
    function plot_hold_duration_scatter(ax, obj, opts)

        for fp_this = 1:length(obj.MixedFP)
            yline(ax, obj.MixedFP(fp_this), 'Color', [.8 .8 .8], 'LineWidth', opts.lw(fp_this), 'LineStyle', '-', 'Alpha', 0.4);
        end
        xline(ax, opts.session_sep, 'Color', [.7 .7 .7], 'LineWidth', 1, 'LineStyle', '-');

        s_sep = [0 opts.session_sep opts.trial_ticks(end)];
        dcz_ind = find(obj.Treatment == "DCZ");
        num_dcz = length(dcz_ind);
        patch(ax, 'XData', [s_sep(dcz_ind); s_sep(dcz_ind); s_sep(dcz_ind+1); s_sep(dcz_ind+1)], 'YData', repmat([0; 100; 100; 0], 1, num_dcz), ...
            'FaceColor', opts.color.Treat, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

        % port 1 wrong (defined by their action, which is different from target)
        scatter(ax, opts.trial_ticks(obj.Ind.wrongL), ...
            obj.BehavTable.HoldDuration(obj.Ind.wrongL), ...
            22*obj.BehavTable.FP(obj.Ind.wrongL), opts.color.PortL, opts.mk(2), 'MarkerEdgeAlpha', 0.6, 'linewidth', 1);

        % port 2 wrong
        scatter(ax, opts.trial_ticks(obj.Ind.wrongR), ...
            obj.BehavTable.HoldDuration(obj.Ind.wrongR), ...
            22*obj.BehavTable.FP(obj.Ind.wrongR), opts.color.PortR, opts.mk(2), 'MarkerEdgeAlpha', 0.6, 'linewidth', 1);

        % premature
        scatter(ax, opts.trial_ticks(obj.Ind.premature), ...
            obj.BehavTable.HoldDuration(obj.Ind.premature), ...
            22*obj.BehavTable.FP(obj.Ind.premature), opts.color.Premature, opts.mk(2), 'MarkerEdgeAlpha', 0.6, 'linewidth', 1);

        % late
        scatter(ax, opts.trial_ticks(obj.Ind.late), ...
            obj.BehavTable.HoldDuration(obj.Ind.late), ...
            22*obj.BehavTable.FP(obj.Ind.late), opts.color.Late, opts.mk(2), 'MarkerEdgeAlpha', 0.6, 'linewidth', 1);

        % port 1 correct (defined by their action, which is also the target for correct response)
        scatter(ax, opts.trial_ticks(obj.Ind.correctL), ...
            obj.BehavTable.HoldDuration(obj.Ind.correctL), ...
            18*obj.BehavTable.FP(obj.Ind.correctL), opts.color.PortL, opts.mk(1), 'MarkerEdgeAlpha', 0.6, 'linewidth', 1);

        % port 2 correct
        scatter(ax, opts.trial_ticks(obj.Ind.correctR), ...
            obj.BehavTable.HoldDuration(obj.Ind.correctR), ...
            18*obj.BehavTable.FP(obj.Ind.correctR), opts.color.PortR, opts.mk(1), 'MarkerEdgeAlpha', 0.6, 'linewidth', 1);

        ax.XLabel.String = 'Time in training (s)';
        ax.YLabel.String = 'Hold duration (s)';
        set(ax, 'xlim', [0 opts.trial_ticks(end)+5], 'ylim', [0 2.5], 'ticklength', [0.01 0.1]);

    end

%% ha3. Plot correct trial's reaction during training
    function plot_reaction_time_scatter(ax, obj, opts)

        xline(ax, opts.session_sep, 'Color', [.7 .7 .7], 'LineWidth', 1, 'LineStyle', '-')
        yline(ax, .5, 'Color', [.7 .7 .7], 'LineWidth', 1.5, 'LineStyle', '--');

        s_sep = [0 opts.session_sep opts.trial_ticks(end)];
        dcz_ind = find(obj.Treatment == "DCZ");
        num_dcz = length(dcz_ind);
        patch(ax, 'XData', [s_sep(dcz_ind); s_sep(dcz_ind); s_sep(dcz_ind+1); s_sep(dcz_ind+1)], 'YData', repmat([0; 100; 100; 0], 1, num_dcz), ...
            'FaceColor', opts.color.Treat, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

        % port 1 wrong (defined by their action, which is different from target)
        scatter(ax, opts.trial_ticks(obj.Ind.wrongL), ...
            obj.BehavTable.RT(obj.Ind.wrongL), ...
            22*obj.BehavTable.FP(obj.Ind.wrongL), opts.color.PortL, opts.mk(2), 'MarkerEdgeAlpha', 0.6, 'linewidth', 1);

        % port 2 wrong
        scatter(ax, opts.trial_ticks(obj.Ind.wrongR), ...
            obj.BehavTable.RT(obj.Ind.wrongR), ...
            22*obj.BehavTable.FP(obj.Ind.wrongR), opts.color.PortR, opts.mk(2), 'MarkerEdgeAlpha', 0.6, 'linewidth', 1);

        % port 1 correct (defined by their action, which is also the target for correct response)
        scatter(ax, opts.trial_ticks(obj.Ind.correctL), ...
            obj.BehavTable.RT(obj.Ind.correctL), ...
            18*obj.BehavTable.FP(obj.Ind.correctL), opts.color.PortL, opts.mk(1), 'MarkerEdgeAlpha', 0.6, 'linewidth', 1);

        % port 2 correct
        scatter(ax, opts.trial_ticks(obj.Ind.correctR), ...
            obj.BehavTable.RT(obj.Ind.correctR), ...
            18*obj.BehavTable.FP(obj.Ind.correctR), opts.color.PortR, opts.mk(1), 'MarkerEdgeAlpha', 0.6, 'linewidth', 1);

        ax.XLabel.String = 'Time in training (s)';
        ax.YLabel.String = 'Reaction time (s)';
        set(ax, 'xlim', [0 opts.trial_ticks(end)+5], 'ylim', [0 obj.Bins.RT(end)], 'ticklength', [0.01 0.1]);
    end

%% ha3. Plot correct trial's reaction during training
    function plot_movement_time_scatter(ax, obj, opts)

        xline(ax, opts.session_sep, 'Color', [.7 .7 .7], 'LineWidth', 1, 'LineStyle', '-')

        s_sep = [0 opts.session_sep opts.trial_ticks(end)];
        dcz_ind = find(obj.Treatment == "DCZ");
        num_dcz = length(dcz_ind);
        patch(ax, 'XData', [s_sep(dcz_ind); s_sep(dcz_ind); s_sep(dcz_ind+1); s_sep(dcz_ind+1)], 'YData', repmat([0; 100; 100; 0], 1, num_dcz), ...
            'FaceColor', opts.color.Treat, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

        % port 1 wrong (defined by their action, which is different from target)
        scatter(ax, opts.trial_ticks(obj.Ind.wrongL), ...
            obj.BehavTable.MovementTime(obj.Ind.wrongL), ...
            22*obj.BehavTable.FP(obj.Ind.wrongL), opts.color.PortL, opts.mk(2), 'MarkerEdgeAlpha', 0.6, 'linewidth', 1);

        % port 2 wrong
        scatter(ax, opts.trial_ticks(obj.Ind.wrongR), ...
            obj.BehavTable.MovementTime(obj.Ind.wrongR), ...
            22*obj.BehavTable.FP(obj.Ind.wrongR), opts.color.PortR, opts.mk(2), 'MarkerEdgeAlpha', 0.6, 'linewidth', 1);

        % port 1 correct (defined by their action, which is also the target for correct response)
        scatter(ax, opts.trial_ticks(obj.Ind.correctL), ...
            obj.BehavTable.MovementTime(obj.Ind.correctL), ...
            18*obj.BehavTable.FP(obj.Ind.correctL), opts.color.PortL, opts.mk(1), 'MarkerEdgeAlpha', 0.6, 'linewidth', 1);

        % port 2 correct
        scatter(ax, opts.trial_ticks(obj.Ind.correctR), ...
            obj.BehavTable.MovementTime(obj.Ind.correctR), ...
            18*obj.BehavTable.FP(obj.Ind.correctR), opts.color.PortR, opts.mk(1), 'MarkerEdgeAlpha', 0.6, 'linewidth', 1);

        ax.XLabel.String = 'Time in training (s)';
        ax.YLabel.String = 'Movement time (s)';
        set(ax, 'xlim', [0 opts.trial_ticks(end)+5], 'ylim', [0 obj.Bins.MovementTime(end)], 'ticklength', [0.01 0.1]);
    end

%% ha3. Plot correct trial's reaction during training
    function plot_shuttle_time_scatter(ax, obj, opts)

        xline(ax, opts.session_sep, 'Color', [.7 .7 .7], 'LineWidth', 1, 'LineStyle', '-')

        s_sep = [0 opts.session_sep opts.trial_ticks(end)];
        dcz_ind = find(obj.Treatment == "DCZ");
        num_dcz = length(dcz_ind);
        patch(ax, 'XData', [s_sep(dcz_ind); s_sep(dcz_ind); s_sep(dcz_ind+1); s_sep(dcz_ind+1)], 'YData', repmat([0; 100; 100; 0], 1, num_dcz), ...
            'FaceColor', opts.color.Treat, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

        % port 1 wrong (defined by their action, which is different from target)
        scatter(ax, opts.trial_ticks, ...
            log10(obj.BehavTable.ShuttleTime), ...
            18, [0 0 0], opts.mk(1), 'MarkerEdgeAlpha', 0.4, 'linewidth', 1);

        ax.XLabel.String = 'Time in training (s)';
        ax.YLabel.String = 'Log Shuttle time (s)';
        set(ax, 'xlim', [0 opts.trial_ticks(end)+5], 'ylim', [0 obj.Bins.ShuttleTimeLog(end)], 'ticklength', [0.01 0.1]);
    end

%% ha4. Plot performance track of each session
    function plot_performance_track_progress(ax, obj, opts)

        xline(ax, opts.session_sep, 'Color', [.7 .7 .7], 'LineWidth', 1, 'LineStyle', '-')

        s_sep = [0 opts.session_sep opts.trial_ticks(end)];
        dcz_ind = find(obj.Treatment == "DCZ");
        num_dcz = length(dcz_ind);
        patch(ax, 'XData', [s_sep(dcz_ind); s_sep(dcz_ind); s_sep(dcz_ind+1); s_sep(dcz_ind+1)], 'YData', repmat([0; 100; 100; 0], 1, num_dcz), ...
            'FaceColor', opts.color.Treat, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

        for s_this = 1:obj.NumSessions
            ind_this = find(obj.PerformanceTrack.Sessions==obj.Sessions(s_this));
            plot(ax, obj.PerformanceTrack.WinPosProgress(ind_this), obj.PerformanceTrack.CorrectRatio(ind_this),  'linestyle', '-', 'color', opts.color.Correct, ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', opts.color.Correct,   'markeredgecolor', 'w');
            plot(ax, obj.PerformanceTrack.WinPosProgress(ind_this), obj.PerformanceTrack.WrongRatio(ind_this),    'linestyle', '-', 'color', opts.color.Wrong, ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', opts.color.Wrong,     'markeredgecolor', 'w');
            plot(ax, obj.PerformanceTrack.WinPosProgress(ind_this), obj.PerformanceTrack.PrematureRatio(ind_this), 'linestyle', '-', 'color', opts.color.Premature, ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', opts.color.Premature, 'markeredgecolor', 'w');
            plot(ax, obj.PerformanceTrack.WinPosProgress(ind_this), obj.PerformanceTrack.LateRatio(ind_this),      'linestyle', '-', 'color', opts.color.Late, ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', opts.color.Late,      'markeredgecolor', 'w');
        end

        ax.XLabel.String = 'Time in training (s)';
        ax.YLabel.String = 'Performance (%)';
        set(ax, 'XLim', [0 opts.trial_ticks(end)+5], 'YLim', [0 100]);
    end

%% ha5. Plot performance progress
    function plot_performance_progress(ax, obj, opts)

        session_id = 1:obj.NumSessions;
        xline(ax, session_id-0.5, 'Color', [.7 .7 .7], 'LineWidth', 1, 'LineStyle', '-');
        xline(ax, session_id, 'Color', [.8 .8 .8], 'LineWidth', 1, 'LineStyle', ':');

        dcz_ind = find(obj.Treatment == "DCZ");
        num_dcz = length(dcz_ind);
        patch(ax, 'XData', [dcz_ind-.5 dcz_ind-.5 dcz_ind+.5 dcz_ind+.5]', 'YData', repmat([0; 100; 100; 0], 1, num_dcz), ...
            'FaceColor', opts.color.Treat, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

        for fp_this = 1:length(obj.MixedFP)
            for p_this = 1:length(obj.Ports)

                ind_this = find(obj.Performance.Foreperiod==obj.MixedFP(fp_this) & obj.Performance.TargetPort==obj.Ports(p_this));
                
                scatter(ax, session_id+(1.5-p_this)/3, obj.Performance.PrematureRatio(ind_this), ...
                    9*fp_this, 'Marker', '^', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', opts.color.Premature, 'MarkerFaceAlpha', .3);
                scatter(ax, session_id+(1.5-p_this)/3, obj.Performance.LateRatio(ind_this), ...
                    9*fp_this, 'Marker', '^', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', opts.color.Late, 'MarkerFaceAlpha', .3);
                scatter(ax, session_id+(1.5-p_this)/3, obj.Performance.WrongRatio(ind_this), ...
                    9*fp_this, 'Marker', '^', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', opts.color.Wrong, 'MarkerFaceAlpha', .3);
                scatter(ax, session_id+(1.5-p_this)/3, obj.Performance.CorrectRatio(ind_this), ...
                    9*fp_this, 'Marker', '^', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', opts.color.Correct, 'MarkerFaceAlpha', .5);
            end
        end

        ind_this = find(obj.Performance.Foreperiod==0 & obj.Performance.TargetPort=="Both");

        plot(ax, session_id, obj.Performance.PrematureRatio(ind_this), 'o', 'linestyle', '-', 'color', opts.color.Premature, ...
            'markersize', 5, 'linewidth', 1, 'markerfacecolor', opts.color.Premature, 'markeredgecolor', 'w');
        plot(ax, session_id, obj.Performance.LateRatio(ind_this), 'o', 'linestyle', '-', 'color', opts.color.Late, ...
            'markersize', 5, 'linewidth', 1, 'markerfacecolor', opts.color.Late, 'markeredgecolor', 'w');
        plot(ax, session_id, obj.Performance.WrongRatio(ind_this), 'o', 'linestyle', '-', 'color', opts.color.Wrong, ...
            'markersize', 5, 'linewidth', 1, 'markerfacecolor', opts.color.Wrong, 'markeredgecolor', 'w');
        plot(ax, session_id, obj.Performance.CorrectRatio(ind_this), 'o', 'linestyle', '-', 'color', opts.color.Correct, ...
            'markersize', 5, 'linewidth', 1, 'markerfacecolor', opts.color.Correct, 'markeredgecolor', 'w');

        ax.XLabel.String = 'Sessions';
        ax.YLabel.String = 'Performance (%)';
        set(ax, 'xlim', [0.5 obj.NumSessions+0.5], 'xtick', session_id, 'xticklabel', opts.session_date);
    end

%% ha6. Plot hold duration of each session (violin), each port
    function plot_hold_duration_violin(ax, obj, opts)

        for fp_this = 1:length(obj.MixedFP)
            yline(ax, obj.MixedFP(fp_this), 'Color', [.8 .8 .8], 'LineWidth', opts.lw(fp_this), 'LineStyle', '-', 'Alpha', 0.4);
        end
        xline(ax, (1:obj.NumSessions-1)+0.5, 'Color', [.7 .7 .7], 'LineWidth', 1, 'LineStyle', '-');

        dcz_ind = find(obj.Treatment == "DCZ");
        num_dcz = length(dcz_ind);
        patch(ax, 'XData', [dcz_ind-.5 dcz_ind-.5 dcz_ind+.5 dcz_ind+.5]', 'YData', repmat([0; 100; 100; 0], 1, num_dcz), ...
            'FaceColor', opts.color.Treat, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

        thisHD = nan(height(obj.BehavTable), length(obj.Ports)*obj.NumSessions);

        HD = obj.BehavTable.HoldDuration;
        [~, ~, indrmv] = rmoutliers_custome(HD);
        HD(indrmv) = nan;

        for s_this = 1:obj.NumSessions
            session_id = obj.BehavTable.SessionDate==obj.Sessions(s_this);
            for p_this = 1:length(obj.Ports)
                ind_this = session_id & obj.BehavTable.Stage==1 & eval("obj.Ind.port"+obj.Ports(p_this));
                thisHD(ind_this, 2*(s_this-1)+p_this) = HD(ind_this);
            end
        end
        thisHD(1, all(isnan(thisHD))) = 0;

        violinplot({thisHD(:, 2:2:end), thisHD(:, 1:2:end)}, obj.Sessions, ...
            'ViolinColor', {repmat(opts.color.PortR, obj.NumSessions, 1), repmat(opts.color.PortL, obj.NumSessions, 1)}, ...
            'ScatterSize', 4, 'ShowMedian', false, 'ShowWhisker', false, 'ShowBox', false, 'Bandwidth', 0.1);

        ax.XLabel.String = 'Sessions';
        ax.YLabel.String = 'Hold duration (s)';
        set(ax, 'xlim', [.5 obj.NumSessions+.5], 'ylim', [0 obj.Bins.HoldDuration(end)], 'xtick', 1:obj.NumSessions, ...
            'xticklabel', opts.session_date, 'ticklength', [0.01 0.1], 'box', 'off');
    end

%% ha6. Plot reaction time of each session (violin), each port
    function plot_reaction_time_violin(ax, obj, opts)

        xline(ax, (1:obj.NumSessions-1)+0.5, 'Color', [.7 .7 .7], 'LineWidth', 1, 'LineStyle', '-');
        yline(ax, .5, 'Color', [.7 .7 .7], 'LineWidth', 1.5, 'LineStyle', '--');

        dcz_ind = find(obj.Treatment == "DCZ");
        num_dcz = length(dcz_ind);
        patch(ax, 'XData', [dcz_ind-.5 dcz_ind-.5 dcz_ind+.5 dcz_ind+.5]', 'YData', repmat([0; 100; 100; 0], 1, num_dcz), ...
            'FaceColor', opts.color.Treat, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        
        thisRT = nan(height(obj.BehavTable), length(obj.Ports)*obj.NumSessions);

        RT = obj.BehavTable.RT;
        [~, ~, indrmv] = rmoutliers_custome(RT);
        RT(indrmv) = nan;

        for s_this = 1:obj.NumSessions
            session_id = obj.BehavTable.SessionDate==obj.Sessions(s_this);
            for p_this = 1:length(obj.Ports)
                ind_this = session_id & obj.BehavTable.Stage==1 & eval("obj.Ind.correct"+obj.Ports(p_this));
                thisRT(ind_this, 2*(s_this-1)+p_this) = RT(ind_this);
            end
        end

        thisRT(1, all(isnan(thisRT))) = 0;
        violinplot({thisRT(:, 2:2:end), thisRT(:, 1:2:end)}, obj.Sessions, ...
            'ViolinColor', {repmat(opts.color.PortR, obj.NumSessions, 1), repmat(opts.color.PortL, obj.NumSessions, 1)}, ...
            'ScatterSize', 4, 'ShowMedian', false, 'ShowWhisker', false, 'ShowBox', false);
        
        session_order = [1:obj.NumSessions; 1:obj.NumSessions];
        session_order = session_order(:);
        scatter(ax, session_order, median(thisRT, 'omitnan'), 24, ...
            repmat([opts.color.PortL; opts.color.PortR], obj.NumSessions, 1), ...
            'filled', 'LineWidth', 1, 'MarkerEdgeColor', [.3 .3 .3]);

        ax.XLabel.String = 'Sessions';
        ax.YLabel.String = 'Reaction time (s)';
        set(ax, 'xlim', [.5 obj.NumSessions+.5], 'ylim', [0 obj.Bins.RT(end)], 'xtick', 1:obj.NumSessions, ...
            'xticklabel', opts.session_date, 'ticklength', [0.01 0.1], 'box', 'off');
    end

%% ha6. Plot reaction time of each session (violin), each port
    function plot_movement_time_violin(ax, obj, opts)

        xline(ax, (1:obj.NumSessions-1)+0.5, 'Color', [.7 .7 .7], 'LineWidth', 1, 'LineStyle', '-');

        dcz_ind = find(obj.Treatment == "DCZ");
        num_dcz = length(dcz_ind);
        patch(ax, 'XData', [dcz_ind-.5 dcz_ind-.5 dcz_ind+.5 dcz_ind+.5]', 'YData', repmat([0; 100; 100; 0], 1, num_dcz), ...
            'FaceColor', opts.color.Treat, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

        thisMT = nan(height(obj.BehavTable), length(obj.Ports)*obj.NumSessions);

        MT = obj.BehavTable.MovementTime;
        [~, ~, indrmv] = rmoutliers_custome(MT);
        MT(indrmv) = nan;

        for s_this = 1:obj.NumSessions
            session_id = obj.BehavTable.SessionDate==obj.Sessions(s_this);
            for p_this = 1:length(obj.Ports)
                ind_this = session_id & obj.BehavTable.Stage==1 & eval("obj.Ind.correct"+obj.Ports(p_this));
                thisMT(ind_this, 2*(s_this-1)+p_this) = MT(ind_this);
            end
        end

        thisMT(1, all(isnan(thisMT))) = 0;
        violinplot({thisMT(:, 2:2:end), thisMT(:, 1:2:end)}, obj.Sessions, ...
            'ViolinColor', {repmat(opts.color.PortR, obj.NumSessions, 1), repmat(opts.color.PortL, obj.NumSessions, 1)}, ...
            'ScatterSize', 4, 'ShowMedian', false, 'ShowWhisker', false, 'ShowBox', false);

        session_order = [1:obj.NumSessions; 1:obj.NumSessions];
        session_order = session_order(:);
        scatter(ax, session_order, median(thisMT, 'omitnan'), 24, ...
            repmat([opts.color.PortL; opts.color.PortR], obj.NumSessions, 1), ...
            'filled', 'LineWidth', 1, 'MarkerEdgeColor', [.3 .3 .3]);

        ax.XLabel.String = 'Sessions';
        ax.YLabel.String = 'Movement time (s)';
        set(ax, 'xlim', [.5 obj.NumSessions+.5], 'ylim', [0 obj.Bins.MovementTime(end)], 'xtick', 1:obj.NumSessions, ...
            'xticklabel', opts.session_date, 'ticklength', [0.01 0.1], 'box', 'off');
    end

%% ha6. Plot reaction time of each session (violin), each port
    function plot_shuttle_time_violin(ax, obj, opts)

        xline(ax, (1:obj.NumSessions-1)+0.5, 'Color', [.7 .7 .7], 'LineWidth', 1, 'LineStyle', '-');

        dcz_ind = find(obj.Treatment == "DCZ");
        num_dcz = length(dcz_ind);
        patch(ax, 'XData', [dcz_ind-.5 dcz_ind-.5 dcz_ind+.5 dcz_ind+.5]', 'YData', repmat([0; 100; 100; 0], 1, num_dcz), ...
            'FaceColor', opts.color.Treat, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

        thisSTLog = nan(height(obj.BehavTable), obj.NumSessions);

        STLog = log(obj.BehavTable.ShuttleTime);
        [~, ~, indrmv] = rmoutliers_custome(STLog);
        STLog(indrmv) = nan;

        for s_this = 1:obj.NumSessions
            session_id = obj.BehavTable.SessionDate==obj.Sessions(s_this);

            ind_this = session_id & obj.BehavTable.Stage==1;
            thisSTLog(ind_this, s_this) = STLog(ind_this);
        end

        thisSTLog(1, all(isnan(thisSTLog))) = 0;
        violinplot(thisSTLog, obj.Sessions, ...
            'ViolinColor', zeros(obj.NumSessions, 3), ...
            'ScatterSize', 4, 'ShowMedian', false, 'ShowWhisker', false, 'ShowBox', false);

        scatter(ax, 1:obj.NumSessions, median(thisSTLog, 'omitnan'), 24, ...
            repmat(1-opts.color.Control, obj.NumSessions, 1), ...
            'filled', 'LineWidth', 1, 'MarkerEdgeColor', [.3 .3 .3]);

        ax.XLabel.String = 'Sessions';
        ax.YLabel.String = 'Log Shuttle time (s)';
        set(ax, 'xlim', [.5 obj.NumSessions+.5], 'ylim', [0 obj.Bins.ShuttleTimeLog(end)], 'xtick', 1:obj.NumSessions, ...
            'xticklabel', opts.session_date, 'ticklength', [0.01 0.1], 'box', 'off');
    end

%%
    function plot_reaction_time_median(ax, obj, opts)

        xline(ax, (1:obj.NumSessions-1)+0.5, 'Color', [.7 .7 .7], 'LineWidth', 1, 'LineStyle', '-');
        yline(0.5, 'Color', [.7 .7 .7], 'LineWidth', 1.5, 'LineStyle', '--');

        dcz_ind = find(obj.Treatment == "DCZ");
        num_dcz = length(dcz_ind);
        patch(ax, 'XData', [dcz_ind-.5 dcz_ind-.5 dcz_ind+.5 dcz_ind+.5]', 'YData', repmat([0; 100; 100; 0], 1, num_dcz), ...
            'FaceColor', opts.color.Treat, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

        for s_this = 1:obj.NumSessions
            for p_this = 1:2
                plot([s_this-0.35 s_this s_this+0.35], ...
                    obj.RTStat.Median(obj.RTStat.Port==obj.Ports(p_this) & obj.RTStat.Sessions==obj.Sessions(s_this) & obj.RTStat.thisFP~=0), ...
                    'Color', eval("opts.color.Port"+obj.Ports(p_this)), 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12);
            end
        end

        ax.XLabel.String = 'Sessions';
        ax.YLabel.String = 'Reaction time (s)';
        set(ax, 'xlim', [.5 obj.NumSessions+.5], 'ylim', [0 .5], 'xtick', 1:obj.NumSessions, ...
            'xticklabel', opts.session_date, 'ticklength', [0.01 0.1], 'box', 'off');
    end

%%
    function plot_reaction_time_iqr(ax, obj, opts)

        xline(ax, (1:obj.NumSessions-1)+0.5, 'Color', [.7 .7 .7], 'LineWidth', 1, 'LineStyle', '-');

        dcz_ind = find(obj.Treatment == "DCZ");
        num_dcz = length(dcz_ind);
        patch(ax, 'XData', [dcz_ind-.5 dcz_ind-.5 dcz_ind+.5 dcz_ind+.5]', 'YData', repmat([0; 100; 100; 0], 1, num_dcz), ...
            'FaceColor', opts.color.Treat, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

        for s_this = 1:obj.NumSessions
            for p_this = 1:length(obj.Ports)
                plot([s_this-0.35 s_this s_this+0.35], ...
                    obj.RTStat.IQR(obj.RTStat.Port==obj.Ports(p_this) & obj.RTStat.Sessions==obj.Sessions(s_this) & obj.RTStat.thisFP~=0), ...
                    'Color', eval("opts.color.Port"+obj.Ports(p_this)), 'LineWidth', 2, 'Marker', '.', 'MarkerSize', 12);
            end
        end

        ax.XLabel.String = 'Sessions';
        ax.YLabel.String = 'Reaction time IQR (s)';
        set(ax, 'xlim', [.5 obj.NumSessions+.5], 'ylim', [0 max(obj.RTStat.IQR)*1.5], 'xtick', 1:obj.NumSessions, ...
            'xticklabel', opts.session_date, 'ticklength', [0.01 0.1], 'box', 'off');
    end

%%
    function plot_hold_duration_heatmap(ax, obj, port, opts)

        hd_l = zeros(length(obj.Bins.HoldDuration), obj.NumSessions*length(obj.MixedFP));
        hd_r = zeros(length(obj.Bins.HoldDuration), obj.NumSessions*length(obj.MixedFP));

        for s_this = 1:obj.NumSessions
            for fp_this = 1:length(obj.MixedFP)
                hd_l(:, s_this + obj.NumSessions*(fp_this-1)) = obj.HDPDF{s_this}{fp_this, 1};
                hd_r(:, s_this + obj.NumSessions*(fp_this-1)) = obj.HDPDF{s_this}{fp_this, 2};
            end
        end

        switch port
            case {"L", "l"}
                imagesc(ax, hd_l);
                ax.YLabel.String = 'Hold duration Left (s)';
                caxis(ax, [-max(max([hd_l; hd_r])) max(max([hd_l; hd_r]))]);
            case {"R", "r"}
                imagesc(ax, hd_r);
                ax.YLabel.String = 'Hold duration Right (s)';
                caxis(ax, [-max(max([hd_l; hd_r])) max(max([hd_l; hd_r]))]);
            case {"Diff", "diff", "L-R", "l-r"}
                imagesc(ax, hd_l-hd_r);
                ax.YLabel.String = 'Hold duration L - R (s)';
                if abs(min(min(hd_l-hd_r))) < abs(max(max(hd_l-hd_r)))
                    caxis(ax, [-abs(max(max(hd_l-hd_r))) abs(max(max(hd_l-hd_r)))]);
                else
                    caxis(ax, [-abs(min(min(hd_l-hd_r))) abs(min(min(hd_l-hd_r)))]);
                end
        end

        line(ax, [.5 obj.NumSessions+.5], [obj.MixedFP(1) obj.MixedFP(1)]/obj.Bins.width, 'Color', [.5 .5 .5], 'LineWidth', 1, 'LineStyle', ':');
        line(ax, [obj.NumSessions+.5 2*obj.NumSessions+.5], [obj.MixedFP(2) obj.MixedFP(2)]/obj.Bins.width, 'Color', [.5 .5 .5], 'LineWidth', 1, 'LineStyle', ':');
        line(ax, [2*obj.NumSessions+.5 3*obj.NumSessions+.5], [obj.MixedFP(3) obj.MixedFP(3)]/obj.Bins.width, 'Color', [.5 .5 .5], 'LineWidth', 1, 'LineStyle', ':');

        xline(ax, (1:2)*obj.NumSessions + .5, 'Color', [.5 .5 .5], 'LineWidth', 1, 'LineStyle', '--');

        ax.XLabel.String = 'Sessions';
        set(ax, 'xlim', [.5 3*obj.NumSessions+.5], 'ylim', [-.5 length(obj.Bins.HoldDuration)+.5], ...
            'xtick', 1:3*obj.NumSessions, 'xticklabel', repmat(opts.session_date, 3, 1), ...
            'ytick', 0:250:length(obj.Bins.HoldDuration), 'yticklabel', string(0:0.5:obj.Bins.HoldDuration(end)), ...
            'ticklength', [0.01 0.1], 'box', 'off');
    end

%%
    function plot_hold_duration_pdf_early_late(ax, obj, port, opts)

        p_this = obj.Ports==upper(string(port));

        if all(all(cellfun(@(x) length(x)>=100, obj.HDSortedNone)))
            HDs = obj.HDSortedNone;
        else
            HDs = cellfun(@(x, y) [x; y], obj.HDSortedNone, obj.HDSortedSaline, 'UniformOutput', false);
        end

        if ~any(any(cellfun(@(x) length(x)>=100, HDs)))
            return
        end

        for fp_this = 1:length(obj.MixedFP)

            xline(ax, obj.MixedFP(fp_this), 'color', [.7 .7 .7], 'linewidth', opts.lw(fp_this), 'LineStyle', '-');

            hd_this = HDs{fp_this, p_this};

            if length(hd_this) < 2*obj.PhaseCount
                continue;
            end

            hd_early_pdf = ksdensity(hd_this(1:obj.PhaseCount), obj.Bins.HoldDuration, 'Function', 'pdf');
            hd_late_pdf  = ksdensity(hd_this(end-obj.PhaseCount+1:end), obj.Bins.HoldDuration, 'Function', 'pdf');

            plot(ax, obj.Bins.HoldDuration, hd_early_pdf, ...
                'color', opts.color.PhaseEarly, 'linewidth', opts.lw(fp_this), 'LineStyle', '-');
            plot(ax, obj.Bins.HoldDuration, hd_late_pdf, ...
                'color', opts.color.PhaseLate, 'linewidth', opts.lw(fp_this), 'LineStyle', '-');

        end

        switch upper(string(port))
            case {"L"}
                ax.YLabel.String = "Prob. density Left (1/s)";
            case {"R"}
                ax.YLabel.String = "Prob. density Right (1/s)";
        end
        
        ax.XLabel.String = "Hold duration (s)";
        set(ax, 'xlim', [0 obj.Bins.HoldDuration(end)], 'ylimmode', 'auto');
    end

    function plot_hold_duration_cdf_early_late(ax, obj, port, opts)

        p_this = obj.Ports==upper(string(port));

        if all(all(cellfun(@(x) length(x)>=100, obj.HDSortedNone)))
            HDs = obj.HDSortedNone;
        else
            HDs = cellfun(@(x, y) [x;y], obj.HDSortedNone, obj.HDSortedSaline, 'UniformOutput', false);
        end

        if ~any(any(cellfun(@(x) length(x)>=100, HDs)))
            return
        end

        for fp_this = 1:length(obj.MixedFP)

            xline(ax, obj.MixedFP(fp_this), 'color', [.7 .7 .7], 'linewidth', opts.lw(fp_this), 'LineStyle', '-');

            hd_this = HDs{fp_this, p_this};

            if length(hd_this) < 2*obj.PhaseCount
                continue;
            end

            hd_early_cdf = ksdensity(hd_this(1:obj.PhaseCount), obj.Bins.HoldDuration, 'Function', 'cdf');
            hd_late_cdf  = ksdensity(hd_this(end-obj.PhaseCount+1:end), obj.Bins.HoldDuration, 'Function', 'cdf');

            plot(ax, obj.Bins.HoldDuration, hd_early_cdf, ...
                'color', opts.color.PhaseEarly, 'linewidth', opts.lw(fp_this), 'LineStyle', '-');
            plot(ax, obj.Bins.HoldDuration, hd_late_cdf, ...
                'color', opts.color.PhaseLate, 'linewidth', opts.lw(fp_this), 'LineStyle', '-');
        end

        switch upper(string(port))
            case {"L"}
                ax.YLabel.String = "Cum. distribution Left";
            case {"R"}
                ax.YLabel.String = "Cum. distribution Right";
        end
        
        ax.XLabel.String = "Hold duration (s)";
        set(ax, 'xlim', [0 obj.Bins.HoldDuration(end)], 'ylim', [0 1]);
    end

end
