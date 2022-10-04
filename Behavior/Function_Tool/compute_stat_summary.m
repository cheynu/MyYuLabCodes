function [out] = compute_stat_summary(vector,method)
% _________________________________________________________________________
% File:               compute_stat_summary.m
% Created on:         Oct 2, 2021
% Created by:         Yu Chen
% Last revised on:    OCt 2, 2021
% Last revised by:    Yu Chen
% _________________________________________________________________________
vector = vector(~isnan(vector));
    switch method
        case 'mean-std'
            tendency = mean(vector);
            dispersion = std(vector);
            lower = tendency - dispersion;
            upper = tendency + dispersion;
            out = [tendency;lower;upper];
        case 'mean-sem'
            tendency = mean(vector);
            dispersion = std(vector)./sqrt(length(vector));
            lower = tendency - dispersion;
            upper = tendency + dispersion;
            out = [tendency;lower;upper];
        case 'quartile'
            tendency = median(vector);
            quartile = [quantile(vector, 0.25); quantile(vector,0.75)];
            out = [tendency; quartile];
        case 'mean-bootci'
            tendency = mean(vector);
            ci95 = bootci(1000,{@(x) mean(x), vector},'Alpha',0.05);
            out = [tendency;ci95];
        case 'geomean-geomad' % (Narayanan & Laubach,2006)
            vector = vector(vector>0);
            tendency = geomean(vector);
            dispersion = mean(abs(vector - (vector.*0 + tendency)));%geometric mean absolute deviation
            lower = tendency - dispersion;
            upper = tendency + dispersion;
            out = [tendency;lower;upper];
        case 'geomean-bootci'
            vector = vector(vector>0);
            tendency = geomean(vector);
            ci95 = bootci(1000,{@(x) geomean(x), vector},'Alpha',0.05);
            out = [tendency;ci95];
        otherwise % default is mean-std
            tendency = mean(vector);
            dispersion = std(vector);
            lower = tendency - dispersion;
            upper = tendency + dispersion;
            out = [tendency;lower;upper];
    end
end