% Let's explore the relationshp between movement trajectory and spikes
% e.g, E:\Dropbox\Work\VideoEphys\ANMs\Musk\20210824\EphysVideoSnapShots

traj_path       = fullfile(pwd, 'TrajExtracted');  % tracked trajectories from rVideoViewer.mlapp
video_path      = fullfile(pwd, 'VideoClips', 'Press'); % including video, video meta files, and tracking results, probably won't use
prefix          = 'Top_Press_'; % file prefix e.g, TrajExtracted_Top_Press_######.mat
r_path          = pwd;
r_name          = 'RTarray_Musk_20210824.mat'; % r file
% First turn spike to sdf
load(fullfile(r_path, r_name), 'r');

spike_notes = r.Units.SpikeNotes;
n_units = size(spike_notes, 1);
sdf_units = struct('ch', [], 'unit', [], 'spk_time_ms', [], 't_sdf_ms', [], 'sdf', []);

% Parameters for tight_subplot
rows = n_units; cols = 1; % Number of subplots
gap = 0.05; % Gap between plots
marg_h = [0.1 0.1]; % Top and bottom margins
marg_w = [0.1 0.1]; % Left and right margins

% sdfout =sdf_spktimes(spk_times, tmax, kernel_width)
figure('Visible','on');
tl = tiledlayout(n_units, 1, 'Padding', 'compact', 'TileSpacing', 'compact'); % Create a 2x2 layout

ha = zeros(1, n_units);
all_colors = parula(n_units);
tmax = 100;
kernel_width = 50; % 50 ms kernel
bin_size = 10; 

for i =1:n_units
    ispk_times              = r.Units.SpikeTimes(i).timings;
    i_df_units              = sdf_spktimes(ispk_times, max(ispk_times)+1000, kernel_width, bin_size);

    sdf_units(i).ch             =  spike_notes(i, 1);
    sdf_units(i).unit           =  spike_notes(i, 2);
    sdf_units(i).spk_time_ms    =  ispk_times;
    sdf_units(i).t_sdf_ms       =  i_df_units(:, 1);
    sdf_units(i).sdf            =  i_df_units(:, 2);

    ha(i) = nexttile;
    plot(sdf_units(i).t_sdf_ms/1000, sdf_units(i).sdf, 'Color', all_colors(i, :), 'linewidth', 1);
    if i<n_units
        set(ha(i), 'XTick', []); % Remove x-ticks for each subplot
    end
    tmax = max(tmax, sdf_units(i).t_sdf_ms(end)/1000);
    fprintf('Ch%2.0dUnit%2.0d', spike_notes(i, 1), spike_notes(i, 2))
    legend(sprintf('Ch%2.0dUnit%2.0d', spike_notes(i, 1), spike_notes(i, 2)), 'Box', 'off')
end
arrayfun(@(h) set(h, 'XLim', [0 tmax]), ha);
xlabel('Time (s)')

%% Extract trajectory
% plot this spike
ind_plot = [14 1];

% Define the folder where the files are located
folderPath = traj_path; % Replace with your folder path

% Get a list of all .mat files with the specified prefix
filePattern = fullfile(folderPath, 'TrajExtracted_Top_*.mat');
fileList = dir(filePattern);
traj_out = []; % time, x, y, likelihood, dx, dy, ddx, ddy
clean = 1;
body_part = 'EarLTop';
% Loop through each file and load it
TrajTableAll = [];
for k = 1:length(fileList)    
    % Construct the full file path
    fullFilePath = fullfile(folderPath, fileList(k).name);
    % Load the .mat file
    loadedData = load(fullFilePath);
    name_tag = [fullFilePath '_' body_part];
    k_traj_table = Spikes.Videos.extract_trajectory(loadedData.TrajExtracted, body_part, clean, name_tag);
    disp('traj table from this file')
    disp(size(k_traj_table))
    TrajTableAll = [TrajTableAll; k_traj_table];
    disp('current table compiled')
    disp(size(TrajTableAll))
end

%%  Now we have table

Spikes.Videos.ViewSpikeOnTraj(TrajTableAll, sdf_units(2))

























