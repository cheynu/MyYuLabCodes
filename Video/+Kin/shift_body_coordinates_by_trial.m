function B2 = shift_body_coordinates_by_trial(B, x_col, y_col, valid_col, shift_ms, bin_ms)
% shift_body_coordinates_by_trial
% Shift body coordinates within each trial by a fixed time offset.
%
% INPUT
%   B         : trial-bin table
%   x_col     : x coordinate column, e.g. 'LeftPaw_x_rel_cm'
%   y_col     : y coordinate column, e.g. 'LeftPaw_y_rel_cm'
%   valid_col : validity column, e.g. 'valid_LeftPaw'
%   shift_ms  : desired shift in ms
%               > 0 means use future coordinates: x(t+shift), y(t+shift)
%               < 0 means use past coordinates:   x(t+shift), y(t+shift)
%   bin_ms    : bin size in ms, e.g. 30
%
% OUTPUT
%   B2        : copy of B with added columns
%       <x_col>_shift
%       <y_col>_shift
%       <valid_col>_shift
%
% EXAMPLE
%   B2 = shift_body_coordinates_by_trial(B, ...
%       'LeftPaw_x_rel_cm', 'LeftPaw_y_rel_cm', 'valid_LeftPaw', 60, 30);
%
% NOTES
%   For shift_ms = +60 and bin_ms = 30:
%       shifted x at row i = original x at row i+2 (within the same trial)
%   Rows shifted out of range are set to NaN / false.

    %-----------------------------
    % checks
    %-----------------------------
    if ~istable(B)
        error('B must be a table.');
    end

    req = ["trial", "time_bin_center", string(x_col), string(y_col), string(valid_col)];
    has_req = ismember(req, string(B.Properties.VariableNames));
    if ~all(has_req)
        missing = req(~has_req);
        error('Missing required columns: %s', strjoin(cellstr(missing), ', '));
    end

    if nargin < 6 || isempty(bin_ms)
        error('bin_ms must be provided.');
    end

    % integer shift in bins
    n_shift = round(shift_ms / bin_ms);

    % copy table
    B2 = B;

    x_shift_col = x_col + "_shift";
    y_shift_col = y_col + "_shift";
    valid_shift_col = valid_col + "_shift";

    B2.(x_shift_col) = nan(height(B2), 1);
    B2.(y_shift_col) = nan(height(B2), 1);
    B2.(valid_shift_col) = false(height(B2), 1);

    %-----------------------------
    % process trial by trial
    %-----------------------------
    trials = unique(B2.trial, "stable");

    for k = 1:numel(trials)
        this_trial = trials(k);
        idx = find(B2.trial == this_trial);

        if isempty(idx)
            continue
        end

        % sort rows within this trial by time
        [~, ord] = sort(B2.time_bin_center(idx), 'ascend');
        idx = idx(ord);

        x = B2.(x_col)(idx);
        y = B2.(y_col)(idx);
        v = logical(B2.(valid_col)(idx));

        n = numel(idx);

        x_new = nan(n,1);
        y_new = nan(n,1);
        v_new = false(n,1);

        for i = 1:n
            j = i + n_shift;

            if j < 1 || j > n
                continue
            end

            x_new(i) = x(j);
            y_new(i) = y(j);
            v_new(i) = v(j);
        end

        B2.(x_shift_col)(idx) = x_new;
        B2.(y_shift_col)(idx) = y_new;
        B2.(valid_shift_col)(idx) = v_new;
    end
end