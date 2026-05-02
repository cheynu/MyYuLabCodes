function fig = plotShow(obj)

%%
opts.color = GPSColor(); % Color class for GPS
opts.mk = ["o", "x"]; % Scatter marker for correct and others
opts.ls = [":", "-.", "-"]; % Line style for [ShortFP, MedFP, LongFP]
opts.lw = [1, 1.5, 2]; % Line width for [ShortFP, MedFP, LongFP]

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

%%
fig = figure(24); clf(24);
set(gcf, 'unit', 'centimeters', 'position', [2 2 30 12], 'paperpositionmode', 'auto', 'color', 'w');

uicontrol('Style', 'text', 'parent', 24, 'units', 'normalized', 'position', [0.3 0.95 0.4 0.04],...
    'string', obj.Subject+" / "+obj.Task, 'fontsize', 11, 'fontweight', 'bold', 'backgroundcolor', 'w');

%% Set axes and plot
%
ha_maze = axes();
set(ha_maze, 'units', 'centimeters', 'position', [1.2 7, 8 4], ...
    'nextplot', 'add', 'fontsize', 7, 'tickdir', 'out');
plot_diagram(ha_maze, opts);

% Performance track
ha1 = axes;
set(ha1, 'units', 'centimeters', 'position', [1.8 1.5, 6 4.5], ...
    'nextplot', 'add', 'fontsize', 9, 'tickdir', 'out');
plot_performance_progress(ha1, obj, opts);

% legend
ha11 = axes;
set(ha11, 'units', 'centimeters', 'position', [7.8 2.2, 1.5 3.7], ...
    'nextplot', 'add', 'fontsize', 7, 'tickdir', 'out');
line(ha11, [0 .6], [0 0], 'Color', opts.color.Correct, 'LineWidth', 1);
text(ha11, .7, 0, 'Correct', 'Fontsize', 9, 'Color', opts.color.Correct);
line(ha11, [0 .6], [1 1], 'Color', opts.color.Premature, 'LineWidth', 1);
text(ha11, .7, 1, 'Premature', 'Fontsize', 9, 'Color', opts.color.Premature);
line(ha11, [0 .6], [2 2], 'Color', opts.color.Wrong, 'LineWidth', 1);
text(ha11, .7, 2, 'Wrong', 'Fontsize', 9, 'Color', opts.color.Wrong);
line(ha11, [0 .6], [3 3], 'Color', opts.color.Late, 'LineWidth', 1);
text(ha11, .7, 3, 'Late', 'Fontsize', 9, 'Color', opts.color.Late);

set(ha11, 'xlim', [0 2], 'ylim', [0 7], 'xcolor', 'none', 'ycolor', 'none', 'ydir', 'reverse', 'color', 'none');

ha2 = axes;
set(ha2, 'units', 'centimeters', 'position', [11 1.5, 4 4], ...
    'nextplot', 'add', 'fontsize', 9, 'tickdir', 'out');
plot_reaction_time(ha2, obj, opts, 'early');

ha21 = axes;
set(ha21, 'units', 'centimeters', 'position', [15.5 1.5, 4 4], ...
    'nextplot', 'add', 'fontsize', 9, 'tickdir', 'out');
plot_reaction_time(ha21, obj, opts, 'late');
set(ha21, 'yticklabel', [], 'ylabel', []);

ha2.YLim(2) = 0.3; %max([ha2.YLim(2) ha21.YLim(2)]);
ha21.YLim(2) = 0.3; %ha2.YLim(2);

ha_ct = axes;
set(ha_ct, 'units', 'centimeters', 'position', [11 6.5, 4 4], ...
    'nextplot', 'add', 'fontsize', 9, 'tickdir', 'out');
plot_choice_time(ha_ct, obj, opts, 'early');
set(ha_ct, 'xlabel', [], 'xticklabel', []);

ha_ct1 = axes;
set(ha_ct1, 'units', 'centimeters', 'position', [15.5 6.5, 4 4], ...
    'nextplot', 'add', 'fontsize', 9, 'tickdir', 'out');
plot_choice_time(ha_ct1, obj, opts, 'late');
set(ha_ct1, 'yticklabel', [], 'ylabel', [], 'xlabel', [], 'xticklabel', []);

ha_ct.YLim(2) = 0.8; %max([ha_ct.YLim(2) ha_ct1.YLim(2)]);
ha_ct1.YLim(2) = 0.8; %ha_ct.YLim(2);

ha3 = axes;
set(ha3, 'units', 'centimeters', 'position', [21.3 1.5, 8 4], ...
    'nextplot', 'add', 'fontsize', 9, 'tickdir', 'out');
plot_hold_duration_pdf_early_late(ha3, obj, "l", opts)

ha31 = axes;
set(ha31, 'units', 'centimeters', 'position', [21.3 6.5, 8 4], ...
    'nextplot', 'add', 'fontsize', 9, 'tickdir', 'out');
plot_hold_duration_pdf_early_late(ha31, obj, "r", opts)
set(ha31, 'xticklabel', [], 'xlabel', []);

ha3.YLim(2) = max([ha3.YLim(2) ha31.YLim(2)]);
ha31.YLim(2) = ha3.YLim(2);

ha32 = axes;
set(ha32, 'units', 'centimeters', 'position', [27.5 10, 1.5 1.2], ...
    'nextplot', 'add', 'fontsize', 9, 'color', 'none', 'xcolor', 'none', 'ycolor', 'none', 'xlim', [0 3], 'ylim', [0 3], 'ticklength', [0.01 0.1], 'tickdir', 'out');
line(ha32, [1 2], [2 2], 'Color', opts.color.PhaseEarly, 'LineWidth', 1.5, 'LineStyle', '-');
line(ha32, [1 2], [1 1], 'Color', opts.color.PhaseLate, 'LineWidth', 1.5, 'LineStyle', '-');
text(ha32, 2.2, 2, "Early", 'FontSize', 9);
text(ha32, 2.2, 1, "Late", 'FontSize', 9);

%%
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

%% ha1. Make a diagram of the setup
    function plot_performance_progress(ax, obj, opts)

        session_id = 1:obj.NumSessions;

        ind_this = find(obj.Performance.Foreperiod==0 & obj.Performance.TargetPort=="Both");

        plot(ax, session_id, obj.Performance.PrematureRatio(ind_this), 'o', 'linestyle', '-', 'color', opts.color.Premature, ...
            'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', opts.color.Premature, 'markeredgecolor', 'w', 'MarkerSize', 6);
        plot(ax, session_id, obj.Performance.LateRatio(ind_this), 'o', 'linestyle', '-', 'color', opts.color.Late, ...
            'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', opts.color.Late, 'markeredgecolor', 'w', 'MarkerSize', 6);
        plot(ax, session_id, obj.Performance.WrongRatio(ind_this), 'o', 'linestyle', '-', 'color', opts.color.Wrong, ...
            'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', opts.color.Wrong, 'markeredgecolor', 'w', 'MarkerSize', 6);
        plot(ax, session_id, obj.Performance.CorrectRatio(ind_this), 'o', 'linestyle', '-', 'color', opts.color.Correct, ...
            'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', opts.color.Correct, 'markeredgecolor', 'w', 'MarkerSize', 6);

        ax.XLabel.FontWeight = "Bold";
        ax.YLabel.FontWeight = "Bold";
        ax.XLabel.String = 'Sessions';
        ax.YLabel.String = 'Performance (%)';
        set(ax, 'xlim', [0.5 obj.NumSessions+0.5], 'ylim', [0 100], 'xtick', session_id, 'tickdir', 'out');
    end

%% Reaction time violin
    function plot_reaction_time(ax, obj, opts, phase)

        sig_ax = axes('Units', ax.Units, 'Position', ax.Position, 'nextplot', 'add', ...
            'xlim', [.5 length(obj.MixedFP)+.5], 'YLim', [0 1], ...
            'Color', 'none', 'XColor', 'none', 'YColor', 'none');

        yline(ax, .5, 'Color', [.7 .7 .7], 'LineWidth', 1.5, 'LineStyle', '--')

        num_violin = length(obj.Ports)*length(obj.MixedFP);
        thisRT = nan(obj.PhaseCount, num_violin);
        thisFP = nan(obj.PhaseCount, num_violin);
        thisPort = nan(obj.PhaseCount, num_violin);

        for fp_this = 1:length(obj.MixedFP)
            for p_this = 1:length(obj.Ports)
                thisFP(:, 2*(fp_this-1)+p_this) = fp_this;
                thisPort(:, 2*(fp_this-1)+p_this) = p_this;
                n_this = length(obj.RTSortedAll{fp_this, p_this});
                switch phase
                    case {'early'}
                        ax.Title.String = "Early";
                        ax.Title.Color  = opts.color.PhaseEarly;
                        if n_this >= 2*obj.PhaseCount
                            thisRT(:, 2*(fp_this-1)+p_this) = obj.RTSortedAll{fp_this, p_this}(1:obj.PhaseCount);
                        else
                            thisRT(1:floor(n_this/2), 2*(fp_this-1)+p_this) = obj.RTSortedAll{fp_this, p_this}(1:floor(n_this/2));
                        end
                    case {'late'}
                        ax.Title.String = "Late";
                        ax.Title.Color  = opts.color.PhaseLate;
                        if n_this >= 2*obj.PhaseCount
                            thisRT(:, 2*(fp_this-1)+p_this) = obj.RTSortedAll{fp_this, p_this}(end-obj.PhaseCount+1:end);
                        else
                            thisRT(1:floor(n_this/2), 2*(fp_this-1)+p_this) = obj.RTSortedAll{fp_this, p_this}(end-floor(n_this/2)+1:end);
                        end
                end
            end
        end

        means = mean(thisRT, 'omitnan');
        sems  = std(thisRT, 'omitnan') ./ sqrt(sum(~isnan(thisRT), 'omitnan'));

        pval = anovan(thisRT(:), {thisFP(:), thisPort(:)}, 'model', 'interaction', 'varnames', {'FP', 'Port'}, 'display', 'off');
%         if pval(3)<.05 % interaction
            if pval(1)<.05 % control Port L, test FP
                [pval_left,~,stats_left] = anovan(thisRT(thisPort==1), thisFP(thisPort==1), 'varnames', {'FP'}, 'display', 'off');
                if pval_left<.05
                    results_left = multcompare(stats_left, 'Display', 'off');
                    tbl_left = array2table(results_left, ...
                        "VariableNames", ["Group A","Group B","Lower Limit","A-B","Upper Limit","P-value"]);
                    sig_left = find(tbl_left.("P-value")<.05);
                    for s_this = 1:length(sig_left)
                        sig_this = sig_left(s_this);
                        if mean(means(2:2:end)) < mean(means(1:2:end)) % R < L
                            y_this   = 1.01 - 0.08 * sig_this;
                        else
                            y_this   = -.05 + 0.08 * sig_this;
                        end
                        line(sig_ax, results_left(sig_this, 1:2)-0.08, [y_this y_this], 'Color', opts.color.PortL, 'LineWidth', 1);
                        if tbl_left.("P-value")(sig_this)>0.01
                            text(sig_ax, mean(results_left(sig_this, 1:2)-0.08), y_this+.01, "*", ...
                                "FontSize", 14, 'HorizontalAlignment', 'center', 'Color', opts.color.PortL);
                        elseif tbl_left.("P-value")(sig_this)>0.001
                            text(sig_ax, mean(results_left(sig_this, 1:2)-0.08), y_this+.01, "**", ...
                                "FontSize", 14, 'HorizontalAlignment', 'center', 'Color', opts.color.PortL);
                        else
                            text(sig_ax, mean(results_left(sig_this, 1:2)-0.08), y_this+.01, "***", ...
                                "FontSize", 14, 'HorizontalAlignment', 'center', 'Color', opts.color.PortL);
                        end
                    end
                end

                [pval_right,~,stats_right] = anovan(thisRT(thisPort==2), thisFP(thisPort==2), 'varnames', {'FP'}, 'display', 'off');
                if pval_right<.05
                    results_right = multcompare(stats_right, 'Display', 'off');
                    tbl_right = array2table(results_right, ...
                        "VariableNames", ["Group A","Group B","Lower Limit","A-B","Upper Limit","P-value"]);
                    sig_right = find(tbl_right.("P-value")<.05);
                    for s_this = 1:length(sig_right)
                        sig_this = sig_right(s_this);
                        if mean(means(2:2:end)) > mean(means(1:2:end)) % R > L
                            y_this   = 1.01 - 0.08 * sig_this;
                        else
                            y_this   = -.05 + 0.08 * sig_this;
                        end
                        line(sig_ax, results_right(sig_this, 1:2)+0.08, [y_this y_this], 'Color', opts.color.PortR, 'LineWidth', 1);
                        if tbl_right.("P-value")(sig_this)>0.01
                            text(sig_ax, mean(results_right(sig_this, 1:2)+0.08), y_this+.01, "*", ...
                                "FontSize", 14, 'HorizontalAlignment', 'center', 'Color', opts.color.PortR);
                        elseif tbl_right.("P-value")(sig_this)>0.001
                            text(sig_ax, mean(results_right(sig_this, 1:2)+0.08), y_this+.01, "**", ...
                                "FontSize", 14, 'HorizontalAlignment', 'center', 'Color', opts.color.PortR);
                        else
                            text(sig_ax, mean(results_right(sig_this, 1:2)+0.08), y_this+.01, "***", ...
                                "FontSize", 14, 'HorizontalAlignment', 'center', 'Color', opts.color.PortR);
                        end
                    end
                end
            end

        medians = median(thisRT, 'omitnan');
        iqr_pos = prctile(thisRT, 75)-medians;
        iqr_neg = medians-prctile(thisRT, 25);
      
        errorbar(ax, (1:3)+0.08, means(2:2:end), sems(2:2:end), 'LineStyle', '-', 'CapSize', 2, 'LineWidth', 1.5, ...
            'Color', opts.color.PortR, 'Marker', 'o', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', opts.color.PortR, 'MarkerSize', 5);
        errorbar(ax, (1:3)-0.08, means(1:2:end), sems(1:2:end), 'LineStyle', '-', 'CapSize', 2, 'LineWidth', 1.5, ...
            'Color', opts.color.PortL, 'Marker', 'o', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', opts.color.PortL, 'MarkerSize', 5);

        ax.Title.FontWeight = "Bold";
        ax.XLabel.FontWeight = "Bold";
        ax.YLabel.FontWeight = "Bold";
        ax.XLabel.String = 'Foreperiod (s)';
        ax.YLabel.String = 'Reaction time (s)';
        set(ax, 'xlim', [.5 length(obj.MixedFP)+.5], 'ylim', [0 max(means+sems)+0.08], 'xtick', 1:length(obj.MixedFP), ...
            'xticklabel', obj.MixedFP, 'ticklength', [0.01 0.1], 'box', 'off');
    end

%% Reaction time violin
    function plot_choice_time(ax, obj, opts, phase)

        sig_ax = axes('Units', ax.Units, 'Position', ax.Position, 'nextplot', 'add', ...
            'xlim', [.5 length(obj.MixedFP)+.5], 'YLim', [0 1], ...
            'Color', 'none', 'XColor', 'none', 'YColor', 'none');

        num_violin = length(obj.Ports)*length(obj.MixedFP);
        thisCT = nan(obj.PhaseCount, num_violin);
        thisFP = nan(obj.PhaseCount, num_violin);
        thisPort = nan(obj.PhaseCount, num_violin);

        for fp_this = 1:length(obj.MixedFP)
            for p_this = 1:length(obj.Ports)
                thisFP(:, 2*(fp_this-1)+p_this) = fp_this;
                thisPort(:, 2*(fp_this-1)+p_this) = p_this;
                n_this = length(obj.CTSortedAll{fp_this, p_this});
                switch phase
                    case {'early'}
                        ax.Title.String = "Early";
                        ax.Title.Color  = opts.color.PhaseEarly;
                        if n_this >= 2*obj.PhaseCount
                            thisCT(:, 2*(fp_this-1)+p_this) = obj.CTSortedAll{fp_this, p_this}(1:obj.PhaseCount);
                        else
                            thisCT(1:floor(n_this/2), 2*(fp_this-1)+p_this) = obj.CTSortedAll{fp_this, p_this}(1:floor(n_this/2));
                        end
                    case {'late'}
                        ax.Title.String = "Late";
                        ax.Title.Color  = opts.color.PhaseLate;
                        if n_this >= 2*obj.PhaseCount
                            thisCT(:, 2*(fp_this-1)+p_this) = obj.CTSortedAll{fp_this, p_this}(end-obj.PhaseCount+1:end);
                        else
                            thisCT(1:floor(n_this/2), 2*(fp_this-1)+p_this) = obj.CTSortedAll{fp_this, p_this}(end-floor(n_this/2)+1:end);
                        end
                end
            end
        end

        [~, ~, indrmv] = rmoutliers_custome(thisCT(:));
        thisCT(indrmv) = nan;

        means = mean(thisCT, 'omitnan');
        sems  = std(thisCT, 'omitnan') ./ sqrt(sum(~isnan(thisCT), 'omitnan'));

        pval = anovan(thisCT(:), {thisFP(:), thisPort(:)}, 'model', 'interaction', 'varnames', {'FP', 'Port'}, 'display', 'off');
%         if pval(3)<.05 % interaction
            if pval(1)<.05 % control Port L, test FP
                [pval_left,~,stats_left] = anovan(thisCT(thisPort==1), thisFP(thisPort==1), 'varnames', {'FP'}, 'display', 'off');
                if pval_left<.05
                    results_left = multcompare(stats_left, 'Display', 'off');
                    tbl_left = array2table(results_left, ...
                        "VariableNames", ["Group A","Group B","Lower Limit","A-B","Upper Limit","P-value"]);
                    sig_left = find(tbl_left.("P-value")<.05);
                    for s_this = 1:length(sig_left)
                        sig_this = sig_left(s_this);
                        if mean(means(2:2:end)) < mean(means(1:2:end)) % R < L
                            y_this   = 1.01 - 0.08 * sig_this;
                        else
                            y_this   = -.05 + 0.08 * sig_this;
                        end
                        line(sig_ax, results_left(sig_this, 1:2)-0.08, [y_this y_this], 'Color', opts.color.PortL, 'LineWidth', 1);
                        if tbl_left.("P-value")(sig_this)>0.01
                            text(sig_ax, mean(results_left(sig_this, 1:2)-0.08), y_this+.01, "*", ...
                                "FontSize", 14, 'HorizontalAlignment', 'center', 'Color', opts.color.PortL);
                        elseif tbl_left.("P-value")(sig_this)>0.001
                            text(sig_ax, mean(results_left(sig_this, 1:2)-0.08), y_this+.01, "**", ...
                                "FontSize", 14, 'HorizontalAlignment', 'center', 'Color', opts.color.PortL);
                        else
                            text(sig_ax, mean(results_left(sig_this, 1:2)-0.08), y_this+.01, "***", ...
                                "FontSize", 14, 'HorizontalAlignment', 'center', 'Color', opts.color.PortL);
                        end
                    end
                end

                [pval_right,~,stats_right] = anovan(thisCT(thisPort==2), thisFP(thisPort==2), 'varnames', {'FP'}, 'display', 'off');
                if pval_right<.05
                    results_right = multcompare(stats_right, 'Display', 'off');
                    tbl_right = array2table(results_right, ...
                        "VariableNames", ["Group A","Group B","Lower Limit","A-B","Upper Limit","P-value"]);
                    sig_right = find(tbl_right.("P-value")<.05);
                    for s_this = 1:length(sig_right)
                        sig_this = sig_right(s_this);
                        if mean(means(2:2:end)) > mean(means(1:2:end)) % R > L
                            y_this   = 1.01 - 0.08 * sig_this;
                        else
                            y_this   = -.05 + 0.08 * sig_this;
                        end
                        line(sig_ax, results_right(sig_this, 1:2)+0.08, [y_this y_this], 'Color', opts.color.PortR, 'LineWidth', 1);
                        if tbl_right.("P-value")(sig_this)>0.01
                            text(sig_ax, mean(results_right(sig_this, 1:2)+0.08), y_this+.01, "*", ...
                                "FontSize", 14, 'HorizontalAlignment', 'center', 'Color', opts.color.PortR);
                        elseif tbl_right.("P-value")(sig_this)>0.001
                            text(sig_ax, mean(results_right(sig_this, 1:2)+0.08), y_this+.01, "**", ...
                                "FontSize", 14, 'HorizontalAlignment', 'center', 'Color', opts.color.PortR);
                        else
                            text(sig_ax, mean(results_right(sig_this, 1:2)+0.08), y_this+.01, "***", ...
                                "FontSize", 14, 'HorizontalAlignment', 'center', 'Color', opts.color.PortR);
                        end
                    end
                end
            end

        medians = median(thisCT, 'omitnan');
        iqr_pos = prctile(thisCT, 75)-medians;
        iqr_neg = medians-prctile(thisCT, 25);
      
        errorbar(ax, (1:3)+0.08, means(2:2:end), sems(2:2:end), 'LineStyle', '-', 'CapSize', 2, 'LineWidth', 1.5, ...
            'Color', opts.color.PortR, 'Marker', 'o', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', opts.color.PortR, 'MarkerSize', 5);
        errorbar(ax, (1:3)-0.08, means(1:2:end), sems(1:2:end), 'LineStyle', '-', 'CapSize', 2, 'LineWidth', 1.5, ...
            'Color', opts.color.PortL, 'Marker', 'o', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', opts.color.PortL, 'MarkerSize', 5);

        ax.Title.FontWeight = "Bold";
        ax.XLabel.FontWeight = "Bold";
        ax.YLabel.FontWeight = "Bold";
        ax.XLabel.String = 'Foreperiod (s)';
        ax.YLabel.String = 'Choice time (s)';
        set(ax, 'xlim', [.5 length(obj.MixedFP)+.5], 'ylim', [0 max(means+sems)+0.08], 'xtick', 1:length(obj.MixedFP), ...
            'xticklabel', obj.MixedFP, 'ticklength', [0.01 0.1], 'box', 'off');
    end

%%

    function plot_hold_duration_pdf_early_late(ax, obj, port, opts)

        n_boot = 1000;
        alpha_ci = 0.05;
        band_width = 0.05;

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

            kde = @(x) ksdensity(x, obj.Bins.HoldDuration, 'Function', 'pdf', 'Bandwidth', band_width);
            hd_early_pdf = kde(hd_this(1:obj.PhaseCount));
            hd_late_pdf  = kde(hd_this(end-obj.PhaseCount+1:end));

            hd_early_pdf_ci = bootci(n_boot, {kde, hd_this(1:obj.PhaseCount)}, 'Type', 'cper', 'Alpha', alpha_ci);
            hd_late_pdf_ci  = bootci(n_boot, {kde, hd_this(end-obj.PhaseCount+1:end)}, 'Type', 'cper', 'Alpha', alpha_ci);

            fill(ax, [obj.Bins.HoldDuration flip(obj.Bins.HoldDuration)], [hd_early_pdf_ci(1,:) flip(hd_early_pdf_ci(2,:))], 'y', ...
                'FaceColor', opts.color.PhaseEarly, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
            plot(ax, obj.Bins.HoldDuration, hd_early_pdf, ...
                'color', opts.color.PhaseEarly, 'linewidth', opts.lw(fp_this), 'LineStyle', '-');
            fill(ax, [obj.Bins.HoldDuration flip(obj.Bins.HoldDuration)], [hd_late_pdf_ci(1,:) flip(hd_late_pdf_ci(2,:))], 'y', ...
                'FaceColor', opts.color.PhaseLate, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
            plot(ax, obj.Bins.HoldDuration, hd_late_pdf, ...
                'color', opts.color.PhaseLate, 'linewidth', opts.lw(fp_this), 'LineStyle', '-');

        end

        switch upper(string(port))
            case {"L"}
                ax.YLabel.String = "Prob. density Left (1/s)";
                ax.YLabel.Color  = opts.color.PortL;
            case {"R"}
                ax.YLabel.String = "Prob. density Right (1/s)";
                ax.YLabel.Color  = opts.color.PortR;
        end

        ax.XLabel.FontWeight = "Bold";
        ax.YLabel.FontWeight = "Bold";
        ax.XLabel.String = "Hold duration (s)";
        set(ax, 'xlim', [0 2], 'ylimmode', 'auto', 'tickdir', 'out');
    end

end
