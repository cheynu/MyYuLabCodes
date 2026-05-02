function PopOutWarpedT = VisualizePopSDFWarped(sdfFolder, sdfTable, opts)
% Plot Warped Population PSTH of one session (fixed single rt_median & retrieval_median)
%% Initiation
arguments
    sdfFolder % the path containing sdf files and sdf table
    sdfTable = table
    opts.figSaveFolder = ''
    % parameters
    opts.zrange = [-4 4]
    opts.frPeakThresold = [] % firing rate peak threshold (if filter units by fr)
    % notice edge problem
    opts.tRangePress = [-2000 500] % the time before & after press
    opts.tRangeTriggerReward = [-500 1000] % value(1) before release, value(2) after rewarded poke
end
figSaveFolder = opts.figSaveFolder;
zrange = opts.zrange;
frPeakThresold = opts.frPeakThresold;
tRangePress = opts.tRangePress; % for pooled data
tRangeTriggerReward = opts.tRangeTriggerReward;
tBeforePress = opts.tRangePress(1); % for the data in different FPs
tAfterPoke = opts.tRangeTriggerReward(2);
%% Some parameters

% press_col = [5 191 219]/255;
% trigger_col = [242 182 250]/255;
% release_col = [87, 108, 188]/255;
% reward_col = [164, 208, 164]/255;

press_col = [0 0 0];
trigger_col = [0 0 0];
release_col = [0 0 0];
reward_col = [0 0 0];
FP_cols = [255, 217, 90; 192, 127, 0; 76, 61, 61]/255;

fontsize_label = 9;
mycolormap = customcolormap(linspace(0,1,11), {'#68011d','#b5172f','#d75f4e','#f7a580','#fedbc9','#f5f9f3','#d5e2f0','#93c5dc','#4295c1','#2265ad','#062e61'});

cSoftNorm = 5;
normRange = [-0.5 0.5];

figsize_preset = [20 25];
ParamP = struct; % parameter plot
ParamP.map_height = 4;
ParamP.size_factor = 2.6;
ParamP.space = 0.2;
ParamP.xlevel_start = 1.25;
ParamP.ylevel_start = 2;
%% Extract fundamental parameters

% get the location of sdf files
sdfTableDir = dir(fullfile(sdfFolder,'sdfTable_*.csv'));
if isempty(sdfTable)
    if ~isempty(sdfTableDir)
        sdfTable = readtable(fullfile(sdfTableDir.folder,sdfTableDir.name));
    else
        errordlg('We need sdfTable');
    end
end
sdfList = sdfTable.cell_id; % keep the same order of sdfTable
warpedSDF = fullfile(sdfFolder, strcat('sdf_',sdfList, '.mat'));

n_unit_all = length(warpedSDF);

load(warpedSDF{1},'s'); % examples
% unit info
subject = s.subject;
session = s.session;

% % session info
MixedFPs = s.FPs;
nFP = length(MixedFPs);
trials_fp = nan(size(MixedFPs));

% pooled
rt_retrieval_median_ms = s.sdf.trigger.pooled.warped.rt_retrieval;

idxSDF_Press = find(s.sdf.press.pooled.time >= tRangePress(1)/1000 & ...
    s.sdf.press.pooled.time <= tRangePress(2)/1000);
t_sdf_press = s.sdf.press.pooled.time(idxSDF_Press).*1000;
idxSDF_trigger = find(s.sdf.trigger.pooled.warped.time >= tRangeTriggerReward(1)/1000 & ...
    s.sdf.trigger.pooled.warped.time <= (sum(rt_retrieval_median_ms)+tRangeTriggerReward(2))/1000);
t_sdf_trigger = s.sdf.trigger.pooled.warped.time(idxSDF_trigger).*1000;

% not pooled (FPs)
rt_median_ms_fp = nan(1,nFP);
retrieval_median_ms_fp = nan(1,nFP);
pre_press_ms_fp = nan(1,nFP);
post_poke_ms_fp = nan(1,nFP);

idxSDF_FP = cell(1,nFP);
t_sdf_fp = cell(1,nFP);
tRange_FP = cell(1,nFP);
for ifp=1:nFP
    trials_fp(ifp) = size(s.sdf.warped(ifp).sdf_all,1);

    rt_median_ms_fp(ifp) = s.sdf.warped(ifp).rt_median_ms;
    retrieval_median_ms_fp(ifp) = s.sdf.warped(ifp).retrieval_median_ms;
    pre_press_ms_fp(ifp) = min(s.sdf.warped(ifp).pre_press_ms,tBeforePress);
    post_poke_ms_fp(ifp) = min(s.sdf.warped(ifp).post_poke_ms,tAfterPoke);
    
    tRange = [pre_press_ms_fp(ifp),...
        MixedFPs(ifp)+rt_median_ms_fp(ifp)+retrieval_median_ms_fp(ifp)+post_poke_ms_fp(ifp)];
    tRange_FP{ifp} = tRange;
    idxSDF_FP{ifp} = find(s.sdf.warped(ifp).t_sdf>=tRange(1) & s.sdf.warped(ifp).t_sdf<=tRange(2));
    t_sdf_fp{ifp} = s.sdf.warped(ifp).t_sdf(idxSDF_FP{ifp});
end
%% Extract all units' sdf

sdf_mean_press = []; % row: unit, column: time point
sdf_mean_trigger = [];
sdf_mean_fp = cell(1,nFP);

ticExtract = tic;
for iUnit = 1:n_unit_all
    clear s;
    load(warpedSDF{iUnit},'s');
    
    sdf_mean_press(iUnit,:) = s.sdf.press.pooled.mean(idxSDF_Press);
    sdf_mean_trigger(iUnit,:) = s.sdf.trigger.pooled.warped.mean(idxSDF_trigger);

    for ifp=1:nFP
        sdf_mean_fp{ifp}(iUnit,:) = s.sdf.warped(ifp).sdf_mean(idxSDF_FP{ifp});
    end
end
fprintf('Time of extracting warped sdf: %.0f seconds\n\n',toc(ticExtract));

%% Process (pooled)

% % sort units (according to pooled data)
sdf_mean_pool = [sdf_mean_press sdf_mean_trigger];
idx_press = 1:size(sdf_mean_press,2);
idx_trigger = 1+size(sdf_mean_press,2):size(sdf_mean_pool,2);

frPeak = max(sdf_mean_pool, [], 2);
if ~isempty(frPeakThresold)
    isQualified = frPeak>=frPeakThresold;
else
    isQualified = true(size(frPeak));
end

% soft normalization & posi-/nega- modulation grouping
sdf_mean_pool_norm = zeros(size(sdf_mean_pool));
for i=1:size(sdf_mean_pool,1)
    sdf_mean_pool_norm(i,:) = cal_soft_norm(sdf_mean_pool(i,:),cSoftNorm);
end
max_vals = max(sdf_mean_pool_norm,[],2);
min_vals = min(sdf_mean_pool_norm,[],2);
posUnits = find(abs(max_vals) >= abs(min_vals));
negUnits = find(abs(max_vals) <  abs(min_vals));

sdf_mean_pool_norm_pos = sdf_mean_pool_norm(posUnits,:);
sdf_mean_pool_norm_pos_smooth = movmean(sdf_mean_pool_norm_pos, 3, 2);
[~,tPeak] = max(sdf_mean_pool_norm_pos_smooth,[],2);
[~, idxSort_pos] = sort(tPeak, 1, 'ascend');
n_unit_all_pos = length(idxSort_pos);

sdf_mean_pool_norm_neg = sdf_mean_pool_norm(negUnits,:);
sdf_mean_pool_norm_neg_smooth = movmean(sdf_mean_pool_norm_neg, 3, 2);
[~,tValley] = min(sdf_mean_pool_norm_neg_smooth,[],2);
[~, idxSort_neg] = sort(tValley, 1, 'ascend');
n_unit_all_neg = length(idxSort_neg);

idxPosSorted = posUnits(idxSort_pos);
idxNegSorted = negUnits(idxSort_neg);

% range norm
sdf_mean_pool_rangenorm = normalize(sdf_mean_pool,2,'range');
sdf_mean_pool_rangenorm_pos = sdf_mean_pool_rangenorm(posUnits,:);
sdf_mean_pool_rangenorm_neg = sdf_mean_pool_rangenorm(negUnits,:);

% zscore
sdf_mean_pool_zscore = zscore(sdf_mean_pool,0,2);
sdf_mean_pool_zscore_pos = sdf_mean_pool_zscore(posUnits,:);
sdf_mean_pool_zscore_neg = sdf_mean_pool_zscore(negUnits,:);

% qualified units
idxQualified = find(isQualified);
isQualified_pos = ismember(posUnits, idxQualified); % index used in posUnits
isQualified_neg = ismember(negUnits, idxQualified);
idxQualifiedPos = posUnits(isQualified_pos);
idxQualifiedNeg = negUnits(isQualified_neg);
n_unit_qualified = sum(isQualified);
n_unit_qualified_pos = sum(isQualified_pos);
n_unit_qualified_neg = sum(isQualified_neg);

% % collect data to plot

% pooled (soft norm.)
sdf_mean_press_sorted_norm_pos = sdf_mean_pool_norm_pos(idxSort_pos,idx_press);
sdf_mean_press_sorted_norm_neg = sdf_mean_pool_norm_neg(idxSort_neg,idx_press);
sdf_mean_trigger_sorted_norm_pos = sdf_mean_pool_norm_pos(idxSort_pos,idx_trigger);
sdf_mean_trigger_sorted_norm_neg = sdf_mean_pool_norm_neg(idxSort_neg,idx_trigger);

% pooled (range norm.)
sdf_mean_press_sorted_rangenorm_pos = sdf_mean_pool_rangenorm_pos(idxSort_pos,idx_press);
sdf_mean_press_sorted_rangenorm_neg = sdf_mean_pool_rangenorm_neg(idxSort_neg,idx_press);
sdf_mean_trigger_sorted_rangenorm_pos = sdf_mean_pool_rangenorm_pos(idxSort_pos,idx_trigger);
sdf_mean_trigger_sorted_rangenorm_neg = sdf_mean_pool_rangenorm_neg(idxSort_neg,idx_trigger);

% pooled (zscore)
sdf_mean_press_sorted_zscore_pos = sdf_mean_pool_zscore_pos(idxSort_pos,idx_press);
sdf_mean_press_sorted_zscore_neg = sdf_mean_pool_zscore_neg(idxSort_neg,idx_press);
sdf_mean_trigger_sorted_zscore_pos = sdf_mean_pool_zscore_pos(idxSort_pos,idx_trigger);
sdf_mean_trigger_sorted_zscore_neg = sdf_mean_pool_zscore_neg(idxSort_neg,idx_trigger);

%% Process (FP)
sdf_mean_fp_norm = cell(size(sdf_mean_fp));
sdf_mean_fp_sorted_norm_pos = cell(size(sdf_mean_fp));
sdf_mean_fp_sorted_norm_neg = cell(size(sdf_mean_fp));
sdf_mean_fp_rangenorm = cell(size(sdf_mean_fp));
sdf_mean_fp_sorted_rangenorm_pos = cell(size(sdf_mean_fp));
sdf_mean_fp_sorted_rangenorm_neg = cell(size(sdf_mean_fp));
sdf_mean_fp_zscore = cell(size(sdf_mean_fp));
sdf_mean_fp_sorted_zscore_pos = cell(size(sdf_mean_fp));
sdf_mean_fp_sorted_zscore_neg = cell(size(sdf_mean_fp));
for ifp=1:nFP
    % fp (soft norm.)
    sdf_mean_fp_norm{ifp} = zeros(size(sdf_mean_fp{ifp}));
    for i=1:size(sdf_mean_fp{ifp},1)
        sdf_mean_fp_norm{ifp}(i,:) = cal_soft_norm(sdf_mean_fp{ifp}(i,:),cSoftNorm);
    end
    sdf_mean_fp_sorted_norm_pos{ifp} = sdf_mean_fp_norm{ifp}(posUnits(idxSort_pos),:);
    sdf_mean_fp_sorted_norm_neg{ifp} = sdf_mean_fp_norm{ifp}(negUnits(idxSort_neg),:);
    
    % fp (range norm.)
    sdf_mean_fp_rangenorm{ifp} = normalize(sdf_mean_fp{ifp},2,'range');
    sdf_mean_fp_sorted_rangenorm_pos{ifp} = sdf_mean_fp_rangenorm{ifp}(posUnits(idxSort_pos),:);
    sdf_mean_fp_sorted_rangenorm_neg{ifp} = sdf_mean_fp_rangenorm{ifp}(negUnits(idxSort_neg),:);

    % fp (zscore)
    sdf_mean_fp_zscore{ifp} = zscore(sdf_mean_fp{ifp},0,2);
    sdf_mean_fp_sorted_zscore_pos{ifp} = sdf_mean_fp_zscore{ifp}(posUnits(idxSort_pos),:);
    sdf_mean_fp_sorted_zscore_neg{ifp} = sdf_mean_fp_zscore{ifp}(negUnits(idxSort_neg),:);
end
%% Plot
setDefaultStyles;

hf = figure(48); clf(hf);
set(hf, 'unit', 'centimeters', 'position', [2 2 figsize_preset], 'paperpositionmode', 'auto' ,'color', 'w')

%%%%%%%%%% Plot Pooled %%%%%%%%%%
xlevel_start = ParamP.xlevel_start;
ylevel_start = ParamP.ylevel_start;
colormaps_used = {'parula',mycolormap};
titles = {'A. Normalized activity ([0-1])',['B. z-scored activity [' num2str(zrange(1)) '-' num2str(zrange(2)) ']']};
bar_labels = {'normalize','z score'};
% cRange = {normRange, zrange};
% data_neg_press = {sdf_mean_press_sorted_norm_neg, sdf_mean_press_sorted_zscore_neg};
% data_pos_press = {sdf_mean_press_sorted_norm_pos, sdf_mean_press_sorted_zscore_pos};
% data_neg_trigger = {sdf_mean_trigger_sorted_norm_neg, sdf_mean_trigger_sorted_zscore_neg};
% data_pos_trigger = {sdf_mean_trigger_sorted_norm_pos, sdf_mean_trigger_sorted_zscore_pos};
cRange = {[0 1], zrange};
data_neg_press = {sdf_mean_press_sorted_rangenorm_neg(isQualified_neg,:), sdf_mean_press_sorted_zscore_neg(isQualified_neg,:)};
data_pos_press = {sdf_mean_press_sorted_rangenorm_pos(isQualified_pos,:), sdf_mean_press_sorted_zscore_pos(isQualified_pos,:)};
data_neg_trigger = {sdf_mean_trigger_sorted_rangenorm_neg(isQualified_neg,:), sdf_mean_trigger_sorted_zscore_neg(isQualified_neg,:)};
data_pos_trigger = {sdf_mean_trigger_sorted_rangenorm_pos(isQualified_pos,:), sdf_mean_trigger_sorted_zscore_pos(isQualified_pos,:)};

for i=1:2
% % Pooled Press (norm)
tRange = tRangePress;
WidthPress = ParamP.size_factor*diff(tRange)/2000;
Height_pos = ParamP.map_height*n_unit_qualified_pos/n_unit_qualified;
Height_neg = ParamP.map_height*n_unit_qualified_neg/n_unit_qualified;

% negative 
ha_pool_press_neg = axes('unit', 'centimeters', 'position',...
    [xlevel_start ylevel_start WidthPress Height_neg], 'nextplot', 'add',...
    'xlim', tRange, 'xtick', -3500:500:2000,'ytick',0:50:n_unit_qualified,...
    'ylim', [0.5 n_unit_qualified_neg+0.5], 'ydir', 'reverse', 'XTickLabelRotation', 90);
% ylabel('Units')

text(tRange(1),n_unit_qualified_neg*(1+1/Height_neg),'Time from press (ms)',...
    'HorizontalAlignment','left','VerticalAlignment','top',...
    'FontSize',fontsize_label);

h_img_neg = imagesc(t_sdf_press, 1:n_unit_qualified_neg, data_neg_press{i}, cRange{i});
colormap(ha_pool_press_neg,colormaps_used{i});
yrange = [0.5 n_unit_qualified_neg+0.5];
line([0 0], yrange, 'Color', press_col, 'linestyle', ':', 'linewidth', 1.5);

% positive
ha_pool_press_pos = axes('unit', 'centimeters', 'position',...
    [xlevel_start ylevel_start+Height_neg+ParamP.space WidthPress Height_pos], 'nextplot', 'add',...
    'xlim', tRange, 'xtick', -3500:500:2000,'ytick',0:50:n_unit_qualified,...
    'ylim', [0.5 n_unit_qualified_pos+0.5], 'ydir', 'reverse', 'XTickLabelRotation', 90,...
    'xticklabel',[]);
ha_pool_press_pos.XAxis.Visible = 'off';
if i==1
    ylabel('Units')
end
text_trialsinfo = sprintf('Ntrials=%d',sum(trials_fp));
title(text_trialsinfo);

h_img_pos = imagesc(t_sdf_press, 1:n_unit_qualified_pos, data_pos_press{i}, cRange{i});
colormap(ha_pool_press_pos,colormaps_used{i});
yrange = [0.5 n_unit_qualified_pos+0.5];
line([0 0], yrange, 'Color', press_col, 'linestyle', ':', 'linewidth', 1.5);

% % Pooled Trigger (norm)
tRange = [tRangeTriggerReward(1) sum(rt_retrieval_median_ms)+tRangeTriggerReward(2)];
WidthTrigger = ParamP.size_factor*diff(tRange)/2000;
Height_pos = ParamP.map_height*n_unit_qualified_pos/n_unit_qualified;
Height_neg = ParamP.map_height*n_unit_qualified_neg/n_unit_qualified;

% negative 
ha_pool_trigger_neg = axes('unit', 'centimeters', 'position',...
    [xlevel_start+WidthPress+ParamP.space ylevel_start WidthTrigger Height_neg], 'nextplot', 'add',...
    'xlim', tRange, 'xtick', -3500:500:3500,'ytick',0:50:n_unit_qualified,...
    'ylim', [0.5 n_unit_qualified_neg+0.5], 'ydir', 'reverse', 'XTickLabelRotation', 90);
ha_pool_trigger_neg.YAxis.Visible = 'off';
text(tRange(1),n_unit_qualified_neg*(1+1/Height_neg),'Time from trigger (ms)',...
    'HorizontalAlignment','left','VerticalAlignment','top',...
    'FontSize',fontsize_label);

h_img_neg = imagesc(t_sdf_trigger, 1:n_unit_qualified_neg, data_neg_trigger{i}, cRange{i});

colormap(ha_pool_trigger_neg,colormaps_used{i});
yrange = [0.5 n_unit_qualified_neg+0.5];
line([0 0], yrange, 'Color', trigger_col, 'linestyle', ':', 'linewidth', 1.5);
line(repmat(rt_retrieval_median_ms(1),[1 2]), yrange, 'Color', release_col, 'linestyle', ':', 'linewidth', 1.5);
line(repmat(sum(rt_retrieval_median_ms),[1 2]), yrange, 'Color', reward_col, 'linestyle', ':', 'linewidth', 1.5);

% positive
ha_pool_trigger_pos = axes('unit', 'centimeters', 'position',...
    [xlevel_start+WidthPress+ParamP.space ylevel_start+Height_neg+ParamP.space WidthTrigger Height_pos], 'nextplot', 'add',...
    'xlim', tRange, 'xtick', -3500:500:2000,'ytick',0:50:n_unit_qualified,...
    'ylim', [0.5 n_unit_qualified_pos+0.5], 'ydir', 'reverse', 'XTickLabelRotation', 90,...
    'xticklabel',[]);
ha_pool_trigger_pos.YAxis.Visible = 'off';
ha_pool_trigger_pos.XAxis.Visible = 'off';

h_img_pos = imagesc(t_sdf_trigger, 1:n_unit_qualified_pos, data_pos_trigger{i}, cRange{i});
colormap(ha_pool_trigger_pos,colormaps_used{i});
yrange = [0.5 n_unit_qualified_pos+0.5];
line([0 0], yrange, 'Color', trigger_col, 'linestyle', ':', 'linewidth', 1.5);
line(repmat(rt_retrieval_median_ms(1),[1 2]), yrange, 'Color', release_col, 'linestyle', ':', 'linewidth', 1.5);
line(repmat(sum(rt_retrieval_median_ms),[1 2]), yrange, 'Color', reward_col, 'linestyle', ':', 'linewidth', 1.5);

% % color bar of pooled
% hbar1 = colorbar('Eastoutside');
% set(hbar1,'units','centimeters','position',...
%     [xlevel_start+WidthPress+ParamP.space*2+WidthTrigger ylevel_start 0.2 2],...
%     'FontSize',fontsize_label);
% hbar1.Label.String = bar_labels{i};

% big title
annotation('textbox', ...
    'Units', 'centimeters', ...
    'Position', [xlevel_start ylevel_start+Height_neg+Height_pos+ParamP.space+0.3 7 0.7], ...
    'String', titles{i}, ...
    'FontWeight', 'bold', ...
    'FontSize', 10, ...
    'BackgroundColor', [1 1 1], ...
    'VerticalAlignment', 'bottom',...
    'HorizontalAlignment', 'left', ...
    'EdgeColor', 'none');

% update params
xlevel_start = xlevel_start+WidthPress+WidthTrigger+ParamP.space + 4;
end % norm & zscore
WidthAll = WidthPress+ParamP.space+WidthTrigger;


%%%%%%%%%%%%%% Plot in different FPs %%%%%%%%%%%%%%
ylevel_start = ylevel_start+Height_neg+Height_pos+ParamP.space*2+2.5;
colormaps_used = {'parula',mycolormap};
titles = {'A. Normalized activity ([0-1])',['B. z-scored activity [' num2str(zrange(1)) '-' num2str(zrange(2)) ']']};
bar_labels = {'normalize','z score'};
tRangeLen = cellfun(@(x)diff(x),tRange_FP,'UniformOutput',true);

cRange = {[0 1], zrange};
data_neg = {sdf_mean_fp_sorted_rangenorm_neg, sdf_mean_fp_sorted_zscore_neg};
data_pos = {sdf_mean_fp_sorted_rangenorm_pos, sdf_mean_fp_sorted_zscore_pos};

revFP = fliplr(1:nFP);
for idxFP=1:nFP
ifp = revFP(idxFP);
xlevel_start = ParamP.xlevel_start; 

tRange = tRange_FP{ifp};
WidthFP = WidthAll*diff(tRange)/max(tRangeLen);
Height_pos = ParamP.map_height*n_unit_qualified_pos/n_unit_qualified;
Height_neg = ParamP.map_height*n_unit_qualified_neg/n_unit_qualified;

for i=1:2 % normalize/zscore
% negative 
ha_pool_press_neg = axes('unit', 'centimeters', 'position',...
    [xlevel_start ylevel_start WidthFP Height_neg], 'nextplot', 'add',...
    'xlim', tRange, 'xtick', -3500:500:6000,'ytick',0:50:n_unit_qualified,...
    'ylim', [0.5 n_unit_qualified_neg+0.5], 'ydir', 'reverse', 'XTickLabelRotation', 90);
if idxFP==1
    text(tRange(1),n_unit_qualified_neg*(1+1/Height_neg),'Time from press (ms)',...
        'HorizontalAlignment','left','VerticalAlignment','top',...
        'FontSize',fontsize_label);
else
    set(ha_pool_press_neg,'XTickLabel',{});
end

h_img_neg = imagesc(t_sdf_fp{ifp}, 1:n_unit_qualified_neg, data_neg{i}{ifp}(isQualified_neg,:), cRange{i});
colormap(ha_pool_press_neg, colormaps_used{i});
yrange = [0.5 n_unit_qualified_neg+0.5];
line([0 0], yrange, 'Color', press_col, 'linestyle', ':', 'linewidth', 1.5);
line(repmat(MixedFPs(ifp),[1 2]),...
    yrange, 'Color', FP_cols(ifp,:), 'linestyle', ':', 'linewidth', 1.5);
line(repmat(MixedFPs(ifp)+rt_median_ms_fp(ifp),[1 2]),...
    yrange, 'Color', release_col, 'linestyle', ':', 'linewidth', 1.5);
line(repmat(MixedFPs(ifp)+rt_median_ms_fp(ifp)+retrieval_median_ms_fp(ifp),[1 2]), ...
    yrange, 'Color', reward_col, 'linestyle', ':', 'linewidth', 1.5);
if idxFP==1 && i==1
    text(t_sdf_fp{ifp}(end)*11/10, n_unit_qualified_neg/2, sprintf('Nunits=%d',n_unit_qualified_neg),...
        'FontSize',fontsize_label,'HorizontalAlignment','left','VerticalAlignment','middle');
end

% positive
ha_pool_press_pos = axes('unit', 'centimeters', 'position',...
    [xlevel_start ylevel_start+Height_neg+ParamP.space WidthFP Height_pos], 'nextplot', 'add',...
    'xlim', tRange, 'xtick', -3500:500:6000,'ytick',0:50:n_unit_qualified,...
    'ylim', [0.5 n_unit_qualified_pos+0.5], 'ydir', 'reverse', 'XTickLabelRotation', 90,...
    'xticklabel',[]);
ha_pool_press_pos.XAxis.Visible = 'off';
if idxFP==1 && i==1
    ylabel('Units')
end
text_trialsinfo = sprintf('FP=%dms, Ntrials=%d',MixedFPs(ifp),trials_fp(ifp));
title(text_trialsinfo);

h_img_pos = imagesc(t_sdf_fp{ifp}, 1:n_unit_qualified_pos, data_pos{i}{ifp}(isQualified_pos,:), cRange{i});
colormap(ha_pool_press_pos,colormaps_used{i});
yrange = [0.5 n_unit_qualified_pos+0.5];
line([0 0], yrange, 'Color', press_col, 'linestyle', ':', 'linewidth', 1.5);
line(repmat(MixedFPs(ifp),[1 2]),...
    yrange, 'Color', FP_cols(ifp,:), 'linestyle', ':', 'linewidth', 1.5);
line(repmat(MixedFPs(ifp)+rt_median_ms_fp(ifp),[1 2]),...
    yrange, 'Color', release_col, 'linestyle', ':', 'linewidth', 1.5);
line(repmat(MixedFPs(ifp)+rt_median_ms_fp(ifp)+retrieval_median_ms_fp(ifp),[1 2]), ...
    yrange, 'Color', reward_col, 'linestyle', ':', 'linewidth', 1.5);
if idxFP==1 && i==1
    text(t_sdf_fp{ifp}(end)*11/10, n_unit_qualified_pos/2, sprintf('Nunits=%d',n_unit_qualified_pos),...
        'FontSize',fontsize_label,'HorizontalAlignment','left','VerticalAlignment','middle');
end

if idxFP==1
    % pass
elseif idxFP==nFP
    % color bar of FPs
    hbarFP = colorbar('Eastoutside');
    set(hbarFP,'units','centimeters','position',...
        [xlevel_start+WidthFP+ParamP.space ylevel_start 0.2 2],...
        'FontSize',fontsize_label);
    hbarFP.Label.String = bar_labels{i};
    
    % big title
    annotation('textbox', ...
        'Units', 'centimeters', ...
        'Position', [xlevel_start ylevel_start+Height_neg+Height_pos+ParamP.space+0.3 7 0.7], ...
        'String', titles{i}, ...
        'FontWeight', 'bold', ...
        'FontSize', 10, ...
        'BackgroundColor', [1 1 1], ...
        'VerticalAlignment', 'bottom',...
        'HorizontalAlignment', 'left', ...
        'EdgeColor', 'none');

end

% update params for normalized/zscore
xlevel_start = xlevel_start+WidthPress+WidthTrigger+ParamP.space + 4;
end 
% update params for FP
ylevel_start = ylevel_start+Height_neg+Height_pos+ParamP.space*2+0.4;
end
if isempty(frPeakThresold)
    titlename = sprintf('%s | %s', subject, strrep(session, '_', '-'));
else
    titlename = sprintf('%s | %s | FR Peak >= %.0f s^{-1}', subject, strrep(session, '_', '-'), frPeakThresold);
end
annotation('textbox', ...
    'Units', 'centimeters', ...
    'Position', [figsize_preset(1)/4 ylevel_start+0.5 figsize_preset(1)/2 1], ...
    'String', titlename, ...
    'FontWeight', 'bold', ...
    'FontSize', 12, ...
    'BackgroundColor', [1 1 1], ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'bottom',...
    'EdgeColor', 'none');

% % Re-adjust figure height
fig_height = ylevel_start + 2;
figsize = get(hf,'position');
figsize(4) = fig_height;
set(hf, 'position', figsize);

%% Table info
% modulation sign
ModulationSign = zeros(n_unit_all,1);
ModulationSign(posUnits) = 1; % Positive
ModulationSign(negUnits) = -1; % Negative

varNames = sdfTable.Properties.VariableNames;
if any(contains(varNames,'ModulationSign'))
    sdfTable.ModulationSign = ModulationSign;
else
    sdfTable = addvars(sdfTable,ModulationSign,'After','kcoords');
end

% firing rate peak
FR_Peak = frPeak;
if any(contains(varNames,'FR_Peak'))
    sdfTable.FR_Peak = FR_Peak;
else
    sdfTable = addvars(sdfTable,FR_Peak,'After','ModulationSign');
end

% qualified
Qualified = isQualified;
if any(contains(varNames,'Qualified'))
    sdfTable.Qualified = Qualified;
else
    sdfTable = addvars(sdfTable,Qualified,'After','FR_Peak');
end

% Sorted order
isQualifiedPosSorted = ismember(idxPosSorted, idxQualifiedPos);
isQualifiedNegSorted = ismember(idxNegSorted, idxQualifiedNeg);
idxQualifiedPosSorted = idxPosSorted(isQualifiedPosSorted);
idxQualifiedNegSorted = idxNegSorted(isQualifiedNegSorted);
idxUnqualifiedPosSorted = idxPosSorted(~isQualifiedPosSorted);
idxUnqualifiedNegSorted = idxNegSorted(~isQualifiedNegSorted);

sortedT_qualified_pos = sdfTable(idxQualifiedPosSorted,:);
sortedT_qualified_neg = sdfTable(idxQualifiedNegSorted,:);
sortedT_unqualified_pos = sdfTable(idxUnqualifiedPosSorted,:);
sortedT_unqualified_neg = sdfTable(idxUnqualifiedNegSorted,:);

PopOutWarpedT = [sortedT_qualified_pos; sortedT_qualified_neg; sortedT_unqualified_pos; sortedT_unqualified_neg];
%% Add event modulation info in figure

% process
p_events_var = varNames(contains(varNames, 'pval_'));
eventNames = extractAfter(p_events_var,'pval_');
n_event = length(p_events_var);

pT_pos = PopOutWarpedT(PopOutWarpedT.ModulationSign==1 & PopOutWarpedT.Qualified==1, p_events_var);
pT_neg = PopOutWarpedT(PopOutWarpedT.ModulationSign==-1 & PopOutWarpedT.Qualified==1, p_events_var);

pValEvents_pos = table2array(pT_pos);
pValEvents_neg = table2array(pT_neg);

unsigEvents_pos = pValEvents_pos > 0.05;
unsigEvents_neg = pValEvents_neg > 0.05;

unsigEvents = [unsigEvents_pos; unsigEvents_neg];
ratioEvents = sum(~unsigEvents,1)./size(unsigEvents,1);

% plot
xlevel_start = ParamP.xlevel_start+WidthPress+WidthTrigger+ParamP.space*2;
ylevel_start = ParamP.ylevel_start;
WidthEvent = 3;
HeightBar = 1;

xTickEvent = 1:n_event;

ha_event_modulation_neg = axes('unit', 'centimeters', 'position',...
    [xlevel_start ylevel_start WidthEvent Height_neg], 'nextplot', 'add',...
    'xlim', [0.5 n_event+0.5], 'xtick', xTickEvent,'ytick',[],...
    'ylim', [0.5 n_unit_qualified_neg+0.5], 'ydir', 'reverse', 'XTickLabelRotation', 90,...
    'XTickLabel',eventNames);
ha_event_modulation_neg.YAxis.Visible = 'off';

imagesc(xTickEvent, 1:n_unit_qualified_neg, unsigEvents_neg, [0 1]);
colormap(ha_event_modulation_neg, [0 0 0;1 1 1]);


ha_event_modulation_pos = axes('unit', 'centimeters', 'position',...
    [xlevel_start ylevel_start+Height_neg+ParamP.space WidthEvent Height_pos], 'nextplot', 'add',...
    'xlim', [0.5 n_event+0.5], 'xtick', [],'ytick',[],...
    'ylim', [0.5 n_unit_qualified_pos+0.5], 'ydir', 'reverse', 'XTickLabelRotation', 90);
ha_event_modulation_pos.XAxis.Visible = 'off';
ha_event_modulation_pos.YAxis.Visible = 'off';

imagesc(xTickEvent, 1:n_unit_qualified_pos, unsigEvents_pos, [0 1]);
colormap(ha_event_modulation_pos, [0.1 0.1 0.1;1 1 1]);

% bar
ha_event_bar = axes('unit', 'centimeters', 'position',...
    [xlevel_start ylevel_start+Height_neg+ParamP.space*2+Height_pos WidthEvent HeightBar], 'nextplot', 'add',...
    'xlim', [0.5 n_event+0.5], 'xtick', [],'ytick',[],...
    'ylim', [0 1], 'XTickLabel', []);
ha_event_bar.YAxis.Visible = 'off';

barLabels = strcat(string(round(ratioEvents,2).*100),'%');
hb = bar(xTickEvent,ratioEvents,'k');
xtips = hb.XEndPoints;
ytips = hb.YEndPoints;
% labels = string(hb.YData);
text(xtips,ytips,barLabels,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',7);
%% Save figures & Tables
if ~isfolder(figSaveFolder)
    figSaveFolder = sdfFolder;
end
if isempty(frPeakThresold)
    savename = sprintf('PopulationActivityWarped_%s_%s', subject, strrep(session, '_', ''));
else
    savename = sprintf('PopulationActivityWarped_%s_%s_frThreshold%.0f', subject, strrep(session, '_', '-'), frPeakThresold);
end
tosavename = fullfile(figSaveFolder, savename);
disp('########## making figure ########## ');
print(hf,'-dpdf', tosavename);
print(hf,'-dpng', tosavename, '-r300');
print(hf,'-depsc2', tosavename);

% table
writetable(sdfTable,fullfile(sdfFolder,['sdfTable_' subject '_' session '.csv']));
writetable(PopOutWarpedT,fullfile(figSaveFolder,['PopOutWarped_' subject '_' session '.csv']));
end

