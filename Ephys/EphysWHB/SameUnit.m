function SameUnit(dates, units)


% example:
%    dates --> [20220303; 20220304; 20220305]
%    units --> [6 1; 6 2; 7 1] 
% format: SameUnit([20220303; 20220304; 20220305], [6 1; 6 2; 7 1])
%    to check if Ch6U1 of 20220303, Ch6U2 of 20220304 and
%    Ch7U1 of 20220305 are the same unit

% plz put all RTarrayAll_xxxxxxxx.mat file in one folder


%% load spike data
nDate = length(dates);
nUnit = length(units);
% chstr = repmat([newline 'Ch'], nDate, 1);
chstr = repmat('Ch', nDate, 1);
ustr = repmat('U', nDate, 1);
unitInfo = strtrim([chstr, num2str(units(:,1)), ustr, num2str(units(:,2))]);
% allInfo = [num2str(dates), chstr, num2str(units(:,1)), ustr, num2str(units(:,2))];

if nDate ~= nUnit
    warning('Dates and units are not even.');
end

printsize = [2 2 23 11];
wavepos = [3 3 6 6];
acpos = [14 3 6 6];

allSpikes = cell(nDate, 1);
meanWaves = cell(nDate, 1);
autoCorr  = cell(nDate, 1);
autoCorrZ  = cell(nDate, 1); % zscore of autocorr

for i = 1:nDate

    rname = ['RTarrayAll_', num2str(dates(i)), '.mat'];
    load(rname);  %#ok<LOAD>

    CHANNEL = units(i, 1);
    UNIT = units(i, 2);
    idxUnit = find(r.Units.SpikeNotes(:,1) == CHANNEL ...
        & r.Units.SpikeNotes(:,2) == UNIT);
    allSpikes{i} = r.Units.SpikeTimes(idxUnit).wave(:, 1:256);
    meanWaves{i} = mean(allSpikes{i});

    kutime = r.Units.SpikeTimes(idxUnit).timings;
    kutime2 = zeros(1, max(kutime));
    kutime2(kutime) = 1;
    [c, lags]    = xcorr(kutime2, 25); % max lag 100 ms
    c(lags==0)   = 0;
    autoCorr{i}  = [lags; c];
    autoCorrZ{i} = zscore(c);

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

f1 = figure(1); clf(1);
set(f1, 'unit', 'centimeters', 'position', printsize, 'paperpositionmode', 'auto', 'color', 'w');
title('Similarity comparison: units across sessions', 'FontSize', 12, 'FontWeight', 'bold');
axis off;

% Pearson corr of waveform
h1 = axes('unit', 'centimeters', 'position', wavepos);
pcolor(h1, color_corr);
colormap(h1, "parula");
set(h1, 'xtick', 1.5:1:(nDate+0.5), 'xticklabels', num2str(dates), ...
    'ytick', 1.5:1:(nDate+0.5), 'yticklabels', num2str(dates), 'YTickLabelRotation', 90, 'FontSize', 7);
[textX, textY] = meshgrid(1.5:1:(nDate+0.5));
text(textX(:), textY(:), arrayfun(@(x)[num2str(x, '%.2f')], all_corr, 'UniformOutput', false), ...
    'HorizontalAlignment', 'center', 'FontSize', 7);
text(1.5:1:(nDate+0.5), repmat(0.6, nDate, 1), unitInfo, ...
    'HorizontalAlignment', 'center', 'FontSize', 7, 'FontWeight', 'bold');
title('Pearson of Waveform', 'FontWeight', 'bold', 'FontSize', 10);

h1b = axes('unit', 'centimeters', 'position', [wavepos(1)+wavepos(3)+0.5 wavepos(2) 0 wavepos(4)], ...
    'ytick', [], 'yticklabel', []);
axis('off');
% colormap(h1b, "parula");
colorbar(h1b);

for jj = 1:nDate
    kuwave = meanWaves{jj};
    plotMeanWave(jj, nDate, kuwave, wavepos);
end

% Euclidean distance of autocorrelogram
h2 = axes('unit', 'centimeters', 'position', acpos);
pcolor(h2, color_distance);
colormap(h2, 'parula');
set(h2, 'xtick', 1.5:1:(nDate+0.5), 'xticklabels', num2str(dates), ...
    'ytick', 1.5:1:(nDate+0.5), 'yticklabels', num2str(dates), 'YTickLabelRotation', 90, 'FontSize', 7);
[textX, textY] = meshgrid(1.5:1:(nDate+0.5));
text(textX(:), textY(:), arrayfun(@(x)[num2str(x, '%.2f')], all_distance, 'UniformOutput', false), ...
    'HorizontalAlignment', 'center', 'FontSize', 7);
text(1.5:1:(nDate+0.5), repmat(0.6, nDate, 1), unitInfo, ...
    'HorizontalAlignment', 'center', 'FontSize', 7, 'FontWeight', 'bold');
title('Euclidean Distance of Autocorrelogram', 'FontWeight', 'bold', 'FontSize', 10);

h2b = axes('unit', 'centimeters', 'position', [acpos(1)+acpos(3)+0.5 acpos(2) 0 acpos(4)], 'ytick', [], 'yticklabel', []);
axis('off');
% colormap(h2b, 'autumn');
cb = colorbar(h2b);
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