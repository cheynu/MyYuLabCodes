function h = plotPeakProgressIndiv(pdataIndiv,tarDelay,opt)
%PLOTPEAKPROGRESSINDIV 此处显示有关此函数的摘要
%   此处显示详细说明

arguments
    pdataIndiv
    tarDelay
    opt.SavePath = pwd
    opt.plotRange = [] % e.g., []: plot all sessions; [1 2 3]: plot 1st, 2nd, 3rd sessions
end
savePath = opt.SavePath;
plotRange = opt.plotRange;

if ~isempty(plotRange)
    pdataRaw = pdataIndiv; % for debugging
    pdataIndiv = pdataIndiv(plotRange);
end
%%
nSess = length(pdataIndiv);

ANM = pdataIndiv{1}.ANM;
AllTreatment = cellfun(@(x)x.Treatment,pdataIndiv,'UniformOutput',false);
AllDateStr = cellfun(@(x)x.Date,pdataIndiv,'UniformOutput',false);

mSSMS = [];
lowerSSMS = [];
upperSSMS = [];
mPokeRateAll = [];
mPokeRateRun = [];
ciPRAll = [];
ciPRRun = [];
for iSess=1:nSess
    pdata = pdataIndiv{iSess};
    
    ssmsM = pdata.SSMS.Mean;
    ciSSMS = pdata.SSMS.CI;
    pokeRateAllM = pdata.PokeRate.PI.Mean;
    pokeRateRunM = pdata.PokeRate.ST2SP.Mean;
    cipokeRateAll = pdata.PokeRate.PI.CI;
    cipokeRateRun = pdata.PokeRate.ST2SP.CI;

    mSSMS = [mSSMS ssmsM'];
    lowerSSMS = [lowerSSMS ciSSMS(1,:)'];
    upperSSMS = [upperSSMS ciSSMS(2,:)'];
    mPokeRateAll = [mPokeRateAll pokeRateAllM];
    mPokeRateRun = [mPokeRateRun pokeRateRunM];
    ciPRAll = [ciPRAll cipokeRateAll];
    ciPRRun = [ciPRRun cipokeRateRun];
end

idxDCZ = find(contains(AllTreatment,'DCZ'));
%% Plot
xl = [0.5 nSess+0.5];
yl = [0 tarDelay*2];
h = figure(102); clf(h);
set(h, 'unit', 'centimeters', 'position',[2 2 10 15], 'paperpositionmode', 'auto',...
    'renderer','Painters');

subplot(4,1,[1 2]);
line([0 nSess],[tarDelay tarDelay],'color','r','linewidth',1);
hold on;
if ~isempty(idxDCZ)
    for i=1:length(idxDCZ)
        x = idxDCZ(i);
        fill([x-0.5 x+0.5 x+0.5 x-0.5],[yl(1) yl(1) yl(2) yl(2)],[0 0.447 0.741],'FaceAlpha',0.2,'EdgeAlpha',0.2);
    end
end
ha_middle = shadedErrorBar(1:nSess,mSSMS(3,:),abs([upperSSMS(3,:);lowerSSMS(3,:)]-mSSMS(3,:)),...
    'lineProps',{'k.-','linewidth',1.5,'markersize',15},'patchSaturation',0.15);
ha_start = shadedErrorBar(1:nSess,mSSMS(1,:),abs([upperSSMS(1,:);lowerSSMS(1,:)]-mSSMS(1,:)),...
    'lineProps',{'m.--','linewidth',1.5,'markersize',15},'patchSaturation',0.15);
ha_stop = shadedErrorBar(1:nSess,mSSMS(2,:),abs([upperSSMS(2,:);lowerSSMS(2,:)]-mSSMS(2,:)),...
    'lineProps',{'g.--','linewidth',1.5,'markersize',15},'patchSaturation',0.15);
set(gca,'XTick',1:length(AllDateStr),'XTickLabel',{});
xlim(xl); ylim(yl);
ylabel('Time from press (s)');
le = legend([ha_middle.mainLine ha_start.mainLine ha_stop.mainLine],{'Middle','StartTime','StopTime'},...
    'Location','northwest');
le.ItemTokenSize = 10;
legend('boxoff');
title(ANM);

subplot(4,1,3);
if ~isempty(idxDCZ)
    for i=1:length(idxDCZ)
        x = idxDCZ(i);
        fill([x-0.5 x+0.5 x+0.5 x-0.5],[yl(1) yl(1) yl(2) yl(2)],[0 0.447 0.741],'FaceAlpha',0.2,'EdgeAlpha',0.2);
        hold on;
    end
end
ha_spread = shadedErrorBar(1:nSess,mSSMS(4,:),abs([upperSSMS(4,:);lowerSSMS(4,:)]-mSSMS(4,:)),...
    'lineProps',{'k.-','linewidth',1.5,'markersize',15},'patchSaturation',0.15);
set(gca,'XTick',1:length(AllDateStr),'XTickLabel',{});
xlim(xl); ylim(yl);
ylabel('Spread (s)');
box off

subplot(4,1,4);
if ~isempty(idxDCZ)
    for i=1:length(idxDCZ)
        x = idxDCZ(i);
        fill([x-0.5 x+0.5 x+0.5 x-0.5],[yl(1) yl(1) yl(2) yl(2)],[0 0.447 0.741],'FaceAlpha',0.2,'EdgeAlpha',0.2);
        hold on;
    end
end
ha_pr_all = shadedErrorBar(1:nSess,mPokeRateAll,abs(flip(ciPRAll,1)-mPokeRateAll),...
    'lineProps',{'k.-','linewidth',1.5,'markersize',15},'patchSaturation',0.15);
hold on;
ha_pr_run = shadedErrorBar(1:nSess,mPokeRateRun,abs(flip(ciPRRun,1)-mPokeRateRun),...
    'lineProps',{'r.-','linewidth',1.5,'markersize',15},'patchSaturation',0.15);
set(gca,'XTick',1:length(AllDateStr),'XTickLabel',AllDateStr);
xlim(xl);
ylm = ylim;
ylim([ylm(1) min(max(mPokeRateRun)+3,ylm(2))]);
ylabel('Pokes / s');
box off

le = legend([ha_pr_all.mainLine ha_pr_run.mainLine],{'Average','Start-Stop'},'Location','northwest');
le.ItemTokenSize(1) = 10;
legend('boxoff');

saveName = fullfile(savePath,append('StartTimeAnalysis_',ANM,'.png'));
print(h,saveName,'-dpng');

end