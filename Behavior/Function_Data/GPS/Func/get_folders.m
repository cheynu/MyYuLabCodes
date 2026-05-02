function folder_names = get_folders(directory, opts)
% Recursive function to get a list of all the .mat files in a directory and its subdirectories

arguments
    directory       (1, 1) string = '';
    opts.FolderType (1, 1) string = 'PROTOCOL';
    opts.Tasks      (:, 1) string = ["ALL"];
end

opts.FolderType = upper(opts.FolderType);
opts.Tasks      = upper(opts.Tasks);

% Get a list of all the files and folders in the directory
if isempty(directory)
    directory = pwd;
end

if any(strcmp(opts.Tasks, "ALL"))
    opts.Tasks = [
        "Autoshaping";
        "Wait1Hold";
        "Wait1HoldCRT";
        "Wait2HoldCRT";
        "ThreeFPHoldCRT";
        "ThreeFPHoldSRT";
        "ThreeFPHoldWM";
        "KornblumSRT";
        "Kornblum1000SRT";
        "Kornblum1000SRTSelf";
        "Kornblum1500SRTSelf";
        "Kornblum2000SRTSelf";
        "Kornblum2000SRTEmpSelf";
        "Kornblum2000SRTUnguideSelf";
        "Kornblum2000SRTMixSelf"
        "KornblumHold1000SRT";
        "KornblumHold1000SRTSelf";
        "KornblumHold1500SRTSelf";
        "KornblumHold2000SRTSelf";
        "KornblumHold2000SRTEmpSelf";
        "KornblumHold2000SRTUnguideSelf";
        "KornblumHold2000SRTMixSelf"
        ];
end

dir_parts = split(directory, filesep);
if length(dir_parts) >= 2
    parent_dir = '';
    for i = 1:length(dir_parts)-1
        parent_dir = fullfile(parent_dir, dir_parts{i});
    end
    folder = dir_parts{end};
    parts = split(folder, '_');
    switch opts.FolderType
        case "PROTOCOL"
            if length(parts)==3 && all(isstrprop(parts{2}, 'digit')) && any(strcmpi(parts{3}, opts.Tasks)) % GPS_##_Protocol
                % If the foldername has at least 5 parts and the date part has 8 digits, append the full file path to the cell array
                folder_names = directory;
                return
            end
        case "SESSION"
            if length(parts)==1 && all(isstrprop(parts{1}, 'digit')) && length(parts{1})==8 % yyyymmss
                % If the foldername has at least 5 parts and the date part has 8 digits, append the full file path to the cell array
                folder_names = directory;
                return
            end
    end
end

contents = dir(directory);

% Initialize an empty cell array to store the file names
folder_names = {};

% Loop through each entry in the directory
for i = 1:length(contents)
    entry = contents(i);

    if entry.isdir && ~strcmp(entry.name, '.') && ~strcmp(entry.name, '..')
        % If the entry is a directory (and not '.' or '..'), call this function recursively on the subdirectory
        parts = split(entry.name, '_');
        switch opts.FolderType
            case "PROTOCOL"
                if length(parts)>=3 && all(isstrprop(parts{2}, 'digit')) && any(strcmpi(parts{3}, opts.Tasks)) % GPS_##_Protocol
                    % If the foldername has at least 5 parts and the date part has 8 digits, append the full file path to the cell array
                    folder_names = [folder_names; fullfile(directory, entry.name)];
                else
                    subdirectory = fullfile(directory, entry.name);
                    subdirectory_folders = get_folders(subdirectory, "FolderType", opts.FolderType, "Tasks", opts.Tasks);
                    folder_names = [folder_names; subdirectory_folders];
                end
            case "SESSION"
                if length(parts)==1 && all(isstrprop(parts{1}, 'digit')) && length(parts{1})==8 % yyyymmss
                    % If the foldername has at least 5 parts and the date part has 8 digits, append the full file path to the cell array
                    folder_names = [folder_names; fullfile(directory, entry.name)];
                elseif length(parts)==1 && length(parts{1})==9 && all(isstrprop(parts{1}(1:8), 'digit')) % yyyymmssi
                    folder_names = [folder_names; fullfile(directory, entry.name)];
                else
                    subdirectory = fullfile(directory, entry.name);
                    subdirectory_folders = get_folders(subdirectory, "FolderType", opts.FolderType, "Tasks", opts.Tasks);
                    folder_names = [folder_names; subdirectory_folders];
                end
        end
    end
end

end
