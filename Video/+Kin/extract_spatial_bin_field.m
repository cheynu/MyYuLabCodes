function F = extract_spatial_bin_field(result, bins, body_part)
%EXTRACT_SPATIAL_BIN_FIELD
% For one-hot spatial bin features, return the fitted beta map directly.

feature_names = string(result.feature_names(:));
beta = result.beta(:);

pat = sprintf('%s_bin_', body_part);
idx = startsWith(feature_names, pat);

beta_bin = beta(idx);

if isempty(beta_bin)
    F = local_make_empty_field_struct();
    return
end

if numel(beta_bin) ~= bins.K
    error('Bin beta count mismatch for %s: got %d, expected %d.', ...
        body_part, numel(beta_bin), bins.K);
end

beta_map = reshape(beta_bin, [bins.ny, bins.nx]);

[Xq, Yq] = meshgrid(bins.x_centers, bins.y_centers);

F = struct();
F.xq = bins.x_centers;
F.yq = bins.y_centers;
F.Xq = Xq;
F.Yq = Yq;
F.F = beta_map;          % direct bin-wise beta map
F.beta_basis = [];
F.beta_bin = beta_bin;
F.mode = "bin";
end

function F = local_make_empty_field_struct()
F = struct( ...
    'xq', [], ...
    'yq', [], ...
    'Xq', [], ...
    'Yq', [], ...
    'F', [], ...
    'beta_basis', [], ...
    'beta_bin', [], ...
    'mode', "");
end