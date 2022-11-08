function h = BPOD_LearningPlot_Individual(btAll,plotRange)
%%
altMethod = {'mean','median','geomean'};
cenMethod = altMethod{1};
% errMethod = 'sem';
%% Data processing
switch nargin
    case 1
        plotRange = 1:length(btAll);
end
btAll_use = btAll(:,plotRange);
[SBS,TBT] = packData(btAll_use,cenMethod);
date_SBS = num2str(SBS.Date);
SBS.Date = string(date_SBS(:,end-3:end));
date_TBT = num2str(TBT.Date);
TBT.Date = string(date_TBT(:,end-3:end));

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
cRed = cTab10(4,:);
cGray = cTab10(8,:);
cGray2 = cTab20(15:16,:);
cBlue = cTab10(1,:);
cCor_Pre_Late = [cGreen;cRed;cGray];
% c3FPs = YlOrBr(4);c3FPs = c3FPs(2:end,:);
c3FPs = [cGray;mean([Oranges(1);cGray]);Oranges(1)];

% TrialNum
g(1,1) = gramm('X',cellstr(SBS.Date),'Y',SBS.nTrial,'color',SBS.rTrial);
g(1,1).facet_grid([], cellstr(SBS.Task),'scale','free_x','space','free_x');
g(1,1).geom_point(); g(1,1).set_point_options('base_size',6);
g(1,1).geom_line();  g(1,1).set_line_options('base_size',2);
g(1,1).axe_property('ylim',[0 400],'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'on');
g(1,1).set_names('x',{}, 'y', 'Trials','column', '','color','Trial%');
g(1,1).set_continuous_color('colormap','copper','CLim',[0,1]);
g(1,1).set_order_options('column',0,'x',0);
g(1,1).set_layout_options('Position',[0 0.87 0.9 0.13],'legend_position',[0.89 0.815 0.1 0.1]);

% Performance
SBSp = stack(SBS,{'Cor','Pre','Late'});
g(2,1) = gramm('X', cellstr(SBSp.Date), 'Y',SBSp.Cor_Pre_Late, 'color',SBSp.Cor_Pre_Late_Indicator);
g(2,1).facet_grid([], cellstr(SBSp.Task), 'scale', 'free_x','space','free_x', 'column_labels', false);
g(2,1).geom_hline('yintercept',0.7,'style','k:');
g(2,1).geom_point(); g(2,1).set_point_options('base_size',6);
g(2,1).geom_line();  g(2,1).set_line_options('base_size',2);
g(2,1).axe_property('ylim', [0 1], 'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'on');
g(2,1).set_names('x',{}, 'y', 'Performance','color','');
g(2,1).set_color_options('map',cCor_Pre_Late,'n_color',3,'n_lightness',1);
g(2,1).set_order_options('column',0,'x',0,'color',{'Cor','Pre','Late'});
g(2,1).set_layout_options('Position',[0 0.57 0.9 0.3],'legend_position',[0.89 0.74 0.08 0.1]);

% RT
g(3,1) = gramm('X',cellstr(TBT.Date),'Y',TBT.RT,'subset',TBT.Outcome=="Cor");
g(3,1).facet_grid([], cellstr(TBT.Task), 'scale', 'free_x','space','free_x', 'column_labels',false);
% g(3,1).stat_violin('half',true,'normalization','area','fill','edge','dodge',0,'width',0.7);
g(3,1).stat_boxplot('width', 0.5,'notch',false);
g(3,1).set_point_options('base_size',2);
g(3,1).set_color_options('map',cBlue,'n_color',1,'n_lightness',1);
g(3,1).axe_property('ylim', ylim_rt, 'xticklabels', {},'XTickLabelRotation', 90, 'XGrid', 'on', 'YGrid', 'on');
g(3,1).set_names('x',{}, 'y', 'RT(s)','column', '','color','FP(s)');
g(3,1).set_order_options('column',0,'x',0);
g(3,1).set_layout_options('Position',[0 0.37 0.9 0.2]);

% Trial2Criterion or Performance by 3FP
if ~plot3FP
    % pre-processed
    SBS_t = stack(SBS,{'t2mFP','t2mRW'});
    SBS_c = stack(SBS,{'maxFP','minRW'});
    SBS_t.t2mFP_t2mRW_Indicator = categorical(erase(cellstr(SBS_t.t2mFP_t2mRW_Indicator),{'t2m'}));
    SBS_c.maxFP_minRW_Indicator = categorical(erase(cellstr(SBS_c.maxFP_minRW_Indicator),{'min','max'}));
    
    g(4,1) = gramm('X',cellstr(SBS_c.Date),'Y',SBS_c.maxFP_minRW,...
        'linestyle',SBS_c.maxFP_minRW_Indicator);
    g(4,1).facet_grid([], cellstr(SBS_c.Task), 'scale', 'free_x','space','free_x', 'column_labels',false);
    g(4,1).axe_property('ylim', [0.5 2], 'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'on');
    g(4,1).set_names('x',{}, 'y','BestPerf','column','','color','','linestyle','');
    g(4,1).geom_point(); g(4,1).set_point_options('base_size',6);
    g(4,1).geom_line();  g(4,1).set_line_options('base_size',2,'style',{'-',':'});
    g(4,1).set_color_options('map',cDarkGray,'n_color',1,'n_lightness',1);
    g(4,1).set_order_options('column',0,'x',0,'line',{'FP','RW'});
    g(4,1).set_layout_options('Position',[0 0.2 0.9 0.17],'legend_position',[0.89,0.28,0.24,0.1]);
    
    g(5,1) = gramm('X',cellstr(SBS_t.Date),'Y',SBS_t.t2mFP_t2mRW,...
        'linestyle',SBS_t.t2mFP_t2mRW_Indicator);
    g(5,1).facet_grid([], cellstr(SBS_t.Task), 'scale', 'free_x','space','free_x', 'column_labels',false);
    g(5,1).axe_property('ylim', [40 200], 'XTickLabelRotation', 90, 'XGrid', 'on', 'YGrid', 'on');
    g(5,1).set_names('x',{}, 'y','Trials2BestPerf','column','','color','','linestyle','');
    g(5,1).geom_point(); g(5,1).set_point_options('base_size',6);
    g(5,1).geom_line();  g(5,1).set_line_options('base_size',2,'style',{'-',':'});
    g(5,1).set_color_options('map',cDarkGray,'n_color',1,'n_lightness',1);
    g(5,1).set_order_options('column',0,'x',0,'line',{'FP','RW'});
    g(5,1).set_layout_options('Position',[0 0.0 0.9 0.2],'legend_position',[0.89,0.12,0.1,0.1]);
    g(5,1).no_legend;
else
    SBS_3c = stack(SBS,{'CorS','CorM','CorL'});
    g(4,1) = gramm('X',cellstr(SBS_3c.Date),'Y',SBS_3c.CorS_CorM_CorL,...
        'linestyle',SBS_3c.CorS_CorM_CorL_Indicator,'color',SBS_3c.CorS_CorM_CorL_Indicator);
    g(4,1).facet_grid([], cellstr(SBS_3c.Task), 'scale', 'free_x','space','free_x', 'column_labels',false);
    g(4,1).geom_point(); g(4,1).set_point_options('base_size',4);
    g(4,1).geom_line();  g(4,1).set_line_options('base_size',1.5,'style',{':','-.','-'});
    g(4,1).geom_hline('yintercept',0.7,'style','k:');
    g(4,1).axe_property('ylim', [0 1], 'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'on');
    g(4,1).set_names('x',{}, 'y','Accuracy','column','','color','','linestyle','FP');
    g(4,1).set_color_options('map',c3FPs,'n_color',3,'n_lightness',1);
    g(4,1).set_order_options('column',0,'x',0,'linestyle',{'CorS','CorM','CorL'},'color',{'CorS','CorM','CorL'});
    g(4,1).set_layout_options('Position',[0 0.20 0.9 0.17],'legend_position',[0.89,0.28,0.1,0.1]);
    g(4,1).no_legend;
    
    g(5,1) = gramm('X',cellstr(TBT.Date),'Y',TBT.RT,...
        'color',TBT.FP,...
        'subset',(TBT.FP==0.5 | TBT.FP==1.0 | TBT.FP==1.5) & TBT.Outcome=="Cor");
    g(5,1).facet_grid([], cellstr(TBT.Task), 'scale', 'free_x','space','free_x', 'column_labels', false);
    g(5,1).stat_summary('type', @(x)compute_stat_summary(x,'quartile'),'geom',{'errorbar','point'},'dodge',0.6);
    g(5,1).set_point_options('base_size',3);
    g(5,1).set_line_options('base_size',1.2);
    g(5,1).axe_property('ylim', [0 0.6], 'XGrid', 'on', 'YGrid', 'on','XTickLabelRotation',90);
    g(5,1).set_names('x',{}, 'y', 'RT(s) Quartile','color','FP(s)');
    g(5,1).set_color_options('map',c3FPs,'n_color',3,'n_lightness',1);
    g(5,1).set_order_options('column',0,'x',0,'color',1);
    g(5,1).set_layout_options('Position',[0 0.0 0.9 0.2],'legend_position',[0.89,0.09,0.1,0.1]);
end

g.set_title(TBT.Subject(1)+": "+"Learning Curve");
g.set_text_options('base_size',6,'label_scaling',1.3,'legend_scaling',1.1,...
    'legend_title_scaling',1.2,'facet_scaling',1.4,'big_title_scaling',1.6);

h = figure(3);clf(h);
set(h,'Name','LearningFig','unit', 'centimeters', ...
    'position',[1 1 9 16], 'paperpositionmode', 'auto');
g.draw();

% modify
hp = findobj(g(3,1).facet_axes_handles,'Type','Line');
set(hp,'MarkerSize',3);

figName = "LearningProgress_"+TBT.Subject(1);
%% Save
figPath = fullfile(pwd,'IndivFig');
if ~exist(figPath,'dir')
    mkdir(figPath);
end
figFile = fullfile(figPath,figName);
saveas(h, figFile, 'fig');
% saveas(h, figFile, 'png');
print(h,'-dpng',figFile);
% print(h,'-depsc2',figFile);
end

%% Functions

function [SBS,TBT] = packData(btAll,cenMethod)
SBS = table;
TBT = table;
for i=1:length(btAll)
    T = btAll{i};
    SBS = [SBS;estSBS(T,i,cenMethod)];
    
    nrow = size(T,1);
    tempT = addvars(T,repelem(i,nrow)','After','Date','NewVariableNames','Session');
    TBT = [TBT;tempT];
end
end

function outT = estSBS(data,session,cenMethod,varargin)
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

switch cenMethod
    case 'mean'
        t.HT = mean(data.HT,'omitnan');
        t.RT = mean(data(data.Outcome=="Cor",:).RT,'omitnan');
    case 'median'
        t.HT = median(data.HT,'omitnan');
        t.RT = median(data(data.Outcome=="Cor",:).RT,'omitnan');
    case 'geomean'
        t.HT = geomean(data.HT,'omitnan');
        t.RT = geomean(data(data.Outcome=="Cor" & data.RT>0,:).RT,'omitnan');
end
outT = [outT;struct2table(t)];

end