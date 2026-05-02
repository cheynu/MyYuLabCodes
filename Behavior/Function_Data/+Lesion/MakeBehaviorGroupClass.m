function MakeBehaviorGroupClass

savename = ['BClassArrayLesion_*'  '.mat'];

% look for file
thisfile = dir(savename);
if ~isempty(thisfile) && length(thisfile)==1
    load(thisfile.name)
    obj=Behavior.SRT.BehaviorGroupClass(BClassArray); % this is the group obj. Note that I am using package mode to organize these data
    obj.PreLesionSessions  = (-5:-1);
    obj.PostLesionSessions = (1:5);
    obj.PreLesionTrialNum  = 500;
    obj.PostLesionTrialNum = 500;
    obj = obj.FitGauss_Lesion();
    obj = obj.CalRTLesion();
    obj.PlotPrePostLesion;
    obj.PlotPerformanceLesion;
    obj.Print();
    obj.Save();
end

