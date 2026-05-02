function out = reconstruct_spatial_tuning_field_masked(result, basis, body_part, x, y, varargin)
%RECONSTRUCT_SPATIAL_TUNING_FIELD_MASKED
% Reconstruct smooth spatial field from basis betas, compute occupancy on
% the same grid, and mask low-occupancy regions.
%
% out = reconstruct_spatial_tuning_field_masked(result, basis, body_part, x, y)
%
% Inputs
%   result      fitted result struct, must contain result.beta_table
%   basis       basis struct with:
%                 .centers, .sigma_x, .sigma_y, .x_range, .y_range
%   body_part   string or char, e.g. 'LeftPaw'
%   x, y        position samples used for occupancy support
%
% Name-value
%   'NumX'            number of x grid points, default 100
%   'NumY'            number of y grid points, default 100
%   'Dt'              sample duration in seconds, default 1
%   'SmoothSigma'     Gaussian smoothing sigma for occupancy (grid bins), default 1
%   'MinTime'         minimum occupancy time threshold, default []
%   'MinFracOfMax'    threshold as fraction of max smoothed occupancy, default 0.05
%   'UseSmoothedOcc'  true/false, use smoothed occupancy for mask, default true
%   'ShowPlot'        true/false, default false
%   'ShowExpField'    true/false, default false
%
% Output
%   out.field         field struct from reconstruction, plus masked field
%   out.occ           occupancy struct
%   out.mask          logical support mask
%
% Notes
%   field.F is on the log-rate scale.
%   exp(field.F) is the multiplicative gain implied by this body-part
%   position block, if using a log-link GLM.

p = inputParser;
p.addParameter('NumX', 100, @(z) isnumeric(z) && isscalar(z) && z >= 10);
p.addParameter('NumY', 100, @(z) isnumeric(z) && isscalar(z) && z >= 10);
p.addParameter('Dt', 1, @(z) isnumeric(z) && isscalar(z) && z > 0);
p.addParameter('SmoothSigma', 1, @(z) isnumeric(z) && isscalar(z) && z >= 0);
p.addParameter('MinTime', [], @(z) isempty(z) || (isnumeric(z) && isscalar(z) && z >= 0));
p.addParameter('MinFracOfMax', 0.05, @(z) isnumeric(z) && isscalar(z) && z >= 0 && z <= 1);
p.addParameter('UseSmoothedOcc', true, @(z) islogical(z) && isscalar(z));
p.addParameter('ShowPlot', false, @(z) islogical(z) && isscalar(z));
p.addParameter('ShowExpField', false, @(z) islogical(z) && isscalar(z));
p.parse(varargin{:});

nx = p.Results.NumX;
ny = p.Results.NumY;
dt = p.Results.Dt;
smooth_sigma = p.Results.SmoothSigma;
min_time = p.Results.MinTime;
min_frac = p.Results.MinFracOfMax;
use_smoothed_occ = p.Results.UseSmoothedOcc;
show_plot = p.Results.ShowPlot;
show_exp_field = p.Results.ShowExpField;

% 1) reconstruct field
field = Kin.reconstruct_spatial_tuning_field(result, basis, body_part, ...
    'NumX', nx, 'NumY', ny);

% 2) occupancy on same grid
occ = Kin.compute_spatial_occupancy_map(x, y, field.xq, field.yq, ...
    'Dt', dt, 'SmoothSigma', smooth_sigma);

% 3) support mask
mask = Kin.make_occupancy_support_mask(occ, ...
    'MinQuantileNonzero', 0.01, ...
    'UseSmoothedOcc', true);

% 4) apply mask
field = Kin.apply_occupancy_mask_to_field(field, mask);

out = struct();
out.field = field;
out.occ = occ;
out.mask = mask;

% 5) plot if needed
 
end