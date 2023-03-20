classdef BehaviorDSRT
    % Single session data
    % METHODS: 
    % obj.merge(anotherObj,method,just1Day); Merge 2 or more obj
        % method: 'Merge' or 'Select', integration or select the longer one
        % just1Day: true or false, only merge the sessions of the same Date
    % obj.save(savepath); Save the obj information as .mat file & .csv file
        % default path is pwd
    % obj.plot
    % obj.print(hf,savepath) or (savepath,hf); 
        % save the figure, if there's not figure, call plot method then save
        % hf: handle of figure
        % savepath
    
    properties
        Subject char {mustBeTextScalar} % e.g., Panini
        Strain char {mustBeTextScalar} % e.g., LE (manual)
        Group char {mustBeTextScalar} % e.g., hM3Dq (manual) between-group variable
        Experiment char {mustBeTextScalar} % e.g., Saline or DCZ, PreLesion or PostLesion (manual) within-group variable
        Comment char {mustBeTextScalar} % e.g., Bilateral mPFC, Day 2 (manual)
        Experimenter char {mustBeTextScalar} % e.g., CY (manual)
        Weight double {mustBeNumeric} = NaN % 388 (gram) (manual)
        Task char {mustBeTextScalar} % e.g., 3FPs
        MixedFP double {mustBeNumeric} = NaN % e.g., [0.5,1.0,1.5]
        Session double = NaN % e.g., 3 (manual)
        Date double % e.g., 20221128
        DateTime datetime % e.g., datetime format precision time
        nTrial double % e.g., 318
        iTrial (:,1) double % e.g., 56
        BlockNum (:,1) double % e.g., 3
        TrialNum (:,1) double % e.g., 16
        TrialType (:,1) string % e.g., "Lever"
        TimeElapsed (:,1) double % e.g., 1020
        FP (:,1) double % e.g., 1.5
        RW (:,1) double % e.g., 0.6
        DarkTry (:,1) double % e.g., 1
        ConfuseNum (:,1) double % e.g., 2
        Outcome (:,1) string % e.g., "Cor" "Pre" "Late"
        HT (:,1) double % e.g., 1.62
        RT (:,1) double % e.g., 0.34
        MT (:,1) double % e.g., 0.98
    end

    properties (Dependent)
        RelT (:,1) double
        Table table
        Performance table
        AvgRT table
        AvgRTLoose table
    end
    
    properties (Dependent, GetAccess = private)
        SaveName
    end

    properties (Constant, GetAccess = private)
        TrialTypeOptions = {'Lever','Poke'} % 0 - Lever, 1 - Poke
        OutcomeOptions = {'Cor','Pre','Late','Err'} % 1 - Correct, -1 - Premature, -2 - Late, 0 - Error
        FigNum = 1
        DefaultMixedFP = [0.5,1.0,1.5]
        MergeMethod = {'Merge','Select'}
    end

    methods
        function obj = BehaviorDSRT(filename)
            % e.g., filename = 'Strangelove_DSRT_06_3FPs_20221115_151443.mat';
            % Construct an instance of this class
            arguments
                filename char {mustBeFile}
            end
            load(filename,"SessionData");
            data = SessionData;
            % get info
            dname = split(string(filename), '_');
            obj.Subject = dname(1);
            obj.Date = str2double(dname(5));
            obj.DateTime = datetime(data.Info.SessionStartTime_MATLAB,'convertfrom','datenum');
            obj.Task = dname(4);
            
            % get trial data
            nTrials = data.nTrials;
            cellCustom = struct2cell(data.Custom);
            for i=1:length(cellCustom)
                if ~isempty(cellCustom{i}) && nTrials > length(cellCustom{i})
                    nTrials = length(cellCustom{i});
%                     display(newName+"_"+newTask+"_"+newDate+"_CustomTrials ~= nTrials");
                end
            end
            obj.nTrial = nTrials;
            obj.iTrial = (1:nTrials)';
            if ~isfield(data.Custom,'BlockNum') % All is lever
                obj.BlockNum = ones(nTrials,1);
                obj.TrialNum = (1:nTrials)';
                trialType = zeros(nTrials,1); % all is lever
            else % DSRT: Lever / Poke
                obj.BlockNum = data.Custom.BlockNum(1:nTrials)';
                obj.TrialNum = data.Custom.TrialNum(1:nTrials)';
                trialType = data.Custom.TrialType(1:nTrials)';
            end
            TimeElapsed = data.Custom.TimeElapsed(1:nTrials)'; % start press or poke: wait4tone(1)
            TimeElapsed(TimeElapsed>1e4) = NaN;
            if isfield(data.Custom,'ForePeriod')
                if ~isempty(data.Custom.ForePeriod)
                    obj.FP = round(data.Custom.ForePeriod(1:nTrials),2)';
                    obj.RW = data.Custom.ResponseWindow(1:nTrials)';
                else % Leverpress / release
                    obj.FP = nan(nTrials,1);
                    obj.RW = nan(nTrials,1);
                end
                obj.RT = data.Custom.ReactionTime(1:nTrials)';

                % modify MixedFP if needed
                FPuni = round(unique(obj.FP),2);
                if ~isequal(FPuni(:),obj.MixedFP(:))
                    switch lower(obj.Task)
                        case {'wait1','wait2'}
                            obj.MixedFP = 1.5; % calculate performance in FP 1.5s
                        case {'leverpress','leverrelease'}
                            obj.MixedFP = NaN;
                        case '3fps'
                            defaultFP = obj.DefaultMixedFP;
                            if all(ismember(FPuni,defaultFP))
                                obj.MixedFP = defaultFP;
                            else
                                obj.MixedFP = FPuni;
                            end
                        otherwise
                            obj.MixedFP = FPuni;
                    end
                end
            else % Autoshaping
%                 obj.FP = nan(nTrials,1); % use FP variable as so-called FI
                FI = [];
                obj.RW = nan(nTrials,1);
                obj.RT = nan(nTrials,1);
            end
            darkTry = [];
            confuseNum = [];
            outcome = data.Custom.OutcomeCode(1:nTrials)';
            ht = [];
            
            obj.MT = data.Custom.MovementTime(1:nTrials)';
            
            % for some special cases
            if isnan(TimeElapsed)
                TimeElapsed = nan(nTrials,1);
                alterTE = true;
            else
                alterTE = false;
            end
            % get info from rawData
            for i=1:nTrials
                if exist('FI','var')
                    FI = [FI;diff(data.RawEvents.Trial{1,i}.States.WaitForLED)];
                end
                if isfield(data.RawEvents.Trial{1,i}.States,'TimeOut_reset') % dark try num
                    if ~isnan(data.RawEvents.Trial{1,i}.States.TimeOut_reset)
                        darkTry = [darkTry; size(data.RawEvents.Trial{1,i}.States.TimeOut_reset,1)];
                    else
                        darkTry = [darkTry; 0];
                    end
                else
                    darkTry = [darkTry; 0];
                end
                switch trialType(i) % confuse try num
                    case 0 % lever
                        if isfield(data.RawEvents.Trial{1,i}.Events,'Port2In')
                            confuseNum = [confuseNum; length(data.RawEvents.Trial{1,i}.Events.Port2In)];
                        else
                            confuseNum = [confuseNum; 0];
                        end
                    case 1 % poke
                        if isfield(data.RawEvents.Trial{1,i}.Events,'BNC1High')
                            confuseNum = [confuseNum; length(data.RawEvents.Trial{1,i}.Events.BNC1High)];
                        elseif isfield(data.RawEvents.Trial{1,i}.Events,'RotaryEncoder1_1')
                            confuseNum = [confuseNum; length(data.RawEvents.Trial{1,i}.Events.RotaryEncoder1_1)];
                        else
                            confuseNum = [confuseNum; 0];
                        end
                end
                if isfield(data.RawEvents.Trial{1, i}.States,'Wait4Tone')
                    if isnan(data.RawEvents.Trial{1, i}.States.Wait4Tone) % HT start time
                        if isfield(data.RawEvents.Trial{1, i}.States,'Delay')
                            HT_ori = data.RawEvents.Trial{1, i}.States.Delay(2);
                        else
                            HT_ori = data.RawEvents.Trial{1, i}.Wait4Start(2);
                        end
                    else
                        HT_ori = data.RawEvents.Trial{1, i}.States.Wait4Tone(end,1);
                    end
                    switch outcome(i) % HT
                        case 1
                            ht = [ht; ...
                                data.RawEvents.Trial{1, i}.States.Wait4Stop(2) - HT_ori];
                        case -1
                            if isfield(data.RawEvents.Trial{1, i}.States,'GracePeriod')
                                ht = [ht;...
                                    data.RawEvents.Trial{1, i}.States.GracePeriod(end,1) - HT_ori];
                            else
                                ht = [ht;...
                                    data.RawEvents.Trial{1, i}.States.Premature(1) - HT_ori];
                            end
                        case -2
                            ht = [ht;...
                                data.RawEvents.Trial{1, i}.States.LateError(2) - HT_ori];
                        otherwise
                            ht = [ht;NaN];
                    end
                elseif isfield(data.RawEvents.Trial{1,i}.States,'WaitForLED') % Autoshaping
                    HT_ori = data.RawEvents.Trial{1, i}.States.WaitForLED(2); % tone or poke time
                    ht = [ht;NaN];
                elseif isfield(data.RawEvents.Trial{1,i}.States,'Wait4Stop') % Leverpress / Leverrelease
                    HT_ori = data.RawEvents.Trial{1,i}.States.Wait4Stop(1);
                    timeBNC = {data.RawEvents.Trial{1,i}.Events.BNC1High,data.RawEvents.Trial{1,i}.Events.BNC1Low};
                    durBNC = 0;
                    for j=1:length(timeBNC{1})
                        dur = timeBNC{2}(j) - timeBNC{1}(j);
                        durBNC = durBNC + dur;
                        if dur>0.001
                            break;
                        end
                    end
                    ht = [ht;durBNC];
                else
                    error('Unspecified conditions');
                end
                if alterTE
                    TimeElapsed(i) = data.TrialStartTimestamp(i) + HT_ori;
                end
            end
            % adjust name
            ind_lever = trialType == 0;
            ind_poke = trialType == 1;
            trialType = string(trialType);
            trialType(ind_lever) = repelem(string(obj.TrialTypeOptions{1}),sum(ind_lever))';
            trialType(ind_poke) = repelem(string(obj.TrialTypeOptions{2}),sum(ind_poke))';

            ind_cor = outcome == 1;
            ind_pre = outcome == -1;
            ind_late = outcome == -2;
            ind_err = outcome == 0;
            outcome = string(outcome);
            outcome(ind_cor) = repelem(string(obj.OutcomeOptions{1}),sum(ind_cor)');
            outcome(ind_pre) = repelem(string(obj.OutcomeOptions{2}),sum(ind_pre)');
            outcome(ind_late) = repelem(string(obj.OutcomeOptions{3}),sum(ind_late)');
            outcome(ind_err) = repelem(string(obj.OutcomeOptions{4}),sum(ind_err)');
            % set value
            obj.TrialType = trialType;
            obj.TimeElapsed = TimeElapsed;
            obj.DarkTry = darkTry;
            obj.ConfuseNum = confuseNum;
            obj.Outcome = outcome;
            obj.HT = ht;
            if exist('FI','var'); obj.FP = FI; end
        end
        
        function value = get.SaveName(obj)
            value = append('BClass_',upper(obj.Subject),'_',...
                char(obj.DateTime,'yyyyMMdd_HHmmss'));
        end
        
        function value = get.RelT(obj)
            value = obj.HT - obj.FP;
            value(strcmp(obj.Outcome,obj.OutcomeOptions{2})) = NaN;
        end

        function T = get.Table(obj)
            tablenames = {'Subject','Group','Experiment','Task','Session','Date',...
                'DateTime','iTrial','BlockNum','TrialNum','TrialType','TimeElapsed',...
                'FP','RW','DarkTry','ConfuseNum','Outcome','HT','RT','MT','RelT'};
            T = table(repelem(string(obj.Subject),obj.nTrial)',...
                repelem(string(obj.Group),obj.nTrial)',...
                repelem(string(obj.Experiment),obj.nTrial)',...
                repelem(string(obj.Task),obj.nTrial)',...
                repelem(obj.Session,obj.nTrial)',...
                repelem(obj.Date,obj.nTrial)',...
                repelem(obj.DateTime,obj.nTrial)',...
                obj.iTrial,obj.BlockNum,obj.TrialNum,obj.TrialType,obj.TimeElapsed,...
                obj.FP,obj.RW,obj.DarkTry,obj.ConfuseNum,obj.Outcome,obj.HT,...
                obj.RT,obj.MT,obj.RelT,...
                'VariableNames',tablenames);
        end

        function value = get.Performance(obj)
            Foreperiod      = [num2cell(obj.MixedFP(:));'All'];
            N_press         = zeros(length(Foreperiod), 1);
            CorrectRatio    = zeros(length(Foreperiod), 1);
            PrematureRatio  = zeros(length(Foreperiod), 1);
            LateRatio       = zeros(length(Foreperiod), 1);

            for i = 1:length(obj.MixedFP)
                n_correct   = sum(obj.FP == obj.MixedFP(i) & strcmp(obj.Outcome,obj.OutcomeOptions{1}));
                n_premature = sum(obj.FP == obj.MixedFP(i) & strcmp(obj.Outcome,obj.OutcomeOptions{2}));
                n_late      = sum(obj.FP == obj.MixedFP(i) & strcmp(obj.Outcome,obj.OutcomeOptions{3}));
                n_legit     = n_correct+n_premature+n_late;
                N_press(i)  = n_legit;

                CorrectRatio(i)  =  100*n_correct/n_legit;
                PrematureRatio(i)  =  100*n_premature/n_legit;
                LateRatio(i)  =  100*n_late/n_legit;
            end

            % takes everything
            n_correct   = sum(strcmp(obj.Outcome,obj.OutcomeOptions{1}));
            n_premature = sum(strcmp(obj.Outcome,obj.OutcomeOptions{2}));
            n_late      = sum(strcmp(obj.Outcome,obj.OutcomeOptions{3}));
            n_err       = sum(strcmp(obj.Outcome,obj.OutcomeOptions{4})); % Autoshaping
            n_legit     = n_correct+n_premature+n_late+n_err;
            i = i+1;
            N_press(i) = n_legit;
            CorrectRatio(i)     = 100*n_correct/n_legit;
            PrematureRatio(i)   = 100*n_premature/n_legit;
            LateRatio(i)        = 100*n_late/n_legit;
            rt_table = table(Foreperiod, N_press, CorrectRatio, PrematureRatio, LateRatio);
            value = rt_table;
        end

        function value = get.AvgRT(obj)
            % Use calRT to compute RT
            rt.median=[];
            rt.median_ksdensity=[];
            N_press = [];

            for i = 1:length(obj.MixedFP)
                iFP = obj.MixedFP(i);
                ind_press   = find(obj.FP == obj.MixedFP(i) & strcmp(obj.Outcome,obj.OutcomeOptions{1}));
                HoldDurs    = obj.HT(ind_press); % turn it into ms
                iRTOut      = calRT(HoldDurs, iFP, 'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
                N_press(i)  = length(HoldDurs);
                rt.median(i)            = iRTOut.median;
                rt.median_ksdensity(i)  = iRTOut.median_ksdensity;
            end

            i=i+1;
            ind_press   = find(strcmp(obj.Outcome,obj.OutcomeOptions{1}));
            FPs         = obj.FP(ind_press);
            HoldDurs    = obj.HT(ind_press); % turn it into ms
            iRTOut = calRT(HoldDurs, FPs, 'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);

            N_press(i) = length(HoldDurs);
            rt.median(i) = iRTOut.median;
            rt.median_ksdensity(i) = iRTOut.median_ksdensity;

            Foreperiod = [num2cell(obj.MixedFP(:)); 'All'];
            RT_median = rt.median';
            RT_median_ksdensity = rt.median_ksdensity';
            N_press = N_press';
            rt_table = table(Foreperiod, N_press, RT_median, RT_median_ksdensity);
            value = rt_table;
        end

        function value = get.AvgRTLoose(obj)
            % Use calRT to compute RT
            rt.median=[];
            rt.median_ksdensity=[];
            N_press = [];

            for i = 1:length(obj.MixedFP)
                iFP = obj.MixedFP(i);
                ind_press   = find(obj.FP == obj.MixedFP(i) &...
                    (strcmp(obj.Outcome,obj.OutcomeOptions{1}) | strcmp(obj.Outcome,obj.OutcomeOptions{3})));
                HoldDurs    = obj.HT(ind_press); % turn it into ms
                iRTOut      = calRT(HoldDurs, iFP, 'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
                N_press(i)  = length(HoldDurs);
                rt.median(i)            = iRTOut.median;
                rt.median_ksdensity(i)  = iRTOut.median_ksdensity;
            end

            i=i+1;
            ind_press   = find(strcmp(obj.Outcome,obj.OutcomeOptions{1}) | strcmp(obj.Outcome,obj.OutcomeOptions{3}));
            FPs         = obj.FP(ind_press);
            HoldDurs    = obj.HT(ind_press); % turn it into ms
            iRTOut = calRT(HoldDurs, FPs, 'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);

            N_press(i) = length(HoldDurs);
            rt.median(i) = iRTOut.median;
            rt.median_ksdensity(i) = iRTOut.median_ksdensity;

            Foreperiod = [num2cell(obj.MixedFP(:)); 'All'];
            RT_median = rt.median';
            RT_median_ksdensity = rt.median_ksdensity';
            N_press = N_press';
            rt_table = table(Foreperiod, N_press, RT_median, RT_median_ksdensity);
            value = rt_table;
        end

        function out = outcomeProgress(obj,targetOutcome,options)
            arguments
                obj
                targetOutcome = obj.OutcomeOptions(1:3) % {'Cor','Pre','Late'}
                options.avgMethod {mustBeMember(options.avgMethod,{'mean','median'})} = 'mean'
                options.slidingMethod {mustBeMember(options.slidingMethod,{'ratio','fixed'})} = 'ratio'
                options.winRatio = 8
                options.stepRatio = 2
                options.winSize = 30
                options.stepSize = 15
            end
            out = struct;
            switch options.slidingMethod
                case 'ratio'
                    options.winSize = [];
                    options.stepSize = [];
                case 'fixed'
                    options.winRatio = [];
                    options.stepRatio = [];
            end
            out.x = table;
            out.y = table;
            out.options = options;
            for i=1:length(targetOutcome)
                [x,y] = calMovAVG(obj.Table.TimeElapsed,obj.Table.Outcome,...
                    'winRatio',options.winRatio,'stepRatio',options.stepRatio,...
                    'winSize',options.winSize,'stepSize',options.stepSize,...
                    'tarStr',targetOutcome{i},'avgMethod',options.avgMethod);
                out.x = addvars(out.x,x,'NewVariableNames',targetOutcome{i});
                out.y = addvars(out.y,y,'NewVariableNames',targetOutcome{i});
            end
        end
        
        function [objOut,isMerge] = merge(obj,objNew,method,just1Day)
            arguments
                obj
                objNew BehaviorDSRT
                method {mustBeMember(method,{'merge','select','Merge','Select','MERGE','SELECT'})} = 'merge'
%                 method {mustBeMergeMethod(method)} = 'Merge'
                just1Day = true
            end
            objOut = obj;
            isMerge = false;
            if just1Day && ~isequal(obj.Date,objNew.Date)
                return
            elseif ~strcmpi(obj.Subject,objNew.Subject)...
                    || ~strcmpi(obj.Task,objNew.Task)
                return
            end
            if strcmpi(method,'select') % select the bigger data (more trials)
                if obj.nTrial < objNew.nTrial
                    objOut = objNew;
                end
                isMerge = true;
                return
            end
            % merge method
            diffTime = minus(obj.DateTime,objNew.DateTime);
            diffSec = abs(seconds(diffTime)); % when isNewEarly==true, diffSec>0
            if diffTime>0
                isNewEarly = true;
            else
                isNewEarly = false;
            end
            objOut = obj;
            if isNewEarly
                objOut.Date = objNew.Date;
                objOut.DateTime = objNew.DateTime;
                objOut.nTrial = obj.nTrial + objNew.nTrial;
                objOut.iTrial = (1:objOut.nTrial)';
                
                objOut.BlockNum = [objNew.BlockNum(:);obj.BlockNum(:)];
                objOut.TrialNum = [objNew.TrialNum(:);obj.TrialNum(:)];
                objOut.TrialType = [objNew.TrialType(:);obj.TrialType(:)];
                objOut.TimeElapsed = [objNew.TimeElapsed(:);(obj.TimeElapsed(:)+diffSec)];
                objOut.FP = [objNew.FP(:);obj.FP(:)];
                objOut.RW = [objNew.RW(:);obj.RW(:)];
                objOut.DarkTry = [objNew.DarkTry(:);obj.DarkTry(:)];
                objOut.ConfuseNum = [objNew.ConfuseNum(:);obj.ConfuseNum(:)];
                objOut.Outcome = [objNew.Outcome(:);obj.Outcome(:)];
                objOut.HT = [objNew.HT(:);obj.HT(:)];
                objOut.RT = [objNew.RT(:);obj.RT(:)];
                objOut.MT = [objNew.MT(:);obj.MT(:)];
            else
                objOut.Date = obj.Date;
                objOut.DateTime = obj.DateTime;
                objOut.nTrial = obj.nTrial + objNew.nTrial;
                objOut.iTrial = (1:objOut.nTrial)';
                
                objOut.BlockNum = [obj.BlockNum(:);objNew.BlockNum(:)];
                objOut.TrialNum = [obj.TrialNum(:);objNew.TrialNum(:)];
                objOut.TrialType = [obj.TrialType(:);objNew.TrialType(:)];
                objOut.TimeElapsed = [obj.TimeElapsed(:);(objNew.TimeElapsed(:)+diffSec)];
                objOut.FP = [obj.FP(:);objNew.FP(:)];
                objOut.RW = [obj.RW(:);objNew.RW(:)];
                objOut.DarkTry = [obj.DarkTry(:);objNew.DarkTry(:)];
                objOut.ConfuseNum = [obj.ConfuseNum(:);objNew.ConfuseNum(:)];
                objOut.Outcome = [obj.Outcome(:);objNew.Outcome(:)];
                objOut.HT = [obj.HT(:);objNew.HT(:)];
                objOut.RT = [obj.RT(:);objNew.RT(:)];
                objOut.MT = [obj.MT(:);objNew.MT(:)];
            end
            isMerge = true;
        end

        function save(obj, savepath)
            arguments
                obj
                savepath = pwd;
            end
            [~,~] = mkdir(savepath);
            save(fullfile(savepath,obj.SaveName),'obj');
            writetable(obj.Table,fullfile(savepath,append(obj.SaveName,'.csv')));
        end

        function print(obj, varargin)
            hf = [];
            targetDir = pwd;
            for i=1:length(varargin)
                in = varargin{i};
                if isa(in,'matlab.ui.Figure')
                    hf = in;
                else
                    mustBeTextScalar(in)
                    targetDir = in;
                end
            end
            if isempty(hf)
                hf = obj.plot;
            end
            savename = obj.SaveName;
            [~,~] = mkdir(targetDir);
            savename = fullfile(targetDir,savename);
            saveas(hf, savename, 'fig');
%             export_fig(hf,savename,'-png','-eps');
            print(hf,'-dpng', savename);
            exportgraphics(hf,append(savename,'.eps'),'ContentType','vector');
        end

        function progFig = plot(obj)
            if strcmpi(obj.Task,'AutoShaping')
                progFig = plot_autoshaping(obj);
            elseif strcmpi(obj.Task,'LeverPress') || strcmpi(obj.Task,'LeverRelease')
                progFig = plot_leveroperant(obj);
            else
                progFig = plot_srt(obj);
            end

            function progFig = plot_srt(obj)
                cTab10 = [0.0901960784313726,0.466666666666667,0.701960784313725;0.960784313725490,0.498039215686275,0.137254901960784;0.152941176470588,0.631372549019608,0.278431372549020;0.843137254901961,0.149019607843137,0.172549019607843;0.564705882352941,0.403921568627451,0.674509803921569;0.549019607843137,0.337254901960784,0.290196078431373;0.847058823529412,0.474509803921569,0.698039215686275;0.501960784313726,0.501960784313726,0.501960784313726;0.737254901960784,0.745098039215686,0.196078431372549;0.113725490196078,0.737254901960784,0.803921568627451];
                cBlue = cTab10(1,:);
                cGreen = cTab10(3,:);
                cCyan = cTab10(10,:);
                cRed = cTab10(4,:);
                cGray = cTab10(8,:);
                cCPL = [cGreen;cRed;cGray];
                
                set(groot,'defaultAxesFontName','Helvetica');
    
                FontAxesSz = 7;
                FontLablSz = 9;
                FontTitlSz = 10;
                
                figSize = [2 2 15 17];
                plotsize1 = [8 4];
                plotsize2 = [3.5 4];
                plotsize3 = [2.5 4];
                plotsize4 = [3.5 1.7];
                xpos = [1.3,11];
                ypos = [1.3,6.6,11.9,13.9];
                
                tLim = [0 3600];
                htLim = [0 2500];
                bt = obj.Table;
                switch bt.Task(1)
                    case "3FPs"
                        figSize = [2 2 18.5 17];
                        xpos = [1.3 14.8 10];
                        rtLim = [0 1000];
                        rtLim2 = [100 600];
                        
                        fplist = unique(round(bt.FP,1))'; % [0.5 1.0 1.5]
                        switch length(fplist)
                            case 3
                                idxS = abs((bt.FP-fplist(1)))<1E-4;
                                idxM = abs((bt.FP-fplist(2)))<1E-4;
                                idxL = abs((bt.FP-fplist(3)))<1E-4;
                            case 2
                                idxS = abs((bt.FP-fplist(1)))<1E-4;
                                idxM = abs((bt.FP-fplist(2)))<1E-4;
                                idxL = false(size(bt.FP));
                                fplist = [fplist NaN];
                            case 1
                                idxS = abs((bt.FP-fplist(1)))<1E-4;
                                idxM = false(size(bt.FP));
                                idxL = false(size(bt.FP));
                                fplist = [fplist NaN NaN];
                            case 0
                                idxS = false(size(bt.FP));
                                idxM = false(size(bt.FP));
                                idxL = false(size(bt.FP));
                                fplist = nan(1,3);
                        end
                    case {"Wait1","Wait2"}
                        rtLim = [0 2000];
                        rtLim2 = [100 1100];
                        if bt.Task(1) == "Wait1"
                            criterion = [1.5, 2]; % FP 1.5s, RW 2s
                        else
                            criterion = [1.5, 0.6]; % FP 1.5s, RW 2s
                        end
                        idxCri = abs((bt.FP-criterion(1)))<1E-4 & abs((bt.RW-criterion(2)))<1E-4;
                        diffCri = diff([0;idxCri;0]); %
                        prdCri = [find(diffCri==1),find(diffCri==-1)-1];
                end
                idxCor = bt.Outcome == string(obj.OutcomeOptions{1});
                idxPre = bt.Outcome == string(obj.OutcomeOptions{2});
                idxLate = bt.Outcome == string(obj.OutcomeOptions{3});
                
                progFig = figure(obj.FigNum); clf(progFig);
                set(progFig, 'unit', 'centimeters', 'position',figSize,...
                    'paperpositionmode', 'auto', 'color', 'w');
                
                tt = obj.DateTime;
                uicontrol(progFig,'Style', 'text', 'units', 'centimeters',...
                    'position', [xpos(1)+plotsize1(1)/2-3,figSize(4)-0.6,6,0.5],...
                    'string', append(bt.Subject(1),' / ',char(tt,'yyyy-MM-dd HH:mm:ss')), 'fontweight', 'bold',...
                    'backgroundcolor', [1 1 1],'FontSize',FontTitlSz);
                
                % HT - Time
                ha1 = axes;
                set(ha1, 'units', 'centimeters', 'position', [xpos(1) ypos(1), plotsize1],...
                    'nextplot', 'add', 'ylim', htLim, 'xlim', tLim,'tickdir','out',...
                    'TickLength', [0.0200 0.0250],'fontsize',FontAxesSz);
                xlabel('Time in session (sec)','FontSize',FontLablSz)
                ylabel('Hold time (ms)','FontSize',FontLablSz)
                
                modiHT = bt.HT.*1000; modiHT(modiHT>htLim(2)) = htLim(2);
                switch bt.Task(1)
                    case {"Wait1","Wait2"}
                        for i=1:size(prdCri,1)
                            fill([repelem(bt.TimeElapsed(prdCri(i,1)),2),repelem(bt.TimeElapsed(prdCri(i,2)),2)],...
                                [htLim(1),htLim(2),htLim(2),htLim(1)],cCyan,'EdgeColor','none','FaceAlpha',0.1);
                        end
                    case "3FPs"
                        line(tLim,[fplist(1) fplist(1)].*1000,'LineStyle',':',...
                                'color',cBlue,'linewidth',1.28);
                        line(tLim,[fplist(2) fplist(2)].*1000,'LineStyle','-.',...
                                'color',cBlue,'linewidth',1.2);
                        line(tLim,[fplist(3) fplist(3)].*1000,'LineStyle','-',...
                                'color',cBlue,'linewidth',1.1);
                end
                line([bt.TimeElapsed,bt.TimeElapsed],[htLim(1),htLim(1)+diff(htLim)/10],...
                    'color',cBlue,'linewidth',0.4);
                scatter(bt.TimeElapsed(idxCor),modiHT(idxCor),30,cCPL(1,:),...
                    'MarkerEdgeAlpha',0.85,'LineWidth',1.1);
                scatter(bt.TimeElapsed(idxPre),modiHT(idxPre),30,cCPL(2,:),...
                    'MarkerEdgeAlpha',0.85,'LineWidth',1.1);
                scatter(bt.TimeElapsed(idxLate),modiHT(idxLate),30,cCPL(3,:),...
                    'MarkerEdgeAlpha',0.85,'LineWidth',1.1);
                if ismember(bt.Task(1),["Wait1","Wait2"])
                    plot(bt.TimeElapsed,bt.FP.*1000,'--','color','k','LineWidth',1);
                end
                
                % RT - Time
                ha2 = axes;
                set(ha2, 'units', 'centimeters', 'position', [xpos(1) ypos(2), plotsize1],...
                    'nextplot', 'add', 'ylim', rtLim, 'xlim', tLim,'tickdir','out',...
                    'TickLength', [0.0200 0.0250],'fontsize',FontAxesSz);
                xlabel('Time in session (sec)','FontSize',FontLablSz);
                ylabel('Reaction time (ms)','FontSize',FontLablSz);
                
                modiRT = (bt.HT - bt.FP).*1000;
                modiRT(modiRT>rtLim(2)) = rtLim(2);
                modiRT(modiRT<rtLim(1)) = rtLim(1);
                switch bt.Task(1)
                    case {"Wait1","Wait2"}
                        for i=1:size(prdCri,1)
                            fill([repelem(bt.TimeElapsed(prdCri(i,1)),2),repelem(bt.TimeElapsed(prdCri(i,2)),2)],...
                                [rtLim(1),rtLim(2),rtLim(2),rtLim(1)],cCyan,'EdgeColor','none','FaceAlpha',0.1);
                        end
                    case "3FPs"
                        fill([tLim(1) tLim(2) tLim(2) tLim(1)],...
                            [rtLim(1) rtLim(1) 600 600],...
                            cGreen,'FaceAlpha',0.1,'EdgeColor',cGreen,'EdgeAlpha',0.2);
                end
                scatter(bt.TimeElapsed(idxCor),modiRT(idxCor),30,cCPL(1,:),...
                    'MarkerEdgeAlpha',0.85,'LineWidth',1.1);
                %     scatter(bt.TimeElapsed(idxPre),modiRT(idxPre),30,cCPL(2,:),...
                %         'MarkerFaceAlpha',0.8,'LineWidth',1.1);
                scatter(bt.TimeElapsed(idxLate),modiRT(idxLate),30,cCPL(3,:),...
                    'MarkerEdgeAlpha',0.85,'LineWidth',1.1);
                if strcmp(bt.Task(1),"Wait2")
                    plot(bt.TimeElapsed,bt.RW.*1000,'--','color','k','LineWidth',1);
                end
                
                % Sliding Performance - Time
                sldRe = obj.outcomeProgress(obj.OutcomeOptions(1:3),...
                    'avgMethod','mean','slidingMethod','ratio','winRatio',8,'stepRatio',2);
                ha3 = axes;
                set(ha3, 'units', 'centimeters', 'position', [xpos(1) ypos(3), plotsize1],...
                    'nextplot', 'add', 'ylim', [0 100], 'xlim', tLim,'tickdir','out',...
                    'TickLength', [0.0200 0.0250],'fontsize',FontAxesSz);
                xlabel('Time in session (sec)','FontSize',FontLablSz);
                ylabel('Performance (%)','FontSize',FontLablSz);
                
                %     mc = 100.*sum(strcmp(bt.Outcome,obj.OutcomeOptions{1}))./length(bt.Outcome);
                %     mp = 100.*sum(strcmp(bt.Outcome,obj.OutcomeOptions{2}))./length(bt.Outcome);
                %     ml = 100.*sum(strcmp(bt.Outcome,obj.OutcomeOptions{3}))./length(bt.Outcome);
                %     line(tLim,repelem(mc,2)','LineStyle','--','color',cCPL(1,:),'LineWidth',1.5);
                %     line(tLim,repelem(mp,2)','LineStyle','--','color',cCPL(2,:),'LineWidth',1.5);
                %     line(tLim,repelem(ml,2)','LineStyle','--','color',cCPL(3,:),'LineWidth',1.5);
                plot(sldRe.x.(obj.OutcomeOptions{1}), sldRe.y.(obj.OutcomeOptions{1}),...
                    'o', 'linestyle', '-', 'color', cCPL(1,:), ...
                    'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', cCPL(1,:),...
                    'markeredgecolor', 'w');
                plot(sldRe.x.(obj.OutcomeOptions{2}), sldRe.y.(obj.OutcomeOptions{2}),...
                    'o', 'linestyle', '-', 'color', cCPL(2,:), ...
                    'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', cCPL(2,:),...
                    'markeredgecolor', 'w');
                plot(sldRe.x.(obj.OutcomeOptions{3}), sldRe.y.(obj.OutcomeOptions{3}),...
                    'o', 'linestyle', '-', 'color', cCPL(3,:), ...
                    'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', cCPL(3,:),...
                    'markeredgecolor', 'w');
                
                % Num of Outcome
                ha4 = axes;
                set(ha4, 'units', 'centimeters', 'position', [xpos(2) ypos(1), plotsize2],...
                    'nextplot', 'add', 'tickdir','out',...
                    'TickLength', [0.0200 0.0250],'fontsize',FontAxesSz);
                xlabel('','FontSize',FontLablSz);
                ylabel('Number','FontSize',FontLablSz);
                X = categorical({'Correct','Premature','Late','Dark'});
                X = reordercats(X,{'Correct','Premature','Late','Dark'});
                bh = bar(X,[sum(idxCor),sum(idxPre),sum(idxLate),sum(bt.DarkTry)],...
                    'FaceColor','flat','EdgeColor','none');
                bh.CData(1,:) = cCPL(1,:);
                bh.CData(2,:) = cCPL(2,:);
                bh.CData(3,:) = cCPL(3,:);
                bh.CData(4,:) = [0 0 0];
                xtps = bh.XEndPoints;
                ytps = bh.YEndPoints;
                Labl = string(bh.YData);
                text(xtps,ytps,Labl,'HorizontalAlignment','center',...
                    'VerticalAlignment','bottom','fontsize',FontAxesSz);
                
                switch bt.Task(1)
                    case "3FPs"
                        % Reaction time - 3FPs
                        ha5 = axes;
                        set(ha5, 'units', 'centimeters', 'position', [xpos(2) ypos(2), plotsize2],...
                            'nextplot', 'add', 'tickdir','out',...
                            'xlim',[min(fplist).*1000-100,max(fplist).*1000+100],...
                            'ylim',rtLim2,...
                            'TickLength', [0.0200 0.0250],'fontsize',FontAxesSz);
                        xlabel('Foreperiod (ms)','FontSize',FontLablSz);
                        ylabel('Reaction time (ms)','FontSize',FontLablSz);
                        
                        rtS = calRT(bt.HT(idxCor&idxS).*1000,bt.FP(idxCor&idxS).*1000,...
                            'Remove100ms',true,'RemoveOutliers',true,'ToPlot',false,'Calse',false);
                        rtM = calRT(bt.HT(idxCor&idxM).*1000,bt.FP(idxCor&idxM).*1000,...
                            'Remove100ms',true,'RemoveOutliers',true,'ToPlot',false,'Calse',false);
                        rtL = calRT(bt.HT(idxCor&idxL).*1000,bt.FP(idxCor&idxL).*1000,...
                            'Remove100ms',true,'RemoveOutliers',true,'ToPlot',false,'Calse',false);
                        rtS_L = calRT(bt.HT((idxLate|idxCor)&idxS).*1000,bt.FP((idxLate|idxCor)&idxS).*1000,...
                            'Remove100ms',true,'RemoveOutliers',true,'ToPlot',false,'Calse',false);
                        rtM_L = calRT(bt.HT((idxLate|idxCor)&idxM).*1000,bt.FP((idxLate|idxCor)&idxM).*1000,...
                            'Remove100ms',true,'RemoveOutliers',true,'ToPlot',false,'Calse',false);
                        rtL_L = calRT(bt.HT((idxLate|idxCor)&idxL).*1000,bt.FP((idxLate|idxCor)&idxL).*1000,...
                            'Remove100ms',true,'RemoveOutliers',true,'ToPlot',false,'Calse',false);
                        plot(fplist.*1000,[rtS.median,rtM.median,rtL.median],'^-','color',cGreen,...
                            'markersize', 7, 'linewidth', 1.5, 'markerfacecolor', cGreen,...
                            'MarkerEdgeColor', 'w');
                        plot(fplist.*1000,[rtS_L.median,rtM_L.median,rtL_L.median],'o-','color',cGray,...
                            'markersize', 7, 'linewidth', 1.5, 'markerfacecolor', cGray,...
                            'MarkerEdgeColor', 'w');
                        le = legend({'Strict','Loose'},'fontsize',FontAxesSz,'Location','northeast');
                        legend('boxoff');
                        le.ItemTokenSize(1) = 15;
                        
                        % Performance - 3FPs
                        ha6 = axes;
                        set(ha6, 'units', 'centimeters', 'position', [xpos(2) ypos(3), plotsize2],...
                            'nextplot', 'add', 'tickdir','out','ylim',[0 100],...
                            'TickLength', [0.0200 0.0250],'fontsize',FontAxesSz);
                        xlabel('Foreperiod (ms)','FontSize',FontLablSz);
                        ylabel('Performance (%)','FontSize',FontLablSz);
                        
                        OutS = bt.Outcome(idxS);
                        OutM = bt.Outcome(idxM);
                        OutL = bt.Outcome(idxL);
                        
                        bh2 = bar(fplist.*1000,...
                            [sum(OutS==string(obj.OutcomeOptions{1}))/length(OutS),sum(OutS==string(obj.OutcomeOptions{2}))/length(OutS),sum(OutS==string(obj.OutcomeOptions{3}))/length(OutS);...
                             sum(OutM==string(obj.OutcomeOptions{1}))/length(OutM),sum(OutM==string(obj.OutcomeOptions{2}))/length(OutM),sum(OutM==string(obj.OutcomeOptions{3}))/length(OutM);...
                             sum(OutL==string(obj.OutcomeOptions{1}))/length(OutL),sum(OutL==string(obj.OutcomeOptions{2}))/length(OutL),sum(OutL==string(obj.OutcomeOptions{3}))/length(OutL);].*100,...
                            'FaceColor','flat','EdgeColor','none');
                        bh2(1).FaceColor = cCPL(1,:);
                        bh2(2).FaceColor = cCPL(2,:);
                        bh2(3).FaceColor = cCPL(3,:);
                        xtps1 = bh2(1).XEndPoints; xtps2 = bh2(2).XEndPoints; xtps3 = bh2(3).XEndPoints;
                        ytps1 = bh2(1).YEndPoints; ytps2 = bh2(2).YEndPoints; ytps3 = bh2(3).YEndPoints;
                        Labl1 = string(round(bh2(1).YData)); Labl2 = string(round(bh2(2).YData)); Labl3 = string(round(bh2(3).YData));
                        text(xtps1,ytps1,Labl1,'HorizontalAlignment','center',...
                            'VerticalAlignment','bottom','fontsize',FontAxesSz);
                        text(xtps2,ytps2,Labl2,'HorizontalAlignment','center',...
                            'VerticalAlignment','bottom','fontsize',FontAxesSz);
                        text(xtps3,ytps3,Labl3,'HorizontalAlignment','center',...
                            'VerticalAlignment','bottom','fontsize',FontAxesSz);

                        % Distribution - 3FPs
                        % HT pdf
                        edges_HT = 0:0.05:2.5;
                        HTpdf.S = ksdensity(bt.HT(idxS),edges_HT);
                        HTpdf.M = ksdensity(bt.HT(idxM),edges_HT);
                        HTpdf.L = ksdensity(bt.HT(idxL),edges_HT);
                        HTcdf.S = ksdensity(bt.HT(idxS),edges_HT,'Function','cdf');
                        HTcdf.M = ksdensity(bt.HT(idxM),edges_HT,'Function','cdf');
                        HTcdf.L = ksdensity(bt.HT(idxL),edges_HT,'Function','cdf');

                        ha7 = axes;
                        set(ha7, 'units', 'centimeters', 'position', [xpos(3) ypos(1), plotsize3],...
                            'nextplot', 'add', 'tickdir','out','ylim',htLim,...
                            'ytick',ha1.YTick,'yticklabel',{},...
                            'TickLength', [0.0200 0.0250],'fontsize',FontAxesSz);
                        xlabel('pdf (s^{-1})','FontSize',FontLablSz);
                        ylabel('','FontSize',FontLablSz);

                        plot(HTpdf.S,edges_HT.*1000,':k','lineWidth',1.28);
                        plot(HTpdf.M,edges_HT.*1000,'-.k','lineWidth',1.2);
                        plot(HTpdf.L,edges_HT.*1000,'-k','lineWidth',1.1);
                        line(ha7.XLim,[fplist(1) fplist(1)].*1000,'LineStyle',':',...
                                'color',cBlue,'linewidth',1.28);
                        line(ha7.XLim,[fplist(2) fplist(2)].*1000,'LineStyle','-.',...
                                'color',cBlue,'linewidth',1.2);
                        line(ha7.XLim,[fplist(3) fplist(3)].*1000,'LineStyle','-',...
                                'color',cBlue,'linewidth',1.1);

                        % RT pdf
                        edges_RelT = 0:0.025:1;
                        RelTpdf.S = ksdensity(bt.RelT(idxS&(idxCor|idxLate)),edges_RelT);
                        RelTpdf.M = ksdensity(bt.RelT(idxM&(idxCor|idxLate)),edges_RelT);
                        RelTpdf.L = ksdensity(bt.RelT(idxL&(idxCor|idxLate)),edges_RelT);

                        ha8 = axes;
                        set(ha8, 'units', 'centimeters', 'position', [xpos(3) ypos(2), plotsize3],...
                            'nextplot', 'add', 'tickdir','out','ylim',rtLim,...
                            'ytick',ha2.YTick,'yticklabel',{},...
                            'TickLength', [0.0200 0.0250],'fontsize',FontAxesSz);
                        xlabel('pdf (s^{-1})','FontSize',FontLablSz);
                        ylabel('','FontSize',FontLablSz);

%                         line([0,4],[600 600],'LineStyle','-',...
%                                 'color',cGreen,'linewidth',1.1);
%                         fill([0 4 4 0],[rtLim(1) rtLim(1) 600 600],...
%                             cGreen,'FaceAlpha',0.15,'EdgeColor',cGreen,'EdgeAlpha',0.25);
                        plot(RelTpdf.S,edges_RelT.*1000,':k','lineWidth',1.28);
                        plot(RelTpdf.M,edges_RelT.*1000,'-.k','lineWidth',1.2);
                        plot(RelTpdf.L,edges_RelT.*1000,'-k','lineWidth',1.1);
                        fill([ha8.XLim(1) ha8.XLim(2) ha8.XLim(2) ha8.XLim(1)],...
                            [rtLim(1) rtLim(1) 600 600],...
                            cGreen,'FaceAlpha',0.1,'EdgeColor',cGreen,'EdgeAlpha',0.2);

                        % HT PDF & CDF
                        ha9 = axes;
                        set(ha9, 'units', 'centimeters', 'position', [xpos(3) ypos(3), plotsize4],...
                            'nextplot', 'add', 'tickdir','out','xlim',htLim,'xtick',ha1.YTick,'ytick',ha7.XTick,...
                            'TickLength', [0.0200 0.0250],'fontsize',FontAxesSz);
                        ylabel('pdf (s^{-1})','FontSize',FontLablSz);
                        xlabel('Hold time (ms)','FontSize',FontLablSz);

                        plot(edges_HT.*1000,HTpdf.S,':k','lineWidth',1.28);
                        plot(edges_HT.*1000,HTpdf.M,'-.k','lineWidth',1.2);
                        plot(edges_HT.*1000,HTpdf.L,'-k','lineWidth',1.1);
                        line([fplist(1) fplist(1)].*1000,ha9.YLim,'LineStyle',':',...
                                'color',cBlue,'linewidth',1.28);
                        line([fplist(2) fplist(2)].*1000,ha9.YLim,'LineStyle','-.',...
                                'color',cBlue,'linewidth',1.2);
                        line([fplist(3) fplist(3)].*1000,ha9.YLim,'LineStyle','-',...
                                'color',cBlue,'linewidth',1.1);
                        
                        ha10 = axes;
                        set(ha10, 'units', 'centimeters', 'position', [xpos(3) ypos(4), plotsize4],...
                            'nextplot', 'add', 'tickdir','out','xlim',htLim,...
                            'xtick',ha9.XTick,'xticklabel',{},'yLim',[0 1],...
                            'TickLength', [0.0200 0.0250],'fontsize',FontAxesSz);
                        ylabel('cdf','FontSize',FontLablSz);
                        xlabel('','FontSize',FontLablSz);

                        line([fplist(1) fplist(1)].*1000,ha10.YLim,'LineStyle',':',...
                                'color',cBlue,'linewidth',1.28);
                        line([fplist(2) fplist(2)].*1000,ha10.YLim,'LineStyle','-.',...
                                'color',cBlue,'linewidth',1.2);
                        line([fplist(3) fplist(3)].*1000,ha10.YLim,'LineStyle','-',...
                                'color',cBlue,'linewidth',1.1);
                        plot(edges_HT.*1000,HTcdf.S,':k','lineWidth',1.28);
                        plot(edges_HT.*1000,HTcdf.M,'-.k','lineWidth',1.2);
                        plot(edges_HT.*1000,HTcdf.L,'-k','lineWidth',1.1);
                        
                    case {"Wait1","Wait2"}
                        % Reaction time - progress/criterion
                        ha5 = axes;
                        set(ha5, 'units', 'centimeters', 'position', [xpos(2) ypos(2), plotsize2],...
                            'nextplot', 'add', 'tickdir','out','ylim',rtLim2,...
                            'TickLength', [0.0200 0.0250],'fontsize',FontAxesSz);
                        xlabel('','FontSize',FontLablSz);
                        ylabel('Reaction time (ms)','FontSize',FontLablSz);
                
                        xtik = categorical({'InProgress','InCriterion'});
                        xtik = reordercats(xtik,{'InProgress','InCriterion'});
                        rtPro = calRT(bt.HT(idxCor & ~idxCri).*1000,bt.FP(idxCor & ~idxCri).*1000,...
                            'Remove100ms',true,'RemoveOutliers',true,'ToPlot',false,'Calse',false);
                        rtCri = calRT(bt.HT(idxCor & idxCri).*1000,bt.FP(idxCor & idxCri).*1000,...
                            'Remove100ms',true,'RemoveOutliers',true,'ToPlot',false,'Calse',false);
                        rtPro_L = calRT(bt.HT((idxLate|idxCor) & ~idxCri).*1000,bt.FP((idxLate|idxCor) & ~idxCri).*1000,...
                            'Remove100ms',true,'RemoveOutliers',true,'ToPlot',false,'Calse',false);
                        rtCri_L = calRT(bt.HT((idxLate|idxCor) & idxCri).*1000,bt.FP((idxLate|idxCor) & idxCri).*1000,...
                            'Remove100ms',true,'RemoveOutliers',true,'ToPlot',false,'Calse',false);
                        bh2 = bar(xtik,...
                            [rtPro.median(1),rtPro_L.median(1);rtCri.median(1),rtCri_L.median(1)],...
                            'FaceColor','flat','EdgeColor','none');
                %             xtps1 = bh2(1).XEndPoints; xtps2 = bh2(2).XEndPoints;
                %             ytps1 = bh2(1).YEndPoints; ytps2 = bh2(2).YEndPoints;
                %             errorbar([xtps1,xtps2],[ytps1,ytps2],...
                %                 [rtPro.median(2),rtCri.median(2),rtPro_L.median(2),rtCri_L.median(2)],...
                %                 '.k');
                        bh2(1).FaceColor = cCPL(1,:);
                        bh2(2).FaceColor = cCPL(3,:);
                        xtps1 = bh2(1).XEndPoints; xtps2 = bh2(2).XEndPoints;
                        ytps1 = bh2(1).YEndPoints; ytps2 = bh2(2).YEndPoints;
                        Labl1 = string(round(bh2(1).YData)); Labl2 = string(round(bh2(2).YData));
                        text(xtps1,ytps1,Labl1,'HorizontalAlignment','center',...
                            'VerticalAlignment','bottom','fontsize',FontAxesSz);
                        text(xtps2,ytps2,Labl2,'HorizontalAlignment','center',...
                            'VerticalAlignment','bottom','fontsize',FontAxesSz);
                        le = legend({'Strict','Loose'},'Location','northwest');
                        legend('boxoff');
                        le.ItemTokenSize(1) = 15;
                        
                        % Performance - progress/criterion
                        ha6 = axes;
                        set(ha6, 'units', 'centimeters', 'position', [xpos(2) ypos(3), plotsize2],...
                            'nextplot', 'add', 'tickdir','out','ylim',[0 100],...
                            'TickLength', [0.0200 0.0250],'fontsize',FontAxesSz);
                        xlabel('','FontSize',FontLablSz);
                        ylabel('Performance (%)','FontSize',FontLablSz);
                        
                        outPro = bt.Outcome(~idxCri);
                        outCri = bt.Outcome(idxCri);
                        bh3 = bar(xtik,...
                            [sum(outPro==string(obj.OutcomeOptions{1}))/length(outPro),sum(outPro==string(obj.OutcomeOptions{2}))/length(outPro),sum(outPro==string(obj.OutcomeOptions{3}))/length(outPro);...
                             sum(outCri==string(obj.OutcomeOptions{1}))/length(outCri),sum(outCri==string(obj.OutcomeOptions{2}))/length(outCri),sum(outCri==string(obj.OutcomeOptions{3}))/length(outCri)].*100,...
                            'FaceColor','flat','EdgeColor','none');
                        bh3(1).FaceColor = cCPL(1,:);
                        bh3(2).FaceColor = cCPL(2,:);
                        bh3(3).FaceColor = cCPL(3,:);
                        xtps1 = bh3(1).XEndPoints; xtps2 = bh3(2).XEndPoints; xtps3 = bh3(3).XEndPoints;
                        ytps1 = bh3(1).YEndPoints; ytps2 = bh3(2).YEndPoints; ytps3 = bh3(3).YEndPoints;
                        Labl1 = string(round(bh3(1).YData)); Labl2 = string(round(bh3(2).YData)); Labl3 = string(round(bh3(3).YData));
                        text(xtps1,ytps1,Labl1,'HorizontalAlignment','center',...
                            'VerticalAlignment','bottom','fontsize',FontAxesSz);
                        text(xtps2,ytps2,Labl2,'HorizontalAlignment','center',...
                            'VerticalAlignment','bottom','fontsize',FontAxesSz);
                        text(xtps3,ytps3,Labl3,'HorizontalAlignment','center',...
                            'VerticalAlignment','bottom','fontsize',FontAxesSz);
                end
            end
            
            function progFig = plot_leveroperant(obj)
                cTab10 = [0.0901960784313726,0.466666666666667,0.701960784313725;0.960784313725490,0.498039215686275,0.137254901960784;0.152941176470588,0.631372549019608,0.278431372549020;0.843137254901961,0.149019607843137,0.172549019607843;0.564705882352941,0.403921568627451,0.674509803921569;0.549019607843137,0.337254901960784,0.290196078431373;0.847058823529412,0.474509803921569,0.698039215686275;0.501960784313726,0.501960784313726,0.501960784313726;0.737254901960784,0.745098039215686,0.196078431372549;0.113725490196078,0.737254901960784,0.803921568627451];
                cBlue = cTab10(10,:);
                cGreen = cTab10(3,:);
                cGray = cTab10(8,:);
                cDark = [0 0 0];
                cWhite = [1,1,1];
                
                tLim = [0 4000];
                mtLim = [0,3];
                htLim = [0 1];

                bt = obj.Table;
                
                plotsize1 = [6, 3.5];
                progFig = figure(obj.FigNum); clf(progFig);
                set(progFig, 'unit', 'centimeters', 'position',[2 2 9 10], 'paperpositionmode', 'auto', 'color', 'w');
                
                tt = obj.DateTime;
                uicontrol(progFig,'Style', 'text', 'units', 'normalized',...
                    'position', [0.17 0.84 0.7 0.14],...
                    'string', append(bt.Subject(1),' / ',char(tt,'yyyy-MM-dd HH:mm:ss')), 'fontweight', 'bold',...
                    'backgroundcolor', [1 1 1]);
                
                % MT-t
                ymax = mtLim(2);ymin = mtLim(1);
                ha1 = axes;
                set(ha1, 'units', 'centimeters', 'position', [1.5 5.5, plotsize1],...
                    'nextplot', 'add', 'ylim', [ymin ymax], 'xlim', tLim,...
                    'tickdir','out');
%                 xlabel('Time in session (sec)');
                ylabel('Movement time (sec)');
                
                btMT = bt(~isnan(bt.MT),:);
                btMT.MT(btMT.MT>ymax) = ymax;
                btMT.MT(btMT.MT<ymin) = ymin;
                line([btMT.TimeElapsed,btMT.TimeElapsed],[ymin,ymin+abs(ymax-ymin)/10],...
                    'color',cBlue,'linewidth',0.4);
                line([0 4200],[median(btMT.MT),median(btMT.MT)],'linestyle','--','color',cDark,'linewidth',1.5);
                scatter(btMT.TimeElapsed,btMT.MT,...
                    30, cGreen,'o','MarkerEdgeAlpha', 0.7, 'linewidth', 1.1);
                text(4200,median(btMT.MT),{'median',sprintf('%.1f(s)',median(btMT.MT))},'FontSize',8);
                
                % HT-t
                ymax = htLim(2);ymin = htLim(1);
                ha2 = axes;
                set(ha2, 'units', 'centimeters', 'position', [1.5 1, plotsize1],...
                    'nextplot', 'add', 'ylim', [ymin ymax], 'xlim', tLim,...
                    'tickdir','out');
                xlabel('Time in session (sec)');
                ylabel('Press duration (sec)');
                
                btHT = bt(~isnan(bt.HT),:);
                btHT.HT(btHT.HT>ymax) = ymax;
                btHT.HT(btHT.HT<ymin) = ymin;
                line([btHT.TimeElapsed,btHT.TimeElapsed],[ymin,ymin+abs(ymax-ymin)/15],...
                    'color',cBlue,'linewidth',0.4);
                line([0 4200],[median(btHT.HT),median(btHT.HT)],'linestyle','--','color',cDark,'linewidth',1.5);
                scatter(btHT.TimeElapsed,btHT.HT,...
                    30, cGreen,'o','MarkerEdgeAlpha', 0.7, 'linewidth', 1.1);
                text(4200,median(btHT.HT),{'median',sprintf('%.1f(s)',median(btHT.HT))},'FontSize',8);
            end

            function progFig = plot_autoshaping(obj)
                col_perf = [85  225   0
                            255   0   0
                            140 140 140]/255;
                cTab10 = [0.0901960784313726,0.466666666666667,0.701960784313725;0.960784313725490,0.498039215686275,0.137254901960784;0.152941176470588,0.631372549019608,0.278431372549020;0.843137254901961,0.149019607843137,0.172549019607843;0.564705882352941,0.403921568627451,0.674509803921569;0.549019607843137,0.337254901960784,0.290196078431373;0.847058823529412,0.474509803921569,0.698039215686275;0.501960784313726,0.501960784313726,0.501960784313726;0.737254901960784,0.745098039215686,0.196078431372549;0.113725490196078,0.737254901960784,0.803921568627451];
                cBlue = cTab10(10,:);
                cGreen = cTab10(3,:);
                cGray = cTab10(8,:);
                cDark = [0 0 0];
                cWhite = [1,1,1];
                
                qLim = [0.12,6]; % qualified trials criterion
                
                bt = obj.Table;

                progFig = figure(obj.FigNum); clf(progFig);
                set(progFig, 'unit', 'centimeters', 'position',[2 2 9 10], 'paperpositionmode', 'auto', 'color', 'w')
                
                plotsize1 = [6, 3.5];
                plotsize2 = [3, 3.5];
                
                tt = obj.DateTime;
                uicontrol(progFig,'Style', 'text', 'units', 'normalized',...
                    'position', [0.17 0.94 0.7 0.05],...
                    'string', append(bt.Subject(1),' / ',char(tt,'yyyy-MM-dd HH:mm:ss')), 'fontweight', 'bold',...
                    'backgroundcolor', [1 1 1]);
                
                % MT-t
                ymax = 60;ymin = 0.1;
                ha1 = axes;
                set(ha1, 'units', 'centimeters', 'position', [1.5 5.5, plotsize1],...
                    'nextplot', 'add', 'ylim', [ymin ymax], 'xlim', [1 4200],...
                    'yscale', 'log','tickdir','out');
                xlabel('Time in session (sec)')
                ylabel('Movement time (sec)')
                
                btMT = bt(~isnan(bt.MT),:);
                btMT.MT(btMT.MT>ymax) = ymax;
                btMT.MT(btMT.MT<ymin) = ymin;
                idxVal = bt.MT>qLim(1) & bt.MT<qLim(2);
                idxInv = isnan(bt.MT) | bt.MT<=qLim(1) | bt.MT>=qLim(2);
                newOutc = repelem("",length(bt.Outcome))';
                newOutc(idxVal) = obj.OutcomeOptions{1};
                newOutc(idxInv) = obj.OutcomeOptions{4};
                btn = addvars(bt,newOutc,'NewVariableNames','criOutcome');
            
                fill([0,4200,4200,0],[qLim(1),qLim(1),qLim(2),qLim(2)],cGreen,'EdgeColor','none','FaceAlpha',0.2);
            
                line([bt.TimeElapsed(idxInv),bt.TimeElapsed(idxInv)], [ymin ymin+0.04], 'color',cDark, 'linewidth', 0.4); % invalid trial
                line([bt.TimeElapsed(idxVal),bt.TimeElapsed(idxVal)], [ymin+0.04 ymin+0.1], 'color',cBlue, 'linewidth', 0.4); % valid trial
                line([0 4200],[median(btMT.MT),median(btMT.MT)],'linestyle','--','color',cDark,'linewidth',1.5);
                scatter(btMT.TimeElapsed,btMT.MT,...
                    30, cGreen,'o','Markerfacealpha', 0.9, 'linewidth', 1.1);
                
                text(4200,median(btMT.MT),{'median',sprintf('%.1f(s)',median(btMT.MT))},'FontSize',8);
                text(4200,ymin+0.13,sprintf('Qualif %.0f',sum(strcmp(btn.criOutcome,obj.OutcomeOptions{1}))),'FontSize',8,'color',cBlue.*0.8);
                text(4200,ymin+0.03,sprintf('Unqual %.0f',sum(strcmp(btn.criOutcome,obj.OutcomeOptions{4}))),'FontSize',8);
                
                % sliding performance
                [x1,y1] = calMovAVG(btn.TimeElapsed,btn.Outcome,...
                    'winRatio',6,'stepRatio',3,'tarStr',obj.OutcomeOptions{1});
                [x2,y2] = calMovAVG(btn.TimeElapsed,btn.criOutcome,...
                    'winRatio',6,'stepRatio',3,'tarStr',obj.OutcomeOptions{1});
                ha2 = axes;
                set(ha2, 'units', 'centimeters', 'position', [1.5 1, plotsize1],...
                    'nextplot', 'add', 'ylim', [0 100], 'xlim', [1 4200],...
                    'yscale', 'linear','tickdir','out');
                xlabel('Time in session (sec)')
                ylabel('Performance (%)')
            
                mperf1 = 100.*sum(strcmp(btn.Outcome,obj.OutcomeOptions{1}))./length(btn.Outcome);
                line([0 4200],[mperf1,mperf1],...
                    'linestyle','--','color',cGreen,'linewidth',1.5);
                plot(x1, y1, 'o', 'linestyle', '-', 'color', cGreen, ...
                    'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', cGreen,...
                    'markeredgecolor', 'w');
                text(4200,mperf1,sprintf('mean %.0f%%',mperf1),...
                    'FontSize',8,'color',cGreen.*0.8);
                
                mperf2 = 100.*sum(strcmp(btn.criOutcome,obj.OutcomeOptions{1}))./length(btn.criOutcome);
                line([0 4200],[mperf2,mperf2],...
                    'linestyle','--','color',cBlue,'linewidth',1.5);
                plot(x2, y2, 'o', 'linestyle', '-', 'color', cBlue, ...
                    'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', cBlue,...
                    'markeredgecolor', 'w');
                text(4200,mperf1-max([mperf1-mperf2,8]),sprintf('mean %.0f%%',mperf2),...
                    'FontSize',8,'color',cBlue.*0.8);
            end
        end
    end
    
end
