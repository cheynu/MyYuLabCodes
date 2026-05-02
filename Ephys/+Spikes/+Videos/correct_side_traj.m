function Tout = correct_side_traj(T, varargin)
%CORRECT_SIDE_TRAJ  Apply single-point correction in a long kinematics table and recompute derived columns.
%
% T must contain at least:
%   time, body_part, x, y
% and typically:
%   lh, x_s, y_s, vx, vy, speed, v_forward, v_up, kept_mask, keep_run_mask, run_id
% and metadata (optional but recommended):
%   trial, lever_phase (or lever_phase column name), anm_session
%
% Corrections:
%   If T has x_corrected/y_corrected columns, non-NaN entries will overwrite x/y at those rows.
%   (You can put exactly one corrected point, or multiple; all will be applied.)
%
% Recompute is done PER (trial, lever_phase, body_part). If trial/lever_phase not present,
% it recomputes per body_part across whole table.

p = inputParser;
p.addParameter('SmoothWin', 7, @(v) isnumeric(v) && isscalar(v) && v>=1);
p.addParameter('TimeUnit', 'ms', @(s) ischar(s) || isstring(s));   % 'ms' or 'sec'
p.addParameter('Thresh', [], @(v) isempty(v) || (isnumeric(v)&&isscalar(v))); % if empty, ignore likelihood
p.addParameter('KeepLongestRun', true, @(v) islogical(v) && isscalar(v));
p.addParameter('MinKeepFrames', 5, @(v) isnumeric(v) && isscalar(v) && v>=1);
p.addParameter('ComputeVelAfterTrimming', true, @(v) islogical(v) && isscalar(v));
p.addParameter('ForwardAxis', "x");    % "x","y","neg_x","neg_y" or [ux uy]
p.addParameter('UpAxis', "neg_y");     % same options
p.addParameter('DropNaNs', false, @(v) islogical(v) && isscalar(v)); % set true if you want to drop rows where x/y are NaN
p.parse(varargin{:});

win         = p.Results.SmoothWin;
timeUnit    = lower(string(p.Results.TimeUnit));
thr         = p.Results.Thresh;
keepLongest = p.Results.KeepLongestRun;
minKeep     = round(p.Results.MinKeepFrames);
doVelAfter  = p.Results.ComputeVelAfterTrimming;

if mod(win,2)==0, win = win+1; end

% ---- basic checks ----
assert(istable(T), 'Input must be a table.');
req = {'time','body_part','x','y'};
assert(all(ismember(req, T.Properties.VariableNames)), ...
    'T must contain columns: time, body_part, x, y');

Tout = T;

% ---- apply corrections if present ----
if all(ismember({'x_corrected','y_corrected'}, Tout.Properties.VariableNames))
    mCorr = isfinite(Tout.x_corrected) & isfinite(Tout.y_corrected);
    if any(mCorr)
        Tout.x(mCorr) = Tout.x_corrected(mCorr);
        Tout.y(mCorr) = Tout.y_corrected(mCorr);

        % set likelihood to 1 for corrected points
        if ismember('lh', Tout.Properties.VariableNames)
            Tout.lh(mCorr) = 1;
        elseif ismember('likelihood', Tout.Properties.VariableNames)
            Tout.likelihood(mCorr) = 1;
        end
    end
end

% ---- which grouping keys exist? ----
hasTrial = ismember('trial', Tout.Properties.VariableNames);
hasPhase = ismember('lever_phase', Tout.Properties.VariableNames);

% normalize body_part as string for grouping
bpAll = string(Tout.body_part);

% resolve projection axes
uF = resolve_axis(p.Results.ForwardAxis, "forward");
uU = resolve_axis(p.Results.UpAxis, "up");

% find groups
if hasTrial && hasPhase
    [G, trialG, phaseG, bpG] = findgroups(string(Tout.trial), string(Tout.lever_phase), bpAll);
else
    [G, bpG] = findgroups(bpAll);
    trialG = [];
    phaseG = [];
end

% Pre-create columns if missing (so assignment works)
Tout = ensure_cols_(Tout);

% ---- recompute per group ----
nGroups = max(G);
for g = 1:nGroups
    ii = find(G==g);
    if numel(ii) < 2
        continue
    end

    % sort by time within group
    [~, ord] = sort(Tout.time(ii));
    ii = ii(ord);

    t = double(Tout.time(ii));
    x = double(Tout.x(ii));
    y = double(Tout.y(ii));

    % kept_mask definition
    kept_mask = isfinite(t) & isfinite(x) & isfinite(y);
    if ~isempty(thr) && ismember('lh', Tout.Properties.VariableNames)
        lh = double(Tout.lh(ii));
        kept_mask = kept_mask & isfinite(lh) & (lh > thr);
    end

    % runs
    if keepLongest
        [run_id, keep_run_mask] = longest_true_run(kept_mask, minKeep);
    else
        keep_run_mask = kept_mask;
        run_id = label_true_runs(kept_mask);
    end

    % trim outside keep_run_mask
    x_trim = x; y_trim = y;
    x_trim(~keep_run_mask) = NaN;
    y_trim(~keep_run_mask) = NaN;

    % smooth
    if win > 1
        xs = movmedian(x_trim, win, 'omitnan');
        ys = movmedian(y_trim, win, 'omitnan');
    else
        xs = x_trim; ys = y_trim;
    end

    % velocity arrays
    vx = nan(size(xs));
    vy = nan(size(ys));
    sp = nan(size(xs));
    vF = nan(size(xs));
    vU = nan(size(xs));

    if doVelAfter
      % velocity arrays
vx = nan(size(xs));
vy = nan(size(ys));
sp = nan(size(xs));
vF = nan(size(xs));
vU = nan(size(xs));

% parameters for velocity estimate
k_   = 3;   % +/- k frames for centered diff
vwin = 5;   % smoothing window on velocity

if doVelAfter
    jj = find(keep_run_mask);

    % need enough points for centered + endpoints
    if numel(jj) >= max(3, win) && numel(jj) >= (2*k_+1)

        % work on the kept segment only
        xs_s = xs(jj);
        ys_s = ys(jj);

        Nseg = numel(jj);

        vx_s = nan(Nseg,1);
        vy_s = nan(Nseg,1);

        % -------------------------
        % A) centered difference (middle)
        % -------------------------
        ii_mid = (1+k_):(Nseg-k_);
        dt_mid = t(jj(ii_mid+k_)) - t(jj(ii_mid-k_));
        good_mid = isfinite(dt_mid) & (dt_mid > 0);

        vx_mid = nan(numel(ii_mid),1);
        vy_mid = nan(numel(ii_mid),1);

        vx_mid(good_mid) = (xs_s(ii_mid(good_mid)+k_) - xs_s(ii_mid(good_mid)-k_)) ./ dt_mid(good_mid);
        vy_mid(good_mid) = (ys_s(ii_mid(good_mid)+k_) - ys_s(ii_mid(good_mid)-k_)) ./ dt_mid(good_mid);

        vx_s(ii_mid) = vx_mid;
        vy_s(ii_mid) = vy_mid;

        % -------------------------
        % B) forward difference (first k_ points)
        % v(i) = (x(i+k)-x(i)) / (t(i+k)-t(i))
        % -------------------------
        ii_L = 1:k_;
        dtL = t(jj(ii_L+k_)) - t(jj(ii_L));
        goodL = isfinite(dtL) & (dtL > 0);

        vxL = nan(numel(ii_L),1);
        vyL = nan(numel(ii_L),1);

        vxL(goodL) = (xs_s(ii_L(goodL)+k_) - xs_s(ii_L(goodL))) ./ dtL(goodL);
        vyL(goodL) = (ys_s(ii_L(goodL)+k_) - ys_s(ii_L(goodL))) ./ dtL(goodL);

        vx_s(ii_L) = vxL;
        vy_s(ii_L) = vyL;

        % -------------------------
        % C) backward difference (last k_ points)
        % v(i) = (x(i)-x(i-k)) / (t(i)-t(i-k))
        % -------------------------
        ii_R = (Nseg-k_+1):Nseg;
        dtR = t(jj(ii_R)) - t(jj(ii_R-k_));
        goodR = isfinite(dtR) & (dtR > 0);

        vxR = nan(numel(ii_R),1);
        vyR = nan(numel(ii_R),1);

        vxR(goodR) = (xs_s(ii_R(goodR)) - xs_s(ii_R(goodR)-k_)) ./ dtR(goodR);
        vyR(goodR) = (ys_s(ii_R(goodR)) - ys_s(ii_R(goodR)-k_)) ./ dtR(goodR);

        vx_s(ii_R) = vxR;
        vy_s(ii_R) = vyR;

        % convert to per-second once
        if timeUnit == "ms"
            vx_s = vx_s * 1000;
            vy_s = vy_s * 1000;
        elseif timeUnit ~= "sec"
            error("TimeUnit must be 'ms' or 'sec'.");
        end

        % optional small smoothing on velocity (within kept segment)
        if vwin > 1
            vx_s = movmean(vx_s, vwin, 'omitnan');
            vy_s = movmean(vy_s, vwin, 'omitnan');
        end

        sp_s = hypot(vx_s, vy_s);

        % write back into full arrays (only jj indices)
        vx(jj) = vx_s;
        vy(jj) = vy_s;
        sp(jj) = sp_s;

        vF(jj) = vx_s*uF(1) + vy_s*uF(2);
        vU(jj) = vx_s*uU(1) + vy_s*uU(2);
    end
end

    % write back
    Tout.kept_mask(ii)     = logical(kept_mask);
    Tout.keep_run_mask(ii) = logical(keep_run_mask);
    Tout.run_id(ii)        = double(run_id);

    Tout.x_s(ii) = xs;
    Tout.y_s(ii) = ys;

    Tout.vx(ii) = vx;
    Tout.vy(ii) = vy;
    Tout.speed(ii) = sp;
    Tout.v_forward(ii) = vF;
    Tout.v_up(ii) = vU;
end

if p.Results.DropNaNs
    Tout = Tout(isfinite(Tout.x) & isfinite(Tout.y), :);
end

end
end

% ================= helpers =================

function T = ensure_cols_(T)
need = {'kept_mask','keep_run_mask','run_id','x_s','y_s','vx','vy','speed','v_forward','v_up'};
for k = 1:numel(need)
    nm = need{k};
    if ~ismember(nm, T.Properties.VariableNames)
        switch nm
            case {'kept_mask','keep_run_mask'}
                T.(nm) = false(height(T),1);
            otherwise
                T.(nm) = nan(height(T),1);
        end
    end
end
end

function [run_id, keep_run_mask] = longest_true_run(mask, minKeep)
n = numel(mask);
run_id = zeros(n,1,'uint16');
keep_run_mask = false(n,1);

if ~any(mask), return; end

d = diff([false; mask(:); false]);
starts = find(d==1);
ends   = find(d==-1)-1;

lens = ends - starts + 1;
[bestLen, ibest] = max(lens);

if bestLen < minKeep
    return
end

for r = 1:numel(starts)
    run_id(starts(r):ends(r)) = uint16(r);
end

keep_run_mask(starts(ibest):ends(ibest)) = true;
end

function run_id = label_true_runs(mask)
n = numel(mask);
run_id = zeros(n,1,'uint16');
if ~any(mask), return; end
d = diff([false; mask(:); false]);
starts = find(d==1);
ends   = find(d==-1)-1;
for r = 1:numel(starts)
    run_id(starts(r):ends(r)) = uint16(r);
end
end

function u = resolve_axis(axisSpec, which)
if isnumeric(axisSpec) && numel(axisSpec)==2
    u = axisSpec(:).';
    n = hypot(u(1), u(2));
    if n==0, error('%s axis vector cannot be zero.', which); end
    u = u ./ n;
    return;
end
s = lower(string(axisSpec));
switch s
    case "x",     u = [1 0];
    case "neg_x", u = [-1 0];
    case "y",     u = [0 1];
    case "neg_y", u = [0 -1];
    otherwise
        error('Unknown %s axis spec: %s', which, s);
end
end