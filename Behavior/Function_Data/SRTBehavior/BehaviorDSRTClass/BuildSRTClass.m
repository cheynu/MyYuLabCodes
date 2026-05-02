function BClassGroup = BuildSRTClass(Protocol, options)

% Jan 2023, Hanbo Wang & Yu Chen

% This script plots behavior data for SRT learning task

% To run this script smoothly -->
% - Data should be organized as root/ANM/Stage/BpodRawData
% - Functions(packed in root/0_Function) used in this script:
%   @BehaviorDSRT
%   @BehaviorDSRT_Indiv
%   @BehaviorDSRT_Group
%   @calRT
%   @calMovAvg
%   @getSubContents
%   @appendSheets
% - Edit "Meta" in "Initiate" part:
%   Subjects and Group should be matched
%   TrialType: 'AutoShaping', 'LeverPress', 'LeverRelease', 'Wait', '3FPs'
%   Injection: if inject saline/DCZ in different sessions, add this field

% Extracted data will be stored as .mat file in root/ANM/Stage
% Figures will be stored in root/1_Archive/Stage/ANM

arguments
    Protocol
    options.Subjects       string  = []
    options.reExtract      logical = true
    options.rePlot         logical = true
    options.plotProgress   logical = true
    options.plotIndividual logical = true
    options.plotGroup      logical = true
    options.plotRecovery   logical = false
    options.shadedExp      string  = ""
    options.recTitle       string  = ""
end

if isempty(options.Subjects)
    Subjects = arrayfun(@(x)x.name, ...
        getSubContents(fullfile(pwd,'2_ANMs')), 'UniformOutput', false);
else
    Subjects = options.Subjects;
end
nSubject = length(Subjects);

%% Initiate, check data structure and build paths
rng('shuffle'); % Set the random seed for reproducibility of the results
rpath = pwd; % rootpath
fctnPath = fullfile(rpath,'0_Functions'); addpath(genpath(fctnPath));
if ~exist(fullfile(rpath, '1_Archive'), 'dir') || ~exist(fullfile(rpath, '2_ANMs'), 'dir')
    error('Check current path and data structure');
end

TrainingLogXls = dir('TrainingLog*.xls');
if isempty(TrainingLogXls)
    error('Check excel file "TrainingLog"');
elseif length(TrainingLogXls) > 1
    TrainingLog = appendSheets(uigetfile('TrainingLog*.xls'), Subjects);
else
    TrainingLog = appendSheets(TrainingLogXls(1).name, Subjects);
end

rxivPath  = fullfile(rpath,    '1_Archive', Protocol); [~,~] = mkdir(rxivPath);
groupPath = fullfile(rxivPath, 'GroupSummary');        [~,~] = mkdir(groupPath);
progPath  = fullfile(rxivPath, 'Progress');            [~,~] = mkdir(progPath);
indivPath = fullfile(rxivPath, 'Individual');          [~,~] = mkdir(indivPath);

ptclPath = cell(nSubject,1);
for i = 1:nSubject
    ptclPath{i} = fullfile(rpath, '2_ANMs', Subjects{i}, Protocol);
    [~,~] = mkdir(fullfile(indivPath, Subjects{i}));
end

%% Extract Data as BClass & BClass_Indiv
allBClassIndiv = cell(nSubject, 1);  % rxiv cell for building BClass_Group
for i = 1:nSubject  % i = subject num

    if exist(ptclPath{i}, 'dir') == 7
        cd(ptclPath{i}); [~,~] = mkdir('0_Summary');
        summaryPath = fullfile(ptclPath{i}, '0_Summary');
        dataPath = arrayfun(@(x)x.name, dir('20*'), 'UniformOutput', false);

        iLog = TrainingLog(string(TrainingLog.Subject) == string(Subjects{i}), :);
        sbjBClass = cell(1, length(dataPath));  % rxiv cell for building BClass_Indiv
        % extract and processing
        for j = 1:length(dataPath)  % j = date num
    
            jPath = fullfile(ptclPath{i}, dataPath{j}); cd(jPath);
            jLog = iLog(iLog.Date == str2double(dataPath{j}), :);
            % Re-generate BClass when: Meta.reExtract is true || no/multiple such file
            if options.reExtract || length(dir('BClass*.mat')) ~= 1
                delete('BClass*');  % delete old BClass* files
                FileNames = arrayfun(@(x)x.name, dir('*SRT*.mat'), 'UniformOutput', false);
                for k = 1:length(FileNames)  % k = session num
                    if k == 1
                        BClass = BehaviorSRT(FileNames{k});
                    else
                        kBClass = BehaviorSRT(FileNames{k});
                        BClass = BClass.merge(kBClass);  % Merge files of one day
                    end
                    jGroup = jLog.Group;
                    if iscell(jGroup)
                        BClass.Group = jLog.Group{:};
                    elseif isnan(jGroup)
                        BClass.Group = {''};
                    else
                        error('Check "Group" in Trianinglog.xls');
                    end
    
                    jExp = jLog.Experiment;
                    if iscell(jExp)
                        BClass.Experiment = jLog.Experiment{:};
                    elseif isnan(jExp)
                        BClass.Experiment = {''};
                    else
                        error('Check "Experiment" in Trianinglog.xls');
                    end

                    jProtocol = jLog.Protocol;
                    if iscell(jProtocol)
                        BClass.Protocol = jLog.Protocol{:};
                    elseif isnan(jProtocol)
                        BClass.Protocol = {''};
                    else
                        error('Check "Protocol" in Trianinglog.xls');
                    end

                    BClass.save();
                    BClass.save(fullfile(progPath, Subjects{i}));
                end
            else
                BClassName = arrayfun(@(x)x.name, dir('BClass*.mat'), 'UniformOutput', false);
                BClass = load(BClassName{:});
                BClass = BClass.obj;  % BClass*.mat is saved as BClass.obj (struct)
            end
    
            if options.plotProgress
                if options.rePlot || isempty(dir("Fig/*.png"))
                    prgFig = BClass.plot("plotType", "SRT_V2");
                    BClass.print("Figure", prgFig, "savePath", fullfile(pwd, 'Fig'));
                    BClass.print("Figure", prgFig, "savePath", fullfile(progPath, Subjects{i}, 'Fig'));
                end
            end
            sbjBClass{j} = BClass;
        end
    
        cd(summaryPath);
        if options.reExtract || length(dir('BClassIndiv*.mat')) ~= 1
            delete('BClassIndiv*');  % delete old BClass* files
            BClassIndiv = BehaviorSRT_Indiv(sbjBClass);
            BClassIndiv.save();
            BClassIndiv.save(fullfile(indivPath, "1_ClassFile"));
        else
            BClassIndivName = arrayfun(@(x)x.name, dir('BClassIndiv*.mat'), 'UniformOutput', false);
            BClassIndiv = load(BClassIndivName{:});
            BClassIndiv = BClassIndiv.obj;
        end
    
        if options.plotIndividual
            indivFig = BClassIndiv.plot("plotType", "Learning", "shadedExp", options.shadedExp);
            BClassIndiv.print("Figure", indivFig, "savePath", fullfile(summaryPath, 'Fig'), "saveName", BClassIndiv.Subject+"_Learning");
            BClassIndiv.print("Figure", indivFig, "savePath", fullfile(indivPath, '0_Fig'), "saveName", BClassIndiv.Subject+"_Learning");
        end

        if options.plotRecovery
            indivRecFig = BClassIndiv.plot("plotType", "Recovery", "shadedExp", options.shadedExp, "txtTitle", options.recTitle);
            BClassIndiv.print("Figure", indivRecFig, "savePath", fullfile(summaryPath, 'Fig'), "saveName", BClassIndiv.Subject+"_Recovery");
            BClassIndiv.print("Figure", indivRecFig, "savePath", fullfile(indivPath, '0_Fig'), "saveName", BClassIndiv.Subject+"_Recovery");
        end
        allBClassIndiv{i} = BClassIndiv;
    else
        allBClassIndiv{i} = {};
    end
    

end

% BClass_Group
cd(groupPath);
if options.reExtract || length(dir('BClassGroup*.mat')) ~= 1
    delete('BClassGroup*');  % delete old BClass* files
    BClassGroup = BehaviorSRT_Group(allBClassIndiv);
    BClassGroup.save();
else
    BClassGroupName = arrayfun(@(x)x.name, dir('BClassGroup*.mat'), 'UniformOutput', false);
    BClassGroup = load(BClassGroupName{:});
    BClassGroup = BClassGroup.obj;
end

% if options.plotGroup
%     groupFig = BClassGroup.plot('plotType', 'Learning');
%     BClassIndiv.print('tarFig', groupFig, 'tarDir', fullfile(groupPath, 'Fig'));
% end

end