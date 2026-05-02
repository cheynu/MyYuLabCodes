function feature_mat = make_glm_feature_matrix_by_trial(T, feature_vars, lags, trial_var, varargin)
%MAKE_GLM_FEATURE_MATRIX_BY_TRIAL
% Build lagged feature matrix within each trial separately, while keeping
% row-level metadata aligned with X.
%
% Required inputs
%   T            table
%   feature_vars cell array or string array of full variable names in T
%   lags         integer vector, e.g. -4:4
%   trial_var    name of trial-id column in T, e.g. 'trial'
%
% Name-value options
%   'TimeStartVar'     default 'time_bin_start'
%   'TimeEndVar'       default 'time_bin_end'
%   'SessionVar'       default 'anm_session'
%   'DropNaNRows'      default true
%   'RequireColumns'   default true
%   'ReturnXTable'     default false
%   'Verbose'          default true
%
% Output
%   feature_mat struct with fields:
%       .X
%       .feature_names
%       .valid_rows
%       .time_bin_start
%       .time_bin_end
%       .anm_session
%       .trial
%       .meta
%
% Lag convention
%   X(t,j) = source(t + lag) within the same trial only.
%   positive lag -> future kinematics relative to row t
%   negative lag -> past kinematics relative to row t

% -------------------- parse inputs --------------------
p = inputParser;
p.addRequired('T', @(x) istable(x));
p.addRequired('feature_vars', @(x) iscell(x) || isstring(x));
p.addRequired('lags', @(x) isnumeric(x) && isvector(x) && all(isfinite(x)) ...
    && all(abs(x - round(x)) < eps));
p.addRequired('trial_var', @(x) ischar(x) || isstring(x));

p.addParameter('TimeStartVar', 'time_bin_start', @(x) ischar(x) || isstring(x));
p.addParameter('TimeEndVar',   'time_bin_end',   @(x) ischar(x) || isstring(x));
p.addParameter('SessionVar',   'anm_session',    @(x) ischar(x) || isstring(x));
p.addParameter('DropNaNRows',  true,  @(x) islogical(x) && isscalar(x));
p.addParameter('RequireColumns', true, @(x) islogical(x) && isscalar(x));
p.addParameter('ReturnXTable', false, @(x) islogical(x) && isscalar(x));
p.addParameter('Verbose', true, @(x) islogical(x) && isscalar(x));

p.parse(T, feature_vars, lags, trial_var, varargin{:});

feature_vars   = cellstr(string(feature_vars(:)));
lags           = double(lags(:)');
trial_var      = char(string(trial_var));
time_start_var = char(string(p.Results.TimeStartVar));
time_end_var   = char(string(p.Results.TimeEndVar));
session_var    = char(string(p.Results.SessionVar));
drop_nan_rows  = p.Results.DropNaNRows;
require_cols   = p.Results.RequireColumns;
return_xtable  = p.Results.ReturnXTable;
verbose        = p.Results.Verbose;

n_rows = height(T);

% -------------------- required row-level columns --------------------
required_row_vars = {trial_var, time_start_var, time_end_var, session_var};
missing_row_vars = required_row_vars(~ismember(required_row_vars, T.Properties.VariableNames));
if ~isempty(missing_row_vars)
    error('make_glm_feature_matrix_by_trial:MissingRowVars', ...
        'Missing required row-level column(s): %s', strjoin(missing_row_vars, ', '));
end

% -------------------- check feature columns --------------------
has_col = ismember(feature_vars, T.Properties.VariableNames);
if ~all(has_col)
    missing = feature_vars(~has_col);
    if require_cols
        error('make_glm_feature_matrix_by_trial:MissingFeatureColumns', ...
            'Missing feature column(s): %s', strjoin(missing, ', '));
    else
        feature_vars = feature_vars(has_col);
    end
end

if isempty(feature_vars)
    error('make_glm_feature_matrix_by_trial:NoFeatures', ...
        'No usable feature columns found.');
end

for i = 1:numel(feature_vars)
    if ~isnumeric(T.(feature_vars{i}))
        error('make_glm_feature_matrix_by_trial:NonNumericFeature', ...
            'Feature column must be numeric: %s', feature_vars{i});
    end
end

% -------------------- build feature spec --------------------
feature_specs = struct('base_col', {}, 'lag', {}, 'feature_name', {});
for i = 1:numel(feature_vars)
    base_col = feature_vars{i};
    for j = 1:numel(lags)
        ell = lags(j);
        feature_specs(end+1).base_col = base_col; %#ok<AGROW>
        feature_specs(end).lag = ell;
        feature_specs(end).feature_name = sprintf('%s_lag_%s', base_col, local_lag_tag(ell));
    end
end

n_features = numel(feature_specs);
X = nan(n_rows, n_features);
feature_names = {feature_specs.feature_name};

% -------------------- trial labels --------------------
trial = T.(trial_var);
trial_key = local_to_group_key(trial);
[trial_groups, ~, group_idx] = unique(trial_key, 'stable');
n_trials = numel(trial_groups);

% -------------------- build X within each trial --------------------
for g = 1:n_trials
    rows = find(group_idx == g);

    for j = 1:n_features
        base_col = feature_specs(j).base_col;
        ell = feature_specs(j).lag;
        x_trial = T.(base_col)(rows);
        X(rows, j) = local_shift_vector(x_trial, ell);
    end
end

% -------------------- valid rows --------------------
row_keep = true(n_rows, 1);

if drop_nan_rows
    row_keep = row_keep & all(~isnan(X), 2);
end

% -------------------- row-level aligned metadata --------------------
time_bin_start = T.(time_start_var);
time_bin_end   = T.(time_end_var);

% session as row-aligned vector
anm_session = T.(session_var){1};

% -------------------- meta --------------------
meta = struct();
meta.feature_vars = feature_vars(:)';
meta.lags = lags;
meta.trial_var = trial_var;
meta.time_start_var = time_start_var;
meta.time_end_var = time_end_var;
meta.session_var = session_var;
meta.n_rows_original = n_rows;
meta.n_rows_kept = sum(row_keep);
meta.n_trials = n_trials;
meta.trial_groups = trial_groups;
meta.col_map = table( ...
    (1:n_features)', ...
    string(feature_names(:)), ...
    string({feature_specs.base_col})', ...
    [feature_specs.lag]', ...
    'VariableNames', {'col_idx','feature_name','base_column','lag'});

if return_xtable
    meta.X_table = array2table(X, ...
        'VariableNames', matlab.lang.makeValidName(feature_names));
end

% -------------------- final struct --------------------
feature_mat = struct();
feature_mat.X = X;
feature_mat.feature_names = feature_names;
feature_mat.valid_rows = row_keep;

feature_mat.time_bin_start = time_bin_start;
feature_mat.time_bin_end = time_bin_end;
feature_mat.anm_session = anm_session;
feature_mat.trial = trial;

feature_mat.meta = meta;

if verbose
    fprintf('[make_glm_feature_matrix_by_trial] Built %d features from %d base vars x %d lags.\n', ...
        n_features, numel(feature_vars), numel(lags));
    fprintf('[make_glm_feature_matrix_by_trial] Trials: %d\n', n_trials);
    fprintf('[make_glm_feature_matrix_by_trial] Rows kept: %d / %d\n', ...
        meta.n_rows_kept, meta.n_rows_original);
end

end

% ==================== helpers ====================

function y = local_shift_vector(x, lag)
% y(t) = x(t + lag), within one trial only
n = numel(x);
y = nan(size(x));

if lag == 0
    y = x;
elseif lag > 0
    if lag < n
        y(1:n-lag) = x(1+lag:n);
    end
else
    k = -lag;
    if k < n
        y(1+k:n) = x(1:n-k);
    end
end
end

function key = local_to_group_key(x)
if iscategorical(x)
    key = string(x);
elseif isstring(x)
    key = x;
elseif iscellstr(x)
    key = string(x);
elseif isnumeric(x) || islogical(x)
    key = x;
else
    try
        key = string(x);
    catch
        error('make_glm_feature_matrix_by_trial:BadTrialType', ...
            'Unsupported type for trial grouping.');
    end
end
end

function tag = local_lag_tag(lag)
if lag < 0
    tag = sprintf('m%d', abs(lag));
elseif lag > 0
    tag = sprintf('p%d', lag);
else
    tag = '0';
end
end