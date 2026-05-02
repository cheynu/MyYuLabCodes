function critical_pval = BH_method(allpvals, q, toplot)
% 5/1/2024 BH method to output critical p val to control false discovery
% rate
if nargin<3
    toplot = 0;
    if nargin<2
        q=0.05;
    end
end

allpvals_sort = sort(allpvals);
if size(allpvals_sort, 1)>1
    allpvals_sort = allpvals_sort';
end
% perform BH method to control FDR (false discovery rate)
ranks_q = q*(1:length(allpvals))/length(allpvals);

ind_below = find(allpvals_sort<ranks_q, 1, 'last');
crit_p = allpvals_sort(ind_below);

if toplot
    figure;
    plot(allpvals_sort, 'ko-');
    hold on
    plot(ranks_q, 'r.-');
    plot(ind_below, crit_p, 'c^', 'markersize', 10)
end
critical_pval = crit_p;