function [RegularIndex, unitLocation] = seePixelsGPS(r, spatial)
% Revised from Jianing Yu 2025.5
if nargin < 2
    if isfield(r, 'ChanMap')
        spatial = r.ChanMap;
    else
        error('Lack spatial information');
    end
end

% Plot the spike sorting results of a single session
nSpk = size(r.Units.SpikeNotes, 1);
% plot channel information. 
channel_locations = [spatial.xcoords, spatial.ycoords];

% find out the max waveform
vOffset = 50;
Fs = 30000;
binSize = 1;
maxLag = 50;

peakTrough                  =       zeros(1, nSpk);
tPeakTrough                 =       zeros(1, nSpk);
fullWidthHalfHeight         =       zeros(1, nSpk);

good                        =       zeros(1, nSpk);
autoCorr                    =       []; % compute auto correlogram
tCorr                       =       [];
amplitudes                  =       zeros(2, nSpk);
nWave = 5;
waveCollection              =       cell(1, nWave);
nNearest = 40;
unitLocation.where          =       zeros(3, nSpk);
unitLocation.what           =       zeros(1, nSpk); % size of the spike (this differs from the max size in a channel)
unitLocation.type           =       zeros(1, nSpk); % size of the spike (this differs from the max size in a channel)

for i =1:nSpk

    allWaves        =   r.Units.SpikeTimes(i).wave_mean;
    nSample         =   size(allWaves, 2);
    % find out the largest waveform
    spikeSize       =   abs(max(allWaves, [], 2)-min(allWaves, [], 2)); % this is a nCh x 1 vector.
    [spikeSizeSorted, indSort] = sort(spikeSize, 'descend');
    amplitudes(1, i) = spikeSizeSorted(1);
    amplitudes(2, i) = spikeSizeSorted(2);

    for j =1:nWave
        waveCollection{j} = [waveCollection{j}; allWaves(indSort(j), :)];
    end
    twave           =   (1:nSample)*1000/Fs; % in ms
    % get spike features
    feature_out = spike_features(twave, allWaves(indSort(1), :));
    peakTrough(i) = feature_out.peak2trough;
    tPeakTrough(i) = feature_out.t_peak2trough;
    fullWidthHalfHeight(i) = feature_out.fwhh;
    good(i) = r.Units.SpikeNotes(i, 3) == 1; % mark good spikes.
 
    unitLocation.type(i) = good(i);

    spikeTimes = r.Units.SpikeTimes(i).timings;
    [lags, counts] = computeACG(spikeTimes, binSize, maxLag);

    if isempty(tCorr)
        tCorr = lags;
    end

    autoCorr = [autoCorr; counts'];

    % based on allWaves, compute the location of the unit. 

    % use this function from Yue Huang
    % function [x, y, z, ptt] = spikeLocation(waveforms_mean, channel_locations, n_nearest_channels, algorithm)
    [unitLocation.where(1, i),unitLocation.where(2, i),unitLocation.where(3, i)] = spikeLocation(allWaves, channel_locations, nNearest, 'monopolar_triangulation');
     unitLocation.what(i) = spikeSizeSorted(1);

end

unit_location_name = sprintf('unitLocation_%s_%s.mat', r.BehaviorClass.Subject, r.BehaviorClass.Session);
save(unit_location_name, 'unitLocation')

% Make a figure showing spikes
% Save a 'SpikeQuality_meta' figure to current directory. 
% An index of good units is also saved. 
set_matlab_default
% setDefaultStyles
fig = 98;
figure(fig); clf(fig)
set(gcf, 'Visible', 'on', 'Units', 'centimeters','Position',[2 2 15 12])

x_now = 1;
y_now = 2;
width = 3;
height = 9;

ha1 = axes('Units', 'centimeters', 'Position', [x_now y_now width height], 'nextplot', 'add');% plot spikes
xlabel('ms')
x_now = x_now +width+1;

ha2 = axes('Units', 'centimeters', 'Position', [x_now y_now width height], 'nextplot', 'add');% plot spikes correogram
xlabel('lag (ms)')
title('Auto-correlation')
x_now = x_now +width+1;

y_now = 1.5;
width2 = 4;
height2 = 5;
ha4 = axes('Units', 'centimeters', 'Position', [x_now y_now width2 height2], 'nextplot', 'add'); % plot distribution of spikes
y_now = 7.5;
height3 = 4;
ha3 = axes('Units', 'centimeters', 'Position', [x_now y_now width2 height3], 'nextplot', 'add'); % plot peakTrough vs full widht

% Plot waveforms, first plot the 'good' units, then 'mua'. Sort units by
% their spike amplitude
[~, indAmpSort] = sort(amplitudes(1, :), 'descend');
waveCollectionSorted = cell(1, nWave);
for j =1:nWave
    waveCollectionSorted{j} = waveCollection{j}(indAmpSort, :);
end

goodSorted = good(indAmpSort);
autoCorrSorted = autoCorr(indAmpSort, :);

peakTroughSorted = peakTrough(indAmpSort);
fullWidthHalfHeightSorted = fullWidthHalfHeight(indAmpSort);
tPeakTroughSorted = tPeakTrough(indAmpSort);

% Cluster analysis
X = [peakTroughSorted(:), fullWidthHalfHeightSorted(:)];
% Normalize data (optional, if scales differ)
X = (X - mean(X)) ./ std(X);
% Run kmeans with optimized parameters
[cidx, ctrs] = kmeans(X, 2, ...
    'Distance', 'sqeuclidean', ...
    'Replicates', 5, ...
    'Start', 'plus', ...
    'EmptyAction', 'singleton', ...
    'MaxIter', 200, ...
    'Display', 'off');

% Count points in each cluster
clusterCounts = histcounts(cidx, [1 2 3]); % Counts for cluster 1 and 2
count1 = clusterCounts(1); % Number of points in cluster 1
count2 = clusterCounts(2); % Number of points in cluster 2

% Swap indices if cluster 2 is larger
if count2 > count1
    cidx = 3 - cidx; % Converts 1 to 2 and 2 to 1
    ctrs = ctrs([2 1], :); % Swap centroid rows to match
end

GoodRegularIndex = indAmpSort(goodSorted' == 1 & cidx == 1);
disp(GoodRegularIndex)

MUARegularIndex = indAmpSort(goodSorted' == 0 & cidx == 1);
disp(MUARegularIndex)

RegularIndex.Good = GoodRegularIndex;
RegularIndex.MUA = MUARegularIndex;

% Plot waveform
nGood = sum(goodSorted==1);
indGood = find(goodSorted == 1);

k = 0;
text(ha1, twave(1), 0, sprintf('N = %2.0d', nGood))
for i =1:nGood
    k = k +1;
    if cidx(indGood(i)) == 1
        for j =1:nWave
            plot(ha1, twave+(j-1)*twave(end), waveCollectionSorted{j}(indGood(i), :)-k*vOffset, 'k', 'linewidth', 1);
        end
    else
        for j =1:nWave
            plot(ha1, twave+(j-1)*twave(end), waveCollectionSorted{j}(indGood(i), :)-k*vOffset, 'r', 'linewidth', 1);
        end
    end
end
nMUA = sum(goodSorted == 0);
indMUA = find(goodSorted == 0);

k = k + 2;
text(ha1, twave(1), -k*vOffset, sprintf('N = %2.0d', nMUA))
for i =1:nMUA
    k = k +1;
    if cidx(indMUA(i)) == 1
        for j =1:nWave
            plot(ha1, twave+(j-1)*twave(end), waveCollectionSorted{j}(indMUA(i), :)-k*vOffset, 'k', 'linewidth', .5);
        end
    else
        for j =1:nWave
            plot(ha1, twave+(j-1)*twave(end), waveCollectionSorted{j}(indMUA(i), :)-k*vOffset, 'r', 'linewidth', .5);
        end
    end
end

ha1.YLim = [min(waveCollectionSorted{1}(indMUA(i), :)-k*vOffset) 100];
ha1.YTick = [-100 0];

ylabel('Peak to trough ratio')
xlabel('Full width at half height (ms)')
% Plot autocorrelograms
autoCorrStruct.All =  autoCorrSorted;
autoCorrStruct.Good =  autoCorrSorted(goodSorted == 1, :);
autoCorrStruct.MUA =  autoCorrSorted(goodSorted == 0, :);

autoCorrStruct.MAUNorm = normalize(autoCorrStruct.MUA, 2, 'range');
imagesc(ha2, tCorr, (1:size(autoCorrStruct.MUA, 1)), flipud(autoCorrStruct.MAUNorm));

autoCorrStruct.GoodNorm = normalize(autoCorrStruct.Good, 2, 'range');
imagesc(ha2, tCorr, (1:size(autoCorrStruct.Good, 1))+2+nMUA, flipud(autoCorrStruct.GoodNorm));
ha2.YLim = [1 nGood+nMUA+3];

colormap(ha2, 'turbo')
hbar = colorbar(ha2, 'EastOutside');
ha2.XLim = [-15 15];
% Plot spike features
% Prepare data

scatter(ha3,  fullWidthHalfHeightSorted(cidx==1 & goodSorted' == 1), peakTroughSorted(cidx==1 & goodSorted' == 1), ...
    40, 'k', 'filled', 'markerfacealpha', 0.6);
scatter(ha3, fullWidthHalfHeightSorted(cidx==1 & goodSorted' == 0), peakTroughSorted(cidx==1 & goodSorted' == 0),  40, 'k');
scatter(ha3, fullWidthHalfHeightSorted(cidx==2), peakTroughSorted(cidx==2),  40, 'r', 'filled');

% Here we plot the spatial locations. 
seeUnitLocation(spatial, unitLocation, ha4);

meta = sprintf('%s | %s | %s', r.BehaviorClass.Subject, r.BehaviorClass.Session, r.BehaviorClass.Protocol);
% meta = [r.BehaviorClass.Subject ' | ' r.BehaviorClass.Date ' | ' r.BehaviorClass.Protocol];
annotation('textbox', 'String', meta, ...
    'units', 'normalized', ...
    'Position', [.1 .95 .8 .05], ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'bottom', ...
    'FontSize', 10, ...
    'FontWeight', 'bold',...
    'EdgeColor','none'); %     'FontName', myFont,...

if ~exist('Figure', 'dir')
    mkdir('Figure');
end

savename1 = fullfile(pwd, 'Figure', sprintf('SpikeQuality_%s_%s_%s', r.BehaviorClass.Subject, r.BehaviorClass.Session, r.BehaviorClass.Protocol));
% savename1 = fullfile(pwd, 'Figure', ['SpikeQuality_' r.BehaviorClass.Subject '_' r.BehaviorClass.Date '_' r.BehaviorClass.Protocol]);
print(fig, '-dpng', [savename1, '.png']) 

% GoodRegularIndex
savename1 = fullfile(pwd, sprintf('RegularIndex_%s_%s_%s', r.BehaviorClass.Subject, r.BehaviorClass.Session, r.BehaviorClass.Protocol));
% savename1 = fullfile(pwd, ['RegularIndex_' r.BehaviorClass.Subject '_' r.BehaviorClass.Date '_' r.BehaviorClass.Protocol '.mat']);
save(savename1, 'RegularIndex')
