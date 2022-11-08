function h = BPOD_TrialProgress_Individual(btAll,varargin)
p = inputParser;
addRequired(p,'btAll');
addOptional(p,'plotRange',[]);
parse(p,btAll,varargin{:});

plotRange = p.Results.plotRange;
if ~isempty(plotRange)
    btAll = btAll(:,plotRange);
end

sepSess = 300; % fixed time separation between sessions
%% Preprocess
nSess = length(btAll);
sbjName = btAll{1}.Subject(1);
dateRange = num2str([btAll{1}.Date(1);btAll{end}.Date(1)]);
% dateRange = string(dateRange(:,end-3:end));
dateRange = string(dateRange);

[~,TBT] = packData(btAll,sepSess);

TBT.TimeElapsedMerge = TBT.TimeElapsedMerge./60;
[~,ia] = unique(TBT.Session,'last');
timeSep = TBT.TimeElapsedMerge(ia)+sepSess/120;

sessName = unique(TBT.Session);
idxCor = TBT.Outcome == "Cor";
idxPre = TBT.Outcome == "Pre";
idxLate = TBT.Outcome =="Late";
idxW1 = TBT.Task=="Wait1";
idxW2 = TBT.Task=="Wait2";
%% Plot parameters
cTab10 = [0.0901960784313726,0.466666666666667,0.701960784313725;0.960784313725490,0.498039215686275,0.137254901960784;0.152941176470588,0.631372549019608,0.278431372549020;0.843137254901961,0.149019607843137,0.172549019607843;0.564705882352941,0.403921568627451,0.674509803921569;0.549019607843137,0.337254901960784,0.290196078431373;0.847058823529412,0.474509803921569,0.698039215686275;0.501960784313726,0.501960784313726,0.501960784313726;0.737254901960784,0.745098039215686,0.196078431372549;0.113725490196078,0.737254901960784,0.803921568627451];
cBlue = cTab10(1,:);
cGreen = cTab10(3,:);
cRed = cTab10(4,:);
cGray = cTab10(8,:);
cBrown = cTab10(6,:);
cCyan = cTab10(10,:);
cCPL = [cGreen;cRed;cGray];

set(groot,'defaultAxesFontName','Helvetica');

fontAxesSz = 7;
fontLablSz = 9;
fontTitlSz = 10;

xstart = 1.5; ystart = 1.3;
xsep = 0.5; ysep = 1.2;
singleSz = [3, 3];
axesSz = [(singleSz(1)+xsep).*nSess-xsep singleSz(2)];
figPos = [2 2 ...
    xstart+axesSz(1)+xsep...
    ystart+(axesSz(2)+ysep).*3];
tickLen = [0.15 0.25]; % cm

tLim = [0 max(TBT.TimeElapsedMerge)+sepSess/60];
htLim = [0 2500];
rtLim = [0 1000];
winSz = 30;
stepSz = 15;
%% Plot
h = figure(20); clf(20)
set(h, 'unit', 'centimeters', 'position',figPos,...
    'paperpositionmode', 'auto', 'color', 'w')
uicontrol(h,'Style', 'text', 'units', 'centimeters',...
        'position', [figPos(3)/2-4,figPos(4)-ysep*0.66,8,0.5],...
        'string', append(sbjName,' / ', dateRange(1),'-',dateRange(2)),...
        'fontsize', fontTitlSz, 'fontweight', 'bold','backgroundcolor', [1 1 1]);
% Hold time - Time
ha1 = axes;
set(ha1, 'units', 'centimeters', 'position', [xstart,ystart,axesSz],...
    'nextplot', 'add', 'ylim', htLim, 'xlim', tLim, 'tickdir','out',...
    'TickLength', [tickLen(1)/max(axesSz),tickLen(2)/max(axesSz)], 'fontsize',fontAxesSz); % 
xlabel('Time (min)','FontSize',fontLablSz)
ylabel('Hold time (ms)','FontSize',fontLablSz)

if ~isempty(idxW1)
    fillCriterion(TBT(idxW1,:),[1.5,2],htLim,cCyan)
end
if ~isempty(idxW2)
    fillCriterion(TBT(idxW2,:),[1.5,0.6],htLim,cCyan)
end
line([timeSep timeSep],htLim,'color','k','linewidth',1,'linestyle','--');
modiHT = TBT.HT.*1000; modiHT(modiHT>htLim(2)) = htLim(2);
line([TBT.TimeElapsedMerge,TBT.TimeElapsedMerge],[htLim(1),htLim(1)+diff(htLim)/10],...
    'color',cBlue,'linewidth',0.4);
scatter(TBT.TimeElapsedMerge(idxCor),modiHT(idxCor),15,cCPL(1,:),...
    'MarkerEdgeAlpha',0.7,'LineWidth',1);
scatter(TBT.TimeElapsedMerge(idxPre),modiHT(idxPre),15,cCPL(2,:),...
    'MarkerEdgeAlpha',0.7,'LineWidth',1);
scatter(TBT.TimeElapsedMerge(idxLate),modiHT(idxLate),15,cCPL(3,:),...
    'MarkerEdgeAlpha',0.7,'LineWidth',1);

% Sliding RT - Time
ha2 = axes;
set(ha2, 'units', 'centimeters', 'position', [xstart,ystart+(axesSz(2)+ysep),axesSz],...
    'nextplot', 'add', 'ylim', rtLim, 'xlim', tLim,'tickdir','out',...
    'TickLength', [tickLen(1)/max(axesSz),tickLen(2)/max(axesSz)],'fontsize',fontAxesSz);
xlabel('Time (min)','FontSize',fontLablSz);
ylabel('Reaction time (ms)','FontSize',fontLablSz);

if ~isempty(idxW1)
    fillCriterion(TBT(idxW1,:),[1.5,2],htLim,cCyan)
end
if ~isempty(idxW2)
    fillCriterion(TBT(idxW2,:),[1.5,0.6],htLim,cCyan)
end
modiRT = (TBT.HT - TBT.FP).*1000;
modiRT(modiRT>rtLim(2)) = rtLim(2);
modiRT(modiRT<rtLim(1)) = rtLim(1);
scatter(TBT.TimeElapsedMerge(idxCor),modiRT(idxCor),15,cCPL(1,:),...
    'MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.5,'LineWidth',0.5);
scatter(TBT.TimeElapsedMerge(idxLate),modiRT(idxLate),15,cCPL(3,:),...
    'MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.5,'LineWidth',0.5);
line([timeSep timeSep],rtLim,'color','k','linewidth',1,'linestyle','--');
for i=1:length(sessName)
    idxSess = TBT.Session==sessName(i);
    T = TBT(idxSess,:);

%     isWait = find(ismember(["Wait1","Wait2"],T.Task(1)));
%     if ~isempty(isWait)
%         plot(ha1,T.TimeElapsedMerge,T.FP.*1000,'--','color','k','LineWidth',1);
%         if isWait==2
%             plot(ha2,T.TimeElapsedMerge,T.RW.*1000,'--','color','k','LineWidth',1);
%         end
%     end

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
    fillCriterion(TBT(idxW1,:),[1.5,2],htLim,cCyan)
end
if ~isempty(idxW2)
    fillCriterion(TBT(idxW2,:),[1.5,0.6],htLim,cCyan)
end
line([timeSep timeSep],[0 100],'color','k','linewidth',1,'linestyle','--');
for i=1:length(sessName)
    idxSess = TBT.Session==sessName(i);
    [xc,yc] = calMovAVG(TBT.TimeElapsedMerge(idxSess),TBT.Outcome(idxSess),...
        'winSize',winSz,'stepSize',stepSz,'tarStr','Cor');
    [xp,yp] = calMovAVG(TBT.TimeElapsedMerge(idxSess),TBT.Outcome(idxSess),...
        'winSize',winSz,'stepSize',stepSz,'tarStr','Pre');
    [xl,yl] = calMovAVG(TBT.TimeElapsedMerge(idxSess),TBT.Outcome(idxSess),...
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
%% Save
figName = append("TrialProgress_",TBT.Subject(1),'_',dateRange(1),'-',dateRange(2));
figPath = fullfile(pwd,'IndivFig');
if ~exist(figPath,'dir')
    mkdir(figPath);
end
figFile = fullfile(figPath,figName);
saveas(h, figFile, 'fig');
print(h,'-dpng',figFile);
% print(h,'-depsc2',figFile);
end

%% Functions
function [SBS,TBT] = packData(btAll,sepSess)
SBS = table;
TBT = table;
curTime = 0;
for i=1:length(btAll)
    T = btAll{i};
%     SBS = [SBS;estSBS(T,i,cenMethod)];
    te = T.TimeElapsed;
    te = T.TimeElapsed+curTime;
    nrow = size(T,1);
    tempT = addvars(T,repelem(i,nrow)','After','Date','NewVariableNames','Session');
    tempT = addvars(tempT,te,'After','TimeElapsed','NewVariableNames','TimeElapsedMerge');
    TBT = [TBT;tempT];
    curTime = curTime + T.TimeElapsed(end) + sepSess;
end
end

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