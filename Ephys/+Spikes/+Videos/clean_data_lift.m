function [x_,y_, vel_,t_]=clean_data_lift(t, x, y, like, threshold, name)

    if nargin<5
        name = 'Temp';
    end

    figure(15); clf(15);
    set(15, 'Visible', 'on', 'Units', 'pixels', 'Position', [250 250 800 500], 'name', 'Lift and Press')
    ha1 = subplot(3, 2, [2 4]); hold on
    plot(x, y, 'color', 'k','marker', 'o', 'markerfacecolor', 'k', 'linestyle', '-', 'linewidth', 1)
    set(gca, 'ydir', 'reverse')
    ha2 = subplot(3, 2, 1); hold on
    plot(t,x, 'color', 'k','marker', 'o', 'markerfacecolor', 'k', 'linestyle', '-', 'linewidth', 1); ylabel('x')
    ha3 = subplot(3, 2, 3); hold on
    plot(t,y, 'color', 'k','marker', 'o', 'markerfacecolor', 'k', 'linestyle', '-', 'linewidth', 1); ylabel('y')

    % Remove points with low likelihood at the beginning and end
    valid_indices = like > threshold;
    start_idx = find(valid_indices, 1, 'first'); % First valid point
    end_idx = find(valid_indices, 1, 'last');   % Last valid point

    % Truncate the data to only include valid points
    t = t(start_idx:end_idx);
    t_ = t';
    x = x(start_idx:end_idx);
    y = y(start_idx:end_idx);

    like = like(start_idx:end_idx);
    lowLikelihoodIdx = like < threshold; % Threshold for low likelihood (adjust if necessary)
    axes(ha1)
    plot(x(lowLikelihoodIdx), y(lowLikelihoodIdx), 'color', 'r','marker', '*')

    % Interpolate missing points (low likelihood) in the middle
    for i = 2:length(like)-1
        if like(i) < threshold
            % Linear interpolation for x and y coordinates
            x(i) = interp1([t(i-1), t(i+1)], [x(i-1), x(i+1)], t(i), 'linear', 'extrap');
            y(i) = interp1([t(i-1), t(i+1)], [y(i-1), y(i+1)], t(i), 'linear', 'extrap');
        end
    end
    hold on
    % Plot interpolated x, y
    scatter(x(lowLikelihoodIdx),y(lowLikelihoodIdx), 'markerfacecolor', 'm','marker','o', 'SizeData', 20, 'linewidth', 1);
    grid on
    % add smoothdata
    x_=smoothdata(x, 'movmedian', 7);
    y_=smoothdata(y, 'movmedian', 7);

    % Interpolate missing points (NaN) in x and y using interp1
    valid_x_idx = ~isnan(x_);
    valid_y_idx = ~isnan(y_);

    % Interpolation for x
    x_(isnan(x_)) = interp1(t_(valid_x_idx), x_(valid_x_idx), t_(isnan(x_)), 'linear', 'extrap');

    % Interpolation for y
    y_(isnan(y_)) = interp1(t_(valid_y_idx), y_(valid_y_idx), t_(isnan(y_)), 'linear', 'extrap');

    plot(x_, y_, 'color', 'g','marker', '+', 'LineWidth',1, 'LineStyle','-')
    legend('Org', 'LowLike', 'LowLikeCorrected', 'MedianSmoothed', 'Location', 'best')

    axes(ha2)
    plot(t, x, 'color', 'r','marker', '*')
    % scatter(t(lowLikelihoodIdx),x(lowLikelihoodIdx), 'markerfacecolor', 'm','marker','o', 'SizeData', 20, 'linewidth', 1);
    % add smoothdata
    plot(t, x_,  'color', 'g','marker', '+', 'LineWidth',1, 'LineStyle','-')
    set(gca, 'xlim', [t(1) t(end)]);
    grid on

    axes(ha3)
    plot(t, y, 'color', 'r','marker', '*')
    % scatter(t(lowLikelihoodIdx),y(lowLikelihoodIdx), 'markerfacecolor', 'm','marker','o', 'SizeData', 20, 'linewidth', 1);
    % add smoothdata
    plot(t,y_,  'color', 'g','marker', '+', 'LineWidth',1, 'LineStyle','-')
    set(gca, 'xlim', [t(1) t(end)]);
    grid on

    % compute movement direction and compute the difference between
    % movement direction and head direction, bang!
    dx = smoothdata(diff(x_), 'movmedian', 7);
    dy = smoothdata(-diff(y_), 'movmedian', 7); % compute difference 

    % plot velocity
    subplot(3, 2, [5 6])
    t=t';
    vel = sqrt(diff(x_).^2+diff(y_).^2)./diff(t);
    vel = smoothdata(vel, 'gaussian', 11);
    % Create a plot with two y-axes
    plot(t(2:end), vel, 'bo-');  % Plot velocity (left y-axis)
    ylabel('Velocity (pix/ms)');  % Label for the left y-axis
      set(gca, 'xlim', [t(1) t(end)]);
    vel_ = [NaN; vel];

    % xlabel('velocity')
    data_folder = fullfile(pwd, 'SideTrajExtracted_Clean');
    if ~exist(data_folder, 'dir')
        mkdir(data_folder);
    end

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