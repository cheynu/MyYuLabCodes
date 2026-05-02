function h = plot_xy_bin_grid(ax, bins, varargin)
%PLOT_XY_BIN_GRID Plot a 2D spatial bin grid from design_shared_xy_bin_set.
%
% Usage:
%   h = plot_xy_bin_grid(ax, bins)
%   h = plot_xy_bin_grid(ax, bins, 'ShowCenters', true)
%
% Inputs
%   ax    axis handle
%   bins  struct with fields:
%         .x_edges, .y_edges, .centers, .x_range, .y_range
%
% Name-value options
%   'ShowCenters'      logical, default false
%   'GridColor'        1x3 RGB, default [0.5 0.5 0.5]
%   'LineWidth'        scalar, default 0.75
%   'LineStyle'        char/string, default '-'
%   'CenterColor'      1x3 RGB, default [0.2 0.2 0.2]
%   'CenterSize'       scalar, default 12
%   'SetLimits'        logical, default true
%   'MakeEqual'        logical, default true
%
% Output
%   h    struct of graphics handles

p = inputParser;
p.addRequired('ax', @(x) isempty(x) || isgraphics(x, 'axes'));
p.addRequired('bins', @(x) isstruct(x) && isfield(x, 'x_edges') && isfield(x, 'y_edges'));

p.addParameter('ShowCenters', false, @(x) islogical(x) && isscalar(x));
p.addParameter('GridColor', [0.5 0.5 0.5], @(x) isnumeric(x) && numel(x) == 3);
p.addParameter('LineWidth', 0.75, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('LineStyle', '-', @(x) ischar(x) || isstring(x));
p.addParameter('CenterColor', [0.2 0.2 0.2], @(x) isnumeric(x) && numel(x) == 3);
p.addParameter('CenterSize', 12, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('SetLimits', true, @(x) islogical(x) && isscalar(x));
p.addParameter('MakeEqual', true, @(x) islogical(x) && isscalar(x));
p.addParameter('BinPlot', [], @(x) isnumeric(x));

p.parse(ax, bins, varargin{:});

if isempty(ax)
    ax = gca;
end

x_edges = bins.x_edges(:)';
y_edges = bins.y_edges(:)';

x0 = x_edges(1);
x1 = x_edges(end);
y0 = y_edges(1);
y1 = y_edges(end);

hold_state = ishold(ax);
hold(ax, 'on');

% vertical grid lines
h.v = gobjects(numel(x_edges), 1);
for i = 1:numel(x_edges)
    h.v(i) = line(ax, [x_edges(i) x_edges(i)], [y0 y1], ...
        'Color', p.Results.GridColor, ...
        'LineWidth', p.Results.LineWidth, ...
        'LineStyle', p.Results.LineStyle);
end

% horizontal grid lines
h.h = gobjects(numel(y_edges), 1);
for i = 1:numel(y_edges)
    h.h(i) = line(ax, [x0 x1], [y_edges(i) y_edges(i)], ...
        'Color', p.Results.GridColor, ...
        'LineWidth', p.Results.LineWidth, ...
        'LineStyle', p.Results.LineStyle);
end

% optional centers
h.centers = gobjects(0);
if p.Results.ShowCenters && isfield(bins, 'centers') && ~isempty(bins.centers)
    h.centers = scatter(ax, bins.centers(:,1), bins.centers(:,2), ...
        p.Results.CenterSize, ...
        'Marker', '.', ...
        'MarkerEdgeColor', p.Results.CenterColor);
end

% optional bin highlight
h.binplot = gobjects(0);

if ~isempty(p.Results.BinPlot)

    idx = p.Results.BinPlot(:);
    idx = idx(~isnan(idx));
    idx = idx(idx >= 1 & idx <= numel(bins.centers(:,1)));

    if ~isempty(idx)

        nx = numel(x_edges) - 1;
        ny = numel(y_edges) - 1;

        % convert linear index → (ix, iy)
        [ix, iy] = ind2sub([nx, ny], idx);

        h.binplot = gobjects(numel(idx),1);

        for k = 1:numel(idx)
            xe = [x_edges(ix(k)), x_edges(ix(k)+1)];
            ye = [y_edges(iy(k)), y_edges(iy(k)+1)];

            h.binplot(k) = patch(ax, ...
                [xe(1) xe(2) xe(2) xe(1)], ...
                [ye(1) ye(1) ye(2) ye(2)], ...
                'k', ...
                'EdgeColor', 'none');
        end
    end
end

if p.Results.SetLimits
    xlim(ax, [x0 x1]);
    ylim(ax, [y0 y1]);
end

if p.Results.MakeEqual
    axis(ax, 'equal');
end

if ~hold_state
    hold(ax, 'off');
end
end