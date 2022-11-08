clear;clc;
sbjPath = uigetdir(fullfile(pwd,'..'),'Please select the subject folder to be processed');
tarPathDir = dir(sbjPath);
tarPathDir = tarPathDir(arrayfun(@(x) x.isdir & ~strcmp(x.name,'.') & ~strcmp(x.name,'..'),tarPathDir));
tarPathName = {tarPathDir.name}';

for i=1:length(tarPathName)
    tarPath = fullfile(sbjPath,tarPathName{i});
    delete(fullfile(tarPath,'Cam*.avi'));
    delete(fullfile(tarPath,'Cam*.txt'));
end