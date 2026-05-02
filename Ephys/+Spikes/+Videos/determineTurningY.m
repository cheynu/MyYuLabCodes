function [cluster_idx_to, cluster_idx_from] = determineTurningY(xys, unit_name, numClusters)
% Used in PlotTrajectorySpikes_v2.m
% See a script in
% Opto_Paper/VideoEphys/ANMs/DLS/Lunar/20230321/TrajectoryAnalysis.m
% to_lever_direction = Spikes.Videos.determingTuningY(Trials)

% Trials = cell(length(trial_names), 5); 
% - 1. trial name, 
% - 2. time before press, trajectory before press, 
% - 3. traj mapped before press, 
% - 4. time after press, trajectory after press, 
% - 5. traj mapped after press,
% Trials{iTrial, 2} = [t_i(ind_before_press), x_i(ind_before_press) y_i(ind_before_press)];

% Revised 2025/4/23 JY

if nargin<3
     numClusters = []; % cluster number will be identified with unsupervised method
end

 tPost = 3000;

areas = zeros(1, length(xys)); % this is the area
durations = zeros(1, length(xys)); % this is the time taken from one side to the other side
areas_diff = zeros(1, length(xys)); % this is the difference between area and the area under a straight line connecting beg and end 
 
figure(11); clf(11)
ha0= subplot(3, 2, [1 2]); hold on
ha1=subplot(3, 2, 3); hold on;
ylabel('y')
ha2=subplot(3, 2, 4); hold on;
ylabel('x')
ha3=subplot(3, 2, 5); hold on;
ha4=subplot(3, 2, 6); hold on;

for i =1:length(xys)
    itrial_name = xys{i, 1};
    if ~isempty(xys{i, 2})
        t=xys{i, 2}(:, 1);
        x=xys{i, 2}(:, 2);
        y=xys{i, 2}(:, 3);
        ind_nan = isnan(x) | isnan(y);
        x = x(~ind_nan);
        y = y(~ind_nan);
        t = t(~ind_nan);        

        checkTraj(t, x, y, itrial_name, 'toLever', unit_name); %  check trajectory, make sure there is no abrupt points, if there is, point it out. 

        x1 = x(end);
        y1 = y(end);
        scatter(ha0, x, y, '.')
        plot(ha1, t, y-y1); 
        plot(ha2, t, x-x1);
        [areas(i), areas_diff(i), durations(i)] = computeArea(t, x, y);    
    else
        areas(i) = NaN;
         areas_diff(i) = NaN;
        durations(i) = NaN;
    end
end
  
data = [durations' areas' ];
% there could be 1 or 2 clusters, let's see which one works better
if isempty(numClusters)
    k = evaluate_cluster_number(data);
else
    k = numClusters(1);
end

% Perform k-means clustering
[cluster_idx, ~] = kmeans(data, k);
%
% Plot the data again
for i =1:length(xys)
    if ~isempty(xys{i, 2})
        t=xys{i, 2}(:, 1);
        x=xys{i, 2}(:, 2);
        y=xys{i, 2}(:, 3);

        if cluster_idx(i)==1
            plot(ha3, t, y-y1, 'k');
            plot(ha4, x,y, 'k');
            plot(ha1, t, y-y1, 'k');
            plot(ha2, t, x-x1,'k');
        elseif cluster_idx(i)==2
            plot(ha1, t, y-y1,'r');
            plot(ha2, t, x-x1, 'r');
            plot(ha3, t, y-y1, 'r');
            plot(ha4, x,y, 'r');
        end
    end
end

cluster_idx_to = cluster_idx;

%% Determine the index from the lever
 figure(14); clf(14)

 areas = zeros(1, length(xys)); % this is the area
 areas_diff = zeros(1, length(xys)); % this is the difference between area and the area under a straight line connecting beg and end

 ha0= subplot(3, 2, [1 2]); hold on
 ha1=subplot(3, 2, 3); hold on;
 ylabel('y')
 ha2=subplot(3, 2, 4); hold on;
 ylabel('x')
 ha3=subplot(3, 2, 5); hold on;
 ha4=subplot(3, 2, 6); hold on;

 for i =1:length(xys)
     itrial_name = xys{i, 1};
     if ~isempty(xys{i, 4})
         t=xys{i, 4}(:, 1);
         x=xys{i, 4}(:, 2);
         y=xys{i, 4}(:, 3);
        x = x(t<tPost);
        y = y(t<tPost);
        t = t(t<tPost);
        ind_nan = isnan(x) | isnan(y);
        x = x(~ind_nan);
        y = y(~ind_nan);
        t = t(~ind_nan);

        checkTraj(t, x, y, itrial_name, 'fromLever', unit_name); %  check trajectory, make sure there is no abrupt points, if there is, point it out. 

        if abs(min(x)-max(x))<200
            areas(i) = NaN;
            areas_diff(i) = NaN;
                    durations(i) = NaN;
            continue
        end

        scatter(ha0, x, y, '.')
        plot(ha1, t, y-y1);
        plot(ha2, t, x-x1);
        [areas(i), areas_diff(i), durations(i)] = computeArea(t, x, y);

    else
        areas(i) = NaN;
        areas_diff(i) = NaN;
        durations(i) = NaN;
    end
end

data = [durations' areas' ];
% there could be 1 or 2 clusters, let's see which one works better

if isempty(numClusters)
    k = evaluate_cluster_number(data);
else
    k = numClusters(2);
end

% Perform k-means clustering
[cluster_idx, ~] = kmeans(data, k);
%
% Plot the data again
for i =1:length(xys)
    if ~isempty(xys{i, 4})
        t=xys{i, 4}(:, 1);
        x=xys{i, 4}(:, 2);
        y=xys{i, 4}(:, 3);

        if cluster_idx(i)==1
            plot(ha3, t, y-y1, 'k');
            plot(ha4, x,y, 'k');
            plot(ha1, t, y-y1, 'k');
            plot(ha2, t, x-x1,'k');
        elseif cluster_idx(i)==2
            plot(ha1, t, y-y1,'r');
            plot(ha2, t, x-x1, 'r');
            plot(ha3, t, y-y1, 'r');
            plot(ha4, x,y, 'r');
        end
    end
end
cluster_idx_from = cluster_idx;

end

function [area, area_between, t_travel] = computeArea(t, x, y)

% compute area
% Step 1: Compute bounds
xi = x;
yi =y;
x_min = min(xi);
x_max = max(xi);
a = x_min + 0.1 * (x_max - x_min);
b = x_min + 0.9 * (x_max - x_min);

% Step 2: Sort points by xi to handle non-monotonic data
[xi_sorted, sort_idx] = sort(xi);
yi_sorted = yi(sort_idx);

% Step 3: Filter points within [a, b] or interpolate
x_new = xi_sorted(xi_sorted >= a & xi_sorted <= b);
y_new = yi_sorted(xi_sorted >= a & xi_sorted <= b);

% Step 4: Interpolate at a and b if they are not in x_new
if ~any(x_new == a)
    % Find the interval [xi_sorted(i), xi_sorted(i+1)] containing a
    idx = find(xi_sorted >= a, 1, 'first') - 1;
    if idx > 0 && idx < length(xi_sorted)
        x0 = xi_sorted(idx);
        x1 = xi_sorted(idx + 1);
        y0 = yi_sorted(idx);
        y1 = yi_sorted(idx + 1);
        y_a = y0 + (a - x0) * (y1 - y0) / (x1 - x0); % Linear interpolation
        x_new = [a; x_new];
        y_new = [y_a; y_new];
    else
        % Handle edge case: a is outside sorted xi range
        warning('Bound a is outside the range of xi. Area may be inaccurate.');
    end
end

if ~any(x_new == b)
    % Find the interval [xi_sorted(i), xi_sorted(i+1)] containing b
    idx = find(xi_sorted >= b, 1, 'first') - 1;
    if idx > 0 && idx < length(xi_sorted)
        x0 = xi_sorted(idx);
        x1 = xi_sorted(idx + 1);
        y0 = yi_sorted(idx);
        y1 = yi_sorted(idx + 1);
        y_b = y0 + (b - x0) * (y1 - y0) / (x1 - x0); % Linear interpolation
        x_new = [x_new; b];
        y_new = [y_new; y_b];
    else
        % Handle edge case: b is outside sorted xi range
        warning('Bound b is outside the range of xi. Area may be inaccurate.');
    end
end

% Step 5: Sort x_new and y_new to ensure monotonicity for trapz
[x_new, sort_idx] = sort(x_new);
y_new = y_new(sort_idx);
% Step 6: Compute the area using trapz
area = trapz(x_new, y_new);
% Step 8: Compute the area between the curve and the straight line
% Find y(a) and y(b) from the interpolated points
idx_a = find(x_new == a, 1);
idx_b = find(x_new == b, 1);
y_a = y_new(idx_a);
y_b = y_new(idx_b);
% Equation of the straight line: y_line(x) = m*x + c
m = (y_b - y_a) / (b - a); % Slope
c = y_a - m * a; % Intercept
y_line = m * x_new + c; % y-values of the straight line at x_new
% Compute the area under the line using trapz
area_between = abs(trapz(x_new, y_line))-area;

% determine traveling time from a to b
[~, ind_a] = min(abs(x-a));
[~, ind_b] = min(abs(x-b));

t_travel = abs(t(ind_a) - t(ind_b));
 end

 function checkTraj(t, x, y, trial_name, type, unit_name) %  check trajectory, make sure there is no abrupt points, if there is, point it out. 
        name = [unit_name '_' trial_name];

    dx = diff(x);
    dy = diff(y);
    dt = diff(t);
    dv = sqrt(dx.^2+dy.^2)./dt;

    if any(dv>20)
        sprintf('This %s trial (trial name: %s) is likely not tracked properly', type, trial_name)
        figure(16); clf(16)
        scatter(x, y);
        title(name, 'Interpreter','none')
        if ~exist('BadTracking', 'dir')
            mkdir('BadTracking')
        end
        print(16, '-dpng', fullfile(pwd, 'BadTracking', name))
    end
    % Sample vector (replace with your vector)
 
    % Parameters
    min_run_length = 20; % Minimum number of consecutive elements to consider "prolonged"

    % Exclude zeros from consideration
    non_zero_idx = dv >10^-5; % Logical index for non-zero elements
    dv_non_zero = dv(non_zero_idx); % Keep only non-zero elements
    original_indices = find(non_zero_idx); % Track original indices

    % Find runs of identical consecutive elements
    if isempty(dv_non_zero)
        fprintf('No non-zero elements in dv.\n');
        return;
    end


    % Compute differences to detect changes in value
    diffs = diff(dv_non_zero);
    ind_lows = find(abs(diffs)<10^-5);

    if ~isempty(ind_lows)

        run_starts = [ind_lows(1); ind_lows(find(diff(ind_lows)>1)+1)]; % Indices where new runs start
        run_ends = [ind_lows(find(diff(ind_lows)>1)); ind_lows(end)]; % Indices where runs end
        run_lengths = run_ends - run_starts + 1; % Length of each run
        run_values = dv_non_zero(run_starts); % Value of each run

        % Filter for prolonged runs (length >= min_run_length)
        prolonged_idx = run_lengths >= min_run_length;
        prolonged_values = run_values(prolonged_idx);
        prolonged_starts = run_starts(prolonged_idx);
        prolonged_lengths = run_lengths(prolonged_idx);

        % Display results
        if isempty(prolonged_values)
            fprintf('No prolonged sequences of identical non-zero elements (minimum length %d).\n', min_run_length);
        else
            fprintf('Prolonged sequences of identical non-zero elements (minimum length %d):\n', min_run_length);
            figure(16); clf(16)
            scatter(x, y);
            title(name, 'Interpreter','none')
            if ~exist('BadTracking', 'dir')
                mkdir('BadTracking')
            end
            print(16, '-dpng', fullfile(pwd, 'BadTracking', name));
            for i = 1:length(prolonged_values)
                % Map back to original indices
                start_idx = original_indices(prolonged_starts(i));
                end_idx = original_indices(prolonged_starts(i) + prolonged_lengths(i) - 1);
                fprintf('Value %.2f appears %d times consecutively from index %d to %d\n', ...
                    prolonged_values(i), prolonged_lengths(i), start_idx, end_idx);
            end
        end
    end
 end

function k_out = evaluate_cluster_number(data)
data(isnan(data(:, 1))|isnan(data(:, 2)), :) = [];
% normalize data
data = zscore(data, 0, 1);
% Parameters
k_values = [1, 2];
num_replicates = 10; % Number of kmeans runs to avoid local minima
min_cluster_size = max(5, 0.05 * size(data, 1)); % At least 5 points or 5% of data
wcss = zeros(1, length(k_values));
silhouette_scores = zeros(1, length(k_values));
cluster_sizes = cell(1, length(k_values));

% Run kmeans and evaluate for each k
figure;
for i = 1:length(k_values)
    k = k_values(i);

    % Run kmeans
    [idx, centroids, sumd] = kmeans(data, k, 'Replicates', num_replicates, 'Distance', 'sqeuclidean');

    % Compute WCSS (Within-Cluster Sum of Squares)
    wcss(i) = sum(sumd); % Sum of distances to centroids

    % Compute Silhouette Score
    if k > 1
        sil = silhouette(data, idx, 'sqeuclidean');
        silhouette_scores(i) = mean(sil);
    else
        silhouette_scores(i) = NaN; % Silhouette undefined for k=1
    end

    % Compute cluster sizes
    cluster_sizes{i} = histcounts(idx, 1:k+1);

    % Visualize clusters
    subplot(1, length(k_values), i);
    gscatter(data(:,1), data(:,2), idx, 'br', '+o', 10); % Scatter plot with cluster labels
    hold on;
    plot(centroids(:,1), centroids(:,2), 'kx', 'MarkerSize', 35, 'LineWidth', 2); % Centroids
    title(sprintf('k = %d\nWCSS: %.2f\nSilhouette: %.3f\nSizes: %s', ...
        k, wcss(i), silhouette_scores(i), num2str(cluster_sizes{i})));
    xlabel('duration'); ylabel('area');
    grid on;
    hold off;
end

% Compute WCSS drop percentage
wcss_drop = (wcss(1) - wcss(2)) / wcss(1) * 100;
% Check if k=2 has any small clusters
small_cluster = any(cluster_sizes{2} < min_cluster_size);

% Display results
fprintf('Evaluation Metrics:\n');
for i = 1:length(k_values)
    fprintf('k = %d:\n', k_values(i));
    fprintf('  WCSS: %.2f\n', wcss(i));
    fprintf('  Silhouette Score: %.3f\n', silhouette_scores(i));
    fprintf('  Cluster Sizes: %s\n', num2str(cluster_sizes{i}));
end
fprintf('WCSS Drop from k=1 to k=2: %.2f%%\n', wcss_drop);
fprintf('Minimum Cluster Size Threshold: %d points\n', round(min_cluster_size));

% Suggest optimal k
if wcss_drop > 30 && silhouette_scores(2) > 0.4 && ~small_cluster
    fprintf('Recommendation: k = 2 (large WCSS drop, high Silhouette, and balanced clusters).\n');
    k_out = 2;
else
    fprintf('Recommendation: k = 1 (small clusters, low Silhouette, or small WCSS drop).\n');
    if small_cluster
        fprintf('Reason: k=2 has a cluster with fewer than %d points.\n', round(min_cluster_size));
    end
    k_out = 1;
end
end