function [IndSort, IndInsignificant] = RankSDFWarpPooled(PopPool, thres)
% Jianing Yu 5/15/2023
% PopOut is population psth produce by Spikes.SRT.PopulationActivity.m
% 7/8/2023 modified 

if nargin<2
    thres = 0.75; % rank sdfs according to the time point firing rate cross 75% of max firing rate
end

nPort = 2;
n_unit = length(PopPool.stat.centin{1});

SDFs_Flat = cell(1, nPort);
IndMax = zeros(n_unit, nPort); % for 2 ports each
IndThres = zeros(n_unit, nPort); % for 2 ports each
SigMod = zeros(n_unit, nPort); % if 1, neural activity is significantly modulated at some points
pVal_critical = 0.05/2;
pVals = zeros(2, n_unit);

for j = 1:nPort
    for i = 1:n_unit
        SDF_CentIn = PopPool.sdf.centin{j}(i, :);
        pVals(1, i) = PopPool.stat.centin{j}.pval;

        SDF_Trigger = PopPool.sdf.trigger{j}(i, :);
        pVals(2, i) = PopPool.stat.trigger{j}.pval;

        SDF_Flat  = [SDF_CentIn SDF_Trigger];
        SDFs_Flat{j} = [SDFs_Flat{j}; SDF_Flat];

        [~, IndMax(i, j)] = max(SDF_Flat);
        if min(pVals(:, i)) < pVal_critical
            SigMod(i, j) = 1;
        end

        SDF_Flat_n = normalize(SDF_Flat, 2, 'range');
        id_thres = find(SDF_Flat_n>thres, 1, 'first');
        if ~isempty(id_thres)
            IndThres(i, j) = id_thres;
        else
            IndThres(i, j) = 0;
        end
    end
end

IndSort = cell(1, nPort);
IndInsignificant = cell(1, nPort);
for j = 1:nPort
    [~, IndSort{j}] = sort(IndThres(:, j));
    SigMod_j   = SigMod(IndSort{j}, j);
    IndSort{j} = [IndSort{j}(SigMod_j==1); IndSort{j}(SigMod_j==0)];
    SigMod_j   = [SigMod_j(SigMod_j==1); SigMod_j(SigMod_j==0)];
    IndInsignificant{j} = find(SigMod_j==0);
end
