function mask = make_occupancy_support_mask(occ, varargin)
%MAKE_OCCUPANCY_SUPPORT_MASK Create support mask from occupancy map.

p = inputParser;
p.addParameter('MinTime', [], @(z) isempty(z) || (isnumeric(z) && isscalar(z) && z >= 0));
p.addParameter('MinFracOfMax', [], @(z) isempty(z) || (isnumeric(z) && isscalar(z) && z >= 0 && z <= 1));
p.addParameter('MinQuantileNonzero', 0.01, @(z) isempty(z) || (isnumeric(z) && isscalar(z) && z >= 0 && z <= 1));
p.addParameter('UseSmoothedOcc', true, @(z) islogical(z) && isscalar(z));
p.parse(varargin{:});

min_time = p.Results.MinTime;
min_frac = p.Results.MinFracOfMax;
min_q = p.Results.MinQuantileNonzero;
use_smoothed = p.Results.UseSmoothedOcc;

if use_smoothed
    H = occ.H_smooth;
else
    H = occ.H_time;
end

if ~isempty(min_time)
    thr = min_time;
elseif ~isempty(min_q)
    a = H(:);
    a = a(a > 0);
    if isempty(a)
        thr = inf;
    else
        thr = quantile(a, min_q);
    end
elseif ~isempty(min_frac)
    thr = min_frac * max(H(:));
else
    error('Specify one of MinTime, MinQuantileNonzero, or MinFracOfMax.');
end

mask = H >= thr;
end