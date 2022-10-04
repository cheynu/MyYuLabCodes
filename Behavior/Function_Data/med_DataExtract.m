function bt = med_DataExtract(filename,plotmark,path_arc)
% _________________________________________________________________________
% File:               med_DataExtract.m
% Created on:         Sept 25, 2021
% Created by:         Yu Chen
% Last revised on:    Mar 15, 2022
% Last revised by:    Yu Chen
% _________________________________________________________________________
% Required Functions:
%   med_to_tec_new
%   med_to_protocol
%   med_to_tec_fp
% _________________________________________________________________________
%% Derived from track_training_progress_advanced.m by Jianing Yu
% Add the output of table format
% Add the FPs & RWs information in Wait1&2 by computing according to rule (verified by events)
% Add an alternative data output format - table: each row is a press event & its corresponding parameters
% Add an alternative raw data plot - scatterhistogram
% Fix the bug that RT data mismatch

% event code in Time_event:
% 12: house light on
% 22: house light off
% 14: lever out
% 24: lever in
% 15: lever light on
% 25: lever light off
%  1: lever press
%  4: lever release
% 18: reward TTL on
% 28: reward TTL off
% 11: tone on
% 21: tone off
% 50: premature release
% 51: late release
%% 
switch nargin
    case 1
        plotmark = [1,0];
        path_arc = pwd;
    case 2
        if plotmark
            plotmark = [1,0];
            path_arc = pwd;
        else
            plotmark = [0,0];
            path_arc = pwd;
        end
    case 3
        if plotmark
            plotmark = [1,0];
        else
            plotmark = [0,0];
        end
        if ~isfolder(path_arc)
            path_arc = pwd;
        end
    otherwise
        assert(false,'Input variable number is not suitable.');
end
session_name = string(strrep(filename(1:end-4), '_', '-'));
Time_events = med_to_tec_new(filename, 100);
metadata = med_to_protocol(filename);
session_date = str2double(metadata.Date);

fig_path = fullfile(path_arc,'ProgFig',metadata.SubjectName);
if any(plotmark)
    if ~exist(fig_path,'dir')
        mkdir(fig_path);
    end
end

%% find out press-time & release-time
% time of presses
ind_leverpress = find(Time_events(:, 2)==1);
time_leverpress = Time_events(ind_leverpress, 1);
% time of releases
ind_leverrelease =find(Time_events(:, 2)==4);
time_leverrelease = Time_events(ind_leverrelease, 1);
% exclude the final release that was not registered before the session ended
% some situations: num of releases are more than presses
if length(time_leverrelease)~=length(time_leverpress)
    pressNum = min(length(time_leverpress),length(time_leverrelease));
    ind_leverpress  = ind_leverpress(1:pressNum);
    time_leverpress = time_leverpress(1:pressNum);
    ind_leverrelease = ind_leverrelease(1:pressNum);
    time_leverrelease = time_leverrelease(1:pressNum);
end
n_leverpress = length(ind_leverpress);
n_leverrelease = length(ind_leverrelease);
% press duration for each press, in ms
press_durs = (time_leverrelease-time_leverpress).*1000;

% event_matrix:
% 1-pressTime,2-releaseTime,3-pressDur,4-pressType,5-toneTime,6-FP,7-RW,8-RT,9-trial#
event_matrix = [time_leverpress,time_leverrelease,press_durs.*0.001];
event_matrix(:,4) = NaN;%Press&ReleaseType,1:Correct,-1:Premature,-2:Late,0:Dark(inter-trial)
%% Classify presses & releases
% correct(reward)
if ~isempty(find(Time_events(:, 2)==13, 1))
    time_reward = Time_events(Time_events(:, 2)==13, 1);
else
    time_reward = Time_events(Time_events(:, 2)==18, 1);
end
[~, ind_correct_release] = intersect(time_leverrelease, time_reward);
event_matrix(ind_correct_release,4) = 1;
ind_bad_release = setdiff(1:n_leverrelease, ind_correct_release);

% premature
time_premature = Time_events(Time_events(:, 2)==50, 1);
[~, ind_premature_release] = intersect(time_leverrelease, time_premature);
event_matrix(ind_premature_release,4) = -1;

% late
time_late = Time_events(Time_events(:, 2)==51, 1); %the time of late_error z pulse(the end of the response window)
ind_late_release = [];
for i = 1 : length(time_late)
   ind_late_release = [ind_late_release; find((time_leverpress-time_late(i)).*(time_leverrelease-time_late(i))<=0)];
end
event_matrix(ind_late_release,4) = -2;

% dark(inter-trial)
time_leverlighton = Time_events(Time_events(:, 2)==15, 1);% lever-light-on time
time_leverlightoff = Time_events(Time_events(:, 2)==25, 1);% lever-light-off time

ind_inter_trial_press = [];
for i=1:length(ind_bad_release)
    recent_lighton  = time_leverlighton(find(time_leverlighton < time_leverpress(ind_bad_release(i)), 1, 'last'));
    recent_lightoff = time_leverlightoff(find(time_leverlightoff < time_leverpress(ind_bad_release(i)), 1, 'last'));
    if ~isempty(recent_lighton) && ~isempty(recent_lightoff) && recent_lightoff > recent_lighton
        ind_inter_trial_press=[ind_inter_trial_press;ind_bad_release(i)];
    end
end
bigamyDark = intersect(ind_inter_trial_press,find(~isnan(event_matrix(:,4))));
if ~isnan(bigamyDark)
    locname = string(metadata.SubjectName) + ' ' + string(metadata.Date) + ' Bigamy Dark index';
    display(bigamyDark',char(locname));
    ind_inter_trial_press = setdiff(ind_inter_trial_press,bigamyDark);
end
event_matrix(ind_inter_trial_press,4) = 0;
orphan_press = find(isnan(event_matrix(:,4)));
if ~isempty(orphan_press)
    event_matrix(orphan_press,4) = 0;
    ind_inter_trial_press = sort([ind_inter_trial_press; orphan_press],'ascend');
    orphan_name = string(metadata.SubjectName) + ' ' + string(metadata.Date) + ' Orphan Press #';
    display(orphan_press, char(orphan_name));
end
%% Compute FP & RW
% record time of tone
time_tone = Time_events(Time_events(:, 2)==11, 1);
event_matrix(:,5) = NaN; % for tone
ind_trial_tone = find(event_matrix(:,4)==1|event_matrix(:,4)==-2);
ind_tone_late = event_matrix(ind_trial_tone,4) == -2;
time_tone = time_tone(1:length(ind_trial_tone)); % sometimes the last one is redundant
event_matrix(ind_trial_tone,5) = time_tone;

event_matrix(:,[6,7]) = NaN; % for foreperiod & response window
ind_iTrial = find(event_matrix(:,4)~=0);
trial_outcome = event_matrix(ind_iTrial,4);

protocol_underl = strfind(metadata.ProtocolName,'_');
% protocol_name = metadata.ProtocolName(protocol_underl(end)+1:end);
protocol_name = metadata.ProtocolName(protocol_underl(3)+1:end);
FPs = [];
RWs = [];
switch protocol_name
    case 'Wait1Bpod'
        RW_exe = 2;
        FP_cal = 0.5;
        FP_exe = FP_cal;
        FP_end = 1.5;
        consec_cor = 0;
        consec_pre = 0;
        FP_debug = [];
        for i=1:length(trial_outcome)
            if i == length(trial_outcome)
                inter_recent = ind_iTrial(i)+1 : n_leverrelease;
            else
                inter_recent = ind_iTrial(i)+1 : ind_iTrial(i+1)-1;
            end
            n_chunk = 1 + length(inter_recent);
            FP_debug = [FP_debug; FP_exe];
            FPs = [FPs;repelem(FP_exe,n_chunk)'.*1000];
            RWs = [RWs;repelem(RW_exe,n_chunk)'.*1000];
            if trial_outcome(i)>0 %current outcome
                consec_cor = consec_cor + 1;
                consec_pre = 0;
            else
                consec_pre = consec_pre + 1;
                consec_cor = 0;
            end
            if consec_cor>3 && FP_cal<FP_end %adjust FP
                FP_cal = FP_cal + 0.1;
                FP_exe = FP_cal;
                consec_cor = 0;
            elseif consec_pre>=10 && FP_cal>=0.1
                FP_cal = FP_cal - 0.1;
                if session_date>=20210927 % fix the bug on this day
                    FP_exe = FP_cal; % Med-PC code forget to update, lacking this line
                end
                consec_pre = 0;
            end
        end
        event_matrix(:,[6,7]) = [FPs,RWs].*0.001; % s
        % verification FP
        FP_calculated = round(event_matrix(ind_trial_tone,6),3);
        FP_recorded = round(time_tone - event_matrix(ind_trial_tone,1),3); % reserve 3 decimal fraction
        FP_contrast = table(FP_recorded,FP_calculated,'VariableNames',{'FP_recorded','FP_calculated'});
        wrongFP = ind_trial_tone(FP_recorded~=FP_calculated);
        if ~isempty(wrongFP)
            locname = string(metadata.SubjectName) + ' ' + string(metadata.Date) + ' Mismatch FP index';
            display(wrongFP,char(locname));
        end
    case 'Wait2Bpod'
        RW_exe = 2;
        if session_date>=20210927
            RW_end = 0.6;
        else
            RW_end = 0.7;
        end
        FP_exe = 0.5;
        FP_end = 1.5;
        consec_cor = 0;
        consec_pre = 0;
        accum_cor = 0;
        accum_late = 0;
        FP_debug = [];
        for i=1:length(trial_outcome)
            if i == length(trial_outcome)
                inter_recent = ind_iTrial(i)+1 : n_leverrelease;
            else
                inter_recent = ind_iTrial(i)+1 : ind_iTrial(i+1)-1;
            end
            n_chunk = 1 + length(inter_recent);
            FP_debug = [FP_debug; FP_exe];
            FPs = [FPs;repelem(FP_exe,n_chunk)'.*1000];
            RWs = [RWs;repelem(RW_exe,n_chunk)'.*1000];
            if trial_outcome(i) > 0 %current outcome
                consec_cor = consec_cor + 1;
                accum_cor = accum_cor + 1;
                consec_pre = 0;
            elseif trial_outcome(i) == -1
                consec_pre = consec_pre + 1;
                consec_cor = 0;
            else
                accum_late = accum_late + 1;
                consec_cor = 0;
            end
            if consec_cor>3 && FP_exe<FP_end %adjust FP
                FP_exe = FP_exe + 0.1;
                consec_cor = 0;
            elseif consec_pre>=10 && FP_exe>=0.1
                FP_exe = FP_exe - 0.1;
                consec_pre = 0;
            end
            if accum_cor>=4
                if RW_exe>RW_end %adjust RW
                    RW_exe = RW_exe - 0.1;
                    accum_cor = 0;
                end
            elseif accum_late>=10 && RW_exe<1
                RW_exe = RW_exe + 0.1;
                accum_late = 0;
            end
        end
        event_matrix(:,[6,7]) = [FPs,RWs].*0.001; % s
        % verification FP
        FP_calculated = round(event_matrix(ind_trial_tone,6),3);
        FP_recorded = round(time_tone - event_matrix(ind_trial_tone,1),3); % reserve 3 decimal fraction
        FP_contrast = table(FP_recorded,FP_calculated,'VariableNames',{'FP_recorded','FP_calculated'});
        wrongFP = ind_trial_tone(FP_recorded~=FP_calculated);
        if ~isempty(wrongFP)
            locname = string(metadata.SubjectName) + ' ' + string(metadata.Date) + ' Mismatch FP index';
            display(wrongFP,char(locname));
        end
        % verification RW
        RW_calculated = round(event_matrix(ind_late_release,7),3);
        RW_recorded = round(time_late - event_matrix(ind_late_release,5),3);
        RW_contrast = table(RW_recorded,RW_calculated,'VariableNames',{'RW_recorded','RW_calculated'});
        wrongRW = ind_late_release(RW_recorded~=RW_calculated);
        if ~isempty(wrongRW)
            locname = string(metadata.SubjectName) + ' ' + string(metadata.Date) + ' Mismatch RW index';
            display(wrongRW,char(locname));
        end
    otherwise
        FPs = [];
        RW_exe = 0.6;
        try
            fp_events = med_to_tec_fp(filename,100);
            if size(fp_events, 1) >= length(time_leverpress)  % if this checks out, foreperiod requirement is documented.
                FPs = fp_events(1: length(time_leverpress), 2) .* 10; %ms
            else
                FPs = ones(length(time_leverpress), 1) .* NaN; % lack enough FP data
            end
            event_matrix(:,[6,7]) = [FPs.*0.001,repelem(RW_exe,n_leverrelease)'];
        catch ME
            display(ME);
        end
end
%% Compute RT
event_matrix(:,8) = NaN; % for reaction time
reaction_time = (event_matrix(ind_trial_tone,2) - event_matrix(ind_trial_tone,5)).*1000; % ms
event_matrix(ind_trial_tone,8) = reaction_time.*0.001;
%% Save data
event_matrix(:,9) = NaN; % for trial num index
event_matrix(ind_iTrial,9) = 1:length(ind_iTrial);

tablenames = {'Subject','Date',...
    'Task','iTrial',...
    'PressTime','ReleaseTime','PressDur','ToneTime',...
    'Type','FP','RW','RT'};
bt = table(repelem(string(metadata.SubjectName),n_leverrelease)',repelem(session_date,n_leverrelease)',...
    repelem(string(protocol_name),n_leverrelease)',event_matrix(:,9),...
    event_matrix(:,1),event_matrix(:,2),event_matrix(:,3),event_matrix(:,5),...
    event_matrix(:,4),event_matrix(:,6),event_matrix(:,7),event_matrix(:,8),...
    'VariableNames',tablenames);
bt_NoDark = bt(bt.Type~=0,:); % for debug

% old version format
b.Metadata = metadata;
b.SessionName = session_name;
b.PressTime = time_leverpress';
b.ReleaseTime = time_leverrelease';
b.Correct = ind_correct_release';
b.Premature = ind_premature_release';
b.Late = ind_late_release';
b.Dark = ind_inter_trial_press';
b.ReactionTime = reaction_time';
b.TimeTone = time_tone';
b.IndToneLate = ind_tone_late';
b.FPs = FPs';
% b.RWs = RWs';

savename = ['B_' upper(metadata.SubjectName) '_' strrep(metadata.Date, '-', '_') '_' strrep(metadata.StartTime, ':', '')];
save(savename, 'b','bt')
%% Compute Trials-to-Criterion
t2c_label = '';
switch protocol_name
    case 'Wait1Bpod'
        trial2cri = find(abs(bt_NoDark.FP - FP_end)<1E-14,1);
        if ~isempty(trial2cri)
            t2c_label = "Trials to criterion: "+ num2str(trial2cri);
        else
            maxFP = max(bt_NoDark.FP);
            t2c_label = "Max FP(s) achieved: "+ num2str(maxFP);
        end
    case 'Wait2Bpod'
        trial2fp = find(abs(bt_NoDark.FP - FP_end)<1E-14,1);
        trial2rw = find(abs(bt_NoDark.RW - RW_end)<1E-14,1);
        if ~isempty(trial2fp)
            if ~isempty(trial2rw)
                trial2cri = max(trial2fp,trial2rw);
                t2c_label = "Trials to criterion: "+ num2str(trial2cri);
            end
        else
            maxFP = max(bt_NoDark.FP);
            minRW = min(bt_NoDark.RW);
            t2c_label = "FP & RW(s) achieved: "+ num2str(maxFP)+" & "+num2str(minRW);
        end
end
%% progress plot (old version)
if plotmark(1)
    good_col=[0 1 0]*0.75;

    figure(1); clf(1)
    set(gcf, 'unit', 'centimeters', 'position',[1 1 22 18], 'paperpositionmode', 'auto' )

    subplot(2, 5, [1 2 3 4])
    set(gca, 'nextplot', 'add', 'ylim', [0 2800], 'xlim', [0 4000])
    line([time_leverlighton time_leverlighton], [0 500], 'color', 'b')
    line([time_leverlightoff time_leverlightoff], [0 500], 'color', 'b', 'linestyle', ':')
    plot(time_leverrelease(ind_correct_release), press_durs(ind_correct_release), 'o', 'linewidth', 1, 'color', good_col)
    plot(time_leverrelease(ind_premature_release), press_durs(ind_premature_release), 'ro', 'linewidth', 1)
    plot(time_leverrelease(ind_late_release), press_durs(ind_late_release), 'ro', 'linewidth', 1, 'markerfacecolor', 'r')
    plot(time_leverrelease(ind_inter_trial_press), press_durs(ind_inter_trial_press), 'ko', 'linewidth', 1)
    xlabel ('Time (s)')
    ylabel ('Press duration (ms)')

    subplot(2, 5, 5);
    init_loc = 1.5;
    set(gca, 'xlim', [1.5 10], 'ylim', [0 9], 'nextplot', 'add')
    plot(init_loc,     8, 'o', 'linewidth', 1, 'color', good_col)
    text(init_loc+0.7, 8, 'Correct')
    plot(init_loc,     7, 'ro', 'linewidth', 1)
    text(init_loc+0.7, 7, 'Premature')
    plot(init_loc,     6 , 'ro', 'linewidth', 1, 'markerfacecolor', 'r')
    text(init_loc+0.7, 6, 'Late')
    plot(init_loc,     5, 'ko', 'linewidth', 1)
    text(init_loc+0.7, 5, 'Dark')
    axis off
    % axes(hainfo)
    text(init_loc, 4, strrep(metadata.ProtocolName, '_', '-'))
    text(init_loc, 3, upper(metadata.SubjectName))
    text(init_loc, 2, metadata.Date)
    text(init_loc, 1, metadata.StartTime)
    text(init_loc, 0, t2c_label)

    subplot(2, 5, [6 7 8 9])
    set(gca, 'nextplot', 'add', 'ylim', [0 1000], 'xlim', [0 4000])
    plot(bt.ToneTime(ind_late_release),    bt.RT(ind_late_release).*1000,   'ro', 'linewidth', 1, 'markerfacecolor', 'r', 'markersize', 6)
    plot(bt.ToneTime(ind_correct_release), bt.RT(ind_correct_release).*1000, 'o', 'linewidth', 1, 'color', good_col, 'markersize', 6)
    xlabel ('Time (s)')
    ylabel ('Reaction time (ms)')

    subplot(2, 5, [10])
    set(gca, 'nextplot', 'add', 'ylim', [0 1000], 'xlim', [0 5], 'xtick', [])
    hb1=bar([1], length(ind_correct_release));
    set(hb1, 'EdgeColor', good_col, 'facecolor', 'none', 'linewidth', 2);
    hb2=bar([2], length(ind_premature_release));
    set(hb2, 'EdgeColor', 'r', 'facecolor', 'none', 'linewidth', 2);
    hb2=bar([3], length(ind_late_release));
    set(hb2, 'EdgeColor', 'r', 'facecolor', 'r', 'linewidth', 2);
    hb3=bar([4], length(ind_inter_trial_press));
    set(hb3, 'EdgeColor', 'k', 'facecolor', 'none', 'linewidth', 2);
    axis 'auto y'
    % add success rate:
    per_success=length(ind_correct_release)/(length(ind_correct_release)+length(ind_premature_release)+length(ind_late_release));
    text(init_loc, 0.9*max(get(gca, 'ylim')), [sprintf('%2.1f %s', per_success*100), '%'], 'color', good_col)
    ylabel ('Number')

    savename=fullfile(fig_path, savename);
    saveas(gcf, savename, 'png')
    saveas(gcf, savename, 'fig')
end
%% progress plot with histogram
if plotmark(2)
    cDarkGray = [0.3,0.3,0.3];
    cGreen = [0.4660 0.6740 0.1880];
    cRed = [0.6350 0.0780 0.1840];
    cYellow = [0.9290 0.6940 0.1250];
    cBlue = [0,0.6902,0.9412];
    cGray = [0.4 0.4 0.4];
    colorlist1 = {cDarkGray,cGreen,cRed,cYellow};
    colorlist2 = {cGreen,cYellow};

    figure(2); clf(2)
    set(gcf, 'unit', 'centimeters', 'position',[1 1 22 18], 'paperpositionmode', 'auto' )

    bt_plot = bt;
    bt_plot.PressDur = bt_plot.PressDur .* 1000;
    bt_plot.RT = bt_plot.RT .* 1000;
    bt_plot.Type(ind_inter_trial_press) = 2; % for sorting
    bt_plot = sortrows(bt_plot,9,'descend');
    bt_plot.Type = string(bt_plot.Type);
    bt_plot.Type(bt_plot.Type=="1") = "Correct";
    bt_plot.Type(bt_plot.Type=="-1") = "Premature";
    bt_plot.Type(bt_plot.Type=="-2") = "Late";
    bt_plot.Type(bt_plot.Type=="2") = "Inter-trial";
    if isempty(find(bt_plot.Type=="Late", 1))
        colorlist1 = {cDarkGray,cGreen,cRed};
    end

    subplot(2, 10, [1:7])

    s1 = scatterhistogram(bt_plot,'ReleaseTime','PressDur','GroupVariable','Type',...
        'BinWidths',[60;50],'HistogramDisplayStyle','smooth','ScatterPlotLocation','SouthWest',...
        'LineWidth',1.5,'Color',colorlist1,'MarkerSize',30,'MarkerAlpha',0.7,'LegendVisible','off');
    s1.XLimits = [0 4000];
    s1.YLimits = [0 2800];
    s1.XLabel = 'Time (s)';
    s1.YLabel = 'Press duration (ms)';
    s1.LegendTitle = '';
    s1.ScatterPlotProportion = 0.8;

    subplot(2, 10, [9 10]);
    init_loc = 1.5;
    set(gca, 'xlim', [1.5 10], 'ylim', [0 9], 'nextplot', 'add')
    plot(init_loc,     8, 'o', 'linewidth', 1, 'markerfacecolor', cGreen, 'markeredgecolor', cGreen)
    text(init_loc+0.7, 8, 'Correct')
    plot(init_loc,     7, 'o', 'linewidth', 1, 'markerfacecolor', cRed, 'markeredgecolor', cRed)
    text(init_loc+0.7, 7, 'Premature')
    plot(init_loc,     6, 'o', 'linewidth', 1, 'markerfacecolor', cYellow, 'markeredgecolor', cYellow)
    text(init_loc+0.7, 6, 'Late')
    plot(init_loc,     5, 'o', 'linewidth', 1, 'markerfacecolor', cDarkGray, 'markeredgecolor', cDarkGray)
    text(init_loc+0.7, 5, 'Inter-trial')
    axis off
    % axes(hainfo)
    text(init_loc, 4, strrep(metadata.ProtocolName, '_', '-'))
    text(init_loc, 3, upper(metadata.SubjectName))
    text(init_loc, 2, metadata.Date)
    text(init_loc, 1, metadata.StartTime)
    text(init_loc, 0, t2c_label)

    subplot(2, 10, [11:17])
    bt_rt_plot = bt_plot(~isnan(bt_plot.ToneTime),:);

    s2 = scatterhistogram(bt_rt_plot,'ToneTime','RT','GroupVariable','Type',...
        'BinWidths',[60;50],'HistogramDisplayStyle','smooth','ScatterPlotLocation','SouthWest',...
        'LineWidth',1.5,'Color',colorlist2,'MarkerSize',30,'MarkerAlpha',0.7,'LegendVisible','off');
    s2.XLimits = [0 4000];
    s2.YLimits = [0 1300];
    s2.XLabel = 'Time (s)';
    s2.YLabel = 'Reaction Time (ms)';
    s2.LegendTitle = '';
    s2.ScatterPlotProportion = 0.8;

    subplot(2, 10, [19 20])
    set(gca, 'nextplot', 'add', 'xlim', [0 5], 'xtick', [])
    hb1=bar([1], length(ind_correct_release));
    set(hb1, 'EdgeColor', cGreen, 'facecolor', 'none', 'linewidth', 2);
    hb2=bar([2], length(ind_premature_release));
    set(hb2, 'EdgeColor', cRed, 'facecolor', 'none', 'linewidth', 2);
    hb2=bar([3], length(ind_late_release));
    set(hb2, 'EdgeColor', cYellow, 'facecolor', 'none', 'linewidth', 2);
    hb3=bar([4], length(ind_inter_trial_press));
    set(hb3, 'EdgeColor', cDarkGray, 'facecolor', 'none', 'linewidth', 2);
    axis 'auto y'
    % add success rate:
    per_success=length(ind_correct_release)/(length(ind_correct_release)+length(ind_premature_release)+length(ind_late_release));
    text(init_loc, 0.9*max(get(gca, 'ylim')), [sprintf('%2.1f %s', per_success*100), '%'], 'color', cGreen)
    ylabel ('Number')

    savename_newB = ['NB_' upper(metadata.SubjectName) '_' strrep(metadata.Date, '-', '_') '_' strrep(metadata.StartTime, ':', '')];
    savename_newB = fullfile(fig_path, savename_newB);
    saveas(gcf, savename_newB, 'png')
    saveas(gcf, savename_newB, 'fig')
end
end