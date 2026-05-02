function gout = Gfunction(datain, FPs, options)
% Jianing Yu 7/14/2024
% the term G function comes from Ollman and Billington 1972
% datain: cell array containing response time from each FP
% FPs: foreperiods, same number of elements as datain

arguments
    datain
    FPs
    options.toplot = false
end
toplot = options.toplot;

tbin = 0.01;
tmin = 0.1; % minimal response time is 0.1 second, anything before FP+timin is considered an anticipatory response
tbins = (0:tbin:FPs(end)+0.1);
cdf = zeros(1, length(tbins));

for k =2:length(tbins)
    
    ind_counts = find(tbins(k)<FPs+tmin);
   
    n_total = 0;
    n_less = 0;
        
    for j =1:length(ind_counts)
        jFP = FPs(ind_counts(j));
        jdata = datain{ind_counts(j)};
        jdata_anticipatory = jdata(jdata<=tbins(k));
        
        n_total = n_total +length(jdata);
        n_less = n_less +length(jdata_anticipatory);
    end
    
    cdf(k) = n_less/n_total;
    
end

gout = [tbins' cdf'];

if toplot
    plot(gout(:, 1), gout(:, 2));
end