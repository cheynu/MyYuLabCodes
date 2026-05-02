function Ind = getProgressInd(obj)
%GETINDPROGRESS Summary of this function goes here
%   Detailed explanation goes here
Behav = obj.BehavTable;

Ind.portL       = Behav.PortCorrect==1;
Ind.portR       = Behav.PortCorrect==2;

Ind.cue         = Behav.Stage==1 & Behav.Cued==1;
Ind.uncue       = Behav.Stage==1 & Behav.Cued==0;

Ind.correct     = strcmp(Behav.Outcome, 'Correct');
Ind.correctL    = Ind.portL & Ind.correct;
Ind.correctR    = Ind.portR & Ind.correct;

Ind.wrong       = strcmp(Behav.Outcome, 'Wrong');
Ind.wrongL      = Ind.portL & Ind.wrong;
Ind.wrongR      = Ind.portR & Ind.wrong;

Ind.late        = strcmp(Behav.Outcome, 'LateCorrect') | strcmp(Behav.Outcome, 'LateWrong') | strcmp(Behav.Outcome, 'LateMiss') | strcmp(Behav.Outcome, 'Late');
Ind.lateL       = Ind.portL & Ind.late;
Ind.lateR       = Ind.portR & Ind.late;

Ind.premature   = strcmp(Behav.Outcome, 'Premature');
Ind.prematureL  = Ind.portL & Ind.premature;
Ind.prematureR  = Ind.portR & Ind.premature;

Ind = struct2table(Ind);

end
