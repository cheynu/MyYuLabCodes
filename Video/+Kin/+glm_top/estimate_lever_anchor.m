function anchor = estimate_lever_anchor(T, varargin)
%ESTIMATE_TOPVIEW_LEVER_ANCHOR Estimate lever anchor from top-view tracking.
%
% anchor = estimate_topview_lever_anchor(T)
%
% Uses dense head positions during the toLever phase to estimate the lever
% location in top view as the mode of a smoothed 2D occupancy map.
%
% Required columns in T:
%   head_x, head_y, lever_phase, kept_mask
%
% Optional columns:
%   keep_run_mask
%
% Name-value pairs:
%   'UseKeepRunMask'   : true/false, default true
%   'BinSizePx'        : histogram bin size in pixels, default 5
%   'SmoothSigmaBins'  : Gaussian smoothing sigma in bins, default 2
%   'DoPlot'           : true/false, default false
%
% Output:
%   anchor.x_px
%   anchor.y_px
%   anchor.method
%   anchor.n_used
%   anchor.bin_size_px
%   anchor.sigma_bins

    p = inputParser;
    addParameter(p, 'UseKeepRunMask', true, @(x)islogical(x) && isscalar(x));
    addParameter(p, 'BinSizePx', 5, @(x)isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'SmoothSigmaBins', 2, @(x)isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'DoPlot', false, @(x)islogical(x) && isscalar(x));
    parse(p, varargin{:});
    ops = p.Results;

    required_vars = {'head_x', 'head_y', 'lever_phase', 'kept_mask'};
    missing_vars = required_vars(~ismember(required_vars, T.Properties.VariableNames));
    if ~isempty(missing_vars)
        error('estimate_topview_lever_anchor:MissingVariable', ...
            'Missing required variable(s): %s', strjoin(missing_vars, ', '));
    end

    phase = string(T.lever_phase);

    good = phase == "toLever" & ...
           T.kept_mask == 1 & ...
           isfinite(T.head_x) & ...
           isfinite(T.head_y);

    if ops.UseKeepRunMask && ismember('keep_run_mask', T.Properties.VariableNames)
        good = good & T.keep_run_mask == 1;
    end

    x = T.head_x(good);
    y = T.head_y(good);

    if numel(x) < 20
        error('estimate_topview_lever_anchor:TooFewPoints', ...
            'Too few valid points (%d) to estimate top-view lever anchor.', numel(x));
    end

    bin_size = ops.BinSizePx;

    x_edges = (floor(min(x) / bin_size) * bin_size - bin_size) : ...
              bin_size : ...
              (ceil(max(x) / bin_size) * bin_size + bin_size);

    y_edges = (floor(min(y) / bin_size) * bin_size - bin_size) : ...
              bin_size : ...
              (ceil(max(y) / bin_size) * bin_size + bin_size);

    N = histcounts2(y, x, y_edges, x_edges);   % rows=y, cols=x

    sigma_bins = ops.SmoothSigmaBins;
    kernel_size = max(3, ceil(sigma_bins * 6));
    if mod(kernel_size, 2) == 0
        kernel_size = kernel_size + 1;
    end

    G = fspecial('gaussian', [kernel_size, kernel_size], sigma_bins);
    N_smooth = imfilter(N, G, 'replicate');

    [~, idx] = max(N_smooth(:));
    [iy, ix] = ind2sub(size(N_smooth), idx);

    x_center = (x_edges(ix) + x_edges(ix + 1)) / 2;
    y_center = (y_edges(iy) + y_edges(iy + 1)) / 2;

    anchor = struct();
    anchor.x_px = x_center;
    anchor.y_px = y_center;
    anchor.method = 'mode of smoothed 2D occupancy during toLever';
    anchor.n_used = numel(x);
    anchor.bin_size_px = bin_size;
    anchor.sigma_bins = sigma_bins;

    if ops.DoPlot
        hf = figure('Color', 'w', 'Name', 'Top-view lever anchor');
        tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

        nexttile;
        scatter(x, y, 6, '.', 'MarkerEdgeAlpha', 0.12);
        hold on;
        plot(anchor.x_px, anchor.y_px, 'rp', 'MarkerSize', 16, 'LineWidth', 2);
        set(gca, 'YDir', 'reverse');
        axis equal;
        xlabel('head x (px)');
        ylabel('head y (px)');
        title(sprintf('Points used (n = %d)', anchor.n_used));
        box off;

        nexttile;
        imagesc(x_edges, y_edges, padarray(N_smooth, [1 1], NaN, 'post'));
        hold on;
        plot(anchor.x_px, anchor.y_px, 'rp', 'MarkerSize', 16, 'LineWidth', 2);
        set(gca, 'YDir', 'reverse');
        axis image;
        xlabel('x (px)');
        ylabel('y (px)');
        title('Smoothed occupancy');
        box off;
    end
end