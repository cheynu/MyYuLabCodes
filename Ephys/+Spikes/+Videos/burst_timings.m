function burout = burst_timings(r, ind_unit, th, toplot)
% 12/28/2024
% extract times when there are transient increase of neural activities. 
if nargin<4
    toplot = 1;
    if nargin<3
        th = 0.95;
    end
end
if length(ind_unit)>1
    ch = ind_unit(1);
    un = ind_unit(2);
    ind_unit     = find(r.Units.SpikeNotes(:, 1)== ch & r.Units.SpikeNotes(:, 2)== un);
end
PSTH = Spikes.SRT.SRTSpikes(r, ind_unit); % so we don't rely on r having a PSTH field anymore

press_on    = sort(cell2mat(PSTH.Presses.Time([1 2 3 4])')/1000); % all press taken into consideration
press_off = sort(cell2mat(PSTH.Releases.Time')/1000); % all releases taken into consideration
% Poke events
poke_on = sort(cell2mat(PSTH.Pokes.RewardPoke.Time)/1000); % all releases taken into consideration

spts            =    r.Units.SpikeTimes(ind_unit).timings; % spike times in ms
spts            =    spts/1000; % convert to seconds
nsp             =    length(spts);
dtStim          =    50/1000; % bin size is 50 ms
max_spt         = max(spts)*1.2;
tbins_edges     = 0:dtStim:max_spt;
tbins_centers   = tbins_edges(1:end-1)+dtStim/2;
nT = length(tbins_centers);
max_spt         =    max(spts)*1.2;
% spikes are binned with a bin size of dtStim
sps                     =       histcounts(spts,tbins_edges)';  % binned spike train
sps_rate              =       sps/dtStim;
sps_smoothed    =       smoothdata(sps, 'gaussian', 11)/dtStim; % this is spk rate, smoothed

t_check = 10*60; % every 5 min
tnow = tbins_edges(1);

t_bursts = [];
sps_burst = [];

surprise_poisson = [];
tsurprise_poisson = [];
t_bursts_poisson = [];

% for computing surprising scores
twin = 0.25; % every 0.1 second
while tnow+t_check<tbins_edges(end)
    ind_block = find(tbins_edges>=tnow & tbins_edges<tnow+t_check);
    t_block = tbins_edges(ind_block);
    sps_block = sps_smoothed(ind_block);
    tf = find(sps_block>quantile(sps_smoothed, th));
    t_bursts = [t_bursts t_block(tf)];
    sps_burst = [sps_burst transpose(sps_block(tf))];
    
    spts_block = spts(spts>=tnow & spts<tnow+t_check);
    baseline_rate = length(spts_block)/t_check;

    if ~isempty(spts_block)
        [surprise_scores, t_scores] = Spikes.poisson_surprise(spts_block, baseline_rate, twin, t_check);
        [peaks, peaks_loc] = findpeaks(surprise_scores,...
            'MinPeakHeight', quantile(surprise_scores, .99), ...
            'MinPeakDistance', 5000,...
            'MinPeakWidth', 10);
        surprise_poisson = [surprise_poisson surprise_scores];
        tsurprise_poisson = [tsurprise_poisson t_scores];
        t_bursts_poisson = [t_bursts_poisson t_scores(peaks_loc)];
        % figure(19); clf(19)
        % plot(t_scores, surprise_scores, 'k');
        % hold on
        % scatter(t_scores(peaks_loc), surprise_scores(peaks_loc), '+', 'sizedata', 100, ...
        %     'markeredgecolor', 'r')
    end
    tnow = tnow + t_check;
end

% merge t_bursts
tmin = 1; % 1 second
diff_t = diff(t_bursts);
ind_long_enough = find(diff_t>tmin);
burst_onsets = t_bursts([1 ind_long_enough+1]);
burst_offsets = t_bursts([ind_long_enough end]);

min_dur = 0.5; % at least 0.25 second long
ind_tooshort = find((burst_offsets-burst_onsets)<min_dur);
burst_onsets(ind_tooshort)=[];
burst_offsets(ind_tooshort)=[];
burst_rate = ones(1, length(burst_onsets));
y_range = max(sps_smoothed)*1.2;

% merge t_bursts (poisson)
surprise_poisson_smoothed = smoothdata(surprise_poisson, 'gaussian', 51);
y_range2 = quantile(surprise_poisson_smoothed, 0.99)*2;
tf = find(surprise_poisson_smoothed>quantile(surprise_poisson_smoothed, 0.975));
t_bursts2 = tsurprise_poisson(tf);
tmin = 1; % 1 second
diff_t = diff(t_bursts2);
ind_long_enough = find(diff_t>tmin);
burst_onsets2 = t_bursts2([1 ind_long_enough+1]);
burst_offsets2 = t_bursts2([ind_long_enough end]);
min_dur = 0.5; % at least 0.25 second long
ind_tooshort = find((burst_offsets2-burst_onsets2)<min_dur);
burst_onsets2(ind_tooshort)=[];
burst_offsets2(ind_tooshort)=[];
burst_rate2 = ones(1, length(burst_onsets2));

figure(316);
clf(316);
burst_color = [50, 205, 50]/255;
set(gcf, 'position', [250 250 1200 600])
t = tiledlayout(5, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

tseg = 3; % 3 min of data
tplot = [median(t_bursts) median(t_bursts)+tseg*60];
nexttile([1 2]); hold on
% Plot press
% press_on    = sort(cell2mat(PSTH.Presses.Time([1 2 3 4])')/1000); % all press taken into consideration
% press_off = sort(cell2mat(PSTH.Releases.Time')/1000); % all releases taken into consideration
% % Poke events
% poke_on = sort(cell2mat(PSTH.Pokes.RewardPoke.Time)/1000); % all releases taken into consideration
for i =1:length(press_on)
    tpress_i = press_on(i);
    if tpress_i >tplot(1) && tpress_i<tplot(2)
        ind_release = find(press_off>tpress_i, 1, 'first');
        trelease_i =press_off(ind_release);
        if ~isempty(trelease_i) && trelease_i-tpress_i<5
            plotshaded([tpress_i trelease_i], [0 0; y_range y_range], [0.6 0.6 0.6])
            ind_poke = find(poke_on>trelease_i, 1, 'first');
            if ~isempty(ind_poke)
                line([poke_on(ind_poke) poke_on(ind_poke)], [0 y_range],'color',  'm', 'linewidth', 1, 'linestyle', '-.')
            end
        end
    end
end

ind_spts = find(spts>tplot(1) & spts<tplot(2));
scatter(spts(ind_spts),max(sps_smoothed)+rand(1, length(ind_spts))*0.2*max(sps_smoothed), '.', 'black')

for i =1:length(burst_onsets)
    plotshaded([burst_onsets(i) burst_offsets(i)], [0 0; y_range y_range], burst_color);
    burst_rate(i) = sum(spts>=burst_onsets(i) & spts<burst_offsets(i))/(burst_offsets(i)-burst_onsets(i));
end

plot(tbins_edges(1:end-1), sps_smoothed, 'k');
scatter(t_bursts(t_bursts>tplot(1) & t_bursts<tplot(2)), sps_burst(t_bursts>tplot(1) & t_bursts<tplot(2)), 'red', '.')
set(gca, 'xlim', tplot, 'ylim', [0 y_range]);
ylabel('spiking rate')

burout.subject = r.BehaviorClass.Subject;
burout.date = r.BehaviorClass.Date;
burout.unit = [r.Units.SpikeNotes(ind_unit, 1) r.Units.SpikeNotes(ind_unit, 2)];
title([burout.subject ' | ' burout.date ' | ch' num2str(burout.unit(1)) ' | unit' num2str(burout.unit(2)) ])
set(gca, 'XTick', []); %
nexttile([1 2]);
hold on
for i =1:length(press_on)
    tpress_i = press_on(i);
    if tpress_i >tplot(1) && tpress_i<tplot(2)
        ind_release = find(press_off>tpress_i, 1, 'first');
        trelease_i =press_off(ind_release);
        if ~isempty(trelease_i) && trelease_i-tpress_i<5
            plotshaded([tpress_i trelease_i], [0 0; y_range2 y_range2], [0.6 0.6 0.6])
            ind_poke = find(poke_on>trelease_i, 1, 'first');
            if ~isempty(ind_poke)
                line([poke_on(ind_poke) poke_on(ind_poke)], [0 y_range2],'color',  'm', 'linewidth', 1, 'linestyle', '-.')
            end
        end
    end
end

for i =1:length(burst_onsets2)
    plotshaded([burst_onsets2(i) burst_offsets2(i)], [0 0; y_range y_range], burst_color);
    burst_rate2(i) = sum(spts>=burst_onsets2(i) & spts<burst_offsets2(i))/(burst_offsets2(i)-burst_onsets2(i));
end
plot(tsurprise_poisson, surprise_poisson_smoothed, 'b', 'linewidth',1);
line([t_bursts_poisson; t_bursts_poisson], [0 y_range2], 'color', 'r', 'linewidth', 0.5)
set(gca, 'xlim', tplot, 'ylim', [0 y_range2]);
ylabel('log(p)')
set(gca, 'XTick', []); %
% plot another segments
tplot = [quantile(t_bursts, 0.7) quantile(t_bursts, 0.7)+tseg*60];
nexttile([1 2]); hold on
% Plot press
% press_on    = sort(cell2mat(PSTH.Presses.Time([1 2 3 4])')/1000); % all press taken into consideration
% press_off = sort(cell2mat(PSTH.Releases.Time')/1000); % all releases taken into consideration
% % Poke events
% poke_on = sort(cell2mat(PSTH.Pokes.RewardPoke.Time)/1000); % all releases taken into consideration
for i =1:length(press_on)
    tpress_i = press_on(i);
    if tpress_i >tplot(1) && tpress_i<tplot(2)
        ind_release = find(press_off>tpress_i, 1, 'first');
        trelease_i =press_off(ind_release);
        if ~isempty(trelease_i) && trelease_i-tpress_i<5
            plotshaded([tpress_i trelease_i], [0 0; y_range y_range], [0.6 0.6 0.6])
            ind_poke = find(poke_on>trelease_i, 1, 'first');
            if ~isempty(ind_poke)
                line([poke_on(ind_poke) poke_on(ind_poke)], [0 y_range],'color',  'm', 'linewidth', 1, 'linestyle', '-.')
            end
        end
    end
end

ind_spts = find(spts>tplot(1) & spts<tplot(2));
scatter(spts(ind_spts),max(sps_smoothed)+rand(1, length(ind_spts))*0.2*max(sps_smoothed), '.', 'black')

for i =1:length(burst_onsets)
    plotshaded([burst_onsets(i) burst_offsets(i)], [0 0; y_range y_range], burst_color);
    burst_rate(i) = sum(spts>=burst_onsets(i) & spts<burst_offsets(i))/(burst_offsets(i)-burst_onsets(i));
end

plot(tbins_edges(1:end-1), sps_smoothed, 'k');
scatter(t_bursts(t_bursts>tplot(1) & t_bursts<tplot(2)), sps_burst(t_bursts>tplot(1) & t_bursts<tplot(2)), 'red', '.')
set(gca, 'xlim', tplot, 'ylim', [0 y_range]);

burout.subject = r.BehaviorClass.Subject;
burout.date = r.BehaviorClass.Date;
burout.unit = [r.Units.SpikeNotes(ind_unit, 1) r.Units.SpikeNotes(ind_unit, 2)];
set(gca, 'XTick', []); %
ylabel('spiking rate')

nexttile([1 2]); hold on
for i =1:length(press_on)
    tpress_i = press_on(i);
    if tpress_i >tplot(1) && tpress_i<tplot(2)
        ind_release = find(press_off>tpress_i, 1, 'first');
        trelease_i =press_off(ind_release);
        if ~isempty(trelease_i) && trelease_i-tpress_i<5
            plotshaded([tpress_i trelease_i], [0 0; y_range2 y_range2], [0.6 0.6 0.6])
            ind_poke = find(poke_on>trelease_i, 1, 'first');
            if ~isempty(ind_poke)
                line([poke_on(ind_poke) poke_on(ind_poke)], [0 y_range2],'color',  'm', 'linewidth', 1, 'linestyle', '-.')
            end
        end
    end
end

for i =1:length(burst_onsets2)
    plotshaded([burst_onsets2(i) burst_offsets2(i)], [0 0; y_range y_range], burst_color);
    burst_rate2(i) = sum(spts>=burst_onsets2(i) & spts<burst_offsets2(i))/(burst_offsets2(i)-burst_onsets2(i));
end

plot(tsurprise_poisson, surprise_poisson_smoothed, 'b', 'linewidth',1);
line([t_bursts_poisson; t_bursts_poisson], [0 y_range2], 'color', 'r', 'linewidth', 0.5)
set(gca, 'xlim', tplot, 'ylim', [0 y_range2]);
ylabel('log(p)')
xlabel('time (s)')
set(gca, 'XTick', []); %
% burout.time = t_bursts;
% burout.spk_rate=sps_burst;
burout.onset = burst_onsets;
burout.offset = burst_offsets;
burout.burst_rate = burst_rate;
burout.n_burst = length(burst_onsets);
burout.poisson_surprises = [tsurprise_poisson; surprise_poisson];
burout.tpeaks_poisson_surprises = t_bursts_poisson;

burout.onset_poisson = burst_onsets2;
burout.offset_poisson = burst_offsets2;
burout.burst_rate_poisson = burst_rate2;
burout.n_burst_poisson = length(burst_onsets2);

% add spike trains 
sdf_out = sdf_spktimes(spts, spts(end), 25);
spks_in_bursts = cell(2, length(burst_onsets2));
for i =1:length(burst_onsets2)

    ispts = spts(spts>=burst_onsets2(i)-0.1 & spts<burst_offsets2(i)+0.1);
    spks_in_bursts{1, i} = ispts;
    ind_sdf = find(sdf_out(:, 1)/1000>=burst_onsets2(i)-0.1 & sdf_out(:, 1)/1000<burst_offsets2(i)+0.1);
    spks_in_bursts{2, i} = sdf_out(ind_sdf, :);

end
burout.spikes_in_bursts = spks_in_bursts;
burout.sdf_all = sdf_out;

nexttile; 
violinplot(burst_rate);
title('bursting rate (hz)')
nexttile; 
violinplot(burst_offsets2-burst_onsets2);
legend(sprintf('%2.0d',  length(burst_onsets2)))
title('bursting duration poisson (sec)')

if toplot
    thisFolder = fullfile(pwd, 'Bursting_Figs');
    if ~exist(thisFolder, 'dir')
        mkdir(thisFolder)
    end
    % burout.subject = r.BehaviorClass.Subject;
    % burout.date = r.BehaviorClass.Date;
    % burout.unit = [r.Units.SpikeNotes(ind_unit, 1) r.Units.SpikeNotes(ind_unit, 2)];

    tosavename2= fullfile(thisFolder, [ burout.subject  '_' burout.date '_Ch'  num2str(r.Units.SpikeNotes(ind_unit, 1)) '_Unit' num2str(r.Units.SpikeNotes(ind_unit, 2)) ]);
    print (gcf,'-dpng', tosavename2)
    % save PSTH as well save(psth_new_name, 'PSTHOut');
    save([tosavename2 '.mat'], 'burout')
end