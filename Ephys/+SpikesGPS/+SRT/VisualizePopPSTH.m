function [IndSort, fig] = VisualizePopPSTH(Pop, order_info, tosave)
% Pop = PopOut;
% 5/14/2023 revised JY

% IndSort = PSTHOut.IndSort;
% IndSignificant = PSTHOut.IndSignificant;
% nsig = sum(IndSignificant);

if nargin<2
    order_info = 'Each';
    tosave = true;
elseif nargin<3
    tosave = true;
end

%%
% visualize PSTH (z score)
zrange = [-4 4];
n_unit = size(Pop.Units, 1);

[nFP, nPort] = size(Pop.CentIn);
FPs = Pop.FPs * 1000;
switch Pop.ImplantLateral
    case 'L'
        Ports = {'Left | Ipsi', 'Right | Contra'};
    case 'R'
        Ports = {'Left | Contra', 'Right | Ipsi'};
end

%%
% order by contra side
switch lower(order_info)
    case 'contra'
        order_info = 'Contra';
        switch Pop.ImplantLateral
            case 'L'
                orderby = [2 2];
                order_note = 'Ordered by (1.5s, contra/right) trials';
            case 'R'
                orderby = [1 1];
                order_note = 'Ordered by (1.5s, contra/left) trials';
        end
    case 'ipsi'
        order_info = 'Ipsi';
        switch Pop.ImplantLateral
            case 'L'
                orderby = [1 1];
                order_note = 'Ordered by (1.5s, ipsi/left) trials';
            case 'R'
                orderby = [2 2];
                order_note = 'Ordered by (1.5s, ipsi/right) trials';
        end
    case 'left'
        order_info = 'Left';
        orderby = [1 1];
        order_note = 'Ordered by (1.5s, left) trials';
    case 'right'
        order_info = 'Right';
        orderby = [2 2];
        order_note = 'Ordered by (1.5s, right) trials';
    case 'each'
        order_info = 'Each';
        orderby = [1 2];
        order_note = 'Ordered by 1.5s trials for each port';
end

fprintf("\n************* %s *************\n", order_note);
IndSort = Pop.IndSort(orderby);
nsig = n_unit - length(Pop.IndUnmodulated);

%% Set colors
c_centin    = [5 191 219]/255;
c_trigger   = [219 5 191]/255;
c_centout   = [1 1 1];
c_reward    = [1 1 1];
c_centout_z = [0 0 0];
c_reward_z  = [0 0 0];

%%
CentInPSTHs  = cell(size(Pop.CentIn));
CentInPSTHZs = cell(size(Pop.CentIn));
tCentInPSTHs = cell(size(Pop.CentIn));
CentOutPSTHZs = cell(size(Pop.CentOut));
CentOutPSTHs  = cell(size(Pop.CentOut));
tCentOutPSTHs = cell(size(Pop.CentOut));
TriggerPSTHs  = cell(size(Pop.CentOut));
TriggerPSTHZs = cell(size(Pop.CentOut));
tTriggerPSTHs = cell(size(Pop.CentOut));
RewardPSTHs  = cell(size(Pop.Reward));
RewardPSTHZs = cell(size(Pop.Reward));
tRewardPSTHs = cell(size(Pop.Reward));

%%
for ifp = 1:nFP
    for jport = 1:nPort
        % Cent-In
        tCentInPSTHs{ifp, jport} = Pop.CentInZ{ifp, jport}(1, :);
        thisPSTH                 = Pop.CentInZ{ifp, jport}(2:end, :);
        CentInPSTHZs{ifp, jport} = thisPSTH(IndSort{jport}, :);
        thisPSTH                 = Pop.CentIn{ifp, jport}(2:end, :);
        CentInPSTHs{ifp, jport}  = thisPSTH(IndSort{jport}, :);

        % Cent-Out
        tCentOutPSTHs{ifp, jport} = Pop.CentOutZ{ifp, jport}(1, :);
        thisPSTH                  = Pop.CentOutZ{ifp, jport}(2:end, :);
        CentOutPSTHZs{ifp, jport} = thisPSTH(IndSort{jport}, :);
        thisPSTH                  = Pop.CentOut{ifp, jport}(2:end, :);
        CentOutPSTHs{ifp, jport}  = thisPSTH(IndSort{jport}, :);

        % Trigger
        tTriggerPSTHs{ifp, jport} = Pop.TriggerZ{ifp, jport}(1, :);
        thisPSTH                  = Pop.TriggerZ{ifp, jport}(2:end, :);
        TriggerPSTHZs{ifp, jport} = thisPSTH(IndSort{jport}, :);
        thisPSTH                  = Pop.Trigger{ifp, jport}(2:end, :);
        TriggerPSTHs{ifp, jport}  = thisPSTH(IndSort{jport}, :);

        % Reward
        tRewardPSTHs{ifp, jport} = Pop.Reward{ifp, jport}(1, :);
        thisPSTH                 = Pop.RewardZ{ifp, jport}(2:end, :);
        RewardPSTHZs{ifp, jport} = thisPSTH(IndSort{jport}, :);
        thisPSTH                 = Pop.Reward{ifp, jport}(2:end, :);
        RewardPSTHs{ifp, jport}  = thisPSTH(IndSort{jport}, :);
    end
end

%% Concatenate raw PSTH for computing normalized PSTHs
PSTH_Concatenate = cell(nFP, nPort);
PSTH_ConNorm = cell(nFP, nPort);
IndCentIn  =  cell(nFP, nPort);
IndCentOut = cell(nFP, nPort);
IndReward  = cell(nFP, nPort);
norm_range = [0 1];

for ifp = 1:nFP
    for jport = 1:nPort
        % concatenate events for each condition
        PSTH_Concatenate{ifp, jport} = [CentInPSTHs{ifp, jport} CentOutPSTHs{ifp, jport} RewardPSTHs{ifp, jport}];
        % normalize by range for each condition
        PSTH_ConNorm{ifp, jport} = normalize(PSTH_Concatenate{ifp, jport}' , 'range', norm_range);
        PSTH_ConNorm{ifp, jport} = PSTH_ConNorm{ifp, jport}';
        % get the index for each condition
        IndCentIn{ifp, jport}  = 1:size(CentInPSTHs{ifp, jport}, 2);
        IndCentOut{ifp, jport} = IndCentIn{ifp, jport}(end) + (1:size(CentOutPSTHs{ifp, jport}, 2));
        IndReward{ifp, jport}  = IndCentOut{ifp, jport}(end) + (1:size(RewardPSTHs{ifp, jport}, 2));
    end
end

%% Plot
set_matlab_default;
% colormap for z-scored PSTH (red-white-blue)
zcolormap = customcolormap(linspace(0,1,11), {'#68011d','#b5172f','#d75f4e','#f7a580','#fedbc9','#f5f9f3','#d5e2f0','#93c5dc','#4295c1','#2265ad','#062e61'});
% visualize PSTH
hf = 48;
fig = figure(hf); clf(hf)
set(fig, 'unit', 'centimeters', 'position', [2 2 24 20], 'paperpositionmode', 'auto' ,'color', 'w')
size_factor = 1.2;
w_space = 0.1;
h_space = 0.5;

% A. Plot range normalize
xlevel_start = 1.25;
xlevel_now   = xlevel_start;
ylevel_start = 2;
map_height   = 3;

for jport = 1:nPort
    % CentIn
    tRange = [tCentInPSTHs{ifp, jport}(1) 2000];
    Width  = size_factor*diff(tRange)/2000;
    for ifp = 1:nFP
        ha_centin(ifp) = axes('unit', 'centimeters', 'position',...
            [xlevel_now ylevel_start+(map_height+h_space)*(ifp-1) Width map_height], 'nextplot', 'add',...
            'xlim', tRange, 'xtick', -3500:500:2000,...
            'ylim', [0.5 n_unit+0.5], 'ydir', 'reverse', 'ticklength', [0.025 0.01], 'XTickLabelRotation', 90);
        if ifp > 1
            set(ha_centin(ifp), 'xticklabel', [])
        else
            ylabel('Units')
        end
        if jport > 1
            yticklabels([]);
            ylabel([]);
        end
        CentInPSTH_thisFP = PSTH_ConNorm{ifp, jport}(:, IndCentIn{ifp, jport});
        imagesc(tCentInPSTHs{ifp, jport}, 1:n_unit, CentInPSTH_thisFP, norm_range);
        colormap('Parula')
        yrange = [0.5 n_unit+0.5];
        line([0 0], yrange, 'color', c_centin, 'linestyle', ':', 'linewidth', 1.5);
        line([0 0]+FPs(ifp), yrange, 'color', c_trigger, 'linestyle', ':', 'linewidth', 1.5)
        fill([get(gca, 'xlim') flip(get(gca, 'xlim'))], [nsig+.5 nsig+.5 n_unit+0.5 n_unit+0.5], 'w', 'FaceColor', 'w', 'EdgeColor', 'none', 'FaceAlpha', .75);
        if jport==1
            title(sprintf('FP=%2.0dms, Ntrials=%2.0d', FPs(ifp), Pop.Trials(ifp, jport)));
        else
            title(sprintf('Ntrials=%2.0d', Pop.Trials(ifp, jport)));
        end
    end
    ylevel_now = ylevel_start+(map_height+h_space)*nFP;
    % uicontrol('Style','text','Units','centimeters','Position',[xlevel_now+Width-.5 ylevel_now 6 0.5],...
    %     'string', Ports{jport}, ...
    %     'FontName','Dejavu Sans',  'fontweight', 'bold','fontsize', 9,'BackgroundColor',[1 1 1],...
    %     'HorizontalAlignment','Left');
    annotation('textbox', ...
        'Units', 'centimeters', ...
        'Position', [xlevel_now+Width-.5 ylevel_now 6 0.5], ...
        'String', Ports{jport}, ...
        'FontName', 'Dejavu Sans', ...
        'FontWeight', 'bold', ...
        'FontSize', 9, ...
        'BackgroundColor', [1 1 1], ...
        'HorizontalAlignment', 'left', ...
        'EdgeColor', 'none');
    if jport==1
        % uicontrol('Style','text','Units','centimeters','Position',[xlevel_start-1 ylevel_now+0.75 6 0.5],...
        %     'string', 'A. Normalized activity ([0-1])', ...
        %     'FontName','Dejavu Sans',  'fontweight', 'bold','fontsize', 9,'BackgroundColor',[1 1 1],...
        %     'HorizontalAlignment','Left');
        annotation('textbox', ...
            'Units', 'centimeters', ...
            'Position', [xlevel_start-1 ylevel_now+0.75 6 0.5], ...
            'String', 'A. Normalized activity ([0-1])', ...
            'FontName', 'Dejavu Sans', ...
            'FontWeight', 'bold', ...
            'FontSize', 9, ...
            'BackgroundColor', [1 1 1], ...
            'HorizontalAlignment', 'left', ...
            'EdgeColor', 'none');
    end
    xlevel_now = xlevel_now + Width + w_space;

    % Cent-Out
    tRange = [-500 tCentOutPSTHs{1}(end)];
    Width  = size_factor*diff(tRange)/2000;
    for ifp =1:nFP
        ha_centout(ifp) = axes('unit', 'centimeters', 'position',...
            [xlevel_now ylevel_start+(map_height+h_space)*(ifp-1)  Width map_height],...
            'nextplot', 'add', 'xlim', tRange, 'xtick', -500:500:2000,'ytick', [], 'yticklabel', [],...
            'ylim', [0.5 n_unit+0.5], 'ydir', 'reverse', 'ticklength', [0.025 0.01], 'XTickLabelRotation', 90);
        if ifp > 1
            set(ha_centout(ifp), 'xticklabel', []);
        elseif jport==1
            xlabel('From CentIn / CentOut / Reward (ms)');
        end
        if jport > 1
            yticklabels([]);
            ylabel([]);
        end
        ReleasePSTH_thisFP = PSTH_ConNorm{ifp, jport}(:, IndCentOut{ifp, jport});
        imagesc(tCentOutPSTHs{ifp, jport}, 1:n_unit, ReleasePSTH_thisFP, norm_range);
        colormap('Parula')
        yrange = [0.5 n_unit+0.5];
        line([0 0], yrange, 'color', c_centout, 'linestyle', ':', 'linewidth', 1.5);
        fill([get(gca, 'xlim') flip(get(gca, 'xlim'))], [nsig+.5 nsig+.5 n_unit+0.5 n_unit+0.5], 'w', 'FaceColor', 'w', 'EdgeColor', 'none', 'FaceAlpha', .75);
    end
    xlevel_now = xlevel_now + Width + w_space;

    % Reward
    tRange = [-500 tRewardPSTHs{1}(end)];
    Width  = size_factor*diff(tRange)/2000;
    for ifp =1:nFP
        ha_reward(ifp) = axes('unit', 'centimeters', 'position',...
            [xlevel_now ylevel_start+(map_height+h_space)*(ifp-1) Width map_height],...
            'nextplot', 'add', 'xlim', tRange, 'xtick', -500:500:2000,'ytick', [], 'yticklabel', [],...
            'ylim', [0.5 n_unit+0.5], 'ydir', 'reverse', 'ticklength', [0.025 0.01], 'XTickLabelRotation', 90);
        if ifp >1
            set(ha_reward(ifp), 'xticklabel', [])
        end
        if jport > 1
            yticklabels([]);
            ylabel([]);
        end
        RewardPSTH_thisFP = PSTH_ConNorm{ifp, jport}(:, IndReward{ifp, jport});
        imagesc(tRewardPSTHs{ifp, jport}, 1:n_unit, RewardPSTH_thisFP, norm_range);
        colormap('Parula')
        yrange = [0.5 n_unit+0.5];
        line([0 0], yrange, 'color', c_reward, 'linestyle', ':', 'linewidth', 1.5);
        fill([get(gca, 'xlim') flip(get(gca, 'xlim'))], [nsig+.5 nsig+.5 n_unit+0.5 n_unit+0.5], 'w', 'FaceColor', 'w', 'EdgeColor', 'none', 'FaceAlpha', .75);
    end
    xlevel_now = xlevel_now + Width + 2*w_space;
end
% ylevel_now = ylevel_start+(map_height+0.5)*(nFP-1)+map_height+0.5;
xloc = get(gca, 'position');
xboundbar = sum(xloc([1, 3]))+w_space;
% add color bar
hcbar = colorbar('location', 'eastoutside');
set(hcbar, 'units', 'centimeters', 'position', [xboundbar, ylevel_start, 0.25 3], 'TickDirection', 'out', 'ticklength', 0.025)
hcbar.Label.String = 'normalized';
hcbar.Label.FontSize = 9;

%% B. Plot z scores
xlevel_start = xboundbar+2.5;
xlevel_now   = xlevel_start;

for jport = 1:nPort
    % Cent-In
    tRange = [tCentInPSTHs{1}(1) 2000];
    Width  = size_factor*diff(tRange)/2000;
    for ifp = 1:nFP
        ha_centin(ifp) = axes('unit', 'centimeters', 'position',...
            [xlevel_now ylevel_start+(map_height+h_space)*(ifp-1) Width map_height], 'nextplot', 'add',...
            'xlim', tRange, 'xtick', -3500:500:2000,...
            'ylim', [0.5 n_unit+0.5], 'ydir', 'reverse', 'ticklength', [0.025 0.01], 'XTickLabelRotation', 90);
        colormap(ha_centin(ifp), zcolormap);
        if ifp >1
            set(ha_centin(ifp), 'xticklabel', [])
        else
            ylabel('Units')
        end
        if jport > 1
            yticklabels([]);
            ylabel([]);
        end
        imagesc(tCentInPSTHs{ifp, jport}, 1:n_unit, CentInPSTHZs{ifp, jport}, 'AlphaData', ~isnan(CentInPSTHZs{ifp, jport}),zrange);% clim(zrange);
        yrange = [0.5 n_unit+0.5];
        line([0 0], yrange, 'color', c_centin, 'linestyle', ':', 'linewidth', 1.5);
        line([0 0]+FPs(ifp), yrange, 'color', c_trigger, 'linestyle', ':', 'linewidth', 1.5)
        fill([get(gca, 'xlim') flip(get(gca, 'xlim'))], [nsig+.5 nsig+.5 n_unit+0.5 n_unit+0.5], 'w', 'FaceColor', 'w', 'EdgeColor', 'none', 'FaceAlpha', .75);
        if jport==1
            title(sprintf('FP=%2.0dms, Ntrials=%2.0d', FPs(ifp), Pop.Trials(ifp, jport)));
        else
            title(sprintf('Ntrials=%2.0d', Pop.Trials(ifp, jport)));
        end
    end
    ylevel_now = ylevel_start+(map_height+h_space)*nFP;
    % uicontrol('Style','text','Units','centimeters','Position',[xlevel_now+Width-.5 ylevel_now 6 0.5],...
    %     'string', Ports{jport}, ...
    %     'FontName','Dejavu Sans',  'fontweight', 'bold','fontsize', 9,'BackgroundColor',[1 1 1],...
    %     'HorizontalAlignment','Left');
    annotation('textbox', ...
        'Units', 'centimeters', ...
        'Position', [xlevel_now+Width-.5 ylevel_now 6 0.5], ...
        'String', Ports{jport}, ...
        'FontName', 'Dejavu Sans', ...
        'FontWeight', 'bold', ...
        'FontSize', 9, ...
        'BackgroundColor', [1 1 1], ...
        'HorizontalAlignment', 'left', ...
        'EdgeColor', 'none');
    if jport==1
        % uicontrol('Style','text','Units','centimeters','Position',[xlevel_start-1 ylevel_now+0.75 6 0.5],...
        %     'string', ['B. z-scored activity [' num2str(zrange(1)) '-' num2str(zrange(2)) ']'], ...
        %     'FontName','Dejavu Sans',  'fontweight', 'bold','fontsize', 9,'BackgroundColor',[1 1 1],...
        %     'HorizontalAlignment','Left');
        annotation('textbox', ...
            'Units', 'centimeters', ...
            'Position', [xlevel_start-1 ylevel_now+0.75 6 0.5], ...
            'String', ['B. z-scored activity [' num2str(zrange(1)) '-' num2str(zrange(2)) ']'], ...
            'FontName', 'Dejavu Sans', ...
            'FontWeight', 'bold', ...
            'FontSize', 9, ...
            'BackgroundColor', [1 1 1], ...
            'HorizontalAlignment', 'left', ...
            'EdgeColor', 'none');
    end
    xlevel_now = xlevel_now + Width+w_space;

    % Cent-Out
    tRange = [-600 tCentOutPSTHs{1}(end)];
    Width  = size_factor*diff(tRange)/2000;
    for ifp =1:nFP
        ha_centout(ifp) = axes('unit', 'centimeters', 'position',...
            [xlevel_now ylevel_start+(map_height+0.5)*(ifp-1)  Width map_height],...
            'nextplot', 'add', 'xlim', tRange, 'xtick', -500:500:2000,'ytick', [], 'yticklabel', [],...
            'ylim', [0.5 n_unit+0.5], 'ydir', 'reverse', 'ticklength', [0.025 0.01], 'XTickLabelRotation', 90);
        colormap(ha_centout(ifp), zcolormap);
        if ifp >1
            set(ha_centout(ifp), 'xticklabel', [])
        elseif jport==1
            xlabel('From CentIn / CentOut / Reward (ms)');
        end
        if jport > 1
            yticklabels([]);
            ylabel([]);
        end
        imagesc(tCentOutPSTHs{ifp, jport} , 1:n_unit,  CentOutPSTHZs{ifp, jport}, 'AlphaData', ~isnan(CentOutPSTHZs{ifp, jport}),zrange); %clim(zrange);
        yrange = [0.5 n_unit+0.5];
        line([0 0], yrange, 'color', c_centout_z, 'linestyle', ':', 'linewidth', 1.5);
        fill([get(gca, 'xlim') flip(get(gca, 'xlim'))], [nsig+.5 nsig+.5 n_unit+0.5 n_unit+0.5], 'w', 'FaceColor', 'w', 'EdgeColor', 'none', 'FaceAlpha', .75);
    end
    xlevel_now = xlevel_now + Width+w_space;

    % Reward
    tRange = [-1000 tRewardPSTHs{1}(end)];
    Width  = size_factor*diff(tRange)/2000;
    for ifp =1:nFP
        ha_reward(ifp) = axes('unit', 'centimeters', 'position',...
            [xlevel_now ylevel_start+(map_height+0.5)*(ifp-1)  Width map_height],...
            'nextplot', 'add', 'xlim', tRange, 'xtick', -500:500:2000,'ytick', [], 'yticklabel', [],...
            'ylim', [0.5 n_unit+0.5], 'ydir', 'reverse', 'ticklength', [0.025 0.01], 'XTickLabelRotation', 90);
        colormap(ha_reward(ifp), zcolormap);
        if ifp >1
            set(ha_reward(ifp), 'xticklabel', [])
        end
        if jport > 1
            yticklabels([]);
            ylabel([]);
        end
        imagesc(tRewardPSTHs{ifp, jport}, 1:n_unit, RewardPSTHZs{ifp, jport}, 'AlphaData', ~isnan(RewardPSTHZs{ifp, jport}),zrange); %clim(zrange);
        yrange = [0.5 n_unit+0.5];
        line([0 0], yrange, 'color', c_reward_z, 'linestyle', ':', 'linewidth', 1.5);
        fill([get(gca, 'xlim') flip(get(gca, 'xlim'))], [nsig+.5 nsig+.5 n_unit+0.5 n_unit+0.5], 'w', 'FaceColor', 'w', 'EdgeColor', 'none', 'FaceAlpha', .75);
    end

    xlevel_now = xlevel_now + Width + 2 * w_space;
end
xloc = get(gca, 'position');
xboundbar = sum(xloc([1, 3]))+0.1;

% add color bar
hcbar = colorbar('location', 'eastoutside');
set(hcbar, 'units', 'centimeters', 'position', [xboundbar, ylevel_start, 0.25 3], 'TickDirection', 'out', 'ticklength', 0.025)
hcbar.Label.String = 'z score';
hcbar.Label.FontSize = 9;

ylevel_now = ylevel_start + (map_height+0.5)*nFP + 2.5;

%% Add information
% figure title
% uicontrol('Style','text','Units','centimeters','Position', [1 ylevel_now 6 1],...
%     'string', Pop.Name+' | '+strrep(Pop.Session, '_', '-'), ...
%     'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 12,'BackgroundColor','w')

% uicontrol('Style','text','Units','centimeters','Position', [1 ylevel_now-.75 6 1],...
%     'string', order_note, ...
%     'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 9,'BackgroundColor','w')
annotation('textbox', ...
    'Units', 'centimeters', ...
    'Position', [1 ylevel_now 6 1], ...
    'String', Pop.Name+' | '+strrep(Pop.Session, '_', '-'), ...
    'FontName', 'Dejavu Sans', ...
    'FontWeight', 'bold', ...
    'FontSize', 12, ...
    'BackgroundColor', [1 1 1], ...
    'HorizontalAlignment', 'center', ...
    'EdgeColor', 'none');
annotation('textbox', ...
    'Units', 'centimeters', ...
    'Position', [1 ylevel_now-.75 6 1], ...
    'String', order_note, ...
    'FontName', 'Dejavu Sans', ...
    'FontWeight', 'bold', ...
    'FontSize', 9, ...
    'BackgroundColor', [1 1 1], ...
    'HorizontalAlignment', 'center', ...
    'EdgeColor', 'none');
% Re-adjust figure height
fig_height = ylevel_now + 3 + 0.5;
fig.Position(4) = fig_height;

fig.PaperUnits = fig.Units;
fig.PaperSize  = fig.Position(3:4);

%% Save this figure
if tosave
    thisFolder = fullfile(pwd, 'Fig');
    if ~exist(thisFolder, 'dir')
        mkdir(thisFolder)
    end
    tosavename= fullfile(thisFolder, 'PopulationActivity_'+Pop.Name+'_'+strrep(Pop.Session, '_', '')+'_OrderBy'+order_info);
    disp('########## making figure ########## ')
    tic
    print (fig,'-dpdf', tosavename)
    print (fig,'-dpng', tosavename, '-r300')
    print (fig,'-depsc2', tosavename);
    saveas (fig, tosavename+".fig");
    toc
end

%% add unit table
% write the info to a csv table.
% number of sorted units in this experiment-this is also the number of
% rows

if orderby(1)==orderby(2)
    % Sorting order
    Chs              = zeros(n_unit, 1);
    Ch_Units         = zeros(n_unit, 1);
    Unit_Quality_Num = zeros(n_unit, 1);
    Unit_Quality     = cell(n_unit, 1);
    % IndUnmodulated
    SignificantMod   = ones(n_unit, 1);
    SignificantMod(Pop.IndUnmodulated{orderby(1)}) = 0;

    Unit_Sorted = IndSort{1};
    for i = 1:size(Unit_Sorted, 1)
        iCode = Pop.Units(IndSort{1}(i), :);
        Chs(i)      = iCode(1);
        Ch_Units(i) = iCode(2);
        if iCode(3) == 1
            Unit_Quality{i} = 's';
        else
            Unit_Quality{i} = 'm';
        end
        Unit_Quality_Num(i) = iCode(3);
    end

    % Insert table
    % table_data = [Unit_Sorted, Chs, Ch_Units, Unit_Quality_Num SignificantMod];
    % htable = uitable(hf, 'unit', 'centimeters','Data', table_data,...
    %     'ColumnName', {'UnitID', 'Channel', 'Unit',  'Quality', 'Significant'},...
    %     'Position', [12.5 ylevel_now-1 10 4], 'ColumnWidth',{60, 60, 60, 60, 70});

    sort_table = table(Unit_Sorted, Chs, Ch_Units, Unit_Quality_Num, SignificantMod, 'VariableNames', {'UnitID', 'Channel', 'Unit',  'Quality', 'Significant'});
    writetable(sort_table, tosavename+".csv");
else
    for j = 1:nPort
        x_j = 10 + 6.5*(j-1);
        % Sorting order
        Chs              = zeros(n_unit, 1);
        Ch_Units         = zeros(n_unit, 1);
        Unit_Quality_Num = zeros(n_unit, 1);
        Unit_Quality     = cell(n_unit, 1);
        % IndUnmodulated
        SignificantMod   = ones(n_unit, 1);
        SignificantMod(Pop.IndUnmodulated{orderby(j)}) = 0;

        Unit_Sorted = IndSort{orderby(j)};
        for i = 1:size(Unit_Sorted, 1)
            iCode = Pop.Units(IndSort{orderby(j)}(i), :);
            Chs(i)      = iCode(1);
            Ch_Units(i) = iCode(2);
            if iCode(3) == 1
                Unit_Quality{i} = 's';
            else
                Unit_Quality{i} = 'm';
            end
            Unit_Quality_Num(i) = iCode(3);
        end

        % Insert table
        % table_data = [Unit_Sorted, Chs, Ch_Units, Unit_Quality_Num SignificantMod];
        % htable = uitable(hf, 'unit', 'centimeters','Data', table_data,...
        %     'ColumnName', {'ID', 'Ch.', 'Unit',  'Qua.', 'Sig.'},...
        %     'Position', [x_j ylevel_now-1 6 4], 'ColumnWidth',{30, 30, 30, 30, 30});

    end
end

%% Save this figure
if tosave
    disp('########## save original figure file ########## ')
    saveas (fig, tosavename+".fig");
    toc
end


% % try
% %     thisFolder = fullfile(findonedrive, '00_Work' , '03_Projects', '05_Physiology', 'Data', 'PopulationPSTH', Pop.Name);
% %     if ~exist(thisFolder, 'dir')
% %         mkdir(thisFolder)
% %     end
% %     disp('##########  copying figure ########## ')
% %     tic
% %     copyfile([tosavename '.png'], thisFolder)
% %     copyfile([tosavename '.eps'], thisFolder)
% %     toc
% % end