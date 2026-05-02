folders = {
% % '20220117'                         
% '20220118'                                    
% '20220119'                                    
% '20220120'                                    
% '20220121'                                    
'20220123'                                    
'20220124' 
};

for i =1:length(folders)
    cd (fullfile('E:\DLSOpt\Data\ANMs\Claire\Sessions', folders{i}))
   MakeAVIDLCLive([], 'Redo', 0)
      MakeAVIApproach([])
end;