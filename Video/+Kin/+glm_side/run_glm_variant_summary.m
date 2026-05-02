function [result_summary, meta, result_rep] = run_glm_variant_summary( ...
    B, basis, spike_times_ms, lambda_fixed, varargin)
%RUN_GLM_VARIANT_SUMMARY
% Build a feature matrix for a requested model variant, optionally shift
% spike times, and run repeated fixed-lambda GLM fitting.
%
% Example:
%   [result_summary, meta] = run_glm_variant_summary( ...
%       B, basis, spike_times_ms, lambda_fixed, ...
%       'BodyParts', {'LeftPaw','LeftEar'}, ...
%       'UsePosition', true, ...
%       'UseVelocity', true, ...
%       'UseSpeed', true, ...
%       'LagMs', 0, ...
%       'NumRepeats', 20);

p = inputParser;
p.addRequired('B', @(x) istable(x) && height(x) > 0);
p.addRequired('basis', @(x) isstruct(x) && isfield(x, 'centers'));
p.addRequired('spike_times_ms', @(x) isnumeric(x) && isvector(x));
p.addRequired('lambda_fixed', @(x) isnumeric(x) && isscalar(x) && x >= 0);

p.addParameter('BodyParts', {'LeftPaw','LeftEar'}, @(x) iscell(x) || isstring(x));
p.addParameter('UsePosition', true, @(x) islogical(x) && isscalar(x));
p.addParameter('UseVelocity', true, @(x) islogical(x) && isscalar(x));
p.addParameter('UseSpeed', true, @(x) islogical(x) && isscalar(x));
p.addParameter('LagMs', 0, @(x) isnumeric(x) && isscalar(x));

p.addParameter('TrainFrac', 0.75, @(x) isnumeric(x) && isscalar(x) && x > 0 && x < 1);
p.addParameter('Alpha', 0.9, @(x) isnumeric(x) && isscalar(x) && x >= 0 && x <= 1);
p.addParameter('NumInnerFolds', 5, @(x) isnumeric(x) && isscalar(x) && x >= 2);
p.addParameter('NumLambda', 50, @(x) isnumeric(x) && isscalar(x) && x >= 5);
p.addParameter('NumRepeats', 20, @(x) isnumeric(x) && isscalar(x) && x >= 1);
p.addParameter('BaseSeed', 101, @(x) isnumeric(x) && isscalar(x));
p.addParameter('ShowProgress', false, @(x) islogical(x) && isscalar(x));
p.addParameter('Standardize', true, @(x) islogical(x) && isscalar(x));
p.addParameter('Verbose', false, @(x) islogical(x) && isscalar(x));
p.addParameter('ReturnResultRep', false, @(x) islogical(x) && isscalar(x));
p.addParameter('UnitID', false, @(x) isscalar(x) || isstring(x));
p.addParameter('MinSpikesToFit', 100, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.addParameter('PositionMode', 'basis', @(x) any(strcmpi(string(x), ["basis","bin"])));

p.parse(B, basis, spike_times_ms, lambda_fixed, varargin{:});

body_parts   = cellstr(string(p.Results.BodyParts(:)));
use_position = p.Results.UsePosition;
use_velocity = p.Results.UseVelocity;
use_speed    = p.Results.UseSpeed;
lag_ms       = p.Results.LagMs;
unit_id      = p.Results.UnitID;

train_frac    = p.Results.TrainFrac;
alpha         = p.Results.Alpha;
n_inner_folds = p.Results.NumInnerFolds;
n_lambda      = p.Results.NumLambda;
n_repeats     = p.Results.NumRepeats;
base_seed     = p.Results.BaseSeed;
show_progress = p.Results.ShowProgress;
standardize   = p.Results.Standardize;
verbose       = p.Results.Verbose;
return_rep    = p.Results.ReturnResultRep;
position_mode = lower(string(p.Results.PositionMode));
if ~use_position && ~use_velocity && ~use_speed
    error('At least one of UsePosition / UseVelocity / UseSpeed must be true.');
end

if use_speed && ~use_velocity
    warning('UseSpeed is true while UseVelocity is false. This is allowed, but check if this is intended.');
end

% ------------------------------------------------------------
% 1. Build pos_specs / vel_vars / speed_vars for selected body parts
% ------------------------------------------------------------
pos_specs = struct('prefix', {}, 'x_col', {}, 'y_col', {}, 'valid_col', {});

vel_vars = {};
speed_vars = {};

for i = 1:numel(body_parts)
    bp = body_parts{i};

    switch bp
        case 'LeftPaw'
            if use_position
                pos_specs(end+1) = struct( ... %#ok<AGROW>
                    'prefix', 'LeftPaw', ...
                    'x_col', 'LeftPaw_x_rel_cm', ...
                    'y_col', 'LeftPaw_y_rel_cm', ...
                    'valid_col', 'valid_LeftPaw');
            end
            if use_velocity
                vel_vars = [vel_vars, {'LeftPaw_vx_cm_s', 'LeftPaw_vy_cm_s'}]; %#ok<AGROW>
            end
            if use_speed
                speed_vars = [speed_vars, {'LeftPaw_speed_cm_s'}]; %#ok<AGROW>
            end

          case 'RightPaw'
            if use_position
                pos_specs(end+1) = struct( ... %#ok<AGROW>
                    'prefix', 'RightPaw', ...
                    'x_col', 'RightPaw_x_rel_cm', ...
                    'y_col', 'RightPaw_y_rel_cm', ...
                    'valid_col', 'valid_RightPaw');
            end
            if use_velocity
                vel_vars = [vel_vars, {'RightPaw_vx_cm_s', 'RightPaw_vy_cm_s'}]; %#ok<AGROW>
            end
            if use_speed
                speed_vars = [speed_vars, {'RightPaw_speed_cm_s'}]; %#ok<AGROW>
            end    

        case 'LeftEar'
            if use_position
                pos_specs(end+1) = struct( ... %#ok<AGROW>
                    'prefix', 'LeftEar', ...
                    'x_col', 'LeftEar_x_rel_cm', ...
                    'y_col', 'LeftEar_y_rel_cm', ...
                    'valid_col', 'valid_LeftEar');
            end
            if use_velocity
                vel_vars = [vel_vars, {'LeftEar_vx_cm_s', 'LeftEar_vy_cm_s'}]; %#ok<AGROW>
            end
            if use_speed
                speed_vars = [speed_vars, {'LeftEar_speed_cm_s'}]; %#ok<AGROW>
            end

        otherwise
            error('Unsupported body part: %s', bp);
    end
end

% ------------------------------------------------------------
% 2. Make variant feature matrix
%    Assumes your feature builder can handle empty pos_specs / vel_vars / speed_vars
% ------------------------------------------------------------

feature_mat = Kin.make_glm_feature_matrix( ...
    B, pos_specs, vel_vars, speed_vars, 'trial', basis, ...
    'PositionMode', position_mode);


% ------------------------------------------------------------
% 3. Shift spike times (easy lag implementation)
% ------------------------------------------------------------
spike_times_shifted = spike_times_ms(:) + lag_ms;

% ------------------------------------------------------------
% 4. Run repeated fixed-lambda fitting
% ------------------------------------------------------------
[result_rep_local, result_summary] = Kin.fit_poisson_elasticnet_glm_repeated( ...
    feature_mat, ...
    spike_times_shifted, ...
    basis, ...
    body_parts, ...
    'NumRepeats', n_repeats, ...
    'BaseSeed', base_seed, ...
    'TrainFrac', train_frac, ...
    'Alpha', alpha, ...
    'NumInnerFolds', n_inner_folds, ...
    'NumLambda', n_lambda, ...
    'Lambda', lambda_fixed, ...
    'ShowProgress', show_progress, ...
    'Standardize', standardize, ...
    'Verbose', verbose,...
    'MinSpikesToFit', p.Results.MinSpikesToFit);

result_summary.unit_id = unit_id;

% ------------------------------------------------------------
% 5. Add metadata
% ------------------------------------------------------------
meta = struct();
meta.body_parts = body_parts;
meta.use_position = use_position;
meta.use_velocity = use_velocity;
meta.use_speed = use_speed;
meta.lag_ms = lag_ms;
meta.lambda_fixed = lambda_fixed;
meta.unit_id = unit_id;
meta.model_name = local_make_model_name(use_position, use_velocity, use_speed);
meta.bodypart_name = strjoin(body_parts, '_');

result_summary.meta = meta;

% ------------------------------------------------------------
% 6. Optional: drop result_rep to save memory
% ------------------------------------------------------------
if return_rep
    result_rep = result_rep_local;
else
    result_rep = [];
end

end

% ============================================================
% helpers
% ============================================================

function model_name = local_make_model_name(use_position, use_velocity, use_speed)

if use_position && ~use_velocity && ~use_speed
    model_name = 'position_only';
elseif ~use_position && use_velocity && ~use_speed
    model_name = 'velocity_only';
elseif ~use_position && use_velocity && use_speed
    model_name = 'velocity_plus_speed';
elseif use_position && use_velocity && ~use_speed
    model_name = 'position_plus_velocity';
elseif use_position && use_velocity && use_speed
    model_name = 'full';
elseif ~use_position && ~use_velocity && use_speed
    model_name = 'speed_only';
elseif use_position && ~use_velocity && use_speed
    model_name = 'position_plus_speed';
else
    model_name = 'unknown';
end

end