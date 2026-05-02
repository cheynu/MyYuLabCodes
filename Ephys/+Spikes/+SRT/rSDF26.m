function [Out, spk_data_tab] = rSDF26(r, id)
% Out, spk_data_tab] = rSDF26(r, id)
% 3.9.2024 plot a simple version of PSTH
% 4/23/2024 Plot warped PSTH
% 2025.6.5 revised from PlotPSTHLiteWarped to simply the code
% 2025.08.11 We should also warp sdf for each FPs, aligned to press time. 
% 2025.08.13 add code to extract firing rate dynamics when there is no
% actiivty (10 seconds of activity in the absence of any behavioral events)
% This is useful for computing z score. 
% 2025.09.04 add an event table for further references. 

% 2025.12.31 new revision: remove the need to take data from r.PopPSTH (we
% have retired that field). Add 26. JY

% 2026.1.20 for wait task
tic

% figure out which unit it is
spk_note =r.Units.SpikeNotes;

if length(id) == 2
    ind_unit = find(spk_note(:, 1)==id(1) & spk_note(:, 2)==id(2));
else
    ind_unit = id;
    id = [spk_note(id, 1) spk_note(id, 2)];
end
Out.subject                     =       r.BehaviorClass.Subject;
Out.session                     =       r.BehaviorClass.Date;
Out.unit_id                     =       [Out.subject '_' Out.session '_Ch' num2str(r.Units.SpikeNotes(ind_unit, 1)) '_Unit' num2str(r.Units.SpikeNotes(ind_unit, 2))];
Out.unit.index                  =       ind_unit;
Out.unit.ch                     =       [r.Units.SpikeNotes(ind_unit, 1) r.Units.SpikeNotes(ind_unit, 2)];
Out.events                      =       r.EventTable;
beh_tab                             =       r.EventTable; % give it a simple name
FPs                                 =       r.BehaviorClass.MixedFP;
Out.fps                         =       FPs;
%extract spike wave forms, spikes times, and conver spike times to 0 and 1
Out.unit.waves = r.Units.SpikeTimes(ind_unit).wave;

if size(Out.unit.waves, 1)>50
    Out.unit.waves = Out.unit.waves(randperm(size(Out.unit.waves, 1), 50), :);
end

if isfield(r.Units.SpikeTimes(ind_unit), 'wave_mean') % for Neuropixels recordings, this are all the waves.
    Out.unit.wave_mean = r.Units.SpikeTimes(ind_unit).wave_mean;
end

if isfield(r, 'ChanMap')
    wave_out = Spikes.waveLoc(r, r.Units.SpikeNotes(ind_unit, 1), r.Units.SpikeNotes(ind_unit, 2));
    Out.unit.wave_location = wave_out;
end

spktimes = r.Units.SpikeTimes(ind_unit).timings; % in ms
[tSpk, spkVec] = spike_to_sparse(spktimes); % this generates a sparse vector representing the spike train
[ar, lags]=xcorr(full(spkVec), 25, 'unbiased');
ar(lags==0)=0;
nFPs = length(FPs);

Out.unit.spike_times_ms    =      spktimes;
Out.unit.spike_sparse_ms   =      [tSpk' spkVec]; % sparse matrix representing spikes
Out.unit.auto_correlation = [lags' ar];

%% Added on 8/13/2025 find out periods without any behavioral engagement
% these are all the event times
event_times = sort([beh_tab.t_press; beh_tab.t_trigger; beh_tab.t_release; beh_tab.t_poke]);

tmin = min(spktimes);
tmax = max(spktimes);

tstep = 5*1000; % 5 sec step
twin = 10*1000; % 10 sec window
sigma_kernel = 50; % gaussian kernel to make spike density function
dt = 1; % time bins, 1 ms

tnow = tmin;
baseline_sdf = [];
t_baseline_sdf = [];
baseline_timing = [];

while tnow +twin<tmax
    this_win = [tnow tnow+twin];
    if any(event_times>(this_win(1)) & event_times<(this_win(2)))
        tnow = tnow + tstep;
    else
        spktimes_this   =   spktimes(spktimes>this_win(1) & spktimes>this_win(1)<this_win(2));
        [spkout, tspk]  =   sdf25(spktimes_this, this_win, sigma_kernel, dt);  %  spkout=sdf(tspk, spkin, kernel_width
        baseline_sdf    =   [baseline_sdf; spkout];
        t_baseline_sdf  =   [t_baseline_sdf; tspk];
        baseline_timing =   [baseline_timing mean(this_win)];
        tnow            =   tnow+twin;
    end
end

Out.baseline.description            = 'these were extracted from 10 s of data when rats are not doing the task';
Out.baseline.sdf                    = baseline_sdf;
Out.baseline.t_sdf                  = t_baseline_sdf;
Out.baseline.mean                   = mean(baseline_sdf);
Out.baseline.t_mean                 = t_baseline_sdf(1, :)-t_baseline_sdf(1,1);
Out.baseline.timing                 = baseline_timing;
Out.baseline.timing_description     = 'these are the times of the extracted segments';

% Events 
events = {'press','trigger','release','poke'};
pre  = struct('press',2500,'trigger',200,'release',500,'poke',500);
post = struct('press',500,'trigger',300,'release',1000,'poke',1000);
sdf_struct = Spikes.SRT.build_sdf_table(spktimes, beh_tab, ...
    'Events', events, ...
    'Pre', pre, ...
    'Post', post, ...
    'SigmaKernel', sigma_kernel, ...
    'Dt', 1, ...
    'SdfPad', 5*sigma_kernel, ...
    'EventTimePrefix', 't_', ...
    'OutcomeVar', 'outcome', ...
    'TypeVar', 'type', ...
    'FPVar', 'FP');
% [sdf_struct, spk_data_tab] = Spikes.SRT.build_sdf_and_spkcount_table( ...
%     spktimes, beh_tab, ...
%     'Events', events, ...
%     'Pre', pre, ...
%     'Post', post, ...
%     'SigmaKernel', sigma_kernel, ...
%     'SdfPad', 5*sigma_kernel,...
%     'Dt', dt, ...
%     'SpkCountRange', spk_count_range, ...
%     'BinSize', bin_size);

% ------ build spike count table ------
spk_count_range = struct();
spk_count_range.press   = [-2000 500];
spk_count_range.trigger = [-200 500];
spk_count_range.release = [-500 1000];
spk_count_range.poke    = [-200 500];
bin_size = 50;

spk_data_tab = Spikes.SRT.build_spkcount_table( ...
    spktimes, beh_tab, ...
    'Events', events, ...
    'SpkCountRange', spk_count_range, ...
    'BinSize', bin_size, ...
    'EventTimePrefix', 't_', ...
    'OutcomeVar', 'outcome', ...
    'TypeVar', 'type', ...
    'FPVar', 'FP');

Out.sdfs_trials                 =   sdf_struct;
Out.spk_data_tab                =   spk_data_tab;
Out.meta.sdf_pre                =   pre;
Out.meta.sdf_post               =   post;
Out.meta.sdf_sigma_kernel       =   sigma_kernel;
Out.meta.spk_count_range        =   spk_count_range;
Out.meta.spk_count_bin          =   bin_size;

fig_num = 26;

fig_x = 2;
fig_y = 2;
fig_width = 18;
fig_height = 8;

hf = start_fig('fig', fig_num, 'name', 'sdf_curve', ...
    'position', [fig_x, fig_y, fig_width, fig_height]);

% sdf_collection
sdf_conc = [];
events = {'press', 'trigger', 'release', 'poke'};

panel_height = 4;

xp = 1.5;
yp = 1.5;
h_spacing = 0.25;

t_bound = 0; % no longer useful
max_sdf = 0;

for i = 1:length(events)
    event = events{i};
    ind_valid = ~strcmp(beh_tab.outcome, 'Dark');

    if ~strcmp(event, 'release')
        all = arrayfun(@(x)x.(event).data_sdf, sdf_struct(ind_valid), 'UniformOutput', false);
        mean_sdf = mean(transpose(cell2mat(all')), 2);
        max_sdf = max(max_sdf, max(mean_sdf));
    else
        % Correct
        ind = strcmp(beh_tab.outcome, 'Correct');
        all = arrayfun(@(x)x.(event).data_sdf, sdf_struct(ind), 'UniformOutput', false);
        mean_sdf = mean(transpose(cell2mat(all')), 2);
        max_sdf = max(max_sdf, max(mean_sdf));
        % Incorrect
        ind = strcmp(beh_tab.outcome, 'Premature') | strcmp(beh_tab.outcome, 'Late');
        all = arrayfun(@(x)x.(event).data_sdf, sdf_struct(ind), 'UniformOutput', false);
        mean_sdf = mean(transpose(cell2mat(all')), 2);
        max_sdf = max(max_sdf, max(mean_sdf));
    end
end

ylim_shared = [0, 2 * max_sdf];
ylim_shared(2) = max(ylim_shared(2), 4);

unit_width = 1.5/500;
shade_col = [172, 186, 196]/255;
shade_col_incorrect = '#FA5C5C';
sdf_events = struct('press', [], 'trigger', [], ...
    'release_correct', [],'release_incorrect', [], 'poke', []);
% outcome is to test whether the neuron is modulated by correct or
% incorrect leverl release
n_plot = 30; % plot 30 trials of rasters

for i =1:length(events)
    % extract trigger
    event = events{i};

    if ~strcmp(event, 'release')
        ind = ~strcmp(beh_tab.outcome, 'Dark');       
        [mean_data, ci_data, t_data] = cal_mean_ci(sdf_struct, ind, event, t_bound, pre, post);
                
        sdf_events.(event).trial_index = ind;
        sdf_events.(event).data.t = t_data;
        sdf_events.(event).data.mean = mean_data;
        sdf_events.(event).data.ci = ci_data;

        sdf_conc = [sdf_conc mean_data];

        panel_width = unit_width*(t_data(end)-t_data(1));

        ha = start_axes(hf, [xp yp panel_width panel_height], ...
            'xlim', [0 1], ...
            'ylim',  ylim_shared, ...
            'ytick', round(linspace(0, ylim_shared(2), 3)), ...
            'ygrid', 'off', 'fontsize', 9);
        xlabel(sprintf('%s (ms)', event))

        plotshaded(t_data, ci_data, shade_col);
        plot(ha, t_data, mean_data, 'k-', 'LineWidth', 1.5);
        ha.XLim = [min(t_data) max(t_data)];
        xline(ha, 0, 'Color','b');

        if strcmp(event, 'press')
            ylabel('FR (hz)');
        else
            ha.YTickLabel = [];
        end

        % add spike raster
        ha_raster = start_axes(hf, [xp yp+panel_height/2 panel_width panel_height], ...
            'xlim', [0 1], ...
            'ylim',  [0 2*n_plot], ...
            'ytick', round(linspace(0, ylim_shared(2), 4)), ...
            'ygrid', 'off');

        ha_raster.YDir = 'reverse';
        ind = find(ind);
        ind = sort(ind(randperm(length(ind), min(n_plot, length(ind)))));
        for k =1:length(ind)

            x = sdf_struct(ind(k)).(event).spk_times;
            % force column + remove NaNs
            x = x(:);
            x = x(~isnan(x));

            if ~isempty(x)
                yTop = k;
                yBottom = k-1;
                n = numel(x);
                % Build 3-by-n segments: [x; x; nan], [yTop; yBottom; nan]
                X = [x.'; x.'; nan(1, n)];
                Y = [repmat(yTop,    1, n); ...
                    repmat(yBottom, 1, n); ...
                    nan(1, n)];
                line(ha_raster, X(:), Y(:), 'Color', 'k', 'LineWidth', 1.5);
            end
        end
        ha_raster.Color = 'none';
        ha_raster.XLim = [min(t_data) max(t_data)];
        axis off
        xp = xp + panel_width + h_spacing;

    else

        ind = ~strcmp(beh_tab.outcome, 'Dark');
        % Correct release
        ind = strcmp(beh_tab.outcome, 'Correct');
        [mean_data, ci_data, t_data] = cal_mean_ci(sdf_struct, ind, event, t_bound, pre, post);

        event_ = [event '_correct'];
        sdf_events.(event_).trial_index = ind;
        sdf_events.(event_).data.t = t_data;
        sdf_events.(event_).data.mean = mean_data;
        sdf_events.(event_).data.ci = ci_data;
        sdf_conc = [sdf_conc mean_data];

        panel_width = unit_width*(t_data(end)-t_data(1));
        ha = start_axes(hf, [xp yp panel_width panel_height], ...
            'xlim', [0 1], ...
            'ylim', ylim_shared, ...
            'ytick', round(linspace(0, ylim_shared(2), 4)), ...
            'ygrid', 'off', 'fontsize', 9);
        xlabel(sprintf('%s (ms)', event))
        % plot sd
        axes(ha)
        plotshaded(t_data, ci_data, shade_col);
        plot(ha, t_data, mean_data, 'k-', 'LineWidth', 1.5);
        ha.XLim = [min(t_data) max(t_data)];
        ha.YTickLabel = [];

        % add spike raster
        ha_raster = start_axes(hf, [xp yp+panel_height/2 panel_width panel_height], ...
            'xlim', [0 1], ...
            'ylim',  [0 2*n_plot], ...
            'ytick', round(linspace(0, ylim_shared(2), 4)), ...
            'ygrid', 'off');

        ha_raster.YDir = 'reverse';

        ind = find(ind);
        ind = sort(ind(randperm(length(ind), min(n_plot, length(ind)))));

        for k =1:length(ind)

           x = sdf_struct(ind(k)).(event).spk_times;
            % force column + remove NaNs
            x = x(:);
            x = x(~isnan(x));

            if ~isempty(x)
                yTop = k;
                yBottom = k-1;
                n = numel(x);
                % Build 3-by-n segments: [x; x; nan], [yTop; yBottom; nan]
                X = [x.'; x.'; nan(1, n)];
                Y = [repmat(yTop,    1, n); ...
                    repmat(yBottom, 1, n); ...
                    nan(1, n)];
                line(ha_raster, X(:), Y(:), 'Color', 'k', 'LineWidth', 1.5);
            end
        end
        ha_raster.Color = 'none';
        ha_raster.XLim = [min(t_data) max(t_data)];
        axis off
        xp = xp + panel_width + h_spacing;

        % Incorrect release
        ind = strcmp(beh_tab.outcome, 'Premature') | strcmp(beh_tab.outcome, 'Late');
        [mean_data, ci_data, t_data] = cal_mean_ci(sdf_struct, ind, event, t_bound, pre, post);
        
        event_ = [event '_incorrect'];
        sdf_events.(event_).trial_index = ind;
        sdf_events.(event_).data.t = t_data;
        sdf_events.(event_).data.mean = mean_data;
        sdf_events.(event_).data.ci = ci_data;
        axes(ha)
        plotshaded(t_data, ci_data, shade_col_incorrect);
        plot(ha, t_data, mean_data, 'r-.', 'LineWidth', 1.5);
        xline(ha, 0, 'Color','b');

        ind = find(ind);
        ind = sort(ind(randperm(length(ind), min(n_plot, length(ind)))));

        for k =1:length(ind)

           x = sdf_struct(ind(k)).(event).spk_times;
            % force column + remove NaNs
            x = x(:);
            x = x(~isnan(x));

            if ~isempty(x)
                yTop = k+n_plot;
                yBottom = k-1+n_plot;
                n = numel(x);
                % Build 3-by-n segments: [x; x; nan], [yTop; yBottom; nan]
                X = [x.'; x.'; nan(1, n)];
                Y = [repmat(yTop,    1, n); ...
                    repmat(yBottom, 1, n); ...
                    nan(1, n)];
                line(ha_raster, X(:), Y(:), 'Color', 'r', 'LineWidth', 1.5);
            end
        end
end
end

hf = figure(hf);
hf.Position(3) = xp+.5;
hf.Position(4) = yp + panel_height+2+1;

[~, sdf_events.max_location] = max(sdf_conc);
sdf_events.conc = sdf_conc;
sdf_events.mean = mean(sdf_conc);
sdf_events.range = max(sdf_conc)-min(sdf_conc);
sdf_events.sd   = std(sdf_conc);
sdf_events.unit = Out.unit_id;

% Add information
annotation('textbox', ...
    'Units','centimeters', ...
    'Position',[0.1 hf.Position(4)-0.5 hf.Position(3)*0.9 0.5], ...
    'String',sprintf('%s | max %d',Out.unit_id, sdf_events.max_location), ...
    'Interpreter','none', ...
    'FitBoxToText','off', ...
    'BackgroundColor','w', ...
    'EdgeColor','none', ...
    'FontName','DejaVu Sans', ...
    'FontWeight','bold', ...
    'FontSize',10, ...
    'HorizontalAlignment','left', ...
    'VerticalAlignment','middle');


% Compute event modulation
% [stat_out, stat_table, spk_count_table] = Spikes.rPSTH_glme26(Out);
% Out.glm_results.stat_out        =   stat_out;
% Out.glm_results.table           =   stat_table;
% Out.glm_results.spk_count       =   spk_count_table;

Out.sdfs_event                  =   sdf_events;

Out.meta.date                   =       datetime;
Out.meta.pwd                    =       pwd;
Out.meta.code                   =       sprintf('Spikes.SRT.rSDF26(r, [%d, %d])', r.Units.SpikeNotes(ind_unit, 1), r.Units.SpikeNotes(ind_unit, 2));

figName = sprintf('sdf_events_%s', Out.unit_id);
outFolder = fullfile(pwd, 'Fig');
save_fig(hf, figName, outFolder, 'Formats', {'png'});      % png only
toc
end

function [mean_data, ci_data, t_data] = cal_mean_ci(sdf_struct, ind, event, t_bound, pre, post)

all = arrayfun(@(x)x.(event).data_sdf, sdf_struct(ind), 'UniformOutput', false);
all = cell2mat(all');
mean_sdf = mean(all, 1);
% sd_sdf = std(all, 0, 2);
t_sdf = arrayfun(@(x)x.(event).t_sdf, sdf_struct(ind), 'UniformOutput', false);
t_sdf = cell2mat(t_sdf');
t_sdf = t_sdf(1, :);
ind = find(t_sdf>=-(pre.(event)-t_bound) & t_sdf<=post.(event)-t_bound);
t_data = t_sdf(ind);
mean_data = mean_sdf(ind);
all = all(:, ind);
% se_data = transpose(sd_sdf(ind))
ci_data = bootci(1000, @mean, all);
 
end