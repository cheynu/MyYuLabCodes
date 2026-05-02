classdef GPSPlot < handle

    properties
    end

    methods
        function obj = GPSPlot(); end

        %% Plot functions
        function plot_trials(~, ax, data, varargin)

            defaultColor = [0 0 0];
            defaultMarker = 'o';
            defaultSize = 18;
            defaultNumShow = 50;
            defaultFP = zeros(1, length(data));

            p = inputParser;
            addParameter(p,'n_show', defaultNumShow, @isnumeric);
            addParameter(p,'FP', defaultFP, @(x) (isvector(x) && length(x)==length(data)));
            addParameter(p,'Marker', defaultMarker);
            addParameter(p,'FaceColor', defaultColor);
            addParameter(p,'MarkerColor', defaultColor);
            addParameter(p,'MarkerSize', defaultSize);
            addParameter(p,'FaceAlpha', 0.2);
            addParameter(p,'MarkerAlpha', 0.6);

            parse(p, varargin{:});

            n_show = p.Results.n_show;
            FP = p.Results.FP;
            Marker = p.Results.Marker;
            FaceColor = p.Results.FaceColor;
            MarkerColor = p.Results.MarkerColor;
            MarkerSize = p.Results.MarkerSize;
            FaceAlpha = p.Results.FaceAlpha;
            MarkerAlpha = p.Results.MarkerAlpha;

            n_show = min([n_show min(cellfun(@(x) length(x), data))]);

            for i=1:length(data)
                if FP(i)~=0
                    fill(ax, [0 FP(i) FP(i) 0], [0 0 1 1]+i-1, 'r', ...
                        'FaceColor', FaceColor, 'FaceAlpha', FaceAlpha, 'EdgeColor', 'none');
                end
                id_show = randperm(length(data{i}), n_show);
                scatter(ax, data{i}(id_show), linspace(.1, .9, n_show)+i-1, MarkerSize, "filled", 'Marker', Marker, ...
                    "MarkerEdgeColor", "none", "MarkerFaceColor", MarkerColor, "MarkerFaceAlpha", MarkerAlpha);
            end
            set(ax, 'XColor', 'none', 'YColor', 'none');
        end % plot_trials

        %
        function plot_distr(~, ax, data, varargin)
            defaultColor =  repmat({[0 0 0]}, 1, length(data));
            defaultLw = repmat(1.2, 1, length(data));
            defaultLs = repmat("-", 1, length(data));
            defaultFP = zeros(1, length(data));

            p = inputParser;
            addRequired(p,'ax', @ishandle);
            addRequired(p,'data', @iscell);
            addParameter(p,'FP', defaultFP, @isvector);
            addParameter(p,'Color', defaultColor, @iscell);
            addParameter(p,'LineWidth', defaultLw, @isvector);
            addParameter(p,'LineStyle', defaultLs, @isvector);
            addParameter(p,'Reversed', 0);

            parse(p, ax, data, varargin{:});

            ax = p.Results.ax;
            data = p.Results.data;
            FP = p.Results.FP;
            Color = p.Results.Color;
            LineWidth = p.Results.LineWidth;
            LineStyle = p.Results.LineStyle;
            Reversed = p.Results.Reversed;

            if length(FP)~=length(data) && length(FP)~=1
                error("Unmatched length between color and data");
            end
            if length(Color)==1
                Color = repmat(Color, 1, length(data));
            elseif length(Color)~=length(data)
                error("Unmatched length between color and data");
            end
            if length(LineWidth)==1
                LineWidth = repmat(LineWidth, 1, length(data));
            elseif length(LineWidth)~=length(data)
                error("Unmatched length between lw and data");
            end
            if length(LineStyle)==1
                LineStyle = repmat(LineStyle, 1, length(data));
            elseif length(LineStyle)~=length(data)
                error("Unmatched length between ls and data");
            end

            for i = 1:length(data)
                if length(FP)==1
                    if i==1 && FP~=0
                        if Reversed
                            yline(ax, FP, 'LineStyle', "-", 'Color', [.5 .5 .5]);
                        else
                            xline(ax, FP, 'LineStyle', "-", 'Color', [.5 .5 .5]);
                        end
                    end
                elseif FP(i)~=0
                    if Reversed
                        yline(ax, FP(i), 'LineStyle', LineStyle(i), 'Color', [.5 .5 .5]);
                    else
                        xline(ax, FP(i), 'LineStyle', LineStyle(i), 'Color', [.5 .5 .5]);
                    end
                end
                if ~isempty(data{i}.ci)
                    if Reversed
                        fill(ax, [data{i}.ci(1,:) flip(data{i}.ci(2,:))], [data{i}.x flip(data{i}.x)], 'r', ...
                            'FaceColor', Color{i}, 'FaceAlpha', .2, 'EdgeColor', Color{i}, 'LineWidth', .2, 'EdgeAlpha', .6);
                    else
                        fill(ax, [data{i}.x flip(data{i}.x)], [data{i}.ci(1,:) flip(data{i}.ci(2,:))], 'r', ...
                            'FaceColor', Color{i}, 'FaceAlpha', .2, 'EdgeColor', Color{i}, 'LineWidth', .2, 'EdgeAlpha', .6);
                    end
                end
                if Reversed
                    plot(ax, data{i}.f, data{i}.x, 'Color', Color{i}, 'LineWidth', LineWidth(i), 'LineStyle', LineStyle(i));
                else
                    plot(ax, data{i}.x, data{i}.f, 'Color', Color{i}, 'LineWidth', LineWidth(i), 'LineStyle', LineStyle(i));
                end
            end
        end % plot_distr

        %
        function plot_violin_compare(~, ax, datain_1, datain_2, band_width, varargin)
            defaultCate = string(1:length(datain_1));
            defaultColor = repmat({[0 0 0]}, 1, 2);

            p = inputParser;
            addRequired(p,'ax', @ishandle);
            addRequired(p,'datain_1', @iscell);
            addRequired(p,'datain_2', @iscell);
            addRequired(p,'band_width', @isnumeric);
            addParameter(p,'cate_name', defaultCate);
            addParameter(p,'Color', defaultColor);
            addParameter(p,'Scale', 1, @isnumeric);
            addParameter(p,'TextMedian', false, @islogical);
            addParameter(p,'ShowMedian', true, @islogical);
            addParameter(p,'MedianSize', 16, @isnumeric);

            parse(p, ax, datain_1, datain_2, band_width, varargin{:});

            ax = p.Results.ax;
            datain_1 = p.Results.datain_1;
            datain_2 = p.Results.datain_2;
            band_width = p.Results.band_width;
            cate_name = p.Results.cate_name;
            Color = p.Results.Color;
            Scale = p.Results.Scale;
            TextMedian = p.Results.TextMedian;
            ShowMedian = p.Results.ShowMedian;
            MedianSize = p.Results.MedianSize;

            n_data_1 = max(cellfun(@length, datain_1));
            n_data_2 = max(cellfun(@length, datain_2));
            n_data = max([n_data_1 n_data_2]);
            if n_data==0
                return
            end

            if length(n_data_1)~=length(n_data_2)
                error("input data dont match");
            else
                n_cate = length(datain_1);
            end
            if length(Color)==1
                Color = repmat(Color, 1, 2);
            end
            %
            data_1 = nan(n_data, n_cate);
            data_2 = nan(n_data, n_cate);
            for i = 1:n_cate
                if isempty(datain_1{i})
                    datain_1{i} = nan;
                else
                    data_1(1:length(datain_1{i}), i) = Scale*datain_1{i};
                end
                if isempty(datain_2{i})
                    datain_2{i} = nan;
                else
                    data_2(1:length(datain_2{i}), i) = Scale*datain_2{i};
                end
            end

            data_all = [data_1 data_2];
            [~, ~, ind_rmv] = rmoutliers_custome(data_all(:));
            data_all(ind_rmv) = nan;
            data_1 = data_all(:, 1:n_cate);
            data_2 = data_all(:, n_cate+1:end);

            data_med_1 = median(data_1, 1, 'omitnan');
            data_med_2 = median(data_2, 1, 'omitnan');

            valid_1 = sum(~isnan(data_1))>=5;
            valid_2 = sum(~isnan(data_2))>=5;
            data_1(1, ~any(~isnan(data_1), 1)) = 0;
            data_2(1, ~any(~isnan(data_2), 1)) = 0;

            data_med_ci_1 = nan(2, n_cate);
            data_med_ci_2 = nan(2, n_cate);
            if any(valid_1)
                data_med_ci_1(:, valid_1) = bootci(1000, {@(x) median(x, 1, 'omitnan'), data_1(:, valid_1)}, 'alpha', .05, 'type', 'cper');
            end
            if any(valid_2)
                data_med_ci_2(:, valid_2) = bootci(1000, {@(x) median(x, 1, 'omitnan'), data_2(:, valid_2)}, 'alpha', .05, 'type', 'cper');
            end

            %
            axes(ax);
            try
                v = violinplot({data_2, data_1}, cate_name, ...
                    'ViolinColor', Color([2 1]), 'ViolinAlpha', {.1, .1}, ...
                    'BandWidth', Scale*band_width, 'MarkerSize', 2, ...
                    'ShowMedian', false, 'ShowWhiskers', false, 'ShowBox', false);
            catch

            end
            xlim(ax, [.5 n_cate+.5]);

            for i = 1:n_cate
                v(i).ScatterPlot.MarkerFaceAlpha = .2;
                v(i).ScatterPlot2.MarkerFaceAlpha = .2;

                if ShowMedian
                    scatter(ax, i-.05, data_med_1(i), MedianSize, Color{1}, "filled", ...
                        'LineWidth', 1, 'MarkerEdgeColor', 'flat', ...
                        'MarkerFaceColor', 'none');
                    scatter(ax, i+.05, data_med_2(i), MedianSize, Color{2}, "filled", ...
                        'LineWidth', 1, 'MarkerEdgeColor', 'flat', ...
                        'MarkerFaceColor', 'none');
                    plot(ax, [i-.05 i-.05], data_med_ci_1(:,i), 'Color', Color{1}, 'LineWidth', 1);
                    plot(ax, [i+.05 i+.05], data_med_ci_2(:,i), 'Color', Color{2}, 'LineWidth', 1);
                end
                if TextMedian
                    switch Scale
                        case 1
                            median_format = '%.2f';
                        case 1000
                            median_format = '%.0f';
                    end
                    text(ax, i-.05, ax.YLim(1) + 0.6*range(ax.YLim), sprintf(median_format, data_med_1(i)), 'FontSize', 5, 'HorizontalAlignment', 'right');
                    text(ax, i+.05, ax.YLim(1) + 0.6*range(ax.YLim), sprintf(median_format, data_med_2(i)), 'FontSize', 5, 'HorizontalAlignment', 'left');
                end
                set(ax, 'Box', 'off');
            end
        end % plot_violin_compare

        %
        function [ax, v] = plot_violin_compare_box(~, ax, data_1, data_2, varargin)

            % parse input
            defaultCate = string(1:length(data_1));
            defaultColor = repmat({[0 0 0]}, 1, 2);

            p = inputParser;
            addRequired(p,'ax', @ishandle);
            addRequired(p,'datain_1', @iscell);
            addRequired(p,'datain_2', @iscell);
            addParameter(p,'band_width', [], @isnumeric);
            addParameter(p,'cate_name', defaultCate);
            addParameter(p,'color', defaultColor);
            addParameter(p,'scale', 1, @isnumeric);
            addParameter(p,'rm_outliers', true, @islogical);
            addParameter(p,'d_violin', .15, @isnumeric);
            addParameter(p,'d_median', .05, @isnumeric);
            addParameter(p,'violin_width', .2, @isnumeric);
            addParameter(p,'violin_alpha', .1, @isnumeric);
            addParameter(p,'marker_alpha', .4, @isnumeric);
            addParameter(p,'marker_size', 6, @isnumeric);
            addParameter(p,'median_size', 24, @isnumeric);
            addParameter(p,'median_width', 1, @isnumeric);
            addParameter(p,'median_text', false, @islogical);
            addParameter(p,'box_width', 0.03, @isnumeric);
            addParameter(p,'box_color', repmat({[.5 .5 .5]}, 1, 2));

            parse(p, ax, data_1, data_2, varargin{:});

            ax = p.Results.ax;
            data_1 = p.Results.datain_1;
            data_2 = p.Results.datain_2;
            band_width = p.Results.band_width;
            cate_name = p.Results.cate_name;
            color = p.Results.color;
            scale = p.Results.scale;
            rm_outliers = p.Results.rm_outliers;
            d_violin = p.Results.d_violin;
            d_median = p.Results.d_median;
            violin_width = p.Results.violin_width;
            violin_alpha = p.Results.violin_alpha;
            marker_alpha = p.Results.marker_alpha;
            marker_size = p.Results.marker_size;
            median_size = p.Results.median_size;
            median_width = p.Results.median_width;
            median_text = p.Results.median_text;
            box_width   = p.Results.box_width;
            box_color   = p.Results.box_color;
            
            % check input
            if length(data_1)~=length(data_2)
                error("input data dont match");
            else
                n_cate = length(data_1);
            end
            if length(color)==1
                color = repmat(color, 1, 2);
            end

            % remove outliers
            if rm_outliers
                data_1 = cellfun(@(x) rmoutliers_tail(x(~isnan(x))), data_1, 'UniformOutput', false);
                data_2 = cellfun(@(x) rmoutliers_tail(x(~isnan(x))), data_2, 'UniformOutput', false);
            end

            % 
            data = {data_1, data_2};
            for i = 1:2
                for j = 1:length(data_1)
                    data{i}{j} = scale * data{i}{j};
                end
            end

            % violin plot
            axes(ax);
            d_violin = d_violin * [-1 1];
            d_median = d_median * [-1 1];
            half_violin = ["left", "right"];

            v = cell(1, 2);
            for i = 1:2
                d_m_v = d_median(i) - d_violin(i);
                for j = 1:n_cate
                    if isempty(data{i}{j})
                        continue;
                    end
                    if isempty(band_width)
                        v{i}{j} = Violin(data{i}(j), j + d_violin(i), 'ViolinColor', color(i), 'ViolinAlpha', {violin_alpha}, ...
                            'MarkerSize', marker_size, ...
                            'HalfViolin', half_violin(i), 'Width', violin_width); % , 'BoxColor', color{i}
                    else
                        v{i}{j} = Violin(data{i}(j), j + d_violin(i), 'ViolinColor', color(i), 'ViolinAlpha', {violin_alpha}, ...
                            'BandWidth', scale*band_width, 'MarkerSize', marker_size, ...
                            'HalfViolin', half_violin(i), 'Width', violin_width); % , 'BoxColor', color{i}
                    end
                    if ~isempty(v{i}{j}.MedianPlot)
                        v{i}{j}.MedianPlot.XData    = v{i}{j}.MedianPlot.XData + d_m_v;
                        v{i}{j}.MedianPlot.SizeData = median_size;
                        v{i}{j}.MedianPlot.LineWidth = median_width;
                        v{i}{j}.MedianPlot.Marker = '_';
                        v{i}{j}.MedianPlot.MarkerEdgeColor = [1 1 1];
                        
                        if median_text
                            switch scale
                                case 1
                                    median_format = '%.2f';
                                case 1000
                                    median_format = '%.0f';
                            end
                            switch i
                                case 1
                                    text(ax, v{i}{j}.MedianPlot.XData, ax.YLim(1) + 0.8*range(ax.YLim), sprintf(median_format, v{i}{j}.MedianPlot.YData), 'FontSize', 5, 'HorizontalAlignment', 'right');
                                case 2
                                    text(ax, v{i}{j}.MedianPlot.XData, ax.YLim(1) + 0.8*range(ax.YLim), sprintf(median_format, v{i}{j}.MedianPlot.YData), 'FontSize', 5, 'HorizontalAlignment', 'left');
                            end
                        end
                    end
                    if ~isempty(v{i}{j}.BoxPlot)
                        v{i}{j}.BoxPlot.XData = v{i}{j}.BoxPlot.XData + d_m_v;
                        v{i}{j}.BoxWidth = box_width;
                        v{i}{j}.BoxPlot.FaceColor = box_color{i};
                        v{i}{j}.BoxPlot.EdgeColor = box_color{i};
                    end
                    if ~isempty(v{i}{j}.WhiskerPlot)
                        v{i}{j}.WhiskerPlot.XData  = v{i}{j}.WhiskerPlot.XData + d_m_v;
                        v{i}{j}.WhiskerPlot.Color  = box_color{i};
                        v{i}{j}.ScatterPlot.MarkerFaceAlpha = marker_alpha;
                    end
                end
            end
            set(ax, 'Box', 'off', 'XTick', 1:n_cate, 'XTickLabel', cate_name, 'XLim', [.5 n_cate+.5]);
        end % plot_violin_compare_box

        function ax = add_shade(~, ax, zone, varargin)

            % parsing input
            P = inputParser;

            addParameter(P, 'color'  , [1 0 1]);
            addParameter(P, 'alpha'  , .2);
            addParameter(P, 'reverse', false);

            parse(P, varargin{:});

            color = P.Results.color;
            alpha = P.Results.alpha;
            reverse = P.Results.reverse;

            %
            if ~reverse
                fill(ax, [zone flip(zone)], [ax.YLim(1) ax.YLim(1) ax.YLim(2) ax.YLim(2)], 'r', 'FaceColor', color, 'FaceAlpha', alpha, 'EdgeColor', 'none');
            else
                fill(ax, [ax.XLim(1) ax.XLim(1) ax.XLim(2) ax.XLim(2)], [zone flip(zone)], 'r', 'FaceColor', color, 'FaceAlpha', alpha, 'EdgeColor', 'none');
            end

            children = ax.Children;
            set(ax, 'Children', [children(2:end); children(1)]);
        end % add_shade

        %% For easy plot
        function [ax, pos, ax_sz] = assign_ax_to_fig(obj, fig, n_row, n_col, pos, ax_sz, varargin)
            % parsing input
            P = inputParser;

            addParameter(P, 'font_size', 7);
            parse(P, varargin{:});
            font_size = P.Results.font_size;

            %
            ax = cell(n_row, n_col);
            [dist_w, dist_h] = obj.get_plot_dist(ax, pos, ax_sz);

            for i = 1:n_row
                for j = 1:n_col
                    x_now = pos(1) + dist_w * (j-1);
                    y_now = pos(2) + dist_h * (n_row-i);

                    ax{i,j} = axes(fig, "Units", "centimeters", "Position", [x_now y_now ax_sz], ...
                        'NextPlot', 'add', 'FontSize', font_size, 'TickDir', 'out', 'TickLength', [0.02 0.03]);
                end
            end
        end % assign_ax_to_fig

        function data_assigned = assign_data_to_ax(~, ax, data_cell)
            sz_ax = size(ax);
            sz_data = size(data_cell);
            if length(sz_ax)>2
                error("Dimensions of axes is more than 2");
            end
            if length(sz_data)>2
                error("Dimensions of data cell is more than 2");
            end

            data_assigned = cell(sz_ax);
            if sz_ax(1)==1
                if numel(data_cell)==numel(ax)
                    for i = 1:sz_ax(2)
                        data_assigned{i} = data_cell(i);
                    end
                elseif sz_ax(2)==1 && sz_data(1)==1
                    data_assigned{1,1} = data_cell(1,:);
                else
                    if sz_data(2)==sz_ax(2)
                        for i = 1:sz_ax(2)
                            data_assigned{i} = data_cell(:,i);
                        end
                    else
                        error("Size of axes (%d, %d) is not equal to size of data cell (%d, %d)", sz_ax(1), sz_ax(2), sz_data(1), sz_data(2));
                    end
                end
            elseif sz_ax(2)==1
                if numel(data_cell)==numel(ax)
                    for i = 1:sz_ax(1)
                        data_assigned{i} = data_cell(i);
                    end
                else
                    if sz_data(1)==sz_ax(1)
                        for i = 1:sz_ax(1)
                            data_assigned{i} = data_cell(i,:);
                        end
                    else
                        error("Size of axes (%d, %d) is not equal to size of data cell (%d, %d)", sz_ax(1), sz_ax(2), sz_data(1), sz_data(2));
                    end
                end
            else
                if numel(data_cell)~=numel(ax)
                    error("Size of axes (%d, %d) is not equal to size of data cell (%d, %d)", sz_ax(1), sz_ax(2), sz_data(1), sz_data(2));
                else
                    if sz_ax(1)~=sz_data(1) && sz_ax(1)~=sz_data(2)
                        data_cell = data_cell';
                    end
                end
                for i = 1:sz_ax(1)
                    for j = 1:sz_ax(2)
                        data_assigned{i, j} = data_cell(i, j);
                    end
                end
            end
        end % assign_data_to_ax

        function add_serial(~, fig, ax_pos, serial_text, dist, varargin)
            % parsing input
            P = inputParser;
            addParameter(P, 'font_size', 10);
            parse(P, varargin{:});
            font_size = P.Results.font_size;

            pos = [ax_pos(1)+dist(1), ax_pos(2)+ax_pos(4)+dist(2), 1 1];
            ax = axes(fig, "Units", "centimeters", "Position", pos, ...
                'NextPlot', 'add', 'FontSize', font_size, 'TickDir', 'out', ...
                'Color', 'none', 'XColor', 'none', 'YColor', 'none',...
                'XLim', [0 1], 'YLim', [0 1]); %
            text(ax, 0, 0, serial_text, 'FontSize', font_size, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
            drawnow;
        end % add_serial

        function [dist_w, dist_h] = get_plot_dist(~, ax_cell, pos, ax_sz)
            [n_h, n_w] = size(ax_cell);
            if n_w>1
                sep_w = ( pos(3) - n_w*ax_sz(1) ) / (n_w-1);
            else
                sep_w = 0;
            end
            if n_h > 1
                sep_h = ( pos(4) - n_h*ax_sz(2) ) / (n_h-1);
            else
                sep_h = 0;
            end

            dist_w = sep_w + ax_sz(1);
            dist_h = sep_h + ax_sz(2);
        end % get_plot_dist
    end
end
