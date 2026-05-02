function [x, y, meta] = extract_bodypart_positions_from_trial_info(trial_info, body_part, trial_sel)
%EXTRACT_BODYPART_POSITIONS_FROM_TRIAL_INFO
% Collect x/y position samples for one body part across selected trials.
%
% Inputs
%   trial_info : struct array
%   body_part  : e.g. 'LeftPaw'
%   trial_sel  : vector of trial indices; default = all trials
%
% Outputs
%   x, y       : concatenated column vectors
%   meta       : struct with bookkeeping fields

    if nargin < 3 || isempty(trial_sel)
        trial_sel = 1:numel(trial_info);
    end

    x_cell = {};
    y_cell = {};
    trial_idx_cell = {};

    n_kept_trials = 0;
    n_skipped_trials = 0;

    for ii = 1:numel(trial_sel)
        k = trial_sel(ii);

        if k < 1 || k > numel(trial_info)
            n_skipped_trials = n_skipped_trials + 1;
            continue
        end

        if ~isfield(trial_info(k), body_part)
            n_skipped_trials = n_skipped_trials + 1;
            continue
        end

        S = trial_info(k).(body_part);

        if ~isfield(S, 'x_rel_cm') || ~isfield(S, 'y_rel_cm')
            n_skipped_trials = n_skipped_trials + 1;
            continue
        end

        xk = S.x_rel_cm;
        yk = S.y_rel_cm;

        if isempty(xk) || isempty(yk)
            n_skipped_trials = n_skipped_trials + 1;
            continue
        end

        xk = xk(:);
        yk = yk(:);

        n = min(numel(xk), numel(yk));
        xk = xk(1:n);
        yk = yk(1:n);

        good = isfinite(xk) & isfinite(yk);
        xk = xk(good);
        yk = yk(good);

        if isempty(xk)
            n_skipped_trials = n_skipped_trials + 1;
            continue
        end

        x_cell{end+1,1} = xk; %#ok<AGROW>
        y_cell{end+1,1} = yk; %#ok<AGROW>
        trial_idx_cell{end+1,1} = repmat(k, numel(xk), 1); %#ok<AGROW>

        n_kept_trials = n_kept_trials + 1;
    end

    if isempty(x_cell)
        x = [];
        y = [];
        trial_idx = [];
    else
        x = vertcat(x_cell{:});
        y = vertcat(y_cell{:});
        trial_idx = vertcat(trial_idx_cell{:});
    end

    meta = struct();
    meta.body_part = string(body_part);
    meta.trial_sel = trial_sel(:);
    meta.trial_idx_per_sample = trial_idx;
    meta.n_samples = numel(x);
    meta.n_kept_trials = n_kept_trials;
    meta.n_skipped_trials = n_skipped_trials;
end