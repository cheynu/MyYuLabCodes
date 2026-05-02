function S = local_prepare_one_bodypart_binmap( ...
    result, bins, trial_info, body_part, varargin)

p = inputParser;
p.addParameter('UseOccupancyMask', true, @(x) islogical(x) && isscalar(x));
p.addParameter('MaskSmoothSigma', 1, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.addParameter('MaskQuantileNonzero', 0, @(x) isnumeric(x) && isscalar(x) && x >= 0 && x <= 1);
p.addParameter('MaskUseSmoothedOcc', false, @(x) islogical(x) && isscalar(x));
p.addParameter('UseMaskedRegionForCLim', true, @(x) islogical(x) && isscalar(x));
p.parse(varargin{:});

xq = bins.x_centers;
yq = bins.y_centers;

% ------------------------------------------------------------
% 1. Build raw beta map from fitted bin coefficients
% ------------------------------------------------------------
F = nan(bins.ny, bins.nx);

if isfield(result, 'beta_table') && ~isempty(result.beta_table)
    
    Tbeta = result.beta_table;

    is_bp  = string(Tbeta.body_part) == string(body_part);
    is_bin = contains(string(Tbeta.feature_name), "_bin_x");
    Tb = Tbeta(is_bp & is_bin, :);

    for i = 1:height(Tb)
        fname = string(Tb.feature_name(i));
        tok = regexp(fname, '_bin_x(\d+)_y(\d+)$', 'tokens', 'once');
        if isempty(tok)
            continue
        end

        ix = str2double(tok{1});
        iy = str2double(tok{2});

        if isfinite(ix) && isfinite(iy) && ...
                ix >= 1 && ix <= bins.nx && ...
                iy >= 1 && iy <= bins.ny
            F(iy, ix) = Tb.beta(i);
        end
    end
else
    Fstruct = result.field.(body_part);

    if isfield(Fstruct, 'F_mean') && ~isempty(Fstruct.F_mean)
        F = Fstruct.F_mean;
    elseif isfield(Fstruct, 'F') && ~isempty(Fstruct.F)
        F = Fstruct.F;
    else
        error('No F_mean/F found in result.field.%s', body_part);
    end
    if isfield(Fstruct, 'xq') && ~isempty(Fstruct.xq)
        xq = Fstruct.xq;
    end
    if isfield(Fstruct, 'yq') && ~isempty(Fstruct.yq)
        yq = Fstruct.yq;
    end
end

F(isnan(F)) = 0;

% ------------------------------------------------------------
% 2. Occupancy and support mask
% ------------------------------------------------------------
trial_sel = 1:numel(trial_info);
[x, y] = local_extract_bodypart_positions(trial_info, body_part, trial_sel);
n_pos_samples = numel(x);

occ = zeros(bins.ny, bins.nx);

if ~isempty(x)
    x = min(max(x, bins.x_edges(1) + eps), bins.x_edges(end) - eps);
    y = min(max(y, bins.y_edges(1) + eps), bins.y_edges(end) - eps);

    ix = discretize(x, bins.x_edges);
    iy = discretize(y, bins.y_edges);

    keep = ~isnan(ix) & ~isnan(iy);
    if any(keep)
        occ = accumarray([iy(keep), ix(keep)], 1, [bins.ny, bins.nx], @sum, 0);
    end
end

if p.Results.MaskSmoothSigma > 0
    G = local_make_gaussian_kernel(p.Results.MaskSmoothSigma);

    visited = double(occ > 0);
    num = conv2(F .* visited, G, 'same');
    den = conv2(visited, G, 'same');
    F = num ./ max(den, eps);
end

if p.Results.UseOccupancyMask
    if p.Results.MaskUseSmoothedOcc && p.Results.MaskSmoothSigma > 0
        G = local_make_gaussian_kernel(p.Results.MaskSmoothSigma);
        occ_for_mask = conv2(double(occ), G, 'same');
    else
        occ_for_mask = occ;
    end

    if p.Results.MaskQuantileNonzero <= 0
        support_mask = occ > 0;
    else
        occ_nonzero = occ_for_mask(occ_for_mask > 0);
        if isempty(occ_nonzero)
            support_mask = false(size(F));
        else
            thr = quantile(occ_nonzero, p.Results.MaskQuantileNonzero);
            support_mask = occ_for_mask >= thr & occ > 0;
        end
    end
else
    support_mask = true(size(F));
end

% ------------------------------------------------------------
% 3. CLim
% ------------------------------------------------------------
if p.Results.UseMaskedRegionForCLim
    vals = F(support_mask & isfinite(F));
else
    vals = F(isfinite(F));
end

if isempty(vals)
    mx = 1;
else
    mx = max(abs(vals));
    if mx == 0
        mx = 1;
    end
end

% ------------------------------------------------------------
% 4. Pack output to match basis version
% ------------------------------------------------------------
S = struct();
S.body_part = body_part;
S.xq = xq;
S.yq = yq;
S.F = F;
S.support_mask = support_mask;
S.clim = [-mx mx];
S.occ = occ;
S.n_pos_samples = n_pos_samples;
end


function G = local_make_gaussian_kernel(sigma)
if sigma <= 0
    G = 1;
    return
end

rad = max(1, ceil(3 * sigma));
[xg, yg] = meshgrid(-rad:rad, -rad:rad);
G = exp(-(xg.^2 + yg.^2) / (2 * sigma^2));
G = G / sum(G(:));
end

function [x, y] = local_extract_bodypart_positions(trial_info, body_part, trial_sel)
%LOCAL_GET_BODYPART_XY_VALID
% Collect valid x/y positions for one body part across selected trials.
%
% Inputs
%   trial_info   struct array, one entry per trial
%   body_part    e.g. 'LeftPaw', 'LeftEar'
%   trial_sel    indices of trials to include
%
% Outputs
%   x, y         concatenated valid positions (column vectors)

if nargin < 3 || isempty(trial_sel)
    trial_sel = 1:numel(trial_info);
end

x_cell = {};
y_cell = {};

for ii = 1:numel(trial_sel)
    k = trial_sel(ii);

    if k < 1 || k > numel(trial_info)
        continue
    end

    if ~isfield(trial_info(k), body_part)
        continue
    end

    S = trial_info(k).(body_part);

    if ~isfield(S, 'x_rel_cm') || ~isfield(S, 'y_rel_cm')
        continue
    end

    xk = S.x_rel_cm;
    yk = S.y_rel_cm;

    if isempty(xk) || isempty(yk)
        continue
    end

    xk = xk(:);
    yk = yk(:);
    n = min(numel(xk), numel(yk));
    xk = xk(1:n);
    yk = yk(1:n);

    % optional validity mask if present
    if isfield(S, 'valid') && ~isempty(S.valid)
        vk = logical(S.valid(:));
        vk = vk(1:min(numel(vk), n));
        n2 = min([numel(xk), numel(yk), numel(vk)]);
        xk = xk(1:n2);
        yk = yk(1:n2);
        vk = vk(1:n2);
        good = vk & isfinite(xk) & isfinite(yk);
    else
        good = isfinite(xk) & isfinite(yk);
    end

    xk = xk(good);
    yk = yk(good);

    if ~isempty(xk)
        x_cell{end+1,1} = xk; %#ok<AGROW>
        y_cell{end+1,1} = yk; %#ok<AGROW>
    end
end

if isempty(x_cell)
    x = [];
    y = [];
else
    x = vertcat(x_cell{:});
    y = vertcat(y_cell{:});
end
end

