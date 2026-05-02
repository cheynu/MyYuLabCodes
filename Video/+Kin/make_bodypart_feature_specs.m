function S = make_bodypart_feature_specs(body_parts)
%MAKE_BODYPART_FEATURE_SPECS Build variable names for selected body parts.
%
% Usage:
%   S = make_bodypart_feature_specs({'LeftPaw','RightPaw','LeftEar'});
%
% Output fields:
%   S.x_cols
%   S.y_cols
%   S.valid_cols
%   S.pos_specs
%   S.vel_vars
%   S.speed_vars
%
% Example:
%   S = make_bodypart_feature_specs({'RightPaw','LeftEar'});
%   basis = Kin.design_shared_xy_basis_set(B, S.x_cols, S.y_cols, S.valid_cols, ...
%       'NumX', 10, 'NumY', 10, 'QuantileRange', [0 1], 'SigmaScale', 0.75);

    arguments
        body_parts (1,:) cell
    end

    n = numel(body_parts);

    x_cols = cell(1, n);
    y_cols = cell(1, n);
    valid_cols = cell(1, n);

    pos_specs = struct( ...
        'prefix', cell(1, n), ...
        'x_col', cell(1, n), ...
        'y_col', cell(1, n), ...
        'valid_col', cell(1, n));

    vel_vars = cell(1, 2 * n);
    speed_vars = cell(1, n);

    for i = 1:n
        bp = body_parts{i};

        x_cols{i} = sprintf('%s_x_rel_cm', bp);
        y_cols{i} = sprintf('%s_y_rel_cm', bp);
        valid_cols{i} = sprintf('valid_%s', bp);

        pos_specs(i).prefix = bp;
        pos_specs(i).x_col = x_cols{i};
        pos_specs(i).y_col = y_cols{i};
        pos_specs(i).valid_col = valid_cols{i};

        vel_vars{2*i - 1} = sprintf('%s_vx_cm_s', bp);
        vel_vars{2*i}     = sprintf('%s_vy_cm_s', bp);

        speed_vars{i} = sprintf('%s_speed_cm_s', bp);
    end

    S = struct();
    S.x_cols = x_cols;
    S.y_cols = y_cols;
    S.valid_cols = valid_cols;
    S.pos_specs = pos_specs;
    S.vel_vars = vel_vars;
    S.speed_vars = speed_vars;
end