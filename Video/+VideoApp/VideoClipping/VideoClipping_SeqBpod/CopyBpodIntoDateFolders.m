pathBPOD = 'C:\Users\CY\OneDrive\lab\BehaviorTraining\Data\00_rawData\Rat\DREADD\3_Nacho2Woody\Toro\DSRT_06_3FPs\Session Data';
pathDateFolders = 'C:\Users\CY\OneDrive\lab\BehaviorTraining\Data\07_Rat_aDMS_Lesion\ANMs\Toro\01_Bilateral_aDMS_Lesion';

if isempty(pathBPOD)
    pathBPOD = uigetdir(pwd,'Select the folder containing BPOD files');
end
if isempty(pathDateFolders)
    pathDateFolders = uigetdir(pwd,'Select the parent directory of target folders');
end
%% Target folders
pathTar = arrayfun(@(x)x.name,dir(fullfile(pathDateFolders,'*.')),'UniformOutput',false);
idxTar = cellfun(@(x) ~ismember(x,{'.','..'}) & length(x)==8,pathTar);
pathTar = pathTar(idxTar);
TarFolders = fullfile(pathDateFolders,pathTar);
%% Matched files
bpodfiles = arrayfun(@(x)x.name,dir(fullfile(pathBPOD,'*DSRT*.mat')),'UniformOutput',false);

TarFiles = cell(size(pathTar));
for i=1:length(pathTar)
    tarpath = pathTar{i};
    idxFile = contains(bpodfiles,tarpath);
    
    if sum(idxFile)==1
        tarfile = bpodfiles{idxFile};
        TarFiles{i} = fullfile(pathBPOD,tarfile);
    else
        TarFiles{i} = '';
    end
end
%% Copy
for i=1:length(TarFolders)
    folder = TarFolders{i};
    file = TarFiles{i};
    if ~isempty(file)
        copyfile(file,folder);
    else
        fprintf('The file matched with %s was not found\n',pathTar{i});
    end
end