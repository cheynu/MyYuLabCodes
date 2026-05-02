function T = add_kinematics_columns(T, varargin)
% NO LONGER NEEDED FROM 3/4/2026 JY. EVERYTHING IS COMPUTED IN function T = head_pose_table_from_ears(time, x, y, tracking_lh, varargin)

%ADD_KINEMATICS_COLUMNS Add velocity + acceleration (linear and angular) to pose table.
%
% Assumes T has:
%   time (ms by default), head_x, head_y, head_theta_x, head_theta_y, kept_mask
%
% Adds:
%   vx, vy, speed
%   ax, ay, accel
%   omega (rad/s), omega_deg
%   alpha (rad/s^2), alpha_deg
%
% Name-value:
%   'TimeUnit' : 'ms' (default) or 'sec'

p = inputParser;
p.addParameter('TimeUnit', 'ms', @(s) ischar(s) || isstring(s));
p.parse(varargin{:});
timeUnit = lower(string(p.Results.TimeUnit));

t = T.time(:);
switch timeUnit
    case "ms"
        tsec = t / 1000;
    case "sec"
        tsec = t;
    otherwise
        error('TimeUnit must be ''ms'' or ''sec''.');
end

n = height(T);

% initialize outputs
vx = nan(n,1); vy = nan(n,1); speed = nan(n,1);
ax = nan(n,1); ay = nan(n,1); accel = nan(n,1);

omega = nan(n,1); omega_deg = nan(n,1);
alpha = nan(n,1); alpha_deg = nan(n,1);

% require position + direction + time to be finite
k = T.kept_mask(:) & isfinite(T.head_x) & isfinite(T.head_y) & ...
    isfinite(T.head_theta_x) & isfinite(T.head_theta_y) & isfinite(tsec);

% contiguous kept segments (toolbox-free)
d = diff([false; k; false]);
starts = find(d==1);
ends   = find(d==-1)-1;

for s = 1:numel(starts)
    idx = (starts(s):ends(s))';
    if numel(idx) < 3
        % need at least 3 samples for acceleration to be meaningful
        continue
    end

    tt = tsec(idx);

    % --- linear velocity (px/s) ---
    xx = T.head_x(idx);
    yy = T.head_y(idx);

    vx(idx) = gradient(xx, tt);
    vy(idx) = gradient(yy, tt);
    speed(idx) = hypot(vx(idx), vy(idx));

    % --- linear acceleration (px/s^2) ---
    ax(idx) = gradient(vx(idx), tt);
    ay(idx) = gradient(vy(idx), tt);
    accel(idx) = hypot(ax(idx), ay(idx));

    % --- angular velocity from unit vectors (wrap-safe) ---
    ux = T.head_theta_x(idx);
    uy = T.head_theta_y(idx);

    crossz = ux(1:end-1).*uy(2:end) - uy(1:end-1).*ux(2:end);
    dotuv  = ux(1:end-1).*ux(2:end) + uy(1:end-1).*uy(2:end);
    dtheta = atan2(crossz, dotuv);          % radians between successive directions
    dt     = diff(tt);                      % seconds
    w_mid  = dtheta ./ dt;                  % rad/s (length = numel(idx)-1)

    % align omega to samples (simple, consistent)
    omega(idx(2:end)) = w_mid;
    omega(idx(1)) = omega(idx(2));
    omega_deg(idx) = rad2deg(omega(idx));

    % --- angular acceleration (rad/s^2) ---
    alpha(idx) = gradient(omega(idx), tt);
    alpha_deg(idx) = rad2deg(alpha(idx));
end

% attach to table
T.vx = vx; T.vy = vy; T.speed = speed;
T.ax = ax; T.ay = ay; T.accel = accel;

T.omega = omega; T.omega_deg = omega_deg;
T.alpha = alpha; T.alpha_deg = alpha_deg;
end