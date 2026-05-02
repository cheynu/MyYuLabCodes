clear;

%% Choose the target tasks to generate ProgressClass
Tasks = [
    "Autoshaping";
    "Wait1Hold";
    "Wait1HoldSRT";
    "Wait1HoldCRT";
    "Wait2HoldSRT";
    "Wait2HoldCRT";
    "ThreeFPHoldCRT";
    "ThreeFPHoldSRT";
    "ThreeFPHoldWM";
    "ThreeFPHoldSRTProbe";
    "KornblumHold500SRT";
    "KornblumHold1000SRT";
    "KornblumHold500SRTSelf";
    "KornblumHold1000SRTSelf";
    "KornblumHold1500SRTSelf";
    "KornblumHold2000SRTSelf";
    "KornblumHold10001500SRTSelf";
    "KornblumHold2000SRTEmpSelf";
    "KornblumHold2000SRTUnguideSelf";
    "KornblumHold2000SRTMixSelf"
    ];

[TaskInd, tf] = listdlg("ListString", Tasks, "ListSize", [200, 200]);
if ~tf
    return
end

%%
Drives = char('A':'Z');
Drives = string(Drives(:));
for i = 1:length(Drives)
    if isfolder(Drives(i)+":\OneDrive")
        ParentDir   = Drives(i) + ":\OneDrive\YuLab\Work\GPS\Data\";
        AnmInfoFile = fullfile(ParentDir, "ANMInfo.xlsx");
        break;
    end
end

Entry = dir(ParentDir);
ANMFolders = [];
for e = 1:length(Entry)
    if Entry(e).isdir && ~any(strcmp(Entry(e).name, {'.', '..'}))
        ANMFolders = [ANMFolders; string(fullfile(Entry(e).folder, Entry(e).name))];
    end
end
[~, ANMs] = arrayfun(@(x) fileparts(x), ANMFolders);

[ANMInd, tf] = listdlg("ListString", ANMs, "ListSize", [200, 200]);
if ~tf
    return
end

ANMFolders = ANMFolders(ANMInd);

%%
ProtocolFolders = [];
for f = 1:length(ANMFolders)
    ProtocolFolders = [ProtocolFolders; get_folders(ANMFolders(f), "FolderType", 'Protocol', "Tasks", Tasks(TaskInd))];
end

%%
SessionFolders = [];
for f = 1:length(ProtocolFolders)
    SessionFolders = [SessionFolders; get_folders(ProtocolFolders(f), "FolderType", 'Session')];
end

%%
[~, SessionsAll] = arrayfun(@(x) fileparts(x), SessionFolders);
Sessions = unique(SessionsAll);

[SessionInd, tf] = listdlg("ListString", Sessions, "ListSize", [200, 200]);
if ~tf
    return
end

%%
Folders = SessionFolders(ismember(SessionsAll, Sessions(SessionInd)));

%%
for d = 1:length(Folders)
    % Call the recursive function to get a list of all the .mat files in the parent directory and its subdirectories
    ProtocolDir = Folders(d);
    Files = get_mat_files(ProtocolDir, "FileType", 'Bpod');

    for i = 1:length(Files)
        file = Files{i};
        file_info = split(file, filesep);
        [file_path, file_name, ext] = fileparts(file);
        [protocol_folder, file_date] = fileparts(file_path);

        SessionDataFigsFolder = fullfile(protocol_folder, 'SessionDataFigs');
        if ~isfolder(SessionDataFigsFolder)
            mkdir(SessionDataFigsFolder);
        end

        % Plot Interruption durations
%         load(file);
%         f = check_interruption(SessionData);
%         f_savename = sprintf("GPS_Interruptions_%s_%s.jpg", file_info{end-3}, file_date);
%         f_savepath = fullfile(file_path, f_savename);
%         exportgraphics(f, f_savepath, 'Resolution', 600);
%         f_savepath = fullfile(SessionDataFigsFolder, f_savename);
%         exportgraphics(f, f_savepath, 'Resolution', 600);

        SessionClass = GPSBehSessionClass(file, AnmInfoFile);
        disp(SessionClass.SaveName);
        SessionClass.save();
        SessionClass.print(SessionDataFigsFolder);

        BehavCsvName = sprintf('GPSBehSessionTable_%s_%s_%s.csv',  SessionClass.Task, SessionClass.Subject, SessionClass.Session);
        writetable(SessionClass.BehavTable, fullfile(file_path, BehavCsvName));

        InterCsvName = sprintf('GPSInterruptTable_%s_%s_%s.csv',  SessionClass.Task, SessionClass.Subject, SessionClass.Session);
        writetable(SessionClass.Interruption, fullfile(file_path, InterCsvName));
    end
end

% close all;
