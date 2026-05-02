function [CodingDirection, fig_cd] = showCodingDirection(r)

c = cell(3,2);
c{1,1} = [246 178 147] / 255;
c{2,1} = [220 109 87]  / 255;
c{3,1} = [183 34 48]   / 255;
c{1,2} = [182 215 232] / 255;
c{2,2} = [109 173 209] / 255;
c{3,2} = [49 124 183]  / 255;

plt = GPSPlot();


% cluster spikes by waveform, get regular good spikes
regular_file = dir('RegularIndex*.mat');
if ~isempty(regular_file)
    load(regular_file.name, 'RegularIndex');
else
    RegularIndex = clusterSpikes(r, 'PeakTrough');
end


% Do soft normalization
fr = r.popSDFWarped.sdf;
fr = cellfun(@(x) x(RegularIndex.Good,:), fr, 'UniformOutput', false);
fr_ci_l = cellfun(@(x) x(RegularIndex.Good,:), r.popSDFWarped.sdf_ci_l, 'UniformOutput', false);
fr_ci_u = cellfun(@(x) x(RegularIndex.Good,:), r.popSDFWarped.sdf_ci_u, 'UniformOutput', false);

n_u = size(fr{1}, 1); % number of units in total
n_t = cellfun(@(x) size(x, 2), fr); % time length in each conditions

fr_c = cell2mat(fr(:)'); % concatenate all conditions
fr_c_norm = single(nan(size(fr_c))); % initialize soft-norm output
soft_f = zeros(n_u, 1);
g_mean = zeros(n_u, 1);
for i = 1:n_u
    [fr_c_norm(i,:), soft_f(i), g_mean(i)] = cal_soft_norm(fr_c(i,:));
end

fr_norm = mat2cell(fr_c_norm, n_u, n_t(:)'); % split conditions
fr_norm = reshape(fr_norm, 3, 2);

fr_norm_ci_l = cellfun(@(x) (x-g_mean) ./ soft_f, fr_ci_l, 'UniformOutput', false);
fr_norm_ci_u = cellfun(@(x) (x-g_mean) ./ soft_f, fr_ci_u, 'UniformOutput', false);

% time information
t_warp = r.popSDFWarped.t_warp;
t_point = r.popSDFWarped.t_points;

% analyze from 1500ms pre cent-in, to 200ms post choice-in
fr_norm = cellfun(@(x, t_w, t_p) x(:, t_w>-1500 & t_w<=t_p(4)+200), fr_norm, t_warp, t_point, 'UniformOutput', false);
fr_norm_ci_l = cellfun(@(x, t_w, t_p) x(:, t_w>-1500 & t_w<=t_p(4)+200), fr_norm_ci_l, t_warp, t_point, 'UniformOutput', false);
fr_norm_ci_u = cellfun(@(x, t_w, t_p) x(:, t_w>-1500 & t_w<=t_p(4)+200), fr_norm_ci_u, t_warp, t_point, 'UniformOutput', false);
t_warp = cellfun(@(t_w, t_p) t_w(t_w>-1500 & t_w<=t_p(4)+200), t_warp, t_point, 'UniformOutput', false);

% update fr concatenate
fr_c_norm = cell2mat(fr_norm(:)');
n_u = size(fr_norm{1}, 1); % number of units in total
n_t = cellfun(@(x) size(x, 2), fr_norm); % time length in each conditions


%% Coding directions in different stages
c_pre_cent  = getSpikeCount(r, 'tCentIn', [-150 0]);
c_post_cent = getSpikeCount(r, 'tCentIn', [0 150]);
c_pre_trig  = getSpikeCount(r, 'tTrigger', [-150 0]);
c_post_trig = getSpikeCount(r, 'tTrigger', [0 150]);
c_pre_resp  = getSpikeCount(r, 'tCentOut', [-400 0]);
c_post_resp = getSpikeCount(r, 'tCentOut', [0 400]);

c_pre_cent.Count  = c_pre_cent.Count(:, RegularIndex.Good);
c_post_cent.Count = c_post_cent.Count(:, RegularIndex.Good);
c_pre_trig.Count  = c_pre_trig.Count(:, RegularIndex.Good);
c_post_trig.Count = c_post_trig.Count(:, RegularIndex.Good);
c_pre_resp.Count  = c_pre_resp.Count(:, RegularIndex.Good);
c_post_resp.Count = c_post_resp.Count(:, RegularIndex.Good);


id_cd = cell(1,2);
for p = 1:2
    id_cd{p} = find(r.EphysTable.Outcome=="Correct" & r.EphysTable.PortCorrect==p);
end

cd_hold = mean(c_pre_trig.Count(id_cd{1},:)) - mean(c_pre_trig.Count(id_cd{2},:));
cd_hold = cd_hold' / norm(cd_hold);

cd_resp = mean(c_post_trig.Count(id_cd{1},:)) - mean(c_post_trig.Count(id_cd{2},:));
cd_resp = cd_resp' / norm(cd_resp);

cd_move = mean(c_post_resp.Count(id_cd{1},:)) - mean(c_post_resp.Count(id_cd{2},:));
cd_move = cd_move' / norm(cd_move);

id_d = find(r.EphysTable.Outcome=="Correct");
d_ramp = mean(c_pre_trig.Count(id_d,:)) - mean(c_post_cent.Count(id_d,:));
d_ramp = d_ramp' / norm(d_ramp);

d_trig = mean(c_post_trig.Count(id_d,:)) - mean(c_pre_trig.Count(id_d,:));
d_trig = d_trig' / norm(d_trig);

d_move = mean(c_post_resp.Count(id_d,:)) - mean(c_pre_resp.Count(id_d,:));
d_move = d_move' / norm(d_move);


%% Plot coding direction
fig_cd = figure(89); clf(fig_cd);
set_fig_default(fig_cd);
set(fig_cd, 'Name', 'Coding direction', 'Position', [5 5 19.5 6.5]);
set_fig_title(fig_cd, sprintf('%s | %s', r.BehaviorClass.Subject, r.BehaviorClass.Session));

% Pearson's correlation of coding direction through time
fr_norm_len = cellfun(@(x, t_w, t_p) x(:, t_w>t_p(1)-150 & t_w<=t_p(2)+500), fr_norm, t_warp, t_point, 'UniformOutput', false);
t_warp_len  = cellfun(@(t_w, t_p) t_w(:, t_w>t_p(1)-150 & t_w<=t_p(2)+500), t_warp, t_point, 'UniformOutput', false);

cd_len = fr_norm_len{3,1} - fr_norm_len{3,2};
for i = 1:size(cd_len, 2)
    cd_len(:,i) = cd_len(:,i) ./ norm(cd_len(:,i)', 2);
end
cd_corr = corr(cd_len, 'type', 'Pearson');

ax_corr = plt.assign_ax_to_fig(fig_cd, 1, 1, [1.5 1 4 4], [4 4]);
ax_corr = ax_corr{1};
set(ax_corr, 'XLim', [-150.5 2000.5], 'YLim', [-150.5 2000.5], 'YDir', 'reverse', 'CLim', [-.1 .9]);

imagesc(ax_corr, t_warp_len{3}, t_warp_len{3}, cd_corr); colormap('turbo');

xline(ax_corr, 0, '--w', 'Alpha', 1, 'LineWidth', 1.5); yline(ax_corr, 0, '--w', 'Alpha', 1, 'LineWidth', 1.5);
xline(ax_corr, 1500, '--w', 'Alpha', 1, 'LineWidth', 1.5); yline(ax_corr, 1500, '--w', 'Alpha', 1, 'LineWidth', 1.5);
rt_m = mean([t_point{3,1}(3), t_point{3,2}(3)]);
xline(ax_corr, rt_m, ':w', 'Alpha', 1, 'LineWidth', 1.5); yline(ax_corr, rt_m, ':w', 'Alpha', 1, 'LineWidth', 1.5);

xlabel(ax_corr, 'Time to Cent-In (ms)'); ylabel(ax_corr, 'Time to Cent-In (ms)');

cb_corr = colorbar(ax_corr, 'Units', 'centimeters', 'Position', [5.75 1 .25 4], 'TickDirection', 'out', 'Ticks', 0:.2:1, 'FontSize', 7);
cb_corr.Label.String = "Pearson's correlation";
cb_corr.Label.FontSize = 7;

%%
ax_proj = plt.assign_ax_to_fig(fig_cd, 2, 3, [8 1 10.5 4], [3 1.5]);
cellfun(@(x) set(x, 'Xlim', [-1500 2500]), ax_proj(:,1:2));
cellfun(@(x) set(x, 'Xlim', [-3000 1000]), ax_proj(:,3));

% CD-hold
ax = ax_proj{1,1};

fr_proj_hold = cellfun(@(x) (x' * cd_hold)', fr_norm, 'UniformOutput', false);
fr_proj_hold_ci_l = cellfun(@(x) (x' * cd_hold)', fr_norm_ci_l, 'UniformOutput', false);
fr_proj_hold_ci_u = cellfun(@(x) (x' * cd_hold)', fr_norm_ci_u, 'UniformOutput', false);

fp = 3;
for p = 1:2
    fill(ax, [t_warp{fp,p} fliplr(t_warp{fp,p})], [fr_proj_hold_ci_l{fp,p}, fliplr(fr_proj_hold_ci_u{fp,p})], 'r', 'FaceColor', c{fp,p}, 'FaceAlpha', .2, 'LineStyle', 'none');
    plot(ax, t_warp{fp,p}, fr_proj_hold{fp,p}, 'Color', c{fp,p}, 'LineWidth', 1);

    yline(ax, 0, ':k', 'Alpha', 1, 'LineWidth', 1);
    xline(ax, [0 1500], ':k', 'Alpha', 1, 'LineWidth', 1);
    t_resp_choice = round(t_point{fp,p}(3:4));
    fr_resp_choice = fr_proj_hold{fp,p}(ismember(t_warp{fp,p}, t_resp_choice));
    scatter(ax, t_resp_choice, fr_resp_choice, 12, c{fp,p}, 'filled', 'o', 'LineWidth', 1);
end
title(ax, 'CD_{Hold}');
ylabel(ax, 'Projection (a.u.)');

% CD-response
ax = ax_proj{1,2};

fr_proj_resp = cellfun(@(x) (x' * cd_resp)', fr_norm, 'UniformOutput', false);
fr_proj_resp_ci_l = cellfun(@(x) (x' * cd_resp)', fr_norm_ci_l, 'UniformOutput', false);
fr_proj_resp_ci_u = cellfun(@(x) (x' * cd_resp)', fr_norm_ci_u, 'UniformOutput', false);

fp = 3;
for p = 1:2
    fill(ax, [t_warp{fp,p} fliplr(t_warp{fp,p})], [fr_proj_resp_ci_l{fp,p}, fliplr(fr_proj_resp_ci_u{fp,p})], 'r', 'FaceColor', c{fp,p}, 'FaceAlpha', .2, 'LineStyle', 'none');
    plot(ax, t_warp{fp,p}, fr_proj_resp{fp,p}, 'Color', c{fp,p}, 'LineWidth', 1);

    yline(ax, 0, ':k', 'Alpha', 1, 'LineWidth', 1);
    xline(ax, [0 1500], ':k', 'Alpha', 1, 'LineWidth', 1);
    t_resp_choice = round(t_point{fp,p}(3:4));
    fr_resp_choice = fr_proj_resp{fp,p}(ismember(t_warp{fp,p}, t_resp_choice));
    scatter(ax, t_resp_choice, fr_resp_choice, 12, c{fp,p}, 'filled', 'o', 'LineWidth', 1);
end
title(ax, 'CD_{Response}');

% CD-move
ax = ax_proj{1,3};

fr_proj_move = cellfun(@(x) (x' * cd_move)', fr_norm, 'UniformOutput', false);
fr_proj_move_ci_l = cellfun(@(x) (x' * cd_move)', fr_norm_ci_l, 'UniformOutput', false);
fr_proj_move_ci_u = cellfun(@(x) (x' * cd_move)', fr_norm_ci_u, 'UniformOutput', false);

fp = 3;
for p = 1:2
    fill(ax, [t_warp{fp,p} fliplr(t_warp{fp,p})] - t_point{fp,p}(3), [fr_proj_move_ci_l{fp,p}, fliplr(fr_proj_move_ci_u{fp,p})], 'r', 'FaceColor', c{fp,p}, 'FaceAlpha', .2, 'LineStyle', 'none');
    plot(ax, t_warp{fp,p} - t_point{fp,p}(3), fr_proj_move{fp,p}, 'Color', c{fp,p}, 'LineWidth', 1);

    yline(ax, 0, ':k', 'Alpha', 1, 'LineWidth', 1);
    xline(ax, 0, ':k', 'Alpha', 1, 'LineWidth', 1);
    t_trig_choice = round(t_point{fp,p}([2 4]));
    fr_trig_choice = fr_proj_move{fp,p}(ismember(t_warp{fp,p}, t_trig_choice));
    scatter(ax, t_trig_choice - t_point{fp,p}(3), fr_trig_choice, 12, c{fp,p}, 'filled', 'o', 'LineWidth', 1);
end
title(ax, 'CD_{Move}');

% D-ramp
ax = ax_proj{2,1};

fr_proj_ramp = cellfun(@(x) (x' * d_ramp)', fr_norm, 'UniformOutput', false);
fr_proj_ramp_ci_l = cellfun(@(x) (x' * d_ramp)', fr_norm_ci_l, 'UniformOutput', false);
fr_proj_ramp_ci_u = cellfun(@(x) (x' * d_ramp)', fr_norm_ci_u, 'UniformOutput', false);

fp = 3;
for p = 1:2
    fill(ax, [t_warp{fp,p} fliplr(t_warp{fp,p})], [fr_proj_ramp_ci_l{fp,p}, fliplr(fr_proj_ramp_ci_u{fp,p})], 'r', 'FaceColor', c{fp,p}, 'FaceAlpha', .2, 'LineStyle', 'none');
    plot(ax, t_warp{fp,p}, fr_proj_ramp{fp,p}, 'Color', c{fp,p}, 'LineWidth', 1);

    yline(ax, 0, ':k', 'Alpha', 1, 'LineWidth', 1);
    xline(ax, [0 1500], ':k', 'Alpha', 1, 'LineWidth', 1);
    t_resp_choice = round(t_point{fp,p}(3:4));
    fr_resp_choice = fr_proj_ramp{fp,p}(ismember(t_warp{fp,p}, t_resp_choice));
    scatter(ax, t_resp_choice, fr_resp_choice, 12, c{fp,p}, 'filled', 'o', 'LineWidth', 1);
end
title(ax, 'D_{Ramp}');
ylabel(ax, 'Projection (a.u.)');
xlabel(ax, 'Time to Cent-In (ms)');

% D-trigger
ax = ax_proj{2,2};

fr_proj_trig = cellfun(@(x) (x' * d_trig)', fr_norm, 'UniformOutput', false);
fr_proj_trig_ci_l = cellfun(@(x) (x' * d_trig)', fr_norm_ci_l, 'UniformOutput', false);
fr_proj_trig_ci_u = cellfun(@(x) (x' * d_trig)', fr_norm_ci_u, 'UniformOutput', false);

fp = 3;
for p = 1:2
    fill(ax, [t_warp{fp,p} fliplr(t_warp{fp,p})], [fr_proj_trig_ci_l{fp,p}, fliplr(fr_proj_trig_ci_u{fp,p})], 'r', 'FaceColor', c{fp,p}, 'FaceAlpha', .2, 'LineStyle', 'none');
    plot(ax, t_warp{fp,p}, fr_proj_trig{fp,p}, 'Color', c{fp,p}, 'LineWidth', 1);

    yline(ax, 0, ':k', 'Alpha', 1, 'LineWidth', 1);
    xline(ax, [0 1500], ':k', 'Alpha', 1, 'LineWidth', 1);
    t_resp_choice = round(t_point{fp,p}(3:4));
    fr_resp_choice = fr_proj_trig{fp,p}(ismember(t_warp{fp,p}, t_resp_choice));
    scatter(ax, t_resp_choice, fr_resp_choice, 12, c{fp,p}, 'filled', 'o', 'LineWidth', 1);
end
title(ax, 'D_{Response}');
xlabel(ax, 'Time to Cent-In (ms)');

% D_move
ax = ax_proj{2,3};

fr_proj_turn = cellfun(@(x) (x' * d_move)', fr_norm, 'UniformOutput', false);
fr_proj_turn_ci_l = cellfun(@(x) (x' * d_move)', fr_norm_ci_l, 'UniformOutput', false);
fr_proj_turn_ci_u = cellfun(@(x) (x' * d_move)', fr_norm_ci_u, 'UniformOutput', false);

fp = 3;
for p = 1:2
    fill(ax, [t_warp{fp,p} fliplr(t_warp{fp,p})] - t_point{fp,p}(3), [fr_proj_turn_ci_l{fp,p}, fliplr(fr_proj_turn_ci_u{fp,p})], 'r', 'FaceColor', c{fp,p}, 'FaceAlpha', .2, 'LineStyle', 'none');
    plot(ax, t_warp{fp,p} - t_point{fp,p}(3), fr_proj_turn{fp,p}, 'Color', c{fp,p}, 'LineWidth', 1);

    yline(ax, 0, ':k', 'Alpha', 1, 'LineWidth', 1);
    xline(ax, 0, ':k', 'Alpha', 1, 'LineWidth', 1);
    t_trig_choice = round(t_point{fp,p}([2 4]));
    fr_trig_choice = fr_proj_turn{fp,p}(ismember(t_warp{fp,p}, t_trig_choice));
    scatter(ax, t_trig_choice - t_point{fp,p}(3), fr_trig_choice, 12, c{fp,p}, 'filled', 'o', 'LineWidth', 1);
end
title(ax, 'D_{Move}');
xlabel(ax, 'Time to Cent-Out (ms)');

%%
fig_name = sprintf('CodingDirection_%s_%s', r.BehaviorClass.Subject, r.BehaviorClass.Session);
fig_path = fullfile('Figure', fig_name);
exportgraphics(fig_cd, sprintf('%s.png', fig_path), 'Resolution', 300);

%%
CodingDirection.CD_hold = cd_hold;
CodingDirection.CD_response = cd_resp;
CodingDirection.CD_move = cd_move;
CodingDirection.D_ramp = d_ramp;
CodingDirection.D_trigger = d_trig;
CodingDirection.D_move = d_move;

end