function newDLC = DLCfilter(dlc,pressOut,varargin)
%% input examples
% load('DLCTrackingOut.mat','DLCTrackingOut');
% dlc = DLCTrackingOut;
% pressOut = PressOut(i);
p = inputParser;
addRequired(p,'dlc');
addRequired(p,'pressOut');
addParameter(p,'pressPaw',{});
addParameter(p,'holdPaw',{});
addParameter(p,'releasePaw',{});
addParameter(p,'outcome',{});
parse(p,dlc,pressOut,varargin{:});

pressPaw = p.Results.pressPaw;
holdPaw = p.Results.holdPaw;
releasePaw = p.Results.releasePaw;
outcome = p.Results.outcome;
%% extract PressIdx to remain from pressOut
idxRem = pressOut.PressIndex;
idxRem = findIdx(idxRem,pressOut,'PressPaw',pressPaw,...
    {{'l',1},1;{'r',2},2;{'b',3},3});
idxRem = findIdx(idxRem,pressOut,'HoldPaw',holdPaw,...
    {{'l',1},1;{'r',2},2;{'b',3},3});
idxRem = findIdx(idxRem,pressOut,'ReleasePaw',releasePaw,...
    {{'l',1},1;{'r',2},2;{'b',3},3});
idxRem = findIdx(idxRem,pressOut,'Outcome',outcome,...
    {{'correct','cor','c',1},1;...
    {'premature','pre','p',-1},-1;...
    {'late','lat','l',0},0});
%% filter DLC data
% get idx in DLC
newDLC = dlc;
try
    idxNew = find(ismember(dlc.PoseTracking.EventIndex(1,:),idxRem));
    newDLC.PoseTracking.PosData = dlc.PoseTracking.PosData(idxNew);
    newDLC.PoseTracking.EventIndex = dlc.PoseTracking.EventIndex(:,idxNew);
    newDLC.PoseTracking.Performance = dlc.PoseTracking.Performance(idxNew);
    newDLC.PoseTracking.Images = dlc.PoseTracking.Images(idxNew);
    newDLC.PoseTracking.ImagesIndex = dlc.PoseTracking.ImagesIndex(idxNew);
catch
    warning('Failed to filter DLCdata, return the raw input');
    newDLC = dlc;
end

end
%% Functions
function idxOut = findIdx(idxIn,pressOut,tarField,pat,matchrule)
% idxIn: 1:100
% tarField: 'PressPaw'
% pat: {'l','r'} / 'l' / 1 / {'l',2}
% matchrule: {'l',1;'r',2;'b',3}
if ~isa(pat,'cell')
    pat = num2cell(pat);
end
idxPat = [];
for i=1:length(pat)
    switch lower(pat{i})
        case matchrule{1,1} % {'l',1}
            idx = pressOut.PressIndex(pressOut.(tarField) == matchrule{1,2});
        case matchrule{2,1} % {'r',2}
            idx = pressOut.PressIndex(pressOut.(tarField) == matchrule{2,2});
        case matchrule{3,1} % {'b',3}
            idx = pressOut.PressIndex(pressOut.(tarField) == matchrule{3,2});
        otherwise
            idx = [];
    end
    idxPat = union(idxPat,idx);
end
if isempty(idxPat)
    idxPat = idxIn;
end
idxOut = intersect(idxIn,idxPat);
end