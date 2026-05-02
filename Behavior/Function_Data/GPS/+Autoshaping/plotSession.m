function fig = plotSession(obj)

% plot the entire session
Color = GPSColor();

choice_symbols = {'o', 'x'};

fig = figure(22); clf(22);
set(gcf, 'unit', 'centimeters', 'position',[2 2 22 16], 'paperpositionmode', 'auto', 'color', 'w')

plotsize1 = [8 4];
plotsize2 = [2 4];
plotsize3 = [4 4];

set_fig_title(fig, obj.Subject+" / "+obj.Session+" / "+obj.Task);

%% Make a diagram of the setup
ha1 = axes;
set(ha1, 'units', 'centimeters', 'position', [1 11, plotsize1], ...
    'nextplot', 'add', 'ylim', [0 6], 'xlim', [0 12], ...
    'yscale', 'linear', 'ytick', [], 'fontsize', 8)

line([1 1], [0 6], 'color', 'k', 'linewidth', 2);
line([1 3], [0 0], 'color', 'k', 'linewidth', 2);
line([3 5], [0 2], 'color', 'k', 'linewidth', 2);
line([5 8], [2 2], 'color', 'k', 'linewidth', 2);
line([1 3], [6 6], 'color', 'k', 'linewidth', 2);
line([3 5], [6 4], 'color', 'k', 'linewidth', 2);
line([5 8], [4 4], 'color', 'k', 'linewidth', 2);

line([8 9], [4 4.8], 'color', 'k', 'linewidth', 2);
line([8 9], [2 1.2], 'color', 'k', 'linewidth', 2);
line([9 11], [4.8 4.8], 'color', 'k', 'linewidth', 2);
line([9 11], [1.2 1.2], 'color', 'k', 'linewidth', 2);
line([11 11], [1.2 4.8], 'color', 'k', 'linewidth', 2);

viscircles([9.6, 3], 0.3, 'color', 'k', 'LineWidth', 1);
text(9.6, 3.8, 'P_{Init}', 'FontWeight','bold', 'HorizontalAlignment', 'center');
viscircles([3.5, 3], 0.3,  'color', 'k', 'LineWidth', 1);
text(3.9, 3, 'P_{Cent}', 'FontWeight', 'bold');

viscircles([3, 1.5], 0.3, 'color', Color.PortL);
text(1.2, 1.5, 'P_{Left}', 'FontWeight','bold', 'HorizontalAlignment', 'left', 'Color', Color.PortL);
viscircles([3, 4.5], 0.3,  'color', Color.PortR);
text(1.2, 4.5, 'P_{Right}', 'FontWeight', 'bold', 'HorizontalAlignment', 'left', 'Color', Color.PortR);

axis off

%% Cumulative plot
center_pokes = obj.TrialStartTime + cellfun(@(x)x(1), obj.CentPokeInTime); % only count the first one
ha2 = axes;
set(ha2,  'units', 'centimeters', 'position', [1.5 11-plotsize1(2)-1 plotsize1], 'nextplot', 'add', 'ylim', [0 100], 'xlim', [1 3600], 'yscale', 'linear', 'fontsize', 8)
set(ha2, 'xlim', [0 center_pokes(end)+5])
set(ha2, 'ylim', [0 length(center_pokes)+5])
xlabel('Time in session (s)')
ylabel('Trial (count)')

stairs(center_pokes, 1:length(center_pokes), 'color', 'k', 'LineWidth', 1.5);

%% Plot performance over time
ha3 = axes;
set(ha3,  'units', 'centimeters', 'position', [1.5 11-2*plotsize1(2)-2 plotsize1], 'nextplot', 'add', 'ylim', [0 100], 'xlim', [1 3600], 'yscale', 'linear', 'fontsize', 8)
set(ha3, 'xlim', [0 center_pokes(end)+5])

perf_L = obj.PerformanceTrack{1};
perf_R = obj.PerformanceTrack{2};

plot(perf_L.Pos, 100*perf_L.Correct, 'o', 'linestyle', '-', 'color', Color.PortL, ...
    'markersize', 5, 'linewidth', 1, 'markerfacecolor', Color.PortL, 'markeredgecolor', 'w');
plot(perf_R.Pos, 100*perf_R.Correct, 'o', 'linestyle', '-', 'color', Color.PortR, ...
    'markersize', 5, 'linewidth', 1, 'markerfacecolor', Color.PortR, 'markeredgecolor', 'w');

xlabel('Time in session (s)')
ylabel('Performance (%)')

%% Plot shuttle time
ha4 = axes;
set(ha4, 'units', 'centimeters', 'position', [1.5+plotsize1(1)+1 11-plotsize1(2)-1 plotsize1], 'nextplot', 'add', ...
    'ylim', [log10(0.5) 1], 'xlim', [0 3], 'yscale', 'linear','ticklength', [0.01 0.1], ...
    'YTick', log10([0.1:0.1:1 2:10]), 'YTickLabel', ["0.1" repmat("",1,8) "1", repmat("", 1, 8), "10"], 'fontsize', 8)
xlabel('Time in session (s)')
ylabel('Shuttle time (s)')
set(ha4, 'xlim', [0 center_pokes(end)+5]);

line([center_pokes center_pokes]', log10(0.5)+[0 0.05], 'color', 'b')

scatter(center_pokes, ...
    obj.LogST, ...
    25, 'k', choice_symbols{1}, 'Markerfacealpha', 0.8, 'linewidth', 1.05);

%% Plot shuttle time PDF on the right
ha5 = axes;
set(ha5, 'units', 'centimeters', 'position', [1.5+2*plotsize1(1)+1.5 11-plotsize1(2)-1 plotsize2], 'nextplot', 'add', ...
    'ylim', [log10(0.5) 1], 'xlim', [0 5], 'yscale', 'linear', 'yticklabel', [], 'ticklength', [0.02 0.1], ...
    'YTick', log10([0.1:0.1:1 2:10]), 'YTickLabel', ["0.1" repmat("",1,8) "1", repmat("", 1, 8), "10"], 'fontsize', 8)

xlabel('Prob. density (1/s)')
binEdges = -1:0.002:2;
PDF_ST = ksdensity(obj.LogST, binEdges);
plot(ha5, PDF_ST, binEdges, 'color', 'k', 'linewidth', 1.5);
axis 'auto x'

%% plot movement times
ha6 = axes;
set(ha6, 'units', 'centimeters', 'position', [1.5+plotsize1(1)+1 11-2*plotsize1(2)-2 plotsize1], 'nextplot', 'add', ...
    'ylim', [0 2], 'xlim', [1 3600], 'yscale', 'linear', 'ticklength', [0.01 0.1], 'fontsize', 8)
xlabel('Time in session (s)')
ylabel('Movement time (s)')

set(ha6, 'xlim', [0 center_pokes(end)+5])
line([center_pokes center_pokes]', [0 0.1], 'color', 'b')

% port 1 correct (defined by their action, which is also the target for correct response)
ind_correctL = obj.PortChosen==1 & strcmp(obj.Outcome, 'Correct');
hs1 = scatter(center_pokes(ind_correctL), ...
    obj.MT(ind_correctL), ...
    25, Color.PortL, choice_symbols{1},'Markerfacealpha', 0.8, 'linewidth', 1.05);
MTCorrect_PortL = obj.MT(ind_correctL);

% port 2 correct
ind_correctR = obj.PortChosen==2 & strcmp(obj.Outcome, 'Correct');
hs2 = scatter(center_pokes(ind_correctR), ...
    obj.MT(ind_correctR), ...
    25, Color.PortR, choice_symbols{1}, 'Markerfacealpha', 0.8, 'linewidth', 1.05);
MTCorrect_PortR = obj.MT(ind_correctR);

% port 1 wrong (defined by their action, which is different from target)
ind_wrong1 = obj.PortCorrect==1 & strcmp(obj.Outcome, 'Wrong');
hs3 = scatter(center_pokes(ind_wrong1), ...
    obj.MT(ind_wrong1), ...
    25, Color.PortL, choice_symbols{2},'Markerfacealpha', 0.8, 'linewidth', 1.5);

% port 2 wrong
ind_wrong2 = obj.PortCorrect==2 & strcmp(obj.Outcome, 'Wrong');
hs4 = scatter(center_pokes(ind_wrong2), ...
    obj.MT(ind_wrong2), ...
    25, Color.PortR, choice_symbols{2}, 'Markerfacealpha', 0.8, 'linewidth', 1.5);

% legend([hs1 hs2 hs3 hs4], {'Port_{Left} correct', 'Port_{Right} correct', 'Port_{Left} wrong', 'Port_{Right} wrong'}, 'Box', 'off')

%% Plot movement time PDF on the right
ha7 = axes;
set(ha7, 'units', 'centimeters', 'position', [1.5+2*plotsize1(1)+1.5 11-2*plotsize1(2)-2, plotsize2], 'nextplot', 'add', ...
    'ylim', [0 2], 'xlim', [0 1], 'yscale', 'linear', 'yticklabel', [], 'ticklength', [0.02 0.1], 'fontsize', 8)

xlabel('Prob. density (1/s)')
binEdges = 0:0.002:3;

if ~isempty(MTCorrect_PortL)
    PDF_PortL = ksdensity(MTCorrect_PortL, binEdges);
    plot(ha7, PDF_PortL, binEdges, 'color', Color.PortL, 'linewidth', 1.5)

end
if ~isempty(MTCorrect_PortR)
    PDF_PortR = ksdensity(MTCorrect_PortR, binEdges);
    plot(ha7, PDF_PortR, binEdges, 'color', Color.PortR, 'linewidth', 1.5)
end
axis 'auto x'

%% Accuracy of each port
ha8 = axes;
set(ha8,'units', 'centimeters', 'position', [1.5+plotsize1(1)+1, 11, plotsize3], 'nextplot', 'add', 'ylim', [0 100], 'xlim', [0 3], ...
    'xtick', [1 2], 'xticklabel', {'P_{Left}', 'P_{Right}'}, 'fontsize', 8)
ylabel('Accuracy (%)');

hb1 = bar(1, 100*sum(ind_correctL)/sum(obj.PortCorrect==1), 0.7);
set(hb1, 'EdgeColor', 'none', 'facecolor', Color.PortL, 'linewidth', 1);
hb1b = bar(2, 100*sum(ind_correctR)/sum(obj.PortCorrect==2), 0.7);
set(hb1b, 'EdgeColor', 'none', 'facecolor', Color.PortR, 'linewidth', 1);

%% Movement time to each port
ha9 = axes; % this is the legend
set(ha9,'units', 'centimeters', 'position', [1.5+plotsize1(1)+plotsize3(1)+3, 11, plotsize3], 'nextplot', 'add', 'ylim', [0 4], 'xlim', [0 3], ...
    'xtick', [1 2], 'xticklabel', {'P_{Left}', 'P_{Right}'}, 'fontsize', 8)
ylabel('Movement time (s)');

scatter(ones(length(MTCorrect_PortL)), MTCorrect_PortL, 25, Color.PortL, choice_symbols{1},'Markerfacealpha', 0.8, 'linewidth', 1.05, 'XJitter', 'density', 'XJitterWidth', 0.5)
scatter(2*ones(length(MTCorrect_PortR)), MTCorrect_PortR, 25, Color.PortR, choice_symbols{1}, 'Markerfacealpha', 0.8, 'linewidth', 1.05, 'XJitter', 'density', 'XJitterWidth', 0.5)

end

