function bins = design_shared_xy_bin_set(T, x_cols, y_cols, valid_cols, varargin)
%DESIGN_SHARED_XY_BIN_SET
% Build one shared 2D hard-bin set from pooled valid x-y coordinates.
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
%
% Output
%   bins struct with fields:
%       .x_edges, .y_edges
%       .x_centers, .y_centers
%       .CX, .CY
%       .centers
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

if ~(x_hi > x_lo) || ~(y_hi > y_lo)
    error('Degenerate x/y range after quantile selection.');
end

x_edges = linspace(x_lo, x_hi, nx+1);
y_edges = linspace(y_lo, y_hi, ny+1);

x_centers = (x_edges(1:end-1) + x_edges(2:end)) / 2;
y_centers = (y_edges(1:end-1) + y_edges(2:end)) / 2;

[CX, CY] = meshgrid(x_centers, y_centers);

% ------------------------------------------------------------
% define consistent bin indexing (x-fast order)
% ------------------------------------------------------------

[ix_grid, iy_grid] = meshgrid(1:nx, 1:ny);  % size = [ny, nx]

% flatten in x-fast order (row-major)
ix_list = reshape(ix_grid', [], 1);
iy_list = reshape(iy_grid', [], 1);

% generate labels
bin_labels = strings(numel(ix_list),1);
for k = 1:numel(ix_list)
    bin_labels(k) = sprintf("x%02d_y%02d", ix_list(k), iy_list(k));
end

bins = struct();
bins.x_edges = x_edges;
bins.y_edges = y_edges;
bins.x_centers = x_centers;
bins.y_centers = y_centers;
bins.CX = CX;
bins.CY = CY;
% reorder centers to match x-fast indexing
CX_flat = reshape(CX', [], 1);
CY_flat = reshape(CY', [], 1);
bins.centers = [CX_flat, CY_flat];
bins.ix = ix_list;
bins.iy = iy_list;
bins.labels = bin_labels;

bins.nx = nx;
bins.ny = ny;
bins.K = numel(CX);
bins.x_range = [x_lo, x_hi];
bins.y_range = [y_lo, y_hi];
bins.quantile_range = qrange;
bins.source_columns = table(string(x_cols), string(y_cols), string(valid_cols), ...
    'VariableNames', {'x_col','y_col','valid_col'});
end