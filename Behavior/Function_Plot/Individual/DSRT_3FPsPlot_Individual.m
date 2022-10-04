function h = DSRT_3FPsPlot_Individual(btAll,taskfilter,datefilter)
%% Initiate
switch nargin
    case 2
        % nothing to do
    case 3
        btAll = btAll(datefilter);
    otherwise
        assert(false,'Input variable number is not suitable.');
end
tend_disp_approachs = {'mean-std','mean-bootci','mean-sem','quartile',...
    'geomean-geomad','geomean-bootci'}; 
RT_stat = tend_disp_approachs{2};
%% Data packaging
TBT = table;
for i=1:length(btAll)
    bt = btAll{i}(btAll{i}.Task==string(taskfilter),:);
    LastFP = [NaN;bt.FP(1:end-1)];
    LastOutcome = ["";bt.Outcome(1:end-1)];
    bt_ext = addvars(bt,LastFP,'After','FP');
    bt_ext = addvars(bt_ext,LastOutcome,'After','Outcome');
    TBT = [TBT;bt_ext];
end
date_str = num2str(TBT.Date);
TBT.Date = string(date_str(:,end-3:end));

nType = length(unique(TBT.TrialType));
%% Plot
cDarkGray = [0.2,0.2,0.2];
cGreen = [0.4660 0.6740 0.1880];
cRed = [0.6350 0.0780 0.1840];
cYellow = [0.9290 0.6940 0.1250];
cBlue = [0,0.6902,0.9412];
cOrange = [0.929,0.49,0.192];
cGray = [0.5 0.5 0.5];
cLightGray = [0.8,0.8,0.8];
color_default = cOrange;
color_FP = [cGray;mean([color_default;cGray]);color_default];
color_Outcome = [cGreen;cRed;cYellow];

h = figure(4); clf(h);
switch nType
    case 1
        ind_Cor = find(TBT.Outcome=="Cor");

        FPcat = categorical(TBT.FP);
        FPcat_cor = categorical(TBT.FP(ind_Cor));
        LFPcat_cor = TBT.LastFP(ind_Cor);
        Outcat = categorical(TBT.Outcome);
        LOutcat_cor = TBT.LastOutcome(ind_Cor);
        RT_cor = TBT.RT(ind_Cor);
        
        set(h, 'Name', '3FPsFig','unit', 'centimeters', 'position',[1 1 16 18],...
            'paperpositionmode', 'auto' );
        
        g(1,1) = gramm('x',FPcat_cor,'y',RT_cor,'color',FPcat_cor); % RT-FP 95ci
        g(1,1).stat_summary('type', @(x)compute_stat_summary(x,RT_stat), 'geom',{'bar','black_errorbar'},'width',1.5);
        g(1,1).axe_property('ylim', [0.1 0.5], 'XGrid', 'on', 'YGrid', 'on');
        g(1,1).set_names('x','FP(s)', 'y', 'RT(s)');
        g(1,1).set_order_options('x',unique(FPcat_cor));
        g(1,1).set_color_options('map', color_FP, 'n_color',3,'n_lightness',1);
        g(1,1).set_layout_options('Position',[0 0.66 0.4 0.33]);
        g(1,1).no_legend();

        g(1,2) = gramm('x',FPcat_cor,'y',RT_cor,'color',FPcat_cor); % RT-FP for each LastFP
        g(1,2).facet_grid([], LFPcat_cor);
        g(1,2).stat_summary('type', @(x)compute_stat_summary(x,RT_stat),'geom',{'bar','black_errorbar'},'width',0.6,'dodge',0);
        g(1,2).axe_property('ylim', [0.1 0.5], 'XGrid', 'on', 'YGrid', 'on');
        g(1,2).set_names('x','FP(s)', 'y', 'RT(s)','column', 'LastFP(s)');
        g(1,2).set_order_options('x',unique(FPcat_cor));
        g(1,2).set_color_options('map', color_FP, 'n_color',3,'n_lightness',1);
        g(1,2).set_layout_options('Position',[0.4 0.66 0.6 0.33]);
        g(1,2).no_legend();

        g(2,1) = gramm('x',FPcat_cor,'y',RT_cor,'color',FPcat_cor); % RT-FP violin&boxplot
        g(2,1).stat_violin('normalization','count','fill','edge','dodge',0);
        g(2,1).stat_boxplot('width',0.4);
        g(2,1).axe_property('ylim', [0 0.6], 'YGrid', 'on');
        g(2,1).set_names('x','FP(s)', 'y', 'RT(s)');
        g(2,1).set_order_options('x',unique(FPcat_cor));
        g(2,1).set_color_options('map', color_FP, 'n_color',3,'n_lightness',1);
        g(2,1).set_layout_options('Position',[0 0.33 0.4 0.33]);
        g(2,1).no_legend();

        g(2,2) = gramm('x',TBT.HT); % PressDuration Distribution for each FP
        g(2,2).stat_bin('edges',0:0.05:2.5,'fill','all');
        g(2,2).set_names('x','HT(s)', 'y', 'Count','column', 'FP(s)');
        g(2,2).set_color_options('map', cLightGray, 'n_color',1,'n_lightness',1);
        g(2,2).set_layout_options('Position',[0.4 0.33 0.6 0.33]);

        g(3,1) = gramm('x',cellstr(Outcat),'color',FPcat); % Fraction of every outcome to FP
        g(3,1).stat_bin('normalization','pdf','geom','bar','fill','all','dodge',0.9,'width',0.8);
        g(3,1).axe_property('YGrid', 'on');
        g(3,1).set_names('x','', 'y', 'Fraction','color','FP(s)');
        g(3,1).set_order_options('x',{'Cor','Pre','Late'},'color',unique(FPcat));
        g(3,1).set_color_options('map', color_FP, 'n_color',3,'n_lightness',1);
        g(3,1).set_layout_options('Position',[0 0 0.4 0.33]);

        g(3,2) = gramm('x',FPcat_cor,'y',RT_cor,'color',FPcat_cor); % RT-FP for each Last FP
        g(3,2).facet_grid([], cellstr(LOutcat_cor));
        g(3,2).stat_summary('type', @(x)compute_stat_summary(x,RT_stat),'geom',{'bar','black_errorbar'},'width',0.6,'dodge',0);
        g(3,2).axe_property('ylim', [0.1 0.5], 'XGrid', 'on', 'YGrid', 'on');
        g(3,2).set_names('x','FP(s)', 'y', 'RT(s)', 'column','');
        g(3,2).set_order_options('x',unique(FPcat_cor),'column',{'Cor','Pre','Late'});
        g(3,2).set_color_options('map', color_FP, 'n_color',3,'n_lightness',1);
        g(3,2).set_layout_options('Position',[0.4 0 0.6 0.33]);
        g(3,2).no_legend();

        daterange = unique(TBT.Date);
        g.set_title(TBT.Subject(1)+": 3FPs "+daterange(1)+" - "+daterange(end)+"  ("+RT_stat+")");

        g.draw();

        % Adjust figures 1
        ylim22 = g(2,2).facet_axes_handles(1).YLim;
        g(2,2).update('color',TBT.FP);
        g(2,2).facet_grid([],TBT.FP);
        g(2,2).stat_bin('edges',0:0.05:2.5,'fill','face','dodge',0);
        g(2,2).set_color_options('map', color_FP, 'n_color',3,'n_lightness',1);
        g(2,2).no_legend();

        warning('off');
        g.draw();

        % Adjust figures 2
        obj_cor = findobj(g(3,2).facet_axes_handles(1),'String','Cor');
        obj_pre = findobj(g(3,2).facet_axes_handles(2),'String','Pre');
        obj_late = findobj(g(3,2).facet_axes_handles(3),'String','Late');
        obj_cor.String = 'Post-Cor';
        obj_pre.String = 'Post-Pre';
        obj_late.String = 'Post-Late';

        x22 = [0.5,0.5,1.1,1.1,  1,1,1.6,1.6,  1.5,1.5,2.1,2.1];
        y22 = [0,ylim22(2),ylim22(2),0]; y22 = [y22,y22,y22];
        c22 = [0.5,0.5,0.5,0.5,  1,1,1.0,1.0,  1.5,1.5,1.5,1.5];
        g(2,2).update('x',x22,'y',y22);
        g(2,2).facet_grid([],c22);
        g(2,2).geom_line();
        g(2,2).set_line_options('base_size',1,'styles',{':'});
        g(2,2).set_color_options('map', cDarkGray, 'n_color',1,'n_lightness',1);
        g(2,2).no_legend();

        g.draw();
        warning('on');

    case 2
        % unfinished
    otherwise
        % unfinished
end
%% Save
figName = "3FPs_"+TBT.Subject(1)+"_"+daterange(1)+"-"+daterange(end);
figPath = fullfile(pwd,'IndivFig');
if ~exist(figPath,'dir')
    mkdir(figPath);
end
figFile = fullfile(figPath,figName);
saveas(h, figFile, 'png');
saveas(h, figFile, 'fig');

end

