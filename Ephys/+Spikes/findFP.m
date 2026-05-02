function FPs = findFP(r)

allFPs = r.Behavior.Foreperiods;

uniqueFPs = unique(allFPs);
n_unique = zeros(1, length(uniqueFPs));

for i =1:length(uniqueFPs)
    n_unique(i) = sum(allFPs==uniqueFPs(i));
end

if length(n_unique)>2
    ids =  kmeans(n_unique', 2); % one cluster for warm-up, one for regular
    if sum(n_unique(ids==2))>sum(n_unique(ids==1))
        FPs = uniqueFPs(ids==2);
    else
        FPs = uniqueFPs(ids==1);
    end
else
    FPs = uniqueFPs;
end

if size(FPs, 2)<size(FPs, 1)
    FPs = FPs';
end
