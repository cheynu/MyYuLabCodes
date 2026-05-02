function out = zero2cold
% hbWang 06/13/2023, customized colormap
% (darkblue --> blue --> white --> red --> darkred)
    out = customcolormap(linspace(0,1,6), ...
                {'#f5f9f3','#d5e2f0','#93c5dc', ...
                '#4295c1','#2265ad','#062e61'});
end