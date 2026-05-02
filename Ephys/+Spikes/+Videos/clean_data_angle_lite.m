function [x_,y_, angle_, vel_, vel_ang_, theta_, t_]=clean_data_angle_lite(t, x, y, angle, like, threshold, name)
% This version is the same as clearn_data_angle.m but it won't plot the
% data
% figure
if nargin<5
    name = 'Temp';
end

% Remove points with low likelihood at the beginning and end
valid_indices = like > threshold;
start_idx = find(valid_indices, 1, 'first'); % First valid point
end_idx = find(valid_indices, 1, 'last');   % Last valid point

% Truncate the data to only include valid points
t = t(start_idx:end_idx);
t_ = t;
x = x(start_idx:end_idx);
y = y(start_idx:end_idx);
angle = angle(start_idx:end_idx);
angle = unwrap(angle);
like = like(start_idx:end_idx);
lowLikelihoodIdx = like < threshold; % Threshold for low likelihood (adjust if necessary)

% Interpolate missing points (low likelihood) in the middle
for i = 2:length(like)-1
    if like(i) < threshold
        % Linear interpolation for x and y coordinates
        x(i) = interp1([t(i-1), t(i+1)], [x(i-1), x(i+1)], t(i), 'linear', 'extrap');
        y(i) = interp1([t(i-1), t(i+1)], [y(i-1), y(i+1)], t(i), 'linear', 'extrap');
        angle(i) = interp1([t(i-1), t(i+1)], [angle(i-1), angle(i+1)], t(i), 'linear', 'extrap');
    end
end

x_=smoothdata(x, 'movmedian', 7);
y_=smoothdata(y, 'movmedian', 7);

% Find valid (non-NaN) indices
valid_x_idx = ~isnan(x_);
valid_y_idx = ~isnan(y_);

% Interpolation for x (only interpolate NaNs within valid range)
if any(valid_x_idx)
    % Get time points and values for valid data
    t_valid = t_(valid_x_idx);
    x_valid = x_(valid_x_idx);

    % Find indices of NaNs that are within the valid range
    first_valid_idx = find(valid_x_idx, 1, 'first');
    last_valid_idx = find(valid_x_idx, 1, 'last');
    interpolate_idx = isnan(x_) & (t_ >= t_(first_valid_idx) & t_ <= t_(last_valid_idx));

    % Interpolate only for NaNs within the valid range
    x_(interpolate_idx) = interp1(t_valid, x_valid, t_(interpolate_idx), 'linear');
end

% Interpolation for y (only interpolate NaNs within valid range)
if any(valid_y_idx)
    % Get time points and values for valid data
    t_valid = t_(valid_y_idx);
    y_valid = y_(valid_y_idx);

    % Find indices of NaNs that are within the valid range
    first_valid_idx = find(valid_y_idx, 1, 'first');
    last_valid_idx = find(valid_y_idx, 1, 'last');
    interpolate_idx = isnan(y_) & (t_ >= t_(first_valid_idx) & t_ <= t_(last_valid_idx));

    % Interpolate only for NaNs within the valid range
    y_(interpolate_idx) = interp1(t_valid, y_valid, t_(interpolate_idx), 'linear');
end

% compute movement direction and compute the difference between
% movement direction and head direction, bang!
dx = smoothdata(diff(x_), 'movmedian', 7);
dy = smoothdata(-diff(y_), 'movmedian', 7); % compute difference
theta = atan2(dy, dx); % Convert to angles.
theta_ = [NaN theta];

% figure(15); clf(15);
% subplot(2, 1, 1);
% plot(t(2:end), dx, t(2:end), dy);
% axis tight
% subplot(2, 1, 2);
% line([t(1) t(end)], [0 0], 'color', 'k', 'linewidth', 2)
% hold on
% plot(t(2:end), theta, 'linewidth', 1)
% plot(t, theta_, 'c', 'linewidth', 1)
% axis tight

angle_ = smoothdata(angle, 'gaussian', 11);
% plot velocity
vel = sqrt(diff(x_).^2+diff(y_).^2)./diff(t);
vel = smoothdata(vel, 'gaussian', 11);
vel_ang = diff((angle_))./diff(t);
vel_ang = smoothdata(vel_ang, 'gaussian', 11);
% Create a plot with two y-axes
vel_ = [NaN vel];
vel_ang_ = [NaN vel_ang];

% scatter(t(lowLikelihoodIdx),angle(lowLikelihoodIdx), 'markerfacecolor', 'c','marker','o', 'SizeData', 20, 'linewidth', 1);
% add smoothdata
theta__ = theta_;
theta__(vel_<0.05)=NaN; % note if there is no movement, there is no movement direction

end