function score_out = Similarity(TrajDist1, TrajDist2 , name)

% Jianing Yu 9/12/2023

% Here we compute similarity scores for reaches in block 1, in block 2, and
% across blocks 1 and 2

% bootstraping , n = n_total, N = 5000 (iterations)
% self-self

Nresample = 5000;
n1 = size(TrajDist1, 3);
n2 = size(TrajDist2, 3);

% randomly sample nselct trials from condition 1 and 2

TrajCorrResample_Block1 = zeros(1, Nresample);
TrajDistanceResample_Block1 = zeros(1, Nresample);
TrajCorrResample_Block2 = zeros(1, Nresample);
TrajDistanceResample_Block2 = zeros(1, Nresample);

TrajCorrResample_Comparison = zeros(1, Nresample);
TrajDistanceResample_Comparison = zeros(1, Nresample);

% This is the block 1
TrajCorr            =           [];
TrajDistance    =           [];

for k = 1:n1-1
    j = k+1;
    T1a                            =       reshape(TrajDist1(:, :, k), 1, []);
    T1b                            =       reshape(TrajDist1(:, :, j), 1, []);
    r                                 =       corrcoef(T1a, T1b);
    TrajCorr                    =       [TrajCorr r(1, 2)];
    TrajDistance            =         [TrajDistance norm(T1a-T1b)];
end

% Bootstrapping
%   TrajCorr                              1x101                   808  double  
%   TrajDistance                      1x101                   808  double 
n_results = length(TrajCorr);
% we need to do bootstrapping on this data set (using 'select with
% replacement' method)
ResampleIndex = randi(n_results, [Nresample, n_results]);
TrajCorrResample_Block1 = mean(TrajCorr(ResampleIndex), 2);
TrajDistanceResample_Block1 = mean(TrajDistance(ResampleIndex), 2);

score_out.TrajCorr.Block1_mean                                      =           mean(TrajCorr);
score_out.TrajCorr.Block1_Resamples                               =          TrajCorrResample_Block1;
score_out.TrajCorr.Block1_CI95           =          prctile(TrajCorrResample_Block1, [2.5 97.5]);
sprintf('Block 1 (correlation coefficient): mean %2.2f, 95%% confidence interval [%2.2f %2.2f]', score_out.TrajCorr.Block1_mean, score_out.TrajCorr.Block1_CI95)

score_out.TrajDistance.Block1_mean                                      =           mean(TrajDistance);
score_out.TrajDistance.Block1_Resamples                               =          TrajDistanceResample_Block1;
score_out.TrajDistance.Block1_CI95           =          prctile(TrajDistanceResample_Block1, [2.5 97.5]);
sprintf('Block 1 (distance): mean %2.2f, 95%% confidence interval [%2.2f %2.2f]', score_out.TrajDistance.Block1_mean, score_out.TrajDistance.Block1_CI95)



% This is the block 2
TrajCorr            =           [];
TrajDistance    =           [];

for k = 1:n2-1
    j = k+1;
    T2a                            =       reshape(TrajDist2(:, :, k), 1, []);
    T2b                            =       reshape(TrajDist2(:, :, j), 1, []);
    r                                 =       corrcoef(T2a, T2b);
    TrajCorr                    =       [TrajCorr r(1, 2)];
    TrajDistance            =         [TrajDistance norm(T2a-T2b)];
end

% Bootstrapping
%   TrajCorr                              1x101                   808  double  
%   TrajDistance                      1x101                   808  double 
n_results = length(TrajCorr);
% we need to do bootstrapping on this data set (using 'select with
% replacement' method)
ResampleIndex = randi(n_results, [Nresample, n_results]);
TrajCorrResample_Block2 = mean(TrajCorr(ResampleIndex), 2);
TrajDistanceResample_Block2 = mean(TrajDistance(ResampleIndex), 2);
score_out.TrajCorr.Block2_mean                                      =           mean(TrajCorr);
score_out.TrajCorr.Block2_Resamples                               =          TrajCorrResample_Block2;
score_out.TrajCorr.Block2_CI95           =          prctile(TrajCorrResample_Block2, [2.5 97.5]);
sprintf('Block2 (correlation coefficient): mean %2.2f, 95%% confidence interval [%2.2f %2.2f]', score_out.TrajCorr.Block2_mean, score_out.TrajCorr.Block2_CI95)

score_out.TrajDistance.Block2_mean                                      =           mean(TrajDistance);
score_out.TrajDistance.Block2_Resamples                               =          TrajDistanceResample_Block2;
score_out.TrajDistance.Block2_CI95           =          prctile(TrajDistanceResample_Block2, [2.5 97.5]);
sprintf('Block 2 (distance): mean %2.2f, 95%% confidence interval [%2.2f %2.2f]', score_out.TrajDistance.Block2_mean, score_out.TrajDistance.Block2_CI95)

% This is the block 1 vs 2
TrajCorr            =           [];
TrajDistance    =           [];

for k = 1:n1
    for j = 1:n2
        Ta                            =       reshape(TrajDist1(:, :, k), 1, []);
        Tb                            =       reshape(TrajDist2(:, :, j), 1, []);
        r                                 =       corrcoef(Ta, Tb);
        TrajCorr                    =       [TrajCorr r(1, 2)];
        TrajDistance            =         [TrajDistance norm(Ta-Tb)];
    end
end

% Bootstrapping
%   TrajCorr                              1x101                   808  double  
%   TrajDistance                      1x101                   808  double 
n_results = length(TrajCorr);
% we need to do bootstrapping on this data set (using 'select with
% replacement' method)
ResampleIndex = randi(n_results, [Nresample, n_results]);
TrajCorrResample_Block12 = mean(TrajCorr(ResampleIndex), 2);
TrajDistanceResample_Block12 = mean(TrajDistance(ResampleIndex), 2);
score_out.TrajCorr.Block12_mean                                      =           mean(TrajCorr);
score_out.TrajCorr.Block12_Resamples                             =          TrajCorrResample_Block12;
score_out.TrajCorr.Block12_CI95                                        =          prctile(TrajCorrResample_Block12, [2.5 97.5]);
sprintf('Block 1vs2 (correlation coefficient): mean %2.2f, 95%% confidence interval [%2.2f %2.2f]', ...
    score_out.TrajCorr.Block12_mean, score_out.TrajCorr.Block12_CI95)

score_out.TrajDistance.Block12_mean                                      =           mean(TrajDistance);
score_out.TrajDistance.Block12_Resamples                             =          TrajDistanceResample_Block12;
score_out.TrajDistance.Block12_CI95                                        =          prctile(TrajDistanceResample_Block12, [2.5 97.5]);
sprintf('Block 1vs2 (distance): mean %2.2f, 95%% confidence interval [%2.2f %2.2f]', ...
    score_out.TrajDistance.Block12_mean, score_out.TrajDistance.Block12_CI95)

% Plot the results

hf = figure;
set(hf, 'units', 'centimeters', 'position', [4 4 15 8], 'Visible','on', 'PaperPositionMode', 'auto')
ha1 = axes('units', 'centimeters', 'position', [2 2 5 5]);
bins = [0:0.005:1];
bin_centers = bins(1:end-1)+0.005/2;
TrajCorrBlock1_Count = histcounts(score_out.TrajCorr.Block1_Resamples, bins);
hbar1 = bar(bin_centers, TrajCorrBlock1_Count);
hbar1.EdgeColor = 'k';
set(gca, 'nextplot', 'add', 'xlim',[0 1])

TrajCorrBlock2_Count = histcounts(score_out.TrajCorr.Block2_Resamples, bins);
hbar2 = bar(bin_centers, TrajCorrBlock2_Count);
hbar2.EdgeColor = 'r';

TrajCorrBlock12_Count = histcounts(score_out.TrajCorr.Block12_Resamples, bins);
hbar3 = bar(bin_centers, TrajCorrBlock12_Count);
hbar3.EdgeColor = 'c';

set(gca, 'xlim', [0.2 0.8])
xlabel('Correlation cofficient')
ylabel('Frequency')

TrajCorrBlock2_Count = histcounts(score_out.TrajCorr.Block2_Resamples, bins);
hbar2 = bar(bin_centers, TrajCorrBlock2_Count);
hbar2.EdgeColor = 'r';

TrajCorrBlock12_Count = histcounts(score_out.TrajCorr.Block12_Resamples, bins);
hbar3 = bar(bin_centers, TrajCorrBlock12_Count);
hbar3.EdgeColor = 'c';

set(gca, 'xlim', [0.2 0.8], 'box', 'off')
xlabel('Correlation cofficient')
ylabel('Frequency')

% Plot distance
ha2 = axes('units', 'centimeters', 'position', [9 2 5 5]);
bins = [0:100];
bin_centers = bins(1:end-1)+1/2;
TrajDistanceBlock1_Count = histcounts(score_out.TrajDistance.Block1_Resamples, bins);
hbar1 = bar(bin_centers, TrajDistanceBlock1_Count);
hbar1.EdgeColor = 'k';
set(gca, 'nextplot', 'add', 'xlim',[10 80])

TrajDistanceBlock2_Count = histcounts(score_out.TrajDistance.Block2_Resamples, bins);
hbar2 = bar(bin_centers, TrajDistanceBlock2_Count);
hbar2.EdgeColor = 'r';

TrajDistanceBlock12_Count = histcounts(score_out.TrajDistance.Block12_Resamples, bins);
hbar3 = bar(bin_centers, TrajDistanceBlock12_Count);
hbar3.EdgeColor = 'c';

set(gca, 'xlim', [10 80], 'box', 'off')
xlabel('Distance')
ylabel('Frequency') 

if nargin<3
    name = 'Correlation_and_Distance';
else
    name = ['Correlation_and_Distance_' name];
end
tosavename=  fullfile(pwd, 'Figures', name);
saveas(gcf, tosavename, 'epsc')
saveas(gcf, [tosavename], 'fig')
print (gcf,'-dpdf', tosavename)