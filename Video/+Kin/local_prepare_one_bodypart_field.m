function S = local_prepare_one_bodypart_field(result, basis, trial_info, body_part, is_average_mode, varargin)
%LOCAL_PREPARE_ONE_BODYPART_FIELD
% Prepare one reconstructed spatial field plus occupancy-based mask.
%
% Output S fields:
%   .body_part
%   .xq, .yq
%   .F
%   .support_mask
%   .clim
%   .occ            (optional diagnostic)
%   .n_pos_samples

p = inputParser;
p.addParameter('UseOccupancyMask', true, @(x) islogical(x) && isscalar(x));
p.addParameter('MaskSmoothSigma', 1, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.addParameter('MaskQuantileNonzero', 0.01, @(x) isnumeric(x) && isscalar(x) && x >= 0 && x <= 1);
p.addParameter('MaskUseSmoothedOcc', true, @(x) islogical(x) && isscalar(x));
p.addParameter('UseMaskedRegionForCLim', true, @(x) islogical(x) && isscalar(x));
p.parse(varargin{:});

use_mask = p.Results.UseOccupancyMask;
mask_smooth_sigma = p.Results.MaskSmoothSigma;
mask_quantile = p.Results.MaskQuantileNonzero;
mask_use_smoothed = p.Results.MaskUseSmoothedOcc;
use_masked_for_clim = p.Results.UseMaskedRegionForCLim;

% --------------------------------
% 1) reconstruct / read field
% --------------------------------
if is_average_mode
    if ~isfield(result.field, body_part)
        error('Missing result.field.%s', body_part);
    end
    Fstruct = struct( ...
        'xq', result.field.(body_part).xq, ...
        'yq', result.field.(body_part).yq, ...
        'F',  result.field.(body_part).F_mean);
else
    Fstruct = Kin.reconstruct_spatial_tuning_field(result, basis, body_part);
end

% --------------------------------
% 2) extract positions
% --------------------------------
[x_bp, y_bp] = local_extract_bodypart_positions(trial_info, body_part, 1:numel(trial_info));
n_pos_samples = numel(x_bp);

% --------------------------------
% 3) build support mask
% --------------------------------
if use_mask && ~isempty(x_bp)
    occ = local_compute_spatial_occupancy_map( ...
        x_bp, y_bp, Fstruct.xq, Fstruct.yq, ...
        'SmoothSigma', mask_smooth_sigma);

    support_mask = local_make_occupancy_support_mask_quantile( ...
        occ, ...
        'MinQuantileNonzero', mask_quantile, ...
        'UseSmoothedOcc', mask_use_smoothed);
else
    occ = struct();
    support_mask = true(size(Fstruct.F));
end

% --------------------------------
% 4) CLim
% --------------------------------
if use_masked_for_clim
    vals = Fstruct.F(isfinite(Fstruct.F) & support_mask);
else
    vals = Fstruct.F(isfinite(Fstruct.F));
end

mx = max(abs(vals));
if isempty(mx) || mx == 0
    mx = 1;
end

% --------------------------------
% 5) package output
% --------------------------------
S = struct();
S.body_part = body_part;
S.xq = Fstruct.xq;
S.yq = Fstruct.yq;
S.F = Fstruct.F;
S.support_mask = support_mask;
S.clim = [-mx mx];
S.occ = occ;
S.n_pos_samples = n_pos_samples;
end



function [x, y] = local_extract_bodypart_positions(trial_info, body_part, trial_sel)
x_cell = {};
y_cell = {};

for ii = 1:numel(trial_sel)
    k = trial_sel(ii);

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

    good = isfinite(xk) & isfinite(yk);
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

function occ = local_compute_spatial_occupancy_map(x, y, xq, yq, varargin)
p = inputParser;
p.addParameter('SmoothSigma', 1, @(z) isnumeric(z) && isscalar(z) && z >= 0);
p.parse(varargin{:});

smooth_sigma = p.Results.SmoothSigma;

x = x(:);
y = y(:);
good = isfinite(x) & isfinite(y);
x = x(good);
y = y(good);

dx = median(diff(xq));
dy = median(diff(yq));

x_edges = [xq(1)-dx/2, xq(1:end-1)+dx/2, xq(end)+dx/2];
y_edges = [yq(1)-dy/2, yq(1:end-1)+dy/2, yq(end)+dy/2];

H = histcounts2(x, y, x_edges, y_edges);
H = H';  % rows = y bins, cols = x bins

if smooth_sigma > 0
    H_smooth = imgaussfilt(H, smooth_sigma);
else
    H_smooth = H;
end

occ = struct();
occ.H_count = H;
occ.H_smooth = H_smooth;
end

function mask = local_make_occupancy_support_mask_quantile(occ, varargin)
p = inputParser;
p.addParameter('MinQuantileNonzero', 0.01, @(z) isnumeric(z) && isscalar(z) && z >= 0 && z <= 1);
p.addParameter('UseSmoothedOcc', true, @(z) islogical(z) && isscalar(z));
p.parse(varargin{:});

min_q = p.Results.MinQuantileNonzero;
use_smoothed = p.Results.UseSmoothedOcc;

if use_smoothed
    Hmask = occ.H_smooth;
else
    Hmask = occ.H_count;
end

Href = occ.H_count;  % use raw occupancy for threshold reference
a = Href(:);
a = a(a > 0);

if isempty(a)
    mask = false(size(Hmask));
    return
end

thr = quantile(a, min_q);
mask = Hmask >= thr;
end
