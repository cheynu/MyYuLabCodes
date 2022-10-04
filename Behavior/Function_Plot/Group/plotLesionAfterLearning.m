function plotLesionAfterLearning(btAll2d,plotRange)
%%
altMethod = {'mean','median'};
global cenMethod edges_RT edges_HT edges_RelT smo_win;
cenMethod = altMethod{2}; % each subject's central estimate
grandCen = 'mean';
grandErr = 'sem';

edges_RT = 0:0.025:0.6; % Reaction Time (only correct)
edges_RelT = 0:0.05:1; % Realease Time (correct + late trials)
edges_HT = 0:0.05:2.5; % Hold Time (all trials)

smo_win = 8; % smoothdata('gaussian'), 
cmpWin = 3; % cmpWin sessions before/after surgery to compare
grpName = ["Lesion";"Sham"];
prdName = ["Pre","Post"];
fplist = [0.5 1.0 1.5];
DataOut = [];
%% Data processing
btAll2d_use = btAll2d(:,plotRange);
% session by session, trial by trial: 2 packaging method
[SBS,TBT] = packData(btAll2d_use);

sess_pre = unique(SBS.Session(cellfun(@(x) ~isempty(x),strfind(SBS.Group,prdName(1)))));
sess_post = unique(SBS.Session(cellfun(@(x) ~isempty(x),strfind(SBS.Group,prdName(2)))));
% subject * group
TBTsg = [estTBT_3FPs(TBT(cellfun(@(x) ~isempty(x),strfind(TBT.Group,strcat(grpName(1),'-',prdName(1)))) & ismember(TBT.Session,sess_pre(end-cmpWin+1:end)),:));...
    estTBT_3FPs(TBT(cellfun(@(x) ~isempty(x),strfind(TBT.Group,strcat(grpName(1),'-',prdName(2)))) & ismember(TBT.Session,sess_post(1:cmpWin)),:));...
    estTBT_3FPs(TBT(cellfun(@(x) ~isempty(x),strfind(TBT.Group,strcat(grpName(2),'-',prdName(1)))) & ismember(TBT.Session,sess_pre(end-cmpWin+1:end)),:));...
    estTBT_3FPs(TBT(cellfun(@(x) ~isempty(x),strfind(TBT.Group,strcat(grpName(2),'-',prdName(2)))) & ismember(TBT.Session,sess_post(1:cmpWin)),:))];

% group
TBTg = grpstats(removevars(TBTsg,{'Subject','Task','Type'}),'Group',{grandCen,grandErr});

% between subject group
SBSbtw = grpstats(addvars(removevars(SBS,{'Subject','Date','Task','Group','Type'}),...
    erase(SBS.Group,cellstr({strcat('-',prdName(1)),strcat('-',prdName(2))})),'NewVariableNames','Group'),...
    {'Group','Session'},{grandCen,grandErr});
% subject * group
SBSsg = grpstats(removevars(SBS,{'Session','Date','Task','Type'}),{'Subject','Group'},{grandCen,grandErr});

xedges = struct;
xedges.edges_RT = edges_RT;
xedges.edges_RelT = edges_RelT;
xedges.edges_HT = edges_HT;
xedges.RT = movmean(edges_RT,2,'Endpoints','discard');
xedges.RelT = movmean(edges_RelT,2,'Endpoints','discard');
xedges.HT = movmean(edges_HT,2,'Endpoints','discard');

DataOut.TBTsg = TBTsg;
DataOut.TBTg = TBTg; 
DataOut.SBSbtw = SBSbtw;
DataOut.SBSsg = SBSsg;
DataOut.xedges = xedges;
%% Statistics
p = struct;
% performance, pre v.s. post
corLesBefore = TBTsg.Cor(strcmp(TBTsg.Group,strcat(grpName(1),'-',prdName(1))))';
corLesAfter = TBTsg.Cor(strcmp(TBTsg.Group,strcat(grpName(1),'-',prdName(2))))';
corShamBefore = TBTsg.Cor(strcmp(TBTsg.Group,strcat(grpName(2),'-',prdName(1))))';
corShamAfter = TBTsg.Cor(strcmp(TBTsg.Group,strcat(grpName(2),'-',prdName(2))))';
p.corLe = signrank(corLesBefore,corLesAfter);
p.corSh = signrank(corShamBefore,corShamAfter);
fprintf(strcat('Correct ',prdName(1),'-',prdName(2),' signrank test, Lesion p=%.3f, Sham p=%.3f\n'),p.corLe,p.corSh);
[~,p.corLeT] = ttest(corLesBefore,corLesAfter);
[~,p.corShT] = ttest(corShamBefore,corShamAfter);
fprintf(strcat('Correct ',prdName(1),'-',prdName(2),' paired-ttest test, Lesion p=%.3f, Sham p=%.3f\n'),p.corLeT,p.corShT);

preLesBefore = TBTsg.Pre(strcmp(TBTsg.Group,strcat(grpName(1),'-',prdName(1))))';
preLesAfter = TBTsg.Pre(strcmp(TBTsg.Group,strcat(grpName(1),'-',prdName(2))))';
preShamBefore = TBTsg.Pre(strcmp(TBTsg.Group,strcat(grpName(2),'-',prdName(1))))';
preShamAfter = TBTsg.Pre(strcmp(TBTsg.Group,strcat(grpName(2),'-',prdName(2))))';
p.preLe = signrank(preLesBefore,preLesAfter);
p.preSh = signrank(preShamBefore,preShamAfter);
fprintf('Premature Pre-Post signrank test, Lesion p=%.3f, Sham p=%.3f\n',p.preLe,p.preSh);
[~,p.preLeT] = ttest(preLesBefore,preLesAfter);
[~,p.preShT] = ttest(preShamBefore,preShamAfter);
fprintf('Premature Pre-Post paired-ttest test, Lesion p=%.3f, Sham p=%.3f\n',p.preLeT,p.preShT);

lateLesBefore = TBTsg.Late(strcmp(TBTsg.Group,strcat(grpName(1),'-',prdName(1))))';
lateLesAfter = TBTsg.Late(strcmp(TBTsg.Group,strcat(grpName(1),'-',prdName(2))))';
lateShamBefore = TBTsg.Late(strcmp(TBTsg.Group,strcat(grpName(2),'-',prdName(1))))';
lateShamAfter = TBTsg.Late(strcmp(TBTsg.Group,strcat(grpName(2),'-',prdName(2))))';
p.lateLe = signrank(lateLesBefore,lateLesAfter);
p.lateSh = signrank(lateShamBefore,lateShamAfter);
fprintf('Late Pre-Post signrank test, Lesion p=%.3f, Sham p=%.3f\n',p.lateLe,p.lateSh);
[~,p.lateLeT] = ttest(lateLesBefore,lateLesAfter);
[~,p.lateShT] = ttest(lateShamBefore,lateShamAfter);
fprintf('Late Pre-Post paired-ttest test, Lesion p=%.3f, Sham p=%.3f\n',p.lateLeT,p.lateShT);

% Late: 3FPs × Pre/Post friedman test in Lesion
lateSLesBefore = TBTsg.Late_S(strcmp(TBTsg.Group,'Lesion-Pre'))';
lateSLesAfter = TBTsg.Late_S(strcmp(TBTsg.Group,'Lesion-Post'))';
lateMLesBefore = TBTsg.Late_M(strcmp(TBTsg.Group,'Lesion-Pre'))';
lateMLesAfter = TBTsg.Late_M(strcmp(TBTsg.Group,'Lesion-Post'))';
lateLLesBefore = TBTsg.Late_L(strcmp(TBTsg.Group,'Lesion-Pre'))';
lateLLesAfter = TBTsg.Late_L(strcmp(TBTsg.Group,'Lesion-Post'))';
late3FPs = [lateSLesBefore',lateSLesAfter';...
    lateMLesBefore',lateMLesAfter';...
    lateLLesBefore',lateLLesAfter'];
[p.late3FPsLe,tb1,stats_late3FPs] = friedman(late3FPs,length(lateSLesBefore),'off');
% c = multcompare(stats_late3FPs);
fprintf('Late 3FPs×Pre/Post friedman test in Lesion, Pre/Post effect p=%.3f\n',p.late3FPsLe);

save('VarsToPlot.mat','TBT','TBTsg','TBTg','SBS','SBSbtw','SBSsg','xedges','p');
%% Plot
load('VarsToPlot.mat');

cTab20 = [0.0901960784313726,0.466666666666667,0.701960784313725;0.682352941176471,0.780392156862745,0.901960784313726;0.960784313725490,0.498039215686275,0.137254901960784;0.988235294117647,0.729411764705882,0.470588235294118;0.152941176470588,0.631372549019608,0.278431372549020;0.611764705882353,0.811764705882353,0.533333333333333;0.843137254901961,0.149019607843137,0.172549019607843;0.964705882352941,0.588235294117647,0.592156862745098;0.564705882352941,0.403921568627451,0.674509803921569;0.768627450980392,0.690196078431373,0.827450980392157;0.549019607843137,0.337254901960784,0.290196078431373;0.768627450980392,0.607843137254902,0.576470588235294;0.847058823529412,0.474509803921569,0.698039215686275;0.956862745098039,0.709803921568628,0.807843137254902;0.501960784313726,0.501960784313726,0.501960784313726;0.780392156862745,0.780392156862745,0.776470588235294;0.737254901960784,0.745098039215686,0.196078431372549;0.854901960784314,0.862745098039216,0.549019607843137;0.113725490196078,0.737254901960784,0.803921568627451;0.627450980392157,0.843137254901961,0.890196078431373];
cRed = cTab20(7,:);
cRed2 = cTab20(8,:);
cGreen = cTab20(5,:);
cGreen2 = cTab20(6,:);
cBlue = cTab20(1,:);
cBlue2 = cTab20(2,:);
cGray = cTab20(15,:);
cGray2 = cTab20(16,:);
cOrange = cTab20(3,:);
cOrange2 = cTab20(4,:);


hf = figure(44); clf(hf,'reset');
set(hf, 'name', 'Lesion effect', 'units', 'centimeters', 'position', [1 1 17 11.5],...
    'PaperPositionMode', 'auto','renderer','painter'); % 生科论文要求版面裁掉边距还剩，宽度15.8cm,高度24.2cm

size1 = [3.5,3.5*0.7];
size2 = [4*0.618,4*0.618];
size3 = [2.4,4*0.618];
size4 = [3.5 3.5*0.7];  
size5 = [3.5 3.5*0.7]; % compare performance
% ys = [1 5.2 8.8 12.5 16.3,20.2]; % yStart
ys = [1 8.8 5.2 12.5 16.3,20.2]; % yStart
xs1 = [1.5 6 11 15.5]; % xStart
xs2 = [1.5 6.3 11.2 16];
xs3 = [1 5.4 10.5 13.2];

% PLOT x:sessions, y:%, color:cor/pre/late, Lesion
ha11 = axes;
set(ha11, 'units', 'centimeters', 'position', [xs1(1) ys(1) size1], 'nextplot', 'add','tickDir', 'out',...
    'fontsize',7,'fontname','Arial','ticklength', [0.02 0.025]);
lenPre = length(sess_pre)+1;
lenPost = length(sess_post)-1;

shadedErrorBar(unique(SBSbtw.Session)-lenPre,SBSbtw.mean_Cor(SBSbtw.Group==grpName(1)),...
    SBSbtw.sem_Cor(SBSbtw.Group==grpName(1)),...
    'lineProps',{'o-','linewidth',1.5,'color',cGreen,'markerSize',4,'markerFaceColor',cGreen,'markerEdgeColor','none'});
shadedErrorBar(unique(SBSbtw.Session)-lenPre,SBSbtw.mean_Pre(SBSbtw.Group==grpName(1)),...
    SBSbtw.sem_Pre(SBSbtw.Group==grpName(1)),...
    'lineProps',{'o-','linewidth',1.5,'color',cRed,'markerSize',4,'markerFaceColor',cRed,'markerEdgeColor','none'});
shadedErrorBar(unique(SBSbtw.Session)-lenPre,SBSbtw.mean_Late(SBSbtw.Group==grpName(1)),...
    SBSbtw.sem_Late(SBSbtw.Group==grpName(1)),...
    'lineProps',{'o-','linewidth',1.5,'color',cGray,'markerSize',4,'markerFaceColor',cGray,'markerEdgeColor','none'});



plot([-0.5,-0.5],[0,1],'k','linewidth',0.6);
xlim([-lenPre+0.5,lenPost+0.5]);ylim([0,1]);
set(gca,'xtick',[-7,-5,-3,-1,0,2,4,6,8,10],'xticklabel',{'-7','-5','-3','-1','1','3','5','7','9','11'},...
    'ytick',0:0.5:1, 'yticklabel',{'0', '50', '100'});
xlabel('Sessions','Fontsize',8,'FontName','Arial');
ylabel('Percentage (%)','Fontsize',8,'FontName','Arial');
title(grpName(1),'Fontsize',9,'FontName','Arial');

le1 = legend({'Correct','Premature','Late'},'Fontsize',8,'fontname','Arial','units','centimeters',...
    'Position',[xs1(3)+size1(1)+0.7,ys(1)+1.4,1,1]);% [4.7,2.8,1,1]
le1.ItemTokenSize = [12,22];
le1.Position = le1.Position + [0.025 0.045 0 0];
legend('boxoff');

% PLOT x:sessions, y:%, color:cor/pre/late, Sham
ha12 = axes;
set(ha12, 'units', 'centimeters', 'position', [xs1(2) ys(1) size1], 'nextplot', 'add','tickDir', 'out',...
    'fontsize',7,'fontname','Arial','ytick',0:0.2:1,'yticklabel',{},'ticklength', [0.02 0.025]);
shadedErrorBar(unique(SBSbtw.Session)-lenPre,SBSbtw.mean_Cor(SBSbtw.Group==grpName(2)),...
    SBSbtw.sem_Cor(SBSbtw.Group==grpName(2)),...
    'lineProps',{'o-','linewidth',1.5,'color',cGreen,'markerSize',4,'markerFaceColor',cGreen,'markerEdgeColor','none'});
shadedErrorBar(unique(SBSbtw.Session)-lenPre,SBSbtw.mean_Pre(SBSbtw.Group==grpName(2)),...
    SBSbtw.sem_Pre(SBSbtw.Group==grpName(2)),...
    'lineProps',{'o-','linewidth',1.5,'color',cRed,'markerSize',4,'markerFaceColor',cRed,'markerEdgeColor','none'});
shadedErrorBar(unique(SBSbtw.Session)-lenPre,SBSbtw.mean_Late(SBSbtw.Group==grpName(2)),...
    SBSbtw.sem_Late(SBSbtw.Group==grpName(2)),...
    'lineProps',{'o-','linewidth',1.5,'color',cGray,'markerSize',4,'markerFaceColor',cGray,'markerEdgeColor','none'});
plot([-0.5,-0.5],[0,1],'k','linewidth',0.6);

xlim([-lenPre+0.5,lenPost+0.5]);ylim([0,1]);
set(gca,'xtick',[-7,-5,-3,-1,0,2,4,6,8,10],'xticklabel',{'-7','-5','-3','-1','1','3','5','7','9','11'},...
    'ytick',0:0.5:1, 'yticklabel',{'0', '50', '100'});
xlabel('Sessions','Fontsize',8,'FontName','Arial');
title(grpName(2),'Fontsize',9,'FontName','Arial');

% PLOT x:cor/pre/late * Pre/Post * Lesion/Sham, y:%, line&thickness: S/M/L
ha13 = axes;
set(ha13, 'units', 'centimeters', 'position', [xs1(3) ys(1) size5], 'nextplot', 'add','tickDir', 'out',...
    'xtick',[],'xticklabel',{},'xticklabelRotation',-45,'fontsize',7,'fontname','Arial',...
    'ytick',0:0.5:1,'yticklabel',{'0','50','100'},'xlim', [0 7.5],'ylim', [0 1]);
% 'xtick',[1.25,3.25,5.75,7.75,10.25,12.25]
% Lesion: Correct Premature Late
hl1 = plot([0.5 1.25],[TBTg.mean_Cor_S(TBTg.Group==grpName(1)+"-"+prdName(1)),TBTg.mean_Cor_S(TBTg.Group==grpName(1)+"-"+prdName(2))],'-','lineWidth',0.6,'color',cGreen,'markersize',4,'markerFaceColor',cGreen,'markerEdgeColor','none');
hl2 = plot([0.5 1.25],[TBTg.mean_Cor_M(TBTg.Group==grpName(1)+"-"+prdName(1)),TBTg.mean_Cor_M(TBTg.Group==grpName(1)+"-"+prdName(2))],'-','lineWidth',1,'color',cGreen,'markersize',4,'markerFaceColor',cGreen,'markerEdgeColor','none');
hl3 = plot([0.5 1.25],[TBTg.mean_Cor_L(TBTg.Group==grpName(1)+"-"+prdName(1)),TBTg.mean_Cor_L(TBTg.Group==grpName(1)+"-"+prdName(2))],'-','lineWidth',1.5,'color',cGreen,'markersize',4,'markerFaceColor',cGreen,'markerEdgeColor','none');

plot([1.5 2.25],[TBTg.mean_Pre_S(TBTg.Group==grpName(1)+"-"+prdName(1)),TBTg.mean_Pre_S(TBTg.Group==grpName(1)+"-"+prdName(2))],'-','lineWidth',0.6,'color',cRed,'markersize',4,'markerFaceColor',cRed,'markerEdgeColor','none');
plot([1.5 2.25],[TBTg.mean_Pre_M(TBTg.Group==grpName(1)+"-"+prdName(1)),TBTg.mean_Pre_M(TBTg.Group==grpName(1)+"-"+prdName(2))],'-','lineWidth',1,'color',cRed,'markersize',4,'markerFaceColor',cRed,'markerEdgeColor','none');
plot([1.5 2.25],[TBTg.mean_Pre_L(TBTg.Group==grpName(1)+"-"+prdName(1)),TBTg.mean_Pre_L(TBTg.Group==grpName(1)+"-"+prdName(2))],'-','lineWidth',1.5,'color',cRed,'markersize',4,'markerFaceColor',cRed,'markerEdgeColor','none');

plot([2.5 3.25],[TBTg.mean_Late_S(TBTg.Group==grpName(1)+"-"+prdName(1)),TBTg.mean_Late_S(TBTg.Group==grpName(1)+"-"+prdName(2))],'-','lineWidth',0.6,'color',cGray,'markersize',4,'markerFaceColor',cGray,'markerEdgeColor','none');
plot([2.5 3.25],[TBTg.mean_Late_M(TBTg.Group==grpName(1)+"-"+prdName(1)),TBTg.mean_Late_M(TBTg.Group==grpName(1)+"-"+prdName(2))],'-','lineWidth',1,'color',cGray,'markersize',4,'markerFaceColor',cGray,'markerEdgeColor','none');
plot([2.5 3.25],[TBTg.mean_Late_L(TBTg.Group==grpName(1)+"-"+prdName(1)),TBTg.mean_Late_L(TBTg.Group==grpName(1)+"-"+prdName(2))],'-','lineWidth',1.5,'color',cGray,'markersize',4,'markerFaceColor',cGray,'markerEdgeColor','none');
% Sham
plot([4.25 5],[TBTg.mean_Cor_S(TBTg.Group==grpName(2)+"-"+prdName(1)),TBTg.mean_Cor_S(TBTg.Group==grpName(2)+"-"+prdName(2))],'-','lineWidth',0.6,'color',cGreen,'markersize',4,'markerFaceColor',cGreen,'markerEdgeColor','none');
plot([4.25 5],[TBTg.mean_Cor_M(TBTg.Group==grpName(2)+"-"+prdName(1)),TBTg.mean_Cor_M(TBTg.Group==grpName(2)+"-"+prdName(2))],'-','lineWidth',1,'color',cGreen,'markersize',4,'markerFaceColor',cGreen,'markerEdgeColor','none');
plot([4.25 5],[TBTg.mean_Cor_L(TBTg.Group==grpName(2)+"-"+prdName(1)),TBTg.mean_Cor_L(TBTg.Group==grpName(2)+"-"+prdName(2))],'-','lineWidth',1.5,'color',cGreen,'markersize',4,'markerFaceColor',cGreen,'markerEdgeColor','none');

plot([5.25 6],[TBTg.mean_Pre_S(TBTg.Group==grpName(2)+"-"+prdName(1)),TBTg.mean_Pre_S(TBTg.Group==grpName(2)+"-"+prdName(2))],'-','lineWidth',0.6,'color',cRed,'markersize',4,'markerFaceColor',cRed,'markerEdgeColor','none');
plot([5.25 6],[TBTg.mean_Pre_M(TBTg.Group==grpName(2)+"-"+prdName(1)),TBTg.mean_Pre_M(TBTg.Group==grpName(2)+"-"+prdName(2))],'-','lineWidth',1,'color',cRed,'markersize',4,'markerFaceColor',cRed,'markerEdgeColor','none');
plot([5.25 6],[TBTg.mean_Pre_L(TBTg.Group==grpName(2)+"-"+prdName(1)),TBTg.mean_Pre_L(TBTg.Group==grpName(2)+"-"+prdName(2))],'-','lineWidth',1.5,'color',cRed,'markersize',4,'markerFaceColor',cRed,'markerEdgeColor','none');

plot([6.25 7],[TBTg.mean_Late_S(TBTg.Group==grpName(2)+"-"+prdName(1)),TBTg.mean_Late_S(TBTg.Group==grpName(2)+"-"+prdName(2))],'-','lineWidth',0.6,'color',cGray,'markersize',4,'markerFaceColor',cGray,'markerEdgeColor','none');
plot([6.25 7],[TBTg.mean_Late_M(TBTg.Group==grpName(2)+"-"+prdName(1)),TBTg.mean_Late_M(TBTg.Group==grpName(2)+"-"+prdName(2))],'-','lineWidth',1,'color',cGray,'markersize',4,'markerFaceColor',cGray,'markerEdgeColor','none');
plot([6.25 7],[TBTg.mean_Late_L(TBTg.Group==grpName(2)+"-"+prdName(1)),TBTg.mean_Late_L(TBTg.Group==grpName(2)+"-"+prdName(2))],'-','lineWidth',1.5,'color',cGray,'markersize',4,'markerFaceColor',cGray,'markerEdgeColor','none');

grpAbbr = cellstr(grpName);
text([1.875,5.625],repelem(-0.125,2),grpAbbr,'HorizontalAlignment','center','fontsize',8,'FontName','Arial');
ylabel('Percentage (%)','Fontsize',8,'FontName','Arial');
% title('Pre vs. Post','Fontsize',9,'FontName','Arial');

le3 = legend([hl1,hl2,hl3],{'FP 0.5 s','FP 1.0 s','FP 1.5 s'},...
    'Fontsize',8,'FontName','Arial','units','centimeters',...
    'Position',[xs1(3)+size1(1)+0.55,ys(1)+0.1,1,1]); % [10.7,8.9,1,1]
legend('boxoff');
le3.ItemTokenSize = [12,22];
le3.Position = le3.Position + [0.025 0.045 0 0];


% PLOT LesionGroup, RelT distribution, legend: Pre/Post
ha21 = axes;
thisGroup = 1;
set(ha21, 'units', 'centimeters', 'position', [xs2(1) ys(2) size1], 'nextplot', 'add','tickDir', 'out',...
    'xlim',[xedges.edges_RelT(1),xedges.edges_RelT(end)],'xtick',[xedges.edges_RelT(1):0.25:xedges.edges_RelT(end)],...
    'xticklabel',cellstr(string((xedges.edges_RelT(1):0.25:xedges.edges_RelT(end))*1000)),'fontsize',7,'fontname','Arial',...
    'ylim',[0 0.17],'ytick', [0:0.05:0.15], 'yticklabel', {'0', '5', '10', '15'}, 'ticklength', [0.02 0.025]);
fill([0,0.6,0.6,0],[0,0,1,1],cGreen,'EdgeColor','none','FaceAlpha',0.25);
f41 = shadedErrorBar(xedges.RelT,TBTg.mean_RelTdist(TBTg.Group==grpName(thisGroup)+"-"+prdName(1),:),...
    TBTg.sem_RelTdist(TBTg.Group==grpName(thisGroup)+"-"+prdName(1),:),...
    'lineProps',{'-','lineWidth',1.5,'color','k'},'patchSaturation',0.2);
f42 = shadedErrorBar(xedges.RelT,TBTg.mean_RelTdist(TBTg.Group==grpName(thisGroup)+"-"+prdName(2),:),...
    TBTg.sem_RelTdist(TBTg.Group==grpName(thisGroup)+"-"+prdName(2),:),...
    'lineProps',{'-','lineWidth',1.5,'color',cOrange},'patchSaturation',0.2);
xlabel('Reaction time (ms)','Fontsize',8,'FontName','Arial');
ylabel('Probability (%)','Fontsize',8,'FontName','Arial');
% title(grpName(1),'Fontsize',9,'FontName','Arial');

% PLOT LesionGroup, RelT distribution CDF, Pre/Post
ha22 = axes;
thisGroup = 1;
set(ha22, 'units', 'centimeters', 'position', [xs2(2) ys(2) size1], 'nextplot', 'add','tickDir', 'out',...
    'xlim',[xedges.edges_RelT(1),xedges.edges_RelT(end)],'xtick',[xedges.edges_RelT(1):0.25:xedges.edges_RelT(end)],...
    'xticklabel',cellstr(string((xedges.edges_RelT(1):0.25:xedges.edges_RelT(end))*1000)),'fontsize',7,'fontname','Arial',...
    'ylim',[0 1],'ytick', [0:0.25:1], 'yticklabel', {'0', '25', '50', '75','100'}, 'ticklength', [0.02 0.025]);
fill([0,0.6,0.6,0],[0,0,1,1],cGreen,'EdgeColor','none','FaceAlpha',0.25);
f41 = shadedErrorBar(xedges.RelT,TBTg.mean_RelTdist_CDF(TBTg.Group==grpName(thisGroup)+"-"+prdName(1),:),...
    TBTg.sem_RelTdist_CDF(TBTg.Group==grpName(thisGroup)+"-"+prdName(1),:),...
    'lineProps',{'-','lineWidth',1.5,'color','k'},'patchSaturation',0.2);
f42 = shadedErrorBar(xedges.RelT,TBTg.mean_RelTdist_CDF(TBTg.Group==grpName(thisGroup)+"-"+prdName(2),:),...
    TBTg.sem_RelTdist_CDF(TBTg.Group==grpName(thisGroup)+"-"+prdName(2),:),...
    'lineProps',{'-','lineWidth',1.5,'color',cOrange},'patchSaturation',0.2);
xlabel('Reaction time (ms)','Fontsize',8,'FontName','Arial');
ylabel('CDF (%)','Fontsize',8,'FontName','Arial');
% title(grpName(1),'Fontsize',9,'FontName','Arial');

% PLOT LesionGroup, 3FPs-RelT, Pre/Post
% S
thisGroup = 1;
RelTMedPreMean(1) = TBTg.mean_RelT_S(TBTg.Group==grpName(thisGroup)+"-"+prdName(1));
RelTMedPreSEM(1) = TBTg.sem_RelT_S(TBTg.Group==grpName(thisGroup)+"-"+prdName(1));
RelTMedPostMean(1) = TBTg.mean_RelT_S(TBTg.Group==grpName(thisGroup)+"-"+prdName(2));
RelTMedPostSEM(1) = TBTg.sem_RelT_S(TBTg.Group==grpName(thisGroup)+"-"+prdName(2));
% M
RelTMedPreMean(2) = TBTg.mean_RelT_M(TBTg.Group==grpName(thisGroup)+"-"+prdName(1));
RelTMedPreSEM(2) = TBTg.sem_RelT_M(TBTg.Group==grpName(thisGroup)+"-"+prdName(1));
RelTMedPostMean(2) = TBTg.mean_RelT_M(TBTg.Group==grpName(thisGroup)+"-"+prdName(2));
RelTMedPostSEM(2) = TBTg.sem_RelT_M(TBTg.Group==grpName(thisGroup)+"-"+prdName(2));
% L
RelTMedPreMean(3) = TBTg.mean_RelT_L(TBTg.Group==grpName(thisGroup)+"-"+prdName(1));
RelTMedPreSEM(3) = TBTg.sem_RelT_L(TBTg.Group==grpName(thisGroup)+"-"+prdName(1));
RelTMedPostMean(3) = TBTg.mean_RelT_L(TBTg.Group==grpName(thisGroup)+"-"+prdName(2));
RelTMedPostSEM(3) = TBTg.sem_RelT_L(TBTg.Group==grpName(thisGroup)+"-"+prdName(2));
% plot
ha23 = axes;
set(ha23, 'units', 'centimeters', 'position', [xs2(3) ys(2) size1], 'nextplot', 'add','tickDir', 'out',...
    'xlim',[fplist(1)-0.25,fplist(end)+0.25],'xtick',fplist,'xticklabel',cellstr(string(fplist.*1000)),'fontsize',7, ...
    'ylim',[0.2 0.9],'ytick',0.2:0.2:0.8,'yticklabels',{'200','400','600','800'},'ticklength', [0.02 0.025]);
plot(fplist, RelTMedPreMean, 'o-', 'linewidth', 1, 'color', 'k', 'markerfacecolor', 'k', 'markeredgecolor','w', 'markersize', 5)
line([fplist; fplist], [RelTMedPreMean-RelTMedPreSEM; RelTMedPreMean+RelTMedPreSEM], ...
    'color','k', 'linewidth', 1)

plot(fplist, RelTMedPostMean, 'o-', 'linewidth', 1, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5)
line([fplist; fplist], [RelTMedPostMean-RelTMedPostSEM; RelTMedPostMean+RelTMedPostSEM], ...
    'color',cOrange, 'linewidth', 1)

xlabel('Foreperiod (ms)','Fontsize',8,'FontName','Arial')
ylabel('Reaction time (ms)','Fontsize',8,'FontName','Arial')

xlm = xlim; xsep = (xlm(2)-xlm(1))./15; xtext = xlm(2)+xsep;
ylm = ylim; ysep = (ylm(2)-ylm(1))./5; ytext = mean(ylm)+ysep;
text(xtext,ytext,grpName(thisGroup),...
    'HorizontalAlignment','left','VerticalAlignment','middle','rotation',-90,...
    'fontsize',8,'FontName','Arial','fontweight','bold');


% PLOT ShamGroup, RelT distribution, legend: Pre/Post
ha31 = axes;
thisGroup = 2;
set(ha31, 'units', 'centimeters', 'position', [xs2(1) ys(3) size1], 'nextplot', 'add','tickDir', 'out',...
    'xlim',[xedges.edges_RelT(1),xedges.edges_RelT(end)],'xtick',[xedges.edges_RelT(1):0.25:xedges.edges_RelT(end)],...
    'xticklabel',cellstr(string((xedges.edges_RelT(1):0.25:xedges.edges_RelT(end))*1000)),'fontsize',7,'fontname','Arial',...
    'ylim',[0 0.17],'ytick', [0:0.05:0.15], 'yticklabel', {'0', '5', '10', '15'}, 'ticklength', [0.02 0.025]);
fill([0,0.6,0.6,0],[0,0,1,1],cGreen,'EdgeColor','none','FaceAlpha',0.25);
f41 = shadedErrorBar(xedges.RelT,TBTg.mean_RelTdist(TBTg.Group==grpName(thisGroup)+"-"+prdName(1),:),...
    TBTg.sem_RelTdist(TBTg.Group==grpName(thisGroup)+"-"+prdName(1),:),...
    'lineProps',{'-','lineWidth',1.5,'color','k'},'patchSaturation',0.2);
f42 = shadedErrorBar(xedges.RelT,TBTg.mean_RelTdist(TBTg.Group==grpName(thisGroup)+"-"+prdName(2),:),...
    TBTg.sem_RelTdist(TBTg.Group==grpName(thisGroup)+"-"+prdName(2),:),...
    'lineProps',{'-','lineWidth',1.5,'color',cOrange},'patchSaturation',0.2);
xlabel('Reaction time (ms)','Fontsize',8,'FontName','Arial');
ylabel('Probability (%)','Fontsize',8,'FontName','Arial');
% title(grpName(1),'Fontsize',9,'FontName','Arial');

% PLOT ShamGroup, RelT distribution CDF, Pre/Post
ha32 = axes;
thisGroup = 2;
set(ha32, 'units', 'centimeters', 'position', [xs2(2) ys(3) size1], 'nextplot', 'add','tickDir', 'out',...
    'xlim',[xedges.edges_RelT(1),xedges.edges_RelT(end)],'xtick',[xedges.edges_RelT(1):0.25:xedges.edges_RelT(end)],...
    'xticklabel',cellstr(string((xedges.edges_RelT(1):0.25:xedges.edges_RelT(end))*1000)),'fontsize',7,'fontname','Arial',...
    'ylim',[0 1],'ytick', [0:0.25:1], 'yticklabel', {'0', '25', '50', '75','100'}, 'ticklength', [0.02 0.025]);
fill([0,0.6,0.6,0],[0,0,1,1],cGreen,'EdgeColor','none','FaceAlpha',0.25);
f41 = shadedErrorBar(xedges.RelT,TBTg.mean_RelTdist_CDF(TBTg.Group==grpName(thisGroup)+"-"+prdName(1),:),...
    TBTg.sem_RelTdist_CDF(TBTg.Group==grpName(thisGroup)+"-"+prdName(1),:),...
    'lineProps',{'-','lineWidth',1.5,'color','k'},'patchSaturation',0.2);
f42 = shadedErrorBar(xedges.RelT,TBTg.mean_RelTdist_CDF(TBTg.Group==grpName(thisGroup)+"-"+prdName(2),:),...
    TBTg.sem_RelTdist_CDF(TBTg.Group==grpName(thisGroup)+"-"+prdName(2),:),...
    'lineProps',{'-','lineWidth',1.5,'color',cOrange},'patchSaturation',0.2);
xlabel('Reaction time (ms)','Fontsize',8,'FontName','Arial');
ylabel('CDF (%)','Fontsize',8,'FontName','Arial');
% title(grpName(1),'Fontsize',9,'FontName','Arial');

% PLOT ShamGroup, 3FPs-RelT, Pre/Post
% S
thisGroup = 2;
RelTMedPreMean(1) = TBTg.mean_RelT_S(TBTg.Group==grpName(thisGroup)+"-"+prdName(1));
RelTMedPreSEM(1) = TBTg.sem_RelT_S(TBTg.Group==grpName(thisGroup)+"-"+prdName(1));
RelTMedPostMean(1) = TBTg.mean_RelT_S(TBTg.Group==grpName(thisGroup)+"-"+prdName(2));
RelTMedPostSEM(1) = TBTg.sem_RelT_S(TBTg.Group==grpName(thisGroup)+"-"+prdName(2));
% M
RelTMedPreMean(2) = TBTg.mean_RelT_M(TBTg.Group==grpName(thisGroup)+"-"+prdName(1));
RelTMedPreSEM(2) = TBTg.sem_RelT_M(TBTg.Group==grpName(thisGroup)+"-"+prdName(1));
RelTMedPostMean(2) = TBTg.mean_RelT_M(TBTg.Group==grpName(thisGroup)+"-"+prdName(2));
RelTMedPostSEM(2) = TBTg.sem_RelT_M(TBTg.Group==grpName(thisGroup)+"-"+prdName(2));
% L
RelTMedPreMean(3) = TBTg.mean_RelT_L(TBTg.Group==grpName(thisGroup)+"-"+prdName(1));
RelTMedPreSEM(3) = TBTg.sem_RelT_L(TBTg.Group==grpName(thisGroup)+"-"+prdName(1));
RelTMedPostMean(3) = TBTg.mean_RelT_L(TBTg.Group==grpName(thisGroup)+"-"+prdName(2));
RelTMedPostSEM(3) = TBTg.sem_RelT_L(TBTg.Group==grpName(thisGroup)+"-"+prdName(2));
% plot
ha33 = axes;
set(ha33, 'units', 'centimeters', 'position', [xs2(3) ys(3) size1], 'nextplot', 'add','tickDir', 'out',...
    'xlim',[fplist(1)-0.25,fplist(end)+0.25],'xtick',fplist,'xticklabel',cellstr(string(fplist.*1000)),'fontsize',7, ...
    'ylim',[0.2 0.9],'ytick',0.2:0.2:0.8,'yticklabels',{'200','400','600','800'},'ticklength', [0.02 0.025]);
lpre = plot(fplist, RelTMedPreMean, 'o-', 'linewidth', 1, 'color', 'k', 'markerfacecolor', 'k', 'markeredgecolor','w', 'markersize', 5);
line([fplist; fplist], [RelTMedPreMean-RelTMedPreSEM; RelTMedPreMean+RelTMedPreSEM], ...
    'color','k', 'linewidth', 1)
lpost = plot(fplist, RelTMedPostMean, 'o-', 'linewidth', 1, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
line([fplist; fplist], [RelTMedPostMean-RelTMedPostSEM; RelTMedPostMean+RelTMedPostSEM], ...
    'color',cOrange, 'linewidth', 1)
xlabel('Foreperiod (ms)','Fontsize',8,'FontName','Arial')
ylabel('Reaction time (ms)','Fontsize',8,'FontName','Arial')

xlm = xlim; xsep = (xlm(2)-xlm(1))./15; xtext = xlm(2)+xsep;
ylm = ylim; ysep = (ylm(2)-ylm(1))./5; ytext = mean(ylm)+ysep;
text(xtext,ytext,grpName(thisGroup),...
    'HorizontalAlignment','left','VerticalAlignment','middle','rotation',-90,...
    'fontsize',8,'FontName','Arial','fontweight','bold');

le6 = legend([lpre,lpost],cellstr(prdName),...
    'Fontsize',8,'FontName','Arial','units','centimeters',...
    'Position',[xs2(3)+size1(1)+0.6,ys(3)-0.2,1,1]); % [10.7,8.9,1,1]
legend('boxoff');
le6.ItemTokenSize = [12,22];
le6.Position = le6.Position + [0.025 0.045 0 0];


% Subject grouping information
grp1Sbj = unique(SBS(cellfun(@(x) ~isempty(x),strfind(SBS.Group,grpName(1))),:).Subject,'stable');
grp2Sbj = unique(SBS(cellfun(@(x) ~isempty(x),strfind(SBS.Group,grpName(2))),:).Subject,'stable');

haSbj = axes('units', 'centimeters', 'position', [17 ys(1) 2.642 size1(2)],'Visible','off');
text(haSbj,0,1,[upper(grpName(1)),grp1Sbj'],'fontsize',6,'VerticalAlignment','top');
text(haSbj,0.5,1,[upper(grpName(2)),grp2Sbj'],'fontsize',6,'VerticalAlignment','top');

% % PLOT LesionGroup, HT distribution, legend: S/M/L * Pre/Post
% ha31 = axes;
% set(ha31, 'units', 'centimeters', 'position', [xs3(1) ys(3) size1], 'nextplot', 'add','tickDir', 'out',...
%     'xlim',[xedges.edges_HT(1),xedges.edges_HT(end)],'xtick',[xedges.edges_RelT(1):0.5:xedges.edges_RelT(end)],...
%     'xticklabel',cellstr(string((xedges.edges_RelT(1):0.5:xedges.edges_RelT(end))*1000)),...
%     'fontsize',7,'fontname','Arial','ylim',[0 0.2]);
% fill([0.5,1.1,1.1,0.5],[0,0,1,1],[0.8,0.8,0.8],'EdgeColor','none','FaceAlpha',0.3);
% fill([1.0,1.6,1.6,1.0],[0,0,1,1],[0.8,0.8,0.8],'EdgeColor','none','FaceAlpha',0.4);
% fill([1.5,2.1,2.1,1.5],[0,0,1,1],[0.8,0.8,0.8],'EdgeColor','none','FaceAlpha',0.5);
% shadedErrorBar(xedges.HT,TBTg.mean_HTdist_S(TBTg.Group==grpName(1)+"-"+"Pre",:),...
%     TBTg.sem_HTdist_S(TBTg.Group==grpName(1)+"-"+"Pre",:),...
%     'lineProps',{':','lineWidth',2,'color',cGray},'patchSaturation',0.1);
% shadedErrorBar(xedges.HT,TBTg.mean_HTdist_M(TBTg.Group==grpName(1)+"-"+"Pre",:),...
%     TBTg.sem_HTdist_M(TBTg.Group==grpName(1)+"-"+"Pre",:),...
%     'lineProps',{'--','lineWidth',1.7,'color',cGray},'patchSaturation',0.1);
% h71 = shadedErrorBar(xedges.HT,TBTg.mean_HTdist_L(TBTg.Group==grpName(1)+"-"+"Pre",:),...
%     TBTg.sem_HTdist_L(TBTg.Group==grpName(1)+"-"+"Pre",:),...
%      'lineProps',{'-','lineWidth',1.5,'color',cGray},'patchSaturation',0.1);
% shadedErrorBar(xedges.HT,TBTg.mean_HTdist_S(TBTg.Group==grpName(1)+"-"+"Post",:),...
%     TBTg.sem_HTdist_S(TBTg.Group==grpName(1)+"-"+"Post",:),...
%     'lineProps',{':','lineWidth',2,'color',cOrange},'patchSaturation',0.1);
% shadedErrorBar(xedges.HT,TBTg.mean_HTdist_M(TBTg.Group==grpName(1)+"-"+"Post",:),...
%     TBTg.sem_HTdist_M(TBTg.Group==grpName(1)+"-"+"Post",:),...
%     'lineProps',{'--','lineWidth',1.7,'color',cOrange},'patchSaturation',0.1);
% h72 = shadedErrorBar(xedges.HT,TBTg.mean_HTdist_L(TBTg.Group==grpName(1)+"-"+"Post",:),...
%     TBTg.sem_HTdist_L(TBTg.Group==grpName(1)+"-"+"Post",:),...
%     'lineProps',{'-','lineWidth',1.5,'color',cOrange},'patchSaturation',0.1);
% xlabel('Press duration (ms)','Fontsize',8,'FontName','Arial');
% ylabel('Probability','Fontsize',8,'FontName','Arial');
% title(grpName(1),'Fontsize',9,'FontName','Arial');
% 
% h71 = h71.mainLine; h72 = h72.mainLine;
% le7 = legend([h71 h72],{'Pre','Post'},'fontsize',8,'FontName','Arial','units','centimeter',...
%     'Position',[xs3(3)+size2(1)+0.36,ys(3)+1.6,1,1]); % [10.5,10.2,1,1]
% legend('boxoff');
% le7.ItemTokenSize = [12,22];
% le7.Position = le7.Position + [0.025 0.045 0 0];

% % PLOT ShamGroup, HT distribution, legend: S/M/L * Pre/Post
% ha32 = axes;
% set(ha32, 'units', 'centimeters', 'position', [xs3(2) ys(3) size1], 'nextplot', 'add','tickDir', 'out',...
%     'xlim',[xedges.edges_HT(1),xedges.edges_HT(end)],'xtick',[xedges.edges_RelT(1):0.5:xedges.edges_RelT(end)],...
%     'xticklabel',cellstr(string((xedges.edges_RelT(1):0.5:xedges.edges_RelT(end))*1000)),...
%     'fontsize',7,'fontname','Arial','ylim',[0 0.2],'yticklabel',{});
% fill([0.5,1.1,1.1,0.5],[0,0,1,1],[0.8,0.8,0.8],'EdgeColor','none','FaceAlpha',0.3);
% fill([1.0,1.6,1.6,1.0],[0,0,1,1],[0.8,0.8,0.8],'EdgeColor','none','FaceAlpha',0.4);
% fill([1.5,2.1,2.1,1.5],[0,0,1,1],[0.8,0.8,0.8],'EdgeColor','none','FaceAlpha',0.5);
% shadedErrorBar(xedges.HT,TBTg.mean_HTdist_S(TBTg.Group==grpName(2)+"-"+"Pre",:),...
%     TBTg.sem_HTdist_S(TBTg.Group==grpName(2)+"-"+"Pre",:),...
%     'lineProps',{':','lineWidth',2,'color',cGray},'patchSaturation',0.1);
% shadedErrorBar(xedges.HT,TBTg.mean_HTdist_M(TBTg.Group==grpName(2)+"-"+"Pre",:),...
%     TBTg.sem_HTdist_M(TBTg.Group==grpName(2)+"-"+"Pre",:),...
%     'lineProps',{'--','lineWidth',1.7,'color',cGray},'patchSaturation',0.1);
% shadedErrorBar(xedges.HT,TBTg.mean_HTdist_L(TBTg.Group==grpName(2)+"-"+"Pre",:),...
%     TBTg.sem_HTdist_L(TBTg.Group==grpName(2)+"-"+"Pre",:),...
%      'lineProps',{'-','lineWidth',1.5,'color',cGray},'patchSaturation',0.1);
% shadedErrorBar(xedges.HT,TBTg.mean_HTdist_S(TBTg.Group==grpName(2)+"-"+"Post",:),...
%     TBTg.sem_HTdist_S(TBTg.Group==grpName(2)+"-"+"Post",:),...
%     'lineProps',{':','lineWidth',2,'color',cOrange},'patchSaturation',0.1);
% shadedErrorBar(xedges.HT,TBTg.mean_HTdist_M(TBTg.Group==grpName(2)+"-"+"Post",:),...
%     TBTg.sem_HTdist_M(TBTg.Group==grpName(2)+"-"+"Post",:),...
%     'lineProps',{'--','lineWidth',1.7,'color',cOrange},'patchSaturation',0.1);
% shadedErrorBar(xedges.HT,TBTg.mean_HTdist_L(TBTg.Group==grpName(2)+"-"+"Post",:),...
%     TBTg.sem_HTdist_L(TBTg.Group==grpName(2)+"-"+"Post",:),...
%     'lineProps',{'-','lineWidth',1.5,'color',cOrange},'patchSaturation',0.1);
% xlabel('Press duration (ms)','Fontsize',8,'FontName','Arial');
% % ylabel('Probability','Fontsize',8,'FontName','Arial');
% title(grpName(2),'Fontsize',9,'FontName','Arial');
% 
% % PLOT x:RT-Pre, y:RT-Post, marker:Lesion/Sham, each point a subjects
% ha33 = axes;
% set(ha33, 'units', 'centimeters', 'position', [xs3(3) ys(3) size2], 'nextplot', 'add','tickDir', 'out',...
%    'fontsize',7,'fontname','Arial','xlim',[0.17 0.43],'ylim',[0.17 0.43],'xtick',[0.2,0.3,0.4],'xticklabel',{'200','300','400'},...
%    'ytick',[0.2,0.3,0.4],'yticklabel',{'200','300','400'}); %
% plot([0,0.6],[0,0.6],':k','lineWidth',0.6)
% % errorbar comes from different sessions of one subject
% % h61 = errorbar(SBSsg.mean_RT(SBSsg.Group==grpName(1)+"-"+"Pre"),SBSsg.mean_RT(SBSsg.Group==grpName(1)+"-"+"Post"),...
% %     SBSsg.sem_RT(SBSsg.Group==grpName(1)+"-"+"Post"),SBSsg.sem_RT(SBSsg.Group==grpName(1)+"-"+"Post"),...
% %     SBSsg.sem_RT(SBSsg.Group==grpName(1)+"-"+"Pre"),SBSsg.sem_RT(SBSsg.Group==grpName(1)+"-"+"Pre"),...
% %     '.','MarkerSize',12,'MarkerEdgeColor',cBlue,'color',cBlue,'lineWidth',1,'CapSize',3);
% % h62 = errorbar(SBSsg.mean_RT(SBSsg.Group==grpName(2)+"-"+"Pre"),SBSsg.mean_RT(SBSsg.Group==grpName(2)+"-"+"Post"),...
% %     SBSsg.sem_RT(SBSsg.Group==grpName(2)+"-"+"Post"),SBSsg.sem_RT(SBSsg.Group==grpName(2)+"-"+"Post"),...
% %     SBSsg.sem_RT(SBSsg.Group==grpName(2)+"-"+"Pre"),SBSsg.sem_RT(SBSsg.Group==grpName(2)+"-"+"Pre"),...
% %     '.','MarkerSize',12,'MarkerEdgeColor',cGray,'color',cGray,'lineWidth',1,'CapSize',3);
% % RT_CI1 = TBTsg.RT_CI(:,1); RT_CI2 = TBTsg.RT_CI(:,2); % errorbar comes from different trials of one subject
% RT_CI1 = TBTsg.RT_SE(:,1); RT_CI2 = TBTsg.RT_SE(:,2); % errorbar comes from different trials of one subject
% h61 = errorbar(TBTsg.RT(TBTsg.Group==grpName(1)+"-"+"Pre"),TBTsg.RT(TBTsg.Group==grpName(1)+"-"+"Post"),...
%     RT_CI1(TBTsg.Group==grpName(1)+"-"+"Post"),RT_CI2(TBTsg.Group==grpName(1)+"-"+"Post"),...
%     RT_CI1(TBTsg.Group==grpName(1)+"-"+"Pre"),RT_CI2(TBTsg.Group==grpName(1)+"-"+"Pre"),...
%     '.','MarkerSize',12,'MarkerEdgeColor',cBlue,'color',cBlue,'lineWidth',1,'CapSize',3);
% h62 = errorbar(TBTsg.RT(TBTsg.Group==grpName(2)+"-"+"Pre"),TBTsg.RT(TBTsg.Group==grpName(2)+"-"+"Post"),...
%     RT_CI1(TBTsg.Group==grpName(2)+"-"+"Post"),RT_CI2(TBTsg.Group==grpName(2)+"-"+"Post"),...
%     RT_CI1(TBTsg.Group==grpName(2)+"-"+"Pre"),RT_CI2(TBTsg.Group==grpName(2)+"-"+"Pre"),...
%     '.','MarkerSize',12,'MarkerEdgeColor',cGray,'color',cGray,'lineWidth',1,'CapSize',3);
% xlabel('Pre RT (ms)','Fontsize',8,'FontName','Arial');
% ylabel('Post RT (ms)','Fontsize',8,'FontName','Arial');
% 
% le6 = legend([h61,h62],{grpName(1),grpName(2)},'Fontsize',8,'FontName','Arial','units','centimeters',...
%     'Position',[xs3(3)+size2(1)+0.44,ys(3)-0.7,1,1]); % [14,6.4,1,1]
% legend('boxoff');
% le6.ItemTokenSize = [15,25];
% le6.Position = le6.Position + [0.025 0.045 0 0];

% % PLOT Cor pre vs. post (Bar Plot)
% ha21 = axes;
% set(ha21, 'units', 'centimeters', 'position', [xs2(1) ys(2) size2], 'nextplot', 'add','tickDir', 'out',...
%     'fontsize',7,'fontname','Arial', 'ylim',[0.2 1]);
% bh21 = bar(1:2,... % categorical({'Lesion','Sham'})
%     [TBTg.mean_Cor(strcmp(TBTg.Group,'Lesion-Pre')),TBTg.mean_Cor(strcmp(TBTg.Group,'Lesion-Post'));...
%     TBTg.mean_Cor(strcmp(TBTg.Group,'Sham-Pre')),TBTg.mean_Cor(strcmp(TBTg.Group,'Sham-Post'))],...
%     'FaceColor','flat','EdgeColor','none');
% xtips1 = bh21(1).XEndPoints;
% xtips2 = bh21(2).XEndPoints;
% ytips1 = bh21(1).YEndPoints;
% ytips2 = bh21(2).YEndPoints;
% errorbar(xtips1,ytips1,...
%     [TBTg.sem_Cor(strcmp(TBTg.Group,'Lesion-Pre')),TBTg.sem_Cor(strcmp(TBTg.Group,'Sham-Pre'))],...
%     '.k','capsize',3,'lineWidth',0.7);
% errorbar(xtips2,ytips2,...
%     [TBTg.sem_Cor(strcmp(TBTg.Group,'Lesion-Post')),TBTg.sem_Cor(strcmp(TBTg.Group,'Sham-Post'))],...
%     '.k','capsize',3,'lineWidth',0.7);
% ylm = ylim;ysep = (ylm(2)-ylm(1))/15;yline = ylm(2)-ysep*2; ysym = ylm(2)-ysep;
% plot([xtips1(1),xtips2(1)],[yline yline],'-k','lineWidth',0.7);
% plot([xtips1(2),xtips2(2)],[yline yline],'-k','lineWidth',0.7);
% text(1,ysym,pValue2symbol(p.corLe),'fontsize',8,'HorizontalAlignment','center','fontname','Arial');
% text(2,ysym,pValue2symbol(p.corSh),'fontsize',8,'HorizontalAlignment','center','fontname','Arial');
% bh21(1).FaceColor = cGray;
% bh21(2).FaceColor = cOrange;
% set(gca,'xtick',[1,2],'xticklabel',{'Lesion','Sham'});
% ylabel('Probability','Fontsize',8,'FontName','Arial');
% title('Correct','Fontsize',9,'FontName','Arial');
% 
% le1 = legend({'Pre','Post'},'Fontsize',8,'fontname','Arial','units','centimeters',...
%     'Position',[xs2(4)+size2(1)+0.65,ys(2)+1.3,1,1]);% [4.7,2.8,1,1]
% le1.ItemTokenSize = [12,22];
% le1.Position = le1.Position + [0.025 0.045 0 0];
% legend('boxoff');
% 
% % PLOT late-3FPs (Bar Plot)
% ha24 = axes;
% set(ha24, 'units', 'centimeters', 'position', [xs2(4) ys(2) size2+[0.5,0]], 'nextplot', 'add','tickDir', 'out',...
%     'fontsize',7,'fontname','Arial', 'ylim',[0 0.7]);
% bh24 = bar(1:3,... % categorical({'S','M','L'})
%     [TBTg.mean_Late_S(strcmp(TBTg.Group,'Lesion-Pre')),TBTg.mean_Late_S(strcmp(TBTg.Group,'Lesion-Post'));...
%     TBTg.mean_Late_M(strcmp(TBTg.Group,'Lesion-Pre')),TBTg.mean_Late_M(strcmp(TBTg.Group,'Lesion-Post'));...
%     TBTg.mean_Late_L(strcmp(TBTg.Group,'Lesion-Pre')),TBTg.mean_Late_L(strcmp(TBTg.Group,'Lesion-Post'))],...
%     'FaceColor','flat','EdgeColor','none');
% xtips1 = bh24(1).XEndPoints;
% xtips2 = bh24(2).XEndPoints;
% ytips1 = bh24(1).YEndPoints;
% ytips2 = bh24(2).YEndPoints;
% errorbar(xtips1,ytips1,...
%     [TBTg.sem_Late_S(strcmp(TBTg.Group,'Lesion-Pre')),...
%     TBTg.sem_Late_M(strcmp(TBTg.Group,'Lesion-Pre')),...
%     TBTg.sem_Late_L(strcmp(TBTg.Group,'Lesion-Pre'))],...
%     '.k','capsize',3,'lineWidth',0.7);
% errorbar(xtips2,ytips2,...
%     [TBTg.sem_Late_S(strcmp(TBTg.Group,'Lesion-Post')),...
%     TBTg.sem_Late_M(strcmp(TBTg.Group,'Lesion-Post')),...
%     TBTg.sem_Late_L(strcmp(TBTg.Group,'Lesion-Post'))],...
%     '.k','capsize',3,'lineWidth',0.7);
% ylm = ylim;ysep = (ylm(2)-ylm(1))/15;yline = ylm(2)-ysep*2; ysym = ylm(2)-ysep;
% bh24(1).FaceColor = cGray;
% bh24(2).FaceColor = cOrange;
% set(gca,'xtick',[1,2,3],'xticklabel',{'S','M','L'});% ,'XTickLabelRotation',30
% title('Late-3FPs in Lesion','Fontsize',9,'FontName','Arial');
%% Save
savename = fullfile(pwd,strcat(grpName(1),'AfterLearning'));
saveas(hf,savename,'fig');
print(hf,'-dpng',savename);
print(hf,'-dpdf',savename,'-bestfit');
% print(hf,'-depsc2',savename);
%% performance of each animal
esti = 'Cor';
clm = [-9 9];
Height = 6; % axes height (centimeter)

cSeismic = seismic(200);
cRdYlBu = RdYlBu(200);
% mycolormap = flipud(cRdYlBu);
mycolormap = cSeismic;

nSBS = SBS;
grp = split(nSBS.Group,'-');
nSBS.Group = grp(:,1);
nSBS = addvars(nSBS,grp(:,2),'NewVariableNames','Experiment','After','Group');
sortSBS = sortrows(nSBS,{'Group','Subject'},{'ascend','ascend'});
[sbjorder,idxSub] = unique(strcat(sortSBS.Subject,sortSBS.Group),'stable');
grporder = sortSBS.Group(idxSub);
Nrats = length(unique(strcat(sortSBS.Subject,sortSBS.Group)));
Ngrp = [length(unique(nSBS(nSBS.Group==grpName(1),:).Subject)),length(unique(nSBS(nSBS.Group==grpName(2),:).Subject))];
Nperiod = [length(unique(nSBS(nSBS.Experiment==prdName(1),:).Session)),length(unique(nSBS(nSBS.Experiment==prdName(2),:).Session))];

Width = (sum(Nperiod)+length(Nperiod))*Height./(sum(Ngrp)+length(Ngrp));

hf2 = figure(44); clf(hf2,'reset');
set(hf2, 'name', 'LesionEffect', 'units', 'centimeters', 'position', [1 1 Width+3.8 Height+1.5],...
    'PaperPositionMode', 'auto');
hheat = axes(hf2);
set(hheat, 'units', 'centimeters','nextplot', 'add','tickDir', 'out',...
    'position',[1.8 0.8 Width,Height],...
    'xlim',[0 sum(Nperiod)+length(Nperiod)],...
    'xtick', [Nperiod(1)/2+0.5, Nperiod(1)+Nperiod(2)/2+1.5],...
    'xticklabel',cellstr(unique(sortSBS.Experiment,'stable')),...
    'ylim',[0, Nrats+2],'ytick', [Ngrp(2)/2+0.5, Ngrp(2)+Ngrp(1)/2+1.5], ...
    'yticklabel', {sprintf('%s(N=%2.0d)',grpName(2), Ngrp(2)), sprintf('%s(N=%2.0d)',grpName(1), Ngrp(1))},...
    'fontsize',7,'fontname','arial','ticklength', [0.02 0.025]);
title([esti],'fontsize',9,'fontname','arial');

% sort
pv = struct; %plot value

N = 1;
Nx = Nperiod(N);
curSBS = sortSBS(sortSBS.Experiment==prdName(N),:);
eval(['estVec = curSBS.',esti,';']);
val2 = reshape(estVec(curSBS.Group==grpName(2)),[Nx,length(estVec(curSBS.Group==grpName(2)))/Nx])';
val1 = reshape(estVec(curSBS.Group==grpName(1)),[Nx,length(estVec(curSBS.Group==grpName(1)))/Nx])';
[val2,mval2,sval2] = zscore(val2,0,2);
[val1,mval1,sval1] = zscore(val1,0,2);
pv(N).v2 = val2;pv(N).v1 = val1;

N = 2;
Nx = Nperiod(N);
curSBS = sortSBS(sortSBS.Experiment==prdName(N),:);
eval(['estVec = curSBS.',esti,';']);
val2 = reshape(estVec(curSBS.Group==grpName(2)),[Nx,length(estVec(curSBS.Group==grpName(2)))/Nx])';
val1 = reshape(estVec(curSBS.Group==grpName(1)),[Nx,length(estVec(curSBS.Group==grpName(1)))/Nx])';
val2 = (val2-mval2)./sval2; % zscore
val1 = (val1-mval1)./sval1;
[~,idx2] = sort(mean(val2,2),'ascend');
[~,idx1] = sort(mean(val1,2),'ascend');
pv(N).v2 = val2;pv(N).v1 = val1;

% plot
N = 1;
Nx = Nperiod(N); Nxpre = 0;
curSBS = sortSBS(sortSBS.Experiment==prdName(N),:);
eval(['estVec = curSBS.',esti,';']);
val2 = pv(N).v2(idx2,:);
val1 = pv(N).v1(idx1,:);
h_grp2 = imagesc([Nxpre+1,Nxpre+Nx],[1,Ngrp(2)],val2,clm);
h_grp1 = imagesc([Nxpre+1,Nxpre+Nx],[1,Ngrp(1)]+Ngrp(2)+1,val1,clm);
Nxpre = Nxpre+Nx+1;
sbj2 = sbjorder(strcmp(grporder,grpName(2)));sbj2 = erase(sbj2(idx2),grpName);
sbj1 = sbjorder(strcmp(grporder,grpName(1)));sbj1 = erase(sbj1(idx1),grpName);
set(gca,'ytick',[1:Ngrp(2),(Ngrp(2)+2):(Ngrp(2)+1+Ngrp(1))],'yticklabel',cellstr([sbj2;sbj1]));

N = 2;
Nx = Nperiod(N);
curSBS = sortSBS(sortSBS.Experiment==prdName(N),:);
eval(['estVec = curSBS.',esti,';']);
val2 = pv(N).v2(idx2,:);
val1 = pv(N).v1(idx1,:);
h_grp2 = imagesc([Nxpre+1,Nxpre+Nx],[1,Ngrp(2)],val2,clm);
h_grp1 = imagesc([Nxpre+1,Nxpre+Nx],[1,Ngrp(1)]+Ngrp(2)+1,val1,clm);

colormap(mycolormap);
hcbar = colorbar('location', 'EastOutSide','Units', 'Centimeters','AxisLocation','in',...
    'position',[1.8+Width+0.8,0.8,0.25,Height],...
    'ytick', -18:3:18,'yticklabel', cellstr(string(-18:3:18)),...
    'TickDirection', 'out','ticklength', 0.02,'FontSize',7,'fontname','arial');
hcbarbel = ylabel(hcbar,['z-score'],'FontSize',8,'Rotation',270,'fontname','arial',...
    'Units','Centimeters');
hcbarbel.Position(1) = hcbarbel.Position(1)+1.1;
%% Save
savename = fullfile(pwd,strcat(['LesionEffect_Allsbj_',esti]));
saveas(hf2,savename,'fig');
print(hf2,'-dpng',savename);
% print(hf2,'-dpdf',savename,'-bestfit');
print(hf2,'-depsc2',savename);
end

%% Functions
function [SBS,TBT] = packData(btAll2d)
SBS = table; % session by session data
TBT = table; % trial by trial data
for i=1:size(btAll2d,1)
    for j=1:size(btAll2d,2)
        T = btAll2d{i,j};
        SBS = [SBS;estSBS(T,j)];
        
        nrow = size(T,1);
        if nrow>1
            tempT = addvars(T,repelem(j,nrow)','After','Date','NewVariableNames','Session');
            TBT = [TBT;tempT];
        end
    end
end
end

function outT = estSBS(data,session)

global cenMethod;

outT = table;
if isempty(data)
    return;
end

sbj = data.Subject(1);
task = data.Task(1);

typename = unique(data.TrialType);
for i=1:length(typename)
    t = struct;
    t.Subject = sbj;
    t.Group =data.Group(1);
    t.Date = data.Date(1);
    t.Session = session;
    t.Task = task;
    t.Type = typename(i);
    tdata = data(data.TrialType==t.Type,:);

    t.nBlock = length(unique(tdata.BlockNum));
    t.nTrial = length(tdata.iTrial);
    t.Dark   = sum(tdata.DarkTry)./(sum(tdata.DarkTry)+t.nTrial);
    t.Cor  = sum(tdata.Outcome=="Cor")./t.nTrial;
    t.Pre  = sum(tdata.Outcome=="Pre")./t.nTrial;
    t.Late = sum(tdata.Outcome=="Late")./t.nTrial;

    t.Cor_S = sum(tdata.Outcome=="Cor" & abs(tdata.FP-0.5)<1e-4)./sum(abs(tdata.FP-0.5)<1e-4);
    t.Cor_M = sum(tdata.Outcome=="Cor" & abs(tdata.FP-1.0)<1e-4)./sum(abs(tdata.FP-1.0)<1e-4);
    t.Cor_L = sum(tdata.Outcome=="Cor" & abs(tdata.FP-1.5)<1e-4)./sum(abs(tdata.FP-1.5)<1e-4);
    t.Pre_S = sum(tdata.Outcome=="Pre" & abs(tdata.FP-0.5)<1e-4)./sum(abs(tdata.FP-0.5)<1e-4);
    t.Pre_M = sum(tdata.Outcome=="Pre" & abs(tdata.FP-1.0)<1e-4)./sum(abs(tdata.FP-1.0)<1e-4);
    t.Pre_L = sum(tdata.Outcome=="Pre" & abs(tdata.FP-1.5)<1e-4)./sum(abs(tdata.FP-1.5)<1e-4);
    t.Late_S = sum(tdata.Outcome=="Late" & abs(tdata.FP-0.5)<1e-4)./sum(abs(tdata.FP-0.5)<1e-4);
    t.Late_M = sum(tdata.Outcome=="Late" & abs(tdata.FP-1.0)<1e-4)./sum(abs(tdata.FP-1.0)<1e-4);
    t.Late_L = sum(tdata.Outcome=="Late" & abs(tdata.FP-1.5)<1e-4)./sum(abs(tdata.FP-1.5)<1e-4);
    
    t.maxFP = max(tdata.FP);
    t.t2mFP = find(tdata.FP==t.maxFP,1,'first');
    t.minRW = min(tdata.RW);
    t.t2mRW = find(tdata.RW==t.minRW,1,'first');
    
    switch cenMethod
        case 'mean'
            t.HT = mean(rmoutliers(tdata.HT,'mean'),'omitnan');
            RT = rmoutliers(tdata(tdata.Outcome=="Cor",:).RT,'mean');
            t.RT = mean(RT(RT>=0.1),'omitnan');
            t.MT = mean(rmoutliers(tdata(tdata.Outcome=="Cor",:).MT,'mean'),'omitnan');
        case 'median'
            t.HT = median(rmoutliers(tdata.HT,'median'),'omitnan');
            RT = rmoutliers(tdata(tdata.Outcome=="Cor",:).RT,'median');
            t.RT = median(RT(RT>=0.1),'omitnan');
            t.MT = median(rmoutliers(tdata(tdata.Outcome=="Cor",:).MT,'median'),'omitnan');
        case 'geomean'
            t.HT = geomean(rmoutliers(tdata.HT,'quartiles'),'omitnan');
            RT = rmoutliers(tdata(tdata.Outcome=="Cor" & tdata.RT>0,:).RT,'quartiles');
            t.RT = geomean(RT(RT>=0.1),'omitnan');
            t.MT = geomean(rmoutliers(tdata(tdata.Outcome=="Cor",:).MT,'quartiles'),'omitnan');
    end
    outT = [outT;struct2table(t)];
end

end

function outT = estTBT_3FPs(TBT)
global cenMethod edges_RT edges_HT edges_RelT smo_win
fplist = [0.5,1.0,1.5];
nboot = 1000;

outT = table;
sbjlist = unique(TBT.Subject);

for i=1:length(sbjlist)
    data = TBT(TBT.Subject==sbjlist(i),:);
    typename = unique(data.TrialType);
    for j=1:length(typename)
        t = struct;
        t.Subject = sbjlist(i);
        t.Group = data.Group(1);
        t.Task = data.Task(1);
        t.Type = typename(j);
        tdata = data(data.TrialType==t.Type,:);

        t.nSession = length(unique(tdata.Session));
        t.nTrial = size(tdata,1);
        t.Dark = sum(tdata.DarkTry)./(sum(tdata.DarkTry)+t.nTrial);

        idxFPS = abs(tdata.FP-fplist(1))<1E-4; % small
        idxFPM = abs(tdata.FP-fplist(2))<1E-4; % medium
        idxFPL = abs(tdata.FP-fplist(3))<1E-4; % large
        idxCor = tdata.Outcome=="Cor";
        idxPre = tdata.Outcome=="Pre";
        idxLate = tdata.Outcome=="Late";

        t.Cor = sum(idxCor)./t.nTrial;
        t.Pre = sum(idxPre)./t.nTrial;
        t.Late = sum(idxLate)./t.nTrial;
        t.Cor_S = sum( idxFPS & idxCor )./sum(idxFPS);
        t.Pre_S = sum( idxFPS & idxPre )./sum(idxFPS);
        t.Late_S = sum( idxFPS & idxLate )./sum(idxFPS);
        t.Cor_M = sum( idxFPM & idxCor )./sum(idxFPM);
        t.Pre_M = sum( idxFPM & idxPre )./sum(idxFPM);
        t.Late_M = sum( idxFPM & idxLate )./sum(idxFPM);
        t.Cor_L = sum( idxFPL & idxCor )./sum(idxFPL);
        t.Pre_L = sum( idxFPL & idxPre )./sum(idxFPL);
        t.Late_L = sum( idxFPL & idxLate )./sum(idxFPL);
        
        RT = rmoutliers(tdata.RT(idxCor),cenMethod);
        RT_S = rmoutliers(tdata.RT(idxCor&idxFPS),cenMethod);
        RT_M = rmoutliers(tdata.RT(idxCor&idxFPM),cenMethod);
        RT_L = rmoutliers(tdata.RT(idxCor&idxFPL),cenMethod);
        RT = RT(RT>=0.1);
        RT_S = RT_S(RT_S>=0.1);
        RT_M = RT_M(RT_M>=0.1);
        RT_L = RT_L(RT_L>=0.1);
        t.RT = eval(cenMethod+"(RT,'omitnan')");
        RT_CI = eval("bootci(nboot,{@"+cenMethod+",RT},'alpha',0.05)'");
        t.RT_CI = [t.RT-RT_CI(1), RT_CI(2)-t.RT];
        RT_SE = eval("std(bootstrp(nboot,@"+cenMethod+",RT))");
        t.RT_SE = [RT_SE,RT_SE];
        t.RT_S = eval(cenMethod+"(RT_S,'omitnan')");
        t.RT_M = eval(cenMethod+"(RT_M,'omitnan')");
        t.RT_L = eval(cenMethod+"(RT_L,'omitnan')");
        
        RelT = rmoutliers(tdata.HT(idxCor|idxLate)-tdata.FP(idxCor|idxLate),cenMethod);
        RelT_S = rmoutliers(tdata.HT((idxCor|idxLate)&idxFPS)-tdata.FP((idxCor|idxLate)&idxFPS),cenMethod);
        RelT_M = rmoutliers(tdata.HT((idxCor|idxLate)&idxFPM)-tdata.FP((idxCor|idxLate)&idxFPM),cenMethod);
        RelT_L = rmoutliers(tdata.HT((idxCor|idxLate)&idxFPL)-tdata.FP((idxCor|idxLate)&idxFPL),cenMethod);
        RelT = RelT(RelT>=0.1);
        RelT_S = RelT_S(RelT_S>=0.1);
        RelT_M = RelT_M(RelT_M>=0.1);
        RelT_L = RelT_L(RelT_L>=0.1);
        t.RelT = eval(cenMethod+"(RelT,'omitnan')");
        RelT_CI = eval("bootci(nboot,{@"+cenMethod+",RelT},'alpha',0.05)'");
        t.RelT_CI = [t.RelT-RelT_CI(1), RelT_CI(2)-t.RelT];
        RelT_SE = eval("std(bootstrp(nboot,@"+cenMethod+",RelT))");
        t.RelT_SE = [RelT_SE,RelT_SE];
        t.RelT_S = eval(cenMethod+"(RelT_S,'omitnan')");
        t.RelT_M = eval(cenMethod+"(RelT_M,'omitnan')");
        t.RelT_L = eval(cenMethod+"(RelT_L,'omitnan')");

        t.RTdist = smoothdata(histcounts(tdata.RT(idxCor),...
            edges_RT,'Normalization','pdf'),2,'gaussian',smo_win);
        t.RTdist_S = smoothdata(histcounts(tdata.RT(idxCor&idxFPS),...
            edges_RT,'Normalization','pdf'),2,'gaussian',smo_win);
        t.RTdist_M = smoothdata(histcounts(tdata.RT(idxCor&idxFPM),...
            edges_RT,'Normalization','pdf'),2,'gaussian',smo_win);
        t.RTdist_L = smoothdata(histcounts(tdata.RT(idxCor&idxFPL),...
            edges_RT,'Normalization','pdf'),2,'gaussian',smo_win);

        t.HTdist = smoothdata(histcounts(tdata.HT,...
            edges_HT,'Normalization','probability'),2,'gaussian',smo_win);
        t.HTdist_S = smoothdata(histcounts(tdata.HT(idxFPS),...
            edges_HT,'Normalization','probability'),2,'gaussian',smo_win);
        t.HTdist_M = smoothdata(histcounts(tdata.HT(idxFPM),...
            edges_HT,'Normalization','probability'),2,'gaussian',smo_win);
        t.HTdist_L = smoothdata(histcounts(tdata.HT(idxFPL),...
            edges_HT,'Normalization','probability'),2,'gaussian',smo_win);
        
        t.RelTdist = smoothdata(histcounts(tdata.HT(idxCor|idxLate)-tdata.FP(idxCor|idxLate),...
            edges_RelT,'Normalization','probability'),2,'gaussian',smo_win);
        t.RelTdist_S = smoothdata(histcounts(tdata.HT((idxCor|idxLate)&idxFPS)-tdata.FP((idxCor|idxLate)&idxFPS),...
            edges_RelT,'Normalization','probability'),2,'gaussian',smo_win);
        t.RelTdist_M = smoothdata(histcounts(tdata.HT((idxCor|idxLate)&idxFPM)-tdata.FP((idxCor|idxLate)&idxFPM),...
            edges_RelT,'Normalization','probability'),2,'gaussian',smo_win);
        t.RelTdist_L = smoothdata(histcounts(tdata.HT((idxCor|idxLate)&idxFPL)-tdata.FP((idxCor|idxLate)&idxFPL),...
            edges_RelT,'Normalization','probability'),2,'gaussian',smo_win);
        
        t.RelTdist_CDF = smoothdata(histcounts(tdata.HT(idxCor|idxLate)-tdata.FP(idxCor|idxLate),...
            edges_RelT,'Normalization','cdf'),2,'gaussian',smo_win);
        t.RelTdist_S_CDF = smoothdata(histcounts(tdata.HT((idxCor|idxLate)&idxFPS)-tdata.FP((idxCor|idxLate)&idxFPS),...
            edges_RelT,'Normalization','cdf'),2,'gaussian',smo_win);
        t.RelTdist_M_CDF = smoothdata(histcounts(tdata.HT((idxCor|idxLate)&idxFPM)-tdata.FP((idxCor|idxLate)&idxFPM),...
            edges_RelT,'Normalization','cdf'),2,'gaussian',smo_win);
        t.RelTdist_L_CDF = smoothdata(histcounts(tdata.HT((idxCor|idxLate)&idxFPL)-tdata.FP((idxCor|idxLate)&idxFPL),...
            edges_RelT,'Normalization','cdf'),2,'gaussian',smo_win);

        outT = [outT;struct2table(t)];
    end
end

end

function symbol = pValue2symbol(p)
    if p>0.05
%         symbol = 'n.s';
        symbol = sprintf('%0.2f',p);
    elseif p>0.01 && p<=0.05
        symbol = '*';
    elseif p>0.001 && p<=0.01
        symbol = '**';
    else
        symbol = '***';
    end
end