function LesionGroupAnalysisWithClass(LesionedRats, DataDirectory, LesionType, subFolder, params)

% to analysis group data from a lesion type
% under each ANM folder, there should be a structure called
% LesionEffect_NAME.mat
% this function will read this data and extract useful information. 
% e.g., 

%%%% Example Script: %%%%%%%
% set_matlab_default;
% 
% LesionedRats = {
%     'Africa'               '2021-09-08_13h46m_Subject Africa'  % check
%     'America'           '2021-09-08_13h46m_Subject America' % check
%     'Asia'                  '2021-09-08_13h46m_Subject Asia' % check
%     'Gardner'           '2021-02-27_15h26m_Subject Gardner' % check
%     'Gilbert'              '2020-09-26_16h11m_Subject Gilbert' % check
%     'Lyla'                      '2021-05-25_10h01m_Subject Lyla' % check
%     'Ruben'                 '2021-05-25_10h01m_Subject Ruben' % check
%     'Susie'                    '2020-12-15_18h07m_Subject Susie'    % check
%     'Winter'                 '2022-06-16_14h43m_Subject Winter' % check
%     'Summer'               '2022-06-13_14h48m_Subject Summer' % check
%     'Spring'                    '2022-06-16_14h43m_Subject Spring'  % check
%     };
% 
% Datapath = 'C:\Users\jiani\OneDrive\00_Work\03_Projects\03_LesionData\Results\DLS_Lesion\ANMs';
% LesionType = 'Unilateral DLS';
% LesionGroupAnalysis(LesionedRats, Datapath, LesionType)
% Jianing Yu 8/31/2022

arguments
    LesionedRats
    DataDirectory
    LesionType
    subFolder = ''
    params.periLesion = [-5:6]
    params.corLim = [40 100]
    params.preLim = [0 60]
    params.lateLim = [0 60]
    params.rtLim = [200 1000] % Figure DaybyDay
    params.rtLim2 = [250 450] % Figure 3FPs
    params.pdfLim = [0 5]
    params.diffLim = [-3 1]
end

% collect behavior data from all animals, 5 sessions pre and post lesion
% for each rat
Nrat = size(LesionedRats, 1);
FPs = [500 1000 1500];

CorrectScore = zeros(length(FPs)+1, size(LesionedRats, 1)); 
PrematureScore = zeros(length(FPs)+1, size(LesionedRats, 1));
LateScore = zeros(length(FPs)+1, size(LesionedRats, 1));
RTLoose=zeros(length(FPs)+1, size(LesionedRats, 1)); 

% Extract the following sessions
PeriLesion = params.periLesion;
PeriLesionLabels = {};
for k =1:length(PeriLesion)
    if PeriLesion(k)<0
        PeriLesionLabels{k} = ['', num2str(PeriLesion(k))];
    else
        PeriLesionLabels{k} = ['', num2str(1+PeriLesion(k))];
    end;
end;

%% Extract data from each rat 
bTableAllTrials = [];
bDataClass = cell(size(LesionedRats, 1), length(PeriLesion));

for i =1:size(LesionedRats, 1)    
    irat = LesionedRats{i, 1};
    disp(irat)
%     bload = load(fullfile(DataDirectory, irat, ['LesionEffect_' upper(irat) '.mat']));
%     bAllFPsBpod = bload.bAllFPsBpod; 
    % all sessions
    load(fullfile(DataDirectory, irat, subFolder, ['BClassArrayLesion_' upper(irat) '.mat']))
    load(fullfile(DataDirectory, irat, subFolder, ['LesionEffect_' upper(irat) '.mat']));

    allSessions = cellfun(@(x)x.Session, BClassArray, 'UniformOutput', false)';
    lesionIndex = cell2mat(cellfun(@(x)x.LesionIndex, BClassArray, 'UniformOutput', false)');
    % check the session of post-lesion day 1
    indPostLesion = find(lesionIndex>0, 1, 'first');

    if ~isempty(indPostLesion)
        for j =1:length(PeriLesion)
            if PeriLesion(j)>=0
                jj = PeriLesion(j)+1;
            else
                jj = PeriLesion(j);
            end;

            bc = BClassArray{indPostLesion + PeriLesion(j)};
            bc.LesionType = LesionType;
            bDataClass{i, j} = bc;

            bdata = bAllFPsBpod(indPostLesion + PeriLesion(j));
            b_table           =       turn_bdata2table(bdata); % turn_bdata turns bdata into a usable table.
            b_table.LesionIndex = jj*ones(size(b_table.LesionIndex));

            if isempty(bTableAllTrials)
                bTableAllTrials = b_table;
            else
                bTableAllTrials = [bTableAllTrials; b_table];
            end;
            for k =1:length(FPs)
               indk = (cellfun(@(c)isequal(c, bc.MixedFP(k)), bc.Performance.Foreperiod));
                CorrectScore(k, i, j) = bc.Performance.CorrectRatio(indk);
                PrematureScore(k, i, j) = bc.Performance.PrematureRatio(indk);
                LateScore(k, i, j) = bc.Performance.LateRatio(indk);
                RTLoose(k, i, j) = bc.AvgRTLoose.RT_median_ksdensity(indk);
            end;
            % overall
            k = k+1;
            indk = (cellfun(@(c)strcmp(c, 'all'), bc.Performance.Foreperiod));
            CorrectScore(k, i, j) = bc.Performance.CorrectRatio(indk);
            PrematureScore(k, i, j) = bc.Performance.PrematureRatio(indk);
            LateScore(k, i, j) = bc.Performance.LateRatio(indk);
            RTLoose(k, i, j) = bc.AvgRTLoose.RT_median_ksdensity(indk);
        end;
    else
        error('Check')
    end;
end;


    
% Perform analysis on 500 trials before and after lesion. 

RTAccum         =       cell(size(LesionedRats, 1), 3); % Col1, Press duration(pre), Col2, Press duration (post), Col3,  FP ( 500, 1000, 1500) warmup not included. 
N_included     =       500;

for i =1:size(LesionedRats, 1)    

    irat = LesionedRats{i, 1};
    disp(irat)
    iDataClassArray = bDataClass(i, :);
    % Track pre-lesion sessions
    indLesion                                 =       [];
    PreLesion_PressDurConc      =       [];
    FPConc                                     =        [];
    OutcomeConc                         =        {};
    IndLesion        =     find(cellfun(@(x)x.LesionIndex, iDataClassArray)==1); 
    for j = 1:IndLesion-1
        bcj                                           =       iDataClassArray{j};
        ind_over                                 =       find(bcj.FP>=1500, 1, 'first');
        indLesion                                =       [indLesion repmat(bcj.LesionIndex, 1, (length(bcj.FP) - ind_over+1))];
        PreLesion_PressDurConc     =       [PreLesion_PressDurConc (bcj.ReleaseTime(ind_over:end)-bcj.PressTime(ind_over:end))];
        FPConc                                     =       [FPConc (bcj.FP(ind_over:end))];
        OutcomeConc                         =       [OutcomeConc, (bcj.Outcome(ind_over:end))];
    end;
    indLesion                                      =      fliplr(indLesion);
    PreLesion_PressDurConc          =       fliplr(PreLesion_PressDurConc);
    FPConc                                          =       fliplr(FPConc);
    OutcomeConc                              =       fliplr(OutcomeConc); 
    RTConc = 1000*PreLesion_PressDurConc - FPConc;
    RTConc_med = median(RTConc);
    RTConc_ipr   = diff(prctile(RTConc, [25, 75]));
    RT_Outliers     = RTConc_med +[-1 1]*RTConc_ipr*5;
    ind_included =  find(~strcmp(OutcomeConc, 'Dark') & RTConc<RT_Outliers(2) & RTConc>RT_Outliers(1));
    % extract 500 trials
    RTAccum{i, 1} = RTConc(ind_included(1:N_included));
    RTAccum{i, 2} = FPConc(ind_included(1:N_included));
    RTAccum{i, 3} = OutcomeConc(ind_included(1:N_included));
    RTAccum{i, 4} = indLesion(ind_included(1:N_included));
    % Track post lesion sessions

    indLesion                                 =       [];
    PostLesion_PressDurConc      =       [];
    FPConc                                     =        [];
    OutcomeConc                         =        {};

    for j = IndLesion:size(bDataClass, 2)
        bcj                                           =       iDataClassArray{j};
        ind_over                                 =       find(bcj.FP>=1500, 1, 'first');
        if ~isempty(ind_over)
            indLesion                                =       [indLesion repmat(bcj.LesionIndex, 1, (length(bcj.FP) - ind_over+1))];
            PostLesion_PressDurConc     =       [PostLesion_PressDurConc (bcj.ReleaseTime(ind_over:end)-bcj.PressTime(ind_over:end))];
            FPConc                                     =       [FPConc (bcj.FP(ind_over:end))];
            OutcomeConc                         =       [OutcomeConc, (bcj.Outcome(ind_over:end))];
        end;
    end;

    % No need to flip the data 

    RTConc = 1000*PostLesion_PressDurConc - FPConc;
    RTConc_med = median(RTConc);
    RTConc_ipr   = diff(prctile(RTConc, [25, 75]));
    RT_Outliers     = RTConc_med +[-1 1]*RTConc_ipr*5;

    ind_included =  find(~strcmp(OutcomeConc, 'Dark') & RTConc<RT_Outliers(2) & RTConc>RT_Outliers(1));

    % extract 500 trials
    RTAccum{i, 5} = RTConc(ind_included(1:N_included));
    RTAccum{i, 6} = FPConc(ind_included(1:N_included));
    RTAccum{i, 7} = OutcomeConc(ind_included(1:N_included));
    RTAccum{i, 8} = indLesion(ind_included(1:N_included));

end;

%% start plotting
ratio = Nrat/length(PeriLesion); % this is used for colorplots. each pixel needs to be a square

hf = figure(29); clf
set(gcf, 'unit', 'centimeters', 'position',[2 2 32 7.5+4*ratio+3], 'paperpositionmode', 'auto',...
    'renderer','Painters' )

% some colors to pick from 
cControl = [0 0 0];
cControlShade = [207 210 207]/255;
cLesion =[255, 178, 0]/255;
cLesionShade = [255 203 66]/255;

col_perf = [85 225 0; 255 0 0; 140 140 140]/255;
overal_col = [50 50 50]/255;

row_height = [2+4*ratio+1 2 NaN 6.5+4*ratio+1];

% orange-white-purple
% mycolormap = customcolormap(linspace(0,1,11), {'#7f3c0a','#b35807','#e28212','#f9b967','#ffe0b2','#f7f7f5','#d7d9ee','#b3abd2','#8073a9','#562689','#2f004d'});

% # red yellow blue
mycolormap = customcolormap(linspace(0,1,11), {'#a60026','#d83023','#f66e44','#faac5d','#ffdf93','#ffffbd','#def4f9','#abd9e9','#73add2','#4873b5','#313691'});


%% Plot correct
ha1 =  axes('unit', 'centimeters', 'position', [2 row_height(1) 4 3], 'nextplot', 'add', 'xlim', [PeriLesion(1)-0.5 PeriLesion(end)+0.5], 'ylim', params.corLim,...
    'ytick', [0:20:100], 'xtick', [PeriLesion(1):PeriLesion(end)], 'xticklabels', PeriLesionLabels, 'ticklength', [0.02, 1],  'XTickLabelRotation', 0);
jitter = [-0.1 0 0.1 0];

for i = 1:size(CorrectScore, 1)  % FP
    if i<4
        score = squeeze(CorrectScore(i, :, :));
        mean_score = mean(score, 1, 'omitnan');
        se_score       = std(score, 0, 1, 'omitnan')/sqrt(Nrat);
        for k = 1:length(mean_score)
            line(PeriLesion([k k])+jitter(i), [-1 1]*se_score(k)+mean_score(k), 'color', col_perf(1, :), 'linewidth', 0.5*i);
        end;
        plot(PeriLesion+jitter(i), mean_score, 'color',  col_perf(1, :), 'linewidth', 0.5*i)
    else
        score = squeeze(CorrectScore(i, :, :));
        mean_score = mean(score, 1, 'omitnan');
        se_score       = std(score, 0, 1, 'omitnan')/sqrt(Nrat);
        for k = 1:length(mean_score)
            line(PeriLesion([k k])+jitter(i), [-1 1]*se_score(k)+mean_score(k), 'color', overal_col, 'linewidth', 2);
        end;
        plot(PeriLesion+jitter(i), mean_score, 'color',  overal_col, 'linewidth', 2)
    end;
end;

line([-.5 -.5], params.corLim, 'color', [0.5 0.5 0.5], 'linestyle', '--', 'linewidth', 1)

ylabel('(%)')
title('Correct')
text(PeriLesion(1), params.corLim(1)+diff(params.corLim)/5, sprintf('N = %2.0d', size(LesionedRats, 1)))

%% Plot all rats in colormap
% score = squeeze(CorrectScore(2, :,:));
ha1b =  axes('unit', 'centimeters', 'position', [2  row_height(2) 4 4*ratio], ...
    'nextplot', 'add', 'xlim', [PeriLesion(1)-0.5 PeriLesion(end)+0.5], 'ylim', [0.5 Nrat+0.5],...
    'ytick', [0:4:Nrat], 'xtick', [PeriLesion(1):PeriLesion(end)], 'xticklabels', PeriLesionLabels, 'ticklength', [0.02, 1], ...
    'XTickLabelRotation', 0);
ylabel('Rat #')
% diff between pre and recovered 
ind_prelesion = PeriLesion<0;
PreLesion_Performance = mean(score(:, ind_prelesion), 2);
PreLesion_STD = std(score(:, ind_prelesion), 0, 2);
score_z = (score-repmat(PreLesion_Performance, 1, size(score, 2)))./PreLesion_STD;

ind_postlesion = PeriLesion>=4;
PostLesion_Performance = mean(score(:, ind_postlesion), 2);
DiffPerformance = PostLesion_Performance - PreLesion_Performance;
[~, indsort] = sort(DiffPerformance); % rearrange these rats, from bad to good recovery
score_sort = score_z(indsort, :);
himg = imagesc(PeriLesion, [1:Nrat], score_sort, [-15 15]);
line([0 0]-0.5, [0 Nrat+0.5], 'color', [0.75 0.75 0.75], 'linestyle', '--', 'linewidth', 1)
% mycolormap = customcolormap([0 0.5 1], [1 1 1; 1 0 0; 0 0 0]);
% hcbar = colorbar('location', 'EastOutSide','Units', 'Centimeters', 'Position', [6.25, 5.5, 0.25, 4*size(score, 1)/size(score, 2)]);
% hcbar.Label.String = 'Z score';
colormap(mycolormap);
ylabel('Rats')
xlabel('Sessions ')

%% Plot premature 
ha2 =  axes('unit', 'centimeters', 'position', [7.5  row_height(1) 4 3], 'nextplot', 'add',  'xlim', [PeriLesion(1)-0.5 PeriLesion(end)+0.5], 'ylim', params.preLim,...
    'ytick', [0:20:100], 'xtick', [PeriLesion(1):PeriLesion(end)], 'xticklabels', PeriLesionLabels, 'ticklength', [0.02, 1],  'XTickLabelRotation', 0);

for i = 1:size(PrematureScore, 1)  % FP
    if i<4
        score = squeeze(PrematureScore(i, :, :));
        mean_score = mean(score, 1, 'omitnan');
        se_score       = std(score, 0, 1, 'omitnan')/sqrt(Nrat);
        for k = 1:length(mean_score)
            line(PeriLesion([k k])+jitter(i), [-1 1]*se_score(k)+mean_score(k), 'color', col_perf(2, :), 'linewidth', 0.5*i);
        end;
        plot(PeriLesion+jitter(i), mean_score, 'color',  col_perf(2, :), 'linewidth', 0.5*i)
    else
        score = squeeze(PrematureScore(i, :, :));
        mean_score = mean(score, 1, 'omitnan');
        se_score       = std(score, 0, 1, 'omitnan')/sqrt(Nrat);
        for k = 1:length(mean_score)
            line(PeriLesion([k k])+jitter(i), [-1 1]*se_score(k)+mean_score(k), 'color', overal_col, 'linewidth', 2);
        end;
        plot(PeriLesion+jitter(i), mean_score, 'color',  overal_col, 'linewidth', 2)
    end;
end;

line([-.5 -.5], params.preLim, 'color', [0.5 0.5 0.5], 'linestyle', '--', 'linewidth', 1)

ylabel('(%)')
title('Premature')
%% Plot all rats in colormap
ha2b =  axes('unit', 'centimeters', 'position', [7.5 row_height(2) 4 4*ratio], 'nextplot', 'add', 'xlim', [PeriLesion(1)-0.5 PeriLesion(end)+0.5], 'ylim', [0.5 Nrat+0.5],...
    'ytick', [0:4:Nrat], 'xtick', [PeriLesion(1):PeriLesion(end)], 'xticklabels', PeriLesionLabels, 'ticklength', [0.02, 1], ...
    'XTickLabelRotation', 0);
ylabel('Rat #')
% diff between pre and recovered 
ind_prelesion = PeriLesion<0;
PreLesion_Performance = mean(score(:, ind_prelesion), 2);
PreLesion_STD = std(score(:, ind_prelesion), 0, 2);
score_z = (score-repmat(PreLesion_Performance, 1, size(score, 2)))./PreLesion_STD;

ind_postlesion = PeriLesion>=4;
PostLesion_Performance = mean(score(:, ind_postlesion), 2);
DiffPerformance = PostLesion_Performance - PreLesion_Performance;
% [~, indsort] = sort(DiffPerformance); % rearrange these rats, from bad to good recovery
score_sort = score_z(indsort, :);
himg = imagesc(PeriLesion, [1:Nrat], score_sort, [-15 15]);
line([0 0]-0.5, [0 Nrat+0.5], 'color', [0.75 0.75 0.75], 'linestyle', '--', 'linewidth', 1)
% mycolormap = customcolormap(linspace(0,1,11), {'#a60026','#d83023','#f66e44','#faac5d','#ffdf93','#ffffbd','#def4f9','#abd9e9','#73add2','#4873b5','#313691'});
colormap(mycolormap);
% hcbar2 = colorbar('location', 'EastOutSide','Units', 'Centimeters', 'Position', [11.75, 5.5, 0.25, 4*size(score, 1)/size(score, 2)]);
% hcbar2.Label.String = 'Z score';

 xlabel('Sessions ')
%% Plot late 
ha3 =  axes('unit', 'centimeters', 'position', [13  row_height(1) 4 3], 'nextplot', 'add',  'xlim', [PeriLesion(1)-0.5 PeriLesion(end)+0.5], 'ylim', params.lateLim,...
    'ytick', [0:20:100], 'xtick', [PeriLesion(1):PeriLesion(end)], 'xticklabels', PeriLesionLabels, 'ticklength', [0.02, 1],  'XTickLabelRotation', 0);

for i = 1:size(LateScore, 1)  % FP
    if i<4
        score = squeeze(LateScore(i, :, :));
        mean_score = mean(score, 1, 'omitnan');
        se_score       = std(score, 0, 1, 'omitnan')/sqrt(Nrat);
        for k = 1:length(mean_score)
            line(PeriLesion([k k])+jitter(i), [-1 1]*se_score(k)+mean_score(k), 'color', col_perf(3, :), 'linewidth', 0.5*i);
        end;
        plot(PeriLesion+jitter(i), mean_score, 'color',  col_perf(3, :), 'linewidth', 0.5*i)
    else
        score = squeeze(LateScore(i, :, :));
        mean_score = mean(score, 1, 'omitnan');
        se_score       = std(score, 0, 1, 'omitnan')/sqrt(Nrat);
        for k = 1:length(mean_score)
            line(PeriLesion([k k])+jitter(i), [-1 1]*se_score(k)+mean_score(k), 'color', overal_col, 'linewidth', 2);
        end;
        plot(PeriLesion+jitter(i), mean_score, 'color',  overal_col, 'linewidth', 2)
    end;
end;

line([-.5 -.5], params.lateLim, 'color', [0.5 0.5 0.5], 'linestyle', '--', 'linewidth', 1)

ylabel('(%)')
 title('Late')
%% Plot all rats in colormap
ha3b =  axes('unit', 'centimeters', 'position', [13  row_height(2) 4 4*ratio], 'nextplot', 'add', 'xlim', [PeriLesion(1)-0.5 PeriLesion(end)+0.5], 'ylim', [0.5 Nrat+0.5],...
    'ytick', [0:4:Nrat], 'xtick', [PeriLesion(1):PeriLesion(end)], 'xticklabels', PeriLesionLabels, 'ticklength', [0.02, 1], ...
    'XTickLabelRotation', 0);
ylabel('Rat #')
% diff between pre and recovered 
ind_prelesion = PeriLesion<0;
PreLesion_Performance = mean(score(:, ind_prelesion), 2);
PreLesion_STD = std(score(:, ind_prelesion), 0, 2);
score_z = (score-repmat(PreLesion_Performance, 1, size(score, 2)))./PreLesion_STD;

ind_postlesion = PeriLesion>=4;
PostLesion_Performance = mean(score(:, ind_postlesion), 2);
DiffPerformance = PostLesion_Performance - PreLesion_Performance;
% [~, indsort] = sort(DiffPerformance); % rearrange these rats, from bad to good recovery
score_sort = score_z(indsort, :);
himg = imagesc(PeriLesion, [1:Nrat], score_sort, [-15 15]);
line([0 0]-0.5, [0 Nrat+0.5], 'color', [0.75 0.75 0.75], 'linestyle', '--', 'linewidth', 1)
% mycolormap = customcolormap(linspace(0,1,11), {'#a60026','#d83023','#f66e44','#faac5d','#ffdf93','#ffffbd','#def4f9','#abd9e9','#73add2','#4873b5','#313691'});
colormap(mycolormap);
hcbar2 = colorbar('location', 'EastOutSide','Units', 'Centimeters', 'Position', [17.25, row_height(2), 0.25, 4*size(score, 1)/size(score, 2)]);
hcbar2.Label.String = 'Z score';
xlabel('Sessions ')
%% plot reaction time

rt_col = [39 123 192]/255;
ha4 =  axes('unit', 'centimeters', 'position', [19.5  row_height(1) 4 3], 'nextplot', 'add',  'xlim', [PeriLesion(1)-0.5 PeriLesion(end)+0.5], 'ylim', params.rtLim,...
    'ytick', [200  400   800 ],'yscale', 'log', 'xtick', [PeriLesion(1):PeriLesion(end)], 'xticklabels', PeriLesionLabels, 'ticklength', [0.02, 1],  'XTickLabelRotation', 0);

for i = 4% 1:size(RTLoose, 1)  % FP
%     if i<4
%         rt = squeeze(RTLoose(i, :, :));
%         mean_rt = mean(rt, 1, 'omitnan');
%         se_rt       = std(rt, 0, 1, 'omitnan')/sqrt(Nrat);
%         for k = 1:length(mean_score)
%             line(PeriLesion([k k])+jitter(i), [-1 1]*se_rt(k)+mean_rt(k), 'color', rt_col, 'linewidth', 0.5*i);
%         end;
%         plot(PeriLesion+jitter(i), mean_rt, 'color',  rt_col, 'linewidth', 0.5*i)
%     else
        rt = squeeze(RTLoose(i, :, :));
        mean_rt = mean(rt, 1, 'omitnan');
        se_rt       = std(rt, 0, 1, 'omitnan')/sqrt(Nrat);
        for k = 1:length(mean_rt)
            line(PeriLesion([k k])+jitter(i), [-1 1]*se_rt(k)+mean_rt(k), 'color', rt_col, 'linewidth', 2);
        end;
        plot(PeriLesion+jitter(i), mean_rt, 'color',  rt_col, 'linewidth', 2)
        %     end;
end;

line([-.5 -.5], get(ha4, 'ylim'), 'color', [0.5 0.5 0.5], 'linestyle', '--', 'linewidth', 1)

ylabel('Reaction time (ms)')

%% Plot all rats in colormap
ha4b =  axes('unit', 'centimeters', 'position', [19.5  row_height(2) 4 4*ratio], 'nextplot', 'add', 'xlim', [PeriLesion(1)-0.5 PeriLesion(end)+0.5], 'ylim', [0.5 Nrat+0.5],...
    'ytick', [0:4:Nrat], 'xtick', [PeriLesion(1):PeriLesion(end)], 'xticklabels', PeriLesionLabels, 'ticklength', [0.02, 1], ...
    'XTickLabelRotation', 0);
ylabel('Rat #')
% diff between pre and recovered 

ind_prelesion = PeriLesion<0;
PreLesion_Performance = mean(rt(:, ind_prelesion), 2);
PreLesion_STD = std(rt(:, ind_prelesion), 0, 2);
rt_z = (rt-repmat(PreLesion_Performance, 1, size(rt, 2)))./PreLesion_STD;

ind_postlesion = PeriLesion>=4;
PostLesion_Performance = mean(score(:, ind_postlesion), 2);
DiffPerformance = PostLesion_Performance - PreLesion_Performance;
% [~, indsort] = sort(DiffPerformance); % rearrange these rats, from bad to good recovery
rt_sort = rt_z(indsort, :);
himg = imagesc(PeriLesion, [1:Nrat], rt_sort, [-15 15]);
line([0 0]-0.5, [0 Nrat+0.5], 'color', [0.75 0.75 0.75], 'linestyle', '--', 'linewidth', 1)
% mycolormap = customcolormap(linspace(0,1,11), {'#a60026','#d83023','#f66e44','#faac5d','#ffdf93','#ffffbd','#def4f9','#abd9e9','#73add2','#4873b5','#313691'});
colormap(mycolormap);
hcbar2 = colorbar('location', 'EastOutSide','Units', 'Centimeters', 'Position', [23.75, row_height(2), 0.25, 4*size(score, 1)/size(score, 2)]);
hcbar2.Label.String = 'Z score';

xlabel('Sessions ')

%% Work on release time distribution
% use 500 trials before and after lesions to perform this analysis. 
% We have defined these colors:
% cControl = [0 0 0];
% cControlShade = [207 210 207]/255;
% cLesion =[255, 178, 0]/255;
% cLesionShade = [255 203 66]/255;

binEdges = [0:20:2000];
binCenters = (binEdges(1:end-1)+binEdges(2:end))/2;

% ha4 =  axes('unit', 'centimeters', 'position', [19.5  row_height(1) 4 3], 'nextplot', 'add',  'xlim', [PeriLesion(1)-0.5 PeriLesion(end)+0.5], 'ylim', params.rtLim,...
%     'ytick', [200 300 400 500 600 800 1000],'yscale', 'log', 'xtick', [PeriLesion(1):PeriLesion(end)], 'xticklabels', PeriLesionLabels, 'ticklength', [0.02, 1],  'XTickLabelRotation', 0);
ha5 =  axes('unit', 'centimeters', 'position', [26  row_height(1)+2 4 2], 'nextplot', 'add', ...
    'xlim', [0 1000], 'ylim', params.pdfLim,...
    'ytick', params.pdfLim(1):2:params.pdfLim(2), 'xtick', [0:200:2000], 'xticklabel', [], 'ticklength', [0.02, 1], ...
    'XTickLabelRotation', 0);

ylabel('PDF (1e-3/ms)')

RTDist = zeros(4, length(binCenters), Nrat, 2); % 3 FP, + 1 overal , Nrat, + pre/post
RTCDF = zeros(4, length(binCenters), Nrat, 2); 
RTFixedTrials = zeros(4, Nrat, 2);

for i =1:Nrat
    for k = 1:length(FPs)
        % prelesion
        % RT_ik: all release time for one FP for one rat(rat i). Late
        % trials included. 
        RT_ik = RTAccum{i, 1}(~strcmp(RTAccum{i, 3}, 'Premature') & RTAccum{i, 2}==FPs(k));
        RTOut =  calRT(RT_ik, [], 'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
        RTFixedTrials(k, i, 1) = RTOut.median_ksdensity;
        % use ksdensity to derive the probability density function, who has
        % an unit of 1/ms (note, integration of pdf over time gives
        % probability)
        [f, ~] = ksdensity(RT_ik, binCenters);
        [fcdf, ~] = ksdensity(RT_ik, binCenters, 'function', 'cdf');
        RTDist(k, :, i, 1) = f;
        RTCDF(k, :, i, 1) = fcdf;
        % postlesion
        RT_ik = RTAccum{i, 5}(~strcmp(RTAccum{i, 7}, 'Premature') & RTAccum{i, 6}==FPs(k));
        [f, ~] = ksdensity(RT_ik, binCenters);
        [fcdf, ~] = ksdensity(RT_ik, binCenters, 'function', 'cdf');
        RTDist(k, :, i,  2) = f;
        RTCDF(k, :, i,  2) = fcdf;
        RTOut =  calRT(RT_ik, [], 'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
        RTFixedTrials(k, i, 2) = RTOut.median_ksdensity;
    end;
    % prelesion
    k = k+1;
    RT_ik = RTAccum{i, 1}(~strcmp(RTAccum{i, 3}, 'Premature'));
    [f, ~] = ksdensity(RT_ik, binCenters);
    [fcdf, ~] = ksdensity(RT_ik, binCenters, 'function', 'cdf');
    RTDist(k, :, i, 1) = f;
    RTCDF(k, :, i, 1) = fcdf;
    RTOut =  calRT(RT_ik, [], 'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
    RTFixedTrials(k, i, 1) = RTOut.median_ksdensity;
    % postlesion
    RT_ik = RTAccum{i, 5}(~strcmp(RTAccum{i, 7}, 'Premature'));
    [f, ~] = ksdensity(RT_ik, binCenters);
    [fcdf, ~] = ksdensity(RT_ik, binCenters, 'function', 'cdf');
    RTDist(k, :, i, 2) = f;
    RTCDF(k, :, i, 2) = fcdf;
    RTOut =  calRT(RT_ik, [], 'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
    RTFixedTrials(k, i, 2) = RTOut.median_ksdensity;
end;

RTDist_PreAvg = mean(squeeze(RTDist(4, :, :, 1)), 2);
RTDist_PreSE = std(squeeze(RTDist(4, :, :, 1)), 0,  2)/sqrt(Nrat);
RTDist_PostAvg = mean(squeeze(RTDist(4, :, :, 2)), 2);
RTDist_PostSE = std(squeeze(RTDist(4, :, :, 2)), 0,  2)/sqrt(Nrat);

plotshaded([0 600], [0 0; max(get(ha5, 'ylim')) max(get(ha5, 'ylim'))], [0.2 0.8 0.2], 0.25)
plotshaded(binCenters, 1000*[RTDist_PreAvg-RTDist_PreSE RTDist_PreAvg+RTDist_PreSE]',cControlShade, 0.75)
plotshaded(binCenters, 1000*[RTDist_PostAvg-RTDist_PostSE RTDist_PostAvg+RTDist_PostSE]',  cLesionShade, 0.75)
plot(binCenters, 1000*RTDist_PreAvg, 'color', cControl, 'linewidth', 1.5)
plot(binCenters, 1000*RTDist_PostAvg, 'color', cLesion, 'linewidth', 1.5)

% Plot difference
ha5b =  axes('unit', 'centimeters', 'position', [26  row_height(1) 4 1.5], 'nextplot', 'add', ...
    'xlim', [0 1000], 'ylim', params.diffLim,...
    'ytick', [-4:2:4], 'xtick', [0:200:2000], 'ticklength', [0.02, 1], ...
    'XTickLabelRotation', 0);
ylabel('Diff')
cDiff = [49 32 224]/255;
cDiffShade = [59 154 225]/255;

i = 4;
RTDist_PreAllRats = squeeze(RTDist(i, :, :, 1));  % size: 100 x Nrat
RTDist_PostAllRats = squeeze(RTDist(i, :, :, 2));  % size: 100 x Nrat
RTDist_Diff = RTDist_PostAllRats - RTDist_PreAllRats;

RTDistDiff_Avg = 1000*mean(RTDist_Diff, 2);
RTDistDiff_SE = 1000*std(RTDist_Diff, 0,  2)/sqrt(Nrat);

plotshaded([0 600], [min(get(ha5b, 'ylim')) min(get(ha5b, 'ylim')); max(get(ha5b, 'ylim')) max(get(ha5b, 'ylim'))], [0.2 0.8 0.2], 0.25)
plotshaded(binCenters, [RTDistDiff_Avg-RTDistDiff_SE RTDistDiff_Avg+RTDistDiff_SE]',cDiffShade, 0.5) 

plot(binCenters, RTDistDiff_Avg, 'color', cDiff, 'linewidth', 1.5) 

ha5c =  axes('unit', 'centimeters', 'position', [26  row_height(2) 4 4*ratio], 'nextplot', 'add', 'xlim', ...
    [0 1000], 'ylim', [0.5 Nrat+0.5],...
    'ytick', [0:4:Nrat], 'xtick', [0:200:1000],  'ticklength', [0.02, 1], ...
    'XTickLabelRotation', 0);

RTDist_Diff = RTDist_Diff(:, indsort);
% z score
RTDist_Diff = zscore(RTDist_Diff);
RTDist_Diff = RTDist_Diff';

himg = imagesc(binCenters, [1:Nrat], RTDist_Diff, [-6 6]);

% mycolormap = customcolormap(linspace(0,1,11), {'#a60026','#d83023','#f66e44','#faac5d','#ffdf93','#ffffbd','#def4f9','#abd9e9','#73add2','#4873b5','#313691'});
colormap(mycolormap);
hcbar2 = colorbar('location', 'EastOutSide','Units', 'Centimeters', 'Position', [30.5, row_height(2), 0.25, 4*ratio]);
hcbar2.Label.String = 'Z score';
xlabel('Reaction time (ms)')
ylabel('Rat #')

% Plot CDF
ha6 =  axes('unit', 'centimeters', 'position', [26  row_height(1)+4.5 4 2], 'nextplot', 'add', ...
    'xlim', [0 1000], 'ylim', [0 1],...
    'ytick', [0:0.2:1], 'xtick', [0:200:2000], 'xticklabel', [], 'ticklength', [0.02, 1], ...
    'XTickLabelRotation', 0);

% xlabel('Reaction time (ms)')
ylabel('CDF')
RTCDF_PreAvg = mean(squeeze(RTCDF(4, :, :, 1)), 2);
RTCDF_PreSE = std(squeeze(RTCDF(4, :, :, 1)), 0,  2)/sqrt(Nrat);
RTCDF_PostAvg = mean(squeeze(RTCDF(4, :, :, 2)), 2);
RTCDF_PostSE = std(squeeze(RTCDF(4, :, :, 2)), 0,  2)/sqrt(Nrat);

plotshaded([0 600], [0 0; 1 1], [0.2 0.8 0.2], 0.25)

plotshaded(binCenters, [RTCDF_PreAvg-RTCDF_PreSE RTCDF_PreAvg+RTCDF_PreSE]',cControlShade, 0.75)
plotshaded(binCenters, [RTCDF_PostAvg-RTCDF_PostSE RTCDF_PostAvg+RTCDF_PostSE]',  cLesionShade, 0.75)

plot(binCenters, RTCDF_PreAvg, 'color', cControl, 'linewidth', 1.5)
plot(binCenters, RTCDF_PostAvg, 'color', cLesion, 'linewidth', 1.5)

%% Plot reaction time over 3 FPs
ha7 =  axes('unit', 'centimeters', 'position', [19.5  row_height(4) 4 2.5], 'nextplot', 'add', ...
    'xlim', [250 1750], 'ylim', params.rtLim2,...
    'ytick', [200:100:800], 'xtick', FPs, 'ticklength', [0.02, 1], ...
    'XTickLabelRotation', 0);

FPs_mean = size(size(RTFixedTrials, 1), 2);
FPs_se       =  size(size(RTFixedTrials, 1), 2);

for i =1:length(FPs)
    FPs_mean(i, 1) = mean(squeeze(RTFixedTrials(i, :, 1)));
    FPs_se(i, 1)        = std(squeeze(RTFixedTrials(i, :, 1)))/sqrt(Nrat);
    FPs_mean(i, 2) = mean(squeeze(RTFixedTrials(i, :, 2)));
    FPs_se(i, 2)        = std(squeeze(RTFixedTrials(i, :, 2)))/sqrt(Nrat);
end;

i = i+1;
FPs_mean(i, 1) = mean(squeeze(RTFixedTrials(i, :, 1)));
FPs_se(i, 1)        = std(squeeze(RTFixedTrials(i, :, 1)))/sqrt(Nrat);
FPs_mean(i, 2) = mean(squeeze(RTFixedTrials(i, :, 2)));
FPs_se(i, 2)        = std(squeeze(RTFixedTrials(i, :, 2)))/sqrt(Nrat);

% plot scale bar

line([FPs; FPs], [FPs_mean([1:3], 1)-FPs_se([1:3], 1) FPs_mean([1:3], 1)+FPs_se([1:3], 1)]', 'color', cControl, 'linewidth', 1);
line([FPs; FPs], [FPs_mean([1:3], 2)-FPs_se([1:3], 2) FPs_mean([1:3], 2)+FPs_se([1:3], 2)]', 'color', cLesion, 'linewidth', 1);
plot(FPs, FPs_mean([1:3], 1), 'o',  'markersize', 5, 'linestyle', '-', 'color', cControl, 'markerfacecolor', cControl, ...
    'linewidth', 1)
plot(FPs, FPs_mean([1:3], 2), 'o',  'markersize', 5, 'linestyle', '-', 'color', cLesion, 'markerfacecolor', cLesion, ...
    'linewidth', 1)
 
xlabel('Foreperiod (ms)')
ylabel('Reaction time (ms)')
% 

ha8 =  axes('unit', 'centimeters', 'position', [2  row_height(4) 4 3], 'nextplot', 'add', ...
    'xlim', [0 10], 'ylim', [0 10]);
axis off

text(1, 5, [LesionType ' Lesion'], 'fontsize', 12, 'fontweight', 'bold')

hf.UserData = fullfile(pwd, mfilename)

thisfolder = extractBefore(DataDirectory, 'ANMs'); 

tosavename=  fullfile(thisfolder, 'Figures',  [strrep(LesionType, ' ', '_') 'GroupPerformance'])

exportgraphics(hf, [tosavename '.png'],'ContentType','vector')
exportgraphics(hf, [tosavename '.pdf'],'ContentType','vector')
exportgraphics(hf, [tosavename '.eps'],'ContentType','vector')
saveas(hf, [tosavename], 'fig') 


filename = fullfile(thisfolder, 'Data', ['BehaviorLesionDataTrials_' strrep(LesionType, ' ', '') '.csv']);
writetable(bTableAllTrials,filename);
classfilename = fullfile(thisfolder, 'Data', ['LesionClassGroup_' strrep(LesionType, ' ', '') '.mat']);
save(classfilename, 'bDataClass')