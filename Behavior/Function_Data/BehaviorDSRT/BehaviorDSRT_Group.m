classdef BehaviorDSRT_Group
    % Based on BehaviorDSRT_Indiv & BehaviorDSRT
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
        Protocol char {mustBeTextScalar}
        Comment char {mustBeTextScalar}
    end

    properties (Dependent)
        Subjects (:,1) cell {mustBeText}
        Groups (:,1) cell {mustBeText}
        nSession (:,1) double {mustBeNumeric}
        DataAll cell
        Sessions double {mustBeNumeric}
        Dates double {mustBeNumeric}
        Weights double {mustBeNumeric}
        Tasks cell {mustBeText}
        Experiments cell {mustBeText}
        nTrial double
        TableAll cell
    end

    properties (Dependent, GetAccess = private)
        SaveName
    end

    properties (Constant, GetAccess = private)
        FigNum = 2
    end
    
    methods
        function obj = BehaviorDSRT_Group(behavDSRTIndiv,protocol,comment,options)
            arguments
                behavDSRTIndiv (:,1) cell
                protocol char {mustBeTextScalar} = ''
                comment char {mustBeTextScalar} = ''
                options.Groups string {mustBeText} = ""
            end
            obj.Protocol = protocol;
            obj.Comment = comment;

            dataAll = behavDSRTIndiv(cellfun(@(x) isa(x,'BehaviorDSRT_Indiv'),behavDSRTIndiv,'UniformOutput',true));
            nData = length(dataAll);
            % add some information
            for k=1:nData
                % add optional information
                if any(strlength(options.Groups))>0
                    if length(options.Groups)==nData
                        dataAll{k}.Group = options.Groups{k};
                    elseif length(options.Groups)==1
                        dataAll{k}.Group = char(options.Groups);
                    else
                        warning('The length of Groups is not equal to Subjects. Skip the setting.');
                    end
                end
            end
            obj.IndivAll = dataAll;
        end

        function value = get.DataAll(obj)
            dataAll = obj.IndivAll;
            % reorganize: nest --> spread
            dataOut = {};
            for i=1:size(dataAll,1)
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
            for i=1:length(obj.Subjects)
                obj.IndivAll{i}.Subject = value{i};
            end
        end
        
        function value = get.nSession(obj)
            value = cellfun(@(x)x.nSession,obj.IndivAll,'UniformOutput',true);
        end
        
        function value = get.Sessions(obj)
            value = cellfun(@(x)getProp(x,'Session'),obj.DataAll,'UniformOutput',false);
        end

        function obj = set.Sessions(obj,value)
            for i=1:length(obj.Subjects)
                obj.IndivAll{i,1}.Sessions(1:obj.nSession(i)) = value(i,1:obj.nSession(i));
            end
        end

        function value = get.Dates(obj)
            value = cellfun(@(x)getProp(x,'Date'),obj.DataAll,'UniformOutput',false);
        end
        
        function value = get.Weights(obj)
            value = cellfun(@(x)getProp(x,'Weight'),obj.DataAll,'UniformOutput',false);
        end

        function value = get.Tasks(obj)
            value = cellfun(@(x)getProp(x,'Task'),obj.DataAll,'UniformOutput',false);
        end

        function value = get.Experiments(obj)
            value = cellfun(@(x)getProp(x,'Experiment'),obj.DataAll,'UniformOutput',false);
        end

        function obj = set.Experiments(obj,value)
            for i=1:length(obj.Subjects)
                obj.IndivAll{i,1}.Experiments = value(i,1:obj.nSession(i)); % string{i}
            end
        end

        function value = get.nTrial(obj)
            value = cellfun(@(x)getProp(x,'nTrial'),obj.DataAll,'UniformOutput',false);
        end

        function value = get.TableAll(obj)
            value = cellfun(@(x)getProp(x,'Table'),obj.DataAll,'UniformOutput',false);
        end
        
        function STAT = stat(obj)
            STAT = struct;
            % TBT
            value = table;
            for i=1:length(obj.Subjects)
                value = [value;obj.IndivAll{i}.TBT];
            end
            STAT.TBT = value;
            % SBS
            value = table;
            for i=1:length(obj.Subjects)
                value = [value;obj.IndivAll{i}.SBS];
            end
            STAT.SBS = value;
            % SBSgrp
            SBSerase = removevars(STAT.SBS,{'Subject','Experiment','Date','DateTime'});
            value = grpstats(SBSerase,{'Group','Session','Task','TrialType'},{'mean','sem'});
            STAT.SBSgrp = value;
            % SBSebe
            SBSerase = removevars(STAT.SBS,{'Subject','Date','DateTime'});
            value = grpstats(SBSerase,{'Session','Group','Experiment','Task','TrialType'},{'mean','sem'});
            STAT.SBSebe = value;
            % EBE
            value = table;
            for i=1:length(obj.Subjects)
                value = [value;obj.IndivAll{i}.EBE];
            end
            STAT.EBE = value;
            %EBEgrp
            EBEerase = removevars(STAT.EBE,{'Subject'});
            value = grpstats(EBEerase,{'Group','Experiment','Task','TrialType'},{'mean','sem'});
            STAT.EBEgrp = value;
        end

        function value = get.SaveName(obj)
            if isempty(obj.Protocol)
                value = append('BClassGroup_',char(datetime('now','Format','yyyyMMdd')));
            else
                value = append('BClassGroup_',obj.Protocol);
            end
        end

        function obj = reNumber(obj, expStr)
            % re-number sessions by experiments
            expAll = obj.Experiments;
            newSess = zeros(size(expAll));
            if nargin == 1
                % simply renumber sessions as 1~n for each experiment
                for i = 1:height(expAll)
                    kk = 1;
                    for j = 1:length(expAll)
                        if ~isempty(expAll{i, j})
                            if j > 1
                                if string(expAll{i, j}) ~= string(expAll{i, j-1})
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
                expcmp1 = strcmp(expAll, expStr{1});
                expcmp2 = strcmp(expAll, expStr{2});
                for i = 1:height(expAll)
                    idx1 = find(expcmp1(i, :));
                    idx2 = find(expcmp2(i, :));
                    if ~isempty(idx1)
                        newSess(i, idx1) = idx1-idx1(end)-1;
                    end
                    if ~isempty(idx2)
                        newSess(i, idx2) = idx2-idx2(1)+1;
                    end
                end
            end
            obj.Sessions = newSess;
        end

        function obj = reExp(obj, slctSes, expStr)
            % re-number sessions by experiments
            nSes = obj.nSession;
            sesAll = obj.Sessions;
            newExp = cell(size(sesAll));
            if height(slctSes) ~= height(expStr)
                error('Sessions ~ Experiments not match');
            end

            for i = 1:length(nSes)
                for j = 1:nSes(i)
                    for k = 1:height(slctSes)
                        if ismember(sesAll{i,j}, slctSes(k,:))
                            newExp{i,j} = expStr{k};
                        end
                    end
                    if isempty(newExp{i,j})
                        newExp{i,j} = 'reject';
                    end
                end
            end
            newExp = cellfun(@(x) trans2char(x),newExp,'UniformOutput',false);
            obj.Experiments = newExp;
        end

        

        function save(obj,savePath)
            arguments
                obj
                savePath = pwd
            end
            STAT = obj.stat;
            [~,~] = mkdir(savePath);
            save(fullfile(savePath,obj.SaveName),'obj','STAT');
            writetable(STAT.TBT,fullfile(savePath,append(obj.SaveName,'.xlsx')),'Sheet','TBT');
            writetable(STAT.SBS,fullfile(savePath,append(obj.SaveName,'.xlsx')),'Sheet','SBS');
            writetable(STAT.SBSgrp,fullfile(savePath,append(obj.SaveName,'.xlsx')),'Sheet','SBSgrp');
            writetable(STAT.SBSebe,fullfile(savePath,append(obj.SaveName,'.xlsx')),'Sheet','SBSebe');
            writetable(STAT.EBE,fullfile(savePath,append(obj.SaveName,'.xlsx')),'Sheet','EBE');
            writetable(STAT.EBEgrp,fullfile(savePath,append(obj.SaveName,'.xlsx')),'Sheet','EBEgrp');
        end

        function fig = plot(obj,plotRange,options)
            arguments
                obj
                plotRange = []
                options.plotType char {mustBeMember(options.plotType,{'DayByDay', 'CompExp', 'CompSes', 'LearningAll'})} = 'DayByDay'
                options.figSize double = []
                options.slctSession double = []
                options.expStr string = []
            end
            
            if ~isempty(plotRange) && ~any(isnan(plotRange))
                Obj = BehaviorDSRT_Indiv(obj.DataAll(plotRange));
            else
                Obj = obj;
            end
            % Parameters
            cTab10 = [0.0901960784313726,0.466666666666667,0.701960784313725;
                0.960784313725490,0.498039215686275,0.137254901960784;
                0.152941176470588,0.631372549019608,0.278431372549020;
                0.843137254901961,0.149019607843137,0.172549019607843;
                0.564705882352941,0.403921568627451,0.674509803921569;
                0.549019607843137,0.337254901960784,0.290196078431373;
                0.847058823529412,0.474509803921569,0.698039215686275;
                0.501960784313726,0.501960784313726,0.501960784313726;
                0.737254901960784,0.745098039215686,0.196078431372549;
                0.113725490196078,0.737254901960784,0.803921568627451];
            cBlue = cTab10(1,:);
            cOrange = cTab10(2,:);
            cGreen = cTab10(3,:);
            cRed = cTab10(4,:);
            cGray = cTab10(8,:);
            cBrown = cTab10(6,:);
            cCyan = cTab10(10,:);
            cCPL = [cGreen;cRed;cGray];
            cExp = [cBlue;cGray];
            c3FPs = [cGray;mean([cOrange;cGray]);cOrange];

            set(groot,'defaultAxesFontName','Helvetica');
            fontAxesSz = 7;
            fontLablSz = 9;
            fontTitlSz = 10;

            switch lower(options.plotType)
                case 'daybyday'
                    fig = learningPlot(Obj);
                case 'learningall'
                    fig = learningPlotAll(Obj);
                case 'compexp'
                    fig = compExpPlot(Obj, options.expStr);
                case 'compses'
                    fig = compSesPlot(Obj, options.slctSession, options.expStr);
            end

            %% Learning curve of Wait or MixedFPs
            function h = learningPlot(Obj)
            
            end

            %% Learning curve of all SRT stages
            function h = learningPlotAll(Obj)
                STAT = Obj.stat;
                SBS = STAT.SBS;
                SBSgrp = STAT.SBSgrp;
                grpName = unique(SBSgrp.Group);
                if length(grpName) > 2
                    error('Check group names in TrainingLog.xls');
                end

                % generate TaskSign (TS)
                % TS.Task - task name (e.g. '3FPs'); 
                % TS.Ori/End - first/last session number
                sessTask = {'Wait1', 'Wait2', '3FPs'};
                taskLen = struct;
                taskLen.Task = sessTask;
                taskSBS = cell(length(sessTask), 1);
                for i = 1:length(sessTask)
                    taskSBS{i} = SBS(SBS.Task == sessTask{i}, :);
                    it = tabulate(taskSBS{i}.Session);
                    taskLen.Len{i} = find(it(:, 2) == max(it(:, 2)));
                end
                TaskLen = struct2table(taskLen);


                h = figure(2); clf(h, 'reset');
                set(h, 'name', 'Learning', 'units', 'centimeters', 'position', [1 1 12.5 11.5],...
                    'PaperPositionMode', 'auto');
                size1 = [3,3*0.7];
                
                ys = [1 3.6 6.2 8.8]; % yStart
                ys = fliplr(ys);
                xs = [1.3 4.5 7.7]; % xStart
                
                % PLOT x:session, y:Correct Wait1, color: Group(hM4D/EGFP)
                ha11 = axes;
                set(ha11, 'units', 'centimeters', 'position', [xs(1) ys(1) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',7,'fontname','Arial','ylim',[0.4,1],'ticklength', [0.02 0.025]);
                iTask = 1;
                SBSgrp_this = SBSgrp(ismember(SBSgrp.Session, TaskLen.Len{iTask}) & SBSgrp.Task == TaskLen.Task{iTask}, :);
                
                idxGrp = 2;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_Cor(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_Cor(SBSgrp_this.Group==grpName(idxGrp))';
                l2 = plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
                idxGrp = 1;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_Cor(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_Cor(SBSgrp_this.Group==grpName(idxGrp))';
                l1 = plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)
                
                xlim([0.5, TaskLen.Len{iTask}(end)+0.5]);
                set(gca,'xtick',1:10,'ytick',0:0.2:1,'yticklabel',cellstr(string((0:0.2:1).*100))); %grid on;
                % xlabel('Sessions','Fontsize',8,'FontName','Arial');
                ylabel('Correct (%)','Fontsize',8,'FontName','Arial');
                title(TaskLen.Task{iTask},'Fontsize',9,'FontName','Arial');
                
                le1 = legend([l1 l2],cellstr(grpName),'Fontsize',8,'units','centimeters',...
                    'Position',[xs(3)+size1(1)+0.3,ys(1)+size1(2)/1.8,1,1]);% [4.7,2.8,1,1]
                le1.ItemTokenSize = [12,22];
                le1.Position = le1.Position + [0.025 0.045 0 0];
                legend('boxoff');

                
                % PLOT x:session, y:Correct Wait2, color: Group(hM4D/EGFP)
                ha12 = axes;
                set(ha12, 'units', 'centimeters', 'position', [xs(2) ys(1) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',7,'fontname','Arial','ylim',[0.4,1],'ticklength', [0.02 0.025]);
                ha12.YAxis.Visible = 'off';
                iTask = 2;
                SBSgrp_this = SBSgrp(ismember(SBSgrp.Session, TaskLen.Len{iTask}) & SBSgrp.Task == TaskLen.Task{iTask}, :);
                
                idxGrp = 2;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_Cor(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_Cor(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
                idxGrp = 1;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_Cor(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_Cor(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)
                
                
                xlim([0.5, TaskLen.Len{iTask}(end)+0.5]);
                set(gca,'xtick',1:10); %grid on;
                title(TaskLen.Task{iTask},'Fontsize',9,'FontName','Arial');

                % PLOT x:session, y:Correct 3FPs, color: Group(hM4D/EGFP)
                ha13 = axes;
                set(ha13, 'units', 'centimeters', 'position', [xs(3) ys(1) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',7,'fontname','Arial','ylim',[0.4,1],'ticklength', [0.02 0.025]);
                ha13.YAxis.Visible = 'off';
                iTask = 3;
                SBSgrp_this = SBSgrp(ismember(SBSgrp.Session, TaskLen.Len{iTask}) & SBSgrp.Task == TaskLen.Task{iTask}, :);
                
                idxGrp = 2;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_Cor(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_Cor(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
                idxGrp = 1;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_Cor(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_Cor(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)
                
                xlim([0.5, TaskLen.Len{iTask}(end)+0.5]);
                set(gca,'xtick',1:10); %grid on;
                title(TaskLen.Task{iTask},'Fontsize',9,'FontName','Arial');

                
                % PLOT x:session, y:Premature Wait1, color: Group(hM4D/EGFP)
                ha21 = axes;
                set(ha21, 'units', 'centimeters', 'position', [xs(1) ys(2) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',7,'fontname','Arial','ylim',[0,0.5],'ticklength', [0.02 0.025]);
                iTask = 1;
                SBSgrp_this = SBSgrp(ismember(SBSgrp.Session, TaskLen.Len{iTask}) & SBSgrp.Task == TaskLen.Task{iTask}, :);
        
                idxGrp = 2;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_Pre(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_Pre(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
                idxGrp = 1;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_Pre(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_Pre(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)
                
                xlim([0.5, TaskLen.Len{iTask}(end)+0.5]);
                set(gca,'xtick',1:10,'ytick',0:0.2:1,'yticklabel',cellstr(string((0:0.2:1).*100))); %grid on;
                % xlabel('Sessions','Fontsize',8,'FontName','Arial');
                ylabel('Premature (%)','Fontsize',8,'FontName','Arial');
                % title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');
                
                % PLOT x:session, y:Premature Wait2, color: Group(hM4D/EGFP)
                ha22 = axes;
                set(ha22, 'units', 'centimeters', 'position', [xs(2) ys(2) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',7,'fontname','Arial','ylim',[0,0.5],'ticklength', [0.02 0.025]);
                ha22.YAxis.Visible = 'off';
                iTask = 2;
                SBSgrp_this = SBSgrp(ismember(SBSgrp.Session, TaskLen.Len{iTask}) & SBSgrp.Task == TaskLen.Task{iTask}, :);
        
                idxGrp = 2;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_Pre(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_Pre(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
                idxGrp = 1;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_Pre(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_Pre(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)
                
                xlim([0.5, TaskLen.Len{iTask}(end)+0.5]);
                set(gca,'xtick',1:10); %grid on;
                % xlabel('Sessions','Fontsize',8,'FontName','Arial');
                % ylabel('Premature','Fontsize',8,'FontName','Arial');
                % title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');
                
                % PLOT x:session, y:Premature 3FPs, color: Group(hM4D/EGFP)
                ha23 = axes;
                set(ha23, 'units', 'centimeters', 'position', [xs(3) ys(2) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',7,'fontname','Arial','ylim',[0,0.5],'ticklength', [0.02 0.025]);
                ha23.YAxis.Visible = 'off';
                iTask = 3;
                SBSgrp_this = SBSgrp(ismember(SBSgrp.Session, TaskLen.Len{iTask}) & SBSgrp.Task == TaskLen.Task{iTask}, :);
       
                idxGrp = 2;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_Pre(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_Pre(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
                idxGrp = 1;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_Pre(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_Pre(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)
                
                xlim([0.5, TaskLen.Len{iTask}(end)+0.5]);
                set(gca,'xtick',1:10); %grid on;
                % xlabel('Sessions','Fontsize',8,'FontName','Arial');
                % ylabel('Premature','Fontsize',8,'FontName','Arial');
                % title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');
                
                % PLOT x:session, y:Late Wait1, color: Group(hM4D/EGFP)
                ha31 = axes;
                set(ha31, 'units', 'centimeters', 'position', [xs(1) ys(3) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',7,'fontname','Arial','ylim',[0,0.31],'ticklength', [0.02 0.025]);
                iTask = 1;
                SBSgrp_this = SBSgrp(ismember(SBSgrp.Session, TaskLen.Len{iTask}) & SBSgrp.Task == TaskLen.Task{iTask}, :);
        
                idxGrp = 2;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_Late(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_Late(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
                idxGrp = 1;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_Late(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_Late(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)
                
                xlim([0.5, TaskLen.Len{iTask}(end)+0.5]);
                set(gca,'xtick',1:10,'ytick',0:0.1:1,'yticklabel',cellstr(string((0:0.1:1).*100))); %grid on;
                % xlabel('Sessions','Fontsize',8,'FontName','Arial');
                ylabel('Late (%)','Fontsize',8,'FontName','Arial');
                % title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');
                
                % PLOT x:session, y:Late Wait2, color: Group(hM4D/EGFP)
                ha32 = axes;
                set(ha32, 'units', 'centimeters', 'position', [xs(2) ys(3) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',7,'fontname','Arial','ylim',[0,0.31],'ticklength', [0.02 0.025]);
                ha32.YAxis.Visible = 'off';
                iTask = 2;
                SBSgrp_this = SBSgrp(ismember(SBSgrp.Session, TaskLen.Len{iTask}) & SBSgrp.Task == TaskLen.Task{iTask}, :);
       
                idxGrp = 2;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_Late(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_Late(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
                idxGrp = 1;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_Late(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_Late(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)
                
                xlim([0.5, TaskLen.Len{iTask}(end)+0.5]);
                set(gca,'xtick',1:10); %grid on;
                % xlabel('Sessions','Fontsize',8,'FontName','Arial');
                % ylabel('Late','Fontsize',8,'FontName','Arial');
                % title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');
                
                % PLOT x:session, y:Late 3FPs, color: Group(hM4D/EGFP)
                ha33 = axes;
                set(ha33, 'units', 'centimeters', 'position', [xs(3) ys(3) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',7,'fontname','Arial','ylim',[0,0.31],'ticklength', [0.02 0.025]);
                ha33.YAxis.Visible = 'off';
                iTask = 3;
                SBSgrp_this = SBSgrp(ismember(SBSgrp.Session, TaskLen.Len{iTask}) & SBSgrp.Task == TaskLen.Task{iTask}, :);
      
                idxGrp = 2;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_Late(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_Late(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
                idxGrp = 1;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_Late(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_Late(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)
                
                xlim([0.5, TaskLen.Len{iTask}(end)+0.5]);
                set(gca,'xtick',1:10); %grid on;
                % xlabel('Sessions','Fontsize',8,'FontName','Arial');
                % ylabel('Late','Fontsize',8,'FontName','Arial');
                % title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');
                
                % PLOT x:session, y:RT Wait1, color: Group(hM4D/EGFP)
                ha41 = axes;
                set(ha41, 'units', 'centimeters', 'position', [xs(1) ys(4) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',7,'fontname','Arial','ylim',[0.25,0.75],'ticklength', [0.02 0.025]);
                iTask = 1;
                SBSgrp_this = SBSgrp(ismember(SBSgrp.Session, TaskLen.Len{iTask}) & SBSgrp.Task == TaskLen.Task{iTask}, :);
     
                idxGrp = 2;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_RT(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_RT(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
                idxGrp = 1;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_RT(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_RT(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)
                
                xlim([0.5, TaskLen.Len{iTask}(end)+0.5]);
                set(gca,'xtick',1:10,'ytick',0.1:0.2:1,'yticklabel',cellstr(string((0.1:0.2:1).*1000))); %grid on;
                xlabel('Sessions','Fontsize',8,'FontName','Arial');
                ylabel('RT (ms)','Fontsize',8,'FontName','Arial');
                % title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');
                
                % PLOT x:session, y:RT Wait2, color: Group(hM4D/EGFP)
                ha42 = axes;
                set(ha42, 'units', 'centimeters', 'position', [xs(2) ys(4) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',7,'fontname','Arial','ylim',[0.25,0.75],'ticklength', [0.02 0.025]);
                ha42.YAxis.Visible = 'off';
                iTask = 2;
                SBSgrp_this = SBSgrp(ismember(SBSgrp.Session, TaskLen.Len{iTask}) & SBSgrp.Task == TaskLen.Task{iTask}, :);
       
                idxGrp = 2;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_RT(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_RT(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
                idxGrp = 1;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_RT(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_RT(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)
                
                xlim([0.5, TaskLen.Len{iTask}(end)+0.5]);
                set(gca,'xtick',1:10); %grid on;
                xlabel('Sessions','Fontsize',8,'FontName','Arial');
                % ylabel('RT','Fontsize',8,'FontName','Arial');
                % title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');
                
                % PLOT x:session, y:RT 3FPs, color: Group(hM4D/EGFP)
                ha43 = axes;
                set(ha43, 'units', 'centimeters', 'position', [xs(3) ys(4) size1], 'nextplot', 'add','tickDir', 'out',...
                    'fontsize',7,'fontname','Arial','ylim',[0.25,0.75],'ticklength', [0.02 0.025]);
                ha43.YAxis.Visible = 'off';
                iTask = 3;
                SBSgrp_this = SBSgrp(ismember(SBSgrp.Session, TaskLen.Len{iTask}) & SBSgrp.Task == TaskLen.Task{iTask}, :);
           
                idxGrp = 2;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_RT(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_RT(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
                idxGrp = 1;
                xv = (TaskLen.Len{iTask})';
                yv = SBSgrp_this.mean_RT(SBSgrp_this.Group==grpName(idxGrp))';
                ev = SBSgrp_this.sem_RT(SBSgrp_this.Group==grpName(idxGrp))';
                plot(xv,yv,...
                    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
                line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)
                
                xlim([0.5, TaskLen.Len{iTask}(end)+0.5]);
                set(gca,'xtick',1:10); %grid on;
                xlabel('Sessions','Fontsize',8,'FontName','Arial');

                % text
                grp1Sbj = unique(SBS(cellfun(@(x) ~isempty(x),strfind(SBS.Group,grpName(1))),:).Subject,'stable');
                grp2Sbj = unique(SBS(cellfun(@(x) ~isempty(x),strfind(SBS.Group,grpName(2))),:).Subject,'stable');
                
                haSbj = axes('units', 'centimeters', 'position', [12.5 ys(1) 2.642 size1(2)],'Visible','off');
                text(haSbj,0,1,[upper(grpName(1)),grp1Sbj'],'fontsize',6,'VerticalAlignment','top');
                text(haSbj,0.5,1,[upper(grpName(2)),grp2Sbj'],'fontsize',6,'VerticalAlignment','top');

                %% Heatmap of each animal's performance


                esti = 'Cor';
                estVec = [];
                clm = [0.3,1];
                Height = 8; % axes height (centimeter)
                mycolormap = customcolormap([0 0.5 1], [1 1 1; 1 0 0; 0 0 0]);%Black
                % mycolormap = flipud(magma);
                
                sortSBS = sortrows(SBS,{'Group','Subject'},{'ascend','ascend'});
                [sbjorder,idxSub] = unique(sortSBS.Subject,'stable');
                grporder = sortSBS.Group(idxSub);
                Nrats = length(unique(SBS.Subject));
                Ngrp = [length(unique(SBS(SBS.Group==grpName(1),:).Subject)),length(unique(SBS(SBS.Group==grpName(2),:).Subject))];
                Ntask = [length(TaskLen.Len{1}), length(TaskLen.Len{2}), length(TaskLen.Len{3})];
%                 Ntask = [length(unique(SBS(SBS.Task=="Wait1",:).Session)),length(unique(SBS(SBS.Task=="Wait2",:).Session)),length(unique(SBS(SBS.Task=="3FPs",:).Session))];
                
                Width = (sum(Ntask)+length(Ntask))*Height./(sum(Ngrp)+length(Ngrp));
                
                h = figure(44); clf(h,'reset');
                set(h, 'name', 'Learning', 'units', 'centimeters', 'position', [1 1 Width+3.8 Height+1.5],...
                    'PaperPositionMode', 'auto');
                hheat = axes;
                set(hheat, 'units', 'centimeters','nextplot', 'add','tickDir', 'out',...
                    'position',[1.8 0.8 Width,Height],...
                    'xlim',[0 sum(Ntask)+length(Ntask)],...
                    'xtick', [Ntask(1)/2+0.5, Ntask(1)+Ntask(2)/2+1.5, Ntask(1)+Ntask(2)+Ntask(3)/2+2.5],...
                    'xticklabel',cellstr(unique(sortSBS.Task,'stable')),...
                    'ylim',[0, Nrats+2],'ytick', [Ngrp(2)/2+0.5, Ngrp(2)+Ngrp(1)/2+1.5], ...
                    'yticklabel', {sprintf('%s(N=%2.0d)',grpName(2), Ngrp(2)), sprintf('%s(N=%2.0d)',grpName(1), Ngrp(1))},...
                    'fontsize',7,'fontname','arial','ticklength', [0.02 0.025]);
                % title(['Performance: ',esti],'fontsize',9,'fontname','arial');
                
                Nx = Ntask(1); Nxpre = 0;
                curSBS = sortSBS(sortSBS.Task=="Wait1" & ismember(sortSBS.Session, TaskLen.Len{1}),:);
                eval(['estVec = curSBS.', esti, ';']);
                val2 = reshape(estVec(curSBS.Group==grpName(2)),[Nx,length(estVec(curSBS.Group==grpName(2)))/Nx])';
                val1 = reshape(estVec(curSBS.Group==grpName(1)),[Nx,length(estVec(curSBS.Group==grpName(1)))/Nx])';
                % [val2,idx2] = sortrows(val2,1,'descend');
                % [val1,idx1] = sortrows(val1,1,'descend');
                mval2 = mean(val2,2); [~,idx2] = sort(mval2,'ascend');val2 = val2(idx2,:);
                mval1 = mean(val1,2); [~,idx1] = sort(mval1,'ascend');val1 = val1(idx1,:);
                h_grp2 = imagesc([Nxpre+1,Nxpre+Nx],[1,Ngrp(2)],val2,clm);
                h_grp1 = imagesc([Nxpre+1,Nxpre+Nx],[1,Ngrp(1)]+Ngrp(2)+1,val1,clm);
                Nxpre = Nxpre+Nx+1;
                sbj2 = sbjorder(strcmp(grporder,grpName(2)));sbj2 = sbj2(idx2);
                sbj1 = sbjorder(strcmp(grporder,grpName(1)));sbj1 = sbj1(idx1);
                set(gca,'ytick',[1:Ngrp(2),(Ngrp(2)+2):(Ngrp(2)+1+Ngrp(1))],'yticklabel',cellstr([sbj2;sbj1]));
                
                Nx = Ntask(2);
                curSBS = sortSBS(sortSBS.Task=="Wait2" & ismember(sortSBS.Session, TaskLen.Len{2}),:);
                eval(['estVec = curSBS.', esti, ';']);
                val2 = reshape(estVec(curSBS.Group==grpName(2)),[Nx,length(estVec(curSBS.Group==grpName(2)))/Nx])';
                val1 = reshape(estVec(curSBS.Group==grpName(1)),[Nx,length(estVec(curSBS.Group==grpName(1)))/Nx])';
                val2 = val2(idx2,:);
                val1 = val1(idx1,:);
                h_grp2 = imagesc([Nxpre+1,Nxpre+Nx],[1,Ngrp(2)],val2,clm);
                h_grp1 = imagesc([Nxpre+1,Nxpre+Nx],[1,Ngrp(1)]+Ngrp(2)+1,val1,clm);
                Nxpre = Nxpre+Nx+1;
                
                Nx = Ntask(3);
                curSBS = sortSBS(sortSBS.Task=="3FPs" & ismember(sortSBS.Session, TaskLen.Len{3}),:);
                eval(['estVec = curSBS.', esti, ';']);
                val2 = reshape(estVec(curSBS.Group==grpName(2)),[Nx,length(estVec(curSBS.Group==grpName(2)))/Nx])';
                val1 = reshape(estVec(curSBS.Group==grpName(1)),[Nx,length(estVec(curSBS.Group==grpName(1)))/Nx])';
                val2 = val2(idx2,:);
                val1 = val1(idx1,:);
                h_grp2 = imagesc([Nxpre+1,Nxpre+Nx],[1,Ngrp(2)],val2,clm);
                h_grp1 = imagesc([Nxpre+1,Nxpre+Nx],[1,Ngrp(1)]+Ngrp(2)+1,val1,clm);
                
                colormap(mycolormap);
                hcbar = colorbar('location', 'EastOutSide','Units', 'Centimeters','AxisLocation','in',...
                    'position',[1.8+Width+0.8,0.8,0.25,Height*0.4],...
                    'ytick', 0:0.2:1,'yticklabel', cellstr(string([0:0.2:1].*100)),...
                    'TickDirection', 'out','ticklength', 0.02,'FontSize',7,'fontname','arial');
                hcbarbel = ylabel(hcbar,[esti, ' %'],'FontSize',8,'Rotation',270,'fontname','arial',...
                    'Units','Centimeters');
                hcbarbel.Position(1) = hcbarbel.Position(1)+1.1;
            end

            %% Comparison between two experiment conditions
            function h = compExpPlot(Obj, expStr)
                
            end

            %% Comparison between selected sessions
            function h = compSesPlot(Obj, scltSession, expStr)

            end

        end

        function compExpPlot(Obj, expStr)

            % Parameters
            cTab10 = [0.0901960784313726,0.466666666666667,0.701960784313725;
                0.960784313725490,0.498039215686275,0.137254901960784;
                0.152941176470588,0.631372549019608,0.278431372549020;
                0.843137254901961,0.149019607843137,0.172549019607843;
                0.564705882352941,0.403921568627451,0.674509803921569;
                0.549019607843137,0.337254901960784,0.290196078431373;
                0.847058823529412,0.474509803921569,0.698039215686275;
                0.501960784313726,0.501960784313726,0.501960784313726;
                0.737254901960784,0.745098039215686,0.196078431372549;
                0.113725490196078,0.737254901960784,0.803921568627451];
            cGreen = cTab10(3,:);
            cRed = cTab10(4,:);
            cGray = cTab10(8,:);

            Obj = Obj.reNumber(expStr);
            STAT = Obj.stat;
            SBS = STAT.SBS;
            SBSebe = STAT.SBSebe;

            expLen = cell(length(expStr), 1);
            expSBS = cell(length(expStr), 1);
            for i = 1:length(expStr)
                expSBS{i} = SBS(SBS.Experiment == expStr{i}, :);
                it = tabulate(expSBS{i}.Session);
                expLen{i} = it(it(:, 2) == max(it(:, 2)), 1);
            end
            idxExp = ismember(SBSebe.Session, [expLen{1}, expLen{2}]);
            shadedErrorBar([expLen{1}+1, expLen{2}], SBSebe.mean_Cor(idxExp),...
                SBSebe.sem_Cor(idxExp),...
                'lineProps',{'o-','linewidth',1.5,'color',cGreen, ...
                'markerSize',4,'markerFaceColor',cGreen,'markerEdgeColor','none'});
            shadedErrorBar([expLen{1}+1, expLen{2}], SBSebe.mean_Pre(idxExp),...
                SBSebe.sem_Pre(idxExp),...
                'lineProps',{'o-','linewidth',1.5,'color',cRed, ...
                'markerSize',4,'markerFaceColor',cRed,'markerEdgeColor','none'});
            shadedErrorBar([expLen{1}+1, expLen{2}], SBSebe.mean_Late(idxExp),...
                SBSebe.sem_Late(idxExp),...
                'lineProps',{'o-','linewidth',1.5,'color',cGray, ...
                'markerSize',4,'markerFaceColor',cGray,'markerEdgeColor','none'});

            plot([0.5,0.5],[0,1],'k','linewidth',0.6);
            xlim([expLen{1}(1)+0.5, expLen{2}(end)+0.5]);ylim([0,1]);
            set(gca,'xtick',[expLen{1}(1)+1,0,1,expLen{2}(end)], ...
                'xticklabel', string([expLen{1}(1),-1,1,expLen{2}(end)]),...
                'ytick',0:0.5:1, 'yticklabel',{'0', '50', '100'});
            xlabel('Sessions','Fontsize',8,'FontName','Arial');
            ylabel('Percentage (%)','Fontsize',8,'FontName','Arial');
            
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

function out = trans2char(in)
    out = '';
    if ischar(in)
        out = in;
    end
end