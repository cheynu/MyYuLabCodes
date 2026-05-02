function T = ensure_topview_base_columns(T)
%ENSURE_TOPVIEW_BASE_COLUMNS
% Make sure the raw top-view table contains the core kinematic columns
% needed downstream, before px->cm conversion.
%
% It standardizes aliases and computes missing derived variables when
% possible.

% ------------------------------------------------------------
% 1. Simple aliases
% ------------------------------------------------------------
if ~ismember('head_theta', T.Properties.VariableNames) && ismember('head_angle', T.Properties.VariableNames)
    T.head_theta = T.head_angle;
end

if ~ismember('head_theta_deg', T.Properties.VariableNames) && ismember('head_theta', T.Properties.VariableNames)
    T.head_theta_deg = rad2deg(T.head_theta);
end

if ~ismember('head_omega', T.Properties.VariableNames) && ismember('omega', T.Properties.VariableNames)
    T.head_omega = T.omega;
end

if ~ismember('head_omega_deg', T.Properties.VariableNames)
    if ismember('omega_deg', T.Properties.VariableNames)
        T.head_omega_deg = T.omega_deg;
    elseif ismember('head_omega', T.Properties.VariableNames)
        T.head_omega_deg = rad2deg(T.head_omega);
    end
end

if ~ismember('move_dx', T.Properties.VariableNames) && ismember('vx', T.Properties.VariableNames)
    T.move_dx = T.vx;
end

if ~ismember('move_dy', T.Properties.VariableNames) && ismember('vy', T.Properties.VariableNames)
    T.move_dy = T.vy;
end

if ~ismember('accel_x', T.Properties.VariableNames) && ismember('ax', T.Properties.VariableNames)
    T.accel_x = T.ax;
end

if ~ismember('accel_y', T.Properties.VariableNames) && ismember('ay', T.Properties.VariableNames)
    T.accel_y = T.ay;
end

% ------------------------------------------------------------
% 2. move_dir_x / move_dir_y
% ------------------------------------------------------------
if (~ismember('move_dir_x', T.Properties.VariableNames) || ...
    ~ismember('move_dir_y', T.Properties.VariableNames)) && ...
    ismember('move_dx', T.Properties.VariableNames) && ...
    ismember('move_dy', T.Properties.VariableNames)

    sp = hypot(T.move_dx, T.move_dy);
    good = isfinite(sp) & sp > 0;

    if ~ismember('move_dir_x', T.Properties.VariableNames)
        T.move_dir_x = nan(height(T),1);
        T.move_dir_x(good) = T.move_dx(good) ./ sp(good);
    end

    if ~ismember('move_dir_y', T.Properties.VariableNames)
        T.move_dir_y = nan(height(T),1);
        T.move_dir_y(good) = T.move_dy(good) ./ sp(good);
    end
end

% ------------------------------------------------------------
% 3. move_theta / move_theta_deg
% ------------------------------------------------------------
if ~ismember('move_theta', T.Properties.VariableNames)
    if ismember('movement_angle', T.Properties.VariableNames)
        T.move_theta = T.movement_angle;
    elseif ismember('move_dir_x', T.Properties.VariableNames) && ...
           ismember('move_dir_y', T.Properties.VariableNames)
        T.move_theta = atan2(T.move_dir_y, T.move_dir_x);
    elseif ismember('move_dy', T.Properties.VariableNames) && ...
           ismember('move_dx', T.Properties.VariableNames)
        T.move_theta = atan2(T.move_dy, T.move_dx);
    end
end

if ~ismember('move_theta_deg', T.Properties.VariableNames) && ismember('move_theta', T.Properties.VariableNames)
    T.move_theta_deg = rad2deg(T.move_theta);
end

% ------------------------------------------------------------
% 4. head_theta_x / head_theta_y
% ------------------------------------------------------------
if ~ismember('head_theta_x', T.Properties.VariableNames) && ismember('head_theta', T.Properties.VariableNames)
    T.head_theta_x = cos(T.head_theta);
end

if ~ismember('head_theta_y', T.Properties.VariableNames) && ismember('head_theta', T.Properties.VariableNames)
    T.head_theta_y = sin(T.head_theta);
end

% ------------------------------------------------------------
% 5. slip_angle / forward_speed / lateral_speed
% ------------------------------------------------------------
need_slip = ~ismember('slip_angle', T.Properties.VariableNames);
need_fwd  = ~ismember('forward_speed', T.Properties.VariableNames);
need_lat  = ~ismember('lateral_speed', T.Properties.VariableNames);

if (need_slip || need_fwd || need_lat) && ...
        ismember('move_theta', T.Properties.VariableNames) && ...
        ismember('head_theta', T.Properties.VariableNames)

    slip_angle = wrapToPi(T.move_theta - T.head_theta);

    if need_slip
        T.slip_angle = slip_angle;
    end

    if ~ismember('slip_angle_deg', T.Properties.VariableNames)
        T.slip_angle_deg = rad2deg(slip_angle);
    end

    if ismember('speed', T.Properties.VariableNames)
        if need_fwd
            T.forward_speed = T.speed .* cos(slip_angle);
        end
        if need_lat
            T.lateral_speed = T.speed .* sin(slip_angle);
        end
    end
end

% ------------------------------------------------------------
% 6. final required-column check
% ------------------------------------------------------------
if ~ismember('keep_run_mask', T.Properties.VariableNames)
    T.keep_run_mask = true(height(T), 1);
end

required_cols = {'time','head_x','head_y','head_theta_x','head_theta_y', ...
    'filled_mask','kept_mask','keep_run_mask', ...
    'head_theta','head_theta_deg', ...
    'head_omega','head_omega_deg', ...
    'move_dx','move_dy','speed', ...
    'move_dir_x','move_dir_y','move_theta','move_theta_deg', ...
    'slip_angle','slip_angle_deg','forward_speed','lateral_speed', ...
    'accel_x','accel_y','accel'};

missing_cols = required_cols(~ismember(required_cols, T.Properties.VariableNames));
if ~isempty(missing_cols)
    error('Top-view table still missing required columns: %s', strjoin(missing_cols, ', '));
end
end