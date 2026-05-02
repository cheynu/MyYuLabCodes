function [areas, cluster_idx, cluster_centers,  avg_silhouette,dbi] = determine_turning_x(xys)
% Used in PlotTrajectorySpikes_v2.m
% See a script in
% Opto_Paper/VideoEphys/ANMs/DLS/Lunar/20230321/TrajectoryAnalysis.m

areas = zeros(1, length(xys));

for i =1:length(xys)

    if ~isempty(xys{i})

        x=xys{i}(:, 1);
        y=xys{i}(:, 2);

        ind_nan = isnan(x) | isnan(y);
        x=x(~ind_nan);
        y=y(~ind_nan);

        x0=x(1);
        x1 = x(end);

        y0=y(1);
        y1 = y(end);

        % this is the linear line linking beginning and end of this trajectory
        % y = mx+c
        m = (y1-y0)/(x1-x0);
        c = y0-m*x0;
        x_line = x;
        y_line = m*x_line+c;

        area_above = trapz(x, max(0, y - y_line)); % Integrate the positive difference
        areas(i) = area_above;
    else
        areas(i) = NaN;
    end
end
% sprintf('area above the line is %2.2f', area_above)

% Example 1D data
data = areas';
k = 2; % Number of clusters

% Perform k-means clustering
[cluster_idx, cluster_centers] = kmeans(data(:), k);

% Sort cluster centers
[cluster_centers, sort_idx] = sort(cluster_centers);
% Reassign cluster indices based on sorted centers
cluster_idx = arrayfun(@(x) find(sort_idx == x), cluster_idx);

% Compute silhouette scores
silhouette_values = silhouette(data(:), cluster_idx);

% Average silhouette score
avg_silhouette = mean(silhouette_values);

fprintf('Average silhouette score: %.2f\n', avg_silhouette)

if avg_silhouette<0.5
    fprintf('There is only one cluster')
    cluster_idx= ones(1,length(areas));
else
    % Compute intra-cluster distances
    intra_dist = zeros(k, 1);
    for i = 1:k
        intra_dist(i) = mean(pdist2(data(cluster_idx == i), cluster_centers(i)));
    end
    
    % Compute inter-cluster distances
    inter_dist = pdist(cluster_centers);
    
    % Compute DBI
    dbi = mean((intra_dist(1) + intra_dist(2)) / inter_dist);
    fprintf('Davies-Bouldin Index: %.2f\n', dbi)
    
    
    figure(11); clf(11)
    scatter(data, zeros(size(data)), 50, cluster_idx, 'filled');
    hold on;
    plot(cluster_centers, [0, 0], 'rx', 'MarkerSize', 10, 'LineWidth', 2);
    legend('Data points', 'Cluster centers');
    xlabel('Data'); title('1D Clustering');
    grid on;
end