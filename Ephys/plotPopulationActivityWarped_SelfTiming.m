function plotPopulationActivityWarped_SelfTiming(r,opts)
%% Plot population PSTH of SelfTiming task (only correct uncued trials)
% Revised from Yue Huang, 2025.1.3 Yu Chen
arguments
    r
    opts.t_pre = -2000 % ms
    opts.t_press = 0 % ms
    opts.t_post_reward = 2000 % ms
    opts.gaussian_kernel = 50 % ms
    opts.FP = [] % ms
    opts.UnitsFilter {mustBeMember(opts.UnitsFilter,["All","Single","Multi"])} = "All"
    opts.SaveInterVars = true
    opts.FigSavePath = 'Fig'
    opts.PlotFromInterVars = false
end
t_pre = opts.t_pre;
t_press = opts.t_press;
t_post_reward = opts.t_post_reward;
gaussian_kernel = opts.gaussian_kernel;
if isempty(opts.FP)
    FP = r.BehaviorClass.MixedFP;
else
    FP = opts.FP;
end
switch opts.UnitsFilter
    case "All"
        unitFilter = [];
    case "Single"
        unitFilter = 1;
    case "Multi"
        unitFilter = 2;
end
if isempty(unitFilter)
    units_of_interest = 1:size(r.Units.SpikeNotes,1);
else
    units_of_interest = find(r.Units.SpikeNotes(:,3)==unitFilter);
end
units_of_interest_ch = r.Units.SpikeNotes(units_of_interest,1:3);
ifSaveInterVars = opts.SaveInterVars;
pathFig = opts.FigSavePath;
ifReProcess = ~opts.PlotFromInterVars;

if ifReProcess
%% Get median HoldTime and MovementTime
[HD_median, MT_median] = get_HD_MT(r, units_of_interest, false);
HD_median = median(HD_median);
MT_median = median(MT_median);

t_release = t_press + HD_median;
t_reward = t_release + MT_median;
t_post = t_reward + t_post_reward;
%% Load warped data
[average_spikes_uncued, medianRT, medianMT, spike_counts_warped_uncued, raster_info_uncued] = get_warped_spikes(...
    r,...
    units_of_interest,...
    t_pre,...
    t_press,...
    t_release,...
    t_reward,...
    t_post,...
    'gaussian_kernel',gaussian_kernel,...
    'onlyFirstSession', false,...
    'Channel_Number', false,...
    'Foreperiod', FP);

peth_press_uncued = average_spikes_uncued;
spike_counts_warped_uncued_all = {};
waveforms = {};
unit_info = {};
for j=1:length(units_of_interest)
    spike_counts_warped_uncued_all{end+1} = squeeze(spike_counts_warped_uncued(:,:,j));
    idx_unit = units_of_interest(j);
    waveforms{end+1} = r.Units.SpikeTimes(idx_unit).wave;
    
    unit_info_this = struct();
    unit_info_this.Unit = idx_unit;
    unit_info_this.RatName = r.Meta(1).Subject;
    unit_info_this.Session = datestr(r.Meta(1).DateTime, 'yyyymmdd');
    unit_info_this.SpikeTimes = raster_info_uncued.SpikeTimes{j};
    unit_info_this.PressTimesUncued = raster_info_uncued.PressTimes;
    unit_info_this.ReleaseTimesUncued = raster_info_uncued.ReleaseTimes;
    unit_info_this.RewardTimesUncued = raster_info_uncued.RewardTimes;
    unit_info_this.SameOtherNeurons = '';
    unit_info_this.MedianRT = medianRT;
    unit_info_this.MedianMT = medianMT;
    
    unit_info{end+1} = unit_info_this;
end
disp(['Successfully loaded ', num2str(size(average_spikes_uncued, 2)), ' Units!']);
%% Process and save warped data
% sort by FP = 1500
[~, max_idx_uncued] = max(peth_press_uncued);
[~, sort_idx_uncued] = sort(max_idx_uncued);

% get normalizing parameters
min_peth = min(peth_press_uncued);
max_peth = max(peth_press_uncued);
mean_peth = mean(peth_press_uncued);
std_peth = std(peth_press_uncued);

% get organized
data_all_uncued = peth_press_uncued(:,sort_idx_uncued);
t_all_uncued = t_pre:t_post;
unit_info_sorted = unit_info(sort_idx_uncued);
waveforms_sorted = waveforms(sort_idx_uncued);
spike_counts_warped_all_sorted = spike_counts_warped_uncued_all(sort_idx_uncued);

% make xlsx file for sorted unit info
filename = ['PopulationDataWarped_', r.Meta(1).Subject,'_', datestr(r.Meta(1).DateTime, 'yyyymmdd')];
excel_filename = [filename, '.xlsx'];
fprintf('Writing to %s...\n', excel_filename);
    

SortIndex = {};
RatName = {};
Session = {};
Unit = {};
Chs = {};
Chs_unit = {};
Unit_qual = {};
for k = 1:length(unit_info_sorted)
    SortIndex{k} = k;
    RatName{k} = unit_info_sorted{k}.RatName;
    Session{k} = unit_info_sorted{k}.Session;
    Unit{k} = unit_info_sorted{k}.Unit;
    Chs{k} = units_of_interest_ch(Unit{k},1);
    Chs_unit{k} = units_of_interest_ch(Unit{k},2);
    Unit_qual{k} = units_of_interest_ch(Unit{k},3);
end

data_excel = table(SortIndex', RatName', Session', Unit', Chs', Chs_unit', Unit_qual',....
    'VariableNames', {'SortIndex', 'RatName','Session', 'Unit_Sorted', 'Chs', 'Ch_Units', 'Unit_Quality_Num'});
writetable(data_excel, excel_filename);

if ifSaveInterVars
    save([filename '.mat'],...
        't_pre', 't_press', 't_release', 't_reward', 't_post', ...
        'gaussian_kernel',...
        'min_peth', 'max_peth', 'std_peth', 'mean_peth',...
        'data_all_uncued', 't_all_uncued', 'unit_info_sorted', ...
        'waveforms', 'waveforms_sorted', 'spike_counts_warped_all_sorted',...
        'sort_idx_uncued','peth_press_uncued');
end

else % No RePlot
    dataWarped = dir('PopulationDataWarped*.mat');
    load(dataWarped.name);
end

%% Plot
figname = ['PopulationActivityWarped_', r.Meta(1).Subject,'_', datestr(r.Meta(1).DateTime, 'yyyymmdd')];

fig = EasyPlot.figure();
ax_colormap_uncued = EasyPlot.axes(fig,...
    'Width', 4,...
    'Height', 5.5,...
    'MarginLeft', 1,...
    'MarginRight', 1,...
    'MarginBottom', 0.7,...
    'MarginTop', 1,...
    'fontSize', 7,...
    'YDir', 'reverse');

t_plot_uncued = t_all_uncued;

% colormap
data_zscore = (data_all_uncued - mean_peth(sort_idx_uncued))./std_peth(sort_idx_uncued);
imagesc(ax_colormap_uncued, data_zscore', 'XData', t_plot_uncued/1000);


xline(ax_colormap_uncued, t_press/1000, 'k:', 'LineWidth', 2);
% xline(ax_colormap_uncued, (t_trigger-750)/1000, 'k:', 'LineWidth', 2);
xline(ax_colormap_uncued, t_release/1000, 'k:', 'LineWidth', 2);
xline(ax_colormap_uncued, t_reward/1000, 'k:', 'LineWidth', 2);

EasyPlot.setXLim(ax_colormap_uncued, [t_pre, t_post]/1000);
EasyPlot.setYLim(ax_colormap_uncued, [0.5, size(data_all_uncued, 2)+0.5]);
EasyPlot.colormap(ax_colormap_uncued, EasyPlot.ColorMap.Diverging.seismic, 'zeroCenter', 'on');
EasyPlot.colorbar(ax_colormap_uncued,...
    'Height', 2,...
    'Width', 0.2,...
    'label', 'Firing rate (z score)',...
    'fontSize', 6,...
    'MarginRight', 1);

xlabel(ax_colormap_uncued, 'Time since press (s, warped)');
ylabel(ax_colormap_uncued, 'Units');
% EasyPlot.setYTicksAndLabels(ax_colormap_long, ax_colormap_long.YTick, []);

ylim_range = range(ax_colormap_uncued.YLim);
y_pos = ax_colormap_uncued.YLim(1)-ylim_range*0.02;
text(ax_colormap_uncued, t_press/1000, y_pos, 'Press', 'Rotation', 45, 'FontSize', 7);
text(ax_colormap_uncued, t_release/1000, y_pos, 'Release', 'Rotation', 45, 'FontSize', 7);
text(ax_colormap_uncued, t_reward/1000, y_pos, 'Poke', 'Rotation', 45, 'FontSize', 7);
text(ax_colormap_uncued, t_release/1000, ax_colormap_uncued.YLim(1)-ylim_range*0.18,...
    [r.Meta(1).Subject,' ', datestr(r.Meta(1).DateTime, 'yyyymmdd'),' (Correct & Uncued)'], 'FontSize', 8, 'HorizontalAlignment', 'center');

EasyPlot.cropFigure(fig);
EasyPlot.exportFigure(fig, fullfile(pathFig,figname));
EasyPlot.exportFigure(fig, fullfile(pathFig,figname), 'type', 'eps');
EasyPlot.exportFigure(fig, fullfile(pathFig,figname), 'type', 'pdf');
end