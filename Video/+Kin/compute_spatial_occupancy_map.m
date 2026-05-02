function occ = compute_spatial_occupancy_map(x, y, xq, yq, varargin)
%COMPUTE_SPATIAL_OCCUPANCY_MAP Occupancy map on the same grid as field.
%
% occ = compute_spatial_occupancy_map(x, y, xq, yq)
%
% Inputs
%   x, y    position samples for one body part, vectors of same length
%   xq, yq  grid axes used for reconstructed field
%
% Name-value
%   'Dt'          sample duration in seconds, default 1
%   'SmoothSigma' Gaussian smoothing sigma in grid bins, default 1
%
% Output fields
%   .H_count      raw sample counts per bin
%   .H_time       occupancy time per bin
%   .H_smooth     smoothed occupancy time
%   .x_edges
%   .y_edges
%   .x_centers
%   .y_centers

p = inputParser;
p.addParameter('Dt', 1, @(z) isnumeric(z) && isscalar(z) && z > 0);
p.addParameter('SmoothSigma', 1, @(z) isnumeric(z) && isscalar(z) && z >= 0);
p.parse(varargin{:});

dt = p.Results.Dt;
smooth_sigma = p.Results.SmoothSigma;

x = x(:);
y = y(:);

good = isfinite(x) & isfinite(y);
x = x(good);
y = y(good);

% build edges from grid centers
dx = median(diff(xq));
dy = median(diff(yq));

x_edges = [xq(1)-dx/2, xq(1:end-1)+dx/2, xq(end)+dx/2];
y_edges = [yq(1)-dy/2, yq(1:end-1)+dy/2, yq(end)+dy/2];

% histcounts2 returns size [numel(x_edges)-1, numel(y_edges)-1]
H = histcounts2(x, y, x_edges, y_edges);

% transpose so rows correspond to y and columns to x, matching imagesc/meshgrid
H = H';

H_time = H * dt;

if smooth_sigma > 0
    H_smooth = imgaussfilt(H_time, smooth_sigma);
else
    H_smooth = H_time;
end

occ = struct();
occ.H_count = H;
occ.H_time = H_time;
occ.H_smooth = H_smooth;
occ.x_edges = x_edges;
occ.y_edges = y_edges;
occ.x_centers = xq;
occ.y_centers = yq;
end