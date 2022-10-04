function BPOD_LearningPlot_PairComp(btAll2d,grpVar)
grpName = unique(grpVar);
if length(grpName)~=2
    error("Grouping variables have invalid number of elements");
end
altMethod = {'mean','median','geomean'};
cenMethod = altMethod{1};
errMethod = 'sem';
%% Data processing
[SBS,TBT] = packData(btAll2d,grpVar,cenMethod);
date_SBS = num2str(SBS.Date);
SBS.Date = string(date_SBS(:,end-3:end));
date_TBT = num2str(TBT.Date);
TBT.Date = string(date_TBT(:,end-3:end));

% SBSbtw = grpstats(removevars(SBS,{'Subject','Date'}),{'Group','Session','Task'},{cenMethod,errMethod});
sbjName = unique(SBS.Subject,'stable');
taskname = unique(SBS.Task,'stable');
if length(taskname)>1
    taskrange = taskname(1) + "-" + taskname(end);
else
    taskrange = taskname;
end
if any(contains(unique(TBT.Task),{'Wait'}))
    ylim_rt = [0,2];
else
    ylim_rt = [0,0.6];
end
if any(contains(unique(TBT.Task),'3FPs'))
    plot3FP = true;
else
    plot3FP = false;
end
%% Plot
cDarkGray = [0.2,0.2,0.2];
cTab10 = tab10(10);
cTab20 = tab20(20);
cGreen = cTab10(3,:);
cGreen5 = Greens(5);cGreen3 = cGreen5(3:end,:);
cRed = cTab10(4,:);
cGray = cTab10(8,:);
cGray2 = cTab20(15:16,:);
cBlue = cTab10(1,:);
cBlue5 = Blues(5);cBlue3 = cBlue5(3:end,:);
cCor_Pre_Late = [cGreen;cRed;cGray];
cPre_Late = cCor_Pre_Late(2:3,:);
% c3FPs = YlOrBr(4);c3FPs = c3FPs(2:end,:);
c3FPs = [cGray;mean([Oranges(1);cGray]);Oranges(1)];

% g(1,1) = gramm('X',SBSbtw.Session,'Y',SBSbtw.mean_nTrial,...
%     'ymin',SBSbtw.mean_nTrial-SBSbtw.sem_nTrial,...
%     'ymax',SBSbtw.mean_nTrial+SBSbtw.sem_nTrial,...
%     'color',SBSbtw.mean_rTrial,'linestyle',cellstr(SBSbtw.Group));
% g(1,1).facet_grid([], cellstr(SBSbtw.Task),'scale', 'free_x','space','free_x','column_labels',true);
% % g(1,1).stat_summary('type',errMethod,'geom',{'area','point'},'setylim',true);
% % g(1,1).geom_interval('geom','errorbar','width',0.6);
% g(1,1).geom_interval('geom','area');
% g(1,1).set_color_options('map',cGray,'n_color',1,'n_lightness',1);
% g(1,1).geom_line(); g(1,1).set_line_options('base_size',2,'styles',{'-',':'});
% g(1,1).geom_point();g(1,1).set_point_options('base_size',6);
% g(1,1).set_continuous_color('colormap','copper','CLim',[0,1]);
% g(1,1).axe_property('xticklabels', {}, 'XGrid', 'on', 'YGrid', 'on');
% g(1,1).set_names('x','', 'y', '','column','','color','','linestyle','');
% g(1,1).set_order_options('column',0,'x',0,'linestyle',1);
% g(1,1).set_layout_options('Position',[0 0.8 0.5 0.2],'legend_position',[0.38 0.77 0.12 0.13]);
% g(1,1).no_legend;

xtick = unique(SBS.Session)';

% Trials
g(1,1) = gramm('x',SBS.Session,'y',SBS.nTrial,'linestyle',cellstr(SBS.Group));
g(1,1).facet_grid([],cellstr(SBS.Task),'scale','free_x','space','free_x');
g(1,1).stat_summary('type',errMethod,'geom',{'area','point'},'dodge',0.4,'setylim',true);
g(1,1).axe_property('xticklabels', {}, 'XGrid', 'on', 'YGrid', 'off','xtick',xtick);
g(1,1).set_names('x','', 'y', 'Trials','column', '','row','','color','','linestyle','');
g(1,1).set_line_options('base_size',2,'styles',{'-',':'});
g(1,1).set_point_options('base_size',5);
g(1,1).set_color_options('map',cDarkGray,'n_color',1,'n_lightness',1);
g(1,1).set_order_options('linestyle',1,'x',0,'column',0);
g(1,1).set_layout_options('Position',[0 0.77 0.46 0.23]);
g(1,1).no_legend;
% TrialRatio
g(2,1) = gramm('x',SBS.Session,'y',SBS.rTrial,'linestyle',cellstr(SBS.Group));
g(2,1).facet_grid([],cellstr(SBS.Task),'scale','free_x','space','free_x','column_labels',false);
g(2,1).stat_summary('type',errMethod,'geom',{'area','point'},'dodge',0.4,'setylim',true);
g(2,1).axe_property('xticklabels', {}, 'XGrid', 'on', 'YGrid', 'off','xtick',xtick);
g(2,1).set_names('x','', 'y', 'Trial Ratio','column', '','row','','color','','linestyle','');
g(2,1).set_line_options('base_size',2,'styles',{'-',':'});
g(2,1).set_point_options('base_size',5);
g(2,1).set_color_options('map',cDarkGray,'n_color',1,'n_lightness',1);
g(2,1).set_order_options('linestyle',1,'x',0,'column',0);
g(2,1).set_layout_options('Position',[0 0.58 0.46 0.19]);
g(2,1).no_legend;
% Cor-Pre-Late
SBScpl = stack(SBS,{'Cor','Pre','Late'});
g(1,2) = gramm('x',SBScpl.Session,'y',SBScpl.Cor_Pre_Late,...
    'color',SBScpl.Cor_Pre_Late_Indicator,'linestyle',cellstr(SBScpl.Group));
g(1,2).facet_grid([], cellstr(SBScpl.Task), 'scale', 'free_x','space','free_x', 'column_labels', true);
g(1,2).geom_hline('yintercept',0.7,'style','k:');
g(1,2).stat_summary('type',errMethod,'geom',{'area','point'},'dodge',0.4);
% g(1,2).geom_point('alpha',0.9); 
g(1,2).set_point_options('base_size',5);
% g(1,2).geom_line();  g(1,2).set_line_options('base_size',2);
g(1,2).set_line_options('base_size',2,'styles',{'-',':'});
g(1,2).axe_property('ylim', [0 1], 'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'off','xtick',xtick);
g(1,2).set_names('x',{}, 'y', 'Performance','color','','column','','linestyle','');
g(1,2).set_color_options('map',cCor_Pre_Late,'n_color',3,'n_lightness',1);
g(1,2).set_order_options('linestyle',1,'column',0,'x',0,'color',{'Cor','Pre','Late'});
g(1,2).set_layout_options('Position',[0.46 0.65 0.46 0.35],'legend_position',[0.92 0.72 0.12 0.2]);

% RT
g(2,2) = gramm('x',SBS.Session,'y',SBS.RT,'linestyle',cellstr(SBS.Group));
g(2,2).facet_grid([],cellstr(SBS.Task),'scale', 'free_x','space','free_x', 'column_labels',false);
g(2,2).stat_summary('type',errMethod,'geom',{'area','point'},'dodge',0.4,'setylim',true);
g(2,2).set_color_options('map',cBlue,'n_color',1,'n_lightness',1);
g(2,2).set_line_options('base_size',2,'styles',{'-',':'});
g(2,2).set_point_options('base_size',5);
g(2,2).axe_property('xticklabels', {}, 'XGrid', 'on', 'YGrid', 'off','xtick',xtick);
g(2,2).set_names('x',{}, 'y', 'RT(s)','column', '','linestyle','');
g(2,2).set_order_options('linestyle',1,'x',0,'column',0);
g(2,2).set_layout_options('Position',[0.46 0.4 0.46 0.25]);
g(2,2).no_legend;

if ~plot3FP
    g(3,1) = gramm('x',SBS.Session,'y',SBS.t2cInv,'linestyle',cellstr(SBS.Group),'subset',SBS.t2cInv<1);
    g(3,1).facet_grid([],cellstr(SBS.Task),'scale', 'free_x','space','free_x', 'column_labels',false);
    g(3,1).stat_summary('type',errMethod,'geom',{'area','point'},'dodge',0.4,'setylim',false);
    g(3,1).axe_property('xticklabels', {}, 'XGrid', 'on', 'YGrid', 'off','xtick',xtick);
    g(3,1).set_names('x','', 'y', '1 / Tri2Cri','column', '','row','','color','','linestyle','');
    g(3,1).set_line_options('base_size',2,'styles',{'-',':'});
    g(3,1).set_point_options('base_size',5);
    g(3,1).set_color_options('map',cDarkGray,'n_color',1,'n_lightness',1);
    g(3,1).set_order_options('linestyle',1,'x',0,'column',0);
    g(3,1).set_layout_options('Position',[0 0.4 0.46 0.18]);
    g(3,1).no_legend;
    
    g(4,1) = gramm('x',TBT.Session,'y',TBT.iTrial,'color',cellstr(TBT.Outcome),'subset',TBT.Outcome~="Cor");
    g(4,1).facet_grid(cellstr(TBT.Group),cellstr(TBT.Task),'scale', 'free_x','space','free_x',...
        'row_labels',false,'column_labels',false);
%     g(4,1).stat_violin('half',true,'normalization','area','fill','transparent','width',0.8);
    g(4,1).geom_jitter('dodge',0.8,'width',0.4,'alpha',0.5);
    g(4,1).set_point_options('base_size',1.2);
    g(4,1).axe_property('XTickLabelRotation', 90, 'XGrid', 'on', 'YGrid', 'off','xtick',xtick);
    g(4,1).set_names('x','Session#', 'y', 'Trial#','column', '','row','','color','','linestyle','');
    g(4,1).set_color_options('map',cPre_Late,'n_color',2,'n_lightness',1);
    g(4,1).set_order_options('x',0,'column',0,'row',1,'color',{'Pre','Late'});
%     g(4,1).set_title(grpName(1));
    g(4,1).set_layout_options('Position',[0.0 0 0.46 0.4]);
    g(4,1).no_legend;
    
    g(3,2) = gramm('x',TBT.TimeElapsed./60,'y',TBT.iTrial,'color',TBT.FP);
    g(3,2).facet_grid(cellstr(TBT.Group),cellstr(TBT.Task),'scale', 'free_x','space','free_x',...
        'row_labels',true,'column_labels',false);
%     g(3,2).geom_point('alpha',0.2);
%     g(3,2).set_point_options('base_size',1.5);
    g(3,2).geom_line();
    g(3,2).set_line_options('base_size',0.3);
    g(3,2).axe_property('xlim',[0 67],'XTickLabelRotation', 90, 'XGrid', 'off', 'YGrid', 'off');
    g(3,2).set_names('x','Time (min)', 'y', 'Trial#','column', '','row','','color','FP','linestyle','');
%     g(3,2).set_color_options('map',cCor_Pre_Late,'n_color',3,'n_lightness',1);
    g(3,2).set_continuous_color('colormap','copper');
    g(3,2).set_order_options('x',0,'column',0,'row',1,'color',1)%{'Cor','Pre','Late'});
    g(3,2).set_layout_options('Position',[0.46 0 0.46 0.4],'legend_position',[0.92 0.02 0.1 0.15]);
%     g(3,2).no_legend;
else
    g(3,1) = gramm('x',SBS.Session,'y',SBS.CorS,'linestyle',cellstr(SBS.Group));
    g(3,1).facet_grid([],cellstr(SBS.Task),'scale', 'free_x','space','free_x', 'column_labels',false);
    g(3,1).stat_summary('type',errMethod,'geom',{'area','point'},'dodge',0.4,'setylim',true);
    g(3,1).geom_hline('yintercept',0.7,'style','k:');
    g(3,1).axe_property('ylim',[0,1],'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'off','xtick',xtick);
    g(3,1).set_names('x','', 'y', 'Cor min','column', '','row','','color','','linestyle','');
    g(3,1).set_line_options('base_size',2,'styles',{'-',':'});
    g(3,1).set_point_options('base_size',5);
    g(3,1).set_color_options('map',cGreen3(1,:),'n_color',1,'n_lightness',1);
    g(3,1).set_order_options('linestyle',1,'x',0,'column',0);
    g(3,1).set_layout_options('Position',[0 0.4 0.46 0.18]);
    g(3,1).no_legend;
    
    g(4,1) = gramm('x',SBS.Session,'y',SBS.CorM,'linestyle',cellstr(SBS.Group));
    g(4,1).facet_grid([],cellstr(SBS.Task),'scale', 'free_x','space','free_x', 'column_labels',false);
    g(4,1).stat_summary('type',errMethod,'geom',{'area','point'},'dodge',0.4,'setylim',true);
    g(4,1).geom_hline('yintercept',0.7,'style','k:');
    g(4,1).axe_property('ylim',[0,1],'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'off','xtick',xtick);
    g(4,1).set_names('x','', 'y', 'Cor mid','column', '','row','','color','','linestyle','');
    g(4,1).set_line_options('base_size',2,'styles',{'-',':'});
    g(4,1).set_point_options('base_size',5);
    g(4,1).set_color_options('map',cGreen3(2,:),'n_color',1,'n_lightness',1);
    g(4,1).set_order_options('linestyle',1,'x',0,'column',0);
    g(4,1).set_layout_options('Position',[0 0.22 0.46 0.18]);
    g(4,1).no_legend;
    
    g(5,1) = gramm('x',SBS.Session,'y',SBS.CorL,'linestyle',cellstr(SBS.Group));
    g(5,1).facet_grid([],cellstr(SBS.Task),'scale', 'free_x','space','free_x', 'column_labels',false);
    g(5,1).stat_summary('type',errMethod,'geom',{'area','point'},'dodge',0.4,'setylim',true);
    g(5,1).geom_hline('yintercept',0.7,'style','k:');
    g(5,1).axe_property('ylim',[0,1],'XTickLabelRotation', 90, 'XGrid', 'on', 'YGrid', 'off','xtick',xtick);
    g(5,1).set_names('x','Session#', 'y', 'Cor max','column', '','row','','color','','linestyle','');
    g(5,1).set_line_options('base_size',2,'styles',{'-',':'});
    g(5,1).set_point_options('base_size',5);
    g(5,1).set_color_options('map',cGreen3(3,:),'n_color',1,'n_lightness',1);
    g(5,1).set_order_options('linestyle',1,'x',0,'column',0);
    g(5,1).set_layout_options('Position',[0 0 0.46 0.22]);
    g(5,1).no_legend;
    
    g(3,2) = gramm('x',SBS.Session,'y',SBS.RTS,'linestyle',cellstr(SBS.Group));
    g(3,2).facet_grid([],cellstr(SBS.Task),'scale', 'free_x','space','free_x', 'column_labels',false);
    g(3,2).stat_summary('type',errMethod,'geom',{'area','point'},'dodge',0.4,'setylim',true);
    g(3,2).axe_property('ylim',[0.15 0.45],'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'off','xtick',xtick);
    g(3,2).set_names('x','', 'y', 'RTmin','column', '','row','','color','','linestyle','');
    g(3,2).set_line_options('base_size',2,'styles',{'-',':'});
    g(3,2).set_point_options('base_size',5);
    g(3,2).set_color_options('map',cBlue3(1,:),'n_color',1,'n_lightness',1);
    g(3,2).set_order_options('linestyle',1,'x',0,'column',0);
    g(3,2).set_layout_options('Position',[0.46 0.29 0.46 0.11]);
    g(3,2).no_legend;
    
    g(4,2) = gramm('x',SBS.Session,'y',SBS.RTM,'linestyle',cellstr(SBS.Group));
    g(4,2).facet_grid([],cellstr(SBS.Task),'scale', 'free_x','space','free_x', 'column_labels',false);
    g(4,2).stat_summary('type',errMethod,'geom',{'area','point'},'dodge',0.4,'setylim',true);
    g(4,2).axe_property('ylim',[0.15 0.45],'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'off','xtick',xtick);
    g(4,2).set_names('x','', 'y', 'RTmid','column', '','row','','color','','linestyle','');
    g(4,2).set_line_options('base_size',2,'styles',{'-',':'});
    g(4,2).set_point_options('base_size',5);
    g(4,2).set_color_options('map',cBlue3(2,:),'n_color',1,'n_lightness',1);
    g(4,2).set_order_options('linestyle',1,'x',0,'column',0);
    g(4,2).set_layout_options('Position',[0.46 0.18 0.46 0.11]);
    g(4,2).no_legend;
    
    g(5,2) = gramm('x',SBS.Session,'y',SBS.RTL,'linestyle',cellstr(SBS.Group));
    g(5,2).facet_grid([],cellstr(SBS.Task),'scale', 'free_x','space','free_x', 'column_labels',false);
    g(5,2).stat_summary('type',errMethod,'geom',{'area','point'},'dodge',0.4,'setylim',true);
    g(5,2).axe_property('ylim',[0.15 0.45],'XTickLabelRotation', 90, 'XGrid', 'on', 'YGrid', 'off','xtick',xtick);
    g(5,2).set_names('x','Session#', 'y', 'RTmax','column', '','row','','color','','linestyle','');
    g(5,2).set_line_options('base_size',2,'styles',{'-',':'});
    g(5,2).set_point_options('base_size',5);
    g(5,2).set_color_options('map',cBlue3(3,:),'n_color',1,'n_lightness',1);
    g(5,2).set_order_options('linestyle',1,'x',0,'column',0);
    g(5,2).set_layout_options('Position',[0.46 0 0.46 0.18]);
    g(5,2).no_legend;
    
%     g(3,2) = gramm('x',TBT.Session,'y',TBT.RT,'color',TBT.FP,...
%         'subset',(TBT.FP==0.5 | TBT.FP==1.0 | TBT.FP==1.5) & TBT.Outcome=="Cor" & TBT.Group==grpName(1));
%     g(3,2).facet_grid([], cellstr(TBT.Task), 'scale', 'free_x','space','free_x', 'column_labels', false);
%     g(3,2).stat_summary('type', @(x)compute_stat_summary(x,'quartile'),'geom',{'errorbar','point'},'dodge',0.6);
%     g(3,2).set_point_options('base_size',3);
%     g(3,2).set_line_options('base_size',1.2);
%     g(3,2).axe_property('ylim', [0.2 0.5], 'XGrid', 'on', 'YGrid', 'off','xticklabels', {});
%     g(3,2).set_names('x',{}, 'y', strcat('RT'," ",grpName(1)),'color','FP(s)');
%     g(3,2).set_color_options('map',c3FPs,'n_color',3,'n_lightness',1);
%     g(3,2).set_order_options('column',0,'x',0,'color',1);
%     g(3,2).set_layout_options('Position',[0.46 0.22 0.46 0.18]);
%     g(3,2).no_legend;
%     
%     g(4,2) = gramm('x',TBT.Session,'y',TBT.RT,'color',TBT.FP,...
%         'subset',(TBT.FP==0.5 | TBT.FP==1.0 | TBT.FP==1.5) & TBT.Outcome=="Cor" & TBT.Group==grpName(2));
%     g(4,2).facet_grid([], cellstr(TBT.Task), 'scale', 'free_x','space','free_x', 'column_labels', false);
%     g(4,2).stat_summary('type', @(x)compute_stat_summary(x,'quartile'),'geom',{'errorbar','point'},'dodge',0.6);
%     g(4,2).set_point_options('base_size',3);
%     g(4,2).set_line_options('base_size',1.2);
%     g(4,2).axe_property('ylim', [0.2 0.5], 'XGrid', 'on', 'YGrid', 'off','XTickLabelRotation', 90);
%     g(4,2).set_names('x','Session#', 'y', strcat('RT'," ",grpName(2)),'color','FP(s)');
%     g(4,2).set_color_options('map',c3FPs,'n_color',3,'n_lightness',1);
%     g(4,2).set_order_options('column',0,'x',0,'color',1);
%     g(4,2).set_layout_options('Position',[0.46 0 0.46 0.22],'legend_position',[0.92 0.028 0.1 0.15]);
    
    % to be continued
end

g.set_title("Learning Curve: "+taskrange + " ("+cenMethod+"-"+errMethod+")");
g.set_text_options('base_size',6,'label_scaling',1.3,'legend_scaling',1.1,...
    'legend_title_scaling',1.2,'facet_scaling',1.4,...
    'title_scaling',1.4,'big_title_scaling',1.6);

h = figure(5);clf(h,'reset');
set(h,'Name','LearningFig_Comparison','unit', 'centimeters',...
    'position',[1 1 18.542 10.43],'paperpositionmode', 'auto');
g.draw();

axes('position',[0.92,0.42,0.05,0.3],'Visible','off');
text(0,1,[upper(grpName(1)),sbjName(ismember(grpVar,grpName(1)))','',...
    upper(grpName(2)),sbjName(ismember(grpVar,grpName(2)))'],'fontsize',6,'VerticalAlignment','top');

%% Save
figName = "DaybyDay Comparison_"+taskrange;
figPath = pwd;
figFile = fullfile(figPath,figName);

saveas(h, figFile, 'fig');
% saveas(h, figFile, 'png');
print(h,'-dpng',figFile);
% print(h,'-depsc2',figFile);
end

%% Functions
function [SBS,TBT] = packData(btAll2d,grpVar,cenMethod)
SBS = table;
TBT = table;
for i=1:size(btAll2d,1)
    for j=1:size(btAll2d,2)
        T = btAll2d{i,j};
        SBS = [SBS;estSBS(T,grpVar(i),j,cenMethod)];
        
        nrow = size(T,1);
        if nrow>1
            tempT = addvars(T,repelem(j,nrow)','After','Date','NewVariableNames','Session');
            tempTT = addvars(tempT,repelem(grpVar(i),nrow)','Before','Date','NewVariableNames','Group');
            TBT = [TBT;tempTT];
        end
    end
end
end

function outT = estSBS(data,grp,session,cenMethod,varargin)
fplist = [0.5,1.0,1.5];
for i=1:length(varargin)
    switch i
        case 1
            fplist = varargin{i};
    end
end

outT = table;
if isempty(data)
    return;
end

t = struct;
t.Subject = data.Subject(1);
t.Group = grp;
t.Date = data.Date(1);
t.Session = session;
t.Task = data.Task(1);

t.nTrial = length(data.iTrial);
t.rTrial = t.nTrial./(sum(data.DarkTry)+t.nTrial);
t.Cor = sum(data.Outcome=="Cor")./t.nTrial;
t.Pre = sum(data.Outcome=="Pre")./t.nTrial;
t.Late = sum(data.Outcome=="Late")./t.nTrial;

t.CorS = sum(data.Outcome=="Cor" & abs(data.FP-fplist(1))<1e-4)./sum(abs(data.FP-fplist(1))<1e-4);
t.CorM = sum(data.Outcome=="Cor" & abs(data.FP-fplist(2))<1e-4)./sum(abs(data.FP-fplist(2))<1e-4);
t.CorL = sum(data.Outcome=="Cor" & abs(data.FP-fplist(3))<1e-4)./sum(abs(data.FP-fplist(3))<1e-4);
t.PreS = sum(data.Outcome=="Pre" & abs(data.FP-fplist(1))<1e-4)./sum(abs(data.FP-fplist(1))<1e-4);
t.PreM = sum(data.Outcome=="Pre" & abs(data.FP-fplist(2))<1e-4)./sum(abs(data.FP-fplist(2))<1e-4);
t.PreL = sum(data.Outcome=="Pre" & abs(data.FP-fplist(3))<1e-4)./sum(abs(data.FP-fplist(3))<1e-4);
t.LateS = sum(data.Outcome=="Late" & abs(data.FP-fplist(1))<1e-4)./sum(abs(data.FP-fplist(1))<1e-4);
t.LateM = sum(data.Outcome=="Late" & abs(data.FP-fplist(2))<1e-4)./sum(abs(data.FP-fplist(2))<1e-4);
t.LateL = sum(data.Outcome=="Late" & abs(data.FP-fplist(3))<1e-4)./sum(abs(data.FP-fplist(3))<1e-4);

t.maxFP = max(data.FP);
t.t2mFP = find(data.FP==t.maxFP,1,'first');
t.minRW = min(data.RW);
t.t2mRW = find(data.RW==t.minRW,1,'first');

switch string(t.Task)
    case "Wait1"
        t2c = find(abs(data.FP-1.5)<1e-4,1,'first');
        if ~isempty(t2c)
            t2cInv = 1./t2c;
        else
            t2c = t.nTrial;
            t2cInv = 0;
        end
    case "Wait2"
        t2c = find(abs(data.FP-1.5)<1e-4 & abs(data.RW-0.6)<1e-4,1,'first');
        if ~isempty(t2c)
            t2cInv = 1./t2c;
        else
            t2c = t.nTrial;
            t2cInv = 0;
        end
    case "3FPs"
        t2c = 0;
        t2cInv = 1;
end
t.t2c = t2c;
t.t2cInv = t2cInv;
    
switch cenMethod
    case 'mean'
        t.HT = mean(data.HT,'omitnan');
        t.RT = mean(data(data.Outcome=="Cor",:).RT,'omitnan');
        t.RTS = mean(data(data.Outcome=="Cor" & data.FP==fplist(1),:).RT,'omitnan');
        t.RTM = mean(data(data.Outcome=="Cor" & data.FP==fplist(2),:).RT,'omitnan');
        t.RTL = mean(data(data.Outcome=="Cor" & data.FP==fplist(3),:).RT,'omitnan');
    case 'median'
        t.HT = median(data.HT,'omitnan');
        t.RT = median(data(data.Outcome=="Cor",:).RT,'omitnan');
        t.RTS = median(data(data.Outcome=="Cor" & data.FP==fplist(1),:).RT,'omitnan');
        t.RTM = median(data(data.Outcome=="Cor" & data.FP==fplist(2),:).RT,'omitnan');
        t.RTL = median(data(data.Outcome=="Cor" & data.FP==fplist(3),:).RT,'omitnan');
    case 'geomean'
        t.HT = geomean(data.HT,'omitnan');
        t.RT = geomean(data(data.Outcome=="Cor" & data.RT>0,:).RT,'omitnan');
        t.RTS = geomean(data(data.Outcome=="Cor" & data.FP==fplist(1) & data.RT>0,:).RT,'omitnan');
        t.RTM = geomean(data(data.Outcome=="Cor" & data.FP==fplist(2) & data.RT>0,:).RT,'omitnan');
        t.RTL = geomean(data(data.Outcome=="Cor" & data.FP==fplist(3) & data.RT>0,:).RT,'omitnan');
end
outT = [outT;struct2table(t)];
end