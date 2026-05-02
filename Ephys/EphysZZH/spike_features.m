function feature_out = spike_features(twave, spkwave, name, savefolder)

if nargin<4
    savefolder = [];
    if nargin<3
        name = 'Unknown';
    end
end

v_baseline = mean(spkwave(twave<0.25));
spkwave = spkwave-v_baseline;
if -min(spkwave)<max(spkwave) % regular spike, negative phase is larger than the  positive phase
    spkwave = - spkwave;
end
[trough, ind_trough] = min(spkwave);
t_trough = twave(ind_trough);

% find peak location (peak must follow trough)

t_block                         =       twave(ind_trough:end);
spk_block                       =       spkwave(ind_trough:end);

[peak, ind_peak ]               =       max(spk_block);
t_peak                          =       t_block(ind_peak);

peak_trough                     =       abs(peak/trough);
t_peak2trough                   =       t_peak-t_trough;

feature_out.peak2trough         =       peak_trough;
feature_out.t_peak2trough       =       t_peak2trough;

feature_out.fwhh = analyze_spike_waveform(twave, spkwave);

if ~isempty(savefolder)
    figure; plot(twave, spkwave)
    title(name)
    line([1 1]*t_trough, [trough 0],'color', 'm', 'linewidth', 1);
    line([1 1]*t_peak, [peak 0],'color', 'r', 'linewidth', 1);

    ylim =get(gca, 'ylim');
    ymin = ylim(1);

    text(twave(end)-0.8, ymin*0.4, ['peak to trough: ' num2str(peak_trough)], 'fontsize', 15)
    text(twave(end)-0.8, ymin*0.2, ['time peak to trough: ' num2str(t_peak2trough)], 'fontsize', 15)
    set(gca, 'XAxisLocation', 'origin', 'YAxisLocation', 'origin', 'box', 'off')

    % save this figure
    tosavename = fullfile(savefolder, [strrep(name, '|', '_') '_wave']);
    print (gcf,'-dpng', tosavename)
end


function [fwhh, trough_amplitude, peak_amplitude] = analyze_spike_waveform(t, v)
    % Input:
    % t - time vector (in ms or s)
    % v - voltage vector (in µV or mV)
    %
    % Output:
    % fwhh - full width at half height (in same units as t)
    % trough_amplitude - amplitude of negative trough
    % peak_amplitude - amplitude of positive peak

    % Find baseline (assuming it's near zero, taking mean of first 10% of data)
    baseline = mean(v(1:floor(length(v)*0.1)));
    
    % Find trough (minimum value)
    [trough_amplitude, trough_idx] = min(v);
    trough_amplitude = trough_amplitude - baseline;
    
    % Find peak after trough (maximum value after trough)
    [peak_amplitude, peak_idx] = max(v(trough_idx:end));
    peak_idx = peak_idx + trough_idx - 1;
    peak_amplitude = peak_amplitude - baseline;
    
    % Calculate half height level
    half_height = baseline + (trough_amplitude / 2);
    
    % Find points where waveform crosses half height
    % Before trough
    pre_crossings = find(diff(sign(v(1:trough_idx) - half_height)) ~= 0);
    if isempty(pre_crossings)
        error('No crossing found before trough');
    end
    t1_idx = pre_crossings(end);
    
    % After trough
    post_crossings = find(diff(sign(v(trough_idx:end) - half_height)) ~= 0);
    if isempty(post_crossings)
        error('No crossing found after trough');
    end
    t2_idx = trough_idx + post_crossings(1);
    
    % Interpolate to get more precise crossing times
    t1 = interp1(v(t1_idx:t1_idx+1), t(t1_idx:t1_idx+1), half_height);
    t2 = interp1(v(t2_idx-1:t2_idx), t(t2_idx-1:t2_idx), half_height);
    
    % Calculate full width at half height
    fwhh = t2 - t1;
end

end
