function [theta_filled, valid, filled_mask] = fill_head_direction(theta, tracking_lh, fs, varargin)
% Fill short NaN gaps in head-direction (radians), circular-safe.
% - theta: 1xN (radians, can contain NaN)
% - tracking_lh: 1xN likelihood (or [] if theta already has NaNs)
% - fs: sampling rate (Hz)
%
% Name-value:
%   'Thresh'     likelihood threshold (default 0.9)
%   'MaxGapSec'  fill gaps <= this duration (default 0.15)
p = inputParser;
p.addParameter('Thresh', 0.9, @(v) isnumeric(v)&&isscalar(v));
p.addParameter('MaxGapSec', 0.15, @(v) isnumeric(v)&&isscalar(v)&&v>=0);
p.parse(varargin{:});
thr = p.Results.Thresh;
maxGap = round(p.Results.MaxGapSec * fs);

theta = theta(:)';  % row
n = numel(theta);

if ~isempty(tracking_lh)
    tracking_lh = tracking_lh(:)';
    valid = (tracking_lh > thr) & ~isnan(theta);
else
    valid = ~isnan(theta);
end

theta_filled = theta;
filled_mask  = false(1,n);

% --- work on unwrapped angle, but only within valid segments ---
theta_u = theta;
theta_u(~valid) = NaN;

% unwrap within each valid contiguous segment
seg = bwconncomp(valid);
for s = 1:seg.NumObjects
    idx = seg.PixelIdxList{s};
    theta_u(idx) = unwrap(theta_u(idx));
end

% --- fill short gaps by linear interpolation in unwrapped space ---
nanMask = ~valid;
d = diff([0 nanMask 0]);
gapStarts = find(d==1);
gapEnds   = find(d==-1)-1;

for g = 1:numel(gapStarts)
    gs = gapStarts(g); ge = gapEnds(g);
    glen = ge-gs+1;
    if glen <= maxGap
        left  = gs-1;
        right = ge+1;
        if left>=1 && right<=n && ~isnan(theta_u(left)) && ~isnan(theta_u(right))
            theta_u(gs:ge) = linspace(theta_u(left), theta_u(right), glen+2).';
            filled_mask(gs:ge) = true;
        end
    end
end

% wrap back to (-pi, pi]
theta_filled = mod(theta_u + pi, 2*pi) - pi;

% keep long gaps as NaN
theta_filled(~valid & ~filled_mask) = NaN;
end