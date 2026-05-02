function tLEDon = FindLEDonAuto(tsROI, SummedROI, name)
% Jianing Yu
% 4/27/2021
% Track the change in ROI intensity to judge when LED is on
if nargin<3
     name = [];
end
if size(SummedROI, 1)==1
    led =SummedROI';
else
    led = SummedROI;
end

if size(tsROI, 1) ==1
    tsROI = tsROI';
end

figure(14); clf(14)
set(gcf, 'name', 'ROI dynamics', 'units', 'centimeters', 'position', [15 5 25 15], 'Visible', 'on')
led = detrend(led);
led = led-median(led);
SROI_filt = led;
ha1= subplot(2, 2 ,1);
set(ha1, 'nextplot', 'add');
plot(tsROI, SROI_filt, 'k');
axis tight

% dete
% Automatically determine height threshold
[pks, ~] = findpeaks(SROI_filt); % Detect all peaks
baseline = median(pks);
threshold = mean(pks) + 2.5 * std(pks); % Set height threshold based on mean + 1.5*std
% Detect large peaks using the calculated height threshold
% min separation should be 1 second, that is, 100 frames
[large_peaks, large_locs] = findpeaks(SROI_filt, 'MinPeakHeight', threshold, 'MinPeakDistance', 100);
% there might still be errors, try to identify them
ind_outliers = isoutlier(large_peaks, 'ThresholdFactor',10);
if sum(ind_outliers)>0    
    large_peaks(ind_outliers)       =         [];
    large_locs(ind_outliers)          =         [];
end
% plot(tsROI(large_locs), large_peaks, 'ro', 'markersize', 10, 'markerfacecolor', 'r');

% get rid of 
ha2=subplot(2, 2, [3]);
set(ha2, 'nextplot', 'add', 'yscale', 'log');
histogram(large_peaks, 10);
axis 'auto y'

% find begs
onsets = large_locs;

onsets = NaN*ones(1, length(onsets));
offsets = NaN*ones(1, length(onsets));
durations =  zeros(1, length(onsets));

for k = 1:length(large_peaks)
    k_beg   = large_locs(k);
    this_peak = large_peaks(k);
    % find when the signal goes down
    this_beg   = find(SROI_filt<0.5*(this_peak+baseline)&tsROI<tsROI(k_beg), 1, 'last');
    this_end   = find(SROI_filt<0.5*(this_peak+baseline)&tsROI>tsROI(k_beg), 1, 'first');
    if ~isempty(this_beg)
        onsets(k) = this_beg;
    end

    if ~isempty(this_end)
        offsets(k) = this_end;
    end
    disp(k)
    disp([this_beg this_end])
    if ~isempty(this_end) && ~isempty(this_beg)
    durations(k)=this_end-this_beg;
    else
    durations(k) = NaN;
    end
end

% get rid of nans
is_nans = (isnan(onsets) | isnan(offsets));
onsets(is_nans) = [];
offsets(is_nans) = [];
durations(is_nans) = [];
large_peaks(is_nans) =[];

plot(ha1, tsROI(onsets), led(onsets), 'go', 'markerfacecolor', 'g');
plot(ha1, tsROI(offsets), led(offsets), 'b^', 'markerfacecolor', 'b');

% check the duration of these LED on periods
ha3=subplot(2, 2, [2]);
dur_log = (durations);
set(ha3, 'nextplot', 'add', 'xscale', 'linear')
plot(dur_log, large_peaks, 'ko')
title('Select multiple points for decision boundary')
xlabel('Num of frames (interval 10 or 20 ms)')
ylabel('Amp')
set(ha3, 'xlim', [0 50])
clc;
% remove "bad" ROIs
disp('Select mulitple points to define a decision boundary, end selection by right click')
[x_thrh, y_thrh] = getpts(ha3);
plot(ha3, x_thrh, y_thrh, 'bx');
tbl = table(x_thrh(1:end-1), y_thrh(1:end-1));
lm = fitlm(tbl, 'linear'); % y = ax + b
ypredict = predict(lm, dur_log');
[above_sort, indsort] = sort(dur_log);
plot(above_sort, ypredict(indsort), 'Color','m');

% find those that are above this line
ind_good = find(large_peaks > ypredict);
falseindex_LEDon = find(large_peaks < ypredict);
plot(dur_log(ind_good), large_peaks(ind_good), 'g+', 'linewidth', 2)
axis tight

if ~isempty(falseindex_LEDon)
    axes(ha1)
    plot(tsROI(onsets(falseindex_LEDon)), led(onsets(falseindex_LEDon)), 'r*', 'markersize', 8);
end

if onsets(1) == 1
    falseindex_LEDon = [1; falseindex_LEDon];
end

if offsets(end) == length(tsROI)
    falseindex_LEDon = [falseindex_LEDon; length(offsets)];
end
onsets(falseindex_LEDon)         = [];
offsets(falseindex_LEDon)         = [];
durations(falseindex_LEDon)            = [];

% empirically, push the onset time by one frame
ha4=subplot(2, 2, [4]);
set(ha4, 'nextplot', 'add', 'xlim', [-1 5]);
abv_seg =[];

for j =1:length(onsets)
    if onsets(j)-3 >= 1
        abv_seg{j} = led(onsets(j)-3:offsets(j));
        tseg = [0:length(abv_seg{j})-1]-3;
        plot(ha1,tsROI(onsets(j)-3:offsets(j)), abv_seg{j}, 'g')
    else
        abv_seg{j} = led(onsets(j):offsets(j));
        tseg = [0:length(abv_seg{j})-1];
        plot(ha1,tsROI(onsets(j):offsets(j)), abv_seg{j}, 'g')
    end;
    plot(ha4, tseg, abv_seg{j}, 'k');
end

xlabel('Frames')
ylabel('ROI')

tLEDon = tsROI(onsets);

print (gcf,'-dpng', ['ROI_LEDon' name]);