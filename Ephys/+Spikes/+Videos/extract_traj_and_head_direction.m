function traj_table = extract_traj_and_head_direction(TrajExtracted, clean_data, name_tag)

% Jianing Yu 1/15/2025
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

% Extract relevant data: left ear
index = TrajExtracted.IndexSelected;
timeSegments = TrajExtracted.TimeSelected; % Time segments

eval(['xL = TrajExtracted.' 'EarLTop', '.x;'])
eval(['yL = TrajExtracted.' 'EarLTop', '.y;'])
eval(['tracking_likelihood_L = TrajExtracted.' 'EarLTop', '.likelihood;'])
% Extract relevant data: right ear
eval(['xR = TrajExtracted.' 'EarRTop', '.x;'])
eval(['yR = TrajExtracted.' 'EarRTop', '.y;'])
eval(['tracking_likelihood_R = TrajExtracted.' 'EarRTop', '.likelihood;'])
% Extract relevant data: tail
eval(['xT = TrajExtracted.' 'Tail', '.x;'])
eval(['yT = TrajExtracted.' 'Tail', '.y;'])
eval(['tracking_likelihood_T = TrajExtracted.' 'Tail', '.likelihood;'])
tracking_likelihood = min([tracking_likelihood_L tracking_likelihood_R tracking_likelihood_T], [], 2);
% Determine the correct perpendicular direction: We can now check which of
% the perpendicular vectors is pointing away from the tail. To do this, we
% compute the dot product between each perpendicular vector and the vector
% from the tail to the midpoint of the ears.
% The perpendicular vector whose dot product with the tail-to-midpoint
% vector is positive will be the one pointing away from the tail.

figure(10); clf(10)
subplot(2, 1, 1)

axis equal
set(gca, 'nextplot', 'add', 'ydir', 'reverse');
head_direction = NaN*ones(1, length(xL));
% midpoints 
x_midpoints =  NaN*ones(1, length(xL));
y_midpoints =  NaN*ones(1, length(xL));

% compute angle
for i=1:length(index)
    ii = index(i);
    itheta_perp = NaN;
    if tracking_likelihood(ii)>0.9
        dxlr = xR(ii)-xL(ii);
        dylr = yR(ii)-yL(ii);
        % midpoint of the ears
        xm = (xL(ii)+xR(ii))/2;
        ym = (yL(ii)+yR(ii))/2;
        x_midpoints(ii) = xm;
        y_midpoints(ii) = ym; 
        % vector from tail to midpoint
        Tx = xm - xT(ii);
        Ty = ym - yT(ii);
        d_perp_1 = [dylr, -dxlr]; % 90 deg clockwise
        d_perp_2 = [-dylr, dxlr]; % 90 deg counter-clockwise
        % compute dot product betwen d_perp and the tail-to-midline vector
        dot1 = Tx*d_perp_1(1)+Ty*d_perp_1(2);
        dot2 = Tx*d_perp_2(1)+Ty*d_perp_2(2);
        if dot1>0
            d_perp = d_perp_1;
        else
            d_perp=d_perp_2;
        end
        itheta_perp             = -atan2(d_perp(2), d_perp(1)); % note the -d_perp(1) is to invert the direction since y labeling is reversed. 
        itheta_perp_deg         = rad2deg(itheta_perp);
        if rand>.95
            hold on
            line([xL(ii)'; xR(ii)'], [yL(ii)'; yR(ii)'], 'Color', 'r');
            scatter(xT(ii), yT(ii), '^', 'c','filled', 'SizeData', 40);
            quiver(xm, ym, d_perp(1), d_perp(2), 0, 'r', 'LineWidth', 0.5, 'MaxHeadSize', 2);
            hold off
            % Display the angles
            % disp('Angles of the perpendicular direction (in deg):');
            % disp(itheta_perp_deg);
            drawnow
        end
    end
    head_direction(ii) = itheta_perp;
end
subplot(2, 1, 2)
tplot = TrajExtracted.TimeSelected;
head_plot = head_direction(index);
scatter(tplot, head_plot, '+', 'r')
hold on
scatter(tplot, unwrap(head_plot), 'o', 'g')
hold off

if isempty(index)
    disp('This file is empty: ')
    disp(name_tag)
    traj_table = [];
else

    % Logical array indicating jumps
    jumps       = [true; diff(index) > 1];
    ind_jumps_beg = find(jumps); % this is the index of jumps, the first one is 1
    seg_beg = index(jumps); % this is the beg index of the index

    if length(ind_jumps_beg)>1
        ind_jumps_end = [find(jumps(2:end)); numel(index)];
        seg_end = index([find(jumps(2:end)); numel(index)]);
    else
        ind_jumps_end = numel(index);
        seg_end = index(end);
    end

    % Segment beginnings and endings
    numSegments = numel(seg_beg);
    threshold = 0.2;

    x_selected = [];
    y_selected = [];
    t_selected = [];
    angle_selected = [];
    theta_selected = []; % movement direction
    vel_selected = [];
    vel_angle_selected = [];

    dx_dt = [];
    dy_dt = [];
    d2x_dt2 = [];
    d2y_dt2 = [];

    for seg = 1:numSegments
        % Extract time indices for the current segment
        t                   = timeSegments(ind_jumps_beg(seg):ind_jumps_end(seg));
        x_seg               = x_midpoints(seg_beg(seg):seg_end(seg));
        y_seg               = y_midpoints(seg_beg(seg):seg_end(seg));
        head_seg            = head_direction(seg_beg(seg):seg_end(seg));
        likelihood_seg      = tracking_likelihood(seg_beg(seg):seg_end(seg));
        if clean_data == 1
            %  [x_,y_, angle_, vel_, vel_ang_]
            [x_seg,y_seg, angle_seg, vel_seg, vel_ang_seg, theta_seg, t_seg]=Spikes.Videos.clean_data_angle(t, x_seg, y_seg, head_seg, likelihood_seg, threshold, name_tag);
        end

        x_selected = [x_selected; x_seg'];
        y_selected = [y_selected; y_seg'];
        t_selected = [t_selected; t_seg'];
        angle_selected = [angle_selected; angle_seg'];
        theta_selected = [theta_selected; theta_seg'];
        vel_selected = [vel_selected; vel_seg'];
        vel_angle_selected = [vel_angle_selected; vel_ang_seg'];

        if length(t) < 2
            continue; % Skip this segment if less than 2 time points
        end

        % Compute derivatives within the current segment
        dx = diff(x_seg'); % dx
        dy = diff(y_seg'); % dy
        dt  = diff(t_seg);
        dt  = dt';
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
    traj_table= table(data_source, t_selected, x_selected, y_selected, angle_selected, theta_selected, vel_selected, vel_angle_selected, dx_dt, dy_dt, d2x_dt2, d2y_dt2, ...
        'VariableNames',{'Source', 'Time', 'x', 'y', 'head_angle', 'movement_angle', 'velocity','angular_velocity', 'dx', 'dy', 'd2x', 'd2y'});

end