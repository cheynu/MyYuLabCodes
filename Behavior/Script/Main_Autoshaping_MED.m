clear;clc;
rng(20221011); % Set the random seed for reproducibility of the results
rpath = pwd; % rootpath
%% Initiate
% path_functions = fullfile(rpath,'0_Functions');addpath(path_functions);
path_archive = fullfile(rpath,'1_Archive');
if ~isfolder(path_archive)
    mkdir(path_archive);
end

Subjects = {'DGS','Janni','Mala','SeCu'};
subfolder = 'Autoshaping';
plotmark = true;
%%
tarPath = {};
for i=1:length(Subjects)
    tarPath{i} = fullfile(rpath,Subjects{i},subfolder);
end
%% Extract Data
btAll2d = {}; % 'b'pod 't'able Allsessions 2d(for all subjects)
MT = cell(1,length(tarPath));
TrialType = cell(1,length(tarPath));

% Extract the raw data & packaging
for ipath=1:length(tarPath) % each subject
    dataPath = tarPath{ipath};
    cd(dataPath);
    % extract and processing
    FileNames = arrayfun(@(x)x.name, dir('*MedLick*.mat'), 'UniformOutput', false);
    
    sbjMT = {}; sbjType = {};
    for iFile=1:length(FileNames) % each session
        load(FileNames{iFile},'SessionData');
        btAll2d{ipath,iFile} = SessionData;
        
        sessionMT = []; sessionType = [];
        for iTrial=1:SessionData.nTrials % each trial
            iState = SessionData.RawEvents.Trial{1, iTrial}.States;
            if ~isnan(iState.BriefReward(1)) % valid trial (reward poke)
                trialtype = "Valid";
                if isfield(iState,'WaitForRewardEntryLight') &&...
                    ~isnan(iState.WaitForRewardEntryLight(2))
                    trialMT = iState.WaitForRewardEntryLight(2) - iState.WaitForRewardEntry(1);
                else
                    trialMT = iState.WaitForRewardEntry(2) - iState.WaitForRewardEntry(1);
                end
            else % invalid trial (no reward poke)
                trialtype = "Invalid";
                trialMT = NaN;
            end
            sessionMT(iTrial) = trialMT;
            sessionType(iTrial) = trialtype;
        end
        sbjMT{iFile} = sessionMT;
        sbjType{iFile} = sessionType;
    end
    MT{ipath} = sbjMT;
    TrialType{ipath} = sbjType;
end
save(fullfile(path_archive,'bmixedAllsbj.mat'),'btAll2d','MT','TrialType');
%% Plot MT
load(fullfile(path_archive,'bmixedAllsbj.mat'));

for iSbj=1:length(MT)
    iMT = MT{iSbj};
    sbjname = Subjects{iSbj};

    plotMT = [];
    plotCat = [];
    plotDate = [];
    for i=1:length(iMT)
        dt = datetime(btAll2d{iSbj,i}.Info.SessionStartTime_MATLAB,'ConvertFrom','datenum');
        date = string(dt,'yyyyMMdd');
        mt = iMT{1,i};
        mt = mt(~isnan(mt));
        plotMT = [plotMT;mt'];
        plotCat = [plotCat;linspace(i,i,length(mt))'];
        plotDate = [plotDate;repelem(date,length(mt))'];
    end
    plotDate = cellstr(plotDate);
    %plot, require 'grammm' package
    g(1,1) = gramm('x',plotMT,'color',plotDate);% or use plotCat
    g(1,1).axe_property('XLim',[0 10],'YLim',[0,1]);
    g(1,1).stat_bin('edges',0:1:10,'normalization','cdf','geom','stairs');
    g(1,1).set_names('x','MT(s)','y','Cumulative Distribution','color','Date');
    g(1,1).set_title("CDF");
    g(1,1).set_color_options('map','lch','chroma',66,'lightness',66);
    % g(1,1).set_continuous_color('LCH_colormap',[0 100; 100 20;30 20]);
    % don't know why can't use the method
    
    g(1,2) = gramm('y',plotMT,'x',plotDate);
    g(1,2).stat_boxplot();
    g(1,2).axe_property('YLim',[0 20],'XTickLabelRotation',90);
    g(1,2).set_names('x','Session#','y','MT(s)');
    g(1,2).set_title("Boxplot");
    g(1,2).set_color_options('map','lch','chroma',66,'lightness',66);
    
    g(1,3) = gramm('y',plotMT,'x',plotDate);
    % custom_bootci = @(x)([mean(x);bootci(1000,{@(y) mean(y), x},'Alpha',0.05)]);% set 1000 samplings
    g(1,3).stat_summary('type','95percentile','geom',{'black_errorbar','line','point'});
    % g(1,3).stat_violin('normalization','area','fill','transparent','width',0.2);
    g(1,3).geom_jitter('alpha',0.5,'width',0.5);
    g(1,3).set_point_options('base_size',3);
    g(1,3).axe_property('YLim',[0 20],'XTickLabelRotation',90);
    g(1,3).set_names('x','Session#','y','MT(s)');
    g(1,3).set_title("95%Range");
    g(1,3).set_color_options('map','lch','chroma',66,'lightness',66);
    
    g.set_title(append(sbjname,' - ','Movement Time'));
    g.set_text_options('title_scaling',1.2);
    
    h = figure('Position',[100 100 900 300]);
    g.draw();

    if isfolder(path_archive) && plotmark
%         saveas(h, fullfile(append("MT_",Subjects{iSbj})), 'png');
        print(h,append(fullfile(path_archive,append("MT_",sbjname)),'.png'),'-dpng');
    end
end

