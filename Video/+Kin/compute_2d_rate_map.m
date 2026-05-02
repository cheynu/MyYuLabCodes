function M = compute_2d_rate_map(B, params)
% compute_2d_rate_map
% Compute a 2D occupancy-normalized firing-rate map from binned trajectory data.
%
% INPUT
%   B : table
%       Must contain:
%         - time_bin_start
%         - time_bin_end
%         - spike_count   (unless you want to add it before calling)
%         - x/y columns specified by params.x_col and params.y_col
%
%   params : struct with fields
%       .x_col            : string/char, e.g. 'LeftPaw_x_rel_cm'
%       .y_col            : string/char, e.g. 'LeftPaw_y_rel_cm'
%       .valid_col        : string/char, e.g. 'valid_LeftPaw' (optional)
%       .bin_size_cm      : spatial bin size, e.g. 0.25
%       .min_occ_s        : minimum occupancy (sec) to keep a bin, e.g. 0.06
%       .smooth_sigma_cm  : Gaussian sigma in cm, e.g. 0.35
%       .do_plot          : true/false
%       .plot_title       : optional title
%
%   spike_times_ms : optional, unused here if B.spike_count exists
%                    included only for interface flexibility
%
% OUTPUT
%   M : struct with fields
%       .occ_s
%       .spk
%       .rate_raw_hz
%       .rate_smooth_hz
%       .x_edges
%       .y_edges
%       .x_centers
%       .y_centers
%       .valid_mask
%       .params
%
% NOTES
%   Standard approach:
%     1) accumulate occupancy and spikes in 2D bins
%     2) smooth occupancy and spikes separately
%     3) divide smoothed spike map by smoothed occupancy map
%
% EXAMPLE
%   params = struct();
%   params.x_col = 'LeftPaw_x_rel_cm';
%   params.y_col = 'LeftPaw_y_rel_cm';
%   params.valid_col = 'valid_LeftPaw';
%   params.bin_size_cm = 0.25;
%   params.min_occ_s = 0.06;
%   params.smooth_sigma_cm = 0.35;
%   params.do_plot = true;
%   params.plot_title = 'Left paw rate map';
%
%   M = compute_2d_rate_map(B, params);

    if nargin < 3
        spike_times_ms = []; %#ok<NASGU>
    end

    %-----------------------------
    % defaults
    %-----------------------------
    if ~isfield(params, 'bin_size_cm') || isempty(params.bin_size_cm)
        params.bin_size_cm = 0.25;
    end
    if ~isfield(params, 'min_occ_s') || isempty(params.min_occ_s)
        params.min_occ_s = 0.06;
    end
    if ~isfield(params, 'smooth_sigma_cm') || isempty(params.smooth_sigma_cm)
        params.smooth_sigma_cm = 0.35;
    end
    if ~isfield(params, 'do_plot') || isempty(params.do_plot)
        params.do_plot = false;
    end
    if ~isfield(params, 'plot_title') || isempty(params.plot_title)
        params.plot_title = '';
    end
    if ~isfield(params, 'valid_col')
        params.valid_col = '';
    end

    %-----------------------------
    % checks
    %-----------------------------
    req = ["time_bin_start","time_bin_end","spike_count", string(params.x_col), string(params.y_col)];
    has_req = ismember(req, string(B.Properties.VariableNames));
    if ~all(has_req)
        missing = req(~has_req);
        error('compute_2d_rate_map:MissingColumns', ...
            'B is missing required columns: %s', strjoin(cellstr(missing), ', '));
    end

    x_col = string(params.x_col);
    y_col = string(params.y_col);

    x = B.(x_col);
    y = B.(y_col);
    spk = B.spike_count;
    dt_s = (B.time_bin_end - B.time_bin_start) / 1000;

    %-----------------------------
    % valid rows
    %-----------------------------
    keep = ~isnan(x) & ~isnan(y) & ~isnan(spk) & ~isnan(dt_s);

    if ~isempty(params.valid_col)
        valid_col = string(params.valid_col);
        if ~ismember(valid_col, string(B.Properties.VariableNames))
            error('compute_2d_rate_map:BadValidColumn', ...
                'valid_col "%s" not found in B.', valid_col);
        end
        keep = keep & logical(B.(valid_col));
    end

    x = x(keep);
    y = y(keep);
    spk = spk(keep);
    dt_s = dt_s(keep);

    if isempty(x)
        error('compute_2d_rate_map:NoValidRows', ...
            'No valid rows remained after filtering.');
    end

    %-----------------------------
    % spatial edges
    %-----------------------------
    bs = params.bin_size_cm;

    if isfield(params, 'x_edges') && ~isempty(params.x_edges)
        x_edges = params.x_edges;
    else
        x_min = floor(min(x) / bs) * bs;
        x_max = ceil(max(x) / bs) * bs;
        x_edges = x_min:bs:x_max;

        if numel(x_edges) < 2
            x_edges = [x_min, x_min + bs];
        end
    end

    if isfield(params, 'y_edges') && ~isempty(params.y_edges)
        y_edges = params.y_edges;
    else
        y_min = floor(min(y) / bs) * bs;
        y_max = ceil(max(y) / bs) * bs;
        y_edges = y_min:bs:y_max;

        if numel(y_edges) < 2
            y_edges = [y_min, y_min + bs];
        end
    end

    if any(diff(x_edges) <= 0) || any(diff(y_edges) <= 0)
        error('compute_2d_rate_map:BadEdges', ...
            'x_edges and y_edges must be strictly increasing.');
    end

    x_centers = x_edges(1:end-1) + diff(x_edges)/2;
    y_centers = y_edges(1:end-1) + diff(y_edges)/2;

    %-----------------------------
    % bin assignment
    % histcounts2 uses:
    %   first input -> X dimension (columns)
    %   second input -> Y dimension (rows)
    %-----------------------------
    [occ_counts, ~, ~, x_bin, y_bin] = histcounts2(x, y, x_edges, y_edges);

    % occupancy in seconds
    occ_s = zeros(numel(y_edges)-1, numel(x_edges)-1);
    spk_map = zeros(numel(y_edges)-1, numel(x_edges)-1);

    for i = 1:numel(x)
        xb = x_bin(i);
        yb = y_bin(i);

        if xb < 1 || yb < 1
            continue
        end

        % histcounts2 indexing convention:
        % rows correspond to y bins, columns to x bins
        occ_s(yb, xb) = occ_s(yb, xb) + dt_s(i);
        spk_map(yb, xb) = spk_map(yb, xb) + spk(i);
    end

    % raw rate
    rate_raw_hz = spk_map ./ occ_s;
    rate_raw_hz(occ_s <= 0) = NaN;

    %-----------------------------
    % spatial smoothing
    % smooth spikes and occupancy separately, then divide
    %-----------------------------
    sigma_bins = params.smooth_sigma_cm / params.bin_size_cm;
    G = local_gaussian_kernel_2d(sigma_bins);

    occ_s_smooth = conv2(occ_s, G, 'same');
    spk_smooth = conv2(spk_map, G, 'same');

    rate_smooth_hz = spk_smooth ./ occ_s_smooth;
    rate_smooth_hz(occ_s_smooth <= 0) = NaN;

    % apply minimum occupancy mask
    valid_mask = occ_s >= params.min_occ_s;
    rate_raw_hz(~valid_mask) = NaN;

    valid_mask_smooth = occ_s_smooth >= params.min_occ_s;
    rate_smooth_hz(~valid_mask_smooth) = NaN;

    %-----------------------------
    % output
    %-----------------------------
    M = struct();
    M.occ_s = occ_s;
    M.spk = spk_map;
    M.rate_raw_hz = rate_raw_hz;
    M.rate_smooth_hz = rate_smooth_hz;
    M.occ_s_smooth = occ_s_smooth;
    M.spk_smooth = spk_smooth;
    M.x_edges = x_edges;
    M.y_edges = y_edges;
    M.x_centers = x_centers;
    M.y_centers = y_centers;
    M.valid_mask = valid_mask;
    M.valid_mask_smooth = valid_mask_smooth;
    M.unit_id = B.unit_id{1};
    M.params = params;

    %-----------------------------
    % optional plots
    %-----------------------------
    if params.do_plot
        local_plot_rate_map(M, params);
    end
end


function G = local_gaussian_kernel_2d(sigma_bins)
% Build a normalized 2D Gaussian kernel.
    if sigma_bins <= 0
        G = 1;
        return
    end

    rad = max(1, ceil(3 * sigma_bins));
    x = -rad:rad;
    y = -rad:rad;
    [X, Y] = meshgrid(x, y);

    G = exp(-(X.^2 + Y.^2) / (2 * sigma_bins^2));
    G = G / sum(G(:));
end


function local_plot_rate_map(M, params)

    figure;

    subplot(1,3,1);
    imagesc(M.x_centers, M.y_centers, M.occ_s);
    axis xy equal tight;
    xlabel(string(params.x_col), 'Interpreter', 'none');
    ylabel(string(params.y_col), 'Interpreter', 'none');
    title('Occupancy (s)');
    colorbar;

    subplot(1,3,2);
    imagesc(M.x_centers, M.y_centers, M.spk);
    axis xy equal tight;
    xlabel(string(params.x_col), 'Interpreter', 'none');
    ylabel(string(params.y_col), 'Interpreter', 'none');
    title('Spike count');
    colorbar;

    subplot(1,3,3);
    imagesc(M.x_centers, M.y_centers, M.rate_smooth_hz);
    axis xy equal tight;
    xlabel(string(params.x_col), 'Interpreter', 'none');
    ylabel(string(params.y_col), 'Interpreter', 'none');
    title('Smoothed rate (Hz)');
    colorbar;

    if isfield(params, 'plot_title') && strlength(string(params.plot_title)) > 0
        sgtitle(string(params.plot_title));
    end
end