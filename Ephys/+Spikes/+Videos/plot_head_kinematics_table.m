function plot_head_kinematics_table(T, figH)
%PLOT_HEAD_KINEMATICS_TABLE Plot kinematics summary from head kinematics table.
%
% Jianing Yu (JY) | Updated: 2026-03-04
%
% This version assumes the UPDATED T returned by head_pose_table_from_ears(),
% i.e. T has already been restricted to the longest contiguous segment.
%
% What it plots (6 panels):
%   1) head_x
%   2) head_y
%   3) head_theta (unwrapped for visualization)
%   4) speed
%   5) forward_speed
%   6) lateral_speed
%
% Notes
% - In your pipeline, T should already contain only the longest segment, so we
%   don't need kept_mask to segment further. We still unwrap within finite runs.
% - time is assumed to be ms unless Source encodes a t0 suffix.

if nargin < 2 || isempty(figH) || ~ishandle(figH)
    figH = figure;
else
    figure(figH);
end
clf(figH);

% ---- trial string / t0 ----
trialStr = "";
if any(strcmp(T.Properties.VariableNames, 'Source'))
    s = T.Source(1);
    if iscell(s); s = s{1}; end
    trialStr = string(s);
end
if strlength(trialStr)==0
    trialStr = "trial";
end

tok = regexp(trialStr, '\d+$', 'match', 'once');
if isempty(tok)
    t0_ms = T.time(1);
else
    t0_ms = str2double(tok);
end

% ---- time relative (sec) ----
t_ms  = T.time;
t_rel = (t_ms - t0_ms) / 1000;

% ---- fetch columns (updated names) ----
hx = T.head_x;
hy = T.head_y;

% head angle (rad)
if any(strcmp(T.Properties.VariableNames, 'head_theta'))
    head_ang = T.head_theta;
else
    % fallback from vector if user trimmed angle column
    if all(ismember({'head_theta_x','head_theta_y'}, T.Properties.VariableNames))
        head_ang = atan2(T.head_theta_y, T.head_theta_x);
    else
        head_ang = nan(height(T),1);
    end
end

% speed / forward / lateral
if any(strcmp(T.Properties.VariableNames, 'speed'))
    spd = T.speed;
else
    spd = nan(height(T),1);
end

if any(strcmp(T.Properties.VariableNames, 'forward_speed'))
    fwd = T.forward_speed;
else
    fwd = nan(height(T),1);
end

if any(strcmp(T.Properties.VariableNames, 'lateral_speed'))
    lat = T.lateral_speed;
else
    lat = nan(height(T),1);
end

% ---- unwrap head angle within contiguous finite runs ----
mAng = isfinite(head_ang) & isfinite(t_rel);
head_ang_u = head_ang;

% toolbox-free contiguous runs
d = diff([false; mAng; false]);
starts = find(d==1);
ends   = find(d==-1) - 1;

for s = 1:numel(starts)
    idx = starts(s):ends(s);
    head_ang_u(idx) = unwrap(head_ang_u(idx));
end

% ---- helpers ----
isOk = @(v) isfinite(t_rel) & isfinite(v);

% smooth within contiguous valid runs (prevents connecting across gaps)
smooth_in_runs = @(t, v, m, win) local_smooth_in_segments(t, v, m, win);

% window length in samples (odd)
win = 11;

% ---- plotting ----
tl = tiledlayout(figH, 6, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, sprintf('%s | t0(ms)=%g', trialStr, t0_ms), 'Interpreter','none');

nexttile;
m = isOk(hx);
plot(t_rel(m), hx(m), '-o', 'markersize', 4, 'MarkerFaceColor','b'); hold on;
[ts, ys] = smooth_in_runs(t_rel, hx, m, win);
plot(ts, ys, '-', 'Color', 'r', 'LineWidth', 2);
ylabel('head\_x (px)'); grid on;

nexttile;
m = isOk(hy);
plot(t_rel(m), hy(m), '-o', 'markersize', 4, 'MarkerFaceColor','b'); hold on;
[ts, ys] = smooth_in_runs(t_rel, hy, m, win);
plot(ts, ys, '-', 'Color', 'r', 'LineWidth', 2);
ylabel('head\_y (px)'); grid on;

nexttile;
m = isOk(head_ang_u);
plot(t_rel(m), head_ang_u(m), '-o', 'markersize', 4, 'MarkerFaceColor','b'); hold on;
[ts, ys] = smooth_in_runs(t_rel, head_ang_u, m, win);
plot(ts, ys, '-', 'Color', 'r', 'LineWidth', 2);
ylabel('head \theta (rad, unwrapped)'); grid on;

nexttile;
m = isOk(spd);
plot(t_rel(m), spd(m), '-o', 'markersize', 4, 'MarkerFaceColor','b'); hold on;
[ts, ys] = smooth_in_runs(t_rel, spd, m, win);
plot(ts, ys, '-', 'Color', 'r', 'LineWidth', 2);
ylabel('speed (px/s)'); grid on;

nexttile;
m = isOk(fwd);
plot(t_rel(m), fwd(m), '-o', 'markersize', 4, 'MarkerFaceColor','b'); hold on;
[ts, ys] = smooth_in_runs(t_rel, fwd, m, win);
plot(ts, ys, '-', 'Color', 'r', 'LineWidth', 2);
ylabel('forward (px/s)'); grid on;

nexttile;
m = isOk(lat);
plot(t_rel(m), lat(m), '-o', 'markersize', 4, 'MarkerFaceColor','b'); hold on;
[ts, ys] = smooth_in_runs(t_rel, lat, m, win);
plot(ts, ys, '-', 'Color', 'r', 'LineWidth', 2);
ylabel('lateral (px/s)'); xlabel('t - trial# (s)'); grid on;

end

% =================== local helper ===================
function [t_out, v_out] = local_smooth_in_segments(t_all, v_all, mask, win)
% Smooth v within contiguous true segments of mask, return concatenated (t,v)
% with NaN breaks between segments so the red line doesn't connect across gaps.

t_out = [];
v_out = [];

if nargin < 4 || isempty(win) || ~isscalar(win) || win < 3
    win = 11;
end
win = round(win);
if mod(win,2)==0
    win = win + 1;
end

idxAll = find(mask);
if isempty(idxAll)
    return
end

d = diff(idxAll);
breaks = find(d > 1);

runStarts = [1; breaks+1];
runEnds   = [breaks; numel(idxAll)];

for r = 1:numel(runStarts)
    idx = idxAll(runStarts(r):runEnds(r));
    tt = t_all(idx);
    vv = v_all(idx);

    if numel(vv) < 3
        t_out = [t_out; tt; NaN];
        v_out = [v_out; vv; NaN];
        continue
    end

    w = min(win, numel(vv));
    if mod(w,2)==0, w = w-1; end
    if w < 3, w = 3; end

    vs = movmean(vv, w, 'omitnan');

    t_out = [t_out; tt; NaN];
    v_out = [v_out; vs; NaN];
end
end