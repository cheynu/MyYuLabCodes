classdef BehaviorSRT
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
        Subject           string   % subject name
        Group             string = ""  % between-group variable (hM3Dq/ChR2, Lesion/Sham)
        Experiment        string = ""  % within-group variable (Saline/DCZ, PreLesion/PostLesion)
        Protocol          string = ""  % Jun/24/2024, revised for shifted fp task
        Task              string   % e.g., 3FPs
        Session           double = NaN  % e.g., 3 (manual)
        Date              double   % YYYYMMDD
        DateTime          datetime % e.g., datetime format precision time
        nTrial            double   % trial number in this session
        nPress            double   % press number (dark and probe not includeds)
        iPress      (:,1) double   % 1:nPress
        iTrial      (:,1) double   % dark and probe not included
        TimeElapsed (:,1) double   % sec, time of each trial
        Outcome     (:,1) string   % "Cor" "Pre" "Late"
        FP          (:,1) double   % sec, foreperiod
        RW          (:,1) double   % sec, response window
        HT          (:,1) double   % sec, hold time
        RT          (:,1) double   % sec, reaction time
        RelT        (:,1) double   % sec, release time (Cor + Late RT)
        MT          (:,1) double   % sec, movement time
    end

    properties (Dependent)
        MixedFP           double   % e.g., [0.5,1.0,1.5]
        Performance       table
        RawTable          table
        Table             table
        Dark              table
        Probe             table
    end
    
    properties (Dependent, GetAccess = private)
        SaveName
    end

    properties (Constant, GetAccess = private)
        OutcomeOptions = ["Cor", "Pre", "Late"] % 1 - Correct, -1 - Premature, -2 - Late
        DefaultMixedFP = [0.5, 1.0, 1.5]
    end

    methods
        function obj = BehaviorSRT(in)
            % e.g., filename = 'Strangelove_DSRT_06_3FPs_20221115_151443.mat';
            % Construct an instance of this class
            switch class(in)
                case 'struct'
                    datain = in;
                otherwise % filename
                    mustBeFile(in);
                    datain = extractBpodData(in);
            end
            fields = fieldnames(datain);
            for iField=1:length(fields)
                field = fields{iField};
                obj.(field) = datain.(field);
            end
        end

        function obj = set.Protocol(obj, in)
            obj.Protocol = in;
        end

        function value = get.SaveName(obj)
            value = "BClass_"+upper(obj.Subject)+"_"+string(obj.DateTime,'yyyyMMdd_HHmmss');
        end

        function value = get.MixedFP(obj)
            % modify MixedFP if needed
            FPuni = round(unique(obj.Table.FP), 2);
            switch lower(obj.Task)
                case "autoshaping"
                    value = max(obj.Table.FP);
                case {"leverpress", "leverrelease"}
                    value = NaN;
                case {"wait1", "wait2"}
                    value = obj.DefaultMixedFP;
                case "3fps"
                    if all(ismember(FPuni, obj.DefaultMixedFP))
                        value = obj.DefaultMixedFP;
                    else
                        value = FPuni;
                    end
                case {"wait1ephys", "wait2ephys", "2fps"}
                    value = [0.75 1.5];
                otherwise
                    value = FPuni;
            end

            if any(ismember(obj.Protocol, "Shift250"))
                value = value(2:end);
            end
        end

        function value = get.Performance(obj)
            nFP = length(obj.MixedFP);
            varNames = ["FP", "nCor", "nPre", "nLate", "rCor", "rPre", "rLate", ...
                        "medianRT", "medianRelT", "RT", "RelT"];
            nVar = length(varNames);

            tbl = table('Size', [nFP+1 nVar], ...
                'VariableTypes', [repmat("double", [1 nVar-2]) "cell" "cell"], ...
                'VariableNames', varNames, ...
                'RowNames', [string(obj.MixedFP) "All"]);

            idxCor  = obj.Table.Outcome == "Cor";
            idxPre  = obj.Table.Outcome == "Pre";
            idxLate = obj.Table.Outcome == "Late";

            for i = 1:nFP
                idxFP = obj.Table.FP == obj.MixedFP(i);

                tbl.nCor(i)  = sum(idxFP & idxCor);
                tbl.rCor(i)  = sum(idxFP & idxCor)/sum(idxFP);
                tbl.nPre(i)  = sum(idxFP & idxPre);
                tbl.rPre(i)  = sum(idxFP & idxPre)/sum(idxFP);
                tbl.nLate(i) = sum(idxFP & idxLate);
                tbl.rLate(i) = sum(idxFP & idxLate)/sum(idxFP);
                tbl.FP(i)    = obj.MixedFP(i);
                tbl.RT{i}    = obj.RT(idxFP & idxCor);
                tbl.RelT{i}  = obj.RelT(idxFP & (idxCor | idxLate));

                iHT_Cor = obj.Table.HT(idxFP & idxCor);
                iFP_Cor = obj.Table.FP(idxFP & idxCor);
                iRT = calRT(iHT_Cor, iFP_Cor, 'Remove100ms', 1, ...
                    'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
                tbl.medianRT(i) = iRT.median;

                iHT_CorLate = obj.Table.HT(idxFP & (idxCor | idxLate));
                iFP_CorLate = obj.Table.FP(idxFP & (idxCor | idxLate));
                iRelT = calRT(iHT_CorLate, iFP_CorLate, 'Remove100ms', 1, ...
                    'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
                tbl.medianRelT(i) = iRelT.median;
            end

            i = i + 1;
            tbl.nCor(i)  = sum(idxCor);  tbl.rCor(i)  = sum(idxCor)/obj.nTrial;
            tbl.nPre(i)  = sum(idxPre);  tbl.rPre(i)  = sum(idxPre)/obj.nTrial;
            tbl.nLate(i) = sum(idxLate); tbl.rLate(i) = sum(idxLate)/obj.nTrial;
            tbl.FP(i)    = "All";
            tbl.RT{i}    = obj.RT(idxCor);
            tbl.RelT{i}  = obj.RelT(idxCor | idxLate);

            iRT = calRT(obj.Table.HT(idxCor), obj.Table.FP(idxCor), ...
                        'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
            tbl.medianRT(i)   = iRT.median;

            iRelT = calRT(obj.Table.HT(idxCor | idxLate), ...
                          obj.Table.FP(idxCor | idxLate), ...
                          'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
            tbl.medianRelT(i) = iRelT.median;

            value = tbl;
        end

        function value = get.RawTable(obj)
            tablenames = {'Subject','Group','Experiment','Task', ...
                'Session','Date','iTrial','iPress','TimeElapsed',...
                'FP','RW','Outcome','HT','RT','MT','RelT'};
            value = table(...
                repelem(obj.Subject,obj.nPress)',...
                repelem(obj.Group,obj.nPress)',...
                repelem(obj.Experiment,obj.nPress)',...
                repelem(obj.Task,obj.nPress)',...
                repelem(obj.Session,obj.nPress)',...
                repelem(obj.Date,obj.nPress)',...
                obj.iTrial,obj.iPress,obj.TimeElapsed,...
                obj.FP,obj.RW,obj.Outcome,obj.HT,...
                obj.RT,obj.MT,obj.RelT,...
                'VariableNames',tablenames);
        end

        function value = get.Table(obj)
            idx = ~isnan(obj.RawTable.iTrial);
            value = obj.RawTable(idx, :);
        end

        function value = get.Dark(obj)
            idx = obj.RawTable.Outcome == "Dark";
            value = obj.RawTable(idx, :);
        end

        function value = get.Probe(obj)
            idx = obj.RawTable.Outcome == "Probe";
            value = obj.RawTable(idx, :);
        end

        % function out = calPrematureCDF(obj, options)
        %     arguments
        %         obj
        %         options.tbin = 0.01
        %         options.tmin = 0.1   % minimal response time, anything before FP+timin 
        %                              % is considered an anticipatory response
        %     end
        %     allFPs = obj.MixedFP;
        %     tbins = 0:options.tbin:(allFPs(end)+options.tmin);
        %     CDF = zeros(1,length(tbins));
        % 
        %     for i = 2:length(tbins)
        %         idx_FP = (obj.FP+options.tmin) >= tbins(i);
        %         idx_anticipatory = obj.HT(idx_FP) < (obj.FP(idx_FP)+options.tmin);
        %         CDF(i) = sum(idx_anticipatory)/sum(idx_FP);
        %     end
        %     out = CDF;
        % end

        function out = calPrematureCDF(obj, options)
            arguments
                obj
                options.tbin = 0.01
                options.tmin = 0.1   % minimal response time, anything before FP+timin 
                                     % is considered an anticipatory response
            end
            tbins = (0:options.tbin:obj.MixedFP(end)+options.tmin);
            cdf = zeros(1, length(tbins));
            
            for k = 2:length(tbins)
                
                ind_counts = find(tbins(k)<=obj.FP+options.tmin);

                n_total = 0; n_less = 0;
                    
                for j = 1:length(ind_counts)
                    jdata = obj.HT(ind_counts(j));
                    jdata_anticipatory = jdata(jdata<=tbins(k));
                    
                    n_total = n_total +length(jdata);
                    n_less = n_less +length(jdata_anticipatory);
                end
                
                cdf(k) = n_less/n_total;
                
            end
            
            out = cdf';
            
        end

        function out = calProgress(obj,targetVar,options)
            arguments
                obj
                targetVar             {mustBeText} = "Outcome"  % variables to calculate
                options.tarStr        {mustBeText} = ["Cor", "Pre", "Late"]  % divide targetVar by tarStr
                options.avgMethod     {mustBeMember(options.avgMethod,{'mean','median'})} = 'mean'
                options.slidingMethod {mustBeMember(options.slidingMethod,{'ratio','fixed'})} = 'ratio'
                options.winRatio  = 8
                options.stepRatio = 2
                options.winSize   = 30 % trials
                options.stepSize  = 10 % trials
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
            if obj.Task == "3FPs"
                for iFP = 1:length(obj.DefaultMixedFP)
                    out.("x"+string(iFP)) = table;
                    out.("y"+string(iFP)) = table;
                end
            end

            for i=1:length(options.tarStr)
                calmultiFP = 1;
                switch targetVar
                    case "FP"
                        tarVarData = obj.Table.FP;
                        calmultiFP = 0;
                    case "RT"
                        if options.tarStr{i} == "Cor"
                            tarVarData = obj.Table.RT;
                        elseif options.tarStr{i} == "CorLate"
                            tarVarData = obj.Table.RelT;
                        else
                            error('Check input "tarStr" in calProgress("RT")');
                        end
                    case "Outcome"
                        tarVarData = obj.Table.Outcome;
                end
                [x,y] = calMovAVG(obj.Table.TimeElapsed,tarVarData,...
                    'winRatio',options.winRatio,'stepRatio',options.stepRatio,...
                    'winSize',options.winSize,'stepSize',options.stepSize,...
                    'tarStr',options.tarStr{i},'avgMethod',options.avgMethod);
                out.x = addvars(out.x,x,'NewVariableNames',options.tarStr{i});
                out.y = addvars(out.y,y,'NewVariableNames',options.tarStr{i});
                if obj.Task == "3FPs" && calmultiFP == 1
                    for iFP = 1:length(obj.DefaultMixedFP)
                        idxFP = obj.Table.FP == obj.DefaultMixedFP(iFP);
                        [x,y] = calMovAVG(obj.Table.TimeElapsed(idxFP),tarVarData(idxFP),...
                            'winRatio',options.winRatio,'stepRatio',options.stepRatio,...
                            'winSize',options.winSize,'stepSize',options.stepSize,...
                            'tarStr',options.tarStr{i},'avgMethod',options.avgMethod);
                        out.("x"+string(iFP)) = addvars(out.("x"+string(iFP)),x,'NewVariableNames',options.tarStr{i});
                        out.("y"+string(iFP)) = addvars(out.("y"+string(iFP)),y,'NewVariableNames',options.tarStr{i});
                    end
                end
            end
        end

        function [objOut,isMerge] = merge(obj,obj2,method,just1Day)
            arguments
                obj
                obj2 BehaviorSRT
                method string {mustBeMember(method, ["Merge","Select"])} = "Merge"
                just1Day = true
            end
            objOut = obj;
            isMerge = false;
            if just1Day && ~isequal(obj.Date,obj2.Date)
                return
            elseif ~strcmpi(obj.Subject,obj2.Subject)...
                    || ~strcmpi(obj.Task,obj2.Task)
                return
            end
            if method == "Select" % select data with more trials
                if obj.nTrial < obj2.nTrial
                    objOut = obj2;
                end
                isMerge = true;
                return
            end
            % Merge method
            diffTime = minus(obj.DateTime,obj2.DateTime);
            diffSec = abs(seconds(diffTime)); % when isNewEarly==true, diffSec>0
            if diffTime > 0
                objEarly = obj2;
                objLate  = obj;
            else
                objEarly = obj;
                objLate  = obj2;
            end
            objLate.TimeElapsed = objLate.TimeElapsed(:)+diffSec;

            objOut = objEarly;
            objOut.nTrial = objEarly.nTrial + objLate.nTrial;
            objOut.nPress = objEarly.nPress + objLate.nPress;

            % sort trial/press idx using rawtable
            t1 = objEarly.RawTable;
            t2 = objLate.RawTable;
            t0 = [t1;t2]; t0 = sortrows(t0,"TimeElapsed");
            t0.iTrial(~isnan(t0.iTrial)) = 1:objOut.nTrial;
            t0.iPress(:) = 1:objOut.nPress;

            objOut.TimeElapsed = t0.TimeElapsed;
            objOut.iTrial = t0.iTrial;
            objOut.iPress = t0.iPress;
            objOut.Outcome = t0.Outcome;
            objOut.FP = t0.FP;
            objOut.RW = t0.RW;
            objOut.RT = t0.RT;
            objOut.HT = t0.HT;
            objOut.MT = t0.MT;
            objOut.RelT = t0.RelT;
            isMerge = true;
        end

        function save(obj, savepath)
            arguments
                obj
                savepath = pwd;
            end
            [~,~] = mkdir(savepath);
            save(fullfile(savepath,obj.SaveName), "obj");
            writetable(obj.Table,fullfile(savepath,obj.SaveName+".csv"));
        end

        function Fig = plot(obj, options)
            arguments
                obj
                options.plotType string {mustBeMember(options.plotType, ...
                    ["SRT", "SRT_V2"])}  = "SRT_V2"
                options.htLim     double  = [0 3]
                options.rtLim     double  = [0 1]
                options.perfLim   double  = [0 1]
                options.bw_kernel double  = 0.08
                options.bw_hist   double  = 0.05
            end
            bw_kernel = options.bw_kernel;
            bw_hist   = options.bw_hist;
            edges_HT  = options.htLim(1):bw_hist:options.htLim(2);
            bins_HT   = (options.htLim(1)+0.5*bw_hist):bw_hist:(options.htLim(2)-0.5*bw_hist);

            % Parameters
            set(groot,'defaultAxesFontName','Dejavu Sans');
            fontSize = struct("Axes", 7, "Label", 7, "Title", 10, "Info", 12);
            tickLen = [0.0200 0.0250]; tickLen2 = tickLen/3; tLim = [0 3000];           

            yLim.HT = options.htLim;
            yTick.HT = yLim.HT(1):0.5:yLim.HT(2);
            yTickLabel.HT = num2str(yTick.HT' * 1000);
            yTick.HT2 = yLim.HT(1):1:yLim.HT(2);
            yTickLabel.HT2 = num2str(yTick.HT2' * 1000);

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
            xLim.Time = [0 3000];
            xTick.Time = [xLim.Time(1) xLim.Time(2)];
            xTickLabel.Time = num2str(xTick.Time');
            xTick.Time2 = xLim.Time(1):1000:xLim.Time(2);
            xTickLabel.Time2 = num2str(xTick.Time2');

            cTab10 = tab10(10); cAccent = Accent(8); cDarkGrey = cAccent(end,:);
            cBlue = cTab10(1,:); cOrange = cTab10(2,:); cGreen = cTab10(3,:);
            cRed  = cTab10(4,:); cGrey = cTab10(8,:);

            font = "Dejavu Sans";
            c = struct("Perf", [cGreen;cRed;cGrey], "MixedFPs", [cGrey;mean([cOrange;cGrey]);cOrange], ...
                       "MixedFPsJY", ["#9BBEC8", "#427D9D", "#164863"], ...
                       "PostExpJY", "#FF6C22", ...
                       "Exp", [cOrange;cDarkGrey], "CustomLine", [cBlue;cRed], ...
                       "Scatter", ["flat", "none"], "Shade", cOrange, "GapLine", cGrey, "FPLine", 'k', ... % Raster plot
                       "Whisker", cRed, "Violin", cGrey, "ViolinEdge", cGrey, "ViolinBox", cBlue, ...
                       "htColorMap", customcolormap([0 1], [cRed;cBlue]), ...
                       "Samples", [cBlue;cRed;cGreen], "Unsampled", cBlue);
            alpha = struct("Shade", 0.1, "Violin", 0.2, "Scatter", 0.5, "MixedFPs", [0.5 0.6 0.7]);
            psize = struct("Marker", [4 6 8], "Scatter", [25 30 35], "ScatterLine", [0.5 0.5 0.5], ...
                           "CustomLine", [1.5 1.5 1.5], "GapLine", 0.5, "FPLine", 1, "MixedFPs", [1 1.4 1.8], ...
                           "Arrow", [2 3 35], "RecoveryV2", 5);  % arrow parameters [linewidth length tipangle]
            style = struct("MarkerStyleFP", ["o", "^", "square"], "LineStyleFP", ["-", ":", "-."], ...
                           "MarkerStyleRec", ["o", "^", "diamond"]);

            if obj.Task == "AutoShaping"
                Fig = plot_autoshaping(obj);
            elseif obj.Task == "LeverPress" || obj.Task == "LeverRelease"
                Fig = plot_leveroperant(obj);
            elseif options.plotType == "SRT"
                Fig = plot_srt(obj);
            elseif options.plotType == "SRT_V2"
                Fig = plotSRT_V2(obj);
            end


            function Fig = plotSRT_V2(obj)
                
                switch obj.Task
                    case {"Wait1", "Wait2", "Wait1Ephys", "Wait2Ephys"}
                        fpList = [0 obj.MixedFP(end)];
                        obj.FP(obj.FP ~= fpList(2)) = 0;
                        isWait = 1;
                    case {"3FPs", "2FPs"}
                        fpList = obj.MixedFP;
                        isWait = 0;
                end
                nFP = length(fpList);
                PDF = cell(nFP, 1);
                HIST = cell(nFP, 1);
                for i = 1:nFP
                    idxFP = obj.Table.FP == fpList(i);
                    PDF{i} = ksdensity(obj.Table.HT(idxFP), edges_HT, 'Bandwidth', bw_kernel);
                    HIST{i} = histcounts(obj.Table.HT(idxFP), "Normalization", "pdf", "BinEdges", edges_HT);
                end
                pdfLim = ceil(max(cellfun(@(x) max(x, [], "all"), PDF)))+1;
                histLim = ceil(max(cellfun(@(x) max(x, [], "all"), HIST)));
                pdfLim = max([pdfLim histLim]);

                xstart = 1.5; ystart = 1.8; xgap = 0.5; ygap = 1;

                axeSize1 = [2.7 3];                           % HT
                axeSize2 = [axeSize1(1)*2.5+2*xgap 4];        % sliding perf
                axeSize3 = [axeSize1(1)*1.8 axeSize1(2)]; % perf summary
                
                xmap = [xstart, ...
                        xstart + xgap*1 + axeSize1(1)*1, ...
                        xstart + xgap*2 + axeSize1(1)*2, ...
                        xstart + xgap*3 + axeSize1(1)*3, ...
                        xstart + xgap*4 + axeSize1(1)*4, ...
                        xstart + xgap*7 + axeSize1(1)*5];

                axeSizeInfo = [xmap(end)-xmap(1) 0.5];

                ymap = [ystart, ...
                        ystart + ygap*0.5 + axeSize2(2), ...
                        ystart + ygap*2 + axeSize2(2) + axeSize1(2)*1, ...
                        ystart + ygap*3 + axeSize2(2) + axeSize1(2)*2, ...
                        ystart + ygap*4 + axeSize2(2) + axeSize1(2)*3, ...
                        ystart + ygap*5 + axeSize2(2) + axeSize1(2)*3, ...
                        ystart + ygap*5 + axeSize2(2) + axeSize1(2)*3 + axeSizeInfo(2)];
                % ymap = fliplr(ymap);

                Fig = figure(1); clf(Fig, "reset");
                set(Fig, "Unit", "centimeters", "PaperPositionMode", "auto", ...
                    "Position", [2 2 xmap(end) ymap(end)], "Color", "w");
                
                for i = 1:nFP
                    h.("a1"+num2str(i)) = axes;
                    set(h.("a1"+num2str(i)), "Units", "centimeters", "Position", [xmap(i) ymap(4) axeSize1],...
                        "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                        "XLim", xLim.Time, "XTick", xTick.Time, "XTickLabel", xTickLabel.Time, ...
                        "YLim", yLim.HT, "YTick", [], "YTickLabel", {}, ...
                        "FontSize", fontSize.Axes, "FontName", font);
                    idxFP = obj.Table.FP == fpList(i);
                    if isWait && i == 1
                        set(h.("a1"+num2str(i)), "XLim", [0 max(obj.TimeElapsed(idxFP))])
                        title("< "+string(fpList(end))+" s | "+sum(idxFP), "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                    else
                        title(string(fpList(i))+" s | "+sum(idxFP), "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                    end
                    for j = 1:length(obj.OutcomeOptions)
                        idxOutcome = obj.Table.Outcome == obj.OutcomeOptions(j);
                        scatter(obj.Table.TimeElapsed(idxFP & idxOutcome), obj.Table.HT(idxFP & idxOutcome), ...
                            psize.Scatter(i), c.Perf(j,:), "LineWidth", psize.ScatterLine(i), "MarkerFaceColor", "none");
                    end
                    fill([xLim.Time(1) xLim.Time(1) xLim.Time(2) xLim.Time(2)], ...
                        [0 fpList(i) fpList(i) 0], c.Shade, ...
                        "FaceAlpha", alpha.Shade, "EdgeColor", "none");
                    if i == 1
                        set(h.("a1"+num2str(i)), "YTick", yTick.HT2, "YTickLabel", yTickLabel.HT2);
                        xlabel("Time in session (sec)", "FontSize", fontSize.Label, "FontName", font);
                        ylabel("Press duration (ms)", "FontSize", fontSize.Label, "FontName", font);
                    end

                    h.("a2"+num2str(i)) = axes;
                    set(h.("a2"+num2str(i)), "Units", "centimeters", "Position", [xmap(i) ymap(3) axeSize1],...
                        "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                        "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, "XTickLabelRotation", 0, ...
                        "YLim", [0 pdfLim], "YTick", [], "YTickLabel", {}, ...
                        "FontSize", fontSize.Axes, "FontName", font);
    
                    histogram(h.("a2"+num2str(i)), obj.Table.HT(idxFP), "Normalization", "pdf", ...
                        "BinEdges", edges_HT, "FaceColor", c.MixedFPsJY(i), "EdgeColor", "none");
                    plot(edges_HT, PDF{i}, '-r', "LineWidth", 1);
                    fill([0 0 fpList(i) fpList(i)], [0 pdfLim pdfLim 0], c.Shade, ...
                        "FaceAlpha", alpha.Shade, "EdgeColor", "none");
                    if i == 1
                        if pdfLim >= 2
                            set(h.("a2"+num2str(i)), "YTick", 0:2:pdfLim, "YTickLabel", string(0:2:pdfLim));
                        else
                            set(h.("a2"+num2str(i)), "YTick", [0 pdfLim], "YTickLabel", string([0 pdfLim]));
                        end
                        ylabel("Density (1/s)", "FontSize", fontSize.Label, "FontName", font);
                    end

                    h.("a3"+num2str(i)) = axes;
                    set(h.("a3"+num2str(i)), "Units", "centimeters", "Position", [xmap(i) ymap(2) axeSize1],...
                        "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                        "XTick", [], "XTickLabel", {}, ...
                        "YLim", yLim.RT, "YTick", yTick.RT2, "YTickLabel", {}, ...
                        "FontSize", fontSize.Axes, "FontName", font);
                    violinCue = violinplot(obj.Table.RelT(idxFP), obj.Table.FP(idxFP), ...
                        'ViolinColor', c.Violin, ...
                        'Width', 0.4, 'ViolinAlpha', alpha.Violin, 'ShowWhiskers', false, ...
                        'BoxColor', c.Whisker, 'BoxWidth', 0.01, 'EdgeColor', c.ViolinEdge);
                    violinCue.MedianPlot.LineWidth = 1.5;
                    violinCue.MedianPlot.SizeData  = 30;
                    violinCue.ScatterPlot.MarkerFaceColor = c.MixedFPsJY(i);
                    violinCue.ScatterPlot.SizeData = 25;
                    violinCue.ScatterPlot.MarkerFaceAlpha = 0.8;

                    set(gca, "Box", "off", "XTickLabel", {});
                    if i == 1
                        set(h.("a3"+num2str(i)), "YTick", yTick.RT2, "YTickLabel", yTickLabel.RT2);
                        ylabel("Reaction time (ms)", "FontSize", fontSize.Label, "FontName", font);
                    end
                    medianRT = median(obj.Table.RelT(idxFP), "omitmissing")*1000;
                    iqrRT    = iqr(obj.Table.RelT(idxFP))*1000;
                    title(num2str(medianRT, "%.0f")+" | "+num2str(iqrRT, "%.0f"), "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                end

                if size(obj.Probe, 1) > 0
                    ha14 = axes;
                    set(ha14, "Units", "centimeters", "Position", [xmap(nFP+1) ymap(4) axeSize1],...
                        "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                        "XLim", xLim.Time, "XTick", xTick.Time, "XTickLabel", xTickLabel.Time, ...
                        "YLim", yLim.HT, "YTick", [], "YTickLabel", {}, ...
                        "FontSize", fontSize.Axes, "FontName", font);
                    title("Probe | "+size(obj.Probe,1), "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                    scatter(obj.Probe.TimeElapsed, obj.Probe.HT, ...
                        psize.Scatter(3), c.Unsampled, "LineWidth", psize.ScatterLine(3), "MarkerFaceColor", "none");

                    ha24 = axes;
                    set(ha24, "Units", "centimeters", "Position", [xmap(4) ymap(3) axeSize1],...
                        "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                        "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, "XTickLabelRotation", 0, ...
                        "YLim", [0 pdfLim], "YTick", [], "YTickLabel", {}, ...
                        "FontSize", fontSize.Axes, "FontName", font);
    
                    histogram(ha24, obj.Probe.HT, "Normalization", "pdf", ...
                        "BinEdges", edges_HT, "FaceColor", 'k', "EdgeColor", "none");
                    pdf_probe = ksdensity(obj.Probe.HT, edges_HT, 'Bandwidth', bw_kernel);
                    plot(edges_HT, pdf_probe, '-r', "LineWidth", 1);
                end

                if size(obj.Dark, 1) > 0
                    if size(obj.Probe, 1) > 0; xid = nFP+2; else; xid = nFP+1; end
                    ha15 = axes;
                    set(ha15, "Units", "centimeters", "Position", [xmap(xid) ymap(4) axeSize1],...
                        "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                        "XLim", xLim.Time, "XTick", xTick.Time, "XTickLabel", xTickLabel.Time, ...
                        "YLim", yLim.HT, "YTick", [], "YTickLabel", {}, ...
                        "FontSize", fontSize.Axes, "FontName", font);
                    title("Dark | "+size(obj.Dark,1), "FontSize", fontSize.Title, "FontName", font, "FontWeight", "bold");
                    scatter(obj.Dark.TimeElapsed, obj.Dark.HT, ...
                        psize.Scatter(3), 'k', "LineWidth", psize.ScatterLine(3), "MarkerFaceColor", "none");

                    ha25 = axes;
                    set(ha25, "Units", "centimeters", "Position", [xmap(xid) ymap(3) axeSize1],...
                        "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                        "XLim", xLim.HT, "XTick", xTick.HT, "XTickLabel", xTickLabel.HT, "XTickLabelRotation", 0, ...
                        "YLim", [0 pdfLim], "YTick", [], "YTickLabel", {}, ...
                        "FontSize", fontSize.Axes, "FontName", font);
    
                    histogram(ha25, obj.Dark.HT, "Normalization", "pdf",...
                        "BinEdges", edges_HT, "FaceColor", 'k', "EdgeColor", "none");
                    pdf_dark = ksdensity(obj.Dark.HT, edges_HT, 'Bandwidth', bw_kernel);
                    plot(edges_HT, pdf_dark, '-r', "LineWidth", 1);
                end
                
                ha41 = axes;
                set(ha41, "Units", "centimeters", "Position", [xmap(1) ymap(1) axeSize2],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2,...
                    "XLim", xLim.Time, "XTick", xTick.Time2, "XTickLabel", xTickLabel.Time2, ...
                    "YLim", yLim.Perf, "YTick", yTick.Perf2, "YTickLabel", yTickLabel.Perf2, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                xlabel("Time in session (sec)", "FontSize", fontSize.Label);
                ylabel("Performance (%)", "FontSize", fontSize.Label);

                sldRe = obj.calProgress("Outcome",'tarStr',{'Cor','Pre','Late'},...
                    'avgMethod','mean','slidingMethod','ratio','winRatio',8,'stepRatio',2);
                for i = 1:length(obj.OutcomeOptions)
                    plot(sldRe.x.(obj.OutcomeOptions(i)), sldRe.y.(obj.OutcomeOptions(i)),...
                        '-o', 'color', c.Perf(i,:), 'linewidth', 1.2, ...
                        'markersize', 5, 'markerfacecolor', c.Perf(i,:), 'markeredgecolor', 'w');
                end

                % Num of Outcome
                ha42 = axes;
                set(ha42, 'units', 'centimeters', 'position', [xmap(4)+xgap*3 ymap(1) axeSize3],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                xlabel("", "FontSize", fontSize.Label);
                ylabel("Number", "FontSize", fontSize.Label);
                
                idxCor  = obj.Table.Outcome == obj.OutcomeOptions(1);
                idxPre  = obj.Table.Outcome == obj.OutcomeOptions(2);
                idxLate = obj.Table.Outcome == obj.OutcomeOptions(3);
                X = categorical({'Cor','Pre','Late','Probe','Dark'});
                X = reordercats(X,{'Cor','Pre','Late','Probe','Dark'});
                bh = bar(X,[sum(idxCor),sum(idxPre),sum(idxLate),size(obj.Probe,1),size(obj.Dark,1)],...
                    'FaceColor','flat','EdgeColor','none');
                bh.CData(1,:) = c.Perf(1,:);
                bh.CData(2,:) = c.Perf(2,:);
                bh.CData(3,:) = c.Perf(3,:);
                bh.CData(4,:) = cBlue;
                bh.CData(5,:) = [0 0 0];
                xtps = bh.XEndPoints;
                ytps = bh.YEndPoints;
                Labl = string(bh.YData);
                text(xtps,ytps,Labl,'HorizontalAlignment','center',...
                    'VerticalAlignment','bottom','fontsize',fontSize.Axes);

                % Performance - progress/criterion
                ha42b = axes;
                set(ha42b, 'units', 'centimeters', 'position', [xmap(4)+xgap*3 ymap(2) axeSize3],...
                    "NextPlot", "add", "TickDir", "out", "TickLength", tickLen2, ...
                    "FontSize", fontSize.Axes, "FontName", font);
                xlabel("", "FontSize", fontSize.Label);
                ylabel("Performance %", "FontSize", fontSize.Label);
                
                if isWait
                    idxS = obj.Table.FP == fpList(1);
                    idxL = obj.Table.FP == fpList(2);
                    OutS = obj.Table.Outcome(idxS);
                    OutL = obj.Table.Outcome(idxL);
                    bh2 = bar(fpList.*1000,...
                        [sum(OutS==obj.OutcomeOptions(1))/length(OutS),sum(OutS==obj.OutcomeOptions(2))/length(OutS),sum(OutS==obj.OutcomeOptions(3))/length(OutS);...
                         sum(OutL==obj.OutcomeOptions(1))/length(OutL),sum(OutL==obj.OutcomeOptions(2))/length(OutL),sum(OutL==obj.OutcomeOptions(3))/length(OutL);].*100,...
                        'FaceColor','flat','EdgeColor','none');
                    set(ha42b, "XTick", fpList.*1000, "XTickLabel", ["<1500", "1500"]);
                else
                    idxS = obj.Table.FP == fpList(1);
                    idxM = obj.Table.FP == fpList(2);
                    idxL = obj.Table.FP == fpList(3);
    
                    OutS = obj.Table.Outcome(idxS);
                    OutM = obj.Table.Outcome(idxM);
                    OutL = obj.Table.Outcome(idxL);
                    
                    bh2 = bar(fpList.*1000,...
                        [sum(OutS==obj.OutcomeOptions(1))/length(OutS),sum(OutS==obj.OutcomeOptions(2))/length(OutS),sum(OutS==obj.OutcomeOptions(3))/length(OutS);...
                         sum(OutM==obj.OutcomeOptions(1))/length(OutM),sum(OutM==obj.OutcomeOptions(2))/length(OutM),sum(OutM==obj.OutcomeOptions(3))/length(OutM);...
                         sum(OutL==obj.OutcomeOptions(1))/length(OutL),sum(OutL==obj.OutcomeOptions(2))/length(OutL),sum(OutL==obj.OutcomeOptions(3))/length(OutL);].*100,...
                        'FaceColor','flat','EdgeColor','none');
                end
                bh2(1).FaceColor = c.Perf(1,:);
                bh2(2).FaceColor = c.Perf(2,:);
                bh2(3).FaceColor = c.Perf(3,:);
                xtps1 = bh2(1).XEndPoints; xtps2 = bh2(2).XEndPoints; xtps3 = bh2(3).XEndPoints;
                ytps1 = bh2(1).YEndPoints; ytps2 = bh2(2).YEndPoints; ytps3 = bh2(3).YEndPoints;
                Labl1 = string(round(bh2(1).YData)); Labl2 = string(round(bh2(2).YData)); Labl3 = string(round(bh2(3).YData));
                text(xtps1,ytps1,Labl1,'HorizontalAlignment','center',...
                    'VerticalAlignment','bottom','fontsize',fontSize.Axes);
                text(xtps2,ytps2,Labl2,'HorizontalAlignment','center',...
                    'VerticalAlignment','bottom','fontsize',fontSize.Axes);
                text(xtps3,ytps3,Labl3,'HorizontalAlignment','center',...
                    'VerticalAlignment','bottom','fontsize',fontSize.Axes);

                ha00 = axes;
                set(ha00, "Units", "centimeters", "Position", [xmap(1)-xstart/2 ymap(5)-ygap/2 axeSizeInfo]);
                axis off;
                title("Subject: "+obj.Subject+" | "+string(obj.DateTime), ...
                    "FontSize", fontSize.Title, "FontName", "Dejavu Sans", "FontWeight", "bold");

            end

            %% plot session summary for SRT task
            function progFig = plot_srt(obj)
                
                cTab10 = tab10(10);
                cBlue = cTab10(1,:); cGreen = cTab10(3,:); cRed = cTab10(4,:);
                cGray = cTab10(8,:); cCyan = cTab10(10,:); cDark = [0 0 0];
                cCPL = [cGreen;cRed;cGray];
            
                set(groot,'defaultAxesFontName','Dejavu Sans');
                FontAxesSz = 7; FontLablSz = 9; FontTitlSz = 10;
                tLim = [0 3600]; htLim = [0 2500]; mtLim = [0,3];

                figSize = [2 2 15 17];
                xpos = [1.3,11];
                ypos = [1.3,6.6,11.9,13.9];
                plotsize1 = [8 4];
                plotsize2 = [3.5 4];
                plotsize3 = [2.5 4];
                plotsize4 = [3.5 1.7];

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
                idxCor = bt.Outcome == obj.OutcomeOptions(1);
                idxPre = bt.Outcome == obj.OutcomeOptions(2);
                idxLate = bt.Outcome == obj.OutcomeOptions(3);
                
                progFig = figure(1); clf(progFig);
                set(progFig, 'unit', 'centimeters', 'position', figSize, 'color', 'w');
                
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
                sldRe = obj.calProgress("Outcome",'tarStr',{'Cor','Pre','Late'},...
                    'avgMethod','mean','slidingMethod','ratio','winRatio',8,'stepRatio',2);
                ha3 = axes;
                set(ha3, 'units', 'centimeters', 'position', [xpos(1) ypos(3), plotsize1],...
                    'nextplot', 'add', 'ylim', [0 1], 'ytick',0:0.2:1, 'yticklabel', string((0:0.2:1).*100), 'xlim', tLim,'tickdir','out',...
                    'TickLength', [0.0200 0.0250],'fontsize',FontAxesSz);
                xlabel('Time in session (sec)','FontSize',FontLablSz);
                ylabel('Performance (%)','FontSize',FontLablSz);
                
                %     mc = 100.*sum(strcmp(bt.Outcome,obj.OutcomeOptions{1}))./length(bt.Outcome);
                %     mp = 100.*sum(strcmp(bt.Outcome,obj.OutcomeOptions{2}))./length(bt.Outcome);
                %     ml = 100.*sum(strcmp(bt.Outcome,obj.OutcomeOptions{3}))./length(bt.Outcome);
                %     line(tLim,repelem(mc,2)','LineStyle','--','color',cCPL(1,:),'LineWidth',1.5);
                %     line(tLim,repelem(mp,2)','LineStyle','--','color',cCPL(2,:),'LineWidth',1.5);
                %     line(tLim,repelem(ml,2)','LineStyle','--','color',cCPL(3,:),'LineWidth',1.5);
                plot(sldRe.x.(obj.OutcomeOptions{1}), sldRe.y.(obj.OutcomeOptions(1)),...
                    'o', 'linestyle', '-', 'color', cCPL(1,:), ...
                    'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', cCPL(1,:),...
                    'markeredgecolor', 'w');
                plot(sldRe.x.(obj.OutcomeOptions{2}), sldRe.y.(obj.OutcomeOptions(2)),...
                    'o', 'linestyle', '-', 'color', cCPL(2,:), ...
                    'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', cCPL(2,:),...
                    'markeredgecolor', 'w');
                plot(sldRe.x.(obj.OutcomeOptions{3}), sldRe.y.(obj.OutcomeOptions(3)),...
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
                X = categorical({'Cor','Pre','Late','Dark','Probe'});
                X = reordercats(X,{'Cor','Pre','Late','Dark','Probe'});
                bh = bar(X,[sum(idxCor),sum(idxPre),sum(idxLate),size(obj.Dark,1),size(obj.Probe,1)],...
                    'FaceColor','flat','EdgeColor','none');
                bh.CData(1,:) = cCPL(1,:);
                bh.CData(2,:) = cCPL(2,:);
                bh.CData(3,:) = cCPL(3,:);
                bh.CData(4,:) = [0 0 0];
                bh.CData(5,:) = cBlue;
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
                        
                        HTpdf.P = ksdensity(obj.Probe.HT,edges_HT);
                        HTcdf.P = ksdensity(obj.Probe.HT,edges_HT,'Function','cdf');

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
                        plot(HTpdf.P,edges_HT.*1000,'-.r','LineWidth',1);

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
                        plot(edges_HT.*1000,HTpdf.P,'-.r','lineWidth',1);

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
                        plot(edges_HT.*1000,HTcdf.P,'-.r','lineWidth',1);
                        
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
            
            %% plot session summary for leverpress/release task
            function progFig = plot_leveroperant(obj)
                cTab10 = tab10(10);
                cBlue = cTab10(1,:); cGreen = cTab10(3,:); cDark = [0 0 0];
                set(groot,'defaultAxesFontName','Dejavu Sans');
                tLim = [0 3600]; htLim = [0 2500]; mtLim = [0,3];

                bt = obj.Table;
                
                plotsize1 = [6, 3.5];
                progFig = figure(1); clf(progFig);
                set(progFig, 'unit', 'centimeters', 'position', [2 2 9 10], 'paperpositionmode', 'auto', 'color', 'w');
                
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
            
            %% plot session summary for autoshaping task
            function progFig = plot_autoshaping(obj)
                cTab10 = tab10(10);
                cBlue = cTab10(1,:); cGreen = cTab10(3,:); cDark = [0 0 0];

                set(groot,'defaultAxesFontName','Dejavu Sans');

                qLim = [0.12,6]; % qualified trials criterion
                bt = obj.Table;

                progFig = figure(1); clf(progFig);
                set(progFig, 'unit', 'centimeters', 'position', [2 2 9 10], 'paperpositionmode', 'auto', 'color', 'w')
                
                plotsize1 = [6, 3.5];
                
                tt = obj.DateTime;
                uicontrol(progFig,'Style', 'text', 'units', 'normalized',...
                    'position', [0.17 0.94 0.7 0.05],...
                    'string', append(bt.Subject(1),' / ',char(tt,'yyyy-MM-dd HH:mm:ss')), 'fontweight', 'bold',...
                    'backgroundcolor', [1 1 1]);
                
                % MT-t
                ymax = 60;ymin = 0.1;
                ha1 = axes;
                set(ha1, 'units', 'centimeters', 'position', [1.5 5.5, plotsize1],...
                    'nextplot', 'add', 'ylim', [ymin ymax], 'xlim', [0 3000],...
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
                newOutc(idxInv) = obj.OutcomeOptions{2};
                btn = addvars(bt,newOutc,'NewVariableNames','criOutcome');
            
                fill([0,3000,3000,0],[qLim(1),qLim(1),qLim(2),qLim(2)],cGreen,'EdgeColor','none','FaceAlpha',0.2);
            
                line([bt.TimeElapsed(idxInv),bt.TimeElapsed(idxInv)], [ymin ymin+0.04], 'color',cDark, 'linewidth', 0.4); % invalid trial
                line([bt.TimeElapsed(idxVal),bt.TimeElapsed(idxVal)], [ymin+0.04 ymin+0.1], 'color',cBlue, 'linewidth', 0.4); % valid trial
                line([0 4200],[median(btMT.MT),median(btMT.MT)],'linestyle','--','color',cDark,'linewidth',1.5);
                scatter(btMT.TimeElapsed,btMT.MT,...
                    30, cGreen,'o','Markerfacealpha', 0.9, 'linewidth', 1.1);
                
                text(3000,median(btMT.MT),{'median',sprintf('%.1f(s)',median(btMT.MT))},'FontSize',8);
                text(3000,ymin+0.13,sprintf('Qualif %.0f',sum(strcmp(btn.criOutcome,obj.OutcomeOptions{1}))),'FontSize',8,'color',cBlue.*0.8);
                text(3000,ymin+0.03,sprintf('Unqual %.0f',sum(strcmp(btn.criOutcome,obj.OutcomeOptions{2}))),'FontSize',8);
                
                % sliding performance
                [x1,y1] = calMovAVG(btn.TimeElapsed,btn.Outcome,...
                    'winRatio',6,'stepRatio',3,'tarStr',obj.OutcomeOptions{1});
                [x2,y2] = calMovAVG(btn.TimeElapsed,btn.criOutcome,...
                    'winRatio',6,'stepRatio',3,'tarStr',obj.OutcomeOptions{1});
                ha2 = axes;
                set(ha2, 'units', 'centimeters', 'position', [1.5 1, plotsize1],...
                    'nextplot', 'add', 'ylim', [0 1], 'ytick', [0 0.5 1], 'yticklabel', [0 50 100], ...
                    'xlim', [1 3000],...
                    'yscale', 'linear','tickdir','out');
                xlabel('Time in session (sec)')
                ylabel('Performance (%)')
            
                mperf1 = sum(strcmp(btn.Outcome,obj.OutcomeOptions{1}))./length(btn.Outcome);
                line([0 3000],[mperf1,mperf1],...
                    'linestyle','--','color',cGreen,'linewidth',1.5);
                plot(x1, y1, 'o', 'linestyle', '-', 'color', cGreen, ...
                    'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', cGreen,...
                    'markeredgecolor', 'w');
                text(3000,mperf1,sprintf('mean %.0f%%',mperf1),...
                    'FontSize',8,'color',cGreen.*0.8);
                
                mperf2 = sum(strcmp(btn.criOutcome,obj.OutcomeOptions{1}))./length(btn.criOutcome);
                line([0 3000],[mperf2,mperf2],...
                    'linestyle','--','color',cBlue,'linewidth',1.5);
                plot(x2, y2, 'o', 'linestyle', '-', 'color', cBlue, ...
                    'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', cBlue,...
                    'markeredgecolor', 'w');
                text(3000,mperf1-max([mperf1-mperf2,8]),sprintf('mean %.0f%%',mperf2),...
                    'FontSize',8,'color',cBlue.*0.8);
            end
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
    end
    
end

function out = extractBpodData(filename)
    isAutoShaping = 0;
    load(filename,"SessionData");
    sd = SessionData;
    % get info
    dname = split(string(filename), '_');
    out.Subject = string(dname(1));
    out.Date = str2double(dname(end-1));
    out.DateTime = datetime(sd.Info.SessionStartTime_MATLAB,'convertfrom','datenum');
    out.Task = string(dname(4));
    
    % get trial data
    nTrials = sd.nTrials;
    cellCustom = struct2cell(sd.Custom);
    for i = 1:length(cellCustom)
        if ~isempty(cellCustom{i}) && nTrials > length(cellCustom{i})
            nTrials = length(cellCustom{i});
        end
    end
    out.nTrial = nTrials;

    iTrial = (1:nTrials)';
    MT = sd.Custom.MovementTime(1:nTrials)';
    if isfield(sd.Custom,'ForePeriod')
        if ~isempty(sd.Custom.ForePeriod)
            FP = round(sd.Custom.ForePeriod(1:nTrials),2)';
            RW = sd.Custom.ResponseWindow(1:nTrials)';
        else % Leverpress / release
            FP = nan(nTrials,1);
            RW = nan(nTrials,1);
        end
        RT = sd.Custom.ReactionTime(1:nTrials)';
    else % Autoshaping
        FI = []; isAutoShaping = 1;
        RW = nan(nTrials,1);
        RT = nan(nTrials,1);
    end

    % darkTry = zeros(nTrials, 1);
    darkPress = [];
    HT = zeros(nTrials, 1);
    outcome = sd.Custom.OutcomeCode(1:nTrials)';
    
    TimeElapsed = sd.Custom.TimeElapsed(1:nTrials)'; % start press or poke: wait4tone(1)
    TimeElapsed(TimeElapsed > 1e4) = NaN;
    alterTE = false;
    if isnan(TimeElapsed) % for some special cases
        TimeElapsed = nan(nTrials, 1);
        alterTE = true;
    end
    % get info from rawData
    for i = 1:nTrials
        iStates = sd.RawEvents.Trial{1,i}.States;
        iEvents = sd.RawEvents.Trial{1,i}.Events;
        if exist('FI', 'var')
            FI = [FI; diff(iStates.WaitForLED)]; %#ok<*AGROW>
        end


        if isfield(iStates, 'Wait4Tone')
            if isnan(iStates.Wait4Tone) % HT start time
                if isfield(iStates, 'Delay')
                    HT_ori = iStates.Delay(2);
                else
                    HT_ori = iStates.Wait4Start(2);
                end
            else
                HT_ori = iStates.Wait4Tone(end,1);
            end
            switch outcome(i) % HT
                case 1
                    HT(i) = iStates.Wait4Stop(2) - HT_ori;
                case -1
                    if isfield(iStates, 'GracePeriod')
                        HT(i) = iStates.GracePeriod(end,1) - HT_ori;
                    else
                        HT(i) = iStates.Premature(1) - HT_ori;
                    end
                case -2
                    HT(i) = iStates.LateError(2) - HT_ori;
                case 0
                    if isfield(iStates, 'Probe')
                        HT(i) = diff(iStates.Probe);
                    else
                        HT(i) = NaN;
                    end
                otherwise
                    HT(i) = NaN;
            end
        elseif isfield(iStates, 'WaitForLED') % Autoshaping
            HT_ori = iStates.WaitForLED(2); % tone or poke time
            HT(i) = NaN;
        elseif isfield(iStates, 'Wait4Stop') % Leverpress / Leverrelease
            HT_ori = iStates.Wait4Stop(1);
            timeBNC = {sd.RawEvents.Trial{1,i}.Events.BNC1High, ...
                       sd.RawEvents.Trial{1,i}.Events.BNC1Low};
            if timeBNC{2}(1) <= timeBNC{1}(1)
                timeBNC{2} = timeBNC{2}(2:end);
            end
            if timeBNC{1}(end) >= timeBNC{2}(end)
                timeBNC{1} = timeBNC{1}(1:end-1);
            end
            durBNC = 0;
            for j = 1:length(timeBNC{1})
                dur = timeBNC{2}(j) - timeBNC{1}(j);
                durBNC = durBNC + dur;
                if dur > 0.001
                    break;
                end
            end
            HT(i) = durBNC;
        else
            error('Unspecified conditions');
        end

        if alterTE | isnan(TimeElapsed(i))
            TimeElapsed(i) = sd.TrialStartTimestamp(i) + HT_ori;
        end

        if isfield(iStates, 'TimeOut_reset') % dark try num
            if ~isnan(iStates.TimeOut_reset)
                numDark = size(iStates.TimeOut_reset,1);
                for idark = 1:numDark
                    tPress = iStates.TimeOut(idark,2);
                    tRelease = iEvents.BNC1Low(find(iEvents.BNC1Low-tPress>0.1, 1, "first"));
                    if ~isempty(tRelease)
                        darkPress = [darkPress; i sd.TrialStartTimestamp(i)+tPress tRelease-tPress];
                    end
                end
            end
        end

    end
    if exist('FI', 'var'); FP = FI; end

    % get release time
    RelT = HT - FP;
    RelT(outcome == -1 | outcome == 0) = NaN;
    RelT(RelT > 2) = NaN;
    
    % adjust outcome name
    idxCor = outcome == 1; idxPre = outcome == -1; idxLate = outcome == -2;
    idxZero = outcome == 0;
    outcome = string(outcome);
    outcome(idxCor)  = repelem("Cor",  sum(idxCor)');
    outcome(idxPre)  = repelem("Pre",  sum(idxPre)');
    outcome(idxLate) = repelem("Late", sum(idxLate)');
    if isAutoShaping
        outcome(idxZero) = repelem("Pre", sum(idxZero)'); % Nov/07/2023, mark invalid pokes as premature in autoshaping
    else
        outcome(idxZero) = repelem("Probe", sum(idxZero)');
    end

    % % revised by hbWang, June/24/2024
    % outcome(1) = "Remove";

    tablenames = {'Subject','Group','Experiment','Task', ...
                'Session','Date', 'iTrial','TimeElapsed',...
                'FP','RW','Outcome','HT','RT','MT','RelT'};
    t = table(...
        repelem(out.Subject, nTrials)',...
        repelem(NaN,         nTrials)',...
        repelem(NaN,         nTrials)',...
        repelem(out.Task,    nTrials)',...
        repelem(NaN,         nTrials)',...
        repelem(out.Date,    nTrials)',...
        iTrial, TimeElapsed, FP, RW, outcome, HT, RT, MT, RelT,...
        'VariableNames', tablenames);

    nDark = height(darkPress);
    if nDark > 0
        idxDark = nTrials+1:nTrials+nDark;
        t.iTrial(idxDark) = darkPress(:,1);
        t.TimeElapsed(idxDark) = darkPress(:,2);
        t.HT(idxDark) = darkPress(:,3);
        t.Outcome(idxDark) = "Dark";
    
        t.Subject(idxDark) = out.Subject;
        t.Group(idxDark) = NaN;
        t.Experiment(idxDark) = NaN;
        t.Session(idxDark) = NaN;
        t.RT(idxDark) = NaN;
        t.RelT(idxDark) = NaN;
        t.MT(idxDark) = NaN;
    
        t.Date(idxDark) = out.Date;
        t.Task(idxDark) = out.Task;
        
        for i = idxDark
            it = t.iTrial(i);
            idx = find(t.iTrial == it, 1, "first");
            t.FP(i) = t.FP(idx);
            t.RW(i) = t.RW(idx);
        end
    end
    idxTrial = ismember(t.Outcome, ["Cor", "Pre", "Late"]);
    t.iTrial(~idxTrial) = NaN;
    t.iTrial(idxTrial) = 1:sum(idxTrial);

    iPress = 1:size(t, 1);
    t = sortrows(t, "TimeElapsed");
    t = addvars(t, iPress', 'NewVariableNames', "iPress");

    out.nTrial = sum(idxTrial);
    out.nPress = length(iPress);

    out.TimeElapsed = t.TimeElapsed;
    out.iTrial = t.iTrial;
    out.iPress = t.iPress;
    out.Outcome = t.Outcome;
    out.FP = t.FP;
    out.RW = t.RW;
    out.RT = t.RT;
    out.HT = t.HT;
    out.MT = t.MT;
    out.RelT = t.RelT;
end

function out = extractBpodDataFromMED(in)
    isAutoShaping = 0;
    load(filename,"SessionData");
    sd = SessionData;
    % get info
    dname = split(string(filename), '_');
    out.Subject = string(dname(1));
    out.Date = str2double(dname(end-1));
    out.DateTime = datetime(sd.Info.SessionStartTime_MATLAB,'convertfrom','datenum');
    out.Task = string(dname(4));
    
    % get trial data
    nTrials = sd.nTrials;
    cellCustom = struct2cell(sd.Custom);
    for i = 1:length(cellCustom)
        if ~isempty(cellCustom{i}) && nTrials > length(cellCustom{i})
            nTrials = length(cellCustom{i});
        end
    end
    out.nTrial = nTrials;

    iTrial = (1:nTrials)';
    MT = sd.Custom.MovementTime(1:nTrials)';
    if isfield(sd.Custom,'ForePeriod')
        if ~isempty(sd.Custom.ForePeriod)
            FP = round(sd.Custom.ForePeriod(1:nTrials),2)';
            RW = sd.Custom.ResponseWindow(1:nTrials)';
        else % Leverpress / release
            FP = nan(nTrials,1);
            RW = nan(nTrials,1);
        end
        RT = sd.Custom.ReactionTime(1:nTrials)';
    else % Autoshaping
        FI = []; isAutoShaping = 1;
        RW = nan(nTrials,1);
        RT = nan(nTrials,1);
    end

    % darkTry = zeros(nTrials, 1);
    darkPress = [];
    HT = zeros(nTrials, 1);
    outcome = sd.Custom.OutcomeCode(1:nTrials)';
    
    TimeElapsed = sd.Custom.TimeElapsed(1:nTrials)'; % start press or poke: wait4tone(1)
    TimeElapsed(TimeElapsed > 1e4) = NaN;
    alterTE = false;
    if isnan(TimeElapsed) % for some special cases
        TimeElapsed = nan(nTrials, 1);
        alterTE = true;
    end
    % get info from rawData
    for i = 1:nTrials
        iStates = sd.RawEvents.Trial{1,i}.States;
        iEvents = sd.RawEvents.Trial{1,i}.Events;
        if exist('FI', 'var')
            FI = [FI; diff(iStates.WaitForLED)]; %#ok<*AGROW>
        end


        if isfield(iStates, 'Wait4Tone')
            if isnan(iStates.Wait4Tone) % HT start time
                if isfield(iStates, 'Delay')
                    HT_ori = iStates.Delay(2);
                else
                    HT_ori = iStates.Wait4Start(2);
                end
            else
                HT_ori = iStates.Wait4Tone(end,1);
            end
            switch outcome(i) % HT
                case 1
                    HT(i) = iStates.Wait4Stop(2) - HT_ori;
                case -1
                    if isfield(iStates, 'GracePeriod')
                        HT(i) = iStates.GracePeriod(end,1) - HT_ori;
                    else
                        HT(i) = iStates.Premature(1) - HT_ori;
                    end
                case -2
                    HT(i) = iStates.LateError(2) - HT_ori;
                case 0
                    if isfield(iStates, 'Probe')
                        HT(i) = diff(iStates.Probe);
                    else
                        HT(i) = NaN;
                    end
                otherwise
                    HT(i) = NaN;
            end
        elseif isfield(iStates, 'WaitForLED') % Autoshaping
            HT_ori = iStates.WaitForLED(2); % tone or poke time
            HT(i) = NaN;
        elseif isfield(iStates, 'Wait4Stop') % Leverpress / Leverrelease
            HT_ori = iStates.Wait4Stop(1);
            timeBNC = {sd.RawEvents.Trial{1,i}.Events.BNC1High, ...
                       sd.RawEvents.Trial{1,i}.Events.BNC1Low};
            if timeBNC{2}(1) <= timeBNC{1}(1)
                timeBNC{2} = timeBNC{2}(2:end);
            end
            if timeBNC{1}(end) >= timeBNC{2}(end)
                timeBNC{1} = timeBNC{1}(1:end-1);
            end
            durBNC = 0;
            for j = 1:length(timeBNC{1})
                dur = timeBNC{2}(j) - timeBNC{1}(j);
                durBNC = durBNC + dur;
                if dur > 0.001
                    break;
                end
            end
            HT(i) = durBNC;
        else
            error('Unspecified conditions');
        end

        if alterTE | isnan(TimeElapsed(i))
            TimeElapsed(i) = sd.TrialStartTimestamp(i) + HT_ori;
        end

        if isfield(iStates, 'TimeOut_reset') % dark try num
            if ~isnan(iStates.TimeOut_reset)
                numDark = size(iStates.TimeOut_reset,1);
                for idark = 1:numDark
                    tPress = iStates.TimeOut(idark,2);
                    tRelease = iEvents.BNC1Low(find(iEvents.BNC1Low-tPress>0.1, 1, "first"));
                    if ~isempty(tRelease)
                        darkPress = [darkPress; i sd.TrialStartTimestamp(i)+tPress tRelease-tPress];
                    end
                end
            end
        end

    end
    if exist('FI', 'var'); FP = FI; end

    % get release time
    RelT = HT - FP;
    RelT(outcome == -1 | outcome == 0) = NaN;
    RelT(RelT > 2) = NaN;
    
    % adjust outcome name
    idxCor = outcome == 1; idxPre = outcome == -1; idxLate = outcome == -2;
    idxZero = outcome == 0;
    outcome = string(outcome);
    outcome(idxCor)  = repelem("Cor",  sum(idxCor)');
    outcome(idxPre)  = repelem("Pre",  sum(idxPre)');
    outcome(idxLate) = repelem("Late", sum(idxLate)');
    if isAutoShaping
        outcome(idxZero) = repelem("Pre", sum(idxZero)'); % Nov/07/2023, mark invalid pokes as premature in autoshaping
    else
        outcome(idxZero) = repelem("Probe", sum(idxZero)');
    end

    % % revised by hbWang, June/24/2024
    % outcome(1) = "Remove";

    tablenames = {'Subject','Group','Experiment','Task', ...
                'Session','Date', 'iTrial','TimeElapsed',...
                'FP','RW','Outcome','HT','RT','MT','RelT'};
    t = table(...
        repelem(out.Subject, nTrials)',...
        repelem(NaN,         nTrials)',...
        repelem(NaN,         nTrials)',...
        repelem(out.Task,    nTrials)',...
        repelem(NaN,         nTrials)',...
        repelem(out.Date,    nTrials)',...
        iTrial, TimeElapsed, FP, RW, outcome, HT, RT, MT, RelT,...
        'VariableNames', tablenames);

    nDark = height(darkPress);
    if nDark > 0
        idxDark = nTrials+1:nTrials+nDark;
        t.iTrial(idxDark) = darkPress(:,1);
        t.TimeElapsed(idxDark) = darkPress(:,2);
        t.HT(idxDark) = darkPress(:,3);
        t.Outcome(idxDark) = "Dark";
    
        t.Subject(idxDark) = out.Subject;
        t.Group(idxDark) = NaN;
        t.Experiment(idxDark) = NaN;
        t.Session(idxDark) = NaN;
        t.RT(idxDark) = NaN;
        t.RelT(idxDark) = NaN;
        t.MT(idxDark) = NaN;
    
        t.Date(idxDark) = out.Date;
        t.Task(idxDark) = out.Task;
        
        for i = idxDark
            it = t.iTrial(i);
            idx = find(t.iTrial == it, 1, "first");
            t.FP(i) = t.FP(idx);
            t.RW(i) = t.RW(idx);
        end
    end
    idxTrial = ismember(t.Outcome, ["Cor", "Pre", "Late"]);
    t.iTrial(~idxTrial) = NaN;
    t.iTrial(idxTrial) = 1:sum(idxTrial);

    iPress = 1:size(t, 1);
    t = sortrows(t, "TimeElapsed");
    t = addvars(t, iPress', 'NewVariableNames', "iPress");

    out.nTrial = sum(idxTrial);
    out.nPress = length(iPress);

    out.TimeElapsed = t.TimeElapsed;
    out.iTrial = t.iTrial;
    out.iPress = t.iPress;
    out.Outcome = t.Outcome;
    out.FP = t.FP;
    out.RW = t.RW;
    out.RT = t.RT;
    out.HT = t.HT;
    out.MT = t.MT;
    out.RelT = t.RelT;
end