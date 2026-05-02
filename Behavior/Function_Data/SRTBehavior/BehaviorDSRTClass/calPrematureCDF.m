function [cdf_out, integral_out] = calPrematureCDF(HT, FP, tbin, tmin)

tbins = (0:tbin:1.5+tmin);
cdf = zeros(1, length(tbins));

for k = 2:length(tbins)
    
    ind_counts = find(tbins(k)<=FP+tmin);

    n_total = 0; n_less = 0;
        
    for j = 1:length(ind_counts)
        jdata = HT(ind_counts(j));
        jdata_anticipatory = jdata(jdata<=tbins(k));
        
        n_total = n_total +length(jdata);
        n_less = n_less +length(jdata_anticipatory);
    end
    
    cdf(k) = n_less/n_total;
    
end

cdf_out = cdf';
integral_out = cumtrapz(tbins, cdf);

end