function Tlong = compute_pawtraj_usingDLC(TrajExtracted, varargin)
% LONG table: one row per (time, body_part).
% Optionally keep only the longest contiguous valid run per body_part (per trial segment).
%
% Columns:
%   time, body_part, x, y, lh, vx, vy, speed, v_forward, v_up,
%   kept_mask, keep_run_mask, run_id
%
% Key options:
%   'KeepLongestRun'  true/false
%   'MinKeepFrames'   minimum frames required for the longest run to be kept
%   'ComputeVelAfterTrimming' (recommended true)

p = inputParser;
p.addParameter('BodyParts', [], @(v) isempty(v) || iscellstr(v) || isstring(v));
p.addParameter('Thresh', 0.8, @(v) isnumeric(v) && isscalar(v));
p.addParameter('TimeUnit', 'ms', @(s) ischar(s) || isstring(s));  % 'ms' or 'sec'
p.addParameter('SmoothWin', 5, @(v) isnumeric(v) && isscalar(v) && v>=1); % 1=no smoothing
p.addParameter('ForwardAxis', "x");  % "x","y","neg_x","neg_y" or [ux uy]
p.addParameter('UpAxis', "neg_y");   % "neg_y" typical for image coords
p.addParameter('KeepLongestRun', true, @(v) islogical(v) && isscalar(v));
p.addParameter('MinKeepFrames', 5, @(v) isnumeric(v) && isscalar(v) && v>=1);
p.addParameter('ComputeVelAfterTrimming', true, @(v) islogical(v) && isscalar(v));
p.parse(varargin{:});

thr      = p.Results.Thresh;
timeUnit = lower(string(p.Results.TimeUnit));
win      = p.Results.SmoothWin;
keepLongest = p.Results.KeepLongestRun;
minKeep = round(p.Results.MinKeepFrames);
doVelAfter = p.Results.ComputeVelAfterTrimming;


if isempty(p.Results.BodyParts)
    ignore = {'Name','IndexSelected','TimeSelected','Tag'};
    fn = fieldnames(TrajExtracted);
    parts = setdiff(fn, ignore);

    keep = false(size(parts));
    for k = 1:numel(parts)
        s = TrajExtracted.(parts{k});
        keep(k) = isstruct(s) && isfield(s,'x') && isfield(s,'y') && isfield(s,'likelihood');
    end
    parts = parts(keep);
else
    parts = cellstr(p.Results.BodyParts);
end

if mod(win,2)==0, win = win + 1; end

% --- time/index ---
assert(isfield(TrajExtracted,'TimeSelected') && ~isempty(TrajExtracted.TimeSelected), ...
    'TrajExtracted.TimeSelected is required.');
t = TrajExtracted.TimeSelected(:);
n = numel(t);

if isfield(TrajExtracted,'IndexSelected') && ~isempty(TrajExtracted.IndexSelected)
    idx = TrajExtracted.IndexSelected(:);
else
    idx = [];
end

% --- choose body parts ---
if isempty(p.Results.BodyParts)
    ignore = {'Name','IndexSelected','TimeSelected','Tag'};
    fn = fieldnames(TrajExtracted);
    parts = setdiff(fn, ignore);

    keep = false(size(parts));
    for k = 1:numel(parts)
        s = TrajExtracted.(parts{k});
        keep(k) = isstruct(s) && isfield(s,'x') && isfield(s,'y') && isfield(s,'likelihood');
    end
    parts = parts(keep);
else
    parts = cellstr(p.Results.BodyParts);
end

% --- axes for projection ---
uF = resolve_axis(p.Results.ForwardAxis, "forward");
uU = resolve_axis(p.Results.UpAxis, "up");

Tcells = cell(numel(parts), 1);

for k = 1:numel(parts)
    part = parts{k};
    P = TrajExtracted.(part);

    if isempty(idx)
        x = P.x(:); y = P.y(:); q = P.likelihood(:);
        if numel(x) ~= n
            error('Part %s length (%d) does not match TimeSelected length (%d). Provide IndexSelected or fix inputs.', ...
                part, numel(x), n);
        end
    else
        x = P.x(idx); y = P.y(idx); q = P.likelihood(idx);
        if numel(x) ~= n
            error('IndexSelected slice for %s does not match TimeSelected length.', part);
        end
    end

    % raw kept mask (before choosing longest run)
    % kept_mask = (q > thr) & isfinite(x) & isfinite(y) & isfinite(t);
    kept_mask =  isfinite(x) & isfinite(y) & isfinite(t);

    % find runs + longest run
    run_id = zeros(n,1,'uint16');
    keep_run_mask = false(n,1);

    if keepLongest
        [run_id, keep_run_mask] = longest_true_run(kept_mask, minKeep);
    else
        keep_run_mask = kept_mask;
        % give each contiguous run an id anyway (handy)
        run_id = label_true_runs(kept_mask);
    end

    % apply trimming: outside keep_run_mask -> NaN
    x(~keep_run_mask) = NaN;
    y(~keep_run_mask) = NaN;

    % smooth (on trimmed)
    if win > 1
        xs = movmedian(x, win, 'omitnan');
        ys = movmedian(y, win, 'omitnan');
    else
        xs = x; ys = y;
    end

    % velocities
    vx = nan(n,1); vy = nan(n,1); sp = nan(n,1);
    vF = nan(n,1); vU = nan(n,1);

    % You can expose these as varargin options if you want
    k_    = 3;   % centered diff half-window (±k frames)
    vwin = 5;   % post-smooth velocity window (frames)

    if doVelAfter
        jj = find(keep_run_mask);     % indices of the trusted contiguous run

        if numel(jj) >= max(3, win) && numel(jj) >= (2*k_+1)

            % % 1) smooth position first (like your head example)
            % xs_s = movmedian(xs(jj), win, 'omitnan');
            % ys_s = movmedian(ys(jj), win, 'omitnan');

            xs_s = xs;
            ys_s = ys;

            Nseg = numel(jj);

            vx_s = nan(Nseg,1);
            vy_s = nan(Nseg,1);

            % -------------------------
            % A) centered difference (middle)
            % -------------------------
            ii = (1+k_):(Nseg-k_);
            dt_ik = t(jj(ii+k_)) - t(jj(ii-k_));   % time unit of t
            good_dt = isfinite(dt_ik) & (dt_ik > 0);

            vx_tmp = nan(numel(ii),1);
            vy_tmp = nan(numel(ii),1);

            vx_tmp(good_dt) = (xs_s(ii(good_dt)+k_) - xs_s(ii(good_dt)-k_)) ./ dt_ik(good_dt);
            vy_tmp(good_dt) = (ys_s(ii(good_dt)+k_) - ys_s(ii(good_dt)-k_)) ./ dt_ik(good_dt);

            vx_s(ii) = vx_tmp;
            vy_s(ii) = vy_tmp;

            % -------------------------
            % B) forward difference (first k_ points)
            % v(i) = (x(i+k)-x(i)) / (t(i+k)-t(i))
            % -------------------------
            iL = 1:k_;
            dtL = t(jj(iL+k_)) - t(jj(iL));
            goodL = isfinite(dtL) & (dtL > 0);

            vxL = nan(numel(iL),1);
            vyL = nan(numel(iL),1);

            vxL(goodL) = (xs_s(iL(goodL)+k_) - xs_s(iL(goodL))) ./ dtL(goodL);
            vyL(goodL) = (ys_s(iL(goodL)+k_) - ys_s(iL(goodL))) ./ dtL(goodL);

            vx_s(iL) = vxL;
            vy_s(iL) = vyL;

            % -------------------------
            % C) backward difference (last k_ points)
            % v(i) = (x(i)-x(i-k)) / (t(i)-t(i-k))
            % -------------------------
            iR = (Nseg-k_+1):Nseg;
            dtR = t(jj(iR)) - t(jj(iR-k_));
            goodR = isfinite(dtR) & (dtR > 0);

            vxR = nan(numel(iR),1);
            vyR = nan(numel(iR),1);

            vxR(goodR) = (xs_s(iR(goodR)) - xs_s(iR(goodR)-k_)) ./ dtR(goodR);
            vyR(goodR) = (ys_s(iR(goodR)) - ys_s(iR(goodR)-k_)) ./ dtR(goodR);

            vx_s(iR) = vxR;
            vy_s(iR) = vyR;

            % -------------------------
            % convert to per-second (apply once to all)
            % -------------------------
            if timeUnit == "ms"
                vx_s = vx_s * 1000;
                vy_s = vy_s * 1000;
            elseif timeUnit ~= "sec"
                error("TimeUnit must be 'ms' or 'sec'.");
            end

            % 2) optional velocity smoothing
            vx_s = movmean(vx_s, vwin, 'omitnan');
            vy_s = movmean(vy_s, vwin, 'omitnan');

            % 3) speed + projections
            sp_s = hypot(vx_s, vy_s);

            % write back into full-length vectors
            vx(jj) = vx_s;
            vy(jj) = vy_s;
            sp(jj) = sp_s;

            vF(jj) = vx_s*uF(1) + vy_s*uU(1)*0; % <- ignore this line; see below
            vF(jj) = vx_s*uF(1) + vy_s*uF(2);
            vU(jj) = vx_s*uU(1) + vy_s*uU(2);

        end

    else % not really being used since i have one contiguous block at this step and we only examine that
        % If you truly want "everywhere", I'd still recommend avoiding bleed across gaps.
        % Here is a safer version that computes on EACH contiguous finite segment.
        finite = isfinite(xs) & isfinite(ys) & isfinite(t);
        segID = cumsum([true; diff(finite) ~= 0]);  % labels runs of finite/non-finite
        segLabels = unique(segID(finite));

        for s = segLabels(:)'
            jj = find(segID == s & finite);
            if numel(jj) < (2*k+1)
                continue
            end

            xs_s = movmedian(xs(jj), win, 'omitnan');
            ys_s = movmedian(ys(jj), win, 'omitnan');

            Nseg = numel(jj);
            vx_s = nan(Nseg,1);
            vy_s = nan(Nseg,1);

            ii = (1+k):(Nseg-k);
            dt_ik = t(jj(ii+k)) - t(jj(ii-k));
            good_dt = isfinite(dt_ik) & (dt_ik > 0);

            vx_tmp = nan(numel(ii),1);
            vy_tmp = nan(numel(ii),1);

            vx_tmp(good_dt) = (xs_s(ii(good_dt)+k) - xs_s(ii(good_dt)-k)) ./ dt_ik(good_dt);
            vy_tmp(good_dt) = (ys_s(ii(good_dt)+k) - ys_s(ii(good_dt)-k)) ./ dt_ik(good_dt);

            if timeUnit == "ms"
                vx_tmp = vx_tmp * 1000;
                vy_tmp = vy_tmp * 1000;
            elseif timeUnit ~= "sec"
                error("TimeUnit must be 'ms' or 'sec'.");
            end

            vx_s(ii) = vx_tmp;
            vy_s(ii) = vy_tmp;

            vx_s = movmean(vx_s, vwin, 'omitnan');
            vy_s = movmean(vy_s, vwin, 'omitnan');

            sp_s = hypot(vx_s, vy_s);

            vx(jj) = vx_s;
            vy(jj) = vy_s;
            sp(jj) = sp_s;
            vF(jj) = vx_s*uF(1) + vy_s*uF(2);
            vU(jj) = vx_s*uU(1) + vy_s*uU(2);
        end
    end

    body_part = repmat(string(part), n, 1);

    Tcells{k} = table(t, body_part, x, y, q, xs, ys, vx, vy, sp, vF, vU, ...
        logical(kept_mask), logical(keep_run_mask), double(run_id), ...
        'VariableNames', {'time','body_part','x','y','lh','x_s','y_s','vx','vy','speed','v_forward','v_up', ...
                          'kept_mask','keep_run_mask','run_id'});
end

Tlong = vertcat(Tcells{:});

% final cleanup: you said you want to remove NaNs
% Here, since we already trimmed to keep_run_mask, dropping NaNs means:
Tlong = Tlong(isfinite(Tlong.x) & isfinite(Tlong.y), :);

end

% ---------------- helpers ----------------
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
    % nothing survives
    return;
end

% label runs (optional)
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