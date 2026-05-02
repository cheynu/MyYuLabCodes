function Stage = getStage(obj)
%GETSTAGE Summary of this function goes here
%   Detailed explanation goes here
IndNewStage = 1 + find(abs(diff(obj.FP))==0.5 | abs(diff(obj.FP))==1, 1, 'first');
Stage = zeros(length(obj.FP), 1);
Stage(IndNewStage:end) = 1;
end

