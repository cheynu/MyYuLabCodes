% Program to move files starting with 'Side' and 'Top' to respective folders

% Get the current directory
currentDir = pwd;

% Define the destination folders
sideFolder = fullfile(currentDir, 'Side');
topFolder = fullfile(currentDir, 'Top');

% Create the folders if they don't exist
if ~exist(sideFolder, 'dir')
    mkdir(sideFolder);
    fprintf('Created folder: %s\n', sideFolder);
end
if ~exist(topFolder, 'dir')
    mkdir(topFolder);
    fprintf('Created folder: %s\n', topFolder);
end

% Get a list of all files in the current directory
fileList = dir(currentDir);
fileList = fileList(~[fileList.isdir]); % Exclude directories

% Loop through the files and move them based on their names
for i = 1:length(fileList)
    fileName = fileList(i).name;
    sourcePath = fullfile(currentDir, fileName);
    
    % Check if the file starts with 'Side'
    if startsWith(fileName, 'Side', 'IgnoreCase', true)
        destPath = fullfile(sideFolder, fileName);
        movefile(sourcePath, destPath);
        fprintf('Moved %s to %s\n', fileName, sideFolder);
    
    % Check if the file starts with 'Top'
    elseif startsWith(fileName, 'Top', 'IgnoreCase', true)
        destPath = fullfile(topFolder, fileName);
        movefile(sourcePath, destPath);
        fprintf('Moved %s to %s\n', fileName, topFolder);
    end
end

fprintf('File organization complete.\n');