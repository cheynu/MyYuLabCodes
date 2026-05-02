function out = reconstruct_spatial_tuning_field_masked_from_trial_info( ...
    result, basis, trial_info, body_part, varargin)
%RECONSTRUCT_SPATIAL_TUNING_FIELD_MASKED_FROM_TRIAL_INFO
% Reconstruct spatial field and occupancy mask using body-part positions
% extracted directly from trial_info.
%
% Inputs
%   result, basis, trial_info, body_part
%
% Name-value
%   'TrialSel'        trial indices, default all trials
%   'NumX'            default 100
%   'NumY'            default 100
%   'Dt'              default 1
%   'SmoothSigma'     default 1
%   'MinTime'         default []
%   'MinFracOfMax'    default 0.05
%   'UseSmoothedOcc'  default true
%   'ShowPlot'        default false
%   'ShowExpField'    default false

    p = inputParser;
    p.addParameter('TrialSel', 1:numel(trial_info), @(z) isnumeric(z) || islogical(z));
    p.addParameter('NumX', 100, @(z) isnumeric(z) && isscalar(z) && z >= 10);
    p.addParameter('NumY', 100, @(z) isnumeric(z) && isscalar(z) && z >= 10);
    p.addParameter('Dt', 1, @(z) isnumeric(z) && isscalar(z) && z > 0);
    p.addParameter('SmoothSigma', 1, @(z) isnumeric(z) && isscalar(z) && z >= 0);
    p.addParameter('MinTime', [], @(z) isempty(z) || (isnumeric(z) && isscalar(z) && z >= 0));
    p.addParameter('MinFracOfMax', 0.05, @(z) isnumeric(z) && isscalar(z) && z >= 0 && z <= 1);
    p.addParameter('UseSmoothedOcc', true, @(z) islogical(z) && isscalar(z));
    p.addParameter('ShowPlot', false, @(z) islogical(z) && isscalar(z));
    p.addParameter('ShowExpField', false, @(z) islogical(z) && isscalar(z));
    p.parse(varargin{:});

    trial_sel = p.Results.TrialSel;

    [x, y, extract_meta] = Kin.extract_bodypart_positions_from_trial_info( ...
        trial_info, body_part, trial_sel);

    out = Kin.reconstruct_spatial_tuning_field_masked( ...
        result, basis, body_part, x, y, ...
        'NumX', p.Results.NumX, ...
        'NumY', p.Results.NumY, ...
        'Dt', p.Results.Dt, ...
        'SmoothSigma', p.Results.SmoothSigma, ...
        'MinTime', p.Results.MinTime, ...
        'MinFracOfMax', p.Results.MinFracOfMax, ...
        'UseSmoothedOcc', p.Results.UseSmoothedOcc, ...
        'ShowExpField', p.Results.ShowExpField);

    out.extract_meta = extract_meta;


    if p.Results.ShowPlot

        hf = figure('Color', 'w');
        hf.Units = 'centimeters';
        hf.Position = [2 2 8 7];

        Kin.plot_spatial_field_masked( ...
            hf, out.field, basis, trial_info, body_part, ...
            'FieldPosition', [1.2 1.8 5 5], ...
            'FontName', 'Arial', ...
            'FontSize', 7, ...
            'TrajLineWidth', 0.25, ...
            'TrajColor', [0.3 0.3 0.3], ...
            'NumTrialsToPlot', 20, ...
            'ShowMaskOverlay', true, ...
            'MaskColor', [.8 .8 .8]);

    end

end