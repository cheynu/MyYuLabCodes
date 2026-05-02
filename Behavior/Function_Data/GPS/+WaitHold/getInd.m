function ind = getInd(obj)
%GETIND Summary of this function goes here
%   Detailed explanation goes here
ind.portL       = obj.PortCorrect==1;
ind.portR       = obj.PortCorrect==2;

ind.short       = obj.Stage==1 & obj.FP==obj.MixedFP(1);
ind.med         = obj.Stage==1 & obj.FP==obj.MixedFP(2);
ind.long        = obj.Stage==1 & obj.FP==obj.MixedFP(3);

ind.correct     = strcmp(obj.Outcome, 'Correct');
ind.correctL    = ind.portL & ind.correct;
ind.correctR    = ind.portR & ind.correct;

ind.wrong       = strcmp(obj.Outcome, 'Wrong');
ind.wrongL      = ind.portL & ind.wrong;
ind.wrongR      = ind.portR & ind.wrong;

ind.late        = (strcmp(obj.Outcome, 'LateCorrect') | strcmp(obj.Outcome, 'LateWrong')  | strcmp(obj.Outcome, 'LateMiss') | strcmp(obj.Outcome, 'Late'));
ind.lateL       = ind.portL & ind.late;
ind.lateR       = ind.portR & ind.late;

ind.premature   = strcmp(obj.Outcome, 'Premature');
ind.prematureL  = ind.portL & ind.premature;
ind.prematureR  = ind.portR & ind.premature;

ind.hit         = (strcmp(obj.Outcome, 'Correct') | strcmp(obj.Outcome, 'LateCorrect'));
ind.hitL        = ind.portL & ind.hit;
ind.hitR        = ind.portR & ind.hit;

ind.off         = (strcmp(obj.Outcome, 'Wrong') | strcmp(obj.Outcome, 'LateWrong'));
ind.offL        = ind.portL & ind.off;
ind.offR        = ind.portR & ind.off;

end
