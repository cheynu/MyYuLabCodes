function T = head_pose_table_from_ears(time, x, y, tracking_lh, varargin)
% 2026.2.27 very much polished version JY
% HEAD_POSE_TABLE_FROM_EARS
% Compute head position (ear midpoint) and head direction (cw-perp of L->R ear vector),
% then fill ONLY short INTERNAL gaps (do NOT fill gaps touching segment edges).
% fill ONLY short INTERNAL gaps, then REMOVE short "islands" of kept data.
% e.g., the one good frame will not be counted
    % 2.1009e+06    163.53    276.46      -0.91082          -0.4128        false         true   
    % 2.1009e+06    162.15    272.29      -0.91455         -0.40447        false         true   
    % 2.1009e+06    161.49    269.56      -0.90761         -0.41981        false         true   
    % 2.1009e+06       NaN       NaN           NaN              NaN        false         false  
    % 2.1009e+06       NaN       NaN           NaN              NaN        false         false  
    % 2.1009e+06       NaN       NaN           NaN              NaN        false         false  
    % 2.1009e+06       NaN       NaN           NaN              NaN        false         false  
    % 2.1009e+06       NaN       NaN           NaN              NaN        false         false  
    % 2.1009e+06       NaN       NaN           NaN              NaN        false         false  
    %  2.101e+06       NaN       NaN           NaN              NaN        false         false  
    %  2.101e+06       NaN       NaN           NaN              NaN        false         false  
    %  2.101e+06       NaN       NaN           NaN              NaN        false         false  
    %  2.101e+06       NaN       NaN           NaN              NaN        false         false  
    %  2.101e+06       NaN       NaN           NaN              NaN        false         false  
    %  2.101e+06       NaN       NaN           NaN              NaN        false         false  
    %  2.101e+06       NaN       NaN           NaN              NaN        false         false  
    %  2.101e+06       NaN       NaN           NaN              NaN        false         false  
    %  2.101e+06       NaN       NaN           NaN              NaN        false         false  
    %  2.101e+06    132.96    222.45      -0.88528         -0.46506        false         true   
    % 2.1011e+06       NaN       NaN           NaN              NaN        false         false  
    % 2.1011e+06       NaN       NaN           NaN              NaN        false         false 
% Output table columns:
%   time, head_x, head_y, head_theta_x, head_theta_y, filled_mask, kept_mask
%
% Inputs
%   time        : 1xN or Nx1 time vector (seconds)
%   x, y        : structs with fields EarLTop, EarRTop
%   tracking_lh : 1xN likelihood/confidence (same length)
%
% Name-value options
%   'Thresh'     : likelihood threshold (default 0.9)
%   'MaxGapSec'  : max gap duration to fill (seconds, default 0.15)
%   'MinVecNorm' : minimum norm of ear vector to accept (pixels, default 1e-6)
%   'MinKeepSec' : minimum sec of data to keep (segment shorter than this
%   will be deleted)

% Notes
% - Direction is represented as a UNIT VECTOR (theta_x, theta_y), which avoids angle wrap issues.
% - Clockwise perp of left->right vector: [dx,dy] -> [dy,-dx]
% - If your coordinate system is image-like (y down), this definition still works consistently
%   as a vector field; convert to angle later with atan2 as you prefer.

% 2026.2.27 polished version JY
% Compute head position (ear midpoint) and head direction (cw-perp of L->R ear vector),
% fill ONLY short INTERNAL gaps (do NOT fill gaps touching segment edges),
% remove short "islands" of kept data,
% then compute movement direction/speed ONLY on the longest contiguous kept segment.


% HEAD_POSE_TABLE_FROM_EARS  Build head-pose + kinematics table from ear tracks.
%
% Jianing Yu (JY), 
% Last updated: 2026-03-04
%
% Overview
% --------
% This function computes (i) head position, (ii) head heading direction, and (iii) movement
% kinematics from tracked ear coordinates (e.g., DeepLabCut outputs). It is designed to be
% robust to missing frames by:
%   1) Defining "valid" frames by likelihood threshold + finite coordinates.
%   2) Filling ONLY short *internal* gaps (gaps that are bracketed by valid samples).
%      - Gaps touching the beginning/end of a valid segment are NOT filled.
%   3) Removing short "islands" of kept data (e.g., 1–2 frames) after filling.
%   4) Keeping ONLY the longest contiguous kept segment, and returning T for that segment
%      only (rows outside the longest segment are removed, not merely set to NaN).
%
% Coordinate convention (image coordinates: y down)
% -------------------------------------------------
% Most video tracking is in image coordinates where:
%   - x increases to the right
%   - y increases downward
%
% The function does NOT attempt to "correct" for this. Instead, it uses consistent vector
% definitions in this coordinate system, which is perfectly valid as long as you interpret
% angles consistently.
%
% Head direction definition
% -------------------------
% Let the ear vector be from Left ear to Right ear:
%   dx = xR - xL
%   dy = yR - yL
%
% We define head heading direction as the CLOCKWISE perpendicular of the L->R ear vector:
%   [dx, dy] -> [dy, -dx]
%
% Why clockwise perp?
%   - With typical ear labeling (left/right in the animal's body frame), the perpendicular
%     vector points approximately "forward" along the head direction.
%   - In y-down coordinates, the same algebra still produces a consistent vector field.
%
% We store head direction as a UNIT VECTOR:
%   head_theta_x = cos(theta)
%   head_theta_y = sin(theta)
% computed from the normalized [dy, -dx]. This avoids wrap issues at ±pi.
%
% Converting the head direction vector to an angle
% ------------------------------------------------
% The heading angle in radians is:
%   head_theta = atan2(head_theta_y, head_theta_x)
%
% IMPORTANT: In y-down coordinates, atan2 still returns a mathematically consistent angle
% for the coordinate system you are using. If you need angles in a y-up coordinate system,
% you can flip y before angle computations (or negate the returned angle appropriately).
% Practically: keep everything in the same coordinate system throughout your analysis.
%
% Movement direction, slip angle, forward/lateral velocity
% --------------------------------------------------------
% Movement velocity is computed from SMOOTHED head position (hx, hy) using time-aware
% gradients within the longest contiguous segment:
%   vx = d(hx)/dt,  vy = d(hy)/dt
% converted and reported in px/s.
%
% Movement direction angle:
%   move_theta = atan2(vy, vx)
%
% Slip angle (a.k.a. heading error):
%   slip_angle = wrapToPi(move_theta - head_theta)
%
% Forward / lateral speed relative to head heading:
%   forward_speed = speed .* cos(slip_angle)
%   lateral_speed = speed .* sin(slip_angle)
%
% Acceleration
% ------------
% Translational acceleration is computed as the time-derivative of velocity:
%   ax = d(vx)/dt, ay = d(vy)/dt
% reported in px/s^2, along with magnitude:
%   accel = hypot(ax, ay)
%
% Head angular speed
% ------------------
% Head angular speed is computed from heading angle within the kept segment:
%   head_omega = d(unwrap(head_theta))/dt
% reported in rad/s (and deg/s).
%
% Inputs
% ------
% time        : 1xN or Nx1 time vector. Unit is controlled by 'TimeUnit' (default 'ms').
% x, y        : structs with fields:
%                 x.EarLTop, x.EarRTop
%                 y.EarLTop, y.EarRTop
% tracking_lh : 1xN likelihood/confidence (same length)
%
% Name-value options
% ------------------
% 'Thresh'            : likelihood threshold (default 0.9)
% 'MaxGapSec'         : max internal gap duration to fill (seconds, default 0.15)
% 'MinVecNorm'        : minimum ear-vector norm (pixels) to accept direction (default 1e-6)
% 'MinKeepSec'        : minimum segment duration (sec) to keep after fill (default 0.25)
% 'MinKeepFrames'     : override MinKeepSec with explicit frame count (default [])
% 'TimeUnit'          : 'ms' or 'sec' for the time vector (default 'ms')
% 'SmoothWin'         : movmedian window (samples) for hx/hy smoothing (default 9)
% 'MinSpeedPxPerSec'  : minimum speed (px/s) to accept movement direction (default 5)
%
% Output
% ------
% T : table (ONLY the longest contiguous kept segment), columns:
%   time, head_x, head_y,
%   head_theta_x, head_theta_y,
%   filled_mask, kept_mask, keep_run_mask,
%   head_theta, head_theta_deg,
%   head_omega, head_omega_deg,
%   move_dx, move_dy, speed,
%   move_dir_x, move_dir_y,
%   move_theta, move_theta_deg,
%   slip_angle, slip_angle_deg,
%   forward_speed, lateral_speed,
%   accel_x, accel_y, accel
%
% Notes
% -----
% - All kinematic derivatives (v, a, omega) are computed ONLY within the longest segment
%   to avoid NaN contamination and to match the intended downstream usage.
% - If you later want multiple segments (instead of only the longest), we can return a
%   segment id column and compute per segment.
%
% -------------------------------------------------------------------------

p = inputParser;
p.addParameter('Thresh', 0.9, @(v) isnumeric(v) && isscalar(v));
p.addParameter('MaxGapSec', 0.15, @(v) isnumeric(v) && isscalar(v) && v>=0);
p.addParameter('MinVecNorm', 1e-6, @(v) isnumeric(v) && isscalar(v) && v>0);
p.addParameter('MinKeepSec', 0.25, @(v) isnumeric(v) && isscalar(v) && v>=0);
p.addParameter('MinKeepFrames', [], @(v) isempty(v) || (isnumeric(v) && isscalar(v) && v>=1));
p.addParameter('TimeUnit', 'ms', @(s) ischar(s) || isstring(s));  % 'ms' or 'sec'
p.addParameter('SmoothWin', 9, @(v) isnumeric(v) && isscalar(v) && v>=3);
p.addParameter('MinSpeedPxPerSec', 5, @(v) isnumeric(v) && isscalar(v) && v>=0);
p.parse(varargin{:});

thr            = p.Results.Thresh;
maxGapSec      = p.Results.MaxGapSec;
minVecN        = p.Results.MinVecNorm;
minKeepSec     = p.Results.MinKeepSec;
minKeepFrames  = p.Results.MinKeepFrames;
timeUnit       = lower(string(p.Results.TimeUnit));
win            = p.Results.SmoothWin;
minSpeed_ps    = p.Results.MinSpeedPxPerSec;

if mod(win,2)==0, win = win + 1; end

t  = time(:)'; 
xL = x.EarLTop(:)';  yL = y.EarLTop(:)';
xR = x.EarRTop(:)';  yR = y.EarRTop(:)';
q  = tracking_lh(:)';

n = numel(t);
assert(numel(xL)==n && numel(yL)==n && numel(xR)==n && numel(yR)==n && numel(q)==n, ...
    'All inputs must have the same length.');

% ---- raw head position & direction ----
head_x = nan(1,n); head_y = nan(1,n);
head_theta_x = nan(1,n); head_theta_y = nan(1,n);

valid0 = (q > thr) & isfinite(xL) & isfinite(yL) & isfinite(xR) & isfinite(yR);
head_x(valid0) = (xL(valid0) + xR(valid0))/2;
head_y(valid0) = (yL(valid0) + yR(valid0))/2;

dx = xR - xL;
dy = yR - yL;

% cw-perp of L->R is [dy, -dx]
vx_dir = dy;
vy_dir = -dx;

vnorm = hypot(vx_dir, vy_dir);
validVec = valid0 & (vnorm > minVecN);

head_theta_x(validVec) = vx_dir(validVec) ./ vnorm(validVec);
head_theta_y(validVec) = vy_dir(validVec) ./ vnorm(validVec);

valid = validVec & isfinite(head_x) & isfinite(head_y) & isfinite(t);

% ---- dt ----
dt = median(diff(t), 'omitnan');
if ~isfinite(dt) || dt <= 0
    error('Time vector must be increasing with finite dt.');
end

switch timeUnit
    case "ms",  dt_sec = dt / 1000;
    case "sec", dt_sec = dt;
    otherwise,  error('TimeUnit must be ''ms'' or ''sec''.');
end

maxGap = round(maxGapSec / dt_sec);
if isempty(minKeepFrames)
    minKeep = max(2, round(minKeepSec / dt_sec));
else
    minKeep = max(2, round(minKeepFrames));
end

filled_mask = false(1,n);
hx  = head_x; 
hy  = head_y; 
thx = head_theta_x; 
thy = head_theta_y;

% ---- fill short INTERNAL gaps only ----
nanMask = ~valid;
d = diff([0 nanMask 0]);
gapStarts = find(d==1);
gapEnds   = find(d==-1)-1;

for g = 1:numel(gapStarts)
    gs = gapStarts(g); ge = gapEnds(g);
    glen = ge-gs+1;

    if glen > maxGap, continue; end

    left = gs-1; right = ge+1;
    if left < 1 || right > n, continue; end
    if ~(valid(left) && valid(right)), continue; end

    frac = (1:glen) / (glen+1);

    hx(gs:ge)  = hx(left)  + frac*(hx(right)  - hx(left));
    hy(gs:ge)  = hy(left)  + frac*(hy(right)  - hy(left));
    thx(gs:ge) = thx(left) + frac*(thx(right) - thx(left));
    thy(gs:ge) = thy(left) + frac*(thy(right) - thy(left));

    tmpx = thx(gs:ge);
    tmpy = thy(gs:ge);
    nn   = hypot(tmpx, tmpy);
    good = nn > minVecN;

    tmpx(good) = tmpx(good) ./ nn(good);
    tmpy(good) = tmpy(good) ./ nn(good);
    tmpx(~good) = NaN;
    tmpy(~good) = NaN;

    thx(gs:ge) = tmpx;
    thy(gs:ge) = tmpy;

    if any(~good)
        ii = gs:ge;
        hx(ii(~good)) = NaN;
        hy(ii(~good)) = NaN;
    end

    filled_mask(gs:ge) = good;
end

kept_mask = valid | filled_mask;

% ---- remove short kept islands ----
cc = bwconncomp(kept_mask);
for k = 1:cc.NumObjects
    ii = cc.PixelIdxList{k};
    if numel(ii) < minKeep
        kept_mask(ii) = false;
        filled_mask(ii) = false;
    end
end

hx(~kept_mask)  = NaN;
hy(~kept_mask)  = NaN;
thx(~kept_mask) = NaN;
thy(~kept_mask) = NaN;

% ---- longest contiguous kept segment ----
cc2 = bwconncomp(kept_mask);
keep_run_mask = false(1,n);
jj = [];

if cc2.NumObjects > 0
    lens = cellfun(@numel, cc2.PixelIdxList);
    [~, imax] = max(lens);
    jj = cc2.PixelIdxList{imax};
    keep_run_mask(jj) = true;
end

% ---- movement + acceleration ONLY on jj ----
move_dx        = nan(1,n);   % vx in px/s
move_dy        = nan(1,n);   % vy in px/s
speed          = nan(1,n);   % px/s
move_dir_x     = nan(1,n);
move_dir_y     = nan(1,n);
move_theta     = nan(1,n);

accel_x        = nan(1,n);   % ax in px/s^2
accel_y        = nan(1,n);   % ay in px/s^2
accel          = nan(1,n);   % |a| in px/s^2

% head angular speed (rad/s)
head_theta     = atan2(thy, thx);
head_theta(~kept_mask) = NaN;
head_omega     = nan(1,n);   % rad/s
head_omega_deg = nan(1,n);   % deg/s

if ~isempty(jj) && numel(jj) >= max(3, win)

    k = 3; % use a 2k-frame baseline 

    % --- movement from smoothed position ---
    hx_s = movmedian(hx(jj), win, 'omitnan');
    hy_s = movmedian(hy(jj), win, 'omitnan');

    Nseg = numel(jj);

    vx_s = nan(1, Nseg);
    vy_s = nan(1, Nseg);
    sp_s = nan(1, Nseg);

    ii = (1+k):(Nseg-k);

    dt_ik = t(jj(ii+k)) - t(jj(ii-k));      % time unit of t
    vx = (hx_s(ii+k) - hx_s(ii-k)) ./ dt_ik;
    vy = (hy_s(ii+k) - hy_s(ii-k)) ./ dt_ik;

    if timeUnit == "ms"
        vx = vx * 1000;  % px/s
        vy = vy * 1000;
    end

    vx_s(ii) = vx;
    vy_s(ii) = vy;

    % optional small smoothing on velocity (same length)
    vwin = 5;
    vx_s = movmean(vx_s, vwin, 'omitnan');
    vy_s = movmean(vy_s, vwin, 'omitnan');

    sp_s = hypot(vx_s, vy_s);   % 1 x Nseg

    % now this matches:
    speed(jj) = sp_s;

    good = isfinite(sp_s) & (sp_s > minSpeed_ps);

    move_dx(jj(good))    = vx_s(good);
    move_dy(jj(good))    = vy_s(good);

    move_dir_x(jj(good)) = vx_s(good) ./ sp_s(good);
    move_dir_y(jj(good)) = vy_s(good) ./ sp_s(good);

    move_theta(jj(good)) = atan2(vy_s(good), vx_s(good));

    % --- acceleration: derivative of velocity (time-aware) ---
    ax = gradient(vx_s, t(jj));   % (px/s)/(time unit)
    ay = gradient(vy_s, t(jj));

    switch timeUnit
        case "ms"
            ax = ax * 1000;       % px/s^2
            ay = ay * 1000;
        case "sec"
            % already px/s^2
    end

    accel_x(jj) = ax;
    accel_y(jj) = ay;
    accel(jj)   = hypot(ax, ay);

    % --- head angular speed from heading angle (unwrap inside jj) ---
    th = head_theta(jj);
    if all(isfinite(th))
        th_u = unwrap(th);
        w = gradient(th_u, t(jj));      % rad/(time unit)
        switch timeUnit
            case "ms"
                w = w * 1000;           % rad/s
            case "sec"
                % already rad/s
        end
        head_omega(jj) = w;
        head_omega_deg(jj) = rad2deg(w);
    else
        % If any NaNs sneak in (shouldn't within kept run), compute on finite subset
        finite = isfinite(th) & isfinite(t(jj));
        if nnz(finite) >= 3
            th_u = unwrap(th(finite));
            w = gradient(th_u, t(jj(finite)));
            switch timeUnit
                case "ms"
                    w = w * 1000;
            end
            tmp = nan(size(th));
            tmp(finite) = w;
            head_omega(jj) = tmp;
            head_omega_deg(jj) = rad2deg(tmp);
        end
    end
end

move_theta_deg = rad2deg(move_theta);

% ---- slip/forward/lateral ----
slip_angle     = wrapToPi(move_theta - head_theta);
slip_angle_deg = rad2deg(slip_angle);

forward_speed = speed .* cos(slip_angle);   % px/s
lateral_speed = speed .* sin(slip_angle);   % px/s

% head_theta definition
%  	•	0 = pointing to 3 o'clock (+x)
% 	•	+\pi/2 = pointing to 6 o'clock (+y, down)
% 	•	-\pi/2 = pointing to 12 o'clock (−y, up)
% 	•	+\pi or -\pi = pointing to 9 o'clock (−x)

% •	slip_angle < 0 → left, lateral speed < 0
% •	slip_angle > 0 → right, lateral speed > 0

% ---- build table ----
T = table( ...
    t(:), hx(:), hy(:), thx(:), thy(:), ...
    filled_mask(:), kept_mask(:), keep_run_mask(:), ...
    head_theta(:), rad2deg(head_theta(:)), ...
    head_omega(:), head_omega_deg(:), ...
    move_dx(:), move_dy(:), speed(:), ...
    move_dir_x(:), move_dir_y(:), move_theta(:), move_theta_deg(:), ...
    slip_angle(:), slip_angle_deg(:), forward_speed(:), lateral_speed(:), ...
    accel_x(:), accel_y(:), accel(:), ...
    'VariableNames', {'time','head_x','head_y','head_theta_x','head_theta_y', ...
                      'filled_mask','kept_mask','keep_run_mask', ...
                      'head_theta','head_theta_deg', ...
                      'head_omega','head_omega_deg', ...
                      'move_dx','move_dy','speed', ...
                      'move_dir_x','move_dir_y','move_theta','move_theta_deg', ...
                      'slip_angle','slip_angle_deg','forward_speed','lateral_speed', ...
                      'accel_x','accel_y','accel'} );

% ---- KEEP ONLY the longest segment rows ----
if any(keep_run_mask)
    T = T(T.keep_run_mask, :);
else
    T = T([],:);
end

end