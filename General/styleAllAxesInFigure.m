function styleAllAxesInFigure(fig)
    % Styles all axes in a figure for consistent tick label appearance
    % Input: fig (figure handle, optional; defaults to current figure)
    
    % Default to current figure if none provided
    if nargin < 1 || isempty(fig)
        fig = gcf;
    end
    
    % Find all axes in the figure (including subplots, excludes colorbars)
    ax = findall(fig, 'Type', 'axes', '-not', 'Tag', 'Colorbar');
    
    % Desired tick length in millimeters
    tickLengthMM = 0.4/10; % 0.5 mm for all ticks

    % Loop through each axes object
    for i = 1:length(ax)

        set(ax(i), 'Units', 'centimeters');
        pos = get(ax(i), 'Position'); % [x, y, width, height] in mm
        axesWidthMM = pos(3); % Width in mm
        axesHeightMM = pos(4); % Height in mm
        
        % Convert 0.5 mm to normalized units for TickLength
        % TickLength is [2D_length 3D_length], we set 2D ticks (x and y)
        tickLengthNormalizedX = tickLengthMM / axesWidthMM; % For x-axis ticks
        tickLengthNormalizedY = tickLengthMM / axesHeightMM; % For y-axis ticks
        tickLengthNormalized = min(tickLengthNormalizedX, tickLengthNormalizedY);
        % Apply styling
        ax(i).TickLength = [tickLengthNormalized tickLengthNormalized];
        ax(i).FontSize = 7; % Tick label font size
        ax(i).TickDir = 'out';
        ax(i).XLabel.FontSize = 7.5; % X-axis label font size
        ax(i).YLabel.FontSize = 7.5; % Y-axis label font size
        % ax(i).Box = 'off'; % Cleaner look
        ax(i).LineWidth = 0.5; % Thinner axes lines
        % ax(i).XLabel.Interpreter = 'latex'; % Support italicized labels
        % ax(i).YLabel.Interpreter = 'latex'; % For multiline ylabel
    end
    
    % Optional: Style colorbars if present
    cb = findall(fig, 'Type', 'colorbar');
    for j = 1:length(cb)
        cb(j).EdgeColor = 'k'; % From your earlier question
        cb(j).FontSize = 6; % Match axes font size
        cb(j).TickLength = 0.01; % Short ticks
    end

    adjust_figure_size(fig);
end


% Script to adjust figure height to max plot height and width to rightmost plot position
function adjust_figure_size(hf)
    % Get the current figure
    fig = hf;
    
    % Set units to centimeters for precise measurements
    set(fig, 'Units', 'centimeters');
    
    % Get all axes in the figure
    axes = findall(fig, 'Type', 'axes');
    
    % Initialize maximum boundaries (in centimeters)
    maxHeight = 5;
    maxRight = 5;
    
    % Loop through each axes to find the maximum height and rightmost position
    for ax = axes'
        % Set axes units to centimeters
        set(ax, 'Units', 'centimeters');
                % Get position of axes in figure (centimeters)
        pos = get(ax, 'Position');        
        % Calculate height including title
        height = pos(2)+pos(4); % Height of axes         

        % Calculate rightmost position including ylabel
        right = pos(1) + pos(3); % Right edge of axes
        % Update maximum boundaries
        maxHeight = max(maxHeight, height);
        maxRight = max(maxRight, right);
    end

    cbs = findall(fig, 'Type', 'colorbar');
    for cb = cbs'
        set(cb, 'Units', 'centimeters');
        % Get position of axes in figure (centimeters)
        pos = get(cb, 'Position');
        % Calculate height including title
        height = pos(2)+pos(4); % Height of axes

        % Calculate rightmost position including ylabel
        right = pos(1) + pos(3); % Right edge of axes
        % Update maximum boundaries
        maxHeight = max(maxHeight, height);
        maxRight = max(maxRight, right);
    end
    
    % Add small padding (e.g., 0.2 cm)
    padding = 1;
    maxHeight = maxHeight +  padding; % Padding top and bottom
    maxRight = maxRight + padding; % Padding on right

    % 
    % sprintf('Maximal height is %.2d cm', maxHeight)
    % sprintf('Maximal width is %.2d cm', maxRight)

    % Get current figure position
    fig_pos = get(fig, 'Position');
    
    % Adjust figure width and height
    fig_pos(3) = maxRight; % Set width to rightmost position
    fig_pos(4) = maxHeight; % Set height to maximum plot height
    set(fig, 'Position', fig_pos);
    
    % Ensure PaperPositionMode is auto for proper saving/exporting
    set(fig, 'PaperPositionMode', 'auto');
end