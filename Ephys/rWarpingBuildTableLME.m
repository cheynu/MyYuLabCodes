function [T, LMEresult] = rWarpingBuildTableLME(r, chanMap, ifPlot, opts)
%RWARPINGBUILDTABLELME 此处显示有关此函数的摘要
%   此处显示详细说明
arguments (Input)
    r = []
    chanMap = []
    ifPlot = true
    opts.SavePath = pwd
    opts.PlotDepthSegment = false
    opts.EdgeSegment = linspace(0, 3840, 4) % default: maxDepth of NP1.0, divide into 3 same length segments
    opts.CorrectionMethod {mustBeMember(opts.CorrectionMethod,{'bonferroni','fdr_bh','fdr_storey'})} = 'fdr_bh'
    opts.SaveSDF = true
    opts.FolderSDF = 'Figures_WarpedPSTHs'
end

if isempty(r) || isempty(chanMap)
    fprintf('Load data from EventLME.csv\n\n');
    readExistingT = true;
else
    readExistingT = false;
end

savepath = opts.SavePath;
ifPlotSegment = opts.PlotDepthSegment;
edgeDepth = opts.EdgeSegment;
nSegment = length(edgeDepth)-1;
corrMethod = opts.CorrectionMethod;
ifSaveSDF = opts.SaveSDF;
pathSDF = fullfile(savepath,opts.FolderSDF);
%% Initiation
LME = struct;
LME.UnitIndex = [];
LME.Channel = [];
LME.Unit = [];
LME.UnitQuality = [];
LME.p.press = [];
LME.p.trigger = [];
LME.p.poke = [];
LME.contrast.est.press = [];
LME.contrast.est.trigger = [];
LME.contrast.est.poke = [];
LME.contrast.se.press = [];
LME.contrast.se.trigger = [];
LME.contrast.se.poke = [];
LME.contrast.ciLower.press = [];
LME.contrast.ciLower.trigger = [];
LME.contrast.ciLower.poke = [];
LME.contrast.ciUpper.press = [];
LME.contrast.ciUpper.trigger = [];
LME.contrast.ciUpper.poke = [];

if ~readExistingT

iTic = tic;
for iUnit=1:size(r.Units.SpikeNotes,1)
    s = Spikes.SRT.rPSTHWarped(r,iUnit);
    [stat_out, ~] = Spikes.SRT.rPSTH_lme(s);
    
    if ifSaveSDF
        thisSaveName = [s.subject, '_', s.session, '_Ch', num2str(s.unit.ch(1)), '_Unit', num2str(s.unit.ch(2)), '_Warped', '.mat'];
        save(fullfile(pathSDF,thisSaveName),'s','-mat');
    end
    
    LME.UnitIndex = [LME.UnitIndex; iUnit];
    LME.Channel = [LME.Channel; r.Units.SpikeNotes(iUnit,1)];
    LME.Unit = [LME.Unit; r.Units.SpikeNotes(iUnit,2)];
    LME.UnitQuality = [LME.UnitQuality; r.Units.SpikeNotes(iUnit,3)];
    
    LME.p.press = [LME.p.press; stat_out.pvals.press];
    LME.p.trigger = [LME.p.trigger; stat_out.pvals.trigger];
    LME.p.poke = [LME.p.poke; stat_out.pvals.poke];

    LME.contrast.est.press = [LME.contrast.est.press; stat_out.contrast.est_press];
    LME.contrast.est.trigger = [LME.contrast.est.trigger; stat_out.contrast.est_trigger];
    LME.contrast.est.poke = [LME.contrast.est.poke; stat_out.contrast.est_poke];

    LME.contrast.se.press = [LME.contrast.se.press; stat_out.contrast.se_press];
    LME.contrast.se.trigger = [LME.contrast.se.trigger; stat_out.contrast.se_trigger];
    LME.contrast.se.poke = [LME.contrast.se.poke; stat_out.contrast.se_poke];

    LME.contrast.ciLower.press = [LME.contrast.ciLower.press; stat_out.contrast.ci_press_lower];
    LME.contrast.ciLower.trigger = [LME.contrast.ciLower.trigger; stat_out.contrast.ci_trigger_lower];
    LME.contrast.ciLower.poke = [LME.contrast.ciLower.poke; stat_out.contrast.ci_poke_lower];

    LME.contrast.ciUpper.press = [LME.contrast.ciUpper.press; stat_out.contrast.ci_press_upper];
    LME.contrast.ciUpper.trigger = [LME.contrast.ciUpper.trigger; stat_out.contrast.ci_trigger_upper];
    LME.contrast.ciUpper.poke = [LME.contrast.ciUpper.poke; stat_out.contrast.ci_poke_upper];

    fprintf('%.0f seconds, finished units: %d / %d\n\n', toc(iTic), iUnit, size(r.Units.SpikeNotes,1));

    clear s;
end
%% add information
Subjects = repelem(string(r.BehaviorClass.Subject), iUnit, 1);
Sessions = repelem(string(r.BehaviorClass.Session), iUnit, 1);
Protocols = repelem(string(r.BehaviorClass.Protocol), iUnit, 1);

idxUseCh = chanMap.connected;
chanLoc = struct;
chanLoc.ch = (1:sum(idxUseCh))';
chanLoc.x = chanMap.xcoords(idxUseCh);
chanLoc.y = chanMap.ycoords(idxUseCh);
chanLoc.k = chanMap.kcoords(idxUseCh);

rCh = r.Units.SpikeNotes(:,1);
locX = chanLoc.x(rCh);
locY = chanLoc.y(rCh);
locK = chanLoc.k(rCh);
%% Build table
T = table(Subjects, Sessions, Protocols,...
    LME.UnitIndex, LME.Channel, LME.Unit, LME.UnitQuality,...
    locX, locY, locK,...
    LME.p.press, LME.p.trigger, LME.p.poke,...
    LME.contrast.est.press, LME.contrast.est.trigger, LME.contrast.est.poke,...
    LME.contrast.se.press, LME.contrast.se.trigger, LME.contrast.se.poke,...
    LME.contrast.ciLower.press, LME.contrast.ciLower.trigger, LME.contrast.ciLower.poke,...
    LME.contrast.ciUpper.press, LME.contrast.ciUpper.trigger, LME.contrast.ciUpper.poke,...
    'VariableNames',{'Subject','Session','Protocol',...
    'Index', 'Chs', 'Ch_Units', 'Unit_Quality_Num',...
    'PositionX', 'PositionY', 'PositionK',...
    'pval_press', 'pval_trigger', 'pval_poke',...
    'est_press', 'est_trigger', 'est_poke',...
    'se_press', 'se_trigger', 'se_poke',...
    'ci_press_lower', 'ci_trigger_lower', 'ci_poke_lower',...
    'ci_press_upper', 'ci_trigger_upper', 'ci_poke_upper'});
writetable(T,fullfile(savepath,'EventLME.csv'),'WriteMode','overwrite');
clear T;
end
% 读取数据table & calculating
targetT = fullfile(savepath,'EventLME.csv');
if isfile(targetT)
    T = readtable(targetT);

    alpha = 0.05;
    switch corrMethod
        case 'bonferroni'
            isPress   = T.pval_press.*3   < alpha;
            isTrigger = T.pval_trigger.*3 < alpha;
            isPoke    = T.pval_poke.*3    < alpha;
        case 'fdr_bh'
            [~,~,~,pEvents] = fdr_bh([T.pval_press, T.pval_trigger, T.pval_poke]);
            % same result compared with: mafdr([T.pval_press; T.pval_trigger; T.pval_poke], 'BHFDR', true);
            
            pPress = pEvents(:,1);
            pTrigger = pEvents(:,2);
            pPoke = pEvents(:,3);
            
            isPress = pPress < alpha;
            isTrigger = pTrigger < alpha;
            isPoke = pPoke < alpha;
        case 'fdr_storey'
            pEvents = mafdr([T.pval_press; T.pval_trigger; T.pval_poke], 'BHFDR', false);
    
            nUnit = length(T.pval_press);
            pPress = pEvents(1:nUnit);
            pTrigger = pEvents((1:nUnit)+nUnit);
            pPoke = pEvents((1:nUnit)+2*nUnit);
    
            isPress = pPress < alpha;
            isTrigger = pTrigger < alpha;
            isPoke = pPoke < alpha;
    end
    
    Data = struct;
    Data.Labels = {'Press','Trigger','Poke'};
    Data.All = [isPress isTrigger isPoke];
    
    idxSingle = T.Unit_Quality_Num==1;
    Data.Single = [isPress(idxSingle), isTrigger(idxSingle), isPoke(idxSingle)];
    
    % segment info
    Data.SegDepth = cell(1,nSegment);
    Data.SegAll = cell(1,nSegment);
    Data.SegSingle = cell(1,nSegment);

    TTidx = cell(1,nSegment);
    TT = cell(1,nSegment);
    for i=1:nSegment
        thisDepth = [edgeDepth(i) edgeDepth(i+1)];
        if i==1
            idxRow = T.PositionY >= thisDepth(1) & T.PositionY <= thisDepth(2);
        else
            idxRow = T.PositionY > thisDepth(1) & T.PositionY <= thisDepth(2);
        end
        TTidx{i} = idxRow;
        TT{i} = T(idxRow,:);

        isPressThis = isPress(TTidx{i});
        isTriggerThis = isTrigger(TTidx{i});
        isPokeThis = isPoke(TTidx{i});
        
        Data.SegDepth{i} = thisDepth;
        Data.SegAll{i} = [isPressThis, isTriggerThis, isPokeThis];
        idxSingleThis = TT{i}.Unit_Quality_Num==1;
        Data.SegSingle{i} = [isPressThis(idxSingleThis), isTriggerThis(idxSingleThis), isPokeThis(idxSingleThis)];
    end
    LMEresult = Data;
else
    T = table;
    ifPlot = false;
    LMEresult = [];
end

%% Plot venn diagram
if ifPlot

if ifPlotSegment
    figureSize = [8.5 3.5*(nSegment+1)];
else
    figureSize = [8.5 5];
end

% plot Figure
hf = figure(173); clf(hf,"reset");
set(hf, 'Units','centimeters','Position',[1 1 figureSize],'Renderer','painters','PaperPositionMode','auto' );

% title
axTitle = axes('Position',[0.50 1 0.2 0.1]);
axTitle.XAxis.Visible='off';
axTitle.YAxis.Visible='off';
text(0,0,append(T.Subject(1),'  ',T.Session(1),'  ',T.Protocol(1)),...
    'HorizontalAlignment','center','VerticalAlignment','top',...
    'FontSize',8);

if ~ifPlotSegment
    posi1 = [1 1 3 3];
    posi2 = [5 1 3 3];
    % posi1 = [0.1 0.1 0.35 0.7];
    % posi2 = [0.6 0.1 0.35 0.7];
else
    yaxes = (figureSize(2)-2-1*nSegment)/(nSegment+1);
    posi1 = [1 0.7 3 yaxes];
    posi2 = [5.2 0.7 3 yaxes];
    % posi1 = [0.1 0.05 0.35 yaxes];
    % posi2 = [0.6 0.05 0.35 yaxes];
end

% 左侧 axes（All units）
ax1 = axes('Units','Centimeters','Position',posi1);
plotBar(ax1, Data.Labels, Data.All, 'All units')

% 右侧 axes（Single units）
ax2 = axes('Units','Centimeters','Position',posi2);
plotBar(ax2, Data.Labels, Data.Single,'Single units');
ylabel('');

if ifPlotSegment
    for i=1:nSegment
        % 左侧 axes（All units）
        ax1 = axes('Units','Centimeters','Position',[posi1(1) posi1(2)+i.*(yaxes+1) posi1(3) yaxes]);
        plotBar(ax1, Data.Labels, Data.SegAll{i}, sprintf('Depth %.0f-%.0f nm All', edgeDepth(i), edgeDepth(i+1)));
        
        % 右侧 axes（Single units）
        ax2 = axes('Units','Centimeters','Position',[posi2(1) posi2(2)+i.*(yaxes+1) posi2(3) yaxes]);
        plotBar(ax2, Data.Labels, Data.SegSingle{i}, sprintf('Single', edgeDepth(i), edgeDepth(i+1)));
        ylabel('');
    end

    % save figure
    print(hf,fullfile(savepath,'EventProportionDepth.png'),'-dpng','-r300');
else
    % save figure
    print(hf,fullfile(savepath,'EventProportion.png'),'-dpng','-r300');
end

end

end

%% Functions

function plotBar(ax,X,Y,titlename)
cBlue = [0.417647058823529	0.680392156862746	0.837254901960784];

axes(ax);

nUnit = size(Y,1);
prcData = round(100.*sum(Y./size(Y,1),1));
b = bar(X, prcData, 0.6,...
    'EdgeColor', 'none', 'FaceColor', cBlue);
ylim([0 max(prcData).*1.2]);

xtips1 = b(1).XEndPoints;
ytips1 = b(1).YEndPoints;
labels1 = string(b(1).YData);
text(xtips1,ytips1,labels1,'HorizontalAlignment','center',...
    'VerticalAlignment','bottom','FontSize',7, 'FontName','Helvetica');

box off;
ylabel('Modulated units (%)')
titlestr = sprintf('%s (n=%d)', titlename, nUnit);
title(titlestr);

end