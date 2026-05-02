% Input: spktimes (spike times in ms, non-integer)
% Output: t (time vector 0:max_t), spk_t (sparse binary vector)
function [t, spk_t] = spike_to_sparse(spktimes)
    % Define buffer based on number of spikes
    few_spikes_threshold = 100; % Threshold for "very few spikes"
    buffer_1min = 60000; % 1 minute in ms
    buffer_30min = 1800000; % 30 minutes in ms
    
    % Filter valid spike times (non-negative)
    spktimes = spktimes(spktimes >= 0);
    
    % Check if there are any spikes
    if isempty(spktimes)
        t = 0:buffer_1min; % Default to 1 min if no spikes
        spk_t = sparse([], [], [], length(t), 1, 0);
        spk_t = logical(spk_t);
        return;
    end
    
    % Determine max time
    max_spike_time = max(spktimes);
    max_t = ceil(max_spike_time); % Round up to next ms
    
    % Set buffer based on spike count
    if length(spktimes) < few_spikes_threshold
        buffer = buffer_30min;
    else
        buffer = buffer_1min;
    end
    max_t = max_t + buffer;
    
    % Define time vector
    t = 0:max_t;
    
    % Round spike times to nearest ms and ensure within bounds
    spktimes = round(spktimes);
    spktimes = spktimes(spktimes >= 0 & spktimes <= max_t);
    
    % Convert spike times to indices (1-based for MATLAB)
    spike_indices = spktimes + 1; % t=0 is index 1, t=1 is index 2, etc.
    
    % Remove duplicates (if multiple spikes round to same ms)
    spike_indices = unique(spike_indices);
    
    % Create sparse binary vector
    spk_t = sparse(spike_indices, 1, 1, length(t), 1);
    
    % Ensure spk_t is logical and sparse
    spk_t = logical(spk_t);
end