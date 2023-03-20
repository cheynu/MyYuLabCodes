classdef KornblumGroupClass
    % 11/8/2022, Jianing Yu
    % This takes kornblum class from each session, group them together,
    % mark each session with proper statement, and plot the data 


    properties

        Subject
        Sessions
        Strain
        Experimenter
        Protocols
        NumSessions
        NumTrialsPerSession
        Treatments_Sessions
        Doses_Sessions
        Treatments
        Doses
        Cue

        PressIndex
        PressTime
        ReleaseTime
        HoldTime
        FP
        MixedFP
        ToneTime
        ReactionTime
        Outcome
        Stage
        RTbinCenters
        HoldTbinCenters
        PerformanceSlidingWindow
        PerformanceOverSessions

        Control

    end;

    properties (SetAccess = private)

    end

    properties (Constant)

        PerformanceType = {'Correct', 'Premature', 'Late'}
        ToneTimeNotation = {'Any positive number, tone time for correct or late release'; 
            '0, FP ending for uncued correct or late release'; 
            'NaN, premature or dark trials'}
        RTbinEdges = [0:0.05:2]; 
        HoldTbinEdges = [0:0.05:4];
        RTCeiling = 5; % RTs over 5 sec will be removed
        ResponseWindow = [0.6 1]; % for cue and uncue trials. 
        GaussEqn = 'a1*exp(-((x-b1)/c1)^2)+a2*exp(-((x-b2)/c2)^2)';
        StartPoints = [1 1 1 2 2 1];
        LowerBound = [0 0 0 0 0 0];
        UpperBound = [10 10 10 10 10 10];

    end
    properties (Dependent)
        RT_Cue
        RT_Uncue
        HoldT_Cue
        HoldT_Uncue

        PDF_RT_Cue            
        CDF_RT_Cue    
        PDF_RT_Uncue    
        CDF_RT_Uncue   

        PDF_HoldT_Cue        
        PDF_HoldT_Cue_Gauss % using a gauss model to fit the data
        FWHM_HoldT_Cue % Full width at half maximum, derived from Gauss model
        CDF_HoldT_Cue   
        PDF_HoldT_Uncue  
        PDF_HoldT_Uncue_Gauss % using a gauss model to fit the data
        FWHM_HoldT_Uncue % Full width at half maximum, derived from Gauss model
        CDF_HoldT_Uncue    

        PerformanceTable
        FastResponseRatio
        IQR

       end


    methods
        function obj = KornblumGroupClass(KornblumClassAll)
            % KornblumClassAll is a collection of kornblum class from all
            % sessions for a rat
            obj.Subject                                        =                 unique(cellfun(@(x)x.Subject, KornblumClassAll, 'UniformOutput', false)');
            obj.Strain                                           =                 KornblumClassAll{1}.Strain; 
            obj.Sessions                                       =                 cellfun(@(x)x.Session, KornblumClassAll, 'UniformOutput', false)';
            obj.Experimenter                              =                cellfun(@(x)x.Experimenter, KornblumClassAll, 'UniformOutput', false)';            
            obj.Protocols                                      =                cellfun(@(x)x.Protocol, KornblumClassAll, 'UniformOutput', false)';            
            obj.NumSessions                               =                length(KornblumClassAll);
            obj.NumTrialsPerSession                  =                cellfun(@(x)x.TrialNum, KornblumClassAll);
            obj.Cue                                                 =                 cell2mat(cellfun(@(x)x.Cue, KornblumClassAll , 'UniformOutput', false));   
   
            for i =1:obj.NumSessions            

                obj.PressIndex                          =           [obj.PressIndex repmat(i, 1,   obj.NumTrialsPerSession(i))];
                obj.PressTime                           =           [obj.PressTime KornblumClassAll{i}.PressTime];
                obj.ReleaseTime                       =           [obj.ReleaseTime KornblumClassAll{i}.ReleaseTime];
                obj.HoldTime                            =           [obj.HoldTime KornblumClassAll{i}.HoldTime];
                obj.FP                                         =           [obj.FP KornblumClassAll{i}.FP];
                obj.MixedFP                              =           [obj.MixedFP KornblumClassAll{i}.MixedFP];
                obj.ToneTime                            =            [obj.ToneTime KornblumClassAll{i}.ToneTime];
                obj.ReactionTime                     =            [obj.ReactionTime KornblumClassAll{i}.ReactionTime];
                obj.Outcome                             =            [obj.Outcome;  KornblumClassAll{i}.Outcome'];
                obj.Stage                                   =            [obj.Stage KornblumClassAll{i}.Stage];
                obj.Treatments_Sessions        =             [obj.Treatments_Sessions KornblumClassAll{i}.Treatment];
                obj.Doses_Sessions                 =             [obj.Doses_Sessions KornblumClassAll{i}.Dose];
                obj.Treatments                        =             [obj.Treatments repmat(KornblumClassAll{i}.Treatment, 1, obj.NumTrialsPerSession(i))];
                obj.Doses                                =            [obj.Doses repmat(KornblumClassAll{i}.Dose, 1, obj.NumTrialsPerSession(i))];
                obj.PerformanceOverSessions{i} =         KornblumClassAll{i}.Performance;      

                iSlidingWindowTable  =           KornblumClassAll{i}.PerformanceSlidingWindow;
                iSlidingWindowTable.('Session') = repmat(i, size(iSlidingWindowTable, 1), 1);
                obj.PerformanceSlidingWindow = [obj.PerformanceSlidingWindow; iSlidingWindowTable];
                obj.Control = {'Saline', 'NaN'};

            end; 

            obj.RTbinCenters = mean([obj.RTbinEdges(1:end-1); obj.RTbinEdges(2:end)], 1);
            obj.HoldTbinCenters = mean([obj.HoldTbinEdges(1:end-1); obj.HoldTbinEdges(2:end)], 1);

        end

        function value = get.RT_Cue(obj)
            % Reaction time
            RTCue              =        cell(1, 2); % Saline, DCZ
            if sum(strcmp(obj.Control, 'NaN'))>0
                Ind_Cue_Control          =        ((strcmp(obj.Treatments, 'Saline')|strcmp(obj.Treatments, 'NaN')) & obj.Cue == 1 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late')) & obj.Stage == 1);
            else
                Ind_Cue_Control          =        (strcmp(obj.Treatments, 'Saline') & obj.Cue == 1 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late')) & obj.Stage == 1);
            end;
            Ind_Cue_DCZ                =        (strcmp(obj.Treatments, 'DCZ') & obj.Cue == 1 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late')) & obj.Stage == 1);
            RTCue{1}                        =          obj.ReactionTime(Ind_Cue_Control);
            RTCue{2}                        =          obj.ReactionTime(Ind_Cue_DCZ);
            value                               =          RTCue;
        end;

        function value = get.RT_Uncue(obj)
            % Reaction time
            RTUncue                             =        cell(1, 2); % Saline, DCZ
            if sum(strcmp(obj.Control, 'NaN'))>0
                Ind_Uncue_Control          =        ((strcmp(obj.Treatments, 'Saline')|strcmp(obj.Treatments, 'NaN')) & obj.Cue == 0 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late')) & obj.Stage == 1);
            else
                Ind_Uncue_Control          =        (strcmp(obj.Treatments, 'Saline') & obj.Cue == 0 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late')) & obj.Stage == 1);
            end;
            Ind_Uncue_DCZ                =        (strcmp(obj.Treatments, 'DCZ') & obj.Cue == 0 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late')) & obj.Stage == 1);
            RTUncue{1}                        =         obj.ReactionTime(Ind_Uncue_Control);
            RTUncue{2}                        =         obj.ReactionTime(Ind_Uncue_DCZ);
            value                                    =         RTUncue;
        end;

        function value = get.HoldT_Cue(obj)
            % Reaction time
            HoldTCue                            =          cell(1, 2); % Saline, DCZ
            if sum(strcmp(obj.Control, 'NaN'))>0
                Ind_Cue_Control               =          ((strcmp(obj.Treatments, 'Saline')|strcmp(obj.Treatments, 'NaN')) & obj.Cue == 1 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late') | strcmp(obj.Outcome, 'Premature')) & obj.Stage == 1);
            else
                Ind_Cue_Control               =          (strcmp(obj.Treatments, 'Saline') & obj.Cue == 1 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late') | strcmp(obj.Outcome, 'Premature')) & obj.Stage == 1);
            end;
            Ind_Cue_DCZ                      =         (strcmp(obj.Treatments, 'DCZ') & obj.Cue == 1 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late') | strcmp(obj.Outcome, 'Premature')) & obj.Stage == 1);
            HoldTCue{1}                        =         obj.HoldTime(Ind_Cue_Control);
            HoldTCue{2}                        =         obj.HoldTime(Ind_Cue_DCZ);
            value                                     =         HoldTCue;
        end;

        function value = get.HoldT_Uncue(obj)
            % Reaction time
            HoldTUncue                             =        cell(1, 2); % Saline, DCZ
            if sum(strcmp(obj.Control, 'NaN'))>0
            Ind_Uncue_Control                =        ((strcmp(obj.Treatments, 'Saline')|strcmp(obj.Treatments, 'NaN')) & obj.Cue == 0 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late') | strcmp(obj.Outcome, 'Premature')) & obj.Stage == 1);
            else
            Ind_Uncue_Control                =        (strcmp(obj.Treatments, 'Saline') & obj.Cue == 0 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late') | strcmp(obj.Outcome, 'Premature')) & obj.Stage == 1);
            end;
            Ind_Uncue_DCZ                      =        (strcmp(obj.Treatments, 'DCZ') & obj.Cue == 0 & transpose(strcmp(obj.Outcome, 'Correct') |strcmp(obj.Outcome, 'Late') | strcmp(obj.Outcome, 'Premature')) & obj.Stage == 1);
            HoldTUncue{1}                        =        obj.HoldTime(Ind_Uncue_Control);
            HoldTUncue{2}                        =        obj.HoldTime(Ind_Uncue_DCZ);
            value                                          =        HoldTUncue;
        end;

        function value = get.PDF_RT_Cue(obj)
            PDFOut = cell(1, length(obj.RT_Cue));
            for i =1:length(PDFOut)
                RT_Cue                                          =           obj.RT_Cue{i};
                if ~isempty(RT_Cue)
         %             RT_Cue(RT_Cue> obj.RTCeiling) =            [];
                    PDFOut{i}                                        =            ksdensity(RT_Cue, obj.RTbinEdges, 'function', 'pdf');
                else
                    PDFOut{i} = [];
                end;
            end;
            value = PDFOut;
        end;

        function value = get.CDF_RT_Cue(obj)
            CDFOut = cell(1, length(obj.RT_Cue));
            for i =1:length(CDFOut)
                RT_Cue                                          =           obj.RT_Cue{i};
                if ~isempty(RT_Cue)
           %           RT_Cue(RT_Cue> obj.RTCeiling) =            [];
                    CDFOut{i}                                        =            ksdensity(RT_Cue, obj.RTbinEdges, 'function', 'cdf');
                else
                    CDFOut{i}  = [];
                end;
            end;
            value = CDFOut;
        end;

        function value = get.PDF_RT_Uncue(obj)
            PDFOut = cell(1, length(obj.RT_Uncue));
            for i =1:length(PDFOut)
                RT_Uncue                                          =           obj.RT_Uncue{i};
                if ~isempty(RT_Uncue)
                    PDFOut{i}                                        =            ksdensity(RT_Uncue, obj.RTbinEdges, 'function', 'pdf');
                else
                    PDFOut{i}       = [];
                end;
            end;
            value = PDFOut;
        end;

        function value = get.CDF_RT_Uncue(obj)
            CDFOut = cell(1, length(obj.RT_Uncue));
            for i =1:length(CDFOut)
                RT_Uncue                                                                                          =           obj.RT_Uncue{i};
                if ~isempty(RT_Uncue)
                    RT_Uncue(RT_Uncue> obj.RTCeiling)                                           =            [];
                    CDFOut{i}                                                                                           =            ksdensity(RT_Uncue, obj.RTbinEdges, 'function', 'cdf');
                else
                    CDFOut{i}     = [];
                end;
            end;
            value = CDFOut;
        end;

        function value = get.PDF_HoldT_Cue(obj)
            PDFOut = cell(1, length(obj.HoldT_Cue));
            for i =1:length(PDFOut)
                HoldT_Cue                                                                                           =           obj.HoldT_Cue{i};
                if ~isempty(HoldT_Cue)
                    PDFOut{i}                                                                                              =            ksdensity(HoldT_Cue, obj.HoldTbinEdges, 'function', 'pdf');
                else
                    PDFOut{i}  = [];
                end;
            end;
            value = PDFOut;
        end;

        function value = get.CDF_HoldT_Cue(obj)
            CDFOut = cell(1, length(obj.HoldT_Cue));
            for i =1:length(CDFOut)
                HoldT_Cue                                                                                                   =            obj.HoldT_Cue{i};
                if ~isempty(HoldT_Cue)
                    HoldT_Cue(HoldT_Cue> obj.RTCeiling+unique(obj.MixedFP))           =            [];
                    CDFOut{i}                                                                                                      =            ksdensity(HoldT_Cue, obj.HoldTbinEdges, 'function', 'cdf');
                else
                    CDFOut{i}   = [];
                end;
            end;
            value = CDFOut;
        end;

        function value = get.PDF_HoldT_Uncue(obj)
            PDFOut = cell(1, length(obj.HoldT_Uncue));
            for i =1:length(PDFOut)
                HoldT_Uncue                                                                                                     =           obj.HoldT_Uncue{i};
                if ~isempty(HoldT_Uncue)
                    PDFOut{i}                                                                                                            =            ksdensity(HoldT_Uncue, obj.HoldTbinEdges, 'function', 'pdf');
                else
                    PDFOut{i}  = [];
                end;
            end;
            value = PDFOut;
        end;

        function value = get.CDF_HoldT_Uncue(obj)
            CDFOut = cell(1, length(obj.HoldT_Uncue));
            for i =1:length(CDFOut)
                HoldT_Uncue                                                                                                     =           obj.HoldT_Uncue{i};
                if ~isempty(HoldT_Uncue)
                    CDFOut{i}                                                                                                            =            ksdensity(HoldT_Uncue, obj.HoldTbinEdges, 'function', 'cdf');
                else
                    CDFOut{i}     = [];
                end;
            end;
            value = CDFOut;
        end;

        function value = get.IQR(obj)
            Types = {'Cue_Saline'; 'Cue_DCZ'; 'Uncue_Saline'; 'Uncue_DCZ'};
            Cue  = zeros(1, length(obj.RT_Cue));
            for i =1:length(Cue)
                RT_Cue                                          =           obj.RT_Cue{i};
                if ~isempty(RT_Cue)
                    Cue(i)                                        =       diff(prctile(RT_Cue, [25 75]));
                end;
            end;
            Uncue  = zeros(1, length(obj.RT_Uncue));
            for i =1:length(Uncue)
                RT_Uncue                                          =           obj.RT_Uncue{i};
                if ~isempty(RT_Uncue)
                    Uncue(i)                                        =       diff(prctile(RT_Uncue, [25 75]));
                end;
            end;
            IQR = [Cue'; Uncue'];
            IQRTable = table(Types, IQR);
            value = IQRTable;
        end;

        function value = get.PDF_HoldT_Cue_Gauss(obj)
            x = obj.HoldTbinEdges;
            y =  obj.PDF_HoldT_Cue{1};
            f = fit(x', y',obj.GaussEqn, 'Start', obj.StartPoints, 'Lower', obj.LowerBound, 'Upper',obj.UpperBound);
            value{1}= f;
            if length(obj.PDF_RT_Cue)>1 && ~isempty(obj.PDF_RT_Cue{2})
                y =  obj.PDF_HoldT_Cue{2};
                f = fit(x', y',obj.GaussEqn, 'Start', obj.StartPoints, 'Lower', obj.LowerBound, 'Upper',obj.UpperBound);
                value{2}= f;
            end;
        end;

        function value = get.PDF_HoldT_Uncue_Gauss(obj)
            x = obj.HoldTbinEdges;
            y =  obj.PDF_HoldT_Uncue{1};
            f = fit(x', y',obj.GaussEqn, 'Start', obj.StartPoints, 'Lower', obj.LowerBound, 'Upper',obj.UpperBound);
            value{1}= f;
            if length(obj.PDF_RT_Uncue)>1 && ~isempty(obj.PDF_RT_Uncue{2})
                y =  obj.PDF_HoldT_Uncue{2};
                f = fit(x', y',obj.GaussEqn, 'Start', obj.StartPoints, 'Lower', obj.LowerBound, 'Upper',obj.UpperBound);
                value{2}= f;
            end;
        end;

        function value = get.FWHM_HoldT_Cue(obj)
            % compute FWHM based on the model
             xnew = [obj.HoldTbinEdges(1):0.001:obj.HoldTbinEdges(end)];
             f = obj.PDF_HoldT_Cue_Gauss{1};
             ynew = f(xnew);
             x_above = xnew(ynew>0.5*max(ynew));
             value(1) = x_above(end) - x_above(1);
             if length(obj.PDF_RT_Cue)>1 && ~isempty(obj.PDF_RT_Cue{2})
                 f = obj.PDF_HoldT_Cue_Gauss{2};
                 ynew = f(xnew);
                 x_above = xnew(ynew>0.5*max(ynew));
                 value(2) = x_above(end) - x_above(1);
             end;
        end;

        function value = get.FWHM_HoldT_Uncue(obj)
            % compute FWHM based on the model
            xnew = [obj.HoldTbinEdges(1):0.001:obj.HoldTbinEdges(end)];
            f = obj.PDF_HoldT_Uncue_Gauss{1};
            ynew = f(xnew);
            x_above = xnew(ynew>0.5*max(ynew));
            value(1) = x_above(end) - x_above(1);
            if length(obj.PDF_RT_Uncue)>1 && ~isempty(obj.PDF_RT_Uncue{2})
                f = obj.PDF_HoldT_Uncue_Gauss{2};
                ynew = f(xnew);
                x_above = xnew(ynew>0.5*max(ynew));
                value(2) = x_above(end) - x_above(1);
            end;
        end;

        function value = get.PerformanceTable(obj)
            %  Calculate performance
            OutcomeCount = {'All'; 'Correct'; 'Premature'; 'Late'}; % 'fast' means response within 1 second after tone
            CueUncueSal            =         zeros(4, 2); % 4: all, correct, premature, late; 1st col, cue trials, 2nd col, uncue,  saline
            CueUncueDCZ          =         zeros(4, 2); % 4: all, correct, premature, late; 1st col, cue trials, 2nd col, uncue,  DCZ
            CueTypes                   =         [1 0];           % cue, uncue
            P_CueUncue_Saline            =         zeros(4, 2); 
            P_CueUncue_DCZ                =         zeros(4, 2); 

            for k =1:length(CueTypes)

                n_correct                                  =       sum(strcmp(obj.Treatments, 'Saline') & strcmp(obj.Outcome', 'Correct')        & obj.Cue == CueTypes(k) & obj.Stage ==1);
                n_premature                            =       sum(strcmp(obj.Treatments, 'Saline') & strcmp(obj.Outcome', 'Premature')  & obj.Cue == CueTypes(k) & obj.Stage ==1);
                n_late                                        =       sum(strcmp(obj.Treatments, 'Saline') & strcmp(obj.Outcome', 'Late')              & obj.Cue == CueTypes(k) & obj.Stage ==1);
                n_legit                                       =       n_correct+n_premature+n_late;
                CueUncueSal(1, k)                   =           CueUncueSal(1, k) + n_legit;
                CueUncueSal(2, k)                   =           CueUncueSal(2, k) + n_correct;
                CueUncueSal(3, k)                   =           CueUncueSal(3, k) + n_premature;
                CueUncueSal(4, k)                   =           CueUncueSal(4, k) + n_late;
                P_CueUncue_Saline(:, k)        =            [1; CueUncueSal(2, k)/CueUncueSal(1, k); CueUncueSal(3, k)/CueUncueSal(1, k); CueUncueSal(4, k)/CueUncueSal(1, k)];

                n_correct                             =       sum(strcmp(obj.Treatments, 'DCZ') & strcmp(obj.Outcome', 'Correct')        & obj.Cue == CueTypes(k) & obj.Stage ==1);
                n_premature                       =       sum(strcmp(obj.Treatments, 'DCZ') & strcmp(obj.Outcome', 'Premature')  & obj.Cue == CueTypes(k) & obj.Stage ==1);
                n_late                                    =       sum(strcmp(obj.Treatments, 'DCZ') & strcmp(obj.Outcome', 'Late')              & obj.Cue == CueTypes(k) & obj.Stage ==1);
                n_legit                                   =       n_correct+n_premature+n_late;
                CueUncueDCZ(1, k)             =          CueUncueDCZ(1, k) + n_legit;
                CueUncueDCZ(2, k)             =          CueUncueDCZ(2, k) + n_correct;
                CueUncueDCZ(3, k)             =          CueUncueDCZ(3, k) + n_premature;
                CueUncueDCZ(4, k)             =          CueUncueDCZ(4, k) + n_late;
                P_CueUncue_DCZ(:, k)        =          [1; CueUncueDCZ(2, k)/CueUncueDCZ(1, k); CueUncueDCZ(3, k)/CueUncueDCZ(1, k); CueUncueDCZ(4, k)/CueUncueDCZ(1, k)];

            end;

            BehaviorTypes = {'OutcomeCount',...
                'N_Cue_Saline', 'Percent_Cue_Saline', ...
                'N_Cue_DCZ', 'Percent_Cue_DCZ',...
                'N_Uncue_Saline', 'Percent_Uncue_Saline', ...
                'N_Uncue_DCZ', 'Percent_Uncue_DCZ'};

            value = table(OutcomeCount, ...
                CueUncueSal(:, 1), P_CueUncue_Saline(:, 1),...
                CueUncueDCZ(:, 1), P_CueUncue_DCZ(:, 1), ...
                CueUncueSal(:, 2), P_CueUncue_Saline(:, 2), ...
                CueUncueDCZ(:, 2), P_CueUncue_DCZ(:, 2),...
                'VariableNames', BehaviorTypes);

        end

        function value = get.FastResponseRatio(obj)
            % ratio of responses within a time window after tone (only count post tone responses, excluding premature responses)
            vNames = {'Type', 'Ratio'};
            AllTypes = {'Cue_Saline'; 'Cue_DCZ'; 'Uncue_Saline'; 'Uncue_DCZ'};

            % Cue, Control
            iRT = obj.RT_Cue{1};
            Ratio_Cue_Control = sum(iRT>0.1 & iRT<=obj.ResponseWindow(1))/length(iRT);
            iRT = obj.RT_Cue{2};
            Ratio_Cue_DCZ = sum(iRT>0.1 & iRT<=obj.ResponseWindow(1))/length(iRT);
            iRT = obj.RT_Uncue{1};
            Ratio_Uncue_Control = sum(iRT>0.1 & iRT<=obj.ResponseWindow(2))/length(iRT);
            iRT = obj.RT_Uncue{2};
            Ratio_Uncue_DCZ = sum(iRT>0.1 & iRT<=obj.ResponseWindow(2))/length(iRT);
            Ratio = [Ratio_Cue_Control; Ratio_Cue_DCZ; Ratio_Uncue_Control; Ratio_Uncue_DCZ];

            value = table(AllTypes, Ratio, ...
                'VariableNames', vNames);

        end

        function outputArg = plot(obj)
            % Plot group data
            set_matlab_default;
            col_perf = [85 225 0
                255 0 0
                140 140 140]/255;
            FPColor = [189, 198, 184]/255;
            WhiskerColor = [132, 121, 225]/255;

            figure(20); clf(20)
            set(gcf, 'unit', 'centimeters', 'position',[2 2 28 19], 'paperpositionmode', 'auto', 'color', 'w')

            % Plot press duration across these sessions
            plotsize1 = [8, 3];
            plotsize4 = [4 3];
            plotsize5 = [2 3]; % for writing information
            plotsize6 = [5 3]; % for writing information
            plotsize3 = [2 3];
            StartTime = 0;
 
            ha(1) = axes;
            title('Cued trials', 'fontsize', 7, 'FontWeight', 'bold')
            xlevel = 2;
            ylevel = 19-plotsize1(2)-1.25;
            set(ha(1), 'units', 'centimeters', 'position', [xlevel, ylevel, plotsize1], 'nextplot', 'add', ...
                'ylim', [0 3500], 'yscale', 'linear')
            xlabel('Time in session (sec)')
            ylabel('Press duration (msec)')

            % Performance score, Cued
            xlevel = 2;
            ylevel2 = ylevel - plotsize1(2) - 1.25;

            ha(2) = axes;
            set(ha(2),  'units', 'centimeters', 'position', [xlevel, ylevel2, plotsize1], 'nextplot', 'add', ...
                'ylim', [-5 100], 'xlim', [0 obj.ReleaseTime(end)], 'yscale', 'linear')

            ylabel('Performance')

            %% Uncued trials
            ha(3) = axes;
            title('Uncued trials', 'fontsize', 7, 'FontWeight', 'bold')
            xlevel = 2;
            ylevel3 = ylevel2 - plotsize1(2) - 1.5;
            set(ha(3), 'units', 'centimeters', 'position', [xlevel, ylevel3, plotsize1], 'nextplot', 'add', ...
                'ylim', [0 3500], 'yscale', 'linear')
            xlabel('Time in session (sec)')
            ylabel('Press duration (msec)')

            % Performance score, Uncued
            xlevel = 2;
            ylevel4 = ylevel3 - plotsize1(2) - 1.25;
            ha(4) = axes;
            set(ha(4),  'units', 'centimeters', 'position', [xlevel, ylevel4, plotsize1], 'nextplot', 'add', ...
                'ylim', [-5 100], 'xlim', [0 obj.ReleaseTime(end)], 'yscale', 'linear')
            ylabel('Performance')
            title('Uncued trials', 'fontsize', 7, 'FontWeight', 'bold')

            % Press duration y range
            PressDurRange = [0, unique(obj.MixedFP)+1000];

            for i =1:obj.NumSessions
                iPressTimes                 =           obj.PressTime(obj.PressIndex ==i);
                iReleaseTimes             =           obj.ReleaseTime(obj.PressIndex ==i);
                iCue                               =           obj.Cue(obj.PressIndex == i);
                iOutcome                     =            [obj.Outcome(obj.PressIndex == i)]'; 
                iStage                            =            obj.Stage(obj.PressIndex == i);
                indPerformanceSliding   =       find(obj.PerformanceSlidingWindow.Session == i);

                set(ha(1), 'ylim', PressDurRange, 'xlim', [0 iReleaseTimes(end)+StartTime], 'yscale', 'linear');
                set(ha(3), 'ylim', PressDurRange, 'xlim', [0 iReleaseTimes(end)+StartTime], 'yscale', 'linear');
                set(ha(2), 'ylim', [-5 100], 'xlim', [0 iReleaseTimes(end)+StartTime], 'yscale', 'linear', 'xtick', []);
                set(ha(4), 'ylim', [-5 100], 'xlim', [0 iReleaseTimes(end)+StartTime], 'yscale', 'linear', 'xtick', []);

                line(ha(1), [iPressTimes(1) + StartTime iPressTimes(1) + StartTime], [0 3500], ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1);
                line(ha(3), [iPressTimes(1) + StartTime iPressTimes(1) + StartTime], [0 3500], ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1)

                % Shade DCZ trials
                if strcmp(obj.Treatments_Sessions{i}, 'DCZ')
                    axes(ha(1)) %#ok<LAXES>
                    plotshaded([iPressTimes(1) iReleaseTimes(end)]+StartTime, [0  0; PressDurRange(2) PressDurRange(2)], [255 203 66]/255)
                    axes(ha(2)) %#ok<LAXES>
                    plotshaded([iPressTimes(1) iReleaseTimes(end)]+StartTime, [0  0; 100 100], [255 203 66]/255)
                    axes(ha(3)) %#ok<LAXES>
                    plotshaded([iPressTimes(1) iReleaseTimes(end)]+StartTime, [0  0; PressDurRange(2) PressDurRange(2)], [255 203 66]/255)
                    axes(ha(4)) %#ok<LAXES>
                    plotshaded([iPressTimes(1) iReleaseTimes(end)]+StartTime, [0  0; 100 100], [255 203 66]/255)
                end

                % plot press times
                line(ha(1), [iPressTimes(iCue==1); iPressTimes(iCue==1)]+StartTime, [0; 250], 'color', 'b')
                % Plot premature responses
                % Cued
                ind_premature_presses = (strcmp(iOutcome, 'Premature') & iCue == 1 & iStage ==1);
                scatter(ha(1), iReleaseTimes(ind_premature_presses)+StartTime, ...
                    1000*(iReleaseTimes(ind_premature_presses) -iPressTimes(ind_premature_presses)), ...
                    8, col_perf(2, :), 'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','none');

                % Uncued
                line(ha(3), [iPressTimes(iCue==0); iPressTimes(iCue==0)]+StartTime, [0 250], 'color', 'b')
                ind_premature_presses = (strcmp(iOutcome, 'Premature') & iCue == 0 & iStage ==1);
                scatter(ha(3), iReleaseTimes(ind_premature_presses)+StartTime, ...
                    1000*(iReleaseTimes(ind_premature_presses) -iPressTimes(ind_premature_presses)), ...
                    8, col_perf(2, :), 'o','filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor', col_perf(2, :));

                % Plot late responses
                % Cued
                ind_late_presses = (strcmp(iOutcome, 'Late') & iCue == 1 & iStage ==1);
                LateDur =   1000*(iReleaseTimes(ind_late_presses) - iPressTimes(ind_late_presses));
                LateDur(LateDur>3500) = 3499;
                scatter(ha(1), iReleaseTimes(ind_late_presses)+StartTime, LateDur, ...
                    8, col_perf(3, :),  'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','none');
                % Uncued
                ind_late_presses = (strcmp(iOutcome, 'Late') & iCue == 0 & iStage ==1);
                LateDur =   1000*(iReleaseTimes(ind_late_presses) - iPressTimes(ind_late_presses));
                LateDur(LateDur>3500) = 3499;
                scatter(ha(3), iReleaseTimes(ind_late_presses)+StartTime, LateDur, ...
                    8, col_perf(3, :),  'o','filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor', col_perf(3, :));

                %  Plot dark responses
                % Cued
                ind_dark_presses = strcmp(iOutcome, 'Dark') & iCue == 1  & iStage ==1;
                scatter(ha(1), iReleaseTimes(ind_dark_presses)+StartTime, ...
                    1000*(iReleaseTimes(ind_dark_presses) - iPressTimes(ind_dark_presses)), ...
                    8, 'k',  'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','none');

                % Uncued
                ind_dark_presses = strcmp(iOutcome, 'Dark') & iCue == 0  & iStage ==1;
                scatter(ha(3), iReleaseTimes(ind_dark_presses)+StartTime, ...
                    1000*(iReleaseTimes(ind_dark_presses) - iPressTimes(ind_dark_presses)), ...
                    8, 'k',  'o','filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','k');

                % Plot correct responses
                % Cued
                ind_good_presses = strcmp(iOutcome, 'Correct') & iCue == 1  & iStage ==1;
                scatter(ha(1), iReleaseTimes(ind_good_presses)+StartTime, ...
                    1000*(iReleaseTimes(ind_good_presses) - iPressTimes(ind_good_presses)), ...
                    8, col_perf(1, :),   'o', 'filled','Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor','none');

                ind_good_presses = strcmp(iOutcome, 'Correct') & iCue == 0  & iStage ==1;
                scatter(ha(3), iReleaseTimes(ind_good_presses)+StartTime, ...
                    1000*(iReleaseTimes(ind_good_presses) - iPressTimes(ind_good_presses)), ...
                    8, col_perf(1, :),   'o','filled', 'Markerfacealpha', 0.6, 'linewidth', 0.5, 'MarkerEdgeColor',col_perf(1, :));

                % Plot performance indPerformanceSliding
                line(ha(2), [obj.PerformanceSlidingWindow.Time(indPerformanceSliding(1)) + StartTime obj.PerformanceSlidingWindow.Time(indPerformanceSliding(1)) + StartTime], [0 100], ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1);
                line(ha(4), [obj.PerformanceSlidingWindow.Time(indPerformanceSliding(1)) + StartTime obj.PerformanceSlidingWindow.Time(indPerformanceSliding(1)) + StartTime], [0 100], ...
                    'linestyle', ':' ,'color', [0.6 0.6 0.6],'linewidth', 1)

                plot(ha(2),  obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Correct_Cued(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(1, :))

                % add mean performance
                iCorrect = obj.PerformanceOverSessions{i}.Correct(obj.PerformanceOverSessions{i}.CueTypes==1);
                tSpan = [min(obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime) max(obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime)];
                line(ha(2), tSpan, [iCorrect iCorrect], 'color', col_perf(1, :), 'linewidth', 2);


                % add session time
                iSession = obj.Sessions{i}(5:10);
                iSession = strrep(iSession, '-', '');

                text(ha(2), obj.PerformanceSlidingWindow.Time(indPerformanceSliding(1)) + StartTime, -25, iSession , "fontname",'dejavu sans','FontSize',7,'FontWeight','bold','Color', ...
                    'k', 'Rotation', 25)
                text(ha(4), obj.PerformanceSlidingWindow.Time(indPerformanceSliding(1)) + StartTime, -25, iSession , "fontname",'dejavu sans','FontSize',7,'FontWeight','bold','Color', ...
                    'k', 'Rotation', 25)

                plot(ha(4),  obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Correct_Uncued(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(1, :))

                iCorrect = obj.PerformanceOverSessions{i}.Correct(obj.PerformanceOverSessions{i}.CueTypes==0);
                tSpan = [min(obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime) max(obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime)];
                line(ha(4), tSpan, [iCorrect iCorrect], 'color', col_perf(1, :), 'linewidth', 2);

                plot(ha(2),  obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Premature_Cued(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(2, :))
                plot(ha(4),  obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Premature_Uncued(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(2, :))

                plot(ha(2),  obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Late_Cued(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(3, :))
                plot(ha(4),  obj.PerformanceSlidingWindow.Time(indPerformanceSliding) + StartTime, ...
                    obj.PerformanceSlidingWindow.Late_Uncued(indPerformanceSliding), 'linewidth', 1, 'Color',col_perf(3, :))
                StartTime = iReleaseTimes(end) + StartTime;
            end;

            line(ha(1), [0 iReleaseTimes(end)+StartTime], [unique(obj.MixedFP)  unique(obj.MixedFP)], 'color', [0 0 0], 'linestyle', ':', 'linewidth', 1)
            line(ha(3), [0 iReleaseTimes(end)+StartTime], [unique(obj.MixedFP)  unique(obj.MixedFP)], 'color', [0 0 0], 'linestyle', ':', 'linewidth', 1)
 
            %% Plot reaction time distribution
            SalineColor = [90 90 90]/255;
            DCZColor     =  [255, 203, 66]/255;

            if length(obj.PDF_RT_Cue)>1 && ~isempty(obj.PDF_RT_Cue{2})
                TwoConditions = 1;
            else
                TwoConditions = 0;
            end;
   
            % Plot PDF, reaction time, cued trials
            ha5 = axes;
            xlevel2 = xlevel + plotsize1(1) + 1.5;
            set(ha5,'units', 'centimeters', 'position', [xlevel2, ylevel, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 1], ...
                'xlim', [0 2],'xtick', [0:4], ...
                'xticklabelrotation', 0, 'ticklength',[0.02 0.01]);

            maxPDF = 0;
            plot(obj.RTbinEdges, obj.PDF_RT_Cue{1}, 'color', SalineColor, 'linewidth', 1.25)
            plot(obj.RTbinEdges, obj.PDF_RT_Uncue{1}, 'color', SalineColor, 'linewidth', 1.25, 'LineStyle', '-.')
            maxPDF = max([maxPDF, max(obj.PDF_RT_Cue{1}), max(obj.PDF_RT_Uncue{1})]);
            if TwoConditions
                plot(obj.RTbinEdges, obj.PDF_RT_Cue{2}, 'color', DCZColor, 'linewidth', 1.25)
                plot(obj.RTbinEdges, obj.PDF_RT_Uncue{2}, 'color', DCZColor, 'linewidth', 1.25, 'LineStyle', '-.')
                maxPDF = max([maxPDF, max(obj.PDF_RT_Cue{2}), max(obj.PDF_RT_Uncue{2})]);
            end;

            xlabel('Reaction time (s)')
            ylabel('PDF (1/s)')
            set(gca, 'ylim', [0 maxPDF*1.1])

            % Plot CDF, reaction time, cued trials
            ha7 = axes;
            xlevel3 = xlevel2 + plotsize4(1) + 1.25;
            set(ha7,'units', 'centimeters', 'position', [xlevel3, ylevel, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 1], ...
                'xlim', [0 2], 'xtick', [0:4],...
                'xticklabelrotation', 0, 'ticklength',[0.02 0.01]);

            plot(obj.RTbinEdges, obj.CDF_RT_Cue{1}, 'color', SalineColor, 'linewidth', 1.25)
            plot(obj.RTbinEdges, obj.CDF_RT_Uncue{1}, 'color', SalineColor, 'linewidth', 1.25, 'LineStyle', '-.')

            if TwoConditions
                plot(obj.RTbinEdges, obj.CDF_RT_Cue{2}, 'color', DCZColor, 'linewidth', 1.25)
                plot(obj.RTbinEdges, obj.CDF_RT_Uncue{2}, 'color', DCZColor, 'linewidth', 1.25, 'LineStyle', '-.')
            end;

            xlabel('Reaction time (s)')
            ylabel('CDF')

            % Plot press duration distribution using violinplot
            ha8a = axes;
            xlevel4 = xlevel3 + plotsize4(1) + 1.5;
            set(ha8a,'units', 'centimeters', 'position', [xlevel4, ylevel, plotsize6], 'nextplot', 'add', ...
                'ylim', [0 2], ...
                'xlim', [0.5 4.5], 'xtick', [0:4],'xticklabel', {'Cue (Saline)', 'Cue (DCZ)', 'Uncue (Saline)', 'Uncue (DCZ)'},...
                'xticklabelrotation', 30, 'ticklength',[0.02 0.01]);
            ylabel('Reaction time (s)')

            if TwoConditions

                RTVec       =             [];
                RTType     =             [];
                RTVec         =           [RTVec obj.RT_Cue{1}];
                RTType       =             [RTType ones(1, length(obj.RT_Cue{1}))];
                RTVec         =           [RTVec obj.RT_Cue{2}];
                RTType       =             [RTType 2*ones(1, length(obj.RT_Cue{2}))];
                RTVec         =           [RTVec obj.RT_Uncue{1}];
                RTType       =             [RTType 3*ones(1, length(obj.RT_Uncue{1}))];
                RTVec         =           [RTVec obj.RT_Uncue{2}];
                RTType       =             [RTType 4*ones(1, length(obj.RT_Uncue{2}))];

                hVio = violinplot(RTVec,  RTType);
                for iv =1:length(hVio)
                    hVio(iv).EdgeColor = [0 0 0];
                    hVio(iv).WhiskerPlot.Color = WhiskerColor;
                    hVio(iv).WhiskerPlot.LineWidth = 1.5;
                end;

                hVio(1).ViolinColor = {SalineColor};
                % add outliers
                outliers_RT_Cue = find_outliers(obj.RT_Cue{1});
                if ~isempty(outliers_RT_Cue)
                    plot(1, outliers_RT_Cue, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end

                hVio(2).ViolinColor = {DCZColor};
                outliers_RT_CueDCZ = find_outliers(obj.RT_Cue{2});
                if ~isempty(outliers_RT_CueDCZ)
                    plot(2, outliers_RT_CueDCZ, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end;

                hVio(3).ViolinColor = {SalineColor};
                outliers_RT_Uncue = find_outliers(obj.RT_Uncue{1});
                if ~isempty(outliers_RT_Uncue)
                    plot(3, outliers_RT_Uncue, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end;

                hVio(4).ViolinColor = {DCZColor};
                outliers_RT_UncueDCZ = find_outliers(obj.RT_Uncue{2});
                if ~isempty(outliers_RT_UncueDCZ)
                    plot(4, outliers_RT_UncueDCZ, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end
                line([1 2], [median(obj.RT_Cue{1}) median(obj.RT_Cue{2})], 'color', [0.60 0.60 0.6], 'linewidth', 1)
                line([3 4], [median(obj.RT_Uncue{1}) median(obj.RT_Uncue{2})], 'color', [0.60 0.60 0.6], 'linewidth', 1)
            else

                RTVec       =             [];
                RTType     =             [];
                RTVec         =           [RTVec obj.RT_Cue{1}];
                RTType       =             [RTType ones(1, length(obj.RT_Cue{1}))];
                RTVec         =           [RTVec obj.RT_Uncue{1}];
                RTType       =             [RTType 3*ones(1, length(obj.RT_Uncue{1}))];
                hVio = violinplot(RTVec,  RTType);
                for iv =1:length(hVio)
                    hVio(iv).EdgeColor = [0 0 0];
                    hVio(iv).WhiskerPlot.Color = WhiskerColor;
                    hVio(iv).WhiskerPlot.LineWidth = 1.5;
                end;

                hVio(1).ViolinColor = {SalineColor};
                % add outliers
                outliers_RT_Cue = find_outliers(obj.RT_Cue{1});
                if ~isempty(outliers_RT_Cue)
                    plot(1, outliers_RT_Cue, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end;

                hVio(2).ViolinColor = {SalineColor};
                outliers_RT_Uncue = find_outliers(obj.RT_Uncue{1});
                if ~isempty(outliers_RT_Uncue)
                    plot(2, outliers_RT_Uncue, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end;
                set(ha8a, 'xlim', [0.5 2.5]);
            end;

            set(ha8a, 'xticklabel', {''}, 'box','off')

            % find out the probability that lever release is within 1000 ms following the
            % end of FP
            ha5b = axes;
            set(ha5b,'units', 'centimeters', 'position', [xlevel2, ylevel2, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 2], ...
                'xlim', [0 unique(obj.MixedFP)/1000+2], 'xtick', [0:4],...
                'xticklabelrotation', 0, 'ticklength',[0.02 0.01]);
            % add Foreperiod as a shaded area
            plotshaded([0 unique(obj.MixedFP)/1000], [0 0; 5 5], FPColor)
            maxPDF = 0;
            plot(obj.HoldTbinEdges, obj.PDF_HoldT_Cue{1}, 'color', SalineColor, 'linewidth', 1.25)
            maxPDF = max(maxPDF, max(obj.PDF_HoldT_Cue{1}));
            if TwoConditions
                plot(obj.HoldTbinEdges, obj.PDF_HoldT_Cue{2}, 'color', DCZColor, 'linewidth', 1.25)
                maxPDF = max(maxPDF, max(obj.PDF_HoldT_Cue{2}));
            end;
            plot(obj.HoldTbinEdges, obj.PDF_HoldT_Uncue{1}, 'color', SalineColor, 'linewidth', 1.25, 'LineStyle', '-.')
            maxPDF = max(maxPDF, max(obj.PDF_HoldT_Uncue{1}));
            if TwoConditions
                plot(obj.HoldTbinEdges, obj.PDF_HoldT_Uncue{2}, 'color', DCZColor, 'linewidth', 1.25, 'LineStyle', '-.')
                maxPDF = max(maxPDF, max(obj.PDF_HoldT_Uncue{2}));
            end;
            xlabel('Hold duration (s)')
            ylabel('PDF (1/s)')
            set(gca, 'ylim', [0 maxPDF*1.1])

            % Plot CDF
            ha7b = axes;
            set(ha7b,'units', 'centimeters', 'position', [xlevel3, ylevel2, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 1], ...
                'xlim', [0 unique(obj.MixedFP)/1000+2], 'xtick', [0:4],...
                'xticklabelrotation', 0, 'ticklength',[0.02 0.01]);
            plotshaded([0 unique(obj.MixedFP)/1000], [0 0; 1 1], FPColor)

            plot(obj.HoldTbinEdges, obj.CDF_HoldT_Cue{1}, 'color', SalineColor, 'linewidth', 1.25)
            plot(obj.HoldTbinEdges, obj.CDF_HoldT_Uncue{1}, 'color', SalineColor, 'linewidth', 1.25, 'LineStyle', '-.')
            if TwoConditions
                plot(obj.HoldTbinEdges, obj.CDF_HoldT_Cue{2}, 'color', DCZColor, 'linewidth', 1.25)
                plot(obj.HoldTbinEdges, obj.CDF_HoldT_Uncue{2}, 'color', DCZColor, 'linewidth', 1.25, 'LineStyle', '-.')
            end;
            xlabel('Hold duration (s)')
            ylabel('CDF')

            % Plot press duration distribution using violinplot
            ha8 = axes;
            set(ha8,'units', 'centimeters', 'position', [xlevel4, ylevel2, plotsize6], 'nextplot', 'add', ...
                'ylim', [0 4], ...
                'xlim', [0.5 4.5], 'xtick', [0:4],'xticklabel', {'Cue (Saline)', 'Cue (DCZ)', 'Uncue (Saline)', 'Uncue (DCZ)'},...
                'xticklabelrotation', 30, 'ticklength',[0.02 0.01]);
            ylabel('Hold duration (s)')
            plotshaded([0 5], [0 0;  unique(obj.MixedFP)/1000 unique(obj.MixedFP)/1000], FPColor)

            if TwoConditions
                PressDurVec       =             [];
                PressType            =             [];
                PressDurVec         =           [PressDurVec obj.HoldT_Cue{1}];
                PressType             =             [PressType ones(1, length(obj.HoldT_Cue{1}))];
                PressDurVec         =           [PressDurVec obj.HoldT_Cue{2}];
                PressType             =             [PressType 2*ones(1, length(obj.HoldT_Cue{2}))];
                PressDurVec         =           [PressDurVec obj.HoldT_Uncue{1}];
                PressType             =             [PressType 3*ones(1, length(obj.HoldT_Uncue{1}))];
                PressDurVec         =           [PressDurVec obj.HoldT_Uncue{2}];
                PressType             =             [PressType 4*ones(1, length(obj.HoldT_Uncue{2}))];

                hVio1 = violinplot(PressDurVec,  PressType);
                for iv =1:length(hVio1)
                    hVio1(iv).EdgeColor = [0 0 0];
                    hVio1(iv).WhiskerPlot.Color = WhiskerColor;
                    hVio1(iv).WhiskerPlot.LineWidth = 1.5;
                end;

                hVio1(1).ViolinColor = {SalineColor};
                outliers_HoldT_Cue = find_outliers(obj.HoldT_Cue{1});
                if ~isempty(outliers_HoldT_Cue)
                    plot(1, outliers_HoldT_Cue, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end;

                hVio1(2).ViolinColor = {DCZColor};
                outliers_HoldT_CueDCZ = find_outliers(obj.HoldT_Cue{2});
                if ~isempty(outliers_HoldT_CueDCZ)
                    plot(2, outliers_HoldT_CueDCZ, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end;

                hVio1(3).ViolinColor = {SalineColor};
                outliers_HoldT_Uncue = find_outliers(obj.HoldT_Uncue{1});
                if ~isempty(outliers_HoldT_Uncue)
                    plot(3, outliers_HoldT_Uncue, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end;

                hVio1(4).ViolinColor = {DCZColor};
                outliers_HoldT_UncueDCZ = find_outliers(obj.HoldT_Uncue{2});
                if ~isempty(outliers_HoldT_UncueDCZ)
                    plot(4, outliers_HoldT_UncueDCZ, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end;

                line([1 2], [median(obj.HoldT_Cue{1}) median(obj.HoldT_Cue{2})], 'color', [0.60 0.60 0.6], 'linewidth', 1)
                line([3 4], [median(obj.HoldT_Uncue{1}) median(obj.HoldT_Uncue{2})], 'color', [0.60 0.60 0.6], 'linewidth', 1)
                set(ha8, 'xticklabel', {'Cue (Saline)', 'Cue (DCZ)', 'Uncue (Saline)', 'Uncue (DCZ)'}, 'box','off')
            else
                PressDurVec       =             [];
                PressType            =             [];
                PressDurVec         =           [PressDurVec obj.HoldT_Cue{1}];
                PressType             =             [PressType ones(1, length(obj.HoldT_Cue{1}))];
                PressDurVec         =           [PressDurVec obj.HoldT_Uncue{1}];
                PressType             =             [PressType 3*ones(1, length(obj.HoldT_Uncue{1}))];
                hVio1 = violinplot(PressDurVec,  PressType);
                for iv =1:length(hVio1)
                    hVio1(iv).EdgeColor = [0 0 0];
                    hVio1(iv).WhiskerPlot.Color = WhiskerColor;
                    hVio1(iv).WhiskerPlot.LineWidth = 1.5;
                end;

                hVio1(1).ViolinColor = {SalineColor};
                outliers_HoldT_Cue = find_outliers(obj.HoldT_Cue{1});
                if ~isempty(outliers_HoldT_Cue)
                    plot(1, outliers_HoldT_Cue, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end;

                hVio1(2).ViolinColor = {SalineColor};
                outliers_HoldT_Uncue = find_outliers(obj.HoldT_Uncue{1});
                if ~isempty(outliers_HoldT_Uncue)
                    plot(2, outliers_HoldT_Uncue, 'rd', 'markersize', 3, 'markerfacecolor', 'r', 'markeredgecolor', 'w', 'linewidth', 0.25)
                end;

                set(ha8, 'xlim', [0.5 2.5], 'xticklabel', {'Cue','Uncue'}, 'box','off')
            end;

            % Plot performance scores
            thisTable = obj.PerformanceTable;
            ha9 = axes; % Cue trials
            ylevel3 = ylevel2 - plotsize4(2) - 1.5;
            set(ha9,'units', 'centimeters', 'position', [xlevel2, ylevel3, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 100], 'xlim', [0 8], 'xtick', [1 3.5 6], 'xticklabel', {'Correct', 'Premature', 'Late'},...
                'xticklabelrotation', 30, 'ticklength',[0.02 0.01]);
            % Correct, Cue, Saline, DCZ
            bar(1,100* thisTable.Percent_Cue_Saline(strcmp(thisTable.OutcomeCount, 'Correct')),...
                'Edgecolor', SalineColor,'Facecolor', col_perf(1, :), 'linewidth', 1.5);
            bar(2,100* thisTable.Percent_Cue_DCZ(strcmp(thisTable.OutcomeCount, 'Correct')),...
                'Edgecolor', DCZColor,'Facecolor', col_perf(1, :), 'linewidth', 1.5);

            % Premature, Cue, Saline, DCZ
            bar(3.5,100* thisTable.Percent_Cue_Saline(strcmp(thisTable.OutcomeCount, 'Premature')),...
                'Edgecolor',SalineColor,'Facecolor', col_perf(2, :), 'linewidth', 1.5);
            bar(4.5,100* thisTable.Percent_Cue_DCZ(strcmp(thisTable.OutcomeCount, 'Premature')),...
                'Edgecolor', DCZColor,'Facecolor', col_perf(2, :), 'linewidth', 1.5);

            % Late, Cue, Saline
            bar(6,100* thisTable.Percent_Cue_Saline(strcmp(thisTable.OutcomeCount, 'Late')),...
                'Edgecolor', SalineColor,'Facecolor', col_perf(3, :), 'linewidth', 1.5);
            bar(7,100* thisTable.Percent_Cue_DCZ(strcmp(thisTable.OutcomeCount, 'Late')),...
                'Edgecolor',DCZColor,'Facecolor', col_perf(3, :), 'linewidth', 1.5);
            text(3, 100, 'Cued trials', 'fontsize', 8, 'fontname', 'dejavu sans', 'fontweight', 'bold')
            ylabel('Performance (%)')

            ha10 = axes; % Uncue trials
            set(ha10,'units', 'centimeters', 'position', [xlevel3, ylevel3, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 100], 'xlim', [0 8], 'xtick', [1 3.5 6], 'xticklabel', {'Correct', 'Premature', 'Late'},...
                'xticklabelrotation', 30, 'ticklength',[0.02 0.01]);
            ylabel('Performance (%)')

             % Correct, Cue, Saline, DCZ
            bar(1,100* thisTable.Percent_Uncue_Saline(strcmp(thisTable.OutcomeCount, 'Correct')),...
                'Edgecolor', SalineColor,'Facecolor', col_perf(1, :), 'linewidth', 1.5, 'linestyle', '-.');
            bar(2,100* thisTable.Percent_Uncue_DCZ(strcmp(thisTable.OutcomeCount, 'Correct')),...
                'Edgecolor', DCZColor,'Facecolor', col_perf(1, :), 'linewidth', 1.5, 'linestyle', '-.');

            % Premature, Cue, Saline, DCZ
            bar(3.5,100* thisTable.Percent_Uncue_Saline(strcmp(thisTable.OutcomeCount, 'Premature')),...
                'Edgecolor',SalineColor,'Facecolor', col_perf(2, :), 'linewidth', 1.5, 'linestyle', '-.');
            bar(4.5,100* thisTable.Percent_Uncue_DCZ(strcmp(thisTable.OutcomeCount, 'Premature')),...
                'Edgecolor', DCZColor,'Facecolor', col_perf(2, :), 'linewidth', 1.5, 'linestyle', '-.');

            % Late, Cue, Saline
            bar(6,100* thisTable.Percent_Uncue_Saline(strcmp(thisTable.OutcomeCount, 'Late')),...
                'Edgecolor', SalineColor,'Facecolor', col_perf(3, :), 'linewidth', 1.5, 'linestyle', '-.');
            bar(7,100* thisTable.Percent_Uncue_DCZ(strcmp(thisTable.OutcomeCount, 'Late')),...
                'Edgecolor',DCZColor,'Facecolor', col_perf(3, :), 'linewidth', 1.5, 'linestyle', '-.');
            text(3, 100, 'Uncued trials', 'fontsize', 8, 'fontname', 'dejavu sans', 'fontweight', 'bold')
            ylabel('Performance (%)')

            ha10 = axes;
            set(ha10,'units', 'centimeters', 'position', [xlevel4, ylevel3, plotsize3], 'nextplot', 'add', ...
                'ylim', [30 100], 'xlim', [0.5 4.5], 'xtick', [1 2 3 4], 'xticklabel', {'Cue', ' ', 'Uncue', ' '},...
                'xticklabelrotation', 30, 'ticklength',[0.02 0.01]);
            thisTable = obj.FastResponseRatio;
            ylabel('Fast-responding ratio')

            bar(1, 100*thisTable.Ratio(strcmp(thisTable.Type, 'Cue_Saline')),  'Edgecolor', SalineColor,'Facecolor', 'w', 'linewidth', 1.5)
            if length(obj.FWHM_HoldT_Cue)>1
                bar(2, 100*thisTable.Ratio(strcmp(thisTable.Type, 'Cue_DCZ')),  'Edgecolor', DCZColor,'Facecolor', 'w', 'linewidth', 1.5)
            end;

            bar(3,  100*thisTable.Ratio(strcmp(thisTable.Type, 'Uncue_Saline')),  'Edgecolor', SalineColor,'Facecolor', 'w', 'linewidth', 1.5, 'linestyle', '-.')
            if length(obj.FWHM_HoldT_Uncue)>1
                bar(4, 100*thisTable.Ratio(strcmp(thisTable.Type, 'Uncue_DCZ')),  'Edgecolor', DCZColor,'Facecolor', 'w', 'linewidth', 1.5, 'linestyle', '-.')
            end;

            % Plot normalized PDF (peak normalized to 1)
            ha11 = axes;
            ylevel4 = ylevel3 - plotsize4(2) - 1.5;
            set(ha11,'units', 'centimeters', 'position', [xlevel2, ylevel4, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 1.1], 'xlim', [0 unique(obj.MixedFP)/1000+2], 'xtick', [0:4],...
                'xticklabelrotation', 0, 'ticklength',[0.02 0.01]);

            % add Foreperiod as a shaded area
            plotshaded([0 unique(obj.MixedFP)/1000], [0 0; 1.1 1.1], FPColor)

            plot(obj.HoldTbinEdges, obj.PDF_HoldT_Cue{1}/max(obj.PDF_HoldT_Cue{1}), 'color', SalineColor, 'linewidth', 1.25)
            plot(obj.HoldTbinEdges, obj.PDF_HoldT_Uncue{1}/max(obj.PDF_HoldT_Uncue{1}), 'color', SalineColor, 'linewidth', 1.25, 'LineStyle', '-.')
            if TwoConditions
                plot(obj.HoldTbinEdges, obj.PDF_HoldT_Cue{2}/max(obj.PDF_HoldT_Cue{2}), 'color', DCZColor, 'linewidth', 1.25)
                plot(obj.HoldTbinEdges, obj.PDF_HoldT_Uncue{2}/max(obj.PDF_HoldT_Uncue{2}), 'color', DCZColor, 'linewidth', 1.25, 'LineStyle', '-.')
            end;

            xlabel('Hold duration (s)')
            ylabel('PDF (normalized)')

            % Plot Gauss normalized PDF (peak normalized to 1)
            ha12 = axes; 
            set(ha12,'units', 'centimeters', 'position', [xlevel3, ylevel4, plotsize4], 'nextplot', 'add', ...
                'ylim', [0 1.1], 'xlim', [0 unique(obj.MixedFP)/1000+2], 'xtick', [0:4],...
                'xticklabelrotation', 0, 'ticklength',[0.02 0.01]);

            % add Foreperiod as a shaded area
            plotshaded([0 unique(obj.MixedFP)/1000], [0 0; 10 10], FPColor)

            maxPDF = 0;

            tfit = [obj.HoldTbinEdges(1):0.01:obj.HoldTbinEdges(end)];

            plot(tfit, obj.PDF_HoldT_Cue_Gauss{1}(tfit), 'color', SalineColor, 'linewidth', 1.25)
            maxPDF = max(maxPDF, max(obj.PDF_HoldT_Cue_Gauss{1}(tfit)));
            plot(tfit, obj.PDF_HoldT_Uncue_Gauss{1}(tfit), 'color', SalineColor, 'linewidth', 1.25, 'LineStyle', '-.')
            maxPDF = max(maxPDF, max(obj.PDF_HoldT_Uncue_Gauss{1}(tfit)));

            if TwoConditions
                plot(tfit, obj.PDF_HoldT_Cue_Gauss{2}(tfit), 'color', DCZColor, 'linewidth', 1.25)
                maxPDF = max(maxPDF, max(obj.PDF_HoldT_Cue_Gauss{2}(tfit)));
                plot(tfit, obj.PDF_HoldT_Uncue_Gauss{2}(tfit), 'color', DCZColor, 'linewidth', 1.25, 'LineStyle', '-.')
                maxPDF = max(maxPDF, max(obj.PDF_HoldT_Cue_Gauss{2}(tfit)));
            end;

            set(gca, 'ylim', [0 maxPDF])
            xlabel('Hold duration (s)')
            ylabel('PDF (2-term Gauss fit)')

            ha13 = axes;
            set(ha13,'units', 'centimeters', 'position', [xlevel4, ylevel4, plotsize3], 'nextplot', 'add', ...
                'ylim', [0 1000], 'xlim', [0.5 4.5], 'xtick', [1 2 3 4], 'xticklabel', {'Cue', ' ', 'Uncue', ' '},...
                'xticklabelrotation', 30, 'ticklength',[0.02 0.01]);
            bar(1, 1000*obj.FWHM_HoldT_Cue(1),  'Edgecolor', SalineColor,'Facecolor', 'w', 'linewidth', 1.5)
            if length(obj.FWHM_HoldT_Cue)>1
                bar(2, 1000*obj.FWHM_HoldT_Cue(2),  'Edgecolor', DCZColor,'Facecolor', 'w', 'linewidth', 1.5)
            end;

            bar(3, 1000*obj.FWHM_HoldT_Uncue(1),  'Edgecolor', SalineColor,'Facecolor', 'w', 'linewidth', 1.5, 'linestyle', '-.')
            if length(obj.FWHM_HoldT_Uncue)>1
                bar(4, 1000*obj.FWHM_HoldT_Uncue(2),  'Edgecolor', DCZColor,'Facecolor', 'w', 'linewidth', 1.5, 'linestyle', '-.')
            end;

            axis 'auto y'
            ylabel('FWHM (ms)')
           

            % Write information
            ha6 = axes;
            xlevel5 = xlevel4 + plotsize3(1)+0.5;

            set(ha6,'units', 'centimeters', 'position', [xlevel5, ylevel4, plotsize3], 'nextplot', 'add', ...
                'ylim', [2 10], ...
                'xlim', [0 10], 'xtick', [0:4],...
                'xticklabelrotation', 0, 'ticklength',[0.02 0.01]);

            line([0  5], [9 9],  'color', SalineColor, 'linewidth', 1.25)
            text(6, 9, 'Cue-Saline', 'fontsize', 8, 'fontname', 'dejavu sans')
            line([0 5], [7 7],  'color', DCZColor, 'linewidth', 1.25)
            text(6, 7, 'Cue-DCZ', 'fontsize', 8, 'fontname', 'dejavu sans')
            line([0 5], [5 5],  'color', SalineColor, 'linewidth', 1.25, 'LineStyle', '-.')
            text(6, 5, 'Uncue-Saline', 'fontsize', 8, 'fontname', 'dejavu sans')
            line([0 5], [3 3],  'color', DCZColor, 'linewidth', 1.25, 'LineStyle', '-.')
            text(6, 3, 'Uncue-DCZ', 'fontsize', 8, 'fontname', 'dejavu sans')

            axis off

            hui_1 = uicontrol('Style', 'text', 'parent', 20, 'units', 'normalized', 'position', [0.1 0.965 0.2 0.03],...
                'string',  ['Subject: ' obj.Subject{1}], 'fontweight', 'bold', ...
                'backgroundcolor', [1 1 1], 'HorizontalAlignment', 'left' , 'fontname', 'dejavu sans' );

            hui_2 = uicontrol('Style', 'text', 'parent', 20, 'units', 'normalized', 'position', [0.2 0.965 0.4 0.03],...
                'string', ['Protocol: ' obj.Protocols{1}], 'fontweight', 'bold', ...
                'backgroundcolor', [1 1 1], 'HorizontalAlignment', 'left' , 'fontname', 'dejavu sans');

        end

        function save(obj, savepath)
            if nargin<2
                savepath = pwd;
            end
            save(fullfile(savepath, ['KornblumGroupClass_' (obj.Subject{1})]),  'obj');
        end

        function print(obj, targetDir)
            savename = ['KornblumGroupClass_' (obj.Subject{1})];
            hf = 20;
            figure(hf)
            %             print (hf,'-dpdf', [savename], '-bestfit')
            %             print (hf,'-dpng', [savename])
            %             export_fig(hf, savename, '-png', '-tif', '-pdf', '-q101')
            print(hf, '-dpng', [savename, '.png'])
            print(hf, '-dpdf', [savename, '.pdf'])
            saveas(hf, savename, 'fig')
            saveas(hf, savename, 'epsc')
        end;

        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end