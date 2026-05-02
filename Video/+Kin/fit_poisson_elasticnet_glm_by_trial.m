function result = fit_poisson_elasticnet_glm_by_trial(feature_mat, spike_times, varargin)
%FIT_POISSON_ELASTICNET_GLM_BY_TRIAL
% Fit a Poisson elastic-net GLM with trial-based train/test split and
% trial-based inner CV for lambda selection, using MATLAB built-in lassoglm.

p = inputParser;
p.addParameter('TrainFrac', 0.75, @(x) isnumeric(x) && isscalar(x) && x > 0 && x < 1);
p.addParameter('Alpha', 0.9, @(x) isnumeric(x) && isscalar(x) && x >= 0 && x <= 1);
p.addParameter('NumInnerFolds', 5, @(x) isnumeric(x) && isscalar(x) && x >= 2);
p.addParameter('NumLambda', 50, @(x) isnumeric(x) && isscalar(x) && x >= 5);
p.addParameter('Lambda', [], @(x) isempty(x) || isnumeric(x));
p.addParameter('Seed', 1, @(x) isnumeric(x) && isscalar(x));
p.addParameter('Standardize', true, @(x) islogical(x) && isscalar(x));
p.addParameter('Verbose', true, @(x) islogical(x) && isscalar(x));
p.addParameter('MinSpikesToFit', 100, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.addParameter('UnitID', '', @(x) isstring(x));

p.parse(varargin{:});

train_frac     = p.Results.TrainFrac;
alpha          = p.Results.Alpha;
n_inner_folds  = p.Results.NumInnerFolds;
n_lambda       = p.Results.NumLambda;
lambda_user    = p.Results.Lambda;
seed           = p.Results.Seed;
do_standardize = p.Results.Standardize;
verbose        = p.Results.Verbose;
min_spikes_to_fit = p.Results.MinSpikesToFit;
unit_id = p.Results.UnitID;
rng(seed);

% ------------------------------------------------------------
% 1. Build response vector y from spike times
% ------------------------------------------------------------
y_all = local_bin_spike_counts(spike_times, ...
    feature_mat.time_bin_start, feature_mat.time_bin_end);

% ------------------------------------------------------------
% 2. Restrict to valid rows
% ------------------------------------------------------------
use_rows = feature_mat.valid_rows(:);

X = feature_mat.X(use_rows, :);
y = y_all(use_rows);
trial = string(feature_mat.trial(use_rows));
t0 = feature_mat.time_bin_start(use_rows);
t1 = feature_mat.time_bin_end(use_rows);
n_spikes_used = sum(y);
% fprintf('++++++++++ Found %d spikes for fitting ++++++++++\n', n_spikes_used)
n_obs = size(X,1);
n_feat = size(X,2);

if verbose
    fprintf('[fit_glm] Using %d valid rows, %d features\n', n_obs, n_feat);
end

if n_spikes_used < min_spikes_to_fit
    if verbose
        fprintf('[fit_glm] Too few spikes for fitting: %d < %d. Returning NaNs.\n', ...
            n_spikes_used, min_spikes_to_fit);
    end

    result = local_make_low_spike_result( ...
        feature_mat, spike_times, use_rows, y, trial, t0, t1, ...
        n_spikes_used, min_spikes_to_fit);

    return
end

% ------------------------------------------------------------
% 3. Trial-based outer train/test split
% ------------------------------------------------------------
u_trials = unique(trial, 'stable');
n_trials = numel(u_trials);

perm = randperm(n_trials);
n_train_trials = max(1, round(train_frac * n_trials));

train_trial_ids = u_trials(perm(1:n_train_trials));
test_trial_ids  = u_trials(perm(n_train_trials+1:end));

is_train = ismember(trial, train_trial_ids);
is_test  = ismember(trial, test_trial_ids);

if ~any(is_test)
    error('No test rows after train/test split. Try a different split or more trials.');
end

X_train = X(is_train, :);
y_train = y(is_train);
trial_train = trial(is_train);

X_test = X(is_test, :);
y_test = y(is_test);
trial_test = trial(is_test);

% ------------------------------------------------------------
% 4. Standardize using training rows only
% ------------------------------------------------------------
if do_standardize
    mu = mean(X_train, 1, 'omitnan');
    sigma = std(X_train, 0, 1, 'omitnan');
    sigma(sigma == 0 | isnan(sigma)) = 1;

    X_train_z = (X_train - mu) ./ sigma;
    X_test_z  = (X_test  - mu) ./ sigma;
else
    mu = zeros(1, size(X_train,2));
    sigma = ones(1, size(X_train,2));
    X_train_z = X_train;
    X_test_z = X_test;
end

% ------------------------------------------------------------
% 5. Determine lambda strategy
% ------------------------------------------------------------
if isempty(lambda_user)
    % automatic lambda path
    [~, FitInfo0] = lassoglm(X_train_z, y_train, 'poisson', ...
        'Alpha', alpha, ...
        'NumLambda', n_lambda, ...
        'Standardize', false);
    lambda_seq = FitInfo0.Lambda;
    lambda_mode = 'auto_path';

elseif isscalar(lambda_user)
    % fixed lambda, no CV
    lambda_seq = lambda_user;
    lambda_mode = 'fixed';

else
    % user-specified lambda path, still do CV
    lambda_seq = lambda_user(:)';
    lambda_mode = 'user_path';
end

if verbose
    fprintf('[fit_glm] Lambda mode: %s\n', lambda_mode);
    fprintf('[fit_glm] Lambda path length: %d\n', numel(lambda_seq));
end

% ------------------------------------------------------------
% 6. Inner CV on training trials only (if needed)
% ------------------------------------------------------------
if strcmp(lambda_mode, 'fixed')
    lambda_best = lambda_seq(1);
    cv_score = NaN;
    mean_cv_score = NaN;
    best_cv_score = NaN;

    if verbose
        fprintf('[fit_glm] Using fixed lambda = %.6g (inner CV skipped)\n', lambda_best);
    end

else
    u_train_trials = unique(trial_train, 'stable');
    n_train_unique = numel(u_train_trials);

    if n_train_unique < n_inner_folds
        n_inner_folds = n_train_unique;
        if verbose
            fprintf('[fit_glm] Reducing inner folds to %d due to limited trial count.\n', n_inner_folds);
        end
    end

    fold_ids = local_make_trial_folds(u_train_trials, n_inner_folds);
    cv_score = nan(numel(lambda_seq), n_inner_folds);

    for f = 1:n_inner_folds
        val_trials = u_train_trials(fold_ids == f);
        tr_trials  = u_train_trials(fold_ids ~= f);

        row_tr = ismember(trial_train, tr_trials);
        row_va = ismember(trial_train, val_trials);

        X_tr = X_train_z(row_tr, :);
        y_tr = y_train(row_tr);

        X_va = X_train_z(row_va, :);
        y_va = y_train(row_va);

        [B_cv, FitInfo_cv] = lassoglm(X_tr, y_tr, 'poisson', ...
            'Alpha', alpha, ...
            'Lambda', lambda_seq, ...
            'Standardize', false);

        for k = 1:numel(lambda_seq)
            eta_va = X_va * B_cv(:,k) + FitInfo_cv.Intercept(k);
            mu_va = exp(eta_va);
            mu_va = max(mu_va, eps);

            mu_null = mean(y_tr);
            mu_null = max(mu_null, eps);

            cv_score(k, f) = Kin.compute_poisson_pseudoR2(y_va, mu_va, mu_null);
        end
    end

    mean_cv_score = mean(cv_score, 2, 'omitnan');
    [best_cv_score, best_idx] = max(mean_cv_score);
    lambda_best = lambda_seq(best_idx);

    if verbose
        fprintf('[fit_glm] Best lambda = %.6g, inner-CV pseudo-R2 = %.4f\n', ...
            lambda_best, best_cv_score);
    end
end

% ------------------------------------------------------------
% 7. Refit on all training rows using chosen lambda
% ------------------------------------------------------------
[B_final, FitInfo_final] = lassoglm(X_train_z, y_train, 'poisson', ...
    'Alpha', alpha, ...
    'Lambda', lambda_best, ...
    'Standardize', false);

beta = B_final(:,1);
intercept = FitInfo_final.Intercept(1);

eta_train = X_train_z * beta + intercept;
eta_train = min(max(eta_train, -7), 7);
mu_train = exp(eta_train);
mu_train = max(mu_train, eps);

eta_test = X_test_z * beta + intercept;
eta_test = min(max(eta_test, -7), 7);
mu_test = exp(eta_test);
mu_test = max(mu_test, eps);

% ------------------------------------------------------------
% 8. Evaluate pseudo-R2
% ------------------------------------------------------------
mu_null_train = max(mean(y_train), eps);

pR2_train = Kin.compute_poisson_pseudoR2(y_train, mu_train, mu_null_train);
pR2_test  = Kin.compute_poisson_pseudoR2(y_test,  mu_test,  mu_null_train);

LL_train = local_poisson_loglik(y_train, mu_train);
LL_test  = local_poisson_loglik(y_test,  mu_test);
% ------------------------------------------------------------
% 9. Pack result
% ------------------------------------------------------------
result = struct();

result.feature_names = feature_mat.feature_names;
result.lambda_best = lambda_best;
result.lambda_seq = lambda_seq;

result.lambda_mode = lambda_mode;
result.lambda_user = lambda_user;

result.alpha = alpha;

result.cv_score = cv_score;
result.mean_cv_score = mean_cv_score;
result.best_cv_score = best_cv_score;

result.intercept = intercept;
result.beta = beta;

result.mu_train = mu_train;
result.mu_test = mu_test;
result.y_train = y_train;
result.y_test = y_test;

result.pR2_train = pR2_train;
result.pR2_test = pR2_test;
result.LL_train = LL_train;
result.LL_test = LL_test;

result.is_train_valid = is_train;
result.is_test_valid = is_test;

result.trial_train = trial_train;
result.trial_test = trial_test;
result.time_bin_start_train = t0(is_train);
result.time_bin_end_train   = t1(is_train);
result.time_bin_start_test  = t0(is_test);
result.time_bin_end_test    = t1(is_test);

result.time_bin_center_train = (result.time_bin_start_train + result.time_bin_end_train)/2;
result.time_bin_center_test  = (result.time_bin_start_test  + result.time_bin_end_test)/2;

binw_train = result.time_bin_end_train - result.time_bin_start_train;
binw_test  = result.time_bin_end_test  - result.time_bin_start_test;

result.y_rate_train = result.y_train ./ binw_train;
result.y_rate_test  = result.y_test  ./ binw_test;

result.mu_rate_train = result.mu_train ./ binw_train;
result.mu_rate_test  = result.mu_test  ./ binw_test;

result.y_rate_test_hz  = result.y_test ./ binw_test * 1000;
result.mu_rate_test_hz = result.mu_test ./ binw_test * 1000;

result.spike_times_test_by_bin = get_spike_times_by_bin( ...
    spike_times, result.time_bin_start_test, result.time_bin_end_test);

result.valid_rows_global = use_rows;
result.train_trial_ids = train_trial_ids;
result.test_trial_ids = test_trial_ids;

result.X_mean = mu;
result.X_std = sigma;

result.FitInfo_final = FitInfo_final;
result.beta_table = make_glm_beta_table(result);

result.did_fit = true;
result.skip_reason = "";
result.n_spikes_used = n_spikes_used;
result.min_spikes_to_fit = min_spikes_to_fit;

result.train_trials = local_group_prediction_by_trial( ...
    trial_train, ...
    result.time_bin_start_train, ...
    result.time_bin_end_train, ...
    y_train, ...
    mu_train, ...
    spike_times);

result.test_trials = local_group_prediction_by_trial( ...
    trial_test, ...
    result.time_bin_start_test, ...
    result.time_bin_end_test, ...
    y_test, ...
    mu_test, ...
    spike_times);

result.unit_id = unit_id;

end


% ============================================================
% Helpers
% ============================================================

function y = local_bin_spike_counts(spike_times, bin_start, bin_end)
n = numel(bin_start);
y = zeros(n,1);
spike_times = spike_times(:);

for i = 1:n
    y(i) = sum(spike_times >= bin_start(i) & spike_times < bin_end(i));
end
end

function fold_ids = local_make_trial_folds(u_trials, K)
n = numel(u_trials);
perm = randperm(n);
fold_ids = zeros(n,1);
for i = 1:n
    fold_ids(perm(i)) = mod(i-1, K) + 1;
end
end

function ll = local_poisson_loglik(y, mu)
y = y(:);
mu = mu(:);

mu(~isfinite(mu)) = 1e6;
mu = min(max(mu, eps), 1e6);

ll = sum(y .* log(mu) - mu - gammaln(y + 1));
end


function beta_tbl = make_glm_beta_table(result)

feature_name = string(result.feature_names(:));
beta = result.beta(:);
abs_beta = abs(beta);

body_part = strings(size(feature_name));
signal = strings(size(feature_name));
lag = nan(size(beta));

for i = 1:numel(feature_name)
    s = feature_name(i);

    if contains(s, "LeftPaw")
        body_part(i) = "LeftPaw";
    elseif contains(s, "RightPaw")
        body_part(i) = "RightPaw";
    elseif contains(s, "LeftEar")
        body_part(i) = "LeftEar";
    elseif contains(s, "RightEar")
        body_part(i) = "RightEar";
    end

    if contains(s, "_x_rel_cm_")
        signal(i) = "x";
    elseif contains(s, "_y_rel_cm_")
        signal(i) = "y";
    elseif contains(s, "_vx_cm_s_")
        signal(i) = "vx";
    elseif contains(s, "_vy_cm_s_")
        signal(i) = "vy";
    end

    tok = regexp(s, 'lag_(m\d+|p\d+|0)$', 'tokens', 'once');
    if ~isempty(tok)
        t = string(tok{1});
        if t == "0"
            lag(i) = 0;
        elseif startsWith(t, "m")
            lag(i) = -str2double(extractAfter(t,1));
        elseif startsWith(t, "p")
            lag(i) = str2double(extractAfter(t,1));
        end
    end
end

beta_tbl = table(feature_name, body_part, signal, lag, beta, abs_beta);
beta_tbl = sortrows(beta_tbl, 'body_part', 'descend');
end

function spike_times_by_bin = get_spike_times_by_bin(spike_times, bin_start, bin_end)
n = numel(bin_start);
spike_times_by_bin = cell(n,1);

for i = 1:n
    spike_times_by_bin{i} = spike_times(spike_times >= bin_start(i) & spike_times < bin_end(i));
end
end

function trial_struct = local_group_prediction_by_trial(trial_id, t0, t1, y, mu, spike_times)

u = unique(trial_id, 'stable');
n = numel(u);

trial_struct = repmat(struct( ...
    'trial', "", ...
    'press_time', NaN, ...
    'time_bin_start', [], ...
    'time_bin_end', [], ...
    'time_bin_center', [], ...
    'y', [], ...
    'mu', [], ...
    'y_rate', [], ...
    'mu_rate', [], ...
    'y_rate_hz', [], ...
    'mu_rate_hz', [], ...
    'spike_times_ms', [], ...
    'spike_times_rel_ms', [], ...
    'spike_times_rel_s', []), n, 1);

for i = 1:n
    m = (trial_id == u(i));

    tb0 = t0(m);
    tb1 = t1(m);
    bw = tb1 - tb0;

    % infer press time from trial name
    tok = regexp(u(i), '^(?:Side|Top)_Press_(\d+)$', 'tokens', 'once');
    if ~isempty(tok)
        press_time = str2double(tok{1});
    else
        press_time = NaN;
    end

    % spikes within this trial window
    spk = spike_times(spike_times >= min(tb0) & spike_times < max(tb1));

    trial_struct(i).trial = u(i);
    trial_struct(i).press_time = press_time;
    trial_struct(i).time_bin_start = tb0;
    trial_struct(i).time_bin_end = tb1;
    trial_struct(i).time_bin_center = (tb0 + tb1) / 2;
    trial_struct(i).y = y(m);
    trial_struct(i).mu = mu(m);

    trial_struct(i).y_rate = y(m) ./ bw;
    trial_struct(i).mu_rate = mu(m) ./ bw;

    trial_struct(i).y_rate_hz = y(m) ./ bw * 1000;
    trial_struct(i).mu_rate_hz = mu(m) ./ bw * 1000;

    trial_struct(i).spike_times_ms = spk;

    if ~isnan(press_time)
        trial_struct(i).spike_times_rel_ms = spk - press_time;
        trial_struct(i).spike_times_rel_s = (spk - press_time) / 1000;
    else
        trial_struct(i).spike_times_rel_ms = [];
        trial_struct(i).spike_times_rel_s = [];
    end
end
end

function result = local_make_low_spike_result(feature_mat, spike_times, use_rows, y, trial, t0, t1, n_spikes_used, min_spikes_to_fit)

result = struct();

result.did_fit = false;
result.skip_reason = "too_few_spikes";
result.n_spikes_used = n_spikes_used;
result.min_spikes_to_fit = min_spikes_to_fit;

result.feature_names = feature_mat.feature_names;
result.lambda_best = NaN;
result.lambda_seq = [];

result.lambda_mode = "not_fit";
result.lambda_user = [];

result.alpha = NaN;

result.cv_score = NaN;
result.mean_cv_score = NaN;
result.best_cv_score = NaN;

result.intercept = NaN;
result.beta = nan(numel(feature_mat.feature_names), 1);

result.mu_train = [];
result.mu_test = [];
result.y_train = [];
result.y_test = [];

result.pR2_train = NaN;
result.pR2_test = NaN;
result.LL_train = NaN;
result.LL_test = NaN;

result.is_train_valid = false(size(y));
result.is_test_valid = false(size(y));

result.trial_train = strings(0,1);
result.trial_test = strings(0,1);
result.time_bin_start_train = [];
result.time_bin_end_train   = [];
result.time_bin_start_test  = [];
result.time_bin_end_test    = [];

result.time_bin_center_train = [];
result.time_bin_center_test  = [];

result.y_rate_train = [];
result.y_rate_test  = [];

result.mu_rate_train = [];
result.mu_rate_test  = [];

result.y_rate_test_hz  = [];
result.mu_rate_test_hz = [];

result.spike_times_test_by_bin = {};

result.valid_rows_global = use_rows;
result.train_trial_ids = strings(0,1);
result.test_trial_ids = strings(0,1);

result.X_mean = nan(1, size(feature_mat.X,2));
result.X_std = nan(1, size(feature_mat.X,2));

result.FitInfo_final = [];
result.beta_table = make_glm_beta_table(result);

result.train_trials = struct([]);
result.test_trials = struct([]);

% optional useful bookkeeping
result.trial_all = trial;
result.time_bin_start_all = t0;
result.time_bin_end_all = t1;
result.y_all_valid = y;
result.spike_times = spike_times;
end