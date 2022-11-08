classdef PawTraj
    % sensory array data set class

    properties (GetAccess = private)

    end

    properties (Constant)

    end

    properties (Dependent)

    end

    properties
        Subject
        Event
        Session
        BodyParts
        PoseTracking 

        % for plotting
        x_range
        y_range
        t_range

        t_endpoints % track paw location at this time point, eg., -50 ms

        Treatment

    end

    methods

        function obj = PawTraj(DLCTrackingOut, Subject, varargin)

            if nargin<2
                Subject = '';
            end

            obj.Subject             = Subject;
            obj.Event               = DLCTrackingOut.Event;
            obj.Session             = DLCTrackingOut.Session;
            obj.BodyParts           = DLCTrackingOut.BodyParts;
            obj.PoseTracking        = DLCTrackingOut.PoseTracking;
            obj.PoseTracking.Images = cellfun(@(x)x(:, :, :, 3), DLCTrackingOut.PoseTracking.Images, 'UniformOutput', false);

            yrange = [400 1100];
            xrange = [200 900];
            trange = [-300 200];
            t_endpoints = [-50 -100 -150];

            for i=1:2:size(varargin,2)
                switch varargin{i}
                    case 'x_range'
                        xrange =  varargin{i+1};
                    case 'y_range'
                        yrange =  varargin{i+1};
                    case 't_range'
                        trange =  varargin{i+1};
                    case 't_endpoints'
                        t_endpoints =  varargin{i+1};
                end
            end
            obj.x_range = xrange;
            obj.y_range = yrange;
            obj.t_range = trange;
            obj.t_endpoints= t_endpoints;
        end

        function print(obj)
            FigFolder = fullfile(pwd, 'Figures');
            if ~isfolder(FigFolder)
                mkdir(FigFolder);
            end
            tosavename = fullfile(FigFolder, [ 'PawTrajectory_' obj.Subject strrep(obj.Session(1:10), '-', '')]);
            print(25,'-dpng', tosavename);
            print(25,'-depsc2', tosavename);
        end

        function save(obj)
            save([ 'PawTrajectory_' obj.Subject  strrep(obj.Session(1:10), '-', '')], 'obj');
        end

        function obj = set.Treatment(obj, treatment_type)
            if nargin<1
                return
            end
            if ~(strcmpi(treatment_type,'Saline') ||...
                    strcmpi(treatment_type,'DCZ') ||...
                    strcmpi(treatment_type,'NA') ||...
                    strcmpi(treatment_type,'PreLesion')||...
                    strcmpi(treatment_type,'PostLesion'))
                error(" 'Treatment can only be 'Saline', 'DCZ', 'PreLesion', 'PostLesion', or 'NA' ");
            end
            obj.Treatment = treatment_type;
        end

        function obj = plot(obj)
            % plot paw trajectory
            tmin = obj.t_range(1);
            tmax = obj.t_range(2);
            ind_exp = randperm(length(obj.PoseTracking.PosData), 1);
            lsize=size(obj.PoseTracking.Images{ind_exp});
            lx =lsize(1);
            ly=lsize(2);

            width = 4;
            height = width*diff(obj.y_range)/diff(obj.x_range);

            printsize = [2 2 20 15];

            xpos = [
                1.5
                7
                12.5
                17  % coloarbar location
                1.5
                7
                12.5
                12
                1.5
                1.5+3.2
                1.5+3.2*2
                1.5+3.2*3
                16.3
                ];

            ypos = [
                1.5+4+height+1
                1.5+4+height+1
                1.5+4+height+1
                1.5+4+height+1
                1.5+4.8
                1.5+4.8
                1.5+4.8
                1.5
                1.5
                1.5
                1.5
                1.5
                1.5
                ];

            plotsize = [
                width, height;
                width, height
                width, height
                0.25, height
                width, 3
                width, 3
                width, 3
                3, 3
                3, 3
                3, 3
                3, 3% histogram of position at -50 ms
                3, 3
                3, 3
                ];

            these_colors = [
                3, 37, 108
                37, 65, 178
                23, 104, 172
                229, 213, 73
                ]/255;


            %%
            hf=25;
            figure(hf); clf(hf)

            set(gcf, 'unit', 'centimeters', 'position', printsize, ...
                'paperpositionmode', 'auto','renderer','Painters', 'Visible', 'on', 'color', 'w');

            % Write down the name
            h_ANM_Name = uicontrol('style', 'text', 'parent', hf, 'unit', 'centimeters', ...
                'position', [2, 15-0.5, 2.5, 0.5], ...
                'backgroundcolor', 'w', 'string', obj.Subject, 'BackgroundColor', 'w' , ...
                'fontsize',10, 'fontname', 'Dejavu Sans','ForegroundColor', 'k', ...
                'FontWeight', 'bold');

            ha1 = axes('unit', 'centimeters', 'position', [xpos(1) ypos(1)  plotsize(1, :)], 'nextplot', 'add',...
                'xlim', obj.x_range, 'xtick', [obj.x_range(1):200:obj.x_range(2)], ...
                'ylim', obj.y_range,'ytick', [obj.y_range(1):200:obj.y_range(2)], ...
                'xticklabel', [], 'yticklabel', [], ...
                'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'ydir', 'reverse');

            title([obj.Session]);
            image(ha1, obj.PoseTracking.Images{ind_exp});
            posmat_eg = obj.PoseTracking.PosData{ind_exp};
            indplot = find(posmat_eg(:, 4)<=0);
            plot(ha1, posmat_eg(indplot, 1), posmat_eg(indplot, 2), 'color', [255 135 0]/255, 'linewidth', 1.5);

            % plot all trials
            ha2 = axes('unit', 'centimeters', 'position', [xpos(2) ypos(2) plotsize(2, :)], 'nextplot', 'add',...
                'xlim', obj.x_range, 'xtick', [obj.x_range(1):200:obj.x_range(2)], ...
                'ylim', obj.y_range,'ytick', [obj.y_range(1):200:obj.y_range(2)], ...
                'xticklabel', [], 'yticklabel', [], ...
                'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'ydir', 'reverse');

            xlabel('Horizontal axis (pixels)');
            ylabel('Vertical axis (pixels)');

            ha3 = axes('unit', 'centimeters', 'position', [xpos(3) ypos(3) plotsize(3, :)], 'nextplot', 'add',...
                'xlim', obj.x_range, 'xtick', [obj.x_range(1):200:obj.x_range(2)], ...
                'ylim', obj.y_range,'ytick', [obj.y_range(1):200:obj.y_range(2)], ...
                'xticklabel', [], 'yticklabel', [], ...
                'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'ydir', 'reverse');
            % ha3 is essentially the same as ha2, but data points are semi-transparent

            xlabel('Horizontal axis (pixels)');
            ylabel('Vertical axis (pixels)');
            title(obj.Treatment);

            % define whenever the paw enters this region as time = 0
            tMap = [-1000:2000];

            posmat = obj.PoseTracking.PosData;
            trajAll = NaN*ones(length(tMap), 3, length(posmat));

            for j =1:length(posmat)
                tj_interp =[];
                indplot = find(posmat{j}(:, 4)<=100);
                tj          =    posmat{j}(indplot, 4);
                posj      =      posmat{j}(indplot, [1 2]);
                trajorg = [tj, posj];
                %         [dist] = CalDist(trajorg, 1)
                t_traj = [min(tj):max(tj)];
                tj_interp(:, 1) = smoothdata(interp1(tj,posj(:, 1),t_traj), 'gaussian', 25);
                tj_interp(:, 2) = smoothdata(interp1(tj,posj(:, 2),t_traj), 'gaussian', 25);

                % find peak
                [peaka, locpeak] = findpeaks(-tj_interp(:, 2));
                if ~isempty(locpeak)
                    [~, indmax] = max(peaka);
                    tjnew = t_traj - round(t_traj(locpeak(indmax)));
                else
                    continue
                end
                [~, indMapTo, indMapFrom] = intersect(tMap, tjnew);
                trajAll(indMapTo, 1, j) = tjnew(indMapFrom);
                trajAll(indMapTo, 2, j) = tj_interp(indMapFrom, 1);
                trajAll(indMapTo, 3, j) = tj_interp(indMapFrom, 2);

            end

            tmap = [tmin:tmax];
            cmap = viridis(length(tmap));
            x_aligned = [];
            y_aligned = [];

            for i = 1:size(trajAll, 3)
                t_plot = trajAll(:, 1, i);
                x_plot = trajAll(:, 2, i);
                y_plot = trajAll(:, 3, i);

                x_plot_aligned = nan*ones(1, length(tmap));
                y_plot_aligned = nan*ones(1, length(tmap));
                indplot = find(~isnan(x_plot) & ~isnan(y_plot));
                [~, indmap, indplot2] = intersect(tmap, t_plot(indplot));
                t_plot = t_plot(indplot(indplot2));
                x_plot = x_plot(indplot(indplot2));
                y_plot = y_plot(indplot(indplot2));
                x_plot_aligned(indmap) = x_plot;
                y_plot_aligned(indmap) = y_plot;
                x_aligned = [x_aligned x_plot_aligned'];
                y_aligned = [y_aligned y_plot_aligned'];

                c_plot = cmap(indmap, :);
                ind_selected = floor(linspace(1, length(t_plot), length(t_plot)/10));
                s = scatter(ha2, x_plot(ind_selected), y_plot(ind_selected), 5, c_plot(ind_selected, :), 'filled');
                s2 = scatter(ha3, x_plot(ind_selected), y_plot(ind_selected), 5, c_plot(ind_selected, :), 'filled');
                set(s2, 'MarkerFaceAlpha', 0.2, 'MarkerEdgeColor', 'none', 'MarkerEdgeAlpha',  .2);
            end

            % save trajsamples x_aligned y_aligned
            % this plots the color scalebar
            ha4 = axes('units', 'centimeters', 'position', [xpos(4) ypos(4) plotsize(4, :)], ...
                'nextplot', 'add', ...
                'YAxisLocation', 'right',...
                'ydir', 'normal','ylim', [tmap(1)-20 tmap(end)+20], ...
                'ytick', [-200:200:1400], 'xlim', [0 1.5], 'xtick', [], 'TickLength', [0.015 0.1]);

            ss =  scatter(ones(1, length(tmap)), tmap, 30,  cmap, 'filled', 's');
            ylabel('Time from maximal height (ms)');

            % compute lever position
            % Lever end-point:
            tmaxout = median(tmap(tmap>0));

            LeverXend = nanmedian(x_aligned, 2) ;
            LeverXend = nanmean(LeverXend(tmap>tmaxout));
            LeverYend = nanmedian(y_aligned, 2);
            LeverYend = nanmean(LeverYend(tmap>tmaxout));

            % x, y vs t
            % this plots trajectory: x vs t
            ha2b = axes('unit', 'centimeters', 'position', [xpos(5) ypos(5) plotsize(5, :)], 'nextplot', 'add',...
                'xlim', [tmin-100 tmax+100],'ytick', [200:200:800], 'ylim', obj.x_range, ...
                'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'ydir', 'reverse');

            xlabel('Time from maximal height (ms)');
            ylabel('Horizontal axis (pixels)');

            % this plots trajectory: y vs t
            ha2c = axes('unit', 'centimeters', 'position', [xpos(6) ypos(6) plotsize(6, :)], 'nextplot', 'add',...
                'xlim', [tmin-100 tmax+100], 'ytick', [200:200:1000],'ylim', obj.y_range, ...
                'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'ydir', 'reverse');

            xlabel('Time from maximal height (ms)');
            ylabel('Vertical axis (pixels)');

            ha2d = axes('unit', 'centimeters', 'position', [xpos(7) ypos(7) plotsize(7, :)], 'nextplot', 'add',...
                'xlim', [tmin-100 tmax+100], 'ytick', [0:200:1000],'ylim', [-10 600], ...
                'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'ydir', 'reverse');
            xlabel('Time from maximal height (ms)');
            ylabel('Distance to lever (pixels)');
            
            ha2e = axes('unit', 'centimeters', 'position', [xpos(13) ypos(13) plotsize(13, :)], 'nextplot', 'add',...
                'xlim', [tmin-100 tmax+100], 'ytick', [0:50:200],'ylim', [0 150], ...
                'tickdir', 'out', 'TickLength', [0.0200 0.0250]);
            xlabel('Time from maximal height (ms)');
            ylabel('Speed (pixels/frame)');

            dist_aligned = dist_out(x_aligned, y_aligned, LeverXend, LeverYend);
            speed_aligned = speed_out(x_aligned,y_aligned,'bin',20);
            
            plot(ha2b, tmap, x_aligned, 'color', [0.8 0.8 0.8], 'linewidth', 0.5);
            plot(ha2c, tmap, y_aligned, 'color', [0.8 0.8 0.8], 'linewidth', 0.5);
            plot(ha2d, tmap, dist_aligned, 'color', [0.8 0.8 0.8], 'linewidth', 0.5);
            plot(ha2e, tmap, speed_aligned, 'color', [0.8 0.8 0.8], 'linewidth', 0.5);
            
            plot(ha2b, tmap, nanmedian(x_aligned, 2), 'color', [0 0 0], 'linewidth', 2);
            plot(ha2c, tmap, nanmedian(y_aligned, 2), 'color', [0 0 0], 'linewidth', 2);
            plot(ha2d, tmap, nanmedian(dist_aligned, 2), 'color', [0 0 0], 'linewidth', 2);
            plot(ha2e, tmap, nanmedian(speed_aligned, 2), 'color', [0 0 0], 'linewidth', 2);

            hadist1 = axes('nextplot', 'add', 'unit', 'centimeters', 'position', [xpos(8) ypos(8) plotsize(8, :)], ...
                'xlim', [0 600],'xtick', [0:200:600], 'ylim', [0 0.25], 'ticklength', [0.02 1]);  % this is the histogram of the paw-to-lever distribution
            xlabel('Distance to lever');
            ylabel('Probability');
            
            
            
            
            


            % cycle through t_endpoints
            for i =1:length(obj.t_endpoints)
                % get the poisition at -50 ms to peak
                [~, ind_end] = min(abs(tmap - obj.t_endpoints(i)));

                hascatter1 = axes('nextplot', 'add', 'unit', 'centimeters', 'position', [xpos(8+i) ypos(8+i) plotsize(8+i, :)], ...
                    'xlim', obj.x_range, 'ylim', obj.y_range, 'ydir', 'reverse');

                % derive 2d histogram
                xedges = [obj.x_range(1):20:obj.x_range(2)];
                yedges = [obj.y_range(1):20:obj.y_range(2)];

                xbincenters = [xedges(1:end-1)+xedges(2:end)]/2;
                ybincenters = [yedges(1:end-1)+yedges(2:end)]/2;

                ndist2=histcounts2(x_aligned(ind_end, :),y_aligned(ind_end, :), xedges, yedges);
                psf = fspecial('gaussian', [8 8], 1); % create a 2d gaussian kernel
                ndist2sm = conv2(ndist2, psf,'same');
                imagesc(hascatter1, xbincenters, ybincenters, ndist2sm');
                scatter(hascatter1, LeverXend, LeverYend, 50, 'w', '+');
                if i == 1
                    xlabel('x position');
                    ylabel('y position');
                else
                    set(gca, 'xtick', [], 'ytick',[]);
                end

                title(sprintf('%2.0d ms', obj.t_endpoints(i)), 'color', these_colors(i, :));

                %                 endpoints = struct('tend',[], 'xend',[], 'yend',[]);
                %                 endpoints.xend = {x_aligned(ind_end, :)};
                %                 endpoints.yend = {y_aligned(ind_end, :)};
                %                 obj.endpoints = endpoints;

                % get the distribution of dist_aligned
                dist_aligned1  = dist_aligned(ind_end, :);
                bin_edges = [0:20:600];
                bin_centers = mean([bin_edges(1:end-1); bin_edges(2:end)], 1);
                [ndist, bin_edges] = histcounts(dist_aligned1, bin_edges, 'normalization', 'probability');
                ndist = smoothdata(ndist, 'gaussian', 5);
                plot(hadist1, bin_centers, ndist, 'color',these_colors(i, :),'linewidth', 1);
                
                % get the speed
                

            end


        end
        %
    end
end
