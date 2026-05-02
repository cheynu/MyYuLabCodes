function plotLocationFiringRate(KilosortOutput,BehClass,opts)
arguments
    KilosortOutput
    BehClass = []
    opts.UnitFilter {mustBeMember(opts.UnitFilter,{'all','good','mua'})} = 'all'
    opts.nSampleY = 21
end

if ~isempty(BehClass)
    ANM = BehClass.Subject;
    Date = BehClass.Date;
else
    pathUnits = strsplit(pwd,filesep);
    ANM = pathUnits{end-1};
    Date = pathUnits{end};
end

unitType = KilosortOutput.SpikeTable.group;
switch opts.UnitFilter
    case 'all'
        idxUse = contains(unitType,{'good','mua'});
        tagFilter = '';
    case 'good'
        idxUse = contains(unitType,'good');
        tagFilter = 'good';
    case 'mua'
        idxUse = contains(unitType,'mua');
        tagFilter = 'mua';
end

nSampleY = opts.nSampleY;
%% extract data
ch = cell2mat(KilosortOutput.SpikeTable.ch(idxUse));
fr = KilosortOutput.SpikeTable.fr(idxUse);
depth = KilosortOutput.SpikeTable.depth(idxUse);

chanMap = KilosortOutput.ChanMap;
idxConnected = chanMap.connected == true;
chanMap.connected = chanMap.connected(idxConnected);
chanMap.chanMap = chanMap.chanMap(idxConnected);
chanMap.chanMap0ind = chanMap.chanMap0ind.(idxConnected);
chanMap.xcoords = chanMap.xcoords(idxConnected);
chanMap.ycoords = chanMap.ycoords(idxConnected);
chanMap.kcoords = chanMap.kcoords(idxConnected);
%% 1. 平滑平均 Firing Rate vs. Depth（11 个点）
xGrid = linspace(min(depth), max(depth), nSampleY);
bandwidth = mean(diff(xGrid))/2;
% bandwidth = 50;
[numPdf,~,bw1] = ksdensity(depth, xGrid, ...
                  'weights', fr, ...
                  'function', 'pdf',...
                  'Bandwidth',bandwidth);
[denPdf,~,bw2] = ksdensity(depth, xGrid, ...
                  'function', 'pdf',...
                  'Bandwidth',bandwidth);
meanFR_smooth = numPdf ./ (denPdf + 1e-6); % 防止除以0
%% 2. 计算每个 channel 的平均 firing rate
n_channel = length(chanMap.chanMap);
mean_fr_channel = nan(1, n_channel);
for k = 1:n_channel
    fr_k = fr(ch == k);
    if ~isempty(fr_k)
        mean_fr_channel(k) = mean(fr_k);
    else
        mean_fr_channel(k) = 0;
    end
end
%% Plot
set_matlab_default_CY;

x_range = range(chanMap.xcoords);
y_range = range(chanMap.ycoords);
height = 13;
width = height/y_range*x_range;

xLim = [min(chanMap.xcoords) max(chanMap.xcoords)];
yLim = [min(chanMap.ycoords) max(chanMap.ycoords)];

fig = EasyPlot.figure();
ax1 = EasyPlot.axes(fig);
EasyPlot.set(ax1, 'Width', 1.5, 'Height', height,...
    'MarginLeft', 1.2,...
    'MarginTop', 0.5,...
    'MarginBottom',1);

ax2 = EasyPlot.createAxesAgainstAxes(fig,ax1,'right',...
    'Width', width, 'Height', height,...
    'XAxisVisible', 'off','YaxisVisible','off',...
    'MarginRight',0.5,...
    'MarginLeft',1.2);

% ---- 左侧 axes: mean FR vs. depth ----
plot(ax1, meanFR_smooth, xGrid, '-o', 'LineWidth', 1.5, 'MarkerSize', 5);
xlabel(ax1, 'Firing Rate (Hz)');
ylabel(ax1, 'Distance from tip (µm)');
xlim(ax1,[0 max(3,ceil(prctile(meanFR_smooth,95)))]);
ylim(ax1,yLim);
% xticks(ax1,0:2:50)
box off;

% ---- 右侧 axes: Channel 电极图 ----
% colormap(ax2, parula);
color_max = prctile(mean_fr_channel(mean_fr_channel>0),95);
% 构造颜色映射
nTrunc = 25;
cmap = jet(256+nTrunc);
cmap = cmap(1:end-nTrunc,:);
temp_fr = mean_fr_channel;
temp_fr(temp_fr>color_max) = color_max;
norm_fr = round(rescale(temp_fr, 1, 256));
norm_fr(mean_fr_channel == 0) = 1;
colors = cmap(norm_fr, :);
colors(mean_fr_channel == 0,:) = repmat([0.9 0.9 0.9],sum(mean_fr_channel == 0),1);

ticks = 0:2:color_max;
tick_labels = string(round(ticks,1));

EasyPlot.setCLim(ax2,[0 color_max]);

scatter(ax2, chanMap.xcoords, chanMap.ycoords, 5, colors, 'filled');
xlabel(ax2, '');
xlim(xLim);
ylim(yLim);
xticks([]);
yticklabels({})

EasyPlot.colorbar(ax2,...
    'label', 'Mean FR (Hz)',...
    'colormap', cmap,...
    'Ticks', ticks,...
    'TickLabels', tick_labels,...
    'Height', height/2,...
    'MarginRight',1,...
    'tickdir','out');

sc = EasyPlot.scalebar(ax2, 'Y', 'location', 'southwest',...
                'yBarLabel', '1 mm', 'yBarLength', 1000, 'yBarRatio', 1);
EasyPlot.move(sc, 'dx', -0.5);

EasyPlot.title(ax1,ANM,'fontSize',9);
EasyPlot.title(ax2,Date,'fontSize',9);

EasyPlot.cropFigure(fig);
pause(0.6); % it seems that Crop need time for correct output
if isempty(tagFilter)
    EasyPlot.exportFigure(fig, 'channelFiringRate.png');
else
    EasyPlot.exportFigure(fig, ['channelFiringRate' '_' tagFilter '.png']);
end

end