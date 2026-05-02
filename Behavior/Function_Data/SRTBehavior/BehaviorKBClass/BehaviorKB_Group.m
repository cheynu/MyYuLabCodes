classdef BehaviorKB_Group

    % 20/June/2023, hbWang
    % Behavior class for kornblum protocol (in pure bpod box)
    % *_Group: based on BehaviorKB_Indiv & BehaviorKB

    % Data format containing multiple subjects' data
    % METHODS:
    % STAT = obj.stat
      % STAT
        % .TBT      1 row: raw data of 1 trial. Trial-By-Trial, similar in the followings (Session/Experiment)
        % .SBS      1 row: stat of 1 Subject * Session * TrialType
        % .SBSgrp   1 row: stat of 1 Group * Session * TrialType, calculated by SBS, Grand-Average
        % .SBSebe   1 row: stat of 1 Subject * (Group) * Experiment * TrialType, calculated by SBS, Grand-Average of each day's stat
        % .EBE      1 row: stat of 1 Subject * (Group) * Experiment * TrialType, calculated by TBT
        % .EBEgrp   1 row: stat of 1 Group * Experiment * TrialType, calculated by EBE, Grand-Average
        % such as EBE/EBEgrp suggest to table2struct for previewing variables/fields
    % obj.save(savepath); Save the obj as .mat file & .csv file
        % default path is pwd
    % obj.plot

    properties
        IndivAll cell
        Protocol string {mustBeText}
    end

    properties (Dependent)
        Subjects (:,1) string {mustBeText}
        Groups   (:,1) string {mustBeText}
        nSession (:,1) double {mustBeNumeric}
        DataAll        cell
        Sessions       double {mustBeNumeric}
        Dates          double {mustBeNumeric}
        Tasks          cell   {mustBeText}
        Experiments    string {mustBeText}
        nTrial         double {mustBeNumeric}
        TableAll       cell
        StatOut
    end

    properties (Dependent, GetAccess = private)
        SaveName
    end

    properties (GetAccess = private)
        pStat
    end

    properties (Constant, GetAccess = private)
        OutcomeOptions = ["Cor", "Pre", "Late"]
        CueOptions     = ["Cue", "Uncue"]
        RTOptions      = ["Cor", "CorLate"]
        CustomOptions  = ["EarlyProgress", "LateProgress"];
        ProgressLength = [150,50]  % (1) - trial/session; (2) - trial/FP
    end
    
    methods
        function obj = BehaviorKB_Group(behavKBIndiv, protocol)
            arguments
                behavKBIndiv (:,1) cell
                protocol           string {mustBeText} = ""
            end
            obj.Protocol = protocol;
            dataAll = behavKBIndiv(cellfun(@(x) isa(x,'BehaviorKB_Indiv'), behavKBIndiv, 'UniformOutput',true));
            obj.IndivAll = dataAll;
        end

        function value = get.DataAll(obj)
            dataAll = obj.IndivAll;
            % reorganize: nest --> spread
            dataOut = {};
            for i = 1:size(dataAll,1)
                dataOut(end+1,1:dataAll{i}.nSession) = dataAll{i}.DataAll;
            end
            value = dataOut;
        end

        function value = get.Subjects(obj)
            value = string(cellfun(@(x)x.Subject,obj.IndivAll,'UniformOutput',false));
        end

        function value = get.Groups(obj)
            value = string(cellfun(@(x)x.Group,obj.IndivAll,'UniformOutput',false));
        end

        function obj = set.Groups(obj,value)
            value = string(value);
            for i = 1:length(obj.Subjects)
                obj.IndivAll{i}.Group = value{i};
            end
        end
        
        function value = get.nSession(obj)
            value = cellfun(@(x)x.nSession,obj.IndivAll,'UniformOutput',true);
        end
        
        function value = get.Sessions(obj)
            value = cellfun(@(x)getProp(x,'Session'),obj.DataAll,'UniformOutput',false);
        end

        function obj = set.Sessions(obj,value)
            for i = 1:length(obj.Subjects)
                obj.IndivAll{i,1}.Sessions(1:obj.nSession(i)) = value(i,1:obj.nSession(i));
            end
        end

        function value = get.Dates(obj)
            value = cellfun(@(x)getProp(x,'Date'),obj.DataAll,'UniformOutput',false);
        end

        function value = get.Tasks(obj)
            value = cellfun(@(x)getProp(x,'Task',''),obj.DataAll,'UniformOutput',false);
        end

        function value = get.Experiments(obj)
            value = cellfun(@(x)getProp(x,'Experiment',''),obj.DataAll,'UniformOutput',false);
            value = string(value);
        end

        function obj = set.Experiments(obj,value)
            for i = 1:length(obj.Subjects)
                ivalue = value(i,1:obj.nSession(i));
                obj.IndivAll{i,1}.Experiments = ivalue; % string{i}
            end
        end

        function value = get.nTrial(obj)
            value = cellfun(@(x)getProp(x,'nTrial'),obj.DataAll,'UniformOutput',false);
        end

        function value = get.TableAll(obj)
            value = cellfun(@(x)getProp(x,'Table'),obj.DataAll,'UniformOutput',false);
        end

        function value = get.StatOut(obj)
            value = obj.pStat;
        end
        
        function obj = stat(obj, updateIndiv)
            arguments
                obj
                updateIndiv = false  % 21/Apr/2023 hbWang
                % add this param for individual class update
                % (indiv.TBT/SBS... is no longer dependent)
            end
            STAT = struct;
            % TBT
            value = table;
            for i=1:length(obj.Subjects)
                if updateIndiv
                    obj.IndivAll{i} = obj.IndivAll{i}.stat();
                end
                value = [value; obj.IndivAll{i}.TBT];
            end
            STAT.TBT = value;
            % SBS
            value = table;
            for i = 1:length(obj.Subjects)
                value = [value; obj.IndivAll{i}.SBS];
            end
            prgLen = round(obj.ProgressLength(1)/value.progressStep(1));
            prgLenFP = round(obj.ProgressLength(2)/value.progressStep(1));
            
            STAT.SBS = value;
            STAT.SBS = removevars(STAT.SBS, {'progressPerf', 'progressRT', ...
                'progressWin', 'progressStep', 'progressTime'});
            STAT.SBS = addProgressData(STAT.SBS, value.progressPerf, {'Cor','Pre','Late'}, prgLen);
            STAT.SBS = addProgressData(STAT.SBS, value.progressRT, {'Cor','CorLate'}, prgLen, {'RT', 'RelT'});
            for j = 1:length(obj.CueOptions)
                jCue = obj.CueOptions(j);
                STAT.SBS = removevars(STAT.SBS, cellstr("progressPerf_"+jCue));
                STAT.SBS = removevars(STAT.SBS, cellstr("progressRT_"+jCue));
                STAT.SBS = removevars(STAT.SBS, cellstr("progressTime_"+jCue));
                STAT.SBS = addProgressData(STAT.SBS, value.("progressPerf_"+jCue), {'Cor','Pre','Late'}, ...
                    prgLenFP, cellstr(["Cor_"+jCue,"Pre_"+jCue,"Late_"+jCue]));
                STAT.SBS = addProgressData(STAT.SBS, value.("progressRT_"+jCue), {'Cor','CorLate'}, ...
                    prgLenFP, cellstr(["RT_"+jCue,"RelT_"+jCue]));
            end

            % SBSgrp
            SBSerase = removevars(STAT.SBS,{'Subject','Experiment','Date'});
            value = grpstats(SBSerase,{'Group','Session','Task'},{'mean','sem'});
            STAT.SBSgrp = value;
            % SBSebe
            SBSerase = removevars(STAT.SBS,{'Subject','Date'});
            value = grpstats(SBSerase,{'Session','Group','Experiment','Task'},{'mean','sem'});
            STAT.SBSebe = value;
            % EBE
            value = table;
            for i = 1:length(obj.Subjects)
                value = [value;obj.IndivAll{i}.EBE];
            end
            STAT.EBE = value;
            %EBEgrp
            EBEerase = removevars(STAT.EBE,{'Subject'});
            value = grpstats(EBEerase,{'Group','Experiment','Task'},{'mean','sem'});
            STAT.EBEgrp = value;

            obj.pStat = STAT;

            function out = addProgressData(dataset, in, subvar, prglen, newname)
                % this mini function add progressdata to dataset (SBS)
                % dataset - original SBS
                %      in - value.progress*
                %  subvar - subset of in, e.g. {'Cor','Pre','Late'} for
                %               performance; {'Cor', 'CorLate'} for RT
                %  prglen - length of progress mat (default 200
                %               trials/session & 70 trials/FP)
                % newname - new variable names while adding to dataset e.g. 
                %               {'RTC', 'RTCL'} rename 'Cor/CorLate' to 'RTC/RTCL'
                if nargin < 5
                    newname = subvar;
                end
                for isub = 1:length(subvar)
                    for iprg = 1:height(in)
                        if ~isempty(in{iprg})
                            iprgvalue.(subvar{isub}) = in{iprg}.(subvar{isub});
                            iprglen = height(iprgvalue.(subvar{isub}));
                            if prglen<iprglen  % if current session longer than default(200)
                                prg.(subvar{isub})(iprg,1:prglen) = iprgvalue.(subvar{isub})(1:prglen)';
                            else               % current session shorter than 200
                                prg.(subvar{isub})(iprg,1:iprglen) = iprgvalue.(subvar{isub})(1:iprglen)';
                                prg.(subvar{isub})(iprg,iprglen+1:prglen) = NaN;
                            end
                        else
                            prg.(subvar{isub})(iprg,1:prglen) = nan(1,prglen);
                        end
                    end
                    dataset = addvars(dataset, prg.(subvar{isub}), 'NewVariableNames', cellstr("progress"+string(newname{isub})));
                end
                out = dataset;
            end
        end

        function out = getSBSdata(obj, var, options)
            % Output: struct "out"
            %   .DataAll     - n*m array, n sessions and m subjects
            %                - e.g, Correct ratio in Wait1 S01 of Subject Lavazza
            %                - if target variable is progress data, m=nSubj*length(data)
            %   .Subject     - all subjects' name;
            %   .Group       - groups corresponding to .Subject
            %   .Session     - #session;
            %   .Experiment  - experiments corr. to .Session
            % For multi-group data:
            %   .DataByGroup - DataAll divided by group name
            %   .mean        - mean of .DataByGroup.(GroupX) in dim2 (sessions)
            %   .sem/.ci95   - sem or 95%bootci of mean
            % ** Set options.calStat="Group" and get:
            %   .stat_group  - rmANOVA and multicomparison result
            %                -   Within Factor: Session
            %                -   Between Factor: Group
            %                - multicomparison "Group-By-Session"
            % ** Set options.calStat="Experiment" and get:
            %   .stat_exp    - add "Experiment" to Within Factor
            %                - multicomparison "Session-By-Group"
            % Input defined in arguments
            arguments
                obj
                var                 (1,1) string {mustBeText}
                % variable to extract, e.g, Cor for correct ratio

                options.Varcol      (1,1) double              = 0
                % which column in target variable, defined for multi-FPs
                % default 0 ~ select all data

                options.Task        (1,1) string {mustBeText} = "KB1000Cue50"
                % Task(protocol) to extract (Wait1, Wait2, 3FPs)

                options.Varname     (1,1) string {mustBeText} = obj.SaveName
                % save name of this variable in out.VariableName
                % e.g, obj.getSBSdata("Cor_FP", 'Varcol', 1, 'Task', "3FPs", ...
                %                  'Sessions', 1:8, 'Varname', "Correct3FP_S")
                %   example codes above: get 1~8 Sessions Correct ratio of short FP trials,
                %     and set out.VariableName = Correct3FP_S

                options.Sessions    (1,:) double              = []
                % what session to extract (e.g, [-3,-2,-1, 1,2,3])
                % default = [], extract all sessions (trim to min sessions of max subjects)

                options.calStat     (1,1) string              = "Group"
                % calculate mean/sem/ci95 and rmANOVA by "Group" or "Experiment"
                % set to "" if don't need this
            end

            sbs = obj.StatOut.SBS;
            allsubj = unique(sbs.Subject, 'stable');
            % update sbs by specific task
            sbs = sbs(sbs.Task == string(options.Task),:);

            if ~isempty(options.Sessions)
                sessions = options.Sessions;
            else
                it = tabulate(sbs.Session);
                sessions = find(it(:, 2) == max(it(:, 2)));
            end
            % update sbs by sessions
            sbs = sbs(ismember(sbs.Session, sessions),:);
            sbs_var = []; group = []; subjname = [];
            for isubj = 1:length(allsubj)
                isbs = sbs(sbs.Subject == allsubj(isubj),:);
                isbs_var = isbs.(var);
                % For Cue/Uncue statistics, choose specific column of data
                if options.Varcol ~= 0
                    isbs_var = isbs_var(:,options.Varcol);
                end
                isbs_var = reshape(isbs_var',[],1); % reshape data to 1 col
                sbs_var = [sbs_var, isbs_var];
                group = [group, string(isbs.Group(1))];
                subjname = [subjname, string(isbs.Subject(1))];
                if isubj == 1
                    experiment = isbs.Experiment;
                    allexp = unique(experiment, 'stable');
                    logicexp = zeros(length(experiment),1);
                    logicexp(experiment==allexp(1)) = 1;
                end
            end

            allgroup = unique(group);
            if options.calStat~="" && length(allgroup) > 1
                for igrp = 1:length(allgroup)
                    sbsgrp_var.(allgroup(igrp)) = sbs_var(:,group==allgroup(igrp));
                    var_mean.(allgroup(igrp)) = mean(sbsgrp_var.(allgroup(igrp)), 2, 'omitnan');
%                     var_bootstrap = bootstrp(1000, @(x) mean(x, 'omitnan'), sbsgrp_var.(allgroup(igrp))');
%                     var_ci95.(allgroup(igrp)) = prctile(var_bootstrap, [0.025, 0.975]);
                    var_ci95.(allgroup(igrp)) = bootci(1000, @(x) mean(x, 'omitnan'), sbsgrp_var.(allgroup(igrp))');
                    sem_temp = std(sbsgrp_var.(allgroup(igrp)), 0, 2, 'omitnan')/sqrt(size(sbsgrp_var.(allgroup(igrp)),2));
                    var_sem.(allgroup(igrp))(1,:) = var_mean.(allgroup(igrp)) - sem_temp;
                    var_sem.(allgroup(igrp))(2,:) = var_mean.(allgroup(igrp)) + sem_temp;
                end
            end

            if options.Varname ~= ""
                Varname = options.Varname;
            else
                Varname = var;
            end

            if options.calStat ~= ""
                out.mean = var_mean;
                out.ci95 = var_ci95;
                out.sem = var_sem;
                out.DataByGroup = sbsgrp_var;
                switch options.calStat
                    case "Group"
                        logicgroup = zeros(length(group),1);
                        logicgroup(group==allgroup(1)) = 1;
                        [tbl,rm] = simple_mixed_anova(sbs_var',logicgroup,{'Sessions'},{'Group'});
                        out.stat_group.rmANOVA = tbl;
                        out.stat_group.multicompare = multcompare(rm, 'Group', 'by', 'Sessions');
                    case "Experiment"
                        t = addvars(array2table(sbs_var'), group', 'NewVariableNames', "Group");
                        within = table(experiment, sessions', 'VariableNames', {'Experiment', 'Session'});
                        m = "Var1-Var"+num2str(length(sessions))+"~Group";
                        rm = fitrm(t, m, 'WithinDesign', within);
                        out.stat_exp.rmANOVA = ranova(rm, 'WithinModel', 'Experiment+Session');
                        out.stat_exp.multicompare = multcompare(rm, 'Session', 'by', 'Group');
                end
            end
            out.DataAll = sbs_var;
            out.Session = sessions;
            out.Experiment = experiment;
            out.Group = group;
            out.Subject = subjname;
            out.VariableName = Varname;
        end

        function [EBEgrp, EBEprop] = getEBEdata(obj, options)
            % Output:
            %   EBEgrp  - Experiment By Experiment data, @grpstats by groups
            %           - e.g. Pre_Lesion, Post_Lesion, Pre_Sham, Post_Sham
            %   EBEprop - properties of EBEgrp, including:
            %           - .EBE: all subjects' EBE data;
            %           - .Subject: all subjects' name;
            %           - .Session: #session;
            %           - .Group: groups corresponding to .Subject
            %           - .Experiment: experiments corr. to .Session
            % Input defined in arguments
            arguments
                obj
                options.Sessions                   % #session, e.g. [-3:-1, 1:3]
                options.Samples  double = 50;      % random sample trials for one session
                options.Task     string = "KB1000Cue50"   % task of target sessions
                options.Mode     string = "random" % mode of trial sampling
            end
            rng('shuffle'); % set random seeds

            tbt = obj.StatOut.TBT;
            allsubj = unique(tbt.Subject, 'stable');
            % update sbs by specific task
            tbt = tbt(tbt.Task == string(options.Task),:);

            if ~isempty(options.Sessions)
                sessions = options.Sessions;
            else
                it = tabulate(tbt.Session);
                sessions = find(it(:, 2) == max(it(:, 2)));
            end
            % update sbs by sessions
            tbt = tbt(ismember(tbt.Session, sessions),:);
            experiment = unique(tbt.Experiment);
            ebe = []; group = []; subjname = [];
            for isubj = 1:length(allsubj)
                tbt_subj = tbt(tbt.Subject==allsubj(isubj),:);  % tbt for one subj
                group = [group, string(tbt_subj.Group(1))];
                subjname = [subjname, string(tbt_subj.Subject(1))];
                randidx = []; % random index of all sessions for one subj
                for isess = 1:length(sessions)
                    idxsess = find(tbt_subj.Session==sessions(isess));  % tbt of one subj in one day
                    switch options.Mode
                        case "random"
                            % randomly choose SampleSize of trials 
                            randidx = [randidx randi([idxsess(1) idxsess(end)],1,options.Samples)];
                        case "fixed"
                            % choose the first SampleSize of trials
                            if length(idxsess)>=options.Samples
                                randidx = [randidx idxsess(1:options.Samples)];
                            else % if nTrials < samplesize, use randi
                                randidx = [randidx randi([idxsess(1) idxsess(end)],1,options.Samples)];
                            end
                    end
                end
                rand_tbt_subj = tbt_subj(randidx,:);
                allexp = unique(rand_tbt_subj.Experiment);
                for iexp = 1:length(allexp)
                    data = rand_tbt_subj(rand_tbt_subj.Experiment==allexp{iexp},:);
                    stat = calIndivStatKB(data,true,'ifDistr',true);
                    ebe = [ebe;stat];
                end
            end
            ebetemp = removevars(ebe,{'Subject','Task'});
            ebegrp = grpstats(ebetemp,{'Group','Experiment'},{'mean','sem','meanci'});
            EBEprop.EBE = ebe;
            EBEprop.Subject = subjname;
            EBEprop.Session = sessions;
            EBEprop.Task = options.Task;
            EBEprop.Group = group;
            EBEprop.Experiment = experiment;
            EBEgrp = ebegrp;
        end

        function value = get.SaveName(obj)
            if obj.Protocol == ""
                value = "BClassGroup_" + string(datetime('now','Format','yyyyMMdd'));
            else
                value = "BClassGroup_" + obj.Protocol;
            end
        end

        function obj = reNumberSessions(obj, indicator, switchStr)
            arguments
                obj
                indicator string {mustBeMember(indicator, ["Tasks", "Experiments"])}
                switchStr string = []
            end
            % re-number sessions by experiments
            allIndicators = obj.(indicator);
            newSess = zeros(size(allIndicators));
            if isempty(switchStr)
                % simply renumber sessions as 1:n for each experiment
                for i = 1:height(allIndicators)
                    kk = 1;
                    for j = 1:length(allIndicators)
                        if ~isempty(allIndicators{i, j})
                            if j > 1
                                if string(allIndicators{i, j}) ~= string(allIndicators{i, j-1})
                                    kk = 1;
                                else
                                    kk = kk + 1;
                                end
                            end
                            newSess(i, j) = kk;
                        end
                    end
                end
            else
                % renumber sessions as -m:-1 for exp1 and 1:n for exp2
                expcmp1 = strcmp(allIndicators, char(switchStr(1)));
                expcmp2 = strcmp(allIndicators, char(switchStr(2)));
                for i = 1:height(allIndicators)
                    idx1 = find(expcmp1(i, :));
                    idx1_end = find(expcmp1(i, :) == 0, 1, 'first');
                    idx2 = find(expcmp2(i, :));
                    if ~isempty(idx1)
                        newSess(i, idx1) = idx1-idx1_end;
                        idx_pos = find(newSess(i, idx1) > 0);
                        newSess(i, idx1(idx_pos)) = newSess(i, idx1(idx_pos))+1;
                    end
                    if ~isempty(idx2)
                        newSess(i, idx2) = idx2-idx2(1)+1;
                    end
                end
            end
            obj.Sessions = newSess;
        end

        function obj = changeGroupName(obj, oldGrp, newGrp)
            if length(oldGrp) ~= length(newGrp)
                error('Check inputs length: old ~ new groups');
            end
            grpAll = obj.Groups;
            nSes = obj.nSession;
            grpCell = cell(size(nSes));
            for i = 1:length(nSes)
                for j = 1:length(oldGrp)
                    if grpAll(i) == string(oldGrp{j})
                        grpCell{i} = newGrp{j};
                    end
                end
                if isempty(grpCell{i})
                    grpCell{i} = grpAll(i);
                end
            end
            obj.Groups = grpCell;
        end

        function save(obj, options)
            arguments
                obj
                options.savePath string = pwd
                options.saveName string = obj.SaveName
            end
            [~,~] = mkdir(options.savePath);
            save(fullfile(options.savePath, options.saveName), "obj");
        end

        function print(obj, options)
            arguments
                obj
                options.Figure   = []
                options.savePath = pwd
                options.saveName = obj.SaveName
            end
            if isempty(options.Figure)
                warning("No existing figure, use default settings");
                options.Figure = obj.plot();
            end

            [~,~] = mkdir(options.savePath);
            savename = fullfile(options.savePath, options.saveName);
            print(options.Figure, '-dpng', savename);
            print(options.Figure, '-depsc2', savename);
            saveas(options.Figure, savename, 'fig');
        end

        function Fig = plot(obj,options)
            arguments
                obj
                options.plotType char {mustBeMember(options.plotType, ...
                    {'Learning', 'LearningHeat', 'CmpExp', 'CmpExpBySession', 'Progress'})} = 'Learning'
                options.taskName string = ""
                options.expName  (1,:) cell {mustBeText} = {}
                options.grpName  (1,:) cell {mustBeText} = {}
                options.sesList  (1,:) cell {mustBeVector} = {}
                options.saveName char {mustBeText} = {}
                options.figPath  char {mustBeText} = {}
                % to edit ylim, input (e.g. 'figParam', figParam.corLim) to
                % change default ylim settings
                options.figParam struct = []
            end
            
            Obj = obj;

            % Set experiment names
            if ~isempty(options.expName)
                expName = options.expName;
            else
                expName = unique(string(Obj.Experiments), 'stable');
                expName = expName(expName~="");
                dispList = "";
                for idisp = 1:length(expName)
                    dispList = dispList+" "+expName(idisp);
                end
                disp("Default expName = "+dispList);
            end
            if length(expName) > 2
                error('Check "expName" inputs or "Experiment" in TrainingLog*.xls');
            end

            % Set group names
            if ~isempty(options.grpName)
                grpName = options.grpName;
            else
                grpName = unique(Obj.Groups);
                dispList = "";
                for idisp = 1:length(grpName)
                    dispList = dispList+" "+grpName(idisp);
                end
                disp("Default grpName = "+dispList);
            end
            if length(grpName) > 2
                error('Check "grpName" inputs or "Group" in TrainingLog*.xls');
            end

            if options.taskName ~= ""
                taskName = options.taskName;
            else
                taskName = unique(string(Obj.Tasks), 'stable');
                taskName = taskName(taskName~="");
                dispList = "";
                for idisp = 1:length(taskName)
                    dispList = dispList+" "+taskName(idisp);
                end
                disp("Default protocolName = "+dispList);
            end

            if ~isempty(options.sesList)
                sesList = options.sesList;
            else
                sesList = {};
                disp("Default sesList = {}.");
            end

            if ~isempty(options.saveName)
                saveName = options.saveName;
            else
                saveName = obj.SaveName+string(options.plotType);
                disp("Default saveName = "+string(saveName));
            end

            % Parameters
            cTab10 = tab10(10);
            cBlue = cTab10(1,:); cOrange = cTab10(2,:); cGreen = cTab10(3,:);
            cRed = cTab10(4,:);  cBrown = cTab10(6,:);  cGray = cTab10(8,:);
            cBlue5 = Blues(5); cBlue3 = cBlue5(3:end,:);
            cGreen5 = Greens(5); cGreen3 = cGreen5(3:end,:);

            cExp = [cBlue;cGray]; cGrp = [cOrange;cGray];
            cCPL = [cGreen;cRed;cGray]; cPre_Late = cCPL(2:3,:);
            c3FPs = [cGray;mean([cOrange;cGray]);cOrange];

            set(groot,'defaultAxesFontName','Helvetica');
            fontAxesSz = 7; fontLablSz = 9; fontTitlSz = 10;
            fpList = [0.5 1.0 1.5];
            lineWidthList = [1 1.5 1.5];
            lineStyleList = ["-", "-.", "-"];
            xedges = setXEdges; % custom function to set xedges

            % set figure parameters
            figParamDef.figSize  = [12.0 15.0];
            figParamDef.corLim   = [0.40 1.00];
            figParamDef.preLim   = [0.00 0.50];
            figParamDef.lateLim  = [0.00 0.40];
            figParamDef.rtLim    = [0.20 0.50];
            figParamDef.rtiqrLim = [0.05 0.25];
            figParam = figParamDef;
            if ~isempty(options.figParam)
                fieldList = fieldnames(options.figParam);
                for ifl = 1:length(fieldList)
                    figParam.(fieldList{ifl}) = options.figParam.(fieldList{ifl});
                end
            end

            switch lower(options.plotType)
                case 'cmpexp'
                    Fig = cmpExpPlot(Obj);
                case 'cmpexpbysession'
                    Fig = cmpExpPlotBySession(Obj);
                case 'progress'
                    Fig = progressPlot(Obj);
            end

            if ~isempty(options.figPath)
                figPath = options.figPath; cd(figPath);
                saveas(Fig,saveName,'fig');
                print(Fig,'-dpng',saveName);
                print(Fig,'-depsc2',saveName);
            else
                disp("No figPath, current figure not saved")
            end
            %% Comparison between two experiment conditions
            function h = cmpExpPlot(Obj)
                
                Obj = Obj.reNumber(expName); % reNumber sessions by expName
                if ~isempty(sesList)
                    Obj = Obj.reExp(sesList, expName); % Calculate select sessions' obj & stat
                end
                STAT = Obj.stat;
                EBE = STAT.EBE(STAT.EBE.Experiment~='reject',:);
                EBEgrp = STAT.EBEgrp(STAT.EBEgrp.Experiment~='reject',:);
                titleText = "Comparison: "+string(expName{1})+" vs. "+string(expName{2});
                
                axeSize  = [3.5, 3.5*0.6];
                axeSize2 = [2.5, 2.5];
                xstart = 1.3; xgap = 1.0; ncol = 3; xmap = zeros(1,ncol);
                ystart = 1.0; ygap = 0.6; nrow = 5; ymap = zeros(1,nrow);
                for icol = 1:ncol
                    xmap(icol) = xstart + (axeSize(1)+xgap)*(icol-1);
                end
                for irow = 1:nrow
                    ymap(irow) = ystart + (axeSize(2)+ygap)*(irow-1);
                end
                ymap(3) = ymap(3) + ygap;
                ymap([4,5]) = ymap([4,5]) + axeSize2(2)-axeSize(2)+3*ygap;
                ymap = fliplr(ymap);
                figSize = [xmap(end)+axeSize(1)+xgap ymap(1)+axeSize(2)+ygap+1.5];

                tickLen = [0.1 0.2]/max(axeSize); % cm

                fpLim  = [fpList(1)-0.25,fpList(end)+0.25];
                fpTick = fpList;  fpTickLabel = string(fpTick*1000);
                yTick  = 0:0.2:1; yTickLabel  = string(yTick); 
                yTickLabel100  = string(yTick*100); 
                yTickLabel1000 = string(yTick*1000);
                corLim = figParam.corLim;   preLim = figParam.preLim; lateLim = figParam.lateLim;
                rtLim  = figParam.rtLim;  rtiqrLim = figParam.rtiqrLim;

                % plot figure
                h = figure(3); clf(h, 'reset');
                set(h, 'name', 'compExpPlot', 'units', 'centimeters', 'position', [2 2 figSize], 'color', 'w');

                % plot grp1 data (e.g. hM3Dq, Lesion group)
                % ha11, grp1 exp1/2, correct ratio under 3FPs
                ha11 = axes;
                set(ha11, 'units', 'centimeters', 'position', [xmap(1) ymap(1) axeSize], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', tickLen, ...
                    'xlim', fpLim, 'xtick', fpTick, 'xticklabel', fpTickLabel, ...
                    'ylim', corLim, 'ytick', yTick, 'yticklabel', yTickLabel100, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                plot3FPebe(EBEgrp, "Cor", 'grpName', string(grpName{1}));
                xlabel('Foreperiod (ms)','Fontsize',fontLablSz,'FontName','Arial');
                ylabel('Correct (%)','Fontsize',fontLablSz,'FontName','Arial');
                
                % ha12, grp1 exp1/2, premature ratio under 3FPs
                ha12 = axes;
                set(ha12, 'units', 'centimeters', 'position', [xmap(2) ymap(1) axeSize], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', tickLen,...
                    'xlim', fpLim, 'xtick', fpTick, 'xticklabel', fpTickLabel,...
                    'ylim', preLim, 'ytick', yTick, 'yticklabel', yTickLabel100, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                plot3FPebe(EBEgrp, "Pre", 'grpName', string(grpName{1}));
                xlabel('Foreperiod (ms)','Fontsize',fontLablSz,'FontName','Arial');
                ylabel('Premature (%)','Fontsize',fontLablSz,'FontName','Arial');
                
                % ha13, grp1 exp1/2, late ratio under 3FPs
                ha13 = axes;
                set(ha13, 'units', 'centimeters', 'position', [xmap(3) ymap(1) axeSize], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', tickLen,...
                    'xlim', fpLim, 'xtick', fpTick, 'xticklabel', fpTickLabel,...
                    'ylim', lateLim, 'ytick', yTick, 'yticklabel', yTickLabel100, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                plot3FPebe(EBEgrp, "Late", 'grpName', string(grpName{1}));
%                 xlabel('Foreperiod (ms)','Fontsize',fontLablSz,'FontName','Arial');
                ylabel('Late (%)','Fontsize',fontLablSz,'FontName','Arial');

                % ha21, grp1 exp1/2, reaction time under 3FPs
                ha21 = axes;
                set(ha21, 'units', 'centimeters', 'position', [xmap(1) ymap(2) axeSize], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', tickLen,...
                    'xlim', fpLim, 'xtick', fpTick, 'xticklabel', fpTickLabel,...
                    'ylim', rtLim, 'ytick', yTick, 'yticklabel', yTickLabel1000, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                plot3FPebe(EBEgrp, "RelT", 'grpName', string(grpName{1}));
                xlabel('Foreperiod (ms)','Fontsize',fontLablSz,'FontName','Arial');
                ylabel('Reaction time (ms)','Fontsize',fontLablSz,'FontName','Arial');

                % ha22, grp2 exp1/2, RT IQR under 3FPs
                ha22 = axes;
                set(ha22, 'units', 'centimeters', 'position', [xmap(2) ymap(2) axeSize], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', tickLen,...
                    'xlim', fpLim, 'xtick', fpTick, 'xticklabel', fpTickLabel,...
                    'ylim', rtiqrLim, 'ytick', yTick, 'yticklabel', yTickLabel1000, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                plot3FPebe(EBEgrp, "RT_IQR", 'grpName', string(grpName{1}));
                xlabel('Foreperiod (ms)','Fontsize',fontLablSz,'FontName','Arial');
                ylabel('RT IQR (ms)','Fontsize',fontLablSz,'FontName','Arial');

                % ha31/32/33, grp1/2 exp1/2, error pattern
                for iFP = 1:size(EBE.PreTendency_FP,2)
                    idxE1G1 = find(EBE.Experiment==expName{1} & EBE.Group==grpName{1});
                    idxE2G1 = find(EBE.Experiment==expName{2} & EBE.Group==grpName{1});
                    idxE1G2 = find(EBE.Experiment==expName{1} & EBE.Group==grpName{2});
                    idxE2G2 = find(EBE.Experiment==expName{2} & EBE.Group==grpName{2});
                    ha = axes;
                    set(ha, 'units', 'centimeters', 'position', [xmap(iFP) ymap(3) axeSize2], ...
                        'nextplot', 'add','tickDir', 'out', 'ticklength', tickLen,...
                       'xlim',[-1 1],'ylim',[-1 1],'xtick',[-1 0 1],'ytick',[-1 0 1], ...
                       'fontsize',fontAxesSz,'fontname','Arial'); %
                    plot([-1 1],[-1,1],':k','lineWidth',0.6);
                    sc1 = scatter(EBE.PreTendency_FP(idxE1G1,iFP),EBE.PreTendency_FP(idxE2G1,iFP),...
                        15,'MarkerEdgeColor',cGrp(1,:),'MarkerFaceColor',cGrp(1,:),...
                        'MarkerFaceAlpha',0.5);
                    sc2 = scatter(EBE.PreTendency_FP(idxE1G2,iFP),EBE.PreTendency_FP(idxE2G2,iFP),...
                        15,'MarkerEdgeColor',cGrp(2,:),'MarkerFaceColor',cGrp(2,:),...
                        'MarkerFaceAlpha',0.5);
                    xlabel(expName{1},'Fontsize',fontLablSz,'FontName','Arial');
                    ylabel(expName{2},'Fontsize',fontLablSz,'FontName','Arial');
                    title("FP "+num2str(fpList(iFP)*1000)+" ms",'Fontsize',fontTitlSz,'FontName','Arial');
                    if iFP == 3
                        le = legend([sc1;sc2],{grpName{1};grpName{2}}, ...
                            'Fontsize',fontLablSz,'FontName','Arial');
                        le.ItemTokenSize = [12,15]; legend('boxoff');
                        set(le, 'Fontsize',fontLablSz,'units','centimeters',...
                            'Position',[xmap(end)+xgap+1.5 ymap(1)+axeSize(2)+ygap,1,1]);     
                    end
                end

                % plot grp2 data (e.g. ChR2, Sham group)
                % ha41, grp2 exp1/2, correct ratio under 3FPs
                ha41 = axes;
                set(ha41, 'units', 'centimeters', 'position', [xmap(1) ymap(4) axeSize], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', tickLen,...
                    'xlim', fpLim, 'xtick', fpTick, 'xticklabel', fpTickLabel,...
                    'ylim', corLim, 'ytick', yTick, 'yticklabel', yTickLabel100, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                plot3FPebe(EBEgrp, "Cor", 'grpName', string(grpName{2}));
                xlabel('Foreperiod (ms)','Fontsize',fontLablSz,'FontName','Arial');
                ylabel('Correct (%)','Fontsize',fontLablSz,'FontName','Arial');
                
                % ha42, grp2 exp1/2, premature ratio under 3FPs
                ha42 = axes;
                set(ha42, 'units', 'centimeters', 'position', [xmap(2) ymap(4) axeSize], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', tickLen,...
                    'xlim', fpLim, 'xtick', fpTick, 'xticklabel', fpTickLabel,...
                    'ylim', preLim, 'ytick', yTick, 'yticklabel', yTickLabel100, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                plot3FPebe(EBEgrp, "Pre", 'grpName', string(grpName{2}));
                xlabel('Foreperiod (ms)','Fontsize',fontLablSz,'FontName','Arial');
                ylabel('Premature (%)','Fontsize',fontLablSz,'FontName','Arial');
                
                % ha43, grp2 exp1/2, late ratio under 3FPs
                ha43 = axes;
                set(ha43, 'units', 'centimeters', 'position', [xmap(3) ymap(4) axeSize], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', tickLen,...
                    'xlim', fpLim, 'xtick', fpTick, 'xticklabel', fpTickLabel,...
                    'ylim', lateLim, 'ytick', yTick, 'yticklabel', yTickLabel100, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                plot3FPebe(EBEgrp, "Late", 'grpName', string(grpName{2}));
%                 xlabel('Foreperiod (ms)','Fontsize',fontLablSz,'FontName','Arial');
                ylabel('Late (%)','Fontsize',fontLablSz,'FontName','Arial');

                % ha51, grp2 exp1/2, reaction time under 3FPs
                ha51 = axes;
                set(ha51, 'units', 'centimeters', 'position', [xmap(1) ymap(5) axeSize], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', tickLen,...
                    'xlim', fpLim, 'xtick', fpTick, 'xticklabel', fpTickLabel,...
                    'ylim', rtLim, 'ytick', yTick, 'yticklabel', yTickLabel1000, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                plot3FPebe(EBEgrp, "RelT", 'grpName', string(grpName{2}));
                xlabel('Foreperiod (ms)','Fontsize',fontLablSz,'FontName','Arial');
                ylabel('Reaction time (ms)','Fontsize',fontLablSz,'FontName','Arial');
                
                % ha52, grp2 exp1/2, RT IQR under 3FPs
                ha52 = axes;
                set(ha52, 'units', 'centimeters', 'position', [xmap(2) ymap(5) axeSize], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', tickLen,...
                    'xlim', fpLim, 'xtick', fpTick, 'xticklabel', fpTickLabel,...
                    'ylim', rtiqrLim, 'ytick', yTick, 'yticklabel', yTickLabel1000, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                le = plot3FPebe(EBEgrp, "RT_IQR", 'grpName', string(grpName{2}), 'plotLegend', true);
                set(le, 'Fontsize',fontLablSz,'units','centimeters',...
                    'Position',[xmap(end)+xgap ymap(1)+axeSize(2)+ygap,1,1]);     
                xlabel('Foreperiod (ms)','Fontsize',fontLablSz,'FontName','Arial');
                ylabel('RT IQR (ms)','Fontsize',fontLablSz,'FontName','Arial');

%                 text(xtext,ytext,grpName{2},...
%                     'HorizontalAlignment','left','VerticalAlignment','middle','rotation',-90,...
%                     'fontsize',fontLablSz,'FontName','Arial','fontweight','bold');

                function legendOut = plot3FPebe(ebedata, statstr, varargin)

                    grpname    = getVararginValue(varargin, "grpName",    "string");
                    plotlegend = getVararginValue(varargin, "plotLegend", "logical");

                    meanstat = "mean_" + string(statstr) + "_FP";
                    semstat  = "sem_"  + string(statstr) + "_FP";
                    idx1 = find(ebedata.Group == grpname & ebedata.Experiment==expName{1});
                    idx2 = find(ebedata.Group == grpname & ebedata.Experiment==expName{2});

                    lr1 = plot(fpList, ebedata.(meanstat)(idx1,:), 'o-', 'linewidth', 1, ...
                        'color', cExp(1,:), 'markerfacecolor', cExp(1,:), 'markeredgecolor','w', 'markersize', 5);
                    line([fpList; fpList], [ebedata.(meanstat)(idx1,:)-ebedata.(semstat)(idx1,:); ...
                        ebedata.(meanstat)(idx1,:)+ebedata.(semstat)(idx1,:)], 'color',cExp(1,:), 'linewidth', 1);
                    
                    lr2 = plot(fpList, ebedata.(meanstat)(idx2,:), 'o-', 'linewidth', 1, ...
                        'color', cExp(2,:), 'markerfacecolor', cExp(2,:), 'markeredgecolor','w', 'markersize', 5);
                    line([fpList; fpList], [ebedata.(meanstat)(idx2,:)-ebedata.(semstat)(idx2,:); ...
                        ebedata.(meanstat)(idx2,:)+ebedata.(semstat)(idx2,:)], 'color',cExp(2,:), 'linewidth', 1);
                
                    if plotlegend
                        legendOut = legend([lr1;lr2],{expName{1};expName{2}},'Fontsize',fontLablSz,'FontName','Arial');
                        legendOut.ItemTokenSize = [12,22]; legend('boxoff');
                    end
                end

                % ha00, add title text
                ha00 = axes;
                set(ha00, 'units', 'centimeters', 'position', [xmap(1) ymap(1)+axeSize(2)+0.5 xmap(end)-xmap(1) 0.1]);
                axis off;
                title(titleText, 'FontSize', fontTitlSz, 'FontName', 'Arial', 'FontWeight', 'bold');

            end
            
            %% Learning curve comparison between two experiment conditions
            function h = cmpExpPlotBySession(Obj)

                size1 = [4, 4*0.6];
                xstart = 1.3; xgap = 0.5; ncol = 3; xmap = zeros(1,ncol);
                ystart = 1.0; ygap = 0.3; nrow = 5; ymap = zeros(1,nrow);
                
                for icol = 1:ncol
                    xmap(icol) = xstart + (size1(1)+xgap)*(icol-1);
                end
                for irow = 1:nrow
                    ymap(irow) = ystart + (size1(2)+ygap)*(irow-1);
                end
                ymap = fliplr(ymap);

                corLim = figParam.corLim; preLim = figParam.preLim; lateLim = figParam.lateLim;
                rtLim  = figParam.rtLim;  rtiqrLim = figParam.rtiqrLim;

                % reNumber sessions by expName, plot all performance
                % before/after experiment conditions changed
%                 Obj = Obj.reNumber(expName);
                SBS = Obj.StatOut.SBS;
                SBSebe = Obj.StatOut.SBSebe;
    
                % Trim all subjects' sessions by the minimal of them
                expLen = cell(length(expName), 1);
                expSBS = cell(length(expName), 1);
                for i = 1:length(expName)
                    expSBS{i} = SBS(SBS.Experiment == expName{i}, :);
                    it = tabulate(expSBS{i}.Session);
                    expLen{i} = it(it(:, 2) == max(it(:, 2)), 1);
                end
                xSess = [expLen{1}; expLen{2}]; % new session number for both experiments
                taskStruct.Len = sort(xSess);   % no zero point
                taskStruct.Task = "3FPs";       % not real single fp task, just to plot each fp data
                taskTable = struct2table(taskStruct, 'AsArray', true);

                if any(contains({expName{1}, expName{2}}, 'DCZ'))
                    idxFill = find(contains({expName{1}, expName{2}}, 'DCZ'));
                else
                    idxFill = 2;
                end
                xTick = [expLen{1}(1)+1,0,1,expLen{2}(end)]; xTickLabel = {};
                xTickLabel1 = string([expLen{1}(1),-1,1,expLen{2}(end)]); % for xticklabel, -1 for exp1 sessions
                yTick = 0:0.2:1;
                yTickLabel = cellstr(string(yTick));
                yTickLabel100 = cellstr(string(yTick*100));
                titleText = "Group Compare: "+cellstr(expName{1})+" vs. "+cellstr(expName{2});

                % plot
                h = figure(4); clf(h, 'reset');
                set(h, 'name', 'Learning', 'units', 'centimeters', 'color', 'w', ...
                    'position', [2 2 xmap(end)+size1(1)+0.5 ymap(1)+size1(2)+ygap+2]);

                % ha11, short FP correct sessions
                ha11 = axes;
                set(ha11, 'units', 'centimeters', 'position', [xmap(1) ymap(1) size1], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', [0.02 0.025],...
                    'xtick', xTick, 'xticklabel', xTickLabel,...
                    'ylim', corLim, 'ytick', yTick, 'yticklabel', yTickLabel100, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                le = plot3FPstat(SBSebe, "Cor", 'taskTable', taskTable, 'taskName', "3FPs", ...
                    'whichFP', 1, 'idxFill', idxFill, 'plotLegend', true);
                le.NumColumns = 2;
                set(le,'units', 'centimeters', 'Position',[xmap(end)+xgap+1,ymap(1)+size1(2)+0.8,1,1]);
                ylabel('Correct (%)', 'Fontsize', fontLablSz, 'FontName','Arial');
                title('ShortFP (500ms)', 'Fontsize', fontTitlSz, 'FontName', 'Arial')

                % ha12, mid FP correct sessions
                ha12 = axes;
                set(ha12, 'units', 'centimeters', 'position', [xmap(2) ymap(1) size1], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', [0.02 0.025],...
                    'xtick', xTick, 'xticklabel', {},...
                    'ylim', corLim, 'ytick', yTick, 'yticklabel', yTickLabel100, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                ha12.YAxis.Visible = 'off';
                plot3FPstat(SBSebe, "Cor", 'taskTable', taskTable, 'taskName', "3FPs", ...
                    'whichFP', 2, 'idxFill', idxFill);
                title('MidFP (1000ms)', 'Fontsize', fontTitlSz, 'FontName', 'Arial')

                % ha13, long FP correct sessions
                ha13 = axes;
                set(ha13, 'units', 'centimeters', 'position', [xmap(3) ymap(1) size1], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', [0.02 0.025],...
                    'xtick', xTick, 'xticklabel', xTickLabel,...
                    'ylim', corLim, 'ytick', yTick, 'yticklabel', yTickLabel100, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                ha13.YAxis.Visible = 'off';
                plot3FPstat(SBSebe, "Cor", 'taskTable', taskTable, 'taskName', "3FPs", ...
                    'whichFP', 3, 'idxFill', idxFill);
                title('LongFP (1500ms)', 'Fontsize', fontTitlSz, 'FontName', 'Arial')

                % ha21, short FP premature sessions
                ha21 = axes;
                set(ha21, 'units', 'centimeters', 'position', [xmap(1) ymap(2) size1], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', [0.02 0.025],...
                    'xtick', xTick, 'xticklabel', xTickLabel,...
                    'ylim', preLim, 'ytick', yTick, 'yticklabel', yTickLabel100, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                plot3FPstat(SBSebe, "Pre", 'taskTable', taskTable, 'taskName', "3FPs", ...
                    'whichFP', 1, 'idxFill', idxFill);
                ylabel('Premature (%)', 'Fontsize', fontLablSz, 'FontName', 'Arial');

                % ha22, mid FP premature sessions
                ha22 = axes;
                set(ha22, 'units', 'centimeters', 'position', [xmap(2) ymap(2) size1], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', [0.02 0.025],...
                    'xtick', xTick, 'xticklabel', xTickLabel,...
                    'ylim', preLim, 'ytick', yTick, 'yticklabel', yTickLabel100, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                ha22.YAxis.Visible = 'off';
                plot3FPstat(SBSebe, "Pre", 'taskTable', taskTable, 'taskName', "3FPs", ...
                    'whichFP', 2, 'idxFill', idxFill);

                % ha23, long FP premature sessions
                ha23 = axes;
                set(ha23, 'units', 'centimeters', 'position', [xmap(3) ymap(2) size1], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', [0.02 0.025],...
                    'xtick', xTick, 'xticklabel', xTickLabel,...
                    'ylim', preLim, 'ytick', yTick, 'yticklabel', yTickLabel100, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                ha23.YAxis.Visible = 'off';
                plot3FPstat(SBSebe, "Pre", 'taskTable', taskTable, 'taskName', "3FPs", ...
                    'whichFP', 3, 'idxFill', idxFill);

                % ha31, short FP premature sessions
                ha31 = axes;
                set(ha31, 'units', 'centimeters', 'position', [xmap(1) ymap(3) size1], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', [0.02 0.025],...
                    'xtick', xTick, 'xticklabel', xTickLabel,...
                    'ylim', lateLim, 'ytick', yTick, 'yticklabel', yTickLabel100, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                plot3FPstat(SBSebe, "Late", 'taskTable', taskTable, 'taskName', "3FPs", ...
                    'whichFP', 1, 'idxFill', idxFill);
                ylabel('Late (%)', 'Fontsize', fontLablSz, 'FontName', 'Arial');

                % ha32, mid FP premature sessions
                ha32 = axes;
                set(ha32, 'units', 'centimeters', 'position', [xmap(2) ymap(3) size1], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', [0.02 0.025],...
                    'xtick', xTick, 'xticklabel', xTickLabel,...
                    'ylim', lateLim, 'ytick', yTick, 'yticklabel', yTickLabel100, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                ha32.YAxis.Visible = 'off';
                plot3FPstat(SBSebe, "Late", 'taskTable', taskTable, 'taskName', "3FPs", ...
                    'whichFP', 2, 'idxFill', idxFill);

                % ha33, long FP premature sessions
                ha33 = axes;
                set(ha33, 'units', 'centimeters', 'position', [xmap(3) ymap(3) size1], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', [0.02 0.025],...
                    'xtick', xTick, 'xticklabel', xTickLabel,...
                    'ylim', lateLim, 'ytick', yTick, 'yticklabel', yTickLabel100, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                ha33.YAxis.Visible = 'off';
                plot3FPstat(SBSebe, "Late", 'taskTable', taskTable, 'taskName', "3FPs", ...
                    'whichFP', 3, 'idxFill', idxFill);

                % ha41, short FP premature sessions
                ha41 = axes;
                set(ha41, 'units', 'centimeters', 'position', [xmap(1) ymap(4) size1], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', [0.02 0.025],...
                    'xtick', xTick, 'xticklabel', xTickLabel,...
                    'ylim', rtLim, 'ytick', yTick, 'yticklabel', yTickLabel, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                plot3FPstat(SBSebe, "RT", 'taskTable', taskTable, 'taskName', "3FPs", ...
                    'whichFP', 1, 'idxFill', idxFill);
                ylabel('RT (s)', 'Fontsize', fontLablSz, 'FontName', 'Arial');

                % ha42, mid FP premature sessions
                ha42 = axes;
                set(ha42, 'units', 'centimeters', 'position', [xmap(2) ymap(4) size1], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', [0.02 0.025],...
                    'xtick', xTick, 'xticklabel', xTickLabel,...
                    'ylim', rtLim, 'ytick', yTick, 'yticklabel', yTickLabel, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                ha42.YAxis.Visible = 'off';
                plot3FPstat(SBSebe, "RT", 'taskTable', taskTable, 'taskName', "3FPs", ...
                    'whichFP', 2, 'idxFill', idxFill);

                % ha43, long FP premature sessions
                ha43 = axes;
                set(ha43, 'units', 'centimeters', 'position', [xmap(3) ymap(4) size1], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', [0.02 0.025],...
                    'xtick', xTick, 'xticklabel', xTickLabel,...
                    'ylim', rtLim, 'ytick', yTick, 'yticklabel', yTickLabel, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                ha43.YAxis.Visible = 'off';
                plot3FPstat(SBSebe, "RT", 'taskTable', taskTable, 'taskName', "3FPs", ...
                    'whichFP', 3, 'idxFill', idxFill);

                % ha51, short FP premature sessions
                ha51 = axes;
                set(ha51, 'units', 'centimeters', 'position', [xmap(1) ymap(5) size1], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', [0.02 0.025],...
                    'xtick', xTick, 'xticklabel', xTickLabel1,...
                    'ylim', rtiqrLim, 'ytick', yTick, 'yticklabel', yTickLabel, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                plot3FPstat(SBSebe, "RT_IQR", 'taskTable', taskTable, 'taskName', "3FPs", ...
                    'whichFP', 1, 'idxFill', idxFill);
                xlabel('Sessions', 'Fontsize', fontLablSz, 'FontName', 'Arial');
                ylabel('RT IQR (s)', 'Fontsize', fontLablSz, 'FontName', 'Arial');

                % ha52, mid FP premature sessions
                ha52 = axes;
                set(ha52, 'units', 'centimeters', 'position', [xmap(2) ymap(5) size1], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', [0.02 0.025],...
                    'xtick', xTick, 'xticklabel', xTickLabel1,...
                    'ylim', rtiqrLim, 'ytick', yTick, 'yticklabel', yTickLabel, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                ha52.YAxis.Visible = 'off';
                plot3FPstat(SBSebe, "RT_IQR", 'taskTable', taskTable, 'taskName', "3FPs", ...
                    'whichFP', 2, 'idxFill', idxFill);
                xlabel('Sessions', 'Fontsize', fontLablSz, 'FontName', 'Arial');

                % ha53, long FP premature sessions
                ha53 = axes;
                set(ha53, 'units', 'centimeters', 'position', [xmap(3) ymap(5) size1], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', [0.02 0.025],...
                    'xtick', xTick, 'xticklabel', xTickLabel1,...
                    'ylim', rtiqrLim, 'ytick', yTick, 'yticklabel', yTickLabel, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                ha53.YAxis.Visible = 'off';
                plot3FPstat(SBSebe, "RT_IQR", 'taskTable', taskTable, 'taskName', "3FPs", ...
                    'whichFP', 3, 'idxFill', idxFill);
                xlabel('Sessions', 'Fontsize', fontLablSz, 'FontName', 'Arial');

                % ha00, add title text
                ha00 = axes;
                set(ha00, 'units', 'centimeters', 'position', [xmap(1) ymap(1)+size1(2)+ygap+0.7 xmap(end)-xmap(1) 0.01]);
                axis off;
                title(titleText, 'FontSize', fontTitlSz, 'FontName', 'Arial', 'FontWeight', 'bold');
            end

            %% Progress data of all sessions
            function h = progressPlot(Obj)
                
                if any(contains(taskName, 'Wait')) % learning data, 1 exp & no multiFP
                    plotExp = 0; multiFP = 1;
                    titleText = "Performance & RT progress of "+cellstr(taskName);
                else  % plot learned data (withdraw or post-lesion)
                    multiFP = 3;
                    if length(expName) == 1
                        plotExp = 0;
                    else % plot all performance before/after exp changed
                        plotExp = 1;
                        Obj = Obj.reNumber(expName); % reNumber sessions by expName, 
                        if ~isempty(sesList)  
                            Obj = Obj.reExp(sesList, expName); % Select specific sessions
                        end
                        titleText = "Performance & RT progress of "+cellstr(expName{1})+" vs. "+cellstr(expName{2});
                    end
                end
                STAT   = Obj.stat; 
                SBS    = STAT.SBS(STAT.SBS.Experiment~='reject',:);
                SBSebe = STAT.SBSebe(STAT.SBSebe.Experiment~='reject',:);

                % Trim all subjects' sessions by the minimal of them
                expLen = cell(length(expName), 1);
                expSBS = cell(length(expName), 1);
                for i = 1:length(expName)
                    expSBS{i} = SBS(SBS.Experiment == expName{i}, :);
                    it = tabulate(expSBS{i}.Session);
                    expLen{i} = it(it(:, 2) == max(it(:, 2)), 1);
                end

                taskStruct = struct;
                taskStruct.Task = taskName;
                taskSBS = cell(length(taskName), 1);
                for i = 1:length(taskName)
                    taskSBS{i} = SBS(SBS.Task == taskName{i}, :);
                    if ~isempty(taskSBS{i})
                        it = tabulate(taskSBS{i}.Session);
                        taskStruct.Len{i,1} = it(it(:, 2) == max(it(:, 2)),1);
                    else
                        taskStruct.Len{i,1} = {};
                    end
                end
                taskTable = struct2table(taskStruct);
                taskTable = taskTable(cellfun(@(x) ~isempty(x), taskTable.Len), :);
%                 taskRange = taskTable.Task(1)+" S"+taskTable.Len{1}(1)+...
%                     " ~ "+taskTable.Task(end)+" S"+taskTable.Len{end}(end);
                
                % index of background fill
                idxFill = 2;
                if length(expName) > 1
                    if any(contains({expName{1}, expName{2}}, 'DCZ'))
                        idxFill = find(contains({expName{1}, expName{2}}, 'DCZ'));  
                    end
                else
                    idxFill = [];
                end

                % plotExp: 1 - plot switch line between two exp conditions
                if plotExp
                    sesAll = [expLen{1}; expLen{2}];
                else
                    sesAll = expLen{1};
                end
                sesLen = length(sesAll);

                xstart = 1.3; xgap = 0.5; ncol = 2; xmap = zeros(1,ncol);
                ystart = 1.0; ygap = 0.3; nrow = 4; ymap = zeros(1,nrow);
                % figure position & axes
                if sesLen > 5
                    figSize = [20+xstart+xgap 4*(3+ygap)+2*ystart+ygap];
                    axeSize = [20 3];
                else
                    figSize = [4*sesLen+xstart+xgap 4*(3+ygap)+2*ystart+ygap];
                    axeSize = [4*sesLen 3];
                end

                for icol = 1:ncol
                    xmap(icol) = xstart + (axeSize(1)+xgap)*(icol-1);
                end
                for irow = 1:nrow
                    ymap(irow) = ystart + (axeSize(2)+ygap)*(irow-1);
                end
                ymap = fliplr(ymap);
                xle = 4;
                tickLen = [0.1 0.2]/max(axeSize); % cm

                corLim = figParam.corLim; preLim = figParam.preLim; lateLim = figParam.lateLim;
                rtLim  = figParam.rtLim;  rtiqrLim = figParam.rtiqrLim;
                yTick  = 0:0.2:1;  yTickLabel = string(yTick); 
                yTickLabel100 = string(yTick*100);

                h = figure(5); clf(h, 'reset');
                set(h, 'units', 'centimeters', 'position', [2 2 figSize], 'color', 'w');

                % ha1, progress of performance
                ha1 = axes;
                set(ha1, 'units', 'centimeters', 'position', [xmap(1) ymap(1) axeSize], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', tickLen,...
                    'ylim', corLim, 'ytick', yTick, 'yticklabel', yTickLabel100, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                ylabel('Cor (%)','FontSize',fontLablSz);
                
                plot3FPprogress(SBSebe, "Cor", 'taskTable', taskTable, 'taskName', taskName, ...
                    'idxFill', idxFill, 'multiFP', multiFP, 'plotLegend', false);

                ha2 = axes;
                set(ha2, 'units', 'centimeters', 'position', [xmap(1) ymap(2) axeSize], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', tickLen,...
                    'ylim', preLim, 'ytick', yTick, 'yticklabel', yTickLabel100, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                ylabel('Pre (%)','FontSize',fontLablSz);
                
                plot3FPprogress(SBSebe, "Pre", 'taskTable', taskTable, 'taskName', taskName, ...
                    'idxFill', idxFill, 'multiFP', multiFP, 'plotLegend', false);

                ha3 = axes;
                set(ha3, 'units', 'centimeters', 'position', [xmap(1) ymap(3) axeSize], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', tickLen,...
                    'ylim', lateLim, 'ytick', yTick, 'yticklabel', yTickLabel100, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                ylabel('Late (%)','FontSize',fontLablSz);
                
                plot3FPprogress(SBSebe, "Late", 'taskTable', taskTable, 'taskName', taskName, ...
                    'idxFill', idxFill, 'multiFP', multiFP, 'plotLegend', false);

                ha4 = axes;
                set(ha4, 'units', 'centimeters', 'position', [xmap(1) ymap(4) axeSize], ...
                    'nextplot', 'add', 'tickDir', 'out', 'ticklength', tickLen,...
                    'ylim', rtLim, 'ytick', yTick, 'yticklabel', yTickLabel, ...
                    'fontsize', fontLablSz, 'fontname', 'Arial');
                xlabel('Sessions','FontSize',fontLablSz);
                ylabel('RT (s)','FontSize',fontLablSz);
                
                le = plot3FPprogress(SBSebe, "RTC", 'taskTable', taskTable, 'taskName', taskName, ...
                    'idxFill', idxFill, 'multiFP', multiFP, 'plotLegend', true);
                le.NumColumns = 2;
                set(le,'units', 'centimeters', 'Position',[xmap(end)-xle-xgap,ymap(1)+axeSize(2)+ygap,xle,1], ...
                    'Fontsize', fontLablSz, 'fontname', 'Arial');

                % ha00, add title text
                ha00 = axes;
                set(ha00, 'units', 'centimeters', 'position', [xmap(1) ymap(1)+axeSize(2)+ygap axeSize(1)-xle 0.1]);
                axis off;
                title(titleText, 'FontSize', fontTitlSz, 'FontName', 'Arial', 'FontWeight', 'bold');

            end
            
            %% Function to plot progress data for SBS data (by FP)
            function legendOut = plot3FPprogress(sbsdata, statstr, varargin)

                taskname   = getVararginValue(varargin, "taskName",   "string");
                tasktable  = getVararginValue(varargin, "taskTable",  "table");
                idxfill    = getVararginValue(varargin, "idxFill",    "double");
                multifp    = getVararginValue(varargin, "multiFP",    "double");
                plotlegend = getVararginValue(varargin, "plotLegend", "logical");
                gaplen     = 3;
                xTick      = [];

                idxtask = tasktable.Task == taskname;
                sbsdata = sbsdata(sbsdata.Task == taskname & ...
                    ismember(sbsdata.Session, tasktable.Len{idxtask}), :);

                for isess = 1:length(tasktable.Len{idxtask})
                    idxsess = sbsdata.Session == tasktable.Len{idxtask}(isess);
                    for igrp = 1:length(grpName)
                        idxgrp = sbsdata.Group == grpName{igrp};
                        for ifp = 1:multifp
                            switch taskname
                                case {"Wait1", "Wait2"}
                                    meanstat = "mean_progress"+string(statstr);
                                    semstat  = "sem_progress" +string(statstr);
                                case "3FPs"
                                    meanstat = "mean_progress"+string(statstr)+"_FP"+string(ifp);
                                    semstat  = "sem_progress" +string(statstr)+"_FP"+string(ifp);
                            end
                            ydata = sbsdata.(meanstat)(idxgrp & idxsess,:)';
                            semdata = sbsdata.(semstat)(idxgrp & idxsess,:)';
                            prglen = length(ydata);

                            % xdata: 
                            %  - session number * (progress length +
                            % gap length)
                            xdata = (((isess-1)*(prglen+gaplen)+1):(isess*prglen+(isess-1)*gaplen))';
                            if isess == 1
                                lr{igrp,ifp} = plot(xdata,ydata,lineStyleList(ifp), 'linewidth', lineWidthList(ifp), 'color', cGrp(igrp,:));
                            else
                                plot(xdata,ydata,lineStyleList(ifp), 'linewidth', lineWidthList(ifp), 'color', cGrp(igrp,:));
                                line([(isess-1)*(prglen+gaplen)-gaplen/2 (isess-1)*(prglen+gaplen)-gaplen/2], ...
                                    [0 1],'linestyle',':','linewidth',1,'color','k');
                            end
                        end
                    end
                    xTick = [xTick (isess-1)*(prglen+gaplen)+prglen/2];
                end                            

                if ~isempty(idxfill)
                    xexp = sbsdata.Session(sbsdata.Experiment==expName{idxfill} & sbsdata.Group==grpName{1}); % this exp x values (ignore group)
                    oexp = sbsdata.Session(sbsdata.Experiment==expName{3-idxfill} & sbsdata.Group==grpName{1}); % other exp x values (ignore group)
                    % find and plot exp1/2 switch line
                    [~,switchpoint] = min(abs(sort([xexp;oexp])-1));
                    plot([(switchpoint-1)*(prglen+gaplen)-gaplen/2 (switchpoint-1)*(prglen+gaplen)-gaplen/2], ...
                        [0 1],'LineStyle','--','Color',cRed,'LineWidth',0.8);
                    for ixexp = 1:length(xexp)
                        ix  = find(tasktable.Len{idxtask}==xexp(ixexp));  % actual #session of isess
                        ixv = (ix-1)*(prglen+gaplen)+[0.5,prglen+0.5,prglen+0.5,0.5];
                        ox  = find(tasktable.Len{idxtask}==oexp(1));
                        oxv = (ox-1)*(prglen+gaplen)+[0.5,prglen+0.5,prglen+0.5,0.5];
                        if ixexp == 1
                            bgfill1 = fill(ixv,[0,0,1,1],cExp(1,:),'EdgeColor','none','FaceAlpha',0.07);
                            bgfill2 = fill(oxv,[0,0,1,1],cExp(2,:),'EdgeColor','none','FaceAlpha',0.00);
                        else
                            fill(ixv,[0,0,1,1],cExp(1,:),'EdgeColor','none','FaceAlpha',0.07);
                        end
                    end
                end
                xlim([0, length(tasktable.Len{idxtask})*(prglen+gaplen)-1]);
                if plotlegend % add legend if needed
                    if exist("bgfill1")
                        legendOut = legend([lr{1,1};lr{2,1};bgfill1;bgfill2], ...
                            {grpName{1};grpName{2};expName{idxfill};expName{3-idxfill}},'Fontsize',fontLablSz);
                    else
                        legendOut = legend([lr{1};lr{2}],{grpName{1};grpName{2}},'Fontsize',fontLablSz);
                    end
                    legendOut.ItemTokenSize = [12,22]; legend('boxoff');
                    set(gca, 'XTick', xTick, 'XTickLabel', tasktable.Len{idxtask});
                else
                    set(gca, 'XTick', xTick, 'xTickLabel', {});
                end
            end

            %% Function to plot statistics for SBS data (by FP)
            function legendOut = plot3FPstat(sbsdata, statstr, varargin)

                taskname   = getVararginValue(varargin, "taskName",   "string");
                tasktable  = getVararginValue(varargin, "taskTable",  "table");
                plotlegend = getVararginValue(varargin, "plotLegend", "logical");
                idxfill    = getVararginValue(varargin, "idxFill",    "double");
                whichfp    = getVararginValue(varargin, "whichFP",    "double");

                idxtask = tasktable.Task == taskname;
                sbsdata = sbsdata(sbsdata.Task == taskname & ...
                    ismember(sbsdata.Session, tasktable.Len{idxtask}), :);
                sessnum = length(tasktable.Len{idxtask});
                switch taskname
                    case {"Wait1", "Wait2"}
                        xdata(1,:) = tasktable.Len{idxtask}';
                        meanstat   = "mean_" + string(statstr);
                        semstat    = "sem_"  + string(statstr);
                    case "3FPs"
                        xdata(1,:) = tasktable.Len{idxtask}';
                        if ~isempty(whichfp)  % plot 1 of 3FPs
                            xdata(xdata<0) = xdata(xdata<0) + 1;
                        else
                            xdata(2,:) = xdata(1,:) + sessnum;
                            xdata(3,:) = xdata(2,:) + sessnum;
                        end
                        meanstat   = "mean_" + string(statstr) + "_FP";
                        semstat    = "sem_"  + string(statstr) + "_FP";
                end

                for ifp = 1:height(xdata)
                    for igrp = 1:length(grpName)
                        if ~isempty(whichfp)  % just plot 1 of 3 FPs data
                            ydata = sbsdata.(meanstat)(sbsdata.Group==grpName{igrp},whichfp)';
                            semdata = sbsdata.(semstat)(sbsdata.Group==grpName{igrp},whichfp)'; 
                        else
                            ydata = sbsdata.(meanstat)(sbsdata.Group==grpName{igrp},ifp)';
                            semdata = sbsdata.(semstat)(sbsdata.Group==grpName{igrp},ifp)'; 
                        end

                        if ifp==1
                            lr{igrp} = plot(xdata(ifp,:),ydata,'o-', 'linewidth', 1.5, 'color', cGrp(igrp,:), ...
                                'markerfacecolor', cGrp(igrp,:), 'markeredgecolor','w', 'markersize', 2);
                        else
                            plot(xdata(ifp,:),ydata,'o-', 'linewidth', 1.5, 'color', cGrp(igrp,:), ...
                                'markerfacecolor', cGrp(igrp,:), 'markeredgecolor','w', 'markersize', 2);
                        end
                        line([xdata(ifp,:); xdata(ifp,:)], [ydata-semdata;ydata+semdata],'color',cGrp(igrp,:), 'linewidth', 1);
                        if ifp > 1
                            line([xdata(ifp,1)-0.5 xdata(ifp,1)-0.5],[0 1],'linestyle',':','linewidth',1,'color','k');
                        end
                    end
                end

                if ~isempty(idxfill)
                    plot([0.5,0.5],[0,1],'LineStyle','--','Color',cRed,'LineWidth',0.8);
                    xexp = sbsdata.Session(sbsdata.Experiment==expName{idxfill}); % this exp x values
                    ox = sbsdata.Session(sbsdata.Experiment~=expName{idxfill});   % other exp x values
                    for ixexp = 1:length(xexp)
                        ix = xexp(ixexp);
                        if ix < 0
                            ix = ix + 1;
                        end
                        if ixexp == 1
                            bgfill1 = fill([ix-0.5,ix+0.5,ix+0.5,ix-0.5],[0,0,1,1],cExp(1,:), ...
                                'EdgeColor','none','FaceAlpha',0.07);
                            bgfill2 = fill([ox(1)-0.5,ox(1)+0.5,ox(1)+0.5,ox(1)-0.5],[0,0,1,1],cExp(2,:), ...
                                'EdgeColor','none','FaceAlpha',0.00);
                        else
                            fill([ix-0.5,ix+0.5,ix+0.5,ix-0.5],[0,0,1,1],cExp(1,:), ...
                            'EdgeColor','none','FaceAlpha',0.07);
                        end
                    end
                end
                xlim([xdata(1,1)-0.5, xdata(end,end)+0.5]);
                
                if plotlegend % add legend if needed
                    if ~isempty(idxfill)
                        legendOut = legend([lr{1};lr{2};bgfill1;bgfill2], ...
                            {grpName{1};grpName{2};expName{idxfill};expName{3-idxfill}},'Fontsize',fontLablSz,'FontName','Arial');
                    else
                        legendOut = legend([lr{1};lr{2}],{grpName{1};grpName{2}},'Fontsize',fontLablSz,'FontName','Arial');
                    end
                    legendOut.ItemTokenSize = [12,22]; legend('boxoff');
                end

            end
        end

    end
end

function value = getProp(x,prop,mis)
    arguments
        x
        prop
        mis = [] % [], missing
    end
    
    if ~isempty(x) && isprop(x,prop)
        value = x.(prop);
    else
        value = mis;
    end
end
