function [IndSort, fig] = VisualizePopSDFWarped(Pop, order_info, tosave)
% Pop = PopOut;
% 5/14/2023 revised JY

% IndSort = PSTHOut.IndSort;
% IndSignificant = PSTHOut.IndSignificant;
% nsig = sum(IndSignificant);
% 
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

[nFP, nPort] = size(Pop.sdf);
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
WarpedSDFs  = cell(size(Pop.sdf));
WarpedSDFZs = cell(size(Pop.sdf));
tWarpedSDFs = cell(size(Pop.sdf));

%%
for ifp = 1:nFP
    for jport = 1:nPort
        tWarpedSDFs{ifp, jport} = Pop.t_warp{ifp, jport};
        WarpedSDFs{ifp, jport}  = Pop.sdf{ifp, jport}(IndSort{jport}, :);
        WarpedSDFZs{ifp, jport} = Pop.sdf_z{ifp, jport}(IndSort{jport}, :);
    end
end
norm_range = [0 1];
WarpedSDFs_norm = cellfun(@(x) normalize(x, 2, "range", norm_range), WarpedSDFs, 'UniformOutput', false);

%% Plot
set_matlab_default;
% colormap for z-scored PSTH (red-white-blue)
zcolormap = customcolormap(linspace(0,1,11), {'#68011d','#b5172f','#d75f4e','#f7a580','#fedbc9','#f5f9f3','#d5e2f0','#93c5dc','#4295c1','#2265ad','#062e61'});
% visualize PSTH
hf = 49;
fig = figure(hf); clf(hf)
set(fig, 'unit', 'centimeters', 'position', [2 2 22 20], 'paperpositionmode', 'auto' ,'color', 'w')
size_factor = 2;
w_space = 0.1;
h_space = 0.5;

% A. Plot range normalize
xlevel_start = 1.25;
xlevel_now   = xlevel_start;
ylevel_start = 2;
map_height   = 3;

for jport = 1:nPort
    tRange = [-1000 3000];
    Width  = size_factor*diff(tRange)/2000;
    for ifp = 1:nFP
        ax_sdf_norm(ifp) = axes('unit', 'centimeters', 'position',...
            [xlevel_now ylevel_start+(map_height+h_space)*(ifp-1) Width map_height], 'nextplot', 'add',...
            'xlim', tRange, 'xtick', -2000:1000:2000,...
            'ylim', [0.5 n_unit+0.5], 'ydir', 'reverse', 'ticklength', [0.025 0.01], 'XTickLabelRotation', 90);
        if ifp > 1
            set(ax_sdf_norm(ifp), 'xticklabel', [])
        else
            ylabel('Units')
        end
        if jport > 1
            yticklabels([]);
            ylabel([]);
        end
        imagesc(tWarpedSDFs{ifp, jport}, 1:n_unit, WarpedSDFs_norm{ifp, jport}, norm_range);
        colormap('Parula')

        t_points = Pop.t_points{ifp, jport};
        xline(t_points(1), 'color', c_centin, 'linestyle', ':', 'linewidth', 1.5, 'Alpha', 1);
        xline(t_points(2), 'color', c_trigger, 'linestyle', ':', 'linewidth', 1.5, 'Alpha', 1);
        xline(t_points(3), 'color', c_centout, 'linestyle', ':', 'linewidth', 1.5, 'Alpha', 1);
        xline(t_points(4), 'color', c_reward, 'linestyle', ':', 'linewidth', 1.5, 'Alpha', 1);

        fill([get(gca, 'xlim') flip(get(gca, 'xlim'))], [nsig+.5 nsig+.5 n_unit+0.5 n_unit+0.5], 'w', 'FaceColor', 'w', 'EdgeColor', 'none', 'FaceAlpha', .75);
        if jport==1
            title(sprintf('FP=%2.0dms, Ntrials=%2.0d', FPs(ifp), Pop.Trials(ifp, jport)));
        else
            title(sprintf('Ntrials=%2.0d', Pop.Trials(ifp, jport)));
        end
        if ifp==1
            xlabel('Time warped (ms)');
        end
    end

    ylevel_now = ylevel_start+(map_height+h_space)*nFP;
    % uicontrol('Style','text','Units','centimeters','Position',[xlevel_now+1 ylevel_now 6 0.5],...
    %     'string', Ports{jport}, ...
    %     'FontName','Dejavu Sans',  'fontweight', 'bold','fontsize', 9,'BackgroundColor',[1 1 1],...
    %     'HorizontalAlignment','Left');
    annotation('textbox',...
        'String', Ports{jport}, ...
        'Units','Centimeters',...
        'position', [xlevel_now+1 ylevel_now 6 0.5], ...
        'EdgeColor', 'none', ...
        'FontName', 'Dejavu Sans', ...
        'FontWeight', 'bold', ...
        'FontSize', 9, ...
        'BackgroundColor', [1 1 1], ...
        'HorizontalAlignment', 'Left', ...
        'VerticalAlignment', 'middle');

    if jport==1
        % uicontrol('Style','text','Units','centimeters','Position',[xlevel_start-1 ylevel_now+0.75 6 0.5],...
        %     'string', 'A. Normalized activity ([0-1])', ...
        %     'FontName','Dejavu Sans',  'fontweight', 'bold','fontsize', 9,'BackgroundColor',[1 1 1],...
        %     'HorizontalAlignment','Left');
        annotation('textbox',...
            'String', 'A. Normalized activity ([0-1])', ...
            'Units','Centimeters',...
            'position', [xlevel_start-1 ylevel_now+0.75 6 0.5], ...
            'EdgeColor', 'none', ...
            'FontName', 'Dejavu Sans', ...
            'FontWeight', 'bold', ...
            'FontSize', 9, ...
            'BackgroundColor', [1 1 1], ...
            'HorizontalAlignment', 'Left', ...
            'VerticalAlignment', 'middle');
    end
    xlevel_now = xlevel_now + Width + 2 * w_space;
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
    tRange = [-1000 3000];
    Width  = size_factor*diff(tRange)/2000;
    for ifp = 1:nFP
        ax_sdf_z(ifp) = axes('unit', 'centimeters', 'position',...
            [xlevel_now ylevel_start+(map_height+h_space)*(ifp-1) Width map_height], 'nextplot', 'add',...
            'xlim', tRange, 'xtick', -2000:1000:2000,...
            'ylim', [0.5 n_unit+0.5], 'ydir', 'reverse', 'ticklength', [0.025 0.01], 'XTickLabelRotation', 90);
        colormap(ax_sdf_z(ifp), zcolormap);
        if ifp >1
            set(ax_sdf_z(ifp), 'xticklabel', [])
        else
            ylabel('Units')
        end
        if jport > 1
            yticklabels([]);
            ylabel([]);
        end
        imagesc(tWarpedSDFs{ifp, jport}, 1:n_unit, WarpedSDFZs{ifp, jport}, 'AlphaData', ~isnan(WarpedSDFZs{ifp, jport}),zrange); %clim(zrange);

        t_points = Pop.t_points{ifp, jport};
        xline(t_points(1), 'color', c_centin, 'linestyle', ':', 'linewidth', 1.5, 'Alpha', 1);
        xline(t_points(2), 'color', c_trigger, 'linestyle', ':', 'linewidth', 1.5, 'Alpha', 1);
        xline(t_points(3), 'color', c_centout_z, 'linestyle', ':', 'linewidth', 1.5, 'Alpha', 1);
        xline(t_points(4), 'color', c_reward_z, 'linestyle', ':', 'linewidth', 1.5, 'Alpha', 1);

        fill([get(gca, 'xlim') flip(get(gca, 'xlim'))], [nsig+.5 nsig+.5 n_unit+0.5 n_unit+0.5], 'w', 'FaceColor', 'w', 'EdgeColor', 'none', 'FaceAlpha', .75);
        if jport==1
            title(sprintf('FP=%2.0dms, Ntrials=%2.0d', FPs(ifp), Pop.Trials(ifp, jport)));
        else
            title(sprintf('Ntrials=%2.0d', Pop.Trials(ifp, jport)));
        end
        if ifp==1
            xlabel('Time warped (ms)');
        end
    end
    ylevel_now = ylevel_start+(map_height+h_space)*nFP;
    % uicontrol('Style','text','Units','centimeters','Position',[xlevel_now+1 ylevel_now 6 0.5],...
    %     'string', Ports{jport}, ...
    %     'FontName','Dejavu Sans',  'fontweight', 'bold','fontsize', 9,'BackgroundColor',[1 1 1],...
    %     'HorizontalAlignment','Left');
    annotation('textbox',...
            'String', Ports{jport}, ...
            'Units','Centimeters',...
            'position', [xlevel_now+1 ylevel_now 6 0.5], ...
            'EdgeColor', 'none', ...
            'FontName', 'Dejavu Sans', ...
            'FontWeight', 'bold', ...
            'FontSize', 9, ...
            'BackgroundColor', [1 1 1], ...
            'HorizontalAlignment', 'Left', ...
            'VerticalAlignment', 'middle');
    if jport==1
        % uicontrol('Style','text','Units','centimeters','Position',[xlevel_start-1 ylevel_now+0.75 6 0.5],...
        %     'string', ['B. z-scored activity [' num2str(zrange(1)) '-' num2str(zrange(2)) ']'], ...
        %     'FontName','Dejavu Sans',  'fontweight', 'bold','fontsize', 9,'BackgroundColor',[1 1 1],...
        %     'HorizontalAlignment','Left');
        annotation('textbox',...
            'String', ['B. z-scored activity [' num2str(zrange(1)) '-' num2str(zrange(2)) ']'], ...
            'Units','Centimeters',...
            'position', [xlevel_start-1 ylevel_now+0.75 6 0.5], ...
            'EdgeColor', 'none', ...
            'FontName', 'Dejavu Sans', ...
            'FontWeight', 'bold', ...
            'FontSize', 9, ...
            'BackgroundColor', [1 1 1], ...
            'HorizontalAlignment', 'Left', ...
            'VerticalAlignment', 'middle');
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
%     'string', Pop.Subject+' | '+strrep(Pop.Session, '_', '-'), ...
%     'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 12,'BackgroundColor','w')
% 
% uicontrol('Style','text','Units','centimeters','Position', [1 ylevel_now-.75 6 1],...
%     'string', order_note, ...
%     'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 9,'BackgroundColor','w')

annotation('textbox',...
    'String', Pop.Subject+' | '+strrep(Pop.Session, '_', '-'), ...
    'Units','Centimeters',...
    'position', [1 ylevel_now 6 1], ...
    'EdgeColor', 'none', ...
    'FontName', 'Dejavu Sans', ...
    'FontWeight', 'bold', ...
    'FontSize', 12, ...
    'BackgroundColor', 'w', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle');

annotation('textbox',...
    'String', order_note, ...
    'Units', 'Centimeters',...
    'position', [1 ylevel_now-.75 6 1],...
    'EdgeColor', 'none', ...
    'FontName', 'Dejavu Sans', ...
    'FontWeight', 'bold', ...
    'FontSize', 9, ...
    'BackgroundColor', 'w', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle');

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
    tosavename= fullfile(thisFolder, 'PopSDFWarped_'+Pop.Subject+'_'+strrep(Pop.Session, '_', '')+'_OrderBy'+order_info);
    disp('########## making figure ########## ')
    tic
    print(fig,'-dpdf', tosavename)
    print(fig,'-dpng', tosavename, '-r300')
    print(fig,'-depsc2', tosavename);
    saveas(fig, tosavename+".fig");
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
    % table_data = [Unit_Sorted, Chs, Ch_Units, Unit_Quality_Num, SignificantMod];
    % htable = uitable(hf, 'unit', 'centimeters','Data', table_data,...
    %     'ColumnName', {'UnitID', 'Channel', 'Unit',  'Quality', 'Significant'},...
    %     'Position', [10.5 ylevel_now-1 10 4], 'ColumnWidth',{60, 60, 60, 60, 70});
    table_data = table(Unit_Sorted, Chs, Ch_Units, Unit_Quality_Num, SignificantMod,...
        'VariableNames', {'UnitID', 'Channel', 'Unit',  'Quality', 'Significant'});
    writetable(table_data,tosavename+".csv");
else
    for j = 1:nPort
        x_j = 8 + 6.5*(j-1);
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
        % table_data = [Unit_Sorted, Chs, Ch_Units, Unit_Quality_Num, SignificantMod];
        % htable = uitable(hf, 'unit', 'centimeters','Data', table_data,...
        %     'ColumnName', {'ID', 'Ch.', 'Unit',  'Qua.', 'Sig.'},...
        %     'Position', [x_j ylevel_now-1 6 4], 'ColumnWidth',{30, 30, 30, 30, 30});

        tosavename= fullfile(thisFolder, 'PopSDFWarped_'+Pop.Subject+'_'+strrep(Pop.Session, '_', '')+'_OrderBy'+Ports{j});
        table_data = table(Unit_Sorted, Chs, Ch_Units, Unit_Quality_Num, SignificantMod, ...
            'VariableNames', {'UnitID', 'Channel', 'Unit',  'Quality', 'Significant'});
        writetable(table_data,tosavename+".csv");
    end
end

%% Save this figure
if tosave
    disp('########## save original figure file ########## ')
    saveas(fig, tosavename+".fig");
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