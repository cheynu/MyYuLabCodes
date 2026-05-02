function [StartTime,StopTime,Middle,Spread] = getPeakStartTime(response_times,trial_end_time)
% Calculate the start time and stop time
% Church, R.M., Meck, W.H., and Gibbon, J. (1994). Application of scalar timing theory to individual trials. Journal of Experimental Psychology: Animal Behavior Processes 20, 135–155. https://doi.org/10.1037/0097-7403.20.2.135.
%   "On each trial, the index that was maximized was t1(r-r1) + t2(r2 - r) + t3(r - r3), 
%   where t1, t2, and t3 were the times until s1, the time between s1 and s2, and the time from s2 
%   until the end of the trial, and r1, r2, and r3 were the mean response rates during the 
%   corresponding three time periods during the trial, and r was the overall mean response rate on 
%   the trial. The index was calculated with s1 at the time of each of the responses, except the last,
%   and s2 at each subsequent response (r1 included the response at s1, r2 included the response at 
%   s2, and r3 included a hypothetical response at the end of the trial)."
% Input:
%   response_times: 1xn vector, time points of every responses (>0, align to lever-press)
%   trial_end_time: generally it's 3*target_delay, e.g., 15 s for 5 s delay probe trial
% Output:
%   StartTime:  time of beginning to respond
%   StopTime:   time of stopping response
%   Middle:     middle of the high-responding state
%   Spread:     duration of responding

arguments
    response_times 
    trial_end_time 
end
response_times = response_times(response_times>0 & response_times<trial_end_time);
%% Traversal algorithm
% Initialize variables to store the results
StartTime = NaN;
StopTime = NaN;
maxFunctionValue = 0;

nResp = length(response_times);
for iResp=2:nResp-2
    for jResp=iResp+1:nResp-1
        S1 = response_times(iResp);
        S2 = response_times(jResp);
        t1 = S1-0;
        t2 = S2-S1;
        t3 = trial_end_time-S2;
        r1 = iResp/t1; % first response to S1
        r2 = (jResp-iResp)/t2; % S1+1 response to S2
        r3 = (nResp-jResp+1)/t3; % S2+1 response to last + 1 hypothetical resposne
        r  = nResp/trial_end_time;
        functionValue = t1*(r-r1) + t2*(r2 - r) + t3*(r - r3);
        if functionValue>maxFunctionValue
            maxFunctionValue = functionValue;
            StartTime = S1;
            StopTime = S2;
        end
    end
end
Middle = (StartTime+StopTime)/2;
Spread = StopTime-StartTime;
end

