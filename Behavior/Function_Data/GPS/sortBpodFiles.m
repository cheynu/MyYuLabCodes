Drives = string(char('A':'Z')');
for i = 1:26
    folder_i = Drives(i)+":\OneDrive\YuLab\Work\GPS\Data";
    if isfolder(folder_i)
        DataFolder = folder_i;
    end
end

%% move bpod file to session folder
bpod_files = get_mat_files(DataFolder, "FileType", "Bpod");
for i = 1:length(bpod_files)
    f_path = bpod_files(i);
    f_part = split(f_path, filesep);

    f_dir  = fileparts(f_path);
    f_up   = f_part(end-1);
    f_name = f_part(end);

    f_info = split(f_name, "_");
    f_date = f_info(end-1);

    if ~contains(f_up, f_date)
        f_dir_new = fullfile(f_dir, f_date);
        if ~isfolder(f_dir_new)
            mkdir(f_dir_new);
        end
        movefile(f_path, f_dir_new);
    end
end

%% check if there is more than one bpod file in a single session folder
session_folders = get_folders(DataFolder, "FolderType", "Session");
for i = 1:length(session_folders)
    s = session_folders(i);
    bpod_f = get_mat_files(s, "FileType", "Bpod");
    if length(bpod_f)>1
        [task_folder, session_date] = fileparts(s);
        serial_lb = string(char('a':'z')');
        for j = 1:length(bpod_f)
            f_dir_new = fullfile(task_folder, session_date+serial_lb(j));
            if ~isfolder(f_dir_new)
                mkdir(f_dir_new);
            end
            movefile(bpod_f(j), f_dir_new);
        end
        rmdir(s);
        fprintf("\nMore than one bpod file in this session folder:\n%s\n", s);
    end
end
