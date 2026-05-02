set(0, 'DefaultAxesFontSize', 7);
try
    set(groot,'defaultAxesFontName','Helvetica')
    set(groot,{'DefaultAxesXColor','DefaultAxesYColor','DefaultAxesZColor'},{'k','k','k'})
    matlab.graphics.internal.setPrintPreferences('DefaultPaperPositionMode','manual')
    set(groot,'defaultFigurePaperPositionMode','manual')
end