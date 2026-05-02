%% Load data
Anm='Baba';
load(strcat('SRTGroupClass_',Anm,'.mat'))

 %% Plotting logistics
 markersize = 10;
 nboot = 500;
 func = @(x)median(x);
 kernel_bw = 0.15;
 npre_plot = 20;
 markeralpha = 0.75;
 FP_colors ={'#9BBEC8', '#427D9D', '#164863'};

nTrials_PreLesion = 200; % choose 100 presses from each FP prelesion
nTrials_PostLesionEarly = 200;
nTrials_PostLesionLate = 200;
%% Check learning
AllSessions = obj.LesionSessions;
figure;
plot(AllSessions, 'ko-')

AllPreTrialsIndex       =   obj.LesionTrials<0 & obj.Stage == 1;
HoldTime_PreLesion      =   obj.HoldTime(AllPreTrialsIndex);
Trials_PreLesion        =   obj.LesionTrials(AllPreTrialsIndex);
FPs_PreLesion           =   obj.FP(AllPreTrialsIndex);
FPTypes                 =   obj.MixedFP;
nFP                     =   length(FPTypes);
UniqueSessions          =   unique(Trials_PreLesion);
nSessions               =   length(UniqueSessions);
close all;

if ~isempty(npre_plot) && npre_plot <nSessions
    UniqueSessions          =   UniqueSessions(end-npre_plot:end);
    nSessions                       =   npre_plot;
end
xlabels = num2cell(-nSessions:-1);

hf = figure('units', 'Centimeters', 'position',[5 5 20 17], 'Visible','on', 'paperpositionmode', 'auto');
xbins =(0:0.05:4);
pdf_pre = zeros(length(xbins), nSessions, nFP); % pdf x session x nFP
DurRange =[0 3];
theta_care = zeros(3, nSessions, nFP);

PreLesionPresses = cell(1, nFP);

tic
ha_scatter_prelesion = zeros(1, nFP);
for i =1:nFP
    ha_scatter_prelesion(i) = axes('units', 'Centimeters', 'position',[1.5, 2+(i-1)*5, 17.5, 4]);
    set(ha_scatter_prelesion(i), 'nextplot', 'add', 'ylim', DurRange,'xlim', [0 nSessions-1],'xtick', 0.5+[0:nSessions-1], 'xticklabel', xlabels);
    if i == 1
        xlabel('Session # relative to lesion')
        ylabel('Press duration (s)')
    end
    line([0 nSessions], [FPTypes(i) FPTypes(i)]/1000, 'color', 'r', 'linestyle', '--', 'linewidth', 1)
    for j = 1:nSessions
        ij_HoldDurations_PreLesion = HoldTime_PreLesion(Trials_PreLesion == UniqueSessions(j) & FPs_PreLesion==FPTypes(i));    
        x_index = rand(1, length(ij_HoldDurations_PreLesion))*0.8+(j-1);
        scatter(ha_scatter_prelesion(i), x_index, ij_HoldDurations_PreLesion,'o', 'MarkerEdgeColor','none', 'MarkerFaceColor',FP_colors{i}, ...
            'SizeData', markersize, 'MarkerFaceAlpha', markeralpha)
        index_and_press = [x_index; ij_HoldDurations_PreLesion];
        PreLesionPresses{i} = [PreLesionPresses{i} index_and_press];

        % We look at the median
        if ~isempty(ij_HoldDurations_PreLesion) && length(ij_HoldDurations_PreLesion)>10
            this_median = func(ij_HoldDurations_PreLesion);
            this_ci = bootci(nboot, {func,  ij_HoldDurations_PreLesion}, 'type', 'per');
            theta_care(:, j, i) = [this_median; this_ci];
            [f, xi]=ksdensity(ij_HoldDurations_PreLesion, xbins, 'Bandwidth',kernel_bw);
            pdf_pre(:, j, i)= f;
        else
            theta_care(:, j, i) = [nan; nan; nan];
            pdf_pre(:, j, i)= nan(length(xbins), 1);
        end
        line([j, j],DurRange,'color','k', 'linestyle', ':','linewidth', 1)
        set(ha_scatter_prelesion(i), 'xlim', [0, j])
    end
end
toc

for i =1:length(PreLesionPresses)
    n = length(PreLesionPresses{i});
    rand_selection = [n- nTrials_PreLesion+1:n];
    press_selection = PreLesionPresses{i}(:, rand_selection);
    scatter(ha_scatter_prelesion(i), press_selection(1, :),  press_selection(2, :),'x', 'MarkerEdgeColor','r', 'MarkerFaceColor',FP_colors{i}, ...
        'SizeData', markersize, 'MarkerFaceAlpha', markeralpha)
    PreLesionPresses{i} = press_selection(2, :);
end

% save this figure
fig_folder = fullfile(pwd, 'Figure');
if ~exist(fig_folder, 'dir')
    mkdir(fig_folder)
end
tosavename=  fullfile(fig_folder, [Anm,'Fig1_PreLesionHoldDurationDistribution']);
saveas(gcf, tosavename, 'epsc')
print (gcf,'-dpdf', tosavename)
print (gcf,'-dpng', tosavename)

%% Visualize the distribution
set_matlab_default
hf2 = figure('units', 'Centimeters', 'position',[5 5 21 18], 'Visible','on', 'paperpositionmode', 'auto');
ylim = [0 3];
xlim = [0 3];
nskip = floor(nSessions/5);
 
sessions_plotted = [];
sessions_plotted_relative = [];
for i =1:nFP
    ha_i = axes('units', 'Centimeters', 'position',[1.5+6*(i-1),1.5, 5, 5]);
    set(ha_i, 'nextplot', 'add', 'ylim', ylim, 'xlim', xlim);
    xlabel('Time (s)')
    ylabel('Probability Density (1/s)')
    all_colors = (parula(5+size(pdf_pre, 2)));
    for j = 1:nSessions
        if rem(j, nskip) ==0
            if i == 1
                sessions_plotted=[sessions_plotted j];
                sessions_plotted_relative = [sessions_plotted_relative UniqueSessions(j)];
            end
            plot(xbins, pdf_pre(:, j, i), 'color', all_colors(2+j, :), 'linewidth', 2);
        end
    end
    line([FPTypes(i), FPTypes(i)]/1000, ylim, 'color', 'r', 'linewidth', 1, 'linestyle', '-.')
end

ha_bar = axes('units', 'Centimeters', 'position',[1+6*nFP, 1.5, 0.25, 2]);
set(ha_bar, 'nextplot', 'add', 'ylim', [0 nSessions], 'xlim', [0 1], 'ytick', sessions_plotted, 'yticklabel',sessions_plotted_relative , 'YAxisLocation','right');
for i =1:nSessions
    scatter(0.5, i, 'MarkerFaceColor', all_colors(2+i, :), 'MarkerEdgeColor','none','Marker','s')
end
ylabel('Sessions')

% plot colormap
colormap(jet)
ylim = [0 3];
for i =1:nFP
    ha_i = axes('units', 'Centimeters', 'position',[1.5, 5+i*3.25, 7, 3]);
    set(ha_i, 'nextplot', 'add', 'ylim', DurRange, 'xlim', [0 nSessions+1], 'xtick', 0.5+[0:nSessions-1], 'xticklabel', xlabels);
    if i>1
        set(ha_i, 'xtick', [])
    else
        xlabel('Sessions')
        ylabel('Time (s)')
    end
    for j = 1:nSessions
        imagesc(ha_i, j, xbins, pdf_pre(:, j, i), ylim)
    end
    line([0 nSessions+1], [FPTypes(i) FPTypes(i)]/1000, 'color', 'r', 'linewidth', 1, 'linestyle', '--' )
end

% place colorbar
ha_bar = colorbar;
set(ha_bar, 'units', 'Centimeters', 'position', [8.75 5+3.25, 0.25, 3]);
ha_bar.Label.String = 'Probability density (1/s)';

for i =1:nFP
    ha_i = axes('units', 'Centimeters', 'position',[11.5, 5+i*3.25, 7, 3]);
    set(ha_i, 'nextplot', 'add', 'ylim', DurRange, 'xlim', [0.5 nSessions+0.5], 'xtick', 0.5+[0:nSessions-1], 'xticklabel', xlabels);
    if i>1
        set(ha_i, 'xtick', [])
    else
        xlabel('Session # relative to lesion')
        ylabel('Press duration (s)')
    end
    for j = 1:nSessions
        line(ha_i, [j, j], theta_care([2 3], j, i), 'linewidth', 2, 'color', FP_colors{i});
        plot(j, theta_care(1, j, i), 'marker', 'o', 'MarkerEdgeColor',FP_colors{i},...
            'MarkerFaceColor', 'w', 'markersize', 4, 'linewidth', 1)
        %         imagesc(ha_i, j, xbins, pdf_pre(:, j, i), ylim)
    end
    line([0 nSessions+1], [FPTypes(i) FPTypes(i)]/1000, 'color', 'r', 'linewidth', 1, 'linestyle', '-.' )
end

% save this figure
fig_folder = fullfile(pwd, 'Figure');
if ~exist(fig_folder, 'dir')
    mkdir(fig_folder)
end
tosavename=  fullfile(fig_folder, [Anm,'Fig2_PreLesionHoldDurationDistribution']);
saveas(gcf, tosavename, 'epsc')
print (gcf,'-dpdf', tosavename)
print (gcf,'-dpng', tosavename)

 
%% Check post
AllSessions = obj.LesionSessions;
figure;
plot(AllSessions, 'ko-')
AllPostTrialsIndex       =   obj.LesionTrials>0 & obj.Stage == 1;
HoldTime_PostLesion      =   obj.HoldTime(AllPostTrialsIndex);
Trials_PostLesion        =   obj.LesionTrials(AllPostTrialsIndex);
FPs_PostLesion           =   obj.FP(AllPostTrialsIndex);
FPTypes                 =   obj.MixedFP;
nFP                     =   length(FPTypes);
UniqueSessions          =   unique(Trials_PostLesion);
nSessions               =   length(UniqueSessions);
 
PostLesionPresses = cell(1, nFP);

hf = figure('units', 'Centimeters', 'position',[5 5 20 17], 'Visible','on', 'paperpositionmode', 'auto');
xbins =(0:0.05:4);
pdf_Post = zeros(length(xbins), nSessions, nFP); % pdf x session x nFP
DurRange =[0 3];
kernel_bw = 0.15;
theta_care = zeros(3, nSessions, nFP);

func = @(x)median(x);
ind_post_lesion_sessions = num2cell(1:nSessions);
tic
ha_scatter_postlesion = zeros(1, nFP);


for i =1:nFP
    ha_scatter_postlesion(i) = axes('units', 'Centimeters', 'position',[1.5, 2+(i-1)*5, 17.5, 4]);
    set(ha_scatter_postlesion(i) , 'nextplot', 'add', 'ylim', DurRange, 'xtick', [1:nSessions]-0.5, 'xticklabels', ind_post_lesion_sessions);
    if i == 1
        xlabel('Session # relative to lesion')
        ylabel('Press duration (s)')
    end
    line([0 nSessions], [FPTypes(i) FPTypes(i)]/1000, 'color', 'r', 'linestyle', '--', 'linewidth', 1)
    for j = 1:nSessions
        ij_HoldDurations_PostLesion = HoldTime_PostLesion(Trials_PostLesion == UniqueSessions(j) & FPs_PostLesion==FPTypes(i));
        x_index = rand(1, length(ij_HoldDurations_PostLesion))*0.8+(j-1);
        index_and_press = [x_index; ij_HoldDurations_PostLesion];
        PostLesionPresses{i} = [PostLesionPresses{i} index_and_press];

        scatter(ha_scatter_postlesion(i) , x_index, ij_HoldDurations_PostLesion,'o', ...
            'MarkerEdgeColor','none', 'MarkerFaceColor',FP_colors{i}, ...
            'SizeData', markersize, 'MarkerFaceAlpha', markeralpha)
        % We look at the median
        if ~isempty(ij_HoldDurations_PostLesion) && length(ij_HoldDurations_PostLesion)>10
            this_median = func(ij_HoldDurations_PostLesion);
            this_ci = bootci(nboot, {func,  ij_HoldDurations_PostLesion}, 'type', 'per');
            theta_care(:, j, i) = [this_median; this_ci];
            [f, xi]=ksdensity(ij_HoldDurations_PostLesion, xbins, 'Bandwidth',kernel_bw);
            pdf_Post(:, j, i)= f;
        else
            theta_care(:, j, i) = [nan; nan; nan];
            pdf_Post(:, j, i)= nan(length(xbins), 1);
        end
        line([j, j],DurRange,'color','k', 'linestyle', ':','linewidth', 1)
        set(ha_scatter_postlesion(i) , 'xlim', [0, j])
    end
end
toc

PostLesionPresses_Early = cell(1, nFP);
PostLesionPresses_Late = cell(1, nFP);

for i =1:nFP

    scatter(ha_scatter_postlesion(i) , PostLesionPresses{i}(1, 1:nTrials_PostLesionEarly), ...
        PostLesionPresses{i}(2, 1:nTrials_PostLesionEarly),'x', ...
        'MarkerEdgeColor','r', 'MarkerFaceColor',FP_colors{i}, ...
        'SizeData', markersize, 'MarkerFaceAlpha', markeralpha)

    scatter(ha_scatter_postlesion(i) , PostLesionPresses{i}(1, end-nTrials_PostLesionLate+1:end), ...
        PostLesionPresses{i}(2, end-nTrials_PostLesionLate+1:end),'x', ...
        'MarkerEdgeColor','r', 'MarkerFaceColor',FP_colors{i}, ...
        'SizeData', markersize, 'MarkerFaceAlpha', markeralpha)

    PostLesionPresses_Early{i} = [PostLesionPresses_Early{i} PostLesionPresses{i}(2, 1:nTrials_PostLesionEarly)];
    PostLesionPresses_Late{i} = [PostLesionPresses_Late{i} PostLesionPresses{i}(2, end-nTrials_PostLesionLate+1:end)];
end

% save this figure
fig_folder = fullfile(pwd, 'Figure');
if ~exist(fig_folder, 'dir')
    mkdir(fig_folder)
end
tosavename=  fullfile(fig_folder,[Anm, 'Fig1_PostLesionHoldDurationDistribution']);
saveas(gcf, tosavename, 'epsc')
print (gcf,'-dpdf', tosavename)
print (gcf,'-dpng', tosavename)

%% Visualize the distribution
set_matlab_default
hf2 = figure('units', 'Centimeters', 'position',[5 5 21 18], 'Visible','on', 'paperpositionmode', 'auto');

ylim = [0 3];
xlim = [0 3];
nskip = floor(nSessions/5);
sessions_plotted = [];
sessions_plotted_relative = [];
for i =1:nFP
    ha_i = axes('units', 'Centimeters', 'position',[1.5+6*(i-1),1.5, 5, 5]);
    set(ha_i, 'nextplot', 'add', 'ylim', ylim, 'xlim', xlim);
    xlabel('Time (s)')
    ylabel('Probability Density (1/s)')
    all_colors = (parula(5+size(pdf_Post, 2)));
    for j = 1:nSessions
        if rem(j, nskip) ==0
            if i == 1
                sessions_plotted=[sessions_plotted j];
                sessions_plotted_relative = [sessions_plotted_relative UniqueSessions(j)];
            end
            plot(xbins, pdf_Post(:, j, i), 'color', all_colors(j, :), 'linewidth',2);
        end
    end
    line([FPTypes(i), FPTypes(i)]/1000, ylim, 'color', 'r', 'linestyle', '-.')
end

ha_bar = axes('units', 'Centimeters', 'position',[1+6*nFP, 1.5, 0.25, 2]);
set(ha_bar, 'nextplot', 'add', 'ylim', [0 nSessions], 'xlim', [0 1],...
    'ytick', sessions_plotted, 'yticklabel',sessions_plotted_relative , 'YAxisLocation','right');
for i =1:nSessions
    scatter(0.5, i, 'MarkerFaceColor', all_colors(2+i, :), 'MarkerEdgeColor','none','Marker','s')
end
ylabel('Sessions')

% plot colormap
colormap(jet)
ylim = [0 3];
for i =1:nFP
    ha_i = axes('units', 'Centimeters', 'position',[1.5, 5+i*3.25, 7, 3]);
    set(ha_i, 'nextplot', 'add', 'ylim', DurRange, 'xlim', [0 nSessions+1]);
    if i>1
        set(ha_i, 'xtick', [])
    else
        xlabel('Sessions')
        ylabel('Time (s)')
    end
    for j = 1:nSessions
        imagesc(ha_i, j, xbins, pdf_Post(:, j, i), ylim)
    end
    line([0 nSessions+1], [FPTypes(i) FPTypes(i)]/1000, 'color', 'r', 'linewidth', 1, 'linestyle', '-.' )
end

% place colorbar
ha_bar = colorbar;
set(ha_bar, 'units', 'Centimeters', 'position', [8.75 5+3.25, 0.25, 3]);
ha_bar.Label.String = 'Probability density (1/s)';

for i =1:nFP
    ha_i = axes('units', 'Centimeters', 'position',[11.5, 5+i*3.25, 7, 3]);
    set(ha_i, 'nextplot', 'add', 'ylim', DurRange, 'xlim', [0 nSessions+1]);
    if i>1
        set(ha_i, 'xtick', [])
    else
        xlabel('Sessions')
        ylabel('Press duration (s)')
    end
    for j = 1:nSessions
        line(ha_i, [j, j], theta_care([2 3], j, i), 'linewidth', 2, 'color', FP_colors{i});
        plot(j, theta_care(1, j, i), 'marker', 'o', 'MarkerEdgeColor',FP_colors{i},...
        'MarkerFaceColor', 'w', 'markersize', 4, 'linewidth', 1)
    end
    line([0 nSessions+1], [FPTypes(i) FPTypes(i)]/1000, 'color', 'r', 'linewidth', 1, 'linestyle', '-.' )
end
% save this figure
fig_folder = fullfile(pwd, 'Figure');
if ~exist(fig_folder, 'dir')
    mkdir(fig_folder)
end
tosavename=  fullfile(fig_folder,[Anm, 'Fig2_PostLesionHoldDurationDistribution']);
saveas(gcf, tosavename, 'epsc')
print (gcf,'-dpdf', tosavename)
print (gcf,'-dpng', tosavename)

%% Compare pre and post

hf3 = figure('units', 'Centimeters', 'position',[5 5 18 2+2.5+2.5+2.5+5], 'Visible','on', 'paperpositionmode', 'auto', 'color', 'w');
PDF_PrePost = cell(nFP, 3);
shaded_color = '#99B080';
ResponseWin = 600;
PDF_range = [0 2.5];
nboot = 1000;

early_color = '#FF6C22';
late_color = '#7743DB';

ha1a = zeros(1, nFP);
ha1b = zeros(1, nFP);
ha1c = zeros(1, nFP);
ha2 = zeros(1, nFP);
 

for i =1:nFP
    ha1a(i)= axes('units','centimeters', 'position',[2+5*(i-1) 2 4 2], 'xlim', [0 3], 'nextplot', 'add');

    plotshaded([FPTypes(i) FPTypes(i)+ResponseWin]/1000, [0 0; length(PreLesionPresses{i}) length(PreLesionPresses{i})], shaded_color);
    scatter(ha1a(i),  PreLesionPresses{i}, (1:nTrials_PreLesion),'o', ...
        'MarkerEdgeColor','none', 'MarkerFaceColor',FP_colors{i}, ...
        'SizeData', markersize*1.5, 'MarkerFaceAlpha', markeralpha, 'linewidth', 0.25)
    line([FPTypes(i) FPTypes(i)]/1000, [0 nTrials_PreLesion],'color', [0.8 0.1 0.1],'linewidth', 1, 'linestyle','-.');
    if i ==1
        xlabel('Press duration (s)')
        ylabel('Pre-Lesion')
    end

    % add post-lesion
    ha1b(i)= axes('units','centimeters', 'position',[2+5*(i-1) 2+2.5 4 2], 'xlim', [0 3], 'nextplot', 'add');
    plotshaded([FPTypes(i) FPTypes(i)+ResponseWin]/1000, [0 0; nTrials_PostLesionEarly nTrials_PostLesionEarly], shaded_color);
    scatter(ha1b(i),  PostLesionPresses_Early{i}, (1:length(PostLesionPresses_Early{i})),'^', ...
        'MarkerEdgeColor','none', 'MarkerFaceColor',FP_colors{i}, ...
        'SizeData', markersize*1.5, 'MarkerFaceAlpha', markeralpha, 'linewidth', 0.25)
    line([FPTypes(i) FPTypes(i)]/1000, [0 nTrials_PostLesionEarly],'color', [0.8 0.1 0.1],'linewidth', 1, 'linestyle','-.');
    line([FPTypes(i) FPTypes(i)]/1000, [0 nTrials_PreLesion],'color', [0.8 0.1 0.1],'linewidth', 1, 'linestyle','-.');
    if i ==1
        ylabel('Post (early)', 'color', early_color)
    end

    % add post-lesion
    ha1c(i)= axes('units','centimeters', 'position',[2+5*(i-1) 2+2.5+2.5 4 2], 'xlim', [0 3], 'nextplot', 'add');
    plotshaded([FPTypes(i) FPTypes(i)+ResponseWin]/1000, [0 0; nTrials_PostLesionLate nTrials_PostLesionLate], shaded_color);
    scatter(ha1c(i),  PostLesionPresses_Late{i}, (1:length(PostLesionPresses_Late{i})),'d', ...
        'MarkerEdgeColor','none', 'MarkerFaceColor',FP_colors{i}, ...
        'SizeData', markersize*1.5, 'MarkerFaceAlpha', markeralpha, 'linewidth', 0.25)
    line([FPTypes(i) FPTypes(i)]/1000, [0 nTrials_PostLesionLate],'color', [0.8 0.1 0.1],'linewidth', 1, 'linestyle','-.');

    if i ==1
        ylabel('Post (late)', 'color', late_color)
    end

    ha2(i)= axes('units','centimeters', 'position',[2+5*(i-1)  2+2.5+2.5+2.5 4 4], 'xlim', [0 3], 'ylim', PDF_range, 'nextplot', 'add');
%     plotshaded([FPTypes(i) FPTypes(i)+ResponseWin]/1000, [0 0; max(PDF_range) max(PDF_range)], shaded_color);
    line([FPTypes(i) FPTypes(i)]/1000,PDF_range,'color', [0.8 0.1 0.1],'linewidth', 1, 'linestyle','-.');
    if i ==1
        ylabel('Probability density (1/s)')
    end
    % pre-lesion
    [f, xi]=ksdensity(PreLesionPresses{i}, xbins, 'Bandwidth',kernel_bw);
    [f_ci] = ksdensity_ci(PreLesionPresses{i}, xbins,kernel_bw, nboot);
    plotshaded(xi, f_ci, FP_colors{i});
    plot(xi, f, 'color', FP_colors{i},  'linewidth', 1.5)

    % post-lesion(early)
    [f, xi]=ksdensity(PostLesionPresses_Early{i}, xbins, 'Bandwidth',kernel_bw);
    [f_ci] = ksdensity_ci(PostLesionPresses_Early{i}, xbins,kernel_bw, nboot);
    plotshaded(xi, f_ci, FP_colors{i});
    plot(xi, f, 'color', early_color,  'linewidth', 1.5, 'linestyle', '-')

    % post-lesion(late)
    [f, xi]=ksdensity(PostLesionPresses_Late{i}, xbins, 'Bandwidth',kernel_bw);
    [f_ci] = ksdensity_ci(PostLesionPresses_Late{i}, xbins,kernel_bw, nboot);
    plotshaded(xi, f_ci, FP_colors{i});
    plot(xi, f, 'color', late_color,  'linewidth', 1.5, 'linestyle', '-')

    if i ==1
    legend('', '', 'Pre', '', 'Post(early)', '',  'Post(late)', 'box', 'off')
    end
end

uicontrol('style', 'text', 'units', 'normalized', 'position', [0.1 0.95 0.8 0.05],...
    'string', [Anm,'_first lesion (bilateral DLS) and recovery'], 'BackgroundColor','w', 'fontsize', 11, 'fontweight','bold')

% save this figure
fig_folder = fullfile(pwd, 'Figure');
if ~exist(fig_folder, 'dir')
    mkdir(fig_folder)
end
tosavename=  fullfile(fig_folder,[Anm, 'Fig3_PostLesionAndRecovery']);
saveas(gcf, tosavename, 'epsc')
print (gcf,'-dpdf', tosavename)
print (gcf,'-dpng', tosavename)

%% 

function    [f_ci] = ksdensity_ci(press_durs, xbins,kernel_bw, nboot);
    f_boots = zeros(nboot, length(xbins));
    nsample = length(press_durs);
    tic
    for i =1:nboot
        press_durs_boot = press_durs(randi(nsample, 1, nsample));
         [f, xi]=ksdensity(press_durs_boot, xbins, 'Bandwidth',kernel_bw);
        f_boots(i, :) = f;
    end
    toc
    f_ci = quantile(f_boots, [0.025 0.975]);
end

