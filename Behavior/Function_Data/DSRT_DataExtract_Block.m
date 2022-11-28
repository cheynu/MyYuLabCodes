function bt = DSRT_DataExtract_Block(filename,varargin)
p = inputParser;
addRequired(p,'filename');
addOptional(p,'plotmark',true);
addOptional(p,'path_arc',pwd,@isfolder);
parse(p,filename,varargin{:});

plotmark = p.Results.plotmark;
path_arc = p.Results.path_arc;
%%
load(filename,'SessionData');
data = SessionData;

% get sbj name and session date from filename
dname = split(string(filename), '_');
newName = dname(1);
newDate = str2double(dname(5));
Tstart = str2double(datestr(data.Info.SessionStartTime_MATLAB,'HHMMSS'));
% Tstart = str2double(char(datetime(data.Info.SessionStartTime_MATLAB,'convertfrom','datenum','Format','HHmmss')));
newTask = dname(4);
nTrials = data.nTrials;
cellCustom = struct2cell(data.Custom);
for i=1:length(cellCustom)
    if nTrials > length(cellCustom{i})
        nTrials = length(cellCustom{i});
        display(newName+"_"+newTask+"_"+newDate+"_CustomTrials ~= nTrials");
    end
end

Name = repelem(newName,nTrials)';
Date = repelem(newDate,nTrials)';
StartTime = repelem(Tstart,nTrials)';
Task = repelem(newTask,nTrials)';
iTrial = (1:nTrials)';
if ~isfield(data.Custom,'BlockNum')
    BlockNum = ones(nTrials,1);
    TrialNum = (1:nTrials)';
    TrialType = zeros(nTrials,1); % all is lever
else
    BlockNum = data.Custom.BlockNum(1:nTrials)';
    TrialNum = data.Custom.TrialNum(1:nTrials)';
    TrialType = data.Custom.TrialType(1:nTrials)';
end
TimeElapsed = data.Custom.TimeElapsed(1:nTrials)'; % start press or poke: wait4tone(1)
TimeElapsed(TimeElapsed>1e4) = NaN;
FP = round(data.Custom.ForePeriod(1:nTrials),1)';
RW = data.Custom.ResponseWindow(1:nTrials)';
DarkTry = [];
ConfuseNum = []; % e.g., try to poke in lever block
Outcome = data.Custom.OutcomeCode(1:nTrials)';
HT = []; % hold time
RT = data.Custom.ReactionTime(1:nTrials)';
MT = data.Custom.MovementTime(1:nTrials)';

alterTE = false;
if isnan(TimeElapsed)
    TimeElapsed = zeros(nTrials,1).*NaN;
    alterTE = true;
end

for i = 1:nTrials
    if isfield(data.RawEvents.Trial{1,i}.States,'TimeOut_reset') % dark try num
        if ~isnan(data.RawEvents.Trial{1,i}.States.TimeOut_reset)
            DarkTry = [DarkTry; size(data.RawEvents.Trial{1,i}.States.TimeOut_reset,1)];
        else
            DarkTry = [DarkTry; 0];
        end
    else
        DarkTry = [DarkTry; 0];
    end
    switch TrialType(i) % confuse try num
        case 0 % lever
            if isfield(data.RawEvents.Trial{1,i}.Events,'Port2In')
                ConfuseNum = [ConfuseNum; length(data.RawEvents.Trial{1,i}.Events.Port2In)];
            else
                ConfuseNum = [ConfuseNum; 0];
            end
        case 1 % poke
            if isfield(data.RawEvents.Trial{1,i}.Events,'BNC1High')
                ConfuseNum = [ConfuseNum; length(data.RawEvents.Trial{1,i}.Events.BNC1High)];
            elseif isfield(data.RawEvents.Trial{1,i}.Events,'RotaryEncoder1_1')
                ConfuseNum = [ConfuseNum; length(data.RawEvents.Trial{1,i}.Events.RotaryEncoder1_1)];
            else
                ConfuseNum = [ConfuseNum; 0];
            end
    end
    if isnan(data.RawEvents.Trial{1, i}.States.Wait4Tone) % HT start time
        if isfield(data.RawEvents.Trial{1, i}.States,'Delay')
            HT_ori = data.RawEvents.Trial{1, i}.States.Delay(2);
        else
            HT_ori = data.RawEvents.Trial{1, i}.Wait4Start(2);
        end
    else
        HT_ori = data.RawEvents.Trial{1, i}.States.Wait4Tone(end,1);
    end
    switch Outcome(i) % HT
        case 1
            HT = [HT; ...
                data.RawEvents.Trial{1, i}.States.Wait4Stop(2) - HT_ori];
        case -1
            if isfield(data.RawEvents.Trial{1, i}.States,'GracePeriod')
                HT = [HT;...
                    data.RawEvents.Trial{1, i}.States.GracePeriod(end,1) - HT_ori];
            else
                HT = [HT;...
                    data.RawEvents.Trial{1, i}.States.Premature(1) - HT_ori];
            end
        case -2
            HT = [HT;...
                data.RawEvents.Trial{1, i}.States.LateError(2) - HT_ori];
        otherwise
            HT = [HT;NaN];
    end
    if alterTE
        TimeElapsed(i) = data.TrialStartTimestamp(i) + HT_ori;
    end
end
% adjust name
ind_lever = TrialType == 0;
ind_poke  = TrialType == 1;
newType = string(TrialType);
newType(ind_lever) = repelem("Lever",sum(ind_lever))';
newType(ind_poke) = repelem("Poke" ,sum(ind_poke))';

ind_cor  = Outcome ==  1;
ind_pre  = Outcome == -1;
ind_late = Outcome == -2;
newOutcome = string(Outcome);
newOutcome(ind_cor) = repelem("Cor",sum(ind_cor)');
newOutcome(ind_pre) = repelem("Pre",sum(ind_pre)');
newOutcome(ind_late) = repelem("Late",sum(ind_late)');
% create table
tablenames = {'Subject','Date','StartTime','Task','iTrial','BlockNum','TrialNum','TrialType',...
    'TimeElapsed','FP','RW','DarkTry','ConfuseNum','Outcome','HT','RT','MT'};
bt = table(Name,Date,StartTime,Task,iTrial,BlockNum,TrialNum,newType,...
    TimeElapsed,FP,RW,DarkTry,ConfuseNum,newOutcome,HT,RT,MT,...
    'VariableNames',tablenames);

savename = 'B_' + upper(newName) + '_' + strrep(num2str(newDate), '-', '_') + '_' +...
    strrep(data.Info.SessionStartTime_UTC,':', '');
save(savename,'bt');
%% Plot progress
if plotmark
    plotDailyPerformance(bt,savename,path_arc);
end
end

function plotDailyPerformance(bt,savename,path_arc)
cTab10 = [0.0901960784313726,0.466666666666667,0.701960784313725;0.960784313725490,0.498039215686275,0.137254901960784;0.152941176470588,0.631372549019608,0.278431372549020;0.843137254901961,0.149019607843137,0.172549019607843;0.564705882352941,0.403921568627451,0.674509803921569;0.549019607843137,0.337254901960784,0.290196078431373;0.847058823529412,0.474509803921569,0.698039215686275;0.501960784313726,0.501960784313726,0.501960784313726;0.737254901960784,0.745098039215686,0.196078431372549;0.113725490196078,0.737254901960784,0.803921568627451];
cBlue = cTab10(1,:);
cGreen = cTab10(3,:);
cCyan = cTab10(10,:);
cRed = cTab10(4,:);
cGray = cTab10(8,:);
cCPL = [cGreen;cRed;cGray];

set(groot,'defaultAxesFontName','Helvetica');

FontAxesSz = 7;
FontLablSz = 9;
FontTitlSz = 10;

figSize = [2 2 15 17];
plotsize1 = [8, 4];
plotsize2 = [3.5, 4];
xpos = [1.3,11];
ypos = [1.3,6.6,11.9];

tLim = [0 3600];
htLim = [0 2500];
switch bt.Task(1)
    case "3FPs"
        rtLim = [0 1000];
        rtLim2 = [100 600];
    case {"Wait1","Wait2"}
        rtLim = [0 2000];
        rtLim2 = [100 1100];
        if bt.Task(1) == "Wait1"
            criterion = [1.5, 2]; % FP 1.5s, RW 2s
        else
            criterion = [1.5, 0.6]; % FP 1.5s, RW 2s
        end
        idxCri = abs((bt.FP-criterion(1)))<1E-4 & abs((bt.RW-criterion(2)))<1E-4;
        diffCri = diff([0;idxCri;0]); %
        prdCri = [find(diffCri==1),find(diffCri==-1)-1];
end
idxCor = bt.Outcome == "Cor";
idxPre = bt.Outcome == "Pre";
idxLate = bt.Outcome =="Late";

progFig = figure(1); clf(progFig);
set(progFig, 'unit', 'centimeters', 'position',figSize,...
    'paperpositionmode', 'auto', 'color', 'w')

dd = num2str(bt.Date(1)); ss = num2str(bt.StartTime(1));
tt = datetime([dd,'-',ss],'InputFormat','yyyyMMdd-HHmmss');
uicontrol(progFig,'Style', 'text', 'units', 'centimeters',...
    'position', [xpos(1)+plotsize1(1)/2-3,figSize(4)-0.6,6,0.5],...
    'string', append(bt.Subject(1),' / ',datestr(tt,31)), 'fontweight', 'bold',...
    'backgroundcolor', [1 1 1],'FontSize',FontTitlSz);

% HT - Time
ha1 = axes;
set(ha1, 'units', 'centimeters', 'position', [xpos(1) ypos(1), plotsize1],...
    'nextplot', 'add', 'ylim', htLim, 'xlim', tLim,'tickdir','out',...
    'TickLength', [0.0200 0.0250],'fontsize',FontAxesSz);
xlabel('Time in session (sec)','FontSize',FontLablSz)
ylabel('Hold time (ms)','FontSize',FontLablSz)

modiHT = bt.HT.*1000; modiHT(modiHT>htLim(2)) = htLim(2);
if ismember(bt.Task(1),["Wait1","Wait2"])
    for i=1:size(prdCri,1)
        fill([repelem(bt.TimeElapsed(prdCri(i,1)),2),repelem(bt.TimeElapsed(prdCri(i,2)),2)],...
            [htLim(1),htLim(2),htLim(2),htLim(1)],cCyan,'EdgeColor','none','FaceAlpha',0.1);
    end
end
line([bt.TimeElapsed,bt.TimeElapsed],[htLim(1),htLim(1)+diff(htLim)/10],...
    'color',cBlue,'linewidth',0.4);
scatter(bt.TimeElapsed(idxCor),modiHT(idxCor),30,cCPL(1,:),...
    'MarkerEdgeAlpha',0.8,'LineWidth',1.1);
scatter(bt.TimeElapsed(idxPre),modiHT(idxPre),30,cCPL(2,:),...
    'MarkerEdgeAlpha',0.8,'LineWidth',1.1);
scatter(bt.TimeElapsed(idxLate),modiHT(idxLate),30,cCPL(3,:),...
    'MarkerEdgeAlpha',0.8,'LineWidth',1.1);
if ismember(bt.Task(1),["Wait1","Wait2"])
    plot(bt.TimeElapsed,bt.FP.*1000,'--','color','k','LineWidth',1);
end

% RT - Time
ha2 = axes;
set(ha2, 'units', 'centimeters', 'position', [xpos(1) ypos(2), plotsize1],...
    'nextplot', 'add', 'ylim', rtLim, 'xlim', tLim,'tickdir','out',...
    'TickLength', [0.0200 0.0250],'fontsize',FontAxesSz);
xlabel('Time in session (sec)','FontSize',FontLablSz);
ylabel('Reaction time (ms)','FontSize',FontLablSz);

modiRT = (bt.HT - bt.FP).*1000;
modiRT(modiRT>rtLim(2)) = rtLim(2);
modiRT(modiRT<rtLim(1)) = rtLim(1);
if ismember(bt.Task(1),["Wait1","Wait2"])
    for i=1:size(prdCri,1)
        fill([repelem(bt.TimeElapsed(prdCri(i,1)),2),repelem(bt.TimeElapsed(prdCri(i,2)),2)],...
            [rtLim(1),rtLim(2),rtLim(2),rtLim(1)],cCyan,'EdgeColor','none','FaceAlpha',0.1);
    end
end
scatter(bt.TimeElapsed(idxCor),modiRT(idxCor),30,cCPL(1,:),...
    'MarkerEdgeAlpha',0.8,'LineWidth',1.1);
%     scatter(bt.TimeElapsed(idxPre),modiRT(idxPre),30,cCPL(2,:),...
%         'MarkerFaceAlpha',0.8,'LineWidth',1.1);
scatter(bt.TimeElapsed(idxLate),modiRT(idxLate),30,cCPL(3,:),...
    'MarkerEdgeAlpha',0.8,'LineWidth',1.1);
if strcmp(bt.Task(1),"Wait2")
    plot(bt.TimeElapsed,bt.RW.*1000,'--','color','k','LineWidth',1);
end

% Sliding Performance - Time
[xc,yc] = calMovAVG(bt.TimeElapsed,bt.Outcome,...
    'winRatio',8,'stepRatio',2,'tarStr','Cor');
[xp,yp] = calMovAVG(bt.TimeElapsed,bt.Outcome,...
    'winRatio',8,'stepRatio',2,'tarStr','Pre');
[xl,yl] = calMovAVG(bt.TimeElapsed,bt.Outcome,...
    'winRatio',8,'stepRatio',2,'tarStr','Late');
ha3 = axes;
set(ha3, 'units', 'centimeters', 'position', [xpos(1) ypos(3), plotsize1],...
    'nextplot', 'add', 'ylim', [0 100], 'xlim', tLim,'tickdir','out',...
    'TickLength', [0.0200 0.0250],'fontsize',FontAxesSz);
xlabel('Time in session (sec)','FontSize',FontLablSz);
ylabel('Performance (%)','FontSize',FontLablSz);

%     mc = 100.*sum(strcmp(bt.Outcome,'Cor'))./length(bt.Outcome);
%     mp = 100.*sum(strcmp(bt.Outcome,'Pre'))./length(bt.Outcome);
%     ml = 100.*sum(strcmp(bt.Outcome,'Late'))./length(bt.Outcome);
%     line(tLim,repelem(mc,2)','LineStyle','--','color',cCPL(1,:),'LineWidth',1.5);
%     line(tLim,repelem(mp,2)','LineStyle','--','color',cCPL(2,:),'LineWidth',1.5);
%     line(tLim,repelem(ml,2)','LineStyle','--','color',cCPL(3,:),'LineWidth',1.5);
plot(xc, yc, 'o', 'linestyle', '-', 'color', cCPL(1,:), ...
    'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', cCPL(1,:),...
    'markeredgecolor', 'w');
plot(xp, yp, 'o', 'linestyle', '-', 'color', cCPL(2,:), ...
    'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', cCPL(2,:),...
    'markeredgecolor', 'w');
plot(xl, yl, 'o', 'linestyle', '-', 'color', cCPL(3,:), ...
    'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', cCPL(3,:),...
    'markeredgecolor', 'w');

% Num of Outcome
ha4 = axes;
set(ha4, 'units', 'centimeters', 'position', [xpos(2) ypos(1), plotsize2],...
    'nextplot', 'add', 'tickdir','out',...
    'TickLength', [0.0200 0.0250],'fontsize',FontAxesSz);
xlabel('','FontSize',FontLablSz);
ylabel('Number','FontSize',FontLablSz);
X = categorical({'Correct','Premature','Late','Dark'});
X = reordercats(X,{'Correct','Premature','Late','Dark'});
bh = bar(X,[sum(idxCor),sum(idxPre),sum(idxLate),sum(bt.DarkTry)],...
    'FaceColor','flat','EdgeColor','none');
bh.CData(1,:) = cCPL(1,:);
bh.CData(2,:) = cCPL(2,:);
bh.CData(3,:) = cCPL(3,:);
bh.CData(4,:) = [0 0 0];
xtps = bh.XEndPoints;
ytps = bh.YEndPoints;
Labl = string(bh.YData);
text(xtps,ytps,Labl,'HorizontalAlignment','center',...
    'VerticalAlignment','bottom','fontsize',FontAxesSz);

switch bt.Task(1)
    case "3FPs"
        fplist = unique(round(bt.FP,1))'; % [0.5 1.0 1.5]
        switch length(fplist)
            case 3
                idxS = abs((bt.FP-fplist(1)))<1E-4;
                idxM = abs((bt.FP-fplist(2)))<1E-4;
                idxL = abs((bt.FP-fplist(3)))<1E-4;
            case 2
                idxS = abs((bt.FP-fplist(1)))<1E-4;
                idxM = abs((bt.FP-fplist(2)))<1E-4;
                idxL = false(size(bt.FP));
                fplist = [fplist NaN];
            case 1
                idxS = abs((bt.FP-fplist(1)))<1E-4;
                idxM = false(size(bt.FP));
                idxL = false(size(bt.FP));
                fplist = [fplist NaN NaN];
            case 0
                idxS = false(size(bt.FP));
                idxM = false(size(bt.FP));
                idxL = false(size(bt.FP));
                fplist = nan(1,3);
        end
        
        % Reaction time - 3FPs
        ha5 = axes;
        set(ha5, 'units', 'centimeters', 'position', [xpos(2) ypos(2), plotsize2],...
            'nextplot', 'add', 'tickdir','out',...
            'xlim',[min(fplist).*1000-100,max(fplist).*1000+100],...
            'ylim',rtLim2,...
            'TickLength', [0.0200 0.0250],'fontsize',FontAxesSz);
        xlabel('Foreperiod (ms)','FontSize',FontLablSz);
        ylabel('Reaction time (ms)','FontSize',FontLablSz);
        
        rtS = calRT(bt.HT(idxCor&idxS).*1000,bt.FP(idxCor&idxS).*1000,...
            'Remove100ms',true,'RemoveOutliers',true,'ToPlot',false,'Calse',false);
        rtM = calRT(bt.HT(idxCor&idxM).*1000,bt.FP(idxCor&idxM).*1000,...
            'Remove100ms',true,'RemoveOutliers',true,'ToPlot',false,'Calse',false);
        rtL = calRT(bt.HT(idxCor&idxL).*1000,bt.FP(idxCor&idxL).*1000,...
            'Remove100ms',true,'RemoveOutliers',true,'ToPlot',false,'Calse',false);
        rtS_L = calRT(bt.HT((idxLate|idxCor)&idxS).*1000,bt.FP((idxLate|idxCor)&idxS).*1000,...
            'Remove100ms',true,'RemoveOutliers',true,'ToPlot',false,'Calse',false);
        rtM_L = calRT(bt.HT((idxLate|idxCor)&idxM).*1000,bt.FP((idxLate|idxCor)&idxM).*1000,...
            'Remove100ms',true,'RemoveOutliers',true,'ToPlot',false,'Calse',false);
        rtL_L = calRT(bt.HT((idxLate|idxCor)&idxL).*1000,bt.FP((idxLate|idxCor)&idxL).*1000,...
            'Remove100ms',true,'RemoveOutliers',true,'ToPlot',false,'Calse',false);
        plot(fplist.*1000,[rtS.median,rtM.median,rtL.median],'o-','color',cGreen,...
            'markersize', 7, 'linewidth', 1.5, 'markerfacecolor', cGreen,...
            'MarkerEdgeColor', 'w');
        plot(fplist.*1000,[rtS_L.median,rtM_L.median,rtL_L.median],'^-','color',cGray,...
            'markersize', 7, 'linewidth', 1.5, 'markerfacecolor', cGray,...
            'MarkerEdgeColor', 'w');
        legend({'Cor','Cor+Late'},'fontsize',FontAxesSz,'Location','southeast');
        legend('boxoff');
        
        % Performance - 3FPs
        ha6 = axes;
        set(ha6, 'units', 'centimeters', 'position', [xpos(2) ypos(3), plotsize2],...
            'nextplot', 'add', 'tickdir','out','ylim',[0 100],...
            'TickLength', [0.0200 0.0250],'fontsize',FontAxesSz);
        xlabel('Foreperiod (ms)','FontSize',FontLablSz);
        ylabel('Performance (%)','FontSize',FontLablSz);
        
        OutS = bt.Outcome(idxS);
        OutM = bt.Outcome(idxM);
        OutL = bt.Outcome(idxL);

        bh2 = bar(fplist.*1000,...
            [sum(OutS=="Cor")/length(OutS),sum(OutS=="Pre")/length(OutS),sum(OutS=="Late")/length(OutS);...
             sum(OutM=="Cor")/length(OutM),sum(OutM=="Pre")/length(OutM),sum(OutM=="Late")/length(OutM);...
             sum(OutL=="Cor")/length(OutL),sum(OutL=="Pre")/length(OutL),sum(OutL=="Late")/length(OutL);].*100,...
            'FaceColor','flat','EdgeColor','none');
        bh2(1).FaceColor = cCPL(1,:);
        bh2(2).FaceColor = cCPL(2,:);
        bh2(3).FaceColor = cCPL(3,:);
        xtps1 = bh2(1).XEndPoints; xtps2 = bh2(2).XEndPoints; xtps3 = bh2(3).XEndPoints;
        ytps1 = bh2(1).YEndPoints; ytps2 = bh2(2).YEndPoints; ytps3 = bh2(3).YEndPoints;
        Labl1 = string(round(bh2(1).YData)); Labl2 = string(round(bh2(2).YData)); Labl3 = string(round(bh2(3).YData));
        text(xtps1,ytps1,Labl1,'HorizontalAlignment','center',...
            'VerticalAlignment','bottom','fontsize',FontAxesSz);
        text(xtps2,ytps2,Labl2,'HorizontalAlignment','center',...
            'VerticalAlignment','bottom','fontsize',FontAxesSz);
        text(xtps3,ytps3,Labl3,'HorizontalAlignment','center',...
            'VerticalAlignment','bottom','fontsize',FontAxesSz);
    case {"Wait1","Wait2"}
        % Reaction time - progress/criterion
        ha5 = axes;
        set(ha5, 'units', 'centimeters', 'position', [xpos(2) ypos(2), plotsize2],...
            'nextplot', 'add', 'tickdir','out','ylim',rtLim2,...
            'TickLength', [0.0200 0.0250],'fontsize',FontAxesSz);
        xlabel('','FontSize',FontLablSz);
        ylabel('Reaction time (ms)','FontSize',FontLablSz);

        xtik = categorical({'InProgress','InCriterion'});
        xtik = reordercats(xtik,{'InProgress','InCriterion'});
        rtPro = calRT(bt.HT(idxCor & ~idxCri).*1000,bt.FP(idxCor & ~idxCri).*1000,...
            'Remove100ms',true,'RemoveOutliers',true,'ToPlot',false,'Calse',false);
        rtCri = calRT(bt.HT(idxCor & idxCri).*1000,bt.FP(idxCor & idxCri).*1000,...
            'Remove100ms',true,'RemoveOutliers',true,'ToPlot',false,'Calse',false);
        rtPro_L = calRT(bt.HT((idxLate|idxCor) & ~idxCri).*1000,bt.FP((idxLate|idxCor) & ~idxCri).*1000,...
            'Remove100ms',true,'RemoveOutliers',true,'ToPlot',false,'Calse',false);
        rtCri_L = calRT(bt.HT((idxLate|idxCor) & idxCri).*1000,bt.FP((idxLate|idxCor) & idxCri).*1000,...
            'Remove100ms',true,'RemoveOutliers',true,'ToPlot',false,'Calse',false);
        bh2 = bar(xtik,...
            [rtPro.median(1),rtPro_L.median(1);rtCri.median(1),rtCri_L.median(1)],...
            'FaceColor','flat','EdgeColor','none');
%             xtps1 = bh2(1).XEndPoints; xtps2 = bh2(2).XEndPoints;
%             ytps1 = bh2(1).YEndPoints; ytps2 = bh2(2).YEndPoints;
%             errorbar([xtps1,xtps2],[ytps1,ytps2],...
%                 [rtPro.median(2),rtCri.median(2),rtPro_L.median(2),rtCri_L.median(2)],...
%                 '.k');
        bh2(1).FaceColor = cCPL(1,:);
        bh2(2).FaceColor = cCPL(3,:);
        xtps1 = bh2(1).XEndPoints; xtps2 = bh2(2).XEndPoints;
        ytps1 = bh2(1).YEndPoints; ytps2 = bh2(2).YEndPoints;
        Labl1 = string(round(bh2(1).YData)); Labl2 = string(round(bh2(2).YData));
        text(xtps1,ytps1,Labl1,'HorizontalAlignment','center',...
            'VerticalAlignment','bottom','fontsize',FontAxesSz);
        text(xtps2,ytps2,Labl2,'HorizontalAlignment','center',...
            'VerticalAlignment','bottom','fontsize',FontAxesSz);
        le = legend({'Cor','Cor+Late'},'Location','northwest');
        legend('boxoff');
        le.ItemTokenSize(1) = 10;

        % Performance - progress/criterion
        ha6 = axes;
        set(ha6, 'units', 'centimeters', 'position', [xpos(2) ypos(3), plotsize2],...
            'nextplot', 'add', 'tickdir','out','ylim',[0 100],...
            'TickLength', [0.0200 0.0250],'fontsize',FontAxesSz);
        xlabel('','FontSize',FontLablSz);
        ylabel('Performance (%)','FontSize',FontLablSz);
        
        outPro = bt.Outcome(~idxCri);
        outCri = bt.Outcome(idxCri);
        bh3 = bar(xtik,...
            [sum(outPro=="Cor")/length(outPro),sum(outPro=="Pre")/length(outPro),sum(outPro=="Late")/length(outPro);...
             sum(outCri=="Cor")/length(outCri),sum(outCri=="Pre")/length(outCri),sum(outCri=="Late")/length(outCri)].*100,...
            'FaceColor','flat','EdgeColor','none');
        bh3(1).FaceColor = cCPL(1,:);
        bh3(2).FaceColor = cCPL(2,:);
        bh3(3).FaceColor = cCPL(3,:);
        xtps1 = bh3(1).XEndPoints; xtps2 = bh3(2).XEndPoints; xtps3 = bh3(3).XEndPoints;
        ytps1 = bh3(1).YEndPoints; ytps2 = bh3(2).YEndPoints; ytps3 = bh3(3).YEndPoints;
        Labl1 = string(round(bh3(1).YData)); Labl2 = string(round(bh3(2).YData)); Labl3 = string(round(bh3(3).YData));
        text(xtps1,ytps1,Labl1,'HorizontalAlignment','center',...
            'VerticalAlignment','bottom','fontsize',FontAxesSz);
        text(xtps2,ytps2,Labl2,'HorizontalAlignment','center',...
            'VerticalAlignment','bottom','fontsize',FontAxesSz);
        text(xtps3,ytps3,Labl3,'HorizontalAlignment','center',...
            'VerticalAlignment','bottom','fontsize',FontAxesSz);
end
%%
figPath = fullfile(path_arc,'ProgFig',bt.Subject(1));
[~,~] = mkdir(figPath);
figFile = fullfile(figPath,savename);
print(progFig, figFile, '-dpng');
saveas(progFig, figFile, 'fig');
end
