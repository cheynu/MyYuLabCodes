function SRTOut = SRTDistributionInactivation_CY(obj, SalineSessionsSelected, DCZSessionsSelected,opts)

arguments
    obj
    SalineSessionsSelected
    DCZSessionsSelected
    opts.nplot = 20
    opts.nTrialFisrtHalf = 150
    opts.nTrialSecondHalf = 150
    opts.nTrialType {mustBeMember(opts.nTrialType,{'Press','Trial'})} = 'Press'
    opts.pathFigure = 'Figure'
end
nTrial1Half = opts.nTrialFisrtHalf;
nTrial2Half = opts.nTrialSecondHalf;
nTrialType = opts.nTrialType;
pathSaveFig = opts.pathFigure;

SRTOut                                =      [];
SRTOut.ANM                       =       obj.Subject;
SRTOut.SalineSessions      =        SalineSessionsSelected;
SRTOut.DCZSessions         =        DCZSessionsSelected;

n_repeats = length(SalineSessionsSelected);

nplot = opts.nplot;
xnow =-2;
plot_width = 3;
plot_height = 2;
plot_height2 = 1.35;
vspacing = 1.3;
vspacing2 = 1.1;

FP_colors           =   {'#9BBEC8', '#427D9D', '#164863'};
inactivation_color  =   '#FF6C22';

marker_size = 5;
FP_shade_color = [0.3 0.8 0.5];
marker_type = 'o';
FPs = [500 1000 1500]/1000;
nFP = length(FPs);
rng(3)
% rng(5)
trange  =[0 2.5];
categories = [0 0.3 0.6 trange(2)]; % response duration less than 0.1+FP,
SRTOut.TimeCategories = categories;
hf = figure(45);
clf(hf)

set(gcf, 'units', 'Centimeters', 'position',[2 2 22 18],...
    'Visible','on', 'paperpositionmode', 'auto', 'color', 'w');

% [f,  f_ci, xi] = ksdensity_ci(press_durs, xbins,kernel_bw, nboot);
xbins       =     (0:0.05:4);
kernel_bw   =     0.08;
nboot       =     1000;
pdf_range   =     [0 5];
SRTOut.KernelBW = kernel_bw;
SRTOut.nboot = nboot;
 
category_cells_saline_combined = zeros(nFP, length(categories));    % combined across repeats
category_cells_dcz_combined = zeros(nFP, length(categories));        % combined across repeats

PressDurations = cell(nFP, 2, n_repeats); % combine press duration across sessions.

for ii =1:n_repeats
    disp(ii)
    % Plot all trials from saline session
    Saline1 = SalineSessionsSelected{ii};
    DCZ1 = DCZSessionsSelected{ii};
    Ind_Saline1             = find(strcmp(obj.Dates,Saline1));
    Press_Saline1           = obj.HoldTime(obj.SessionIndex == Ind_Saline1);
    FPs_Saline1             = obj.FP(obj.SessionIndex == Ind_Saline1);
    Outcome_Saline1         = obj.Outcome(obj.SessionIndex == Ind_Saline1);
    PDF_Saline              = cell(1, nFP);
    PDF_DCZ                 = cell(1, nFP);
    pvals                   = zeros(1, nFP);

    category_cells_saline = zeros(nFP, length(categories));
    category_cells_dcz = zeros(nFP, length(categories));

    % compute PDF
    for j =1:nFP
        PressDur                            =       Press_Saline1(FPs_Saline1 == FPs(j)*1000);
        kOutcome                            =       Outcome_Saline1(FPs_Saline1 == FPs(j)*1000);
        PressDur(strcmp(kOutcome, 'Dark'))  =       [];
        PressDurations{j, 1, ii}               =   PressDur;
        category_cells_saline(j, 1) = sum(PressDur<FPs(j));
        category_cells_saline(j, 2) = sum(PressDur>FPs(j) & PressDur<categories(2)+FPs(j));
        category_cells_saline(j, 3) = sum(PressDur>FPs(j)+categories(2) & PressDur<categories(3)+FPs(j));
        category_cells_saline(j, 4) = sum(PressDur>FPs(j)+categories(3) & PressDur<categories(4)+FPs(j));
        [f,  f_ci, xi]                      =       ksdensity_ci(PressDur, xbins,kernel_bw, nboot);
        PDF_Saline{j}                       =       [xi', f', f_ci'];
    end

    Ind_DCZ1             = find(strcmp(obj.Dates,DCZ1));
    Press_DCZ1           = obj.HoldTime(obj.SessionIndex == Ind_DCZ1);
    FPs_DCZ1             = obj.FP(obj.SessionIndex == Ind_DCZ1);
    Outcome_DCZ1         = obj.Outcome(obj.SessionIndex == Ind_DCZ1);

    for j =1:nFP
        PressDur                            =       Press_DCZ1(FPs_DCZ1 == FPs(j)*1000);
        kOutcome                            =       Outcome_DCZ1(FPs_DCZ1 == FPs(j)*1000);
        PressDur(strcmp(kOutcome, 'Dark'))  =       [];
        PressDurations{j, 2, ii}               =  PressDur;
        category_cells_dcz(j, 1) = sum(PressDur<FPs(j));
        category_cells_dcz(j, 2) = sum(PressDur>FPs(j) & PressDur<categories(2)+FPs(j));
        category_cells_dcz(j, 3) = sum(PressDur>FPs(j)+categories(2) & PressDur<categories(3)+FPs(j));
        category_cells_dcz(j, 4) = sum(PressDur>FPs(j)+categories(3) & PressDur<categories(4)+FPs(j));
        pvals(j) = Chi2Test([category_cells_saline(j, :);category_cells_dcz(j, :)]);
        % get rid of 'Dark' presses

        [f,  f_ci, xi]                              =       ksdensity_ci(PressDur, xbins,kernel_bw, nboot);
        PDF_DCZ{j}                          =       [xi', f', f_ci'];
    end

    SRTOut.Presses_Repeats{ii}                           =       PressDurations;
    SRTOut.PDF_Saline_Repeats{ii}                      =       PDF_Saline;
    SRTOut.PDF_DCZ_Repeats{ii}                         =       PDF_DCZ;
    SRTOut.Categories_Saline_Repeats{ii}             =       category_cells_saline;
    SRTOut.Categories_DCZ_Repeats{ii}            =       category_cells_dcz;
    SRTOut.Categories_ChiSquare_Repeats{ii}     =       pvals;

    % combine different repeats
    category_cells_saline_combined = category_cells_saline_combined+category_cells_saline;
    category_cells_dcz_combined = category_cells_dcz_combined+category_cells_dcz;

    disp('Saline')
    disp(category_cells_saline)
    disp('DCZ')
    disp(category_cells_dcz)
    xnow = xnow+4;
    ynow = 15;

    switch nTrialType
        case 'Press'
            % pass
        case 'Trial'
            idxTrialSaline1 = ~strcmp(Outcome_Saline1,'Dark');
            Press_Saline1 = Press_Saline1(idxTrialSaline1);
            FPs_Saline1 = FPs_Saline1(idxTrialSaline1);
            Outcome_Saline1 = Outcome_Saline1(idxTrialSaline1);

            idxTrialDCZ1 = ~strcmp(Outcome_DCZ1,'Dark');
            Press_DCZ1 = Press_DCZ1(idxTrialDCZ1);
            FPs_DCZ1 = FPs_DCZ1(idxTrialDCZ1);
            Outcome_DCZ1 = Outcome_DCZ1(idxTrialDCZ1);
    end

    %     this is the first half of a saline session
    ha1 = axes('units', 'centimeters', ...
        'position', [xnow, ynow plot_width plot_height], ...
        'ydir','normal','nextplot', 'add', ...
        'xlim',trange, 'ylim', [0 nplot*nFP], 'yticklabel', []);
    ynow = ynow - plot_height*vspacing;
    axis off
    title(['S|' Saline1 '|First'])

    n = nTrial1Half;
    Press_Saline1a           = Press_Saline1(1:n);
    FPs_Saline1a             = FPs_Saline1(1:n);
    Outcome_Saline1a         = Outcome_Saline1(1:n);

    for k =1:nFP
        if k == 1
            xlabel('Hold duration (s)')
        end
        PressDur                = Press_Saline1a(FPs_Saline1a==FPs(k)*1000);
        kOutcome                = Outcome_Saline1a(FPs_Saline1a==FPs(k)*1000);
        % get rid of 'Dark' presses
        PressDur(strcmp(kOutcome, 'Dark')) = [];
        IndRandPerm             = randperm(length(PressDur), nplot);
        PressDur_Selected       = PressDur(IndRandPerm);
        plotshaded([0 FPs(k)], [nplot*(k-1) nplot*(k-1); nplot*k nplot*k],  FP_colors{k});
        IndSeq = (1:nplot)+nplot*(k-1);
        scatter(PressDur_Selected, IndSeq, marker_type, ...
            'sizedata', marker_size,'markeredgecolor', FP_colors{k}, 'MarkerFaceColor',FP_colors{k})
    end


    %     this is the second half of the saline session
    ha2 = axes('units', 'centimeters', ...
        'position', [xnow, ynow plot_width plot_height], ...
        'ydir','normal','nextplot', 'add', ...
        'xlim',trange, 'ylim', [0 nplot*nFP], 'yticklabel', []);
    ynow = ynow - plot_height*vspacing;
    axis off
    title(['S|' Saline1 '|Second'])

    n = nTrial2Half;
    Press_Saline1b        = Press_Saline1(end-n:end);
    FPs_Saline1b             = FPs_Saline1(end-n:end);
    Outcome_Saline1b         = Outcome_Saline1(end-n:end);

    for k =1:nFP
        if k == 1
            xlabel('Hold duration (s)')
        end

        PressDur                = Press_Saline1b(FPs_Saline1b==FPs(k)*1000);
        kOutcome                = Outcome_Saline1b(FPs_Saline1b==FPs(k)*1000);

        % get rid of 'Dark' presses
        PressDur(strcmp(kOutcome, 'Dark')) = [];
        IndRandPerm             = randperm(length(PressDur), nplot);
        PressDur_Selected       = PressDur(IndRandPerm);

        plotshaded([0 FPs(k)], [nplot*(k-1) nplot*(k-1); nplot*k nplot*k],  FP_colors{k})

        IndSeq = (1:nplot)+nplot*(k-1);
        scatter(PressDur_Selected, IndSeq, marker_type, ...
            'sizedata', marker_size,'markeredgecolor', FP_colors{k}, 'MarkerFaceColor',FP_colors{k})
    end

    %     This is the first DCZ session

    ha3 = axes('units', 'centimeters', ...
        'position', [xnow, ynow plot_width plot_height], ...
        'ydir','normal','nextplot', 'add', ...
        'xlim',trange, 'ylim', [0 nplot*nFP], 'yticklabel', []);
    title(['D|' DCZ1 '|First'], 'color', inactivation_color)
    axis off
    ynow = ynow - plot_height*vspacing;

    % first 100 trials
    n = nTrial1Half;
    Press_DCZ1a             = Press_DCZ1(1:n);
    FPs_DCZ1a               = FPs_DCZ1(1:n);
    Outcome_DCZ1a         = Outcome_DCZ1(1:n);

    for k =1:nFP
        if k == 1
            xlabel('Hold duration (s)')
        end
        PressDur                = Press_DCZ1a(FPs_DCZ1a==FPs(k)*1000);
        kOutcome                = Outcome_DCZ1a(FPs_DCZ1a==FPs(k)*1000);
        % get rid of 'Dark' presses
        PressDur(strcmp(kOutcome, 'Dark')) = [];
        IndRandPerm             = randperm(length(PressDur), nplot);
        PressDur_Selected       = PressDur(IndRandPerm);
        plotshaded([0 FPs(k)], [nplot*(k-1) nplot*(k-1); nplot*k nplot*k],  FP_colors{k});
        IndSeq = (1:nplot)+nplot*(k-1);
        scatter(PressDur_Selected, IndSeq, marker_type, ...
            'sizedata', marker_size,'markeredgecolor', FP_colors{k}, 'MarkerFaceColor',FP_colors{k})
    end

    ha4 = axes('units', 'centimeters', ...
        'position', [xnow, ynow plot_width plot_height], ...
        'ydir','normal','nextplot', 'add', ...
        'xlim',trange, 'ylim', [0 nplot*nFP], 'yticklabel', []);

    title(['D|' DCZ1 '|Second'], 'color', inactivation_color)


    % first 150 trials
    n   = nTrial2Half;
    Press_DCZ1b           = Press_DCZ1(end-n:end);
    FPs_DCZ1b             = FPs_DCZ1(end-n:end);
    Outcome_DCZ1b         = Outcome_DCZ1(end-n:end);

    for k =1:nFP
        if k == 1
            xlabel('Hold duration (s)')
        end

        PressDur                = Press_DCZ1b(FPs_DCZ1b==FPs(k)*1000);
        kOutcome                = Outcome_DCZ1b(FPs_DCZ1b==FPs(k)*1000);

        % get rid of 'Dark' presses
        PressDur(strcmp(kOutcome, 'Dark')) = [];
        IndRandPerm             = randperm(length(PressDur), nplot);
        PressDur_Selected       = PressDur(IndRandPerm);

        plotshaded([0 FPs(k)], [nplot*(k-1) nplot*(k-1); nplot*k nplot*k],  FP_colors{k})

        IndSeq = (1:nplot)+nplot*(k-1);
        scatter(PressDur_Selected, IndSeq, marker_type, ...
            'sizedata', marker_size,'markeredgecolor', FP_colors{k}, 'MarkerFaceColor',FP_colors{k})
    end

    ynow = 1.5;
    for k =1:nFP
        ha6 = axes('units', 'centimeters', ...
            'position', [xnow, ynow plot_width plot_height2], ...
            'ydir','normal','nextplot', 'add', ...
            'xlim',trange, 'ylim',pdf_range);
        if pvals(k)>0.0001
            text( FPs(k)+0.75, pdf_range(2)*0.8, sprintf('p=%2.4f', pvals(k)), 'fontname','dejavu sans', 'fontsize', 7)
        else
            text(FPs(k)+0.75, pdf_range(2)*0.8, 'p<0.0001', 'fontname','dejavu sans', 'fontsize', 7)
        end

        ynow = ynow +plot_height2+0.05;

        if k >1
            set(gca, 'xtick', [], 'ytick',[])
            axis off
        elseif k==1 && ii ==1
            xlabel('Hold duration (s)')
            ylabel('Density (1/s)')
        end

        plotshaded([0 FPs(k)], [0 0; pdf_range(2) pdf_range(2)],  FP_colors{k});

        kPDF = PDF_Saline{k};
        xi = kPDF(:, 1);
        f  = kPDF(:, 2);
        f_ci = kPDF(:, [3 4]);
        plotshaded(xi', f_ci', [.5 .5 .5]);
        plot(xi, f, 'color', FP_colors{k},  'linewidth', 1.5)

        kPDF = PDF_DCZ{k};
        xi = kPDF(:, 1);
        f  = kPDF(:, 2);
        f_ci = kPDF(:, [3 4]);
        plotshaded(xi', f_ci', [.5 .5 .5]);
        plot(xi, f, 'color', inactivation_color,  'linewidth', 1.5)
        line([categories(1:end-1); categories(1:end-1)]+FPs(k), repmat(pdf_range', 1, length(categories)-1), ...
            'color', 'k', 'linestyle', ':', 'linewidth', 0.75)
    end
end

% Lastly, we check the combined data
xnow = xnow+4;
ynow = 1.5;
pvals_combined = zeros(1, nFP);
SRTOut.Presses_Repeats                              =       PressDurations;

for k =1:nFP
    ha7 = axes('units', 'centimeters', ...
        'position', [xnow, ynow plot_width plot_height2], ...
        'ydir','normal','nextplot', 'add', ...
        'xlim',trange, 'ylim',pdf_range);
    if k == nFP
        title('Sessions combined', 'fontname','dejavu sans', 'fontsize', 8,'fontweight','bold')
    end
    % compute PDF from combined data:
     kPressDurations_Saline =   cell2mat(squeeze(SRTOut.Presses_Repeats(k,1,:))');
     kPressDurations_DCZ   =    cell2mat(squeeze(SRTOut.Presses_Repeats(k,2,:))');

     [f_saline,  f_saline_ci, xi]                      =       ksdensity_ci(kPressDurations_Saline, xbins,kernel_bw, nboot);
     [f_dcz,  f_dcz_ci, xi]                              =       ksdensity_ci(kPressDurations_DCZ, xbins,kernel_bw, nboot);

     SRTOut.PDF_Saline_Combine            =       [xi' f_saline'  f_saline_ci'];
     SRTOut.PDF_DCZ_Combine               =       [xi' f_dcz'  f_dcz_ci'];

     plotshaded([0 FPs(k)], [0 0; pdf_range(2) pdf_range(2)],  FP_colors{k});
     plotshaded(xi, f_saline_ci, [.5 .5 .5]);
     plot(xi, f_saline, 'color', FP_colors{k},  'linewidth', 1.5);
     plotshaded(xi, f_dcz_ci, [.5 .5 .5]);
     plot(xi, f_dcz, 'color', inactivation_color,  'linewidth', 1.5);
     line([categories(1:end-1); categories(1:end-1)]+FPs(k), repmat(pdf_range', 1, length(categories)-1), ...
         'color', 'k', 'linestyle', ':', 'linewidth', 0.75)
     pvals_combined(j) = Chi2Test([category_cells_saline_combined(k, :);category_cells_dcz_combined(k, :)]);
    if pvals_combined(k)>0.0001
        text( FPs(k)+0.75, pdf_range(2)*0.8, sprintf('p=%2.4f', pvals_combined(k)), 'fontname','dejavu sans', 'fontsize', 7)
    else
        text(FPs(k)+0.75, pdf_range(2)*0.8, 'p<0.0001', 'fontname','dejavu sans', 'fontsize', 7)
    end
    ynow = ynow +plot_height2+0.05;
    if k >1
        set(gca, 'xtick', [], 'ytick',[])
        axis off
    elseif k==1 && ii ==1
        xlabel('Hold duration (s)')
        ylabel('Density (1/s)')
    end
end
 
SRTOut.Categories_Saline_Combined               =      category_cells_saline_combined;
SRTOut.Categories_DCZ_Combined                  =      category_cells_dcz_combined;
SRTOut.Categories_ChiSquare_Combined        =       pvals_combined;

uicontrol('style', 'text', 'units', 'normalized', 'position', [0.4 0.01 0.1 0.025],...
    'string', [obj.Subject ], 'HorizontalAlignment', 'center','BackgroundColor','w', 'fontsize', 10, 'fontweight','bold')

uicontrol('style', 'text', 'units', 'normalized', 'position', [0.5 0.01 0.1 0.025],...
    'string', ['(SRT)' ], 'HorizontalAlignment', 'center','BackgroundColor','w', 'fontsize', 10, 'fontweight','bold')


% save this figure
fig_folder = fullfile(pwd, pathSaveFig);
if ~exist(fig_folder, 'dir')
    mkdir(fig_folder)
end

tosavename=  fullfile(fig_folder, 'Fig1_ResponseDistribution');
saveas(hf, tosavename, 'epsc')
print (hf,'-dpdf', tosavename)
print (hf,'-dpng', tosavename)

target_folder = pwd;
tosavename=   fullfile(target_folder, ['SRTOutDistributionStatistics_' obj.Subject{1} '.mat']);
save(tosavename, 'SRTOut')

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
% xx = linspace(0, 20, 1000);
% yy = chi2pdf(xx, dof);
%
% figure;
% plot(xx, yy, 'r', 'linewidth', 1);
% hold on
% line([1 1]*T, get(gca, 'ylim'), 'color', 'c','linewidth', 2)
% xlabel('Chi-square')
% ylabel('Density')
%
% line([14 15], [0.002 0.06],'color','k')
% text(14, 0.065, sprintf('p-val: %2.2f', p_value))
% legend('Chi2 distribution', 'test stat.')