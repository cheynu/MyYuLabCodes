function occ = compute_pixel_occupancy(tr, basis, bodypart, mode)

bp = tr.(bodypart);

x = bp.x_rel_cm;
y = bp.y_rel_cm;
valid = bp.valid;

% only use valid samples
x = x(valid);
y = y(valid);

% bin indices
ix = discretize(x, basis.x_edges);
iy = discretize(y, basis.y_edges);

% remove NaNs (outside range)
valid_idx = ~isnan(ix) & ~isnan(iy);
ix = ix(valid_idx);
iy = iy(valid_idx);

nx = basis.nx;
ny = basis.ny;
K = basis.K;

% convert (ix, iy) → linear index
lin_idx = sub2ind([nx, ny], ix, iy);

switch mode

    case "trial"
        % -------- trial-level binary occupancy --------
        occ = zeros(K,1);
        occ(unique(lin_idx)) = 1;

    case "time"
        % -------- time-resolved occupancy --------
        T = length(lin_idx);
        occ = zeros(T, K);

        for t = 1:T
            occ(t, lin_idx(t)) = 1;
        end

    otherwise
        error('mode must be "trial" or "time"')

end

end