function hAnn = addAxisCornerLabel(ax, str, varargin)
% addAxisCornerLabel  Place a label at an axes corner using annotation textbox (cm units).
%
%   hAnn = addAxisCornerLabel(ax, str)
%   hAnn = addAxisCornerLabel(ax, str, 'Name', value, ...)
%
% Name-value options (all in centimeters):
%   'Corner'  : 'topleft' (default) | 'topright' | 'bottomleft' | 'bottomright'
%   'Offset'  : [dx dy] cm (default [0 0.4])
%   'BoxSize' : [w h]  cm (default [2.0 0.4])
%
% Any extra name-value pairs are passed to annotation('textbox',...).

% --- parse inputs
p = inputParser;
p.addRequired('ax', @(x) isgraphics(x,'axes'));
p.addRequired('str', @(s) ischar(s) || isstring(s));
p.addParameter('Corner','topleft', @(s) any(strcmpi(s, ...
    {'topleft','topright','bottomleft','bottomright'})));
p.addParameter('Offset',[0 0.4], @(v) isnumeric(v) && numel(v)==2);
p.addParameter('BoxSize',[3.0 0.4], @(v) isnumeric(v) && numel(v)==2);
p.KeepUnmatched = true;
p.parse(ax, str, varargin{:});

corner  = lower(p.Results.Corner);
offset  = p.Results.Offset;   % cm
boxsize = p.Results.BoxSize;  % cm

fig = ancestor(ax,'figure');

% --- get axes position in cm, relative to figure
oldAxUnits  = ax.Units;
oldFigUnits = fig.Units;

ax.Units  = 'centimeters';
fig.Units = 'centimeters';

axpos = ax.Position;   % [x y w h] in cm (figure coordinates)

% restore units
ax.Units  = oldAxUnits;
fig.Units = oldFigUnits;

% --- compute textbox position in cm (figure coordinates)
switch corner
    case 'topleft'
        x0 = axpos(1);
        y0 = axpos(2) + axpos(4);
        pos = [x0 + offset(1), y0 + offset(2) - boxsize(2), boxsize(1), boxsize(2)];

    case 'topright'
        x0 = axpos(1) + axpos(3);
        y0 = axpos(2) + axpos(4);
        pos = [x0 + offset(1) - boxsize(1), y0 + offset(2) - boxsize(2), boxsize(1), boxsize(2)];

    case 'bottomleft'
        x0 = axpos(1);
        y0 = axpos(2);
        pos = [x0 + offset(1), y0 + offset(2), boxsize(1), boxsize(2)];

    case 'bottomright'
        x0 = axpos(1) + axpos(3);
        y0 = axpos(2);
        pos = [x0 + offset(1) - boxsize(1), y0 + offset(2), boxsize(1), boxsize(2)];
end

% --- create annotation textbox
hAnn = annotation(fig, 'textbox', ...
    'Units', 'centimeters', ...
    'Position', pos, ...
    'String', char(str), ...
    'Interpreter', 'none', ...
    'FitBoxToText', 'off', ...
    'LineStyle', 'none', ...
    'EdgeColor', 'none', ...
    'BackgroundColor', 'none', ...
    'Color', [0 0 0], ...
    'FontSize', 7, ...
    'FontWeight', 'bold', ...
    'FontName', 'DejaVu Sans', ...
    'VerticalAlignment', 'middle');

% pass through any extra properties (e.g., 'Color', 'FontSize', etc.)
unmatched = p.Unmatched;
if ~isempty(fieldnames(unmatched))
    set(hAnn, unmatched);
end
end
