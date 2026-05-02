function out = map_event_time(t_domain1, t_ref_domain1, t_ref_domain2, varargin)
% Jianing Yu 2025.12.21 with chat
% map_event_time
% Map event timestamps from domain1 to domain2 using reference anchor pairs
% (t_ref_domain1 <-> t_ref_domain2) and piecewise-linear interpolation.
%
% INPUTS
%   t_domain1      : [N x 1] (or [1 x N]) event times in domain1 (to map)
%   t_ref_domain1  : [M x 1] reference anchor times in domain1
%   t_ref_domain2  : [M x 1] corresponding reference anchor times in domain2
%
% NAME-VALUE OPTIONS
%   'Extrapolation' : 'nearest' (default) | 'linear' | 'none'
%       - 'nearest': clamp to the endpoint anchors before interpolation
%       - 'linear' : allow linear extrapolation beyond anchor range
%       - 'none'   : return NaN outside anchor range
%
%   'DuplicatePolicy' : 'first' (default) | 'mean'
%       How to handle duplicate t_ref_domain1 values after sorting:
%       - 'first': keep first occurrence
%       - 'mean' : average t_ref_domain2 for duplicates
%
% OUTPUT (struct)
%   out.t_domain2         : mapped event times in domain2 (same shape as t_domain1)
%   out.closestRefIdx     : index (into sorted anchors) of closest ref point
%   out.closestRefDomain1 : closest anchor time in domain1
%   out.closestRefDomain2 : corresponding anchor time in domain2
%   out.ref_domain1       : sorted, cleaned anchor times in domain1 actually used
%   out.ref_domain2       : sorted, cleaned anchor times in domain2 actually used

% -------------------- parse options --------------------
p = inputParser;
p.addParameter('Extrapolation', 'none', @(s)ischar(s) || isstring(s));
p.addParameter('DuplicatePolicy', 'first', @(s)ischar(s) || isstring(s));
p.parse(varargin{:});
extrapMode = lower(string(p.Results.Extrapolation));
dupMode    = lower(string(p.Results.DuplicatePolicy));

% -------------------- reshape inputs (internal as column) --------------------
sz_in = size(t_domain1);
t_domain1     = t_domain1(:);
t_ref_domain1 = t_ref_domain1(:);
t_ref_domain2 = t_ref_domain2(:);

% -------------------- validate refs --------------------
if numel(t_ref_domain1) ~= numel(t_ref_domain2)
    error('t_ref_domain1 and t_ref_domain2 must have the same length.');
end

good = isfinite(t_ref_domain1) & isfinite(t_ref_domain2);
x = t_ref_domain1(good);
y = t_ref_domain2(good);

if numel(x) < 2
    error('Need at least 2 valid reference anchor pairs for interpolation.');
end

% sort anchors by domain1 time
[x, ord] = sort(x, 'ascend');
y = y(ord);

% -------------------- handle duplicates in x --------------------
dx = diff(x);
hasDup = any(dx == 0);

if hasDup
    switch dupMode
        case "first"
            keep = [true; dx ~= 0];
            x = x(keep);
            y = y(keep);

        case "mean"
            % group duplicates and average y within each unique x
            [xu, ~, g] = unique(x, 'stable');
            yu = accumarray(g, y, [], @mean);
            x = xu;
            y = yu;

        otherwise
            error("Unknown DuplicatePolicy: %s. Use 'first' or 'mean'.", dupMode);
    end
end

if numel(x) < 2
    error('After duplicate handling, fewer than 2 unique anchors remain.');
end

% -------------------- closest reference anchor for each event --------------------
N = numel(t_domain1);
closestIdx = nan(N,1);
closestX   = nan(N,1);
closestY   = nan(N,1);

for k = 1:N
    tk = t_domain1(k);
    if ~isfinite(tk), continue; end
    [~, ii] = min(abs(x - tk));
    closestIdx(k) = ii;
    closestX(k)   = x(ii);
    closestY(k)   = y(ii);
end

% -------------------- interpolation mapping domain1 -> domain2 --------------------
switch extrapMode
    case "nearest"
        tq = min(max(t_domain1, x(1)), x(end));
        t_domain2 = interp1(x, y, tq, 'linear');

    case "linear"
        t_domain2 = interp1(x, y, t_domain1, 'linear', 'extrap');

    case "none"
        t_domain2 = interp1(x, y, t_domain1, 'linear', NaN);

    otherwise
        error("Unknown Extrapolation mode: %s. Use 'nearest', 'linear', or 'none'.", extrapMode);
end

% -------------------- package output --------------------
out = struct();
out.t_domain2         = reshape(t_domain2, sz_in);
out.closestRefIdx     = reshape(closestIdx, sz_in);
out.closestRefDomain1 = reshape(closestX,   sz_in);
out.closestRefDomain2 = reshape(closestY,   sz_in);
out.ref_domain1       = x;
out.ref_domain2       = y;

end
