function [T, meta] = add_topview_features(T, anchor, varargin)
%ADD_TOPVIEW_FEATURES Add lever-centered and cm-scaled top-view features.
%
% [T, meta] = add_topview_features(T, anchor)
%
% Required input:
%   T       : top-view tracking table
%   anchor  : struct returned by estimate_topview_lever_anchor, with fields
%             .x_px and .y_px
%
% Required columns in T:
%   head_x, head_y
%
% Optional columns used when present:
%   move_dx, move_dy, speed
%   forward_speed, lateral_speed
%   accel_x, accel_y, accel
%   head_theta, head_omega
%
% Name-value pairs:
%   'PxPerCm' : pixels per cm, default 25
%
% Output:
%   T    : table with appended feature columns
%   meta : struct with scale and anchor info

    p = inputParser;
    addRequired(p, 'T', @istable);
    addRequired(p, 'anchor', @(x)isstruct(x) && isfield(x, 'x_px') && isfield(x, 'y_px'));
    addParameter(p, 'PxPerCm', 25, @(x)isnumeric(x) && isscalar(x) && x > 0);
    parse(p, T, anchor, varargin{:});
    ops = p.Results;

    required_vars = {'head_x', 'head_y'};
    missing_vars = required_vars(~ismember(required_vars, T.Properties.VariableNames));
    if ~isempty(missing_vars)
        error('add_topview_features:MissingVariable', ...
            'Missing required variable(s): %s', strjoin(missing_vars, ', '));
    end

    px_per_cm = ops.PxPerCm;

    % Relative head position to lever
    T.head_x_rel_px = T.head_x - anchor.x_px;
    T.head_y_rel_px = T.head_y - anchor.y_px;

    T.head_x_rel_cm = T.head_x_rel_px / px_per_cm;
    T.head_y_rel_cm = T.head_y_rel_px / px_per_cm;

    % Velocity in image/world coordinates
    if ismember('move_dx', T.Properties.VariableNames)
        T.vx_cm_s = T.move_dx / px_per_cm;
    end

    if ismember('move_dy', T.Properties.VariableNames)
        T.vy_cm_s = T.move_dy / px_per_cm;
    end

    if ismember('speed', T.Properties.VariableNames)
        T.speed_cm_s = T.speed / px_per_cm;
    end

    % Egocentric motion
    if ismember('forward_speed', T.Properties.VariableNames)
        T.forward_speed_cm_s = T.forward_speed / px_per_cm;
    end

    if ismember('lateral_speed', T.Properties.VariableNames)
        T.lateral_speed_cm_s = T.lateral_speed / px_per_cm;
    end

    % Acceleration
    if ismember('accel_x', T.Properties.VariableNames)
        T.accel_x_cm_s2 = T.accel_x / px_per_cm;
    end

    if ismember('accel_y', T.Properties.VariableNames)
        T.accel_y_cm_s2 = T.accel_y / px_per_cm;
    end

    if ismember('accel', T.Properties.VariableNames)
        T.accel_cm_s2 = T.accel / px_per_cm;
    end

    % Circular heading features
    if ismember('head_theta', T.Properties.VariableNames)
        T.head_theta_cos = cos(T.head_theta);
        T.head_theta_sin = sin(T.head_theta);
    end

    % Keep angular variables as-is
    % head_omega is assumed to already be in rad/s if computed from head_theta
    % so we do not rescale it.
    % head_omega_deg is similarly kept unchanged.

    % Distance to lever
    T.dist_to_lever_cm = hypot(T.head_x_rel_cm, T.head_y_rel_cm);

    % Approach speed: projection of motion toward lever
    if all(ismember({'move_dx', 'move_dy'}, T.Properties.VariableNames))
        rx = -T.head_x_rel_px;   % vector from current head position to lever
        ry = -T.head_y_rel_px;
        rnorm = hypot(rx, ry);

        ux = nan(height(T), 1);
        uy = nan(height(T), 1);

        good = isfinite(rnorm) & rnorm > 0;
        ux(good) = rx(good) ./ rnorm(good);
        uy(good) = ry(good) ./ rnorm(good);

        T.approach_speed_cm_s = (T.move_dx .* ux + T.move_dy .* uy) / px_per_cm;
    end

    meta = struct();
    meta.anchor = anchor;
    meta.px_per_cm = px_per_cm;
    meta.feature_source = 'topview';
end