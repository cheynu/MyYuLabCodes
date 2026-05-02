function [h, k1] = plotRasterFast(ax, ap_mat, t, k0, hold_dur, fp_dur, fp_color, tick_color)
% plotSpikeRaster  Fast raster plot with optional per-trial event line + optional FP shading,
%                  with a starting row offset k0 so you can stack multiple rasters in one axes.
%
%   [h, k1] = plotRasterFast(ax, ap_mat, t, k0)
%   [h, k1] = plotRasterFast(ax, ap_mat, t, k0, hold_dur)
%   [h, k1] = plotRasterFast(ax, ap_mat, t, k0, hold_dur, fp_dur, fp_color)
%
% Inputs
%   ax      : axes handle
%   ap_mat  : [nTime x nTrial], 1 = spike, any NaN in a trial => skip plotting for that trial
%   t       : [nTime x 1] time vector
%   k0      : starting row index (like your k before entering the i-loop)
%   hold_dur: (optional) [nTrial x 1] event time per trial (can be negative)
%   fp_dur  : (optional) scalar foreperiod duration, shade [0 fp_dur] per trial row
%   fp_color: (optional) 1x3 RGB color for shading
%
% Outputs
%   h struct with handles: h.fpPatch, h.spikeLines, h.eventLines
%   k1 = k0 + nTrial   (matches your original k increment behavior)

if nargin < 4 || isempty(k0), k0 = 0; end
if nargin < 5 || isempty(hold_dur), hold_dur = []; end
if nargin < 6, fp_dur = []; end
if nargin < 7 || isempty(fp_color), fp_color = [0.8 0.8 0.8]; end
if nargin < 8, tick_color = [0 0 0]; end

t = t(:);
[nTime, nTrial] = size(ap_mat);

hold(ax, 'on');

if size(hold_dur, 1)>1
    hold_dur = hold_dur';
end

% y mapping that matches yy=[0 1]-k, with k starting at k0
% trial i (1-based) uses k = k0 + (i-1)
kVec = k0 + (0:nTrial-1);
yTop    = -kVec;        % equals 0-k, -1-k, ...
yBottom = 1 - kVec;     % equals 1-k

% Return next starting k (match your loop: k increments every trial)
k1 = k0 + nTrial;

% Identify bad trials (skip plotting content)
badTrial  = any(isnan(ap_mat), 1);
goodTrial = ~badTrial;

h = struct('fpPatch', gobjects(1), 'spikeLines', gobjects(1), 'eventLines', gobjects(1));

%% Optional FP shading (only for good trials)
if false
    if ~isempty(fp_dur) && isfinite(fp_dur)
        idx = find(goodTrial);
        if ~isempty(idx)
            x0 = 0; x1 = fp_dur;

            N = numel(idx);
            X = repmat([x0; x1; x1; x0], 1, N);
            Y = [yTop(idx);
                yTop(idx);
                yBottom(idx);
                yBottom(idx)];

            h.fpPatch = patch(ax, X, Y, fp_color, 'EdgeColor','none', 'FaceAlpha',0.5);
        end
    end
end

if ~isempty(fp_dur) && all(isfinite(fp_dur))
    idx = find(goodTrial);
    if ~isempty(idx)
        % fp duration for selected trials
        if numel(fp_dur) == 1
            fp_i = repmat(fp_dur, 1, length(idx));
        else
            fp_i = fp_dur(idx);          % N x 1
        end

        N    = numel(idx);

        % X coordinates: [0, fp, fp, 0] for each trial
        X = [zeros(1,N); ...
             fp_i(:).'; ...
             fp_i(:).'; ...
             zeros(1,N)];

        % Y coordinates (same logic as before)
        Y = [yTop(idx);
             yTop(idx);
             yBottom(idx);
             yBottom(idx)];

        h.fpPatch = patch(ax, X, Y, fp_color, ...
            'EdgeColor','none', ...
            'FaceAlpha',0.5);
    end
end

%% Spikes: one line object
spikeLogical = (ap_mat == 1);
spikeLogical(:, badTrial) = false;

[rr, cc] = find(spikeLogical);
if ~isempty(rr)
    x = t(rr);
    y1 = yTop(cc);
    y2 = yBottom(cc);
    X = [x.'; x.'; nan(1,numel(x))];
    if size(y1, 1)~= 1
        y1 = y1';
    end
    if size(y2, 1)~= 1
        y2 = y2';
    end
    Y = [y1; y2;  nan(1,numel(x))]; % y1, y2 should be n x 1 vector
    h.spikeLines = line(ax, X(:), Y(:), 'Color', tick_color, 'LineWidth',1.5);
end

%% Optional event lines (one line object)

% Make sure these vectors are of size n x 1 
if size(goodTrial, 1) == 1
    goodTrial = goodTrial';
end
hold_dur = hold_dur(:);

if ~isempty(hold_dur)
    if numel(hold_dur) ~= nTrial
        error('hold_dur must have length nTrial (%d).', nTrial);
    end

    idx = find(goodTrial & ~isnan(hold_dur) & isfinite(hold_dur));
    if ~isempty(idx)
        x = hold_dur(idx);
        y1 = yTop(idx)+0.2;
        y2 = yBottom(idx)-0.2;

        X = [x.'; x.'; nan(1,numel(x))];
        Y = [y1; y2; nan(1,numel(x))];
        h.eventLines = line(ax, X(:), Y(:), 'Color','r', 'LineWidth',2);  
    end
end

end
