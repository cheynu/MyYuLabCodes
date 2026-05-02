function basis = design_shared_xy_basis_set(T, x_cols, y_cols, valid_cols, varargin)
%DESIGN_SHARED_XY_BASIS_SET
% Build one shared 2D Gaussian basis set from pooled valid x-y coordinates.
%
% Inputs
%   T          table
%   x_cols     cell array / string array of x column names
%   y_cols     cell array / string array of y column names
%   valid_cols cell array / string array of validity column names
%              pass [] or "" for entries with no validity column
%
% Name-value
%   'NumX'           default 5
%   'NumY'           default 5
%   'QuantileRange'  default [0.025 0.975]
%   'SigmaScale'     default 1.0
%
% Output
%   basis struct with fields:
%       .cx, .cy
%       .CX, .CY
%       .centers
%       .sigma_x, .sigma_y
%       .nx, .ny, .K
%       .x_range, .y_range
%       .quantile_range
%       .source_columns

p = inputParser;
p.addRequired('T', @(x) istable(x));
p.addRequired('x_cols', @(x) iscell(x) || isstring(x));
p.addRequired('y_cols', @(x) iscell(x) || isstring(x));
p.addRequired('valid_cols', @(x) isempty(x) || iscell(x) || isstring(x));

p.addParameter('NumX', 5, @(x) isnumeric(x) && isscalar(x) && x >= 2);
p.addParameter('NumY', 5, @(x) isnumeric(x) && isscalar(x) && x >= 2);
p.addParameter('QuantileRange', [0.025 0.975], @(x) isnumeric(x) && numel(x)==2);
p.addParameter('SigmaScale', 1.0, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.parse(T, x_cols, y_cols, valid_cols, varargin{:});

x_cols = cellstr(string(x_cols(:)));
y_cols = cellstr(string(y_cols(:)));

if isempty(valid_cols)
    valid_cols = repmat({''}, size(x_cols));
else
    valid_cols = cellstr(string(valid_cols(:)));
end

if numel(x_cols) ~= numel(y_cols)
    error('x_cols and y_cols must have the same length.');
end

if numel(valid_cols) ~= numel(x_cols)
    error('valid_cols must have the same length as x_cols, or be empty.');
end

nx = p.Results.NumX;
ny = p.Results.NumY;
qrange = p.Results.QuantileRange;
sigma_scale = p.Results.SigmaScale;

x_all = [];
y_all = [];

for i = 1:numel(x_cols)
    x_col = x_cols{i};
    y_col = y_cols{i};
    v_col = valid_cols{i};

    if ~ismember(x_col, T.Properties.VariableNames)
        error('Missing x column: %s', x_col);
    end
    if ~ismember(y_col, T.Properties.VariableNames)
        error('Missing y column: %s', y_col);
    end

    x = T.(x_col);
    y = T.(y_col);

    if ~isempty(v_col)
        if ~ismember(v_col, T.Properties.VariableNames)
            error('Missing valid column: %s', v_col);
        end
        v = logical(T.(v_col));
    else
        v = true(height(T),1);
    end

    good = v & isfinite(x) & isfinite(y);

    x_all = [x_all; x(good)]; %#ok<AGROW>
    y_all = [y_all; y(good)]; %#ok<AGROW>
end

if isempty(x_all)
    error('No valid pooled x-y samples found.');
end

x_lo = quantile(x_all, qrange(1));
x_hi = quantile(x_all, qrange(2));
y_lo = quantile(y_all, qrange(1));
y_hi = quantile(y_all, qrange(2));

cx = linspace(x_lo, x_hi, nx);
cy = linspace(y_lo, y_hi, ny);

[CX, CY] = meshgrid(cx, cy);

if nx > 1
    dx = median(diff(cx));
else
    dx = std(x_all);
end

if ny > 1
    dy = median(diff(cy));
else
    dy = std(y_all);
end

sigma_x = sigma_scale * dx;
sigma_y = sigma_scale * dy;

basis = struct();
basis.cx = cx;
basis.cy = cy;
basis.CX = CX;
basis.CY = CY;
basis.centers = [CX(:), CY(:)];
basis.sigma_x = sigma_x;
basis.sigma_y = sigma_y;
basis.nx = nx;
basis.ny = ny;
basis.K = size(basis.centers, 1);
basis.x_range = [x_lo, x_hi];
basis.y_range = [y_lo, y_hi];
basis.quantile_range = qrange;
basis.source_columns = table(string(x_cols), string(y_cols), string(valid_cols), ...
    'VariableNames', {'x_col','y_col','valid_col'});
end