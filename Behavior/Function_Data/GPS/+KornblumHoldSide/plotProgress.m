function fig_progress = plotProgress(obj)
%%
beh = obj.BehavTable;

beh_sorted = obj.sort_table(beh(beh.Stage==1, :), obj.SortVars, obj.SortCodes);
beh_sorted_st = obj.sort_table(beh(beh.Stage==1, :), [], []);
beh_sorted_mt = obj.sort_table(beh(beh.Stage==1 & beh.Outcome=="Correct", :), obj.SortVars, obj.SortCodes);

perf_sorted = obj.sort_table(obj.Performance.Session, obj.SortVars, obj.SortCodes);
stat_sorted = obj.sort_table(obj.HDStat.Session, obj.SortVars, obj.SortCodes);

if ~all(isfield(obj.HDPDF, ["Early", "Late"]))
    id_early = find(beh.Stage==1 & ~ismember(beh.Label, ["Chemo", "Lesion", "LesionEarly", "LesionExtensive"]), obj.PhaseCount, 'first');
    id_late  = find(beh.Stage==1 & ~ismember(beh.Label, ["Chemo", "Lesion", "LesionEarly", "LesionExtensive"]), obj.PhaseCount, 'last');
    beh_early = beh(id_early, :);
    beh_late  = beh(id_late, :);

    obj.HDSorted.Early = obj.sort_data(beh_early.HD, {beh_early.Cued, beh_early.PortCorrect}, obj.SortCodes);
    obj.HDSorted.Late  = obj.sort_data(beh_late.HD,  {beh_late.Cued,  beh_late.PortCorrect},  obj.SortCodes);

    fprintf("\n******** EarlyTraning ********\n");
    obj.HDPDF.Early = obj.get_kde(obj.HDSorted.Early, obj.Bins.HD, 'pdf', 'HD', 1);
    fprintf("\n******** LateTraning ********\n");
    obj.HDPDF.Late  = obj.get_kde(obj.HDSorted.Late, obj.Bins.HD, 'pdf', 'HD', 1);
    obj.save();
end

C = GPSColor();

%%
ax_sz_1 = [6 2];    
ax_sz_2 = [2.9 2];

[x_grid, y_grid] = meshgrid([1.2 7.7 16 23.2], [10 7 4 1]);
ax_grid = cat(3, x_grid, y_grid);
ax_grid = mat2cell(ax_grid, ones(1,4), ones(1,4), 2);
ax_grid = cellfun(@(x) squeeze(x)', ax_grid, 'UniformOutput', false);

if contains(obj.Protocol, "Self")
    ls = "-";
    lw = 1;
    sort_id = 2;
    rw = .8;
    ax_sz_s = ax_sz_1;
    n_s = 1;
else
    ls = ["-", ":"];
    lw = [1 1.25];
    sort_id = [1 2];
    rw = [.5 .8];
    ax_sz_s = ax_sz_2;
    n_s = 2;
end

% Figure
fig_progress = figure(12); clf(fig_progress);
set(fig_progress, 'Visible', 'on', 'Units', 'centimeters', 'Position', [5 5 30 13.2], 'Color', 'w', 'toolbar', 'none');

fig_title = sprintf("%s / %s / %s - %s", obj.Subject, obj.Protocol, obj.Sessions(1), obj.Sessions(end));
set_fig_title(fig_progress, fig_title);

% performance track
ax_perf_track = obj.assign_ax_to_fig(fig_progress, 1, 2, [ax_grid{1,1} 12.5 2], ax_sz_1);
perf_track = obj.splice_data(obj.PerformanceTrack.Session);
data_perf_track = obj.assign_data_to_ax(ax_perf_track, perf_track(sort_id, :));
draw_perf_track(obj, ax_perf_track, data_perf_track, repmat({ls}, 1, 2), repmat({lw}, 1, 2));
title(ax_perf_track{1,1}, 'Left' , 'FontWeight', 'bold', 'Color', C.PortL);
title(ax_perf_track{1,2}, 'Right', 'FontWeight', 'bold', 'Color', C.PortR);

% performance progress
ax_perf = obj.assign_ax_to_fig(fig_progress, 1, 2, [ax_grid{2,1} 12.5 2], ax_sz_1);
data_perf = obj.assign_data_to_ax(ax_perf, perf_sorted(sort_id, :));
draw_perf_progress(obj, ax_perf, data_perf, repmat({ls}, 1, 2), repmat({lw}, 1, 2));

% pdf heatmap of hold duration
pdf_x = obj.Bins.HD;
pdf_l = cell(1, n_s);
pdf_r = cell(1, n_s);
for i = 1:n_s
    pdf_l{i} = cellfun(@(x) x{sort_id(i),1}.f, obj.HDPDF.Session, 'UniformOutput', false);
    pdf_r{i} = cellfun(@(x) x{sort_id(i),2}.f, obj.HDPDF.Session, 'UniformOutput', false);
    pdf_l{i} = cell2mat(pdf_l{i})';
    pdf_r{i} = cell2mat(pdf_r{i})';
end

ax_heat_l = obj.assign_ax_to_fig(fig_progress, 1, n_s, [ax_grid{3,1} 6 2], ax_sz_s);
set(ax_heat_l{1}, 'YLim', [-1 1]+obj.TargetFP);
draw_heatmap(obj, ax_heat_l, pdf_l, pdf_x, obj.TargetFP(1), rw);

ax_heat_r = obj.assign_ax_to_fig(fig_progress, 1, n_s, [ax_grid{3,2} 6 2], ax_sz_s);
set(ax_heat_r{1}, 'YTickLabel', "", 'YLim', [-1 1]+sort(obj.TargetFP));
draw_heatmap(obj, ax_heat_r, pdf_r, pdf_x, obj.TargetFP(2), rw);
ylabel(ax_heat_r{1}, "");
xlabel(ax_heat_r{1}, "");

cb = colorbar(ax_heat_r{1}, 'Units', 'centimeters', 'Position', [ax_grid{3,2}+[ax_sz_1(1)+.2 0], .25, ax_sz_1(2)], ...
    'Ticks', [0 1]);
cb.Label.String = "Norm. Density";
cb.Label.FontWeight = "bold";

% pdf hold duration in early and late training phase
ax_e_l = obj.assign_ax_to_fig(fig_progress, 1, 2, [ax_grid{4,1} 12.5 2], ax_sz_1);
pdf_e_l = obj.assign_data_to_ax(ax_e_l, [obj.HDPDF.Early(sort_id,:); obj.HDPDF.Late(sort_id,:)]);
c_e_l = [repmat({C.PhaseEarly}, n_s, 1); repmat({C.PhaseLate}, n_s, 1)];
ls_e_l = repmat(ls, 1, 2);
lw_e_l = repmat(lw, 1, 2);

draw_distr(obj, ax_e_l, pdf_e_l, repmat({c_e_l}, 1, 2), repmat({ls_e_l}, 1, 2), repmat({lw_e_l}, 1, 2), obj.TargetFP, rw);

y_lim = cellfun(@(x) x.YLim(2), ax_e_l);
y_lim = max(max(y_lim));
y_lim = (ceil(y_lim) + round(y_lim)) / 2;
for i = 1:2
    ax_e_l{i}.YLim = [0 y_lim];
end

% Shuttle time
% scatter
ax_st_s = obj.assign_ax_to_fig(fig_progress, 1, 1, [ax_grid{1,3} ax_sz_1], ax_sz_1);
set(ax_st_s{1}, "YLim", [0 1], 'YTick', log10(1:10), 'YTickLabel', ["1", repmat("", 1, 8), "10"]);
ylabel(ax_st_s{1}, 'ST (s)', 'FontWeight', 'bold');
data_st = obj.assign_data_to_ax(ax_st_s, beh_sorted_st);
c_st  = repmat({[.2 .2 .2]}, 1, 1);
ms_st = repmat({8}, 1, 1);
draw_scatter(obj, ax_st_s, data_st, "TrialCentInTimeProgress", "LogST", c_st, "o", ms_st, [], []);

% violin
ax_st_v = obj.assign_ax_to_fig(fig_progress, 1, 1, [ax_grid{1,4} ax_sz_1], ax_sz_1);
data_st_v = cell(1,1);
set(ax_st_v{1}, "YLim", [0 1], 'YTick', log10(1:10), 'YTickLabel', ["1", repmat("", 1, 8), "10"]);
data_st_v{1} = cellfun(@(x) x([1 end]), obj.LogSTSplit.Session, 'UniformOutput', false);
draw_violin(obj, ax_st_v, data_st_v, obj.BandWidth, c_st, [], []);

% Movement time
% scatter
ax_mt_s = obj.assign_ax_to_fig(fig_progress, 1, n_s, [ax_grid{2,3} ax_sz_1], ax_sz_s);
for i = 1:n_s
    set(ax_mt_s{i}, "YLim", [.2 1.2], "YTick", [.2 1.2], "YTickLabel", "");
    if i==1
        ylabel(ax_mt_s{i}, 'MT (s)', 'FontWeight', 'bold');
        set(ax_mt_s{i}, "YTickLabel", ax_mt_s{i}.YLim);
    end
end
data_mt = obj.assign_data_to_ax(ax_mt_s, beh_sorted_mt(sort_id, :)');
c_mt  = repmat({[C.PortL; C.PortR]}, 1, n_s);
ms_mt = repmat({[8; 8]}, 1, n_s);
draw_scatter(obj, ax_mt_s, data_mt, "TrialCentInTimeProgress", "MT", c_mt, ["o", "x"], ms_mt, [], []);

% violin
ax_mt_v = obj.assign_ax_to_fig(fig_progress, 1, n_s, [ax_grid{2,4} ax_sz_1], ax_sz_s);
data_mt_v = cell(1,n_s);
for i = 1:n_s
    set(ax_mt_v{i}, "YLim", [.2 1.2], "YTick", [.2 1.2], "YTickLabel", "");
    data_mt_v{i} = cellfun(@(x) x(sort_id(i), :), obj.MTSorted.Session, 'UniformOutput', false);
    if i==1
        set(ax_mt_v{i}, "YTickLabel", ax_mt_v{i}.YTick);
    end
end
draw_violin(obj, ax_mt_v, data_mt_v, obj.BandWidth, c_mt, [], []);

% Hold duration
% scatter
ax_hd_s = obj.assign_ax_to_fig(fig_progress, 1, n_s, [ax_grid{3,3} ax_sz_1], ax_sz_s);
for i = 1:n_s
    set(ax_hd_s{i}, "YLim", [-1 1]+sort(obj.TargetFP), "YTick", min(obj.TargetFP)-1:1:max(obj.TargetFP)+1, "YTickLabel", "");
    if i==1
        ylabel(ax_hd_s{i}, 'HD (s)', 'FontWeight', 'bold');
        set(ax_hd_s{i}, "YTickLabel", ax_hd_s{i}.YTick);
    end
end
data_hd = obj.assign_data_to_ax(ax_hd_s, beh_sorted(sort_id, :)');
c_hd  = repmat({[C.PortL; C.PortR]}, 1, n_s);
ms_hd = repmat({[8; 8]}, 1, n_s);
draw_scatter(obj, ax_hd_s, data_hd, "TrialCentInTimeProgress", "HD", c_hd, ["o", "x"], ms_hd, obj.TargetFP, rw);

% violin
ax_hd_v = obj.assign_ax_to_fig(fig_progress, 1, n_s, [ax_grid{3,4} ax_sz_1], ax_sz_s);
data_hd_v = cell(1,n_s);
for i = 1:n_s
    set(ax_hd_v{i}, "YLim", [-1 1]+sort(obj.TargetFP), "YTick", min(obj.TargetFP)-1:1:max(obj.TargetFP)+1, "YTickLabel", "");
    data_hd_v{i} = cellfun(@(x) x(sort_id(i), :), obj.HDSorted.Session, 'UniformOutput', false);
    if i==1
        set(ax_hd_v{i}, "YTickLabel", ax_hd_v{i}.YTick);
    end
end
draw_violin(obj, ax_hd_v, data_hd_v, obj.BandWidth, c_hd, obj.TargetFP, rw);

% Hold duration statistics
stat = obj.assign_data_to_ax(cell(1,n_s), stat_sorted(sort_id, :)');
c_stat = repmat({[C.PortL; C.PortR]}, 1, n_s);
% median
ax_median = obj.assign_ax_to_fig(fig_progress, 1, n_s, [ax_grid{4,3} ax_sz_1], ax_sz_s);
for i = 1:n_s
    ax_median{i}.YLim = [-1 1] + obj.TargetFP;
end
draw_stat(obj, ax_median, stat, "Median", c_stat, ls, lw, obj.TargetFP, rw);
ylabel(ax_median{1}, "HD (s) median", 'FontWeight', 'bold');

% iqr
ax_iqr = obj.assign_ax_to_fig(fig_progress, 1, n_s, [ax_grid{4,4} ax_sz_1], ax_sz_s);
for i = 1:n_s
    ax_iqr{i}.YLim = [0 1];
end
draw_stat(obj, ax_iqr, stat, "IQR", c_stat, ls, lw, [], []);
ylabel(ax_iqr{1}, "HD (s) IQR", 'FontWeight', 'bold');

%%
end

%%
function ax_cell = draw_perf_track(obj, ax_cell, perf_track_cell, ls, lw)
session_info  = obj.DurationSession;
session_sep   = [0; cumsum(session_info)];
session_chemo = find(obj.Label=="Chemo");
sep_lesion    = find(obj.Label=="Lesion", 1);
sz_draw = size(ax_cell);
for i = 1:sz_draw(1)
    for j = 1:sz_draw(2)
        ax = ax_cell{i,j};
        set(ax, 'XLim', [0 obj.BehavTable.TrialCentInTimeProgress(end)], 'YLim', [0 100]);
        mark_sessions(ax, session_sep, session_chemo, sep_lesion);
        for k = 1:length(perf_track_cell{i,j})
            perf_track = perf_track_cell{i,j}{k};
            perf_track = obj.add_progress_info(perf_track, "Pos", session_info);
            plot_perf_track(obj, ax, perf_track, ls{i,j}(k), lw{i,j}(k))
        end

        if i==sz_draw(1) && j==1
            xlabel(ax, 'Time (s)', 'FontWeight', 'bold');
            ylabel(ax, 'Perfomance %', 'FontWeight', 'bold');
        end
        if i~=sz_draw(i)
            set(ax, 'XTickLabel', []);
        end
        if j~=1
            set(ax, 'YTickLabel', []);
        end
    end % for j = 1:sz_draw(2)
end % for i = 1:sz_draw(1)
drawnow();
end % draw_perf_track

function ax_cell = draw_perf_progress(obj, ax_cell, perf_progress, ls, lw)
session_info  = ones(obj.NumSessions, 1);
session_sep   = .5+[0; cumsum(session_info)];
session_chemo = find(obj.Label=="Chemo");
sep_lesion    = find(obj.Label=="Lesion", 1);
sz_draw = size(ax_cell);
for i = 1:sz_draw(1)
    for j = 1:sz_draw(2)
        ax = ax_cell{i,j};
        set(ax, 'XLim', .5+[0 obj.NumSessions], 'YLim', [0 100], 'XTick', 0:5:obj.NumSessions);
        mark_sessions(ax, session_sep, session_chemo, sep_lesion);
        for k = 1:length(perf_progress{i,j})
            plot_perf_progress(obj, ax, perf_progress{i,j}{k}, ls{i,j}(k), lw{i,j}(k))
        end

        if i==sz_draw(1) && j==1
            xlabel(ax, 'Session', 'FontWeight', 'bold');
            ylabel(ax, 'Perfomance %', 'FontWeight', 'bold');
        end
        if i~=sz_draw(i)
            set(ax, 'XTickLabel', []);
        end
        if j~=1
            set(ax, 'YTickLabel', []);
        end
    end % for j = 1:sz_draw(2)
end % for i = 1:sz_draw(1)
drawnow();
end % draw_perf_progress

function draw_heatmap(obj, ax_cell, pd_f, pd_x, fp, rw)
session_info  = ones(obj.NumSessions, 1);
session_chemo = find(obj.Label=="Chemo");
sep_lesion    = find(obj.Label=="Lesion", 1);
sz_draw = size(ax_cell);
for i = 1:sz_draw(1)
    for j = 1:sz_draw(2)
        ax = ax_cell{i,j};
        set(ax, 'YDir', 'normal', ...
            'XLim', .5+[0 obj.NumSessions], 'XTick', 0:5:obj.NumSessions);
        pd_this = normalize(pd_f{i,j}(:), 'range');
        pd_this = reshape(pd_this, size(pd_f{i,j}));
        imagesc(ax, 1:obj.NumSessions, pd_x, pd_this);
        
        for k = 1:length(session_chemo)
            fill(ax, [-.5 -.5 .5 .5]+session_chemo(k), [ax.YLim flip(ax.YLim)], 'r', ...
                'FaceColor', 'none', 'EdgeColor', GPSColor.Treat, 'LineWidth', 1.5, 'LineStyle', ':');
        end
        if ~isempty(sep_lesion)
            xline(ax, sep_lesion, 'LineWidth', 1.5, 'Color', [1 1 1]);
        end
        
        if ~isempty(fp)
            yline(ax, fp, 'Color', [1 1 1], 'LineWidth', .5, 'LineStyle', '-', 'Alpha', .7);
            yline(ax, fp+rw(j), 'Color', [1 1 1], 'LineWidth', .5, 'LineStyle', ':', 'Alpha', .7);
        end

        if i==sz_draw(1) && j==1
            xlabel(ax, 'Session', 'FontWeight', 'bold');
            ylabel(ax, 'HD (s)', 'FontWeight', 'bold');
        end
        if i~=sz_draw(i)
            set(ax, 'XTickLabel', []);
        end
        if j~=1
            set(ax, 'YTickLabel', []);
        end
    end % for j = 1:sz_draw(2)
end % for i = 1:sz_draw(1)
drawnow();
end % draw_heatmap

function draw_distr(obj, ax_cell, data_cell, c, ls, lw, fp, rw)
sz_draw = size(ax_cell);
for i = 1:sz_draw(1)
    for j = 1:sz_draw(2)
        ax = ax_cell{i,j};
        set(ax, 'XLim', [0 3]);
        
        obj.plot_distr(ax, data_cell{i,j}, 'Color', c{i,j}, 'LineStyle', ls{i,j}, 'LineWidth', lw{i,j});
        
        if ~isempty(fp)
            xline(ax, fp(j), 'Color', [.2 .2 .2], 'LineWidth', .5, 'LineStyle', '-', 'Alpha', .7);
            xline(ax, fp(j)+rw, 'Color', [.2 .2 .2], 'LineWidth', .5, 'LineStyle', ':', 'Alpha', .7);
        end

        if i==sz_draw(1) && j==1
            xlabel(ax, 'HD (s)', 'FontWeight', 'bold');
            ylabel(ax, 'Density (1/s)', 'FontWeight', 'bold');
        end
        if i~=sz_draw(i)
            set(ax, 'XTickLabel', []);
        end
        if j~=1
            set(ax, 'YTickLabel', []);
        end
    end % for j = 1:sz_draw(2)
end % for i = 1:sz_draw(1)
drawnow();
end % draw_distr

function draw_scatter(obj, ax_cell, beh_cell, var_x, var_y, c, mk, mk_sz, fp, rw)
session_info  = obj.DurationSession;
session_sep   = [0; cumsum(session_info)];
session_chemo = find(obj.Label=="Chemo");
sep_lesion    = find(obj.Label=="Lesion", 1);
sz_draw = size(ax_cell);
for i = 1:sz_draw(1)
    for j = 1:sz_draw(2)
        ax = ax_cell{i,j};
        mark_sessions(ax, session_sep, session_chemo, sep_lesion);
        if ~isempty(fp)
            yline(ax, fp, 'LineWidth', .5, 'LineStyle', '-', 'Alpha', .5);
            yline(ax, fp+rw(j), 'LineWidth', .5, 'LineStyle', ':', 'Alpha', .5);
        end
        plot_scatter(ax, beh_cell{i,j}, var_x, var_y, c{i,j}, mk, mk_sz{i,j});
        set(ax, 'XLim', [0 obj.BehavTable.TrialCentInTimeProgress(end)]);

        if i==sz_draw(1) && j==1
            xlabel(ax, 'Time (s)', 'FontWeight', 'bold');
        end
        if i~=sz_draw(i)
            set(ax, 'XTickLabel', []);
        end
        if j~=1
            set(ax, 'YTickLabel', []);
        end
    end % for j = 1:sz_draw(2)
end % for i = 1:sz_draw(1)
drawnow();
end % draw_scatter

function draw_violin(obj, ax_cell, data, band_width, c, fp, rw)
session_info  = ones(obj.NumSessions, 1);
session_sep   = .5+[0; cumsum(session_info)];
session_chemo = find(obj.Label=="Chemo");
sep_lesion    = find(obj.Label=="Lesion", 1);
sz_draw = size(ax_cell);
for i = 1:sz_draw(1)
    for j = 1:sz_draw(2)
        ax = ax_cell{i,j};
        mark_sessions(ax, session_sep, session_chemo, sep_lesion);
        if ~isempty(fp)
            yline(ax, fp, 'LineWidth', .5, 'LineStyle', '-', 'Alpha', .5);
            yline(ax, fp+rw(j), 'LineWidth', .5, 'LineStyle', ':', 'Alpha', .5);
        end
        data_this = data{i,j};
        data_1 = cellfun(@(x) x{1}, data_this, 'UniformOutput', false);
        data_2 = cellfun(@(x) x{2}, data_this, 'UniformOutput', false);
        c_this = mat2cell(c{i,j}, ones(size(c{i,j}, 1), 1));
        obj.plot_violin_compare(ax, data_1, data_2, band_width, 'Color', c_this, 'ShowMedian', false)
        set(ax, 'XLim', .5 + [0 obj.NumSessions], 'XTick', 0:5:obj.NumSessions, 'XTickLabel', 0:5:obj.NumSessions);

        if i==sz_draw(1) && j==1
            xlabel(ax, 'Session', 'FontWeight', 'bold');
        end
        if i~=sz_draw(i)
            set(ax, 'XTickLabel', []);
        end
        if j~=1
            set(ax, 'YTickLabel', []);
        end
    end % for j = 1:sz_draw(2)
end % for i = 1:sz_draw(1)
drawnow();
end % draw_violin

function draw_stat(obj, ax_cell, stat_cell, variable, c, ls, lw, fp, rw)
session_info  = ones(obj.NumSessions, 1);
session_sep   = .5+[0; cumsum(session_info)];
session_chemo = find(obj.Label=="Chemo");
sep_lesion    = find(obj.Label=="Lesion", 1);
sz_draw = size(ax_cell);

for i = 1:sz_draw(1)
    for j = 1:sz_draw(2)
        ax = ax_cell{i,j};
        mark_sessions(ax, session_sep, session_chemo, sep_lesion);
        if ~isempty(fp)
            yline(ax, fp, 'LineWidth', .5, 'LineStyle', '-', 'Alpha', .5);
            yline(ax, fp+rw(j), 'LineWidth', .5, 'LineStyle', ':', 'Alpha', .5);
        end
            
        stat_this = stat_cell{i,j};
        for k = 1:length(stat_this)
            plot_stat(ax, stat_this{k}, variable, c{i,j}(k,:), ls(i,j), lw(i,j))
        end
        
        set(ax, 'XLim', .5 + [0 obj.NumSessions], 'XTick', 0:5:obj.NumSessions, 'XTickLabel', 0:5:obj.NumSessions);

        if i==sz_draw(1) && j==1
            xlabel(ax, 'Session', 'FontWeight', 'bold');
        end
        if i~=sz_draw(i)
            set(ax, 'XTickLabel', []);
        end
        if j~=1
            set(ax, 'YTickLabel', []);
        end
    end % for j = 1:sz_draw(2)
end % for i = 1:sz_draw(1)
drawnow();
end % draw_stat

%% Plot functions
function plot_perf_track(obj, ax, perf_track, ls, lw)
sessions = unique(perf_track.Session, "stable");
for i = 1:length(sessions)
    ind_this = perf_track.Session == sessions(i);
    track_this = perf_track(ind_this, :);
    for j = 1:length(obj.PerformanceType)
        perf_this = obj.PerformanceType(j);
        plot(ax, track_this.PosProgress, 100*track_this.(perf_this), ...
            'LineStyle', ls, 'LineWidth', lw, 'Color', GPSColor.(perf_this));
    end
end
end % plot_perf_track

function plot_perf_progress(obj, ax, perf, ls, lw)
for i = 1:length(obj.PerformanceType)
    perf_this = obj.PerformanceType(i);
    plot(ax, 1:obj.NumSessions, 100*perf.(perf_this), ...
        'LineStyle', ls, 'LineWidth', lw, 'Color', GPSColor.(perf_this), ...
        'Marker', 'o', 'MarkerSize', 4, 'MarkerFaceColor', GPSColor.(perf_this), 'MarkerEdgeColor', 'w');
end
end % plot_perf_progress

function plot_scatter(ax, beh, var_x, var_y, c, mk, mk_sz)
n_beh = cellfun(@height, beh);
beh_this = vertcat(beh{:});

x_this = beh_this.(var_x);
y_this = beh_this.(var_y);
o_this = beh_this.Outcome;

c_this  = zeros(sum(n_beh), 3);
ms_this = zeros(sum(n_beh), 1);
count_1 = 1;
for i = 1:length(n_beh)
    count_2 = count_1+n_beh(i)-1;
    c_this(count_1:count_2, :) = repmat(c(i, :), n_beh(i), 1);
    ms_this(count_1:count_2)   = repmat(mk_sz(i), n_beh(i), 1);
    count_1 = count_2 + 1;
end
[x, id] = sort(x_this);
y = y_this(id);
o = o_this(id);
c = c_this(id,:);
ms = ms_this(id);

if length(mk)==1
    scatter(ax, x, y, ms, c, 'filled', 'MarkerFaceAlpha', .6);
elseif length(mk)==2
    id_c = o=="Correct";
    scatter(ax, x(id_c) , y(id_c) , ms(id_c) , c(id_c,:) , mk(1), 'filled', 'MarkerFaceAlpha', .6);
    scatter(ax, x(~id_c), y(~id_c), ms(~id_c), c(~id_c,:), mk(2), 'MarkerEdgeAlpha', .6);
end
end % plot_scatter

function plot_stat(ax, stat, variable, c, ls, lw)
stat_vars = string(stat.Properties.VariableNames);
if ismember(variable, stat_vars)
    var_this = stat.(variable);
    plot(ax, 1:length(var_this), var_this, 'Color', c, 'LineStyle', ls, 'LineWidth', lw);
    if ismember([variable+"_ci_u", variable+"_ci_l"], stat_vars)
        ci_u = stat.(variable+"_ci_u");
        ci_l = stat.(variable+"_ci_l");
        for i = 1:length(var_this)
            plot(ax, [i i], [ci_l(i) ci_u(i)], 'Color', c, 'LineWidth', lw);
        end
    end
end
end % plot_stat

%% Marking sessions
function mark_sessions(ax, session_sep, session_chemo, sep_lesion)
xline(ax, session_sep(2:end-1), 'LineWidth', .5, 'LineStyle', '-', 'Color', [.7 .7 .7], 'Alpha', .7);

if ~isempty(session_chemo)
    for k = 1:length(session_chemo)
        s_this = session_sep([0 1] + session_chemo(k));
        fill(ax, [s_this(1) s_this(2) s_this(2) s_this(1)], [ax.YLim(1) ax.YLim(1) ax.YLim(2) ax.YLim(2)], 'r', ...
            'FaceColor', GPSColor.Treat, 'FaceAlpha', .2, 'EdgeColor', 'none');
    end
end
if ~isempty(sep_lesion)
    xline(ax, session_sep(sep_lesion), 'LineWidth', 1.5, 'LineStyle', '-', 'Color', [0 0 0], 'Alpha', .7);
end
end % mark_sessions