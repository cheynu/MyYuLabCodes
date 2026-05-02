function feature_mat = make_glm_feature_matrix(T, pos_specs, vel_vars, speed_vars, trial_var, basis, varargin)
%MAKE_GLM_FEATURE_MATRIX
% 4/2/2026 | make sure the "basis can also be bins from 
% bins = Kin.design_shared_xy_bin_set(B, S.x_cols, S.y_cols, S.valid_cols, ...
    % 'NumX', 10, 'NumY', 10, 'QuantileRange', [0 1]);"
% Build GLM feature matrix using shared 2D spatial basis activations for position,
% directional velocity components, and scalar speed terms.
%
% Supports:
%   - position only
%   - velocity only
%   - speed only
%   - any combination of the above
%
% Inputs
%   T          table
%   pos_specs  struct array with fields:
%                .prefix
%                .x_col
%                .y_col
%                .valid_col   (can be '')
%              Can be empty struct([]) if position terms are not used.
%   vel_vars   cell array / string array of directional velocity columns
%              Can be empty.
%   speed_vars cell array / string array of scalar speed columns
%              Can be empty.
%   trial_var  trial-id column name
%   basis      shared basis struct from design_shared_xy_basis_set
%
% Name-value
%   'TimeStartVar'   default 'time_bin_start'
%   'TimeEndVar'     default 'time_bin_end'
%   'SessionVar'     default 'anm_session'
%   'DropNaNRows'    default true
%   'Verbose'        default true
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

p = inputParser;
p.addRequired('T', @(x) istable(x));

% allow empty position specs
p.addRequired('pos_specs', @(x) isstruct(x));

% allow empty cell/string arrays
p.addRequired('vel_vars', @(x) iscell(x) || isstring(x));
p.addRequired('speed_vars', @(x) iscell(x) || isstring(x));

p.addRequired('trial_var', @(x) ischar(x) || isstring(x));
p.addRequired('basis', @(x) isstruct(x) && isfield(x, 'centers'));

p.addParameter('TimeStartVar', 'time_bin_start', @(x) ischar(x) || isstring(x));
p.addParameter('TimeEndVar',   'time_bin_end',   @(x) ischar(x) || isstring(x));
p.addParameter('SessionVar',   'anm_session',    @(x) ischar(x) || isstring(x));
p.addParameter('DropNaNRows',  true, @(x) islogical(x) && isscalar(x));
p.addParameter('Verbose',      true, @(x) islogical(x) && isscalar(x));
p.addParameter('PositionMode', 'basis', @(x) any(strcmpi(string(x), ["basis","bin"])));

p.parse(T, pos_specs, vel_vars, speed_vars, trial_var, basis, varargin{:});

vel_vars       = cellstr(string(vel_vars(:)));
speed_vars     = cellstr(string(speed_vars(:)));
trial_var      = char(string(trial_var));
time_start_var = char(string(p.Results.TimeStartVar));
time_end_var   = char(string(p.Results.TimeEndVar));
session_var    = char(string(p.Results.SessionVar));
drop_nan_rows  = p.Results.DropNaNRows;
verbose        = p.Results.Verbose;
position_mode = lower(string(p.Results.PositionMode));
n_rows = height(T);

% -------------------- normalize empty pos_specs --------------------
if isempty(pos_specs)
    pos_specs = struct('prefix', {}, 'x_col', {}, 'y_col', {}, 'valid_col', {});
end

% -------------------- sanity check: at least one feature block --------------------
if isempty(pos_specs) && isempty(vel_vars) && isempty(speed_vars)
    error('At least one of pos_specs, vel_vars, or speed_vars must be non-empty.');
end

% -------------------- check required row vars --------------------
required_row_vars = {trial_var, time_start_var, time_end_var, session_var};
missing_row_vars = required_row_vars(~ismember(required_row_vars, T.Properties.VariableNames));
if ~isempty(missing_row_vars)
    error('Missing required row-level column(s): %s', strjoin(missing_row_vars, ', '));
end

% -------------------- build feature blocks --------------------
X_parts = {};
name_parts = {};

% -------------------- position basis terms --------------------
for i = 1:numel(pos_specs)
    prefix = string(pos_specs(i).prefix);
    x_col = char(string(pos_specs(i).x_col));
    y_col = char(string(pos_specs(i).y_col));

    if isfield(pos_specs(i), 'valid_col')
        valid_col = char(string(pos_specs(i).valid_col));
    else
        valid_col = '';
    end

    if ~ismember(x_col, T.Properties.VariableNames)
        error('Missing position x column: %s', x_col);
    end
    if ~ismember(y_col, T.Properties.VariableNames)
        error('Missing position y column: %s', y_col);
    end
    if ~isempty(valid_col) && ~ismember(valid_col, T.Properties.VariableNames)
        error('Missing position valid column: %s', valid_col);
    end

    switch position_mode
    case "basis"
        [Phi, phi_names] = Kin.eval_xy_basis(T, x_col, y_col, valid_col, basis, prefix);

    case "bin"
        [Phi, phi_names] = Kin.eval_xy_bins(T, x_col, y_col, valid_col, basis, prefix);

    otherwise
        error('Unknown PositionMode: %s', position_mode);
    end


    X_parts{end+1} = Phi; %#ok<AGROW>
    name_parts{end+1} = cellstr(phi_names); %#ok<AGROW>
end

% -------------------- directional velocity terms --------------------
if ~isempty(vel_vars)
    X_vel = nan(n_rows, numel(vel_vars));
    for j = 1:numel(vel_vars)
        vcol = vel_vars{j};
        if ~ismember(vcol, T.Properties.VariableNames)
            error('Missing velocity column: %s', vcol);
        end
        X_vel(:, j) = T.(vcol);
    end

    X_parts{end+1} = X_vel; %#ok<AGROW>
    name_parts{end+1} = vel_vars; %#ok<AGROW>
end

% -------------------- scalar speed terms --------------------
if ~isempty(speed_vars)
    X_speed = nan(n_rows, numel(speed_vars));
    for j = 1:numel(speed_vars)
        scol = speed_vars{j};
        if ~ismember(scol, T.Properties.VariableNames)
            error('Missing speed column: %s', scol);
        end
        X_speed(:, j) = T.(scol);
    end

    X_parts{end+1} = X_speed; %#ok<AGROW>
    name_parts{end+1} = speed_vars; %#ok<AGROW>
end

% -------------------- concatenate --------------------
if isempty(X_parts)
    error('No feature blocks were constructed.');
end

X = cat(2, X_parts{:});
feature_names = vertcat(name_parts{:});
feature_names = cellstr(string(feature_names(:)));

% -------------------- valid rows --------------------
row_keep = true(n_rows, 1);

if drop_nan_rows
    row_keep = row_keep & all(isfinite(X), 2);
end

% -------------------- row-level metadata --------------------
time_bin_start = T.(time_start_var);
time_bin_end   = T.(time_end_var);
anm_session    = T.(session_var);
trial          = T.(trial_var);

% -------------------- meta --------------------
meta = struct();
meta.basis = basis;
meta.pos_specs = pos_specs;
meta.vel_vars = vel_vars;
meta.speed_vars = speed_vars;
meta.trial_var = trial_var;
meta.time_start_var = time_start_var;
meta.time_end_var = time_end_var;
meta.session_var = session_var;
meta.n_rows_original = n_rows;
meta.n_rows_kept = sum(row_keep);
meta.n_features = size(X,2);
meta.position_mode = position_mode;
meta.has_position = ~isempty(pos_specs);
meta.has_velocity = ~isempty(vel_vars);
meta.has_speed = ~isempty(speed_vars);

meta.col_map = table( ...
    (1:numel(feature_names))', ...
    string(feature_names(:)), ...
    'VariableNames', {'col_idx','feature_name'});

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
    fprintf('[make_glm_feature_matrix_spatial_basis] Built %d features.\n', size(X,2));
    fprintf('[make_glm_feature_matrix_spatial_basis] Position: %d | Velocity: %d | Speed: %d\n', ...
        meta.has_position, meta.has_velocity, meta.has_speed);
    fprintf('[make_glm_feature_matrix_spatial_basis] Rows kept: %d / %d\n', ...
        sum(row_keep), n_rows);
end
end