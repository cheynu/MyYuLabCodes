function mergeDLC(tarPath,varargin)
p = inputParser;
addRequired(p,'tarPath',@isfolder);
addOptional(p,'savePath','',@isfolder);
parse(p,tarPath,varargin{:});
savePath = p.Results.savePath;
if isempty(savePath)
    savePath = tarPath;
end

% tarPath = 'D:\VideoProcessing\1_Data\Matias\20220404\VideoData\Clips\VideoData';
filename = dir(fullfile(tarPath,'*DLC.mat'));
%% Merge
DLCTrackingOut = struct;
for i=1:length(filename)
    file = filename(i).name;
    load(fullfile(tarPath,file));
    if i==1
        DLCTrackingOut = DLCSave;
    else
        DLCTrackingOut.PoseTracking.PosData(end+1)        = DLCSave.PoseTracking.PosData;
        DLCTrackingOut.PoseTracking.EventIndex(:,end+1)  = DLCSave.PoseTracking.EventIndex;
        DLCTrackingOut.PoseTracking.Performance(end+1)    = DLCSave.PoseTracking.Performance;
        DLCTrackingOut.PoseTracking.Images(end+1)         = DLCSave.PoseTracking.Images;
        DLCTrackingOut.PoseTracking.ImagesIndex(end+1)    = DLCSave.PoseTracking.ImagesIndex;
    end
end
%% Save
save(fullfile(savePath,'DLCTrackingOut.mat'),'DLCTrackingOut','-v7.3');
end