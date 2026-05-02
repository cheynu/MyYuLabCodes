function file_names = get_mat_files(directory, opts)
% Recursive function to get a list of all the .mat files in a directory and its subdirectories

arguments
    directory (1, 1) string
    opts.FileType (1, 1) string = 'BPOD'
end

opts.FileType = upper(opts.FileType);
% Get a list of all the files and folders in the directory
if isempty(directory)
    contents = dir();
else
    contents = dir(directory);
end

% Initialize an empty cell array to store the file names
file_names = {};

% Loop through each entry in the directory
for i = 1:length(contents)
    entry = contents(i);

    if entry.isdir && ~strcmp(entry.name, '.') && ~strcmp(entry.name, '..')
        % If the entry is a directory (and not '.' or '..'), call this function recursively on the subdirectory
        subdirectory = fullfile(directory, entry.name);
        subdirectory_files = get_mat_files(subdirectory, "FileType", opts.FileType);
        file_names = [file_names; subdirectory_files];
    elseif ~entry.isdir && endsWith(entry.name, '.mat')
        % If the entry is a .mat file, check if the filename contains the date in the correct format
        parts = split(entry.name, '_');
        switch opts.FileType
            case "BPOD"
                if length(parts)>=5 && length(parts{5})==8 % ANM_PROJECT_step_Task_yyyymmdd_hhmmss.mat
                    % If the filename has at least 5 parts and the date part has 8 digits, append the full file path to the cell array
                    file_names = [file_names; fullfile(directory, entry.name)];
                end
            case "SESSIONCLASS"
                if length(parts)>=4 && strcmp(parts{1}, 'GPSSessionClass')
                    file_names = [file_names; fullfile(directory, entry.name)];
                end
            case "BEHSESSIONCLASS"
                if length(parts)>=4 && strcmp(parts{1}, 'GPSBehSessionClass')
                    file_names = [file_names; fullfile(directory, entry.name)];
                end
            case "PROGRESSCLASS"
                if length(parts)>=3 && strcmp(parts{1}, 'GPSProgressClass')
                    file_names = [file_names; fullfile(directory, entry.name)];
                end
            case "BEHPROGRESSCLASS"
                if length(parts)>=3 && strcmp(parts{1}, 'GPSBehProgressClass')
                    file_names = [file_names; fullfile(directory, entry.name)];
                end
            case "TRAJSESSIONCLASS"
                if length(parts)>=3 && strcmp(parts{1}, 'GPSTrajSessionClass')
                    file_names = [file_names; fullfile(directory, entry.name)];
                end
            case "TRAJPROGRESSCLASS"
                if length(parts)>=3 && strcmp(parts{1}, 'GPSTrajProgressClass')
                    file_names = [file_names; fullfile(directory, entry.name)];
                end
            case "TRAJFIELDSESSIONCLASS"
                if length(parts)>=3 && strcmp(parts{1}, 'GPSTrajFieldSessionClass')
                    file_names = [file_names; fullfile(directory, entry.name)];
                end
            case "TRAJFIELDPROGRESSCLASS"
                if length(parts)>=3 && strcmp(parts{1}, 'GPSTrajFieldProgressClass')
                    file_names = [file_names; fullfile(directory, entry.name)];
                end
            case "TRAJINITSESSIONCLASS"
                if length(parts)>=3 && strcmp(parts{1}, 'GPSTrajInitSessionClass')
                    file_names = [file_names; fullfile(directory, entry.name)];
                end
            case "TRAJINITPROGRESSCLASS"
                if length(parts)>=3 && strcmp(parts{1}, 'GPSTrajInitProgressClass')
                    file_names = [file_names; fullfile(directory, entry.name)];
                end
        end
    end
end

end
