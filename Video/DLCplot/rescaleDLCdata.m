function newDLC = rescaleDLCdata(dlc,scaleIn)
    curSize = size(dlc.PoseTracking.Images{1},[2 1]); % width × height
    switch isscalar(scaleIn)
        case true % scaling value
            vscaling = scaleIn;
            tarSize = round(curSize.*vscaling);
        case false % target image size (width×height)
            tarSize = scaleIn;
            vscaling = mean([tarSize(1)./curSize(1),tarSize(2)./curSize(2)]);
    end
    if mean(abs(curSize-tarSize))>0.1
        dlc.PoseTracking.PosData = cellfun(@(x,y) x.*[ones(size(x,1),2).*y,ones(size(x,1),2)],...
            dlc.PoseTracking.PosData, num2cell(repelem(vscaling,length(dlc.PoseTracking.PosData))),...
            'UniformOutput',false);
        dlc.PoseTracking.Images = cellfun(@(x,y) imresize(x,y),...
            dlc.PoseTracking.Images,num2cell(repelem(vscaling,length(dlc.PoseTracking.Images))),...
            'UniformOutput',false);
    end
    newDLC = dlc;
end