function [Xbin, bin_names] = eval_xy_bins(T, x_col, y_col, valid_col, bins, prefix)
%EVAL_XY_BINS
% Convert x-y coordinates into one-hot 2D bin features.
%
% Uses bins.ix / bins.iy / bins.labels for consistent indexing.

x = T.(x_col);
y = T.(y_col);
N = height(T);

if ~isempty(valid_col)
    v = logical(T.(valid_col));
else
    v = true(N,1);
end

good = v & isfinite(x) & isfinite(y);

% initialize
Xbin = nan(N, bins.K);

if any(good)
    xg = x(good);
    yg = y(good);

    % clip to ensure inclusion in bins
    xg = min(max(xg, bins.x_edges(1) + eps), bins.x_edges(end) - eps);
    yg = min(max(yg, bins.y_edges(1) + eps), bins.y_edges(end) - eps);

    % discretize → ix, iy
    ix = discretize(xg, bins.x_edges);
    iy = discretize(yg, bins.y_edges);

    valid_idx = isfinite(ix) & isfinite(iy);
    ix = ix(valid_idx);
    iy = iy(valid_idx);

    % convert to bin index using SAME convention as basis
    % lin_idx = sub2ind([bins.ny, bins.nx], iy, ix);

    lin_idx = (iy - 1) * bins.nx + ix;
    
    % build sparse one-hot
    n_valid = numel(lin_idx);
    Xg = sparse(1:n_valid, lin_idx, 1, n_valid, bins.K);

    % insert back into full matrix
    tmp = nan(sum(good), bins.K);
    tmp(valid_idx, :) = full(Xg);

    Xbin(good, :) = tmp;
end

% ============================================================
% bin names (CONSISTENT WITH BASIS)
% ============================================================
bin_names = prefix + "_bin_" + bins.labels;

end