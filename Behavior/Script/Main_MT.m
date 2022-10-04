% _________________________________________________________________________
% File:               Main_MT.m
% Created on:         Sept 16, 2021
% Created by:         Yu Chen
% Last revised on:    Sept 20, 2021
% Last revised by:    Yu Chen
% _________________________________________________________________________
% The code aims to analyze movement time across sessions of one subject
% 'Gramm' plot package is needed
% 1. Put this code file to your specified folder
% 2. Run & select the bpod files you need to analyze
% 3. Selected data and result figures will be saved at current folder
% P.S. After importing selected data, you can just load data and analyze them
% by pressing "Ctrl+Enter" in "Analyze MT" code section
% _________________________________________________________________________
clear;clc;
%% Import & Save Bpod Data
[BpodData,filename,sbjname] = importdata();
c_filename = char(filename');
underline_idx = cell2mat(strfind(filename','_'));
date_idx = [underline_idx(:,3)-4,underline_idx(:,3)-1];
date = '';
for i=1:length(filename)
    date(i,:) = c_filename(i,date_idx(i,1):date_idx(i,2));
end
date = string(date);
save("BpodData_"+sbjname,'BpodData','date')
ConRunMark = 1;
%% Analyze MT
%select saved bpod data
sbjlist = {'38','40','42','63','64','65','66','67','69'};
if ~exist('ConRunMark','var') || ~ConRunMark
    sbjname = sbjlist{4}; % manual loading
end
load("BpodData_"+sbjname)

%extract MT
MT = cell(1,length(BpodData));
for i=1:length(BpodData)
    Data = BpodData{1,i}.SessionData;
    nTrials = Data.nTrials;
    sessionMT = [];
    for j=1:nTrials
        States = Data.RawEvents.Trial{1,j}.States;
        if  ~isnan(States.BriefReward(1))
        %if  isfield(BpodData{1,i}.SessionData.RawEvents.Trial{1,j}.Events,'BNC1High') %alternative way
            trialMT = States.WaitForRewardEntry(2) - States.WaitForRewardEntry(1);
        else
            trialMT = -1;
        end
        sessionMT = [sessionMT;trialMT];
    end
    MT{1,i} = sessionMT;
end
%format data
plotMT = [];
plotCat = [];
plotDate = [];
for i=1:length(MT)
    mt = MT{1,i};
    mt = mt(mt>0);
    plotMT = [plotMT;mt];
    plotCat = [plotCat;linspace(i,i,length(mt))'];
    plotDate = [plotDate;repelem(date(i),length(mt))'];
end
plotDate = cellstr(plotDate);
%plot
g(1,1) = gramm('x',plotMT,'color',plotDate);% or use plotCat
g(1,1).axe_property('XLim',[0 10],'YLim',[0,1]);
g(1,1).stat_bin('edges',0:1:10,'normalization','cdf','geom','stairs');
g(1,1).set_names('x','MT(s)','y','Cumulative Distribution','color','Date');
g(1,1).set_title("MT_Cdf_"+sbjname);
g(1,1).set_color_options('map','lch','chroma',66,'lightness',66);
% g(1,1).set_continuous_color('LCH_colormap',[0 100; 100 20;30 20]);
% don't know why can't use the method
g(1,2) = gramm('y',plotMT,'x',plotDate);
g(1,2).stat_boxplot();
g(1,2).axe_property('YLim',[0 20],'XTickLabelRotation',90);
g(1,2).set_names('x','Session#','y','MT(s)');
g(1,2).set_title("MT_Boxplot_"+sbjname);
g(1,2).set_color_options('map','lch','chroma',66,'lightness',66);
g(1,3) = gramm('y',plotMT,'x',plotDate);
custom_bootci = @(x)([mean(x);bootci(1000,{@(y) mean(y), x},'Alpha',0.05)]);% set 1000 samplings
g(1,3).stat_summary('type',custom_bootci);
g(1,3).axe_property('YLim',[0 20],'XTickLabelRotation',90);
g(1,3).set_names('x','Session#','y','MT(s)');
g(1,3).set_title("MT_95%CI_"+sbjname);
g(1,3).set_color_options('map','lch','chroma',66,'lightness',66);

figure('Position',[100 100 900 300]);
g.draw();

ConRunMark = 0; %used for ctrl+enter
%% Save Result Figures
saveas(gcf, "MT_" + sbjname, 'png');
%% Functions
function [BpodData,filename,sbjname] = importdata()
%used for importing specific Bpod data
    %acquire filepath of bpod data
    [filename,pathname] = uigetfile('*.mat','MultiSelect','on');
    sbjname = filename{1}(1:(find(filename{1}=='_',1)-1));
    filename = string(filename);
    filepath = [];
    for i=1:length(filename)
        temp = fullfile(pathname,filename(i));
        filepath = [filepath,temp];
    end
    %data packaging
    BpodData = {};
    for j = 1:length(filename)
        data = load(filepath(j),'-mat');
        BpodData{1,j} = data;
    end
end