function [x_,y_, vel_]=clean_data(t, x, y, like, threshold, name)
    if nargin<5
        name = 'Temp';
    end
    lowLikelihoodIdx = like < threshold; % Threshold for low likelihood (adjust if necessary)
    highLikelihoodIdx = ~lowLikelihoodIdx;
    figure(12); clf(12);
    set(12, 'Visible', 'on')
    subplot(3, 2, [2 4 6])
    plot(x, y, 'color', 'k','marker', 'o', 'markerfacecolor', 'k', 'linestyle', '-', 'linewidth', 1)
    % Interpolate x and y using high-likelihood points
    x(lowLikelihoodIdx) = interp1(find(highLikelihoodIdx), x(highLikelihoodIdx), find(lowLikelihoodIdx), 'linear', 'extrap');
    y(lowLikelihoodIdx) = interp1(find(highLikelihoodIdx), y(highLikelihoodIdx), find(lowLikelihoodIdx), 'linear', 'extrap');
    hold on
    plot(x, y, 'color', 'r','marker', '*')
    scatter(x(lowLikelihoodIdx),y(lowLikelihoodIdx), 'markerfacecolor', 'c','marker','o', 'SizeData', 20, 'linewidth', 1);
    set(gca, 'ydir', 'reverse')
    % add smoothdata
    plot(smoothdata(x, 'movmedian', 7), smoothdata(y, 'movmedian', 7), 'color', 'g','marker', '+', 'LineWidth',1, 'LineStyle','-')
    legend('Org', 'LowLike', 'Smoothed')
    subplot(3, 2, 1)
    plot(t, x, 'ko'); hold on
    x_=smoothdata(x, 'movmedian', 7);
    plot(t, x_, '+-', 'Color','g','LineWidth',1);
    set(gca, 'xlim', [t(1) t(end)]);
    ylabel('x')
    subplot(3, 2, 3)
    plot(t, y, 'ko'); hold on
    y_=smoothdata(y, 'movmedian', 7);
    plot(t, y_, '+-', 'Color', 'g','LineWidth',1);
    set(gca, 'xlim', [t(1) t(end)]);
    ylabel('y')
    % plot velocity
    subplot(3, 2, 5)
    vel = sqrt(diff(x_).^2+diff(y_).^2)./diff(t');
    vel = smoothdata(vel, 'gaussian', 11);
    plot(t(2:end), vel, '-', 'Color', 'k','LineWidth',1);
    ylabel('velocity')
    xlabel('t')
    set(gca, 'xlim', [t(1) t(end)]);
    vel_ = [NaN; vel];

    % xlabel('velocity')
    data_folder = fullfile(pwd, 'TrajExtracted_Clean');
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