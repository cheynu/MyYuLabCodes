function [units_selected, out] = rank_units_selected(r, units_selected)

% Jianing Yu Feb25,2026 for the app: track_kinematics.mlapp
% units_selected is a n x 2 matrix, the first column is channel number, the
% second column is unit number
% 
%    280     1
%    274     1
%    271     1
%    268     1
%     21     1
%  ...

unit_table = table();
unit_table.ch = units_selected(:, 1);
unit_table.unit = units_selected(:, 2);

cell_units = cell(size(units_selected, 1), 1);
for i = 1:size(units_selected, 1)
    cell_units{i} = sprintf('%s_%s_Ch%d_Unit%d', r.BehaviorClass.Subject, r.BehaviorClass.Date, units_selected(i, 1), units_selected(i, 2));
end
unit_table.cell_id = cell_units;

sdfs_units = cell(height(unit_table), 1);
event_index = [];
norm_factor = 4;
crossing_times = zeros(1, height(unit_table));
n_nan = 10;

t_range_events = struct( ...
    'press', [-2000 500],...
    'trigger', [-250 500],...
    'release_correct', [-250 500],...
    'poke', [-1000 1000]);
events = {'press', 'trigger', 'release_correct', 'poke'};

data_folder = fullfile(pwd, 'Data', 'Processed', 'SDFs');
if ~exist(data_folder, 'dir')
    mkdir(data_folder);
end

for i =1:height(unit_table)

    % ---- file check ----
    fname = fullfile(data_folder, ...
        ['sdf_events_' unit_table.cell_id{i} '.mat']);

    if exist(fname,'file')
        load(fname); % this loads s
    else
        % ---- compute ----
        s = Spikes.SRT.rSDF26(r, ...
            [unit_table.ch(i), unit_table.unit(i)]);
        % ---- remove sdfs_trials to save space ----
        s = rmfield(s, 'sdfs_trials');
        save(fname, 's', '-v7.3');
    end

    sdf_conc = [];
    t_conc = [];

    for j = 1:numel(events)

        t = s.sdfs_event.(events{j}).data.t;
        jsdf = s.sdfs_event.(events{j}).data.mean;
        t_range = t_range_events.(events{j});
        ind_range = find(t>=t_range(1) & t<=t_range(2));

        if j<numel(events)
            sdf_conc = [sdf_conc jsdf(ind_range) NaN(1, n_nan)];
            t_conc = [t_conc t(ind_range) NaN(1, n_nan)];
        else
            sdf_conc = [sdf_conc jsdf(ind_range)];
            t_conc = [t_conc t(ind_range)];
        end
    end
    sdf_conc_norm = (sdf_conc-mean(sdf_conc, 'omitnan'))/(range(sdf_conc)+norm_factor);
    crossing_times(i) = find(sdf_conc_norm>0.75*max(sdf_conc_norm), 1, 'first');
    if isempty(event_index)
        event_index = find(t_conc == 0);
    end
    sdfs_units{i} = sdf_conc_norm;

end

[~, ind] = sort(crossing_times);
sdfs_units = sdfs_units(ind);
sdfs_units = cell2mat(sdfs_units);

time = (1:size(sdfs_units, 2)); % in ms
event_markers = time(event_index);

units_selected = units_selected(ind, :);
unit_table = unit_table(ind, :);

out.sdfs = sdfs_units;
out.t_sdfs = t_conc;
out.t_single = time;
out.event_markers = event_markers;
out.events = events;
out.unit_table = unit_table;
