function med_3FPsPlot_TimeGroup(btAll2d,grpVar,dateGrpVar)
%%
grpName = unique(grpVar);
altMethod = {'mean','median','geomean'};
cenMethod = altMethod{1};
errMethod = 'sem';
%% Data processing
% session by session, trial by trial: 2 packaging method
[SBS,TBT] = packData(btAll2d,grpVar,dateGrpVar,cenMethod);
% subject * group
TBTsg = [estTBT_3FPs(TBT(cellfun(@(x) ~isempty(x),strfind(TBT.Group,'Pre')),:));...
        estTBT_3FPs(TBT(cellfun(@(x) ~isempty(x),strfind(TBT.Group,'Post')),:))];
% group
TBTg = grpstats(removevars(TBTsg,{'Subject','Task'}),'Group',{cenMethod,errMethod});

% between subject group
SBSbtw = grpstats(addvars(removevars(SBS,{'Subject','Date','Task','Group'}),...
    erase(SBS.Group,{'-Pre','-Post'}),'NewVariableNames','Group'),...
    {'Group','Session'},{cenMethod,errMethod});
% subject * group
SBSsg = grpstats(removevars(SBS,{'Session','Date','Task'}),{'Subject','Group'},{cenMethod,errMethod});

save('VarsToPlot.mat','TBT','TBTsg','TBTg','SBS','SBSbtw','SBSsg');
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
set(hf, 'name', 'Lesion effect', 'units', 'centimeters', 'position', [1 1 18.542 12.5],...
    'PaperPositionMode', 'auto');

% subplot1: x:sessions, y:%, color:cor/pre/late, Lesion
ha1 = axes;
set(ha1, 'units', 'centimeters', 'position', [1.2 1 4.5 4.5*0.618], 'nextplot', 'add','tickDir', 'out',...
    'fontsize',6);
lenPre = round(TBTg.mean_nSession(find(contains(TBTg.Group,'Pre'),1))+1);
lenPost = round(TBTg.mean_nSession(find(contains(TBTg.Group,'Post'),1))-1);
% plot(unique(SBSs.Session)-lenPre,SBSs.mean_Dark(SBSs.Group==grpName(1)),'linewidth',2,'color','k');
plot(unique(SBSbtw.Session)-lenPre,SBSbtw.mean_Cor(SBSbtw.Group==grpName(1)),'linewidth',1.5,'color',cGreen);
plot(unique(SBSbtw.Session)-lenPre,SBSbtw.mean_Pre(SBSbtw.Group==grpName(1)),'linewidth',1.5,'color',cRed);
plot(unique(SBSbtw.Session)-lenPre,SBSbtw.mean_Late(SBSbtw.Group==grpName(1)),'linewidth',1.5,'color',cGray);
% errorbar(unique(SBSs.Session)-lenPre,SBSs.mean_Dark(SBSs.Group==grpName(1)),SBSs.sem_Dark(SBSs.Group==grpName(1)),'linewidth',2,'color','k');
errorbar(unique(SBSbtw.Session)-lenPre,SBSbtw.mean_Cor(SBSbtw.Group==grpName(1)),SBSbtw.sem_Cor(SBSbtw.Group==grpName(1)),'linewidth',0.8,'color',cGreen);
errorbar(unique(SBSbtw.Session)-lenPre,SBSbtw.mean_Pre(SBSbtw.Group==grpName(1)),SBSbtw.sem_Pre(SBSbtw.Group==grpName(1)),'linewidth',0.8,'color',cRed);
errorbar(unique(SBSbtw.Session)-lenPre,SBSbtw.mean_Late(SBSbtw.Group==grpName(1)),SBSbtw.sem_Late(SBSbtw.Group==grpName(1)),'linewidth',0.8,'color',cGray);
plot([-0.5,-0.5],[0,1],'k','linewidth',0.6);

le1 = legend({'Correct','Premature','Late'},'Fontsize',6,'units','centimeters','Position',[16.13,5,1,1]);% [4.7,2.8,1,1]
le1.ItemTokenSize = [12,22];
le1.Position = le1.Position + [0.025 0.045 0 0];
legend('boxoff');

% set(lemark(1:3:end),'markersize',5);

xlim([-lenPre+0.5,lenPost+0.5]);ylim([0,1]);
xlabel('Sessions','Fontsize',8);
ylabel('Probability','Fontsize',8);
title(grpName(1),'Fontsize',8);

% subplot2: x:sessions, y:%, color:cor/pre/late, Sham
ha2 = axes;
set(ha2, 'units', 'centimeters', 'position', [7 1 4.5 4.5*0.618], 'nextplot', 'add','tickDir', 'out',...
    'fontsize',6);

plot(unique(SBSbtw.Session)-lenPre,SBSbtw.mean_Cor(SBSbtw.Group==grpName(2)),'-','linewidth',1.5,'color',cGreen);
plot(unique(SBSbtw.Session)-lenPre,SBSbtw.mean_Pre(SBSbtw.Group==grpName(2)),'-','linewidth',1.5,'color',cRed);
plot(unique(SBSbtw.Session)-lenPre,SBSbtw.mean_Late(SBSbtw.Group==grpName(2)),'-','linewidth',1.5,'color',cGray);
errorbar(unique(SBSbtw.Session)-lenPre,SBSbtw.mean_Cor(SBSbtw.Group==grpName(2)),SBSbtw.sem_Cor(SBSbtw.Group==grpName(2)),'linewidth',0.8,'color',cGreen);
errorbar(unique(SBSbtw.Session)-lenPre,SBSbtw.mean_Pre(SBSbtw.Group==grpName(2)),SBSbtw.sem_Pre(SBSbtw.Group==grpName(2)),'linewidth',0.8,'color',cRed);
errorbar(unique(SBSbtw.Session)-lenPre,SBSbtw.mean_Late(SBSbtw.Group==grpName(2)),SBSbtw.sem_Late(SBSbtw.Group==grpName(2)),'linewidth',0.8,'color',cGray);
plot([-0.5,-0.5],[0,1],'k','linewidth',0.6);

xlim([-lenPre+0.5,lenPost+0.5]);ylim([0,1]);
xlabel('Sessions','Fontsize',8);
ylabel('Probability','Fontsize',8);
title(grpName(2),'Fontsize',8);

% subplot3: x:cor/pre/late * Pre/Post * Lesion/Sham, y:%, line&thickness: S/M/L
ha3 = axes;
set(ha3, 'units', 'centimeters', 'position', [12.8 1 4.5 4.5*0.618], 'nextplot', 'add','tickDir', 'out',...
    'xtick',[],'xticklabel',{},'xticklabelRotation',-45,'fontsize',6);
% 'xtick',[1.25,3.25,5.75,7.75,10.25,12.25]
plot([0.5 1.5],[TBTg.mean_Cor_S(TBTg.Group==grpName(1)+"-"+"Pre"),TBTg.mean_Cor_S(TBTg.Group==grpName(1)+"-"+"Post")],'o:','lineWidth',2,'color',cGreen,'markersize',3);
plot([0.5 1.5],[TBTg.mean_Cor_M(TBTg.Group==grpName(1)+"-"+"Pre"),TBTg.mean_Cor_M(TBTg.Group==grpName(1)+"-"+"Post")],'o--','lineWidth',1.7,'color',cGreen,'markersize',3);
plot([0.5 1.5],[TBTg.mean_Cor_L(TBTg.Group==grpName(1)+"-"+"Pre"),TBTg.mean_Cor_L(TBTg.Group==grpName(1)+"-"+"Post")],'o-','lineWidth',1.5,'color',cGreen,'markersize',3);
plot([2.5 3.5],[TBTg.mean_Cor_S(TBTg.Group==grpName(2)+"-"+"Pre"),TBTg.mean_Cor_S(TBTg.Group==grpName(2)+"-"+"Post")],'o:','lineWidth',2,'color',cGreen,'markersize',3);
plot([2.5 3.5],[TBTg.mean_Cor_M(TBTg.Group==grpName(2)+"-"+"Pre"),TBTg.mean_Cor_M(TBTg.Group==grpName(2)+"-"+"Post")],'o--','lineWidth',1.7,'color',cGreen,'markersize',3);
plot([2.5 3.5],[TBTg.mean_Cor_L(TBTg.Group==grpName(2)+"-"+"Pre"),TBTg.mean_Cor_L(TBTg.Group==grpName(2)+"-"+"Post")],'o-','lineWidth',1.5,'color',cGreen,'markersize',3);
plot([4.5 5.5],[TBTg.mean_Pre_S(TBTg.Group==grpName(1)+"-"+"Pre"),TBTg.mean_Pre_S(TBTg.Group==grpName(1)+"-"+"Post")],'o:','lineWidth',2,'color',cRed,'markersize',3);
plot([4.5 5.5],[TBTg.mean_Pre_M(TBTg.Group==grpName(1)+"-"+"Pre"),TBTg.mean_Pre_M(TBTg.Group==grpName(1)+"-"+"Post")],'o--','lineWidth',1.7,'color',cRed,'markersize',3);
plot([4.5 5.5],[TBTg.mean_Pre_L(TBTg.Group==grpName(1)+"-"+"Pre"),TBTg.mean_Pre_L(TBTg.Group==grpName(1)+"-"+"Post")],'o-','lineWidth',1.5,'color',cRed,'markersize',3);
plot([6.5 7.5],[TBTg.mean_Pre_S(TBTg.Group==grpName(2)+"-"+"Pre"),TBTg.mean_Pre_S(TBTg.Group==grpName(2)+"-"+"Post")],'o:','lineWidth',2,'color',cRed,'markersize',3);
plot([6.5 7.5],[TBTg.mean_Pre_M(TBTg.Group==grpName(2)+"-"+"Pre"),TBTg.mean_Pre_M(TBTg.Group==grpName(2)+"-"+"Post")],'o--','lineWidth',1.7,'color',cRed,'markersize',3);
plot([6.5 7.5],[TBTg.mean_Pre_L(TBTg.Group==grpName(2)+"-"+"Pre"),TBTg.mean_Pre_L(TBTg.Group==grpName(2)+"-"+"Post")],'o-','lineWidth',1.5,'color',cRed,'markersize',3);
plot([8.5 9.5],[TBTg.mean_Late_S(TBTg.Group==grpName(1)+"-"+"Pre"),TBTg.mean_Late_S(TBTg.Group==grpName(1)+"-"+"Post")],'o:','lineWidth',2,'color',cGray,'markersize',3);
plot([8.5 9.5],[TBTg.mean_Late_M(TBTg.Group==grpName(1)+"-"+"Pre"),TBTg.mean_Late_M(TBTg.Group==grpName(1)+"-"+"Post")],'o--','lineWidth',1.7,'color',cGray,'markersize',3);
plot([8.5 9.5],[TBTg.mean_Late_L(TBTg.Group==grpName(1)+"-"+"Pre"),TBTg.mean_Late_L(TBTg.Group==grpName(1)+"-"+"Post")],'o-','lineWidth',1.5,'color',cGray,'markersize',3);
plot([10.5 11.5],[TBTg.mean_Late_S(TBTg.Group==grpName(2)+"-"+"Pre"),TBTg.mean_Late_S(TBTg.Group==grpName(2)+"-"+"Post")],'o:','lineWidth',2,'color',cGray,'markersize',3);
plot([10.5 11.5],[TBTg.mean_Late_M(TBTg.Group==grpName(2)+"-"+"Pre"),TBTg.mean_Late_M(TBTg.Group==grpName(2)+"-"+"Post")],'o--','lineWidth',1.7,'color',cGray,'markersize',3);
plot([10.5 11.5],[TBTg.mean_Late_L(TBTg.Group==grpName(2)+"-"+"Pre"),TBTg.mean_Late_L(TBTg.Group==grpName(2)+"-"+"Post")],'o-','lineWidth',1.5,'color',cGray,'markersize',3);

text([0.5 1.5 2.5 3.5 4.5 5.5 6.5 7.5 8.5 9.5 10.5 11.5],repelem(-0.02,12),...
    {'Pr','Po','Pr','Po','Pr','Po','Pr','Po','Pr','Po','Pr','Po'},...
    'HorizontalAlignment','left','fontsize',6,'Rotation',-90);
grpAbbr = char(grpName);grpAbbr = cellstr(grpAbbr(:,1:2));
text([1,3,5,7,9,11],repelem(-0.16,6),{grpAbbr{1},grpAbbr{2},grpAbbr{1},grpAbbr{2},grpAbbr{1},grpAbbr{2}},'HorizontalAlignment','center','fontsize',6);
text([2,6,10],repelem(-0.25,3),{'Cor','Pre','Late'},'HorizontalAlignment','center','fontsize',7);

% le3 = legend({'Short','Medium','Long'},'fontsize',6,'units','centimeter','Position',[16.1,2.8,1,1]);
% legend('boxoff');
% le3.ItemTokenSize = [12,22];
% le3.Position = le3.Position + [0.025 0.045 0 0];

xlim([0 12]);ylim([0 1]);
ylabel('Probability','Fontsize',8);
title('Pre vs. Post','Fontsize',8);

% subplot4: LesionGroup, RT distribution, legend: S/M/L * Pre/Post
ha4 = axes;
set(ha4, 'units', 'centimeters', 'position', [1.2 5 4.5 4.5*0.618], 'nextplot', 'add','tickDir', 'out',...
    'xlim',[0,0.6],'xtick',[0 0.2 0.4 0.6],'xticklabel',{'0','200','400','600'},'fontsize',6,...
    'ylim',[0 0.3]);
% edges_RT = 0:0.05:0.6;
plot(0.025:0.05:0.575,TBTg.mean_RTdist_S(TBTg.Group==grpName(1)+"-"+"Pre",:),':','lineWidth',2,'color',cGray);
plot(0.025:0.05:0.575,TBTg.mean_RTdist_M(TBTg.Group==grpName(1)+"-"+"Pre",:),'--','lineWidth',1.7,'color',cGray);
plot(0.025:0.05:0.575,TBTg.mean_RTdist_L(TBTg.Group==grpName(1)+"-"+"Pre",:),'-','lineWidth',1.5,'color',cGray);
plot(0.025:0.05:0.575,TBTg.mean_RTdist_S(TBTg.Group==grpName(1)+"-"+"Post",:),':','lineWidth',2,'color',cOrange);
plot(0.025:0.05:0.575,TBTg.mean_RTdist_M(TBTg.Group==grpName(1)+"-"+"Post",:),'--','lineWidth',1.7,'color',cOrange);
plot(0.025:0.05:0.575,TBTg.mean_RTdist_L(TBTg.Group==grpName(1)+"-"+"Post",:),'-','lineWidth',1.5,'color',cOrange);

le4 = legend({'Short','Medium','Long'},...
    'Fontsize',6,'units','centimeters','Position',[11.95,9.3,1,1]);
legend('boxoff');
le4.ItemTokenSize = [12,22];
le4.Position = le4.Position + [0.025 0.045 0 0];

xlabel('Reaction time (ms)','Fontsize',8);
ylabel('Probability','Fontsize',8);
title(grpName(1),'Fontsize',8);

% subplot5: ShamGroup, RT distribution, legend: S/M/L * Pre/Post
ha5 = axes;
set(ha5, 'units', 'centimeters', 'position', [7 5 4.5 4.5*0.618], 'nextplot', 'add','tickDir', 'out',...
    'xlim',[0,0.6],'xtick',[0 0.2 0.4 0.6],'xticklabel',{'0','200','400','600'},'fontsize',6,...
    'ylim',[0 0.3]);
% edges_RT = 0:0.05:0.6;
plot(0.025:0.05:0.575,TBTg.mean_RTdist_S(TBTg.Group==grpName(2)+"-"+"Pre",:),':','lineWidth',2,'color',cGray);
plot(0.025:0.05:0.575,TBTg.mean_RTdist_M(TBTg.Group==grpName(2)+"-"+"Pre",:),'--','lineWidth',1.7,'color',cGray);
plot(0.025:0.05:0.575,TBTg.mean_RTdist_L(TBTg.Group==grpName(2)+"-"+"Pre",:),'-','lineWidth',1.5,'color',cGray);
plot(0.025:0.05:0.575,TBTg.mean_RTdist_S(TBTg.Group==grpName(2)+"-"+"Post",:),':','lineWidth',2,'color',cOrange);
plot(0.025:0.05:0.575,TBTg.mean_RTdist_M(TBTg.Group==grpName(2)+"-"+"Post",:),'--','lineWidth',1.7,'color',cOrange);
plot(0.025:0.05:0.575,TBTg.mean_RTdist_L(TBTg.Group==grpName(2)+"-"+"Post",:),'-','lineWidth',1.5,'color',cOrange);

% le5 = legend({'Short','Medium','Long'},...
%     'Fontsize',6,'units','centimeters','Position',[16,5.7,1,1]);%[10.3,6.8,1,1]
% legend('boxoff');
% le5.ItemTokenSize = [12,22];
% le5.Position = le5.Position + [0.025 0.045 0 0];

xlabel('Reaction time (ms)','Fontsize',8);
ylabel('Probability','Fontsize',8);
title(grpName(2),'Fontsize',8);

% subplot6: x:RT-Pre, y:RT-Post, marker:Lesion/Sham, each point a subjects
ha6 = axes;
set(ha6, 'units', 'centimeters', 'position', [12.8 5 4.5*0.618 4.5*0.618], 'nextplot', 'add','tickDir', 'out',...
   'fontsize',6,'xlim',[0.14 0.36],'ylim',[0.14 0.36],'xtick',[0.15,0.25,0.35],'xticklabel',{'150','250','350'},...
   'ytick',[0.15,0.25,0.35],'yticklabel',{'150','250','350'}); %

plot([0,0.6],[0,0.6],':k','lineWidth',0.6)
h61 = errorbar(SBSsg.mean_RTfltr(SBSsg.Group==grpName(1)+"-"+"Pre"),SBSsg.mean_RTfltr(SBSsg.Group==grpName(1)+"-"+"Post"),...
    SBSsg.sem_RTfltr(SBSsg.Group==grpName(1)+"-"+"Post"),SBSsg.sem_RTfltr(SBSsg.Group==grpName(1)+"-"+"Post"),...
    SBSsg.sem_RTfltr(SBSsg.Group==grpName(1)+"-"+"Pre"),SBSsg.sem_RTfltr(SBSsg.Group==grpName(1)+"-"+"Pre"),...
    '.','MarkerSize',12,'MarkerEdgeColor',cBlue,'color',cBlue,'lineWidth',1,'CapSize',3);
h62 = errorbar(SBSsg.mean_RTfltr(SBSsg.Group==grpName(2)+"-"+"Pre"),SBSsg.mean_RTfltr(SBSsg.Group==grpName(2)+"-"+"Post"),...
    SBSsg.sem_RTfltr(SBSsg.Group==grpName(2)+"-"+"Post"),SBSsg.sem_RTfltr(SBSsg.Group==grpName(2)+"-"+"Post"),...
    SBSsg.sem_RTfltr(SBSsg.Group==grpName(2)+"-"+"Pre"),SBSsg.sem_RTfltr(SBSsg.Group==grpName(2)+"-"+"Pre"),...
    '.','MarkerSize',12,'MarkerEdgeColor',cGray,'color',cGray,'lineWidth',1,'CapSize',3);

le6 = legend([h61,h62],{grpName(1),grpName(2)},'Fontsize',6,'units','centimeters','Position',[15.9,6.6,1,1]);
legend('boxoff');
le6.ItemTokenSize = [15,25];
le6.Position = le6.Position + [0.025 0.045 0 0];

xlabel('Pre RT (ms)','Fontsize',8);
ylabel('Post RT (ms)','Fontsize',8);

% subplot7: LesionGroup, HT distribution, legend: S/M/L * Pre/Post
ha7 = axes;
set(ha7, 'units', 'centimeters', 'position', [1.2 9 4.5 4.5*0.618], 'nextplot', 'add','tickDir', 'out',...
    'xlim',[0,2.5],'xtick',[0 0.5 1 1.5 2 2.5],'xticklabel',{'0','500','1000','1500','2000','2500'},...
    'fontsize',6,'ylim',[0 0.25]);
% edges_RT = 0:0.05:0.6;
plot(0.025:0.05:2.475,TBTg.mean_HTdist_S(TBTg.Group==grpName(1)+"-"+"Pre",:),':','lineWidth',2,'color',cGray);
plot(0.025:0.05:2.475,TBTg.mean_HTdist_M(TBTg.Group==grpName(1)+"-"+"Pre",:),'--','lineWidth',1.7,'color',cGray);
h71 = plot(0.025:0.05:2.475,TBTg.mean_HTdist_L(TBTg.Group==grpName(1)+"-"+"Pre",:),'-','lineWidth',1.5,'color',cGray);
plot(0.025:0.05:2.475,TBTg.mean_HTdist_S(TBTg.Group==grpName(1)+"-"+"Post",:),':','lineWidth',2,'color',cOrange);
plot(0.025:0.05:2.475,TBTg.mean_HTdist_M(TBTg.Group==grpName(1)+"-"+"Post",:),'--','lineWidth',1.7,'color',cOrange);
h72 = plot(0.025:0.05:2.475,TBTg.mean_HTdist_L(TBTg.Group==grpName(1)+"-"+"Post",:),'-','lineWidth',1.5,'color',cOrange);

le7 = legend([h71 h72],{'Pre','Post'},'fontsize',6,'units','centimeter','Position',[11.8,10.6,1,1]); % [4.6,6.9,1,1]
legend('boxoff');
le7.ItemTokenSize = [12,22];
le7.Position = le7.Position + [0.025 0.045 0 0];

xlabel('Press duration (ms)','Fontsize',8);
ylabel('Probability','Fontsize',8);
title(grpName(1),'Fontsize',8);

% subplot8: ShamGroup, HT distribution, legend: S/M/L * Pre/Post
ha8 = axes;
set(ha8, 'units', 'centimeters', 'position', [7 9 4.5 4.5*0.618], 'nextplot', 'add','tickDir', 'out',...
    'xlim',[0,2.5],'xtick',[0 0.5 1 1.5 2 2.5],'xticklabel',{'0','500','1000','1500','2000','2500'},...
    'fontsize',6,'ylim',[0 0.25]);
% edges_RT = 0:0.05:0.6;
plot(0.025:0.05:2.475,TBTg.mean_HTdist_S(TBTg.Group==grpName(2)+"-"+"Pre",:),':','lineWidth',2,'color',cGray);
plot(0.025:0.05:2.475,TBTg.mean_HTdist_M(TBTg.Group==grpName(2)+"-"+"Pre",:),'--','lineWidth',1.7,'color',cGray);
plot(0.025:0.05:2.475,TBTg.mean_HTdist_L(TBTg.Group==grpName(2)+"-"+"Pre",:),'-','lineWidth',1.5,'color',cGray);
plot(0.025:0.05:2.475,TBTg.mean_HTdist_S(TBTg.Group==grpName(2)+"-"+"Post",:),':','lineWidth',2,'color',cOrange);
plot(0.025:0.05:2.475,TBTg.mean_HTdist_M(TBTg.Group==grpName(2)+"-"+"Post",:),'--','lineWidth',1.7,'color',cOrange);
plot(0.025:0.05:2.475,TBTg.mean_HTdist_L(TBTg.Group==grpName(2)+"-"+"Post",:),'-','lineWidth',1.5,'color',cOrange);

xlabel('Press duration (ms)','Fontsize',8);
ylabel('Probability','Fontsize',8);
title(grpName(2),'Fontsize',8);

% text
sbjName = unique(SBS.Subject,'stable');
ha9 = axes('units', 'centimeters', 'position', [15.9 9 2.642 4.5*0.618],'Visible','off');
text(ha9,0,1,[upper(grpName(1)),sbjName(ismember(grpVar,grpName(1)))'],'fontsize',6,'VerticalAlignment','top');
text(ha9,0.5,1,[upper(grpName(2)),sbjName(ismember(grpVar,grpName(2)))'],'fontsize',6,'VerticalAlignment','top');
%% Save
savename = fullfile(pwd,'3FPsComparison_BtwWithin');
saveas(hf,savename,'fig');
print(hf,'-dpng',savename);
% print(hf,'-depsc2',savename);
end
%% Functions
function [SBS,TBT] = packData(btAll2d,grpVar,dateGrpVar,cenMethod)
SBS = table; % session by session data
TBT = table; % trial by trial data
for i=1:size(btAll2d,1)
    for j=1:size(btAll2d,2)
        T = btAll2d{i,j};
        nrow = size(T,1);
        grp1 = grpVar(i);
        if ~isempty(find(dateGrpVar{1}==j,1,'first'))
            grp2 = 'Pre';
        elseif ~isempty(find(dateGrpVar{2}==j,1,'first'))
            grp2 = 'Post';
        else
            continue;
        end
        T = addvars(T,repelem(grp1+"-"+grp2,nrow)','After','Date','NewVariableNames','Group');
        
        SBS = [SBS;estSBS(T,j,cenMethod)];
        
        nrow = size(T,1);
        if nrow>1
            tempT = addvars(T,repelem(j,nrow)','After','Date','NewVariableNames','Session');
            TBT = [TBT;tempT];
        end
    end
end
end

function outT = estSBS(data,session,cenMethod)

outT = table;
if isempty(data)
    return;
end

sbj = data.Subject(1);
task = data.Task(1);

t = struct;
t.Subject = sbj;
t.Group =data.Group(1);
t.Date = data.Date(1);
t.Session = session;
t.Task = task;
tdata = data(data.Type~=0,:); % trial data

t.nTrial = length(tdata.iTrial);
t.Dark   = sum(data.Type==0)./size(data,1);
t.Cor  = sum(tdata.Type==1)./t.nTrial;
t.Pre  = sum(tdata.Type==-1)./t.nTrial;
t.Late = sum(tdata.Type==-2)./t.nTrial;

t.Cor_S = sum(tdata.Type==1 & abs(tdata.FP-0.5)<1e-4)./sum(abs(tdata.FP-0.5)<1e-4);
t.Cor_M = sum(tdata.Type==1 & abs(tdata.FP-1.0)<1e-4)./sum(abs(tdata.FP-1.0)<1e-4);
t.Cor_L = sum(tdata.Type==1 & abs(tdata.FP-1.5)<1e-4)./sum(abs(tdata.FP-1.5)<1e-4);
t.Pre_S = sum(tdata.Type==-1 & abs(tdata.FP-0.5)<1e-4)./sum(abs(tdata.FP-0.5)<1e-4);
t.Pre_M = sum(tdata.Type==-1 & abs(tdata.FP-1.0)<1e-4)./sum(abs(tdata.FP-1.0)<1e-4);
t.Pre_L = sum(tdata.Type==-1 & abs(tdata.FP-1.5)<1e-4)./sum(abs(tdata.FP-1.5)<1e-4);
t.Late_S = sum(tdata.Type==-2 & abs(tdata.FP-0.5)<1e-4)./sum(abs(tdata.FP-0.5)<1e-4);
t.Late_M = sum(tdata.Type==-2 & abs(tdata.FP-1.0)<1e-4)./sum(abs(tdata.FP-1.0)<1e-4);
t.Late_L = sum(tdata.Type==-2 & abs(tdata.FP-1.5)<1e-4)./sum(abs(tdata.FP-1.5)<1e-4);

t.maxFP = max(tdata.FP);
t.t2mFP = find(tdata.FP==t.maxFP,1,'first');
t.minRW = min(tdata.RW);
t.t2mRW = find(tdata.RW==t.minRW,1,'first');

%     if string(taskfilter)=="Wait2"
%         t2cri = find(abs(tdata.FP-1.5)<1e-4 & abs(tdata.RW-0.6)<1e-4,1,'first');
%     else
%         t2cri = find(abs(tdata.FP-1.5)<1e-4,1,'first');
%     end
%     if isempty(t2cri)
%         t2cInv = 0;
%     elseif t2cri==1
%         t2cInv = NaN;
%     else
%         t2cInv = 1./t2cri;
%     end
%     t.t2cInv = t2cInv;

switch cenMethod
    case 'mean'
        t.HT = mean(tdata.PressDur);
        t.RT = mean(tdata(tdata.Type==1,:).RT);
        t.RTfltr = mean(tdata(tdata.Type==1 & tdata.RT>=0.1,:).RT);
    case 'median'
        t.HT = median(tdata.PressDur);
        t.RT = median(tdata(tdata.Type==1,:).RT);
        t.RTfltr = median(tdata(tdata.Type==1 & tdata.RT>=0.1,:).RT);
    case 'geomean'
        t.HT = geomean(tdata.PressDur);
        t.RT = geomean(tdata(tdata.Type==1 & tdata.RT>0,:).RT);
        t.RTfltr = geomean(tdata(tdata.Type==1 & tdata.RT>=0.1,:).RT);
end
outT = [outT;struct2table(t)];

end

function outT = estTBT_3FPs(TBT)
fplist = [0.5,1.0,1.5];

outT = table;
sbjlist = unique(TBT.Subject);

for i=1:length(sbjlist)
    data = TBT(TBT.Subject==sbjlist(i),:);

    t = struct;
    t.Subject = sbjlist(i);
    t.Group = data.Group(1);
    t.Task = data.Task(1);
    tdata = data(data.Type~=0,:); % trial data

    t.nSession = length(unique(tdata.Session));
    t.nTrial = size(tdata,1);
    t.Dark = sum(data.Type==0)./(size(data,1));

    idxFPS = abs(tdata.FP-fplist(1))<1E-4; % small
    idxFPM = abs(tdata.FP-fplist(2))<1E-4; % medium
    idxFPL = abs(tdata.FP-fplist(3))<1E-4; % large
    idxCor = tdata.Type==1;
    idxPre = tdata.Type==-1;
    idxLate = tdata.Type==-2;

    t.Cor = sum(idxCor)./t.nTrial;
    t.Pre = sum(idxPre)./t.nTrial;
    t.Late = sum(idxLate)./t.nTrial;
%         t.Perf = [...
%             sum(idxCor)./t.nTrial,...
%             sum(idxPre)./t.nTrial,...
%             sum(idxLate)./t.nTrial];
    t.Cor_S = sum( idxFPS & idxCor )./sum(idxFPS);
    t.Pre_S = sum( idxFPS & idxPre )./sum(idxFPS);
    t.Late_S = sum( idxFPS & idxLate )./sum(idxFPS);
%         t.Perf_FPS = [...
%             sum( idxFPS & idxCor )./sum(idxFPS),...
%             sum( idxFPS & idxPre )./sum(idxFPS),...
%             sum( idxFPS & idxLate )./sum(idxFPS)];
    t.Cor_M = sum( idxFPM & idxCor )./sum(idxFPM);
    t.Pre_M = sum( idxFPM & idxPre )./sum(idxFPM);
    t.Late_M = sum( idxFPM & idxLate )./sum(idxFPM);
%         t.Perf_FPM = [...
%             sum( idxFPM & idxCor )./sum(idxFPM),...
%             sum( idxFPM & idxPre )./sum(idxFPM),...
%             sum( idxFPM & idxLate )./sum(idxFPM)];
    t.Cor_L = sum( idxFPL & idxCor )./sum(idxFPL);
    t.Pre_L = sum( idxFPL & idxPre )./sum(idxFPL);
    t.Late_L = sum( idxFPL & idxLate )./sum(idxFPL);
%         t.Perf_FPL = [...
%             sum( idxFPL & idxCor )./sum(idxFPL),...
%             sum( idxFPL & idxPre )./sum(idxFPL),...
%             sum( idxFPL & idxLate )./sum(idxFPL)];

    t.RT = mean(tdata.RT(idxCor),'omitnan');
    t.RT_S = mean(tdata.RT(idxCor&idxFPS));
    t.RT_M = mean(tdata.RT(idxCor&idxFPM));
    t.RT_L = mean(tdata.RT(idxCor&idxFPL));
%         t.RT_3FPs = [mean(tdata.RT(idxCor&idxFPS)),mean(tdata.RT(idxCor&idxFPM)),mean(tdata.RT(idxCor&idxFPL))];
    edges_RT = 0:0.05:0.6;
    t.RTdist_S = smooth(histcounts(tdata.RT(idxCor&idxFPS),edges_RT,'Normalization','probability'),3)';
    t.RTdist_M = smooth(histcounts(tdata.RT(idxCor&idxFPM),edges_RT,'Normalization','probability'),3)';
    t.RTdist_L = smooth(histcounts(tdata.RT(idxCor&idxFPL),edges_RT,'Normalization','probability'),3)';

    edges_HT = 0:0.05:2.5;
    t.HTdist = histcounts(tdata.PressDur,edges_HT,'Normalization','probability');
    t.HTdist_S = smooth(histcounts(tdata.PressDur(idxFPS),edges_HT,'Normalization','probability'),3)';
    t.HTdist_M = smooth(histcounts(tdata.PressDur(idxFPM),edges_HT,'Normalization','probability'),3)';
    t.HTdist_L = smooth(histcounts(tdata.PressDur(idxFPL),edges_HT,'Normalization','probability'),3)';

    outT = [outT;struct2table(t)];
end

end