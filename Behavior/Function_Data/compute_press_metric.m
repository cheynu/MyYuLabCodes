function metric_out = compute_press_metric(ra, rb)

% Jianing Yu 12/17/2023
% Here we compute all useful information of random variables between two
% conditions, or the information of random variable from just one condition
% ra is responses under condition a, rb is responses under condition b
% if you only need to gather information on responses under condition a,
% leave rb empty or just list one input arguement.

if nargin<2
    rb = [];
end

% here is the list of information of the random variable
response_a.median  = [median(ra); bootci(1000, @median,ra)];
response_a.mean     =  [mean(ra); bootci(1000, @mean,ra)];
response_a.iqr          =  [iqr(ra); bootci(1000, @iqr,ra)];
response_a.var         =  [var(ra); bootci(1000, @var, ra)];
response_a.sd          =  [std(ra); bootci(1000, @std, ra)];

% compute mode
bw = 0.1;
response_a.mode = compute_mode(ra, bw);
metric_out.ResponseA = response_a;

% compute response_b, if there is any
if ~isempty(rb)
    % here is the list of information of the random variable
    response_b.median  = [median(rb); bootci(1000, @median,rb)];
    response_b.mean     =  [mean(rb); bootci(1000, @mean,rb)];
    response_b.iqr          =  [iqr(rb); bootci(1000, @iqr,rb)];
    response_b.var         =  [var(rb); bootci(1000, @var, rb)];
    response_b.sd          =  [std(rb); bootci(1000, @std, rb)];
    % compute mode
    response_b.mode = compute_mode(rb, bw);
    % Perform hypothesis testing
    % compare median
    pval.median = permutation_measurements(ra, rb, 'median');
    [~, pval.mean] = ttest2(ra, rb);
    pval.iqr = permutation_measurements(ra, rb, 'iqr');
    pval.var = permutation_measurements(ra, rb, 'var');
    pval.sd = permutation_measurements(ra, rb, 'sd');
    pval.mode = permutation_measurements(ra, rb, 'mode');
    metric_out.ResponseB = response_b;
    metric_out.Pval = pval;
else
    metric_out.ResponseB = [];
    metric_out.Pval = [];
end

function mode_out = compute_mode(r, bw)
tbins = (0:0.01:4);
% we first use kernel density method to estimate the pdf of r (response
% times)
% then, we do a boostrapping to get the confidence intervals

f = ksdensity(r, tbins, 'Bandwidth',bw, 'Function','pdf');
peak = tbins(f==max(f));
nboot = 1000;
peak_boot = zeros(1, nboot);

for i =1:nboot
    % resampling
    r_boot = r(randi(length(r), 1, length(r)));
    f = ksdensity(r_boot, tbins, 'Bandwidth',bw, 'Function','pdf');
    peak_boot(i) =  tbins(f==max(f));
end

mode_ci = quantile(peak_boot, [0.025 0.975]);
mode_out = [peak, mode_ci];