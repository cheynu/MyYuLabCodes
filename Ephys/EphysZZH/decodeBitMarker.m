function [trial_id, ind_head, fig_decode] = decodeBitMarker(tOn, tOff, varargin)

% Default params
% led bit code information
bit_len = 60; % ms
bit_num = 9; % number of bits used
% head information
head_on_dur  = 120; % ms
head_off_dur = 60; % ms
% sample rate
fs = 50; % ms
% plot decode result
sample_dur = [];
to_print = true;

if nargin>2
    for i=1:2:size(varargin,2)
        switch varargin{i}
            case 'bit_len'
                bit_len = varargin{i+1};
            case 'bit_num'
                bit_num = varargin{i+1};
            case 'head_on_dur'
                head_on_dur = varargin{i+1};
            case 'head_off_dur'
                head_off_dur = varargin{i+1};
            case 'fs'
                fs = varargin{i+1};
            case 'sample_dur'
                sample_dur = varargin{i+1};
            case 'to_plot'
                to_print = varargin{i+1};
            otherwise
                errordlg('unknown argument')
        end
    end
end

% led bit code information
bit_dur = bit_len*bit_num;

% head information
head_dur  = head_on_dur + head_off_dur;
head_code = [repmat('1', 1, head_on_dur/bit_len) repmat('0', 1, head_off_dur/bit_len)];
head_num  = length(head_code);

% entire signal information
signal_num = head_num + bit_num;
signal_dur = head_dur + bit_dur;

% exposure time
exposure_time = round(1000 / fs);

% tolerant duration, use this duration to check if the bitcode was around
% the start or end of the recording
tol_dur = signal_dur + 5*exposure_time;

if ~isempty(sample_dur)
    while tOn(1) < tol_dur
        tOn(abs(tOn-tOn(1))<tol_dur) = [];
    end
    while (sample_dur-tOn(end)) < tol_dur
        tOn(abs(tOn-tOn(end))<tol_dur) = [];
    end
end

% check signal from the first LED-on
trial_id = nan(length(tOn), 1); % set a larger initial container
ind_head = (1:length(tOn))';
i = 1;
while i < length(tOn)
    % find time of LED-on within signal duration
    t_on_follow = tOn(i:end) - tOn(i);
    t_on_follow = t_on_follow(t_on_follow<=signal_dur);

    % check if there is a bit sequence following, otherwise go to next LED-on
    if length(t_on_follow)<2
        i = i+1;
        continue;
    end

    % find time of LED-off within signal duration
    t_off_follow = tOff(tOff>tOn(i)) - tOn(i);
    t_off_follow = t_off_follow(t_off_follow<=head_dur+bit_dur+tol_dur); % include extra tolerant duration, in case of timestamp shift
    
    if length(t_on_follow)~=length(t_off_follow)
        i = i+1;
        continue;
    end

    % transfer time points to signal sequence
    entire_signal = zeros(1, signal_dur);
    t_signal   = 1:signal_dur;
    for j = 1:length(t_on_follow)
        entire_signal(t_signal>=t_on_follow(j) & t_signal<t_off_follow(j)+exposure_time) = 1;
    end

    % transfer signal sequence to bit code
    entire_code = zeros(1, signal_num);
    for j = 1:signal_num
        j_loc = (j-1)*bit_len + (1:bit_len);
        entire_code(j) = round(mean(entire_signal(j_loc)));
    end

    % check if there is a head code in front
    if any(num2str(entire_code(1:head_num), '%d') ~= head_code)
        i = i+1;
        continue;
    end

    % turn bit code to trial number
    bit_code = entire_code(head_num+1:end);
    i_trial  = bin2dec(num2str(bit_code, '%d'));

    trial_id(i) = i_trial;
    % go to next head
    i = i + length(t_on_follow);
end
ind_head(isnan(trial_id)) = [];
trial_id(isnan(trial_id)) = [];
tOn = tOn(ind_head);

% check decode results (trial diff ~= 1)
trial_diff = diff(trial_id);
shift_diff = find(trial_diff~=1) + 1;
shift_id   = shift_diff(diff(shift_diff)==1);

% plot decode results
fig_decode = figure(38); clf(38);
set(fig_decode, 'name', 'BitDecoding', 'units', 'centimeters', 'position', [5 3 7 5.5], 'PaperUnits', 'centimeters', 'PaperPosition', [5 3 7 5.5], 'visible', 'on');
ax_decode = axes(fig_decode, 'Units', 'centimeters', 'Position', [1.5 1.5 5 3.5], 'NextPlot', 'add', 'FontSize', 9, 'TickDir', 'out');
scatter(ax_decode, tOn/1000, trial_id, 16, 'blue', 'LineWidth', .5);
plot(ax_decode, tOn/1000, trial_id, '-b');
if ~isempty(shift_id)
    scatter(ax_decode, tOn(shift_id)/1000, trial_id(shift_id), 20, 'red', 'LineWidth', .5);
end
ylim(ax_decode, [0 max(trial_id)]);
xlabel(ax_decode, 'Time (s)');
ylabel(ax_decode, 'TrialID');

if to_print
    print_name = 'BitDecoding';
    print(fig_decode, '-dpng', print_name);
end

% remove shifted trials
trial_id(shift_id) = [];
ind_head(shift_id) = [];

end