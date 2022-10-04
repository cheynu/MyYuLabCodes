function h = DSRT_WaitPlot_Individual(btAll,taskfilter)
%% data session-by-session
SBS = struct;
SBS.Date = {};
SBS.Type = [];
SBS.nBlock = [];
SBS.nTrial = [];
SBS.Dark = [];
SBS.Cor = [];
SBS.Pre = [];
SBS.Late = [];
SBS.maxFP = []; % max FP achieved
SBS.t2mFP = []; % trial to max FP
SBS.minRW = [];
SBS.t2mRW = [];
nameType = ["Lever";"Poke"];
for i=1:length(btAll)
    bt = btAll{i}(btAll{i}.Task==string(taskfilter),:);
    for j=1:length(unique(bt.TrialType))
        btt = bt(bt.TrialType==nameType(j),:);
        tmp_date   = num2str(bt.Date(1));
        SBS.Date   = [SBS.Date;   string(tmp_date(end-3:end))];
        SBS.Type   = [SBS.Type;   nameType(j)];
        SBS.nBlock = [SBS.nBlock; length(unique(btt.BlockNum))];
        nTrial     = length(btt.iTrial);
        SBS.nTrial = [SBS.nTrial; nTrial];
        SBS.Dark   = [SBS.Dark;   sum(btt.DarkTry)];
        SBS.Cor    = [SBS.Cor;    sum(btt.Outcome=="Cor")./nTrial];
        SBS.Pre    = [SBS.Pre;    sum(btt.Outcome=="Pre")./nTrial];
        SBS.Late   = [SBS.Late;   sum(btt.Outcome=="Late")./nTrial];
        SBS.maxFP  = [SBS.maxFP;  max(btt.FP)];
        SBS.t2mFP  = [SBS.t2mFP;  find(btt.FP==max(btt.FP),1,'first')];
        SBS.minRW  = [SBS.minRW;  min(btt.RW)];
        SBS.t2mRW  = [SBS.t2mRW;  find(btt.RW==min(btt.RW),1,'first')];
    end
end
SBS = struct2table(SBS);
SBS_nd = stack(SBS,{'nTrial','Dark'});
SBS_cpl = stack(SBS,{'Cor','Pre','Late'});

%% data trial-by-trial
TBT = table;
for i=1:length(btAll)
    TBT = [TBT;btAll{i}(btAll{i}.Task==string(taskfilter),:)];
end
% date, block_length
date_str = num2str(TBT.Date);
TBT.Date = string(date_str(:,end-3:end));
block_length = length(unique(TBT.TrialNum));
% BlockOrder for each type
ind_lever = TBT.TrialType == "Lever";
ind_poke  = TBT.TrialType == "Poke";
BlockOrder = TBT.BlockNum./2;
BlockOrder(ind_lever) = ceil(BlockOrder(ind_lever));
BlockOrder(ind_poke) = floor(BlockOrder(ind_poke));
TBT = addvars(TBT, BlockOrder, 'After','BlockNum');
% summarize each trial's confusing try (e.g., poke in lever block) & recent 5 confusing trial
ConfuseNum = double(TBT.ConfuseNum>0);
ConfuseRecent = ConfuseNum + ...
    [0;ConfuseNum(1:end-1)] + ...
    [0;0;ConfuseNum(1:end-2)] + ...
    [0;0;0;ConfuseNum(1:end-3)] + ...
    [0;0;0;0;ConfuseNum(1:end-4)];
TBT = addvars(TBT, ConfuseRecent, 'After','ConfuseNum');
% TBT_NoConfuse = table;
% [~,iT_date,~] = unique(TBT.Date,'stable');
% for i=1:length(iT_date)
%     if i==length(iT_date)
%         dateT = TBT(iT_date(i):end,:);
%     else
%         dateT = TBT(iT_date(i):iT_date(i+1)-1,:);
%     end
%     [~,iT_block,~] = unique(dateT.BlockNum,'stable');
%     for j=1:length(iT_block)
%         if j==length(iT_block)
%             blockT = dateT(iT_block(j):end,:);
%         else
%             blockT = dateT(iT_block(j):iT_block(j+1)-1,:);
%         end
%         firstNoConfuse = blockT.TrialNum(find(blockT.TrialNum>=5 ...
%             & blockT.ConfuseRecent<=1,1,'first'));
%         if isempty(firstNoConfuse) && blockT.TrialNum(end)==block_length
%             firstNoConfuse = block_length;
%         end
%         TBT_NoConfuse = [TBT_NoConfuse;blockT(firstNoConfuse,:)];
%     end
% end

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
cFP = rainbow(15);
c3FPs = YlOrBr(3);

% TrialNum & dark num
g(1,1) = gramm('X',cellstr(SBS_nd.Date),'Y',SBS_nd.nTrial_Dark,'color',SBS_nd.nTrial_Dark_Indicator);
g(1,1).facet_grid([], cellstr(SBS_nd.Type));
g(1,1).geom_point(); g(1,1).set_point_options('base_size',7);
g(1,1).geom_line();  g(1,1).set_line_options('base_size',2);
g(1,1).axe_property('ylim', [0 400], 'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'on');
g(1,1).set_names('x',{}, 'y', 'Num','column', '','color','');
g(1,1).set_color_options('map',[cDarkGray;cGray],'n_color',2,'n_lightness',1);
g(1,1).set_order_options('color',{'Dark','nTrial'});
g(1,1).set_layout_options('Position',[0 0.85 1 0.15],'legend_position',[0.9,0.88,0.1,0.1]);
% Cor-Pre-Late
g(2,1) = gramm('X',cellstr(SBS_cpl.Date),'Y',SBS_cpl.Cor_Pre_Late,'color',SBS_cpl.Cor_Pre_Late_Indicator);
g(2,1).facet_grid([], cellstr(SBS_cpl.Type), 'column_labels',false);
g(2,1).geom_point(); g(2,1).set_point_options('base_size',7);
g(2,1).geom_line();  g(2,1).set_line_options('base_size',2);
g(2,1).axe_property('ylim', [0 1], 'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'on');
g(2,1).set_names('x',{}, 'y', 'Proportion','column', '','color','');
g(2,1).set_color_options('map',cCor_Pre_Late,'n_color',3,'n_lightness',1);
g(2,1).set_order_options('color',{'Cor','Pre','Late'});
% g(2,1).set_layout_options('Position',[0 0.55 1 0.3],'legend_position',[0.51,0.68,0.15,0.15]);
g(2,1).set_layout_options('Position',[0 0.55 1 0.3],'legend_position',[0.91,0.58,0.1,0.15]);
% maxFP & Trial2maxFP
if string(taskfilter)=="3FPs"
    ylim_rt = [0 0.6];
    g(3,1) = gramm('X',cellstr(TBT.Date),'Y',TBT.RT,'color',TBT.FP);
    g(3,1).facet_grid([], cellstr(TBT.TrialType), 'column_labels',false);
    g(3,1).stat_boxplot('width',0.4);
    g(3,1).set_color_options('map',c3FPs,'n_color',3,'n_lightness',1);
    g(3,1).axe_property('ylim', ylim_rt, 'xticklabels',{}, 'XGrid', 'on', 'YGrid', 'on');
    g(3,1).set_names('x',{}, 'y', 'RT(s)','column', '','color','FP (s)');
    g(3,1).set_order_options('color',1);
%     g(3,1).set_layout_options('Position',[0 0.3 1 0.25],'legend_position',[0.502,0.37,0.18,0.15]);
    g(3,1).set_layout_options('Position',[0 0.3 1 0.25],'legend_position',[0.92,0.3,0.08,0.2]);
elseif string(taskfilter)=="Wait2"
    % x-date, y-mFP/RW, color-t2FP/RW group-FP/RW indicator
    SBS_t = stack(SBS,{'t2mFP','t2mRW'});
    SBS_frt = stack(SBS_t,{'maxFP','minRW'});
    str_t = char(SBS_frt.t2mFP_t2mRW_Indicator);
    str_fr = char(SBS_frt.maxFP_minRW_Indicator);
    delrow = str_t(:,end)~=str_fr(:,end);
    SBS_fr = SBS_frt; SBS_fr(delrow,:) = [];
    simp = char(SBS_fr.maxFP_minRW_Indicator);
    SBS_fr.maxFP_minRW_Indicator = categorical(cellstr(simp(:,end-1:end)));
    g(3,1) = gramm('X',cellstr(SBS_fr.Date),'Y',SBS_fr.maxFP_minRW,...
        'color',SBS_fr.t2mFP_t2mRW,'linestyle',SBS_fr.maxFP_minRW_Indicator);
    g(3,1).facet_grid([], cellstr(SBS_fr.Type), 'column_labels',false);
    g(3,1).axe_property('ylim', [0 2], 'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'on');
    g(3,1).set_names('x',{}, 'y','trmlLevel(trials)','column','','color','t2FP/RW','linestyle','');
    g(3,1).geom_point(); g(3,1).set_point_options('base_size',7);
    g(3,1).geom_line();  g(3,1).set_line_options('base_size',2,'style',{'-',':'});
    g(3,1).set_continuous_color('colormap','parula');
%     g(3,1).set_layout_options('Position',[0 0.3 1 0.25],'legend_position',[0.55,0.31,0.15,0.2]);
    g(3,1).set_layout_options('Position',[0 0.3 1 0.25],'legend_position',[0.9,0.3,0.1,0.2]);
    ylim_rt = [0 1.5];
else
    g(3,1) = gramm('X',cellstr(SBS.Date),'Y',SBS.maxFP,'color',SBS.t2mFP);
    g(3,1).facet_grid([], cellstr(SBS.Type), 'column_labels',false);
    g(3,1).axe_property('ylim', [0 1.5], 'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'on');
    g(3,1).set_names('x',{}, 'y', 'maxFP(s)','column', '','color','Trial2FP');
    g(3,1).geom_point(); g(3,1).set_point_options('base_size',7);
    g(3,1).geom_line();  g(3,1).set_line_options('base_size',2);
    g(3,1).set_continuous_color('colormap','parula');
%     g(3,1).set_layout_options('Position',[0 0.3 1 0.25],'legend_position',[0.51,0.32,0.15,0.2]);
    g(3,1).set_layout_options('Position',[0 0.3 1 0.25],'legend_position',[0.87,0.28,0.15,0.2]);
    ylim_rt = [0 1.5];
end
% RT
% g(4,1) = gramm('X',cellstr(TBT.Date),'Y',TBT.RT,'color',TBT.FP,'subset',TBT.Outcome=="Cor" & TBT.FP>0);
g(4,1) = gramm('X',cellstr(TBT.Date),'Y',TBT.RT,'subset',TBT.Outcome~="Pre");
g(4,1).facet_grid([], cellstr(TBT.TrialType), 'column_labels',false);
g(4,1).stat_boxplot('width', 0.4,'notch',true); g(4,1).set_color_options('map',cBlue,'n_color',1,'n_lightness',1);
% g(4,1).geom_jitter('width', 0.5,'height',0); g(4,1).set_color_options('map',cFP,'n_color',15,'n_lightness',1);
g(4,1).set_point_options('base_size',4);
g(4,1).axe_property('ylim', ylim_rt, 'XTickLabelRotation', 90, 'XGrid', 'on', 'YGrid', 'on');
g(4,1).set_names('x',{}, 'y', 'RT(s)','column', '','color','FP(s)');
g(4,1).set_layout_options('Position',[0 0 1 0.3]);

g.set_title(TBT.Subject(1)+": "+string(taskfilter));

h = figure(3);clf(h);
set(h,'Name','WaitFig','unit', 'centimeters', ...
    'position',[1 1 16 20], 'paperpositionmode', 'auto')

g.draw();

%% Save
figName = string(taskfilter)+"Performance_" + TBT.Subject(1) + "_" + TBT.Date(1) + "-" + TBT.Date(end);
figPath = fullfile(pwd,'IndivFig');
if ~exist(figPath,'dir')
    mkdir(figPath);
end
figFile = fullfile(figPath,figName);
saveas(h, figFile, 'png');
saveas(h, figFile, 'fig');

end

