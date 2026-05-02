function [spike_times_shuf_ms, shuffle_info] = shuffle_spike_times_press_poke( ...
    spike_times_ms, Beh, press_win_ms, poke_win_ms)
% Shuffle spike snippets around press and poke separately across trials.
%
% INPUTS
%   spike_times_ms : spike times in ms
%   Beh            : behavior table with at least:
%                    Beh.t_press, Beh.t_poke
%   press_win_ms   : [start end] around t_press, e.g. [-4000 500]
%   poke_win_ms    : [start end] around t_poke,  e.g. [-1000 1000]
%
% OUTPUTS
%   spike_times_shuf_ms : shuffled spike times in ms
%   shuffle_info        : struct containing permutations and metadata
%
% LOGIC
%   1. Peri-press spikes are shuffled across all trials with valid t_press.
%   2. Peri-poke spikes are shuffled across trials with valid t_poke.
%   3. To avoid double counting, peri-press spikes that also fall inside the
%      peri-poke window of the same source trial are excluded from the
%      press snippet pool.
%
% NOTES
%   - Spikes outside these event windows are NOT included in the output.
%   - If you want, you can later append unshuffled "background" spikes, but
%     for event-centered analyses this event-only surrogate is often cleaner.

    spike_times_ms = spike_times_ms(:);

    if ~istable(Beh)
        error('Beh must be a table.');
    end
    req = {'t_press', 't_poke'};
    for k = 1:numel(req)
        if ~ismember(req{k}, Beh.Properties.VariableNames)
            error('Beh must contain column %s.', req{k});
        end
    end

    if numel(press_win_ms) ~= 2 || numel(poke_win_ms) ~= 2
        error('press_win_ms and poke_win_ms must each be [start end].');
    end

    t_press = Beh.t_press(:);
    t_poke  = Beh.t_poke(:);

    n_trials = height(Beh);

    valid_press = ~isnan(t_press);
    valid_poke  = ~isnan(t_poke);

    press_trials = find(valid_press);
    poke_trials  = find(valid_poke);

   
    perm_press = press_trials(randperm(numel(press_trials)));
    perm_poke  = poke_trials(randperm(numel(poke_trials)));

    shuf_press = [];
    shuf_poke  = [];

    src_press_trial = [];
    tgt_press_trial = [];

    src_poke_trial = [];
    tgt_poke_trial = [];

    %% ---------------------------
    %  PRESS-ALIGNED SNIPPETS
    %  Exclude spikes that are also in the poke window of the same source trial
    %  so they won't be duplicated.
    %  ---------------------------
    for ii = 1:numel(press_trials)
        i = press_trials(ii);

        w_press = t_press(i) + press_win_ms;
        m_press = spike_times_ms >= w_press(1) & spike_times_ms < w_press(2);

        % remove overlap with poke window from the same source trial
        if valid_poke(i)
            w_poke_same = t_poke(i) + poke_win_ms;
            m_poke_same = spike_times_ms >= w_poke_same(1) & spike_times_ms < w_poke_same(2);
            m_press = m_press & ~m_poke_same;
        end

        spikes_i = spike_times_ms(m_press);
        rel_i = spikes_i - t_press(i);

        j = perm_press(ii);   % target press trial
        spikes_j = t_press(j) + rel_i;

        shuf_press = [shuf_press; spikes_j]; %#ok<AGROW>
        src_press_trial = [src_press_trial; repmat(i, numel(spikes_j), 1)]; %#ok<AGROW>
        tgt_press_trial = [tgt_press_trial; repmat(j, numel(spikes_j), 1)]; %#ok<AGROW>
    end

    %% ---------------------------
    %  POKE-ALIGNED SNIPPETS
    %  Only valid poke trials
    %  ---------------------------
    for ii = 1:numel(poke_trials)
        i = poke_trials(ii);

        w_poke = t_poke(i) + poke_win_ms;
        m_poke = spike_times_ms >= w_poke(1) & spike_times_ms < w_poke(2);

        spikes_i = spike_times_ms(m_poke);
        rel_i = spikes_i - t_poke(i);

        j = perm_poke(ii);   % target poke trial
        spikes_j = t_poke(j) + rel_i;

        shuf_poke = [shuf_poke; spikes_j]; %#ok<AGROW>
        src_poke_trial = [src_poke_trial; repmat(i, numel(spikes_j), 1)]; %#ok<AGROW>
        tgt_poke_trial = [tgt_poke_trial; repmat(j, numel(spikes_j), 1)]; %#ok<AGROW>
    end

    %% combine and sort
    spike_times_shuf_ms = [shuf_press; shuf_poke];
    [spike_times_shuf_ms, ord] = sort(spike_times_shuf_ms);

    tag = [repmat("press", numel(shuf_press), 1); repmat("poke", numel(shuf_poke), 1)];
    tag = tag(ord);

    src_trial = [src_press_trial; src_poke_trial];
    tgt_trial = [tgt_press_trial; tgt_poke_trial];
    src_trial = src_trial(ord);
    tgt_trial = tgt_trial(ord);

    shuffle_info = struct();
    shuffle_info.press_win_ms = press_win_ms;
    shuffle_info.poke_win_ms = poke_win_ms;
    shuffle_info.press_trials = press_trials;
    shuffle_info.poke_trials = poke_trials;
    shuffle_info.perm_press = perm_press;
    shuffle_info.perm_poke = perm_poke;
    shuffle_info.event_tag = tag;
    shuffle_info.source_trial = src_trial;
    shuffle_info.target_trial = tgt_trial;
end