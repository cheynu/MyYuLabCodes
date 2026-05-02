function out = process_pi_cy(Dates, Treatment, ANM, options)
arguments
    Dates
    Treatment
    ANM
    options.binWidth = 0.1 % second
    options.maxAnalysisTime = 45 % second. adjust according to xlim=[0 3*target_delay]
    options.splitReward logical = false % plot reward trials or plot N_Switch and fixed interval trials
    options.printDailyFig logical = false % whether save everyday performance
    options.pokeAlign {mustBeMember(options.pokeAlign,["lastPress","lastDelayStart"])} = "lastDelayStart"
    options.cleanInfo logical = true
    options.dataCutoff {mustBeMember(options.dataCutoff,["nextPress","nextAlignPress"])} = "nextPress"
    options.printSummaryFig logical = true % whether save summary performance
    options.ksBandWidth = 0.5 % smooth index of ksdensity for each trial
    options.treatmentName = {'Saline','DCZ'} % 1x2 cellstr, corresponding to {man==0, man==1}
    options.figSaveFolder char = 'Fig' % save in fullfile(pwd,figSaveFolder)
    options.figNameSuffix char = ''
    options.ifPlot = true
    options.ifSaveData = false
    options.nboot = 1000
end
dt = options.binWidth;
maxT = options.maxAnalysisTime;
ifSplitR = options.splitReward;
ifPrintDaily = options.printDailyFig;
pokeAlignType = options.pokeAlign;
ifClean = options.cleanInfo;
cutoffType = options.dataCutoff;
ifPrintSummary = options.printSummaryFig;
ksBW = options.ksBandWidth;
treatName = options.treatmentName;
figSaveFolder = options.figSaveFolder;
figNameSuffix = options.figNameSuffix;
ifPlot = options.ifPlot;
ifSaveData = options.ifSaveData;
nboot = options.nboot;

out = cell(1,length(Dates));
%%
edges                       =       linspace(0, maxT, maxT*(1/dt)+1); % 0 to maxAnalysisTime seconds, 100 bins
% bins                        =       (edges(2:end)+edges(1:end-1))/2;
bins                        =       edges(2:end);

if ~isempty(figNameSuffix)
    suffix = ['_' figNameSuffix];
else
    suffix = '';
end
if ~isempty(figSaveFolder) && (ifPrintDaily || ifPrintSummary)
    [~,~] = mkdir(fullfile(pwd,figSaveFolder));
end

Times_Saline = [];
Times_DCZ = [];
SSMS_Saline = []; % StartTime, StopTime, Middle, Spread
SSMS_DCZ = [];

for thisday = 1:length(Dates)
    man = Treatment(thisday);
    Trial_Type              =       {}; % tag each trial's type
    Raw_Events              =       {}; % rawdata excluded warmup
    Port_Times_Rewarded     =       {}; % all rewarded trials (fixed interval & time warning trials)
    Port_Times_Probe        =       {}; % peak interval trials
    Port_Times_FI           =       {}; % fixed interval trials
    Port_Times_NS           =       {}; % time warning trials (N_Switch)
    Lever_Times_Probe       =       {}; % all lever-presses (aligned to the lever-press used for pokes alignment)
    TrialEnd_Times_Probe    =       {}; % the trial end time point aligned to the leverpress (zero point of x axis)
    Hist_Times_Rewarded     =       [];
    Hist_Times_Probe        =       [];
    Hist_Times_FI           =       [];
    Hist_Times_NS           =       [];
    StartStop_Times_Probe   =       []; % [start1 stop1 middle1 spread1;...;startN stopN middleN spreadN]
    PokeRate_Trial_Probe    =       []; % [PRAllTrial1 ... PRAllTrialN]
    PokeRate_StartStop_Probe=       []; % [PRBetweenStartStop1 ... PRBetweenStartStopN]

    a                       =       load(Dates{thisday});
    [~,thisfilename]        =       fileparts(Dates{thisday});
    aData                   =       a.SessionData;
    trials                  =       aData.RawEvents.Trial;
    n_trials                =       length(trials);
    n_probe                 =       0;
    n_rewards               =       0;
    n_fi                    =       0;
    n_ns                    =       0;
    
    datechar = strsplit(Dates{thisday},'_');
    datechar = char(datechar{end-1});

    Raw_Events              =       trials;
    for k =1:n_trials
        k_trial_start       =       aData.TrialStartTimestamp(k);
        GUI_info            =       aData.TrialSettings(k).GUI;
        target_delay        =       GUI_info.TargetDelay;
        iStates             =       trials{k}.States;
        this_delay          =       round(diff(iStates.WaitingDelay(end, :)));    
        if this_delay == target_delay
            switch pokeAlignType
                case "lastPress"
                    t_lever_press   =   trials{k}.Events.BNC1High(end);
                case "lastDelayStart"
                    % When the delay has been over, one more lever-press won't restart the delay, 
                    % and it would lead to wrong alignment
                    t_lever_press   =   trials{k}.States.WaitingDelay(end,1); % use the last press triggering state shift  
            end
            t_lever_press_all = trials{k}.Events.BNC1High - t_lever_press; % find all lever-presses
            t_trial_end = trials{k}.Events.Tup(end) - t_lever_press;
            if isfield(trials{k}.Events, 'Port1In')
                pokes               =   trials{k}.Events.Port1In-t_lever_press;
            elseif isfield(trials{k}.Events, 'Port2In') % Box4
                pokes               =   trials{k}.Events.Port2In-t_lever_press;
            else
                pokes               =   [];
            end
            ifNextPressInNextTrial = true;
            switch cutoffType
                case "nextPress"
                    idxAlignPress = find(round(t_lever_press_all,1)>=0,1,'first');
                    if idxAlignPress<length(t_lever_press_all)
                        pokes = pokes(pokes<t_lever_press_all(idxAlignPress+1));
                        ifNextPressInNextTrial = false;
                    end
                case "nextAlignPress"
                    % pass
            end

            if k <n_trials
                knext_trial_start = aData.TrialStartTimestamp(k+1); % starting time of next trial
                % extract poke and press from next trial
                switch pokeAlignType
                    case "lastPress"
                        t_lever_press_next = trials{k+1}.Events.BNC1High(end); 
                    case "lastDelayStart"
                        t_lever_press_next = trials{k+1}.States.WaitingDelay(end,1); % the same reason as above
                end
                if isfield(trials{k+1}.Events,'BNC1High')
                    t_lever_press_next_all = trials{k+1}.Events.BNC1High + (knext_trial_start - k_trial_start) - t_lever_press;
                else
                    t_lever_press_next_all = [];
                    
                end
                t_lever_press_all = [t_lever_press_all t_lever_press_next_all];
                t_trial_end_next = trials{k+1}.Events.Tup(end) + (knext_trial_start - k_trial_start) - t_lever_press;
                t_trial_end = [t_trial_end t_trial_end_next];
                if isfield(trials{k+1}.Events, 'Port1In') % extract all pokes in next trials
                    pokes_next = trials{k+1}.Events.Port1In;
                elseif isfield(trials{k+1}.Events, 'Port2In') % Box4
                    pokes_next = trials{k+1}.Events.Port2In;
                else
                    pokes_next = [];
                end
                switch cutoffType % exclude some pokes if needed
                    case "nextPress"
                        if ifNextPressInNextTrial
                            if isfield(trials{k+1}.Events,'BNC1High')
                                t_lever_press_next_first = trials{k+1}.Events.BNC1High(1); % first press in next trial 
                                pokes_next = pokes_next(pokes_next<t_lever_press_next_first)+(knext_trial_start-k_trial_start)-t_lever_press;
                            end
                        else % exclude all th pokes in the next trial (cutoff is before that)
                            pokes_next = [];
                        end
                    case "nextAlignPress"
                        % exclude the pokes in the range of next trial's analysis
                        pokes_next = pokes_next(pokes_next<t_lever_press_next)+(knext_trial_start-k_trial_start)-t_lever_press;
                end

                if ~isempty(pokes_next)
                    pokes = [pokes pokes_next];
                end
            end

            if isnan(iStates.WaitForRewardEmpty(1))
                n_rewards = n_rewards+1;
                Port_Times_Rewarded = [Port_Times_Rewarded pokes];
                if ~isempty(pokes)
                    rate_Hist_Times_Rewarded = ksdensity(pokes, edges, 'Bandwidth', ksBW).*sum(pokes>0 & pokes<=maxT); % poke / sec
                else
                    rate_Hist_Times_Rewarded = zeros(size(edges));
                end
                Hist_Times_Rewarded = [Hist_Times_Rewarded; rate_Hist_Times_Rewarded];
                if ~isnan(iStates.WaitForRewardBlank(1)) % this is a fixed interval trial
                    n_fi = n_fi + 1;
                    Port_Times_FI = [Port_Times_FI pokes];
                    Hist_Times_FI = [Hist_Times_FI; histcounts(pokes, edges)];
                    Trial_Type{k} = 'FI';
                else % ~isnan(iStates.WaitForRewardEntry(1)) % this is a N_Switch trial (Time warning trial)
                    n_ns = n_ns + 1;
                    Port_Times_NS = [Port_Times_NS pokes];
                    Hist_Times_NS = [Hist_Times_NS; histcounts(pokes, edges)];
                    Trial_Type{k} = 'NS';
                end
            else % this is a probe trial
                if ~isempty(pokes)
                    n_probe = n_probe + 1;
                    Port_Times_Probe = [Port_Times_Probe  pokes];
                    Hist_Times_Probe = [Hist_Times_Probe; ksdensity(pokes, edges, 'Bandwidth', ksBW).*sum(pokes>0 & pokes<=maxT)];
%                     Hist_Times_Probe = smoothdata(histcounts(pokes, edges, 'Normalization', 'countdensity'),'gaussian',smoWin(1));
                    
                    Lever_Times_Probe = [Lever_Times_Probe t_lever_press_all];
                    TrialEnd_Times_Probe = [TrialEnd_Times_Probe t_trial_end];

                    [startT,stopT,mid,spread] = getPeakStartTime(pokes,3*target_delay);
                    StartStop_Times_Probe = [StartStop_Times_Probe; [startT stopT mid spread]];

                    peakPokes = pokes(pokes>=startT & pokes<= stopT);
                    trialPokes = pokes(pokes<=3*target_delay);
                    PokeRate_Trial_Probe = [PokeRate_Trial_Probe length(trialPokes)./(3*target_delay)];
                    PokeRate_StartStop_Probe = [PokeRate_StartStop_Probe length(peakPokes)./abs(stopT-startT)];

                    Trial_Type{k} = 'PI';
                end
            end
        else
            Trial_Type{k} = 'Warmup';
        end
    end
%% Compute the average estimates of the session
    if ~isempty(StartStop_Times_Probe)
        ifQualifiedStart = StartStop_Times_Probe(:,1)<target_delay & StartStop_Times_Probe(:,2)>target_delay; % avoid using trials when the animal took long breaks
        % mean of startTime stopTime Middle Spread
        qSSMS = StartStop_Times_Probe(ifQualifiedStart,:);
        mStartStop_Times_Probe = mean(qSSMS,1,'omitnan');
        % mean of pokeRateAll/pokeRateRun
        qPokeRateAll = PokeRate_Trial_Probe(ifQualifiedStart);
        qPokeRateRun = PokeRate_StartStop_Probe(ifQualifiedStart);
        mPokeRateAll = mean(qPokeRateAll,'omitnan');
        mPokeRateRun = mean(qPokeRateRun,'omitnan');
        % 95CI
        if sum(ifQualifiedStart)>1 % there should be more than 1 qualified trials
            ciSSMS = bootci(nboot,@(x)mean(x,1,'omitnan'),qSSMS);
            ciPokeRateAll = bootci(nboot,@(x)mean(x,'omitnan'),qPokeRateAll);
            ciPokeRateRun = bootci(nboot,@(x)mean(x,'omitnan'),qPokeRateRun);
        else
            ciSSMS = nan(2,4);
            ciPokeRateAll = nan(2,1);
            ciPokeRateRun = nan(2,1);
            mStartStop_Times_Probe = nan(1,4);
            mPokeRateAll = NaN;
            mPokeRateRun = NaN;
        end
    else
        ifQualifiedStart = [];
        ciSSMS = nan(2,4);
        ciPokeRateAll = nan(2,1);
        ciPokeRateRun = nan(2,1);
        mStartStop_Times_Probe = nan(1,4);
        mPokeRateAll = NaN;
        mPokeRateRun = NaN;
    end
%% Plot Daily Performance
    limXTime = [0 maxT];
    
    if ifPlot
        hf = figure(1); clf(hf);
        set(hf, 'unit', 'centimeters', 'position',[2 2 8 20], 'paperpositionmode', 'auto',...
            'renderer','Painters');
    
        subplot(4, 1, 1)
        if ~isempty(Hist_Times_Rewarded)
            if ~ifSplitR
                bar(edges, mean(Hist_Times_Rewarded, 1),'EdgeColor','none');
                hold on
                line([target_delay target_delay], get(gca, 'ylim'), 'color', 'r', 'linewidth', 1)
                set(gca, 'xlim', limXTime);
                ylabel('Pokes / s');
                text(diff(xlim)*99/100, diff(ylim)*9/10, ['reward trials: ' num2str(n_rewards)], 'fontname', 'arial', 'fontsize', 10, 'HorizontalAlignment','right');
            else
                hb = bar(edges, [sum(Hist_Times_FI, 1); sum(Hist_Times_NS,1)],'stacked');
                hold on
                line([target_delay target_delay], get(gca, 'ylim'), 'color', 'r')
                set(gca, 'xlim', limXTime);
                ylabel('Poke times');
                le = legend(hb,{'Fixed Interval','Before Switch'},'location','northeast');
                le.ItemTokenSize(1) = 10;
                legend('boxoff');
                text(diff(xlim)*97/100, diff(ylim)*10/15, ['FI trials: ' num2str(n_fi)], 'fontname', 'arial', 'fontsize', 10, 'HorizontalAlignment','right');
                text(diff(xlim)*97/100, diff(ylim)*8/15, ['BS trials: ' num2str(n_ns)], 'fontname', 'arial', 'fontsize', 10, 'HorizontalAlignment','right');
            end
        end
        title(strrep(Dates{thisday}, '_', '-'), 'fontname','arial','fontsize', 9,'fontweight', 'bold')
    
        subplot(4, 1, 2)
        set(gca, 'xlim', limXTime, 'ylim', [0 length(Port_Times_Probe)+1],'nextplot', 'add')
        % plot rasters
        for i =1:length(Port_Times_Probe)
            i_Time_Probe = Port_Times_Probe{i};
            i_Time_Probe(i_Time_Probe<0) = [];
            i_LeverTime_Probe = round(Lever_Times_Probe{i},1);
            i_LeverTime_Probe(i_LeverTime_Probe<0) = [];
            i_TrialEnd_Probe = TrialEnd_Times_Probe{i};
            xx = [i_Time_Probe; i_Time_Probe];
            xx_lever = [i_LeverTime_Probe; i_LeverTime_Probe];
            xx_trialend = [i_TrialEnd_Probe; i_TrialEnd_Probe];
            xx_s1 = [StartStop_Times_Probe(i,1); StartStop_Times_Probe(i,1)];
            xx_s2 = [StartStop_Times_Probe(i,2); StartStop_Times_Probe(i,2)];
            yy = [i-1; i];
            if ~isempty(xx)
                line(xx, yy, 'color', 'k', 'linewidth', 1)
                hold on
                line(xx_s1, yy, 'color', 'm', 'linewidth', 1)
                line(xx_s2, yy, 'color', 'g', 'linewidth', 1)
                if ~ifClean
                    line(xx_lever, yy, 'color', "#4DBEEE", 'linewidth', 1)
                    text(diff(xlim)*1/100, diff(ylim)*105/100, 'Leverpress', 'Color', "#4DBEEE", 'fontname', 'arial', 'fontsize', 10, 'HorizontalAlignment','left');
                    line(xx_trialend, yy, 'color', "#D95319", 'linewidth', 1)
                    text(diff(xlim)*99/100, diff(ylim)*105/100, 'TrialEnd', 'Color', "#D95319", 'fontname', 'arial', 'fontsize', 10, 'HorizontalAlignment','right');
                end
            end
        end
        ylabel('# Probe trial')
    
        if ~isempty(Hist_Times_Probe)
            subplot(4, 1, 3)
            
            if man==0
                Times_Saline = [Times_Saline; Hist_Times_Probe];
                SSMS_Saline = [SSMS_Saline; mStartStop_Times_Probe];
            elseif man==1
                Times_DCZ = [Times_DCZ; Hist_Times_Probe];
                SSMS_DCZ = [SSMS_DCZ; mStartStop_Times_Probe];
            end
    
            histo_smoothed = mean(Hist_Times_Probe, 1);
            plot(edges, histo_smoothed, 'LineWidth', 1);
            hold on
            set(gca, 'xlim', limXTime,'ylim', [0 max(4, max(histo_smoothed))], 'nextplot', 'add')
            xl = xlim; yl = ylim;
    
            line([target_delay target_delay], yl, 'color', 'r', 'linewidth', 1)
            line([mStartStop_Times_Probe(1) mStartStop_Times_Probe(1)], yl, 'lineStyle' , '--', 'color', 'm', 'linewidth', 1);
            line([mStartStop_Times_Probe(2) mStartStop_Times_Probe(2)], yl, 'lineStyle' , '--', 'color', 'g', 'linewidth', 1);

            text(diff(xl)*97/100, diff(yl)*9/10, ['probe trials: ' num2str(n_probe)], 'fontname', 'arial', 'fontsize', 10, 'HorizontalAlignment','right')
            text(mStartStop_Times_Probe(1), diff(yl)*18/17, ['S1=' num2str(mStartStop_Times_Probe(1),'%.1f')],'fontname','Arial','fontsize', 8, 'HorizontalAlignment','center');
            text(mStartStop_Times_Probe(2), diff(yl)*18/17, ['S2=' num2str(mStartStop_Times_Probe(2),'%.1f')],'fontname','Arial','fontsize', 8, 'HorizontalAlignment','center');
            text(diff(xl)*70/100, diff(yl)*14/12, ['middle=' num2str(mStartStop_Times_Probe(3),'%.1f')],'fontname','Arial','fontsize', 8, 'HorizontalAlignment','right');
            text(diff(xl)*99/100, diff(yl)*14/12, ['spread=' num2str(mStartStop_Times_Probe(4),'%.1f')],'fontname','Arial','fontsize', 8, 'HorizontalAlignment','right');
            
            % xlabel('Time since lever press')
            ylabel('Pokes / s')
            
            
            subplot(4, 1, 4);
            if sum(ifQualifiedStart)>1
                HistStart = ksdensity(StartStop_Times_Probe(ifQualifiedStart,1),edges,'Bandwidth',ksBW);
                HistStop = ksdensity(StartStop_Times_Probe(ifQualifiedStart,2),edges,'Bandwidth',ksBW);
                HistMiddle = ksdensity(StartStop_Times_Probe(ifQualifiedStart,3),edges,'Bandwidth',ksBW);
                HistSpread = ksdensity(StartStop_Times_Probe(ifQualifiedStart,4),edges,'Bandwidth',ksBW);
                
                % HistStart = ksdensity(StartStop_Times_Probe(:,1),edges,'Bandwidth',ksBW);
                % HistStop = ksdensity(StartStop_Times_Probe(:,2),edges,'Bandwidth',ksBW);
                % HistMiddle = ksdensity(StartStop_Times_Probe(:,3),edges,'Bandwidth',ksBW);
                % HistSpread = ksdensity(StartStop_Times_Probe(:,4),edges,'Bandwidth',ksBW);
    
                h_s1 = plot(edges, HistStart, 'm', 'LineWidth', 1);
                hold on;
                h_s2 = plot(edges, HistStop, 'g', 'LineWidth', 1);
                h_mid = plot(edges, HistMiddle, 'r', 'LineWidth', 1.5);
                h_sp = plot(edges, HistSpread, 'k--', 'LineWidth', 1);
                xlim(limXTime)
                ylabel('PDF');
                xlabel('Time / s')
    
                le = legend([h_s1 h_s2 h_mid h_sp],{'StartT','StopT','Middle','Spread'});
                le.ItemTokenSize = 12;
                legend('boxoff')
            end
        end
    
        if ifPrintDaily
            pathFigSave = fullfile(pwd,figSaveFolder);
            [~,~] = mkdir(pathFigSave);
            print(hf,fullfile(pathFigSave,['Fig_',thisfilename,suffix,'.png']),'-dpng','-r300')
        end
    end

    pdata = struct;
    pdata.ANM = char(ANM);
    pdata.Date = datechar;
    if man==1
        pdata.Treatment = options.treatmentName{2};
    elseif man==0
        pdata.Treatment = options.treatmentName{1};
    else
        pdata.Treatment = '';
    end
    pdata.Delay                 = target_delay;
    pdata.TrialType             = Trial_Type;
    pdata.RawData               = Raw_Events;
    pdata.nTrial.PI             = length(Port_Times_Probe);
    pdata.nTrial.Rewarded       = length(Port_Times_Rewarded);
    pdata.nTrial.FI             = length(Port_Times_FI);
    pdata.nTrial.NS             = length(Port_Times_NS);
    pdata.PokeTime.PI           = Port_Times_Probe;
    pdata.PokeTime.Rewarded     = Port_Times_Rewarded;
    pdata.PokeTime.FI           = Port_Times_FI;
    pdata.PokeTime.NS           = Port_Times_NS;
    pdata.PokeHist.PI           = Hist_Times_Probe;
    pdata.PokeHist.Rewarded     = Hist_Times_Rewarded;
    pdata.PokeHist.FI           = Hist_Times_FI;
    pdata.PokeHist.NS           = Hist_Times_NS;
    pdata.LeverTime.PI          = Lever_Times_Probe;
    pdata.TrialEndTime.PI       = TrialEnd_Times_Probe;
    pdata.idxGoodPI             = find(ifQualifiedStart);
    pdata.SSMS.Raw              = StartStop_Times_Probe; % StartTime, StopTime, Middle, Spread
    pdata.SSMS.Mean             = mStartStop_Times_Probe;
    pdata.SSMS.CI               = ciSSMS;
    pdata.PokeRate.PI.Raw       = PokeRate_Trial_Probe;
    pdata.PokeRate.PI.Mean      = mPokeRateAll;
    pdata.PokeRate.PI.CI        = ciPokeRateAll;
    pdata.PokeRate.ST2SP.Raw    = PokeRate_StartStop_Probe;
    pdata.PokeRate.ST2SP.Mean   = mPokeRateRun;
    pdata.PokeRate.ST2SP.CI     = ciPokeRateRun;

    pdata.Options = options;
    
    if ifSaveData
        save(append('PData_',pdata.ANM,'_',pdata.Date,'_Delay',num2str(pdata.Delay),'.mat'),'pdata','-mat');
    end

    out{thisday} = pdata;
end
%% Summary Performance
if ifPlot && ~isempty(Times_Saline)
    h = figure(31); clf(h);
    set(h, 'unit', 'centimeters', 'position',[2 2 10 10], 'paperpositionmode', 'auto',...
    'renderer','Painters');
    % Times_Saline    = Times_Saline;
    % Times_DCZ       = Times_DCZ;
    hLine = [];
    hLine(1) = plotSummary(treatName{1},Times_Saline,SSMS_Saline,{'#021526','#E2E2B6'},'-');
    if ~isempty(Times_DCZ)
        hLine(end+1) = plotSummary(treatName{2},Times_DCZ,SSMS_DCZ,{'#3572ef','#a7e6ff'},'-.');
    end
    xlabel('Time (s)')
    ylabel('Pokes/s')
    title([ANM suffix])
    legend(hLine,treatName);
    legend('boxoff');
    
    if ifPrintSummary
        tosavename = fullfile(pwd,figSaveFolder, ['PeakIntervalResult_' ANM suffix]);
        print(h,'-dpng', tosavename)
    %     tosavename = fullfile(GetParentFolder(pwd), ['PeakIntervalResult_' ANM suffix]);
        tosavename = fullfile(pwd, ['PeakIntervalResult_' ANM suffix]);
        print(h,'-dpng', tosavename)
    end
end

function h_line = plotSummary(Name_Manipu,Times_Saline,SSMS_Saline,colors,linestyle)
    Times_Saline_mean = smoothdata(mean(Times_Saline), 'gaussian', 15);
    if size(Times_Saline,1)>2
        Times_Saline_ci = smoothdata(bootci(1000, @mean, Times_Saline), 2, 'gaussian', 15);
    else
        disp(['Samples of the ' Name_Manipu ' was less than 3. Using sem instead of 95ci\n']);
        Times_Saline_ci = repmat(smoothdata(std(Times_Saline,1)./sqrt(size(Times_Saline,1)),2,'gaussian',15),[2 1]).*[-1; 1]+Times_Saline_mean;
    end 
    peak_saline = max(Times_Saline_mean);
    
    [Width_Saline,hfPkRise,hfPkFall] = myFWHM(edges,Times_Saline_mean,'minPeakDistance',5);

    line([hfPkRise hfPkFall], peak_saline*0.5*[1 1], 'color', 'r','linestyle',linestyle);
    fprintf(['Width at half peak (' Name_Manipu ') is %2.2f\n'], Width_Saline)
    fprintf(['Midpoint of half peak (' Name_Manipu ') is %2.2f\n'], mean([hfPkRise hfPkFall],'all'))

    ind_plot = find(~isnan(Times_Saline_ci(1, :)));
    plotshaded(edges(ind_plot), Times_Saline_ci(:, ind_plot), hex2rgb(colors{2})); hold on
    h_line = plot(edges, Times_Saline_mean, 'color', colors{1}, 'linewidth', 1.5);
    
    % Plot Start & Stop Times
    ylm = [0 peak_saline];
    SSMS_Saline_mean = mean(SSMS_Saline,1);
%         SSMS_Saline_ci = bootci(1000,@(x)mean(x,1,'omitnan'),SSMS_Saline);
%         plotshaded([SSMS_Saline_ci(1,1) SSMS_Saline_ci(2,1) ],[ylm(1) ylm(1); ylm(2) ylm(2)],hex2rgb(colors{1}),0.05) % Start
%         plotshaded([SSMS_Saline_ci(1,2) SSMS_Saline_ci(2,2) ],[ylm(1) ylm(1); ylm(2) ylm(2)],hex2rgb(colors{1}),0.05) % Stop
%         line([SSMS_Saline_mean(1) SSMS_Saline_mean(1)],ylm,'color',hex2rgb(colors{1}),'linestyle',linestyle,'linewidth',1); % StartTime
%         line([SSMS_Saline_mean(2) SSMS_Saline_mean(2)],ylm,'color',hex2rgb(colors{1}),'linestyle',linestyle,'linewidth',1); % StopTime
    fprintf(['Mean of start time (' Name_Manipu ') is %.2f\n'],SSMS_Saline_mean(1))
    fprintf(['Mean of stop time (' Name_Manipu ') is %.2f\n'],SSMS_Saline_mean(2))
    fprintf(['Mean of middle (' Name_Manipu ') is %.2f\n'],SSMS_Saline_mean(3))
    fprintf(['Mean of spread (' Name_Manipu ') is %.2f\n'],SSMS_Saline_mean(4))
end

end
