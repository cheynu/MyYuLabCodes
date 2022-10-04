function DSRT_BlockPlot_Individual(btAll)

% data trial-by-trial
TBT = table;
for i=1:length(btAll)
    TBT = [TBT;btAll{i}(btAll{i}.Task=="Block",:)];
end
% date, block_length
date_str = num2str(TBT.Date);
TBT.Date = string(date_str(:,end-3:end));
block_length = length(unique(TBT.TrialNum));
% BlockOrder for each type
ind_lever = TBT.TrialType == "Lever";
ind_poke  = TBT.TrialType == "Poke";
BlockOrder = TBT.BlockNum./2;
BlockOrder(ind_lever) = ceil(BlockOrder(ind_lever));
BlockOrder(ind_poke) = floor(BlockOrder(ind_poke));
TBT = addvars(TBT, BlockOrder, 'After','BlockNum');
% summarize each trial's confusing try (e.g., poke in lever block) & recent 5 confusing trial
ConfuseNum = double(TBT.ConfuseNum>0);
ConfuseRecent = ConfuseNum + ...
    [0;ConfuseNum(1:end-1)] + ...
    [0;0;ConfuseNum(1:end-2)] + ...
    [0;0;0;ConfuseNum(1:end-3)] + ...
    [0;0;0;0;ConfuseNum(1:end-4)];
TBT = addvars(TBT, ConfuseRecent, 'After','ConfuseNum');
TBT_NoConfuse = table;
[~,iT_date,~] = unique(TBT.Date,'stable');
for i=1:length(iT_date)
    if i==length(iT_date)
        dateT = TBT(iT_date(i):end,:);
    else
        dateT = TBT(iT_date(i):iT_date(i+1)-1,:);
    end
    [~,iT_block,~] = unique(dateT.BlockNum,'stable');
    for j=1:length(iT_block)
        if j==length(iT_block)
            blockT = dateT(iT_block(j):end,:);
        else
            blockT = dateT(iT_block(j):iT_block(j+1)-1,:);
        end
        firstNoConfuse = blockT.TrialNum(find(blockT.TrialNum>=5 ...
            & blockT.ConfuseRecent<=1,1,'first'));
        if isempty(firstNoConfuse) && blockT.TrialNum(end)==block_length
            firstNoConfuse = block_length;
        end
        TBT_NoConfuse = [TBT_NoConfuse;blockT(firstNoConfuse,:)];
    end
end
%% Plot
cDarkGray = [0.2,0.2,0.2];
cBlue = Blues(1); % need this (add to path): https://www.yuque.com/spikes/bnkhly/24304200
maxBlock = 10; % can't exceed 15
cBlock = rainbow(maxBlock);

% Points: day-by-day & task facet_grid

% TrialNum
g(1,1) = gramm('X',categorical(TBT.Date));
g(1,1).facet_grid([], cellstr(TBT.TrialType));
g(1,1).stat_bin('geom','line','normalization','count');
g(1,1).axe_property('ylim', [50 200], 'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'on');
g(1,1).set_names('x',{}, 'y', 'Trials','column', '');
g(1,1).set_color_options('map',cDarkGray,'n_color',1,'n_lightness',1);

% MT
g(2,1) = gramm('X',categorical(TBT.Date),'Y',TBT.MT);
g(2,1).facet_grid([], cellstr(TBT.TrialType));
g(2,1).stat_boxplot('width', 0.4);
g(2,1).axe_property('ylim', [0 5], 'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'on');
g(2,1).set_names('x',{}, 'y', 'MT(s)','column','');
g(2,1).set_color_options('map', cBlue, 'n_color',1,'n_lightness',1);

% HT
g(3,1) = gramm('X',categorical(TBT.Date),'Y',TBT.RT);% RT ≈ HT in Block task
g(3,1).facet_grid([], cellstr(TBT.TrialType));
g(3,1).stat_boxplot('width', 0.4);
g(3,1).axe_property('ylim', [0 2], 'xticklabels', {}, 'XGrid', 'on', 'YGrid', 'on');
g(3,1).set_names('x',{}, 'y', 'HT(s)','column','');
g(3,1).set_color_options('map', cBlue, 'n_color',1,'n_lightness',1);

% Switch criterion trial
% x: Date, y: criterion trial, color: block num
% criterion trial: the first trial# in which at least 4 non-confusing try in recent 5 trials in a block
g(4,1) = gramm('X',categorical(TBT_NoConfuse.Date),'Y',TBT_NoConfuse.TrialNum,'Color',TBT_NoConfuse.BlockOrder);
g(4,1).facet_grid([], cellstr(TBT_NoConfuse.TrialType));
g(4,1).geom_jitter('width',0.4,'height',0,'dodge',0);
g(4,1).axe_property('ylim', [5 block_length], 'XGrid', 'on', 'YGrid', 'on',...
    'XTickLabelRotation',90);
g(4,1).set_color_options('map',cBlock,'n_color',maxBlock,'n_lightness',1);
g(4,1).set_names('x',{}, 'y', 'Trial2Cri','column','','color','Block');

g.set_title(TBT.Subject(1)+": Block");

figure('Name','BlockFig','unit', 'centimeters', 'position',[1 1 18 20], 'paperpositionmode', 'auto')

g.draw();
%% Save
figName = "BlockPerformance_" + TBT.Subject(1) + "_" + TBT.Date(1) + "-" + TBT.Date(end);
figPath = fullfile(pwd,'AnalysisFig');
if ~exist(figPath,'dir')
    mkdir(figPath);
end
figFile = fullfile(figPath,figName);
saveas(gcf, figFile, 'png');
saveas(gcf, figFile, 'fig');

end

