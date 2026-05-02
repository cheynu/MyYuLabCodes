function traj_table = extract_traj_lift(TrajExtracted, clean_data, name_tag, body_part)

% Jianing Yu 1/15/2025
% Jianing Yu 3/18/2025
% extract data from TrajExtracted
% TrajExtracted = 
%   struct with fields:
%           EarLTop: [1×1 struct]
%           EarRTop: [1×1 struct]
%              LEDa: [1×1 struct]
%              LEDp: [1×1 struct]
%           NoseTop: [1×1 struct]
%              Tail: [1×1 struct]
%     IndexSelected: [438×1 double]
%      TimeSelected: [1.5565e+04 1.5575e+04 1.5585e+04 1.5595e+04 1.5605e+04 1.5615e+04 1.5625e+04 … ] (1×438 double)
% TrajExtracted is a product of the app 'rVideoViewer.mlapp'
% Load the .mat file and access the TrajExtracted structure
% Assuming TrajExtracted is already loaded from the file

if nargin<3
    name_tag = [];
end
name_tag = [name_tag '_' body_part];
% Extract relevant data: left paw, right paw, left ear
index = TrajExtracted.IndexSelected;
timeSegments = TrajExtracted.TimeSelected; % Time segments

eval(['xPaw = TrajExtracted.' body_part, '.x;'])
eval(['yPaw = TrajExtracted.' body_part, '.y;'])
eval(['tracking_likelihood_Paw = TrajExtracted.' body_part, '.likelihood;'])
tracking_likelihood = tracking_likelihood_Paw;

if isempty(index)
    disp('Hello, this file is empty! ')
    disp(name_tag)
    traj_table = [];
else
    % Logical array indicating jumps
    jumps       = [true; diff(index) > 1];
    ind_jumps_beg = find(jumps); % this is the index of jumps, the first one is 1
    seg_beg = index(jumps); % this is the beg index of the index

    if length(ind_jumps_beg)>1
        ind_jumps_end       = [find(jumps(2:end)); numel(index)];
        seg_end                 = index([find(jumps(2:end)); numel(index)]);
    else
        ind_jumps_end       = numel(index);
        seg_end                 = index(end);
    end

    % Segment beginnings and endings
    numSegments         = numel(seg_beg);
    threshold               = 0.2;

    x_selected = [];
    y_selected = [];
    t_selected = [];

    vel_selected = [];

    dx_dt = [];
    dy_dt = [];
    d2x_dt2 = [];
    d2y_dt2 = [];

    for seg = 1:numSegments
        % Extract time indices for the current segment
        t                   = timeSegments(ind_jumps_beg(seg):ind_jumps_end(seg));
        x_seg               = xPaw(seg_beg(seg):seg_end(seg));
        y_seg               = yPaw(seg_beg(seg):seg_end(seg));
        likelihood_seg      = tracking_likelihood(seg_beg(seg):seg_end(seg));

        if clean_data == 1
            [x_seg,y_seg, vel_seg, t_seg]=Spikes.Videos.clean_data_lift(t, x_seg, y_seg, likelihood_seg, threshold, name_tag);
        end

        x_selected = [x_selected; x_seg];
        y_selected = [y_selected; y_seg];
        t_selected = [t_selected; t_seg];
        vel_selected = [vel_selected; vel_seg];

        if length(t) < 2
            continue; % Skip this segment if less than 2 time points
        end

        % Compute derivatives within the current segment
        dx = diff(x_seg); % dx
        dy = diff(y_seg); % dy
        dt  = diff(t_seg);
        % First derivatives (set NaN at boundaries where computation is invalid)
        dx_dt_seg = [NaN; dx ./ dt];
        dy_dt_seg = [NaN; dy ./ dt];

        % Second derivatives (set NaN at boundaries)
        d2x_dt2_seg = [NaN; NaN; diff(dx_dt_seg(2:end)) ./ dt(1:end-1)];
        d2y_dt2_seg = [NaN; NaN; diff(dy_dt_seg(2:end)) ./ dt(1:end-1)];

        % Append to results
        dx_dt = [dx_dt; dx_dt_seg];
        dy_dt = [dy_dt; dy_dt_seg];
        d2x_dt2 = [d2x_dt2; d2x_dt2_seg];
        d2y_dt2 = [d2y_dt2; d2y_dt2_seg];
    end
    pattern = 'TrajExtracted_([A-Za-z0-9_]+)\.mat';
    % Use regexp to extract the token
    tokens = regexp(name_tag, pattern, 'tokens');
    % Display result
    file_name = tokens{1};
    data_source = repmat(file_name, length(x_selected), 1);
    % Let's put things together
    traj_table= table(data_source, t_selected, x_selected, y_selected, vel_selected, dx_dt, dy_dt, d2x_dt2, d2y_dt2, ...
        'VariableNames',{'Source', 'Time', 'x', 'y', 'velocity', 'dx', 'dy', 'd2x', 'd2y'});
end