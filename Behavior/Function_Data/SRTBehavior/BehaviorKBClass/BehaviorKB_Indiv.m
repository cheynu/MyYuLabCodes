classdef BehaviorKB_Indiv

    % 20/June/2023, hbWang
    % Behavior class for kornblum protocol (in pure bpod box)
    % *_Indiv: Based on BehaviorKB

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
        Group       (1,1) string {mustBeTextScalar} % e.g., hM3Dq (manual or extracted by BehaviorDSRT)
        nSession    (1,1) double {mustBeNumeric}
        Sessions    (1,:) double {mustBeNumeric}
        Dates       (1,:) double {mustBeNumeric}
        nTrial      (1,:) double {mustBeNumeric}
        Meta        (1,:) cell   {mustBeNumeric}
        Tasks       (1,:) string {mustBeText}
        Experiments (1,:) string {mustBeText} % e.g., ["Saline", "DCZ", "Saline"]
        TableAll    (1,:) cell
        TBT               table % trial by trial
        SBS               table % session by session, every row: stat for each session * TrialType
        EBE               table % experiment by experiment, every row: stat for each Experiment * TrialType
        CBC               table % estimates of custom conditions, every row: stat for each custom conditions (e.g., early 200 trials)
        StatComparison    struct
        Options           struct
    end

    properties (Dependent, GetAccess = private)
        SaveName
    end

    properties (GetAccess = private)
        pTBT  table
        pSBS  table
        pEBE  table
        pCBC  table
        cStat struct
        Edges_HT   = 0:0.05:3         % Hold time (All trials)
        Bins_HT    = 0.025:0.05:2.975
        Edges_RT   = 0:0.05:1         % Reaction time (Cor)
        Edges_RelT = 0:0.05:2         % Release time (Cor+Late)
        SmoWin     = 8                % smoothdata('gaussian')
        ProgressTrials = 600          % all trials
        SlidingMethod = 'fixed'
        SlidingWin  = 30
        SlidingStep = 10
        CompExp = ["DCZ25", "Saline"]
        CompDate = {[], []};
    end

    properties (Constant, GetAccess = private)       
        OutcomeOptions = ["Cor", "Pre", "Late"]
        CueOptions     = ["Cue", "Uncue"]
        RTOptions      = ["Cor", "CorLate"]
        CustomOptions  = ["EarlyProgress", "LateProgress"];
    end
    
    methods
        function obj = BehaviorKB_Indiv(behavKBAll, method)
            arguments
                behavKBAll (1,:) cell
                method     string {mustBeMember(method,["Merge", "Select"])} = "Merge"
            end

            dates = cellfun(@(x)x.Date, behavKBAll, 'UniformOutput', true);
            [~, idxDate, ~] = unique(dates, "sorted");  % May/25/2023, hbWang: "stable" -> "sorted"

            dataAll = cell(1, length(idxDate));
            for i = 1:length(dataAll)
                dataAll{i} = behavKBAll{idxDate(i)};
                for j = 1:length(behavKBAll)
                    if idxDate(i) ~= j
                        dataAll{i} = dataAll{i}.merge(behavKBAll{j}, method, true);
                    end
                end
            end
            obj.DataAll = dataAll;
            obj = obj.reNumberSessions("Tasks");
            disp("Checking subject names ..."); mustBeTextScalar(obj.Subject);
            disp("Checking group names ...");   mustBeTextScalar(obj.Group);
            disp("Calculating statistics data ..."); obj = obj.stat();
            disp(obj.Subject+" - kornblum individual subject class has been built");
        end

        function value = get.Subject(obj)
            value = unique(string(cellfun(@(x)x.Subject,obj.DataAll,'UniformOutput',false)));
        end

        function obj = set.Subject(obj,value)
            for i = 1:obj.nSession; obj.DataAll{i}.Subject = char(value); end
        end

        function value = get.Group(obj)
            value = unique(string(cellfun(@(x)x.Group,obj.DataAll,'UniformOutput',false)));
        end

        function obj = set.Group(obj, value)
            for i = 1:obj.nSession; obj.DataAll{i}.Group = value; end
        end
        
        function value = get.Meta(obj)
            value = cellfun(@(x)x.Meta,obj.DataAll,'UniformOutput',false);
        end

        function obj = set.Meta(obj, value)
            for i = 1:obj.nSession; obj.DataAll{i}.Meta = value{i}; end
        end

        function value = get.nSession(obj)
            value = length(obj.DataAll);
        end

        function value = get.Sessions(obj)
            value = cellfun(@(x)x.Session,obj.DataAll,'UniformOutput',true);
        end

        function obj = set.Sessions(obj, value)
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
        
        function obj = set.Experiments(obj, value)
            for i = 1:obj.nSession; obj.DataAll{i}.Experiment = value(i); end
        end

        function value = get.nTrial(obj)
            value = cellfun(@(x)x.nTrial,obj.DataAll,'UniformOutput',true);
        end

        function value = get.TableAll(obj)
            value = cell(1, obj.nSession);
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

        function obj = set.Options(obj, value)
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

        function obj = stat(obj)
            obj.pTBT = tbt(obj);
            obj.pSBS = sbs(obj);
            obj.pEBE = ebe(obj);
            obj.pCBC = cbc(obj);
        end

        function value = tbt(obj)
            value = table;
            for i = 1:obj.nSession
                T = obj.TableAll{i};
                value = [value; T]; %#ok<*AGROW> 
            end
        end

        function value = sbs(obj)
            value = table;
            for i = 1:obj.nSession
                iobj = obj.DataAll{i};
                itable = obj.TableAll{i};
                stat = calIndivStatKB(itable,'ifDistr',true,'cuelist',obj.CueOptions,...
                    'edges_HT',obj.Edges_HT,'bins_HT',obj.Bins_HT,'edges_RT',obj.Edges_RT,...
                    'edges_RelT',obj.Edges_RelT,'smoWin',obj.SmoWin);
                % Add progress performance for each session by "fixed" slidingMethod, 
                % each session has different length, we just append them as struct.
                switch lower(obj.SlidingMethod)
                    case 'fixed'
                        iprgPerf = iobj.calProgress("Outcome", "tarStr", obj.OutcomeOptions,...
                            'slidingMethod',obj.SlidingMethod,'winSize',obj.SlidingWin,'stepSize',obj.SlidingStep);
                        iprgRT = iobj.calProgress("RT", "tarStr", obj.RTOptions,...
                            'slidingMethod',obj.SlidingMethod,'winSize',obj.SlidingWin,'stepSize',obj.SlidingStep);
                    case 'ratio'
                        iprgPerf = iobj.calProgress("Outcome", "tarStr", obj.OutcomeOptions,...
                            'slidingMethod',obj.SlidingMethod,'winRatio',obj.SlidingWin,'stepRatio',obj.SlidingStep);
                        iprgRT = iobj.calProgress("RT", "tarStr", obj.RTOptions,...
                            'slidingMethod',obj.SlidingMethod,'winRatio',obj.SlidingWin,'stepRatio',obj.SlidingStep);
                    otherwise
                        error('Invalid parameters of SlidingMethod');
                end
                
                stat = addvars(stat, obj.SlidingWin, obj.SlidingStep, {iprgPerf.x.Cor}, {iprgPerf.y}, {iprgRT.y},...
                    'NewvariableNames', {'progressWin', 'progressStep', 'progressTime', 'progressPerf', 'progressRT'});
                
                % Add Cue / Uncue progress data, and trim to same length(lim)
                for j = 1:length(obj.CueOptions)
                    jCue = obj.CueOptions(j);
                    lim = min([height(iprgPerf.xCue(:,1)), height(iprgPerf.xUncue(:,1))]);
                    iprg.("Time_"+jCue) = iprgPerf.("x"+jCue).Cor(1:lim);
                    iprg.("Perf_"+jCue) = iprgPerf.("y"+jCue)(1:lim,:);
                    iprg.("RT_"+jCue)   = iprgRT.("y"+jCue)(1:lim,:);

                    stat = addvars(stat, {iprg.("Time_"+jCue)}, {iprg.("Perf_"+jCue)}, {iprg.("RT_"+jCue)}, ...
                        'NewVariableNames', cellstr(["progressTime_"+jCue,"progressPerf_"+jCue, "progressRT_"+jCue]));
                end
                value = [value; stat];
            end
        end
        
        function value = ebe(obj)
            value = table;
            uniExp = unique(obj.Experiments);
            for i = 1:length(uniExp)
                data = obj.TBT(obj.TBT.Experiment == uniExp(i),:);
                stat = calIndivStatKB(data,true,'ifDistr',true,'cuelist',obj.CueOptions,...
                    'edges_HT',obj.Edges_HT,'bins_HT',obj.Bins_HT,'edges_RT',obj.Edges_RT, ...
                    'edges_RelT',obj.Edges_RelT,'smoWin',obj.SmoWin);
                value = [value; stat];
            end
        end

        function value = cbc(obj)
            % Existing conditions:
                % Early ProgressTrials (e.g., first 600) of TBT
                % Late ProgressTrials  (e.g., last 600) of TBT
            value = table;
            progTrials = min(obj.ProgressTrials,size(obj.TBT,1));
            % Early ProgressTrials
            data = obj.TBT(1:progTrials,:);
            stat = calIndivStatKB(data,true,'ifDistr',true,'cuelist',obj.CueOptions,...
                    'edges_HT',obj.Edges_HT,'bins_HT',obj.Bins_HT,'edges_RT',obj.Edges_RT, ...
                    'edges_RelT',obj.Edges_RelT,'smoWin',obj.SmoWin);
            value = [value;stat];
            % Late ProgressTrials
            data = obj.TBT(end-progTrials+1:end,:);
            stat = calIndivStatKB(data,true,'ifDistr',true,'cuelist',obj.CueOptions,...
                    'edges_HT',obj.Edges_HT,'bins_HT',obj.Bins_HT,'edges_RT',obj.Edges_RT, ...
                    'edges_RelT',obj.Edges_RelT,'smoWin',obj.SmoWin);
            value = [value;stat];

            value = addvars(value,["EarlyProgress";"LateProgress"],...
                'NewVariableNames','Customization','Before','Subject');
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
            
            newobj = BehaviorKB_Indiv(obj.DataAll(union(idxExp1, idxExp2))); % Only use the selected sessions
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

        function obj = reNumberSessions(obj, indicator, switchStr)
            arguments
                obj
                indicator string {mustBeMember(indicator, ["Tasks", "Experiment"])}
                switchStr string = []
            end

            allIndicators = obj.(indicator);
            newSess = zeros(size(allIndicators));
            kk = 1;
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
            obj.Sessions = newSess;
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
                options.plotType  string {mustBeMember(options.plotType,["Learning", "Comparison"])} = "Learning"
                options.shadedExp string  = "DCZ"
                options.htLim     double  = [0 3]
                options.perfLim   double  = [0 1]
                options.save      logical = true
                options.saveName  string  = obj.SaveName
                options.savePath  string  = fullfile(pwd, "Fig")
                % PrgComp: for comparison figure, plot day by day progress
                options.PrgComp   logical = false  
            end
            
            %% Default settings
            shadedExp = options.shadedExp;
            plotProgressCompare = options.PrgComp;

            % Parameters
            fontSize = struct("Axes", 7, "Label", 9, "Title", 10, "Info", 12);
            tickLen = [0.0200 0.0250]; tLim = [0 3000];           

            yLim.HT = options.htLim;
            yTick.HT = yLim.HT(1):0.5:yLim.HT(2);
            yTickLabel.HT = num2str(yTick.HT' * 1000);

            yLim.Perf = options.perfLim;
            yTick.Perf = yLim.Perf(1):0.5:yLim.Perf(2);
            yTickLabel.Perf = num2str(yTick.Perf' * 100);
            yTick.Perf2 = yLim.Perf(1):0.2:yLim.Perf(2);
            yTickLabel.Perf2 = num2str(yTick.Perf2' * 100);

            xLim.HT = options.htLim;
            xTick.HT = xLim.HT(1):1:xLim.HT(2);
            xTickLabel.HT = num2str(xTick.HT' * 1000);

            xLim.Date = [0.5 obj.nSession+0.5];
            xTick.Date = 1:obj.nSession;
            xTickLabel.Date = num2str(obj.Dates');

            cTab10 = tab10(10); cAccent = Accent(8); cDarkGrey = cAccent(end,:);
            cBlue = cTab10(1,:); cOrange = cTab10(2,:); cGreen = cTab10(3,:);
            cRed  = cTab10(4,:); cPurple = cTab10(5,:); cGrey  = cTab10(8,:);
            
            c = struct("Perf", [cGreen;cRed;cGrey], "Cue", [[0 0 0];cPurple], ...
                       "Exp", [cOrange;cDarkGrey], "CustomLine", [cBlue;cRed], ...
                       "Scatter", ["flat", "none"], "Shade", cOrange, "GapLine", cGrey, "FPLine", 'k', ... % Raster plot
                       "Whisker", cRed, "Violin", cGrey, "ViolinEdge", cDarkGrey, "ViolinBox", cBlue, ...
                       "htColorMap", customcolormap([0 1], [cRed;cBlue]));
            alpha = struct("Cue", 0.7, "Uncue", 1, "Shade", 0.1, "Violin", 0.2);
            psize = struct("Marker", [5 7], "Scatter", [20 20], "ScatterLine", [1 1.3], ...
                           "CustomLine", [1.5 1.5], "GapLine", 0.5, "FPLine", 1, ...
                           "CueLine", [1.5 2], "PerfLine", [1.5 1.5 1.5], ...
                           "CueLineStyle", ["-", ":"], ...
                           "Arrow", [2 3 35]);  % arrow parameters [linewidth length tipangle]

            switch options.plotType
                case "Learning"
                    Fig = plotLearning(obj);
                case "Comparison"
                    Fig = plotComparison(obj);
            end

            %% Learning plot: session by session data
            function Fig = plotLearning(obj)

                tbt = obj.TBT; sbs = obj.SBS; cbc = obj.CBC;

                idxShade = obj.Experiments == shadedExp;
                fillList = zeros(obj.nSession, 4); FPLineListX = zeros(obj.nSession, 2);
                for i = 1:obj.nSession
                    fillList(i,:)    = [i-0.5 i+0.5 i+0.5 i-0.5];
                    FPLineListX(i,:) = [i-0.5 i+0.5];
                end
                fillList = fillList.*(idxShade)';
                FPLineListY = cellfun(@(x) x.FP, obj.Meta, "UniformOutput", true);
                GapLineList = [xTick.Date(1:end-1);xTick.Date(1:end-1)]+0.5;

                xstart = 1.5; ystart = 1.5; xgap = 0.8; ygap = 0.8;

                axeSize1 = [8 4];                                    % cross sessions HT / progress
                axeSize2 = [5 axeSize1(2)];                          % cross sessions performance
                axeSize3 = [(axeSize2(1)-xgap/2)/2 axeSize1(2)*0.7]; % for early-late PDF comparison
                cbarSize = [0.5 axeSize1(2)];                        % for heatmap colorbar
                
                xmap = [xstart, ...
                        xstart + xgap*3 + axeSize2(1), ...
                        xstart + xgap*4 + axeSize2(1) + axeSize1(1), ...
                        xstart + xgap*5 + axeSize2(1) + axeSize1(1)*2, ...
                        xstart + xgap*6 + axeSize2(1) + axeSize1(1)*2 + cbarSize(1)];

                axeSizeInfo = [xmap(end-2)-xmap(1) 1.1];

                ymap = [ystart, ...
                        ystart + ygap*1 + axeSize1(2), ...
                        ystart + ygap*2 + axeSize1(2)*2, ...
                        ystart + ygap*3 + axeSize1(2)*3, ...
                        ystart + ygap*4 + axeSize1(2)*4, ...
                        ystart + ygap*5 + axeSize1(2)*4 + axeSizeInfo(2)];

                Fig = figure(1); clf(Fig, "reset");
                set(Fig, "Unit", "centimeters", "PaperPositionMode", "auto", ...
                    "Position", [2 2 xmap(end) ymap(end)], "Color", "w");

                %% ha11 & ha11b, cue / uncue early-late comp
                maxCustompdf = max([obj.CBC.HTpdf_KBCue obj.CBC.HTpdf_KBUncue], [], 'all');

                ha11 = axes;
                set(ha11, "Units", "centimeters", "Position", [xmap(1) ymap(1) axeSize3],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                    "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, ...
                    "YLim", [0 maxCustompdf*1.1], ...
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                xlabel("HT (ms)", "FontSize", fontSize.Label, "FontName", "Arial");
                ylabel("PDF (1/sec)", "FontSize", fontSize.Label, "FontName", "Arial");
                title("Cue", "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");

                ha11b = axes;
                set(ha11b, "Units", "centimeters", "Position", [xmap(1)+xgap/2+axeSize3(1) ymap(1) axeSize3],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                    "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, ...
                    "YLim", [0 maxCustompdf*1.1], ...
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                xlabel("HT (ms)", "FontSize", fontSize.Label, "FontName", "Arial");
                title("Uncue", "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");
                ha11b.YAxis.Visible = "off";
                
                axesList_PDF = [ha11; ha11b];
                for i = 1:length(obj.CueOptions)
                    Fig.CurrentAxes = axesList_PDF(i);
                    for j = 1:length(obj.CustomOptions)
                        idx = cbc.Customization == obj.CustomOptions(j);
                        linePDF.("l"+num2str(j)) = plot(obj.Bins_HT, cbc(idx,:).("HTpdf_KB"+obj.CueOptions(i)), ...
                            "LineStyle", "-", "LineWidth", psize.CustomLine(j), "Color", c.CustomLine(j,:));
                    end
                    line([FPLineListY(1) FPLineListY(1)], [0 maxCustompdf*1.1], ...
                        "Color", c.FPLine, "LineStyle", "--", "LineWidth", psize.FPLine);
%                     view(90,-90);
                end


                %% ha21, HT IQR
                ha21 = axes;
                set(ha21, "Units", "centimeters", "Position", [xmap(1) ymap(2) axeSize2],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", xTickLabel.Date, ...
                    "YTick", yTick.HT, "YTickLabel", yTickLabel.HT, ...
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                xlabel("Sessions (dates)", "FontSize", fontSize.Label, "FontName", "Arial");
                ylabel("HT IQR (ms)", "FontSize", fontSize.Label, "FontName", "Arial");
                if ha21.YLim(2) < yLim.HT(2)/2; set(ha21, "YLim", [0 yLim.HT(2)/2]); end

                for i = 1:length(obj.CueOptions)
                    if i == 1; mfColor = c.Cue(i,:); else; mfColor = "none"; end
                    lineIQR.("l"+num2str(i)) = plot(1:obj.nSession, obj.SBS.RelT_IQR_KB(:,i), ...
                        'o', "LineStyle", "-", "LineWidth", psize.CueLine(i), "Color", c.Cue(i,:), ...
                        "MarkerSize", psize.Marker(i), "MarkerFaceColor", mfColor, "MarkerEdgeColor", c.Cue(i,:));
                end
                
                %% ha41 & ha31, Cue / uncue performance
                ha31 = axes;
                set(ha31, "Units", "centimeters", "Position", [xmap(1) ymap(3) axeSize2(1) axeSize2(2)*0.9],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YLim", yLim.Perf, "YTick", yTick.Perf, "YTickLabel", yTickLabel.Perf, ...
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                ylabel("Performance (%)", "FontSize", fontSize.Label, "FontName", "Arial");
                title("Uncue", "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");
                
                ha41 = axes;
                set(ha41, "Units", "centimeters", "Position", [xmap(1) ymap(4) axeSize2],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YLim", yLim.Perf, "YTick", yTick.Perf, "YTickLabel", yTickLabel.Perf, ...
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                ylabel("Performance (%)", "FontSize", fontSize.Label, "FontName", "Arial");
                title("Cue", "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");

                axesList_Perf = [ha41; ha31];
                for i = 1:length(obj.CueOptions)
                    Fig.CurrentAxes = axesList_Perf(i);
                    iCue = obj.CueOptions(i);
                    for j = 1:length(obj.OutcomeOptions)
                        jPerf = obj.OutcomeOptions(j);
                        if iCue == "Cue"; mfColor = c.Perf(j,:); else; mfColor = "none"; end
                        linePerf.("l"+num2str(i)+num2str(j)) = plot(sbs.(jPerf+"_KB")(:,i), 'o', "Color", c.Perf(j,:), ...
                            "LineStyle", "-", "LineWidth", psize.PerfLine(j), ...
                            "MarkerFaceColor", mfColor, "MarkerSize", psize.Marker(i));
                    end
                end

                %% ha12 & ha13, cue / uncue holdtime heatmap
                maxHTpdf = max([obj.SBS.HTpdf_KBCue obj.SBS.HTpdf_KBUncue], [], 'all');

                ha12 = axes;
                set(ha12, "Units", "centimeters", "Position", [xmap(2) ymap(1) axeSize1],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", xTickLabel.Date, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", yTickLabel.HT, ...
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                xlabel("Sessions (dates)", "FontSize", fontSize.Label, "FontName", "Arial");
                ylabel("Hold duration (ms)", "FontSize", fontSize.Label, "FontName", "Arial");
                imagesc(ha12, 1:obj.nSession, obj.Bins_HT, obj.SBS.HTpdf_KBCue', [0 maxHTpdf*1.1]);

                ha13 = axes;
                set(ha13, "Units", "centimeters", "Position", [xmap(3) ymap(1) axeSize1],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", xTickLabel.Date, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", {}, ...
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                ha13.YAxis.Visible = "off";
                xlabel("Sessions (dates)", "FontSize", fontSize.Label, "FontName", "Arial");
                imagesc(ha13, 1:obj.nSession, obj.Bins_HT, obj.SBS.HTpdf_KBUncue', [0 maxHTpdf*1.1]);
%                 colormap(c.htColorMap); too ugly
                cbar = colorbar(ha13, "Units", "centimeters", "Position", [xmap(4)-xgap/2 ymap(1) cbarSize], ...
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                set(cbar.Label, "String", "PDF (1/sec)", "Units", "centimeters", ...
                    "FontSize", fontSize.Label, "FontName", "Arial");  %"Position", cbar.Label.Position+[-2.7 0.5 0]
                axesList_Heatmap = [ha12; ha13];
                if any(idxShade)
                    for i = 1:length(obj.CueOptions)
                        Fig.CurrentAxes = axesList_Heatmap(i);
                        arrow([find(idxShade)' zeros(sum(idxShade),1)], ...
                            [find(idxShade)' 0.2*ones(sum(idxShade), 1)], 'Color', c.Shade, ...
                            'LineWidth', psize.Arrow(1), 'Length', psize.Arrow(2), 'TipAngle', psize.Arrow(3));
                    end
                end
                %% ha22 & ha23, cue / uncue holdtime violin plot
                ha22 = axes;
                set(ha22, "Units", "centimeters", "Position", [xmap(2) ymap(2) axeSize1],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", yTickLabel.HT, ...
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                ylabel("Hold duration (ms)", "FontSize", fontSize.Label, "FontName", "Arial");

                ha23 = axes;
                set(ha23, "Units", "centimeters", "Position", [xmap(3) ymap(2) axeSize1],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", {}, ...
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                ha23.YAxis.Visible = "off";

                axesList_HTviolin = [ha22; ha23];
                for i = 1:length(obj.CueOptions)
                    Fig.CurrentAxes = axesList_HTviolin(i);
                    idx = tbt.Cue == obj.CueOptions(i);
                    violinCue = violinplot(tbt.HT(idx,:), tbt.Date(idx,:), 'ViolinColor', c.Violin, ...
                        'Width', 0.4, 'ViolinAlpha', alpha.Violin, 'ShowWhiskers', false, ...
                        'BoxColor', c.Whisker, 'BoxWidth', 0.01, 'EdgeColor', c.ViolinEdge);
                    for k = 1:obj.nSession
                        violinCue(k).MedianPlot.LineWidth = 1.5;
                        violinCue(k).MedianPlot.SizeData  = 30;
                        violinCue(k).ScatterPlot.MarkerFaceColor = 'k';
                        violinCue(k).ScatterPlot.SizeData = 15;
%                         violinCue(k).ViolinPlot.FaceColor = c.Violin;
                    end
                    set(gca, "Box", "off", "XTickLabel", {});
                    line(FPLineListX, FPLineListY, ...
                        "Color", c.FPLine, "LineStyle", "--", "LineWidth", psize.FPLine);
                end

                %% ha32 & ha33, cue / uncue holdtime raster
                ha32 = axes;
                set(ha32, "Units", "centimeters", "Position", [xmap(2) ymap(3) axeSize1], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen, ...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", yTickLabel.HT, ...
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                ylabel("Hold duration (ms)", "FontSize", fontSize.Label, "FontName", "Arial");

                ha33 = axes;
                set(ha33, "Units", "centimeters", "Position", [xmap(3) ymap(3) axeSize1], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen, ...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", {}, ...
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                ha33.YAxis.Visible = "off";

                axesList_HT = [ha32; ha33];
                for i = 1:length(obj.CueOptions)
                    Fig.CurrentAxes = axesList_HT(i);
                    iCue = obj.CueOptions(i);
                    itbt = tbt(tbt.Cue == iCue & ...
                        tbt.TimeElapsed<tLim(2) & tbt.TimeElapsed>tLim(1), :);
                    iTErescaled = rescale(itbt.TimeElapsed, 0.05, 0.95);
                    itime = iTErescaled + itbt.Session - 0.5;
%                     itime = itbt.TimeElapsed + (itbt.Session-1).*(tLim(2)+tgap);
                    for j = 1:length(obj.OutcomeOptions)
                        idxOutcome = itbt.Outcome == obj.OutcomeOptions(j);
                        scatter(itime(idxOutcome), itbt.HT(idxOutcome,:), psize.Scatter(i), ...
                            c.Perf(j,:), "LineWidth", psize.ScatterLine(i), ...
                            "MarkerFaceColor", c.Scatter(i), "MarkerFaceAlpha", alpha.(iCue));
%                         scatter(axesList_HT(i), itime(idxOutcome), itbt.HT(idxOutcome,:), psize.Scatter(i), ...
%                             c.Perf(j,:), "MarkerFaceColor", c.Scatter(i), "MarkerFaceAlpha", alpha.(iCue));
                    end
                    line(FPLineListX, FPLineListY, ...
                        "Color", c.FPLine, "LineStyle", "--", "LineWidth", psize.FPLine);
                end

                %% ha42 & ha43, cue / uncue progress performance plot
                ha42 = axes;
                set(ha42, "Units", "centimeters", "Position", [xmap(2) ymap(4) axeSize1],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YLim", yLim.Perf, "YTick", yTick.Perf, "YTickLabel", yTickLabel.Perf, ...
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                ylabel("Sliding performance (%)", "FontSize", fontSize.Label, "FontName", "Arial");
                title("Cue", "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");

                ha43 = axes;
                set(ha43, "Units", "centimeters", "Position", [xmap(3) ymap(4) axeSize1],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                    "XLim", xLim.Date, "XTick", xTick.Date, "XTickLabel", {}, ...
                    "YLim", yLim.Perf, "YTick", yTick.Perf, "YTickLabel", {}, ...
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                title("Uncue", "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");
                ha43.YAxis.Visible = "off";

                axesList_Prg = [ha42; ha43];
                for i = 1:length(obj.CueOptions)
                    Fig.CurrentAxes = axesList_Prg(i);
                    iCue = obj.CueOptions(i);
                    for j = 1:obj.nSession
                        ijprg = sbs(j,:).("progressPerf_"+iCue);
                        for k = 1:length(obj.OutcomeOptions)
                            kPerf = obj.OutcomeOptions(k);
                            plot(j-0.5+rescale(1:size(ijprg{1,1}, 1), 0.1, 0.9), ijprg{1,1}.(kPerf), ...
                                "Color", c.Perf(k,:), "LineStyle", "-", "LineWidth", psize.PerfLine(k));
                        end
                    end
                end

                %% Add gaplines and fill shaded backgrounds
                axesList_All = [ha21; ha22; ha23; ha31; ha32; ha33; ha41; ha42; ha43];
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
                legendIQR = legend(ha21, [lineIQR.l1 lineIQR.l2], obj.CueOptions, "Location", "northeast",...
                    "NumColumns", 1, "FontSize", fontSize.Label, "FontName", "Arial", "Box", "off");
                legendIQR.ItemTokenSize = [12,15];
                legendIQR.Position = legendIQR.Position + [0.025 0.01 0 0];

                legendPDF = legend(ha11b, [linePDF.l1 linePDF.l2], ["Early", "Late"], "Location", "northeast",...
                    "NumColumns", 1, "FontSize", fontSize.Label, "FontName", "Arial", "Box", "off");
                legendPDF.ItemTokenSize = [12,15];
                legendPDF.Position = legendPDF.Position + [0.025 0.01 0 0];
                
                ha41_copy = axes("Position", get(ha41, "Position"), "Visible", "off");
                legendPerf = legend(ha41_copy, [linePerf.l11 linePerf.l12 linePerf.l13], obj.OutcomeOptions, ...
                    "FontSize", fontSize.Label, "FontName", "Arial", "NumColumns", 3, "Box", "off");
                legendPerf.ItemTokenSize = [12,15];
                set(legendPerf, "Units", "centimeters", 'Position', [xmap(3) ymap(5) axeSize1(1) 1]);

                % This point is to add legend for "cue"
                linePerf.l00 = plot(ha41, sbs.Cor_KB(1,1), 'o', "Color", c.Perf(1,:), ...
                    "MarkerFaceColor", c.Perf(1,:), "MarkerSize", psize.Marker(1));
                legendCue = legend(ha41, [linePerf.l00 linePerf.l21], obj.CueOptions, ...
                    "FontSize", fontSize.Label, "FontName", "Arial", "NumColumns", 3, "Box", "off");
                legendCue.ItemTokenSize = [12,15];
                set(legendCue, "Units", "centimeters", 'Position', [xmap(3) ymap(5)+ygap axeSize1(1) 1]);

                linePerf.l00 = plot(ha41, sbs.Cor_KB(1,1), 'o', "Color", c.Perf(1,:), ...
                    "MarkerFaceColor", c.Perf(1,:), "MarkerSize", psize.Marker(1));
                if any(obj.Experiments == shadedExp)
                    ha42_copy = axes("Position", get(ha42, "Position"), "Visible", "off");
                    leFill = fill(ha42_copy, fillList(idxShade(1),:), [yLim.Perf(1) yLim.Perf(1) yLim.Perf(2) yLim.Perf(2)], ...
                        c.Shade, "FaceAlpha", alpha.Shade, "EdgeColor", "none");
                    legendCue = legend(ha41, [linePerf.l00 linePerf.l21 leFill], [obj.CueOptions shadedExp], ...
                        "FontSize", fontSize.Label, "FontName", "Arial", "NumColumns", 3, "Box", "off");
                else
                    legendCue = legend(ha41, [linePerf.l00 linePerf.l21], obj.CueOptions, ...
                        "FontSize", fontSize.Label, "FontName", "Arial", "NumColumns", 2, "Box", "off");
                end
                legendCue.ItemTokenSize = [12,15];
                set(legendCue, "Units", "centimeters", 'Position', [xmap(3) ymap(5)+ygap axeSize1(1) 1]);

                %% Add info
                uicontrol(Fig, "Style", "text", "Units", "centimeters", "BackgroundColor", "w", ...
                    "Position", [xmap(1) ymap(5) axeSizeInfo],...
                    "String", obj.Subject+"  |  "+unique(obj.Tasks)+"  |  "+ ...
                    num2str(obj.Dates(1))+" ~ "+num2str(obj.Dates(end)), ...
                    "FontSize", fontSize.Info, "FontWeight", "bold", "FontName", "Arial");
            end
        
            function Fig = plotComparison(obj)
                if isempty(obj.cStat)
                    obj = obj.calStatComparison;
                end
                op = obj.StatComparison.Options;
                tbt = obj.StatComparison.TBT;
                sbs = obj.StatComparison.SBS;
                ebe = obj.StatComparison.EBE;
                
                allFP = cellfun(@(x) x.FP, obj.Meta, "UniformOutput", true);
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
                    FPLineListY.("E"+num2str(i)) = allFP(ismember(obj.Dates, op.CompDate{i}));
                    GapLineList.("E"+num2str(i)) = [xTick.("DateE"+num2str(i))(1:end-1);
                                                    xTick.("DateE"+num2str(i))(1:end-1)]+0.5;
                end

                xstart = 1.3; ystart = 1.3; xgap = 0.6; ygap = 0.6;

                axeSize1 = [8 4];
                axeSize2 = [(axeSize1(1)+2*xgap)/2 (axeSize1(2)*2-2*ygap)/3];
                
                xmap = [xstart, ...
                        xstart + xgap*1 + axeSize1(1), ...
                        xstart + xgap*3 + axeSize1(1)*2, ...
                        xstart + xgap*4 + axeSize1(1)*2 + axeSize2(1), ...
                        xstart + xgap*5 + axeSize1(1)*2 + axeSize2(1)*2];
                xlen = axeSize1(1)*2 + axeSize2(1)*2 - xgap*6;

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
                set(Fig, "Unit", "centimeters", "PaperPositionMode", "auto", ...
                    "Position", [2 2 xmap(end) ymap(end)], "Color", "w");
                
                 
                %% Patterns under two experiment conditions
                idxE1 = ebe.Experiment == op.CompExp(1);
                idxE2 = ebe.Experiment == op.CompExp(2);

                ha51 = axes;
                set(ha51, "Units", "centimeters", "Position", [xmap2(1) ymap(5) axeSize4],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                    "XLim", yLim.Perf, "XTick", yTick.Perf, "XTickLabel", yTickLabel.Perf, ...
                    "YLim", yLim.Perf, "YTick", yTick.Perf, "YTickLabel", yTickLabel.Perf,...
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                xlabel(op.CompExp(1), "FontSize", fontSize.Label, "FontName", "Arial");
                ylabel(op.CompExp(2), "FontSize", fontSize.Label, "FontName", "Arial");
                title("Performance", "FontSize", fontSize.Label, "FontName", "Arial");
                line(yLim.Perf, yLim.Perf, "Color", "k", "LineStyle", "-.", "LineWidth", 1);
              
                for i = 1:length(obj.CueOptions)
                    iCue = obj.CueOptions(i);
                    for j = 1:length(obj.OutcomeOptions)
                        if iCue == "Cue"; mkfColor = c.Perf(j,:); else; mkfColor = "none"; end
                        jOut = obj.OutcomeOptions(j);
                        linePerf.("l"+iCue+jOut) = plot(ebe.(jOut+"_KB")(idxE1,i), ebe.(jOut+"_KB")(idxE2,i), "o", ...
                            "LineWidth", 1.3, "MarkerSize", 6,...
                            "MarkerFaceColor", mkfColor, "MarkerEdgeColor", c.Perf(j,:));
                        if i == 1
                            plot(ebe.(jOut)(idxE1), ebe.(jOut)(idxE2), "o", "LineWidth", 1.3, ...
                                "MarkerSize", 6, "MarkerFaceColor", c.Perf(j,:), "MarkerEdgeColor", 'k');
                        end
                    end
                end

                ha52 = axes;
                set(ha52, "Units", "centimeters", "Position", [xmap2(2) ymap(5) axeSize4],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                    "XLim", xLim.HT*2/3, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, ...
                    "YLim", yLim.HT*2/3, "YTick", yTick.HT, "YTickLabel", yTickLabel.HT, ...
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                xlabel(op.CompExp(1), "FontSize", fontSize.Label, "FontName", "Arial");
                title("HT", "FontSize", fontSize.Label, "FontName", "Arial");
                line(xLim.HT, yLim.HT, "Color", "k", "LineStyle", "-.", "LineWidth", 1);

                lineHT.l1 = plot(ebe.HT_KB(idxE1,1), ebe.HT_KB(idxE2,1), "o", "MarkerSize", 6,...
                    "MarkerFaceColor", c.Cue(1,:), "MarkerEdgeColor", c.Cue(1,:));
                lineHT.l2 = plot(ebe.HT_KB(idxE1,2), ebe.HT_KB(idxE2,2), "o", "LineWidth", 1.3, "MarkerSize", 6,...
                    "MarkerFaceColor", "none", "MarkerEdgeColor", c.Cue(2,:));
                lineHT.l3 = plot(ebe.HT(idxE1), ebe.HT(idxE2), "o", "LineWidth", 1.3, "MarkerSize", 6, ...
                    "MarkerFaceColor", c.Cue(2,:), "MarkerEdgeColor", c.Cue(1,:));

                ha53 = axes;
                set(ha53, "Units", "centimeters", "Position", [xmap2(3) ymap(5) axeSize4], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen, ...
                    "XLim", xLim.HT/2, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, ...
                    "YLim", yLim.HT/2, "YTick", yTick.HT, "YTickLabel", yTickLabel.HT, ...
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                xlabel(op.CompExp(1), "FontSize", fontSize.Label, "FontName", "Arial");
                title("HT IQR", "FontSize", fontSize.Label, "FontName", "Arial");
                line(xLim.HT, yLim.HT, "Color", "k", "LineStyle", "-.", "LineWidth", 1);

                plot(ebe.HT_IQR_KB(idxE1,1), ebe.HT_IQR_KB(idxE2,1), "o", "MarkerSize", 6,...
                    "MarkerFaceColor", c.Cue(1,:), "MarkerEdgeColor", c.Cue(1,:));
                plot(ebe.HT_IQR_KB(idxE1,2), ebe.HT_IQR_KB(idxE2,2), "o", "LineWidth", 1.3, "MarkerSize", 6,...
                    "MarkerFaceColor", "none", "MarkerEdgeColor", c.Cue(2,:));
                plot(ebe.HT_IQR(idxE1), ebe.HT_IQR(idxE2), "o", "LineWidth", 1.3, "MarkerSize", 6, ...
                    "MarkerFaceColor", c.Cue(2,:), "MarkerEdgeColor", c.Cue(1,:));

                ha54 = axes;
                set(ha54, "Units", "centimeters", "Position", [xmap2(4) ymap(5) axeSize3], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen, ...
                    "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", yTickLabel.HT, ...
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                xlabel("   Cue              Uncue", "FontSize", fontSize.Label, "FontName", "Arial")
                ylabel("Holdtime (ms)", "FontSize", fontSize.Label, "FontName", "Arial");
                cnt = 1; HTviolin = []; cats = [];
                for i = 1:length(obj.CueOptions)
                    for j = 1:length(op.CompExp)
                        idx = tbt.Cue==obj.CueOptions(i) & tbt.Experiment==op.CompExp(j);
                        HTviolin = [HTviolin; tbt(idx,:).HT];
                        cats = [cats; repmat(cnt,sum(idx),1)];
                        cnt = cnt + 1;
                    end
                end
                violinCue = violinplot(HTviolin, cats, ...
                    'Width', 0.4, 'ViolinAlpha', alpha.Violin, 'ShowWhiskers', false, ...
                    'BoxColor', c.Whisker, 'BoxWidth', 0.01, 'EdgeColor', c.ViolinEdge);
                for iv = 1:length(violinCue)
                    if rem(iv, 2)~=0
                        violinCue(iv).ScatterPlot.MarkerFaceColor = c.Exp(1,:);
                    else
                        violinCue(iv).ScatterPlot.MarkerFaceColor = c.Exp(2,:);
                    end
                    violinCue(iv).EdgeColor = c.Violin;
                    violinCue(iv).ScatterPlot.MarkerFaceAlpha = 0.35;
                    violinCue(iv).ScatterPlot.SizeData = 10;
                    violinCue(iv).ViolinPlot.LineWidth = 1.5;
                    violinCue(iv).ViolinPlot.FaceColor = c.Violin;
                end
                set(ha54, "Box", "off", "XLim", [0.5 4.5], "XTick", 1:4, ...
                    "XTickLabel", [op.CompExp op.CompExp]);
                line([0.5 2.5; 2.5 4.5], [FPLineListY.E1(1);FPLineListY.E2(1)], ...
                    "Color", c.FPLine, "LineStyle", "--", "LineWidth", psize.FPLine);
                
                ha55 = axes;
                set(ha55, "Units", "centimeters", "Position", [xmap2(5) ymap(5) axeSize3], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen, ...
                    "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, ...
                    "YLim", [0 1], ...
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                xlabel("Holdtime (ms)", "FontSize", fontSize.Label, "FontName", "Arial")
                ylabel("CDF", "FontSize", fontSize.Label, "FontName", "Arial");
                for i = 1:length(obj.CueOptions)
                    for j = 1:length(op.CompExp)
                        idx = ebe.Experiment == op.CompExp(j);
                        plot(obj.Bins_HT, ebe(idx,:).("HTcdf_KB"+obj.CueOptions(i)), ...
                            "LineStyle", psize.CueLineStyle(i), "LineWidth", psize.CueLine(i), "Color", c.Exp(j,:));
                    end
                end
                curYLim = get(gca, "YLim");
                line([FPLineListY.E1(1) FPLineListY.E1(1)], curYLim, ...
                    "Color", c.FPLine, "LineStyle", "--", "LineWidth", psize.FPLine);

                hb5 = axes;
                set(hb5, "Units", "centimeters", "Position", [xmap2(6) ymap(5) axeSize3], ...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen, ...
                    "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, ...
                    "FontSize", fontSize.Axes, "FontName", "Arial");
                xlabel("Holdtime (ms)", "FontSize", fontSize.Label, "FontName", "Arial")
                ylabel("PDF (1/s)", "FontSize", fontSize.Label, "FontName", "Arial");
                for i = 1:length(obj.CueOptions)
                    for j = 1:length(op.CompExp)
                        idx = ebe.Experiment == op.CompExp(j);
                        linePDF.("l"+num2str(i)+num2str(j)) = plot(obj.Bins_HT, ebe(idx,:).("HTpdf_KB"+obj.CueOptions(i)), ...
                            "LineStyle", psize.CueLineStyle(i), "LineWidth", psize.CueLine(i), "Color", c.Exp(j,:));
                    end
                end
                curYLim = get(gca, "YLim");
                line([FPLineListY.E1(1) FPLineListY.E1(1)], curYLim, ...
                    "Color", c.FPLine, "LineStyle", "--", "LineWidth", psize.FPLine);

                %% ha33, 34, 43, 44: holdtime scatter plot
                ha13 = axes("NextPlot", "add", "Units", "centimeters", ...
                    "Position", [xmap(1) ymap(1) axeSize1]);
                ha14 = axes("NextPlot", "add", "Units", "centimeters", ...
                    "Position", [xmap(2) ymap(1) axeSize1]);
                ha14.YAxis.Visible = "off";
                ha23 = axes("NextPlot", "add", "Units", "centimeters", ...
                    "Position", [xmap(1) ymap(3) axeSize1]);
                ha24 = axes("NextPlot", "add", "Units", "centimeters", ...
                    "Position", [xmap(2) ymap(3) axeSize1]);
                ha24.YAxis.Visible = "off";

                axesList_HT = [ha23 ha24; ha13 ha14];

                for i = 1:length(obj.CueOptions)
                    iCue = obj.CueOptions(i);

                    for j = 1:length(op.CompExp)
                        Fig.CurrentAxes = axesList_HT(j,i);
                        ijtbt = tbt(tbt.Cue == iCue & tbt.Experiment == op.CompExp(j) &...
                            tbt.TimeElapsed<tLim(2) & tbt.TimeElapsed>tLim(1), :);
                        [~,~,ijSession] = unique(ijtbt.Session);
                        ijTErescaled = rescale(ijtbt.TimeElapsed, 0.05, 0.95);
                        ijtime = ijTErescaled + ijSession - 0.5;
                        for k = 1:length(obj.OutcomeOptions)
                            idxOutcome = ijtbt.Outcome == obj.OutcomeOptions(k);
                            scatter(ijtime(idxOutcome), ijtbt.HT(idxOutcome,:), psize.Scatter(i), ...
                                c.Perf(k,:), "LineWidth", psize.ScatterLine(i), ...
                                "MarkerFaceColor", c.Scatter(i), "MarkerFaceAlpha", alpha.(iCue));
                        end
                        line(FPLineListX.("E"+num2str(j)), [FPLineListY.("E"+num2str(j))' FPLineListY.("E"+num2str(j))'], ...
                            "Color", c.FPLine, "LineStyle", "--", "LineWidth", psize.FPLine);
                        set(axesList_HT(j,i), "TickDir", "out", "TickLength", tickLen,...
                            "XLim", xLim.("DateE"+num2str(j)), "XTick", xTick.("DateE"+num2str(j)), ...
                            "XTickLabel", xTickLabel.("DateE"+num2str(j)), ...
                            "YLim", yLim.HT, "YTick", yTick.HT, "YTickLabel", yTickLabel.HT, ...
                            "FontSize", fontSize.Axes, "FontName", "Arial");
                        title(obj.CueOptions(i)+" | "+op.CompExp(j), ...
                            "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");
                        fill(fillList.("E"+num2str(j)), [yLim.HT(1) yLim.HT(1) yLim.HT(2) yLim.HT(2)], c.Shade, ...
                            "FaceAlpha", alpha.Shade, "EdgeColor", "none");
                        if ~isempty(GapLineList.("E"+num2str(j)))
                            line(GapLineList.("E"+num2str(j)), yLim.HT, ...
                                "Color", c.GapLine, "LineStyle", ":", "LineWidth", psize.GapLine);
                        end
                    end
                end

                xlabel(ha13, "Sessions (dates)", "FontSize", fontSize.Label, "FontName", "Arial");
                ylabel(ha13, "HT (ms)", "FontSize", fontSize.Label, "FontName", "Arial");
                xlabel(ha14, "Sessions (dates)", "FontSize", fontSize.Label, "FontName", "Arial");
                ylabel(ha23, "HT (ms)", "FontSize", fontSize.Label, "FontName", "Arial");

                if ~plotProgressCompare
                    %% ha31/32, 41/42, 51/52: mean of progress performance
                    % Late
                    ha11 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(3) ymap(1) axeSize2]);
                    ha12 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(4) ymap(1) axeSize2]);
                    ha12.YAxis.Visible = "off";
                    % Premature
                    ha21 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(3) ymap(2) axeSize2]);
                    ha21.XAxis.Visible = "off";
                    ha22 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(4) ymap(2) axeSize2]);
                    ha22.XAxis.Visible = "off"; ha22.YAxis.Visible = "off";
                    % Correct
                    ha31 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(3) ymap(4) axeSize2]);
                    ha31.XAxis.Visible = "off"; 
                    ha32 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(4) ymap(4) axeSize2]);
                    ha32.XAxis.Visible = "off"; ha32.YAxis.Visible = "off";
    
                    axesList_Prg = [ha31 ha32; ha21 ha22; ha11 ha12];
                    prgLim.Cor = [0.6 1.0]; prgLim.Pre = [0 0.2]; prgLim.Late = [0 0.2];
                    for i = 1:length(obj.CueOptions)
                        iCue = obj.CueOptions(i);
                        iPrgPerf = sbs.("progressPerf_"+iCue);
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
                                plot(ijkPrg_mean, "Color", c.Exp(k,:), "LineStyle", psize.CueLineStyle(i), "LineWidth", psize.CueLine(i));
                                prgLim.(jOut) = [min([min(ijkPrg_shade,[],"all") prgLim.(jOut)(1)]), ...
                                    max([max(ijkPrg_shade,[],"all") prgLim.(jOut)(2)])];
                            end
                            set(axesList_Prg(j,:), "YLim", prgLim.(jOut));
                            set(axesList_Prg(j,i), "TickDir", "out", "TickLength", tickLen,...
                                "XLim", [0.5 minPrgLen], "XTick", 0.5:5:minPrgLen, ...
                                "XTickLabel", num2str(20+(0.5:5:minPrgLen)'*10), ...
                                "YTick", yTick.Perf2, "YTickLabel", yTickLabel.Perf2, ...
                                "FontSize", fontSize.Axes, "FontName", "Arial");
                        end
                    end
    
                    xlabel(ha11, "Trials in session", "Units", "centimeters", ...
                        "FontSize", fontSize.Label, "FontName", "Arial");
                    ha11.XLabel.Position(1) = ha11.XLabel.Position(1)+(axeSize2(1)+xgap)/2;
                    ylabel(ha11, "Late (%)", "FontSize", fontSize.Label, "FontName", "Arial");
                    ylabel(ha21, "Pre (%)", "FontSize", fontSize.Label, "FontName", "Arial");
                    ylabel(ha31, "Cor (%)", "FontSize", fontSize.Label, "FontName", "Arial");
                    title(ha31, "Cue", "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");
                    title(ha32, "Uncue", "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");
                
                else
                    %% Progress compare between session pairs
                    if nDate.E1 ~= nDate.E2
                        error("Session numbers under two experiment conditions are not equal.");
                    end
                    axeSize5 = [axeSize1(1)*0.8 (axeSize1(2)*2-ygap)/3];
                    xmap(4) = xmap(3) + xgap + axeSize5(1);
                    xmap(5) = xmap(4) + xgap + axeSize5(1);
                    set(Fig, "Position", [2 2 xmap(end) ymap(end)]);
                    ymap2 = [ystart + ygap, ...
                             ystart + ygap*2 + axeSize5(2), ...
                             ystart + ygap*3 + axeSize5(2)*2];
                    % Late
                    hb1 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(3) ymap2(1) axeSize5]);
                    hb4 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(4) ymap2(1) axeSize5]);
                    hb4.YAxis.Visible = "off";
                    % Premature
                    hb2 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(3) ymap2(2) axeSize5]);
                    hb2.XAxis.Visible = "off";
                    hb5 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(4) ymap2(2) axeSize5]);
                    hb5.XAxis.Visible = "off"; hb5.YAxis.Visible = "off";
                    % Correct
                    hb3 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(3) ymap2(3) axeSize5]);
                    hb3.XAxis.Visible = "off"; 
                    hb6 = axes("NextPlot", "add", "Units", "centimeters", ...
                        "Position", [xmap(4) ymap2(3) axeSize5]);
                    hb6.XAxis.Visible = "off"; hb6.YAxis.Visible = "off";

                    axesList_Prg2 = [hb3 hb6; hb2 hb5; hb1 hb4];
                    prgLim.Cor = [0.6 1.0]; prgLim.Pre = [0 0.2]; prgLim.Late = [0 0.2];
                    for i = 1:length(obj.CueOptions)
                        iCue = obj.CueOptions(i);
                        iPrgPerf = sbs.("progressPerf_"+iCue);
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
                                plot(addon, ijkPrg', "Color", c.Exp(k,:), "LineStyle", psize.CueLineStyle(i), "LineWidth", psize.CueLine(i));
                                prgLim.(jOut) = [min([min(ijkPrg,[],"all") prgLim.(jOut)(1)]), ...
                                    max([max(ijkPrg,[],"all") prgLim.(jOut)(2)])];
                            end
                            set(axesList_Prg2(j,:), "YLim", prgLim.(jOut));
                            xtlabeltext = [xTickLabel.DateE1, repmat('\newline      vs.\newline', nDate.E1, 1), xTickLabel.DateE2];
                            set(axesList_Prg2(j,i), "TickDir", "out", "TickLength", tickLen,...
                                "XLim", xLim.DateE1, "XTick", xTick.DateE1, ...
                                "XTickLabel", xtlabeltext, ...
                                "YTick", yTick.Perf2, "YTickLabel", yTickLabel.Perf2, ...
                                "FontSize", fontSize.Axes, "FontName", "Arial");
                            if ~isempty(GapLineList.E1)
                                line(GapLineList.E1, prgLim.(jOut), ...
                                    "Color", c.GapLine, "LineStyle", ":", "LineWidth", psize.GapLine);
                            end
                        end
                    end
                    xlabel(hb1, "Trials in session", "Units", "centimeters", ...
                        "FontSize", fontSize.Label, "FontName", "Arial");
                    hb1.XLabel.Position(1) = hb1.XLabel.Position(1)+(axeSize5(1)+xgap)/2;
                    ylabel(hb1, "Late (%)", "FontSize", fontSize.Label, "FontName", "Arial");
                    ylabel(hb2, "Pre (%)", "FontSize", fontSize.Label, "FontName", "Arial");
                    ylabel(hb3, "Cor (%)", "FontSize", fontSize.Label, "FontName", "Arial");
                    title(hb3, "Cue", "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");
                    title(hb6, "Uncue", "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");
                end

                %% Add legends
                legendPerf = legend(ha51, [linePerf.lCueCor linePerf.lCuePre linePerf.lCueLate; lineHT.l1 lineHT.l2 lineHT.l3], ...
                    [obj.OutcomeOptions;obj.CueOptions "All"], ...
                    "FontSize", fontSize.Label, "FontName", "Arial", "NumColumns", 6, "Box", "off");
                legendPerf.ItemTokenSize = [12,15];
                set(legendPerf, "Units", "centimeters", 'Position', [xmap2(1)-xgap ymap(6) xmap2(4)-xmap2(1)-2*xgap 1]);
              
                legendPDF = legend(hb5, [linePDF.l11 linePDF.l12;linePDF.l21 linePDF.l22], ...
                    ["Cue-"+op.CompExp;"Uncue-"+op.CompExp],...
                    "NumColumns", 1, "FontSize", fontSize.Label, "FontName", "Arial", "Box", "off");
                legendPDF.ItemTokenSize = [12,15];
                set(legendPDF, "Units", "centimeters", 'Position', [xmap2(6)+axeSize3(1)/2 ymap(6)-ygap axeSize3(1)/2+2*xgap 1]);

                %% Add info

                uicontrol(Fig, "Style", "text", "Units", "centimeters", "BackgroundColor", "w", ...
                    "Position", [xmap2(1) ymap(7)-ygap axeSizeInfo], "HorizontalAlignment", "left", ...
                    "String", obj.Subject+"  |  "+unique(obj.Tasks)+"  |  "+op.CompExp(1)+" vs. "+op.CompExp(2), ...
                    "FontSize", fontSize.Info, "FontWeight", "bold", "FontName", "Arial");
            end
        
        end

    end
end

function stat = calIndivStatKB(data,multiSession,opts)
% calculate the STATs of one subject
% STATs of 1 session or across sessions (but in the same Experiment & Task)
    arguments
        data
        multiSession    = false
        opts.cuelist    = unique(data.Cue)
        opts.ifDistr    = false
        opts.edges_HT   = 0:0.05:3 % Hold time (All trials)
        opts.bins_HT    = 0.025:0.05:2.975
        opts.edges_RT   = 0:0.05:1 % Reaction time (Cor)
        opts.edges_RelT = 0:0.05:1 % Release time (Cor+Late)
        opts.smoWin     = 8 % smoothdata('gaussian')
    end

    cuelist = opts.cuelist;
    
    stat = table;  t = struct;

    t.Subject = data.Subject(1);
    t.Group = data.Group(1);
    t.Experiment = data.Experiment(1);
    t.Task = data.Task(1);
    if ~multiSession
        t.Session  = data.Session(1);
        t.Date     = data.Date(1);
    else
        t.nSession = length(unique(data.Session));
    end
    t.nTrial = length(data.iTrial);
    t.Dark = sum(data.DarkTry);
    t.DarkRatio = t.nTrial./(t.Dark+t.nTrial);

    idxCor  = data.Outcome == "Cor";
    idxPre  = data.Outcome == "Pre";
    idxLate = data.Outcome == "Late";
    t.Cor   = sum(idxCor)./t.nTrial;
    t.Pre   = sum(idxPre)./t.nTrial;
    t.Late  = sum(idxLate)./t.nTrial;
    
    t.HT = median(rmoutliers(data.HT,'quartiles'),'omitnan');
    t.HT_IQR = diff(prctile(data.HT, [25 75]));
    rt = calRT(data.HT(idxCor), data.FP(idxCor),...
        'Remove100ms', 0, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
    t.RT = rt.median;
    t.RT_IQR = diff(prctile(data.RT(idxCor), [25 75]));
    relt = calRT(data.HT(idxCor|idxLate), data.FP(idxCor|idxLate),...
        'Remove100ms', 0, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
    t.RelT = relt.median;
    t.RelT_IQR = diff(prctile(data.HT(idxCor|idxLate)-data.FP(idxCor|idxLate), [25 75]));
    t.MT = median(rmoutliers(data.MT,'quartiles'),'omitnan');

    % Stat in Cue/Uncue conditions, named var_KB rows corresponding to obj.CueOptions
    corKB = []; preKB = []; lateKB = []; htKB = []; htiqr_KB = [];
    rtKB = []; rtiqr_KB = []; reltKB = []; reltiqr_KB = []; mtKB = [];
    for i = 1:length(cuelist)
        idxThis = data.Cue == cuelist(i);
        if sum(idxThis) == 0
            corKB = [corKB, 0];
            preKB = [preKB, 0];
            lateKB = [lateKB, 0];
            htKB = [htKB, 0];
            htiqr_KB = [htiqr_KB, 0];
            rtKB = [rtKB, 0];
            rtiqr_KB = [rtiqr_KB, 0];
            reltKB = [reltKB, 0];
            reltiqr_KB = [reltiqr_KB, 0];
            mtKB = [mtKB, 0];
        else
            corKB = [corKB, sum(idxCor & idxThis)./sum(idxThis)];
            preKB = [preKB, sum(idxPre & idxThis)./sum(idxThis)];
            lateKB = [lateKB, sum(idxLate & idxThis)./sum(idxThis)];
            htKB = [htKB, median(rmoutliers(data.HT(idxThis),'quartiles'),'omitnan')];
            htiqr_KB = [htiqr_KB, iqr(data.HT(idxThis))];
            rtt = calRT(data.HT(idxCor & idxThis), data.FP(idxCor & idxThis),...
            'Remove100ms', 0, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
            rtKB = [rtKB, rtt.median];
            rtiqr_KB = [rtiqr_KB, iqr(data.RT(idxCor & idxThis))];
            reltt = calRT(data.HT((idxCor|idxLate)&idxThis), data.FP((idxCor|idxLate)&idxThis),...
            'Remove100ms', 0, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
            reltKB = [reltKB, reltt.median];
            reltiqr_KB = [reltiqr_KB, iqr(data.RelT((idxCor|idxLate) & idxThis))];
            mtKB = [mtKB, median(rmoutliers(data.MT(idxThis),'quartiles'),'omitnan')];
        end
    end
    t.Cor_KB = corKB;
    t.Pre_KB = preKB;
    t.Late_KB = lateKB;
    t.HT_KB = htKB;
    t.HT_IQR_KB = htiqr_KB;
    t.RT_KB = rtKB;
    t.RT_IQR_KB = rtiqr_KB;
    t.RelT_KB = reltKB;
    t.RelT_IQR_KB = reltiqr_KB;
    t.MT_KB = mtKB;

    % calculate distribution
    if opts.ifDistr
        t.HTpdf = smoothdata(histcounts(data.HT,...
            opts.edges_HT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
        t.RTpdf = smoothdata(histcounts(data.RT(idxCor),...
            opts.edges_RT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
        t.RelTpdf = smoothdata(histcounts(data.HT(idxCor|idxLate)-data.FP(idxCor|idxLate),...
            opts.edges_RelT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
        t.HTcdf = smoothdata(histcounts(data.HT,...
            opts.edges_HT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
        t.RTcdf = smoothdata(histcounts(data.RT(idxCor),...
            opts.edges_RT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
        t.RelTcdf = smoothdata(histcounts(data.HT(idxCor|idxLate)-data.FP(idxCor|idxLate),...
            opts.edges_RelT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
        
        for i = 1:length(cuelist)
            idxThis = data.Cue == cuelist(i);
            iCue = cuelist(i);
            
            t.("HTpdf_KB"+iCue) = smoothdata(histcounts(data.HT(idxThis),...
                opts.edges_HT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
            t.("RTpdf_KB"+iCue) = smoothdata(histcounts(data.RT(idxCor&idxThis),...
                opts.edges_RT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
            t.("RelTpdf_KB"+iCue) = smoothdata(histcounts(data.HT((idxCor|idxLate)&idxThis)-...
                data.FP((idxCor|idxLate)&idxThis),...
                opts.edges_RelT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
            t.("HTcdf_KB"+iCue) = smoothdata(histcounts(data.HT(idxThis),...
                opts.edges_HT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
            t.("RTcdf_KB"+iCue) = smoothdata(histcounts(data.RT(idxCor&idxThis),...
                opts.edges_RT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
            t.("RelTcdf_KB"+iCue) = smoothdata(histcounts(data.HT((idxCor|idxLate)&idxThis)-...
                data.FP((idxCor|idxLate)&idxThis),...
                opts.edges_RelT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
        end
    end
    stat = [stat;struct2table(t)];
end
