function    [f,  f_ci, xi, cdf, cdf_ci] = ksdensity_ci(press_durs, xbins,kernel_bw, nboot);
% Jianing Yu
% 11/17/2023
[f, xi]=ksdensity(press_durs, xbins, 'Bandwidth',kernel_bw);
[cdf, xi]=ksdensity(press_durs, xbins, 'Bandwidth',kernel_bw, 'function','cdf');
f_boots = zeros(nboot, length(xbins));
cdf_boots = zeros(nboot, length(xbins));

nsample = length(press_durs);
tic
for ii =1:nboot
    press_durs_boot = press_durs(randi(nsample, 1, nsample));
    [f, xi]=ksdensity(press_durs_boot, xbins, 'Bandwidth',kernel_bw);
    f_boots(ii, :) = f;    
    [cdf, xi]=ksdensity(press_durs_boot, xbins, 'Bandwidth',kernel_bw, 'function','cdf');
    cdf_boots(ii, :) = cdf;
end

toc;
f_ci = quantile(f_boots, [0.025 0.975]);
cdf_ci = quantile(cdf_boots, [0.025 0.975]);

end