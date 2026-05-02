function Ind = getProgressInd(obj)
%GETINDPROGRESS Summary of this function goes here
%   Detailed explanation goes here
Behav = obj.BehavTable;

Ind.portL       = Behav.PortCorrect==1;
Ind.portR       = Behav.PortCorrect==2;

Ind.correct     = strcmp(Behav.Outcome, 'Correct');
Ind.correctL    = Ind.portL & Ind.correct;
Ind.correctR    = Ind.portR & Ind.correct;

Ind.wrong       = strcmp(Behav.Outcome, 'Wrong');
Ind.wrongL      = Ind.portL & Ind.wrong;
Ind.wrongR      = Ind.portR & Ind.wrong;

Ind = struct2table(Ind);

end
