function seePixelsSpikesSingleSession(r,sdfUnits, spatial)

% Jianing Yu 2025.5
% run this after running [RegularIndex, unitLocation]=seePixels(r, spatial);
% sdfUnits are from     sdfUnits = rWarp(r, [RegularIndex.Good, RegularIndex.MUA], unitLocation);
% spatial is from 
% look for 'channel_map.npy' and 'channel_positions.npy'
%     spatial =load('chanMap.mat');
% 2025.5.20 add short FP trials

% Check all isi_violation
isi_vio = arrayfun(@(x)x.isi_violation, sdfUnits);
% compute the area under auto-correlogram
auto_vio = zeros(1, length(sdfUnits));
good_index = zeros(1, length(sdfUnits));
for i =1:length(sdfUnits)
    auto_3 = sum(sdfUnits(i).auto_correlation.counts(abs(sdfUnits(i).auto_correlation.lags)<=3));
    auto_all = sum(sdfUnits(i).auto_correlation.counts(abs(sdfUnits(i).auto_correlation.lags)<=50));
    auto_vio(i) = auto_3/auto_all;
    good_index(i) = sdfUnits(i).good;
end
allSparsenss = arrayfun(@(x)x.sparseness, sdfUnits);

figure;
subplot(1, 2, 1)
scatter(isi_vio(good_index==1), auto_vio(good_index==1), 'filled'); hold on
scatter(isi_vio(good_index==2), auto_vio(good_index==2), '+');
xlabel('ISI violation (<3ms percentage)');
ylabel('AutoCorrelation (<3ms percentage)');

% Choose these spikes for plotting:
% ISI violation should be less than 0.8%, auto violation should be less
% than 0.02, and sparseness should be more than 0.5 (continuously spiking neurons not selected). 
index_chosen = isi_vio<0.8 & auto_vio<0.02 & allSparsenss>0.5;
scatter(isi_vio(index_chosen), auto_vio(index_chosen), 'o', 'SizeData', 60); hold on
subplot(1, 2, 2)

scatter(isi_vio(good_index==1), allSparsenss(good_index==1), 'filled'); hold on
scatter(isi_vio(good_index==2), allSparsenss(good_index==2), '+')
scatter(isi_vio(index_chosen), allSparsenss(index_chosen), 'o', 'SizeData', 60); hold on
sdfUnitsSelected = sdfUnits(index_chosen);
indFP.Short = 1;
indFP.Long = 2;

nUnits = length(sdfUnitsSelected);
disp(nUnits)
% get all press sdf
time_press = sdfUnitsSelected(1).warp_out.pooled.press.sdf_pooled.time;
sdf_press = zeros(length(time_press), nUnits);
sdf_press_ci = zeros(length(time_press), nUnits, 2);

for i =1:nUnits
    sdf_press(:, i)         = sdfUnitsSelected(i).warp_out.pooled.press.sdf_pooled.mean;
    sdf_press_ci(:, i, :)   = sdfUnitsSelected(i).warp_out.pooled.press.sdf_pooled.ci;
end

% get all release sdf
time_release = sdfUnitsSelected(1).warp_out.pooled.trigger_release_poke.sdf_pooled.time;
sdf_release = NaN*ones(length(time_release), nUnits);

for i =1:nUnits
    iTime = sdfUnitsSelected(i).warp_out.pooled.trigger_release_poke.sdf_pooled.time;
    [~, ind1, ind2] = intersect(iTime, time_release);
    sdf_release(ind2, i) = sdfUnitsSelected(i).warp_out.pooled.trigger_release_poke.sdf_pooled.mean(ind1);
end

% sort data
figure;
t_offset = -50;
r_offset = 5;
tplot = [-2500 750];
ind = time_press>=tplot(1) & time_press<=tplot(2);
tplot2 = [-500 2000];
ind2 = time_release>=tplot2(1) & time_release<=tplot2(2);

indMax = zeros(1, nUnits);
indLowFR = zeros(1, nUnits);

for i =1:nUnits
    plot(time_press(ind)+t_offset*i, sdf_press(ind, i)+i*r_offset, 'k')
    hold on
    plot(time_release(ind2)+time_press(end)-time_release(1)+0.25+t_offset*i, sdf_release(ind2, i)+i*r_offset, 'k')
    sdf_conc = [sdf_press(ind, i); sdf_release(ind2, i)];
    indMax(i) = find(sdf_conc > 0.9*max(sdf_conc), 1, 'first');
    if max(sdf_conc)<5
        indLowFR(i) = 1;
    end
end

indMax(indLowFR==1) = NaN;
[indMax_, indSort] = sort(indMax);

sdf_press_sort = sdf_press(:, indSort);
sdf_release_sort = sdf_release(:, indSort);

sdf_press_sort(:, isnan(indMax_)) = [];
sdf_release_sort(:, isnan(indMax_)) = [];

sdfUnitsSelectedSorted = sdfUnitsSelected(indSort);
sdfUnitsSelectedSorted = sdfUnitsSelectedSorted(~isnan(indMax_));
nUnitsFinal = size(sdf_press_sort, 2);

figure;
t_offset = -50;
r_offset = -10;
tplot = [-2500 750];
ind = time_press>=tplot(1) & time_press<=tplot(2);
tplot2 = [-500 2000];
ind2 = time_release>=tplot2(1) & time_release<=tplot2(2);

for i =1:nUnitsFinal
    plot(time_press(ind)+t_offset*(i-1), sdf_press_sort(ind, i)+(i-1)*r_offset, 'k')
    hold on
    plot(time_release(ind2)+time_press(end)-time_release(1)+0.25+t_offset*(i-1), sdf_release_sort(ind2, i)+(i-1)*r_offset, 'k')
end
close all;

tosavename = ['sdfUnitsSelected_' r.BehaviorClass.Subject '_' r.BehaviorClass.Date, '.mat'];
sdfUnitsSelected = sdfUnitsSelectedSorted;
save(tosavename, 'sdfUnitsSelected', '-v7.3')
%
% Make a publication-quality figure showing PSTH of all units, in the ridgeline fasion and color map. 

% Set default font to Helvetica for all text in figures
setDefaultStyles

% extract press and release PSTHs 
tPress              =   time_press;
indPressPlot        =   find(tPress>=-2500 & tPress<=750);
tRelease            =   time_release;
rt_median           =   sdfUnitsSelected(1).warp_out.pooled.trigger_release_poke.sdf_pooled.event_times(1);
retrieval_median    =   sdfUnitsSelected(1).warp_out.pooled.trigger_release_poke.sdf_pooled.event_times(2);

indReleasePlot      =   find(tRelease>=-500 & tRelease <=rt_median+retrieval_median+1000);
tPressPlot          =   tPress(indPressPlot);
tReleasePlot        =   tRelease(indReleasePlot);

press_sdfs_all_     =   fliplr(sdf_press_sort(indPressPlot, :));
release_sdfs_all_   =   fliplr(sdf_release_sort(indReleasePlot, :));

% unit_index_ = flipud(unit_index);
% num_curves = size(press_sdfs_all, 2);

x_offset = 50; % Horizontal shift
y_offset = 10; % Vertical shift

% Make this figure
fig_num = 10;
fig = figure(fig_num); clf(fig)

set(fig, 'units', 'Centimeters', 'position',[2 2 22 22],...
    'Visible','on', 'paperpositionmode', 'auto', 'color', 'w');

y_now = 17;
x_width = 4;
y_width = 4;

t_press_range = [tPressPlot(1) tPressPlot(end)];
t_press_range_pseudo = [t_press_range(1) t_press_range(2)+500];

ha_PSTH_Press = axes('units', 'centimeters', 'position', [1.5 y_now x_width y_width],...
    'nextplot', 'add', 'xlim', t_press_range_pseudo, 'ylim', [0 250],  'TickLength',[.0125 .1]);

set(ha_PSTH_Press, 'FontSize', 7)
curve_colors = repmat([0, 0.4470, 0.7410], 400, 1);

ymax = 50;
ymin = 0;
xmin = t_press_range_pseudo(1);
xmax = t_press_range_pseudo(2);
num_curves = size(sdf_press_sort, 2);

for i = 1:num_curves
    x_shifted1 = tPressPlot + (i-1) * x_offset;
    y_shifted1 = press_sdfs_all_(:, i) + (i-1) * y_offset;

    plot(x_shifted1, y_shifted1, 'LineWidth', .5, 'Color', curve_colors(i, :));

    ymin = min(ymin, min(y_shifted1));
    ymax = max(ymax, max(y_shifted1));
    xmin = min(xmin, min(x_shifted1));
    xmax = max(xmax, max(x_shifted1));

end
ha_PSTH_Press.YLim = [ymin ymax];
ha_PSTH_Press.XLim = [xmin xmax];
 
line([1000 1000], [0 50], 'color', 'k', 'linewidth', 2);
text(1200, 20, '50 Hz', 'fontsize', 6, 'FontName', 'Helvetica')

% determine width per 100 ms:
width100ms = 100*x_width/(xmax - xmin);

 % This line marks the press time
line([0 (num_curves-1)*x_offset], [0 (num_curves-1) * y_offset], 'color', 'k')
xlabel('Time from press (s)', 'FontSize', 8); ylabel('Spike rate (Hz)', 'FontSize', 8);
grid off;

ha_PSTH_Press.XTick = [-2000 -1500 -1000 -500 0 500 1000];
ha_PSTH_Press.XTickLabel = {'-2', '', '-1', '', '0', '', '1'};

% add release
t_release_range = [tReleasePlot(1) tReleasePlot(end)];
t_release_range_pseudo = [t_release_range(1) t_release_range(2)+2000];
% 'rt_median_all', 'retrieval_median_all')
x_width_release = 3;
ha_PSTH_Release = axes('units', 'centimeters', 'position', [1.5+x_width-.5 y_now x_width_release y_width],...
    'nextplot', 'add', 'xlim', t_release_range_pseudo, 'ylim', [ymin ymax],  'TickLength',[.0125 .1],...
    'ytick', [], 'color', 'none');
axis off
set(ha_PSTH_Release, 'FontSize', 7)
xmin = t_release_range_pseudo(1);
xmax = t_release_range_pseudo(2);

for i = 1:num_curves
    x_shifted2 = tReleasePlot + (i-1) * x_offset;
    y_shifted2 = release_sdfs_all_(:, i)+ (i-1) * y_offset;
    plot(x_shifted2, y_shifted2, 'LineWidth', .5, 'Color', curve_colors(i, :));
    xmin = min(xmin, min(x_shifted2));
    xmax = max(xmax, max(x_shifted2));
    ymax = max(ymax, max(y_shifted2));
end

ha_PSTH_Press.YLim = [ymin ymax];
ha_PSTH_Release.YLim = [ymin ymax];
ha_PSTH_Release.XLim = [xmin xmax];

t_release_range_pseudo = [xmin xmax];
x_width_release = width100ms*diff(t_release_range_pseudo)/100;

ha_PSTH_Release.Position(3) = x_width_release;
ha_PSTH_Release.XTick = [0 500 1000 1500 2000];
ha_PSTH_Release.XTickLabel = {'0', '', '1', '', '2'};
xlabel('Time from trigger (s)', 'FontSize', 8); 
% plot some grid for references
xgrids = (-2000:500:xmax);
for k =1:length(xgrids)
    line(ha_PSTH_Press, [0 (num_curves-1)*x_offset]+xgrids(k), [0 (num_curves-1) * y_offset], 'color', [.75 .75 .75], 'linestyle', ':');
end

% plot some grid for references
xgrids = (0:500:2000);
for k =1:length(xgrids)
    line(ha_PSTH_Release, [0 (num_curves-1)*x_offset]+xgrids(k), [0 (num_curves-1) * y_offset], 'color', [.75 .75 .75], 'linestyle', ':');
end
 % This line maarks the trigger time
line([0 (num_curves-1)*x_offset], [0 (num_curves-1) * y_offset], 'color', 'k')
% this line marks the release time
line([0 (num_curves-1)*x_offset]+rt_median, [0 (num_curves-1) * y_offset], 'color', 'k')
line([0 (num_curves-1)*x_offset]+rt_median+retrieval_median, [0 (num_curves-1) * y_offset], 'color', 'k')
% Use colormap to visualize the spikes
press_sdfs_all_norm         =   zeros(size(press_sdfs_all_));
release_sdfs_all_norm       =   zeros(size(release_sdfs_all_));

for i =1:num_curves
    sdf_concat                  =   [press_sdfs_all_(:, i); release_sdfs_all_(:, i)];
    press_sdfs_all_norm(:, i)   = (press_sdfs_all_(:, i)-min(sdf_concat))/(max(sdf_concat)-min(sdf_concat));
    release_sdfs_all_norm(:, i) = (release_sdfs_all_(:, i)-min(sdf_concat))/(max(sdf_concat)-min(sdf_concat));
end

% plot these activity in colormap
x_now = 11;
width = width100ms*length(tPressPlot)/100;
height = 4;

ha_Press =  axes('unit', 'centimeters', ...
    'position', [x_now  y_now width  height],...
    'nextplot', 'add', ...
    'xlim', [tPressPlot(1) tPressPlot(end)], 'ylim', [0 num_curves+1],...
    'ytick', [10.5 20.5 30.5 40.5 50.5],'yticklabel', num2cell(10:10:50),...
    'xtick', (-2000:1000:4000),...
    'xticklabel', num2cell((-2:4)),...
    'xscale', 'linear', 'yscale', 'linear', 'ticklength', [0.02, 1], ...
    'XTickLabelRotation', 0, 'fontname', 'Helvetica', 'fontsize', 7);

xlabel('Time from press (s)', 'fontname', 'Helvetica', 'fontsize', 7)
ylabel('Units', 'fontname', 'Helvetica', 'fontsize', 7)

imagesc(tPressPlot, (1:num_curves), press_sdfs_all_norm', [0 1])
line([0 0], [0 num_curves+1], 'color', 'w')
colormap(ha_Press, turbo)

x_now = x_now +width +.25;
width2 = width100ms*length(tReleasePlot)/100;

ha_Release =  axes('unit', 'centimeters', ...
    'position', [x_now  y_now width2  height],...
    'nextplot', 'add', ...
    'xlim', [tReleasePlot(1) tReleasePlot(end)], 'ylim', [0 num_curves+1],...
    'ytick', [50.5 100.5 150.5 200.5],'yticklabel', [],...
    'xtick', (-2000:1000:4000),...
    'xticklabel', num2cell((-2:4)),...
    'xscale', 'linear', 'yscale', 'linear', 'ticklength', [0.02, 1], ...
    'XTickLabelRotation', 0, 'fontname', 'Helvetica', 'fontsize', 7);

xlabel('Time from trigger (s)', 'fontname', 'Helvetica', 'fontsize', 7)

imagesc(tReleasePlot, (1:num_curves), release_sdfs_all_norm', [0 1])
colormap(ha_Release, turbo)
 % This line maarks the trigger time
line([0 0], [0 num_curves+1], 'color', 'w')
% this line marks the release time
line([0 0]+rt_median, [0 num_curves+1], 'color', 'w')
line([0 0]+rt_median+retrieval_median, [0 num_curves+1], 'color', 'w')
hbar1 = colorbar('Eastoutside');
set(hbar1, 'units', 'centimeters', 'position',[x_now+width2+0.2 y_now 0.2 2])
hbar1.Label.String = 'Firing rate (normalized)';

hbar1.Ticks=[0 0.5 1];
hbar1.TickLength = 0.04;

styleAllAxesInFigure(fig)

% Plot these spikes to channel maps
y_now = y_now - y_width - 1.5;
x_now = 1.5;
width = 1.5;
height = 2.5;
left_shift=0.5;
v_shift=0.5;

annotation('textbox', 'String', 'Peri-Press', ...
    'units', 'centimeters', ...
    'Position', [x_now-left_shift y_now+height+v_shift 5 0.5], ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'bottom', ...
    'FontSize', 12, ...
    'FontWeight', 'bold',...
    'FontName', myFont,...
    'EdgeColor','none');

annotation('textbox', 'String', 'Peri-Trigger/Release', ...
    'units', 'centimeters', ...
    'Position', [x_now-left_shift+7 y_now+height+v_shift 5 0.5], ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'bottom', ...
    'FontSize', 12, ...
    'FontWeight', 'bold',...
    'FontName', myFont,...
    'EdgeColor','none');

approachTimeBins    = [-2 -1 0]*1000; % in ms, 3 divisions
releaseTimeBins     = [0 rt_median rt_median+retrieval_median]; % 2 divisions

nDivs_Press = length(approachTimeBins);
nDivs_Release = length(releaseTimeBins);

h_spacing = 0.2;


for i =1:nDivs_Press
    ha =  axes('unit', 'centimeters', ...
    'position', [x_now  y_now width  height],...
    'nextplot', 'add');
    x_now = x_now +width +h_spacing;

    if i>1
        axis off
    else
        xlabel('X (um)')
        ylabel('Y (um)')
    end

    % find out the units that mostly fire here

    if i<length(approachTimeBins)
            title(sprintf('%2.1f~%2.1f', approachTimeBins(i)/1000, approachTimeBins(i+1)/1000), 'fontsize', 5);

        unitLocation = [];
        maxPDF = max(press_sdfs_all_norm(tPressPlot>=approachTimeBins(i) & tPressPlot<approachTimeBins(i+1), :));
        indUnits = find(maxPDF>0.5); % these are the units that are active during this period
        unitLocation.where = cell2mat(arrayfun(@(x)x.location, sdfUnitsSelected(indUnits), 'UniformOutput', false));
        unitLocation.what =  arrayfun(@(x)x.spike_size, sdfUnitsSelected(indUnits));
        unitLocation.type =  arrayfun(@(x)x.good, sdfUnitsSelected(indUnits));
        unitLocation.rateNorm = maxPDF(indUnits);
        seeUnitLocation(spatial, unitLocation, ha);
    end

    if i==length(approachTimeBins)
        title(sprintf('%2.1f~', approachTimeBins(i)/1000), 'fontsize', 5);

        unitLocation = [];
        maxPDF = max(press_sdfs_all_norm(tPressPlot>=approachTimeBins(i), :));
        indUnits = find(maxPDF>0.5); % these are the units that are active during this period
        unitLocation.where = cell2mat(arrayfun(@(x)x.location, sdfUnitsSelected(indUnits), 'UniformOutput', false));
        unitLocation.what =  arrayfun(@(x)x.spike_size, sdfUnitsSelected(indUnits));
        unitLocation.type =  arrayfun(@(x)x.good, sdfUnitsSelected(indUnits));
        unitLocation.rateNorm = maxPDF(indUnits);
        seeUnitLocation(spatial, unitLocation, ha);
    end
end
x_now = x_now+1;

for j =1:nDivs_Release
    ha =  axes('unit', 'centimeters', ...
        'position', [x_now  y_now width  height],...
        'nextplot', 'add');
    x_now = x_now +width +h_spacing;

    if j>1
        axis off
    end

    if j<nDivs_Release

        title(sprintf('%2.1f~%2.1f', releaseTimeBins(j)/1000, releaseTimeBins(j+1)/1000), 'fontsize', 5);

        unitLocation = [];
        maxPDF = max(release_sdfs_all_norm(tReleasePlot>=releaseTimeBins(j) & tReleasePlot<releaseTimeBins(j+1), :));
        indUnits = find(maxPDF>0.5); % these are the units that are active during this period
        unitLocation.where = cell2mat(arrayfun(@(x)x.location, sdfUnitsSelected(indUnits), 'UniformOutput', false));
        unitLocation.what =  arrayfun(@(x)x.spike_size, sdfUnitsSelected(indUnits));
        unitLocation.type =  arrayfun(@(x)x.good, sdfUnitsSelected(indUnits));
        unitLocation.rateNorm = maxPDF(indUnits);
        seeUnitLocation(spatial, unitLocation, ha);

    else
        title(sprintf('%2.1f~', releaseTimeBins(j)/1000), 'fontsize', 5);
        unitLocation = [];
        maxPDF = max(release_sdfs_all_norm(tReleasePlot>=releaseTimeBins(j), :));
        indUnits = find(maxPDF>0.5); % these are the units that are active during this period
        unitLocation.where = cell2mat(arrayfun(@(x)x.location, sdfUnitsSelected(indUnits), 'UniformOutput', false));
        unitLocation.what =  arrayfun(@(x)x.spike_size, sdfUnitsSelected(indUnits));
        unitLocation.type =  arrayfun(@(x)x.good, sdfUnitsSelected(indUnits));
        unitLocation.rateNorm = maxPDF(indUnits);
        seeUnitLocation(spatial, unitLocation, ha);
    end
end

%% Plot some trials to show the trial-to-trial variability
y_now = y_now - height - 2;

indFP.Short = 1;
indFP.Long = 2;

types = [indFP.Short, indFP.Long];

for m = 1:length(types)
    pressTimes   =   r.PSTH.Events.Presses.Time{types(m)};
    releseTimes  =   r.PSTH.Events.Releases.Time{types(m)};
    pokeTimes           =   r.PSTH.Events.Pokes.Time;

    rng(12)
    % we plot 15 randomly selected examples. but we keep the order in a session
    nPlot = 15;

    indSelected = sort(randperm(length(pressTimes), nPlot));

    y_width = 3.45;

    tPre= 2000; % 2000 ms before press
    tPost = 4000; % 4000 ms after press
    nUnits = length(sdfUnitsSelectedSorted);
    pressColor = [247 182 45]/255;

    x_width = 1;

    for k =1:length(indSelected)

        ha_Press = axes('units', 'centimeters', 'position', [1+(k-1)*x_width*1.1 y_now x_width y_width],...
            'nextplot', 'add', 'xlim', [-tPre tPost], 'xtick', [-1000 0 1000 2000], 'xticklabel', {'-1', '0', '1', '2'}, ...
            'ylim', [0 nUnits],'ytick',(5:5:40), 'ydir', 'reverse', 'TickLength',[.0125 .1], 'Color', [.95 .95 .95]);
        box on

        ktPress = pressTimes(indSelected(k));
        ktRelease = releseTimes(indSelected(k));
        ktPoke = pokeTimes(find(pokeTimes>ktRelease, 1, 'first'));

        tRange = [ktPress-tPre ktPress+tPost];

        % draw press time, release time, and poke time
        line([0 nUnits], (k-1)*2000, 'color', 'w');

        plotshaded([0 ktRelease-ktPress], [0 0; nUnits nUnits], pressColor);
        line([1 1]*sdfUnitsSelectedSorted(k).fp(m), [0 nUnits], 'color', 'r'); % trigger
        line([1 1]*(ktPoke-ktPress), [0 nUnits], 'color', 'b'); % poke

        for i=1:nUnits

            ispk = sdfUnitsSelectedSorted(i).spk_time_ms;
            ispk = ispk(ispk>tRange(1) & ispk<tRange(2));
            if isempty(ispk)
                continue
            end
            ispk = ispk - ktPress;
            line([ispk;ispk], [i; i+0.8], 'color', 'k')
        end

        if k>1
            set(ha_Press, 'xtick', [], 'ytick', [])
            if k== nPlot
                title(['Trial #' num2str(nPlot)])
            end
            set(gca, 'ycolor', 'w')
        else
            xlabel('Time (s)')
            ylabel('Units')
            title(['Trial #' num2str(1)])
        end
    end
    y_now = y_now - y_width - 1.5;
end
styleAllAxesInFigure(fig)

 
meta = [r.BehaviorClass.Subject ' | ' r.BehaviorClass.Date ' | ' r.BehaviorClass.Protocol];
annotation('textbox', 'String', meta, ...
    'units', 'normalized', ...
    'Position', [.1 .95 .9 .05], ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'bottom', ...
    'FontSize', 10, ...
    'FontWeight', 'bold',...
    'FontName', myFont,...
    'EdgeColor','none');


this_dir = pwd;

if ~exist(fullfile(this_dir, 'Figure'), 'dir')
    mkdir(fullfile(this_dir, 'Figure'))
end
tosavename = fullfile(this_dir, 'Figure', ['Fig_Neuropixels_SingleSession_' r.BehaviorClass.Subject '_' r.BehaviorClass.Date '_' r.BehaviorClass.Protocol]);
print (fig,'-dpng', tosavename)
print (fig,'-dpdf', tosavename)
end