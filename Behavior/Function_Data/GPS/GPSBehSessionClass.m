classdef GPSBehSessionClass < GPSBehClass & GPSPlot
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    properties
        % Class object information
        UpdateTime

        % Experiment information
        BpodFile
        SessionFolder
        BpodFileName
        Subject % Name of the animal, extrated from data file name

        % Animal information
        ANMInfoFile;
        ANMInfo;

        % Session information
        SessionInfo;
        Task % Name of task, extrated from data file name and set as {'Autoshaping', 'Wait1Hold', 'Wait1HoldCRT', 'Wait2HoldCRT', 'ThreeFPHoldCRT', 'ThreeFPHoldSRT', 'Kornblum'}
        Protocol % Task name for save and print. Same as Task for SRT, plus TargetFP for Kb
        Session % Date of this session, extrated from data file name
        SessionStartTime

        NumTrials % Total trial number, extraced from SessionData.Info
        TargetFP % FP configuration, for ThreeFP paradigm only, [NumTrials x N (number of FPs)]

        % Trial information
        Trials % Trial index, [NumTrials x 1]
        TrialStartTime % Time when trial started (last trial ended) relative to SessionStartTime, [NumTrials x 1]

        FP % foreperiod in each trial, for all paradigms except Autoshaping, [NumTrials x 1]
        RW
        PortCorrect % The correct for each trial (1 for port_left, 2 for port_right), [NumTrials x 1]

        Cued
        Guided

        SortVars
        SortLabels
        
        % Behavior information
        InitPokeInTime % Time when the animal first poked-in port_init, [NumTrials x 1]
        InitPokeOutTime % Time when the animal poked-out port_init, and went to port_cent, [NumTrials x 1]
        CentPokeInTime % Time when the animal poked-in port_cent, [NumTrials x 1]
        CentPokeOutTime % Time when the animal poked-out port_cent, and went to make choice, [NumTrials x 1]
        ChoicePokeTime % Time when the animal poked-in one of the port_choice (port_left/port_right), [NumTrials x 1]
        ChoiceCueTime % Duration that choice light lit up, [NumTrials x 2]
        TriggerCueTime

        PortChosen % The port chosen by the animal in each trial, [NumTrials x 1]
        Outcome % Outcome of each trial, (1 for correct; 0 for choice-error; -1 for premature; -2 for late), [NumTrials x 1]
        LateChoice % Choice after late error

        Interruption

        % Probability density and cumulative distribution
        RTPDF % reaction time
        RTCDF
        MTPDF % movement time
        MTCDF
        HDPDF % hold duration
        HDCDF
        HDvPDF % hold duration
        HDvCDF
        CTPDF % choice time
        CTCDF
        LogSTPDF % Log10 shuttle time
        LogSTCDF
    end

    properties (Dependent)
        % Animal and session information
        Strain % Strain of the animal, set manually
        Gender
        Experimenter % Name (initials) of the Experimenter, set manually
        Treatment % Set manually
        Dose % Set manually
        Label

        %
        TrialCentInTime
        TrialSorted
        TimeSorted

        % Behavior information
        Stage % warm-up or 3FP
        Order

        % Reference data and codes for data sorting
        SortRefs
        SortCodes

        % Shuttle time
        ST % check
        STSplit
        STStat
        LogST
        LogSTSplit
        LogSTStat

        % Hold duration
        HD
        HDSorted
        HDStat

        HDv
        HDvSorted
        HDvStat

        % Reaction time
        RT
        RTSorted
        RTStat

        % Movement time
        MT
        MTSorted
        MTStat

        % Choice time
        CT
        CTSorted
        CTStat

        % Performance
        OutcomeSorted
        Performance
        PerformanceTrack

        % Behavior table
        BehavTable

        % Save name for object, figure and csv files
        SaveName
    end

    methods
        %% Initiation
        function obj = GPSBehSessionClass(BpodFile, AnmInfoFile)

            % Convert to string
            BpodFile = string(BpodFile);
            AnmInfoFile = string(AnmInfoFile);

            % Process SessionData to get properties
            load(BpodFile, 'SessionData');
            obj.BpodFile = BpodFile;
            [obj.SessionFolder, obj.BpodFileName] = fileparts(obj.BpodFile);
            
            % Get meta information from session folder path and Bpod file name
            session_path_info = split(obj.SessionFolder, filesep);
            bpod_file_info = split(obj.BpodFileName, '_');

            % Rat name
            subject_bpod = bpod_file_info(1);
            subject_path = session_path_info(end-2);
            if strcmp(subject_bpod, subject_path)
                obj.Subject = subject_bpod;
            else
                error('Subject names extracted from Bpod file and session folder path do not match.');
            end

            % Session date
            session_bpod = bpod_file_info(end-1);
            session_path = session_path_info(end);
            if contains(session_path, session_bpod)
                obj.Session = session_path;
            else
                error('Session dates extracted from Bpod file and session folder path do not match.');
            end

            % Task (in general: Autoshaping, Wait, ThreeFP, Timing)
            protocol_bpod = bpod_file_info(end-2);
            switch protocol_bpod % e.g. 'Wait3FPFlash'
                case {'Autoshaping', 'AutoshapingAdvance'}
                    obj.Task = "Autoshaping";
                    obj.SortLabels = "LeftRight";
                    obj.SortVars   = "PortCorrect";
                case {'Wait1Hold', 'Wait1HoldSRT', 'Wait1HoldFlash', 'Wait2HoldSRT', 'Wait2HoldFlash'}
                    obj.Task = "WaitHold";
                    obj.SortLabels = ["TargetFP", "LeftRight"];
                    obj.SortVars   = ["FP"      , "PortCorrect"];
                case {'3FPHoldFlash', '3FPHoldSRT', '3FPHoldWM'}
                    obj.Task = "ThreeFPHold";
                    obj.SortLabels = ["TargetFP", "LeftRight"];
                    obj.SortVars   = ["FP"      , "PortCorrect"];
                case {'3FPHoldCRTProbe', '3FPHoldSRTProbe', '3FPHoldWMProbe', '3FPHoldSRT525Probe'}
                    obj.Task = "ThreeFPHoldProbe";
                    obj.SortLabels = ["TargetFP", "LeftRight"];
                    obj.SortVars   = ["FP"      , "PortCorrect"];
                case {'KornblumHold', 'KornblumHoldEmpty'}
                    obj.Task = "KornblumHold";
                    obj.SortLabels = ["CueUncue", "LeftRight"];
                    obj.SortVars   = ["Cued"    , "PortCorrect"];
                case {'KornblumHoldSide'}
                    obj.Task = "KornblumHoldSide";
                    obj.SortLabels = ["CueUncue", "LeftRight"];
                    obj.SortVars   = ["Cued"    , "PortCorrect"];
                case {'KornblumHoldMix'}
                    obj.Task = "KornblumHoldMix";
                    obj.SortLabels = ["CueUncue", "Guidance", "LeftRight"];
                    obj.SortVars   = ["Cued"    , "Guided"  , "PortCorrect"];
            end

            % Protocol (training specific)
            protocol_path = session_path_info(end-1);
            protocol_path_info = split(protocol_path, '_');
            obj.Protocol = protocol_path_info(end);

            % Animal information
            obj.ANMInfoFile = AnmInfoFile;
            obj.ANMInfo = readtable(obj.ANMInfoFile, "Sheet", "ANM", "TextType", "string");
            obj.ANMInfo = obj.ANMInfo(strcmp(obj.ANMInfo.Name, obj.Subject), :);

            % Session information
            obj.SessionInfo = obj.read_session_table();
            obj.SessionInfo = obj.SessionInfo(strcmp(string(obj.SessionInfo.Session), obj.Session), :);
            obj.SessionStartTime = string(SessionData.Info.SessionStartTime_UTC);

            % Get paradigm specific trial information
            feval(obj.Task+".getTrialInfo", obj, SessionData);

            % Get PDFs and CDFs
            obj.get_all_kdes(0);

            % Get behavior tables
            obj.get_Interruption();

        end % GPSSessionClass

        %% Manually set
        function set.Strain(obj, strain)
            if ismember(strain, {'BN', 'Wistar', 'LE', 'SD', 'Hybrid'})
                obj.Strain = string(strain);
            else
                error("Strain can only be: 'BN', 'Wistar', 'LE', 'SD', 'Hybrid'")
            end
        end

        function set.Gender(obj, gender)
            if ismember(gender, {'F', 'M'})
                obj.Gender = string(gender);
            else
                error("Strain can only be: 'F', 'M'")
            end
        end

        function set.Experimenter(obj, person_name)
            % Manually set the name (initials) of the experimenter, and
            % turn it to string
            obj.Experimenter = string(person_name);
        end

        function set.Treatment(obj, treatment)
            % Manually set the treatment of this session, NaN/Saline/DCZ
            if ismember(treatment, {'None', 'Saline', 'DCZ'})
                obj.Treatment = string(treatment);
            else
                error('Treatment can only be: None, Saline, DCZ')
            end
        end

        function set.Dose(obj, dose)
            % Manually set the dose of injection
            if isnumeric(dose)
                obj.Dose = dose;
            else
                error('"dose" must be a scalar')
            end
        end

        function set.Label(obj, label)
            % Manually set the treatment of this session, NaN/Saline/DCZ
            if ismember(label, {'None', 'Control', 'Chemo'})
                obj.Treatment = string(label);
            else
                error('Treatment can only be: None, Control, Chemo')
            end
        end

        function set.TargetFP(obj, mFP)
            if isnumeric(mFP)
                if mean(mFP)>100
                    error('Please use seconds')
                else
                    obj.TargetFP = mFP;
                end
            end
        end

        %% Get animal information
        function strain = get.Strain(obj)
            strain = string(obj.ANMInfo.Strain);
        end

        function gender = get.Gender(obj)
            gender = obj.ANMInfo.Gender;
        end

        function experimenter = get.Experimenter(obj)
            experimenter = obj.SessionInfo.Experimenter;
        end

        function treatment = get.Treatment(obj)
            treatment = obj.SessionInfo.Treatment;
        end

        function dose = get.Dose(obj)
            dose = obj.SessionInfo.Dose;
        end

        function label = get.Label(obj)
            label = obj.SessionInfo.Label;
        end

        function save_name = get.SaveName(obj)
            save_name = sprintf("GPSBehSessionClass_%s_%s_%s", obj.Protocol, upper(obj.Subject), obj.Session);
        end

        %%
        function trial_centin_time = get.TrialCentInTime(obj)
            trial_centin_time = obj.TrialStartTime + cellfun(@(x) x(1), obj.CentPokeInTime);
        end

        function trial_sorted = get.TrialSorted(obj)
            ind = obj.Stage==1;
            trial_this = obj.Trials(ind);
            refs_this = cellfun(@(x) x(ind), obj.SortRefs, 'UniformOutput', false);
            trial_sorted = obj.sort_data(trial_this, refs_this, obj.SortCodes);
        end

        function time_sorted = get.TimeSorted(obj)
            ind = obj.Stage==1;
            time_this = obj.TrialCentInTime(ind);
            refs_this = cellfun(@(x) x(ind), obj.SortRefs, 'UniformOutput', false);
            time_sorted = obj.sort_data(time_this, refs_this, obj.SortCodes);
        end

        %% Get protocol specific information
        function stage = get.Stage(obj)
            stage = feval(obj.Task+".getStage", obj);
        end

        %% Split session to several parts
        function order = get.Order(obj)
            order = zeros(obj.NumTrials, 1);
            ind = obj.Stage==1;
            [~, order_id] = obj.split_data(obj.Trials(ind), obj.NumOrders);
            order(ind) = cell2mat(order_id);
        end

        %% Sorting References
        function sort_refs = get.SortRefs(obj)
            sort_refs = arrayfun(@(x) obj.(x), obj.SortVars, 'UniformOutput', false);
        end

        function sort_codes = get.SortCodes(obj)
            sort_codes = arrayfun(@(x) obj.(x), obj.SortLabels, 'UniformOutput', false);
        end

        %% Get behavior information
        % Shuttle time
        function shuttle_time = get.ST(obj)
            shuttle_time = cellfun(@(x, y) y(1)-x(end), obj.InitPokeOutTime, obj.CentPokeInTime);
        end

        function st_split = get.STSplit(obj)
            if ~any(obj.Stage==1)
                st_split = obj.split_data(obj.ST, 3);
            else
                st_split = obj.split_data(obj.ST(obj.Stage==1), 3);
            end
        end

        function st_stat = get.STStat(obj)
            order_cell = cellfun(@(x) ones(length(x), 1), obj.STSplit, 'UniformOutput', false);
            for i = 1:length(order_cell)
                order_cell{i} = order_cell{i} * i;
            end
            order_this = cell2mat(order_cell(:));

            if ~any(obj.Stage==1)
                ind = obj.Stage==0;
            else
                ind = obj.Stage==1;
            end
            st_this = obj.ST(ind);
            st_stat = obj.get_stat(st_this, {order_this}, {unique(order_this)}, "Order", 1);
            st_stat = obj.add_session_info(st_stat);
        end

        % Log shuttle time
        function shuttle_time = get.LogST(obj)
            shuttle_time = log10(obj.ST);
        end

        function st_split = get.LogSTSplit(obj)
            if ~any(obj.Stage==1)
                st_split = obj.split_data(obj.LogST, 3);
            else
                st_split = obj.split_data(obj.LogST(obj.Stage==1), 3);
            end
        end

        function st_stat = get.LogSTStat(obj)
            order_cell = cellfun(@(x) ones(length(x), 1), obj.LogSTSplit, 'UniformOutput', false);
            for i = 1:length(order_cell)
                order_cell{i} = order_cell{i} * i;
            end
            order_this = cell2mat(order_cell(:));

            if ~any(obj.Stage==1)
                ind = obj.Stage==0;
            else
                ind = obj.Stage==1;
            end            
            st_this = obj.LogST(ind);
            st_stat = obj.get_stat(st_this, {order_this}, {unique(order_this)}, "Order", 1);
            st_stat = obj.add_session_info(st_stat);
        end

        % Hold duration
        function hold_duration = get.HD(obj)
            hold_duration = cellfun(@(x, y) y(end) - x(1), obj.CentPokeInTime, obj.CentPokeOutTime);
        end

        function hd_sorted = get.HDSorted(obj)
            ind = obj.Stage==1;
            hd_this = obj.HD(ind);
            refs_this = cellfun(@(x) x(ind), obj.SortRefs, 'UniformOutput', false);
            hd_sorted = obj.sort_data(hd_this, refs_this, obj.SortCodes);
        end

        function hd_stat = get.HDStat(obj)
            ind = obj.Stage==1;
            hd_this = obj.HD(ind);
            refs_this = cellfun(@(x) x(ind), obj.SortRefs, 'UniformOutput', false);
            hd_stat = obj.get_stat(hd_this, refs_this, obj.SortCodes, obj.SortVars, 1);
            hd_stat = obj.add_session_info(hd_stat);
        end

        function hold_duration_v = get.HDv(obj)
            id_v = obj.HD>0.5;
            hold_duration_v = obj.HD;
            hold_duration_v(~id_v) = nan;
        end

        function hd_sorted = get.HDvSorted(obj)
            ind = obj.Stage==1;
            hd_this = obj.HDv(ind);
            refs_this = cellfun(@(x) x(ind), obj.SortRefs, 'UniformOutput', false);
            hd_sorted = obj.sort_data(hd_this, refs_this, obj.SortCodes);
        end

        function hd_stat = get.HDvStat(obj)
            ind = obj.Stage==1;
            hd_this = obj.HDv(ind);
            refs_this = cellfun(@(x) x(ind), obj.SortRefs, 'UniformOutput', false);
            hd_stat = obj.get_stat(hd_this, refs_this, obj.SortCodes, obj.SortVars, 1);
            hd_stat = obj.add_session_info(hd_stat);
        end

        % Reaction time
        function reaction_time = get.RT(obj)
            reaction_time = cellfun(@(x) x(end), obj.CentPokeOutTime) - obj.TriggerCueTime;
%             reaction_time(reaction_time<0.05 | reaction_time>2) = nan;
        end

        function rt_sorted = get.RTSorted(obj)
            ind = obj.Stage==1;
            rt_this = obj.RT(ind);
            refs_this = cellfun(@(x) x(ind), obj.SortRefs, 'UniformOutput', false);
            rt_sorted = obj.sort_data(rt_this, refs_this, obj.SortCodes);
        end

        function rt_stat = get.RTStat(obj)
            ind = obj.Stage==1;
            rt_this = obj.RT(ind);
            refs_this = cellfun(@(x) x(ind), obj.SortRefs, 'UniformOutput', false);
            rt_stat = obj.get_stat(rt_this, refs_this, obj.SortCodes, obj.SortVars, 1);
            rt_stat = obj.add_session_info(rt_stat);
        end

        % Movement time
        function movement_time = get.MT(obj)
            movement_time = obj.ChoicePokeTime - cellfun(@(x) x(end), obj.CentPokeOutTime);
        end

        function mt_sorted = get.MTSorted(obj)
            ind = obj.Stage==1 & obj.PortChosen==obj.PortCorrect;
            mt_this = obj.MT(ind);
            refs_this = cellfun(@(x) x(ind), obj.SortRefs, 'UniformOutput', false);
            mt_sorted = obj.sort_data(mt_this, refs_this, obj.SortCodes);
        end

        function mt_stat = get.MTStat(obj)
            ind = obj.Stage==1 & obj.PortChosen==obj.PortCorrect;
            mt_this = obj.MT(ind);
            refs_this = cellfun(@(x) x(ind), obj.SortRefs, 'UniformOutput', false);
            mt_stat = obj.get_stat(mt_this, refs_this, obj.SortCodes, obj.SortVars, 1);
            mt_stat = obj.add_session_info(mt_stat);
        end

        % Choice time
        function choice_time = get.CT(obj)
            choice_time = obj.ChoicePokeTime - obj.TriggerCueTime;
        end

        function ct_sorted = get.CTSorted(obj)
            ind = obj.Stage==1 & obj.PortChosen==obj.PortCorrect;
            ct_this = obj.CT(ind);
            refs_this = cellfun(@(x) x(ind), obj.SortRefs, 'UniformOutput', false);
            ct_sorted = obj.sort_data(ct_this, refs_this, obj.SortCodes);
        end

        function ct_stat = get.CTStat(obj)
            ind = obj.Stage==1 & obj.PortChosen==obj.PortCorrect;
            ct_this = obj.CT(ind);
            refs_this = cellfun(@(x) x(ind), obj.SortRefs, 'UniformOutput', false);
            ct_stat = obj.get_stat(ct_this, refs_this, obj.SortCodes, obj.SortVars, 1);
            ct_stat = obj.add_session_info(ct_stat);
        end

        function get_all_kdes(obj, cal_ci)
            Vars = ["HD", "HDv", "RT", "MT", "CT"];
            for i = 1:length(Vars)
                v_this = Vars(i);
                obj.(v_this+"PDF") = obj.get_kde(obj.(v_this+"Sorted"), obj.Bins.(v_this), 'pdf', v_this, cal_ci);
                obj.(v_this+"CDF") = obj.get_kde(obj.(v_this+"Sorted"), obj.Bins.(v_this), 'cdf', v_this, cal_ci);
            end
            logST = cellfun(@log10, obj.STSplit, 'UniformOutput', false);
            obj.LogSTPDF = obj.get_kde(logST, obj.Bins.LogST, 'pdf', "LogST", cal_ci);
            obj.LogSTCDF = obj.get_kde(logST, obj.Bins.LogST, 'cdf', "LogST", cal_ci);
        end

        %% Performance
        function outcome_sorted = get.OutcomeSorted(obj)
            ind = obj.Stage==1;
            outcome_this = obj.Outcome(ind);
            refs_this = cellfun(@(x) x(ind), obj.SortRefs, 'UniformOutput', false);
            outcome_sorted = obj.sort_data(outcome_this, refs_this, obj.SortCodes);
        end

        function perf_table = get.Performance(obj)
            ind = obj.Stage==1;
            outcome_this = obj.Outcome(ind);
            refs_this = cellfun(@(x) x(ind), obj.SortRefs, 'UniformOutput', false);
            
            perf_table = obj.get_perfs(outcome_this, refs_this, obj.SortCodes, obj.SortVars);
            perf_table = obj.add_session_info(perf_table);
        end

        function perf_track = get.PerformanceTrack(obj)
            ind = obj.Stage==1;
            outcome_this = obj.Outcome(ind);
            index_this = obj.TrialCentInTime(ind);
            refs_this = cellfun(@(x) x(ind), obj.SortRefs, 'UniformOutput', false);

            perf_track = obj.get_perf_track(outcome_this, index_this, refs_this, obj.SortCodes);
            perf_track = cellfun(@(x) obj.add_session_info(x), perf_track, 'UniformOutput', false);
        end

        %% Interruption
        function get_Interruption(obj)
            inter_on        = cellfun(@(x, y) x(1:end-1) - y(1), obj.CentPokeOutTime, obj.CentPokeInTime, 'UniformOutput', false);
            inter_dur       = cellfun(@(x, y) y(2:end) - x(1:end-1), obj.CentPokeOutTime, obj.CentPokeInTime, 'UniformOutput', false);
            trial           = cellfun(@(x, y) repmat(x, length(y), 1), num2cell(obj.Trials), inter_on, 'UniformOutput', false);
            order           = cellfun(@(x, y) repmat(x, length(y), 1), num2cell((1:obj.NumTrials)'), inter_on, 'UniformOutput', false);

            id = find(obj.Stage & ~cellfun(@isempty, inter_on));
            
            inter_on        = cell2mat(inter_on(id));
            inter_dur       = cell2mat(inter_dur(id));
            trial           = cell2mat(trial(id));
            order           = cell2mat(order(id));

            port_correct    = obj.PortCorrect(order);
            fp              = obj.FP(order);
            cued            = obj.Cued(order);
            hold_duration   = obj.HD(order);
            outcome         = obj.Outcome(order);

            Subjects = repmat(string(obj.Subject), length(trial), 1);
            Sessions = repmat(string(obj.Session), length(trial), 1);

            inter = table(Subjects, Sessions, trial, inter_on, inter_dur, port_correct, fp, cued, hold_duration, outcome, ...
                'VariableNames', {'Subjects', 'Sessions', 'Trials', 'On', 'Dur', 'PortCorrect', 'FP', 'Cued', 'HD', 'Outcome'});
            inter(inter.Dur<0.001, :) = [];

            obj.Interruption = inter;
        end % getInterruption

        %% Behavior table
        function behav_table = get.BehavTable(obj)
            InitInTime  = cellfun(@(x) x(1),   obj.InitPokeInTime);
            InitOutTime = cellfun(@(x) x(end), obj.InitPokeOutTime);
            CentInTime  = cellfun(@(x) x(1),   obj.CentPokeInTime);
            CentOutTime = cellfun(@(x) x(end), obj.CentPokeOutTime);

            RWthis = obj.RW;
            if isempty(RWthis)
                RWthis = nan(obj.NumTrials, 1);
            end
            SessionStart = repmat(string(obj.SessionStartTime), obj.NumTrials, 1);

            behav_table = table( ...
                SessionStart, obj.Trials, obj.TrialStartTime, obj.TrialCentInTime, obj.Stage, obj.Order, ...
                InitInTime, InitOutTime, CentInTime, CentOutTime, obj.ChoicePokeTime, obj.ChoiceCueTime, obj.TriggerCueTime, ...
                obj.PortCorrect, obj.PortChosen, obj.FP, RWthis, obj.Outcome, ...
                obj.ST, obj.LogST, obj.HD, obj.HDv, obj.RT, obj.MT, obj.CT, obj.Cued, ...
                'VariableNames', ...
                {'SessionStartTime', 'Trials', 'TrialStartTime', 'TrialCentInTime', 'Stage', 'Order', ...
                'InitInTime', 'InitOutTime', 'CentInTime', 'CentOutTime', 'ChoicePokeTime', 'ChoiceCueTime', 'TriggerCueTime', ...
                'PortCorrect', 'PortChosen', 'FP', 'RW', 'Outcome', ...
                'ST', 'LogST', 'HD', 'HDv', 'RT', 'MT', 'CT', 'Cued'});
            if ~isempty(obj.Guided)
                behav_table = addvars(behav_table, obj.Guided, 'After', 'Cued', 'NewVariableNames', {'Guided'});
            end
            behav_table = obj.add_session_info(behav_table);
        end % get.BehavTable

        % add session information to tables
        function table_new = add_session_info(obj, table_raw)

            h_table = height(table_raw);

            info = table('Size', [h_table, 5], ...
                'VariableTypes', ["string", "string", "string", "double", "string"], ...
                'VariableNames', ["Subject", "Session", "Treatment", "Dose", "Label"]);
            
            info.Subject    = repmat(string(obj.Subject), h_table, 1);
            info.Session    = repmat(string(obj.Session), h_table, 1);
            info.Treatment  = repmat(string(obj.Treatment), h_table, 1);
            info.Dose       = repmat(obj.Dose, h_table, 1);
            info.Label      = repmat(string(obj.Label), h_table, 1);

            table_new = horzcat(info, table_raw);
        end

        %% Read session table
        function session_table = read_session_table(obj)
            opts = spreadsheetImportOptions("NumVariables", 10);
            opts.Sheet = obj.Subject;
            opts.DataRange = 'A2';
            opts.VariableNames = ["Session", "Treatment", "Dose", "Label", "Experimenter", "Task", "SessionFolder", "BpodFile", "SessionClassFile", "UpdateTime"];
            opts.VariableTypes = ["string", "string", "double", "string", "string", "string", "string", "string", "string", "string"];
            opts = setvaropts(opts, "Session", "WhitespaceRule", "preserve");
            opts = setvaropts(opts, ["Session", "Treatment", "Label", "Experimenter", "Task", "SessionFolder", "BpodFile", "SessionClassFile", "UpdateTime"], "EmptyFieldRule", "auto");

            % Import the data
            session_table = readtable(obj.ANMInfoFile, opts, "UseExcel", false);
        end

        %% Save and print
        function save(obj, copy_dir)
            obj.UpdateTime = string(datetime());
            obj.update_SessionInfo();
            obj.update_ANMInfoFile();

            save_path = fullfile(obj.SessionFolder, obj.SaveName);
            save(save_path, 'obj');

            if nargin==2
                copy_path = fullfile(copy_dir, obj.SaveName);
                copyfile(save_path+".mat", copy_path+".mat");
            end
        end % save

        function update_SessionInfo(obj)
            obj.SessionInfo.Task = obj.Protocol;
            obj.SessionInfo.SessionFolder = obj.SessionFolder;
            obj.SessionInfo.BpodFile = obj.BpodFileName;
            obj.SessionInfo.SessionClassFile = obj.SaveName;
            obj.SessionInfo.UpdateTime = obj.UpdateTime;    
        end % update_SessionInfo

        function update_ANMInfoFile(obj)
            session_sheet = obj.read_session_table();
            session_ind = strcmp(string(session_sheet.Session), obj.Session);
            session_sheet(session_ind, :) = obj.SessionInfo;
            writetable(session_sheet, obj.ANMInfoFile, "Sheet", obj.Subject);
        end % update_ANMInfoFile

        function print(obj, copy_dir)
            save_dir = obj.SessionFolder;
            if ~isfolder(obj.SessionFolder)
                save_dir = "./";
            end
            save_path = fullfile(save_dir, obj.SaveName);
            
            fig = obj.plot();
            exportgraphics(fig, save_path+".png", 'Resolution', 600);
            exportgraphics(fig, save_path+".pdf", 'ContentType', 'vector');
            saveas(fig, save_path, 'fig');

            if nargin==2
                if save_dir==copy_dir
                    return
                end
                if ~isfolder(copy_dir)
                    mkdir(copy_dir);
                end
                copy_path = fullfile(copy_dir, obj.SaveName);
                copyfile(save_path+".pdf", copy_path+".pdf");
                copyfile(save_path+".png", copy_path+".png");
                copyfile(save_path+".fig", copy_path+".fig");
            end
        end % print

        function fig = plot(obj)
            try
                set_matlab_default
            catch
                disp('You do not have "set_matlab_default"' )
            end

            fig = feval(obj.Task+".plotSession", obj);
        end % plot
    end
end