function [pdf_out, cdf_out, hold_time, tbins, response]= calPDF(hold_time, FP, bins, response_win)

if nargin<4
    response_win = 0.6;
end

if FP>20
    FP = FP/1000; % FP's unit is second
end

nFP      = 1;
tAnticipatory= 0.1; % any response less than 0.1 sec is anticipatory ones
N_std = 8; % remove any points greater than N_std of the mean

% a few parameters
response.ComputingTypes = {'mean', 'median', 'mode', 'iqr'};
response.RT_Types = {'strict', 'loose'};
response.RT = zeros(length(response.ComputingTypes), length(response.RT_Types));
response.HoldT = zeros(length(response.ComputingTypes), nFP);

% Proportion of anticipatory responses, defined as premature responses and
% those with a RT less than tAnti (e.g., 0.1 sec)
response.AnticipatoryResponses = sum(hold_time<FP+tAnticipatory)/length(hold_time);

% Remove extremely long responses
hold_time(hold_time>mean(hold_time)+N_std*std(hold_time)) = [];

% Compute PDF and CDF
pdf_out = ksdensity(hold_time, bins,'function', 'pdf');
cdf_out = ksdensity(hold_time, bins,'function', 'cdf');

% Compute RT
RTs_strict = hold_time(hold_time>FP+tAnticipatory & hold_time<FP+response_win)-FP;
RTs_loose  = hold_time(hold_time>FP+tAnticipatory)-FP;

response.RT(1, 1) = mean(RTs_strict); % this is the average, strict reaction time
response.RT(2, 1) = mean(RTs_strict); % this is the average, strict reaction time
response.RT(3, 1) = NaN; % this is the average, strict reaction time
response.RT(4, 1) = diff(prctile(RTs_strict, [25 75])); % this is the average, strict reaction time

response.RT(1, 2) = median(RTs_loose); % this is the average, strict reaction time
response.RT(2, 2) = median(RTs_loose); % this is the average, strict reaction time
response.RT(3, 2) = NaN; % this is the average, strict reaction time
response.RT(4, 2) = diff(prctile(RTs_loose, [25 75])); % this is the average, strict reaction time

response.HoldT(1) = mean(hold_time); % this is the average
response.HoldT(2) = median(hold_time); % this is the median
response.HoldT(3) = find_mode(bins, pdf_out); % this is the peak
response.HoldT(4) = diff(prctile(hold_time, [25 75]));

% Plot hold time distribution and mode
hf2 = 32;
figure(hf2)
clf(hf2)
set(hf2, 'Visible', 'on')
plot(bins, pdf_out, 'k', 'linewidth', 1);
hold on
line([response.HoldT(3) response.HoldT(3)], [0 max(pdf_out)], 'color', 'm', 'linestyle', ':', 'linewidth', 2)
text(response.HoldT(2) ,  1*max(pdf_out), 'mode', 'color', 'm')

line([response.HoldT(2) response.HoldT(2)], [0 max(pdf_out)], 'color', 'c', 'linestyle', ':', 'linewidth', 2)
text(response.HoldT(2) , 0.25*max(pdf_out), 'median' , 'color', 'c')

pause(0.1)
tbins = bins;

end


function rt_out = find_mode(bins, pdf)    
    
    rt_out = bins(pdf==max(pdf));

 
end