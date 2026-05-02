function plot2dmap_side(M, map_name, opts)
% plot2dmap_side
% Plot a 2D map from compute_2d_rate_map output M, with masked bins in black.
%
% INPUT
%   M         : struct from compute_2d_rate_map
%   map_name  : string/char, e.g.
%               'occ_s', 'spk', 'spk_smooth', 'rate_raw_hz', 'rate_smooth_hz'
%   opts      : optional struct with fields
%       .ax            : target axes handle
%       .reverse_y     : true/false, default true
%       .xlim          : x limits, e.g. [-2 12]
%       .ylim          : y limits, e.g. [-2 6]
%       .title         : custom title
%       .colormap      : colormap name or Nx3 matrix, default parula
%       .mask_color    : RGB for masked bins, default [0 0 0]
%       .use_smooth_mask: true/false, default auto
%
% OUTPUT
%   ax        : axes handle
%
% EXAMPLE
%   subplot(2,1,2)
%   plot2dmap_side(M, 'spk_smooth');

    if nargin < 3
        opts = struct();
    end

    if ~isfield(opts, 'reverse_y') || isempty(opts.reverse_y)
        opts.reverse_y = true;
    end
    if ~isfield(opts, 'mask_color') || isempty(opts.mask_color)
        opts.mask_color = [0 0 0];
    end
    if ~isfield(opts, 'colormap') || isempty(opts.colormap)
        opts.colormap = parula;
    end
    if ~isfield(opts, 'tosave') || isempty(opts.tosave)
        opts.tosave = false;
    end

    if ~isfield(opts, 'range') || isempty(opts.range)
        opts.range = [];
    end

    if ~isfield(M, map_name)
        error('M does not contain field "%s".', map_name);
    end

    if isfield(opts, 'ax') && ~isempty(opts.ax)
        ax = opts.ax;
        axes(ax);
    else
        ax = gca;
    end

    Z = M.(map_name);

    % choose which mask to use
    if isfield(opts, 'use_smooth_mask') && ~isempty(opts.use_smooth_mask)
        use_smooth_mask = opts.use_smooth_mask;
    else
        use_smooth_mask = contains(string(map_name), "smooth");
    end

    if use_smooth_mask && isfield(M, 'valid_mask_smooth')
        mask = ~M.valid_mask_smooth;
    elseif isfield(M, 'valid_mask')
        mask = ~M.valid_mask;
    else
        mask = isnan(Z);
    end

    % mask invalid bins as NaN so underlying black image shows through
    Zplot = Z;
    Zplot(mask) = NaN;

    hold(ax, 'on');

    % actual map first
    if isempty(opts.range)
        hMap = imagesc(ax, M.x_centers, M.y_centers, Zplot);
    else
        hMap = imagesc(ax, M.x_centers, M.y_centers, Zplot, opts.range);
    end

    colormap(ax, opts.colormap);
    hold(ax, 'on');

    % black RGB image on top
    mask_rgb = ones([size(Z), 3]);   % all black
    hMask = image(ax, M.x_centers, M.y_centers, mask_rgb);

    % only show masked bins
    set(hMask, 'AlphaData', double(mask));
   
    if opts.reverse_y
        set(ax, 'YDir', 'reverse');
    end

    if isfield(opts, 'xlim') && ~isempty(opts.xlim)
        set(ax, 'XLim', opts.xlim);
    end
    if isfield(opts, 'ylim') && ~isempty(opts.ylim)
        set(ax, 'YLim', opts.ylim);
    end

    xlabel(ax, 'x (cm)');
    ylabel(ax, 'y (cm)');

    if isfield(opts, 'title') && ~isempty(opts.title)
        title(ax, opts.title, 'FontName', 'Helvetica', 'FontSize', 6, 'Interpreter', 'none');
    else
        title(ax, strrep(map_name, '_', '\_'), 'FontName', 'Helvetica', 'FontSize', 6);
    end

    box(ax, 'on');

    if opts.plot_bar
        hbar = colorbar(ax);
        hbar.Label.String = strrep(map_name, '_', '\_');
        hbar.Units = 'centimeters';
        hbar.Position(1) = ax.Position(1)+ax.Position(3)+0.25;
        hbar.Position(2) = ax.Position(2);
        hbar.Position(3) = 0.25;
        hbar.Position(4) = ax.Position(4);
    end
 
end