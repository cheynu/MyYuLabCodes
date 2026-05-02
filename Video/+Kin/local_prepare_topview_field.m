function field_info = local_prepare_topview_field_bin( ...
    Tbeta, basis, trial_info, phases, position_prefix, varargin)

% -------------------- parse --------------------
p = inputParser;
p.addParameter('UseOccupancyMask', true, @(x) islogical(x));
p.addParameter('MaskSmoothSigma', 1, @(x) isnumeric(x));
p.addParameter('MaskQuantileNonzero', 0, @(x) isnumeric(x));
p.addParameter('MaskUseSmoothedOcc', true, @(x) islogical(x));
p.addParameter('UseMaskedRegionForCLim', true, @(x) islogical(x));
p.parse(varargin{:});

use_mask = p.Results.UseOccupancyMask;
mask_smooth_sigma = p.Results.MaskSmoothSigma;
mask_quantile = p.Results.MaskQuantileNonzero;
mask_use_smoothed = p.Results.MaskUseSmoothedOcc;
use_masked_for_clim = p.Results.UseMaskedRegionForCLim;

% ============================================================
% 1. extract bin betas
% ============================================================
fn = string(Tbeta.feature_name);
prefix = string(position_prefix) + "_bin_";

is_bin = startsWith(fn, prefix);
Tb = Tbeta(is_bin, :);

fn_sub = extractAfter(fn(is_bin), prefix);  % "x01_y01"

tokens = split(fn_sub, ["x","_y"]);

ix = str2double(tokens(:,2));
iy = str2double(tokens(:,3));

valid = isfinite(ix) & isfinite(iy);
ix = ix(valid);
iy = iy(valid);
beta_vals = Tb.beta(valid);

% ============================================================
% 2. build F (CORE)
% ============================================================
F = zeros(basis.ny, basis.nx);   % (row=y, col=x)

for i = 1:numel(beta_vals)
    if ix(i) >= 1 && ix(i) <= basis.nx && ...
       iy(i) >= 1 && iy(i) <= basis.ny
        F(iy(i), ix(i)) = beta_vals(i);
    end
end

xq = basis.x_centers;
yq = basis.y_centers;

% ============================================================
% 3. occupancy mask (SAME logic, adapted edges)
% ============================================================
support_mask = true(size(F));
occ = zeros(size(F));

if use_mask
    [x_occ, y_occ] = local_collect_phase_xy(trial_info, phases);

    if ~isempty(x_occ)

        occ = histcounts2(y_occ, x_occ, basis.y_edges, basis.x_edges);

        if mask_smooth_sigma > 0
            kernel_size = max(3, ceil(mask_smooth_sigma * 6));
            if mod(kernel_size,2) == 0
                kernel_size = kernel_size + 1;
            end
            G = fspecial('gaussian', [kernel_size kernel_size], mask_smooth_sigma);
            occ_s = imfilter(occ, G, 'replicate');
        else
            occ_s = occ;
        end

        if mask_use_smoothed
            occ_ref = occ_s;
        else
            occ_ref = occ;
        end

        nz = occ_ref(occ_ref > 0);
        if isempty(nz)
            thresh = 0;
        else
            thresh = quantile(nz, mask_quantile);
        end

        support_mask = occ_ref > thresh;
    end
end

% ============================================================
% 4. clim (same rule: min 0.2)
% ============================================================
if use_masked_for_clim && any(support_mask(:))
    vals = F(support_mask);
else
    vals = F(:);
end

mx = max(abs(vals), [], 'omitnan');

if isempty(mx) || mx < 0.2
    mx = 0.2;
else
    mx = ceil(mx*10)/10;
end

clim = [-mx mx];

% ============================================================
% output
% ============================================================
field_info = struct();
field_info.F = F;
field_info.xq = xq;
field_info.yq = yq;
field_info.support_mask = support_mask;
field_info.occ = occ;
field_info.clim = clim;

end