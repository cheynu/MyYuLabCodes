function seeUnitLocation(spatial, unitLocation, ha);

% Extract coordinates
recording_x = spatial.xcoords(spatial.connected); % Use only connected channels
recording_y = spatial.ycoords(spatial.connected);
shank_ids = spatial.kcoords(spatial.connected); % Shank assignments (if available)
unit_x = unitLocation.where(1, :); % X-coordinates of units
unit_y = unitLocation.where(2, :); % Y-coordinates of units
spike_sizes = unitLocation.what; % Spike sizes for color mapping
good = unitLocation.type;
% Diagnostic: Check unique x-coordinates and shank IDs
unique_x = unique(recording_x);
% fprintf('Unique X-coordinates (μm): %s\n', num2str(unique_x'));
% fprintf('Number of unique X-coordinates: %d\n', length(unique_x));
if exist('shank_ids', 'var')
    fprintf('Unique shank IDs: %s\n', num2str(unique(shank_ids')));
end

% Compress shank separation
if length(unique(shank_ids)) > 1
    new_spacing = 50; % Desired shank separation (μm)
    unique_shanks = unique(shank_ids);
    shank_centers = zeros(size(unique_shanks));
    for s = 1:length(unique_shanks)
        shank_mask = shank_ids == unique_shanks(s);
        shank_centers(s) = mean(unique(recording_x(shank_mask)));
    end
    % Shift x-coordinates to new spacing
    x_shifted = recording_x;
    for s = 1:length(unique_shanks)
        shank_mask = shank_ids == unique_shanks(s);
        old_center = shank_centers(s);
        new_center = min(shank_centers) + (s-1) * new_spacing;
        x_shifted(shank_mask) = recording_x(shank_mask) - old_center + new_center;
    end
    % Shift unit x-coordinates similarly
    unit_x_shifted = unit_x;
    for s = 1:length(unique_shanks)
        shank_mask = abs(unit_x - shank_centers(s)) < 100; % Units near shank
        old_center = shank_centers(s);
        new_center = min(shank_centers) + (s-1) * new_spacing;
        unit_x_shifted(shank_mask) = unit_x(shank_mask) - old_center + new_center;
    end
else
    unique_shanks = unique(shank_ids);
    x_shifted = recording_x; % No shift for single shank
    unit_x_shifted = unit_x;
end

axes(ha)
ha.NextPlot = "add";

% Define probe parameters
probe_length = 5000; % 5 mm (μm)
shank_width = 40; % Approximate shank width (μm)
shank_spacing = 250; % Shank separation for Neuropixels 2.0 (μm)

% Plot probe outline
colors = lines(length(unique_shanks)); % Color per shank
for s = 1:length(unique_shanks)
    shank_mask = shank_ids == unique_shanks(s);
    x_center = mean(unique(x_shifted(shank_mask))); % Center of shifted shank
    % Warn if no staggering
    if length(unique(x_shifted(shank_mask))) < 2
        warning('Shank %d has only %d unique x-coordinate(s). Check channel map.', ...
                unique_shanks(s), length(unique(x_shifted(shank_mask))));
    end
    % Draw shank outline
    rectangle(ha, 'Position', [x_center - shank_width/2, 0, shank_width, probe_length], ...
              'EdgeColor', colors(s, :), 'LineWidth', 1, 'FaceColor', 'none');
end

% Plot recording sites as small squares, color-coded by shank
square_size = 5; % Smaller size to show staggering
for s = 1:length(unique_shanks)
    shank_mask = shank_ids == unique_shanks(s);
    for i = find(shank_mask)'
        % rectangle(ha, 'Position', [x_shifted(i) - square_size/2, recording_y(i) - square_size/2, square_size, square_size], ...
        %     'FaceColor', colors(s, :), 'EdgeColor', 'none');
        scatter(ha, x_shifted(i), recording_y(i), 'o', 'SizeData', square_size, ...
            'MarkerFaceColor', colors(s, :), 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.5);
    end
end

% Plot unit locations
cmap = parula; % Colormap
spike_sizes_norm = (spike_sizes - min(spike_sizes)) / (max(spike_sizes) - min(spike_sizes)); % Normalize
circle_size = 20; % Scatter point size

% Plot unit locations with size based on rateNorm (if available)
if isfield(unitLocation, 'rateNorm')
    rate_norm = unitLocation.rateNorm;
    % Map rateNorm (0-1) to dot sizes (10-50 points)
    min_size = 10; max_size = 50;
    circle_sizes = min_size + (max_size - min_size) * rate_norm;

    % Plot good (filled) and bad (outlined) units in black
    scatter(ha, unit_x_shifted(good==1), unit_y(good==1), circle_sizes(good==1), 'k', 'filled', 'Marker', 'o','MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', 'none');
    scatter(ha, unit_x_shifted(good==0), unit_y(good==0), circle_sizes(good==0), 'k', 'Marker', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'none');

else
    % Fallback: Fixed size
    circle_sizes = 40;

    scatter(ha, unit_x_shifted(good==1), unit_y(good==1), circle_sizes, 'k', 'filled', 'Marker', 'o');
    scatter(ha, unit_x_shifted(good==0), unit_y(good==0), circle_sizes, 'k', 'Marker', 'o', 'MarkerEdgeColor', 'flat');
   
end


% Customize plot
% xlabel('X (μm)');
% ylabel('Y (μm)');
grid on;

% Zoom to show both shanks
x_zoom = [min(x_shifted) - 50, max(x_shifted) + 50]; % Adjusted for compressed shanks
y_zoom = [min(recording_y) - 200, max(recording_y) + 200]; % ~400 μm
xlim(ha, x_zoom);
ylim(ha, y_zoom);

hold off;