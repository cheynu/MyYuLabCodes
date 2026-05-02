function S = compute_sparseness(t_array, sdf_out, bin_size)
% COMPUTE_SPARSENESS - Compute lifetime sparseness from spike times and SDF
%
% Inputs:
%   t_spikes - Vector of spike times (in ms)
%   sdf - Vector of spike density function values (in Hz), sampled at dt
%   bin_size - Size of bins for sparseness calculation (in seconds, default  100 ms)

% Output:
%   S - Lifetime sparseness (0 to 1)

% JY 2025

if nargin < 4
    bin_size = 100; % 100 ms default bin size
end

if ~iscell(sdf_out);
    sdf_out = {sdf_out};
    t_array = {t_array};
end

S = zeros(1, length(t_array));

for kk = 1:length(t_array)

    k_t_array = t_array{kk};
    k_sdf = sdf_out{kk};

    dt = k_t_array(2)-k_t_array(1);

    % Number of bins (100 ms bins)
    N = floor(((k_t_array(end)-k_t_array(1)) / bin_size)/dt);

    % Bin the SDF into 100 ms bins by averaging
    rr = NaN*ones(1, N);
   
    for j = 1:N

        start_idx = floor((j-1) * bin_size) + 1;
        end_idx = floor(j * bin_size);    
        rr(j) = mean(k_sdf(start_idx:end_idx)); % Average SDF over bin

    end

    % Compute sparseness
    sum_r = sum(rr);
    sum_r_squared = sum(rr.^2);
    mean_r = sum_r / N;
    mean_r_squared = sum_r_squared / N;

    S(kk) = (1 - (mean_r^2 / mean_r_squared)) / (1 - 1/N);
end
end
