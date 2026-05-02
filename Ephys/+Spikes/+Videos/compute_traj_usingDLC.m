function T = compute_traj_usingDLC(TrajExtracted)

% Jianing Yu 1/15/2026, 2/26/2026, 3/4/2026 update
% extract data from TrajExtracted
% Here is how TrajExtracted generated:
% dlc_folder = app.folderPath;
% trial_name = app.currentTrial;
% dlc_file_name = sprintf('%sDLC*.csv', trial_name);
% dlc_file_location = dir(fullfile(dlc_folder, dlc_file_name));
% if isempty(dlc_file_location)
%     warndlg(sprintf('There is no DLC file associated with %s in %s', dlc_file_name, dlc_folder));
% end
% dlc_file_path = fullfile(dlc_file_location.folder, dlc_file_location.name);
% app.dlcResults = read_dlc_table(dlc_file_path);
% t_start = app.EditFieldStart.Value;
% t_end   = app.EditFieldEnd.Value;
% dur_min = 500; % there has to be one second of data
% if t_start~=0 && t_end~=0 && t_end-t_start>dur_min
%     warndlg('Too short!');
%     return;
% end
% 
% % --- this is the video info (meta data)---
% videoMetaFileName = [trial_name '.mat'];
% app.VideoMeta = load(fullfile(app.folderPath, videoMetaFileName));
% % Find out the index
% IndexTimeSelected = find(app.VideoMeta.VideoInfo.EphysTimeStamps>=t_start & app.VideoMeta.VideoInfo.EphysTimeStamps<=t_end);
% TrajExtracted = app.dlcResults;
% TrajExtracted.IndexSelected = IndexTimeSelected;
% TrajExtracted.TimeSelected = app.VideoMeta.VideoInfo.EphysTimeStamps(IndexTimeSelected); 
% % If no folder path is saved, ask user to select one
% if isempty(app.TrajSavedPath)
%     selectedFolder = fullfile(pwd, 'TrajExtracted');
%     if ~exist(selectedFolder, 'dir')
%         mkdir(selectedFolder);
%         disp(['Created folder: ', selectedFolder]);
%     end
%     app.TrajSavedPath = selectedFolder; % Save the new folder path
% end
% savedFolderPath = app.TrajSavedPath; 
% % determine if this segment is before or after press
% if TrajExtracted.TimeSelected(1)<app.currentTrialBehavior.t_press
%     tag = 'toLever';
% else
%     tag = 'fromLever';
% end
% 
% % Display the saved folder path
% new_traj_name = sprintf('TrajExtracted_%s_%s.mat', trial_name, tag);
% save(fullfile(savedFolderPath, new_traj_name), 'TrajExtracted');
% disp(['Data will be saved to: ', fullfile(savedFolderPath, new_traj_name)]);

if nargin<3
    name_tag = [];
end

% Extract relevant data: left ear
index           =   TrajExtracted.IndexSelected;
timeSegments    =   TrajExtracted.TimeSelected; % Time segments

body_parts = {'EarLTop', 'EarRTop'};

x = struct('EarLTop', [], 'EarRTop', []);  % y
y = struct('EarLTop', [], 'EarRTop', []);  % x
lh = struct('EarLTop', [], 'EarRTop', []); % likelihood

min_lh = 1;
for i =1:length(body_parts)
    body_part = body_parts{i};
    x.(body_part) = TrajExtracted.(body_part).x(index);
    y.(body_part) = TrajExtracted.(body_part).y(index);
    lh.(body_part) = TrajExtracted.(body_part).likelihood(index);
end

tracking_lh = min([lh.EarLTop lh.EarRTop], [], 2);
% Determine the correct perpendicular direction: We can now check which of
% the perpendicular vectors is pointing away from the tail. To do this, we
% compute the dot product between each perpendicular vector and the vector
% from the tail to the midpoint of the ears.
% The perpendicular vector whose dot product with the tail-to-midpoint
% vector is positive will be the one pointing away from the tail.

% figure(9); clf(9); hold on
% 
% for i =1:length(body_parts)
%     body_part = body_parts{i};
%     % subplot(length(body_parts), 1, i)
%     scatter(timeSegments, y.(body_part), 50, lh.(body_part), 'filled');
%     title(sprintf('Y of %s', body_part))
% end
% hold off

% [head_direction, x_midpoints, y_midpoints, d_perp_x, d_perp_y] = ...
%     Spikes.Videos.compute_head_direction_from_ears(x, y, tracking_lh,...
%     'Thresh', 0.8, 'DoPlot', true, 'PlotProb', 0.2);

% Never interpolate gaps that touch the start/end of a kept segment (those are "edge gaps").
% Only fill short internal gaps that are bracketed by good tracking on both sides.
% Do position + direction vector together, and output a single table you can bin, differentiate, and mask.

T = Spikes.Videos.head_pose_table_from_ears(timeSegments, x, y, tracking_lh, ...
    'Thresh', 0.8, 'MaxGapSec', 0.2);

file_name = TrajExtracted.Name;

T.Source = repmat({file_name}, height(T), 1);

% --- plot the data ---
fig_num = 98;
figH = figure(fig_num);
figH.Position(2) = 100;
figH.Position(3) = 500;
figH.Position(4) = 600;

Spikes.Videos.plot_head_kinematics_table(T, figH)

end