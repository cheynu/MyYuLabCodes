function [pos_out, ind_val, fig] = valifyTrackingParts(traj, part, thres, tol_dur, to_plot)

if nargin<3
    thres = 0.8; % likelihood threshold of valid tracking
    tol_dur = 1; % tolerant duration for below threshold tracking
    to_plot = 0; % whether to plot trajectories
elseif nargin<4
    tol_dur = 1;
    to_plot = 0;
elseif nargin<5
    to_plot = 0;
end

%%
t_frame = traj.t_frame_e;
pos = traj.BodyPart.(part);
n_trial = length(pos);
pos_out = cell(n_trial, 1);
ind_val = false(n_trial, 1);

%
for i = 1:n_trial
    t = t_frame{i};
    x = pos(i).x;
    y = pos(i).y;
    lh = pos(i).lh;

    below_th = find(lh<thres);
    if isempty(below_th)
        % all track results were valid
        pos_out{i} = [x'; y'];
        ind_val(i) = true;
        continue;
    end

    % turn below threshold trackings to nan
    x(below_th) = nan;
    y(below_th) = nan;

    % find begains and ends
    below_th_begs = below_th([1; 1+find(diff(below_th)>1)]);
    below_th_ends = below_th([find(diff(below_th)>1); end]);
    % get the duration of invalid trackings
    below_th_dur  = below_th_ends - below_th_begs + 1;

    ind_interp = false(length(x), 1);
    for j = 1:length(below_th_dur)
        % find the below threshold trackings which duration shorter than tolerant duration
        if below_th_dur(j)<=tol_dur
            ind_interp(below_th_begs(j):below_th_ends(j)) = true;
        end
    end

    if any(ind_interp)
        t_org = t;
        t(ind_interp) = [];
        x(ind_interp) = [];
        y(ind_interp) = [];

        x = interp1(t, x, t_org, 'linear');
        y = interp1(t, y, t_org, 'linear');
    end

    pos_out{i} = [x'; y'];
    ind_val(i) = all(~isnan(x) & ~isnan(y));
end

if to_plot
    fig = figure(); clf(fig);
    set(fig, 'name', 'TrajValify', 'units', 'centimeters', 'position', [5 3 11 5.5], 'PaperUnits', 'centimeters', 'PaperPosition', [5 3 12 5.5], 'visible', 'on');
    ax = axes(fig, 'Units', 'centimeters', 'Position', [.5 .5 10 4], 'NextPlot', 'add', 'FontSize', 9, 'XColor', 'none', 'YColor', 'none', 'YDir', 'reverse');
    
    for i = 1:n_trial
        if ind_val(i)
            c = 'blue';
        else
            c = 'red';
        end
        scatter(ax, pos_out{i}(1,:), pos_out{i}(2,:), 2, c, 'filled', 'MarkerFaceAlpha', .2);
    end
    title(ax, sprintf('%s : %d / %d valid trials', part, sum(ind_val), n_trial));
end

