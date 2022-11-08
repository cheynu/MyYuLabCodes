function h = BPOD_AutoshapingPlot_Individual(btAll,varargin)
%%
p = inputParser;
addRequired(p,'btAll');
addParameter(p,'expVar',{});
addParameter(p,'tLim',[0,4200]); % Time points of session lim
addParameter(p,'mLim',[0.1,60]); % Movement time lim
addParameter(p,'qLim',[0.12,6]); % qualified MT lim
parse(p,btAll,varargin{:});

expVar = p.Results.expVar;
tLim = p.Results.tLim;
mLim = p.Results.mLim;
qLim = p.Results.qLim;
%%
TBT = table;
SBS = table;
btAll_new = {};
nDate = length(btAll);
for i=1:nDate
    bt = btAll{i};
    if ~isempty(expVar)
        bt = addvars(bt,repelem(string(expVar{i}),size(bt,1))',...
            'NewVariableNames','Experiment','After','Date');
    end
    bt = addvars(bt,repelem(true,size(bt,1))',...
        'NewVariableNames','Qualified');
    bt.Qualified(isnan(bt.MT) | bt.MT<qLim(1) | bt.MT>qLim(2)) = false;
    btAll_new{i} = bt;
    TBT = [TBT;bt];
end


%% Plot
Font = 'Arial';
cTab10 = [0.0901960784313726,0.466666666666667,0.701960784313725;0.960784313725490,0.498039215686275,0.137254901960784;0.152941176470588,0.631372549019608,0.278431372549020;0.843137254901961,0.149019607843137,0.172549019607843;0.564705882352941,0.403921568627451,0.674509803921569;0.549019607843137,0.337254901960784,0.290196078431373;0.847058823529412,0.474509803921569,0.698039215686275;0.501960784313726,0.501960784313726,0.501960784313726;0.737254901960784,0.745098039215686,0.196078431372549;0.113725490196078,0.737254901960784,0.803921568627451];
cBlue = cTab10(10,:);
cGreen = cTab10(3,:);
cGray = cTab10(8,:).*0.7;
cOrange = cTab10(2,:);
cDark = [0 0 0];
cQual = cGreen; cVali = cBlue;

xstart = 1.2; ystart = 1;
xstep = 0.3; ystep = 1;
size_axes = [4 3];
xs = xstart:(size_axes(1)+xstep):(xstart+nDate*(size_axes(1)+xstep));
ys = ystart:(size_axes(2)+ystep):(ystart+2*(size_axes(2)+ystep));

h = figure(20); clf(20)
set(h, 'unit', 'centimeters', 'position',[2 2 xs(end) ys(end)],...
    'paperpositionmode', 'auto', 'color', 'w')
uicontrol(h,'Style', 'text', 'parent', 20, 'units', 'normalized',...
        'position', [0.17 0.94 0.7 0.05],...
        'string', append(bt.Subject(1),' / ', bt.Task(1)), 'fontweight', 'bold',...
        'backgroundcolor', [1 1 1]);

% MT - Time, scatter
thisRow = 1;
for i=1:nDate
    bt = btAll_new{i};

    ha = axes(h);
    set(ha,'units', 'centimeters', 'position', [xs(i) ys(thisRow) size_axes],...
        'nextplot', 'add','tickDir', 'out','fontsize',7,'fontname',Font,...
        'ylim',mLim,'ticklength', [0.02 0.025],'yscale','log');
    xlabel('Time in session (s)','Fontsize',8,'FontName',Font)
    ylabel('Movement time (s)','Fontsize',8,'FontName',Font)
    if i~=1
        ha.YAxis.Visible = 'off';
    end
    
    fill([tLim,fliplr(tLim)],[qLim(1),qLim(1),qLim(2),qLim(2)],...
        cGreen,'EdgeColor','none','FaceAlpha',0.15);
    ltick = logspace(log10(mLim(1)),log10(mLim(1)+0.1),3);
    line([bt.TimeElapsed(~bt.Qualified),bt.TimeElapsed(~bt.Qualified)],...
        [ltick(1),ltick(2)], 'color',cDark, 'linewidth', 0.3); % invalid trial
    line([bt.TimeElapsed(bt.Qualified),bt.TimeElapsed(bt.Qualified)],...
        [ltick(2),ltick(3)], 'color',cBlue, 'linewidth', 0.3); % valid trial
    line(tLim,repelem(median(bt.MT(~isnan(bt.MT))),2),...
        'linestyle','--','color',cDark,'linewidth',1.5);
    mt_plot = bt.MT;
    mt_plot(bt.MT>mLim(2)) = mLim(2);
    mt_plot(bt.MT<mLim(1)) = mLim(1);
    scatter(bt.TimeElapsed(~isnan(bt.MT)),mt_plot(~isnan(bt.MT)),...
        10, cGray,'o','Markeredgealpha', 0.8, 'linewidth', 1.1);
    text(tLim(2)-diff(tLim)/8,mLim(2)-10,...
        sprintf('%.1fs',median(bt.MT(~isnan(bt.MT)))),'FontSize',8);
end

% Performance - Time
thisRow = 2;
for i=1:nDate
    bt = btAll_new{i};
    [x_v,y_v] = computeSlidingCor(bt.TimeElapsed,bt.Outcome,...
        'winSize',40,'stepSize',20);
    [x_q,y_q] = computeSlidingCor(bt.TimeElapsed,bt.Qualified,...
        'winSize',40,'stepSize',20);

    ha = axes(h);
    set(ha,'units', 'centimeters', 'position', [xs(i) ys(thisRow) size_axes],...
        'nextplot', 'add','tickDir', 'out','fontsize',7,'fontname',Font,...
        'ylim',[0 100],'ticklength', [0.02 0.025]);
    xlabel('Time in session (s)','Fontsize',8,'FontName',Font)
    ylabel('Performance (%)','Fontsize',8,'FontName',Font)
    if i~=1
        ha.YAxis.Visible = 'off';
    end
    mperfv = 100.*sum(strcmp(bt.Outcome,'Valid'))./length(bt.Outcome);
    line(tLim,repelem(mperfv,2),...
        'linestyle','--','color',cVali,'linewidth',1.5);
    plot(x_v, y_v, 'o', 'linestyle', '-', 'color', cVali, ...
        'markersize', 5, 'linewidth', 1, 'markerfacecolor', cVali,...
        'markeredgecolor', 'w');
    text(tLim(2)-diff(tLim)/8,97,sprintf('%.0f%%',mperfv),...
        'FontSize',8,'color',cVali.*0.8);

    mperfq = 100.*sum(bt.Qualified)./length(bt.Outcome);
    line(tLim,repelem(mperfq,2),...
        'linestyle','--','color',cQual,'linewidth',1.5);
    plot(x_q, y_q, 'o', 'linestyle', '-', 'color', cQual, ...
        'markersize', 5, 'linewidth', 1, 'markerfacecolor', cQual,...
        'markeredgecolor', 'w');
    text(tLim(2)-diff(tLim)/8,6,sprintf('%.0f%%',mperfq),...
        'FontSize',8,'color',cQual.*0.8);
    
    if isempty(expVar)
        title(num2str(bt.Date(1)),'Fontsize',9,'FontName',Font);
    else
        title([num2str(bt.Date(1)),'-',expVar{i}],'Fontsize',9,'FontName',Font);
    end
    
end
%% Save
figName = 'Autoshaping_'+bt.Subject(1);
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
function [xo,yo] = computeSlidingCor(time,outcome,varargin)
pp = inputParser;
addRequired(pp,'time');
addRequired(pp,'outcome');
addParameter(pp,'winRatio',6);
addParameter(pp,'stepRatio',3);
addParameter(pp,'winSize',[]);
addParameter(pp,'stepSize',[]);
addParameter(pp,'corStr','Valid');
parse(pp,time,outcome,varargin{:});

winRatio = pp.Results.winRatio;
stepRatio = pp.Results.stepRatio;
winSize = pp.Results.winSize;
stepSize = pp.Results.stepSize;
corStr = pp.Results.corStr;

if ~isempty(winSize)
    win = winSize;
else
    win = floor(length(time)/winRatio);
end
if ~isempty(stepSize)
    step = stepSize;
else
    step = max(1,floor(win/stepRatio));
end

countStart = 1;
xo = [];
yo = [];
while countStart+win-1 <= length(time)
    thisWin = [countStart:countStart+win-1]';
    thisOutcome = outcome(thisWin);
    switch class(thisOutcome)
        case 'logical'
            yo = [yo; 100.*sum(thisOutcome)./length(thisOutcome)]; % 'Valid'
        case 'string'
            yo = [yo; 100.*sum(strcmp(thisOutcome,corStr))./length(thisOutcome)]; % 'Valid'
    end
    xo = [xo; time(round(median(thisWin)))];
    countStart = countStart + step;
end

end