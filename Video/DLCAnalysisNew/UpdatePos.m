function PosData = UpdatePos(PosData)

% Jianing Yu 9/10/2021
% update DLC posdata after excel file has been edited.

% Look for excel table
[tablefile,path] = uigetfile('DLCPos*.xlsx');

if isequal(tablefile,0)
    disp('User selected Cancel');
else
    disp(['User selected ', fullfile(path,tablefile)]);
end

[~,~,raw] = xlsread(tablefile) ;
StimIndexTable = cell2mat(raw(2:end, 1));
GoodTracking = cell2mat(raw(2:end, 2));
IndStimAll = 1:size(PosData.StimTime, 1);
N_bad = length(find(GoodTracking==0));
N_all = length(GoodTracking);
sprintf('Bad labeling vs all labeling: %2.0d / %2.0d, %2.2f%%', N_bad, N_all, N_bad/N_all*100)
ToCorrect = StimIndexTable(GoodTracking==0);

for i =1:length(PosData.StimClus)
    PosData.StimClus{i}(ToCorrect) = 0;
end;

% save PosData
 posfile = dir('PosData*.mat');
 
 filename = posfile.name;
 filename2 = [filename(1:end-4) '_Updated.mat']
  
 save(filename2, 'PosData')