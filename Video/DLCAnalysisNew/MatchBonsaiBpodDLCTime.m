function IndOut = MatchBonsaiBpodDLCTime(Bpod_Softcode, Bonsai_TriggerTime);

% Jianing Yu 3/30/2022
% Compare softcode time recorded in Bpod (softcode) with Bonsai's trigger
% time (manually curated)

if size(Bonsai_TriggerTime, 1)>1
    Bonsai_TriggerTime = Bonsai_TriggerTime';
end;

IndOut = NaN*ones(size(Bonsai_TriggerTime));

minITI = 2; % minimal 1 s

% Pick out events that are widely spaced. Only use these to do sequence matching 
IndSpacedEnough = [1 find(diff(Bonsai_TriggerTime)>1)+1];
IndSpacedSmall    = setdiff([1:length(Bonsai_TriggerTime)], IndSpacedEnough);

sprintf('Use %2.2f %% of Bonsai trigger time', length(IndSpacedEnough)/length(Bonsai_TriggerTime));

Bonsai_TriggerTime_Subset = Bonsai_TriggerTime(IndSpacedEnough);

% Sequence matching
IndBonsaiSubset = findseqmatchrev(Bpod_Softcode, Bonsai_TriggerTime_Subset, 0, 1, 'MatchingSoftCodeWithBonsai');
% This is essentially what IndOut(IndSpacedEnough) are 

Matched_IndBonsaiSubset = find(~isnan(IndBonsaiSubset));

% These are successful matched events

IndSpacedEnough_Matched = IndSpacedEnough(Matched_IndBonsaiSubset); % this is index (in bonsai)
Bonsai_SpacedEnough_Matched = Bonsai_TriggerTime(IndSpacedEnough_Matched); % this is time
BonsaiToBpodInd_SpacedEnough_Matched = Bpod_Softcode(IndBonsaiSubset(Matched_IndBonsaiSubset)); % this is time (bpod)


% Fill up IndSpacedSmall
minDist = zeros(1, length(IndSpacedSmall));
Bonsai2BpodSpacedSmall = zeros(1, length(IndSpacedSmall));

for i = 1:length(minDist)
    itSmall = Bonsai_TriggerTime(IndSpacedSmall(i));

    % nearest match
    [minDist(i), indNearest]=(min(abs(itSmall - Bonsai_SpacedEnough_Matched)));
    Bonsai2BpodSpacedSmall(i) = itSmall-Bonsai_SpacedEnough_Matched(indNearest)+BonsaiToBpodInd_SpacedEnough_Matched(indNearest);

end;

figure;
plot(minDist,'ko')


figure