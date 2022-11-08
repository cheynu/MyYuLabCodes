function TrajOut = DLCTrajPrePost(TrackingOutPreLesion, TrackingOutPostLesion, varargin)
% J Yu 6/14/2022

ANM_Name = 'Unknown';
savepath = pwd;

yrange = [400 800];
xrange = [300 900];

trange = [-300 200];
t_endpoints = [-50,-100,-200];

for i=1:2:size(varargin,2)
    switch varargin{i}
        case {'ANM_Name'}
            ANM_Name = varargin{i+1};
        case 'HorizontalRange'
            xrange =  varargin{i+1};
        case 'VerticalRange'
            yrange =  varargin{i+1};
        case 'tRange'
            trange =  varargin{i+1};
        case 'savepath'
            savepath = varargin{i+1};
        case 'tEndPoints'
            t_endpoints = varargin{i+1};
    end
end

tmin = trange(1);
tmax = trange(2);

nes = zeros(1, length(TrackingOutPreLesion));
for i =1:length(TrackingOutPreLesion)
    ne(i) = randperm(length( TrackingOutPreLesion(i).PoseTracking.PosData), 1);
end

nes = zeros(1, length(TrackingOutPostLesion));
for i =1:length(TrackingOutPostLesion)
    nes(i) = randperm(length(TrackingOutPostLesion(i).PoseTracking.PosData), 1);
end

lsize=size(TrackingOutPreLesion(1).PoseTracking.Images{ne(1)});
lx = lsize(2);
ly = lsize(1);

nspace = 5; % this is to plot trajectory--how points are spaced out. time diff between points, etc.
close all;


height =  3;
width =  height*diff(xrange)/diff(yrange);
kshift = 1.35; % to space out each row
xsep = 1.5;
xsep2 = 1;
plotperc = 99.5;

fontAxesSz = 7;
fontLablSz = 8;
fontTitlSz = 8.5;

set(groot,'defaultAxesFontName','Helvetica')
%%
nSession = length(TrackingOutPreLesion)+length(TrackingOutPostLesion);
hf=25;
figure(hf); clf(hf)
sizeFig = [1 1 38.5 29.5];
set(gcf, 'unit', 'centimeters', 'position', sizeFig, ...
    'paperpositionmode', 'auto','renderer','opengl', 'Visible', 'on', 'color', 'w');% 'rederer','Painters'

% Write down the name
h_ANM_Name = uicontrol('style', 'text', 'parent', hf, 'unit', 'centimeters', ...
    'position', [sizeFig(3)/2-1.5, sizeFig(4)-0.5, 3, 0.5], ...
    'backgroundcolor', 'w', 'string', ANM_Name, 'BackgroundColor', 'w' , ...
    'fontsize',10, 'fontname', 'Dejavu Sans','ForegroundColor', 'k', ...
    'FontWeight', 'bold');
for k=1:length(TrackingOutPreLesion)
    ha1 = axes('unit', 'centimeters', 'position', [1 sizeFig(4)-k*height*kshift width height], 'nextplot', 'add',...
        'xlim', xrange, 'ylim', yrange, ...
        'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'ydir', 'reverse','Fontsize',fontAxesSz);
    title({'PreLesion',TrackingOutPreLesion(k).Session},'fontsize',fontTitlSz); ha1.TitleHorizontalAlignment = 'left';
    Rsize=size(TrackingOutPreLesion(k).PoseTracking.Images{ne(k)});
    Rx = Rsize(2);
    image(ha1, imresize(TrackingOutPreLesion(k).PoseTracking.Images{ne(k)}(:, :, :, 3),Rx/lx));
    posmat_eg=TrackingOutPreLesion(k).PoseTracking.PosData{ne(k)};
    posmat_eg =[posmat_eg(:,1:2)*Rx/lx,posmat_eg(:,3:4)];
    indplot = find(posmat_eg(:, 4)<=0);
    plot(ha1, posmat_eg(indplot, 1), posmat_eg(indplot, 2), 'color', [255 135 0]/255, 'linewidth', 1.5);

    axis off
    % plot all trials
    ha2 = axes('unit', 'centimeters', 'position', [2+width+xsep sizeFig(4)-k*height*kshift width height], 'nextplot', 'add',...
        'xlim', xrange, 'ylim', yrange, ...
        'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'ydir', 'reverse','Fontsize',fontAxesSz);
    if k==1
        xlabel('Horizontal axis (pixels)','FontSize',fontLablSz);
        ylabel('Vertical axis (pixels)','FontSize',fontLablSz);

    end
    ha3 = axes('unit', 'centimeters', 'position', [2+(width+xsep)*2 sizeFig(4)-k*height*kshift width height], 'nextplot', 'add',...
        'xlim', xrange, 'ylim', yrange, ...
        'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'ydir', 'reverse','Fontsize',fontAxesSz);
    if k==1
        xlabel('Horizontal axis (pixels)','FontSize',fontLablSz);
        ylabel('Vertical axis (pixels)','FontSize',fontLablSz);
    end

    t_traj = [-1000:1:100]; % time
    tj_interp = [];
    trajAll = []; % t, x, y
    FlexPoints = [];

    % define whenever the paw enters this region as time = 0
    xy_threshold = [650 650];
    tMap = [-1000:2000];

    for ipre =k
        posmat = arrayfun(@(x)[TrackingOutPreLesion(ipre).PoseTracking.PosData{x}(:,1:2)*Rx/lx,TrackingOutPreLesion(ipre).PoseTracking.PosData{x}(:,3:4)],[1:length(TrackingOutPreLesion(ipre).PoseTracking.PosData)],'UniformOutput',false);
        trajAll = NaN*ones(length(tMap), 3, length(posmat));

        for j =1:length(posmat)
            tj_interp =[];
            indplot = find(posmat{j}(:, 4)<=100);
            tj   = posmat{j}(indplot, 4);
            posj = posmat{j}(indplot, [1 2]);

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
        set(s2, 'MarkerFaceAlpha', 0.2, 'MarkerEdgeColor', 'none', 'MarkerEdgeAlpha',  .2)
    end

    % save trajsamples x_aligned y_aligned

    TrajOut.tpre{ipre} = tmap;
    TrajOut.xpre{ipre} = x_aligned;
    TrajOut.ypre{ipre} = y_aligned;

    % this plots the color scalebar
    if k==1
        ha4 = axes('units', 'centimeters', 'position', [2+(width+xsep)*3 sizeFig(4)-k*height*kshift 0.5 height], ...
            'nextplot', 'add', 'Fontsize',fontAxesSz,...
            'ydir', 'normal','xlim', [0 1.5], ...
            'xtick', [], 'ylim', [tmap(1)-20 tmap(end)+20], 'ytick', [-200:200:1400], 'TickLength', [0.015 0.1]);

        ss =  scatter(ones(1, length(tmap)), tmap, 20,  cmap, 'filled', 's');
        ylabel('Time from maximal height (ms)','FontSize',fontLablSz);
    end
    % compute lever position
    % Lever end-point:
    tmaxout = median(tmap(tmap>0));

    LeverXend = nanmedian(x_aligned, 2) ;
    LeverXend = nanmean(LeverXend(tmap>tmaxout));
    LeverYend = nanmedian(y_aligned, 2);
    LeverYend = nanmean(LeverYend(tmap>tmaxout));

    % x, y vs t
    % this plots trajectory: x vs t
    if k==1
        ha2b = axes('unit', 'centimeters', 'position', [2+(width+xsep)*3+2 sizeFig(4)-k*height*kshift width, height], 'nextplot', 'add',...
            'xlim', [tmin-100 tmax+100],'ytick', [200:200:800], 'ylim', xrange, 'Fontsize',fontAxesSz,...
            'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'ydir', 'reverse');
        xlabel('Time from maximal height (ms)','FontSize',fontLablSz);
        ylabel('Horizontal axis (pixels)','FontSize',fontLablSz);
        % this plots trajectory: y vs t
        ha2c = axes('unit', 'centimeters', 'position', [2+(width+xsep)*4+2 sizeFig(4)-k*height*kshift  width, height], 'nextplot', 'add',...
            'xlim', [tmin-100 tmax+100], 'ytick', [200:200:1000],'ylim', yrange, 'Fontsize',fontAxesSz,...
            'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'ydir', 'reverse');
        xlabel('Time from maximal height (ms)','FontSize',fontLablSz);
        ylabel('Vertical axis (pixels)','FontSize',fontLablSz);
        ha2d = axes('unit', 'centimeters', 'position', [2+(width+xsep)*5+2 sizeFig(4)-k*height*kshift width, height], 'nextplot', 'add',...
            'xlim', [tmin-100 tmax+100], 'ytick', [0:200:1000],'ylim', [-10 600], 'Fontsize',fontAxesSz,...
            'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'ydir', 'reverse');
        xlabel('Time from maximal height (ms)','FontSize',fontLablSz);
        ylabel('Distance to lever (pixels)','FontSize',fontLablSz);
        ha2e = axes('unit', 'centimeters', 'position', [2+(width+xsep)*6+2 sizeFig(4)-k*height*kshift width, height], 'nextplot', 'add',...
            'xlim', [tmin-100 tmax+100], 'ytick', [0:50:200],'ylim', [0 150], 'Fontsize',fontAxesSz,...
            'tickdir', 'out', 'TickLength', [0.0200 0.0250]);
        xlabel('Time from maximal height (ms)','FontSize',fontLablSz);
        ylabel('Speed (pixels/frame)','FontSize',fontLablSz);

        dist_aligned = dist_out(x_aligned, y_aligned, LeverXend, LeverYend);
        speed_aligned = speed_out(x_aligned, y_aligned,'bin',20); % 1 frame -> 20ms -> 20bin
        
        plot(ha2b, tmap, x_aligned, 'color', [0.8 0.8 0.8], 'linewidth', 0.5);
        plot(ha2c, tmap, y_aligned, 'color', [0.8 0.8 0.8], 'linewidth', 0.5);
        plot(ha2d, tmap, dist_aligned, 'color', [0.8 0.8 0.8], 'linewidth', 0.5);
        plot(ha2e, tmap, speed_aligned, 'color', [0.8 0.8 0.8], 'linewidth', 0.5);

        plot(ha2b, tmap, nanmedian(x_aligned, 2), 'color', [0 0 0], 'linewidth', 2);
        plot(ha2c, tmap, nanmedian(y_aligned, 2), 'color', [0 0 0], 'linewidth', 2);
        plot(ha2d, tmap, nanmedian(dist_aligned, 2), 'color', [0 0 0], 'linewidth', 2);
        plot(ha2e, tmap, nanmedian(speed_aligned, 2), 'color', [0 0 0], 'linewidth', 2);
    else
        ha2b2 = axes('unit', 'centimeters', 'position', [2+(width+xsep)*3+2 sizeFig(4)-k*height*kshift width, height], 'nextplot', 'add',...
            'xlim', [tmin-100 tmax+100],'ytick', [200:200:800], 'ylim', xrange, 'Fontsize',fontAxesSz,...
            'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'ydir', 'reverse');
        % this plots trajectory: y vs t
        ha2c2 = axes('unit', 'centimeters', 'position', [2+(width+xsep)*4+2 sizeFig(4)-k*height*kshift  width, height], 'nextplot', 'add',...
            'xlim', [tmin-100 tmax+100], 'ytick', [200:200:1000],'ylim', yrange, 'Fontsize',fontAxesSz,...
            'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'ydir', 'reverse');
        ha2d2 = axes('unit', 'centimeters', 'position', [2+(width+xsep)*5+2 sizeFig(4)-k*height*kshift width, height], 'nextplot', 'add',...
            'xlim', [tmin-100 tmax+100], 'ytick', [0:200:1000],'ylim', [-10 600], 'Fontsize',fontAxesSz,...
            'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'ydir', 'reverse');
        ha2e2 = axes('unit', 'centimeters', 'position', [2+(width+xsep)*6+2 sizeFig(4)-k*height*kshift width, height], 'nextplot', 'add',...
            'xlim', [tmin-100 tmax+100], 'ytick', [0:50:200],'ylim', [0 150], 'Fontsize',fontAxesSz,...
            'tickdir', 'out', 'TickLength', [0.0200 0.0250]);

        dist_aligned = dist_out(x_aligned, y_aligned, LeverXend, LeverYend);
        speed_aligned = speed_out(x_aligned, y_aligned,'bin',20); % 1 frame -> 20ms -> 20bin

        plot(ha2b2, tmap, x_aligned, 'color', [0.8 0.8 0.8], 'linewidth', 0.5);
        plot(ha2c2, tmap, y_aligned, 'color', [0.8 0.8 0.8], 'linewidth', 0.5);
        plot(ha2d2, tmap, dist_aligned, 'color', [0.8 0.8 0.8], 'linewidth', 0.5);
        plot(ha2e2, tmap, speed_aligned, 'color', [0.8 0.8 0.8], 'linewidth', 0.5);

        plot(ha2b2, tmap, nanmedian(x_aligned, 2), 'color', [0 0 0], 'linewidth', 2);
        plot(ha2c2, tmap, nanmedian(y_aligned, 2), 'color', [0 0 0], 'linewidth', 2);
        plot(ha2d2, tmap, nanmedian(dist_aligned, 2), 'color', [0 0 0], 'linewidth', 2);
        plot(ha2e2, tmap, nanmedian(speed_aligned, 2), 'color', [0 0 0], 'linewidth', 2);

        plot(ha2b, tmap, nanmedian(x_aligned, 2), 'color', [0 0 0], 'linewidth', 2);
        plot(ha2c, tmap, nanmedian(y_aligned, 2), 'color', [0 0 0], 'linewidth', 2);
        plot(ha2d, tmap, nanmedian(dist_aligned, 2), 'color', [0 0 0], 'linewidth', 2);
        plot(ha2e, tmap, nanmedian(speed_aligned, 2), 'color', [0 0 0], 'linewidth', 2);
    end
    trajAllPre = trajAll;

    x_prelesion_final = [];
    y_prelesion_final = [];

    for i = 1:size(trajAll, 3)
        ind_final = find(trajAll(:, 1, i) >tmax/2 & trajAll(:, 1, i) < tmax & ~isnan(trajAll(:, 1, i)));
        x_prelesion_final = [x_prelesion_final; trajAll(ind_final, 2, i)];
        y_prelesion_final = [y_prelesion_final; trajAll(ind_final, 3, i)];
    end

    % compute the variance

    % hf2 = figure(26); set(hf2,'visible', 'on', 'unit', 'centimeters', 'position', [8 8 20 8])

    [~, ind50] = min(abs(tmap - t_endpoints(1)));
    if k==1
        hascatter50 = axes('nextplot', 'add', 'unit', 'centimeters', 'position',...
            [1.5 sizeFig(4)-height*kshift*(1+nSession) height height], ...
            'xlim', xrange, 'ylim', yrange, 'ydir', 'reverse', 'Fontsize',fontAxesSz);
        xlabel('x position','FontSize',fontLablSz);
        ylabel('y position','FontSize',fontLablSz);
        title([num2str(t_endpoints(1)),' ms'],'fontsize',fontTitlSz);
    end
    s_prelesion1 = scatter(hascatter50, x_aligned(ind50, :), y_aligned(ind50, :), 10, "black", 'filled');
    set(s_prelesion1, 'MarkerFaceAlpha', 0.75, 'MarkerEdgeColor', 'none', 'MarkerEdgeAlpha',  .8);

    % get the distribution of dist_aligned
    dist_aligned50_prelesion = dist_aligned(ind50, :);
    VarEnd50{k}=dist_aligned50_prelesion;
    if k==1
        hadist50 = axes('nextplot', 'add', 'unit', 'centimeters', 'position',...
            [1.5+(height+xsep2) sizeFig(4)-height*kshift*(1+nSession) height height], ...
            'xlim', [0 600],'xtick', [0:200:600], 'ylim', [0 0.5], 'Fontsize',fontAxesSz);
        xlabel('Distance to lever','FontSize',fontLablSz);
        ylabel('Probability','FontSize',fontLablSz);
    end

    bin_edges = [0:20:600];
    bin_centers = mean([bin_edges(1:end-1); bin_edges(2:end)], 1);
    [npre50, bin_edges] = histcounts(dist_aligned50_prelesion, bin_edges, 'normalization', 'probability');
    npre50 = smoothdata(npre50, 'gaussian', 5);
    hadist50bars = plot(hadist50, bin_centers, npre50, 'color','k','linewidth', 1);

    [~, ind100] = min(abs(tmap - t_endpoints(2)));
    if k==1
        hascatter100 = axes('nextplot', 'add', 'unit', 'centimeters', 'position',...
            [1.5+(height+xsep2)*2 sizeFig(4)-height*kshift*(1+nSession) height height], ...
            'xlim', xrange, 'ylim', yrange, 'ydir', 'reverse', 'Fontsize',fontAxesSz);
        xlabel('x position','FontSize',fontLablSz);
        ylabel('y position','FontSize',fontLablSz);
        title([num2str(t_endpoints(2)),' ms'],'FontSize',fontTitlSz);
    end
    s_prelesion2 = scatter(hascatter100, x_aligned(ind100, :), y_aligned(ind100, :), 10, "black", 'filled');
    set(s_prelesion2, 'MarkerFaceAlpha', 0.75, 'MarkerEdgeColor', 'none', 'MarkerEdgeAlpha',  .8);

    % get the distribution of dist_aligned
    dist_aligned100_prelesion = dist_aligned(ind100, :);
    VarEnd100{k}=dist_aligned100_prelesion;
    if k==1
        hadist100 = axes('nextplot', 'add', 'unit', 'centimeters', 'position',...
            [1.5+(height+xsep2)*3 sizeFig(4)-height*kshift*(1+nSession) height height], ...
            'xlim', [0 600],'xtick', [0:200:600], 'ylim', [0 0.5], 'Fontsize',fontAxesSz);
        xlabel('Distance to lever','FontSize',fontLablSz);
        ylabel('Probability','FontSize',fontLablSz);
    end
    %
    % bin_edges = [0:50:600];
    % bin_centers = mean([bin_edges(1:end-1); bin_edges(2:end)], 1);
    [npre100, bin_edges] = histcounts(dist_aligned100_prelesion, bin_edges, 'normalization', 'probability');
    npre100 = smoothdata(npre100, 'gaussian', 5);
    hadist100bars = plot(hadist100, bin_centers, npre100, 'color','k','linewidth', 1);

    if trange(1) <= t_endpoints(3)
        [~, ind200] = min(abs(tmap - t_endpoints(3)));
        if k==1
            hascatter200 = axes('nextplot', 'add', 'unit', 'centimeters', 'position',...
                [1.5+(height+xsep2)*4 sizeFig(4)-height*kshift*(1+nSession) height height], ...
                'xlim', xrange, 'ylim', yrange, 'ydir', 'reverse', 'Fontsize',fontAxesSz);
            xlabel('x position','FontSize',fontLablSz);
            ylabel('y position','FontSize',fontLablSz);
            title([num2str(t_endpoints(3)),' ms'],'FontSize',fontTitlSz);
        end
        s_prelesion3 = scatter(hascatter200, x_aligned(ind200, :), y_aligned(ind200, :), 10, "black", 'filled');
        set(s_prelesion3, 'MarkerFaceAlpha', 0.75, 'MarkerEdgeColor', 'none', 'MarkerEdgeAlpha',  .8);

        % get the distribution of dist_aligned
        dist_aligned200_prelesion = dist_aligned(ind200, :);
        VarEnd200{k}=dist_aligned200_prelesion;
        if k==1
            hadist200 = axes('nextplot', 'add', 'unit', 'centimeters', 'position',...
                [1.5+(height+xsep2)*5 sizeFig(4)-height*kshift*(1+nSession) height height], ...
                'xlim', [0 600],'xtick', [0:200:600], 'ylim', [0 0.5], 'Fontsize',fontAxesSz);
            xlabel('Distance to lever','FontSize',fontLablSz);
            ylabel('Probability','FontSize',fontLablSz);

            %
            % bin_edges = [0:50:600];
            % bin_centers = mean([bin_edges(1:end-1); bin_edges(2:end)], 1);
            [npre200, bin_edges] = histcounts(dist_aligned200_prelesion, bin_edges, 'normalization', 'probability');
            npre200 = smoothdata(npre200, 'gaussian' ,5);

            hadist200bars = plot(hadist200, bin_centers, npre200, 'color','k','linewidth', 1);

        end
    end
end
figure(hf);

these_colors = [
    193 68 14
    255 127.5 79.1
    231 125 18
    253 186 0
    ]/255;

for eg =1:length(TrackingOutPostLesion)

    ha3(eg) = axes('unit', 'centimeters', 'position', [1 sizeFig(4)-height*kshift*(eg+length(TrackingOutPreLesion)) width height], 'nextplot', 'add',...
        'xlim', xrange, 'ylim', yrange, ...
        'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'ydir', 'reverse', 'Fontsize', fontAxesSz);

    ne = nes(eg);
    Rsize=size(TrackingOutPostLesion(eg).PoseTracking.Images{ne});
    Rx = Rsize(2);
    title({'PostLesion',TrackingOutPostLesion(eg).Session},'fontsize',fontTitlSz);ha3(eg).TitleHorizontalAlignment = 'left';


    image(ha3(eg), imresize(TrackingOutPostLesion(eg).PoseTracking.Images{ne}(:, :, :, 3),Rx/lx));
    posmat_eg = TrackingOutPostLesion(eg).PoseTracking.PosData{ne};
    posmat_eg =[posmat_eg(:,1:2)*Rx/lx,posmat_eg(:,3:4)];
    indplot = find(posmat_eg(:, 4)<=200);
    plot(ha3(eg), posmat_eg(indplot, 1), posmat_eg(indplot, 2), 'color', [255 135 0]/255, 'linewidth', 1.5);
    axis off

    % plot trajectories
    ha2 = axes('unit', 'centimeters', 'position', [2+(width+xsep) sizeFig(4)-height*kshift*(eg+length(TrackingOutPreLesion)) width height], 'nextplot', 'add',...
        'xlim', xrange, 'ylim', yrange, ...
        'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'ydir', 'reverse', 'Fontsize', fontAxesSz);
    %
    %     xlabel('Horizontal axis (pixels)')
    %     ylabel('Vertical axis (pixels)')


    ha3 = axes('unit', 'centimeters', 'position', [2+(width+xsep)*2 sizeFig(4)-height*kshift*(eg+length(TrackingOutPreLesion)) width height], 'nextplot', 'add',...
        'xlim', xrange, 'ylim', yrange, ...
        'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'ydir', 'reverse', 'Fontsize', fontAxesSz);

    %     xlabel('Horizontal axis (pixels)')
    %     ylabel('Vertical axis (pixels)')

    t_traj = [-1000:1:100]; % time
    tj_interp = [];
    FlexPoints = [];
    posmat = arrayfun(@(x)[TrackingOutPostLesion(eg).PoseTracking.PosData{x}(:,1:2)*Rx/lx,TrackingOutPostLesion(eg).PoseTracking.PosData{x}(:,3:4)],[1:length(TrackingOutPostLesion(eg).PoseTracking.PosData)],'UniformOutput',false);

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


    % calibrate so make sure lever position is the same for pre- and post
    % conditions

    x_postlesion_final = [];
    y_postlesion_final = [];

    for i = 1:size(trajAll, 3)
        ind_final = find(trajAll(:, 1, i) > tmax/2 & trajAll(:, 1, i) < tmax & ~isnan(trajAll(:, 1, i)));
        x_postlesion_final = [x_postlesion_final; trajAll(ind_final, 2, i)];
        y_postlesion_final = [y_postlesion_final; trajAll(ind_final, 3, i)];
    end;

    dx = mean(x_postlesion_final) - mean(x_prelesion_final);
    dy = mean(y_postlesion_final) - mean(y_prelesion_final);

    trajAll(:, 2, :) =  trajAll(:, 2, :) - dx;
    trajAll(:, 3, :) =  trajAll(:, 3, :) - dy;
    trajAllPost{eg} = trajAll;

    %     tmap = [tmin:tmax];
    %     cmap = parula(length(tmap));
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
        set(s2, 'MarkerFaceAlpha', 0.2, 'MarkerEdgeColor', 'none', 'MarkerEdgeAlpha',  .2)
    end

    % save trajectory data
    TrajOut.tpost{eg} = tmap;
    TrajOut.xpost{eg} = x_aligned;
    TrajOut.ypost{eg} = y_aligned;

    %     save(['TrajOut_' ANM_Name '.mat'], 'TrajOut')

    % Lever end-point:
    LeverXend = nanmedian(x_aligned, 2) ;
    LeverXend = nanmean(LeverXend(tmap>tmaxout));
    LeverYend = nanmedian(y_aligned, 2);
    LeverYend = nanmean(LeverYend(tmap>tmaxout));

    % x, y vs t
    ha2bpost = axes('unit', 'centimeters', 'position', [2+(width+xsep)*3+2 sizeFig(4)-height*kshift*(eg+length(TrackingOutPreLesion)) width, height], 'nextplot', 'add',...
        'xlim', [tmin-100 tmax+100],'ytick', [200:200:800], 'ylim', xrange, ...
        'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'ydir', 'reverse', 'Fontsize', fontAxesSz);
    %
    %     xlabel('Time from lift (ms)')
    %     ylabel('Horizontal axis (pixels)')
    ha2cpost = axes('unit', 'centimeters', 'position', [2+(width+xsep)*4+2 sizeFig(4)-height*kshift*(eg+length(TrackingOutPreLesion)) width height], 'nextplot', 'add',...
        'xlim', [tmin-100 tmax+100], 'ytick', [200:200:1000],'ylim', yrange, ...
        'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'ydir', 'reverse', 'Fontsize', fontAxesSz);
    %
    %     xlabel('Time from lift (ms)')
    %     ylabel('Vertical axis (pixels)')
    ha2dpost = axes('unit', 'centimeters', 'position', [2+(width+xsep)*5+2 sizeFig(4)-height*kshift*(eg+length(TrackingOutPreLesion)) width height], 'nextplot', 'add',...
        'xlim', [tmin-100 tmax+100], 'ytick', [0:200:1000],'ylim', [-10 600], ...
        'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'ydir', 'reverse', 'Fontsize', fontAxesSz);
    ha2epost = axes('unit', 'centimeters', 'position', [2+(width+xsep)*6+2 sizeFig(4)-height*kshift*(eg+length(TrackingOutPreLesion)) width height], 'nextplot', 'add',...
        'xlim', [tmin-100 tmax+100], 'ytick', [0:50:200],'ylim', [0 150], ...
        'tickdir', 'out', 'TickLength', [0.0200 0.0250], 'Fontsize', fontAxesSz);

    dist_aligned = dist_out(x_aligned, y_aligned, LeverXend, LeverYend);
    speed_aligned = speed_out(x_aligned, y_aligned,'bin',20); % 1 frame -> 20ms -> 20bin

    plot(ha2bpost, tmap, x_aligned, 'color', [0.8 0.8 0.8], 'linewidth', 0.5);
    plot(ha2cpost, tmap, y_aligned, 'color', [0.8 0.8 0.8], 'linewidth', 0.5);
    plot(ha2dpost, tmap, dist_aligned, 'color', [0.8 0.8 0.8], 'linewidth', 0.5);
    plot(ha2epost, tmap, speed_aligned, 'color', [0.8 0.8 0.8], 'linewidth', 0.5);

    plot(ha2bpost, tmap, nanmedian(x_aligned, 2), 'color', these_colors(eg, :), 'linewidth', 2);
    plot(ha2cpost, tmap, nanmedian(y_aligned, 2), 'color', these_colors(eg, :), 'linewidth', 2);
    plot(ha2dpost, tmap, nanmedian(dist_aligned, 2), 'color', these_colors(eg, :), 'linewidth', 2);
    plot(ha2epost, tmap, nanmedian(speed_aligned, 2), 'color', these_colors(eg, :), 'linewidth', 2);

    plot(ha2b, tmap, nanmedian(x_aligned, 2), 'color', these_colors(eg, :), 'linewidth', 2);
    plot(ha2c, tmap, nanmedian(y_aligned, 2), 'color', these_colors(eg, :), 'linewidth', 2);
    plot(ha2d, tmap, nanmedian(dist_aligned, 2), 'color',  these_colors(eg, :), 'linewidth', 2);
    plot(ha2e, tmap, nanmedian(speed_aligned, 2), 'color',  these_colors(eg, :), 'linewidth', 2);

    % plot paw position at -50, -100, -200 ms
    s_postlesion1 = scatter(hascatter50, x_aligned(ind50, :), y_aligned(ind50, :), 10, these_colors(eg, :), 'filled');
    set(s_postlesion1, 'MarkerFaceAlpha', 0.75, 'MarkerEdgeColor', 'none', 'MarkerEdgeAlpha',  .1);

    % get the distribution of dist_aligned
    dist_aligned50_postlesion1 = dist_aligned(ind50, :);
    VarEnd50{2+eg}=dist_aligned50_postlesion1;
    [npost1_50, bin_edges] = histcounts(dist_aligned50_postlesion1, bin_edges, 'normalization', 'probability');
    npost1_50 = smoothdata(npost1_50, 'gaussian', 5);
    hadist50bars = plot(hadist50, bin_centers, npost1_50, 'color', these_colors(eg, :),'linewidth', 1);

    [~, ind100] = min(abs(tmap - t_endpoints(2)));
    s_postlesion2 = scatter(hascatter100, x_aligned(ind100, :), y_aligned(ind100, :), 10, these_colors(eg, :), 'filled');
    set(s_postlesion2, 'MarkerFaceAlpha', 0.75, 'MarkerEdgeColor', 'none', 'MarkerEdgeAlpha',  .1);

    % get the distribution of dist_aligned
    dist_aligned100_postlesion1 = dist_aligned(ind100, :);
    VarEnd100{2+eg}=dist_aligned100_postlesion1;
    [npost1_100, bin_edges] = histcounts(dist_aligned100_postlesion1, bin_edges, 'normalization', 'probability');
    npost1_100 = smoothdata(npost1_100, 'gaussian', 5);
    hadist100bars = plot(hadist100, bin_centers, npost1_100, 'color', these_colors(eg, :),'linewidth', 1);

    if trange(1) <= t_endpoints(3)
        [~, ind200] = min(abs(tmap - t_endpoints(3)));
        s_postlesion3 = scatter(hascatter200, x_aligned(ind200, :), y_aligned(ind200, :), 10, these_colors(eg, :), 'filled');
        set(s_postlesion3, 'MarkerFaceAlpha', 0.75, 'MarkerEdgeColor', 'none', 'MarkerEdgeAlpha',  .1);

        dist_aligned200_postlesion1 = dist_aligned(ind200, :);
        VarEnd200{2+eg}=dist_aligned200_postlesion1;
        [npost1_200, bin_edges] = histcounts(dist_aligned200_postlesion1, bin_edges, 'normalization', 'probability');
        npost1_200 = smoothdata(npost1_200, 'gaussian', 5);
        hadist200bars = plot(hadist200, bin_centers, npost1_200, 'color', these_colors(eg, :),'linewidth', 1);

    end
end
%
MVartall = axes('nextplot', 'add', 'unit', 'centimeters', 'position',...
    [1.5+(height+xsep2)*6 sizeFig(4)-height*kshift*(1+nSession) height height], ...
    'xlim', [0 7],'xtick', [1:nSession],'xticklabel',[-2 -1 1 2 3 5],'ytick', [0:200:600], 'ylim', [0 600], 'Fontsize', fontAxesSz);
xlabel('Sessions','FontSize',fontLablSz);
ylabel('Mean of Distance','FontSize',fontLablSz);
SVartall = axes('nextplot', 'add', 'unit', 'centimeters', 'position',...
    [1.5+(height+xsep2)*7 sizeFig(4)-height*kshift*(1+nSession) height height], ...
    'xlim', [0 7],'xtick', [1:nSession], 'xticklabel',[-2 -1 1 2 3 5],'ytick', [0:50:250],'ylim', [0 250], 'Fontsize', fontAxesSz);
xlabel('Sessions','FontSize',fontLablSz);
ylabel('Std of Distance','FontSize',fontLablSz);
n1=2.5;
n2=nan;
n3=nan;
MVarEnd50=arrayfun(@(x)nanmean(VarEnd50{x}),[1:length(VarEnd50)], 'UniformOutput', false);
Ci_MVarEnd50=arrayfun(@(x)bootci(1000,@(k)nanmean(k),VarEnd50{x}),[1:length(VarEnd50)], 'UniformOutput', false);
MVarEnd100=arrayfun(@(x)nanmean(VarEnd100{x}),[1:length(VarEnd100)], 'UniformOutput', false);
Ci_MVarEnd100=arrayfun(@(x)bootci(1000,@(k)nanmean(k),VarEnd100{x}),[1:length(VarEnd100)], 'UniformOutput', false);
MVarEnd200=arrayfun(@(x)nanmean(VarEnd200{x}),[1:length(VarEnd200)], 'UniformOutput', false);
Ci_MVarEnd200=arrayfun(@(x)bootci(1000,@(k)nanmean(k),VarEnd200{x}),[1:length(VarEnd200)], 'UniformOutput', false);
SVarEnd50=arrayfun(@(x)nanstd(VarEnd50{x}),[1:length(VarEnd50)], 'UniformOutput', false);
Ci_SVarEnd50=arrayfun(@(x)bootci(1000,@(k)nanstd(k),VarEnd50{x}),[1:length(VarEnd50)], 'UniformOutput', false);
SVarEnd100=arrayfun(@(x)nanstd(VarEnd100{x}),[1:length(VarEnd100)], 'UniformOutput', false);
Ci_SVarEnd100=arrayfun(@(x)bootci(1000,@(k)nanstd(k),VarEnd100{x}),[1:length(VarEnd100)], 'UniformOutput', false);
SVarEnd200=arrayfun(@(x)nanstd(VarEnd200{x}),[1:length(VarEnd200)], 'UniformOutput', false);
Ci_SVarEnd200=arrayfun(@(x)bootci(1000,@(k)nanstd(k),VarEnd200{x}),[1:length(VarEnd200)], 'UniformOutput', false);
plot(MVartall,[1:length(MVarEnd50)],cell2mat(MVarEnd50),'ko-','linewidth',0.5);
plot(MVartall,[1:length(MVarEnd50);1:length(MVarEnd50)],cell2mat(Ci_MVarEnd50),'k','linewidth',0.5);
plot(MVartall,[1:length(MVarEnd100)],cell2mat(MVarEnd100),'ko-','linewidth',1);
plot(MVartall,[1:length(MVarEnd100);1:length(MVarEnd100)],cell2mat(Ci_MVarEnd100),'k','linewidth',1);
plot(MVartall,[1:length(MVarEnd200)],cell2mat(MVarEnd200),'ko-','linewidth',2);
plot(MVartall,[1:length(MVarEnd200);1:length(MVarEnd200)],cell2mat(Ci_MVarEnd200),'k','linewidth',2);
plot(MVartall,[n1,n2,n3;n1,n2,n3;],[0,0,0;650,650,650],'-','color',[0.8 0.36 0.36],'linewidth',0.5);
l1 = plot(SVartall,[1:length(SVarEnd50)],cell2mat(SVarEnd50),'ko-','linewidth',0.5);
plot(SVartall,[1:length(SVarEnd50);1:length(SVarEnd50)],cell2mat(Ci_SVarEnd50),'k','linewidth',0.5);
l2 = plot(SVartall,[1:length(SVarEnd100)],cell2mat(SVarEnd100),'ko-','linewidth',1);
plot(SVartall,[1:length(SVarEnd100);1:length(SVarEnd100)],cell2mat(Ci_SVarEnd100),'k','linewidth',1);
l3 = plot(SVartall,[1:length(SVarEnd200)],cell2mat(SVarEnd200),'ko-','linewidth',2);
plot(SVartall,[1:length(SVarEnd200);1:length(SVarEnd200)],cell2mat(Ci_SVarEnd200),'k','linewidth',2);
plot(SVartall,[n1,n2,n3;n1,n2,n3;],[0,0,0;650,650,650],'-','color',[0.8 0.36 0.36],'linewidth',0.5);
ledis = legend([l1 l2 l3],cellstr(append(string(t_endpoints)'," ms")),'fontsize',fontLablSz,...
    'units','centimeters','position',[1+(height+xsep2)*8 sizeFig(4)-height*kshift*(1+nSession)+height/2 height/2 height/2]);
legend('boxoff');
ledis.ItemTokenSize(1) = 20;
%%
tosavename = fullfile(savepath,...
    ['DLCTrajPeriLesion' '_' ANM_Name]);

print (hf,'-dpng', tosavename);
print (hf,'-depsc2', tosavename);
end

function distout = dist_out(x, y, xref, yref)
% compute e-distance between vector x and y
z_x = x - xref;
z_y = y - yref;
distout = sqrt(z_x.^2+z_y.^2);
end

function [speedout,bin] = speed_out(x,y,varargin)
p = inputParser;
addRequired(p,'x');
addRequired(p,'y');
addParameter(p,'bin',20);
parse(p,x,y,varargin{:});
bin = p.Results.bin;

x_shift = nan(size(x));
y_shift = nan(size(y));
x_shift(bin+1:end,:) = x(1:end-bin,:);
y_shift(bin+1:end,:) = y(1:end-bin,:);
x_mov = abs(x - x_shift);
y_mov = abs(y - y_shift);

speedout = sqrt(x_mov.^2+y_mov.^2);

end