classdef GPSBehProgressClass < GPSBehClass & GPSPlot
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        % Class object information
        ProtocolDir
        UpdateTime

        % Animal information
        Subject
        Strain

        % Task information
        Task
        Protocol
        TargetFP

        % Session information
        Sessions
        NumSessions
        NumTrialsSession
        DurationSession
        
        % Experiment information
        Treatment
        Dose
        Label

        % Sorting
        SortVars
        SortLabels

        % Behavior information
        % Shuttle time
        STSplit
        STStat
        LogSTSplit
        LogSTStat
        LogSTPDF
        LogSTCDF

        % Hold duration
        HDSorted
        HDStat
        HDPDF
        HDCDF

        HDvSorted
        HDvStat
        HDvPDF
        HDvCDF

        % Reaction time
        RTSorted
        RTStat
        RTPDF
        RTCDF

        % Movement time
        MTSorted
        MTStat
        MTPDF
        MTCDF
        
        % Choice time
        CTSorted
        CTStat
        CTPDF
        CTCDF
        
        % Behavior table
        BehavTable

        % Performance
        OutcomeSorted
        Performance
        PerformanceTrack

        % Interruption
        Interruption
    end

    properties (Dependent)
        % Reference data and codes for data sorting
        SortRefs
        SortCodes

        % Save name for object, figure and csv files
        SaveName
    end

    methods
        %% Initiation
        function obj = GPSBehProgressClass(SessionClassAll, ProtocolDir)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj.ProtocolDir = ProtocolDir;
            % Animal information
            obj.Subject = unique(cellfun(@(x) string(x.Subject), SessionClassAll));
            obj.Strain  = unique(cellfun(@(x) string(x.Strain), SessionClassAll));
            if length(obj.Subject)>1
                error("More than one animal");
            end

            % Task information
            obj.Task     = unique(cellfun(@(x) string(x.Task), SessionClassAll));
            obj.Protocol = unique(cellfun(@(x) string(x.Protocol), SessionClassAll));
            if length(obj.Protocol)>1
                error("More than one protocol");
            end

            % Session information
            obj.Sessions            = cellfun(@(x) string(x.Session), SessionClassAll);
            obj.NumSessions         = length(SessionClassAll);
            obj.NumTrialsSession    = cellfun(@(x) x.NumTrials, SessionClassAll);
            obj.DurationSession     = cellfun(@(x) x.TrialCentInTime(end), SessionClassAll);
            obj.TargetFP            = unique(cell2mat(cellfun(@(x) x.TargetFP, SessionClassAll, 'UniformOutput', false)), "rows");
            if size(obj.TargetFP, 1)>1 && obj.Task~="WaitHold"
                error("More than one set of target fp");
            end
            fprintf("\n%s: from %s to %s\n", obj.SaveName, obj.Sessions(1), obj.Sessions(end));

            % Experiment information
            obj.Treatment = cellfun(@(x) string(x.Treatment), SessionClassAll);
            obj.Dose      = cellfun(@(x) x.Dose, SessionClassAll);
            obj.Label     = cellfun(@(x) string(x.Label), SessionClassAll);

            % Sorting reference
            obj.SortVars   = SessionClassAll{1}.SortVars;
            obj.SortLabels = SessionClassAll{1}.SortLabels;
            for i = 2:obj.NumSessions
                if any(obj.SortVars~=SessionClassAll{i}.SortVars) || any(obj.SortLabels~=SessionClassAll{i}.SortLabels)
                    error("More than one set of sorting labels");
                end
            end

            % Behavior table
            allTables = cellfun(@(x) {x.BehavTable}, SessionClassAll, 'UniformOutput', false);
            allTables = obj.splice_data(allTables);
            allTables = obj.add_progress_info(allTables{1}, "Trials", obj.NumTrialsSession);
            allTables = obj.add_progress_info(allTables, "TrialCentInTime", obj.DurationSession);
            allTables = obj.add_progress_info(allTables, "TrialStartTime", obj.DurationSession);
            obj.BehavTable = allTables;
            obj.split_lesion_trials();
            
            % Sorted data
            obj.RTSorted.Session    = cellfun(@(x) x.RTSorted, SessionClassAll, 'UniformOutput', false);
            obj.HDSorted.Session    = cellfun(@(x) x.HDSorted, SessionClassAll, 'UniformOutput', false);
            obj.HDvSorted.Session   = cellfun(@(x) x.HDvSorted, SessionClassAll, 'UniformOutput', false);
            obj.MTSorted.Session    = cellfun(@(x) x.MTSorted, SessionClassAll, 'UniformOutput', false);
            obj.CTSorted.Session    = cellfun(@(x) x.CTSorted, SessionClassAll, 'UniformOutput', false);
            obj.get_data_sorted();

            % Splited data
            obj.STSplit.Session     = cellfun(@(x) x.STSplit, SessionClassAll, 'UniformOutput', false);
            obj.LogSTSplit.Session  = cellfun(@(x) x.LogSTSplit, SessionClassAll, 'UniformOutput', false);
            obj.get_data_split();

            % Statistics
            allSTStats              = cellfun(@(x) {x.STStat}, SessionClassAll, 'UniformOutput', false);
            allSTStats              = obj.splice_data(allSTStats);
            obj.STStat.Session      = allSTStats{1};

            allLogSTStats           = cellfun(@(x) {x.LogSTStat}, SessionClassAll, 'UniformOutput', false);
            allLogSTStats           = obj.splice_data(allLogSTStats);
            obj.LogSTStat.Session   = allLogSTStats{1};

            allHDStats          = cellfun(@(x) {x.HDStat}, SessionClassAll, 'UniformOutput', false);
            allHDStats          = obj.splice_data(allHDStats);
            obj.HDStat.Session  = allHDStats{1};

            allHDvStats         = cellfun(@(x) {x.HDvStat}, SessionClassAll, 'UniformOutput', false);
            allHDvStats         = obj.splice_data(allHDvStats);
            obj.HDvStat.Session = allHDvStats{1};
            
            allRTStats          = cellfun(@(x) {x.RTStat}, SessionClassAll, 'UniformOutput', false);
            allRTStats          = obj.splice_data(allRTStats);
            obj.RTStat.Session  = allRTStats{1};

            allMTStats          = cellfun(@(x) {x.MTStat}, SessionClassAll, 'UniformOutput', false);
            allMTStats          = obj.splice_data(allMTStats);
            obj.MTStat.Session  = allMTStats{1};

            allCTStats          = cellfun(@(x) {x.CTStat}, SessionClassAll, 'UniformOutput', false);
            allCTStats          = obj.splice_data(allCTStats);
            obj.CTStat.Session  = allCTStats{1};

%             obj.gather_stat(); % session mean
            obj.get_all_stats(1); % pooled data

            % KS density
            obj.LogSTPDF.Session = cellfun(@(x) x.LogSTPDF, SessionClassAll, 'UniformOutput', false);
            obj.LogSTCDF.Session = cellfun(@(x) x.LogSTCDF, SessionClassAll, 'UniformOutput', false);

            obj.HDPDF.Session    = cellfun(@(x) x.HDPDF, SessionClassAll, 'UniformOutput', false);
            obj.HDCDF.Session    = cellfun(@(x) x.HDCDF, SessionClassAll, 'UniformOutput', false);
            obj.HDvPDF.Session   = cellfun(@(x) x.HDvPDF, SessionClassAll, 'UniformOutput', false);
            obj.HDvCDF.Session   = cellfun(@(x) x.HDvCDF, SessionClassAll, 'UniformOutput', false);

            obj.RTPDF.Session    = cellfun(@(x) x.RTPDF, SessionClassAll, 'UniformOutput', false);
            obj.RTCDF.Session    = cellfun(@(x) x.RTCDF, SessionClassAll, 'UniformOutput', false);
            obj.MTPDF.Session    = cellfun(@(x) x.MTPDF, SessionClassAll, 'UniformOutput', false);
            obj.MTCDF.Session    = cellfun(@(x) x.MTCDF, SessionClassAll, 'UniformOutput', false);
            obj.CTPDF.Session    = cellfun(@(x) x.CTPDF, SessionClassAll, 'UniformOutput', false);
            obj.CTCDF.Session    = cellfun(@(x) x.CTCDF, SessionClassAll, 'UniformOutput', false);

            obj.get_all_kdes(0);

            % Performance
            allPerfs                = cellfun(@(x) {x.Performance}, SessionClassAll, 'UniformOutput', false);
            allPerfs                = obj.splice_data(allPerfs);
            obj.Performance.Session = allPerfs{1};

            obj.PerformanceTrack.Session = cellfun(@(x) x.PerformanceTrack, SessionClassAll, 'UniformOutput', false);
%             obj.gather_perf_track();
        end % GPSBehProgressClass

        %% Save name for object, figure and csv files
        function save_name = get.SaveName(obj)
            save_name = sprintf("GPSBehProgressClass_%s_%s", obj.Protocol, upper(obj.Subject));
        end

        %% Sorting References
        function sort_refs = get.SortRefs(obj)
            sort_refs = arrayfun(@(x) obj.BehavTable.(x), obj.SortVars, 'UniformOutput', false);
        end
        
        function sort_codes = get.SortCodes(obj)
            sort_codes = arrayfun(@(x) obj.(x), obj.SortLabels, 'UniformOutput', false);
        end

        %% Sorting function
        function get_data_sorted(obj)
            beh = obj.BehavTable;
            vars = ["HD", "HDv", "RT", "MT", "CT", "Outcome"];
            labels = ["All", "Control", "Chemo", "PreControl", "LesionEarly", "LesionExtensive"];
            for v = 1:length(vars)
                v_this = vars(v);
                data_v = beh.(v_this);
                switch v_this
                    case {'ST', 'LogST', 'HD', 'HDv', 'RT', 'Outcome'}
                        ind_v = beh.Stage==1;
                    case {'MT', 'CT'}
                        ind_v = beh.Stage==1 & beh.Outcome=="Correct";
                end

                for l = 1:length(labels)
                    lb_this = labels(l);
                    if lb_this=="All"
                        ind_this = ind_v & ismember(beh.Label, ["None", "Saline", "Control", "PreLesion", "PreControl"]);
                    else
                        ind_this = ind_v & beh.Label==lb_this;
                    end
                    if ~any(ind_this)
                        continue
                    end

                    data_this = data_v(ind_this);
                    refs_this = cellfun(@(x) x(ind_this), obj.SortRefs, 'UniformOutput', false);

                    obj.(v_this+"Sorted").(lb_this) = obj.sort_data(data_this, refs_this, obj.SortCodes);
                end
            end
        end % get_data_sorted

        %% Get splited data
        function get_data_split(obj)
            beh = obj.BehavTable;
            vars = ["ST", "LogST"];
            labels = ["All", "Control", "Chemo", "PreControl", "LesionEarly", "LesionExtensive"];
            for v = 1:length(vars)
                v_this = vars(v);
                data_v = beh.(v_this);
                switch v_this
                    case {'ST', 'LogST', 'HD', 'HDv', 'RT', 'Outcome'}
                        ind_v = beh.Stage==1;
                    case {'MT', 'CT'}
                        ind_v = beh.Stage==1 & beh.Outcome=="Correct";
                end

                for l = 1:length(labels)
                    lb_this = labels(l);
                    
                    if lb_this=="All"
                        ind_this = ind_v & ismember(beh.Label, ["None", "Saline", "Control", "PreLesion", "PreControl"]);
                    else
                        ind_this = ind_v & beh.Label==lb_this;
                    end
                    if ~any(ind_this)
                        continue
                    end

                    data_this = data_v(ind_this);
                    refs_this = {beh.Order(ind_this)};
                    code_this = {1:obj.NumOrders};
                    obj.(v_this+"Split").(lb_this) = obj.sort_data(data_this, refs_this, code_this);
                end
            end
        end % get_data_split

        %% Calculate statistics
        function get_all_stats(obj, cal_ci)
            if cal_ci
                fprintf("\nCalculate statistics from pooled data with bootstrap ci\n");
            else
                fprintf("\nCalculate statistics from pooled data\n");
            end
            beh = obj.BehavTable;
            vars = ["ST", "LogST", "HD", "HDv", "RT", "MT", "CT"];
            labels = ["All", "Control", "Chemo", "PreControl", "LesionEarly", "LesionExtensive"];
            for v = 1:length(vars)
                v_this = vars(v);
                data_v = beh.(v_this);
                switch v_this
                    case {'ST', 'LogST', 'HD', 'HDv', 'RT'}
                        ind_v = beh.Stage==1;
                    case {'MT', 'CT'}
                        ind_v = beh.Stage==1 & beh.Outcome=="Correct";
                end
                switch v_this
                    case {'ST', 'LogST'}
                        vars_this = "Order";
                        refs_v = {beh.Order};
                        code_this = {1:obj.NumOrders};
                    case {'HD', 'HDv', 'RT', 'MT', 'CT'}
                        vars_this = obj.SortVars;
                        refs_v = obj.SortRefs;
                        code_this = obj.SortCodes;
                end

                for l = 1:length(labels)
                    lb_this = labels(l);
                    if lb_this=="All"
                        ind_this = ind_v & ismember(beh.Label, ["None", "Saline", "Control", "PreLesion", "PreControl"]);
                    else
                        ind_this = ind_v & beh.Label==lb_this;
                    end
                    if ~any(ind_this)
                        continue
                    end

                    data_this = data_v(ind_this);
                    refs_this = cellfun(@(x) x(ind_this), refs_v, 'UniformOutput', false);
                    obj.(v_this+"Stat").(lb_this) = obj.get_stat(data_this, refs_this, code_this, vars_this, cal_ci);
                end
            end
        end % get_all_stats

        %% Gather statistics table
        function gather_stat(obj)
            fprintf("\nCalculate statistics using session means\n");
            vars = ["ST", "LogST", "HD", "HDv", "RT", "MT", "CT"];
            labels = ["All", "Control", "Chemo"];

            params = ["N", "Mean", "STD", "SEM", "Median", "Median_kde", "Q1", "Q3", "IQR"];
            n_params = length(params);
            for v = 1:length(vars)
                v_this = vars(v);
                switch v_this
                    case {'MT', 'CT', 'HD', 'HDv', 'RT'}
                        sort_vars = obj.SortVars;
                    case {'ST', 'LogST'}
                        sort_vars = "Order";
                end

                stat_session = obj.(v_this+"Stat").Session;
                sort_refs    = stat_session(:, sort_vars);
                ref_types    = strings(1, length(sort_vars));
                for i  = 1:length(sort_vars)
                    ref_types(i) = class(sort_refs{:,i});
                end
                for l = 1:length(labels)
                    % find statistics of current label
                    lb_this = labels(l);
                    if lb_this=="All"
                        ind = ismember(stat_session.Label, ["None", "Saline", "Control", "PreLesion"]);
                    else
                        ind = stat_session.Label==lb_this;
                    end
                    if ~any(ind)
                        continue
                    end
                    stat_this = stat_session(ind, :);
                    ref_this  = sort_refs(ind, :);
                    code_this = unique(ref_this, "stable");

                    % 
                    table_h = height(code_this);
                    table_w = 2 + length(sort_vars) + n_params + 2;
                    stat_out = table('Size', [table_h, table_w], ...
                        'VariableTypes', ["string", "string", ref_types, repmat("double", 1, n_params+2)], ...
                        'VariableNames', ["Subject", "Label", sort_vars, params, "Median_sem", "IQR_sem"]);

                    % Calculate mean of parameters
                    for i = 1:table_h
                        id_this = all(table2array(ref_this)==code_this{i,:}, 2);
                        for j = 1:length(params)
                            param_data = stat_this.(params(j))(id_this);
                            param_mean = mean(param_data, 'omitnan');
                            stat_out.(params(j))(i) = param_mean;
                        end
                        for j = 1:length(sort_vars)
                            stat_out.(sort_vars(j))(i) = ref_this{i,j};
                        end
                        stat_out.Median_sem(i) = std(stat_this.Median(id_this), 'omitnan') / sqrt(sum(~isnan(stat_this.Median(id_this))));
                        stat_out.IQR_sem(i) = std(stat_this.IQR(id_this), 'omitnan') / sqrt(sum(~isnan(stat_this.IQR(id_this))));
                    end

                    % Add information
                    stat_out.Subject = repmat(obj.Subject, table_h, 1);
                    stat_out.Label = repmat(lb_this, table_h, 1);

                    obj.(v_this+"Stat").(lb_this) = stat_out;
                end
            end
        end % gather_stat

        %% KS density
        function get_all_kdes(obj, cal_ci)
            vars = ["HD", "HDv", "RT", "MT"];
            labels = ["Control", "Chemo", "PreControl", "LesionEarly", "LesionExtensive"]; % "All", 
            for l = 1:length(labels)
                lb_this = labels(l);
                if cal_ci
                    fprintf("\n******** %s ********\n", lb_this);
                end
                for v = 1:length(vars)
                    v_this = vars(v);
                    data_sorted = obj.(v_this+"Sorted");
                    if ~isfield(data_sorted, lb_this)
                        continue
                    end

                    data_this = data_sorted.(lb_this);
                    obj.(v_this+"PDF").(lb_this) = obj.get_kde(data_this, obj.Bins.(v_this), 'pdf', v_this, cal_ci);
                    obj.(v_this+"CDF").(lb_this) = obj.get_kde(data_this, obj.Bins.(v_this), 'cdf', v_this, cal_ci);
                end
                if ~isfield(obj.LogSTSplit, lb_this)
                    continue
                end
                obj.LogSTPDF.(lb_this) = obj.get_kde(obj.LogSTSplit.(lb_this), obj.Bins.LogST, 'pdf', "LogST", cal_ci);
                obj.LogSTCDF.(lb_this) = obj.get_kde(obj.LogSTSplit.(lb_this), obj.Bins.LogST, 'cdf', "LogST", cal_ci);
            end
        end % get_all_kdes

        %% Gather performance track
        function gather_perf_track(obj)
            labels = ["All", "Control", "Chemo", "PreLesion", "Lesion"];
            for l = 1:(length(labels))
                lb_this = labels(l);
                switch lb_this
                    case {'All'}
                        ind = ismember(obj.Label, ["None", "Saline", "Control", "PreLesion"]);
                    otherwise
                        ind = obj.Label==lb_this;
                end
                if ~any(ind)
                    continue;
                end
                obj.PerformanceTrack.(lb_this) = obj.splice_data(obj.PerformanceTrack.Session(ind));
            end
        end % gather_perf_track

        function [table_new, session_sep] = add_progress_info(~, table_raw, variable, info_session)
            sessions = unique(table_raw.Session, "stable");

            session_date = table_raw.Session;
            var_sessions = table_raw.(variable);
            var_progress = zeros(height(table_raw), 1);
            session_sep  = [0; cumsum(info_session(1:end-1))];
            for i = 1:length(sessions)
                id_this = session_date==sessions(i);
                var_progress(id_this) = var_sessions(id_this) + session_sep(i);
            end
            session_sep(1) = [];
            table_new = addvars(table_raw, var_progress, 'After', variable, 'NewVariableNames', variable+"Progress");
        end % add_progress_info

        %% Find early and late lesion stage
        function split_lesion_trials(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if ~any(obj.Label=="Lesion")
                return
            end
            beh = obj.BehavTable;
            pre_id = find(beh.Label~="Lesion" & beh.Stage==1);
            lesion_id = find(beh.Label=="Lesion" & beh.Stage==1);
            num_lesion_trials = length(lesion_id);

            if num_lesion_trials >= 2*obj.PhaseLesion
                c = obj.PhaseLesion;
            else
                c = floor(num_lesion_trials / 2);
            end

            lesion_id_pre   = pre_id(end-c+1:end);
            lesion_id_early = lesion_id(1:c);
            lesion_id_late  = lesion_id(end-c+1:end);

            beh.Label(lesion_id_pre)   = "PreControl";
            beh.Label(lesion_id_early) = "LesionEarly";
            beh.Label(lesion_id_late)  = "LesionExtensive";

            obj.BehavTable.Label = beh.Label;
        end % split_lesion_trials

        %% Save and print
        function save(obj, copy_dir)
            obj.UpdateTime = string(datetime());

            if isfolder(obj.ProtocolDir)
                save_path = fullfile(obj.ProtocolDir, obj.SaveName);
                save(save_path, 'obj');
            end

            if nargin==2
                copy_path = fullfile(copy_dir, obj.SaveName);
                save(copy_path, 'obj');
            end
        end % save

        function fig = plotProgress(obj)
            fig = feval(obj.Task+".plotProgress", obj);
        end

        function print(obj, fig, varargin)
            % parsing input
            P = inputParser;

            addParameter(P, 'save_dir', obj.ProtocolDir, @(x) (ischar(x) || isstring(x)));
            addParameter(P, 'copy_dir', "", @(x) (ischar(x) || isstring(x)));
            addParameter(P, 'save_name', obj.SaveName, @(x) (ischar(x) || isstring(x)));

            parse(P, varargin{:});

            save_dir = P.Results.save_dir;
            copy_dir = P.Results.copy_dir;
            save_name = P.Results.save_name;

            % 
            fprintf("\n*********************************\n... Exporting figure ...");
            save_path = fullfile(save_dir, save_name);
            exportgraphics(fig, save_path+".png", 'Resolution', 600);
            exportgraphics(fig, save_path+".pdf", 'ContentType', 'vector');
            saveas(fig, save_path, 'fig');

            if copy_dir ~= ""
                if ~isfolder(copy_dir)
                    mkdir(copy_dir);
                end
                copy_path = fullfile(copy_dir, save_name);
                copyfile(save_path+".png", copy_path+".png");
                copyfile(save_path+".pdf", copy_path+".pdf");
                copyfile(save_path+".fig", copy_path+".fig");
            end
            fprintf("\n*********************************\n\n");
        end

    end % methods

end % GPSBehProgressClass