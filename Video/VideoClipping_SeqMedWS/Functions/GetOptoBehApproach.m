function bUpdated =  GetOptoBehApproach(isession, ibpodsession)

b=track_training_progress_advanced(isession);

load(ibpodsession);
sd = SessionData;

press_time_bpod = []; % press time
appstim = []; % 1: stim occurs when approach, 0: no stim
app2press_time_bpod= []; % time from approach to press
app_time = []; % approach time
app2press = [];  % 1: rat did a press after approach, 0: rat didn't do a press after approach
stim_time = [];  % for each appstim == 1, the laser stimulation time is plotted here. time and laser stim pattern can be found in bpod or wavesurfer files. 
stim_pattern = []; % dur, freq, pulse-dur

for j =1 : length(sd.RawEvents.Trial)
    app_time = [app_time sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForApproach(end)];
    
    if  ~isnan(sd.RawEvents.Trial{j}.States.WaitForPressStim(1))  % stim trials
        appstim                         =           [appstim 1];
        stim_time                      =           [stim_time sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForPressStim(1)];
        stim_pattern                  =           [stim_pattern; sd.TrialSettings(j).GUI.StimDur sd.TrialSettings(j).GUI.StimFreq sd.TrialSettings(j).GUI.StimPulseDur sd.TrialSettings(j).GUI.Delay];
    else
        appstim                         =           [appstim 0];
    end;
    
    if ~isnan(sd.RawEvents.Trial{j}.States.WaitForMedTTL(1)) % rat did a lever press
        press_time_bpod         =           [press_time_bpod sd.TrialStartTimestamp(j) + sd.RawEvents.Trial{j}.States.WaitForMedTTL(1)];
        app2press_time_bpod =           [app2press_time_bpod sd.RawEvents.Trial{j}.States.WaitForMedTTL(1)-sd.RawEvents.Trial{j}.States.Masking(1)];
        app2press                    =           [app2press 1];
    else
        app2press = [app2press 0]; % rat didn't do a press
    end;
end;

% now, every press_time_bpod should be corresponding to a press in
% b.PressTime. Our next step is to identify the index the link
% press_time_bpod to b.PressTime

IndBpod2MED = findseqmatch(b.PressTime*1000, press_time_bpod*1000, 1);
% Now determine the time of approach/laserstim in MED's time domain
AppTimeMED = Map2TimeInB(app_time, press_time_bpod, b.PressTime, IndBpod2MED);
StimTimeMED = Map2TimeInB(stim_time, press_time_bpod, b.PressTime, IndBpod2MED);

bUpdated = b;
bUpdated.PressTimeBpodvsMED = [press_time_bpod; b.PressTime(IndBpod2MED)];
bUpdated.PressTimeBpodIndex = IndBpod2MED;
bUpdated.Approach = AppTimeMED;
bUpdated.ApproachStimIndex = appstim;
bUpdated.StimTime = StimTimeMED;
bUpdated.StimProfile = stim_pattern;

bUpdated.App2PressCompleted = app2press;
bUpdated.App2PressLatency = app2press_time_bpod;

save bUpdated bUpdated


% 
% 
% 
% [~,bnew.Correct] = intersect(bnew.MedIndex, intersect(b.Correct, bpod_to_MED));
% [~,bnew.Premature] = intersect(bnew.MedIndex, intersect(b.Premature, bpod_to_MED));
% [~,bnew.Late] = intersect(bnew.MedIndex, intersect(b.Late, bpod_to_MED));
% [~,bnew.Dark] = intersect(bnew.MedIndex, intersect(b.Dark, bpod_to_MED));
% 
% bnew.FPs = b.FPs(bpod_to_MED);
% bnew.Stim = press_stim;
% 
% bnew.Performance_Definition = {'N_correct', 'N_premature', 'N_late', 'Perc_Correct',  'Perc_Premature',  'Perc_Late'};
% 
% bnew.Performance_Nostim = [length(intersect(bnew.Correct, find(bnew.Stim==0)));
%     length(intersect(bnew.Premature, find(bnew.Stim==0)));
%     length(intersect(bnew.Late, find(bnew.Stim==0))) ];
% 
% bnew.Performance_Nostim(4)= bnew.Performance_Nostim(1)/sum(bnew.Performance_Nostim(1:3));
% bnew.Performance_Nostim(5)= bnew.Performance_Nostim(2)/sum(bnew.Performance_Nostim(1:3));
% bnew.Performance_Nostim(6)= bnew.Performance_Nostim(3)/sum(bnew.Performance_Nostim(1:3));
% 
% bnew.Performance_Stim = [length(intersect(bnew.Correct, find(bnew.Stim==1)));
%     length(intersect(bnew.Premature, find(bnew.Stim==1)));
%     length(intersect(bnew.Late, find(bnew.Stim==1))) ];
% bnew.Performance_Stim(4)= bnew.Performance_Stim(1)/sum(bnew.Performance_Stim);
% bnew.Performance_Stim(5)= bnew.Performance_Stim(2)/sum(bnew.Performance_Stim(1:3));
% bnew.Performance_Stim(6)= bnew.Performance_Stim(3)/sum(bnew.Performance_Stim(1:3));
% 
% 
% % press duration short FP, nostim
% Nostim_short_index = find(bnew.FPs == ifp(1)&bnew.Stim==0);
% Stim_short_index = find(bnew.FPs == ifp(1)&bnew.Stim==1);
% 
% Nostim_Short_PressDur = bnew.ReleaseTime(Nostim_short_index)-bnew.PressTime(Nostim_short_index);
% Stim_Short_PressDur = bnew.ReleaseTime(Stim_short_index)-bnew.PressTime(Stim_short_index);
% 
% data_shortFP = {1000*Nostim_Short_PressDur, 1000*Stim_Short_PressDur};
% catIdx_short = [ones(length(Nostim_Short_PressDur), 1); 2*ones(length(Stim_Short_PressDur), 1)]
% 
% % performance at short FPs:
% 
% bnew.Performance_Nostim_ShortFP = [length(intersect(bnew.Correct, Nostim_short_index));
%     length(intersect(bnew.Premature, Nostim_short_index));
%     length(intersect(bnew.Late, Nostim_short_index)) ];
% 
% bnew.Performance_Nostim_ShortFP(4)= bnew.Performance_Nostim_ShortFP(1)/sum(bnew.Performance_Nostim_ShortFP(1:3));
% bnew.Performance_Nostim_ShortFP(5)= bnew.Performance_Nostim_ShortFP(2)/sum(bnew.Performance_Nostim_ShortFP(1:3));
% bnew.Performance_Nostim_ShortFP(6)= bnew.Performance_Nostim_ShortFP(3)/sum(bnew.Performance_Nostim_ShortFP(1:3));
% 
% bnew.Performance_Stim_ShortFP = [length(intersect(bnew.Correct, Stim_short_index));
%     length(intersect(bnew.Premature, Stim_short_index));
%     length(intersect(bnew.Late, Stim_short_index)) ];
% 
% bnew.Performance_Stim_ShortFP(4)= bnew.Performance_Stim_ShortFP(1)/sum(bnew.Performance_Stim_ShortFP(1:3));
% bnew.Performance_Stim_ShortFP(5)= bnew.Performance_Stim_ShortFP(2)/sum(bnew.Performance_Stim_ShortFP(1:3));
% bnew.Performance_Stim_ShortFP(6)= bnew.Performance_Stim_ShortFP(3)/sum(bnew.Performance_Stim_ShortFP(1:3));
% 
% % press duration long FP, nostim
% 
% Nostim_long_index = find(bnew.FPs ==ifp(2)&bnew.Stim==0);
% Stim_long_index = find(bnew.FPs == ifp(2)&bnew.Stim==1);
% 
% Nostim_Long_PressDur = bnew.ReleaseTime(Nostim_long_index)-bnew.PressTime(Nostim_long_index);
% Stim_Long_PressDur = bnew.ReleaseTime(Stim_long_index)-bnew.PressTime(Stim_long_index);
% 
% data_longFP = {1000*Nostim_Long_PressDur, 1000*Stim_Long_PressDur};
% catIdx_long = [4*ones(length(Nostim_Long_PressDur), 1); 5*ones(length(Stim_Long_PressDur), 1)]
% 
% data_both = [data_shortFP data_longFP];
% catldx_both = [catIdx_short; catIdx_long];
% 
% 
% % performance at long FPs:
% 
% bnew.Performance_Nostim_LongFP = [length(intersect(bnew.Correct, Nostim_long_index));
%     length(intersect(bnew.Premature, Nostim_long_index));
%     length(intersect(bnew.Late, Nostim_long_index)) ];
% 
% bnew.Performance_Nostim_LongFP(4)= bnew.Performance_Nostim_LongFP(1)/sum(bnew.Performance_Nostim_LongFP(1:3));
% bnew.Performance_Nostim_LongFP(5)= bnew.Performance_Nostim_LongFP(2)/sum(bnew.Performance_Nostim_LongFP(1:3));
% bnew.Performance_Nostim_LongFP(6)= bnew.Performance_Nostim_LongFP(3)/sum(bnew.Performance_Nostim_LongFP(1:3));
% 
% bnew.Performance_Stim_LongFP = [length(intersect(bnew.Correct, Stim_long_index));
%     length(intersect(bnew.Premature, Stim_long_index));
%     length(intersect(bnew.Late, Stim_long_index)) ];
% 
% bnew.Performance_Stim_LongFP(4)= bnew.Performance_Stim_LongFP(1)/sum(bnew.Performance_Stim_LongFP(1:3));
% bnew.Performance_Stim_LongFP(5)= bnew.Performance_Stim_LongFP(2)/sum(bnew.Performance_Stim_LongFP(1:3));
% bnew.Performance_Stim_LongFP(6)= bnew.Performance_Stim_LongFP(3)/sum(bnew.Performance_Stim_LongFP(1:3));
% 
% figure(20); clf(20)
% set(gcf, 'unit', 'centimeters', 'position',[2 2 20 15], 'paperpositionmode', 'auto' )
% 
% ha1 = subplot(2, 2, 1);
% set(ha1, 'nextplot', 'add', 'TickDir', 'Out');
% title(bnew.SessionName)
% 
% hbar1(1) = bar([1], [100*bnew.Performance_Nostim_ShortFP(4) ], 0.9)
% hbar1(2) = bar([2], [100*bnew.Performance_Nostim_ShortFP(5) ], 0.9)
% hbar1(3) = bar([3], [100*bnew.Performance_Nostim_ShortFP(6) ], 0.9)
% set(hbar1(1), 'facecolor', [55 255 0]/255, 'edgecolor', 'k', 'linewidth', 1.5)
% set(hbar1(2), 'facecolor', [153 51 0]/255, 'edgecolor', 'k', 'linewidth', 1.5)
% set(hbar1(3), 'facecolor', 'r', 'edgecolor', 'k', 'linewidth', 1.5)
% 
% hbar2(1) = bar([5 ], [100*bnew.Performance_Stim_ShortFP(4)], 0.9)
% hbar2(2) = bar([6], [100*bnew.Performance_Stim_ShortFP(5)], 0.9)
% hbar2(3) = bar([7], [100*bnew.Performance_Stim_ShortFP(6)], 0.9)
% 
% set(hbar2(1), 'facecolor', [55 255 0]/255, 'edgecolor', 'b', 'linewidth', 1.5)
% set(hbar2(2), 'facecolor', [153 51 0]/255, 'edgecolor', 'b', 'linewidth', 1.5)
% set(hbar2(3), 'facecolor', 'r', 'edgecolor', 'b', 'linewidth', 1.5)
% 
% hbar1(4) = bar([10], [100*bnew.Performance_Nostim_LongFP(4) ], 0.9)
% hbar1(5) = bar([11], [100*bnew.Performance_Nostim_LongFP(5) ], 0.9)
% hbar1(6) = bar([12], [100*bnew.Performance_Nostim_LongFP(6) ], 0.9)
% set(hbar1(4), 'facecolor', [55 255 0]/255, 'edgecolor', 'k', 'linewidth', 1.5)
% set(hbar1(5), 'facecolor', [153 51 0]/255, 'edgecolor', 'k', 'linewidth', 1.5)
% set(hbar1(6), 'facecolor', 'r', 'edgecolor', 'k', 'linewidth', 1.5)
% 
% hbar2(4) = bar([ 14], [100*bnew.Performance_Stim_LongFP(4)], 0.9)
% hbar2(5) = bar([ 15], [100*bnew.Performance_Stim_LongFP(5)], 0.9)
% hbar2(6) = bar([ 16], [100*bnew.Performance_Stim_LongFP(6)], 0.9)
% 
% line([8 8], [0 100], 'linestyle', '--', 'color', [.5 .5 .5]);
% 
% set(hbar2(4), 'facecolor', [55 255 0]/255, 'edgecolor', 'b', 'linewidth', 1.5)
% set(hbar2(5), 'facecolor', [153 51 0]/255, 'edgecolor', 'b', 'linewidth', 1.5)
% set(hbar2(6), 'facecolor', 'r', 'edgecolor', 'b', 'linewidth', 1.5)
% 
% text(2, 95, 'Short')
% text(11, 95, 'Long')
% 
% set(ha1,'xlim', [0 17], 'xtick', [2 6 11 15], 'xticklabel', {'Nostim', 'Stim', 'Nostim', 'Stim'}, 'ylim', [0 100])
% ylabel('Performance')
% 
% ha2 = subplot(2, 2, 2);
% set(ha2, 'nextplot', 'add', 'TickDir', 'Out');
% 
% hp2 = plotSpread(data_both, 'CategoryIdx',catldx_both,...
%     'categoryMarkers',{'.','.', '.', '.'},'categoryColors',{'k','b', 'k', 'b'}, 'spreadWidth', 0.6)
% 
% line([0.5 2.5], [ifp(1) ifp(1)], 'color', [0.8 0.8 0.8], 'linestyle', '--', 'linewidth', 1)
% line([0.5 2.5], [ifp(1)+1000 ifp(1)+1000], 'color', [0.8 0.8 0.8], 'linestyle', ':','linewidth', 1)
% 
% line([2.5 4.5], [ifp(2) ifp(2)], 'color', [0.8 0.8 0.8], 'linestyle', '--', 'linewidth', 1)
% line([2.5 4.5], [ifp(2)+1000 ifp(2)+1000], 'color', [0.8 0.8 0.8], 'linestyle', ':', 'linewidth', 1)
% 
% set(ha2, 'xlim', [0 5], 'ylim', [0 4000], 'xtick', [1 2 3 4], 'xticklabel', {'Nostim', 'Stim', 'Nostim', 'Stim'})
% ylabel('Press duration (ms)')
% 
% % Reaction time
% % 1. Reaction time for short FP
% Nostim_short_index_correct = intersect(Nostim_short_index, bnew.Correct);
% Stim_short_index_correct = intersect(Stim_short_index, bnew.Correct);
% 
% RT_short_nostim = bnew.ReleaseTime(Nostim_short_index_correct)-bnew.PressTime(Nostim_short_index_correct)-ifp(1)/1000;
% RT_short_stim = bnew.ReleaseTime(Stim_short_index_correct)-bnew.PressTime(Stim_short_index_correct)-ifp(1)/1000;
% 
% median_RT_short_nostim = median(RT_short_nostim);
% median_RT_short_stim = median(RT_short_stim);
% 
% bnew.RT_Short_Nostim = RT_short_nostim;
% bnew.RT_Short_Stim = RT_short_stim;
% 
% % 2. Reaction time for long FP
% Nostim_long_index_correct = intersect(Nostim_long_index, bnew.Correct);
% Stim_long_index_correct = intersect(Stim_long_index, bnew.Correct);
% 
% RT_long_nostim = bnew.ReleaseTime(Nostim_long_index_correct)-bnew.PressTime(Nostim_long_index_correct)-ifp( 2)/1000;
% RT_long_stim = bnew.ReleaseTime(Stim_long_index_correct)-bnew.PressTime(Stim_long_index_correct)-ifp( 2)/1000;
% 
% median_RT_long_nostim = median(RT_long_nostim);
% median_RT_long_stim = median(RT_long_stim);
% 
% RTdata = {1000*RT_short_nostim, 1000*RT_short_stim, 1000*RT_long_nostim, 1000*RT_long_stim};
% catIdx_RT = [ones(1, length(RT_short_nostim)) 2*ones(1, length(RT_short_stim)) 3*ones(1, length(RT_long_nostim)) 4*ones(1, length(RT_long_stim))];
% 
% bnew.RT_Long_Nostim = RT_long_nostim;
% bnew.RT_Long_Stim = RT_long_stim;
% 
% ha3 = subplot(2, 2, 3);
% set(ha3, 'nextplot', 'add', 'TickDir', 'Out');
% 
% hp3 = plotSpread(RTdata, 'CategoryIdx',catIdx_RT,...
%     'categoryMarkers',{'.','.', '.', '.'},'categoryColors',{'k','b', 'k', 'b'}, 'spreadWidth', 0.8)
% set(ha3, 'xlim', [0 5], 'ylim', [0 1000], 'xtick', [1 2 3 4], 'xticklabel', {'Nostim', 'Stim', 'Nostim', 'Stim'})
% 
% line([1 1], prctile(RT_short_nostim, [25 75])*1000, 'color', 'r', 'linewidth', 2)
% line([0.9 1.1], [median_RT_short_nostim median_RT_short_nostim]*1000, 'color', 'r', 'linewidth', 2)
% line([2 2], prctile(RT_short_stim, [25 75])*1000, 'color', 'r', 'linewidth', 2)
% line([1.9 2.1], [median_RT_short_stim median_RT_short_stim]*1000, 'color', 'r', 'linewidth', 2)
% 
% line([3 3], prctile(RT_long_nostim, [25 75])*1000, 'color', 'r', 'linewidth', 2)
% line([2.9 3.1] , [median_RT_long_nostim median_RT_long_nostim]*1000, 'color', 'r', 'linewidth', 2)
% line([4 4], prctile(RT_long_stim, [25 75])*1000, 'color', 'r', 'linewidth', 2)
% line([3.9 4.1] , [median_RT_long_stim median_RT_long_stim]*1000, 'color', 'r', 'linewidth', 2)
% ylabel('Reaction time (ms)')
% 
% [p_short, h_short] = ranksum(RT_short_nostim, RT_short_stim);
% [p_long, h_long] = ranksum(RT_long_nostim, RT_long_stim);
% 
% text(1, 900, sprintf('p=%2.4f', p_short))
% text(3, 900, sprintf('p=%2.4f', p_long))
% 
% 
% fprintf('short FP p value is %2.5f\n', p_short)
% fprintf('long FP p value is %2.5f\n', p_long)
% mkdir('Fig');
% 
% savename = ['OptoEffect'  upper(bnew.Metadata.Metadata.SubjectName) '_' bnew.Metadata.Metadata.Date];
% savename=fullfile(pwd, 'Fig', savename)
% 
% print (gcf,'-dpng', [savename])
% print (gcf,'-dpdf', [savename])


