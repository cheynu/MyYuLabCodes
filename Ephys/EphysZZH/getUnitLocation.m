function unitLocation = getUnitLocation(r, spatial)
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
Fs = 30000;

peakTrough                  =       zeros(1, nSpk);
tPeakTrough                 =       zeros(1, nSpk);
fullWidthHalfHeight         =       zeros(1, nSpk);

good                        =       zeros(1, nSpk);
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

    % based on allWaves, compute the location of the unit. 
    % use this function from Yue Huang
    % function [x, y, z, ptt] = spikeLocation(waveforms_mean, channel_locations, n_nearest_channels, algorithm)
    [unitLocation.where(1, i),unitLocation.where(2, i),unitLocation.where(3, i)] = spikeLocationZZH(allWaves, channel_locations, nNearest, 'monopolar_triangulation');
     unitLocation.what(i) = spikeSizeSorted(1);

end

unit_location_name = sprintf('unitLocation_%s_%s.mat', r.BehaviorClass.Subject, r.BehaviorClass.Session);
save(unit_location_name, 'unitLocation')

end