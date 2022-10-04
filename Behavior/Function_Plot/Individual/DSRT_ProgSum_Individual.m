function progFig = DSRT_ProgSum_Individual(btAll,taskfilter,datefilter)
%% initiate
switch nargin
    case 2
        % nothing to do
    case 3
        btAll = btAll(datefilter);
    otherwise
        assert(false,'Input variable number is not suitable.');
end
%% 
TBT = table;
for i=1:length(btAll)
    TBT = [TBT;btAll{i}];
end
% date, block_length
date_str = num2str(TBT.Date);
TBT.Date = string(date_str(:,end-3:end));

%% Plot
cTab10 = tab10(10);
cTab20 = tab20(20);
cGreen = cTab10(3,:);
cGreen2 = cTab20(5:6,:);
cRed = cTab10(4,:);
cRed2 = cTab20(7:8,:);
cGray = cTab10(8,:);
cGray2 = cTab20(15:16,:);

cCor_Pre_Late = [cGreen;cRed;cGray];
cCor_Pre_Late2 = [cGreen2;cRed2;cGray2];
cCor_Late = [cGreen;cGray];

progFig = figure(2);clf(progFig);
set(progFig,'Name','ProgressSummary','unit', 'centimeters', ...
    'position',[1 1 12 8], 'paperpositionmode', 'auto')

g(1,1) = gramm('x',TBT.TimeElapsed,'y',TBT.iTrial,'group',cellstr(TBT.Date),...
    'color',cellstr(TBT.Outcome),'lightness',cellstr(TBT.TrialType),...
    'subset',TBT.Task==string(taskfilter));
g(1,1).axe_property('xlim',[0 4000],'XGrid', 'on', 'YGrid', 'on');
g(1,1).geom_point('alpha',0.5); g(1,1).set_point_options('base_size',4);
g(1,1).set_names('x','Time(s)','y','Trial#','color','','lightness','','group','');
g(1,1).set_color_options('map',cCor_Pre_Late2,'n_color',3,'n_lightness',2);
g(1,1).set_order_options('color',{'Cor','Pre','Late'},'lightness',{'Lever','Poke'});
g(1,1).set_layout_options('legend_position',[0.38,0.11,0.2,0.3]);

g(1,2) = gramm('x',TBT.TimeElapsed,'y',TBT.iTrial,'group',cellstr(TBT.Date),...
    'color',TBT.BlockNum,'subset',TBT.Task==string(taskfilter));
g(1,2).axe_property('xlim',[0 4000],'XGrid', 'on', 'YGrid', 'on');
g(1,2).geom_line();g(1,2).set_line_options('base_size',1.2);
g(1,2).set_names('x','Time(s)','y','Trial#','group','','color','Block#');
% g(1,2).set_color_options('map',cGray,'n_color',1,'n_lightness',1);
g(1,2).set_continuous_color('colormap','parula');
g(1,2).set_layout_options('legend_position',[0.88,0.07,0.2,0.4]);

nSession = length(unique(TBT.Date(TBT.Task==string(taskfilter))));
g.set_title(TBT.Subject(1)+" "+string(taskfilter)+": "+TBT.Date(1)+"-"+TBT.Date(end)+" ("+nSession+" sessions)");
g.draw();
%% Save
figPath = fullfile(pwd,'IndivFig');
figName = TBT.Subject(1)+"_"+string(taskfilter)+"_"+TBT.Date(1)+"-"+TBT.Date(end);
if ~exist(figPath,'dir')
    mkdir(figPath);
end
figFile = fullfile(figPath,figName);
saveas(progFig, figFile, 'png');
saveas(progFig, figFile, 'fig');

end

