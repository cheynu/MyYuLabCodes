function linear_info = detect_linear_segments_xy(x, y, time_ms, params)
% detect_linear_segments_xy
% Detect suspicious straight-line trajectory segments, often caused by interpolation.
%
% INPUT
%   x, y      : coordinate vectors
%   time_ms   : timestamp vector (same length)
%   params    : struct with optional fields
%       .min_block_len       minimum consecutive samples in a block (default 4)
%       .max_turn_deg        maximum turning angle in degrees (default 5)
%       .min_total_disp      minimum total displacement in coordinate units (default 0.2)
%       .use_valid_mask      optional logical vector same length as x/y
%
% OUTPUT
%   linear_info : struct
%       .linear_mask
%       .linear_dur_ms
%       .n_linear_blocks
%       .linear_blocks
%       .turn_deg
%
% NOTES
%   This flags runs where the trajectory direction changes very little over
%   consecutive steps. Good for catching straight interpolation bridges.

    if nargin < 4
        params = struct();
    end
    if ~isfield(params, 'min_block_len') || isempty(params.min_block_len)
        params.min_block_len = 4;
    end
    if ~isfield(params, 'max_turn_deg') || isempty(params.max_turn_deg)
        params.max_turn_deg = 5;
    end
    if ~isfield(params, 'min_total_disp') || isempty(params.min_total_disp)
        params.min_total_disp = 0.2;
    end

    x = x(:);
    y = y(:);
    time_ms = time_ms(:);

    n = numel(x);
    linear_mask = false(n,1);

    if n < 3
        linear_info = struct();
        linear_info.linear_mask = linear_mask;
        linear_info.linear_dur_ms = 0;
        linear_info.n_linear_blocks = 0;
        linear_info.linear_blocks = zeros(0,2);
        linear_info.turn_deg = nan(max(n-2,0),1);
        return
    end

    % valid points only
    valid = ~(isnan(x) | isnan(y) | isnan(time_ms));
    if isfield(params, 'use_valid_mask') && ~isempty(params.use_valid_mask)
        valid = valid & logical(params.use_valid_mask(:));
    end

    dx = diff(x);
    dy = diff(y);
    step_norm = hypot(dx, dy);

    % turning angle between consecutive step vectors
    turn_deg = nan(n-2,1);
    for i = 1:n-2
        if ~valid(i) || ~valid(i+1) || ~valid(i+2)
            continue
        end
        v1 = [dx(i), dy(i)];
        v2 = [dx(i+1), dy(i+1)];

        n1 = norm(v1);
        n2 = norm(v2);
        if n1 == 0 || n2 == 0
            continue
        end

        c = dot(v1, v2) / (n1*n2);
        c = max(-1, min(1, c));
        turn_deg(i) = acosd(c);
    end

    % candidate where local turning angle is very small
    cand = false(n,1);
    cand(2:n-1) = turn_deg <= params.max_turn_deg;

    % find contiguous runs in cand
    d = diff([false; cand; false]);
    starts = find(d == 1);
    ends   = find(d == -1) - 1;

    keep_blocks = zeros(0,2);

    for j = 1:numel(starts)
        s = starts(j);
        e = ends(j);

        if (e - s + 1) < params.min_block_len
            continue
        end

        % total displacement across the whole block
        disp_tot = hypot(x(e) - x(s), y(e) - y(s));
        if disp_tot < params.min_total_disp
            continue
        end

        linear_mask(s:e) = true;
        keep_blocks(end+1,:) = [s e]; %#ok<AGROW>
    end

    % duration estimate from timestamps
    linear_dur_ms = 0;
    for j = 1:size(keep_blocks,1)
        s = keep_blocks(j,1);
        e = keep_blocks(j,2);
        linear_dur_ms = linear_dur_ms + (time_ms(e) - time_ms(s));
    end

    linear_info = struct();
    linear_info.linear_mask = linear_mask;
    linear_info.linear_dur_ms = linear_dur_ms;
    linear_info.n_linear_blocks = size(keep_blocks,1);
    linear_info.linear_blocks = keep_blocks;
    linear_info.turn_deg = turn_deg;
end