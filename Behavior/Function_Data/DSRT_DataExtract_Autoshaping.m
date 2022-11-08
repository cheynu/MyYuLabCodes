function bt = DSRT_DataExtract_Autoshaping(filename,plotmark,path_arc)

switch nargin
    case 1
        plotmark = true;
        path_arc = pwd;
    case 2
        path_arc = pwd;
    case 3
        if ~isfolder(path_arc)
            path_arc = pwd;
        end
    otherwise
        error('Invalid input argument number');
end

load(filename);
data = SessionData;

% get sbj name and session date from filename
dname = split(string(filename), '_');
newName = dname(1);
newDate = str2double(dname(5));
Tstart = str2double(datestr(data.Info.SessionStartTime_MATLAB,'HHMMSS'));
newTask = dname(4);
nTrials = data.nTrials;
cellCustom = struct2cell(data.Custom);
for i=1:length(cellCustom)
    if nTrials > length(cellCustom{i})
        nTrials = length(cellCustom{i});
        display(newName+"_"+newTask+"_"+newDate+"_CustomTrials ~= nTrials");
    end
end

Name = repelem(newName,nTrials)';
Date = repelem(newDate,nTrials)';
StartTime = repelem(Tstart,nTrials)';
Task = repelem(newTask,nTrials)';
iTrial = (1:nTrials)';

TimeElapsed = data.Custom.TimeElapsed(1:nTrials)'; % start press or poke: wait4tone(1)
TimeElapsed(TimeElapsed>1e4) = NaN;
FI = [];
Outcome = data.Custom.OutcomeCode(1:nTrials)';
MT = data.Custom.MovementTime(1:nTrials)';

for i = 1:nTrials
    FI = [FI; diff(data.RawEvents.Trial{1,i}.States.WaitForLED)];
end

nOutcome = string(Outcome);
nOutcome(Outcome==1) = repelem("Valid",sum(Outcome==1))';
nOutcome(Outcome==0) = repelem("Invalid",sum(Outcome==0))';

tablenames = {'Subject','Date','StartTime','Task','iTrial','TimeElapsed',...
    'FI','Outcome','MT'};
bt = table(Name,Date,StartTime,Task,iTrial,TimeElapsed,...
    FI,nOutcome,MT,...
    'VariableNames',tablenames);

savename = 'B_' + upper(newName) + '_' + strrep(num2str(newDate), '-', '_') + '_' +...
    strrep(data.Info.SessionStartTime_UTC,':', '');
save(savename,'bt');
%% Plot progress
col_perf = [85  225   0
            255   0   0
            140 140 140]/255;
cTab10 = [0.0901960784313726,0.466666666666667,0.701960784313725;0.960784313725490,0.498039215686275,0.137254901960784;0.152941176470588,0.631372549019608,0.278431372549020;0.843137254901961,0.149019607843137,0.172549019607843;0.564705882352941,0.403921568627451,0.674509803921569;0.549019607843137,0.337254901960784,0.290196078431373;0.847058823529412,0.474509803921569,0.698039215686275;0.501960784313726,0.501960784313726,0.501960784313726;0.737254901960784,0.745098039215686,0.196078431372549;0.113725490196078,0.737254901960784,0.803921568627451];
cBlue = cTab10(10,:);
cGreen = cTab10(3,:);
cGray = cTab10(8,:);
cDark = [0 0 0];
cWhite = [1,1,1];

qLim = [0.12,6]; % qualified trials criterion

if plotmark
    progFig = figure(20); clf(20)
    set(progFig, 'unit', 'centimeters', 'position',[2 2 9 10], 'paperpositionmode', 'auto', 'color', 'w')
    
    plotsize1 = [6, 3.5];
    plotsize2 = [3, 3.5];
    
    dd = num2str(bt.Date(1)); ss = num2str(bt.StartTime(1));
    tt = datetime([dd,'-',ss],'InputFormat','yyyyMMdd-HHmmss');
    uicontrol(progFig,'Style', 'text', 'units', 'normalized',...
        'position', [0.17 0.94 0.7 0.05],...
        'string', append(bt.Subject(1),' / ',datestr(tt,31)), 'fontweight', 'bold',...
        'backgroundcolor', [1 1 1]);
    
    % MT-t
    ymax = 60;ymin = 0.1;
    ha1 = axes;
    set(ha1, 'units', 'centimeters', 'position', [1.5 5.5, plotsize1],...
        'nextplot', 'add', 'ylim', [ymin ymax], 'xlim', [1 4200],...
        'yscale', 'log','tickdir','out');
    xlabel('Time in session (sec)')
    ylabel('Movement time (sec)')
    
    btMT = bt(~isnan(bt.MT),:);
    btMT.MT(btMT.MT>ymax) = ymax;
    btMT.MT(btMT.MT<ymin) = ymin;
    idxVal = bt.MT>qLim(1) & bt.MT<qLim(2);
    idxInv = isnan(bt.MT) | bt.MT<=qLim(1) | bt.MT>=qLim(2);
    newOutc = repelem("",length(bt.Outcome))';
    newOutc(idxVal) = "Valid";
    newOutc(idxInv) = "Invalid";
    btn = addvars(bt,newOutc,'NewVariableNames','criOutcome');

    fill([0,4200,4200,0],[qLim(1),qLim(1),qLim(2),qLim(2)],cGreen,'EdgeColor','none','FaceAlpha',0.2);

    line([bt.TimeElapsed(idxInv),bt.TimeElapsed(idxInv)], [ymin ymin+0.04], 'color',cDark, 'linewidth', 0.4); % invalid trial
    line([bt.TimeElapsed(idxVal),bt.TimeElapsed(idxVal)], [ymin+0.04 ymin+0.1], 'color',cBlue, 'linewidth', 0.4); % valid trial
    line([0 4200],[median(btMT.MT),median(btMT.MT)],'linestyle','--','color',cDark,'linewidth',1.5);
    scatter(btMT.TimeElapsed,btMT.MT,...
        30, cGreen,'o','Markerfacealpha', 0.9, 'linewidth', 1.1);
    
    text(4200,median(btMT.MT),{'median',sprintf('%.1f(s)',median(btMT.MT))},'FontSize',8);
    text(4200,ymin+0.13,sprintf('Qualif %.0f',sum(strcmp(btn.criOutcome,'Valid'))),'FontSize',8,'color',cBlue.*0.8);
    text(4200,ymin+0.03,sprintf('Unqual %.0f',sum(strcmp(btn.criOutcome,'Invalid'))),'FontSize',8);
    
    % sliding performance
    [x1,y1] = calMovAVG(btn.TimeElapsed,btn.Outcome,...
        'winRatio',6,'stepRatio',3,'tarStr','Valid');
    [x2,y2] = calMovAVG(btn.TimeElapsed,btn.criOutcome,...
        'winRatio',6,'stepRatio',3,'tarStr','Valid');
    ha2 = axes;
    set(ha2, 'units', 'centimeters', 'position', [1.5 1, plotsize1],...
        'nextplot', 'add', 'ylim', [0 100], 'xlim', [1 4200],...
        'yscale', 'linear','tickdir','out');
    xlabel('Time in session (sec)')
    ylabel('Performance (%)')

    mperf1 = 100.*sum(strcmp(btn.Outcome,'Valid'))./length(btn.Outcome);
    line([0 4200],[mperf1,mperf1],...
        'linestyle','--','color',cGreen,'linewidth',1.5);
    plot(x1, y1, 'o', 'linestyle', '-', 'color', cGreen, ...
        'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', cGreen,...
        'markeredgecolor', 'w');
    text(4200,mperf1,sprintf('mean %.0f%%',mperf1),...
        'FontSize',8,'color',cGreen.*0.8);
    
    mperf2 = 100.*sum(strcmp(btn.criOutcome,'Valid'))./length(btn.criOutcome);
    line([0 4200],[mperf2,mperf2],...
        'linestyle','--','color',cBlue,'linewidth',1.5);
    plot(x2, y2, 'o', 'linestyle', '-', 'color', cBlue, ...
        'markersize', 5, 'linewidth', 1.2, 'markerfacecolor', cBlue,...
        'markeredgecolor', 'w');
    text(4200,mperf1-max([mperf1-mperf2,8]),sprintf('mean %.0f%%',mperf2),...
        'FontSize',8,'color',cBlue.*0.8);
%%
    figPath = fullfile(path_arc,'ProgFig',newName);
    if ~exist(figPath,'dir')
        mkdir(figPath);
    end
    figFile = fullfile(figPath,savename);
    saveas(progFig, figFile, 'fig');
    print(progFig,'-dpng',figFile);
%     print(progFig,'-dpdf',figFile,'-bestfit');
end

end