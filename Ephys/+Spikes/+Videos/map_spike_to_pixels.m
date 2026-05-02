function [rate_map, isvalid, integral_map, occupancy_map] = map_spike_to_pixels(t, sdf_in, t_traj, x_traj, y_traj, x_bins, y_bins)
% Jianing Yu 2025.09.03
% Jianing Yu revision 2025.11.07
% Inputs:
% - t: Time vector for SDF (seconds)
% - sdf_in: Spike density function (firing rate in Hz at each t)% - t_traj: Time vector for trajectory (seconds)
% - x_traj: x-coordinates at t_traj (e.g., in cm)
% - y_traj: y-coordinates at t_traj (e.g., in cm)
% - x_bins: Predefined x bin edges (e.g., in cm)
% - y_bins: Predefined y bin edges (e.g., in cm)
% Initialize rate map
n_xbins = length(x_bins) - 1;
n_ybins = length(y_bins) - 1;
rate_map = NaN(n_ybins, n_xbins); % Rows: y-bins, Columns: x-bins
integral_map = NaN(n_ybins, n_xbins);
occupancy_map = NaN(n_ybins, n_xbins);
% Calculate speed between consecutive points
dt_traj = diff(t_traj);
dx = diff(x_traj);
dy = diff(y_traj);
distances = sqrt(dx.^2 + dy.^2); % Euclidean distance
speed = distances ./ dt_traj; % Speed in cm/s (or units/s)
is_interpolated = false(size(x_traj));

% Identify interpolated segments (constant speed over 50+ bins)
min_consecutive_bins = 50;
for i = 1:length(speed) - min_consecutive_bins + 1
    if all(abs(speed(i:i+min_consecutive_bins-1) - speed(i)) < 1e-6)
        is_interpolated(i:i+min_consecutive_bins-1) = true;
    end
end

% Exclude interpolated segments
valid_mask = ~is_interpolated;
t_traj_valid = t_traj(valid_mask);
x_traj_valid = x_traj(valid_mask);
y_traj_valid = y_traj(valid_mask);

isvalid.t_org = t_traj;
isvalid.t = t_traj_valid;
isvalid.x = x_traj_valid;
isvalid.y = y_traj_valid;
isvalid.x_org = x_traj;
isvalid.y_org = y_traj;
isvalid.index = valid_mask;

% Initialize output arrays
x_at_t = NaN(size(t));
y_at_t = NaN(size(t));

% Find valid segments (contiguous valid trajectory points)
dt_traj = diff([t_traj_valid; t_traj_valid(end)]); % Approximate last dt
gap_threshold = median(dt_traj) * 2; % Consider gaps larger than 2x median dt as breaks
segment_starts = [1; find(dt_traj > gap_threshold) + 1];
segment_ends = [find(dt_traj > gap_threshold); length(t_traj_valid)];

too_short = find(segment_ends-segment_starts<10);
segment_starts(too_short) = [];
segment_ends(too_short) = [];

if isempty(segment_starts)
    return
end

if false
figure(11); clf(11)
subplot(3, 1, 1)
scatter(x_traj, y_traj, 'ko');
hold on
scatter(x_traj_valid, y_traj_valid, 'r+')
subplot(3, 1, 2)
scatter(t_traj, x_traj, 'ko');
hold on
scatter(t_traj_valid, x_traj_valid, 'r+')
xline(t_traj_valid(segment_starts), 'Color','m')
xline(t_traj_valid(segment_ends), 'Color','b')

subplot(3, 1, 3)
scatter(t_traj, y_traj, 'ko');
hold on
scatter(t_traj_valid, y_traj_valid, 'r+')
xline(t_traj_valid(segment_starts), 'Color','m')
xline(t_traj_valid(segment_ends), 'Color','b')

hold off
end

% Interpolate within each valid segment
for seg = 1:length(segment_starts)
    idx = segment_starts(seg):segment_ends(seg);
    t_seg = t_traj_valid(idx);
    x_seg = x_traj_valid(idx);
    y_seg = y_traj_valid(idx);
    
    % Find SDF times within this segment's time range
    seg_mask = t >= min(t_seg) & t <= max(t_seg);
    
    % Interpolate only for times within this segment (using 'linear', no extrapolation)
    if ~isempty(t_seg) && length(t_seg)>1
        x_at_t(seg_mask) = interp1(t_seg, x_seg, t(seg_mask), 'linear');
        y_at_t(seg_mask) = interp1(t_seg, y_seg, t(seg_mask), 'linear');
    end
end

% Calculate time differences (dt) for weighting
if all(abs(diff(t) - (t(2) - t(1))) < 1e-6) % Check for uniform sampling
    dt = (t(2) - t(1)) * ones(size(t));
else
    dt = diff([t(1); t]); % Approximate first dt, assumes t is sorted
end

% Compute spike rate for each bin
for i = 1:n_xbins
    for j = 1:n_ybins
        % Define pixel boundaries
        x_min = x_bins(i);
        x_max = x_bins(i+1);
        y_min = y_bins(j);
        y_max = y_bins(j+1);        
        % Identify times where position is within the pixel and valid
        pixel_mask = (x_at_t >= x_min) & (x_at_t < x_max) & ...
                     (y_at_t >= y_min) & (y_at_t < y_max) & ...
                     ~isnan(x_at_t) & ~isnan(y_at_t);
        
        % Compute occupancy time
        occupancy_time = sum(dt(pixel_mask));
        occupancy_map(j, i) = occupancy_time;

        % Compute average spike rate (weighted mean of SDF in the pixel)
        if occupancy_time > 0
            this_integral = sum(sdf_in(pixel_mask) .* dt(pixel_mask));
            rate_map(j, i) = this_integral / occupancy_time;
            integral_map(j, i) = this_integral;
        else
            rate_map(j, i) = NaN; % Set to NaN for unvisited pixels
            integral_map(j, i) = NaN;
        end
    end
end

 