function anchor = estimate_final_position_xy(x, y, binSize, bandwidth, do_plot)
% estimate_final_position_kde
% Estimate the modal 2D location from x/y samples using KDE.
%
% INPUT
%   x, y       : vectors of coordinates
%   binSize    : grid spacing in pixels, e.g. 5
%   bandwidth  : KDE bandwidth in pixels, e.g. [8 8] or []
%   do_plot    : true/false
%
% OUTPUT
%   anchor     : struct with fields
%       .x
%       .y
%       .fmax
%       .xgrid
%       .ygrid
%       .F

    if nargin < 3 || isempty(binSize)
        binSize = 5;
    end
    if nargin < 4
        bandwidth = [];
    end
    if nargin < 5 || isempty(do_plot)
        do_plot = false;
    end

    x = x(:);
    y = y(:);

    keep = ~(isnan(x) | isnan(y) | isinf(x) | isinf(y));
    x = x(keep);
    y = y(keep);

    if isempty(x)
        error('estimate_final_position_kde:NoValidData', ...
            'No valid x/y samples were provided.');
    end

    xmin = min(x);
    xmax = max(x);
    ymin = min(y);
    ymax = max(y);

    xgrid = xmin:binSize:xmax;
    ygrid = ymin:binSize:ymax;

    if numel(xgrid) < 2
        xgrid = [xmin xmax];
    end
    if numel(ygrid) < 2
        ygrid = [ymin ymax];
    end

    [Xgrid, Ygrid] = meshgrid(xgrid, ygrid);

    pts = [x y];
    query = [Xgrid(:) Ygrid(:)];

    if isempty(bandwidth)
        F = ksdensity(pts, query);
    else
        F = ksdensity(pts, query, 'Bandwidth', bandwidth);
    end

    F = reshape(F, size(Xgrid));

    [fmax, idx] = max(F(:));
    x_peak = Xgrid(idx);
    y_peak = Ygrid(idx);

    anchor = struct();
    anchor.x = x_peak;
    anchor.y = y_peak;
    anchor.fmax = fmax;
    anchor.xgrid = xgrid;
    anchor.ygrid = ygrid;
    anchor.F = F;

    if do_plot
        figure;
        imagesc(xgrid, ygrid, F);
        axis xy;
        axis equal tight;
        set(gca, 'ydir', 'reverse')
        hold on;

        % plot 10% random subset of points
        n = numel(x);
        n_show = max(1, round(0.10 * n));
        idx_show = randperm(n, n_show);

        scatter(x(idx_show), y(idx_show), 8, 'c', 'filled');

        % mark peak clearly
        plot(x_peak, y_peak, 'rp', 'MarkerSize', 18, ...
            'MarkerFaceColor', 'r', 'LineWidth', 1.5);

        xline(x_peak, 'r--', 'LineWidth', 1);
        yline(y_peak, 'r--', 'LineWidth', 1);

        xlabel('x');
        ylabel('y');
        title(sprintf('KDE peak at (%.1f, %.1f)', x_peak, y_peak));
        colorbar;
    end
end