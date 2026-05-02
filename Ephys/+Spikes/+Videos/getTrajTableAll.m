function getTrajTableAll(r_name, traj_path)
% JY 2025.2
% Extract trajectory
% plot this spike

if nargin==0
   r_name = dir('RTarray*.mat');
   r_name = r_name.name;
   traj_path = fullfile(pwd, 'TrajExtracted');
end

% Define the folder where the files are located
folderPath = traj_path; % Replace with your folder path
% Get a list of all .mat files with the specified prefix
filePattern = fullfile(folderPath, 'TrajExtracted_Top_*.mat');
fileList = dir(filePattern);
clean = 1;
 % Loop through each file and load it
TrajTableAll = [];
for k = 1:length(fileList)    
    sprintf('Finishing trajectory #%2.0d', k)
    % Construct the full file path
    fullFilePath = fullfile(folderPath, fileList(k).name);
    numberStr = regexp(fileList(k).name, '\d+', 'match');
    ktPress = str2double(numberStr{1});

    % Load the .mat file
    loadedData = load(fullFilePath);
    name_tag = [fullFilePath '_' 'Movement'];

    % k_traj_table = Spikes.Videos.extract_trajectory(loadedData.TrajExtracted, body_part, clean, name_tag);
    % compute head direction
    k_traj_table = Spikes.Videos.extract_traj_and_head_direction(loadedData.TrajExtracted, clean, name_tag);

    before_after = k_traj_table.Time;
    ind_before_after = before_after>ktPress;
    k_traj_table.BeforePress = ind_before_after;

    disp('traj table from this file')
    disp(size(k_traj_table))
    TrajTableAll = [TrajTableAll; k_traj_table];
    disp('current table compiled')
    disp(size(TrajTableAll))
end
% save TrajTableAll
table_name = extractBetween(r_name, 'RTarray_', '.mat');
table_name= ['Trajectory_' table_name{1} '.csv'];
writetable(TrajTableAll, table_name)