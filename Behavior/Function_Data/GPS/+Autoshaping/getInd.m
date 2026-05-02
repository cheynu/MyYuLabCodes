function ind = getInd(obj)
%GETIND Summary of this function goes here
%   Detailed explanation goes here
ind.portL       = obj.PortCorrect==1;
ind.portR       = obj.PortCorrect==2;

ind.correct     = strcmp(obj.Outcome, 'Correct');
ind.correctL    = ind.portL & ind.correct;
ind.correctR    = ind.portR & ind.correct;

ind.wrong       = strcmp(obj.Outcome, 'Wrong');
ind.wrongL      = ind.portL & ind.wrong;
ind.wrongR      = ind.portR & ind.wrong;

ind.late        = zeros(obj.NumTrials, 1);
ind.lateL       = zeros(obj.NumTrials, 1);
ind.lateR       = zeros(obj.NumTrials, 1);

ind.premature   = zeros(obj.NumTrials, 1);
ind.prematureL  = zeros(obj.NumTrials, 1);
ind.prematureR  = zeros(obj.NumTrials, 1);

end
