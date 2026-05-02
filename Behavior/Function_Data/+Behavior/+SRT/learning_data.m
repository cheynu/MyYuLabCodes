classdef learning_data
    % learning_data
    %
    % Behavioral analysis class for EventTable-based learning datasets
    %
    % Each row = one trial
    % Core metric: reaction time relative to FP (seconds)
    %
    % Example:
    %   obj = learning_data(r.r.EventTable);
    %   tabC = obj.select('outcome','Correct','FP',500);
    %   stats = obj.rtDistribution(tabC,'do_plot',true);

    properties
        tab table
    end

    methods
        %% ---------------------------------------------------------------
        % Constructor
        %% ---------------------------------------------------------------
        function obj = learning_data(input)

            if istable(input)
                tab = input;
            else
                error('Input must be a table (EventTable)');
            end

            % --- Basic sanity checks
            requiredCols = {
                't_press'
                't_release'
                'FP'
                'outcome'
                'rt'
                'anm_session'
                };

            for i = 1:numel(requiredCols)
                assert(ismember(requiredCols{i}, tab.Properties.VariableNames), ...
                    'Missing required column: %s', requiredCols{i});
            end

            obj.tab = tab;
        end

        %% ---------------------------------------------------------------
        % Flexible selector
        %% ---------------------------------------------------------------
        function tab_sub = select(obj, varargin)
            % Usage:
            %   tab = obj.select('outcome','Correct','FP',500);
            %   tab = obj.select('FP', @(x) x >= 1000);

            tab_sub = obj.tab;

            for i = 1:2:numel(varargin)
                key = varargin{i};
                val = varargin{i+1};

                assert(ismember(key, tab_sub.Properties.VariableNames), ...
                    'Unknown column: %s', key);

                col = tab_sub.(key);

                if isa(val, 'function_handle')
                    ind = val(col);

                elseif iscell(col) || isstring(col) || iscategorical(col)
                    ind = strcmp(string(col), string(val));

                else
                    ind = col == val;
                end

                tab_sub = tab_sub(ind, :);
            end
        end

        function T = stats2table(obj, stats)
            % Convert stats struct to a 1-row table
            % Split anm_session into anm + session

            anm = stats.anm;
            sess = stats.session;
            
            T = table( ...
                anm, ...
                sess, ...
                stats.mu, ...
                stats.sigma, ...
                stats.integral_01_1, ...
                stats.integral_premature, ...
                stats.n_trials, ...
                stats.valid, ...
                string(stats.reason), ...
                'VariableNames', { ...
                'anm', ...
                'session', ...
                'mu', ...
                'sigma', ...
                'integral_01_1', ...
                'integral_premature', ...
                'n_trials', ...
                'valid', ...
                'reason' ...
                } ...
                );
        end

    %% ---------------------------------------------------------------
    % RT / hold distribution analysis
    %% ---------------------------------------------------------------
    function stats = rtDistribution(obj, tab, varargin)
        % Compute RT density and Gaussian fit
            %
            % stats fields:
            %   mu, sigma, skew, integral_01_1, integral_premature, KL

            % ----------------------
            % Parameters
            % ----------------------
            p = inputParser;
            addParameter(p, 'fp_min', 1000);       % ms
            addParameter(p, 'range', [-1 3]);      % seconds
            addParameter(p, 'bin_size', 0.05);     % seconds
            addParameter(p, 'bandwidth', 0.075);
            addParameter(p, 'outcomes', []);
            addParameter(p, 'do_plot', false);
            addParameter(p, 'rt_valid_range', []);   % hard exclusion
            addParameter(p, 'eval_range', [-1 3]);   % density support
            addParameter(p, 'n_min', 30);

            parse(p, varargin{:});

            fp_min          =       p.Results.fp_min;
            eval_range      =       p.Results.eval_range;
            rt_valid_range  =       p.Results.rt_valid_range;
            bin_size        =       p.Results.bin_size;
            bw              =       p.Results.bandwidth;
            outcomes        =       p.Results.outcomes;
            do_plot         =       p.Results.do_plot;
            n_min           =       p.Results.n_min;

            % ----------------------
            % Initialize output (stable structure)
            % ----------------------
            stats = struct( ...
                'anm', "", ...
                'session', "", ...
                'mu', NaN, ...
                'sigma', NaN, ...
                'skew', NaN, ...
                'integral_01_1', NaN, ...
                'integral_premature', NaN, ...
                'KL', NaN, ...
                'bins', [], ...
                'f_density', [], ...
                'g_fit', [], ...
                'summary', '', ...
                'valid', false, ...
                'n_trials', 0, ...
                'reason', '' ...
                );

            
            % ----------------------
            % Select valid trials
            % ----------------------

            ind = ...
                ~strcmp(string(tab.outcome), 'Dark') & ...
                tab.FP >= fp_min;

            % Optional outcome filtering
            if ~isempty(outcomes)
                ind = ind & ismember(string(tab.outcome), string(outcomes));
            end

            n_valid = sum(ind);
            stats.n_trials = n_valid;

            if n_valid < n_min
                stats.reason = sprintf('Too few trials (n=%d < %d)', n_valid, n_min);
                return
            end

            % ----------------------
            % Infer animal and session
            % ----------------------
            if ismember('anm_session', tab.Properties.VariableNames)
                sess_all = unique(string(tab.anm_session));

                if numel(sess_all) == 1 && contains(sess_all, "_")
                    parts = split(sess_all, "_");
                    stats.anm     = parts(1);
                    stats.session = parts(2);
                else
                    stats.anm     = "Multiple";
                    stats.session = "Multiple";
                end
            else
                stats.anm     = "Unknown";
                stats.session = "Unknown";
            end

            rt = 0.001 * (tab.t_release(ind)-tab.t_press(ind)-tab.FP(ind));

            % Hard validity filter (optional)
            if ~isempty(rt_valid_range)
                rt = rt(rt > rt_valid_range(1) & rt < rt_valid_range(2));
            end

            % Density evaluated only here
            bins = eval_range(1):bin_size:eval_range(2);
            f_density = ksdensity(rt, bins, 'Bandwidth', bw);
            f_density = f_density / sum(f_density * bin_size);

            % ----------------------
            % Metrics
            % ----------------------
            integral = sum(f_density(bins >= 0.1 & bins <= 1)) * bin_size;
            integral_premature = sum(f_density(bins < 0.1)) * bin_size;

            sk = skewness(rt);

            % ----------------------
            % Gaussian fit
            % ----------------------
            gauss_fun = @(p, x) normpdf(x, p(1), p(2));

            mu0 = bins(f_density == max(f_density));
            sigma0 = 0.3;
            p0 = [mu0(1), sigma0];

            opts = optimoptions('lsqcurvefit','Display','off');

            p_hat = lsqcurvefit( ...
                gauss_fun, p0, bins, f_density, ...
                [min(bins), 0], [max(bins), Inf], opts);

            mu_hat    = p_hat(1);
            sigma_hat = p_hat(2);

            g_fit = normpdf(bins, mu_hat, sigma_hat);
            g_fit = g_fit / sum(g_fit * bin_size);

            % ----------------------
            % KL divergence
            % ----------------------
            eps_val = 1e-10;
            KL = sum( ...
                f_density .* log((f_density + eps_val) ./ (g_fit + eps_val)) ...
                ) * bin_size;

            % ----------------------
            % Output (valid case)
            % ----------------------
            stats.mu    = mu_hat;
            stats.sigma = sigma_hat;
            stats.skew  = sk;

            stats.integral_01_1       = integral;
            stats.integral_premature = integral_premature;
            stats.KL    = KL;

            stats.bins      = bins;
            stats.f_density = f_density;
            stats.g_fit     = g_fit;

            stats.summary = sprintf( ...
                'integral=%2.2f\npremature=%2.2f\nskew=%2.2f\nmu=%2.2f\nsigma=%2.2f', ...
                integral, integral_premature, sk, mu_hat, sigma_hat);

            stats.valid  = true;
            stats.reason = '';


            % ----------------------
            % Optional plot
            % ----------------------
            if do_plot
                this_fig = figure('Color','w','Position',[300 300 450 300]); hold on;
                bar(bins, f_density, 1, ...
                    'FaceColor','k','EdgeColor','none');
                plot(bins, g_fit, 'r', 'LineWidth', 1.5);
                xline(0, 'k-.', 'LineWidth', 1);
                xlabel('RT relative to FP (s)');
                ylabel('Density');
                title(sprintf('RT distribution (%s | %s)', stats.anm, stats.session));
                text(0.72, 0.95, stats.summary, ...
                    'Units','normalized', ...
                    'VerticalAlignment','top', ...
                    'FontSize',10, 'Color','r');
                box on;
                
                outname = sprintf('%s_%s_response_distribution', stats.anm, stats.session);
                exportgraphics(this_fig, [outname '.png'], ...
                    'Resolution',150, ...
                    'BackgroundColor','white');

            end
        end
    end
end
