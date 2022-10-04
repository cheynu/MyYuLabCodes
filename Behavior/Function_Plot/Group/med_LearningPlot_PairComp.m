function med_LearningPlot_PairComp(btAll2d,grpVar)
% _________________________________________________________________________
% File:               med_LearningPlot_PairComp.m
% Created on:         Sept 27, 2021
% Created by:         Yu Chen
% Last revised on:    Mar 14, 2022
% Last revised by:    Yu Chen
% _________________________________________________________________________
% Required Packages:
% 'gramm' by Pierre Morel
% _________________________________________________________________________
%% initiate
grpName = unique(grpVar);
if length(grpName)~=2
    error("Grouping variables have invalid number of elements");
end
altMethod = {'mean-std','mean-sem','mean-bootci','quartile','geomean-geomad',...
    'geomean-bootci'};
estMethod = altMethod{1};
errMethod = 'sem';
%% calculate point estimate for each subject & each session
estT = table;
for i=1:size(btAll2d,1) % subjects
    for j=1:size(btAll2d,2) % sessions
        tempT = btAll2d{i,j};
        % point estimate data for each session
        estT = [estT; estPerf(tempT,grpVar(i),j,estMethod)];
    end
end

taskname = erase(unique(estT.Task),"Bpod");
taskname = strrep(taskname,"Three","3");
if length(taskname)>1
    taskrange = taskname(1)+"-"+taskname(end);
else
    taskrange = taskname;
end
%% Plot
% x: date
% column: trialtype
% color/lightness: subject group
% y: estimate point for each subject
%   use stat_summary to compute grand mean of estimate point
cDarkGray = [0.2,0.2,0.2];
cTab20 = tab20(20);
cGreen = cTab20(5:6,:);
cRed = cTab20(7:8,:);
cGray = cTab20(15:16,:);
cBlue = cTab20(1:2,:);
cBlue3 = Blues(5); cBlue3 = cBlue3(3:end,:);
cGreen3 = Greens(5); cGreen3 = cGreen3(3:end,:);
cCor_Pre_Late = [cGreen;cRed;cGray];
cFP = rainbow(15);
c3FPs = YlOrBr(5);c3FPs = c3FPs(3:end,:);

fpestT = stack(estT,{'nTrial','TrialRatio','maxFP','minRW','t2cInv'});
g(1,1) = gramm('X',fpestT.Session,'Y',fpestT.nTrial_TrialRatio_maxFP_minRW_t2cInv,'linestyle',cellstr(fpestT.Group));
g(1,1).facet_grid(fpestT.nTrial_TrialRatio_maxFP_minRW_t2cInv_Indicator, cellstr(fpestT.Task),'scale','free','space','free_x','column_labels', false);

g(1,1).stat_summary('type',errMethod,'geom',{'area','point'},'dodge',0.4);
g(1,1).axe_property('XTickLabelRotation', 90, 'XGrid', 'on', 'YGrid', 'on');
g(1,1).set_names('x','Session#', 'y', '','column', '','row','','color','','linestyle','');
g(1,1).set_line_options('base_size',1.2,'styles',{'-',':'});g(1,1).set_point_options('base_size',4);
g(1,1).set_color_options('map',cDarkGray,'n_color',1,'n_lightness',1);
g(1,1).set_order_options('linestyle',-1,'row',{'nTrial','TrialRatio','t2cInv','maxFP','minRW'});
g(1,1).set_layout_options('Position',[0 0 0.3 1]);
g(1,1).no_legend;

% RT
g(1,2) = gramm('X',estT.Session,'Y',estT.RT,'linestyle',cellstr(estT.Group));
g(1,2).facet_grid([], cellstr(estT.Task),'scale','free_x','space','free_x','column_labels', false);
g(1,2).stat_summary('type',errMethod,'geom',{'area','point'},'dodge',0.4);
g(1,2).set_color_options('map',cBlue,'n_color',1,'n_lightness',2);
g(1,2).set_line_options('base_size',1.2,'styles',{'-',':'});g(1,2).set_point_options('base_size',4);
g(1,2).axe_property('xticklabels', {}, 'ylim', [0.1 0.6], 'XGrid', 'on', 'YGrid', 'on');
g(1,2).set_names('x',{}, 'y', 'RT(s)','column', '','linestyle','');
g(1,2).set_order_options('linestyle',-1);
g(1,2).set_layout_options('Position',[0.3 0.7 0.4 0.3]);
g(1,2).no_legend;
% Cor-Pre-Late
mestT = stack(estT,{'Cor','Pre','Late'});
g(2,2) = gramm('X',mestT.Session,'Y',mestT.Cor_Pre_Late,...
    'color',mestT.Cor_Pre_Late_Indicator,'linestyle',cellstr(mestT.Group));
g(2,2).facet_grid([], cellstr(mestT.Task), 'column_labels',false,'scale','free_x','space','free_x');
g(2,2).stat_summary('type',errMethod,'geom',{'area','point'},'dodge',0.4);
g(2,2).axe_property('ylim', [0 0.9], 'XTickLabelRotation', 90, 'XGrid', 'on', 'YGrid', 'on');
g(2,2).set_names('x','Session#', 'y', 'Proportion','column', '','color','','column','','linestyle','');
g(2,2).set_line_options('base_size',1.2,'styles',{'-',':'});g(2,2).set_point_options('base_size',4);
g(2,2).set_color_options('map',cCor_Pre_Late,'n_color',3,'n_lightness',2);
g(2,2).set_order_options('color',{'Cor','Pre','Late'},'linestyle',-1);
g(2,2).set_layout_options('Position',[0.3 0 0.4 0.7],'legend_position',[0.355,0.25,0.15,0.23]);
% RT 3FPs
rtestT = stack(estT,{'RTS','RTM','RTL'});
g(1,3) = gramm('X',rtestT.Session,'Y',rtestT.RTS_RTM_RTL,'linestyle',cellstr(rtestT.Group),...
    'color',rtestT.RTS_RTM_RTL_Indicator);
g(1,3).facet_grid(rtestT.RTS_RTM_RTL_Indicator, cellstr(rtestT.Task),...
    'column_labels',false,'scale','free_x','space','free_x');
g(1,3).stat_summary('type',errMethod,'geom',{'area','point'},'dodge',0.4);
g(1,3).axe_property('xticklabels', {}, 'XGrid', 'on', 'YGrid', 'on');
g(1,3).set_names('x','', 'y', '','column', '','row','','color','','linestyle','');
g(1,3).set_line_options('base_size',1.2,'styles',{'-',':'});g(1,3).set_point_options('base_size',4);
g(1,3).set_color_options('map',cBlue3,'n_color',3,'n_lightness',1);
g(1,3).set_order_options('linestyle',-1,'row',{'RTS','RTM','RTL'},'color',{'RTS','RTM','RTL'});
g(1,3).set_layout_options('Position',[0.7 0.5 0.3 0.5]);
% g(1,3).set_title("RT (3FPs)");
g(1,3).no_legend;
% Accuracy 3FPs
cestT = stack(estT,{'CorS','CorM','CorL'});
g(2,3) = gramm('X',cestT.Session,'Y',cestT.CorS_CorM_CorL,'linestyle',cellstr(cestT.Group),...
    'color',cestT.CorS_CorM_CorL_Indicator);
g(2,3).facet_grid(cestT.CorS_CorM_CorL_Indicator, cellstr(cestT.Task),...
    'scale','free','space','free_x','column_labels', false);
g(2,3).stat_summary('type',errMethod,'geom',{'area','point'},'dodge',0.4);
g(2,3).axe_property('XTickLabelRotation', 90, 'XGrid', 'on', 'YGrid', 'on');
g(2,3).set_names('x','Session#', 'y', '','column', '','row','','color','','linestyle','');
g(2,3).set_line_options('base_size',1.2,'styles',{'-',':'});g(2,3).set_point_options('base_size',4);
g(2,3).set_color_options('map',cGreen3,'n_color',3,'n_lightness',1);
g(2,3).set_order_options('linestyle',-1,'row',{'CorS','CorM','CorL'},'color',{'CorS','CorM','CorL'});
g(2,3).set_layout_options('Position',[0.7 0 0.3 0.5]);
% g(2,3).set_title("Accuracy (3FPs)");
g(2,3).no_legend;

cenName = split(string(estMethod),'-');
cenName = cenName(1);
g.set_title("Day-by-day Performance: " + taskrange +" ("+cenName+"-"+errMethod+")");

figure('Name',"LearningComparison",'unit', 'centimeters', 'position',[1 1 27 15], 'paperpositionmode', 'auto')

g.draw();

maxCol = size(g(1,3).facet_axes_handles,2);
marker05 = findobj(g(1,3).facet_axes_handles(1,maxCol),'String','RTS');
marker10 = findobj(g(1,3).facet_axes_handles(2,maxCol),'String','RTM');
marker15 = findobj(g(1,3).facet_axes_handles(3,maxCol),'String','RTL');
marker05.String = 'RT min';
marker10.String = 'RT mid';
marker15.String = 'RT max';
marker05 = findobj(g(2,3).facet_axes_handles(1,maxCol),'String','CorS');
marker10 = findobj(g(2,3).facet_axes_handles(2,maxCol),'String','CorM');
marker15 = findobj(g(2,3).facet_axes_handles(3,maxCol),'String','CorL');
marker05.String = 'Cor min';
marker10.String = 'Cor mid';
marker15.String = 'Cor max';

%% Save
figName = "CompPerf_"+taskrange;
figPath = pwd;
figFile = fullfile(figPath,figName);
saveas(gcf, figFile, 'png');
saveas(gcf, figFile, 'fig');

end
%% Functions
function outT = estPerf(data,group,session,estMethod)
% estimate:
% grouping by trialtype
%   Trials
%   DarkTry
%   Accuracy
%   Premature
%   Late
%   maxFP
%   trials2maxFP & trial2criterion
%   HT
%   RT
%   MT

altMethod = {'mean-std','mean-sem','mean-bootci','quartile','geomean-geomad',...
    'geomean-bootci'};
switch nargin
    case 4
        estMethod = altMethod{1}; % default is mean-std
    case 5
        % pass
    otherwise
        error('Invalid input argument number');
end

outT = table;

if isempty(data)
    return;
end

sbj = data.Subject(1);
task = data.Task(1);

t = struct;
t.Subject = sbj;
t.Group = group;
t.Session = session;
t.Task = task;

tdata = data(data.Type~=0,:);

t.maxFP = max(tdata.FP);
t.t2mFP = find(tdata.FP==t.maxFP,1,'first');
t.minRW = min(tdata.RW);
t.t2mRW = find(tdata.RW==t.minRW,1,'first');

flag750 = string(task)=="ThreeFPsMixedBpod750_1250_1750";
flag500 = string(task)=="ThreeFPsMixedBpod";
if flag500 || flag750
    t2cri = find(abs(tdata.FP-1.4)<1e-4,1,'last');
    if ~isempty(t2cri)
        t2cri = t2cri + 1;
        tdata = tdata(t2cri:end,:);
        t2cInv = 1./(t2cri-0); % or -10: possible trials cost at least to achieve criterion
    else
        t2cInv = 0;
    end
elseif string(task)=="Wait2Bpod"
    t2cri = find(abs(tdata.FP-1.5)<1e-4 & abs(tdata.RW-0.6)<1e-4,1,'first');
    if ~isempty(t2cri)
        t2cInv = 1./(t2cri-0); % or -56;
    else
        t2cInv = 0;
    end
else
    t2cri = find(abs(tdata.FP-1.5)<1e-4,1,'first');
    if ~isempty(t2cri)
        t2cInv = 1./(t2cri-0); % or -40
    else
        t2cInv = 0;
    end
end
t.t2cInv = t2cInv;

t.nTrial = length(tdata.iTrial);
t.TrialRatio = t.nTrial./size(data,1);
t.Cor  = sum(tdata.Type==1)./t.nTrial;
t.Pre  = sum(tdata.Type==-1)./t.nTrial;
t.Late = sum(tdata.Type==-2)./t.nTrial;

if flag750
    fplist = [0.75,1.25,1.75];
else
    fplist = [0.5,1.0,1.5];
end
t.CorS = sum(tdata.Type==1 & abs(tdata.FP-fplist(1))<1e-4)./sum(abs(tdata.FP-fplist(1))<1e-4);
t.CorM = sum(tdata.Type==1 & abs(tdata.FP-fplist(2))<1e-4)./sum(abs(tdata.FP-fplist(2))<1e-4);
t.CorL = sum(tdata.Type==1 & abs(tdata.FP-fplist(3))<1e-4)./sum(abs(tdata.FP-fplist(3))<1e-4);

rt = compute_stat_summary(tdata(tdata.Type==1,:).RT,estMethod);
rtS = compute_stat_summary(tdata(tdata.Type==1 & abs(tdata.FP-fplist(1))<1e-4,:).RT,...
    estMethod);
rtM = compute_stat_summary(tdata(tdata.Type==1 & abs(tdata.FP-fplist(2))<1e-4,:).RT,...
    estMethod);
rtL = compute_stat_summary(tdata(tdata.Type==1 & abs(tdata.FP-fplist(3))<1e-4,:).RT,...
    estMethod);
t.RT = rt(1);
t.RTS = rtS(1);
t.RTM = rtM(1);
t.RTL = rtL(1);

outT = [outT;struct2table(t)];

end

