function [x_,y_, angle_, vel_, vel_ang_, theta_, t_]=clean_data_angle(t, x, y, angle, like, threshold, name)

if nargin<5
    name = 'Temp';
end

figure(12); clf(12);
set(12, 'Visible', 'on', 'Units', 'pixels', 'Position', [250 250 800 500])
ha1 = subplot(3, 2, [2 4]); hold on
plot(x, y, 'color', 'k','marker', 'o', 'markerfacecolor', 'k', 'linestyle', '-', 'linewidth', 1)
set(gca, 'ydir', 'reverse')
ha2 = subplot(3, 2, 1); hold on
plot(t,x, 'color', 'k','marker', 'o', 'markerfacecolor', 'k', 'linestyle', '-', 'linewidth', 1); ylabel('x')
ha3 = subplot(3, 2, 3); hold on
plot(t,y, 'color', 'k','marker', 'o', 'markerfacecolor', 'k', 'linestyle', '-', 'linewidth', 1); ylabel('y')
ha4 = subplot(3, 2, 5); hold on
h1=plot(t,angle, 'color', 'k','marker', 'o', 'markerfacecolor', 'k', 'linestyle', '-', 'linewidth', 1); ylabel('angle')
%

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
hold on
axes(ha1)
plot(x, y, 'color', 'r','marker', '*')
scatter(x(lowLikelihoodIdx),y(lowLikelihoodIdx), 'markerfacecolor', 'c','marker','o', 'SizeData', 20, 'linewidth', 1);
grid on
% add smoothdata

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

plot(x_, y_, 'color', 'g','marker', '+', 'LineWidth',1, 'LineStyle','-')
legend('Org', 'LowLike', 'Smoothed')
axes(ha2)
plot(t, x, 'color', 'r','marker', '*')
scatter(t(lowLikelihoodIdx),x(lowLikelihoodIdx), 'markerfacecolor', 'c','marker','o', 'SizeData', 20, 'linewidth', 1);
% add smoothdata
plot(t, x_,  'color', 'g','marker', '+', 'LineWidth',1, 'LineStyle','-')
set(gca, 'xlim', [t(1) t(end)]);
grid on

axes(ha3)
plot(t, y, 'color', 'r','marker', '*')
scatter(t(lowLikelihoodIdx),y(lowLikelihoodIdx), 'markerfacecolor', 'c','marker','o', 'SizeData', 20, 'linewidth', 1);
% add smoothdata
plot(t,y_,  'color', 'g','marker', '+', 'LineWidth',1, 'LineStyle','-')
set(gca, 'xlim', [t(1) t(end)]);
grid on

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

figure(12)
angle_ = smoothdata(angle, 'gaussian', 11);
% plot velocity
subplot(3, 2, 6)
vel = sqrt(diff(x_).^2+diff(y_).^2)./diff(t);
vel = smoothdata(vel, 'gaussian', 11);
vel_ang = diff((angle_))./diff(t);
vel_ang = smoothdata(vel_ang, 'gaussian', 11);
% Create a plot with two y-axes
yyaxis left
plot(t(2:end), vel, 'b');  % Plot velocity (left y-axis)
ylabel('Velocity (pix/ms)');  % Label for the left y-axis
yyaxis right
plot(t(2:end), vel_ang, 'r');  % Plot angular velocity (right y-axis)
ylabel('Angular Velocity (rad/ms)');  % Label for the right y-axis
xlabel('Time (ms)');
title('Velocity and Angular Velocity vs Time');
set(gca, 'xlim', [t(1) t(end)]);
vel_ = [NaN vel];
vel_ang_ = [NaN vel_ang];

axes(ha4);
h2=plot(t, angle, 'color', 'b','marker', '*');
hold on
% scatter(t(lowLikelihoodIdx),angle(lowLikelihoodIdx), 'markerfacecolor', 'c','marker','o', 'SizeData', 20, 'linewidth', 1);
% add smoothdata
h3=plot(t, angle_,  'color', 'g','marker', '+', 'LineWidth',1, 'LineStyle','-');
theta__ = theta_;
theta__(vel_<0.05)=NaN; % note if there is no movement, there is no movement direction
h4=plot(t, theta__, 'color', 'r', 'marker', '.');
legend([h1, h3, h4],'head angle', 'angle smoothed', 'move direction')
set(gca, 'xlim', [t(1) t(end)]);
xlabel('Time (ms)')
grid on

% xlabel('velocity')
data_folder = fullfile(pwd, 'TrajExtracted_Clean');
if ~exist(data_folder, 'dir')
    mkdir(data_folder);
end
if ~isempty(name)
    if strcmp(name, 'Temp')
        path_name = fullfile(data_folder, [name '.png']);
        [file_path, name, file_ext] = fileparts(path_name); % Split into components
        % Check if the file exists and append a number if necessary
        new_path_name = path_name;
        counter = 1;
        while exist(new_path_name, 'file') % Check if the file exists
            new_path_name = fullfile(file_path, sprintf('%s_%d%s', name, counter, file_ext));
            counter = counter + 1;
        end

        % Save the current figure as a PNG
        print(gcf, new_path_name, '-dpng', '-r300'); % '-r300' sets the resolution to 300 DPI
    else
        pattern = 'TrajExtracted_([A-Za-z0-9_]+)\.mat';
        % Use regexp to extract the token
        tokens = regexp(name, pattern, 'tokens');
        % Display result
        file_name = tokens{1}{1};

        annotation('textbox', [0.5, 0.9, 0.1, 0.1], 'String', file_name, ...
            'Interpreter', 'none',...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'EdgeColor', 'none', 'FontSize', 15, 'FontWeight', 'bold');

        path_name = fullfile(data_folder, [file_name '.png']);
        [file_path, file_name, file_ext] = fileparts(path_name); % Split into components
        % Check if the file exists and append a number if necessary
        new_path_name = path_name;
        counter = 1;
        while exist(new_path_name, 'file') % Check if the file exists
            new_path_name = fullfile(file_path, sprintf('%s_%d%s', file_name, counter, file_ext));
            counter = counter + 1;
        end

        % Save the current figure as a PNG
        print(gcf, new_path_name, '-dpng', '-r300'); % '-r300' sets the resolution to 300 DPI
        disp(['Figure saved to: ', new_path_name]);
    end
end
end