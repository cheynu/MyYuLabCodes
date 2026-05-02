function [result_summary, meta, result_rep] = run_topview_glm_variant_summary( ...
    B, basis, spike_times_ms, lambda_fixed, varargin)
%RUN_TOPVIEW_GLM_VARIANT_SUMMARY
% Build a top-view feature matrix for a requested model class, optionally
% shift spike times, and run repeated fixed-lambda GLM fitting.
%
% Model classes:
%   1) state  : head position basis + head direction
%   2) action : body-frame motion + angular velocity + scalar speed
%   3) full   : state + action
%
% Inputs
%   B              top-view bin table
%   basis          shared xy basis struct
%   spike_times_ms spike times in ms
%   lambda_fixed   lambda to use in repeated fits
%
% Name-value
%   'ModelClass'      one of {'state','action','full'}; default 'full'
%   'Phase'           '' (all rows), 'toLever', 'fromLever', or {'toLever','fromLever'}
%   'LagMs'           default 0
%   'TrainFrac'       default 0.75
%   'Alpha'           default 0.9
%   'NumInnerFolds'   default 5
%   'NumLambda'       default 50
%   'NumRepeats'      default 20
%   'BaseSeed'        default 101
%   'ShowProgress'    default false
%   'Standardize'     default true
%   'Verbose'         default false
%   'ReturnResultRep' default false
%   'UnitID'          default ""
%
% Notes
%   The feature grouping is:
%
%   state:
%       pos_specs   = head position basis
%       speed_vars  = head_theta_cos, head_theta_sin
%
%   action:
%       vel_vars    = forward_speed_cm_s, lateral_speed_cm_s, head_omega
%       speed_vars  = speed_cm_s
%
%   full:
%       state + action
%
%   Even though head_theta_cos/sin are passed through the 'speed_vars' slot,
%   they are conceptually orientation/state variables, not speed variables.

p = inputParser;
p.addRequired('B', @(x) istable(x) && height(x) > 0);
p.addRequired('basis', @(x) isstruct(x) && isfield(x, 'centers'));
p.addRequired('spike_times_ms', @(x) isnumeric(x) && isvector(x));
p.addRequired('lambda_fixed', @(x) isnumeric(x) && isscalar(x) && x >= 0);

p.addParameter('ModelClass', 'full', @(x) ischar(x) || isstring(x));
p.addParameter('Phase', '', @(x) ischar(x) || isstring(x) || iscell(x));
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
p.addParameter('UnitID', "", @(x) isscalar(x) || isstring(x) || ischar(x));
p.addParameter('MinSpikesToFit', 100, @(x) isnumeric(x) && isscalar(x) && x >= 0);
% NEW: match side-view
p.addParameter('PositionMode', 'basis', @(x) any(strcmpi(string(x), ["basis","bin"])));

p.parse(B, basis, spike_times_ms, lambda_fixed, varargin{:});

model_class   = lower(string(p.Results.ModelClass));
phase_in      = p.Results.Phase;
lag_ms        = p.Results.LagMs;
unit_id       = string(p.Results.UnitID);
position_mode = lower(string(p.Results.PositionMode));

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

if ~ismember(model_class, ["state","action","full"])
    error('ModelClass must be one of: state, action, full.');
end

% ------------------------------------------------------------
% 1. Optional phase subset
% ------------------------------------------------------------
phases = local_normalize_phases_topview(phase_in);

if isempty(phases)
    B_use = B;
    phase_label = "both";
else
    if ~ismember('lever_phase', B.Properties.VariableNames)
        error('B must contain lever_phase if Phase is specified.');
    end
    B_use = B(ismember(string(B.lever_phase), phases), :);
    phase_label = strjoin(phases, "+");
end

if isempty(B_use)
    error('No rows remain after phase filtering.');
end

% ------------------------------------------------------------
% 2. Build feature blocks according to model class
% ------------------------------------------------------------
pos_specs = struct('prefix', {}, 'x_col', {}, 'y_col', {}, 'valid_col', {});
vel_vars = {};
speed_vars = {};

% state block
state_pos_specs = struct( ...
    'prefix',    "headPos", ...
    'x_col',     "head_x_rel_cm", ...
    'y_col',     "head_y_rel_cm", ...
    'valid_col', "valid_head");

state_speed_vars = {'head_theta_cos', 'head_theta_sin'};

% action block
action_vel_vars = {'forward_speed_cm_s', 'lateral_speed_cm_s'};
action_speed_vars = {'speed_cm_s'};

switch model_class
    case "state"
        pos_specs = state_pos_specs;
        vel_vars = {};
        speed_vars = {};

    case "action"
        pos_specs = struct('prefix', {}, 'x_col', {}, 'y_col', {}, 'valid_col', {});
        vel_vars = action_vel_vars;
        speed_vars = action_speed_vars;

    case "full"
        pos_specs = state_pos_specs;
        vel_vars = action_vel_vars;
        speed_vars = [action_speed_vars, state_speed_vars];
end

% ------------------------------------------------------------
% 3. Make feature matrix
% ------------------------------------------------------------

feature_mat = Kin.make_glm_feature_matrix( ...
    B_use, pos_specs, vel_vars, speed_vars, 'trial', basis, ...
    'PositionMode', position_mode);

% ------------------------------------------------------------
% 4. Shift spike times
% ------------------------------------------------------------
spike_times_shifted = spike_times_ms(:) + lag_ms;

% ------------------------------------------------------------
% 5. Run repeated fixed-lambda fitting
% ------------------------------------------------------------
[result_rep_local, result_summary] = Kin.fit_poisson_elasticnet_glm_repeated( ...
    feature_mat, ...
    spike_times_shifted, ...
    basis, ...
    {'headPos'}, ...
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
% 6. Metadata
% ------------------------------------------------------------
meta = struct();
meta.model_class = char(model_class);
meta.phase = char(phase_label);
meta.phases = phases;
meta.lag_ms = lag_ms;
meta.lambda_fixed = lambda_fixed;
meta.unit_id = unit_id;
meta.position_mode = position_mode;

meta.pos_specs = pos_specs;
meta.vel_vars = vel_vars;
meta.speed_vars = speed_vars;

meta.n_rows_B = height(B_use);

result_summary.meta = meta;

% ------------------------------------------------------------
% 7. Optional repetition details
% ------------------------------------------------------------
if return_rep
    result_rep = result_rep_local;
else
    result_rep = [];
end

end

function phases = local_normalize_phases_topview(phase_in)
if isempty(phase_in)
    phases = strings(0,1);
    return
end

phases = string(phase_in);
phases = phases(:);

if numel(phases) == 1 && strlength(phases) == 0
    phases = strings(0,1);
    return
end

if any(strcmpi(phases, "all")) || any(strcmpi(phases, "both"))
    phases = ["toLever"; "fromLever"];
end

phases = unique(phases, 'stable');
end


