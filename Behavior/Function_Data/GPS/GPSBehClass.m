classdef GPSBehClass < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    properties (Constant)
        PerformanceType = ["Correct", "Premature", "Late", "Wrong"];
        PerformanceCode = [1, -1, -2, 0];
        Definition = [
            "ShuttleTime  (ST): Time of moving from port_init to port_cent";
            "HoldDuration (HD): Time from port_cent poke out to port_choice poke in (for hold paradigm only)";
            "ReactionTime (RT): For hold paradigm, it is time from tone to port_cent poke-out; for free paradigm, it is the time from tone to port_choice poke-in";
            "MovementTime (MT): For hold paradigm, it is the time from port_cent poke-out to port_choice poke-in; for free paradigm, leave it empy; for autoshaping paradigm, it is the time from port_cent poke-in to port_choice poke-in";
            "ChoiceTime   (CT):  Time from tone to port_choice poke in (for hold paradigm only)";
            ];
        PhaseCount  = 300; % Trial number to determine the early or late training phase
        PhaseLesion = 600; % Trial number to determine the pre-lesion, early-lesion and late-lesion phase
        Ports      = ["L", "R"];
        LeftRight  = [ 1 ,  2 ]; % Correct port, 1 for left; 2 for right
        CueUncue   = [ 1 ,  0 ];
        Guidance   = [ 1 ,  0,  -1]; % Guided, Empty, Filled
        BandWidth  = .05;
        NumOrders  = 3;
    end

    properties (Dependent)
        Bins
    end

    methods
        %% Initiation
        function obj = GPSBehClass(); end
        
        %% Bin-edges for ksdensity functions
        function bins = get.Bins(~)
            bins.width = .002;

            bins.LogST = -1:bins.width:2;
            bins.HD    = 0:bins.width:3;
            bins.HDv   = 0:bins.width:3;
            bins.RT    = 0:bins.width:2;
            bins.MT    = 0:bins.width:2;
            bins.CT    = 0:bins.width:2.5;

            bins.widthInter     = 0.02;
            bins.Interruption   = 0:bins.widthInter:3;
        end

        %% get PDFs and CDFs
        function data_kde = get_kde(obj, data, bin_edges, func, var_name, cal_ci)

            if cal_ci
                fprintf("... Calculate 95CI for %s of %s ... \n", func, var_name);
            end
            data_kde = cellfun(@(x) obj.cal_kde(x, bin_edges, func, cal_ci), data, 'UniformOutput', false);

        end % get_kde

        function data_kde = cal_kde(obj, data_this, bin_edges, func, cal_ci)
            kde = @(x) ksdensity(x, bin_edges, 'Function', func, 'BandWidth', obj.BandWidth);
            data_this(isnan(data_this)) = [];

            data_kde.x = bin_edges;
            data_kde.ci = [];
            if length(data_this) >= 5
                data_kde.f = kde(data_this);
                if cal_ci
                    data_kde.ci = bootci(1000, {kde, data_this}, 'type', 'cper', 'alpha', .05);
                end
            else
                data_kde.f = zeros(1, length(bin_edges));
            end
        end % cal_kde

        %% Data pre-processing
        function data_sorted = sort_data(obj, data_origin, sort_refs, sort_codes)

            % Check inputs
            if isempty(sort_refs)
                data_sorted = {data_origin};
                return
            end
            n_refs = cellfun(@length, sort_refs);

            if isvector(data_origin)
                data_origin = data_origin(:);
                n_data = length(data_origin);
            elseif ismatrix(data_origin) && ~iscell(data_origin)
                n_data = size(data_origin, 1);
            else
                error("data_origin should be a vector or a matrix");
            end
            
            if ~all(n_refs==n_data)
                error("Length of reference data should be equal to the number of data to be sorted");
            end

            % Get output size
            sz = cellfun(@length, sort_codes);
            if length(sz)==1
                data_sorted = cell([sz, 1]);
            else
                data_sorted = cell(sz);
            end

            code_this = sort_codes{1};
            ref_this = sort_refs{1};
            if length(sort_codes)>1 % recursion, if more than one reference variable remains
                for i = 1:length(code_this)
                    ind_this = ref_this==code_this(i);
                    data_now = data_origin(ind_this, :);
                    refs_now = cellfun(@(x) x(ind_this), sort_refs(2:end), 'UniformOutput', false);

                    data_sorted_i = obj.sort_data(data_now, refs_now, sort_codes(2:end));
                    data_sorted(i,:) = data_sorted_i(:);
                end
            else
                for i = 1:length(code_this)
                    ind_this = ref_this==code_this(i);
                    data_sorted{i} = data_origin(ind_this, :);
                end
            end
        end % sort_data

        function table_sorted = sort_table(obj, table_raw, sort_vars, sort_codes)

            % Check inputs
            if ~istable(table_raw)
                error("table_raw should be a table");
            end
            
            if isempty(sort_vars)
                table_sorted = {table_raw};
                return
            end

            % Get output size
            sz = cellfun(@length, sort_codes);
            if length(sort_codes)==1
                table_sorted = cell([sz, 1]);
            else
                table_sorted = cell(sz);
            end

            code_this = sort_codes{1};
            var_this = sort_vars(1);
            ref_this = table_raw.(var_this);
            if length(sort_codes)>1 % recursion, if more than one reference variable remains
                for i = 1:length(code_this)
                    ind_this = ref_this==code_this(i);
                    table_now = table_raw(ind_this, :);
                    vars_now = sort_vars(2:end);

                    data_sorted_i = obj.sort_table(table_now, vars_now, sort_codes(2:end));
                    table_sorted(i,:) = data_sorted_i(:);
                end
            else
                for i = 1:length(code_this)
                    ind_this = ref_this==code_this(i);
                    table_sorted{i} = table_raw(ind_this, :);
                end
            end
        end % sort_data

        function [data_splited, order] = split_data(~, data_origin, n)
            data_splited = cell(n, 1);
            order = cell(n, 1);

            num_data = length(data_origin);
            ind = 1:num_data;
%             [~, ~, indrmv] = rmoutliers_custome(data_origin);

            for i = 1:n
                ind_range = [i-1 i] * num_data/n;
                ind_this = ind>ind_range(1) & ind<=ind_range(2);
                data_splited{i} = data_origin(ind_this);
                order{i} = i * ones(length(data_splited{i}), 1);
            end

        end % split_data

        function data_spliced = splice_data(obj, data_cell)
            sz = size(data_cell{1});
            if length(sz)==1
                data_spliced = cell([sz, 1]);
            else
                data_spliced = cell(sz);
            end

            if length(sz)==2 && sz(2)==1
                for i = 1:sz
                    data_this = cellfun(@(x) x{i}, data_cell, 'UniformOutput', false);
                    data_spliced{i} = vertcat(data_this{:});
                end
            else  % recursion
                sz_now = sz(2:end);
                if length(sz_now)==1
                    sz_now = [sz_now, 1];
                end
                for i = 1:sz(1)
                    data_now = cellfun(@(x) squeeze(x(i,:)), data_cell, 'UniformOutput', false);
                    data_now = cellfun(@(x) reshape(x, sz_now), data_now, 'UniformOutput', false);
                    data_splice_i = obj.splice_data(data_now);
                    data_spliced(i,:) = data_splice_i(:);
                end
            end
        end % splice_data

        %% Get statistics
        function stat_table = get_stat(obj, data_origin, sort_refs, sort_codes, sort_vars, cal_ci)

            data_sorted = obj.sort_data(data_origin, sort_refs, sort_codes);

            data_origin(isnan(data_origin)) = [];
            data_2575 = prctile(data_origin, [25, 75]);
            interq = data_2575(2) - data_2575(1);
            c = 5; % threshold for removing outliers
            bound_l = data_2575(1)-interq*c;
            bound_u = data_2575(2)+interq*c;
            
            stat_table_cell = cellfun(@(x) obj.cal_stat(x(x>=bound_l & x<=bound_u), cal_ci), data_sorted, 'UniformOutput', false);
            stat_table = vertcat(stat_table_cell{:});

            stat_table = obj.add_sort_info(stat_table, sort_codes, sort_vars);
        end % get_stat

        function stat_this = cal_stat(~, data_this, cal_ci)

            dur_this = calDur(data_this, [], "Remove100ms", 0, "RemoveOutliers", 0, 'CalSE', 0);

            N = sum(~isnan(data_this));

            Mean = dur_this.mean;
            STD = dur_this.std;
            SEM = dur_this.sem;

            Median = dur_this.median;
            Median_kde = dur_this.median_ksdensity;
            Q1 = dur_this.q1;
            Q3 = dur_this.q3;
            IQR = Q3 - Q1;

            if ~cal_ci
                stat_this = table(N, Mean, STD, SEM, Median, Median_kde, Q1, Q3, IQR);
            else
                if ~isnan(Median)
                    med_ci = bootci(1000, {@(x) median(x, 'omitnan'), data_this}, 'Type', 'cper');
                    iqr_ci = bootci(1000, {@iqr, data_this}, 'Type', 'cper');
                else
                    med_ci = [nan nan];
                    iqr_ci = [nan nan];
                end
                Median_ci_l = med_ci(1);
                Median_ci_u = med_ci(2);
                IQR_ci_l = iqr_ci(1);
                IQR_ci_u = iqr_ci(2);
                stat_this = table(N, Mean, STD, SEM, Median, Median_ci_l, Median_ci_u, Median_kde, Q1, Q3, IQR, IQR_ci_l, IQR_ci_u);
            end
            
        end % cal_stat

        %% Get performance ratio
        function perf_table = get_perfs(obj, data_outcome, sort_refs, sort_codes, sort_vars)

            data_sorted = obj.sort_data(data_outcome, sort_refs, sort_codes);

            perf_table_cell = cellfun(@(x) obj.cal_ratio(x, obj.PerformanceType), data_sorted, 'UniformOutput', false);
            perf_table = vertcat(perf_table_cell{:});

            perf_table = obj.add_sort_info(perf_table, sort_codes, sort_vars);
        end % get_perfs

        function ratio_table = cal_ratio(~, data_origin, labels)

            n_labels = length(labels);
            ratio_table = table('Size', [1, 1+n_labels], 'VariableTypes', repmat("double", 1, 1+n_labels), ...
                'VariableNames', ["N", labels]);

            if isempty(data_origin)
                ratio_table.N = 0;
                for i = 1:n_labels
                    ratio_table.(labels(i)) = 0;
                end
                return
            end

            counts = zeros(n_labels, 1);
            for i = 1:n_labels
                counts(i) = sum(data_origin==labels(i));
            end
            counts_total = sum(counts);

            ratios = counts ./ counts_total;
            
            ratio_table.N = counts_total;
            for i = 1:n_labels
                ratio_table.(labels(i)) = ratios(i);
            end
        end % cal_ratio

        %% Get tracks
        function perf_track = get_perf_track(obj, data_outcome, data_index, sort_refs, sort_codes)
            outcome_sorted = obj.sort_data(data_outcome, sort_refs, sort_codes);
            index_sorted = obj.sort_data(data_index, sort_refs, sort_codes);

            win_sz = cellfun(@(x) floor(length(x)/5), outcome_sorted, 'UniformOutput', false);
            step_sz = cellfun(@(x) max(1, floor(x/5)), win_sz, 'UniformOutput', false);

            outcome_track = cellfun(@(x, w_z, s_z) obj.cal_ratio_track(x, obj.PerformanceType, w_z, s_z), ...
                outcome_sorted, win_sz, step_sz, 'UniformOutput', false);
            index_track = cellfun(@(x, w_z, s_z) obj.cal_data_track(x, w_z, s_z), ...
                index_sorted, win_sz, step_sz, 'UniformOutput', false);

            perf_track = cellfun(@(o, i) addvars(o, i, 'NewVariableNames', "Pos", 'Before', "N"), ...
                outcome_track, index_track, 'UniformOutput', false);
        end % get_perf_track

        function [data_track, index_track] = get_data_track(obj, data_origin, data_index, sort_refs, sort_codes)
            data_sorted = obj.sort_data(data_origin, sort_refs, sort_codes);
            index_sorted = obj.sort_data(data_index, sort_refs, sort_codes);

            win_sz = cellfun(@(x) floor(length(x)/5), data_sorted, 'UniformOutput', false);
            step_sz = cellfun(@(x) max(1, floor(x/5)), win_sz, 'UniformOutput', false);

            data_track = cellfun(@(x, w_z, s_z) obj.cal_data_track(x, w_z, s_z), ...
                data_sorted, win_sz, step_sz, 'UniformOutput', false);
            index_track = cellfun(@(x, w_z, s_z) obj.cal_data_track(x, w_z, s_z), ...
                index_sorted, win_sz, step_sz, 'UniformOutput', false);
        end % get_perf_track

        function ratio_track_table = cal_ratio_track(obj, data_origin, labels, win_sz, step_sz)
            n_labels = length(labels);
            num_trials = length(data_origin);
            length_track = floor((num_trials-win_sz+1)/step_sz);

            ratio_track_table = table('Size', [length_track, 1+n_labels], ...
                'VariableTypes', repmat("double", 1, 1+n_labels), ...
                'VariableNames', ["N", labels]);

            count_start = 1;
            i = 1;
            while count_start+win_sz-1 <= num_trials
                win_this = count_start:(count_start+win_sz-1);
                ratio_track_table(i,:) = obj.cal_ratio(data_origin(win_this), labels);
                count_start = count_start + step_sz;
                i = i+1;
            end
        end % cal_ratio_track

        function data_track = cal_data_track(~, data_origin, win_sz, step_sz)
            num_trials = size(data_origin, 1);
            length_track = floor((num_trials-win_sz+1)/step_sz);
            data_track = zeros(length_track, 1);

            count_start = 1;
            i = 1;
            while count_start+win_sz-1 <= num_trials
                win_this = count_start:(count_start+win_sz-1);
                data_track(i) = sum(data_origin(win_this, :)) / win_sz;
                count_start = count_start + step_sz;
                i = i+1;
            end
        end % cal_data_track

        %% Add information to table
        function table_new = add_sort_info(~, table_raw, sort_codes, sort_vars)

            if isempty(sort_codes)
                table_new = table_raw;
                return;
            end

            sz = cellfun(@length, sort_codes);
            var_types = cellfun(@class, sort_codes, 'UniformOutput', false);
            info = table('Size', [prod(sz), length(sz)], ...
                'VariableTypes', string(var_types), ...
                'VariableNames', sort_vars);

            for i = 1:length(sort_codes)
                info_this = repmat(sort_codes{i}, prod(sz(1:i-1)), prod(sz(i+1:end)));
                info.(sort_vars(i)) = info_this(:);
            end

            table_new = horzcat(info, table_raw);
        end % add_sort_info

    end
end