% Let's explore the relationshp between movement trajectory and spikes
% e.g, E:\Dropbox\Work\VideoEphys\ANMs\Musk\20210824\EphysVideoSnapShots

traj_path       = fullfile(pwd, 'TrajExtracted');  % tracked trajectories from rVideoViewer.mlapp
video_path      = fullfile(pwd, 'VideoClips', 'Press'); % including video, video meta files, and tracking results, probably won't use
prefix          = 'Top_Press_'; % file prefix e.g, TrajExtracted_Top_Press_######.mat
r_path          = pwd;
r_name          = dir('RTarray_*.mat');
r_name          = r_name.name; % r file
% First turn spike to sdf
load(fullfile(r_path, r_name), 'r');
spike_notes = r.Units.SpikeNotes;
n_units = size(spike_notes, 1);
sdf_units = struct('ch', [], 'unit', [], 'spk_time_ms', [], 't_sdf_ms', [], 'sdf', [], 'warp_out', [], 'fp', []);

% Parameters for tight_subplot
rows = n_units; cols = 1; % Number of subplots
gap = 0.05; % Gap between plots
marg_h = [0.1 0.1]; % Top and bottom margins
marg_w = [0.1 0.1]; % Left and right margins
ha = zeros(1, n_units);
tmax = 100;
kernel_width = 10; % 5 bins kernel
bin_size = 10; 
FPs=  r.BehaviorClass.MixedFP;
for i =1:n_units
    ispk_times                  =   r.Units.SpikeTimes(i).timings;
    i_df_units                  =   sdf_spktimes(ispk_times, max(ispk_times)+1000, kernel_width, bin_size);
    sdf_units(i).ch             =  spike_notes(i, 1);
    sdf_units(i).unit           =  spike_notes(i, 2);
    sdf_units(i).spk_time_ms    =  ispk_times;
    sdf_units(i).t_sdf_ms       =  i_df_units(:, 1);
    sdf_units(i).sdf            =  i_df_units(:, 2);
    tmax                        =  max(tmax, sdf_units(i).t_sdf_ms(end)/1000);
    fprintf('Ch%2.0dUnit%2.0d', spike_notes(i, 1), spike_notes(i, 2))
    legend(sprintf('Ch%2.0dUnit%2.0d', spike_notes(i, 1), spike_notes(i, 2)), 'Box', 'off')
    sdf_units(i).warp_out = Spikes.SRT.PlotPSTHLiteWarped(r, [sdf_units(i).ch sdf_units(i).unit]); 
    sdf_units(i).fp = FPs;
end
%% Extract trajectory
% plot this spike
% Define the folder where the files are located
folderPath = traj_path; % Replace with your folder path
% Get a list of all .mat files with the specified prefix
filePattern = fullfile(folderPath, 'TrajExtracted_Top_*.mat');
fileList = dir(filePattern);

Spikes.Videos.getTrajTableAll(r_name, traj_path);

%%  Now we have table
table_name = extractBetween(r_name, 'RTarray_', '.mat');
table_name= ['Trajectory_' table_name{1} '.csv'];
TrajTableAll = readtable(table_name);
units_of_interests = spike_notes; % go through each sorted unit. 
session_name = extractBetween(r_name, 'RTarray_', '.mat');
session_name = session_name{1};
spatial_span = [50 750; 150 650]; % first row, x span; second row, y span
for i =1:size(units_of_interests, 1)
    j = units_of_interests(i, [1 2]);
    indx = (arrayfun(@(x)x.ch, sdf_units)==j(1) & arrayfun(@(x)x.unit, sdf_units)==j(2));
    name_tag = [session_name '_Ch' num2str(sdf_units(indx).ch) '_Unit' num2str(sdf_units(indx).unit)];
    Spikes.Videos.ViewSpikeOnTraj(TrajTableAll, sdf_units(indx), name_tag, spatial_span)
end