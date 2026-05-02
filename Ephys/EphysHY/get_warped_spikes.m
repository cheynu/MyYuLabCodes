function [average_spikes, medianHD, medianMT, spike_counts_warped, raster_info] = get_warped_spikes(r, unit_of_interest, t_pre, t_press_warp, t_release_warp, t_reward_warp, t_post, varargin)
    gaussian_kernel = 50;
    is_channel_number = false;
    is_only_first_session = false;
    t_start = NaN;
    t_end = NaN;
    Foreperiod = 1500;
    for i =1:2:size(varargin, 2)
        switch varargin{i}
            case 'gaussian_kernel'
                gaussian_kernel = varargin{i+1};
            case 'Channel_Number'
                is_channel_number = varargin{i+1};
            case 'onlyFirstSession'
                is_only_first_session = varargin{i+1};
            case 'tStart'
                t_start = varargin{i+1};
            case 'tEnd'
                t_end = varargin{i+1};
            case 'Foreperiod'
                Foreperiod = varargin{i+1};
            otherwise
                error('unknown argument');
        end
    end

    if is_channel_number
        unit_of_interest_new = [];
        for k = 1:size(unit_of_interest,1)
            unit_of_interest_new = [unit_of_interest_new,find(r.Units.SpikeNotes(:,1)==unit_of_interest(k,1) ...
                & r.Units.SpikeNotes(:,2)==unit_of_interest(k,2))];
        end
        unit_of_interest = unit_of_interest_new;
    end
    if isempty(unit_of_interest)
        average_spikes = [];
        medianHD = [];
        medianMT = [];
        spike_counts_warped = [];
        raster_info = [];
        return
    end

    if is_only_first_session
        t_start = get_t_start_session(r,1);
        t_end = get_t_end_session(r,1);
    end
    if isnan(t_start)
        t_start = get_t_start_session(r, 1);
    end
    if isnan(t_end)
        t_end = get_t_end_session(r, length(r.Meta));
    end
    spike_times = cell(length(unit_of_interest),1);
    for k = 1:length(spike_times)
        spike_times{k} = round(r.Units.SpikeTimes(unit_of_interest(k)).timings);
    end

    % pick correct trials and separate long-FP/short-FP trials
    ind_press = find(strcmp(r.Behavior.Labels, 'LeverPress'));
    t_presses = round(r.Behavior.EventTimings(r.Behavior.EventMarkers == ind_press));
    ind_release = find(strcmp(r.Behavior.Labels, 'LeverRelease'));
    t_releases = round(r.Behavior.EventTimings(r.Behavior.EventMarkers == ind_release));
    ind_rewards = find(strcmp(r.Behavior.Labels, 'ValveOnset'));
    t_rewards= round(r.Behavior.EventTimings(r.Behavior.EventMarkers == ind_rewards));

    idx_correct = r.Behavior.CorrectIndex;
    idx_in_time_range = find(t_presses > t_start & t_presses < t_end);
    idx_uncued = find(r.Behavior.CueIndex(:,2)==0);
    
    % exclude short HD and long MT

    idx_included = intersect(idx_correct, idx_in_time_range);
    idx_included = sort(intersect(idx_included, idx_uncued));

    fprintf('%d trials are included!\n', length(idx_included));

    binwidth = 1;
    t_post_border = 5000;
    t_warped = t_pre:t_post;
    t_unwarped = t_pre:t_post+t_post_border;
    spike_counts_warped = NaN(length(t_warped), length(idx_included), length(spike_times));
    
    HD_all = [];
    MT_all = [];
    press_times_all = [];
    release_times_all = [];
    reward_times_all = [];
    tempk = 0;
    for k = 1:length(idx_included)
        kten = floor(k/10);
        if k==1
            fprintf('Trial#%d\n',k);
            ticT = tic;
        elseif kten>tempk
            fprintf('Trial#%d: %.1f seconds from last display\n',k,toc(ticT));
            tempk = kten;
            ticT = tic;
        end

        idx_this = idx_included(k);
        t_press_this = t_presses(idx_this);
        t_release_this = t_releases(idx_this);
        t_foreperiod_this = t_press_this+Foreperiod;

        if t_release_this<t_foreperiod_this
            disp(t_release_this-t_foreperiod_this);
            warning('Wrong release time!');
            continue
        end

        t_reward_this = t_rewards(find(t_rewards>t_release_this, 1));
        if isempty(t_reward_this)
            continue
        end
        if idx_this ~= length(t_presses) && t_reward_this > t_presses(idx_this + 1)
            continue
        end
        if t_reward_this-t_release_this > 3000
            continue
        end
        HD_all = [HD_all, t_release_this-t_foreperiod_this];
        MT_all = [MT_all, t_reward_this-t_release_this];
        press_times_all = [press_times_all, t_press_this];
        release_times_all = [release_times_all, t_release_this];
        reward_times_all = [reward_times_all, t_reward_this];
        
        spike_counts = cell(1, length(spike_times));
        for i_unit = 1:length(spike_times)
            spike_counts_this = zeros(1, length(t_unwarped));
            st = round(spike_times{i_unit}-t_press_this)-t_pre+1;
            st = st(st>0 & st<=length(t_unwarped));

            spike_counts_this(st) = 1;

            spike_counts{i_unit} = spike_counts_this;
        end
        
        t_points_to_warp = [t_press_this, t_release_this, t_reward_this] - t_press_this;
        t_dest = [t_press_warp, t_release_warp, t_reward_warp];
        t_new = t_unwarped;
        for j = 2:length(t_points_to_warp)
            idx0 = findNearestPoint(t_unwarped, t_points_to_warp(j-1));
            idx1 = findNearestPoint(t_unwarped, t_points_to_warp(j));
            t_new(idx1) = t_dest(j);
            if idx0 == idx1
                idx1 = idx0+1;
            end
            % 使用线性插值公式替换 interp1
            x = idx0+1:idx1-1;
            t_new(x) = (t_dest(j-1) * (idx1 - x) + t_dest(j) * (x - idx0)) / (idx1 - idx0);
%             t_new(idx0+1:idx1-1) = interp1([idx0, idx1], [t_dest(j-1), t_dest(j)], idx0+1:idx1-1);
            if j == length(t_points_to_warp)
                t_new(idx1+1:end) = t_new(idx1+1:end) - t_new(idx1+1) + t_new(idx1) + binwidth;
            end
        end
        if t_new(end)<t_post
            error('t_new is too short!');
        end

        for i_unit = 1:length(spike_times)
            spike_counts_warped_this = zeros(1, length(t_warped));
            for j = 1:length(spike_counts_warped_this)
                i = find(t_new >= t_warped(j), 1);
                if t_new(i) == t_warped(j)
                    spike_counts_warped_this(j) = spike_counts{i_unit}(i);
                elseif t_new(i) > t_warped(j)
                    % 使用线性插值公式替换 interp1
                    spike_counts_warped_this(j) = ...
                        spike_counts{i_unit}(i-1) + ...
                        (spike_counts{i_unit}(i) - spike_counts{i_unit}(i-1)) * ...
                        (t_warped(j) - t_new(i-1)) / (t_new(i) - t_new(i-1));
%                     spike_counts_warped_this(j) = interp1([t_new(i-1), t_new(i)], [spike_counts{i_unit}(i-1), spike_counts{i_unit}(i)], t_warped(j));
                end
            end
            spike_counts_warped(:, k, i_unit) = spike_counts_warped_this;
        end
    end
    % remove NaN in spike_counts_warped
    idx_nan = any(squeeze(any(isnan(spike_counts_warped),1)),2);
    spike_counts_warped(:, idx_nan, :) = [];

    % get median HD and MT
    medianHD = median(HD_all);
    medianMT = median(MT_all);

    % Average
    average_spikes = reshape(mean(spike_counts_warped, 2, 'omitnan'), length(t_warped), length(spike_times));

    % Smooth
    for k = 1:size(average_spikes, 2)
        average_spikes(:,k) = smoothdata(average_spikes(:,k), 'gaussian', gaussian_kernel*5/binwidth)*1000;
    end

    % raster
    raster_info.SpikeTimes = spike_times;
    raster_info.PressTimes = press_times_all;
    raster_info.ReleaseTimes = release_times_all;
    raster_info.RewardTimes = reward_times_all;
end