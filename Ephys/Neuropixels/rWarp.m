function sdf_units = rWarp(r, index, unitLocation)

% This function produces a warped PSTH and ridgeplot. index can be a list or a single
% number. It is the index in r.Units.SpikeTimes, don't use [ch unit]
% anymore
% JY 2025

if nargin < 2
    index = 1:length(r.Units.SpikeTimes);
end

% Input validation
if ~isfield(r, 'Units') || ~isfield(r.Units, 'SpikeTimes')
    error('Invalid input: r.Units.SpikeTimes is missing.');
end
if any(index < 1) || any(index > length(r.Units.SpikeTimes))
    error('Invalid index: values must be between 1 and %d.', length(r.Units.SpikeTimes));
end

% Initialize output
sdf_units = repmat(struct('index', [], 'ch', [], 'unit', [], 'spk_time_ms', [], ...
    't_sdf_ms', [], 'sdf', [], 'warp_out', [], 'fp', [], 'auto_correlation', [], ...
    'isi_violation', [], 'good', [], 'waveform', [], 'spk_features', [], 'sparseness', []), 1, length(index));

kernel_width = 20;
bin_size = 10;
FPs = r.BehaviorClass.MixedFP;
nWave = 9;
Fs = 30000;

for i = 1:length(index)
    ind = index(i);
    ispk_times = r.Units.SpikeTimes(ind).timings;
    i_df_units = sdf_spktimes(ispk_times, max(ispk_times)+1000, kernel_width, bin_size);
    
    sdf_units(i).index = ind;
    sdf_units(i).ch = r.Units.SpikeNotes(ind, 1);
    sdf_units(i).unit = r.Units.SpikeNotes(ind, 2);
    sdf_units(i).spk_time_ms = ispk_times;
    sdf_units(i).t_sdf_ms = i_df_units(:, 1);
    sdf_units(i).sdf = i_df_units(:, 2);
    fprintf('Ch%2.0dUnit%2.0d\n', r.Units.SpikeNotes(ind, 1), r.Units.SpikeNotes(ind, 2));
    sdf_units(i).warp_out = Spikes.SRT.PlotPSTHLiteWarpedTidy(r, [sdf_units(i).ch sdf_units(i).unit]);
    sdf_units(i).fp = FPs;
    sdf_units(i).sparseness = compute_sparseness(i_df_units(:, 1), i_df_units(:, 2),100);    
  

    [lags, counts] = computeACG(ispk_times, 1, 50);
    sdf_units(i).auto_correlation.lags = lags;
    sdf_units(i).auto_correlation.counts = counts;
    
    sdf_units(i).isi_violation = computeISIViolation(ispk_times);
    sdf_units(i).good = r.Units.SpikeNotes(ind, 3);
    
    % Waveform processing
    sdf_units(i).waveform = processWaveforms(r.Units.SpikeTimes(ind), nWave, Fs);
    sdf_units(i).spk_features = spike_features(sdf_units(i).waveform.twave, ...
        sdf_units(i).waveform.waves{1});

    % location of this unit
    sdf_units(i).location = unitLocation.where(:, ind);
    sdf_units(i).spike_size = unitLocation.what(ind);
end

end

function violation_ratio = computeISIViolation(ispk_times)
    isi = diff(ispk_times); % Assumes ispk_times in milliseconds
    violations = sum(isi < 3); % ISIs < 3 ms
    total_isi = length(isi);
    violation_ratio = (violations / total_isi) * 100; % As percentage
end

function waveform = processWaveforms(spikeTimes, nWave, Fs)
    allWaves = spikeTimes.wave_mean;
    nSample = size(allWaves, 2);
    spikeSize = abs(max(allWaves, [], 2) - min(allWaves, [], 2));
    [~, indSort] = sort(spikeSize, 'descend');
    waveCollection = cell(1, nWave);
    for j = 1:nWave
        waveCollection{j} = allWaves(indSort(j), :);
    end
    waveform.channels = indSort;
    waveform.waves = waveCollection;
    waveform.twave = (1:nSample) * 1000 / Fs;
end