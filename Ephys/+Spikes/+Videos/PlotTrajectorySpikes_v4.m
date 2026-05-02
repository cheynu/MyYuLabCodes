function DataOut = PlotTrajectorySpikes_v4(sdf_unit, TrajTableAll, TimeStamp, video_path, unit_name, type, plot_rate, num_trajs)
% revised: 2024.09.02 
% use most recent version of sdf_unit which comes from Spikes.SRT.rPSTHWarped(r, [channel, unit])
% removed some variables that are included in sdf_unit
if nargin<9
    num_trajs = [];
    if nargin<8
        plot_rate = 1;  % color map plots the rate, else, it plots spike count/grid
    end
end

% video_path = fullfile(pwd, 'Data/');
% TimeStamp = '182295';
top_vid_name = ['Top_Press_' TimeStamp '.mp4'];
top_vid_meta = ['Top_Press_' TimeStamp '.mat'];
side_vid_name = ['Side_Press_' TimeStamp '.mp4'];
side_vid_meta = ['Side_Press_' TimeStamp '.mat'];

meta_file = load(fullfile(video_path, vid_meta));

t_toPress = 500; % 500 ms before presds
ind = find(meta_file.VideoInfo.EphysTimeStamps<meta_file.VideoInfo.Time-t_toPress, 1, 'last');

% Create VideoReader object
vid_file = fullfile(video_path, vid_name);
vidObj = VideoReader(vid_file);

% Frame index to extract
frame_index = ind;

% Read and extract the 100th frame
vidObj.CurrentTime = (frame_index - 1) / vidObj.FrameRate; % Convert frame index to time
frame = readFrame(vidObj);
frame_size = size(frame);

DataOut = struct();
% start a structure to save byproduct
DataOut.Name = unit_name; % this is in the format of ANM_Session_Ch_Unit
DataOut.TrajTable = TrajTableAll;

xrange = [0 frame_size(2)];
yrange = [0 frame_size(1)];

bin_size = 20;
% Create edges for grid bins
xBinEdges = linspace(0, frame_size(2), frame_size(2)/bin_size);
% Create edges for grid bins
yBinEdges = linspace(0, frame_size(1), frame_size(1)/bin_size);

DataOut.xrange = xrange;
DataOut.yrange = yrange;
DataOut.xBinEdges = xBinEdges;
DataOut.yBinEdges = yBinEdges;

% Data preparation
time_table = TrajTableAll.Time; % Replace with the Time column from your table
x = TrajTableAll.x; % x positions
y = TrajTableAll.y; % y positions

is_before = ~TrajTableAll.BeforePress;
trial_names = unique(TrajTableAll.Source);
% Group each trials

Trials = cell(length(trial_names), 5);
% - 1. trial name,
% - 2. time before press, trajectory before press, spike rate sdf, spike times (t, x, y, sdf, spk),
% - 3. traj mapped before press,
% - 4. time after press, trajectory after press, spike rate sdf, spike times (t, x, y, sdf, spk),
% - 5. traj mapped after press,

DataOut.TrialsExplained = {
    '- 1. trial name',
    '- 2. time before press, trajectory before press, spike rate sdf (t, x, y, sdf)'
    '- 3. traj mapped before press (map_out, xcenters, ycenters)'
    '- 4. time after press, trajectory after press, spike rate sdf (t, x, y, sdf)'
    '- 5. traj mapped after press (map_out, xcenters, ycenters)'
    '- 6. spike time before press '
    '- 7. spike time after press '};
% sdf_values_org          =       interp1(sdf_unit.t_sdf_ms, sdf_unit.sdf, time_table, 'linear', 0);
t_sdf                         =           sdf_unit.t_sdf_ms;
sdf_org                     =           sdf_unit.sdf;
spk_train                   =           sdf_unit.spk_time_ms;

figure(25); clf(25);
hold on;

for iTrial = 1:length(Trials)

    this_trial          =   trial_names{iTrial};
    t_press             =   str2double(regexp(this_trial, '\d+', 'match'));
    Trials{iTrial, 1}   =   this_trial;
    ind_this_trial      =   strcmp(TrajTableAll.Source, this_trial);
    x_i                 =   x(ind_this_trial);
    y_i                 =   y(ind_this_trial);

    t_i_org             =   time_table(ind_this_trial);
    sdf_iTrial          =   interp1(t_sdf, sdf_org, t_i_org, 'linear', 0);
    spk_train_iTrial    =   spk_train(spk_train>=t_i_org(1) & spk_train<=t_i_org(end))-t_press;
    t_i                 =   time_table(ind_this_trial)-t_press; % relative spikes


    is_before_i         =   is_before(ind_this_trial);
    ind_before_press    =   find(is_before_i>0);
    ind_after_press     =   find(is_before_i==0);

    if ~isempty(ind_before_press)
        sdf_before_press = sdf_iTrial(ind_before_press);
        spk_train_before_press = spk_train_iTrial(spk_train_iTrial<=0);
        [map_out, xcenters, ycenters] = Spikes.Videos.compute_corr2D(x_i(ind_before_press), y_i(ind_before_press), xBinEdges, yBinEdges);
        Trials{iTrial, 2} = [t_i(ind_before_press), x_i(ind_before_press) y_i(ind_before_press), sdf_before_press];
        Trials{iTrial, 6} = spk_train_before_press;
        Trials{iTrial, 3} = {map_out, xcenters, ycenters};
        plot(t_i(ind_before_press), y_i(ind_before_press), 'k.');

    end
    if ~isempty(ind_after_press)
        sdf_after_press = sdf_iTrial(ind_after_press);
        spk_train_after_press = spk_train_iTrial(spk_train_iTrial>0);
        [map_out, xcenters, ycenters] = Spikes.Videos.compute_corr2D(x_i(ind_after_press), y_i(ind_after_press), xBinEdges, yBinEdges);
        Trials{iTrial, 4} = [t_i(ind_after_press), x_i(ind_after_press) y_i(ind_after_press), sdf_after_press];
        Trials{iTrial, 7} = spk_train_after_press;
        Trials{iTrial, 5} = {map_out, xcenters, ycenters};
    end
end

DataOut.Trials = Trials;

% Determine movement direciton
[toLeverDirection, fromLeverDirection] = Spikes.Videos.determineTurningY(Trials, unit_name, num_trajs);
DataOut.TrajDirections = {toLeverDirection, fromLeverDirection};

% Compute average trajectories.
num_bins = 100;
x_bins = linspace(xrange(1), xrange(2), num_bins);
x_centers = 0.5*(x_bins(1:end-1)+x_bins(2:end));

nToLever = 1;
nFromLever = 1;

if any(toLeverDirection==2) % only one direction
    nToLever = 2;
end

if any(fromLeverDirection==2) % only one direction
    nFromLever = 2;
end

y_means_to = nan(2, num_bins);
y_ci_to = nan(2, num_bins, 2);
y_means_from = nan(2, num_bins);
y_ci_from = nan(2, num_bins, 2);
for i = 1:num_bins-1
    xbeg = x_bins(i);
    xend = x_bins(i+1);
    % collect y value at each x.
    y_values_to_lever = cell(1, nToLever);
    y_values_from_lever = cell(1, nFromLever);
    for j =1:size(Trials, 1)
        toLeverDirection_j = toLeverDirection(j);
        fromLeverDirection_j = fromLeverDirection(j);
        if ~isempty(Trials{j, 2}) && ~isnan(toLeverDirection_j)
            x_to_j = Trials{j, 2}(:, 2);
            y_to_j = Trials{j, 2}(:, 3);
            idx = find(x_to_j>=xbeg & x_to_j<xend);
            if ~isempty(idx)
                y_values_to_lever{toLeverDirection_j} = [y_values_to_lever{toLeverDirection_j}; mean(y_to_j(idx))];
            end
        end
        if ~isempty(Trials{j, 4}) && ~isnan(fromLeverDirection_j)
            x_from_j = Trials{j, 4}(:, 2);
            y_from_j = Trials{j, 4}(:, 3);
            idx = find(x_from_j>=xbeg & x_from_j<xend);
            if ~isempty(idx)
                y_values_from_lever{fromLeverDirection_j} = [y_values_from_lever{fromLeverDirection_j}; mean(y_from_j(idx))];
            end
        end
    end
    for kk =1:nToLever
        if length(y_values_to_lever{kk})>8
            y_means_to(kk, i) = mean(y_values_to_lever{kk});
            y_ci_to(:, i, kk) = bootci(1000, @mean, y_values_to_lever{kk});
        end
    end
    for kk =1:nFromLever
        if length(y_values_from_lever{kk})>8
            y_means_from(kk, i) = mean(y_values_from_lever{kk});
            y_ci_from(:, i, kk) = bootci(1000, @mean, y_values_from_lever{kk});
        end
    end
end

DataOut.TrajAverages = {'x_centers', 'y_means_to', 'y_ci_to', 'y_means_from', 'y_ci_from';
    x_centers, y_means_to, y_ci_to, y_means_from, y_ci_from};

% Display the extracted frame
figure;
imshow(frame);
title(sprintf('Frame %d from %s', frame_index, vid_name));
% also a side video clip
vid_name = ['Side_Press_' TimeStamp '.mp4'];
vid_meta = ['Side_Press_' TimeStamp '.mat'];

meta_file_side = load(fullfile(video_path, vid_meta));

t_toPress = 500; % 500 ms before presds
ind = find(meta_file_side.VideoInfo.EphysTimeStamps<meta_file_side.VideoInfo.Time-t_toPress, 1, 'last');

% Create VideoReader object
vid_file = fullfile(video_path, vid_name);
vidObjSide = VideoReader(vid_file);

% Frame index to extract
frame_index = ind;

% Read and extract the 100th frame
vidObjSide.CurrentTime = (frame_index - 1) / vidObj.FrameRate; % Convert frame index to time
frame = readFrame(vidObjSide);

% Display the extracted frame
figure;
imshow(frame);
title(sprintf('Side frame %d from %s', frame_index, vid_name));
set(groot, 'DefaultAxesFontSize', 7, 'DefaultAxesFontName', 'Arial');
%
% Interpolate SDF values for each time point in the table

sdf_values_org          =       interp1(sdf_unit.t_sdf_ms, sdf_unit.sdf, time_table, 'linear', 0);
sdf_values              =       sdf_values_org;
spike_rate_max          =       quantile(sdf_values, 0.95);
high_firing             =       sdf_values > 5; % Define threshold
FR_range                =       [quantile(sdf_values, .25) quantile(sdf_values(sdf_values>0), .75)];

DataOut.sdfValOrg       =       {sdf_unit.t_sdf_ms, sdf_unit.sdf};
DataOut.sdfValMapped    =       {time_table, sdf_values};

close all;
hf = 26;
figure(hf); clf(hf)

figSize = [16 17]; % in cm
plotSize = [2*diff(xrange)/diff(yrange) 2];

set(hf,'units', 'centimeters', 'position', [2 2 figSize],...
    'color', 'w', 'name', 'trajectory and firing rate', 'paperpositionmode', 'auto', 'Visible', 'on')
% Force figure to pop up
set(hf, 'WindowStyle', 'normal');
% Ensure it ap

y_to_move = 4;

% A1 position
x_pos = 1.5;
y_pos = 10.5+y_to_move;

% Plot spikes
tSpk = sdf_unit.warp_out.press_raster{1}{1};
SpkMat = [sdf_unit.warp_out.press_raster{1}{2} sdf_unit.warp_out.press_raster{2}{2}];
[numTimePoints, numTrials] = size(SpkMat);
% compute spike density function
kernel_width = 20;
[~, sdf_mean, sdf_ci] = sdf(tSpk/1000, SpkMat, kernel_width, 1);
DataOut.SpkMat_Press     = {'time (ms)', 'Spike matrix', 'SDF(mean)', 'SDF(95ci)'; tSpk, SpkMat, sdf_mean, sdf_ci};

plotSizeSpikes = [1 1.25];
plotSizeSDF = [1 2];

% This is panel A1
annotation('textbox', 'units', 'centimeters', ...
    'position', [x_pos-1 y_pos+plotSizeSpikes(2) .5 .5], ...
    'String', 'A_1', 'EdgeColor', 'none', ...
    'Interpreter', 'tex',...
    'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');

ha_a1=axes;
% this is the plot for raster
set(ha_a1, 'nextplot', 'add', 'ydir', 'normal',...
    'units', 'centimeters', 'position', [x_pos y_pos plotSizeSpikes], ...
    'xlim', [tSpk(1) 500], 'ylim', [0 numTrials],'xtick',[], 'ticklength', [.025 .1]);
ha_a1.XColor = 'w'; % make sure the x axis is not visible

% Loop through each neuron and plot spikes as raster
for trialIdx = 1:numTrials
    spikeTimes = tSpk(SpkMat(:, trialIdx) > 0); % Get spike times for the neuron
    if ~isempty(spikeTimes)
        xx = [spikeTimes; spikeTimes];
        yy = [trialIdx; trialIdx+1];
        line(xx, yy, 'color', 'k');
    end
end
line([0 0], [0 numTrials], 'color', 'm', 'linestyle',':');
ylabel('Trials');

DataOut.sdf_unit        = sdf_unit; % lots of infomration
% add warped PSTH herewx_pos = x_pos+plotSize(1)+1+2;
% A2 position x_pos is the same as A1
y_pos = 8+y_to_move;
% This is panel A2
annotation('textbox', 'units', 'centimeters', ...
    'position', [x_pos-1 y_pos+plotSizeSDF(2) .5 .5], ...
    'String', 'A_2', 'EdgeColor', 'none', ...
    'Interpreter', 'tex',...
    'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');

ha_a2=axes;
yrange_spk = [0 1.2*max(sdf_ci(:))];
set(ha_a2, 'nextplot', 'add', 'ydir', 'normal',...
    'units', 'centimeters', 'position', [x_pos y_pos plotSizeSDF],...
    'xlim', [tSpk(1), 500]/1000, 'ylim', yrange_spk, 'ticklength', [.025 .1]);
plotshaded(tSpk/1000, sdf_ci, [.6 .6 .6])
plot(tSpk/1000, sdf_mean, 'k', 'linewidth', 1);
press_line = line([0 0], yrange_spk, 'color', 'm', 'linestyle',':');

xlabel('from press (s)')
ylabel('Firing rate (Hz)')
x_pos = x_pos +plotSizeSDF(1)+.75;

% Plot spikes
tSpk = sdf_unit.warp_out.release_raster{1}{1};
SpkMat = [sdf_unit.warp_out.release_raster{1}{2} sdf_unit.warp_out.release_raster{2}{2}];
[numTimePoints, numTrials] = size(SpkMat);

% for releases
x_pos = 3.25;
y_pos = 10.5+y_to_move;

% This is panel B1
annotation('textbox', 'units', 'centimeters', ...
    'position', [x_pos-.25 y_pos+plotSizeSpikes(2) .5 .5], ...
    'String', 'B1', 'EdgeColor', 'none', ...
    'Interpreter', 'tex',...
    'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');

ha_b1=axes;
% this is the plot for raster(release)
set(ha_b1, 'nextplot', 'add', 'ydir', 'normal',...
    'units', 'centimeters', 'position', [x_pos y_pos plotSizeSpikes], ...
    'xlim', [-500 1000], 'ylim', [0 numTrials],'xtick',[], 'ticklength', [.025 .1]);
ha_b1.YTick = [];
ha_b1.YColor = 'w';
ha_b1.XColor = 'w';

% Loop through each neuron and plot spikes as raster
for trialIdx = 1:numTrials
    spikeTimes = tSpk(SpkMat(:, trialIdx) > 0); % Get spike times for the neuron
    if ~isempty(spikeTimes)
        xx = [spikeTimes; spikeTimes];
        yy = [trialIdx; trialIdx+1];
        line(xx, yy, 'color', 'k');
    end
end
line([0 0], [0 numTrials], 'color', 'm', 'linestyle',':');

% compute spike density function
kernel_width = 20;
[~, sdf_mean, sdf_ci] = sdf(tSpk/1000, SpkMat, kernel_width, 1);
% add warped PSTH herewx_pos = x_pos+plotSize(1)+1+2;
DataOut.SpkMat_Release     = {'time (ms)', 'Spike matrix', 'SDF(mean)', 'SDF(95ci)'; tSpk, SpkMat, sdf_mean, sdf_ci};

y_pos = 8+y_to_move;
% This is panel B2
annotation('textbox', 'units', 'centimeters', ...
    'position', [x_pos-.25 y_pos+plotSizeSDF(2) .5 .5], ...
    'String', 'B_2', 'EdgeColor', 'none', ...
    'Interpreter', 'tex',...
    'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');
if max(sdf_ci(:))*1.1>yrange_spk(2)
    yrange_spk(2) = max(sdf_ci(:))*1.1;
    press_line.YData = yrange_spk;
end
set(ha_a2, 'ylim', yrange_spk);

ha_b2=axes;
set(ha_b2, 'nextplot', 'add', 'ydir', 'normal',...
    'units', 'centimeters', 'position', [x_pos y_pos plotSizeSDF], ...
    'xlim', [-500 1000]/1000, 'ylim', yrange_spk, 'ticklength', [.025 .1]);
ha_b2.YTick = [];
ha_b2.YColor = 'w';

plotshaded(tSpk/1000, sdf_ci, [.6 .6 .6])
plot(tSpk/1000, sdf_mean, 'k', 'linewidth', 1);
line([0 0], yrange_spk, 'color', 'm', 'linestyle',':');
xlabel('release (s)')

% also compute poke (but won't plot it)
% Plot spikes
tSpk = sdf_unit.warp_out.poke_raster{1}{1};
SpkMat = [sdf_unit.warp_out.poke_raster{1}{2} sdf_unit.warp_out.poke_raster{2}{2}];
% compute spike density function
kernel_width = 20;
[~, sdf_mean, sdf_ci] = sdf(tSpk/1000, SpkMat, kernel_width, 1);
DataOut.SpkMat_Poke     = {'time (ms)', 'Spike matrix', 'SDF(mean)', 'SDF(95ci)'; tSpk, SpkMat, sdf_mean, sdf_ci};


% coordinates for panel C (single trial )
y_pos = 4+y_to_move;
x_pos = 1.25;

% This is panel C
annotation('textbox', 'units', 'centimeters', ...
    'position', [x_pos-.5 y_pos+plotSize(2) .5 .5], ...
    'String', 'C', 'EdgeColor', 'none', ...
    'Interpreter', 'none',...
    'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');

% Plot movement of a single trial (with head direction also plotted)
ha_c = axes;
set(ha_c, 'nextplot', 'add', 'box', 'on', 'ydir', 'reverse', 'units', 'centimeters', ...
    'position', [x_pos y_pos plotSize], 'xlim', xrange, 'ylim', yrange,...
    'XTickLabel', [], 'YtickLabel', [], 'ticklength', [.025 .1]);

% Select a trial for illustrating
tReleases = sort(tReleases);
% tPress = 1043849;
%for m =1:length(ind_examples)
my_example = ['Top_Press_' TimeStamp];
% my_example = trial_names{ind_examples(m)};
% Extract the number at the end using regular expressions
num_str = regexp(my_example, '\d+$', 'match');

% Convert to a number
if ~isempty(num_str)
    tPress = str2double(num_str{1});
end

DataOut.Example = my_example;

disp(tPress);
tRelease = tReleases(find(tReleases>tPress, 1, 'first'));
tPokes = sort(tPokes);
tPoke = tPokes(find(tPokes>tRelease, 1, 'first'));
disp(tRelease)
disp(tPoke)
tReleaseRelative    = tRelease-tPress;

disp(my_example)
t_example                   =       TrajTableAll.Time(strcmp(TrajTableAll.Source, my_example));
t_example_org               =       t_example;
t_example_relative          =       t_example - tPress; % this the time relative the press.
t_example                   =       t_example -t_example(1);
x_example                   =       x(strcmp(TrajTableAll.Source, my_example));
y_example                   =       y(strcmp(TrajTableAll.Source, my_example));
x_example_org               =       x(strcmp(TrajTableAll.Source, my_example));
y_example_org               =       y(strcmp(TrajTableAll.Source, my_example));
head_example                =       TrajTableAll.head_angle(strcmp(TrajTableAll.Source, my_example));

% extract spike times within t_example
ispk_times                  = sdf_unit.spk_time_ms;
spk_example                 = ispk_times(ispk_times>t_example_org(1) & ispk_times<t_example_org(end));
spk_example_org         = spk_example;
spk_example                 = spk_example-tPress;
move_example        = TrajTableAll.movement_angle(strcmp(TrajTableAll.Source, my_example));
vel_example         = TrajTableAll.velocity(strcmp(TrajTableAll.Source, my_example));
sdf_values_example  = sdf_values_org(strcmp(TrajTableAll.Source, my_example));
sdf_values_example_org = sdf_values_example;
high_firing_example = high_firing(strcmp(TrajTableAll.Source, my_example));
ind_moving = extractMovement(vel_example, t_example);
move_example(~ind_moving) = NaN;
turning_example_org      = atan2(sin(move_example-head_example), cos(move_example-head_example));
move_example_org = move_example;
vel_example_org = vel_example;
head_example_org = head_example;
% here
x_10 = min(x_example) + 0.1*(max(x_example)-min(x_example));
x_90 = min(x_example) + 0.9*(max(x_example)-min(x_example));
ind_selected        = find(x_example< x_90 & x_example>x_10); % the point is not to include too much data when the rat is not moving

DataOut.ExampleTraj = {'time (ms)', 'x', 'y', 'move_direction', 'head_direction', 'velocity', 'spk', 'sdf', 'Press/Release/Poke time (ms)';...
    t_example_org, x_example_org, y_example_org, move_example, head_example, vel_example,spk_example_org, sdf_values_example, [tPress tRelease tPoke]};

t_example           = t_example(ind_selected);
x_example           = x_example(ind_selected);
y_example           = y_example(ind_selected);
head_example        = head_example(ind_selected);
move_example        = move_example(ind_selected);
vel_example         = vel_example(ind_selected);

turning_example      = atan2(sin(move_example-head_example), cos(move_example-head_example));
sdf_values_example   = sdf_values_example(ind_selected);

marker_sizes_example = 10 + 0 * (sdf_values_example - min(sdf_values)) / (spike_rate_max - min(sdf_values));
high_firing_example = high_firing_example(ind_selected);

% Normalize firing rate values to [0, 1] for colormap mapping
min_val = min(sdf_values_example);
max_val = max(sdf_values_example);
min_val = min(FR_range);
max_val = max(FR_range);
normalized_values = (sdf_values_example - min_val) / (max_val - min_val);
normalized_values(normalized_values>1) = 1;
normalized_values(normalized_values<0) = 0;

% Get parula colormap
num_colors = 256; % Number of colors in colormap
colormap_parula = hot(num_colors);

% Map normalized values to colormap indices
color_indices = round(normalized_values * (num_colors - 1)) + 1;
dot_colors = colormap_parula(color_indices, :);

% plot these first
% Select 20% of the data, evenly distributed
plot_ratio = 0.25;
num_points = length(x_example);
indices = round(linspace(1, num_points, round(plot_ratio * num_points)));

% Extract subsampled data
x_sub = x_example(indices);
y_sub = y_example(indices);
head_example_sub = head_example(indices);
angle_sub = move_example(indices);
vel_sub = vel_example(indices);
dot_colors_sub = dot_colors(indices, :);
% Plot the randomly sampled points for hsc1 (before high firing)

% Compute arrow components
scale = 80; % the length doesn't represent anything
dx = scale*vel_sub .* cos(angle_sub); % X-component of arrow
dy = -scale*vel_sub .* sin(angle_sub); % Y-component of arrow
%
scale3 = 80;
dx_heado = scale3.*cos(head_example_sub);
dy_heado = -scale3.*sin(head_example_sub);

for i=1:length(x_sub)
    q = quiver(ha_c, x_sub(i), y_sub(i), dx_heado(i), dy_heado(i), 0,...
        'Color', [.5 .5 .5], 'LineWidth', .5, 'MaxHeadSize', 0.5);
    q.ShowArrowHead = 'off';
    q.Marker = '.';
    q.LineWidth = .5;
    q.MaxHeadSize = 2;
end

hsc1 = scatter(ha_c, x_sub, y_sub, ...
    marker_sizes_example(indices), sdf_values_example(indices), 'filled', ...
    'Marker', 'o',  'MarkerEdgeColor', 'None', ...
    'Linewidth', 0.25);

colormap(ha_c, 'hot')
%end
hold off
% Labels and title
title(sprintf('Press: %s ms',TimeStamp), 'fontsize', 8);
grid on;
set(gca, 'ydir', 'reverse')

hbar = colorbar; % Show colorbar for firing rate
set(hbar, 'units', 'centimeters',...
    'position', [x_pos+plotSize(1)+0.1 y_pos .15 plotSize(2)])

hbar.Label.String = 'Firing rate (Hz)';
hbar.Label.Rotation = 90; % Rotate the colorbar label
hbar.Label.VerticalAlignment = 'Middle';
hbar.Label.Position(1) = hbar.Label.Position(1) + .5; % Adjust label position horizontally
hbar.Label.Position(2) = hbar.Label.Position(2); %
caxis(FR_range); % Set color axis to match SDF range

%% Method 1 | Plot trajectory with color-coded firing rate
rng(10);
% y_pos = y_pos + plotSize(2)+1.5;
% FR_range = [min(sdf_values_example) max(sdf_values_example)*0.9];
% plot two blue rectangles as port and lever
width_box = 40;
length_box = 150;
rectangle('Position', [ha_c.XLim(1), 280, width_box, length_box], 'EdgeColor', 'none', 'FaceColor', [0 173 238]/255, 'LineWidth', 2);
rectangle('Position', [ha_c.XLim(2)-width_box, 280, width_box, length_box], 'EdgeColor', 'none', 'FaceColor', [0 173 238]/255, 'LineWidth', 2);
y_pos = y_pos -plotSize(2)-1;

% This is panel D1, plotting approach to lever
annotation('textbox', 'units', 'centimeters', ...
    'position', [x_pos-.5 y_pos+plotSize(2)+0.25 plotSize(1) .5], ...
    'String', 'D_1 | to lever', 'EdgeColor', 'none', ...
    'Interpreter', 'tex',...
    'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');

ha_d1 = axes;
set(ha_d1, 'nextplot', 'add', 'box', 'on', 'ydir', 'reverse', 'units', 'centimeters', ...
    'position', [x_pos y_pos plotSize], 'xlim', xrange, 'ylim', yrange, 'ticklength', [.025 .1],...
    'xticklabel', [], 'yticklabel', []);
line([500 600], [780 780], 'color', 'k','linewidth', 2)
rectangle('Position', [ha_d1.XLim(1), 280, width_box, length_box], 'EdgeColor', 'none', 'FaceColor', [0 173 238]/255, 'LineWidth', 2);
rectangle('Position', [ha_d1.XLim(2)-width_box, 280, width_box, length_box], 'EdgeColor', 'none', 'FaceColor', [0 173 238]/255, 'LineWidth', 2);
grid on

% This is panel D2, plotting leaving lever
y_pos = y_pos - plotSize(2)-1.5;

annotation('textbox', 'units', 'centimeters', ...
    'position', [x_pos-.5 y_pos+plotSize(2)+0.25 2*plotSize(1) .5], ...
    'String', 'D_2 | from lever', 'EdgeColor', 'none', ...
    'Interpreter', 'tex',...
    'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');

ha_d2 = axes;
set(ha_d2, 'nextplot', 'add', 'box', 'on', 'ydir', 'reverse', 'units', 'centimeters', ...
    'position', [x_pos y_pos plotSize], 'xlim', xrange, 'ylim', yrange, 'ticklength', [.025 .1],...
    'xticklabel', [], 'yticklabel', []);
grid on
line([500 600], [780 780], 'color', 'k','linewidth', 2)
rectangle('Position', [ha_d2.XLim(1), 280, width_box, length_box], 'EdgeColor', 'none', 'FaceColor', [0 173 238]/255, 'LineWidth', 2);
rectangle('Position', [ha_d2.XLim(2)-width_box, 280, width_box, length_box], 'EdgeColor', 'none', 'FaceColor', [0 173 238]/255, 'LineWidth', 2);
%

% To lever
xyt = Trials(:, 2);
spks = Trials(:, 6);
not_empty = cellfun(@(x)~isempty(x), xyt);
xyt_ = xyt(not_empty);
spks = spks(not_empty);

% n_plot = 50;
% ind_plot = randperm(length(xyt_), min(length(xyt_), n_plot));
dot_size = 5;
circle_size = 5;
traj_color = [.8 .8 .8];
% Plot all these trials
for kk =1:length(xyt_)
    xk = xyt_{kk}(:, 2);
    yk = xyt_{kk}(:, 3);
    scatter(ha_d1, xk, yk, dot_size, '.', 'MarkerEdgeColor',traj_color);
    % scatter(ha_d1, xk(sps_k_mapped>0), yk(sps_k_mapped>0), circle_size, 'o', 'MarkerEdgeColor','none', 'MarkerFaceColor','r', 'MarkerFaceAlpha',.6);
end

for kk =1:length(xyt_)
    tk = xyt_{kk}(:, 1);
    if length(tk)<10
        continue
    end
    xk = xyt_{kk}(:, 2);
    yk = xyt_{kk}(:, 3);
    sp_k = spks{kk};
    sps_k_mapped = [0 histcounts(sp_k, tk)];
    scatter(ha_d1, xk(sps_k_mapped>0), yk(sps_k_mapped>0), circle_size, 'o', 'MarkerEdgeColor','none', 'MarkerFaceColor','r', 'MarkerFaceAlpha',.6);
end

% From lever
xyt = Trials(:, 4);
spks = Trials(:, 7);
not_empty = cellfun(@(x)~isempty(x), xyt);
xyt_ = xyt(not_empty);
spks = spks(not_empty);

% n_plot = 50;
% ind_plot = randperm(length(xyt_), min(length(xyt_), n_plot));
dot_size = 5;
circle_size = 5;
traj_color = [.8 .8 .8];
% Plot all these trials
for kk =1:length(xyt_)
    xk = xyt_{kk}(:, 2);
    yk = xyt_{kk}(:, 3);
    scatter(ha_d2, xk, yk, dot_size, '.', 'MarkerEdgeColor',traj_color);
    % scatter(ha_d1, xk(sps_k_mapped>0), yk(sps_k_mapped>0), circle_size, 'o', 'MarkerEdgeColor','none', 'MarkerFaceColor','r', 'MarkerFaceAlpha',.6);
end

for kk =1:length(xyt_)
    tk = xyt_{kk}(:, 1);
    if length(tk)<10
        continue
    end
    xk = xyt_{kk}(:, 2);
    yk = xyt_{kk}(:, 3);
    sp_k = spks{kk};
    sps_k_mapped = [0 histcounts(sp_k, tk)];
    scatter(ha_d2, xk(sps_k_mapped>0), yk(sps_k_mapped>0), circle_size, 'o', 'MarkerEdgeColor','none', 'MarkerFaceColor','r', 'MarkerFaceAlpha',.6);

end

% Coordinates for panel E: single trial ephys
x_pos = 6.75;
y_pos = 10+y_to_move;
plotSize_dynamics = [2.5 1.25]; % this is to plot x versus t
% This is panel E （plot the activity of current trial
% I want to plot spike raster, along with x(t)

% This is panel E （plot the activity of current trial)
% for approach cell
annotation('textbox', 'units', 'centimeters', ...
    'position', [x_pos-.75 y_pos+plotSize_dynamics(2)+0.2 .5 .5], ...
    'String', 'E', 'EdgeColor', 'none', ...
    'Interpreter', 'none',...
    'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');

xrange2 = xrange;
xrange2(2) = xrange2(2)+100;
ha_e=axes;
t_example_org_relative = t_example_org-tPress;
ind_plot = find(t_example_org_relative<=3000); % plot less than 2000 ms after press

set(ha_e, 'nextplot', 'add','units', 'centimeters',...
    'position', [x_pos y_pos plotSize_dynamics(1) plotSize_dynamics(2)], ...
    'xlim', [t_example_org_relative(1) t_example_org_relative(ind_plot(end))]/1000, ...
    'ylim', xrange2, ...
    'xtick', (-3:3),...
    'xticklabel', [],...
    'ticklength', [.025 .1]);

plotshaded([0 tReleaseRelative]/1000, [xrange2(1) xrange2(1); xrange2(2) xrange2(2)], [.6 .6 .6]); % Hold period
hpx=plot(t_example_org_relative(ind_plot)/1000, x_example_org(ind_plot), 'color', 'k');
hpy=plot(t_example_org_relative(ind_plot)/1000, y_example_org(ind_plot), 'color', 'k', 'linestyle',':');

% spike raster
line([spk_example; spk_example]/1000, [xrange2(2); xrange2(2)-200], 'color', 'k')
lgd = legend([hpx, hpy], {'x', 'y'});
ylabel('location')
set(lgd, 'units', 'centimeters',...
    'Position', [x_pos+plotSize_dynamics(1)+1.5 y_pos+plotSize_dynamics(2)-.5 .25 .5])  % [left, bottom, width, height]
lgd.Position(3)=0.5;
lgd.Box = 'off';

% find out the max spike time
tMax                = t_example_org(sdf_values_example_org==max(sdf_values_example_org));
tMaxRel             = t_example_relative(sdf_values_example_org==max(sdf_values_example_org))/1000;

harrow              = annotation('arrow');  % store the arrow information in ha
harrow.Parent       = gca;           % associate the arrow the the current axes
harrow.X            = [tMaxRel tMaxRel];          % the location in data units
harrow.Y            = [xrange2(2)-600 xrange2(2)-300];
harrow.LineWidth    = 1;          % make the arrow bolder for the picture
harrow.HeadWidth    = 5;
harrow.HeadLength   = 5;
harrow.Color        = 'r';

ha_e2 = axes; % same , overlapped axes
set(ha_e2, 'nextplot', 'add','units', 'centimeters',...
    'position', [x_pos y_pos plotSize_dynamics(1) plotSize_dynamics(2)], ...
    'YAxisLocation', 'right',...
    'xlim', [t_example_org_relative(1) t_example_org_relative(ind_plot(end))]/1000, ...
    'ylim', [-pi pi], ...
    'xticklabel', [],...
    'ticklength', [.025 .1]);

ha_e2.Color = 'none';
ha_e2.YColor = 'b';

tPlotBefore = t_example_org_relative(ind_plot)<0;
tPlotAfter = t_example_org_relative(ind_plot)>tReleaseRelative;

hp_turning = scatter(t_example_org_relative(ind_plot(tPlotBefore))/1000,...
    turning_example_org(ind_plot(tPlotBefore)), 'o', 'filled', 'markerfacecolor', 'b',...
    'markeredgecolor', 'none', 'sizedata', 4);
hp_turning = scatter(t_example_org_relative(ind_plot(tPlotAfter))/1000,...
    turning_example_org(ind_plot(tPlotAfter)), 'o', 'filled', 'markerfacecolor', 'b',...
    'markeredgecolor', 'none', 'sizedata', 4);
ylabel('Turning angle')

% illustrate how the turning angle come around
tocheck = 0;
if tocheck

    figure(46); clf(46)
    hax1 = subplot(2, 1, 1);
    set(hax1, 'nextplot', 'add',...
        'xlim', [t_example_org_relative(1) t_example_org_relative(ind_plot(end))]/1000, ...
        'ylim', xrange2, ...
        'xticklabel', [],...
        'ticklength', [.0125 .1]);

    plotshaded([0 tReleaseRelative]/1000, [xrange2(1) xrange2(1); xrange2(2) xrange2(2)], [.6 .6 .6]); % Hold period
    plot(t_example_org_relative(ind_plot)/1000, x_example_org(ind_plot), 'color', 'k', 'linewidth', 1);
    plot(t_example_org_relative(ind_plot)/1000, y_example_org(ind_plot), 'color', 'k', 'linestyle',':', 'linewidth', 1);
    % spike raster
    line([spk_example; spk_example]/1000, [xrange2(2); xrange2(2)-200], 'color', 'k')
    line([-2 -1], [100 100], 'color', 'b', 'linewidth', 2)

    hax=subplot(2, 1, 2);
    set(hax, 'nextplot', 'add',...
        'YAxisLocation', 'left',...
        'xlim', [t_example_org_relative(1) t_example_org_relative(ind_plot(end))]/1000, ...
        'ylim', [-pi pi], ...
        'ticklength', [.0125 .1]);
    xplot       = t_example_org_relative(ind_plot)/1000;
    yplot_move  = move_example_org(ind_plot);
    yplot_head  = head_example_org(ind_plot);
    yplot_vel   = vel_example_org(ind_plot);

    % atan2(sin(a), cos(a))
    yplot_turn  = turning_example_org(ind_plot);

    hp_move = scatter(xplot,...
        yplot_move, 'o', 'filled', 'markerfacecolor', 'k',...
        'markeredgecolor', 'none', 'sizedata', 4);
    hp_head = scatter(xplot,...
        yplot_head, 'o', 'filled', 'markerfacecolor', 'r',...
        'markeredgecolor', 'none', 'sizedata', 4);
    hp_turn = scatter(xplot,...
        yplot_turn, '+', 'filled', 'markerfacecolor', 'm',...
        'markeredgecolor', 'm', 'sizedata', 10);
    legend('movement', 'head', 'difference')
end
% Now plot this frame (place a try-end condition here)
try
    % find out the frame number
    [~, indFrame] = min(abs(meta_file.VideoInfo.EphysTimeStamps-tMax));
    % This is panel F1 （top frame)
    y_pos = 7+y_to_move;
    annotation('textbox', 'units', 'centimeters', ...
        'position', [x_pos-.75 y_pos+plotSize(2)+0.25 .5 .5], ...
        'String', 'F1', 'EdgeColor', 'none', ...
        'Interpreter', 'none',...
        'HorizontalAlignment', 'center', 'FontSize', 10,...
        'fontweight', 'bold');

    ha_f=axes;
    set(ha_f, 'nextplot', 'add','units', 'centimeters',...
        'position', [x_pos y_pos plotSize(1) plotSize(2)], ...
        'ticklength', [.025 .1]);
    % Frame index to extract
    frame_index = indFrame;

    % Read and extract the 100th frame
    vidObj.CurrentTime = (frame_index - 1) / vidObj.FrameRate; % Convert frame index to time
    frame = readFrame(vidObj);

    DataOut.TopFrame = frame;

    % Display the extracted frame
    imshow(frame);
    hold on
    scatter(x_example, y_example, '.');
    scatter(x_example_org(sdf_values_example_org==max(sdf_values_example_org)),...
        y_example_org(sdf_values_example_org==max(sdf_values_example_org)), 'o', 'filled',...
        'markerfacecolor', 'r', 'sizedata', 25);

    % adjusting size. make sure height is fixed.
    plotSize2(1) = size(frame, 2)*plotSize(1)/diff(xrange);
    plotSize2(2) = size(frame, 1)*plotSize(2)/diff(yrange);

    ha_f.Position(3) = plotSize2(1);
    ha_f.Position(4) = plotSize2(2);
    ha_f.Position(1) = x_pos;
    ha_f.Position(2) = y_pos;

    % Side frame
    y_pos = y_pos - plotSize(2)-1;
    [~, indFrameSide] = min(abs(meta_file_side.VideoInfo.EphysTimeStamps-tMax));

    % This is panel F2 （top frame)
    annotation('textbox', 'units', 'centimeters', ...
        'position', [x_pos-.75 y_pos+plotSize(2)+0.5 .5 .5], ...
        'String', 'F2', 'EdgeColor', 'none', ...
        'Interpreter', 'none',...
        'HorizontalAlignment', 'center', 'FontSize', 10,...
        'fontweight', 'bold');
    ha_f2=axes;
    set(ha_f2, 'nextplot', 'add','units', 'centimeters',...
        'position', [x_pos y_pos plotSize(1) plotSize(2)], ...
        'ticklength', [.025 .1]);
    % Frame index to extract
    frame_index = indFrameSide;

    % Read and extract the 100th frame
    vidObjSide.CurrentTime = (frame_index - 1) / vidObj.FrameRate; % Convert frame index to time
    side_frame = readFrame(vidObjSide);
    DataOut.SideFrame = side_frame;

    % Display the extracted frame
    imshow(side_frame);

    plotSize3(1) = plotSize2(1);
    plotSize3(2) = size(side_frame, 1)*plotSize2(1)/size(side_frame, 2);

    ha_f2.Position(3) = plotSize3(1);
    ha_f2.Position(4) = plotSize3(2);

    DataOut.ExampleFrame = {frame, side_frame};
end

% Initialize the grid for averaging
numBinsY = length(yBinEdges)-1;
numBinsX = length(xBinEdges)-1;

rateGridBefore = zeros(numBinsY, numBinsX);
countGridBefore = zeros(numBinsY, numBinsX);
rateGridAfter = zeros(numBinsY, numBinsX);
countGridAfter = zeros(numBinsY, numBinsX);

% Assign each (xi, yi) to a grid cell and accumulate firing rates
% Seperating before and after press
for i = 1:length(x)
    if is_before(i)
        % Find the bin indices for the current point
        xBin = find(x(i) >= xBinEdges, 1, 'last');
        yBin = find(y(i) >= yBinEdges, 1, 'last');
        if ~isempty(xBin) && ~isempty(yBin)
            % Skip points falling outside the grid boundaries
            if xBin > numBinsX || yBin > numBinsY || xBin < 1 || yBin < 1
                continue;
            end
            % Accumulate the firing rate in the corresponding grid cell
            rateGridBefore(yBin, xBin) = rateGridBefore(yBin, xBin) + sdf_values_org(i);
            countGridBefore(yBin, xBin) = countGridBefore(yBin, xBin) + 1;
        end
    else
        % Find the bin indices for the current point
        xBin = find(x(i) >= xBinEdges, 1, 'last');
        yBin = find(y(i) >= yBinEdges, 1, 'last');
        if ~isempty(xBin) && ~isempty(yBin)
            % Skip points falling outside the grid boundaries
            if xBin > numBinsX || yBin > numBinsY || xBin < 1 || yBin < 1
                continue;
            end
            % Accumulate the firing rate in the corresponding grid cell
            rateGridAfter(yBin, xBin) = rateGridAfter(yBin, xBin) + sdf_values_org(i);
            countGridAfter(yBin, xBin) = countGridAfter(yBin, xBin) + 1;
        end
    end
end

% Calculate the average firing rate for each grid cell
avgRateGridBefore = rateGridBefore ./ countGridBefore;
avgRateGridBefore(isnan(avgRateGridBefore)) = 0;  % Replace NaN with 0 for empty cells

avgRateGridAfter = rateGridAfter ./ countGridAfter;
avgRateGridAfter(isnan(avgRateGridAfter)) = 0;  % Replace NaN with 0 for empty cells

% Apply Gaussian smoothing
sigma = 2.5;  % Standard deviation for Gaussian kernel
kernelSize = 5;  % Size of the Gaussian kernel
[xx, yy] = meshgrid(-floor(kernelSize/2):floor(kernelSize/2), -floor(kernelSize/2):floor(kernelSize/2));
gaussianKernel = exp(-(xx.^2 + yy.^2) / (2 * sigma^2));
gaussianKernel = gaussianKernel / sum(gaussianKernel(:));  % Normalize the kernel
% Convolve the grid with the Gaussian kernel
smoothedRateGridBefore = conv2(avgRateGridBefore, gaussianKernel, 'same');
smoothedRateGridAfter= conv2(avgRateGridAfter, gaussianKernel, 'same');
RateGrouped = [smoothedRateGridBefore(:); smoothedRateGridAfter(:)];
FR_range2 =[min(RateGrouped) max(RateGrouped)];

% added 2025/04/19
% project spike number to each grid (without averaging to make sure dwell time won't decrease spike count) spk_train
% relevant parameters
% this is the spike train: spk_train
% time_table      =      TrajTableAll.Time; % Replace with the Time column from your table
% x                     =       TrajTableAll.x; % x positions
% y                     =       TrajTableAll.y; % y positions

[spikeCountGridBefore, spikeCountGridDensityBefore, locationCountGridBefore, avgSpikeCountGridBefore]    =       countSpikes(time_table(is_before==1), x(is_before==1), y(is_before==1), spk_train, xBinEdges, yBinEdges);
[spikeCountGridAfter, spikeCountGridDensityAfter, locationCountGridAfter, avgSpikeCountGridAfter]       =       countSpikes(time_table(is_before==0), x(is_before==0), y(is_before==0), spk_train, xBinEdges, yBinEdges);

smoothedspikeCountGridBefore            =           conv2(spikeCountGridBefore, gaussianKernel, 'same');
smoothedspikeCountGridAfter             =           conv2(spikeCountGridAfter, gaussianKernel, 'same');

smoothedspikeCountGridDensityBefore     =           conv2(spikeCountGridDensityBefore, gaussianKernel, 'same');
smoothedspikeCountGridDensityAfter      =           conv2(spikeCountGridDensityAfter, gaussianKernel, 'same');

smoothedavgSpikeCountGridBefore         =           conv2(avgSpikeCountGridBefore, gaussianKernel, 'same');
smoothedavgSpikeCountGridAfter          =           conv2(avgSpikeCountGridAfter, gaussianKernel, 'same');

spikeCountGrouped                       =           [smoothedspikeCountGridBefore(:); smoothedspikeCountGridAfter(:)];
spikeCountRange                         =           [min(spikeCountGrouped) max(spikeCountGrouped)]/sum(spikeCountGrouped);

% Plot the 2D color map
y_pos = 5;
if plot_rate
    % This is panelg G1
    annotation('textbox', 'units', 'centimeters', ...
        'position', [x_pos-.75 y_pos+plotSize(2)+0.5 plotSize(1)*2.5  .5], ...
        'String', 'G_1 | to lever', 'EdgeColor', 'none', ...
        'Interpreter', 'tex',...
        'HorizontalAlignment', 'Left', 'FontSize', 10,...
        'fontweight', 'bold');
    ha_g1=axes;
    set(ha_g1, 'nextplot', 'add', 'ydir', 'reverse', 'units', 'centimeters',...
        'position', [x_pos y_pos plotSize], 'xlim', xrange, 'ylim', yrange, ...
        'ticklength', [.025 .1], 'xticklabel', [], 'yticklabel', []);

    imagesc(ha_g1, xBinEdges, yBinEdges, smoothedRateGridBefore, FR_range2);
    set(ha_g1, 'YDir', 'reverse');  % Ensure the y-axis is oriented correctly
    title('average trajectory/rate');
    colormap(ha_g1, 'turbo');

    y_pos = y_pos-plotSize(2)-1.5;
    % This is panelg G2
    annotation('textbox', 'units', 'centimeters', ...
        'position', [x_pos-.75 y_pos+plotSize(2)+0.5 plotSize(1)*2.5 .5], ...
        'String', 'G_2 | from lever', 'EdgeColor', 'none', ...
        'Interpreter', 'tex',...
        'HorizontalAlignment', 'left', 'FontSize', 10,...
        'fontweight', 'bold');
    ha_g2=axes;
    set(ha_g2, 'nextplot', 'add', 'ydir', 'reverse', 'units', 'centimeters',...
        'position', [x_pos y_pos plotSize], 'xlim', xrange, 'ylim', yrange, ...
        'ticklength', [.025 .1], 'xticklabel', [], 'yticklabel', []);

    imagesc(ha_g2, xBinEdges, yBinEdges, smoothedRateGridAfter, FR_range2);
    set(ha_g2, 'YDir', 'reverse');  % Ensure the y-axis is oriented correctly
    title('average trajectory/rate');
    colormap(ha_g2, 'turbo');

else
    % This is panelg G1
    annotation('textbox', 'units', 'centimeters', ...
        'position', [x_pos-.75 y_pos+plotSize(2)+0.5 plotSize(1)*2.5  .5], ...
        'String', 'G_1 | to lever', 'EdgeColor', 'none', ...
        'Interpreter', 'tex',...
        'HorizontalAlignment', 'Left', 'FontSize', 10,...
        'fontweight', 'bold');
    ha_g1=axes;
    set(ha_g1, 'nextplot', 'add', 'ydir', 'reverse', 'units', 'centimeters',...
        'position', [x_pos y_pos plotSize], 'xlim', xrange, 'ylim', yrange, ...
        'ticklength', [.025 .1], 'xticklabel', [], 'yticklabel', []);

    imagesc(ha_g1, xBinEdges, yBinEdges, smoothedspikeCountGridBefore/sum(spikeCountGrouped), spikeCountRange);
    set(ha_g1, 'YDir', 'reverse');  % Ensure the y-axis is oriented correctly
    title('spike count prob.');
    colormap(ha_g1, 'turbo');

    y_pos = y_pos-plotSize(2)-1.5;
    % This is panelg G2
    annotation('textbox', 'units', 'centimeters', ...
        'position', [x_pos-.75 y_pos+plotSize(2)+0.5 plotSize(1)*2.5 .5], ...
        'String', 'G_2 | from lever', 'EdgeColor', 'none', ...
        'Interpreter', 'tex',...
        'HorizontalAlignment', 'left', 'FontSize', 10,...
        'fontweight', 'bold');
    ha_g2=axes;
    set(ha_g2, 'nextplot', 'add', 'ydir', 'reverse', 'units', 'centimeters',...
        'position', [x_pos y_pos plotSize], 'xlim', xrange, 'ylim', yrange, ...
        'ticklength', [.025 .1], 'xticklabel', [], 'yticklabel', []);

    imagesc(ha_g2, xBinEdges, yBinEdges, smoothedspikeCountGridAfter/sum(spikeCountGrouped), spikeCountRange);
    set(ha_g2, 'YDir', 'reverse');  % Ensure the y-axis is oriented correctly
    title('spike count prob.');
    colormap(ha_g2, 'turbo');

end

DataOut.SpikeRate2D.xBinEdges                               =       xBinEdges;
DataOut.SpikeRate2D.yBinEdges                               =       yBinEdges;
DataOut.SpikeRate2D.smoothedRateGridBefore                  =       smoothedRateGridBefore;
DataOut.SpikeRate2D.smoothedRateGridAfter                   =       smoothedRateGridAfter;

DataOut.SpikeCount2D.xBinEdges                              =       xBinEdges;
DataOut.SpikeCount2D.yBinEdges                              =       yBinEdges;
DataOut.SpikeCount2D.smoothedspikeCountGridBefore           =       smoothedspikeCountGridBefore;
DataOut.SpikeCount2D.smoothedspikeCountGridAfter            =       smoothedspikeCountGridAfter;
DataOut.SpikeCount2D.smoothedspikeCountGridDensityBefore    =       smoothedspikeCountGridDensityBefore;
DataOut.SpikeCount2D.smoothedspikeCountGridDensityAfter     =       smoothedspikeCountGridDensityAfter;

DataOut.SpikeCount2D.locationCountGridBefore                =       locationCountGridBefore;
DataOut.SpikeCount2D.locationCountGridAfter                 =       locationCountGridAfter;
DataOut.SpikeCount2D.smoothedavgSpikeCountGridBefore        =       smoothedavgSpikeCountGridBefore;
DataOut.SpikeCount2D.smoothedavgSpikeCountGridAfter         =       smoothedavgSpikeCountGridAfter;
DataOut.SpikeCount2D.spikeCountGrouped                      =       sum(spikeCountGrouped);
DataOut.SpikeCount2D.Explained                              =       'Spike counts have been normalized to total spike number. The unit for density is 1/pxs^2';


c = colorbar; % Show colorbar for firing rate
set(c, 'units', 'centimeters', 'position', [x_pos+plotSize(1)+0.2 y_pos .15 plotSize(2)])
if plot_rate
    c.Label.String = 'Firing rate (Hz)';
else
    c.Label.String = 'Probability';
end
c.Label.Rotation = 90; % Rotate the colorbar label
c.Label.VerticalAlignment = 'bottom';
c.Label.Position(1) = c.Label.Position(1) + 1; % Adjust label position horizontally

% scale
line(ha_g1, [xrange(2)-150 xrange(2)-50], [yrange(2)-100 yrange(2)-100], 'color', 'w', 'linewidth', 2)
text(ha_g1, xrange(2)-150, yrange(2)-50, '100pix', 'fontsize', 5,'color', 'w')

line(ha_g2, [xrange(2)-150 xrange(2)-50], [yrange(2)-100 yrange(2)-100], 'color', 'w', 'linewidth', 2)
text(ha_g2, xrange(2)-150, yrange(2)-50, '100pix', 'fontsize', 5,'color', 'w')

to_color = [179, 216, 168]/255;
from_color = [234, 189, 230]/255;
% Plot average trajectory (This was computed around lines 79 ~ 117)

for i =1:length(x_centers)
    for j =1:nToLever
        if ~isnan(y_means_to(j, i))
            line(ha_g1, [x_centers(i) x_centers(i)], y_ci_to(:, i, j), 'color', to_color, 'linewidth', 1);
            scatter(ha_g1, x_centers(i), y_means_to(j, i), '.', 'filled', 'markerfacecolor', to_color,...
                'sizedata', 10, 'markeredgecolor', to_color);
        end
    end

    for j =1:nFromLever
        if ~isnan(y_means_from(j, i))
            line(ha_g2, [x_centers(i) x_centers(i)], y_ci_from(:, i, j), 'color', from_color, 'linewidth', 1);
            scatter(ha_g2, x_centers(i), y_means_from(j, i), '.', 'markerfacecolor', from_color,...
                'sizedata', 10, 'markeredgecolor', from_color);
        end
    end
end

line(ha_g1, [xrange(1)+20 xrange(1)+100], [yrange(1)+50 yrange(1)+50], 'color',to_color, 'linewidth', 2)
text(ha_g1, xrange(1)+150, yrange(1)+50, 'approaching', 'fontsize', 6,'color', to_color)

line(ha_g2, [xrange(1)+20 xrange(1)+100], [yrange(1)+50 yrange(1)+50], 'color',from_color, 'linewidth', 2)
text(ha_g2, xrange(1)+150, yrange(1)+50, 'leaving', 'fontsize', 6,'color', from_color)

%% Plot direction vs firing rate
vel     = TrajTableAll.velocity;
t       = TrajTableAll.Time;
theta   = TrajTableAll.movement_angle; % Convert to angles.
head_theta = TrajTableAll.head_angle; % this is head direciton

% not considering very slow movement
ind_moving = extractMovement(vel, t);

theta(~ind_moving)=NaN;
not_nan = ~isnan(theta);
% go through each trial
movement_direction = [];
velocity_direction = [];
to_press_direction = []; % 1 on the way to press, 0 on the way to drink
firing_rate_direction  = []; %sdf_values_org
head_direction = []; % this is the head direction
% Define sliding window parameters
window_size = 50; % in ms
step_size = 25; % in ms

for j =1:length(trial_names)
    x_j                 =   x(strcmp(TrajTableAll.Source, trial_names{j}));
    y_j                 =   y(strcmp(TrajTableAll.Source, trial_names{j}));
    t_j                 =   t(strcmp(TrajTableAll.Source, trial_names{j}));
    sdf_j               =   sdf_values_org(strcmp(TrajTableAll.Source, trial_names{j}));
    theta_j             =   theta(strcmp(TrajTableAll.Source, trial_names{j})); % this is head direction
    vel_j               =   vel(strcmp(TrajTableAll.Source, trial_names{j}));
    is_before_j         =   is_before(strcmp(TrajTableAll.Source, trial_names{j}));
    head_j              =   head_theta(strcmp(TrajTableAll.Source, trial_names{j}));

    ind_before_press = find(is_before_j>0);
    ind_after_press = find(is_before_j==0);

    if ~isempty(ind_before_press)
        x_j_before = x_j(ind_before_press);
        y_j_before = y_j(ind_before_press);
        t_j_before = t_j(ind_before_press);
        theta_j_before = theta_j(ind_before_press);
        sdf_j_before = sdf_j(ind_before_press);
        vel_j_before = vel_j(ind_before_press);
        head_j_before = head_j(ind_before_press);

        % Find the min and max times
        t_min = min(t_j_before);
        t_max = max(t_j_before);

        % Sliding window loop
        for t_start = t_min : step_size : (t_max - window_size)
            t_end = t_start + window_size;
            % Find indices of data points within the current window
            window_idx = (t_j_before >= t_start) & (t_j_before < t_end);
            % Compute means if there are points in the window
            % mean_out = angle_mean(angles)
            if any(window_idx)
                movement_direction      = [movement_direction; angle_mean(theta_j_before(window_idx))];
                velocity_direction      = [velocity_direction; mean(vel_j_before(window_idx))];
                to_press_direction      = [to_press_direction; 1];
                firing_rate_direction   = [firing_rate_direction; mean(sdf_j_before(window_idx))];
                head_direction = [head_direction; angle_mean(head_j_before(window_idx))];
            end
        end
    end

    if ~isempty(ind_after_press)
        x_j_after = x_j(ind_after_press);
        y_j_after = y_j(ind_after_press);
        t_j_after = t_j(ind_after_press);
        theta_j_after = theta_j(ind_after_press);
        vel_j_after = vel_j(ind_after_press);
        sdf_j_after = sdf_j(ind_after_press);
        head_j_after = head_j(ind_after_press);

        % Find the min and max times
        t_min = min(t_j_after);
        t_max = max(t_j_after);

        % Sliding window loop
        for t_start = t_min : step_size : (t_max - window_size)
            t_end = t_start + window_size;

            % Find indices of data points within the current window
            window_idx = (t_j_after >= t_start) & (t_j_after < t_end);

            % Compute means if there are points in the window
            if any(window_idx)
                movement_direction      = [movement_direction; angle_mean(theta_j_after(window_idx))];
                velocity_direction      = [velocity_direction; mean(vel_j_after(window_idx))];
                to_press_direction      = [to_press_direction; 0];
                firing_rate_direction   = [firing_rate_direction; mean(sdf_j_after(window_idx))];
                head_direction          = [head_direction; angle_mean(head_j_after(window_idx))];
            end
        end
    end
end
[velocity_direction, ind_sort]=sort(velocity_direction);
movement_direction = movement_direction(ind_sort);
head_angles_direction = head_direction(ind_sort);

% finding out the difference between movement direction and head angle, which is the turning angle
head_turning_angle = atan2(sin(movement_direction-head_angles_direction), cos(movement_direction-head_angles_direction));

velocity_direction = velocity_direction(ind_sort);
to_press_direction = to_press_direction(ind_sort);
firing_rate_direction = firing_rate_direction(ind_sort);
firing_rate = firing_rate_direction;

% Define movement direction bins
bin_edges = -pi : (pi/4) : pi;  % Bins from -π to π in steps of π/4
bin_centers = bin_edges(1:end-1) + diff(bin_edges)/2;  % Compute bin centers

% Assign each movement direction to a bin
bin_indices = discretize(movement_direction, bin_edges);
bin_indices_turning = discretize(head_turning_angle, bin_edges);

% Initialize storage for mean firing rates
firing_rate_avg = nan(size(bin_centers));
velocity_avg = nan(size(bin_centers));
firing_rate_ci = nan(2, length(bin_centers));

% Turning firing rate initiation
firing_rate_turning_avg = nan(size(bin_centers));
velocity_turning_avg = nan(size(bin_centers));
firing_rate_turning_ci = nan(2, length(bin_centers));

firing_rate_grouped = cell(size(bin_centers));
velocity_grouped = cell(size(bin_centers));

firing_rate_turning_grouped = cell(size(bin_centers));
velocity_turning_grouped = cell(size(bin_centers));

% Compute mean firing rate for each bin (direction tuning)
for i = 1:length(bin_centers)
    bin_data = firing_rate(bin_indices == i); % Extract firing rates for this bin
    bin_data_vel = velocity_direction(bin_indices == i); % Extract velocity for this bin

    firing_rate_grouped{i} = bin_data;
    velocity_grouped{i} = bin_data_vel;

    if ~isempty(bin_data)
        firing_rate_avg(i) = mean(bin_data);
        firing_rate_ci(:, i) = bootci(1000, @mean, bin_data);
    end
end

% Compute mean firing rate for each bin (turning tuning)
for i = 1:length(bin_centers)
    bin_data = firing_rate(bin_indices_turning == i); % Extract firing rates for this bin
    bin_data_vel = velocity_direction(bin_indices_turning == i); % Extract velocity for this bin

    firing_rate_turning_grouped{i} = bin_data;
    velocity_turning_grouped{i} = bin_data_vel;

    if ~isempty(bin_data)
        firing_rate_turning_avg(i) = mean(bin_data);
        firing_rate_turning_ci(:, i) = bootci(1000, @mean, bin_data);
    end
end

% Convert to polar coordinates
theta = bin_centers; % Movement direction (angle)
rho = firing_rate_avg; % Mean firing rate

% Close the circular plot by repeating the first value at the end
theta = [theta, theta(1)];
rho = [rho, rho(1)];

% This is panel H
y_pos = 11;
x_pos = 12;
annotation('textbox', 'units', 'centimeters', ...
    'position', [x_pos-1.5 y_pos+plotSize(2)+0.2 2 .5], ...
    'String', 'H', 'EdgeColor', 'none', ...
    'Interpreter', 'none',...
    'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');
plotSize_angular = [1.75 1.75];
pax = polaraxes;
hp = polarplot(theta, rho, 'r-', 'LineWidth', 1, ...
    'MarkerFaceColor', 'r', 'MarkerSize', 5, 'Marker', '.');
set(pax, 'Units', 'centimeters',...
    'Position', [x_pos, y_pos, plotSize_angular(1), plotSize_angular(2)], 'fontname', 'arial', 'fontsize', 7);
pax.ThetaTick = 0:45:360; % Tick marks at every 45 degrees
pax.ThetaTickLabel = string(0:45:360); % Ensure labels are shown
ind_high_spk = find(firing_rate_avg==max(firing_rate_avg));
firing_rate_prefdir = cell2mat(firing_rate_grouped(ind_high_spk)');
vel_prefdir = cell2mat(velocity_grouped(ind_high_spk)');
is_nan = isnan(vel_prefdir);
firing_rate_prefdir = firing_rate_prefdir(~is_nan);
vel_prefdir = vel_prefdir(~is_nan);

% This is panel I
y_pos = y_pos -plotSize_angular(2)-1.25;
plotSize_speed = [1.5 1];
annotation('textbox', 'units', 'centimeters', ...
    'position', [x_pos-0.75 y_pos+plotSize_speed(2)+0.8 .5 .5], ...
    'String', 'I', 'EdgeColor', 'none', ...
    'Interpreter', 'none',...
    'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');

ha_i=axes;
set(ha_i, 'nextplot', 'add', 'units', 'centimeters',...
    'position', [x_pos+.5 y_pos plotSize_speed], 'xlim', [0 max(vel_prefdir)*1.25], 'ylim', [0 max(firing_rate_prefdir)+5], ...
    'ticklength', [.025 .1]);

scatter(vel_prefdir, firing_rate_prefdir, 4, 'b', 'filled', 'MarkerFaceAlpha', 0.5); % Blue dots
xlabel('Velocity (pix/ms)');
ylabel('Firing rate (Hz)');
grid on;

[r, p] = corr(vel_prefdir(:), firing_rate_prefdir(:));
disp(['r = ', num2str(r), ', p = ', num2str(p)]);
mdl = fitlm(vel_prefdir, firing_rate_prefdir);
disp(mdl);x_vals = linspace(min(vel_prefdir), max(vel_prefdir), 100);y_vals = predict(mdl, x_vals');
plot(x_vals, y_vals, 'r-', 'LineWidth', 2); % Red regression line
text(min(vel_prefdir), max(firing_rate_prefdir), sprintf('r = %.2f, p = %.3f', r, p), ...
    'FontSize', 6, 'fontname', 'arial', 'Color', 'k', 'FontWeight', 'bold');

DataOut.DirectionTuning = {
    'bin_centers', 'firing_rate_avg', 'firing_rate_ci', 'firing_rate_grouped', 'velocity_grouped', 'lm_model';
    bin_centers, firing_rate_avg, firing_rate_ci, firing_rate_grouped, velocity_grouped, mdl
    };

% This is panel J
y_pos = y_pos -plotSize_speed(2)-2.5;
% Convert to polar coordinates
theta_turning = bin_centers; % Movement direction (angle)
rho_turning = firing_rate_turning_avg; % Mean firing rate

% Close the circular plot by repeating the first value at the end
theta_turning = [theta_turning, theta_turning(1)];
rho_turning = [rho_turning, rho_turning(1)];

annotation('textbox', 'units', 'centimeters', ...
    'position', [x_pos-1.5 y_pos+plotSize_angular(2)+0.2 2 .5], ...
    'String', 'J', 'EdgeColor', 'none', ...
    'Interpreter', 'none',...
    'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');

plotSize_angular = [1.75 1.75];
pax = polaraxes;
hp = polarplot(theta_turning, rho_turning, 'r-', 'LineWidth', 1, ...
    'MarkerFaceColor', 'r', 'MarkerSize', 5, 'Marker', '.');
set(pax, 'Units', 'centimeters',...
    'Position', [x_pos, y_pos, plotSize_angular(1), plotSize_angular(2)], 'fontname', 'arial', 'fontsize', 7);

pax.ThetaTick = 0:45:360; % Tick marks at every 45 degrees
pax.ThetaTickLabel = string(0:45:360); % Ensure labels are shown

% velocity turning
ind_high_spk = find(firing_rate_turning_avg==max(firing_rate_turning_avg));
firing_rate_prefdir = cell2mat(firing_rate_turning_grouped(ind_high_spk)');
vel_prefdir = cell2mat(velocity_turning_grouped(ind_high_spk)');
is_nan = isnan(vel_prefdir);
firing_rate_prefdir = firing_rate_prefdir(~is_nan);
vel_prefdir = vel_prefdir(~is_nan);

% This is panel K
y_pos = y_pos -plotSize_angular(2)-1.5;
plotSize_speed = [1.5 1];
annotation('textbox', 'units', 'centimeters', ...
    'position', [x_pos-.75 y_pos+plotSize_speed(2)+0.8 .5 .5], ...
    'String', 'K', 'EdgeColor', 'none', ...
    'Interpreter', 'none',...
    'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');

ha_k=axes;
set(ha_k, 'nextplot', 'add', 'units', 'centimeters',...
    'position', [x_pos+.5 y_pos plotSize_speed], 'xlim', [0 max(vel_prefdir)*1.25], 'ylim', [0 max(firing_rate_prefdir)+5], ...
    'ticklength', [.025 .1]);

scatter(vel_prefdir, firing_rate_prefdir, 4, 'b', 'filled', 'MarkerFaceAlpha', 0.5); % Blue dots
xlabel('Velocity (pix/ms)');
ylabel('Firing rate (Hz)');
grid on;

[r, p] = corr(vel_prefdir(:), firing_rate_prefdir(:));
disp(['r = ', num2str(r), ', p = ', num2str(p)]);
mdl = fitlm(vel_prefdir, firing_rate_prefdir);
disp(mdl);x_vals = linspace(min(vel_prefdir), max(vel_prefdir), 100);y_vals = predict(mdl, x_vals');
plot(x_vals, y_vals, 'r-', 'LineWidth', 2); % Red regression line
text(min(vel_prefdir), max(firing_rate_prefdir), sprintf('r = %.2f, p = %.3f', r, p), ...
    'FontSize', 6, 'fontname', 'arial', 'Color', 'k', 'FontWeight', 'bold');

DataOut.TurningTuning = {
    'bin_centers', 'firing_rate_avg', 'firing_rate_ci', 'firing_rate_grouped', 'velocity_grouped', 'lm_model';
    bin_centers, firing_rate_turning_avg, firing_rate_turning_ci, firing_rate_turning_grouped, velocity_turning_grouped, mdl
    };

% this is the title
dim = [0.1 0.6 0.01 0.05]; % [x, y, width, height]
str = unit_name;
annotation('textbox', dim, 'units', 'normalized',...
    'Position', [.05 .0 .4 .05],...
    'String', str, 'EdgeColor', 'none', ...
    'Interpreter', 'none',...
    'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');

hold off;
% Save this figure

fig_folder = fullfile(pwd, 'Figure');
if ~exist(fig_folder, 'dir')
    mkdir(fig_folder)
end

tosavename = fullfile(fig_folder, [unit_name '_' type]);
print (hf,'-dpng', tosavename)
print (hf,'-dpdf', tosavename)

tosavename = fullfile(fig_folder, [unit_name '_' type '.mat']);
save(tosavename, 'DataOut')

    function mean_out = angle_mean(angles)
        angles = angles(~isnan(angles));
        mean_out = atan2(mean(sin(angles)), mean(cos(angles)));
    end


    function ind_move = extractMovement(move_in, t_in)

        th                      = max(move_in)*0.25;
        minMoveTime             = 100;

        ind_above_th            = find(move_in>th);
        ind_above_onset         = [ind_above_th(1); ind_above_th(diff(ind_above_th)>1)+1];
        ind_above_offset        = [ind_above_th(diff(ind_above_th)>1); ind_above_th(end)];

        duration                = t_in(ind_above_offset) - t_in(ind_above_onset);
        ind_real                = find(duration>minMoveTime);
        ind_above_onset         = ind_above_onset(ind_real);
        ind_above_offset        = ind_above_offset(ind_real);
        ind_move                = zeros(size(move_in));

        if ~isempty(ind_real)
            for k =1:length(ind_real)
                ind_move(ind_above_onset(k):ind_above_offset(k)) = 1;
            end

            % fill the gaps (using rolling window convolution)
            gap_length = 10;
            ind_move_conv = conv(ind_move, ones(1, gap_length), 'same');
        end
        ind_move = ind_move_conv>0; % convert to logic values.
    end

    function [spikeCountGrid,  spikeDensityGrid, locationCountGrid, avgSpikeCountGrid] = countSpikes(time_table, x, y, spk_train, xBinEdges, yBinEdges);

        % Inputs (assumed to be provided):
        % time_table: vector of time points (in milliseconds)
        % x, y: vectors of animal locations at corresponding times
        % spk_train: vector of spike times (in milliseconds)

        % Parameters
        blockSize = 25; % 25 ms time blocks

        numBinsX_ = length(xBinEdges)-1;
        numBinsY_ = length(yBinEdges)-1;

        % Initialize grids
        spikeCountGrid          =       zeros(numBinsY_, numBinsX_); % Grid to store spike counts
        locationCountGrid       =       zeros(numBinsY_, numBinsX_); % Grid to store location counts

        totalSpikeCount         =       length(time_table);

        % Determine time block edges
        tMin_ = min(time_table);
        tMax_ = max(time_table);
        blockEdges = tMin_:blockSize:tMax_;
        if blockEdges(end) < tMax_
            blockEdges = [blockEdges, blockEdges(end) + blockSize];
        end

        % Process each time block
        for b = 1:(length(blockEdges) - 1)
            % Define current block time range
            tStart = blockEdges(b);
            tEnd = blockEdges(b + 1);

            % Find time points and spikes in this block
            timeIdx = time_table >= tStart & time_table < tEnd;
            spikeIdx = spk_train >= tStart & spk_train < tEnd;

            % Count spikes in this block
            spikeCount = sum(spikeIdx);

            % Compute average x, y location in this block
            if any(timeIdx)
                avgX = mean(x(timeIdx), 'omitnan');
                avgY = mean(y(timeIdx), 'omitnan');

                % Map to grid
                xBin_ = find(avgX >= xBinEdges, 1, 'last');
                yBin_ = find(avgY >= yBinEdges, 1, 'last');

                % Check if the point is within grid boundaries
                if ~isempty(xBin_) && ~isempty(yBin_) && ...
                        xBin_ <= numBinsX_ && yBin_ <= numBinsY_ && xBin_ >= 1 && yBin_ >= 1
                    % Accumulate spike count and location count
                    spikeCountGrid(yBin_, xBin_) = spikeCountGrid(yBin_, xBin_) + spikeCount/totalSpikeCount;
                    locationCountGrid(yBin_, xBin_) = locationCountGrid(yBin_, xBin_) + 1;
                end
            end
        end

        % Normalize spike counts by location counts to get average spike count per visit
        avgSpikeCountGrid = spikeCountGrid;
        nonZeroIdx = locationCountGrid > 0;
        avgSpikeCountGrid(nonZeroIdx) = spikeCountGrid(nonZeroIdx) ./ locationCountGrid(nonZeroIdx);

        % Compute spike density (spikes per unit area)
        % Calculate bin areas
        xWidths = diff(xBinEdges); % Width of each x-bin
        yWidths = diff(yBinEdges); % Height of each y-bin
        [X, Y] = meshgrid(xWidths, yWidths);
        binAreas = X .* Y; % Area of each bin (yBins x xBins)

        % Initialize spike density grid
        spikeDensityGrid = zeros(numBinsY_, numBinsX_);
        % Normalize spike counts by bin areas
        nonZeroAreaIdx = binAreas > 0;
        spikeDensityGrid(nonZeroAreaIdx) = spikeCountGrid(nonZeroAreaIdx) ./ binAreas(nonZeroAreaIdx);

    end

end