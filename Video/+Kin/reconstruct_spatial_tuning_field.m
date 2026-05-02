function field = reconstruct_spatial_tuning_field(result, basis, body_part, varargin)
%RECONSTRUCT_SPATIAL_TUNING_FIELD Reconstruct smooth spatial field from basis betas.
%
% field = reconstruct_spatial_tuning_field(result, basis, body_part)
%
% Inputs
%   result    fitted result struct, must contain result.beta_table
%   basis     basis struct with:
%               .centers, .sigma_x, .sigma_y, .x_range, .y_range
%   body_part string or char, e.g. 'LeftPaw' or 'LeftEar'
%
% Name-value
%   'NumX'    number of x grid points, default 100
%   'NumY'    number of y grid points, default 100
%
% Output struct fields
%   .xq, .yq      query axes
%   .Xq, .Yq      meshgrid
%   .F            reconstructed field on log-rate scale
%   .beta_basis   K x 1 basis beta vector

p = inputParser;
p.addParameter('NumX', 100, @(x) isnumeric(x) && isscalar(x) && x >= 10);
p.addParameter('NumY', 100, @(x) isnumeric(x) && isscalar(x) && x >= 10);
p.parse(varargin{:});

nx = p.Results.NumX;
ny = p.Results.NumY;

if ~isfield(result, 'beta_table')
    error('result.beta_table is required.');
end

T = result.beta_table;
K = size(basis.centers, 1);

% collect basis betas for this body part
beta_basis = zeros(K,1);
fn = string(T.feature_name);

for k = 1:K
    target = sprintf('%s_basis_%02d', string(body_part), k);
    idx = find(fn == target, 1);
    if ~isempty(idx)
        beta_basis(k) = T.beta(idx);
    end
end

% dense query grid
xq = linspace(basis.x_range(1), basis.x_range(2), nx);
yq = linspace(basis.y_range(1), basis.y_range(2), ny);
[Xq, Yq] = meshgrid(xq, yq);

F = zeros(size(Xq));

for k = 1:K
    cx = basis.centers(k,1);
    cy = basis.centers(k,2);

    Phi_k = exp( ...
        -0.5 * ((Xq - cx) ./ basis.sigma_x).^2 ...
        -0.5 * ((Yq - cy) ./ basis.sigma_y).^2 );

    F = F + beta_basis(k) * Phi_k;
end

field = struct();
field.xq = xq;
field.yq = yq;
field.Xq = Xq;
field.Yq = Yq;
field.F = F;
field.beta_basis = beta_basis;
end