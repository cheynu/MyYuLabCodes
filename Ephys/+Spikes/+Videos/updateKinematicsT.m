function Tnew = updateKinematicsT(Told, varargin)
%UPDATEKINEMATICST Upgrade an old kinematics table to the NEW minimal schema.
%
% Jianing Yu (JY) | 2026-03-04
%
% This converts your "old" table (with legacy columns like vx/vy/ax/ay/omega/alpha,
% and duplicated metadata like Time/x/y/head_angle/movement_angle/velocity/angular_velocity)
% into the NEW schema used by your updated pipeline.
%
% Core behavior
% -------------
% 1) Choose the longest contiguous kept segment (based on kept_mask if present;
%    otherwise based on finite head_x/head_y/head_theta_x/head_theta_y/time).
% 2) Recompute movement velocity using:
%      - position smoothing (movmedian)
%      - long-baseline central difference (2k frames)
%      - optional small movmean smoothing on velocity
% 3) Compute:
%      - head_theta (+deg)
%      - head_omega (+deg/s) via unwrap+central difference
%      - movement direction + move_theta (+deg)
%      - slip_angle (+deg), forward_speed, lateral_speed
%      - accel_x/accel_y/accel
% 4) Return ONLY a minimal, clean table (drops legacy columns).
%
% Output columns (30)
% -------------------
% time, head_x, head_y, head_theta_x, head_theta_y, filled_mask, kept_mask, keep_run_mask,
% head_theta, head_theta_deg, head_omega, head_omega_deg,
% move_dx, move_dy, speed, move_dir_x, move_dir_y, move_theta, move_theta_deg,
% slip_angle, slip_angle_deg, forward_speed, lateral_speed,
% accel_x, accel_y, accel,
% Source, lever_phase, trial, anm_session
%
% Name-value options
% ------------------
% 'TimeUnit'          : 'ms' (default) or 'sec' for Told.time
% 'SmoothWin'         : movmedian window in samples for head_x/head_y (default 9)
% 'VelBaselineFrames' : k for 2k-frame central difference velocity (default 3 -> 7 frames)
% 'VelSmoothWin'      : movmean window (samples) applied to vx/vy after diff (default 5)
% 'MinSpeedPxPerSec'  : minimum speed (px/s) to accept move_dir/move_theta/slip (default 5)
%
% Notes on angle conventions (image coordinates, y down)
% ------------------------------------------------------
% head_theta = atan2(head_theta_y, head_theta_x) in your coordinate system:
%   0 rad points to 3 o'clock; +pi/2 points to 6 o'clock; -pi/2 points to 12 o'clock.
% Angles increase clockwise due to y-down coordinates; this is fine if you stay consistent.

p = inputParser;
p.addParameter('TimeUnit', 'ms', @(s) ischar(s) || isstring(s));
p.addParameter('SmoothWin', 9, @(v) isnumeric(v) && isscalar(v) && v>=3);
p.addParameter('VelBaselineFrames', 3, @(v) isnumeric(v) && isscalar(v) && v>=1);
p.addParameter('VelSmoothWin', 5, @(v) isnumeric(v) && isscalar(v) && v>=1);
p.addParameter('MinSpeedPxPerSec', 5, @(v) isnumeric(v) && isscalar(v) && v>=0);
p.parse(varargin{:});

timeUnit    = lower(string(p.Results.TimeUnit));
win         = round(p.Results.SmoothWin);
k           = round(p.Results.VelBaselineFrames);
vwin        = round(p.Results.VelSmoothWin);
minSpeed_ps = p.Results.MinSpeedPxPerSec;

if mod(win,2)==0, win = win + 1; end
if mod(vwin,2)==0, vwin = vwin + 1; end

% ---- required columns (from your old table) ----
mustHave = {'time','head_x','head_y','head_theta_x','head_theta_y'};
for i = 1:numel(mustHave)
    if ~ismember(mustHave{i}, Told.Properties.VariableNames)
        error('updateKinematicsT:MissingColumn', 'Missing required column: %s', mustHave{i});
    end
end

% vectors
t   = Told.time(:);
hx  = Told.head_x(:);
hy  = Told.head_y(:);
thx = Told.head_theta_x(:);
thy = Told.head_theta_y(:);

n = height(Told);

% ---- determine "kept" samples ----
if ismember('kept_mask', Told.Properties.VariableNames)
    kept = logical(Told.kept_mask(:));
else
    kept = true(n,1);
end
kept = kept & isfinite(t) & isfinite(hx) & isfinite(hy) & isfinite(thx) & isfinite(thy);

% ---- pick the longest contiguous kept run ----
[keep_run_mask_full, jj] = local_longest_run(kept);

if isempty(jj)
    % return empty NEW-schema table
    Tnew = local_empty_new_schema(Told);
    return
end

% subset first
S = Told(jj, :);

% ensure masks exist
if ~ismember('filled_mask', S.Properties.VariableNames)
    S.filled_mask = false(height(S),1);
end
if ~ismember('kept_mask', S.Properties.VariableNames)
    S.kept_mask = true(height(S),1);
end

% after subsetting, this is all-true by construction
keep_run_mask = true(height(S),1);

% rebind after subsetting
t   = S.time(:);
hx  = S.head_x(:);
hy  = S.head_y(:);
thx = S.head_theta_x(:);
thy = S.head_theta_y(:);

Nseg = numel(t);

% ---- head angle ----
head_theta = atan2(thy, thx);
head_theta_deg = rad2deg(head_theta);

% ---- head omega (rad/s) via unwrap + central difference ----
th_u = unwrap(head_theta);
w = local_central_diff(th_u, t, 1);   % rad/(time unit)
if timeUnit == "ms"
    w = w * 1000;                     % rad/s
end
head_omega = w;
head_omega_deg = rad2deg(head_omega);

% ---- movement velocity from smoothed position ----
hx_s = movmedian(hx, win, 'omitnan');
hy_s = movmedian(hy, win, 'omitnan');

move_dx = nan(Nseg,1);  % px/s
move_dy = nan(Nseg,1);  % px/s

if Nseg >= 2*k + 1
    ii = (1+k):(Nseg-k);
    dt_ik = t(ii+k) - t(ii-k);

    vx_mid = (hx_s(ii+k) - hx_s(ii-k)) ./ dt_ik;
    vy_mid = (hy_s(ii+k) - hy_s(ii-k)) ./ dt_ik;

    if timeUnit == "ms"
        vx_mid = vx_mid * 1000;
        vy_mid = vy_mid * 1000;
    end

    move_dx(ii) = vx_mid;
    move_dy(ii) = vy_mid;

    % small smoothing on velocity itself (keeps same length)
    if vwin >= 3
        move_dx = movmean(move_dx, vwin, 'omitnan');
        move_dy = movmean(move_dy, vwin, 'omitnan');
    end
end

speed = hypot(move_dx, move_dy);

% movement direction + theta (only when speed is meaningful)
goodMove = isfinite(speed) & (speed > minSpeed_ps);

move_dir_x = nan(Nseg,1);
move_dir_y = nan(Nseg,1);
move_theta = nan(Nseg,1);

move_dir_x(goodMove) = move_dx(goodMove) ./ speed(goodMove);
move_dir_y(goodMove) = move_dy(goodMove) ./ speed(goodMove);
move_theta(goodMove) = atan2(move_dy(goodMove), move_dx(goodMove));
move_theta_deg = rad2deg(move_theta);

% ---- slip + forward/lateral ----
slip_angle = nan(Nseg,1);
slip_angle(goodMove) = local_wrapToPi(move_theta(goodMove) - head_theta(goodMove));
slip_angle_deg = rad2deg(slip_angle);

forward_speed = nan(Nseg,1);
lateral_speed = nan(Nseg,1);
forward_speed(goodMove) = speed(goodMove) .* cos(slip_angle(goodMove));
lateral_speed(goodMove) = speed(goodMove) .* sin(slip_angle(goodMove));

% ---- acceleration (px/s^2) from velocity ----
ax = local_central_diff(move_dx, t, 1);   % (px/s)/(time unit)
ay = local_central_diff(move_dy, t, 1);
if timeUnit == "ms"
    ax = ax * 1000;
    ay = ay * 1000;
end
accel_x = ax;
accel_y = ay;
accel = hypot(accel_x, accel_y);

% ---- build NEW minimal table ----
Tnew = table();
Tnew.time          = t(:);
Tnew.head_x        = hx(:);
Tnew.head_y        = hy(:);
Tnew.head_theta_x  = thx(:);
Tnew.head_theta_y  = thy(:);

Tnew.filled_mask   = logical(S.filled_mask(:));
Tnew.kept_mask     = logical(S.kept_mask(:));
Tnew.keep_run_mask = logical(keep_run_mask(:));

Tnew.head_theta     = head_theta(:);
Tnew.head_theta_deg = head_theta_deg(:);
Tnew.head_omega      = head_omega(:);
Tnew.head_omega_deg  = head_omega_deg(:);

Tnew.move_dx       = move_dx(:);
Tnew.move_dy       = move_dy(:);
Tnew.speed         = speed(:);

Tnew.move_dir_x    = move_dir_x(:);
Tnew.move_dir_y    = move_dir_y(:);
Tnew.move_theta    = move_theta(:);
Tnew.move_theta_deg= move_theta_deg(:);

Tnew.slip_angle     = slip_angle(:);
Tnew.slip_angle_deg = slip_angle_deg(:);
Tnew.forward_speed  = forward_speed(:);
Tnew.lateral_speed  = lateral_speed(:);

Tnew.accel_x       = accel_x(:);
Tnew.accel_y       = accel_y(:);
Tnew.accel         = accel(:);

% metadata columns you want to keep (if present)
Tnew.Source      = local_get_col(S, 'Source', "");
Tnew.lever_phase = local_get_col(S, 'lever_phase', "");
Tnew.trial       = local_get_col(S, 'trial', "");
Tnew.anm_session = local_get_col(S, 'anm_session', "");

% (optional) enforce strings for metadata
Tnew.Source      = string(Tnew.Source);
Tnew.lever_phase = string(Tnew.lever_phase);
Tnew.trial       = string(Tnew.trial);
Tnew.anm_session = string(Tnew.anm_session);

end

% ==================== helpers ====================

function [mask, jj] = local_longest_run(m)
m = m(:);
d = diff([false; m; false]);
starts = find(d==1);
ends   = find(d==-1) - 1;

mask = false(size(m));
jj = [];

if isempty(starts)
    return
end

len = ends - starts + 1;
[~, k] = max(len);

jj = (starts(k):ends(k))';
mask(jj) = true;
end

function dv = local_central_diff(v, t, k)
% Central difference derivative over baseline 2k, output same size with NaNs at edges.
v = v(:);
t = t(:);
n = numel(v);

dv = nan(n,1);
if n < 2*k + 1
    return
end

ii = (1+k):(n-k);
dt = t(ii+k) - t(ii-k);

v1 = v(ii+k);
v0 = v(ii-k);

good = isfinite(v1) & isfinite(v0) & isfinite(dt) & (dt ~= 0);
tmp = nan(size(ii));
tmp(good) = (v1(good) - v0(good)) ./ dt(good);

dv(ii) = tmp;
end

function a = local_wrapToPi(a)
a = mod(a + pi, 2*pi) - pi;
end

function v = local_get_col(T, name, defaultVal)
if ismember(name, T.Properties.VariableNames)
    v = T.(name);
else
    v = repmat(defaultVal, height(T), 1);
end
end

function T0 = local_empty_new_schema(Told)
% Return empty table with the new schema vars, so downstream code doesn't crash.
T0 = table();
vars = {'time','head_x','head_y','head_theta_x','head_theta_y','filled_mask','kept_mask','keep_run_mask', ...
        'head_theta','head_theta_deg','head_omega','head_omega_deg', ...
        'move_dx','move_dy','speed','move_dir_x','move_dir_y','move_theta','move_theta_deg', ...
        'slip_angle','slip_angle_deg','forward_speed','lateral_speed', ...
        'accel_x','accel_y','accel','Source','lever_phase','trial','anm_session'};
for i = 1:numel(vars)
    nm = vars{i};
    if any(strcmp(nm, {'filled_mask','kept_mask','keep_run_mask'}))
        T0.(nm) = false(0,1);
    elseif any(strcmp(nm, {'Source','lever_phase','trial','anm_session'}))
        T0.(nm) = strings(0,1);
    else
        T0.(nm) = nan(0,1);
    end
end
end