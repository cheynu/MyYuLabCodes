function [sdf_out, t] = sdf25(tspk, time_range, sigma, dt, num_trials)
% spike density function, 2025. JY
%
% Inputs:
%   tspk       - Vector of spike times in milliseconds
%   time_range - [start end] in ms, defines the time window for analysis
%   sigma      - Standard deviation of Gaussian kernel (in ms), controls width
%   dt         - Time step for output sdf_out (in ms), e.g., 1 ms
%   num_trials - Number of trials
%
% Output:
%   sdf_out        - Spike Density Function (firing rate in spikes/sec)
%
% Example:
%   tspk = [100, 150, 200, 250]; % Spike times in ms
%   sdf_out = sdf_out25(tspk, [0 500], 20, 1, 1);

% Input validation
if nargin < 5
    num_trials = 1;
    if nargin < 4
        error('All inputs (tspk, time_range, sigma, dt) are required.');
    end
end

if length(time_range) ~= 2 || time_range(1) >= time_range(2)
    error('time_range must be a 2-element vector [start end] with start < end.');
end
if sigma <= 0 || dt <= 0
    error('sigma and dt must be positive.');
end

% Define time vector based on time_range and dt
t_start = round(time_range(1));
t_end = round(time_range(2));
t = t_start:dt:t_end;  % Time points for sdf_out output

if ~isvector(tspk) || isempty(tspk)
    sdf_out = zeros(size(t));
else
    % Initialize sdf_out array
    sdf_out = zeros(size(t));
    bin_edges = t_start-dt/2:dt:t_end+dt/2;

    % Gaussian kernel parameters
    % Kernel size should cover ±3σ for 99.7% of the Gaussian
    kernel_half_width = ceil(4 * sigma);  % In ms
    kernel_t = -kernel_half_width:dt:kernel_half_width;
    gaussian_kernel = (1 / (sigma * sqrt(2 * pi))) * exp(-kernel_t.^2 / (2 * sigma^2));
    % Normalize kernel to ensure area = 1 when scaled to spikes/sec later
    gaussian_kernel = gaussian_kernel / sum(gaussian_kernel);

    % convert tspk to spike train
    spk_train = histcounts(tspk, bin_edges);
    sdf_out = conv(spk_train, gaussian_kernel, 'same');

    % Convert sdf_out to firing rate (spikes/sec)
    sdf_out = sdf_out * (1000 / dt)/num_trials;  % Scale from per-ms to per-second

    to_plot = 0;
    if to_plot

        % Plot the SDF
        figure(47); clf(47)
        plot(t, sdf_out, 'LineWidth', 2);
        hold on;
        stem(tspk, ones(size(tspk)) * max(sdf_out) * 0.1, 'k', 'LineWidth', 1, 'Marker', 'none'); % Spike markers
        xlabel('Time (ms)');
        ylabel('Firing Rate (spikes/sec)');
        title(['Spike Density Function (\sigma = ' num2str(sigma) ' ms)']);
        grid on;
        hold off;
    end
end
end