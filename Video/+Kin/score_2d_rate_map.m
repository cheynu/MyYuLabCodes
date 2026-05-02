function S = score_2d_rate_map(M, M0)
% score_2d_rate_map
% Score a 2D smoothed rate map and optionally compare it with a zero-lag map.
%
% INPUT
%   M   : struct from compute_2d_rate_map
%   M0  : zero-lag map struct from compute_2d_rate_map
%         if empty, corr_with_zero is NaN
%
% OUTPUT
%   S   : struct with fields
%       .peak_rate_hz
%       .map_var_hz2
%       .contrast_hz
%       .corr_with_zero
%       .spread_cm
%       .compactness_inv_cm
%       .n_valid_bins

    if nargin < 2
        M0 = [];
    end

    R = M.rate_smooth_hz;

    if isfield(M, 'valid_mask_smooth')
        mask = M.valid_mask_smooth;
    elseif isfield(M, 'valid_mask')
        mask = M.valid_mask;
    else
        mask = ~isnan(R);
    end

    rv = R(mask);
    rv = rv(~isnan(rv));

    S = struct();
    S.peak_rate_hz = NaN;
    S.map_var_hz2 = NaN;
    S.contrast_hz = NaN;
    S.corr_with_zero = NaN;
    S.spread_cm = NaN;
    S.compactness_inv_cm = NaN;
    S.n_valid_bins = numel(rv);

    if isempty(rv)
        return
    end

    %-----------------------------
    % basic map scores
    %-----------------------------
    S.peak_rate_hz = max(rv);
    rv_sort = sort(rv, 'descend');
    S.top_mean_rate_hz = mean(rv_sort(1:10));
    S.map_var_hz2 = var(rv, 'omitnan');
    S.contrast_hz = prctile(rv, 95) - prctile(rv, 5);


    %
    % compute average rate around the peak pixel
    %

    R = M.rate_smooth_hz;
    if isfield(M, 'valid_mask_smooth')
        mask = M.valid_mask_smooth;
    elseif isfield(M, 'valid_mask')
        mask = M.valid_mask;
    else
        mask = ~isnan(R);
    end

    Rvalid = R;
    Rvalid(~mask) = NaN;

    % peak pixel
    [~, idx_peak] = max(Rvalid(:));
    [row_peak, col_peak] = ind2sub(size(Rvalid), idx_peak);

    % coordinates of all pixels
    [Xc, Yc] = meshgrid(M.x_centers, M.y_centers);

    x0 = Xc(row_peak, col_peak);
    y0 = Yc(row_peak, col_peak);

    % valid pixels only
    good = mask & ~isnan(Rvalid);

    xg = Xc(good);
    yg = Yc(good);
    rg = Rvalid(good);

    % distance to peak pixel
    d = hypot(xg - x0, yg - y0);

    % nearest 10 valid pixels
    [~, ord] = sort(d, 'ascend');
    n_take = min(10, numel(ord));

    S.peak_local10_mean_hz = mean(rg(ord(1:n_take)), 'omitnan');

    %-----------------------------
    % correlation with zero-lag map
    %-----------------------------
    if ~isempty(M0)
        R0 = M0.rate_smooth_hz;

        if isfield(M0, 'valid_mask_smooth')
            mask0 = M0.valid_mask_smooth;
        elseif isfield(M0, 'valid_mask')
            mask0 = M0.valid_mask;
        else
            mask0 = ~isnan(R0);
        end

        m = mask & mask0 & ~isnan(R) & ~isnan(R0);

        if nnz(m) >= 3
            c = corr(R(m), R0(m), 'rows', 'complete');
            S.corr_with_zero = c;
        end
    end

    %-----------------------------
    % center-of-mass compactness
    % spread_cm = weighted RMS distance to COM
    % compactness_inv_cm = 1 / spread_cm
    %-----------------------------
    [Xc, Yc] = meshgrid(M.x_centers, M.y_centers);

    W = R;
    W(~mask) = NaN;
    W(W < 0) = 0;  % be safe if smoothing ever produces tiny negatives

    good = ~isnan(W) & (W > 0);

    if nnz(good) >= 3
        w = W(good);
        x = Xc(good);
        y = Yc(good);

        wsum = sum(w);
        xc = sum(w .* x) / wsum;
        yc = sum(w .* y) / wsum;

        d2 = (x - xc).^2 + (y - yc).^2;
        spread_cm = sqrt(sum(w .* d2) / wsum);

        S.spread_cm = spread_cm;
        S.compactness_inv_cm = 1 / max(spread_cm, eps);
    end
end