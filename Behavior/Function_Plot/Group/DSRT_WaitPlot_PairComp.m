function DSRT_WaitPlot_PairComp(btAll2d,grpVar,taskfilter)
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
TBT = table;
for i=1:size(btAll2d,1) % subjects
    for j=1:size(btAll2d,2) % sessions
        tempT = btAll2d{i,j};
        % point estimate data for each session
        estT = [estT; estPerf_Wait(tempT,grpVar(i),taskfilter,j,estMethod)];
        % trial by trial data
        nrow = size(tempT,1);
        if nrow>0
            tempGrp = repelem(grpVar(i),nrow)';
            tempT_new = addvars(tempT,tempGrp,'Before','Date','NewVariableNames','Group');
            tempT_new.Date = repelem(j,nrow)';
            tempT_new.Properties.VariableNames{'Date'} = 'Session';
            TBT = [TBT;tempT_new];
        end
    end
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
cCor_Pre_Late = [cGreen;cRed;cGray];
cFP = rainbow(15);
c3FPs = YlOrBr(5);c3FPs = c3FPs(3:end,:);

if string(taskfilter)=="3FPs"
    fpestT = stack(estT,{'nTrial','Dark'});
    g(1,1) = gramm('X',fpestT.Session,'Y',fpestT.nTrial_Dark,'linestyle',cellstr(fpestT.Group));
    g(1,1).facet_grid(fpestT.nTrial_Dark_Indicator, cellstr(fpestT.Type),'scale','free_y');
    g(1,1).stat_summary('type',errMethod,'geom',{'area','point'},'dodge',0.4);
    g(1,1).axe_property('xticklabels', {}, 'XGrid', 'on', 'YGrid', 'on');
    g(1,1).set_names('x','', 'y', '','column', '','row','','color','','linestyle','');
    g(1,1).set_line_options('base_size',1.2,'styles',{'-',':'});g(1,1).set_point_options('base_size',4);
    g(1,1).set_color_options('map',cDarkGray,'n_color',1,'n_lightness',1);
    g(1,1).set_order_options('linestyle',1,'row',{'nTrial','Dark'});
    g(1,1).set_layout_options('Position',[0 0.6 0.4 0.4]);
    g(1,1).no_legend;
    
    cestT = stack(estT,{'Cor05','Cor10','Cor15'});
    g(2,1) = gramm('X',cestT.Session,'Y',cestT.Cor05_Cor10_Cor15,'linestyle',cellstr(cestT.Group),...
        'color',cestT.Cor05_Cor10_Cor15_Indicator);
    g(2,1).facet_grid(cestT.Cor05_Cor10_Cor15_Indicator, cellstr(cestT.Type), 'column_labels',false);
    g(2,1).stat_summary('type',errMethod,'geom',{'area','point'},'dodge',0.4);
    g(2,1).axe_property('XTickLabelRotation', 90, 'XGrid', 'on', 'YGrid', 'on');
    g(2,1).set_names('x','Session#', 'y', '','column', '','row','','color','','linestyle','');
    g(2,1).set_line_options('base_size',1.2,'styles',{'-',':'});g(2,1).set_point_options('base_size',4);
    g(2,1).set_color_options('map',c3FPs,'n_color',3,'n_lightness',1);
    g(2,1).set_order_options('linestyle',1,'row',{'Cor05','Cor10','Cor15'},'color',{'Cor05','Cor10','Cor15'});
    g(2,1).set_layout_options('Position',[0 0 0.4 0.6]);
    g(2,1).set_title("Correct (3FPs)");
    g(2,1).no_legend;
else
    if string(taskfilter)=="Wait2"
        fpestT = stack(estT,{'nTrial','Dark','maxFP','minRW','t2cInv'});
        g(1,1) = gramm('X',fpestT.Session,'Y',fpestT.nTrial_Dark_maxFP_minRW_t2cInv,'linestyle',cellstr(fpestT.Group));
        g(1,1).facet_grid(fpestT.nTrial_Dark_maxFP_minRW_t2cInv_Indicator, cellstr(fpestT.Type),'scale','free_y');
    else
        fpestT = stack(estT,{'nTrial','Dark','maxFP','t2cInv'});
        g(1,1) = gramm('X',fpestT.Session,'Y',fpestT.nTrial_Dark_maxFP_t2cInv,'linestyle',cellstr(fpestT.Group));
        g(1,1).facet_grid(fpestT.nTrial_Dark_maxFP_t2cInv_Indicator, cellstr(fpestT.Type),'scale','free_y');
    end
    g(1,1).stat_summary('type',errMethod,'geom',{'area','point'},'dodge',0.4);
    g(1,1).axe_property('XTickLabelRotation', 90, 'XGrid', 'on', 'YGrid', 'on');
    g(1,1).set_names('x','Session#', 'y', '','column', '','row','','color','','linestyle','');
    g(1,1).set_line_options('base_size',1.2,'styles',{'-',':'});g(1,1).set_point_options('base_size',4);
    g(1,1).set_color_options('map',cDarkGray,'n_color',1,'n_lightness',1);
    g(1,1).set_order_options('linestyle',1,'row',{'nTrial','Dark','t2cInv','maxFP','minRW'});
    g(1,1).set_layout_options('Position',[0 0 0.4 1]);
    g(1,1).no_legend;
end
% RT
g(1,2) = gramm('X',estT.Session,'Y',estT.RT,'linestyle',cellstr(estT.Group));
g(1,2).facet_grid([], cellstr(estT.Type));
g(1,2).stat_summary('type',errMethod,'geom',{'area','point'},'dodge',0.4);
g(1,2).set_color_options('map',cBlue,'n_color',1,'n_lightness',2);
g(1,2).set_line_options('base_size',1.2,'styles',{'-',':'});g(1,2).set_point_options('base_size',4);
g(1,2).axe_property('xticklabels', {}, 'XGrid', 'on', 'YGrid', 'on');
g(1,2).set_names('x',{}, 'y', 'RT(s)','column', '','linestyle','');
g(1,2).set_order_options('linestyle',1);
g(1,2).set_layout_options('Position',[0.4 0.7 0.4 0.3]);
g(1,2).no_legend;
% Cor-Pre-Late
mestT = stack(estT,{'Cor','Pre','Late'});
g(2,2) = gramm('X',mestT.Session,'Y',mestT.Cor_Pre_Late,...
    'color',mestT.Cor_Pre_Late_Indicator,'linestyle',cellstr(mestT.Group));
g(2,2).facet_grid([], cellstr(mestT.Type), 'column_labels',false);
g(2,2).stat_summary('type',errMethod,'geom',{'area','point'},'dodge',0.4);
g(2,2).axe_property('ylim', [0 0.9], 'XTickLabelRotation', 90, 'XGrid', 'on', 'YGrid', 'on');
g(2,2).set_names('x','Session#', 'y', 'Proportion','column', '','color','','column','','linestyle','');
g(2,2).set_line_options('base_size',1.2,'styles',{'-',':'});g(2,2).set_point_options('base_size',4);
g(2,2).set_color_options('map',cCor_Pre_Late,'n_color',3,'n_lightness',2);
g(2,2).set_order_options('color',{'Cor','Pre','Late'},'linestyle',1);
g(2,2).set_layout_options('Position',[0.4 0 0.4 0.7],'legend_position',[0.66,0.26,0.2,0.23]);
% Progress comparison
g(1,3) = gramm('x',TBT.TimeElapsed,'y',TBT.iTrial,...
    'group',cellstr(TBT.Subject+string(TBT.Session)),'color',TBT.BlockNum,...
    'subset',TBT.Task==string(taskfilter));
g(1,3).facet_grid(cellstr(TBT.Group),[]);
g(1,3).axe_property('xlim',[0 4000],'XGrid', 'on', 'YGrid', 'on');
g(1,3).geom_line();g(1,3).set_line_options('base_size',0.8);
g(1,3).set_names('x','Time(s)','y','Trial#','group','','color','Block#','row','');
g(1,3).set_continuous_color('colormap','parula');
g(1,3).set_layout_options('Position',[0.8 0 0.2 1],'legend_position',[0.86,0.74,0.15,0.2]);

cenName = split(string(estMethod),'-');
cenName = cenName(1);
g.set_title(string(taskfilter)+" Performance ("+cenName+"-"+errMethod+")");

figure('Name',string(taskfilter)+"Cmp",'unit', 'centimeters', 'position',[1 1 27 15], 'paperpositionmode', 'auto')

g.draw();

if string(taskfilter)=="3FPs"
    if ~isempty(findobj(g(2,1).facet_axes_handles(1,1),'String','Cor05'))
        loc = 1;
    else
        loc = 2;
    end
    marker05 = findobj(g(2,1).facet_axes_handles(1,loc),'String','Cor05');
    marker10 = findobj(g(2,1).facet_axes_handles(2,loc),'String','Cor10');
    marker15 = findobj(g(2,1).facet_axes_handles(3,loc),'String','Cor15');
    marker05.String = 'FP 0.5s';
    marker10.String = 'FP 1.0s';
    marker15.String = 'FP 1.5s';
end

%% Save
figName = string(taskfilter)+"CompPerf";
figPath = pwd;
% if ~exist(figPath,'dir')
%     mkdir(figPath);
% end
figFile = fullfile(figPath,figName);
saveas(gcf, figFile, 'png');
saveas(gcf, figFile, 'fig');

end

function outT = estPerf_Wait(data,group,taskfilter,session,estMethod)
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

if isempty(data) || data.Task(1)~=string(taskfilter)
    return;
end

sbj = data.Subject(1);
task = data.Task(1);

typename = unique(data.TrialType);
for i=1:length(typename)
    t = struct;
    t.Subject = sbj;
    t.Group = group;
    t.Session = session;
    t.Task = task;
    t.Type = typename(i);
    tdata = data(data.TrialType==t.Type,:);
    
    t.nBlock = length(unique(tdata.BlockNum));
    t.nTrial = length(tdata.iTrial);
    t.Dark   = sum(tdata.DarkTry);
    t.Cor  = sum(tdata.Outcome=="Cor")./t.nTrial;
    t.Pre  = sum(tdata.Outcome=="Pre")./t.nTrial;
    t.Late = sum(tdata.Outcome=="Late")./t.nTrial;
    
    t.Cor05 = sum(tdata.Outcome=="Cor" & abs(tdata.FP-0.5)<1e-4)./length(find(abs(tdata.FP-0.5)<1e-4));
    t.Cor10 = sum(tdata.Outcome=="Cor" & abs(tdata.FP-1.0)<1e-4)./length(find(abs(tdata.FP-1.0)<1e-4));
    t.Cor15 = sum(tdata.Outcome=="Cor" & abs(tdata.FP-1.5)<1e-4)./length(find(abs(tdata.FP-1.5)<1e-4));
    
    t.maxFP = max(tdata.FP);
    t.t2mFP = find(tdata.FP==t.maxFP,1,'first');
    t.minRW = min(tdata.RW);
    t.t2mRW = find(tdata.RW==t.minRW,1,'first');

    if string(taskfilter)=="Wait2"
        t2cri = find(abs(tdata.FP-1.5)<1e-4 & abs(tdata.RW-0.6)<1e-4,1,'first');
    else
        t2cri = find(abs(tdata.FP-1.5)<1e-4,1,'first');
    end
    if isempty(t2cri)
        t2cInv = 0;
    elseif t2cri==1
        t2cInv = NaN;
    else
        t2cInv = 1./t2cri;
    end
    t.t2cInv = t2cInv;

    ht = compute_stat_summary(tdata.HT,estMethod);
    rt = compute_stat_summary(tdata(tdata.Outcome=="Cor",:).RT,estMethod);
    mt = compute_stat_summary(tdata(tdata.Outcome=="Cor",:).MT,estMethod);
    t.HT = ht(1); % just need central tendency estimation
    t.RT = rt(1);
    t.MT = mt(1);
    
    outT = [outT;struct2table(t)];
end

end