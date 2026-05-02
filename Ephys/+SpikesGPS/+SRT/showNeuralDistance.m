function fig_dist = showNeuralDistance(r)

plt = GPSPlot();

% cluster spikes by waveform, get regular good spikes
regular_file = dir('RegularIndex*.mat');
if ~isempty(regular_file)
    load(regular_file.name, 'RegularIndex');
else
    RegularIndex = clusterSpikes(r, 'PeakTrough');
end

%% 
t_sample = 1:1500;
n_sample = 1500;
n_unit = length(RegularIndex.Good);
% [~, ~, ind_sort] = cellfun(@(x) unique(x(ismember(x, RegularIndex.Good)), 'sorted'), r.popSDFWarped.IndSort, 'UniformOutput', false);

note = r.Units.SpikeNotes(:, 1:2);
for i = 1:n_unit
    sdf_out = SpikesGPS.SRT.ComputeSDFWarped(r, note(RegularIndex.Good(i),:), 0);
    t_warp = sdf_out.SDFWarp.t_warp;
    sdf_contra_i = sdf_out.SDFWarp.sdf_warp{3,1}(:, t_warp{3,1}>0 & t_warp{3,1}<=n_sample)';
    sdf_ipsi_i   = sdf_out.SDFWarp.sdf_warp{3,2}(:, t_warp{3,2}>0 & t_warp{3,2}<=n_sample)';

    if i==1
        n_trial_contra = size(sdf_contra_i, 2);
        sdf_contra = zeros([n_unit n_sample n_trial_contra]); % n_unit * n_sample * n_trial
        n_trial_ipsi = size(sdf_ipsi_i, 2);
        sdf_ipsi   = zeros([n_unit n_sample n_trial_ipsi]);
    end
    sdf_contra(i,:,:) = sdf_contra_i;
    sdf_ipsi(i,:,:)   = sdf_ipsi_i;
end
sdf_hold = cat(3, sdf_contra, sdf_ipsi);

side = [ones(1, n_trial_contra) 2*ones(1, n_trial_ipsi)];

sdf_contra_m = mean(sdf_contra, 3);
sdf_ipsi_m   = mean(sdf_ipsi, 3);

%% Distance between
side_dist = pdist2(sdf_contra_m', sdf_ipsi_m', 'euclidean') ./ sqrt(n_unit);
side_dist = diag(side_dist);

sdf_contra_norm = sdf_contra_m;
sdf_ipsi_norm = sdf_ipsi_m;
for i = 1:n_unit
    sdf_norm = cal_soft_norm([sdf_contra_m(i,:) sdf_ipsi_m(i,:)]);
    sdf_contra_norm(i,:) = sdf_norm(1:n_sample);
    sdf_ipsi_norm(i,:) = sdf_norm(n_sample+1:end);
end
coef_hold = pca([sdf_contra_norm'; sdf_ipsi_norm']);
pc_contra = (sdf_contra_norm' * coef_hold(:, [1 2]))';
pc_ipsi   = (sdf_ipsi_norm' * coef_hold(:, [1 2]))';

n_perm = 200;
side_dist_perm = zeros(n_perm, length(side_dist));
pc1_contra_perm = zeros(n_perm, size(pc_contra, 2));
pc2_contra_perm = zeros(n_perm, size(pc_contra, 2));
pc1_ipsi_perm   = zeros(n_perm, size(pc_ipsi, 2));
pc2_ipsi_perm   = zeros(n_perm, size(pc_ipsi, 2));

for i = 1:n_perm
    side_perm = side(randperm(length(side)));
    sdf_contra_perm = mean(sdf_hold(:,:,side_perm==1), 3);
    sdf_ipsi_perm   = mean(sdf_hold(:,:,side_perm==2), 3);

    side_dist_perm_i    = pdist2(sdf_contra_perm', sdf_ipsi_perm', 'euclidean') ./ sqrt(n_unit);
    side_dist_perm(i,:) = diag(side_dist_perm_i);

    for n = 1:n_unit
        sdf_norm_perm = cal_soft_norm([sdf_contra_perm(n,:) sdf_ipsi_perm(n,:)]);
        sdf_contra_perm(n,:) = sdf_norm_perm(1:n_sample);
        sdf_ipsi_perm(n,:) = sdf_norm_perm(n_sample+1:end);
    end

    pc1_contra_perm(i,:) = sdf_contra_perm' * coef_hold(:, 1);
    pc2_contra_perm(i,:) = sdf_contra_perm' * coef_hold(:, 2);
    pc1_ipsi_perm(i,:)   = sdf_ipsi_perm' * coef_hold(:, 1);
    pc2_ipsi_perm(i,:)   = sdf_ipsi_perm' * coef_hold(:, 2);
end

side_dist_ci = prctile(side_dist_perm, [99.5 0.5]);

%% Figure
fig_dist = figure(87); clf(fig_dist);
set_fig_default(fig_dist);
set(fig_dist, 'Name', 'Neural distance', 'Position', [5 5 11 8]);
set_fig_title(fig_dist, sprintf('%s | %s', r.BehaviorClass.Subject, r.BehaviorClass.Session));

%% plot neural distance between contra and ipsi
% 2D visualization
ax_side_pc = plt.assign_ax_to_fig(fig_dist, 1, 1, [.75 1 3 3], [3 3]);
ax = ax_side_pc{1};
set(ax, 'CLim', [0 n_sample], 'XColor', 'none', 'YColor', 'none');

cmap_contra = customcolormap_preset_z('red-light');
cmap_contra = resizeColormap(cmap_contra, n_sample);
cmap_ipsi = customcolormap_preset_z('blue-light');
cmap_ipsi = resizeColormap(cmap_ipsi, n_sample);
cmap_perm = colormap('gray');
cmap_perm = resizeColormap(cmap_perm(50:220,:), n_sample);

id_perm = randperm(n_perm, 5);
for i = 1:length(id_perm)
    scatter(ax, pc1_contra_perm(id_perm(i), :), pc2_contra_perm(id_perm(i), :), 8, flipud(cmap_perm), 'filled', 'MarkerFaceAlpha', .6);
    scatter(ax, pc1_ipsi_perm(id_perm(i), :), pc2_ipsi_perm(id_perm(i), :), 8, flipud(cmap_perm), 'filled', 'MarkerFaceAlpha', .6);
end

scatter(ax, pc_contra(1, :), pc_contra(2, :), 8, cmap_contra, 'filled', 'MarkerFaceAlpha', .6);
scatter(ax, pc_ipsi(1, :), pc_ipsi(2, :), 8, cmap_ipsi, 'filled', 'MarkerFaceAlpha', .6);

colormap(ax, flipud(cmap_perm));
ax.YLim = ax.XLim;

cb_side = colorbar(ax, 'Units', 'centimeters', 'Position', [4 1 .25 2], 'TickDirection', 'out', 'FontSize', 7);
cb_side.Label.String = "Time to Cent-In (ms)";
cb_side.Label.FontSize = 7;

% distance vs. permutation
ax_side_dist = plt.assign_ax_to_fig(fig_dist, 1, 1, [6.5 1 3 3], [3 2]);
ax = ax_side_dist{1};

fill(ax, [t_sample fliplr(t_sample)], [side_dist_ci(1,:) fliplr(side_dist_ci(2,:))], 'k', 'FaceAlpha', .1, 'EdgeAlpha', .2);
plot(ax, t_sample, side_dist, '-k', 'LineWidth', 1.5);

xlabel(ax, "Time to Cent-In (ms)");
ylabel(ax, "Neural distance (Hz)");


%% Distance traveled
n_contra = sum(side==1);
n_ipsi = sum(side==2);
n_trials = n_contra + n_ipsi;

travel_dist = pdist2(mean(sdf_hold, 3)', mean(sdf_hold, 3)', 'euclidean') ./ sqrt(n_unit); % Hz
% travel_dist = travel_dist + diag(nan(1,n_sample));

% travel_dist_trial = zeros(n_sample, n_sample, n_trials);
% for i = 1:n_trials
%     sdf_i = sdf_hold(:,:,i);
%
%     travel_dist_i = pdist2(sdf_i', sdf_i', 'euclidean') ./ sqrt(n_unit); % Hz
%     travel_dist_i = travel_dist_i + diag(nan(1,n_sample));
%     travel_dist_trial(:,:,i) = travel_dist_i;
% end
n_boot = 200;
travel_dist_boot = zeros(n_boot, n_sample);
for i = 1:n_boot
    id_boot = randi(n_trials, n_trials, 1);
    travel_dist_boot(i,:) = pdist2(mean(sdf_hold(:,1,id_boot), 3)', mean(sdf_hold(:,:,id_boot), 3)', 'euclidean') ./ sqrt(n_unit); % Hz
    %     travel_dist_boot(i,1) = nan;
end

travel_dist_ci = prctile(travel_dist_boot, [.5 99.5], 1);


%% Plot
% distance matrix
ax_travel_mat = plt.assign_ax_to_fig(fig_dist, 1, 1, [1 4 3 3], [3 3]);
ax = ax_travel_mat{1};
set(ax, 'YDir', 'reverse', 'XLim', [-.5 n_sample+.5], 'YLim', [-.5 n_sample+.5]);

imagesc(ax, t_sample, t_sample, travel_dist);

cb_travel = colorbar(ax, 'Units', 'centimeters', 'Position', [4.25 4 .25 3], 'TickDirection', 'out', 'FontSize', 7);
cb_travel.Label.String = "Neural distance (Hz)";
cb_travel.Label.FontSize = 7;

colormap(ax, 'parula');

% travel distance relative to cent-in
ax_travel = plt.assign_ax_to_fig(fig_dist, 1, 1, [6.5 4.25 3 3], [3 2]);
ax = ax_travel{1};

fill(ax, [t_sample fliplr(t_sample)], [travel_dist_ci(1,:) fliplr(travel_dist_ci(2,:))], 'k', 'FaceAlpha', .1, 'EdgeAlpha', .2);
plot(ax, t_sample, travel_dist(1,:), '-k', 'LineWidth', 1.5);
% plot(ax, t_sample, travel_dist_ci(1,:), ':k', 'LineWidth', 1);
% plot(ax, t_sample, travel_dist_ci(2,:), ':k', 'LineWidth', 1);
xlim(ax, [0 1500])

ylabel(ax, 'Travel distance (Hz)');

%%
fig_name = sprintf('NeuralDistance_%s_%s', r.BehaviorClass.Subject, r.BehaviorClass.Session);
fig_path = fullfile('Figure', fig_name);
exportgraphics(fig_dist, sprintf('%s.png', fig_path), 'Resolution', 300);


end