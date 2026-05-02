function [g_soft_norm, soft_factor, g_mean] = cal_soft_norm(g, soft_norm)

% Extracted form preprocessing_pca_analysis by J Yu 20250831
% Ideas come from the following

% PCA references:
% Churchland, M. M., & Shenoy, K. V. (2007). Temporal Complexity and Heterogeneity of Single-Neuron Activity in Premotor and Motor Cortex. Journal of Neurophysiology. https://doi.org/10.1152/jn.00095.2007
% Principal component analysis (PCA) was applied to the neural responses collected using the direction series, 108 of which passed the criteria for inclusion. The response pattern of each neuron was considered to be a single observation. We considered times from 150 ms before until 300 ms after movement onset, with the mean firing rate sampled every 10 ms, for a total of 46 data points. Each neuron thus contributed a single 1,288-dimensional observation (46 time-points and 28 target conditions). Each of these vectors had its mean subtracted and was normalized so that the maximum value minus the minimum value was one. PCA was performed on the population of 108 such observations, resulting in 107 PCs. Each of these is itself a 1,288-dimensional vector, embodying a component response pattern. For a given set of PCs (e.g., the 1st 10), the proportion of variance accounted for was computed as the cumulative sum of the eigenvalues associated with those PCs.
% Late, Churchland used 'soft' normalization as follows (in Churchland, M. M., Cunningham, J. P., Kaufman, M. T., Foster, J. D., Nuyujukian, P., Ryu, S. I., & Shenoy, K. V. (2012). Neural population dynamics during reaching. Nature, 487(7405), 51–56. https://doi.org/10.1038/nature11129):
% 'Soft' normalization was used, so that neurons with very strong responses were reduced to approximately unity range, but neurons with weak responses had less than unity range. For each neuron, the data were mean-centred at every time: the average across-condition response was subtracted from the response for each condition. Thus, all subsequent analysis focused on those aspects of the neural response that differ across conditions. 
% Basically, it works like this:
% Add a Softening Term: Introduce a small constant (often called the "soft norm" or offset, e.g., 5 spikes/second) to the denominator. This "softens" the normalization:
% Normalized response = response / (range + soft_norm)
% Sometimes it's preceded by mean-subtraction or min-subtraction to shift the data (e.g., response_normalized = (response - min) / (range + soft_norm)), ensuring values are roughly between 0 and 1 for high-range neurons.
% Purpose and Effect:
% For neurons with large ranges (strong modulations), the soft_norm is negligible, so they normalize close to a [0,1] scale, reducing their outsized influence on variance-based analyses like PCA.
% For neurons with small ranges (weak or noisy responses), the soft_norm dominates the denominator, keeping their normalized values small (<1) and preventing noise amplification (which could happen with hard division by a tiny range).
% This equalizes neuron contributions without harsh clipping or equal-variance assumptions, preserving relative modulations while making the population more comparable.

if nargin<2
    soft_norm = 5;
end

% Step 1: Mean subtraction
g_mean = mean(g);
g_mean_sub = g - g_mean;

% Step 2: Compute range of mean-subtracted data
data_range = max(g_mean_sub) - min(g_mean_sub);

% Step 3: Soft normalization
if data_range == 0
    g_soft_norm = g_mean_sub;  % Avoid division by zero for flat data
    soft_factor = 1;
else
    g_soft_norm = g_mean_sub / (data_range + soft_norm);
    soft_factor = data_range + soft_norm;
end