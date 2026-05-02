classdef BehaviorKB
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
        Subject           string  % subject name
        Group             string  % between-group variable (hM3Dq/ChR2, Lesion/Sham)
        Experiment        string  % within-group variable (Saline/DCZ, PreLesion/PostLesion) 
        Session           double = NaN            % e.g., 3 (manual)
        Date              double                  % YYYYMMDD
        Meta              struct
        nTrial            double                  % trial number in this session
        iTrial      (:,1) double                  % index of each trial
        TimeElapsed (:,1) double                  % sec, start time of iTrial
        Cue         (:,1) string                  % "Cue" "Uncue"
        FP          (:,1) double                  % sec, foreperiod
        RW          (:,1) double                  % sec, response window
        HT          (:,1) double                  % sec, hold time
        RT          (:,1) double                  % sec, reaction time
        MT          (:,1) double                  % sec, movement time
        Outcome     (:,1) string                  % "Cor" "Pre" "Late"
        DarkTry     (:,1) double                  % dark press number of each trial
    end

    properties (Dependent)
        Task              string % KB+FP+CueRatio (e.g. KB1000Cue50)
        RelT        (:,1) double
        Table             table
        Performance       table
        AvgRT             table
    end
    
    properties (Dependent, GetAccess = private)
        SaveName
    end

    properties (Constant, GetAccess = private)
        OutcomeOptions = ["Cor", "Pre", "Late"] % 1 - Correct, -1 - Premature, -2 - Late
        CueOptions     = ["Cue", "Uncue"]       % 1 - Cue, 0 - Uncue
        MergeMethod    = ["Merge", "Selecgt"]
        RTOptions      = ["Cor", "CorLate"]
    end

    methods
        function obj = BehaviorKB(filename)
            % e.g., filename = 'Strangelove_DSRT_06_3FPs_20221115_151443.mat';
            % Construct an instance of this class
            switch class(filename)
                case 'struct'
                    datain = filename;
                otherwise
                    mustBeFile(filename);
                    datain = extractBpodDataKB(filename);
            end
            fields = fieldnames(datain);
            for iField = 1:length(fields)
                field = fields{iField};
                obj.(field) = datain.(field);
            end
        end

        function value = get.SaveName(obj)
            value = "BClass_"+upper(obj.Subject)+"_"+string(obj.Meta.DateTime,'yyyyMMdd_HHmmss');
        end
        
        function value = get.Task(obj)
            value = ("KB"+num2str(obj.Meta.FP*1000)+"Cue"+num2str(obj.Meta.CueRatio*100));
        end

        function value = get.RelT(obj)
            value = obj.HT - obj.FP;
            value(obj.Outcome == obj.OutcomeOptions(2)) = NaN;
            value(value > 6) = NaN;
        end

        function value = get.Table(obj)
            tablenames = {'Subject','Group','Experiment','Task', ...
                'Session','Date','iTrial','TimeElapsed','Cue',...
                'FP','RW','DarkTry','Outcome','HT','RT','MT','RelT'};
            value = table(...
                repelem(string(obj.Subject),obj.nTrial)',...
                repelem(string(obj.Group),obj.nTrial)',...
                repelem(string(obj.Experiment),obj.nTrial)',...
                repelem(string(obj.Task),obj.nTrial)',...
                repelem(obj.Session,obj.nTrial)',...
                repelem(obj.Date,obj.nTrial)',...
                obj.iTrial,obj.TimeElapsed,obj.Cue,...
                obj.FP,obj.RW,obj.DarkTry,obj.Outcome,obj.HT,...
                obj.RT,obj.MT,obj.RelT,...
                'VariableNames',tablenames);
        end

        function value = get.Performance(obj)

            nCueType  = length(obj.CueOptions);
            N_press   = zeros(nCueType+1, 1);
            ratioCor  = zeros(nCueType+1, 1);
            ratioPre  = zeros(nCueType+1, 1);
            ratioLate = zeros(nCueType+1, 1);

            idxCor  = obj.Outcome == obj.OutcomeOptions(1);
            idxPre  = obj.Outcome == obj.OutcomeOptions(2);
            idxLate = obj.Outcome == obj.OutcomeOptions(3);
            
            nCor  = sum(idxCor); nPre = sum(idxPre); nLate = sum(idxLate);

            for i = 1:nCueType
                idxCueOrUncue = obj.Cue == obj.CueOptions(i);

                inCor  = sum(idxCueOrUncue & idxCor);
                inPre  = sum(idxCueOrUncue & idxPre);
                inLate = sum(idxCueOrUncue & idxLate);
                inPerfAll = inCor + inPre + inLate;
                N_press(i) = inPerfAll;

                ratioCor(i)  = 100*inCor/inPerfAll;
                ratioPre(i)  = 100*inPre/inPerfAll;
                ratioLate(i) = 100*inLate/inPerfAll;
            end

            i = i+1;

            nPerfAll = nCor + nPre + nLate;
            N_press(i)   = nPerfAll;
            ratioCor(i)  = 100*nCor/nPerfAll;
            ratioPre(i)  = 100*nPre/nPerfAll;
            ratioLate(i) = 100*nLate/nPerfAll;
            rt_table = table([obj.CueOptions';"All"], N_press, ratioCor, ratioPre, ratioLate);
            value = rt_table;
        end

        function value = get.AvgRT(obj)
            % Use calRT to compute RT
            rt.median   = []; rt.median_ksdensity = [];
            relt.median = []; relt.median_ksdensity = [];

            nCueType = length(obj.CueOptions);
            nCor = zeros(nCueType+1, 1);
            nCorLate = zeros(nCueType+1, 1);
            
            idxCor = obj.Outcome == obj.OutcomeOptions(1);
            idxCorLate = obj.Outcome == obj.OutcomeOptions(1) | obj.Outcome == obj.OutcomeOptions(3);

            for i = 1:nCueType
                idxCueOrUncue = obj.Cue == obj.CueOptions(i);

                iHT_Cor = obj.HT(idxCueOrUncue & idxCor);
                iFP_Cor = obj.FP(idxCueOrUncue & idxCor);
                iRT_Cor = calRT(iHT_Cor, iFP_Cor, 'Remove100ms', 0, ...
                    'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
                nCor(i) = length(iHT_Cor);
                rt.median(i)           = iRT_Cor.median;
                rt.median_ksdensity(i) = iRT_Cor.median_ksdensity;

                iHT_CorLate = obj.HT(idxCueOrUncue & idxCorLate);
                iFP_CorLate = obj.FP(idxCueOrUncue & idxCorLate);
                iRT_CorLate = calRT(iHT_CorLate, iFP_CorLate, 'Remove100ms', 0, ...
                    'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
                nCorLate(i) = length(iHT_CorLate);
                relt.median(i)           = iRT_CorLate.median;
                relt.median_ksdensity(i) = iRT_CorLate.median_ksdensity;
            end

            i = i+1;

            FP_Cor  = obj.FP(idxCor);
            HT_Cor  = obj.HT(idxCor); % turn it into ms
            iRT_Cor = calRT(HT_Cor, FP_Cor, 'Remove100ms', 0, ...
                'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
            nCor(i) = length(HT_Cor);
            rt.median(i)  = iRT_Cor.median;
            rt.median_ksdensity(i) = iRT_Cor.median_ksdensity;

            FP_CorLate  = obj.FP(idxCorLate);
            HT_CorLate  = obj.HT(idxCorLate); % turn it into ms
            iRT_CorLate = calRT(HT_CorLate, FP_CorLate, 'Remove100ms', 0, ...
                'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
            nCorLate(i) = length(HT_CorLate);
            relt.median(i)    = iRT_CorLate.median;
            relt.median_ksdensity(i) = iRT_CorLate.median_ksdensity;

            CueLabel = [obj.CueOptions';"All"];
            medianRT   = rt.median';   medianRT_ks   = rt.median_ksdensity'; 
            medianRelT = relt.median'; medianRelT_ks = rt.median_ksdensity';

            value = table(CueLabel, nCor, medianRT, medianRT_ks, ...
                nCorLate, medianRelT, medianRelT_ks);
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
            out.x = table; out.y = table;
            out.options = options;
            for j = 1:length(obj.CueOptions)
                out.("x"+obj.CueOptions(j)) = table;
                out.("y"+obj.CueOptions(j)) = table;
            end

            for i = 1:length(options.tarStr)
                switch targetVar
                    case "RT"
                        if options.tarStr(i) == "Cor"
                            tarVarData = obj.Table.RT;
                        elseif options.tarStr(i) == "CorLate"
                            tarVarData = obj.Table.RelT;
                        else
                            error("Check input 'tarStr' in calProgress('RT')");
                        end
                    case "Outcome"
                        tarVarData = obj.Table.Outcome;
                end
                [x,y] = calMovAVG(obj.Table.TimeElapsed,tarVarData,...
                    'winRatio',options.winRatio,'stepRatio',options.stepRatio,...
                    'winSize',options.winSize,'stepSize',options.stepSize,...
                    'tarStr',options.tarStr(i),'avgMethod',options.avgMethod);
                out.x = addvars(out.x,x,'NewVariableNames',options.tarStr(i));
                out.y = addvars(out.y,y,'NewVariableNames',options.tarStr(i));
                for j = 1:length(obj.CueOptions)
                    jCue = obj.CueOptions(j);
                    [x,y] = calMovAVG(obj.Table.TimeElapsed(obj.Table.Cue == jCue),...
                        tarVarData(obj.Table.Cue == jCue),...
                        'winRatio',options.winRatio,'stepRatio',options.stepRatio,...
                        'winSize',options.winSize,'stepSize',options.stepSize,...
                        'tarStr',options.tarStr(i),'avgMethod',options.avgMethod);
                    out.("x"+jCue) = addvars(out.("x"+jCue),x,'NewVariableNames',options.tarStr(i));
                    out.("y"+jCue) = addvars(out.("y"+jCue),y,'NewVariableNames',options.tarStr(i));
                end
            end
        end

        function [objOut,isMerge] = merge(obj,objNew,method,just1Day)
            arguments
                obj
                objNew BehaviorKB
                method string {mustBeMember(method, ["Merge", "Select"])} = "Merge"
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
            if method == "Select" % select the bigger data (more trials)
                if obj.nTrial < objNew.nTrial
                    objOut = objNew;
                end
                isMerge = true;
                return
            end
            % Merge method
            diffTime = minus(obj.Meta.DateTime,objNew.Meta.DateTime);
            diffSec = abs(seconds(diffTime)); % when isNewEarly==true, diffSec>0
            if diffTime > 0
                isNewEarly = true;
            else
                isNewEarly = false;
            end
            objOut = obj;
            if isNewEarly
                objOut.Date = objNew.Date;
                objOut.Meta = objNew.Meta;
                objOut.nTrial = obj.nTrial + objNew.nTrial;
                objOut.iTrial = (1:objOut.nTrial)';
                objOut.Cue = [objNew.Cue(:);obj.Cue(:)];
                objOut.TimeElapsed = [objNew.TimeElapsed(:);(obj.TimeElapsed(:)+diffSec)];
                objOut.FP = [objNew.FP(:);obj.FP(:)];
                objOut.RW = [objNew.RW(:);obj.RW(:)];
                objOut.DarkTry = [objNew.DarkTry(:);obj.DarkTry(:)];
                objOut.Outcome = [objNew.Outcome(:);obj.Outcome(:)];
                objOut.HT = [objNew.HT(:);obj.HT(:)];
                objOut.RT = [objNew.RT(:);obj.RT(:)];
                objOut.MT = [objNew.MT(:);obj.MT(:)];
            else
                objOut.Date = obj.Date;
                objOut.Meta = obj.Meta;
                objOut.nTrial = obj.nTrial + objNew.nTrial;
                objOut.iTrial = (1:objOut.nTrial)';
                objOut.Cue = [obj.Cue(:);objNew.Cue(:)];
                objOut.TimeElapsed = [obj.TimeElapsed(:);(objNew.TimeElapsed(:)+diffSec)];
                objOut.FP = [obj.FP(:);objNew.FP(:)];
                objOut.RW = [obj.RW(:);objNew.RW(:)];
                objOut.DarkTry = [obj.DarkTry(:);objNew.DarkTry(:)];
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
            save(fullfile(savepath,obj.SaveName), "obj");
            writetable(obj.Table,fullfile(savepath,obj.SaveName+".csv"));
        end

        function Fig = plot(obj)
            
            bt = obj.Table;
            fp = obj.Meta.FP;

            cTab10 = tab10(10);
            cBlue = cTab10(1,:); cGreen  = cTab10(3,:); cRed = cTab10(4,:);
            cPurple = cTab10(5,:); cGray = cTab10(8,:);
            cCPL = [cGreen;cRed;cGray];
            cCue = 'k'; cUncue = cPurple;

            fontSize = struct("Axes", 7, "Label", 9, "Title", 10);
            tickLen = [0.0200 0.0250];

            xstart = 1.5; ystart = 1.3; xgap = 0.5; ygap = 0.6;
            axeSize1 = [6 4];           % size of HT-time etc.
            axeSize2 = [2 axeSize1(2)]; % size of pdf
            yInfo    = 2;               % height of session info
            axeSize3 = [(axeSize1(1)+axeSize2(1)-4*xgap)/2 (axeSize1(2)+yInfo)/2]; % size of cdf etc.

            xmap = [xstart, ...                                        % col 1: Cue (RT, HT) and Progress perf
                    xstart + xgap*1 + axeSize1(1), ...                 % col 2: Uncue (RT, HT) and Performance hist
                    xstart + xgap*2 + axeSize1(1)*2, ...               % col 3: PDF
                    xstart + xgap*3 + axeSize1(1)*2 + axeSize2(1)];    % end
            xmap2 = [xstart, ...                                       % col 1: Progress
                     xstart + xgap*3 + axeSize1(1), ...                % col 2: Performance
                     xstart + xgap*6 + axeSize1(1) + axeSize3(1)];     % col 3: CDF

            ymap = [ystart, ...                                        % row -1: RT / PDF
                    ystart + ygap*1 + axeSize1(2), ...                 % row -2: HT / PDF
                    ystart + ygap*4 + axeSize1(2)*2, ...               % row -3: Performance / CDF
                    ystart + ygap*6 + axeSize1(2)*2 + axeSize3(2), ... % row -4: Performance / CDF row2
                    ystart + ygap*6 + axeSize1(2)*3, ...               % row -5: Session info
                    ystart + ygap*7 + axeSize1(2)*3 + yInfo];          % end

            tLim     = [0 3100];
            htLim    = [0 3.3];
            reltLim  = [0 1.0];
            reltLim2 = [0 2.0];

            yTick.HT = htLim(1):0.5:htLim(2);
            yTickLabel.HT = num2str(yTick.HT' * 1000);

            yTick.RelT = reltLim(1):0.2:reltLim(2);
            yTickLabel.RelT = num2str(yTick.RelT' * 1000);

            idxCue   = bt.Cue     == obj.CueOptions(1);
            idxUncue = bt.Cue     == obj.CueOptions(2);
            idxCor   = bt.Outcome == obj.OutcomeOptions(1);
            idxPre   = bt.Outcome == obj.OutcomeOptions(2);
            idxLate  = bt.Outcome == obj.OutcomeOptions(3);
            RW_Cue   = unique(bt.RW(idxCue, :));
            RW_Uncue = unique(bt.RW(idxUncue, :));

            Fig = figure(1); clf(Fig, "reset");
            set(Fig, 'unit', 'centimeters', 'paperpositionmode', 'auto', ...
                'position', [2 2 xmap(end) ymap(end)], 'color', 'w');

            modHT   = bt.HT;   modHT(modHT > htLim(2)) = htLim(2);
            modRelT = bt.RelT; % modRelT(modRelT > reltLim(2)) = reltLim(2);
            TE = bt.TimeElapsed;

            % HT - Time - Cue
            ha11 = axes;
            set(ha11, "Units", "centimeters", "Position", [xmap(1) ymap(1), axeSize1],...
                "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                "XLim", tLim, "YLim", htLim, "YTick", yTick.HT, "YTickLabel", yTickLabel.HT, ...
                "FontSize", fontSize.Axes, "FontName", "Arial");
            xlabel("Time in session (sec)", "FontSize", fontSize.Label, "FontName", "Arial");
            ylabel("Hold duration (ms)", "FontSize", fontSize.Label, "FontName", "Arial", "FontWeight", "bold");

            line([TE(idxCue), TE(idxCue)], [htLim(1),htLim(1)+diff(htLim)/10],...
                'color', cBlue, 'linewidth', 0.4);
            fill([tLim(1) tLim(2) tLim(2) tLim(1)], fp+[0 0 RW_Cue RW_Cue],...
                cBlue, 'FaceAlpha', 0.1, 'EdgeColor', 'none');

            scatter(TE(idxCue & idxCor), modHT(idxCue & idxCor), 30, cCPL(1,:), ...
                'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.6);
            scatter(TE(idxCue & idxPre), modHT(idxCue & idxPre), 30, cCPL(2,:),...
                'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.6);
            scatter(TE(idxCue & idxLate), modHT(idxCue & idxLate), 30, cCPL(3,:),...
                'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.6);

            % HT - Time - Uncue
            ha12 = axes;
            set(ha12, "Units", "centimeters", "Position", [xmap(2) ymap(1), axeSize1],...
                "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                "XLim", tLim, "YLim", htLim, "YTick", ha11.YTick, "YTickLabel", {}, ...
                "FontSize", fontSize.Axes, "FontName", "Arial");
            xlabel("Time in session (sec)", "FontSize", fontSize.Label, "FontName", "Arial");
            ha12.YAxis.Visible = "off";

            line([TE(idxUncue), TE(idxUncue)], [htLim(1),htLim(1)+diff(htLim)/10], ...
                'color', cBlue, 'linewidth', 0.4);
            fill([tLim(1) tLim(2) tLim(2) tLim(1)], fp+[0 0 RW_Uncue RW_Uncue],...
                cBlue, 'FaceAlpha', 0.1, 'EdgeColor', 'none');
            
            scatter(TE(idxUncue & idxCor), modHT(idxUncue & idxCor), 30, cCPL(1,:), ...
                'MarkerEdgeAlpha', 0.6, 'LineWidth', 1.5);
            scatter(TE(idxUncue & idxPre), modHT(idxUncue & idxPre), 30, cCPL(2,:), ...
                'MarkerEdgeAlpha', 0.6, 'LineWidth', 1.5);
            scatter(TE(idxUncue & idxLate), modHT(idxUncue & idxLate), 30, cCPL(3,:), ...
                'MarkerEdgeAlpha', 0.6, 'LineWidth', 1.5);

            % HT pdf
            edges_HT   = 0:0.05:htLim(2);
            HTpdfCue   = ksdensity(bt.HT(idxCue),   edges_HT);
            HTpdfUncue = ksdensity(bt.HT(idxUncue), edges_HT);
            HTcdfCue   = ksdensity(bt.HT(idxCue),   edges_HT, 'Function', 'cdf');
            HTcdfUncue = ksdensity(bt.HT(idxUncue), edges_HT, 'Function', 'cdf');

            ha13 = axes;
            set(ha13, "Units", "centimeters", "Position", [xmap(3) ymap(1), axeSize2],...
                "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                "YLim", htLim, "YTick", ha11.YTick, "YTickLabel", {}, ...
                "FontSize", fontSize.Axes, "FontName", "Arial");
            xlabel("PDF (s^{-1})", "FontSize", fontSize.Label, "FontName", "Arial");

            plot(HTpdfCue, edges_HT, 'Color', cCue, 'LineStyle', '-', 'LineWidth', 1.5);
            plot(HTpdfUncue, edges_HT, 'Color', cUncue, 'LineStyle', '-', 'LineWidth', 2);
            line(ha13.XLim, [fp fp],'LineStyle', '--', 'color', cBlue, 'linewidth', 1.3);

            ha33 = axes;
            set(ha33, "Units", "centimeters", "Position", [xmap2(3) ymap(3) axeSize3],...
                "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                "XLim", htLim, "XTick", 0:1:htLim(2), ...
                "YLim", [0 1], "YTick", [0 0.5 1], ...
                "FontSize", fontSize.Axes, "FontName", "Arial");
            xlabel("Hold duration (s)", "FontSize", fontSize.Label, "FontName", "Arial");
            ylabel("CDF", "FontSize", fontSize.Label, "FontName", "Arial");

            plot(edges_HT, HTcdfCue, 'Color', cCue, 'LineStyle', '-', 'LineWidth', 1.5);
            plot(edges_HT, HTcdfUncue, 'Color', cUncue, 'LineStyle', '-', 'LineWidth', 2);
            line([fp fp], ha33.YLim, 'LineStyle', '--', 'color', cBlue, 'linewidth', 1.3);

            % RelT - Time - Cue
            ha21 = axes;
            set(ha21, "Units", "centimeters", "Position", [xmap(1) ymap(2), axeSize1],...
                "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                "XLim", tLim, "XTickLabel", {}, ...
                "YLim", reltLim, "YTick", yTick.RelT, "YTickLabel", yTickLabel.RelT, ...
                "FontSize", fontSize.Axes, "FontName", "Arial");
%             xlabel("Time in session (sec)", "FontSize", fontSize.Label, "FontName", "Arial");
            ylabel("Release time (ms)", "FontSize", fontSize.Label, "FontName", "Arial", "FontWeight", "bold");
            title("Cue trials", "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");

            scatter(TE(idxCue & idxCor), modRelT(idxCue & idxCor), 30, cCPL(1,:), ...
                'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.6);
            scatter(TE(idxCue & idxLate), modRelT(idxCue & idxLate), 30, cCPL(3,:),...
                'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.6);

            % RelT - Time - Uncue
            ha22 = axes;
            set(ha22, "Units", "centimeters", "Position", [xmap(2) ymap(2), axeSize1],...
                "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                "XLim", tLim, "XTickLabel", {}, ...
                "YLim", reltLim, "YTick", ha21.YTick, "YTickLabel", {}, ...
                "FontSize", fontSize.Axes, "FontName", "Arial");
            ha22.YAxis.Visible = "off";
%             xlabel("Time in session (sec)", "FontSize", fontSize.Label, "FontName", "Arial");
            title("Uncue trials", "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");

            scatter(TE(idxUncue & idxCor), modRelT(idxUncue & idxCor), 30, cCPL(1,:), ...
                'MarkerEdgeAlpha', 0.6, 'LineWidth', 1.5);
            scatter(TE(idxUncue & idxLate), modRelT(idxUncue & idxLate), 30, cCPL(3,:), ...
                'MarkerEdgeAlpha', 0.6, 'LineWidth', 1.5);

            % RelT pdf
            edges_RelT   = 0:0.02:reltLim2(2);
            RelTpdfCue   = ksdensity(bt.RelT(idxCue),   edges_RelT);
            RelTpdfUncue = ksdensity(bt.RelT(idxUncue), edges_RelT);
            RelTcdfCue   = ksdensity(bt.RelT(idxCue),   edges_RelT, 'Function', 'cdf');
            RelTcdfUncue = ksdensity(bt.RelT(idxUncue), edges_RelT, 'Function', 'cdf');

            ha23 = axes;
            set(ha23, "Units", "centimeters", "Position", [xmap(3) ymap(2) axeSize2],...
                "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                "YLim", reltLim, "YTick", ha21.YTick, "YTickLabel", {}, ...
                "FontSize", fontSize.Axes, "FontName", "Arial");
            title("PDF", "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");

            plot(RelTpdfCue, edges_RelT, 'Color', cCue, 'LineStyle', '-', 'LineWidth', 1.5);
            plot(RelTpdfUncue, edges_RelT, 'Color', cUncue, 'LineStyle', '-', 'LineWidth', 2);
            lepdf = legend(obj.CueOptions, "FontSize", fontSize.Label, "FontName", "Arial");
            set(lepdf, "Units", "centimeters", "NumColumns", 1, ...
                "Position", [xmap(3)+axeSize3(1)/3 ymap(2)+axeSize2(2)*3/4 1 1]);
            lepdf.ItemTokenSize = [12,15]; legend('boxoff');

            ha43 = axes;
            set(ha43, "Units", "centimeters", "Position", [xmap2(3) ymap(4), axeSize3],...
                "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                "XLim", reltLim2, "XTick", 0:1:reltLim2(2), ...
                "YLim", [0 1], "YTick", [0 0.5 1], ...
                "FontSize", fontSize.Axes, "FontName", "Arial");
            xlabel("Release time (s)", "FontSize", fontSize.Label, "FontName", "Arial");
            ylabel("CDF", "FontSize", fontSize.Label, "FontName", "Arial");

            plot(edges_RelT, RelTcdfCue, 'Color', cCue, 'LineStyle', '-', 'LineWidth', 1.5);
            plot(edges_RelT, RelTcdfUncue, 'Color', cUncue, 'LineStyle', '-', 'LineWidth', 2);
            lecdf = legend(obj.CueOptions, "FontSize", fontSize.Label, "FontName", "Arial");
            set(lecdf, "Units", "centimeters", "NumColumns", 1, ...
                "Position", [xmap2(3)+axeSize3(1)*2/3 ymap(4)+0.2 1 1]);
            lecdf.ItemTokenSize = [12,15]; legend('boxoff');

            % Sliding Performance - Time
            prgPerf = obj.calProgress("Outcome", 'tarStr', obj.OutcomeOptions,...
                'avgMethod','mean','slidingMethod','ratio','winRatio',8,'stepRatio',2);
            ha31 = axes;
            set(ha31, "Units", "centimeters", "Position", [xmap2(1) ymap(3), axeSize1],...
                "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                "XLim", tLim, "YLim", [0 1], "YTick", 0:0.2:1, "YTickLabel", num2str((0:20:100)'), ...
                "FontSize", fontSize.Axes, "FontName", "Arial");
            xlabel('Time in session (sec)','FontSize',fontSize.Label);
            ylabel('Performance (%)','FontSize',fontSize.Label);

            for i = 1:length(obj.CueOptions)
                iCue = obj.CueOptions(i);
                for j = 1:length(obj.OutcomeOptions)
                    if iCue == "Cue"
                        mfColor = cCPL(j,:); mkSize = 5;
                    else
                        mfColor = 'none'; mkSize = 7;
                    end
                    jOutcome = obj.OutcomeOptions(j);
                    pl.("pl"+num2str(i)+num2str(j)) = plot(prgPerf.("x"+iCue).(jOutcome), prgPerf.("y"+iCue).(jOutcome),...
                        'o', 'linestyle', '-', 'linewidth', 1.2, 'color', cCPL(j,:), ...
                        'markersize', mkSize, 'markerfacecolor', mfColor, 'markeredgecolor', cCPL(j,:));
                end
            end
            % pl.pl00 is just a copy of cue-cor first dot, make it easier to plot legend
            pl.pl00 = plot(prgPerf.xCue.Cor(1), prgPerf.yCue.Cor(1),...
                        'o', 'linestyle', '-', 'linewidth', 1.2, 'color', cCPL(1,:), ...
                        'markersize', 5, 'markerfacecolor', cCPL(1,:), 'markeredgecolor', cCPL(1,:));
            
            le1 = legend([pl.pl00 pl.pl21], obj.CueOptions', "NumColumns", 2, ...
                "FontSize", fontSize.Label, "FontName", "Arial", "FontWeight", "bold");
            le1.ItemTokenSize = [12,15]; legend('boxoff');
            set(le1, "Units", "centimeters", 'Position',[xmap2(1) ymap(4)+ygap/2 axeSize1(1) 1]);

            ha31_copy = axes("Position", get(ha31, "Position"), "Visible", "off");
            le2 = legend(ha31_copy, [pl.pl11 pl.pl12 pl.pl13], obj.OutcomeOptions, ...
                "FontSize", fontSize.Label, "FontName", "Arial", "NumColumns", 3);
            le2.ItemTokenSize = [12,15]; legend('boxoff');
            set(le2, "Units", "centimeters", 'Position',[xmap2(1) ymap(4)-ygap/2 axeSize1(1) 1]);

            % Num of Outcome
            ha32 = axes;
            set(ha32, "Units", "centimeters", "Position", [xmap2(2) ymap(3), axeSize3],...
                "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                "XLim", [0.2 7.8], "XTick", [2 6], "XTickLabel", ["Cue", "Uncue"], ...
                "FontSize", fontSize.Axes, "FontName", "Arial");
            ylabel("Number", "FontSize", fontSize.Label, "FontName", "Arial");
            bardataNum = [sum(idxCor & idxCue), sum(idxPre & idxCue), sum(idxLate & idxCue), ...
                sum(idxCor & idxUncue), sum(idxPre & idxUncue), sum(idxLate & idxUncue)];
            xdata = [1 2 3 5 6 7];
            for i = 1:6
                cBar = [cCPL; cCPL];
                hbnum.("b"+num2str(i)) = bar(ha32, xdata(i), bardataNum(i));
                if i <= 3
                    set(hbnum.("b"+num2str(i)), "EdgeColor", "none", "FaceColor", cBar(i,:), "LineWidth", 1);
                else
                    set(hbnum.("b"+num2str(i)), "EdgeColor", cBar(i,:), "FaceColor", "none", "LineWidth", 2);
                end
                text(hbnum.("b"+num2str(i)).XEndPoints, hbnum.("b"+num2str(i)).YEndPoints, ...
                    string(hbnum.("b"+num2str(i)).YData), ...
                    "HorizontalAlignment", "center", "VerticalAlignment", "bottom", ...
                    "FontSize", fontSize.Axes, "FontWeight", "normal", "FontName", "Arial");
            end

            % Performance
            ha42 = axes;
            set(ha42, "Units", "centimeters", "Position", [xmap2(2) ymap(4), axeSize3],...
                "NextPlot", "add", "TickDir", "out", "TickLength", tickLen,...
                "XLim", [0.2 7.8], "XTick", [2 6], "XTickLabel", ["Cue", "Uncue"], ...
                "YLim", [0 1], "YTick", 0:0.2:1, "YTickLabel", num2str((0:20:100)'), ...
                "FontSize", fontSize.Axes, "FontName", "Arial");
            ylabel("Performance (%)", "FontSize", fontSize.Label, "FontName", "Arial");

            bardataPerf = [sum(idxCue & idxCor)/sum(idxCue), sum(idxCue & idxPre)/sum(idxCue), ...
                       sum(idxCue & idxLate)/sum(idxCue), sum(idxUncue & idxCor)/sum(idxUncue), ...
                       sum(idxUncue & idxPre)/sum(idxUncue), sum(idxUncue & idxLate)/sum(idxUncue)];
            for i = 1:6
                cBar = [cCPL; cCPL];
                hbperf.("b"+num2str(i)) = bar(ha42, xdata(i), bardataPerf(i));
                if i <= 3
                    set(hbperf.("b"+num2str(i)), "EdgeColor", "none", "FaceColor", cBar(i,:), "LineWidth", 1);
                else
                    set(hbperf.("b"+num2str(i)), "EdgeColor", cBar(i,:), "FaceColor", "none", "LineWidth", 2);
                end
                text(hbperf.("b"+num2str(i)).XEndPoints, hbperf.("b"+num2str(i)).YEndPoints, ...
                    string(round(hbperf.("b"+num2str(i)).YData * 100)), ...
                    "HorizontalAlignment", "center", "VerticalAlignment", "bottom", ...
                    "FontSize", fontSize.Axes, "FontWeight", "normal", "FontName", "Arial");
            end

            % Info
            uicontrol(Fig, "Style", "text", "Units", "centimeters", "BackgroundColor", "w", ...
                "Position", [xmap2(1)-xgap ymap(5)+yInfo/2 axeSize1(1) yInfo/2],...
                "String", bt.Subject(1)+" | KB"+num2str(fp*1000)+" | "+num2str(obj.Meta.CueRatio*100)+"%Cue", ...
                "FontSize", fontSize.Title+1, "FontWeight", "bold", "FontName", "Arial");
            uicontrol(Fig, "Style", "text", "Units", "centimeters", "BackgroundColor", "w", ...
                "Position", [xmap2(1)-xgap ymap(5) axeSize1(1) yInfo/2],...
                "String", string(obj.Meta.DateTime,'yyyy-MM-dd HH:mm:ss'), ...
                "FontSize", fontSize.Title+1, "FontWeight", "bold", "FontName", "Arial");
        end
    
        function print(obj, options)
            arguments
                obj
                options.Figure   = []
                options.savePath = pwd
                options.saveName = obj.SaveName
            end
            if isempty(options.Figure)
                options.Figure = obj.plot();
            end

            [~,~] = mkdir(options.savePath);
            savename = fullfile(options.savePath, options.saveName);
            print(options.Figure, '-dpng', savename);
            print(options.Figure, '-depsc2', savename);
            saveas(options.Figure, savename, 'fig');
        end
    end
    
end

function out = extractBpodDataKB(filename)

    load(filename, "SessionData");
    sd = SessionData;
    % get info
    dname = split(string(filename), '_');
    out.Subject = string(dname(1));
    out.Date = str2double(dname(5));
    
    % get trial data
    nTrials = sd.nTrials;
    cellCustom = struct2cell(sd.Custom);
    for i = 1:length(cellCustom)
        if ~isempty(cellCustom{i}) && nTrials > length(cellCustom{i})
            nTrials = length(cellCustom{i});
        end
    end
    out.nTrial = nTrials;
    out.iTrial = (1:nTrials)';

    % Cue
    cue = sd.Custom.Cue(1:nTrials)';
    idxCue = cue == 1; idxUncue = cue == 0; cue = string(cue);
    cue(idxCue)   = repelem("Cue",   sum(idxCue));
    cue(idxUncue) = repelem("Uncue", sum(idxUncue));
    out.Cue = cue;

    out.FP = round(sd.Custom.ForePeriod(1:nTrials), 2)';
    out.RW = sd.Custom.ResponseWindow(1:nTrials)';
    out.RT = sd.Custom.ReactionTime(1:nTrials)';
    out.MT = sd.Custom.MovementTime(1:nTrials)';

    % Modify FP if needed
    out.Meta.DateTime = datetime(sd.Info.SessionStartTime_MATLAB,'convertfrom','datenum');
    out.Meta.FP = round(unique(out.FP), 2);
    if length(out.Meta.FP) > 1
        warning(string(out.Meta.DateTime)+"  More than one ForePeriod in this session !!!");
    elseif out.Meta.FP ~= sd.Meta.FP
        warning(string(out.Meta.DateTime)+"  Meta.FP = "+num2str(sd.Meta.FP)+ ...
            ", while real FP = "+num2str(out.Meta.FP)+", plz check FP !!!");
    end

    % Add CueRatio from .Meta and check "real cueratio"
    out.Meta.CueRatio = sd.Meta.CueRatio;
    ratioCue = sum(out.Cue == "Cue")/length(out.Cue);
    if abs(ratioCue-out.Meta.CueRatio) > 0.08
        warning(string(out.Meta.DateTime)+"  Meta.CueRatio = "+num2str(sd.Meta.CueRatio)+ ...
            ", while the real cue ratio = "+num2str(ratioCue, "%.2f")+", plz check CueRatio !!!");
    end
    out.Meta.RW_Cue = sd.Meta.RW_Cue;
    out.Meta.RW_Uncue = [sd.Meta.RW_UncueFast sd.Meta.RW_Uncue sd.Meta.RW_UncueSlow];

    darkTry = zeros(nTrials, 1);
    ht = zeros(nTrials, 1);
    outcome = sd.Custom.OutcomeCode(1:nTrials)';

    te = sd.Custom.TimeElapsed(1:nTrials)'; % start press or poke: wait4tone(1)
    te(te > 1e4) = NaN;
    alterTE = false;
    if isnan(te) % For some special cases
        te = nan(nTrials, 1);
        alterTE = true;
    end

    % Get info from rawData
    for i = 1:nTrials
        iStates = sd.RawEvents.Trial{1,i}.States;

        % Dark try num
        if isfield(iStates, 'TimeOut_reset')
            if ~isnan(iStates.TimeOut_reset)
                darkTry(i) = size(iStates.TimeOut_reset,1);
            end
        end
        
        % Hold time
        if isfield(iStates, 'Wait4Tone')
            if isnan(iStates.Wait4Tone) % get hold start time
                if isfield(iStates, 'Delay')
                    HT_ori = iStates.Delay(2); % for custom-made lever
                else
                    HT_ori = iStates.Wait4Start(2);
                end
            else
                HT_ori = iStates.Wait4Tone(end,1);
            end
            switch outcome(i) % HT
                case 1
                    if ~isnan(iStates.Wait4Stop_UncueSlow)
                        ht(i) = iStates.Wait4Stop_UncueSlow(2) - HT_ori;
                    elseif ~isnan(iStates.Wait4Stop_Uncue)
                        ht(i) = iStates.Wait4Stop_Uncue(2) - HT_ori;
                    elseif ~isnan(iStates.Wait4Stop_UncueFast)
                        ht(i) = iStates.Wait4Stop_UncueFast(2) - HT_ori;
                    else
                        ht(i) = iStates.Wait4Stop_Cue(2) - HT_ori;
                    end
                case -1
                    if isfield(iStates, 'GracePeriod')
                        ht(i) = iStates.GracePeriod(end,1) - HT_ori;
                    else
                        ht(i) = iStates.Premature(1) - HT_ori;
                    end
                case -2
                    ht(i) = iStates.LateError(2) - HT_ori;
                otherwise
                    ht(i) = NaN;
            end
        else
            error('Unspecified conditions');
        end

        if alterTE
            te(i) = sd.TrialStartTimestamp(i) + HT_ori;
        end
    end

    % Outcome
    idxCor = outcome == 1; idxPre  = outcome == -1; idxLate = outcome == -2;
    outcome = string(outcome);
    outcome(idxCor)  = repelem("Cor",  sum(idxCor)');
    outcome(idxPre)  = repelem("Pre",  sum(idxPre)');
    outcome(idxLate) = repelem("Late", sum(idxLate)');

    % set value
    out.TimeElapsed = te;
    out.DarkTry = darkTry;
    out.Outcome = outcome;
    out.HT = ht;
end
