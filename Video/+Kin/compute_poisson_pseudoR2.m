function pr2 = compute_poisson_pseudoR2(y, mu_model, mu_null, den_tol)
if nargin < 4 || isempty(den_tol)
    den_tol = 1e-8;
end
y = y(:);
mu_model = max(mu_model(:), eps);

if isscalar(mu_null)
    mu_null = repmat(max(mu_null, eps), size(y));
else
    mu_null = max(mu_null(:), eps);
end

L_model = local_poisson_loglik(y, mu_model);
L_null  = local_poisson_loglik(y, mu_null);

ysafe = y;
ysafe(ysafe == 0) = 1;
L_sat = sum(y .* log(ysafe) - y - gammaln(y + 1));

den = L_sat - L_null;
den_tol = 1e-8;

if ~isfinite(den) || abs(den) < den_tol
    pr2 = NaN;
    return
end

pr2 = 1 - (L_sat - L_model) / den;

if ~isfinite(pr2) || abs(pr2) > 100
    pr2 = NaN;
end
end

function ll = local_poisson_loglik(y, mu)
y = y(:);
mu = mu(:);

mu(~isfinite(mu)) = 1e6;
mu = min(max(mu, eps), 1e6);

ll = sum(y .* log(mu) - mu - gammaln(y + 1));
end