function title_string = set_fig_title(fig, title_text, varargin)


% parsing input
P = inputParser;

addRequired(P, 'fig', @isobject);
addRequired(P, 'title_text', @(x) isstring(x) || ischar(x));

addParameter(P, 'FontSize', 11, @isnumeric);
addParameter(P, 'FontWeight', 'bold', @(x) ismember(x, {'bold', 'normal'}));
addParameter(P, 'FontColor', 'k');
addParameter(P, 'BackColor', 'none');

parse(P, fig, title_text, varargin{:})

fig = P.Results.fig;
title_text = P.Results.title_text;
font_size = P.Results.FontSize;
font_weight = P.Results.FontWeight;
font_color = P.Results.FontColor;
back_color = P.Results.BackColor;

fig.Units = "centimeters";
w = fig.Position(3);
h = fig.Position(4);

ax = axes(fig, 'Units', 'centimeters', 'Position', [.5 h-1 w-1 1], ...
    'Color', back_color, 'XColor', 'none', 'YColor', 'none', ...
    'XLim', [-1 1], 'YLim', [-1 1]);

title_string = text(ax, 0, 0, title_text, 'FontSize', font_size, 'FontWeight', font_weight, 'Color', font_color, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');

end