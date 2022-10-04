function h = med_LearningPlot_Individual(btAll)
% _________________________________________________________________________
% File:               med_LearningPlot_Individual.m
% Created on:         Sept 27, 2021
% Created by:         Yu Chen
% Last revised on:    Mar 15, 2022
% Last revised by:    Yu Chen
% _________________________________________________________________________
% Required Packages:
% 'gramm' by Pierre Morel
% _________________________________________________________________________
%% Data packaging
% data session-by-session
SBS.Name = {};
SBS.Date = {};
SBS.Task = {};
SBS.nTrial = [];
SBS.rTrial = [];
SBS.Cor = [];
SBS.Pre = [];
SBS.Late = [];
SBS.RT = [];
SBS.RT_var = [];

% data trial-by-trial struct
TBTs.Name = {};
TBTs.Date = {};
TBTs.Task = {};
TBTs.iTrial = [];
TBTs.FP = [];
TBTs.Outcome = [];
TBTs.RT = [];
TBTs.PressDur = [];

% central tendency & dispersion parameter
tend_disp_approachs = {'mean-std','mean-bootci','mean-sem','quartile',...
    'geomean-geomad','geomean-bootci'}; 
RT_stat = tend_disp_approachs{4};

for i=1:length(btAll)
    bt = btAll{i}(btAll{i}.Type~=0,:);
    
    SBS.Name   = [SBS.Name;      bt.Subject(1)];
    strdate = num2str(bt.Date(1));
    SBS.Date   = [SBS.Date;      strdate(end-3:end)];
    SBS.Task   = [SBS.Task;      replace(bt.Task(1),{'Bpod','Three'},{'','3'})];
    numTrial   = size(bt,1);
    SBS.nTrial = [SBS.nTrial;    numTrial];
    SBS.rTrial = [SBS.rTrial;    numTrial./size(btAll{i},1)];
    SBS.Cor    = [SBS.Cor;       sum(bt.Type==1)./numTrial];
    SBS.Pre    = [SBS.Pre;       sum(bt.Type==-1)./numTrial];
    SBS.Late   = [SBS.Late;      sum(bt.Type==-2)./numTrial];
    
    rt_summ  = compute_stat_summary(bt.RT(bt.Type==1 & bt.RT>0),RT_stat);
    SBS.RT     = [SBS.RT;        rt_summ(1)];
    SBS.RT_var = [SBS.RT_var;    (rt_summ(3)-rt_summ(2))./2];
    
    date_str = num2str(bt.Date);
    TBTs.Name     = [TBTs.Name;     bt.Subject];
    TBTs.Date     = [TBTs.Date;     string(date_str(:,end-3:end))];
    TBTs.Task     = [TBTs.Task;     bt.Task];
    TBTs.iTrial   = [TBTs.iTrial;   bt.iTrial];
    TBTs.FP       = [TBTs.FP;       bt.FP];
    TBTs.Outcome  = [TBTs.Outcome;  bt.Type];
    TBTs.RT       = [TBTs.RT;       bt.RT];
    TBTs.PressDur = [TBTs.PressDur; bt.PressDur];
end

% trial-by-trial table
varNames = {'Name','Date','Task','iTrial','FP',...
    'Outcome','RT','PressDur'};
TBT = table(TBTs.Name,TBTs.Date,TBTs.Task,TBTs.iTrial,TBTs.FP,...
    TBTs.Outcome,TBTs.RT,TBTs.PressDur,'VariableNames',varNames);

isTask500 = TBT.Task == "ThreeFPsMixedBpod";
isTask750 = TBT.Task == "ThreeFPsMixedBpod750_1250_1750";
isExist3FPs500 = ~isempty(isTask500);
isExist3FPs750 = ~isempty(isTask750);
isExist3FPs = isExist3FPs500 && isExist3FPs750;

if isExist3FPs
    idx_3fp = TBT.FP==0.5 | TBT.FP==1.0 | TBT.FP==1.5...
        | TBT.FP==0.75 | TBT.FP==1.25 | TBT.FP==1.75;
elseif isExist3FPs500
    idx_3fp = TBT.FP==0.5 | TBT.FP==1.0 | TBT.FP==1.5;
elseif isExist3FPs750
    idx_3fp = TBT.FP==0.75 | TBT.FP==1.25 | TBT.FP==1.75;
end
TBT_3fp_cor = TBT(idx_3fp & TBT.Outcome==1,:);
TBT_3fp_cor.FP = string(TBT_3fp_cor.FP);
TBT_3fp_cor.FP = replace(TBT_3fp_cor.FP,{'0.75','1.25','1.75','0.5','1.5','1'},{'min','mid','max','min','max','mid'});
%% Plot
cDarkGray = [0.2,0.2,0.2];
cGreen = [0.4660 0.6740 0.1880];
cRed = [0.6350 0.0780 0.1840];
cYellow = [0.9290 0.6940 0.1250];
cBlue = [0,0.6902,0.9412];
cOrange = [0.929,0.49,0.192];
cGray = [0.4 0.4 0.4];
colorlist = [cDarkGray;cGray;cGreen;cRed;cYellow;cBlue];
color_FP = [cGray;mean([cOrange;cGray]);cOrange];
color_Perf = [cGreen;cRed;cYellow];

% Trial Number
g(1,1) = gramm('X', cellstr(SBS.Date), 'Y',SBS.nTrial);
g(1,1).facet_grid([], cellstr(SBS.Task), 'scale', 'free_x','space','free_x');
g(1,1).geom_point(); g(1,1).set_point_options('base_size',6);
g(1,1).geom_line();  g(1,1).set_line_options('base_size',2);
% g(1,1).axe_property('ylim', [100 500], 'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'on');
g(1,1).axe_property('xticklabels', {}, 'XGrid', 'on', 'YGrid', 'on');
g(1,1).set_names('x',{}, 'y', 'Trials','column', '');
g(1,1).set_color_options('map',colorlist(1,:),'n_color',1,'n_lightness',1);
g(1,1).set_order_options('column',0,'x',0);
g(1,1).set_layout_options('Position',[0 0.85 1 0.15]);

% Trial Press Ratio
g(2,1) = gramm('X', cellstr(SBS.Date), 'Y',SBS.rTrial);
g(2,1).facet_grid([], cellstr(SBS.Task), 'scale', 'free_x','space','free_x', 'column_labels', false);
g(2,1).geom_point(); g(2,1).set_point_options('base_size',6);
g(2,1).geom_line();  g(2,1).set_line_options('base_size',2);
g(2,1).axe_property('ylim', [0 1], 'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'on');
g(2,1).set_names('x',{}, 'y', 'Trial Ratio');
g(2,1).set_color_options('map',colorlist(2,:),'n_color',1,'n_lightness',1);
g(2,1).set_order_options('column',0,'x',0);
g(2,1).set_layout_options('Position',[0 0.74 1 0.11]);

SBSt = struct2table(SBS);
pSBSt = stack(SBSt,{'Cor','Pre','Late'});
g(3,1) = gramm('X', cellstr(pSBSt.Date), 'Y',pSBSt.Cor_Pre_Late, 'color',pSBSt.Cor_Pre_Late_Indicator);
g(3,1).facet_grid([], cellstr(pSBSt.Task), 'scale', 'free_x','space','free_x', 'column_labels', false);
g(3,1).geom_point(); g(3,1).set_point_options('base_size',6);
g(3,1).geom_line();  g(3,1).set_line_options('base_size',2);
g(3,1).axe_property('ylim', [0 1], 'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'on');
g(3,1).set_names('x',{}, 'y', 'Performance','color','');
g(3,1).set_color_options('map',color_Perf,'n_color',3,'n_lightness',1);
g(3,1).set_order_options('column',0,'x',0,'color',{'Cor','Pre','Late'});
g(3,1).set_layout_options('Position',[0 0.4 1 0.34],'legend_position',[0.08 0.61 0.08 0.11]);

% RT
g(4,1) = gramm('X',cellstr(TBT.Date),'Y',TBT.RT,'subset',TBT.Outcome==1 & TBT.RT>=0.1);
g(4,1).facet_grid([], cellstr(TBT.Task), 'scale', 'free_x','space','free_x', 'column_labels', false);
g(4,1).stat_summary('type', @(x)compute_stat_summary(x,RT_stat),'geom',{'black_errorbar','point','line'});
g(4,1).set_point_options('base_size',5);
g(4,1).set_line_options('base_size',1.5);
g(4,1).axe_property('ylim', [0 0.7], 'XGrid', 'on', 'YGrid', 'on');
g(4,1).set_names('x','Date', 'y', 'RT(s)');
g(4,1).set_color_options('map',colorlist(6,:),'n_color',1,'n_lightness',1);
g(4,1).set_order_options('column',0,'x',0);
g(4,1).set_layout_options('Position',[0 0.2 1 0.2]);

if isExist3FPs
    g(4,1).axe_property('xticklabels',{});
    g(4,1).set_names('x',{}, 'y', 'RT(s)');
    g(5,1) = gramm('X',cellstr(TBT_3fp_cor.Date),'Y',TBT_3fp_cor.RT,'color',cellstr(TBT_3fp_cor.FP),'subset',TBT_3fp_cor.RT>=0.1);
    g(5,1).facet_grid([], cellstr(TBT_3fp_cor.Task), 'scale', 'free_x','space','free_x', 'column_labels', false);
    g(5,1).stat_summary('type', @(x)compute_stat_summary(x,RT_stat),'geom',{'errorbar','point'},'dodge',0.6);
    g(5,1).set_point_options('base_size',3);
    g(5,1).set_line_options('base_size',1.2);
    g(5,1).axe_property('ylim', [0 0.7], 'XGrid', 'on', 'YGrid', 'on','XTickLabelRotation',90);
    g(5,1).set_names('x',{}, 'y', 'RT_3FPs(s)','color','FP(s)');
    g(5,1).set_color_options('map',color_FP,'n_color',3,'n_lightness',1);
    g(5,1).set_order_options('column',0,'x',0,'color',{'min','mid','max'});
    g(5,1).set_layout_options('Position',[0 0 1 0.2]);
    g(5,1).no_legend();
end

g.set_title(bt.Subject(1) + ": Learning Curve"+"  ("+RT_stat+")");
g.set_text_options('base_size',6,'label_scaling',1.3,'legend_scaling',1.1,...
    'legend_title_scaling',1.2,'facet_scaling',1.4,'big_title_scaling',1.6);

h = figure(3);clf(h);
set(h, 'Name', 'Learning curve', 'unit', 'centimeters', 'position',[1 1 12 16], 'paperpositionmode', 'auto' )

g.draw();
figName = "LearningProgress_"+bt.Subject(1);
%% Save
figPath = fullfile(pwd,'IndivFig');
if ~exist(figPath,'dir')
    mkdir(figPath);
end
figFile = fullfile(figPath,figName);
saveas(h, figFile, 'png');
saveas(h, figFile, 'fig');

end