function [lags, counts] = computeACG(spikeTimes, binSize, maxLag)
% Compute autocorrelogram (ACG) for spike times, excluding zero lag.
% Inputs:
%   spikeTimes: Vector of spike timestamps (in milliseconds)
%   binSize: Bin size for histogram (in milliseconds, e.g., 1)
%   maxLag: Maximum time lag to consider (in milliseconds, e.g., 100)
% Outputs:
%   lags: Time lags (centers of bins, in milliseconds)
%   counts: Number of spike pairs in each bin
%   JY 2025 with Grok
% % Example usage
% spikeTimes = r.Units.SpikeTimes(i).timings; % Your spike times
% binSize = 1; % 1 ms bins
% maxLag = 100; % ±100 ms
% [lags, counts] = computeACG(spikeTimes, binSize, maxLag);

% Ensure spikeTimes is a column vector
spikeTimes = spikeTimes(:);

% Input validation
if isempty(spikeTimes)
    lags = [];
    counts = [];
    warning('No spikes provided. Returning empty ACG.');
    return;
end
if binSize <= 0 || maxLag <= 0
    error('binSize and maxLag must be positive.');
end

% Determine time range
tMin = min(spikeTimes);
tMax = max(spikeTimes);
if tMin == tMax
    lags = [];
    counts = [];
    warning('Spike times span zero duration. Returning empty ACG.');
    return;
end

% Bin spike times
edges = tMin:binSize:tMax+binSize; % Include endpoint
binnedSpikes = histcounts(spikeTimes, edges);
binnedSpikes = binnedSpikes(:); % Ensure column vector

% Compute autocorrelation using corrcoef
nBins = length(binnedSpikes);
maxLagBins = ceil(maxLag / binSize); % Number of bins for maxLag
% Pad the signal to handle edges
paddedSpikes = [zeros(maxLagBins, 1); binnedSpikes; zeros(maxLagBins, 1)];
% Compute autocorrelation via corrcoef
[acf, lagsBins] = xcorr(paddedSpikes, maxLagBins, 'unbiased');
% xcorr returns lags from -maxLagBins to +maxLagBins
lags = lagsBins * binSize; % Convert to milliseconds

% Extract counts (remove zero lag)
counts = acf; % Unnormalized counts
zeroLagIdx = find(lags == 0);
if ~isempty(zeroLagIdx)
    counts(zeroLagIdx) = []; % Remove zero lag
    lags(zeroLagIdx) = []; % Remove corresponding lag
end

% Ensure non-negative counts (should already be the case)
counts = max(counts, 0);

end
