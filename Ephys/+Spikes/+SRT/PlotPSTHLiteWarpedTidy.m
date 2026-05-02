function WarpOut = PlotPSTHLiteWarpedTidy(r, id, toplot)
% PlotPSTHLiteWarpedTidy - Plot warped PSTHs and rasters for neural data.
% Inputs:
%   r        - Struct containing spike and event data.
%   id       - [channel, unit] identifier for the unit to plot.
%   toplot   - Boolean to save and display the figure (default: true).
% Outputs:
%   WarpOut  - Struct containing PSTH, raster, and waveform data.
%
% Created: 3/9/2024
% Updated: 5/17/2025

%% Input Validation
if nargin < 3, toplot = true; end
validate_inputs(r, id, toplot);

%% Configuration
cfg = struct();
cfg.FPs = r.PopPSTH.FPs;
cfg.nFPs = length(cfg.FPs);
cfg.colors = struct( ...
    'press', [5, 5, 5]/255, ...
    'trigger', [242, 182, 250]/255, ...
    'release', [87, 108, 188]/255, ...
    'poke', [164, 208, 164]/255, ...
    'FP', [76, 61, 61; 192, 127, 0; 255, 217, 90]/255 ...
    );
cfg.ranges = struct( ...
    'press', [-2500, 2500], ...
    'release', [-1000, 1000],...
    'poke', [-1000 1000],...
    'warped', [-2000 5000]);

cfg.plot = struct( ...
    'fig_size', [2, 2, 17, 16], ...
    'x_size', 5, ...
    'y_size', 2, ...
    'y_size2', 2, ...
    'hspacing', 1, ...
    'vspacing', 0.5, ...
    'vspacing_raster', 0.25, ...
    'yrange', [0, 40], ...
    'FRmax', 20 ...
    );
cfg.pre = 5; % seconds before press
cfg.post = 5; % seconds after poke
cfg.post_keep = 2;
cfg.latency = 5; % max release to poke latency
cfg.sigma_kernel = 25; % SDF kernel width

%% Initialize Figure
hf = figure(73); clf;
set(hf, 'Units', 'centimeters', 'Position', cfg.plot.fig_size, ...
    'PaperPositionMode', 'auto', 'Renderer', 'Painters', 'Color', 'w');

%% Extract Unit Data
unit_data = extract_unit_data(r, id);
WarpOut.meta.anm = r.BehaviorClass.Subject;
WarpOut.meta.date = r.BehaviorClass.Date;
WarpOut.spike.unitID = [id(1), id(2) unit_data.ind_unit];
WarpOut.spike.times = unit_data.spk_times;
WarpOut.spike.waveforms = unit_data.spk_wave;

%% Process Spike Trains and Events
[spikes_trials, warped_data]    =   process_spike_trains(r, unit_data, cfg);
WarpOut.trials.events           =   spikes_trials(:, 1);
WarpOut.trials.spikes           =   spikes_trials(:, 2);
WarpOut.trials.t_warped         =   spikes_trials(:, 3);
WarpOut.trials.sdf_warped       =   spikes_trials(:, 4);
WarpOut.trials.FPs              =   spikes_trials(:, 5);
% WarpOut.sdf_warped              =   warped_data; % repetitive data

%% Plot Rasters and PSTHs
plot_rasters_and_psths(hf, r, unit_data, cfg);

%% Plot Spike Waveform
plot_spike_waveform(hf, unit_data.spk_wave, cfg);

%% Plot Autocorrelation
plot_autocorrelation(hf, unit_data.spk_times, cfg);

%% Plot Warped PSTH
plot_warped_psth(hf, warped_data, cfg);

%% Add Title
meta_to_print = sprintf('Rat:%s|Session:%s|Ch%0.2dUnit%0.2d|UnitIndex%0.2d',r.BehaviorClass.Subject,...
    r.BehaviorClass.Date, id(1), id(2), unit_data.ind_unit);

annotation('textbox', [0.01, 0.9, 0.8, 0.08], ...
    'String', meta_to_print, ...
    'FontName', 'DejaVu Sans', ...
    'FontSize', 12, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', 'w', ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'middle');

%% Two-part warped sdf
% warp psth in this way: approach to press: no change; press to
% press+750 ms, no change. trigger-250 ms to release: warp; release to
% poke: warp;
% function warp_out=warp_srt_sdfs_pooled(prp_sequence, prp_sdfs, toplot)
warp_out_pooled = process_trigger_sequences(r, unit_data.spk_times, cfg);
plot_warped_pooled_psth(hf, warp_out_pooled, cfg);

%% Save Figure
if toplot
    save_figure(r, id, hf);
end

%% Pack Output
WarpOut.spikes_trials = spikes_trials;
WarpOut.warped_data = warped_data;
WarpOut.pooled = warp_out_pooled;

styleAllAxesInFigureGeneral(hf);
end

%% Helper Functions

function validate_inputs(r, id, toplot)
% Validate input arguments
if ~isstruct(r) || ~isfield(r, 'Units') || ~isfield(r, 'PSTH')
    error('Input ''r'' must be a struct with ''Units'' and ''PSTH'' fields.');
end
if ~isvector(id) || length(id) ~= 2 || ~all(isnumeric(id))
    error('Input ''id'' must be a 2-element numeric vector [channel, unit].');
end
if ~islogical(toplot) && ~isnumeric(toplot)
    error('Input ''toplot'' must be a boolean or numeric value.');
end
end

function unit_data = extract_unit_data(r, id)
% Extract spike times and waveforms for the specified unit
spk_note = r.Units.SpikeNotes;
ind_unit = find(spk_note(:, 1) == id(1) & spk_note(:, 2) == id(2));
if isempty(ind_unit)
    error('Unit with ID [%d, %d] not found.', id(1), id(2));
end
unit_data.spk_wave = r.Units.SpikeTimes(ind_unit).wave;
unit_data.spk_times = r.Units.SpikeTimes(ind_unit).timings;
unit_data.ind_unit = ind_unit;
end

function [spikes_trials, warped_data] = process_spike_trains(r, unit_data, cfg)
% Process spike trains and compute warped SDFs
spikes_trials = cell(10000, 5);
warped_data = struct('t_warped', {}, 'sdf_warped', {}, 'sdf_mean', {}, 'sdf_ci', {}, 'time_points', {});
n_count = 0;

for fp_idx = 1:cfg.nFPs
    FP = cfg.FPs(fp_idx);
    [seq, spk_trains, sdfs] = extract_event_sequences(r, unit_data.spk_times, FP, cfg);
    % Warp SDFs
    [t_warped, sdf_warped, time_points] = warp_sdfs(seq, sdfs, FP, cfg);

    % Store results
    for j = 1:size(seq, 1)
        n_count = n_count + 1;
        spikes_trials{n_count, 1} = seq(j, :);
        spikes_trials{n_count, 2} = spk_trains{j};
        spikes_trials{n_count, 3} = t_warped;
        spikes_trials{n_count, 4} = sdf_warped(j, :);
        spikes_trials{n_count, 5} = FP;
    end
    warped_data(fp_idx).t_warped = t_warped;
    warped_data(fp_idx).sdf_warped_mean = mean(sdf_warped, 1);
    warped_data(fp_idx).sdf_wared_ci = bootci(1000, @mean, sdf_warped);
    warped_data(fp_idx).event_time_points = time_points;
end
spikes_trials = spikes_trials(1:n_count, :);
end

function [seq, spk_trains, sdfs] = extract_event_sequences(r, spk_times, FP, cfg)
% extract_event_sequences - Extract press-release-poke sequences and compute spike trains and SDFs.
% Inputs:
%   r         - Struct containing spike and event data.
%   spk_times - Spike times for the unit (in ms).
%   FP        - Foreperiod value (in ms).
%   cfg       - Configuration struct with parameters.
% Outputs:
%   seq       - Matrix of [press, release, poke] times.
%   spk_trains - Cell array of spike trains for each sequence.
%   sdfs      - Cell array of SDFs [time; sdf] for each sequence.

% Initialize outputs
seq = [];
spk_trains = {};
sdfs = {};

% Extract event times
press_times = sort(r.PSTH.Events.Presses.Time{r.PopPSTH.FPs == FP});
release_times = sort(r.PSTH.Events.Releases.Time{r.PopPSTH.FPs == FP});
poke_times = sort(r.PSTH.Events.Pokes.RewardPoke.Time{r.PopPSTH.FPs == FP});

% Match press-release-poke sequences
for j = 1:length(press_times)
    j_release = release_times(find(release_times >= press_times(j), 1, 'first'));
    if isempty(j_release), continue; end

    % Find the first poke after release
    j_poke = poke_times(find(poke_times > j_release, 1, 'first'));
    if isempty(j_poke) || (j_poke - j_release > cfg.latency * 1000), continue; end

    % Ensure no intervening press
    if ~isempty(find(press_times > j_release & press_times < j_poke, 1)), continue; end

    % Valid sequence found
    seq = [seq; press_times(j), j_release, j_poke];

    % Extract spike train
    total_dur = round(j_poke - press_times(j)) + cfg.pre * 1000 + cfg.post * 1000;
    this_spk = spk_times(spk_times >= press_times(j) - cfg.pre * 1000 & ...
        spk_times <= j_poke + cfg.post * 1000);
    spk_trains{end+1} = this_spk;

    % Compute SDF
    tspk = (0:total_dur-1) - cfg.pre * 1000; % Time in ms
    spkmat = zeros(1, total_dur);
    if ~isempty(this_spk)
        [~, ind_spikes] = intersect(round(tspk), round(this_spk - press_times(j)));
        spkmat(ind_spikes) = 1;
    end
    [spkout, tspkout] = sdf25(this_spk - press_times(j), [-cfg.pre * 1000, total_dur - cfg.pre * 1000], cfg.sigma_kernel, 1);
    sdfs{end+1} = [tspkout; spkout];
end
end

function plot_rasters_and_psths(hf, r, unit_data, cfg)
% Plot rasters and PSTHs for press, release, and poke events
events = {'press', 'release', 'poke'};
x_positions = [2, ...
    2 + cfg.plot.x_size + cfg.plot.hspacing, ...
    2 + cfg.plot.x_size + cfg.plot.hspacing + cfg.plot.x_size * diff(cfg.ranges.release) / diff(cfg.ranges.press) + cfg.plot.hspacing ];
y_now = 13;

for evt_idx = 1:3
    event = events{evt_idx};
    x_now = x_positions(evt_idx);
    y_now = 13;
    for fp_idx = 1:cfg.nFPs
        % Plot raster
        ha = axes('Units', 'centimeters', 'Position', [x_now, y_now, cfg.plot.x_size * diff(cfg.ranges.(lower(event))) / diff(cfg.ranges.press), cfg.plot.y_size2], ...
            'NextPlot', 'add', 'XLim', cfg.ranges.(lower(event)), 'YLim', [0, 21], 'YDir', 'reverse', 'YTick', [0, 20], ...
            'XTick', -2000:1000:2000, 'TickLength', [0.015, 0.1], 'Color', 'none');
        axis off;
        plot_raster(ha, r, unit_data, event, fp_idx, cfg);
        y_now = y_now - cfg.plot.y_size2 - cfg.plot.vspacing_raster;
    end
    % Plot PSTH
    ha = axes('Units', 'centimeters', 'Position', [x_now, y_now - cfg.plot.vspacing, cfg.plot.x_size * diff(cfg.ranges.(lower(event))) / diff(cfg.ranges.press), cfg.plot.y_size], ...
        'NextPlot', 'add', 'XLim', cfg.ranges.(lower(event)), 'YLim', cfg.plot.yrange, 'YTick', 0:20:100, ...
        'XTick', -2000:1000:2000, 'TickLength', [0.025, 0.1], 'Color', 'none');
    if evt_idx > 1, set(ha, 'YTickLabel', []); end
    plot_psth(ha, r, unit_data, event, cfg);
    if fp_idx == cfg.nFPs, xlabel(sprintf('Time from %s (ms)', event(1:end-1))); end
    if evt_idx == 1, ylabel('Spike rate (Hz)'); end
end
end

function [t_warped, sdf_warped, time_points] = warp_sdfs(seq, sdfs, FP, cfg)
% warp_sdfs - Warp SDFs based on median hold and movement times.
% Inputs:
%   seq       - Matrix of [press, release, poke] times.
%   sdfs      - Cell array of [time; sdf] matrices.
%   FP        - Foreperiod value (in ms).
%   cfg       - Configuration struct.
% Outputs:
%   t_warped  - Warped time points.
%   sdf_warped - Warped SDFs.
%   time_points - Template time points [0, FP, median_hold, median_total].

% Compute median durations
median_hold = median(seq(:, 2) - seq(:, 1)); % Press to release
median_move = median(seq(:, 3) - seq(:, 2)); % Release to poke

% Define template
jt_template = [0, FP, median_hold, median_hold + median_move];
time_points = jt_template;

% Warp SDFs
dt = 1; % 1 ms
jt_target_time = (0:dt:median_move + median_hold);
t_warptarget_first = jt_target_time(jt_target_time >= FP & jt_target_time < jt_template(3));
t_warptarget_second = jt_target_time(jt_target_time >= jt_template(3) & jt_target_time < jt_template(4));

sdf_warped = [];
for j = 1:size(seq, 1)
    jt = seq(j, :) - seq(j, 1); % Normalize to press time
    jsdf = sdfs{j};
    tsdf = jsdf(1, :);
    jsdf = jsdf(2, :);

    not_warped = jsdf(tsdf < FP);
    towarp_first = jsdf(tsdf >= FP & tsdf < jt(2));
    t_towarp_first = tsdf(tsdf >= FP & tsdf < jt(2));
    towarp_second = jsdf(tsdf >= jt(2) & tsdf < jt(3));
    t_towarp_second = tsdf(tsdf >= jt(2) & tsdf < jt(3));
    not_warped2 = jsdf(tsdf >= jt(3));
    not_warped2 = not_warped2(1:min(length(not_warped2), cfg.post_keep * 1000));

    if ~isempty(t_towarp_first) && ~isempty(t_towarp_second)
        sdf_warped_first = Spikes.SRT.warp_sdf(t_towarp_first, towarp_first, t_warptarget_first);
        sdf_warped_second = Spikes.SRT.warp_sdf(t_towarp_second, towarp_second, t_warptarget_second);
        new_sdf = [not_warped, sdf_warped_first, sdf_warped_second, not_warped2];
        sdf_warped = [sdf_warped; new_sdf];
    end
end

t_warped = (-cfg.pre * 1000:dt:length(new_sdf) - cfg.pre * 1000 - dt);
end

function plot_raster(ha, r, unit_data, event, fp_idx, cfg)
% Plot raster for a specific event and foreperiod.
switch event
    case 'press'
        here = 'Presses';
    case 'release'
        here = 'Releases';
    case 'poke'
        here = 'RewardPokes';
    otherwise
        error('Check event')
end
spkmat = r.PSTH.PSTHs(unit_data.ind_unit).(here){fp_idx}{3};
t_spkmat = r.PSTH.PSTHs(unit_data.ind_unit).(here){fp_idx}{4};
nplot = size(spkmat, 2);
line([0, 0], [0, nplot+1], 'Color', 'k', 'LineWidth', 1, 'Parent', ha);
if strcmp(here, 'Presses')
    line([cfg.FPs(fp_idx), cfg.FPs(fp_idx)], [0, nplot+1], 'Color', cfg.colors.trigger, 'LineWidth', 1, 'Parent', ha);
end
for k = 1:nplot
    xx = t_spkmat(spkmat(:, k) == 1);
    yy = [0, 0.8] + k;
    if ~isempty(xx)
        line([xx; xx], yy, 'Color', cfg.colors.FP(fp_idx, :), 'Parent', ha);
    end
end
end

function plot_psth(ha, r, unit_data, event, cfg)
% plot_psth - Plot PSTH for a specific event with mean SDF and confidence intervals.
% Inputs:
%   ha        - Axes handle to plot on.
%   r         - Struct containing spike and event data.
%   unit_data - Struct with unit-specific data (e.g., ind_unit).
%   event     - Event type ('Presses', 'Releases', 'RewardPokes').
%   cfg       - Configuration struct with plot parameters and colors.
% Outputs:
%   None (plots directly to the axes).
switch event
    case 'press'
        here = 'Presses';
    case 'release'
        here = 'Releases';
    case 'poke'
        here = 'RewardPokes';
    otherwise
        error('Check event')
end
% Set axes properties
set(ha, 'NextPlot', 'add', 'XLim', cfg.ranges.(lower(event)), ...
    'YLim', cfg.plot.yrange, 'YTick', 0:20:100, ...
    'XTick', -2000:1000:2000, 'TickLength', [0.025, 0.1], ...
    'XTickLabelRotation', 0, 'Color', 'none');

% Plot vertical line at time 0
line([0, 0], cfg.plot.yrange, 'Color', 'k', 'LineWidth', 1, 'Parent', ha);

% Initialize FRmax for dynamic y-axis scaling
FRmax = cfg.plot.FRmax;

% Plot SDFs for each foreperiod
for fp_idx = 1:cfg.nFPs
    % Extract spike matrix and time points
    spkmat = r.PSTH.PSTHs(unit_data.ind_unit).(here){fp_idx}{3};
    t_spkmat = r.PSTH.PSTHs(unit_data.ind_unit).(here){fp_idx}{4};

    % Compute SDF
    [~, sdf_mean, sdf_ci]=sdf(t_spkmat, spkmat, cfg.sigma_kernel, 1);
    % Plot confidence intervals
    plotshaded(t_spkmat, sdf_ci, [0.6, 0.6, 0.6]);

    % Plot mean SDF
    plot(t_spkmat, sdf_mean, 'LineWidth', 2, 'Color', cfg.colors.FP(fp_idx, :), 'Parent', ha);

    % Update FRmax
    FRmax = max(FRmax, max(sdf_mean));
end

% Update y-axis limits based on FRmax
set(ha, 'YLim', [0, FRmax * 1.2]);
line([0, 0], [0, FRmax * 1.2], 'Color', 'k', 'LineWidth', 1, 'Parent', ha);
end

function plot_spike_waveform(hf, spk_wave, cfg)
% plot_spike_waveform - Plot mean spike waveform with standard deviation to the right of raster/PSTH plots.
% Inputs:
%   hf        - Figure handle to plot on.
%   spk_wave  - Spike waveform matrix (trials x samples).
%   cfg       - Configuration struct with plot parameters.
% Outputs:
%   None (plots directly to a new axes in the figure).

% Validate input waveform
if isempty(spk_wave) || ~ismatrix(spk_wave) || size(spk_wave, 2) == 0
    warning('Invalid or empty spike waveform data. Skipping waveform plot.');
    return;
end

% Compute waveform statistics
spks = spk_wave;
tspk = (1:size(spks, 2)) / 30; % Time in ms (30 kHz sampling rate)
spk_mean = mean(spks, 1);
spk_std = std(spks, 0, 1);
yrange = [min(spk_mean) * 1.2, max(spk_mean) * 1.2];

% Define plot position
x_positions = [2, 2 + cfg.plot.x_size + cfg.plot.hspacing, ...
    2 + cfg.plot.x_size + cfg.plot.hspacing + cfg.plot.x_size * diff(cfg.ranges.release) / diff(cfg.ranges.press)];

poke_width = cfg.plot.x_size * diff(cfg.ranges.poke) / diff(cfg.ranges.press); % Width of poke plots
x_now = x_positions(3) + poke_width + 1.5; % Right of poke plots + 1.5 cm offset
y_now = 1.5; % Bottom of figure
height0 = 1.5; % Square plot (1.5 cm x 1.5 cm)

% Create axes
ha = axes('Parent', hf, ...
    'Units', 'centimeters', ...
    'Position', [x_now, y_now, height0, height0], ...
    'NextPlot', 'add', ...
    'XLim', [0, tspk(end)], ...
    'YLim', yrange, ...
    'YTick', [0, 20], ...
    'XTick', 0:5, ...
    'XScale', 'linear', ...
    'YScale', 'linear', ...
    'TickLength', [0.02, 1], ...
    'XTickLabelRotation', 40, ...
    'YTickLabel', [], ...
    'XTickLabel', [], ...
    'Color', 'none');

% Plot scale line
line([1, 2], [yrange(1), yrange(1)], 'Color', 'k', 'Parent', ha);

% Plot standard deviation (shaded area)
plotshaded(tspk, [spk_mean - spk_std; spk_mean + spk_std], [0.5, 0.5, 0.5]);

% Plot mean waveform
plot(tspk, spk_mean, 'k', 'LineWidth', 1, 'Parent', ha);

% Hide axes
axis(ha, 'off');
end

function plot_autocorrelation(hf, spk_times, cfg)
% plot_autocorrelation - Plot autocorrelation histogram of spike times.
% Inputs:
%   hf        - Figure handle to plot on.
%   spk_times - Spike times for the unit (in ms).
%   cfg       - Configuration struct with plot parameters.
% Outputs:
%   None (plots directly to a new axes in the figure).

% Validate input spike times
if isempty(spk_times) || ~isvector(spk_times)
    warning('Invalid or empty spike times. Skipping autocorrelation plot.');
    return;
end

% Compute autocorrelation
max_time = ceil(max(spk_times));
spktimes_ = zeros(1, max_time);
spktimes_(round(spk_times)) = 1;
[ar, lags] = xcorr(spktimes_, 25); % Max lag = 25 ms
ar(lags == 0) = 0; % Set zero-lag to 0

% Define plot position
x_positions = [2, 2 + cfg.plot.x_size + cfg.plot.hspacing, ...
    2 + cfg.plot.x_size + cfg.plot.hspacing + cfg.plot.x_size * diff(cfg.ranges.release) / diff(cfg.ranges.press)];

poke_width = cfg.plot.x_size * diff(cfg.ranges.poke) / diff(cfg.ranges.press); % Width of poke plots
x_now = x_positions(3) + poke_width + 1.5; % Same x as waveform plot (right of poke plots)
y_now = 1.5 + 1.5 + 2; % Above waveform plot: y_wave + height0 + 2 cm
width = 2; % Wider than waveform plot
height0 = 1.5; % Same height as waveform plot

% Create axes
ha = axes('Parent', hf, ...
    'Units', 'centimeters', ...
    'Position', [x_now, y_now, width, height0], ...
    'NextPlot', 'add', ...
    'XLim', [-20, 20], ...
    'YLim', [0, 100], ...
    'XTick', -20:10:20, ...
    'XScale', 'linear', ...
    'YScale', 'linear', ...
    'TickLength', [0.05, 0.1], ...
    'XTickLabelRotation', 40, ...
    'Color', 'none');

% Plot autocorrelation histogram
bar(lags, ar, 'FaceColor', [0.5, 0.5, 0.5], 'EdgeColor', 'none', 'Parent', ha);

% Customize axes
xlabel('Lag (ms)', 'Parent', ha);
ylabel('Frequency', 'Parent', ha);
axis(ha, 'auto y'); % Adjust y-limits automatically
end

function plot_warped_psth(hf, warped_data, cfg)
% plot_warped_psth - Plot warped PSTH with mean SDFs and confidence intervals for each FP.
% Inputs:
%   hf          - Figure handle to plot on.
%   warped_data - Struct array with warped SDF data (t_warped, sdf_warped, sdf_mean, sdf_ci, time_points).
%   cfg         - Configuration struct with plot and color parameters.
% Outputs:
%   None (plots directly to a new axes in the figure).

% Validate input data


% Initialize FRmax (use cfg.plot.FRmax as initial value)
FRmax = cfg.plot.FRmax;

% Create axes
x_positions = [2, 2 + cfg.plot.x_size + cfg.plot.hspacing, ...
    2 + cfg.plot.x_size + cfg.plot.hspacing + cfg.plot.x_size * diff(cfg.ranges.release) / diff(cfg.ranges.press)];

x_now = x_positions(1); % Align with press plot (x = 2 cm)
y_now = 4.5; % Bottom of figure
x_size_warped = 10; % Wider than raster/PSTH plots
y_size_warped = 2; % 2 * 1.5 = 3 cm
ha = axes('Parent', hf, ...
    'Units', 'centimeters', ...
    'Position', [x_now, y_now, x_size_warped, y_size_warped], ...
    'NextPlot', 'add', ...
    'XLim', cfg.ranges.warped, ...
    'YLim', [0, FRmax * 1.2], ...
    'YTick', 0:20:100, ...
    'XTick', -2000:1000:2000, ...
    'XScale', 'linear', ...
    'YScale', 'linear', ...
    'TickLength', [0.025, 0.1], ...
    'XTickLabelRotation', 0, ...
    'Color', 'none');

% Plot vertical line at time 0 (press)
line([0, 0], [0, FRmax * 1.2], 'Color', 'k', 'LineWidth', 1, 'Parent', ha);

% Plot warped SDFs for each FP
for fp_idx = 1:cfg.nFPs

    % warped_data(fp_idx).t_warped = t_warped;
    % warped_data(fp_idx).sdf_warped_mean = mean(sdf_warped, 1);
    % warped_data(fp_idx).sdf_wared_ci = bootci(1000, @mean, sdf_warped);
    % warped_data(fp_idx).event_time_points = time_points;

    % Plot confidence intervals
    plotshaded(warped_data(fp_idx).t_warped, warped_data(fp_idx).sdf_wared_ci, [0.6, 0.6, 0.6]);

    % Plot mean SDF
    plot(warped_data(fp_idx).t_warped, warped_data(fp_idx).sdf_warped_mean, ...
        'LineWidth', 2, 'Color', cfg.colors.FP(fp_idx, :), 'Parent', ha);

    % Plot trigger line (at FP)
    line([cfg.FPs(fp_idx), cfg.FPs(fp_idx)], [0, FRmax * 1.2], ...
        'Color', cfg.colors.trigger, 'LineStyle', '--', 'LineWidth', 1, 'Parent', ha);

    % Plot poke line
    poke_time = warped_data(fp_idx).event_time_points(4);
    line([poke_time poke_time], [0, FRmax * 1.2], ...
        'Color', cfg.colors.poke, 'LineStyle', '--', 'LineWidth', 1, 'Parent', ha);

    % Update FRmax
    FRmax = max(FRmax, max(warped_data(fp_idx).sdf_warped_mean));
end

% Update y-limits
set(ha, 'YLim', [0, FRmax * 1.2]);
line([0, 0], [0, FRmax * 1.2], 'Color', 'k', 'LineWidth', 1, 'Parent', ha);

% Add labels
xlabel('Time from press (ms)', 'Parent', ha);
ylabel('Spike rate (Hz)', 'Parent', ha);
end


function plot_warped_pooled_psth(hf, warped_data, cfg)
% plot_warped_psth - Plot warped PSTH with mean SDFs and confidence intervals, pooled from both FPs.
% Inputs:
%   hf          - Figure handle to plot on.
%   warped_data - Struct array with warped SDF data (t_warped, sdf_warped, sdf_mean, sdf_ci, time_points).
%   cfg         - Configuration struct with plot and color parameters.
% Outputs:
%   None (plots directly to a new axes in the figure).

% Initialize FRmax (use cfg.plot.FRmax as initial value)
FRmax = cfg.plot.FRmax;

% Create axes
x_positions = [2, 2 + cfg.plot.x_size + cfg.plot.hspacing, ...
    2 + cfg.plot.x_size + cfg.plot.hspacing + cfg.plot.x_size * diff(cfg.ranges.release) / diff(cfg.ranges.press)];

x_now = x_positions(1); % Align with press plot (x = 2 cm)
y_now = 1.15; % Bottom of figure

x_size_warped_press = 5; % Wider than raster/PSTH plots
total_press_dur = warped_data.press.time(end)-warped_data.press.time(1);
total_release_dur = warped_data.trigger_release_poke.sdf_pooled.time(end)-warped_data.trigger_release_poke.sdf_pooled.time(1);
x_size_warped_release = x_size_warped_press*(total_release_dur/total_press_dur); % Wider than raster/PSTH plots
x_now_press = x_now;
x_now_release = x_now + x_size_warped_press +cfg.plot.hspacing;
y_size_warped = 2; % 2 * 1.5 = 3 cm

ha_press = axes('Parent', hf, ...
    'Units', 'centimeters', ...
    'Position', [x_now_press, y_now, x_size_warped_press, y_size_warped], ...
    'NextPlot', 'add', ...
    'XLim', [warped_data.press.time(1) warped_data.press.time(end)], ...
    'YLim', [0, FRmax * 1.2], ...
    'YTick', 0:20:100, ...
    'XTick', -2000:1000:2000, ...
    'XScale', 'linear', ...
    'YScale', 'linear', ...
    'TickLength', [0.025, 0.1], ...
    'XTickLabelRotation', 0, ...
    'Color', 'none');

% Plot vertical line at time 0 (press)
line([0, 0], [0, FRmax * 1.2], 'Color', 'k', 'LineWidth', 1, 'Parent', ha_press);

% Plot confidence intervals
plotshaded(warped_data.press.sdf_pooled.time',  warped_data.press.sdf_pooled.ci', [0.6, 0.6, 0.6]);

% Plot mean SDF
plot(warped_data.press.sdf_pooled.time, warped_data.press.sdf_pooled.mean, ...
    'LineWidth', 2, 'Color', cfg.colors.FP(1, :), 'Parent', ha_press);

FRmax = max(FRmax, max(warped_data.press.sdf_pooled.mean));

% Add labels
xlabel('Time from press (ms)', 'Parent', ha_press);
ylabel('Spike rate (Hz)', 'Parent', ha_press);

ha_release = axes('Parent', hf, ...
    'Units', 'centimeters', ...
    'Position', [x_now_release, y_now, x_size_warped_release, y_size_warped], ...
    'NextPlot', 'add', ...
    'XLim', [warped_data.trigger_release_poke.sdf_pooled.time(1) warped_data.trigger_release_poke.sdf_pooled.time(end)], ...
    'YLim', [0, FRmax * 1.2], ...
    'YTick', 0:20:100, ...
    'XTick', -2000:1000:2000, ...
    'XScale', 'linear', ...
    'YScale', 'linear', ...
    'TickLength', [0.025, 0.1], ...
    'XTickLabelRotation', 0, ...
    'Color', 'none');

% Plot trigger line (at FP)
line([0 0], [0, FRmax * 1.2], ...
    'Color', cfg.colors.trigger, 'LineStyle', '--', 'LineWidth', 1, 'Parent', ha_release);

release_time = warped_data.trigger_release_poke.sdf_pooled.event_times(1);
% Plot poke line
line([release_time release_time], [0, FRmax * 1.2], ...
    'Color', cfg.colors.release, 'LineStyle', '--', 'LineWidth', 1, 'Parent', ha_release);

poke_time = warped_data.trigger_release_poke.sdf_pooled.event_times(2)+release_time;
% Plot poke line
line([poke_time poke_time], [0, FRmax * 1.2], ...
    'Color', cfg.colors.poke, 'LineStyle', '--', 'LineWidth', 1, 'Parent', ha_release);

% Plot confidence intervals
plotshaded(warped_data.trigger_release_poke.sdf_pooled.time',  warped_data.trigger_release_poke.sdf_pooled.ci', [0.6, 0.6, 0.6]);

% Plot mean SDF
plot(warped_data.trigger_release_poke.sdf_pooled.time, warped_data.trigger_release_poke.sdf_pooled.mean, ...
    'LineWidth', 2, 'Color', cfg.colors.FP(1, :), 'Parent', ha_release);

xlabel('Time from trigger (ms)', 'Parent', ha_release);

FRmax = max(FRmax, max(warped_data.trigger_release_poke.sdf_pooled.mean));

% Update y-limits
set(ha_press, 'YLim', [0, FRmax * 1.2]);
set(ha_release, 'YLim', [0, FRmax * 1.2]);
 
end

function warp_out = process_trigger_sequences(r, spk_times, cfg)
% process_trigger_sequences - Process trigger-release-poke sequences and compute warped SDFs.
% Inputs:
%   r         - Struct containing spike and event data.
%   spk_times - Spike times for the unit (in ms).
%   cfg       - Configuration struct with parameters.
% Outputs:
%   warp_out  - Struct with press- and trigger-aligned spike trains, SDFs, and warped SDFs.

% Validate inputs
if isempty(spk_times) || ~isvector(spk_times)
    warning('Invalid or empty spike times. Returning empty warp_out.');
    warp_out = struct();
    return;
end
if ~isfield(r, 'PSTH') || ~isfield(r.PSTH, 'Events') || ~isfield(r, 'PopPSTH')
    error('Input ''r'' must contain ''PSTH.Events'' and ''PopPSTH'' fields.');
end

% Initialize parameters
pre_press = 2.75; % s before press
post_press = 1; % s after press
pre_trigger = 0.75; % s before trigger
post_poke = 1; % s after poke
sigma_kernel = 25; % ms, Gaussian kernel width
dt = 1; % ms, time bin size

% Initialize output
warp_out = struct();
warp_out.event_sequence_label = {'press', 'trigger', 'release', 'poke', 'FP'};
warp_out.event_sequence = [];
% warp_out.press = struct('spk_train_FPs_explained', [], 'spk_train_FPs', {}, 'time', [], 'sdf_FPs', {}, 'sdf_FPs_mean_ci', {}, ...
%     'sdf_pooled', []);
% warp_out.release = struct('spk_train_FPs', {}, 'sdf_FPs', {}, 'sdf_warped', []);

% Get all poke times
all_pokes = sort(cell2mat(r.PSTH.Events.Pokes.RewardPoke.Time(:)));

% Process each FP
press_spktrains_all = cell(1, cfg.nFPs);
press_sdfs_all = cell(1, cfg.nFPs);
press_release_seqs_all = cell(1, cfg.nFPs);
release_spktrains_all = cell(1, cfg.nFPs);
release_sdfs_all = cell(1, cfg.nFPs);
release_event_seqs_all = [];

for fp_idx = 1:cfg.nFPs
    % Extract event times
    press_times = sort(r.PSTH.Events.Presses.Time{fp_idx});
    trigger_times = press_times + cfg.FPs(fp_idx);
    release_times = sort(r.PSTH.Events.Releases.Time{fp_idx});

    % Match release to poke
    release_times_ = [];
    trigger_times_ = [];
    poke_times_ = [];

    for m = 1:length(release_times)
        poke_idx = find(all_pokes > release_times(m), 1, 'first');
        if ~isempty(poke_idx)
            poke_times_ = [poke_times_; all_pokes(poke_idx)];
            release_times_ = [release_times_; release_times(m)];
            trigger_times_ = [trigger_times_; trigger_times(m)];
        end
    end

    % Filter sequences
    reaction_times = release_times_ - trigger_times_;
    retrieval_durs = poke_times_ - release_times_;
    ind_included = ~isoutlier(retrieval_durs, 'ThresholdFactor', 10) & reaction_times > 100;

    release_times_ = release_times_(ind_included);
    trigger_times_ = trigger_times_(ind_included);
    poke_times_ = poke_times_(ind_included);

    % Reconstruct press times
    press_times_ = zeros(size(trigger_times_));
    for m = 1:length(trigger_times_)
        press_idx = find(press_times < trigger_times_(m), 1, 'last');
        if ~isempty(press_idx)
            press_times_(m) = press_times(press_idx);
        end
    end

    % Store sequences
    press_release_seqs = [press_times_, trigger_times_, release_times_, poke_times_ repmat(cfg.FPs(fp_idx), length(press_times_), 1)];
    press_release_seqs_all{fp_idx} = press_release_seqs;

    % Compute spike trains and SDFs
    press_spktrains = {};
    press_sdfs = {};
    t_press_sdf = [];

    release_spktrains = {};
    release_sdfs = {};
    t_release_sdf = [];

    k_ = 0;
    for k = 1:size(press_release_seqs, 1)
        k_press = press_release_seqs(k, 1);
        k_trigger = press_release_seqs(k, 2);
        k_release = press_release_seqs(k, 3);
        k_poke = press_release_seqs(k, 4);

        % Check time bounds
        if k_press - pre_press*1000 > 0 && k_press + post_press*1000 < max(spk_times) && ...
                k_trigger - pre_trigger*1000 > 0 && k_poke + post_poke*1000 < max(spk_times)
            k_ = k_ + 1;
            press_release_seqs_(k_, :) = press_release_seqs(k, :);

            % Press-aligned
            t_range = [k_press - pre_press*1000, k_press + post_press*1000];
            k_spktimes = spk_times(spk_times >= t_range(1) & spk_times <= t_range(2)) - k_press;
            press_spktrains{k_} = k_spktimes;
            [spkout, tspk] = sdf25(k_spktimes, t_range - k_press, sigma_kernel, dt);
            press_sdfs{k_} = [tspk', spkout'];

            % Trigger-aligned
            t_range = [k_trigger - pre_trigger*1000, k_poke + post_poke*1000];
            k_spktimes = spk_times(spk_times >= t_range(1) & spk_times <= t_range(2)) - k_trigger;
            release_spktrains{k_} = k_spktimes;
            rel_timing = [0, k_release - k_trigger, k_poke - k_release];
            release_event_seqs_all = [release_event_seqs_all; rel_timing];
            [spkout, tspk] = sdf25(k_spktimes, t_range - k_trigger, sigma_kernel, dt);
            release_sdfs{k_} = [tspk', spkout'];
        end
    end

    press_spktrains_all{fp_idx} = press_spktrains;
    press_sdfs_all{fp_idx} = press_sdfs;
    release_spktrains_all{fp_idx} = release_spktrains;
    release_sdfs_all{fp_idx} = release_sdfs;
end

% Store press-related data
warp_out.event_sequence = vertcat(press_release_seqs_all{:});

press_sdf_FPs = cell(1, cfg.nFPs);
press_sdf_FPs_mean_ci = cell(1, cfg.nFPs);
press_sdf_pooled = [];
for fp_idx = 1:cfg.nFPs
    for jj = 1:length(press_sdfs_all{fp_idx})
        press_sdf_pooled = [press_sdf_pooled, press_sdfs_all{fp_idx}{jj}(:, 2)];
        press_sdf_FPs{fp_idx} = [press_sdf_FPs{fp_idx}, press_sdfs_all{fp_idx}{jj}(:, 2)];
    end
    if ~isempty(press_sdfs_all{fp_idx})
        press_sdf_FPs_mean_ci{fp_idx} = [press_sdfs_all{fp_idx}{1}(:, 1), ...
            mean(press_sdf_FPs{fp_idx}, 2), transpose(bootci(1000, @mean, press_sdf_FPs{fp_idx}'))];
    end
end

warp_out.press.spk_train_FPs_explained = 'Press-related spike trains and SDFs, each cell is an FP';
warp_out.press.spk_train_FPs = press_spktrains_all;

if ~isempty(press_sdfs_all{1}) && ~isempty(press_sdfs_all{1}{1})
    warp_out.press.time = press_sdfs_all{1}{1}(:, 1);
else
    warp_out.press.time = [];
end

warp_out.press.sdf_FPs = press_sdf_FPs;
warp_out.press.sdf_FPs_mean_ci = press_sdf_FPs_mean_ci;
warp_out.press.sdf_pooled.time = press_sdfs_all{1}{1}(:, 1);
warp_out.press.sdf_pooled.mean = mean(press_sdf_pooled, 2);
warp_out.press.sdf_pooled.ci = transpose(bootci(1000, @mean, press_sdf_pooled'));
warp_out.press.sdf_pooled.trials = press_sdf_pooled;

% Store trigger-related data
warp_out.trigger_release_poke.spk_train_FPs_explained = 'Trigger-related spike trains and SDFs, each cell is an FP';
warp_out.trigger_release_poke.spk_train_FPs = release_spktrains_all;

warp_out.trigger_release_poke.sdf_FPs = release_sdfs_all;

% Warp trigger-aligned SDFs
release_spktrains_all = horzcat(release_spktrains_all{:});
release_sdfs_all = horzcat(release_sdfs_all{:});

rt_median = round(median(release_event_seqs_all(:, 2)));
retrieval_median = round(median(release_event_seqs_all(:, 3)));
target_time_trigger = (-pre_trigger*1000:-1);
target_time_rt = (0:rt_median);
target_time_retrieval = (rt_median+1:rt_median+retrieval_median);
target_time_postpoke = (rt_median+retrieval_median+1:rt_median+retrieval_median+post_poke*1000);
target_time = [target_time_trigger, target_time_rt, target_time_retrieval, target_time_postpoke];
release_sdfs_warped = [];

for ii = 1:length(release_sdfs_all)
    t_ii = release_sdfs_all{ii}(:, 1);
    sdf_ii = release_sdfs_all{ii}(:, 2);
    ii_rt = release_event_seqs_all(ii, 2);
    ii_retrieval = release_event_seqs_all(ii, 3);

    ind_preTrigger = find(t_ii <= target_time_trigger(end));
    sdf_ii_preTrigger = sdf_ii(ind_preTrigger);
    ind_Release = find(t_ii >= 0 & t_ii <= ii_rt);
    t_ii_Release = t_ii(ind_Release);
    sdf_ii_Release = sdf_ii(ind_Release);
    sdf_ii_Release_warped = Spikes.SRT.warp_sdf(t_ii_Release, sdf_ii_Release, target_time_rt);
    ind_Poke = find(t_ii >= ii_rt+1 & t_ii <= ii_rt+ii_retrieval);
    t_ii_Poke = t_ii(ind_Poke);
    sdf_ii_Poke = sdf_ii(ind_Poke);
    sdf_ii_Poke_warped = Spikes.SRT.warp_sdf(t_ii_Poke, sdf_ii_Poke, target_time_retrieval);
    ind_PostPoke = find(t_ii > ii_rt+ii_retrieval);
    ind_PostPoke = ind_PostPoke(1:min(length(ind_PostPoke), length(target_time_postpoke)));
    sdf_ii_PostPoke = sdf_ii(ind_PostPoke);

    sdf_ii_warped = [sdf_ii_preTrigger; sdf_ii_Release_warped'; sdf_ii_Poke_warped'; sdf_ii_PostPoke];
    release_sdfs_warped = [release_sdfs_warped, sdf_ii_warped];
end

warp_out.trigger_release_poke.sdf_pooled.time = target_time';
warp_out.trigger_release_poke.sdf_pooled.mean = mean(release_sdfs_warped, 2)';
warp_out.trigger_release_poke.sdf_pooled.ci = transpose(bootci(1000, @mean, release_sdfs_warped'));
warp_out.trigger_release_poke.sdf_pooled.trials = release_sdfs_warped;
warp_out.trigger_release_poke.sdf_pooled.event_labels = {'rt(median)', 'retrieval(median)'};
warp_out.trigger_release_poke.sdf_pooled.event_times = [rt_median, retrieval_median];

end

function save_figure(r, id, hf)
% Save the figure to the Figures_WarpedPSTHs directory
thisFolder = fullfile(pwd, 'Figures_WarpedPSTHs');
if ~exist(thisFolder, 'dir')
    mkdir(thisFolder);
end
filename = fullfile(thisFolder, sprintf('%s_%s_Ch%d_Unit%d_Lite', ...
    r.BehaviorClass.Subject, r.BehaviorClass.Date, id(1), id(2)));
print(hf, '-dpng', filename);
end