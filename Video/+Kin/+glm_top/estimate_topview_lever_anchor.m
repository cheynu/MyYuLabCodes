function anchor = estimate_topview_lever_anchor(T, varargin)
% Estimate lever location in top view from late toLever head positions,
% while plotting the full toLever occupancy for visual continuity.
%
% anchor = estimate_topview_lever_anchor(T)
%
% Required columns in T:
%   head_x, head_y, lever_phase, kept_mask, trial
%
% Optional:
%   keep_run_mask
%
% Output:
%   anchor.x_px
%   anchor.y_px
%   anchor.method
%   anchor.n_used

    p = inputParser;
    addParameter(p, 'UseKeepRunMask', true, @islogical);
    addParameter(p, 'BinSizePx', 5, @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'SmoothSigmaBins', 2, @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'TailFramesPerTrial', 20, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    addParameter(p, 'DoPlot', true, @islogical);
    parse(p, varargin{:});
    ops = p.Results;

    phase = string(T.lever_phase);
    good = phase == "toLever" & T.kept_mask == 1 & isfinite(T.head_x) & isfinite(T.head_y);

    if ops.UseKeepRunMask && ismember('keep_run_mask', T.Properties.VariableNames)
        good = good & T.keep_run_mask == 1;
    end

    Tfull = T(good, :);
    Tgood = Tfull;

    if ismember('trial', Tgood.Properties.VariableNames)
        Tgood.trial = string(Tgood.trial);
        trials = unique(Tgood.trial, 'stable');
        keep_tail = false(height(Tgood), 1);
        for i = 1:numel(trials)
            idx = find(Tgood.trial == trials(i));
            idx_tail = idx(max(1, numel(idx)-ops.TailFramesPerTrial+1):end);
            keep_tail(idx_tail) = true;
        end
        Tgood = Tgood(keep_tail, :);
    end

    x = Tgood.head_x;
    y = Tgood.head_y;

    if numel(x) < 20
        error('Not enough valid top-view samples to estimate lever anchor.');
    end

    % 2D histogram using late toLever samples for the actual anchor estimate
    bin = ops.BinSizePx;
    x_edges = floor(min(x))-bin : bin : ceil(max(x))+bin;
    y_edges = floor(min(y))-bin : bin : ceil(max(y))+bin;

    N = histcounts2(y, x, y_edges, x_edges);  % rows=y, cols=x

    % smooth
    sz = max(3, ceil(ops.SmoothSigmaBins * 6));
    if mod(sz,2)==0
        sz = sz + 1;
    end
    G = fspecial('gaussian', [sz sz], ops.SmoothSigmaBins);
    Ns = imfilter(N, G, 'replicate');

    % peak bin
    [~, idx] = max(Ns(:));
    [iy, ix] = ind2sub(size(Ns), idx);

    x_center = (x_edges(ix) + x_edges(ix+1)) / 2;
    y_center = (y_edges(iy) + y_edges(iy+1)) / 2;

    % Also compute the old "full toLever occupancy" anchor for reference only.
    x_full = Tfull.head_x;
    y_full = Tfull.head_y;
    x_edges_full = floor(min(x_full))-bin : bin : ceil(max(x_full))+bin;
    y_edges_full = floor(min(y_full))-bin : bin : ceil(max(y_full))+bin;
    N_full = histcounts2(y_full, x_full, y_edges_full, x_edges_full);
    Ns_full = imfilter(N_full, G, 'replicate');
    [~, idx_full] = max(Ns_full(:));
    [iy_full, ix_full] = ind2sub(size(Ns_full), idx_full);
    x_center_full = (x_edges_full(ix_full) + x_edges_full(ix_full+1)) / 2;
    y_center_full = (y_edges_full(iy_full) + y_edges_full(iy_full+1)) / 2;

    anchor = struct();
    anchor.x_px = x_center;
    anchor.y_px = y_center;
    anchor.method = '2D histogram mode of late toLever head position';
    anchor.n_used = numel(x);
    anchor.tail_frames_per_trial = ops.TailFramesPerTrial;
    if ops.DoPlot
        hf = figure('Color', 'w', 'Name', 'Top-view lever anchor');
        tiledlayout(1,2, 'Padding', 'compact', 'TileSpacing', 'compact');

        nexttile;
        scatter(x_full, y_full, 6, '.', 'MarkerEdgeAlpha', 0.10);
        hold on;
        scatter(x, y, 10, '.', 'MarkerEdgeAlpha', 0.20);
        plot(x_center_full, y_center_full, 'bp', 'MarkerSize', 14, 'LineWidth', 1.5);
        plot(anchor.x_px, anchor.y_px, 'rp', 'MarkerSize', 16, 'LineWidth', 2);
        axis equal;
        set(gca, 'YDir', 'reverse');
        xlabel('head_x (px)');
        ylabel('head_y (px)');
        title(sprintf('Full toLever shown; late samples used (n = %d)', anchor.n_used));
        legend({'full toLever','late toLever tail','full-phase peak','used anchor'}, 'Location', 'best');
        box off;

        nexttile;
        imagesc(x_edges_full, y_edges_full, padarray(Ns_full, [1 1], NaN, 'post'));
        hold on;
        plot(x_center_full, y_center_full, 'bp', 'MarkerSize', 14, 'LineWidth', 1.5);
        plot(anchor.x_px, anchor.y_px, 'rp', 'MarkerSize', 16, 'LineWidth', 2);
        set(gca, 'YDir', 'reverse');
        axis image;
        xlabel('x (px)');
        ylabel('y (px)');
        title('Smoothed occupancy of full toLever');
        box off;
    end
end
