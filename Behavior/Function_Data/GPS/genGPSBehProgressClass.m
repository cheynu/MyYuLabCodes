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

[indx, tf] = listdlg("ListString", Tasks, "ListSize", [200, 200]);
if ~tf
    return
end

%% Use the uigetdir function to open a dialog box and allow the user to select the parent directory
Drives = char('A':'Z');
Drives = string(Drives(:));
for i = 1:length(Drives)
    if isfolder(Drives(i)+":\OneDrive")
        DataFolder  = Drives(i) + ":\OneDrive\YuLab\Work\GPS\Data\";
        break;
    end
end

ParentDir = uigetdir(DataFolder, "Select parent directory");
if ~ParentDir
    return
end

% indx = 5;
% ParentDir = "E:\YuLab\Work\GPS\Data\Gena";
Folders = get_folders(ParentDir, "FolderType", 'Protocol', "Tasks", Tasks(indx));

%%
for d = 1:length(Folders)
    % Call the recursive function to get a list of all the .mat files in the parent directory and its subdirectories
    ProtocolDir = Folders(d);
    Files = get_mat_files(ProtocolDir, "FileType", 'BehSessionClass');

    if isempty(Files)
        continue
    end
    
    %
    SessionClassAll = cell(length(Files), 1);
    for f = 1:length(Files)
        file = Files{f};
        load(file);
        SessionClassAll{f} = obj;
    end
    clear obj;
    
    % Make sure that those session classes are sorted by their date
    SessionDate = cellfun(@(x) x.Session, SessionClassAll);
    [SessionDate, SortID] = sort(SessionDate);
    SessionClassAll = SessionClassAll(SortID);

    %
    ProgressClass = GPSBehProgressClass(SessionClassAll, ProtocolDir);
    ProgressClass.get_all_kdes(1);
    ProgressClass.save();
    
    fig_progress = ProgressClass.plotProgress();
    ProgressClass.print(fig_progress);
%     ProgressClass.print("Show", ProtocolDir);

    BehavCsvName = fullfile(ProtocolDir, "GPSBehProgressClass_" + ProgressClass.Protocol + "_" + upper(ProgressClass.Subject) + ".csv");
    writetable(ProgressClass.BehavTable, BehavCsvName);
% 
%     %
%     if all(ismember(["Control", "Chemo"], ProgressClass.Label))
%         ProgressClass.print("ChemoEffect", ProtocolDir);
%     end
end
