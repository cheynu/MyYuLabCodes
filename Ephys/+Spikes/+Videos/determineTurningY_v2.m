function [cluster_idx_to, cluster_idx_from] = determineTurningY(xys)
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

tPre = 4500;
tPost = 3000;

areas = zeros(1, length(xys));

figure(11); clf(11)
ha0= subplot(3, 2, [1 2]); hold on
ha1=subplot(3, 2, 3); hold on;
ylabel('y')
ha2=subplot(3, 2, 4); hold on;
ylabel('x')
ha3=subplot(3, 2, 5); hold on;
ha4=subplot(3, 2, 6); hold on;

for i =1:length(xys)

    if ~isempty(xys{i, 2})

        t=xys{i, 2}(:, 1);
        x=xys{i, 2}(:, 2);
        y=xys{i, 2}(:, 3);


        x = x(t>-tPre);
        y = y(t>-tPre);
        t = t(t>-tPre);

        ind_nan = isnan(x) | isnan(y);
        x = x(~ind_nan);
        y = y(~ind_nan);
        t = t(~ind_nan);
        
        x1 = x(end);
        y1 = y(end);

        scatter(ha0, x1, y1, '.')

        plot(ha1, t, y-y1); 
        plot(ha2, t, x-x1);
        areas(i) = trapz(t, y-y1);
    else
        areas(i) = NaN;
    end
end
% sprintf('area above the line is %2.2f', area_above)

% Example 1D data
data = areas';
data_ = data(~isnan(data));
same_sign = all(sign(data_) == sign(data_(1)));

if same_sign
    k = 1;
else
    if sum(sign(data_)==1)/length(data_)>0.1 && sum(sign(data_)==-1)/length(data_)>0.1
        k = 2;
    else
        k = 1;
    end
end

% Perform k-means clustering

[cluster_idx, cluster_centers] = kmeans(data(:), k);

% Plot the data again
for i =1:length(xys)

    if ~isempty(xys{i, 2})

        t=xys{i, 2}(:, 1);
        x=xys{i, 2}(:, 2);
        y=xys{i, 2}(:, 3);

        if cluster_idx(i)==1
            plot(ha3, t, y-y1, 'k');
            plot(ha4, x,y, 'k');
        elseif cluster_idx(i)==2
            plot(ha3, t, y-y1, 'r');
            plot(ha4, x,y, 'r');
        end
    end
end

% Compute silhouette scores
silhouette_values = silhouette(data(:), cluster_idx);

% Average silhouette score
avg_silhouette = mean(silhouette_values, 'omitnan');

fprintf('Average silhouette score: %.2f\n', avg_silhouette)

% Compute intra-cluster distances
intra_dist = zeros(k, 1);
for i = 1:k
    intra_dist(i) = mean(pdist2(data(cluster_idx == i), cluster_centers(i)));
end

figure(13); clf(13)
scatter(data, zeros(size(data)), 50, cluster_idx, 'filled');
hold on;
plot(cluster_centers, [0, 0], 'rx', 'MarkerSize', 10, 'LineWidth', 2);
legend('Data points', 'Cluster centers');
xlabel('Data'); title('1D Clustering (from lever)');
grid on;

cluster_idx_to = cluster_idx;
%% Determine the index from the lever
distance = zeros(1, length(xys));
figure(14); clf(14)
ha1=subplot(2, 2, 1); hold on;
ha2=subplot(2, 2, 2); hold on;
ha3=subplot(2, 2, 3); hold on;
ha4=subplot(2, 2, 4); hold on;

for i =1:length(xys)
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

        if length(x)>10

            x1 = x(1);
            xn = x(end);
            y1 = y(1);
            yn = y(end);

            % Slope of the line (handle vertical line case)
            if xn ~= x1
                m = (yn - y1) / (xn - x1); % Slope
                b = y1 - m * x1;           % y-intercept
                line_eq = @(x) m * x + b;  % Line equation y = mx + b
            else
                % Vertical line: x = x1
                line_eq = @(x) x1; % Not a function of y, handled separately
            end

            % Step 2: Compute perpendicular distances
            n = length(x); % Number of points
            signed_distances = zeros(1, n); % Store distances

            for ii = 1:n
                if xn ~= x1
                    % Distance from point (x(i), y(i)) to line y = mx + b
                    % Formula: |Ax + By + C| / sqrt(A^2 + B^2), where Ax + By + C = 0
                    % For y = mx + b, rewrite as mx - y + b = 0
                    A = m;
                    B = -1;
                    C = b;
                    signed_distances(ii) = (A * x(ii) + B * y(ii) + C) / sqrt(A^2 + B^2);
                else
                    % Vertical line: distance is horizontal distance to x = x1
                    signed_distances(ii) = (x(ii) - x1);
                end
            end

            [max_abs_distance, max_idx] = max(abs(signed_distances));
            most_distant_x = x(max_idx);
            most_distant_y = y(max_idx);
            most_distant_signed = signed_distances(max_idx);

            distance(i) = most_distant_signed;

        else
            distance(i) = NaN;
        end
    else
        distance(i) = NaN;
    end
end
% sprintf('area above the line is %2.2f', area_above)

% Example 1D data
data = distance';
data_ = data(~isnan(data));
same_sign = all(sign(data_) == sign(data_(1)));

if same_sign
    k = 1;
else
    if sum(sign(data_)==1)/length(data_)>0.1 && sum(sign(data_)==-1)/length(data_)>0.1
        k = 2;
    else
        k = 1;
    end
end

% Perform k-means clustering

[cluster_idx, cluster_centers] = kmeans(data(:), k);

% Plot the data again
for i =1:length(xys)

    if ~isempty(xys{i, 4})

        t=xys{i, 4}(:, 1);
        x=xys{i, 4}(:, 2);
        y=xys{i, 4}(:, 3);

        if cluster_idx(i)==1
            plot(ha3, t, y-y1, 'k');
            plot(ha4, x,y, 'k');
        elseif cluster_idx(i)==2
            plot(ha3, t, y-y1, 'r');
            plot(ha4, x,y, 'r');
        end
    end
end

% Compute silhouette scores
silhouette_values = silhouette(data(:), cluster_idx);

% Average silhouette score
avg_silhouette = mean(silhouette_values, 'omitnan');

fprintf('Average silhouette score (from lever): %.2f\n', avg_silhouette)

% Compute intra-cluster distances
intra_dist = zeros(k, 1);
for i = 1:k
    intra_dist(i) = mean(pdist2(data(cluster_idx == i), cluster_centers(i)));
end

figure(16); clf(16)
scatter(data, zeros(size(data)), 50, cluster_idx, 'filled');
hold on;
plot(cluster_centers, [0, 0], 'rx', 'MarkerSize', 10, 'LineWidth', 2);
legend('Data points', 'Cluster centers');
xlabel('Data'); title('1D Clustering');
grid on;
cluster_idx_from = cluster_idx;


end