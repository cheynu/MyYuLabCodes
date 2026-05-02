function f = plotHT_1KbSession(kbClass)
obj = kbClass;
% 
col_perf = [ 85 225   0
            255   0   0
            140 140 140]/255;
% blue     = [  0   0   1];
blue = [0 0.4470 0.7410];

plotsize1 = [6, 2.8];
plotsize2 = [2, 2.8];
xlevel = 1.5;
ylevel = 9.5-plotsize1(2)-1.2;

% add cue info for Dark press
indCue = obj.Cue;
while any(isnan(indCue))
    indCue(isnan(indCue)) = indCue(find(isnan(indCue))-1);
end

% plot
f = figure(obj.Fig1); clf(f);
set(f, 'unit', 'centimeters', 'position',[2 2 9.5 9.5], 'paperpositionmode', 'auto',...
    'color', 'w', 'render', 'painter');

hui_1 = uicontrol('Style', 'text', 'parent', obj.Fig1, 'units', 'normalized',...
    'position', [0.15 0.9 0.2 0.1],'string', [obj.Subject], 'fontweight', 'bold', ...
    'backgroundcolor', [1 1 1], 'HorizontalAlignment', 'left' );

hui_2 = uicontrol('Style', 'text', 'parent', obj.Fig1, 'units', 'normalized',...
    'position', [0.35 0.9 0.4 0.1],'string', [obj.Session], 'fontweight', 'bold', ...
    'backgroundcolor', [1 1 1], 'HorizontalAlignment', 'left' );

hui_3 = uicontrol('Style', 'text', 'parent', obj.Fig1, 'units', 'normalized',...
    'position', [0.75 0.9 0.2 0.1],'string', [obj.Treatment], 'fontweight', 'bold', ...
    'backgroundcolor', [1 1 1], 'HorizontalAlignment', 'left' );


ha1 = axes('units', 'centimeters', 'position', [xlevel, ylevel, plotsize1], 'nextplot', 'add', ...
    'ylim', [0 3500], 'xlim', [0 obj.ReleaseTime(end)], 'yscale', 'linear');
xlabel('Time in session (sec)')
ylabel('Press duration (msec)')
title('Cued trials', 'fontsize', 7, 'FontWeight', 'bold');

line([0 obj.ReleaseTime(end)], [obj.MixedFP obj.MixedFP], 'color', [0.5 0.5 0.5], 'linestyle', ':', 'linewidth', 1)
text(obj.ReleaseTime(end)+100, obj.MixedFP, ['FP: ' num2str(obj.MixedFP)], ...
    'fontsize', 7, 'fontname', 'dejavu sans', 'FontWeight','bold')
% plot press times - Cued
line([obj.PressTime(indCue==1); obj.PressTime(indCue==1)], [0 250], 'color', blue)
ind_premature_presses_cued = (strcmp(obj.Outcome, 'Premature') & obj.Cue == 1);
scatter(obj.ReleaseTime(ind_premature_presses_cued), ...
    1000*(obj.ReleaseTime(ind_premature_presses_cued) - obj.PressTime(ind_premature_presses_cued)), ...
    28, col_perf(2, :), 'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','w');

ind_late_presses_cued = strcmp(obj.Outcome, 'Late') & obj.Cue == 1;
LateDur = 1000*(obj.ReleaseTime(ind_late_presses_cued) - obj.PressTime(ind_late_presses_cued));
LateDur(LateDur>3500) = 3499;
scatter(obj.ReleaseTime(ind_late_presses_cued), LateDur, ...
    28, col_perf(3, :),  'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','w');

ind_dark_presses_cued = strcmp(obj.Outcome, 'Dark') & indCue == 1;
scatter(obj.ReleaseTime(ind_dark_presses_cued), ...
    1000*(obj.ReleaseTime(ind_dark_presses_cued) - obj.PressTime(ind_dark_presses_cued)), ...
    18, 'k',  'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','w');

ind_good_presses_cued = strcmp(obj.Outcome, 'Correct') & obj.Cue == 1;
scatter(obj.ReleaseTime(ind_good_presses_cued), ...
    1000*(obj.ReleaseTime(ind_good_presses_cued) - obj.PressTime(ind_good_presses_cued)), ...
    28, col_perf(1, :), 'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','w');


ylevel2 = ylevel -plotsize1(2)-1.5;
ha2 = axes('units', 'centimeters', 'position', [xlevel, ylevel2, plotsize1], 'nextplot', 'add', ...
    'ylim', [0 3500], 'xlim', [0 obj.ReleaseTime(end)], 'yscale', 'linear');
xlabel('Time in session (sec)')
ylabel('Press duration (msec)')
title('Uncued trials', 'fontsize', 7, 'FontWeight', 'bold');

line([0 obj.ReleaseTime(end)], [obj.MixedFP obj.MixedFP], 'color', [0.5 0.5 0.5], 'linestyle', ':', 'linewidth', 1)
text(obj.ReleaseTime(end)+100, obj.MixedFP, ['FP: ' num2str(obj.MixedFP)], ...
    'fontsize', 7, 'fontname', 'dejavu sans', 'FontWeight','bold')
% plot press times - Uncued
line([obj.PressTime(indCue==0); obj.PressTime(indCue==0)], [0 250], 'color', blue)
ind_premature_presses_uncued = (strcmp(obj.Outcome, 'Premature') & obj.Cue == 0);
% scatter(obj.ReleaseTime(ind_premature_presses_uncued), ...
%     1000*(obj.ReleaseTime(ind_premature_presses_uncued) - obj.PressTime(ind_premature_presses_uncued)), ...
%     25, col_perf(2, :), 'o',  'Markerfacealpha', 0.8, 'linewidth', 1.05);
scatter(obj.ReleaseTime(ind_premature_presses_uncued), ...
    1000*(obj.ReleaseTime(ind_premature_presses_uncued) - obj.PressTime(ind_premature_presses_uncued)), ...
    28, col_perf(2, :), 'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','w');

ind_late_presses_uncued = strcmp(obj.Outcome, 'Late') & obj.Cue == 0;
LateDur = 1000*(obj.ReleaseTime(ind_late_presses_uncued) - obj.PressTime(ind_late_presses_uncued));
LateDur(LateDur>3500) = 3499;
% scatter(obj.ReleaseTime(ind_late_presses_uncued), LateDur, ...
%     25, col_perf(3, :), 'o', 'Markerfacealpha', 0.8, 'linewidth', 1.05);
scatter(obj.ReleaseTime(ind_late_presses_uncued), LateDur, ...
    28, col_perf(3, :), 'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','w');

ind_dark_presses_uncued = strcmp(obj.Outcome, 'Dark') & indCue == 0;
% scatter(obj.ReleaseTime(ind_dark_presses_uncued), ...
%     1000*(obj.ReleaseTime(ind_dark_presses_uncued) - obj.PressTime(ind_dark_presses_uncued)), ...
%     15, 'k', 'o', 'Markerfacealpha', 0.8, 'linewidth', 1.05);
scatter(obj.ReleaseTime(ind_dark_presses_uncued), ...
    1000*(obj.ReleaseTime(ind_dark_presses_uncued) - obj.PressTime(ind_dark_presses_uncued)), ...
    18, 'k', 'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','w');

ind_good_presses_uncued = strcmp(obj.Outcome, 'Correct') & obj.Cue == 0;
% scatter(obj.ReleaseTime(ind_good_presses_uncued), ...
%     1000*(obj.ReleaseTime(ind_good_presses_uncued) - obj.PressTime(ind_good_presses_uncued)), ...
%     25, col_perf(1, :), 'o', 'Markerfacealpha', 0.8, 'linewidth', 1.05);
scatter(obj.ReleaseTime(ind_good_presses_uncued), ...
    1000*(obj.ReleaseTime(ind_good_presses_uncued) - obj.PressTime(ind_good_presses_uncued)), ...
    28, col_perf(1, :), 'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','w');

% Legend
xlevel2 = xlevel + plotsize1(1) + 0.3;
hainfo = axes('units', 'centimeters', 'position', [xlevel2, ylevel, plotsize2], ...
    'xlim', [1.95 10], 'ylim', [0 9], 'nextplot', 'add');
plot(2, 8, 'o', 'linewidth', 1, 'color', col_perf(1, :),'markerfacecolor', col_perf(1, :));
text(3, 8, 'Correct', 'fontsize', 8);
plot(2, 7, 'o', 'linewidth', 1, 'color', col_perf(2, :),'markerfacecolor', col_perf(2, :));
text(3, 7, 'Premature', 'fontsize', 8);
plot(2, 6 , 'o', 'linewidth', 1,'color', col_perf(3, :),'markerfacecolor', col_perf(3, :));
text(3, 6, 'Late', 'fontsize', 8);
plot(2, 5, 'ko', 'linewidth', 1,'markerfacecolor', 'k');
text(3, 5, 'Dark', 'fontsize', 8);
axis off

savename = [obj.Subject,'_',obj.Date,'_',obj.Protocol];
print(f,'-dpng',savename);
saveas(f,savename,'fig');
end

