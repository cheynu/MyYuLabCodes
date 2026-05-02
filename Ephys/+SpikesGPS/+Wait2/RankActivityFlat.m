function [IndSort, IndInsignificant] = RankActivityFlat(PopOut, thres)
% Jianing Yu 5/15/2023
% PopOut is population psth produce by Spikes.SRT.PopulationActivity.m
% 7/8/2023 modified 

if nargin<2
    thres = 0.75;
end

FPs = PopOut.FPs;
nPort = length(PopOut.Ports);
n_unit = size(PopOut.Units, 1);
FPindx = length(FPs);
n_events = 3; % cent-in, cent-out, reward

CentInTimeRange  = [-2000, FPs(FPindx)*1000];
CentOutTimeRange = [-500 1000];
RewardTimeRange  = [-1000 2000];

PSTHs_Flat = cell(1, nPort);
IndMax = zeros(n_unit, nPort); % for 2 ports each
IndThres = zeros(n_unit, nPort); % for 2 ports each
SigMod = zeros(n_unit, nPort); % if 1, neural activity is significantly modulated at some points
pVal_critical = 0.05/3;
pVals = zeros(n_events, n_unit);

for j = 1:nPort
    for i = 1:n_unit
        tCentIn = PopOut.CentIn{FPindx, j}(1, :);
        PSTH_CentIn = PopOut.CentIn{FPindx, j}(i+1, :);
        IndCentIn   = find(tCentIn>=CentInTimeRange(1) & tCentIn<=CentInTimeRange(2));
        pVals(1, i) = PopOut.CentInStat{FPindx, j}.StatOut(i).pval;

        tCentOut = PopOut.CentOut{FPindx, j}(1, :);
        PSTH_CentOut = PopOut.CentOut{FPindx, j}(i+1, :);
        IndCentOut   = find(tCentOut>=CentOutTimeRange(1) & tCentOut<=CentOutTimeRange(2));
        pVals(2, i)  = PopOut.CentOutStat{FPindx, j}.StatOut(i).pval;

        tReward = PopOut.Reward{FPindx, j}(1, :);
        PSTH_Reward = PopOut.Reward{FPindx, j}(i+1, :);
        IndReward   = find(tReward>=RewardTimeRange(1) & tReward<=RewardTimeRange(2));
        pVals(3, i) = PopOut.RewardStat{FPindx, j}.StatOut(i).pval;

        PSTH_Flat  = [PSTH_CentIn(IndCentIn) PSTH_CentOut(IndCentOut) PSTH_Reward(IndReward)];
        PSTHs_Flat{j} = [PSTHs_Flat{j}; PSTH_Flat];

        [~, IndMax(i, j)] = max(PSTH_Flat);
        if min(pVals(:, i))<pVal_critical
            SigMod(i, j) = 1;
        end

        PSTH_Flat_n = normalize(PSTH_Flat, 2, 'range');
        id_thres = find(PSTH_Flat_n>thres, 1, 'first');
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
