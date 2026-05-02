function B = add_spike_counts_to_bins(B, spike_times_ms, unit)
% add_spike_counts_to_bins
% Add spike counts to each bin in table B.
%
% INPUT
%   B               : table with columns
%                     - time_bin_start
%                     - time_bin_end
%   spike_times_ms  : vector of spike times in ms
%   unit: unit name as "anm_session_ch_unit"
%
% OUTPUT
%   B               : same table with added columns
%                     - spike_count
%                     - spike_rate_hz
%
% NOTES
%   Bins are treated as left-closed, right-open:
%       time_bin_start <= spike_time < time_bin_end
%   This avoids double counting spikes exactly on bin boundaries.

    %-----------------------------
    % basic checks
    %-----------------------------
    if ~istable(B)
        error('B must be a table.');
    end

    req_vars = ["time_bin_start", "time_bin_end"];
    has_vars = ismember(req_vars, string(B.Properties.VariableNames));
    if ~all(has_vars)
        error('B must contain time_bin_start and time_bin_end.');
    end

    %-----------------------------
    % clean spike times
    %-----------------------------
    spike_times_ms = spike_times_ms(:);
    spike_times_ms = spike_times_ms(~isnan(spike_times_ms) & ~isinf(spike_times_ms));
    spike_times_ms = sort(spike_times_ms);

    %-----------------------------
    % initialize outputs
    %-----------------------------
    nBins = height(B);
    spike_count = zeros(nBins, 1);

    %-----------------------------
    % count spikes bin by bin
    %-----------------------------
    for i = 1:nBins
        t0 = B.time_bin_start(i);
        t1 = B.time_bin_end(i);

        spike_count(i) = sum(spike_times_ms >= t0 & spike_times_ms < t1);
    end

    B.spike_count = spike_count;

    % optional but useful for plotting / QC
    bin_width_ms = B.time_bin_end - B.time_bin_start;
    B.spike_rate_hz = spike_count ./ bin_width_ms * 1000;
    B.unit_id = repmat({unit}, height(B), 1);
end