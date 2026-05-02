function fig = plotSession(obj)

% plot the entire session
Color = GPSColor();
choice_symbols = {'o', 'x'};

fig = figure(22); clf(22);
set(gcf, 'unit', 'centimeters', 'position',[2 2 22 21.2], 'paperpositionmode', 'auto', 'color', 'w')

plotsize1 = [8 4];
plotsize2 = [2 4];
plotsize3 = [3.5 4];

set_fig_title(fig, obj.Subject+" /"+obj.Session+" / "+obj.Task);

%% Make a diagram of the setup
ha1 = axes;
set(ha1, 'units', 'centimeters', 'position', [1 16, plotsize1], ...
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
text(8.6, 3, 'P_{Init}', 'FontWeight','bold', 'HorizontalAlignment', 'center');
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
set(ha2,  'units', 'centimeters', 'position', [1.5 16-plotsize1(2)-1, plotsize1], 'nextplot', 'add', 'ylim', [0 100], 'xlim', [1 3600], 'yscale', 'linear', 'fontsize', 8)
set(ha2, 'xlim', [0 center_pokes(end)+5])
set(ha2, 'ylim', [0 length(center_pokes)+5])
xlabel('Time in session (s)')
ylabel('Trial (count)')

stairs(center_pokes, 1:length(center_pokes), 'color', Color.Control, 'LineWidth', 1.5);

%% Plot performance over time
ha3 = axes;
set(ha3,  'units', 'centimeters', 'position', [1.5 16-2*plotsize1(2)-2, plotsize1], 'nextplot', 'add', 'ylim', [0 100], 'xlim', [1 3600], 'yscale', 'linear', 'fontsize', 8)
set(ha3, 'xlim', [0 center_pokes(end)+5])
WinSize = floor(obj.NumTrials/5);
StepSize = max(1, floor(WinSize/5));
CountStart = 1;
WinPos = [];
CorrectRatio = [];
WrongRatio = [];
PrematureRatio = [];
while CountStart+WinSize < obj.NumTrials
    thisWin = CountStart:(CountStart+WinSize);
    thisOutcome = obj.Outcome(thisWin);
    CorrectRatio = [CorrectRatio 100*sum(strcmp(thisOutcome, 'Correct')) / length(thisOutcome)];
    WrongRatio = [WrongRatio 100*sum(strcmp(thisOutcome, 'Wrong')) / length(thisOutcome)];
    PrematureRatio = [PrematureRatio 100*sum(strcmp(thisOutcome, 'Premature')) / length(thisOutcome)];
    WinPos = [WinPos center_pokes(thisWin(end))];
    CountStart = CountStart + StepSize;
end

plot(WinPos, CorrectRatio, 'o', 'linestyle', '-', 'color', Color.Correct, ...
    'markersize', 5, 'linewidth', 1, 'markerfacecolor', Color.Correct, 'markeredgecolor', 'w');
plot(WinPos, WrongRatio, 'o', 'linestyle', '-', 'color', Color.Wrong, ...
    'markersize', 5, 'linewidth', 1, 'markerfacecolor', Color.Wrong, 'markeredgecolor', 'w');
plot(WinPos, PrematureRatio, 'o', 'linestyle', '-', 'color', Color.Premature, ...
    'markersize', 5, 'linewidth', 1, 'markerfacecolor', Color.Premature, 'markeredgecolor', 'w');

xlabel('Time in session (s)')
ylabel('Performance (%)')

%% Plot shuttle time
ha4 = axes;
set(ha4, 'units', 'centimeters', 'position', [1.5+plotsize1(1)+1 16, plotsize1], 'nextplot', 'add', ...
    'ylim', [0 3], 'xlim', [0 3], 'yscale', 'linear','ticklength', [0.01 0.1], 'ytick', 1:3, 'yticklabel', {'10^1', '10^2', '10^3'}, 'fontsize', 8)
xlabel('Time in session (s)')
ylabel('Shuttle time (s)')
set(ha4, 'xlim', [0 center_pokes(end)+5]);

line([center_pokes center_pokes]', [0 0.15], 'color', 'K')

scatter(center_pokes, ...
    obj.LogST, ...
    24, 'k', choice_symbols{1}, 'Markerfacealpha', 0.8, 'linewidth', 1.5);

%% Plot shuttle time PDF on the right
ha5 = axes;
set(ha5, 'units', 'centimeters', 'position', [1.5+2*plotsize1(1)+1.5 16, plotsize2], 'nextplot', 'add', 'ylim', [0 3], ...
    'xlim', [0 5], 'yscale', 'linear', 'yticklabel', [], 'ticklength', [0.02 0.1], 'ytick', 1:3, 'fontsize', 8)

xlabel('Prob. density (1/s)')
binEdges = 0:0.01:3;
PDF_LogST = ksdensity(obj.LogST, binEdges);
plot(ha5, PDF_LogST, binEdges, 'color', 'k', 'linewidth', 1.5);
axis 'auto x'

%% Plot hold duration and FP
ha6 = axes;
set(ha6, 'units', 'centimeters', 'position', [1.5+plotsize1(1)+1 16-plotsize1(2)-1, plotsize1], 'nextplot', 'add', ...
    'ylim', [0 3], 'xlim', [0 3], 'yscale', 'linear','ticklength', [0.01 0.1], 'fontsize', 8)
xlabel('Time in session (s)')
ylabel('Hold duration (s)')
set(ha6, 'xlim', [0 center_pokes(end)+5]);

line([center_pokes center_pokes]', [0 3/20], 'color', 'K')

stairs(center_pokes, obj.FP, 'color', [.7 .7 .7], 'LineWidth', 1.5);

% port 1 correct (defined by their action, which is also the target for correct response)
ind_correctL = obj.PortChosen==1 & strcmp(obj.Outcome, 'Correct');
scatter(center_pokes(ind_correctL), ...
    obj.HD(ind_correctL), ...
    18*(obj.FP(ind_correctL)+0.5), Color.PortL, choice_symbols{1},'Markerfacealpha', 0.8, 'linewidth', 1.5);

% port 2 correct
ind_correctR = obj.PortChosen==2 & strcmp(obj.Outcome, 'Correct');
scatter(center_pokes(ind_correctR), ...
    obj.HD(ind_correctR), ...
    18*(obj.FP(ind_correctR)+0.5), Color.PortR, choice_symbols{1}, 'Markerfacealpha', 0.8, 'linewidth', 1.5);

% port 1 wrong (defined by their action, which is different from target)
ind_wrongL = obj.PortCorrect==1 & strcmp(obj.Outcome, 'Wrong');
scatter(center_pokes(ind_wrongL), ...
    obj.HD(ind_wrongL), ...
    22*(obj.FP(ind_wrongL)+0.5), Color.PortL, choice_symbols{2},'Markerfacealpha', 0.8, 'linewidth', 1.5);

% port 2 wrong
ind_wrongR = obj.PortCorrect==2 & strcmp(obj.Outcome, 'Wrong');
scatter(center_pokes(ind_wrongR), ...
    obj.HD(ind_wrongR), ...
    22*(obj.FP(ind_wrongR)+0.5), Color.PortR, choice_symbols{2}, 'Markerfacealpha', 0.8, 'linewidth', 1.5);

% premature
ind_premature = strcmp(obj.Outcome, 'Premature');
scatter(center_pokes(ind_premature), ...
    obj.HD(ind_premature), ...
    22*(obj.FP(ind_premature)+0.5), Color.Premature, choice_symbols{2}, 'Markerfacealpha', 0.8, 'linewidth', 1.5);

%% plot hold duration density
ha7 = axes;
set(ha7, 'units', 'centimeters', 'position', [1.5+2*plotsize1(1)+1.5 16-plotsize1(2)-1, plotsize2], 'nextplot', 'add', 'ylim', [0 3], ...
    'xlim', [0 1], 'yscale', 'linear', 'yticklabel', [], 'ticklength', [0.02 0.1], 'fontsize', 8)

xlabel('Prob. density (1/s)')
binEdges = 0:0.01:4;

yline(1.5, 'Color', [.7 .7 .7], 'LineWidth', 1.5, 'LineStyle', '--');

if sum(obj.FP==1.5)
    PDF = ksdensity(obj.HD(obj.FP==1.5), binEdges);
    plot(ha7, PDF, binEdges, 'color', Color.Control, 'linewidth', 1.5)
end

axis 'auto x'

%% Plot reaction time
ha8 = axes;
set(ha8, 'units', 'centimeters', 'position', [1.5+plotsize1(1)+1 16-2*plotsize1(2)-2, plotsize1], 'nextplot', 'add', ...
    'ylim', [0 1], 'xlim', [0 3], 'yscale', 'linear','ticklength', [0.01 0.1], 'fontsize', 8)
xlabel('Time in session (s)')
ylabel('Reaction time (s)')
set(ha8, 'xlim', [0 center_pokes(end)+5]);

line([center_pokes center_pokes]', [0 1/20], 'color', 'K')

% port 1 correct (defined by their action, which is also the target for correct response)
scatter(center_pokes(ind_correctL), ...
    obj.RT(ind_correctL), ...
    18*(obj.FP(ind_correctL)+0.5), Color.PortL, choice_symbols{1},'Markerfacealpha', 0.8, 'linewidth', 1.5);

% port 2 correct
scatter(center_pokes(ind_correctR), ...
    obj.RT(ind_correctR), ...
    18*(obj.FP(ind_correctR)+0.5), Color.PortR, choice_symbols{1}, 'Markerfacealpha', 0.8, 'linewidth', 1.5);

% port 1 wrong (defined by their action, which is different from target)
scatter(center_pokes(ind_wrongL), ...
    obj.RT(ind_wrongL), ...
    22*(obj.FP(ind_wrongL)+0.5), Color.PortL, choice_symbols{2},'Markerfacealpha', 0.8, 'linewidth', 1.5);

% port 2 wrong
scatter(center_pokes(ind_wrongR), ...
    obj.RT(ind_wrongR), ...
    22*(obj.FP(ind_wrongR)+0.5), Color.PortR, choice_symbols{2}, 'Markerfacealpha', 0.8, 'linewidth', 1.5);

%% plot reaction time density
ha9 = axes;
set(ha9, 'units', 'centimeters', 'position', [1.5+2*plotsize1(1)+1.5 16-2*plotsize1(2)-2, plotsize2], 'nextplot', 'add', 'ylim', [0 1], ...
    'xlim', [0 1], 'yscale', 'linear', 'yticklabel', [], 'ticklength', [0.02 0.1], 'fontsize', 8)

xlabel('Prob. density (1/s)')
binEdges = 0:0.01:1;

if any(~isnan(obj.RT(ind_correctL & obj.FP==1.5)))
    PDF_L = ksdensity(obj.RT(ind_correctL & obj.FP==1.5), binEdges);
    plot(ha9, PDF_L, binEdges, 'color', Color.PortL, 'linewidth', 1.5)
end
if any(~isnan(obj.RT(ind_correctR & obj.FP==1.5)))
    PDF_R = ksdensity(obj.RT(ind_correctR & obj.FP==1.5), binEdges);
    plot(ha9, PDF_R, binEdges, 'color', Color.PortR, 'linewidth', 1.5)
end

axis 'auto x'

%% plot movement times
ha10 = axes;
set(ha10, 'units', 'centimeters', 'position', [1.5+plotsize1(1)+1 16-3*plotsize1(2)-3, plotsize1], 'nextplot', 'add', ...
    'ylim', [0 3], 'xlim', [1 3600], 'yscale', 'linear', 'ticklength', [0.01 0.1], 'fontsize', 8)
xlabel('Time in session (s)')
ylabel('Movement time (s)')

set(ha10, 'xlim', [0 center_pokes(end)+5])
line([center_pokes center_pokes]', [0 0.15], 'color', 'k')

% port 1 correct (defined by their action, which is also the target for correct response)
scatter(center_pokes(ind_correctL), ...
    obj.MT(ind_correctL), ...
    18*(obj.FP(ind_correctL)+0.5), Color.PortL, choice_symbols{1},'Markerfacealpha', 0.8, 'linewidth', 1.5);

% port 2 correct
scatter(center_pokes(ind_correctR), ...
    obj.MT(ind_correctR), ...
    18*(obj.FP(ind_correctR)+0.5), Color.PortR, choice_symbols{1}, 'Markerfacealpha', 0.8, 'linewidth', 1.5);

% port 1 wrong (defined by their action, which is different from target)
scatter(center_pokes(ind_wrongL), ...
    obj.MT(ind_wrongL), ...
    22*(obj.FP(ind_wrongL)+0.5), Color.PortL, choice_symbols{2},'Markerfacealpha', 0.8, 'linewidth', 1.5);

% port 2 wrong
scatter(center_pokes(ind_wrongR), ...
    obj.MT(ind_wrongR), ...
    22*(obj.FP(ind_wrongR)+0.5), Color.PortR, choice_symbols{2}, 'Markerfacealpha', 0.8, 'linewidth', 1.5);

% legend([hs1 hs2 hs3 hs4], {'Port_{Left} correct', 'Port_{Right} correct', 'Port_{Left} wrong', 'Port_{Right} wrong'}, 'Box', 'off')

%% Plot movement time PDF on the right
ha11 = axes;
set(ha11, 'units', 'centimeters', 'position', [1.5+2*plotsize1(1)+1.5 16-3*plotsize1(2)-3, plotsize2], 'nextplot', 'add', 'ylim', [0 3], ...
    'xlim', [0 1], 'yscale', 'linear', 'yticklabel', [], 'ticklength', [0.02 0.1], 'fontsize', 8)

xlabel('Prob. density (1/s)')
binEdges = 0:0.01:3;

if sum(ind_correctL & obj.FP==1.5)
    PDF_L = ksdensity(obj.MT(ind_correctL & obj.FP==1.5), binEdges);
    plot(ha11, PDF_L, binEdges, 'color', Color.PortL, 'linewidth', 1.5)
end
if sum(ind_correctR & obj.FP==1.5)
    PDF_R = ksdensity(obj.MT(ind_correctR & obj.FP==1.5), binEdges);
    plot(ha11, PDF_R, binEdges, 'color', Color.PortR, 'linewidth', 1.5)
end

axis 'auto x'

%% Accuracy of each port
ha12 = axes;
set(ha12,'units', 'centimeters', 'position', [1.5, 16-3*plotsize1(2)-3, plotsize3], 'nextplot', 'add', 'ylim', [0 100], 'xlim', [0.5 10], ...
    'xtick', [1 2.5 3.5 5 6 7.5], 'xticklabel', {'L', 'R', '', '', '', ''}, 'fontsize', 8, 'ticklength', [0.01 0.1])
ylabel('Performance (%)');

line([1 2.5], 100*[obj.Performance.Correct(1) obj.Performance.Correct(2)], 'color', Color.Correct, 'linewidth', 1.2);
line([3.5 5], 100*[obj.Performance.Wrong(1) obj.Performance.Wrong(2)], 'color', Color.Wrong, 'linewidth', 1.2);
line([6 7.5], 100*[obj.Performance.Premature(1) obj.Performance.Premature(2)], 'color', Color.Premature, 'linewidth', 1.2);
line([8.5 7.5], 100*[obj.Performance.Late(1) obj.Performance.Late(2)], 'color', Color.Late, 'linewidth', 1.2);


ha121 = axes;
set(ha121,'units', 'centimeters', 'position', [3.2, 16-3*plotsize1(2)-3+2*plotsize3(2)/3, plotsize3/3], 'nextplot', 'add', 'ylim', [0.5 4.5], 'xlim', [.5 2], ...
    'fontsize', 8, 'ticklength', [0.01 0.1], 'xcolor', 'none', 'ycolor', 'none')
line([.5 1], [4 4], 'color', Color.Correct, 'linewidth', 1.2);
line([.5 1], [3 3], 'color', Color.Wrong, 'linewidth', 1.2);
line([.5 1], [2 2], 'color', Color.Premature, 'linewidth', 1.2);
text(1.2, 4, 'Correct', 'FontSize', 7)
text(1.2, 3, 'Wrong', 'FontSize', 7)
text(1.2, 2, 'Premature', 'FontSize', 7)

%% Reaction time to each port
ha13 = axes; % this is the legend
set(ha13,'units', 'centimeters', 'position', [1.5+plotsize3(1)+1, 16-3*plotsize1(2)-3, plotsize3], 'nextplot', 'add', 'ylim', [0 1], 'xlim', [0 3], ...
    'xtick', [1 2], 'xticklabel', {'Left', 'Right'}, 'fontsize', 8, 'ticklength', [0.01 0.1])
ylabel('Reaction time (s)');

if sum((ind_correctL | ind_correctR) & obj.FP==1.5)
violinplot(obj.RT(ind_correctL | ind_correctR), string(obj.PortCorrect(ind_correctL | ind_correctR)), ...
    'ViolinColor', [Color.PortL; Color.PortR], 'ViolinAlpha', 0.3, 'GroupOrder', {'1', '2'}, 'MarkerSize', 16);
end
set(ha13, 'xticklabel', {'Left', 'Right'});
box off
% scatter(ones(length(MTCorrect_PortL)), MTCorrect_PortL, 25, Color.PortL, choice_symbols{1},'Markerfacealpha', 0.8, 'linewidth', 1.05, 'XJitter', 'density', 'XJitterWidth', 0.5)
% scatter(2*ones(length(MTCorrect_PortR)), MTCorrect_PortR, 25, Color.PortR, choice_symbols{1}, 'Markerfacealpha', 0.8, 'linewidth', 1.05, 'XJitter', 'density', 'XJitterWidth', 0.5)

end

