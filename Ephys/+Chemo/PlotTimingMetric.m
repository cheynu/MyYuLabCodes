function PlotTimingMetric(TimingOut, name)
% Jianing Yu 12/17/2023
% Jianing Yu 12/23/2023
if nargin<2
    name = [];
end

PressMetric = TimingOut.PressMetric;

xnow =2;
plot_width = 2;
plot_height = 3;
plot_height2 = 1.5;
vspacing = 1.3;
uncue_color = [0.7 0.7 0.7];
marker_alpha = 0.25;
marker_size = 3;
fontsize = 7;
xbins       =     (0:0.05:4);
kernel_bw   =     0.08;

FP_colors           =   {'#9BBEC8', '#427D9D', '#164863'};
inactivation_color  =   '#FF6C22';
 
FP_shade_color = [0.3 0.8 0.5];
marker_type = 'o';
FPs = [500 1000 1500]/1000;
FP_Color = FP_colors{3};
ynow = 6;
yrange = [0 3];

%% First, use Bejamini-Houchberg Method to control false discovery rate
% extract all p values
Properties = {'median', 'mean', 'iqr', 'sd', 'mode'};
Types = {'Uncue_FirstHalf', 'Cue_FirstHalf', 'Uncue_SecondHalf', 'Cue_SecondHalf',...
    'Uncue_Whole', 'Cue_Whole'};
pval_all = [];
for i = 1:length(Types)
    for j =1:length(Properties)
        pval_ij = eval(['TimingOut.PressMetric.' Types{i} '.' 'Pval.' Properties{j}]);
        pval_all=[pval_all pval_ij];
    end
end

pval_sort = sort(pval_all);
figure(10); clf(10)
plot([1:length(pval_sort)], pval_sort, 'ko-')
alpha = 0.05;
li = [1:length(pval_sort)]*alpha/length(pval_sort);
hold on
plot([1:length(pval_sort)], li, 'ko-', 'markerfacecolor', 'g')
ind_last = find(pval_sort<li, 1, 'last');
pval_threshold = pval_sort(ind_last);
sprintf('threshold for rejecting null hypotheis: %2.5f', pval_threshold)

text(1, 0.6, sprintf('threshold for rejecting null hypotheis: %2.5f', pval_threshold))

hf = figure(69);
clf(hf)
set(gcf, 'units', 'Centimeters', 'position',[2 2 19.5 16],...
    'Visible','on', 'paperpositionmode', 'auto', 'color', 'w');

% First plot, Uncue (first half)
ha1 = axes('units', 'centimeters', ...
    'position', [xnow, ynow plot_width plot_height], ...
    'ydir','normal','nextplot', 'add', ...
    'xlim',[0.2 2.8], 'ylim', ...
    [0 3]);
ylabel('Hold duration (s)')
type_labels = [ones(1, length(TimingOut.Presses.Uncue_Saline_FirstHalf)) 2*ones(1, length(TimingOut.Presses.Uncue_DCZ_FirstHalf))];
type_responses = [TimingOut.Presses.Uncue_Saline_FirstHalf TimingOut.Presses.Uncue_DCZ_FirstHalf];
% hbox1 = boxplot(type_responses, type_labels, 'outliersize', 4, 'symbol','rx','widths', 0.6);
hviolin = violinplot(type_responses, type_labels);
hviolin(1).ScatterPlot.MarkerFaceColor = FP_Color;
hviolin(2).ScatterPlot.MarkerFaceColor = inactivation_color;
hviolin(1).ScatterPlot.SizeData = marker_size;
hviolin(2).ScatterPlot.SizeData = marker_size;
hviolin(1).ScatterPlot.MarkerFaceAlpha = marker_alpha;
hviolin(2).ScatterPlot.MarkerFaceAlpha = marker_alpha;
hviolin(1).ViolinPlot.FaceColor = 'none';
hviolin(2).ViolinPlot.FaceColor = 'none';
hviolin(1).ViolinPlot.EdgeColor = 'none';
hviolin(2).ViolinPlot.EdgeColor = 'none';
hviolin(1).BoxPlot.FaceColor = 'b';
hviolin(2).BoxPlot.FaceColor = 'b';
hviolin(1).BoxPlot.EdgeColor = 'b';
hviolin(2).BoxPlot.EdgeColor = 'b';
hviolin(1).ShowWhiskers=0;
hviolin(2).ShowWhiskers=0;
hviolin(1).ShowMedian = 0;
hviolin(2).ShowMedian = 0;

% also make box-plot
hbplot = boxplot(type_responses, type_labels, 'symbol', '', ...
    'boxstyle', 'outline','plotstyle', 'compact','medianstyle','line', 'widths', 0.6);
set(hbplot,{'linew'},{1})
h=findobj('LineStyle','--'); set(h, 'LineStyle','-', 'LineWidth', 1, 'color', 'b');

set(ha1, 'xtick', [1 2], 'xticklabel', {'Saline', 'DCZ'}, 'box','off' , ...
    'position', [xnow, ynow plot_width plot_height], 'ylim', yrange)
title('First 1/2(Uncue)', 'fontname', 'dejavu sans','fontsize', 9,'fontweight','bold')
 
%% PDF
ynow_pdf = ynow+plot_height+1.5;
ha1b = axes('units', 'centimeters', ...
    'position', [xnow, ynow_pdf plot_width plot_height2], ...
    'ydir','normal','nextplot', 'add', ...
    'xlim', yrange, 'ylim', ...
    [0 4]);
 
xlabel('Hold duration (s)')
ylabel('Density (1/s)')
PDF_Saline   = TimingOut.PDF_Uncue_Saline_FirstHalf;
PDF_DCZ     = TimingOut.PDF_Uncue_DCZ_FirstHalf;

plotshaded(PDF_Saline(:, 1)', PDF_Saline(:, [3 4])', [.5 .5 .5]);
plot(PDF_Saline(:, 1), PDF_Saline(:, 2), 'color', FP_Color,  'linewidth', 1.5);
% fit a gaussian model
f_Saline_FirstHalf = fit(PDF_Saline(:, 1), PDF_Saline(:, 2), 'gauss1');

plotshaded(PDF_DCZ(:, 1)', PDF_DCZ(:, [3 4])', [.5 .5 .5]);
plot(PDF_DCZ(:, 1), PDF_DCZ(:, 2), 'color', inactivation_color,  'linewidth', 1.5);
f_DCZ_FirstHalf = fit(PDF_DCZ(:, 1), PDF_DCZ(:, 2), 'gauss1');

xnow_pdfinfo = xnow + plot_width+0.15;

ha1info = axes('units', 'centimeters', ...
    'position', [xnow_pdfinfo, ynow_pdf  plot_width plot_height], ...
    'ydir','normal','nextplot', 'add', ...
    'xlim',[0 8], 'ylim', ...
    [0 10], 'yticklabel', []);
text(1, 12,'a*exp(-((x-b)/c)^2)', 'fontname', 'dejavu sans', 'fontsize', 8)
conf_ints_saline = confint(f_Saline_FirstHalf);
text(1, 8, sprintf('Saline:\n a=%2.2f [%2.2f %2.2f]\n b=%2.2f [%2.2f %2.2f]\n c=%2.2f [%2.2f %2.2f]', ...
    f_Saline_FirstHalf.a1, conf_ints_saline(1, 1), conf_ints_saline(2, 1), f_Saline_FirstHalf.b1, ...
    conf_ints_saline(1, 2), conf_ints_saline(2, 2), f_Saline_FirstHalf.c1, conf_ints_saline(1, 3), conf_ints_saline(2, 3)), 'fontname', 'dejavu sans', 'fontsize', 8)

conf_ints_DCZ = confint(f_DCZ_FirstHalf);
text(1, 3, sprintf('DCZ:\n a=%2.2f [%2.2f %2.2f]\n b=%2.2f [%2.2f %2.2f]\n c=%2.2f [%2.2f %2.2f]', ...
    f_DCZ_FirstHalf.a1, conf_ints_DCZ(1, 1), conf_ints_DCZ(2, 1), f_DCZ_FirstHalf.b1, ...
    conf_ints_DCZ(1, 2), conf_ints_DCZ(2, 2), f_DCZ_FirstHalf.c1, conf_ints_DCZ(1, 3), conf_ints_DCZ(2, 3)), 'fontname', 'dejavu sans', 'fontsize', 8)

% mark parameters with non-overlapping ci red
if f_Saline_FirstHalf.a1>f_DCZ_FirstHalf.a1
    if conf_ints_saline(1, 1)>conf_ints_DCZ(2, 1)
        text(1, 0, 'a,', 'color', 'r')
    else
        text(1, 0, 'a,', 'color', 'b')
    end
else
    if conf_ints_saline(2, 1)<conf_ints_DCZ(1, 1)
        text(1, 0, 'a,', 'color', 'r')
    else
        text(1, 0, 'a,', 'color', 'b')
    end
end

if f_Saline_FirstHalf.b1>f_DCZ_FirstHalf.b1
    if conf_ints_saline(1, 2)>conf_ints_DCZ(2, 2)
        text(4, 0, 'b,', 'color', 'r')
    else
        text(4, 0, 'b,', 'color', 'b')
    end
else
    if conf_ints_saline(2, 2)<conf_ints_DCZ(1, 2)
        text(4, 0, 'b,', 'color', 'r')
    else
        text(4, 0, 'b,', 'color', 'b')
    end
end

if f_Saline_FirstHalf.c1>f_DCZ_FirstHalf.c1
    if conf_ints_saline(1, 3)>conf_ints_DCZ(2, 3)
        text(7, 0, 'c,', 'color', 'r')
    else
        text(7, 0, 'c,', 'color', 'b')
    end
else
    if conf_ints_saline(2, 3)<conf_ints_DCZ(1, 3)
        text(7, 0, 'c,', 'color', 'r')
    else
        text(7, 0, 'c,', 'color', 'b')
    end
end

axis off
ynow_pdf=ynow_pdf+plot_height2+0.5;

ha1c = axes('units', 'centimeters', ...
    'position', [xnow, ynow_pdf plot_width plot_height2], ...
    'ydir','normal','nextplot', 'add', ...
    'xlim', yrange, 'ylim', ...
    [0 3]);
plot(PDF_Saline(:, 1), f_Saline_FirstHalf(PDF_Saline(:, 1)), 'color', FP_Color, 'linewidth', 1.5)
plot(PDF_DCZ(:, 1), f_DCZ_FirstHalf(PDF_DCZ(:, 1)), 'color', inactivation_color, 'linewidth', 1.5)
title('First 1/2(Uncue)', 'fontname', 'dejavu sans','fontsize', 9,'fontweight','bold')
 
%% information on median and variance
xnow = xnow+plot_width;
ha1info = axes('units', 'centimeters', ...
    'position', [xnow, ynow-1.5  plot_width plot_height+2], ...
    'ydir','normal','nextplot', 'add', ...
    'xlim',[-2 10], 'ylim', ...
    [-8 10], 'yticklabel', []);
axis off
xnow = xnow+plot_width+1.5;
text(1, 10.5, '~~~~~~~~')
text(1, 9, sprintf('median(saline) \n %2.2f [%2.2f-%2.2f]', PressMetric.Uncue_FirstHalf.ResponseA.median), 'fontname', 'dejavu sans', 'fontsize', fontsize)
text(1, 7, sprintf('median(dcz) \n %2.2f [%2.2f-%2.2f]', PressMetric.Uncue_FirstHalf.ResponseB.median), 'fontname', 'dejavu sans', 'fontsize', fontsize)
this_p = PressMetric.Uncue_FirstHalf.Pval.median;
if this_p<pval_threshold
    fontcol = 'r';
else
    fontcol ='b';
end
if this_p<10^-4
    text(1, 5, sprintf('pval %2.3f****',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color',fontcol)
elseif this_p<10^-3
    text(1, 5, sprintf('pval %2.3f***',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color',fontcol)
elseif this_p<10^-2
    text(1, 5, sprintf('pval %2.3f**',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color',fontcol)
elseif this_p<0.05
    text(1, 5, sprintf('pval %2.3f*',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color',fontcol)
else
    text(1, 5, sprintf('pval %2.3f (n.s.)',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color',fontcol)
end

text(1, 3, sprintf('sd(saline) \n %2.2f [%2.2f-%2.2f]', PressMetric.Uncue_FirstHalf.ResponseA.sd), 'fontname', 'dejavu sans', 'fontsize', fontsize)
text(1, 1, sprintf('sd(dcz) \n %2.2f [%2.2f-%2.2f]', PressMetric.Uncue_FirstHalf.ResponseB.sd), 'fontname', 'dejavu sans', 'fontsize', fontsize)
this_p = PressMetric.Uncue_FirstHalf.Pval.sd;
if this_p<pval_threshold
    fontcol = 'r';
else
    fontcol ='b';
end
if this_p<10^-4
    text(1, -1, sprintf('pval %2.3f****',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color',fontcol)
elseif this_p<10^-3
    text(1, -1, sprintf('pval %2.3f***',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-2
    text(1, -1, sprintf('pval %2.3f**',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color',fontcol)
elseif this_p<0.05
    text(1, -1, sprintf('pval %2.3f*',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
else
    text(1, -1, sprintf('pval %2.3f (n.s.)',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color',fontcol)
end

% add mode
text(1, -3, sprintf('mode(saline) \n %2.2f [%2.2f-%2.2f]', PressMetric.Uncue_FirstHalf.ResponseA.mode), 'fontname', 'dejavu sans', 'fontsize', fontsize)
text(1, -5, sprintf('mode(dcz) \n %2.2f [%2.2f-%2.2f]', PressMetric.Uncue_FirstHalf.ResponseB.mode), 'fontname', 'dejavu sans', 'fontsize', fontsize)
this_p = PressMetric.Uncue_FirstHalf.Pval.mode;
if this_p<pval_threshold
    fontcol = 'r';
else
    fontcol ='b';
end
if this_p<10^-4
    text(1, -7, sprintf('pval %2.3f****',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color',fontcol)
elseif this_p<10^-3
    text(1, -7, sprintf('pval %2.3f***',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-2
    text(1, -7, sprintf('pval %2.3f**',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color',fontcol)
elseif this_p<0.05
    text(1, -7, sprintf('pval %2.3f*',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color',fontcol)
else
    text(1, -7, sprintf('pval %2.3f (n.s.)',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color',fontcol)
end

%% Second plot, Uncue (second half)
ha2 = axes('units', 'centimeters', ...
    'position', [xnow, ynow plot_width plot_height], ...
    'ydir','normal','nextplot', 'add', ...
    'xlim',[0.2 2.8], 'ylim', ...
    [0 3]);
 
type_labels = [ones(1, length(TimingOut.Presses.Uncue_Saline_SecondHalf)) 2*ones(1, length(TimingOut.Presses.Uncue_DCZ_SecondHalf))];
type_responses = [TimingOut.Presses.Uncue_Saline_SecondHalf TimingOut.Presses.Uncue_DCZ_SecondHalf];

hviolin = violinplot(type_responses, type_labels);
hviolin(1).ScatterPlot.MarkerFaceColor = FP_Color;
hviolin(2).ScatterPlot.MarkerFaceColor = inactivation_color;
hviolin(1).ScatterPlot.SizeData = marker_size;
hviolin(2).ScatterPlot.SizeData = marker_size;
hviolin(1).ScatterPlot.MarkerFaceAlpha = marker_alpha;
hviolin(2).ScatterPlot.MarkerFaceAlpha = marker_alpha;
hviolin(1).ViolinPlot.FaceColor = 'none';
hviolin(2).ViolinPlot.FaceColor = 'none';
hviolin(1).ViolinPlot.EdgeColor = 'none';
hviolin(2).ViolinPlot.EdgeColor = 'none';
hviolin(1).BoxPlot.FaceColor = 'b';
hviolin(2).BoxPlot.FaceColor = 'b';
hviolin(1).BoxPlot.EdgeColor = 'b';
hviolin(2).BoxPlot.EdgeColor = 'b';
hviolin(1).ShowWhiskers=0;
hviolin(2).ShowWhiskers=0;
title('Second 1/2(Uncue)', 'fontname', 'dejavu sans','fontsize', 9,'fontweight','bold')
 
% also make box-plot
hbplot = boxplot(type_responses, type_labels, 'symbol', '', ...
    'boxstyle', 'outline','plotstyle', 'compact','medianstyle','line', 'widths', 0.6);
set(hbplot,{'linew'},{1})
h=findobj('LineStyle','--'); set(h, 'LineStyle','-', 'LineWidth', 1, 'color', 'b');
set(ha2,'xtick', [1 2],  'xticklabel', {'Saline', 'DCZ'}, 'box','off' , ...
    'position', [xnow, ynow plot_width plot_height], 'ylim', yrange)
 
%% PDF
ynow_pdf = ynow+plot_height+1.5;
ha1b = axes('units', 'centimeters', ...
    'position', [xnow, ynow_pdf plot_width plot_height2], ...
    'ydir','normal','nextplot', 'add', ...
    'xlim', yrange, 'ylim', ...
    [0 4]);
 xlabel('Hold duration (s)')
PDF_Saline   = TimingOut.PDF_Uncue_Saline_SecondHalf;
PDF_DCZ     = TimingOut.PDF_Uncue_DCZ_SecondHalf;

plotshaded(PDF_Saline(:, 1)', PDF_Saline(:, [3 4])', [.5 .5 .5]);
plot(PDF_Saline(:, 1), PDF_Saline(:, 2), 'color', FP_Color,  'linewidth', 1.5);
% fit a gaussian model
f_Saline_SecondHalf = fit(PDF_Saline(:, 1), PDF_Saline(:, 2), 'gauss1');
plotshaded(PDF_DCZ(:, 1)', PDF_DCZ(:, [3 4])', [.5 .5 .5]);
plot(PDF_DCZ(:, 1), PDF_DCZ(:, 2), 'color', inactivation_color,  'linewidth', 1.5);
f_DCZ_SecondHalf = fit(PDF_DCZ(:, 1), PDF_DCZ(:, 2), 'gauss1');
xnow_pdfinfo = xnow + plot_width+0.15;

ha1info = axes('units', 'centimeters', ...
    'position', [xnow_pdfinfo, ynow_pdf  plot_width plot_height], ...
    'ydir','normal','nextplot', 'add', ...
    'xlim',[0 8], 'ylim', ...
    [0 10], 'yticklabel', []);
text(1, 12,'a*exp(-((x-b)/c)^2)', 'fontname', 'dejavu sans', 'fontsize', 8)
conf_ints_saline = confint(f_Saline_SecondHalf);
text(1, 8, sprintf('Saline:\n a=%2.2f [%2.2f %2.2f]\n b=%2.2f [%2.2f %2.2f]\n c=%2.2f [%2.2f %2.2f]', ...
    f_Saline_SecondHalf.a1, conf_ints_saline(1, 1), conf_ints_saline(2, 1), f_Saline_SecondHalf.b1, ...
    conf_ints_saline(1, 2), conf_ints_saline(2, 2), f_Saline_SecondHalf.c1, conf_ints_saline(1, 3), conf_ints_saline(2, 3)), 'fontname', 'dejavu sans', 'fontsize', 8)
conf_ints_DCZ = confint(f_DCZ_SecondHalf);
text(1, 2.5, sprintf('DCZ:\n a=%2.2f [%2.2f %2.2f]\n b=%2.2f [%2.2f %2.2f]\n c=%2.2f [%2.2f %2.2f]', ...
    f_DCZ_SecondHalf.a1, conf_ints_DCZ(1, 1), conf_ints_DCZ(2, 1), f_DCZ_SecondHalf.b1, ...
    conf_ints_DCZ(1, 2), conf_ints_DCZ(2, 2), f_DCZ_SecondHalf.c1, conf_ints_DCZ(1, 3), conf_ints_DCZ(2, 3)), 'fontname', 'dejavu sans', 'fontsize', 8)

% mark parameters with non-overlapping ci red
if f_Saline_SecondHalf.a1>f_DCZ_SecondHalf.a1
    if conf_ints_saline(1, 1)>conf_ints_DCZ(2, 1)
        text(1, 0, 'a,', 'color', 'r')
    else
        text(1, 0, 'a,', 'color', 'b')
    end
else
    if conf_ints_saline(2, 1)<conf_ints_DCZ(1, 1)
        text(1, 0, 'a,', 'color', 'r')
    else
        text(1, 0, 'a,', 'color', 'b')
    end
end

if f_Saline_SecondHalf.b1>f_DCZ_SecondHalf.b1
    if conf_ints_saline(1, 2)>conf_ints_DCZ(2, 2)
        text(4, 0, 'b,', 'color', 'r')
    else
        text(4, 0, 'b,', 'color', 'b')
    end
else
    if conf_ints_saline(2, 2)<conf_ints_DCZ(1, 2)
        text(4, 0, 'b,', 'color', 'r')
    else
        text(4, 0, 'b,', 'color', 'b')
    end
end

if f_Saline_SecondHalf.c1>f_DCZ_SecondHalf.c1
    if conf_ints_saline(1, 3)>conf_ints_DCZ(2, 3)
        text(7, 0, 'c,', 'color', 'r')
    else
        text(7, 0, 'c,', 'color', 'b')
    end
else
    if conf_ints_saline(2, 3)<conf_ints_DCZ(1, 3)
        text(7, 0, 'c,', 'color', 'r')
    else
        text(7, 0, 'c,', 'color', 'b')
    end
end

axis off
ynow_pdf=ynow_pdf+plot_height2+0.5;
ha1c = axes('units', 'centimeters', ...
    'position', [xnow, ynow_pdf plot_width plot_height2], ...
    'ydir','normal','nextplot', 'add', ...
    'xlim', yrange, 'ylim', ...
    [0 3]);
plot(PDF_Saline(:, 1), f_Saline_SecondHalf(PDF_Saline(:, 1)), 'color', FP_Color, 'linewidth', 1.5)
plot(PDF_DCZ(:, 1), f_DCZ_SecondHalf(PDF_DCZ(:, 1)), 'color', inactivation_color, 'linewidth', 1.5)
title('Second 1/2(Uncue)', 'fontname', 'dejavu sans','fontsize', 9,'fontweight','bold')

xnow = xnow+plot_width;
ha2info = axes('units', 'centimeters', ...
    'position', [xnow, ynow-1.5 plot_width plot_height+2], ...
    'ydir','normal','nextplot', 'add', ...
    'xlim',[-2 10], 'ylim', ...
    [-8 10], 'yticklabel', []);
axis off
xnow = xnow+plot_width+1.5;
text(1, 10.5, '~~~~~~~~')
text(1, 9, sprintf('median(saline) \n %2.2f [%2.2f-%2.2f]', PressMetric.Uncue_SecondHalf.ResponseA.median), ...
    'fontname', 'dejavu sans', 'fontsize', fontsize)
text(1, 7, sprintf('median(dcz) \n %2.2f [%2.2f-%2.2f]', PressMetric.Uncue_SecondHalf.ResponseB.median), ...
    'fontname', 'dejavu sans', 'fontsize', fontsize)
this_p = PressMetric.Uncue_SecondHalf.Pval.median;
if this_p<pval_threshold
    fontcol = 'r';
else
    fontcol ='b';
end
if this_p<10^-4
    text(1, 5, sprintf('pval %2.3f****',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-3
    text(1, 5, sprintf('pval %2.3f***',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-2
    text(1, 5, sprintf('pval %2.3f**',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<0.05
    text(1, 5, sprintf('pval %2.3f*',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
else
    text(1, 5, sprintf('pval %2.3f (n.s.)',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
end

text(1, 3, sprintf('sd(saline) \n %2.2f [%2.2f-%2.2f]', PressMetric.Uncue_SecondHalf.ResponseA.sd), 'fontname', 'dejavu sans', 'fontsize', fontsize)
text(1, 1, sprintf('sd(dcz) \n %2.2f [%2.2f-%2.2f]', PressMetric.Uncue_SecondHalf.ResponseB.sd), 'fontname', 'dejavu sans', 'fontsize', fontsize)
this_p = PressMetric.Uncue_SecondHalf.Pval.sd;
if this_p<pval_threshold
    fontcol = 'r';
else
    fontcol ='b';
end
if this_p<10^-4
    text(1, -1, sprintf('pval %2.3f****',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-3
    text(1, -1, sprintf('pval %2.3f***',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-2
    text(1, -1, sprintf('pval %2.3f**',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<0.05
    text(1, -1, sprintf('pval %2.3f*',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
else
    text(1, -1, sprintf('pval %2.3f (n.s.)',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
end

% add mode
text(1, -3, sprintf('mode(saline) \n %2.2f [%2.2f-%2.2f]', PressMetric.Uncue_SecondHalf.ResponseA.mode), 'fontname', 'dejavu sans', 'fontsize', fontsize)
text(1, -5, sprintf('mode(dcz) \n %2.2f [%2.2f-%2.2f]', PressMetric.Uncue_SecondHalf.ResponseB.mode), 'fontname', 'dejavu sans', 'fontsize', fontsize)
this_p = PressMetric.Uncue_SecondHalf.Pval.mode;
if this_p<pval_threshold
    fontcol = 'r';
else
    fontcol ='b';
end
if this_p<10^-4
    text(1, -7, sprintf('pval %2.3f****',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-3
    text(1, -7, sprintf('pval %2.3f***',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-2
    text(1, -7, sprintf('pval %2.3f**',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<0.05
    text(1, -7, sprintf('pval %2.3f*',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
else
    text(1, -7, sprintf('pval %2.3f (n.s.)',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
end

%% Third plot, Uncue (combined)
ha3 = axes('units', 'centimeters', ...
    'position', [xnow, ynow plot_width plot_height], ...
    'ydir','normal','nextplot', 'add', ...
    'xlim',[0.2 2.8], 'ylim', ...
    [0 3]);
type_labels = [ones(1, length(TimingOut.Presses.Uncue_Saline_Combine)) 2*ones(1, length(TimingOut.Presses.Uncue_DCZ_Combine))];
type_responses = [TimingOut.Presses.Uncue_Saline_Combine TimingOut.Presses.Uncue_DCZ_Combine];
hviolin = violinplot(type_responses, type_labels);
hviolin(1).ScatterPlot.MarkerFaceColor = FP_Color;
hviolin(2).ScatterPlot.MarkerFaceColor = inactivation_color;
hviolin(1).ScatterPlot.SizeData = marker_size;
hviolin(2).ScatterPlot.SizeData = marker_size;
hviolin(1).ScatterPlot.MarkerFaceAlpha = marker_alpha;
hviolin(2).ScatterPlot.MarkerFaceAlpha = marker_alpha;
hviolin(1).ViolinPlot.FaceColor = 'none';
hviolin(2).ViolinPlot.FaceColor = 'none';
hviolin(1).ViolinPlot.EdgeColor = 'none';
hviolin(2).ViolinPlot.EdgeColor = 'none';
hviolin(1).BoxPlot.FaceColor = 'b';
hviolin(2).BoxPlot.FaceColor = 'b';
hviolin(1).BoxPlot.EdgeColor = 'b';
hviolin(2).BoxPlot.EdgeColor = 'b';
hviolin(1).ShowWhiskers=0;
hviolin(2).ShowWhiskers=0;
title('Whole(Uncue)', 'fontname', 'dejavu sans','fontsize', 9,'fontweight','bold')
 
% also make box-plot
hbplot = boxplot(type_responses, type_labels, 'symbol', '', ...
    'boxstyle', 'outline','plotstyle', 'compact','medianstyle','line', 'widths', 0.6);
set(hbplot,{'linew'},{1})
h=findobj('LineStyle','--'); set(h, 'LineStyle','-', 'LineWidth', 1, 'color', 'b');
set(ha3,'xtick', [1 2], 'xticklabel', {'Saline', 'DCZ'}, 'box','off' , ...
    'position', [xnow, ynow plot_width plot_height],'ylim', yrange)

%% PDF
ynow_pdf = ynow+plot_height+1.5;
ha1b = axes('units', 'centimeters', ...
    'position', [xnow, ynow_pdf plot_width plot_height2], ...
    'ydir','normal','nextplot', 'add', ...
    'xlim', yrange, 'ylim', ...
    [0 4]);
 xlabel('Hold duration (s)')
PDF_Saline   = TimingOut.PDF_Uncue_Saline_Combine;
PDF_DCZ     = TimingOut.PDF_Uncue_DCZ_Combine;

plotshaded(PDF_Saline(:, 1)', PDF_Saline(:, [3 4])', [.5 .5 .5]);
plot(PDF_Saline(:, 1), PDF_Saline(:, 2), 'color', FP_Color,  'linewidth', 1.5);
% fit a gaussian model
f_Saline_Combine = fit(PDF_Saline(:, 1), PDF_Saline(:, 2), 'gauss1');
plotshaded(PDF_DCZ(:, 1)', PDF_DCZ(:, [3 4])', [.5 .5 .5]);
plot(PDF_DCZ(:, 1), PDF_DCZ(:, 2), 'color', inactivation_color,  'linewidth', 1.5);
f_DCZ_Combine = fit(PDF_DCZ(:, 1), PDF_DCZ(:, 2), 'gauss1');
xnow_pdfinfo = xnow + plot_width+0.15;

ha1info = axes('units', 'centimeters', ...
    'position', [xnow_pdfinfo, ynow_pdf  plot_width plot_height], ...
    'ydir','normal','nextplot', 'add', ...
    'xlim',[0 8], 'ylim', ...
    [0 10], 'yticklabel', []);
text(1, 12,'a*exp(-((x-b)/c)^2)', 'fontname', 'dejavu sans', 'fontsize', 8)
conf_ints_saline = confint(f_Saline_Combine);
text(1, 8, sprintf('Saline:\n a=%2.2f [%2.2f %2.2f]\n b=%2.2f [%2.2f %2.2f]\n c=%2.2f [%2.2f %2.2f]', ...
    f_Saline_Combine.a1, conf_ints_saline(1, 1), conf_ints_saline(2, 1), f_Saline_SecondHalf.b1, ...
    conf_ints_saline(1, 2), conf_ints_saline(2, 2), f_Saline_Combine.c1, conf_ints_saline(1, 3), conf_ints_saline(2, 3)), 'fontname', 'dejavu sans', 'fontsize', 8)
conf_ints_DCZ = confint(f_DCZ_Combine);
text(1, 2.5, sprintf('DCZ:\n a=%2.2f [%2.2f %2.2f]\n b=%2.2f [%2.2f %2.2f]\n c=%2.2f [%2.2f %2.2f]', ...
    f_DCZ_Combine.a1, conf_ints_DCZ(1, 1), conf_ints_DCZ(2, 1), f_DCZ_Combine.b1, ...
    conf_ints_DCZ(1, 2), conf_ints_DCZ(2, 2), f_DCZ_Combine.c1, conf_ints_DCZ(1, 3), conf_ints_DCZ(2, 3)), 'fontname', 'dejavu sans', 'fontsize', 8)

% mark parameters with non-overlapping ci red
if f_Saline_Combine.a1>f_DCZ_Combine.a1
    if conf_ints_saline(1, 1)>conf_ints_DCZ(2, 1)
        text(1, 0, 'a,', 'color', 'r')
    else
        text(1, 0, 'a,', 'color', 'b')
    end
else
    if conf_ints_saline(2, 1)<conf_ints_DCZ(1, 1)
        text(1, 0, 'a,', 'color', 'r')
    else
        text(1, 0, 'a,', 'color', 'b')
    end
end

if f_Saline_Combine.b1>f_DCZ_Combine.b1
    if conf_ints_saline(1, 2)>conf_ints_DCZ(2, 2)
        text(4, 0, 'b,', 'color', 'r')
    else
        text(4, 0, 'b,', 'color', 'b')
    end
else
    if conf_ints_saline(2, 2)<conf_ints_DCZ(1, 2)
        text(4, 0, 'b,', 'color', 'r')
    else
        text(4, 0, 'b,', 'color', 'b')
    end
end

if f_Saline_Combine.c1>f_DCZ_Combine.c1
    if conf_ints_saline(1, 3)>conf_ints_DCZ(2, 3)
        text(7, 0, 'c,', 'color', 'r')
    else
        text(7, 0, 'c,', 'color', 'b')
    end
else
    if conf_ints_saline(2, 3)<conf_ints_DCZ(1, 3)
        text(7, 0, 'c,', 'color', 'r')
    else
        text(7, 0, 'c,', 'color', 'b')
    end
end

axis off
ynow_pdf=ynow_pdf+plot_height2+0.5;
ha1c = axes('units', 'centimeters', ...
    'position', [xnow, ynow_pdf plot_width plot_height2], ...
    'ydir','normal','nextplot', 'add', ...
    'xlim', yrange, 'ylim', ...
    [0 3]);
plot(PDF_Saline(:, 1), f_Saline_Combine(PDF_Saline(:, 1)), 'color', FP_Color, 'linewidth', 1.5)
plot(PDF_DCZ(:, 1), f_DCZ_Combine(PDF_DCZ(:, 1)), 'color', inactivation_color, 'linewidth', 1.5)
 
title('Whole(Uncue)', 'fontname', 'dejavu sans','fontsize', 9,'fontweight','bold')

%% Info
xnow = xnow+plot_width;
ha3info = axes('units', 'centimeters', ...
    'position', [xnow, ynow-1.5 plot_width plot_height+2], ...
    'ydir','normal','nextplot', 'add', ...
    'xlim',[-2 10], 'ylim', ...
    [-8 10], 'yticklabel', []);
axis off
text(1, 10.5, '~~~~~~~~')
text(1, 9, sprintf('median(saline) \n %2.2f [%2.2f-%2.2f]', PressMetric.Uncue_Whole.ResponseA.median), ...
    'fontname', 'dejavu sans', 'fontsize', fontsize)
text(1, 7, sprintf('median(dcz) \n %2.2f [%2.2f-%2.2f]', PressMetric.Uncue_Whole.ResponseB.median), ...
    'fontname', 'dejavu sans', 'fontsize', fontsize)
this_p = PressMetric.Uncue_Whole.Pval.median;
if this_p<pval_threshold
    fontcol = 'r';
else
    fontcol ='b';
end
if this_p<10^-4
    text(1, 5, sprintf('pval %2.3f****',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-3
    text(1, 5, sprintf('pval %2.3f***',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-2
    text(1, 5, sprintf('pval %2.3f**',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<0.05
    text(1, 5, sprintf('pval %2.3f*',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
else
    text(1, 5, sprintf('pval %2.3f (n.s.)',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
end

text(1, 3, sprintf('sd(saline) \n %2.2f [%2.2f-%2.2f]', PressMetric.Uncue_Whole.ResponseA.sd), ...
    'fontname', 'dejavu sans', 'fontsize', fontsize)
text(1, 1, sprintf('sd(dcz) \n %2.2f [%2.2f-%2.2f]', PressMetric.Uncue_Whole.ResponseB.sd), ...
    'fontname', 'dejavu sans', 'fontsize', fontsize)
this_p = PressMetric.Uncue_Whole.Pval.sd;
if this_p<pval_threshold
    fontcol = 'r';
else
    fontcol ='b';
end
if this_p<10^-4
    text(1, -1, sprintf('pval %2.3f****',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-3
    text(1, -1, sprintf('pval %2.3f***',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-2
    text(1, -1, sprintf('pval %2.3f**',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<0.05
    text(1, -1, sprintf('pval %2.3f*',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
else
    text(1, -1, sprintf('pval %2.3f (n.s.)',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
end

% add mode
text(1, -3, sprintf('mode(saline) \n %2.2f [%2.2f-%2.2f]', PressMetric.Uncue_Whole.ResponseA.mode), 'fontname', 'dejavu sans', 'fontsize', fontsize)
text(1, -5, sprintf('mode(dcz) \n %2.2f [%2.2f-%2.2f]', PressMetric.Uncue_Whole.ResponseB.mode), 'fontname', 'dejavu sans', 'fontsize', fontsize)
this_p = PressMetric.Uncue_Whole.Pval.mode;
if this_p<pval_threshold
    fontcol = 'r';
else
    fontcol ='b';
end
if this_p<10^-4
    text(1, -7, sprintf('pval %2.3f****',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-3
    text(1, -7, sprintf('pval %2.3f***',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-2
    text(1, -7, sprintf('pval %2.3f**',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<0.05
    text(1, -7, sprintf('pval %2.3f*',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
else
    text(1, -7, sprintf('pval %2.3f (n.s.)',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
end

 
%% Next row (Cue)
ynow = ynow -4.5;
xnow =2;
% First plot, Cue (first half)
ha11 = axes('units', 'centimeters', ...
    'position', [xnow, ynow plot_width plot_height], ...
    'ydir','normal','nextplot', 'add', ...
    'xlim',[0.2 2.8], 'ylim', ...
    [0 3]);
ylabel('Hold duration (s)')

type_labels = [ones(1, length(TimingOut.Presses.Cue_Saline_FirstHalf)) 2*ones(1, length(TimingOut.Presses.Cue_DCZ_FirstHalf))];
type_responses = [TimingOut.Presses.Cue_Saline_FirstHalf TimingOut.Presses.Cue_DCZ_FirstHalf];
% hbox1 = boxplot(type_responses, type_labels, 'outliersize', 4, 'symbol','rx','widths', 0.6);
hviolin = violinplot(type_responses, type_labels);
hviolin(1).ScatterPlot.MarkerFaceColor = FP_Color;
hviolin(2).ScatterPlot.MarkerFaceColor = inactivation_color;
hviolin(1).ScatterPlot.SizeData = marker_size;
hviolin(2).ScatterPlot.SizeData = marker_size;
hviolin(1).ScatterPlot.MarkerFaceAlpha = marker_alpha;
hviolin(2).ScatterPlot.MarkerFaceAlpha = marker_alpha;
hviolin(1).ViolinPlot.FaceColor = 'none';
hviolin(2).ViolinPlot.FaceColor = 'none';
hviolin(1).ViolinPlot.EdgeColor = 'none';
hviolin(2).ViolinPlot.EdgeColor = 'none';
hviolin(1).BoxPlot.FaceColor = 'b';
hviolin(2).BoxPlot.FaceColor = 'b';
hviolin(1).BoxPlot.EdgeColor = 'b';
hviolin(2).BoxPlot.EdgeColor = 'b';
hviolin(1).ShowWhiskers=0;
hviolin(2).ShowWhiskers=0;
title('First 1/2(Cue)', 'fontname', 'dejavu sans','fontsize', 9,'fontweight','bold')

% also make box-plot
hbplot = boxplot(type_responses, type_labels, 'symbol', '', ...
    'boxstyle', 'outline','plotstyle', 'compact','medianstyle','line', 'widths', 0.6);
set(hbplot,{'linew'},{1})
h=findobj('LineStyle','--'); set(h, 'LineStyle','-', 'LineWidth', 1, 'color', 'b');
set(ha11, 'xtick', [1 2], 'ylim',[0 3],'xticklabel', {'Saline', 'DCZ'}, 'box','off' , 'position', [xnow, ynow plot_width plot_height])
xnow = xnow+plot_width;

ha11info = axes('units', 'centimeters', ...
    'position', [xnow, ynow-0.75 plot_width plot_height], ...
    'ydir','normal','nextplot', 'add', ...
    'xlim',[-2 10], 'ylim', ...
    [0 10], 'yticklabel', []);
axis off
xnow = xnow+plot_width+1.5;
text(1, 10.5, '~~~~~~~~')
text(1, 9, sprintf('median(saline) \n %2.2f %2.2f-%2.2f', PressMetric.Cue_FirstHalf.ResponseA.median), 'fontname', 'dejavu sans', 'fontsize', fontsize)
text(1, 7, sprintf('median(dcz) \n %2.2f %2.2f-%2.2f', PressMetric.Cue_FirstHalf.ResponseB.median), 'fontname', 'dejavu sans', 'fontsize', fontsize)
this_p = PressMetric.Cue_FirstHalf.Pval.median;
if this_p<pval_threshold
    fontcol = 'r';
else
    fontcol ='b';
end
if this_p<10^-4
    text(1, 5, sprintf('pval %2.3f****',this_p), 'fontname', 'dejavu sans',  'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-3
    text(1, 5, sprintf('pval %2.3f***',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-2
    text(1, 5, sprintf('pval %2.3f**',this_p), 'fontname', 'dejavu sans',  'fontsize', fontsize, 'color', fontcol)
elseif this_p<0.05
    text(1, 5, sprintf('pval %2.3f*',this_p), 'fontname', 'dejavu sans',  'fontsize', fontsize, 'color', fontcol)
else
    text(1, 5, sprintf('pval %2.3f (n.s.)',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
end

text(1, 3, sprintf('sd(saline) \n %2.2f %2.2f-%2.2f', PressMetric.Cue_FirstHalf.ResponseA.sd), 'fontname', 'dejavu sans', 'fontsize', 8)
text(1, 1, sprintf('sd(dcz) \n %2.2f %2.2f-%2.2f', PressMetric.Cue_FirstHalf.ResponseB.sd), 'fontname', 'dejavu sans', 'fontsize', 8)
this_p = PressMetric.Cue_FirstHalf.Pval.sd;
if this_p<pval_threshold
    fontcol = 'r';
else
    fontcol ='b';
end
if this_p<10^-4
    text(1, -1, sprintf('pval %2.3f****',this_p), 'fontname', 'dejavu sans','fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-3
    text(1, -1, sprintf('pval %2.3f***',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-2
    text(1, -1, sprintf('pval %2.3f**',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<0.05
    text(1, -1, sprintf('pval %2.3f*',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
else
    text(1, -1, sprintf('pval %2.3f (n.s.)',this_p), 'fontname', 'dejavu sans','fontsize', fontsize, 'color', fontcol)
end

% Second plot, Cue (second half)
ha22 = axes('units', 'centimeters', ...
    'position', [xnow, ynow plot_width plot_height], ...
    'ydir','normal','nextplot', 'add', ...
    'xlim',[0.2 2.8], 'ylim', ...
    [0 3]);
 
type_labels = [ones(1, length(TimingOut.Presses.Cue_Saline_SecondHalf)) 2*ones(1, length(TimingOut.Presses.Cue_DCZ_SecondHalf))];
type_responses = [TimingOut.Presses.Cue_Saline_SecondHalf TimingOut.Presses.Cue_DCZ_SecondHalf];

hviolin = violinplot(type_responses, type_labels);
hviolin(1).ScatterPlot.MarkerFaceColor = FP_Color;
hviolin(2).ScatterPlot.MarkerFaceColor = inactivation_color;
hviolin(1).ScatterPlot.SizeData = marker_size;
hviolin(2).ScatterPlot.SizeData = marker_size;
hviolin(1).ScatterPlot.MarkerFaceAlpha = marker_alpha;
hviolin(2).ScatterPlot.MarkerFaceAlpha = marker_alpha;
hviolin(1).ViolinPlot.FaceColor = 'none';
hviolin(2).ViolinPlot.FaceColor = 'none';
hviolin(1).ViolinPlot.EdgeColor = 'none';
hviolin(2).ViolinPlot.EdgeColor = 'none';
hviolin(1).BoxPlot.FaceColor = 'b';
hviolin(2).BoxPlot.FaceColor = 'b';
hviolin(1).BoxPlot.EdgeColor = 'b';
hviolin(2).BoxPlot.EdgeColor = 'b';
hviolin(1).ShowWhiskers=0;
hviolin(2).ShowWhiskers=0;
title('Second 1/2(Cue)', 'fontname', 'dejavu sans','fontsize', 9,'fontweight','bold')
 
% also make box-plot
hbplot = boxplot(type_responses, type_labels, 'symbol', '', ...
    'boxstyle', 'outline','plotstyle', 'compact','medianstyle','line', 'widths', 0.6);
set(hbplot,{'linew'},{1})
h=findobj('LineStyle','--'); set(h, 'LineStyle','-', 'LineWidth', 1, 'color', 'b');
set(ha22,'xtick', [1 2],'ylim',[0 3],  'xticklabel', {'Saline', 'DCZ'}, 'box','off' , ...
    'position', [xnow, ynow plot_width plot_height], 'ylim', yrange)
xnow = xnow+plot_width;

ha22info = axes('units', 'centimeters', ...
    'position', [xnow, ynow-0.75 plot_width plot_height], ...
    'ydir','normal','nextplot', 'add', ...
    'xlim',[-2 10], 'ylim', ...
    [0 10], 'yticklabel', []);
axis off
xnow = xnow+plot_width+1.5;
text(1, 10.5, '~~~~~~~~')
text(1, 9, sprintf('median(saline) \n %2.2f [%2.2f-%2.2f]', PressMetric.Cue_SecondHalf.ResponseA.median), ...
    'fontname', 'dejavu sans', 'fontsize', 8)
text(1, 7, sprintf('median(dcz) \n %2.2f [%2.2f-%2.2f]', PressMetric.Cue_SecondHalf.ResponseB.median), ...
    'fontname', 'dejavu sans', 'fontsize', 8)
this_p = PressMetric.Cue_SecondHalf.Pval.median;
if this_p<pval_threshold
    fontcol = 'r';
else
    fontcol ='b';
end
if this_p<10^-4
    text(1, 5, sprintf('pval %2.3f****',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-3
    text(1, 5, sprintf('pval %2.3f***',this_p), 'fontname', 'dejavu sans','fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-2
    text(1, 5, sprintf('pval %2.3f**',this_p), 'fontname', 'dejavu sans','fontsize', fontsize, 'color', fontcol)
elseif this_p<0.05
    text(1, 5, sprintf('pval %2.3f*',this_p), 'fontname', 'dejavu sans','fontsize', fontsize, 'color', fontcol)
else
    text(1, 5, sprintf('pval %2.3f (n.s.)',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
end

text(1, 3, sprintf('sd(saline) \n %2.2f [%2.2f-%2.2f]', PressMetric.Cue_SecondHalf.ResponseA.sd), 'fontname', 'dejavu sans', 'fontsize', 8)
text(1, 1, sprintf('sd(dcz) \n %2.2f [%2.2f-%2.2f]', PressMetric.Cue_SecondHalf.ResponseB.sd), 'fontname', 'dejavu sans', 'fontsize', 8)
this_p = PressMetric.Cue_SecondHalf.Pval.sd;
if this_p<pval_threshold
    fontcol = 'r';
else
    fontcol ='b';
end
if this_p<10^-4
    text(1, -1, sprintf('pval %2.3f****',this_p), 'fontname', 'dejavu sans','fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-3
    text(1, -1, sprintf('pval %2.3f***',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-2
    text(1, -1, sprintf('pval %2.3f**',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<0.05
    text(1, -1, sprintf('pval %2.3f*',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
else
    text(1, -1, sprintf('pval %2.3f (n.s.)',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
end

% Third plot, Cue (combined)
ha33 = axes('units', 'centimeters', ...
    'position', [xnow, ynow-1 plot_width plot_height], ...
    'ydir','normal','nextplot', 'add', ...
    'xlim',[0.2 2.8], 'ylim', ...
    [0 3]);

type_labels = [ones(1, length(TimingOut.Presses.Cue_Saline_Combine)) 2*ones(1, length(TimingOut.Presses.Cue_DCZ_Combine))];
type_responses = [TimingOut.Presses.Cue_Saline_Combine TimingOut.Presses.Cue_DCZ_Combine];
hviolin = violinplot(type_responses, type_labels);
hviolin(1).ScatterPlot.MarkerFaceColor = FP_Color;
hviolin(2).ScatterPlot.MarkerFaceColor = inactivation_color;
hviolin(1).ScatterPlot.SizeData = marker_size;
hviolin(2).ScatterPlot.SizeData = marker_size;
hviolin(1).ScatterPlot.MarkerFaceAlpha = marker_alpha;
hviolin(2).ScatterPlot.MarkerFaceAlpha = marker_alpha;
hviolin(1).ViolinPlot.FaceColor = 'none';
hviolin(2).ViolinPlot.FaceColor = 'none';
hviolin(1).ViolinPlot.EdgeColor = 'none';
hviolin(2).ViolinPlot.EdgeColor = 'none';
hviolin(1).BoxPlot.FaceColor = 'b';
hviolin(2).BoxPlot.FaceColor = 'b';
hviolin(1).BoxPlot.EdgeColor = 'b';
hviolin(2).BoxPlot.EdgeColor = 'b';
hviolin(1).ShowWhiskers=0;
hviolin(2).ShowWhiskers=0;
title('Whole(Cue)', 'fontname', 'dejavu sans','fontsize', 9,'fontweight','bold')
 
% also make box-plot
hbplot = boxplot(type_responses, type_labels, 'symbol', '', ...
    'boxstyle', 'outline','plotstyle', 'compact','medianstyle','line', 'widths', 0.6);
set(hbplot,{'linew'},{1})
h=findobj('LineStyle','--'); set(h, 'LineStyle','-', 'LineWidth', 1, 'color', 'b');
set(ha33,'xtick', [1 2],'ylim',[0 3], 'xticklabel', {'Saline', 'DCZ'}, 'box','off' , ...
    'position', [xnow, ynow plot_width plot_height],'ylim', yrange)
xnow = xnow+plot_width;

ha33info = axes('units', 'centimeters', ...
    'position', [xnow, ynow-0.75 plot_width plot_height], ...
    'ydir','normal','nextplot', 'add', ...
    'xlim',[-2 10], 'ylim', ...
    [0 10], 'yticklabel', []);
axis off
text(1, 10.5, '~~~~~~~~')
text(1, 9, sprintf('median(saline) \n %2.2f [%2.2f-%2.2f]', PressMetric.Cue_Whole.ResponseA.median), ...
    'fontname', 'dejavu sans', 'fontsize', 8)
text(1, 7, sprintf('median(dcz) \n %2.2f [%2.2f-%2.2f]', PressMetric.Cue_Whole.ResponseB.median), ...
    'fontname', 'dejavu sans', 'fontsize', 8)
this_p = PressMetric.Cue_Whole.Pval.median;
if this_p<pval_threshold
    fontcol = 'r';
else
    fontcol ='b';
end
if this_p<10^-4
    text(1, 5, sprintf('pval %2.3f****',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-3
    text(1, 5, sprintf('pval %2.3f***',this_p), 'fontname', 'dejavu sans','fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-2
    text(1, 5, sprintf('pval %2.3f**',this_p), 'fontname', 'dejavu sans','fontsize', fontsize, 'color', fontcol)
elseif this_p<0.05
    text(1, 5, sprintf('pval %2.3f*',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
else
    text(1, 5, sprintf('pval %2.3f (n.s.)',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
end

text(1, 3, sprintf('sd(saline) \n %2.2f [%2.2f-%2.2f]', PressMetric.Cue_Whole.ResponseA.sd), ...
    'fontname', 'dejavu sans', 'fontsize', 8)
text(1, 1, sprintf('sd(dcz) \n %2.2f [%2.2f-%2.2f]', PressMetric.Cue_Whole.ResponseB.sd), ...
    'fontname', 'dejavu sans', 'fontsize', 8)
this_p = PressMetric.Cue_Whole.Pval.sd;
if this_p<pval_threshold
    fontcol = 'r';
else
    fontcol ='b';
end
if this_p<10^-4
    text(1, -1, sprintf('pval %2.3f****',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-3
    text(1, -1, sprintf('pval %2.3f***',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<10^-2
    text(1, -1, sprintf('pval %2.3f**',this_p), 'fontname', 'dejavu sans', 'fontsize', fontsize, 'color', fontcol)
elseif this_p<0.05
    text(1, -1, sprintf('pval %2.3f*',this_p), 'fontname', 'dejavu sans','fontsize', fontsize, 'color', fontcol)
else
    text(1, -1, sprintf('pval %2.3f (n.s.)',this_p), 'fontname', 'dejavu sans','fontsize', fontsize, 'color', fontcol)
end
 
% Mark animal name
% if isempty(name)
%     hui = uicontrol('style', 'text', 'units', 'normalized', 'position', [0.1 0.925 0.4 0.05],...
%         'string', [TimingOut.ANM{1} ' | Timing' ], 'HorizontalAlignment', 'center','BackgroundColor','w', 'fontsize', 10, 'fontweight','bold');
% else
%     hui = uicontrol('style', 'text', 'units', 'normalized', 'position', [0.1 0.925 0.4 0.05],...
%         'string', [TimingOut.ANM{1} ' | Timing | ' name], 'HorizontalAlignment', 'center','BackgroundColor','w', 'fontsize', 10, 'fontweight','bold');
% end
% 
% hui = uicontrol('style', 'text', 'units', 'normalized', 'position', [0.5 0.925 0.25 0.05],...
%     'string', [sprintf('p-val threshold (BH method): %2.5f', pval_threshold) ], 'HorizontalAlignment', 'center','BackgroundColor','w', 'fontsize', 10, 'fontweight','bold');
if isempty(name)
    annotation('textbox', [0.1 0.925 0.4 0.05], ...
        'String', [TimingOut.ANM{1} ' | Timing'], ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', 'w', ...
        'FontSize', 10, ...
        'FontWeight', 'bold', ...
        'EdgeColor', 'none');
else
    annotation('textbox', [0.1 0.925 0.4 0.05], ...
        'String', [TimingOut.ANM{1} ' | Timing | ' name], ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', 'w', ...
        'FontSize', 10, ...
        'FontWeight', 'bold', ...
        'EdgeColor', 'none');
end
annotation('textbox', [0.5 0.925 0.25 0.05], ...
    'String', sprintf('p-val threshold (BH method): %2.5f', pval_threshold), ...
    'HorizontalAlignment', 'center', ...
    'BackgroundColor', 'w', ...
    'FontSize', 10, ...
    'FontWeight', 'bold', ...
    'EdgeColor', 'none');

% save this figure  
fig_folder = fullfile(pwd, 'Figure');
if ~exist(fig_folder, 'dir')
    mkdir(fig_folder)
end

if isempty(name)
    tosavename=  fullfile(fig_folder, 'Fig2_ResponseDistribution');
    saveas(hf, tosavename, 'epsc')
    print (hf,'-dpdf', tosavename)
    print (hf,'-dpng', tosavename)
else
    tosavename=  fullfile(fig_folder, ['Fig2_ResponseDistribution_', name]);
    saveas(hf, tosavename, 'epsc')
    print (hf,'-dpdf', tosavename)
    print (hf,'-dpng', tosavename)
end