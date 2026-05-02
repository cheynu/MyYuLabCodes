function [Phi, feature_names] = eval_xy_basis(T, x_col, y_col, valid_col, basis, prefix)
%EVAL_XY_BASIS Evaluate shared 2D Gaussian basis for one x-y pair.

if ~ismember(x_col, T.Properties.VariableNames)
    error('Missing x column: %s', x_col);
end
if ~ismember(y_col, T.Properties.VariableNames)
    error('Missing y column: %s', y_col);
end

x = T.(x_col);
y = T.(y_col);

if nargin >= 4 && ~isempty(valid_col)
    if ~ismember(valid_col, T.Properties.VariableNames)
        error('Missing valid column: %s', valid_col);
    end
    v = logical(T.(valid_col));
else
    v = true(height(T),1);
end

x = x(:);
y = y(:);
v = v(:);

n = numel(x);
K = basis.K;

Phi = nan(n, K);
feature_names = strings(K,1);

for k = 1:K
    cx = basis.centers(k,1);
    cy = basis.centers(k,2);

    Phi(:,k) = exp( ...
        -0.5 * ((x - cx) ./ basis.sigma_x).^2 ...
        -0.5 * ((y - cy) ./ basis.sigma_y).^2 );

    feature_names(k) = sprintf('%s_basis_%02d', prefix, k);
end

bad = ~v | ~isfinite(x) | ~isfinite(y);
Phi(bad,:) = NaN;
end