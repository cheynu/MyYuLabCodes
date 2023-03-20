function r=CorrectBehaviorEphysMapping(r, kb)

% Jianing Yu 12/21/2022
% double check behavior data in r to make sure index is in order 

% get kornblum class or calculate it
if nargin<2
    kb =  KornblumClass;
end;

PressTimeR              =           r.Behavior.EventTimings(r.Behavior.EventMarkers == find(strcmp(r.Behavior.Labels, 'LeverPress')));
IndexPressR             =          [1:length(PressTimeR)];
PressTimeMED         =          kb.PressTime*1000;
IndexPressMED        =          kb.PressIndex;

% function Indout = findseqmatchrev(seqmom, seqson, man, toprint, toprintname, threshold)
IndMatched              =               findseqmatchrev(PressTimeMED, PressTimeR, 0, 1);
IndNotNan                =               find(~isnan(IndMatched));

if sum(isnan(IndMatched))>0
    disp('Found unmatched press event')
end;

IndexPressR            =             IndexPressR(IndNotNan);
IndexPressR2MED  =             IndexPressMED(IndMatched(IndNotNan));

r.Behavior.ReMapped.PressIndex =         IndexPressR; % this marks the press index 
r.Behavior.ReMapped.Outcome    =         kb.Outcome(IndexPressR2MED);
r.Behavior.ReMapped.FP              =         kb.FP(IndexPressR2MED);
r.Behavior.ReMapped.CueIndex   =         kb.Cue(IndexPressR2MED);
r.Behavior.ReMapped.DateOfRemapping = date;

% r.Behavior = rmfield(r.Behavior, 'Correctindex');
% r.Behavior = rmfield(r.Behavior, 'PrematureIndex');
% r.Behavior = rmfield(r.Behavior, 'DarkIndex');
% r.Behavior = rmfield(r.Behavior, 'Foreperiods');
% r.Behavior = rmfield(r.Behavior, 'CueIndex');

save('RArray.mat', 'r') 