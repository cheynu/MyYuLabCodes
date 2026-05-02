function PlotUnitLearning(dates, units, flag)

% Nov/05/2022, hbWang

% This function first checks units similarity then plots z-scored-PSTH's
% heatmap across sessions

% example:
%    dates --> [20220303; 20220304; 20220305]
%    units --> [6 1; 6 2; 7 1] 
% format: PlotUnitLearning([20220303; 20220304; 20220305], [6 1; 6 2; 7 1])
%    to check if Ch6U1 of 20220303, Ch6U2 of 20220304 and
%    Ch7U1 of 20220305 are the same unit

% plz put all RTarrayAll_xxxxxxxx.mat file in one folder


%% load spike data

if nargin < 3
    plotPre = 0;
else
    plotPre = flag;
end

nDate = length(dates);
nUnit = length(units);
if nDate ~= nUnit
    warning('Dates and units are not even.');
end

% chstr = repmat([newline 'Ch'], nDate, 1);
chstr = repmat('Ch', nDate, 1);
ustr = repmat('U', nDate, 1);
unitInfo = strtrim([chstr, num2str(units(:,1)), ustr, num2str(units(:,2))]);
% allInfo = [num2str(dates), chstr, num2str(units(:,1)), ustr, num2str(units(:,2))];

printsize = [2 2 24 12];
h8Unit    = 0.5;

cRed    = [0.6350 0.0780 0.1840];
cYellow = 0.86*[0.9290 0.6940 0.1250];
cGreen  = 0.95*[0.4660 0.6740 0.1880];
cGray   = [0.5 0.5 0.5];

params.pre  = 2000;
params.post = 2500;
params.binwidth = 50;
trange = params.pre + params.post + 1;

nameUnits = cell(nDate, 1); 
allSpikes = cell(nDate, 1);
meanWaves = cell(nDate, 1);
autoCorr  = cell(nDate, 1);
autoCorrZ = cell(nDate, 1); % zscore of autocorr
 

psthrange = round(trange/params.binwidth);
psthtick  = round(psthrange/40);
pcolorPrsCor = zeros(nDate, psthrange);
pcolorPrsPre = zeros(nDate, psthrange);
pcolorRlsCor = zeros(nDate, psthrange);
pcolorRlsPre = zeros(nDate, psthrange);

for i = 1:nDate

    rname = ['RTarrayAll_', num2str(dates(i)), '.mat'];
    load(rname);  %#ok<LOAD>
    sbjname  = r.Meta.Subject;

    CHANNEL = units(i, 1);
    UNIT = units(i, 2);
    idxUnit = find(r.Units.SpikeNotes(:,1) == CHANNEL ...
        & r.Units.SpikeNotes(:,2) == UNIT);
    allSpikes{i} = r.Units.SpikeTimes(idxUnit).wave(:, 1:256);
    meanWaves{i} = mean(allSpikes{i});

    curUnit = r.Units.SpikeTimes(idxUnit);
    curUnitTime = r.Units.SpikeTimes(idxUnit).timings;
    curUnitTime2 = zeros(1, max(curUnitTime));
    curUnitTime2(curUnitTime) = 1;
    [c, lags]    = xcorr(curUnitTime2, 25); % max lag 100 ms
    c(lags==0)   = 0;
    autoCorr{i}  = [lags; c];
    autoCorrZ{i} = zscore(c);

    rb = r.Behavior;
    idxPrs = find(strcmp(rb.Labels, 'LeverPress'));
    tPrs   = rb.EventTimings(rb.EventMarkers == idxPrs);
    idxRls = find(strcmp(rb.Labels, 'LeverRelease'));
    tRls   = rb.EventTimings(rb.EventMarkers == idxRls);
    tPrsCor = tPrs(rb.CorrectIndex);
    tRlsCor = tRls(rb.CorrectIndex);

    if plotPre
        tPrsPre = tPrs(rb.PrematureIndex);
        tRlsPre = tRls(rb.PrematureIndex);
    end

    [psthPrsCor, ~, ~, ~] = jpsth(curUnit.timings, tPrsCor, params);
    psthPrsCor = smoothdata(psthPrsCor, 'gaussian', 10);
    psthPrsCor = zscore(psthPrsCor);
    [psthRlsCor, ~, ~, ~] = jpsth(curUnit.timings, tRlsCor, params);
    psthRlsCor = smoothdata(psthRlsCor, 'gaussian', 10);
    psthRlsCor = zscore(psthRlsCor);

    pcolorPrsCor(i, :) = psthPrsCor';
    pcolorRlsCor(i, :) = psthRlsCor';

    if plotPre
        [psthPrsPre, ~, ~, ~] = jpsth(curUnit.timings, tPrsPre, params);
        psthPrsPre = smoothdata(psthPrsPre, 'gaussian', 10);
        psthPrsPre = zscore(psthPrsPre);
        [psthRlsPre, ~, ~, ~] = jpsth(curUnit.timings, tRlsPre, params);
        psthRlsPre = smoothdata(psthRlsPre, 'gaussian', 10);
        psthRlsPre = zscore(psthRlsPre);

        pcolorPrsPre(i, :) = psthPrsPre';
        pcolorRlsPre(i, :) = psthRlsPre';
    end


end


pcolorPrsCor(:, psthrange + 1) = 0;
pcolorPrsCor(nDate + 1, :) = 0;
pcolorRlsCor(:, psthrange + 1) = 0;
pcolorRlsCor(nDate + 1, :) = 0;

if plotPre
    pcolorPrsPre(:, psthrange + 1) = 0;
    pcolorPrsPre(nDate + 1, :) = 0;
    pcolorRlsPre(:, psthrange + 1) = 0;
    pcolorRlsPre(nDate + 1, :) = 0;
end


%% waveform similarity

all_corr = zeros(nDate, nDate);
for j = 1:nDate % j - xdates
    for k = 1:nDate % k - ydates
        if ~isempty(meanWaves{j}) && ~isempty(meanWaves{k})
            t = corrcoef(meanWaves{j}, meanWaves{k});
            all_corr(j, k) = t(2,1);
        else
            all_corr(j, k) = NaN;
        end
    end
end
color_corr = repmat(all_corr, 1);
color_corr(nDate+1, :) = 0;
color_corr(:, nDate+1) = 0;

%% autocorrelogram similarity

all_distance = zeros(nDate, nDate);
for m = 1:nDate % m - xdates
    for n = 1:nDate % n - ydates
        ac1 = autoCorrZ{m};
        ac2 = autoCorrZ{n};
        if ~isempty(ac1) && ~isempty(ac2)
            all_distance(m, n) = ((ac1-ac2)*(ac1-ac2)'/length(ac1));
        else
            all_distance(m, n) = NaN;
        end
    end
end
color_distance = repmat(all_distance, 1);
color_distance(nDate+1, :) = 0;
color_distance(:, nDate+1) = 0;

%% plot
close all;
f1 = figure(1); clf(1);

hmx = 1; hmy = 1;
hmwidth = 10.5;
hmheight = nDate*h8Unit;

titletext = strcat('Unit progress:  ', string(sbjname), '-', unitInfo(1, :));
set(f1, 'unit', 'centimeters', 'position', printsize, 'paperpositionmode', 'auto', 'color', 'w');
title(titletext, 'FontSize', 12, 'FontWeight', 'bold');
axis off;

% Heatmap of cor press trials
ax1 = axes('unit', 'centimeters', 'position', [hmx hmy hmwidth hmheight]);
pcolor(ax1, pcolorPrsCor);
colormap(ax1, "parula");
colorbar(ax1); shading flat;
set(ax1, 'xtick', (0:10:40)*psthtick, 'xticklabels', {'-2000', '-1000', '0', '1000', '2000'}, ...
    'ytick', 1.5:1:nDate+1.5, 'yticklabels', num2str(dates), ...
    'FontSize', 7);
title('Correct trials align at press', 'FontWeight', 'bold', 'FontSize', 10);

if plotPre
% Heatmap of cor press trials
    hmy2 = hmy + hmheight + 1;
    ax2 = axes('unit', 'centimeters', 'position', [hmx hmy2 hmwidth hmheight]);
    pcolor(ax2, pcolorPrsPre);
    colormap(ax2, "parula");
    colorbar(ax2); shading flat;
    set(ax2, 'xtick', (0:10:40)*psthtick, 'xticklabels', {'-2000', '-1000', '0', '1000', '2000'}, ...
        'ytick', 1.5:1:nDate+1.5, 'yticklabels', num2str(dates), ...
        'FontSize', 7);
    title('Premature trials align at press', 'FontWeight', 'bold', 'FontSize', 10);
end

% Heatmap of cor press trials
hmx2 = hmx + hmwidth + 1;
ax3 = axes('unit', 'centimeters', 'position', [hmx2 hmy hmwidth hmheight]);
pcolor(ax3, pcolorRlsCor);
colormap(ax3, "parula");
colorbar(ax3); shading flat;
set(ax3, 'xtick', (0:10:40)*psthtick, 'xticklabels', {'-2000', '-1000', '0', '1000', '2000'}, ...
    'ytick', 1.5:1:nDate+1.5, 'yticklabels', num2str(dates), ...
    'FontSize', 7);
title('Correct trials align at release', 'FontWeight', 'bold', 'FontSize', 10);

if plotPre
    % Heatmap of cor press trials
    ax4 = axes('unit', 'centimeters', 'position', [hmx2 hmy2 hmwidth hmheight]);
    pcolor(ax4, pcolorRlsPre);
    colormap(ax4, "parula");
    colorbar(ax4); shading flat;
    set(ax4, 'xtick', (0:10:40)*psthtick, 'xticklabels', {'-2000', '-1000', '0', '1000', '2000'}, ...
        'ytick', 1.5:1:nDate+1.5, 'yticklabels', num2str(dates), ...
        'FontSize', 7);
    title('Premature trials align at release', 'FontWeight', 'bold', 'FontSize', 10);
end


f2 = figure(2); clf(2);
set(f2, 'unit', 'centimeters', 'position', printsize, 'paperpositionmode', 'auto', 'color', 'w');
title('Similarity comparison: units across sessions', 'FontSize', 12, 'FontWeight', 'bold');
axis off;

% Pearson corr of waveform
% wavepos   = [hmx hmy2+hmheight+3 hmwidth/2 hmwidth/2];
% acpos     = [hmx2 hmy2+hmheight+3 hmwidth/2 hmwidth/2];
wavepos = [1 1 6 6];
acpos = [8 1 6 6];

ax5 = axes('unit', 'centimeters', 'position', wavepos);
pcolor(ax5, color_corr);
colormap(ax5, "parula");
set(ax5, 'xtick', 1.5:1:(nDate+0.5), 'xticklabels', num2str(dates), ...
    'ytick', 1.5:1:(nDate+0.5), 'yticklabels', num2str(dates), 'YTickLabelRotation', 90, 'FontSize', 7);
[textX, textY] = meshgrid(1.5:1:(nDate+0.5));
text(textX(:), textY(:), arrayfun(@(x)[num2str(x, '%.2f')], all_corr, 'UniformOutput', false), ...
    'HorizontalAlignment', 'center', 'FontSize', 7);
text(1.5:1:(nDate+0.5), repmat(0.6, nDate, 1), unitInfo, ...
    'HorizontalAlignment', 'center', 'FontSize', 7, 'FontWeight', 'bold');
title('Pearson of Waveform', 'FontWeight', 'bold', 'FontSize', 10);

ax5b = axes('unit', 'centimeters', 'position', [wavepos(1)+wavepos(3)+0.5 wavepos(2) 0 wavepos(4)], ...
    'ytick', [], 'yticklabel', []);
axis('off');
% colormap(h1b, "parula");
colorbar(ax5b);

for jj = 1:nDate
    curWave = meanWaves{jj};
    plotMeanWave(jj, nDate, curWave, wavepos);
end

% Euclidean distance of autocorrelogram
ax6 = axes('unit', 'centimeters', 'position', acpos);
pcolor(ax6, color_distance);
colormap(ax6, 'parula');
set(ax6, 'xtick', 1.5:1:(nDate+0.5), 'xticklabels', num2str(dates), ...
    'ytick', 1.5:1:(nDate+0.5), 'yticklabels', num2str(dates), 'YTickLabelRotation', 90, 'FontSize', 7);
[textX, textY] = meshgrid(1.5:1:(nDate+0.5));
text(textX(:), textY(:), arrayfun(@(x)[num2str(x, '%.2f')], all_distance, 'UniformOutput', false), ...
    'HorizontalAlignment', 'center', 'FontSize', 7);
text(1.5:1:(nDate+0.5), repmat(0.6, nDate, 1), unitInfo, ...
    'HorizontalAlignment', 'center', 'FontSize', 7, 'FontWeight', 'bold');
title('Euclidean Distance of Autocorrelogram', 'FontWeight', 'bold', 'FontSize', 10);

ax6b = axes('unit', 'centimeters', 'position', [acpos(1)+acpos(3)+0.5 acpos(2) 0 acpos(4)], 'ytick', [], 'yticklabel', []);
axis('off');
% colormap(h2b, 'autumn');
cb = colorbar(ax6b);
ticklim = max(all_distance);
set(cb, 'ticks', 0:0.2:1, 'ticklabels', 0:0.2*max(all_distance):max(all_distance));


for mm = 1:nDate
    kuac = autoCorr{mm};
    plotAutoCorr(mm, nDate, kuac, acpos);
end

end


%% subplot fnctns
function plotMeanWave(i, ndates, wave, wavepos)

xwidth = wavepos(3)/(ndates+1);
ywidth = xwidth;
xheight = wavepos(4)/(ndates+1);
yheight = xheight;

xx = wavepos(1) + (i-1)*wavepos(3)/ndates;
xy = wavepos(2)/4;
yx = wavepos(1)/3;
yy = wavepos(2) + (i-1)*wavepos(4)/ndates;

kuposx = [xx xy xwidth xheight];
kuposy = [yx yy ywidth yheight];

h1x = axes('unit', 'centimeters', 'position', kuposx, 'xlim', [0 256], 'ylim', [-800 400]); %#ok<*NASGU> 
plot(1:256, wave, 'color', 'k', 'linewidth', 2);
axis off;

h1y = axes('unit', 'centimeters', 'position', kuposy, 'xlim', [0 256], 'ylim', [-800 400]);
plot(1:256, wave, 'color', 'k', 'linewidth', 2);
axis off;

end


function plotAutoCorr(i, ndates, ac, acpos)

xwidth = acpos(3)/(ndates+1);
ywidth = xwidth;
xheight = acpos(4)/(ndates+1);
yheight = xheight;

xx = acpos(1) + (i-1)*acpos(3)/ndates;
xy = acpos(2)/4;
yx = acpos(1)-acpos(2)*2/3;
yy = acpos(2) + (i-1)*acpos(4)/ndates;

kacposx = [xx xy xwidth xheight];
kacposy = [yx yy ywidth yheight];

h2x = axes('unit', 'centimeters', 'position', kacposx, 'xlim', [-25 25], 'ylim', [0 1]); %#ok<*NASGU> 
hbar = bar(ac(1,:), ac(2,:));
set(hbar, 'facecolor', 'k')
axis off;

h2y = axes('unit', 'centimeters', 'position', kacposy, 'xlim', [-25 25], 'ylim', [0 1]);
hbar = bar(ac(1,:), ac(2,:));
set(hbar, 'facecolor', 'k')
axis off;

end