function OperationGroupAnalysis(GroupArray, savePath, options)% type, plot_rats)

% Jianing Yu 6/4/2023
% Yu Chen 10/27/2023, adapted from LesionGroupAnalysis

arguments
    GroupArray
    savePath = pwd
    options.PlotSingleRats = true
    options.ManipType = 'Unknown' % Detailed manipulation type, e.g., 'Bilateral_mPFC_Lesion'
    options.ManipTypeShort = 'Lesion' % the short form, e.g., 'Lesion', 'ShiftedFP'
    options.PeriLesionTrialNum = 2000
    options.PeriLesionTrialNumNarrow = 200
    options.FPs = [500 1000 1500]
    options.PeriLesion = [-7:-1,1:7] % Do not include 0
    options.PeriLesionLabels = {} % Include the site of 0
    options.CorrectLim = [40 100]
    options.PrematureLim = [0 60]
    options.LateLim = [0 60]
    options.RTLim = [200 600] % x-trial, y-RT
    options.RTLim_PrePost = [200 800] % used for Post-Pre axes
    options.RTLim_FPs = [200 800]
    options.HTIQRLim = [0 1000]
    options.PDFLim = [0 5]
    options.FontName = 'Helvetica' % e.g., 'Helvetica', 'DejaVu Sans'
end

plot_rats = options.PlotSingleRats;
type = options.ManipType;
typeShort = options.ManipTypeShort;

N_included      = options.PeriLesionTrialNum;
N_included2     = options.PeriLesionTrialNumNarrow;
N_includedFinal = 500;

Lim.Correct = options.CorrectLim;
Lim.Premature = options.PrematureLim;
Lim.Late = options.LateLim;
Lim.RT = options.RTLim;
Lim.RT_PrePost = options.RTLim_PrePost;
Lim.RT_FPs = options.RTLim_FPs;
Lim.HTIQR = options.HTIQRLim;
Lim.PDF = options.PDFLim;

fontname = options.FontName;

% 2023/5/31
% based on group class
% collect behavior data from all animals, 5 sessions pre and post lesion
% for each rat
Nrat = length(GroupArray);
FPs = options.FPs;
col_perf = [85 225 0
    255 0 0
    200 200 200]/255;

prelesion_col = [39, 55, 77]/255;
postlesion_col = [229 124 35]/255;
shaded_col = [255, 229, 105]/255;

PreColor = [0 0 0.6];
PostColor =  [255, 201, 60]/255;

FPColors = [45, 205, 223]/255;
PerfCode = {'Correct', 'Premature', 'Late'};

% Extract the following sessions
PeriLesion = options.PeriLesion;
PeriLesionLabels = options.PeriLesionLabels;

if isempty(PeriLesionLabels)
    PeriLesionLabels = cellstr([string(PeriLesion(PeriLesion<0)),"",string(PeriLesion(PeriLesion>0))]);
end

CorrectScore        = zeros(length(FPs)+1, Nrat, length(PeriLesion));
PrematureScore      = zeros(length(FPs)+1, Nrat, length(PeriLesion));
LateScore           = zeros(length(FPs)+1, Nrat, length(PeriLesion));
RTLoose             = zeros(length(FPs)+1, Nrat, length(PeriLesion));
RTStrict            = zeros(length(FPs)+1, Nrat, length(PeriLesion));
PeriLesionScore     = cell(2, Nrat); % Pre, early-post, late-post
PeriLesionHoldTime  = cell(2, Nrat);
PDF_PeriLesion_All  = cell(1, Nrat);
CDF_PeriLesion_All  = cell(1, Nrat);

RTAccum         = cell(2, Nrat); % Col1, Press duration(pre), Col2, Press duration (post), Col3,  FP ( 500, 1000, 1500) warmup not included.
HoldTimeAccum   = cell(Nrat, 2, length(FPs)); % Col1, Press duration(pre), Col2, Press duration (post), Col3,  FP ( 500, 1000, 1500) warmup not included.

sz  = 2;
dsz = 2;
HoldTimeMax = 3;
gap         = N_included/20;
win_size    = 100;
step_size   = 20;
clc
%% Extract data from each rat
for i =1:Nrat
    irat = GroupArray{i}.Subject{1};
    disp([num2str(i), irat])
    iClass = GroupArray{i};
    LesionSessionIndex = iClass.LesionSessionsAll;

    for j =1:length(PeriLesion)
        thisLesionIndex = find(LesionSessionIndex == PeriLesion(j));
        if ~isempty(thisLesionIndex)
            jPerformance = iClass.PerformanceSessions{thisLesionIndex};
            for k =1:length(FPs)
                kFP = FPs(k);
                IndFP = cell2mat(cellfun(@(d)isequal(d, kFP),  jPerformance.Foreperiod, 'UniformOutput', false));
                CorrectScore(k, i, j)   = jPerformance.CorrectRatio(IndFP);
                PrematureScore(k, i, j) = jPerformance.PrematureRatio(IndFP);
                LateScore(k, i, j)      = jPerformance.LateRatio(IndFP);
                % Reaction time
                IndSelected = iClass.LesionTrials == PeriLesion(j) & iClass.FP == kFP & (strcmp(iClass.Outcome', 'Correct') | strcmp(iClass.Outcome', 'Late'));
                RTLoose_this = iClass.ReactionTime(IndSelected);
                RTOutLoose = calRT(RTLoose_this, [], 'Remove100ms', 1, 'RemoveOutliers', 0, 'ToPlot', 0, 'CalSE', 0);
                IndSelected = iClass.LesionTrials == PeriLesion(j) & iClass.FP == kFP & (strcmp(iClass.Outcome', 'Correct'));
                RTStrict_this = iClass.ReactionTime(IndSelected);
                RTOutStrict = calRT(RTStrict_this, [], 'Remove100ms', 1, 'RemoveOutliers', 0, 'ToPlot', 0, 'CalSE', 0);
                RTLoose(k, i, j)    = RTOutLoose.median;
                RTStrict(k, i, j)   = RTOutStrict.median;
            end
        end
    end

    %% Perform analysis on N_included trials before and after lesion.
    IndPreLesion = [];
    IndPostLesion = [];
    % all pre-lesion trials
    IndPreLesionTrials = find(iClass.LesionTrials<=0);

    max_num = length(IndPreLesionTrials);
    disp(['Max pre-lesion trials: ' num2str(max_num)])

    k=0;
    while k < N_included && ~isempty(IndPreLesionTrials)
        last_ind = IndPreLesionTrials(end);
        if iClass.Stage(last_ind)==1 && (strcmp(iClass.Outcome{last_ind}, 'Correct') || strcmp(iClass.Outcome{last_ind}, 'Premature') || strcmp(iClass.Outcome{last_ind}, 'Late'))
            k = k+1;
            IndPreLesion = [IndPreLesion, last_ind];
            IndPreLesionTrials(end) = [];
        else
            IndPreLesionTrials(end) = [];
        end
    end

    IndPreLesion = fliplr(IndPreLesion);
    max_num = length(IndPreLesion);
    disp(['Max pre-lesion trials extracted: ' num2str(max_num)]);
    IndPostLesionTrials = find(iClass.LesionTrials>=0);
    
    max_num = length(IndPostLesionTrials);
    disp(['Max post-lesion trials: ' num2str(max_num)])

    kk=0;
    while kk < N_included && ~isempty(IndPostLesionTrials)
        last_ind = IndPostLesionTrials(1);
        if iClass.Stage(last_ind)==1 &&  (strcmp(iClass.Outcome{last_ind}, 'Correct') || strcmp(iClass.Outcome{last_ind}, 'Premature') || strcmp(iClass.Outcome{last_ind}, 'Late'))
            kk = kk+1;
            IndPostLesion = [IndPostLesion, last_ind];
            IndPostLesionTrials(1) = [];
        else
            IndPostLesionTrials(1) = [];
        end
    end

    max_num = length(IndPostLesion);
    disp(['Max post-lesion trials extracted: ' num2str(max_num)]);

    % take twice as much data for pre-lesion trials to reduce variability
    IndPreLesionTest    = IndPreLesion(randperm(N_included, N_included2));
    IndPreLesion2       = IndPreLesion(end-N_included2*2-1:end);
    IndPostLesion2      = IndPostLesion(1:N_included2);

    % we can also build a sliding sequence on the last N_included trials
    disp(['Max pre-lesion trials extracted: ' num2str(max_num)]);
    IndPostLesionTrials = find(iClass.LesionTrials>=0);
    % we need to extract LesionLate trials from the final few sessions of
    % this animal
    IndPostLesionLate = [];
    kk=0;
    IndPostLesionTrials = find(iClass.LesionTrials>=0);
    AllTrials = IndPostLesionTrials;
    while kk < N_included2 && ~isempty(AllTrials)
        last_ind = AllTrials(end);
        if iClass.Stage(last_ind)==1 &&  (strcmp(iClass.Outcome{last_ind}, 'Correct') || strcmp(iClass.Outcome{last_ind}, 'Premature') || strcmp(iClass.Outcome{last_ind}, 'Late'))
            kk = kk+1;
            IndPostLesionLate = [IndPostLesionLate, last_ind];
            AllTrials(end) = [];
        else
            AllTrials(end) = [];
        end
    end

    disp(['We collect trials from ' num2str(IndPostLesionLate(1)-length(IndPreLesionTrials)) ' to ' num2str(IndPostLesionLate(end)-length(IndPreLesionTrials))])

    [PDF_PreLesionTest, CDF_PreLesionTest, HoldTimePreTest]     = calPDF(iClass, IndPreLesionTest);
    [PDF_PreLesion, CDF_PreLesion, HoldTimePre]                 = calPDF(iClass, IndPreLesion2);
    [PDF_PostLesion, CDF_PostLesion, HoldTimePost]              = calPDF(iClass, IndPostLesion2);
    [PDF_PostLesionLate, CDF_PostLesionLate, HoldTimePostLate]  = calPDF(iClass, IndPostLesionLate);

    % rt_out = calRTlocal(obj, index)
    RT_Pre = calRTlocal(iClass, IndPreLesion2);
    RT_Post = calRTlocal(iClass, IndPostLesion2);
    RT_PostLate = calRTlocal(iClass, IndPostLesionLate); % after extensive training

    tBins = iClass.HoldTbinEdges;
    PDF_PeriLesion_All{i}  = {tBins, PDF_PreLesion, PDF_PostLesion, RT_Pre, RT_Post, PDF_PostLesionLate, RT_PostLate, PDF_PreLesionTest};
    CDF_PeriLesion_All{i}  = {tBins, CDF_PreLesion, CDF_PostLesion, CDF_PostLesionLate};

    HoldTimeAccum(i, 1,:) = HoldTimePre;
    HoldTimeAccum(i, 2,:) = HoldTimePost;
    HoldTimeAccum(i, 3,:) = HoldTimePostLate;

    % Compute performance score over a sliding window
    % PreLesion trials
    seg_beg = 1; % IndPreLesion(1);

    PreLesionScore = struct('Correct', [], 'Premature',[],'Late',[], 'TrialIndex', []);
    PreLesionRT = struct('RT', [], 'HoldTimeIQR', [], 'TrialIndex', []);

    while seg_beg + win_size< length(IndPreLesion)
        IndThisSeg = IndPreLesion([seg_beg:seg_beg+win_size]);
        seg_beg = seg_beg + step_size;
        % compute Correct/Premature/Late for 3 FPs
        [performance_score, rt_seg, ht_iqr] = compute_performance(iClass, IndThisSeg);
        PreLesionScore.Correct      = [PreLesionScore.Correct; performance_score.Correct];
        PreLesionScore.Premature    = [PreLesionScore.Premature; performance_score.Premature];
        PreLesionScore.Late         = [PreLesionScore.Late; performance_score.Late];
        PreLesionScore.TrialIndex   = [PreLesionScore.TrialIndex, seg_beg+round(0.5*win_size)];
        PreLesionRT.RT              = [PreLesionRT.RT; rt_seg];
        PreLesionRT.HoldTimeIQR     = [PreLesionRT.HoldTimeIQR; ht_iqr];
        PreLesionRT.TrialIndex      = [PreLesionRT.TrialIndex seg_beg+round(0.5*win_size)];
    end

    PostLesionScore = struct('Correct', [], 'Premature',[],'Late',[], 'TrialIndex', []);
    PostLesionRT = struct('RT', [], 'HoldTimeIQR', [],  'TrialIndex', []);

    seg_beg=1;
    while seg_beg + win_size< length(IndPostLesion)
        IndThisSeg = IndPostLesion(seg_beg:seg_beg+win_size);
        seg_beg = seg_beg + step_size;
        % compute Correct/Premature/Late for 3 FPs
        [performance_score, rt_seg, ht_iqr] = compute_performance(iClass, IndThisSeg);
        PostLesionScore.Correct     = [PostLesionScore.Correct; performance_score.Correct];
        PostLesionScore.Premature   = [PostLesionScore.Premature; performance_score.Premature];
        PostLesionScore.Late        = [PostLesionScore.Late; performance_score.Late];
        PostLesionScore.TrialIndex  = [PostLesionScore.TrialIndex, seg_beg+round(0.5*win_size)];
        PostLesionRT.RT             = [PostLesionRT.RT; rt_seg];
        PostLesionRT.HoldTimeIQR    = [PostLesionRT.HoldTimeIQR; ht_iqr];
        PostLesionRT.TrialIndex     = [PostLesionRT.TrialIndex seg_beg+round(0.5*win_size)];
    end

    PeriLesionScore(:, i) = {PreLesionScore, PostLesionScore};
    RTAccum(:, i) = {PreLesionRT, PostLesionRT};

    HoldTimePre     = iClass.HoldTime(IndPreLesion);
    FP_Pre          = iClass.FP(IndPreLesion);
    HoldTimePost    = iClass.HoldTime(IndPostLesion);
    FP_Post         = iClass.FP(IndPostLesion);

    % PeriLesionHoldTime
    HoldTime = [];
    for kk =1:length(IndPreLesion)
        k_index     = IndPreLesion(kk);
        Hold_k      = HoldTimePre(kk);
        Hold_k      = min(HoldTimeMax, Hold_k);
        HoldTime    = [HoldTime;  iClass.FP(k_index) HoldTimePre(kk)];
    end
    PeriLesionHoldTime{1, i} = HoldTime;

    HoldTime = [];
    for kk =1:length(IndPostLesion)
        kplot       = kk+gap;
        k_index     = IndPostLesion(kk);
        Hold_k      = HoldTimePost(kk);
        Hold_k      = min(HoldTimeMax, Hold_k);
        HoldTime    = [HoldTime; iClass.FP(k_index) HoldTimePost(kk)];
    end

    PeriLesionHoldTime{2, i} = HoldTime;
    if plot_rats
        %% Plot these data
        hrat = figure(23);
        clf(hrat);
        set(hrat, 'unit', 'centimeters', 'position', [2 2 29 18], 'paperpositionmode', 'auto', 'color', 'w');

        %% A. Sessions
        uicontrol('Style','text','Units','centimeters','Position',[2 13 4 1],...
            'string', ['A. Performance/RT vs sessions'], ...
            'FontName',fontname, 'fontweight', 'bold','fontsize', 10,'BackgroundColor',[1 1 1],...
            'HorizontalAlignment','Left');

        uicontrol('Style','text','Units','centimeters','Position',[2 14.5 4 1],...
            'string', [iClass.Subject], ...
            'FontName',fontname, 'fontweight', 'bold','fontsize', 12,'BackgroundColor',[1 1 1],...
            'HorizontalAlignment','Left');

        haRT =  axes('parent', hrat, 'units', 'centimeters', 'position', [2 10.5 6 2], 'nextplot', 'add', ...
            'ylim', [0 600], 'ytick', 0:200:600, ...
            'xtick', -5:6, 'xlim', [min(PeriLesion)-0.5 max(PeriLesion)+0.5],...
            'yscale', 'linear', 'xticklabelrotation', 0, 'FontSize', 8, 'FontName', fontname);
        xlabel('Session relative to lesion')
        ylabel('Reaction time (ms)')
        plotshaded([0 max(PeriLesion)+0.5], [0 0; 600 600], shaded_col);

        ha0 =  axes('parent', hrat, 'units', 'centimeters', 'position', [2 7 6 2], 'nextplot', 'add', ...
            'ylim', [0 100], 'ytick', 0:50:100, ...
            'xtick', -5:6, 'xlim', [min(PeriLesion)-0.5 max(PeriLesion)+0.5],'xticklabel', [],...
            'yscale', 'linear', 'xticklabelrotation', 0, 'FontSize', 8, 'FontName', fontname);
        plotshaded([0 max(PeriLesion)+0.5], [0 0; 100 100], shaded_col);

        ylabel('Performance')
        ha00 =  axes('parent', hrat, 'units', 'centimeters', 'position', [2 4.5 6 2], 'nextplot', 'add', ...
            'ylim', [0 100], 'ytick', 0:50:100, ...
            'xtick', -5:6, 'xlim', [min(PeriLesion)-0.5 max(PeriLesion)+0.5],'xticklabel', [],...
            'yscale', 'linear', 'xticklabelrotation', 0, 'FontSize', 8, 'FontName', fontname);
        plotshaded([0 max(PeriLesion)+0.5], [0 0; 100 100], shaded_col);

        ha000 =  axes('parent', hrat, 'units', 'centimeters', 'position', [2 2 6 2], 'nextplot', 'add', ...
            'ylim', [0 100], 'ytick', 0:50:100, ...
            'xtick', -5:6, 'xlim', [min(PeriLesion)-0.5 max(PeriLesion)+0.5],...
            'yscale', 'linear', 'xticklabelrotation', 0, 'FontSize', 8, 'FontName', fontname);
        xlabel('Session relative to lesion')
        plotshaded([0 max(PeriLesion)+0.5], [0 0; 100 100], shaded_col);

        basesize = 2;
        increasingsize =2;
        for ii =1:length(FPs)
            IndPre = find(PeriLesion<0);
            plot(ha0, PeriLesion(IndPre), squeeze(CorrectScore(ii, i, IndPre)), 'color', col_perf(1, :), ...
                'linewidth', 0.5*ii, 'marker','.','markerfacecolor', col_perf(1, :), 'markersize', basesize+increasingsize*(ii-1))
            plot(ha00, PeriLesion(IndPre), squeeze(PrematureScore(ii, i, IndPre)), 'color', col_perf(2, :), ...
                'linewidth', 0.5*ii, 'marker','.','markerfacecolor', col_perf(1, :),'markersize', basesize+increasingsize*(ii-1))
            plot(ha000, PeriLesion(IndPre), squeeze(LateScore(ii, i, IndPre)), 'color', col_perf(3, :), ...
                'linewidth', 0.5*ii, 'marker','.', 'markerfacecolor', col_perf(1, :),'markersize', basesize+increasingsize*(ii-1))
            plot(haRT, PeriLesion(IndPre), 1000*squeeze(RTLoose(ii, i, IndPre)), 'color', 'k', ...
                'linewidth', 0.5*ii, 'markeredgecolor', 'k', 'marker','o', 'markerfacecolor', 'none','markersize', 2*basesize)
            IndPost = find(PeriLesion>0);
            plot(ha0, PeriLesion(IndPost), squeeze(CorrectScore(ii, i, IndPost)), 'color', col_perf(1, :), ...
                'linewidth', 0.5*ii, 'marker','.','markerfacecolor', col_perf(1, :),  'markersize', basesize+increasingsize*(ii-1))
            plot(ha00, PeriLesion(IndPost), squeeze(PrematureScore(ii, i, IndPost)), 'color', col_perf(2, :), ...
                'linewidth', 0.5*ii, 'marker','.','markerfacecolor', col_perf(1, :), 'markersize', basesize+increasingsize*(ii-1))
            plot(ha000, PeriLesion(IndPost), squeeze(LateScore(ii, i, IndPost)), 'color', col_perf(3, :), ...
                'linewidth', 0.5*ii,  'marker','.', 'markerfacecolor', col_perf(1, :),'markersize', basesize+increasingsize*(ii-1))
            plot(haRT, PeriLesion(IndPost), 1000*squeeze(RTLoose(ii, i, IndPost)), 'color', 'k', ...
                'linewidth', 0.5*ii, 'markeredgecolor', 'k', 'marker','o', 'markerfacecolor', 'none','markersize', 2*basesize)
        end

        %% B. Trials
        ha1 = axes('parent', hrat, 'units', 'centimeters', 'position', [10 2 6 2], 'nextplot', 'add', 'ylim', [0 HoldTimeMax], 'ytick', [0:1:HoldTimeMax], ...
            'xtick', [-1000:500:1000], 'xlim', [-N_included-2*gap N_included+2*gap],...
            'yscale', 'linear', 'xticklabelrotation', 0, 'FontSize', 8, 'FontName', fontname);
        plotshaded([0 N_included+gap], [0 0; HoldTimeMax HoldTimeMax], shaded_col);

        ha2 = axes('parent', hrat, 'units', 'centimeters', 'position', [10 4.5 6 2], 'nextplot', 'add',...
            'ylim', [0 100], 'ytick', [0:50:100], ...
            'xtick', [-1000:500:1000], 'xlim', [-N_included-2*gap N_included+2*gap], 'xticklabel', [],...
            'yscale', 'linear', 'xticklabelrotation', 0, 'FontSize', 8, 'FontName', fontname);
        plotshaded([0 N_included+gap], [0 0; 100 100], shaded_col);

        ha3 = axes('parent', hrat, 'units', 'centimeters', 'position', [10 7 6 2], 'nextplot', 'add',...
            'ylim', [0 100], 'ytick', [0:50:100], ...
            'xtick', [-1000:500:1000], 'xlim', [-N_included-2*gap N_included+2*gap],...
            'yscale', 'linear','xtick',[], 'xticklabelrotation', 0, 'FontSize', 8, 'FontName', fontname);
        plotshaded([0 N_included+gap], [0 0; 100 100], shaded_col);

        ha4 = axes('parent', hrat, 'units', 'centimeters', 'position', [10 9.5 6 2], 'nextplot', 'add',...
            'ylim', [0 100], 'ytick', [0:50:100], ...
            'xtick', [-1000:500:1000], 'xlim', [-N_included-2*gap N_included+2*gap],...
            'yscale', 'linear','xtick', [], 'xticklabelrotation', 0, 'FontSize', 8, 'FontName', fontname);
        plotshaded([0 N_included+gap], [0 0; 100 100], shaded_col);

        ha5 = axes('parent', hrat, 'units', 'centimeters', 'position', [10 13 6 2], 'nextplot', 'add',...
            'ylim', [0 800], 'ytick', [0:200:600], ...
            'xtick', [-1000:500:1000], 'xlim', [-N_included-2*gap N_included+2*gap],...
            'yscale', 'linear','xticklabelrotation', 0, 'FontSize', 8, 'FontName', fontname);
        plotshaded([0 N_included+gap], [0 0; 800 800], shaded_col);
        ylabel('Reaction time (ms)')
        uicontrol('Style','text','Units','centimeters','Position',[10 15.5  4 1],...
            'string', ['B. Performance/RT vs trials'], ...
            'FontName',fontname, 'fontweight', 'bold','fontsize', 10,'BackgroundColor',[1 1 1],...
            'HorizontalAlignment','Left');
        for ii =1:length(FPs)
            plot(ha4, PreLesionScore.TrialIndex-N_included-gap, PreLesionScore.Correct(:, ii), 'color', col_perf(1, :), 'linewidth', 0.5*ii, 'marker','.')
            plot(ha3, PreLesionScore.TrialIndex-N_included-gap, PreLesionScore.Premature(:, ii), 'color', col_perf(2, :), 'linewidth', 0.5*ii, 'marker','.')
            plot(ha2, PreLesionScore.TrialIndex-N_included-gap, PreLesionScore.Late(:, ii), 'color', col_perf(3, :), 'linewidth', 0.5*ii, 'marker','.')
            plot(ha5, PreLesionRT.TrialIndex-N_included-gap, 1000*PreLesionRT.RT(:, ii), 'color', 'k', 'linewidth', 0.5*ii, 'marker','.')
        end
        for ii =1:length(FPs)
            plot(ha4, PostLesionScore.TrialIndex+gap, PostLesionScore.Correct(:, ii), 'color', col_perf(1, :), 'linewidth', 0.5*ii, 'marker','.')
            plot(ha3, PostLesionScore.TrialIndex+gap, PostLesionScore.Premature(:, ii), 'color', col_perf(2, :), 'linewidth', 0.5*ii, 'marker','.')
            plot(ha2, PostLesionScore.TrialIndex+gap, PostLesionScore.Late(:, ii), 'color', col_perf(3, :), 'linewidth', 0.5*ii, 'marker','.')
            plot(ha5, PostLesionRT.TrialIndex+gap, 1000*PostLesionRT.RT(:, ii), 'color', 'k', 'linewidth', 0.5*ii, 'marker','.')
        end
        line(ha1, [-N_included-2*gap N_included+2*gap], [FPs;FPs]'/1000, 'color', [195, 129, 84]/255);
        for kk=1:length(IndPreLesion)
            kplot   = kk-N_included-gap;
            k_index = IndPreLesion(kk);
            kFP     = find(FPs == iClass.FP(k_index));
            sz_k    = sz + kFP*dsz;
            color_k = col_perf(strcmp(PerfCode, iClass.Outcome{k_index}), :);
            Hold_k  = HoldTimePre(kk);
            Hold_k  = min(HoldTimeMax, Hold_k);

            scatter(ha1, kplot, Hold_k, sz_k, 'Marker', 'o', 'MarkerFaceAlpha',0.25,...
                'LineWidth', 0.5, 'MarkerFaceColor', color_k, ...
                'MarkerEdgeColor', color_k);
        end
        for kk=1:length(IndPostLesion)
            kplot   = kk+gap;
            k_index = IndPostLesion(kk);
            kFP     = find(FPs == iClass.FP(k_index));
            sz_k    = sz + kFP*dsz;
            color_k = col_perf(strcmp(PerfCode, iClass.Outcome{k_index}), :);
            Hold_k  = HoldTimePost(kk);
            Hold_k  = min(HoldTimeMax, Hold_k);
            HoldTime = [HoldTime;  iClass.FP(k_index) HoldTimePost(kk)];
            scatter(ha1, kplot, Hold_k, sz_k, 'Marker', 'o', 'MarkerFaceAlpha',0.25,...
                'LineWidth', 0.5, 'MarkerFaceColor', color_k, ...
                'MarkerEdgeColor', color_k);
        end
        %% C. Hold time
        ha6 = axes('parent', hrat, 'units', 'centimeters', 'position', [18 2 4 3], 'nextplot', 'add', ...
            'ylim', [0 6], 'ytick', 0:1:6, 'xtick', 0:0.5:3, 'xlim', [0 3],...
            'yscale', 'linear', 'xticklabelrotation', 0, 'FontSize', 8, 'FontName', fontname);

        for m = 1:size(PDF_PreLesion, 2)
            plot(tBins, PDF_PreLesion(:, m), 'color', PreColor, 'linewidth', 0.5*m);
            plot(tBins, PDF_PostLesion(:, m), 'color', PostColor, 'linewidth', 0.5*m);
            plot(tBins, PDF_PostLesionLate(:, m), 'color', PostColor*0.7, 'linewidth', 0.5*m, 'linestyle', ':');
        end
        xlabel('Hold duration (s)')
        ylabel('PDF (1/s)')
        ha7 = axes('parent', hrat, 'units', 'centimeters', 'position', [18 6.5 4 3], 'nextplot', 'add', ...
            'ylim', [0 1], 'ytick', 0:0.2:1, ...
            'xtick', 0:0.5:3, 'xlim', [0 3],...
            'yscale', 'linear', 'xticklabelrotation', 0, 'FontSize', 8, 'FontName', fontname);
        for m = 1:size(CDF_PreLesion, 2)
            plot(tBins, CDF_PreLesion(:, m), 'color', PreColor, 'linewidth', 0.5*m);
            plot(tBins, CDF_PostLesion(:, m), 'color', PostColor, 'linewidth', 0.5*m);
            plot(tBins, CDF_PostLesionLate(:, m), 'color', PostColor*0.7, 'linewidth', 0.5*m, 'linestyle', ':');
        end
        xlabel('Hold duration (s)')
        ylabel('CDF')
        uicontrol('Style','text','Units','centimeters','Position',[18 10  4 1],...
            'string', ['C. Pre vs Post ('  num2str(N_included2) ' trials)'], ...
            'FontName',fontname, 'fontweight', 'bold','fontsize', 10,'BackgroundColor',[1 1 1],...
            'HorizontalAlignment','Left');
        xlabel('Trials relative to lesion')
        ylabel('Hold time')
        % Print and save this figure
        tosavefolder = fullfile(savePath, 'Figures', type);
        if ~exist(tosavefolder, 'dir')
            mkdir(tosavefolder);
        end
        tosavename = [iClass.Subject{1}];
        tosavename = fullfile(tosavefolder, tosavename);
        print(hrat,'-dpng', tosavename)
        print(hrat,'-depsc2', tosavename)
    end
end
close all;
%% Start plotting
ratio = 0.1;
width = 2.5;
height = 2;
height_col = 1.5;

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
x_start = 2;

%% Plot distribution of reaction time or hold time
hf = figure(26); clf
set(hf, 'unit', 'centimeters', 'position',[1 1 34 19],...
    'renderer','Painters','InvertHardcopy','off','Color','w',...
    'paperpositionmode','auto' ,'paperunits','centimeters','papersize',[34 19]); % 

this_height = 12;
width_pdf = 2 ;
height_pdf = 2;

ha1 = axes('unit', 'centimeters', 'position', [x_start this_height width_pdf height_pdf], 'nextplot', 'add', ...
    'xlim', [tBins(1) tBins(1)+FPs(end)/1000+1], 'ylim', Lim.PDF,...
    'ytick', Lim.PDF(1):Lim.PDF(end), 'xtick', 0:1:tBins(end),'ticklength', [0.02, 1], ...
    'XTickLabelRotation', 0);
ylabel('PDF (1/s)')
xlabel('Hold duration (s)')

line(ha1, [FPs; FPs]/1000, Lim.PDF, 'color', 'k', 'linestyle', ':');

ha2 =  axes('unit', 'centimeters', 'position', [x_start  this_height+height_pdf+0.5 width_pdf height_pdf], 'nextplot', 'add', ...
    'xlim', [tBins(1) tBins(1)+FPs(end)/1000+1], 'ylim', [0 1],...
    'ytick', 0:0.5:5, 'xtick', 0:1:tBins(end),'xticklabel', [], 'ticklength', [0.02, 1], ...
    'XTickLabelRotation', 0);
ylabel('CDF')
line(ha2, [FPs; FPs]/1000, [0 1],'color', 'k', 'linestyle', ':');

uicontrol('Style','text','Units','centimeters','Position',[x_start this_height+height_pdf+0.5+height_pdf+0.1  width_pdf 1],...
    'string',['Peri' typeShort ' ' num2str(N_included2) ' trials'], ...
    'FontName',fontname, 'fontweight', 'bold','fontsize', 8,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Left');

x_start = x_start + width_pdf+1.5;
ha1late =  axes('unit', 'centimeters', 'position', [x_start this_height width_pdf height_pdf], 'nextplot', 'add', ...
    'xlim', [tBins(1) tBins(1)+FPs(end)/1000+1], 'ylim', Lim.PDF,...
    'ytick', Lim.PDF(1):Lim.PDF(end), 'xtick', 0:1:tBins(end),'ticklength', [0.02, 1], ...
    'XTickLabelRotation', 0);
ylabel('PDF (1/s)')
xlabel('Hold duration (s)')
line(ha1late, [FPs; FPs]/1000, Lim.PDF, 'color', 'k', 'linestyle', ':');

ha2late =  axes('unit', 'centimeters', 'position', [x_start  this_height+height_pdf+0.5 width_pdf height_pdf], 'nextplot', 'add', ...
    'xlim', [tBins(1) tBins(1)+FPs(end)/1000+1], 'ylim', [0 1],...
    'ytick', 0:0.5:5, 'xtick', 0:1:tBins(end),'xticklabel', [], 'ticklength', [0.02, 1], ...
    'XTickLabelRotation', 0);
ylabel('CDF')
line(ha2late,  [FPs; FPs]/1000, [0 1],'color', 'k', 'linestyle', ':');

uicontrol('Style','text','Units','centimeters','Position',[x_start this_height+height_pdf+0.5+height_pdf+0.1  width_pdf 1],...
    'string',['Extensive post-' lower(typeShort) ' training'], ...
    'FontName',fontname, 'fontweight', 'bold','fontsize', 8,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Left');

CDF_PressDuration_PreLesion =cell(1, length(FPs));
CDF_PressDuration_PostLesion = cell(1, length(FPs));
CDF_PressDuration_PostLesionLate = cell(1, length(FPs));
PDF_PressDuration_PreLesion = cell(1, length(FPs));
PDF_PressDuration_PostLesion = cell(1, length(FPs));
PDF_PressDuration_PostLesionLate = cell(1, length(FPs));
%     PDF_PeriLesion_All{i}  = {tBins, PDF_PreLesion, PDF_PostLesion, RT_Pre, RT_Post, 
%  PDF_PostLesionLate, RT_PostLate, PDF_PreLesionTest};

CrossCorrelation_PrePre = zeros(Nrat, 2, length(FPs)); % time shifted, max correlation score
CrossCorrelation_PrePost = zeros(Nrat, 2, length(FPs)); % time shifted, max correlation score
CrossCorrelation_PrePostLate = zeros(Nrat, 2, length(FPs));

for k =1:length(FPs)
    CDF_PressDuration_PreLesion{k} = zeros(Nrat, length(tBins));
    CDF_PressDuration_PostLesion{k} = zeros(Nrat, length(tBins));
    CDF_PressDuration_PostLesionLate{k} = zeros(Nrat, length(tBins));
    PDF_PressDuration_PreLesion{k} = zeros(Nrat, length(tBins));
    PDF_PressDuration_PostLesion{k} = zeros(Nrat, length(tBins));
    PDF_PressDuration_PostLesionLate{k} = zeros(Nrat, length(tBins));

    Ind_PDF_PreLesion=2;
    Ind_PDF_PostLesion = 3;
    Ind_PDF_PostLesionLate = 6;
    Ind_PDF_PreLesionTest = 8;
    Ind_CDF_PreLesion=2;
    Ind_CDF_PostLesion = 3;
    Ind_CDF_PostLesionLate = 4;

    for i =1:Nrat
        CDF_PressDuration_PreLesion{k}(i, :) = CDF_PeriLesion_All{i}{Ind_CDF_PreLesion}(:, k)';
        CDF_PressDuration_PostLesion{k}(i, :) = CDF_PeriLesion_All{i}{Ind_CDF_PostLesion}(:, k)';
        CDF_PressDuration_PostLesionLate{k}(i, :)  = CDF_PeriLesion_All{i}{Ind_CDF_PostLesionLate}(:, k)';
        PDF_PressDuration_PreLesion{k}(i, :) = PDF_PeriLesion_All{i}{Ind_PDF_PreLesion}(:, k)';
        PDF_PressDuration_PostLesion{k}(i, :) = PDF_PeriLesion_All{i}{Ind_PDF_PostLesion}(:, k)';
        PDF_PressDuration_PostLesionLate{k}(i, :)  = PDF_PeriLesion_All{i}{Ind_PDF_PostLesionLate}(:, k)';
        % Compute cross correlation between pre- and post-lesion PDFs
        [maxcc, tmaxcc]=  compute_ccmax(tBins, PDF_PeriLesion_All{i}{Ind_PDF_PreLesion}(:, k),  PDF_PeriLesion_All{i}{Ind_PDF_PostLesion}(:, k));
        CrossCorrelation_PrePost( i,1, k) = maxcc;
        CrossCorrelation_PrePost( i,2, k) = tmaxcc;

        [maxcc, tmaxcc] = compute_ccmax(tBins, PDF_PeriLesion_All{i}{Ind_PDF_PreLesion}(:, k),  PDF_PeriLesion_All{i}{Ind_PDF_PostLesionLate}(:, k));
        CrossCorrelation_PrePostLate( i,1, k) = maxcc;
        CrossCorrelation_PrePostLate( i,2, k) = tmaxcc;

        [maxcc, tmaxcc] = compute_ccmax(tBins, PDF_PeriLesion_All{i}{Ind_PDF_PreLesion}(:, k),  PDF_PeriLesion_All{i}{Ind_PDF_PreLesionTest}(:, k));
        CrossCorrelation_PrePre( i,1, k) = maxcc;
        CrossCorrelation_PrePre( i,2, k) = tmaxcc;
    end
    %  shaded_col = [255, 229, 105]/255;
    Mean_CDF_Press_PreLesion   = mean(CDF_PressDuration_PreLesion{k}, 1);
    Mean_CDF_Press_PostLesion  = mean(CDF_PressDuration_PostLesion{k}, 1);
    Mean_CDF_Press_PostLesionLate  = mean(CDF_PressDuration_PostLesionLate{k}, 1);
    SE_CDF_Press_PreLesion   = std(CDF_PressDuration_PreLesion{k}, 0, 1)/sqrt(Nrat);
    SE_CDF_Press_PostLesion  = std(CDF_PressDuration_PostLesion{k},0,  1)/sqrt(Nrat);
    SE_CDF_Press_PostLesionLate  = std(CDF_PressDuration_PostLesionLate{k},0,  1)/sqrt(Nrat);

    Mean_PDF_Press_PreLesion   = mean(PDF_PressDuration_PreLesion{k}, 1);
    Mean_PDF_Press_PostLesion  = mean(PDF_PressDuration_PostLesion{k}, 1);
    Mean_PDF_Press_PostLesionLate  = mean(PDF_PressDuration_PostLesionLate{k}, 1);
    SE_PDF_Press_PreLesion   = std(PDF_PressDuration_PreLesion{k}, 0, 1)/sqrt(Nrat);
    SE_PDF_Press_PostLesion  = std(PDF_PressDuration_PostLesion{k},0,  1)/sqrt(Nrat);
    SE_PDF_Press_PostLesionLate  = std(PDF_PressDuration_PostLesionLate{k},0,  1)/sqrt(Nrat);

    axes(ha1)
    plotshaded(tBins, [Mean_PDF_Press_PreLesion-SE_PDF_Press_PreLesion; Mean_PDF_Press_PreLesion+SE_PDF_Press_PreLesion], [0.5 0.5 0.5], 0.25)
    plotshaded(tBins, [Mean_PDF_Press_PostLesion-SE_PDF_Press_PostLesion; Mean_PDF_Press_PostLesion+SE_PDF_Press_PostLesion], shaded_col, 0.25)
    plot(ha1, tBins, Mean_PDF_Press_PreLesion, 'color', prelesion_col, 'linewidth', 0.5*k);
    plot(ha1, tBins, Mean_PDF_Press_PostLesion, 'color', postlesion_col, 'linewidth', 0.5*k);

    axes(ha1late)
    plotshaded(tBins, [Mean_PDF_Press_PreLesion-SE_PDF_Press_PreLesion; Mean_PDF_Press_PreLesion+SE_PDF_Press_PreLesion], [0.5 0.5 0.5], 0.25)
    plotshaded(tBins, [Mean_PDF_Press_PostLesionLate-SE_PDF_Press_PostLesionLate; Mean_PDF_Press_PostLesionLate+SE_PDF_Press_PostLesionLate], shaded_col, 0.25)
    plot(ha1late, tBins, Mean_PDF_Press_PreLesion, 'color', prelesion_col, 'linewidth', 0.5*k);
    plot(ha1late, tBins, Mean_PDF_Press_PostLesionLate, 'color', postlesion_col.*0.8, 'linewidth', 0.5*k);

    axes(ha2)
    plotshaded(  tBins, [Mean_CDF_Press_PreLesion-SE_CDF_Press_PreLesion; Mean_CDF_Press_PreLesion+SE_CDF_Press_PreLesion],  [0.5 0.5 0.5], 0.25)
    plotshaded( tBins, [Mean_CDF_Press_PostLesion-SE_CDF_Press_PostLesion; Mean_CDF_Press_PostLesion+SE_CDF_Press_PostLesion], shaded_col, 0.25)
    plot(ha2, tBins, Mean_CDF_Press_PreLesion, 'color', prelesion_col, 'linewidth', 0.5*k);
    plot(ha2, tBins, Mean_CDF_Press_PostLesion, 'color', postlesion_col, 'linewidth', 0.5*k);

    axes(ha2late)
    plotshaded(tBins, [Mean_CDF_Press_PreLesion-SE_CDF_Press_PreLesion; Mean_CDF_Press_PreLesion+SE_CDF_Press_PreLesion],  [0.5 0.5 0.5], 0.25)
    plotshaded( tBins, [Mean_CDF_Press_PostLesionLate-SE_CDF_Press_PostLesionLate; Mean_CDF_Press_PostLesionLate+SE_CDF_Press_PostLesionLate], shaded_col, 0.25)
    plot(ha2late, tBins, Mean_CDF_Press_PreLesion, 'color', prelesion_col, 'linewidth', 0.5*k);
    plot(ha2late, tBins, Mean_CDF_Press_PostLesionLate, 'color', postlesion_col.*0.8, 'linewidth', 0.5*k);
end


%% Plot color map
% this_height = this_height +height_pdf+1.5;
height_color = ratio*Nrat;
indsort = [];
x_start = x_start+width_pdf+0.75;

diffmat = [];

for i =1:length(FPs)    
    if isempty(indsort)
        [~, indsort] = sort(max(PDF_PressDuration_PreLesion{i}, [], 2));
    end
    PDF_PressDuration_PreLesion{i} = PDF_PressDuration_PreLesion{i}(indsort, :);
    PDF_PressDuration_PostLesion{i} = PDF_PressDuration_PostLesion{i}(indsort, :);
    PDF_PressDuration_PostLesionLate{i} = PDF_PressDuration_PostLesionLate{i}(indsort, :);

    hpdf1(i)=axes('unit', 'centimeters', 'position', [x_start  this_height+(i-1)*height_color*1.1 width_pdf height_color], ...
        'nextplot', 'add', 'xlim', [tBins(1) tBins(1)+FPs(end)/1000+1], 'ylim', [0.5 Nrat+0.5],...
        'ytick', 0:4:Nrat, 'xtick', 0:1:5, 'ticklength', [0.02, 1], ...
        'XTickLabelRotation', 0);
    x_start_updated = x_start + width_pdf+0.25;
    if i>1
        set(hpdf1(i), 'yticklabel', [], 'xticklabel', []);
    end
    if i ==1
        xlabel('Hold duration (s) ')
    elseif i==length(FPs)
        title('Pre');
    end
    himg = imagesc(tBins, 1:Nrat, PDF_PressDuration_PreLesion{i}, [0 5]);

    himg.AlphaData = ~isnan(himg.CData); % make sure a few NAN pixels are set to be transparent
    line([FPs(i) FPs(i)]/1000, [0 Nrat+0.5], 'color', [0.75 0.75 0.75], 'linestyle', '--', 'linewidth', 1)
    colormap(hpdf1(i), 'parula');

    hpdf2(i)=axes('unit', 'centimeters', 'position', [x_start_updated  this_height+(i-1)*height_color*1.1 width_pdf height_color], ...
        'nextplot', 'add', 'xlim', [tBins(1) tBins(1)+FPs(end)/1000+1], 'ylim', [0.5 Nrat+0.5],...
        'ytick', 0:4:Nrat, 'xtick', 0:1:5, 'ticklength', [0.02, 1], ...
        'XTickLabelRotation', 0);
    if i==length(FPs)
        title('Post | Early');
    end
    x_start_updated = x_start_updated+width_pdf+0.25;
    set(hpdf2(i), 'yticklabel', [], 'xticklabel', []);
    himg = imagesc(tBins, 1:Nrat, PDF_PressDuration_PostLesion{i}, [0 5]);
    line([FPs(i) FPs(i)]/1000, [0 Nrat+0.5], 'color', [0.75 0.75 0.75], 'linestyle', '--', 'linewidth', 1);
    colormap(hpdf2(i), 'parula');
    set(hpdf2(i), 'yticklabel', [], 'xticklabel', []);

    % Plot the difference
    hadiff(i) = axes('unit', 'centimeters', 'position', [x_start_updated  this_height+(i-1)*height_color*1.1 width_pdf height_color], ...
        'nextplot', 'add', 'xlim', [tBins(1) tBins(1)+FPs(end)/1000+1], 'ylim', [0.5 Nrat+0.5],...
        'ytick', 0:4:Nrat, 'yticklabel', [], 'xtick', [0:5],'xticklabel', [],  'ticklength', [0.02, 1], ...
        'XTickLabelRotation', 0);
    x_start_updated = x_start_updated+width_pdf+0.25;
    if i>1
        set(hadiff(i) , 'yticklabel', [], 'xticklabel', []);
    end
    mycolormap =  customcolormap(linspace(0,1,11), {'#68011d','#b5172f','#d75f4e','#f7a580','#fedbc9','#f5f9f3','#d5e2f0','#93c5dc','#4295c1','#2265ad','#062e61'});
    colormap(hadiff(i), mycolormap)
    himg = imagesc(tBins, [1:Nrat], PDF_PressDuration_PostLesion{i}- PDF_PressDuration_PreLesion{i}, [-5 5]);
    line([FPs(i) FPs(i)]/1000, [0 Nrat+0.5], 'color', [0.75 0.75 0.75], 'linestyle', '--', 'linewidth', 1);

    % later trials (after extensive training)
    hpdf3(i)=axes('unit', 'centimeters', 'position', [x_start_updated  this_height+(i-1)*height_color*1.1 width_pdf height_color], ...
        'nextplot', 'add', 'xlim', [tBins(1) tBins(1)+FPs(end)/1000+1], 'ylim', [0.5 Nrat+0.5],...
        'ytick', 0:4:Nrat, 'xtick', 0:1:5, 'ticklength', [0.02, 1], ...
        'XTickLabelRotation', 0);
    x_start_updated = x_start_updated+width_pdf+0.25;
    set(hpdf3(i), 'yticklabel', [], 'xticklabel', []);
    if i==length(FPs)
        title('Post | Late');
    end
    himg = imagesc(tBins, [1:Nrat], PDF_PressDuration_PostLesionLate{i}, [0 5]);
    line([FPs(i) FPs(i)]/1000, [0 Nrat+0.5], 'color', [0.75 0.75 0.75], 'linestyle', '--', 'linewidth', 1);
    colormap(hpdf2(i), 'parula');
    set(hpdf2(i), 'yticklabel', [], 'xticklabel', []);

    if i==1
        % add colorbar
        hbar1 = colorbar('Southoutside');
        set(hbar1, 'units', 'centimeters', 'position',[x_start_updated-1.3 this_height-0.5 1 0.125])
        hbar1.Label.String = 'PDF (1/s)';
        hbar1.Ticks=[0 5];
        hbar1.TickLength = 0.02;
    end

    % Plot the difference
    hadiff2(i) = axes('unit', 'centimeters', 'position', [x_start_updated  this_height+(i-1)*height_color*1.1 width_pdf height_color], ...
        'nextplot', 'add', 'xlim', [tBins(1) tBins(1)+FPs(end)/1000+1], 'ylim', [0.5 Nrat+0.5],...
        'ytick', 0:4:Nrat, 'yticklabel', [], 'xtick', 0:5,'xticklabel', [],  'ticklength', [0.02, 1], ...
        'XTickLabelRotation', 0);
    x_start_updated = x_start_updated+width_pdf+0.25;
    if i>1
        set(hadiff2(i) , 'yticklabel', [], 'xticklabel', []);
    end
    mycolormap =  customcolormap(linspace(0,1,11), {'#68011d','#b5172f','#d75f4e','#f7a580','#fedbc9','#f5f9f3','#d5e2f0','#93c5dc','#4295c1','#2265ad','#062e61'});
    colormap(hadiff(i), mycolormap)
    colormap(hadiff2(i), mycolormap)
    himg = imagesc(tBins, 1:Nrat, PDF_PressDuration_PostLesionLate{i}- PDF_PressDuration_PreLesion{i}, [-5 5]);
    line([FPs(i) FPs(i)]/1000, [0 Nrat+0.5], 'color', [0.75 0.75 0.75], 'linestyle', '--', 'linewidth', 1);

    if i==1
        % add colorbar
        hbar2 = colorbar('Southoutside');
        set(hbar2, 'units', 'centimeters', 'position',[x_start_updated-1.3  this_height-0.5 1 0.125])
        hbar2.Label.String = 'ΔPDF(1/s)';
        hbar2.Ticks = -5:5:5;
        hbar2.TickLength = 0.02;
    end
end
x_now = x_start_updated+0.5;

%% Plot distribution of pdf correlation score

plot_width = 1.5;
ccbins = 0:.1:3;
ccbins_center = ccbins(1:end-1)+0.5*(ccbins(2)-ccbins(1));
pdf_early = [];
pdf_late = [];

for i=1:length(FPs)
    hacc =  axes('unit', 'centimeters', 'position', [x_now  this_height+(i-1)*height_color*1.1 plot_width height_color], 'nextplot', 'add', ...
        'xlim', [0 3], 'ylim', [0 Nrat+1],...
        'ytick', [1 Nrat], 'xtick', [0:1:3],...
        'xscale', 'linear', 'yscale', 'linear', 'ticklength', [0.02, 1], ...
        'XTickLabelRotation', 0);
    
    pdf_early(i, :)= histcounts(squeeze(CrossCorrelation_PrePost( :,1, i)), ccbins, 'Normalization', 'cumcount');
    pdf_late(i, :)= histcounts(squeeze(CrossCorrelation_PrePostLate( :,1, i)), ccbins, 'Normalization', 'cumcount');
    pdf_pre(i, :)= histcounts(squeeze(CrossCorrelation_PrePre( :,1, i)), ccbins, 'Normalization', 'cumcount');

    stairs(ccbins_center, pdf_early(i, :), 'color', postlesion_col, 'linewidth', 0.5*i);
    stairs(ccbins_center, pdf_late(i, :), 'color', postlesion_col*0.8, 'linewidth', 0.5*i, 'linestyle','-.');
    stairs(ccbins_center, pdf_pre(i, :), 'color', 'k', 'linewidth', 0.5*i, 'linestyle','-.');
    if i==1
        xlabel('Correlation(F-trans)')
        ylabel('Count')
    else
        hacc.XTickLabel = {};
        hacc.YTickLabel = {};
    end
end

CrossCorr.Pre.Score = CrossCorrelation_PrePre;
CrossCorr.Early.Score = CrossCorrelation_PrePost;
CrossCorr.Late.Score = CrossCorrelation_PrePostLate;
CrossCorr.Pre.Hist = pdf_pre;
CrossCorr.Pre.HistBins = ccbins_center;
CrossCorr.Early.Hist = pdf_early;
CrossCorr.Early.HistBins = ccbins_center;
CrossCorr.Late.Hist = pdf_late;
CrossCorr.Late.HistBins = ccbins_center;

tosavefolder = fullfile(savePath, 'Output');
if ~exist(tosavefolder, 'dir')
    mkdir(tosavefolder);
end
tosavename = fullfile(tosavefolder, ['CrossCorrelationPDF_' type '.mat']);
save(tosavename, 'CrossCorr')

% also save PDF and so on: PDF_PeriLesion_All
%     PDF_PeriLesion_All{i}  = {tBins, PDF_PreLesion, PDF_PostLesion, RT_Pre, RT_Post, PDF_PostLesionLate, RT_PostLate, PDF_PreLesionTest};
PDF.Definition  = {'{tBins, PDF_PreLesion, PDF_PostLesion, RT_Pre, RT_Post, PDF_PostLesionLate, RT_PostLate, PDF_PreLesionTest}'}; 
PDF.Data        = PDF_PeriLesion_All;
PDF.NumOfRats   = Nrat;
PDF.Rats        = cellfun(@(x)x.Subject, GroupArray);

tosavename = fullfile(tosavefolder, ['PDF_' type '.mat']);
save(tosavename, 'PDF')

x_now = x_now + plot_width + 1.5;

%% Plot reaction time over 3 FPs
rt_plot_width = 2.5;
rt_plot_height = 2.5;
haRT =  axes('unit', 'centimeters', 'position', [x_now  this_height rt_plot_width rt_plot_height], 'nextplot', 'add', ...
    'xlim', Lim.RT_PrePost, 'ylim', Lim.RT_PrePost,...
    'ytick', 0:200:1000, 'xtick', 0:200:1000,...
    'xscale', 'linear', 'yscale', 'linear', 'ticklength', [0.02, 1], ...
    'XTickLabelRotation', 0);
line(get(haRT, 'xlim'), get(haRT, 'ylim'),'color','k','linestyle', ':')
xlabel(['Pre-' typeShort ' (ms)'])
ylabel(['Post-' typeShort ' (ms)'])
uicontrol('Style','text','Units','centimeters','Position',[x_now this_height+rt_plot_height+0.25  rt_plot_width 1],...
    'string', [typeShort ': ' strrep(type, '_', '-') '|Early'], ...
    'FontName',fontname, 'fontweight', 'bold','fontsize', 8,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Left');

x_now = x_now + rt_plot_width + 1.5;
haRTLate =  axes('unit', 'centimeters', 'position', [x_now  this_height rt_plot_width rt_plot_height], 'nextplot', 'add', ...
    'xlim', Lim.RT_PrePost, 'ylim', Lim.RT_PrePost,...
    'ytick', 0:200:1000, 'xtick', 0:200:1000,...
    'xscale', 'linear', 'yscale', 'linear', 'ticklength', [0.02, 1], ...
    'XTickLabelRotation', 0);
line(get(haRTLate, 'xlim'), get(haRTLate, 'ylim'),'color','k','linestyle', ':')
xlabel(['Pre-' typeShort ' (ms)'])
ylabel(['Post-' typeShort ' (ms)'])
uicontrol('Style','text','Units','centimeters','Position',[x_now this_height+rt_plot_height+0.25  rt_plot_width 1],...
    'string',[typeShort ': ' strrep(type, '_', '-') '|Late'], ...
    'FontName',fontname, 'fontweight', 'bold','fontsize', 8,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Left');
x_now = x_now + rt_plot_width + 0.5;

FPs_col = [136 74 57; 195, 129, 84; 255, 194, 111]/255; % brown-ish
FPs_col = [39, 55, 77; 82, 109, 130; 157, 178, 191]/255; % navy

RTs_Pre         = zeros(Nrat, length(FPs));
RTs_Post        = zeros(Nrat, length(FPs));
RTs_PostLate    = zeros(Nrat, length(FPs));

% PDF_PeriLesion_All{i}  = {tBins, PDF_PreLesion, PDF_PostLesion, RT_Pre, RT_Post, PDF_PostLesionLate, RT_PostLate};
% CDF_PeriLesion_All{i}  = {tBins, CDF_PreLesion, CDF_PostLesion, CDF_PostLesionLate};

IndPre          = 4;
IndPostEarly    = 5;
IndPostLater    = 7;
for k =1:Nrat
    for i =1:length(FPs)
        % rt_out
        iRT_Pre = PDF_PeriLesion_All{k}{IndPre}(:, i)*1000;
        iRT_Post = PDF_PeriLesion_All{k}{IndPostEarly}(:, i)*1000;
        iRT_PostLate = PDF_PeriLesion_All{k}{IndPostLater}(:, i)*1000;

        RTs_Pre(k, i)       = iRT_Pre(1);
        RTs_Post(k, i)      = iRT_Post(1);
        RTs_PostLate(k, i)  = iRT_PostLate(1);

        line(haRT, [iRT_Pre(1) iRT_Pre(1)], [iRT_Post([2 3])], 'color', FPs_col(i, :));
        line(haRT, [iRT_Pre([2 3])], [iRT_Post(1) iRT_Post(1)], 'color',FPs_col(i, :));
       
        line(haRTLate, [iRT_Pre(1) iRT_Pre(1)], [iRT_PostLate([2 3])], 'color', FPs_col(i, :));
        line(haRTLate, [iRT_Pre([2 3])], [iRT_PostLate(1) iRT_PostLate(1)], 'color',FPs_col(i, :));

        if iRT_Post(1)>1000
            scatter(haRT, iRT_Pre(1),1000, 'o','filled', 'MarkerEdgeColor', 'k', ...
                'MarkerFaceColor', FPs_col(i, :), 'MarkerFaceAlpha', 0.5, 'SizeData', 5+(i-1)*10);
        else
            scatter(haRT, iRT_Pre(1), iRT_Post(1), 'o','filled', 'MarkerEdgeColor', 'k', ...
                'MarkerFaceColor', FPs_col(i, :), 'MarkerFaceAlpha', 0.5, 'SizeData', 5+(i-1)*10);
        end
        if iRT_PostLate(1)>1000
            scatter(haRTLate, iRT_Pre(1),1000, 'o','filled', 'MarkerEdgeColor', 'k', ...
                'MarkerFaceColor', FPs_col(i, :), 'MarkerFaceAlpha', 0.5, 'SizeData', 5+(i-1)*10);
        else
            scatter(haRTLate, iRT_Pre(1), iRT_PostLate(1), 'o','filled', 'MarkerEdgeColor', 'k', ...
                'MarkerFaceColor', FPs_col(i, :), 'MarkerFaceAlpha', 0.5, 'SizeData', 5+(i-1)*10);
        end
    end
end

h_line = findobj(haRT,'Type','line');
h_scatter = findobj(haRT,'Type','Scatter');
h_children = [h_scatter; h_line];
set(haRT, 'Children', h_children)

h_line = findobj(haRTLate,'Type','line');
h_scatter = findobj(haRTLate,'Type','Scatter');
h_children = [h_scatter; h_line];
set(haRTLate, 'Children', h_children)

% make an axis to describe the figure
haRTinfo =  axes('unit', 'centimeters', 'position', [x_now   this_height+rt_plot_height 1 3], 'nextplot', 'add', ...
    'xlim', [0 10], 'ylim', [0 10],...
    'XTickLabelRotation', 0);
axis off
for i =1:length(FPs)
    scatter(2, 10-i, 'o','filled', 'MarkerEdgeColor', 'k', ...
        'MarkerFaceColor', FPs_col(i, :), 'MarkerFaceAlpha', 0.5, 'SizeData', 5+(i-1)*10);
    text(4, 10-i, ['FP= ' num2str(FPs(i))])
end

line([2 4], [6 6], 'color', 'k')
text(4, 6, '95% Cl')

% descript the statistics
% RTs_Pre, RTs_Post
PreLesionMean = [];
PostLesionMean = [];
PostLesionMeanLate = [];
DiffMean = [];
DiffMeanLate = [];

PreLesionSE = [];
PostLesionSE = [];
PostLesionSELate = [];
DiffSE = [];
DiffSELate = [];

for i =1:length(FPs)
    iRTs_Pre = RTs_Pre(:, i);
    PreLesionMean(i) = mean(iRTs_Pre);
    PreLesionSE(i) = std(iRTs_Pre)/sqrt(Nrat);

    iRTs_Post = RTs_Post(:, i);
    PostLesionMean(i) = mean(iRTs_Post);
    PostLesionSE(i) = std(iRTs_Post)/sqrt(Nrat);

    iRTs_PostLate = RTs_PostLate(:, i);
    PostLesionMeanLate(i) = mean(iRTs_PostLate);
    PostLesionSELate(i) = std(iRTs_PostLate)/sqrt(Nrat);

    Diff_RTs = RTs_Post(:, i)-RTs_Pre(:, i);
    DiffMean(i) = mean(Diff_RTs);
    DiffSE(i) = std(Diff_RTs)/sqrt(Nrat);

    Diff_RTs = RTs_PostLate(:, i)-RTs_Pre(:, i);
    DiffMeanLate(i) = mean(Diff_RTs);
    DiffSELate(i) = std(Diff_RTs)/sqrt(Nrat);
end

RT_table = table(FPs', PreLesionMean', PostLesionMean', PostLesionMeanLate', DiffMean', DiffMeanLate', ...
    PreLesionSE', PostLesionSE', PostLesionSELate', DiffSE',DiffSELate', ...
    'VariableNames', {'FP', 'Pre(mean)', 'Post(mean)','PostLate(mean)', 'Diff(mean)','DiffLate(mean)',...
    'Pre(se)', 'Post(se)', 'PostLate(se)', 'Diff(se)', 'DiffLate(se)'});

RT_table

tosavefolder = fullfile(savePath, 'DataTable', type);
if ~exist(tosavefolder, 'dir')
    mkdir(tosavefolder);
end
tosavename = fullfile(tosavefolder, ['ReactionTime_' type '.csv']);
writetable(RT_table, tosavename);

x_now = x_now + 1;
jitter = [-50 0 50];
markersize = 5;
rt_plot_width; 
rt_plot_height2 = 3;
haRT_all =  axes('unit', 'centimeters', 'position', [x_now  this_height rt_plot_width rt_plot_height2], 'nextplot', 'add', ...
    'xlim', [min(FPs)-mean(diff(FPs))/2 max(FPs)+mean(diff(FPs))/2], 'ylim', Lim.RT_FPs,...
    'ytick', 0:200:1000, 'xtick', FPs,...
    'ticklength', [0.02, 1], ...
    'XTickLabelRotation', 0);
ylabel('Reaction time (ms)')
xlabel('Foreperiod (ms)')

for i =1:length(FPs)

    he1= errorbar(FPs, PreLesionMean,PreLesionSE);
    he1.Color = prelesion_col;
    he1.LineWidth = 1;
    he1.Marker = 'o';
    he1.MarkerSize = markersize;

    he2= errorbar(FPs, PostLesionMean,PostLesionSE);
    he2.Color = postlesion_col;
    he2.LineWidth = 1;
    he2.Marker = 'o';
    he2.MarkerSize = markersize;

    he3= errorbar(FPs, PostLesionMeanLate,PostLesionSELate);
    he3.Color = postlesion_col*0.8;
    he3.LineWidth = 1;
    he3.LineStyle = ':';
    he3.Marker = 'o';
    he3.MarkerSize = markersize;

end

xlabel('Foreperiod (ms)')
ylabel('Reaction time (ms)')

%% Plot correct
x_start = 2;
yloc = 1.3;
axes('unit', 'centimeters', 'position', [x_start yloc+length(FPs)*height_col*1.3+0.75 width height],...
    'nextplot', 'add', 'xlim', [PeriLesion(1)-0.5 PeriLesion(end)+0.5], 'ylim', Lim.Correct,...
    'ytick', 0:20:100, 'xtick', PeriLesion(1):PeriLesion(end), 'xticklabel', PeriLesionLabels, 'ticklength', [0.02, 1], 'XTickLabelRotation', 0);
jitter = [-0.1 0 0.1 0];
% CorrectScore: nFP x NRats x LesionDay
for i = 1:size(CorrectScore, 1)  % FP
    if i<4
        score = squeeze(CorrectScore(i, :, :));
        mean_score = mean(score, 1, 'omitnan');
        se_score = std(score, 0, 1, 'omitnan')/sqrt(Nrat);
        for k = 1:length(mean_score)
            line(PeriLesion([k k])+jitter(i), [-1 1]*se_score(k)+mean_score(k), 'color', col_perf(1, :), 'linewidth', 0.5*i);
        end
        plot(PeriLesion+jitter(i), mean_score, 'color',  col_perf(1, :), 'linewidth', 0.5*i)
    end
end
line([0 0], Lim.Correct, 'color', [0.5 0.5 0.5], 'linestyle', '--', 'linewidth', 1)
ylabel('(%)')
title('Correct','fontweight','bold');
if Nrat>=10
    blankSep = '';
else
    blankSep = ' ';
end
text(PeriLesion(ceil(length(PeriLesion)/1.6)), Lim.Correct(1)+diff(Lim.Correct)/8, sprintf(['N=' blankSep '%2.0d'], Nrat))

%% Plot all rats in colormap
% score = squeeze(CorrectScore(2, :,:));
zscore_range = [-40 40]; % no longer z score.
indsort = [];
for i =1:length(FPs)
    ha(i) = axes('unit', 'centimeters', 'position', [x_start  yloc+(i-1)*height_col*1.3 width height_col], ...
        'nextplot', 'add', 'xlim', [PeriLesion(1)-0.5 PeriLesion(end)+0.5], 'ylim', [0.5 Nrat+0.5],...
        'ytick', 0:4:Nrat, 'xtick', PeriLesion(1):PeriLesion(end), 'xticklabel', PeriLesionLabels,...
        'ticklength', [0.02, 1], 'XTickLabelRotation', 0, 'Color','k');
    if i>1
        set(gca, 'yticklabel', {}, 'xticklabel', {});
    end
    % diff between pre and recovered
    %   CorrectScore                   4x16x14                7168  double
    score = squeeze(CorrectScore(i, :, :));
    ind_prelesion = PeriLesion<0;
    PreLesion_Performance = mean(score(:, ind_prelesion), 2);
    PreLesion_STD = std(score(:, ind_prelesion), 0, 2);
    %     score_z = (score-repmat(PreLesion_Performance, 1, size(score, 2)))./PreLesion_STD;
    score_z = (score-repmat(PreLesion_Performance, 1, size(score, 2))); % just plot the difference
    ind_postlesion = find(PeriLesion>0 & PeriLesion<=4);
    PostLesion_Performance = mean(score(:, ind_postlesion), 2, 'omitnan');
    DiffPerformance = PostLesion_Performance - PreLesion_Performance;
    %     if isempty(indsort)
    [~, indsort] = sort(DiffPerformance, 'descend'); % rearrange these rats, from bad to good recovery
    %     end
    disp(['Index for sorting, FP' num2str(FPs(i))])
    disp(indsort)
    score_sort = score_z(indsort, :);
    for m = 1:Nrat
        m_score = score_sort(m, :);
%         ind_notnan = find(~isnan(m_score));
%         imagesc(ha(i), PeriLesion(ind_notnan), m, m_score(ind_notnan), zscore_range);
        m_score_insert = [m_score(1:sum(ind_prelesion)),NaN,m_score(sum(ind_prelesion)+1:end)];
        himg = imagesc(ha(i), PeriLesion(1):PeriLesion(end), m, m_score_insert, zscore_range);
        set(himg,'alphadata',~isnan(m_score_insert));
    end
    % himg = imagesc(PeriLesion, [1:Nrat], score_sort, zscore_range);
    line([0 0], [0 Nrat+0.5], 'color', [0.75 0.75 0.75], 'linestyle', '--', 'linewidth', 1)
    % mycolormap = customcolormap([0 0.5 1], [1 1 1; 1 0 0; 0 0 0]);
    % hcbar = colorbar('location', 'EastOutSide','Units', 'Centimeters', 'Position', [6.25, 5.5, 0.25, 4*size(score, 1)/size(score, 2)]);
    % hcbar.Label.String = 'Z score';
    colormap(ha(i), mycolormap);
    if i ==1
        xlabel('Sessions ');
        ylabel('Rats')
    end
    title(['FP: ' num2str(FPs(i)) 'ms'])
    %
end
x_start = x_start+width+1;
%% Plot premature
axes('unit', 'centimeters', 'position', [x_start yloc+length(FPs)*height_col*1.3+0.75 width height], 'nextplot', 'add',...
    'xlim', [PeriLesion(1)-0.5 PeriLesion(end)+0.5], 'ylim', Lim.Premature, 'ytick', 0:20:100,...
    'xtick', PeriLesion(1):PeriLesion(end), 'xticklabel', PeriLesionLabels, 'ticklength', [0.02, 1],  'XTickLabelRotation', 0);
jitter = [-0.1 0 0.1 0];
for i = 1:size(PrematureScore, 1)  % FP
    if i<4
        score = squeeze(PrematureScore(i, :, :));
        mean_score = mean(score, 1, 'omitnan');
        se_score       = std(score, 0, 1, 'omitnan')/sqrt(Nrat);
        for k = 1:length(mean_score)
            line(PeriLesion([k k])+jitter(i), [-1 1]*se_score(k)+mean_score(k), 'color', col_perf(2, :), 'linewidth', 0.5*i);
        end
        plot(PeriLesion+jitter(i), mean_score, 'color',  col_perf(2, :), 'linewidth', 0.5*i)
    end
end

line([0 0], Lim.Premature, 'color', [0.5 0.5 0.5], 'linestyle', '--', 'linewidth', 1)

ylabel('(%)')
title('Premature','fontweight','bold');
%% Plot all rats in colormap
for i =1:length(FPs)
    ha(i)= axes('unit', 'centimeters', 'position', [x_start  yloc+(i-1)*height_col*1.3 width height_col], ...
        'nextplot', 'add', 'xlim', [PeriLesion(1)-0.5 PeriLesion(end)+0.5], 'ylim', [0.5 Nrat+0.5],...
        'ytick', 0:4:Nrat, 'xtick', PeriLesion(1):PeriLesion(end), 'xticklabel', PeriLesionLabels,'ticklength', [0.02, 1], ...
        'XTickLabelRotation', 0, 'Color','k');
    if i>1
        set(gca, 'yticklabel', [], 'xticklabel', []);
    end
    score = squeeze(PrematureScore(i, :, :));
    ind_prelesion = PeriLesion<0;
    PreLesion_Performance = mean(score(:, ind_prelesion), 2);
    PreLesion_STD = std(score(:, ind_prelesion), 0, 2);
    %     score_z = (score-repmat(PreLesion_Performance, 1, size(score, 2)))./PreLesion_STD;
    score_z = (score-repmat(PreLesion_Performance, 1, size(score, 2)));
    ind_postlesion = find(PeriLesion>0 & PeriLesion<=4);
    PostLesion_Performance = mean(score(:, ind_postlesion), 2, 'omitnan');
    %     if isempty(indsort)
    DiffPerformance = PostLesion_Performance - PreLesion_Performance;
    [~, indsort] = sort(DiffPerformance, 'descend'); % rearrange these rats, from bad to good recovery
    %     end;
    score_sort = score_z(indsort, :);
    for m = 1:Nrat
        m_score = score_sort(m, :);
%         ind_notnan = find(~isnan(m_score));
%         imagesc(ha(i), PeriLesion(ind_notnan), m, m_score(ind_notnan), zscore_range);
        m_score_insert = [m_score(1:sum(ind_prelesion)),NaN,m_score(sum(ind_prelesion)+1:end)];
        himg = imagesc(ha(i), PeriLesion(1):PeriLesion(end), m, m_score_insert, zscore_range); hold on;
        set(himg,'alphadata',~isnan(m_score_insert));
    end
%     himg = imagesc(PeriLesion, [1:Nrat], score_sort, zscore_range);
    line([0 0], [0 Nrat+0.5], 'color', [0.75 0.75 0.75], 'linestyle', '--', 'linewidth', 1)
    % mycolormap = customcolormap([0 0.5 1], [1 1 1; 1 0 0; 0 0 0]);
    % hcbar = colorbar('location', 'EastOutSide','Units', 'Centimeters', 'Position', [6.25, 5.5, 0.25, 4*size(score, 1)/size(score, 2)]);
    % hcbar.Label.String = 'Z score';
    colormap(ha(i), mycolormap);
    if i ==1
%         xlabel('Sessions ')
    end
    title(['FP: ' num2str(FPs(i)) 'ms'])
end

x_start = x_start+width+1;
%% Plot late
axes('unit', 'centimeters', 'position', [x_start yloc+length(FPs)*height_col*1.3+0.75 width height],...
    'nextplot', 'add', 'xlim', [PeriLesion(1)-0.5 PeriLesion(end)+0.5], 'ylim', Lim.Late,...
    'ytick', 0:20:100, 'xtick', PeriLesion(1):PeriLesion(end), 'xticklabel', PeriLesionLabels,  'ticklength', [0.02, 1],  'XTickLabelRotation', 0);
jitter = [-0.1 0 0.1 0];

for i = 1:size(LateScore, 1)  % FP
    if i<4
        score = squeeze(LateScore(i, :, :));
        mean_score = mean(score, 1, 'omitnan');
        se_score       = std(score, 0, 1, 'omitnan')/sqrt(Nrat);
        for k = 1:length(mean_score)
            line(PeriLesion([k k])+jitter(i), [-1 1]*se_score(k)+mean_score(k), 'color', col_perf(3, :), 'linewidth', 0.5*i);
        end
        plot(PeriLesion+jitter(i), mean_score, 'color',  col_perf(3, :), 'linewidth', 0.5*i);
    end
end

line([0 0], Lim.Late, 'color', [0.5 0.5 0.5], 'linestyle', '--', 'linewidth', 1)

ylabel('(%)')
title('Late','fontweight','bold')
%% Plot all rats in colormap
for i =1:length(FPs)
    ha(i)=axes('unit', 'centimeters', 'position', [x_start  yloc+(i-1)*height_col*1.3 width height_col], ...
        'nextplot', 'add', 'xlim', [PeriLesion(1)-0.5 PeriLesion(end)+0.5], 'ylim', [0.5 Nrat+0.5],...
        'ytick', 0:4:Nrat, 'xtick', PeriLesion(1):PeriLesion(end), 'xticklabel', PeriLesionLabels,...
        'ticklength', [0.02, 1], 'XTickLabelRotation', 0, 'Color','k');

    if i>1
        set(gca, 'yticklabel', [], 'xticklabel', []);
    end
    score = squeeze(LateScore(i, :, :));
    ind_prelesion = PeriLesion<0;
    PreLesion_Performance = mean(score(:, ind_prelesion), 2);
    PreLesion_STD = std(score(:, ind_prelesion), 0, 2);
%     score_z = (score-repmat(PreLesion_Performance, 1, size(score, 2)))./PreLesion_STD;
    score_z = (score-repmat(PreLesion_Performance, 1, size(score, 2)));
    ind_postlesion = find(PeriLesion>0 & PeriLesion<=4);
    PostLesion_Performance = mean(score(:, ind_postlesion), 2, 'omitnan');
    DiffPerformance = PostLesion_Performance - PreLesion_Performance;
    [~, indsort] = sort(DiffPerformance, 'descend'); % rearrange these rats, from bad to good recovery
    score_sort = score_z(indsort, :);
    for m = 1:Nrat
        m_score = score_sort(m, :);
%         ind_notnan = find(~isnan(m_score));
%         imagesc(ha(i), PeriLesion(ind_notnan), m, m_score(ind_notnan), zscore_range);
        m_score_insert = [m_score(1:sum(ind_prelesion)),NaN,m_score(sum(ind_prelesion)+1:end)];
        himg = imagesc(ha(i), PeriLesion(1):PeriLesion(end), m, m_score_insert, zscore_range);
        set(himg,'alphadata',~isnan(m_score_insert));
    end
%     himg = imagesc(PeriLesion, [1:Nrat], score_sort, zscore_range);
    line([0 0], [0 Nrat+0.5], 'color', [0.75 0.75 0.75], 'linestyle', '--', 'linewidth', 1);
    % mycolormap = customcolormap([0 0.5 1], [1 1 1; 1 0 0; 0 0 0]);
    % hcbar = colorbar('location', 'EastOutSide','Units', 'Centimeters', 'Position', [6.25, 5.5, 0.25, 4*size(score, 1)/size(score, 2)]);
    % hcbar.Label.String = 'Z score';
    colormap(ha(i), mycolormap);
    if i ==1
%         xlabel('Sessions ')
    end
    title(['FP: ' num2str(FPs(i)) 'ms'])
end
x_start = x_start+width+0.25;
hbar = colorbar;
set(hbar, 'units', 'centimeters', 'position',[x_start 1.3 0.125 1])
hbar.Label.String = 'Δ%';

x_start = x_start + 2;

%% Plot performance over specific trials pre- and post lesion.
Perfs = {'Correct', 'Premature', 'Late'};
y_range = [Lim.Correct(:)'; Lim.Premature(:)'; Lim.Late(:)'];
xlimTrials = [-N_included + win_size/2 + step_size, N_included - win_size/2] + 1;
% xlimTrials = [-N_included,N_included];
indsort = [];
for ip = 1:length(Perfs)
    iPerf = Perfs{ip};
    ha_perf = axes('unit', 'centimeters', 'position', [x_start yloc+length(FPs)*height_col*1.3+0.75 width height], 'nextplot', 'add', ...
        'xlim', xlimTrials, 'ylim', y_range(ip, :),...
        'ytick', 0:20:100, 'xtick', -2000:500:2000, 'ticklength', [0.02, 1],  'XTickLabelRotation', 0);
    score_pre_all = [];
    score_post_all= [];
    for i = 1:length(FPs) % FP
        score_pre = [];
        score_post = [];
        % discover the max TrialIndexPre
        for n=1:size(PeriLesionScore, 2)
            if n == 1
                TrialIndexPre = PeriLesionScore{1, 1}.TrialIndex;
            else
                if length(PeriLesionScore{1, n}.TrialIndex)>length(TrialIndexPre)
                    TrialIndexPre = PeriLesionScore{1, n}.TrialIndex;
                end
            end
        end
        TrialIndexPre = TrialIndexPre-N_included;
        score_pre = NaN*ones(Nrat, length(TrialIndexPre));
        for j =1:size(PeriLesionScore,2)
            eval(['this_score = PeriLesionScore{1, j}.' iPerf '(:, i);'])
            %             this_score = PeriLesionScore{1, j}.Correct(:, i);
            score_pre(j, 1:length(this_score)) = this_score;
        end

        score_pre_all(:,:, i) = score_pre;
        score_post = NaN*ones(Nrat, length(TrialIndexPre));

        % discover the max TrialIndexPre
        for n=1:size(PeriLesionScore, 2)
            if n== 1
                TrialIndexPost = PeriLesionScore{2, 1}.TrialIndex;
            else
                if length(PeriLesionScore{2, n}.TrialIndex)>length(TrialIndexPost)
                    TrialIndexPost = PeriLesionScore{2, n}.TrialIndex;
                end
            end
        end
        for j =1:size(PeriLesionScore,2)
            eval(['this_score = PeriLesionScore{2, j}.' iPerf '(:, i);']);
            % this_score = PeriLesionScore{2, j}.Correct(:, i);
            score_post(j, 1:length(this_score)) = this_score;
        end
        score_post_all(:,:, i) = score_post;
        mean_score_pre  = mean(score_pre, 1, 'omitnan');
        se_score_pre    = std(score_pre, 0, 1, 'omitnan')/sqrt(Nrat);

        mean_score_post = mean(score_post, 1, 'omitnan');
        se_score_post   = std(score_post, 0, 1, 'omitnan')/sqrt(Nrat);

        axes(ha_perf)
        plotshaded(TrialIndexPre,  [mean_score_pre-se_score_pre; mean_score_pre+se_score_pre],  col_perf(ip, :), 0.25);
        plotshaded(TrialIndexPost,  [mean_score_post-se_score_post; mean_score_post+se_score_post],  col_perf(ip, :), 0.25);

        plot(ha_perf,TrialIndexPre, mean_score_pre, 'color',  col_perf(ip, :), 'linewidth', 0.5*i)
        plot(ha_perf,TrialIndexPost, mean_score_post, 'color',  col_perf(ip, :), 'linewidth', 0.5*i)

        line([-.5 -.5], [0 100], 'color', [0.5 0.5 0.5], 'linestyle', '--', 'linewidth', 1)
        ylabel('(%)')
        title(iPerf,'fontweight','bold')

        TrialIndex = [TrialIndexPre TrialIndexPost];

        %% Plot all rats in colormap
        zscore_range = [-40 40];
        diff_TrialIndex = TrialIndex(2) - TrialIndex(1);
        
        ha = axes('unit', 'centimeters', 'position', [x_start  yloc+(i-1)*height_col*1.3 width height_col], ...
            'nextplot', 'add', 'xlim',xlimTrials, 'ylim', [0.5 Nrat+0.5],...
            'ytick', 0:4:Nrat, 'xtick', -2000:500:2000,  'ticklength', [0.02, 1], ...
            'XTickLabelRotation', 0, 'color','k');
        if i>1
            set(gca, 'yticklabel', [], 'xticklabel', []);
        end
        score_pre       = score_pre_all(:,:,i);
        score_post      = score_post_all(:,:,i);
        score_prepost   = [score_pre score_post];
        baseline        = median(score_pre, 2, 'omitnan');
        var             = std(score_pre, 0, 2, 'omitnan');
        diff_performance = zeros(1, Nrat);

        for j =1:Nrat
            var(j) = 1;
            score_prepost(j, :) = (score_prepost(j, :)-baseline(j))/var(j);
            diff_performance(j) = mean(score_post(j, :), 'omitnan') - mean(score_pre(j, :), 'omitnan');
        end
        %         if isempty(indsort)
        [~, indsort] = sort(diff_performance, 'descend');
        %         end
        score_prepost = score_prepost(indsort, :);
        for m = 1:Nrat
            m_score = score_prepost(m, :);
            ind_notnan = find(~isnan(m_score));
            imagesc(ha, TrialIndex(ind_notnan), m, m_score(ind_notnan), zscore_range);
%             mimg = imagesc(ha, TrialIndex, m, m_score, zscore_range);
%             set(mimg, 'alphadata', ~isnan(m_score));
        end

        line(ha, [0 0], [0.5 Nrat+0.5], 'color', [0.75 0.75 0.75], 'linestyle', '--', 'linewidth', 1)
        % mycolormap = customcolormap([0 0.5 1], [1 1 1; 1 0 0; 0 0 0]);
        % hcbar = colorbar('location', 'EastOutSide','Units', 'Centimeters', 'Position', [6.25, 5.5, 0.25, 4*size(score, 1)/size(score, 2)]);
        % hcbar.Label.String = 'Z score';
        colormap(ha, mycolormap);
        if i==1 && ip==1
            xlabel(['Trials since ' lower(typeShort)])
        end
        title(['FP: ' num2str(FPs(i)) 'ms'])
        %
    end
    x_start = x_start + width +1;
end
hbar = colorbar;
set(hbar, 'units', 'centimeters', 'position',[x_start-0.75 1.3 0.125 1]);

x_start = x_start + 0.5;
%% Plot reaction time     RTAccum(:, i) = {PreLesionRT, PostLesionRT};
axes('unit', 'centimeters', 'position', [x_start yloc+length(FPs)*height_col*1.3+0.75 width height], 'nextplot', 'add', ...
    'xlim', xlimTrials, 'ylim', Lim.RT,...
    'ytick', 0:200:1000, 'xtick', -2000:500:2000, 'ticklength', [0.02, 1],  'XTickLabelRotation', 0);
rt_pre_all = [];
rt_post_all= [];
for i = 1:length(FPs) % FP
    rt_pre = [];
    rt_post = [];
    for n=1:size(RTAccum, 2)
        if n == 1
            TrialIndexPre = RTAccum{1, 1}.TrialIndex;
        else
            if length(RTAccum{1, n}.TrialIndex)>length(TrialIndexPre)
                TrialIndexPre = RTAccum{1, n}.TrialIndex;
            end
        end
    end
    TrialIndexPre = TrialIndexPre-N_included;
    rt_pre = NaN*ones(Nrat, length(TrialIndexPre));
    for j =1:Nrat
        this_rt = 1000*RTAccum{1, j}.RT(:, i);
        rt_pre(j, 1:length(this_rt)) = this_rt;
    end
    rt_pre_all(:,:, i) = rt_pre;
    for n=1:size(RTAccum, 2)
        if n == 1
            TrialIndexPost = RTAccum{2, 1}.TrialIndex;
        else
            if length(RTAccum{2, n}.TrialIndex)>length(TrialIndexPost)
                TrialIndexPost = RTAccum{2, n}.TrialIndex;
            end
        end
    end
    rt_post = NaN*ones(Nrat, length(TrialIndexPost));
    for j =1:Nrat
        this_rt = 1000*RTAccum{2, j}.RT(:, i);
        rt_post(j, 1:length(this_rt)) = this_rt;
    end
    rt_post_all(:,:, i) = rt_post;
    mean_rt_pre = mean(rt_pre, 1, 'omitnan');
    se_rt_pre = std(rt_pre, 0, 1, 'omitnan')/sqrt(Nrat);
    mean_rt_post = mean(rt_post, 1, 'omitnan');
    se_rt_post = std(rt_post, 0, 1, 'omitnan')/sqrt(Nrat);
    plotshaded(TrialIndexPre,  [mean_rt_pre-se_rt_pre; mean_rt_pre+se_rt_pre],  'k', 0.25);
    plotshaded(TrialIndexPost,  [mean_rt_post-se_rt_post; mean_rt_post+se_rt_post],  'k', 0.25);
    plot(TrialIndexPre, mean_rt_pre, 'color', 'k', 'linewidth', 0.5*i);
    plot(TrialIndexPost, mean_rt_post, 'color',  'k', 'linewidth', 0.5*i);
end
line([0 0], Lim.RT, 'color', [0.5 0.5 0.5], 'linestyle', '--', 'linewidth', 1)
ylabel('(ms)')
title('Reaction time','fontweight','bold')
TrialIndex = [TrialIndexPre TrialIndexPost];

%% Reaction time colormap
zscore_range = [-300 300];
for i =1:length(FPs)
    ha=axes('unit', 'centimeters', 'position', [x_start  yloc+(i-1)*height_col*1.3 width height_col], ...
        'nextplot', 'add', 'xlim', xlimTrials, 'ylim', [0.5 Nrat+0.5],...
        'ytick', 0:4:Nrat, 'xtick', -2000:500:2000, 'ticklength', [0.02, 1], ...
        'XTickLabelRotation', 0, 'color', 'k');
    if i>1
        set(gca, 'yticklabel', [], 'xticklabel', []);
    end

    rt_pre = rt_pre_all(:,:,i);
    rt_post = rt_post_all(:,:,i);
    rt_prepost = [rt_pre rt_post];
    baseline = median(rt_pre, 2, 'omitnan');
    var = std(rt_pre, 0, 2, 'omitnan');

    diff_rt = zeros(1, Nrat);

    for j =1:Nrat
        var(j)=1;
        rt_prepost(j, :) = (rt_prepost(j,:)-baseline(j))/var(j);
        diff_rt(j) = mean(rt_post(j,:), 'omitnan') - mean(rt_pre(j,:), 'omitnan');
    end
    [~, indsort] = sort(diff_rt, 'descend');
    rt_prepost = rt_prepost(indsort, :);
    for m = 1:Nrat
        m_score = rt_prepost(m, :);
        ind_notnan = find(~isnan(m_score));
        imagesc(ha, TrialIndex(ind_notnan), m, m_score(ind_notnan), zscore_range);
    end

    line([0 0], [0 Nrat+0.5], 'color', [0.75 0.75 0.75], 'linestyle', '--', 'linewidth', 1);
    % mycolormap = customcolormap([0 0.5 1], [1 1 1; 1 0 0; 0 0 0]);
    % hcbar = colorbar('location', 'EastOutSide','Units', 'Centimeters', 'Position', [6.25, 5.5, 0.25, 4*size(score, 1)/size(score, 2)]);
    % hcbar.Label.String = 'Z score';
    colormap(ha, mycolormap);
    if i ==1
%         xlabel('Trials ')
    end
    title(['FP: ' num2str(FPs(i)) 'ms'])
end
x_start = x_start+width+0.25;
hbar = colorbar;
set(hbar, 'units', 'centimeters', 'position',[x_start 1.3 0.125 1])
hbar.Label.String = 'ΔRT(ms)';

%% Plot hold time IQR
x_start = x_start + 1.5;
axes('unit', 'centimeters', 'position', [x_start yloc+length(FPs)*height_col*1.3+0.75 width height], 'nextplot', 'add', ...
    'xlim', xlimTrials, 'ylim', Lim.HTIQR,...
    'ytick', 0:500:1000, 'xtick', -2000:500:2000, 'ticklength', [0.02, 1],  'XTickLabelRotation', 0);
iqr_pre_all = [];
iqr_post_all= [];
for i = 1:length(FPs) % FP
    iqr_pre = [];
    iqr_post = [];
    for n=1:size(RTAccum, 2)
        if n == 1
            TrialIndexPre = RTAccum{1, 1}.TrialIndex;
        else
            if length(RTAccum{1, n}.TrialIndex)>length(TrialIndexPre)
                TrialIndexPre = RTAccum{1, n}.TrialIndex;
            end
        end
    end
    TrialIndexPre = TrialIndexPre-N_included;
    %     PostLesionRT = struct('RT', [], 'HoldTimeIQR', [],  'TrialIndex', []);
    ht_iqr_pre = NaN*ones(Nrat, length(TrialIndexPre));
    for j =1:Nrat
        this_iqr = 1000*RTAccum{1, j}.HoldTimeIQR(:, i);
        ht_iqr_pre(j, 1:length(this_iqr)) = this_iqr;
    end
    iqr_pre_all(:,:, i) = ht_iqr_pre;

    for n=1:size(RTAccum, 2)
        if n == 1
            TrialIndexPost = RTAccum{2, 1}.TrialIndex;
        else
            if length(RTAccum{2, n}.TrialIndex)>length(TrialIndexPost)
                TrialIndexPost = RTAccum{2, n}.TrialIndex;
            end
        end
    end
    ht_iqr_post = NaN*ones(Nrat, length(TrialIndexPost));
    for j =1:Nrat
        this_iqr = 1000*RTAccum{2, j}.HoldTimeIQR(:, i);
        ht_iqr_post(j, 1:length(this_iqr)) = this_iqr;
    end
    iqr_post_all(:,:, i) = ht_iqr_post;

    mean_iqr_pre = median(ht_iqr_pre, 1, 'omitnan');
    se_iqr_pre = std(ht_iqr_pre, 0, 1, 'omitnan')/sqrt(Nrat);

    mean_iqr_post = median(ht_iqr_post, 1, 'omitnan');
    se_iqr_post = std(ht_iqr_post, 0, 1, 'omitnan')/sqrt(Nrat);

    plotshaded(TrialIndexPre, [mean_iqr_pre-se_iqr_pre; mean_iqr_pre+se_iqr_pre],  'k', 0.25);
    plotshaded(TrialIndexPost, [mean_iqr_post-se_iqr_post; mean_iqr_post+se_iqr_post],  'k', 0.25);
    
    plot(TrialIndexPre, mean_iqr_pre, 'color', 'k', 'linewidth', 0.5*i);
    plot(TrialIndexPost, mean_iqr_post, 'color',  'k', 'linewidth', 0.5*i);
end
line([0 0], Lim.HTIQR, 'color', [0.5 0.5 0.5], 'linestyle', '--', 'linewidth', 1);
ylabel('(ms)')
title('Hold time IQR','fontweight','bold')
TrialIndex = [TrialIndexPre TrialIndexPost];

%% Hold time iqr colormap
zscore_range = [-1000 1000];
for i =1:length(FPs)
    ha=axes('unit', 'centimeters', 'position', [x_start  yloc+(i-1)*height_col*1.3 width height_col], ...
        'nextplot', 'add', 'xlim', xlimTrials, 'ylim', [0.5 Nrat+0.5],...
        'ytick', [0:4:Nrat], 'xtick', -2000:500:2000, 'ticklength', [0.02, 1], ...
        'XTickLabelRotation', 0, 'color', 'k');
    if i>1
        set(gca, 'yticklabel', [], 'xticklabel', []);
    end

    iqr_pre = iqr_pre_all(:,:,i);
    iqr_post = iqr_post_all(:,:,i);
    iqr_prepost = [iqr_pre iqr_post];
    baseline = median(iqr_pre, 2, 'omitnan');
    var = std(iqr_post, 0, 2, 'omitnan');
    diff_rt = zeros(1, Nrat);

    for j =1:Nrat
        var(j)=1;
        iqr_prepost(j, :) = (iqr_prepost(j,:)-baseline(j))/var(j);
        diff_iqr(j) = mean(iqr_post(j,:), 'omitnan') - mean(iqr_pre(j,:), 'omitnan');
    end

    [~, indsort] = sort(diff_iqr, 'descend');
    iqr_prepost = iqr_prepost(indsort, :);

    for m = 1:Nrat
        m_score = iqr_prepost(m, :);
        ind_notnan = find(~isnan(m_score));
        imagesc(ha, TrialIndex(ind_notnan), m, m_score(ind_notnan), zscore_range);
    end

    line([0 0], [0 Nrat+0.5], 'color', [0.75 0.75 0.75], 'linestyle', '--', 'linewidth', 1);
    % mycolormap = customcolormap([0 0.5 1], [1 1 1; 1 0 0; 0 0 0]);
    % hcbar = colorbar('location', 'EastOutSide','Units', 'Centimeters', 'Position', [6.25, 5.5, 0.25, 4*size(score, 1)/size(score, 2)]);
    % hcbar.Label.String = 'Z score';
    colormap(ha, mycolormap);
    if i ==1
%         xlabel('Trials ')
    end
    title(['FP: ' num2str(FPs(i)) 'ms'])
end
x_start = x_start+width+0.25;
hbar = colorbar;
set(hbar, 'units', 'centimeters', 'position',[x_start 1.3 0.125 1])
hbar.Label.String = 'ΔIQR(ms)';

%% save figures
tosavefolder = fullfile(savePath, 'Figures', type);
if ~exist(tosavefolder, 'dir')
    mkdir(tosavefolder);
end
tosavename = ['GroupData_' type];
tosavename = fullfile(tosavefolder, tosavename);
print(hf,'-dpng', tosavename);
print(hf,'-depsc', tosavename);
print(hf,'-dpdf', tosavename); % containing tranparency
saveas(hf, tosavename, 'fig');

function [Performance, RT, IQR] = compute_performance(obj, index)
FPs = obj.MixedFP;
FP_index = obj.FP(index);
CorrectRatio = zeros(1, length(FPs));
PrematureRatio = zeros(1, length(FPs));
LateRatio = zeros(1, length(FPs));
RT = zeros(1, length(FPs));

for i =1:length(FPs)
    index_iFP = index(find(FP_index == FPs(i)));
    i_outcome = obj.Outcome(index_iFP);
    CorrectRatio(i) = 100*sum(strcmp(i_outcome, 'Correct'))/length(i_outcome);
    PrematureRatio(i) = 100*sum(strcmp(i_outcome, 'Premature'))/length(i_outcome);
    LateRatio(i) = 100*sum(strcmp(i_outcome, 'Late'))/length(i_outcome);
    IndSelected = index_iFP(strcmp(obj.Outcome(index_iFP)', 'Correct') | strcmp(obj.Outcome(index_iFP)', 'Late'));
    RTs_this = obj.ReactionTime(IndSelected);
    thisRT = calRT(RTs_this, [], 'Remove100ms', 1, 'RemoveOutliers', 0, 'ToPlot', 0, 'CalSE', 0);
    RT(i) = thisRT.median;
end
Performance.Correct = CorrectRatio;
Performance.Premature = PrematureRatio;
Performance.Late = LateRatio;

% computing IQR for the hold time distribution
IQR = zeros(1, length(FPs));
for i =1:length(FPs)
    index_iFP = index(find(FP_index == FPs(i)));
    i_outcome = obj.Outcome(index_iFP);
    IndSelected = index_iFP(~strcmp(obj.Outcome(index_iFP)', 'Dark'));
    HTs_this = obj.HoldTime(IndSelected);
    IQR(i) = diff(prctile(HTs_this, [25 75]));
end

function [pdf_out, cdf_out, hold_time]= calPDF(obj, index)
%     [PDF_PreLesion, CDF_PreLesion, HoldTimePre. RTPre]                   =       calPDF(iClass, IndPreLesion2);
FPs = obj.MixedFP;
FP_index = obj.FP(index);
pdf_out = zeros(length(obj.HoldTbinEdges), length(FPs));
cdf_out = zeros(length(obj.HoldTbinEdges), length(FPs));
hold_time = cell(1, length(FPs));
for i =1:length(FPs)
    index_iFP = index(FP_index == FPs(i));
    i_holdtime = obj.HoldTime(index_iFP);
    hold_time{i} = i_holdtime;
    pdf_out(:, i) = ksdensity(i_holdtime, obj.HoldTbinEdges,'function', 'pdf');
    cdf_out(:, i) = ksdensity(i_holdtime, obj.HoldTbinEdges,'function', 'cdf');
end

function rt_out = calRTlocal(obj, index)
FPs = obj.MixedFP;
FP_index = obj.FP(index);

rt_out = zeros(3, length(FPs));
%             RTOutStrict = calRT(RTStrict_this, [], 'Remove100ms', 1, 'RemoveOutliers', 0, 'ToPlot', 0, 'CalSE', 0);
for i =1:length(FPs)
    % compute reaction time
    index_iFP = index(FP_index == FPs(i) & (strcmp(obj.Outcome(index)', 'Correct')|strcmp(obj.Outcome(index)', 'Late')));
    i_reactiontime = obj.ReactionTime(index_iFP);
    i_reactiontime=i_reactiontime(i_reactiontime>0.1);
    tic
    rt_out(:, i) = [median(i_reactiontime); bootci(1000, @median, i_reactiontime)];
    toc
end

function   [cc_max, t_cc_max] = compute_ccmax(tbins, pdf_1, pdf_2)

% compute cross-correlation of two PDFs
fig_cc = 66;
figure(fig_cc);
clf(fig_cc);
diff_bin = tbins(2)-tbins(1);

ha1 = subplot(2, 1, 1);
plot(tbins, pdf_1, 'k');
hold on
plot(tbins, pdf_2, 'r');

ha2=subplot(2, 1, 2);
[c, lags]=xcov(pdf_1, pdf_2, 20, 'normalized');
plot(lags*diff_bin, c, 'k', 'linewidth', 2);

t_cc_max = lags(find(c==max(c)))*diff_bin;
cc_max = atanh(max(c));
line([t_cc_max t_cc_max], get(gca, 'ylim'),'color','m')
 

% function image_this(haxis, t, index, data_mat, color_rage, thiscolormap)
%
% cmap = thiscolormap;
% data_mat(data_mat>color_rage(2))=color_rage(2);
% data_mat(data_mat<color_rage(1))=color_rage(1);
%
% I = double(data_mat);
% I = rescale(I, 0, 256);
% I = ceil(I);
% I = ind2rgb(I, cmap);
% % Handle nan value
% colorToChange = [0 0 0]; % arbitary color in RGB
% colorToChange = reshape(colorToChange, 1, 1, 3);
%
% colorMask = isnan(data_mat);
% I = I .* ~colorMask; % make sure your matlab version is new enough for dimension broadcasting, or handle it mannually
% I = I + colorMask .* colorToChange;
% % Display
% image(haxis, t, index, I);
% []
