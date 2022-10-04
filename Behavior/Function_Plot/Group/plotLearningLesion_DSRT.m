function plotLearningLesion_DSRT(btAll2d,tarType)
%%
altMethod = {'mean','median','geomean'};
global cenMethod edges_RT edges_HT edges_RelT smo_win;
cenMethod = altMethod{2}; % each subject's RT central estimate
grandCen = 'mean';
grandErr = 'sem';

edges_RT = 0:0.025:0.6; % Reaction Time (only correct)
edges_HT = 0:0.05:2.5; % Hold Time (all trials)
edges_RelT = 0:0.025:1; % Realease Time (correct + late trials)
smo_win = 8; % smoothdata('gaussian'), 

grpName = ["Lesion";"Sham"];
% tarType = "Lever";
%% Data processing
% session by session, trial by trial: 2 packaging method
[SBS_raw,TBT_raw] = packData(btAll2d);
SBS = SBS_raw(SBS_raw.Type==tarType,:);
TBT = TBT_raw(TBT_raw.TrialType==tarType,:);

[~,idxSess] = unique(SBS.Session);
sessTask = SBS.Task(idxSess);
taskSign = struct;
[taskSign.Task,taskSign.Ori] = unique(sessTask,'stable');
nTask = size(taskSign.Task,1);
if nTask>1
    taskSign.End = [taskSign.Ori(2:nTask)-1;length(sessTask)];
else
    taskSign.End = length(sessTask);
end
TS = struct2table(taskSign);

% between subject group
SBSbtw = grpstats(removevars(SBS,{'Subject','Date','Task','Type'}),...
    {'Group','Session'},{grandCen,grandErr});
% % subject * group
% SBSsg = grpstats(removevars(SBS,{'Session','Date','Task','Type'}),{'Subject','Group'},{grandCen,grandErr});

save('VarsToPlot.mat','TBT','SBS','SBSbtw','TS');
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

cBlue = cOrange; % 
cGray = [0.3 0.3 0.3];

hf = figure(44); clf(hf,'reset');
set(hf, 'name', 'Learning', 'units', 'centimeters', 'position', [1 1 12.5 11.5],...
    'PaperPositionMode', 'auto','renderer','painter'); % 生科论文要求版面裁掉边距还剩，宽度15.8cm,高度24.2cm

size1 = [3,3*0.7];

ys = [1 3.6 6.2 8.8]; % yStart
ys = fliplr(ys);
xs = [1.3 4.5 7.7]; % xStart

% PLOT x:session, y:Correct Wait1, color: Group(hM4D/EGFP)
ha11 = axes;
set(ha11, 'units', 'centimeters', 'position', [xs(1) ys(1) size1], 'nextplot', 'add','tickDir', 'out',...
    'fontsize',7,'fontname','Arial','ylim',[0.4,1],'ticklength', [0.02 0.025]);
thisTS = 1;
SBSbtw_this = SBSbtw(ismember(SBSbtw.Session,TS.Ori(thisTS):(TS.End(thisTS))),:);
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_Cor(SBSbtw_this.Group==grpName(1)),...
%     SBSbtw_this.sem_Cor(SBSbtw_this.Group==grpName(1)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cBlue,'markerSize',4,'markerFaceColor',cBlue,'markerEdgeColor','none'});
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_Cor(SBSbtw_this.Group==grpName(2)),...
%     SBSbtw_this.sem_Cor(SBSbtw_this.Group==grpName(2)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cGray,'markerSize',4,'markerFaceColor',cGray,'markerEdgeColor','none'});
idxGrp = 2;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_Cor(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_Cor(SBSbtw_this.Group==grpName(idxGrp))';
l2 = plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
idxGrp = 1;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_Cor(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_Cor(SBSbtw_this.Group==grpName(idxGrp))';
l1 = plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)

xlim([0.5,TS.End(thisTS)-TS.Ori(thisTS)+1.5]);
set(gca,'xtick',1:10,'ytick',0:0.2:1,'yticklabel',cellstr(string((0:0.2:1).*100))); %grid on;
% xlabel('Sessions','Fontsize',8,'FontName','Arial');
ylabel('Correct (%)','Fontsize',8,'FontName','Arial');
title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');

le1 = legend([l1 l2],cellstr(grpName),'Fontsize',8,'units','centimeters',...
    'Position',[xs(3)+size1(1)+0.3,ys(1)+size1(2)/1.8,1,1]);% [4.7,2.8,1,1]
le1.ItemTokenSize = [12,22];
le1.Position = le1.Position + [0.025 0.045 0 0];
legend('boxoff');

% PLOT x:session, y:Correct Wait2, color: Group(hM4D/EGFP)
ha12 = axes;
set(ha12, 'units', 'centimeters', 'position', [xs(2) ys(1) size1], 'nextplot', 'add','tickDir', 'out',...
    'fontsize',7,'fontname','Arial','ylim',[0.4,1],'ticklength', [0.02 0.025]);
ha12.YAxis.Visible = 'off';
thisTS = 2;
SBSbtw_this = SBSbtw(ismember(SBSbtw.Session,TS.Ori(thisTS):(TS.End(thisTS))),:);
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_Cor(SBSbtw_this.Group==grpName(1)),...
%     SBSbtw_this.sem_Cor(SBSbtw_this.Group==grpName(1)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cBlue,'markerSize',4,'markerFaceColor',cBlue,'markerEdgeColor','none'});
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_Cor(SBSbtw_this.Group==grpName(2)),...
%     SBSbtw_this.sem_Cor(SBSbtw_this.Group==grpName(2)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cGray,'markerSize',4,'markerFaceColor',cGray,'markerEdgeColor','none'});
idxGrp = 2;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_Cor(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_Cor(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
idxGrp = 1;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_Cor(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_Cor(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)

xlim([0.5,TS.End(thisTS)-TS.Ori(thisTS)+1.5]);
set(gca,'xtick',1:10); %grid on;
% xlabel('Sessions','Fontsize',8,'FontName','Arial');
% ylabel('Correct','Fontsize',8,'FontName','Arial');
title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');

% PLOT x:session, y:Correct 3FPs, color: Group(hM4D/EGFP)
ha13 = axes;
set(ha13, 'units', 'centimeters', 'position', [xs(3) ys(1) size1], 'nextplot', 'add','tickDir', 'out',...
    'fontsize',7,'fontname','Arial','ylim',[0.4,1],'ticklength', [0.02 0.025]);
ha13.YAxis.Visible = 'off';
thisTS = 3;
SBSbtw_this = SBSbtw(ismember(SBSbtw.Session,TS.Ori(thisTS):(TS.End(thisTS))),:);
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_Cor(SBSbtw_this.Group==grpName(1)),...
%     SBSbtw_this.sem_Cor(SBSbtw_this.Group==grpName(1)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cBlue,'markerSize',4,'markerFaceColor',cBlue,'markerEdgeColor','none'});
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_Cor(SBSbtw_this.Group==grpName(2)),...
%     SBSbtw_this.sem_Cor(SBSbtw_this.Group==grpName(2)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cGray,'markerSize',4,'markerFaceColor',cGray,'markerEdgeColor','none'});
idxGrp = 2;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_Cor(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_Cor(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
idxGrp = 1;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_Cor(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_Cor(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)

xlim([0.5,TS.End(thisTS)-TS.Ori(thisTS)+1.5]);
set(gca,'xtick',1:10); %grid on;
% xlabel('Sessions','Fontsize',8,'FontName','Arial');
% ylabel('Correct','Fontsize',8,'FontName','Arial');
title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');

% PLOT x:session, y:Premature Wait1, color: Group(hM4D/EGFP)
ha21 = axes;
set(ha21, 'units', 'centimeters', 'position', [xs(1) ys(2) size1], 'nextplot', 'add','tickDir', 'out',...
    'fontsize',7,'fontname','Arial','ylim',[0,0.5],'ticklength', [0.02 0.025]);
thisTS = 1;
SBSbtw_this = SBSbtw(ismember(SBSbtw.Session,TS.Ori(thisTS):(TS.End(thisTS))),:);
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_Pre(SBSbtw_this.Group==grpName(1)),...
%     SBSbtw_this.sem_Pre(SBSbtw_this.Group==grpName(1)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cBlue,'markerSize',4,'markerFaceColor',cBlue,'markerEdgeColor','none'});
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_Pre(SBSbtw_this.Group==grpName(2)),...
%     SBSbtw_this.sem_Pre(SBSbtw_this.Group==grpName(2)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cGray,'markerSize',4,'markerFaceColor',cGray,'markerEdgeColor','none'});
idxGrp = 2;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_Pre(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_Pre(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
idxGrp = 1;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_Pre(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_Pre(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)

xlim([0.5,TS.End(thisTS)-TS.Ori(thisTS)+1.5]);
set(gca,'xtick',1:10,'ytick',0:0.2:1,'yticklabel',cellstr(string((0:0.2:1).*100))); %grid on;
% xlabel('Sessions','Fontsize',8,'FontName','Arial');
ylabel('Premature (%)','Fontsize',8,'FontName','Arial');
% title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');

% PLOT x:session, y:Premature Wait2, color: Group(hM4D/EGFP)
ha22 = axes;
set(ha22, 'units', 'centimeters', 'position', [xs(2) ys(2) size1], 'nextplot', 'add','tickDir', 'out',...
    'fontsize',7,'fontname','Arial','ylim',[0,0.5],'ticklength', [0.02 0.025]);
ha22.YAxis.Visible = 'off';
thisTS = 2;
SBSbtw_this = SBSbtw(ismember(SBSbtw.Session,TS.Ori(thisTS):(TS.End(thisTS))),:);
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_Pre(SBSbtw_this.Group==grpName(1)),...
%     SBSbtw_this.sem_Pre(SBSbtw_this.Group==grpName(1)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cBlue,'markerSize',4,'markerFaceColor',cBlue,'markerEdgeColor','none'});
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_Pre(SBSbtw_this.Group==grpName(2)),...
%     SBSbtw_this.sem_Pre(SBSbtw_this.Group==grpName(2)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cGray,'markerSize',4,'markerFaceColor',cGray,'markerEdgeColor','none'});
idxGrp = 2;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_Pre(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_Pre(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
idxGrp = 1;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_Pre(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_Pre(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)

xlim([0.5,TS.End(thisTS)-TS.Ori(thisTS)+1.5]);
set(gca,'xtick',1:10); %grid on;
% xlabel('Sessions','Fontsize',8,'FontName','Arial');
% ylabel('Premature','Fontsize',8,'FontName','Arial');
% title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');

% PLOT x:session, y:Premature 3FPs, color: Group(hM4D/EGFP)
ha23 = axes;
set(ha23, 'units', 'centimeters', 'position', [xs(3) ys(2) size1], 'nextplot', 'add','tickDir', 'out',...
    'fontsize',7,'fontname','Arial','ylim',[0,0.5],'ticklength', [0.02 0.025]);
ha23.YAxis.Visible = 'off';
thisTS = 3;
SBSbtw_this = SBSbtw(ismember(SBSbtw.Session,TS.Ori(thisTS):(TS.End(thisTS))),:);
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_Pre(SBSbtw_this.Group==grpName(1)),...
%     SBSbtw_this.sem_Pre(SBSbtw_this.Group==grpName(1)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cBlue,'markerSize',4,'markerFaceColor',cBlue,'markerEdgeColor','none'});
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_Pre(SBSbtw_this.Group==grpName(2)),...
%     SBSbtw_this.sem_Pre(SBSbtw_this.Group==grpName(2)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cGray,'markerSize',4,'markerFaceColor',cGray,'markerEdgeColor','none'});
idxGrp = 2;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_Pre(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_Pre(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
idxGrp = 1;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_Pre(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_Pre(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)

xlim([0.5,TS.End(thisTS)-TS.Ori(thisTS)+1.5]);
set(gca,'xtick',1:10); %grid on;
% xlabel('Sessions','Fontsize',8,'FontName','Arial');
% ylabel('Premature','Fontsize',8,'FontName','Arial');
% title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');

% PLOT x:session, y:Late Wait1, color: Group(hM4D/EGFP)
ha31 = axes;
set(ha31, 'units', 'centimeters', 'position', [xs(1) ys(3) size1], 'nextplot', 'add','tickDir', 'out',...
    'fontsize',7,'fontname','Arial','ylim',[0,0.31],'ticklength', [0.02 0.025]);
thisTS = 1;
SBSbtw_this = SBSbtw(ismember(SBSbtw.Session,TS.Ori(thisTS):(TS.End(thisTS))),:);
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_Late(SBSbtw_this.Group==grpName(1)),...
%     SBSbtw_this.sem_Late(SBSbtw_this.Group==grpName(1)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cBlue,'markerSize',4,'markerFaceColor',cBlue,'markerEdgeColor','none'});
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_Late(SBSbtw_this.Group==grpName(2)),...
%     SBSbtw_this.sem_Late(SBSbtw_this.Group==grpName(2)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cGray,'markerSize',4,'markerFaceColor',cGray,'markerEdgeColor','none'});
idxGrp = 2;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_Late(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_Late(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
idxGrp = 1;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_Late(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_Late(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)

xlim([0.5,TS.End(thisTS)-TS.Ori(thisTS)+1.5]);
set(gca,'xtick',1:10,'ytick',0:0.1:1,'yticklabel',cellstr(string((0:0.1:1).*100))); %grid on;
% xlabel('Sessions','Fontsize',8,'FontName','Arial');
ylabel('Late (%)','Fontsize',8,'FontName','Arial');
% title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');

% PLOT x:session, y:Late Wait2, color: Group(hM4D/EGFP)
ha32 = axes;
set(ha32, 'units', 'centimeters', 'position', [xs(2) ys(3) size1], 'nextplot', 'add','tickDir', 'out',...
    'fontsize',7,'fontname','Arial','ylim',[0,0.31],'ticklength', [0.02 0.025]);
ha32.YAxis.Visible = 'off';
thisTS = 2;
SBSbtw_this = SBSbtw(ismember(SBSbtw.Session,TS.Ori(thisTS):(TS.End(thisTS))),:);
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_Late(SBSbtw_this.Group==grpName(1)),...
%     SBSbtw_this.sem_Late(SBSbtw_this.Group==grpName(1)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cBlue,'markerSize',4,'markerFaceColor',cBlue,'markerEdgeColor','none'});
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_Late(SBSbtw_this.Group==grpName(2)),...
%     SBSbtw_this.sem_Late(SBSbtw_this.Group==grpName(2)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cGray,'markerSize',4,'markerFaceColor',cGray,'markerEdgeColor','none'});
idxGrp = 2;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_Late(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_Late(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
idxGrp = 1;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_Late(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_Late(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)

xlim([0.5,TS.End(thisTS)-TS.Ori(thisTS)+1.5]);
set(gca,'xtick',1:10); %grid on;
% xlabel('Sessions','Fontsize',8,'FontName','Arial');
% ylabel('Late','Fontsize',8,'FontName','Arial');
% title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');

% PLOT x:session, y:Late 3FPs, color: Group(hM4D/EGFP)
ha33 = axes;
set(ha33, 'units', 'centimeters', 'position', [xs(3) ys(3) size1], 'nextplot', 'add','tickDir', 'out',...
    'fontsize',7,'fontname','Arial','ylim',[0,0.31],'ticklength', [0.02 0.025]);
ha33.YAxis.Visible = 'off';
thisTS = 3;
SBSbtw_this = SBSbtw(ismember(SBSbtw.Session,TS.Ori(thisTS):(TS.End(thisTS))),:);
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_Late(SBSbtw_this.Group==grpName(1)),...
%     SBSbtw_this.sem_Late(SBSbtw_this.Group==grpName(1)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cBlue,'markerSize',4,'markerFaceColor',cBlue,'markerEdgeColor','none'});
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_Late(SBSbtw_this.Group==grpName(2)),...
%     SBSbtw_this.sem_Late(SBSbtw_this.Group==grpName(2)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cGray,'markerSize',4,'markerFaceColor',cGray,'markerEdgeColor','none'});
idxGrp = 2;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_Late(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_Late(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
idxGrp = 1;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_Late(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_Late(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)

xlim([0.5,TS.End(thisTS)-TS.Ori(thisTS)+1.5]);
set(gca,'xtick',1:10); %grid on;
% xlabel('Sessions','Fontsize',8,'FontName','Arial');
% ylabel('Late','Fontsize',8,'FontName','Arial');
% title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');

% PLOT x:session, y:RT Wait1, color: Group(hM4D/EGFP)
ha41 = axes;
set(ha41, 'units', 'centimeters', 'position', [xs(1) ys(4) size1], 'nextplot', 'add','tickDir', 'out',...
    'fontsize',7,'fontname','Arial','ylim',[0.25,0.75],'ticklength', [0.02 0.025]);
thisTS = 1;
SBSbtw_this = SBSbtw(ismember(SBSbtw.Session,TS.Ori(thisTS):(TS.End(thisTS))),:);
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_RT(SBSbtw_this.Group==grpName(1)),...
%     SBSbtw_this.sem_RT(SBSbtw_this.Group==grpName(1)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cBlue,'markerSize',4,'markerFaceColor',cBlue,'markerEdgeColor','none'});
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_RT(SBSbtw_this.Group==grpName(2)),...
%     SBSbtw_this.sem_RT(SBSbtw_this.Group==grpName(2)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cGray,'markerSize',4,'markerFaceColor',cGray,'markerEdgeColor','none'});
idxGrp = 2;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_RT(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_RT(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
idxGrp = 1;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_RT(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_RT(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)

xlim([0.5,TS.End(thisTS)-TS.Ori(thisTS)+1.5]);
set(gca,'xtick',1:10,'ytick',0.1:0.2:1,'yticklabel',cellstr(string((0.1:0.2:1).*1000))); %grid on;
xlabel('Sessions','Fontsize',8,'FontName','Arial');
ylabel('RT (ms)','Fontsize',8,'FontName','Arial');
% title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');

% PLOT x:session, y:RT Wait2, color: Group(hM4D/EGFP)
ha42 = axes;
set(ha42, 'units', 'centimeters', 'position', [xs(2) ys(4) size1], 'nextplot', 'add','tickDir', 'out',...
    'fontsize',7,'fontname','Arial','ylim',[0.25,0.75],'ticklength', [0.02 0.025]);
ha42.YAxis.Visible = 'off';
thisTS = 2;
SBSbtw_this = SBSbtw(ismember(SBSbtw.Session,TS.Ori(thisTS):(TS.End(thisTS))),:);
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_RT(SBSbtw_this.Group==grpName(1)),...
%     SBSbtw_this.sem_RT(SBSbtw_this.Group==grpName(1)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cBlue,'markerSize',4,'markerFaceColor',cBlue,'markerEdgeColor','none'});
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_RT(SBSbtw_this.Group==grpName(2)),...
%     SBSbtw_this.sem_RT(SBSbtw_this.Group==grpName(2)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cGray,'markerSize',4,'markerFaceColor',cGray,'markerEdgeColor','none'});
idxGrp = 2;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_RT(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_RT(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
idxGrp = 1;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_RT(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_RT(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)

xlim([0.5,TS.End(thisTS)-TS.Ori(thisTS)+1.5]);
set(gca,'xtick',1:10); %grid on;
xlabel('Sessions','Fontsize',8,'FontName','Arial');
% ylabel('RT','Fontsize',8,'FontName','Arial');
% title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');

% PLOT x:session, y:RT 3FPs, color: Group(hM4D/EGFP)
ha43 = axes;
set(ha43, 'units', 'centimeters', 'position', [xs(3) ys(4) size1], 'nextplot', 'add','tickDir', 'out',...
    'fontsize',7,'fontname','Arial','ylim',[0.25,0.75],'ticklength', [0.02 0.025]);
ha43.YAxis.Visible = 'off';
thisTS = 3;
SBSbtw_this = SBSbtw(ismember(SBSbtw.Session,TS.Ori(thisTS):(TS.End(thisTS))),:);
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_RT(SBSbtw_this.Group==grpName(1)),...
%     SBSbtw_this.sem_RT(SBSbtw_this.Group==grpName(1)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cBlue,'markerSize',4,'markerFaceColor',cBlue,'markerEdgeColor','none'});
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_RT(SBSbtw_this.Group==grpName(2)),...
%     SBSbtw_this.sem_RT(SBSbtw_this.Group==grpName(2)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cGray,'markerSize',4,'markerFaceColor',cGray,'markerEdgeColor','none'});
idxGrp = 2;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_RT(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_RT(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cGray, 'markerfacecolor', cGray, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cGray, 'linewidth', 1)
idxGrp = 1;
xv = (unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1)';
yv = SBSbtw_this.mean_RT(SBSbtw_this.Group==grpName(idxGrp))';
ev = SBSbtw_this.sem_RT(SBSbtw_this.Group==grpName(idxGrp))';
plot(xv,yv,...
    'o-', 'linewidth', 1.5, 'color', cOrange, 'markerfacecolor', cOrange, 'markeredgecolor','w', 'markersize', 5);
line([xv; xv], [yv-ev;yv+ev],'color',cOrange, 'linewidth', 1)

xlim([0.5,TS.End(thisTS)-TS.Ori(thisTS)+1.5]);
set(gca,'xtick',1:10); %grid on;
xlabel('Sessions','Fontsize',8,'FontName','Arial');
% ylabel('RT','Fontsize',8,'FontName','Arial');
% title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');

% % PLOT x:session, y:RT Wait1, color: Group(hM4D/EGFP)
% ha51 = axes;
% set(ha51, 'units', 'centimeters', 'position', [xs(1) ys(5) size1], 'nextplot', 'add','tickDir', 'out',...
%     'fontsize',7,'fontname','Arial','YGrid','on','ylim',[0 1]);
% thisTS = 1;
% SBSbtw_this = SBSbtw(ismember(SBSbtw.Session,TS.Ori(thisTS):(TS.End(thisTS))),:);
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_t2cInv(SBSbtw_this.Group==grpName(1)),...
%     SBSbtw_this.sem_t2cInv(SBSbtw_this.Group==grpName(1)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cBlue,'markerSize',4,'markerFaceColor',cBlue,'markerEdgeColor','none'});
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_t2cInv(SBSbtw_this.Group==grpName(2)),...
%     SBSbtw_this.sem_t2cInv(SBSbtw_this.Group==grpName(2)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cGray,'markerSize',4,'markerFaceColor',cGray,'markerEdgeColor','none'});
% xlim([0.5,TS.End(thisTS)-TS.Ori(thisTS)+1.5]);
% set(gca,'xtick',1:10); %grid on;
% xlabel('Sessions','Fontsize',8,'FontName','Arial');
% ylabel('Stepping speed','Fontsize',8,'FontName','Arial');
% title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');
% 
% % PLOT x:session, y:RT Wait2, color: Group(hM4D/EGFP)
% ha52 = axes;
% set(ha52, 'units', 'centimeters', 'position', [xs(2) ys(5) size1], 'nextplot', 'add','tickDir', 'out',...
%     'fontsize',7,'fontname','Arial','YGrid','on','ylim',[0 1]);
% thisTS = 2;
% SBSbtw_this = SBSbtw(ismember(SBSbtw.Session,TS.Ori(thisTS):(TS.End(thisTS))),:);
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_t2cInv(SBSbtw_this.Group==grpName(1)),...
%     SBSbtw_this.sem_t2cInv(SBSbtw_this.Group==grpName(1)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cBlue,'markerSize',4,'markerFaceColor',cBlue,'markerEdgeColor','none'});
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_t2cInv(SBSbtw_this.Group==grpName(2)),...
%     SBSbtw_this.sem_t2cInv(SBSbtw_this.Group==grpName(2)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cGray,'markerSize',4,'markerFaceColor',cGray,'markerEdgeColor','none'});
% xlim([0.5,TS.End(thisTS)-TS.Ori(thisTS)+1.5]);
% set(gca,'xtick',1:10); %grid on;
% xlabel('Sessions','Fontsize',8,'FontName','Arial');
% % ylabel('1/t2c','Fontsize',8,'FontName','Arial');
% title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');
% 
% % PLOT x:session, y:RT 3FPs, color: Group(hM4D/EGFP)
% ha53 = axes;
% set(ha53, 'units', 'centimeters', 'position', [xs(3) ys(5) size1], 'nextplot', 'add','tickDir', 'out',...
%     'fontsize',7,'fontname','Arial','YGrid','on','ylim',[0 1]);
% thisTS = 3;
% SBSbtw_this = SBSbtw(ismember(SBSbtw.Session,TS.Ori(thisTS):(TS.End(thisTS))),:);
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_t2cInv(SBSbtw_this.Group==grpName(1)),...
%     SBSbtw_this.sem_t2cInv(SBSbtw_this.Group==grpName(1)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cBlue,'markerSize',4,'markerFaceColor',cBlue,'markerEdgeColor','none'});
% shadedErrorBar(unique(SBSbtw_this.Session)-TS.Ori(thisTS)+1,SBSbtw_this.mean_t2cInv(SBSbtw_this.Group==grpName(2)),...
%     SBSbtw_this.sem_t2cInv(SBSbtw_this.Group==grpName(2)),...
%     'lineProps',{'o-','linewidth',1.5,'color',cGray,'markerSize',4,'markerFaceColor',cGray,'markerEdgeColor','none'});
% xlim([0.5,TS.End(thisTS)-TS.Ori(thisTS)+1.5]);
% set(gca,'xtick',1:10); %grid on;
% xlabel('Sessions','Fontsize',8,'FontName','Arial');
% % ylabel('1/t2c','Fontsize',8,'FontName','Arial');
% title(TS.Task(thisTS),'Fontsize',9,'FontName','Arial');


% text
grp1Sbj = unique(SBS(cellfun(@(x) ~isempty(x),strfind(SBS.Group,grpName(1))),:).Subject,'stable');
grp2Sbj = unique(SBS(cellfun(@(x) ~isempty(x),strfind(SBS.Group,grpName(2))),:).Subject,'stable');

haSbj = axes('units', 'centimeters', 'position', [12.5 ys(1) 2.642 size1(2)],'Visible','off');
text(haSbj,0,1,[upper(grpName(1)),grp1Sbj'],'fontsize',6,'VerticalAlignment','top');
text(haSbj,0.5,1,[upper(grpName(2)),grp2Sbj'],'fontsize',6,'VerticalAlignment','top');
%% Save
savename = fullfile(pwd,strcat('Learning',grpName(1),'_',tarType));
saveas(hf,savename,'fig');
print(hf,'-dpng',savename);
print(hf,'-dpdf',savename,'-bestfit');
% print(hf,'-depsc2',savename);
%% performance of each animal
esti = 'Cor';
clm = [0.3,1];
Height = 8; % axes height (centimeter)
mycolormap = customcolormap([0 0.5 1], [1 1 1; 1 0 0; 0 0 0]);%Black
% mycolormap = flipud(magma);

sortSBS = sortrows(SBS,{'Group','Subject'},{'ascend','ascend'});
[sbjorder,idxSub] = unique(sortSBS.Subject,'stable');
grporder = sortSBS.Group(idxSub);
Nrats = length(unique(SBS.Subject));
Ngrp = [length(unique(SBS(SBS.Group==grpName(1),:).Subject)),length(unique(SBS(SBS.Group==grpName(2),:).Subject))];
Ntask = [length(unique(SBS(SBS.Task=="Wait1",:).Session)),length(unique(SBS(SBS.Task=="Wait2",:).Session)),length(unique(SBS(SBS.Task=="3FPs",:).Session))];

Width = (sum(Ntask)+length(Ntask))*Height./(sum(Ngrp)+length(Ngrp));

hf2 = figure(44); clf(hf2,'reset');
set(hf2, 'name', 'Learning', 'units', 'centimeters', 'position', [1 1 Width+3.8 Height+1.5],...
    'PaperPositionMode', 'auto');
hheat = axes;
set(hheat, 'units', 'centimeters','nextplot', 'add','tickDir', 'out',...
    'position',[1.8 0.8 Width,Height],...
    'xlim',[0 sum(Ntask)+length(Ntask)],...
    'xtick', [Ntask(1)/2+0.5, Ntask(1)+Ntask(2)/2+1.5, Ntask(1)+Ntask(2)+Ntask(3)/2+2.5],...
    'xticklabel',cellstr(unique(sortSBS.Task,'stable')),...
    'ylim',[0, Nrats+2],'ytick', [Ngrp(2)/2+0.5, Ngrp(2)+Ngrp(1)/2+1.5], ...
    'yticklabel', {sprintf('%s(N=%2.0d)',grpName(2), Ngrp(2)), sprintf('%s(N=%2.0d)',grpName(1), Ngrp(1))},...
    'fontsize',7,'fontname','arial','ticklength', [0.02 0.025]);
% title(['Performance: ',esti],'fontsize',9,'fontname','arial');

Nx = Ntask(1); Nxpre = 0;
curSBS = sortSBS(sortSBS.Task=="Wait1",:);
eval(['estVec = curSBS.',esti]);
val2 = reshape(estVec(curSBS.Group==grpName(2)),[Nx,length(estVec(curSBS.Group==grpName(2)))/Nx])';
val1 = reshape(estVec(curSBS.Group==grpName(1)),[Nx,length(estVec(curSBS.Group==grpName(1)))/Nx])';
% [val2,idx2] = sortrows(val2,1,'descend');
% [val1,idx1] = sortrows(val1,1,'descend');
mval2 = mean(val2,2); [~,idx2] = sort(mval2,'ascend');val2 = val2(idx2,:);
mval1 = mean(val1,2); [~,idx1] = sort(mval1,'ascend');val1 = val1(idx1,:);
h_grp2 = imagesc([Nxpre+1,Nxpre+Nx],[1,Ngrp(2)],val2,clm);
h_grp1 = imagesc([Nxpre+1,Nxpre+Nx],[1,Ngrp(1)]+Ngrp(2)+1,val1,clm);
Nxpre = Nxpre+Nx+1;
sbj2 = sbjorder(strcmp(grporder,grpName(2)));sbj2 = sbj2(idx2);
sbj1 = sbjorder(strcmp(grporder,grpName(1)));sbj1 = sbj1(idx1);
set(gca,'ytick',[1:Ngrp(2),(Ngrp(2)+2):(Ngrp(2)+1+Ngrp(1))],'yticklabel',cellstr([sbj2;sbj1]));

Nx = Ntask(2);
curSBS = sortSBS(sortSBS.Task=="Wait2",:);
eval(['estVec = curSBS.',esti]);
val2 = reshape(estVec(curSBS.Group==grpName(2)),[Nx,length(estVec(curSBS.Group==grpName(2)))/Nx])';
val1 = reshape(estVec(curSBS.Group==grpName(1)),[Nx,length(estVec(curSBS.Group==grpName(1)))/Nx])';
val2 = val2(idx2,:);
val1 = val1(idx1,:);
h_grp2 = imagesc([Nxpre+1,Nxpre+Nx],[1,Ngrp(2)],val2,clm);
h_grp1 = imagesc([Nxpre+1,Nxpre+Nx],[1,Ngrp(1)]+Ngrp(2)+1,val1,clm);
Nxpre = Nxpre+Nx+1;

Nx = Ntask(3);
curSBS = sortSBS(sortSBS.Task=="3FPs",:);
eval(['estVec = curSBS.',esti]);
val2 = reshape(estVec(curSBS.Group==grpName(2)),[Nx,length(estVec(curSBS.Group==grpName(2)))/Nx])';
val1 = reshape(estVec(curSBS.Group==grpName(1)),[Nx,length(estVec(curSBS.Group==grpName(1)))/Nx])';
val2 = val2(idx2,:);
val1 = val1(idx1,:);
h_grp2 = imagesc([Nxpre+1,Nxpre+Nx],[1,Ngrp(2)],val2,clm);
h_grp1 = imagesc([Nxpre+1,Nxpre+Nx],[1,Ngrp(1)]+Ngrp(2)+1,val1,clm);

colormap(mycolormap);
hcbar = colorbar('location', 'EastOutSide','Units', 'Centimeters','AxisLocation','in',...
    'position',[1.8+Width+0.8,0.8,0.25,Height*0.4],...
    'ytick', 0:0.2:1,'yticklabel', cellstr(string([0:0.2:1].*100)),...
    'TickDirection', 'out','ticklength', 0.02,'FontSize',7,'fontname','arial');
hcbarbel = ylabel(hcbar,[esti, ' %'],'FontSize',8,'Rotation',270,'fontname','arial',...
    'Units','Centimeters');
hcbarbel.Position(1) = hcbarbel.Position(1)+1.1;
%% Save
savename = fullfile(pwd,strcat(['Learning_Allsbj_',esti]));
saveas(hf2,savename,'fig');
print(hf2,'-dpng',savename);
% print(hf2,'-dpdf',savename,'-bestfit');
print(hf2,'-depsc2',savename);
end

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
    
    switch string(t.Task)
        case "Wait1"
            t2c = find(abs(data.FP-1.5)<1e-4,1,'first');
            if ~isempty(t2c)
                t2cInv = 46./t2c; % FP0→1.5，3*15+1 = 45；
            else
                t2c = t.nTrial;
                t2cInv = 0;
            end
        case "Wait2"
            t2c = find(abs(data.FP-1.5)<1e-4 & abs(data.RW-0.6)<1e-4,1,'first');
            if ~isempty(t2c)
                t2cInv = 46./t2c; % FP0→1.5，3*15+1 = 46；RW2.0→0.6，3*14 +1 = 43
            else
                t2c = t.nTrial;
                t2cInv = 0;
            end
        case "3FPs"
            t2c = 1;
            t2cInv = 1;
    end
    t.t2c = t2c;
    t.t2cInv = t2cInv;
    
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
