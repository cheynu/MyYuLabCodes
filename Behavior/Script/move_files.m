SessionTypes ={
    '00_AutoShaping'
    '01_LeverPress'
    '02_LeverRelease'
    '03_Wait1'
    '04_Wait2'
    '05_ThreeFPs'
    '06_Kornblum1000'
    '07_SingleFP'
    '08_SingleFP1500'
    '09_Kornblum1500'
    };

thisFolder = pwd;
thisFolderSplitted = strsplit(thisFolder, '\');
NameIndex =  find(strcmp(thisFolderSplitted, 'ANMs'))+1;
ratName = thisFolderSplitted{NameIndex};

% Read folders
rootFolder = pwd;
files = dir(rootFolder);
dirFlags = [files.isdir];
subFolders                 =        files(dirFlags);
subFolderNames      =        {subFolders(3:end).name};
dataFolderNames    = {};
for k =1:length(subFolderNames)
    if ~isempty(str2num(subFolderNames{k}))
        dataFolderNames = [dataFolderNames  subFolderNames{k}];
        fprintf('Subfolder #%d = %s \n', k,  subFolderNames{k})
    end;
end
dataFolderNames'

for k =1:length(SessionTypes)

    kSessionTypes = SessionTypes{k};
    keyword           =  extractAfter(kSessionTypes, '_');
    mkdir(kSessionTypes)

    %  Go through all files
    for i =1:length(dataFolderNames)
        txtFile = dir(fullfile(thisFolder, dataFolderNames{i}, '*.txt'));
        if ~isempty(txtFile)
            if length(txtFile) == 1
                % Read protocol name
                metadata = Behavior.MED.med_to_protocol(fullfile(thisFolder, dataFolderNames{i}, txtFile.name));
                protocol = metadata.ProtocolName;
                disp([dataFolderNames{i} ' | ' protocol ' | Experiment: ' metadata.Experiment])
                protocol = erase(protocol, 'Style');
                protocol = erase(protocol, 'Bpod');
                if  contains(protocol, keyword)
                    % move this file
                    cd(rootFolder)
                    sourcefolder_to_move = fullfile(rootFolder, dataFolderNames{i});
                    targetfolder_to_move = fullfile(rootFolder, kSessionTypes);
                    movefile(sourcefolder_to_move, targetfolder_to_move);
                end;
            else
                disp(['Multiple files found in folder: ', dataFolderNames{i}])
            end;
        end;
    end;
end;

