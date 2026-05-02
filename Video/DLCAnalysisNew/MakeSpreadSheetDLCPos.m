function MakeSpreadSheetDLCPos(PosData, newname)

% make a spread sheet to mark Pos detection time, pos location, and cluster
% one needs to edit this sheet to remove erroneous detections

% Jianing Yu 9/10/2021

if nargin<2
    newname = [];
end;


StimIndex      =     1:size(PosData.StimTime, 1);  % index of stim
StimClus        =     zeros(1, size(StimIndex, 1)); % 0: unclustered; 1: cluster 1; 2: cluster 2

for i=1:length(PosData.StimClus)
    StimClus(PosData.StimClus{i}) = i;
end;

StimTime        =       num2cell(PosData.StimTime(:, 1));


StimPos_x       =       num2cell(PosData.StimPos(:, 1));
StimPos_y       =       num2cell(PosData.StimPos(:, 2));

StimIndex       =       num2cell(StimIndex(StimClus~=0)');
StimTime        =       num2cell(StimTime(StimClus~=0));
StimPos_x       =       num2cell(StimPos_x(StimClus~=0));
StimPos_y       =       num2cell(StimPos_y(StimClus~=0));
StimClus          =       num2cell(StimClus(StimClus~=0)');
GoodTracking =       repmat({1}, length(StimClus), 1);

TableEvents     =       table(StimIndex,GoodTracking, StimClus, StimTime, StimPos_x, StimPos_y);
sheetname =   sprintf('DLCPos.xlsx');
% ver = 0;
% 
% while length(dir(sheetname)) > 0
%     ver = ver+1;
%     sheetname =   sprintf('DLCPos_v%d.xlsx', ver);
% end;

writetable(TableEvents, sheetname);