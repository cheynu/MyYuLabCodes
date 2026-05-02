function h = plotComparePeakDistribution(pdataIndiv,tarDelay,options)

arguments
    pdataIndiv
    tarDelay
    options.targetTreatment = {'Saline','DCZ'}
    options.plotRange = [];
    options.onlyQualifiedTrials = false;
    options.figNameSuffix char = ''
    options.figSaveFolder char = ''
end
treatName = options.targetTreatment;
plotRange = options.plotRange;
ifPlotQualified = options.onlyQualifiedTrials;
figNameSuffix = options.figNameSuffix;
figSaveFolder = options.figSaveFolder;

if ~isempty(plotRange)
    pdataIndiv = pdataIndiv(plotRange);
end
if ~isempty(figNameSuffix)
    suffix = ['_' figNameSuffix];
else
    suffix = '';
end
%% Processing data
ANM = pdataIndiv{1}.ANM;

Times_Saline = [];
Times_DCZ = [];
lastI = 1;
for i=1:length(pdataIndiv)
    pdata = pdataIndiv{i};
    treat = pdata.Treatment;
    delay = pdata.Delay;
    if delay~=tarDelay
        continue;
    end

    pokeHistPI = pdata.PokeHist.PI;
    if ifPlotQualified
        pokeHistPI = pokeHistPI(pdata.idxGoodPI,:);
    end

    if strcmp(treat,treatName{1})
        Times_Saline = [Times_Saline; pokeHistPI];
        lastI = i;
    elseif strcmp(treat,treatName{2})
        Times_DCZ = [Times_DCZ; pokeHistPI];
        lastI = i;
    else
        % pass
    end
end

dt = pdataIndiv{lastI}.Options.binWidth;
maxT = pdataIndiv{lastI}.Options.maxAnalysisTime;
edges = linspace(0, maxT, maxT*(1/dt)+1);

%% Plot
h = figure(31); clf(h);
set(h, 'unit', 'centimeters', 'position',[2 2 10 10], 'paperpositionmode', 'auto',...
'renderer','Painters');

hLine = [];
hLine(1) = plotSummary(treatName{1},Times_Saline,{'#021526','#E2E2B6'},'-');
if ~isempty(Times_DCZ)
    hLine(end+1) = plotSummary(treatName{2},Times_DCZ,{'#3572ef','#a7e6ff'},'-.');
end
xlabel('Time (s)')
ylabel('Pokes/s')
title([ANM suffix]);
legend(hLine,treatName);
legend('boxoff');

tosavename = fullfile(pwd,figSaveFolder, ['PeakIntervalDistribution_' ANM suffix]);
print(h,'-dpng', tosavename);

function h_line = plotSummary(Name_Manipu,Times_Saline,colors,linestyle)
    Times_Saline_mean = smoothdata(mean(Times_Saline), 'gaussian', 15);
    if size(Times_Saline,1)>2
        Times_Saline_ci = smoothdata(bootci(1000, @mean, Times_Saline), 2, 'gaussian', 15);
    else
        disp(['Samples of the ' Name_Manipu ' was less than 3. Using sem instead of 95ci\n']);
        Times_Saline_ci = repmat(smoothdata(std(Times_Saline,1)./sqrt(size(Times_Saline,1)),2,'gaussian',15),[2 1]).*[-1; 1]+Times_Saline_mean;
    end 
    peak_saline = max(Times_Saline_mean);
    
    [Width_Saline,hfPkRise,hfPkFall] = myFWHM(edges,Times_Saline_mean,'minPeakDistance',5);

    line([hfPkRise hfPkFall], peak_saline*0.5*[1 1], 'color', 'r','linestyle',linestyle);
    fprintf(['Width at half peak (' Name_Manipu ') is %2.2f\n'], Width_Saline);
    fprintf(['Midpoint of half peak (' Name_Manipu ') is %2.2f\n'], mean([hfPkRise hfPkFall],'all'));

    ind_plot = find(~isnan(Times_Saline_ci(1, :)));
    plotshaded(edges(ind_plot), Times_Saline_ci(:, ind_plot), hex2rgb(colors{2})); hold on
    h_line = plot(edges, Times_Saline_mean, 'color', colors{1}, 'linewidth', 1.5);
    
end

end