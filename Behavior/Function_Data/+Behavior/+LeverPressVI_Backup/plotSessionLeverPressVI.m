function plotSessionLeverPressVI(vb,opts)

arguments
    vb
    opts.SavePath = ''
end

if isempty(opts.SavePath)
    pathFigSave = pwd;
else
    pathFigSave = opts.SavePath;
end

% %params
nBoot = 500;

% size & space
figSize = [18 16];

x_start = 1.5;
y_start = 1;
x_space_right = 1.5;
x_space = 0.6;
x_space_small = 0.3;
x_space_label = 1;
y_space_small = 0.3;
y_space_big = 1;

fontsize_label = 8;

% color
cBlack = [0 0 0];
cWhite = [1 1 1];
cTab10 = [  0.090196078431373	0.466666666666667	0.701960784313725
            0.960784313725490	0.498039215686275	0.137254901960784
            0.152941176470588	0.631372549019608	0.278431372549020
            0.843137254901961	0.149019607843137	0.172549019607843
            0.564705882352941	0.403921568627451	0.674509803921569
            0.549019607843137	0.337254901960784	0.290196078431373
            0.847058823529412	0.474509803921569	0.698039215686275
            0.501960784313726	0.501960784313726	0.501960784313726
            0.737254901960784	0.745098039215686	0.196078431372549
            0.113725490196078	0.737254901960784	0.803921568627451];
cBlue = 'b'; %cTab10(1,:);
cOrange = cTab10(2,:);
cGreen = 'g'; %cTab10(3,:);
cRed = cTab10(4,:);
cPurple = cTab10(5,:);
cBrown = cTab10(6,:);
cPink = cTab10(7,:);
cGray = cTab10(8,:);
cYellow = cTab10(9,:);
cCyan = cTab10(10,:);

% limit & edges
tLim = [0 max(2500, vb.SessionDuration+60)]; tTicks = tLim(1):300:tLim(2);
trialLim = [0 max(50, vb.nTrial)];
viLim = [-100, 60];  viTicks = viLim(1):20:viLim(2);
rateLim = [-10 20];  rateTicks = 0:5:rateLim(2);
pressLineBottom = -10; pressLineLen = 2;
pokeLineBottom = -6; pokeLineLen = 2;
rateEpochLim = [0 14]; rateEpochTicks = rateEpochLim(1):2:rateEpochLim(2);
viAllLim = [0 max(ceil(max(vb.VI)),100)];
mtLim = [0 10];
iriLim = [0 200]; % inter-response interval limit
iriEdges = iriLim(1):0.25:iriLim(2);
iriLogLim = [1 200]; iriLogTicks = [1 2 3 5 10 20 30 50 100 200];
ipiLim = [0 60];
mtLim = [0 15]; mtTicks = mtLim(1):5:mtLim(2);
mtEdges = mtLim(1):1/3:mtLim(2);
latencyLim = [0 45];
latencyEdges = latencyLim(1):1:latencyLim(2); latencyTicks = latencyLim(1):15:latencyLim(2);
countLim = [0 30];
pdfLim = [0 0.61];
cdfLim = [0 1.01];
probLim = [-abs(rateLim(1))/(rateLim(2)) 1]; probTicks = 0:0.2:1;
boutRateLim = [0 40]; boutRateTicks = boutRateLim(1):10:boutRateLim(2);

% process data
% some variables
resptypes = unique(vb.Responses.Type);
t_GoodPress = vb.Responses.Time(vb.Responses.Type=="GoodPress");
t_BadPress = vb.Responses.Time(vb.Responses.Type=="BadPress");
t_GoodPokeFirst = vb.Responses.Time(vb.Responses.Type=="GoodPokeFirst");
t_BadPokeFirst = vb.Responses.Time(vb.Responses.Type=="BadPokeFirst");
restartLatency_bad = vb.PokeType.Bad.RestartLatency;
restartLatency_good = vb.PokeType.Good.RestartLatency;
restartLatencySort = sort([restartLatency_bad;restartLatency_good]);
mt_bad = vb.PokeType.Bad.MovementTime;
mt_good = vb.PokeType.Good.MovementTime;
mtSort = sort([mt_bad;mt_good]);

% Session progress
% press rate
step = 60;
edgesT = 0:step:3600;
edgesT = edgesT(edgesT<vb.SessionDuration+step);
N_rate = histcounts(vb.tPress, edgesT, 'Normalization', 'count');
t_rate = edgesT(1:end-1)+diff(edgesT)./2;
N_rate_smooth = movmean(N_rate,3); % 5 min smooth

% P(Press/Press) Press Stay Probability
t_PressNextPress = t_rate;

R_select = vb.Responses(contains(vb.Responses.Type,{'Press','PokeFirst'}),:);

idxPress = find(contains(R_select.Type,'Press'));
idxPress = idxPress(idxPress+1<size(R_select,1));

tPress = R_select.Time(idxPress);
N_Press = histcounts(tPress, edgesT, 'Normalization', 'count');
N_Press_smo = movmean(N_Press,3,'omitnan');

tPressNextPress = R_select.Time(idxPress(contains(R_select.Type(idxPress+1),'Press')));
N_PressNextPress = histcounts(tPressNextPress, edgesT, 'Normalization', 'count');
N_PressNextPress_smo = movmean(N_PressNextPress,3,'omitnan');

N_Press(N_Press==0) = NaN;
P_PressNextPress = N_PressNextPress./N_Press;

N_Press_smo(N_Press_smo==0) = NaN;
P_PressNextPress_smo = N_PressNextPress_smo./N_Press_smo;

% ha4
ipi = vb.IRI; % inter-press interval
iwi = diff(t_GoodPokeFirst); % inter-water (reinforcer) interval
ibpi = diff(t_BadPokeFirst);
cdf_ipi = [iriEdges(1) histcounts(ipi,iriEdges,'Normalization','cdf')];
cdf_iwi = [iriEdges(1) histcounts(iwi,iriEdges,'Normalization','cdf')];
cdf_retrieval = [iriEdges(1) histcounts(vb.RetrievalLatency,iriEdges,'Normalization','cdf')];
cdf_vi = [iriEdges(1) histcounts(vb.VI,iriEdges,'Normalization','cdf')];
cdf_ibpi = [iriEdges(1) histcounts(ibpi, iriEdges,'Normalization','cdf')];
cdf_restart = [iriEdges(1) histcounts(restartLatencySort,iriEdges,'Normalization','cdf')];
cdf_mt = [iriEdges(1) histcounts(mtSort,iriEdges,'Normalization','cdf')];

iriBins = iriEdges(2:end);

% ha lag-IPI
ipi_this = ipi(2:end);
ipi_last = ipi(1:end-1);
ipi_last2 = movmean(ipi,[1 0],'Endpoints','shrink');
ipi_last2 = ipi_last2(1:end-1);

% ha post-poke re-press interval

pdf_rL_bad = movmean([latencyEdges(1) histcounts(restartLatency_bad, latencyEdges,'Normalization','pdf')],3);
pdf_rL_good = movmean([latencyEdges(1) histcounts(restartLatency_good, latencyEdges,'Normalization','pdf')],3);
% cdf_rL_bad = [latencyEdges(1) histcounts(restartLatency_bad, latencyEdges,'Normalization','cdf')];
% cdf_rL_good = [latencyEdges(1) histcounts(restartLatency_good, latencyEdges,'Normalization','cdf')];

pdf_mt_bad = movmean([mtEdges(1) histcounts(mt_bad, mtEdges,'Normalization','pdf')],3);
pdf_mt_good = movmean([mtEdges(1) histcounts(mt_good, mtEdges,'Normalization','pdf')],3);

% Press/BadPoke rate - Session Time (5 min bin)
% press rate
min2bin = 5; % 5 minites
stepEpoch = 60*min2bin;
edgesEpoch = 0:stepEpoch:1800;
ticksEpoch = 1:length(edgesEpoch)-1;
N_press_Epoch = histcounts(vb.tPress, edgesEpoch, 'Normalization', 'count')./min2bin;
N_badpoke_Epoch = histcounts(t_BadPokeFirst, edgesEpoch, 'Normalization', 'count')./min2bin;
N_goodpoke_Epoch = histcounts(t_GoodPokeFirst, edgesEpoch, 'Normalization', 'count')./min2bin;

% N-back press rate (Press rate - xth Press [after poke]/[in a press bout]
boutTicks = 1:8;
Bout.Ticks = boutTicks;
Bout.AllPress.PressRate = cell(size(boutTicks));
Bout.AllPress.isAfterGood = cell(size(boutTicks));
Bout.AllPress.isStay = cell(size(boutTicks));
Bout.N.All = [];
Bout.N.Good = [];
Bout.N.Bad = [];
Bout.PressRate.All = [];
Bout.PressRate.Good = [];
Bout.PressRate.Bad = [];
Bout.CI.All = [];
Bout.CI.Good = [];
Bout.CI.Bad = [];
Bout.Stay.All = [];
Bout.Stay.Good = [];
Bout.Stay.Bad = [];
for i=1:length(boutTicks)
    thisN = boutTicks(i);
    idxTarPress = find(vb.nPressAfterPoke==thisN);
    thisIRI = vb.IRI_Adjusted(idxTarPress);
    thisType = vb.isPressAfterGood(idxTarPress);
    thisStay = vb.isPressStay(idxTarPress);
    
    Bout.AllPress.PressRate{i} = 60./thisIRI; % press rate (/min)
    Bout.AllPress.isAfterGood{i} = thisType;
    Bout.AllPress.isStay{i} = thisStay;
    % all
    idxFilter = true(size(Bout.AllPress.isAfterGood{i}));
    thisdata = Bout.AllPress.PressRate{i}(idxFilter);
    mean_rate = mean(thisdata,'omitnan');
    if length(thisdata)>1
        ci_rate = bootci(nBoot, @mean, thisdata);
    else
        ci_rate = [NaN;NaN];
    end
    pStay = sum(Bout.AllPress.isStay{i}(idxFilter))./length(Bout.AllPress.isStay{i}(idxFilter));
    Bout.PressRate.All = [Bout.PressRate.All mean_rate];
    Bout.CI.All = [Bout.CI.All ci_rate];
    Bout.Stay.All = [Bout.Stay.All pStay];
    Bout.N.All = [Bout.N.All length(thisdata)];
    % good
    idxFilter = Bout.AllPress.isAfterGood{i};
    thisdata = Bout.AllPress.PressRate{i}(idxFilter);
    mean_rate = mean(thisdata,'omitnan');
    if length(thisdata)>1
        ci_rate = bootci(nBoot, @mean, thisdata);
    else
        ci_rate = [NaN;NaN];
    end
    pStay = sum(Bout.AllPress.isStay{i}(idxFilter))./length(Bout.AllPress.isStay{i}(idxFilter));
    Bout.PressRate.Good = [Bout.PressRate.Good mean_rate];
    Bout.CI.Good = [Bout.CI.Good ci_rate];
    Bout.Stay.Good = [Bout.Stay.Good pStay];
    Bout.N.Good = [Bout.N.Good length(thisdata)];
    % bad
    idxFilter = ~Bout.AllPress.isAfterGood{i};
    thisdata = Bout.AllPress.PressRate{i}(idxFilter);
    mean_rate = mean(thisdata,'omitnan');
    if length(thisdata)>1
        ci_rate = bootci(nBoot, @mean, thisdata);
    else
        ci_rate = [NaN;NaN];
    end
    pStay = sum(Bout.AllPress.isStay{i}(idxFilter))./length(Bout.AllPress.isStay{i}(idxFilter));
    Bout.PressRate.Bad = [Bout.PressRate.Bad mean_rate];
    Bout.CI.Bad = [Bout.CI.Bad ci_rate];
    Bout.Stay.Bad = [Bout.Stay.Bad pStay];
    Bout.N.Bad = [Bout.N.Bad length(thisdata)];
end

%% plot
setDefaultStyles;

hf = figure(1); clf(hf);
set(hf,'Unit','centimeters','position',[1 1 figSize], ...
    'nextplot','add','Color','w','ToolBar','none','PaperPositionMode','auto');

% progress in session
thisX = x_start;
thisY = y_start;

%%%%%%%%%%%%%%%%%%%%%%%%% x - time in session, y - press rate
% thisX = x_start;
% thisY = thisY+4.8;
xSize = figSize(1)-thisX-x_space_right;
ySize = 5;
ha_progress = axes('unit', 'centimeters', 'position',[thisX thisY xSize ySize], 'nextplot', 'add',...
        'xtick', tTicks, 'xlim', tLim);

colororder([cBlack;cBrown])
yyaxis(ha_progress,'left');

line(xlim, zeros([1 2]), 'Color', 'k', 'linewidth', 0.5, 'LineStyle', '-.');
line(xlim, repmat(vb.PressRate,[1 2]), 'Color', 'k', 'linewidth', 2, 'LineStyle', '-');
% line([0 vb.EarlyLateMin(1)*60], repmat(vb.PressRateEarly,[1 2]), 'Color', 'k', 'linewidth', 1.5, 'markersize', 8);
% line(vb.SessionDuration+[-vb.EarlyLateMin(2)*60 0], repmat(vb.PressRateLate,[1 2]), 'Color', 'k', 'linewidth', 1.5, 'markersize', 8);
if ~isempty(t_BadPress)
    line(repmat(t_BadPress,[1 2]),[0 pressLineLen]+pressLineBottom, 'color', 'k', 'linewidth', 0.6, 'LineStyle', '-', 'Marker', 'none');
end
if ~isempty(t_BadPokeFirst)
    line(repmat(t_BadPokeFirst,[1 2]),[0 pokeLineLen]+pokeLineBottom, 'color', 'k', 'linewidth', 0.6, 'LineStyle', '-', 'Marker', 'none');
end
if ~isempty(t_GoodPress)
    line(repmat(t_GoodPress,[1 2]),[0 pressLineLen*2]+pressLineBottom, 'color', cGreen, 'linewidth', 0.6, 'LineStyle', '-', 'Marker', 'none');
end
if ~isempty(t_GoodPokeFirst)
    line(repmat(t_GoodPokeFirst,[1 2]),[0 pokeLineLen*2]+pokeLineBottom, 'color', cBlue, 'linewidth', 0.6, 'LineStyle', '-', 'Marker', 'none');
end
% line(repmat(vb.tVI_End,[2 1]),[0 rateLim(2)], 'Color',cGray, 'linewidth', 0.5);
for i=1:length(vb.tVI_End)
    plotshaded([vb.tVI_End(i)-vb.VI(i), vb.tVI_End(i)], repmat([0 rateLim(2)]',[1 2]), cGray, 0.15);
end

% Probability that next event of the press is press (alternative is poke)
yyaxis(ha_progress,'right');
line(xlim, [0.5 0.5], 'Color', cBrown, 'linewidth', 0.5, 'LineStyle', '-.');
% plot(t_PressNextPress, P_PressNextPress, '-.', 'LineWidth', 0.5, 'MarkerEdgeColor', 'w', 'MarkerFaceColor', cBrown, 'Color', cBrown);
plot(t_PressNextPress, P_PressNextPress_smo, '-','color', cBrown, 'LineWidth', 1);
ylim(probLim);
yticks(probTicks);
ylabel('Stay probability');
% ylabel('P(Press | Press)');

% Press rate
yyaxis(ha_progress,'left');
plot(t_rate, N_rate, '-k', 'LineWidth', 1);
plot(t_rate, N_rate, 'vk', 'LineWidth', 0.5, 'LineStyle', 'none',...
    'MarkerSize', 6, 'MarkerEdgeColor', 'w', 'MarkerFaceColor', 'k');
plot(t_rate, N_rate_smooth, '-','color', cRed, 'LineWidth', 2.5);

text(tLim(2),vb.PressRate,sprintf('Mean=%.1f ',vb.PressRate),...
    'VerticalAlignment','bottom','HorizontalAlignment','right','FontSize',fontsize_label)
text(vb.EarlyLateMin(1)*60,rateLim(2),sprintf('EarlyRate=%.1f|',vb.EarlyLatePressRate(1)),...
    'VerticalAlignment','top','HorizontalAlignment','right','FontSize',fontsize_label)
text(vb.SessionDuration-vb.EarlyLateMin(2)*60,rateLim(2),sprintf('|LateRate=%.1f',vb.EarlyLatePressRate(2)),...
    'VerticalAlignment','top','HorizontalAlignment','left','FontSize',fontsize_label)
text(tLim(2)-0.2*diff(tLim)/xSize,rateLim(2),sprintf('$\\bar{VI}$=%.1f',mean(vb.VI,'omitnan')),...
    'VerticalAlignment','top','HorizontalAlignment','right','FontSize',fontsize_label,...
    'BackgroundColor', cGray.*0.15+cWhite.*0.85, 'Interpreter', 'latex');
text(tLim(2),pressLineBottom,{' Press',sprintf(' %d/%d',length(t_GoodPress),length(t_GoodPress)+length(t_BadPress))},...
    'VerticalAlignment','bottom','HorizontalAlignment','left','FontSize',fontsize_label);
text(tLim(2),pokeLineBottom,{' PokeFirst',sprintf(' %d/%d',length(t_GoodPokeFirst),length(t_GoodPokeFirst)+length(t_BadPokeFirst))},...
    'VerticalAlignment','bottom','HorizontalAlignment','left','FontSize',fontsize_label);
ylabel('Press rate (min^{-1})');
ylim(rateLim);
yticks(rateTicks);

%%%%%%%%%%%%%%%%%%%% x - duration, y - cdf
thisX = x_start;
thisY = thisY+ySize+y_space_big;
xSize = (figSize(1)-thisX-x_space_right-x_space_label)*2/3;
ySize = 3;
ha_cdf = axes('unit', 'centimeters', 'position',[thisX thisY xSize ySize], 'nextplot', 'add',...
        'xlim', iriLogLim, 'YGrid', 'on', 'XGrid', 'on', 'XScale', 'log', 'XTick', iriLogTicks);

% plotshaded(iriEdges, [zeros(size(cdf_ipi)); cdf_ipi], 'k',0.1);
% plotshaded(iriEdges, [zeros(size(cdf_iwi)); cdf_iwi], cBlue,0.1);

wLine = 2;
% ha_retrieval = plot(iriEdges, cdf_retrieval, 'Color', cCyan, 'LineWidth', wLine);
ha_mt = plot(iriEdges, cdf_mt, 'Color', cCyan, 'LineWidth', wLine);
ha_restart = plot(iriEdges, cdf_restart, 'Color', cBrown, 'LineWidth', wLine);
ha_press = plot(iriEdges, cdf_ipi, 'Color', cRed, 'LineWidth', wLine);
ha_badpoke = plot(iriEdges, cdf_ibpi, 'Color', cPurple, 'LineWidth', wLine);
ha_vi = plot(iriEdges, cdf_vi, 'Color', 'k', 'LineWidth', wLine);
ha_reinforcer = plot(iriEdges, cdf_iwi, 'Color', cOrange, 'LineWidth', wLine);

ha_list = [ha_mt, ha_restart, ha_press, ha_badpoke, ha_reinforcer, ha_vi];
ha_name = {'MT', 'Restart','Inter-press', 'Inter-badpoke', 'Inter-reward', 'VI'};
le = legend(ha_list, ha_name,...
    'fontsize',fontsize_label,'Location','southeastoutside');
le.ItemTokenSize(1) = 5;
legend('Box','off');
ylim(cdfLim)
ylabel('cdf');
xlabel('Time (s) - Log Scale');

%%%%%%%%%%%%%%%%%%%%% movement time x Good/Bad poke
thisX = thisX + xSize + x_space_label;
thisY = thisY;
xSize = (figSize(1)-thisX-x_space_right-x_space)/2;
haMT = axes('unit', 'centimeters', 'position',[thisX thisY xSize ySize], 'nextplot', 'add',...
        'YGrid', 'on');
ha_bad_mt = plot(mtEdges, pdf_mt_bad, 'Color', 'k', 'LineWidth', 1.5);
ha_good_mt = plot(mtEdges, pdf_mt_good, 'Color', cBlue, 'LineWidth', 1.5);

% ha_list = [ha_bad_mt, ha_good_mt];
% ha_name = {'BadPoke', 'GoodPoke'};
% le = legend(ha_list, ha_name,...
%     'fontsize',fontsize_label,'Location','northeast');
% le.ItemTokenSize(1) = 10;
% legend('Box','off');

title('Movement time');
xticks(mtTicks);
ylim(ylim.*1.2);
xlabel('Time (s)');
ylabel('pdf');

%%%%%%%%%%%%%%%%%%%%%% re-press latency x Good/Bad poke
thisX = thisX + xSize + x_space;
thisY = thisY;
xSize = figSize(1)-thisX-x_space_right;
ha6 = axes('unit', 'centimeters', 'position',[thisX thisY xSize ySize], 'nextplot', 'add',...
        'YGrid', 'on');

ha_bad_rl = plot(latencyEdges, pdf_rL_bad, 'Color', 'k', 'LineWidth', 1.5);
ha_good_rl = plot(latencyEdges, pdf_rL_good, 'Color', cBlue, 'LineWidth', 1.5);

ha_list = [ha_bad_rl, ha_good_rl];
ha_name = {'BadPoke', 'GoodPoke'};
le = legend(ha_list, ha_name,...
    'fontsize',fontsize_label,'Location','northwest');
le.ItemTokenSize(1) = 7;
legend('Box','off');
title('Restart latency');
xticks(latencyTicks);
xlim(latencyLim);
ylim(ylim.*1.2);
xlabel('Time (s)');
% ylabel('pdf');

%%%%%%%%%%%%%%%%% Event rate - Session time binned (first 30 min)
thisX = x_start;
thisY = thisY+ySize+y_space_big;
xSize = 4;
ySize = 3;
haRateProgress = axes('unit', 'centimeters', 'position',[thisX thisY xSize ySize], 'nextplot', 'add');

plot(ticksEpoch,N_goodpoke_Epoch,'Color',cBlue, 'LineStyle', '-.', 'LineWidth', 1);
plot(ticksEpoch,N_badpoke_Epoch,'Color',cBlack, 'LineStyle', '-.', 'LineWidth', 1);
plot(ticksEpoch,N_press_Epoch,'Color',cBlack, 'LineStyle', '-', 'LineWidth', 1);
ha_goodpokeE = plot(ticksEpoch,N_goodpoke_Epoch,'lineStyle','none', 'LineWidth', 1.2,...
    'Marker', 'o', 'MarkerSize', 5, 'MarkerFaceColor', cWhite, 'MarkerEdgeColor', cBlue);
ha_badpokeE = plot(ticksEpoch,N_badpoke_Epoch,'lineStyle','none', 'LineWidth', 1.2,...
    'Marker', 'o', 'MarkerSize', 5, 'MarkerFaceColor', cWhite, 'MarkerEdgeColor', cBlack);
ha_pressE = plot(ticksEpoch,N_press_Epoch,'lineStyle','none', 'LineWidth', 0.5,...
    'Marker', 'v', 'MarkerSize', 6, 'MarkerFaceColor', cBlack, 'MarkerEdgeColor', cWhite);

ylabel('Number / min');
xlabel(sprintf('%d-min bins',min2bin));
xlim([ticksEpoch(1)-0.5 ticksEpoch(end)+0.5]);
xticks(ticksEpoch);
ylim(rateEpochLim);
yticks(rateEpochTicks);

le_rateE = legend([ha_pressE ha_badpokeE ha_goodpokeE],{'Press','BadPoke','GoodPoke'},...
    'Location','southeastoutside', 'FontSize',fontsize_label);
legend('box', 'off');

%%%%%%%%%%%%%%%%%%%%%%% Lag-IPI plot
% thisX = x_start + xSize + x_space_label;
% thisY = thisY;
% xSize = 3;
% haLagIPI = axes('unit', 'centimeters', 'position',[thisX thisY xSize ySize], 'nextplot', 'add',...
%         'YGrid', 'on', 'XGrid', 'on');
% 
% line(ipiLim,ipiLim,'Color','k','LineWidth',1)
% scatter(ipi_last,ipi_this,15,...
%     'MarkerFaceColor','k','MarkerEdgeColor','w','LineWidth',0.5,'MarkerFaceAlpha',0.5)
% xlim(ipiLim);
% ylim(ipiLim);
% xlabel('Last inter-press interval');
% ylabel('This IPI');

ySize2 = 1.4;
ySize = ySize-y_space_small-ySize2;
%%%%%%%%%%%%% N-back stay probability & number (all)
thisX = thisX + xSize + x_space_label;
thisY = thisY;
xSize = (figSize(1)-thisX-x_space_right-x_space_small*2)/3;
haNstay = axes('unit', 'centimeters', 'position',[thisX thisY xSize ySize], 'nextplot', 'add');
xticks(Bout.Ticks);
xlim([Bout.Ticks(1)-0.5 Bout.Ticks(end)+0.5]);
xlabel('#Press rank');

colororder([cBlack;cBrown])

yyaxis left;
plot(Bout.Ticks, Bout.N.All, 'color', cBlack, 'LineStyle', '-', 'LineWidth', 1);
plot(Bout.Ticks, Bout.N.All, 'lineStyle','none', 'LineWidth', 0.5,...
    'Marker', 'v', 'MarkerSize', 6, 'MarkerFaceColor', cBlack, 'MarkerEdgeColor', cWhite);
ylabel('N');
N_Lim = ylim;
N_Lim(1) = 0;
ylim(N_Lim);
N_Ticks = yticks;

yyaxis right;
plot(Bout.Ticks, Bout.Stay.All, 'color', cBrown, 'LineStyle', '-', 'LineWidth', 1);
plot(Bout.Ticks, Bout.Stay.All, 'lineStyle','none', 'LineWidth', 0.5,...
    'Marker', 'v', 'MarkerSize', 6, 'MarkerFaceColor', cBrown, 'MarkerEdgeColor', cWhite);
% ylabel('P(Stay)');
ylim([0 1]); 
yticklabels({});

%%% N-back press rate (all)
thisX = thisX;
thisY2 = thisY + ySize + y_space_small;

haNback = axes('unit', 'centimeters', 'position',[thisX thisY2 xSize ySize2], 'nextplot', 'add');

idxUse = ~isnan(Bout.CI.All(1,:));
if sum(idxUse)>1
    plotshaded(Bout.Ticks(idxUse), Bout.CI.All(:,idxUse), cBlack, 0.1);
end
plot(Bout.Ticks, Bout.PressRate.All, 'color', cBlack, 'LineStyle', '-', 'LineWidth', 1);
ha_Nback_all = plot(Bout.Ticks, Bout.PressRate.All, 'lineStyle','none', 'LineWidth', 0.5,...
    'Marker', 'v', 'MarkerSize', 6, 'MarkerFaceColor', cBlack, 'MarkerEdgeColor', cWhite);

xticks(Bout.Ticks);
xticklabels({});
xlim([Bout.Ticks(1)-0.5 Bout.Ticks(end)+0.5]);
xlabel('');

ylim(boutRateLim);
yticks(boutRateTicks);
ylabel('Press / min');

title('All');

%%%%%%%%%%%%% N-back stay probability & number (good)
thisX = thisX + xSize + x_space_small;
thisY = thisY;

haNstay = axes('unit', 'centimeters', 'position',[thisX thisY xSize ySize], 'nextplot', 'add');
xticks(Bout.Ticks);
xlim([Bout.Ticks(1)-0.5 Bout.Ticks(end)+0.5]);
% xlabel('#Press rank');

colororder([cBlack;cBrown])

yyaxis left;
plot(Bout.Ticks, Bout.N.Good, 'color', cBlack, 'LineStyle', '-', 'LineWidth', 1);
plot(Bout.Ticks, Bout.N.Good, 'lineStyle','none', 'LineWidth', 0.5,...
    'Marker', 'v', 'MarkerSize', 6, 'MarkerFaceColor', cBlack, 'MarkerEdgeColor', cWhite);
ylim(N_Lim);
yticks(N_Ticks);
yticklabels({});
% ylabel('N');

yyaxis right;
plot(Bout.Ticks, Bout.Stay.Good, 'color', cBrown, 'LineStyle', '-', 'LineWidth', 1);
plot(Bout.Ticks, Bout.Stay.Good, 'lineStyle','none', 'LineWidth', 0.5,...
    'Marker', 'v', 'MarkerSize', 6, 'MarkerFaceColor', cBrown, 'MarkerEdgeColor', cWhite);
% ylabel('P(Stay)');
ylim([0 1]);
yticklabels({});

%%% N-back press rate (Good)
thisX = thisX;
thisY2 = thisY + ySize + y_space_small;

haNback = axes('unit', 'centimeters', 'position',[thisX thisY2 xSize ySize2], 'nextplot', 'add');

idxUse = ~isnan(Bout.CI.Good(1,:));
if sum(idxUse)>1
    plotshaded(Bout.Ticks(idxUse), Bout.CI.Good(:,idxUse), cBlack, 0.1);
end
plot(Bout.Ticks, Bout.PressRate.Good, 'color', cBlack, 'LineStyle', '-', 'LineWidth', 1);
ha_Nback_all = plot(Bout.Ticks, Bout.PressRate.Good, 'lineStyle','none', 'LineWidth', 0.5,...
    'Marker', 'v', 'MarkerSize', 6, 'MarkerFaceColor', cBlack, 'MarkerEdgeColor', cWhite);

xticks(Bout.Ticks);
xticklabels({});
xlim([Bout.Ticks(1)-0.5 Bout.Ticks(end)+0.5]);
xlabel('');

ylim(boutRateLim);
yticks(boutRateTicks);
yticklabels({});
% ylabel('Press / min');

title('AfterGoodPoke');

%%%%%%%%%%%%% N-back stay probability & number (bad)
thisX = thisX + xSize + x_space_small;
thisY = thisY;

haNstay = axes('unit', 'centimeters', 'position',[thisX thisY xSize ySize], 'nextplot', 'add');
xticks(Bout.Ticks);
xlim([Bout.Ticks(1)-0.5 Bout.Ticks(end)+0.5]);
% xlabel('#Press rank');

colororder([cBlack;cBrown])

yyaxis left;
plot(Bout.Ticks, Bout.N.Bad, 'color', cBlack, 'LineStyle', '-', 'LineWidth', 1);
plot(Bout.Ticks, Bout.N.Bad, 'lineStyle','none', 'LineWidth', 0.5,...
    'Marker', 'v', 'MarkerSize', 6, 'MarkerFaceColor', cBlack, 'MarkerEdgeColor', cWhite);
ylim(N_Lim);
yticks(N_Ticks);
yticklabels({});
% ylabel('N');

yyaxis right;
plot(Bout.Ticks, Bout.Stay.Bad, 'color', cBrown, 'LineStyle', '-', 'LineWidth', 1);
plot(Bout.Ticks, Bout.Stay.Bad, 'lineStyle','none', 'LineWidth', 0.5,...
    'Marker', 'v', 'MarkerSize', 6, 'MarkerFaceColor', cBrown, 'MarkerEdgeColor', cWhite);
ylabel('P(Stay)');
ylim([0 1]);

%%% N-back press rate (bad)
thisX = thisX;
thisY2 = thisY + ySize + y_space_small;

haNback = axes('unit', 'centimeters', 'position',[thisX thisY2 xSize ySize2], 'nextplot', 'add');

idxUse = ~isnan(Bout.CI.Bad(1,:));
if sum(idxUse)>1
    plotshaded(Bout.Ticks(idxUse), Bout.CI.Bad(:,idxUse), cBlack, 0.1);
end
plot(Bout.Ticks, Bout.PressRate.Bad, 'color', cBlack, 'LineStyle', '-', 'LineWidth', 1);
ha_Nback_all = plot(Bout.Ticks, Bout.PressRate.Bad, 'lineStyle','none', 'LineWidth', 0.5,...
    'Marker', 'v', 'MarkerSize', 6, 'MarkerFaceColor', cBlack, 'MarkerEdgeColor', cWhite);

xticks(Bout.Ticks);
xticklabels({});
xlim([Bout.Ticks(1)-0.5 Bout.Ticks(end)+0.5]);
xlabel('');

ylim(boutRateLim);
yticks(boutRateTicks);
yticklabels({});
% ylabel('Press / min');

title('AfterBadPoke');

%%%%%%%%%%%%%%%%% title
titlename = [vb.Subject ' | ' char(vb.DateTime)];
if vb.isDevaluation
    titlename = [titlename ' | Devaluation'];
end
if vb.isExtinction
    titlename = [titlename ' | Extinction'];
end
annotation('textbox', ...
    'Units', 'centimeters', ...
    'Position', [0, figSize(2)-0.5, figSize(1) 0.5], ...
    'String', titlename, ...
    'FontName', 'Dejavu Sans', ...
    'FontWeight', 'bold', ...
    'FontSize', 11, ...
    'BackgroundColor', [1 1 1], ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'top',...
    'EdgeColor', 'none');

% print
savename = ['FigFull_VI_' vb.Subject '_' vb.Session];
savename = fullfile(pathFigSave, savename);
print(hf, [savename '.png'], '-dpng', '-r300');
end