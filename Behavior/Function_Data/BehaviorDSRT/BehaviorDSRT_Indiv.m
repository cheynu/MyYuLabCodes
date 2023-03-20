classdef BehaviorDSRT_Indiv
    % Based on BehaviorDSRT
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
        Protocol char {mustBeTextScalar} % e.g., 'WaitPeriod'
        Comment char {mustBeTextScalar}
    end

    properties (Dependent)
        Subject char {mustBeTextScalar} % e.g., Panini
        Strain char {mustBeTextScalar} % e.g., LE
        Group char {mustBeTextScalar} % e.g., hM3Dq (manual or extracted by BehaviorDSRT)
        nSession double {mustBeNumeric}
        Sessions double {mustBeNumeric}
        Dates (1,:) double {mustBeNumeric}
        Weights (1,:) double {mustBeNumeric}
        Tasks (1,:) cell {mustBeText} % e.g., {'Wait1','Wait1','Wait1','Wait2'}
        Experiments (1,:) cell {mustBeText} % e.g., {'Saline','DCZ','Saline','DCZ'}
        nTrial (1,:) double
        TableAll (1,:) cell
        TBT table % trial by trial
        SBS table % session by session, every row: stat for each session * TrialType
        EBE table % experiment by experiment, every row: stat for each Experiment * TrialType
    end

    properties (Dependent, GetAccess = private)
        SaveName
    end

    properties (Constant, GetAccess = private)
        FigNum = 2
        MergeMethod = {'Merge','Select'}
    end
    
    methods
        function obj = BehaviorDSRT_Indiv(behavDSRTAll,protocol,comment,options)
            arguments
                behavDSRTAll (1,:) cell
                protocol char {mustBeTextScalar} = ''
                comment char {mustBeTextScalar} = ''
                options.Subject char {mustBeTextScalar} = ''
                options.Strain char {mustBeTextScalar} = ''
                options.Group char {mustBeTextScalar} = ''
                options.Experimenter string {mustBeText} = ""
                options.Comments string {mustBeText} = ""
                options.Experiments string {mustBeText} = ""
                options.Weights double {mustBeNumeric} = []
                options.Sessions double {mustBeNumeric} = []
                options.MergeMethod char {mustBeMember(options.MergeMethod,{'Merge','Select'})} = 'Merge'
            end
            
            obj.Protocol = protocol;
            obj.Comment = comment;
            dataAll = Merge1DayDSRT(behavDSRTAll,options.MergeMethod); % Merge 1 day's data
            nData = length(dataAll);
            % add some information
            isSession = cellfun(@(x)~isnan(x.Session),dataAll,'UniformOutput',true);
            for k=1:nData
                % add session information
                if ~any(isSession)
                    if k == 1
                        kk = 1;
                    else
                        if string(dataAll{1, k}.Task) ~= string(dataAll{1, k-1}.Task)
                            kk = 1;
                        else
                            kk = kk + 1;
                        end
                    end
                    if isempty(options.Sessions) || length(options.Sessions)~=nData
                        dataAll{k}.Session = kk;
                    else
                        dataAll{k}.Session = options.Sessions(k);
                    end
                end
                % add optional information
                if ~isempty(options.Subject)
                    dataAll{k}.Subject = options.Subject;
                end
                if ~isempty(options.Strain)
                    dataAll{k}.Strain = options.Strain;
                end
                if ~isempty(options.Group)
                    dataAll{k}.Group = options.Group;
                end
                if any(strlength(options.Experimenter))>0 % isempty("")==false
                    if length(options.Experimenter)==nData
                        dataAll{k}.Experimenter = options.Experimenter{k};
                    elseif length(options.Experimenter)==1
                        dataAll{k}.Experimenter = char(options.Experimenter);
                    else
                        warning('The length of Experimenter is not equal to nSession. Skip the setting.');
                    end
                end
                if any(strlength(options.Comments))>0
                    if length(options.Comments)==nData
                        dataAll{k}.Comment = options.Comments{k};
                    elseif length(options.Comments)==1
                        dataAll{k}.Comment = char(options.Comments);
                    else
                        warning('The length of Comment is not equal to nSession. Skip the setting.');
                    end
                end
                if any(strlength(options.Experiments))>0
                    if length(options.Experiments)==nData
                        dataAll{k}.Experiment = options.Experiments{k}; % string{1} = 'str', string(1) = "str".
                    elseif length(options.Experiments)==1
                        dataAll{k}.Experiment = char(options.Experiments);
                    else
                        warning('The length of Experiments is not equal to nSession. Skip the setting.');
                    end
                end
                if ~isempty(options.Weights)
                    if length(options.Weights)==nData
                        dataAll{k}.Weight = options.Weights{k}; % string{1} = 'str', string(1) = "str".
                    elseif length(options.Weights)==1
                        dataAll{k}.Weight = options.Weights;
                    else
                        warning('The length of Weights is not equal to nSession. Skip the setting.');
                    end
                end
                if ~isempty(options.Sessions)
                    if length(options.Sessions)==nData
                        dataAll{k}.Session = options.Sessions{k}; % string{1} = 'str', string(1) = "str".
                    elseif length(options.Sessions)==1
                        dataAll{k}.Session = options.Sessions;
                    else
                        warning('The length of Weights is not equal to nSession. Skip the setting.');
                    end
                end
            end
            obj.DataAll = dataAll;

            function out = Merge1DayDSRT(behavDSRTAll,varargin)
                p = inputParser;
                addRequired(p,'behavDSRTAll',@iscell);
                addOptional(p,'method','Merge',@mustBeTextScalar);
                parse(p,behavDSRTAll,varargin{:});
                method = p.Results.method;
                
                dates = cellfun(@(x)x.Date,behavDSRTAll,'UniformOutput',true);
                [~,ia,~] = unique(dates,'stable');

                out = cell(1,length(ia));
                for i=1:length(out)
                    out{i} = behavDSRTAll{ia(i)};
                    for j=1:length(behavDSRTAll)
                        if ia(i)~=j
                            out{i} = out{i}.merge(behavDSRTAll{j},method,true);
                        end
                    end
                end
            end
        end

        function value = get.Subject(obj)
            value = unique(string(cellfun(@(x)x.Subject,obj.DataAll,'UniformOutput',false)));
            mustBeTextScalar(value);
            value = char(value);
        end

        function obj = set.Subject(obj,value)
            for i=1:obj.nSession
                obj.DataAll{i}.Subject = char(value);
            end
        end

        function value = get.Strain(obj)
            value = unique(string(cellfun(@(x)x.Strain,obj.DataAll,'UniformOutput',false)));
            mustBeTextScalar(value);
            value = char(value);
        end

        function obj = set.Strain(obj,value)
            for i=1:obj.nSession
                obj.DataAll{i}.Strain = char(value);
            end
        end

        function value = get.Group(obj)
            value = unique(string(cellfun(@(x)x.Group,obj.DataAll,'UniformOutput',false)));
            mustBeTextScalar(value);
            value = char(value);
        end

        function obj = set.Group(obj,value)
            for i=1:obj.nSession
                obj.DataAll{i}.Group = char(value);
            end
        end
        
        function value = get.nSession(obj)
            value = length(obj.DataAll);
        end

        function value = get.Sessions(obj)
            value = cellfun(@(x)x.Session,obj.DataAll,'UniformOutput',true);
        end

        function obj = set.Sessions(obj,value)
            for i=1:obj.nSession
                obj.DataAll{i}.Session = value(i);
            end
        end

        function value = get.Dates(obj)
            value = cellfun(@(x)x.Date,obj.DataAll,'UniformOutput',true);
        end

        function value = get.Weights(obj)
            value = cellfun(@(x)x.Weight,obj.DataAll,'UniformOutput',true);
        end

        function obj = set.Weights(obj,value)
            for i=1:obj.nSession
                obj.DataAll{i}.Weight = value(i);
            end
        end
            
        function value = get.Tasks(obj)
            value = cellfun(@(x)x.Task,obj.DataAll,'UniformOutput',false);
        end

        function value = get.Experiments(obj)
            value = cellfun(@(x)x.Experiment,obj.DataAll,'UniformOutput',false);
        end
        
        function obj = set.Experiments(obj,value)
            for i=1:obj.nSession
                obj.DataAll{i}.Experiment = value{i}; % string{i}
            end
        end

        function value = get.nTrial(obj)
            value = cellfun(@(x)x.nTrial,obj.DataAll,'UniformOutput',true);
        end

        function value = get.TableAll(obj)
            value = cell(1,obj.nSession);
            for i=1:obj.nSession
                value{i} = obj.DataAll{i}.Table;
            end
        end

        function value = get.TBT(obj)
            value = table;
            for i=1:obj.nSession
                T = obj.TableAll{i};
                value = [value;T];
            end
        end

        function value = get.SBS(obj)
            value = table;
            for i=1:obj.nSession
                data = obj.TableAll{i};
                stat = calIndivStat(data);
                value = [value;stat];
            end
        end
        
        function value = get.EBE(obj)
            value = table;
            uniExp = unique(obj.Experiments);
            for i=1:length(uniExp)
                data = obj.TBT(obj.TBT.Experiment==uniExp{i},:);
                stat = calIndivStat(data,true,'ifDistr',true);
                value = [value;stat];
            end
%             value = table2struct(value);
        end

        function value = get.SaveName(obj)
            if isempty(obj.Protocol)
                value = append('BClassIndiv_',upper(obj.Subject),'_',...
                    num2str(min(obj.Dates)),'-',num2str(max(obj.Dates)));
            else
                value = append('BClassIndiv_',upper(obj.Subject),'_',...
                    obj.Protocol);
            end
        end

        function save(obj, savepath)
            arguments
                obj
                savepath = pwd
            end
            [~,~] = mkdir(savepath);
            save(fullfile(savepath,obj.SaveName),'obj');
            writetable(obj.TBT,fullfile(savepath,append(obj.SaveName,'.csv')));
        end

        function r = print(obj, savename, varargin)
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
            if isempty(savename)
                savename = obj.SaveName;
            else
                savename = obj.SaveName + "_" + savename;
            end
            [~,~] = mkdir(targetDir);
            savename = fullfile(targetDir,savename);
            saveas(hf, savename, 'fig');
%             export_fig(hf,savename,'-png','-eps');
            print(hf,'-dpng', savename);
            exportgraphics(hf,append(savename,'.eps'),'ContentType','vector');
            r = 1;
        end


        function fig = plot(obj,plotRange,options)
            arguments
                obj
                plotRange = []
%                 options.plotType char {mustBeMember(options.plotType,{'DayByDay','Progress','CompExp'})} = 'DayByDay'
                options.plotType char {mustBeMember(options.plotType,{'DayByDay','Progress','CompExp', 'CompSes'})} = 'DayByDay'
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
                case 'progress'
                    fig = progressPlot(Obj);
                case 'compexp'
                    fig = compExpPlot(Obj, options.expStr);
                case 'compses'
                    fig = compSesPlot(Obj, options.slctSession, options.expStr);
            end

            function h = learningPlot(Obj)
                tbt = Obj.TBT;
                sbs = Obj.SBS;

                if any(contains(unique(tbt.Task),{'Wait1'}))
                    rtLim = [0,2];
                else
                    rtLim = [0,0.6];
                end
                if any(contains(unique(tbt.Task),'3FPs'))
                    plot3FP = true;
                else
                    plot3FP = false;
                end
                if isempty(options.figSize)
                    figSize = [9 16];
                else
                    figSize = options.figSize;
                end
                
                % TrialNum & dark ratio
                g(1,1) = gramm('x',cellstr(sbs.DateTime,'MMdd'),'y',sbs.nTrial,'color',sbs.rTrial);
                g(1,1).facet_grid(cellstr(sbs.TrialType), cellstr(sbs.Task),'scale','free_x','space','free_x');
                g(1,1).geom_point(); g(1,1).set_point_options('base_size',6);
                g(1,1).geom_line();  g(1,1).set_line_options('base_size',2);
                g(1,1).axe_property('ylim',[0 400],'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'off',...
                    'tickdir','out');
                g(1,1).set_names('x',{}, 'y', 'Trials','column', '','color','Trial%');
                g(1,1).set_continuous_color('colormap','copper','CLim',[0,1]);
                g(1,1).set_order_options('column',0,'x',0);
                g(1,1).set_layout_options('Position',[0 0.87 0.9 0.13],'legend_position',[0.89 0.815 0.1 0.1]);
                % Performance
                SBSp = stack(sbs,{'Cor','Pre','Late'});
                g(2,1) = gramm('X', cellstr(SBSp.DateTime,'MMdd'), 'Y',SBSp.Cor_Pre_Late, 'color',SBSp.Cor_Pre_Late_Indicator);
                g(2,1).facet_grid(cellstr(SBSp.TrialType), cellstr(SBSp.Task), 'scale', 'free_x','space','free_x', 'column_labels', false);
                g(2,1).geom_hline('yintercept',0.7,'style','k:');
                g(2,1).geom_point(); g(2,1).set_point_options('base_size',6);
                g(2,1).geom_line();  g(2,1).set_line_options('base_size',2);
                g(2,1).axe_property('ylim', [0 1], 'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'off',...
                    'tickdir','out');
                g(2,1).set_names('x',{}, 'y', 'Performance','color','');
                g(2,1).set_color_options('map',cCPL,'n_color',3,'n_lightness',1);
                g(2,1).set_order_options('column',0,'x',0,'color',{'Cor','Pre','Late'});
                g(2,1).set_layout_options('Position',[0 0.57 0.9 0.3],'legend_position',[0.89 0.74 0.08 0.1]);
                % RT
                g(3,1) = gramm('X',cellstr(tbt.DateTime,'MMdd'),'Y',tbt.RT,'subset',contains(tbt.Outcome,'Cor'));
                g(3,1).facet_grid(cellstr(tbt.TrialType), cellstr(tbt.Task), 'scale', 'free_x','space','free_x', 'column_labels',false);
                % g(3,1).stat_violin('half',true,'normalization','area','fill','edge','dodge',0,'width',0.7);
                g(3,1).stat_boxplot('width', 0.5,'notch',false);
                g(3,1).set_point_options('base_size',2);
                g(3,1).set_color_options('map',cBlue,'n_color',1,'n_lightness',1);
                g(3,1).axe_property('ylim', rtLim, 'xticklabels', {},'XTickLabelRotation', 90, 'XGrid', 'on', 'YGrid', 'off',...
                    'tickdir','out');
                g(3,1).set_names('x',{}, 'y', 'RT(s)','column', '','color','FP(s)');
                g(3,1).set_order_options('column',0,'x',0);
                g(3,1).set_layout_options('Position',[0 0.37 0.9 0.2]);
                % Trial2Criterion or Performance by 3FP
                if ~plot3FP
                    % pre-processed
                    SBS_t = stack(sbs,{'t2mFP','t2mRW'});
                    SBS_c = stack(sbs,{'maxFP','minRW'});
                    SBS_t.t2mFP_t2mRW_Indicator = categorical(erase(cellstr(SBS_t.t2mFP_t2mRW_Indicator),{'t2m'}));
                    SBS_c.maxFP_minRW_Indicator = categorical(erase(cellstr(SBS_c.maxFP_minRW_Indicator),{'min','max'}));
                    
                    g(4,1) = gramm('X',cellstr(SBS_c.DateTime,'MMdd'),'Y',SBS_c.maxFP_minRW,...
                        'linestyle',SBS_c.maxFP_minRW_Indicator);
                    g(4,1).facet_grid(cellstr(SBS_c.TrialType), cellstr(SBS_c.Task), 'scale', 'free_x','space','free_x', 'column_labels',false);
                    g(4,1).axe_property('ylim', [0.5 2], 'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'off','tickdir','out');
                    g(4,1).set_names('x',{}, 'y','BestPerf','column','','color','','linestyle','');
                    g(4,1).geom_point(); g(4,1).set_point_options('base_size',6);
                    g(4,1).geom_line();  g(4,1).set_line_options('base_size',2,'style',{'-',':'});
                    g(4,1).set_color_options('map',cGray,'n_color',1,'n_lightness',1);
                    g(4,1).set_order_options('column',0,'x',0,'line',{'FP','RW'});
                    g(4,1).set_layout_options('Position',[0 0.2 0.9 0.17],'legend_position',[0.89,0.28,0.24,0.1]);
                    
                    g(5,1) = gramm('X',cellstr(SBS_t.DateTime,'MMdd'),'Y',SBS_t.t2mFP_t2mRW,...
                        'linestyle',SBS_t.t2mFP_t2mRW_Indicator);
                    g(5,1).facet_grid(cellstr(SBS_t.TrialType), cellstr(SBS_t.Task), 'scale', 'free_x','space','free_x', 'column_labels',false);
                    g(5,1).axe_property('ylim', [40 200], 'XTickLabelRotation', 90, 'XGrid', 'on', 'YGrid', 'off','tickdir','out');
                    g(5,1).set_names('x',{}, 'y','Trials2BestPerf','column','','color','','linestyle','');
                    g(5,1).geom_point(); g(5,1).set_point_options('base_size',6);
                    g(5,1).geom_line();  g(5,1).set_line_options('base_size',2,'style',{'-',':'});
                    g(5,1).set_color_options('map',cGray,'n_color',1,'n_lightness',1);
                    g(5,1).set_order_options('column',0,'x',0,'line',{'FP','RW'});
                    g(5,1).set_layout_options('Position',[0 0.0 0.9 0.2],'legend_position',[0.89,0.12,0.1,0.1]);
                    g(5,1).no_legend;
                else
                    SBS_3c = stack(splitvars(sbs,'Cor_FP','NewVariableNames',{'CorS','CorM','CorL'}),{'CorS','CorM','CorL'});
                    g(4,1) = gramm('X',cellstr(SBS_3c.DateTime,'MMdd'),'Y',SBS_3c.CorS_CorM_CorL,...
                        'linestyle',SBS_3c.CorS_CorM_CorL_Indicator,'color',SBS_3c.CorS_CorM_CorL_Indicator);
                    g(4,1).facet_grid(cellstr(SBS_3c.TrialType), cellstr(SBS_3c.Task), 'scale', 'free_x','space','free_x', 'column_labels',false);
                    g(4,1).geom_point(); g(4,1).set_point_options('base_size',4);
                    g(4,1).geom_line();  g(4,1).set_line_options('base_size',1.5,'style',{':','-.','-'});
                    g(4,1).geom_hline('yintercept',0.7,'style','k:');
                    g(4,1).axe_property('ylim', [0 1], 'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'off','tickdir','out');
                    g(4,1).set_names('x',{}, 'y','Accuracy','column','','color','','linestyle','FP');
                    g(4,1).set_color_options('map',c3FPs,'n_color',3,'n_lightness',1);
                    g(4,1).set_order_options('column',0,'x',0,'linestyle',{'CorS','CorM','CorL'},'color',{'CorS','CorM','CorL'});
                    g(4,1).set_layout_options('Position',[0 0.20 0.9 0.17],'legend_position',[0.89,0.28,0.1,0.1]);
                    g(4,1).no_legend;
                    
                    g(5,1) = gramm('X',cellstr(tbt.DateTime,'MMdd'),'Y',tbt.RT,...
                        'color',tbt.FP,...
                        'subset',(tbt.FP==0.5 | tbt.FP==1.0 | tbt.FP==1.5) & tbt.Outcome=="Cor");
                    g(5,1).facet_grid(cellstr(tbt.TrialType), cellstr(tbt.Task), 'scale', 'free_x','space','free_x', 'column_labels', false);
                    g(5,1).stat_summary('type', @(x)compute_stat_summary(x,'quartile'),'geom',{'errorbar','point'},'dodge',0.6);
                    g(5,1).set_point_options('base_size',3);
                    g(5,1).set_line_options('base_size',1.2);
                    g(5,1).axe_property('ylim', [0 0.6], 'XGrid', 'on', 'YGrid', 'off','XTickLabelRotation',90, 'tickdir','out');
                    g(5,1).set_names('x',{}, 'y', 'RT(s) Quartile','color','FP(s)');
                    g(5,1).set_color_options('map',c3FPs,'n_color',3,'n_lightness',1);
                    g(5,1).set_order_options('column',0,'x',0,'color',1);
                    g(5,1).set_layout_options('Position',[0 0.0 0.9 0.2],'legend_position',[0.89,0.09,0.1,0.1]);
                end
                g.set_title(append(Obj.Subject,': Learning Curve'));
                g.set_text_options('base_size',fontAxesSz,'label_scaling',fontLablSz./fontAxesSz,...
                    'legend_scaling',1.1,'legend_title_scaling',1.2,...
                    'facet_scaling',fontTitlSz/fontAxesSz,...
                    'title_scaling',fontTitlSz/fontAxesSz,'big_title_scaling',fontTitlSz/fontAxesSz+0.1);
                
                h = figure(obj.FigNum);clf(h);
                set(h,'Name','LearningFig','unit','centimeters',...
                    'position',[1 1 figSize],'paperpositionmode','auto');
                g.draw();

                % modify
                hp = findobj(g(3,1).facet_axes_handles,'Type','Line');
                set(hp,'MarkerSize',2);
            end

            function h = progressPlot(Obj)
                % figure position & axes
                xstart = 1.5; ystart = 1.3;
                xsep = 0.5; ysep = 1.2;
                
                if isempty(options.figSize)
                    singleSz = [3, 3];
                else
                    singleSz = options.figSize;
                end
                axesSz = [(singleSz(1)+xsep).*Obj.nSession-xsep singleSz(2)];
                figPos = [2 2 ...
                    xstart+axesSz(1)+xsep...
                    ystart+(axesSz(2)+ysep).*3];
                tickLen = [0.15 0.25]; % cm
                % Merge time as x axis
                sepSess = 300;
                tbt = Obj.TBT;
                [~,ia,ic] = unique(tbt.Session,'last');
                curTime = cumsum(tbt.TimeElapsed(ia)+sepSess);
                timeSep = (curTime - sepSess./2)./60;
                curTime = [0;curTime(1:end-1)];
                tem = tbt.TimeElapsed; % TimeElapsedMerge
                for i=1:Obj.nSession
                    tem(ic==i) = tem(ic==i) + curTime(i);
                end
                tem = tem./60; % min
                tbt = addvars(tbt,tem,'After','TimeElapsed','NewVariableNames','TimeElapsedMerge');
                % index
                sessName = unique(tbt.Session);
                idxCor = tbt.Outcome == "Cor";
                idxPre = tbt.Outcome == "Pre";
                idxLate = tbt.Outcome == "Late";
                idxW1 = tbt.Task == "Wait1";
                idxW2 = tbt.Task == "Wait2";
                % limit
                tLim = [0 max(tbt.TimeElapsedMerge)+sepSess/60];
                htLim = [0 2500];
                rtLim = [0 1000];
                winSz = 30;
                stepSz = 15;
                
                %
                h = figure(obj.FigNum);clf(h);
                set(h, 'unit', 'centimeters', 'position',figPos,...
                    'paperpositionmode', 'auto', 'color', 'w')
                uicontrol(h,'Style', 'text', 'units', 'centimeters',...
                        'position', [figPos(3)/2-4,figPos(4)-ysep*0.66,8,0.5],...
                        'string', append(Obj.Subject,' / ', num2str(min(Obj.Dates)),'-',num2str(max(Obj.Dates))),...
                        'fontsize', fontTitlSz, 'fontweight', 'bold','backgroundcolor', [1 1 1]);
                
                % Hold time - Time
                ha1 = axes;
                set(ha1, 'units', 'centimeters', 'position', [xstart,ystart,axesSz],...
                    'nextplot', 'add', 'ylim', htLim, 'xlim', tLim, 'tickdir','out',...
                    'TickLength', [tickLen(1)/max(axesSz),tickLen(2)/max(axesSz)], 'fontsize',fontAxesSz);
                xlabel('Time (min)','FontSize',fontLablSz)
                ylabel('Hold time (ms)','FontSize',fontLablSz)
                
                if ~isempty(idxW1)
                    fillCriterion(tbt(idxW1,:),[1.5,2],htLim,cCyan)
                end
                if ~isempty(idxW2)
                    fillCriterion(tbt(idxW2,:),[1.5,0.6],htLim,cCyan)
                end
                line([timeSep timeSep],htLim,'color','k','linewidth',1,'linestyle','--');
                modiHT = tbt.HT.*1000; modiHT(modiHT>htLim(2)) = htLim(2);
                line([tbt.TimeElapsedMerge,tbt.TimeElapsedMerge],[htLim(1),htLim(1)+diff(htLim)/10],...
                    'color',cBlue,'linewidth',0.4);
                scatter(tbt.TimeElapsedMerge(idxCor),modiHT(idxCor),15,cCPL(1,:),...
                    'MarkerEdgeAlpha',0.7,'LineWidth',1);
                scatter(tbt.TimeElapsedMerge(idxPre),modiHT(idxPre),15,cCPL(2,:),...
                    'MarkerEdgeAlpha',0.7,'LineWidth',1);
                scatter(tbt.TimeElapsedMerge(idxLate),modiHT(idxLate),15,cCPL(3,:),...
                    'MarkerEdgeAlpha',0.7,'LineWidth',1);

                % Sliding RT - Time
                ha2 = axes;
                set(ha2, 'units', 'centimeters', 'position', [xstart,ystart+(axesSz(2)+ysep),axesSz],...
                    'nextplot', 'add', 'ylim', rtLim, 'xlim', tLim,'tickdir','out',...
                    'TickLength', [tickLen(1)/max(axesSz),tickLen(2)/max(axesSz)],'fontsize',fontAxesSz);
                xlabel('Time (min)','FontSize',fontLablSz);
                ylabel('Reaction time (ms)','FontSize',fontLablSz);
                
                if ~isempty(idxW1)
                    fillCriterion(tbt(idxW1,:),[1.5,2],htLim,cCyan)
                end
                if ~isempty(idxW2)
                    fillCriterion(tbt(idxW2,:),[1.5,0.6],htLim,cCyan)
                end
                modiRT = (tbt.HT - tbt.FP).*1000;
                modiRT(modiRT>rtLim(2)) = rtLim(2);
                modiRT(modiRT<rtLim(1)) = rtLim(1);
                scatter(tbt.TimeElapsedMerge(idxCor),modiRT(idxCor),15,cCPL(1,:),...
                    'MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.5,'LineWidth',0.5);
                scatter(tbt.TimeElapsedMerge(idxLate),modiRT(idxLate),15,cCPL(3,:),...
                    'MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.5,'LineWidth',0.5);
                line([timeSep timeSep],rtLim,'color','k','linewidth',1,'linestyle','--');
                for i=1:length(sessName)
                    idxSess = tbt.Session==sessName(i);
                    T = tbt(idxSess,:);
                
                    rtSess = T.HT - T.FP;
                    rtCL = rtSess; rtCL(T.Outcome=="Pre") = NaN;
                    rtC = rtSess; rtC(T.Outcome=="Pre" | T.Outcome=="Late") = NaN;
                    
                    [xc,yc] = calMovAVG(T.TimeElapsedMerge,rtC,...
                        'winSize',winSz,'stepSize',stepSz,'tarStr','Cor','avgMethod','mean');
                    lr1 = plot(xc, yc.*1000, 'o', 'linestyle', '-', 'color', 'k', ...
                        'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', 'k',...
                        'markeredgecolor', 'w');
                
                    [xcl,ycl] = calMovAVG(T.TimeElapsedMerge,rtCL,...
                        'winSize',winSz,'stepSize',stepSz,'tarStr','Cor','avgMethod','mean');
                    lr2 = plot(xcl, ycl.*1000, 'o', 'linestyle', '-', 'color', cBrown, ...
                        'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', cBrown,...
                        'markeredgecolor', 'w');
                end
                le2 = legend([lr1 lr2],{'Cor','Cor+Late'},'units','centimeters',...
                    'Position',[xstart+axesSz(1)-singleSz(1)-xsep/2,ystart+axesSz(2)*2+ysep,singleSz(1),0.5],...
                    'Orientation','horizontal','FontSize',fontLablSz);
                legend('boxoff');
                le2.ItemTokenSize(1) = 10;

                % Sliding Performance - Time
                ha3 = axes;
                set(ha3, 'units', 'centimeters', 'position', [xstart,ystart+(axesSz(2)+ysep).*2,axesSz],...
                    'nextplot', 'add', 'ylim', [0 100], 'xlim', tLim,'tickdir','out',...
                    'TickLength', [tickLen(1)/max(axesSz),tickLen(2)/max(axesSz)],'fontsize',fontAxesSz);
                xlabel('Time (min)','FontSize',fontLablSz);
                ylabel('Performance (%)','FontSize',fontLablSz);
                
                if ~isempty(idxW1)
                    fillCriterion(tbt(idxW1,:),[1.5,2],htLim,cCyan)
                end
                if ~isempty(idxW2)
                    fillCriterion(tbt(idxW2,:),[1.5,0.6],htLim,cCyan)
                end
                line([timeSep timeSep],[0 100],'color','k','linewidth',1,'linestyle','--');
                for i=1:length(sessName)
                    idxSess = tbt.Session==sessName(i);
                    [xc,yc] = calMovAVG(tbt.TimeElapsedMerge(idxSess),tbt.Outcome(idxSess),...
                        'winSize',winSz,'stepSize',stepSz,'tarStr','Cor');
                    [xp,yp] = calMovAVG(tbt.TimeElapsedMerge(idxSess),tbt.Outcome(idxSess),...
                        'winSize',winSz,'stepSize',stepSz,'tarStr','Pre');
                    [xl,yl] = calMovAVG(tbt.TimeElapsedMerge(idxSess),tbt.Outcome(idxSess),...
                        'winSize',winSz,'stepSize',stepSz,'tarStr','Late');
                    l1 = plot(xc, yc, 'o', 'linestyle', '-', 'color', cCPL(1,:), ...
                        'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', cCPL(1,:),...
                        'markeredgecolor', 'w');
                    l2 = plot(xp, yp, 'o', 'linestyle', '-', 'color', cCPL(2,:), ...
                        'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', cCPL(2,:),...
                        'markeredgecolor', 'w');
                    l3 = plot(xl, yl, 'o', 'linestyle', '-', 'color', cCPL(3,:), ...
                        'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', cCPL(3,:),...
                        'markeredgecolor', 'w');
                end
                le1 = legend([l1 l2 l3],{'Cor','Pre','Late'},'units','centimeters',...
                    'Position',[xstart+axesSz(1)-singleSz(1)-xsep/2,ystart+axesSz(2)*3+ysep*2,singleSz(1),0.5],...
                    'Orientation','horizontal','FontSize',fontLablSz);
                legend('boxoff');
                le1.ItemTokenSize(1) = 10;
                
                function fillCriterion(T,criterion,yLim,color)
                    % criterion = [1.5,2];
                    idxCri = abs((T.FP-criterion(1)))<1E-4 & abs((T.RW-criterion(2)))<1E-4;
                    diffCri = diff([0;idxCri;0]);
                    prdCri = [find(diffCri==1),find(diffCri==-1)-1];
                    for i=1:size(prdCri,1)
                        fill([repelem(T.TimeElapsedMerge(prdCri(i,1)),2),repelem(T.TimeElapsedMerge(prdCri(i,2)),2)],...
                            [yLim(1),yLim(2),yLim(2),yLim(1)],color,'EdgeColor','none','FaceAlpha',0.1);
                    end
                end
            end

            function h = compExpPlot(Obj, expStr)

                % PDF & CDF: use ExperimentByExperiment date, merge sessions
                ebe = Obj.EBE;
                if isempty(expStr)
                    expall = unique(ebe.Experiment);
                    if length(expall) == 1
                        error('Only one "Experiment" condition');
                    elseif length(expall) == 3 && ~isempty(find(expall == '', 1))
                        ebe(idxNan) = [];
                    elseif length(expall) == 2
                        expStr = expall;
                    else
                        error('More than two ~nan "Experiment" conditions');
                    end
                else
                    if length(expStr) ~= 2
                        error('Check input "Experiment" of @compExpPlot');
                    end
                    ebe = ebe(arrayfun(@(x) find(ebe.Experiment == x), expStr, 'UniformOutput', true), :);
                end
                % 
                figPos = [2 2 10 10];
                h = figure(obj.FigNum);clf(h);
                set(h, 'unit', 'centimeters', 'position', figPos,...
                    'paperpositionmode', 'auto', 'color', 'w');

                a1 = axes;
                a1x = 1.5; a1y = 1.5;
                a1width = 5; a1h8 = 5;
                
                set(a1, 'units', 'centimeters', 'position', [a1x a1y a1width a1h8],...
                    'nextplot', 'add', 'ylim', [0 3.5], 'xlim', [0 2.5],'tickdir','out');
                xlabel('HoldTime (sec)', 'FontSize',fontLablSz);
                ylabel('PDF (%)', 'FontSize',fontLablSz);
                htpdf1_exp1 = plot(0.025:0.05:2.475, ebe.HTpdf_FP1(1,:), 'Color', cExp(1,:), 'LineStyle', '-', 'LineWidth', 1.0);
                htpdf1_exp2 = plot(0.025:0.05:2.475, ebe.HTpdf_FP1(2,:), 'Color', cExp(2,:), 'LineStyle', '-', 'LineWidth', 1.0);
                htpdf2_exp1 = plot(0.025:0.05:2.475, ebe.HTpdf_FP2(1,:), 'Color', cExp(1,:), 'LineStyle', '-', 'LineWidth', 1.8);
                htpdf2_exp2 = plot(0.025:0.05:2.475, ebe.HTpdf_FP2(2,:), 'Color', cExp(2,:), 'LineStyle', '-', 'LineWidth', 1.8);
                htpdf3_exp1 = plot(0.025:0.05:2.475, ebe.HTpdf_FP3(1,:), 'Color', cExp(1,:), 'LineStyle', '-', 'LineWidth', 2.5);
                htpdf3_exp2 = plot(0.025:0.05:2.475, ebe.HTpdf_FP3(2,:), 'Color', cExp(2,:), 'LineStyle', '-', 'LineWidth', 2.5);
%                 legend([htpdf2_exp1 htpdf2_exp2], ebe.Experiment(1:2), 'Box', 'off', 'Location', 'northeast', 'FontSize', fontLablSz);

                a2 = axes;
                a2x = a1x + a1width + 1.5; a2y = a1y;
                a2width = a1width; a2h8 = a1h8;
                set(a2, 'units', 'centimeters', 'position', [a2x a2y a2width a2h8],...
                    'nextplot', 'add', 'ylim', [0 1], 'xlim', [0 2.5],'tickdir','out');
                xlabel('HoldTime (sec)', 'FontSize', fontLablSz);
                ylabel('CDF (%)', 'FontSize', fontLablSz);
                htcdf1_exp1 = plot(0.025:0.05:2.475, ebe.HTcdf_FP1(1,:), 'Color', cExp(1,:), 'LineStyle', '-', 'LineWidth', 1.0);
                htcdf1_exp2 = plot(0.025:0.05:2.475, ebe.HTcdf_FP1(2,:), 'Color', cExp(2,:), 'LineStyle', '-', 'LineWidth', 1.0);
                htcdf2_exp1 = plot(0.025:0.05:2.475, ebe.HTcdf_FP2(1,:), 'Color', cExp(1,:), 'LineStyle', '-', 'LineWidth', 1.8);
                htcdf2_exp2 = plot(0.025:0.05:2.475, ebe.HTcdf_FP2(2,:), 'Color', cExp(2,:), 'LineStyle', '-', 'LineWidth', 1.8);
                htcdf3_exp1 = plot(0.025:0.05:2.475, ebe.HTcdf_FP3(1,:), 'Color', cExp(1,:), 'LineStyle', '-', 'LineWidth', 2.5);
                htcdf3_exp2 = plot(0.025:0.05:2.475, ebe.HTcdf_FP3(2,:), 'Color', cExp(2,:), 'LineStyle', '-', 'LineWidth', 2.5);
                legend(a2, [htcdf2_exp1 htcdf2_exp2], ebe.Experiment(1:2), 'Units', 'centimeters', ...
                    'Box', 'off', 'Position', [a2x+a2width-1 a2y 1 1], 'FontSize', fontLablSz);
                
                % Error pattern scatter plot: use SessionBySession data, divided by exp.
                sbs = Obj.SBS;
                sbs_exp_idx = arrayfun(@(x) find(sbs.Experiment == x), expStr, 'UniformOutput', false);
                sbs_exp{1} = sbs(sbs_exp_idx{1}, :);
                sbs_exp{2} = sbs(sbs_exp_idx{2}, :);

                b1 = axes;
                b1x = a1x; b1y = a1y + a1h8 + 1.5;
                b1width = 4; b1h8 = 4;
                set(b1, 'units', 'centimeters', 'position', [b1x b1y b1width b1h8],...
                    'nextplot', 'add', 'ylim', [0 0.3], 'xlim', [0 0.3], ...
                    'tickdir', 'out', 'XTick', 0:0.1:0.3, 'YTick', 0:0.1:0.3, 'XTickLabel', 0:10:30, 'YTickLabel', 0:10:30);
                xlabel('Premature (%)', 'FontSize', fontLablSz);
                ylabel('Late (%)', 'FontSize', fontLablSz);
                sc1_error1 = scatter(sbs_exp{1}.Pre, sbs_exp{1}.Late, 'MarkerFaceColor', cExp(1, :), 'MarkerEdgeColor', 'none');
                sc1_error1_mean = errorbar(mean(sbs_exp{1}.Pre), mean(sbs_exp{1}.Late), ...
                    sem(sbs_exp{1}.Late), sem(sbs_exp{1}.Late), ...  % y neg, y pos
                    sem(sbs_exp{1}.Pre), sem(sbs_exp{1}.Pre), ...    % x neg, x pos
                    'o', 'MarkerFaceColor', cExp(1, :), 'MarkerEdgeColor', cRed, 'CapSize', 3, 'Color', cRed, 'LineWidth', 1.2);      
                sc1_error2 = scatter(sbs_exp{2}.Pre, sbs_exp{2}.Late, 'MarkerFaceColor', cExp(2, :), 'MarkerEdgeColor', 'none');
                sc1_error2_mean = errorbar(mean(sbs_exp{2}.Pre), mean(sbs_exp{2}.Late), ...
                    sem(sbs_exp{2}.Late), sem(sbs_exp{2}.Late), ...  % y neg, y pos
                    sem(sbs_exp{2}.Pre), sem(sbs_exp{2}.Pre), ...    % x neg, x pos
                    'o', 'MarkerFaceColor', cExp(2, :), 'MarkerEdgeColor', cRed, 'CapSize', 3, 'Color', cRed, 'LineWidth', 1.2);   
                line([0 100], [0 100], 'LineStyle', ':', 'Color', cGray, 'LineWidth', 1.5);
                legend(b1, [sc1_error1 sc1_error2], ebe.Experiment(1:2), 'Units', 'centimeters', ...
                    'Box', 'off', 'Position', [b1x+b1width-0.5 b1y+b1h8-1 1 1], 'FontSize', fontLablSz);

                % Injection scatter plot: use SBS data
                b2 = axes;
                b2x = a2x; b2y = b1y;
                b2width = 4; b2h8 = 4;
                set(b2, 'units', 'centimeters', 'position', [b2x b2y b2width b2h8],...
                    'nextplot', 'add', 'ylim', [0 1], 'xlim', [0 1], ...
                    'tickdir', 'out', 'XTick', [0 0.5 1], 'YTick', [0 0.5 1], 'XTickLabel', [0 0.5 1.0], 'YTickLabel', [0 0.5 1.0]);
                xlabel(expStr(1), 'FontSize', fontLablSz);
                ylabel(expStr(2), 'FontSize', fontLablSz);

                line([0 1], [0 1], 'LineStyle', ':', 'Color', cGray, 'LineWidth', 1.5);
                sc2_pre = expErrorbar(sbs_exp, 'Pre', cRed);
                sc2_late = expErrorbar(sbs_exp, 'Late', cOrange);
                sc2_dark = expErrorbar(sbs_exp, 'rTrial', cGray);
                sc2_rt = expErrorbar(sbs_exp, 'RT', cGreen);
                sc2_mt = expErrorbar(sbs_exp, 'MT', cBlue);
                legend([sc2_pre sc2_late sc2_dark sc2_rt sc2_mt], ["Pre", "Late", "Dark", "RT", "MT"], ...
                    'Units', 'centimeters', 'Box', 'off', 'Position', [b2x+b2width+0.2 b2y+b2h8-1.5 1 1], 'FontSize', fontLablSz);


                xfinal = a2x + a2width + 1.5;
                yfinal = b2y + b2h8 + 1.2;
                set(h, 'position', [2 2 xfinal yfinal]);
                uicontrol(h, 'Style', 'text', 'units', 'centimeters',...
                    'position', [xfinal/2-4,yfinal-0.8, 8, 0.5],...
                    'string', append(Obj.Subject, ' / ', expStr(1), ' vs. ', expStr(2)),...
                    'fontsize', fontTitlSz, 'fontweight', 'bold','backgroundcolor', [1 1 1]);

                function err = expErrorbar(data, field, color)

                    if nargin == 2
                        color = 'k';
                    end
                    field = string(field);

                    tempdata = eval("normalize([data{1}."+field+"; data{2}."+field+"], 'range')");
                    normdata{1} = tempdata(1:height(data{1}));
                    normdata{2} = tempdata((height(data{1})+1):end);

                    mMethod = "mean"; eMethod = "sem";

                    xdata = eval(mMethod+"(normdata{1})");
                    ydata = eval(mMethod+"(normdata{2})");
                    xerr = eval(eMethod+"(normdata{1})");
                    yerr = eval(eMethod+"(normdata{2})");

                    err = errorbar(xdata, ydata, yerr, yerr, xerr, xerr, ...
                        'o', 'CapSize', 3, 'Color', color, 'LineWidth', 1.2); 
                end
                


            end

            function h = compSesPlot(Obj, slctSession, expStr)

                newObj = Obj;
                for j = 1:length(newObj.Experiments)
                    [idx, ~] = find(newObj.Sessions(j) == slctSession);
                    if isempty(idx)
                        newObj.Experiments{j} = '';
                    else
                        newObj.Experiments{j} = char(expStr(idx));
                    end
                end
                h = compExpPlot(newObj, expStr);

            end
        end

    end
end

function mustBeMemberi(value,S)
    val = lower(value);
    s = lower(S);
    mustBeMember(val,s)
end

function stat = calIndivStat(data,multiSession,opts)
% calculate the STATs of one subject
% STATs of 1 session or across sessions (but in the same Experiment & Task)
    arguments
        data
        multiSession = false
        opts.fplist = []
        opts.ifDistr = false
        opts.edges_HT = 0:0.05:2.5 % Hold time (All trials)
        opts.edges_RT = 0:0.025:0.6 % Reaction time (Cor)
        opts.edges_RelT = 0:0.05:1 % Release time (Cor+Late)
        opts.smoWin = 8 % smoothdata('gaussian')
    end
    if isempty(opts.fplist)
        fplist = unique(data.FP); % sorted from small to big
        if length(fplist) > 3 || length(fplist) == 1
            fplist = [0.5 1.0 1.5];
        end
    else
        fplist = opts.fplist;
    end
    
    stat = table;

    typename = unique(data.TrialType);
    for j=1:length(typename)
        t = struct;
        
        t.Subject = data.Subject(1);
        t.Group = data.Group(1);
        t.Experiment = data.Experiment(1);
        t.Task = data.Task(1);
        if ~multiSession
            t.Session = data.Session(1);
            t.Date = data.Date(1);
            t.DateTime = data.DateTime(1);
        else
            t.nSession = length(unique(data.Session));
        end
        
        t.TrialType = typename(j);
        tdata = data(data.TrialType==t.TrialType,:);
        
        if ~multiSession
            t.nBlock = length(unique(tdata.BlockNum));
        else
            nBlk = 0;
            uniSession = unique(tdata.Session);
            for iBlk=1:length(uniSession)
                nBlk = nBlk + length(unique(tdata(tdata.Session==uniSession(iBlk),:).BlockNum));
            end
        end
        
        t.nTrial = length(tdata.iTrial);
        t.Dark = sum(tdata.DarkTry);
        t.rTrial = t.nTrial./(t.Dark+t.nTrial);

        idxCor = contains(tdata.Outcome,'Cor');
        idxPre = contains(tdata.Outcome,'Pre');
        idxLate = contains(tdata.Outcome,'Late');
        t.Cor  = sum(idxCor)./t.nTrial;
        t.Pre  = sum(idxPre)./t.nTrial;
        t.Late = sum(idxLate)./t.nTrial;
        t.PreTendency = (t.Pre-t.Late)./(t.Pre+t.Late);

        if ~multiSession
            t.maxFP = max(tdata.FP);
            t.t2mFP = find(tdata.FP==t.maxFP,1,'first');
            t.minRW = min(tdata.RW);
            t.t2mRW = find(tdata.RW==t.minRW,1,'first');
        end
        
        t.HT = median(rmoutliers(tdata.HT,'quartiles'),'omitnan');
        rt = calRT(tdata.HT(idxCor), tdata.FP(idxCor),...
            'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
        t.RT = rt.median;
        relt = calRT(tdata.HT(idxCor|idxLate), tdata.FP(idxCor|idxLate),...
            'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
        t.RelT = relt.median;
        t.MT = median(rmoutliers(tdata.MT,'quartiles'),'omitnan');

        % Stat in each FP
        corFP = []; preFP = []; lateFP = [];
        htFP = []; rtFP = []; reltFP = []; mtFP = [];
        for iFP = 1:length(fplist)
            if iFP == 1
                idxThis = (tdata.FP>=0) & (tdata.FP<=fplist(iFP));
            else
                idxThis = (tdata.FP<=fplist(iFP)) & (tdata.FP>fplist(iFP-1));
            end
            if sum(idxThis) == 0
                corFP = [corFP, 0];
                preFP = [preFP, 0];
                lateFP = [lateFP, 0];
                htFP = [htFP, 0];
                rtFP = [rtFP, 0];
                reltFP = [reltFP, 0];
                mtFP = [mtFP, 0];
            else
                corFP = [corFP, sum(idxCor & idxThis)./sum(idxThis)];
                preFP = [preFP, sum(idxPre & idxThis)./sum(idxThis)];
                lateFP = [lateFP, sum(idxLate & idxThis)./sum(idxThis)];
                htFP = [htFP, median(rmoutliers(tdata.HT(idxThis),'quartiles'),'omitnan')];
                rtt = calRT(tdata.HT(idxCor & idxThis), tdata.FP(idxCor & idxThis),...
                'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
                rtFP = [rtFP, rtt.median];
                reltt = calRT(tdata.HT((idxCor|idxLate)&idxThis), tdata.FP((idxCor|idxLate)&idxThis),...
                'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
                reltFP = [reltFP, reltt.median];
                mtFP = [mtFP, median(rmoutliers(tdata.MT(idxThis),'quartiles'),'omitnan')];
            end
        end
        t.Cor_FP = corFP;
        t.Pre_FP = preFP;
        t.Late_FP = lateFP;
        t.PreTendency_FP = (preFP-lateFP)./(preFP+lateFP);
        t.HT_FP = htFP;
        t.RT_FP = rtFP;
        t.ReltT_FP = reltFP;
        t.MT_FP = mtFP;

        % calculate distribution
        if opts.ifDistr
            t.HTpdf = smoothdata(histcounts(tdata.HT,...
                opts.edges_HT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
            t.RTpdf = smoothdata(histcounts(tdata.RT(idxCor),...
                opts.edges_RT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
            t.RelTpdf = smoothdata(histcounts(tdata.HT(idxCor|idxLate)-tdata.FP(idxCor|idxLate),...
                opts.edges_RelT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
            t.HTcdf = smoothdata(histcounts(tdata.HT,...
                opts.edges_HT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
            t.RTcdf = smoothdata(histcounts(tdata.RT(idxCor),...
                opts.edges_RT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
            t.RelTcdf = smoothdata(histcounts(tdata.HT(idxCor|idxLate)-tdata.FP(idxCor|idxLate),...
                opts.edges_RelT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
            
            for iFP = 1:length(fplist)
                idxThis = tdata.FP==fplist(iFP);
                
                t.(['HTpdf_FP',num2str(iFP)]) = smoothdata(histcounts(tdata.HT(idxThis),...
                    opts.edges_HT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
                t.(['RTpdf_FP',num2str(iFP)]) = smoothdata(histcounts(tdata.RT(idxCor&idxThis),...
                    opts.edges_RT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
                t.(['RelTpdf_FP',num2str(iFP)]) = smoothdata(histcounts(tdata.HT((idxCor|idxLate)&idxThis)-...
                    tdata.FP((idxCor|idxLate)&idxThis),...
                    opts.edges_RelT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
                t.(['HTcdf_FP',num2str(iFP)]) = smoothdata(histcounts(tdata.HT(idxThis),...
                    opts.edges_HT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
                t.(['RTcdf_FP',num2str(iFP)]) = smoothdata(histcounts(tdata.RT(idxCor&idxThis),...
                    opts.edges_RT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
                t.(['RelTcdf_FP',num2str(iFP)]) = smoothdata(histcounts(tdata.HT((idxCor|idxLate)&idxThis)-...
                    tdata.FP((idxCor|idxLate)&idxThis),...
                    opts.edges_RelT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
            end
        end
        
        stat = [stat;struct2table(t)];
    end
end
