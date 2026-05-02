function plotAroundChemo(BClassArray,ChemoDates)
% BClassArray: 1xn cell, each cell contains one BClass
% ChemoDates
%   .SessionChemoPre    : 1xm cell, e.g. {'20230315','20230318'}
%   .SessionChemo       : 1xm cell, e.g. {'20230316','20230319'}
%   .SessionChemoPost   : 1xm cell, e.g. {'20230317','20230320'}

dates = unique([ChemoDates.SessionChemoPre,ChemoDates.SessionChemo,ChemoDates.SessionChemoPost]);
BClassArrayChemoAround = BClassArray(cellfun(@(x)ismember(x.Date,dates),BClassArray,'UniformOutput',true));

obj = Behavior.SRT.BehaviorGroupClass(BClassArrayChemoAround); % this is the group obj. Note that I am using package mode to organize these data
%% Class
% obj.PlotPerformance;
% obj.Print;
% obj.Save;
%% Mini Version of PlotPerformance in BehaviorGroupClass
% parameters
set_matlab_default;
col_perf = [85 225 0
            255 0 0
            140 140 140]/255;
ShadeCol = [255, 212, 149]/255;

figsize = [11 11.5];
plotsize1 = [8,4];
maxDur = 3500/1000;
Lneg = -250; % for plotting response time
PressDurRange = [Lneg, max(obj.MixedFP)+2000];

% Create figure
rng(0);
fignum = randperm(1000,6);
h = figure(fignum(3));clf(h);
set(h, 'unit', 'centimeters', 'position',[2 2 figsize], 'paperpositionmode', 'auto', 'color', 'w')
% Create axes
ha(1) = axes;
xlevel = 2;
ylevel = figsize(2)-plotsize1(2)-1;
set(ha(1), 'units', 'centimeters', 'position', [xlevel, ylevel, plotsize1], 'nextplot', 'add', ...
    'ylim', [0 maxDur*1000], 'yscale', 'linear');
xlabel('Time in session (sec)')
ylabel('Press duration (msec)')

ha(2) = axes;
xlevel = xlevel;
ylevel2 =  ylevel - plotsize1(2) - 1;
set(ha(2),  'units', 'centimeters', 'position', [xlevel, ylevel2, plotsize1], 'nextplot', 'add', ...
    'ylim', [-5 100], 'xlim', [0 obj.ReleaseTime(end)], 'yscale', 'linear')
ylabel('Performance')
% xlabel('Time in session (sec)')
xlabel('Sessions');
% Plot
StartTime = 0;
sessTicks = [];
for i=1:obj.NumSessions
    iTrialsIndx                     = obj.SessionIndex == i;                          
    iPressTimes                     = obj.PressTime(iTrialsIndx);
    iReleaseTimes                   = obj.ReleaseTime(iTrialsIndx);
    iPressDurs                      = iReleaseTimes - iPressTimes;
    iPressDurs(iPressDurs>maxDur)   = maxDur;
    iOutcome                        = [obj.Outcome(iTrialsIndx)]';
    iStage                          = obj.Stage(iTrialsIndx);
    iFP                             = obj.FP(iTrialsIndx);
    indPerformanceSliding           = find(obj.PerformanceSlidingWindow.Session == i);

    set(ha(1), 'ylim', PressDurRange, 'xlim', [0 iReleaseTimes(end)+StartTime], 'yscale', 'linear');
    set(ha(2), 'ylim', [-5 100], 'xlim', [0 iReleaseTimes(end)+StartTime], 'yscale', 'linear');

    % draw shades
    if ismember(obj.Dates{i},ChemoDates.SessionChemo)
        axes(ha(1));
        plotshaded([StartTime StartTime + iReleaseTimes(end)], [PressDurRange(1) PressDurRange(1); PressDurRange(2) PressDurRange(2)], ShadeCol, 0.5);
        axes(ha(2))
        plotshaded([StartTime StartTime + iReleaseTimes(end)], [-5 -5; 100 100], ShadeCol, 0.5); 
    end
    % mark a new session
    line(ha(1), [StartTime StartTime], [0 maxDur*1000], ...
        'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1);
    line(ha(2), [StartTime StartTime], [-5 100], ...
        'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1);
    % plot press times
    line(ha(1), [iPressTimes; iPressTimes]+StartTime, [Lneg; 0], 'color', 'b'); % all press times
    % Plot premature responses
    for k=1:length(obj.MixedFP)
        symbolSize = 5+10*(k-1);
        ind_premature_presses = strcmp(iOutcome, 'Premature') & iFP == obj.MixedFP(k) & iStage == 1;
        scatter(ha(1),iPressTimes(ind_premature_presses)+StartTime, ...
            1000*iPressDurs(ind_premature_presses), ...
            25, col_perf(2, :), 'o','Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize, 'linewidth', 0.5);
    end
    % Plot late and correct responses
    for k=1:length(obj.MixedFP)
        symbolSize = 5+10*(k-1);
        ind_late_presses = strcmp(iOutcome, 'Late') & iFP == obj.MixedFP(k) & iStage == 1;
        scatter(ha(1), iPressTimes(ind_late_presses)+StartTime, ...
            1000*iPressDurs(ind_late_presses), ...
            25, col_perf(3, :), 'o','Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize, 'linewidth', 0.5);
        
        ind_correct_presses = strcmp(iOutcome, 'Correct') & iFP == obj.MixedFP(k) & iStage == 1;
        scatter(ha(1),iPressTimes(ind_correct_presses)+StartTime, ...
            1000*iPressDurs(ind_correct_presses), ...
            25, col_perf(1, :), 'o','Markerfacealpha', 0.8, 'linewidth', 1, 'SizeData', symbolSize, 'linewidth', 0.5);
    
    end
    % plot performance over time
    plot(ha(2),  obj.PerformanceSlidingWindow.TimeInSession(indPerformanceSliding) + StartTime, ...
        obj.PerformanceSlidingWindow.Correct(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(1, :), ...
        'marker', 'none', 'linestyle', '-', 'markersize', 4)
    plot(ha(2),  obj.PerformanceSlidingWindow.TimeInSession(indPerformanceSliding) + StartTime, ...
        obj.PerformanceSlidingWindow.Premature(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(2, :));
    plot(ha(2),  obj.PerformanceSlidingWindow.TimeInSession(indPerformanceSliding) + StartTime, ...
        obj.PerformanceSlidingWindow.Late(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(3, :));
    
    sessTicks = [sessTicks, StartTime+iReleaseTimes(end)./2];
    StartTime = StartTime + iReleaseTimes(end);
end
set(ha(2),'xtick',sessTicks,'xticklabel',dates);

hui_1 = uicontrol('Style', 'text', 'parent', h, 'units', 'normalized', 'position', [0.1 0.965 0.3 0.03],...
    'string',  ['Subject: ' obj.Subject{1}], 'fontweight', 'bold', ...
    'backgroundcolor', [1 1 1], 'HorizontalAlignment', 'left' , 'fontname', 'dejavu sans' );

hui_2 = uicontrol('Style', 'text', 'parent', h, 'units', 'normalized', 'position', [0.4 0.965 0.5 0.03],...
    'string', ['Protocol: ' obj.Protocols{1}], 'fontweight', 'bold', ...
    'backgroundcolor', [1 1 1], 'HorizontalAlignment', 'left' , 'fontname', 'dejavu sans');
 
savename = ['Fig3_1_PerformanceAroundChemo_',upper(obj.Subject{1})];
saveas(h, savename, 'fig');
print(h,'-dpng',savename);

end