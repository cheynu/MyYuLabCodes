function [result_rep, result_summary] = fit_poisson_elasticnet_glm_repeated( ...
    feature_mat, spike_times, basis, body_parts, varargin)

%FIT_POISSON_ELASTICNET_GLM_REPEATED
% Repeated random outer train/test splits for Poisson elastic-net GLM.
%
% Inputs
%   feature_mat
%   spike_times
%   basis
%   body_parts   e.g. {'LeftPaw','LeftEar'}
%
% Name-value
%   'NumRepeats'   default 20
%   'BaseSeed'     default 1
%   plus any args passed to Kin.fit_poisson_elasticnet_glm_by_trial
%
% Outputs
%   result_rep      1 x n_repeats struct array
%   result_summary  summary struct

p = inputParser;
p.addRequired('feature_mat', @isstruct);
p.addRequired('spike_times', @(x) isnumeric(x) && isvector(x));
p.addRequired('basis', @isstruct);
p.addRequired('body_parts', @(x) iscell(x) || isstring(x));

p.addParameter('NumRepeats', 20, @(x) isnumeric(x) && isscalar(x) && x >= 2);
p.addParameter('BaseSeed', 1, @(x) isnumeric(x) && isscalar(x));
p.addParameter('ShowProgress', false, @(x) islogical(x) && isscalar(x));
p.addParameter('MinSpikesToFit', 100, @(x) isnumeric(x) && isscalar(x) && x >= 0);

% parse known args, leave rest to downstream fit function
p.KeepUnmatched = true;
p.parse(feature_mat, spike_times, basis, body_parts, varargin{:});

n_repeats = p.Results.NumRepeats;
base_seed = p.Results.BaseSeed;
body_parts = cellstr(string(body_parts(:)));
show_progress = p.Results.ShowProgress;

extra_args = namedargs2cell(p.Unmatched);

result_rep = [];   % <-- key change

position_mode = "basis";
has_position = false;

if isfield(feature_mat, 'meta')
    if isfield(feature_mat.meta, 'position_mode')
        position_mode = lower(string(feature_mat.meta.position_mode));
    end
    if isfield(feature_mat.meta, 'has_position')
        has_position = logical(feature_mat.meta.has_position);
    end
end


% ---------------- progress bar ----------------
wb = [];
if show_progress
    wb = waitbar(0, sprintf('Running split 0 / %d', n_repeats), ...
        'Name', 'Repeated GLM fitting');
end

for r = 1:n_repeats
    if show_progress && ~isempty(wb) && isgraphics(wb)
        waitbar((r-1)/n_repeats, wb, sprintf('Running split %d / %d', r, n_repeats));
    end
    seed_r = base_seed + r - 1;

    result_rep_ = Kin.fit_poisson_elasticnet_glm_by_trial( ...
        feature_mat, spike_times, ...
        'Seed', seed_r, ...
        'MinSpikesToFit', p.Results.MinSpikesToFit,...
        extra_args{:});

    % spatial field / map for each body part
    if ~result_rep_.did_fit
        for b = 1:numel(body_parts)
            bp = body_parts{b};
            if ~has_position
                result_rep_.field.(bp) = local_make_empty_field_struct();
                continue
            end
            switch position_mode
                case "basis"
                    result_rep_.field.(bp) = Kin.reconstruct_spatial_tuning_field( ...
                        result_rep_, basis, bp);

                case "bin"
                    result_rep_.field.(bp) = Kin.extract_spatial_bin_field( ...
                        result_rep_, basis, bp);

                otherwise
                    error('Unknown position_mode: %s', position_mode);
            end
        end
    end

    result_keep = local_reduce_result_struct(result_rep_, body_parts);

    if r == 1
        result_rep = result_keep;   % initialize struct array properly
    else
        result_rep(r) = result_keep;
    end

    if show_progress && ~isempty(wb) && isgraphics(wb)
        waitbar(r/n_repeats, wb, sprintf('Finished split %d / %d', r, n_repeats));
    end
end
if show_progress && ~isempty(wb) && isgraphics(wb)
    close(wb);
end
% ---------------- summarize scalars ----------------
pR2_test_all = [result_rep.pR2_test];
pR2_train_all = [result_rep.pR2_train];
lambda_all = [result_rep.lambda_best];

result_summary = struct();
result_summary.n_repeats = n_repeats;

result_summary.pR2_test_all = pR2_test_all;
result_summary.pR2_test_mean = mean(pR2_test_all, 'omitnan');
result_summary.pR2_test_std = std(pR2_test_all, 0, 'omitnan');
result_summary.pR2_test_sem = result_summary.pR2_test_std / sqrt(sum(~isnan(pR2_test_all)));

result_summary.pR2_test_median = median(pR2_test_all, 'omitnan');
result_summary.pR2_test_min = min(pR2_test_all, [], 'omitnan');
result_summary.pR2_test_max = max(pR2_test_all, [], 'omitnan');

result_summary.pR2_train_all = pR2_train_all;
result_summary.pR2_train_mean = mean(pR2_train_all, 'omitnan');
result_summary.pR2_train_std = std(pR2_train_all, 0, 'omitnan');

result_summary.lambda_best_all = lambda_all;
result_summary.lambda_best_mean = mean(lambda_all, 'omitnan');
result_summary.lambda_best_std = std(lambda_all, 0, 'omitnan');

% ---------------- summarize beta ----------------
B = cat(2, result_rep.beta);   % [n_features x n_repeats]
idx_valid = find(arrayfun(@(r) ~isempty(r.feature_names), result_rep), 1);
if ~isempty(idx_valid)
    result_summary.feature_names = result_rep(idx_valid).feature_names;
else
    result_summary.feature_names = {};
end
result_summary.beta_mean = mean(B, 2, 'omitnan');
result_summary.beta_std = std(B, 0, 2, 'omitnan');
result_summary.beta_nonzero_frac = mean(B ~= 0, 2);

% ---------------- summarize fields ----------------
for b = 1:numel(body_parts)
    bp = body_parts{b};

    has_F = arrayfun(@(r) isfield(r.field, bp) && ~isempty(r.field.(bp).F), result_rep);
    if ~any(has_F)
        result_summary.field.(bp) = local_make_empty_field_struct();
        continue
    end

    first_idx = find(has_F, 1, 'first');
    F0 = result_rep(first_idx).field.(bp).F;

    Fstack = nan([size(F0), n_repeats]);
    for r = 1:n_repeats
        if isfield(result_rep(r).field, bp) && ~isempty(result_rep(r).field.(bp).F)
            Fstack(:,:,r) = result_rep(r).field.(bp).F;
        end
    end

    fld = result_rep(first_idx).field.(bp);

    result_summary.field.(bp).xq = local_getfield_safe(fld, 'xq', []);
    result_summary.field.(bp).yq = local_getfield_safe(fld, 'yq', []);
    result_summary.field.(bp).Xq = local_getfield_safe(fld, 'Xq', []);
    result_summary.field.(bp).Yq = local_getfield_safe(fld, 'Yq', []);
    result_summary.field.(bp).mode = local_getfield_safe(fld, 'mode', "");


    result_summary.field.(bp).F_mean = mean(Fstack, 3, 'omitnan');
    result_summary.field.(bp).F_std = std(Fstack, 0, 3, 'omitnan');
end

% ---------------- summarize velocity betas ----------------
if isfield(result_rep(1), 'beta_table')
    beta_tables = {result_rep.beta_table};
    result_summary.velocity_beta = local_collect_velocity_summary(beta_tables, body_parts);
end
end

function S = local_collect_velocity_summary(beta_tables, body_parts)

S = struct();

for b = 1:numel(body_parts)
    bp = body_parts{b};

    vx_name = sprintf('%s_vx_cm_s', bp);
    vy_name = sprintf('%s_vy_cm_s', bp);
    sp_name = sprintf('%s_speed_cm_s', bp);

    vx = nan(1, numel(beta_tables));
    vy = nan(1, numel(beta_tables));
    sp = nan(1, numel(beta_tables));

    for r = 1:numel(beta_tables)
        T = beta_tables{r};
        vx(r) = local_extract_beta_from_table(T, vx_name);
        vy(r) = local_extract_beta_from_table(T, vy_name);
        sp(r) = local_extract_beta_from_table(T, sp_name);
    end

    S.(bp).vx_all = vx;
    S.(bp).vx_mean = mean(vx, 'omitnan');
    S.(bp).vx_std = std(vx, 0, 'omitnan');
    S.(bp).vx_nonzero_frac = mean(vx ~= 0, 'omitnan');

    S.(bp).vy_all = vy;
    S.(bp).vy_mean = mean(vy, 'omitnan');
    S.(bp).vy_std = std(vy, 0, 'omitnan');
    S.(bp).vy_nonzero_frac = mean(vy ~= 0, 'omitnan');

    S.(bp).speed_all = sp;
    S.(bp).speed_mean = mean(sp, 'omitnan');
    S.(bp).speed_std = std(sp, 0, 'omitnan');
    S.(bp).speed_nonzero_frac = mean(sp ~= 0, 'omitnan');
end
end

function b = local_extract_beta_from_table(T, feature_name)
idx = find(string(T.feature_name) == string(feature_name), 1);
if isempty(idx)
    b = NaN;
else
    b = T.beta(idx);
end
end

function S = local_reduce_result_struct(R, body_parts)
% Keep only repeat-stable fields for repeated-fit storage.

S = struct();

% scalar summaries
S.unit_id = local_getfield_safe(R, 'unit_id', "");
S.lambda_best = local_getfield_safe(R, 'lambda_best', NaN);
S.pR2_train = local_getfield_safe(R, 'pR2_train', NaN);
S.pR2_test = local_getfield_safe(R, 'pR2_test', NaN);
S.intercept = local_getfield_safe(R, 'intercept', NaN);

% arrays that should be stable across repeats
S.beta = local_getfield_safe(R, 'beta', []);
S.feature_names = local_getfield_safe(R, 'feature_names', {});
S.beta_table = local_getfield_safe(R, 'beta_table', table());

% optional fit diagnostics
S.best_cv_score = local_getfield_safe(R, 'best_cv_score', NaN);
S.lambda_mode = local_getfield_safe(R, 'lambda_mode', "");
S.lambda_seq = local_getfield_safe(R, 'lambda_seq', []);

% train/test trial IDs if useful
S.train_trial_ids = local_getfield_safe(R, 'train_trial_ids', strings(0,1));
S.test_trial_ids = local_getfield_safe(R, 'test_trial_ids', strings(0,1));

S.y_test = local_getfield_safe(R, 'y_test', []);
S.mu_test = local_getfield_safe(R, 'mu_test', []);
S.LL_test = local_getfield_safe(R, 'LL_test', NaN);
S.LL_train = local_getfield_safe(R, 'LL_train', NaN);

S.y_train = local_getfield_safe(R, 'y_train', []);
S.mu_train = local_getfield_safe(R, 'mu_train', []);

% reconstructed fields
S.field = struct();
for b = 1:numel(body_parts)
    bp = body_parts{b};
    if isfield(R, 'field') && isfield(R.field, bp)
       S.field.(bp) = local_force_field_struct(R.field.(bp));
    else
        % force identical nested structure
        S.field.(bp) = struct( ...
            'xq', [], ...
            'yq', [], ...
            'Xq', [], ...
            'Yq', [], ...
            'F', [], ...
            'beta_basis', [], ...
            'beta_bin', [], ...
            'mode', "");
    end
end
end

function F = local_force_field_struct(F)

template = struct( ...
    'xq', [], ...
    'yq', [], ...
    'Xq', [], ...
    'Yq', [], ...
    'F', [], ...
    'beta_basis', [], ...
    'beta_bin', [], ...
    'mode', "");

fn = fieldnames(template);

for i = 1:numel(fn)
    if ~isfield(F, fn{i})
        F.(fn{i}) = template.(fn{i});
    end
end

end

function val = local_getfield_safe(S, fname, default_val)
if isfield(S, fname)
    val = S.(fname);
else
    val = default_val;
end
end

function S = local_make_empty_field_struct()

S = struct( ...
    'xq', [], ...
    'yq', [], ...
    'Xq', [], ...
    'Yq', [], ...
    'F', [], ...
    'beta_basis', [], ...
    'beta_bin', [], ...
    'mode', "");

end