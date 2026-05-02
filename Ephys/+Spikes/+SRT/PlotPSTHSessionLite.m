function PlotPSTHSessionLite(r)

figure(26); clf(26)

n_unit = length(r.PSTH.PSTHs);
tiledlayout((n_unit), 3, 'Padding', 'none', 'TileSpacing', 'compact');
all_colors = varycolor(n_unit);

for i =1:(n_unit)
    ha = zeros(1, 3);
    ymax = 10;
    nexttile
    ispike_note = r.Units.SpikeNotes(i, [1 2]);
    event_time_index = zeros(1, 3);

    iPSTH = [];
    % extract press
    press_range = [-2 1];
    idata=r.PSTH.PSTHs(i).Presses{end};
    tPSTH = idata{2};
    PSTH = idata{1};
    ind=find(tPSTH/1000>=press_range(1) & tPSTH/1000<=press_range(2));
    iPSTH = [iPSTH PSTH(ind) NaN(1, 100)];

    bar(tPSTH(ind), PSTH(ind), 'facecolor', all_colors(i, :), 'linewidth', 1, 'edgecolor', 'none')
    legend(sprintf('C%2.0d | U%2.0d', ispike_note(1), ispike_note(2)), ...
        'location', 'NorthWest', 'box', 'off', 'fontsize', 8, 'fontweight', 'bold')
    ymax = max(ymax, max(PSTH(ind)));
    ha(1)= gca;

    % extract release
    nexttile
    release_range = [-.5 1];
    idata=r.PSTH.PSTHs(i).Releases{end};
    tPSTH = idata{2};
    PSTH = idata{1};
    ind=find(tPSTH/1000>=release_range(1) & tPSTH/1000<=release_range(2));
    iPSTH = [iPSTH PSTH(ind) NaN(1, 100)];
    bar(tPSTH(ind), PSTH(ind), 'facecolor', all_colors(i, :), 'linewidth', 1, 'edgecolor', 'none');
    ymax = max(ymax, max(PSTH(ind)));
    ha(2)= gca;

    % extract poke
    nexttile
    poke_range = [-1 1];
    idata=r.PSTH.PSTHs(i).RewardPokes{end};
    tPSTH = idata{2};
    PSTH = idata{1};
    ind=find(tPSTH/1000>=poke_range(1) & tPSTH/1000<=poke_range(2));
    iPSTH = [iPSTH PSTH(ind) NaN(1, 100)];
    bar(tPSTH(ind), PSTH(ind), 'facecolor', all_colors(i, :), 'linewidth', 1, 'edgecolor', 'none')
    ymax = max(ymax, max(PSTH(ind)));
    ha(3)= gca;

    for k =1:length(ha)
        set(ha(k), 'ylim', [0 1.25*ymax]);
    end
 
end