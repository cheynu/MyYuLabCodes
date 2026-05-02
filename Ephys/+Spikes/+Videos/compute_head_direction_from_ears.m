function [head_direction, x_midpoints, y_midpoints, d_perp_x, d_perp_y] = ...
    compute_head_direction_from_ears(x, y, tracking_lh, varargin)
%COMPUTE_HEAD_DIRECTION_FROM_EARS Head direction from ear line (no tail needed).
%
% Head direction is defined as the vector obtained by rotating the
% left->right ear vector clockwise by 90 degrees.
%
% Inputs
%   x, y          : structs with fields EarLTop, EarRTop (1xN or Nx1)
%   tracking_lh   : 1xN (or Nx1) likelihood/confidence for tracking quality
%
% Name-value pairs (optional)
%   'Thresh'      : tracking threshold (default 0.9)
%   'DoPlot'      : true/false, plot random samples (default false)
%   'PlotProb'    : probability to plot a valid frame (default 0.01)
%
% Outputs
%   head_direction: 1xN angles (radians), NaN where invalid
%   x_midpoints   : 1xN midpoint x
%   y_midpoints   : 1xN midpoint y
%   d_perp_x/y    : 1xN clockwise-perp vector components (unscaled)

% ---- parse inputs ----
p = inputParser;
p.addParameter('Thresh', 0.9, @(v) isnumeric(v) && isscalar(v));
p.addParameter('DoPlot', false, @(v) islogical(v) && isscalar(v));
p.addParameter('PlotProb', 0.01, @(v) isnumeric(v) && isscalar(v) && v>=0 && v<=1);
p.parse(varargin{:});

thr      = p.Results.Thresh;
doPlot   = p.Results.DoPlot;
plotProb = p.Results.PlotProb;

% ---- pull vectors and force row shape ----
xL = x.EarLTop(:)';  yL = y.EarLTop(:)';
xR = x.EarRTop(:)';  yR = y.EarRTop(:)';
q  = tracking_lh(:)';

n = numel(xL);
assert(numel(xR)==n && numel(yL)==n && numel(yR)==n && numel(q)==n, ...
    'EarLTop/EarRTop and tracking_lh must have the same length.');

% ---- initialize outputs ----
head_direction = nan(1, n);
x_midpoints    = nan(1, n);
y_midpoints    = nan(1, n);
d_perp_x       = nan(1, n);
d_perp_y       = nan(1, n);

% ---- valid mask ----
valid = (q > thr) & ~isnan(xL) & ~isnan(yL) & ~isnan(xR) & ~isnan(yR);

% ---- midpoints ----
x_midpoints(valid) = (xL(valid) + xR(valid)) / 2;
y_midpoints(valid) = (yL(valid) + yR(valid)) / 2;

% ---- left->right vector ----
dx = xR - xL;
dy = yR - yL;

% ---- clockwise 90° rotation: [dx,dy] -> [dy,-dx] ----
dpx = dy;
dpy = -dx;

d_perp_x(valid) = dpx(valid);
d_perp_y(valid) = dpy(valid);

% ---- angle (keep your convention: negate atan2 because image y is flipped) ----
head_direction(valid) = -atan2(dpy(valid), dpx(valid));

% ---- optional quick visualization ----
if doPlot
    idx = find(valid);
    if ~isempty(idx)
        figure(22); clf(22)
        scatter(xL, yL, 30, q, 'o', 'filled')
        hold on;
        axis equal; 
        set(gca,'YDir','reverse', 'NextPlot', 'add'); % common for image coords; remove if not desired
        for k = 1:numel(idx)
            ii = idx(k);
            if rand > (1 - plotProb)
                line([xL(ii) xR(ii)], [yL(ii) yR(ii)], 'Color', 'r', 'LineWidth', 1);
                scatter(x_midpoints(ii), y_midpoints(ii), 25, 'b', 'filled');
                quiver(x_midpoints(ii), y_midpoints(ii), d_perp_x(ii), d_perp_y(ii), ...
                       0, 'r', 'LineWidth', 0.8, 'MaxHeadSize', 2);
                title(sprintf('Frame %d, theta=%.2f rad', ii, head_direction(ii)));
                drawnow;
            end
        end
        hold off;
    end
end
end
