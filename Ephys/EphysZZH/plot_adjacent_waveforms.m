function wave_form = plot_adjacent_waveforms(ax, r, ku)
%PLOT_ADJACENT_WAVEFORMS Plot waveforms of adjacent channels (for neuropixels 1.0/2.0, assigned by channel location)
%

wave_form = r.Units.SpikeTimes(ku).wave_mean / 4;
n_sample = size(wave_form, 2); % sample size per spike

chs = 1:size(wave_form, 1);
ch_largest = r.Units.SpikeNotes(ku,1);

ch_map  = r.ChanMap.chanMap;
kcoords = r.ChanMap.kcoords;
k_this  = kcoords(ch_map==ch_largest);
ind_k   = kcoords==k_this;

chs     = chs(ind_k);
ch_map  = ch_map(ind_k);
xcoords = r.ChanMap.xcoords(ind_k);
ycoords = r.ChanMap.ycoords(ind_k);

x_id = (xcoords-min(xcoords)) / unique(diff(unique(xcoords)));
y_id = (ycoords-min(ycoords)) / unique(diff(unique(ycoords)));

n_x = length(unique(x_id));

x_id_0 = x_id(ch_map==ch_largest);
y_id_0 = y_id(ch_map==ch_largest);

switch n_x
    case 4 % NP1.0
        h_sep = n_sample;
        v_sep = 100;
        if ch_largest < 16
            ch_selected = 1:32;
            id_show = ch_selected;
        elseif ch_largest > size(wave_form, 1)-16
            ch_selected = (-31:0) + size(wave_form, 1);
            id_show = ch_selected;
        else
            if x_id_0 <= 2
                id_show = y_id>=y_id_0-8 & y_id<=y_id_0+7;
            else
                id_show = y_id>=y_id_0-7 & y_id<=y_id_0+8;
            end
            ch_selected = chs(id_show);
        end
    case 2 % NP2.0
        h_sep = 1.5*n_sample;
        v_sep = 60;
        if y_id_0 < 6
            id_show = y_id<=10;
            ch_selected = chs(id_show);
        elseif y_id_0 > max(y_id)-5
            id_show = y_id>=max(y_id)-9;
            ch_selected = chs(id_show);
        else
            if x_id_0==1
                id_show = y_id>=y_id_0-5 & y_id<=y_id_0+4;
            else
                id_show = y_id>=y_id_0-4 & y_id<=y_id_0+5;
            end
            ch_selected = chs(id_show);
        end
end
n_chs = length(ch_selected);
wave_form = wave_form(ch_selected, :);

x_id = x_id(id_show);
y_id = y_id(id_show);
x_loc = (x_id-min(x_id)) * h_sep;
y_loc = (y_id-min(y_id)) * v_sep;
ind_largest = find(x_id==x_id_0 & y_id==y_id_0);

max_x = 0;
colors = [25 167 206] / 255;

t_wave_all = [];
wave_all = [];
for i = 1:n_chs
    if x_id(i)==0
        text(-1, y_loc(i), string(ch_selected(i)), 'FontSize', 6, 'HorizontalAlignment', 'right');
    end

    if i==ind_largest
        continue
    end
    wave_k = wave_form(i, :) + y_loc(i);
    t_wave = (1:n_sample) + x_loc(i);

    t_wave_all = [t_wave_all, t_wave, NaN];
    wave_all = [wave_all, wave_k, NaN];
    max_x = max([max_x, max(t_wave)]);
end
plot(ax, t_wave_all, wave_all, 'linewidth', 1, 'color', colors);
plot(ax, (1:n_sample) + x_loc(ind_largest), wave_form(ind_largest, :) + y_loc(ind_largest), 'linewidth', 1, 'color', .7*colors);

switch n_x
    case 4
        set(ax, 'xlim', [0 max_x], 'ylim', [-400 v_sep*16+200]);
    case 2
        set(ax, 'xlim', [0 max_x], 'ylim', [-400 v_sep*10+200]);
end

axis off
axis tight

end