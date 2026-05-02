function sdf_out = MakeChemoSDF(r, varargin)

% 3/29/2023
% Jianing Yu
% Example: Chemo.MakeChemoSDF(r, 'InjectionSegment', 3)
set_matlab_default;
% Plot firing rate over sessions  
injection_seg = NaN;
injection_time = NaN;
recovery_segment = NaN;

for i =1:2:nargin-1
    switch varargin{i}
        case 'InjectionTime'
            injection_time = varargin{i+1};
        case 'InjectionSegment'
            injection_seg = varargin{i+1};              
        case 'RecoverySegment'
            recovery_segment = varargin{i+1};
    end;
end;

% Figure out the begining and ending of each recording segments. 
[datafile_onset,  datafile_offset, datafile_dur] = Chemo.find_bounds(r);
% simply plot all data in sdf
n_seg = length(datafile_onset);
time_all = cell(1, n_seg);
for k =1:n_seg
    time_all{k} = round(datafile_onset(k)*1000):round(datafile_offset(k)*1000);
end; 

if ~isnan(injection_seg)
    injection_time = mean([datafile_onset(injection_seg), datafile_offset(injection_seg-1)]); % approximate drug application time
end;

n_unit = length(r.Units.SpikeTimes);
% compute sdf
kernel_width = 10000; % in ms
r_sdf = cell(n_unit, n_seg);
spk_all= cell(n_unit, n_seg);

for i =1:n_unit
    ispk_times = r.Units.SpikeTimes(i).timings; % in ms
    for k =1:n_seg
        ik_spk_times = round(ispk_times(ispk_times>=datafile_onset(k)*1000 & ispk_times<=datafile_offset(k)*1000));
        spk_all{i, k}    = ik_spk_times;
        % extract spikes within this time window
        [~, indspk, indspk2] = intersect(time_all{k}, ik_spk_times);
        ik_spkmat = sparse(1, indspk, 1, 1, length(time_all{k}));
        ik_sdf = Chemo.sdf(time_all{k}/1000, ik_spkmat, kernel_width);
        r_sdf{i, k} = ik_sdf;
    end;
end;

% Press time
event_marker = 'LeverPress';
event_index  = find(strcmp(r.Behavior.Labels, event_marker));
event_times = r.Behavior.EventTimings(r.Behavior.EventMarkers==event_index);
n_event = length(event_times);

% downsample to 1 sample per second
 % size of r_sdf: n_unit x n_segment
sdf_out.time_s      =       cellfun(@(x)downsample(x, 1000)/1000, time_all, 'UniformOutput', false);
sdf_out.sdf         =       cellfun(@(x)downsample(x, 1000), r_sdf, 'UniformOutput', false);
sdf_out.kernel      =       kernel_width;
sdf_out.spk         =       spk_all;
sdf_out.t_injection =       injection_time;
sdf_out.press_times =        event_times;
sdf_out.t_recovery = NaN;

%% Plot all result
hf=23;
figure(hf); clf(hf) 

set(gcf, 'unit', 'centimeters', 'position', [2 2 28 16], 'paperpositionmode', 'auto','renderer','Painters')
seg_sub = 0;
trange = [sdf_out.time_s{1}(1) sdf_out.time_s{end}(end)];

if ~isnan(recovery_segment)
    seg_sub = sdf_out.time_s{recovery_segment}(1)-sdf_out.time_s{recovery_segment-1}(end); % difference between recovery and last recording segment 
    seg_sub_in_hr = (sdf_out.time_s{recovery_segment}(1)-injection_time)/(60*60);
    recovery_onset = sdf_out.time_s{recovery_segment}(1);
    sdf_out.t_recovery = recovery_onset;
end;
session_gap = 60; % add an artificial gap between last recording session and the recovery_segment

drug_color = [235, 176, 45]/255;
% 0. Plot responses
ha0 = axes('unit', 'centimeters', 'position', [2 2 4 1.5], ...
    'xlim', [trange], 'ylim', [0 length(sdf_out.press_times)*1.1],...
    'nextplot', 'add', 'tickdir', 'out', 'TickLength', [0.0200 0.0250]);

press_times = sdf_out.press_times;
if ~isnan(recovery_segment)
    press_times = sdf_out.press_times;
    press_times(press_times>recovery_onset*1000) = press_times(press_times>recovery_onset*1000)-seg_sub*1000+session_gap*1000;
    trange=[trange(1) press_times(end)];
    set(ha0, 'xlim', [trange(1) sdf_out.time_s{end}(end)-seg_sub+session_gap]);
end;

line([injection_time injection_time], [0 length(sdf_out.press_times)*1.1], 'color', 'k', 'linewidth', 1,'linestyle', '-.');
if ~isnan(recovery_segment)
    line([recovery_onset recovery_onset]-seg_sub - session_gap/2, [0 length(sdf_out.press_times)*1.1], 'color', 'k', 'linewidth', 1,'linestyle', '-.');
end;
 
plotshaded([sdf_out.t_injection trange(end)],[0 0; length(sdf_out.press_times)*1.1 length(sdf_out.press_times)*1.1],...
    drug_color)

% add press time
line([press_times press_times]/1000, [0 0.1*length(sdf_out.press_times)]', 'linewidth', 1, 'color', 'k')
plot(press_times/1000, [1:length(press_times)], 'linewidth', 1);

ylabel('Press #')
xlabel('Time (s)')

% 1. Plot all SDFs
height = 8/n_unit; % height of each plot
allcolors = varycolor(n_unit+2);
minY  = 5;

for i =1:n_unit
    max_rate = 0;
    ha1(i)= axes('unit', 'centimeters', 'position', [2 4.5+ height*(i-1) 4 height*0.9], ...
        'xlim', [trange], 'ylim', [1 10],...
        'nextplot', 'add', 'tickdir', 'out', 'TickLength', [0.0200 0.0250]);
    % put injection time
    % use an arbitual number 200 to cover all ranges
    hline(i) = line([injection_time injection_time], [0 200], 'color', 'k', 'linewidth', 1,'linestyle', '-.');
    plotshaded([sdf_out.t_injection trange(end)],[0 0; 200 200],...
        drug_color)    
    if i>1
        set(ha1(i), 'XTicklabel',[], 'XTick', []);
    else
        %         xlabel('Time (s)')
        ylabel('Spk rate (spk per s)')
    end
    for k =1:n_seg
        % add sdf
        if k>=recovery_segment
            % draw another line
            hline2 = line((sdf_out.time_s{k}(1) - seg_sub - session_gap/2)*[1 1], [0 200], 'color', 'k', 'linewidth', 1,'linestyle', '-.');

            plotshaded(sdf_out.time_s{k} - seg_sub + session_gap,[zeros(1, length(sdf_out.sdf{i, k})); transpose(sdf_out.sdf{i, k})], allcolors(i+1, :));
            plot(ha1(i), sdf_out.time_s{k} - seg_sub + session_gap, sdf_out.sdf{i, k}, 'color', allcolors(i+1, :), 'linewidth', 0.5);
            max_rate = max(max_rate, max(sdf_out.sdf{i, k}));
          set(ha1(i), 'xlim', [trange(1) sdf_out.time_s{end}(end)-seg_sub+session_gap]);
 
        else
            plotshaded(sdf_out.time_s{k},[zeros(1, length(sdf_out.sdf{i, k})); transpose(sdf_out.sdf{i, k})], allcolors(i+1, :));
            plot(ha1(i), sdf_out.time_s{k}, sdf_out.sdf{i, k}, 'color', allcolors(i+1, :), 'linewidth', 0.5);
            max_rate = max(max_rate, max(sdf_out.sdf{i, k}));
        end;

    end;
    max_rate = 1.1*max(max_rate,  minY);
    set(ha1(i), 'ylim', [0 max_rate]);
end;

% 2. Plot spike raster for the 200 seconds surrounding drug injection time
t_careabout = 300;
sprintf('Plot %2.0d seconds of data around injection time', t_careabout*2)
trange_raster = injection_time+[-1 1]*t_careabout; % use 100 seconds as a mark
line(ha1(i), trange_raster, [max_rate*0.98, max_rate*0.98], 'color', 'k', 'linewidth', 1,'linestyle', '-')

ha2 = axes('unit', 'centimeters', 'position', [2 13.6 4 2], ...
    'xlim', [trange_raster]-injection_time,'xtick', [-600:60:600], 'ylim', [1 n_unit+1], ...
    'nextplot', 'add', 'tickdir', 'out', 'TickLength', [0.0200 0.0250]);
plotshaded([sdf_out.t_injection trange_raster(end)],[0 0; length(sdf_out.press_times)*1.1 length(sdf_out.press_times)*1.1],...
    drug_color)
for i =1:n_unit
    for k =1:n_seg
        % extract spike train
        ik_spktrain = sdf_out.spk{i, k}/1000; % time of spikes in ms
        %
        ik_spktrain = ik_spktrain(ik_spktrain >=trange_raster(1) & ik_spktrain <= trange_raster(2));
        xx =  ik_spktrain;
        xx= [xx; xx]'-injection_time;
        yy = [i; i+0.8];
        if ~isempty(xx)
            line(ha2, xx, yy, 'color',  allcolors(i+1, :));
        end
    end;
    % put injection time
    line([0 0], [n_unit+1 0], 'color', 'k', 'linewidth', 1,'linestyle', '-.')
end;

xlabel('Time relative to injection(s)')

% 3. Plot firing rate reduction ratio
% 5 min, 10 min
t_pre_injection         =       sdf_out.t_injection - 5*60;   % pre injection
t_post_injection1       =       sdf_out.t_injection + 5*60; % post injection 5 min
t_post_injection2       =       sdf_out.t_injection + 10*60; % post injection 10 min
t_post_injection3       =       sdf_out.t_injection + 15*60; % post injection 10 min

t_critical = [t_pre_injection t_post_injection1 t_post_injection2 t_post_injection3];

if ~isnan(recovery_segment)
    t_recovery  = sdf_out.t_recovery + 5*60;
    t_critical = [t_critical t_recovery];
end;

counting_window         =       3*60;      % look at every rate over 3 min

% pre injection firing rate
rate_pre_injection        =       CalRate(sdf_out, t_pre_injection, counting_window);
rate_post_injection1    =       CalRate(sdf_out, t_post_injection1, counting_window);
rate_post_injection2    =       CalRate(sdf_out, t_post_injection2, counting_window);
rate_post_injection3    =       CalRate(sdf_out, t_post_injection3, counting_window);
rate_all                        =       [rate_pre_injection rate_post_injection1 rate_post_injection2 rate_post_injection3];
 
if ~isnan(recovery_segment)
    rate_post_recovery = CalRate(sdf_out, t_recovery, counting_window);
    rate_all = [rate_all rate_post_recovery];
end;

sdf_out.t_critical = t_critical;
sdf_out.rate_all  = rate_all;
ind_10min = 3;

if ~isnan(recovery_segment)
    sdf_out.t_critical_description = {'Pre', '(5min)', '(10min)', '(15min)', ['(' num2str(round(seg_sub_in_hr)) 'hr)']};
    ind_recovery = 5;
else
    sdf_out.t_critical_description =  {'Pre', '(5min)', '(10min)', '(15min)'};
    ind_recovery = NaN;
end;


max_rate = max(rate_all(:));

% 4. Plot mean firing rate 
ha3 = axes('unit', 'centimeters', 'position', [8 2 4 3], ...
    'xlim', [0.5 length(sdf_out.t_critical)+0.5],'ylim', [0.001 max_rate*1.1], 'ytick', 10.^[-2:1:2], ...
    'xtick', [1:5],'xticklabel',sdf_out.t_critical_description,'XTickLabelRotation', 90,...
    'yscale','log', ...
    'nextplot', 'add', 'tickdir', 'out', 'TickLength', [0.0200 0.0250]);
 
for i =1:n_unit
    plot(ha3, [1:length(sdf_out.t_critical)], rate_all(i, :), 'color', allcolors(i+1, :), 'marker', 'o',...
        'markeredgecolor', 'w', 'markerfacecolor', allcolors(i+1, :), 'linestyle', '-', 'linewidth', 1)
end;

ylabel('Spike rate (Hz)')
line([1.5 1.5], [0 max_rate*1.1], 'linestyle', '-.', 'linewidth', 1)

% 5. Plot mean firing rate change (post/pre) 
ha4 = axes('unit', 'centimeters', 'position', [8 7 4 3], ...
    'xlim', [0.5 length(sdf_out.t_critical)+0.5],'ylim', [0.001 10], 'ytick', [0:0.2:1], ...
    'xtick', [1:5],'xticklabel',sdf_out.t_critical_description,'XTickLabelRotation', 90,...
    'yscale','log', ...
    'nextplot', 'add', 'tickdir', 'out', 'TickLength', [0.0200 0.0250]);

rate_ratio = zeros(n_unit, length(sdf_out.t_critical));
for i =1:n_unit
    rate_ratio(i, :) =  sdf_out.rate_all(i, :)./(rate_all(i, 1));   
    plot(ha4, [1:length(sdf_out.t_critical)], ...
        rate_ratio(i, :), 'color', allcolors(i+1, :), 'marker', 'o',...
        'markeredgecolor', 'w', 'markerfacecolor', allcolors(i+1, :), 'linestyle', '-', 'linewidth', 1)
end;

max_ratio = max(rate_ratio(:));
set(ha4, 'ylim', [0.001 max_ratio*1.1], 'ytick', 10.^[-3:2]);
ylabel('Post/Pre')
line([1.5 1.5], [0 0], 'linestyle', '-.', 'linewidth', 1)
line([0.5 5.5], [1 1], 'linestyle', '--', 'color', 'k', 'linewidth', 1);
sprintf('Firing rate reduction at 10 min is %2.2f \n', 1-rate_ratio(:, ind_10min))

% 6. Plot firing rate reduction  (post/pre) 
ha5 = axes('unit', 'centimeters', 'position', [8 12 4 3], ...
    'xlim', [0 1],'ylim', [0.001 10], 'ytick', 10.^[-3:2], ...
    'xtick', [0.5],'xticklabel', {'(10 min)'},'XTickLabelRotation', 90,...
    'yscale','log', 'xticklabel', [],  ...
    'nextplot', 'add', 'tickdir', 'out', 'TickLength', [0.0200 0.0250]);
set(ha5, 'xlim', [0 1], 'xtick', [0.5], 'xticklabel', {'(10min)'});

for i =1:n_unit
    scatter((rand-0.5)*0.6+0.5, rate_ratio(i, ind_10min), 'Marker', 'o', ...
        'MarkerEdgeColor', 'none', 'MarkerfaceColor', allcolors(i+1, :), ...
        'MarkerFaceAlpha', 0.5, 'SizeData', 25)
    if ~isnan(ind_recovery)
        scatter((rand-0.5)*0.6+0.5+1, rate_ratio(i, ind_recovery), 'Marker', 'o', ...
            'MarkerEdgeColor', 'none', 'MarkerfaceColor', allcolors(i+1, :), ...
            'MarkerFaceAlpha', 0.5, 'SizeData', 25)
    end;
end;

if ~isnan(ind_recovery)
    set(ha5, 'xlim', [0 2], 'xtick', [0.5 1.5], 'xticklabel', {'(10min)', '(Recovery)'});
end;


set(ha5, 'ylim', [0.001 max_ratio*1.1], 'ytick', 10.^[-3:2]);
ylabel('Post/Pre')
 
line([0 2], [1 1], 'linestyle', '--', 'color', 'k', 'linewidth', 1);

% 6. Plot firing rate before press
spkout = struct('Ncell', [], 'raster', [], 'time', [], 'spk_chs', []);
tpre = 2000;
tpost = 1000;
for i = 1:n_event
    spkout(i) = ExtractPhasicPopulationEvents(r, 't', event_times(i),...
        'tpre', tpre, 'tpost', tpost);
end;

% Plot raster
ha6 =  axes('unit', 'centimeters', 'position', [16.5, 2, 4 8],...
    'nextplot', 'add',...
    'xlim', [-tpre tpost], 'ylim', [0 n_event+1], 'box', 'on');
example_unit = 3;
ind_injection = find(event_times/1000>sdf_out.t_injection, 1, 'first');

if ~isempty(ind_injection)
plotshaded([-tpre tpost], [ind_injection ind_injection; 1+n_event 1+n_event], drug_color)
end
for i =1:n_event
    this_raster = spkout(i).raster;
    t_raster    = spkout(i).time;
    for j = 1:n_unit%example_unit
        if ~isempty(find(this_raster(j, :)))
            j_raster = t_raster(find(this_raster(j, :)));
            scatter(j_raster, i*ones(1, length(j_raster)), 2, 'Marker', '.', 'MarkerFaceColor',allcolors(j+1, :),'MarkerEdgeColor',allcolors(j+1, :),...
                'MarkerFaceAlpha',.5,'MarkerEdgeAlpha',.5);
        end;
    end;
end;
line([0 0],  [0 n_event], 'color', 'k', 'linewidth', 2)

xlabel('Time from press onset (s)')
ylabel('Press #')

% 7. plot pre-press time
ha7 =  axes('unit', 'centimeters', 'position', [16.5, 11.5, 4 2.5],...
    'nextplot', 'add',...
    'xlim', [0 n_event], 'ylim', [0.001 100], 'box', 'off', 'yscale', 'linear');
pre_press_rate = cell2mat(arrayfun(@(x)sum(full(x.raster(:,x.time<0)), 2)*1000/tpre, spkout, 'UniformOutput', false));
max_rate  = max(pre_press_rate(:));
if ~isempty(ind_injection)
    plotshaded([ind_injection-0.5 n_event], [0 0; max_rate max_rate], drug_color)
    line([ind_injection-0.5 ind_injection-0.5], [0 100], 'linestyle', '-.', 'linewidth', 1);
end;

pre_press_rate(pre_press_rate==0) = 0.01;
for i = 1:n_unit
    scatter([1:n_event], pre_press_rate(i, :), 10, 'MarkerFaceColor',allcolors(i+1, :),'Marker', '.', 'MarkerEdgeColor',allcolors(i+1, :),...
        'MarkerFaceAlpha',.5,'MarkerEdgeAlpha',.5);
end;
set(ha7, 'ylim', [0 max_rate*1.2]);
xlabel('Press #')
ylabel('Rate before press (spk per s)')

% 8. Plot Press-PSTH of all units in this session
% pre-injection press time
% ind_injection = find(event_times/1000>sdf_out.t_injection, 1, 'first');

if ~isempty(ind_injection)
    pre_injection_time = event_times(1:ind_injection-1);
    post_injection_time = event_times(ind_injection:end);
else
    pre_injection_time = event_times(1:end);
    post_injection_time = [];
end;

params.pre          = 1000;
params.post         = 1000;
params.binwidth     = 20;

for i =1:n_unit
    
    [psth_press_pre, psth_t] = jpsth(r.Units.SpikeTimes(i).timings, pre_injection_time, params);
    [psth_press_post, psth_t] = jpsth(r.Units.SpikeTimes(i).timings, post_injection_time, params);
    
    sdf_out.press_psth        = {psth_t, psth_press_pre, psth_press_post};
    
    psth_press_pre = smoothdata (psth_press_pre, 'gaussian', 5);
    psth_press_post = smoothdata (psth_press_post, 'gaussian', 5);

    max_rate = 0;
    ha8(i)= axes('unit', 'centimeters', 'position', [22.5 2+ height*(i-1) 4 height*0.9], ...
        'xlim', [-params.pre params.post], 'ylim', [1 10],...
        'nextplot', 'add', 'tickdir', 'out', 'TickLength', [0.0200 0.0250]);
    
    plot(psth_t, psth_press_pre, 'color', allcolors(i+1, :), 'linewidth', 2)
    if ~isempty(post_injection_time)
        plot(psth_t, psth_press_post, 'color', allcolors(i+1, :), 'linewidth', 0.5)
    end;
    
    max_rate = max([max(psth_press_pre), max(psth_press_post)]);
    set(ha8(i), 'ylim', [0 max_rate]*1.1)
    
    if i >1
        set(ha8(i), 'xticklabel', [], 'xtick', []);
    else
        xlabel('Time to press (sec)');
        ylabel('Rate (spk per s)')
    end;
    line([0 0], [0 max_rate], 'linestyle', '--', 'color', 'k', 'linewidth', 1);

end;
    
% write down metadata
meta_ax =  axes('unit', 'centimeters', 'position', [22.5 2+ height*(n_unit-1) 4 4], ...
        'xlim', [0 10], 'ylim', [5 10],...
        'nextplot', 'add', 'tickdir', 'out', 'TickLength', [0.0200 0.0250]);
axis off
this_mfile = mfilename;
p = mfilename('fullpath');
text(1, 9, r.Meta(1).Subject, 'fontname', 'dejavu sans');
text(1, 8, r.Meta(1).DateTime(1:11), 'fontname', 'dejavu sans');
text(1, 7, ['Injection time: ' num2str(round(injection_time)) ' s'], 'fontname', 'dejavu sans');

sdf_out.subject = r.Meta(1).Subject;
sdf_out.meta    = r.Meta;
sdf_out.behavior_class = r.BehaviorClass;
sdf_out.units    = r.Units;
sdf_out.mfile   = p;

% save figures and save data. 
% data_folder = fullfile(findonedrive, '00_Work', '03_Projects', '09_Chemogenetics', 'Data', 'sdf_out');
% fig_folder = fullfile(findonedrive, '00_Work', '03_Projects', '09_Chemogenetics', 'Data', 'sdf_figs');
% 
% x=r.Meta(1).DateTimeRaw(1:4);
% file_name   = ['sdf_' r.Meta(1).Subject '_' num2str(x(1), '%2.f') num2str(x(2),'%02.f') num2str(x(4),'%02.f') '.mat'];
% fig_name    = [r.Meta(1).Subject '_' num2str(x(1), '%2.f') num2str(x(2),'%02.f') num2str(x(4),'%02.f')];
% file_name   = fullfile(data_folder, file_name);
% fig_name_tiff    = fullfile(fig_folder, fig_name);
% % fig_name_eps    = fullfile(fig_folder, 'eps', fig_name);
% save(file_name, 'sdf_out');
% print(hf,'-dpng', fig_name_tiff);

fig_folder = fullfile(pwd, 'Fig');

x=r.Meta(1).DateTimeRaw(1:4);
file_name   = ['sdf_' r.Meta(1).Subject '_' num2str(x(1), '%2.f') num2str(x(2),'%02.f') num2str(x(4),'%02.f') '.mat'];
file_name   = fullfile(pwd, file_name);

fig_name    = ['ChemoSDF_' r.Meta(1).Subject '_' num2str(x(1), '%2.f') num2str(x(2),'%02.f') num2str(x(4),'%02.f')];
fig_name_tiff    = fullfile(fig_folder, fig_name);
% fig_name_eps    = fullfile(fig_folder, 'eps', fig_name);
save(file_name, 'sdf_out');
print(hf,'-dpng', fig_name_tiff)



% saveas(gcf, fig_name_eps, 'epsc') % takes too long and too much space.
% omitted for now

function rate_out = CalRate(sdf, tonset, twin)
ncell    = size(sdf.sdf, 1);
rate_out = zeros(ncell, 1);

for k = 1:ncell
    for i =1:length(sdf.time_s)
        ind_spk = find(sdf.time_s{i} > tonset & sdf.time_s{i}<tonset+twin);
        if ~isempty(ind_spk) % thsis is tpre
            i_sdf   = mean(sdf.sdf{k, i}(ind_spk));
            if i_sdf <0.001
                i_sdf = 0.001;
            end
            rate_out(k) = i_sdf;
        end
    end
end


