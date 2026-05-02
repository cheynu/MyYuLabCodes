function fig = plotTrajSession(obj)

FP_zone = [zeros(3,1) 1000*flip(obj.TargetFP(1:3)')];
FP_zone = mat2cell(FP_zone, ones(3,1));

info = obj.TrialInfo;
sort_refs = {info.FP, info.PortCorrect};
sort_code = {flip(obj.TargetFP(1:3)), obj.LeftRight};

time_sorted = obj.sort_data(obj.TimeFromIn, sort_refs, sort_code);
ang_sorted  = obj.sort_data(obj.AngleHead, sort_refs, sort_code);
posx_sorted = obj.sort_data(obj.PosXHead, sort_refs, sort_code);
posy_sorted = obj.sort_data(obj.PosYHead, sort_refs, sort_code);

%%
plt = GPSPlot();

ax_sz = [3 2];
lw = 1.5;
ls = "-";
alpha = 0.15;
x_lim = [-100 2000];

color_cell = repmat({{GPSColor.PortL, GPSColor.PortR}}, 3, 1);
lw_cell = repmat({{lw}}, 3, 2);
ls_cell = repmat({{ls}}, 3, 2);

%%
fig = figure(11); clf(fig);
set(fig, 'Visible', 'on', 'Units', 'centimeters', 'Position', [5 5 16 9], 'Color', 'w', 'toolbar', 'none');

fig_title = sprintf("%s / %s / %s / %s", obj.Subject, obj.Session, obj.Protocol, obj.Label);
set_fig_title(fig, fig_title);

% angle head
ax_ang   = plt.assign_ax_to_fig(fig, 3, 1, [1.5 1 4 7], ax_sz);
time_ang = plt.assign_data_to_ax(ax_ang, time_sorted);
data_ang = plt.assign_data_to_ax(ax_ang, ang_sorted);
ax_ang   = draw_trace_multi(obj, ax_ang, time_ang, data_ang, color_cell, lw_cell, ls_cell, alpha);

y_lim_ang_1 = floor(min(cellfun(@(ax) ax.YLim(1), ax_ang)));
y_lim_ang_2 = ceil(max(cellfun(@(ax) ax.YLim(2), ax_ang)));
cellfun(@(x) set(x, 'XLim', x_lim, 'YLim', [y_lim_ang_1 y_lim_ang_2]), ax_ang);
cellfun(@(x, fp) plt.add_shade(x, fp, 'alpha', .1), ax_ang, FP_zone);

for i = 1:2
    set(ax_ang{i}, 'YColor', 'none', 'XColor', 'none');
end
xlabel(ax_ang{3}, "Time from cent-in (ms)", 'FontWeight', 'bold');
ylabel(ax_ang{3}, "Head angle (°)", 'FontWeight', 'bold');

% pos-x head
ax_posx   = plt.assign_ax_to_fig(fig, 3, 1, [6.5 1 4 7], ax_sz);
time_posx = plt.assign_data_to_ax(ax_posx, time_sorted);
data_posx = plt.assign_data_to_ax(ax_posx, posx_sorted);
ax_posx   = draw_trace_multi(obj, ax_posx, time_posx, data_posx, color_cell, lw_cell, ls_cell, alpha);

y_lim_posx_1 = floor(min(cellfun(@(ax) ax.YLim(1), ax_posx)));
y_lim_posx_2 = ceil(max(cellfun(@(ax) ax.YLim(2), ax_posx)));
cellfun(@(x) set(x, 'XLim', x_lim, 'YLim', [y_lim_posx_1 y_lim_posx_2]), ax_posx);
cellfun(@(x, fp) plt.add_shade(x, fp, 'alpha', .1), ax_posx, FP_zone);

for i = 1:2
    set(ax_posx{i}, 'YColor', 'none', 'XColor', 'none');
end
ylabel(ax_posx{3}, "Head pos-X (pix)", 'FontWeight', 'bold');

% pos-y head
ax_posy   = plt.assign_ax_to_fig(fig, 3, 1, [11.5 1 4 7], ax_sz);
time_posy = plt.assign_data_to_ax(ax_posy, time_sorted);
data_posy = plt.assign_data_to_ax(ax_posy, posy_sorted);
ax_posy   = draw_trace_multi(obj, ax_posy, time_posy, data_posy, color_cell, lw_cell, ls_cell, alpha);

y_lim_posy_1 = floor(min(cellfun(@(ax) ax.YLim(1), ax_posy)));
y_lim_posy_2 = ceil(max(cellfun(@(ax) ax.YLim(2), ax_posy)));
cellfun(@(x) set(x, 'XLim', x_lim, 'YLim', [y_lim_posy_1 y_lim_posy_2]), ax_posy);
cellfun(@(x, fp) plt.add_shade(x, fp, 'alpha', .1), ax_posy, FP_zone);

for i = 1:2
    set(ax_posy{i}, 'YColor', 'none', 'XColor', 'none');
end
ylabel(ax_posy{3}, "Head pos-Y (pix)", 'FontWeight', 'bold');

end % plotTrajSession

function ax_cell = draw_trace_multi(obj, ax_cell, time_cell, trace_cell, color_cell, lw_cell, ls_cell, alpha)

[n_row, n_col] = size(ax_cell);
for i = 1:n_row
    for j = 1:n_col
        ax_now = ax_cell{i,j};
        time_now = time_cell{i,j};
        trace_now = trace_cell{i,j};
        color_now = color_cell{i,j};
        lw_now = lw_cell{i,j};
        ls_now = ls_cell{i,j};

        ax_cell{i,j} = obj.plot_trace_multi(ax_now, time_now, trace_now, 'color', color_now, 'lw', lw_now, 'ls', ls_now, 'alpha', alpha);
    end
end

end % draw_trace_multi