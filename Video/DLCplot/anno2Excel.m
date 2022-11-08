function anno2Excel(tarPath,varargin)
p = inputParser;
addRequired(p,'tarPath',@isfolder);
addOptional(p,'savePath','',@isfolder);
parse(p,tarPath,varargin{:});
savePath = p.Results.savePath;
if isempty(savePath)
    savePath = tarPath;
end
% path_func = 'C:\Users\CY\OneDrive\lab\Codes\CY\Behavior\Function_Data';addpath(path_func);
% filepath = [uigetdir('*.*','Choose the path containing GUI data'),'\'];
filename = dir(fullfile(tarPath,'*Annotated*.mat'));
%%
Bfileloaded = false;
for i=1:length(filename)
    file = filename(i).name;
    load(fullfile(tarPath,file),'VidAnno');
    % check bug
    idx_udl = strfind(file,'_');
    idxPress_file = str2double(file(idx_udl(3)-3:idx_udl(3)-1));
    if VidAnno.PressIndex~=idxPress_file
        if ~Bfileloaded
            bPath = fullfile(tarPath,['..',filesep],['..',filesep],['..',filesep]);
            b = getBehaviorData(bPath);
            Bfileloaded = true;
        end
        metafile = fullfile(tarPath,'..',replace(file,'Annotated',''));
        load(metafile,'VidMeta');
        % recover
        VidAnno.PressIndex = VidMeta.EventIndex;
        VidAnno.PressTime = VidMeta.EventTime;
        VidAnno.Performance = VidMeta.Performance;
        if isa(b,'table')
            VidAnno.RT = num2str(1000.*(b.HT(VidAnno.PressIndex)-b.FP(VidAnno.PressIndex)));
            VidAnno.FP = b.FP(VidAnno.PressIndex);
        end
    end
    % erase RT in premature condition
    if strcmp(string(VidAnno.Performance),'Premature')
        VidAnno.RT='####';
    end
    MovementGUI(i) = VidAnno;
end
save(fullfile(savePath,'MovementGUI'),'MovementGUI')
%% Generate xlsx file
T = struct2table(MovementGUI);
% modified variable name
T.Properties.VariableNames("SessionDate") = "SessionName";
T.Properties.VariableNames("Performance") = "Outcome";
T.Properties.VariableNames("FP") = "FPs";
T.Properties.VariableNames("RT") = "RTs";
T.Properties.VariableNames("Flex") = "FlexOnset";
T.Properties.VariableNames("Touch") = "LeverTouch";
T.Properties.VariableNames("Press") = "PressPaw";
T.Properties.VariableNames("Hold") = "HoldPaw";
T.Properties.VariableNames("Release") = "ReleasePaw";
% modified format
T.SessionName = str2double(T.SessionName);
T.PressTime = round(T.PressTime);
T.FPs = T.FPs.*1000;
newRTs = num2cell(round(str2double(T.RTs)));
newRTs(strcmp(T.Outcome,'Premature')) = cellfun(@(x) replace(num2str(x),'NaN','####'),...
    newRTs(strcmp(T.Outcome,'Premature')),'UniformOutput',false);
T.RTs = newRTs;
T.FlexOnset = round(T.FlexOnset);
T.LeverTouch = round(T.LeverTouch);
T.ReleaseOnset = round(T.ReleaseOnset);
% arrange order
T = movevars(T,'Outcome','After','PressTime');
T = movevars(T,'FPs','After','Outcome');
T = movevars(T,'RTs','After','FPs');
T = movevars(T,'PressPaw','After','ReleaseOnset');
T = movevars(T,'HoldPaw','After','PressPaw');
T = movevars(T,'ReleasePaw','After','HoldPaw');
% save
idx_udl = strfind(filename(1).name,'_');
prefix = filename(1).name(1:idx_udl(2)-1);
suffix = filename(1).name(idx_udl(3):idx_udl(4)-1);
savename = strcat(prefix,suffix,'.xlsx');
writetable(T,fullfile(savePath,savename),'WriteRowNames',true);

end