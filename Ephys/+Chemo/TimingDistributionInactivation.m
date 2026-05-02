function TimingOut = TimingDistributionInactivation(obj, SalineSessionsSelected, DCZSessionsSelected, random_seed, name)
if nargin<5
    name = []; % this name is for marking the saved files and figures
    if nargin<4
        random_seed = 4;
    end
end
TimingOut                                =      [];
TimingOut.ANM                       =       obj.Subject;
TimingOut.SalineSessions      =        SalineSessionsSelected;
TimingOut.DCZSessions         =        DCZSessionsSelected;
n_repeats                                =          length(SalineSessionsSelected);

nplot_cue = 10;
nplot_uncue = 20;

xnow =-2;
plot_width = 3;
plot_height = 2;
plot_height2 = 1.5;
vspacing = 1.3;
uncue_color = [0.7 0.7 0.7];

FP_colors           =   {'#9BBEC8', '#427D9D', '#164863'};
inactivation_color  =   '#FF6C22';

marker_size = 5;
FP_shade_color = [0.3 0.8 0.5];
marker_type = 'o';
FPs = [500 1000 1500 2000]/1000;
CurrentFP = mode(obj.FP);
FP_Color = FP_colors{min(find(FPs*1000==CurrentFP), 3)};
TimingOut.FP = CurrentFP/1000;
nFP = 1;
rng(random_seed)
% rng(5)
trange  =[0 CurrentFP/1000+1.5];
categories = [0 0.3 0.6 5]; % response duration less than 0.1+FP,
TimeBins = categories;
TimingOut.TimeCategories = categories;
close all;

hf = figure(45);
clf(hf)
set(gcf, 'units', 'Centimeters', 'position',[2 2 19.5 18],...
    'Visible','on', 'paperpositionmode', 'auto', 'color', 'w');
xbins       =     (0:0.05:4);
kernel_bw   =     0.08;
nboot       =     1000;
pdf_range   =     [0 4];
TimingOut.KernelBW = kernel_bw;
TimingOut.nboot = nboot;
Conditions = {'cue', 'uncue'};

category_cells_saline_combined = zeros(1, length(categories));    % combined across repeats
category_cells_dcz_combined = zeros(1, length(categories));        % combined across repeats

PressDurations = cell(2, n_repeats); % combine press duration across sessions.
PressDurationsDCZ = cell(2, n_repeats); % combine press duration across sessions.
xnow = 2;

for ii =1:n_repeats

    ynow = 14;
    disp(ii)
    % Plot all trials from saline session
    Saline1                     = SalineSessionsSelected{ii};
    DCZ1                        = DCZSessionsSelected{ii};

    Ind_Saline1               = find(strcmp(obj.Dates,Saline1));
    Press_Saline1           = obj.HoldTime(obj.PressIndex == Ind_Saline1);
    FPs_Saline1             = obj.FP(obj.PressIndex == Ind_Saline1);
    Stage_Saline1          = obj.Stage(obj.PressIndex == Ind_Saline1);
    Outcome_Saline1     = transpose(obj.Outcome(obj.PressIndex == Ind_Saline1));
    Cue_Saline1             = obj.Cue(obj.PressIndex == Ind_Saline1);
    PDF_Saline              = cell(2, 1); % two conditions, cue and uncue, nFP is 1 for this type of task

    pvals                         = zeros(2, 1);
    category_cells_saline = zeros(2, length(categories)); % 2: cue and uncue
    category_cells_dcz = zeros(2, length(categories));

    % Compute PDF and distribution (Cue)
    PressDurCue                             =       Press_Saline1(FPs_Saline1 == CurrentFP & Stage_Saline1==1 & Cue_Saline1==1);
    kOutcomeCue                            =       Outcome_Saline1(FPs_Saline1 == CurrentFP & Stage_Saline1==1 & Cue_Saline1==1);
    PressDurCue(strcmp(kOutcomeCue, 'Dark'))  =       [];
    PressDurations{1,   ii}               =   PressDurCue;
    CurrentFPSec=CurrentFP/1000;
    category_cells_saline(1, 1) = sum(PressDurCue<CurrentFPSec);
    category_cells_saline(1, 2) = sum(PressDurCue>CurrentFPSec & PressDurCue<categories(2)+CurrentFPSec);
    category_cells_saline(1, 3) = sum(PressDurCue>CurrentFPSec+categories(2) & PressDurCue<categories(3)+CurrentFPSec);
    category_cells_saline(1, 4) = sum(PressDurCue>CurrentFPSec+categories(3) & PressDurCue<categories(4)+CurrentFPSec);
    [f,  f_ci, xi]                            =       ksdensity_ci(PressDurCue, xbins,kernel_bw, nboot);
    PDF_Saline{1}                     =       [xi', f', f_ci'];

    % Compute PDF and distribution (Uncue)
    PressDurUncue                       =       Press_Saline1(FPs_Saline1 == CurrentFP & Stage_Saline1==1 & Cue_Saline1==0);
    kOutcomeUncue                      =       Outcome_Saline1(FPs_Saline1 == CurrentFP & Stage_Saline1==1 & Cue_Saline1==0);
    PressDurUncue(strcmp(kOutcomeUncue, 'Dark'))  =       [];
    PressDurations{2,   ii}               =     PressDurUncue;

    category_cells_saline(2, 1) = sum(PressDurUncue<CurrentFPSec);
    category_cells_saline(2, 2) = sum(PressDurUncue>CurrentFPSec & PressDurUncue<categories(2)+CurrentFPSec);
    category_cells_saline(2, 3) = sum(PressDurUncue>CurrentFPSec+categories(2) & PressDurUncue<categories(3)+CurrentFPSec);
    category_cells_saline(2, 4) = sum(PressDurUncue>CurrentFPSec+categories(3) & PressDurUncue<categories(4)+CurrentFPSec);
    [f,  f_ci, xi]                           =       ksdensity_ci(PressDurUncue, xbins,kernel_bw, nboot);
    PDF_Saline{2}                       =       [xi', f', f_ci'];
    disp('category_cells_saline')
    disp(category_cells_saline)

    %% Plot saline session
    %    Plot the data (Cue)
    n = floor(length(PressDurCue)/2);
    PressDurCue_a               = PressDurCue(1:n);
    PressDurCue_b               = PressDurCue(end-n+1:end);
    if n>nplot_cue
        nplot = nplot_cue;
    elseif n>5
        nplot = 5;
    else
        nplot = n;
    end
    IndRandPerm                          = randperm(n, nplot);
    PressDurCue_a_Selected       = PressDurCue_a(IndRandPerm);
    PressDurCue_b_Selected       = PressDurCue_b(IndRandPerm);

    %    Plot the data (Uncue)
    n = floor(length(PressDurUncue)/2);
    PressDurUncue_a               = PressDurUncue(1:n);
    PressDurUncue_b               = PressDurUncue(end-n+1:end);
    if n>nplot_uncue
        nplot = nplot_uncue;
    elseif n>5
        nplot = 5;
    else
        nplot = n;
    end
    IndRandPerm               = randperm(n, nplot);
    PressDurUncue_a_Selected       = PressDurUncue_a(IndRandPerm);
    PressDurUncue_b_Selected       = PressDurUncue_b(IndRandPerm);

    % Plot these data
    % Plot first half, cue and uncue
    num_cue_plot            = length(PressDurCue_a_Selected);
    num_uncue_plot        =length(PressDurUncue_a_Selected);
    ha1 = axes('units', 'centimeters', ...
        'position', [xnow, ynow plot_width plot_height], ...
        'ydir','normal','nextplot', 'add', ...
        'xlim',trange, 'ylim', ...
        [0 num_cue_plot+num_uncue_plot], 'yticklabel', []);
    ynow = ynow - plot_height*vspacing;
    axis off
    title(['S|' Saline1 '|First'],'Fontsize', 7)

    % Plot Cue trials
    plotshaded([0 CurrentFP]/1000, [0 0; num_cue_plot num_cue_plot],  FP_Color);
    IndSeq = 1:num_cue_plot;
    scatter(PressDurCue_a_Selected, IndSeq, marker_type, ...
        'sizedata', marker_size,'markeredgecolor', FP_Color, 'MarkerFaceColor',FP_Color)

    % Plot Uncue trials
    %     plotshaded([0 CurrentFP]/1000, [num_cue_plot num_cue_plot; ...
    %         num_cue_plot+num_uncue_plot num_cue_plot+num_uncue_plot],  FP_Color);
    %     rectangle('Position',[1,2,5,10],'FaceColor',[0 .5 .5],'EdgeColor','b',...
    %     'LineWidth',3)
    rectangle('Position',[0 num_cue_plot CurrentFP/1000  num_uncue_plot], 'linestyle', '-.', 'EdgeColor',uncue_color, 'linewidth', 1.5)
    IndSeq = (1:num_uncue_plot)+num_cue_plot;
    scatter(PressDurUncue_a_Selected, IndSeq, marker_type, ...
        'sizedata', marker_size,'markeredgecolor', FP_Color, 'MarkerFaceColor',FP_Color)

    % Plot second half
    num_cue_plot            = length(PressDurCue_b_Selected);
    num_uncue_plot        =length(PressDurUncue_b_Selected);
    ha2 = axes('units', 'centimeters', ...
        'position', [xnow, ynow plot_width plot_height], ...
        'ydir','normal','nextplot', 'add', ...
        'xlim',trange, 'ylim', ...
        [0 num_cue_plot+num_uncue_plot], 'yticklabel', []);
    ynow = ynow - plot_height*vspacing;
    axis off
    title(['S|' Saline1 '|Second'],'Fontsize', 7)

    % Plot Cue trials
    plotshaded([0 CurrentFP]/1000, [0 0; num_cue_plot num_cue_plot],  FP_Color);
    IndSeq = 1:num_cue_plot;
    scatter(PressDurCue_b_Selected, IndSeq, marker_type, ...
        'sizedata', marker_size,'markeredgecolor', FP_Color, 'MarkerFaceColor',FP_Color)
    rectangle('Position',[0 num_cue_plot CurrentFP/1000  num_uncue_plot], 'linestyle', '-.', 'EdgeColor', uncue_color, 'linewidth', 1.5)
    IndSeq = (1:num_uncue_plot)+num_cue_plot;
    scatter(PressDurUncue_b_Selected, IndSeq, marker_type, ...
        'sizedata', marker_size,'markeredgecolor', FP_Color, 'MarkerFaceColor',FP_Color)

    %% DCZ session

    Ind_DCZ1                  = find(strcmp(obj.Dates,DCZ1));
    Press_DCZ1               = obj.HoldTime(obj.PressIndex == Ind_DCZ1);
    FPs_DCZ1                 = obj.FP(obj.PressIndex == Ind_DCZ1);
    Stage_DCZ1              = obj.Stage(obj.PressIndex == Ind_DCZ1);
    Outcome_DCZ1         = transpose(obj.Outcome(obj.PressIndex == Ind_DCZ1));
    Cue_DCZ1                 = obj.Cue(obj.PressIndex == Ind_DCZ1);
    PDF_DCZ                  = cell(2, 1); % two conditions, cue and uncue, nFP is 1 for this type of task

    % Compute PDF and distribution (Cue)
    PressDurCue                            =       Press_DCZ1(FPs_DCZ1 == CurrentFP & Stage_DCZ1==1 & Cue_DCZ1==1);
    kOutcomeCue                            =      Outcome_DCZ1(FPs_DCZ1 == CurrentFP & Stage_DCZ1==1 & Cue_DCZ1==1);
    PressDurCue(strcmp(kOutcomeCue, 'Dark'))  =       [];
    PressDurationsDCZ{1,   ii}               =   PressDurCue;
    category_cells_dcz(1, 1) = sum(PressDurCue<CurrentFPSec);
    category_cells_dcz(1, 2) = sum(PressDurCue>CurrentFPSec & PressDurCue<categories(2)+CurrentFPSec);
    category_cells_dcz(1, 3) = sum(PressDurCue>CurrentFPSec+categories(2) & PressDurCue<categories(3)+CurrentFPSec);
    category_cells_dcz(1, 4) = sum(PressDurCue>CurrentFPSec+categories(3) & PressDurCue<categories(4)+CurrentFPSec);
    [f,  f_ci, xi]                            =       ksdensity_ci(PressDurCue, xbins,kernel_bw, nboot);
    PDF_DCZ{1}                     =       [xi', f', f_ci'];

    % Compute PDF and distribution (Uncue)
    PressDurUncue                       =        Press_DCZ1(FPs_DCZ1 == CurrentFP & Stage_DCZ1==1 & Cue_DCZ1==0);
    kOutcomeUncue                      =       Outcome_DCZ1(FPs_DCZ1 == CurrentFP & Stage_DCZ1==1 & Cue_DCZ1==0);
    PressDurUncue(strcmp(kOutcomeUncue, 'Dark'))  =       [];
    PressDurationsDCZ{2,   ii}               =     PressDurUncue;
    category_cells_dcz(2, 1) = sum(PressDurUncue<CurrentFPSec);
    category_cells_dcz(2, 2) = sum(PressDurUncue>CurrentFPSec & PressDurUncue<categories(2)+CurrentFPSec);
    category_cells_dcz(2, 3) = sum(PressDurUncue>CurrentFPSec+categories(2) & PressDurUncue<categories(3)+CurrentFPSec);
    category_cells_dcz(2, 4) = sum(PressDurUncue>CurrentFPSec+categories(3) & PressDurUncue<categories(4)+CurrentFPSec);
    [f,  f_ci, xi]                       =       ksdensity_ci(PressDurUncue, xbins,kernel_bw, nboot);
    PDF_DCZ{2}                =       [xi', f', f_ci'];
    disp('category_cells_dcz')
    disp(category_cells_dcz)

    % Perform X2 test
    % Cue condition (this probably won't matter since sometimes there are
    % only 10% of cue trials)
    pvals(1) = Chi2Test([category_cells_saline(1, :);category_cells_dcz(1, :)]);
    pvals(2) = Chi2Test([category_cells_saline(2, :);category_cells_dcz(2, :)]);


    TimingOut.PDF_Saline_Repeats{ii}                   =       PDF_Saline;
    TimingOut.PDF_DCZ_Repeats{ii}                      =       PDF_DCZ;
    TimingOut.Categories_Saline_Repeats{ii}         =       category_cells_saline;
    TimingOut.Categories_DCZ_Repeats{ii}            =       category_cells_dcz;
    TimingOut.Categories_ChiSquare_Repeats{ii}   =       pvals;

    % combine different repeats
    category_cells_saline_combined      = category_cells_saline_combined+category_cells_saline;
    category_cells_dcz_combined         = category_cells_dcz_combined+category_cells_dcz;

    disp('Saline')
    disp(category_cells_saline)
    disp('DCZ')
    disp(category_cells_dcz)

    %  Plot DCZ session
    %  Plot the data (Cue)
    n = floor(length(PressDurCue)/2);
    PressDurCue_a               = PressDurCue(1:n);
    PressDurCue_b               = PressDurCue(end-n+1:end);
    if n>nplot_cue
        nplot = nplot_cue;
    elseif n>5
        nplot = 5;
    else
        nplot = n;
    end

    IndRandPerm                          = randperm(n, nplot);
    PressDurCue_a_Selected       = PressDurCue_a(IndRandPerm);
    PressDurCue_b_Selected       = PressDurCue_b(IndRandPerm);

    %    Plot the data (Uncue)
    n = floor(length(PressDurUncue)/2);
    PressDurUncue_a               = PressDurUncue(1:n);
    PressDurUncue_b               = PressDurUncue(end-n+1:end);

    if n>nplot_uncue
        nplot = nplot_uncue;
    elseif n>5
        nplot = 5;
    else
        nplot = n;
    end

    IndRandPerm               = randperm(n, nplot);
    PressDurUncue_a_Selected       = PressDurUncue_a(IndRandPerm);
    PressDurUncue_b_Selected       = PressDurUncue_b(IndRandPerm);

    % Plot these data
    % Plot first half, cue and uncue
    num_cue_plot            = length(PressDurCue_a_Selected);
    num_uncue_plot        =length(PressDurUncue_a_Selected);
    ha1 = axes('units', 'centimeters', ...
        'position', [xnow, ynow plot_width plot_height], ...
        'ydir','normal','nextplot', 'add', ...
        'xlim',trange, 'ylim', ...
        [0 num_cue_plot+num_uncue_plot], 'yticklabel', []);
    ynow = ynow - plot_height*vspacing;
    axis off
    title(['D|' DCZ1 '|First'],'Fontsize', 7, 'color', inactivation_color)

    % Plot Cue trials
    plotshaded([0 CurrentFP]/1000, [0 0; num_cue_plot num_cue_plot],  FP_Color);
    IndSeq = 1:num_cue_plot;
    scatter(PressDurCue_a_Selected, IndSeq, marker_type, ...
        'sizedata', marker_size,'markeredgecolor', FP_Color, 'MarkerFaceColor',FP_Color)

    % Plot Uncue trials
    %     plotshaded([0 CurrentFP]/1000, [num_cue_plot num_cue_plot; ...
    %         num_cue_plot+num_uncue_plot num_cue_plot+num_uncue_plot],  FP_Color);
    %     rectangle('Position',[1,2,5,10],'FaceColor',[0 .5 .5],'EdgeColor','b',...
    %     'LineWidth',3)
    rectangle('Position',[0 num_cue_plot CurrentFP/1000  num_uncue_plot], 'linestyle', '-.', 'EdgeColor',uncue_color, 'linewidth', 1.5)
    IndSeq = (1:num_uncue_plot)+num_cue_plot;
    scatter(PressDurUncue_a_Selected, IndSeq, marker_type, ...
        'sizedata', marker_size,'markeredgecolor', FP_Color, 'MarkerFaceColor',FP_Color)

    % Plot second half
    num_cue_plot            = length(PressDurCue_b_Selected);
    num_uncue_plot        =length(PressDurUncue_b_Selected);
    ha2 = axes('units', 'centimeters', ...
        'position', [xnow, ynow plot_width plot_height], ...
        'ydir','normal','nextplot', 'add', ...
        'xlim',trange, 'ylim', ...
        [0 num_cue_plot+num_uncue_plot], 'yticklabel', []);
    ynow = ynow - plot_height*vspacing;
    title(['D|' DCZ1 '|Second'],'Fontsize', 7, 'color', inactivation_color)

    % Plot Cue trials
    plotshaded([0 CurrentFP]/1000, [0 0; num_cue_plot num_cue_plot],  FP_Color);
    IndSeq = 1:num_cue_plot;
    scatter(PressDurCue_b_Selected, IndSeq, marker_type, ...
        'sizedata', marker_size,'markeredgecolor', FP_Color, 'MarkerFaceColor',FP_Color)
    rectangle('Position',[0 num_cue_plot CurrentFP/1000  num_uncue_plot], 'linestyle', '-.', 'EdgeColor', uncue_color, 'linewidth', 1.5)
    IndSeq = (1:num_uncue_plot)+num_cue_plot;
    scatter(PressDurUncue_b_Selected, IndSeq, marker_type, ...
        'sizedata', marker_size,'markeredgecolor', FP_Color, 'MarkerFaceColor',FP_Color)
    xlabel('Hold duration (s)')


    %% Plot PDF
    ynow = 1.5;
    % Cue
    k = 1;
    ha6 = axes('units', 'centimeters', ...
        'position', [xnow, ynow plot_width plot_height2], ...
        'ydir','normal','nextplot', 'add', ...
        'xlim',trange, 'ylim',pdf_range);

    if pvals(k)>0.0001
        text(categories(end-1)+CurrentFPSec+0.25, pdf_range(2)*0.8, sprintf('p=%2.4f', pvals(k)), 'fontname','dejavu sans', 'fontsize', 7)
    else
        text(categories(end-1)+CurrentFPSec+0.25, pdf_range(2)*0.8, 'p<0.0001', 'fontname','dejavu sans', 'fontsize', 7)
    end

    ynow = ynow +plot_height2+0.25;

    if k >1
        set(gca, 'xtick', [], 'ytick',[])
        axis off
    elseif k==1 && ii ==1
        xlabel('Hold duration (s)')
        ylabel('Density (1/s)')
    end

    plotshaded([0 CurrentFPSec], [0 0; pdf_range(2) pdf_range(2)],  FP_Color);

    kPDF = PDF_Saline{k};
    xi = kPDF(:, 1);
    f  = kPDF(:, 2);
    f_ci = kPDF(:, [3 4]);
    plotshaded(xi', f_ci', [.5 .5 .5]);
    plot(xi, f, 'color', FP_Color,  'linewidth', 1.5)

    kPDF = PDF_DCZ{k};
    xi = kPDF(:, 1);
    f  = kPDF(:, 2);
    f_ci = kPDF(:, [3 4]);
    plotshaded(xi', f_ci', [.5 .5 .5]);
    plot(xi, f, 'color', inactivation_color,  'linewidth', 1.5)
    line([categories(1:end-1); categories(1:end-1)]+CurrentFPSec, repmat(pdf_range', 1, length(categories)-1), ...
        'color', 'm', 'linestyle', ':', 'linewidth', 1)

    % Uncue
    k = 2;
    ha6 = axes('units', 'centimeters', ...
        'position', [xnow, ynow plot_width plot_height2], ...
        'ydir','normal','nextplot', 'add', ...
        'xlim',trange, 'ylim',pdf_range);

    if pvals(k)>0.0001
        text(categories(end-1)+CurrentFPSec+0.25, pdf_range(2)*0.8, sprintf('p=%2.4f', pvals(k)), 'fontname','dejavu sans', 'fontsize', 7)
    else
        text(categories(end-1)+CurrentFPSec+0.25, pdf_range(2)*0.8, 'p<0.0001', 'fontname','dejavu sans', 'fontsize', 7)
    end

    if k >1
        set(gca, 'xtick', [], 'ytick',[])
        axis off
    elseif k==1 && ii ==1
        xlabel('Hold duration (s)')
        ylabel('Density (1/s)')
    end

    rectangle('Position',[0 0 CurrentFP/1000   pdf_range(2)], 'linestyle', '-.', 'EdgeColor',uncue_color, 'linewidth', 1.5)

    kPDF = PDF_Saline{k};
    xi = kPDF(:, 1);
    f  = kPDF(:, 2);
    f_ci = kPDF(:, [3 4]);
    plotshaded(xi', f_ci', [.5 .5 .5]);
    plot(xi, f, 'color', FP_Color,  'linewidth', 1.5)

    kPDF = PDF_DCZ{k};
    xi = kPDF(:, 1);
    f  = kPDF(:, 2);
    f_ci = kPDF(:, [3 4]);
    plotshaded(xi', f_ci', [.5 .5 .5]);
    plot(xi, f, 'color', inactivation_color,  'linewidth', 1.5)
    line([categories(1:end-1); categories(1:end-1)]+FPs(k), repmat(pdf_range', 1, length(categories)-1), ...
        'color', 'm', 'linestyle', ':', 'linewidth', 1)
    xnow = xnow + plot_width+1;
end

TimingOut.Presses_Saline_Repeats             =       PressDurations;
TimingOut.Presses_DCZ_Repeats                =       PressDurationsDCZ;

xnow = xnow+0.5;
spacing = 0.75;
p_values = struct();
if n_repeats>1
    % Lastly, we check the combined data
    ynow = 14;
    pvals_combined = zeros(1, 2);
    % seperating responses to 'the first half' and 'the second half' within
    % each session.
    PressCue_FirstHalf_Saline           = [];
    PressCue_SecondHalf_Saline      = [];
    PressCue_Saline                           = [];

    PressCue_FirstHalf_DCZ              = [];
    PressCue_SecondHalf_DCZ         = [];
    PressCue_DCZ                              = [];

    PressUncue_FirstHalf_Saline           = [];
    PressUncue_SecondHalf_Saline      = [];
    PressUncue_Saline                           = [];

    PressUncue_FirstHalf_DCZ              = [];
    PressUncue_SecondHalf_DCZ         = [];
    PressUncue_DCZ                              = [];

    for i =1:n_repeats

        % saline sessions
        iPressCue = TimingOut.Presses_Saline_Repeats{1, i};
        nhalf = floor(length(iPressCue)/2);
        PressCue_FirstHalf_Saline=[PressCue_FirstHalf_Saline iPressCue(1:nhalf)];
        PressCue_SecondHalf_Saline=[PressCue_SecondHalf_Saline iPressCue(end-nhalf+1:end)];
        PressCue_Saline = [PressCue_Saline iPressCue];

        iPressUncue = TimingOut.Presses_Saline_Repeats{2, i};
        nhalf = floor(length(iPressUncue)/2);
        PressUncue_FirstHalf_Saline=[PressUncue_FirstHalf_Saline iPressUncue(1:nhalf)];
        PressUncue_SecondHalf_Saline=[PressUncue_SecondHalf_Saline iPressUncue(end-nhalf+1:end)];
        PressUncue_Saline = [PressUncue_Saline iPressUncue];

        % dcz sessions
        iPressCue                               =  TimingOut.Presses_DCZ_Repeats{1, i};
        nhalf                                       =  floor(length(iPressCue)/2);
        PressCue_FirstHalf_DCZ      =  [PressCue_FirstHalf_DCZ iPressCue(1:nhalf)];
        PressCue_SecondHalf_DCZ =  [PressCue_SecondHalf_DCZ iPressCue(end-nhalf+1:end)];
        PressCue_DCZ                                    = [PressCue_DCZ iPressCue];

        iPressUncue                             = TimingOut.Presses_DCZ_Repeats{2, i};
        nhalf                                           = floor(length(iPressUncue)/2);
        PressUncue_FirstHalf_DCZ       =[PressUncue_FirstHalf_DCZ iPressUncue(1:nhalf)];
        PressUncue_SecondHalf_DCZ  =[PressUncue_SecondHalf_DCZ iPressUncue(end-nhalf+1:end)];
        PressUncue_DCZ                          = [PressUncue_DCZ iPressUncue];
    end

    % first plot: First half, DCZ and Saline comparison, Uncue
    ha7 = axes('units', 'centimeters', ...
        'position', [xnow, ynow plot_width plot_height2], ...
        'ydir','normal','nextplot', 'add', ...
        'xlim',trange, 'ylim',pdf_range);
    ynow = ynow - plot_height2 - spacing;
    axis off
    title('Sessions combined |First half', 'fontname', 'dejavu sans','fontsize', 7,'fontweight','bold')

    [f_saline,  f_saline_ci, ~]                      =       ksdensity_ci(PressUncue_FirstHalf_Saline, xbins,kernel_bw, nboot);
    [f_dcz,  f_dcz_ci, xi]                              =       ksdensity_ci(PressUncue_FirstHalf_DCZ, xbins,kernel_bw, nboot);
    
    TimingOut.Presses.Uncue_Saline_FirstHalf       =       PressUncue_FirstHalf_Saline;
    TimingOut.Presses.Uncue_DCZ_FirstHalf       =       PressUncue_FirstHalf_DCZ;
    PressMetric.Uncue_FirstHalf = compute_press_metric(PressUncue_FirstHalf_Saline, PressUncue_FirstHalf_DCZ);
    p_values.UncueFirstHalf = Chi2TestCategories({PressUncue_FirstHalf_Saline, PressUncue_FirstHalf_DCZ}, CurrentFPSec, TimeBins);

    TimingOut.PDF_Uncue_Saline_FirstHalf           =       [xi' f_saline'  f_saline_ci'];
    TimingOut.PDF_Uncue_DCZ_FirstHalf              =       [xi' f_dcz'  f_dcz_ci'];
    rectangle('Position',[0 0 CurrentFP/1000   pdf_range(2)], 'linestyle', '-.', 'EdgeColor',uncue_color, 'linewidth', 1.5)
    plotshaded(xi, f_saline_ci, [.5 .5 .5]);
    plot(xi, f_saline, 'color', FP_Color,  'linewidth', 1.5);
    plotshaded(xi, f_dcz_ci, [.5 .5 .5]);
    plot(xi, f_dcz, 'color', inactivation_color,  'linewidth', 1.5);
    line([categories(1:end-1); categories(1:end-1)]+CurrentFPSec, repmat(pdf_range', 1, length(categories)-1), ...
        'color', 'k', 'linestyle', ':', 'linewidth', 0.75)

    if p_values.UncueFirstHalf>0.0001
        text(CurrentFPSec+1.25, pdf_range(2)*0.8, sprintf('p=%2.4f', p_values.UncueFirstHalf), 'fontname','dejavu sans', 'fontsize', 7)
    else
        text(CurrentFPSec+1.25, pdf_range(2)*0.8, 'p<0.0001', 'fontname','dejavu sans', 'fontsize', 7)
    end

    % second plot: cue trials
    ha8 = axes('units', 'centimeters', ...
        'position', [xnow, ynow plot_width plot_height2], ...
        'ydir','normal','nextplot', 'add', ...
        'xlim',trange, 'ylim',pdf_range);
    ynow = ynow - plot_height2 - 1.5;
    xlabel('Hold duration (s)')
    ylabel('Density (1/s)')

    [f_saline,  f_saline_ci, ~]                      =       ksdensity_ci(PressCue_FirstHalf_Saline, xbins,kernel_bw, nboot);
    [f_dcz,  f_dcz_ci, xi]                              =       ksdensity_ci(PressCue_FirstHalf_DCZ, xbins,kernel_bw, nboot);

    TimingOut.Presses.Cue_Saline_FirstHalf       =       PressCue_FirstHalf_Saline;
    TimingOut.Presses.Cue_DCZ_FirstHalf          =       PressCue_FirstHalf_DCZ;

    PressMetric.Cue_FirstHalf = compute_press_metric(PressCue_FirstHalf_Saline, PressCue_FirstHalf_DCZ);
    p_values.CueFirstHalf = Chi2TestCategories({PressCue_FirstHalf_Saline, PressCue_FirstHalf_DCZ}, CurrentFPSec, TimeBins);

    TimingOut.PDF_Cue_Saline_FirstHalf             =       [xi' f_saline'  f_saline_ci'];
    TimingOut.PDF_Cue_DCZ_FirstHalf                =       [xi' f_dcz'  f_dcz_ci'];

    plotshaded([0 CurrentFPSec], [0 0; pdf_range(2) pdf_range(2)],  FP_Color);
    plotshaded(xi, f_saline_ci, [.5 .5 .5]);
    plot(xi, f_saline, 'color', FP_Color,  'linewidth', 1.5);
    plotshaded(xi, f_dcz_ci, [.5 .5 .5]);
    plot(xi, f_dcz, 'color', inactivation_color,  'linewidth', 1.5);
    line([categories(1:end-1); categories(1:end-1)]+CurrentFPSec, repmat(pdf_range', 1, length(categories)-1), ...
        'color', 'k', 'linestyle', ':', 'linewidth', 0.75)

    if p_values.CueFirstHalf>0.0001
        text(CurrentFPSec+1.25, pdf_range(2)*0.8, sprintf('p=%2.4f', p_values.CueFirstHalf), ...
            'fontname','dejavu sans', 'fontsize', 7)
    else
        text(CurrentFPSec+1.25, pdf_range(2)*0.8, 'p<0.0001', 'fontname','dejavu sans', 'fontsize', 7)
    end

    % third plot: second half, DCZ and Saline comparison, Uncue
    ha9 = axes('units', 'centimeters', ...
        'position', [xnow, ynow plot_width plot_height2], ...
        'ydir','normal','nextplot', 'add', ...
        'xlim',trange, 'ylim',pdf_range);
    ynow = ynow - plot_height2 - spacing;
    axis off
    title('Sessions combined |Second half', 'fontname', 'dejavu sans','fontsize', 7,'fontweight','bold')

    [f_saline,  f_saline_ci, ~]                      =       ksdensity_ci(PressUncue_SecondHalf_Saline, xbins,kernel_bw, nboot);
    [f_dcz,  f_dcz_ci, xi]                              =       ksdensity_ci(PressUncue_SecondHalf_DCZ, xbins,kernel_bw, nboot);

    PressMetric.Uncue_SecondHalf = compute_press_metric(PressUncue_SecondHalf_Saline, PressUncue_SecondHalf_DCZ);

    TimingOut.Presses.Uncue_Saline_SecondHalf        =       PressUncue_SecondHalf_Saline;
    TimingOut.Presses.Uncue_DCZ_SecondHalf        =       PressUncue_SecondHalf_DCZ;

    TimingOut.PDF_Uncue_Saline_SecondHalf          =       [xi' f_saline'  f_saline_ci'];
    TimingOut.PDF_Uncue_DCZ_SecondHalf               =       [xi' f_dcz'  f_dcz_ci'];

    p_values.UncueSecondHalf = Chi2TestCategories({PressUncue_SecondHalf_Saline, PressUncue_SecondHalf_DCZ}, CurrentFPSec, TimeBins);

    rectangle('Position',[0 0 CurrentFP/1000   pdf_range(2)], 'linestyle', '-.', 'EdgeColor',uncue_color, 'linewidth', 1.5)
    plotshaded(xi, f_saline_ci, [.5 .5 .5]);
    plot(xi, f_saline, 'color', FP_Color,  'linewidth', 1.5);
    plotshaded(xi, f_dcz_ci, [.5 .5 .5]);
    plot(xi, f_dcz, 'color', inactivation_color,  'linewidth', 1.5);
    line([categories(1:end-1); categories(1:end-1)]+CurrentFPSec, repmat(pdf_range', 1, length(categories)-1), ...
        'color', 'k', 'linestyle', ':', 'linewidth', 0.75)

    if p_values.UncueSecondHalf>0.0001
        text(CurrentFPSec+1.25, pdf_range(2)*0.8, sprintf('p=%2.4f', p_values.UncueSecondHalf), ...
            'fontname','dejavu sans', 'fontsize', 7)
    else
        text(CurrentFPSec+1.25, pdf_range(2)*0.8, 'p<0.0001', 'fontname','dejavu sans', 'fontsize', 7)
    end

       % fourth plot: second half, DCZ and Saline comparison, Cue
    ha10 = axes('units', 'centimeters', ...
        'position', [xnow, ynow plot_width plot_height2], ...
        'ydir','normal','nextplot', 'add', ...
        'xlim',trange, 'ylim',pdf_range);
    ynow = ynow - plot_height2 - 1.5;
    xlabel('Hold duration (s)')
    ylabel('Density (1/s)')

    [f_saline,  f_saline_ci, ~]                      =       ksdensity_ci(PressCue_SecondHalf_Saline, xbins,kernel_bw, nboot);
    [f_dcz,  f_dcz_ci, xi]                              =       ksdensity_ci(PressCue_SecondHalf_DCZ, xbins,kernel_bw, nboot);

    TimingOut.Presses.Cue_Saline_SecondHalf       =       PressCue_SecondHalf_Saline;
    TimingOut.Presses.Cue_DCZ_SecondHalf       =       PressCue_SecondHalf_DCZ;

    PressMetric.Cue_SecondHalf = compute_press_metric(PressCue_SecondHalf_Saline, PressCue_SecondHalf_DCZ);
    p_values.CueSecondHalf = Chi2TestCategories({PressCue_SecondHalf_Saline, PressCue_SecondHalf_DCZ}, CurrentFPSec, TimeBins);

    TimingOut.PDF_Cue_Saline_SecondHalf             =       [xi' f_saline'  f_saline_ci'];
    TimingOut.PDF_Cue_DCZ_SecondHalf                =       [xi' f_dcz'  f_dcz_ci'];

    plotshaded([0 CurrentFPSec], [0 0; pdf_range(2) pdf_range(2)],  FP_Color);
    plotshaded(xi, f_saline_ci, [.5 .5 .5]);
    plot(xi, f_saline, 'color', FP_Color,  'linewidth', 1.5);
    plotshaded(xi, f_dcz_ci, [.5 .5 .5]);
    plot(xi, f_dcz, 'color', inactivation_color,  'linewidth', 1.5);
    line([categories(1:end-1); categories(1:end-1)]+CurrentFPSec, repmat(pdf_range', 1, length(categories)-1), ...
        'color', 'k', 'linestyle', ':', 'linewidth', 0.75)

    if p_values.CueSecondHalf>0.0001
        text(CurrentFPSec+1.25, pdf_range(2)*0.8, sprintf('p=%2.4f', p_values.CueSecondHalf), ...
            'fontname','dejavu sans', 'fontsize', 7)
    else
        text(CurrentFPSec+1.25, pdf_range(2)*0.8, 'p<0.0001', 'fontname','dejavu sans', 'fontsize', 7)
    end

    % fifth plot: whole, DCZ and Saline comparison, Uncue
    ha9 = axes('units', 'centimeters', ...
        'position', [xnow, ynow plot_width plot_height2], ...
        'ydir','normal','nextplot', 'add', ...
        'xlim',trange, 'ylim',pdf_range);
    ynow = ynow - plot_height2 - spacing;
    axis off
    title('Sessions combined |whole', 'fontname', 'dejavu sans','fontsize', 7,'fontweight','bold')

    [f_saline,  f_saline_ci, ~]                      =       ksdensity_ci(PressUncue_Saline, xbins,kernel_bw, nboot);
    [f_dcz,  f_dcz_ci, xi]                              =       ksdensity_ci(PressUncue_DCZ, xbins,kernel_bw, nboot);

    PressMetric.Uncue_Whole = compute_press_metric(PressUncue_Saline, PressUncue_DCZ);
    p_values.Uncue                                      = Chi2TestCategories({PressUncue_Saline, PressUncue_DCZ}, CurrentFPSec, TimeBins);

    TimingOut.Presses.Uncue_Saline_Combine       =       PressUncue_Saline;
    TimingOut.Presses.Uncue_DCZ_Combine       =       PressUncue_DCZ;

    TimingOut.PDF_Uncue_Saline_Combine            =       [xi' f_saline'  f_saline_ci'];
    TimingOut.PDF_Uncue_DCZ_Combine               =       [xi' f_dcz'  f_dcz_ci'];

    rectangle('Position',[0 0 CurrentFP/1000   pdf_range(2)], 'linestyle', '-.', 'EdgeColor',uncue_color, 'linewidth', 1.5)
    plotshaded(xi, f_saline_ci, [.5 .5 .5]);
    plot(xi, f_saline, 'color', FP_Color,  'linewidth', 1.5);
    plotshaded(xi, f_dcz_ci, [.5 .5 .5]);
    plot(xi, f_dcz, 'color', inactivation_color,  'linewidth', 1.5);
    line([categories(1:end-1); categories(1:end-1)]+CurrentFPSec, repmat(pdf_range', 1, length(categories)-1), ...
        'color', 'k', 'linestyle', ':', 'linewidth', 0.75)

    if p_values.Uncue>0.0001
        text(CurrentFPSec+1.25, pdf_range(2)*0.8, sprintf('p=%2.4f', p_values.Uncue), ...
            'fontname','dejavu sans', 'fontsize', 7)
    else
        text(CurrentFPSec+1.25, pdf_range(2)*0.8, 'p<0.0001', 'fontname','dejavu sans', 'fontsize', 7)
    end

       % sixth plot: whole DCZ and Saline comparison, Cue
    ha10 = axes('units', 'centimeters', ...
        'position', [xnow, ynow plot_width plot_height2], ...
        'ydir','normal','nextplot', 'add', ...
        'xlim',trange, 'ylim',pdf_range);
    ynow = ynow - plot_height2 - 1.5;

    final_width = xnow+plot_width+1.5;
    figure_pos = get(gcf, 'position');
    figure_pos(3) = final_width;
    set(gcf, 'position', figure_pos)

    xlabel('Hold duration (s)')
    ylabel('Density (1/s)')

    [f_saline,  f_saline_ci, ~]                      =       ksdensity_ci(PressCue_Saline, xbins,kernel_bw, nboot);
    [f_dcz,  f_dcz_ci, xi]                              =       ksdensity_ci(PressCue_DCZ, xbins,kernel_bw, nboot);

    PressMetric.Cue_Whole = compute_press_metric(PressCue_Saline, PressCue_DCZ);
    TimingOut.Presses.Cue_Saline_Combine       =       PressCue_Saline;
    TimingOut.Presses.Cue_DCZ_Combine       =       PressCue_DCZ;

    TimingOut.PressMetric = PressMetric;

    p_values.Cue                                      = Chi2TestCategories({PressCue_Saline, PressCue_DCZ}, CurrentFPSec, TimeBins);

    TimingOut.PDF_Cue_Saline_Combine            =       [xi' f_saline'  f_saline_ci'];
    TimingOut.PDF_Cue_DCZ_Combine               =       [xi' f_dcz'  f_dcz_ci'];

    plotshaded([0 CurrentFPSec], [0 0; pdf_range(2) pdf_range(2)],  FP_Color);
    plotshaded(xi, f_saline_ci, [.5 .5 .5]);
    plot(xi, f_saline, 'color', FP_Color,  'linewidth', 1.5);
    plotshaded(xi, f_dcz_ci, [.5 .5 .5]);
    plot(xi, f_dcz, 'color', inactivation_color,  'linewidth', 1.5);
    line([categories(1:end-1); categories(1:end-1)]+CurrentFPSec, repmat(pdf_range', 1, length(categories)-1), ...
        'color', 'k', 'linestyle', ':', 'linewidth', 0.75)

    if p_values.Cue>0.0001
        text(CurrentFPSec+1.25, pdf_range(2)*0.8, sprintf('p=%2.4f', p_values.Cue), ...
            'fontname','dejavu sans', 'fontsize', 7)
    else
        text(CurrentFPSec+1.25, pdf_range(2)*0.8, 'p<0.0001', 'fontname','dejavu sans', 'fontsize', 7)
    end
end

TimingOut.Categories_Saline_Combine               =      category_cells_saline_combined;
TimingOut.Categories_DCZ_Combine                  =      category_cells_dcz_combined;
TimingOut.Categories_ChiSquare_Combine        =       p_values;

% hui = uicontrol('style', 'text', 'units', 'normalized', 'position', [0.1 0.925 0.25 0.05],...
%     'string', [obj.Subject ' | Timing' ], 'HorizontalAlignment', 'center','BackgroundColor','w', 'fontsize', 10, 'fontweight','bold');
% 
% if ~isempty(name)
%     hui = uicontrol('style', 'text', 'units', 'normalized', 'position', [0.35 0.925 0.25 0.05],...
%         'string', name, 'HorizontalAlignment', 'center','BackgroundColor','w', 'fontsize', 10, 'fontweight','bold');
% end
annotation('textbox', [0.1 0.925 0.25 0.05], ...
    'String', [obj.Subject ' | Timing'], ...
    'HorizontalAlignment', 'center', ...
    'BackgroundColor', 'w', ...
    'FontSize', 10, ...
    'FontWeight', 'bold', ...
    'EdgeColor', 'none');

if ~isempty(name)
    annotation('textbox', [0.35 0.925 0.25 0.05], ...
        'String', name, ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', 'w', ...
        'FontSize', 10, ...
        'FontWeight', 'bold', ...
        'EdgeColor', 'none');
end


% save this figure
fig_folder = fullfile(pwd, 'Figure');
if ~exist(fig_folder, 'dir')
    mkdir(fig_folder)
end

if isempty(name)
    tosavename=  fullfile(fig_folder, 'Fig1_ResponseDistribution');
else
    tosavename=  fullfile(fig_folder, ['Fig1_ResponseDistribution_', name]);
end
saveas(hf, tosavename, 'epsc')
print (hf,'-dpdf', tosavename)
print (hf,'-dpng', tosavename)

Chemo.PlotTimingMetric(TimingOut, name)

target_folder = pwd;
if isempty(name)
    tosavename=   fullfile(target_folder, ['TimingOutDistributionStatistics_' obj.Subject{1} '.mat']);
    save(tosavename, 'TimingOut')
else
    tosavename=   fullfile(target_folder, ['TimingOutDistributionStatistics_', name, '_', obj.Subject{1} '.mat']);
    save(tosavename, 'TimingOut')
end

function p_value = Chi2TestCategories(ResponseData, FP, TimeBins)
% ReponseData should be cells of data
% TimeBins should be response time bins that ResponseData will fall into
NumDistributions = length(ResponseData);
TimeBins = TimeBins+FP;
DataClassified = zeros(NumDistributions, length(TimeBins));
for i =1: NumDistributions
    for j =1:length(TimeBins)
        if j == 1
            DataClassified(i, j)=sum(ResponseData{i}<TimeBins(j));
        else
            DataClassified(i, j)=sum(ResponseData{i}>TimeBins(j-1) & ResponseData{i}<TimeBins(j));
        end
    end
end

p_value = Chi2Test(DataClassified);

function p_value = Chi2Test(Data)

% Jianing Yu 12/15/2023
% Data: Row represents subgroups, Column represents categories
% Data = [
%    % 1-3 4-6 7-9
%     111 96 48      % community college students
%     96 133 61   % four-year college students
%     91 150 53   % nonstudents
%     ];

sample_size     = sum(Data(:));
sample_size_subgroups = sum(Data, 2);
disp(sample_size_subgroups)
% Estimate distribution
p_0             = sum(Data, 1)/sample_size;
disp(p_0)
% Compute expectation
Expectation     = sample_size_subgroups*p_0;
disp(Data)
disp(Expectation)
Squared_Difference = (Expectation-Data).^2;
disp(Squared_Difference)
% Normalized by the expected value
Squared_Difference_Norm = Squared_Difference./Expectation;
disp(Squared_Difference_Norm)
% Compute test statistic
T = sum(Squared_Difference_Norm(:));
disp(T)
dof = (size(Data, 1)-1)*(size(Data, 2)-1);
p_value = 1-chi2cdf(T, dof);




