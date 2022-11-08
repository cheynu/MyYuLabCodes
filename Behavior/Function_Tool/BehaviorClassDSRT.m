classdef BehaviorClassDSRT
    % Unfinished

    properties

        Subject
        Strain
        Date
        Session
        Protocol
        LesionType
        LesionIndex
        TrialNum
        PressIndex
        PressTime
        ReleaseTime
        FP
        MixedFP
        ToneTime
        ReactionTime
        Outcome
        Experimenter

    end;

    properties (SetAccess = private)


    end

    properties (Constant)
        PerformanceType = {'Correct', 'Premature', 'Late'}
    end

    properties (Dependent)
        Performance
        AvgRT
        AvgRTLoose
    end

    methods
        function obj = BehaviorClass(bdata)
            %UNTITLED9 Construct an instance of this class
            %   Detailed explanation goes here
            % number of trials
            obj.TrialNum        =       length(bdata.PressTime);
            obj.PressIndex     =       [1:obj.TrialNum];

            % Session information
            obj.Subject         =       extractAfter(bdata.SessionName, 'Subject ');
            obj.Session        =       extractBefore(bdata.SessionName, '-Subject ');
            obj.Date             =        bdata.Metadata.Date;
            obj.Protocol       =        extractAfter(bdata.Metadata.ProtocolName, 'FR1_');

            % Press
            obj.PressTime = bdata.PressTime;
            obj.ReleaseTime = bdata.ReleaseTime;
            obj.ReactionTime = [];
            obj.ToneTime = [];
            obj.FP = bdata.FPs;
            obj.MixedFP = [500 1000 1500] ; % default, subject to change though.
            obj.Outcome = [];

            for i =1:length(bdata.PressTime)
                if ~isempty(find(bdata.Correct == i, 1))
                    obj.Outcome{i} = 'Correct';
                    % find tone time
                    obj.ToneTime(i) = bdata.TimeTone(find(bdata.TimeTone-bdata.PressTime(i)>0, 1, 'first'));
                    obj.ReactionTime(i) = obj.ReleaseTime(i) - obj.ToneTime(i);
                elseif  ~isempty(find(bdata.Premature == i, 1))
                    obj.Outcome{i} = 'Premature';
                    obj.ToneTime(i)= -1;
                    obj.ReactionTime(i) = -1;
                elseif ~isempty(find(bdata.Late == i, 1))
                    obj.Outcome{i} = 'Late';
                    obj.ToneTime(i) = bdata.TimeTone(find(bdata.TimeTone-bdata.PressTime(i)>0, 1, 'first'));
                    obj.ReactionTime(i) = obj.ReleaseTime(i) - obj.ToneTime(i);
                elseif ~isempty(find(bdata.Dark == i, 1))
                    obj.Outcome{i} = 'Dark';
                    obj.ToneTime(i)= 0;
                    obj.ReactionTime(i) = 0;
                else
                    obj.Outcome{i} = 'NAN';
                    obj.ToneTime(i)= 0;
                    obj.ReactionTime(i) = 0;
                end;
            end;

        end

        function obj = set.Experimenter(obj,person_name)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Experimenter = string(person_name);
        end

        function obj = set.LesionType(obj,lesiontype)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.LesionType = string(lesiontype);
        end

        function obj = set.Strain(obj,strain)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Strain = string(strain);
        end


        function obj = set.MixedFP(obj, FPs)
            % compute mixed FP
            if isnumeric(FPs)
                obj.MixedFP = FPs;
            end;
        end

        function value = get.Performance(obj)

            Foreperiod          =       [num2cell(obj.MixedFP) 'all']';
            N_press               =        zeros(length(Foreperiod), 1);
            CorrectRatio        =       zeros(length(Foreperiod), 1);
            PrematureRatio  =       zeros(length(Foreperiod), 1);
            LateRatio              =       zeros(length(Foreperiod), 1);

            for i = 1:length(obj.MixedFP)
                n_correct                =       sum(obj.FP == obj.MixedFP(i) & strcmp(obj.Outcome, 'Correct'));
                n_premature          =       sum(obj.FP == obj.MixedFP(i) & strcmp(obj.Outcome, 'Premature'));
                n_late                      =       sum(obj.FP == obj.MixedFP(i) & strcmp(obj.Outcome, 'Late'));
                n_legit                     =       n_correct+n_premature+n_late;
                N_press(i)               =       n_legit;

                CorrectRatio(i)  =  100*n_correct/n_legit;
                PrematureRatio(i)  =  100*n_premature/n_legit;
                LateRatio(i)  =  100*n_late/n_legit;
            end;

            % takes everything
            n_correct            =    sum(strcmp(obj.Outcome, 'Correct'));
            n_premature     =    sum(strcmp(obj.Outcome, 'Premature'));
            n_late                =    sum(strcmp(obj.Outcome, 'Late'));
            n_legit               =    n_correct+n_premature+n_late;
            i = i+1;
            N_press(i)               =       n_legit;
            CorrectRatio(i)  =  100*n_correct/n_legit;
            PrematureRatio(i)  =  100*n_premature/n_legit;
            LateRatio(i)  =  100*n_late/n_legit;
            rt_table = table(Foreperiod, N_press, CorrectRatio, PrematureRatio, LateRatio);
            value = rt_table;
        end

        function value = get.AvgRT(obj)
            % Use calRT to compute RT
            RT.median=[];
            RT.median_ksdensity=[];
            N_press = [];

            for i = 1:length(obj.MixedFP)
                iFP = obj.MixedFP(i);
                ind_press = find(obj.FP == obj.MixedFP(i) & strcmp(obj.Outcome, 'Correct'));
                HoldDurs = 1000*(obj.ReleaseTime(ind_press) - obj.PressTime(ind_press)); % turn it into ms
                iRTOut = calRT(HoldDurs, iFP, 'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
                N_press(i) = length(HoldDurs);
                RT.median(i) = iRTOut.median;
                RT.median_ksdensity(i) = iRTOut.median_ksdensity;
            end;

            iFP = 'all';
            i=i+1;
            ind_press        =          find(strcmp(obj.Outcome, 'Correct'));
            FPs                   =           obj.FP(ind_press);
            HoldDurs        =           1000*(obj.ReleaseTime(ind_press) - obj.PressTime(ind_press)); % turn it into ms

            iRTOut = calRT(HoldDurs, FPs, 'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);

            N_press(i) = length(HoldDurs);
            RT.median(i) = iRTOut.median;
            RT.median_ksdensity(i) = iRTOut.median_ksdensity;

            Foreperiod = [num2cell(obj.MixedFP'); {'all'}];
            RT_median = RT.median';
            RT_median_ksdensity = RT.median_ksdensity';
            N_press = N_press';
            rt_table = table(Foreperiod, N_press, RT_median, RT_median_ksdensity);
            value = rt_table;
        end


        function value = get.AvgRTLoose(obj)
            % Use calRT to compute RT
            RT.median=[];
            RT.median_ksdensity=[];
            N_press = [];
            for i = 1:length(obj.MixedFP)
                iFP = obj.MixedFP(i);
                ind_press = find(obj.FP == obj.MixedFP(i) & (strcmp(obj.Outcome, 'Correct') | strcmp(obj.Outcome, 'Late')));
                HoldDurs = 1000*(obj.ReleaseTime(ind_press) - obj.PressTime(ind_press)); % turn it into ms
                iRTOut = calRT(HoldDurs, iFP, 'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
                N_press(i) = length(HoldDurs);
                RT.median(i) = iRTOut.median;
                RT.median_ksdensity(i) = iRTOut.median_ksdensity;
            end;

            iFP = 'all';
            i=i+1;
            ind_press        =          find(strcmp(obj.Outcome, 'Correct')|strcmp(obj.Outcome, 'Late'));
            FPs                   =           obj.FP(ind_press);
            HoldDurs        =           1000*(obj.ReleaseTime(ind_press) - obj.PressTime(ind_press)); % turn it into ms

            iRTOut = calRT(HoldDurs, FPs, 'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
            N_press(i) = length(HoldDurs);
            RT.median(i) = iRTOut.median;
            RT.median_ksdensity(i) = iRTOut.median_ksdensity;
            Foreperiod = [num2cell(obj.MixedFP'); {'all'}];
            RT_median = RT.median';
            RT_median_ksdensity = RT.median_ksdensity';
            N_press = N_press';
            rt_table = table(Foreperiod, N_press, RT_median, RT_median_ksdensity);
            value = rt_table;
        end

        function save(obj, savepath)
            if nargin<2
                savepath = pwd;
                save(fullfile(savepath, ['BClass_' upper(obj.Subject)  '_' [strrep(obj.Session(1:10), '-', '') '_' obj.Session(12:end)]]),  'obj');
            end
        end

        function print(obj, targetDir)
            savename = ['BClass_' upper(obj.Subject)  '_' [strrep(obj.Session(1:10), '-', '') '_' obj.Session(12:end)]];

            if nargin==2
                % check if targetDir exists
                if ~contains(targetDir, '/') && ~contains(targetDir, '\')
                    % so it is a relative path
                    if ~exist(targetDir, 'dir')
                        mkdir(targetDir)
                    end;
                end;
                savename = fullfile(targetDir, savename)
            end;

            hf = 20;
            print (hf,'-dpdf', [savename], '-bestfit')
            print (hf,'-dpng', [savename])
            saveas(hf, savename, 'fig')
        end;

        function plot(obj)
            try
                set_matlab_default
            catch
                disp('You do not have "set_matlab_default"' )
            end
            % plot the entire session
            col_perf = [85 225 0
                255 0 0
                140 140 140]/255;

            figure(20); clf(20)
            set(gcf, 'unit', 'centimeters', 'position',[2 2 15 15], 'paperpositionmode', 'auto', 'color', 'w')

            plotsize1 = [6, 3.5];
            plotsize2 = [3, 3.5];

            uicontrol('Style', 'text', 'parent', 20, 'units', 'normalized', 'position', [0.1 0.95 0.5 0.04],...
                'string', [obj.Subject ' / ' obj.Session], 'fontweight', 'bold', 'backgroundcolor', [1 1 1]);

            ha1 = axes;
            set(ha1, 'units', 'centimeters', 'position', [2 10.5, plotsize1], 'nextplot', 'add', 'ylim', [0 2500], 'xlim', [1 3600], 'yscale', 'linear')
            xlabel('Time in session (sec)')
            ylabel('Press duration (msec)')

            % plot press times
            line([obj.PressTime; obj.PressTime], [0 250], 'color', 'b')

            ind_premature_presses = strcmp(obj.Outcome, 'Premature');
            scatter(obj.ReleaseTime(ind_premature_presses), ...
                1000*(obj.ReleaseTime(ind_premature_presses) - obj.PressTime(ind_premature_presses)), ...
                25, col_perf(2, :), 'o','Markerfacealpha', 0.8, 'linewidth', 1.05);

            ind_late_presses = strcmp(obj.Outcome, 'Late');
            LateDur =   1000*(obj.ReleaseTime(ind_late_presses) - obj.PressTime(ind_late_presses));
            LateDur(LateDur>2500) = 2499;
            scatter(obj.ReleaseTime(ind_late_presses), LateDur, ...
                25, col_perf(3, :), 'o', 'Markerfacealpha', 0.8, 'linewidth', 1.05);

            ind_dark_presses = strcmp(obj.Outcome, 'Dark');
            scatter(obj.ReleaseTime(ind_dark_presses), ...
                1000*(obj.ReleaseTime(ind_dark_presses) - obj.PressTime(ind_dark_presses)), ...
                15, 'k', 'o', 'Markerfacealpha', 0.8, 'linewidth', 1.05);

            ind_good_presses = strcmp(obj.Outcome, 'Correct');
            scatter(obj.ReleaseTime(ind_good_presses), ...
                1000*(obj.ReleaseTime(ind_good_presses) - obj.PressTime(ind_good_presses)), ...
                25, col_perf(1, :), 'o', 'Markerfacealpha', 0.8, 'linewidth', 1.05);

            hainfo=axes;
            set(hainfo, 'units', 'centimeters', 'position', [10+plotsize2(1)+0.25 1, 2 plotsize2(2)], ...
                'xlim', [1.95 10], 'ylim', [0 9], 'nextplot', 'add');

            plot(2, 8, 'o', 'linewidth', 1, 'color', col_perf(1, :),'markerfacecolor', col_perf(1, :));
            text(3, 8, 'Correct', 'fontsize', 8);
            plot(2, 7, 'o', 'linewidth', 1, 'color', col_perf(2, :),'markerfacecolor', col_perf(2, :));
            text(3, 7, 'Premature', 'fontsize', 8);
            plot(2, 6 , 'o', 'linewidth', 1,'color', col_perf(3, :),'markerfacecolor', col_perf(3, :));
            text(3, 6, 'Late', 'fontsize', 8);

            plot(2, 5, 'ko', 'linewidth', 1,'markerfacecolor', 'k');
            text(3, 5, 'Dark', 'fontsize', 8);

            axis off

            % Plot reaction time
            ha2 = axes;
            set(ha2,  'units', 'centimeters', 'position', [2 5.5, plotsize1], 'nextplot', 'add', 'ylim', [0 1000], 'xlim', [1 3600], 'yscale', 'linear')
            % late in red
            lateRT =  1000*obj.ReactionTime(ind_late_presses);
            lateRT(lateRT>1000) = 999;
            scatter(obj.ToneTime(ind_late_presses), lateRT, ...
                25, col_perf(3, :), 'o', 'Markerfacealpha', 0.8, 'linewidth', 1.05);
            scatter(obj.ToneTime(ind_good_presses), 1000*obj.ReactionTime(ind_good_presses), ...
                25, col_perf(1, :), 'o', 'Markerfacealpha', 0.8, 'linewidth', 1.05);

            xlabel ('Time in session (s)')
            ylabel ('Reaction time (ms)')

            % Plot performance score
            % Define size of sliding window
            ha3 = axes;
            set(ha3,  'units', 'centimeters', 'position', [2 1, plotsize1], 'nextplot', 'add', 'ylim', [0 100], 'xlim', [1 3600], 'yscale', 'linear')
            WinSize = floor(obj.TrialNum/5);
            StepSize = max(1, floor(WinSize/5));

            CountStart = 1;
            thisWin = [];

            WinPos = [];
            CorrectRatio=[];
            PrematureRatio=[];
            LateRatio=[];
            while CountStart+WinSize < obj.TrialNum

                thisWin = [CountStart:CountStart + WinSize];
                thisOutcome = obj.Outcome(thisWin);
                CorrectRatio =[CorrectRatio 100*sum(strcmp(thisOutcome, 'Correct'))/length(thisOutcome)];
                PrematureRatio = [PrematureRatio 100*sum(strcmp(thisOutcome, 'Premature'))/length(thisOutcome)];
                LateRatio = [LateRatio, 100*sum(strcmp(thisOutcome, 'Late'))/length(thisOutcome)];
                WinPos = [WinPos obj.PressTime(round(median(thisWin)))];
                CountStart = CountStart + StepSize;
            end;

            plot(WinPos, CorrectRatio, 'o', 'linestyle', '-', 'color', col_perf(1, :), ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', col_perf(1, :), 'markeredgecolor', 'w');
            plot(WinPos, PrematureRatio, 'o', 'linestyle', '-', 'color', col_perf(2, :), ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', col_perf(2, :), 'markeredgecolor', 'w');
            plot(WinPos, LateRatio, 'o', 'linestyle', '-', 'color', col_perf(3, :), ...
                'markersize', 5, 'linewidth', 1, 'markerfacecolor', col_perf(3, :), 'markeredgecolor', 'w');

            xlabel('Time in session (sec)')
            ylabel('Performance')

            ha3 = axes; %
            set(ha3,'units', 'centimeters', 'position', [10, 1, plotsize2], 'nextplot', 'add', 'ylim', [0 1000], 'xlim', [0 5], 'xtick', [])
            hb1=bar([1], (sum(ind_good_presses)));
            set(hb1, 'EdgeColor', 'none', 'facecolor',col_perf(1, :), 'linewidth', 2);
            hb2=bar([2], (sum(ind_premature_presses)));
            set(hb2, 'EdgeColor',  'none', 'facecolor', col_perf(2, :), 'linewidth', 2);
            hb2=bar([3], (sum(ind_late_presses)));
            set(hb2, 'EdgeColor',  'none', 'facecolor',col_perf(3, :), 'linewidth', 2);
            hb3=bar([4], (sum(ind_dark_presses)));
            set(hb3, 'EdgeColor',  'none', 'facecolor', 'k', 'linewidth', 2);
            axis 'auto y'

            ylabel('Number')
            %                 legend('Correct', 'Premature', 'Late', 'Dark', 'Location', 'best')

            % Plot performance for different FPs
            ha4 = axes;
            set(ha4,'units', 'centimeters', 'position', [10, 5.5, plotsize2], 'nextplot', 'add', 'ylim', [0 100], ...
                'xlim', [-0.5 12], 'xtick', [2, 6, 10], 'xticklabel', num2cell(obj.MixedFP),...
                'xticklabelrotation', 30);

            for i =1:length(obj.MixedFP)
                bar(1+4*(i-1), obj.Performance.CorrectRatio(i), ...
                    'Edgecolor', 'none','Facecolor', col_perf(1, :), 'linewidth', 1);
                bar(2+4*(i-1), obj.Performance.PrematureRatio(i), ...
                    'Edgecolor', 'none', 'Facecolor', col_perf(2, :), 'linewidth', 1);
                bar(3+4*(i-1), obj.Performance.LateRatio(i), ...
                    'Edgecolor', 'none','Facecolor', col_perf(3, :), 'linewidth', 1);
            end;

            title('Performance|FP', 'fontweight', 'normal')
            ylabel('Performance (%)')

            % plot reaction time
            ha5 = axes;
            set(ha5,'units', 'centimeters', 'position', [10, 10.5, plotsize2], 'nextplot', 'add', ...
                'ylim', [100 500], ...
                'xlim', [obj.MixedFP(1)-100 obj.MixedFP(end)+100], 'xtick', obj.MixedFP, 'xticklabel', num2cell(obj.MixedFP),...
                'xticklabelrotation', 0);

            plot(cell2mat(obj.AvgRTLoose.Foreperiod(1:end-1)), obj.AvgRTLoose.RT_median_ksdensity(1:end-1), ...
                'ko', 'linestyle', '-', 'linewidth', 1, 'color', [0.2 0.2 0.2], 'markerfacecolor', 'k', ...
                'markersize', 8, 'markeredgecolor', 'w');

            plot(cell2mat(obj.AvgRTLoose.Foreperiod(1:end-1)), obj.AvgRT.RT_median_ksdensity(1:end-1), ...
                'k^', 'linestyle', '-', 'linewidth', 1, 'color', [0.2 0.2 0.2], 'markerfacecolor', [255 178 0]/255, ...
                'markersize', 7, 'markeredgecolor', 'w');

            if max(obj.AvgRTLoose.RT_median_ksdensity)>500
                set(ha5, 'ylim',[100 max(obj.AvgRTLoose.RT_median_ksdensity)+100]);
            end;
            legend('Loose', 'Strict')
            legend('boxoff')
            xlabel('Foreperiod (ms)')
            ylabel('Reaction time (ms)')
        end;
    end


end
