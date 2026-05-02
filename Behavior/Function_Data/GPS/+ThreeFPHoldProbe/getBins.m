function bins = getBins()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

bins.width          = .002;
bins.RT             = 0:bins.width:2;
bins.MovementTime   = 0:bins.width:2;
bins.HoldDuration   = 0:bins.width:2.5;
bins.ShuttleTimeLog = 0:bins.width:3;
bins.ChoiceTime     = 0:bins.width:2.5;

bins.widthInter     = 0.02;
bins.Interruption   = 0:bins.widthInter:1.5;

end

