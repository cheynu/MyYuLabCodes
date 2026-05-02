function DataOut = MapTrajectorySpikes(sdf_unit, TrajTableAll, TimeStamp, video_path, save_fig_path)
% revised: 2024.09.02 (from PlotTrajectorySpikes_v3)
% use most recent version of sdf_unit which comes from Spikes.SRT.rPSTHWarped(r, [channel, unit])
% removed some variables that are included in sdf_unit

% video_path = fullfile(pwd, 'Data/');
% TimeStamp = '182295';
top_vid_name = ['Top_Press_' TimeStamp '.mp4'];
top_vid_meta = ['Top_Press_' TimeStamp '.mat'];
side_vid_name = ['Side_Press_' TimeStamp '.mp4'];
side_vid_meta = ['Side_Press_' TimeStamp '.mat'];

% If both side and top trajectories are available, use both of them.
if length(TrajTableAll)>1
    traj_table.top = TrajTableAll{1};
    traj_table.side = TrajTableAll{2};
    top = 1;
    side = 1;
else
    traj_table.top = TrajTableAll{1};
    traj_table.side = [];
    top = 1;
    side = 0;
end

if top
    top_meta_file = load(fullfile(video_path, top_vid_meta));
else
    top_meta_file =[];
end

if side
    side_meta_file = load(fullfile(video_path, side_vid_meta));
else
    side_meta_file =[];
end

t_toPress = 200; % 500 ms before presds
% Create VideoReader object
vidObj = struct('top', [], 'side', []);
bin_size.top = 25;
bin_size.side = 25;
% conversion: 10.3.2025 update
% - box7 side: 6cm = 450 pixels
% - box7 top : 10cm = 250 pixels

DataOut = struct();
% start a structure to save product
DataOut.cell_id = sdf_unit.unit.cell_id; % this is in the format of ANM_Session_Ch_Unit
DataOut.table = TrajTableAll;
DataOut.example = TimeStamp;

if top
    top_vid_file = fullfile(video_path, top_vid_name);
    vidObj.top = VideoReader(top_vid_file);
    ind = find(top_meta_file.VideoInfo.EphysTimeStamps<top_meta_file.VideoInfo.Time-t_toPress, 1, 'last');
    % Frame index to extract
    frame_index = ind;
    % Read and extract the 100th frame
    vidObj.top.CurrentTime = (frame_index - 1) / vidObj.top.FrameRate; % Convert frame index to time
    frame.top = readFrame(vidObj.top);
    frame_size.top = size(frame.top);
    xrange.top = [0 frame_size.top(2)];
    yrange.top = [0 frame_size.top(1)];
    % Create edges for grid bins (top)
    xBinEdges.top = linspace(0, frame_size.top(2), frame_size.top(2)/bin_size.top);
    % Create edges for grid bins (top)
    yBinEdges.top = linspace(0, frame_size.top(1), frame_size.top(1)/bin_size.top);
    DataOut.video_file.top = fullfile(video_path, top_vid_name);
    DataOut.video_meta.top = fullfile(video_path, top_vid_meta);    
end

if side
    side_vid_file = fullfile(video_path, side_vid_name);
    vidObj.side = VideoReader(side_vid_file);
    ind = find(side_meta_file.VideoInfo.EphysTimeStamps<side_meta_file.VideoInfo.Time-t_toPress, 1, 'last');
    % Frame index to extract
    frame_index = ind;
    % Read and extract the 100th frame
    vidObj.side.CurrentTime = (frame_index - 1) / vidObj.side.FrameRate; % Convert frame index to time
    frame.side = readFrame(vidObj.side);
    frame_size.side = size(frame.side);
    xrange.side = [0 frame_size.side(2)];
    yrange.side = [0 frame_size.side(1)];
    % Create edges for grid bins (top)
    xBinEdges.side = linspace(0, frame_size.side(2), frame_size.side(2)/bin_size.side);
    % Create edges for grid bins (top)
    yBinEdges.side = linspace(0, frame_size.side(1), frame_size.side(1)/bin_size.side);
    DataOut.video_file.side = fullfile(video_path, side_vid_name);
    DataOut.video_meta.side = fullfile(video_path, side_vid_meta);
end

DataOut.x_range = xrange;
DataOut.y_range = yrange;
DataOut.x_bins = xBinEdges;
DataOut.y_bins = yBinEdges;
DataOut.this_sdf        = sdf_unit; % lots of infomration

% Get event time
nFP = length(sdf_unit.raster.press);
FPs = sdf_unit.FPs;
event_times = [];
spike_trains = {};

for i =1:nFP
    raster = sdf_unit.raster.press{i};
    for j =1:length(raster)
        event_times = [event_times; sdf_unit.raster.eventSequence{i}(j,:) FPs(i)];
        if isempty(sdf_unit.raster.press{i}{j})
            spike_trains =[spike_trains {'NaN'}];
        else
            spike_trains = [spike_trains {sdf_unit.raster.press{i}{j}}];
        end
    end
end

event_table = sdf_unit.events; % this is a newly-added feature of rPSTHWarped. 
% Data preparation
spk_train = sdf_unit.unit.times;
t_range = [min(spk_train)-1000 max(spk_train)+1000];
sigma_kernel = 50;
dt = 1;
[sdf_org, t_sdf]   =  sdf25(spk_train, t_range, sigma_kernel, dt);  %  spkout=sdf(tspk, spkin, kernel_width

DataOut.sdf = [t_sdf' sdf_org'];
view_angles = {'top', 'side'};
types = {'before', 'after'};
traj_rate        = struct('all', [], 'mean', []);
tPre_Press = -2500/1000;
tPost_Press = 500/1000;

table_temp = table;
k = 0;
for i =1:length(view_angles)
    angle = view_angles{i};
    if strcmp(angle, 'side')
        properties = traj_table.(view_angles{i}).Properties.VariableNames;
        if any(strcmp(properties, 'x_LeftPaw'))
            traj_table.(view_angles{i}).x = traj_table.(view_angles{i}).x_LeftPaw;
            traj_table.(view_angles{i}).y = traj_table.(view_angles{i}).y_LeftPaw;
        end
        if any(strcmp(properties, 'x_RightPaw'))
            traj_table.(view_angles{i}).x = traj_table.(view_angles{i}).x_RightPaw;
            traj_table.(view_angles{i}).y = traj_table.(view_angles{i}).y_RightPaw;
        end

    end

    if eval([angle '==1'])
        trial_names = unique(traj_table.(view_angles{i}).Source); % top view trajectories
        % this really is just the topview map
        trial_struct = struct('name', [], 't_press', [], 'index', [], 'table', [], ...
            'x', [], 'y', [], 'time', [], 'sdf', [], 't_spikes',[], ...
            'time_relative', [], 't_spikes_relative', [], 'is_before', [], 'rate_map', [], 'sdf_integral', [], 'occupancy', []);
        Trials = repmat(trial_struct, 1, length(trial_names));
        x_bins = xBinEdges.(angle);
        y_bins = yBinEdges.(angle);

        rate_maps.before = []; % fixed 10.12.2025
        rate_maps.after = [];

        traj_maps.before = cell(1,  length(trial_names));
        traj_maps.after = cell(1,  length(trial_names));

        for iTrial = 1:length(trial_names)
            this_trial                  =   trial_names{iTrial};
            % this is the press time
            t_press                     =   str2double(regexp(this_trial, '\d+', 'match'));

            Trials(iTrial).name         =   this_trial;
            Trials(iTrial).t_press      =   t_press;
            % t_triggers = event_table.t_trigger;
            % t_release = event_table.t_release;
            % FPs_behavior = event_table.FP;

            [min_dis, ind_row] = min(abs(event_table.t_press-t_press));
            if min_dis<20
                Trials(iTrial).t_trigger = event_table.t_press(ind_row);
                Trials(iTrial).t_trigger = event_table.t_trigger(ind_row);
                Trials(iTrial).t_release = event_table.t_release(ind_row);
                Trials(iTrial).t_poke = event_table.t_poke(ind_row);
                Trials(iTrial).FP = event_table.FP(ind_row);
            else
                continue
            end

            if strcmp(num2str(t_press), TimeStamp)
                Trials(iTrial).example = 1;
            else
                Trials(iTrial).example = 0;
            end

            Trials(iTrial).index        =   strcmp(traj_table.(angle).Source, this_trial);
            Trials(iTrial).table        =   traj_table.(angle)(strcmp(traj_table.(angle).Source, this_trial), :);
            Trials(iTrial).x            =   Trials(iTrial).table.x;
            Trials(iTrial).y            =   Trials(iTrial).table.y;            
            Trials(iTrial).time         =   Trials(iTrial).table.Time;
            Trials(iTrial).sdf          =   interp1(t_sdf, sdf_org, Trials(iTrial).time, 'linear', 0);
            % spike times of this trial
            Trials(iTrial).t_spikes     =   spk_train(spk_train>=Trials(iTrial).time(1) & spk_train<=Trials(iTrial).time(end));
            % normalized to the press time (so it is 0)
            Trials(iTrial).time_relative         =   Trials(iTrial).table.Time-t_press;
            % spike times of this trial
            Trials(iTrial).t_spikes_relative     =    Trials(iTrial).t_spikes-t_press;
            Trials(iTrial).is_before             =   Trials(iTrial).time_relative<=0;
            % index before and after press time
            ind_press.before    =   find(Trials(iTrial).time_relative<=0);
            
            % after is defined from near the trigger time to the rest of the
            % trial
            t_backtrack = 100;
            if isfield(Trials(iTrial), 't_trigger')
                ind_press.after     =   find(Trials(iTrial).time_relative>(Trials(iTrial).t_trigger-Trials(iTrial).t_press-t_backtrack));
            else
                ind_press.after     =   [];
            end

            for j = 1:length(types)
                type = types{j};
                % Map spike rate to a pixel
                if ~isempty(ind_press.(type))
                    t_spikes = Trials(iTrial).t_spikes_relative;
                    t = Trials(iTrial).time_relative(ind_press.(type));
                    sdf_in = Trials(iTrial).sdf(ind_press.(type));
                    t_traj =  Trials(iTrial).time_relative(ind_press.(type));
                    t_spikes = t_spikes(t_spikes>=min(t_traj(1)) & t_spikes<=max(t_traj(end)));
                    x_traj =  Trials(iTrial).x(ind_press.(type));
                    y_traj =  Trials(iTrial).y(ind_press.(type));
                    ind = find(t_traj>=tPre_Press*1000);
                    t_traj= t_traj(ind);
                    x_traj= x_traj(ind);
                    y_traj= y_traj(ind);
                    traj_maps.(type){iTrial} = [t_traj x_traj y_traj];
                    % compute map from a single trial
                    % [rate_map, isvalid, this_integral, occupancy_time] = map_spike_to_pixels(t, sdf_in, t_traj, x_traj, y_traj, x_bins, y_bins)

                    [rate_map_p, isvalid_p, sdf_integral, occupancy] = Spikes.Videos.map_spike_to_pixels(t, sdf_in, ...
                        t_traj, x_traj, y_traj, x_bins, y_bins);

                    Trials(iTrial).rate_map.(type) = rate_map_p;
                    Trials(iTrial).valid_index.(type) = isvalid_p;
                    Trials(iTrial).sdf_integral.(type) = sdf_integral;
                    Trials(iTrial).occupancy.(type) = occupancy;

                    Trials(iTrial).valid_index.(type).spike_times = t_spikes;
                    Trials(iTrial).rate_map.coords = {x_bins, y_bins};
                    rate_maps.(type) = cat(3, rate_maps.(type), Trials(iTrial).rate_map.(type));

                    if strcmp(type, 'after') && strcmp(angle, 'top')
                        % this_row = table(Trials(iTrial).t_press, t_traj(end), Trials(iTrial).t_poke-Trials(iTrial).t_press,...
                        %     'VariableNames', {'PressIndex', 'FinalTrackingPoint', 'PokeTime'});
                        % table_temp = [table_temp; this_row];
                        % sprintf('Trial is: %2.2f, \nLast tracked point is %2.2f, \npoke time is %2.2f', Trials(iTrial).t_press, t_traj(end), Trials(iTrial).t_poke-Trials(iTrial).t_press)
                        %
                    end
                end
            end
        end

        traj_rate.all.(angle) = Trials;
        if strcmp(angle, 'top')

            if true
                slopes = zeros(1, length(Trials));
                for trial =1:length(Trials)
                    if ~isfield(Trials(trial).valid_index, 'before')
                        slopes(trial) = NaN;
                        continue
                    end
                    xfit = Trials(trial).valid_index.before.t;
                    yfit = Trials(trial).valid_index.before.x;
                    if any(isnan(xfit)) || any(isnan(yfit)) || max(yfit)-min(yfit)<250
                        slopes(trial) = 10^-5;
                    else
                        this_reg = fit(xfit, yfit, 'poly1');
                        slopes(trial) = this_reg.p1;
                    end
                end
                slopes = abs(slopes(~isnan(slopes)));
                ind_include = find(slopes>=quantile(slopes, 0.5));
                traj_rate.mean.(angle).mean.before_index  = ind_include;

            end

            % these are all the sdf integrals:
            ind_present = arrayfun(@(x)isfield(x.rate_map, 'before'), Trials);
            sdf_all_trials = arrayfun(@(x)x.sdf_integral.before, Trials(ind_present), 'UniformOutput', false);
            occu_all_trials = arrayfun(@(x)x.occupancy.before, Trials(ind_present), 'UniformOutput', false);
            sdf_all_trials_3d =  cat(3, sdf_all_trials{:});
            occu_all_trials_3d =  cat(3, occu_all_trials{:});
            traj_rate.mean.(angle).mean.before  = cal_mean_rate_map11(sdf_all_trials_3d, occu_all_trials_3d);
            ind_present = arrayfun(@(x)isfield(x.rate_map, 'after'), Trials);
            sdf_all_trials = arrayfun(@(x)x.sdf_integral.after, Trials(ind_present), 'UniformOutput', false);
            occu_all_trials = arrayfun(@(x)x.occupancy.after, Trials(ind_present), 'UniformOutput', false);
            sdf_all_trials_3d =  cat(3, sdf_all_trials{:});
            occu_all_trials_3d =  cat(3, occu_all_trials{:});
            traj_rate.mean.(angle).mean.after  = cal_mean_rate_map11(sdf_all_trials_3d, occu_all_trials_3d);

        else
            ind_present = arrayfun(@(x)isfield(x.rate_map, 'before'), Trials);
            sdf_all_trials = arrayfun(@(x)x.sdf_integral.before, Trials(ind_present), 'UniformOutput', false);
            occu_all_trials = arrayfun(@(x)x.occupancy.before, Trials(ind_present), 'UniformOutput', false);
            sdf_all_trials_3d =  cat(3, sdf_all_trials{:});
            occu_all_trials_3d =  cat(3, occu_all_trials{:});
            traj_rate.mean.(angle).mean.before  = cal_mean_rate_map11(sdf_all_trials_3d, occu_all_trials_3d);
        end

        % Calculate average map
        traj_rate.mean.(angle).all  = rate_maps;
        traj_rate.mean.(angle).coords  = {x_bins, y_bins};
        traj_rate.mean.(angle).trajectories  = traj_maps;
        %
        %  Smooth (no longer needed)
        for kk =1:length(types)
            if isfield(traj_rate.mean.(angle).mean, types{kk})
                rate_map_ = traj_rate.mean.(angle).mean.(types{kk});

                rate_map_smoothed = rate_map_; 
                traj_rate.mean.(angle).mean_smoothed.(types{kk}) = rate_map_smoothed;

                if false % old code. not exactly correct
                    unvisited_mask = (rate_map_ == 0); % Assuming 0 was set above; adjust if using NaN
                    % Temporarily replace NaNs or zeros with a placeholder (e.g., 0) for smoothing
                    rate_map_temp = rate_map_;
                    rate_map_temp(isnan(rate_map_temp)) = 0; % Replace NaNs with 0 for smoothing
                    % Smooth the temporary map
                    rate_map_smoothed = imgaussfilt(rate_map_temp, 1); % Sigma = 2 bins
                    % Restore NaNs for unvisited bins
                    % rate_map_smoothed(unvisited_mask) = NaN;
                    traj_rate.mean.(angle).mean_smoothed.(types{kk}) = rate_map_smoothed;
                end
            end
        end
    end
end
% writetable(table_temp, 'nasha_0405_tracking.csv')
% store the spike-to-map data to this field. 
DataOut.traj_rate_map = traj_rate;

% check top view trajectory rate map
if false
    figure;
    subplot(2, 1, 1)
    imagesc(DataOut.traj_rate_map.mean.top.coords{1}, ...
        DataOut.traj_rate_map.mean.top.coords{2}, ...
        DataOut.traj_rate_map.mean.top.mean_smoothed.before)
    subplot(2, 1, 2)
    imagesc(DataOut.traj_rate_map.mean.top.coords{1}, ...
        DataOut.traj_rate_map.mean.top.coords{2}, ...
        DataOut.traj_rate_map.mean.top.mean_smoothed.after)
end
%% Plot the data
hf = 26;
figure(hf); clf(hf)

figSize = [16 17]; % in cm

set(hf,'units', 'centimeters', 'position', [2 2 figSize],...
    'color', 'w', 'name', 'trajectory and firing rate', 'paperpositionmode', 'auto', 'Visible', 'on')
% Force figure to pop up
set(hf, 'WindowStyle', 'normal');
% Ensure it ap

y_to_move = 4;

% A1 position
x_pos = 1.5;
y_pos = 10.5+y_to_move;

% Plot spikes
plotSizeSpikes = [1 1.25];
plotSizeSDF = [1 2];

% This is panel A1
annotation('textbox', 'units', 'centimeters', ...
    'position', [x_pos-1 y_pos+plotSizeSpikes(2) .5 .5], ...
    'String', 'A_1', 'EdgeColor', 'none', ...
    'Interpreter', 'tex',...
    'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');

ha_a1=axes;
% this is the plot for raster

set(ha_a1, 'nextplot', 'add', 'ydir', 'normal',...
    'units', 'centimeters', 'position', [x_pos y_pos plotSizeSpikes], ...
    'xlim', [tPre_Press tPost_Press], 'ylim', [0 10],'ydir', 'reverse', ...
    'xtick',[], 'ticklength', [.025 .1]);

numTrials = 0;
for i =1:nFP
    raster = sdf_unit.raster.press{i};
    for j =1:length(raster)
        spike_times = raster{j}/1000;
        numTrials = numTrials+1;
        if ~isempty(spike_times)
            event_times = sdf_unit.raster.eventSequence{i}(j, 1);
            xx = [spike_times; spike_times];
            yy = [numTrials; numTrials+1];
            line(xx, yy, 'color', 'k', 'linewidth', 0.5*i);
        end
    end
end

ha_a1.YLim = [0 numTrials+1];
ha_a1.XColor = 'w'; % make sure the x axis is not visible
xline(ha_a1, 0, 'color', 'm', 'linestyle',':', 'LineWidth',1);

ylabel('Trials');

% Add warped PSTH
% A2 position x_pos is the same as A1
y_pos = 8+y_to_move;
% This is panel A2
annotation('textbox', 'units', 'centimeters', ...
    'position', [x_pos-1 y_pos+plotSizeSDF(2) .5 .5], ...
    'String', 'A_2', 'EdgeColor', 'none', ...
    'Interpreter', 'tex',...
    'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');

ha_a2=axes;
set(ha_a2, 'nextplot', 'add', 'ydir', 'normal',...
    'units', 'centimeters', 'position', [x_pos y_pos plotSizeSDF],...
    'xlim', [tPre_Press, tPost_Press], 'ylim', [0 10], 'ticklength', [.025 .1]);
sdf_max = 10;
for i =1:nFP
    data = sdf_unit.sdf.press.mean{i};
    t_sdf = data(:, 1);
    i_sdf = data(:, 2);
   
    ind = find(t_sdf>=tPre_Press & t_sdf<=tPost_Press);
    plot(t_sdf(ind), i_sdf(ind), 'linewidth', 0.5*i, 'Color','k')
    sdf_max = max(sdf_max, max(i_sdf));
end
ha_a2.YLim = [0 sdf_max*1.25];
xline(ha_a2, 0, 'color', 'm', 'linestyle',':', 'LineWidth',1);
xlabel('from press (s)')
ylabel('Firing rate (Hz)')

% for trigger-release
x_pos = 3.25;
y_pos = 10.5+y_to_move;

tPre_Trigger = -250/1000;
tPost_Trigger = 2000/1000;

plotSizeSpikes2=plotSizeSpikes;
plotSizeSpikes2(1) = plotSizeSpikes(1)*(tPost_Trigger-tPre_Trigger)/(tPost_Press-tPre_Press);

plotSizeSDF2= plotSizeSDF;
plotSizeSDF2(1) = plotSizeSpikes(1)*(tPost_Trigger-tPre_Trigger)/(tPost_Press-tPre_Press);

%% This is panel B1
annotation('textbox', 'units', 'centimeters', ...
    'position', [x_pos-.25 y_pos+plotSizeSpikes2(2) .5 .5], ...
    'String', 'B1', 'EdgeColor', 'none', ...
    'Interpreter', 'tex',...
    'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');

ha_b1=axes;
% this is the plot for raster(release)
set(ha_b1, 'nextplot', 'add', 'ydir', 'normal',...
    'units', 'centimeters', 'position', [x_pos y_pos plotSizeSpikes2], ...
    'xlim', [tPre_Trigger tPost_Trigger], ...
    'ylim', [0 100],'xtick',[], 'ticklength', [.025 .1]);
ha_b1.YTick = [];
ha_b1.YColor = 'w';
ha_b1.XColor = 'w';

numTrials = 0;
for i =1:nFP
    raster = sdf_unit.raster.trigger{i};
    for j =1:length(raster)
        spike_times = raster{j}/1000;
        if ~isempty(spike_times)
            numTrials = numTrials+1;
            xx = [spike_times; spike_times];
            yy = [numTrials; numTrials+1];
            line(xx, yy, 'color', 'k', 'linewidth', 0.5*i);
        end
    end
end

ha_b1.YLim = [0 numTrials+1];
ha_b1.XColor = 'k'; % make sure the x axis is not visible
xline(ha_b1, 0, 'color', 'm', 'linestyle',':', 'LineWidth',1);

y_pos = 8+y_to_move;

%% This is panel B2
annotation('textbox', 'units', 'centimeters', ...
    'position', [x_pos-.25 y_pos+plotSizeSDF2(2) .5 .5], ...
    'String', 'B_2', 'EdgeColor', 'none', ...
    'Interpreter', 'tex',...
    'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');

ha_b2=axes;
set(ha_b2, 'nextplot', 'add', 'ydir', 'normal',...
    'units', 'centimeters', 'position', [x_pos y_pos plotSizeSDF2], ...
    'xlim', [tPre_Trigger tPost_Trigger], 'ylim', [0 sdf_max], 'ticklength', [.025 .1]);
t_sdf = sdf_unit.sdf.trigger.pooled.warped.time;
i_sdf = sdf_unit.sdf.trigger.pooled.warped.mean;
ind = find(t_sdf>=tPre_Trigger & t_sdf<=tPost_Trigger);
plot(t_sdf(ind), i_sdf(ind), 'linewidth', 1, 'Color','k')
sdf_max = max(sdf_max, max(i_sdf));
ha_a2.YLim = [0 sdf_max*1.25];
ha_b2.YLim = [0 sdf_max*1.25];
ha_b2.YTick = [];
ha_b2.YColor = 'w';
xline(ha_b2, 0, 'color', 'm', 'linestyle',':', 'LineWidth',1);
% plot reaction time
rt =sdf_unit.sdf.trigger.pooled.warped.rt_retrieval(1);
xline(ha_b1, rt/1000, 'color', 'm', 'linestyle',':', 'LineWidth',1);
xline(ha_b2, rt/1000, 'color', 'm', 'linestyle',':', 'LineWidth',1);

% plot poke time
retrieval_t =sdf_unit.sdf.trigger.pooled.warped.rt_retrieval(2);
xline(ha_b1, (rt+retrieval_t)/1000, 'color', 'm', 'linestyle',':', 'LineWidth',1);
xline(ha_b2, (rt+retrieval_t)/1000, 'color', 'm', 'linestyle',':', 'LineWidth',1);
xlabel('trigger (s)')

% This is the size of the top-view frames
plotSize_width = 4;
plotSize_height = frame_size.top(1)*plotSize_width/frame_size.top(2);

% This is the size of the top-view frames
plotSize_width = 3.5;
plotSize_height_side = frame_size.side(1)*plotSize_width/frame_size.side(2);

% Add top and side frames
ha_e = axes;
x_pos =x_pos+plotSizeSDF2(1)+1;
set(ha_e, 'nextplot', 'add', 'box', 'on', 'ydir', 'reverse', 'units', 'centimeters', ...
    'position', [x_pos y_pos plotSize_width plotSize_height], ...
    'xlim', [0 frame_size.top(2)], ...
    'ylim', [0 frame_size.top(1)],...
    'XTickLabel', [], 'YtickLabel', [], 'ticklength', [.025 .1]);
image(frame.top);
set(gca, 'ydir', 'reverse')
x_pos = x_pos + plotSize_width+1;

ha_e_side = axes;
set(ha_e_side, 'nextplot', 'add', 'box', 'on', 'ydir', 'reverse', 'units', 'centimeters', ...
    'position', [x_pos y_pos plotSize_width plotSize_height_side], ...
    'xlim', [0 frame_size.top(2)], ...
    'ylim', [0 frame_size.top(1)],...
    'XTickLabel', [], 'YtickLabel', [], 'ticklength', [.025 .1]);
image(frame.side);
set(gca, 'ydir', 'reverse')

% Plot all trial
y_pos = 2+y_to_move;
x_pos = 1.25;
%% This is panel C, towards the lever

annotation('textbox', 'units', 'centimeters', ...
    'position', [x_pos-.5 y_pos+plotSize_height .5 .5], ...
    'String', 'C', 'EdgeColor', 'none', ...
    'Interpreter', 'none',...
    'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');

% Plot movement and spikes (to lever)
width_box = 40;
length_box = 150;

traj_size = 8;
spike_size = 1;

ha_c1 = axes;
set(ha_c1, 'nextplot', 'add', 'box', 'on', 'ydir', 'reverse', 'units', 'centimeters', ...
    'position', [x_pos y_pos plotSize_width plotSize_height], ...
    'xlim', [0 frame_size.top(2)], ...
    'ylim', [0 frame_size.top(1)],...
    'XTickLabel', [], 'YtickLabel', [], 'ticklength', [.025 .1]);
rectangle('Position', [ha_c1.XLim(1), 280, width_box, length_box], 'EdgeColor', 'none', 'FaceColor', [0 173 238]/255, 'LineWidth', 2);
rectangle('Position', [ha_c1.XLim(2)-width_box, 280, width_box, length_box], 'EdgeColor', 'none', 'FaceColor', [0 173 238]/255, 'LineWidth', 2);

nplot = 5;
valid_trials = DataOut.traj_rate_map.mean.top.mean.before_index;

if length(valid_trials)>nplot
    indplot = valid_trials(randperm(length(valid_trials), nplot));
else
    nplot = length(valid_trials);
    indplot = valid_trials;
end

trajs = [];
for kk = 1:nplot
    ind_example     =       indplot(kk);
       
    if ~isfield(DataOut.traj_rate_map.all.top(ind_example).valid_index, 'before')
        continue
    end
    data            =       DataOut.traj_rate_map.all.top(ind_example).valid_index.before;
    x_example = data.x;
    y_example = data.y;
    trajs = [trajs; x_example y_example];
    % extract spike times within t_example
    scatter(ha_c1, x_example, y_example, ...
        traj_size, ...
        'Marker', '.', ...
        'MarkerEdgeColor', [.85 .85 .85],...
        'Linewidth', 0.25);
end

for kk = 1:nplot
    ind_example = indplot(kk);
    if ~isfield(DataOut.traj_rate_map.all.top(ind_example).valid_index, 'before')
        continue
    end
    data            =       DataOut.traj_rate_map.all.top(ind_example).valid_index.before;
    x_example = data.x_org;
    y_example = data.y_org;
     t_example = data.t_org;

    valid_ind = data.index;
    spk_example = DataOut.traj_rate_map.all.top(ind_example).t_spikes_relative;

    for i =2:1:length(t_example)
        if valid_ind(i) ==0
            continue
        end
        if any(spk_example>=t_example(i-1) & spk_example<t_example(i))
            i_nspikes = sum(find(spk_example>=t_example(i-1) & spk_example<t_example(i)));
            % add jitters so spikes can be spread out
            jitters_x = bin_size.top*(rand(1, i_nspikes)-0.5);
            jitters_y = bin_size.top*(rand(1, i_nspikes)-0.5);
            scatter(ha_c1, x_example(i)+jitters_x, y_example(i)+jitters_y, ...
                spike_size, 'filled', ...
                'Marker', 'o',  'MarkerEdgeColor', 'none', ...
                'MarkerFaceColor', 'r',...
                'MarkerFaceAlpha', 0.8,...
                'Linewidth', 0.5);
        end
    end
end

% Labels and title
title(sprintf('Press: %s ms',TimeStamp), 'fontsize', 8);
grid on;
set(gca, 'ydir', 'reverse')

%% Related to C | C2 Add spike-trajectory mapping data
spkrate_map_1 = (DataOut.traj_rate_map.mean.top.mean_smoothed.before(:));
spkrate_map_2 = (DataOut.traj_rate_map.mean.top.mean_smoothed.after(:));
spkrate_map_3 = (DataOut.traj_rate_map.mean.side.mean_smoothed.before(:));
spkrate_map = [spkrate_map_1; spkrate_map_2; spkrate_map_3];
spkrate_map_max = quantile(spkrate_map, 0.99);
ha_c2 = axes;
set(ha_c2, 'nextplot', 'add', 'box', 'on', 'ydir', 'reverse', 'units', 'centimeters', ...
    'position', [x_pos y_pos-plotSize_height-1 plotSize_width plotSize_height], ...
    'xlim', [0 frame_size.top(2)], ...
    'ylim', [0 frame_size.top(1)],...
    'XTickLabel', [], 'YtickLabel', [], 'ticklength', [.025 .1]);

x_bins = DataOut.traj_rate_map.mean.top.coords{1};
x_bins = x_bins(1:end-1)+(x_bins(2)-x_bins(1))/2;
y_bins = DataOut.traj_rate_map.mean.top.coords{2};
y_bins = y_bins(1:end-1)+(y_bins(2)-y_bins(1))/2;
map_data = DataOut.traj_rate_map.mean.top.mean_smoothed.before;
imagesc(ha_c2, x_bins, y_bins, map_data, [0 spkrate_map_max]);

% scatter(ha_c2, trajs(:, 1), trajs(:, 2), ...
%     traj_size/5, ...
%     'Marker', '.', ...
%     'MarkerEdgeColor', [.85 .85 .85],...
%     'Linewidth', 0.1);
set(gca, 'ydir', 'reverse')

% add colorbar
hbar = colorbar; % Show colorbar for firing rate
set(hbar, 'units', 'centimeters',...
    'position', [x_pos+plotSize_width+0.1 y_pos-plotSize_height-1 .15 plotSize_height])
hbar.Label.String = 'Firing rate (Hz)';
hbar.Label.Rotation = 90; % Rotate the colorbar label
hbar.Label.VerticalAlignment = 'Middle';
%% D | Plot 'from lever' data
x_pos  = x_pos + plotSize_width+1;
annotation('textbox', 'units', 'centimeters', ...
    'position', [x_pos-.5 y_pos+plotSize_height .5 .5], ...
    'String', 'D', 'EdgeColor', 'none', ...
    'Interpreter', 'none',...
    'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');

ha_d1 = axes;
set(ha_d1, 'nextplot', 'add', 'box', 'on', 'ydir', 'reverse', 'units', 'centimeters', ...
    'position', [x_pos y_pos plotSize_width plotSize_height], ...
    'xlim', [0 frame_size.top(2)], ...
    'ylim', [0 frame_size.top(1)],...
    'XTickLabel', [], 'YtickLabel', [], 'ticklength', [.025 .1]);
rectangle('Position', [ha_d1.XLim(1), 280, width_box, length_box], 'EdgeColor', 'none', 'FaceColor', [0 173 238]/255, 'LineWidth', 2);
rectangle('Position', [ha_d1.XLim(2)-width_box, 280, width_box, length_box], 'EdgeColor', 'none', 'FaceColor', [0 173 238]/255, 'LineWidth', 2);

for kk = 1:nplot
    ind_example     =       indplot(kk);
    if ~isfield(DataOut.traj_rate_map.all.top(ind_example).valid_index, 'after')
        continue
    end
    data            =       DataOut.traj_rate_map.all.top(ind_example).valid_index.after;
    x_example = data.x;
    y_example = data.y;
    % extract spike times within t_example
    scatter(ha_d1, x_example, y_example, ...
        traj_size, ...
        'Marker', '.', ...
        'MarkerEdgeColor', [.85 .85 .85],...
        'Linewidth', 0.25);

end

for kk = 1:nplot
    ind_example = indplot(kk);
    if ~isfield(DataOut.traj_rate_map.all.top(ind_example).valid_index, 'after')
        continue
    end
    data            =       DataOut.traj_rate_map.all.top(ind_example).valid_index.after;
    x_example = data.x_org;
    y_example = data.y_org;
    t_example = data.t_org;

    valid_ind = data.index;
    spk_example = DataOut.traj_rate_map.all.top(ind_example).t_spikes_relative;

    for i =2:1:length(t_example)
        if valid_ind(i) ==0
            continue
        end
        if any(spk_example>=t_example(i-1) & spk_example<t_example(i))
            i_nspikes = sum(find(spk_example>=t_example(i-1) & spk_example<t_example(i)));
            % add jitters so spikes can be spread out
            jitters_x = bin_size.top*(rand(1, i_nspikes)-0.5);
            jitters_y = bin_size.top*(rand(1, i_nspikes)-0.5);
            scatter(ha_d1, x_example(i)+jitters_x, y_example(i)+jitters_y, ...
                spike_size, 'filled', ...
                'Marker', 'o',  'MarkerEdgeColor', 'none', ...
                'MarkerFaceColor', 'r',...
                'MarkerFaceAlpha', 0.8,...
                'Linewidth', 0.5);
        end
    end
end

% Labels and title
title(sprintf('Press: %s ms',TimeStamp), 'fontsize', 8);
grid on;
set(gca, 'ydir', 'reverse')

%% D2 | from lever rate map
ha_d2 = axes;
set(ha_d2, 'nextplot', 'add', 'box', 'on', 'ydir', 'reverse', 'units', 'centimeters', ...
    'position', [x_pos y_pos-plotSize_height-1 plotSize_width plotSize_height], ...
    'xlim', [0 frame_size.top(2)], ...
    'ylim', [0 frame_size.top(1)],...
    'XTickLabel', [], 'YtickLabel', [], 'ticklength', [.025 .1]);
 
map_data = DataOut.traj_rate_map.mean.top.mean_smoothed.after;
imagesc(ha_d2, x_bins, y_bins, map_data, [0 spkrate_map_max]);
set(gca, 'ydir', 'reverse')

% add colorbar
hbar = colorbar; % Show colorbar for firing rate
set(hbar, 'units', 'centimeters',...
    'position', [x_pos+plotSize_width+0.1 y_pos-plotSize_height-1 .15 plotSize_height])
hbar.Label.String = 'Firing rate (Hz)';
hbar.Label.Rotation = 90; % Rotate the colorbar label
hbar.Label.VerticalAlignment = 'Middle';
%% E | Plot side view data
x_pos  = x_pos + plotSize_width+1;
annotation('textbox', 'units', 'centimeters', ...
    'position', [x_pos-.5 y_pos+plotSize_height .5 .5], ...
    'String', 'E', 'EdgeColor', 'none', ...
    'Interpreter', 'none',...
    'HorizontalAlignment', 'center', 'FontSize', 10,...
    'fontweight', 'bold');

ha_e1 = axes;
set(ha_e1, 'nextplot', 'add', 'box', 'on', 'ydir', 'reverse', 'units', 'centimeters', ...
    'position', [x_pos y_pos plotSize_width plotSize_height_side], ...
    'xlim', [0 frame_size.side(2)], ...
    'ylim', [0 frame_size.side(1)],...
    'XTickLabel', [], 'YtickLabel', [], 'ticklength', [.025 .1]);

if length(DataOut.traj_rate_map.all.side)>nplot
    indplot = randperm(length(DataOut.traj_rate_map.all.side), nplot);
else
    nplot = length(DataOut.traj_rate_map.all.side);
    indplot = randperm(length(DataOut.traj_rate_map.all.side), nplot);
end


for kk = 1:nplot
    ind_example     =       indplot(kk);
    if ~isfield(DataOut.traj_rate_map.all.side(ind_example).valid_index, 'before')
        continue
    end
    data            =       DataOut.traj_rate_map.all.side(ind_example).valid_index.before;
    x_example = data.x;
    y_example = data.y;

    % extract spike times within t_example
    scatter(ha_e1, x_example, y_example, ...
        traj_size, ...
        'Marker', '.', ...
        'MarkerEdgeColor', [.85 .85 .85],...
        'Linewidth', 0.25);
end

% add spikes
for kk = 1:nplot
    ind_example = indplot(kk);
    if ~isfield(DataOut.traj_rate_map.all.side(ind_example).valid_index, 'before')
        continue
    end
    data            =       DataOut.traj_rate_map.all.side(ind_example).valid_index.before;
    x_example = data.x_org;
    y_example = data.y_org;
     t_example = data.t_org;

    valid_ind = data.index;
    spk_example = DataOut.traj_rate_map.all.side(ind_example).t_spikes_relative;

    for i =2:1:length(t_example)
        if valid_ind(i) ==0
            continue
        end
        if any(spk_example>=t_example(i-1) & spk_example<t_example(i))
            i_nspikes = sum(find(spk_example>=t_example(i-1) & spk_example<t_example(i)));
            % add jitters so spikes can be spread out
            jitters_x = bin_size.top*(rand(1, i_nspikes)-0.5);
            jitters_y = bin_size.top*(rand(1, i_nspikes)-0.5);
            scatter(ha_e1, x_example(i)+jitters_x, y_example(i)+jitters_y, ...
                spike_size, 'filled', ...
                'Marker', 'o',  'MarkerEdgeColor', 'none', ...
                'MarkerFaceColor', 'r',...
                'MarkerFaceAlpha', 0.8,...
                'Linewidth', 0.5);
        end
    end
end


% Labels and title
title(sprintf('Press: %s ms',TimeStamp), 'fontsize', 8);
grid on;
set(gca, 'ydir', 'reverse')

%% E2 | to lever rate map
ha_e2 = axes;
set(ha_e2, 'nextplot', 'add', 'box', 'on', 'ydir', 'reverse', 'units', 'centimeters', ...
    'position', [x_pos y_pos-plotSize_height-1 plotSize_width plotSize_height_side], ...
    'xlim', [0 frame_size.top(2)], ...
    'ylim', [0 frame_size.top(1)],...
    'XTickLabel', [], 'YtickLabel', [], 'ticklength', [.025 .1]);
 
map_data = DataOut.traj_rate_map.mean.side.mean_smoothed.before;

imagesc(ha_e2, x_bins, y_bins, map_data, [0 spkrate_map_max]);
set(gca, 'ydir', 'reverse')

% add colorbar
hbar = colorbar; % Show colorbar for firing rate
set(hbar, 'units', 'centimeters',...
    'position', [x_pos+plotSize_width+0.1 y_pos-plotSize_height-1 .15 plotSize_height_side])
hbar.Label.String = 'Firing rate (Hz)';
hbar.Label.Rotation = 90; % Rotate the colorbar label
hbar.Label.VerticalAlignment = 'Middle';

annotation('textbox', 'units', 'normalized', ...
    'position', [.6 .92 .3 .05], ...
    'String', DataOut.cell_id, 'EdgeColor', 'none', ...
    'Interpreter', 'none',...
    'HorizontalAlignment', 'center', 'FontSize', 12,...
    'fontweight', 'bold');

% Save this figure
if ~isempty(save_fig_path)
    fig_folder = save_fig_path;
    if ~exist(fig_folder, 'dir')
        mkdir(fig_folder)
    end

    tosavename = fullfile(fig_folder, [DataOut.cell_id]);
    print (hf,'-dpng', tosavename)
    print (hf,'-dpdf', tosavename)
end

end


% A note on NaN-aware smoothing
% Better practice is a **mask-weighted (NaN-aware) smoothing**:
% 
% 1. Build two images on the same grid:
% 
%    * (R): your per-bin rate (NaN for unvisited bins).
%    * (M): a binary mask (1 where visited, 0 where not), or better, **occupancy time** (T_b).
% 
% 2. Convolve **numerator and weights separately**, then divide:
%    $$
%    \tilde R ;=; \frac{G \ast (R \cdot M)}{G \ast M}
%    \quad\text{or}\quad
%    \tilde R ;=; \frac{G \ast (C)}{G \ast (T)},
%    $$
%    where (C) is spike count (or SDF integral) per bin, (T) is occupancy per bin, and (G) is your Gaussian.
%    If the denominator is (0) (no support), leave (\tilde R) as NaN.
% 
% This does exactly what people mean by “NaN-aware smoothing”: only neighboring **visited** bins contribute. It also handles edges correctly