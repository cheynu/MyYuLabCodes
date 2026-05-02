function PlotSpikeDensityOnTrajField(TrajField, r, PosPart)

fig_folder = fullfile(pwd, 'Fig', 'TrajField');
if ~isfolder(fig_folder)
    mkdir(fig_folder);
end

if ~isfield(TrajField, 'Subject')
    TrajField.Subject = r.BehaviorClass.Subject;
end

%% valify the tracking position of both ears and their midpoint
% left ear
[PosL, IndValidL, figL] = SpikesGPS.Video.valifyTrackingParts(TrajField, 'EarLTop', 0.8, 1, 1);
print(figL, '-dpng', fullfile(fig_folder, 'TrajValify_EarLTop'));
% right ear
[PosR, IndValidR, figR] = SpikesGPS.Video.valifyTrackingParts(TrajField, 'EarRTop', 0.8, 1, 1);
print(figR, '-dpng', fullfile(fig_folder, 'TrajValify_EarRTop'));

% ears midpoint
PosC = cellfun(@(pos_l, pos_r) (pos_l + pos_r)/2, PosL, PosR, 'UniformOutput', false);
IndValidC = IndValidR & IndValidL;

figC = figure(); clf(figC);
set(figC, 'name', 'TrajValify', 'units', 'centimeters', 'position', [5 3 11 5.5], 'PaperUnits', 'centimeters', 'PaperPosition', [5 3 12 5.5], 'visible', 'on');
ax = axes(figC, 'Units', 'centimeters', 'Position', [.5 .5 10 4], 'NextPlot', 'add', 'FontSize', 9, 'XColor', 'none', 'YColor', 'none', 'YDir', 'reverse');
for i = 1:length(PosC)
    if IndValidC(i)
        cor = 'blue';
    else
        cor = 'red';
    end
    scatter(ax, PosC{i}(1,:), PosC{i}(2,:), 2, cor, 'filled', 'MarkerFaceAlpha', .2);
end
title(ax, sprintf('%s : %d / %d valid trials', 'EarCenter', sum(IndValidC), length(PosC)));
print(figC, '-dpng', fullfile(fig_folder, 'TrajValify_EarCenter'));

%% Define the part as position of the animal, using which to calculate rat speed (velocity and speed direction)
switch PosPart
    case 'EarLTop'
        Pos = PosL;
        IndValid = IndValidL;
    case 'EarRTop'
        Pos = PosR;
        IndValid = IndValidR;
    case 'EarCenter'
        Pos = PosC;
        IndValid = IndValidC;
end

%% Calculate speed
t = TrajField.t_frame_e;

% calculate speed on x and y direction
d_x = cellfun(@(x) SpikesGPS.Video.cal_diff(x(1,:)), Pos, 'UniformOutput', false);
d_y = cellfun(@(x) SpikesGPS.Video.cal_diff(x(2,:)), Pos, 'UniformOutput', false);
d_t = cellfun(@(x) SpikesGPS.Video.cal_diff(x'), t, 'UniformOutput', false);

v_x = cellfun(@(dx, dt) dx ./ dt, d_x, d_t, 'UniformOutput', false);
v_y = cellfun(@(dx, dt) dx ./ dt, d_y, d_t, 'UniformOutput', false);

% velocity
Velocity = cellfun(@(vx, vy) sqrt(vx.^2 + vy.^2), v_x, v_y, 'UniformOutput', false);

% speed direction
ref_vector = [-1 0];
SpeedDir = cellfun(@(vx, vy) SpikesGPS.Video.cal_angle([vx' vy'], ref_vector)', v_x, v_y, 'UniformOutput', false);
% get the sign of speed direction
positive_vector = [0 1]; % this vector point to positive direction (positive: towards left port; down on field view)
dir_ang  = cellfun(@(vx, vy) SpikesGPS.Video.cal_angle([vx' vy'], positive_vector)', v_x, v_y, 'UniformOutput', false);
dir_sign = cellfun(@(ang) 2*(ang<=90) - 1, dir_ang, 'UniformOutput', false);
% attach sign to speed dir
SpeedDir = cellfun(@(dir, s) dir .* s, SpeedDir, dir_sign, 'UniformOutput', false);

TrajField.PosPart  = PosPart;
TrajField.Pos      = Pos;
TrajField.Velocity = Velocity;
TrajField.SpeedDir = SpeedDir;

%% Map spike density function to trajectory (interp1(tsdf, sdf, t_frame))
n_units = size(r.Units.SpikeNotes, 1);
if isfield(TrajField, 'sdf_mapped')
    sdf_mapped = TrajField.sdf_mapped;
else
    sdf_mapped = [];
    for i = 1:n_units
        id = r.Units.SpikeNotes(i, [1 2]);
        i_sdf_mapped = SpikesGPS.Video.mapSDF2Traj(TrajField, r, id);
        sdf_mapped = [sdf_mapped; i_sdf_mapped];
    end
    TrajField.sdf_mapped = sdf_mapped;
end
traj_filename = sprintf('TrajField_%s_%s.mat', TrajField.Subject, TrajField.Session);
save(traj_filename, 'TrajField');

%% Plot spike density against trajetory
c_hot = colormap('hot');
c_hot = c_hot(1:220, :);

n_trial = length(TrajField.trial_id);
for i = 1:n_units
    fig_sdf = figure(27); clf(fig_sdf);
    set(fig_sdf, 'name', 'Spike density against trajectory', 'units', 'centimeters', 'position', [5 3 12.5 9.5], 'PaperUnits', 'centimeters', 'visible', 'on', 'Color', 'w');
    set_fig_title(fig_sdf, sprintf('%s | %s | Channel%s | Unit%s | %s', TrajField.Subject, TrajField.Session, sdf_mapped(i).meta.Channel, sdf_mapped(i).meta.Unit, sdf_mapped(i).meta.Quality));

    % spike waveform and aytocorrelation
    ax_waveform = axes(fig_sdf, 'Units', 'centimeters', 'Position', [1 6.25 1.5 1.5], 'NextPlot', 'add', 'FontSize', 9, 'XColor', 'none', 'YColor', 'none');
    spk = sdf_mapped(i).spk;
    fill(ax_waveform, [spk.tspk flip(spk.tspk)], [spk.spk_mean+spk.spk_std flip(spk.spk_mean-spk.spk_std)], 'r', 'FaceColor', 0.7*ones(1,3), 'EdgeColor', 'none');
    plot(ax_waveform, spk.tspk, spk.spk_mean, '-k', 'LineWidth', 1);

    % plot autocorrelation
    kutime = round(r.Units.SpikeTimes(i).timings);
    kutime = kutime(kutime>0);
    kutime2 = zeros(1, max(kutime));
    kutime2(kutime) = 1;
    [cor, lags] = xcorr(kutime2, 100); % max lag 100 ms
    cor(lags==0) = 0;

    ax_corr = axes('unit', 'centimeters', 'position', [3 6.5 1.5 1.5], 'nextplot', 'add', 'xlim', [-25 25], 'FontSize', 9, 'YColor', 'none');
    if median(cor)>1
        set(ax_corr, 'nextplot', 'add', 'xtick', -50:10:50, 'ytick', [0 median(cor)]);
    else
        set(ax_corr, 'nextplot', 'add', 'xtick', -50:10:50, 'ytick', [0 1], 'ylim', [0 1]);
    end
    hbar = bar(lags, cor);
    set(hbar, 'facecolor', 'k');
    xlabel('Lag (ms)')

    % map spike density to trajectory
    ax_traj = axes(fig_sdf, 'Units', 'centimeters', 'Position', [.5 .5 10 4], 'NextPlot', 'add', 'FontSize', 9, 'XColor', 'none', 'YColor', 'none', 'YDir', 'reverse');
    title(ax_traj, sprintf('%s : %d / %d valid trials', PosPart, sum(IndValid), n_trial));
    for j = 1:n_trial
        if IndValid(j) && ~isempty(sdf_mapped(i).sdf{j})
            scatter(ax_traj, Pos{j}(1,:), Pos{j}(2,:), 2, .7*ones(1,3), 'filled', 'MarkerFaceAlpha', .2);
        end
    end
    for j = 1:n_trial
        if IndValid(j) && ~isempty(sdf_mapped(i).sdf{j})
            id_fire = sdf_mapped(i).sdf{j}>0;
            scatter(ax_traj, Pos{j}(1,id_fire), Pos{j}(2,id_fire), 4, sdf_mapped(i).sdf{j}(id_fire), 'filled', 'MarkerFaceAlpha', .4);
        end
    end
    colormap(ax_traj, c_hot);

    sdf_cat = cell2mat(sdf_mapped(i).sdf(IndValid)');
    fr_range = round([quantile(sdf_cat, .1) quantile(sdf_cat(sdf_cat>0), .5)]);
    if fr_range(2)==fr_range(1)
        fr_range(2) = fr_range(1) + 1;
    end
    clim(ax_traj, fr_range);

    cb = colorbar(ax_traj, 'Units', 'centimeters', 'Position', [10.7 1 .3 3], 'Ticks', fr_range, 'FontSize', 9);
    cb.Label.String = 'Fring rate (Hz)';

    % plot firing rate vs velocity
    ax_velocity = axes(fig_sdf, 'Units', 'centimeters', 'Position', [6 6.5 2.5 1.5], 'NextPlot', 'add', 'FontSize', 9, 'TickDir', 'out');
    velocity_cat = cell2mat(Velocity(IndValid)');
    velocity_bin = [0:0.1:1 1.5];
    velocity_pos = mean([velocity_bin(1:end-1); velocity_bin(2:end)], 1);
    velocity_ind = discretize(velocity_cat, velocity_bin);
    fr_velocity_m  = zeros(1, length(velocity_pos));
    fr_velocity_ci = zeros(2, length(velocity_pos));
    for j = 1:length(velocity_pos)
        fr_velocity_m(j) = mean(sdf_cat(velocity_ind==j));
        if sum(velocity_ind==j) > 2
            fr_velocity_ci(:,j) = bootci(1000, {@mean, sdf_cat(velocity_ind==j)});
        end
    end
    errorbar(ax_velocity, velocity_pos, fr_velocity_m, fr_velocity_m-fr_velocity_ci(1,:), fr_velocity_ci(2,:)-fr_velocity_m, 'CapSize', 0, 'LineWidth', 1, 'Color', 'k');
    
    xlabel(ax_velocity, 'Velocity (px/ms)');
    ylabel('Firing rate (Hz)');

    % plot firing rate vs speed direction
    ax_speeddir = axes(fig_sdf, 'Units', 'centimeters', 'Position', [9.25 6.5 2.5 1.5], 'NextPlot', 'add', 'FontSize', 9, 'TickDir', 'out');
    speeddir_cat = cell2mat(SpeedDir(IndValid)');
    speeddir_bin = -180:20:180;
    speeddir_pos = mean([speeddir_bin(1:end-1); speeddir_bin(2:end)], 1);
    speeddir_ind = discretize(speeddir_cat, speeddir_bin);
    fr_speeddir_m  = zeros(1, length(speeddir_pos));
    fr_speeddir_ci = zeros(2, length(speeddir_pos));
    for j = 1:length(speeddir_pos)
        fr_speeddir_m(j) = mean(sdf_cat(speeddir_ind==j));
        if sum(speeddir_ind==j) > 2
            fr_speeddir_ci(:,j) = bootci(1000, {@mean, sdf_cat(speeddir_ind==j)});
        end
    end
    errorbar(ax_speeddir, speeddir_pos, fr_speeddir_m, fr_speeddir_m-fr_speeddir_ci(1,:), fr_speeddir_ci(2,:)-fr_speeddir_m, 'CapSize', 0, 'LineWidth', 1, 'Color', 'k');
    
    xlabel(ax_speeddir, 'Speed dir. (°)');
    xticks(ax_speeddir, -180:90:180);
    xlim(ax_speeddir, [-190 190])

    set(fig_sdf, 'PaperPosition', fig_sdf.Position);
    fig_name = sprintf('SpikeTrajField_%s_%s_Ch%s_Unit%s', TrajField.Subject, TrajField.Session, sdf_mapped(i).meta.Channel, sdf_mapped(i).meta.Unit);
    print(fig_sdf, '-dpng', fullfile(fig_folder, fig_name), '-r300');

end

end
