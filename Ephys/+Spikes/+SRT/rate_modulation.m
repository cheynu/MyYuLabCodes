classdef rate_modulation < handle
    % Jianing Yu, 2026.1.21

    % RATE_MODULATION  Event-locked firing rate modulation analysis from a bin table.
    % The table is from function [sdf_struct, spk_data_tab] = build_sdf_and_spkcount_table(spktimes, beh_tab, varargin)

    % Input table format (long):
    %   trial_id, event, bin_start_ms, bin_end_ms, bin_center_ms,
    %   spike_count, outcome, type, FP, (optional more covariates)
    %
    % Typical usage:
    %   rm = rate_modulation(spk_data_tab, 'UnitID', "rat1_ch12_u3");
    %   rm = rm.clean();  % convert outcome/type to string/categorical
    %
    %   % Error vs Correct around release (cluster permutation)
    %   cfg = struct('Event',"release", 'GroupVar',"outcome", ...
    %                'GroupA',"Correct", 'GroupB',"Dark", ...
    %                'TimeRange',[-300 500], 'AlphaBin',0.05, ...
    %                'NPerm',2000, 'MinClusterBins',2, ...
    %                'Tail',"two");
    %   out = rm.contrastByTime(cfg);
    %   rm.plotContrast(out);
    %
    %   % Event modulation (post vs pre) within a subset (e.g. Correct only)
    %   cfg2 = struct('Event',"trigger", 'TimeRange',[-300 300], ...
    %                 'PreRange',[-300 0], 'PostRange',[0 300], ...
    %                 'NPerm',2000, 'MinClusterBins',2);
    %   out2 = rm.eventModulation(cfg2);
    %   rm.plotModulation(out2);
    properties
        T table
        unit_id string = ""
        bin_size double = NaN  % ms (inferred)
    end

    methods
        function obj = rate_modulation(spk_data_tab, varargin)
            % rate_modulation(spk_data_tab, 'UnitID', "...")
            obj.T = spk_data_tab;

            p = inputParser;
            p.addParameter('UnitID', "", @(x) ischar(x) || isstring(x));
            p.parse(varargin{:});
            obj.unit_id = string(p.Results.UnitID);

            obj.bin_size = obj.inferBinSize();
        end

        function obj = clean(obj, varargin)
            % clean table types; optionally drop WarmUp etc.
            p = inputParser;
            p.addParameter('DropWarmUp', false, @(x)islogical(x)||isnumeric(x));
            p.addParameter('WarmUpLabel', "WarmUp", @(x)ischar(x)||isstring(x));
            p.parse(varargin{:});

            % event -> string
            if ~isstring(obj.T.event)
                obj.T.event = string(obj.T.event);
            end

            % outcome/type: turn cellstr -> string if needed
            for v = ["outcome","type"]
                if ismember(v, obj.T.Properties.VariableNames)
                    if iscell(obj.T.(v))
                        obj.T.(v) = string(obj.T.(v));
                    elseif ~isstring(obj.T.(v))
                        obj.T.(v) = string(obj.T.(v));
                    end
                end
            end

            % optional: categorical
            for v = ["outcome","type","event"]
                if ismember(v, obj.T.Properties.VariableNames)
                    obj.T.(v) = categorical(obj.T.(v));
                end
            end

            if p.Results.DropWarmUp && ismember("type", obj.T.Properties.VariableNames)
                obj.T = obj.T(obj.T.type ~= categorical(string(p.Results.WarmUpLabel)), :);
            end
        end
        % ------------------------------
        % Core analysis 1: Condition contrast (A vs B) across time bins
        % ------------------------------
        function out = contrastByTime(obj, cfg)
            % out = contrastByTime(cfg)

            %   Main quesiton: Around a given event, are spike counts different between two trial groups (A vs B) at any time bin?
            % and if yes, when does the difference start (pre vs post) using the same cluster-permutation logic.

            %
            % Required cfg fields:
            %   Event (string) e.g. "release"
            %   GroupVar (string) e.g. "outcome"
            %   GroupA, GroupB (string) labels
            % Optional:
            %   TimeVar (default "bin_center_ms")
            %   CountVar (default "spike_count")
            %   TimeRange (default [-Inf Inf])
            %   Tail ("two"|"right"|"left") default "two"
            %   AlphaBin (default 0.05) threshold for cluster forming
            %   NPerm (default 2000)
            %   MinClusterBins (default 2)
            %   Restrict (struct of additional filters, e.g. Restrict.FP=500)
            %   StratifyVar (string): shuffle labels within strata (e.g., "FP")

            cfg = obj.fillDefaults(cfg, struct( ...
                'TimeVar', "bin_center_ms", ...
                'CountVar', "spike_count", ...
                'TimeRange', [-Inf Inf], ...
                'Tail', "two", ...
                'AlphaBin', 0.05, ...
                'NPerm', 2000, ...
                'MinClusterBins', 2, ...
                'Restrict', struct(), ...
                'StratifyVar', "" ));

            T = obj.subsetTable(cfg);

            if height(T)==0
                out = obj.emptyOut("contrastByTime", cfg, "No rows after filtering.");
                return;
            end

            % pivot to trial x time matrix for each group
            % * `XA` is (n_A \times n_\text{bins})
            % * `XB` is (n_B \times n_\text{bins})
            % * each column is one "sample" (time bin)
            % * each row is a trial
            [times, XA, trialA] = obj.trialTimeMatrix(T, cfg.Event, cfg.GroupVar, cfg.GroupA, cfg.TimeVar, cfg.CountVar, cfg.TimeRange);
            [times2, XB, trialB] = obj.trialTimeMatrix(T, cfg.Event, cfg.GroupVar, cfg.GroupB, cfg.TimeVar, cfg.CountVar, cfg.TimeRange);
            % 
            if isempty(XA) || isempty(XB) || ~isequal(times, times2)
                out = obj.emptyOut("contrastByTime", cfg, "No data for one group or time bins mismatch.");
                return;
            end

            % per-bin test statistic + p-value
            % Note that this is a rank sum test!
            [statObs, pObs, effProb, effMean] = obj.perBinRankSum(XA, XB, cfg.Tail);

            % cluster-based permutation on max cluster mass
            permMax = obj.permuteMaxClusterMass(T, cfg, times, XA, XB, statObs);

            % determine significant clusters
            clusters = obj.findClusters(pObs, statObs, cfg.AlphaBin, cfg.MinClusterBins, cfg.Tail);

            if isempty(permMax)
                thr = NaN;
            else
                thr = prctile(abs(permMax), 95);  % alpha = 0.05 family-wise
            end

            % score clusters, compute corrected p
            clusters = obj.scoreClusters(clusters, statObs, permMax);
            out = struct();
            out.kind          = "contrastByTime";
            out.unit_id       = obj.unit_id;
            out.cfg           = cfg;
            out.times_ms      = times;
            out.nA            = size(XA,1);
            out.nB            = size(XB,1);
            out.trialsA       = trialA;
            out.trialsB       = trialB;
            out.stat          = statObs;   % rank-sum z (signed)
            out.p_unc         = pObs;
            out.effect_prob     = effProb;
            out.effect_mean     = effMean;
            % choose what you want for out.effect (for plotting)
            out.effect          = out.effect_mean;
            out.perm_maxMass  = permMax;
            out.cluster_thr   = thr;
            out.clusters      = clusters;
            out = obj.addPrimaryCluster(out);   % <-- reuse the same helper
            out.class = obj.classifyFromClustersPrimary(out.clusters, out.times_ms);

        end

        % ------------------------------
        % Core analysis 2: Event modulation (Post vs Pre) within subset
        % ------------------------------
        function out = eventModulation(obj, cfg)
            % Compare post vs pre within the same trials.
            %
            % Required:
            %   Event
            %   PreRange  [t1 t2] ms
            %   PostRange [t1 t2] ms
            % Optional similar to contrastByTime:
            %   TimeRange, NPerm, AlphaBin, MinClusterBins, Restrict, StratifyVar
            %
            % Implementation: convert to "two conditions" by labeling bins as PRE/POST and
            % testing difference across trials at each bin (paired not enforced here).
            % If you want paired, we can switch to sign-rank on trial-wise differences later.
            % % "cluster-based permutation correction across peri-event time bins (Maris & Oostenveld, 2007; Nichols & Holmes, 2002)."
            % Maris, E. & Oostenveld, R. (2007).
            % Nonparametric statistical testing of EEG- and MEG-data.
            % Journal of Neuroscience Methods.
            % → This is the canonical paper that lays out: threshold bins → form clusters → use permutation distribution of the maximum cluster statistic to control family-wise error.
            % Nichols, T.E. & Holmes, A.P. (2002).
            % Nonparametric permutation tests for functional neuroimaging: a primer with examples.
            % Human Brain Mapping.
            % → General permutation framework; the "max statistic" idea for multiple comparisons is foundational and is exactly what your permMax is doing.
            cfg = obj.fillDefaults(cfg, struct( ...
                'TimeVar', "bin_center_ms", ...
                'CountVar', "spike_count", ...
                'TimeRange', [-Inf Inf], ...
                'PreRange', [-300 0], ...
                'PostRange', [0 300], ...
                'Tail', "both", ...
                'AlphaBin', 0.05, ...
                'NPerm', 2000, ...
                'MinClusterBins', 2, ...
                'Restrict', struct(), ...
                'StratifyVar', "" ));
            out = struct();
            T = obj.subsetTable(cfg);

            if height(T)==0
                out = obj.emptyOut("eventModulation", cfg, "No rows after filtering.");
                return;
            end

            % only keep bins within TimeRange and for this event
            T = T(T.event == categorical(string(cfg.Event)), :);
            t = T.(cfg.TimeVar);
            T = T(t >= cfg.TimeRange(1) & t <= cfg.TimeRange(2), :);

            % define groups PRE vs POST by bin_center_ms
            isPre  = T.(cfg.TimeVar) >= cfg.PreRange(1)  & T.(cfg.TimeVar) <  cfg.PreRange(2);
            isPost = T.(cfg.TimeVar) >= cfg.PostRange(1) & T.(cfg.TimeVar) <  cfg.PostRange(2);

            % If you want "time-resolved modulation", it's better to test each bin vs baseline.
            % Here we do it time-resolved by comparing each bin to the whole PRE distribution across trials.
            % Build trial x time matrix (all bins) and baseline trial-wise mean in pre window.
            [times, X, trials] = obj.trialTimeMatrixFromEvent(T, cfg.Event, cfg.TimeVar, cfg.CountVar, cfg.TimeRange);
            if isempty(X)
                out = obj.emptyOut("eventModulation", cfg, "No data after pivot.");
                return;
            end

            preBins = times >= cfg.PreRange(1) & times < cfg.PreRange(2);
            if ~any(preBins)
                out = obj.emptyOut("eventModulation", cfg, "No bins found in PreRange.");
                return;
            end

            baseline = mean(X(:, preBins), 2, 'omitnan'); % per-trial baseline computed from preBins. it is a n_trial x 1 matrix, each trial gives a mean could across all preBins
            % baseline: nTrials × 1 vector
            % baseline(i) = average spike count per bin in the pre window for trial i
            % 'omitnan' ignores NaNs (e.g., if some trial is missing a bin due to dropped data or uneven binning)

            % Compare each time bin against baseline using sign-rank on (X(:,k) - baseline)
            % For each time bin k, it compares spike counts in that bin to
            % the baseline within the **same trial**, thus it is a signed
            % rank test!
            [statObs, pObs, effProb, effMean] = obj.perBinSignedRank(X, baseline, cfg.Tail, preBins);
            % statObs(k) is a signed z-like statistic from the Wilcoxon
            % signed-rank test at bin k

            out.effect_prob = effProb;
            out.effect_mean = effMean;

            % Permutation: shuffle time labels? Here better: flip signs within trials (paired null)
            permMax = obj.permuteMaxClusterMass_paired(X, baseline, cfg, statObs);
            clusters = obj.findClusters(pObs, statObs, cfg.AlphaBin, cfg.MinClusterBins, cfg.Tail);
            
            % Important: testing if the cluster(s) in observed data are
            % significant compared to the permutation data. 
            clusters = obj.scoreClusters(clusters, statObs, permMax);

            out.kind         = "eventModulation";
            out.unit_id      = obj.unit_id;
            out.cfg          = cfg;
            out.times_ms     = times;
            out.spk_count    = X;
            out.nTrials      = size(X,1);
            out.trials       = trials;
            out.stat         = statObs;  % signed-rank z approx (signed)
            out.p_unc        = pObs;
            % choose a default for out.effect (I'd default to prob for sparse units)
            out.effect = out.effect_prob;
            out.perm_maxMass = permMax;
            out.clusters     = clusters;
            out = obj.addPrimaryCluster(out);

            out.class = obj.classifyFromClustersPrimary(clusters, out.times_ms);
        end

        % ------------------------------
        % Plot helpers
        % ------------------------------
        function plotContrast(obj, out)
            if isfield(out,'times_ms')==0 || isempty(out.times_ms), return; end
            figure('Color','w','Name',sprintf('contrast | %s | %s', obj.unit_id, out.cfg.Event));
            t = out.times_ms;
            subplot(2,1,1);
            plot(t, out.effect_mean, 'k-'); hold on;
            yline(0,'k:');
            xline(0,'k-');
            xlabel('Time (ms)'); ylabel('Mean diff (A-B)');

            A = obj.labelToStr(out.cfg.GroupA);
            B = obj.labelToStr(out.cfg.GroupB);

            title(sprintf('%s: %s %s vs %s | n=%d,%d | class=%s', ...
                obj.unit_id, out.cfg.GroupVar, A, B, out.nA, out.nB, out.class.label), ...
                'Interpreter','none');

            subplot(2,1,2);
            plot(t, -log10(out.p_unc), 'k-'); hold on;
            xline(0,'k-');
            yline(-log10(out.cfg.AlphaBin),'k:');
            xlabel('Time (ms)'); ylabel('-log10(p)');

            % overlay significant clusters (corrected)
            obj.overlayClusters(out);
        end

        function plotModulation(obj, out)
            if isfield(out,'times_ms')==0 || isempty(out.times_ms), return; end
            figure('Color','w','Name',sprintf('modulation | %s | %s', obj.unit_id, out.cfg.Event));
            t = out.times_ms;
            subplot(2,1,1);
            plot(t, out.effect_mean, 'k-'); hold on;
            yline(0,'k:'); xline(0,'k-');
            xlabel('Time (ms)'); ylabel('Mean (bin - baseline)');
            title(sprintf('%s: %s modulation | n=%d | class=%s', obj.unit_id, out.cfg.Event, out.nTrials, out.class.label), ...
                'Interpreter','none');

            subplot(2,1,2);
            plot(t, -log10(out.p_unc), 'k-'); hold on;
            xline(0,'k-');
            yline(-log10(out.cfg.AlphaBin),'k:');
            xlabel('Time (ms)'); ylabel('-log10(p)');

            obj.overlayClusters(out);
        end
    end

    

    % ==========================
    % Private helper methods
    % ==========================
    methods (Access = private)

        function bs = inferBinSize(obj)
            bs = NaN;
            if ~ismember("bin_start_ms", obj.T.Properties.VariableNames) || ...
                    ~ismember("bin_end_ms", obj.T.Properties.VariableNames)
                return;
            end
            d = unique(obj.T.bin_end_ms - obj.T.bin_start_ms);
            d = d(~isnan(d));
            if ~isempty(d), bs = median(double(d)); end
        end

        function cfg = fillDefaults(~, cfg, defs)
            if ~isstruct(cfg), error('cfg must be a struct.'); end
            fn = fieldnames(defs);
            for k = 1:numel(fn)
                if ~isfield(cfg, fn{k}) || isempty(cfg.(fn{k}))
                    cfg.(fn{k}) = defs.(fn{k});
                end
            end
        end

        function T = subsetTable(obj, cfg)
            T = obj.T;

            % -------------------------
            % 1) Event filter (robust to types and list inputs)
            % -------------------------
            if isfield(cfg,'Event') && ~isempty(cfg.Event) && ismember("event", T.Properties.VariableNames)
                evWanted = cfg.Event;

                % normalize wanted events to string array (possibly multiple)
                if ischar(evWanted), evWanted = string(evWanted); end
                if iscell(evWanted), evWanted = string(evWanted); end
                if isstring(evWanted)
                    % ok
                else
                    % if user passed categorical or something else
                    try
                        evWanted = string(evWanted);
                    catch
                        error('cfg.Event must be char/string/cellstr/categorical.');
                    end
                end

                col = T.event;

                % do comparison based on column type
                if iscategorical(col)
                    % map to same categories; unknowns become <undefined>
                    evCat = categorical(evWanted, categories(col));
                    keep = ismember(col, evCat);

                elseif isstring(col)
                    keep = ismember(col, evWanted);

                elseif iscellstr(col) || iscell(col)
                    % could be cellstr or mixed cell; convert safely
                    keep = ismember(string(col), evWanted);

                elseif ischar(col)
                    keep = ismember(string(col), evWanted);

                else
                    % last resort: compare via string representation
                    keep = ismember(string(col), evWanted);
                end

                T = T(keep, :);
            end

            % -------------------------
            % 2) Time range filter
            % -------------------------
            if isfield(cfg,'TimeVar') && ~isempty(cfg.TimeVar) && isfield(cfg,'TimeRange') ...
                    && ~isempty(cfg.TimeRange) && numel(cfg.TimeRange) == 2 ...
                    && ismember(cfg.TimeVar, T.Properties.VariableNames)

                t = T.(cfg.TimeVar);
                tr = cfg.TimeRange;

                % guard against non-numeric time vectors
                if ~isnumeric(t)
                    try
                        t = double(t);
                    catch
                        error('Time variable "%s" is not numeric and cannot be converted.', cfg.TimeVar);
                    end
                end

                T = T(t >= tr(1) & t <= tr(2), :);
            end

            % -------------------------
            % 3) Extra restriction filters (exact match, supports multi-values)
            % -------------------------
            if isfield(cfg,'Restrict') && isstruct(cfg.Restrict)
                R = cfg.Restrict;
                rfn = fieldnames(R);

                for k = 1:numel(rfn)
                    v = rfn{k};
                    if ~ismember(v, T.Properties.VariableNames)
                        continue
                    end

                    val = R.(v);
                    if isempty(val)
                        continue
                    end

                    col = T.(v);

                    % normalize desired values: allow scalar or list
                    if ischar(val)
                        val = string(val);
                    elseif iscell(val)
                        val = string(val);
                    elseif isstring(val)
                        % ok (could be scalar or vector)
                    elseif iscategorical(val)
                        val = string(val);
                    else
                        % numeric/logical/etc keep as-is
                    end

                    % apply restriction depending on column type
                    if iscategorical(col)
                        % compare categoricals safely (supports multi)
                        valCat = categorical(string(val), categories(col));
                        keep = ismember(col, valCat);

                    elseif isstring(col)
                        keep = ismember(col, string(val));

                    elseif iscellstr(col) || iscell(col)
                        keep = ismember(string(col), string(val));

                    elseif isnumeric(col) || islogical(col)
                        if isnumeric(val) || islogical(val)
                            keep = ismember(col, val);
                        else
                            % user passed strings but column is numeric -> try convert
                            vv = str2double(string(val));
                            keep = ismember(col, vv);
                        end

                    else
                        % fallback: compare as strings
                        keep = ismember(string(col), string(val));
                    end

                    T = T(keep, :);
                end
            end
        end

        function out = addPrimaryCluster(obj, out)
            % addPrimaryCluster
            % Primary = significant cluster (p_corr <= 0.05) with max |mass|
            % If none significant, pick max |mass| as a non-significant candidate.

            % ---------- default primary (always populated, never empty) ----------
            primary = struct( ...
                'index', NaN, ...
                'cluster', struct(), ...
                'idx', [], ...
                'time_ms', [], ...
                'onset_ms', NaN, ...
                'mass', NaN, ...
                'p_corr', NaN, ...
                'direction', "none", ...
                'is_significant', false);

            % no clusters → keep defaults + write flat copies
            if ~isfield(out,'clusters') || isempty(out.clusters) || ~isfield(out,'times_ms') || isempty(out.times_ms)
                out.primary = primary;
                out = obj.copyPrimaryScalars(out);
                return;
            end

            % ---------- choose best cluster ----------
            pc = [out.clusters.p_corr];
            sig = pc <= 0.05;

            masses = [out.clusters.mass];
            if any(sig)
                masses_for_pick = masses;
                masses_for_pick(~sig) = 0;             % ignore nonsig for primary pick
                [~, iBest] = max(abs(masses_for_pick));
                primary.is_significant = true;
            else
                [~, iBest] = max(abs(masses));         % best candidate even if nonsig
                primary.is_significant = false;
            end

            c = out.clusters(iBest);

            % ---------- fill primary ----------
            primary.index   = iBest;
            primary.cluster = c;                       % keep the original cluster struct
            primary.idx     = c.idx;

            primary.time_ms = out.times_ms(c.idx);
            if ~isempty(primary.time_ms)
                primary.onset_ms = primary.time_ms(1);
            end

            primary.mass   = c.mass;
            primary.p_corr = c.p_corr;

            if primary.mass > 0
                primary.direction = "up";
            elseif primary.mass < 0
                primary.direction = "down";
            else
                primary.direction = "none";
            end

            out.primary = primary;

            p = out.primary;

            % ----- add primary_ prefix for easy referencing -----
            out.primary_index      = p.index;
            out.primary_time_ms    = p.time_ms;
            out.primary_onset_ms   = p.onset_ms;
            out.primary_direction  = p.direction;
            out.primary_p_corr     = p.p_corr;
            out.primary_mass       = p.mass;
            out.primary_is_significant = p.is_significant;

            % Optional: keep the old out.primary field name behavior too
            out.primary_cluster = p.cluster;
        end

        function [times, X, trial_ids] = trialTimeMatrix(obj, T, eventName, groupVar, groupLabel, timeVar, countVar, timeRange)
            % Filter to event + group, then pivot to trial x time
            if ~ismember(groupVar, T.Properties.VariableNames)
                times=[]; X=[]; trial_ids=[];
                return;
            end

            T = T(T.event == categorical(string(eventName)), :);
            g = T.(groupVar);

            % normalize label types
            if ~isempty(groupLabel)
                % normalize groupLabel into a categorical vector "want"
                if iscategorical(g)
                    want = categorical(string(groupLabel));
                    keep = ismember(g, want);
                else
                    % compare as strings
                    want = string(groupLabel);
                    keep = ismember(string(g), want);
                end

                T = T(keep, :);
            end

            t = T.(timeVar);
            T = T(t >= timeRange(1) & t <= timeRange(2), :);

            [times, X, trial_ids] = obj.trialTimeMatrixFromEvent(T, eventName, timeVar, countVar, timeRange);
        end

        function [times, X, trial_ids] = trialTimeMatrixFromEvent(~, T, eventName, timeVar, countVar, timeRange)
            % Pivot: rows=trial_id, cols=unique time bins; values=spike_count
            if height(T)==0
                times=[]; X=[]; trial_ids=[];
                return;
            end

            % ensure sorted times
            times = unique(double(T.(timeVar)));
            times = times(times >= timeRange(1) & times <= timeRange(2));
            times = sort(times);

            trial_ids = unique(T.trial_id);
            trial_ids = sort(trial_ids);

            X = nan(numel(trial_ids), numel(times));

            % map indices
            [~, ti] = ismember(double(T.(timeVar)), times);
            [~, ri] = ismember(T.trial_id, trial_ids);

            % fill (assumes one entry per trial×bin; if duplicates, sum)
            for k = 1:height(T)
                r = ri(k); c = ti(k);
                if r==0 || c==0, continue; end
                if isnan(X(r,c))
                    X(r,c) = double(T.(countVar)(k));
                else
                    X(r,c) = X(r,c) + double(T.(countVar)(k));
                end
            end
        end

        function [z, p, effProb, effMean] = perBinRankSum(~, XA, XB, tail)
            % effProb: ΔP(spike)
            % effMean: Δmean spikes/bin (A-B)

            nT = size(XA,2);
            z = nan(1,nT); p = nan(1,nT);
            effProb = nan(1,nT); effMean = nan(1,nT);

            for k = 1:nT
                a = XA(:,k); b = XB(:,k);
                a = a(~isnan(a)); b = b(~isnan(b));
                if numel(a)<3 || numel(b)<3, continue; end

                effProb(k) = mean(a > 0) - mean(b > 0);
                effMean(k) = mean(a) - mean(b);

                try
                    [p(k),~,st] = ranksum(a, b, 'tail', char(tail));
                catch
                    [p(k),~,st] = ranksum(a, b);
                end
                if isfield(st,'zval'), z(k) = st.zval; end
            end
        end


        function [z, p, effProb, effMean] = perBinSignedRank(~, X, baseline, tail, preBins)
            % perBinSignedRank  Robust paired per-bin test vs baseline for sparse spike counts.
            %
            % Inputs:
            %   X        : nTrials x nBins spike counts
            %   baseline : nTrials x 1 baseline count (e.g., mean count over pre bins)
            %   tail     : "both"|"right"|"left" (or "two" mapped to "both")
            %   preBins  : logical 1 x nBins indicating baseline bins
            %
            % Outputs:
            %   z       : signed z-stat per bin (normal approx to signed-rank)
            %   p       : signrank p-value per bin
            %   effProb : ΔP(spike) per bin relative to baseline per-bin probability
            %   effMean : Δmean spike count per bin relative to baseline mean count

            nT = size(X,2);
            z       = nan(1,nT);
            p       = nan(1,nT);
            effProb = nan(1,nT);
            effMean = nan(1,nT);

            % normalize tail
            tail = string(tail);
            if tail == "two" || tail == "two-sided" || tail == "two_sided"
                tail = "both";
            end

            % baseline per-bin spike probability (scalar, comparable to a single bin)
            if nargin < 5 || isempty(preBins) || ~any(preBins)
                p0 = mean(X > 0, 'all', 'omitnan');   % fallback
            else
                p0 = mean(X(:, preBins) > 0, 'all', 'omitnan');
            end

            for k = 1:nT
                % paired differences
                d = X(:,k) - baseline;
                d = d(~isnan(d));

                if numel(d) < 5
                    continue;
                end

                % p-value
                try
                    p(k) = signrank(d, 0, 'tail', char(tail));
                catch
                    p(k) = signrank(d); % fallback
                end

                % effects
                pk = mean(X(:,k) > 0, 'omitnan');
                effProb(k) = pk - p0;

                effMean(k) = mean(d, 'omitnan');   % mean(X(:,k) - baseline)

                % signed-rank z (normal approx)
                d_nz = d(d ~= 0);
                n = numel(d_nz);
                if n < 5
                    z(k) = 0;
                    continue;
                end

                r = tiedrank(abs(d_nz));
                Wplus = sum(r(d_nz > 0));

                mu   = n*(n+1)/4;
                sig2 = n*(n+1)*(2*n+1)/24;
                z0 = (Wplus - mu) / sqrt(sig2);

                dir = sign(mean(d_nz));
                if dir == 0
                    dir = 1; % degenerate; doesn't matter much
                end
                z(k) = abs(z0) * dir;
            end
        end


        function clusters = findClusters(~, pvals, stats, alphaBin, minBins, tail)
            if nargin < 6 || isempty(tail), tail = "two"; end
            tail = string(tail);

            clusters = struct('idx',{},'start',{},'end',{},'mass',{},'p_corr',{},'sign',{});

            % helper to find runs in a logical vector
            function addRuns(sigMask, signLabel)
                sigMask = sigMask(:).';
                if ~any(sigMask), return; end
                d = diff([0 sigMask 0]);
                starts = find(d==1);
                ends   = find(d==-1)-1;

                keep = (ends - starts + 1) >= minBins;
                starts = starts(keep);
                ends   = ends(keep);

                for iC = 1:numel(starts)
                    idx = starts(iC):ends(iC);
                    clusters(end+1).idx   = idx; %#ok<AGROW>
                    clusters(end).start   = starts(iC);
                    clusters(end).end     = ends(iC);
                    clusters(end).mass    = sum(stats(idx), 'omitnan');
                    clusters(end).p_corr  = NaN;
                    clusters(end).sign    = signLabel;
                end
            end

            switch tail
                case {"right","greater"}
                    addRuns((pvals < alphaBin) & (stats > 0), "pos");
                case {"left","less"}
                    addRuns((pvals < alphaBin) & (stats < 0), "neg");
                otherwise  % two-sided
                    addRuns((pvals < alphaBin) & (stats > 0), "pos");
                    addRuns((pvals < alphaBin) & (stats < 0), "neg");
            end
        end

        function clusters = scoreClusters(~, clusters, statObs, permMax)
            % cluster p_corr from permutation distribution of max |mass|
            if isempty(clusters), return; end
            if isempty(permMax) || all(isnan(permMax))
                for i=1:numel(clusters), clusters(i).p_corr = NaN; end
                return;
            end
            permAbs = abs(permMax);
            nPerm   = numel(permAbs);

            for i = 1:numel(clusters)
                m = sum(statObs(clusters(i).idx), 'omitnan');
                clusters(i).mass = m;

                k = sum(permAbs >= abs(m));           % number of permuted maxima as extreme
                clusters(i).p_corr = (k + 1) / (nPerm + 1);
            end
        end

        function class = classifyFromClustersPrimary(~, clusters, times)
            % classification based on PRIMARY (main) significant cluster:
            % 1 no_modulation: no cluster with p_corr <= 0.05
            % 2 onset < 0  -> pre_event_modulation
            % 3 onset >= 0 -> post_event_modulation (latency)
            %
            % Primary cluster = significant cluster with max(|mass|)

            class = struct( ...
                'label', "no_modulation", ...
                'onset_ms', NaN, ...
                'latency_ms', NaN, ...
                'cluster_index', NaN, ...
                'mass', NaN, ...
                'p_corr', NaN, ...
                'direction', "none" );

            if isempty(clusters), return; end

            pc = [clusters.p_corr];
            sigIdx = find(pc <= 0.05);
            if isempty(sigIdx), return; end

            % choose primary = max |mass|
            m = [clusters(sigIdx).mass];
            [~, ii] = max(abs(m));
            kBest = sigIdx(ii);

            % onset time = first bin center of that cluster
            onset_ms = times(clusters(kBest).idx(1));

            class.onset_ms = onset_ms;
            class.cluster_index = kBest;
            class.mass = clusters(kBest).mass;
            class.p_corr = clusters(kBest).p_corr;

            if class.mass > 0
                class.direction = "up";
            elseif class.mass < 0
                class.direction = "down";
            end

            if onset_ms < 0
                class.label = "pre_event_modulation";
            else
                class.label = "post_event_modulation";
                class.latency_ms = onset_ms;
            end
        end
 
        function permMax = permuteMaxClusterMass(obj, T, cfg, times, XA, XB, statObs)
            % Permute labels across trials to get null distribution of max cluster mass.
            %
            % Strategy:
            %   - build a combined matrix X = [XA; XB]
            %   - permute row labels (or within strata if StratifyVar set)
            %   - compute per-bin ranksum z
            %   - compute max cluster mass using same alpha/minBins

            nA = size(XA,1);
            nB = size(XB,1);
            X  = [XA; XB];

            if cfg.NPerm <= 0
                permMax = [];
                return;
            end

            permMax = nan(cfg.NPerm,1);

            % Optional stratification: shuffle labels within strata based on trial-level metadata
            stratVar = string(cfg.StratifyVar);
            if stratVar ~= "" && ismember(stratVar, T.Properties.VariableNames)
                % Build trial-level strat labels for the included trials
                % Note: we use trials from XA and XB, assume trial ids are unique
                % Get trial lists from the matrices: already returned in out, but not passed here.
                % To keep this method self-contained, we skip stratification unless you later pass trials.
                stratVar = ""; % disable for now unless you want to wire trial ids in
            end

            for r = 1:cfg.NPerm
                idx = randperm(nA+nB);
                Aidx = idx(1:nA);
                Bidx = idx(nA+1:end);

                [statP, pP] = obj.quickRankSumZandP(X(Aidx,:), X(Bidx,:), cfg.Tail);

                clusters = obj.findClusters(pP, statP, cfg.AlphaBin, cfg.MinClusterBins);
                if isempty(clusters)
                    permMax(r) = 0;
                else
                    masses = arrayfun(@(c) sum(statP(c.idx), 'omitnan'), clusters);
                    permMax(r) = masses( find(abs(masses)==max(abs(masses)), 1, 'first') );
                end
            end
        end

        function permMax = permuteMaxClusterMass_paired(obj, X, baseline, cfg, statObs)
            % Paired null for eventModulation: sign-flip within trials on d = X - baseline
            if cfg.NPerm <= 0
                permMax = [];
                return;
            end

            D = X - baseline; % nTrials x nTime
            nTr = size(D,1);
            permMax = nan(cfg.NPerm,1);

            for r = 1:cfg.NPerm
                flips = (rand(nTr,1) > 0.5)*2 - 1;  % +1 or -1
                DP = D .* flips;

                [statP, pP] = obj.quickSignRankZandP(DP, cfg.Tail);
                clusters = obj.findClusters(pP, statP, cfg.AlphaBin, cfg.MinClusterBins);

                if isempty(clusters)
                    permMax(r) = 0;
                else
                    masses = arrayfun(@(c) sum(statP(c.idx), 'omitnan'), clusters);
                    permMax(r) = masses( find(abs(masses)==max(abs(masses)), 1, 'first') ); % pick the maximal absolute mass
                end
            end
        end

        function class = classifyFromClusters(~, clusters, times)
            % classifyFromClusters  Summarize modulation timing from cluster results.
            %
            % Classification:
            %   - "no_modulation":         no cluster with p_corr <= 0.05
            %   - "pre_event_modulation":  earliest significant cluster starts at time < 0
            %   - "post_event_modulation": earliest significant cluster starts at time >= 0
            %                              latency_ms = onset_ms
            %
            % Inputs
            %   clusters : struct array with fields idx, p_corr (and optionally mass, etc.)
            %   times    : vector of bin center times (ms), same indexing as cluster idx
            %
            % Output
            %   class struct with fields:
            %     label, onset_ms, latency_ms, cluster_index

            class = struct( ...
                'label',        "no_modulation", ...
                'onset_ms',     NaN, ...
                'latency_ms',   NaN, ...
                'cluster_index',NaN);

            if isempty(clusters)
                return;
            end

            % choose earliest significant cluster (corr p<=0.05)
            pc = arrayfun(@(c) c.p_corr, clusters);
            sigIdx = find(pc <= 0.05);
            if isempty(sigIdx)
                return;
            end

            % earliest onset among significant clusters
            onsetBins = arrayfun(@(k) clusters(k).idx(1), sigIdx);
            [~, ii] = min(onsetBins);
            kBest = sigIdx(ii);

            onset_ms = times(clusters(kBest).idx(1));
            class.onset_ms = onset_ms;
            class.cluster_index = kBest;

            if onset_ms < 0
                class.label = "pre_event_modulation";
                class.latency_ms = NaN;
            else
                class.label = "post_event_modulation";
                class.latency_ms = onset_ms;
            end
        end


        function [z, p] = quickRankSumZandP(~, XA, XB, tail)
            nT = size(XA,2);
            z = nan(1,nT); p = nan(1,nT);
            for k=1:nT
                a = XA(:,k); b = XB(:,k);
                a = a(~isnan(a)); b = b(~isnan(b));
                if numel(a)<3 || numel(b)<3, continue; end
                try
                    [p(k),~,st] = ranksum(a,b,'tail',tail);
                    if isfield(st,'zval'), z(k) = st.zval; end
                catch
                    [p(k),~,st] = ranksum(a,b);
                    if isfield(st,'zval'), z(k) = st.zval; end
                end
            end
        end

        function [z, p] = quickSignRankZandP(~, D, tail)
            nT = size(D,2);
            z = nan(1,nT); p = nan(1,nT);
            for k=1:nT
                d = D(:,k);
                d = d(~isnan(d));
                if numel(d)<5, continue; end
                try
                    [p(k),~,st] = signrank(d, 0, 'tail', tail);
                    if isfield(st,'zval'), z(k) = st.zval; end
                catch
                    [p(k),~,st] = signrank(d);
                    if isfield(st,'zval'), z(k) = st.zval; end
                end
            end
        end

        function overlayClusters(~, out)
            if ~isfield(out,'clusters') || isempty(out.clusters), return; end
            t = out.times_ms;

            % mark corrected-significant clusters
            pc = arrayfun(@(c)c.p_corr, out.clusters);
            sig = find(pc <= 0.05);

            if isempty(sig), return; end

            % overlay on current figure: shade in both subplots
            ax = findall(gcf,'Type','axes');
            for iAx = 1:numel(ax)
                axes(ax(iAx)); %#ok<LAXES>
                yl = ylim;
                for k = sig(:).'
                    idx = out.clusters(k).idx;
                    x1 = t(idx(1)); x2 = t(idx(end));
                    patch([x1 x2 x2 x1], [yl(1) yl(1) yl(2) yl(2)], ...
                        'k', 'FaceAlpha', 0.08, 'EdgeColor', 'none');
                end
                uistack(findall(gca,'Type','line'),'top');
                ylim(yl);
            end
        end

        function s = labelToStr(~, x)
            % Convert group label(s) into a compact string for titles/prints.

            if isempty(x)
                s = "";
                return;
            end

            if iscategorical(x)
                x = string(x);
            elseif iscell(x)
                x = string(x);
            else
                x = string(x);
            end

            x = x(:);
            x = x(~ismissing(x) & x ~= "");
            x = unique(x, 'stable');

            if isempty(x)
                s = "";
            else
                s = strjoin(x, "+");
            end
        end


        function out = emptyOut(~, kind, cfg, msg)
            out = struct('kind',string(kind),'cfg',cfg,'message',string(msg), ...
                'times_ms',[],'stat',[],'p_unc',[],'clusters',[],'class',struct('label',"no_modulation"));
        end
        
        function out = copyPrimaryScalars(obj, out)
            % Copy scalar-like fields from out.primary to top-level out.<field>.
            if ~isfield(out,'primary') || ~isstruct(out.primary)
                return
            end

            p = out.primary;
            f = fieldnames(p);

            for i = 1:numel(f)
                name = f{i};
                val  = p.(name);

                isScalarLike = (isscalar(val) && (isnumeric(val) || islogical(val))) ...
                    || ischar(val) || (isstring(val) && isscalar(val));

                if isScalarLike
                    % choose overwrite policy:
                    % if ~isfield(out, name)
                    out.(name) = val;
                    % end
                end
            end
        end
    end
end