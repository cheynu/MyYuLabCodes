function Stage = getStage(obj)
%GETSTAGE Summary of this function goes here
%   Detailed explanation goes here

IndNewStage = find(obj.Cued==0, 1, 'first');
Stage = zeros(length(obj.FP), 1);
Stage(IndNewStage:end) = 1;

end

