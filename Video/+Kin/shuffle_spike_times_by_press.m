function [spike_times_shuf_ms, shuffle_info] = shuffle_spike_times_by_press(spike_times_ms, Beh)
% Shuffle spike trains across trials based on press time.
%
% For each trial i, spikes assigned to trial i are moved to another trial j,
% while preserving their timing relative to t_press.
%
% INPUTS
%   spike_times_ms : column or row vector of spike times in ms
%   Beh            : behavior table containing at least:
%                    - Beh.t_press
%                    - Beh.t_release
%
% OUTPUTS
%   spike_times_shuf_ms : shuffled spike times in ms
%   shuffle_info        : struct with mapping details
%
% NOTES
%   - Spikes are grouped by trial using interval:
%         [t_press(i), t_press(i+1))
%     for trials 1..N-1
%     and [t_press(N), t_release(N)] for the last trial if t_release exists,
%     otherwise [t_press(N), inf)
%
%   - This is a full permutation of trials.

    spike_times_ms = spike_times_ms(:);
    t_press = Beh.t_press(:);
    n_trials = numel(t_press);

    if ~istable(Beh)
        error('Beh must be a table.');
    end
    if ~ismember('t_press', Beh.Properties.VariableNames)
        error('Beh must contain column t_press.');
    end

    if ismember('t_release', Beh.Properties.VariableNames)
        t_release = Beh.t_release(:);
    else
        t_release = nan(n_trials,1);
    end

    % random permutation: source trial i -> target trial perm(i)
    perm = randperm(n_trials);

    spike_times_shuf_ms = [];
    source_trial_of_spike = [];
    target_trial_of_spike = [];

    for i = 1:n_trials
        % Define source trial window
        t0 = t_press(i);

        if i < n_trials
            t1 = t_press(i+1);   % use next press as boundary
        else
            if ~isnan(t_release(i))
                t1 = t_release(i);
            else
                t1 = inf;
            end
        end

        % spikes belonging to source trial i
        m = spike_times_ms >= t0 & spike_times_ms < t1;
        spikes_i = spike_times_ms(m);

        % relative to press
        rel_i = spikes_i - t_press(i);

        % paste onto target trial j
        j = perm(i);
        spikes_j = t_press(j) + rel_i;

        spike_times_shuf_ms = [spike_times_shuf_ms; spikes_j]; %#ok<AGROW>
        source_trial_of_spike = [source_trial_of_spike; repmat(i, numel(spikes_j), 1)]; %#ok<AGROW>
        target_trial_of_spike = [target_trial_of_spike; repmat(j, numel(spikes_j), 1)]; %#ok<AGROW>
    end

    % sort final spike train
    [spike_times_shuf_ms, ord] = sort(spike_times_shuf_ms);
    source_trial_of_spike = source_trial_of_spike(ord);
    target_trial_of_spike = target_trial_of_spike(ord);

    shuffle_info = struct();
    shuffle_info.perm = perm;                       % source i -> target perm(i)
    shuffle_info.t_press = t_press;
    shuffle_info.source_trial_of_spike = source_trial_of_spike;
    shuffle_info.target_trial_of_spike = target_trial_of_spike;
end