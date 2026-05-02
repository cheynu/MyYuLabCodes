function ViewSpikeOnTraj(TrajTableAll, sdf_unit, name_tag, spatial_span)
% Jianing Yu 2025 
% sdf_units(1)
% ans = 
%   struct with fields:
%              ch: 5
%            unit: 1
%     spk_time_ms: [37 225 233 268 625 909 1740 1980 2643 2721 3166 3203 3458 3659 3979 3997 4420 4521 … ]
%        t_sdf_ms: [217413×1 double]
%             sdf: [217413×1 double]

if nargin<4
    spatial_span = [0 800;0 600];
    if nargin<3
        name_tag = [];
    end
end
set(groot, 'DefaultAxesFontSize', 7, 'DefaultAxesFontName', 'Arial'); 

features      =  [];
response    =  [];

xrange = spatial_span(1, :);
bin_size = 10;
% Create edges for grid bins
xBinEdges = linspace(xrange(1), xrange(2), diff(xrange)/bin_size);
yrange = spatial_span(2, :);
% Create edges for grid bins
yBinEdges = linspace(yrange(1), yrange(2), diff(yrange)/bin_size);

% Data preparation
time_table = TrajTableAll.Time; % Replace with the Time column from your table
x = TrajTableAll.x; % x positions
y = TrajTableAll.y; % y positions
is_before = ~TrajTableAll.BeforePress;

% Interpolate SDF values for each time point in the table
transformed_sdf = (sdf_unit.sdf);
sdf_values_org = interp1(sdf_unit.t_sdf_ms, sdf_unit.sdf, time_table, 'linear', 0);
sdf_values = interp1(sdf_unit.t_sdf_ms, transformed_sdf, time_table, 'linear', 0);
spike_rate_max = quantile(sdf_values, 0.95);
marker_sizes = 5 + 25 * (sdf_values - min(sdf_values)) / (spike_rate_max - min(sdf_values));
threshold = quantile(sdf_values, 0.9);
high_firing = sdf_values > threshold; % Define threshold

%% Method 1 | Plot trajectory with color-coded firing rate
hf = 26;
figure(hf); clf(hf)
figSize = [14 12]; % in cm
plotSize = [4 4*diff(yrange)/diff(xrange)];
set(hf,'units', 'centimeters', 'position', [2 2 figSize],...
    'color', 'w', 'name', 'trajectory and firing rate', 'paperpositionmode', 'auto')
ha1 = axes;
x_pos = 1.25;
y_pos = 2;
set(ha1, 'nextplot', 'add', 'ydir', 'reverse', 'units', 'centimeters', 'position', [x_pos y_pos plotSize], 'xlim', xrange, 'ylim', yrange);

% only plot 10% of the data to reduce figure size
% Get logical indices for the two subsets of data
plotRatio = 0.25                                                                                                                                                                                                                                                                                                                                                                                                                                       ;
low_indices = ~high_firing & is_before;
high_indices = high_firing & is_before;

% Number of points to sample (10% of the total points in each subset)
num_low = sum(low_indices);  % Total points that are 'before'
num_high = sum(high_indices);    % Total points that are 'after'

num_low_sampled = round(num_low * plotRatio);  % 10% of 'before'
num_high_sampled = round(num_high * plotRatio);    % 10% of 'after'

% Randomly sample 10% of the points from the 'before' and 'after' sets
random_low_indices = find(low_indices);  % Indices of points in the 'before' subset
random_high_indices = find(high_indices);    % Indices of points in the 'after' subset

% Sample 10% of the indices
sampled_low_indices = random_low_indices(randperm(num_low, num_low_sampled));
sampled_high_indices = random_high_indices(randperm(num_high, num_high_sampled));

% Plot the randomly sampled points for hsc1 (before high firing)
hsc1 = scatter(x(sampled_low_indices), y(sampled_low_indices), ...
    marker_sizes(sampled_low_indices), sdf_values(sampled_low_indices), 'filled', ...
    'Marker', 'o', 'MarkerFaceAlpha', 0.6, 'SizeData', 2.5, 'MarkerEdgeColor', 'none');

% Plot the randomly sampled points for hsc2 (after high firing)
hsc2 = scatter(x(sampled_high_indices), y(sampled_high_indices), ...
    marker_sizes(sampled_high_indices), sdf_values(sampled_high_indices), 'filled', ...
    'Marker', 'o', 'MarkerFaceAlpha', 0.6, 'SizeData', 10, 'MarkerEdgeColor', 'none');

colormap('hot'); % Apply hot colormap
caxis([quantile(sdf_values, 0.01) quantile(sdf_values, 0.99)+1]); % Set color axis to match SDF range
xlabel('X Position');
ylabel('Y Position');
title('(to lever)');

ha2 = axes;
x_pos = 1.5+plotSize(1)+1.5;

set(ha2, 'nextplot', 'add', 'ydir', 'reverse', 'units', 'centimeters', 'position', [x_pos y_pos plotSize], 'xlim', xrange, 'ylim', yrange);
% only plot 10% of the data to reduce figure size
% Get logical indices for the two subsets of data
low_indices = ~high_firing & ~is_before;
high_indices = high_firing & ~is_before;

% Number of points to sample (10% of the total points in each subset)
num_low = sum(low_indices);  % Total points that are 'before'
num_high = sum(high_indices);    % Total points that are 'after'

num_low_sampled = round(num_low * plotRatio);  % 10% of 'before'
num_high_sampled = round(num_high * plotRatio);    % 10% of 'after'

% Randomly sample 10% of the points from the 'before' and 'after' sets
random_low_indices = find(low_indices);  % Indices of points in the 'before' subset
random_high_indices = find(high_indices);    % Indices of points in the 'after' subset

% Sample 10% of the indices
sampled_low_indices = random_low_indices(randperm(num_low, num_low_sampled));
sampled_high_indices = random_high_indices(randperm(num_high, num_high_sampled));

% Plot the randomly sampled points for hsc1 (before high firing)
hsc1 = scatter(x(sampled_low_indices), y(sampled_low_indices), ...
    marker_sizes(sampled_low_indices), sdf_values(sampled_low_indices), 'filled', ...
    'Marker', 'o', 'MarkerFaceAlpha', 0.6, 'SizeData', 2.5, 'MarkerEdgeColor', 'none');

% Plot the randomly sampled points for hsc2 (after high firing)
hsc2 = scatter(x(sampled_high_indices), y(sampled_high_indices), ...
    marker_sizes(sampled_high_indices), sdf_values(sampled_high_indices), 'filled', ...
    'Marker', 'o', 'MarkerFaceAlpha', 0.6, 'SizeData', 10, 'MarkerEdgeColor', 'none');

colormap('hot'); % Apply hot colormap
hbar = colorbar; % Show colorbar for firing rate
set(hbar, 'units', 'centimeters', 'position', [x_pos+plotSize(1)+0.5 y_pos .2 plotSize(2)])
hbar.Label.String = 'log(1+Firing Rate)';
hbar.Label.Rotation = 90; % Rotate the colorbar label
hbar.Label.VerticalAlignment = 'middle';
hbar.Label.Position(1) = hbar.Label.Position(1) + .5; % Adjust label position horizontally
 
caxis([quantile(sdf_values, 0.01) quantile(sdf_values, 0.99)+1]); % Set color axis to match SDF range
xlabel('X Position');
ylabel('Y Position');
title('(from lever)');

% Initialize the grid for averaging
numBinsY = length(yBinEdges)-1;
numBinsX = length(xBinEdges)-1;
rateGrid = zeros(numBinsY, numBinsX);
countGrid = zeros(numBinsY, numBinsX);

% Assign each (xi, yi) to a grid cell and accumulate firing rates

for i = 1:length(x)
    % Find the bin indices for the current point
    xBin = find(x(i) >= xBinEdges, 1, 'last');
    yBin = find(y(i) >= yBinEdges, 1, 'last');

    if ~isempty(xBin) && ~isempty(yBin)
        % Skip points falling outside the grid boundaries
        if xBin > numBinsX || yBin > numBinsY || xBin < 1 || yBin < 1
            continue;
        end
        % Accumulate the firing rate in the corresponding grid cell
        rateGrid(yBin, xBin) = rateGrid(yBin, xBin) + sdf_values_org(i);
        countGrid(yBin, xBin) = countGrid(yBin, xBin) + 1;
    end
end

% Calculate the average firing rate for each grid cell
avgRateGrid = rateGrid ./ countGrid;
avgRateGrid(isnan(avgRateGrid)) = 0;  % Replace NaN with 0 for empty cells

% Apply Gaussian smoothing
sigma = 1;  % Standard deviation for Gaussian kernel
kernelSize = 5;  % Size of the Gaussian kernel
[xx, yy] = meshgrid(-floor(kernelSize/2):floor(kernelSize/2), -floor(kernelSize/2):floor(kernelSize/2));
gaussianKernel = exp(-(xx.^2 + yy.^2) / (2 * sigma^2));
gaussianKernel = gaussianKernel / sum(gaussianKernel(:));  % Normalize the kernel
% Convolve the grid with the Gaussian kernel
smoothedRateGrid = conv2(avgRateGrid, gaussianKernel, 'same');

% Plot the 2D color map
x_pos = 1.25;
y_pos = y_pos + plotSize(2)+2.5;
ha4=axes;
set(ha4, 'nextplot', 'add', 'ydir', 'reverse', 'units', 'centimeters',...
    'position', [x_pos y_pos plotSize], 'xlim', xrange, 'ylim', yrange);

imagesc(xBinEdges, yBinEdges, smoothedRateGrid);
set(gca, 'YDir', 'reverse');  % Ensure the y-axis is oriented correctly
title('Average Firing Rate Heatmap');
xlabel('X Position');
ylabel('Y Position');
colormap(ha4, 'parula');

c = colorbar; % Show colorbar for firing rate
set(c, 'units', 'centimeters', 'position', [x_pos+plotSize(1)+0.2 y_pos .2 plotSize(2)])
c.Label.String = 'Firing Rate (Hz)';
c.Label.Rotation = 90; % Rotate the colorbar label
c.Label.VerticalAlignment = 'bottom';
c.Label.Position(1) = c.Label.Position(1) + 1; % Adjust label position horizontally

dim = [0.1 0.95 0.9 0.05]; % [x, y, width, height]
str = [name_tag];
annotation('textbox', dim, 'units', 'normalized', 'String', str, 'EdgeColor', 'none', ...
    'Interpreter', 'none',...
   'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');

% add warped PSTH here
x_pos = x_pos+plotSize(1)+1+2;
plotSize = [4 3];
ha5=axes;
set(ha5, 'nextplot', 'add', 'ydir', 'normal',...
    'units', 'centimeters', 'position', [x_pos y_pos plotSize], 'xlim', xrange, 'ylim', yrange);

FP_cols = [40, 55, 57; 34, 136, 150; 169, 197, 47]/255;
for i = 1:length(sdf_unit.warp_out.twarp)
    plotshaded(sdf_unit.warp_out.twarp{i}, sdf_unit.warp_out.sdf_ci{i}, [.6 .6 .6])
    plot(sdf_unit.warp_out.twarp{i}, sdf_unit.warp_out.sdf_avg{i}, 'linewidth', 1, 'color', FP_cols(i, :))
end

set(ha5, 'xlim', [min(sdf_unit.warp_out.twarp{i}) max(sdf_unit.warp_out.twarp{i})]);
axis 'auto y'
for i = 1:length(sdf_unit.warp_out.twarp)
    xShade =[0 sdf_unit.fp(i) sdf_unit.fp(i) 0];
    yShade = [0 0 max(get(ha5, 'ylim')) max(get(ha5, 'ylim'))];
    patch(xShade, yShade, [0.1, 0.8, 0.1], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
end
xlabel('Time from press (ms)')
ylabel('Firing rate (Hz)')

% %% Method 2 | Trajectory segementation (not very useful)
% % Description: Segment the trajectory based on firing rate thresholds and plot different segments in distinct colors or line thicknesses.
% % How:
% % Identify trajectory points where firing rate is high or low using a threshold (e.g., firing rate > median).
% % Plot trajectory segments in different styles (e.g., thick lines for high firing and thin for low firing).
% 
% ha1 = axes;
% set(ha1, 'nextplot', 'add', 'ydir', 'reverse', 'units', 'pixels', 'position', [100 50 300 300], 'xlim', xrange, 'ylim', yrange);
% scatter(x(~high_firing& is_before), y(~high_firing& is_before),...
%     'o','b','filled','markeredgecolor','none', 'LineWidth', 0.5,'markerfacealpha', 0.6); % Low firing
% hold on;
% scatter(x(high_firing & is_before), y(high_firing & is_before),...
%     'o','r','filled','markeredgecolor','none', 'LineWidth', 2,'markerfacealpha', 0.6); % High firing
% legend('High Firing', 'Low Firing');
% xlabel('X Position');
% ylabel('Y Position');
% title('Movement Trajectory with Firing Rate (to lever)');
% 
% ha2 = axes;
% set(ha2, 'nextplot', 'add', 'ydir', 'reverse', 'units', 'pixels', 'position', [500 50 300 300], 'xlim', xrange, 'ylim', yrange);
% scatter(x(~high_firing& ~is_before), y(~high_firing& ~is_before), 'o', 'b',...
%     'filled','markeredgecolor','none','LineWidth', 0.5,'markerfacealpha', 0.6); % Low firing
% hold on;
% scatter(x(high_firing & ~is_before), y(high_firing & ~is_before), 'o','r',...
%     'filled','markeredgecolor','none','LineWidth', 1,'markerfacealpha', 0.6); % High firing
% legend('High Firing', 'Low Firing');
% xlabel('X Position');
% ylabel('Y Position');
% title('Movement Trajectory with Firing Rate (from lever)');

%% Method 3 | Plot speed direction
vel = TrajTableAll.velocity;
is_before = ~TrajTableAll.BeforePress;
theta = TrajTableAll.movement_angle; % Convert to angles.
% not considering very slow movement
theta(vel<quantile(vel, .5))=NaN;
not_nan = ~isnan(theta);
% 
hf2 = 27;
figure(hf2); clf(hf2)

figSize = [16 14.5]; % in cm
set(hf2,'units', 'centimeters', 'position', [15 2 figSize],...
    'color', 'w', 'name', 'trajectory and firing rate', 'paperpositionmode', 'auto')

annotation('textbox', dim, 'units', 'normalized', 'String', str, 'EdgeColor', 'none', ...
    'Interpreter', 'none',...
   'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');

plotSize = [3 3];
theta_1               =           theta(not_nan & is_before);
firing_rate_1       =           sdf_values_org((not_nan & is_before));

bin_centers = -pi : (pi/4) : (3*pi/4);
bin_edges   = bin_centers+pi/8;
% Get the bin index for each data point
bin_idx = discretize(theta_1, bin_edges);
bin_idx(~isnan(bin_idx))=bin_idx(~isnan(bin_idx))+1;
bin_idx(isnan(bin_idx)) = 1; 
num_bins = length(bin_centers);

% Compute mean firing rate for each bin
tuning_curve1 = zeros(1, num_bins); % Initialize tuning curve
tuning_curve1ci = NaN*ones(2, num_bins); % Initialize tuning curve
rate_direction_labels = [];
rate_direction = [];

for i = 1:num_bins
    rates = firing_rate_1(bin_idx == i);
    rate_direction_labels = [rate_direction_labels; i*ones(length(rates), 1)];
    rate_direction = [rate_direction; rates];
    if sum(bin_idx == i)>10
        tuning_curve1(i) = mean(rates); % Mean firing rate for each bin
        tuning_curve1ci (:, i) = bootci(1000, @mean, rates);
    end
end

% Add first bin to the end for circular plot
tuning_curve1 = [tuning_curve1, tuning_curve1(1)];
tuning_curve1ci = [tuning_curve1ci, tuning_curve1ci(:,1)];
bin_centers2 = [bin_centers, bin_centers(1)]; % Add first bin center to close the circle

xpos_2 = 1.5;
xpos = xpos_2;
ypos = 10;

% Plot the tuning curve
ha1 = polaraxes;
polarplot(bin_centers2, tuning_curve1, 'LineWidth', 1, 'color', 'b', 'marker', 'o', 'markerfacecolor', 'b', 'markeredgecolor','w');
hold on
ci_upper = tuning_curve1ci(1, :);
ci_lower= tuning_curve1ci(2, :);
% Now add radial error bars:
for i = 1:length(bin_centers2)
    % For each point, plot a line from (r - err) to (r + err).
    % This draws a "vertical" line in the polar coordinate sense.
    polarplot([bin_centers2(i) bin_centers2(i)], ...
        [ci_upper(i) ci_lower(i)], ...
        'b-', 'LineWidth', 1);
end
ha1.ThetaTick = 0:45:360-45;
hold off
title('Move direction (to lever)', 'fontsize', 9);
ha1.Units = 'centimeters';
ha1.Position=[xpos ypos plotSize];
ha1.FontName = 'arial';
ha1.FontSize = 7;

theta_2 =theta(not_nan & ~is_before);
firing_rate_2 = sdf_values_org((not_nan & ~is_before));
% Bin theta into equally spaced bins
% [~, bin_idx] = histcounts(theta_1, edges); % Assign each theta to a bin
% Get the bin index for each data point
bin_idx = discretize(theta_2, bin_edges);
bin_idx(~isnan(bin_idx))=bin_idx(~isnan(bin_idx))+1;
bin_idx(isnan(bin_idx)) = 1; 
 
% Compute mean firing rate for each bin
tuning_curve2 = zeros(1, num_bins); % Initialize tuning curve
tuning_curve2ci = NaN*ones(2, num_bins); % Initialize tuning curve
for i = 1:num_bins
    if sum(bin_idx == i)>10
            tuning_curve2(i)        = mean(firing_rate_2(bin_idx == i)); % Mean firing rate for each bin
        tuning_curve2ci (:, i) = bootci(1000, @mean, firing_rate_2(bin_idx == i));
    end
end

% Add first bin to the end for circular plot
tuning_curve2= [tuning_curve2, tuning_curve2(1)];
tuning_curve2ci = [tuning_curve2ci, tuning_curve2ci(:,1)];
 
% Plot the tuning curve
ha2 = polaraxes;
polarplot(bin_centers2, tuning_curve2, 'LineWidth', 1, 'color', 'b', 'marker', 'o', 'markerfacecolor', 'b', 'markeredgecolor','w');
hold on
ci_upper = tuning_curve2ci(1, :);
ci_lower= tuning_curve2ci(2, :);
for i = 1:length(bin_centers2)
    % For each point, plot a line from (r - err) to (r + err).
    % This draws a "vertical" line in the polar coordinate sense.
    polarplot([bin_centers2(i) bin_centers2(i)], ...
        [ci_upper(i) ci_lower(i)], ...
        'b-', 'LineWidth', 1);
end
ha2.ThetaTick = 0:45:360-45;
hold off

title('(from lever)', 'fontsize', 9);
ha2.Units = 'centimeters';
xpos = xpos +plotSize(1)+2;
ha2.Position=[xpos ypos plotSize];
ha2.FontName = 'arial';
ha2.FontSize = 7;
 
% all combined
theta_0 =theta(not_nan);
firing_rate_0 = sdf_values_org((not_nan));
% Bin theta into equally spaced bins
 % [~, bin_idx] = histcounts(theta_1, edges); % Assign each theta to a bin
% Get the bin index for each data point

bin_idx = discretize(theta_0, bin_edges);
bin_idx(~isnan(bin_idx))=bin_idx(~isnan(bin_idx))+1;
bin_idx(isnan(bin_idx)) = 1; 
 
% Compute mean firing rate for each bin
tuning_curve0 = zeros(1, num_bins); % Initialize tuning curve
tuning_curve0ci = NaN*ones(2, num_bins); % Initialize tuning curve

for i = 1:num_bins
    if sum(bin_idx == i)>10
        tuning_curve0(i) = mean(firing_rate_0(bin_idx == i)); % Mean firing rate for each bin
        tuning_curve0ci (:, i) = bootci(1000, @mean, firing_rate_0(bin_idx == i));
    end
end

% Add first bin to the end for circular plot
tuning_curve0 = [tuning_curve0, tuning_curve0(1)];
tuning_curve0ci = [tuning_curve0ci, tuning_curve0ci(:,1)];

% Plot the tuning curve
% Plot the tuning curve
ha3 = polaraxes;
polarplot(bin_centers2, tuning_curve0, 'LineWidth', 1, 'color', 'b', 'marker', 'o', 'markerfacecolor', 'b', 'markeredgecolor','w');
hold on
ci_upper = tuning_curve0ci(1, :);
ci_lower= tuning_curve0ci(2, :);
for i = 1:length(bin_centers2)
    % For each point, plot a line from (r - err) to (r + err).
    % This draws a "vertical" line in the polar coordinate sense.
    polarplot([bin_centers2(i) bin_centers2(i)], ...
        [ci_upper(i) ci_lower(i)], ...
        'b-', 'LineWidth', 1);
end
ha3.ThetaTick = 0:45:360-45;
hold off

title('(Combined)', 'fontsize', 9);
ha3.Units = 'centimeters';
xpos = xpos +plotSize(1)+2;
ha3.Position=[xpos ypos plotSize];
ha3.FontName = 'arial';
ha3.FontSize = 7;
rate_max = max([tuning_curve1 tuning_curve2 tuning_curve0]);
ha1.RLim = [0 rate_max*1.1];
ha2.RLim = [0 rate_max*1.1];
ha3.RLim = [0 rate_max*1.1];


%% Method 3.1 | Plot head direction (regardless of movement)
vel = TrajTableAll.velocity;
is_before = ~TrajTableAll.BeforePress;
theta_head = TrajTableAll.head_angle; % Convert to angles.
theta_head = mod(theta_head+pi, 2*pi)-pi;
% not considering very slow movement
theta_head(vel<quantile(vel, .5))=NaN;
not_nan = ~isnan(theta_head);

xpos = xpos_2;
ypos = ypos - plotSize(2)-1.5;
theta_1               =           theta_head(not_nan & is_before);
firing_rate_1       =           sdf_values_org((not_nan & is_before));

% Bin theta into equally spaced bins
% [~, bin_idx] = histcounts(theta_1, edges); % Assign each theta to a bin
% Get the bin index for each data point
bin_idx = discretize(theta_1, bin_edges);
bin_idx(~isnan(bin_idx))=bin_idx(~isnan(bin_idx))+1;
bin_idx(isnan(bin_idx)) = 1; 

% Compute mean firing rate for each bin
tuning_curve1 = zeros(1, num_bins); % Initialize tuning curve
tuning_curve1ci = NaN*ones(2, num_bins); % Initialize tuning curve
for i = 1:num_bins
    rates = firing_rate_1(bin_idx == i);
    if sum(bin_idx == i)>10
            tuning_curve1(i) = mean(rates); % Mean firing rate for each bin
        tuning_curve1ci (:, i) = bootci(1000, @mean, rates);
    end
end

% Add first bin to the end for circular plot
tuning_curve1 = [tuning_curve1, tuning_curve1(1)];
tuning_curve1ci = [tuning_curve1ci, tuning_curve1ci(:,1)];

% Plot the tuning curve
ha1 = polaraxes;
polarplot(bin_centers2, tuning_curve1, 'LineWidth', 1, 'color', 'b', 'marker', 'o', 'markerfacecolor', 'b', 'markeredgecolor','w');
hold on
ci_upper = tuning_curve1ci(1, :);
ci_lower= tuning_curve1ci(2, :);
% Now add radial error bars:
for i = 1:length(bin_centers2)
    % For each point, plot a line from (r - err) to (r + err).
    % This draws a "vertical" line in the polar coordinate sense.
    polarplot([bin_centers2(i) bin_centers2(i)], ...
        [ci_upper(i) ci_lower(i)], ...
        'b-', 'LineWidth', 1);
end
ha1.ThetaTick = 0:45:360-45;
hold off

title('Head direction (to lever)', 'fontsize', 9);
ha1.Units = 'centimeters';
ha1.Position=[xpos ypos plotSize];
ha1.FontName = 'arial';
ha1.FontSize = 7;

theta_2 =theta_head(not_nan & ~is_before);
firing_rate_2 = sdf_values_org((not_nan & ~is_before));
% Bin theta into equally spaced bins
 % [~, bin_idx] = histcounts(theta_1, edges); % Assign each theta to a bin
% Get the bin index for each data point
bin_idx = discretize(theta_2, bin_edges);
bin_idx(~isnan(bin_idx))=bin_idx(~isnan(bin_idx))+1;
bin_idx(isnan(bin_idx)) = 1; 

% Compute mean firing rate for each bin
tuning_curve2 = zeros(1, num_bins); % Initialize tuning curve
tuning_curve2ci = NaN*ones(2, num_bins); % Initialize tuning curve
for i = 1:num_bins
    if sum(bin_idx == i)>10
            tuning_curve2(i)        = mean(firing_rate_2(bin_idx == i)); % Mean firing rate for each bin
        tuning_curve2ci (:, i) = bootci(1000, @mean, firing_rate_2(bin_idx == i));
    end
end

% Add first bin to the end for circular plot
tuning_curve2= [tuning_curve2, tuning_curve2(1)];
tuning_curve2ci = [tuning_curve2ci, tuning_curve2ci(:,1)];

% Plot the tuning curve
ha2 = polaraxes;
polarplot(bin_centers2, tuning_curve2, 'LineWidth', 1, 'color', 'b', 'marker', 'o', 'markerfacecolor', 'b', 'markeredgecolor','w');
hold on
ci_upper = tuning_curve2ci(1, :);
ci_lower= tuning_curve2ci(2, :);
% Now add radial error bars:
for i = 1:length(bin_centers2)
    % For each point, plot a line from (r - err) to (r + err).
    % This draws a "vertical" line in the polar coordinate sense.
    polarplot([bin_centers2(i) bin_centers2(i)], ...
        [ci_upper(i) ci_lower(i)], ...
        'b-', 'LineWidth', 1);
end
ha2.ThetaTick = 0:45:360-45;

hold off
title('(from lever)', 'fontsize', 9);
ha2.Units = 'centimeters';
xpos = xpos + plotSize(1)+2;
ha2.Position=[xpos ypos plotSize];
ha2.FontName = 'arial';
ha2.FontSize = 7;

% all combined
theta_0 =theta_head(not_nan);
firing_rate_0 = sdf_values_org((not_nan));
% Bin theta into equally spaced bins
bin_edges = linspace(-pi, pi, num_bins+1); % Bin edges
% [~, bin_idx] = histcounts(theta_1, edges); % Assign each theta to a bin
% Get the bin index for each data point
bin_idx = discretize(theta_0, bin_edges);
bin_idx(~isnan(bin_idx))=bin_idx(~isnan(bin_idx))+1;
bin_idx(isnan(bin_idx)) = 1; 

% Compute mean firing rate for each bin
tuning_curve0 = zeros(1, num_bins); % Initialize tuning curve
tuning_curve0ci = NaN*ones(2, num_bins); % Initialize tuning curve

for i = 1:num_bins
    if sum(bin_idx == i)>10
            tuning_curve0(i) = mean(firing_rate_0(bin_idx == i)); % Mean firing rate for each bin
        tuning_curve0ci (:, i) = bootci(1000, @mean, firing_rate_0(bin_idx == i));
    end
end

% Add first bin to the end for circular plot
tuning_curve0 = [tuning_curve0, tuning_curve0(1)];
tuning_curve0ci = [tuning_curve0ci, tuning_curve0ci(:,1)];

% Plot the tuning curve
ha3 = polaraxes;
polarplot(bin_centers2, tuning_curve0, 'LineWidth', 1, 'color', 'b', 'marker', 'o', 'markerfacecolor', 'b', 'markeredgecolor','w');
hold on
ci_upper = tuning_curve0ci(1, :);
ci_lower= tuning_curve0ci(2, :);
% Now add radial error bars:
for i = 1:length(bin_centers2)
    % For each point, plot a line from (r - err) to (r + err).
    % This draws a "vertical" line in the polar coordinate sense.
    polarplot([bin_centers2(i) bin_centers2(i)], ...
        [ci_upper(i) ci_lower(i)], ...
        'b-', 'LineWidth', 1);
end
ha3.ThetaTick = 0:45:360-45;
hold off
title('(Combined)', 'fontsize', 9);
ha3.Units = 'centimeters';
xpos = xpos + plotSize(1)+2;
ha3.Position=[xpos ypos plotSize]; 
ha3.FontName = 'arial';
ha3.FontSize = 7;

rate_max = max([tuning_curve1 tuning_curve2 tuning_curve0]);
ha1.RLim = [0 rate_max*1.1];
ha2.RLim = [0 rate_max*1.1];
ha3.RLim = [0 rate_max*1.1];
%% Method 3.2 | Plot firing rate over turning 
% (that is, the difference betwen theta_head and theta_move)
theta_head = TrajTableAll.head_angle; % Convert to angles.
theta_head = mod(theta_head+pi, 2*pi)-pi;
theta_mov = TrajTableAll.movement_angle; % Convert to angles.
angle_diff = theta_mov-theta_head;
angle_diff = mod(angle_diff+pi, 2*pi)-pi;

xpos =xpos_2;
ypos = ypos-plotSize(2)-1.5;

vel = TrajTableAll.velocity;
is_before = ~TrajTableAll.BeforePress;
% not considering very slow movement
ind_excluded = vel<quantile(vel, .5);
angle_diff(ind_excluded)=NaN;
not_nan = ~isnan(angle_diff);

features      =  [theta_mov theta_head angle_diff, vel, x, y, is_before];
response    =  sdf_values_org;

features(ind_excluded, :) = [];
response(ind_excluded) = [];

regOut.name = name_tag;
regOut.features = features;
regOut.feature_names = {'movement_direction', 'head_direction', 'angle_difference','velocity', 'x', 'y', 'before'};
regOut.response = response;

theta_1               =           angle_diff(not_nan & is_before);
firing_rate_1       =           sdf_values_org((not_nan & is_before));

% Bin theta into equally spaced bins
 % [~, bin_idx] = histcounts(theta_1, edges); % Assign each theta to a bin
% Get the bin index for each data point
bin_idx = discretize(theta_1, bin_edges);
bin_idx(~isnan(bin_idx))=bin_idx(~isnan(bin_idx))+1;
bin_idx(isnan(bin_idx)) = 1; 
% Compute mean firing rate for each bin
tuning_curve1 = zeros(1, num_bins); % Initialize tuning curve
tuning_curve1ci = NaN*ones(2, num_bins); % Initialize tuning curve
for i = 1:num_bins
    rates = firing_rate_1(bin_idx == i);
    tuning_curve1(i) = mean(rates); % Mean firing rate for each bin
    if sum(bin_idx == i)>10
        tuning_curve1ci (:, i) = bootci(1000, @mean, rates);
    end
end

% Add first bin to the end for circular plot
tuning_curve1 = [tuning_curve1, tuning_curve1(1)];
tuning_curve1ci = [tuning_curve1ci, tuning_curve1ci(:,1)];

% Plot the tuning curve
ha1 = polaraxes;
polarplot(bin_centers2, tuning_curve1, 'LineWidth', 1, 'color', 'b', 'marker', 'o', 'markerfacecolor', 'b', 'markeredgecolor','w');
hold on
ci_upper = tuning_curve1ci(1, :);
ci_lower= tuning_curve1ci(2, :);
% Now add radial error bars:
for i = 1:length(bin_centers2)
    % For each point, plot a line from (r - err) to (r + err).
    % This draws a "vertical" line in the polar coordinate sense.
    polarplot([bin_centers2(i) bin_centers2(i)], ...
        [ci_upper(i) ci_lower(i)], ...
        'b-', 'LineWidth', 1);
end
ha1.ThetaTick = 0:45:360-45;
hold off

title('Turning angle (to lever)', 'fontsize', 9);
ha1.Units = 'Centimeters';
ha1.Position=[xpos ypos plotSize];
ha1.FontName = 'arial';
ha1.FontSize = 7;

theta_2 =angle_diff(not_nan & ~is_before);
firing_rate_2 = sdf_values_org((not_nan & ~is_before));
% Bin theta into equally spaced bins
bin_edges = linspace(-pi, pi, num_bins+1); % Bin edges
% [~, bin_idx] = histcounts(theta_1, edges); % Assign each theta to a bin
% Get the bin index for each data point
bin_idx = discretize(theta_2, bin_edges);
bin_idx(~isnan(bin_idx))=bin_idx(~isnan(bin_idx))+1;
bin_idx(isnan(bin_idx)) = 1; 
% Compute mean firing rate for each bin
tuning_curve2 = zeros(1, num_bins); % Initialize tuning curve
tuning_curve2ci = NaN*ones(2, num_bins); % Initialize tuning curve
for i = 1:num_bins
    tuning_curve2(i)        = mean(firing_rate_2(bin_idx == i)); % Mean firing rate for each bin
    if sum(bin_idx == i)>10
        tuning_curve2ci (:, i) = bootci(1000, @mean, firing_rate_2(bin_idx == i));
    end
end

% Add first bin to the end for circular plot
tuning_curve2= [tuning_curve2, tuning_curve2(1)];
tuning_curve2ci = [tuning_curve2ci, tuning_curve2ci(:,1)];

% Plot the tuning curve
ha2 = polaraxes;
polarplot(bin_centers2, tuning_curve2, 'LineWidth', 1, 'color', 'b', 'marker', 'o', 'markerfacecolor', 'b', 'markeredgecolor','w');
hold on
ci_upper = tuning_curve2ci(1, :);
ci_lower= tuning_curve2ci(2, :);
% Now add radial error bars:
for i = 1:length(bin_centers2)
    % For each point, plot a line from (r - err) to (r + err).
    % This draws a "vertical" line in the polar coordinate sense.
    polarplot([bin_centers2(i) bin_centers2(i)], ...
        [ci_upper(i) ci_lower(i)], ...
        'b-', 'LineWidth', 1);
end
ha2.ThetaTick = 0:45:360-45;
hold off

title('(from lever)', 'fontsize', 9);
ha2.Units = 'Centimeters';
xpos = xpos+plotSize(1)+2;
ha2.Position=[xpos ypos plotSize];
ha2.FontName = 'arial';
ha2.FontSize = 7;
 
% all combined
theta_0 =angle_diff(not_nan);
firing_rate_0 = sdf_values_org((not_nan));
% Bin theta into equally spaced bins
bin_edges = linspace(-pi, pi, num_bins+1); % Bin edges
% [~, bin_idx] = histcounts(theta_1, edges); % Assign each theta to a bin
% Get the bin index for each data point
bin_idx = discretize(theta_0, bin_edges);
bin_idx(~isnan(bin_idx))=bin_idx(~isnan(bin_idx))+1;
bin_idx(isnan(bin_idx)) = 1; 
% Compute mean firing rate for each bin
tuning_curve0 = zeros(1, num_bins); % Initialize tuning curve
tuning_curve0ci = NaN*ones(2, num_bins); % Initialize tuning curve

for i = 1:num_bins
    tuning_curve0(i) = mean(firing_rate_0(bin_idx == i)); % Mean firing rate for each bin
    if sum(bin_idx == i)>10
        tuning_curve0ci (:, i) = bootci(1000, @mean, firing_rate_0(bin_idx == i));
    end
end

% Add first bin to the end for circular plot
tuning_curve0 = [tuning_curve0, tuning_curve0(1)];
tuning_curve0ci = [tuning_curve0ci, tuning_curve0ci(:,1)];

% Plot the tuning curve
ha3 = polaraxes;
polarplot(bin_centers2, tuning_curve0, 'LineWidth', 1, 'color', 'b', 'marker', 'o', 'markerfacecolor', 'b', 'markeredgecolor','w');
hold on
ci_upper = tuning_curve0ci(1, :);
ci_lower= tuning_curve0ci(2, :);
% Now add radial error bars:
for i = 1:length(bin_centers2)
    % For each point, plot a line from (r - err) to (r + err).
    % This draws a "vertical" line in the polar coordinate sense.
    polarplot([bin_centers2(i) bin_centers2(i)], ...
        [ci_upper(i) ci_lower(i)], ...
        'b-', 'LineWidth', 1);
end
ha3.ThetaTick = 0:45:360-45;
hold off
title('(Combined)', 'fontsize', 9);
ha3.Units = 'Centimeters';
xpos = xpos+plotSize(1)+2;
ha3.Position=[xpos ypos plotSize];
ha3.FontName = 'arial';
ha3.FontSize = 7;

rate_max = max([tuning_curve1 tuning_curve2 tuning_curve0]);
ha1.RLim = [0 rate_max*1.1];
ha2.RLim = [0 rate_max*1.1];
ha3.RLim = [0 rate_max*1.1];

tosavefolder = fullfile(pwd, 'Figures_Motion');
if ~exist(tosavefolder, 'dir')
    mkdir(tosavefolder);
end
tosavename = ['TrajectoryFiringRateMap_' name_tag];
tosavename = fullfile(tosavefolder, tosavename);
print (hf,'-dpng', tosavename)
% print (hf,'-depsc2', tosavename)
print (hf,'-dpdf', tosavename)
savefig([tosavename '.fig']);

tosavename = ['Tuning_' name_tag];
tosavename = fullfile(tosavefolder, tosavename);
print (hf2,'-dpng', tosavename)
% print (hf,'-depsc2', tosavename)
print (hf2,'-dpdf', tosavename)
savefig([tosavename '.fig']);

tosavename = ['regOut' name_tag '.mat'];
tosavename = fullfile(tosavefolder, tosavename);
save(tosavename, 'regOut')
%% Method 4 | Plot acceleration direction
study_acce = 0;
if study_acce
    ddx = TrajTableAll.d2x; % x positions
    ddy = -TrajTableAll.d2y; % y positions
    is_before = ~TrajTableAll.BeforePress;
    theta = atan2(ddx, ddy); % Convert to angles.

    vel = TrajTableAll.velocity;
    % not considering very slow movement
    theta(vel<quantile(vel, .5))=NaN;
    not_nan = ~isnan(theta);

    hf3 = 32;
    figure(hf3); clf(hf3)
    set(hf3, 'units', 'pixels', 'position', [100 100 700 260], 'name', 'acceleration')

    theta_1 =theta(not_nan & is_before);
    firing_rate_1 = sdf_values_org((not_nan & is_before));
    % Bin theta into equally spaced bins
    num_bins = 16; % Number of bins
    bin_edges = linspace(-pi, pi, num_bins+1); % Bin edges
    % [~, bin_idx] = histcounts(theta_1, edges); % Assign each theta to a bin
    % Get the bin index for each data point
    bin_idx = discretize(theta_1, bin_edges);

    % Compute mean firing rate for each bin
    tuning_curve = zeros(1, num_bins); % Initialize tuning curve
    for i = 1:num_bins
        tuning_curve(i) = mean(firing_rate_1(bin_idx == i)); % Mean firing rate for each bin
    end

    % Add first bin to the end for circular plot
    tuning_curve = [tuning_curve, tuning_curve(1)];
    bin_centers = bin_edges(1:end-1) + diff(bin_edges)/2; % Compute bin centers
    bin_centers = [bin_centers, bin_centers(1)]; % Add first bin center to close the circle

    % Plot the tuning curve
    ha1 = polaraxes;
    polarplot(bin_centers, tuning_curve, 'LineWidth', 2);
    title('Acceleration Tuning Curve (to lever)');
    ha1.Position=[-0.1 .1  .5 .6];

    theta_2 =theta(not_nan & ~is_before);
    firing_rate_2 = sdf_values_org((not_nan & ~is_before));
    % Bin theta into equally spaced bins
    num_bins = 16; % Number of bins
    bin_edges = linspace(-pi, pi, num_bins+1); % Bin edges
    % [~, bin_idx] = histcounts(theta_1, edges); % Assign each theta to a bin
    % Get the bin index for each data point
    bin_idx = discretize(theta_2, bin_edges);

    % Compute mean firing rate for each bin
    tuning_curve2 = zeros(1, num_bins); % Initialize tuning curve
    for i = 1:num_bins
        tuning_curve2(i) = mean(firing_rate_2(bin_idx == i)); % Mean firing rate for each bin
    end

    % Add first bin to the end for circular plot
    tuning_curve2= [tuning_curve2, tuning_curve2(1)];
    bin_centers = bin_edges(1:end-1) + diff(bin_edges)/2; % Compute bin centers
    bin_centers = [bin_centers, bin_centers(1)]; % Add first bin center to close the circle

    % Plot the tuning curve
    ha2 = polaraxes;
    polarplot(bin_centers, tuning_curve2, 'LineWidth', 2);
    title('Acceleration Tuning Curve (from lever)');
    ha2.Position=[0.2 .1  .5 .6];

    % all combined
    theta_0 =theta(not_nan);
    firing_rate_0 = sdf_values_org((not_nan));
    % Bin theta into equally spaced bins
    num_bins = 16; % Number of bins
    bin_edges = linspace(-pi, pi, num_bins+1); % Bin edges
    % [~, bin_idx] = histcounts(theta_1, edges); % Assign each theta to a bin
    % Get the bin index for each data point
    bin_idx = discretize(theta_0, bin_edges);

    % Compute mean firing rate for each bin
    tuning_curve0 = zeros(1, num_bins); % Initialize tuning curve
    for i = 1:num_bins
        tuning_curve0(i) = mean(firing_rate_0(bin_idx == i)); % Mean firing rate for each bin
    end

    % Add first bin to the end for circular plot
    tuning_curve0 = [tuning_curve0, tuning_curve0(1)];
    bin_centers = bin_edges(1:end-1) + diff(bin_edges)/2; % Compute bin centers
    bin_centers = [bin_centers, bin_centers(1)]; % Add first bin center to close the circle

    % Plot the tuning curve
    ha3 = polaraxes;
    polarplot(bin_centers, tuning_curve0, 'LineWidth', 2);
    title('(Combined)');
    ha3.Position=[0.5 .1 .5 .6];
end
