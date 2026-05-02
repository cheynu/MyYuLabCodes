classdef BehaviorSRT_Indiv

    % Revised by hbWang, Nov/05/2023

    % Based on BehaviorSRT
    % Data format containing multiple sessions of one subject
    % METHODS:
    % obj.save(savepath); Save the obj as .mat file & .csv file
        % default path is pwd
    % obj.plot(plotrange, options)
        % plotrange: a vector, only plot the data of obj.DataAll(plotrange)
        % options.plotType
            % value should be one of {'DayByDay','Progress','CompExp'}
            % which represents one type we want
        % options.figSize
            % In 'DayByDay', it is [width height] of the whole figure
            % In 'Progress', it is [width height] of every single session
    
    properties
        DataAll (1,:) cell
    end

    properties (Dependent)
        Subject     (1,1) string {mustBeTextScalar} % e.g., Panini
        Group       (1,1) string {mustBeTextScalar} % e.g., hM3Dq (manual or extracted from BehaviorSRT)
        MixedFP     (1,:) double {mustBeNumeric}    % e.g., [0.5 1.0 1.5]
        nSession    (1,1) double {mustBeNumeric}
        Sessions    (1,:) double {mustBeNumeric}
        Dates       (1,:) double {mustBeNumeric}
        Tasks       (1,:) string {mustBeText} % e.g., ["Wait1", "Wait1", "Wait2"]
        Experiments (1,:) string {mustBeText} % e.g., ["Saline", "DCZ", "Saline"]
        nTrial      (1,:) double
        TableAll    (1,:) cell
        TBT               table  % trial by trial
        SBS               table  % session by session, every row: stat for each session
        EBE               table  % experiment by experiment, every row: stat for each Experiment
        CBC               table  % estimates of custom conditions, every row: stat for each custom conditions (e.g., early 200 trials)
        Probe             table  % all probe trials
        StatComparison    struct
        Options           struct
    end

    properties (Dependent, GetAccess = private)
        SaveName
    end

    properties (GetAccess = private)
        pTBT   table
        pSBS   table
        pEBE   table
        pCBC   table
        pProbe table
        cStat  struct
        Edges_HT   = 0:0.05:2.5       % Hold time (All trials)
        Bins_HT    = 0.025:0.05:2.475
        Edges_RT   = 0:0.025:0.6      % Reaction time (Cor)
        Edges_RelT = 0:0.05:1         % Release time (Cor+Late)
        SmoWin     = 8                % smoothdata('gaussian')
        ProgressTrials = 600          % all trials
        SlidingMethod = 'fixed'
        SlidingWin  = 15
        SlidingStep = 3
        CompExp  = ["DCZ", "Saline"]
        CompDate = {[],[]}
    end

    properties (Constant, GetAccess = private)
        DefaultMixedFP = [0.5, 1.0, 1.5]
        OutcomeOptions = ["Cor", "Pre", "Late"]
        RTOptions      = ["Cor", "CorLate"]
        CustomOptions  = ["EarlyProgress", "LateProgress"];
        Edges_HT_A = -3:0.5:3
        Bins_HT_A  = -2.75:0.5:2.75
    end
    
    methods
        function obj = BehaviorSRT_Indiv(behavSRTAll,method)
            arguments
                behavSRTAll (1,:) cell
                method            string {mustBeMember(method,["Merge", "Select"])} = "Merge"
            end

            dates = cellfun(@(x)x.Date, behavSRTAll, 'UniformOutput', true);
            % [~, idxDate, ~] = unique(dates, "sorted");  % Nov/05/2023, hbWang: "stable" -> "sorted"

            dataAll = cell(1, length(dates));
            for i = 1:length(dataAll)
                dataAll{i} = behavSRTAll{i};
                % for j = 1:length(behavSRTAll)
                %     if idxDate(i) ~= j
                %         dataAll{i} = dataAll{i}.merge(behavSRTAll{j}, method, true);
                %     end
                % end
            end
            obj.DataAll = dataAll;
            obj = obj.reNumberSessions("Tasks");
            disp("Checking subject names ..."); mustBeTextScalar(obj.Subject);
            disp("Checking group names ...");   mustBeTextScalar(obj.Group);
            disp("Calculating statistics data ..."); obj = obj.stat();
            disp(obj.Subject+" - SRT individual subject class has been built");
        end

        function value = get.Subject(obj)
            value = unique(string(cellfun(@(x)x.Subject,obj.DataAll,'UniformOutput',false)));
            mustBeTextScalar(value);
        end

        function obj = set.Subject(obj,value)
            for i = 1:obj.nSession
                obj.DataAll{i}.Subject = string(value);
            end
        end

        function value = get.Group(obj)
            value = unique(string(cellfun(@(x)x.Group,obj.DataAll,'UniformOutput',false)));
            mustBeTextScalar(value);
        end

        function obj = set.Group(obj,value)
            for i = 1:obj.nSession
                obj.DataAll{i}.Group = string(value);
            end
        end
        
        function value = get.MixedFP(obj)
            valueAll = cellfun(@(x)num2str(reshape(x.MixedFP, 1, [])),obj.DataAll,'UniformOutput',false);
            valueUni = unique(valueAll,'stable');
            if length(valueUni) > 1 % different MixedFPs exist
                mfp = cell(size(valueUni));
                for iVal = 1:length(valueUni)
                    mfp{iVal} = str2num(valueUni{iVal}); %#ok<*ST2NM>
                end
                value = mfp{end};
                warning('Different MixedFPs across these sessions');
            elseif isscalar(valueUni)
                value = str2num(valueUni{1});
            else
                warning('Invalid value of MixedFPs. Using DefaultMixedFP: %s',num2str(obj.DefaultMixedFP));
                value = obj.DefaultMixedFP;
            end

            if length(value) > 3
                % warning('Too many MixedFPs. Using DefaultMixedFP: %s',num2str(obj.DefaultMixedFP));
                value = obj.DefaultMixedFP;
            end
            
        end

        function obj = set.MixedFP(obj,value)
            for i = 1:obj.nSession; obj.MixedFP = value; end
        end

        function value = get.nSession(obj)
            value = length(obj.DataAll);
        end

        function value = get.Sessions(obj)
            value = cellfun(@(x)x.Session,obj.DataAll,'UniformOutput',true);
        end

        function obj = set.Sessions(obj,value)
            for i = 1:obj.nSession; obj.DataAll{i}.Session = value(i); end
        end

        function value = get.Dates(obj)
            value = cellfun(@(x)x.Date,obj.DataAll,'UniformOutput',true);
        end
            
        function value = get.Tasks(obj)
            value = cellfun(@(x)x.Task,obj.DataAll,'UniformOutput',true);
        end

        function value = get.Experiments(obj)
            value = cellfun(@(x)x.Experiment,obj.DataAll,'UniformOutput',true);
        end
        
        function obj = set.Experiments(obj,value)
            for i = 1:obj.nSession; obj.DataAll{i}.Experiment = value(i); end
        end

        function value = get.nTrial(obj)
            value = cellfun(@(x)x.nTrial,obj.DataAll,'UniformOutput',true);
        end

        function value = get.TableAll(obj)
            value = cell(1,obj.nSession);
            for i = 1:obj.nSession; value{i} = obj.DataAll{i}.Table; end
        end

        function value = get.TBT(obj)
            value = obj.pTBT;
        end

        function value = get.SBS(obj)
            value = obj.pSBS;
        end
        
        function value = get.EBE(obj)
            value = obj.pEBE;
        end

        function value = get.CBC(obj)
            value = obj.pCBC;
        end

        function value = get.Probe(obj)
            value = obj.pProbe;
        end

        function value = get.StatComparison(obj)
            value = obj.cStat;
        end
        
        function value = get.Options(obj)
            value = struct;
            value.Edges_HT = obj.Edges_HT;
            value.Bins_HT = obj.Bins_HT;
            value.Edges_RT = obj.Edges_RT;
            value.Edges_RelT = obj.Edges_RelT;
            value.SmoothWindow = obj.SmoWin;
            value.ProgressTrials = obj.ProgressTrials;
            value.SlidingMethod = obj.SlidingMethod;
            value.SlidingWindow = obj.SlidingWin;
            value.SlidingStep = obj.SlidingStep;
            value.CompExp = obj.CompExp;
            value.CompDate = obj.CompDate;
        end

        function obj = set.Options(obj,value)
            isSameFields = isequal(fieldnames(obj.Options),fieldnames(value));
            if isSameFields
                obj.Edges_HT = value.Edges_HT;
                obj.Bins_HT = value.Bins_HT;
                obj.Edges_RT = value.Edges_RT;
                obj.Edges_RelT = value.Edges_RelT;
                obj.SmoWin = value.SmoothWindow;
                obj.ProgressTrials = value.ProgressTrials;
                obj.SlidingMethod = value.SlidingMethod;
                obj.SlidingWin = value.SlidingWindow;
                obj.SlidingStep = value.SlidingStep;
                obj.CompExp = value.CompExp;
                obj.CompDate = value.CompDate;
            else
                error('Unmatched fieldnames of Options');
            end
        end

        function obj = stat(obj, calRT95CI)
            arguments
                obj
                calRT95CI = false
            end
            obj.pTBT = tbt(obj);
            obj.pSBS = sbs(obj, calRT95CI);
            obj.pEBE = ebe(obj, calRT95CI);
            obj.pCBC = cbc(obj, calRT95CI);
            obj.pProbe = probe(obj);
        end

        function value = tbt(obj)
            value = table;
            for i = 1:obj.nSession
                T = obj.TableAll{i};
                value = [value;T]; %#ok<*AGROW>
            end
        end

        function value = sbs(obj, calRT95CI)
            value = table;
            for i = 1:obj.nSession
                iobj = obj.DataAll{i};
                itable = obj.TableAll{i};
                stat = calIndivStatSRT(itable,'ifDistr',true,'fplist',iobj.MixedFP,...
                    'calRT95CI',calRT95CI,'edges_HT',obj.Edges_HT,'bins_HT',obj.Bins_HT,...
                    'edges_RT',obj.Edges_RT,'edges_RelT',obj.Edges_RelT,'smoWin',obj.SmoWin); 
                % Add progress performance for each session by "fixed" slidingMethod, 
                % each session has different length, we just append them as struct.
                switch lower(obj.SlidingMethod)
                    case 'fixed'
                        iprgPerf = iobj.calProgress("Outcome",'tarStr',obj.OutcomeOptions,...
                            'slidingMethod',obj.SlidingMethod,'winSize',obj.SlidingWin,'stepSize',obj.SlidingStep);
                        iprgRT = iobj.calProgress("RT",'tarStr',obj.RTOptions,...
                            'slidingMethod',obj.SlidingMethod,'winSize',obj.SlidingWin,'stepSize',obj.SlidingStep);
                        iprgFP = iobj.calProgress("FP",'tarStr',{'All'},...
                            'slidingMethod',obj.SlidingMethod,'winSize',obj.SlidingWin,'stepSize',obj.SlidingStep);
                    case 'ratio'
                        iprgPerf = iobj.calProgress("Outcome",'tarStr',obj.OutcomeOptions,...
                            'slidingMethod',obj.SlidingMethod,'winRatio',obj.SlidingWin,'stepRatio',obj.SlidingStep);
                        iprgRT = iobj.calProgress("RT",'tarStr',obj.RTOptions,...
                            'slidingMethod',obj.SlidingMethod,'winRatio',obj.SlidingWin,'stepRatio',obj.SlidingStep);
                        iprgFP = iobj.calProgress("FP",'tarStr',{'All'},...
                            'slidingMethod',obj.SlidingMethod,'winRatio',obj.SlidingWin,'stepRatio',obj.SlidingStep);
                    otherwise
                        error('Invalid parameters of SlidingMethod');
                end
                
                stat = addvars(stat, obj.SlidingWin, obj.SlidingStep, {iprgFP.x.All}, {iprgPerf.y}, {iprgRT.y}, {iprgFP.y},...
                    'NewvariableNames', {'progressWin', 'progressStep', 'progressTime', 'progressPerf', 'progressRT', 'progressFP'});
                
                % Add FP-divided progress data, and trim to same length(yFP)
                for iFP = 1:length(iobj.MixedFP)
                    if iobj.Task == "3FPs"
                        yFP = min([height(iprgPerf.x1(:,1)),height(iprgPerf.x2(:,1)),height(iprgPerf.x3(:,1))]);
                        iprg.("Time_FP"+string(iFP)) = iprgPerf.("x"+string(iFP)).Cor(1:yFP);
                        iprg.("Perf_FP"+string(iFP)) = iprgPerf.("y"+string(iFP))(1:yFP,:);
                        iprg.("RT_FP"+string(iFP))   = iprgRT.("y"+string(iFP))(1:yFP,:);
                    else
                        iprg.("Time_FP"+string(iFP)) = [];
                        iprg.("Perf_FP"+string(iFP)) = [];
                        iprg.("RT_FP"+string(iFP))   = [];
                    end
                    stat = addvars(stat, {iprg.("Time_FP"+string(iFP))},...
                        'NewVariableNames',cellstr("progressTime_FP"+string(iFP)));
                    stat = addvars(stat, {iprg.("Perf_FP"+string(iFP))}, ...
                        'NewVariableNames',cellstr("progressPerf_FP"+string(iFP)));
                    stat = addvars(stat, {iprg.("RT_FP"+string(iFP))}, ...
                        'NewVariableNames',cellstr("progressRT_FP"+string(iFP)));
                end
                value = [value;stat];
            end
        end
        
        function value = ebe(obj, calRT95CI)
            value = table;
            uniExp = unique(obj.Experiments);
            for i = 1:length(uniExp)
                data = obj.TBT(obj.TBT.Experiment == uniExp{i},:);
                stat = calIndivStatSRT(data,true,'ifDistr',true,'fplist',obj.MixedFP,...
                    'calRT95CI',calRT95CI,'edges_HT',obj.Edges_HT,'bins_HT',obj.Bins_HT,...
                    'edges_RT',obj.Edges_RT,'edges_RelT',obj.Edges_RelT,'smoWin',obj.SmoWin);
                value = [value;stat];
            end
%             value = table2struct(value);
        end

        function value = cbc(obj, calRT95CI)
            % Existing conditions:
                % Early ProgressTrials (e.g., first 200) of TBT
                % Late ProgressTrials (e.g., last 200) of TBT
            value = table;
            progTrials = min(obj.ProgressTrials,size(obj.TBT,1));
            % Early ProgressTrials
            data = obj.TBT(1:progTrials,:);
            stat = calIndivStatSRT(data,true,'ifDistr',true,'fplist',obj.MixedFP,...
                'calRT95CI',calRT95CI,'edges_HT',obj.Edges_HT,'bins_HT',obj.Bins_HT,...
                'edges_RT',obj.Edges_RT,'edges_RelT',obj.Edges_RelT,'smoWin',obj.SmoWin);
            value = [value;stat];
            % Late ProgressTrials
            data = obj.TBT(end-progTrials+1:end,:);
            stat = calIndivStatSRT(data,true,'ifDistr',true,'fplist',obj.MixedFP,...
                'edges_HT',obj.Edges_HT,'bins_HT',obj.Bins_HT,...
                'edges_RT',obj.Edges_RT,'edges_RelT',obj.Edges_RelT,'smoWin',obj.SmoWin);
            value = [value;stat];

            value = addvars(value,["EarlyProgress";"LateProgress"],...
                'NewVariableNames','Customization','Before','Subject');
        end

        function value = probe(obj)
            value = table;
            for i = 1:obj.nSession
                T = obj.DataAll{i}.Probe;
                value = [value;T];
            end
        end

        function obj = calStatComparison(obj)
            try
                idxExp1 = find(obj.Experiments == obj.CompExp(1) & ismember(obj.Dates, obj.CompDate{1}));
                idxExp2 = find(obj.Experiments == obj.CompExp(2) & ismember(obj.Dates, obj.CompDate{2}));
%                 if length(idxExp1) ~= length(idxExp2)
%                     minLen = min(length(idxExp1), length(idxExp2));
%                     idxExp1 = idxExp1(1:minLen);
%                     idxExp2 = idxExp2(1:minLen);
%                 end
            catch ME
                msg = ('Invalid arguments (CompExp/CompDate) in Options');
                causeException = MException('MYFUN:invalidFormat', msg);
                ME = addCause(ME, causeException);
                rethrow(ME);
            end
            
            newobj = BehaviorSRT_Indiv(obj.DataAll(union(idxExp1, idxExp2))); % Only use the selected sessions
            if isempty(newobj.TBT)
                newobj = newobj.stat();
            end
            obj.cStat = struct;
            obj.cStat.TBT = newobj.TBT;
            obj.cStat.SBS = newobj.SBS;
            obj.cStat.EBE = newobj.EBE;
            obj.cStat.CBC = newobj.CBC;
            obj.cStat.Options = obj.Options;
        end

        function value = get.SaveName(obj)
            value = "BClassIndiv_"+upper(obj.Subject)+"_"+...
                num2str(min(obj.Dates))+"_"+num2str(max(obj.Dates));
        end

        function obj = reNumberTrials(obj, eachFP, indicator, switchStr)
            % This method add new var .reTrial to TBT, mark a new trial number 
            % standard (e.g. set lesion point as zero, and pre/post-lesion -/+ N)
            arguments
                obj
                % eachFP: true - renumber for each FP
                eachFP    logical = false
                % Task/Experiment: renumber by task type or exp condition;
                indicator string {mustBeMember(indicator, ["Task", "Experiment"])} = "Task"
                % If switchStr ～isempty, set the switch point as zero
                switchStr string = []
            end
            tbt = obj.TBT; out = [];
            tbt = sortrows(tbt, {'Date'});
            if ~any(ismember(fieldnames(tbt), "reTrial"))
                reTrial = nan(height(tbt), 1);
                tbt = addvars(tbt, reTrial, 'NewVariableNames', "reTrial");
            end

            if eachFP
                allFPs = obj.DefaultMixedFP;
                for i = 1:length(allFPs)
                    itbt = tbt(tbt.FP == allFPs(i), :);
                    itbt = renum(itbt, indicator, switchStr);
                    out = [out; itbt];
                end
                out = sortrows(out, {'Date', 'Session', 'iTrial'});
            else
                out = renum(tbt, indicator, switchStr);
            end
            obj.pTBT = out;

            function out = renum(in, indicator, switchStr)
                out = in; kk = 1;
                allIndicators = in.(indicator);
                if isempty(switchStr)
                    % simply renumber trials as 1~n for each experiment / task
                    for ii = 1:length(allIndicators)
                        if ~isempty(allIndicators(ii))
                            if ii > 1
                                if allIndicators(ii) ~= allIndicators(ii-1)
                                    kk = 1;
                                else
                                    kk = kk + 1;
                                end
                            end
                            out.reTrial(ii) = kk;
                        end
                    end
                else
                    idx1 = find(allIndicators == switchStr(1));
                    idx2 = find(allIndicators == switchStr(2));
                    if ~isempty(idx1)
                        out.reTrial(idx1) = idx1-idx1(end)-1;
                    end
                    if ~isempty(idx2)
                        out.reTrial(idx2) = idx2-idx2(1)+1;
                    end
                end
            end
        end

        function obj = reNumberSessions(obj, indicator, switchStr)
            arguments
                obj
                indicator string {mustBeMember(indicator, ["Tasks", "Experiments", "Dates"])}
                switchStr string = []
            end

            allIndicators = obj.(indicator);
            newSess = zeros(size(allIndicators));
            kk = 1;
            switch indicator
                case "Dates"
                    newSess = 1:length(allIndicators);
                case {"Tasks", "Experiments"}
                    if isempty(switchStr)
                        % simply renumber sessions as 1~n for each experiment
                        for i = 1:length(allIndicators)
                            if ~isempty(allIndicators(i))
                                if i > 1
                                    if allIndicators(i) ~= allIndicators(i-1)
                                        kk = 1;
                                    else
                                        kk = kk + 1;
                                    end
                                end
                                newSess(i) = kk;
                            end
                        end
                    else
                        idx1 = find(allIndicators == switchStr(1));
                        idx2 = find(allIndicators == switchStr(2));
                        if ~isempty(idx1)
                            newSess(idx1) = idx1-idx1(end)-1;
                        end
                        if ~isempty(idx2)
                            newSess(idx2) = idx2-idx2(1)+1;
                        end
                    end
            end
            obj.Sessions = newSess;
        end

        function out = sampleTrials(obj, options)
            arguments
                obj
                options.exp      string  = ["Pre", "Post", "Post"]
                options.trialNum double  = [100 100 100]
                options.smplMark double  = [1 2 3]
                options.dir      double  = [1 0 1]
                options.reSample logical = false
                options.tLim     double  = [0 3000]
                options.consec   double  = [1 0 0] % to sample trials from consecutive sessions
                % this is to adapt for saline-dcz-saline-dcz sessions
            end
            tbt = obj.TBT;
            tbt = tbt(tbt.TimeElapsed<options.tLim(2) & tbt.TimeElapsed>options.tLim(1), :);
            if ~any(ismember(fieldnames(tbt), "Sampled")) || options.reSample
                smpl = zeros(height(tbt), 1);
                tbt = addvars(tbt, smpl, 'NewVariableNames', "Sampled");
            end

            for i = 1:length(options.trialNum)
                tbt = sampletrials(tbt, options.exp(i), options.trialNum(i), ...
                    options.smplMark(i), obj.MixedFP, options.dir(i), options.consec(i));
            end
            out = tbt;
            function tbl = sampletrials(tbl, exp, num, mark, fps, flip, consecutive)
                    idx_exp = tbl.Experiment == exp;
                    if consecutive
                        diffexp = find(diff(idx_exp) ~= 0, 1, "first");
                        idx_exp(diffexp+1:end) = 0;
                    end
                    session = unique(tbl.Session(idx_exp), "sorted");
                    if flip; session = flipud(session); end
                    for ifp = 1:length(fps)
                        idx_ifp = tbl.FP == fps(ifp);
                        cnt = 0;
                        for jsess = 1:length(session)
                            idx_jsess = tbl.Session == session(jsess);
                            idx_jsess_ifp = idx_jsess & idx_ifp;
                            if sum(idx_jsess_ifp) <= num-cnt
                                tbl.Sampled(idx_jsess_ifp) = mark;
                                cnt = cnt + sum(idx_jsess_ifp);
                            else
                                idx_smpl = randperm(sum(idx_jsess_ifp), num-cnt);
                                idx_jsess_ifp = find(idx_jsess_ifp);
                                tbl.Sampled(idx_jsess_ifp(idx_smpl)) = mark;
                                break;
                            end
                        end 
                    end
                end
        end

        function out = compareBehavior(obj, options)
            % This medthod is written to compare behavior with chi2test between
            %   two sessions, inputs could be [date1 date2] or [sess1 sess2].
            % If chi2test is significant, z tests would be proceeded for all behavior categories.
            arguments
                obj
                options.Dates = []
                options.Sessions = []
                options.psign = 0.05
                options.tail = 2
            end
            if length(options.Dates) == 2
                dates = options.Dates;
            elseif length(options.Sessions) == 2
                dates = [obj.Dates(options.Sessions(1)) obj.Dates(options.Sessions(2))];
            else
                error('Wrong input format of Dates or Sessions');
            end

            perf1 = obj.DataAll{obj.Dates == dates(1)}.Performance;
            perf2 = obj.DataAll{obj.Dates == dates(2)}.Performance;

            fpNames = perf1.Properties.RowNames;
            out = table('Size', [length(fpNames) 5], ...
                'VariableTypes', ["cell", "double", "cell", "double", "double"], ...
                'VariableNames', ["Performance", "p_chi2test", "ztest", "p_ttestRT", "p_ttestRelT"], ...
                'RowNames', fpNames);

            for i = 1:length(fpNames)
                % cal perf statistics
                perf = [perf1.nCor(i) perf1.nPre(i) perf1.nLate(i);
                        perf2.nCor(i) perf2.nPre(i) perf2.nLate(i)];

                % remove all-zero columns
                idx = ones(3,1);
                for j = 1:3
                    if all(perf(:,j)==0); idx(j) = 0; end
                end
                perfchi = perf(:,idx==1);
                [out.p_chi2test(i), ~] = chi2test(perfchi);
                if out.p_chi2test(i) < options.psign
                    for j = 1:3
                        n1 = sum(perf(1,1:3));
                        n2 = sum(perf(2,1:3));
                        x1 = perf(1,j);
                        x2 = perf(2,j);
                        p1 = x1/n1; p2 = x2/n2;
                        p0 = (x1+x2)/(n1+n2);
    
                        z = (p1-p2)/sqrt(p0*(1-p0)*((1/n1)+(1/n2)));
                        p = options.tail*normcdf(-abs(z),0,1);
                        zt(1,j) = z;
                        zt(2,j) = p;
                    end
                    zt = table(zt(:,1),zt(:,2),zt(:,3), 'VariableNames', ["Cor", "Pre", "Late"]);
                    zt.Properties.RowNames = ["z", "p"];
                    out.ztest{i} = zt;
                end
                out.Performance{i} = perf;

                % cal RT statistics
                irelt1 = perf1.RelT{i}; irt1 = perf1.RT{i};
                irelt2 = perf2.RelT{i}; irt2 = perf2.RT{i};
                [~, out.p_ttestRT(i)]   = ttest2(irt1, irt2);
                [~, out.p_ttestRelT(i)] = ttest2(irelt1, irelt2);
            end

        end

        function out = calPrematureCDF(obj, options)
            arguments
                obj
                options.tbin = 0.01
                options.tmin = 0.1
            end
            allCDF = cell(1, obj.nSession);
            for i = 1:obj.nSession
                allCDF{i} = obj.DataAll{i}.calPrematureCDF("tbin", options.tbin, "tmin", options.tmin);
            end
            out = allCDF;
        end

        function save(obj, savepath)
            arguments
                obj
                savepath = pwd
            end
            [~,~] = mkdir(savepath);
            save(fullfile(savepath,obj.SaveName),'obj');
            % writetable(obj.TBT,fullfile(savepath,append(obj.SaveName,'.csv')));
        end

        function print(obj, options)
            arguments
                obj
                options.Figure   = []
                options.savePath = pwd
                options.saveName = obj.SaveName
                options.saveFig  = false
            end
            if isempty(options.Figure)
                warning("No existing figure, use default settings");
                options.Figure = obj.plot();
            end

            [~,~] = mkdir(options.savePath);
            savename = fullfile(options.savePath, options.saveName);
            print(options.Figure, '-dpng', savename);
            % print(options.Figure, '-depsc2', savename);
            if options.saveFig
                saveas(options.Figure, savename, 'fig');
            end
        end

        function Fig = plot(obj,options)
            arguments
                obj
                options.plotType  string {mustBeMember(options.plotType, ...
                    ["Learning","Comparison","GrammLearning", ...
                    "Recovery", "RecoveryV2", "PrevsPost", "InterSummary", ...
                    "Probe"])} = "Learning"
                options.shadedExp string  = "DCZ"
                options.htLim     double  = [0 3]
                options.rtLim     double  = [0 1.2]
                options.perfLim   double  = [0 1]
                options.save      logical = true
                options.saveName  string  = obj.SaveName
                options.savePath  string  = fullfile(pwd, "Fig")
                options.PrgComp   logical = false
                options.trialNum  double  = [150 150 150] % trial number of trial-based HT analysis
                options.trialNum2 double  = 20  % trial number to show in recovery v2 (for each FP)
                options.nSplit    double  = 100 % trial number to split a session to two parts (early & late)
                options.kernel_bw double  = 0.08
                options.smplExp   string  = ["Pre", "Post", "Post"]
                options.smplMark  double  = [1 2 3] % pre; post; recovery marks
                options.smplMarkS string  = ["Pre-lesion", "Post-early", "Post-late"]
                options.expName   string  = ["Pre", "Post"]
                options.txtTitle  string  = ""
            end
            shadedExp = options.shadedExp;
            plotProgressCompare = options.PrgComp;
            trialNum = options.trialNum;
            trialNum2 = options.trialNum2;
            sampleExps = options.smplExp;
            sampleMarks = options.smplMark;
            SampleMarkStrs = options.smplMarkS;
            expName = options.expName;
            txtTitle = options.txtTitle;
            nSplit = options.nSplit;
            kernel_bw = options.kernel_bw;

            % Parameters
            font = "Dejavu Sans";
            set(groot, "defaultAxesFontName", font);
            fontSize = struct("Axes", 7, "Label", 7, "Title", 10, "Info", 12);
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

            xLim.Date = [0.5 obj.nSession+0.5];
            xTick.Date = 1:obj.nSession;
            xTickLabel.Date = num2str(obj.Dates');

            cTab10 = tab10(10); cAccent = Accent(8); cDarkGrey = cAccent(end,:);
            cBlue = cTab10(1,:); cOrange = cTab10(2,:); cGreen = cTab10(3,:);
            cRed  = cTab10(4,:); cGrey = cTab10(8,:);

            c = struct("Perf", [cGreen;cRed;cGrey], "MixedFPs", [cGrey;mean([cOrange;cGrey]);cOrange], ...
                       "MixedFPsJY", ["#9BBEC8", "#427D9D", "#164863"], ...
                       "PostExpJY", "#FF6C22", ...
                       "Exp", [cOrange;cDarkGrey], "CustomLine", [cBlue;cRed], ...
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
                    switch obj.Tasks(1)
                        case {"AutoShaping", "LeverPress", "LeverRelease"}
                            Fig = plotLearningNaive(obj);
                        case {"Wait1", "Wait2", "3FPs"}
                            Fig = plotLearning(obj);
                        case {"Wait1Ephys", "Wait2Ephys", "2FPs"}
                            Fig = plotLearning2FPs(obj);
                    end
                case "GrammLearning"
                    Fig = plotGrammLearning(obj);
                case "Comparison"
                    Fig = plotComparison(obj);
                case "Recovery"
                    Fig = plotRecovery(obj);
                case "RecoveryV2"
                    Fig = plotRecoveryV2(obj);
                case "PrevsPost"
                    Fig = plotPrevsPost(obj);
                case "InterSummary"
                    Fig = plotInterSummary(obj);
                case "Probe"
                    Fig = plotProbe(obj);
            end

            %% Plot probe summary
            function Fig = plotProbe(obj)
                                
                pbp = obj.Probe;
                pbp = pbp(pbp.HT >= 0.1, :); % remove HT < 0.1 sec trials
                pbp = pbp(pbp.TimeElapsed<tLim(2) & pbp.TimeElapsed>tLim(1), :);

                alldates = unique(pbp.Date);
                allexps  = obj.Experiments(ismember(obj.Dates, alldates));
                idxExp   = pbp.Experiment == shadedExp;
                idxShade = allexps == shadedExp;

                nSess = length(alldates); nFP = length(obj.MixedFP);

                allPDF = cell(nSess, 1);
                for i = 1:nSess
                    idxDate = pbp.Date == alldates(i);
                    pbp.Session(idxDate) = repmat(i, [sum(idxDate), 1]);
                    ipbp = pbp(idxDate,:);
                    allPDF{i} = ksdensity(ipbp.HT, obj.Options.Edges_HT, 'Bandwidth', kernel_bw);
                end

                expHT = cell(2, 1); expPDF = expHT; expPDF_ci = expHT; expGrp = cell(2, 1);
                expHT_FP = cell(2, nFP); expPDF_FP = expHT_FP; expPDF_ci_FP = expHT_FP;
                if any(idxShade) && ~all(idxShade)
                    expHT{1} = pbp.HT(idxExp);
                    expHT{2} = pbp.HT(~idxExp);
                    [expPDF{1}, xi] = ksdensity(pbp.HT(idxExp),  obj.Options.Edges_HT, 'Bandwidth', kernel_bw);
                    expPDF{2} = ksdensity(pbp.HT(~idxExp), obj.Options.Edges_HT, 'Bandwidth', kernel_bw);
                    expPDF_ci{1} = ksdensity_ci(pbp.HT(idxExp),  obj.Options.Edges_HT, kernel_bw, 1000);
                    expPDF_ci{2} = ksdensity_ci(pbp.HT(~idxExp), obj.Options.Edges_HT, kernel_bw, 1000);

                    expCDF{1} = ksdensity(pbp.HT(idxExp),  obj.Options.Edges_HT, 'Bandwidth', kernel_bw, "Function", "cdf");
                    expCDF{2} = ksdensity(pbp.HT(~idxExp), obj.Options.Edges_HT, 'Bandwidth', kernel_bw, "Function", "cdf");
                    expCDF_ci{1} = ksdensity_ci(pbp.HT(idxExp),  obj.Options.Edges_HT, kernel_bw, 1000, "Function", "cdf");
                    expCDF_ci{2} = ksdensity_ci(pbp.HT(~idxExp), obj.Options.Edges_HT, kernel_bw, 1000, "Function", "cdf");
                    for i = 1:nFP
                        iFP = obj.MixedFP(i);
                        idxFP = pbp.FP == iFP;
                        expHT_FP{1,i} = pbp.HT(idxExp & idxFP);
                        expHT_FP{2,i} = pbp.HT(~idxExp & idxFP);
                        expPDF_FP{1,i} = ksdensity(pbp.HT(idxExp & idxFP),  obj.Options.Edges_HT, 'Bandwidth', kernel_bw);
                        expPDF_FP{2,i} = ksdensity(pbp.HT(~idxExp & idxFP), obj.Options.Edges_HT, 'Bandwidth', kernel_bw);
                        expPDF_ci_FP{1,i} = ksdensity_ci(pbp.HT(idxExp & idxFP),  obj.Options.Edges_HT, kernel_bw, 1000);
                        expPDF_ci_FP{2,i} = ksdensity_ci(pbp.HT(~idxExp & idxFP), obj.Options.Edges_HT, kernel_bw, 1000);

                        expCDF_FP{1,i} = ksdensity(pbp.HT(idxExp & idxFP),  obj.Options.Edges_HT, 'Bandwidth', kernel_bw, "Function", "cdf");
                        expCDF_FP{2,i} = ksdensity(pbp.HT(~idxExp & idxFP), obj.Options.Edges_HT, 'Bandwidth', kernel_bw, "Function", "cdf");
                        expCDF_ci_FP{1,i} = ksdensity_ci(pbp.HT(idxExp & idxFP),  obj.Options.Edges_HT, kernel_bw, 1000, "Function", "cdf");
                        expCDF_ci_FP{2,i} = ksdensity_ci(pbp.HT(~idxExp & idxFP), obj.Options.Edges_HT, kernel_bw, 1000, "Function", "cdf");
                    end
                end
                maxHTpdf = max(cellfun(@(x) max(x,[],"all"), expPDF_ci_FP), [], "all");
                maxHTpdf_exp = ceil(max(cellfun(@(x) max(x,[],"all"), expPDF_ci), [], "all")*10)/10;

                
                fillList = zeros(nSess, 4); FPLineListX = zeros(nSess, 2);
                for i = 1:nSess
                    fillList(i,:)    = [i-0.5 i+0.5 i+0.5 i-0.5];
                    FPLineListX(i,:) = [i-0.5 i+0.5];
                end
                fillList = fillList.*(idxShade)';
                GapLineList = [xTick.Date(1:end-1);xTick.Date(1:end-1)]+0.5;

                xstart = 1.5; ystart = 1.8; xgap = 0.8; ygap = 0.8;

                axeSizeRas = [8 4];                             % cross sessions HT / progress
                axeSizePDF = [axeSizeRas(2) axeSizeRas(2)];     % for early-late PDF comparison
                axeSizeFP  = [axeSizeRas(1)*2/3 axeSizeRas(2)]; % heatmap

                cbarSize = [0.3 axeSizePDF(1)/2];               % for heatmap colorbar
                
                xmap = [xstart, ...
                        xstart + xgap*1 + axeSizeRas(1), ...
                        xstart + xgap*2 + axeSizeRas(1) + axeSizePDF(1), ...
                        xstart + xgap*3 + axeSizeRas(1) + axeSizePDF(1)*2];

                axeSizeInfo = [xmap(4)-xmap(1) 0.1];

                ymap = [ystart, ...
                        ystart + ygap*1 + axeSizeRas(2)*1, ...
                        ystart + ygap*2 + axeSizeRas(2)*2, ...
                        ystart + ygap*3 + axeSizeRas(2)*2];

                Fig = figure(1); clf(Fig, "reset");
                set(Fig, "Unit", "centimeters", "PaperPositionMode", "auto", ...
                    "Position", [2 2 xmap(end) ymap(end)], "Color", "w");

                %% HT raster (3FP)
                ha11 = axes;
                set(ha11, "Units", "centimeters", "Position", [xmap(1) ymap(1) axeSizeRas],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", [0 nSess]+0.5, "XTick", 1:nSess, "XTickLabel", string(alldates), ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", yTickLabel.HT, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                % xlabel("Sessions (dates)", "FontSize", fontSize.Label, "FontName", font);
                ylabel("Hold duration (ms)", "FontSize", fontSize.Label, "FontName", font);
                imagesc(ha11, 1:nSess, obj.Bins_HT, cell2mat(allPDF)', [0 maxHTpdf*1.1]);

                colorbar(ha11, "Units", "centimeters", "Position", [xmap(2) ymap(1) cbarSize], ...
                    "FontSize", fontSize.Axes, "FontName", font);
                if any(idxShade)
                    arrow([find(idxShade)' zeros(sum(idxShade),1)], ...
                        [find(idxShade)' 0.2*ones(sum(idxShade), 1)], 'Color', c.Shade, ...
                        'LineWidth', psize.Arrow(1), 'Length', psize.Arrow(2), 'TipAngle', psize.Arrow(3));
                end

                ha21 = axes;
                set(ha21, "Units", "centimeters", "Position", [xmap(1) ymap(2) axeSizeRas],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", [0 nSess]+0.5, "XTick", 1:nSess, "XTickLabel", {}, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", yTickLabel.HT, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                xlabel("Sessions (dates)", "FontSize", fontSize.Label, "FontName", font);
                ylabel("Hold duration (ms)", "FontSize", fontSize.Label, "FontName", font);

                TErescaled = rescale(pbp.TimeElapsed, 0.05, 0.95);
                time2plot = TErescaled + pbp.Session - 0.5;
                scatter(time2plot, pbp.HT, psize.Scatter(1), ...
                        "MarkerFaceColor", c.Unsampled, "MarkerEdgeColor", "none", "MarkerFaceAlpha", alpha.Scatter);

                violingroup = [ones(sum(idxExp),1); 2*ones(sum(~idxExp),1)];
                violindata  = [expHT{1}; expHT{2}];
                [~,pv] = ttest2(expHT{1}, expHT{2});

                ha12 = axes;
                set(ha12, "Units", "centimeters", "Position", [xmap(3) ymap(1) axeSizePDF], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen, ...
                    "XLim", [0.5 2.5], "XTick", [1 2], "XTickLabel", {}, ...
                    "YLim", [0 5], "YTick", 0:1:5, "YTickLabel",string(0:1:5), ...
                    "FontSize", fontSize.Axes, "FontName", font);
                ylabel("Press duration (s)", "FontSize", fontSize.Label, "FontName", font);
                violinHT = daviolinplot(violindata, 'group', violingroup, ...
                    'box', 1, 'boxcolor', 'same', 'boxwidth', 1.5, 'scatter', 3,'jitter', 3,...
                    'scattersize', 5, 'scatteralpha', alpha.Scatter, 'violinwidth', 1.5,...
                    'xtlabels', [], 'outliers', 0);
                for i = 1:2
                    set(violinHT.ds(i), "FaceColor", c.Exp(i,:), "FaceAlpha", alpha.Violin, "EdgeColor", c.ViolinEdge);
                    violinHT.ds(i).XData = violinHT.ds(i).XData-0.2;
                    set(violinHT.sc(i), "MarkerFaceColor", c.Exp(i,:), "MarkerEdgeColor", "none");
                    violinHT.sc(i).XData = violinHT.sc(i).XData-0.2;
                    set(violinHT.bx(i), "FaceColor", c.Exp(i,:), "FaceAlpha", alpha.Violin, "EdgeColor", "none");
                    set(violinHT.md(i), "LineWidth", 1);
                    set(violinHT.wh(1,i,1), "LineWidth", 1);
                    set(violinHT.wh(1,i,2), "LineWidth", 1);
                end
                set(gca, "XLim", [0.5 2.5], "XTickLabel", expName);
                title("ttest pvalue = "+string(pv), "FontSize", fontSize.Label, "FontName", font);

                % PDF and CDF
                ha22 = axes;
                set(ha22, "Units", "centimeters", "Position", [xmap(2) ymap(2) axeSizePDF],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, ...
                    "YLim", [0 maxHTpdf_exp], "YTick", [0 maxHTpdf_exp], "YTickLabel", string([0 maxHTpdf_exp]), ...
                    "FontSize", fontSize.Axes, "FontName", font);
                ylabel("PDF (1/s)", "FontSize", fontSize.Label, "FontName", font);
                plotshaded(xi, expPDF_ci{1}, c.Exp(1,:));
                plot(xi, expPDF{1}, "Color", c.Exp(1,:), "LineWidth", 1, "LineStyle", "-");
                plotshaded(xi, expPDF_ci{2}, c.Exp(2,:));
                plot(xi, expPDF{2}, "Color", c.Exp(2,:), "LineWidth", 1, "LineStyle", "-");

                ha23 = axes;
                set(ha23, "Units", "centimeters", "Position", [xmap(3) ymap(2) axeSizePDF],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, ...
                    "YLim", [0 1], "YTick", [0 1], "YTickLabel", string([0 1]), ...
                    "FontSize", fontSize.Axes, "FontName", font);
                ylabel("CDF", "FontSize", fontSize.Label, "FontName", font);
                plotshaded(xi, expCDF_ci{1}, c.Exp(1,:));
                plot(xi, expCDF{1}, "Color", c.Exp(1,:), "LineWidth", 1, "LineStyle", "-");
                plotshaded(xi, expCDF_ci{2}, c.Exp(2,:));
                plot(xi, expCDF{2}, "Color", c.Exp(2,:), "LineWidth", 1, "LineStyle", "-");

                % % PDF and CDF
                % ha31 = axes;
                % set(ha31, "Units", "centimeters", "Position", [xmap(1) ymap(3) axeSizePDF],...
                %     "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                %     "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, ...
                %     "YLim", [0 maxHTpdf_exp], "YTick", [0 maxHTpdf_exp], "YTickLabel", string([0 maxHTpdf_exp]), ...
                %     "FontSize", fontSize.Axes, "FontName", font);


                %% Add gaplines and fill shaded backgrounds
                axesList_All = [ha21; ha11];
                for i = 1:length(axesList_All)
                    Fig.CurrentAxes = axesList_All(i);
                    curYLim = get(gca, "YLim");
                    if any(idxShade)
                        fill(fillList, [curYLim(1) curYLim(1) curYLim(2) curYLim(2)], c.Shade, ...
                            "FaceAlpha", alpha.Shade, "EdgeColor", "none");
                    end
                    line(GapLineList, curYLim, ...
                        "Color", c.GapLine, "LineStyle", ":", "LineWidth", psize.GapLine);
                end

                
                %% Add info
                ha00 = axes;
                set(ha00, "Units", "centimeters", "Position", [xmap(1)-xstart/2 ymap(end)-ygap*1.5 axeSizeInfo]);
                axis off;
                title("Subject: "+obj.Subject+"  ("+obj.Group+")"+ ...
                    " - Probe trials - Shaded: "+shadedExp, ...
                    "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
            end

            %% Plot learning summary for 3FPs
            function Fig = plotLearning(obj)
                % V2, HT/RT plotted by FPs

                % To plot wait and multiFP stages together:
                %  - renumber session id
                %  - wait task: shortFP ~ 0-0.7s; midFP ~ 0.8-1.4s
                allTasks = unique(obj.Tasks);
                if length(allTasks)>1
                    obj = obj.reNumberSessions("Dates");
                    obj = obj.stat(false);
                end
                tbt = obj.TBT; sbs = obj.SBS; cbc = obj.CBC;
                if any(ismember(allTasks, ["Wait1", "Wait2"]))
                    fp = tbt.FP; newfp = fp;
                    fpmax = max(obj.MixedFP);
                    fplist = [(fpmax-0.1)/2 fpmax-0.1 fpmax];
                    for i = 1:length(fp)
                        if ismember(tbt.Task(i), ["Wait1", "Wait2"])
                            if fp(i) <= fplist(1)
                                newfp(i) = obj.MixedFP(1);
                            elseif fp(i) <= fplist(2)
                                newfp(i) = obj.MixedFP(2);
                            else
                                newfp(i) = obj.MixedFP(3);
                            end
                        end
                    end
                    tbt.FP = newfp;
                end

                % Calculate matrix for shading and lining
                idxShade = obj.Experiments == shadedExp;
                fillList = zeros(obj.nSession, 4); FPLineListX = zeros(obj.nSession, 2);
                for i = 1:obj.nSession
                    fillList(i,:)    = [i-0.5 i+0.5 i+0.5 i-0.5];
                    FPLineListX(i,:) = [i-0.5 i+0.5];
                    FPLineListY(i,:) = obj.DataAll{1,i}.MixedFP;
                end
                fillList = fillList.*(idxShade)';
                % FPLineListY = obj.MixedFP;
                GapLineList = [xTick.Date(1:end-1);xTick.Date(1:end-1)]+0.5;

                xstart = 1.5; ystart = 1.8; xgap = 0.5; ygap = 0.8;

                axeSize1 = [8 4];                                    % cross sessions HT / progress
                axeSize2 = [2 (axeSize1(2)*2-xgap)/3];               % for early-late PDF comparison
                axeSize3 = [axeSize1(1)*3/4 (axeSize1(2)*2-xgap)/3]; % heatmap
                axeSize4 = [axeSize1(1) (axeSize1(2)*2-xgap)/3];     % HT/RT under diff FPs
                axeSize5 = [(axeSize2(1)+axeSize3(1)+axeSize4(1)+xgap)/2 axeSize1(2)];
                axeSize6 = [axeSize4(1) axeSize1(2)*2/3];
                cbarSize = [axeSize2(1) 0.3];                        % for heatmap colorbar
                
                xmap = [xstart, ...
                        xstart + xgap*1 + axeSize3(1), ...
                        xstart + xgap*2 + axeSize3(1) + axeSize2(1), ...
                        xstart + xgap*5 + axeSize3(1) + axeSize2(1) + axeSize4(1), ...
                        xstart + xgap*6 + axeSize3(1) + axeSize2(1) + axeSize4(1)*2];

                axeSizeInfo = [xmap(4)-xmap(1) 0.1];

                ymap = [ystart, ...
                        ystart + ygap*1 + axeSize3(2)*1, ...
                        ystart + ygap*2 + axeSize3(2)*2, ...
                        ystart + ygap*4 + axeSize3(2)*3, ...
                        ystart + ygap*5 + axeSize3(2)*3 + axeSize6(2), ...
                        ystart + ygap*6 + axeSize3(2)*3 + axeSize1(2), ...
                        ystart + ygap*6 + axeSize3(2)*3 + axeSize6(2)*2];

                Fig = figure(1); clf(Fig, "reset");
                set(Fig, "Unit", "centimeters", "PaperPositionMode", "auto", ...
                    "Position", [2 2 xmap(end) ymap(end)], "Color", "w");

                %% ha11abc, holdtime heatmap
                maxHTpdf = max([obj.SBS.HTpdf_FP1 obj.SBS.HTpdf_FP2 obj.SBS.HTpdf_FP3], [], 'all');

                ha11a = axes;
                set(ha11a, "Units", "centimeters", "Position", [xmap(1) ymap(3) axeSize3],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", yTickLabel.HT, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                % xlabel("Sessions (dates)", "FontSize", fontSize.Label, "FontName", font);
                ylabel("Hold duration (ms)", "FontSize", fontSize.Label, "FontName", font);
                title("ShortFP", "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                imagesc(ha11a, 1:obj.nSession, obj.Bins_HT, obj.SBS.HTpdf_FP1', [0 maxHTpdf*1.1]);

                ha11b = axes;
                set(ha11b, "Units", "centimeters", "Position", [xmap(1) ymap(2) axeSize3],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", yTickLabel.HT, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                % xlabel("Sessions (dates)", "FontSize", fontSize.Label, "FontName", font);
                ylabel("Hold duration (ms)", "FontSize", fontSize.Label, "FontName", font);
                title("MidFP", "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                imagesc(ha11b, 1:obj.nSession, obj.Bins_HT, obj.SBS.HTpdf_FP2', [0 maxHTpdf*1.1]);

                ha11c = axes;
                set(ha11c, "Units", "centimeters", "Position", [xmap(1) ymap(1) axeSize3],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", xTickLabel.Date, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", yTickLabel.HT, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                xlabel("Sessions (dates)", "FontSize", fontSize.Label, "FontName", font);
                ylabel("Hold duration (ms)", "FontSize", fontSize.Label, "FontName", font);
                title("LongFP", "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                imagesc(ha11c, 1:obj.nSession, obj.Bins_HT, obj.SBS.HTpdf_FP3', [0 maxHTpdf*1.1]);

                cbar = colorbar(ha11c, "horiz", "Units", "centimeters", "Position", [xmap(2) ymap(1)-ygap*3/2 cbarSize], ...
                    "FontSize", fontSize.Axes, "FontName", font);
                set(cbar, "TickDirection", "out");
                axesList_Heatmap = [ha11a; ha11b; ha11c];
                if any(idxShade)
                    for i = 1:length(obj.MixedFP)
                        Fig.CurrentAxes = axesList_Heatmap(i);
                        arrow([find(idxShade)' zeros(sum(idxShade),1)], ...
                            [find(idxShade)' 0.2*ones(sum(idxShade), 1)], 'Color', c.Shade, ...
                            'LineWidth', psize.Arrow(1), 'Length', psize.Arrow(2), 'TipAngle', psize.Arrow(3));
                    end
                end

                %% ha12abc, early-late comp
                maxCustompdf = max([obj.CBC.HTpdf_FP1 obj.CBC.HTpdf_FP2 obj.CBC.HTpdf_FP3], [], 'all');

                ha12a = axes;
                set(ha12a, "Units", "centimeters", "Position", [xmap(2) ymap(3) axeSize2],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                    "YLim", xLim.HT, "YTick", xTick.HT, "YTickLabel", {},...
                    "XLim", [0 maxCustompdf*1.1],...
                    "FontSize", fontSize.Axes, "FontName", font);
                % ha12.YAxis.Visible = "off";

                ha12b = axes;
                set(ha12b, "Units", "centimeters", "Position", [xmap(2) ymap(2) axeSize2],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                    "YLim", xLim.HT, "YTick", xTick.HT, "YTickLabel", {},...
                    "XLim", [0 maxCustompdf*1.1], ...
                    "FontSize", fontSize.Axes, "FontName", font);
                                
                ha12c = axes;
                set(ha12c, "Units", "centimeters", "Position", [xmap(2) ymap(1) axeSize2],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                    "YLim", xLim.HT, "YTick", xTick.HT, "YTickLabel", {},...
                    "XLim", [0 maxCustompdf*1.1], ...
                    "FontSize", fontSize.Axes, "FontName", font);
                xlabel("PDF (1/sec)", "FontSize", fontSize.Label, "FontName", font);

                axesList_PDF = [ha12a; ha12b; ha12c];
                
                for i = 1:length(obj.MixedFP)
                    Fig.CurrentAxes = axesList_PDF(i);
                    for j = 1:length(obj.CustomOptions)
                        idx = cbc.Customization == obj.CustomOptions(j);
                        linePDF.("l"+num2str(j)) = plot(cbc(idx,:).("HTpdf_FP"+string(i)), obj.Edges_HT, ...
                            "LineStyle", "-", "LineWidth", psize.CustomLine(j), "Color", c.CustomLine(j,:));
                    end
                    line([0 maxCustompdf*1.1], [FPLineListY(1,i) FPLineListY(1,i)], ...
                        "Color", c.FPLine, "LineStyle", "--", "LineWidth", psize.FPLine);
                    view(0,90);
                end

                %% HT raster (3FP)
                ha13a = axes;
                set(ha13a, "Units", "centimeters", "Position", [xmap(3) ymap(3) axeSize4],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", {}, ...
                    "FontSize", fontSize.Axes, "FontName", font);

                ha13b = axes;
                set(ha13b, "Units", "centimeters", "Position", [xmap(3) ymap(2) axeSize4],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", {}, ...
                    "FontSize", fontSize.Axes, "FontName", font);

                ha13c = axes;
                set(ha13c, "Units", "centimeters", "Position", [xmap(3) ymap(1) axeSize4],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", xTickLabel.Date, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", {}, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                xlabel("Sessions (dates)", "FontSize", fontSize.Label, "FontName", font);

                axesList_HT = [ha13a; ha13b; ha13c];
                for k = 1:length(obj.Sessions)
                    iobj = obj.DataAll{1,k};
                    ksess = obj.Sessions(k);
                    for i = 1:length(iobj.MixedFP)
                        Fig.CurrentAxes = axesList_HT(i);
                        iFP = iobj.MixedFP(i);
                        itbt = tbt(tbt.FP == iFP & tbt.Session == ksess & ...
                            tbt.TimeElapsed<tLim(2) & tbt.TimeElapsed>tLim(1), :);
                        iTErescaled = rescale(itbt.TimeElapsed, 0.05, 0.95);
                        itime = iTErescaled + itbt.Session - 0.5;
                        
                        j = length(obj.OutcomeOptions);
                        while j > 0 % here we use whilt loop to plot correct trials at last
                            idxOutcome = itbt.Outcome == obj.OutcomeOptions(j);
                            scatter(itime(idxOutcome), itbt.HT(idxOutcome,:), psize.Scatter(i), ...
                                c.Perf(j,:), "LineWidth", psize.ScatterLine(i), "MarkerFaceColor", "none");
                            fill([k-0.5 k+0.5 k+0.5 k-0.5], [0 0 iFP iFP], ...
                                c.GapLine, "FaceAlpha", alpha.Shade/2, "EdgeColor", "none");
                            j = j - 1;
                        end
                    end
                end

                %% ha34, reaction time violin plot
                ha14a = axes;
                set(ha14a, "Units", "centimeters", "Position", [xmap(4) ymap(3) axeSize4],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YLim", yLim.RT, "YTick", yTick.RT, "YTickLabel", yTickLabel.RT, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                ylabel("RelT (ms)", "FontSize", fontSize.Label, "FontName", font);
                title("Short FP", "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                
                ha14b = axes;
                set(ha14b, "Units", "centimeters", "Position", [xmap(4) ymap(2) axeSize4],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YLim", yLim.RT, "YTick", yTick.RT, "YTickLabel", yTickLabel.RT, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                ylabel("RelT (ms)", "FontSize", fontSize.Label, "FontName", font);
                title("Mid FP", "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                
                ha14c = axes;
                set(ha14c, "Units", "centimeters", "Position", [xmap(4) ymap(1) axeSize4],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", xTickLabel.Date, ...
                    "YLim", yLim.RT, "YTick", yTick.RT, "YTickLabel", yTickLabel.RT, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                ylabel("RelT (ms)", "FontSize", fontSize.Label, "FontName", font);
                title("Long FP", "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                
                axesList_RT = [ha14a; ha14b; ha14c];

                % revised by hbWang, June/24/2024, for shifted FP task
                idxFP = zeros(size(tbt,1), length(obj.MixedFP));
                for k = 1:obj.nSession
                    kobj = obj.DataAll{1,k};
                    for i = 1:length(kobj.MixedFP)
                        idxFP(:, i) = idxFP(:,i) | tbt.FP == kobj.MixedFP(i);
                    end
                end

                for i = 1:length(obj.MixedFP)
                    Fig.CurrentAxes = axesList_RT(i);
                    idx = idxFP(:,i);
                    violinCue = violinplot(tbt.RelT(idx==1), tbt.Date(idx==1), 'ViolinColor', c.Violin, ...
                        'Width', 0.4, 'ViolinAlpha', alpha.Violin, 'ShowWhiskers', false, ...
                        'BoxColor', c.Whisker, 'BoxWidth', 0.01, 'EdgeColor', c.ViolinEdge);
                    for k = 1:obj.nSession
                        if k <= length(violinCue)
                            violinCue(k).MedianPlot.LineWidth = 1.5;
                            violinCue(k).MedianPlot.SizeData  = 30;
                            violinCue(k).ScatterPlot.MarkerFaceColor = 'k';
                            violinCue(k).ScatterPlot.SizeData = 15;
        %                         violinCue(k).ViolinPlot.FaceColor = c.Violin;
                        end
                    end
                    if i == 3
                        set(gca, "Box", "off", "XTickLabel", xTickLabel.Date);
                    else
                        set(gca, "Box", "off", "XTickLabel", {});
                    end
                    line(FPLineListX, [0.6 0.6], ...
                        "Color", c.FPLine, "LineStyle", "--", "LineWidth", psize.FPLine);
                end

                %% ha41 & ha31, performance
                ha41 = axes;
                set(ha41, "Units", "centimeters", "Position", [xmap(1) ymap(4) axeSize5],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", xTickLabel.Date, ...
                    "YLim", yLim.Perf, "YTick", yTick.Perf2, "YTickLabel", yTickLabel.Perf2, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                ylabel("Performance (%)", "FontSize", fontSize.Label, "FontName", font);
                title("Performance", "FontSize", fontSize.Title, "FontName", font);

                for j = 1:length(obj.OutcomeOptions)
                    jPerf = obj.OutcomeOptions(j);
                    linePerf.("l"+jPerf) = plot(sbs.(jPerf), ...
                        "Color", c.Perf(j,:), "MarkerFaceColor", c.Perf(j,:), ...
                        "LineStyle", "-", "LineWidth", 2);
                    for i = 1:length(obj.MixedFP)
                        plot((1:obj.nSession)-0.3+0.15*i, sbs.(jPerf+"_FP")(:,i), ...
                            'o', "Color", c.Perf(j,:), "MarkerSize", psize.Marker(i));
                    end
                end
                
                %% ha42, progress performance plot
                ha42 = axes;
                set(ha42, "Units", "centimeters", "Position", [xmap(1)+(xgap+axeSize5(1)) ymap(4) axeSize5],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", xTickLabel.Date, ...
                    "YLim", yLim.Perf, "YTick", yTick.Perf2, "YTickLabel", {}, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                % ylabel("Sliding performance (%)", "FontSize", fontSize.Label, "FontName", font);
                title("Sliding performance", "FontSize", fontSize.Title, "FontName", font);

                for j = 1:obj.nSession
                    ijprg = sbs(j,:).("progressPerf");
                    for k = 1:length(obj.OutcomeOptions)
                        kPerf = obj.OutcomeOptions(k);
                        plot(j-0.5+rescale(1:size(ijprg{1,1}, 1), 0.1, 0.9), ijprg{1,1}.(kPerf), ...
                            "Color", c.Perf(k,:), "LineStyle", "-", "LineWidth", 0.5);
                    end
                end

                %% ha43, RelT median
                ha43 = axes;
                set(ha43, "Units", "centimeters", "Position", [xmap(4) ymap(4) axeSize6],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", xTickLabel.Date, ...
                    "YTick", yTick.RT2, "YTickLabel", yTickLabel.RT2, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                ylabel("RelT median (ms)", "FontSize", fontSize.Label, "FontName", font);

                if ha43.YLim(2) < yLim.RT(2)/2
                    set(ha43, "YLim", [0 yLim.RT(2)/2])
                else
                    set(ha43, "YLim", [0 ha43.YLim(2)]);
                end

                for i = 1:length(obj.MixedFP)
                    lineRT.("l"+num2str(i)) = plot(1:obj.nSession, obj.SBS.RelT_FP(:,i), ...
                        style.MarkerStyleFP(i), "LineStyle", "-", "LineWidth", psize.MixedFPs(i), ...
                        "Color", 'k', "MarkerSize", psize.Marker(i));
                end

                %% ha44, RelT IQR
                ha44 = axes;
                set(ha44, "Units", "centimeters", "Position", [xmap(4) ymap(5) axeSize6],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YTick", yTick.RT2, "YTickLabel", yTickLabel.RT2, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                ylabel("RelT IQR (ms)", "FontSize", fontSize.Label, "FontName", font);

                if ha44.YLim(2) < yLim.RT(2)/2
                    set(ha44, "YLim", [0 yLim.RT(2)/2]); 
                else
                    set(ha44, "YLim", [0 ha44.YLim(2)]);
                end

                for i = 1:length(obj.MixedFP)
                    plot(1:obj.nSession, obj.SBS.RelT_IQR_FP(:,i), ...
                        style.MarkerStyleFP(i), "LineStyle", "-", "LineWidth", psize.MixedFPs(i), ...
                        "Color", 'k', "MarkerSize", psize.Marker(i));
                end

                %% Add gaplines and fill shaded backgrounds
                axesList_All = [ha13a; ha13b; ha13c; ha14a; ha14b; ha14c; ha41; ha42; ha43; ha44];
                for i = 1:length(axesList_All)
                    Fig.CurrentAxes = axesList_All(i);
                    curYLim = get(gca, "YLim");
                    if any(idxShade)
                        fill(fillList, [curYLim(1) curYLim(1) curYLim(2) curYLim(2)], c.Shade, ...
                            "FaceAlpha", alpha.Shade, "EdgeColor", "none");
                    end
                    line(GapLineList, curYLim, ...
                        "Color", c.GapLine, "LineStyle", ":", "LineWidth", psize.GapLine);
                end

                %% Add legends
                legendRT = legend(ha44, [lineRT.l1 lineRT.l2 lineRT.l3], string(obj.MixedFP), "Location", "northeast",...
                    "NumColumns", 1, "FontSize", fontSize.Label, "FontName", font, "Box", "off");
                legendRT.ItemTokenSize = [12,15];
                % legendRT.Position = legendRT.Position + [0 0.05 0 0];

                legendPDF = legend(ha12a, [linePDF.l1 linePDF.l2], ["Early", "Late"], "Location", "northeast",...
                    "NumColumns", 1, "FontSize", fontSize.Label, "FontName", font, "Box", "off");
                legendPDF.ItemTokenSize = [12,15];
                legendPDF.Position = legendPDF.Position + [0.02 0.01 0 0];
                
                ha41_copy = axes("Position", get(ha41, "Position"), "Visible", "off");
                legendPerf = legend(ha41_copy, [linePerf.lCor linePerf.lPre linePerf.lLate], obj.OutcomeOptions, ...
                    "FontSize", fontSize.Label, "FontName", font, "NumColumns", 1, "Box", "off");
                legendPerf.ItemTokenSize = [12,15];
                set(legendPerf, "Units", "centimeters", 'Position', [xmap(1)+axeSize5(1)-xgap*1.5 ymap(4)+axeSize4(2)/2 1 1]);


                %% Add info
                ha00 = axes;
                set(ha00, "Units", "centimeters", "Position", [xmap(1)-xstart/2 ymap(6)-ygap/2 axeSizeInfo]);
                axis off;
                title("Subject: "+obj.Subject+"  ("+obj.Group+")"+ ...
                    "        Task: "+obj.Tasks(1)+"        Shaded: "+shadedExp, ...
                    "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
            end

            function Fig = plotLearning2FPs(obj)
                % V2, HT/RT plotted by FPs

                % To plot wait and multiFP stages together:
                %  - renumber session id
                %  - wait task: shortFP ~ 0-0.7s; midFP ~ 0.8-1.4s
                allTasks = unique(obj.Tasks);
                if length(allTasks)>1
                    obj = obj.reNumberSessions("Dates");
                    obj = obj.stat(false);
                end
                obj = obj.stat(true);

                tbt = obj.TBT; sbs = obj.SBS; cbc = obj.CBC;
                if any(ismember(allTasks, ["Wait1Ephys", "Wait2Ephys"]))
                    fp = tbt.FP; newfp = fp;
                    fpmax = max(obj.MixedFP);
                    fplist = [fpmax-0.1 fpmax];
                    for i = 1:length(fp)
                        if ismember(tbt.Task(i), ["Wait1Ephys", "Wait2Ephys"])
                            if fp(i) <= fplist(1)
                                newfp(i) = obj.MixedFP(1);
                            else
                                newfp(i) = obj.MixedFP(2);
                            end
                        end
                    end
                    tbt.FP = newfp;
                end

                % Calculate matrix for shading and lining
                idxShade = obj.Experiments == shadedExp;
                fillList = zeros(obj.nSession, 4); FPLineListX = zeros(obj.nSession, 2);
                for i = 1:obj.nSession
                    fillList(i,:)    = [i-0.5 i+0.5 i+0.5 i-0.5];
                    FPLineListX(i,:) = [i-0.5 i+0.5];
                    FPLineListY(i,:) = obj.DataAll{1,i}.MixedFP;
                end
                fillList = fillList.*(idxShade)';
                % FPLineListY = obj.MixedFP;
                GapLineList = [xTick.Date(1:end-1);xTick.Date(1:end-1)]+0.5;

                xstart = 1.5; ystart = 1.8; xgap = 0.5; ygap = 0.8;

                axeSize1 = [8 4];                                    % cross sessions HT / progress
                axeSize2 = [2 (axeSize1(2)*2-xgap)/3];               % for early-late PDF comparison
                axeSize3 = [axeSize1(1)*3/4 (axeSize1(2)*2-xgap)/3]; % heatmap
                axeSize4 = [axeSize1(1) (axeSize1(2)*2-xgap)/3];     % HT/RT under diff FPs
                axeSize5 = [(axeSize2(1)+axeSize3(1)+axeSize4(1)+xgap)/2 axeSize1(2)];
                axeSize6 = [axeSize4(1) axeSize1(2)*2/3];
                cbarSize = [axeSize2(1) 0.3];                        % for heatmap colorbar
                
                xmap = [xstart, ...
                        xstart + xgap*1 + axeSize3(1), ...
                        xstart + xgap*2 + axeSize3(1) + axeSize2(1), ...
                        xstart + xgap*5 + axeSize3(1) + axeSize2(1) + axeSize4(1), ...
                        xstart + xgap*6 + axeSize3(1) + axeSize2(1) + axeSize4(1)*2];

                axeSizeInfo = [xmap(4)-xmap(1) 0.1];

                ymap = [ystart, ...
                        ystart + ygap*1 + axeSize3(2)*1, ...
                        ystart + ygap*3 + axeSize3(2)*2, ...
                        ystart + ygap*4 + axeSize3(2)*2 + axeSize6(2), ...
                        ystart + ygap*5 + axeSize3(2)*2 + axeSize1(2), ...
                        ystart + ygap*5 + axeSize3(2)*2 + axeSize6(2)*2];

                Fig = figure(1); clf(Fig, "reset");
                set(Fig, "Unit", "centimeters", "PaperPositionMode", "auto", ...
                    "Position", [2 2 xmap(end) ymap(end)], "Color", "w");

                %% ha11abc, holdtime heatmap
                maxHTpdf = max([obj.SBS.HTpdf_FP1 obj.SBS.HTpdf_FP2], [], 'all');

                ha11a = axes;
                set(ha11a, "Units", "centimeters", "Position", [xmap(1) ymap(2) axeSize3],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", yTickLabel.HT, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                % xlabel("Sessions (dates)", "FontSize", fontSize.Label, "FontName", font);
                ylabel("Hold duration (ms)", "FontSize", fontSize.Label, "FontName", font);
                title("Short FP", "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                imagesc(ha11a, 1:obj.nSession, obj.Bins_HT, obj.SBS.HTpdf_FP1', [0 maxHTpdf*1.1]);

                ha11b = axes;
                set(ha11b, "Units", "centimeters", "Position", [xmap(1) ymap(1) axeSize3],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", xTickLabel.Date, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", yTickLabel.HT, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                % xlabel("Sessions (dates)", "FontSize", fontSize.Label, "FontName", font);
                ylabel("Hold duration (ms)", "FontSize", fontSize.Label, "FontName", font);
                title("Long FP", "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                imagesc(ha11b, 1:obj.nSession, obj.Bins_HT, obj.SBS.HTpdf_FP2', [0 maxHTpdf*1.1]);

                cbar = colorbar(ha11b, "horiz", "Units", "centimeters", "Position", [xmap(2) ymap(1)-ygap*3/2 cbarSize], ...
                    "FontSize", fontSize.Axes, "FontName", font);
                set(cbar, "TickDirection", "out");
                axesList_Heatmap = [ha11a; ha11b];
                if any(idxShade)
                    for i = 1:length(obj.MixedFP)
                        Fig.CurrentAxes = axesList_Heatmap(i);
                        arrow([find(idxShade)' zeros(sum(idxShade),1)], ...
                            [find(idxShade)' 0.2*ones(sum(idxShade), 1)], 'Color', c.Shade, ...
                            'LineWidth', psize.Arrow(1), 'Length', psize.Arrow(2), 'TipAngle', psize.Arrow(3));
                    end
                end

                %% ha12abc, early-late comp
                maxCustompdf = max([obj.CBC.HTpdf_FP1 obj.CBC.HTpdf_FP2], [], 'all');

                ha12a = axes;
                set(ha12a, "Units", "centimeters", "Position", [xmap(2) ymap(2) axeSize2],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                    "YLim", xLim.HT, "YTick", xTick.HT, "YTickLabel", {},...
                    "XLim", [0 maxCustompdf*1.1],...
                    "FontSize", fontSize.Axes, "FontName", font);
                % ha12.YAxis.Visible = "off";

                ha12b = axes;
                set(ha12b, "Units", "centimeters", "Position", [xmap(2) ymap(1) axeSize2],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                    "YLim", xLim.HT, "YTick", xTick.HT, "YTickLabel", {},...
                    "XLim", [0 maxCustompdf*1.1], ...
                    "FontSize", fontSize.Axes, "FontName", font);

                axesList_PDF = [ha12a; ha12b];
                
                for i = 1:length(obj.MixedFP)
                    Fig.CurrentAxes = axesList_PDF(i);
                    for j = 1:length(obj.CustomOptions)
                        idx = cbc.Customization == obj.CustomOptions(j);
                        linePDF.("l"+num2str(j)) = plot(cbc(idx,:).("HTpdf_FP"+string(i)), obj.Edges_HT, ...
                            "LineStyle", "-", "LineWidth", psize.CustomLine(j), "Color", c.CustomLine(j,:));
                    end
                    line([0 maxCustompdf*1.1], [FPLineListY(1,i) FPLineListY(1,i)], ...
                        "Color", c.FPLine, "LineStyle", "--", "LineWidth", psize.FPLine);
                    view(0,90);
                end

                %% HT raster (3FP)
                ha13a = axes;
                set(ha13a, "Units", "centimeters", "Position", [xmap(3) ymap(2) axeSize4],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", {}, ...
                    "FontSize", fontSize.Axes, "FontName", font);

                ha13b = axes;
                set(ha13b, "Units", "centimeters", "Position", [xmap(3) ymap(1) axeSize4],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", xTickLabel.Date, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", {}, ...
                    "FontSize", fontSize.Axes, "FontName", font);

                axesList_HT = [ha13a; ha13b];
                for k = 1:length(obj.Sessions)
                    iobj = obj.DataAll{1,k};
                    ksess = obj.Sessions(k);
                    for i = 1:length(iobj.MixedFP)
                        Fig.CurrentAxes = axesList_HT(i);
                        iFP = iobj.MixedFP(i);
                        itbt = tbt(tbt.FP == iFP & tbt.Session == ksess & ...
                            tbt.TimeElapsed<tLim(2) & tbt.TimeElapsed>tLim(1), :);
                        iTErescaled = rescale(itbt.TimeElapsed, 0.05, 0.95);
                        itime = iTErescaled + itbt.Session - 0.5;
                        
                        j = length(obj.OutcomeOptions);
                        while j > 0 % here we use whilt loop to plot correct trials at last
                            idxOutcome = itbt.Outcome == obj.OutcomeOptions(j);
                            scatter(itime(idxOutcome), itbt.HT(idxOutcome,:), psize.Scatter(i), ...
                                c.Perf(j,:), "LineWidth", psize.ScatterLine(i), "MarkerFaceColor", "none");
                            fill([k-0.5 k+0.5 k+0.5 k-0.5], [0 0 iFP iFP], ...
                                c.GapLine, "FaceAlpha", alpha.Shade/2, "EdgeColor", "none");
                            j = j - 1;
                        end
                    end
                end

                %% ha34, reaction time violin plot
                ha14a = axes;
                set(ha14a, "Units", "centimeters", "Position", [xmap(4) ymap(2) axeSize4],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YLim", yLim.RT, "YTick", yTick.RT, "YTickLabel", yTickLabel.RT, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                ylabel("RelT (ms)", "FontSize", fontSize.Label, "FontName", font);
                title("Short FP", "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                
                ha14b = axes;
                set(ha14b, "Units", "centimeters", "Position", [xmap(4) ymap(1) axeSize4],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YLim", yLim.RT, "YTick", yTick.RT, "YTickLabel", yTickLabel.RT, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                ylabel("RelT (ms)", "FontSize", fontSize.Label, "FontName", font);
                title("Long FP", "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                
                axesList_RT = [ha14a; ha14b];

                % revised by hbWang, June/24/2024, for shifted FP task
                idxFP = zeros(size(tbt,1), length(obj.MixedFP));
                for k = 1:obj.nSession
                    kobj = obj.DataAll{1,k};
                    for i = 1:length(kobj.MixedFP)
                        idxFP(:, i) = idxFP(:,i) | tbt.FP == kobj.MixedFP(i);
                    end
                end

                for i = 1:length(obj.MixedFP)
                    Fig.CurrentAxes = axesList_RT(i);
                    idx = idxFP(:,i);
                    violinCue = violinplot(tbt.RelT(idx==1), tbt.Session(idx==1), 'ViolinColor', c.Violin, ...
                        'Width', 0.4, 'ViolinAlpha', alpha.Violin, 'ShowWhiskers', false, ...
                        'BoxColor', c.Whisker, 'BoxWidth', 0.01, 'EdgeColor', c.ViolinEdge);
                    for k = 1:obj.nSession
                        if k <= length(violinCue)
                            violinCue(k).MedianPlot.LineWidth = 1.5;
                            violinCue(k).MedianPlot.SizeData  = 30;
                            violinCue(k).ScatterPlot.MarkerFaceColor = 'k';
                            violinCue(k).ScatterPlot.SizeData = 15;
        %                         violinCue(k).ViolinPlot.FaceColor = c.Violin;
                        end
                    end
                    if i == length(obj.MixedFP)
                        set(gca, "Box", "off", "XTickLabel", xTickLabel.Date);
                    else
                        set(gca, "Box", "off", "XTickLabel", {});
                    end
                    line(FPLineListX, [0.6 0.6], ...
                        "Color", c.FPLine, "LineStyle", "--", "LineWidth", psize.FPLine);
                end

                %% ha41 & ha31, performance
                ha41 = axes;
                set(ha41, "Units", "centimeters", "Position", [xmap(1) ymap(3) axeSize5],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", xTickLabel.Date, ...
                    "YLim", yLim.Perf, "YTick", yTick.Perf2, "YTickLabel", yTickLabel.Perf2, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                ylabel("Performance (%)", "FontSize", fontSize.Label, "FontName", font);
                title("Performance", "FontSize", fontSize.Title, "FontName", font);

                for j = 1:length(obj.OutcomeOptions)
                    jPerf = obj.OutcomeOptions(j);
                    linePerf.("l"+jPerf) = plot(sbs.(jPerf), ...
                        "Color", c.Perf(j,:), "MarkerFaceColor", c.Perf(j,:), ...
                        "LineStyle", "-", "LineWidth", 2);
                    for i = 1:length(obj.MixedFP)
                        plot((1:obj.nSession)-0.3+0.15*i, sbs.(jPerf+"_FP")(:,i), ...
                            'o', "Color", c.Perf(j,:), "MarkerSize", psize.Marker(i));
                    end
                end
                
                %% ha42, progress performance plot
                ha42 = axes;
                set(ha42, "Units", "centimeters", "Position", [xmap(1)+(xgap+axeSize5(1)) ymap(3) axeSize5],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", xTickLabel.Date, ...
                    "YLim", yLim.Perf, "YTick", yTick.Perf2, "YTickLabel", {}, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                % ylabel("Sliding performance (%)", "FontSize", fontSize.Label, "FontName", font);
                title("Sliding performance", "FontSize", fontSize.Title, "FontName", font);

                for j = 1:obj.nSession
                    ijprg = sbs(j,:).("progressPerf");
                    for k = 1:length(obj.OutcomeOptions)
                        kPerf = obj.OutcomeOptions(k);
                        plot(j-0.5+rescale(1:size(ijprg{1,1}, 1), 0.1, 0.9), ijprg{1,1}.(kPerf), ...
                            "Color", c.Perf(k,:), "LineStyle", "-", "LineWidth", 0.5);
                    end
                end

                %% ha43, RelT median
                ha43 = axes;
                set(ha43, "Units", "centimeters", "Position", [xmap(4) ymap(3) axeSize6],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", xTickLabel.Date, ...
                    "YTick", yTick.RT2, "YTickLabel", yTickLabel.RT2, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                ylabel("RelT median (ms)", "FontSize", fontSize.Label, "FontName", font);
                title("RT median errorbar: 95 ci", "FontSize", fontSize.Title, "FontName", font);



                for i = 1:length(obj.MixedFP)
                    lineRT.("l"+num2str(i)) = plot((1:obj.nSession)+0.25*(i-1), obj.SBS.RelT_FP(:,i), ...
                        style.MarkerStyleFP(i), "LineStyle", "-", "LineWidth", psize.MixedFPs(i), ...
                        "Color", 'k', "MarkerSize", psize.Marker(i));
                    xv = (1:obj.nSession)+0.25*(i-1);
                    yv = obj.SBS.RelT_CI95_FP(:, [2*i-1 2*i]);
                    line([xv;xv], yv', "LineStyle", "-", "LineWidth", psize.MixedFPs(i), "Color", 'k');
                end
                
                if ha43.YLim(2) < yLim.RT(2)/2
                    set(ha43, "YLim", [0 yLim.RT(2)/2])
                else
                    set(ha43, "YLim", [0 ha43.YLim(2)]);
                end

                %% ha44, RelT IQR
                ha44 = axes;
                set(ha44, "Units", "centimeters", "Position", [xmap(4) ymap(4) axeSize6],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YTick", yTick.RT2, "YTickLabel", yTickLabel.RT2, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                ylabel("RelT IQR (ms)", "FontSize", fontSize.Label, "FontName", font);

                if ha44.YLim(2) < yLim.RT(2)/2
                    set(ha44, "YLim", [0 yLim.RT(2)/2]); 
                else
                    set(ha44, "YLim", [0 ha44.YLim(2)]);
                end

                for i = 1:length(obj.MixedFP)
                    plot((1:obj.nSession)+0.25*(i-1), obj.SBS.RelT_IQR_FP(:,i), ...
                        style.MarkerStyleFP(i), "LineStyle", "-", "LineWidth", psize.MixedFPs(i), ...
                        "Color", 'k', "MarkerSize", psize.Marker(i));
                end

                %% Add gaplines and fill shaded backgrounds
                axesList_All = [ha13a; ha13b; ha14a; ha14b; ha41; ha42; ha43; ha44];
                for i = 1:length(axesList_All)
                    Fig.CurrentAxes = axesList_All(i);
                    curYLim = get(gca, "YLim");
                    if any(idxShade)
                        fill(fillList, [curYLim(1) curYLim(1) curYLim(2) curYLim(2)], c.Shade, ...
                            "FaceAlpha", alpha.Shade, "EdgeColor", "none");
                    end
                    line(GapLineList, curYLim, ...
                        "Color", c.GapLine, "LineStyle", ":", "LineWidth", psize.GapLine);
                end

                %% Add legends
                legendRT = legend(ha44, [lineRT.l1 lineRT.l2], string(obj.MixedFP), "Location", "northeast",...
                    "NumColumns", 1, "FontSize", fontSize.Label, "FontName", font, "Box", "off");
                legendRT.ItemTokenSize = [12,15];
                % legendRT.Position = legendRT.Position + [0 0.05 0 0];

                legendPDF = legend(ha12a, [linePDF.l1 linePDF.l2], ["Early", "Late"], "Location", "northeast",...
                    "NumColumns", 1, "FontSize", fontSize.Label, "FontName", font, "Box", "off");
                legendPDF.ItemTokenSize = [12,15];
                legendPDF.Position = legendPDF.Position + [0.02 0.01 0 0];
                
                ha41_copy = axes("Position", get(ha41, "Position"), "Visible", "off");
                legendPerf = legend(ha41_copy, [linePerf.lCor linePerf.lPre linePerf.lLate], obj.OutcomeOptions, ...
                    "FontSize", fontSize.Label, "FontName", font, "NumColumns", 1, "Box", "off");
                legendPerf.ItemTokenSize = [12,15];
                set(legendPerf, "Units", "centimeters", 'Position', [xmap(1)+axeSize5(1)-xgap*1.5 ymap(3)+axeSize4(2)/2 1 1]);


                %% Add info
                ha00 = axes;
                set(ha00, "Units", "centimeters", "Position", [xmap(1)-xstart/2 ymap(5)-ygap/2 axeSizeInfo]);
                axis off;
                title("Subject: "+obj.Subject+"  ("+obj.Group+")"+ ...
                    "        Task: "+obj.Tasks(1)+"        Shaded: "+shadedExp, ...
                    "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
            end

            %% Plot learning summary for AutoShaping/LeverPress/Release
            function Fig = plotLearningNaive(obj)
                tbt = obj.TBT;
                idxShade = obj.Experiments == shadedExp;
                fillList = zeros(obj.nSession, 4);
                for i = 1:obj.nSession
                    fillList(i,:) = [i-0.5 i+0.5 i+0.5 i-0.5];
                end
                fillList = fillList.*(idxShade)';
                GapLineList = [xTick.Date(1:end-1);xTick.Date(1:end-1)]+0.5;
                switch obj.Tasks
                    case "AutoShaping"
                        ha1Lim = [0.1 20]; ha2Lim = [-6 10];
                    case {"LeverPress", "LeverRelease"}
                        ha1Lim = [0.5 20]; ha2Lim = [0 10];
                end 
                xstart = 1.5; ystart = 1.8; xgap = 0.5; ygap = 0.8;
                axeSize1 = [2*obj.nSession 4]; % cross sessions HT / progress 
                xmap = [xstart, ...
                        xstart + xgap*1 + axeSize1(1), ...
                        xstart + xgap*2 + axeSize1(1)];
                
                axeSizeInfo = [xmap(end)-xmap(1) 0.5];
                
                ymap = [ystart, ...
                        ystart + ygap*1 + axeSize1(2), ...
                        ystart + ygap*2 + axeSize1(2)*2, ...
                        ystart + ygap*3 + axeSize1(2)*3, ...
                        ystart + ygap*4 + axeSize1(2)*3 + axeSizeInfo(2)];
                
                Fig = figure(1); clf(Fig, "reset");
                set(Fig, "Unit", "centimeters", "PaperPositionMode", "auto", ...
                    "Position", [2 2 xmap(end) ymap(end)], "Color", "w");
                
                ha1 = axes;
                set(ha1, "Units", "centimeters", "Position", [xmap(1) ymap(1) axeSize1], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", xTickLabel.Date, ...
                    "YLim", ha1Lim, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                ylabel("Movement time (s)", "FontSize", fontSize.Label, "FontName", font);
                title("MT raster", "FontSize", fontSize.Title, "FontName", font);
                set(ha1, "YScale", "log");
                j = length(obj.OutcomeOptions);
                while j > 0 % here we use while loop to plot correct trials at last
                    itbt = tbt(tbt.TimeElapsed<tLim(2) & tbt.TimeElapsed>tLim(1), :);
                    iTErescaled = rescale(itbt.TimeElapsed, 0.05, 0.95);
                    itime = iTErescaled + itbt.Session - 0.5;
                    
                    idxOutcome = itbt.Outcome == obj.OutcomeOptions(j);
                    scatter(itime(idxOutcome), itbt.MT(idxOutcome), psize.Scatter(1), ...
                        c.Perf(j,:), "LineWidth", 0.5, "MarkerFaceColor", "none");
                    j = j - 1;
                end

                ha2 = axes;
                set(ha2, "Units", "centimeters", "Position", [xmap(1) ymap(2) axeSize1], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YLim", ha2Lim, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                ylabel("Hold duration (s)", "FontSize", fontSize.Label, "FontName", font);
                title("HT raster", "FontSize", fontSize.Title, "FontName", font);
                % set(ha2, 'YScale', 'log');
                j = length(obj.OutcomeOptions);
                while j > 0 % here we use while loop to plot correct trials at last
                    itbt = tbt(tbt.TimeElapsed<tLim(2) & tbt.TimeElapsed>tLim(1), :);
                    iTErescaled = rescale(itbt.TimeElapsed, 0.05, 0.95);
                    itime = iTErescaled + itbt.Session - 0.5;
                    
                    idxOutcome = itbt.Outcome == obj.OutcomeOptions(j);
                    iFP = itbt.FP(idxOutcome)-5;
                    if obj.OutcomeOptions(j) == "Cor"
                        iFP(iFP==2) = 0;
                    elseif obj.OutcomeOptions(j) == "Pre"
                        iFP(iFP>0) = iFP(iFP>0)-2;
                    end
                    scatter(itime(idxOutcome), sum([iFP itbt.MT(idxOutcome)], 2, 'omitnan'), psize.Scatter(1), ...
                        c.Perf(j,:), "LineWidth", 0.5, "MarkerFaceColor", "none");
                    j = j - 1;
                end

                ha3 = axes;
                set(ha3, "Units", "centimeters", "Position", [xmap(1) ymap(3) axeSize1], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YLim", [0 1], "YTick", [0 0.5 1], "YTickLabel", [0 50 100], ...
                    "FontSize", fontSize.Axes, "FontName", font);
                switch obj.Tasks
                    case "AutoShaping"
                        ylabel("Performance %", "FontSize", fontSize.Label, "FontName", font);
                        title("Sliding performance", "FontSize", fontSize.Title, "FontName", font);
                        % set(ha2, 'YScale', 'log');
                        for i = 1:length(obj.DataAll)
                            iobj = obj.DataAll{i};
                            
                            % sliding performance
                            [x1,y1] = calMovAVG(iobj.Table.TimeElapsed,iobj.Table.Outcome,...
                                'winRatio',6,'stepRatio',3,'tarStr',obj.OutcomeOptions{1});
                            iTErescaled = rescale(x1, 0.05, 0.95);
                            itime = iTErescaled + i - 0.5;

                            mperf1 = sum(strcmp(iobj.Table.Outcome,obj.OutcomeOptions{1}))./length(iobj.Table.Outcome);
                            line([i-0.45 i+0.45], [mperf1,mperf1],...
                                "LineStyle", "--", "Color", cGreen, "LineWidth", 1.5);
                            plot(itime, y1, "o", "LineStyle", "-", "Color", "k", ...
                                "MarkerSize", 5, "LineWidth", 1.2, "MarkerFaceColor", "k",...
                                "MarkerEdgeColor", "w");
                            text(i-0.2, 0.8,sprintf('%.2f',mperf1),...
                                "FontSize", 7, "Color", "k");
                            
                            idxCor = iobj.Table.Outcome == "Cor";
                            idxPre = iobj.Table.Outcome == "Pre";
                            MT_Cor = iobj.Table.MT(idxCor);
                            FP_Pre = iobj.Table.FP(idxPre);
                            idxMT = MT_Cor<3;
                            idxFP = FP_Pre>2;
                            FP_Pre = FP_Pre(idxFP)-5;
                            FP_Pre(FP_Pre>0) = FP_Pre(FP_Pre>0)-2;
                            HT = [MT_Cor(idxMT);FP_Pre];
                            [pdf,~] = histcounts(HT, obj.Edges_HT_A);
                            bh = bar(i-0.5+rescale(obj.Bins_HT_A, 0.2, 0.8), pdf/200, ...
                                 "FaceColor","flat","EdgeColor","none");
                            for j = 1:size(bh.CData,1)
                                if bh.XData(j) < i
                                    bh.CData(j, :) = c.Perf(2,:);
                                else
                                    bh.CData(j, :) = c.Perf(1,:);
                                end
                            end
                        end
                    case {"LeverPress", "LeverRelease"}
                        ylabel("CDF %", "FontSize", fontSize.Label, "FontName", font);
                        title("Cumulative trial num", "FontSize", fontSize.Title, "FontName", font);
                        % set(ha2, 'YScale', 'log');
                        for i = 1:length(obj.DataAll)
                            iobj = obj.DataAll{i};
                            
                            % sliding performance
                            itime = iobj.TimeElapsed;
                            if any(isnan(itime))
                                itime = iobj.iTrial;
                            end
                            iTErescaled = rescale(itime, 0.05, 0.95);
                            itime = iTErescaled + i - 0.5;
                            plot(itime, iobj.iTrial/iobj.iTrial(end), "LineStyle", "-", "Color", "k", ...
                                "MarkerSize", 5, "LineWidth", 1.2, "MarkerFaceColor", "k",...
                                "MarkerEdgeColor", "w");
                            
                            q1 = find(iTErescaled-0.25>0, 1, "first");
                            q2 = find(iTErescaled-0.50>0, 1, "first");
                            q3 = find(iTErescaled-0.75>0, 1, "first");
                            plot([i-0.5 i-0.25], [q1/iobj.iTrial(end) q1/iobj.iTrial(end)], "k-");
                            plot([i-0.5 i],      [q2/iobj.iTrial(end) q2/iobj.iTrial(end)], "k-");
                            plot([i-0.5 i+0.25], [q3/iobj.iTrial(end) q3/iobj.iTrial(end)], "k-");

                            text(i-0.2, q1/iobj.iTrial(end), num2str(100*q1/iobj.iTrial(end), "%.1f"), ...
                                "FontSize", fontSize.Axes, "FontName", font);
                            text(i+0.05, q2/iobj.iTrial(end), num2str(100*q2/iobj.iTrial(end), "%.1f"), ...
                                "FontSize", fontSize.Axes, "FontName", font);
                            text(i+0.3, q3/iobj.iTrial(end), num2str(100*q3/iobj.iTrial(end), "%.1f"), ...
                                "FontSize", fontSize.Axes, "FontName", font);
                        end
                end

                axesList_All = [ha1; ha2; ha3];
                for i = 1:length(axesList_All)
                    Fig.CurrentAxes = axesList_All(i);
                    curYLim = get(gca, "YLim");
                    if any(idxShade)
                        fill(fillList, [curYLim(1) curYLim(1) curYLim(2) curYLim(2)], c.Shade, ...
                            "FaceAlpha", alpha.Shade, "EdgeColor", "none");
                    end
                    if ~isempty(GapLineList)
                        line(GapLineList, curYLim, ...
                            "Color", c.GapLine, "LineStyle", ":", "LineWidth", psize.GapLine);
                    end
                end

                ha00 = axes;
                set(ha00, "Units", "centimeters", "Position", [xmap(1) ymap(end)-ygap*2 axeSizeInfo]);
                axis off;
                title("Subject: "+obj.Subject+" ("+obj.Group+")"+" "+txtTitle, ...
                    "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
            end

            %% Plot comparison results between multi sessions
            function Fig = plotComparison(obj)
                % To use this function, you need to define:
                %   - obj.StatComparison.Options.CompDate
                %     format: {[exp1date1, exp1date2], [exp2date3, exp2date4]}
                %   -                  *.Options.CompExp
                %     format: {[exp1], [exp2]}

                if isempty(obj.cStat)
                    obj = obj.calStatComparison;
                end
                op = obj.StatComparison.Options;
                tbt = obj.StatComparison.TBT;
                sbs = obj.StatComparison.SBS;
                ebe = obj.StatComparison.EBE;
                
                % allFP = cellfun(@(x) x.FP, obj.Meta, "UniformOutput", true);
                allFP = unique(obj.MixedFP, "rows", "sorted");
                for i = 1:2
                    Experiment.("E"+num2str(i)) = obj.Experiments(ismember(obj.Dates, op.CompDate{i}));
                    idxShade.("E"+num2str(i))  = Experiment.("E"+num2str(i)) == shadedExp;
                    allDate.("E"+num2str(i))   = unique(sbs(sbs.Experiment==op.CompExp(i),:).Date);
                    nDate.("E"+num2str(i))     = length(allDate.("E"+num2str(i)));
                    xLim.("DateE"+num2str(i))  = [0.5 0.5+nDate.("E"+num2str(i))];
                    xTick.("DateE"+num2str(i)) = 1:nDate.("E"+num2str(i));
                    xTickLabel.("DateE"+num2str(i)) = num2str(allDate.("E"+num2str(i)));

                    fillList.("E"+num2str(i)) = zeros(nDate.("E"+num2str(i)), 4); 
                    FPLineListX.("E"+num2str(i)) = zeros(nDate.("E"+num2str(i)), 2);
                    for j = 1:nDate.("E"+num2str(i))
                        fillList.("E"+num2str(i))(j,:)    = [j-0.5 j+0.5 j+0.5 j-0.5];
                        FPLineListX.("E"+num2str(i))(j,:) = [j-0.5 j+0.5];
                    end
                    fillList.("E"+num2str(i)) = fillList.("E"+num2str(i)).*(idxShade.("E"+num2str(i)))';
                    FPLineListY.("E"+num2str(i)) = (ismember(obj.Dates, op.CompDate{i})).*allFP';
                    GapLineList.("E"+num2str(i)) = [xTick.("DateE"+num2str(i))(1:end-1);
                                                    xTick.("DateE"+num2str(i))(1:end-1)]+0.5;
                end

                xstart = 1.5; ystart = 1.5; xgap = 0.6; ygap = 0.6;

                axeSize1 = [6 4]; % HT rasters
                axeSize2 = [(axeSize1(1)+2*xgap)/2 (axeSize1(2)*2-2*ygap)/3]; % sliding perf
                
                xmap = [xstart, ...
                        xstart + xgap*1 + axeSize1(1)*1, ...
                        xstart + xgap*2 + axeSize1(1)*2, ...
                        xstart + xgap*4 + axeSize1(1)*3, ...
                        xstart + xgap*5 + axeSize1(1)*3 + axeSize2(1)*1, ...
                        xstart + xgap*6 + axeSize1(1)*3 + axeSize2(1)*2, ...
                        xstart + xgap*7 + axeSize1(1)*3 + axeSize2(1)*3];
                xlen = axeSize1(1)*3 + axeSize2(1)*3 - xgap*6;

                axeSize3 = [xlen*3/15 xlen*3/15]; % violin, pdf, cdf
                axeSize4 = [xlen*2/15 xlen*2/15]; % performance pattern
                
                xmap2 = [xstart, ...
                         xstart + xgap*1.5 + axeSize4(1), ...
                         xstart + xgap*3 + axeSize4(1)*2, ...
                         xstart + xgap*5 + axeSize4(1)*3, ...
                         xstart + xgap*7 + axeSize4(1)*3 + axeSize3(1)*1, ...
                         xstart + xgap*9 + axeSize4(1)*3 + axeSize3(1)*2, ...
                         xstart + xgap*11 + axeSize4(1)*3 + axeSize3(1)*3];

                axeSizeInfo = [axeSize4(2)*3+xgap*3 1];

                ymap = [ystart, ...
                        ystart + ygap*2 + axeSize2(2), ...
                        ystart + ygap*2 + axeSize1(2), ...
                        ystart + ygap*4 + axeSize2(2)*2, ...
                        ystart + ygap*7 + axeSize2(2)*3, ...
                        ystart + ygap*8 + axeSize2(2)*3 + axeSize4(2), ...
                        ystart + ygap*9 + axeSize2(2)*3 + axeSize3(2), ...
                        ystart + ygap*9 + axeSize2(2)*3 + axeSize3(2) + axeSizeInfo(2)];
                Fig = figure(1); clf(Fig, "reset");
                set(Fig, "Unit", "centimeters",'paperpositionmode','auto',...
                    "Position", [2 2 xmap(end) ymap(end)], "Color", "w",'renderer','painter');
                
                 
                %% Patterns under two experiment conditions
                idxE1 = ebe.Experiment == op.CompExp(1);
                idxE2 = ebe.Experiment == op.CompExp(2);

                ha51 = axes;
                set(ha51, "Units", "centimeters", "Position", [xmap2(1) ymap(5) axeSize4],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                    "XLim", yLim.Perf, "XTick", yTick.Perf, "XTickLabel", yTickLabel.Perf, ...
                    "YLim", yLim.Perf, "YTick", yTick.Perf, "YTickLabel", yTickLabel.Perf,...
                    "FontSize", fontSize.Axes, "FontName", font);
                xlabel(op.CompExp(1), "FontSize", fontSize.Label, "FontName", font);
                ylabel(op.CompExp(2), "FontSize", fontSize.Label, "FontName", font);
                title("Performance", "FontSize", fontSize.Label, "FontName", font);
                line(yLim.Perf, yLim.Perf, "Color", "k", "LineStyle", "-.", "LineWidth", 1);
                                  
                for j = 1:length(obj.OutcomeOptions)
                    jOut = obj.OutcomeOptions(j);
                    for i = 1:length(obj.MixedFP)
                        linePerf.("l"+num2str(i)+jOut) = scatter(ebe.(jOut+"_FP")(idxE1,i), ebe.(jOut+"_FP")(idxE2,i), ...
                            psize.Scatter(i), "filled", "MarkerFaceColor", c.Perf(j,:), "MarkerFaceAlpha", alpha.Scatter, "MarkerEdgeColor", "none");
                    end
                    plot(ebe.(jOut)(idxE1), ebe.(jOut)(idxE2), "^", ...
                        "MarkerSize", psize.Marker(2), "MarkerFaceColor", c.Perf(j,:), "MarkerEdgeColor", 'k');
                end

                ha52 = axes;
                set(ha52, "Units", "centimeters", "Position", [xmap2(2) ymap(5) axeSize4],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                    "XLim", xLim.RT*2/3, "XTick", xTick.RT2, "XTickLabel", xTickLabel.RT2, ...
                    "YLim", yLim.RT*2/3, "YTick", yTick.RT2, "YTickLabel", yTickLabel.RT2, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                xlabel(op.CompExp(1), "FontSize", fontSize.Label, "FontName", font);
                title("RT", "FontSize", fontSize.Label, "FontName", font);
                line(xLim.RT, yLim.RT, "Color", "k", "LineStyle", "-.", "LineWidth", 1);
                    
                for i = 1:length(obj.MixedFP)
                    lineHT.("l"+num2str(i)) = scatter(ebe.RelT_FP(idxE1,i), ebe.RelT_FP(idxE2,i), psize.Scatter(i)+10, "filled",...
                        "MarkerFaceColor", 'k', "MarkerFaceAlpha", alpha.Scatter, "MarkerEdgeColor", "none");
                end
                lineHT.l0 = plot(ebe.RelT(idxE1), ebe.RelT(idxE2), "^", "MarkerSize", psize.Marker(2), ...
                    "MarkerFaceColor", "none", "MarkerEdgeColor", 'k');

                ha53 = axes;
                set(ha53, "Units", "centimeters", "Position", [xmap2(3) ymap(5) axeSize4], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen, ...
                    "XLim", xLim.RT/2, "XTick", xTick.RT2, "XTickLabel", xTickLabel.RT2, ...
                    "YLim", yLim.RT/2, "YTick", yTick.RT2, "YTickLabel", yTickLabel.RT2, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                xlabel(op.CompExp(1), "FontSize", fontSize.Label, "FontName", font);
                title("RT IQR", "FontSize", fontSize.Label, "FontName", font);
                line(xLim.RT, yLim.RT, "Color", "k", "LineStyle", "-.", "LineWidth", 1);
                
                for i = 1:length(obj.MixedFP)
                    lineHT.("l"+num2str(i)) = scatter(ebe.RelT_IQR_FP(idxE1,i), ebe.RelT_IQR_FP(idxE2,i), psize.Scatter(i)+10, "filled",...
                        "MarkerFaceColor", 'k', "MarkerFaceAlpha", alpha.Scatter, "MarkerEdgeColor", "none");
                end
                lineHT.l0 = plot(ebe.RelT_IQR(idxE1), ebe.RelT_IQR(idxE2), "^", "MarkerSize", psize.Marker(2), ...
                    "MarkerFaceColor", "none", "MarkerEdgeColor", 'k');

                ha54 = axes;
                set(ha54, "Units", "centimeters", "Position", [xmap2(4) ymap(5) axeSize3], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", yTickLabel.HT, ...
                    "FontSize", fontSize.Axes, "FontName", font);
%                 xlabel("   Cue              Uncue", "FontSize", fontSize.Label, "FontName", font)
                ylabel("Holdtime (ms)", "FontSize", fontSize.Label, "FontName", font);
                cnt = 1; HTcat = []; cats = []; nFP = length(obj.MixedFP);
                for i = 1:length(obj.MixedFP)
                    for j = 1:length(op.CompExp)
                        idx = tbt.FP==obj.MixedFP(i) & tbt.Experiment==op.CompExp(j);
                        HTcat = [HTcat; tbt(idx,:).HT];
                        cats = [cats; repmat(cnt,sum(idx),1)];
                        cnt = cnt + 1;
                    end
                end
                violinHT = violinplot(HTcat, cats, ...
                    'Width', 0.4, 'ViolinAlpha', alpha.Violin, 'ShowWhiskers', false, ...
                    'BoxColor', c.Whisker, 'BoxWidth', 0.01, 'EdgeColor', c.ViolinEdge);
                for iv = 1:length(violinHT)
                    if rem(iv, 2)~=0
                        violinHT(iv).ScatterPlot.MarkerFaceColor = c.Exp(1,:);
                    else
                        violinHT(iv).ScatterPlot.MarkerFaceColor = c.Exp(2,:);
                    end
                    violinHT(iv).EdgeColor = c.Violin;
                    violinHT(iv).ScatterPlot.MarkerFaceAlpha = 0.35;
                    violinHT(iv).ScatterPlot.SizeData = 10;
                    violinHT(iv).ViolinPlot.LineWidth = 1.5;
                    violinHT(iv).ViolinPlot.FaceColor = c.Violin;
                end
                set(ha54, "Box", "off", "XLim", 0.5+[0 2*nFP], "XTick", 1:2*nFP, ...
                    "XTickLabel", [op.CompExp op.CompExp]);
                line(0.5+2*[0:nFP-1; 1:nFP], [obj.MixedFP; obj.MixedFP], ...
                    "Color", c.FPLine, "LineStyle", "--", "LineWidth", psize.FPLine);
                
                ha55 = axes;
                set(ha55, "Units", "centimeters", "Position", [xmap2(5) ymap(5) axeSize3], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen, ...
                    "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, ...
                    "YLim", [0 1], ...
                    "FontSize", fontSize.Axes, "FontName", font);
                xlabel("Holdtime (ms)", "FontSize", fontSize.Label, "FontName", font)
                ylabel("CDF", "FontSize", fontSize.Label, "FontName", font);
                for i = 1:length(obj.MixedFP)
                    for j = 1:length(op.CompExp)
                        idx = ebe.Experiment == op.CompExp(j);
                        plot(obj.Bins_HT, ebe(idx,:).("HTcdf_FP"+num2str(i)), ...
                            "LineStyle", style.LineStyleFP(i), "LineWidth", psize.MixedFPs(i), "Color", c.Exp(j,:));
                    end
                end
                curYLim = get(gca, "YLim");
                line([obj.MixedFP;obj.MixedFP], curYLim, ...
                    "Color", c.FPLine, "LineStyle", "--", "LineWidth", psize.FPLine);

                ha56 = axes;
                set(ha56, "Units", "centimeters", "Position", [xmap2(6) ymap(5) axeSize3], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen, ...
                    "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                xlabel("Holdtime (ms)", "FontSize", fontSize.Label, "FontName", font)
                ylabel("PDF (1/s)", "FontSize", fontSize.Label, "FontName", font);
                for i = 1:length(obj.MixedFP)
                    for j = 1:length(op.CompExp)
                        idx = ebe.Experiment == op.CompExp(j);
                        linePDF.("l"+num2str(i)+num2str(j)) = plot(obj.Bins_HT, ebe(idx,:).("HTpdf_FP"+num2str(i)), ...
                            "LineStyle", style.LineStyleFP(i), "LineWidth", psize.MixedFPs(i), "Color", c.Exp(j,:));
                    end
                end
                curYLim = get(gca, "YLim");
                line([obj.MixedFP;obj.MixedFP], curYLim, ...
                    "Color", c.FPLine, "LineStyle", "--", "LineWidth", psize.FPLine);

                %% ha33, 34, 43, 44: holdtime scatter plot
                ha13 = axes("NextPlot", "add", "Units", "centimeters", ...
                    "Position", [xmap(1) ymap(1) axeSize1]);
                ha14 = axes("NextPlot", "add", "Units", "centimeters", ...
                    "Position", [xmap(2) ymap(1) axeSize1]);
                ha15 = axes("NextPlot", "add", "Units", "centimeters", ...
                    "Position", [xmap(3) ymap(1) axeSize1]);
                ha14.YAxis.Visible = "off"; ha15.YAxis.Visible = "off";

                ha23 = axes("NextPlot", "add", "Units", "centimeters", ...
                    "Position", [xmap(1) ymap(3) axeSize1]);
                ha24 = axes("NextPlot", "add", "Units", "centimeters", ...
                    "Position", [xmap(2) ymap(3) axeSize1]);
                ha25 = axes("NextPlot", "add", "Units", "centimeters", ...
                    "Position", [xmap(3) ymap(3) axeSize1]);
                ha24.YAxis.Visible = "off"; ha25.YAxis.Visible = "off";

                axesList_HT = [ha23 ha24 ha25; ha13 ha14 ha15];

                for i = 1:length(obj.MixedFP)
                    iFP = obj.MixedFP(i);

                    for j = 1:length(op.CompExp)
                        Fig.CurrentAxes = axesList_HT(j,i);
                        ijtbt = tbt(tbt.FP == iFP & tbt.Experiment == op.CompExp(j) &...
                            tbt.TimeElapsed<tLim(2) & tbt.TimeElapsed>tLim(1), :);
                        [~,~,ijSession] = unique(ijtbt.Session);
                        ijTErescaled = rescale(ijtbt.TimeElapsed, 0.05, 0.95); 
                        ijtime = ijTErescaled + ijSession - 0.5;
                        for k = 1:length(obj.OutcomeOptions)
                            idxOutcome = ijtbt.Outcome == obj.OutcomeOptions(k);
                            scatter(ijtime(idxOutcome), ijtbt.HT(idxOutcome,:), psize.Scatter(i), ...
                                c.Perf(k,:), "filled", "MarkerFaceAlpha", alpha.Scatter);
                        end
                        line([xLim.("DateE"+num2str(j))(1) xLim.("DateE"+num2str(j))(end)], [iFP, iFP], ...
                            "Color", c.FPLine, "LineStyle", "--", "LineWidth", psize.FPLine);
                        set(axesList_HT(j,i), "TickDir", "out", "TickLength", tickLen,...
                            "XLim", xLim.("DateE"+num2str(j)), "XTick", xTick.("DateE"+num2str(j)), ...
                            "XTickLabel", xTickLabel.("DateE"+num2str(j)), ...
                            "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", yTickLabel.HT, ...
                            "FontSize", fontSize.Axes, "FontName", font);
                        title("FP "+string(obj.MixedFP(i))+" | "+op.CompExp(j), ...
                            "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                        fill(fillList.("E"+num2str(j))', [yLim.HT(1) yLim.HT(1) yLim.HT(2) yLim.HT(2)], c.Shade, ...
                            "FaceAlpha", alpha.Shade, "EdgeColor", "none");
                        if ~isempty(GapLineList.("E"+num2str(j)))
                            line(GapLineList.("E"+num2str(j)), yLim.HT, ...
                                "Color", c.GapLine, "LineStyle", ":", "LineWidth", psize.GapLine);
                        end
                    end
                end

                xlabel(ha13, "Sessions (dates)", "FontSize", fontSize.Label, "FontName", font);
                ylabel(ha13, "HT (ms)", "FontSize", fontSize.Label, "FontName", font);
                xlabel(ha14, "Sessions (dates)", "FontSize", fontSize.Label, "FontName", font);
                xlabel(ha15, "Sessions (dates)", "FontSize", fontSize.Label, "FontName", font);
                ylabel(ha23, "HT (ms)", "FontSize", fontSize.Label, "FontName", font);

                if ~plotProgressCompare
                    %% ha31/32, 41/42, 51/52: mean of progress performance
                    % Late
                    ha11 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(4) ymap(1) axeSize2]);
                    ha12 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(5) ymap(1) axeSize2]);
                    ha13 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(6) ymap(1) axeSize2]);
                    ha12.YAxis.Visible = "off"; ha13.YAxis.Visible = "off";
                    % Premature
                    ha21 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(4) ymap(2) axeSize2]);
                    ha21.XAxis.Visible = "off";
                    ha22 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(5) ymap(2) axeSize2]);
                    ha22.XAxis.Visible = "off"; ha22.YAxis.Visible = "off";
                    ha23 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(6) ymap(2) axeSize2]);
                    ha23.XAxis.Visible = "off"; ha23.YAxis.Visible = "off";
                    % Correct
                    ha31 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(4) ymap(4) axeSize2]);
                    ha31.XAxis.Visible = "off"; 
                    ha32 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(5) ymap(4) axeSize2]);
                    ha32.XAxis.Visible = "off"; ha32.YAxis.Visible = "off";
                    ha33 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(6) ymap(4) axeSize2]);
                    ha33.XAxis.Visible = "off"; ha33.YAxis.Visible = "off";
    
                    axesList_Prg = [ha31 ha32 ha33; ha21 ha22 ha23; ha11 ha12 ha13];
                    prgLim.Cor = [0.6 1.0]; prgLim.Pre = [0 0.2]; prgLim.Late = [0 0.2];
                    for i = 1:length(obj.MixedFP)
                        iPrgPerf = sbs.("progressPerf_FP"+num2str(i));
                        iPrgSize = cellfun(@(x) size(x,1), iPrgPerf, "UniformOutput", true);
                        minPrgLen = min(iPrgSize);
                        iPrgPerf = cellfun(@(x) x(1:minPrgLen,:), iPrgPerf, "UniformOutput", false);
                        for j = 1:length(obj.OutcomeOptions)
                            jOut = obj.OutcomeOptions(j);
                            Fig.CurrentAxes = axesList_Prg(j,i);
                            % ijPrgOutcome: all sessions' progress performance
                            ijPrgOutcome = cell2mat(cellfun(@(x) x.(jOut)', iPrgPerf, "UniformOutput", false));
                            for k = 1:2
                                ijkPrg = ijPrgOutcome(sbs.Experiment==op.CompExp(k), :);
                                ijkPrg_mean = mean(ijkPrg, 1);
                                ijkPrg_sem = std(ijkPrg, 0, 1)/sqrt(size(ijkPrg,1));
                                ijkPrg_shade = [ijkPrg_mean-ijkPrg_sem;ijkPrg_mean+ijkPrg_sem];
                                plotshaded(1:length(ijkPrg_shade), ijkPrg_shade, c.Exp(k,:));
                                plot(ijkPrg_mean, "Color", c.Exp(k,:), "LineStyle", style.LineStyleFP(i), "LineWidth", psize.MixedFPs(i));
                                prgLim.(jOut) = [min([min(ijkPrg_shade,[],"all") prgLim.(jOut)(1)]), ...
                                    max([max(ijkPrg_shade,[],"all") prgLim.(jOut)(2)])];
                            end
                            set(axesList_Prg(j,:), "YLim", prgLim.(jOut));
                            set(axesList_Prg(j,i), "TickDir", "out", "TickLength", tickLen,...
                                "XLim", [0.5 minPrgLen], "XTick", 0.5:5:minPrgLen, ...
                                "XTickLabel", num2str(20+(0.5:5:minPrgLen)'*10), ...
                                "YTick", yTick.Perf2, "YTickLabel", yTickLabel.Perf2, ...
                                "FontSize", fontSize.Axes, "FontName", font);
                        end
                    end
    
                    xlabel(ha11, "Trials in session", "Units", "centimeters", ...
                        "FontSize", fontSize.Label, "FontName", font);
                    ha11.XLabel.Position(1) = ha11.XLabel.Position(1)+(axeSize2(1)+xgap)/2;
                    ylabel(ha11, "Late (%)", "FontSize", fontSize.Label, "FontName", font);
                    ylabel(ha21, "Pre (%)", "FontSize", fontSize.Label, "FontName", font);
                    ylabel(ha31, "Cor (%)", "FontSize", fontSize.Label, "FontName", font);
                    title(ha31, "Short", "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                    title(ha32, "Mid", "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                    title(ha32, "Long", "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");

                else
                    %% Progress compare between session pairs
                    if nDate.E1 ~= nDate.E2
                        error("Session numbers under two experiment conditions are not equal.");
                    end
                    axeSize5 = [axeSize1(1)*0.8 (axeSize1(2)*2-ygap)/3];
                    xmap(5) = xmap(4) + xgap + axeSize5(1);
                    xmap(6) = xmap(5) + xgap + axeSize5(1);
                    xmap(7) = xmap(6) + xgap + axeSize5(1);
                    set(Fig, "Position", [2 2 xmap(end) ymap(end)]);
                    ymap2 = [ystart + ygap, ...
                             ystart + ygap*2 + axeSize5(2), ...
                             ystart + ygap*3 + axeSize5(2)*2];
                    % Late
                    hb1 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(4) ymap2(1) axeSize5]);
                    hb4 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(5) ymap2(1) axeSize5]);
                    hb4.YAxis.Visible = "off";
                    hb7 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(6) ymap2(1) axeSize5]);
                    hb7.YAxis.Visible = "off";
                    % Premature
                    hb2 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(4) ymap2(2) axeSize5]);
                    hb2.XAxis.Visible = "off";
                    hb5 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(5) ymap2(2) axeSize5]);
                    hb5.XAxis.Visible = "off"; hb5.YAxis.Visible = "off";
                    hb8 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(6) ymap2(2) axeSize5]);
                    hb8.XAxis.Visible = "off"; hb8.YAxis.Visible = "off";
                    % Correct
                    hb3 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(4) ymap2(3) axeSize5]);
                    hb3.XAxis.Visible = "off"; 
                    hb6 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(5) ymap2(3) axeSize5]);
                    hb6.XAxis.Visible = "off"; hb6.YAxis.Visible = "off";
                    hb9 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(6) ymap2(3) axeSize5]);
                    hb9.XAxis.Visible = "off"; hb9.YAxis.Visible = "off";

                    axesList_Prg2 = [hb3 hb6 hb9; hb2 hb5 hb8; hb1 hb4 hb7];
                    prgLim.Cor = [0.6 1.0]; prgLim.Pre = [0 0.2]; prgLim.Late = [0 0.2];
                    for i = 1:length(obj.MixedFP)
                        iPrgPerf = sbs.("progressPerf_FP"+num2str(i));
                        iPrgSize = cellfun(@(x) size(x,1), iPrgPerf, "UniformOutput", true);
                        minPrgLen = min(iPrgSize);
                        iPrgPerf = cellfun(@(x) x(1:minPrgLen,:), iPrgPerf, "UniformOutput", false);
                        for j = 1:length(obj.OutcomeOptions)
                            jOut = obj.OutcomeOptions(j);
                            Fig.CurrentAxes = axesList_Prg2(j,i);
                            % ijPrgOutcome: all sessions' progress performance
                            ijPrgOutcome = cell2mat(cellfun(@(x) x.(jOut)', iPrgPerf, "UniformOutput", false));
                            for k = 1:2
                                ijkPrg = ijPrgOutcome(sbs.Experiment==op.CompExp(k), :);
                                xprg = rescale(1:minPrgLen, 0.05, 0.95);
                                addon = repmat((1:nDate.("E"+num2str(k)))-0.5,minPrgLen,1)+xprg';
                                plot(addon, ijkPrg', "Color", c.Exp(k,:), "LineStyle", style.LineStyleFP(i), "LineWidth", psize.MixedFPs(i));
                                prgLim.(jOut) = [min([min(ijkPrg,[],"all") prgLim.(jOut)(1)]), ...
                                    max([max(ijkPrg,[],"all") prgLim.(jOut)(2)])];
                            end
                            set(axesList_Prg2(j,:), "YLim", prgLim.(jOut));
                            xtlabeltext = [xTickLabel.DateE1, repmat('\newline      vs.\newline', nDate.E1, 1), xTickLabel.DateE2];
                            set(axesList_Prg2(j,i), "TickDir", "out", "TickLength", tickLen,...
                                "XLim", xLim.DateE1, "XTick", xTick.DateE1, ...
                                "XTickLabel", xtlabeltext, ...
                                "YTick", yTick.Perf2, "YTickLabel", yTickLabel.Perf2, ...
                                "FontSize", fontSize.Axes, "FontName", font);
                            if ~isempty(GapLineList.E1)
                                line(GapLineList.E1, prgLim.(jOut), ...
                                    "Color", c.GapLine, "LineStyle", ":", "LineWidth", psize.GapLine);
                            end
                        end
                    end
                    xlabel(hb1, "Trials in session", "Units", "centimeters", ...
                        "FontSize", fontSize.Label, "FontName", font);
                    hb1.XLabel.Position(1) = hb1.XLabel.Position(1)+(axeSize5(1)+xgap)/2;
                    ylabel(hb1, "Late (%)", "FontSize", fontSize.Label, "FontName", font);
                    ylabel(hb2, "Pre (%)", "FontSize", fontSize.Label, "FontName", font);
                    ylabel(hb3, "Cor (%)", "FontSize", fontSize.Label, "FontName", font);
                    title(ha31, "Short", "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                    title(ha32, "Mid", "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                    title(ha32, "Long", "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                end

                %% Add legends
                legendPerf = legend(ha51, [linePerf.l1Cor linePerf.l1Pre linePerf.l1Late lineHT.l0], ...
                    [obj.OutcomeOptions "All"], ...
                    "FontSize", fontSize.Label, "FontName", font, "NumColumns", 6, "Box", "off");
                legendPerf.ItemTokenSize = [12,15];
                set(legendPerf, "Units", "centimeters", 'Position', [xmap2(1)-xgap ymap(6) xmap2(4)-xmap2(1)-2*xgap 1]);
              
                legendPDF = legend(ha56, [linePDF.l11 linePDF.l12], op.CompExp,...
                    "NumColumns", 1, "FontSize", fontSize.Label, "FontName", font, "Box", "off");
                legendPDF.ItemTokenSize = [12,15];
                set(legendPDF, "Units", "centimeters", 'Position', [xmap2(6)+axeSize3(1)/2 ymap(6)-ygap axeSize3(1)/2+2*xgap 1]);

                %% Add info

                uicontrol(Fig, "Style", "text", "Units", "centimeters", "BackgroundColor", "w", ...
                    "Position", [xmap2(1) ymap(7)-ygap axeSizeInfo], "HorizontalAlignment", "left", ...
                    "String", obj.Subject+"  |  "+unique(obj.Tasks)+"  |  "+op.CompExp(1)+" vs. "+op.CompExp(2), ...
                    "FontSize", fontSize.Info, "FontWeight", "bold", "FontName", font);
            end
            
            %% Plot recovery figure before/after lesions
            function Fig = plotRecovery(obj)

                temp = obj.reNumberSessions("Experiments", expName);
                xTickLabel.reNum = temp.Sessions; clear temp;

                tbt = obj.sampleTrials("trialNum", trialNum, "smplMark", sampleMarks, "exp", sampleExps);
                tbt = tbt(tbt.TimeElapsed<tLim(2) & tbt.TimeElapsed>tLim(1), :);

                idxShade = obj.Experiments == shadedExp;
                fillList = zeros(obj.nSession, 4); FPLineListX = zeros(obj.nSession, 2);
                for i = 1:obj.nSession
                    fillList(i,:)    = [i-0.5 i+0.5 i+0.5 i-0.5];
                    FPLineListX(i,:) = [i-0.5 i+0.5];
                end
                fillList = fillList.*(idxShade)';
                FPLineListY = obj.MixedFP;
                GapLineList = [xTick.Date(1:end-1);xTick.Date(1:end-1)]+0.5;

                xstart = 1.5; ystart = 1.3; xgap = 0.5; ygap = 0.6;

                axeSize1 = [15 4];                                            % cross sessions HT raster
                axeSize2 = [(axeSize1(1)-xgap*2)/3 (axeSize1(2)*3-ygap*1)/4]; % for HT raster
                axeSize3 = [axeSize2(1) axeSize2(1)*0.8];                     % for PDF comparison
                axeSizeInfo = [axeSize1(1) 0.1];

                xmap = [xstart, ...
                        xstart + xgap*3 + axeSize1(1), ...
                        xstart + xgap*4 + axeSize1(1) + axeSize2(1), ...
                        xstart + xgap*5 + axeSize1(1) + axeSize2(1)*2, ...
                        xstart + xgap*6 + axeSize1(1) + axeSize2(1)*3];

                ymap = [ystart, ...
                        ystart + ygap*1 + axeSize1(2), ...
                        ystart + ygap*2 + axeSize1(2)*2, ...
                        ystart + ygap*3 + axeSize1(2)*3];

                ymap2 = [ystart, ...
                         ystart + ygap*1 + axeSize2(2), ...
                         ystart + ygap*2 + axeSize2(2)*2, ...
                         ystart + ygap*3 + axeSize2(2)*3, ...
                         ystart + ygap*4 + axeSize2(2)*3 + axeSize3(2)];

                Fig = figure(1); clf(Fig, "reset");
                set(Fig, "Unit", "centimeters", "PaperPositionMode", "auto", ...
                    "Position", [2 2 xmap(end) ymap2(end)], "Color", "w");

                %% ha11/12/13 holdtime raster for all sessions
                ha11 = axes;
                set(ha11, "Units", "centimeters", "Position", [xmap(1) ymap(1) axeSize1], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", xTickLabel.reNum, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", yTickLabel.HT, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                xlabel("Session # relative to lesion", "FontSize", fontSize.Label, "FontName", font);
                ylabel("Press duration (ms)", "FontSize", fontSize.Label, "FontName", font);

                ha12 = axes;
                set(ha12, "Units", "centimeters", "Position", [xmap(1) ymap(2) axeSize1], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", xTickLabel.reNum, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", yTickLabel.HT, ...
                    "FontSize", fontSize.Axes, "FontName", font);

                ha13 = axes;
                set(ha13, "Units", "centimeters", "Position", [xmap(1) ymap(3) axeSize1], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", xTickLabel.reNum, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", yTickLabel.HT, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                % title("Press duration raster", "FontSize", fontSize.Title, "FontName", font);

                allAxes = [ha11; ha12; ha13];

                for i = 1:length(obj.MixedFP)
                    Fig.CurrentAxes = allAxes(i);

                    iFP = obj.MixedFP(i);
                    itbt = tbt(tbt.FP == iFP, :);
                    iTErescaled = rescale(itbt.TimeElapsed, 0.05, 0.95);
                    itime = iTErescaled + itbt.Session - 0.5;
                    for j = 1:length(sampleMarks)
                        idxSampled = itbt.Sampled == sampleMarks(j);
                        scatter(itime(idxSampled), itbt.HT(idxSampled,:), psize.Scatter(i), ...
                            c.Samples(2,:), "filled"); % hbWang, Nov/17/2023
                    end
                    line(FPLineListX, [FPLineListY(i) FPLineListY(i)], ...
                        "Color", c.FPLine, "LineStyle", "-.", "LineWidth", psize.FPLine);
                    idxUnsampled = itbt.Sampled == 0;
                    scatter(itime(idxUnsampled), itbt.HT(idxUnsampled,:), psize.Scatter(i), ...
                        c.Unsampled, "filled", "MarkerFaceAlpha", alpha.MixedFPs(i));

                    curYLim = get(gca, "YLim");
                    if any(idxShade)
                        fill(fillList, [curYLim(1) curYLim(1) curYLim(2) curYLim(2)], c.Shade, ...
                            "FaceAlpha", alpha.Shade, "EdgeColor", "none");
                    end
                    line(GapLineList, curYLim, ...
                        "Color", c.GapLine, "LineStyle", ":", "LineWidth", psize.GapLine);
                end

                %% hbij, holdtime raster for each FP and each stage
                 % and hc, holdtime pdf for each stage
                for i = 1:length(obj.MixedFP)
                    iFP = obj.MixedFP(i);
                    itbt = tbt(tbt.FP == iFP, :);

                    h.("c"+num2str(i)) = axes;
                    set(h.("c"+num2str(i)), "Units", "centimeters", "Position", [xmap(i+1) ymap2(4) axeSize3], ...
                            "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                            "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, ...
                            "FontSize", fontSize.Axes, "FontName", font);
                    for j = 1:length(sampleMarks)
                        jNum = trialNum(j);
                        h.("b"+num2str(i)+num2str(j)) = axes;
                        set(h.("b"+num2str(i)+num2str(j)), "Units", "centimeters", "Position", [xmap(i+1) ymap2(j) axeSize2], ...
                            "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                            "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, ...
                            "YLim", [0 jNum], "FontSize", fontSize.Axes, "FontName", font);
                        idxSampled = itbt.Sampled == sampleMarks(j);
                        scatter(itbt.HT(idxSampled), 1:sum(idxSampled), psize.Scatter(i), c.Unsampled, ...
                            "filled", "Marker", style.MarkerStyleRec(j), "MarkerFaceAlpha", alpha.MixedFPs(i));
                        line([iFP iFP], [0 jNum], ...
                            "Color", c.FPLine, "LineStyle", "-.", "LineWidth", psize.FPLine);
                        fill([0 0 0.6 0.6]+iFP, [0 jNum jNum 0], c.Shade, "FaceAlpha", alpha.Shade, "EdgeColor", "none");
                        if i == 1
                            ylabel(SampleMarkStrs(j), "Color", c.Samples(j,:), ...
                                "FontSize", fontSize.Label, "FontName", font);
                            if j == 1
                                xlabel("Press duration (ms)", "FontSize", fontSize.Label, "FontName", font);
                            end
                        end

                        % plot HT pdf in one axes;
                        Fig.CurrentAxes = h.("c"+num2str(i));
                        [ipdf,xi] = ksdensity(itbt.HT(idxSampled), obj.Options.Edges_HT, 'Bandwidth', 0.15);
                        [ipdf_ci] = ksdensity_ci(itbt.HT(idxSampled), obj.Options.Edges_HT, 0.15, 1000);
                        plotshaded(xi, ipdf_ci, c.Samples(j,:));
                        linePDF.("l"+num2str(i)+num2str(j)) = plot(xi, ipdf, ...
                            'color', c.Samples(j,:), 'linewidth', 1.5, 'linestyle', '-');
                        line([iFP iFP], xLim.HT, ...
                            "Color", c.FPLine, "LineStyle", "-.", "LineWidth", psize.FPLine);
                        if i == 1
                            ylabel("Probability density (1/s)", "FontSize", fontSize.Label, "FontName", font)
                        end
                    end

                end
                legendPDF = legend(h.c1, [linePDF.l11, linePDF.l12, linePDF.l13], SampleMarkStrs, "Location", "northeast", ...
                    "FontSize", fontSize.Label, "FontName", font, "NumColumns", 1, "Box", "off");
                legendPDF.ItemTokenSize = [12,15];

                ha00 = axes;
                set(ha00, "Units", "centimeters", "Position", [xmap(1) ymap2(end)-ygap*2 axeSizeInfo]);
                axis off;
                title("Subject: "+obj.Subject+"    "+txtTitle, ...
                    "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
            end

            function Fig = plotRecoveryV2(obj)
                tbt = obj.sampleTrials("trialNum", trialNum, "smplMark", sampleMarks, "exp", sampleExps);
                tbt = tbt(tbt.TimeElapsed<tLim(2) & tbt.TimeElapsed>tLim(1), :);

                xstart = 1.5; ystart = 0.5; xgap = 0.5; ygap = 0.6;

                axeSize = [4 3];

                xmap = [xstart, xstart + xgap + axeSize(1), xstart + xgap*6 + axeSize(1)];

                ymap = [ystart, ...
                        ystart + ygap*1 + axeSize(2), ...
                        ystart + ygap*2 + axeSize(2)*2, ...
                        ystart + ygap*5 + axeSize(2)*3];
                ymap = fliplr(ymap);

                Fig = figure(1); clf(Fig, "reset");
                set(Fig, "Unit", "centimeters", "PaperPositionMode", "auto", ...
                    "Position", [2 2 xmap(end) ymap(1)], "Color", "w");

                %% ha11/12/13 holdtime raster for all sessions
                for i = 1:length(trialNum)
                    h.("a"+num2str(i)) = axes;
                    set(h.("a"+num2str(i)), "Units", "centimeters", "Position", [xmap(1) ymap(i+1) axeSize], ...
                        "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                        "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, ...
                        "YLim", [0 trialNum2*3], "YTick", {}, "YTickLabel", {}, ...
                        "FontSize", fontSize.Axes, "FontName", font);
                    axis off;
                    % ylabel(SampleMarkStrs(i), "FontSize", fontSize.Label, "FontName", font);

                    itbt = tbt(tbt.Sampled == sampleMarks(i),:);
                    for j = 1:length(obj.MixedFP)
                        jFP = obj.MixedFP(j);
                        jtbt = itbt(itbt.FP == jFP,:);
                        idxRand = randperm(length(jtbt.Sampled), trialNum2);
                        fills.("f"+num2str(i)+num2str(j)) = fill([0 jFP jFP 0], ...
                            [trialNum2*(j-1) trialNum2*(j-1) trialNum2*j trialNum2*j], 'k');
                        set(fills.("f"+num2str(i)+num2str(j)), "FaceColor", c.MixedFPsJY(j), "FaceAlpha", 0.5, "EdgeColor", "none");
                        scatter(jtbt.HT(idxRand), (1:trialNum2)+trialNum2*(j-1), ...
                            psize.RecoveryV2, "MarkerFaceColor", c.MixedFPsJY(j), "MarkerEdgeColor", c.MixedFPsJY(j));
                    end
                    if i == 1
                        text(obj.MixedFP(2), trialNum2*3.7, [txtTitle; obj.Subject], "HorizontalAlignment", "center", ...
                            "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                        le = legend([fills.f13; fills.f12; fills.f11], ["1500 ms"; "1000 ms"; "  500 ms"], ... % string(flip(obj.MixedFP)*1000)+" ms"
                            "NumColumns", 1, "Box", "off", ...
                            "Units", "centimeters", "Position", [xmap(2) (ymap(1)+ymap(2))/2 1 1], ...
                            "FontSize", fontSize.Label, "FontName", font, "FontWeight", "bold");
                        le.ItemTokenSize = [18,24];
                        le.Position(1) = le.Position(1);
                        le.Position(2) = le.Position(2) - 0.45;
                    end
                    text(-0.5, trialNum2*3/2, SampleMarkStrs(i), "Rotation", 90, "HorizontalAlignment", "center", ...
                        "FontSize", fontSize.Label, "FontName", font, "FontWeight", "bold");
                    if i == 2
                        text(xLim.HT(2), trialNum2*3/2, ["Sample size";"for each FP"; string(trialNum2)+" / "+string(trialNum(2))], ...
                            "HorizontalAlignment", "left", ...
                            "FontSize", fontSize.Label, "FontName", font, "FontWeight", "bold");
                    end
                end

            end

            %% Plot each experiment condition change
            function Fig = plotPrevsPost(obj)
                % Format: obj.plot("plotType", "PreVsPost", "expName", ["exp1", "exp2"])
                titles = ["1st", "2nd", "1st", "2nd"];
                colors = ["k", "k", c.PostExpJY, c.PostExpJY];
                chi2gory = [0 0.3 0.6 xLim.HT(2)];

                tbt = obj.TBT;
                idxPost = find(obj.Experiments == expName(2));
                idxPre = find(diff(obj.Experiments == expName(1)) == -1);
                idxPost = intersect(idxPost, idxPre+1);

                nCycle = length(idxPre); nFP = length(obj.MixedFP);

                allTBT = cell(nCycle+1, 4);
                allChi2Table = cell(nCycle+1, nFP); 
                allPvalue = zeros(nCycle+1, nFP);
                allPDF = cell(nCycle+1, nFP, 2);
                allPDF_ci = allPDF;
                maxpdf = [];
                for i = 1:nCycle
                    ipre = obj.Sessions(idxPre(i));
                    itbt_pre = tbt(tbt.Session == ipre,:);
                    ipost = obj.Sessions(idxPost(i));
                    itbt_post = tbt(tbt.Session == ipost,:);

                    temp = min([height(itbt_pre) height(itbt_post)]);
                    nsplit = nSplit;
                    if nSplit > temp
                        nsplit = temp;
                    end
                    itbt_pre1 = itbt_pre(1:nsplit, :);
                    itbt_pre2 = itbt_pre(end-nsplit:end, :);
                    itbt_post1 = itbt_post(1:nsplit, :);
                    itbt_post2 = itbt_post(end-nsplit:end, :);

                    allTBT(i,:) = {itbt_pre1, itbt_pre2, itbt_post1, itbt_post2};

                    for j = 1:nFP
                        jFP = obj.MixedFP(j);
                        jtbt_pre = itbt_pre(itbt_pre.FP == jFP,:);
                        jtbt_post = itbt_post(itbt_post.FP == jFP,:);

                        chitable = zeros(2,length(chi2gory));
                        chitable(1,1) = sum(jtbt_pre.HT<jFP);
                        chitable(2,1) = sum(jtbt_post.HT<jFP);
                        for jj = 2:length(chi2gory)
                            chitable(1,jj) = sum(jtbt_pre.HT>=jFP+chi2gory(jj-1) & jtbt_pre.HT<jFP+chi2gory(jj));
                            chitable(2,jj) = sum(jtbt_post.HT>=jFP+chi2gory(jj-1) & jtbt_post.HT<jFP+chi2gory(jj));
                        end
                        pval = chi2test(chitable);
                        
                        allChi2Table{i,j} = chitable;
                        allPvalue(i,j) = pval;

                        % Calculate pdf and pdf_ci
                        [jpdf_pre, ~] = ksdensity(jtbt_pre.HT, obj.Options.Edges_HT, 'Bandwidth', kernel_bw);
                        [jpdf_ci_pre]  = ksdensity_ci(jtbt_pre.HT, obj.Options.Edges_HT, kernel_bw, 1000);
                        [jpdf_post,xi] = ksdensity(jtbt_post.HT, obj.Options.Edges_HT, 'Bandwidth', kernel_bw);
                        [jpdf_ci_post] = ksdensity_ci(jtbt_post.HT, obj.Options.Edges_HT, kernel_bw, 1000);

                        allPDF{i,j,1} = jpdf_pre;  allPDF_ci{i,j,1} = jpdf_ci_pre;
                        allPDF{i,j,2} = jpdf_post; allPDF_ci{i,j,2} = jpdf_ci_post;
                        maxpdf = max([max([jpdf_ci_pre jpdf_ci_post], [], "all") maxpdf]);
                    end
                end
                pdfLim = ceil(maxpdf);

                if nCycle > 1
                    ncol = nCycle+1;
                    alltbt_pre  = tbt(ismember(tbt.Session, obj.Sessions(idxPre)),:);
                    alltbt_post = tbt(ismember(tbt.Session, obj.Sessions(idxPost)),:);
                    for j = 1:nFP
                        jFP = obj.MixedFP(j);
                        jtbt_pre = alltbt_pre(alltbt_pre.FP == jFP,:);
                        jtbt_post = alltbt_post(alltbt_post.FP == jFP,:);

                        chitable = zeros(2,length(chi2gory));
                        chitable(1,1) = sum(jtbt_pre.HT<jFP);
                        chitable(2,1) = sum(jtbt_post.HT<jFP);
                        for jj = 2:length(chi2gory)
                            chitable(1,jj) = sum(jtbt_pre.HT>=jFP+chi2gory(jj-1) & jtbt_pre.HT<jFP+chi2gory(jj));
                            chitable(2,jj) = sum(jtbt_post.HT>=jFP+chi2gory(jj-1) & jtbt_post.HT<jFP+chi2gory(jj));
                        end
                        pval = chi2test(chitable);
                        
                        allChi2Table{end,j} = chitable;
                        allPvalue(end,j) = pval;

                        % Calculate pdf and pdf_ci
                        [jpdf_pre, ~] = ksdensity(jtbt_pre.HT, obj.Options.Edges_HT, 'Bandwidth', kernel_bw);
                        [jpdf_ci_pre]  = ksdensity_ci(jtbt_pre.HT, obj.Options.Edges_HT, kernel_bw, 1000);
                        [jpdf_post,xi] = ksdensity(jtbt_post.HT, obj.Options.Edges_HT, 'Bandwidth', kernel_bw);
                        [jpdf_ci_post] = ksdensity_ci(jtbt_post.HT, obj.Options.Edges_HT, kernel_bw, 1000);

                        allPDF{end,j,1} = jpdf_pre;  allPDF_ci{end,j,1} = jpdf_ci_pre;
                        allPDF{end,j,2} = jpdf_post; allPDF_ci{end,j,2} = jpdf_ci_post;
                    end
                else
                    ncol = nCycle;
                end

                xstart = 1.5; ystart = 1.5; xgap = 1; ygap = 0.6; ygap2 = 0.05;
                axeSize = [3 2]; axeSize2 = [axeSize(1) 1.35];

                for i = 1:ncol+1
                    xmap(i) = xstart + (i-1)*(xgap+axeSize(1));
                end

                ymap = [ystart, ...
                        ystart + axeSize2(2)*1 + ygap2*1, ...
                        ystart + axeSize2(2)*2 + ygap2*2, ...
                        ystart + axeSize2(2)*3 + ygap2*3 + ygap*1, ...
                        ystart + axeSize2(2)*3 + ygap2*3 + ygap*2 + axeSize(2), ...
                        ystart + axeSize2(2)*3 + ygap2*3 + ygap*3 + axeSize(2)*2, ...
                        ystart + axeSize2(2)*3 + ygap2*3 + ygap*4 + axeSize(2)*3];
                ymap = fliplr(ymap);

                Fig = figure(1); clf(Fig, "reset");
                set(Fig, "Unit", "centimeters", "PaperPositionMode", "auto", ...
                    "Position", [2 2 xmap(end)+xgap ymap(1)+axeSize(2)+ygap*3], "Color", "w");

                for i = 1:ncol
                    if i <= nCycle
                        for k = 1:4
                            ktbt = allTBT{i,k};
                            temp = char(ktbt.Experiment(1));
                            titletxt = string(temp(1:3))+" | "+string(ktbt.Date(1))+" "+titles(k);
                            % ha1x, first half of pre sessions
                            h.("a"+num2str(i)+num2str(k)) = axes;
                            set(h.("a"+num2str(i)+num2str(k)), "Units", "centimeters", "Position", [xmap(i) ymap(k) axeSize], ...
                                "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                                "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, ...
                                "YLim", [0 trialNum2*3], "YTick", {}, "YTickLabel", {}, ...
                                "FontSize", fontSize.Axes, "FontName", font);
                            title(titletxt,  "Color", colors(k), ...
                                "FontSize", fontSize.Title, "FontName", font);
                            h.("a"+num2str(i)+num2str(k)).TitleHorizontalAlignment = "left";
                            axis off;
                            for j = 1:length(obj.MixedFP)
                                jFP = obj.MixedFP(j);
                                jtbt = ktbt(ktbt.FP == jFP,:);
                                idxRand = randperm(length(jtbt.FP), trialNum2);
                                fills.("f"+num2str(i)+num2str(j)) = fill([0 jFP jFP 0], ...
                                    [trialNum2*(j-1) trialNum2*(j-1) trialNum2*j trialNum2*j], 'k');
                                set(fills.("f"+num2str(i)+num2str(j)), "FaceColor", c.MixedFPsJY(j), "FaceAlpha", 0.5, "EdgeColor", "none");
                                scatter(jtbt.HT(idxRand), (1:trialNum2)+trialNum2*(j-1), ...
                                    psize.RecoveryV2, "MarkerFaceColor", c.MixedFPsJY(j), "MarkerEdgeColor", c.MixedFPsJY(j));
                            end
                        end
                    end

                    for j = 1:nFP
                        jFP = obj.MixedFP(j);

                        h.("b"+num2str(j)) = axes;
                        set(h.("b"+num2str(j)), "Units", "centimeters", "Position", [xmap(i) ymap(8-j) axeSize2], ...
                            "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                            "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, ...
                            "YLim", [0 pdfLim], "XTickLabelRotation", 0, ...
                            "FontSize", fontSize.Axes, "FontName", font);
                        if j ~= 1
                            axis off;
                        end
                        if i == 1 && j == 1
                            ylabel("Density (1/s)", "FontSize", fontSize.Label, "FontName", font);
                            xlabel("Hold duration (ms)", "FontSize", fontSize.Label, "FontName", font);
                        end
                        fills.("f"+num2str(j)) = fill([0 jFP jFP 0], [pdfLim pdfLim 0 0], 'k');
                        set(fills.("f"+num2str(j)), "FaceColor", c.MixedFPsJY(j), "FaceAlpha", 0.5, "EdgeColor", "none");
                        line([jFP+chi2gory;jFP+chi2gory], [0 pdfLim], ...
                            "Color", c.FPLine, "LineStyle", "-.", "LineWidth", psize.FPLine);
                        
                        plotshaded(xi, allPDF_ci{i,j,1}, c.MixedFPsJY(j));
                        linePDF.("pre"+num2str(j)) = plot(xi, allPDF{i,j,1}, ...
                            "Color", c.MixedFPsJY(j), "LineWidth", 1.5, "LineStyle", "-");

                        plotshaded(xi, allPDF_ci{i,j,2}, c.PostExpJY);
                        linePDF.("post"+num2str(j)) = plot(xi, allPDF{i,j,2}, ...
                            "Color", c.PostExpJY, "LineWidth", 1.5, "LineStyle", "-");
                        
                        pval = allPvalue(i,j);
                        txt1 = "p<0.001";
                        if pval >= 0.001; txt1 = "p="+num2str(pval, "%.3f"); end
                        text(xLim.HT(2)*0.75, pdfLim*0.8, txt1, "Color", 'k', ...
                            "FontSize", fontSize.Label, "FontName", font);
                    end
                end

                ha00 = axes;
                set(ha00, "Units", "centimeters", "Position", [xmap(1) ymap(1)+axeSize(2)+ygap xmap(end)-xmap(1) 0.01]);
                axis off;
                title("Subject: "+obj.Subject+" ("+obj.Group+")", ...
                    "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
            end

            %% Plot summary for intermittent experiment
            function Fig = plotInterSummary(obj)
                % Package your data in saline-dcz format (each training stage 
                %   should contain at least 1 sal-dcz pair)
                % The sample size of HT raster plot is defined by options.trialNum2,
                %   50 is a recommended value.
                tbt = obj.TBT; nFP = length(obj.MixedFP);
                htGap = 10;

                isWait1 = any(obj.Tasks == "Wait1");
                isWait2 = any(obj.Tasks == "Wait2");
                is3FPs  = any(obj.Tasks == "3FPs");

                flagWait = [isWait1 isWait2]; nameWait = ["Wait1" "Wait2"];
                maxpdf = [];
                for i = 1:2
                    iname = nameWait(i);
                    if flagWait(i)
                        HT.(iname) = zeros(2, trialNum2); % (1,:) - Pre;   (2,:) - Post
                        RT.(iname) = cell(2,1);
                        PDF.(iname) = cell(2,1);
                        PDF_ci.(iname) = cell(2,1);
    
                        idxWait = obj.Tasks == iname;
                        idxPost = find(obj.Experiments == expName(2) & idxWait);
                        idxPre  = find(diff(obj.Experiments == expName(1) & idxWait) == -1);
                        idxPre  = intersect(idxPre, find(idxWait)-1);
                        idxPost = intersect(idxPost, idxPre+1);
                        datePre  = obj.Dates(idxPre);
                        datePost = obj.Dates(idxPost);
    
                        tbtPre  = tbt(ismember(tbt.Date, datePre)  & tbt.FP == obj.MixedFP(end),:);
                        tbtPost = tbt(ismember(tbt.Date, datePost) & tbt.FP == obj.MixedFP(end),:);
    
                        idxRand1 = randperm(height(tbtPre),  trialNum2);
                        idxRand2 = randperm(height(tbtPost), trialNum2); 
                        
                        HT.(iname)(1,:) = tbtPre.HT(idxRand1);
                        HT.(iname)(2,:) = tbtPost.HT(idxRand2);
                        RT.(iname){1} = tbtPre.RelT(tbtPre.RelT>0.1 & tbtPre.RelT<2);
                        RT.(iname){2} = tbtPost.RelT(tbtPost.RelT>0.1 & tbtPost.RelT<2);
                        RT.(iname){3} = ones(length(RT.(iname){1}),1);
                        RT.(iname){4} = 2*ones(length(RT.(iname){2}),1);

                        [PDF.(iname){1}, ~] = ksdensity(tbtPre.HT, obj.Options.Edges_HT, 'Bandwidth', kernel_bw);
                        PDF_ci.(iname){1}   = ksdensity_ci(tbtPre.HT, obj.Options.Edges_HT, kernel_bw, 1000);
                        [PDF.(iname){2},xi] = ksdensity(tbtPost.HT, obj.Options.Edges_HT, 'Bandwidth', kernel_bw);
                        PDF_ci.(iname){2}   = ksdensity_ci(tbtPost.HT, obj.Options.Edges_HT, kernel_bw, 1000);
                  
                        maxpdf = max([max([PDF_ci.(iname){1} PDF_ci.(iname){2}], [], "all") maxpdf]);

                        chi2gory = [0 quantile(tbtPre.HT, [0.25 0.5 0.75]) 10];
                        for j = 1:length(chi2gory)-1
                            Chi2gory.(iname) = chi2gory(1:4);
                            Chi2table.(iname)(1,j) = sum(tbtPre.HT>chi2gory(j) & tbtPre.HT<chi2gory(j+1));
                            Chi2table.(iname)(2,j) = sum(tbtPost.HT>chi2gory(j) & tbtPost.HT<chi2gory(j+1));
                        end
                        [pval.(iname),qval.(iname)] = chi2test(Chi2table.(iname));
                    end
                end

                if is3FPs

                    idx3FPs = obj.Tasks == "3FPs";
                    idxPost = find(obj.Experiments == expName(2) & idx3FPs);
                    idxPre  = find(diff(obj.Experiments == expName(1) & idx3FPs) == -1);
                    idxPre  = intersect(idxPre, find(idx3FPs)-1);
                    idxPost = intersect(idxPost, idxPre+1);
                    datePre  = obj.Dates(idxPre);
                    datePost = obj.Dates(idxPost);

                    for i = 1:nFP
                        iname = "FP"+num2str(i);
                        HT.(iname) = zeros(2, trialNum2); % (1,:) - Pre;   (2,:) - Post
                        RT.(iname) = cell(2,1);
                        PDF.(iname) = cell(2,1);
                        PDF_ci.(iname) = cell(2,1);
    
                        tbtPre  = tbt(ismember(tbt.Date, datePre)  & tbt.FP == obj.MixedFP(i),:);
                        tbtPost = tbt(ismember(tbt.Date, datePost) & tbt.FP == obj.MixedFP(i),:);
    
                        idxRand1 = randperm(height(tbtPre),  trialNum2);
                        idxRand2 = randperm(height(tbtPost), trialNum2); 
                        
                        HT.(iname)(1,:) = tbtPre.HT(idxRand1);
                        HT.(iname)(2,:) = tbtPost.HT(idxRand2);
                        RT.(iname){1} = tbtPre.RelT(tbtPre.RelT>0.1 & tbtPre.RelT<2);
                        RT.(iname){2} = tbtPost.RelT(tbtPost.RelT>0.1 & tbtPost.RelT<2);
                        RT.(iname){3} = ones(length(RT.(iname){1}),1);
                        RT.(iname){4} = 2*ones(length(RT.(iname){2}),1);

                        [PDF.(iname){1}, ~] = ksdensity(tbtPre.HT, obj.Options.Edges_HT, 'Bandwidth', kernel_bw);
                        PDF_ci.(iname){1}   = ksdensity_ci(tbtPre.HT, obj.Options.Edges_HT, kernel_bw, 1000);
                        [PDF.(iname){2},xi] = ksdensity(tbtPost.HT, obj.Options.Edges_HT, 'Bandwidth', kernel_bw);
                        PDF_ci.(iname){2}   = ksdensity_ci(tbtPost.HT, obj.Options.Edges_HT, kernel_bw, 1000);
                        maxpdf = max([max([PDF_ci.(iname){1} PDF_ci.(iname){2}], [], "all") maxpdf]);

                        chi2gory = [0 quantile(tbtPre.HT, [0.25 0.5 0.75]) 10];
                        for j = 1:length(chi2gory)-1
                            Chi2gory.(iname) = chi2gory(1:4);
                            Chi2table.(iname)(1,j) = sum(tbtPre.HT>chi2gory(j) & tbtPre.HT<chi2gory(j+1));
                            Chi2table.(iname)(2,j) = sum(tbtPost.HT>chi2gory(j) & tbtPost.HT<chi2gory(j+1));
                        end
                        [pval.(iname),qval.(iname)] = chi2test(Chi2table.(iname));
                    end
                end

                pdfLim = ceil(maxpdf);

                xstart = 1.5; ystart = 1; xgap = 1; ygap = 0.6;
                axeSize = [3 2];

                xmap = [xstart, ...
                        xstart + (axeSize(1)+xgap)*isWait1, ...
                        xstart + (axeSize(1)+xgap)*(isWait1+isWait2)];
                for i = 1:nFP
                    xmap(i+3) = xmap(i+2) + (xgap+axeSize(1))*is3FPs;
                end

                axeSizeInfo = [xmap(end)-xmap(1) 0.01];

                ymap = [ystart, ...
                        ystart + axeSize(2)*1 + ygap*1, ...
                        ystart + axeSize(2)*2 + ygap*2, ...
                        ystart + axeSize(2)*3 + ygap*3.5, ...
                        ystart + axeSize(2)*3 + ygap*5 + axeSizeInfo(2)];

                Fig = figure(1); clf(Fig, "reset");
                set(Fig, "Unit", "centimeters", "PaperPositionMode", "auto", ...
                    "Position", [2 2 xmap(end) ymap(end)], "Color", "w");
            
                for i = 1:2
                    iname = nameWait(i);
                    if flagWait(i)
                        h.("WaitHT"+num2str(i)) = axes;
                        set(h.("WaitHT"+num2str(i)), "Units", "centimeters", "Position", [xmap(i) ymap(3) axeSize], ...
                            "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                            "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", {}, ...
                            "YLim", [0 trialNum2*2+htGap], "YTick", {}, "YTickLabel", {}, ...
                            "FontSize", fontSize.Axes, "FontName", font);
                        title(iname, "FontSize", fontSize.Title, "FontName", font);
                        
                        fills.("WaitHT"+num2str(i)) = fill([0 obj.MixedFP(end) obj.MixedFP(end) 0], ...
                            [0 0 trialNum2*2+htGap trialNum2*2+htGap], 'k');
                        set(fills.("WaitHT"+num2str(i)), "FaceColor", c.MixedFPsJY(3), "FaceAlpha", 0.4, "EdgeColor", "none");
                        scatter(HT.(iname)(1,:), (1:trialNum2)+trialNum2+htGap, ...
                            psize.RecoveryV2, "MarkerFaceColor", c.MixedFPsJY(3), "MarkerEdgeColor", c.MixedFPsJY(3));
                        scatter(HT.(iname)(2,:), (1:trialNum2), ...
                            psize.RecoveryV2, "MarkerFaceColor", c.PostExpJY, "MarkerEdgeColor", c.PostExpJY);
                        if i == 1
                            set(h.("WaitHT"+num2str(i)), "YTickLabel", yTickLabel.HT);
                            ylabel("HT (ms)", "FontSize", fontSize.Label, "FontName", font);
                        end
                        line(xLim.HT, [trialNum2+htGap/2 trialNum2+htGap/2], "LineStyle", "-.", "Color", c.GapLine, "LineWidth", psize.GapLine);

                        h.("WaitPDF"+num2str(i)) = axes;
                        set(h.("WaitPDF"+num2str(i)), "Units", "centimeters", "Position", [xmap(i) ymap(2) axeSize], ...
                            "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                            "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, ...
                            "YLim", [0 pdfLim], "XTickLabelRotation", 0, ...
                            "FontSize", fontSize.Axes, "FontName", font);
                        if i == 1
                            ylabel("Density (1/s)", "FontSize", fontSize.Label, "FontName", font);
                        end
                        fills.("WaitPDF"+num2str(i)) = fill([0 obj.MixedFP(end) obj.MixedFP(end) 0], ...
                            [pdfLim pdfLim 0 0], 'k');
                        set(fills.("WaitPDF"+num2str(i)), "FaceColor", c.MixedFPsJY(3), "FaceAlpha", 0.5, "EdgeColor", "none");
                        if max(PDF.(iname){1})<2.5
                            line([Chi2gory.(iname);Chi2gory.(iname)], [0 pdfLim], ...
                                "Color", c.FPLine, "LineStyle", "-.", "LineWidth", psize.GapLine);
                        end

                        plotshaded(xi, PDF_ci.(iname){1}, c.MixedFPsJY(3));
                        linePDF.("WaitPDFPre"+num2str(i)) = plot(xi, PDF.(iname){1}, ...
                            "Color", c.MixedFPsJY(3), "LineWidth", 1.5, "LineStyle", "-");
                        plotshaded(xi, PDF_ci.(iname){2}, c.PostExpJY);
                        
                        linePDF.("WaitPDFPost"+num2str(i)) = plot(xi, PDF.(iname){2}, ...
                            "Color", c.PostExpJY, "LineWidth", 1.5, "LineStyle", "-");

                        ipval = pval.(iname);
                        txt1 = "p<0.001";
                        if ipval >= 0.001; txt1 = "p="+num2str(ipval, "%.3f"); end
                        text(xLim.HT(2)*0.75, pdfLim*0.8, ["X^{2}_{3}="+num2str(qval.(iname),"%.2f");txt1], "Color", 'k', ...
                            "FontSize", fontSize.Label, "FontName", font, "Interpreter", "tex");


                        h.("WaitRT"+num2str(i)) = axes;
                        set(h.("WaitRT"+num2str(i)), "Units", "centimeters", "Position", [xmap(i) ymap(1) axeSize], ...
                            "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                            "XLim", [0.5 2.5], "XTick", {}, "XTickLabel", xTickLabel.Date, ...
                            "YLim", yLim.RT, "YTick", yTick.RT, "YTickLabel", {}, ...
                            "FontSize", fontSize.Axes, "FontName", font);
                        violinRT = violinplot([RT.(iname){1};RT.(iname){2}], ...
                            [RT.(iname){3};RT.(iname){4}], 'ViolinColor', c.Violin, ...
                            'Width', 0.4, 'ViolinAlpha', alpha.Violin, 'ShowWhiskers', false, ...
                            'BoxColor', c.Whisker, 'BoxWidth', 0.01, 'EdgeColor', c.ViolinEdge);
                        for k = 1:2
                            violinRT(k).MedianPlot.LineWidth = 1.5;
                            violinRT(k).MedianPlot.SizeData  = 30;
                            violinRT(k).ScatterPlot.MarkerFaceColor = 'k';
                            violinRT(k).ScatterPlot.SizeData = 15;
                        end
                        if i == 1
                            set(gca, "Box", "off", "XTickLabel", expName, "YTickLabel", yTickLabel.RT);
                            ylabel("RelT (ms)", "FontSize", fontSize.Label, "FontName", font);
                        else
                            set(gca, "Box", "off", "XTickLabel", expName, "YTickLabel", {});
                        end

                        line([1.5 1.5], yLim.RT, "LineStyle", "-.", "Color", c.GapLine, "LineWidth", psize.GapLine);
                    end
                end

                if is3FPs
                    for i = 1:nFP
                        iname = "FP"+num2str(i);
                        h.("MFPHT"+num2str(i)) = axes;
                        set(h.("MFPHT"+num2str(i)), "Units", "centimeters", "Position", [xmap(6-i) ymap(3) axeSize], ...
                            "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                            "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", {}, ...
                            "YLim", [0 trialNum2*2+htGap], "YTick", {}, "YTickLabel", {}, ...
                            "FontSize", fontSize.Axes, "FontName", font);
                        title("3FP "+num2str(obj.MixedFP(i)*1000)+"ms", "FontSize", fontSize.Title, "FontName", font);
                        
                        fills.("MFPHT"+num2str(i)) = fill([0 obj.MixedFP(i) obj.MixedFP(i) 0], ...
                            [0 0 trialNum2*2+htGap trialNum2*2+htGap], 'k');
                        set(fills.("MFPHT"+num2str(i)), "FaceColor", c.MixedFPsJY(3), "FaceAlpha", 0.4, "EdgeColor", "none");
                        scatter(HT.(iname)(1,:), (1:trialNum2)+trialNum2+htGap, ...
                            psize.RecoveryV2, "MarkerFaceColor", c.MixedFPsJY(3), "MarkerEdgeColor", c.MixedFPsJY(3));
                        scatter(HT.(iname)(2,:), (1:trialNum2), ...
                            psize.RecoveryV2, "MarkerFaceColor", c.PostExpJY, "MarkerEdgeColor", c.PostExpJY);
                        line(xLim.HT, [trialNum2+htGap/2 trialNum2+htGap/2], "LineStyle", "-.", "Color", c.GapLine, "LineWidth", psize.GapLine);

                        % HT pdf
                        h.("HTPDF"+num2str(i)) = axes;
                        set(h.("HTPDF"+num2str(i)), "Units", "centimeters", "Position", [xmap(6-i) ymap(2) axeSize], ...
                            "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                            "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, ...
                            "YLim", [0 pdfLim], "XTickLabelRotation", 0, ...
                            "FontSize", fontSize.Axes, "FontName", font);
                        fills.("HTPDF"+num2str(i)) = fill([0 obj.MixedFP(i) obj.MixedFP(i) 0], ...
                            [pdfLim pdfLim 0 0], 'k');
                        set(fills.("HTPDF"+num2str(i)), "FaceColor", c.MixedFPsJY(i), "FaceAlpha", 0.5, "EdgeColor", "none");
                        if max(PDF.(iname){1})<2.5
                            line([Chi2gory.(iname);Chi2gory.(iname)], [0 pdfLim], ...
                                "Color", c.FPLine, "LineStyle", "-.", "LineWidth", psize.GapLine);
                        end

                        plotshaded(xi, PDF_ci.(iname){1}, c.MixedFPsJY(i));
                        linePDF.("HTPDFPre"+num2str(i)) = plot(xi, PDF.(iname){1}, ...
                            "Color", c.MixedFPsJY(i), "LineWidth", 1.5, "LineStyle", "-");

                        plotshaded(xi, PDF_ci.(iname){2}, c.PostExpJY);
                        linePDF.("HTPDFPost"+num2str(i)) = plot(xi, PDF.(iname){2}, ...
                            "Color", c.PostExpJY, "LineWidth", 1.5, "LineStyle", "-");
                        
                        ipval = pval.(iname);
                        txt1 = "p<0.001";
                        if ipval >= 0.001; txt1 = "p="+num2str(ipval, "%.3f"); end
                        text(xLim.HT(2)*0.75, pdfLim*0.8, ["X^{2}_{3}="+num2str(qval.(iname),"%.2f");txt1], "Color", 'k', ...
                            "FontSize", fontSize.Label, "FontName", font, "Interpreter", "tex");

                        
                        % RT violin
                        h.("MFPRT"+num2str(i)) = axes;
                        set(h.("MFPRT"+num2str(i)), "Units", "centimeters", "Position", [xmap(6-i) ymap(1) axeSize], ...
                            "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                            "XLim", [0.5 2.5], "XTick", {}, ...
                            "YLim", yLim.RT, "YTick", yTick.RT, "YTickLabel", {}, ...
                            "FontSize", fontSize.Axes, "FontName", font);
                        violinRT = violinplot([RT.(iname){1};RT.(iname){2}], ...
                            [RT.(iname){3};RT.(iname){4}], 'ViolinColor', c.Violin, ...
                            'Width', 0.4, 'ViolinAlpha', alpha.Violin, 'ShowWhiskers', false, ...
                            'BoxColor', c.Whisker, 'BoxWidth', 0.01, 'EdgeColor', c.ViolinEdge);
                        for k = 1:2
                            violinRT(k).MedianPlot.LineWidth = 1.5;
                            violinRT(k).MedianPlot.SizeData  = 30;
                            violinRT(k).ScatterPlot.MarkerFaceColor = 'k';
                            violinRT(k).ScatterPlot.SizeData = 15;
                        end
                        set(gca, "Box", "off", "XTickLabel", expName);

                        line([1.5 1.5], yLim.RT, "LineStyle", "-.", "Color", c.GapLine, "LineWidth", psize.GapLine);
                    end
                end

                ha00 = axes;
                set(ha00, "Units", "centimeters", "Position", [xstart/2 ymap(4) axeSizeInfo]);
                axis off;
                title("Subject: "+obj.Subject+" ("+obj.Group+") | Intermittent inactivation", ...
                    "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");

            end

        end

    end
end