function out = zero2warm
% hbWang 06/13/2023, customized colormap
% (darkblue --> blue --> white --> red --> darkred)
    out = customcolormap(linspace(0,1,6), ...
                {'#f5f9f3', '#fedbc9', '#f7a580', ...
                 '#d75f4e', '#b5172f', '#68011d'});
end