function ind = getInd(obj)
%GETIND Summary of this function goes here
%   Detailed explanation goes here
ind.portL       = obj.PortCorrect==1;
ind.portR       = obj.PortCorrect==2;

ind.cue         = obj.Stage==1 & obj.Cued==1;
ind.uncue       = obj.Stage==1 & obj.Cued==0;

ind.correct     = strcmp(obj.Outcome, 'Correct');
ind.correctL    = ind.portL & ind.correct;
ind.correctR    = ind.portR & ind.correct;

ind.wrong       = strcmp(obj.Outcome, 'Wrong');
ind.wrongL      = ind.portL & ind.wrong;
ind.wrongR      = ind.portR & ind.wrong;

ind.late        = strcmp(obj.Outcome, 'LateCorrect') | strcmp(obj.Outcome, 'LateWrong') | strcmp(obj.Outcome, 'LateMiss') | strcmp(obj.Outcome, 'Late');
ind.lateL       = ind.portL & ind.late;
ind.lateR       = ind.portR & ind.late;

ind.premature   = strcmp(obj.Outcome, 'Premature');
ind.prematureL  = ind.portL & ind.premature;
ind.prematureR  = ind.portR & ind.premature;

ind.valid       = ind.correct & ind.wrong;
ind.validL      = ind.correctL & ind.wrongL;
ind.validR      = ind.correctR & ind.wrongR;

end
