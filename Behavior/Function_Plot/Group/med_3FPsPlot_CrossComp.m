function med_3FPsPlot_CrossComp(btAll2d,grpVar,datefilter)
% _________________________________________________________________________
% File:               med_3FPsPlot_CrossComp.m
% Created on:         Oct 2, 2021
% Created by:         Yu Chen
% Last revised on:    Mar 14, 2022
% Last revised by:    Yu Chen
% _________________________________________________________________________
%% initiate
grpName = unique(grpVar);
if length(grpName)~=2
    error("Grouping variables have invalid number of elements");
end
if length(datefilter)~=2 %1*2 cell
    error("Date filter has invalid number of groups (not 2)");
end
altMethod = {'mean-std','mean-sem','mean-bootci','quartile','geomean-geomad',...
    'geomean-bootci'};
estMethod = altMethod{1};
errMethod = 'sem';
%% processing data for each datefilter
btAll2d_bkup = btAll2d;

dategrpName = {'Pre','Post'};
da = cell(1,2);
for ida=1:2
da{ida}.Session = datefilter{ida};
da{ida}.btAll2d = btAll2d_bkup(:,da{ida}.Session);
btAll2d = da{ida}.btAll2d;

%% packaging data
TBT = table; % trial by trial data
daterange = zeros(size(btAll2d,1),2);
fpfixed = 0;
for i=1:size(btAll2d,1) % subjects
    for j=1:size(btAll2d,2) % sessions
        tempT = btAll2d{i,j};
        if isempty(tempT)
            continue;
        else
            bt_3fp500 = tempT(tempT.Task=="ThreeFPsMixedBpod",:);
            bt_3fp750 = tempT(tempT.Task=="ThreeFPsMixedBpod750_1250_1750",:);
        end
        switch fpfixed
            case 0
                if isempty(bt_3fp500)
                    if isempty(bt_3fp750)
                        continue;
                    else
                        fpfixed = 750;
                        tempT = bt_3fp750;
                    end
                else
                    fpfixed = 500;
                    tempT = bt_3fp500;
                end
            case 500
                tempT = bt_3fp500;
                if isempty(tempT)
                    continue;
                end
            case 750
                tempT = bt_3fp750;
                if isempty(tempT)
                    continue;
                end
        end
%         tempT = tempT(tempT.Task=="ThreeFPsMixedBpod" & tempT.Type~=0,:);
        tempT = tempT(tempT.Type~=0,:);
        end_warm = find(abs(tempT.FP - 1.4)<1E-8, 1, 'last');
        if isempty(end_warm) || size(tempT,1)<end_warm+2
            continue;
        end
        tempLType = tempT.Type(end_warm+1:end-1);
        tempLFP = tempT.FP(end_warm+1:end-1);
        tempT = tempT(end_warm+2:end,:);
        nrow = size(tempT,1);
        tempGrp = repelem(grpVar(i),nrow)';
        tempT_new = addvars(tempT,tempGrp,'Before','Date','NewVariableNames','Group');
        tempT_new = addvars(tempT_new,tempLType,'After','Type','NewVariableNames','LastType');
        tempT_new = addvars(tempT_new,tempLFP,'After','FP','NewVariableNames','LastFP');
        tempT_new.Date = repelem(j,nrow)';
        tempT_new.Properties.VariableNames{'Date'} = 'Session';
        TBT = [TBT;tempT_new];
        
        date = tempT.Date(1);
        if j==1
            daterange(i,1) = date;
        else
            daterange(i,2) = max(daterange(i,2),date);
        end
    end
end
if fpfixed==750
    fplist = [0.75,1.25,1.75];
    fpcell = {'0.75s','1.25s','1.75s'};
else
    fplist = [0.5,1.0,1.5];
    fpcell = {'0.5s','1s','1.5s'};
end
datelim = [min(daterange(:,1));max(daterange(:,2))];
datelim = num2str(datelim);
datelim = string(datelim(:,end-3:end))';
%% Calculate estimate for each subject
EES = table; % estimate for each subject
sbjlist = unique(TBT.Subject);
for i=1:length(sbjlist)
    data = TBT(TBT.Subject==sbjlist(i),:);
    E = table;
    E.Subject = sbjlist(i);
    E.Group = data.Group(1);
    E.Date = daterange(i,:);
    
    idxFPS = abs(data.FP-fplist(1))<1E-4;
    idxFPM = abs(data.FP-fplist(2))<1E-4;
    idxFPL = abs(data.FP-fplist(3))<1E-4;
    idxCor = data.Type==1;
    idxPre = data.Type==-1;
    idxLate = data.Type==-2;
    
    E.Perf = [...
        sum(idxCor)./size(data,1),...
        sum(idxPre)./size(data,1),...
        sum(idxLate)./size(data,1)];
    E.Perf_FPS = [...
        sum( idxFPS & idxCor )./sum(idxFPS),...
        sum( idxFPS & idxPre )./sum(idxFPS),...
        sum( idxFPS & idxLate )./sum(idxFPS)];
    E.Perf_FPM = [...
        sum( idxFPM & idxCor )./sum(idxFPM),...
        sum( idxFPM & idxPre )./sum(idxFPM),...
        sum( idxFPM & idxLate )./sum(idxFPM)];
    E.Perf_FPL = [...
        sum( idxFPL & idxCor )./sum(idxFPL),...
        sum( idxFPL & idxPre )./sum(idxFPL),...
        sum( idxFPL & idxLate )./sum(idxFPL)];

    E.RT = mean(data.RT(idxCor),'omitnan');
    E.RT_3FPs = [mean(data.RT(idxCor&idxFPS)),mean(data.RT(idxCor&idxFPM)),mean(data.RT(idxCor&idxFPL))];
    E.RT_3FPs_LastFPS = [...
        mean(data.RT( abs(data.LastFP-fplist(1))<1E-4 & idxFPS & idxCor),'omitnan'),...
        mean(data.RT( abs(data.LastFP-fplist(1))<1E-4 & idxFPM & idxCor),'omitnan'),...
        mean(data.RT( abs(data.LastFP-fplist(1))<1E-4 & idxFPL & idxCor),'omitnan')];
    E.RT_3FPs_LastFPM = [...
        mean(data.RT( abs(data.LastFP-fplist(2))<1E-4 & idxFPS & idxCor),'omitnan'),...
        mean(data.RT( abs(data.LastFP-fplist(2))<1E-4 & idxFPM & idxCor),'omitnan'),...
        mean(data.RT( abs(data.LastFP-fplist(2))<1E-4 & idxFPL & idxCor),'omitnan')];
    E.RT_3FPs_LastFPL = [...
        mean(data.RT( abs(data.LastFP-fplist(3))<1E-4 & idxFPS & idxCor),'omitnan'),...
        mean(data.RT( abs(data.LastFP-fplist(3))<1E-4 & idxFPM & idxCor),'omitnan'),...
        mean(data.RT( abs(data.LastFP-fplist(3))<1E-4 & idxFPL & idxCor),'omitnan')];
    E.RT_3FPs_PostC = [...
        mean(data.RT( data.LastType==1 & idxFPS & idxCor),'omitnan'),...
        mean(data.RT( data.LastType==1 & idxFPM & idxCor),'omitnan'),...
        mean(data.RT( data.LastType==1 & idxFPL & idxCor),'omitnan')];
    E.RT_3FPs_PostP = [...
        mean(data.RT( data.LastType==-1 & idxFPS & idxCor),'omitnan'),...
        mean(data.RT( data.LastType==-1 & idxFPM & idxCor),'omitnan'),...
        mean(data.RT( data.LastType==-1 & idxFPL & idxCor),'omitnan')];
    E.RT_3FPs_PostL = [...
        mean(data.RT( data.LastType==-2 & idxFPS & idxCor),'omitnan'),...
        mean(data.RT( data.LastType==-2 & idxFPM & idxCor),'omitnan'),...
        mean(data.RT( data.LastType==-2 & idxFPL & idxCor),'omitnan')];
    
    edges = 0:0.05:2.5;
    E.HT = histcounts(data.PressDur,edges,'Normalization','probability');
    E.HT_FPS = smooth(histcounts(data.PressDur(idxFPS),edges,'Normalization','probability'),3)';
    E.HT_FPM = smooth(histcounts(data.PressDur(idxFPM),edges,'Normalization','probability'),3)';
    E.HT_FPL = smooth(histcounts(data.PressDur(idxFPL),edges,'Normalization','probability'),3)';
    
    EES = [EES;E];
end
EES = addvars(EES,repelem(string(dategrpName{ida}),size(EES,1))','After','Group','NewVariableNames','DateGroup');
EES = addvars(EES,EES.Subject,'After','Subject','NewVariableNames','SbjBackup');
%% Grand average & sem
EES_val = removevars(EES,{'Subject','SbjBackup','Date','DateGroup'});
GAS = grpstats(EES_val,'Group',{'mean','sem'});

x_edges = movmean(edges,2,'Endpoints','discard');
x_edges_L = edges(1:end-1);
HTT = table;
HTT.Subject = reshape(repelem(EES.Subject,1,length(x_edges)),[numel(EES.HT),1]);
HTT.PressDur = repelem(x_edges',length(sbjlist));
HTT.HT = reshape(EES.HT,[numel(EES.HT),1]);
HTT.HT_FPS = reshape(EES.HT_FPS,[numel(EES.HT_FPS),1]);
HTT.HT_FPM = reshape(EES.HT_FPM,[numel(EES.HT_FPM),1]);
HTT.HT_FPL = reshape(EES.HT_FPL,[numel(EES.HT_FPL),1]);

da{ida}.datelim = datelim;
da{ida}.TBT = TBT;
da{ida}.EES = EES;
da{ida}.GAS = GAS;
da{ida}.HTT = HTT;
end
%% Plot
% pressDur distrubition - heatmap - 2 types: different sbj & grand average
% performance - bar plot, one facet for each group
% RT for 3FPs - bar plot, 3FPs interactive effect with LastFP & LastOutcome
cAcc = Accent(8);
cBlue = cAcc(5,:);
cGray = cAcc(8,:);
cOrange = [0.929,0.49,0.192];
cGray = [0.5 0.5 0.5];
cFPs = [cGray;mean([cOrange;cGray]);cOrange];

fig = figure(5); clf(5);
set(fig, 'unit', 'centimeters', 'position',[1 1 22 22])

t = tiledlayout(fig,3,3);
t.TileSpacing = 'compact';
t.Padding = 'compact';

for i=1:2
GAS = da{i}.GAS;

nexttile(i);
% subplot(3,3,i);
x = 1:3;
y = [GAS.mean_Perf_FPS(1,:);GAS.mean_Perf_FPM(1,:);GAS.mean_Perf_FPL(1,:)]';
err = [GAS.sem_Perf_FPS(1,:);GAS.sem_Perf_FPM(1,:);GAS.sem_Perf_FPL(1,:)]'./2;
h_bar = bar(x,y,'EdgeColor','none');
hold on;
h_err1 = errorbar([1:3]-0.225,y(:,1),err(:,1),'k','linestyle','none','lineWidth',1,'capsize',4);
hold on;
h_err2 = errorbar([1:3],y(:,2),err(:,2),'k','linestyle','none','lineWidth',1,'capsize',4);
hold on;
h_err3 = errorbar([1:3]+0.225,y(:,3),err(:,3),'k','linestyle','none','lineWidth',1,'capsize',4);
xticklabels({'Cor','Pre','Late'});
ylim([0,1]);
h_bar(1).FaceColor = cFPs(1,:);
h_bar(2).FaceColor = cFPs(2,:);
h_bar(3).FaceColor = cFPs(3,:);
title(GAS.Group(1)+"-"+dategrpName{i});
box off; grid on;
legend(fpcell,'Location','northEast');
legend('boxoff');

nexttile(3+i);
% subplot(3,3,3+i);
x = 1:3;
y = [GAS.mean_Perf_FPS(2,:);GAS.mean_Perf_FPM(2,:);GAS.mean_Perf_FPL(2,:)]';
err = [GAS.sem_Perf_FPS(2,:);GAS.sem_Perf_FPM(2,:);GAS.sem_Perf_FPL(2,:)]'./2;
h_bar = bar(x,y,'EdgeColor','none');
hold on;
h_err1 = errorbar([1:3]-0.225,y(:,1),err(:,1),'k','linestyle','none','lineWidth',1,'capsize',4);
hold on;
h_err2 = errorbar([1:3],y(:,2),err(:,2),'k','linestyle','none','lineWidth',1,'capsize',4);
hold on;
h_err3 = errorbar([1:3]+0.225,y(:,3),err(:,3),'k','linestyle','none','lineWidth',1,'capsize',4);
xticklabels({'Cor','Pre','Late'});
ylim([0,1]);
h_bar(1).FaceColor = cFPs(1,:);
h_bar(2).FaceColor = cFPs(2,:);
h_bar(3).FaceColor = cFPs(3,:);
title(GAS.Group(2)+"-"+dategrpName{i});
box off; grid on;
legend(fpcell,'Location','northEast');
legend('boxoff');

nexttile(6+i);
% subplot(3,3,6+i);
h_ht1l = shadedErrorBar(x_edges,GAS.mean_HT_FPL(2,:),GAS.sem_HT_FPL(2,:),...
    'lineProps',{'-','lineWidth',1.3,'color',cGray},'patchSaturation',0.4);
hold on;
h_ht0l = shadedErrorBar(x_edges,GAS.mean_HT_FPL(1,:),GAS.sem_HT_FPL(1,:),...
    'lineProps',{'-','lineWidth',1.3,'color',cBlue},'patchSaturation',0.4);
hold on;
h_ht1m = shadedErrorBar(x_edges,GAS.mean_HT_FPM(2,:),GAS.sem_HT_FPM(2,:),...
    'lineProps',{'-','lineWidth',1,'color',cGray},'patchSaturation',0.3);
hold on;
h_ht0m = shadedErrorBar(x_edges,GAS.mean_HT_FPM(1,:),GAS.sem_HT_FPM(1,:),...
    'lineProps',{'-','lineWidth',1,'color',cBlue},'patchSaturation',0.3);
hold on;
h_ht1s = shadedErrorBar(x_edges,GAS.mean_HT_FPS(2,:),GAS.sem_HT_FPS(2,:),...
    'lineProps',{'-','lineWidth',0.7,'color',cGray},'patchSaturation',0.2);
hold on;
h_ht0s = shadedErrorBar(x_edges,GAS.mean_HT_FPS(1,:),GAS.sem_HT_FPS(1,:),...
    'lineProps',{'-','lineWidth',0.7,'color',cBlue},'patchSaturation',0.2);
ylim([0,0.25]);
legend(flip(GAS.Group));
legend('boxoff');
grid on;
title("HT distribution"+" - "+dategrpName{i});
end

%% PressDur heatmap
da{1}.EES.Subject = strcat(da{1}.EES.Subject,"-"+dategrpName{1});
da{2}.EES.Subject = strcat(da{2}.EES.Subject,"-"+dategrpName{2});
EES = [da{1}.EES;da{2}.EES];

da{1}.HTT.Subject = strcat(da{1}.HTT.Subject,"-"+dategrpName{1});
da{2}.HTT.Subject = strcat(da{2}.HTT.Subject,"-"+dategrpName{2});
HTT = [da{1}.HTT;da{2}.HTT];

sortEES = sortrows(EES,[3,2,4],{'ascend','ascend','descend'});
sortSbj = cellstr(sortEES.Subject);
% boss's requirement
sortSbj = {'38-Pre';'38-Post';'Roy-Pre';'Roy-Post';'Mold-Pre';'Mold-Post';...
    'Vigor-Pre';'Vigor-Post';'Tyrell-Pre';'Tyrell-Post';...
    '42-Pre';'42-Post';'Novel-Pre';'Novel-Post'};

idx_dis = mod(x_edges_L,0.5)==0;
xlab = nan(size(x_edges_L));
xlab(idx_dis) = x_edges_L(idx_dis);


nexttile(3);
% subplot(3,3,3);
h_htFPS = heatmap(HTT,'PressDur','Subject','ColorVariable','HT_FPS',...
    'Colormap',parula,'GridVisible','off');
h_htFPS.XDisplayLabels = string(xlab);
h_htFPS.YDisplayData = sortSbj;
h_htFPS.XLabel = '';
h_htFPS.YLabel = '';
h_htFPS.Title = strcat('FP ',fpcell{1});

nexttile(6);
% subplot(3,3,6);
h_htFPM = heatmap(HTT,'PressDur','Subject','ColorVariable','HT_FPM',...
    'Colormap',parula,'GridVisible','off');
h_htFPM.XDisplayLabels = string(xlab);
h_htFPM.YDisplayData = sortSbj;
h_htFPM.XLabel = '';
h_htFPM.YLabel = '';
h_htFPM.Title = strcat('FP ',fpcell{2});

nexttile(9);
% subplot(3,3,9);
h_htFPL = heatmap(HTT,'PressDur','Subject','ColorVariable','HT_FPL',...
    'Colormap',parula,'GridVisible','off');
h_htFPL.XDisplayLabels = string(xlab);
h_htFPL.YDisplayData = sortSbj;
h_htFPL.XLabel = '';
h_htFPL.YLabel = '';
h_htFPL.Title = strcat('FP ',fpcell{3});

sgtitle("3FPs("+num2str(fpfixed)+"): (#"+...
    string(da{1}.Session(1))+"-"+string(string(da{1}.Session(end)))+" & #"+...
    string(da{2}.Session(1))+"-"+string(string(da{2}.Session(end)))+...
    ") (mean-sem)");
%% Save
figName = "Comp3FPs_"+...
    string(da{1}.Session(1))+"-"+string(string(da{1}.Session(end)))+"_"+...
    string(da{2}.Session(1))+"-"+string(string(da{2}.Session(end)));
figPath = pwd;
figFile = fullfile(figPath,figName);
saveas(gcf, figFile, 'fig');
% saveas(gcf, figFile, 'png');
end

