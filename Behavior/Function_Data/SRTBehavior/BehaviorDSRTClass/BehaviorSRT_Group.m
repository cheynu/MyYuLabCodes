classdef BehaviorSRT_Group
    % Revised by hbWang, Nov/2023
    % Based on BehaviorDSRT_Indiv & BehaviorDSRT
    % Data format containing multiple subjects' data
    % METHODS:
    % STAT = obj.stat
      % STAT
        % .TBT      1 row: raw data of 1 trial. Trial-By-Trial, similar in the followings (Session/Experiment)
        % .SBS      1 row: stat of 1 Subject * Session
        % .SBSgrp   1 row: stat of 1 Group * Session, calculated by SBS, Grand-Average
        % .SBSebe   1 row: stat of 1 Subject * (Group) * Experiment, calculated by SBS, Grand-Average of each day's stat
        % .EBE      1 row: stat of 1 Subject * (Group) * Experiment, calculated by TBT
        % .EBEgrp   1 row: stat of 1 Group * Experiment, calculated by EBE, Grand-Average
        % such as EBE/EBEgrp suggest to table2struct for previewing variables/fields
    % obj.save(savepath); Save the obj as .mat file & .csv file
        % default path is pwd
    % obj.plot

    properties
        IndivAll        cell
        Protocol  (1,1) string {mustBeText}
    end

    properties (Dependent)
        Subjects  (:,1) string {mustBeText}
        Groups    (:,1) string {mustBeText}
        nSession  (:,1) double {mustBeNumeric}
        DataAll         cell
        Sessions        double {mustBeNumeric}
        Dates           double {mustBeNumeric}
        Tasks           cell   {mustBeText}
        Experiments     string {mustBeText}
        nTrial          double
        TableAll        cell
        StatOut
    end

    properties (Dependent, GetAccess = private)
        SaveName
    end

    properties (GetAccess = private)
        pStat
    end

    properties (Constant, GetAccess = private)
        DefaultMixedFP = [0.5,1.0,1.5]
        ProgressLength = [150,50]  % (1) - trial/session; (2) - trial/FP
    end
    
    methods
        function obj = BehaviorSRT_Group(behavSRTIndiv,protocol)
            arguments
                behavSRTIndiv (:,1) cell
                protocol            string {mustBeText} = ""
            end
            obj.Protocol = protocol;
            dataAll = behavSRTIndiv(cellfun(@(x) isa(x,'BehaviorSRT_Indiv'),behavSRTIndiv,'UniformOutput',true));
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
            % value = string(value);
            for i = 1:length(obj.Subjects)
                obj.IndivAll{i}.Group = value(i);
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
                value = [value;obj.IndivAll{i}.TBT];
            end
            STAT.TBT = value;
            % SBS
            value = table;
            for i=1:length(obj.Subjects)
                value = [value;obj.IndivAll{i}.SBS];
            end
            prgLen = round(obj.ProgressLength(1)/value.progressStep(1));
            prgLenFP = round(obj.ProgressLength(2)/value.progressStep(1));
            
            STAT.SBS = value;
            STAT.SBS = removevars(STAT.SBS, {'progressPerf', 'progressRT', ...
                'progressFP', 'progressWin', 'progressStep', 'progressTime'});
            STAT.SBS = addProgressData(STAT.SBS, value.progressPerf, {'Cor','Pre','Late'}, prgLen);
            STAT.SBS = addProgressData(STAT.SBS, value.progressRT, {'Cor','CorLate'}, prgLen, {'RTC', 'RTCL'});
            STAT.SBS = addProgressData(STAT.SBS, value.progressFP, {'All'}, prgLen, {'FP'});
            for iFP = 1:length(obj.DefaultMixedFP)
                STAT.SBS = removevars(STAT.SBS, cellstr("progressPerf_FP"+string(iFP)));
                STAT.SBS = removevars(STAT.SBS, cellstr("progressRT_FP"+string(iFP)));
                STAT.SBS = removevars(STAT.SBS, cellstr("progressTime_FP"+string(iFP)));
                STAT.SBS = addProgressData(STAT.SBS, value.("progressPerf_FP"+string(iFP)), {'Cor','Pre','Late'}, ...
                    prgLenFP, cellstr(["Cor_FP"+string(iFP),"Pre_FP"+string(iFP),"Late_FP"+string(iFP)]));
                STAT.SBS = addProgressData(STAT.SBS, value.("progressRT_FP"+string(iFP)), {'Cor','CorLate'}, ...
                    prgLenFP, cellstr(["RTC_FP"+string(iFP),"RTCL_FP"+string(iFP)]));
            end

            % EBE
            value = table;
            for i=1:length(obj.Subjects)
                value = [value;obj.IndivAll{i}.EBE];
            end
            
            % % SBSgrp
            % SBSerase = removevars(STAT.SBS,{'Subject','Experiment','Date'});
            % value = grpstats(SBSerase,{'Group','Session','Task'},{'mean','sem'});
            % STAT.SBSgrp = value;
            % % SBSebe
            % SBSerase = removevars(STAT.SBS,{'Subject','Date'});
            % value = grpstats(SBSerase,{'Session','Group','Experiment','Task'},{'mean','sem'});
            % STAT.SBSebe = value;

            % STAT.EBE = value;
            % %EBEgrp
            % EBEerase = removevars(STAT.EBE,{'Subject'});
            % value = grpstats(EBEerase,{'Group','Experiment','Task'},{'mean','sem'});
            % STAT.EBEgrp = value;

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

        function out = getTBTdata(obj, var, idx, options)
            arguments
                obj
                % Var: variable name in TBT, e.g. "HT", "RT"
                var                 (1,1) string {mustBeText}
                % idx: index of trial (reTrial) to sample, e.g. [-1000 1000]
                idx                 (1,2) double              = [1 1000]
                % Specific Task and FP to sample
                options.Task        (1,1) string {mustBeText} = "3FPs"
                options.FP                double              = []
                options.varstr            string              = ""
                % Varname to show in out.VariableName
                options.Varname     (1,1) string {mustBeText} = var
                options.calStat     (1,1) string ...
                    {mustBeMember(options.calStat, ["", "Group"])} = ""
                options.calDelta          logical             = false
                % calSmooth: calculate smoothed data or not (using @calSlidWin)
                options.calSmooth         logical             = true
                options.SmoothWin   (1,1) double              = 50
                options.SmoothStep  (1,1) double              = 10
            end
            if isempty(obj.StatOut)
                obj = obj.stat();
            end
            tbt = obj.StatOut.TBT;
            allsubj = unique(tbt.Subject, 'stable');

            % here we get tbt for all subjects within "Task" and "idx"
            tbt = tbt(tbt.Task == string(options.Task),:);
            if ~isempty(options.FP)
                tbt = tbt(tbt.FP == options.FP,:);
            end
            tbt = tbt(tbt.reTrial >= idx(1) & tbt.reTrial <= idx(2),:);
            
            % tbl store all subjects' tbt.var, based on their reTrial
            %  (compared with tblidx, if trial num is less than idx, a NaN left)
            tblidx = idx(1):1:idx(2);
            tblidx(tblidx == 0) = [];
            tbl = nan(length(tblidx), length(allsubj));
            session = tbl;
            subjname = []; group = [];
            for i = 1:length(allsubj)
                itbt = tbt(tbt.Subject == allsubj(i),:);
                idx_subj = ismember(tblidx, itbt.reTrial);
                if options.varstr == ""
                    tbl(idx_subj, i) = itbt.(var);
                else
                    tbl(idx_subj, i) = itbt.(var) == options.varstr;
                end
                session(idx_subj, i) = itbt.Session;
                subjname = [subjname itbt.Subject(1)];
                group = [group itbt.Group(1)];
            end

            % Smooth data using @calSlidWin
            if options.calSmooth
                idx_pre  = tblidx(tblidx<0); tbl_pre  = tbl(tblidx<0,:); 
                idx_post = tblidx(tblidx>0); tbl_post = tbl(tblidx>0,:); 
                tbl_pre_smoothed  = []; idx_pre_smoothed  = [];
                tbl_post_smoothed = []; idx_post_smoothed = [];
                if ~isempty(tbl_pre)
                    [idx_pre_smoothed, tbl_pre_smoothed] = calSlidWin(idx_pre, tbl_pre, ...
                        "Direction", "Reverse", "AvgMethod", "Mean", "Method", "Fixed", ...
                        "SmoothWin", options.SmoothWin, "SmoothStep", options.SmoothStep);
                end
                if ~isempty(tbl_post)
                    [idx_post_smoothed, tbl_post_smoothed] = calSlidWin(idx_post, tbl_post, ...
                        "Direction", "Norm", "AvgMethod", "Mean", "Method", "Fixed", ...
                        "SmoothWin", options.SmoothWin, "SmoothStep", options.SmoothStep);
                end
                out.DataSmoothed = [tbl_pre_smoothed; tbl_post_smoothed];
                out.idxSmoothed  = [idx_pre_smoothed; idx_post_smoothed];
            end

            if options.calDelta
                idxBaseline = tblidx < 0;
                idxBaselineSmoothed = out.idxSmoothed < 0;
                if any(idxBaseline)
                    for i = 1:length(allsubj)
                        tbl(:,i) = tbl(:,i) - mean(tbl(idxBaseline,i), "omitnan");
                        out.DataSmoothed(:,i) = out.DataSmoothed(:,i) - mean(out.DataSmoothed(idxBaselineSmoothed,i), "omitnan");
                    end
                else
                    disp("Baseline sessions needed for delta mode."); return;
                end
            end

            allgroup = unique(group);
            if options.calStat~=""  % && length(allgroup) > 1
                for igrp = 1:length(allgroup)
                    tblgrp.(allgroup(igrp)) = tbl(:,group==allgroup(igrp));
                    tblgrp.(allgroup(igrp)+"Smoothed") = out.DataSmoothed(:,group==allgroup(igrp));
                    tblgrp_mean.(allgroup(igrp)) = mean(tblgrp.(allgroup(igrp)), 2, 'omitnan');
                    tblgrp_mean.(allgroup(igrp)+"Smoothed") = mean(tblgrp.(allgroup(igrp)+"Smoothed"), 2, 'omitnan');
%                     var_bootstrap = bootstrp(1000, @(x) mean(x, 'omitnan'), sbsgrp_var.(allgroup(igrp))');
%                     var_ci95.(allgroup(igrp)) = prctile(var_bootstrap, [0.025, 0.975]);
                    tblgrp_ci95.(allgroup(igrp)) = bootci(1000, @(x) mean(x, 'omitnan'), tblgrp.(allgroup(igrp))');
                    tblgrp_ci95.(allgroup(igrp)+"Smoothed") = bootci(1000, @(x) mean(x, 'omitnan'), tblgrp.(allgroup(igrp)+"Smoothed")');
                    sem_temp = std(tblgrp.(allgroup(igrp)), 0, 2, 'omitnan')/sqrt(size(tblgrp.(allgroup(igrp)),2));
                    tblgrp_sem.(allgroup(igrp))(1,:) = tblgrp_mean.(allgroup(igrp)) - sem_temp;
                    tblgrp_sem.(allgroup(igrp))(2,:) = tblgrp_mean.(allgroup(igrp)) + sem_temp;
                    sem_temp = std(tblgrp.(allgroup(igrp)+"Smoothed"), 0, 2, 'omitnan')/sqrt(size(tblgrp.(allgroup(igrp)+"Smoothed"),2));
                    tblgrp_sem.(allgroup(igrp)+"Smoothed")(1,:) = tblgrp_mean.(allgroup(igrp)+"Smoothed") - sem_temp;
                    tblgrp_sem.(allgroup(igrp)+"Smoothed")(2,:) = tblgrp_mean.(allgroup(igrp)+"Smoothed") + sem_temp;
                end
                out.DataByGroup = tblgrp;
                out.mean = tblgrp_mean;
                out.sem = tblgrp_sem;
                out.ci95 = tblgrp_ci95;
                switch options.calStat
                    case "Group"
                        logicgroup = zeros(length(group),1);
                        logicgroup(group==allgroup(1)) = 1;
                        [anova,rm] = simple_mixed_anova(tbl',logicgroup,{'Trials'},{'Group'});
                        out.stat_group.rmANOVA = anova;
                        out.stat_group.multicompare = multcompare(rm, 'Group', 'by', 'Trials');
                    % case "Experiment"
                    %     t = addvars(array2table(tbl'), group', 'NewVariableNames', "Group");
                    %     within = table(experiment, sessions', 'VariableNames', {'Experiment', 'Session'});
                    %     m = "Var1-Var"+num2str(length(sessions))+"~Group";
                    %     rm = fitrm(t, m, 'WithinDesign', within);
                    %     out.stat_exp.rmANOVA = ranova(rm, 'WithinModel', 'Experiment+Session');
                    %     out.stat_exp.multicompare = multcompare(rm, 'Session', 'by', 'Group');
                end
            end

            % Reshape and store data
            out.DataAll = tbl;
            out.Session = session;
            out.Index = reshape(tblidx, [], 1);
            out.Subject = reshape(subjname, 1, []);
            out.Group = reshape(group, 1, []);
            out.VariableName = options.Varname;
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

                options.Task        (1,1) string {mustBeText} = "3FPs"
                % Task(protocol) to extract (Wait1, Wait2, 3FPs)

                options.Varname     (1,1) string {mustBeText} = var
                % save name of this variable in out.VariableName
                % e.g, obj.getSBSdata("Cor_FP", 'Varcol', 1, 'Task', "3FPs", ...
                %                  'Sessions', 1:8, 'Varname', "Correct3FP_S")
                %   example codes above: get 1~8 Sessions Correct ratio of short FP trials,
                %     and set out.VariableName = Correct3FP_S

                options.Sessions    (1,:) double              = []
                % what session to extract (e.g, [-3,-2,-1, 1,2,3])
                % default = [], extract all sessions (trim to min sessions of max subjects)
                options.addLast                               = 0
                % 1: add last session of each subject

                options.calStat     (1,1) string              = "Group"
                % calculate mean/sem/ci95 and rmANOVA by "Group" or "Experiment"
                % set to "" if don't need this
                options.calDelta                              = 0

                % trial number to sample from each session, mode: "fixed" -
                % first xx trials or "random" - randomly chosen
                options.Samples                               = []
                options.Mode                                  = "random"
                % critical value type of rmANOVA multcomparison
                options.multMethod                            = "bonferroni"
            end

            sbs = obj.StatOut.SBS;
            allsubj = unique(sbs.Subject, 'stable');
            % update sbs by specific task
            sbs = sbs(sbs.Task == string(options.Task),:);
            if ~isempty(options.Sessions)
                sessions = options.Sessions;
            else
                % no session input: default - use first x sessions that all
                % subjects enrolled
                it = tabulate(sbs.Session);
                sessions = find(it(:, 2) == max(it(:, 2)));
            end

            sessions = repmat(sessions, [length(allsubj) 1]);
            % if add last session's data
            if options.addLast
                lastSession = zeros(length(allsubj), 1);
                for isubj = 1:length(allsubj)
                    isess = cell2mat(obj.Sessions(isubj, :));
                    itask = string(obj.Tasks(isubj, :));
                    isess = isess(itask == string(options.Task));
                    lastSession(isubj) = isess(end);
                end
                sessions = [sessions lastSession];
            end
            
            if ~isempty(options.Samples)
                sbs = [];
                tbt = obj.StatOut.TBT;
                tbt = tbt(tbt.Task == string(options.Task),:);
                for isubj = 1:length(allsubj)
                    tbt_subj = tbt(tbt.Subject==allsubj(isubj),:);  % tbt for one subj
                    randidx = []; % random index of all sessions for one subj
                    for isess = 1:length(sessions)
                        idxsess = find(tbt_subj.Session==sessions(isess));  % tbt of one subj in one day
                        switch options.Mode
                            case "random"
                                % randomly choose SampleSize of trials 
                                randidx = randi([idxsess(1) idxsess(end)],1,options.Samples);
                            case "fixed"
                                % choose the first SampleSize of trials
                                if length(idxsess)>=options.Samples
                                    randidx = idxsess(1:options.Samples);
                                else % if nTrials < samplesize, use randi
                                    randidx = randi([idxsess(1) idxsess(end)],1,options.Samples);
                                end
                        end
                        isbs = calIndivStat(tbt_subj(randidx,:),false,'ifDistr',true,'calRT95CI',false);
                        sbs = [sbs;isbs];
                    end
                end
            end

            % update sbs by sessions
            sbs_var = []; group = []; subjname = [];
            for isubj = 1:length(allsubj)
                isbs = sbs(sbs.Subject == allsubj(isubj),:);
                isbs = isbs(ismember(isbs.Session, sessions(isubj,:)),:);

                isbs_var = isbs.(var);
                % For 3FPs statistics, choose specific column of data
                if options.Varcol ~= 0
                    isbs_var = isbs_var(:,options.Varcol);
                end
                if sessions(isubj,end-1) == sessions(isubj,end)
                    isbs_var = [isbs_var;isbs_var(end,:)];
                end
                isbs_var = reshape(isbs_var',[],1); % reshape data to 1 col
                sbs_var = [sbs_var isbs_var]; %#ok<*AGROW>
                group = [group string(isbs.Group(1))];
                subjname = [subjname string(isbs.Subject(1))];
                if isubj == 1
                    experiment = isbs.Experiment;
                    allexp = unique(experiment, 'stable');
                    logicexp = zeros(length(experiment),1);
                    logicexp(experiment==allexp(1)) = 1;
                end
            end

            if options.calDelta
                idxBaseline = sessions < 0;
                for i = 1:length(allsubj)
                    if any(idxBaseline(i,:))
                        sbs_var(:,i) = sbs_var(:,i) - mean(sbs_var(idxBaseline(i,:),i),'omitnan');
                        sbs_var_delta(:,i) = sbs_var(~idxBaseline(i,:),i);
                    else
                        disp("Baseline sessions needed for delta mode."); return;
                    end
                end
            end

            allgroup = unique(group);
            if options.calStat~="" %&& length(allgroup) > 1
                for igrp = 1:length(allgroup)
                    sbsgrp_var.(allgroup(igrp)) = sbs_var(:,group==allgroup(igrp));
                    var_mean.(allgroup(igrp)) = mean(sbsgrp_var.(allgroup(igrp)), 2, 'omitnan');
%                     var_bootstrap = bootstrp(1000, @(x) mean(x, 'omitnan'), sbsgrp_var.(allgroup(igrp))');
%                     var_ci95.(allgroup(igrp)) = prctile(var_bootstrap, [0.025, 0.975]);
                    var_ci95.(allgroup(igrp)) = bootci(1000, @(x) mean(x, 'omitnan'), sbsgrp_var.(allgroup(igrp))');
                    sem_temp = std(sbsgrp_var.(allgroup(igrp)), 0, 2, 'omitnan')/sqrt(size(sbsgrp_var.(allgroup(igrp)),2));
                    var_sem.(allgroup(igrp))(1,:) = var_mean.(allgroup(igrp)) - sem_temp;
                    var_sem.(allgroup(igrp))(2,:) = var_mean.(allgroup(igrp)) + sem_temp;
                    var_median.(allgroup(igrp)) = median(sbsgrp_var.(allgroup(igrp)), 2, 'omitnan');
                    iqr_temp = abs(diff(quantile(reshape(sbsgrp_var.(allgroup(igrp)),[],1), [0.25 0.75])));
                    var_iqr.(allgroup(igrp))(1,:) = var_median.(allgroup(igrp)) - iqr_temp/2;
                    var_iqr.(allgroup(igrp))(2,:) = var_median.(allgroup(igrp)) + iqr_temp/2;
                end
            end

            % if options.Varname ~= ""
            %     Varname = options.Varname;
            % else
            %     Varname = var;
            % end

            if options.calStat ~= ""
                out.mean = var_mean;
                out.ci95 = var_ci95;
                out.sem = var_sem;
                out.median = var_median;
                out.iqr = var_iqr;
                out.DataByGroup = sbsgrp_var;

                sess_anova = sessions;
                sess_anova(:,end) = repmat(options.Sessions(end), [length(allsubj) 1]);
                if length(allgroup) > 1
                    switch options.calStat
                        case "Group"
                            logicgroup = zeros(length(group),1);
                            logicgroup(group==allgroup(1)) = 1;
                            [tbl,rm] = simple_mixed_anova(sbs_var',logicgroup,{'Sessions'},{'Group'});
                            out.stat_group.rmANOVA = tbl;
                            out.stat_group.multicompare = multcompare(rm, 'Group', 'by', 'Sessions');
                            if options.calDelta
                                [tbl,rm] = simple_mixed_anova(sbs_var_delta',logicgroup,{'Sessions'},{'Group'});
                                out.stat_group_delta.rmANOVA = tbl;
                                out.stat_group_delta.multicompare = multcompare(rm, 'Group', 'by', 'Sessions');
                            end
                        case "Experiment"
                            t = addvars(array2table(sbs_var'), group', 'NewVariableNames', "Group");
                            within = table(experiment, sess_anova', 'VariableNames', {'Experiment', 'Session'});
                            m = "Var1-Var"+num2str(length(sessions))+"~Group";
                            rm = fitrm(t, m, 'WithinDesign', within);
                            out.stat_exp.rmANOVA = ranova(rm, 'WithinModel', 'Experiment+Session');
                            out.stat_exp.multicompare = multcompare(rm, 'Session', 'by', 'Group');
                    end
                end
            end
            out.DataAll = sbs_var;
            out.Session = sessions;
            out.Experiment = experiment;
            out.Group = group;
            out.Subject = subjname;
            out.VariableName = options.Varname;
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
                options.Task     string = "3FPs"   % task of target sessions
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
                for iexp=1:length(allexp)
                    data = rand_tbt_subj(rand_tbt_subj.Experiment==allexp{iexp},:);
                    stat = calIndivStatSRT(data,true,'ifDistr',true,'calRT95CI',false);
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

        function out = calPrematureCDF(obj, options)
            arguments
                obj
                options.tbin = 0.01
                options.tmin = 0.1
            end

            out = cellfun(@(x) calPreCDF(x, options), obj.DataAll, "UniformOutput", false);

            function out = calPreCDF(in, options)
                if ~isempty(in)
                    out = in.calPrematureCDF("tbin", options.tbin, "tmin", options.tmin);
                else
                    out = [];
                end
            end
        end

        function value = get.SaveName(obj)
            if obj.Protocol == ""
                value = "BClassGroup_" + string(datetime('now','Format','yyyyMMdd'));
            else
                value = "BClassGroup_" + obj.Protocol;
            end
        end

        function obj = reNumberTrials(obj, eachFP, indicator, switchStr)
            arguments
                obj
                eachFP           = false
                indicator string {mustBeMember(indicator, ["Task", "Experiment"])} = "Task"
                switchStr string = []
            end
            obj.IndivAll = cellfun(@(x) x.reNumberTrials(eachFP, indicator, switchStr), obj.IndivAll, "UniformOutput", false);
            obj = obj.stat(false);
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
                expcmp1 = allIndicators == switchStr(1);
                expcmp2 = allIndicators == switchStr(2);
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

        function obj = changeExpName(obj, oldExp, newExp)
            if length(oldExp) ~= length(newExp)
                error('Check inputs length: old ~ new groups');
            end
            expAll = obj.Experiments;
            expNew = replace(expAll, oldExp, newExp);
            obj.Experiments = expNew;
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

            options.Figure.Renderer = "Painters";

            [~,~] = mkdir(options.savePath);
            savename = fullfile(options.savePath, options.saveName);
            print(options.Figure, '-dpng', savename);
            print(options.Figure, '-depsc2', savename);
            saveas(options.Figure, savename, 'fig');
            print(options.Figure,'-dpdf',savename, '-fillpage');
        end

        function Fig = plot(obj,options)
            arguments
                obj
                options.plotType  string {mustBeMember(options.plotType,...
                    ["Learning","Comparison","GrammLearning",...
                    "Recovery","RecoveryV2","RecoveryV3","Inter"])} = "Learning"
                options.taskName  string  = ""
                options.expName   string  = []
                options.grpName   string  = []
                options.shadedExp string  = "DCZ"
                options.htLim     double  = [0 3]
                options.rtLim     double  = [0 1.5]
                options.perfLim   double  = [0 1]
                options.txtTitle  string  = ""
                options.switchStr string  = ["Pre", "Post"]

                % Parameters of saving figure
                options.save      logical = true
                options.saveName  string  = obj.SaveName
                options.savePath  string  = fullfile(pwd, "Fig")

                % Parameters of recovery plot
                options.kernel_bw double  = 0.15 % kernal binwidth for ksdensity
                options.trialNum  double  = [100 100 100] % trial number of trial-based HT analysis
                options.trialNum2 double  = 20
                options.smplExps  string  = ["Pre", "Post", "Post"]
                options.smplMark  double  = [1 2 3] % pre; post; recovery marks
                options.smplMarkS string  = ["Pre-lesion", "Post-early", "Post-late"]
                options.plotPDFci logical = false % plot pdf curve with ci rather than plot heatmap
            end
            expName = options.expName; grpName = options.grpName; taskName = options.taskName;
            shadedExp = options.shadedExp; switchStr = options.switchStr;
            txtTitle = options.txtTitle; kernel_bw = options.kernel_bw;

            trialNum = options.trialNum; trialNum2 = options.trialNum2;
            sampleExps = options.smplExps;
            sampleMarks = options.smplMark; SampleMarkStrs = options.smplMarkS;
            plotPDFci = options.plotPDFci;
            % Parameters
            set(groot,'defaultAxesFontName','Dejavu Sans');
            fontSize = struct("Axes", 7, "Label", 7, "Title", 9, "Info", 10);
            tickLen = [0.0200 0.0250]; tickLen2 = tickLen/3; tLim = [0 3000];           

            yLim.HT = options.htLim;
            yTick.HT = yLim.HT(1):0.5:yLim.HT(2);
            yTickLabel.HT = num2str(yTick.HT' * 1000);

            yLim.RT = options.rtLim;
            yTick.RT = yLim.RT(1):0.5:yLim.RT(2);
            yTickLabel.RT = num2str(yTick.RT' * 1000);
            yTick.RT2 = yLim.RT(1):0.2:yLim.RT(2);
            yTickLabel.RT2 = num2str(yTick.RT2' * 1000);

            yLim.Perf = options.perfLim;
            yTick.Perf = yLim.Perf(1):0.5:yLim.Perf(2);
            yTickLabel.Perf = num2str(yTick.Perf' * 100);
            yTick.Perf2 = yLim.Perf(1):0.2:yLim.Perf(2);
            yTickLabel.Perf2 = num2str(yTick.Perf2' * 100);

            xLim.HT = options.htLim;
            xTick.HT = xLim.HT(1):1:xLim.HT(2);
            xTickLabel.HT = num2str(xTick.HT' * 1000);

            xLim.RT = options.rtLim;
            xTick.RT = xLim.RT(1):1:xLim.RT(2);
            xTickLabel.RT = num2str(xTick.RT' * 1000);
            xTick.RT2 = xLim.RT(1):0.2:xLim.RT(2);
            xTickLabel.RT2 = num2str(xTick.RT2' * 1000);


            cTab10 = tab10(10); cAccent = Accent(8); cDarkGrey = cAccent(end,:);
            cBlue = cTab10(1,:); cOrange = cTab10(2,:); cGreen = cTab10(3,:);
            cRed  = cTab10(4,:); cGrey = cTab10(8,:);

            c = struct("Perf", [cGreen;cRed;cGrey], "MixedFPs", [cGrey;mean([cOrange;cGrey]);cOrange], ...
                       "MixedFPsJY", ["#9BBEC8", "#427D9D", "#164863"], ...
                       "MixedStagesJY", ["k", "#ff6c22", "#662d91"], ...
                       "Exp", [cOrange;cDarkGrey], "CustomLine", [cBlue;cRed], ... % for early-late pdf comp
                       "SwitchLine", cRed, ...
                       "Scatter", ["flat", "none"], "Shade", cOrange, "GapLine", cGrey, "FPLine", 'k', ... % Raster plot
                       "Whisker", cRed, "Violin", cGrey, "ViolinEdge", cDarkGrey, "ViolinBox", cBlue, ...
                       "htColorMap", customcolormap([0 1], [cRed;cBlue]), ...
                       "Samples", [cBlue;cRed;cGreen], "Unsampled", cBlue);
            alpha = struct("Shade", 0.1, "Violin", 0.2, "Scatter", 0.5, "MixedFPs", [0.5 0.6 0.7]);
            psize = struct("Marker", [4 6 8], "Scatter", [25 30 35], "ScatterLine", [0.5 0.5 0.5], ...
                           "CustomLine", [1.5 1.5 1.5], "GapLine", 0.5, "FPLine", 1, "MixedFPs", [1 1.4 1.8], ...
                           "Arrow", [2 3 35], "RecoveryV2", 5);  % arrow parameters [linewidth length tipangle]
            style = struct("MarkerStyleFP", ["o", "^", "square"], "LineStyleFP", ["-", ":", "-."], ...
                           "MarkerStyleRec", ["o", "^", "diamond"]);

            switch options.plotType
                case "Learning"
                    Fig = plotLearning(obj);
                case "LearningByTrial"
                    Fig = plotLearningByTrial(obj);
                case "CompExp"
                    Fig = plotExpComp(obj);
                case "cmpexpbysession"
                    Fig = cmpExpPlotBySession(obj);
                case "Progress"
                    Fig = progressPlot(obj);
                case "Recovery"
                    Fig = plotRecoveryV1(obj); % Heatmap summary
                case "RecoveryV2"
                    Fig = plotRecoveryV2(obj); % Raster for each subj
                case "RecoveryV3"
                    Fig = plotRecoveryV3(obj); % PDF for each subj
                case "Inter"
                    Fig = plotInterSummary(obj);
            end

            %% Summary of intermittent experiment
            function Fig = plotInterSummary(obj)
                % In this plot method, there will be three stages:
                % 1 - first x trials in saline session
                % 2 - first y trials in dcz session
                % 3 - y+1~y+z trials in dcz session
                % sample size is defined in options.trialNum, recommend: [50 50 50]

                nSubj = length(obj.Subjects);
                nStage = 4;
                allFPs = obj.DefaultMixedFP;
                nFP = length(allFPs);
                RT = zeros(nStage, nFP, nSubj);
                RT_sd = RT; HT = cell(nStage, nFP, nSubj);
                PreRatio = RT; PreRatio2 = zeros(nStage, 2, nSubj);
                for k = 1:nSubj
                    kobj = obj.IndivAll{k};
                    ktbt = kobj.TBT;

                    idxTask = kobj.Tasks == "3FPs";
                    idxPost = find(kobj.Experiments == expName(2) & idxTask);
                    idxPre  = find(diff(kobj.Experiments == expName(1) & idxTask) == -1);
                    idxPre  = intersect(idxPre, find(idxTask)-1);
                    idxPost = intersect(idxPost, idxPre+1);
                    datePre  = kobj.Dates(idxPre);
                    datePost = kobj.Dates(idxPost);
                    tNumAll = length(datePre)*trialNum2;

                    for j = 1:nFP
                        jktbtPre  = ktbt(ismember(ktbt.Date, datePre)  & ktbt.FP == allFPs(j),:);
                        jktbtPost = ktbt(ismember(ktbt.Date, datePost) & ktbt.FP == allFPs(j),:);
                        reltPre1 = []; reltPre2 = []; htPre1 = []; htPre2 = [];
                        reltPost1 = []; reltPost2 = []; htPost1 = []; htPost2 = [];
                        for i = 1:length(datePre)
                            ijktbtPre  = jktbtPre(jktbtPre.Date == datePre(i),:);
                            ijktbtPost = jktbtPost(jktbtPost.Date == datePost(i),:);
                            ijktbtPre  = sortrows(ijktbtPre, "iTrial");
                            ijktbtPost = sortrows(ijktbtPost, "iTrial");

                            % saline
                            ntPre = height(ijktbtPre);
                            if ntPre > trialNum2
                                relttemp = ijktbtPre.RelT(1:trialNum2);
                                httemp   = ijktbtPre.HT(1:trialNum2);
                                reltPre1 = [reltPre1; relttemp(~isnan(relttemp))];
                                htPre1   = [htPre1; httemp(~isnan(httemp))];
                                if ntPre > 2*trialNum2
                                    relttemp  = ijktbtPre.RelT((1:trialNum2)+trialNum2);
                                else
                                    relttemp  = ijktbtPre.RelT((ntPre-trialNum2+1):ntPre);
                                end
                                reltPre2 = [reltPre2; relttemp(~isnan(relttemp))];
                                htPre2   = [htPre2; httemp(~isnan(httemp))];
                            else
                                relttemp = ijktbtPre.RelT;
                                reltPre1 = [reltPre1; relttemp(~isnan(relttemp))];
                                reltPre2 = [reltPre2; relttemp(~isnan(relttemp))];
                                httemp   = ijktbtPre.HT;
                                htPre1   = [htPre1; httemp(~isnan(httemp))];
                                htPre2   = [htPre2; httemp(~isnan(httemp))];
                            end

                            % dcz
                            ntPost = height(ijktbtPost);
                            if ntPost > trialNum2
                                relttemp  = ijktbtPost.RelT(1:trialNum2);
                                httemp   = ijktbtPost.HT(1:trialNum2);
                                reltPost1 = [reltPost1; relttemp(~isnan(relttemp))];
                                htPost1   = [htPost1; httemp(~isnan(httemp))];
                                if ntPost > 2*trialNum2
                                    relttemp  = ijktbtPost.RelT((1:trialNum2)+trialNum2);
                                else
                                    relttemp  = ijktbtPost.RelT((ntPost-trialNum2+1):ntPost);
                                end
                                reltPost2 = [reltPost2; relttemp(~isnan(relttemp))];
                                htPost2   = [htPost2; httemp(~isnan(httemp))];
                            else
                                relttemp  = ijktbtPost.RelT;
                                reltPost1 = [reltPost1; relttemp(~isnan(relttemp))];
                                reltPost2 = [reltPost2; relttemp(~isnan(relttemp))];
                                httemp   = ijktbtPost.HT;
                                htPost1   = [htPost1; httemp(~isnan(httemp))];
                                htPost2   = [htPost2; httemp(~isnan(httemp))];
                            end
                        end
                        jkRTPre1 = calRT(reltPre1, [], ...
                            "Remove100ms", 1, "RemoveOutliers", 1, "ToPlot", 0, "CalSE", 1);
                        RT(1,j,k) = jkRTPre1.median(1);
                        RT_sd(1,j,k) = jkRTPre1.median(2);
                        % PreRatio(1,j,k) = 1-(length(reltPre1)/tNumAll);

                        jkRTPre2 = calRT(reltPre2, [], ...
                            "Remove100ms", 1, "RemoveOutliers", 1, "ToPlot", 0, "CalSE", 1);
                        RT(3,j,k) = jkRTPre2.median(1);
                        RT_sd(3,j,k) = jkRTPre2.median(2);
                        % PreRatio(3,j,k) = 1-(length(reltPre2)/tNumAll);

                        jkRTPost1 = calRT(reltPost1, [], ...
                            "Remove100ms", 1, "RemoveOutliers", 1, "ToPlot", 0, "CalSE", 1);
                        RT(2,j,k) = jkRTPost1.median(1);
                        RT_sd(2,j,k) = jkRTPost1.median(2);
                        % PreRatio(2,j,k) = 1-(length(reltPost1)/tNumAll);

                        jkRTPost2 = calRT(reltPost2, [], ...
                            "Remove100ms", 1, "RemoveOutliers", 1, "ToPlot", 0, "CalSE", 1);
                        RT(4,j,k) = jkRTPost2.median(1);
                        RT_sd(4,j,k) = jkRTPost2.median(2);
                        % PreRatio(4,j,k) = 1-(length(reltPost2)/tNumAll);

                        HT{1,j,k} = htPre1; HT{2,j,k} = htPost1;
                        HT{3,j,k} = htPre2; HT{4,j,k} = htPost2;
                    end
                    for i = 1:nStage
                        PreRatio2(i,1,k) = sum(HT{i,1,k}<0.5)/tNumAll;
                        temp = cell2mat(HT(i,2:end,k));
                        PreRatio2(i,2,k) = 0.5*sum(reshape(temp,[],1)<1)/tNumAll;
                    end
                end


                xstart = 1.5; ystart = 1.2; xgap = 1.3; ygap = 1;
                axeSize1 = [4.5 3];
                % axeSize2 = [(axeSize1(1)*2-xgap)/3 (axeSize1(1)*2-xgap)/3];
                axeSize2 = [axeSize1(2) axeSize1(2)];

                xmap = [xstart, ...
                        xstart + xgap*1 + axeSize1(1), ...
                        xstart + xgap*2 + axeSize1(1)*2, ...
                        xstart + xgap*3 + axeSize1(1)*2 + axeSize2(1)];
                axeSizeInfo = [xmap(end)-xmap(1) 0.01];

                ymap = [ystart, ...
                        ystart + ygap*1 + axeSize1(2)*1, ...
                        ystart + ygap*2 + axeSize1(2)*2, ...
                        ystart + ygap*3 + axeSize1(2)*3, ...
                        ystart + ygap*3.5 + axeSize1(2)*3 + axeSizeInfo(2)];

                Fig = figure(1); clf(Fig, "reset");
                set(Fig, "Unit", "centimeters", "PaperPositionMode", "auto", ...
                    "Position", [2 2 xmap(end) ymap(end)], "Color", "w");

                maxRT = max(RT, [], "all");
                maxRT = ceil(maxRT*10)/10;
                maxRT_sd = max(RT_sd, [], "all");
                if maxRT_sd > 1
                    maxRT_sd = ceil(maxRT_sd*10)/10;
                else
                    maxRT_sd = ceil(maxRT_sd*100)/100;
                end

                maxPre = max(PreRatio2, [], "all");
                maxPre = ceil(maxPre*10)/10;

                ha11 = axes;
                set(ha11, "Units", "centimeters", "Position", [xmap(1) ymap(3) axeSize1], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                    "XLim", [0.5 9.5], "XTick", [2 5 8], "XTickLabel", string(allFPs*1000), ...
                    "YLim", [0 maxRT], "YTick", yTick.RT2, "YTickLabel", yTickLabel.RT2, ...
                    "FontSize", fontSize.Axes, "FontName", "Dejavu Sans");
                ylabel("RT median (ms)", "FontSize", fontSize.Label, "FontName", "Dejavu Sans");
                for j = 1:nFP
                    jRT = RT([1 2],j,:);
                    meanjRT = mean(jRT, 3);
                    b.("RT"+num2str(j)) = bar([1.5 2.5]+(j-1)*nFP, meanjRT, 0.8);
                    set(b.("RT"+num2str(j)), "FaceColor", c.MixedFPsJY(j), "FaceAlpha", 0.8, ...
                        "EdgeColor", "none");
                    for k = 1:nSubj
                        plot([1.5 2.5]+(j-1)*nFP, RT([1 2],j,k), ".-", "Color", "k");
                    end
                end

                ha11b = axes;
                set(ha11b, "Units", "centimeters", "Position", [xmap(2) ymap(3) axeSize1], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                    "XLim", [0.5 9.5], "XTick", [2 5 8], "XTickLabel", string(allFPs*1000), ...
                    "YLim", [0 maxRT], "YTick", yTick.RT2, "YTickLabel", {}, ...
                    "FontSize", fontSize.Axes, "FontName", "Dejavu Sans");
                for j = 1:nFP
                    jRT = RT([3 4],j,:);
                    meanjRT = mean(jRT, 3);
                    b.("RT"+num2str(j)) = bar([1.5 2.5]+(j-1)*nFP, meanjRT, 0.8);
                    set(b.("RT"+num2str(j)), "FaceColor", c.MixedFPsJY(j), "FaceAlpha", 0.8, ...
                        "EdgeColor", "none");
                    for k = 1:nSubj
                        plot([1.5 2.5]+(j-1)*nFP, RT([3 4],j,k), ".-", "Color", "k");
                    end
                end

                ha12 = axes;
                set(ha12, "Units", "centimeters", "Position", [xmap(1) ymap(2) axeSize1], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                    "XLim", [0.5 9.5], "XTick", [2 5 8], "XTickLabel", string(allFPs*1000), ...
                    "YLim", [0 maxRT_sd], "YTick", 0:0.02:maxRT_sd, "YTickLabel", string((0:0.02:maxRT_sd)*1000), ...
                    "FontSize", fontSize.Axes, "FontName", "Dejavu Sans");
                ylabel("RT std (ms)", "FontSize", fontSize.Label, "FontName", "Dejavu Sans");
                for j = 1:nFP
                    jRT_sd = RT_sd([1 2],j,:);
                    meanjRT_sd = mean(jRT_sd, 3);
                    b.("RT_sd"+num2str(j)) = bar([1.5 2.5]+(j-1)*nFP, meanjRT_sd, 0.8);
                    set(b.("RT_sd"+num2str(j)), "FaceColor", c.MixedFPsJY(j), "FaceAlpha", 0.8, ...
                        "EdgeColor", "none");
                    for k = 1:nSubj
                        plot([1.5 2.5]+(j-1)*nFP, RT_sd([1 2],j,k), ".-", "Color", "k");
                    end
                end

                ha12b = axes;
                set(ha12b, "Units", "centimeters", "Position", [xmap(2) ymap(2) axeSize1], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                    "XLim", [0.5 9.5], "XTick", [2 5 8], "XTickLabel", string(allFPs*1000), ...
                    "YLim", [0 maxRT_sd], "YTick", 0:0.02:maxRT_sd, "YTickLabel", {}, ...
                    "FontSize", fontSize.Axes, "FontName", "Dejavu Sans");
                for j = 1:nFP
                    jRT_sd = RT_sd([3 4],j,:);
                    meanjRT_sd = mean(jRT_sd, 3);
                    b.("RT_sd"+num2str(j)) = bar([1.5 2.5]+(j-1)*nFP, meanjRT_sd, 0.8);
                    set(b.("RT_sd"+num2str(j)), "FaceColor", c.MixedFPsJY(j), "FaceAlpha", 0.8, ...
                        "EdgeColor", "none");
                    for k = 1:nSubj
                        plot([1.5 2.5]+(j-1)*nFP, RT_sd([3 4],j,k), ".-", "Color", "k");
                    end
                end


                ha13 = axes;
                set(ha13, "Units", "centimeters", "Position", [xmap(1) ymap(1) axeSize2], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                    "XLim", [0.5 6.5], "XTick", [2 5], "XTickLabel", ["500", "1000"], ...
                    "YLim", [0 maxPre], "YTick", yTick.Perf2, "YTickLabel", yTickLabel.Perf2, ...
                    "FontSize", fontSize.Axes, "FontName", "Dejavu Sans");
                ylabel("Premature (%)", "FontSize", fontSize.Label, "FontName", "Dejavu Sans");
                for j = 1:2
                    jPre = PreRatio2([1 2],j,:);
                    meanjPre = mean(jPre, 3);
                    b.("Pre"+num2str(j)) = bar([1.5 2.5]+(j-1)*3, meanjPre, 0.8);
                    set(b.("Pre"+num2str(j)), "FaceColor", c.MixedFPsJY(j), "FaceAlpha", 0.8, ...
                        "EdgeColor", "none");
                    for k = 1:nSubj
                        plot([1.5 2.5]+(j-1)*3, PreRatio2([1 2],j,k), ".-", "Color", "k");
                    end
                end

                ha13b = axes;
                set(ha13b, "Units", "centimeters", "Position", [xmap(2) ymap(1) axeSize2], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                    "XLim", [0.5 6.5], "XTick", [2 5], "XTickLabel", ["500", "1000"], ...
                    "YLim", [0 maxPre], "YTick", yTick.Perf2, "YTickLabel", yTickLabel.Perf2, ...
                    "FontSize", fontSize.Axes, "FontName", "Dejavu Sans");
                ylabel("Premature (%)", "FontSize", fontSize.Label, "FontName", "Dejavu Sans");
                for j = 1:2
                    jPre = PreRatio2([3 4],j,:);
                    meanjPre = mean(jPre, 3);
                    b.("Pre"+num2str(j)) = bar([1.5 2.5]+(j-1)*3, meanjPre, 0.8);
                    set(b.("Pre"+num2str(j)), "FaceColor", c.MixedFPsJY(j), "FaceAlpha", 0.8, ...
                        "EdgeColor", "none");
                    for k = 1:nSubj
                        plot([1.5 2.5]+(j-1)*3, PreRatio2([3 4],j,k), ".-", "Color", "k");
                    end
                end

                for i = 1:nFP
                    h.("a"+num2str(i)) = axes;
                    set(h.("a"+num2str(i)), "Units", "centimeters", "Position", [xmap(3) ymap(i) axeSize2], ...
                        "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                        "XLim", [0 maxRT], "XTick", yTick.RT2, "XTickLabel", {}, "XTickLabelRotation", 0, ...
                        "YLim", [0 maxRT], "YTick", yTick.RT2, "YTickLabel", yTickLabel.RT2, ...
                        "FontSize", fontSize.Axes, "FontName", "Dejavu Sans");
                    ylabel("Saline: RT (ms)", "FontSize", fontSize.Label, "FontName", "Dejavu Sans");
                    title(string(allFPs(i)*1000)+" ms", ...
                        "Fontsize",fontSize.Title,"FontName","Dejavu Sans");
    
                    scatter(reshape(RT(1,i,:), [], 1), reshape(RT(2,i,:), [], 1), ...
                        psize.Scatter(3), "fill", "MarkerFaceColor", c.MixedFPsJY(j), "MarkerFaceAlpha", 0.6);
                    line([0 3], [0 3], "Color", "k", "LineStyle", "-.", "LineWidth", 1);

                    if i == 1
                        xlabel("DCZ: RT (ms)", "FontSize", fontSize.Label, "FontName", "Dejavu Sans")
                        set(h.("a"+num2str(i)), "XTickLabel", yTickLabel.RT2);
                    end
                end

                % Title
                ha00 = axes;
                set(ha00, "Units", "centimeters", "Position", [xstart/2 ymap(4)-ygap/2 axeSizeInfo]);
                axis off;
                title("3FPs RT comparison: Saline & DCZ"+txtTitle, ...
                    "FontSize", fontSize.Title, "FontName", "Dejavu Sans", "FontWeight", "bold");
            end

            %% Recovery of pre-exp / early post-exp and late post-exp
            function Fig = plotRecoveryV1(obj)

                nSubj = length(obj.Subjects);
                opt = obj.IndivAll{1}.Options;
                allFPs = obj.DefaultMixedFP;

                tbt = cell(1,nSubj);
                pdf = cell(length(allFPs), length(sampleMarks));
                pdf_ci = pdf;
                effect = zeros(1,nSubj);

                for i = 1:nSubj
                    iobj = obj.IndivAll{i};
                    isbs = iobj.SBS;
                    % Get tbt with sampled trials marked
                    itbt = iobj.sampleTrials("trialNum", trialNum, "smplMark", sampleMarks, "exp", sampleExps);
                    % itbt = itbt(itbt.TimeElapsed<tLim(2) & itbt.TimeElapsed>tLim(1), :);
                    tbt{i} = itbt;

                    for j = 1:length(sampleMarks)
                        for k = 1:length(allFPs)
                            idxSampled = itbt.Sampled == sampleMarks(j) & itbt.FP == allFPs(k);
                            [ipdf, xi] = ksdensity(itbt.HT(idxSampled), opt.Edges_HT, 'Bandwidth', 0.15);
                            pdf{j,k} = [pdf{j,k}; ipdf];
                            if plotPDFci
                                [ipdf_ci] = ksdensity_ci(itbt.HT(idxSampled), opt.Edges_HT, 0.15, 1000);
                                pdf_ci{j,k} = [pdf_ci{j,k}; ipdf_ci];
                            end
                        end
                    end

                    % Get experiment effect size using pre-post correct
                    % ratio under long FP trials
                    cor_longfp_pre = isbs.Cor_FP(find(isbs.Experiment == expName(1), 1, "last"), 3);
                    cor_longfp_post = isbs.Cor_FP(find(isbs.Experiment == expName(2), 1, "first"), 3);
                    effect(i) = cor_longfp_post - cor_longfp_pre;
                end

                [~, idxSort] = sort(effect, 2, "ascend");
                pdf_sorted = cellfun(@(x) x(idxSort,:), pdf, "UniformOutput", false);

                xstart = 1.5; ystart = 2; xgap = 0.5; ygap = 0.6;
                axeSize1 = [6 4]; axeSizeInfo = [axeSize1(1)*3+xgap*2 0.01];

                xmap = [xstart, ...
                        xstart + xgap*1 + axeSize1(1), ...
                        xstart + xgap*2 + axeSize1(1)*2, ...
                        xstart + xgap*3 + axeSize1(1)*3];
                ymap = [ystart, ...
                        ystart + ygap*1 + axeSize1(2), ...
                        ystart + ygap*2 + axeSize1(2)*2, ...
                        ystart + ygap*3 + axeSize1(2)*3];
                ymap = fliplr(ymap);

                Fig = figure(1); clf(Fig, "reset");
                set(Fig, "Unit", "centimeters", "PaperPositionMode", "auto", ...
                    "Position", [2 2 xmap(end) ymap(1)+ygap*2], "Color", "w");

                for j = 1:length(sampleMarks)
                    for k = 1:length(allFPs)
                        kFP = allFPs(k);
                        h.("a"+num2str(j)+num2str(k)) = axes;
                        set(h.("a"+num2str(j)+num2str(k)), "Units", "centimeters", "Position", [xmap(j) ymap(k+1) axeSize1], ...
                            "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                            "XLim", [0.5 nSubj+2.5], "XTick", 1:nSubj, "XTickLabel", {}, ...
                            "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", {}, ...
                            "FontSize", fontSize.Axes, "FontName", "Dejavu Sans");
                        if j == 1 % each row, same stage
                            ylabel("FP "+num2str(kFP*1000)+"ms", ...
                                "FontSize", fontSize.Label, "FontName", "Dejavu Sans");                            
                            set(h.("a"+num2str(j)+num2str(k)), "YTickLabel", yTickLabel.HT);
                        end
                        if k == length(sampleMarks)
                            set(h.("a"+num2str(j)+num2str(k)), "XTickLabel", obj.Subjects(idxSort));
                            xlabel("Subject name", "FontSize", fontSize.Label, "FontName", "Dejavu Sans");
                        end
                        if k == 1 % each column, same FP
                            title(SampleMarkStrs(j), "Color", c.Samples(j,:), ...
                                "FontSize", fontSize.Title, "FontName", "Dejavu Sans", "FontWeight", "bold");
                        end

                        if plotPDFci
                            for i = 1:nSubj
                                plotshaded_y(pdf_ci{j,k}([2*i-1 2*i],:)+i, xi, c.Samples(j,:));
                                plot(pdf{j,k}(i,:)+i, xi, ...
                                    'color', c.Samples(j,:), 'linewidth', 1.5, 'linestyle', '-');
                            end
                        else
                            set(h.("a"+num2str(j)+num2str(k)), "XLim", [0.5 nSubj+0.5]);
                            imagesc(1:nSubj, xi, pdf_sorted{j,k}');
                        end
                        plot([0.5 nSubj+2.5], [kFP kFP], "Color", c.FPLine, "LineStyle", "-.", "LineWidth", psize.FPLine)
                    end
                end

                % Title
                ha00 = axes;
                set(ha00, "Units", "centimeters", "Position", [xmap(1) ymap(1) axeSizeInfo]);
                axis off;
                title("Recovery: pre vs. post-early & post-late"+txtTitle, ...
                    "FontSize", fontSize.Title, "FontName", "Dejavu Sans", "FontWeight", "bold");
            end

            % Raster plot of recovery stages
            function Fig = plotRecoveryV2(obj)

                nSubj = length(obj.Subjects); nStage = length(trialNum);
             
                effect = zeros(1,nSubj);
                for j = 1:nSubj
                    isbs = obj.IndivAll{j}.SBS;
                    % Get experiment effect size using pre-post correct ratio under long FP trials
                    cor_longfp_pre = isbs.Cor_FP(find(isbs.Experiment == expName(1), 1, "last"), 3);
                    cor_longfp_post = isbs.Cor_FP(find(isbs.Experiment == expName(2), 1, "first"), 3);
                    effect(j) = cor_longfp_post - cor_longfp_pre;
                end
                [~, idxSort] = sort(effect, 2, "ascend");
                allSubj = obj.Subjects(idxSort);

                if nSubj < 5
                    ncol = nSubj; nrow = 1;
                elseif nSubj <= 10
                    ncol = 5; nrow = ceil(nSubj/5);
                else
                    ncol = 8; nrow = ceil(nSubj/8);
                end

                xstart = 1.5; ystart = 1.2; xgap = 0.5; ygap = 0.5;
                axeSize = [3.5 2.5];

                xmap(1) = xstart; ymap(1) = ystart;
                for k = 1:ncol
                    xmap(k+1) = xmap(k) + xgap + axeSize(1);
                end
                xmap(end+1) = xmap(end) + 2;

                for k = 1:nrow
                    ymap(3*k-1) = ymap(3*k-2) + ygap + axeSize(2);
                    ymap(3*k+0) = ymap(3*k-1) + ygap + axeSize(2);
                    ymap(3*k+1) = ymap(3*k+0) + ygap*2 + axeSize(2);
                end
                ymap = fliplr(ymap);

                Fig = figure(1); clf(Fig, "reset");
                set(Fig, "Unit", "centimeters", "PaperPositionMode", "auto", ...
                    "Position", [2 2 xmap(end) ymap(1)+0.7], "Color", "w");

                for i = 1:nSubj
                    idx = obj.Subjects == allSubj(i);
                    iobj = obj.IndivAll{idx}; nFP = length(iobj.MixedFP);
                    itbt = iobj.sampleTrials("trialNum", trialNum, "smplMark", sampleMarks, "exp", sampleExps);
                    % itbt = itbt(itbt.TimeElapsed<tLim(2) & itbt.TimeElapsed>tLim(1), :);

                    irow = ceil(i/ncol); icol = mod(i,ncol); if icol == 0; icol = ncol; end

                    %% ha11/12/13 holdtime raster for all sessions
                    for j = 1:nStage
                        jtbt = itbt(itbt.Sampled == sampleMarks(j),:);

                        h.("a"+num2str(i)+num2str(j)) = axes;
                        set(h.("a"+num2str(i)+num2str(j)), "Units", "centimeters", "Position", [xmap(icol) ymap(irow*3+j-2) axeSize], ...
                            "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                            "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, ...
                            "YLim", [0 trialNum2*nFP], "YTick", {}, "YTickLabel", {}, ...
                            "FontSize", fontSize.Axes, "FontName", "Dejavu Sans");
                        axis off;
                        for k = 1:nFP
                            kFP = iobj.MixedFP(k);
                            ktbt = jtbt(jtbt.FP == kFP,:);
                            idxRand = randperm(length(ktbt.Sampled), trialNum2);
                            yrange = trialNum2*[k-1 k];
                            fills.("f"+num2str(j)+num2str(k)) = fill([0 kFP kFP 0], ...
                                [yrange(1) yrange(1) yrange(2) yrange(2)], 'k');
                            set(fills.("f"+num2str(j)+num2str(k)), "FaceColor", c.MixedFPsJY(k), "FaceAlpha", 0.5, "EdgeColor", "none");
                            scatter(ktbt.HT(idxRand), (yrange(1)+1):yrange(2), ...
                                psize.RecoveryV2, "MarkerFaceColor", c.MixedFPsJY(k), "MarkerEdgeColor", c.MixedFPsJY(k));
                        end
                        if j == 1
                            text(iobj.MixedFP(2), trialNum2*(nFP+0.5), ...
                                iobj.Subject, "HorizontalAlignment", "center", ...
                                "FontSize", fontSize.Title, "FontName", "Dejavu Sans", "FontWeight", "bold");
                        end
                        % add "ylabel" for first column
                        if icol == 1
                            text(-0.5, trialNum2*nFP/2, SampleMarkStrs(j), ...
                                "Rotation", 90, "HorizontalAlignment", "center", ...
                                "FontSize", fontSize.Label, "FontName", "Dejavu Sans", "FontWeight", "bold");
                        end
                    end

                    % add legend and notes
                    if irow == 1 && icol == ncol
                        le = legend([fills.f13; fills.f12; fills.f11], ["1500 ms"; "1000 ms"; "  500 ms"], ... % string(flip(obj.MixedFP)*1000)+" ms"
                            "NumColumns", 1, "Box", "off", ...
                            "Units", "centimeters", "Position", [xmap(icol+1) ymap(2)+axeSize(2)*4/5 1 1], ...
                            "FontSize", fontSize.Label, "FontName", "Dejavu Sans", "FontWeight", "bold");
                        le.ItemTokenSize = [18,24];
                        le.Position(1) = le.Position(1);
                        % le.Position(2) = le.Position(2) - 0.45;
                        text(xLim.HT(2), trialNum2*nFP/2, ...
                            ["Sample size";"for each FP"; string(trialNum2)+" / "+string(trialNum(2))], ...
                            "HorizontalAlignment", "left", ...
                            "FontSize", fontSize.Label, "FontName", "Dejavu Sans", "FontWeight", "bold");
                    end
                end
                % ha00, add title text
                ha00 = axes;
                set(ha00, "Units", "centimeters", "Position", [xmap(1) ymap(1)-0.4 xmap(end)-xmap(1) 0.1]);
                axis off;
                title(txtTitle+"Press duration raster", "FontSize", fontSize.Title, "FontName", "Dejavu Sans", "FontWeight", "bold");
            end

            % PDF plot of recovery stages
            function Fig = plotRecoveryV3(obj)

                nSubj = length(obj.Subjects); nStage = length(trialNum);
                opt = obj.IndivAll{1}.Options;
                allFPs = obj.DefaultMixedFP; nFP = length(allFPs);

                tbt = cell(1,nSubj);
                pdf = cell(nFP, nStage, nSubj);
                pdf_ci = pdf; cnt = pdf;
                effect = zeros(1,nSubj);
                for k = 1:nSubj
                    iobj = obj.IndivAll{k};
                    isbs = iobj.SBS;
                    % Get tbt with sampled trials marked
                    itbt = iobj.sampleTrials("trialNum", trialNum, "smplMark", sampleMarks, "exp", sampleExps);
                    % itbt = itbt(itbt.TimeElapsed<tLim(2) & itbt.TimeElapsed>tLim(1), :);
                    tbt{k} = itbt;

                    for j = 1:length(sampleMarks)
                        for i = 1:length(allFPs)
                            idxSampled = itbt.Sampled == sampleMarks(j) & itbt.FP == allFPs(i);
                            iHT = itbt.HT(idxSampled);
                            [ipdf, xi] = ksdensity(iHT, opt.Edges_HT, 'Bandwidth', kernel_bw);
                            pdf{j,i,k} = ipdf;
                            if plotPDFci
                                [ipdf_ci] = ksdensity_ci(itbt.HT(idxSampled), opt.Edges_HT, kernel_bw, 1000);
                                pdf_ci{j,i,k} = ipdf_ci;
                            end
                            grp1 = sum(iHT<allFPs(i));
                            grp2 = sum(iHT>=allFPs(i) & iHT<=(allFPs(i)+0.6));
                            grp3 = sum(iHT>(allFPs(i)+0.6));
                            cnt{j,i,k} = [grp1 grp2 grp3];
                        end
                    end

                    % Get experiment effect size using pre-post correct
                    % ratio under long FP trials
                    % hbWang Jan 20224, for in-consecutive injections
                    idxExp1 = find(diff(isbs.Experiment == expName(1)) ~= 0, 1, "first");
                    cor_longfp_pre = isbs.Cor(idxExp1);
                    cor_longfp_post = isbs.Cor(find(isbs.Experiment == expName(2), 1, "first"));
                    effect(k) = cor_longfp_post - cor_longfp_pre;
                end
                [~, idxSort] = sort(effect, 2, "ascend");
                allSubj = obj.Subjects(idxSort);
                % pdf = pdf(:,:,idxSort);
                % pdf_ci = pdf_ci(:,:,idxSort);

                maxpdf = max(cellfun(@(x) max(x,[],"all"), pdf_ci, "UniformOutput", true),[],"all");

                if nSubj < 5
                    ncol = nSubj; nrow = 1;
                elseif nSubj <= 10
                    ncol = 5; nrow = ceil(nSubj/5);
                else
                    ncol = 8; nrow = ceil(nSubj/8);
                end

                xstart = 1.5; ystart = 1.2; xgap = 0.5; ygap = 0.5;
                axeSize = [3.5 2.5];

                xmap(1) = xstart; ymap(1) = ystart;
                for k = 1:ncol
                    xmap(k+1) = xmap(k) + xgap + axeSize(1);
                end
                xmap(end+1) = xmap(end) + 2.5;

                for k = 1:nrow
                    ymap(3*k-1) = ymap(3*k-2) + ygap + axeSize(2);
                    ymap(3*k+0) = ymap(3*k-1) + ygap + axeSize(2);
                    ymap(3*k+1) = ymap(3*k+0) + ygap*2 + axeSize(2);
                end
                ymap = fliplr(ymap);

                Fig = figure(1); clf(Fig, "reset");
                set(Fig, "Unit", "centimeters", "PaperPositionMode", "auto", ...
                    "Position", [2 2 xmap(end) ymap(1)+0.7], "Color", "w");

                for i = 1:nSubj
                    idx = obj.Subjects == allSubj(i);
                    irow = ceil(i/ncol); icol = mod(i,ncol); if icol == 0; icol = ncol; end
                    ipdf = pdf(:,:,idx); ipdf_ci = pdf_ci(:,:,idx); % row: stage; col:FP
                    icnt = cnt(:,:,idx);
                    %% ha11/12/13 holdtime raster for all sessions
                    for j = 1:nFP
                        jFP = allFPs(j);
                        h.("a"+num2str(i)+num2str(j)) = axes;
                        set(h.("a"+num2str(i)+num2str(j)), "Units", "centimeters", "Position", [xmap(icol) ymap(irow*3-j+2) axeSize], ...
                            "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                            "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", {}, ...
                            "YLim", [0 maxpdf], "YTick", yTick.HT, "YTickLabel", {}, ...
                            "FontSize", fontSize.Axes, "FontName", "Dejavu Sans");
                        fills.("f"+num2str(j)+num2str(k)) = fill([0 jFP jFP 0], [0 0 maxpdf maxpdf], 'k');
                        set(fills.("f"+num2str(j)+num2str(k)), "FaceColor", c.MixedFPsJY(j), "FaceAlpha", 0.5, "EdgeColor", "none");
                        for k = 1:nStage
                            plotshaded(xi, ipdf_ci{k,j}, c.MixedStagesJY(k));
                            linePDF.("l"+num2str(j)+num2str(k)) = plot(xi, ipdf{k,j}, ...
                                'color', c.MixedStagesJY(k), 'linewidth', 1.5, 'linestyle', '-');
                            % line([jFP jFP], xLim.HT, ...
                            %     "Color", c.FPLine, "LineStyle", "-.", "LineWidth", psize.FPLine);
                        end

                        % chi-square test, 1/2/3 ~ pre/early/late
                        cnt1 = icnt{1,j}; cnt2 = icnt{2,j}; cnt3 = icnt{3,j};
                        [p12, ~] = chi2test([cnt1;cnt2]); % early vs. pre
                        [p13, ~] = chi2test([cnt1;cnt3]); % late vs. pre

                        txt1 = "p<0.001"; txt2 = "p<0.001";
                        if p12 >= 0.001; txt1 = "p="+num2str(p12, "%.3f"); end
                        if p13 >= 0.001; txt2 = "p="+num2str(p13, "%.3f"); end
                        text(xLim.HT(2)*0.7, maxpdf*0.85, txt1, "Color", c.MixedStagesJY(2), ...
                            "FontSize", fontSize.Label, "FontName", "Dejavu Sans", "FontWeight", "bold");
                        text(xLim.HT(2)*0.7, maxpdf*0.7, txt2, "Color", c.MixedStagesJY(3), ...
                            "FontSize", fontSize.Label, "FontName", "Dejavu Sans", "FontWeight", "bold");

                        if j == nFP
                            jtitle = title(allSubj(i), "FontSize", fontSize.Title, "FontName", "Dejavu Sans", "FontWeight", "bold");
                            temp = char(allSubj(i));
                            if temp(end) == '2'
                                set(jtitle, "EdgeColor", "k");
                            end
                        end
                        % add "ylabel" for first column
                        if icol == 1 && irow == nrow
                            set(h.("a"+num2str(i)+num2str(j)), "YTickLabel", string(0:0.5:maxpdf));
                            ylabel(string(allFPs(j)*1000)+" ms", ...
                                "FontSize", fontSize.Label, "FontName", "Dejavu Sans", "FontWeight", "bold");
                            if j == 1
                                set(h.("a"+num2str(i)+num2str(j)), "xTickLabel", xTickLabel.HT);
                                xlabel("Press duration (ms)", ...
                                    "FontSize", fontSize.Label, "FontName", "Dejavu Sans", "FontWeight", "normal");
                            end
                        end
                    end

                    % add legend and notes
                    if irow == 1 && icol == ncol
                        le = legend([linePDF.l11; linePDF.l12; linePDF.l13], SampleMarkStrs, ...
                            "NumColumns", 1, "Box", "off", ...
                            "Units", "centimeters", "Position", [xmap(icol+1)+0.3 ymap(2)+axeSize(2)*4/5 1 1], ...
                            "FontSize", fontSize.Label, "FontName", "Dejavu Sans", "FontWeight", "bold");
                        le.ItemTokenSize = [18,24];
                        le.Position(1) = le.Position(1);
                    end
                end
                % ha00, add title text
                ha00 = axes;
                set(ha00, "Units", "centimeters", "Position", [xmap(1) ymap(1)-0.5 xmap(end)-xmap(1) 0.1]);
                axis off;
                title(txtTitle+"Press duration PDF", "FontSize", fontSize.Title, "FontName", "Dejavu Sans", "FontWeight", "bold");
            end

            %% Learning curve of all SRT stages
            function h = plotLearning(obj)
                SBS = obj.StatOut.SBS;
                SBSgrp = obj.StatOut.SBSgrp;

                % calculate and trim to the minimal sessions
                taskStruct = struct;
                taskStruct.Task = taskName;
                taskSBS = cell(length(taskName), 1);
                for i = 1:length(taskName)
                    taskSBS{i} = SBS(SBS.Task == taskName{i}, :);
                    if ~isempty(taskSBS{i})
                        it = tabulate(taskSBS{i}.Session);
                        taskStruct.Len{i,1} = find(it(:, 2) == max(it(:, 2)));
                    else
                        taskStruct.Len{i,1} = {};
                    end
                end
                taskTable = struct2table(taskStruct);
                taskTable = taskTable(cellfun(@(x) ~isempty(x), taskTable.Len), :);

                h = figure(2); clf(h, 'reset');
                set(h, 'name', 'Learning', 'units', 'centimeters', 'position', [1 1 18.5 15]);
                size1 = [3,3*0.7];
                size2 = [9,3*0.7];

                ys = [1 3.6 6.2 8.8 11.4]; % yStart
                ys = fliplr(ys);
                xs = [1.3 4.5 7.7 10.9]; % xStart

                corLim = figParam.corLim; preLim = figParam.preLim; lateLim = figParam.lateLim;
                rtLim  = figParam.rtLim;  rtiqrLim = figParam.rtiqrLim;

                % PLOT x:session, y:Correct Wait1, color: Group(hM4D/EGFP)
                ha11 = axes;
                set(ha11, 'units', 'centimeters', 'position', [xs(1) ys(1) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',fontAxesSz,'fontname','Arial','ylim',corLim,'ticklength', [0.02 0.025]);
                le = plot3FPstat(SBSgrp,"Cor",'taskTable',taskTable,'taskName',"Wait1",'plotLegend',true);
                set(gca,'xtick',1:10,'ytick',0:0.2:1,'yticklabel',cellstr(string((0:0.2:1).*100))); %grid on;
                set(le,'units','centimeters','Position',[xs(3)+size2(1)+0.3,ys(1)+size2(2)/1.8,1,1])
                % xlabel('Sessions','Fontsize',8,'FontName','Arial');
                ylabel('Correct (%)','Fontsize',fontLablSz,'FontName','Arial');
                title("Wait1",'Fontsize',fontTitlSz,'FontName','Arial');

                % PLOT x:session, y:Correct Wait2, color: Group(hM4D/EGFP)
                ha12 = axes;
                set(ha12, 'units', 'centimeters', 'position', [xs(2) ys(1) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',fontAxesSz,'fontname','Arial','ylim',corLim,'ticklength', [0.02 0.025]);
                ha12.YAxis.Visible = 'off';
                plot3FPstat(SBSgrp,"Cor",'taskTable',taskTable,'taskName',"Wait2");
                set(gca,'xtick',1:10); %grid on;
                title("Wait2",'Fontsize',fontTitlSz,'FontName','Arial');
                
                % PLOT x:session, y:Correct 3FPs, color: Group(hM4D/EGFP)
                ha13 = axes;
                set(ha13, 'units', 'centimeters', 'position', [xs(3) ys(1) size2], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',fontAxesSz,'fontname','Arial','ylim',corLim,'ticklength', [0.02 0.025]);
                ha13.YAxis.Visible = 'off';
                plot3FPstat(SBSgrp,"Cor",'taskTable',taskTable,'taskName',"3FPs");
                title("ShortFP   /   MidFP   /   LongFP",'Fontsize',fontTitlSz,'FontName','Arial');
                
                % PLOT x:session, y:Premature Wait1, color: Group(hM4D/EGFP)
                ha21 = axes;
                set(ha21, 'units', 'centimeters', 'position', [xs(1) ys(2) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',fontAxesSz,'fontname','Arial','ylim',preLim,'ticklength', [0.02 0.025]);
                plot3FPstat(SBSgrp,"Pre",'taskTable',taskTable,'taskName',"Wait1");
                set(gca,'xtick',1:10,'ytick',0:0.2:1,'yticklabel',cellstr(string((0:0.2:1).*100))); %grid on;
                ylabel('Premature (%)','Fontsize',fontLablSz,'FontName','Arial');

                % PLOT x:session, y:Premature Wait2, color: Group(hM4D/EGFP)
                ha22 = axes;
                set(ha22, 'units', 'centimeters', 'position', [xs(2) ys(2) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',fontAxesSz,'fontname','Arial','ylim',preLim,'ticklength', [0.02 0.025]);
                ha22.YAxis.Visible = 'off';
                plot3FPstat(SBSgrp,"Pre",'taskTable',taskTable,'taskName',"Wait2");
                set(gca,'xtick',1:10); %grid on;

                % PLOT x:session, y:Premature 3FPs, color: Group(hM4D/EGFP)
                ha23 = axes;
                set(ha23, 'units', 'centimeters', 'position', [xs(3) ys(2) size2], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',fontAxesSz,'fontname','Arial','ylim',preLim,'ticklength', [0.02 0.025]);
                ha23.YAxis.Visible = 'off';
                plot3FPstat(SBSgrp,"Pre",'taskTable',taskTable,'taskName',"3FPs");

                % PLOT x:session, y:Late Wait1, color: Group(hM4D/EGFP)
                ha31 = axes;
                set(ha31, 'units', 'centimeters', 'position', [xs(1) ys(3) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',fontAxesSz,'fontname','Arial','ylim',lateLim,'ticklength', [0.02 0.025]);
                plot3FPstat(SBSgrp,"Late",'taskTable',taskTable,'taskName',"Wait1");
                set(gca,'xtick',1:10,'ytick',0:0.1:1,'yticklabel',cellstr(string((0:0.1:1).*100))); %grid on;
                ylabel('Late (%)','Fontsize',fontLablSz,'FontName','Arial');

                % PLOT x:session, y:Late Wait2, color: Group(hM4D/EGFP)
                ha32 = axes;
                set(ha32, 'units', 'centimeters', 'position', [xs(2) ys(3) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',fontAxesSz,'fontname','Arial','ylim',lateLim,'ticklength', [0.02 0.025]);
                ha32.YAxis.Visible = 'off';
                plot3FPstat(SBSgrp,"Late",'taskTable',taskTable,'taskName',"Wait2");
                set(gca,'xtick',1:10); %grid on;

                % PLOT x:session, y:Late 3FPs, color: Group(hM4D/EGFP)
                ha33 = axes;
                set(ha33, 'units', 'centimeters', 'position', [xs(3) ys(3) size2], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',fontAxesSz,'fontname','Arial','ylim',lateLim,'ticklength', [0.02 0.025]);
                ha33.YAxis.Visible = 'off';
                plot3FPstat(SBSgrp,"Late",'taskTable',taskTable,'taskName',"3FPs");

                % PLOT x:session, y:RT Wait1, color: Group(hM4D/EGFP)
                ha41 = axes;
                set(ha41, 'units', 'centimeters', 'position', [xs(1) ys(4) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',fontAxesSz,'fontname','Arial','ylim',rtLim,'ticklength', [0.02 0.025]);
                plot3FPstat(SBSgrp,"RT",'taskTable',taskTable,'taskName',"Wait1");
                set(gca,'xtick',1:10,'ytick',0.1:0.2:1,'yticklabel',cellstr(string((0.1:0.2:1).*1000))); %grid on;
                ylabel('RT (ms)','Fontsize',fontLablSz,'FontName','Arial');

                % PLOT x:session, y:RT Wait2, color: Group(hM4D/EGFP)
                ha42 = axes;
                set(ha42, 'units', 'centimeters', 'position', [xs(2) ys(4) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',fontAxesSz,'fontname','Arial','ylim',rtLim,'ticklength', [0.02 0.025]);
                ha42.YAxis.Visible = 'off';
                plot3FPstat(SBSgrp,"RT",'taskTable',taskTable,'taskName',"Wait2");
                set(gca,'xtick',1:10); %grid on;

                % PLOT x:session, y:RT 3FPs, color: Group(hM4D/EGFP)
                ha43 = axes;
                set(ha43, 'units', 'centimeters', 'position', [xs(3) ys(4) size2], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',fontAxesSz,'fontname','Arial','ylim',rtLim,'ticklength', [0.02 0.025]);
                ha43.YAxis.Visible = 'off';
                plot3FPstat(SBSgrp,"RT",'taskTable',taskTable,'taskName',"3FPs");

                % PLOT x:session, y:RT Wait1, color: Group(hM4D/EGFP)
                ha51 = axes;
                set(ha51, 'units', 'centimeters', 'position', [xs(1) ys(5) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',fontAxesSz,'fontname','Arial','ylim',rtiqrLim,'ticklength', [0.02 0.025]);
                plot3FPstat(SBSgrp,"RT_IQR",'taskTable',taskTable,'taskName',"Wait1");
                set(gca,'xtick',1:10,'ytick',0.1:0.2:1,'yticklabel',cellstr(string((0.1:0.2:1).*1000))); %grid on;
                xlabel('Sessions','Fontsize',fontLablSz,'FontName','Arial');
                ylabel('RT IQR (ms)','Fontsize',fontLablSz,'FontName','Arial');

                % PLOT x:session, y:RT Wait2, color: Group(hM4D/EGFP)
                ha52 = axes;
                set(ha52, 'units', 'centimeters', 'position', [xs(2) ys(5) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',fontAxesSz,'fontname','Arial','ylim',rtiqrLim,'ticklength', [0.02 0.025]);
                ha52.YAxis.Visible = 'off';
                plot3FPstat(SBSgrp,"RT_IQR",'taskTable',taskTable,'taskName',"Wait2");
                set(gca,'xtick',1:10); %grid on;
                xlabel('Sessions','Fontsize',fontLablSz,'FontName','Arial');

                % PLOT x:session, y:RT 3FPs, color: Group(hM4D/EGFP)
                ha53 = axes;
                set(ha53, 'units', 'centimeters', 'position', [xs(3) ys(5) size2], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',fontAxesSz,'fontname','Arial','ylim',rtiqrLim,'ticklength', [0.02 0.025]);
                ha53.YAxis.Visible = 'off';
                plot3FPstat(SBSgrp,"RT_IQR",'taskTable',taskTable,'taskName',"3FPs");

                sessNum = length(taskTable.Len{taskTable.Task == "3FPs"});
                set(gca,'xtick',1:sessNum*3,'xticklabel',cellstr(string(1:sessNum)));
                xlabel('Sessions','Fontsize',fontLablSz,'FontName','Arial');
            end

            %% Comparison between two experiment conditions
            function h = plotExpComp(obj)
                
                obj = obj.reNumber(expName); % reNumber sessions by expName
                if ~isempty(sesList)
                    obj = obj.reExp(sesList, expName); % Calculate select sessions' obj & stat
                end
                STAT = obj.stat;
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

                fpList = obj.DefaultMixedFP;
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
                        15,'MarkerEdgeColor',c.Grp(1,:),'MarkerFaceColor',c.Grp(1,:),...
                        'MarkerFaceAlpha',0.5);
                    sc2 = scatter(EBE.PreTendency_FP(idxE1G2,iFP),EBE.PreTendency_FP(idxE2G2,iFP),...
                        15,'MarkerEdgeColor',c.Grp(2,:),'MarkerFaceColor',c.Grp(2,:),...
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
                        'color', c.Exp(1,:), 'markerfacecolor', c.Exp(1,:), 'markeredgecolor','w', 'markersize', 5);
                    line([fpList; fpList], [ebedata.(meanstat)(idx1,:)-ebedata.(semstat)(idx1,:); ...
                        ebedata.(meanstat)(idx1,:)+ebedata.(semstat)(idx1,:)], 'color',c.Exp(1,:), 'linewidth', 1);
                    
                    lr2 = plot(fpList, ebedata.(meanstat)(idx2,:), 'o-', 'linewidth', 1, ...
                        'color', c.Exp(2,:), 'markerfacecolor', cs.Exp(2,:), 'markeredgecolor','w', 'markersize', 5);
                    line([fpList; fpList], [ebedata.(meanstat)(idx2,:)-ebedata.(semstat)(idx2,:); ...
                        ebedata.(meanstat)(idx2,:)+ebedata.(semstat)(idx2,:)], 'color',c.Exp(2,:), 'linewidth', 1);
                
                    if plotlegend
                        legendOut = legend([lr1;lr2],{expName{1};expName{2}},'Fontsize',fontLablSz,'FontName','Arial');
                        legendOut.ItemTokenSize = [12,22]; legend('boxoff');
                    end
                end

               
%                 % ha22, grp1 exp1/2, holdtime pdf under 3FPs
%                 ha22 = axes;
%                 set(ha22, 'units', 'centimeters', 'position', [xs2(2) ys(2) axeSize], 'nextplot', 'add','tickDir', 'out',...
%                     'xlim',[xedges.edges_HT(1),xedges.edges_HT(end)],'xtick',xedges.edges_HT(1):0.5:xedges.edges_HT(end),...
%                     'xticklabel',cellstr(string((xedges.edges_HT(1):0.5:xedges.edges_HT(end)))),'fontsize',7,'fontname','Arial',...
%                     'ylim',[0 3.8],'ytick', 0:3, 'yticklabel', {'0', '1', '2', '3'}, 'ticklength', [0.02 0.025]);
%                 shadedErrorBar(xedges.HT,EBEgrp.mean_HTpdf_FP1(idxE1G1,:),EBEgrp.sem_HTpdf_FP1(idxE1G1,:),...
%                     'lineProps',{'-','lineWidth',0.5,'color',cExp(1,:)},'patchSaturation',0.2);
%                 shadedErrorBar(xedges.HT,EBEgrp.mean_HTpdf_FP2(idxE1G1,:),EBEgrp.sem_HTpdf_FP2(idxE1G1,:),...
%                     'lineProps',{'-','lineWidth',1.0,'color',cExp(1,:)},'patchSaturation',0.2);
%                 shadedErrorBar(xedges.HT,EBEgrp.mean_HTpdf_FP3(idxE1G1,:),EBEgrp.sem_HTpdf_FP3(idxE1G1,:),...
%                     'lineProps',{'-','lineWidth',1.5,'color',cExp(1,:)},'patchSaturation',0.2);
%                 
%                 shadedErrorBar(xedges.HT,EBEgrp.mean_HTpdf_FP1(idxE2G1,:),EBEgrp.sem_HTpdf_FP1(idxE2G1,:),...
%                     'lineProps',{'-','lineWidth',0.5,'color',cExp(2,:)},'patchSaturation',0.2);
%                 shadedErrorBar(xedges.HT,EBEgrp.mean_HTpdf_FP2(idxE2G1,:),EBEgrp.sem_HTpdf_FP2(idxE2G1,:),...
%                     'lineProps',{'-','lineWidth',1.0,'color',cExp(2,:)},'patchSaturation',0.2);
%                 shadedErrorBar(xedges.HT,EBEgrp.mean_HTpdf_FP3(idxE2G1,:),EBEgrp.sem_HTpdf_FP3(idxE2G1,:),...
%                     'lineProps',{'-','lineWidth',1.5,'color',cExp(2,:)},'patchSaturation',0.2);
%                 
%                 xlabel('Hold time (s)','Fontsize',fontLablSz,'FontName','Arial');
%                 ylabel('PDF (1/s)','Fontsize',fontLablSz,'FontName','Arial');
                
%                 xlm = xlim; xsep = (xlm(2)-xlm(1))./15; xtext = xlm(2)+xsep;
%                 ylm = ylim; ysep = (ylm(2)-ylm(1))./5; ytext = mean(ylm)+ysep;
%                 text(xtext,ytext,grpName{1},...
%                     'HorizontalAlignment','left','VerticalAlignment','middle','rotation',-90,...
%                     'fontsize',8,'FontName','Arial','fontweight','bold');


                % ha00, add title text
                ha00 = axes;
                set(ha00, 'units', 'centimeters', 'position', [xmap(1) ymap(1)+axeSize(2)+0.5 xmap(end)-xmap(1) 0.1]);
                axis off;
                title(titleText, 'FontSize', fontTitlSz, 'FontName', 'Arial', 'FontWeight', 'bold');

            end
            
            %% Learning curve comparison between two experiment conditions
            function h = cmpExpPlotBySession(obj)

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
                SBS = obj.StatOut.SBS;
                SBSebe = obj.StatOut.SBSebe;
    
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
            function h = progressPlot(obj)
                
                if any(contains(taskName, 'Wait')) % learning data, 1 exp & no multiFP
                    plotExp = 0; multiFP = 1;
                    titleText = "Performance & RT progress of "+cellstr(taskName);
                else  % plot learned data (withdraw or post-lesion)
                    multiFP = 3;
                    if length(expName) == 1
                        plotExp = 0;
                    else % plot all performance before/after exp changed
                        plotExp = 1;
                        obj = obj.reNumber(expName); % reNumber sessions by expName, 
                        if ~isempty(sesList)  
                            obj = obj.reExp(sesList, expName); % Select specific sessions
                        end
                        titleText = "Performance & RT progress of "+cellstr(expName{1})+" vs. "+cellstr(expName{2});
                    end
                end
                STAT   = obj.stat; 
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
                                lr{igrp,ifp} = plot(xdata,ydata,lineStyleList(ifp), 'linewidth', lineWidthList(ifp), 'color', c.Grp(igrp,:));
                            else
                                plot(xdata,ydata,lineStyleList(ifp), 'linewidth', lineWidthList(ifp), 'color', c.Grp(igrp,:));
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
                        [0 1],'LineStyle','--','Color',c.SwitchLine,'LineWidth',0.8);
                    for ixexp = 1:length(xexp)
                        ix  = find(tasktable.Len{idxtask}==xexp(ixexp));  % actual #session of isess
                        ixv = (ix-1)*(prglen+gaplen)+[0.5,prglen+0.5,prglen+0.5,0.5];
                        ox  = find(tasktable.Len{idxtask}==oexp(1));
                        oxv = (ox-1)*(prglen+gaplen)+[0.5,prglen+0.5,prglen+0.5,0.5];
                        if ixexp == 1
                            bgfill1 = fill(ixv,[0,0,1,1],c.Exp(1,:),'EdgeColor','none','FaceAlpha',0.07);
                            bgfill2 = fill(oxv,[0,0,1,1],c.Exp(2,:),'EdgeColor','none','FaceAlpha',0.00);
                        else
                            fill(ixv,[0,0,1,1],c.Exp(1,:),'EdgeColor','none','FaceAlpha',0.07);
                        end
                    end
                end
                xlim([0, length(tasktable.Len{idxtask})*(prglen+gaplen)-1]);
                if plotlegend % add legend if needed
                    if exist("bgfill1", "var")
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
                            lr{igrp} = plot(xdata(ifp,:),ydata,'o-', 'linewidth', 1.5, 'color', c.Grp(igrp,:), ...
                                'markerfacecolor', c.Grp(igrp,:), 'markeredgecolor','w', 'markersize', 2);
                        else
                            plot(xdata(ifp,:),ydata,'o-', 'linewidth', 1.5, 'color', c.Grp(igrp,:), ...
                                'markerfacecolor', c.Grp(igrp,:), 'markeredgecolor','w', 'markersize', 2);
                        end
                        line([xdata(ifp,:); xdata(ifp,:)], [ydata-semdata;ydata+semdata],'color',c.Grp(igrp,:), 'linewidth', 1);
                        if ifp > 1
                            line([xdata(ifp,1)-0.5 xdata(ifp,1)-0.5],[0 1],'linestyle',':','linewidth',1,'color','k');
                        end
                    end
                end

                if ~isempty(idxfill)s
                    plot([0.5,0.5],[0,1],'LineStyle','--','Color',c.SwitchLine,'LineWidth',0.8);
                    xexp = sbsdata.Session(sbsdata.Experiment==expName{idxfill}); % this exp x values
                    ox = sbsdata.Session(sbsdata.Experiment~=expName{idxfill});   % other exp x values
                    for ixexp = 1:length(xexp)
                        ix = xexp(ixexp);
                        if ix < 0
                            ix = ix + 1;
                        end
                        if ixexp == 1
                            bgfill1 = fill([ix-0.5,ix+0.5,ix+0.5,ix-0.5],[0,0,1,1],c.Exp(1,:), ...
                                'EdgeColor','none','FaceAlpha',0.07);
                            bgfill2 = fill([ox(1)-0.5,ox(1)+0.5,ox(1)+0.5,ox(1)-0.5],[0,0,1,1],c.Exp(2,:), ...
                                'EdgeColor','none','FaceAlpha',0.00);
                        else
                            fill([ix-0.5,ix+0.5,ix+0.5,ix-0.5],[0,0,1,1],c.Exp(1,:), ...
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
