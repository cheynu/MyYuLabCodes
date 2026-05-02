function PlotRasterPSTH(r, PSTHOut, PSTH, ku, varargin)

% Jianing Yu 5/8/2023
% For plotting PSTHs under SRT condition.
% Extracted from SRTSpikes

% Modified by Yue Huang on 6/26/2023
% Change the way of making raster plots to run faster

% close all;
ToSave = 'on';
if nargin>2
    for i=1:2:size(varargin,2)
        switch varargin{i}
            case 'ToSave'
                ToSave = varargin{i+1};
            otherwise
                errordlg('unknown argument')
        end
    end
end

CentInTimeDomain  = PSTHOut.TimeDomain.CentIn;
CentOutTimeDomain = PSTHOut.TimeDomain.CentOut;
ChoiceTimeDomain  = PSTHOut.TimeDomain.Choice;
TriggerTimeDomain = PSTHOut.TimeDomain.Trigger;
InitInTimeDomain  = PSTHOut.TimeDomain.InitIn;
InitOutTimeDomain = PSTHOut.TimeDomain.InitOut;

FPs = unique(PSTHOut.CentIn.FP{1});
NumFPs = length(FPs);

Ports = unique(PSTHOut.CentIn.Port{1});
NumPorts = length(Ports);

%% Colors for plots
c = GPSColor();

% For PSTH and raster plots
c_cent_in  = [5 191 219] / 255;
c_trigger  = [247 182 45] / 255;
c_cent_out = [238 5 219] / 255;
c_reward   = [164 208 164] / 255;
c_precor   = [0 0 0];
c_preerr   = [160 82 45] / 255;

% For each FP, not used here
if NumFPs == 2
    c_FP = [192, 127, 0; 76, 61, 61]/255;
    lw = [1.5 1];
    ls = [":", "-"];
else
    c_FP = [255, 217, 90; 192, 127, 0; 76, 61, 61]/255;
    lw = [1.5 1.25 1];
    ls = [":", "-.", "-"];
end

% For each port (contra and ipsi)
p_c = .9;
switch r.ImplantLateral
    case 'R'
        c_port = {p_c*c.Contra+(1-p_c)*[1 1 1], p_c*c.Ipsi+(1-p_c)*[1 1 1]};
    case 'L'
        c_port = {p_c*c.Ipsi+(1-p_c)*[1 1 1], p_c*c.Contra+(1-p_c)*[1 1 1]};
    otherwise
        error('No information about the implantation lateral.');
end

%% Plot raster and spks
printsize = [2 2 25 25]; % initialize figure size, the height will be adjusted in the end

w_space = 1.25;
h_psth = 1;
fig = figure(40); clf(fig);
set(fig, 'unit', 'centimeters', 'position', printsize, 'paperpositionmode', 'auto' ,'color', 'w', 'Visible', 'on')

FRMax = 3; % initialize the max firing rate (y limit), will be adjusted according to correct/pre-correct trials

% all cent-in and choice-in times
t_cent_in = PSTHOut.CentIn.Time{end}; % All cent in times
t_choice  = PSTHOut.ChoiceIn.Time; % All choice in times

% height of one trial raster, according to total trial numbers
n_trials = length(t_cent_in); % number of trials (all)
if n_trials>200
    rasterheight = 0.02;
elseif n_trials>100
    rasterheight = 0.03;
else
    rasterheight = 0.04;
end

%% Align to CentIn
w_psth = sum(CentInTimeDomain) / 1000;
x_col1 = 1.25;

% Correct trials
ind_psth     = strcmp(PSTH.CentInLabels, 'PSTH');
ind_t_psth   = strcmp(PSTH.CentInLabels, 'tPSTH');
ind_spkmat   = strcmp(PSTH.CentInLabels, 'SpikeMat');
ind_t_spkmat = strcmp(PSTH.CentInLabels, 'tSpikeMat');
ind_t_event  = strcmp(PSTH.CentInLabels, 'tEvents');
ind_rt       = strcmp(PSTH.CentInLabels, 'RT');

% PSTH of correct trials
y_col1_row1 = 1;
ha_cent_in_psth = cell(NumFPs, 1);
for i = 1:NumFPs
    yshift = y_col1_row1 + (h_psth+0.1)*(NumFPs-i);
    ha_cent_in_psth{i} = axes(fig, 'unit', 'centimeters', 'position', [x_col1 yshift w_psth h_psth], 'nextplot', 'add', 'xlim', [-CentInTimeDomain(1) CentInTimeDomain(2)], 'FontSize', 7, 'TickDir', 'Out');
    xline(0, 'Color', c_cent_in, 'LineWidth', 1, 'Alpha', 1);
    xline(FPs(i)*1000, 'Color', c_trigger, 'LineWidth', 1, 'Alpha', 1);
    for j = 1:NumPorts
        t_psth_cent_in = PSTH.CentIn{i,j}{ind_t_psth};
        psth_cent_in   = PSTH.CentIn{i,j}{ind_psth};

        plot(t_psth_cent_in, psth_cent_in, 'color', c_port{j}, 'linewidth', 1);
        FRMax = max([FRMax max(psth_cent_in)]);
    end
    if i==NumFPs
        xlabel('Time from cent-in (ms)')
        ylabel('Spks per s')
    else
        xticklabels([]);
        yticklabels([]);
    end
end
axis 'auto y'

% make raster plot
y_col1_row2 = y_col1_row1 + (h_psth+.1)*NumFPs;
% Plot spike raster of correct trials (all FPs)
ntrials_cent_in_ij = zeros(NumFPs, NumPorts);
for i = 1:NumFPs
    for j = 1:NumPorts
        t_event_cent_in = PSTH.CentIn{i,j}{ind_t_event};
        ntrials_cent_in_ij(i,j) = length(t_event_cent_in);
    end
end
ntrials_cent_in = sum(ntrials_cent_in_ij, "all");

axes('unit', 'centimeters', 'position', [x_col1 y_col1_row2 w_psth ntrials_cent_in*rasterheight],...
    'nextplot', 'add', 'box', 'on', ...
    'xlim', [-CentInTimeDomain(1) CentInTimeDomain(2)], 'ylim', [-ntrials_cent_in 1]);
% Paint the foreperiod
k=0;
for m = 1:NumFPs
    for n = 1:NumPorts
        t_event = PSTH.CentIn{m,n}{ind_t_event};
        spk_mat = PSTH.CentIn{m,n}{ind_spkmat};
        t_mat   = PSTH.CentIn{m,n}{ind_t_spkmat};
        rt      = PSTH.CentIn{m,n}{ind_rt};

        xx_all = []; % spike times
        yy_all = [];
        xxrt_all = []; % reaction (cent-out) times
        yyrt_all = [];
        x_choice = []; % choice times
        y_choice = [];

        for i = 1:ntrials_cent_in_ij(m,n)
            xx = t_mat(spk_mat(:,i)==1);
            yy1 = [.1 .9] - k; % spikes
            yy2 = [0 1] - k;   % events
            
            irt = rt(i); % time from trigger to cent-out
            xxrt = irt + FPs(m)*1000;

            % register spikes and events
            if isempty(find(isnan(spk_mat(:, i)), 1))
                for i_xx = 1:length(xx)
                    xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN]; % [x1 x1 nan x2 x2 nan x3 x3 nan ... ]
                    yy_all = [yy_all, yy1, NaN];                % [y1 y1 nan y2 y2 nan y3 y3 nan ... ]
                end
                xxrt_all = [xxrt_all, xxrt, xxrt, NaN];
                yyrt_all = [yyrt_all, yy2, NaN];
            end

            % trigger events
%             fill(1000*[0 TargetFPs(m) TargetFPs(m) 0],[-k -k 1-k 1-k], 'r', 'FaceColor', c_trigger, 'FaceAlpha', 1, 'EdgeColor', 'none');
            line(1000*[FPs(m) FPs(m)], yy2, 'Color', c_trigger, 'linewidth', 1);

            % choice time
            it_cent_in = t_event(i);
            it_choice = t_choice - it_cent_in;
            it_choice = it_choice(it_choice>=-CentInTimeDomain(1) & it_choice<=CentInTimeDomain(2));
            if ~isempty(it_choice)
                it_choice = reshape(it_choice,1,[]);
                x_choice = [x_choice, it_choice];
                y_choice = [y_choice, (0.5-k)*ones(1,length(it_choice))];
            end
            k = k+1;
        end
        line(xx_all, yy_all, 'color', c_port{n}, 'linewidth', .2);
        line(xxrt_all, yyrt_all, 'color', c_cent_out, 'linewidth', 1);
        scatter(x_choice, y_choice, 8, 'o', 'filled', 'MarkerFaceColor', c_reward, 'markerfacealpha', 0.5, 'MarkerEdgeColor', 'none');
    end
end
xline(0, 'Color', c_cent_in, 'LineWidth', 1, 'Alpha', 1);
title('Correct', 'fontsize', 7, 'fontweight','bold');
axis off

% Probe trials
ind_psth     = strcmp(PSTH.ProbeLabels, 'PSTH');
ind_t_psth   = strcmp(PSTH.ProbeLabels, 'tPSTH');
ind_spkmat   = strcmp(PSTH.ProbeLabels, 'SpikeMat');
ind_t_spkmat = strcmp(PSTH.ProbeLabels, 'tSpikeMat');
ind_t_event  = strcmp(PSTH.ProbeLabels, 'tEvents');
ind_hd       = strcmp(PSTH.ProbeLabels, 'HoldDuration');

% PSTH of probe trials
y_col1_row3 = y_col1_row2 + ntrials_cent_in*rasterheight + 0.5;
ha_cent_in_psth_probe = axes('unit', 'centimeters', 'position', [x_col1 y_col1_row3 w_psth h_psth], 'nextplot', 'add',...
    'xlim',  [-CentInTimeDomain(1) CentInTimeDomain(2)], 'xticklabel', [], 'FontSize', 7, 'TickDir', 'Out');
xline(0, 'Color', c_cent_in, 'LineWidth', 1, 'Alpha', 1);

% plot psth of probe trials if trial number > 3
for j = 1:NumPorts
    if length(PSTH.ProbeCentIn{j}{ind_t_event}) > 3
        plot(PSTH.ProbeCentIn{j}{ind_t_psth}, PSTH.ProbeCentIn{j}{ind_psth}, 'color', c_port{j}, 'linewidth',1);
    end
end

% Probe cent-in raster plot
y_col1_row4 = y_col1_row3 + (h_psth+.1);
ntrial_probe = sum(cellfun(@(x) length(x{ind_t_event}), PSTH.ProbeCentIn)); % number of trials
axes('unit', 'centimeters', 'position', [x_col1 y_col1_row4 w_psth ntrial_probe*rasterheight], ...
    'nextplot', 'add', 'box', 'on', ...
    'xlim', [-CentInTimeDomain(1) CentInTimeDomain(2)], 'ylim', [-ntrial_probe 1]);
k = 0;
for n = 1:NumPorts
    t_event = PSTH.ProbeCentIn{n}{ind_t_event};
    spk_mat = PSTH.ProbeCentIn{n}{ind_spkmat};
    t_mat   = PSTH.ProbeCentIn{n}{ind_t_spkmat};
    hd      = PSTH.ProbeCentIn{n}{ind_hd};

    xx_all = []; % spike times
    yy_all = [];
    xxrt_all = []; % cent-out times
    yyrt_all = [];
    x_choice = []; % choice times
    y_choice = [];

    for i = 1:size(spk_mat, 2)
        xx = t_mat(spk_mat(:, i)==1);
        yy1 = [.1 .9] - k; % spikes
        yy2 = [0 1] - k;   % events

        xxrt = hd(i);

        % register spikes and events
        if isempty(find(isnan(spk_mat(:, i)), 1))
            for i_xx = 1:length(xx)
                xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN]; % [x1 x1 nan x2 x2 nan x3 x3 nan ... ]
                yy_all = [yy_all, yy1, NaN];                % [y1 y1 nan y2 y2 nan y3 y3 nan ... ]
            end
            xxrt_all = [xxrt_all, xxrt, xxrt, NaN];
            yyrt_all = [yyrt_all, yy2, NaN];
        end

        % plot port poke time
        it_choice = t_choice - t_event(i);
        it_choice = it_choice(it_choice>=-CentInTimeDomain(1) & it_choice<=CentInTimeDomain(2));
        if ~isempty(it_choice)
            it_choice = reshape(it_choice,1,[]);
            x_choice = [x_choice, it_choice];
            y_choice = [y_choice, (0.5-k)*ones(1,length(it_choice))];
        end
        k = k+1;
    end

    line(xx_all, yy_all, 'color', c_port{n}, 'linewidth', .2)
    line(xxrt_all, yyrt_all, 'color', c_cent_out, 'linewidth', 1)
    scatter(x_choice, y_choice, 8, 'o', 'filled','MarkerFaceColor', c_reward,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none')
end
xline(0, 'Color', c_cent_in, 'LineWidth', 1, 'Alpha', 1);
title('Probe', 'fontsize', 7, 'fontweight','bold')
axis off

% Late trials
ind_psth     = strcmp(PSTH.LateLabels, 'PSTH');
ind_t_psth   = strcmp(PSTH.LateLabels, 'tPSTH');
ind_spkmat   = strcmp(PSTH.LateLabels, 'SpikeMat');
ind_t_spkmat = strcmp(PSTH.LateLabels, 'tSpikeMat');
ind_t_event  = strcmp(PSTH.LateLabels, 'tEvents');
ind_hd       = strcmp(PSTH.LateLabels, 'HoldDuration');
ind_fp       = strcmp(PSTH.LateLabels, 'FP');

% PSTH of late trials
y_col1_row5 = y_col1_row4 + 0.5 + ntrial_probe*rasterheight;
ha_cent_in_psth_late =  axes('unit', 'centimeters', 'position', [x_col1 y_col1_row5 w_psth h_psth], 'nextplot', 'add',...
    'xlim',  [-CentInTimeDomain(1) CentInTimeDomain(2)], 'xticklabel', [], 'FontSize', 7, 'TickDir', 'Out');
xline(0, 'Color', c_cent_in, 'LineWidth', 1, 'Alpha', 1);
for j = 1:NumPorts
    if length(PSTH.LateCentIn{j}{ind_t_event}) > 3
        plot(PSTH.LateCentIn{j}{ind_t_psth}, PSTH.LateCentIn{j}{ind_psth}, 'color', c_port{j}, 'linewidth',1);
    end
end

% Late response raster plot
y_col1_row6 = y_col1_row5 + (h_psth+.1);
ntrial_late = sum(cellfun(@(x) length(x{ind_t_event}), PSTH.LateCentIn)); % number of trials
axes('unit', 'centimeters', 'position', [x_col1 y_col1_row6 w_psth ntrial_late*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-CentInTimeDomain(1) CentInTimeDomain(2)], 'ylim', [-ntrial_late 1], 'box', 'on');
k = 0;
for n = 1:NumPorts
    t_event = PSTH.LateCentIn{n}{ind_t_event};
    spk_mat = PSTH.LateCentIn{n}{ind_spkmat};
    t_mat   = PSTH.LateCentIn{n}{ind_t_spkmat};
    hd      = PSTH.LateCentIn{n}{ind_hd};
    fp      = PSTH.LateCentIn{n}{ind_fp};

    xx_all = []; % spike times
    yy_all = [];
    xxrt_all = []; % cent-out times
    yyrt_all = [];
    xxfp_all = []; % trigger times
    yyfp_all = [];
    x_choice = []; % choice times
    y_choice = [];
    
    for i = 1:size(spk_mat, 2)
        xx =  t_mat(spk_mat(:, i)==1);
        yy1 = [.1 .9] - k;
        yy2 = [0 1] - k;
        xxrt = hd(i);
        xxfp = fp(i)*1000;

        for i_xx = 1:length(xx)
            xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
            yy_all = [yy_all, yy1, NaN];
        end
        xxrt_all = [xxrt_all, xxrt, xxrt, NaN];
        yyrt_all = [yyrt_all, yy2, NaN];
        xxfp_all = [xxfp_all, xxfp, xxfp, NaN];
        yyfp_all = [yyfp_all, yy2, NaN];

        % plot port poke time
        it_choice = t_choice - t_event(i);
        it_choice = it_choice(it_choice>=-CentInTimeDomain(1) & it_choice<=CentInTimeDomain(2));
        if ~isempty(it_choice)
            it_choice = reshape(it_choice,1,[]);
            x_choice = [x_choice, it_choice];
            y_choice = [y_choice, (0.5-k)*ones(1,length(it_choice))];
        end
        k = k+1;
    end

    line(xx_all, yy_all, 'color', c_port{n}, 'linewidth', .2)
    line(xxrt_all, yyrt_all, 'color', c_cent_out, 'linewidth', 1)
    line(xxfp_all, yyfp_all, 'color', c_trigger, 'linewidth', 1)
    scatter(x_choice, y_choice, 8, 'o', 'filled','MarkerFaceColor', c_reward,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none')
end
xline(0, 'Color', c_cent_in, 'LineWidth', 1, 'Alpha', 1);
title('Late', 'fontsize', 7, 'fontweight','bold')
axis off

% Premature trials
ind_psth     = strcmp(PSTH.PrematureLabels, 'PSTH');
ind_t_psth   = strcmp(PSTH.PrematureLabels, 'tPSTH');
ind_spkmat   = strcmp(PSTH.PrematureLabels, 'SpikeMat');
ind_t_spkmat = strcmp(PSTH.PrematureLabels, 'tSpikeMat');
ind_t_event  = strcmp(PSTH.PrematureLabels, 'tEvents');
ind_hd       = strcmp(PSTH.PrematureLabels, 'HoldDuration');

% PSTH
y_col1_row7 = y_col1_row6 + 0.5 + ntrial_late*rasterheight;
ha_cent_in_psth_premature =  axes('unit', 'centimeters', 'position', [x_col1 y_col1_row7 w_psth h_psth], 'nextplot', 'add',...
    'xlim',  [-CentInTimeDomain(1) CentInTimeDomain(2)], 'xticklabel', [], 'FontSize', 7, 'TickDir', 'Out');
xline(0, 'Color', c_cent_in, 'LineWidth', 1, 'Alpha', 1);

% plot psth of premature trials if the trial number > 3
for j = 1:NumPorts
    if length(PSTH.PrematureCentIn{j}{ind_t_event}) > 3
        plot(PSTH.PrematureCentIn{j}{ind_t_psth}, PSTH.PrematureCentIn{j}{ind_psth}, 'color', c_port{j}, 'linewidth',1);
    end
end

% Premature press raster plot
y_col1_row8 = y_col1_row7 + (h_psth+.1);
ntrial_premature = sum(cellfun(@(x) length(x{ind_t_event}), PSTH.PrematureCentIn)); % number of trials
axes('unit', 'centimeters', 'position', [x_col1 y_col1_row8 w_psth ntrial_premature*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-CentInTimeDomain(1) CentInTimeDomain(2)], 'ylim', [-ntrial_premature 1], 'box', 'on');
k = 0;
for n = 1:NumPorts
    t_event = PSTH.PrematureCentIn{n}{ind_t_event};
    spk_mat = PSTH.PrematureCentIn{n}{ind_spkmat};
    t_mat   = PSTH.PrematureCentIn{n}{ind_t_spkmat};
    hd      = PSTH.PrematureCentIn{n}{ind_hd};

    xx_all = []; % spike times
    yy_all = [];
    xxrt_all = []; % cent-out times
    yyrt_all = [];
    x_choice = []; % choice times
    y_choice = [];

    for i =1:size(spk_mat, 2)
        xx =  t_mat(spk_mat(:, i)==1);
        yy1 = [.1 .9] - k;
        yy2 = [0 1] - k;
        xxrt = hd(i);

        for i_xx = 1:length(xx)
            xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
            yy_all = [yy_all, yy1, NaN];
        end
        xxrt_all = [xxrt_all, xxrt, xxrt, NaN];
        yyrt_all = [yyrt_all, yy2, NaN];

        % plot choice poke time
        it_choice = t_choice - t_event(i);
        it_choice = it_choice(it_choice>=-CentInTimeDomain(1) & it_choice<=CentInTimeDomain(2));
        if ~isempty(it_choice)
            it_choice = reshape(it_choice,1,[]);
            x_choice = [x_choice, it_choice];
            y_choice = [y_choice, (0.5-k)*ones(1,length(it_choice))];
        end
        k = k+1;
    end

    line(xx_all, yy_all, 'color', c_port{n}, 'linewidth', .2)
    line(xxrt_all, yyrt_all, 'color', c_cent_out, 'linewidth', 1)
    scatter(x_choice, y_choice, 8, 'o', 'filled','MarkerFaceColor', c_reward,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none')
end
xline(0, 'Color', c_cent_in, 'LineWidth', 1, 'Alpha', 1);
title('Premature', 'fontsize', 7, 'fontweight','bold')
axis off

%% Add overall title
% this is the position of last panel
y_col1_row9 = y_col1_row8 + 0.5 + ntrial_premature*rasterheight;
% Add information
% uicontrol('Style', 'text', 'Units', 'centimeters', 'Position', [x_col1-.5 y_col1_row9  6 1],...
%     'string', 'A. CentIn-related', ...
%     'FontName', 'Dejavu Sans', 'fontweight', 'bold', 'fontsize', 8, 'BackgroundColor', [1 1 1],...
%     'HorizontalAlignment', 'Left');
annotation('textbox', ...
    'Units', 'centimeters', ...
    'Position', [x_col1-.5  y_col1_row9  6 1], ...
    'String', 'A. CentIn-related', ...
    'FontName', 'Dejavu Sans', ...
    'FontWeight', 'bold', ...
    'FontSize', 8, ...
    'BackgroundColor', [1 1 1], ...
    'HorizontalAlignment', 'left', ...
    'EdgeColor', 'none');

y_col1_row10 = y_col1_row9 + w_space;
ch = r.Units.SpikeNotes(ku, 1);
unit_no = r.Units.SpikeNotes(ku, 2);
ch_id = r.ChanMap.chanMap==ch;
ch_k  = r.ChanMap.kcoords(ch_id);
ch_x  = r.ChanMap.xcoords(ch_id);
ch_y  = r.ChanMap.ycoords(ch_id);

if size(r.Units.SpikeNotes, 2) == 4
    cluster_id = r.Units.SpikeNotes(ku, 4);
    % uicontrol('style', 'text', 'units', 'centimeters', 'position', [x_col1-.25 y_col1_row10 6 1.2],...
    %     'string', (['Unit #' num2str(ku) ' (Ch ' num2str(ch) ' | UnitOnCh ' num2str(unit_no) ' | ' 'Kilosort cluster ' num2str(cluster_id) ')']),...
    %     'BackgroundColor','w', 'fontsize', 8, 'fontweight','bold',  'FontName','Dejavu Sans')
    annotation('textbox', ...
        'Units', 'centimeters', ...
        'Position', [x_col1-.25 y_col1_row10 6 1.2], ...
        'String', (['Unit #' num2str(ku) ' (Ch ' num2str(ch) ' | UnitOnCh ' num2str(unit_no) ' | ' 'Kilosort cluster ' num2str(cluster_id) ')']), ...
        'FontName', 'Dejavu Sans', ...
        'FontWeight', 'bold', ...
        'FontSize', 8, ...
        'BackgroundColor', [1 1 1], ...
        'HorizontalAlignment', 'center', ...
        'EdgeColor', 'none');
else
    cluster_id = [];
    % uicontrol('style', 'text', 'units', 'centimeters', 'position', [x_col1-.25 y_col1_row10 6 1.2],...
    %     'string', (['Unit #' num2str(ku) ' (' num2str(ch) ' | ' num2str(unit_no) ')']),...
    %     'BackgroundColor','w', 'fontsize', 8, 'fontweight','bold',  'FontName','Dejavu Sans')
    annotation('textbox', ...
        'Units', 'centimeters', ...
        'Position', [x_col1-.25 y_col1_row10 6 1.2], ...
        'String', (['Unit #' num2str(ku) ' (' num2str(ch) ' | ' num2str(unit_no) ')']), ...
        'FontName', 'Dejavu Sans', ...
        'FontWeight', 'bold', ...
        'FontSize', 8, ...
        'BackgroundColor', [1 1 1], ...
        'HorizontalAlignment', 'center', ...
        'EdgeColor', 'none');
end
% uicontrol('style', 'text', 'units', 'centimeters', 'position', [x_col1-.25 y_col1_row10+1.2 4 0.5],...
%     'string', ([r.Meta(1).Subject ' ' r.Meta(1).DateTime(1:11)]), 'BackgroundColor','w',...
%     'fontsize', 8, 'fontweight', 'bold',  'FontName','Dejavu Sans')
annotation('textbox', ...
    'Units', 'centimeters', ...
    'Position', [x_col1-.25 y_col1_row10+1.2 4 0.5], ...
    'String', ([r.Meta(1).Subject ' ' r.Meta(1).DateTime(1:11)]), ...
    'FontName', 'Dejavu Sans', ...
    'FontWeight', 'bold', ...
    'FontSize', 8, ...
    'BackgroundColor', [1 1 1], ...
    'HorizontalAlignment', 'center', ...
    'EdgeColor', 'none');
fig_height = y_col1_row10 + 2;

%% Align to CentOut
x_col2 = x_col1 + w_psth + w_space;
w_psth = sum(CentOutTimeDomain) / 1000;

% Correct trials
ind_psth     = strcmp(PSTH.CentOutLabels, 'PSTH');
ind_t_psth   = strcmp(PSTH.CentOutLabels, 'tPSTH');
ind_spkmat   = strcmp(PSTH.CentOutLabels, 'SpikeMat');
ind_t_spkmat = strcmp(PSTH.CentOutLabels, 'tSpikeMat');
ind_t_event  = strcmp(PSTH.CentOutLabels, 'tEvents');
ind_rt       = strcmp(PSTH.CentOutLabels, 'RT');

% PSTH of correct trials
y_col2_row1 = y_col1_row1;
ha_cent_out_psth = cell(1,NumFPs);
for i = 1:NumFPs
    yshift = y_col2_row1 + (h_psth+0.1)*(NumFPs-i);
    ha_cent_out_psth{i} = axes(fig, 'unit', 'centimeters', 'position', [x_col2 yshift w_psth h_psth], 'nextplot', 'add', 'xlim', [-CentOutTimeDomain(1) CentOutTimeDomain(2)], 'FontSize', 7, 'TickDir', 'Out');
    xline(0, 'Color', c_cent_out, 'LineWidth', 1, 'Alpha', 1);
    for j = 1:NumPorts
        t_psth_cent_out = PSTH.CentOut{i,j}{ind_t_psth};
        psth_cent_out   = PSTH.CentOut{i,j}{ind_psth};

        plot(t_psth_cent_out, psth_cent_out, 'color', c_port{j}, 'linewidth', 1);
        FRMax = max([FRMax max(psth_cent_out)]);
    end
    if i==NumFPs
        xlabel('Time from cent-out (ms)')
        ylabel('Spks per s')
    else
        xticklabels([]);
        yticklabels([]);
    end
end
axis 'auto y'

% make raster plot
y_col2_row2 = y_col1_row2;
% Plot spike raster of correct trials (all FPs)
ntrials_cent_out_ij = zeros(NumFPs, NumPorts);
for i = 1:NumFPs
    for j = 1:NumPorts
        t_event_cent_out = PSTH.CentOut{i,j}{ind_t_event};
        ntrials_cent_out_ij(i,j) = length(t_event_cent_out);
    end
end
ntrials_cent_out = sum(ntrials_cent_out_ij, "all");

axes('unit', 'centimeters', 'position', [x_col2 y_col2_row2 w_psth ntrials_cent_out*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-CentOutTimeDomain(1) CentOutTimeDomain(2)], 'ylim', [-ntrials_cent_out 1], 'box', 'on');

k=0;
for m = 1:NumFPs
    for n = 1:NumPorts
        t_event = PSTH.CentOut{m,n}{ind_t_event};
        spk_mat = PSTH.CentOut{m,n}{ind_spkmat};
        t_mat   = PSTH.CentOut{m,n}{ind_t_spkmat};
        rt      = PSTH.CentOut{m,n}{ind_rt};
        hd      = rt + FPs(m)*1000;

        xx_all = []; % spike times
        yy_all = [];
        xxrt_all = []; % reaction (cent-out) times
        yyrt_all = [];
        xxhd_all = []; % reaction (cent-out) times
        yyhd_all = [];
        x_choice = []; % choice times
        y_choice = [];

        for i = 1:ntrials_cent_out_ij(m,n)
            xx = t_mat(spk_mat(:,i)==1);
            yy1 = [.1 .9] - k; % spikes
            yy2 = [0 1] - k;   % events

            xxrt = -rt(i);
            xxhd = -hd(i);

            if isempty(find(isnan(spk_mat(:, i)), 1))
                for i_xx = 1:length(xx)
                    xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
                    yy_all = [yy_all, yy1, NaN];
                end
                xxrt_all = [xxrt_all, xxrt, xxrt, NaN];
                yyrt_all = [yyrt_all, yy2, NaN];
                xxhd_all = [xxhd_all, xxhd, xxhd, NaN];
                yyhd_all = [yyhd_all, yy2, NaN];
            end

            % choice time
            it_cent_out = t_event(i);
            it_choice = t_choice - it_cent_out;
            it_choice = it_choice(it_choice>=-CentOutTimeDomain(1) & it_choice<=CentOutTimeDomain(2));
            if ~isempty(it_choice)
                it_choice = reshape(it_choice,1,[]);
                x_choice = [x_choice, it_choice];
                y_choice = [y_choice, (0.5-k)*ones(1,length(it_choice))];
            end
            k = k+1;
        end
        line(xx_all, yy_all, 'color', c_port{n}, 'linewidth', .2);
        line(xxrt_all, yyrt_all, 'color', c_trigger, 'linewidth', 1);
        line(xxhd_all, yyhd_all, 'color', c_cent_in, 'linewidth', 1);
        scatter(x_choice, y_choice, 8, 'o', 'filled','MarkerFaceColor', c_reward,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none');
    end
end
xline(0, 'Color', c_cent_out, 'LineWidth', 1, 'Alpha', 1);
title('Correct', 'fontsize', 7, 'fontweight','bold');
axis off

% Probe trials
ind_psth     = strcmp(PSTH.ProbeLabels, 'PSTH');
ind_t_psth   = strcmp(PSTH.ProbeLabels, 'tPSTH');
ind_spkmat   = strcmp(PSTH.ProbeLabels, 'SpikeMat');
ind_t_spkmat = strcmp(PSTH.ProbeLabels, 'tSpikeMat');
ind_t_event  = strcmp(PSTH.ProbeLabels, 'tEvents');
ind_hd       = strcmp(PSTH.ProbeLabels, 'HoldDuration');

% PSTH of probe trials
y_col2_row3 = y_col1_row3;
ha_cent_out_psth_probe = axes('unit', 'centimeters', 'position', [x_col2 y_col2_row3 w_psth h_psth], 'nextplot', 'add',...
    'xlim',  [-CentOutTimeDomain(1) CentOutTimeDomain(2)], 'xticklabel', [], 'FontSize', 7, 'TickDir', 'Out');
xline(0, 'Color', c_cent_out, 'LineWidth', 1, 'Alpha', 1);

% plot probe trials as well
for j = 1:NumPorts
    if length(PSTH.ProbeCentOut{j}{ind_t_event}) > 3
        plot(PSTH.ProbeCentOut{j}{ind_t_psth}, PSTH.ProbeCentOut{j}{ind_psth}, 'color', c_port{j}, 'linewidth',1);
    end
end

y_col2_row4 = y_col1_row4;
% Probe cent-out raster plot
ntrial_probe = sum(cellfun(@(x) length(x{ind_t_event}), PSTH.ProbeCentOut)); % number of trials
axes('unit', 'centimeters', 'position', [x_col2 y_col2_row4 w_psth ntrial_probe*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-CentOutTimeDomain(1) CentOutTimeDomain(2)], 'ylim', [-ntrial_probe 1], 'box', 'on');
k =0;
for n = 1:NumPorts
    t_event = PSTH.ProbeCentOut{n}{ind_t_event};
    spk_mat = PSTH.ProbeCentOut{n}{ind_spkmat};
    t_mat   = PSTH.ProbeCentOut{n}{ind_t_spkmat};
    hd      = PSTH.ProbeCentOut{n}{ind_hd};

    xx_all = []; % spike times
    yy_all = [];
    xxrt_all = []; % cent-out times
    yyrt_all = [];
    x_choice = []; % choice times
    y_choice = [];

    for i =1:size(spk_mat, 2)
        xx =  t_mat(spk_mat(:, i)==1);
        yy1 = [.1 .9] - k;
        yy2 = [0 1] - k;

        xxrt = -hd(i);

        % register spikes and events
        for i_xx = 1:length(xx)
            xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
            yy_all = [yy_all, yy1, NaN];
        end
        xxrt_all = [xxrt_all, xxrt, xxrt, NaN];
        yyrt_all = [yyrt_all, yy2, NaN];

        % plot port poke time
        it_choice = t_choice - t_event(i);
        it_choice = it_choice(it_choice>=-CentOutTimeDomain(1) & it_choice<=CentOutTimeDomain(2));
        if ~isempty(it_choice)
            it_choice = reshape(it_choice,1,[]);
            x_choice = [x_choice, it_choice];
            y_choice = [y_choice, (0.5-k)*ones(1,length(it_choice))];
        end
        k = k+1;
    end

    line(xx_all, yy_all, 'color', c_port{n}, 'linewidth', .2)
    line(xxrt_all, yyrt_all, 'color', c_cent_in, 'linewidth', 1)
    scatter(x_choice, y_choice, 8, 'o', 'filled','MarkerFaceColor', c_reward,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none')
end
xline(0, 'Color', c_cent_out, 'LineWidth', 1, 'Alpha', 1);
title('Probe', 'fontsize', 7, 'fontweight','bold')
axis off

% Late trials
ind_psth     = strcmp(PSTH.LateLabels, 'PSTH');
ind_t_psth   = strcmp(PSTH.LateLabels, 'tPSTH');
ind_spkmat   = strcmp(PSTH.LateLabels, 'SpikeMat');
ind_t_spkmat = strcmp(PSTH.LateLabels, 'tSpikeMat');
ind_t_event  = strcmp(PSTH.LateLabels, 'tEvents');
ind_hd       = strcmp(PSTH.LateLabels, 'HoldDuration');
ind_fp       = strcmp(PSTH.LateLabels, 'FP');

% PSTH of late trials
y_col2_row5 = y_col1_row5;

ha_cent_out_psth_late =  axes('unit', 'centimeters', 'position', [x_col2 y_col2_row5 w_psth h_psth], 'nextplot', 'add',...
    'xlim',  [-CentOutTimeDomain(1) CentOutTimeDomain(2)], 'xticklabel', [], 'FontSize', 7, 'TickDir', 'Out');
xline(0, 'Color', c_cent_out, 'LineWidth', 1, 'Alpha', 1);
for j = 1:NumPorts
    if length(PSTH.LateCentOut{j}{ind_t_event}) > 3
        plot(PSTH.LateCentOut{j}{ind_t_psth}, PSTH.LateCentOut{j}{ind_psth}, 'color', c_port{j}, 'linewidth',1);
    end
end

% Late response raster plot
y_col2_row6 = y_col1_row6;
ntrial_late = sum(cellfun(@(x) length(x{ind_t_event}), PSTH.LateCentOut)); % number of trials
axes('unit', 'centimeters', 'position', [x_col2 y_col2_row6 w_psth ntrial_late*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-CentOutTimeDomain(1) CentOutTimeDomain(2)], 'ylim', [-ntrial_late 1], 'box', 'on');
k = 0;
for n = 1:NumPorts
    t_event = PSTH.LateCentOut{n}{ind_t_event};
    spk_mat = PSTH.LateCentOut{n}{ind_spkmat};
    t_mat   = PSTH.LateCentOut{n}{ind_t_spkmat};
    hd      = PSTH.LateCentOut{n}{ind_hd};
    fp      = PSTH.LateCentOut{n}{ind_fp};
    rt      = hd - fp*1000;

    xx_all = []; % spike times
    yy_all = [];
    xxrt_all = []; % trigger times
    yyrt_all = [];
    xxhd_all = []; % cent-in times
    yyhd_all = [];
    x_choice = []; % choice times
    y_choice = [];
    
    for i =1:size(spk_mat, 2)
        xx =  t_mat(spk_mat(:, i)==1);
        yy1 = [.1 .9] - k;
        yy2 = [0 1] - k;

        xxrt = -rt(i);
        xxhd = -hd(i);

        for i_xx = 1:length(xx)
            xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
            yy_all = [yy_all, yy1, NaN];
        end
        xxrt_all = [xxrt_all, xxrt, xxrt, NaN];
        yyrt_all = [yyrt_all, yy2, NaN];
        xxhd_all = [xxhd_all, xxhd, xxhd, NaN];
        yyhd_all = [yyhd_all, yy2, NaN];

        % plot port poke time
        it_choice = t_choice - t_event(i);
        it_choice = it_choice(it_choice>=-CentOutTimeDomain(1) & it_choice<=CentOutTimeDomain(2));
        if ~isempty(it_choice)
            it_choice = reshape(it_choice,1,[]);
            x_choice = [x_choice, it_choice];
            y_choice = [y_choice, (0.5-k)*ones(1,length(it_choice))];
        end
        k = k+1;
    end

    line(xx_all, yy_all, 'color', c_port{n}, 'linewidth', .2)
    line(xxrt_all, yyrt_all, 'color', c_trigger, 'linewidth', 1)
    line(xxhd_all, yyhd_all, 'color', c_cent_in, 'linewidth', 1)
    scatter(x_choice, y_choice, 8, 'o', 'filled','MarkerFaceColor', c_reward,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none')
end
xline(0, 'Color', c_cent_out, 'LineWidth', 1, 'Alpha', 1);
title('Late', 'fontsize', 7, 'fontweight','bold')
axis off

% Premature trials
ind_psth     = strcmp(PSTH.PrematureLabels, 'PSTH');
ind_t_psth   = strcmp(PSTH.PrematureLabels, 'tPSTH');
ind_spkmat   = strcmp(PSTH.PrematureLabels, 'SpikeMat');
ind_t_spkmat = strcmp(PSTH.PrematureLabels, 'tSpikeMat');
ind_t_event  = strcmp(PSTH.PrematureLabels, 'tEvents');
ind_hd       = strcmp(PSTH.PrematureLabels, 'HoldDuration');

% PSTH
y_col2_row7 = y_col1_row7;
ha_cent_out_psth_premature =  axes('unit', 'centimeters', 'position', [x_col2 y_col2_row7 w_psth h_psth], 'nextplot', 'add',...
    'xlim',  [-CentOutTimeDomain(1) CentOutTimeDomain(2)], 'xticklabel', [], 'FontSize', 7, 'TickDir', 'Out');
xline(0, 'Color', c_cent_out, 'LineWidth', 1, 'Alpha', 1);
for j = 1:NumPorts
    if length(PSTH.PrematureCentOut{j}{ind_t_event}) > 3
        plot(PSTH.PrematureCentOut{j}{ind_t_psth}, PSTH.PrematureCentOut{j}{ind_psth}, 'color', c_port{j}, 'linewidth',1);
    end
end

% Premature press raster plot
y_col2_row8 = y_col1_row8;
ntrial_premature = sum(cellfun(@(x) length(x{ind_t_event}), PSTH.PrematureCentOut)); % number of trials
axes('unit', 'centimeters', 'position', [x_col2 y_col2_row8 w_psth ntrial_premature*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-CentOutTimeDomain(1) CentOutTimeDomain(2)], 'ylim', [-ntrial_premature 1], 'box', 'on');
k = 0;
for n = 1:NumPorts
    t_event = PSTH.PrematureCentOut{n}{ind_t_event};
    spk_mat = PSTH.PrematureCentOut{n}{ind_spkmat};
    t_mat   = PSTH.PrematureCentOut{n}{ind_t_spkmat};
    hd      = PSTH.PrematureCentOut{n}{ind_hd};

    xx_all = []; % spike times
    yy_all = [];
    xxrt_all = []; % cent-in times
    yyrt_all = [];
    x_choice = []; % choice times
    y_choice = [];

    for i = 1:size(spk_mat, 2)
        xx =  t_mat(spk_mat(:, i)==1);
        yy1 = [.1 .9] - k;
        yy2 = [0 1] - k;

        xxrt = -hd(i);

        for i_xx = 1:length(xx)
            xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
            yy_all = [yy_all, yy1, NaN];
        end
        xxrt_all = [xxrt_all, xxrt, xxrt, NaN];
        yyrt_all = [yyrt_all, yy2, NaN];

        % plot port poke time
        it_choice = t_choice - t_event(i);
        it_choice = it_choice(it_choice>=-CentOutTimeDomain(1) & it_choice<=CentOutTimeDomain(2));
        if ~isempty(it_choice)
            it_choice = reshape(it_choice,1,[]);
            x_choice = [x_choice, it_choice];
            y_choice = [y_choice, (0.5-k)*ones(1,length(it_choice))];
        end
        k = k+1;
    end

    line(xx_all, yy_all, 'color', c_port{n}, 'linewidth', .2)
    line(xxrt_all, yyrt_all, 'color', c_cent_in, 'linewidth', 1)
    scatter(x_choice, y_choice, 8, 'o', 'filled','MarkerFaceColor', c_reward,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none')
end
xline(0, 'Color', c_cent_out, 'LineWidth', 1, 'Alpha', 1);
title('Premature', 'fontsize', 7, 'fontweight','bold')
axis off

% this is the position of last panel
% Add information
y_col2_row9 = y_col1_row9;
% uicontrol('Style', 'text', 'Units', 'centimeters', 'Position', [x_col2-.25 y_col2_row9 4 1],...
%     'string', 'B. CentOut-related', ...
%     'FontName', 'Dejavu Sans', 'fontweight', 'bold', 'fontsize', 8, 'BackgroundColor', [1 1 1],...
%     'HorizontalAlignment', 'Left');
annotation('textbox', ...
    'Units', 'centimeters', ...
    'Position', [x_col2-.25 y_col2_row9 4 1], ...
    'String', 'B. CentOut-related', ...
    'FontName', 'Dejavu Sans', ...
    'FontWeight', 'bold', ...
    'FontSize', 8, ...
    'BackgroundColor', [1 1 1], ...
    'HorizontalAlignment', 'Left', ...
    'EdgeColor', 'none');
%% Align to Trigger
% For correct trials and late trials

x_col3 = x_col2 + w_psth + w_space;
w_psth = 2 * sum(TriggerTimeDomain) / 1000;
% Correct trials
ind_psth     = strcmp(PSTH.TriggerLabels, 'PSTH');
ind_t_psth   = strcmp(PSTH.TriggerLabels, 'tPSTH');
ind_spkmat   = strcmp(PSTH.TriggerLabels, 'SpikeMat');
ind_t_spkmat = strcmp(PSTH.TriggerLabels, 'tSpikeMat');
ind_t_event  = strcmp(PSTH.TriggerLabels, 'tEvents');
ind_rt       = strcmp(PSTH.TriggerLabels, 'RT');
ind_fp       = strcmp(PSTH.TriggerLabels, 'FP');

% PSTH of correct trials
y_col3_row1 = y_col1_row1;
ha_trigger_psth = cell(1,NumFPs);
for i = 1:NumFPs
    yshift = y_col3_row1 + (h_psth+0.1)*(NumFPs-i);
    ha_trigger_psth{i} = axes(fig, 'unit', 'centimeters', 'position', [x_col3 yshift w_psth h_psth], 'nextplot', 'add', 'xlim', [-TriggerTimeDomain(1) TriggerTimeDomain(2)], 'FontSize', 7, 'TickDir', 'Out');
    xline(0, 'Color', c_trigger, 'LineWidth', 1, 'Alpha', 1);
    for j = 1:NumPorts
        t_psth_trig = PSTH.Triggers{i,j}{ind_t_psth};
        psth_trig   = PSTH.Triggers{i,j}{ind_psth};

        plot(t_psth_trig, psth_trig, 'color', c_port{j}, 'linewidth', 1);
        FRMax = max([FRMax max(psth_trig)]);
    end
    if i==NumFPs
        xlabel('Time from trigger (ms)')
        ylabel('Spks per s')
    else
        xticklabels([]);
        yticklabels([]);
    end
end

y_col3_row2 = y_col1_row2;
% Plot spike raster of correct trials (all FPs)
ntrials_trigger_ij = zeros(NumFPs, NumPorts);
for i = 1:NumFPs
    for j = 1:NumPorts
        t_event_trigger = PSTH.Triggers{i,j}{ind_t_event};
        ntrials_trigger_ij(i,j) = length(t_event_trigger);
    end
end
ntrials_trigger = sum(ntrials_trigger_ij, "all");

axes('unit', 'centimeters', 'position', [x_col3 y_col3_row2 w_psth ntrials_trigger*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-TriggerTimeDomain(1) TriggerTimeDomain(2)], 'ylim', [-ntrials_trigger 1], 'box', 'on');
k=0;
for m = 1:NumFPs
    for n = 1:NumPorts
        t_event = PSTH.Triggers{m,n}{ind_t_event};
        spk_mat = PSTH.Triggers{m,n}{ind_spkmat};
        t_mat   = PSTH.Triggers{m,n}{ind_t_spkmat};
        rt      = PSTH.Triggers{m,n}{ind_rt};

        xx_all = []; % spike times
        yy_all = [];
        xxrt_all = []; % reaction (cent-out) times
        yyrt_all = [];
        x_choice = []; % choice times
        y_choice = [];

        for i = 1:ntrials_cent_in_ij(m,n)
            xx = t_mat(spk_mat(:,i)==1);
            yy1 = [.1 .9] - k;
            yy2 = [0 1] - k;

            xxrt = rt(i);

            if isempty(find(isnan(spk_mat(:, i)), 1))
                for i_xx = 1:length(xx)
                    xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
                    yy_all = [yy_all, yy1, NaN];
                end
                xxrt_all = [xxrt_all, xxrt, xxrt, NaN];
                yyrt_all = [yyrt_all, yy2, NaN];
            end
            % port access time
            it_trigger = t_event(i);
            it_choice = t_choice - it_trigger;
            it_choice = it_choice(it_choice>=-TriggerTimeDomain(1) & it_choice<=TriggerTimeDomain(2));
            if ~isempty(it_choice)
                it_choice = reshape(it_choice,1,[]);
                x_choice = [x_choice, it_choice];
                y_choice = [y_choice, (0.5-k)*ones(1,length(it_choice))];
            end
            k = k+1;
        end
        line(xx_all, yy_all, 'color', c_port{n}, 'linewidth', .2);
        line(xxrt_all, yyrt_all, 'color', c_cent_out, 'linewidth', 1);
        scatter(x_choice, y_choice, 8, 'o', 'filled','MarkerFaceColor', c_reward,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none');
    end
end
xline(0, 'Color', c_trigger, 'LineWidth', 1, 'Alpha', 1);
title('Correct', 'fontsize', 7, 'fontweight','bold');
axis off

% Late trials
% PSTH of late trials
y_col3_row3 = y_col1_row3;

ha_trigger_psth_late =  axes('unit', 'centimeters', 'position', [x_col3 y_col3_row3 w_psth h_psth], 'nextplot', 'add',...
    'xlim',  [-TriggerTimeDomain(1) TriggerTimeDomain(2)], 'xticklabel', [], 'FontSize', 7, 'TickDir', 'Out');
xline(0, 'Color', c_trigger, 'LineWidth', 1, 'Alpha', 1);
for j = 1:NumPorts
    if length(PSTH.TriggerLate{j}{ind_t_event}) > 3
        plot(PSTH.TriggerLate{j}{ind_t_psth}, PSTH.TriggerLate{j}{ind_psth}, 'color', c_port{j}, 'linewidth',1);
    end
end

% Late response raster plot
y_col3_row4 = y_col1_row4;
ntrial_trigger_late = sum(cellfun(@(x) length(x{ind_t_event}), PSTH.TriggerLate)); % number of trials
axes('unit', 'centimeters', 'position', [x_col3 y_col3_row4 w_psth ntrial_trigger_late*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-TriggerTimeDomain(1) TriggerTimeDomain(2)], 'ylim', [-ntrial_trigger_late 1], 'box', 'on');
k = 0;
for n = 1:NumPorts
    t_event = PSTH.TriggerLate{n}{ind_t_event};
    spk_mat = PSTH.TriggerLate{n}{ind_spkmat};
    t_mat   = PSTH.TriggerLate{n}{ind_t_spkmat};
    rt      = PSTH.TriggerLate{n}{ind_hd};

    xx_all = []; % spike times
    yy_all = [];
    xxrt_all = []; % cent-out times
    yyrt_all = [];
    x_choice = []; % choice times
    y_choice = [];
    
    for i =1:size(spk_mat, 2)
        xx =  t_mat(spk_mat(:, i)==1);
        yy1 = [.1 .9] - k;
        yy2 = [0 1] - k;

        xxrt = rt(i);

        for i_xx = 1:length(xx)
            xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
            yy_all = [yy_all, yy1, NaN];
        end
        xxrt_all = [xxrt_all, xxrt, xxrt, NaN];
        yyrt_all = [yyrt_all, yy2, NaN];

        % plot port poke time
        it_choice = t_choice - t_event(i);
        it_choice = it_choice(it_choice>=-TriggerTimeDomain(1) & it_choice<=TriggerTimeDomain(2));
        if ~isempty(it_choice)
            it_choice = reshape(it_choice,1,[]);
            x_choice = [x_choice, it_choice];
            y_choice = [y_choice, (0.5-k)*ones(1,length(it_choice))];
        end
        k = k+1;
    end

    line(xx_all, yy_all, 'color', c_port{n}, 'linewidth', .2)
    line(xxrt_all, yyrt_all, 'color', c_cent_out, 'linewidth', 1)
    scatter(x_choice, y_choice, 8, 'o', 'filled','MarkerFaceColor', c_reward,  'markerfacealpha', 0.5, 'MarkerEdgeColor','none')
end
xline(0, 'Color', c_trigger, 'LineWidth', 1, 'Alpha', 1);
title('Late', 'fontsize', 7, 'fontweight','bold')
axis off

y_col3_row5 = y_col3_row4 + 0.5 + ntrial_trigger_late*rasterheight;
% Add information
% uicontrol('Style', 'text', 'Units', 'centimeters', 'Position', [x_col3-.25 y_col3_row5 4 1],...
%     'string', 'C. Trigger-related', ...
%     'FontName', 'Dejavu Sans', 'fontweight', 'bold', 'fontsize', 8, 'BackgroundColor', [1 1 1],...
%     'HorizontalAlignment', 'Left');
annotation('textbox', ...
    'Units', 'centimeters', ...
    'Position', [x_col3-.25 y_col3_row5 4 1], ...
    'String', 'C. Trigger-related', ...
    'FontName', 'Dejavu Sans', ...
    'FontWeight', 'bold', ...
    'FontSize', 8, ...
    'BackgroundColor', [1 1 1], ...
    'HorizontalAlignment', 'Left', ...
    'EdgeColor', 'none');
%% Align to ChoiceIn
x_col4 = x_col3 + w_psth + w_space;
w_psth = sum(ChoiceTimeDomain) / 1000;

% Correct trials
ind_psth     = strcmp(PSTH.ChoiceLabels, 'PSTH');
ind_t_psth   = strcmp(PSTH.ChoiceLabels, 'tPSTH');
ind_spkmat   = strcmp(PSTH.ChoiceLabels, 'SpikeMat');
ind_t_spkmat = strcmp(PSTH.ChoiceLabels, 'tSpikeMat');
ind_t_event  = strcmp(PSTH.ChoiceLabels, 'tEvents');
ind_mt       = strcmp(PSTH.ChoiceLabels, 'MoveTime');

% PSTH of correct trials
y_col4_row1 = y_col1_row1;
ha_choice_psth = cell(1,NumFPs);
for i = 1:NumFPs
    yshift = y_col4_row1 + (h_psth+0.1)*(NumFPs-i);
    ha_choice_psth{i} = axes(fig, 'unit', 'centimeters', 'position', [x_col4 yshift w_psth h_psth], 'nextplot', 'add', 'xlim', [-ChoiceTimeDomain(1) ChoiceTimeDomain(2)], 'FontSize', 7, 'TickDir', 'Out');
    xline(0, 'Color', c_reward, 'LineWidth', 1, 'Alpha', 1);
    for j = 1:NumPorts
        t_psth_reward = PSTH.RewardChoice{i,j}{ind_t_psth};
        psth_reward   = PSTH.RewardChoice{i,j}{ind_psth};

        plot(t_psth_reward, psth_reward, 'color', c_port{j}, 'linewidth', 1);
        FRMax = max([FRMax max(psth_reward)]);
    end
    if i==NumFPs
        xlabel('Time from choice (ms)')
        ylabel('Spks per s')
    else
        xticklabels([]);
        yticklabels([]);
    end
end

y_col4_row2 = y_col1_row2;
% Plot spike raster of correct trials (all FPs)
ntrials_reward_ij = zeros(NumFPs, NumPorts);
for i = 1:NumFPs
    for j = 1:NumPorts
        t_event_reward = PSTH.RewardChoice{i,j}{ind_t_event};
        ntrials_reward_ij(i,j) = length(t_event_reward);
    end
end
n_trials_reward = sum(ntrials_reward_ij, "all");

axes('unit', 'centimeters', 'position', [x_col4 y_col4_row2 w_psth n_trials_reward*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-ChoiceTimeDomain(1) ChoiceTimeDomain(2)], 'ylim', [-n_trials_reward 1], 'box', 'on');
k=0;
for m = 1:NumFPs
    for n = 1:NumPorts
        spk_mat = PSTH.RewardChoice{m,n}{ind_spkmat};
        t_mat   = PSTH.RewardChoice{m,n}{ind_t_spkmat};
        mt      = PSTH.RewardChoice{m,n}{ind_mt};

        xx_all = []; % spike times
        yy_all = [];
        xxmt_all = []; % movement (cent-out to choice) times
        yymt_all = [];

        for i = 1:size(spk_mat, 2)
            xx = t_mat(spk_mat(:,i)==1);
            yy1 = [.1 .9] - k;
            yy2 = [0 1] - k;

            xxmt = -mt(i);

            if isempty(find(isnan(spk_mat(:, i)), 1))
                for i_xx = 1:length(xx)
                    xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
                    yy_all = [yy_all, yy1, NaN];
                end
                xxmt_all = [xxmt_all, xxmt, xxmt, NaN];
                yymt_all = [yymt_all, yy2, NaN];
            end
            k = k+1;
        end
        line(xx_all, yy_all, 'color', c_port{n}, 'linewidth', .2);
        line(xxmt_all, yymt_all, 'color', c_cent_out, 'linewidth', 1);
    end
end
xline(0, 'Color', c_reward, 'LineWidth', 1, 'Alpha', 1);
title('Reward', 'fontsize', 7, 'fontweight','bold');
axis off

% Non-reward trials
% PSTH of non-reward trials
y_col4_row3 = y_col1_row3;

ha_nonreward_choice_psth =  axes('unit', 'centimeters', 'position', [x_col4 y_col4_row3 w_psth h_psth], 'nextplot', 'add',...
    'xlim',  [-ChoiceTimeDomain(1) ChoiceTimeDomain(2)], 'xticklabel', [], 'FontSize', 7, 'TickDir', 'Out');
xline(0, 'Color', c_reward, 'LineWidth', 1, 'Alpha', 1);
for j = 1:NumPorts
    if length(PSTH.NonrewardChoice{j}{ind_t_event}) > 3
        plot(PSTH.NonrewardChoice{j}{ind_t_psth}, PSTH.NonrewardChoice{j}{ind_psth}, 'color', c_port{j}, 'linewidth',1);
    end
end

% Late non-reward raster plot
y_col4_row4 = y_col1_row4;
ntrial_nonreward = sum(cellfun(@(x) length(x{ind_t_event}), PSTH.NonrewardChoice)); % number of trials
axes('unit', 'centimeters', 'position', [x_col4 y_col4_row4 w_psth ntrial_nonreward*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-ChoiceTimeDomain(1) ChoiceTimeDomain(2)], 'ylim', [-ntrial_nonreward 1], 'box', 'on');
k = 0;
for n = 1:NumPorts
    spk_mat = PSTH.NonrewardChoice{n}{ind_spkmat};
    t_mat   = PSTH.NonrewardChoice{n}{ind_t_spkmat};
    mt      = PSTH.NonrewardChoice{n}{ind_hd};

    xx_all = []; % spike times
    yy_all = [];
    xxmt_all = []; % cent-out times
    yymt_all = [];

    for i =1:size(spk_mat, 2)
        xx =  t_mat(spk_mat(:, i)==1);
        yy1 = [.1 .9] - k;
        yy2 = [0 1] - k;

        xxmt = -mt(i);

        for i_xx = 1:length(xx)
            xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
            yy_all = [yy_all, yy1, NaN];
        end
        xxmt_all = [xxmt_all, xxmt, xxmt, NaN];
        yymt_all = [yymt_all, yy2, NaN];

        k = k+1;
    end

    line(xx_all, yy_all, 'color', c_port{n}, 'linewidth', .2)
    line(xxmt_all, yymt_all, 'color', c_cent_out, 'linewidth', 1)
end

xline(0, 'Color', c_reward, 'LineWidth', 1, 'Alpha', 1);
title('Non-reward', 'fontsize', 7, 'fontweight','bold')
axis off

y_col4_row5 = y_col4_row4 + 0.5 + ntrial_nonreward*rasterheight;
% Add information
% uicontrol('Style', 'text', 'Units', 'centimeters', 'Position', [x_col4-.25 y_col4_row5 4 1],...
%     'string', 'D. Reward-related', ...
%     'FontName', 'Dejavu Sans', 'fontweight', 'bold', 'fontsize', 8, 'BackgroundColor', [1 1 1],...
%     'HorizontalAlignment', 'Left');
annotation('textbox', ...
    'Units', 'centimeters', ...
    'Position', [x_col4-.25 y_col4_row5 4 1], ...
    'String', 'D. Reward-related', ...
    'FontName', 'Dejavu Sans', ...
    'FontWeight', 'bold', ...
    'FontSize', 8, ...
    'BackgroundColor', [1 1 1], ...
    'HorizontalAlignment', 'Left', ...
    'EdgeColor', 'none');
%% Align to InitIn
x_col5 = x_col4 + w_psth + w_space;
w_psth = sum(InitInTimeDomain) / 1000;

ind_psth     = strcmp(PSTH.InitInLabels, 'PSTH');
ind_t_psth   = strcmp(PSTH.InitInLabels, 'tPSTH');
ind_spkmat   = strcmp(PSTH.InitInLabels, 'SpikeMat');
ind_t_spkmat = strcmp(PSTH.InitInLabels, 'tSpikeMat');
ind_t_event  = strcmp(PSTH.InitInLabels, 'tEvents');
ind_dur      = strcmp(PSTH.InitInLabels, 'InitDur');

% pre-Correct and pre-Error trials
% PSTH of pre-correct and pre-error trials
y_col5_row1 = y_col1_row1;

ha_init_in_psth =  axes('unit', 'centimeters', 'position', [x_col5 y_col5_row1 w_psth h_psth], 'nextplot', 'add',...
    'xlim',  [-InitInTimeDomain(1) InitInTimeDomain(2)], 'FontSize', 7, 'TickDir', 'Out');
xline(0, 'Color', 'k', 'LineWidth', 1, 'Alpha', 1);
if length(PSTH.PreCorrectInitIn{ind_t_event}) > 3
    plot(PSTH.PreCorrectInitIn{ind_t_psth}, PSTH.PreCorrectInitIn{ind_psth}, 'color', c_precor, 'linewidth', 1);
    FRMax = max([FRMax max(PSTH.PreCorrectInitIn{ind_psth})]);
end
if length(PSTH.PreErrorInitIn{ind_t_event}) > 3
    plot(PSTH.PreErrorInitIn{ind_t_psth}, PSTH.PreErrorInitIn{ind_psth}, 'color', c_preerr, 'linewidth', 1);
    FRMax = max([FRMax max(PSTH.PreErrorInitIn{ind_psth})]);
end
xlabel('Time from init-in (ms)')
ylabel('Spks per s')

% raster plot for pre-correct trials
y_col5_row2 = y_col5_row1 + (h_psth+.1);
ntrial_precor = length(PSTH.PreCorrectInitIn{ind_t_event}); % number of trials
axes('unit', 'centimeters', 'position', [x_col5 y_col5_row2 w_psth ntrial_precor*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-InitInTimeDomain(1) InitInTimeDomain(2)], 'ylim', [-ntrial_precor 1], 'box', 'on');
k = 0;

spk_mat  = PSTH.PreCorrectInitIn{ind_spkmat};
t_mat    = PSTH.PreCorrectInitIn{ind_t_spkmat};
init_dur = PSTH.PreCorrectInitIn{ind_dur};

xx_all = [];
yy_all = [];
xxdur_all = [];
yydur_all = [];

for i = 1:size(spk_mat, 2)
    xx =  t_mat(spk_mat(:, i)==1);
    yy1 = [.1 .9] - k;
    yy2 = [0 1] - k;

    xxdur = init_dur(i);

    for i_xx = 1:length(xx)
        xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
        yy_all = [yy_all, yy1, NaN];
    end
    xxdur_all = [xxdur_all, xxdur];
    yydur_all = [yydur_all, mean(yy2)];

    k = k+1;
end
line(xx_all, yy_all, 'color', c_precor, 'linewidth', .2)
scatter(xxdur_all, yydur_all, 6, 'k', 'd')

xline(0, 'Color', 'k', 'LineWidth', 1, 'Alpha', 1);
title('Pre-correct', 'fontsize', 7, 'fontweight','bold')
axis off

% raster plot for pre-error trials
y_col5_row3 = y_col5_row2 + 0.5 + ntrial_precor*rasterheight;
ntrial_preerr = length(PSTH.PreErrorInitIn{ind_t_event}); % number of trials
axes('unit', 'centimeters', 'position', [x_col5 y_col5_row3 w_psth ntrial_preerr*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-InitInTimeDomain(1) InitInTimeDomain(2)], 'ylim', [-ntrial_preerr 1], 'box', 'on');
k = 0;

spk_mat  = PSTH.PreErrorInitIn{ind_spkmat};
t_mat    = PSTH.PreErrorInitIn{ind_t_spkmat};
init_dur = PSTH.PreErrorInitIn{ind_dur};

xx_all = [];
yy_all = [];
xxdur_all = [];
yydur_all = [];
for i = 1:size(spk_mat, 2)
    xx =  t_mat(spk_mat(:, i)==1);
    yy1 = [.1 .9] - k;
    yy2 = [0 1] - k;

    xxdur = init_dur(i);

    for i_xx = 1:length(xx)
        xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
        yy_all = [yy_all, yy1, NaN];
    end
    xxdur_all = [xxdur_all, xxdur];
    yydur_all = [yydur_all, mean(yy2)];

    k = k+1;
end
line(xx_all, yy_all, 'color', c_preerr, 'linewidth', .2)
scatter(xxdur_all, yydur_all, 6, 'k', 'd')

xline(0, 'Color', 'k', 'LineWidth', 1, 'Alpha', 1);
title('Pre-error', 'fontsize', 7, 'fontweight','bold')
axis off

y_col5_row4 = y_col5_row3 + 0.5 + ntrial_preerr*rasterheight;
% Add information
% uicontrol('Style','text','Units','centimeters','Position',[x_col5-.25 y_col5_row4 4 1],...
%     'string', 'E. InitIn-related', ...
%     'FontName','Dejavu Sans', 'fontweight', 'bold','fontsize', 8,'BackgroundColor',[1 1 1],...
%     'HorizontalAlignment','Left');
annotation('textbox', ...
    'Units', 'centimeters', ...
    'Position', [x_col5-.25 y_col5_row4 4 1], ...
    'String', 'E. InitIn-related', ...
    'FontName', 'Dejavu Sans', ...
    'FontWeight', 'bold', ...
    'FontSize', 8, ...
    'BackgroundColor', [1 1 1], ...
    'HorizontalAlignment', 'Left', ...
    'EdgeColor', 'none');
%% Align to InitOut
x_col6 = x_col5 + w_psth + w_space;
w_psth = 0.5 * sum(InitOutTimeDomain) / 1000;

ind_psth     = strcmp(PSTH.InitOutLabels, 'PSTH');
ind_t_psth   = strcmp(PSTH.InitOutLabels, 'tPSTH');
ind_spkmat   = strcmp(PSTH.InitOutLabels, 'SpikeMat');
ind_t_spkmat = strcmp(PSTH.InitOutLabels, 'tSpikeMat');
ind_t_event  = strcmp(PSTH.InitOutLabels, 'tEvents');
ind_st       = strcmp(PSTH.InitOutLabels, 'ShuttleTime');

% pre-Correct and pre-Error trials
% PSTH of pre-correct and pre-error trials
y_col6_row1 = y_col5_row1;

ha_init_out_psth =  axes('unit', 'centimeters', 'position', [x_col6 y_col6_row1 w_psth h_psth], 'nextplot', 'add',...
    'xlim',  [-InitOutTimeDomain(1) InitOutTimeDomain(2)], 'FontSize', 7, 'TickDir', 'Out');
xline(0, 'Color', 'k', 'LineWidth', 1, 'Alpha', 1);
if length(PSTH.PreCorrectInitOut{ind_t_event}) > 3
    plot(PSTH.PreCorrectInitOut{ind_t_psth}, PSTH.PreCorrectInitOut{ind_psth}, 'color', c_precor, 'linewidth', 1);
    FRMax = max([FRMax max(PSTH.PreCorrectInitOut{ind_psth})]);
end
if length(PSTH.PreErrorInitOut{ind_t_event}) > 3
    plot(PSTH.PreErrorInitOut{ind_t_psth}, PSTH.PreErrorInitOut{ind_psth}, 'color', c_preerr, 'linewidth', 1);
    FRMax = max([FRMax max(PSTH.PreErrorInitOut{ind_psth})]);
end
xlabel('Time from init-out (ms)')
ylabel('Spks per s')

% raster plot for pre-correct trials
y_col6_row2 = y_col5_row2;
axes('unit', 'centimeters', 'position', [x_col6 y_col6_row2 w_psth ntrial_precor*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-InitOutTimeDomain(1) InitOutTimeDomain(2)], 'ylim', [-ntrial_precor 1], 'box', 'on');
k = 0;

spk_mat = PSTH.PreCorrectInitOut{ind_spkmat};
t_mat   = PSTH.PreCorrectInitOut{ind_t_spkmat};
st      = PSTH.PreCorrectInitOut{ind_st};

xx_all = [];
yy_all = [];
xxdur_all = [];
yydur_all = [];
for i = 1:size(spk_mat, 2)
    xx  =  t_mat(spk_mat(:, i)==1);
    yy1 = [.1 .9] - k;
    yy2 = [0 1] - k;

    xxdur = st(i);

    for i_xx = 1:length(xx)
        xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
        yy_all = [yy_all, yy1, NaN];
    end
    xxdur_all = [xxdur_all, xxdur];
    yydur_all = [yydur_all, mean(yy2)];

    k = k+1;
end
line(xx_all, yy_all, 'color', c_precor, 'linewidth', .2)
scatter(xxdur_all, yydur_all, 8, 'k', '*')

xline(0, 'Color', 'k', 'LineWidth', 1, 'Alpha', 1);
title('Pre-correct', 'fontsize', 7, 'fontweight','bold')
axis off

% raster plot for pre-error trials
y_col6_row3 = y_col5_row3;
axes('unit', 'centimeters', 'position', [x_col6 y_col6_row3 w_psth ntrial_preerr*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-InitOutTimeDomain(1) InitOutTimeDomain(2)], 'ylim', [-ntrial_preerr 1], 'box', 'on');
k = 0;

spk_mat = PSTH.PreErrorInitOut{ind_spkmat};
t_mat   = PSTH.PreErrorInitOut{ind_t_spkmat};
st      = PSTH.PreErrorInitOut{ind_st};

xx_all = [];
yy_all = [];
xxdur_all = [];
yydur_all = [];
for i = 1:size(spk_mat, 2)
    xx =  t_mat(spk_mat(:, i)==1);
    yy1 = [.1 .9] - k;
    yy2 = [0 1] - k;

    xxdur = st(i);

    for i_xx = 1:length(xx)
        xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
        yy_all = [yy_all, yy1, NaN];
    end
    xxdur_all = [xxdur_all, xxdur];
    yydur_all = [yydur_all, mean(yy2)];

    k = k+1;
end
line(xx_all, yy_all, 'color', c_preerr, 'linewidth', .2)
scatter(xxdur_all, yydur_all, 8, 'k', '*')

xline(0, 'Color', 'k', 'LineWidth', 1, 'Alpha', 1);
title('Pre-error', 'fontsize', 7, 'fontweight','bold')
axis off

y_col6_row4 = y_col5_row4;
% Add information
% uicontrol('Style', 'text', 'Units', 'centimeters', 'Position', [x_col6-.25 y_col6_row4 4 1],...
%     'string', 'F. InitOut-related', ...
%     'FontName', 'Dejavu Sans', 'fontweight', 'bold', 'fontsize', 8,'BackgroundColor', [1 1 1],...
%     'HorizontalAlignment', 'Left');
annotation('textbox', ...
    'Units', 'centimeters', ...
    'Position', [x_col6-.25 y_col6_row4 4 1], ...
    'String', 'F. InitOut-related', ...
    'FontName', 'Dejavu Sans', ...
    'FontWeight', 'bold', ...
    'FontSize', 8, ...
    'BackgroundColor', [1 1 1], ...
    'HorizontalAlignment', 'Left', ...
    'EdgeColor', 'none');
%% Unify the Y-limits
FRrange = [0 FRMax*1.05];
% cent-in
cellfun(@(x) set(x, 'ylim', FRrange), ha_cent_in_psth);
set(ha_cent_in_psth_late, 'ylim', FRrange);
set(ha_cent_in_psth_premature, 'ylim', FRrange);
set(ha_cent_in_psth_probe, 'ylim', FRrange);
% cent-out
cellfun(@(x) set(x, 'ylim', FRrange), ha_cent_out_psth);
set(ha_cent_out_psth_late, 'ylim', FRrange);
set(ha_cent_out_psth_premature, 'ylim', FRrange);
set(ha_cent_out_psth_probe, 'ylim', FRrange);
% choice
cellfun(@(x) set(x, 'ylim', FRrange), ha_choice_psth);
set(ha_nonreward_choice_psth, 'ylim', FRrange);
% trigger
cellfun(@(x) set(x, 'ylim', FRrange), ha_trigger_psth);
set(ha_trigger_psth_late, 'ylim', FRrange);
% init-in and init-out
set(ha_init_in_psth, 'ylim', FRrange);
set(ha_init_out_psth, 'ylim', FRrange);

%% plot pre-press activity vs trial num or time
y_spk_rate = max([y_col3_row5 y_col4_row5]) + 2.5;
ha_spk_rate = axes('unit', 'centimeters', 'position', [x_col3+.5 y_spk_rate 4 2], ...
    'nextplot', 'add', 'xlim', [min(t_cent_in/1000) max(t_cent_in/1000)], 'FontSize', 7, 'TickDir', 'Out');

t_cent_in = PSTH.CentInAll{ind_t_event};
spk_mat = PSTH.CentInAll{ind_spkmat};
t_mat   = PSTH.CentInAll{ind_t_spkmat};

ind_precentin = find(t_mat<0);
spkmat_precentin = spk_mat(ind_precentin, :);
dur_precentin = abs(t_mat(ind_precentin(1))) / 1000; % total time

rate_precentin = sum(spkmat_precentin, 1) / dur_precentin; % spk rate across time
plot(ha_spk_rate, t_cent_in/1000, rate_precentin, 'k', 'marker', 'o', 'markersize', 3, 'linestyle', 'none');

% linear regression
Pfit = polyfit(t_cent_in/1000, rate_precentin, 1);
yfit = Pfit(1) * t_cent_in / 1000 + Pfit(2);
plot(t_cent_in/1000, yfit, 'r:', 'linewidth', 1.5);

xlabel('Time (s)')
ylabel('Spk rate (Hz)')

y_spk_rate = y_spk_rate + 2.5;
% Add information  13.5 3+0.5 6 ntrial4*rasterheight
% uicontrol('Style', 'text', 'Units', 'centimeters', 'Position', [x_col3-0.25 y_spk_rate 4 0.5],...
%     'string', 'G. Activity vs time', ...
%     'FontName', 'Dejavu Sans', 'fontweight', 'bold', 'fontsize', 8, 'BackgroundColor', [1 1 1], 'ForegroundColor', 'k', ...
%     'HorizontalAlignment', 'Left');
annotation('textbox', ...
    'Units', 'centimeters', ...
    'Position', [x_col3-0.25 y_spk_rate 4 0.5], ...
    'String', 'G. Activity vs time', ...
    'FontName', 'Dejavu Sans', ...
    'FontWeight', 'bold', ...
    'FontSize', 8, ...
    'BackgroundColor', [1 1 1], ...
    'color', 'k',...
    'HorizontalAlignment', 'Left', ...
    'EdgeColor', 'none');
fig_height = max([fig_height, y_spk_rate+1]);

%% Plot waveform and autocorrelation
% plot waveform of the channel with max amplitude
thiscolor = [0 0 0];
spk_len = size(r.Units.SpikeTimes(ku).wave, 2);
ha_wave = axes('unit', 'centimeters', 'position', [x_col5+.25 y_col5_row4+5 2 2], ...
    'nextplot', 'add', 'xlim', [0 spk_len], 'ytick', -500:100:200, 'xticklabel', [], 'FontSize', 7, 'TickDir', 'Out');
set(ha_wave, 'nextplot', 'add');
ylabel('\muV')

allwaves = r.Units.SpikeTimes(ku).wave / 4;
if size(allwaves, 1)>100
    nplot = randperm(size(allwaves, 1), 100);
else
    nplot = 1:size(allwaves, 1);
end
wave2plot = allwaves(nplot, :);
plot(1:spk_len, wave2plot, 'color', .8*ones(1,3));
plot(1:spk_len, mean(allwaves, 1), 'color', thiscolor, 'linewidth', 2);

axis([0 spk_len min(wave2plot(:)) max(wave2plot(:))]);
set(gca, 'ylim', 1.25*[min(mean(allwaves, 1)) max(mean(allwaves, 1))]);
axis tight

line([30 60], min(get(gca, 'ylim')), 'color', 'k', 'linewidth', 2.5)
PSTH.SpikeWave = mean(allwaves, 1);

switch r.Units.SpikeNotes(ku, 3)
    case 1
        title(['#' num2str(ku) '(Ch ' num2str(r.Units.SpikeNotes(ku, 1)) ' | unit' num2str(r.Units.SpikeNotes(ku, 2))  ' | SU'], 'fontsize', 7);
    case 2
        title(['#' num2str(ku) '(Ch ' num2str(r.Units.SpikeNotes(ku, 1))  ' | unit' num2str(r.Units.SpikeNotes(ku, 2))  ' | MU'], 'fontsize', 7);
    otherwise
end

% plot autocorrelation
kutime = round(r.Units.SpikeTimes(ku).timings);
kutime = kutime(kutime>0);
kutime2 = zeros(1, max(kutime));
kutime2(kutime) = 1;
[c, lags] = xcorr(kutime2, 100); % max lag 100 ms
c(lags==0) = 0;

ha_corr = axes('unit', 'centimeters', 'position', [x_col5 y_col5_row4+2.5 2.5 2], 'nextplot', 'add', 'xlim', [-25 25], 'FontSize', 7, 'TickDir', 'Out');
if median(c)>1
    set(ha_corr, 'nextplot', 'add', 'xtick', -50:10:50, 'ytick', [0 median(c)]);
else
    set(ha_corr, 'nextplot', 'add', 'xtick', -50:10:50, 'ytick', [0 1], 'ylim', [0 1]);
end

PSTH.AutoCorrelation = {lags, c};

hbar = bar(lags, c);
set(hbar, 'facecolor', 'k');
xlabel('Lag(ms)')

% Plot waveforms of adjacent channels (for neuropixels 1.0, assigned by channel location)
if isfield(r.Units.SpikeTimes(ku), 'wave_mean')
    ha_wave_poly = axes('unit', 'centimeters', 'position', [x_col6 y_col6_row4+2 2.5 6], 'nextplot', 'add', 'FontSize', 7, 'TickDir', 'Out');
    PSTH.SpikeWaveMean = plot_adjacent_waveforms(ha_wave_poly, r, ku);
end

% uicontrol('Style', 'text', 'Units', 'centimeters', 'Position', [x_col5-.25 y_col5_row4+7.5 3 1],...
%     'string', 'H. Spike waveform & autocorrelation', ...
%     'FontName', 'Dejavu Sans', 'fontweight', 'bold', 'fontsize', 8, 'BackgroundColor', [1 1 1], 'ForegroundColor', 'k', ...
%     'HorizontalAlignment', 'Left');
annotation('textbox', ...
    'Units', 'centimeters', ...
    'Position', [x_col5-.25 y_col5_row4+7.5 3 1], ...
    'String', 'H. Spike waveform & autocorrelation', ...
    'FontName', 'Dejavu Sans', ...
    'FontWeight', 'bold', ...
    'FontSize', 8, ...
    'BackgroundColor', [1 1 1], ...
    'color', 'k',...
    'HorizontalAlignment', 'Left', ...
    'EdgeColor', 'none');
fig_height = max([fig_height, y_col5_row4+9.5]);

%% change the height of the figure
printsize(4) = fig_height;
set(fig, 'position', printsize);

%% Save the figure
toc;
if strcmpi(ToSave, 'on')
    % save to a folder
    anm_name = r.BehaviorClass.Subject;
    session  = r.BehaviorClass.Session;
    
    PSTH.ANM_Session = {anm_name, session};
    thisFolder = fullfile(pwd, 'Fig');
    if ~exist(thisFolder, 'dir')
        mkdir(thisFolder)
    end
    tosavename2= fullfile(thisFolder, anm_name+"_"+session+"_k"+num2str(ch_k)+"_y"+num2str(ch_y)+"_x"+num2str(ch_x)+"_Ch"+num2str(ch)+"_Unit"+num2str(unit_no));
    print(fig, '-dpng', tosavename2, '-r300')
    
    % save PSTH as well save(psth_new_name, 'PSTHOut');
    save(tosavename2+".mat", 'PSTH')
    
    try
        tic
        % C:\Users\jiani\OneDrive\00_Work\03_Projects
        thisFolder = fullfile(findonedrive, '00_Work', '03_Projects', '05_Physiology', 'Data', 'UnitsCollection', anm_name, session);
        if ~exist(thisFolder, 'dir')
            mkdir(thisFolder)
        end
        copyfile([tosavename2 '.png'], thisFolder)
        copyfile([tosavename2 '.mat'], thisFolder)
    
        toc
    end
end